#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3.WhenCreatingActionFormOnServer(ThisObject, Parameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "DeletingParticipantsInAction" And Source = UUID Then
		UpdatePresentationsInParticipantTree(Attendees);
		SetFormItemEnabled();
		
	ElsIf EventName = "UpdatePresentationsInParticipantTree" And Source = UUID Then
		UpdatePresentationsInParticipantTree(Attendees);
		SetFormItemEnabled();
		IntegrationWith1CDocumentManagement3Client.ParticipantsInActionWhenLineIsActivated(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagement3Client.SelectEmployeeFromDepartmentTree("Author", ThisObject, True);
	
EndProcedure

&AtClient
Procedure AuthorAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
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
Procedure AuthorClearing(Item, StandardProcessing)
	
	Author = "";
	AuthorID = "";
	AuthorType = "";
	AuthorPresentation = "";
	
	Modified = True;
	
EndProcedure

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
Procedure DescriptionOfDelayedStartOfExecutionClick(Item, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DescriptionOfDelayedStartOfClickAction(
		ThisObject,
		StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttendees

&AtClient
Procedure AttendeesOnChange(Item)
	
	UpdatePresentationsInParticipantTree(Attendees);
	IntegrationWith1CDocumentManagement3Client.ExpandActionParticipantTree(ThisObject);
	
EndProcedure

&AtClient
Procedure AttendeesOnActivateRow(Item)
	
	SetFormItemEnabled();
	IntegrationWith1CDocumentManagement3Client.ParticipantsInActionWhenLineIsActivated(ThisObject);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeDeleteRow(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeDeletion(ThisObject, Cancel, True);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttendeesBeforeRowChange(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeStartOfChange(ThisObject, Cancel, True);
	
EndProcedure

&AtClient
Procedure AttendeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Attendees.FindByID(RowSelected);
	If CurrentData <> Undefined Then
		OpenSpecialNameAndDescription = Not CurrentData.ThisIsAStep
			And (CurrentData.Function = "Registrar");
		GeneralResolution = Undefined;
		If Permissions.Count() > 0 Then
			GeneralResolution = Permissions[0].Resolution;
		EndIf;
		OnlyViewingSpecialNameAndDescription = ReadOnly
			Or (GeneralResolution = "Forbidden")
			Or (GeneralResolution = Undefined);
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsInActionChoice(
		ThisObject,
		RowSelected,
		Field,
		StandardProcessing,
		OpenSpecialNameAndDescription,
		OnlyViewingSpecialNameAndDescription);
	
EndProcedure

&AtClient
Procedure LinePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfActionBeginningOfChoice(
		Item,
		ChoiceData,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinePresentationAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfActionAutoSelection(
		Item,
		Text,
		ChoiceData,
		DataGetParameters,
		Waiting,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinePresentationTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfActionEndOfTextInput(
		Item,
		Text,
		ChoiceData,
		DataGetParameters,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinePresentationChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfActionProcessingOfChoice(
		Item,
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure LinePresentationClearing(Item, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfCleaningAction(
		Item,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure DueDatePresentationOnChange(Item)
	
	IntegrationWith1CDocumentManagement3Client.DeadlineForExecutionOfActionByParticipantInCaseOfChange(ThisObject);
	
EndProcedure

&AtClient
Procedure DueDatePresentationTuning(Item, Direction, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DurationOfActionByParticipantIsRegulation(ThisObject, Direction, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LongDescOnChange(Item)
	
	UpdateFieldHasSpecialNameDescription(Items.Attendees.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateForm(True, False);
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure ContinueDialogue(Command)
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

&AtClient
Procedure ClearDelay(Command)
	
	IntegrationWith1CDocumentManagement3Client.ClearActionDelay(ThisObject);
	
EndProcedure

&AtClient
Procedure IsProtected(Command)
	
	IntegrationWith1CDocumentManagement3Client.ChangeProtectedActionParticipantAttribute(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

#Region Client

// Fills in the Presentation of deadlines in the action card.
//
&AtClient
Procedure FillInPresentationOfDeadlines() Export
	
	For Each ParticipantsStage In Attendees.GetItems() Do
		
		For Each StageParticipant In ParticipantsStage.GetItems() Do
			
			StageParticipant.DueDatePresentation =
				IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
					StageParticipant.DueDate,
					StageParticipant.Term_Days,
					StageParticipant.TermHours,
					StageParticipant.TermMinutes,
					UseDateAndTimeInTaskDeadlines,
					StageParticipant.OptionForSettingDeadline);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure SetFormItemEnabled() Export
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsAStep Then
		
		Items.LinePresentation.ReadOnly = True;
		Items.DueDatePresentation.ReadOnly = True;
		Items.ThereIsSpecialNameDescription.ReadOnly = True;
		Items.LongDesc.ReadOnly = True;
		
	ElsIf CurrentData.Function = "RegistrationResultProcessor" Then
		
		Items.LinePresentation.ReadOnly = False;
		Items.LinePresentation.ChoiceButton = True;
		Items.DueDatePresentation.ReadOnly = False;
		Items.ThereIsSpecialNameDescription.ReadOnly = False;
		Items.LongDesc.ReadOnly = False;
		
	Else
		
		LineViewOnly = (CurrentData.State = "Completed");
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.LinePresentation.ChoiceButton = True;
		Items.DueDatePresentation.ReadOnly = LineViewOnly;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Server

// Fills in the tree of participants by object.
//
&AtServer
Procedure UpdateTreeOfParticipantsByObject(XDTOAction)
	
	StagesOfParticipants = Attendees.GetItems();
	StagesOfParticipants.Clear();
	
	// Registration.
	RegisterStage = StagesOfParticipants.Add();
	RegisterStage.Function = "Registrar";
	RegisterStage.StageName = NStr("vi = 'Đăng ký';
									|ru = 'Зарегистрировать';
									|en = 'Register'; fa = 'ثبات';
									|it = 'Зарегистрировать';
									|pl = 'Register';
									|tr = 'Kayıt ol'");
	RegisterStage.ThisIsAStep = True;
	
	ParticipantsOfAction = XDTOAction.participantRows.rows;
	
	ParticipantsOfStage = RegisterStage.GetItems();
	AddedParticipant = False;
	Recorders = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(
		ParticipantsOfAction,
		"Registrar");
	For Each Recorder In Recorders Do
		StageParticipant = ParticipantsOfStage.Add();
		IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Recorder);
		StageParticipant.Function = Recorder.participantFunction;
		AddedParticipant = True;
		UpdateFieldHasSpecialNameDescription(StageParticipant);
		If Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(StageParticipant.Id) Then
			StageParticipant.Id = String(New UUID);
		EndIf;
	EndDo;
	
	If Not AddedParticipant Then
		StageParticipant = ParticipantsOfStage.Add();
		StageParticipant.Id = String(New UUID);
		StageParticipant.Function = RegisterStage.Function;
	EndIf;
	
	// Adding the result processor.
	FamiliarizationStage = StagesOfParticipants.Add();
	FamiliarizationStage.Function = "RegistrationResultProcessor";
	FamiliarizationStage.StageName = NStr("vi = 'Tham khảo với kết quả đăng ký';
											|ru = 'Ознакомиться с результатом регистрации';
											|en = 'Review the registration result'; fa = 'Review the registration result';
											|it = 'Ознакомиться с результатом регистрации';
											|pl = 'Review the registration result';
											|tr = 'Kayıt sonucunu incele'");
	FamiliarizationStage.ThisIsAStep = True;
	
	ParticipantsOfStage = FamiliarizationStage.GetItems();
	AddedParticipant = False;
	ParticipantProcessingResult = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(
		ParticipantsOfAction,
		"RegistrationResultProcessor");
	For Each ResultProcessor In ParticipantProcessingResult Do
		StageParticipant = ParticipantsOfStage.Add();
		IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, ResultProcessor);
		StageParticipant.Function = ResultProcessor.participantFunction;
		AddedParticipant = True;
		If Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(StageParticipant.Id) Then
			StageParticipant.Id = String(New UUID);
		EndIf;
	EndDo;
	
	If Not AddedParticipant Then
		StageParticipant = ParticipantsOfStage.Add();
		StageParticipant.Id = String(New UUID);
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			StageParticipant,
			XDTOAction.author,
			"Member",
			True);
		StageParticipant.Function = FamiliarizationStage.Function;
	EndIf;
	
	UpdatePresentationsInParticipantTree(Attendees);
	
EndProcedure

&AtServer
Procedure UpdateObjectInMemberTree(Proxy, XDTOAction)
	
	XDTOAction.participantRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionRegistrationParticipantRows");
	XDTOMembers = XDTOAction.participantRows.rows; // XDTOList
	
	ThereArePerformingParticipants = False;
	ThereIsProcessingResult = False;
	
	For Each ElementStage In Attendees.GetItems() Do
		
		For Each MemberElement In ElementStage.GetItems() Do
			
			If Not ValueIsFilled(MemberElement.MemberID) Then
				Continue;
			EndIf;
			
			XDTORow = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionRegistrationParticipantRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTORow, MemberElement);
			XDTORow.participantFunction = ElementStage.Function;
			XDTOMembers.Add(XDTORow);
			
			If Not IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(ElementStage.Function) Then
				ThereArePerformingParticipants = True;
			Else
				ThereIsProcessingResult = True;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// If only the "Processing result" is filled in, then we do not save it.
	If Not ThereArePerformingParticipants Then
		XDTOMembers.Clear();
	ElsIf Not ThereIsProcessingResult Then
		Raise NStr("vi = 'Không có người tham gia ""tham khảo với kết quả đăng ký""';
					|ru = 'Отсутствует участник ""ознакомления с результатом регистрации""';
					|en = 'The ""Registration result review"" participant is missing'; fa = 'The ""Registration result review"" participant is missing';
					|it = 'Отсутствует участник ""ознакомления с результатом регистрации""';
					|pl = 'The ""Registration result review"" participant is missing';
					|tr = '""Kayıt sonucunun incelenmesi"" katılımcısı yok'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFieldHasSpecialNameDescription(String)
	
	If String = Undefined Then
		Return;
	EndIf;
	
	String.ThereIsSpecialNameDescription = ValueIsFilled(String.LongDesc);
	
EndProcedure

// Updates Presentations of rows in the participant tree.
//
// Parameters:
//   Attendees - FormDataTree - a tree with participants.
//
&AtClientAtServerNoContext
Procedure UpdatePresentationsInParticipantTree(Attendees)
	
	For Each StageString_ In Attendees.GetItems() Do
		StageString_.LinePresentation = StageString_.StageName;
		For Each ParticipantLine In StageString_.GetItems() Do
			ParticipantLine.LinePresentation = IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(
				ParticipantLine);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingAction(XDTOAction)
	
	// Fill in the general action data.
	IntegrationWith1CDocumentManagement3.ProcessWebServiceSResponseToReceivingAction(ThisObject, XDTOAction);
	
	// Update the action form.
	UpdateTreeOfParticipantsByObject(XDTOAction);
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfConditionsOfParticipantsInAction(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInStatesAndResultsInActionForm(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.SetAvailabilityOfChangeOfParticipantsOfAction(ThisObject, Permissions);
	
EndProcedure

// Generates an XDTO object to be recorded in the Workflow based on data from the action Form.
//
// Returns:
//   String - string Presentation of an XDTO object of the type inheriting DMAction.
//
&AtServer
Function PrepareActionForRecording()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOAction = IntegrationWith1CDocumentManagement3.PrepareActionForRecording(Proxy, ThisObject);
	UpdateObjectInMemberTree(Proxy, XDTOAction);
	
	Return IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, XDTOAction);
	
EndFunction

#EndRegion

#Region Connection

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
		UpdateForm();
	EndIf;
	
EndProcedure

&AtServer
Function ProcessFormAccordingToServiceVersion() Export
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.13.29") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
			SettingsOf1CDocumentManagement = IntegrationWith1CDocumentManagementCoreCached.GetSettings();
			UseDateAndTimeInTaskDeadlines = SettingsOf1CDocumentManagement.UseDateAndTimeInTaskDeadlines;
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

#EndRegion

#Region UpdateForm

&AtClient
Procedure UpdateForm(OutputIdleWindow = False, HideInterface = True)
	
	If Not OutputIdleWindow And Not HideInterface Then
		Items.Page1CDocumentManagementIsAvailable.Enabled = False;
	EndIf;
	
	Columns = New Array;
	If DialogMode Then
		Columns.Add("dialogueMode");
	EndIf;
	TimeConsumingOperation = IntegrationWith1CDocumentManagementCoreServerCall.GetObjectAsynchronously(
		UUID,
		Type,
		ID,
		Columns);
	NotificationParameters = New Structure("OutputIdleWindow, HideInterface",
		OutputIdleWindow,
		HideInterface);
	CallbackOnCompletion = New CallbackDescription("UpdateFormCompletion", ThisObject, NotificationParameters);
	IntegrationWith1CDocumentManagementCoreClient.ExecuteRequestAsynchronously(
		ThisObject,
		TimeConsumingOperation,
		CallbackOnCompletion,
		OutputIdleWindow,,
		HideInterface);
	
EndProcedure

&AtClient
Procedure UpdateFormCompletion(Result, NotificationParameters) Export
	
	If Not NotificationParameters.OutputIdleWindow And Not NotificationParameters.HideInterface Then
		Items.Page1CDocumentManagementIsAvailable.Enabled = True;
	EndIf;
	
	ProcessAForm = False;
	IntegrationWith1CDocumentManagementCoreClient.CheckForErrorsWhenUpdatingForm(
		ThisObject,
		Result,
		ProcessAForm);
	If ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		ServerUpdateEnd(Result.ResultLongOperation);
		IntegrationWith1CDocumentManagement3Client.WhenOpeningActionForm(ThisObject);
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtServer
Procedure ServerUpdateEnd(ActionXDTOString)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTOAction = IntegrationWith1CDocumentManagementCore.StringInXDTOObject(Proxy, ActionXDTOString);
	ProcessWebServiceSResponseToReceivingAction(XDTOAction);
	
EndProcedure

#EndRegion

#Region WriteObject

&AtClient
Procedure BeforeWrite(Cancel)
	
	If Not ValueIsFilled(AuthorPresentation) Then
		Message = New UserMessage;
		Message.Text = CommonClientServer.FillingErrorText(,, NStr("ru = 'Автор';
																	|vi = 'Author';
																	|en = 'Author'; fa = 'ایجادکننده';
																	|it = 'Author';
																	|pl = 'Author';
																	|tr = 'Oluşturan'"));
		Message.Field = "AuthorPresentation";
		Message.Message();
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndClose()
	
	If Not ValueIsFilled(ID) Or Not ValueIsFilled(Type) Then
		Close(DialogReturnCode.Cancel);
		Return;
	EndIf;
	
	If Not Modified Then
		If DialogMode Then
			Close(DialogReturnCode.OK);
		Else
			Close(DialogReturnCode.Cancel);
		EndIf;
		Return;
	EndIf;
	
	Cancel = False;
	BeforeWrite(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.CheckParticipantsAndRecordAction(
		PrepareActionForRecording(),
		ThisObject,
		New CallbackDescription("WriteAndCloseCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure WriteAndCloseCompletion(Result, NotificationParameters) Export
	
	ProcessAForm = False;
	If IntegrationWith1CDocumentManagementCoreClient.ActionCompleted(Result, ProcessAForm) Then
		Modified = False;
		DataProcessorData = New Structure("SubjectOfID, SubjectOfType", MainSubjectID, MainSubjectType);
		Notify("Workflow_ActionWithProcessing", New Structure("DataProcessorData", DataProcessorData), ThisObject);
		Close();
	ElsIf ProcessAForm Then
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion