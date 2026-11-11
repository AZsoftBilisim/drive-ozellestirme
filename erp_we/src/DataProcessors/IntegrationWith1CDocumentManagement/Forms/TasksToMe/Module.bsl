#Region Variables

&AtClient
Var DetailedInformationAboutTasks;

&AtClient
Var SavedComments;

&AtClient
Var CompositeIsSet;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCore.WhenCreatingFormsHostedOnDesktopOnServer(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	AutoRefresh = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "AutoRefresh", True);
	AutoRefreshPeriod = Common.CommonSettingsStorageLoad(
		"IntegrationWith1CDocumentManagement", "AutoRefreshPeriod", 900);
	
	Items.MainGroup2.Enabled = False;
	Items.AutoRefresh.Enabled = False;
	
	SetTaskAppearance(ConditionalAppearance);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	DetailedInformationAboutTasks = New Map;
	SavedComments = New Map;
	
	Items.TaskViewGroup.Visible = Not DonTShowTaskViewport;
	Items.ShowTaskViewport.Check = Not DonTShowTaskViewport;
	Items.TaskViewPages.CurrentPage = Items.NoIssuePage;
	
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

&AtClient
Procedure DecorationTaskClick(Item)
	
	If SubjectOfConsiderationID = "" Or SubjectOfConsiderationType = "" Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", SubjectOfConsiderationID);
	FormParameters.Insert("type", SubjectOfConsiderationType);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters, ThisObject, SubjectOfConsiderationID);
	
EndProcedure

&AtClient
Procedure DecorationProcessClick(Item)
	
	If BusinessProcessOfSubjectOfConsiderationID = "" Or BusinessProcessOfSubjectOfConsiderationType = "" Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		BusinessProcessOfSubjectOfConsiderationType, BusinessProcessOfSubjectOfConsiderationID, ThisObject);
	
EndProcedure

&AtClient
Procedure CommentTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	// We will save the text of the comment when the focus leaves.
	If Items.Tasks.CurrentData <> Undefined And Not Items.Tasks.CurrentData.Group Then
		
		TaskID = Items.Tasks.CurrentData.TaskID;
		SavedComment = SavedComments.Get(TaskID);
		If SavedComment <> Undefined Or Not IsBlankString(Text) Then
			SavedComments.Insert(TaskID, Text);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NewTermDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DurationOfTransfer = IntegrationWith1CDocumentManagementServerCall.SignatureOfPostponementDuration(
		Author,
		AuthorID,
		AuthorType,
		OldDeadline,
		NewTerm);
	
EndProcedure

&AtClient
Procedure NewTermTimeOnChange(Item)
	
	DurationOfTransfer = IntegrationWith1CDocumentManagementServerCall.SignatureOfPostponementDuration(
		Author,
		AuthorID,
		AuthorType,
		OldDeadline,
		NewTerm);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTasks

&AtClient
Procedure TasksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Modified = False;
	CurrentData = Items.Tasks.CurrentData;
	If CurrentData = Undefined Or CurrentData.Group Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("TasksSelectionCompletion", ThisObject, CurrentData.TaskID);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.TaskType, CurrentData.TaskID, ThisObject,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TasksSelectionCompletion(Result, TaskID) Export
	
	If Items.Tasks.Representation = TableRepresentation.List Then
		TaskLines_ = Tasks.GetItems();
		For Each TaskLine In TaskLines_ Do
			If TaskLine.TaskID = TaskID Then
				TaskLine.DateOfReceiptOfDetailedInformation = Undefined;
				UpdateDetailedInformation(TaskLine);
				Return;
			EndIf;
		EndDo;
	Else
		// Grouping.
		For Each TreeGroup In Tasks.GetItems() Do
			TaskLines_ = TreeGroup.GetItems();
			For Each TaskLine In TaskLines_ Do
				If TaskLine.TaskID = TaskID Then
					TaskLine.DateOfReceiptOfDetailedInformation = Undefined;
					UpdateDetailedInformation(TaskLine);
					Return;
				EndIf;
			EndDo;
		EndDo;
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
Procedure TasksOnActivateRow(Item)
	
	If Item.CurrentRow = CompositeIsSet Then
		Return;
	EndIf;
	CompositeIsSet = Item.CurrentRow;
	
	Items.CreateSubtask.Enabled = False;
	Items.TaskRedirect.Enabled = False;
	Items.AcceptForExecution.Enabled = False;
	Items.TasksContextMenuAcceptForExecution.Enabled = False;
	Items.CancelAcceptForExecution.Enabled = False;
	Items.TasksContextMenuCancelAcceptForExecution.Enabled = False;
	Items.AskAuthorQuestion.Visible = False;
	Items.AgreeOnPostponement.Visible = False;
	
	TaskLine = Items.Tasks.CurrentData;
	If DonTShowTaskViewport Or TaskLine = Undefined Then
		Items.TaskViewPages.CurrentPage = Items.NoIssuePage;
	Else
		If TaskLine.Group Then
			Items.TaskViewPages.CurrentPage = Items.NoIssuePage;
		Else
			Items.TaskViewPages.CurrentPage = Items.TaskViewPage;
		EndIf;
		
		If TaskLine <> Undefined And Not TaskLine.Group Then
			Items.TaskRedirect.Enabled = True;
			Items.CreateSubtask.Enabled = True;
			Items.AcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.TasksContextMenuAcceptForExecution.Enabled = Not TaskLine.AcceptedForExecution;
			Items.CancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
			Items.TasksContextMenuCancelAcceptForExecution.Enabled = TaskLine.AcceptedForExecution;
			
			If TaskLine.Process_Type <> "DMBusinessProcessIssuesSolution" Then
				Items.AskAuthorQuestion.Visible = True;
				Items.AgreeOnPostponement.Visible = Not TaskLine.Executed
					And ValueIsFilled(TaskLine.TaskDueDate)
					And PostponementFunctionalityIsAvailable;
			EndIf;
		EndIf;
		
		AttachIdleHandler("Attachable_GetDetailedInformation", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationTree

&AtClient
Procedure ApplicationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TreeRow = Item.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	If TreeRow.Type = "DMFile" Then // Opening a file for viewing.
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			TreeRow.ID,
			TreeRow.Description,
			TreeRow.Extension,
			UUID);
		
	ElsIf ValueIsFilled(TreeRow.Ref) Then // the IP object.
		ShowValue(, TreeRow.Ref);
		
	Else // Opening a place card BEFORE.
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(TreeRow.Type, TreeRow.ID, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationTreeOnActivateRow(Item)
	
	TaskLine = Items.Tasks.CurrentData;
	SubjectLine = Items.ApplicationTree.CurrentData;
	
	If TaskLine = Undefined
			Or TaskLine.Group
			Or SubjectLine = Undefined Then
		Items.OpenItemForViewing.Enabled = False;
		Items.AddSubject.Enabled = False;
		Items.DeleteSubject.Enabled = False;
		Items.Edit.Enabled = False;
		Items.EndEdit.Enabled = False;
		Items.CancelEdit.Enabled = False;
	Else
		Items.AddSubject.Enabled = True;
		Items.DeleteSubject.Enabled = SubjectLine.DeletionAvailable And Not SubjectLine.IsBeingEdited;
		If SubjectLine.Type = "DMFile" Then
			Items.OpenItemForViewing.Enabled = True;
			Items.Edit.Enabled = FileCaptureIsAvailable
				And (Not SubjectLine.IsBeingEdited Or SubjectLine.EditedByCurUser);
			Items.EndEdit.Enabled = FileCaptureIsAvailable
				And SubjectLine.EditedByCurUser;
			Items.CancelEdit.Enabled = FileCaptureIsAvailable
				And SubjectLine.EditedByCurUser;
			
			SubjectLine = SubjectLine.GetParent();
		Else
			Items.OpenItemForViewing.Enabled = False;
			Items.Edit.Enabled = False;
			Items.EndEdit.Enabled = False;
			Items.CancelEdit.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SceneryNoItemsURLProcessing(Item, FormattedStringURL,
		StandardProcessing)
	
	StandardProcessing = False;
	AddSubject(Undefined);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Modified = False;
	DetailedInformationAboutTasks = New Map;
	RefreshTasksListOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure OpenTask(Command)
	
	Modified = False;
	CurrentData = Items.Tasks.CurrentData;
	If CurrentData = Undefined Or CurrentData.Group Then
		Return;
	EndIf;
	
	DetailedInformationAboutTasks.Delete(CurrentData.TaskID);
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		CurrentData.TaskType, CurrentData.TaskID, ThisObject);
	
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

// Commands with this handler are created programmatically according to the subjects of the active task.
//
// Parameters:
//   Command - FormCommand
//
&AtClient
Procedure Attachable_CreateLinkedObject(Command)
	
	// To create_Guide_Contractors__1 -> Directory.Counterparty_1
	CommandName = Command.Name;
	TypeName = Mid(CommandName, 9);
	TypeName = StrReplace(TypeName, "___", "~");
	TypeName = StrReplace(TypeName, "__", "&");
	TypeName = StrReplace(TypeName, "_", ".");
	TypeName = StrReplace(TypeName, "&", "_");
	TypeName = StrReplace(TypeName, "~", "._");
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	SubjectLine = Items.ApplicationTree.CurrentData;
	If SubjectLine = Undefined Then
		ApplicationTreeElements = ApplicationTree.GetItems();
		If ApplicationTreeElements.Count() = 0 Then
			Return;
		EndIf;
		SubjectLine = ApplicationTreeElements[0];
	Else
		ParentLevelRow = SubjectLine.GetParent();
		If ParentLevelRow <> Undefined Then
			SubjectLine = ParentLevelRow;
		EndIf;
	EndIf;
	
	IntegrationWith1CDocumentManagementClient.CreateIntegratedObjectByType(
		ThisObject,
		TypeName,
		SubjectLine.Type,
		SubjectLine.ID);
	TaskLine.DateOfReceiptOfDetailedInformation = Undefined;
	
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
Procedure ShowTaskViewport(Command)
	
	DonTShowTaskViewport = Not DonTShowTaskViewport;
	
	Items.TaskViewGroup.Visible = Not DonTShowTaskViewport;
	Items.ShowTaskViewport.Check = Not DonTShowTaskViewport;
	
	If Not DonTShowTaskViewport Then
		UpdateDetailedInformation(Items.Tasks.CurrentData);
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
Procedure Forward(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Task", TaskLine.Task);
	FormParameters.Insert("TaskID", TaskLine.TaskID);
	FormParameters.Insert("TaskType", TaskLine.TaskType);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.TaskRedirecting",
		FormParameters);
	
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
Procedure GroupByArtist(Command)
	
	GroupByColumn("Performer");
	
EndProcedure

&AtClient
Procedure GroupByNoGroup(Command)
	
	GroupByColumn("");
	
EndProcedure

