#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3.WhenCreatingActionFormOnServer(ThisObject, Parameters);
	
	FunctionalityOfSettingCyclesAndContinuationsIsAvailable =
		IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.17.36");
	
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
		
		ThereAreStages = IntegrationWith1CDocumentManagement3ClientServer.ThereAreStagesOfAction(
			Attendees,
			IdOfAgreeStage,
			IdOfPersonProcessingResult);
		UpdatePresentationsInParticipantTree(Attendees);
		SetFormItemEnabled();
		
	ElsIf EventName = "UpdatePresentationsInParticipantTree" And Source = UUID Then
		
		UpdatePresentationsInParticipantTree(Attendees);
		
		ChangeParameters = Parameter; // See IntegrationWith1CDocumentManagement3Client.NewNotificationParametersChangesInParticipants
		TypesOfChanges = IntegrationWith1CDocumentManagement3Client.TypesOfChangesOfParticipantsInAction();
		
		If ChangeParameters.CurrentData <> Undefined
				And ChangeParameters.ChangeType = TypesOfChanges.ChangingArtist Then
			OnChangingArtistInParticipants(ChangeParameters.CurrentData);
		EndIf;
		
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
Procedure MaximumNumberOfCyclesOnChange(Item)
	
	EnsureConsistencyOfAttributesOfCycleRestrictions(ThisObject);
	SetVisibilityAccessibilityOfElements(ThisObject);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure LimitMatchingCyclesOnChange(Item)
	
	EnsureConsistencyOfAttributesOfCycleRestrictions(ThisObject);
	SetVisibilityAccessibilityOfElements(ThisObject);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DescriptionOfDelayedStartOfExecutionClick(Item, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DescriptionOfDelayedStartOfClickAction(
		ThisObject,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure GeneratesVisasOnChange(Item)
	
	If Not GeneratesVisas Then
		SignWithDS = False;
	EndIf;
	
	Items.SignWithDS.Enabled = GeneratesVisas;
	
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
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeDeletion(ThisObject, Cancel, True, True);
	
EndProcedure

&AtClient
Procedure AttendeesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	ParametersForAddingParticipantsToAction = IntegrationWith1CDocumentManagement3Client.ParametersForAddingParticipantsToAction();
	ParametersForAddingParticipantsToAction.WithStages = True;
	ParametersForAddingParticipantsToAction.ChildPerformersArePossible = False;
	ParametersForAddingParticipantsToAction.YouCanAddStages = True;
	ParametersForAddingParticipantsToAction.YouCanOnlyAddMembers = YouCanOnlyAddMembers;
	ParametersForAddingParticipantsToAction.ParticipantFunction = "ApprovingPerson";
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeAdding(
		ThisObject,
		Cancel,
		Copy,
		ParametersForAddingParticipantsToAction);
	
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined And ThisIsDialogWithSavingResults Then
		CurrentData.Result = "";
		CurrentData.DirectToNewCycle = True;
		SetUpDisplayOfRepeatLineWhileSavingResults(CurrentData);
		CurrentData.YouCanSaveResult = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AttendeesBeforeRowChange(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeStartOfChange(ThisObject, Cancel);
	
EndProcedure

&AtClient
Procedure AttendeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Attendees.FindByID(RowSelected);
	If CurrentData <> Undefined Then
		OpenSpecialNameAndDescription = Not CurrentData.ThisIsAStep
			And (CurrentData.Function <> "ApprovalResultProcessor");
		OnlyViewingSpecialNameAndDescription = ReadOnly Or CurrentData.Unavailable;
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
Procedure ParticipantsSendPresentationOnChange(Item)
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Variants = RepeatTextOptions();
	
	If CurrentData.AimForNewCyclePresentation = Variants.DoNotDirect
			And ResultOfAgreementCanBeSaved(CurrentData.Result) Then
		CurrentData.DirectToNewCycle = False;
	Else
		CurrentData.DirectToNewCycle = True;
	EndIf;
	
	SetUpDisplayOfRepeatLineWhileSavingResults(CurrentData);
	
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
Procedure OrderOnChange(Item)
	
	IntegrationWith1CDocumentManagement3Client.ProcedureForPerformingActionByParticipantsWhenChanging(ThisObject);
	
EndProcedure

&AtClient
Procedure OrderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.OrderOfExecutionOfActionByParticipantsProcessingSelection(
		ThisObject,
		ValueSelected,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure DueDatePresentationOnChange(Item)
	
	IntegrationWith1CDocumentManagement3Client.DeadlineForExecutionOfActionByParticipantInCaseOfChange(
		ThisObject,
		Not Items.AttendeesDifferentTerms.Check);
	
EndProcedure

&AtClient
Procedure DueDatePresentationTuning(Item, Direction, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DurationOfActionByParticipantIsRegulation(
		ThisObject,
		Direction,
		StandardProcessing,
		Not Items.AttendeesDifferentTerms.Check);
	
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
	Items.CoordinationInCommentsMode.Enabled = False;
	Items.WriteAndClose.Visible = True;
	Items.WriteAndClose.DefaultButton = True;
	SetAvailabilityOfMemberChanges();
	SetFormItemEnabled();
	
	// Immediately add a new line.
	For Each Stage In Attendees.GetItems() Do
		If Stage.Function <> "ApprovingPerson" Or Stage.Unavailable Then
			Continue;
		EndIf;
		ParticipantLine = Stage.GetItems().Add();
		ParticipantLine.LinePresentation =
			IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(ParticipantLine);
		ParticipantLine.Function = Stage.Function;
		Items.Attendees.CurrentRow = ParticipantLine.GetID();
		Break;
	EndDo;
	
	Items.SendToNewMembers.Visible = False;
	Modified = True;
	
	ShowMessageBox(,
		NStr("vi = 'Kết quả người tham gia mới không ảnh hưởng đến kết quả thao tác và lộ trình xử lý, bởi vì đã thống nhất.';
			|ru = 'Результаты новых участников не повлияют на результат действия и маршрут обработки, т.к. согласование уже пройдено.';
			|en = 'The results of new participants will not affect the action result and the route processing as the approval is already completed.'; fa = 'The results of new participants will not affect the action result and the route processing as the approval is already completed.';
			|it = 'Результаты новых участников не повлияют на результат действия и маршрут обработки, т.к. согласование уже пройдено.';
			|pl = 'The results of new participants will not affect the action result and the route processing as the approval is already completed.';
			|tr = 'Yeni katılımcıların sonuçları, mutabakat zaten gerçekleşmiş olduğu için eylemin sonucunu ve işleme rotasını etkilemeyecektir.'"));
	
EndProcedure

&AtClient
Procedure MoveUp(Command)
	
	IntegrationWith1CDocumentManagement3Client.MoveParticipantOfActionUp(ThisObject);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	IntegrationWith1CDocumentManagement3Client.MoveParticipantOfActionDown(ThisObject);
	
EndProcedure

&AtClient
Procedure IsProtected(Command)
	
	IntegrationWith1CDocumentManagement3Client.ChangeProtectedActionParticipantAttribute(ThisObject);
	
EndProcedure

&AtClient
Procedure DifferentTerms(Command)
	
	Items.AttendeesDifferentTerms.Check = Not Items.AttendeesDifferentTerms.Check;
	IntegrationWith1CDocumentManagement3Client.SetSameExpirationDateRecursively(
		Attendees.GetItems(),
		ThisObject);
	
EndProcedure

&AtClient
Procedure AddStage(Command)
	
	IntegrationWith1CDocumentManagement3Client.AddActionStep(ThisObject, "ApprovingPerson");
	
EndProcedure

&AtClient
Procedure RepeatApprovalForAll(Command)
	
	ParticipantLines = LinesOfParticipantsInApprovalForm(ThisObject);
	
	For Each String In ParticipantLines Do
		
		If Not ThisIsMatchingString(String) Then
			Continue;
		EndIf;
		
		String.DirectToNewCycle = True;
		SetUpDisplayOfRepeatLineWhileSavingResults(String);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RepeatApprovalOnlyForThoseWhoDisagree(Command)
	
	ParticipantLines = LinesOfParticipantsInApprovalForm(ThisObject);
	
	For Each String In ParticipantLines Do
		
		If Not ThisIsMatchingString(String) Then
			Continue;
		EndIf;
		
		If Not ResultOfAgreementCanBeSaved(String.Result) Then
			String.DirectToNewCycle = True;
		Else
			String.DirectToNewCycle = False;
		EndIf;
		
		SetUpDisplayOfRepeatLineWhileSavingResults(String);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region Client

// Fills in the Presentation of deadlines in the action card.
//
&AtClient
Procedure FillInPresentationOfDeadlines() Export
	
	For Each ParticipantsStage In Attendees.GetItems() Do
		
		If ParticipantsStage.TermIsGeneral Then
			ParticipantsStage.DueDatePresentation =
				IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
					ParticipantsStage.DueDate,
					ParticipantsStage.Term_Days,
					ParticipantsStage.TermHours,
					ParticipantsStage.TermMinutes,
					UseDateAndTimeInTaskDeadlines,
					ParticipantsStage.OptionForSettingDeadline);
		Else
			ParticipantsStage.DueDatePresentation = "";
		EndIf;
		
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
	
	CurrentParent = CurrentData.GetParent();
	If CurrentParent = Undefined Then
		ParentItems1 = Attendees.GetItems();
		ParentIsUnavailable = Not ReadOnly;
	Else
		ParentItems1 = CurrentParent.GetItems();
		ParentIsUnavailable = CurrentParent.Unavailable;
	EndIf;
	IndexOf = ParentItems1.IndexOf(CurrentData);
	
	ThisIsFirstElement = (IndexOf = 0);
	IsLastItem = (IndexOf = ParentItems1.Count() - 1);
	
	PreviousOneIsAvailable = False;
	If Not ThisIsFirstElement Then
		PreviousItem = ParentItems1.Get(IndexOf - 1);
		PreviousOneIsAvailable = Not PreviousItem.Unavailable;
	EndIf;
	
	FollowingIsAvailable = False;
	If Not IsLastItem Then
		NextItem = ParentItems1.Get(IndexOf + 1);
		FollowingIsAvailable = Not NextItem.Unavailable;
	EndIf;
	
	If CurrentData.Function = "ApprovalResultProcessor" Then
		
		LineViewOnly = CurrentData.ThisIsAStep Or CurrentData.Unavailable;
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.LinePresentation.ChoiceButton = True;
		Items.Order.ReadOnly = True;
		Items.DueDatePresentation.ReadOnly = LineViewOnly;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		
		Items.Add.Enabled = False;
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
		Items.Delete.Enabled = Not LineViewOnly;
		
	ElsIf CurrentData.ThisIsAStep Then
		
		Items.LinePresentation.ReadOnly = CurrentData.Unavailable
			Or ExecutionOfActionWithNewParticipants;
		Items.LinePresentation.ChoiceButton = False;
		Items.DueDatePresentation.ReadOnly = True;
		Items.ThereIsSpecialNameDescription.ReadOnly = True;
		Items.LongDesc.ReadOnly = True;
		Items.Order.ReadOnly = CurrentData.Unavailable
			Or ExecutionOfActionWithNewParticipants
			Or ValueIsFilled(CurrentData.State);
		
		Items.Add.Enabled = Not CurrentData.Unavailable Or CurrentData.AllowedToAdd;
		
		Items.MoveUp.Enabled = Not ThisIsFirstElement
			And Not ExecutionOfActionWithNewParticipants
			And CurrentData.CanBeMovedUp;
		Items.MoveDown.Enabled = Not IsLastItem
			And Not ExecutionOfActionWithNewParticipants
			And CurrentData.CanBeMovedDown;
		Items.Delete.Enabled = Not CurrentData.Unavailable
			And (Not ValueIsFilled(SettingOfActionID) Or Not CurrentData.FromSettings)
			And Not ExecutionOfActionWithNewParticipants;
		
	Else
		
		// The matching one.
		LineViewOnly = ParentIsUnavailable And Not CurrentData.AllowedToAdd Or CurrentData.Unavailable;
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.LinePresentation.ChoiceButton = True;
		Items.DueDatePresentation.ReadOnly = LineViewOnly
			Or YouCanOnlyAddMembers
				And Not ThisIsFirstElement
				And (CurrentParent.Order = "AllAtOnce");
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		Items.Order.ReadOnly = True;
		
		Items.Add.Enabled = Not ParentIsUnavailable Or CurrentData.AllowedToAdd;
		
		Items.MoveUp.Enabled = Not ThisIsFirstElement
			And Not LineViewOnly
			And PreviousOneIsAvailable
			And CurrentData.CanBeMovedUp;
		Items.MoveDown.Enabled = Not IsLastItem
			And Not LineViewOnly
			And FollowingIsAvailable
			And CurrentData.CanBeMovedDown;
		Items.Delete.Enabled = Not LineViewOnly;
		
	EndIf;
	
	Items.AddContext.Enabled = Items.Add.Enabled;
	Items.DeleteContext.Enabled = Items.Delete.Enabled;
	
	Items.AttendeesAddStage.Enabled = Not ValueIsFilled(SettingOfActionID)
		And Not ExecutionOfActionWithNewParticipants Or YouCanOnlyAddMembers Or YouCanAddParticipants;
	
	Items.ContextAddStage.Enabled = Items.AttendeesAddStage.Enabled;
	
EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Procedure SetVisibilityAccessibilityOfGroupOfFlagSettings(Form)
	
	Items = Form.Items;
	
	SettingUpAction = ValueIsFilled(Form.SettingOfActionID);
	If SettingUpAction Then
		Items.FlagSettingsGroup.Visible = False;
		Return;
	EndIf;
	
	If Form.DialogMode Then
		Items.FlagSettingsGroup.Enabled = False;
		Items.FlagSettingsGroup.Visible = False;
		Return;
	EndIf;
	
	If ValueIsFilled(Form.StateOfAction) Then
		Items.FlagSettingsGroup.Enabled = False;
		Return;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityOfDeferredExecutionGroup(Form)
	
	Items = Form.Items;
	
	If Form.DialogMode Then
		Items.GroupDescriptionOfDeferredExecution.Enabled = False;
		Items.GroupDescriptionOfDeferredExecution.Visible = False;
		Return;
	EndIf;
	
	If ValueIsFilled(Form.StateOfAction) Then
		Items.GroupDescriptionOfDeferredExecution.Enabled = False;
		Return;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityOfSavingResults(Form)
	
	Items = Form.Items;
	
	SettingUpAction = ValueIsFilled(Form.SettingOfActionID);
	If SettingUpAction Then
		Items.AllowToSaveResults.Visible = False;
		Return;
	EndIf;
	
	If Form.DialogMode Then
		Items.AllowToSaveResults.Enabled = False;
		Items.AllowToSaveResults.Visible = False;
		Return;
	EndIf;
	
	If ValueIsFilled(Form.StateOfAction) Then
		Items.AllowToSaveResults.Enabled = False;
		Return;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAccessibilityOfElements(Form)
	
	SetVisibilityAvailabilityOfCycleRestrictionItems(Form);
	SetVisibilityAvailabilityOfSavingResults(Form);
	SetVisibilityAccessibilityOfGroupOfFlagSettings(Form);
	SetVisibilityAvailabilityOfDeferredExecutionGroup(Form);
	
	Form.Items.SignWithDS.Enabled = Form.GeneratesVisas;
	If ValueIsFilled(Form.MainSubjectID)
			And Form.MainSubjectType = "DMMeeting" Then
		Form.CoordinationInCommentsMode = False;
		Form.Items.CoordinationInCommentsMode.Visible = False;
		Form.Items.GeneratesVisas.Visible = False;
		Form.Items.GroupSignItemInstances.Visible = False;
	EndIf;
	
	Form.Items.CoordinationInCommentsMode.Enabled =
		Not Form.ExecutionOfActionWithNewParticipants
		And Not Form.Items.SendToNewMembers.Visible;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityOfCycleRestrictionItems(Form)
	
	If Form.DialogMode Or Not Form.FunctionalityOfSettingCyclesAndContinuationsIsAvailable Then
		Form.Items.GroupLimitationOfApprovalCycles.Visible = False;
		Form.Items.ContinueProcessingIfResultIsNegative.Visible = False;
		Return;
	EndIf;
	
	Form.Items.GroupLimitationOfApprovalCycles.Visible = True;
	Form.Items.ContinueProcessingIfResultIsNegative.Visible = True;
	
	Form.Items.LimitMatchingCycles.Enabled = False;
	Form.Items.MaximumNumberOfCycles.Enabled = False;
	Form.Items.ContinueProcessingIfResultIsNegative.Enabled = False;
	
	If Not Form.ChangingActionIsAllowed Then
		Return;
	EndIf;
	
	ItIsForbiddenToChangeBySetting = ValueIsFilled(Form.SettingOfActionID) And Not Form.ThereIsRightOfArbitration;
	
	If ItIsForbiddenToChangeBySetting Then
		Return;
	EndIf;
	
	ActionStartExecution = ValueIsFilled(Form.StateOfAction);
	If ActionStartExecution And Not Form.ThereIsRightOfArbitration Then
		Return;
	EndIf;
	
	Form.Items.LimitMatchingCycles.Enabled = True;
	Form.Items.ContinueProcessingIfResultIsNegative.Enabled = True;
	
	If Not Form.LimitMatchingCycles Then
		Return;
	EndIf;
	
	Form.Items.MaximumNumberOfCycles.Enabled = True;
	Form.Items.MaximumNumberOfCycles.Title =
		StringFunctionsClientServer.StringWithNumberForAnyLanguage(
			NStr("ru = ';циклом;;циклами;циклами;циклами';
				|vi = ';cycle;;;;cycle';
				|en = ';cycle;;;;cycle'; fa = ';cycle;;;;cycle';
				|it = ';cycle;;;;cycle';
				|pl = ';cycle;;;;cycle';
				|tr = ';döngüyle;;döngülerle;döngülerle;döngülerle'"),
			Form.MaximumNumberOfCycles);
	
EndProcedure

#EndRegion

#Region Server

// Fills in the tree of participants by object.
//
&AtServer
Procedure UpdateTreeOfParticipantsByObject(XDTOAction)
	
	StagesOfParticipants = Attendees.GetItems();
	StagesOfParticipants.Clear();
	
	Stages = XDTOAction.stageRows.rows;
	If Stages.Count() Then
		// We add all stages to the table of participants.
		For Each StageString_ In Stages Do
			ParticipantsStage = StagesOfParticipants.Add();
			IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(ParticipantsStage, StageString_);
			ParticipantsStage.Function = "ApprovingPerson";
			ParticipantsStage.StageName = StageString_.stageDescription;
			ParticipantsStage.ThisIsAStep = True;
			ParticipantsStage.Order = StageString_.orderOfExecutionByParticipants;
		EndDo;
	Else
		ParticipantsStage = StagesOfParticipants.Add();
		ParticipantsStage.Function = "ApprovingPerson";
		ParticipantsStage.StageName = NStr("vi = 'Thống nhất';
											|ru = 'Согласовать';
											|en = 'Approve'; fa = 'تأیید';
											|it = 'Согласовать';
											|pl = 'Approve';
											|tr = 'Onayla'");
		ParticipantsStage.ThisIsAStep = True;
		ParticipantsStage.Id = IdOfAgreeStage;
		If ValueIsFilled(XDTOAction.orderOfExecutionByParticipants) Then
			ParticipantsStage.Order = XDTOAction.orderOfExecutionByParticipants;
		Else
			ParticipantsStage.Order = "AllAtOnce";
		EndIf;
	EndIf;
	
	// Adding the result processor.
	ParticipantsStage = StagesOfParticipants.Add();
	ParticipantsStage.Function = "ApprovalResultProcessor";
	ParticipantsStage.Order = "OneByOne";
	ParticipantsStage.StageName = NStr("vi = 'Tham khảo với kết quả thống nhất';
										|ru = 'Ознакомиться с результатом согласования';
										|en = 'Review the approval result'; fa = 'Review the approval result';
										|it = 'Ознакомиться с результатом согласования';
										|pl = 'Review the approval result';
										|tr = 'Mutabakat sonucunu incele'");
	ParticipantsStage.ThisIsAStep = True;
	ParticipantsStage.Id = IdOfPersonProcessingResult;
	
	ParticipantsOfAction = XDTOAction.participantRows.rows;
	
	// We add all stages to the table of participants.
	For Each StageString_ In StagesOfParticipants Do
		ParticipantsOfStage = StageString_.GetItems();
		
		If StageString_.Id <> IdOfPersonProcessingResult Then
			
			For Each Member In ParticipantsOfAction Do
				
				If (IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(Member.stageID)
							And Member.stageID <> StageString_.Id)
						Or (Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(Member.stageID)
							And Member.participantFunction <> StageString_.Function) Then
					Continue;
				EndIf;
				
				StageParticipant = ParticipantsOfStage.Add();
				IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
				StageParticipant.Function = Member.participantFunction;
				UpdateFieldHasSpecialNameDescription(StageParticipant);
				
			EndDo;
			
		Else
			
			// Familiarization.
			ParticipantProcessingResult = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(
				ParticipantsOfAction,
				"ApprovalResultProcessor");
			If ParticipantProcessingResult.Count() > 0 Then
				For Each Member In ParticipantProcessingResult Do
					StageParticipant = ParticipantsOfStage.Add();
					IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
					StageParticipant.Function = "ApprovalResultProcessor";
				EndDo;
			Else
				StageParticipant = ParticipantsOfStage.Add();
				IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
					StageParticipant,
					XDTOAction.author,
					"Member",
					True);
				StageParticipant.Function = StageString_.Function;
				StageParticipant.Id = StageString_.Id;
			EndIf;
			
		EndIf;
		
		If ParticipantsOfStage.Count() = 0 Then
			StageParticipant = ParticipantsOfStage.Add();
			StageParticipant.Id = StageString_.Id;
			StageParticipant.Function = StageString_.Function;
		EndIf;
	EndDo;
	
	ThereAreStages = IntegrationWith1CDocumentManagement3ClientServer.ThereAreStagesOfAction(
		Attendees,
		IdOfAgreeStage,
		IdOfPersonProcessingResult);
	
	UpdatePresentationsInParticipantTree(Attendees);
	Commands.DifferentTerms.ToolTip = IntegrationWith1CDocumentManagement3.HintButtonsHaveDifferentExpirationDates(False, ThereAreStages);
	
EndProcedure

&AtServer
Procedure UpdateObjectInMemberTree(Proxy, XDTOAction)
	
	XDTOAction.participantRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionApprovalParticipantRows");
	XDTOMembers = XDTOAction.participantRows.rows; // XDTOList
	XDTOAction.stageRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionStageRows");
	StagesOfXDTO = XDTOAction.stageRows.rows; // XDTOList
	
	ThereAreStages = False;
	ThereArePerformingParticipants = False;
	ThereIsProcessingResult = False;
	
	// We write the stages only entered by hand.
	ElementsStages = Attendees.GetItems();
	For Each ElementStage In ElementsStages Do
		If ElementStage.Id = IdOfAgreeStage Then
			XDTOAction.orderOfExecutionByParticipants = ElementStage.Order;
		EndIf;
		If ElementStage.Id = IdOfAgreeStage
				Or ElementStage.Id = IdOfPersonProcessingResult Then
			Continue;
		EndIf;
		ThereAreStages = True;
		Break;
	EndDo;
	
	For Each ElementStage In ElementsStages Do
		
		StageID = Undefined;
		
		If ThereAreStages And ElementStage.Id <> IdOfPersonProcessingResult Then
			// For the standard stage, we change the ID if others are set.
			If ElementStage.Id = IdOfAgreeStage Then
				ElementStage.Id = String(New UUID);
			EndIf;
			
			XDTOStage = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionStageRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOStage, ElementStage);
			XDTOStage.stageDescription = ElementStage.StageName;
			XDTOStage.orderOfExecutionByParticipants = ElementStage.Order;
			StagesOfXDTO.Add(XDTOStage);
			StageID = ElementStage.Id;
		EndIf;
		
		For Each MemberElement In ElementStage.GetItems() Do
			
			If Not ValueIsFilled(MemberElement.MemberID) Then
				Continue;
			EndIf;
			
			If ElementStage.Function = "ApprovingPerson" Then
				For Each XDTORow In XDTOMembers Do
					If MemberElement.MemberID = XDTORow.participant.objectID.id
							And MemberElement.MemberType = XDTORow.participant.objectID.type
							And MemberElement.TaskDescription = XDTORow.taskDescription
							And MemberElement.LongDesc = XDTORow.description
							And ((MemberElement.IsProtected = True And XDTORow.protected = False)
								Or MemberElement.IsProtected = False) Then
						Raise StrTemplate(
							NStr("vi = 'Trong các giai đoạn thống nhất lặp lại người thống nhất: %1.
								|Hãy xóa bản trùng lặp, hãy chỉ ra bản mô tả đặc biệt hoặc thiết lập dấu hiệu ""Được bảo mật"" cho người thống nhất';
								|ru = 'В этапах согласования повторяется согласующий: %1.
								|Удалите дубли, укажите особое описание или установите согласующему признак ""Защищенный""';
								|en = 'In the approval stages, the %1 approver is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the approver'; fa = 'In the approval stages, the %1 approver is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the approver';
								|it = 'В этапах согласования повторяется согласующий: %1.
								|Удалите дубли, укажите особое описание или установите согласующему признак ""Защищенный""';
								|pl = 'In the approval stages, the %1 approver is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the approver';
								|tr = 'Mutabakat aşamalarında tekrarlanan onaylayan: %1.
								|Tekrarlananları silin, özel açıklama belirtin veya onaylayanı ""Korumalı"" olarak yapılandırın'"),
							MemberElement.MemberPresentation);
					EndIf;
				EndDo;
			EndIf;
			
			XDTOMember = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionApprovalParticipantRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOMember, MemberElement);
			If ValueIsFilled(StageID) Then
				XDTOMember.stageID = StageID;
			EndIf;
			
			If AllowToSaveResults
					And IntegrationWith1CDocumentManagementCore.PropertyExists(XDTOMember, "saveResult")
					And ThisIsMatchingString(MemberElement) Then
				XDTOMember.saveResult = Not MemberElement.DirectToNewCycle;
			EndIf;
			
			XDTOMember.participantFunction = MemberElement.Function;
			XDTOMembers.Add(XDTOMember);
			
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
		StagesOfXDTO.Clear();
	ElsIf Not ThereIsProcessingResult Then
		Raise NStr("vi = 'Không có người tham gia ""tham khảo với kết quả thống nhất""';
					|ru = 'Отсутствует участник ""ознакомления с результатом согласования""';
					|en = 'The ""Approval result review"" participant is missing'; fa = 'The ""Approval result review"" participant is missing';
					|it = 'Отсутствует участник ""ознакомления с результатом согласования""';
					|pl = 'The ""Approval result review"" participant is missing';
					|tr = '""Mutabakat sonucunun incelenmesi"" katılımcısı yok'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFieldHasSpecialNameDescription(String)
	
	If String = Undefined Then
		Return;
	EndIf;
	
	String.ThereIsSpecialNameDescription = ValueIsFilled(String.TaskDescription)
		Or ValueIsFilled(String.LongDesc);
	
EndProcedure

// Updates Presentations of rows in the participant tree.
//
// Parameters:
//   Attendees - FormDataTree - a tree with participants.
//
&AtClientAtServerNoContext
Procedure UpdatePresentationsInParticipantTree(Attendees)
	
	StagesOfParticipants = Attendees.GetItems();
	
	For IndexOfStage = 0 To StagesOfParticipants.Count() - 1 Do
		
		StageString_ = StagesOfParticipants.Get(IndexOfStage);
		StageString_.RowPrefix = "";
		StageString_.LinePresentation = StageString_.StageName;
		StageString_.OrderPresentation =
			IntegrationWith1CDocumentManagement3ClientServer.PresentationOfOrderOfExecutionOfActionStep(StageString_.Order);
		
		ParticipantsOfStage = StageString_.GetItems();
		
		For IndexOfParticipant = 0 To ParticipantsOfStage.Count() - 1 Do
			ParticipantLine = ParticipantsOfStage[IndexOfParticipant];
			
			ParticipantLine.RowPrefix = "";
			ParticipantLine.LinePresentation =
				IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(ParticipantLine);
			ParticipantLine.OrderPresentation =
				IntegrationWith1CDocumentManagement3ClientServer.PresentationOfOrderOfExecutionOfActionStep(ParticipantLine.Order);
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingAction(XDTOAction)
	
	// Fill in the general action data.
	IntegrationWith1CDocumentManagement3.ProcessWebServiceSResponseToReceivingAction(ThisObject, XDTOAction);
	
	// Fill in these approval actions.
	IdOfAgreeStage = XDTOAction.stageApprovalID;
	IdOfPersonProcessingResult = XDTOAction.resultProcessorID;
	CoordinationInCommentsMode = XDTOAction.approvalInTheRemarksMode;
	ExecutionOfActionWithNewParticipants =
		Not CoordinationInCommentsMode
		And XDTOAction.actionPerformedWithNewParticipants;
	GeneratesVisas = XDTOAction.makeEndorsementsOfApproval;
	SignWithDS = XDTOAction.signWithDS;
	ChangingActionIsAllowed = XDTOAction.changeAllowed;
	LibreOfficePythonIsEnabled = False;
	StateOfAction = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "state") Then
		StateOfAction = XDTOAction.state;
	EndIf;
	If FunctionalityOfSettingCyclesAndContinuationsIsAvailable Then
		ContinueProcessingIfResultIsNegative = XDTOAction.continueProcessingIfResultIsNegative;
	EndIf;
	FillInAttributesOfRestrictionOfCyclesOfFormForObject(XDTOAction);
	
	// Update the action form.
	UpdateTreeOfParticipantsByObject(XDTOAction);
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfConditionsOfParticipantsInAction(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInStatesAndResultsInActionForm(ThisObject, XDTOAction);
	SetAvailabilityOfMemberChanges();
	
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfDirectionToNewParticipantsOfAction(
		ThisObject,
		StateOfAction,
		XDTOAction.permissionRows.rows);
	
	SetVisibilityAccessibilityOfElements(ThisObject);
	
	SetUpRepeatFormWithResultsSaved(XDTOAction);
	
	SetConditionalAppearance();
	
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
	XDTOAction.approvalInTheRemarksMode = CoordinationInCommentsMode;
	XDTOAction.makeEndorsementsOfApproval = GeneratesVisas;
	XDTOAction.signWithDS = SignWithDS;
	If IntegrationWith1CDocumentManagementCore.PropertyExists(XDTOAction, "allowSavingResults") Then
		XDTOAction.allowSavingResults = AllowToSaveResults;
	EndIf;
	UpdateObjectInMemberTree(Proxy, XDTOAction);
	If FunctionalityOfSettingCyclesAndContinuationsIsAvailable Then
		XDTOAction.continueProcessingIfResultIsNegative = ContinueProcessingIfResultIsNegative;
	EndIf;
	FillInRestrictionOfObjectCyclesByAttributesOfForm(XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInTableOfParticipantsInAction(ThisObject.AttendeesBeforeWrite, XDTOAction);
	
	Return IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, XDTOAction);
	
EndFunction

&AtServer
Procedure SetAvailabilityOfMemberChanges()
	
	If ReadOnly = True Then
		Return;
	EndIf;
	
	GeneralResolution = Undefined;
	PermissionsFound = Permissions.FindRows(
		New Structure("StageID", "00000000-0000-0000-0000-000000000000"));
	If PermissionsFound.Count() > 0 Then
		GeneralResolution = PermissionsFound[0].Resolution;
	EndIf;
	
	If GeneralResolution = "Forbidden" Or GeneralResolution = "AllowedToAdd" Then
		Items.Author.Enabled = False;
		Items.GroupDescriptionOfDeferredExecution.Enabled = False;
	EndIf;
	
	If GeneralResolution = "AllowedToAdd" Then
		YouCanOnlyAddMembers = True;
	EndIf;
	
	If GeneralResolution = "Allowed" Then
		YouCanAddParticipants = True;
	EndIf;
	
	StagesOfParticipants = Attendees.GetItems();
	For Each ParticipantsStage In StagesOfParticipants Do
		StageResolution = GeneralResolution;
		If ParticipantsStage.Id <> IdOfAgreeStage Then
			PermissionsFound = Permissions.FindRows(
				New Structure("StageID", ParticipantsStage.Id));
			If PermissionsFound.Count() > 0 Then
				StageResolution = PermissionsFound[0].Resolution;
			EndIf;
		EndIf;
		
		ParticipantsStage.Unavailable =
			StageResolution = "Forbidden"
			Or StageResolution = "AllowedToAdd"
			// We forbid editing completed stages.
			Or (ParticipantsStage.State = "Completed"
				And Not ExecutionOfActionWithNewParticipants);
		ParticipantsStage.AllowedToAdd = (StageResolution = "AllowedToAdd");
		
		ParticipantsOfStage = ParticipantsStage.GetItems();
		For Each StageParticipant In ParticipantsOfStage Do
			StageParticipant.Unavailable =
				ParticipantsStage.Unavailable And ValueIsFilled(StageParticipant.MemberID)
				Or StageParticipant.State = "Completed";
			StageParticipant.AllowedToAdd = ParticipantsStage.AllowedToAdd;
		EndDo;
	EndDo;
	
EndProcedure

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
		IntegrationWith1CDocumentManagement3Client.FillInAvailabilityOfMovingStagesOfParticipantsOfAction(Attendees, True);
		IntegrationWith1CDocumentManagement3Client.MarkButtonsWithDifferentExpirationDatesRecursively(
			Attendees.GetItems(),
			Items.AttendeesDifferentTerms);
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
	
	If Not IntegrationWith1CDocumentManagement3Client.StagesOfActionAreUnique(Attendees) Then
		Cancel = True;
		Return;
	EndIf;
	
	If ExecutionOfActionWithNewParticipants
			And Not IntegrationWith1CDocumentManagement3ClientServer.ParticipantsOfActionHaveBeenChangedInCard(ThisObject) Then
		ShowMessageBox(,
			NStr("vi = 'Chưa thêm người tham gia mới.
				|Để khởi động việc thống nhất mới, hãy thêm người tham gia.';
				|ru = 'Новые участники не добавлены.
				|Для запуска нового согласования добавьте участников.';
				|en = 'New participants are not added.
				|To start a new approval, add participants.'; fa = 'New participants are not added.
				|To start a new approval, add participants.';
				|it = 'Новые участники не добавлены.
				|Для запуска нового согласования добавьте участников.';
				|pl = 'New participants are not added.
				|To start a new approval, add participants.';
				|tr = 'Yeni katılımcılar eklenmedi.
				|Yeni mutabakat başlatmak için katılımcı ekleyin.'"));
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
			
			If Not QuestionWasAskedAboutSavingResults() Then
				Close(DialogReturnCode.OK);
			EndIf;
			
		Else
			
			Close(DialogReturnCode.Cancel);
			
		EndIf;
		
		Return;
		
	EndIf;
	
	StartRecordingActionInWorkflow();
	
EndProcedure

&AtClient
Procedure StartRecordingActionInWorkflow()
	
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

#Region LimitingCycleLimit

&AtServer
Procedure FillInRestrictionOfObjectCyclesByAttributesOfForm(XDTOAction)
	
	If Not FunctionalityOfSettingCyclesAndContinuationsIsAvailable Then
		Return;
	EndIf;
	
	If Not LimitMatchingCycles Or MaximumNumberOfCycles = 0 Then
		XDTOAction.maximumNumberOfCycles = 0;
		Return;
	EndIf;
	
	XDTOAction.maximumNumberOfCycles = MaximumNumberOfCycles;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfRestrictionOfCyclesOfFormForObject(XDTOAction)
	
	ThereIsRightOfArbitration = False;
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			XDTOAction, "haveArbitrationRight") Then
		ThereIsRightOfArbitration = XDTOAction.haveArbitrationRight;
	EndIf;
	
	LimitMatchingCycles = False;
	MaximumNumberOfCycles = 0;
	
	If Not FunctionalityOfSettingCyclesAndContinuationsIsAvailable Or XDTOAction.maximumNumberOfCycles = 0 Then
		Return;
	EndIf;
	
	LimitMatchingCycles = True;
	MaximumNumberOfCycles = XDTOAction.maximumNumberOfCycles;
	
EndProcedure

// Sets the visibility and accessibility of Form elements by limiting cycles.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ApprovalAction
//
&AtClientAtServerNoContext
Procedure EnsureConsistencyOfAttributesOfCycleRestrictions(Form)
	
	If Not Form.LimitMatchingCycles Then
		Form.MaximumNumberOfCycles = 0;
		Return;
	EndIf;
	
	If Form.MaximumNumberOfCycles < 1 Then
		Form.MaximumNumberOfCycles = 3;
	EndIf;
	
EndProcedure

#EndRegion

#Region CoordinationWithAbilityToSaveResults

#Region QuestionIsRepeatedOnlyToDissenters

&AtClient
Function AnswersToQuestionAboutSavingResults()
	
	Variants = New Structure;
	Variants.Insert("OK", "OK");
	Variants.Insert("Cancel", "Cancel");
	
	Return Variants;
	EndFunction

&AtClient
Function QuestionWasAskedAboutSavingResults()
	
	If Not ThisIsDialogWithSavingResults Then
		Return False;
	EndIf;
	
	Number_Participants = NumberOfParticipantsToRepeat();
	If Number_Participants.TotalNumberOfConcordants = Number_Participants.AimForNewCycle Then
		Return False;
	EndIf;
	
	SettingsParameters = SettingsForQuestionAboutSavingResults();
	ShowQuestion = CommonServerCall.CommonSettingsStorageLoad(
		SettingsParameters.ObjectKey,
		SettingsParameters.SettingsKey,
		True);
	
	If ShowQuestion Then
		
		Variants = AnswersToQuestionAboutSavingResults();
		
		VariantList = New ValueList;
		VariantList.Add(Variants.OK, NStr("ru = 'ОК';
											|vi = 'OK';
											|en = 'OK'; fa = 'تأیید';
											|it = 'OK';
											|pl = 'OK';
											|tr = 'Tamam'"));
		VariantList.Add(Variants.Cancel, NStr("ru = 'Отмена';
												|vi = 'Cancel';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Cancel';
												|pl = 'Cancel';
												|tr = 'İptal'"));
		
		QuestionToUserParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionToUserParameters.Title = NStr("ru = 'Сохранение результатов';
												|vi = 'Saving results';
												|en = 'Saving results'; fa = 'Saving results';
												|it = 'Saving results';
												|pl = 'Saving results';
												|tr = 'Sonuçların kaydedilmesi'");
		
		QueryText = StrTemplate(
			NStr("ru = 'Вы направляете документ на частичное повторное согласование:
				|• %1 документ на согласование, %2 будут взяты из предыдущего цикла.
				|• %3 документ на согласование.
				|
				|Направить документ только части согласующих?';
				|vi = 'You are sending the document for partial re-approval:
				|• %1 document for approval, %2 will be taken from the previous cycle.
				|• %3 document for approval.
				|
				|Send the document only to part of the approvers?';
				|en = 'You are sending the document for partial re-approval:
				|• %1 document for approval, %2 will be taken from the previous cycle.
				|• %3 document for approval.
				|
				|Send the document only to part of the approvers?'; fa = 'You are sending the document for partial re-approval:
				|• %1 document for approval, %2 will be taken from the previous cycle.
				|• %3 document for approval.
				|
				|Send the document only to part of the approvers?';
				|it = 'You are sending the document for partial re-approval:
				|• %1 document for approval, %2 will be taken from the previous cycle.
				|• %3 document for approval.
				|
				|Send the document only to part of the approvers?';
				|pl = 'You are sending the document for partial re-approval:
				|• %1 document for approval, %2 will be taken from the previous cycle.
				|• %3 document for approval.
				|
				|Send the document only to part of the approvers?';
				|tr = 'Belgeyi kısmen yeniden onaya gönderiyorsunuz:
				| •  %1 onay belgesi, %2 önceki döngüden alınacaktır. 
				|• %3 onay belgesi.
				|
				|Belge yalnızca onaylayanların bir kısmına gönderilsin mi?'"),
			StringFunctionsClientServer.StringWithNumberForAnyLanguage(
				NStr("ru = ';%1 участник не получит;;%1 участника не получат;%1 участников не получат;%1 участника не получат';
					|vi = ';%1 participant will not receive;;;;%1 participants will not receive';
					|en = ';%1 participant will not receive;;;;%1 participants will not receive'; fa = ';%1 participant will not receive;;;;%1 participants will not receive';
					|it = ';%1 participant will not receive;;;;%1 participants will not receive';
					|pl = ';%1 participant will not receive;;;;%1 participants will not receive';
					|tr = ';%1 katılımcı almayacak;; %1 katılımcı almayacak; %1katılımcı almayacak; %1 katılımcı almayacak'"),
					Number_Participants.SavedResults),
			?(Number_Participants.SavedResults > 1, NStr("ru = 'их результаты';
														|vi = 'their results';
														|en = 'their results'; fa = 'their results';
														|it = 'their results';
														|pl = 'their results';
														|tr = 'onların sonuçları'"), NStr("ru = 'его результат';
																						|vi = 'their result';
																						|en = 'their result'; fa = 'their result';
																						|it = 'their result';
																						|pl = 'their result';
																						|tr = 'onun sonucu'")),
			StringFunctionsClientServer.StringWithNumberForAnyLanguage(
				NStr("ru = ';%1 участник получит;;%1 участника получат;%1 участников получат;%1 участника получат';
					|vi = ';%1 participant will receive;;;;%1 participants will receive';
					|en = ';%1 participant will receive;;;;%1 participants will receive'; fa = ';%1 participant will receive;;;;%1 participants will receive';
					|it = ';%1 participant will receive;;;;%1 participants will receive';
					|pl = ';%1 participant will receive;;;;%1 participants will receive';
					|tr = ';%1 katılımcı alacak;;%1 katılımcı alacak;%1 katılımcı alacak;%1 katılımcı alacak'"),
					Number_Participants.AimForNewCycle));
		
		ResponseHandler1 = New CallbackDescription("ProcessIssueOfSavingResults", ThisObject);
		
		StandardSubsystemsClient.ShowQuestionToUser(
			ResponseHandler1,
			QueryText,
			VariantList,
			QuestionToUserParameters);
		
	Else
		
		StartRecordingActionInWorkflow();
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Function NumberOfParticipantsToRepeat()
	
	Number_Participants = New Structure;
	Number_Participants.Insert("TotalNumberOfConcordants", 0);
	Number_Participants.Insert("AimForNewCycle", 0);
	Number_Participants.Insert("SavedResults", 0);
	
	ParticipantLines = LinesOfParticipantsInApprovalForm(ThisObject);
	For Each ParticipantSLine In ParticipantLines Do
		
		If Not ThisIsMatchingString(ParticipantSLine) Then
			Continue;
		EndIf;
		
		Number_Participants.TotalNumberOfConcordants = Number_Participants.TotalNumberOfConcordants + 1;
		
		If ParticipantSLine.DirectToNewCycle Then
			Number_Participants.AimForNewCycle = Number_Participants.AimForNewCycle + 1;
		EndIf;
		
	EndDo;
	
	Number_Participants.SavedResults =
		Number_Participants.TotalNumberOfConcordants - Number_Participants.AimForNewCycle;
	
	Return Number_Participants;
	
EndFunction

&AtClient
Procedure ProcessIssueOfSavingResults(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Variants = AnswersToQuestionAboutSavingResults();
	SelectedOption = Result.Value;
	
	If SelectedOption = Variants.Cancel Then
		Return;
	EndIf;
	
	If Result.NeverAskAgain Then
		SettingsParameters = SettingsForQuestionAboutSavingResults();
		CommonServerCall.CommonSettingsStorageSave(
			SettingsParameters.ObjectKey,
			SettingsParameters.SettingsKey,
			False);
	EndIf;
	
	StartRecordingActionInWorkflow();
	
EndProcedure

&AtClient
Function SettingsForQuestionAboutSavingResults()
	
	SettingsParameters = New Structure;
	SettingsParameters.Insert("ObjectKey", FormName);
	SettingsParameters.Insert("SettingsKey", "ShowWarningAboutSavingResults");
	
	Return SettingsParameters;
	
EndFunction

#EndRegion

#Region SettingUpRepeatFormWithResultsSaved

&AtClientAtServerNoContext
Function RepeatTextOptions()
	
	Variants = New Structure;
	Variants.Insert("SendFor", NStr("ru = 'Направлять';
									|vi = 'Send';
									|en = 'Send'; fa = 'ارسال';
									|it = 'Send';
									|pl = 'Send';
									|tr = 'Gönder'"));
	Variants.Insert("DoNotDirect", NStr("ru = 'Не направлять';
										|vi = 'Do not send';
										|en = 'Do not send'; fa = 'ارسال نشود';
										|it = 'Do not send';
										|pl = 'Do not send';
										|tr = 'Gönderme'"));
	
	Return Variants;
	
EndFunction

// Fills in the result data and repeat lines of the repeat form with the results saved.
//
// Parameters:
//   ParticipantLines - See LinesOfParticipantsInApprovalForm
//   ParticipantsResults - See ParticipantsResultsForReplayWithResultsSaved
//
&AtServer
Procedure FillInDataOfRepeatLinesWithResultsSaved(ParticipantLines, ParticipantsResults)
	
	For Each String In ParticipantLines Do
		
		If Not ThisIsMatchingString(String) Then
			
			String.Result = "";
			String.DirectToNewCycle = False;
			String.YouCanSaveResult = False;
			
		Else
			
			String.Result = ParticipantsResults[String.Id];
			String.DirectToNewCycle = Not ResultOfAgreementCanBeSaved(String.Result);
			String.YouCanSaveResult = ResultOfAgreementCanBeSaved(String.Result);
			
		EndIf;
		
		SetUpDisplayOfRepeatLineWhileSavingResults(String);
		
	EndDo;
	
EndProcedure

// Fills in the parameters for the visual display of a line in the form of a repeat with the results saved.
//
// Parameters:
//   String - FormDataTreeItem:
//     * Id - UUID
//     * Result - String
//     * PictureNumber - Number
//     * DirectToNewCycle - Boolean
//     * AimForNewCyclePresentation - String
//     * YouCanSaveResult - Boolean
//
&AtClientAtServerNoContext
Procedure SetUpDisplayOfRepeatLineWhileSavingResults(String)
	
	String.ResultPresentation = PresentationOfApprovalResult(String.Result);
	
	If Not ThisIsMatchingString(String) Then
		String.PictureNumber = -1;
		String.AimForNewCyclePresentation = "";
		
		Return;
	EndIf;
	
	String.PictureNumber =
		IntegrationWith1CDocumentManagement3ClientServer.NumberOfImageOfResultOfAction(String.Result);
	
	Variants = RepeatTextOptions();
	
	If String.DirectToNewCycle Then
		String.AimForNewCyclePresentation = Variants.SendFor;
	Else
		String.AimForNewCyclePresentation = Variants.DoNotDirect;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpRepeatFormWithResultsSaved(XDTOAction)
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "allowSavingResults") Then
		AllowToSaveResults = XDTOAction.allowSavingResults;
	EndIf;
	
	ThisIsDialogWithSavingResults = DialogMode And AllowToSaveResults;
	If Not ThisIsDialogWithSavingResults Then
		Return;
	EndIf;
	
	Items.SavingResultsSubmenu.Visible = True;
	Items.AttendeesPictureNumber.Visible = True;
	
	Items.ParticipantsResult.Visible = True;
	Items.ParticipantsSendPresentation.Visible = True;
	
	If ThisIsDialogWithSavingResults Then
		ParticipantsResults = ParticipantsResultsForReplayWithResultsSaved(XDTOAction);
		ParticipantLines = LinesOfParticipantsInApprovalForm(ThisObject);
		FillInDataOfRepeatLinesWithResultsSaved(ParticipantLines, ParticipantsResults);
	EndIf;
	
	FillInRepeatList();
	
EndProcedure

// Returns matching results by participant IDs for the replay Form with the results saved.
//
// Parameters:
//   XDTOAction - XDTODataObject - an XDTO object of the DMActionApproval type.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - UUID
//     * Value - String
//
&AtServer
Function ParticipantsResultsForReplayWithResultsSaved(XDTOAction)
	
	Results = New Map;
	
	For Each XDTORow In XDTOAction.allStatesAndResultsRows.rows Do
		
		ParticipantID = XDTORow.participantID;
		Result = XDTORow.result;
		
		Results[ParticipantID] = Result;
		
	EndDo;
	
	Return Results;
	
EndFunction

#EndRegion

#Region CommonMethodsForSavingResults

&AtClientAtServerNoContext
Function PresentationOfApprovalResult(Result)
	
	Results = ApprovalResults();
	
	PresentationOfResults = New Map;
	PresentationOfResults[Results.Approved] = NStr("ru = 'Согласовано';
													|vi = 'Approved';
													|en = 'Approved'; fa = 'تأییدشده';
													|it = 'Approved';
													|pl = 'Approved';
													|tr = 'Onaylandı'");
	PresentationOfResults[Results.ApprovedWithReservations] = NStr("ru = 'Согласовано с замечаниями';
																	|vi = 'Approved with comments';
																	|en = 'Approved with comments'; fa = 'تأییدشده با توضیحات';
																	|it = 'Approved with comments';
																	|pl = 'Approved with comments';
																	|tr = 'Yorumlarla onaylandı'");
	PresentationOfResults[Results.NotApproved] = NStr("ru = 'Не согласовано';
														|vi = 'Not approved';
														|en = 'Not approved'; fa = 'تأییدنشده';
														|it = 'Not approved';
														|pl = 'Not approved';
														|tr = 'Onaylanmadı'");
	
	Presentation = PresentationOfResults[Result];
	If Presentation <> Undefined Then
		Return Presentation;
	Else
		Return "";
	EndIf;
	
EndFunction

// Returns whether the matching result can be saved.
//
// Parameters:
//   Result - String - See ApprovalResults
//
// Returns:
//   Boolean
//
&AtClientAtServerNoContext
Function ResultOfAgreementCanBeSaved(Result)
	
	StoredResults = New Map;
	StoredResults[ApprovalResults().Approved] = True;
	StoredResults[ApprovalResults().ApprovedWithReservations] = True;
	
	Return (StoredResults[Result] = True);
	
EndFunction

&AtClientAtServerNoContext
Function ApprovalResults()
	
	Results = New Structure;
	Results.Insert("Approved", "Approved");
	Results.Insert("ApprovedWithReservations", "ApprovedWithReservations");
	Results.Insert("NotApproved", "NotApproved");
	
	Return Results;
	
EndFunction

// Rows of participants in the approval form.
//
// Returns:
//   Array of FormDataTreeItem:
//     * Id - UUID
//     * Result - String
//     * PictureNumber - Number
//     * DirectToNewCycle - Boolean
//     * YouCanSaveResult - Boolean
//
&AtClientAtServerNoContext
Function LinesOfParticipantsInApprovalForm(Form)
	
	LinesToFillIn = New Array;
	
	CollectionsOfItemsToCrawl = New Array; // Array of FormDataTreeItemCollection
	CollectionsOfItemsToCrawl.Add(Form.Attendees.GetItems());
	
	While CollectionsOfItemsToCrawl.Count() > 0 Do
		
		ProcessedCollection = CollectionsOfItemsToCrawl[CollectionsOfItemsToCrawl.UBound()];
		CollectionsOfItemsToCrawl.Delete(CollectionsOfItemsToCrawl.UBound());
		
		For Each String In ProcessedCollection Do
			
			LinesToFillIn.Add(String);
			CollectionsOfItemsToCrawl.Add(String.GetItems());
			
		EndDo;
		
	EndDo;
	
	Return LinesToFillIn;
	
EndFunction

// Matching functions.
//
// Returns:
//   Structure:
//     * Approver - String
//     * EnsuringConsistency - String
//     * ResultProcessor - String
//     * ResultProcessingManager - String
//     * PreparingCompletion - String
//
&AtClientAtServerNoContext
Function MatchingFunctions()
	
	Functions = New Structure;
	Functions.Insert("Approver", "ApprovingPerson");
	Functions.Insert("EnsuringConsistency", "EnsuringApproval");
	Functions.Insert("ResultProcessor", "ApprovalResultProcessor");
	Functions.Insert("ResultProcessingManager", "PreparingResultProcessor");
	Functions.Insert("PreparingCompletion", "PreparingCompletion");
	
	Return Functions;
	
EndFunction

// Notifies whether the participant's string is a matching string.
//
// Parameters:
//   String - FormDataTreeItem:
//     * Id - UUID
//     * ThisIsAStep - Boolean
//     * Function - String
//
// Returns:
//   Boolean
//
&AtClientAtServerNoContext
Function ThisIsMatchingString(String)
	
	If String.ThisIsAStep Then
		Return False;
	EndIf;
	
	If String.Function <> MatchingFunctions().Approver Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(String.Id) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

&AtServer
Procedure FillInRepeatList()
	
	Variants = RepeatTextOptions();
	
	ChoiceList = Items.ParticipantsSendPresentation.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(Variants.SendFor);
	ChoiceList.Add(Variants.DoNotDirect);
	
EndProcedure

// Handles the change of the performer in the participants.
//
// Parameters:
//   CurrentData - FormDataTreeItem:
//     * Id - UUID
//     * Result - String
//     * PictureNumber - Number
//     * DirectToNewCycle - Boolean
//     * AimForNewCyclePresentation - String
//     * YouCanSaveResult - Boolean
//
&AtClient
Procedure OnChangingArtistInParticipants(CurrentData)
	
	If Not ThisIsMatchingString(CurrentData) Then
		Return;
	EndIf;
	
	CurrentData.Result = "";
	CurrentData.DirectToNewCycle = True;
	SetUpDisplayOfRepeatLineWhileSavingResults(CurrentData);
	CurrentData.YouCanSaveResult = False;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	If ThisIsDialogWithSavingResults Then
		
		RepeatTextAvailability = ConditionalAppearance.Items.Add();
		
		Fields = RepeatTextAvailability.Fields.Items;
		Fields.Add().Field = New DataCompositionField(Items.ParticipantsSendPresentation.Name);
		
		ItemFilter = RepeatTextAvailability.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Attendees.YouCanSaveResult");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		RepeatTextAvailability.Appearance.SetParameterValue("ReadOnly", True);
		
		RepeatTextAvailability.Use = True;
		
		InactivityOfParticipantsWithSavedResult = ConditionalAppearance.Items.Add();
		
		Fields = InactivityOfParticipantsWithSavedResult.Fields.Items;
		Fields.Add().Field = New DataCompositionField(Items.LinePresentation.Name);
		Fields.Add().Field = New DataCompositionField(Items.ParticipantsResult.Name);
		Fields.Add().Field = New DataCompositionField(Items.DueDatePresentation.Name);
		
		ItemFilter = InactivityOfParticipantsWithSavedResult.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Attendees.Function");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = MatchingFunctions().Approver;
		
		ItemFilter = InactivityOfParticipantsWithSavedResult.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Attendees.DirectToNewCycle");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = InactivityOfParticipantsWithSavedResult.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Attendees.ThisIsAStep");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		InactivityOfParticipantsWithSavedResult.Appearance.SetParameterValue(
			"ReadOnly", True);
		InactivityOfParticipantsWithSavedResult.Appearance.SetParameterValue(
			"TextColor", StyleColors.InaccessibleCellTextColor);
		
		InactivityOfParticipantsWithSavedResult.Use = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion