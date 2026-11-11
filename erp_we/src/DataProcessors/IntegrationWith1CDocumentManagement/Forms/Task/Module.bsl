#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Files. The availability of individual commands is configured when the file is activated in the item tree.
	FileCaptureIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
	// Multi-subject.
	MultiSubjectivityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.3.1");
	Items.AddSubject.Visible = MultiSubjectivityIsAvailable;
	Items.FormAddSubject.Visible = MultiSubjectivityIsAvailable;
	Items.AddSubjectFromDecoration.Visible = MultiSubjectivityIsAvailable;
	Items.DeleteSubject.Visible = MultiSubjectivityIsAvailable;
	Items.FormDeleteSubject.Visible = MultiSubjectivityIsAvailable;
	// Mail.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
		Items.FormCreateEmail.Visible = False;
	EndIf;
	// Solving issues of completing tasks.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
		Items.AskAuthorQuestion.Visible = False;
	EndIf;
	// Timing.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
		Items.FormSpecifyLaborCosts.Visible = False;
		Items.FormSwitchTiming.Visible = False;
	EndIf;
	// Acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
		Items.FormAcceptForExecution.Visible = False;
	EndIf;
	// Canceling the acceptance of tasks for execution.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		Items.FormCancelAcceptForExecution.Visible = False;
	EndIf;
	
	Items.ExecutionResult.InputHint = NStr("vi = 'Ghi chú';
											|ru = 'Комментарий';
											|en = 'Comment'; fa = 'توضیحات';
											|it = 'Commento';
											|pl = 'Uwagi';
											|tr = 'Yorum'");
	
	UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername;
	
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
	
	Items.FormChangeExecutionDate.Visible = SettingsOf1CDocumentManagement.ChangeJobsBackdated;
	
	FillOutIssueForm(Parameters);
	SetOverdueIssueFlag();
	SetTaskAppearance(ConditionalAppearance);
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfTaskForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ProcessFormByPresenceOfItems();
	SetAvailabilityOfApplicationTreeCommands();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Var_Parameters, Source)
	
	If EventName = "Recording_1CDocumentManagementDocument"
			And TypeOf(Var_Parameters) = Type("Structure")
			And Var_Parameters.Property("ID")
			And Var_Parameters.Property("type") Then
		ProcessingAndRecordingItem(Var_Parameters.ID, Var_Parameters.type);
		
	ElsIf EventName = "Recording_1CDocumentManagementFile"
			And TypeOf(Var_Parameters) = Type("Structure")
			And Var_Parameters.Property("FileOperation")
			And Var_Parameters.FileOperation.InformFileListForm
			And Var_Parameters.Property("FileID") Then
		ProcessingAndRecordingItem(Var_Parameters.FileID, "DMFile");
		
	ElsIf EventName = "Recording_1CDocumentManagementTimeSpent" And Source = ID Then
		TimekeepingEnabled = False;
		StartDateOfTimekeeping = '00010101';
		SetPropertiesOfTimekeepingElementsServer();
		
	ElsIf EventName = "DocumentManagement_AddingALink" Then
		TreeItems = ApplicationTree.GetItems();
		For Each TreeItem In TreeItems Do
			If TreeItem.SubjectOfID = Var_Parameters.ID Then
				TreeItem.Ref = Var_Parameters.Object;
				Break;
			EndIf;
		EndDo;
		
	ElsIf EventName = "DocumentManagement_DeletingALink" Then
		TreeItems = ApplicationTree.GetItems();
		For Each TreeItem In TreeItems Do
			If TreeItem.SubjectOfID = Var_Parameters.ID Then
				TreeItems.Delete(TreeItem);
				Break;
			EndIf;
		EndDo;
		
	ElsIf EventName = "Workflow_ActionOnTask" Then
		If TypeOf(Var_Parameters) = Type("Structure")
				And Var_Parameters.Property("OperationType")
				And Var_Parameters.Property("ID")
				And Var_Parameters.Property("Type")
				And Var_Parameters.ID = ID
				And Var_Parameters.Type = Type
				And Var_Parameters.OperationType.Forward Then
			Close();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompletionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure CompletionDateTimeOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ExecutionResultOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure BusinessProcessOfSubjectOfConsiderationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		BusinessProcessOfSubjectOfConsiderationType, BusinessProcessOfSubjectOfConsiderationID, ThisObject);
	
EndProcedure

&AtClient
Procedure SubjectOfConsiderationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", SubjectOfConsiderationID);
	FormParameters.Insert("type", SubjectOfConsiderationType);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters, ThisObject, SubjectOfConsiderationID);
	
EndProcedure

&AtClient
Procedure HTMLPresentationOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
	If StrFind(EventData.Href, "ИзменитьСрокВыполнения") Then //@NON-NLS-1
		AgreeOnPostponement(Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure SceneryItemsAndFilesURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	AddSubject(Undefined);
	
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

#Region FormTableItemsEventHandlersAssignees

&AtClient
Procedure AssigneesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AssigneesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AssigneesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "AssigneesReviewerSComment"
		Or Field.Name = "AssigneesSentForRevision" Then
		Return;
	Else
		StandardProcessing = False;
		If ValueIsFilled(Assignees[RowSelected].TaskID) Then
			FormParameters = New Structure;
			FormParameters.Insert("ID", Assignees[RowSelected].TaskID);
			FormParameters.Insert("type", Assignees[RowSelected].TaskType);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesSentForRevisionOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AssigneesReviewerSCommentOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationTree

&AtClient
Procedure ApplicationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	String = Item.CurrentData;
	If String = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(String.Ref) Then // the IP object.
		ShowValue(, String.Ref);
		
	ElsIf String.SubjectOfType = "DMFile" Then // file.
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			String.SubjectOfID,
			String.SubjectOf,
			String.Extension,
			UUID);
		
	Else // Object BEFORE.
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(String.SubjectOfType, String.SubjectOfID, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationTreeOnActivateRow(Item)
	
	SetAvailabilityOfApplicationTreeCommands();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProperties

&AtClient
Procedure PropertiesValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.SelectValueOfAdditionalProps(
		ThisObject,
		Item,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure PropertiesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		Return;
	EndIf;
		
	If TypeOf(CurrentData.Value) = Type("String") Then
		XDTOType =CurrentData.AvailableTypeList[0].Value.xdtoClassName;
		If XDTOType = "integer" Then
			CurrentData.Value = 0;
		ElsIf XDTOType = "boolean" Then
			CurrentData.Value = False;
		ElsIf XDTOType = "date" Then
			CurrentData.Value = Date(1, 1, 1);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure PropertiesValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
		
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
		Or XDTOType = "boolean"
		Or XDTOType = "date"
		Or XDTOType = "string" Then
		Return;
	EndIf;
		
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType,
		ChoiceData,
		Text,
		StandardProcessing,
		Filter);
	
EndProcedure

&AtClient
Procedure PropertiesValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	CurrentData = Items.Properties.CurrentData;
	If CurrentData.AvailableTypeList.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	XDTOType = CurrentData.AvailableTypeList[0].Value.xdtoClassName;
	
	If XDTOType = "integer"
			Or XDTOType = "boolean"
			Or XDTOType = "string"
			Or XDTOType = "date" Then
		Return;
	EndIf;
	
	If XDTOType = "DMObjectPropertyValue" Then
		AdditionalProperty = New Structure;
		AdditionalProperty.Insert("ID", CurrentData.PropertyID);
		AdditionalProperty.Insert("type", CurrentData.PropertyType);
		Filter = New Structure("additionalProperty", AdditionalProperty);
	Else
		Filter = Undefined;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		XDTOType, ChoiceData, Text, StandardProcessing, Filter);
	
	If ChoiceData.Count() = 1 Then
		IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
			"Value", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertiesValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Value", ValueSelected, StandardProcessing, ThisObject, True, Item);
	
EndProcedure

&AtClient
Procedure PropertiesValueClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	Items.Properties.CurrentData.Value = "";
	Items.Properties.CurrentData.ValueID = "";
	Items.Properties.CurrentData.ValueType = "";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStages

&AtClient
Procedure StagesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Items.Stages.CurrentData <> Undefined Then
		If ValueIsFilled(Items.Stages.CurrentData.RunningBusinessProcessID) Then
			IntegrationWith1CDocumentManagementCoreClient.OpenObject(
				Items.Stages.CurrentData.RunningBusinessProcessType,
				Items.Stages.CurrentData.RunningBusinessProcessID, ThisObject);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteTaskFirst(Command)
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(
			ApplicationTree.GetItems(), "SubjectOfID", "SubjectOf") Then
		Return;
	EndIf;
	
	If Process_Type = "DMBusinessProcessRegistration" Then
		If ThisIsTheRoutePoint("Зарегистрировать") Then //@NON-NLS-1
			For Each SubjectLine In ApplicationTree.GetItems() Do
				If (Not MultiSubjectivityIsAvailable Or SubjectLine.RoleOfSubject = "Основной")
					And IntegrationWith1CDocumentManagementClientServer.IsDocument(SubjectLine.SubjectOfType) Then //@NON-NLS-1
					IntegrationWith1CDocumentManagementServerCall.RegisterDocumentIfNecessary(
						SubjectLine.SubjectOfType,
						SubjectLine.SubjectOfID);
				EndIf;
			EndDo;
		EndIf;
		
	ElsIf Type = "DMBusinessProcessIssuesSolutionTaskQuestion" Then
		If TypeOfQuestionID = "Иное" And Not ValueIsFilled(ExecutionResult) Then //@NON-NLS-1
			ClearMessages();
			CommonClient.MessageToUser(
				CommonClientServer.FillingErrorText(,, NStr("vi = 'Ghi chú';
															|ru = 'Комментарий';
															|en = 'Comment'; fa = 'توضیحات';
															|it = 'Commento';
															|pl = 'Komentarz';
															|tr = 'Yorum'")),,
				"ExecutionResult");
			Return;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessConsideration"
			And RoutePoint = "Рассмотреть" And Not ValueIsFilled(ExecutionResult) Then //@NON-NLS-2
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Khuyến nghị""';
										|ru = 'Поле ""Резолюция"" не заполнено';
										|en = '""Resolution"" field is not filled in'; fa = '""Resolution"" field is not filled in';
										|it = 'Campo ""Risoluzione"" non compilato';
										|pl = 'Nie wypełniono pola ""Rezolucja""';
										|tr = '""Karar"" alanı doldurulamadı'"),,
			"ExecutionResult");
		Return;
	EndIf;
	
	If Process_Type = "DMBusinessProcessInvitation" And ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-2
		Notification = New CallbackDescription("ExecuteTaskFirstCompletion", ThisObject);
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
	Else
		CompleteNotifyCloseForm(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskSecond(Command)
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(
			ApplicationTree.GetItems(), "SubjectOfID", "SubjectOf") Then
		Return;
	EndIf;
	
	If (Process_Type = "DMBusinessProcessApproval" And ThisIsTheRoutePoint("Согласовать"))
			Or (Process_Type = "DMBusinessProcessInvitation" And ThisIsTheRoutePoint("Пригласить")) Then //@NON-NLS-2 @NON-NLS-4
		If Not ValueIsFilled(ExecutionResult) Then
			ClearMessages();
			CommonClient.MessageToUser(
				CommonClientServer.FillingErrorText(,, NStr("vi = 'Ghi chú';
															|ru = 'Комментарий';
															|en = 'Comment'; fa = 'توضیحات';
															|it = 'Commento';
															|pl = 'Comment';
															|tr = 'Yorum'")),,
				"ExecutionResult");
			Return;
		EndIf;
		
	ElsIf Type = "DMBusinessProcessIssuesSolutionTaskAnswer" Then
		If Not ValueIsFilled(ExecutionResult) Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Khi gửi đi làm rõ, cần điền ghi chú.';
					|ru = 'При отправке на уточнение требуется указать комментарий.';
					|en = 'Indicate comment when send to clarification.'; fa = 'Indicate comment when send to clarification.';
					|it = 'È necessario indicare il commento all''invio in precisazione.';
					|pl = 'Przy wysyłce do uściślenia należy wprowadzić uwagi.';
					|tr = 'Kesinleştirme için gönderirken, yorum belirtmek gerekiyor.'"),,
				"ExecutionResult");
			Return;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessConfirmation" And ThisIsTheRoutePoint("Утвердить") Then //@NON-NLS-2
		If Not ValueIsFilled(ExecutionResult) Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Hãy chỉ ra nguyên nhân sai lệch của chứng từ';
					|ru = 'Укажите причину отклонения документа';
					|en = 'Specify reason for document rejection'; fa = 'Specify reason for document rejection';
					|it = 'Specificare il motivo per cui il documento viene rigettato';
					|pl = 'Wskaż powód odrzucenia dokumentu';
					|tr = 'Belgenin reddedilme nedenini belirt'"),,
				"ExecutionResult");
			Return;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessRegistration" And ThisIsTheRoutePoint("Зарегистрировать") Then //@NON-NLS-2
		If Not ValueIsFilled(ExecutionResult) Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Hãy chỉ ra nguyên nhân từ chối đăng ký';
					|ru = 'Укажите причину отказа в регистрации';
					|en = 'Indicate reason of registration cancel'; fa = 'Indicate reason of registration cancel';
					|it = 'Indicare motivo di rifiuto nella registrazione';
					|pl = 'Podaj przyczynę odrzucenia rejestracji';
					|tr = 'Kayıt reddetme nedenini belirt'"),,
				"ExecutionResult");
			Return;
		EndIf;
		
	ElsIf Process_Type = "DMBusinessProcessIssuesSolution" And ThisIsTheRoutePoint("РассмотрениеИнициатором") Then //@NON-NLS-2
		If TypeOfQuestionID = "ПереносСрока" And Not ValueIsFilled(ExecutionResult) Then //@NON-NLS-1
			ClearMessages();
			CommonClient.MessageToUser(
				CommonClientServer.FillingErrorText(,, NStr("vi = 'Ghi chú';
															|ru = 'Комментарий';
															|en = 'Comment'; fa = 'توضیحات';
															|it = 'Commento';
															|pl = 'Comment';
															|tr = 'Yorum'")),,
				"ExecutionResult");
			Return;
		EndIf;
	EndIf;
	
	FormParameters = New Structure("ID, type, taskID", Process_ID, Process_Type, ID);
	Notification = New CallbackDescription("ExecuteTaskSecondCompletion", ThisObject);
	
	If Process_Type = "DMBusinessProcessApproval" And ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-2
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessApproval",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessConfirmation" And ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-2
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessAdoption",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessRegistration" And ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-2
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessRegistration",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf Process_Type = "DMBusinessProcessInvitation" And ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-2
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessInvitation",
			FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
	Else
		CompleteNotifyCloseForm(2);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskThird(Command)
	
	If IntegrationWith1CDocumentManagementClient.ThereAreUnfilledItems(
			ApplicationTree.GetItems(), "SubjectOfID", "SubjectOf") Then
		Return;
	EndIf;
	
	If Process_Type = "DMBusinessProcessApproval" Then
		If Not ValueIsFilled(ExecutionResult) Then
			ClearMessages();
			CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Ghi chú';
														|ru = 'Комментарий';
														|en = 'Comment'; fa = 'توضیحات';
														|it = 'Commento';
														|pl = 'Comment';
														|tr = 'Yorum'")),,
			"ExecutionResult");
			Return;
		EndIf;
	EndIf;
	
	CompleteNotifyCloseForm(3);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	If Modified Then
		If WriteObject() Then
			Modified = False;
			NotificationParameters = New Structure("name, ID, type", Description, ID, Type);
			Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
			Close();
		EndIf;
	Else
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteExecute(Command)
	
	If Modified Then
		If WriteObject() Then
			Modified = False;
			NotificationParameters = New Structure("name, ID, type", Description, ID, Type);
			Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
		EndIf;
	EndIf;
	
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
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(String.SubjectOfType, String.SubjectOfID,
			ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFileForViewing(Command)
	
	String = Items.ApplicationTree.CurrentData;
	If String <> Undefined And String.SubjectOfType = "DMFile" Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			String.SubjectOfID,
			String.SubjectOf,
			String.Extension,
			UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTask(Command)
	
	RowSelected = Items.Assignees.CurrentRow;
	
	If ValueIsFilled(Assignees[RowSelected].TaskID) Then
		FormParameters = New Structure;
		FormParameters.Insert("ID", Assignees[RowSelected].TaskID);
		FormParameters.Insert("type", Assignees[RowSelected].TaskType);
		FormParameters.Insert("RoutePoint",Assignees[RowSelected].RoutePoint);
		FormParameters.Insert("ProcessType",Process_Type);
			
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Task", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenBusinessProcess(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(Process_Type, Process_ID, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenMainItem(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(
		MainSubjectType,
		MainSubjectID,
		ThisObject);
	
EndProcedure

&AtClient
Procedure Forward(Command)
	
	If Modified Then
		WriteObject();
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Task", Description);
	FormParameters.Insert("TaskID", ID);
	FormParameters.Insert("TaskType", Type);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.TaskRedirecting",
		FormParameters);
	
EndProcedure

&AtClient
Procedure AcceptForExecution(Command)
	
	AcceptedForExecution = AcceptTaskForExecutionOnServer();
	
	If AcceptedForExecution Then
		Status(NStr("vi = 'Nhiệm vụ đã được đưa vào thực hiện';
					|ru = 'Задача принята к исполнению';
					|en = 'Task is accepted for execution'; fa = 'Task is accepted for execution';
					|it = 'Compito accettato per l''esecuzione';
					|pl = 'Zadanie zostało przyjęte do wykonania';
					|tr = 'Görev yürütme için kabul edildi'"));
		Items.FormAcceptForExecution.Enabled = False;
		Items.FormCancelAcceptForExecution.Enabled = True;
		NotificationParameters = New Structure("name, ID, type", Description, ID, Type);
		Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelAcceptForExecution(Command)
	
	If CancelAcceptanceForExecutionOnServer() Then
		AcceptedForExecution = False;
		Status(NStr("vi = 'Nhiệm vụ được đánh dấu là chưa đưa vào thực hiện';
					|ru = 'Задача помечена как не принятая к исполнению';
					|en = 'The task is marked as not received for execution'; fa = 'The task is marked as not received for execution';
					|it = 'Compito contrassegnato come non accettato per l''esecuzione';
					|pl = 'Zadanie jest zaznaczone jako nie przyjęte do wykonania';
					|tr = 'Görev, yürütme için kabul edilmedi olarak işaretlendi'"));
		Items.FormAcceptForExecution.Enabled = True;
		Items.FormCancelAcceptForExecution.Enabled = False;
		NotificationParameters = New Structure("name, ID, type", Description, ID, Type);
		Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
	EndIf;
	
EndProcedure

// The handler is bound to programmatically generated commands.
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
	
	If MultiSubjectivityIsAvailable Then
		Subjects = ApplicationTree.GetItems();
		For Each SubjectLine In Subjects Do
			If SubjectLine.SubjectOfType <> "DMFile" Then
				IntegrationWith1CDocumentManagementClient.CreateIntegratedObjectByType(
					ThisObject, TypeName, SubjectLine.SubjectOfType, SubjectLine.SubjectOfID);
				Break;
			EndIf;
		EndDo;
	Else
		IntegrationWith1CDocumentManagementClient.CreateIntegratedObjectByType(
			ThisObject, TypeName, SubjectOfType, SubjectOfID);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateEmail(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", Description);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	
EndProcedure

&AtClient
Procedure AskAuthorQuestion(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", ID);
	FormParameters.Insert("type", Type);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Khác';
												|ru = 'Иное';
												|en = 'Other'; fa = 'سایر';
												|it = 'Altro';
												|pl = 'Other';
												|tr = 'Diğer'"));
	FormParameters.Insert("TypeOfQuestionID", "Иное"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, ID);
	
EndProcedure

&AtClient
Procedure AgreeOnPostponement(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ID", ID);
	FormParameters.Insert("type", Type);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Gia hạn';
												|ru = 'Перенос срока';
												|en = 'Postponement'; fa = 'Postponement';
												|it = 'Spostamento termine';
												|pl = 'Przeniesienie terminu';
												|tr = 'Tarihin ertelenmesi'"));
	FormParameters.Insert("TypeOfQuestionID", "ПереносСрока"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, ID);
	
EndProcedure

&AtClient
Procedure SpecifyLaborCosts(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Source", Presentation);
	FormParameters.Insert("SourceID", ID);
	FormParameters.Insert("SourceType", Type);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ID);
	
EndProcedure

&AtClient
Procedure SwitchTiming(Command)
	
	NeedDialogue = True;
	WorkDuration = IntegrationWith1CDocumentManagementClient.GetRunningTime(StartDateOfTimekeeping);
	If WorkDuration < 60 Then // Less than 1 minute.
		NeedDialogue = False;
	EndIf;
	
	If NeedDialogue Then
		FormParameters = New Structure;
		FormParameters.Insert("Source", Presentation);
		FormParameters.Insert("SourceID", ID);
		FormParameters.Insert("SourceType", Type);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ID);
	Else
		If TimekeepingEnabled Then
			SwitchTimingServer();
			If TimekeepingEnabled Then
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
						|ru = 'Включен хронометраж по ""%1""';
						|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
						|it = 'Crono-analisi attivata per ""%1""';
						|pl = 'Chronometraż jest włączony według ""%1""';
						|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
				Status(Text);
			EndIf;
		Else
			ActiveEntries = IntegrationWith1CDocumentManagementServerCall.ActiveTimekeepingRecords();
			If ActiveEntries.Count() = 0 Then
				SwitchTimingServer();
				If TimekeepingEnabled Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
							|ru = 'Включен хронометраж по ""%1""';
							|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
							|it = 'Crono-analisi attivata per ""%1""';
							|pl = 'Chronometraż jest włączony według ""%1""';
							|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
					Status(Text);
				EndIf;
			Else
				NotificationParameters = New Structure;
				NotificationParameters.Insert("ActiveEntries", ActiveEntries);
				
				Notification = New CallbackDescription("SwitchTimingCompletion", ThisObject, NotificationParameters);
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
Procedure ChangeExecutionDate(Command)
	
	ShowInputDate(
		New CallbackDescription("AfterEnteringExecutionDate", ThisObject),
		CompletionDate,
		NStr("vi = 'Hãy chỉ ra ngày thực tế thực hiện nhiệm vụ';
			|ru = 'Укажите дату фактического выполнения задачи';
			|en = 'Specify task actual execution date'; fa = 'Specify task actual execution date';
			|it = 'Indicare data del completamento effettivo del compito';
			|pl = 'Podaj datę faktycznego wykonania zadania';
			|tr = 'Görev için gerçek bitiş tarihini belirt'"),
		DateFractions.DateTime);
	
EndProcedure

&AtClient
Procedure AfterEnteringExecutionDate(Date, Var_Parameters) Export
	
	If Date <> Undefined Then
		CompletionDate = Date;
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	If WriteObject() Then
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("ID", Process_ID);
		NotificationParameters.Insert("Started", True);
		
		// Let's collect the items.
		Subjects = New Array;
		If MultiSubjectivityIsAvailable Then
			TreeItems = ApplicationTree.GetItems();
			For Each SubjectLine In TreeItems Do
				If SubjectLine.RoleOfSubject = "Основной" Then //@NON-NLS-1
					ItemDescription = New Structure;
					ItemDescription.Insert("ID", SubjectLine.SubjectOfID);
					ItemDescription.Insert("Type", SubjectLine.SubjectOfType);
					Subjects.Add(ItemDescription);
				EndIf;
			EndDo;
		Else
			// One item.
			ItemDescription = New Structure;
			ItemDescription.Insert("ID", SubjectOfID);
			ItemDescription.Insert("Type", SubjectOfType);
			Subjects.Add(ItemDescription);
		EndIf;
		NotificationParameters.Insert("Subjects", Subjects);
		
		Notify("Recording_1CDocumentManagementBusinessProcess", NotificationParameters, FormOwner);
		
		NotificationParameters = New Structure("name, ID, type", Presentation, ID, Type);
		Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
		
		Close();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchTimingCompletion(SelectionResult, NotificationParameters) Export
	
	If SelectionResult = DialogReturnCode.Yes Then
		
		Records = IntegrationWith1CDocumentManagementServerCall.SwitchTimeTrackingBy1CDocumentManagementObjects(NotificationParameters.ActiveEntries);
		
		For Each Record In Records Do
			NotificationParameters = New Structure;
			NotificationParameters.Insert("name", Record.Source);
			NotificationParameters.Insert("ID", Record.SourceID);
			NotificationParameters.Insert("type", Record.SourceType);
			Notify("Recording_1CDocumentManagementTimeSpent", NotificationParameters, Record.SourceID);
		EndDo;
	
		SwitchTimingServer();
		If TimekeepingEnabled Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Sử dụng đồng hồ tính thời gian theo ""%1""';
					|ru = 'Включен хронометраж по ""%1""';
					|en = 'Timing by ""%1"" is enabled'; fa = 'Timing by ""%1"" is enabled';
					|it = 'Crono-analisi attivata per ""%1""';
					|pl = 'Chronometraż jest włączony według ""%1""';
					|tr = '""%1"" ile kronometre etkin'"), String(Presentation));
			Status(Text);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskFirstCompletion(Response, NotificationParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CompleteNotifyCloseForm(1);
	ElsIf TypeOf(Response) = Type("Structure") And Response.Success = True Then
		ExecutionResult = Response.Comment;
		CompleteNotifyCloseForm(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteTaskSecondCompletion(Parameter, NotificationParameters) Export
	
	If TypeOf(Parameter) = Type("Boolean") And Parameter = True Then
		CompleteNotifyCloseForm(2);
	ElsIf TypeOf(Parameter) = Type("Structure") And Parameter.Success = True Then
		ExecutionResult = Parameter.Comment;
		CompleteNotifyCloseForm(2);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfTimekeepingElementsServer()
	
	DataProcessors.IntegrationWith1CDocumentManagement.SetPropertiesOfTimekeepingElements(
		TimekeepingEnabled,
		Commands.SwitchTiming,
		Items.FormSwitchTiming);
	
EndProcedure

&AtServer
Procedure SwitchTimingServer()
	
	DataProcessors.IntegrationWith1CDocumentManagement.SwitchTiming(ThisObject);
	
EndProcedure

&AtServer
Procedure FillOutIssueForm(TaskParameters_)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		TaskParameters_.type,
		TaskParameters_.ID,
		"withDependentObjects");
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInTimekeepingParameters(ThisObject, XDTODataObject);
	
	// Fill in the general details of the tasks.
	ID = XDTODataObject.objectID.ID;
	Type = XDTODataObject.objectID.type;
	Presentation = XDTODataObject.objectID.presentation;
	Description = XDTODataObject.Name;
	Title = XDTODataObject.objectID.presentation;
	Executed = XDTODataObject.executed;
	AcceptedForExecution = XDTODataObject.accepted;
	Date = XDTODataObject.beginDate;
	Number = XDTODataObject.number;
	TaskDueDate = XDTODataObject.dueDate;
	ExecutionResult = XDTODataObject.executionComment;
	CompletionDate = XDTODataObject.endDate;
	LongDesc = XDTODataObject.description;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "project") Then
		Project = XDTODataObject.project.name;
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "projectTask") Then
		TaskOfTheProject = XDTODataObject.projectTask.name;
	EndIf;
	
	Items.ProjectGroup.Visible = (ValueIsFilled(Project) Or ValueIsFilled(TaskOfTheProject));
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTODataObject.importance,"Importance");
	If XDTODataObject.Properties().Get("state") <> Undefined Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTODataObject.state, "State");
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.parentBusinessProcess, "Process_", True);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTODataObject.author, "Author");
	FillInAddressData(ThisObject, XDTODataObject.performer);
	RoutePoint = IntegrationWith1CDocumentManagement.ShortRoutePointName(Process_Type, XDTODataObject.businessProcessStep);
	
	ProcessObject_ = XDTODataObject.parentBusinessProcess;
	
	// Fill in the application tree.
	If Process_Type = "DMBusinessProcessIssuesSolution" Then
		FillApplicationTreeByFiles(XDTODataObject.files);
	ElsIf MultiSubjectivityIsAvailable Then
		XDTOFillableItems = Undefined;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "fillableTargets") Then
			XDTOFillableItems = XDTODataObject.fillableTargets.items;
		EndIf;
		FillApplicationTreeBySubject(XDTODataObject.targets.items, XDTOFillableItems);
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "target") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject, XDTODataObject.target, "SubjectOf");
		CompatibilitySupport_FillProcessSubjectTasks(
			Proxy, XDTODataObject, XDTODataObject.target, ProcessObject_);
		FillInTheApplicationTreeBySubject(XDTODataObject.target);
		CompleteCreationCommandsBySubject(XDTODataObject.target);
	EndIf;
	
	MainSubjectType = "";
	MainSubjectID = "";
	
	For Each Item In ApplicationTree.GetItems() Do
		If Item.RoleOfSubject = "Основной" Then //@NON-NLS-1
			MainSubjectType = Item.SubjectOfType;
			MainSubjectID = Item.SubjectOfID;
			Break;
		EndIf;
	EndDo;
	
	Items.FormOpenMainItem.Enabled = ValueIsFilled(MainSubjectType)
		And ValueIsFilled(MainSubjectID);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.PlaceAdditionalDetailsOnForm(
		ThisObject,
		XDTODataObject);
	
	// Let's determine the possibility of execution and stopping.
	If Not (Executed
			Or XDTODataObject.executionMark = "ReadyToExecute"
			Or StateID = "Остановлен"
			Or StateID = "Прерван") Then //@NON-NLS-2 @NON-NLS-3
		CompletionDate = CurrentSessionDate();
		ExecutionAvailable = True;
	Else
		Items.ExecutionResultText.Visible = True;
		ExecutionAvailable = False;
	EndIf;
	If StateID = "Остановлен" Then //@NON-NLS-1
		Items.TaskInformationGroup.Visible = True;
		Items.TextState.Title = NStr("vi = 'Nhiệm vụ đã tạm dừng';
									|ru = 'Задача остановлена';
									|en = 'The task is stopped'; fa = 'وظیفه متوقف شده است';
									|it = 'Obiettivo interrotto';
									|pl = 'Zadanie zatrzymano';
									|tr = 'Görev durduruldu'");
		PictureState = 1;
	ElsIf StateID = "Прерван" Then //@NON-NLS-1
		Items.TaskInformationGroup.Visible = True;
		Items.TextState.Title = NStr("vi = 'Nhiệm vụ đã bị ngắt';
									|ru = 'Задача прервана';
									|en = 'Task is canceled'; fa = 'Task is canceled';
									|it = 'Compito interrotto';
									|pl = 'Zadanie zostało przerwane';
									|tr = 'Görev kesildi'");
		PictureState = 2;
	ElsIf XDTODataObject.executionMark = "ReadyToExecute" Then
		Items.TaskInformationGroup.Visible = True;
		Items.TextState.Title = NStr(
			"vi = 'Nhiệm vụ đang chờ thực hiện. Nhiệm vụ sẽ tự động thực hiện trong thời gian tới.';
			|ru = 'Задача находится в очереди для выполнения. Выполнение задачи произойдет автоматически в ближайшее время.';
			|en = 'The task is in the execution queue. The task will be completed automatically soon.'; fa = 'The task is in the execution queue. The task will be completed automatically soon.';
			|it = 'Il compito si trova in coda di esecuzione. L''esecuzione del compito avverrà automaticamente a breve.';
			|pl = 'Zadanie jest w kolejce do wykonania. Wykonanie zadania odbędzie się automatycznie w najbliższym czasie.';
			|tr = 'Görev yürütme için sırada bekliyor. Görev yakın gelecekte otomatik olarak gerçekleştirilecek.'");
		PictureState = 9;
	ElsIf XDTODataObject.executionMark = "ExecutionCanceled" Then
		Items.TaskInformationGroup.Visible = True;
		Items.TextState.Title = NStr(
			"vi = 'Lỗi khi thực hiện nhiệm vụ';
			|ru = 'Ошибка при выполнении задачи';
			|en = 'Task execution error'; fa = 'Task execution error';
			|it = 'Errore durante l''esecuzione del compito';
			|pl = 'Błąd podczas wykonywania zadania';
			|tr = 'Görev gerçekleştirilirken hata'");
		PictureState = 10;
	Else
		Items.TaskInformationGroup.Visible = False;
	EndIf;
	
	// Fill in the description.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "htmlView") Then
		Items.DetailsGroup.CurrentPage = Items.GroupHTMLPresentation;
		HTMLPresentation = XDTODataObject.htmlView;
	Else
		Items.DetailsGroup.CurrentPage = Items.GroupTextDescription;
		CompleteTaskDescription(ProcessObject_, XDTODataObject);
	EndIf;
	
	// Let's set up visibility and fill in the details specific to the route point.
	Items.ExecutionResult.ReadOnly = Not ExecutionAvailable;
	Items.CompletionDate.Visible = Not ExecutionAvailable;
	Items.CompletionDateTime.Visible = Not ExecutionAvailable;
	Items.CompletionDate.ReadOnly = Not ExecutionAvailable;
	Items.CompletionDateTime.ReadOnly = Not ExecutionAvailable;
	Items.NewTermGroup.ReadOnly = Not ExecutionAvailable;
	
	// Fill in the details specific to the type of process.
	If Process_Type = "DMBusinessProcessApproval" Then
		FillInTheDataACApproval(XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessConfirmation" Then
		FillInTheDataForTheConfirmation(XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessRegistration" Then
		FillInACData(XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessConsideration" Then
		FillInUAVData(XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessOrder" Then
		FillInDetailsOfBPOrder(Proxy, XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessPerformance" Then
		FillInDataACExecution(Proxy, XDTODataObject);
	ElsIf Process_Type = "DMComplexBusinessProcess" Then
		FillingInBPDataIsComplexProcess(Proxy, ProcessObject_);
	ElsIf Process_Type = "DMBusinessProcessAcquaintance" Then
		FillInBPDataFamiliarization();
	ElsIf Process_Type = "DMBusinessProcessIssuesSolution" Then
		FillInBPDataSolvingQuestions(XDTODataObject);
	ElsIf Process_Type = "DMBusinessProcessInvitation" Then
		FillInDataACInvitation(XDTODataObject);
	Else
		DisplayInformationAboutUnavailabilityOfTask();
	EndIf;
	
	// Let's process the availability of the task for modification.
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "changeRight") Then
		Allowed1Update = XDTODataObject.changeRight;
	Else
		Allowed1Update = False;
	EndIf;
	Allowed1Update = Allowed1Update
			And Not (XDTODataObject.executionMark = "ReadyToExecute")
			And Not (StateID = "Остановлен")
			And Not (StateID = "Прерван")
			And Not Executed; //@NON-NLS-2 @NON-NLS-3
	ReadOnly = Not Allowed1Update;
	If Not Allowed1Update Or Not MultiSubjectivityIsAvailable Then // Remove the hyperlink "Add...".
		Items.SceneryItemsAndFiles.Title = NStr("vi = 'Nhiệm vụ không có chủ đề.';
												|ru = 'У задачи нет предметов.';
												|en = 'The task has no subjects.'; fa = 'The task has no subjects.';
												|it = 'Il compito non ha elementi.';
												|pl = 'Zadanie nie ma przedmiotów.';
												|tr = 'Görevin öğesi mevcut değil.'");
	EndIf;
	Items.FormAcceptForExecution.Enabled = Not AcceptedForExecution And Allowed1Update;
	Items.FormCancelAcceptForExecution.Enabled = AcceptedForExecution And Allowed1Update;
	Items.FormForward.Enabled = Allowed1Update;
	Items.FormAddSubject.Enabled = Allowed1Update;
	Items.FormDeleteSubject.Enabled = Allowed1Update;
	Items.AddSubject.Enabled = Allowed1Update;
	Items.DeleteSubject.Enabled = Allowed1Update;
	Items.AddSubjectFromDecoration.Enabled = Allowed1Update;
	If Process_Type = "DMBusinessProcessIssuesSolution" Then
		Items.AskAuthorQuestion.Visible = False;
		Items.FormAgreeOnPostponement.Visible = False;
	Else
		Items.AskAuthorQuestion.Visible = True;
		Items.FormAgreeOnPostponement.Visible = Not Executed
			And ValueIsFilled(XDTODataObject.dueDate)
			And IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP");
	EndIf;
	
EndProcedure

&AtServer
Procedure CompatibilitySupport_FillProcessSubjectTasks(Proxy, XDTODataObject, SubjectObject, ProcessObject_)
	
	// are the subject and process of the task filled in at once?
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
		
		ObjectsArray = New Array;
		ColumnsArray1 = New Array;
		
		ObjectsArray.Add(
			New Structure("ID, Type",
				XDTODataObject.parentBusinessProcess.ObjectID.ID,
				XDTODataObject.parentBusinessProcess.ObjectID.type));
		ColumnsArray1.Add("name");
		ColumnsArray1.Add("objectID");
		ColumnsArray1.Add("checkResults");
		ColumnsArray1.Add("executionComment");
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "target") Then
			If Find(XDTODataObject.target.objectID.type,"Document") <> 0 Then
				ObjectsArray.Add(
					New Structure("ID, Type", XDTODataObject.target.ObjectID.ID, XDTODataObject.target.ObjectID.type));
				ColumnsArray1.Add("files");
				ColumnsArray1.Add("externalObject");
			ElsIf XDTODataObject.target.objectID.type = "DMFile" Then
				ObjectsArray.Add(
					New Structure("ID, Type", XDTODataObject.target.ObjectID.ID, XDTODataObject.target.ObjectID.type));
				ColumnsArray1.Add("extension");
				ColumnsArray1.Add("modificationDateUniversal");
				ColumnsArray1.Add("size");
			EndIf;
		EndIf;
		
		ListOfObjects = IntegrationWith1CDocumentManagementCore.GetObjects(
			Proxy,
			ObjectsArray,
			ColumnsArray1);
		
		ProcessObject_ = ListOfObjects[0];
		
		If ListOfObjects.Count() > 1 Then
			SubjectObject = ListOfObjects[1];
		EndIf;
		
	EndIf;
	
EndProcedure

// For the BP "Problem Solving", the application tree is filled in by files, not by subjects.
//
&AtServer
Procedure FillApplicationTreeByFiles(XDTOFiles)
	
	Tree = FormAttributeToValue("ApplicationTree");
	
	AddFilesToApplicationTree(Tree.Rows, XDTOFiles, True);
	
	ValueToFormAttribute(Tree, "ApplicationTree");
	
EndProcedure

// For multi-subject versions of the web service.
//
&AtServer
Procedure FillApplicationTreeBySubject(RowsOfXDTOItems, XDTOFillableItems)
	
	Tree = FormAttributeToValue("ApplicationTree");
	Tree.Rows.Clear();
	
	For Each SubjectLineXDTO In RowsOfXDTOItems Do
		
		SubjectLine = Tree.Rows.Add();
		
		SubjectLine.ItemName = SubjectLineXDTO.name;
		SubjectLine.RoleOfSubject = SubjectLineXDTO.role.objectID.ID;
		SubjectLine.DeletionAvailable = SubjectLineXDTO.allowDeletion;
		
		FillItemLineWithItsProperties(SubjectLine, SubjectLineXDTO.target);
		
	EndDo;
	
	If XDTOFillableItems <> Undefined Then
		For Each SubjectLineXDTO In XDTOFillableItems Do
			
			SubjectLine = Tree.Rows.Add();
			
			SubjectLine.RoleOfSubject = SubjectLineXDTO.role.objectID.ID;
			SubjectLine.Mandatory = SubjectLineXDTO.requiredField;
			SubjectLine.DeletionAvailable = SubjectLineXDTO.allowDeletion;
			SubjectLine.SubjectOf = SubjectLineXDTO.name;
			SubjectLine.Presentation = StrTemplate(NStr("vi = '%1 (chưa được nhập), Được điền';
														|ru = '%1 (не введен), Заполняемый';
														|en = '%1 (not entered), To be filled'; fa = '%1 (not entered), To be filled';
														|it = '%1 (не введен), Заполняемый';
														|pl = '%1 (not entered), To be filled';
														|tr = '1 (girilmedi), Doldurulan'"), SubjectLine.SubjectOf);
			
			SetItemPicture(SubjectLine);
			
		EndDo;
	EndIf;
	
	ValueToFormAttribute(Tree, "ApplicationTree");
	
EndProcedure

// For versions of the web service that do not support multi-subject.
//
&AtServer
Procedure FillInTheApplicationTreeBySubject(SubjectXDTO)
	
	Tree = FormAttributeToValue("ApplicationTree");
	Tree.Rows.Clear();
	
	SubjectLine = Tree.Rows.Add();
	FillItemLineWithItsProperties(SubjectLine, SubjectXDTO);
	
	ValueToFormAttribute(Tree, "ApplicationTree");
	
EndProcedure

// Fills in the creation commands for the subject.
//
&AtServer
Procedure CompleteCreationCommandsBySubject(SubjectXDTO)
	
	If SubjectXDTO.objectID.type = "DMFile" Then
		Return;
	EndIf;
	
	TeamStructure = IntegrationWith1CDocumentManagement.StructureOfCreateAndOpenCommands(
		SubjectXDTO.objectID.type,
		SubjectXDTO.objectID.ID);
	
	ProcessedTypes = New Array;
	
	For Each CreationCommand In TeamStructure.CreationCommands Do
		
		If ProcessedTypes.Find(CreationCommand.Type) <> Undefined Then
			Continue;
		EndIf;
		
		Presentation = CreationCommand.Presentation;
		
		CommandName = StrReplace(CreationCommand.Type, "_", "__");
		CommandName = StrReplace(CommandName, ".", "_");
		CommandName = "Create_" + CommandName;
		
		If Commands.Find(CommandName) = Undefined Then
			CreateLinkedObjectCommand = Commands.Add(CommandName);
			CreateLinkedObjectCommand.Action = "Attachable_CreateLinkedObject";
		Else
			Continue;
		EndIf;
		
		Button = Items.Add(CommandName, Type("FormButton"), Items.CreateBasedOn);
		Button.Title = Presentation;
		Button.CommandName = CommandName;
		
	EndDo;
	
EndProcedure

// Fills in the row of the application tree for the subject of XDTO.
//
&AtServer
Procedure FillItemLineWithItsProperties(SubjectLine, SubjectXDTO)
	
	SubjectLine.SubjectOf = SubjectXDTO.name;
	SubjectLine.SubjectOfID = SubjectXDTO.objectID.ID;
	SubjectLine.SubjectOfType = SubjectXDTO.objectID.type;
	
	CompleteCreationCommandsBySubject(SubjectXDTO);
	
	If SubjectLine.SubjectOfType = "DMFile" Then
		SubjectLine.Extension = SubjectXDTO.extension;
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
	
	SetItemPicture(SubjectLine);
	AppendSubjectStringByRelatedObjectIS(SubjectLine, SubjectXDTO);
	AugmentApplicationTreeWithObjectFiles(SubjectLine);
	
EndProcedure

// Sets the image of the subject by its role or by the file extension.
//
&AtServer
Procedure SetItemPicture(SubjectLine)
	
	If SubjectLine.SubjectOfType = "DMFile" Then
		// For a file - by extension.
		SubjectLine.Picture =
			IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(SubjectLine.Extension);
	Else
		// For other types - by role.
		SubjectLine.Picture = IntegrationWith1CDocumentManagementClientServer.ImageBySubjectRole(
			SubjectLine.RoleOfSubject);
	EndIf;
	
EndProcedure

// Complements the line with information about the IP object, changing the representation.
&AtServer
Procedure AppendSubjectStringByRelatedObjectIS(SubjectLine, SubjectXDTO)
	
	// Find the associated IP object.
	If IntegrationWith1CDocumentManagementCore.PropertySet(SubjectXDTO, "externalObject") Then
		ItemReferences = IntegrationWith1CDocumentManagementCore.LinksToExternalObjects(SubjectXDTO);
		If ItemReferences.Count() <> 0 Then
			SubjectLine.Ref = ItemReferences[0];
		EndIf;
	EndIf;
	// Representation, as in BEFORE.
	Presentation = SubjectLine.SubjectOf;
	
	If SubjectLine.SubjectOfType <> "DMFile" Then
		If ValueIsFilled(SubjectLine.ItemName) Then // Multi-subject, the name is known.
			Presentation = Presentation + " (" + SubjectLine.ItemName + ")";
		Else // Without multi-subjects, we will give an explanation according to the type.
			AddItemNameByItemType(Presentation, SubjectLine.SubjectOfType);
		EndIf;
		Presentation = Presentation + NStr("vi = ', văn bản DM';
											|ru = ', документ ДО';
											|en = ', DI document'; fa = ', DI document';
											|it = ', documento DM';
											|pl = ', dokument DM';
											|tr = ', İş Akışı belgesi'");
	EndIf;
	
	// Let's replace the name of the subject in the DO with its representation in the IS. NB: there may be a situation when there are rights in the
	// DO, but not in the IS. In this case, the task form should open normally, and the user will see
	// the error "Access violation" only when trying to open the item in the IP.
	Try
		If ValueIsFilled(SubjectLine.Ref) Then // Presentation as in IP.
			AbbreviatedNameOfConfiguration = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
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
			SubjectLine.Presentation = String(SubjectLine.Ref) + ObjectPresentation;
		Else // Presentation as in BEFORE.
			SubjectLine.Presentation = Presentation;
		EndIf;
	Except
		SubjectLine.Presentation = Presentation;
	EndTry;
	
EndProcedure

// Receives the subject files by calling the service and supplements the application tree with them.
//
&AtServer
Procedure AugmentApplicationTreeWithObjectFiles(SubjectLine)
	
	If SubjectLine.SubjectOfType = "DMFile" Then
		Return;
	EndIf;
	
	ListOfFiles = IntegrationWith1CDocumentManagementCoreServerCall.FilesByOwner(
		SubjectLine.SubjectOfID,
		SubjectLine.SubjectOf,
		SubjectLine.SubjectOfType);
	AddFilesToApplicationTree(SubjectLine.Rows, ListOfFiles.files);
	
EndProcedure

// Complements the application tree with the transferred collection of files.
//
&AtServer
Procedure AddFilesToApplicationTree(TreeRows, XDTOFiles, DeletionAvailable = False)
	
	TreeRows.Clear();
	
	For Each XDTOFile In XDTOFiles Do
		FileString = TreeRows.Add();
		FileString.SubjectOf = XDTOFile.name;
		FileString.SubjectOfType = XDTOFile.objectID.type;
		FileString.SubjectOfID = XDTOFile.objectID.ID;
		FileString.Extension = XDTOFile.extension;
		
		DeletionMark = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "deletionMark") Then
			DeletionMark = XDTOFile.deletionMark;
		EndIf;
		FileString.Picture =
			IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
				FileString.Extension,
				DeletionMark);
		
		If FileCaptureIsAvailable Then
			FileString.IsBeingEdited = XDTOFile.editing;
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOFile, "editingUser") Then
				FileString.EditedByCurUser = (Upper(XDTOFile.editingUser.name) = Upper(UserName));
			EndIf;
		EndIf;
		FileString.Presentation = FileString.SubjectOf;
		FileString.DeletionAvailable = DeletionAvailable;
	EndDo;
	
EndProcedure

&AtServer
Function ThisIsTheRoutePoint(RoutePointName)
	
	If RoutePoint = RoutePointName Then
		Return True
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure FillInTheDataACApproval(TaskObject)
	
	// Filling in the iteration number
	IterationNumber = TaskObject.iterationNumber;
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;

	If ThisIsTheRoutePoint("Согласовать") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã thống nhất';
											|ru = 'Согласовано';
											|en = 'Approved'; fa = 'تأییدشده';
											|it = 'Concordato';
											|pl = 'Uzgodniono';
											|tr = 'Onaylandı'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Đã thống nhất
															|và có lưu ý';
															|ru = 'Согласовано
															|с замечаниями';
															|en = 'Approved with 
															|comments'; fa = 'Approved with 
															|comments';
															|it = 'Omologato
															| con note';
															|pl = 'Uzgodniono
															|z uwagami';
															|tr = 'Yorumlarla
															|onaylandı'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.PositiveTaskCompletionFlag;
		Items.ExecuteTaskThird.Title = NStr("vi = 'Không thống nhất';
											|ru = 'Не согласовано';
											|en = 'Not approved'; fa = 'تأییدنشده';
											|it = 'Non concordato';
											|pl = 'Nie uzgodniono';
											|tr = 'Onaylanmadı'");
		
		Items.GroupCycle.Visible = True;
		
		// Filling in the task approval result
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.approvalResult, "Result");
		
		If Executed Then
			Items.ExecutionResultText.Title = String(Result) + ".";
			If ResultID = "Согласовано" Or ResultID = "СогласованоСЗамечаниями" Then //@NON-NLS-1 @NON-NLS-2
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			ElsIf ResultID = "НеСогласовано" Then //@NON-NLS-1
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			EndIf;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
											|ru = 'Ознакомился';
											|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
											|it = 'Esaminato';
											|pl = 'I have read and understood';
											|tr = 'Tanıştı'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Thống nhất lại...';
											|ru = 'Повторить согласование...';
											|en = 'Repeat approval...'; fa = 'Repeat approval...';
											|it = 'Ripetere omologazione...';
											|pl = 'Powtórz uzgodnienie...';
											|tr = 'Onaylamayı tekrarla...'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		
		// Filling in the approval result
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.approvalResult, "Result");
		SubmittedForRenegotiation = TaskObject.returned;
		
		// Filling out the approval sheet
		For Each ResultString1 In TaskObject.approvalResults Do
			RowOfExecution = Assignees.Add();
			RowOfExecution.ExecutionResult = ResultString1.approvalComment;
			RowOfExecution.CompletionDate = ResultString1.approvalDate;
			RowOfExecution.PictureStateValue = 1;
			FillInAddressData(RowOfExecution, ResultString1.approvalPerformer);
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				RowOfExecution,
				ResultString1.approvalResult,
				"Result");
		EndDo;
		
		Items.ApprovalGroup.Visible = True;
		Items.Assignees.Visible = True;
		Items.AssigneesPerformer.Title = NStr("vi = 'Người thống nhất';
												|ru = 'Согласующее лицо';
												|en = 'Approver'; fa = 'تأییدکننده';
												|it = 'Autorità di omologazione';
												|pl = 'Osoba uzgadniająca';
												|tr = 'Onaylayan'");
		Items.AssigneesCompletionDate.Visible = False;
		Items.PerformersDateOfApproval.Visible = True;
		Items.AssigneesResult.Visible = True;
		Items.ExecutionResult.Visible = False;
		Items.ExecutionResultHidden.Visible = True;
		Items.Assignees.TitleLocation = FormItemTitleLocation.None;

		If (ResultID = "Согласовано") Or (ResultID = "СогласованоСЗамечаниями") Then //@NON-NLS-1 @NON-NLS-2
			Items.ApprovalResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		ElsIf ResultID = "НеСогласовано" Then //@NON-NLS-1
			Items.ApprovalResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		EndIf;
		
		// Button headers
		If ResultID = "НеСогласовано" Then //@NON-NLS-1
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã kết thúc thống nhất';
												|ru = 'Завершить согласование';
												|en = 'Complete approval'; fa = 'Complete approval';
												|it = 'Completare omologazione';
												|pl = 'Zakończ uzgodnienie';
												|tr = 'Onaylamayı tamamla'");
		Else
			Items.ExecuteTaskSecond.Visible = False;
		EndIf;
		
		// Filling in the text of the execution result for the completed task
		If SubmittedForRenegotiation <> Undefined Then
			If SubmittedForRenegotiation Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã gửi để thống nhất lại.';
														|ru = 'Отправлено на повторное согласование.';
														|en = 'Sent for reapproval.'; fa = 'Sent for reapproval.';
														|it = 'Inviato per ripetizione omologazione.';
														|pl = 'Wysłano na ponowne uzgodnienie.';
														|tr = 'Tekrar onaylama için gönderildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
														|ru = 'Ознакомился.';
														|en = 'I have read and understood.'; fa = 'I have read and understood.';
														|it = 'Esaminato.';
														|pl = 'I have read and understood.';
														|tr = 'Tanıştı.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		EndIf;
		
	EndIf;
	
	If IterationNumber <= 1 Then
		Items.ApprovalIterationNumber.Visible = False;
		Items.IterationNumberApproval.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheDataForTheConfirmation(TaskObject)
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	
	// Filling in the iteration number
	IterationNumber = TaskObject.iterationNumber;
	
	If IntegrationWith1CDocumentManagementCore.PropertyExists(TaskObject.parentBusinessProcess, "processType") Then
		ThisIsSigning = (TaskObject.parentBusinessProcess.processType.objectID.ID = "Подписание"); //@NON-NLS-1
	Else
		ThisIsSigning = False;
	EndIf;
	
	If ThisIsTheRoutePoint("Утвердить") Then //@NON-NLS-1
		
		If ThisIsSigning Then
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Ký tên';
												|ru = 'Подписать';
												|en = 'Sign'; fa = 'امضا';
												|it = 'Firmare';
												|pl = 'Sign';
												|tr = 'İmzala'");
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Từ chối';
												|ru = 'Отклонить';
												|en = 'Reject'; fa = 'رد';
												|it = 'Declinare';
												|pl = 'Reject';
												|tr = 'Reddet'");
		Else
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã duyệt';
												|ru = 'Утверждено';
												|en = 'Confirmed'; fa = 'تأییدشده';
												|it = 'Confermato';
												|pl = 'Confirmed';
												|tr = 'Onaylandı'");
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Không duyệt';
												|ru = 'Не утверждено';
												|en = 'Not confirmed'; fa = 'تصدیق‌نشده';
												|it = 'Non confermato';
												|pl = 'Nie zatwierdzono';
												|tr = 'Onaylanmadı'");
		EndIf;
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		
		Items.GroupCycle.Visible = True;
		
		// Filling in the approval result
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.confirmationResult, "Result");
		
		If Executed Then
			If ThisIsSigning Then
				If ResultID = "Утверждено" Then //@NON-NLS-1
					Items.ExecutionResultText.Title = NStr("vi = 'Đã ký.';
															|ru = 'Подписано.';
															|en = 'Signed.'; fa = 'Signed.';
															|it = 'Firmato.';
															|pl = 'Signed.';
															|tr = 'İmzalandı.'");
				Else
					Items.ExecutionResultText.Title = NStr("vi = 'Chưa ký.';
															|ru = 'Не подписано.';
															|en = 'Not signed.'; fa = 'Not signed.';
															|it = 'Non firmato.';
															|pl = 'Nie podpisano.';
															|tr = 'İmzalanmadı.'");
				EndIf;
			Else
				Items.ExecutionResultText.Title = String(Result) + ".";
			EndIf;
			If ResultID = "Утверждено" Then //@NON-NLS-1
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			ElsIf ResultID = "НеУтверждено" Then //@NON-NLS-1
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			EndIf;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
											|ru = 'Ознакомился';
											|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
											|it = 'Esaminato';
											|pl = 'I have read and understood';
											|tr = 'Tanıştı'");
		If ThisIsSigning Then
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Ký lại...';
												|ru = 'Повторить подписание...';
												|en = 'Repeat signature...'; fa = 'Repeat signature...';
												|it = 'Ripetere firma...';
												|pl = 'Powtórz podpisanie...';
												|tr = 'İmzalamayı tekrarla...'");
			Items.ConfirmationResult.Title = NStr("vi = 'Kết quả ký';
													|ru = 'Результат подписания';
													|en = 'Signature result'; fa = 'Signature result';
													|it = 'Risultato di firma';
													|pl = 'Wynik podpisania';
													|tr = 'Sonuç imzalama'");
			Items.Approving.Title = NStr("vi = 'Người ký';
										|ru = 'Подписант';
										|en = 'Signer'; fa = 'امضاکننده';
										|it = 'Firmatario';
										|pl = 'Signer';
										|tr = 'İmzacı'");
			Items.ConfirmationDate.Title = NStr("vi = 'Ngày ký';
												|ru = 'Дата подписания';
												|en = 'Date signed'; fa = 'تاریخ امضا';
												|it = 'Data di firma';
												|pl = 'Data podpisania';
												|tr = 'İmzalama tarihi'");
		Else
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Duyệt lại...';
												|ru = 'Повторить утверждение...';
												|en = 'Repeat confirmation...'; fa = 'Repeat confirmation...';
												|it = 'Ripetere conferma...';
												|pl = 'Potwierdź zatwierdzenie...';
												|tr = 'Onaylamayı tekrarla...'");
		EndIf;
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		
		SubmittedForReApproval = TaskObject.returned;
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.confirmationResult, "Result");
		If ThisIsSigning Then
			If ResultID = "Утверждено" Then //@NON-NLS-1
				Result = NStr("vi = 'Đã ký';
								|ru = 'Подписано';
								|en = 'Signed'; fa = 'امضاشده';
								|it = 'Firmato';
								|pl = 'Podpisano';
								|tr = 'İmzalandı'");
			Else
				Result = NStr("vi = 'Chưa ký';
								|ru = 'Не подписано';
								|en = 'Not signed'; fa = 'Not signed';
								|it = 'Non firmato';
								|pl = 'Nie podpisano';
								|tr = 'İmzalanmadı'");
			EndIf;
		EndIf;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.confirmationPerformer.user, "Approving");
		ConfirmationDate = TaskObject.confirmationDate;
		ResultOfStatementExecution = TaskObject.confirmationComment;
		
		Items.ConfirmationGroup.Visible = True;
		Items.ExecutionResult.Visible = False;
		Items.ExecutionResultHidden.Visible = True;
		
		If (ResultID = "Утверждено") Then //@NON-NLS-1
			Items.ConfirmationResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		ElsIf ResultID = "НеУтверждено" Then //@NON-NLS-1
			Items.ConfirmationResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		EndIf;
		
		// Button headers
		If ResultID = "НеУтверждено" Then //@NON-NLS-1
			If ThisIsSigning Then
				Items.ExecuteTaskFirst.Title = NStr("vi = 'Hoàn thành ký tên';
													|ru = 'Завершить подписание';
													|en = 'Complete signature'; fa = 'Complete signature';
													|it = 'Completare firma';
													|pl = 'Zakończ podpisanie';
													|tr = 'İmzalamayı tamamla'");
			Else
				Items.ExecuteTaskFirst.Title = NStr("vi = 'Hoàn thành quy trình phê duyệt';
													|ru = 'Завершить утверждение';
													|en = 'Complete confirmation'; fa = 'Complete confirmation';
													|it = 'Completare conferma';
													|pl = 'Zakończ zatwierdzenie';
													|tr = 'Onaylamayı tamamla'");
			EndIf;
		Else
			Items.ExecuteTaskSecond.Visible = False;
		EndIf;
		
		// Filling in the text of the execution result for the completed task
		If SubmittedForReApproval <> Undefined Then
			If SubmittedForReApproval Then
				If ThisIsSigning Then
					Items.ExecutionResultText.Title = NStr("vi = 'Đã gửi để ký lại.';
															|ru = 'Отправлено на повторную подпись.';
															|en = 'Sent to resignature.'; fa = 'Sent to resignature.';
															|it = 'Inviato per la ripetizione della firma.';
															|pl = 'Wysłano na ponowne podpisanie.';
															|tr = 'Yeniden imzalamak için gönderildi.'");
				Else
					Items.ExecutionResultText.Title = NStr("vi = 'Đã gửi để duyệt lại.';
															|ru = 'Отправлено на повторное утверждение.';
															|en = 'Sent for reconfirmation.'; fa = 'Sent for reconfirmation.';
															|it = 'Inviato per ripetizione conferma.';
															|pl = 'Wysłano na ponowne zatwierdzenie.';
															|tr = 'Yeniden onay için gönderildi.'");
				EndIf;
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
														|ru = 'Ознакомился.';
														|en = 'I have read and understood.'; fa = 'I have read and understood.';
														|it = 'Esaminato.';
														|pl = 'I have read and understood.';
														|tr = 'Tanıştı.'");
				Items.ExecutionResultText.TextColor = StyleColors.MarkOfNeutralTaskExecution;
			EndIf;
		EndIf;
		
	EndIf;
	
	If IterationNumber <= 1 Then
		Items.NumberOfApprovalIteration.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfBPOrder(Proxy, TaskObject)
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	
	If ThisIsTheRoutePoint("Выполнить") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã thực hiện';
											|ru = 'Выполнено';
											|en = 'Completed'; fa = 'تکمیل‌شده';
											|it = 'Completato';
											|pl = 'Completed';
											|tr = 'Gerçekleştirildi'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã thực hiện.';
													|ru = 'Выполнено.';
													|en = 'Executed.'; fa = 'Executed.';
													|it = 'Completato.';
													|pl = 'Executed.';
													|tr = 'Gerçekleştirildi.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Проверить") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Hoàn thành ủy nhiệm';
											|ru = 'Завершить поручение';
											|en = 'Complete the order'; fa = 'Complete the order';
											|it = 'Terminare commissione';
											|pl = 'Zakończ polecenie';
											|tr = 'Görevi tamamla'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Trả lại để hoàn thiện';
											|ru = 'Вернуть на доработку';
											|en = 'Return for revision'; fa = 'Return for revision';
											|it = 'Restituire in rilavorazione';
											|pl = 'Zwróć na dopracowanie';
											|tr = 'Revizyona gönder'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		
		// Filling in the execution result
		If IntegrationWith1CDocumentManagementCore.PropertySet(TaskObject, "returned") Then
			ReturnedForRevision = TaskObject.returned;
		Else
			ReturnedForRevision = False;
		EndIf;
		
		// Filling in the text of the execution result for the completed task
		If Executed Then
			If ReturnedForRevision Then
				Items.ExecutionResultText.Title = NStr("vi = 'Trả lại để hoàn thiện.';
														|ru = 'Возвращено на доработку.';
														|en = 'Returned for revision.'; fa = 'Returned for revision.';
														|it = 'Restituito in rilavorazione.';
														|pl = 'Zwrócono na dopracowanie.';
														|tr = 'Revizyon için iade edildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
														|ru = 'Ознакомился.';
														|en = 'I have read and understood.'; fa = 'I have read and understood.';
														|it = 'Esaminato.';
														|pl = 'I have read and understood.';
														|tr = 'Tanıştı.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Контролировать") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Bỏ kiểm soát';
											|ru = 'Снять с контроля';
											|en = 'Remove from control'; fa = 'Remove from control';
											|it = 'Rimuovere dal controllo';
											|pl = 'Usuń z kontroli';
											|tr = 'Kontrolden kaldır'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Bỏ kiểm soát.';
													|ru = 'Снято с контроля.';
													|en = 'Removed from control.'; fa = 'Removed from control.';
													|it = 'Rimosso dal controllo.';
													|pl = 'Usunięto z kontroli.';
													|tr = 'Kontrolden kaldırıldı.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		Items.Assignees.Visible = True;
		Items.Assignees.ChildItems.AssigneesTaskDueDate.Visible = True;
		Items.Assignees.ChildItems.AssigneesExecuted.Visible = True;
		
		TaskList = GetBusinessProcessTasks(Proxy);
		For Each Task In TaskList Do
			If Find(Task.businessProcessStep, "Контролировать") <> 0 Then  //@NON-NLS-1
				RowOfExecution = Assignees.Add();
				FillInIssueLine(RowOfExecution,Task);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataACExecution(Proxy, TaskObject)
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	
	If ThisIsTheRoutePoint("Исполнить") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã thực hiện';
											|ru = 'Исполнено';
											|en = 'Executed'; fa = 'Executed';
											|it = 'Eseguito';
											|pl = 'Executed';
											|tr = 'Yürütüldü'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã thực hiện.';
													|ru = 'Исполнено.';
													|en = 'Executed.'; fa = 'Executed.';
													|it = 'Eseguito.';
													|pl = 'Executed.';
													|tr = 'Yürütüldü.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("ОтветственноеИсполнение") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã thực hiện';
											|ru = 'Исполнено';
											|en = 'Executed'; fa = 'Executed';
											|it = 'Eseguito';
											|pl = 'Executed';
											|tr = 'Yürütüldü'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã thực hiện và kiểm tra.';
													|ru = 'Исполнено и проверено.';
													|en = 'Executed and checked.'; fa = 'Executed and checked.';
													|it = 'Eseguito e verificato.';
													|pl = 'Wykonano i sprawdzono.';
													|tr = 'Yürütüldü ve kontrol edildi.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		Items.Assignees.Visible = True;
		Items.Assignees.Title = NStr("vi = 'Đồng thực hiện';
									|ru = 'Соисполнители';
									|en = 'Co-executors'; fa = 'Co-executors';
									|it = 'Co-executors';
									|pl = 'Co-executors';
									|tr = 'Müşterek atananlar'");
		Items.Assignees.ChildItems.AssigneesTaskDueDate.Visible = True;
		Items.Assignees.ChildItems.AssigneesExecuted.Visible = True;
		Items.AssigneesExecuted.Visible = False;
		
		TaskList = GetBusinessProcessTasks(Proxy);
		
		For Each Task In TaskList Do
			If Task.businessProcessStep = "Исполнить" Then //@NON-NLS-1
				RowOfExecution = Assignees.Add();
				FillInIssueLine(RowOfExecution,Task);
			EndIf;
		EndDo;
		
	ElsIf ThisIsTheRoutePoint("Контролировать") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Bỏ kiểm soát';
											|ru = 'Снять с контроля';
											|en = 'Remove from control'; fa = 'Remove from control';
											|it = 'Rimuovere dal controllo';
											|pl = 'Usuń z kontroli';
											|tr = 'Kontrolden kaldır'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã kiểm soát.';
													|ru = 'Проконтролировано.';
													|en = 'Controlled.'; fa = 'Controlled.';
													|it = 'Controllato.';
													|pl = 'Controlled.';
													|tr = 'Kontrollü.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		Items.Assignees.Visible = True;
		Items.Assignees.Title = NStr("vi = 'Quá trình thực hiện';
									|ru = 'Ход исполнения';
									|en = 'Performance process'; fa = 'Performance process';
									|it = 'Codice di esecuzione';
									|pl = 'Tok wykonania';
									|tr = 'Yürütme süreci'");
		Items.AssigneesTaskDueDate.Visible = True;
		Items.AssigneesExecuted.Visible = True;
		Items.AssigneesPictureStateValue.Visible = False;
		Items.AssigneesPictureResponsible.Visible = True;
		
		TaskList = GetBusinessProcessTasks(Proxy);
		For Each Task In TaskList Do
			If Find(Task.businessProcessStep, "Контролировать") = 0 Then  //@NON-NLS-1
				RowOfExecution = Assignees.Add();
				FillInIssueLine(RowOfExecution,Task);
				If Find(Task.businessProcessStep, "Ответственное") <> 0 Then //@NON-NLS-1
					RowOfExecution.PictureResponsible = True;
				EndIf;
			EndIf;
		EndDo;
		
	ElsIf ThisIsTheRoutePoint("Проверить") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã kiểm tra';
											|ru = 'Проверено';
											|en = 'Checked'; fa = 'بررسی‌شده';
											|it = 'Controllato';
											|pl = 'Checked';
											|tr = 'Kontrol edildi'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã kết thúc.';
													|ru = 'Завершено.';
													|en = 'Completed'; fa = 'تکمیل‌شده';
													|it = 'Completato.';
													|pl = 'Completed';
													|tr = 'Tamamlandı.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			Items.AssigneesSentForRevision.ReadOnly = True;
			Items.AssigneesReviewerSComment.ReadOnly = True;
		EndIf;
		Items.GroupCycleExecution.Visible = True;
		Items.ExecutionResult.Visible = False;
		Items.Assignees.Visible = True;
		Items.Assignees.ReadOnly = False;
		Items.Assignees.TitleLocation = FormItemTitleLocation.None;
		Items.PerformersComment.Title = NStr("vi = 'Kết quả thực hiện';
											|ru = 'Результат выполнения';
											|en = 'Execution result'; fa = 'نتیجه اجرا';
											|it = 'Risultato di esecuzione';
											|pl = 'Rezultat wykonania';
											|tr = 'Yürütme sonucu'");
		Items.AssigneesSentForRevision.Visible = True;
		Items.AssigneesSentForRevision.Title = NStr("vi = 'Trả lại để hoàn thiện';
													|ru = 'Вернуть на доработку';
													|en = 'Return for revision'; fa = 'Return for revision';
													|it = 'Restituire in rilavorazione';
													|pl = 'Zwróć na dopracowanie';
													|tr = 'Revizyona gönder'");
		Items.AssigneesReviewerSComment.Visible = True;
		Items.AssigneesPictureStateValue.Visible = False;
		Items.AssigneesPictureResponsible.Visible = True;
		
		IterationNumber = TaskObject.iterationNumber;
		
		For Each XDTORow In TaskObject.checkResults Do
			RowOfExecution = Assignees.Add();
			FillInIssueLine(RowOfExecution, XDTORow.executorTask);
			RowOfExecution.TaskID = XDTORow.executorTask.objectID.ID;
			RowOfExecution.SentForRevision = XDTORow.returned;
			RowOfExecution.ReviewerSComment = XDTORow.checkComment;
			RowOfExecution.IterationNumber = TaskObject.iterationNumber;
			If Find(XDTORow.executorTask.businessProcessStep, "Ответственное") <> 0 Then //@NON-NLS-1
				RowOfExecution.PictureResponsible = True;
			EndIf;
		EndDo;
		
	EndIf;
	
	If IterationNumber <= 1 Then
		Items.ExecutionIterationNumber.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBPDataFamiliarization()
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
										|ru = 'Ознакомился';
										|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
										|it = 'Esaminato';
										|pl = 'I have read and understood';
										|tr = 'Tanıştı'");
	Items.ExecuteTaskSecond.Visible = False;
	Items.ExecuteTaskThird.Visible = False;
	
	If Executed Then
		Items.ExecutionResultText.Title = NStr("vi = 'Bỏ kiểm soát.';
												|ru = 'Снято с контроля.';
												|en = 'Removed from control.'; fa = 'Removed from control.';
												|it = 'Rimosso dal controllo.';
												|pl = 'Usunięto z kontroli.';
												|tr = 'Kontrolden kaldırıldı.'");
		Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
	EndIf;
		
	If ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
													|ru = 'Ознакомился.';
													|en = 'I have read and understood.'; fa = 'I have read and understood.';
													|it = 'Esaminato.';
													|pl = 'I have read and understood.';
													|tr = 'Tanıştı.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInACData(TaskObject)
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	
	// Iterations
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.1.3") Then
		
		If ThisIsTheRoutePoint("Зарегистрировать") Then //@NON-NLS-1
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã đăng ký';
												|ru = 'Зарегистрировано';
												|en = 'Registered'; fa = 'ثبت‌شده';
												|it = 'Registrato';
												|pl = 'Registered';
												|tr = 'Kaydedildi'");
			Items.ExecuteTaskSecond.Visible = False;
			Items.ExecuteTaskThird.Visible = False;
			If Executed Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã đăng ký và gửi đi.';
														|ru = 'Зарегистрировано и отправлено.';
														|en = 'Registered and sent.'; fa = 'Registered and sent.';
														|it = 'Registrato e inviato.';
														|pl = 'Zarejestrowano i wysłano.';
														|tr = 'Kaydedildi ve gönderildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
												|ru = 'Ознакомился';
												|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
												|it = 'Esaminato';
												|pl = 'I have read and understood';
												|tr = 'Tanıştı'");
			Items.ExecuteTaskSecond.Visible = False;
			Items.ExecuteTaskThird.Visible = False;
			If Executed Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
														|ru = 'Ознакомился.';
														|en = 'I have read and understood.'; fa = 'I have read and understood.';
														|it = 'Esaminato.';
														|pl = 'I have read and understood.';
														|tr = 'Tanıştı.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		EndIf;
		
	Else
		// Filling in the iteration number
		IterationNumber = TaskObject.iterationNumber;
		
		If ThisIsTheRoutePoint("Зарегистрировать") Then //@NON-NLS-1
			
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đăng ký';
												|ru = 'Зарегистрировать';
												|en = 'Register'; fa = 'ثبات';
												|it = 'Registra';
												|pl = 'Register';
												|tr = 'Kayıt ol'");
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Chưa đăng ký';
												|ru = 'Не регистрировать';
												|en = 'Do not register'; fa = 'ثبت نشود';
												|it = 'Non registrare';
												|pl = 'Nie rejestruj';
												|tr = 'Kayıt yaptırma'");
			Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Items.ExecuteTaskThird.Visible = False;
			
			If IterationNumber > 1 Then
				Items.GroupCycle.Visible = True;
			EndIf;
			
			// Filling in the approval result
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				ThisObject,
				TaskObject.registrationResult,
				"Result");
			
			If Executed Then
				Items.ExecutionResultText.Title = String(Result) + ".";
				If ResultID = "Зарегистрировано" Then //@NON-NLS-1
					Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
				ElsIf ResultID = "НеЗарегистрировано" Then //@NON-NLS-1
					Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
				EndIf;
			EndIf;
			
		ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
			
			Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
												|ru = 'Ознакомился';
												|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
												|it = 'Esaminato';
												|pl = 'I have read and understood';
												|tr = 'Tanıştı'");
			Items.ExecuteTaskSecond.Title = NStr("vi = 'Đăng ký lại...';
												|ru = 'Повторить регистрацию...';
												|en = 'Repeat registration ...'; fa = 'Repeat registration ...';
												|it = 'Ripetere registrazione...';
												|pl = 'Powtórz rejestrację...';
												|tr = 'Kaydı tekrarla...'");
			Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Items.ExecuteTaskThird.Visible = False;
			
			SubmittedForReRegistration = TaskObject.returned;
			
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				ThisObject,
				TaskObject.registrationResult,
				"Result");
			
			Items.GroupRegistration.Visible = True;
			Items.ExecutionResult.Visible = False;
			Items.ExecutionResultHidden.Visible = True;
			
			If (ResultID = "Зарегистрировано") Then //@NON-NLS-1
				Items.RegistrationResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
			ElsIf ResultID = "НеЗарегистрировано" Then //@NON-NLS-1
				Items.RegistrationResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
			EndIf;
			
			// Button headers
			If ResultID = "НеЗарегистрировано" Then //@NON-NLS-1
				Items.ExecuteTaskFirst.Title = NStr("vi = 'Hoàn thành đăng ký';
													|ru = 'Завершить регистрацию';
													|en = 'Complete registration'; fa = 'Complete registration';
													|it = 'Completare registrazione';
													|pl = 'Zakończ rejestrację';
													|tr = 'Kaydı tamamla'");
			Else
				Items.ExecuteTaskSecond.Visible = False;
			EndIf;
			
			// Filling in the text of the execution result for the completed task
			If SubmittedForReRegistration <> Undefined Then
				If SubmittedForReRegistration Then
					Items.ExecutionResultText.Title = NStr("vi = 'Đã gửi để đăng ký lại.';
															|ru = 'Отправлено на повторную регистрацию.';
															|en = 'Sent for re-registration.'; fa = 'Sent for re-registration.';
															|it = 'Inviato al nuovo tentativo di registrazione.';
															|pl = 'Wysłano na ponowną rejestrację.';
															|tr = 'Tekrar kayda gönderildi.'");
					Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
				Else
					Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
															|ru = 'Ознакомился.';
															|en = 'I have read and understood.'; fa = 'I have read and understood.';
															|it = 'Esaminato.';
															|pl = 'I have read and understood.';
															|tr = 'Tanıştı.'");
					Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
				EndIf;
			EndIf;
			
		EndIf;
		
		If IterationNumber <= 1 Then
			Items.RegistrationIterationNumber.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInUAVData(TaskObject)
	
	If ThisIsTheRoutePoint("Рассмотреть") Then //@NON-NLS-1
		Items.ExecutionResult.InputHint = NStr("vi = 'Khuyến nghị của bạn';
												|ru = 'Ваша резолюция';
												|en = 'Your resolution'; fa = 'Your resolution';
												|it = 'La vostra risoluzione';
												|pl = 'Twoja rezolucja';
												|tr = 'Sizin karar'");
		
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã xem xét';
											|ru = 'Рассмотрено';
											|en = 'Reviewed'; fa = 'بررسی‌شده';
											|it = 'Analizzato';
											|pl = 'Reviewed';
											|tr = 'İncelendi'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã xem xét.';
													|ru = 'Рассмотрено.';
													|en = 'Reviewed.'; fa = 'Reviewed.';
													|it = 'Analizzato.';
													|pl = 'Reviewed.';
													|tr = 'İncelendi.'");
			Items.ExecutionResultText.TextColor = StyleColors.MarkOfNeutralTaskExecution;
		EndIf;
		Items.ExecutionResult.AutoMarkIncomplete = True;
		
	ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã xử lý';
											|ru = 'Обработано';
											|en = 'Processed'; fa = 'پردازش‌شده';
											|it = 'Elaborato';
											|pl = 'Processed';
											|tr = 'İşlendi'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã xử lý.';
													|ru = 'Обработано.';
													|en = 'Processed.'; fa = 'Processed.';
													|it = 'Elaborato.';
													|pl = 'Processed.';
													|tr = 'İşlendi.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		Resolution = TaskObject.resolution;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.resolutionPerformer.user, "ResolutionOfSession");
		ResolutionDateOfConsideration = TaskObject.resolutionDate;
		
		Items.Resolution.Visible = True;
		Items.Resolution.Title = StrTemplate(NStr("vi = 'Khuyến nghị (%1, %2)';
													|ru = 'Резолюция (%1, %2)';
													|en = 'Resolution (%1, %2)'; fa = 'Resolution (%1, %2)';
													|it = 'Risoluzione (%1, %2)';
													|pl = 'Rezolucja (%1, %2)';
													|tr = 'Karar (%1, %2)'"),
			ResolutionOfSession, ResolutionDateOfConsideration);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillingInBPDataIsComplexProcess(Proxy, ProcessObject_)
	
	Items.ExecutionResult.Visible = False;
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	
	If ThisIsTheRoutePoint("Контролировать") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã kiểm soát';
											|ru = 'Проконтролировано';
											|en = 'Monitored'; fa = 'Monitored';
											|it = 'Controllato';
											|pl = 'Monitored';
											|tr = 'Kontrollü'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Bỏ kiểm soát.';
													|ru = 'Снято с контроля.';
													|en = 'Removed from control.'; fa = 'Removed from control.';
													|it = 'Rimosso dal controllo.';
													|pl = 'Usunięto z kontroli.';
													|tr = 'Kontrolden kaldırıldı.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		Items.Stages.Visible = True;
		LineNumber = 1;
		For Each Stage In ProcessObject_.stages Do
			NewRow = Stages.Add();
			NewRow.LineNumber = LineNumber;
			
			NewRow.Importance = 1;
			If IntegrationWith1CDocumentManagementCore.PropertySet(Stage, "importance") Then
				If Stage.importance.objectID.ID = "Низкая" Then //@NON-NLS-1
					NewRow.Importance = 0;
				ElsIf Stage.importance.objectID.ID = "Обычная" Then //@NON-NLS-1
					NewRow.Importance = 1;
				ElsIf Stage.importance.objectID.ID = "Высокая" Then //@NON-NLS-1
					NewRow.Importance = 2;
				EndIf;
			EndIf;
			
			NewRow.StageID = Stage.stageID;
			NewRow.StringPerformers = Stage.participants;
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, Stage.template, "BusinessProcessTemplate");
			AddTemplateNameByTemplateType(NewRow);
			NewRow.PredecessorsOfStringStage = Stage.stagePredecessors;
			NewRow.PredecessorsUseCase = Stage.predecessorsUseOption;
			NewRow.UnconditionalTransitionToNextWasPerformed = Stage.unconditionalPassageExecuted;
			NewRow.TaskExecuted = Stage.executed;
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(NewRow, Stage.businessProcess, "RunningBusinessProcess");
			NewRow.DueDate = Stage.duration;
			LineNumber = LineNumber + 1;
			If IntegrationWith1CDocumentManagementCore.PropertySet(Stage, "businessProcess") Then
				NewRow.DueDate_2 = Stage.businessProcess.dueDate;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBPDataSolvingQuestions(TaskObject)
	
	// solving issues of completing tasks
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
		DisplayInformationAboutUnavailabilityOfTask();
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		TaskObject.issueTask.parentBusinessProcess,
		"BusinessProcessOfSubjectOfConsideration",
		True);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		TaskObject.issueTask,
		"SubjectOfConsideration",
		True);
	If IntegrationWith1CDocumentManagementCore.PropertySet(TaskObject, "issueType") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.issueType,
			"TypeOfQuestion");
	ElsIf IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		TypeOfQuestion = NStr("vi = 'Khác';
								|ru = 'Иное';
								|en = 'Other'; fa = 'سایر';
								|it = 'Altro';
								|pl = 'Inne';
								|tr = 'Diğer'");
		TypeOfQuestionID = "Иное"; //@NON-NLS-1
		TypeOfQuestionType = "DMIssueType";
	EndIf;
	
	If ThisIsTheRoutePoint("РассмотрениеИнициатором") And TypeOfQuestionID = "ПереносСрока"
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then //@NON-NLS-1 @NON-NLS-2
		DisplayInformationAboutUnavailabilityOfTask();
		Return;
	EndIf;
	
	Items.AskAuthorQuestion.Visible = False;
	Items.FormForward.Visible = False;
	Items.GroupSubjectMatter.Visible = True;
	
	IterationNumber = TaskObject.iterationNumber;
	Items.Description.Title = NStr("vi = 'Tên gọi';
									|ru = 'Наименование';
									|en = 'Name'; fa = 'نام';
									|it = 'Nome';
									|pl = 'Name';
									|tr = 'Tanım'");
	Items.FullDescriptionOfTaskTitle.Title =
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lịch sử câu hỏi (vòng lặp: %1)';
																		|ru = 'История вопроса (цикл: %1)';
																		|en = 'Question background (cycle: %1)'; fa = 'Question background (cycle: %1)';
																		|it = 'Cronologia problema (ciclo: %1)';
																		|pl = 'Historia pytania (cykl: %1)';
																		|tr = 'Soru tarihçesi (döngü: %1)'"),IterationNumber);
	
	If ThisIsTheRoutePoint("РассмотрениеИнициатором") And TypeOfQuestionID = "Иное" Then //@NON-NLS-1 @NON-NLS-2
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã xem xét';
											|ru = 'Рассмотрено';
											|en = 'Reviewed'; fa = 'بررسی‌شده';
											|it = 'Analizzato';
											|pl = 'Reviewed';
											|tr = 'İncelendi'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã xem xét.';
													|ru = 'Рассмотрено.';
													|en = 'Reviewed.'; fa = 'Reviewed.';
													|it = 'Analizzato.';
													|pl = 'Reviewed.';
													|tr = 'İncelendi.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		Items.ExecutionResult.AutoMarkIncomplete = True;
		Items.ExecutionResult.AutoChoiceIncomplete = True;
		
	ElsIf ThisIsTheRoutePoint("РассмотрениеИнициатором") And TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1 @NON-NLS-2
		If TaskObject.parentBusinessProcess.Properties().Get("newDueDate") <> Undefined
				And TaskObject.parentBusinessProcess.Properties().Get("issueTask") <> Undefined Then
			OldDeadline = TaskObject.parentBusinessProcess.issueTask.dueDate;
			NewTerm = TaskObject.parentBusinessProcess.newDueDate;
			Items.GroupTerm.Visible = True;
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
		Else
			Items.GroupTerm.Visible = False;
		EndIf;
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Gia hạn';
											|ru = 'Перенести срок';
											|en = 'Move deadline'; fa = 'Move deadline';
											|it = 'Spostare termine';
											|pl = 'Przenieś termin';
											|tr = 'Tarihi taşı'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Từ chối gia hạn';
											|ru = 'Отказать в переносе';
											|en = 'Refuse to move'; fa = 'Refuse to move';
											|it = 'Rifiutare il trasferimento';
											|pl = 'Odmów w przenoszeniu';
											|tr = 'Aktarmada reddet'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		If Executed Then
			If TaskObject.executionMark = "ExecutedPositive" Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã gia hạn.';
														|ru = 'Срок исполнения перенесен.';
														|en = 'Due date is moved.'; fa = 'Due date is moved.';
														|it = 'Termine di esecuzione spostato.';
														|pl = 'Termin wykonania został przeniesiony.';
														|tr = 'Son tarih ertelendi.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			ElsIf TaskObject.executionMark = "ExecutedNegative" Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã từ chối gia hạn.';
														|ru = 'Отказано в переносе срока.';
														|en = 'Due date move is rejected.'; fa = 'Due date move is rejected.';
														|it = 'Negazione spostamento termine.';
														|pl = 'Odmówiono w przeniesieniu terminu.';
														|tr = 'Yürütülme tarihinin ertelenmesi reddedildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã xem xét.';
														|ru = 'Рассмотрено.';
														|en = 'Reviewed.'; fa = 'Reviewed.';
														|it = 'Analizzato.';
														|pl = 'Reviewed.';
														|tr = 'İncelendi.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("ОзнакомлениеСРезультатомРассмотрения") Then //@NON-NLS-1
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đóng câu hỏi';
											|ru = 'Закрыть вопрос';
											|en = 'Close issue'; fa = 'Close issue';
											|it = 'Chiudere domanda';
											|pl = 'Zamknij sprawę';
											|tr = 'Soruyu kapat'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Làm rõ';
											|ru = 'Уточнить';
											|en = 'Specify'; fa = 'تعیین';
											|it = 'Specificare';
											|pl = 'Specify';
											|tr = 'Kesinleştir'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		If IntegrationWith1CDocumentManagementCore.PropertySet(TaskObject, "returned") Then
			ReturnedForRevision = TaskObject.returned;
		Else
			ReturnedForRevision = False;
		EndIf;
		If TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1
			Items.ResultOfConsideration.Visible = True;
			If TaskObject.postponingAmount = 0 Then
				ResultOfConsideration = NStr("vi = 'Không thống nhất gia hạn.';
											|ru = 'Перенос срока не согласован.';
											|en = 'Deadline extension is not approved.'; fa = 'Deadline extension is not approved.';
											|it = 'Spostamento termine non concordato.';
											|pl = 'Przeniesienie terminu nie jest uzgodnione.';
											|tr = 'Tarihin ertelenmesi onaylanmadı.'");
				Items.ResultOfConsideration.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Else
				ResultOfConsideration = NStr("vi = 'Tác giả nhiệm vụ gia hạn.';
											|ru = 'Автор задачи перенес срок.';
											|en = 'Task author extended the deadline.'; fa = 'Task author extended the deadline.';
											|it = 'L''autore del compito ha spostato il termine.';
											|pl = 'Autor zadania przeniósł termin.';
											|tr = 'Görev sahibi tarihi erteledi.'");
			EndIf;
		EndIf;
		If Executed Then
			If ReturnedForRevision Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã gửi để làm rõ.';
														|ru = 'Отправлено на уточнение.';
														|en = 'Sent for clarification.'; fa = 'Sent for clarification.';
														|it = 'Inviato in precisazione.';
														|pl = 'Wysłano na uściślenie.';
														|tr = 'Kesinleştirmeye gönderildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.MarkOfNeutralTaskExecution;
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã thực hiện.';
														|ru = 'Выполнено.';
														|en = 'Executed.'; fa = 'Executed.';
														|it = 'Completato.';
														|pl = 'Executed.';
														|tr = 'Gerçekleştirildi.'");
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			EndIf;
		EndIf;
	Else
		DisplayInformationAboutUnavailabilityOfTask();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDataACInvitation(TaskObject)
	
	// BP Invitation
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3.CORP") Then
		DisplayInformationAboutUnavailabilityOfTask();
		Return;
	EndIf;
	
	Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
	IterationNumber = TaskObject.iterationNumber;
	
	If ThisIsTheRoutePoint("Пригласить") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Nhận lời mời';
											|ru = 'Принять приглашение';
											|en = 'Accept invitation'; fa = 'Accept invitation';
											|it = 'Accettare invito';
											|pl = 'Przyjmij zaproszenie';
											|tr = 'Daveti kabul et'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Hủy lời mời';
											|ru = 'Отклонить приглашение';
											|en = 'Reject invitation'; fa = 'Reject invitation';
											|it = 'Rifiutare invito';
											|pl = 'Odrzuć zaproszenie';
											|tr = 'Daveti reddet'");
		Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
		Items.ExecuteTaskThird.Visible = False;
		
		Items.GroupPlaceTime.Visible = True;
		StartDate = TaskObject.activityBegin;
		EndDate = TaskObject.activityEnd;
		Venue = TaskObject.activityVenue;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.invitationResult, "Result");
		If Executed Then
			Items.ExecutionResultText.Title = String(Result) + ".";
			If ResultID = "Принято" Then //@NON-NLS-1
				Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
			ElsIf ResultID = "НеПринято" Then //@NON-NLS-1
				Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
			EndIf;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Ознакомиться") Then //@NON-NLS-1
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Xác nhận lời mời';
											|ru = 'Подтвердить приглашения';
											|en = 'Confirm invitations'; fa = 'Confirm invitations';
											|it = 'Confermare invito';
											|pl = 'Zatwierdź zaproszenia';
											|tr = 'Daveti onayla'");
		Items.ExecuteTaskSecond.Title = NStr("vi = 'Mời lại...';
											|ru = 'Повторить приглашение...';
											|en = 'Repeat invitation ...'; fa = 'Repeat invitation ...';
											|it = 'Ripetere invito...';
											|pl = 'Powtórz zaproszenie...';
											|tr = 'Daveti tekrar et...'");
		Items.ExecuteTaskThird.Title = NStr("vi = 'Hủy lời mời';
											|ru = 'Отменить приглашение';
											|en = 'Cancel invitation'; fa = 'Cancel invitation';
											|it = 'Annullare invito';
											|pl = 'Anuluj zaproszenie';
											|tr = 'Daveti iptal et'");
		If Executed Then
			If TaskObject.invitationReturned Then
				Items.ExecutionResultText.Title = NStr("vi = 'Đã mời lại.';
														|ru = 'Отправлено на повторное приглашение.';
														|en = 'Sent to reinvite.'; fa = 'Sent to reinvite.';
														|it = 'Inviato per ripetizione invito.';
														|pl = 'Wysłano na ponowne zaproszenie.';
														|tr = 'Tekrar davet için gönderildi.'");
			Else
				Items.ExecutionResultText.Title = NStr("vi = 'Đã mời xong.';
														|ru = 'Приглашение завершено.';
														|en = 'Invitation completed.'; fa = 'Invitation completed.';
														|it = 'Invito completato.';
														|pl = 'Zaproszenie zostało zakończone.';
														|tr = 'Davet tamamlandı.'");
			EndIf;
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.invitationResult, "Result");
		
		// Result color
		If ResultID = "ПринятоВсемиУчастниками" Or ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
			Items.InvitationResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		Else
			Items.InvitationResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		EndIf;
		
		// Button headers
		If ResultID = "ПринятоВсемиУчастниками" Then //@NON-NLS-1
			Items.ExecuteTaskFirst.Visible = True;
			Items.ExecuteTaskSecond.Visible = False;
			Items.ExecuteTaskThird.Visible = False;
			
		ElsIf ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-1
			Items.ExecuteTaskFirst.Visible = True;
			Items.ExecuteTaskSecond.Visible = True;
			Items.ExecuteTaskSecond.TextColor = StyleColors.NegativeTaskCompletionFlag;
			Items.ExecuteTaskThird.Visible = False;
			
		ElsIf ResultID = "НеПринятоОбязательнымиУчастниками"
				Or ResultID = "НеПринятоВсемиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
			Items.ExecuteTaskFirst.Visible = False;
			Items.ExecuteTaskSecond.Visible = True;
			Items.ExecuteTaskSecond.TextColor = StyleColors.PositiveTaskCompletionFlag;
			Items.ExecuteTaskThird.Visible = True;
			
		EndIf;
		
		Items.GroupInvitation.Visible = True;
		Items.Assignees.Visible = True;
		Items.Assignees.TitleLocation = FormItemTitleLocation.None;
		Items.AssigneesPerformer.Title = NStr("vi = 'Người tham gia';
												|ru = 'Участник';
												|en = 'Participant'; fa = 'شرکت‌کننده';
												|it = 'Partecipante';
												|pl = 'Participant';
												|tr = 'Katılımcı'");
		Items.AssigneesResult.Visible = True;
		Items.AssigneesAttendanceIsRequired.Visible = True;
		Items.AssigneesCompletionDate.Visible = False;
		Items.ExecutionResult.Visible = False;
		Items.ExecutionResultHidden.Visible = True;
		
		// Filling out the invitation sheet
		For Each ResultString1 In TaskObject.invitationResults Do
			RowOfExecution = Assignees.Add();
			RowOfExecution.ExecutionResult = ResultString1.invitationComment;
			RowOfExecution.ResponseDate = ResultString1.invitationDate;
			RowOfExecution.PictureStateValue = 1;
			FillInAddressData(RowOfExecution, ResultString1.invitationPerformer);
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(RowOfExecution,
				ResultString1.invitationResult, "Result");
			RowOfExecution.AttendanceIsRequired =  ResultString1.invitationPerformer.attendanceCompulsory;
		EndDo;
		
		If IterationNumber <= 1 Then
			Items.InvitationIterationNumber.Visible = False;
		EndIf;
		
	ElsIf ThisIsTheRoutePoint("Оповестить") Then //@NON-NLS-1
		
		Items.ExecuteTaskFirst.Title = NStr("vi = 'Đã tham khảo';
											|ru = 'Ознакомился';
											|en = 'I have read and understood'; fa = 'مطالعه کردم و متوجه شدم';
											|it = 'Esaminato';
											|pl = 'I have read and understood';
											|tr = 'Tanıştı'");
		Items.ExecuteTaskSecond.Visible = False;
		Items.ExecuteTaskThird.Visible = False;
		
		Items.GroupPlaceTime.Visible = True;
		Items.GroupInvitation.Visible = True;
		Items.ExecutionCommandsGroup.Visible = ExecutionAvailable;
		
		StartDate = TaskObject.activityBegin;
		EndDate = TaskObject.activityEnd;
		Venue = TaskObject.activityVenue;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
			TaskObject.invitationResult, "Result");
		
		If Executed Then
			Items.ExecutionResultText.Title = NStr("vi = 'Đã tham khảo.';
													|ru = 'Ознакомился.';
													|en = 'I have read and understood.'; fa = 'I have read and understood.';
													|it = 'Esaminato.';
													|pl = 'I have read and understood.';
													|tr = 'Tanıştı.'");
			Items.ExecutionResultText.TextColor = StyleColors.PositiveTaskCompletionFlag;
		EndIf;
		
		// The result of the invitation
		If ResultID = "ПринятоВсемиУчастниками"
				Or ResultID = "ПринятоОбязательнымиУчастниками" Then //@NON-NLS-1 @NON-NLS-2
			Result =  NStr("vi = 'Đã xác nhận lời mời cùng địa điểm và thời gian chỉ định';
							|ru = 'Приглашение подтверждено с указанным местом и временем';
							|en = 'The invitation with the specified place and time is confirmed'; fa = 'The invitation with the specified place and time is confirmed';
							|it = 'Invito confermato con orario e luogo indicato';
							|pl = 'Zaproszenie zostało potwierdzone z określonym miejscem i czasem';
							|tr = 'Davet belirtilen yer ve saatle onaylandı'");
			Items.InvitationResult.TextColor = StyleColors.PositiveTaskCompletionFlag;
		Else
			Result =  NStr("vi = 'Lời mời đã bị hủy với địa điểm và thời gian đặt ra';
							|ru = 'Приглашение отменено с указанным местом и временем';
							|en = 'Invitation with specified place and time canceled'; fa = 'Invitation with specified place and time canceled';
							|it = 'Invito annullato con orario e luogo specificato';
							|pl = 'Zaproszenie zostało anulowane ze wskazaniem miejsca i czasu';
							|tr = 'Davet belirtilen yer ve saatte iptal edildi'");
			Items.InvitationResult.TextColor = StyleColors.NegativeTaskCompletionFlag;
		EndIf;
		
		If IterationNumber <= 1 Then
			Items.InvitationIterationNumber.Visible = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayInformationAboutUnavailabilityOfTask()
	
	Items.ExecutionCommandsGroup.Visible = False;
	Items.ExecutionResultText.Visible = True;
	Items.AttentionDecoration.Visible = True;
	
	Items.ExecutionResultText.Title = NStr("vi = 'Không hỗ trợ thực hiện nhiệm vụ kiểu này trong phiên bản 1C:Document Management hiện tại.';
											|ru = 'Выполнение задач такого типа не поддерживается в данной версии 1С:Документооборота.';
											|en = 'Tasks of this type are not supported in this version of 1C:Document Management.'; fa = 'Tasks of this type are not supported in this version of 1C:Document Management.';
											|it = 'Il completamento di compiti di questo tipo non è supportato in questa versione di 1C:Document Management.';
											|pl = 'Wykonanie zadań takiego typu nie jest obsługiwane w tej wersji 1C:Document Management.';
											|tr = 'Bu tür görevlerin gerçekleştirilmesi, 1C:Document Management''ın bu sürümünde desteklenmemektedir.'");
	Items.ExecutionResultText.TextColor = StyleColors.NegativeTaskCompletionFlag;
	
EndProcedure

&AtServer
Procedure AddTemplateNameByTemplateType(StageString_)
	
	Supplement = "";
	If StageString_.BusinessProcessTemplateType = "DMBusinessProcessOrderTemplate"	Then Supplement = NStr("vi = 'Ủy nhiệm';
																											|ru = 'Поручение';
																											|en = 'Instruction'; fa = 'دستورالعمل';
																											|it = 'Commissione';
																											|pl = 'Polecenie';
																											|tr = 'Görev'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessConsiderationTemplate" Then Supplement = NStr("vi = 'Xem xét';
																													|ru = 'Рассмотрение';
																													|en = 'Review'; fa = 'بررسی';
																													|it = 'Esaminazione';
																													|pl = 'Rozpatrzenie';
																													|tr = 'Değerlendirme'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessRegistrationTemplate" Then Supplement = NStr("vi = 'Đăng ký';
																													|ru = 'Регистрация';
																													|en = 'Registration'; fa = 'ثبت';
																													|it = 'Registrazione';
																													|pl = 'Rejestracja';
																													|tr = 'Kayıt'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessApprovalTemplate" 	Then Supplement = NStr("vi = 'Thống nhất';
																													|ru = 'Согласование';
																													|en = 'Approval'; fa = 'تأیید';
																													|it = 'Concordamento';
																													|pl = 'Uzgadnianie';
																													|tr = 'Anlaşma'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessConfirmationTemplate" Then Supplement = NStr("vi = 'Phê duyệt';
																													|ru = 'Утверждение';
																													|en = 'Confirmation'; fa = 'تأیید';
																													|it = 'Approvazione';
																													|pl = 'Zatwierdzenie';
																													|tr = 'Onay'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessPerformanceTemplate" 	Then Supplement = NStr("vi = 'Thực hiện';
																														|ru = 'Исполнение';
																														|en = 'Execution'; fa = 'اجرا';
																														|it = 'Esecuzione';
																														|pl = 'Wykonanie';
																														|tr = 'Yürütme'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMBusinessProcessAcquaintanceTemplate" Then Supplement = NStr("vi = 'Tham khảo';
																													|ru = 'Ознакомление';
																													|en = 'Preview'; fa = 'پیش‌نمایش';
																													|it = 'Riconoscimento';
																													|pl = 'Zapoznanie się';
																													|tr = 'Tanışma'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMCompoundBusinessProcessTemplate" 	Then Supplement = NStr("vi = 'Quy trình phức hợp';
																													|ru = 'Составной процесс';
																													|en = 'Multiple process'; fa = 'Multiple process';
																													|it = 'Processo composito';
																													|pl = 'Proces składowy';
																													|tr = 'Bileşik süreç'");
	ElsIf StageString_.BusinessProcessTemplateType = "DMComplexBusinessProcessTemplate" 		Then Supplement = NStr("vi = 'Quy trình tổng hợp';
																														|ru = 'Комплексный процесс';
																														|en = 'Complex process'; fa = 'Complex process';
																														|it = 'Processo complesso';
																														|pl = 'Proces kompleksowy';
																														|tr = 'Kapsamlı süreç'");
	EndIf;
	If Not IsBlankString(Supplement) Then
		StageString_.BusinessProcessTemplate = Supplement + ": " + StageString_.BusinessProcessTemplate;
	EndIf;
		
EndProcedure

&AtServer
Procedure FillInIssueLine(TaskLine,Task)
	
	FillInAddressData(TaskLine, Task.performer);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(TaskLine,Task,"Task");
	TaskLine.TaskDueDate = Task.dueDate;
	TaskLine.ExecutionResult = Task.executionComment;
	TaskLine.CompletionDate = Task.endDate;
	TaskLine.Executed = Task.executed;
	TaskLine.RoutePoint = Task.businessProcessStep;
	TaskLine.PictureStateValue = ?(TaskLine.Executed, 1, 0);
	
EndProcedure

&AtServer
Function GetBusinessProcessTasks(Proxy)
	
	Query = CreateObject(Proxy, "DMGetTasksTreeRequest");
	Filter = CreateObject(Proxy, "DMGetTasksTreeQuery");
	SelectionOfBusinessProcesses = Filter.businessProcess; // XDTOList
	
	XDTODataObject = CreateObject(Proxy,"DMObject");
	XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Process_ID,
		Process_Type);
	XDTODataObject.name = Process_;
	
	SelectionOfBusinessProcesses.Add(XDTODataObject);
	
	Query.query = Filter;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	Return Response.businessProcesses[0].tasks;
	
EndFunction

&AtServer
Procedure AddItemNameByItemType(ItemName, ObjectType)
	
	If Left(ObjectType, 2) <> "DM" Then
		ClassType = StrSplit(ObjectType, ".");
		If StrFind(ClassType[0], "Document") > 0 Then
			ClassType[0] = "Documents";
		ElsIf StrFind(ClassType[0], "Catalog") > 0 Then
			ClassType[0] = "Catalogs";
		ElsIf StrFind(ClassType[0], "BusinessProcess") > 0 Then
			ClassType[0] = "BusinessProcesses";
		ElsIf StrFind(ClassType[0], "Task") > 0 Then
			ClassType[0] = "Tasks";
		EndIf;
		NameOfTheItemType = " (" + Metadata[ClassType[0]][ClassType[1]].Synonym + ")";
	Else
		NameOfTheItemType = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(ObjectType);
	EndIf;
	
	ItemName = StrTemplate("%1 (%2)", ItemName, NameOfTheItemType);
	
EndProcedure

&AtServer
Procedure SetOverdueIssueFlag()
	If TaskDueDate < CurrentSessionDate() And TaskDueDate <> '00010101000000' Then
		OverdueTask = True;
	EndIf;
EndProcedure

&AtServer
Procedure SetTaskAppearance(Val Var_ConditionalAppearance)

	// setting up registration for overdue tasks
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Assignees.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Assignees.TaskDueDate");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = EndOfDay(CurrentSessionDate());
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Assignees.Executed");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("AssigneesTaskDueDate");
	
	ConditionalAppearanceItem = Var_ConditionalAppearance.Items.Add();
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Stages.DueDate_2");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Stages.DueDate_2");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Less;
	DataFilterItem.RightValue = CurrentSessionDate();
	DataFilterItem.Use = True;
		
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Stages.RunningBusinessProcessID");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem.Use = True;
	
	AppearanceAreaItem = ConditionalAppearanceItem.Fields.Items.Add();
	AppearanceAreaItem.Field = New DataCompositionField("StagesBusinessProcessTemplate");
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value =  Metadata.StyleItems.OverdueDataColor.Value;
	AppearanceColorItem.Use = True;

EndProcedure

&AtClient
Procedure SetAvailabilityOfApplicationTreeCommands()
	
	CurrentData = Items.ApplicationTree.CurrentData;
	
	If CurrentData = Undefined Then
		Items.OpenFileForViewing.Enabled = False;
		Items.Edit.Enabled = False;
		Items.EndEdit.Enabled = False;
		Items.CancelEdit.Enabled = False;
		Items.DeleteSubject.Enabled = False;
		Items.FormDeleteSubject.Enabled = False;
	Else
		If CurrentData.SubjectOfType = "DMFile" Then
			Items.OpenFileForViewing.Enabled = True;
			Items.Edit.Enabled = FileCaptureIsAvailable
				And (Not CurrentData.IsBeingEdited Or CurrentData.EditedByCurUser);
			Items.EndEdit.Enabled = FileCaptureIsAvailable
				And CurrentData.EditedByCurUser;
			Items.CancelEdit.Enabled = FileCaptureIsAvailable
				And CurrentData.EditedByCurUser;
		Else
			Items.OpenFileForViewing.Enabled = False;
			Items.Edit.Enabled = False;
			Items.EndEdit.Enabled = False;
			Items.CancelEdit.Enabled = False;
		EndIf;
		Items.DeleteSubject.Enabled = CurrentData.DeletionAvailable And Not CurrentData.IsBeingEdited;
		Items.FormDeleteSubject.Enabled = CurrentData.DeletionAvailable And Not CurrentData.IsBeingEdited;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAddressData(Receiver, ArtistXDTO)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "user") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(Receiver, ArtistXDTO.user,"Performer")
	ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "role") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(Receiver, ArtistXDTO.role,"Performer")
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "mainAddressingObject") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(Receiver, ArtistXDTO.mainAddressingObject, "MainAddressingObject");
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ArtistXDTO, "secondaryAddressingObject") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(Receiver, ArtistXDTO.secondaryAddressingObject, "AdditionalAddressingObject");
	EndIf;
	
	Performer = Performer
		+ ?(IsBlankString(MainAddressingObject), "", ", " + MainAddressingObject)
		+ ?(IsBlankString(AdditionalAddressingObject), "", ", " + AdditionalAddressingObject);
	
EndProcedure

&AtServer
Procedure FillInXDTOByObjectDetails(Proxy, Var_AttributeName, ObjectPropertyName, XDTODataObject)
	
	ObjectProperty1 = CreateObject(Proxy, ThisObject[Var_AttributeName+"Type"]);
	ObjectProperty1.name = ThisObject[Var_AttributeName];
	ObjectProperty1.ObjectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		ThisObject[Var_AttributeName+"ID"],
		ThisObject[Var_AttributeName+"Type"]);
	
	XDTODataObject[ObjectPropertyName] = ObjectProperty1;
	
EndProcedure

&AtServer
Function CreateObject(Proxy, Type)
	
	Return IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
EndFunction

&AtClient
Procedure CompleteNotifyCloseForm(ButtonNumber)
	
	CallbackDescription = New CallbackDescription("CompleteNotifyCloseFormCompletion",
		ThisObject,
		ButtonNumber);
	
	If ActualTaskExecutor = "userChoice"
			And PerformerType = "DMUser"
			And PerformerID <> CurrentUserID Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Performer", Performer);
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
Procedure CompleteNotifyCloseFormCompletion(SelectedPerformer, ButtonNumber) Export
	
	If SelectedPerformer = Undefined Then
		Return;
	EndIf;
	
	TaskResult = New Structure;
	TaskResult.Insert("ButtonNumber", ButtonNumber);
	TaskResult.Insert("SelectedPerformer", SelectedPerformer);
	TaskResult.Insert("SubjectLink", Undefined);
	
	If WriteObject(TaskResult) Then
		
		If ValueIsFilled(TaskResult.SubjectLink) Then
			NotifyChanged(TaskResult.SubjectLink);
		EndIf;
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("ID", Process_ID);
		NotificationParameters.Insert("Started", True);
		
		// Let's collect the items.
		Subjects = New Array;
		If MultiSubjectivityIsAvailable Then
			TreeItems = ApplicationTree.GetItems();
			For Each SubjectLine In TreeItems Do
				If SubjectLine.RoleOfSubject = "Основной" Then //@NON-NLS-1
					ItemDescription = New Structure;
					ItemDescription.Insert("ID", SubjectLine.SubjectOfID);
					ItemDescription.Insert("Type", SubjectLine.SubjectOfType);
					Subjects.Add(ItemDescription);
				EndIf;
			EndDo;
		Else
			// One item.
			ItemDescription = New Structure;
			ItemDescription.Insert("ID", SubjectOfID);
			ItemDescription.Insert("Type", SubjectOfType);
			Subjects.Add(ItemDescription);
		EndIf;
		NotificationParameters.Insert("Subjects", Subjects);
		
		Notify("Recording_1CDocumentManagementBusinessProcess", NotificationParameters, FormOwner);
		
		NotificationParameters = New Structure("name, ID, type", Description, ID, Type);
		Notify("Recording_1CDocumentManagementTask", NotificationParameters, FormOwner);
		
		Modified = False;
		Close();
		If AddWorkToDailyReportWhenCompletingTask Then
			FormParameters = New Structure;
			FormParameters.Insert("Source", Presentation);
			FormParameters.Insert("SourceID", ID);
			FormParameters.Insert("SourceType", Type);
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.InsertWork", FormParameters, ID);
		EndIf;
	EndIf;
	
EndProcedure

// Records a task, possibly by completing it.
//
// Parameters:
//   TaskResult - Undefined
//                             - Structure:
//     * ButtonNumber - Number - the number of the button performing the task.
//     * SelectedPerformer - String - CurrentUser, if it is the current user, or
//         taskPerformer, if it is the actual performer of the task.
//     * SubjectLink - AnyRef - an implicitly returned parameter, the subject of a task
//         that requires notification of a change.
//
&AtServer
Function WriteObject(TaskResult = Undefined)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOProcess = CreateObject(Proxy, Process_Type);
	XDTOProcess.name = Process_;
	XDTOProcess.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		Process_ID,
		Process_Type);
	
	Task = CreateObject(Proxy, Type);
	
	If MultiSubjectivityIsAvailable Then
		FillTaskWithItemsFromApplicationTree(Proxy, ApplicationTree.GetItems(), Task);
	EndIf;
	
	Task.executed = ?(TaskResult <> Undefined, True, Executed);
	Task.parentBusinessProcess = XDTOProcess;
	
	FillInObjectPropertiesByIssue(Task, Proxy);
	FillInXDTOByObjectDetails(Proxy, "Importance", "importance", Task);
	
	// Fill in the result and the task executor when executing.
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
	
	If TaskResult <> Undefined Then
		FillInObjectPropertiesByTaskTypeWhenExecuting(Proxy, Task, TaskResult.ButtonNumber);
		If TaskResult.SelectedPerformer = "currentUser" Then
			DataExecutor = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				CurrentUserID,
				CurrentUserType,
				CurrentUser);
		EndIf;
	EndIf;
	
	Task.performer = IntegrationWith1CDocumentManagement.TaskParticipant(
		Proxy,
		DataExecutor,
		DataIsMainObject,
		DataIsAdditionalObject);
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.GenerateAdditionalProperties(
		Proxy,
		Task,
		ThisObject);
	
	RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, Task);
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, RecordingResult, "DMError") Then
		
		Return False;
		
	Else // Changing the approval status requires special processing with the notification of the subject.
		
		If Type = "DMBusinessProcessApprovalTaskApproval"
				And TaskResult <> Undefined Then
			
			NewState = Undefined;
			If TaskResult.ButtonNumber = 3 Then
				NewState = Enums.ApprovalStatesIn1CDocumentManagement.NotApproved;
			Else
				ProcessData = IntegrationWith1CDocumentManagementCore.GetObject(
					Proxy,
					Process_Type,
					Process_ID,
					"completed");
				If ProcessData.completed = True Then
					NewState = Enums.ApprovalStatesIn1CDocumentManagement.Approved;
				EndIf;
			EndIf;
			If NewState <> Undefined Then
				For Each SubjectLine In ApplicationTree.GetItems() Do
					If (Not MultiSubjectivityIsAvailable Or SubjectLine.RoleOfSubject = "Основной")
							And IntegrationWith1CDocumentManagementClientServer.IsDocument(SubjectLine.SubjectOfType) Then //@NON-NLS-1
						IntegrationWith1CDocumentManagementCoreServerCall.WhenApprovalStateChanges(
							SubjectLine.SubjectOfID,
							SubjectLine.SubjectOfType,
							NewState,
							False,
							TaskResult.SubjectLink);
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
		Modified = False;
		Return True;
		
	EndIf;
	
EndFunction

// Fills the XDTO object of the business process task with items from the application tree of the form.
//
&AtServer
Procedure FillTaskWithItemsFromApplicationTree(Proxy, TreeRows, Task)
	
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Task, "DMBusinessProcessIssuesSolutionTaskQuestion")
			Or IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Task, "DMBusinessProcessIssuesSolutionTaskAnswer")Then
		
		Task.files.Clear();
		
		For Each SubjectLine In TreeRows Do
			
			file = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.SubjectOfType);
			file.name = SubjectLine.SubjectOf;
			file.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.SubjectOfID,
				SubjectLine.SubjectOfType);
			
			Task.files.Add(file);
			
		EndDo;
		
	Else
		
		targetCollection = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMBusinessProcessTaskTargetCollection");
		ItemDescription = targetCollection.items; // XDTOList
		
		For Each SubjectLine In TreeRows Do
			
			target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTaskTarget");
			
			target.name = SubjectLine.ItemName;
			
			target.role = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessTargetRole");
			target.role.name = SubjectLine.RoleOfSubject;
			target.role.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.RoleOfSubject,
				"DMBusinessProcessTargetRole");
			
			target.target = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.SubjectOfType);
			target.target.name = SubjectLine.SubjectOf;
			target.target.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				SubjectLine.SubjectOfID,
				SubjectLine.SubjectOfType);
			
			target.allowDeletion = SubjectLine.DeletionAvailable;
			
			ItemDescription.Add(target);
			
		EndDo;
		
		Task.targets = targetCollection;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInObjectPropertiesByIssue(Task, Proxy)
	
	Task.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
	Task.name = Description;
	Task.number = Number;
	Task.description = LongDesc;
	Task.beginDate = Date;
	Task.dueDate = TaskDueDate;
	Task.endDate = CompletionDate;
	Task.executionComment = ExecutionResult;
	Task.businessProcessStep = RoutePoint;
	
	TypeName = Task.Type().Name;
	
	If TypeName = "DMBusinessProcessPerfomanceTaskCheckup" Then
		CheckResults = Task.checkResults; // XDTOList
		
		Task.iterationNumber = IterationNumber;
		For Each String In Assignees Do
			XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMBusinessProcessPerfomanceTaskCheckupResult");
			XDTORow.returned = String.SentForRevision;
			XDTORow.checkComment = String.ReviewerSComment;
			SourceTask = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				String.TaskType,
				String.TaskID);
			TaskReceiver = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMBusinessProcessTask");
			IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(
				Proxy,
				TaskReceiver,
				SourceTask);
			XDTORow.executorTask = TaskReceiver;
			CheckResults.Add(XDTORow);
		EndDo
		
	ElsIf TypeName = "DMBusinessProcessConsiderationTaskAcquaint" Then
		Task.resolution = ExecutionResult;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInObjectPropertiesByTaskTypeWhenExecuting(Proxy, Task, ButtonNumber)
	
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
		If ButtonNumber = 1 Then
			Task.invitationAccepted = True;
		ElsIf ButtonNumber = 2 Then
			Task.invitationReturned = True;
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
Procedure CompleteTaskDescription(ProcessObject_, XDTODataObject)
	
	If Items.Find("FullTaskDescription") <> Undefined Then
		
		// The states of the process are "Interrupted", "Stopped".
		If IntegrationWith1CDocumentManagementCore.PropertySet(ProcessObject_, "state") Then
			
			If ProcessObject_.state.name = "Остановлен" Then //@NON-NLS-1
				If Not IsBlankString(FullTaskDescription) Then
					FullTaskDescription = FullTaskDescription + Chars.LF;
				EndIf;
				FullTaskDescription = FullTaskDescription + NStr("vi = 'Nhiệm vụ đã tạm dừng';
																|ru = 'Задача остановлена';
																|en = 'The task is stopped'; fa = 'وظیفه متوقف شده است';
																|it = 'Obiettivo interrotto';
																|pl = 'Zadanie zatrzymano';
																|tr = 'Görev durduruldu'") + Chars.LF;
			ElsIf ProcessObject_.state.name = "Прерван" Then //@NON-NLS-1
				If Not IsBlankString(FullTaskDescription) Then
					FullTaskDescription = FullTaskDescription + Chars.LF;
				EndIf;
				FullTaskDescription = FullTaskDescription + NStr("vi = 'Nhiệm vụ đã bị ngắt';
																|ru = 'Задача прервана';
																|en = 'Task is canceled'; fa = 'Task is canceled';
																|it = 'Compito interrotto';
																|pl = 'Zadanie zostało przerwane';
																|tr = 'Görev kesildi'") + Chars.LF;
			EndIf;
			
		EndIf;
		
		// Description of the task.
		If Not IsBlankString(XDTODataObject.description) Then
			If Not IsBlankString(FullTaskDescription) Then
				FullTaskDescription = FullTaskDescription + Chars.LF;
			EndIf;
			FullTaskDescription = FullTaskDescription + XDTODataObject.description + Chars.LF;
		EndIf;
		
		// Importance.
		If Not IsBlankString(FullTaskDescription) Then
			FullTaskDescription = FullTaskDescription + Chars.LF;
		EndIf;
		FullTaskDescription = FullTaskDescription
			+ StrTemplate(NStr("vi = 'Mức độ quan trọng: %1';
								|ru = 'Важность: %1';
								|en = 'Importance: %1'; fa = 'Importance: %1';
								|it = 'Importanza: %1';
								|pl = 'Ważność: %1';
								|tr = 'Önemlilik: %1'"), XDTODataObject.importance.objectID.ID)
			+ Chars.LF;
		
		// Whom.
		If Not IsBlankString(FullTaskDescription) Then
			FullTaskDescription = FullTaskDescription + Chars.LF;
		EndIf;
		
		ArtistPresentation = "";
		
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject.performer, "user") Then
			
			// Addressed to the user.
			ArtistPresentation = XDTODataObject.performer.user.name;
			
		ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject.performer, "role") Then
			
			// Addressed to the role.
			ArtistPresentation = XDTODataObject.performer.role.name;
			
			If IntegrationWith1CDocumentManagementCore.PropertySet(
					XDTODataObject.performer, "mainAddressingObject") Then
				ArtistPresentation = ArtistPresentation + ", "
					+ XDTODataObject.performer.mainAddressingObject.name;
			EndIf;
			If IntegrationWith1CDocumentManagementCore.PropertySet(
					XDTODataObject.performer, "secondaryAddressingObject") Then
				ArtistPresentation = ArtistPresentation + ", "
					+ XDTODataObject.performer.secondaryAddressingObject.name;
			EndIf;
			
		EndIf;
		
		FullTaskDescription = FullTaskDescription + StrTemplate(
			NStr("vi = 'Người nhận: %1';
				|ru = 'Кому: %1';
				|en = 'To: %1'; fa = 'To: %1';
				|it = 'A chi: %1';
				|pl = 'Do kogo: %1';
				|tr = 'Kime: %1'"),
			ArtistPresentation);
		
		// Term.
		If ValueIsFilled(XDTODataObject.dueDate) Then
			If Not IsBlankString(FullTaskDescription) Then
				FullTaskDescription = FullTaskDescription + Chars.LF;
			EndIf;
			FullTaskDescription = FullTaskDescription
				+ StrTemplate(NStr("vi = 'Thời hạn: %1';
									|ru = 'Срок: %1';
									|en = 'Due date: %1'; fa = 'Due date: %1';
									|it = 'Termine: %1';
									|pl = 'Termin: %1';
									|tr = 'Tarih: %1'"),
					Format(XDTODataObject.dueDate, NStr("ru = 'ДФ=''dd.MM.yyyy HH:mm''';
														|vi = 'DF=''MM/dd/yyyy hh:mm tt''';
														|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
														|it = 'DF=''MM/dd/yyyy hh:mm tt''';
														|pl = 'DF=''MM/dd/yyyy hh:mm tt''';
														|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
		EndIf;
		
		// Author.
		If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "author") Then
			If Not IsBlankString(FullTaskDescription) Then
				FullTaskDescription = FullTaskDescription + Chars.LF;
			EndIf;
			FullTaskDescription = FullTaskDescription
				+ StrTemplate(NStr("vi = 'Tác giả: %1';
									|ru = 'Автор: %1';
									|en = 'Author: %1'; fa = 'Author: %1';
									|it = 'Autore: %1';
									|pl = 'Autor: %1';
									|tr = 'Oluşturan: %1'"), XDTODataObject.author.name);
		EndIf;
		
		// Execution history.
		If ProcessObject_.Properties().Get("executionComment") <> Undefined
				And Not IsBlankString(ProcessObject_.executionComment) Then
			If Not IsBlankString(FullTaskDescription) Then
				FullTaskDescription = FullTaskDescription + Chars.LF;
			EndIf;
			FullTaskDescription = FullTaskDescription
				+ Chars.LF + NStr("vi = 'Lịch sử thực hiện:';
									|ru = 'История выполнения:';
									|en = 'Task history:'; fa = 'Task history:';
									|it = 'Cronologia dell''esecuzione:';
									|pl = 'Historia wykonania:';
									|tr = 'Yürütme tarihçesi:'")
				+ Chars.LF + ProcessObject_.executionComment;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingAndRecordingItem(SubjectOfID, SubjectOfType)
	
	CurrentRowID = Undefined;
	CurSubjectID = Undefined;
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData <> Undefined Then
		CurSubjectID = Items.ApplicationTree.CurrentData.SubjectOfID
	EndIf;
	
	ProcessingAndRecordingItemServer(SubjectOfID, SubjectOfType);
	
	// expand the tree and set the focus to the Cur row.
	TreeItems = ApplicationTree.GetItems();
	For Each TreeItem In TreeItems Do
		RowID = TreeItem.GetID();
		Items.ApplicationTree.Expand(RowID);
		If TreeItem.SubjectOfID = CurSubjectID Then
			CurrentRowID = RowID;
		EndIf;
		If CurrentRowID = Undefined Then
			For Each TreeChildItem In TreeItem.GetItems() Do
				RowID = TreeChildItem.GetID();
				If TreeChildItem.SubjectOfID = CurSubjectID Then
					CurrentRowID = RowID;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	If CurrentRowID <> Undefined Then
		Items.ApplicationTree.CurrentRow = CurrentRowID;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FindItemString(TreeRows, SubjectOfID, SubjectOfType)
	
	FoundRow = Undefined;
	
	For Each SubjectLine In TreeRows Do
		
		If SubjectOfID = SubjectLine.SubjectOfID And SubjectOfType = SubjectLine.SubjectOfType Then
			FoundRow = SubjectLine;
		Else
			If TypeOf(SubjectLine) = Type("FormDataTreeItem") Then
				FileStrings = SubjectLine.GetItems();
			Else
				FileStrings = SubjectLine.Rows;
			EndIf;
			For Each FileString In FileStrings Do
				If SubjectOfID = FileString.SubjectOfID And SubjectOfType = FileString.SubjectOfType Then
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

// Updates the application tree when the subject changes in other forms.
//
&AtServer
Procedure ProcessingAndRecordingItemServer(SubjectOfID, SubjectOfType)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ColumnsArray1 = New Array;
	If IntegrationWith1CDocumentManagementClientServer.IsDocument(SubjectOfType) Then
		ColumnsArray1.Add("files");
		ColumnsArray1.Add("externalObject");
	ElsIf SubjectOfType = "DMFile" Then
		ColumnsArray1.Add("extension");
		ColumnsArray1.Add("modificationDateUniversal");
		ColumnsArray1.Add("size");
	EndIf;
	
	If MultiSubjectivityIsAvailable Then // Find the line you need and update it.
		
		Tree = FormAttributeToValue("ApplicationTree");
		
		FoundRow = FindItemString(Tree.Rows, SubjectOfID, SubjectOfType);
		If FoundRow <> Undefined Then
			SubjectXDTO = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				SubjectOfType,
				SubjectOfID,
				ColumnsArray1);
			FillItemLineWithItsProperties(FoundRow, SubjectXDTO);
		EndIf;
		
		ValueToFormAttribute(Tree, "ApplicationTree");
		
	Else // There is no multi-object, we will re-fill the entire tree.
		
		If SubjectOfID <> ID Then
			Return;
		EndIf;
		
		SubjectXDTO = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			SubjectOfType,
			SubjectOfID,
			ColumnsArray1);
		
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, SubjectXDTO, "SubjectOf");
		FillInTheApplicationTreeBySubject(SubjectXDTO);
		
	EndIf;
	
EndProcedure

&AtServer
Function AcceptTaskForExecutionOnServer()
	
	TasksToBeExecuted = New Array;
	TasksToBeExecuted.Add(ID);
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Return IntegrationWith1CDocumentManagement.AcceptTaskForExecution(Proxy, TasksToBeExecuted);
	
EndFunction

&AtServer
Function CancelAcceptanceForExecutionOnServer()
	
	TasksToBeExecuted = New Array;
	TasksToBeExecuted.Add(ID);
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Return IntegrationWith1CDocumentManagement.CancelAcceptTasksForExecution(Proxy, TasksToBeExecuted);
	
EndFunction

&AtClient
Procedure Attachable_ExecuteProgrammaticallyAddedCommand(Command)
	
	// Let's call the handler of the command that was added programmatically when creating the form on the server.
	IntegrationWith1CDocumentManagementCoreClientOverridable.ExecuteProgrammaticallyAddedCommand(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure AddSubject(Command)
	
	If Not Allowed1Update Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("AddSubjectCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.AddSubject(ThisObject, "Auxiliary", CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddSubjectCompletion(Added_Items, HandlerParameters) Export
	
	If Added_Items = Undefined Or Added_Items.Count() = 0 Then
		Return;
	EndIf;
	
	AddSubjectCompletionAtServer(Added_Items);
	Modified = True;
	ProcessFormByPresenceOfItems();
	
	// Expand the tree and set the focus to the last line with the added item.
	TreeItems = ApplicationTree.GetItems();
	For Each TreeItem In TreeItems Do
		LastID_ = TreeItem.GetID();
		Items.ApplicationTree.Expand(LastID_);
	EndDo;
	Items.ApplicationTree.CurrentRow = LastID_;
	
	If Added_Items[0].SubjectOfType = "DMFile" Then
		WriteExecute(Undefined);
		FillOutIssueForm(New Structure("ID, type", ID, Type));
	EndIf;
	
EndProcedure

&AtServer
Procedure AddSubjectCompletionAtServer(Added_Items)
	
	Tree = FormAttributeToValue("ApplicationTree");
	
	For Each ItemDescription In Added_Items Do
		SubjectLine = Tree.Rows.Add();
		FillPropertyValues(SubjectLine, ItemDescription);
		SubjectLine.DeletionAvailable = True;
		If ValueIsFilled(SubjectLine.Ref) Then
			SubjectLine.Presentation = String(SubjectLine.Ref);
		EndIf;
		SetItemPicture(SubjectLine);
		AugmentApplicationTreeWithObjectFiles(SubjectLine);
	EndDo;
	
	ValueToFormAttribute(Tree, "ApplicationTree");
	
EndProcedure

&AtClient
Procedure DeleteSubject(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData <> Undefined Then
		ApplicationTree.GetItems().Delete(CurrentData);
	EndIf;
	
	ProcessFormByPresenceOfItems();
	
	WriteExecute(Undefined);
	FillOutIssueForm(New Structure("ID, type", ID, Type));
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.SubjectOfType <> "DMFile" Then
		Return;
	EndIf;
	If CurrentData.IsBeingEdited And Not CurrentData.EditedByCurUser Then
		ShowMessageBox(, NStr("vi = 'Tệp này hiện đang do người sử dụng khác chỉnh sửa.';
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
		"EditingCommandsCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.OpenFile(
		CurrentData.SubjectOfID,
		CurrentData.SubjectOf,
		CurrentData.Extension,
		UUID,
		False,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure EndEdit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined
			Or CurrentData.SubjectOfType <> "DMFile"
			Or Not CurrentData.EditedByCurUser Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Command", "EndEdit");
	CallbackDescription = New CallbackDescription(
		"EditingCommandsCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.EndFileEditing(
		CurrentData.SubjectOfID,
		CurrentData.SubjectOf,
		CurrentData.Extension,
		UUID,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined
			Or CurrentData.SubjectOfType <> "DMFile"
			Or Not CurrentData.EditedByCurUser Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Command", "CancelEdit");
	CallbackDescription = New CallbackDescription(
		"EditingCommandsCompletion", ThisObject, NotificationParameters);
	
	IntegrationWith1CDocumentManagementCoreClient.UndoFileEditing(
		CurrentData.SubjectOfID,
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
	SetAvailabilityOfApplicationTreeCommands();
	
EndProcedure

// Controls the visibility of form elements depending on the availability of items.
&AtClient
Procedure ProcessFormByPresenceOfItems()
	
	ThereAreItems = (ApplicationTree.GetItems().Count() <> 0);
	If ThereAreItems Then
		If Items.ApplicationGroup.CurrentPage = Items.PageNoItems Then
			Items.ApplicationGroup.CurrentPage = Items.PageHasItems;
		EndIf;
	Else
		If Items.ApplicationGroup.CurrentPage = Items.PageHasItems Then
			Items.ApplicationGroup.CurrentPage = Items.PageNoItems;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateSubtask(Command)
	
	FormParameters = New Structure("MainTask", New Structure);
	
	FormParameters.MainTask.Insert("name", Description);
	FormParameters.MainTask.Insert("id", ID);
	FormParameters.MainTask.Insert("type", Type);
	
	SubjectOfSubtask = Undefined;
	Applications = ApplicationTree.GetItems();

	For Each Item In Applications Do
		If Item.RoleOfSubject = "Основной" Then //@NON-NLS-1
			SubjectOfSubtask = New Structure;
			SubjectOfSubtask.Insert("name", Item.SubjectOf);
			SubjectOfSubtask.Insert("id", Item.SubjectOfID);
			SubjectOfSubtask.Insert("type", Item.SubjectOfType);
			Break;
		EndIf;
	EndDo;

	If SubjectOfSubtask = Undefined And Applications.Count() > 0 Then
		SubjectOfSubtask = New Structure;
		SubjectOfSubtask.Insert("name", Applications[0].SubjectOf);
		SubjectOfSubtask.Insert("id", Applications[0].SubjectOfID);
		SubjectOfSubtask.Insert("type", Applications[0].SubjectOfType);
	EndIf;

	FormParameters.Insert("SubjectOf", SubjectOfSubtask);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CreatingBusinessProcess", FormParameters);
	
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
	ElsIf Item.Name = "sh_ShamsiInput_F_CompletionDate" Then
		CompletionDateOnChange(Items.CompletionDate);
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