&AtClient
Procedure SwitchTiming(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	TaskDetailInformation = DetailedInformationAboutTasks.Get(TaskLine.TaskID);
	If TaskDetailInformation = Undefined Then
		Return;
	EndIf;
	SubjectOfID = Undefined;
	SubjectLine = Items.ApplicationTree.CurrentData;
	If SubjectLine <> Undefined Then
		ParentLevelRow = SubjectLine.GetParent();
		If ParentLevelRow <> Undefined Then
			SubjectLine = ParentLevelRow;
		EndIf;
		SubjectOfID = SubjectLine.ID;
	EndIf;
	
	NeedDialogue = True;
	WorkDuration = IntegrationWith1CDocumentManagementClient.GetRunningTime(
		TaskDetailInformation.StartDateOfTimekeeping);
	If WorkDuration < 60 Then // Less than 1 minute.
		NeedDialogue = False;
	EndIf;
	
	If NeedDialogue Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Source", TaskLine.Task);
		FormParameters.Insert("SourceID", TaskLine.TaskID);
		FormParameters.Insert("SourceType", TaskLine.TaskType);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ThisObject);
		
	Else
		
		If TaskDetailInformation.TimekeepingEnabled Then
			
			SwitchTimingServer(
				TaskLine.TaskType,
				TaskLine.TaskID,
				SubjectOfID,
				TaskDetailInformation);
			If TaskDetailInformation.TimekeepingEnabled Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
						|ru = 'Включен хронометраж по ""%1""';
						|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
						|it = 'Crono-analisi attivata per ""%1""';
						|pl = 'Chronometraż jest włączony według ""%1""';
						|tr = '""%1"" ile kronometre etkin'"), String(TaskLine.Task));
				Status(Text);
			EndIf;
			DetailedInformationAboutTasks.Insert(TaskLine.TaskID, TaskDetailInformation);
			
		Else
			
			// perhaps the timing is still on, but the detailed record did not have time to update
			ActiveEntries = IntegrationWith1CDocumentManagementServerCall.ActiveTimekeepingRecords();
			If ActiveEntries.Count() = 0
					Or (ActiveEntries.Count() = 1 And ActiveEntries[0].SourceID = TaskLine.TaskID) Then
				
				SwitchTimingServer(
					TaskLine.TaskType,
					TaskLine.TaskID,
					SubjectOfID,
					TaskDetailInformation);
				If TaskDetailInformation.TimekeepingEnabled Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
							|ru = 'Включен хронометраж по ""%1""';
							|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
							|it = 'Crono-analisi attivata per ""%1""';
							|pl = 'Chronometraż jest włączony według ""%1""';
							|tr = '""%1"" ile kronometre etkin'"), String(TaskLine.Task));
					Status(Text);
				EndIf;
				DetailedInformationAboutTasks.Insert(TaskLine.TaskID, TaskDetailInformation);
				
			Else
				
				NotificationParameters = New Structure;
				NotificationParameters.Insert("ActiveEntries", ActiveEntries);
				NotificationParameters.Insert("Task", TaskLine.Task);
				NotificationParameters.Insert("TaskID", TaskLine.TaskID);
				NotificationParameters.Insert("TaskType", TaskLine.TaskType);
				NotificationParameters.Insert("SubjectOfID", SubjectOfID);
				NotificationParameters.Insert("TaskDetailInformation", TaskDetailInformation);
				Notification = New CallbackDescription("SwitchTimingCompletion",
					ThisObject, NotificationParameters);
				
				StringOfTimekeepingObjects = "";
				For Each Record In ActiveEntries Do
					StringOfTimekeepingObjects = StringOfTimekeepingObjects + Chars.Tab + Record.Source + Chars.LF;
				EndDo;
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo các đối tượng khác nhau:
						|%1
						|Tắt đồng hồ tính thời gian và ghi nhận công lao động trước khi sử dụng đồng hồ tính thời gian mới?';
						|ru = 'Включен хронометраж по другим объектам:
						|%1
						|Отключить хронометраж и зафиксировать трудозатраты перед включением нового хронометража?';
						|en = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs before enabling new timing?'; fa = 'Timing by other objects is enabled:
						|%1
						|Disable timing and record labor costs before enabling new timing?';
						|it = 'Crono-analisi attivata per altri oggetti:
						|%1
						|Disattivare crono-analisi e bloccare il costo del lavoro prima dell''attivazione della nuova crono-analisi?';
						|pl = 'Włączono chronometraż według innych obiektów:
						|%1
						|Wyłączyć chronometraż i ustalić nakłady pracy przed włączeniem nowego chronometrażu?';
						|tr = 'Diğer nesneler için kronometraj etkinleştirildi:
						|%1
						|Yeni kronometrajı etkinleştirmeden önce kronometraj devre dışı bırakılsın ve iş gücü maliyetleri uygulansın mı?'"),
						StringOfTimekeepingObjects);
						
				Buttons = New ValueList;
				Buttons.Add(DialogReturnCode.Yes,NStr("vi = 'Có';
														|ru = 'Да';
														|en = 'Yes'; fa = 'بله';
														|it = 'Sì';
														|pl = 'Yes';
														|tr = 'Evet'"));
				Buttons.Add(DialogReturnCode.Cancel,NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
				ShowQueryBox(Notification, QueryText, Buttons, 60, DialogReturnCode.Cancel);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifyLaborCosts(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Source", TaskLine.Task);
	FormParameters.Insert("SourceID", TaskLine.TaskID);
	FormParameters.Insert("SourceType", TaskLine.TaskType);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork",
		FormParameters, TaskLine.TaskID);
	
EndProcedure

&AtClient
Procedure AskAuthorQuestion(Command)
	
	If Items.Tasks.CurrentData = Undefined Then
		Return;
	ElsIf Items.Tasks.CurrentData.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", Items.Tasks.CurrentData.TaskID);
	FormParameters.Insert("type", Items.Tasks.CurrentData.TaskType);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Khác';
												|ru = 'Иное';
												|en = 'Other'; fa = 'سایر';
												|it = 'Altro';
												|pl = 'Other';
												|tr = 'Diğer'"));
	FormParameters.Insert("TypeOfQuestionID", "Иное"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, Items.Tasks.CurrentData.TaskID);
	
EndProcedure

&AtClient
Procedure AgreeOnPostponement(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", TaskLine.TaskID);
	FormParameters.Insert("type", TaskLine.TaskType);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Gia hạn';
												|ru = 'Перенос срока';
												|en = 'Postponement'; fa = 'Postponement';
												|it = 'Spostamento termine';
												|pl = 'Przeniesienie terminu';
												|tr = 'Tarihin ertelenmesi'"));
	FormParameters.Insert("TypeOfQuestionID", "ПереносСрока"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, TaskLine.TaskID);
	
EndProcedure

&AtClient
Procedure OpenCard(Command)
	
	String = Items.ApplicationTree.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(String.Ref) Then // the IP object.
		ShowValue(, String.Ref);
		
	Else // Object BEFORE.
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			String.Type,
			String.ID,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenItemForViewing(Command)
	
	String = Items.ApplicationTree.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(String.Ref) Then
		ShowValue(, String.Ref);
		
	ElsIf String.Type = "DMFile" Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			String.ID,
			String.Description,
			String.Extension,
			UUID);
	Else
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			String.Type,
			String.ID,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenMainItem(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		MainSubjectType,
		MainSubjectID,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ExecuteTaskFirst(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(TaskLine.Subjects, "ID", "Description") Then
		Return;
	EndIf;
	
	ResultID = TaskLine.ResultID;
	Process_Type = TaskLine.Process_Type;
	RoutePoint = TaskLine.RoutePointBriefly;
	RequireExecutionResult = False;
	MessageToUserText = "";
	
	If Process_Type = "DMBusinessProcessRegistration" And RoutePoint = "Зарегистрировать" Then //@NON-NLS-2
		For Each SubjectLine In TaskLine.Subjects Do
			If (Not MultiSubjectivityIsAvailable Or SubjectLine.RoleOfSubject = "Основной")
				And IntegrationWith1CDocumentManagementClientServer.IsDocument(SubjectLine.Type) Then //@NON-NLS-1
				IntegrationWith1CDocumentManagementServerCall.RegisterDocumentIfNecessary(
					SubjectLine.Type,
					SubjectLine.ID);
			EndIf;
		EndDo;
	EndIf;
	
	FormParameters = New Structure("ID, type, taskID", TaskLine.Process_ID, Process_Type, TaskLine.TaskID);
	Notification = New CallbackDescription("ExecuteTaskFirstCompletion", ThisObject);
	
	If TaskLine.Process_Type = "DMBusinessProcessInvitation"
			And ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-2
		QueryText = NStr("vi = 'Có những người tham gia chưa chấp nhận lời mời.
			|Sau khi xác nhận, họ sẽ bị loại khỏi danh sách người tham gia. Tiếp tục?';
			|ru = 'Есть не принявшие приглашения участники.
			|При подтверждении они будут исключены из списка участников. Продолжить?';
			|en = 'Some participants did not accept the invitation. 
			|They will be excluded from the list of participants upon confirmation. Continue?'; fa = 'Some participants did not accept the invitation. 
			|They will be excluded from the list of participants upon confirmation. Continue?';
			|it = 'Vi sono partecipanti che non hanno accettato l''invito.
			|In caso di conferma, saranno esclusi dall''elenco dei partecipanti. Continuare?';
			|pl = 'Są uczestnicy, którzy nie przyjęli zaproszenie.
			|Przy potwierdzeniu zostano oni wykluczeni z listy uczestników. Kontynuować?';
			|tr = 'Daveti kabul etmeyen katılımcılar var.
			|Onaylandıktan sonra, katılımcı listesinden çıkarılacaklardır. Devam et?'");
		IntegrationWith1CDocumentManagementClient.ShowQuestionYesNo(
			Notification,
			QueryText,
			IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
		Return;
	EndIf;
	
	If Process_Type = "DMBusinessProcessConsideration" And RoutePoint = "Рассмотреть" Then //@NON-NLS-2
		RequireExecutionResult = True;
		MessageToUserText = NStr("vi = 'Chưa điền trường ""Khuyến nghị""';
								|ru = 'Поле ""Резолюция"" не заполнено';
								|en = '""Resolution"" field is not filled in'; fa = '""Resolution"" field is not filled in';
								|it = 'Campo ""Risoluzione"" non compilato';
								|pl = 'Nie wypełniono pola ""Rezolucja""';
								|tr = '""Karar"" alanı doldurulamadı'");
	ElsIf Process_Type = "DMBusinessProcessIssuesSolution" And RoutePoint = "РассмотрениеИнициатором" //@NON-NLS-2
			And TypeOfQuestionID = "Иное" Then //@NON-NLS-2 @NON-NLS-3
		RequireExecutionResult = True;
	EndIf;
	
	// Does the type of task require opening a complex form?
	If Process_Type = "DMBusinessProcessInvitation" And RoutePoint = "Ознакомиться"
			And (ResultID = "НеПринятоОбязательнымиУчастниками"
				Or ResultID = "НеПринятоВсемиУчастниками") Then //@NON-NLS-2 @NON-NLS-3 @NON-NLS-4
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessInvitation",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		If RequireExecutionResult And Not ValueIsFilled(Comment) Then
			ClearMessages();
			Items.Comment.MarkIncomplete = True;
			CommonClient.MessageToUser(
				?(ValueIsFilled(MessageToUserText),
					MessageToUserText,
					NStr("vi = 'Chưa điền trường ""Ghi chú""';
						|ru = 'Поле ""Комментарий"" не заполнено';
						|en = 'The field ""Comment"" is required'; fa = 'The field ""Comment"" is required';
						|it = 'Campo ""Commento"" non compilato';
						|pl = 'Pole ""Uwagi"" nie jest wypełnione';
						|tr = '""Yorum"" alanı doldurulmadı'")),,
				"Comment");
			Return;
		Else
			ExecuteTask(1);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskSecond(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(TaskLine.Subjects, "ID", "Description") Then
		Return;
	EndIf;
	
	ResultID = TaskLine.ResultID;
	Process_Type = TaskLine.Process_Type;
	RoutePoint = TaskLine.RoutePointBriefly;
	RequireExecutionResult = False;
	MessageToUserText = "";
	
	// Does the task type require input of the execution result?
	If (Process_Type = "DMBusinessProcessApproval" And RoutePoint = "Согласовать")
			Or (Process_Type = "DMBusinessProcessInvitation" And RoutePoint = "Пригласить") Then //@NON-NLS-2 @NON-NLS-4
		RequireExecutionResult = True;
	ElsIf TaskLine.TaskType = "DMBusinessProcessIssuesSolutionTaskAnswer" Then
		RequireExecutionResult = True;
		MessageToUserText = NStr("vi = 'Khi gửi đi làm rõ, cần điền ghi chú.';
								|ru = 'При отправке на уточнение требуется указать комментарий.';
								|en = 'Indicate comment when send to clarification.'; fa = 'Indicate comment when send to clarification.';
								|it = 'È necessario indicare il commento all''invio in precisazione.';
								|pl = 'Przy wysyłce do uściślenia należy wprowadzić uwagi.';
								|tr = 'Kesinleştirme için gönderirken, yorum belirtmek gerekiyor.'");
	ElsIf Process_Type = "DMBusinessProcessConfirmation" And RoutePoint = "Утвердить" Then //@NON-NLS-2
		RequireExecutionResult = True;
		MessageToUserText = NStr("vi = 'Hãy chỉ ra nguyên nhân sai lệch của chứng từ';
								|ru = 'Укажите причину отклонения документа';
								|en = 'Specify reason for document rejection'; fa = 'Specify reason for document rejection';
								|it = 'Specificare il motivo per cui il documento viene rigettato';
								|pl = 'Wskaż powód odrzucenia dokumentu';
								|tr = 'Belgenin reddedilme nedenini belirt'");
	ElsIf Process_Type = "DMBusinessProcessRegistration" And RoutePoint = "Зарегистрировать" Then //@NON-NLS-2
		RequireExecutionResult = True;
		MessageToUserText = NStr("vi = 'Hãy chỉ ra nguyên nhân từ chối đăng ký';
								|ru = 'Укажите причину отказа в регистрации';
								|en = 'Indicate reason of registration cancel'; fa = 'Indicate reason of registration cancel';
								|it = 'Indicare motivo di rifiuto nella registrazione';
								|pl = 'Podaj przyczynę odrzucenia rejestracji';
								|tr = 'Kayıt reddetme nedenini belirt'");
	ElsIf Process_Type = "DMBusinessProcessIssuesSolution" And RoutePoint = "РассмотрениеИнициатором"
			And TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-2 @NON-NLS-3
		RequireExecutionResult = True;
	EndIf;
	
	FormParameters = New Structure("ID, type, taskID", TaskLine.Process_ID, Process_Type, TaskLine.TaskID);
	Notification = New CallbackDescription("ExecuteTaskSecondCompletion", ThisObject);
	
	// Does the type of task require opening a complex form?
	If Process_Type = "DMBusinessProcessApproval" And RoutePoint = "Ознакомиться" Then //@NON-NLS-2
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessApproval",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessConfirmation" And RoutePoint = "Ознакомиться" Then //@NON-NLS-2
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessAdoption",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessRegistration" And RoutePoint = "Ознакомиться" Then //@NON-NLS-2
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessRegistration",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessInvitation" And RoutePoint = "Ознакомиться"
			And ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-2 @NON-NLS-3
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessInvitation",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		
		If RequireExecutionResult And Not ValueIsFilled(Comment) Then
			ClearMessages();
			Items.Comment.MarkIncomplete = True;
			CommonClient.MessageToUser(
				?(ValueIsFilled(MessageToUserText),
					MessageToUserText,
					NStr("vi = 'Chưa điền trường ""Ghi chú""';
						|ru = 'Поле ""Комментарий"" не заполнено';
						|en = 'The field ""Comment"" is required'; fa = 'The field ""Comment"" is required';
						|it = 'Campo ""Commento"" non compilato';
						|pl = 'Pole ""Uwagi"" nie jest wypełnione';
						|tr = '""Yorum"" alanı doldurulmadı'")),,
				"Comment");
			Return;
		Else
			ExecuteTask(2);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskThird(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(TaskLine.Subjects, "ID", "Description") Then
		Return;
	EndIf;
	
	Process_Type = TaskLine.Process_Type;
	RoutePoint = TaskLine.RoutePointBriefly;
	RequireExecutionResult = False;
	
	// Does the task type require input of the execution result?
	If Process_Type = "DMBusinessProcessApproval" And RoutePoint = "Согласовать" Then //@NON-NLS-2
		RequireExecutionResult = True;
	EndIf;
	
	If RequireExecutionResult
			And Not ValueIsFilled(Comment) Then
		ClearMessages();
		Items.Comment.MarkIncomplete = True;
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ghi chú""';
				|ru = 'Поле ""Комментарий"" не заполнено';
				|en = 'The field ""Comment"" is required'; fa = 'The field ""Comment"" is required';
				|it = 'Campo ""Commento"" non compilato';
				|pl = 'Pole ""Uwagi"" nie jest wypełnione';
				|tr = '""Yorum"" alanı doldurulmadı'"),,
			"Comment");
		Return;
	Else
		ExecuteTask(3);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddSubject(Command)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.TaskID = "" Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("AddSubjectCompletion",
		ThisObject,
		New Structure("TaskLine", TaskLine));
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OwnerSForm", ThisObject);
	NotificationParameters.Insert("Presentation", TaskLine.Task);
	NotificationParameters.Insert("OwnerID", TaskLine.TaskID);
	NotificationParameters.Insert("OwnerType", TaskLine.TaskType);
	NotificationParameters.Insert("RoleOfSubject", "Вспомогательный"); //@NON-NLS-2
	NotificationParameters.Insert("CallbackDescription", CallbackDescription);
	
	DescriptionOfTypeSelectionNotification = New CallbackDescription(
		"AddSubjectAfterTypeSelection",
		IntegrationWith1CDocumentManagementClient,
		NotificationParameters);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectSubjectType",
		New Structure("Process_Type", TaskLine.Process_Type),
		IntegrationWith1CDocumentManagementClient,,,,
		DescriptionOfTypeSelectionNotification,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// The handler for the "Add a Completion" notification.
//
// Parameters:
//   Added_Items - Array of Structure:
//     * SubjectOf - String
//     * SubjectOfID - String
//     * SubjectOfType - String
//     * Presentation - String
//     * Extension - String
//     * RoleOfSubject - String
//   HandlerParameters - Structure:
//     * TaskLine - FormDataTreeItem:
//         ** Description - String
//         ** Subjects - FormDataCollection
//
&AtClient
Procedure AddSubjectCompletion(Added_Items, HandlerParameters) Export
	
	If Added_Items = Undefined Or Added_Items.Count() = 0 Then
		Return;
	EndIf;
	
	For Each ItemDescription In Added_Items Do
		NewItem_ = HandlerParameters.TaskLine.Subjects.Add();
		NewItem_.ItemName = "";
		NewItem_.Description = ItemDescription.Presentation;
		NewItem_.ID = ItemDescription.SubjectOfID;
		NewItem_.Type = ItemDescription.SubjectOfType;
		NewItem_.RoleOfSubject = ItemDescription.RoleOfSubject;
		If ItemDescription.Property("Extension") Then
			NewItem_.Extension = ItemDescription.Extension;
		EndIf;
		NewItem_.DeletionAvailable = True;
		NewItem_.IsBeingEdited = False;
		NewItem_.EditedByCurUser = False;
	EndDo;
	
	HandlerParameters.TaskLine.DateOfReceiptOfDetailedInformation = Date(1, 1, 1);
	
	TaskParameters_ = New Structure;
	TaskParameters_.Insert("ID", HandlerParameters.TaskLine.TaskID);
	TaskParameters_.Insert("Type", HandlerParameters.TaskLine.TaskType);
	TaskParameters_.Insert("Process_Type", HandlerParameters.TaskLine.Process_Type);
	TaskParameters_.Insert("Comment", Comment);
	TaskParameters_.Insert("MultiSubjectivityIsAvailable", MultiSubjectivityIsAvailable);
	
	RecordTaskItems(TaskParameters_, HandlerParameters.TaskLine.Subjects);
	
	UpdateDetailedInformation(HandlerParameters.TaskLine);
	
EndProcedure

&AtClient
Procedure DeleteSubject(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.ID = "" Then
		Return;
	EndIf;
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.TaskID = "" Then
		Return;
	EndIf;
	
	ItemToDeletion = TaskLine.Subjects.FindRows(New Structure("ID, Type",
		CurrentData.ID,
		CurrentData.Type));
	
	If ItemToDeletion.Count() = 0 Then
		Return;
	EndIf;
	
	TaskLine.Subjects.Delete(ItemToDeletion[0]);
	TaskLine.DateOfReceiptOfDetailedInformation = Date(1, 1, 1);
	
	TaskParameters_ = New Structure;
	TaskParameters_.Insert("ID", TaskLine.TaskID);
	TaskParameters_.Insert("Type", TaskLine.TaskType);
	TaskParameters_.Insert("Process_Type", TaskLine.Process_Type);
	TaskParameters_.Insert("Comment", Comment);
	TaskParameters_.Insert("MultiSubjectivityIsAvailable", MultiSubjectivityIsAvailable);
	
	RecordTaskItems(TaskParameters_, TaskLine.Subjects);
	
	UpdateDetailedInformation(TaskLine);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.Type <> "DMFile" Then
		Return;
	EndIf;
	If CurrentData.IsBeingEdited And Not CurrentData.EditedByCurUser Then
		ShowMessageBox(, NStr("vi = 'Hiện tại, tệp này do người sử dụng khác chỉnh sửa.';
								|ru = 'Этот файл сейчас редактируется другим пользователем.';
								|en = 'The file is being edited by another user now.'; fa = 'The file is being edited by another user now.';
								|it = 'Un altro utente sta modificando adesso questo file.';
								|pl = 'Ten plik jest teraz edytowany przez innego użytkownika.';
								|tr = 'Bu dosya şu anda başka kullanıcı tarafından düzenleniyor.'"));
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Command", "Edit");
	CallbackDescription = New CallbackDescription(
		"EditingCommandsCompletion",
		ThisObject,
		NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		CurrentData.ID,
		CurrentData.Presentation,
		CurrentData.Extension,
		UUID,
		False,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined
			Or CurrentData.Type <> "DMFile"
			Or Not CurrentData.EditedByCurUser Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Command", "EndEdit");
	CallbackDescription = New CallbackDescription(
		"EditingCommandsCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
		CurrentData.ID,
		CurrentData.Presentation,
		CurrentData.Extension,
		UUID,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined
			Or CurrentData.Type <> "DMFile"
			Or Not CurrentData.EditedByCurUser Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Command", "CancelEdit");
	CallbackDescription = New CallbackDescription(
		"EditingCommandsCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
		CurrentData.ID,
		CallbackDescription,,
		UUID);
	
EndProcedure

// General completion of editing commands.
&AtClient
Procedure EditingCommandsCompletion(Result, Var_Parameters) Export
	
	SubjectLine = FindItemString(ApplicationTree.GetItems(), Result.ID, Result.Type);
	
	If SubjectLine = Undefined Then
		Return;
	EndIf;
	
	If Var_Parameters.Command = "Edit" Then
		SubjectLine.IsBeingEdited = True;
		SubjectLine.EditedByCurUser = True;
	Else // "Finish editing" Or "Cancel editing".
		SubjectLine.IsBeingEdited = False;
		SubjectLine.EditedByCurUser = False;
	EndIf;
	ApplicationTreeOnActivateRow(Undefined);
	
EndProcedure

&AtClient
Procedure CreateSubtask(Command)
	
	Modified = False;
	
	CurrentData = Items.Tasks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.Group Then
		Return;
	EndIf;
	
	SubjectOfSubtask = Undefined;
	Applications = ApplicationTree.GetItems();
	
	For Each Item In Applications Do
		If Item.RoleOfSubject = "Основной" Then //@NON-NLS-1
			SubjectOfSubtask = New Structure;
			SubjectOfSubtask.Insert("name", Item.Description);
			SubjectOfSubtask.Insert("id", Item.ID);
			SubjectOfSubtask.Insert("type", Item.Type);
			Break;
		EndIf;
	EndDo;
	
	If SubjectOfSubtask = Undefined And Applications.Count() > 0 Then
		SubjectOfSubtask = New Structure;
		SubjectOfSubtask.Insert("name", Applications[0].Description);
		SubjectOfSubtask.Insert("id", Applications[0].ID);
		SubjectOfSubtask.Insert("type", Applications[0].Type);
	EndIf;
	
	MainTask = New Structure;
	MainTask.Insert("name", CurrentData.Task);
	MainTask.Insert("id", CurrentData.TaskID);
	MainTask.Insert("type", CurrentData.TaskType);
	
	Notification = New CallbackDescription("CreateSubtaskCompletion", ThisForm);
	IntegrationWith1CDocumentManagementClient.CreateBusinessProcess(SubjectOfSubtask, MainTask, Notification);
	
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

&AtClientAtServerNoContext
Function FindItemString(TreeRows, SubjectOfID, SubjectOfType)
	
	FoundRow = Undefined;
	
	For Each SubjectLine In TreeRows Do
		
		If SubjectOfID = SubjectLine.ID And SubjectOfType = SubjectLine.Type Then
			FoundRow = SubjectLine;
		Else
			If TypeOf(SubjectLine) = Type("FormDataTreeItem") Then
				FileStrings = SubjectLine.GetItems();
			Else
				FileStrings = SubjectLine.Rows;
			EndIf;
			For Each FileString In FileStrings Do
				If SubjectOfID = FileString.ID And SubjectOfType = FileString.Type Then
					FoundRow = FileString;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If FoundRow <> Undefined Then
			Break;
		EndIf;
		
	EndDo;
	
	Return FoundRow;
	
EndFunction

&AtClient
Procedure CreateSubtaskCompletion(Result, NotificationParameters) Export
	
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
	GroupingMode = ColumnName;
	MarkGroupingMode();
	GroupByColumnOnServer();
	ExpandTaskGroups();
	
EndProcedure

&AtClient
Procedure MarkGroupingMode()
	
	Items.ListGroupByAuthor.Check = (GroupingMode = "Author");
	Items.ListGroupByImportance.Check = (GroupingMode = "StringImportance");
	Items.ListGroupByRoutePoint.Check = (GroupingMode = "RoutePoint");
	Items.GroupListByArtist.Check = (GroupingMode = "Performer");
	Items.ListGroupGroupByNoGroup.Check = (GroupingMode = "");
	
EndProcedure

&AtServer
Procedure GroupByColumnOnServer()
	
	If Not ValueIsFilled(TaskTableLink) Then
		Return;
	EndIf;
	
	CurrentTask = Items.Tasks.CurrentRow;
	NextTask = Undefined;
	PreviousTask = Undefined;
	If CurrentTask <> Undefined Then
		CurTaskLine = Tasks.FindByID(CurrentTask);
		If CurTaskLine = Undefined Then
			CurrentTask = Undefined;
		Else
			If CurTaskLine.TaskID <> "" Then
				NextTaskLine = Tasks.FindByID(CurrentTask + 1);
				If NextTaskLine <> Undefined Then
					NextTask = NextTaskLine.TaskID;
				EndIf;
				PreviousTaskLine = Tasks.FindByID(CurrentTask - 1);
				If PreviousTaskLine <> Undefined Then
					PreviousTask = PreviousTaskLine.TaskID;
				EndIf;
			EndIf;
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
			GroupLines = TaskTable_.FindRows(
				New Structure(GroupingMode, DimensionString[GroupingMode]));
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
	SetCurrentRow(CurrentTask, NextTask, PreviousTask);
	
EndProcedure

&AtServer
Procedure SetCurrentRow(CurrentTaskID, NextTaskID, PreviousTaskID)
	
	TaskArray = New Array;
	TaskArray.Add(CurrentTaskID);
	If NextTaskID <> Undefined Then
		TaskArray.Add(NextTaskID);
	EndIf;
	If PreviousTaskID <> Undefined Then
		TaskArray.Add(PreviousTaskID);
	EndIf;
	
	For Each TaskID In TaskArray Do
		If ValueIsFilled(TaskID) Then
			If Items.Tasks.Representation = TableRepresentation.List Then
				TaskLines_ = Tasks.GetItems();
				For Each TaskLine In TaskLines_ Do
					If TaskLine.TaskID = TaskID Then
						Items.Tasks.CurrentRow = TaskLine.GetID();
						Return;
					EndIf;
				EndDo;
			Else
				// Grouping.
				For Each TreeGroup In Tasks.GetItems() Do
					TaskLines_ = TreeGroup.GetItems();
					For Each TaskLine In TaskLines_ Do
						If TaskLine.TaskID = TaskID Then
							Items.Tasks.CurrentRow = TaskLine.GetID();
							Return;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
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
		MarkGroupingMode();
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
	
	Title = NStr("vi = 'Document Management: Nhiệm vụ đến';
				|ru = 'Документооборот: Задачи мне';
				|en = 'Document Management: My tasks'; fa = 'مدیریت اسناد: وظایف من';
				|it = 'Документооборот: Задачи мне';
				|pl = 'Document Management: zadania dla mnie';
				|tr = 'İş akışı: Benim için görevler'");
	
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
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			
			FormProcessedSuccessfully = False;
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.MainGroup2.Visible = False;
			
		Else
			
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.MainGroup2.Visible = True;
			UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername;
			
			// Tasks.
			If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
				Items.MainGroup2.Enabled = True;
				TaskFunctionalityIsAvailable = True;
				TimekeepingFunctionalityIsAvailable =
					IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3")
						And GetFunctionalOption("UseDailyReports1CDocumentManagement");
				FileCaptureIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
				MultiSubjectivityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.3.1");
				RefreshTasksListOnServer();
			Else
				Items.MainGroup2.Enabled = False;
				TaskFunctionalityIsAvailable = False;
				TimekeepingFunctionalityIsAvailable = False;
				DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(
					ThisObject);
			EndIf;
			Items.SwitchTiming.Enabled = TimekeepingFunctionalityIsAvailable;
			Items.SpecifyLaborCosts.Enabled = TimekeepingFunctionalityIsAvailable;
			// Solving issues.
			If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
				Items.AskAuthorQuestion.Visible = False;
			EndIf;
			// Mail.
			If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
				Items.CreateEmail.Visible = False;
			EndIf;
			// Acceptance of tasks for execution.
			If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
				Items.AcceptForExecution.Visible = False;
				Items.TasksContextMenuAcceptForExecution.Visible = False;
			EndIf;
			// Canceling the acceptance of tasks for execution.
			If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
				PostponementFunctionalityIsAvailable = True;
			Else
				Items.CancelAcceptForExecution.Visible = False;
				Items.TasksContextMenuCancelAcceptForExecution.Visible = False;
			EndIf;
			SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			AddWorkToDailyReportWhenCompletingTask =
				SettingsOf1CDocumentManagement.AddWorkToDailyReportWhenCompletingTask;
			ActualTaskExecutor = SettingsOf1CDocumentManagement.ActualTaskExecutor;
			If ActualTaskExecutor <> "taskPerformer" Then
				CurCurrentUserAndEmployees =
					IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					ThisObject, CurCurrentUserAndEmployees[0], "CurrentUser");
			EndIf;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
				ErrorInfo(), "3.0.1.1") Then
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
	
	DesignFontElement = ConditionalAppearanceItem.Appearance.Items.Find("Font");
	DesignFontElement.Value = Metadata.StyleItems.FontTasksNotReceivedForExecution.Value;
	DesignFontElement.Use = True;
	
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

&AtServer
Procedure AcceptTasksForExecution()
	
	Modified = False;
	RowsArray = Items.Tasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArrayBefore = New Array;
		For Each Item In RowsArray Do
			TaskLine = Tasks.FindByID(Item);
			If ValueIsFilled(TaskLine.TaskID) Then
				TaskArrayBefore.Add(TaskLine.TaskID);
			EndIf;
		EndDo;
		If TaskArrayBefore.Count() > 0 Then
			Try
				Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
				IntegrationWith1CDocumentManagement.AcceptTaskForExecution(Proxy, TaskArrayBefore);
			Except
				If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
						ErrorInfo(), "3.0.1.1") Then
					ProcessFormAccordingToServiceVersion();
				EndIf;
				Return;
			EndTry;
			UpdateTaskListPartiallyOnServer();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CancelAcceptTasksForExecution()
	
	Modified = False;
	RowsArray = Items.Tasks.SelectedRows;
	If RowsArray.Count() <> 0 Then
		TaskArrayBefore = New Array;
		For Each Item In RowsArray Do
			TaskLine = Tasks.FindByID(Item);
			If ValueIsFilled(TaskLine.TaskID) Then
				TaskArrayBefore.Add(TaskLine.TaskID);
			EndIf;
		EndDo;
		If TaskArrayBefore.Count() > 0 Then
			Try
				Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
				IntegrationWith1CDocumentManagement.CancelAcceptTasksForExecution(Proxy, TaskArrayBefore);
			Except
				If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
						ErrorInfo(), "3.0.1.1") Then
					ProcessFormAccordingToServiceVersion();
				EndIf;
				Return;
			EndTry;
			UpdateTaskListPartiallyOnServer();
		EndIf;
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
	
	CurrentTask = Items.Tasks.CurrentRow;
	NextTask = Undefined;
	PreviousTask = Undefined;
	If CurrentTask <> Undefined Then
		CurTaskLine = Tasks.FindByID(CurrentTask);
		If CurTaskLine = Undefined Then
			CurrentTask = Undefined;
		Else
			If CurTaskLine.TaskID <> "" Then
				NextTaskLine = Tasks.FindByID(CurrentTask + 1);
				If NextTaskLine <> Undefined Then
					NextTask = NextTaskLine.TaskID;
				EndIf;
				PreviousTaskLine = Tasks.FindByID(CurrentTask - 1);
				If PreviousTaskLine <> Undefined Then
					PreviousTask = PreviousTaskLine.TaskID;
				EndIf;
			EndIf;
			CurrentTask = CurTaskLine.TaskID;
		EndIf;
	EndIf;
	
	Tree = FormAttributeToValue("Tasks");
	
	TaskTable_ = New ValueTable;
	For Each Column In Tree.Columns Do
		TaskTable_.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	For Each XDTOTask In XDTOTasks Do
		TaskLine = TaskTable_.Add();
		TaskLine.Subjects = TableOfTaskItems();
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
				FillPropertyValues(ElementString, String);
				TreeRow.Rows.Sort("TaskDueDate DESC, Task");
			EndDo;
		EndDo;
		Tree.Rows.Sort("Task");
	Else
		Items.Tasks.Representation = TableRepresentation.List;
		For Each String In TaskTable_ Do
			TreeRow = Tree.Rows.Add();
			FillPropertyValues(TreeRow, String);
		EndDo;
		Tree.Rows.Sort("TaskDueDate DESC, Task");
	EndIf;
	
	ValueToFormAttribute(Tree, "Tasks");
	
	TaskTableLink = PutToTempStorage(TaskTable_, UUID);
	
	SetCurrentRow(CurrentTask, NextTask, PreviousTask);
	
	FillInNumberOfIssuesFields();
	
EndProcedure

// Decomposes the full file name into its components.
//
// Parameters:
//   TaskLine - Structure:
//     * Subjects - ValueTable:
//         ** Description - String
//         ** ID - String
//         ** Type - String
//         ** RoleOfSubject - String
//         ** Mandatory - Boolean
//         ** Extension - String
//         ** LinkedObjectType - String
//         ** LinkedObjectID - String
//         ** ItemName - String
//         ** DeletionAvailable - Boolean
//         ** IsBeingEdited - Boolean
//         ** EditedByCurUser - Boolean
//
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
	TaskLine.RoutePointBriefly = IntegrationWith1CDocumentManagement.ShortRoutePointName(
		XDTOTask.parentBusinessProcess.objectID.type,
		XDTOTask.businessProcessStep);
	TaskLine.TaskDueDate = XDTOTask.dueDate;
	TaskLine.Saved = XDTOTask.beginDate;
	TaskLine.Author = XDTOTask.author.name;
	TaskLine.AuthorID = XDTOTask.author.objectID.ID;
	TaskLine.AuthorType = XDTOTask.author.objectID.type;
	TaskLine.AcceptedForExecution = XDTOTask.accepted;
	TaskLine.ExecutionResult = XDTOTask.executionComment;
	
	If XDTOTask.Properties().Get("iterationNumber") = Undefined Then
		TaskLine.IterationNumber = 0;
	Else
		TaskLine.IterationNumber = XDTOTask.iterationNumber;
	EndIf;
	
	ArtistXDTO = XDTOTask.performer;
	If IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			ArtistXDTO.user, "Performer")
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			ArtistXDTO.role, "Performer")
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
		XDTOTask.parentBusinessProcess, "Process_");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
		XDTOTask, "Task");
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "state") Then
		TaskLine.State = ?(XDTOTask.parentBusinessProcess.state = Undefined,
			"Активен",
			XDTOTask.parentBusinessProcess.state.name); //@NON-NLS-1
	ElsIf TaskLine.RoutePointBriefly = "Ознакомиться"
			And (TaskLine.Process_Type = "DMBusinessProcessApproval"
				Or TaskLine.Process_Type = "DMBusinessProcessConfirmation"
				Or TaskLine.Process_Type = "DMBusinessProcessConsideration"
				Or TaskLine.Process_Type = "DMBusinessProcessRegistration"
				Or TaskLine.Process_Type = "DMBusinessProcessInvitation") Then //@NON-NLS-1
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		XDTOProcess = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			TaskLine.Process_Type,
			TaskLine.Process_ID,
			"state");
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOProcess, "executionResult") Then
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
				XDTOProcess.executionResult, "Result");
		EndIf;
		
		TaskLine.State = ?(XDTOProcess.state = Undefined, "Активен", XDTOProcess.state.name); //@NON-NLS-1
	Else
		TaskLine.State = "Активен"; //@NON-NLS-1
	EndIf;
	
	// Fill in the details specific to the type of process.
	If TaskLine.Process_Type = "DMBusinessProcessApproval" Then
		FillInTheDataACApproval(TaskLine, XDTOTask);
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessConfirmation" Then
		FillInTheDataForTheConfirmation(TaskLine, XDTOTask);
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessConsideration" Then
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessOrder" Then
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessPerformance" Then
		
	ElsIf TaskLine.Process_Type = "DMComplexBusinessProcess" Then
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessRegistration" Then
		FillInACData(TaskLine, XDTOTask);
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessAcquaintance" Then
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessIssuesSolution" Then
		FillInBPDataSolvingQuestions(TaskLine, XDTOTask);
		
	ElsIf TaskLine.Process_Type = "DMBusinessProcessInvitation" Then
		FillInDataACInvitation(TaskLine, XDTOTask);
		
	EndIf;
	
	// We will get the subject(s) of the problem.
	TaskLine.Subjects.Clear();
	If TaskLine.Process_Type = "DMBusinessProcessIssuesSolution" Then
		
		For Each XDTOFile In XDTOTask.files Do
			SubjectLine = TaskLine.Subjects.Add();
			SubjectLine.ItemName = XDTOFile.name;
			SubjectLine.RoleOfSubject = "Вспомогательный"; //@NON-NLS-1
			SubjectLine.DeletionAvailable = True;
			SubjectLine.Description = XDTOFile.name;
			SubjectLine.ID = XDTOFile.objectID.ID;
			SubjectLine.Type = XDTOFile.objectID.type;
			SubjectLine.Extension = XDTOFile.extension;
			If FileCaptureIsAvailable Then
				SubjectLine.IsBeingEdited = XDTOFile.editing;
				If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "editingUser") Then
					CurCurrentUserAndEmployees =
						IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
					SubjectLine.EditedByCurUser =
						IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
							XDTOFile.editingUser.objectID.ID,
							XDTOFile.editingUser.objectID.type,
							CurCurrentUserAndEmployees);
				EndIf;
			EndIf;
		EndDo;
		
	ElsIf MultiSubjectivityIsAvailable Then
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "targets") Then
			For Each SubjectLineXDTO In XDTOTask.targets.items Do
				SubjectLine = TaskLine.Subjects.Add();
				SubjectLine.ItemName = SubjectLineXDTO.name;
				SubjectLine.RoleOfSubject = SubjectLineXDTO.role.objectID.ID;
				SubjectLine.DeletionAvailable = SubjectLineXDTO.allowDeletion;
				SubjectXDTO = SubjectLineXDTO.target;
				SubjectLine.Description = SubjectXDTO.name;
				SubjectLine.ID = SubjectXDTO.objectID.ID;
				SubjectLine.Type = SubjectXDTO.objectID.type;
				If SubjectLine.Type = "DMFile" // The service returns the extension for files.
						And IntegrationWith1CDocumentManagementCore.PropertySet(SubjectXDTO, "extension") Then
					SubjectLine.Extension = SubjectXDTO.extension;
					If FileCaptureIsAvailable Then
						SubjectLine.IsBeingEdited = SubjectXDTO.editing;
						If IntegrationWith1CDocumentManagementCore.PropertySet(SubjectXDTO, "editingUser") Then
							CurCurrentUserAndEmployees =
								IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
							SubjectLine.EditedByCurUser =
								IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
									SubjectXDTO.editingUser.objectID.ID,
									SubjectXDTO.editingUser.objectID.type,
									CurCurrentUserAndEmployees);
						EndIf;
					EndIf;
				EndIf;
				If IntegrationWith1CDocumentManagementCore.PropertySet(SubjectXDTO, "externalObject") Then // the IP object.
					SubjectLine.LinkedObjectID = SubjectXDTO.externalObject.ID;
					SubjectLine.LinkedObjectType = SubjectXDTO.externalObject.type;
				EndIf;
			EndDo;
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "fillableTargets") Then
			For Each SubjectLineXDTO In XDTOTask.fillableTargets.items Do
				SubjectLine = TaskLine.Subjects.Add();
				SubjectLine.ItemName = NStr("vi = 'chưa được nhập';
											|ru = 'не введен';
											|en = 'not entered'; fa = 'not entered';
											|it = 'не введен';
											|pl = 'not entered';
											|tr = 'girilmedi'");
				SubjectLine.RoleOfSubject = SubjectLineXDTO.role.objectID.ID;
				SubjectLine.Mandatory = SubjectLineXDTO.requiredField;
				SubjectLine.DeletionAvailable = SubjectLineXDTO.allowDeletion;
				SubjectLine.Description = SubjectLineXDTO.name;
			EndDo;
		EndIf;
		
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "target") Then
		
		SubjectXDTO = XDTOTask.target;
		SubjectLine = TaskLine.Subjects.Add();
		SubjectLine.Description = SubjectXDTO.name;
		SubjectLine.ID = SubjectXDTO.objectID.ID;
		SubjectLine.Type = SubjectXDTO.objectID.type;
		SubjectLine.DeletionAvailable = False;
		SubjectLine.IsBeingEdited = False;
		SubjectLine.EditedByCurUser = False;
		
	EndIf;
	
EndProcedure

// Initializes the task items table.
//
// Returns:
//   ValueTable:
//     * Description - String
//     * ID - String
//     * Type - String
//     * RoleOfSubject - String
//     * Mandatory - Boolean
//     * Extension - String
//     * LinkedObjectType - String
//     * LinkedObjectID - String
//     * ItemName - String
//     * DeletionAvailable - Boolean
//     * IsBeingEdited - Boolean
//     * EditedByCurUser - Boolean
//
&AtServer
Function TableOfTaskItems()
	
	Subjects = New ValueTable;
	Subjects.Columns.Add("Description", New TypeDescription("String"));
	Subjects.Columns.Add("ID", New TypeDescription("String"));
	Subjects.Columns.Add("Type", New TypeDescription("String"));
	Subjects.Columns.Add("RoleOfSubject", New TypeDescription("String"));
	Subjects.Columns.Add("Mandatory", New TypeDescription("Boolean"));
	Subjects.Columns.Add("Extension", New TypeDescription("String"));
	Subjects.Columns.Add("LinkedObjectType", New TypeDescription("String"));
	Subjects.Columns.Add("LinkedObjectID", New TypeDescription("String"));
	Subjects.Columns.Add("ItemName", New TypeDescription("String"));
	Subjects.Columns.Add("DeletionAvailable", New TypeDescription("Boolean"));
	Subjects.Columns.Add("IsBeingEdited", New TypeDescription("Boolean"));
	Subjects.Columns.Add("EditedByCurUser", New TypeDescription("Boolean"));
	
	Return Subjects;
	
EndFunction

&AtServer
Procedure FillInTheDataACApproval(TaskLine, XDTOTask)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "executionResult") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.parentBusinessProcess.executionResult, "Result");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheDataForTheConfirmation(TaskLine, XDTOTask)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "executionResult") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.parentBusinessProcess.executionResult, "Result");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "processType") Then
		TaskLine.ThisIsSigning = (XDTOTask.parentBusinessProcess.processType.objectID.ID = "Подписание"); //@NON-NLS-1
	Else
		TaskLine.ThisIsSigning = False;
	EndIf;
	
	If TaskLine.ThisIsSigning Then
		If TaskLine.ResultID = "Утверждено" Then //@NON-NLS-1
			TaskLine.Result = NStr("vi = 'Đã ký';
									|ru = 'Подписано';
									|en = 'Signed'; fa = 'امضاشده';
									|it = 'Firmato';
									|pl = 'Podpisano';
									|tr = 'İmzalandı'");
		Else
			TaskLine.Result = NStr("vi = 'Chưa ký';
									|ru = 'Не подписано';
									|en = 'Not signed'; fa = 'Not signed';
									|it = 'Non firmato';
									|pl = 'Nie podpisano';
									|tr = 'İmzalanmadı'");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBPDataSolvingQuestions(TaskLine, XDTOTask)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "issueType") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.issueType, "TypeOfQuestion");
	ElsIf IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		TaskLine.TypeOfQuestion = NStr("vi = 'Khác';
										|ru = 'Иное';
										|en = 'Other'; fa = 'سایر';
										|it = 'Altro';
										|pl = 'Other';
										|tr = 'Diğer'");
		TaskLine.TypeOfQuestionID = "Иное"; //@NON-NLS-1
		TaskLine.TypeOfQuestionType = "DMIssueType";
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "issueTask") Then
		TaskLine.OldDeadline = XDTOTask.parentBusinessProcess.issueTask.dueDate;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "newDueDate") Then
		TaskLine.NewTerm = XDTOTask.parentBusinessProcess.newDueDate;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask, "issueTask") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.issueTask, "SubjectOfConsideration");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.issueTask.parentBusinessProcess, "BusinessProcessOfSubjectOfConsideration");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInACData(TaskLine, XDTOTask)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "executionResult") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.parentBusinessProcess.executionResult, "Result");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataACInvitation(TaskLine, XDTOTask)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "activityVenue") Then
		TaskLine.VenueOfInvitation = XDTOTask.parentBusinessProcess.activityVenue;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "activityBegin") Then
		TaskLine.InvitationStartDate = XDTOTask.parentBusinessProcess.activityBegin;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOTask.parentBusinessProcess, "invitationResult") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,
			XDTOTask.parentBusinessProcess.invitationResult, "Result");
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshTasksListOnServer()
	
	Try
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		XDTOTasks = GetIssues(Proxy, False);
		FillInTheTaskList(XDTOTasks);
	Except
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
				ErrorInfo(), "3.0.1.1") Then
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
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
				ErrorInfo(), "3.0.1.1") Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		Return;
	EndTry;
	
	TaskTable_ = GetFromTempStorage(TaskTableLink); // ValueTable
	TasksToDelete = TaskTable_.UnloadColumn("TaskID");
	
	For Each XDTOTask In XDTOTasks Do
		TaskLines = TaskTable_.FindRows(New Structure("TaskID", XDTOTask.object.objectID.ID));
		If TaskLines.Count() > 0 Then
			TaskLine = TaskLines[0];
			TasksToDelete.Delete(TasksToDelete.Find(XDTOTask.object.objectID.ID));
		Else
			TaskLine = TaskTable_.Add();
			TaskLine.Subjects = TableOfTaskItems();
		EndIf;
		FillInXDTOTaskLine(TaskLine, XDTOTask.object);
	EndDo;
	
	For Each TaskToDelete In TasksToDelete Do
		TaskLines = TaskTable_.FindRows(New Structure("TaskID", TaskToDelete));
		If TaskLines.Count() > 0 Then
			TaskTable_.Delete(TaskLines[0]);
		EndIf;
	EndDo;
	
	TaskTableLink = PutToTempStorage(TaskTable_, UUID);
	GroupByColumnOnServer();
	
	FillInNumberOfIssuesFields();

EndProcedure

&AtServer
Procedure FillInNumberOfIssuesFields()
	
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
	
	AllTasks = TaskTable_.FindRows(New Structure("Group", False));
	TotalTasks = AllTasks.Count();
	OverdueTasks_ = Overdue;
	NewTasks = NotAccepted;
	
	Title =  StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Document Management: nhiệm vụ đến (Mới: %1 / Đã quá hạn: %2 / Tổng số: %3)';
			|ru = 'Документооборот: Задачи мне (Новых: %1 / Просроченных: %2 / Всего: %3)';
			|en = 'Document Management: My tasks (New: %1 / Overdue: %2 / Total: %3)'; fa = 'Document Management: My tasks (New: %1 / Overdue: %2 / Total: %3)';
			|it = 'Документооборот: Задачи мне (Новых: %1 / Просроченных: %2 / Всего: %3)';
			|pl = 'Document Management: My tasks (New: %1 / Overdue: %2 / Total: %3)';
			|tr = 'İş akışı: Görevlerim(Yeni: %1 /Vadesi geçmiş: %2 /Toplam: %3)'"),
		NewTasks, OverdueTasks_, TotalTasks);
	
EndProcedure

&AtClient
Procedure Attachable_GetDetailedInformation()
	
	UpdateDetailedInformation(Items.Tasks.CurrentData);
	
