#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MultiSubjectivityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.3.1");
	Items.MultiSubjectPages.CurrentPage = ?(MultiSubjectivityIsAvailable,
		Items.PageAvailableMultiSubjects,
		Items.PageUnavailableMultiSubject);
	
	ProcessTypeXDTO = "DMBusinessProcessApproval";
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(ProcessTypeXDTO, Parameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
	If Parameters.Property("Template") Then
		TemplateID = Parameters.Template.ID;
		TemplateType = Parameters.Template.type;
	EndIf;
	
	If Parameters.Property("taskID") Then
		Title = NStr("vi = 'Thống nhất lại';
					|ru = 'Повтор согласования';
					|en = 'Repeat approval  '; fa = 'Repeat approval  ';
					|it = 'Ripetizione omologazione';
					|pl = 'Powtórzenie uzgodnienia';
					|tr = 'Anlaşma tekrarı'");
		CommandBarLocation = FormCommandBarLabelLocation.None;
		ReadOnly = False;
		Items.RepeatMatchingGroup.Visible = True;
		Items.Comment.Visible = True;
		Items.OK.DefaultButton = True;
		Items.InfoGroup.Visible = False;
		Items.MainTaskPresentation.Visible = False;
		Items.DescriptionGroup.Visible = False;
		Items.MultiSubjectPages.Visible = False;
		Items.TermOfExecutionDays.ReadOnly = False;
		Items.TermOfExecutionHours.ReadOnly = False;
		Items.AuthorPresentation.Visible = False;
	EndIf;
	
	Items.ApprovalOptionPresentation.ReadOnly = ReadOnly;
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfBusinessProcessForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	Items.ApprovalOptionPresentation.ChoiceList.Clear();
	Items.ApprovalOptionPresentation.ChoiceList.Add(
		"Параллельно",
		NStr("en = 'To all at once'; fa = 'به همه به‌طور همزمان'")); //@NON-NLS-1
	Items.ApprovalOptionPresentation.ChoiceList.Add(
		"Последовательно",
		NStr("en = 'In sequence'; fa = 'به ترتیب'")); //@NON-NLS-1
	Items.ApprovalOptionPresentation.ChoiceList.Add(
		"Смешанно",
		NStr("en = 'Mixed'; fa = 'ترکیبی'")); //@NON-NLS-1
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillInStep(Assignees);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(
			Notification,
			Cancel,
			Exit,,
			WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Changed" And Parameter = Items.SubjectOfPresentation Then
		SubjectOf = Source.Presentation;
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion" And Source = ThisObject Then
		If Parameter.Attribute = "ApprovalProcedure" Then
			FillInStep(Assignees);
		EndIf;
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		If Parameter.ID = ID Then
			RereadProcess();
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainTaskPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(MainTask) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(MainTaskType, MainTaskID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(SubjectOf) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfType, SubjectOfID, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApprovalOptionPresentationOnChange(Item)
	
	If ApprovalOptionID <> "Смешанно" Then //@NON-NLS-1
		Items.AssigneesStep.Visible = False;
		Items.AssigneesApprovalProcedure.Visible = False;
	Else
		Items.AssigneesStep.Visible = True;
		Items.AssigneesApprovalProcedure.Visible = True;
		FillInStep(Assignees);
	EndIf;
	
	If ApprovalOptionID <> "Параллельно" Then //@NON-NLS-1
		Items.PerformersMovingGroup.Visible = True;
	Else
		Items.PerformersMovingGroup.Visible = False;
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ParticipantOfBusinessProcessAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser;DMBusinessProcessExecutorRole",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessProcessParticipantEndOfTextInput(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser;DMBusinessProcessExecutorRole",
			ChoiceData,
			Text,
			StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInList(
				Item.Parent.Parent,
				ChoiceData[0].Value,
				StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessProcessParticipantSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInList(
		Item.Parent.Parent, ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure ImportanceStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMBusinessProcessImportance", "Importance", ThisObject);
	
EndProcedure

&AtClient
Procedure ImportanceAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMBusinessProcessImportance",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportanceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMBusinessProcessImportance", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Importance", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportanceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Importance", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectUserFromUnitTree("Author", ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMUser", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Author", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Author", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAssignees

&AtClient
Procedure AssigneesPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("AssigneesPerformerStartChoiceCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectBusinessProcessPerformer",,
		ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AssigneesPerformerStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.Assignees.CurrentData;
	
	Result.Property("Performer", CurrentData.Performer);
	Result.Property("PerformerID", CurrentData.PerformerID);
	Result.Property("PerformerType", CurrentData.PerformerType);
	
	Result.Property("MainAddressingObject", CurrentData.MainAddressingObject);
	Result.Property("MainAddressingObjectID", CurrentData.MainAddressingObjectID);
	Result.Property("MainAddressingObjectType", CurrentData.MainAddressingObjectType);
	
	Result.Property("AdditionalAddressingObject", CurrentData.AdditionalAddressingObject);
	Result.Property("AdditionalAddressingObjectID", CurrentData.AdditionalAddressingObjectID);
	Result.Property("AdditionalAddressingObjectType", CurrentData.AdditionalAddressingObjectType);
	
EndProcedure

&AtClient
Procedure AssigneesApprovalProcedureStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMApprovalOrder", "ApprovalProcedure", ThisObject,, True, Item);
	
EndProcedure

&AtClient
Procedure AssigneesApprovalProcedureAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMApprovalOrder",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesApprovalProcedureTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMApprovalOrder", ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"ApprovalProcedure", ChoiceData[0].Value, StandardProcessing, ThisObject, True, Item);
			FillInStep(Assignees);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesApprovalProcedureChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"ApprovalProcedure", ValueSelected, StandardProcessing, ThisObject, True, Item);
	FillInStep(Assignees);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordBusinessProcess(Command)
	
	RecordingResult = WriteObject();
	
	If RecordingResult Then
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, False);
		Title = Presentation;
		Status(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã lưu lại quy trình nghiệp vụ ""%1"".';
				|ru = 'Бизнес-процесс ""%1"" сохранен.';
				|en = 'Business process ""%1"" is saved.'; fa = 'Business process ""%1"" is saved.';
				|it = 'Processo aziendale ""%1"" salvato.';
				|pl = 'Proces biznesowy ""%1"" jest zapisany.';
				|tr = '""%1"" iş süreci kaydedildi.'"), Presentation));
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAndClose(Command)
	
	RunResult = PrepareForTransferAndStartBusinessProcess();
	
	If RunResult Then
		
		// Universal notification.
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, True);
		// User notification.
		StateText = NStr("vi = 'Đã khởi chạy thành công quy trình nghiệp vụ ""%Description%"".';
						|ru = 'Бизнес-процесс ""%Description%"" успешно запущен.';
						|en = 'The ""%Description%"" business process is started successfully.'; fa = 'The ""%Description%"" business process is started successfully.';
						|it = 'Processo aziendale ""%Description%"" avviato con successo.';
						|pl = 'Proces biznesowy ""%Description%"" jest pomyślnie uruchomiony.';
						|tr = '""%Description%"" iş süreci başarıyla başlatıldı.'");
		StateText = StrReplace(StateText,"%Description%", Presentation);
		Status(StateText);
		
		Modified = False;
		If IsOpen() Then
			Close(True);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillFromTemplate(Command)
	
	Notification = New CallbackDescription("FillFromTemplateCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.StartSelectingBusinessProcessTemplate(Notification, ThisObject);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(New Structure("Success, Comment", False, Comment));
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	If Not ValueIsFilled(Comment) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền ghi chú';
				|ru = 'Не заполнен комментарий';
				|en = 'Comment is not filled in'; fa = 'Comment is not filled in';
				|it = 'Commento non compilato';
				|pl = 'Nie wypełniono uwagi';
				|tr = 'Yorum doldurulmadı'"),,
			"Comment");
		Return;
	EndIf;
	
	If PrepareForTransferAndRecordBusinessProcess() Then
		Modified = False;
		Close(New Structure("Success, Comment", True, Comment));
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	IndexOfCurCollectionItem = Assignees.IndexOf(
		Items.Assignees.CurrentData);
	CollectionItemsCount = Assignees.Count();
	If IndexOfCurCollectionItem < CollectionItemsCount - 1 Then
		Assignees.Move(IndexOfCurCollectionItem, 1);
	EndIf;
	FillInStep(Assignees);
	Modified = True;
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	IndexOfCurCollectionItem = Assignees.IndexOf(
		Items.Assignees.CurrentData);
	If IndexOfCurCollectionItem > 0 Then
		Assignees.Move(IndexOfCurCollectionItem, -1);
	EndIf;
	Modified = True;
	FillInStep(Assignees);
	
EndProcedure

&AtClient
Procedure StopProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.StopProcess(ThisObject);
	
EndProcedure

&AtClient
Procedure InterruptProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.InterruptProcess(ThisObject);
	
EndProcedure

&AtClient
Procedure ContinueProcess(Command)
	
	IntegrationWith1CDocumentManagementClient.ContinueProcess(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillFromTemplateCompletion(TemplateSelectionResult, NotificationParameters) Export
	
	If TypeOf(TemplateSelectionResult) = Type("Structure") Then
		FillInCardUsingTemplate(TemplateSelectionResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCardUsingTemplate(TemplateData)
	
	FillingResult = IntegrationWith1CDocumentManagement.FillInBusinessProcessUsingTemplate(ThisObject, TemplateData);
	FillOutFormFromXDTOObject(FillingResult.object);

EndProcedure

&AtServer
Procedure FillOutFormFromXDTOObject(XDTODataObject)
	
	If XDTODataObject.IsSet("objectID") Then
		ID = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInStandardHeaderOfBusinessProcess(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.SetDeadlineForProcessingResults(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.SetVisibilityOfProcessStateChangeCommands(ThisObject, XDTODataObject);
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject, XDTODataObject.approvalType, "ApprovalOption");
	
	Assignees.Clear();
	For Each Performer In XDTODataObject.Performers Do
		NewRow = Assignees.Add();
		DataProcessors.IntegrationWith1CDocumentManagement.FillInInformationInForm(NewRow, Performer);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, Performer.approvalOrder, "ApprovalProcedure")
	EndDo;
	
	If ApprovalOptionID <> "Смешанно" Then //@NON-NLS-1
		Items.AssigneesStep.Visible = False;
		Items.AssigneesApprovalProcedure.Visible = False;
	Else
		Items.AssigneesStep.Visible = True;
		Items.AssigneesApprovalProcedure.Visible = True;
	EndIf;
	
	If ApprovalOptionID <> "Параллельно" Then //@NON-NLS-1
		Items.PerformersMovingGroup.Visible = True;
	Else
		Items.PerformersMovingGroup.Visible = False;
	EndIf;
	
	TermOfExecutionDays = XDTODataObject.durationDays;
	TermOfExecutionHours = XDTODataObject.durationHours;
	
	// It is possible that changing the process is prohibited by its template.
	ProhibitedUpdate = False;
	If XDTODataObject.Properties().Get("blockedByTemplate") <> Undefined Then
		ProhibitedUpdate = XDTODataObject.blockedByTemplate;
	EndIf;
	Items.TermOfExecutionDays.ReadOnly = Items.TermOfExecutionDays.ReadOnly
		Or (ValueIsFilled(TermOfExecutionDays) And ProhibitedUpdate);
	Items.TermOfExecutionHours.ReadOnly = Items.TermOfExecutionHours.ReadOnly
		Or (ValueIsFilled(TermOfExecutionHours) And ProhibitedUpdate);
	If Assignees.Count() > 0 And ProhibitedUpdate Then
		Items.Assignees.ReadOnly = True;
		Items.PerformersMoveUp.Enabled = False;
		Items.PerformersMoveDown.Enabled = False;
		Items.ApprovalOptionPresentation.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Function PrepareForTransferAndRecordBusinessProcess()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = PrepareBusinessProcess(Proxy);
	If ValueIsFilled(ID) Then
		RecordingResult = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
	Else
		CreationResult = IntegrationWith1CDocumentManagementCore.CreateNewObject(Proxy, XDTODataObject);
	EndIf;
	
	Result = ?(CreationResult = Undefined, RecordingResult, CreationResult);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	If RecordingResult <> Undefined Then // The write request returns a list.
		XDTODataObject = Result.objects[0];
		SetBusinessProcessLink(XDTODataObject);
		DataProcessors.IntegrationWith1CDocumentManagement.FillInItemsInForm(ThisObject, XDTODataObject);
	Else // The creation request returns the object itself.
		XDTODataObject = Result.object;
		SetBusinessProcessLink(XDTODataObject);
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function PrepareForTransferAndStartBusinessProcess()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = PrepareBusinessProcess(Proxy);
	
	RunResult = IntegrationWith1CDocumentManagement.StartBusinessProcess(Proxy, XDTODataObject);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, RunResult);
	
	SetBusinessProcessLink(RunResult.businessProcess);
	
	Return True;
	
EndFunction

&AtServer
Function PrepareBusinessProcess(Proxy)
	
	XDTODataObject = DataProcessors.IntegrationWith1CDocumentManagement.PrepareBusinessProcessHeader(
		Proxy,
		"DMBusinessProcessApproval",
		ThisObject,
		"DueDate");
	DataProcessors.IntegrationWith1CDocumentManagement.PassDeadlineForProcessingResult(Proxy, ThisObject, XDTODataObject);
	ProcessExecutors = XDTODataObject.performers; // XDTOList
	
	// Specifics of the Agreement
	XDTODataObject.durationDays = TermOfExecutionDays;
	XDTODataObject.durationHours = TermOfExecutionHours;
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		ThisObject,
		"ApprovalOption",
		XDTODataObject.approvalType,
		"DMApprovalType");
	
	For Each String In Assignees Do
		
		DataExecutor = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			String.PerformerID,
			String.PerformerType,
			String.Performer);
		DataIsMainObject = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			String.MainAddressingObjectID,
			String.MainAddressingObjectType,
			String.MainAddressingObject);
		DataIsAdditionalObject = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			String.AdditionalAddressingObjectID,
			String.AdditionalAddressingObjectType,
			String.AdditionalAddressingObject);
		
		Performer = IntegrationWith1CDocumentManagement.ParticipantInApprovalProcess(
			Proxy,
			DataExecutor,
			DataIsMainObject,
			DataIsAdditionalObject);
		
		ProcessExecutors.Add(Performer);
		
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			String,
			"ApprovalProcedure",
			Performer.approvalOrder,
			"DMApprovalOrder",
			True);
		
	EndDo;
	
	Return XDTODataObject;
	
EndFunction

&AtClient
Function WriteObject() Export
	
	PrepareForTransferAndRecordBusinessProcess();
	IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, False);
	Modified = False;
	
	Return True;
	
EndFunction

&AtClient
Procedure FillInStep(Table)
	
	For Each String In Table Do
		String.Step = 0;
	EndDo;
	
	RowsCount = Table.Count();
	For Indus = 0 To RowsCount - 1 Do
		
		String = Table[Indus];
		If Not ValueIsFilled(String.ApprovalProcedureID) Then
			Break;
		EndIf;
		
		If Indus = 0 Then
			String.Step = 1;
			Continue;
		EndIf;
		
		PreviousString = Table[Indus-1];
		If String.ApprovalProcedureID = "ВместеСПредыдущим" Then //@NON-NLS-1
			String.Step = PreviousString.Step;
		ElsIf String.ApprovalProcedureID = "ПослеПредыдущего" Then //@NON-NLS-1
			String.Step = PreviousString.Step + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetBusinessProcessLink(XDTODataObject)
	
	ID = XDTODataObject.objectID.ID;
	If XDTODataObject.objectID.Properties().Get("presentation") <> Undefined Then
		Presentation = XDTODataObject.objectID.presentation;
	Else
		Presentation = XDTODataObject.name;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteObject();
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteProgrammaticallyAddedCommand(Command)
	
	// Let's call the handler of the command that was added programmatically when creating the form on the server.
	IntegrationWith1CDocumentManagementCoreClientOverridable.ExecuteProgrammaticallyAddedCommand(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure AddSubjectMain(Command)
	
	CallbackDescription = New CallbackDescription("AddSubjectCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.AddSubject(
		ThisObject, "Main", CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddSubjectSupplementary(Command)
	
	CallbackDescription = New CallbackDescription("AddSubjectCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.AddSubject(
		ThisObject, "Auxiliary", CallbackDescription);
	
EndProcedure

&AtClient
Procedure ChangeSubject(Command)
	
	OpenArticle();
	
EndProcedure

&AtClient
Procedure DeleteSubject(Command)
	
	CurrentData = Items.Subjects.CurrentData;
	If CurrentData <> Undefined Then
		Subjects.Delete(CurrentData);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SubjectsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenArticle();
	
EndProcedure

&AtClient
Procedure AddSubjectCompletion(Added_Items, HandlerParameters) Export
	
	If Added_Items = Undefined Or Added_Items.Count() = 0 Then
		Return;
	EndIf;
	
	For Each ItemDescription In Added_Items Do
		SubjectLine = Subjects.Add();
		FillPropertyValues(SubjectLine, ItemDescription);
		SubjectLine.Picture = IntegrationWith1CDocumentManagementClientServer.ImageNumberBySubjectRole(
			SubjectLine.RoleOfSubject);
	EndDo;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OpenArticle()
	
	CurrentData = Items.Subjects.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.Ref) Then
		ShowValue(, CurrentData.Ref);
		
	Else
		NotificationParameters = New Structure;
		NotificationParameters.Insert("RowID", CurrentData.GetID());
		NotificationParameters.Insert("SubjectOf", CurrentData.SubjectOf);
		NotificationParameters.Insert("SubjectOfID", CurrentData.SubjectOfID);
		NotificationParameters.Insert("SubjectOfType", CurrentData.SubjectOfType);
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(
			CurrentData.SubjectOfType, CurrentData.SubjectOfID);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RereadProcess()
	
	ReceivingParameters = New Structure("ID, type", ID, Type);
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(Type, ReceivingParameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
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
