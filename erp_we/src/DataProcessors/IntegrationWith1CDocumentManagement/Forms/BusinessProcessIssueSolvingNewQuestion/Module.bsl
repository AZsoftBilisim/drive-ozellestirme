#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Solving issues of task execution.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3") Then
		Cancel = True;
		Return;
	EndIf;
	
	If Parameters.Property("ID") Then
		SubjectOfConsiderationID = Parameters.ID;
		SubjectOfConsiderationType = Parameters.type;
	Else
		Cancel = True;
		Return;
	EndIf;
	
	TypeOfQuestion = Parameters.TypeOfQuestion;
	TypeOfQuestionID = Parameters.TypeOfQuestionID;
	TypeOfQuestionType = "DMIssueType";
	
	// Files. The availability of individual commands is configured when the file is activated in the item tree.
	FileCaptureIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.4.9.1");
	// Multi-subject.
	MultiSubjectivityIsAvailable = False;
	
	UserName = SessionParameters.IntegrationWith1CDocumentManagementUsername;
	
	FillInNewBusinessProcessCard("DMBusinessProcessIssuesSolution", Parameters);
	If TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1
		Title = NStr("vi = 'Yêu cầu gia hạn mới';
					|ru = 'Новый запрос на перенос срока';
					|en = 'New time extension request'; fa = 'New time extension request';
					|it = 'Nuova richiesta di spostamento scadenza';
					|pl = 'Nowe zapytanie na przeniesienie terminu';
					|tr = 'Tarihin ertelenmesi ile ilgili yeni sorgu'");
	Else
		Title = NStr("vi = 'Câu hỏi mới';
					|ru = 'Новый вопрос';
					|en = 'New question'; fa = 'سؤال جدید';
					|it = 'Nuova domanda';
					|pl = 'Nowe pytanie';
					|tr = 'Yen soru'");
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreOverridable.AdditionalProcessingOfBusinessProcessForm(
		ThisObject,
		Cancel,
		StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, ,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		If Parameter.ID = ID Then
			RereadProcess();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ProcessFormByPresenceOfItems();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TaskClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(MainTask) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfConsiderationType, SubjectOfConsiderationID, Item);
	EndIf;

EndProcedure

&AtClient
Procedure ImportanceStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheDropDownList(
		"DMBusinessProcessImportance",
		"Importance",
		ThisObject);
	
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
Procedure TermDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If DueDate = BegOfDay(DueDate) Then
		DueDate = EndOfDay(DueDate);
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

&AtClient
Procedure SceneryItemsAndFilesURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	AddSubject(Undefined);
	
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
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(String.SubjectOfType,String.SubjectOfID, String);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationTreeOnActivateRow(Item)
	
	SetAvailabilityOfApplicationTreeCommands();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordBusinessProcess(Command)
	
	If CheckBusinessProcessCompletion() Then
		Return;
	EndIf;
	
	WriteObject();
	
EndProcedure

&AtClient
Procedure StartAndClose(Command)
	
	If CheckBusinessProcessCompletion() Then
		Return;
	EndIf;
	
	RunResult = PrepareForTransferAndStartBusinessProcess();
	
	If RunResult Then
		IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, True);
		Status(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã khởi chạy thành công quy trình nghiệp vụ ""%1"".';
				|ru = 'Бизнес-процесс ""%1"" успешно запущен.';
				|en = 'The ""%1"" business process is started successfully.'; fa = 'The ""%1"" business process is started successfully.';
				|it = 'Processo aziendale ""%1"" avviato con successo.';
				|pl = 'Proces biznesowy ""%1"" jest pomyślnie uruchomiony.';
				|tr = '""%1"" iş süreci başarıyla başlatıldı.'"), Presentation));
		Modified = False;
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddSubject(Command)
	
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
		WriteObject();
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
			Items.ApplicationTreePresentation);
			
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
Procedure Edit(Command)
	
	CurrentData = Items.ApplicationTree.CurrentData;
	If CurrentData = Undefined Or CurrentData.SubjectOfType <> "DMFile" Then
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

#EndRegion

#Region Private

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

&AtClient
Function CheckBusinessProcessCompletion()
	
	HasErrors = False;
	ClearMessages();
	
	If Not ValueIsFilled(LongDesc) Then
		CommonClient.MessageToUser(
			?(TypeOfQuestionID = "ПереносСрока",
				NStr("vi = 'Chưa chỉ ra cơ sở để gia hạn.';
					|ru = 'Не указано основание для переноса срока.';
					|en = 'Time extension reason is not specified.'; fa = 'Time extension reason is not specified.';
					|it = 'Non è indicata la base per lo spostamento della scadenza.';
					|pl = 'Nie określono podstawy do przeniesienia terminu.';
					|tr = 'Tarih erteleme nedeni belirtilmedi.'"),
				NStr("vi = 'Chưa điền trường ""Vấn đề""';
					|ru = 'Поле ""Вопрос"" не заполнено';
					|en = '""Issue"" is required'; fa = '""Issue"" is required';
					|it = 'Campo ""Domanda"" non compilato';
					|pl = 'Pole ""Pytanie"" nie jest wypełnione';
					|tr = '""Soru"" alanı doldurulmadı'")),,
			"LongDesc"); //@NON-NLS-1
		HasErrors = True;
	EndIf;
	
	If TypeOfQuestionID = "ПереносСрока" And Not ValueIsFilled(NewTerm) Then //@NON-NLS-1
		CommonClient.MessageToUser(NStr("vi = 'Chưa nhập thời hạn thực hiện mới.';
										|ru = 'Не введен новый срок выполнения.';
										|en = 'New due date is not specified.'; fa = 'New due date is not specified.';
										|it = 'Non è stata inserita una nuova scadenza.';
										|pl = 'Nie wprowadzono nowego terminu wykonania.';
										|tr = 'Yeni gerçekleştirme tarihi girilmedi.'"),,
			"NewTerm");
		HasErrors = True;
	EndIf;
	
	Return HasErrors;
	
EndFunction

&AtClient
Function WriteObject() Export
	
	PrepareForTransferAndRecordBusinessProcess();
	IntegrationWith1CDocumentManagementClient.Notify_BusinessProcessRecord(ThisObject, False);
	Title = Presentation;
	Status(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã lưu lại quy trình nghiệp vụ ""%1"".';
			|ru = 'Бизнес-процесс ""%1"" сохранен.';
			|en = 'Business process ""%1"" is saved.'; fa = 'Business process ""%1"" is saved.';
			|it = 'Processo aziendale ""%1"" salvato.';
			|pl = 'Proces biznesowy ""%1"" jest zapisany.';
			|tr = '""%1"" iş süreci kaydedildi.'"), Presentation));
	Modified = False;
	
	Return True;
	
EndFunction

&AtServer
Procedure FillInNewBusinessProcessCard(BusinessProcessType, SubjectOf)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	NewObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(
		Proxy,
		BusinessProcessType,
		SubjectOf);
	
	FillOutFormFromXDTOObject(NewObject);
	
EndProcedure

&AtServer
Procedure FillOutFormFromXDTOObject(XDTODataObject, UpdateItems = True)
	
	If XDTODataObject.IsSet("objectID") Then
		ID = XDTODataObject.objectID.ID;
		Type = XDTODataObject.objectID.type;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		Items.FormAddSubject.Visible = False;
		Items.FormDeleteSubject.Visible = False;
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(
		ThisObject,
		XDTODataObject);
	DataProcessors.IntegrationWith1CDocumentManagement.FillInStandardHeaderOfBusinessProcess(ThisObject, XDTODataObject);
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.initiator,
		"ProcessInitiator");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject,
		XDTODataObject.issueTask,
		"SubjectOfConsideration", True);
	
	Items.PostponementGroup.Visible = False;
	Items.LongDesc.InputHint = NStr("vi = 'Nội dung câu hỏi';
									|ru = 'Текст вопроса';
									|en = 'Issue text'; fa = 'متن مشکل';
									|it = 'Testo domanda';
									|pl = 'Tekst pytania';
									|tr = 'Soru metni'");
	Items.LongDesc.ToolTip = NStr("vi = 'Nội dung câu hỏi';
									|ru = 'Текст вопроса';
									|en = 'Issue text'; fa = 'متن مشکل';
									|it = 'Testo domanda';
									|pl = 'Tekst pytania';
									|tr = 'Soru metni'");
	Items.FormStartAndClose.Title = NStr("vi = 'Đặt câu hỏi và đóng';
										|ru = 'Задать вопрос и закрыть';
										|en = 'Ask a question and close'; fa = 'پرسیدن سؤال و بستن';
										|it = 'Porre domanda e chiudere';
										|pl = 'Zadaj pytanie i zamknij';
										|tr = 'Soru sor ve kapat'");
	
	If TypeOfQuestionID = "ПереносСрока" Then //@NON-NLS-1
		Items.PostponementGroup.Visible = True;
		Items.LongDesc.InputHint = NStr("vi = 'Giải thích yêu cầu';
										|ru = 'Обоснование запроса';
										|en = 'Request justification'; fa = 'Request justification';
										|it = 'Causale della richiesta';
										|pl = 'Uzasadnienie zapytania';
										|tr = 'Sorgunun gerekçesi'");
		Items.LongDesc.ToolTip = NStr("vi = 'Giải thích yêu cầu';
										|ru = 'Обоснование запроса';
										|en = 'Request justification'; fa = 'Request justification';
										|it = 'Causale della richiesta';
										|pl = 'Uzasadnienie zapytania';
										|tr = 'Sorgunun gerekçesi'");
		Items.FormStartAndClose.Title = NStr("vi = 'Gửi yêu cầu và đóng';
											|ru = 'Отправить запрос и закрыть';
											|en = 'Send request and close'; fa = 'Send request and close';
											|it = 'Inviare richiesta e chiudere';
											|pl = 'Wyślij zapytanie i zamknij';
											|tr = 'Sorgu gönder ve kapat'");
		
		OldDeadline = XDTODataObject.issueTask.dueDate;
		NewTerm = OldDeadline + 86400;
		
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
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		Items.ApplicationGroup.Visible = True;
		If UpdateItems And IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "files") Then
			FillApplicationTreeByFiles(XDTODataObject.files);
		EndIf;
	Else
		Items.ApplicationGroup.Visible = False;
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
	
	If RecordingResult <> Undefined Then
		SetBusinessProcessLink(Result.objects[0]);
	Else
		SetBusinessProcessLink(Result.object);
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
		"DMBusinessProcessIssuesSolution",
		ThisObject,
		"Template");
	
	IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(Proxy,
		ThisObject,
		"ProcessInitiator",
		XDTODataObject.initiator,
		"DMUser");
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTOTask = IntegrationWith1CDocumentManagementCore.GetObject(
		Proxy,
		SubjectOfConsiderationType,
		SubjectOfConsiderationID);
	TaskReceiver = CreateObject(
		Proxy,
		"DMBusinessProcessTask");
	IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(
		Proxy,
		TaskReceiver,
		XDTOTask);
	XDTODataObject.issueTask = TaskReceiver;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "issueType") Then
		IntegrationWith1CDocumentManagementCore.PopulateXDTOObjectFromObjectProps(Proxy,
			ThisObject,
			"TypeOfQuestion",
			XDTODataObject.issueType,
			TypeOfQuestionType);
	EndIf;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTODataObject, "newDueDate") Then
		XDTODataObject.newDueDate = NewTerm;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		FillWithItemsFromApplicationTree(Proxy, ApplicationTree.GetItems(), XDTODataObject);
	EndIf;
	
	Return XDTODataObject;
	
EndFunction

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
	
	If CheckBusinessProcessCompletion() Then
		Return;
	EndIf;
	
	WriteObject();
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteProgrammaticallyAddedCommand(Command)
	
	// Let's call the handler of the command that was added programmatically when creating the form on the server.
	IntegrationWith1CDocumentManagementCoreClientOverridable.ExecuteProgrammaticallyAddedCommand(Command, ThisObject);
	
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

&AtServer
Procedure FillApplicationTreeByFiles(XDTOFiles)
	
	Tree = FormAttributeToValue("ApplicationTree");
	
	AddFilesToApplicationTree(Tree.Rows, XDTOFiles, True);
	
	ValueToFormAttribute(Tree, "ApplicationTree");
	
EndProcedure

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
			If XDTOFile.IsSet("editingUser") Then
				FileString.EditedByCurUser =
					(Upper(XDTOFile.editingUser.name) = Upper(UserName));
			EndIf;
		EndIf;
		FileString.Presentation = FileString.SubjectOf;
		FileString.DeletionAvailable = DeletionAvailable;
	EndDo;
	
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

&AtServer
Procedure RereadProcess()
	
	ReceivingParameters = New Structure("ID, type", ID, Type);
	XDTODataObject = IntegrationWith1CDocumentManagement.GetProcessXDTOObject(Type, ReceivingParameters);
	FillOutFormFromXDTOObject(XDTODataObject, False);
	
EndProcedure

// Fills the XDTO object of the business process task with items from the application tree of the form.
//
&AtServer
Procedure FillWithItemsFromApplicationTree(Proxy, TreeRows, XDTODataObject)
	
	XDTODataObject.files.Clear();
	
	For Each SubjectLine In TreeRows Do
		
		file = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, SubjectLine.SubjectOfType);
		file.name = SubjectLine.SubjectOf;
		file.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectLine.SubjectOfID,
			SubjectLine.SubjectOfType);
		
		XDTODataObject.files.Add(file);
		
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
	If Item.Name = "sh_ShamsiInput_F_NewTerm" Then
		NewTermDateOnChange(Items.NewTermDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_DueDate" Then
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