EndProcedure

&AtClient
Procedure UpdateDetailedInformation(TaskLine)
	
	Comment = "";
	
	If TaskLine <> Undefined
			And Not TaskLine.Group
			And ValueIsFilled(TaskLine.TaskID) Then
		
		// We will collect the already known details of the task to obtain detailed information on the server.
		TaskDetails__ = New Structure;
		TaskDetails__.Insert("Task", TaskLine.Task);
		TaskDetails__.Insert("TaskType", TaskLine.TaskType);
		TaskDetails__.Insert("TaskID", TaskLine.TaskID);
		TaskDetails__.Insert("Process_", TaskLine.Process_);
		TaskDetails__.Insert("Process_Type", TaskLine.Process_Type);
		TaskDetails__.Insert("Process_ID", TaskLine.Process_ID);
		TaskDetails__.Insert("ThisIsSigning", TaskLine.ThisIsSigning);
		TaskDetails__.Insert("LongDesc", TaskLine.LongDesc);
		TaskDetails__.Insert("Performer", TaskLine.Performer);
		TaskDetails__.Insert("Executed", TaskLine.Executed);
		TaskDetails__.Insert("RoutePointBriefly", TaskLine.RoutePointBriefly);
		TaskDetails__.Insert("IterationNumber", TaskLine.IterationNumber);
		TaskDetails__.Insert("TypeOfQuestionID", TaskLine.TypeOfQuestionID);
		TaskDetails__.Insert("ResultID", TaskLine.ResultID);
		TaskDetails__.Insert("State", TaskLine.State);
		Subjects = New Array;
		For Each SubjectLine In TaskLine.Subjects Do
			SubjectOf = New Structure;
			SubjectOf.Insert("ItemName", SubjectLine.ItemName);
			SubjectOf.Insert("RoleOfSubject", SubjectLine.RoleOfSubject);
			SubjectOf.Insert("Mandatory", SubjectLine.Mandatory);
			SubjectOf.Insert("Description", SubjectLine.Description);
			SubjectOf.Insert("Type", SubjectLine.Type);
			SubjectOf.Insert("ID", SubjectLine.ID);
			SubjectOf.Insert("Extension", SubjectLine.Extension);
			SubjectOf.Insert("LinkedObjectType", SubjectLine.LinkedObjectType);
			SubjectOf.Insert("LinkedObjectID", SubjectLine.LinkedObjectID);
			SubjectOf.Insert("DeletionAvailable", SubjectLine.DeletionAvailable);
			SubjectOf.Insert("IsBeingEdited", SubjectLine.IsBeingEdited);
			SubjectOf.Insert("EditedByCurUser", SubjectLine.EditedByCurUser);
			Subjects.Add(SubjectOf);
		EndDo;
		TaskDetails__.Insert("Subjects", Subjects);
		
		UpdatingCurLine = (TaskLine = Items.Tasks.CurrentData);
		TaskDetailInformation = Undefined;
		
		// Perhaps there is no cache or it is outdated.
		If Not ValueIsFilled(TaskLine.DateOfReceiptOfDetailedInformation)
				Or CurrentDate() - TaskLine.DateOfReceiptOfDetailedInformation > 5 * 60
				Or DetailedInformationAboutTasks.Get(TaskLine.TaskID) = Undefined Then // The use is justified: duration calculation.
			
			TaskDetailInformation = GetDetailedInformationOnServer(TaskDetails__);
			If TaskDetailInformation = Undefined Or TaskLine = Undefined Then
				Return;
			EndIf;
			DetailedInformationAboutTasks.Insert(TaskLine.TaskID, TaskDetailInformation);
			TaskLine.DateOfReceiptOfDetailedInformation = CurrentDate(); // The use is justified: duration calculation.
			
		EndIf;
		
		If UpdatingCurLine And TaskDetailInformation = Undefined Then
			TaskDetailInformation = DetailedInformationAboutTasks.Get(TaskLine.TaskID);
		EndIf;
		
		SavedComment = SavedComments.Get(TaskLine.TaskID);
		If SavedComment = Undefined Then
			Comment = TaskLine.ExecutionResult;
		Else
			Comment = SavedComment;
		EndIf;
		Process_ = TaskLine.Process_;
		Process_Type = TaskLine.Process_Type;
		Process_ID = TaskLine.Process_ID;
		Author = TaskLine.Author;
		AuthorID = TaskLine.AuthorID;
		AuthorType = TaskLine.AuthorType;
		TypeOfQuestion = TaskLine.TypeOfQuestion;
		TypeOfQuestionID = TaskLine.TypeOfQuestionID;
		TypeOfQuestionType = TaskLine.TypeOfQuestionType;
		ExecutionResult = TaskLine.Result;
		ExecutionResultType = TaskLine.ResultType;
		ExecutionResultID = TaskLine.ResultID;
		SubjectOfConsiderationType = TaskLine.SubjectOfConsiderationType;
		SubjectOfConsiderationID = TaskLine.SubjectOfConsiderationID;
		BusinessProcessOfSubjectOfConsiderationType = TaskLine.BusinessProcessOfSubjectOfConsiderationType;
		BusinessProcessOfSubjectOfConsiderationID = TaskLine.BusinessProcessOfSubjectOfConsiderationID;
		OldDeadline = TaskLine.OldDeadline;
		NewTerm = TaskLine.NewTerm;
		VenueOfInvitation = TaskLine.VenueOfInvitation;
		InvitationStartDate = TaskLine.InvitationStartDate;
		
		UpdateTaskPresentationOnServer(TaskDetails__, TaskDetailInformation);
		
		TreeItems = ApplicationTree.GetItems();
		For Each TopLevelTreeElement In TreeItems Do
			Items.ApplicationTree.Expand(TopLevelTreeElement.GetID(), True);
		EndDo;
		
	Else
		
		UpdateTaskPresentationOnServer(Undefined, Undefined);
		
	EndIf;
	
