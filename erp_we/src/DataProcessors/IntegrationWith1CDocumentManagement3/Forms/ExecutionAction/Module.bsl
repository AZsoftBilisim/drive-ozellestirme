#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3.WhenCreatingActionFormOnServer(ThisObject, Parameters);
	
	BasicStageName = NStr("vi = '<Chưa nhập>';
							|ru = '<Не введен>';
							|en = '<Not entered>'; fa = '<Not entered>';
							|it = '<Не введен>';
							|pl = '<Not entered>';
							|tr = '<Girilmedi>'");
	
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
		RemoveResponsibleParticipant();
		UpdatePresentationsInParticipantTree(Attendees, ByPoints);
		SetFormItemEnabled();
		
	ElsIf EventName = "UpdatePresentationsInParticipantTree" And Source = UUID Then
		UpdatePresentationsInParticipantTree(Attendees, ByPoints);
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
Procedure AuthorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagement3Client.SelectEmployeeFromDepartmentTree("Author", ThisObject, True);
	
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
Procedure InspectorAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure InspectorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("InspectorStartChoiceCompletion", ThisObject);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook",,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure InspectorStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", Inspector);
	Result.Property("PerformerID", InspectorID);
	Result.Property("PerformerType", InspectorType);
	
	Result.Property("MainAddressingObject", MainAddressingObjectInspector);
	Result.Property("MainAddressingObjectID", MainAddressingObjectInspectorID);
	Result.Property("MainAddressingObjectType", MainAddressingObjectInspectorType);
	
	Result.Property("AdditionalAddressingObject", AdditionalAddressingObjectController);
	Result.Property("AdditionalAddressingObjectID", AdditionalAddressingObjectControllerID);
	Result.Property("AdditionalAddressingObjectType", AdditionalAddressingObjectControllerType);
	
	InspectorPresentation = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Inspector,
		MainAddressingObjectInspector,
		AdditionalAddressingObjectController);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure InspectorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ClearControllerField();
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Inspector",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	InspectorPresentation = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Inspector,
		MainAddressingObjectInspector,
		AdditionalAddressingObjectController);
	
EndProcedure

&AtClient
Procedure InspectorTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			ClearControllerField();
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Inspector",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			InspectorPresentation =
				IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
					Inspector,
					MainAddressingObjectInspector,
					AdditionalAddressingObjectController);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure InspectorClearing(Item, StandardProcessing)
	
	ClearControllerField();
	InspectorPresentation = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Inspector,
		MainAddressingObjectInspector,
		AdditionalAddressingObjectController);
	Modified = True;
	
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
Procedure TaskDescriptionOnChange(Item)
	
	UpdateFieldHasSpecialNameDescription(Items.Attendees.CurrentData);
	
EndProcedure

&AtClient
Procedure DescriptionIsSpecialOnChange(Item)
	
	UpdateFieldHasSpecialNameDescription(Items.Attendees.CurrentData);
	
EndProcedure

