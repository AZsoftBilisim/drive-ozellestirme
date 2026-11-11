#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MultiSubjectivityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.3.1");
	Items.MultiSubjectPages.CurrentPage = ?(MultiSubjectivityIsAvailable,
		Items.PageAvailableMultiSubjects,
		Items.PageUnavailableMultiSubject);
	
	ProcessTypeXDTO = "DMBusinessProcessPerformance";
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(ProcessTypeXDTO, Parameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
	If Parameters.Property("Template") Then
		TemplateID = Parameters.Template.ID;
		TemplateType = Parameters.Template.type;
	EndIf;
	
	SetItemsVisibility();
	
	Items.VariantOfExecution.ReadOnly = ReadOnly;
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfBusinessProcessForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	Items.VariantOfExecution.ChoiceList.Clear();
	Items.VariantOfExecution.ChoiceList.Add(
		"Параллельно",
		NStr("en = 'To all at once'; fa = 'به همه به‌طور همزمان'")); //@NON-NLS-1
	Items.VariantOfExecution.ChoiceList.Add(
		"Последовательно",
		NStr("en = 'In sequence'; fa = 'به ترتیب'")); //@NON-NLS-1
	Items.VariantOfExecution.ChoiceList.Add(
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
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Changed" And Parameter = Items.SubjectOfPresentation Then
		SubjectOf = Source.Presentation;
		
	ElsIf EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion" And Source = ThisObject Then
		If Parameter.Attribute = "OrderOfExecution" Then
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
Procedure ImportanceStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList("DMBusinessProcessImportance", "Importance", ThisObject);
	
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
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching("Importance", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure VersionSwitchWhenChanging(Item)
	ProcessChoiceOfExecutionOption();
	Modified = True;
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
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching("Author", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching("Author", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure SupervisorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("SupervisorStartChoiceCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectBusinessProcessPerformer",,
		ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SupervisorStartChoiceCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", Supervisor);
	Result.Property("PerformerID", SupervisorID);
	Result.Property("PerformerType", SupervisorType);
	
	Result.Property("MainAddressingObject", MainObjectOfVerifierAddressing);
	Result.Property("MainAddressingObjectID", MainObjectOfVerifierAddressingID);
	Result.Property("MainAddressingObjectType", MainObjectOfVerifierAddressingType);
	
	Result.Property("AdditionalAddressingObject", AdditionalVerifierAddressingObject);
	Result.Property("AdditionalAddressingObjectID", AdditionalVerifierAddressingObjectID);
	Result.Property("AdditionalAddressingObjectType", AdditionalVerifierAddressingObjectType);
	
EndProcedure

&AtClient
Procedure SupervisorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
		"Supervisor",
		"VerifierAddressObject",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure InspectorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("InspectorStartChoiceCompletion", ThisObject);
		
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.SelectBusinessProcessPerformer",,
		ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InspectorStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", Inspector);
	Result.Property("PerformerID", InspectorID);
	Result.Property("PerformerType", InspectorType);
	
	Result.Property("MainAddressingObject",MainObjectOfControllerAddressing);
	Result.Property("MainAddressingObjectID", MainObjectOfControllerAddressingID);
	Result.Property("MainAddressingObjectType", MainObjectOfControllerAddressingType);
	
	Result.Property("AdditionalAddressingObject", AdditionalControllerAddressingObject);
	Result.Property("AdditionalAddressingObjectID", AdditionalControllerAddressingObjectID);
	Result.Property("AdditionalAddressingObjectType", AdditionalControllerAddressingObjectType);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure InspectorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
		"Inspector",
		"ControllerAddressObject",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
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
			If Item = Items.Supervisor Then
				IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
					"Supervisor",
					"VerifierAddressObject",
					ChoiceData[0].Value,
					StandardProcessing,
					ThisObject);
			ElsIf Item = Items.Inspector Then
				IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
					"Inspector",
					"ControllerAddressObject",
					ChoiceData[0].Value,
					StandardProcessing,
					ThisObject);
			Else
				IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInList(
					Item.Parent.Parent,
					ChoiceData[0].Value,
					StandardProcessing,
					ThisObject);
			EndIf;
			StandardProcessing = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessProcessParticipantSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInList(Item.Parent.Parent, ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure TermDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If DueDate = BegOfDay(DueDate) Then
		DueDate = EndOfDay(DueDate);
	EndIf;
	
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
Procedure AssigneesOnActivateRow(Item)
	
	If Items.Assignees.CurrentData <> Undefined Then
		LineNumber = Assignees.IndexOf(Items.Assignees.CurrentData) + 1;
		
		Items.ExecutorsResponsibleExecutor.Check = Items.Assignees.CurrentData.EmployeeResponsible;
		Items.ExecutorsResponsibleExecutor.Enabled =
			LineNumber = 1
			And Assignees.Count() > 1
			And Not Started;
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesDueDateOnChange(Item)
	
	If Items.Assignees.CurrentData.DueDate = BegOfDay(Items.Assignees.CurrentData.DueDate) Then
		Items.Assignees.CurrentData.DueDate = EndOfDay(Items.Assignees.CurrentData.DueDate);
	EndIf;

EndProcedure

&AtClient
Procedure AssigneesOrderOfExecutionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMTaskExecutionOrder",
		"OrderOfExecution",
		ThisObject,,
		True,
		Item);
	
EndProcedure

&AtClient
Procedure AssigneesOrderOfExecutionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMTaskExecutionOrder",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesOrderOfExecutionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching("DMTaskExecutionOrder", ChoiceData, Text, StandardProcessing);
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"OrderOfExecution",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,
				True,
				Item);
			StandardProcessing = True;
			FillInStep(Assignees);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AssigneesOrderOfExecutionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"OrderOfExecution",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		True,
		Item);
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
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, True);
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
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillFromTemplate(Command)
	
	Notification = New CallbackDescription("FillFromTemplateCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.StartSelectingBusinessProcessTemplate(Notification, ThisObject);
	
EndProcedure

&AtClient
Procedure ResponsibleExecutor(Command)
	
	If Items.Assignees.CurrentData = Undefined Then
		Return;
	EndIf;
	
	EmployeeResponsible = Items.Assignees.CurrentData.EmployeeResponsible;
	For Each TableRow In Assignees Do
		TableRow.EmployeeResponsible = False;
	EndDo;
	
	Items.Assignees.CurrentData.EmployeeResponsible = Not EmployeeResponsible;
	Items.ExecutorsResponsibleExecutor.Check = Items.Assignees.CurrentData.EmployeeResponsible;
	
EndProcedure

 &AtClient
Procedure MoveDown(Command)
	
	IndexOfCurCollectionItem = Assignees.IndexOf(
		Items.Assignees.CurrentData);
	CollectionItemsCount = Assignees.Count();
	If IndexOfCurCollectionItem < CollectionItemsCount - 1 Then
		Assignees.Move(IndexOfCurCollectionItem, 1);
	EndIf;
	Modified = True;
	FillInStep(Assignees);
	
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
Procedure SetItemsVisibility()
	// routing conditions
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		Items.VariantOfExecution.Visible = True;
		If VariantOfExecutionID <> "Смешанно" Then //@NON-NLS-1
			Items.AssigneesStep.Visible = False;
			Items.AssigneesOrderOfExecution.Visible = False;
		Else
			Items.AssigneesStep.Visible = True;
			Items.AssigneesOrderOfExecution.Visible = True;
		EndIf;
		
		If VariantOfExecutionID <> "Параллельно" Then //@NON-NLS-1
			Items.PerformersUp.Visible = True;
			Items.PerformersDown.Visible = True;
		Else
			Items.PerformersUp.Visible = False;
			Items.PerformersDown.Visible = False;
		EndIf;
	Else
		Items.VariantOfExecution.Visible = False;
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
	DataProcessors.IntegrationWith1CDocumentManagement.SetVisibilityOfProcessStateChangeCommands(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInControllerInForm(ThisObject, XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInExaminerInForm(ThisObject, XDTODataObject);
	
	// routing conditions
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject,
			XDTODataObject.performanceType,
			"VariantOfExecution");
	EndIf;
	
	Assignees.Clear();
	
	For Each Performer In XDTODataObject.performers Do
		NewRow = Assignees.Add();
		DataProcessors.IntegrationWith1CDocumentManagement.FillInInformationInForm(NewRow, Performer);
		NewRow.DueDate = Performer.personalDueDate;
		NewRow.InstructionDescription = Performer.personalDescription;
		NewRow.NameOfOrder = Performer.personalTaskName;
		NewRow.EmployeeResponsible = Performer.responsible;
		// routing conditions
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
				NewRow, Performer.performanceOrder, "OrderOfExecution")
		EndIf;
	EndDo;
	
	Items.Assignees.ChildItems.PerformersTime.Visible = XDTODataObject.dueTimeEnabled;
	Items.ExecutorsResponsibleExecutor.Enabled = Not ReadOnly;
	
	If XDTODataObject.IsSet("project") Then
		ProjectTask = XDTODataObject.project.name;
	EndIf;
	
	// It is possible that changing the process is prohibited by its template.
	ProhibitedUpdate = False;
	If XDTODataObject.Properties().Get("blockedByTemplate") <> Undefined Then
		ProhibitedUpdate = XDTODataObject.blockedByTemplate;
	EndIf;
	Items.Inspector.ReadOnly = Items.Inspector.ReadOnly
		Or (ValueIsFilled(InspectorID) And ProhibitedUpdate);
	Items.Supervisor.ReadOnly = Items.Supervisor.ReadOnly
		Or (ValueIsFilled(SupervisorID) And ProhibitedUpdate);
	Items.TermDate.ReadOnly = Items.TermDate.ReadOnly
		Or (ValueIsFilled(DueDate) And ProhibitedUpdate);
	Items.TermTime.ReadOnly = Items.TermTime.ReadOnly
		Or (ValueIsFilled(DueDate) And ProhibitedUpdate);
	If Assignees.Count() > 0 And ProhibitedUpdate Then
		Items.Assignees.ReadOnly = True;
		Items.PerformersUp.Enabled = False;
		Items.PerformersDown.Enabled = False;
		Items.ExecutorsResponsibleExecutor.Enabled = False;
		Items.VariantOfExecution.Enabled = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInStep(Table)
	
	For Each String In Table Do
		String.Step = 0;
	EndDo;
	
	RowsCount = Table.Count();
	For Indus = 0 To RowsCount - 1 Do
		String = Table[Indus];
		If Not ValueIsFilled(String.OrderOfExecutionID) Then
			Break;
		EndIf;
		
		If String.EmployeeResponsible Then
			Continue;
		EndIf;
		
		If Indus = 0 Then
			String.Step = 1;
			Continue;
		EndIf;
		
		If Not Table[Indus-1].EmployeeResponsible Then
			PreviousString = Table[Indus-1];
		Else
			If Indus > 1 Then
				PreviousString = Table[Indus-2];
			Else
				PreviousString = Table[Indus-1];
			EndIf;
		EndIf;
		If String.OrderOfExecutionID = "ВместеСПредыдущим" Then //@NON-NLS-1
			String.Step = PreviousString.Step;
			If PreviousString.EmployeeResponsible And Indus = 1 Then
				String.Step = 1;
			EndIf;
		ElsIf String.OrderOfExecutionID = "ПослеПредыдущего" Then //@NON-NLS-1
			String.Step = PreviousString.Step + 1;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessChoiceOfExecutionOption()
	
	If VariantOfExecutionID <> "Смешанно" Then //@NON-NLS-1
		Items.AssigneesStep.Visible = False;
		Items.AssigneesOrderOfExecution.Visible = False;
	Else
		Items.AssigneesStep.Visible = True;
		Items.AssigneesOrderOfExecution.Visible = True;
	EndIf;
	
	If VariantOfExecutionID <> "Параллельно" Then //@NON-NLS-1
		Items.PerformersUp.Visible = False;
		Items.PerformersDown.Visible = False;
	Else
		Items.PerformersUp.Visible = True;
		Items.PerformersDown.Visible = True;
	EndIf;
	
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
		"DMBusinessProcessPerformance",
		ThisObject);
	ProcessExecutors = XDTODataObject.performers; // XDTOList
	
	// The controller.
	DataController = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		InspectorID,
		InspectorType,
		Inspector);
	DataIsControllerSMainAddressingObject =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			MainObjectOfControllerAddressingID,
			MainObjectOfControllerAddressingType,
			MainObjectOfControllerAddressing);
	DataIsAdditionalObjectOfControllerSAddressing =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			AdditionalControllerAddressingObjectID,
			AdditionalControllerAddressingObjectType,
			AdditionalControllerAddressingObject);
	
	XDTODataObject.controller = IntegrationWith1CDocumentManagement.TaskParticipant(
		Proxy,
		DataController,
		DataIsControllerSMainAddressingObject,
		DataIsAdditionalObjectOfControllerSAddressing);
	
	// The examiner.
	DataVerifier = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		SupervisorID,
		SupervisorType,
		Supervisor);
	DataIsMainObjectOfVerifierSAddressing =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			MainObjectOfVerifierAddressingID,
			MainObjectOfVerifierAddressingType,
			MainObjectOfVerifierAddressing);
	DataIsAdditionalObjectOfVerifierSAddressing =
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			AdditionalVerifierAddressingObjectID,
			AdditionalVerifierAddressingObjectType,
			AdditionalVerifierAddressingObject);
	
	XDTODataObject.verifier = IntegrationWith1CDocumentManagement.TaskParticipant(
		Proxy,
		DataVerifier,
		DataIsMainObjectOfVerifierSAddressing,
		DataIsAdditionalObjectOfVerifierSAddressing);
	
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
		
		Performer = IntegrationWith1CDocumentManagement.ParticipantInProcessExecution(
			Proxy,
			DataExecutor,
			DataIsMainObject,
			DataIsAdditionalObject);
		Performer.personalDueDate = String.DueDate;
		Performer.personalDescription = String.InstructionDescription;
		Performer.personalTaskName = String.NameOfOrder;
		Performer.responsible = String.EmployeeResponsible;
		
		// routing conditions
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
			IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
				Proxy,
				String,
				"OrderOfExecution",
				Performer.performanceOrder,
				"DMTaskExecutionOrder");
		EndIf;
		
		ProcessExecutors.Add(Performer);
		
	EndDo;
	
	// routing conditions
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			ThisObject,
			"VariantOfExecution",
			XDTODataObject.performanceType,
			"DMBusinessProcessRoutingType");
	EndIf;
	
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
	IntegrationWith1CDocumentManagementClient.AddSubject(ThisObject, "Main", CallbackDescription);
	
EndProcedure

&AtClient
Procedure AddSubjectSupplementary(Command)
	
	CallbackDescription = New CallbackDescription("AddSubjectCompletion", ThisObject);
	IntegrationWith1CDocumentManagementClient.AddSubject(ThisObject, "Auxiliary", CallbackDescription);
	
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
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(CurrentData.SubjectOfType, CurrentData.SubjectOfID);
		
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
	If Item.Name = "sh_ShamsiInput_F_DueDate" Then
		TermDateOnChange(Items.TermDate);
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