EndProcedure

// Returns detailed information about the task.
//
// Parameters:
//   TaskDetails__ - Structure:
//     * TypeOfQuestionID - String
//     * Executed - Boolean
//     * Task - String
//     * TaskID - String
//     * TaskType - String
//     * Performer - String
//     * IterationNumber - Number
//     * LongDesc - String
//     * Subjects - Array of Structure:
//         ** ID - String
//         ** DeletionAvailable - Boolean
//         ** ItemName - String
//         ** Description - String
//         ** Extension - String
//         ** IsBeingEdited - Boolean
//         ** EditedByCurUser - Boolean
//         ** RoleOfSubject - String
//         ** Mandatory - Boolean
//         ** LinkedObjectID - String
//         ** LinkedObjectType - String
//         ** Type - String
//     * Process_ - String
//     * Process_ID - String
//     * Process_Type - String
//     * ResultID - String
//     * State - String
//     * RoutePointBriefly - String
//     * ThisIsSigning - Boolean
//
// Returns:
//   Structure:
//     * HTMLPresentation - String
//     * FunctionalityNotAvailable - Boolean
//     * ExecuteTaskFirst - String
//     * ExecuteTaskSecond - String
//     * ExecuteTaskThird - String
//     * TextColorFirst - Color
//     * TextColorSecond - Color
//     * TextColorThird - Color
//     * TimekeepingEnabled - Boolean
//     * StartDateOfTimekeeping - Date
//     * EndDateOfTimekeeping - Date
//     * Subjects - Array of Structure:
//         ** Description - String
//         ** ID - String
//         ** Type - String
//         ** Extension - String
//         ** RoleOfSubject - String
//         ** Mandatory - Boolean
//         ** CommandPageKey - String
//         ** Ref - AnyRef
//         ** DeletionAvailable - Boolean
//         ** IsBeingEdited - Boolean
//         ** EditedByCurUser - Boolean
//         ** Picture - Number
//         ** Presentation - String
//         ** Files - Array of Structure:
//              *** Description - String
//              *** Type - String
//              *** ID - String
//              *** Extension - String
//              *** Presentation - String
//              *** Picture - Number
//              *** DeletionAvailable - Boolean
//              *** IsBeingEdited - Boolean
//              *** EditedByCurUser - Boolean
//         ** CreationCommands - Array of Structure:
//              *** Type - String
//              *** Presentation - String
//
&AtServer
Function GetDetailedInformationOnServer(TaskDetails__)
	
	Result = New Structure;
	
	Result.Insert("HTMLPresentation", "");
	Result.Insert("FunctionalityNotAvailable", False);
	Result.Insert("ExecuteTaskFirst", "");
	Result.Insert("ExecuteTaskSecond", "");
	Result.Insert("ExecuteTaskThird", "");
	Result.Insert("TextColorFirst", New Color);
	Result.Insert("TextColorSecond", New Color);
	Result.Insert("TextColorThird", New Color);
	Result.Insert("TimekeepingEnabled", False);
	Result.Insert("StartDateOfTimekeeping", Date(1, 1, 1));
	Result.Insert("EndDateOfTimekeeping", Date(1, 1, 1));
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Subjects = New Array;
	
	For Each SubjectLine In TaskDetails__.Subjects Do
		
		SubjectOf = New Structure;
		SubjectOf.Insert("Description", SubjectLine.Description);
		SubjectOf.Insert("ID", SubjectLine.ID);
		SubjectOf.Insert("Type", SubjectLine.Type);
		SubjectOf.Insert("Extension", SubjectLine.Extension);
		SubjectOf.Insert("RoleOfSubject", SubjectLine.RoleOfSubject);
		SubjectOf.Insert("Mandatory", SubjectLine.Mandatory);
		SubjectOf.Insert("CommandPageKey", "");
		SubjectOf.Insert("Ref", Undefined);
		SubjectOf.Insert("DeletionAvailable", SubjectLine.DeletionAvailable);
		SubjectOf.Insert("IsBeingEdited", SubjectLine.IsBeingEdited);
		SubjectOf.Insert("EditedByCurUser", SubjectLine.EditedByCurUser);
		
		Files = New Array;
		
		If SubjectLine.Type = "DMFile" Then
			// A multi-subject web service reports the extension along with a collection of items.
			If Not MultiSubjectivityIsAvailable Then
				// we will get the extension by calling the service.
				Try
					XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
						Proxy,
						SubjectLine.Type,
						SubjectLine.ID,
						"extension");
				Except
					If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
							ErrorInfo(), "3.0.1.1") Then
						ProcessFormAccordingToServiceVersion();
					EndIf;
					Return Undefined;
				EndTry;
				SubjectOf.Extension = XDTODataObject.extension;
			EndIf;
			SubjectOf.Insert("Picture",
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(SubjectOf.Extension));
			SubjectOf.Insert("Presentation", SubjectLine.Description);
			
		Else
			// A different type of object that may have attached files.
			If MultiSubjectivityIsAvailable Then
				SubjectOf.Insert("Picture", IntegrationWith1CDocumentManagementClientServer.ImageBySubjectRole(
					SubjectLine.RoleOfSubject));
			Else
				// The role of the subject is unknown, let it be the main one.
				SubjectOf.Insert("Picture", IntegrationWith1CDocumentManagementClientServer.ImageBySubjectRole("Main"));
			EndIf;
			// We will get an idea from the name of the object and its name in the process.
			Presentation = String(SubjectOf.Description);
			If ValueIsFilled(SubjectLine.ItemName) Then
				Presentation = Presentation + " (" + SubjectLine.ItemName + ")";
			EndIf;
			If SubjectLine.Type = "" And SubjectLine.RoleOfSubject = "ToBeFilledIn" Then //@NON-NLS-1
				Presentation = Presentation + NStr("vi = ', Được điền';
													|ru = ', Заполняемый';
													|en = ', To be filled'; fa = ', To be filled';
													|it = ', Заполняемый';
													|pl = ', To be filled';
													|tr = ', Doldurulan'");
			Else
				Presentation = Presentation + NStr("vi = ', văn bản DM';
													|ru = ', документ ДО';
													|en = ', DI document'; fa = ', DI document';
													|it = ', documento DM';
													|pl = ', dokument DM';
													|tr = ', İş Akışı belgesi'");
			EndIf;
			// Find the related object.
			If ValueIsFilled(SubjectLine.LinkedObjectID) Then
				LinkedObject = New Structure("ID, type",
					SubjectLine.LinkedObjectID,
					SubjectLine.LinkedObjectType);
				ArrayOfLinksToExternalObjects = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(
					LinkedObject);
				SubjectOf.Ref = ?(ArrayOfLinksToExternalObjects.Count() > 0,
					ArrayOfLinksToExternalObjects[0],
					Undefined);
			EndIf;
			If ValueIsFilled(SubjectOf.Ref) Then
				// A situation when there are rights to an object in the DO, but not in the IP, should not lead to an exception
				// when selecting tasks. If an exception occurs, we will get a view from BEFORE, and the user
				// will see a "Violation of access rights" only when trying to open the item.
				Try
					If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
						ObjectPresentation = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = ', đối tượng %1';
								|ru = ', объект %1';
								|en = ', object %1'; fa = ', object %1';
								|it = ', oggetto %1';
								|pl = ', obiekt %1';
								|tr = ', nesne %1'"), AbbreviatedNameOfConfiguration);
					Else
						ObjectPresentation = NStr("vi = ', đối tượng IS';
													|ru = ', объект ИС';
													|en = ', IS object'; fa = ', IS object';
													|it = ', oggetto di Sistema Informativo';
													|pl = ', obiekt Systemu Zintegrowanego';
													|tr = ', Entegre Sistemi nesnesi'");
					EndIf;
					SubjectOf.Insert("Presentation", String(SubjectOf.Ref) + ObjectPresentation);
				Except
					SubjectOf.Insert("Presentation", Presentation);
					WriteLogEvent(
						IntegrationWith1CDocumentManagementCore.EventLogEventName(
							NStr("vi = 'Lỗi khi nhận trình bày đối tượng liên kết';
								|ru = 'Ошибка при получении представления связанного объекта';
								|en = 'An error occurred when receiving presentation of the linked object'; fa = 'An error occurred when receiving presentation of the linked object';
								|it = 'Errore alla ricezione della presentazione dell''oggetto collegato';
								|pl = 'Błąd przy otrzymaniu prezentacji powiązanego obiektu';
								|tr = 'İlgili nesnenin sunumu alınırken hata'",
								Common.DefaultLanguageCode())),
						EventLogLevel.Error,,
						SubjectOf.Ref,
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				EndTry;
			Else
				SubjectOf.Insert("Presentation", Presentation);
			EndIf;
			If ValueIsFilled(SubjectLine.ID) Then
				// We will get the attached files.
				Try
					ListOfFiles = IntegrationWith1CDocumentManagementCoreServerCall.FilesByOwner(
						SubjectLine.ID,
						SubjectLine.Description,
						SubjectLine.Type);
				Except
					If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
							ErrorInfo(), "3.0.1.1") Then
						ProcessFormAccordingToServiceVersion();
					EndIf;
					Return Undefined;
				EndTry;
				For Each XDTOFile In ListOfFiles.files Do
					File = New Structure;
					File.Insert("Description", XDTOFile.name);
					File.Insert("Type", XDTOFile.objectID.type);
					File.Insert("ID", XDTOFile.objectID.ID);
					File.Insert("Extension", XDTOFile.extension);
					File.Insert("Presentation", File.Description);
					
					DeletionMark = False;
					If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "deletionMark") Then
						DeletionMark = XDTOFile.deletionMark;
					EndIf;
					File.Insert("Picture",
						IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
							XDTOFile.extension,
							DeletionMark));
					
					File.Insert("DeletionAvailable", False);
					If FileCaptureIsAvailable Then
						File.Insert("IsBeingEdited", XDTOFile.editing);
						If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "editingUser") Then
							CurCurrentUserAndEmployees =
								IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
							EditedByCurUser =
								IntegrationWith1CDocumentManagementCoreServerCall.FileIsBeingEditedByCurUser(
									XDTOFile.editingUser.objectID.ID,
									XDTOFile.editingUser.objectID.type,
									CurCurrentUserAndEmployees);
							File.Insert("EditedByCurUser", EditedByCurUser);
						EndIf;
					EndIf;
					Files.Add(File);
				EndDo;
			EndIf;
		EndIf;
		
		SubjectOf.Insert("Files", Files);
		
		// We will get the items of the "Create based on" submenu.
		TeamStructure = IntegrationWith1CDocumentManagement.StructureOfCreateAndOpenCommands(
			SubjectLine.Type,
			SubjectLine.ID);
		If TeamStructure <> Undefined Then
			CreationCommands = Undefined;
			If TeamStructure.Property("CreationCommands", CreationCommands)
					And CreationCommands.Count() > 0 Then
				PageKey = CommandPageKey(SubjectLine.Type, TeamStructure.DocumentKindID);
				SubjectOf.Insert("CommandPageKey", PageKey);
				SubjectOf.Insert("CreationCommands", CreationCommands);
			EndIf;
		EndIf;
		
		Subjects.Add(SubjectOf);
		
	EndDo;
	
	Result.Insert("Subjects", Subjects);
	
	// We will get an HTML representation.
	FullTaskDescriptionLine = TaskDetails__.LongDesc;
	
	If ValueIsFilled(TaskDetails__.Process_Type) And ValueIsFilled(TaskDetails__.Process_ID) Then
		
		Try
			ProcessObject_ = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				TaskDetails__.Process_Type,
				TaskDetails__.Process_ID,
				"executionComment");
		Except
			If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
					ErrorInfo(), "3.0.1.1") Then
				ProcessFormAccordingToServiceVersion();
			EndIf;
			Return Undefined;
		EndTry;
		
		If ProcessObject_.Properties().Get("executionComment") <> Undefined Then
			If Not IsBlankString(ProcessObject_.executionComment) Then
				If Not IsBlankString(FullTaskDescriptionLine) Then
					FullTaskDescriptionLine = FullTaskDescriptionLine + Chars.LF + Chars.LF;
				EndIf;
				FullTaskDescriptionLine = FullTaskDescriptionLine
					+ Chars.LF + NStr("vi = 'Lịch sử thực hiện:';
										|ru = 'История выполнения:';
										|en = 'Task history:'; fa = 'Task history:';
										|it = 'Cronologia dell''esecuzione:';
										|pl = 'Historia wykonania:';
										|tr = 'Yürütme tarihçesi:'")
					+ Chars.LF + "------------------------------------"
					+ Chars.LF + ProcessObject_.executionComment;
			EndIf;
		EndIf;
		
	EndIf;
	
	FullTaskDescriptionLine = StrReplace(FullTaskDescriptionLine, Chars.LF, "<br>");
	HTMLText = "<html>
		|<head>
		| <style>
		|  h1 {
		|   font-size: 10pt;
		|	 font-family:Arial;
		|  }
		|  p {
		|   font-size: 10pt;
		|	 font-family:Arial;
		|  }
		|	BODY {
		|	 margin: 0px;
		|	 padding: 3px;
		|	}
		| </style>
		|</head>
		|<body scroll=auto>";
	HTMLText = HTMLText + "<h1>" + TaskDetails__.Task + "</h1>";
	If ValueIsFilled(TaskDetails__.Performer) Then
		If TrimAll(TaskDetails__.Performer) <> TrimAll(UserName) Then
			ArtistDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Người nhận: %1';
					|ru = 'Кому: %1';
					|en = 'To: %1'; fa = 'To: %1';
					|it = 'A chi: %1';
					|pl = 'Do kogo: %1';
					|tr = 'Kime: %1'"),
				TaskDetails__.Performer);
			HTMLText = HTMLText + "<p>" + ArtistDescription + "</p>";
		EndIf;
	EndIf;
	If TaskDetails__.IterationNumber <> 0 Then
		TaskIteration = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Vòng lặp: %1';
				|ru = 'Цикл: %1';
				|en = 'Cycle: %1'; fa = 'Cycle: %1';
				|it = 'Ciclo: %1';
				|pl = 'Cykl: %1';
				|tr = 'Döngü: %1'"),
			TaskDetails__.IterationNumber);
			
		HTMLText = HTMLText + "<p>" + TaskIteration + "</p>";
	EndIf;
	If ValueIsFilled(FullTaskDescriptionLine) Then
		HTMLText = HTMLText + "<p>" + FullTaskDescriptionLine + "</p>";
	Else
		HTMLText = HTMLText + "<p><FONT color=""#C0C0C0"">"
			+ NStr("vi = 'Nhiệm vụ không có mô tả.';
					|ru = 'У задачи нет описания.';
					|en = 'The task has no description.'; fa = 'The task has no description.';
					|it = 'Non vi è descrizione del compito.';
					|pl = 'Zadanie nie ma opisu.';
					|tr = 'Görevin ayrıntısı mevcut değil.'") + "</FONT></p>";
	EndIf;
	HTMLText = HTMLText + "</body></html>";
	Result.HTMLPresentation = HTMLText;
	
	// Colors and titles of execution buttons.
	ButtonStructure = IntegrationWith1CDocumentManagement.TaskExecutionStructure(TaskDetails__);
	ButtonColorNames = New Structure("ExecuteTaskFirst, ExecuteTaskSecond, ExecuteTaskThird",
		"TextColorFirst", "TextColorSecond", "TextColorThird");
	For Each ButtonNameColor In ButtonColorNames Do
		Result[ButtonNameColor.Key] = ButtonStructure[ButtonNameColor.Key];
		Result[ButtonNameColor.Value] = ButtonStructure[ButtonNameColor.Value];
	EndDo;
	Result.FunctionalityNotAvailable = ButtonStructure.FunctionalityNotAvailable;
	
	// Timing.
	If TimekeepingFunctionalityIsAvailable Then
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetChronometrationSettingsRequest");
		ListOfObjects = Query.objects; // XDTOList
		
		ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			TaskDetails__.TaskID,
			TaskDetails__.TaskType);
		ListOfObjects.Add(ObjectID);
		Try
			ServiceResponse = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		Except
			If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
					ErrorInfo(), "3.0.1.1") Then
				ProcessFormAccordingToServiceVersion();
			EndIf;
			Return Undefined;
		EndTry;
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ServiceResponse);
		TimingParameters = ServiceResponse.settings[0];
		Result.TimekeepingEnabled = TimingParameters.chronometrationOn;
		Result.StartDateOfTimekeeping = TimingParameters.beginDate;
		Result.EndDateOfTimekeeping = TimingParameters.endDate;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateCommandsAboveTaskDescription(TaskDetailInformation)
	
	CommandPageKey = "";
	Items.TeamPageGroup.CurrentPage.Visible = False;
	
	// Each page has its own timekeeping button.
	If TaskDetailInformation = Undefined Then
		SwitchTimekeepingElement = Items.SwitchTiming;
		SwitchTimekeepingElement.Enabled = False;
	Else
		If TaskDetailInformation.Subjects.Count() = 1 Then
			CurSubject = TaskDetailInformation.Subjects[0];
		Else
			CurSubject = Undefined;
			For Each SubjectOf In TaskDetailInformation.Subjects Do
				If SubjectOf.Type <> "DMFile" Then
					CurSubject = SubjectOf;
					Break;
				EndIf;
			EndDo;
		EndIf;
		If CurSubject <> Undefined Then
			CommandPageKey = CurSubject.CommandPageKey;
			NameOfNewPage = "GroupTeamPage" + CommandPageKey;
			// We build a submenu only if necessary.
			If Items.Find(NameOfNewPage) = Undefined Then
				BuildCreationSubmenuBasedOn();
			EndIf;
			SwitchTimekeepingElement = Items["SwitchTiming" + CommandPageKey];
			SwitchTimekeepingElement.Enabled = True;
			If TaskDetailInformation.TimekeepingEnabled Then
				SwitchTimekeepingElement.Check = True;
			Else
				SwitchTimekeepingElement.Check = False;
			EndIf;
		EndIf;
	EndIf;
	
	Items.TeamPageGroup.CurrentPage = Items["GroupTeamPage" + CommandPageKey];
	Items.TeamPageGroup.CurrentPage.Visible = True;
	
