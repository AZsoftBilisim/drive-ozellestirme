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
	
EndProcedure

&AtClient
Procedure AttendeesOnActivateRow(Item)
	
	SetFormItemEnabled();
	IntegrationWith1CDocumentManagement3Client.ParticipantsInActionWhenLineIsActivated(ThisObject);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeDeleteRow(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeDeletion(ThisObject, Cancel);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	ParametersForAddingParticipantsToAction = IntegrationWith1CDocumentManagement3Client.ParametersForAddingParticipantsToAction();
	ParametersForAddingParticipantsToAction.WithStages = False;
	ParametersForAddingParticipantsToAction.ChildPerformersArePossible = False;
	ParametersForAddingParticipantsToAction.YouCanAddStages = False;
	ParametersForAddingParticipantsToAction.YouCanOnlyAddMembers = YouCanOnlyAddMembers;
	ParametersForAddingParticipantsToAction.ParticipantFunction = "Examinated";
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeAdding(
		ThisObject,
		Cancel,
		Copy,
		ParametersForAddingParticipantsToAction);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeRowChange(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeStartOfChange(ThisObject, Cancel);
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData <> Undefined
			And DataSourceIsActive
			And ValueIsFilled(CurrentData.DataSourceID) Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AttendeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Attendees.FindByID(RowSelected);
	If CurrentData <> Undefined Then
		OpenSpecialNameAndDescription = Not CurrentData.ThisIsAStep;
		GeneralResolution = Undefined;
		If Permissions.Count() > 0 Then
			GeneralResolution = Permissions[0].Resolution;
		EndIf;
		OnlyViewingSpecialNameAndDescription = ReadOnly
			Or (GeneralResolution = "Forbidden")
			Or (GeneralResolution = Undefined)
			Or (YouCanOnlyAddMembers And CurrentData.Unavailable);
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
	
	IntegrationWith1CDocumentManagement3Client.DeadlineForExecutionOfActionByParticipantInCaseOfChange(ThisObject, True);
	
EndProcedure

&AtClient
Procedure DueDatePresentationTuning(Item, Direction, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DurationOfActionByParticipantIsRegulation(
		ThisObject,
		Direction,
		StandardProcessing,
		True);
	
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
Procedure SendToNewMembers(Command)
	
	ExecutionOfActionWithNewParticipants = True;
	ReadOnly = False;
	Items.WriteAndClose.Visible = True;
	Items.WriteAndClose.DefaultButton = True;
	SetFormItemEnabled();
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	
	// Immediately add a new line.
	ParticipantLines = Attendees.GetItems();
	ParticipantLine = ParticipantLines.Add();
	ParticipantLine.LinePresentation =
		IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(ParticipantLine);
	
	IndexOfPreviousElement = ParticipantLines.Count() - 2;
	If IndexOfPreviousElement >= 0 Then
		ParticipantLine.OptionForSettingDeadline = ParticipantLines[IndexOfPreviousElement].OptionForSettingDeadline;
		If ParticipantLine.OptionForSettingDeadline = OptionsForSettingDeadline.Exact_Date Then
			ParticipantLine.DueDate = ParticipantLines[IndexOfPreviousElement].DueDate;
		Else
			ParticipantLine.Term_Days = ParticipantLines[IndexOfPreviousElement].Term_Days;
			ParticipantLine.TermHours = ParticipantLines[IndexOfPreviousElement].TermHours;
			ParticipantLine.TermMinutes = ParticipantLines[IndexOfPreviousElement].TermMinutes;
		EndIf;
	Else
		ParticipantLine.OptionForSettingDeadline = OptionsForSettingDeadline.RelativeTerm;
	EndIf;
	
	ParticipantLine.Function = "Examinated";
	Items.Attendees.CurrentRow = ParticipantLine.GetID();
	
	FillInPresentationOfDeadlines();
	
	Items.SendToNewMembers.Visible = False;
	Modified = True;
	
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
	
	For Each MemberElement In Attendees.GetItems() Do
		MemberElement.DueDatePresentation =
			IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
				MemberElement.DueDate,
				MemberElement.Term_Days,
				MemberElement.TermHours,
				MemberElement.TermMinutes,
				UseDateAndTimeInTaskDeadlines,
				MemberElement.OptionForSettingDeadline);
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure SetFormItemEnabled() Export
	
	If Items.Attendees.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.Attendees.CurrentData;
	
	IndexOf = Attendees.GetItems().IndexOf(CurrentData);
	ThisIsFirstElement = (IndexOf = 0);
	
	LineViewOnly = (CurrentData.State = "Completed")
		Or (DataSourceIsActive And ValueIsFilled(CurrentData.DataSourceID))
		Or (YouCanOnlyAddMembers And CurrentData.Unavailable)
		Or CurrentData.UnavailableGroup;
	
	Items.LinePresentation.ReadOnly = LineViewOnly;
	Items.DueDatePresentation.ReadOnly = LineViewOnly
		Or YouCanOnlyAddMembers And Not ThisIsFirstElement;
	Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
	Items.LongDesc.ReadOnly = LineViewOnly;
	
	Items.LinePresentation.ChoiceButton = True;
	
	Items.Delete.Enabled = Not LineViewOnly;
	Items.DeleteContext.Enabled = Not LineViewOnly;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure FillInStatesOfFamiliarization(XDTOAction)
	
	If Not IntegrationWith1CDocumentManagementCore.PropertySet(
			XDTOAction, "examinationResultRows") Then
		Return;
	EndIf;
	
	ResultsOfFamiliarization = New Map;
	For Each XDTORow In XDTOAction.examinationResultRows.rows Do
		ResultStructure1 = New Structure("HowManyAreFamiliar, HowManyThingsDoINeedToFamiliarizeMyselfWith, EndDateFinal");
		ResultStructure1.HowManyAreFamiliar = XDTORow.numberOfExaminedParticipants;
		ResultStructure1.HowManyThingsDoINeedToFamiliarizeMyselfWith = XDTORow.numberOfParticipantsToBeExamined;
		ResultStructure1.EndDateFinal = XDTORow.finalCompletionDate;
		ResultsOfFamiliarization.Insert(XDTORow.id, ResultStructure1);
	EndDo;
	
	MemberElements = Attendees.GetItems();
	
	For Each MemberElement In MemberElements Do
		
		StructureOfFamiliarization = ResultsOfFamiliarization.Get(MemberElement.Id);
		If StructureOfFamiliarization <> Undefined Then
			
			If StructureOfFamiliarization.HowManyAreFamiliar <> 0 Then // If not 0, then someone has already completed it.
				MemberElement.Unavailable = True;
				MemberElement.UnavailableGroup = True;
			EndIf;
			
			If StructureOfFamiliarization.HowManyAreFamiliar < StructureOfFamiliarization.HowManyThingsDoINeedToFamiliarizeMyselfWith Then
				MemberElement.State = "Performing";
				MemberElement.Result = "";
			Else
				MemberElement.State = "Completed";
				MemberElement.Result = "Examined";
			EndIf;
			
			MemberElement.PictureNumber =
				IntegrationWith1CDocumentManagement3ClientServer.NumberOfImageOfResultOfAction(
					MemberElement.Result,
					MemberElement.State);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the tree of participants by object.
//
&AtServer
Procedure UpdateTreeOfParticipantsByObject(XDTOAction)
	
	MemberElements = Attendees.GetItems();
	MemberElements.Clear();
	
	MaximumNumberOfParticipantsForShow = XDTOAction.maximumNumberOfParticipantsToShow;
	TotalCount = XDTOAction.numberOfParticipants;
	CurrentCount = 0;
	
	For Each Member In XDTOAction.participantRows.rows Do
		
		MemberElement = MemberElements.Add();
		CurrentCount = CurrentCount + 1;
		IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(MemberElement, Member);
		
		MemberElement.Function = "Examinated";
		UpdateFieldHasSpecialNameDescription(MemberElement);
		MemberElement.Unavailable = YouCanOnlyAddMembers;
		DataSourceIsActive = Member.dataSourceIsActive;
		
		If ReadOnly And CurrentCount >= MaximumNumberOfParticipantsForShow Then
			
			If TotalCount = 0 Then
				TotalCount = XDTOAction.participantRows.rows.Count();
			EndIf;
			
			AdditionalDescriptionToRead = StrTemplate(
				NStr("vi = 'và khác, tổng số %1, xem ""Quá trình tham khảo"".';
					|ru = 'и др., всего %1, см ""Ход ознакомления"".';
					|en = 'and others, total %1, see ""Preview progress"".'; fa = 'and others, total %1, see ""Preview progress"".';
					|it = 'и др., всего %1, см ""Ход ознакомления"".';
					|pl = 'and others, total %1, see ""Preview progress"".';
					|tr = 've benzeri, toplam %1, bkz. ""İnceleme ilerlemesi"".'"),
				TotalCount);
			MemberElement.AdditionalDescriptionToRead = StrTemplate(" %1 ", AdditionalDescriptionToRead);
			Break;
			
		EndIf;
		
	EndDo;
	
	UpdatePresentationsInParticipantTree(Attendees);
	
EndProcedure

&AtServer
Procedure UpdateObjectInMemberTree(Proxy, XDTOAction)
	
	XDTOAction.participantRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionExaminationParticipantRows");
	XDTOMembers = XDTOAction.participantRows.rows; // XDTOList
	
	For Each MemberElement In Attendees.GetItems() Do
		
		If Not ValueIsFilled(MemberElement.MemberID) Then
			Continue;
		EndIf;
		
		For Each XDTORow In XDTOMembers Do
			If MemberElement.LongDesc = XDTORow.description
					And MemberElement.MemberID = XDTORow.participant.objectID.id
					And MemberElement.MemberType = XDTORow.participant.objectID.type
					And ((MemberElement.IsProtected = True And XDTORow.protected = False)
						Or MemberElement.IsProtected = False) Then
				Raise StrTemplate(
					NStr("vi = 'Lặp lại người tham gia tham khảo: %1.
						|Hãy xóa bản trùng lặp, hãy chỉ ra mô tả đặc biệt hoặc thiết lập dấu hiệu ""Được bảo mật"" cho người tham gia';
						|ru = 'Повторяется участник ознакомления: %1.
						|Удалите дубли, укажите особое описание или установите участнику признак ""Защищенный""';
						|en = 'The %1 preview participant is duplicated.
						|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant'; fa = 'The %1 preview participant is duplicated.
						|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant';
						|it = 'Повторяется участник ознакомления: %1.
						|Удалите дубли, укажите особое описание или установите участнику признак ""Защищенный""';
						|pl = 'The %1 preview participant is duplicated.
						|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant';
						|tr = 'Tekrarlanan inceleme katılımcısı: %1.
						|Tekrarlananları silin, özel açıklama belirtin veya katılımcıyı ""Korumalı"" olarak yapılandırın'"),
					MemberElement.MemberPresentation);
			EndIf;
		EndDo;
		
		XDTOMember = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMActionExaminationParticipantRow");
		IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOMember, MemberElement);
		XDTOMembers.Add(XDTOMember);
		
	EndDo;
	
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
	
	For Each MemberElement In Attendees.GetItems() Do
		MemberElement.LinePresentation = IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(
			MemberElement,
			MemberElement.AdditionalDescriptionToRead);
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingAction(XDTOAction)
	
	// Fill in the general action data.
	IntegrationWith1CDocumentManagement3.ProcessWebServiceSResponseToReceivingAction(ThisObject, XDTOAction);
	
	// Fill in these familiarization actions.
	SignWithDS = XDTOAction.signWithDS;
	UseExaminationsWithEnhancedDS = XDTOAction.useExaminationsWithEnhancedDS;
	WaitForCompletion = XDTOAction.waitForCompletion;
	StateOfAction = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "state") Then
		StateOfAction = XDTOAction.state;
	EndIf;
	
	// Update the action form.
	UpdateTreeOfParticipantsByObject(XDTOAction);
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfConditionsOfParticipantsInAction(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInStatesAndResultsInActionForm(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.SetAvailabilityOfChangeOfParticipantsOfAction(ThisObject, Permissions);
	
	ThereIsActionSetting =
		IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "actionSettings")
		And ValueIsFilled(XDTOAction.actionSettings.objectID.id);
	Items.WaitForCompletion.Enabled = Not ThereIsActionSetting;
	Items.SignWithDS.Visible = UseExaminationsWithEnhancedDS And XDTOAction.target.objectID.type = "DMDocument";
	Items.SignWithDS.Enabled = Not ThereIsActionSetting;
	
	FillInStatesOfFamiliarization(XDTOAction);
	
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfDirectionToNewParticipantsOfAction(
		ThisObject,
		StateOfAction,
		XDTOAction.permissionRows.rows);
	
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
	XDTOAction.signWithDS = SignWithDS;
	XDTOAction.useExaminationsWithEnhancedDS = UseExaminationsWithEnhancedDS;
	XDTOAction.waitForCompletion = WaitForCompletion;
	UpdateObjectInMemberTree(Proxy, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInTableOfParticipantsInAction(ThisObject.AttendeesBeforeWrite, XDTOAction);
	
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
	
	If ExecutionOfActionWithNewParticipants
			And Not IntegrationWith1CDocumentManagement3ClientServer.ParticipantsOfActionHaveBeenChangedInCard(ThisObject) Then
		ShowMessageBox(,
			NStr("vi = 'Chưa thêm người tham gia mới.
				|Để khởi động tham khảo mới, hãy thêm người tham gia.';
				|ru = 'Новые участники не добавлены.
				|Для запуска нового ознакомления добавьте участников.';
				|en = 'New participants are not added.
				|To start a new preview, add participants.'; fa = 'New participants are not added.
				|To start a new preview, add participants.';
				|it = 'Новые участники не добавлены.
				|Для запуска нового ознакомления добавьте участников.';
				|pl = 'New participants are not added.
				|To start a new preview, add participants.';
				|tr = 'Yeni katılımcılar eklenmedi.
				|Yeni inceleme başlatmak için katılımcı ekleyin.'"));
		Cancel = True;
	EndIf;
	
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
	
	ActionXDTOString = PrepareActionForRecording();
	
	IntegrationWith1CDocumentManagement3Client.CheckParticipantsAndRecordAction(
		ActionXDTOString,
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