&AtClient
Procedure LongDescOnChange(Item)
	
	UpdateFieldHasSpecialNameDescription(Items.Attendees.CurrentData);
	
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
Procedure LinePresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfActionBeginningOfChoice(
		Item,
		ChoiceData,
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
Procedure LinePresentationClearing(Item, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.PresentationOfParticipantOfCleaningAction(
		Item,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ResolutionProcessingTimePresentationOnChange(Item)
	
	CurrentData = Items.Attendees.CurrentData;
	
	TermChangeParameters = IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission();
	TermChangeParameters.Performer = CurrentData.Member;
	TermChangeParameters.PerformerID = CurrentData.MemberID;
	TermChangeParameters.PerformerType = CurrentData.MemberType;
	TermChangeParameters.MainAddressingObjectPerformer = CurrentData.MainAddressingObjectMember;
	TermChangeParameters.MainAddressingObjectPerformerID = CurrentData.MainAddressingObjectMemberID;
	TermChangeParameters.MainAddressingObjectPerformerType = CurrentData.MainAddressingObjectMemberType;
	TermChangeParameters.AdditionalAddressingObjectExecutor =
		CurrentData.AdditionalAddressingObjectParticipant;
	TermChangeParameters.AdditionalAddressingObjectExecutorID =
		CurrentData.AdditionalAddressingObjectParticipantID;
	TermChangeParameters.AdditionalAddressingObjectExecutorType =
		CurrentData.AdditionalAddressingObjectParticipantType;
	
	FillingResult = IntegrationWith1CDocumentManagement3ServerCall.ChangeDeadlineForExecutionByPresentation(
		CurrentData.ResolutionProcessingTime,
		CurrentData.DeadlineForProcessingResolutionIsDays,
		CurrentData.ResolutionProcessingTimeHours,
		CurrentData.ProcessingTimeOfResolutionIsMinutes,
		CurrentData.OptionForSettingResolutionProcessingTime,
		CurrentData.ResolutionProcessingTimePresentation,
		TermChangeParameters);
	
	If FillingResult Then
		FillInPresentationOfResolutionProcessingDeadlines();
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.TextOfWarningMessage) Then
		IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,
			TermChangeParameters.TextOfWarningMessage);
	EndIf;
	
EndProcedure

&AtClient
Procedure ResolutionProcessingTimePresentationTuning(Item, Direction, StandardProcessing)
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.ChangeRelativeTerm(
		CurrentData.DeadlineForProcessingResolutionIsDays,
		CurrentData.ResolutionProcessingTimeHours,
		CurrentData.ProcessingTimeOfResolutionIsMinutes,
		Direction);
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	CurrentData.OptionForSettingResolutionProcessingTime = OptionsForSettingDeadline.RelativeTerm;
	CurrentData.ResolutionProcessingTime = Date(1,1,1);
	
	Modified = True;
	
	FillInPresentationOfResolutionProcessingDeadlines();
	
EndProcedure

&AtClient
Procedure DueDatePresentationOnChange(Item)
	
	IntegrationWith1CDocumentManagement3Client.DeadlineForExecutionOfActionByParticipantInCaseOfChange(
		ThisObject,
		Not Items.AttendeesDifferentTerms.Check);
	UpdateResolutionProcessingDeadline();
	
EndProcedure

&AtClient
Procedure DueDatePresentationTuning(Item, Direction, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.DurationOfActionByParticipantIsRegulation(
		ThisObject,
		Direction,
		StandardProcessing,
		Not Items.AttendeesDifferentTerms.Check);
	UpdateResolutionProcessingDeadline();
	
EndProcedure

&AtClient
Procedure AttendeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Attendees.FindByID(RowSelected);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenSpecialNameAndDescription = Not CurrentData.ThisIsAStep
		And (CurrentData.Function <> "PerformanceResultProcessor")
		And CurrentData.SuperiorMember = "00000000-0000-0000-0000-000000000000";
	GeneralResolution = Undefined;
	If Permissions.Count() > 0 Then
		GeneralResolution = Permissions[0].Resolution;
	EndIf;
	OnlyViewingSpecialNameAndDescription = ReadOnly
		Or (GeneralResolution = "Forbidden")
		Or (GeneralResolution = Undefined)
		Or (YouCanOnlyAddMembers And CurrentData.Unavailable);
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsInActionChoice(
		ThisObject,
		RowSelected,
		Field,
		StandardProcessing,
		OpenSpecialNameAndDescription,
		OnlyViewingSpecialNameAndDescription,
		True);
	
	If ReadOnly And Field <> Items.ProjectResolution And Not CurrentData.ThisIsChildMember Then
		Return;
	EndIf;
	
	If CurrentData.ThisIsPoint Then
		
		StandardProcessing = False;
		PointCreationMode = (CurrentData.StageName = BasicStageName);
		OpenPoint(CurrentData, Not PointCreationMode);
		
	ElsIf Field = Items.ProjectResolution And Not CurrentData.ThisIsAStep And CurrentData.Function = "ReviewingPerson" Then
		
		StandardProcessing = False;
		
		// If there is no resolution, but the action is already active, then we do nothing.
		If Not CurrentData.ThereIsResolution And ValueIsFilled(CurrentData.State) Then
			Return;
		EndIf;
		
		FormParameters = New Structure;
		If CurrentData.ThereIsResolution Then
			FormParameters.Insert("Title", NStr("vi = 'Ý kiến chỉ đạo';
												|ru = 'Резолюция';
												|en = 'Resolution'; fa = 'دستور';
												|it = 'Резолюция';
												|pl = 'Resolution';
												|tr = 'Karar'"));
			FormParameters.Insert("Comment", CurrentData.PresentationOfResolution);
			FormParameters.Insert("ReadOnly", True);
		Else
			FormParameters.Insert("Title", NStr("vi = 'Dự thảo ý kiến chỉ đạo';
												|ru = 'Проект резолюции';
												|en = 'Draft resolution '; fa = 'پیش‌نویس دستور';
												|it = 'Progetto di risoluzione';
												|pl = 'Projekt rezolucji';
												|tr = 'Karar projesi'"));
			FormParameters.Insert("Comment", CurrentData.ProjectResolution);
			FormParameters.Insert("ReadOnly", False);
		EndIf;
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.EnterComment",
			FormParameters,,,,,
			New CallbackDescription("ProjectResolutionEndOfInput", ThisObject, CurrentData),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AttendeesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		If ByPoints Then
			AddAPoint(Undefined);
		EndIf;
		Return;
	EndIf;
	
	ParametersForAddingParticipantsToAction = IntegrationWith1CDocumentManagement3Client.ParametersForAddingParticipantsToAction();
	ParametersForAddingParticipantsToAction.WithStages = True;
	ParametersForAddingParticipantsToAction.ChildPerformersArePossible = True;
	ParametersForAddingParticipantsToAction.ByPoints = ByPoints;
	ParametersForAddingParticipantsToAction.YouCanAddStages = False;
	ParametersForAddingParticipantsToAction.YouCanOnlyAddMembers = YouCanOnlyAddMembers;
	ParametersForAddingParticipantsToAction.ParticipantFunction = "Performer";
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
Procedure AttendeesBeforeDeleteRow(Item, Cancel)
	
	IntegrationWith1CDocumentManagement3Client.ParticipantsOfActionBeforeDeletion(ThisObject, Cancel, True,, ByPoints);
	
EndProcedure

&AtClient
Procedure AttendeesOnActivateRow(Item)
	
	SetFormItemEnabled();
	IntegrationWith1CDocumentManagement3Client.ParticipantsInActionWhenLineIsActivated(ThisObject);
	
EndProcedure

&AtClient
Procedure AttendeesOnChange(Item)
	
	UpdatePresentationsInParticipantTree(Attendees, ByPoints);
	IntegrationWith1CDocumentManagement3Client.ExpandActionParticipantTree(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure AddAPoint(Command)
	
	MemberElements = Attendees.GetItems();
	
	ItemLine = MemberElements.Add();
	AddNewPoint(ItemLine, MemberElements, BasicStageName);
	Items.Attendees.CurrentRow = ItemLine.GetID();
	
	If Command <> Undefined Then
		OpenPoint(Items.Attendees.CurrentData, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure IsProtected(Command)
	
	IntegrationWith1CDocumentManagement3Client.ChangeProtectedActionParticipantAttribute(ThisObject);
	
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
		If Stage.Unavailable Or (Stage.Function <> "Performer" And Stage.Function <> "ReviewingPerson") Then
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
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateForm(True, False);
	
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
Procedure MoveUp(Command)
	
	IntegrationWith1CDocumentManagement3Client.MoveParticipantOfActionUp(ThisObject, False, ByPoints);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	IntegrationWith1CDocumentManagement3Client.MoveParticipantOfActionDown(ThisObject, False, ByPoints);
	
EndProcedure

&AtClient
Procedure ContinueDialogue(Command)
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure DifferentTerms(Command)
	
	Items.AttendeesDifferentTerms.Check = Not Items.AttendeesDifferentTerms.Check;
	IntegrationWith1CDocumentManagement3Client.SetSameExpirationDateRecursively(
		Attendees.GetItems(),
		ThisObject);
	
EndProcedure

&AtClient
Procedure SetEmployeeResponsible(Command)
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Function <> "Performer" Then
		Return;
	EndIf;
	
	CurrentData.EmployeeResponsible = Not CurrentData.EmployeeResponsible;
	Point_Id = CurrentData.Point_Id;
	CurrentRowID = CurrentData.GetID();
	For Each Stage In Attendees.GetItems() Do
		If Point_Id <> Stage.Point_Id Then
			Continue;
		EndIf;
		
		For Each StageParticipant In Stage.GetItems() Do
			If StageParticipant.GetID() = CurrentRowID Then
				Continue;
			EndIf;
			StageParticipant.EmployeeResponsible = False;
		EndDo;
	EndDo;
	
	If CurrentData.EmployeeResponsible Then
		ParticipantStage = CurrentData.GetParent().GetItems();
		RowIndex = ParticipantStage.IndexOf(CurrentData);
		If RowIndex Then
			ParticipantStage.Move(RowIndex, - RowIndex);
		EndIf;
	EndIf;
	
	Items.SetResponsible.Check = CurrentData.EmployeeResponsible;
	Modified = True;
	
EndProcedure

#EndRegion

#Region Private

#Region Client

// Fills in the Presentation of deadlines in the action card.
//
&AtClient
Procedure FillInPresentationOfDeadlines() Export
	
	For Each ParticipantsStage In Attendees.GetItems() Do
		
		If ParticipantsStage.TermIsGeneral
				Or ValueIsFilled(ParticipantsStage.DueDate)
				Or ValueIsFilled(ParticipantsStage.Term_Days)
				Or ValueIsFilled(ParticipantsStage.TermHours)
				Or ValueIsFilled(ParticipantsStage.TermMinutes) Then
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
			
			For Each ChildMember In StageParticipant.GetItems() Do
				
				ChildMember.DueDatePresentation =
					IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
						ChildMember.DueDate,
						ChildMember.Term_Days,
						ChildMember.TermHours,
						ChildMember.TermMinutes,
						UseDateAndTimeInTaskDeadlines,
						ChildMember.OptionForSettingDeadline);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Fills in the Presentation of the resolution processing deadlines in the action card.
//
&AtClient
Procedure FillInPresentationOfResolutionProcessingDeadlines() Export
	
	For Each ParticipantsStage In Attendees.GetItems() Do
		
		If ParticipantsStage.TermIsGeneral
				Or ValueIsFilled(ParticipantsStage.ResolutionProcessingTime)
				Or ValueIsFilled(ParticipantsStage.DeadlineForProcessingResolutionIsDays)
				Or ValueIsFilled(ParticipantsStage.ResolutionProcessingTimeHours)
				Or ValueIsFilled(ParticipantsStage.ProcessingTimeOfResolutionIsMinutes) Then
			ParticipantsStage.ResolutionProcessingTimePresentation =
				IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
					ParticipantsStage.ResolutionProcessingTime,
					ParticipantsStage.DeadlineForProcessingResolutionIsDays,
					ParticipantsStage.ResolutionProcessingTimeHours,
					ParticipantsStage.ProcessingTimeOfResolutionIsMinutes,
					UseDateAndTimeInTaskDeadlines,
					ParticipantsStage.OptionForSettingResolutionProcessingTime);
		Else
			ParticipantsStage.ResolutionProcessingTimePresentation = "";
		EndIf;
		
		For Each StageParticipant In ParticipantsStage.GetItems() Do
			
			StageParticipant.ResolutionProcessingTimePresentation =
				IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
					StageParticipant.ResolutionProcessingTime,
					StageParticipant.DeadlineForProcessingResolutionIsDays,
					StageParticipant.ResolutionProcessingTimeHours,
					StageParticipant.ProcessingTimeOfResolutionIsMinutes,
					UseDateAndTimeInTaskDeadlines,
					StageParticipant.OptionForSettingResolutionProcessingTime);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateResolutionProcessingDeadline()
	
	CurrentData = Items.Attendees.CurrentData;
	If CurrentData.Function <> "ProcessingResolution" Then
		Return;
	EndIf;
	
	LineOfReviewer = CurrentData.GetParent();
	LineOfReviewer.ResolutionProcessingTime = CurrentData.DueDate;
	LineOfReviewer.DeadlineForProcessingResolutionIsDays = CurrentData.Term_Days;
	LineOfReviewer.ResolutionProcessingTimeHours = CurrentData.TermHours;
	LineOfReviewer.ProcessingTimeOfResolutionIsMinutes = CurrentData.TermMinutes;
	
	FillInPresentationOfResolutionProcessingDeadlines();
	
EndProcedure

// Transfers item changes to action.
//
// Parameters:
//   ChangeResult - Structure:
//     * AuthorOfExecution - String
//     * AuthorOfExecutionID - String
//     * AuthorOfExecutionPresentation - String
//     * AuthorOfExecutionType - String
//     * AdditionalAddressingObjectController - String
//     * AdditionalAddressingObjectControllerID - String
//     * AdditionalAddressingObjectControllerType - String
//     * Point_Id - String
//     * PerformersOfExecution - Array of Structure:
//       ** OptionForSettingDeadline - String
//       ** AdditionalAddressingObjectParticipant - String
//       ** AdditionalAddressingObjectParticipantID - String
//       ** AdditionalAddressingObjectParticipantType - String
//       ** Id - String
//       ** MainAddressingObjectMember - String
//       ** MainAddressingObjectMemberID - String
//       ** MainAddressingObjectMemberType - String
//       ** EmployeeResponsible - Boolean
//       ** DueDate - Date
//       ** Term_Days - Number
//       ** TermMinutes - Number
//       ** TermHours - Number
//       ** Member - String
//       ** MemberID - String
//       ** MemberPresentation - String
//       ** MemberType - String
//       ** Function - String
//     * Inspector - String
//     * InspectorID - String
//     * InspectorPresentation - String
//     * InspectorType - String
//     * Number - String
//     * DescriptionOfExecution - String
//     * MainAddressingObjectInspector - String
//     * MainAddressingObjectInspectorID - String
//     * MainAddressingObjectInspectorType - String
//     * DueDate - Date
//   ContextUsedToPerformCheck - Structure:
//     * OpenOnly - Boolean
//
&AtClient
Procedure ProcessAfterChangingPoint(ChangeResult, ContextUsedToPerformCheck) Export
	
	If ChangeResult = Undefined
		Or ChangeResult = DialogReturnCode.Cancel Then
			If Not ContextUsedToPerformCheck.OpenOnly Then
				Attendees.GetItems().Delete(Attendees.FindByID(Items.Attendees.CurrentRow));
			EndIf;
		Return;
	EndIf;
	
	For Each Point In Attendees.GetItems() Do
		If Point.Point_Id <> ChangeResult.Point_Id Then
			Continue;
		EndIf;
		
		// data.
		Point.Number = ChangeResult.Number;
		Point.StageName = ChangeResult.DescriptionOfExecution;
		Point.LinePresentation = StrTemplate("%1. %2", Point.Number, Point.StageName);
		Point.DueDate = ChangeResult.DueDate;
		
		// Author.
		Point.Author = ChangeResult.AuthorOfExecution;
		Point.AuthorID = ChangeResult.AuthorOfExecutionID;
		Point.AuthorType = ChangeResult.AuthorOfExecutionType;
		Point.AuthorPresentation = ChangeResult.AuthorOfExecutionPresentation;
		
		// The controller.
		Point.Inspector = ChangeResult.Inspector;
		Point.InspectorID = ChangeResult.InspectorID;
		Point.InspectorType = ChangeResult.InspectorType;
		Point.InspectorPresentation = ChangeResult.InspectorPresentation;
		Point.MainAddressingObjectInspector = ChangeResult.MainAddressingObjectInspector;
		Point.MainAddressingObjectInspectorID = ChangeResult.MainAddressingObjectInspectorID;
		Point.MainAddressingObjectInspectorType = ChangeResult.MainAddressingObjectInspectorType;
		Point.AdditionalAddressingObjectController = ChangeResult.AdditionalAddressingObjectController;
		Point.AdditionalAddressingObjectControllerID = ChangeResult.AdditionalAddressingObjectControllerID;
		Point.AdditionalAddressingObjectControllerType = ChangeResult.AdditionalAddressingObjectControllerType;
		
		// Performers, verifier, verification period.
		ParticipantsOfStage = Point.GetItems();
		ParticipantsOfStage.Clear();
		For Each Member In ChangeResult.PerformersOfExecution Do
			StageParticipant = ParticipantsOfStage.Add();
			
			// Participant data.
			StageParticipant.Id = Member.Id;
			StageParticipant.OptionForSettingDeadline = Member.OptionForSettingDeadline;
			StageParticipant.EmployeeResponsible = Member.EmployeeResponsible;
			
			// The participant.
			StageParticipant.Member = Member.Member;
			StageParticipant.MemberID = Member.MemberID;
			StageParticipant.MemberType = Member.MemberType;
			StageParticipant.MemberPresentation = Member.MemberPresentation;
			StageParticipant.MainAddressingObjectMember = Member.MainAddressingObjectMember;
			StageParticipant.MainAddressingObjectMemberID = Member.MainAddressingObjectMemberID;
			StageParticipant.MainAddressingObjectMemberType = Member.MainAddressingObjectMemberType;
			StageParticipant.AdditionalAddressingObjectParticipant = Member.AdditionalAddressingObjectParticipant;
			StageParticipant.AdditionalAddressingObjectParticipantID = Member.AdditionalAddressingObjectParticipantID;
			StageParticipant.AdditionalAddressingObjectParticipantType = Member.AdditionalAddressingObjectParticipantType;
			
			// Term.
			StageParticipant.DueDate = Member.DueDate;
			StageParticipant.Term_Days = Member.Term_Days;
			StageParticipant.TermHours = Member.TermHours;
			StageParticipant.TermMinutes = Member.TermMinutes;
			
			// Other data.
			StageParticipant.Function = Member.Function;
			StageParticipant.Point_Id = Point.Id;
		EndDo;
	EndDo;
	
	UpdatePresentationsInParticipantTree(Attendees, ByPoints);
	FillInPresentationOfDeadlines();
	IntegrationWith1CDocumentManagement3Client.MarkButtonsWithDifferentExpirationDatesRecursively(
		Attendees.GetItems(),
		Items.AttendeesDifferentTerms);
	
	// Open the whole tree.
	IntegrationWith1CDocumentManagement3Client.ExpandActionParticipantTree(ThisObject);
	Modified = True;
	
EndProcedure

&AtClient
Procedure OpenPoint(CurrentData, OpenOnly = True)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	// customization.
	EditionAllowed =
		Not ReadOnly
		And Not YouCanOnlyAddMembers
		Or (CurrentData.State = "Completed")
		Or Not OpenOnly;
	FormParameters.Insert("EditionAllowed", EditionAllowed);
	FormParameters.Insert("YouCanOnlyAddMembers", YouCanOnlyAddMembers);
	FormParameters.Insert("Point_Id", CurrentData.Point_Id);
	FormParameters.Insert("UseDateAndTimeInTaskDeadlines", UseDateAndTimeInTaskDeadlines);
	
	// data.
	FormParameters.Insert("Number", CurrentData.Number);
	If CurrentData.StageName <> BasicStageName Then
		FormParameters.Insert("DescriptionOfExecution", CurrentData.StageName);
	Else
		FormParameters.Insert("DescriptionOfExecution", "");
	EndIf;
	FormParameters.Insert("DueDate", CurrentData.DueDate);
	
	// Author.
	FormParameters.Insert("AuthorOfExecution", CurrentData.Author);
	FormParameters.Insert("AuthorOfExecutionID", CurrentData.AuthorID);
	FormParameters.Insert("AuthorOfExecutionType", CurrentData.AuthorType);
	FormParameters.Insert("AuthorOfExecutionPresentation", CurrentData.AuthorPresentation);
	
	// The controller.
	FormParameters.Insert("Inspector", CurrentData.Inspector);
	FormParameters.Insert("InspectorID", CurrentData.InspectorID);
	FormParameters.Insert("InspectorType", CurrentData.InspectorType);
	FormParameters.Insert("InspectorPresentation", CurrentData.InspectorPresentation);
	FormParameters.Insert("MainAddressingObjectInspector", CurrentData.MainAddressingObjectInspector);
	FormParameters.Insert("MainAddressingObjectInspectorID", CurrentData.MainAddressingObjectInspectorID);
	FormParameters.Insert("MainAddressingObjectInspectorType", CurrentData.MainAddressingObjectInspectorType);
	FormParameters.Insert("AdditionalAddressingObjectController",
		CurrentData.AdditionalAddressingObjectController);
	FormParameters.Insert("AdditionalAddressingObjectControllerID",
		CurrentData.AdditionalAddressingObjectControllerID);
	FormParameters.Insert("AdditionalAddressingObjectControllerType",
		CurrentData.AdditionalAddressingObjectControllerType);
	
	// Performers, verifier, verification period.
	PerformersOfExecution = New Array;
	For Each StageParticipant In CurrentData.GetItems() Do
		ParticipantParameters = New Structure;
		
		// Participant data.
		ParticipantParameters.Insert("AssigneeID", StageParticipant.Id);
		ParticipantParameters.Insert("OptionForSettingDueDate", StageParticipant.OptionForSettingDeadline);
		ParticipantParameters.Insert("EmployeeResponsible", StageParticipant.EmployeeResponsible);
		
		// The participant.
		ParticipantParameters.Insert("Performer", StageParticipant.Member);
		ParticipantParameters.Insert("PerformerID", StageParticipant.MemberID);
		ParticipantParameters.Insert("PerformerType", StageParticipant.MemberType);
		ParticipantParameters.Insert("PerformerPresentation", StageParticipant.MemberPresentation);
		ParticipantParameters.Insert("MainAddressingObjectPerformer",
			StageParticipant.MainAddressingObjectMember);
		ParticipantParameters.Insert("MainAddressingObjectPerformerID",
			StageParticipant.MainAddressingObjectMemberID);
		ParticipantParameters.Insert("MainAddressingObjectPerformerType",
			StageParticipant.MainAddressingObjectMemberType);
		ParticipantParameters.Insert("AdditionalAddressingObjectExecutor",
			StageParticipant.AdditionalAddressingObjectParticipant);
		ParticipantParameters.Insert("AdditionalAddressingObjectExecutorID",
			StageParticipant.AdditionalAddressingObjectParticipantID);
		ParticipantParameters.Insert("AdditionalAddressingObjectExecutorType",
			StageParticipant.AdditionalAddressingObjectParticipantType);
		
		// Term.
		ParticipantParameters.Insert("TaskDueDate", StageParticipant.DueDate);
		ParticipantParameters.Insert("DueDateDays", StageParticipant.Term_Days);
		ParticipantParameters.Insert("DueDateHours", StageParticipant.TermHours);
		ParticipantParameters.Insert("ExecutionTimeMinutes", StageParticipant.TermMinutes);
		
		// Other data.
		ParticipantParameters.Insert("Function", StageParticipant.Function);
		ParticipantParameters.Insert("State", StageParticipant.State);
		ParticipantParameters.Insert("PictureNumber", StageParticipant.PictureNumber);
		ParticipantParameters.Insert("Result", StageParticipant.Result);
		
		PerformersOfExecution.Add(ParticipantParameters);
	EndDo;
	FormParameters.Insert("PerformersOfExecution", PerformersOfExecution);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OpenOnly", OpenOnly);
	CallbackDescription = New CallbackDescription(
		"ProcessAfterChangingPoint",
		ThisObject,
		NotificationParameters);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.SubordinateExecutionSetting",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ClearControllerField()
	
	Inspector = "";
	InspectorID = "";
	InspectorType = "";
	
	MainAddressingObjectInspector = "";
	MainAddressingObjectInspectorID = "";
	MainAddressingObjectInspectorType = "";
	
	AdditionalAddressingObjectController = "";
	AdditionalAddressingObjectControllerID = "";
	AdditionalAddressingObjectControllerType = "";
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	WriteAndClose();
	
EndProcedure

&AtClient
Procedure ProjectResolutionEndOfInput(EnteredText, CurrentData) Export
	
	If EnteredText = Undefined
			Or EnteredText = DialogReturnCode.Cancel
			Or TypeOf(EnteredText) <> Type("String") Then
		Return;
	EndIf;
	
	CurrentData.ProjectResolution = EnteredText;
	CurrentData.PresentationOfResolution = EnteredText;
	Modified = True;
	
EndProcedure

&AtClient
Function PointWithoutParticipants(Point)
	
	ThereAreParticipants = False;
	For Each String In Point.GetItems() Do
		If ValueIsFilled(String.MemberID) Then
			ThereAreParticipants = True;
			Break;
		EndIf;
	EndDo;
	
	Return Not ThereAreParticipants;
	
EndFunction

// The Person Responsible for the participant of the execution action removes the mark if he remains alone.
//
&AtClient
Procedure RemoveResponsibleParticipant()
	
	For Each StageString_ In Attendees.GetItems() Do
		If StageString_.Function <> "Performer" Then
			Continue;
		EndIf;
		
		ElementsOfParticipants = StageString_.GetItems();
		ItemCount = ElementsOfParticipants.Count();
		If ItemCount > 1 Then
			Continue;
		EndIf;
		
		For Each ParticipantLine In ElementsOfParticipants Do
			If ParticipantLine.EmployeeResponsible Then
				ParticipantLine.EmployeeResponsible = False;
				Modified = True;
			EndIf;
		EndDo;
	EndDo;
	
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
	Else
		ParentItems1 = CurrentParent.GetItems();
	EndIf;
	IndexOf = ParentItems1.IndexOf(CurrentData);
	ThisIsFirstElement = (IndexOf = 0);
	IsLastItem = (IndexOf = (ParentItems1.Count() - 1));
	
	PreviousOneIsAvailable = False;
	If Not ThisIsFirstElement Then
		PreviousItem = ParentItems1.Get(IndexOf - 1);
		PreviousOneIsAvailable = Not PreviousItem.Unavailable;
	EndIf;
	
	FollowingIsAvailable = False;
	If Not IsLastItem Then
		NextItem = ParentItems1.Get(IndexOf + 1);
		FollowingIsAvailable = Not NextItem.Unavailable
			And (NextItem.Function <> "PerformanceResultProcessor");
	EndIf;
	
	NumberOfParentElements = ParentItems1.Count();
	ResponsiblePersonIsInstalledUnavailable = False;
	For Each Item In ParentItems1 Do
		If Item.EmployeeResponsible And Item.Unavailable Then
			ResponsiblePersonIsInstalledUnavailable = True;
			Break;
		EndIf;
	EndDo;
	Items.SetResponsible.Check = False;
	Items.ResolutionProcessingTimePresentation.ReadOnly = True;
	ThisIsProcessingResolution = (CurrentData.Function = "ProcessingResolution");
	
	If CurrentData.Function = "PerformanceResultProcessor" Then
		LineViewOnly = CurrentData.ThisIsAStep Or CurrentData.Unavailable;
		Items.LinePresentation.ReadOnly = LineViewOnly;
		Items.DueDatePresentation.ReadOnly = LineViewOnly;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.TaskDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		Items.DescriptionIsSpecial.ReadOnly = LineViewOnly;
		Items.ProjectResolution.ReadOnly = True;
		Items.SetResponsible.Enabled = False;
		
		Items.Add.Enabled = False;
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
		Items.Delete.Enabled = Not LineViewOnly;
		
	ElsIf CurrentData.ThisIsAStep Then
		
		Items.LinePresentation.ReadOnly = True;
		Items.DueDatePresentation.ReadOnly = True;
		Items.ThereIsSpecialNameDescription.ReadOnly = True;
		Items.TaskDescription.ReadOnly = True;
		Items.LongDesc.ReadOnly = True;
		Items.DescriptionIsSpecial.ReadOnly = True;
		Items.ProjectResolution.ReadOnly = True;
		Items.SetResponsible.Enabled = False;
		
		Items.Add.Enabled = Not CurrentData.Unavailable Or YouCanOnlyAddMembers;
		Items.MoveUp.Enabled = ByPoints And Not CurrentData.Unavailable And PreviousOneIsAvailable;
		Items.MoveDown.Enabled = ByPoints And Not CurrentData.Unavailable And FollowingIsAvailable;
		Items.Delete.Enabled = Not CurrentData.Unavailable;
		
	Else
		
		// executor.
		If CurrentParent <> Undefined And Not ThisIsProcessingResolution Then
			ForbiddingAddingLine = CurrentParent.Unavailable And Not YouCanOnlyAddMembers
				Or CurrentData.ThisIsChildMember;
		Else
			ForbiddingAddingLine = CurrentData.Unavailable And Not YouCanOnlyAddMembers
				Or CurrentData.ThisIsChildMember;
		EndIf;
		
		LineViewOnly = CurrentData.Unavailable
			Or (CurrentData.ThisIsChildMember And (CurrentData.Function <> "ProcessingResolution"))
			Or (CurrentData.State = "Completed");
		
		Items.LinePresentation.ReadOnly = LineViewOnly Or ThisIsProcessingResolution;
		Items.DueDatePresentation.ReadOnly = LineViewOnly
			Or YouCanOnlyAddMembers And Not ThisIsFirstElement;
		Items.ThereIsSpecialNameDescription.ReadOnly = LineViewOnly;
		Items.TaskDescription.ReadOnly = LineViewOnly;
		Items.LongDesc.ReadOnly = LineViewOnly;
		Items.DescriptionIsSpecial.ReadOnly = LineViewOnly;
		Items.ResolutionProcessingTimePresentation.ReadOnly =
			(CurrentData.Function <> "ReviewingPerson") Or LineViewOnly;
		Items.Add.Enabled = Not ForbiddingAddingLine;
		
		Items.MoveUp.Enabled = Not ThisIsFirstElement
			And Not LineViewOnly
			And PreviousOneIsAvailable;
		Items.MoveDown.Enabled = Not IsLastItem
			And Not LineViewOnly
			And FollowingIsAvailable;
		Items.Delete.Enabled = Not LineViewOnly And Not ThisIsProcessingResolution;
		
		Items.LinePresentation.ChoiceButton = True;
		
		Items.ProjectResolution.ReadOnly = True;
		
		Items.SetResponsible.Enabled = Not LineViewOnly And Not ResponsiblePersonIsInstalledUnavailable
			And CurrentData.State <> "Completed"
			And CurrentData.Function = "Performer"
			And NumberOfParentElements > 1;
		Items.SetResponsible.Check = CurrentData.EmployeeResponsible;
	EndIf;
	
	Items.AddContext.Enabled = Items.Add.Enabled;
	Items.ContextAddItem.Enabled = Items.AttendeesAddAPoint.Enabled;
	Items.DeleteContext.Enabled = Items.Delete.Enabled;
	Items.ContextToEstablishResponsiblePerson.Enabled = Items.SetResponsible.Enabled;
	Items.ContextToEstablishResponsiblePerson.Check = Items.SetResponsible.Check;
	
EndProcedure

#EndRegion

#Region Server

&AtClientAtServerNoContext
Procedure AddNewPoint(ParticipantsStage, StagesOfParticipants, BasicStageName)
	
	ParticipantsStage.Function = "Performer";
	ParticipantsStage.StageName = BasicStageName;
	ParticipantsStage.Number = String(StagesOfParticipants.Count());
	ParticipantsStage.ThisIsAStep = True;
	ParticipantsStage.ThisIsPoint = True;
	ParticipantsStage.Id = String(New UUID);
	ParticipantsStage.Point_Id = ParticipantsStage.Id;
	ParticipantsStage.LinePresentation = StrTemplate("%1. %2", ParticipantsStage.Number, ParticipantsStage.StageName);
	
EndProcedure

// Fills in the tree of participants by object.
//
&AtServer
Procedure UpdateTreeOfParticipantsByObject(XDTOAction)
	
	// Reschedule the Due Date from the item if not specified in the settings
	TermOfExecutionOfSubject = XDTOAction.targetDueDate;
	
	StagesOfParticipants = Attendees.GetItems();
	StagesOfParticipants.Clear();
	
	AllAssignees = XDTOAction.participantRows.rows;
	
	If ByPoints Then
		
		Items_2 = XDTOAction.pointRows.rows;
		
		// We add all the items to the table of participants.
		For Each StageString_ In Items_2 Do
			ParticipantsStage = StagesOfParticipants.Add();
			IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(ParticipantsStage, StageString_);
			ParticipantsStage.Function = "Performer";
			ParticipantsStage.StageName = StageString_.description;
			ParticipantsStage.ThisIsAStep = True;
			ParticipantsStage.ThisIsPoint = True;
			ParticipantsStage.Point_Id = ParticipantsStage.Id;
			ParticipantsStage.LinePresentation = StrTemplate("%1. %2", ParticipantsStage.Number, ParticipantsStage.StageName);
		EndDo;
		
		If Items_2.Count() = 0 Then
			ParticipantsStage = StagesOfParticipants.Add();
			AddNewPoint(ParticipantsStage, StagesOfParticipants, BasicStageName);
		EndIf;
		
		For Each StageString_ In StagesOfParticipants Do
			ParticipantsOfStage = StageString_.GetItems();
			
			StageParticipant = Undefined;
			For Each Member In AllAssignees Do
				If (IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(Member.pointID)
							And Member.pointID <> StageString_.Id)
						Or (Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(Member.pointID)
							And Member.participantFunction <> StageString_.Function) Then
					Continue;
				EndIf;
				
				StageParticipant = ParticipantsOfStage.Add();
				IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
				If ValueIsFilled(Member.participantFunction) Then
					StageParticipant.Function = Member.participantFunction;
				Else
					StageParticipant.Function = "Performer";
				EndIf;
				
				ParticipantsStage.Point_Id = StageString_.Id;
				UpdateFieldHasSpecialNameDescription(StageParticipant);
			EndDo;
		EndDo;
		
	Else
		
		// Consideration.
		ParticipantsStage = StagesOfParticipants.Add();
		ParticipantsStage.Function = "ReviewingPerson";
		ParticipantsStage.StageName = NStr("vi = 'Xem xét';
											|ru = 'Рассмотрение';
											|en = 'Review'; fa = 'بررسی';
											|it = 'Рассмотрение';
											|pl = 'Review';
											|tr = 'Değerlendirme'");
		ParticipantsStage.ThisIsAStep = True;
		ParticipantsStage.Id = "00000000-0000-0000-0000-000000000000";
		ParticipantsStage.Point_Id = "00000000-0000-0000-0000-000000000000";
		
		ParticipantsOfStage = ParticipantsStage.GetItems();
		StageParticipant = Undefined;
		
		ReviewingPersons = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(AllAssignees, "ReviewingPerson");
		For Each ReviewingPerson In ReviewingPersons Do
			StageParticipant = ParticipantsOfStage.Add();
			IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, ReviewingPerson);
			StageParticipant.Function = "ReviewingPerson";
			UpdateFieldHasSpecialNameDescription(StageParticipant);
			
			SubordinateMembers = StageParticipant.GetItems();
			ChildMembers = IntegrationWith1CDocumentManagement3.ChildParticipantsOfAction(AllAssignees, ReviewingPerson.id);
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
		
		// If there is no participant, then add an empty line.
		If StageParticipant = Undefined Then
			StageParticipant = ParticipantsOfStage.Add();
			StageParticipant.Function = ParticipantsStage.Function;
			StageParticipant.Id = String(New UUID);
			If ValueIsFilled(TermOfExecutionOfSubject) Then
				StageParticipant.DueDate = TermOfExecutionOfSubject;
				StageParticipant.OptionForSettingDeadline = "ExactDate";
			EndIf;
		EndIf;
		
		// Execution.
		ParticipantsStage = StagesOfParticipants.Add();
		ParticipantsStage.Function = "Performer";
		ParticipantsStage.StageName = NStr("vi = 'Thực hiện';
											|ru = 'Исполнение';
											|en = 'Execution'; fa = 'اجرا';
											|it = 'Исполнение';
											|pl = 'Execution';
											|tr = 'Yürütme'");
		ParticipantsStage.ThisIsAStep = True;
		ParticipantsStage.Id = "00000000-0000-0000-0000-000000000000";
		ParticipantsStage.Point_Id = "00000000-0000-0000-0000-000000000000";
		
		ParticipantsOfStage = ParticipantsStage.GetItems();
		StageParticipant = Undefined;
		
		Assignees = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(AllAssignees, "Performer");
		For Each Member In Assignees Do
			StageParticipant = ParticipantsOfStage.Add();
			IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
			StageParticipant.Function = "Performer";
			UpdateFieldHasSpecialNameDescription(StageParticipant);
		EndDo;
		
		// If there is no participant, then add an empty line.
		If StageParticipant = Undefined Then
			StageParticipant = ParticipantsOfStage.Add();
			StageParticipant.Function = ParticipantsStage.Function;
			StageParticipant.Id = String(New UUID);
			If ValueIsFilled(TermOfExecutionOfSubject) Then
				StageParticipant.DueDate = TermOfExecutionOfSubject;
				StageParticipant.OptionForSettingDeadline = "ExactDate";
			EndIf;
		EndIf;
		
		// Participants processing the result.
		ParticipantsStage = StagesOfParticipants.Add();
		ParticipantsStage.Function = "PerformanceResultProcessor";
		ParticipantsStage.StageName = NStr("vi = 'Người xử lý kết quả';
											|ru = 'Обрабатывающий результат';
											|en = 'Person who processes the result'; fa = 'Person who processes the result';
											|it = 'Обрабатывающий результат';
											|pl = 'Person who processes the result';
											|tr = 'İşleme sonucu'");
		ParticipantsStage.ThisIsAStep = True;
		ParticipantsStage.Id = "00000000-0000-0000-0000-000000000000";
		ParticipantsStage.Point_Id = "00000000-0000-0000-0000-000000000000";
		
		ParticipantsOfStage = ParticipantsStage.GetItems();
		StageParticipant = Undefined;
		
		ParticipantProcessingResult = IntegrationWith1CDocumentManagement3.ParticipantsInActionWithFunction(
			AllAssignees,
			"PerformanceResultProcessor");
		If ParticipantProcessingResult.Count() > 0 Then
			For Each Member In ParticipantProcessingResult Do
				StageParticipant = ParticipantsOfStage.Add();
				IntegrationWith1CDocumentManagement3.FillInActionParticipantLineFromXDTO(StageParticipant, Member);
				StageParticipant.Function = "PerformanceResultProcessor";
			EndDo;
		Else
			StageParticipant = ParticipantsOfStage.Add();
			StageParticipant.Function = ParticipantsStage.Function;
			StageParticipant.Id = String(New UUID);
			If ValueIsFilled(TermOfExecutionOfSubject) Then
				StageParticipant.DueDate = TermOfExecutionOfSubject;
				StageParticipant.OptionForSettingDeadline = "ExactDate";
			EndIf;
		EndIf;
		
	EndIf;
	
	SetVisibilityAvailabilityOfFieldsByPoints(XDTOAction);
	Commands.DifferentTerms.ToolTip = IntegrationWith1CDocumentManagement3.HintButtonsHaveDifferentExpirationDates(ByPoints, False);
	UpdatePresentationsInParticipantTree(Attendees, ByPoints);
	
EndProcedure

&AtServer
Procedure UpdateObjectInMemberTree(Proxy, XDTOAction)
	
	XDTOAction.participantRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionPerformanceParticipantRows");
	XDTOMembers = XDTOAction.participantRows.rows; // XDTOList
	XDTOAction.pointRows = IntegrationWith1CDocumentManagementCore.CreateObject(
		Proxy,
		"DMActionPerformancePointRows");
	XDTOPoints = XDTOAction.pointRows.rows; // XDTOList
	
	ThereArePerformingParticipants = False;
	For Each ElementStage In Attendees.GetItems() Do
		
		Point_Id = "00000000-0000-0000-0000-000000000000";
		If ByPoints Then
			// For the standard stage, we change the ID if others are set.
			If ElementStage.Id = "00000000-0000-0000-0000-000000000000" Then
				ElementStage.Id = String(New UUID);
			EndIf;
			
			XDTOStage = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionPerformancePointRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOStage, ElementStage);
			XDTOStage.description = ElementStage.StageName;
			XDTOPoints.Add(XDTOStage);
			Point_Id = ElementStage.Id;
		EndIf;
		
		For Each MemberElement In ElementStage.GetItems() Do
			
			If Not ValueIsFilled(MemberElement.MemberID) Then
				Continue;
			EndIf;
			
			If ByPoints Then
				For Each XDTORow In XDTOMembers Do
					If MemberElement.MemberID = XDTORow.participant.objectID.id
							And MemberElement.MemberType = XDTORow.participant.objectID.type
							And MemberElement.Function = XDTORow.participantFunction
							And Point_Id = XDTORow.pointID
							And ((MemberElement.IsProtected = True And XDTORow.protected = False)
								Or MemberElement.IsProtected = False) Then
						Raise StrTemplate(
							NStr("vi = 'Trong mục ""%1"" bị lặp người tham gia:%2.
								|Hãy xóa bản trùng lặp hoặc thiết lập dấu hiệu ""Được bảo mật"" cho người tham gia';
								|ru = 'В пункте ""%1"" повторяется участник: %2.
								|Удалите дубли или установите участнику признак ""Защищенный""';
								|en = 'In the ""%1"" point, the %2 participant is duplicated.
								|Remove the duplicates or select the ""Protected"" checkbox for the participant'; fa = 'In the ""%1"" point, the %2 participant is duplicated.
								|Remove the duplicates or select the ""Protected"" checkbox for the participant';
								|it = 'В пункте ""%1"" повторяется участник: %2.
								|Удалите дубли или установите участнику признак ""Защищенный""';
								|pl = 'In the ""%1"" point, the %2 participant is duplicated.
								|Remove the duplicates or select the ""Protected"" checkbox for the participant';
								|tr = '""%1"" maddesinde tekrarlanan katılımcı: %2.
								|Tekrarlananları silin veya katılımcıyı ""Korumalı"" olarak yapılandırın'"),
							ElementStage.StageName, MemberElement.MemberPresentation);
					EndIf;
				EndDo;
			Else
				For Each XDTORow In XDTOMembers Do
					If MemberElement.MemberID = XDTORow.participant.objectID.id
							And MemberElement.MemberType = XDTORow.participant.objectID.type
							And ElementStage.Function = XDTORow.participantFunction
							And MemberElement.SuperiorMember = XDTORow.higherLevelParticipant
							And MemberElement.TaskDescription = XDTORow.taskDescription
							And MemberElement.LongDesc = XDTORow.description
							And ((MemberElement.IsProtected = True And XDTORow.protected = False)
								Or MemberElement.IsProtected = False) Then
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
							ElementStage.StageName ,MemberElement.MemberPresentation);
					EndIf;
				EndDo;
			EndIf;
			
			XDTOMember = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMActionPerformanceParticipantRow");
			IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(Proxy, XDTOMember, MemberElement);
			If ValueIsFilled(MemberElement.Function) Then
				XDTOMember.participantFunction = MemberElement.Function;
			Else
				XDTOMember.participantFunction = ElementStage.Function;
			EndIf;
			XDTOMember.pointID = Point_Id;
			XDTOMembers.Add(XDTOMember);
			
			If Not IntegrationWith1CDocumentManagement3ClientServer.ThisIsFunctionToProcessResult(
					XDTOMember.participantFunction) Then
				ThereArePerformingParticipants = True;
			EndIf;
			
			For Each MemberChildElement In MemberElement.GetItems() Do
				
				If Not ValueIsFilled(MemberChildElement.MemberID) Then
					Continue;
				EndIf;
				
				For Each XDTORow In XDTOMembers Do
					If MemberChildElement.MemberID = XDTORow.participant.objectID.id
							And MemberChildElement.MemberType = XDTORow.participant.objectID.type
							And ElementStage.Function = XDTORow.participantFunction
							And MemberChildElement.SuperiorMember = XDTORow.higherLevelParticipant
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
				
				XDTOMember = IntegrationWith1CDocumentManagementCore.CreateObject(
					Proxy,
					"DMActionPerformanceParticipantRow");
				IntegrationWith1CDocumentManagement3.FillInXDTOLineFromActionParticipant(
					Proxy,
					XDTOMember,
					MemberChildElement);
				XDTOMember.participantFunction = MemberChildElement.Function;
				XDTOMembers.Add(XDTOMember);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	// If only the "Processing result" is filled in, then we do not save it.
	If Not ThereArePerformingParticipants Then
		XDTOMembers.Clear();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFieldHasSpecialNameDescription(String)
	
	If String = Undefined Then
		Return;
	EndIf;
	
	String.ThereIsSpecialNameDescription = ValueIsFilled(String.TaskDescription)
		Or ValueIsFilled(String.LongDesc)
		Or ValueIsFilled(String.DescriptionIsSpecial);
	
EndProcedure

// Updates Presentations of rows in the participant tree.
//
// Parameters:
//   Attendees - FormDataTree - a tree with participants.
//   ByPoints - Boolean - the action is performed point by point.
//
&AtClientAtServerNoContext
Procedure UpdatePresentationsInParticipantTree(Attendees, ByPoints)
	
	StagesOfParticipants = Attendees.GetItems();
	
	StepNumberOfStage = 1;
	
	For IndexOfStage = 0 To StagesOfParticipants.Count() - 1 Do
		
		StageString_ = StagesOfParticipants.Get(IndexOfStage);
		
		If IndexOfStage <> 0 Then
			StepNumberOfStage = StepNumberOfStage + 1;
		EndIf;
		
		NameLines = New Array;
		If ByPoints Then
			NameLines.Add(StageString_.Number);
		Else
			NameLines.Add(StepNumberOfStage);
		EndIf;
		
		NameLines.Add(". ");
		StageString_.RowPrefix = StrConcat(NameLines);
		
		NameLines.Add(StageString_.StageName);
		StageString_.LinePresentation = StrConcat(NameLines);
		
		ParticipantsOfStage = StageString_.GetItems();
		
		For IndexOfParticipant = 0 To ParticipantsOfStage.Count() - 1 Do
			
			ParticipantLine = ParticipantsOfStage[IndexOfParticipant];
			
			ParticipantLine.RowPrefix = "";
			If ByPoints And ParticipantLine.Function = "PerformanceResultProcessor" Then
				ParticipantLine.RowPrefix = NStr("vi = '(Kiểm tra)';
												|ru = '(Провер.)';
												|en = '(Check.)'; fa = '(Check.)';
												|it = '(Провер.)';
												|pl = '(Check.)';
												|tr = '(Kontrol)'") + " ";
			EndIf;
			ParticipantLine.LinePresentation = IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(
				ParticipantLine,,
				ParticipantLine.RowPrefix);
			
			MembersAreSubsidiaries = ParticipantLine.GetItems();
			For IndexOfMemberOfSubsidiary = 0 To MembersAreSubsidiaries.Count() - 1 Do
				
				ChildMemberString = MembersAreSubsidiaries[IndexOfMemberOfSubsidiary];
				
				ChildMemberString.RowPrefix = "";
				ChildMemberString.LinePresentation = IntegrationWith1CDocumentManagement3ClientServer.ParticipantPresentation(
					ChildMemberString);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessWebServiceSResponseToReceivingAction(XDTOAction)
	
	// Fill in the general action data.
	IntegrationWith1CDocumentManagement3.ProcessWebServiceSResponseToReceivingAction(ThisObject, XDTOAction);
	
	// Fill in these execution actions.
	ByPoints = XDTOAction.byPoints;
	SignEPResolutions = XDTOAction.signResolutionsWithDS;
	ChangingActionIsAllowed = XDTOAction.changeAllowed;
	IntegrationWith1CDocumentManagement3.ParticipantOfActionDM(ThisObject, XDTOAction.controller, "Inspector");
	StateOfAction = "";
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOAction, "state") Then
		StateOfAction = XDTOAction.state;
	EndIf;
	
	// Update the action form.
	UpdateTreeOfParticipantsByObject(XDTOAction);
	IntegrationWith1CDocumentManagement3.EstablishVisibilityOfConditionsOfParticipantsInAction(ThisObject, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInStatesAndResultsInActionForm(ThisObject, XDTOAction);
	SetAvailabilityOfMemberChanges();
	Items.ExecutionByPoints.Check = ByPoints;
	
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
	XDTOAction.signResolutionsWithDS = SignEPResolutions;
	If ValueIsFilled(Inspector) Then
		DataController = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			InspectorID,
			InspectorType,
			Inspector);
		DataIsMainObjectOfAddressingController =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				MainAddressingObjectInspectorID,
				MainAddressingObjectInspectorType,
				MainAddressingObjectInspector);
		DataAdditionalAddressingObjectController =
			IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				AdditionalAddressingObjectControllerID,
				AdditionalAddressingObjectControllerType,
				AdditionalAddressingObjectController);
		XDTOAction.controller = IntegrationWith1CDocumentManagement3.ParticipantOfXDTOAction(
			Proxy,
			DataController,
			DataIsMainObjectOfAddressingController,
			DataAdditionalAddressingObjectController);
	EndIf;
	UpdateObjectInMemberTree(Proxy, XDTOAction);
	IntegrationWith1CDocumentManagement3.FillInTableOfParticipantsInAction(ThisObject.AttendeesBeforeWrite, XDTOAction);
	
	Return IntegrationWith1CDocumentManagementCore.XDTOObjectInString(Proxy, XDTOAction);
	
EndFunction

&AtServer
Procedure SetVisibilityAvailabilityOfFieldsByPoints(XDTOAction)
	
	Items.ProjectResolution.Visible = Not ByPoints;
	Items.SignEPResolutions.Visible = Not ByPoints;
	Items.AttendeesAddAPoint.Visible = ByPoints;
	Items.ContextAddItem.Visible = ByPoints;
	Items.ThereIsSpecialNameDescription.Visible = Not ByPoints;
	Items.ResolutionProcessingTimePresentation.Visible = SettingResolutionProcessingTimeIsAvailable And Not ByPoints;
	
	If ByPoints Then
		Items.LinePresentation.Title = NStr("vi = 'Mục, người tham gia';
											|ru = 'Пункты, участники';
											|en = 'Points, participants'; fa = 'Points, participants';
											|it = 'Пункты, участники';
											|pl = 'Points, participants';
											|tr = 'Maddeler, katılımcılar'");
	Else
		Items.LinePresentation.Title = NStr("vi = 'Người tham gia';
											|ru = 'Участники';
											|en = 'Participants'; fa = 'شرکت‌کنندگان';
											|it = 'Участники';
											|pl = 'Participants';
											|tr = 'Katılımcılar'");
	EndIf;
	
	Items.IsProtected.Visible = Not ByPoints;
	Items.AttendeesIsProtected.Visible = Not ByPoints;
	
	// If it is set from the settings, it cannot be changed.
	// We see the button only if the setting is set point by point.
	Items.ExecutionByPoints.Enabled = False;
	Items.ExecutionByPoints.Visible = ByPoints;
	
EndProcedure

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
		Items.SignEPResolutions.Enabled = False;
		Items.Inspector.Enabled = False;
		Items.GroupDescriptionOfDeferredExecution.Enabled = False;
	EndIf;
	
	If GeneralResolution = "AllowedToAdd" Then
		YouCanOnlyAddMembers = True;
	EndIf;
	
	StagesOfParticipants = Attendees.GetItems();
	For Each ParticipantsStage In StagesOfParticipants Do
		ParticipantsStage.Unavailable =
			GeneralResolution = "Forbidden"
			Or YouCanOnlyAddMembers
			// We forbid editing completed stages.
			Or (ParticipantsStage.Function <> "ReviewingPerson"
				And ParticipantsStage.State = "Completed"
				And Not ExecutionOfActionWithNewParticipants)
			Or (ParticipantsStage.Function = "ReviewingPerson"
				And Not ChangingActionIsAllowed
				And Not ExecutionOfActionWithNewParticipants);
		
		ParticipantsOfStage = ParticipantsStage.GetItems();
		For Each StageParticipant In ParticipantsOfStage Do
			If Not ValueIsFilled(StageParticipant.MemberID) And YouCanOnlyAddMembers Then
				StageParticipant.Unavailable = False;
			Else
				StageParticipant.Unavailable = ParticipantsStage.Unavailable Or StageParticipant.State = "Completed";
			EndIf;
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
		
		SettingResolutionProcessingTimeIsAvailable = True;
		If Not IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.17.36") Then
			SettingResolutionProcessingTimeIsAvailable = False;
			Items.DescriptionIsSpecial.Visible = False;
		EndIf;
		Items.ResolutionProcessingTimePresentation.Visible = SettingResolutionProcessingTimeIsAvailable;
		
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
		FillInPresentationOfResolutionProcessingDeadlines();
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
	
	If ByPoints Then
		ElementsStages = Attendees.GetItems();
		For Each ElementStage In ElementsStages Do
			// We do not allow you to save the stage in which the description is not entered.
			If ElementStage.StageName = BasicStageName Then
				ShowMessageBox(,StrTemplate(NStr("vi = 'Hãy chỉ ra nội dung của mục ""%1""';
												|ru = 'Укажите содержание пункта ""%1""';
												|en = 'Specify the ""%1"" point content'; fa = 'Specify the ""%1"" point content';
												|it = 'Укажите содержание пункта ""%1""';
												|pl = 'Specify the ""%1"" point content';
												|tr = '""%1"" maddesinin içeriğini belirtin'"), ElementStage.Number));
				Cancel = True;
				Return;
			EndIf;
			
			// We do not allow you to save a stage in which there are no participants.
			If PointWithoutParticipants(ElementStage) Then
				ShowMessageBox(,StrTemplate(NStr("vi = 'Hãy điền người tham gia mục ""%1""';
												|ru = 'Заполните участников пункта ""%1""';
												|en = 'Fill the ""%1"" point participants'; fa = 'Fill the ""%1"" point participants';
												|it = 'Заполните участников пункта ""%1""';
												|pl = 'Fill the ""%1"" point participants';
												|tr = '""%1"" maddesinin katılımcılarını doldurun'"), ElementStage.StageName));
				Cancel = True;
				Return;
			EndIf;
		EndDo;
	EndIf;
	
	If ExecutionOfActionWithNewParticipants
			And Not IntegrationWith1CDocumentManagement3ClientServer.ParticipantsOfActionHaveBeenChangedInCard(ThisObject) Then
		ShowMessageBox(,
			NStr("vi = 'Chưa thêm người tham gia mới.
				|Để khởi động việc thực hiện mới, hãy thêm người tham gia.';
				|ru = 'Новые участники не добавлены.
				|Для запуска нового исполнения добавьте участников.';
				|en = 'New participants are not added.
				|To start a new execution, add participants.'; fa = 'New participants are not added.
				|To start a new execution, add participants.';
				|it = 'Новые участники не добавлены.
				|Для запуска нового исполнения добавьте участников.';
				|pl = 'New participants are not added.
				|To start a new execution, add participants.';
				|tr = 'Yeni katılımcılar eklenmedi.
				|Yeni yürütme başlatmak için katılımcı ekleyin.'"));
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