EndProcedure

&AtServer
Procedure UpdateTaskPresentationOnServer(TaskDetails__, TaskDetailInformation)
	
	Items.Comment.MarkIncomplete = False;
	Items.GroupDetailsOfReview.Visible = False;
	Items.ExecutionResult.Visible = False;
	Items.InvitationStartDate.Visible = False;
	Items.VenueOfInvitation.Visible = False;
	Items.Comment.Visible = True;
	Items.Comment.InputHint = NStr("vi = 'Ghi chú';
									|ru = 'Комментарий';
									|en = 'Comment'; fa = 'توضیحات';
									|it = 'Commento';
									|pl = 'Comment';
									|tr = 'Yorum'");
	
	UpdateCommandsAboveTaskDescription(TaskDetailInformation);
	
	If TaskDetails__ = Undefined Then
		Items.Open.Enabled = False;
		Items.TasksContextMenuOpenProcess.Enabled = False;
		Items.ButtonPageExecutionGroup.CurrentPage = Items.GroupExecutionZero;
		Comment = "";
		HTMLPresentation = "";
		ApplicationTree.GetItems().Clear();
		For Each CreateButton In Items.TheCreateGroupOnTheBasisOf.ChildItems Do
			If Left(CreateButton.CommandName, 8) = "Create_" Then
				CreateButton.Visible = False;
			EndIf;
		EndDo;
		Return;
	Else
		Items.Open.Enabled = True;
		Items.TasksContextMenuOpenProcess.Enabled = True;
	EndIf;
	
	If TaskDetailInformation = Undefined Then
		Return;
	EndIf;
	
	If TaskDetailInformation.FunctionalityNotAvailable Then
		DisplayInformationAboutUnavailabilityOfTask();
		Return;
	Else
		Items.ExecutionResultText.Visible = False;
		Items.AttentionDecoration2.Visible = False;
	EndIf;
	
	// Colors and titles of execution buttons.
	ButtonColorNames = New Structure("ExecuteTaskFirst, ExecuteTaskSecond, ExecuteTaskThird",
		"TextColorFirst", "TextColorSecond", "TextColorThird");
	If ValueIsFilled(TaskDetailInformation.ExecuteTaskThird) Then
		NumberOfButtons = "Three";
	ElsIf ValueIsFilled(TaskDetailInformation.ExecuteTaskSecond) Then
		NumberOfButtons = "Two";
	ElsIf ValueIsFilled(TaskDetailInformation.ExecuteTaskFirst) Then
		NumberOfButtons = "One";
	Else
		NumberOfButtons = "Zero";
	EndIf;
	For Each ButtonNameColor In ButtonColorNames Do
		If ValueIsFilled(TaskDetailInformation[ButtonNameColor.Key]) Then
			Button = Items[NumberOfButtons + ButtonNameColor.Key];
			Button.Title = TaskDetailInformation[ButtonNameColor.Key];
			Button.TextColor = TaskDetailInformation[ButtonNameColor.Value];
		EndIf;
	EndDo;
	Items.ButtonPageExecutionGroup.CurrentPage = Items["GroupExecution" + NumberOfButtons];
	
	HTMLPresentation = TaskDetailInformation.HTMLPresentation;
	
	MainSubjectType = "";
	MainSubjectID = "";
	
	// Fill in the application tree.
	Subjects = ApplicationTree.GetItems();
	Subjects.Clear();
	For Each SubjectOf In TaskDetailInformation.Subjects Do
		If SubjectOf.RoleOfSubject = "Основной" And MainSubjectID = "" Then //@NON-NLS-1
			MainSubjectType = SubjectOf.Type;
			MainSubjectID = SubjectOf.ID;
		EndIf;
		ItemString = Subjects.Add();
		FillPropertyValues(ItemString, SubjectOf);
		Files = ItemString.GetItems();
		Files.Clear();
		For Each File In SubjectOf.Files Do
			FileRow = Files.Add();
			FillPropertyValues(FileRow, File);
		EndDo;
	EndDo;
	
	Items.OpenMainItem.Enabled = ValueIsFilled(MainSubjectType)
		And ValueIsFilled(MainSubjectID);
	
	// For a task without objects, we will show the scenery.
	ThereAreItems = (TaskDetailInformation.Subjects.Count() > 0);
	If ThereAreItems Then
		If Items.ApplicationGroup.CurrentPage = Items.PageNoItems Then
			Items.ApplicationGroup.CurrentPage = Items.PageHasItems;
		EndIf;
	Else
		If Items.ApplicationGroup.CurrentPage = Items.PageHasItems Then
			Items.ApplicationGroup.CurrentPage = Items.PageNoItems;
		EndIf;
	EndIf;
	
	// Fill in the details specific to the type of process.
	If TaskDetails__.Process_Type = "DMBusinessProcessApproval" Then
		UpdatePresentationOfACTaskApproval(TaskDetails__);
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessConfirmation" Then
		UpdatePresentationOfACTaskStatement(TaskDetails__);
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessConsideration" Then
		UpdateUAVTaskPresentation(TaskDetails__);
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessOrder" Then
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessPerformance" Then
		
	ElsIf TaskDetails__.Process_Type = "DMComplexBusinessProcess" Then
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessRegistration" Then
		UpdatePSUTaskPresentation(TaskDetails__);
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessAcquaintance" Then
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessIssuesSolution" Then
		UpdatePresentationOfBPProblemSolvingQuestions(TaskDetails__);
		
	ElsIf TaskDetails__.Process_Type = "DMBusinessProcessInvitation" Then
		UpdateTaskPresentationOfPSU(TaskDetails__);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationOfACTaskApproval(TaskDetails__)
	
	If TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
		Items.Comment.Visible = False;
		Items.ExecutionResult.Visible = True;
		If TaskDetails__.ResultID = "НеСогласовано" Then //@NON-NLS-1
			Items.ExecutionResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Else
			Items.ExecutionResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationOfACTaskStatement(TaskDetails__)
	
	If TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
		Items.Comment.Visible = False;
		Items.ExecutionResult.Visible = True;
		If TaskDetails__.ResultID = "НеУтверждено" Then //@NON-NLS-1
			Items.ExecutionResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Else
			Items.ExecutionResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUAVTaskPresentation(TaskDetails__)
	
	If TaskDetails__.RoutePointBriefly = "Рассмотреть" Then //@NON-NLS-1
		Items.Comment.InputHint = NStr("vi = 'Khuyến nghị của bạn';
										|ru = 'Ваша резолюция';
										|en = 'Your resolution'; fa = 'Your resolution';
										|it = 'La vostra risoluzione';
										|pl = 'Twoja rezolucja';
										|tr = 'Sizin karar'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePSUTaskPresentation(TaskDetails__)
	
	If TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
		Items.Comment.Visible = False;
		Items.ExecutionResult.Visible = True;
		If TaskDetails__.ResultID = "НеЗарегистрировано" Then //@NON-NLS-1
			Items.ExecutionResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Else
			Items.ExecutionResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePresentationOfBPProblemSolvingQuestions(TaskDetails__)
	
	// Consideration of the postponement of the deadline.
	If TaskDetails__.RoutePointBriefly = "РассмотрениеИнициатором"
			And TaskDetails__.TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1 @NON-NLS-2
		Items.GroupDetailsOfReview.Visible = True;
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
			Items.DurationOfTransfer.Visible = True;
			DurationOfTransfer = IntegrationWith1CDocumentManagementServerCall.SignatureOfPostponementDuration(
				Author,
				AuthorID,
				AuthorType,
				OldDeadline,
				NewTerm);
		Else
			Items.DurationOfTransfer.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTaskPresentationOfPSU(TaskDetails__)
	
	If TaskDetails__.RoutePointBriefly = "Пригласить" Then //@NON-NLS-1
		Items.InvitationStartDate.Visible = True;
		Items.VenueOfInvitation.Visible = True;
	ElsIf TaskDetails__.RoutePointBriefly = "Ознакомиться" Then //@NON-NLS-1
		Items.Comment.Visible = False;
		Items.ExecutionResult.Visible = True;
		If TaskDetails__.ResultID = "НеПринятоОбязательнымиУчастниками"
				Or TaskDetails__.ResultID = "НеПринятоВсемиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
			Items.ExecutionResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Else
			Items.ExecutionResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SwitchTimingServer(TaskType, TaskID, SubjectOfID, TaskDetailInformation)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMSetChronometrationSettingsRequest");
	ListOfObjects = Query.objects; // XDTOList
	
	ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, TaskID, TaskType);
	ListOfObjects.Add(ObjectID);
	
	Try
		ServiceResponse = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	Except
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
				ErrorInfo(), "3.0.1.1") Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		Return;
	EndTry;
	
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ServiceResponse);
	
	TimingParameters = ServiceResponse.settings[0];
	TaskDetailInformation.TimekeepingEnabled = TimingParameters.chronometrationOn;
	TaskDetailInformation.StartDateOfTimekeeping = TimingParameters.beginDate;
	TaskDetailInformation.EndDateOfTimekeeping = TimingParameters.endDate;
	
	UpdateCommandsAboveTaskDescription(TaskDetailInformation);
	
EndProcedure

&AtClient
Procedure SwitchTimingCompletion(Result, NotificationParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
		
	Records = IntegrationWith1CDocumentManagementServerCall.SwitchTimeTrackingBy1CDocumentManagementObjects(
		NotificationParameters.ActiveEntries);
	
	For Each Record In Records Do
		RecordingAlertSettings = New Structure;
		RecordingAlertSettings.Insert("name", Record.Source);
		RecordingAlertSettings.Insert("ID", Record.SourceID);
		RecordingAlertSettings.Insert("type", Record.SourceType);
		Notify("Recording_1CDocumentManagementTimeSpent", RecordingAlertSettings, Record.SourceID);
	EndDo;
	
	TaskDetailInformation = NotificationParameters.TaskDetailInformation;
	SwitchTimingServer(NotificationParameters.TaskType, NotificationParameters.TaskID,
		NotificationParameters.SubjectOfID, TaskDetailInformation);
	If TaskDetailInformation.TimekeepingEnabled Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
				|ru = 'Включен хронометраж по ""%1""';
				|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
				|it = 'Crono-analisi attivata per ""%1""';
				|pl = 'Chronometraż jest włączony według ""%1""';
				|tr = '""%1"" ile kronometre etkin'"), String(NotificationParameters.Task));
		Status(Text);
	EndIf;
	DetailedInformationAboutTasks.Insert(NotificationParameters.TaskID, TaskDetailInformation);
		
EndProcedure

&AtServer
Function CommandPageKey(Type, KindID)
	
	If ValueIsFilled(KindID) Then
		SafeID = StrReplace(StrReplace(StrReplace(KindID, "_", ""), " ", ""), "-", "");
		Return Type + "_" + SafeID;
	Else
		Return Type;
	EndIf;
	
EndFunction

&AtServer
Procedure BuildCreationSubmenuBasedOn()
	
	// Let's collect the filling sources (for creating submenu pages) and recipients (for adding buttons).
	RequestSourcesRecipients = New Query(
		"SELECT DISTINCT
		|	Rules.ObjectTypeDM AS ObjectTypeDM,
		|	CASE
		|		WHEN Rules.ObjectTypeDM = ""DMCorrespondent""
		|			THEN """"
		|		WHEN Attributes.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue)
		|			THEN Attributes.AttributeValueDMID
		|		WHEN Attributes.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate)
		|			THEN Attributes.TemplateID
		|		ELSE """"
		|	END AS IDOfDocumentType,
		|	Rules.ObjectTypeIS AS ObjectTypeIS
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|		LEFT JOIN Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesDM AS Attributes
		|		ON Rules.Ref = Attributes.Ref
		|			AND (Attributes.AttributeNameObjectDM = ""documentType"")
		|WHERE
		|	NOT Rules.DeletionMark
		|TOTALS BY
		|	ObjectTypeDM,
		|	IDOfDocumentType");
	
	// Elements to be copied.
	SourcePageName = "GroupTeamPage";
	SourcePage = Items[SourcePageName];
	NameOfOriginalSubmenu = "TheCreateGroupOnTheBasisOf";
	SourcePanelName = "CommandGroup";
	SourcePanel = Items[SourcePanelName];
	
	SelectionTypeBefore = RequestSourcesRecipients.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionTypeBefore.Next() Do
		
		// We will protect the construction of an important form from possible problems with the contents of the directory.
		If Not ValueIsFilled(SelectionTypeBefore.ObjectTypeDM) Then
			Continue;
		EndIf;
		
		SelectionKindID = SelectionTypeBefore.Select(QueryResultIteration.ByGroups);
		While SelectionKindID.Next() Do
			
			PageKey = CommandPageKey(SelectionTypeBefore.ObjectTypeDM,
				SelectionKindID.IDOfDocumentType);
			
			NameOfNewPage = SourcePageName + PageKey;
			If Items.Find(NameOfNewPage) <> Undefined Then
				Continue;
			EndIf;
			
			NameOfNewPanel = SourcePanelName + PageKey;
			
			// Let's create a new page.
			NewPage = Items.Add(NameOfNewPage, Type("FormGroup"), Items.TeamPageGroup);
			FillPropertyValues(NewPage, SourcePage, , "Name, TitleDataPath");
			
			// Let's create a new command panel.
			NewPanel = Items.Add(NameOfNewPanel, Type("FormGroup"), NewPage);
			FillPropertyValues(NewPanel, SourcePanel, , "Name");
			
			// Let's copy the command panel elements, limiting ourselves to two levels.
			For Each SourceElement In SourcePanel.ChildItems Do
				NewItem = Items.Add(SourceElement.Name + PageKey, TypeOf(SourceElement), NewPanel);
				FillPropertyValues(NewItem, SourceElement, , "Name");
				If TypeOf(SourceElement) = Type("FormGroup") Then
					NewFolder = NewItem;
					For Each OriginalGroupElement In SourceElement.ChildItems Do
						NewGroupElement = Items.Add(OriginalGroupElement.Name + PageKey,
							TypeOf(OriginalGroupElement), NewFolder);
						FillPropertyValues(NewGroupElement, OriginalGroupElement, , "Name");
					EndDo;
				EndIf;
			EndDo;
			
			// Let's add items specific to this type of object to the standard creation submenu.
			NewSubmenu = Items.Find(NameOfOriginalSubmenu + PageKey);
			SampleUserType = SelectionKindID.Select();
			While SampleUserType.Next() Do
				If ValueIsFilled(SampleUserType.ObjectTypeIS) Then
					
					MetadataObject = Metadata.FindByFullName(SampleUserType.ObjectTypeIS);
					If MetadataObject = Undefined Then
						Continue;
					EndIf;
					If Metadata.Catalogs.Contains(MetadataObject) Then
						Presentation = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Phần tử danh mục %1';
								|ru = 'Элемент справочника %1';
								|en = 'Directory element %1'; fa = 'Directory element %1';
								|it = 'Elemento di directory %1';
								|pl = 'Element katalogu %1';
								|tr = 'Katalog öğesi %1'"),
							MetadataObject.Presentation());
					Else
						Presentation = MetadataObject.Presentation();
					EndIf;
					
					CommandName = StrReplace(SampleUserType.ObjectTypeIS, "_", "__");
					CommandName = StrReplace(CommandName, ".", "_");
					CommandName = "Create_" + CommandName;
					
					If Commands.Find(CommandName) = Undefined Then
						CreateLinkedObjectCommand = Commands.Add(CommandName);
						CreateLinkedObjectCommand.Action = "Attachable_CreateLinkedObject";
					EndIf;
					
					TagName = CommandName + PageKey;
					If Items.Find(TagName) = Undefined Then // Insurance against duplicate rules.
						Button = Items.Add(TagName, Type("FormButton"), NewSubmenu);
						Button.Title = Presentation;
						Button.CommandName = CommandName;
					EndIf;
					
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure ExecuteTaskFirstCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Or Response = True Then
		ExecuteTask(1);
	ElsIf TypeOf(Response) = Type("Structure") And Response.Success = True Then
		Comment = Response.Comment;
		ExecuteTask(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskSecondCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Boolean") And Result = True Then
		ExecuteTask(2);
	ElsIf TypeOf(Result) = Type("Structure") And Result.Success = True Then
		Comment = Result.Comment;
		ExecuteTask(2);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTask(ButtonNumber)
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Or TaskLine.Group Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ExecuteTaskCompletion", ThisObject, ButtonNumber);
	
	If ActualTaskExecutor = "userChoice"
			And TaskLine.PerformerType = "DMUser"
			And TaskLine.PerformerID <> CurrentUserID Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Performer", TaskLine.Performer);
		FormParameters.Insert("CurrentUser", CurrentUser);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectingTaskPerformer",
			FormParameters,
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	Else // Without question.
		
		RunCallback(CallbackDescription, ActualTaskExecutor);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskCompletion(SelectedPerformer, ButtonNumber) Export
	
	If SelectedPerformer = Undefined Then
		Return;
	EndIf;
	
	TaskLine = Items.Tasks.CurrentData;
	If TaskLine = Undefined Then
		Return;
	Else
		Task_Data_ = New Structure;
		Task_Data_.Insert("Task", TaskLine.Task);
		Task_Data_.Insert("TaskID", TaskLine.TaskID);
		Task_Data_.Insert("TaskType", TaskLine.TaskType);
		Task_Data_.Insert("ResultID", TaskLine.ResultID);
	EndIf;
	
	SubjectLink = Undefined;
	
	If WriteATask(
			Task_Data_,
			Comment,
			True,
			ButtonNumber,
			TaskLine.Subjects,
			SelectedPerformer,
			SubjectLink) Then
		
		If ValueIsFilled(SubjectLink) Then
			NotifyChanged(SubjectLink);
		EndIf;
		
		NotificationParameters = New Structure("name, ID, type",
			Task_Data_.Task, Task_Data_.TaskID, Task_Data_.TaskType);
		Notify("Recording_1CDocumentManagementTask", NotificationParameters, ThisObject);
		If AddWorkToDailyReportWhenCompletingTask Then
			FormParameters = New Structure;
			FormParameters.Insert("Source", Task_Data_.Task);
			FormParameters.Insert("SourceID", Task_Data_.TaskID);
			FormParameters.Insert("SourceType", Task_Data_.TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork",
				FormParameters,
				Task_Data_.TaskID);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function WriteATask(Task_Data_, Comment, ExecuteTask, ButtonNumber, Val SubjectsOfTask,
		SelectedPerformer, SubjectLink)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Try
		Task = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			Task_Data_.TaskType,
			Task_Data_.TaskID);
	Except
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(
				ErrorInfo(), "3.0.1.1") Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		Return False;
	EndTry;
	
	XDTOProcess = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Process_Type);
	XDTOProcess.name = Process_;
	XDTOProcess.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Process_ID,
		Process_Type);
	Task.parentBusinessProcess = XDTOProcess;
	
	FillInObjectPropertiesByTaskType(Proxy, Task, Comment, ButtonNumber, Task_Data_.ResultID);
	
	Task.executed = Task.executed Or ExecuteTask;
	Task.endDate = CurrentSessionDate();
	Task.executionComment = Comment;
	
	If SelectedPerformer = "currentUser" Then
		DataExecutor = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			CurrentUserID,
			CurrentUserType,
			CurrentUser);
		Task.performer = IntegrationWith1CDocumentManagement.TaskParticipant(
			Proxy,
			DataExecutor);
	EndIf;
	
	RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, Task);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, RecordingResult, "DMError") Then
		Return False;
	Else
		If Task_Data_.TaskType = "DMBusinessProcessApprovalTaskApproval" And ExecuteTask Then
			NewState = Undefined;
			If ButtonNumber = 3 Then
				NewState = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved;
			Else
				ProcessData = IntegrationWith1CDocumentManagementCore.GetObject(
					Proxy,
					Task.parentBusinessProcess.objectID.type,
					Task.parentBusinessProcess.objectID.ID,
					"completed");
				If ProcessData.completed = True Then
					NewState = Enums.ApprovalStatesIn1CDocumentManagement.Approved;
				EndIf;
			EndIf;
			If NewState <> Undefined Then
				For Each SubjectLine In SubjectsOfTask Do
					If (Not MultiSubjectivityIsAvailable Or SubjectLine.RoleOfSubject = "Основной")
							And IntegrationWith1CDocumentManagementClientServer.IsDocument(SubjectLine.Type) Then //@NON-NLS-1
						IntegrationWith1CDocumentManagementCoreServerCall.WhenApprovalStateChanges(
							SubjectLine.ID,
							SubjectLine.Type,
							NewState,
							False,
							SubjectLink);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		Return True;
	EndIf;
	
EndFunction

&AtServer
Procedure RecordTaskItems(TaskParameters_, Val SubjectsOfTask)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Task = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		TaskParameters_.Type,
		TaskParameters_.ID);
	
	Task.executionComment = TaskParameters_.Comment;
	
	If TaskParameters_.Process_Type = "DMBusinessProcessIssuesSolution" Then
		
		Task.files.Clear();
		
		For Each SubjectLine In SubjectsOfTask Do
			
			file = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.Type);
			file.name = SubjectLine.Description;
			file.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.ID,
				SubjectLine.Type);
			
			Task.files.Add(file);
			
		EndDo;
		
	ElsIf TaskParameters_.MultiSubjectivityIsAvailable Then
		
		targetCollection = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMBusinessProcessTaskTargetCollection");
		ItemDescription = targetCollection.items; // XDTOList
		
		For Each SubjectLine In SubjectsOfTask Do
			
			target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTaskTarget");
			
			target.name = SubjectLine.ItemName;
			target.allowDeletion = True;
			
			target.role = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTargetRole");
			target.role.name = SubjectLine.RoleOfSubject;
			target.role.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.RoleOfSubject,
				"DMBusinessProcessTargetRole");
			
			target.target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.Type);
			target.target.name = SubjectLine.Description;
			target.target.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.ID,
				SubjectLine.Type);
			
			ItemDescription.Add(target);
			
		EndDo;
		
		Task.targets = targetCollection;
		
	EndIf;
	
	RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, Task);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, RecordingResult);
	
	UpdateTaskListPartiallyOnServer();
	
EndProcedure

// Fills in the XDTO properties of the task object by its type.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Task - XDTODataObject - the XDTO object of the task.
//   Comment - String
//   ButtonNumber - Number
//   ResultID - String
//
&AtServer
Procedure FillInObjectPropertiesByTaskType(Proxy, Task, Comment, ButtonNumber, ResultID)
	
	TypeName = Task.Type().Name;
	
	If TypeName = "DMBusinessProcessOrderTaskCheckup" Then
		Task.returned = ?(ButtonNumber = 1, False, True);
		
	ElsIf TypeName = "DMBusinessProcessApprovalTaskApproval" Then
		Response = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMApprovalResult");
		If ButtonNumber = 1 Then
			Response.name = NStr("vi = 'Đã thống nhất';
								|ru = 'Согласовано';
								|en = 'Approved'; fa = 'تأییدشده';
								|it = 'Concordato';
								|pl = 'Uzgodniono';
								|tr = 'Onaylandı'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"Согласовано",
				"DMApprovalResult"); //@NON-NLS-1
		ElsIf ButtonNumber = 2 Then
			Response.name = NStr("vi = 'Đã thống nhất và có lưu ý';
								|ru = 'Согласовано с замечаниями';
								|en = 'Approved with comments'; fa = 'تأییدشده با توضیحات';
								|it = 'Omologato con note';
								|pl = 'Uzgodniono z uwagami';
								|tr = 'Yorumlarla onaylandı'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"СогласованоСЗамечаниями",
				"DMApprovalResult"); //@NON-NLS-1
		ElsIf ButtonNumber = 3 Then
			Response.name = NStr("vi = 'Không thống nhất';
								|ru = 'Не согласовано';
								|en = 'Not approved'; fa = 'تأییدنشده';
								|it = 'Non concordato';
								|pl = 'Nie uzgodniono';
								|tr = 'Onaylanmadı'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"НеСогласовано",
				"DMApprovalResult"); //@NON-NLS-1
		EndIf;
		Task.approvalResult = Response;
		
	ElsIf TypeName = "DMBusinessProcessApprovalTaskCheckup" Then
		Task.returned = ?(ButtonNumber = 1, False, True);
		
	ElsIf TypeName = "DMBusinessProcessConfirmationTaskConfirmation" Then
		Response = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMConfirmationResult");
		If ButtonNumber = 1 Then
			Response.name = NStr("vi = 'Đã duyệt';
								|ru = 'Утверждено';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Confermato';
								|pl = 'Confirmed';
								|tr = 'Onaylandı'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"Утверждено",
				"DMConfirmationResult"); //@NON-NLS-1
		ElsIf ButtonNumber = 2 Then
			Response.name = NStr("vi = 'Không duyệt';
								|ru = 'Не утверждено';
								|en = 'Not confirmed'; fa = 'تصدیق‌نشده';
								|it = 'Non confermato';
								|pl = 'Nie zatwierdzono';
								|tr = 'Onaylanmadı'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"НеУтверждено",
				"DMConfirmationResult"); //@NON-NLS-1
		EndIf;
		Task.confirmationResult = Response;
		
	ElsIf TypeName = "DMBusinessProcessConfirmationTaskCheckup" Then
		Task.returned = ?(ButtonNumber = 1, False, True);
		
	ElsIf TypeName = "DMBusinessProcessRegistrationTaskRegistration" Then
		Response = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMRegistrationResult");
		If ButtonNumber = 1 Then
			Response.name = NStr("vi = 'Đã đăng ký';
								|ru = 'Зарегистрировано';
								|en = 'Registered'; fa = 'ثبت‌شده';
								|it = 'Registrato';
								|pl = 'Registered';
								|tr = 'Kaydedildi'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"Зарегистрировано",
				"DMRegistrationResult"); //@NON-NLS-1
		ElsIf ButtonNumber = 2 Then
			Response.name = NStr("vi = 'Chưa đăng ký';
								|ru = 'Не зарегистрировано';
								|en = 'Not registered'; fa = 'ثبت‌نشده';
								|it = 'Non registrato';
								|pl = 'Nie zarejestrowano';
								|tr = 'Kaydedilmedi'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"НеЗарегистрировано",
				"DMRegistrationResult"); //@NON-NLS-1
		EndIf;
		Task.registrationResult = Response;
		
	ElsIf TypeName = "DMBusinessProcessRegistrationTaskCheckup" Then
		Task.returned = ?(ButtonNumber = 1, False, True);
		
	ElsIf TypeName = "DMBusinessProcessPerfomanceTaskCheckup" Then
		If ButtonNumber = 2 Then
			For Each CheckResult In Task.checkResults Do
				CheckResult.returned = True;
				CheckResult.checkComment = Comment;
			EndDo;
		EndIf;
		
	ElsIf TypeName = "DMBusinessProcessConsiderationTaskAcquaint" Then
		Task.resolution = Comment;
		
	ElsIf TypeName = "DMBusinessProcessIssuesSolutionTaskAnswer" Then
		Task.returned = ?(ButtonNumber = 1, False, True);
		
	ElsIf TypeName = "DMBusinessProcessInvitationTaskInvitation" Then
		Response = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy,"DMInvitationResult");
		If ButtonNumber = 1 Then
			Response.name = NStr("vi = 'Đã tiếp nhận';
								|ru = 'Принято';
								|en = 'Received'; fa = 'دریافت‌شده';
								|it = 'Accettato';
								|pl = 'Received';
								|tr = 'Kabul edildi'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"Принято",
				"DMInvitationResult"); //@NON-NLS-1
		ElsIf ButtonNumber = 2 Then
			Response.name = NStr("vi = 'Chưa tiếp nhận';
								|ru = 'Не принято';
								|en = 'Not received'; fa = 'دریافت نشده';
								|it = 'Non accettato';
								|pl = 'Nie przyjęto';
								|tr = 'Kabul edilmedi'");
			Response.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				"НеПринято",
				"DMInvitationResult"); //@NON-NLS-1
		EndIf;
		Task.invitationResult = Response;
		
	ElsIf TypeName = "DMBusinessProcessInvitationTaskAcquaint" Then
		
		If ResultID = "НеПринятоОбязательнымиУчастниками"
				Or ResultID = "НеПринятоВсемиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
			
			If ButtonNumber = 1 Then
				Task.invitationReturned = True;
			EndIf;
			
		Else
			
			If ButtonNumber = 1 Then
				Task.invitationAccepted = True;
			ElsIf ButtonNumber = 2 Then
				Task.invitationReturned = True;
			EndIf;
			
		EndIf;
		
	ElsIf TypeName = "DMBusinessProcessIssuesSolutionTaskQuestion" Then
		If ButtonNumber = 1 Then
			Task.executionMark = "ExecutedPositive";
			If Task.parentBusinessProcess.Properties().Get("newDueDate") <> Undefined Then
				Task.parentBusinessProcess.newDueDate = NewTerm;
			EndIf;
		ElsIf ButtonNumber = 2 Then
			Task.executionMark = "ExecutedNegative";
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayInformationAboutUnavailabilityOfTask()
	
	Items.ButtonPageExecutionGroup.CurrentPage = Items.GroupExecutionZero;
	Items.ExecutionResultText.Visible = True;
	Items.AttentionDecoration2.Visible = True;
	
	Items.ExecutionResultText.Title = NStr("vi = 'Không hỗ trợ thực hiện nhiệm vụ kiểu này trong phiên bản 1C:Document Management hiện tại.';
											|ru = 'Выполнение задач такого типа не поддерживается в данной версии 1С:Документооборота.';
											|en = 'Tasks of this type are not supported in this version of 1C:Document Management.'; fa = 'Tasks of this type are not supported in this version of 1C:Document Management.';
											|it = 'Il completamento di compiti di questo tipo non è supportato in questa versione di 1C:Document Management.';
											|pl = 'Wykonanie zadań takiego typu nie jest obsługiwane w tej wersji 1C:Document Management.';
											|tr = 'Bu tür görevlerin gerçekleştirilmesi, 1C:Document Management''ın bu sürümünde desteklenmemektedir.'");
	Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_NewTerm" Then
		NewTermDateOnChange(Items.NewTermDate);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
