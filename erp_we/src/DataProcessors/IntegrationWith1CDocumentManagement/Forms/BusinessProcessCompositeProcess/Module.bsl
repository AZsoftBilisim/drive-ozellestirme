#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MultiSubjectivityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.3.1");
	Items.MultiSubjectPages.CurrentPage = ?(MultiSubjectivityIsAvailable,
		Items.PageAvailableMultiSubjects,
		Items.PageUnavailableMultiSubject);
	
	ProcessTypeXDTO = "DMComplexBusinessProcess";
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(ProcessTypeXDTO, Parameters);
	FillOutFormFromXDTOObject(XDTODataObject);
	
	If Parameters.Property("Template") Then
		TemplateID = Parameters.Template.ID;
		TemplateType = Parameters.Template.type;
	EndIf;
	
	SetItemsVisibility();
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfBusinessProcessForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	Items.OrderOfExecutionOfSwitch.ChoiceList.Clear();
	Items.OrderOfExecutionOfSwitch.ChoiceList.Add(
		"Параллельно",
		NStr("en = 'To all at once'; fa = 'به همه به‌طور همزمان'")); //@NON-NLS-1
	Items.OrderOfExecutionOfSwitch.ChoiceList.Add(
		"Последовательно",
		NStr("en = 'In sequence'; fa = 'به ترتیب'")); //@NON-NLS-1
	Items.OrderOfExecutionOfSwitch.ChoiceList.Add(
		"Смешанно",
		NStr("en = 'Mixed'; fa = 'ترکیبی'")); //@NON-NLS-1
	
	sh_ShamsiInit(); // sh_ShamsiInit
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
		
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		If Parameter.ID = ID Then
			RereadProcess();
		EndIf;
		
	ElsIf (EventName = "DocumentManagement_SelectAValueFromTheDropDownListCompletion"
				Or EventName = "DocumentManagement_SelectingDataForAutoComplete")
			And Source = ThisObject
			And Parameter.Attribute = "Importance" Then
		ChangeImportanceOfStages();
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
Procedure OrderOfExecutionOfSwitchOnChange(Item)
	
	ProcessChoiceOfExecutionOrder();
	
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
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Importance",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
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
				"Author",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Author",
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
Procedure InspectorAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser;DMBusinessProcessExecutorRole",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure InspectorTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMUser;DMBusinessProcessExecutorRole",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			If Item = Items.Inspector Then
				IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
					"Inspector", "ControllerAddressObject",
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
Procedure InspectorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.ApplyBusinessProcessParticipantSelectionInField(
		"Inspector",
		"ControllerAddressObject",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure TermDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If DueDate = BegOfDay(DueDate) Then
		DueDate = EndOfDay(DueDate);
	EndIf;
	
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
	
	If ExecutionOrderID <> "Смешанно" Then //@NON-NLS-1
		Items.StagesPredecessorsOfStringStage.Visible = False;
	Else
		Items.StagesPredecessorsOfStringStage.Visible = True;
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
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.routingType,
		"ExecutionOrder");
	ProcessChoiceOfExecutionOrder();
	
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
		ThisObject,
		XDTODataObject.businessProcessTemplate,
		"Template");
	
	Stages.Clear();
	Number = 1;
	For Each Stage In XDTODataObject.stages Do
		NewRow = Stages.Add();
		NewRow.LineNumber = Number;
		
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
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, Stage.template, "BusinessProcessTemplate");
		AddTemplateNameByTemplateType(NewRow);
		NewRow.PredecessorsOfStringStage = Stage.stagePredecessors;
		NewRow.PredecessorsUseCase = Stage.predecessorsUseOption;
		NewRow.UnconditionalTransitionToNextWasPerformed = Stage.unconditionalPassageExecuted;
		NewRow.TaskExecuted = Stage.executed;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, Stage.businessProcess, "RunningBusinessProcess");
		If Stage.IsSet("businessProcess") Then
			NewRow.DueDate_2 = Stage.businessProcess.dueDate;
		EndIf;
		If ValueIsFilled(NewRow.DueDate_2) And Not NewRow.TaskExecuted Then
			NewRow.DueDate = StrTemplate("%1 (%2)",
				Format(NewRow.DueDate_2, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
												|ru = 'ДФ=''dd.MM.yyyy HH:mm''';
												|en = 'DF=''MM/dd/yyyy hh:mm tt'''; fa = 'DF=''MM/dd/yyyy hh:mm tt''';
												|it = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
												|pl = 'DF=''dd.MM.yyyy hh:mm''';
												|tr = 'DF=''dd.MM.yyyy HH:mm'''")), Stage.duration);
		Else
			NewRow.DueDate = Stage.duration;
		EndIf;
		Number = Number + 1;
	EndDo;
	
	PredecessorsOfStages.Clear();
	For Each Predecessor In XDTODataObject.predecessors Do
		NewRow = PredecessorsOfStages.Add();
		NewRow.FollowerID = Predecessor.followerID;
		If Predecessor.IsSet("predecessorID") Then
			NewRow.PredecessorID = Predecessor.predecessorID;
		EndIf;
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, Predecessor.passageCondition, "TransitionCondition");
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			NewRow, Predecessor.considerationCondition, "ConsiderationCondition");
		NewRow.ConditionalTransitionWasExecuted = Predecessor.passageExecuted;
	EndDo;
	
	// It is possible that changing the process is prohibited by its template.
	ProhibitedUpdate = False;
	If XDTODataObject.Properties().Get("blockedByTemplate") <> Undefined Then
		ProhibitedUpdate = XDTODataObject.blockedByTemplate;
	EndIf;
	Items.Inspector.ReadOnly = Items.Inspector.ReadOnly
		Or (ValueIsFilled(InspectorID) And ProhibitedUpdate);
	Items.TermDate.ReadOnly = Items.TermDate.ReadOnly
		Or (ValueIsFilled(DueDate) And ProhibitedUpdate);
	If Stages.Count() > 0 And ProhibitedUpdate Then
		Items.Stages.ReadOnly = True;
		Items.OrderOfExecutionOfSwitch.Enabled = False;
	EndIf;
	
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
Procedure ProcessChoiceOfExecutionOrder()
	
	If ExecutionOrderID <> "Смешанно" Then //@NON-NLS-1
		Items.StagesPredecessorsOfStringStage.Visible = False;
	Else
		Items.StagesPredecessorsOfStringStage.Visible = True;
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
Function CreateObject(Proxy, Type)
	
	Return IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
EndFunction

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
		Proxy, "DMComplexBusinessProcess", ThisObject);
	StagesOfBusinessProcess = XDTODataObject.stages; //XDTOList
	PredecessorsOfBusinessProcessStages = XDTODataObject.predecessors; //XDTOList
	
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
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		ThisObject,
		"ExecutionOrder",
		XDTODataObject.routingType,
		"DMBusinessProcessRoutingType");
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
		Proxy,
		ThisObject,
		"Template",
		XDTODataObject.businessProcessTemplate,
		TemplateType);
	
	For Each Stage In Stages Do
		XDTOStage = CreateObject(Proxy, "DMComplexBusinessProcessStage");
		XDTOStage.stageID = String(Stage.StageID);
		XDTOStage.participants = Stage.StringPerformers;
		XDTOStage.stagePredecessors = Stage.PredecessorsOfStringStage;
		XDTOStage.executed = Stage.TaskExecuted;
		If ValueIsFilled(Stage.RunningBusinessProcessID) Then
			XDTOStage.businessProcess = IntegrationWith1CDocumentManagementCore.GetObject(
				Proxy,
				Stage.RunningBusinessProcessType,
				Stage.RunningBusinessProcessID);
		EndIf;
		XDTOStage.predecessorsUseOption = Stage.PredecessorsUseCase;
		XDTOStage.unconditionalPassageExecuted = Stage.UnconditionalTransitionToNextWasPerformed;
		
		If Stage.Importance = 0 Then
			ImportanceOfStage = NStr("vi = 'Mức độ quan trọng thấp';
									|ru = 'Низкая важность';
									|en = 'Low importance'; fa = 'اهمیت پایین';
									|it = 'Bassa importanza';
									|pl = 'Niska ważność';
									|tr = 'Az önemlilik'");
			ImportanceOfStageID = "Низкая"; //@NON-NLS-1
		ElsIf Stage.Importance = 1 Then
			ImportanceOfStage = NStr("vi = 'Mức độ quan trọng thường';
									|ru = 'Обычная важность';
									|en = 'Normal importance'; fa = 'اهمیت عادی';
									|it = 'Media importanza';
									|pl = 'Zwykła ważność';
									|tr = 'Normal önemlilik'");
			ImportanceOfStageID = "Обычная"; //@NON-NLS-1
		ElsIf Stage.Importance = 2 Then
			ImportanceOfStage = NStr("vi = 'Mức độ quan trọng cao';
									|ru = 'Высокая важность';
									|en = 'High importance'; fa = 'اهمیت بالا';
									|it = 'Alta importanza';
									|pl = 'Wysoka ważność';
									|tr = 'Yüksek önemlilik'");
			ImportanceOfStageID = "Высокая"; //@NON-NLS-1
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTOStage, "importance") Then
			XDTOStage.importance = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMBusinessProcessImportance");
			XDTOStage.importance.name = ImportanceOfStage;
			XDTOStage.importance.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				ImportanceOfStageID,
				"DMBusinessProcessImportance");
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Stage,
			"BusinessProcessTemplate",
			XDTOStage.template,
			"DMObject");
		
		StagesOfBusinessProcess.Add(XDTOStage);
	EndDo;
	
	For Each Predecessor In PredecessorsOfStages Do
		
		PredecessorOfXDTO = CreateObject(Proxy, "DMComplexBusinessProcessStagePredecessor");
		PredecessorOfXDTO.followerID = Predecessor.FollowerID;
		PredecessorOfXDTO.passageExecuted = Predecessor.ConditionalTransitionWasExecuted;
		
		If ValueIsFilled(Predecessor.PredecessorID) Then
			PredecessorOfXDTO.predecessorID = Predecessor.PredecessorID;
		EndIf;
		
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Predecessor,
			"TransitionCondition",
			PredecessorOfXDTO.passageCondition,
			"DMRoutingCondition");
		
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(
			Proxy,
			Predecessor,
			"ConsiderationCondition",
			PredecessorOfXDTO.considerationCondition,
			"DMPredecessorsStageConsiderationCondition");
		
		PredecessorsOfBusinessProcessStages.Add(PredecessorOfXDTO);
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

&AtClient
Procedure ChangeImportanceOfStages()
	
	If ImportanceID = "Низкая" Then //@NON-NLS-1
		NewValue = 0;
	ElsIf ImportanceID = "Обычная" Then //@NON-NLS-1
		NewValue = 1;
	ElsIf ImportanceID = "Высокая" Then //@NON-NLS-1
		NewValue = 2;
	EndIf;
	
	For Each Stage In Stages Do
		Stage.Importance = NewValue;
	EndDo;
	
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
