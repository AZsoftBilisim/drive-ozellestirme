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
		ThereAreStages = IntegrationWith1CDocumentManagement3ClientServer.ThereAreStagesOfAction(
			Attendees,
			IdOfSignStage,
			IdOfPersonProcessingResult);
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

&AtClient
Procedure SigningMethodOnChange(Item)
	
	VisibilityOfProvider = (SigningMethod = "OnPaper");
	Items.AttendeesAddSigner.Visible = VisibilityOfProvider;
	Items.AttendeesContextMenuAddSigner.Visible = VisibilityOfProvider;
	
	ChangeSigningMethod();
	SetFormItemEnabled();
	
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
	ParametersForAddingParticipantsToAction.ParticipantFunction = "Signer";
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeAdding(
		ThisObject,
		Cancel,
		Copy,
		ParametersForAddingParticipantsToAction);
	
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
			And (CurrentData.Function <> "SigningResultProcessor");
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
	Items.WriteAndClose.Visible = True;
	Items.WriteAndClose.DefaultButton = True;
	SetAvailabilityOfMemberChanges();
	SetFormItemEnabled();
	
	// Immediately add a new line.
	For Each Stage In Attendees.GetItems() Do
		If Stage.Function <> "Signer" Or Stage.Unavailable Then
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
		NStr("vi = 'Kết quả người tham gia mới không ảnh hưởng đến kết quả thao tác và lộ trình xử lý, bởi vì đã ký.';
			|ru = 'Результаты новых участников не повлияют на результат действия и маршрут обработки, т.к. подписание уже пройдено.';
			|en = 'The results of new participants will not affect the action result and the processing route as signing is already completed.'; fa = 'The results of new participants will not affect the action result and the processing route as signing is already completed.';
			|it = 'Результаты новых участников не повлияют на результат действия и маршрут обработки, т.к. подписание уже пройдено.';
			|pl = 'The results of new participants will not affect the action result and the processing route as signing is already completed.';
			|tr = 'Yeni katılımcıların sonuçları, imzalama zaten gerçekleşmiş olduğu için eylemin sonucunu ve işleme rotasını etkilemeyecektir.'"));
	
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
	
	IntegrationWith1CDocumentManagement3Client.AddActionStep(ThisObject, "Signer");
	
EndProcedure

&AtClient
Procedure AddSigner(Command)
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsAStep Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsChildMember Then
		Return;
	EndIf;
	
	CurrentParentData = CurrentData.GetParent();
	If CurrentParentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentParentData.Function = "SigningResultProcessor" Then
		ShowMessageBox(,NStr("vi = 'Không thể thêm vào giai đoạn xử lý kết quả.';
							|ru = 'Добавление в этап обработки результата невозможно.';
							|en = 'Cannot add to the result processing stage.'; fa = 'Cannot add to the result processing stage.';
							|it = 'Добавление в этап обработки результата невозможно.';
							|pl = 'Cannot add to the result processing stage.';
							|tr = 'Sonucun işlem aşamasına eklenmesi mümkün değildir.'"));
		Return;
	EndIf;
	
	SignerSLines = CurrentData.GetItems();
	If SignerSLines.Count() <> 0 Then
		ShowMessageBox(,NStr("vi = 'Một người ký chỉ có thể có một người đảm bảo việc ký.';
							|ru = 'У подписывающего может быть только один обеспечивающий подписание.';
							|en = 'A signer can have only one person who ensures signing.'; fa = 'A signer can have only one person who ensures signing.';
							|it = 'У подписывающего может быть только один обеспечивающий подписание.';
							|pl = 'A signer can have only one person who ensures signing.';
							|tr = 'İmzalayanın sadece bir imzalayanı olabilir.'"));
		Return;
	EndIf;
	
	Modified = True;
	
	ParticipantLine = SignerSLines.Add();
	ParticipantLine.Id = String(New UUID);
	ParticipantLine.Function = "EnsuringSigning";
	ParticipantLine.ThisIsChildMember = True;
	ParticipantLine.LinePresentation =
		IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(ParticipantLine);
	
	CopyDataToSigner(ParticipantLine, CurrentData);
	
	If CurrentData.TermIsGeneral Then
		FillPropertyValues(ParticipantLine, CurrentData);
	EndIf;
	
	Items.Attendees.CurrentRow = ParticipantLine.GetID();
	
	FillInPresentationOfDeadlines();
	
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
			
			For Each ParticipantOfSecondLevelStage In StageParticipant.GetItems() Do
				
				ParticipantOfSecondLevelStage.DueDatePresentation =
					IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
						ParticipantOfSecondLevelStage.DueDate,
						ParticipantOfSecondLevelStage.Term_Days,
						ParticipantOfSecondLevelStage.TermHours,
						ParticipantOfSecondLevelStage.TermMinutes,
						UseDateAndTimeInTaskDeadlines,
						ParticipantOfSecondLevelStage.OptionForSettingDeadline);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Event handler for changing the "Signing method" field.
//
&AtClient
Procedure ChangeSigningMethod()
	
	Items.AttendeesAddSigner.Enabled = True;
	
	If SigningMethod <> "OnPaper" Then
		Items.AttendeesAddSigner.Enabled = False;
		
		// Removal of those providing signing.
		For Each StageString_ In Attendees.GetItems() Do
			For Each MemberString In StageString_.GetItems() Do
				ParticipantLines = MemberString.GetItems();
				RowIndex = ParticipantLines.Count() - 1;
				While RowIndex >= 0 Do
					
					ParticipantLine = ParticipantLines[RowIndex];
					If ParticipantLine.Function = "EnsuringSigning" Then
						ParticipantLines.Delete(ParticipantLine);
					EndIf;
					
					RowIndex = RowIndex - 1;
					
				EndDo;
			EndDo;
		EndDo;
		
		Return;
	EndIf;
	
	If SigningMethod = "OnPaper" Then
		For Each Stage In Attendees.GetItems() Do
			If Stage.Order <> "OneByOne" Then
				Stage.Order = "OneByOne";
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure CopyDataToSigner(Var_To, From) Export
	
	Var_To.OptionForSettingDeadline = From.OptionForSettingDeadline;
	
	Var_To.TaskDescription = From.TaskDescription;
	Var_To.LongDesc = From.LongDesc;
	Var_To.ThereIsSpecialNameDescription = From.ThereIsSpecialNameDescription;
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	
	If Var_To.OptionForSettingDeadline = OptionsForSettingDeadline.Exact_Date Then
		Var_To.DueDate = From.DueDate;
	Else
		Var_To.Term_Days = From.Term_Days;
		Var_To.TermHours = From.TermHours;
		Var_To.TermMinutes = From.TermMinutes;
	EndIf;
	
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
	
	If CurrentData.Function = "SigningResultProcessor" Then
		LineViewOnly = CurrentData.ThisIsAStep Or CurrentData.Unavailable;
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.LinePresentation.ChoiceButton = True;
		Items.DueDatePresentation.ReadOnly = LineViewOnly;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		Items.Order.ReadOnly = True;
		
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
		Items.Order.ReadOnly =
			(SigningMethod = "OnPaper")
			Or CurrentData.Unavailable
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
		
		Items.AttendeesAddSigner.Enabled = False;
		
	ElsIf CurrentData.ThisIsChildMember Then
		
		// Securing the signing.
		Items.DueDatePresentation.ReadOnly = True;
		Items.ThereIsSpecialNameDescription.ReadOnly = True;
		Items.LongDesc.ReadOnly = True;
		Items.Order.ReadOnly = True;
		Items.LinePresentation.ChoiceButton = True;
		
		Items.Add.Enabled = False;
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
		
		Items.AttendeesAddSigner.Enabled = False;
		
	Else
		
		// The signer.
		LineViewOnly = ParentIsUnavailable And Not CurrentData.AllowedToAdd Or CurrentData.Unavailable;
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.LinePresentation.ChoiceButton = True;
		Items.DueDatePresentation.ReadOnly = LineViewOnly;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		Items.Order.ReadOnly = True;
		
		Items.Add.Enabled = Not ParentIsUnavailable Or CurrentData.AllowedToAdd;
		
		Items.AttendeesAddSigner.Enabled = Not LineViewOnly
			Or CurrentData.AllowedToAdd;
		
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
	Items.AttendeesContextMenuAddSigner.Enabled =
		Items.AttendeesAddSigner.Enabled;
	
	Items.AttendeesAddStage.Enabled = Not ValueIsFilled(SettingOfActionID)
		And Not ExecutionOfActionWithNewParticipants Or YouCanOnlyAddMembers Or YouCanAddParticipants;
	
	Items.ContextAddStage.Enabled = Items.AttendeesAddStage.Enabled;
	
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
	If Stages.Count() > 0 Then
		// We add all stages to the table of participants.
		For Each StageString_ In Stages Do
			ParticipantsStage = StagesOfParticipants.Add();
			IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(ParticipantsStage, StageString_);
			ParticipantsStage.Function = "Signer";
			ParticipantsStage.StageName = StageString_.stageDescription;
			ParticipantsStage.ThisIsAStep = True;
			ParticipantsStage.Order = StageString_.orderOfExecutionByParticipants;
		EndDo;
	Else
		ParticipantsStage = StagesOfParticipants.Add();
		ParticipantsStage.Function = "Signer";
		ParticipantsStage.StageName = NStr("vi = 'Ký tên';
											|ru = 'Подписать';
											|en = 'Sign'; fa = 'امضا';
											|it = 'Подписать';
											|pl = 'Sign';
											|tr = 'İmzala'");
		ParticipantsStage.ThisIsAStep = True;
		ParticipantsStage.Id = IdOfSignStage;
		If SigningMethod = "OnPaper" Then
			ParticipantsStage.Order = "OneByOne";
		ElsIf SigningMethod = "BasicDS" Or SigningMethod = "EnhancedDS" Then
			If ValueIsFilled(XDTOAction.orderOfExecutionByParticipants) Then
				ParticipantsStage.Order = XDTOAction.orderOfExecutionByParticipants;
			Else
				ParticipantsStage.Order = "AllAtOnce";
			EndIf;
		Else
			// Empty.
			If FormOfObject = "Paper" Then
				ParticipantsStage.Order = "OneByOne";
			ElsIf ValueIsFilled(XDTOAction.orderOfExecutionByParticipants) Then
				ParticipantsStage.Order = XDTOAction.orderOfExecutionByParticipants;
			Else
				ParticipantsStage.Order = "AllAtOnce";
			EndIf;
		EndIf;
	EndIf;
	
	// Adding the result processor.
	ParticipantsStage = StagesOfParticipants.Add();
	ParticipantsStage.Function = "SigningResultProcessor";
	ParticipantsStage.Order = "OneByOne";
	ParticipantsStage.StageName = NStr("vi = 'Tham khảo với kết quả ký kết';
										|ru = 'Ознакомиться с результатом подписания';
										|en = 'Review the signing result'; fa = 'Review the signing result';
										|it = 'Ознакомиться с результатом подписания';
										|pl = 'Review the signing result';
										|tr = 'İmzalama sonucunu incele'");
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
				
				// At the first level, we display only those who are not subordinate to anyone.
				If IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(Member.higherLevelParticipant) Then
					Continue;
				EndIf;
				
				StageParticipant = ParticipantsOfStage.Add();
				IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
				StageParticipant.Function = Member.participantFunction;
				UpdateFieldHasSpecialNameDescription(StageParticipant);
				
				// The second level.
				SubordinateMembers = StageParticipant.GetItems();
				ChildMembers = IntegrationWith1CDocumentManagement3.ChildParticipantsOfAction(ParticipantsOfAction, Member.id);
				For Each ParticipantSubordinate In ChildMembers Do
					MemberChildElement = SubordinateMembers.Add();
					IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(
						MemberChildElement,
						ParticipantSubordinate);
					MemberChildElement.ThisIsChildMember = True;
					MemberChildElement.Function = ParticipantSubordinate.participantFunction;
					
					UpdateFieldHasSpecialNameDescription(MemberChildElement);
				EndDo;
				
			EndDo;
			
		Else
			
			// Familiarization.
			ParticipantProcessingResult = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(
				ParticipantsOfAction,
				"SigningResultProcessor");
			If ParticipantProcessingResult.Count() > 0 Then
				For Each Member In ParticipantProcessingResult Do
					StageParticipant = ParticipantsOfStage.Add();
					IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
					StageParticipant.Function = "SigningResultProcessor";
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
		IdOfSignStage,
		IdOfPersonProcessingResult);
	
	UpdatePresentationsInParticipantTree(Attendees);
	Commands.DifferentTerms.ToolTip = IntegrationWith1CDocumentManagement3.HintButtonsHaveDifferentExpirationDates(False, ThereAreStages);
	
EndProcedure

&AtServer
Procedure UpdateObjectInMemberTree(Proxy, XDTOAction)
	
	XDTOAction.participantRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionSigningParticipantRows");
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
		If ElementStage.Id = IdOfSignStage Then
			XDTOAction.orderOfExecutionByParticipants = ElementStage.Order;
		EndIf;
		If ElementStage.Id = IdOfSignStage
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
			If ElementStage.Id = IdOfSignStage Then
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
			
			If ElementStage.Function = "Signer" Then
				For Each XDTORow In XDTOMembers Do
					If MemberElement.MemberID = XDTORow.participant.objectID.id
							And MemberElement.MemberType = XDTORow.participant.objectID.type
							And MemberElement.TaskDescription = XDTORow.taskDescription
							And MemberElement.LongDesc = XDTORow.description
							And ((MemberElement.IsProtected = True And XDTORow.protected = False)
								Or MemberElement.IsProtected = False) Then
						Raise StrTemplate(
							NStr("vi = 'Trong các giai đoạn lặp lại người ký: %1.
								|Hãy xóa bản trùng lặp, hãy chỉ ra bản mô tả đặc biệt hoặc thiết lập dấu hiệu ""Được bảo mật"" cho người tham gia';
								|ru = 'В этапах повторяется подписывающий: %1.
								|Удалите дубли, укажите особое описание или установите подписывающему признак ""Защищенный""';
								|en = 'In the stages, the %1 signer is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the signer'; fa = 'In the stages, the %1 signer is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the signer';
								|it = 'В этапах повторяется подписывающий: %1.
								|Удалите дубли, укажите особое описание или установите подписывающему признак ""Защищенный""';
								|pl = 'In the stages, the %1 signer is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the signer';
								|tr = 'Aşamalarda tekrarlanan imzalayan: %1.
								|Tekrarlananları silin, özel açıklama belirtin veya imzalayanı ""Korumalı"" olarak yapılandırın'"),
							MemberElement.MemberPresentation);
					EndIf;
				EndDo;
			EndIf;
			
			XDTOMember = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionSigningParticipantRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOMember, MemberElement);
			If ValueIsFilled(StageID) Then
				XDTOMember.stageID = StageID;
			EndIf;
			XDTOMember.participantFunction = MemberElement.Function;
			XDTOMembers.Add(XDTOMember);
			
			If Not IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(ElementStage.Function) Then
				ThereArePerformingParticipants = True;
			Else
				ThereIsProcessingResult = True;
			EndIf;
			
			// The second level.
			For Each MemberChildElement In MemberElement.GetItems() Do
				
				If Not ValueIsFilled(MemberChildElement.MemberID) Then
					Continue;
				EndIf;
				
				For Each XDTORow In XDTOMembers Do
					If MemberChildElement.MemberID = XDTORow.participant.objectID.id
							And MemberChildElement.MemberType = XDTORow.participant.objectID.type
							And ElementStage.Function = XDTORow.participantFunction
							And MemberChildElement.TaskDescription = XDTORow.taskDescription
							And MemberChildElement.LongDesc = XDTORow.description
							And ((MemberChildElement.IsProtected = True And XDTORow.protected = False)
								Or MemberChildElement.IsProtected = False) Then
						Raise StrTemplate(
							NStr("vi = 'Trong giai đoạn ""%1"" lặp lại người tham gia: %2.
								|Hãy xóa bản trùng lặp, hãy chỉ ra bản mô tả đặc biệt hoặc thiết lập dấu hiệu ""Được bảo mật"" cho người tham gia';
								|ru = 'В этапе ""%1"" повторяется участник: %2.
								|Удалите дубли, укажите особое описание или установите участнику признак ""Защищенный""';
								|en = 'In the ""%1"" stage, the %2 participant is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant'; fa = 'In the ""%1"" stage, the %2 participant is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant';
								|it = 'В этапе ""%1"" повторяется участник: %2.
								|Удалите дубли, укажите особое описание или установите участнику признак ""Защищенный""';
								|pl = 'In the ""%1"" stage, the %2 participant is duplicated.
								|Remove the duplicates, specify the special details, or select the ""Protected"" checkbox for the participant';
								|tr = '""%1"" aşamasında tekrarlanan katılımcı: %2.
								|Tekrarlananları silin, özel açıklama belirtin veya katılımcıyı ""Korumalı"" olarak yapılandırın'"),
							ElementStage.StageName ,MemberChildElement.MemberPresentation);
					EndIf;
				EndDo;
				
				MemberChildXDTO = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMActionSigningParticipantRow");
				IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(
					Proxy,
					MemberChildXDTO,
					MemberChildElement);
				MemberChildXDTO.participantFunction = MemberChildElement.Function;
				MemberChildXDTO.higherLevelParticipant = XDTOMember.id; // We take it from the parent (in TS).
				MemberChildXDTO.stageID = XDTOMember.stageID; // We take it from the parent (in TS).
				XDTOMembers.Add(MemberChildXDTO);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	// If only the "Processing result" is filled in, then we do not save it.
	If Not ThereArePerformingParticipants Then
		XDTOMembers.Clear();
		StagesOfXDTO.Clear();
	ElsIf Not ThereIsProcessingResult Then
		Raise NStr("vi = 'Không có người tham gia ""tham khảo với kết quả ký kết""';
					|ru = 'Отсутствует участник ""ознакомления с результатом подписания""';
					|en = 'The ""Signing result review"" participant is missing'; fa = 'The ""Signing result review"" participant is missing';
					|it = 'Отсутствует участник ""ознакомления с результатом подписания""';
					|pl = 'The ""Signing result review"" participant is missing';
					|tr = '""İmza sonucunun incelenmesi"" katılımcısı yok'");
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
			
			// The second level.
			ParticipantsOfStage2 = ParticipantLine.GetItems();
			
			For IndexOfParticipant2 = 0 To ParticipantsOfStage2.Count() - 1 Do
				ParticipantLine = ParticipantsOfStage2[IndexOfParticipant2];
				
				ParticipantLine.RowPrefix = "";
				ParticipantLine.LinePresentation =
					IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(ParticipantLine);
				ParticipantLine.OrderPresentation =
					IntegrationWith1CDocumentManagement3ClientServer.PresentationOfOrderOfExecutionOfActionStep(ParticipantLine.Order);
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingAction(XDTOAction)
	
	// Fill in the general action data.
	IntegrationWith1CDocumentManagement3.ProcessWebServiceSResponseToReceivingAction(ThisObject, XDTOAction);
	
	// Fill in the signing action data.
	SigningMethod = XDTOAction.signingMethod;
	IdOfSignStage = XDTOAction.stageSigningID;
	IdOfPersonProcessingResult = XDTOAction.resultProcessorID;
	FormOfObject = XDTOAction.targetForm;
	StateOfAction = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "state") Then
		StateOfAction = XDTOAction.state;
	EndIf;
	
	// Update the action form.
	UpdateTreeOfParticipantsByObject(XDTOAction);
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfConditionsOfParticipantsInAction(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInStatesAndResultsInActionForm(ThisObject, XDTOAction);
	SetAvailabilityOfMemberChanges();
	SetSigningMethodsFromItemType(XDTOAction);
	
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
	XDTOAction.signingMethod = SigningMethod;
	UpdateObjectInMemberTree(Proxy, XDTOAction);
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
		Items.SigningMethod.Enabled = False;
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
		If ParticipantsStage.Id <> IdOfSignStage Then
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
			EnsuringSigning = StageParticipant.GetItems();
			For Each SecuringSigning In EnsuringSigning Do
				SecuringSigning.Unavailable = ParticipantsStage.Unavailable Or StageParticipant.AllowedToAdd;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSigningMethodsFromItemType(XDTOAction)
	
	If XDTOAction.target.objectID.type = "DMDocument" Then
		
		If XDTOAction.targetForm = "Paper" Then
			Items.SigningMethod.ListChoiceMode = True;
			Items.SigningMethod.ChoiceList.Clear();
			Items.SigningMethod.ChoiceList.Add("OnPaper", NStr("vi = 'Bằng giấy';
																|ru = 'На бумаге';
																|en = 'On paper'; fa = 'روی کاغذ';
																|it = 'На бумаге';
																|pl = 'On paper';
																|tr = 'Kağıt üzerinde'"));
			
			If SigningMethod <> "OnPaper" Then
				SigningMethod = "OnPaper";
			EndIf;
		ElsIf XDTOAction.targetForm = "Electronic" Then
			Items.SigningMethod.ListChoiceMode = True;
			Items.SigningMethod.ChoiceList.Clear();
			Items.SigningMethod.ChoiceList.Add("BasicDS", NStr("vi = 'Chữ ký điện tử đơn giản';
																|ru = 'Простая ЭП';
																|en = 'Simple digital signature'; fa = 'امضای دیجیتال ساده';
																|it = 'Простая ЭП';
																|pl = 'Simple digital signature';
																|tr = 'Basit Eİ'"));
			If UseDigitalSignature Then
				Items.SigningMethod.ChoiceList.Add("EnhancedDS", NStr("vi = 'Chữ ký điện tử nâng cao';
																		|ru = 'Усиленная ЭП';
																		|en = 'Enhanced digital signature'; fa = 'امضای دیجیتال پیشرفته';
																		|it = 'Усиленная ЭП';
																		|pl = 'Enhanced digital signature';
																		|tr = 'Güçlendirilmiş Eİ'"));
			EndIf;
			
			If Not ValueIsFilled(SigningMethod) Or SigningMethod = "OnPaper" Then
				SigningMethod = "BasicDS";
			EndIf;
		EndIf;
		
	ElsIf XDTOAction.target.objectID.type = "DMMeeting" Then
		
		Items.SigningMethod.ListChoiceMode = True;
		Items.SigningMethod.ChoiceList.Clear();
		Items.SigningMethod.ChoiceList.Add("OnPaper", NStr("vi = 'Bằng giấy';
															|ru = 'На бумаге';
															|en = 'On paper'; fa = 'روی کاغذ';
															|it = 'На бумаге';
															|pl = 'On paper';
															|tr = 'Kağıt üzerinde'"));
		Items.SigningMethod.ChoiceList.Add("BasicDS", NStr("vi = 'Chữ ký điện tử đơn giản';
															|ru = 'Простая ЭП';
															|en = 'Simple digital signature'; fa = 'امضای دیجیتال ساده';
															|it = 'Простая ЭП';
															|pl = 'Simple digital signature';
															|tr = 'Basit Eİ'"));
		
		If Not ValueIsFilled(SigningMethod) Then
			SigningMethod = "BasicDS";
		EndIf;
		
	EndIf;
	
	If SigningMethod <> "OnPaper" Then
		Items.AttendeesAddSigner.Visible = False;
		Items.AttendeesContextMenuAddSigner.Visible = False;
	EndIf;
	
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
			UseDigitalSignature = SettingsOf1CDocumentManagement.UseElectronicDigitalSignatures;
			
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
				|Để khởi động ký mới, hãy thêm người tham gia.';
				|ru = 'Новые участники не добавлены.
				|Для запуска нового подписания добавьте участников.';
				|en = 'New participants are not added.
				|To start a new signing, add participants.'; fa = 'New participants are not added.
				|To start a new signing, add participants.';
				|it = 'Новые участники не добавлены.
				|Для запуска нового подписания добавьте участников.';
				|pl = 'New participants are not added.
				|To start a new signing, add participants.';
				|tr = 'Yeni katılımcılar eklenmedi.
				|Yeni imzalama başlatmak için katılımcı ekleyin.'"));
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
	
	If Not ValueIsFilled(SigningMethod) Then
		Message = New UserMessage;
		Message.Text = CommonClientServer.FillingErrorText(,, NStr("ru = 'Способ подписания';
																	|vi = 'Signing method';
																	|en = 'Signing method'; fa = 'روش امضا';
																	|it = 'Signing method';
																	|pl = 'Signing method';
																	|tr = 'İmzalama yöntemi'"));
		Message.Field = "SigningMethod";
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