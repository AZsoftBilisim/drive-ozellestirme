#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UploadExecutionSettingsToForm();
	
	If Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(IdOfPersonChecking) Then
		IdOfPersonChecking = String(New UUID);
	EndIf;
	
	SetAvailability();
	AdjustVisibilityOfControlsWhenCreatingForm();
	Commands.DifferentTerms.ToolTip = IntegrationWith1CDocumentManagement3.HintButtonsHaveDifferentExpirationDates(False, False);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FillInPresentationOfDeadlines();
	CalculateValueOfDifferentTerms();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorOfExecutionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagement3Client.SelectEmployeeFromDepartmentTree("AuthorOfExecution", ThisObject, True);
	
EndProcedure

&AtClient
Procedure AuthorOfExecutionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"AuthorOfExecution",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	
EndProcedure

&AtClient
Procedure AuthorOfExecutionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorOfExecutionTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"AuthorOfExecution",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorOfExecutionClearing(Item, StandardProcessing)
	
	AuthorOfExecution = "";
	AuthorOfExecutionID = "";
	AuthorOfExecutionType = "";
	AuthorOfExecutionPresentation = "";
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ExecutionControllerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ExecutionControllerStartChoiceCompletion", ThisObject);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook",,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ExecutionControllerStartChoiceCompletion(Result, NotificationParameters) Export
	
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
	
EndProcedure

&AtClient
Procedure ExecutionControllerChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ClearExecutionControllerField();
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
Procedure ExecutionControllerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecutionControllerTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			ClearExecutionControllerField();
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
Procedure ExecutionControllerClearing(Item, StandardProcessing)
	
	ClearExecutionControllerField();
	InspectorPresentation = IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
		Inspector,
		MainAddressingObjectInspector,
		AdditionalAddressingObjectController);
	Modified = True;
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("VerifierOfExecutionStartChoiceCompletion", ThisObject);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook",,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionStartChoiceCompletion(Result, NotificationParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", Supervisor);
	Result.Property("PerformerID", SupervisorID);
	Result.Property("PerformerType", SupervisorType);
	
	Result.Property("MainAddressingObject", MainAddressingObjectSupervisor);
	Result.Property("MainAddressingObjectID", MainAddressingObjectSupervisorID);
	Result.Property("MainAddressingObjectType", MainAddressingObjectSupervisorType);
	
	Result.Property("AdditionalAddressingObject", AdditionalAddressingObjectSupervisor);
	Result.Property("AdditionalAddressingObjectID", AdditionalAddressingObjectSupervisorID);
	Result.Property("AdditionalAddressingObjectType", AdditionalAddressingObjectSupervisorType);
	
	SupervisorPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			Supervisor,
			MainAddressingObjectSupervisor,
			AdditionalAddressingObjectSupervisor);
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ClearVerifierField();
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Supervisor",
		ValueSelected,
		StandardProcessing,
		ThisObject);
	SupervisorPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			Supervisor,
			MainAddressingObjectSupervisor,
			AdditionalAddressingObjectSupervisor);
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			ClearVerifierField();
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Supervisor",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject);
			SupervisorPresentation =
				IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
					Supervisor,
					MainAddressingObjectSupervisor,
					AdditionalAddressingObjectSupervisor);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure VerifierOfExecutionClearing(Item, StandardProcessing)
	
	ClearVerifierField();
	SupervisorPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			Supervisor,
			MainAddressingObjectSupervisor,
			AdditionalAddressingObjectSupervisor);
	Modified = True;
	
EndProcedure

&AtClient
Procedure DueDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If DueDate = OpeningDeadline Then
		Return;
	EndIf;
	
	TermChangeParameters = IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission();
	
	DueDatePresentation = Format(DueDate, NStr("vi = 'ДФ=''дд.ММ.гг ЧЧ:мм'';';
												|ru = 'ДФ=''dd.MM.yy HH:mm'';';
												|en = 'DF=''MM/dd/yy hh:mm tt'';'; fa = 'DF=''MM/dd/yy hh:mm tt'';';
												|it = 'ДФ=''дд.ММ.гг ЧЧ:мм'';';
												|pl = 'DF=''MM/dd/yy hh:mm tt'';';
												|tr = 'DF=''dd.MM.yy HH:mm'';'"));
	DueDate = Undefined;
	
	FillingResult = IntegrationWith1CDocumentManagement3ServerCall.ChangeDeadlineForExecutionByPresentation(
		DueDate,
		Term_Days,
		TermHours,
		TermMinutes,
		"ExactDate",
		DueDatePresentation,
		TermChangeParameters);
	
	If FillingResult Then
		For Each PerformersLine In PerformersOfExecution Do
			If PerformersLine.TaskDueDate = OpeningDeadline Then
				PerformersLine.TaskDueDate = DueDate;
			EndIf;
		EndDo;
		OpeningDeadline = DueDate;
		FillInPresentationOfDeadlines();
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.TextOfWarningMessage) Then
		IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,TermChangeParameters.TextOfWarningMessage);
	EndIf;
	
EndProcedure

&AtClient
Procedure DeadlineForProcessingResultsPresentationInCaseOfChanges(Item)
	
	TermChangeParameters = IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission();
	TermChangeParameters.Performer = Supervisor;
	TermChangeParameters.PerformerID = SupervisorID;
	TermChangeParameters.PerformerType = SupervisorType;
	TermChangeParameters.MainAddressingObjectPerformer = MainAddressingObjectSupervisor;
	TermChangeParameters.MainAddressingObjectPerformerID = MainAddressingObjectSupervisorID;
	TermChangeParameters.MainAddressingObjectPerformerType = MainAddressingObjectSupervisorType;
	TermChangeParameters.AdditionalAddressingObjectExecutor = AdditionalAddressingObjectSupervisor;
	TermChangeParameters.AdditionalAddressingObjectExecutorID = AdditionalAddressingObjectSupervisorID;
	TermChangeParameters.AdditionalAddressingObjectExecutorType = AdditionalAddressingObjectSupervisorType;
	
	FillingResult = IntegrationWith1CDocumentManagement3ServerCall.ChangeDeadlineForExecutionByPresentation(
		DeadlineForProcessingExecutionResults,
		DeadlineForProcessingResultsDaysOfExecution,
		ProcessingTimeOfResultsHoursOfExecution,
		ProcessingTimeOfResultsMinutesOfExecution,
		OptionForSettingDeadlineForProcessingExecutionResults,
		DeadlineForProcessingExecutionResultsPresentation,
		TermChangeParameters);
	
	If FillingResult Then
		FillInPresentationOfDeadlines();
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.TextOfWarningMessage) Then
		IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,TermChangeParameters.TextOfWarningMessage);
	EndIf;
	
EndProcedure

&AtClient
Procedure TermOfProcessingOfResultsPresentationRegulation(Item, Direction, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.ChangeRelativeTerm(
		DeadlineForProcessingResultsDaysOfExecution,
		ProcessingTimeOfResultsHoursOfExecution,
		ProcessingTimeOfResultsMinutesOfExecution,
		Direction);
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	OptionForSettingDeadlineForProcessingExecutionResults = OptionsForSettingDeadline.RelativeTerm;
	DeadlineForProcessingExecutionResults = Date(1,1,1);
	
	Modified = True;
	
	FillInPresentationOfDeadlines();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPerformersOfExecution

&AtClient
Procedure PerformersOfExecutionOnActivateRow(Item)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	LineViewOnly = ParticipantLineIsUnavailable(CurrentData);
	Items.AssigneesTaskDueDatePresentation.ReadOnly = LineViewOnly;
	Items.ButtonDifferentDates.Enabled = Not LineViewOnly And DifferentAvailabilityDates;
	Items.PerformersOfExecutionDescriptionIsSpecial.ReadOnly = LineViewOnly;
	
	StateIsComplete = (CurrentData.State = "Completed");
	
	Items.PerformersOfExecutionContextMenuAdd.Enabled = Not CurrentData.Unavailable
		Or YouCanOnlyAddMembers;
	Items.PerformersOfExecutionContextMenuDelete.Enabled = Not StateIsComplete
		And Not CurrentData.Unavailable And DifferentAvailabilityDates;
	
	Items.ExecutorsOfExecutionExecutor.ReadOnly = CurrentData.Unavailable;
	Items.ExecutorsOfExecutionExecutor.TextEdit = Not StateIsComplete And Not CurrentData.Unavailable;
	Items.ExecutorsOfExecutionExecutor.ChoiceButton = Not StateIsComplete And Not CurrentData.Unavailable;
	Items.MoveUp.Enabled = Not StateIsComplete And ChangeResponsiblePersonAvailability;
	Items.MoveDown.Enabled = Not StateIsComplete And ChangeResponsiblePersonAvailability;
	Items.AssignResponsible.Enabled =
		Not StateIsComplete And (PerformersOfExecution.Count() > 1) And ChangeResponsiblePersonAvailability;
	
	If Not EditionAllowed Then
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
		Items.PerformersOfExecution.ChangeRowOrder = YouCanOnlyAddMembers;
	EndIf;
	
	UpdateAvailabilityOfCommandsToMoveAndAssignResponsible();
	
EndProcedure

&AtClient
Procedure PerformersOfExecutionBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined
			And (CurrentData.State = "Completed" Or CurrentData.Unavailable Or Not DifferentAvailabilityDates) Then
		// Completed tasks, as well as actions "Allowed to add" cannot be deleted in the configuration mode.
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformersOfExecutionOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	
	If NewRow Then
		
		If PerformersOfExecution[0].EmployeeResponsible Then
			IndexOfFirstRow = 1;
		Else
			IndexOfFirstRow = 0;
		EndIf;
		
		RowOfFirstPerformer = PerformersOfExecution[IndexOfFirstRow];
		
		If RowOfFirstPerformer.OptionForSettingDueDate = "ExactDate" Then
			CurrentData.TaskDueDate = RowOfFirstPerformer.TaskDueDate;
		Else
			CurrentData.DueDateDays = RowOfFirstPerformer.DueDateDays;
			CurrentData.DueDateHours = RowOfFirstPerformer.DueDateHours;
			CurrentData.ExecutionTimeMinutes = RowOfFirstPerformer.ExecutionTimeMinutes;
		EndIf;
		
		CurrentData.OptionForSettingDueDate = RowOfFirstPerformer.OptionForSettingDueDate;
		
		CurrentData.TaskDueDatePresentation =
			IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
				CurrentData.TaskDueDate,
				CurrentData.DueDateDays,
				CurrentData.DueDateHours,
				CurrentData.ExecutionTimeMinutes,
				UseDateAndTimeInTaskDeadlines,
				CurrentData.OptionForSettingDueDate);
		
	EndIf;
	
	If ValueIsFilled(DueDate)
			And Not ValueIsFilled(CurrentData.TaskDueDate)
			And Not ValueIsFilled(CurrentData.DueDateDays)
			And Not ValueIsFilled(CurrentData.DueDateHours)
			And Not ValueIsFilled(CurrentData.ExecutionTimeMinutes) Then
		CurrentData.TaskDueDate = DueDate;
		CurrentData.OptionForSettingDueDate = "ExactDate";
		
		CurrentData.TaskDueDatePresentation =
			IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
				CurrentData.TaskDueDate,
				CurrentData.DueDateDays,
				CurrentData.DueDateHours,
				CurrentData.ExecutionTimeMinutes,
				UseDateAndTimeInTaskDeadlines,
				CurrentData.OptionForSettingDueDate);
	EndIf;
	
	UpdateAvailabilityOfCommandsToMove();
	
EndProcedure

&AtClient
Procedure PerformersOfExecutionAfterDeleteRow(Item)
	
	If PerformersOfExecution.Count() = 1 And PerformersOfExecution[0].EmployeeResponsible Then
		AssignExecutorResponsible();
	Else
		UpdateAvailabilityOfCommandsToMoveAndAssignResponsible();
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformersOfExecutionDragEnd(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

// Performer field

&AtClient
Procedure ExecutorOfExecutionWhenChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure PerformerOfPerformanceBeginningOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined And CurrentData.State = "Completed" Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("PerformerOfPerformanceBeginningOfSelectionCompletion", ThisObject, CurrentData);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.AddressBook",,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Handler for the execution eventthe initial completion.
//
// Parameters:
//   Result - Structure:
//     * Performer - String
//     * PerformerID - String
//     * PerformerType - String
//     * MainAddressingObject - String
//     * MainAddressingObjectID - String
//     * MainAddressingObjectType - String
//     * AdditionalAddressingObject - String
//     * AdditionalAddressingObjectID - String
//     * AdditionalAddressingObjectType - String
//   CurrentData - FormDataTreeItem
//
&AtClient
Procedure PerformerOfPerformanceBeginningOfSelectionCompletion(Result, CurrentData) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Result.Property("Performer", CurrentData.Performer);
	Result.Property("PerformerID", CurrentData.PerformerID);
	Result.Property("PerformerType", CurrentData.PerformerType);
	
	Result.Property("MainAddressingObject", CurrentData.MainAddressingObjectPerformer);
	Result.Property("MainAddressingObjectID", CurrentData.MainAddressingObjectPerformerID);
	Result.Property("MainAddressingObjectType", CurrentData.MainAddressingObjectPerformerType);
	
	Result.Property("AdditionalAddressingObject", CurrentData.AdditionalAddressingObjectExecutor);
	Result.Property("AdditionalAddressingObjectID", CurrentData.AdditionalAddressingObjectExecutorID);
	Result.Property("AdditionalAddressingObjectType", CurrentData.AdditionalAddressingObjectExecutorType);
	
	CurrentData.PerformerPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Performer,
			CurrentData.MainAddressingObjectPerformer,
			CurrentData.AdditionalAddressingObjectExecutor);
	
EndProcedure

&AtClient
Procedure ExecutorOfExecutionCleaning(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined And CurrentData.State = "Completed" Then
		Return;
	EndIf;
	
	ClearPerformerField(CurrentData);
	CurrentData.PerformerPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Performer,
			CurrentData.MainAddressingObjectPerformer,
			CurrentData.AdditionalAddressingObjectExecutor);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ExecutionExecutorSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined And CurrentData.State = "Completed" Then
		Return;
	EndIf;
	
	ClearPerformerField(CurrentData);
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Performer",
		ValueSelected,
		StandardProcessing,
		ThisObject,
		True,
		Item);
	CurrentData.PerformerPresentation =
		IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
			CurrentData.Performer,
			CurrentData.MainAddressingObjectPerformer,
			CurrentData.AdditionalAddressingObjectExecutor);
	
EndProcedure

&AtClient
Procedure ExecutorOfExecutionAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting,
		StandardProcessing)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined And CurrentData.State = "Completed" Then
		Return;
	EndIf;
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerOfPerformanceEndOfTextInput(Item, Text, ChoiceData, DataGetParameters,
		StandardProcessing)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData <> Undefined And CurrentData.State = "Completed" Then
		Return;
	EndIf;
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			"DMEmployee",
			ChoiceData,
			Text,
			StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			ClearPerformerField(CurrentData);
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Performer",
				ChoiceData[0].Value,
				StandardProcessing,
				ThisObject,
				True,
				Item);
			CurrentData.PerformerPresentation =
				IntegrationWith1CDocumentManagementCoreClientServer.PresentationOfTaskParticipant(
					CurrentData.Performer,
					CurrentData.MainAddressingObjectPerformer,
					CurrentData.AdditionalAddressingObjectExecutor);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

// Field executerisroperformance Representation

&AtClient
Procedure AssigneesTaskDueDatePresentationOnChange(Item)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	
	TermChangeParameters = IntegrationWith1CDocumentManagement3ClientServer.ParametersForChangingDeadlineForSubmission();
	FillPropertyValues(TermChangeParameters, CurrentData);
	
	FillingResult = IntegrationWith1CDocumentManagement3ServerCall.ChangeDeadlineForExecutionByPresentation(
		CurrentData.TaskDueDate,
		CurrentData.DueDateDays,
		CurrentData.DueDateHours,
		CurrentData.ExecutionTimeMinutes,
		CurrentData.OptionForSettingDueDate,
		CurrentData.TaskDueDatePresentation,
		TermChangeParameters);
	
	If FillingResult Then
		If Not DifferentTerms Then
			FillInDeadlinesInPerformersTableForCurrentLine(CurrentData);
		EndIf;
		FillInPresentationOfDeadlines();
	EndIf;
	
	If ValueIsFilled(TermChangeParameters.TextOfWarningMessage) Then
		IntegrationWith1CDocumentManagement3Client.ShowWarningFromBEFORE(,TermChangeParameters.TextOfWarningMessage);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssigneesTaskDueDatePresentationTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.ChangeRelativeTerm(
		CurrentData.DueDateDays,
		CurrentData.DueDateHours,
		CurrentData.ExecutionTimeMinutes,
		Direction);
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	CurrentData.OptionForSettingDueDate = OptionsForSettingDeadline.RelativeTerm;
	CurrentData.TaskDueDate = Date(1,1,1);
	
	Modified = True;
	
	If Not DifferentTerms Then
		FillInDeadlinesInPerformersTableForCurrentLine(CurrentData);
	EndIf;
	FillInPresentationOfDeadlines();
	
EndProcedure

// The field of the executor of the execution description is special

&AtClient
Procedure PerformersOfExecutionDescriptionIsSpecialStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("LongDesc", CurrentData.DescriptionIsSpecial);
	FormParameters.Insert("JustDescription", True);
	FormParameters.Insert("ReadOnly", ParticipantLineIsUnavailable(CurrentData));
	CallbackDescription = New CallbackDescription("FinishSettingUpSpecialDescription", ThisObject, CurrentData);
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagement3.Form.EditSpecialTaskDescriptionAndDetails",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveUp(Command)
	
	MoveArtist(-1);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	MoveArtist(1);
	
EndProcedure

&AtClient
Procedure AssignResponsible(Command)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.State = "Completed" Then
		ShowMessageBox(,
			NStr("vi = 'Nhân viên đã hoàn tất nhiệm vụ của mình.
				|Không nên thay đổi dấu hiệu ""Người chịu trách nhiệm"".';
				|ru = 'Сотрудник завершил свою задачу.
				|Изменить признак ""Ответственный"" нельзя.';
				|en = 'The employee completed their task.
				|Cannot change the ""Responsible"" checkbox.'; fa = 'The employee completed their task.
				|Cannot change the ""Responsible"" checkbox.';
				|it = 'Сотрудник завершил свою задачу.
				|Изменить признак ""Ответственный"" нельзя.';
				|pl = 'The employee completed their task.
				|Cannot change the ""Responsible"" checkbox.';
				|tr = 'Çalışan kendi görevini tamamladı.
				|""Sorumlu"" işareti değiştirilemez.'"));
		Return;
	EndIf;
	
	AssignExecutorResponsible();
	
EndProcedure

&AtClient
Procedure DifferentTerms(Command)
	
	DifferentTerms = Not DifferentTerms;
	Items.ButtonDifferentDates.Check = DifferentTerms;
	If Not DifferentTerms Then
		
		// Put the same deadline back on all lines:
		For Each PerformerRow In PerformersOfExecution Do
			If PerformerRow.EmployeeResponsible Then
				Continue;
			EndIf;
			
			FillInDeadlinesInPerformersTableForCurrentLine(PerformerRow);
			Modified = True;
			Break;
		EndDo;
		If Modified Then
			FillInPresentationOfDeadlines();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	Cancel = False;
	
	PrepareSettingsForExecutionOfFamiliarizationForRecording();
	ClearMessages();
	
	If IsBlankString(PointNumber) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Số mục""';
				|ru = 'Поле ""№ пункта"" не заполнено';
				|en = 'The ""Point No."" field is not filled'; fa = 'The ""Point No."" field is not filled';
				|it = 'Поле ""№ пункта"" не заполнено';
				|pl = 'The ""Point No."" field is not filled';
				|tr = '""Madde numarası"" alanı doldurulmadı'"),,
			"PointNumber",, Cancel);
	EndIf;
	If IsBlankString(DescriptionOfExecution) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Nội dung mục""';
				|ru = 'Поле ""Содержание пункта"" не заполнено';
				|en = 'The ""Point content"" field is not filled'; fa = 'The ""Point content"" field is not filled';
				|it = 'Поле ""Содержание пункта"" не заполнено';
				|pl = 'The ""Point content"" field is not filled';
				|tr = '""Madde içeriği"" alanı doldurulmadı'"),,
			"DescriptionExecution",, Cancel);
	EndIf;
	// Checking the presence of one responsible execution in the list.
	If PerformersOfExecution.Count() = 1 And PerformersOfExecution[0].EmployeeResponsible Then
		CommonClient.MessageToUser(
			NStr("vi = 'Người thực hiện duy nhất không thể là người chịu trách nhiệm.';
				|ru = 'Единственный исполнитель не может быть ответственным.';
				|en = 'A single assignee cannot be responsible.'; fa = 'A single assignee cannot be responsible.';
				|it = 'Единственный исполнитель не может быть ответственным.';
				|pl = 'A single assignee cannot be responsible.';
				|tr = 'Tek atanan sorumlu kişi olamaz.'"),,
			"PerformersOfExecution[0].Performer",,
			Cancel);
	EndIf;
	If PerformersOfExecution.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa nhập bất kỳ dòng nào vào danh sách ""Người thực hiện""';
				|ru = 'Не введено ни одной строки в список ""Исполнители""';
				|en = 'The ""Assignees"" list is empty'; fa = 'The ""Assignees"" list is empty';
				|it = 'Не введено ни одной строки в список ""Исполнители""';
				|pl = 'The ""Assignees"" list is empty';
				|tr = '""Atananlar"" listesine hiçbir satır girilmedi'"),,
			"PerformersOfExecution",, Cancel);
	EndIf;
	
	For Each String In PerformersOfExecution Do
		If Not ValueIsFilled(String.PerformerID) Then
			IndexOf = PerformersOfExecution.IndexOf(String);
			ErrorText = StrTemplate(
				NStr("vi = 'Chưa điền cột ""Người thực hiện"" trong dòng %1 của danh sách ""Người thực hiện""';
					|ru = 'Не заполнена колонка ""Исполнитель"" в строке %1 списка ""Исполнители""';
					|en = 'The ""Assignee"" column is not filled in line %1 of the ""Assignees"" list'; fa = 'The ""Assignee"" column is not filled in line %1 of the ""Assignees"" list';
					|it = 'Не заполнена колонка ""Исполнитель"" в строке %1 списка ""Исполнители""';
					|pl = 'The ""Assignee"" column is not filled in line %1 of the ""Assignees"" list';
					|tr = '""Atananlar"" listesinin %1 satırındaki ""Atanan"" sütunu doldurulmadı'"),
				IndexOf + 1);
			CommonClient.MessageToUser(
				ErrorText,,
				StrTemplate("PerformersOfExecution[%1].Performer", IndexOf),,
				Cancel);
		EndIf;
	EndDo;
	
	If Cancel Then
		Return;
	EndIf;
	
	Close(PreparePointDataIntoAction());
	
EndProcedure

&AtClient
Procedure ContinueDialogue(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure AppointYourselfAsSupervisor(Command)
	
	ClearVerifierField();
	InstallYourselfAsCheckerOnServer();
	Modified = True;
	
EndProcedure

#EndRegion

#Region Private

#Region Client

#Region Deadlines

&AtClient
Procedure FillInPresentationOfDeadlines()
	
	For Each StageParticipant In PerformersOfExecution Do
		StageParticipant.TaskDueDatePresentation =
			IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
				StageParticipant.TaskDueDate,
				StageParticipant.DueDateDays,
				StageParticipant.DueDateHours,
				StageParticipant.ExecutionTimeMinutes,
				UseDateAndTimeInTaskDeadlines,
				StageParticipant.OptionForSettingDueDate);
	EndDo;
	
	DeadlineForProcessingExecutionResultsPresentation =
		IntegrationWith1CDocumentManagement3ClientServer.PresentationOfDeadline(
			DeadlineForProcessingExecutionResults,
			DeadlineForProcessingResultsDaysOfExecution,
			ProcessingTimeOfResultsHoursOfExecution,
			ProcessingTimeOfResultsMinutesOfExecution,
			UseDateAndTimeInTaskDeadlines,
			OptionForSettingDeadlineForProcessingExecutionResults);
	
EndProcedure

&AtClient
Procedure FillInDeadlinesInPerformersTableForCurrentLine(PerformerRow)
	
	NumberOfPerformers = PerformersOfExecution.Count();
	
	If NumberOfPerformers = 0 Or PerformerRow.EmployeeResponsible Then
		Return;
	EndIf;
	
	OptionsForSettingDeadline = IntegrationWith1CDocumentManagement3ClientServer.OptionsForSettingDueDate();
	
	OptionForSettingDueDate = PerformerRow.OptionForSettingDueDate;
	
	If OptionForSettingDueDate = OptionsForSettingDeadline.Exact_Date Then
		TaskDueDate = PerformerRow.TaskDueDate;
		DueDateDays = 0;
		DueDateHours = 0;
		ExecutionTimeMinutes = 0;
	Else
		TaskDueDate = Date(1,1,1);
		DueDateDays = PerformerRow.DueDateDays;
		DueDateHours = PerformerRow.DueDateHours;
		ExecutionTimeMinutes = PerformerRow.ExecutionTimeMinutes;
	EndIf;
	
	If DifferentTerms Then
		PerformerRow.TaskDueDate = TaskDueDate;
		PerformerRow.DueDateDays = DueDateDays;
		PerformerRow.DueDateHours = DueDateHours;
		PerformerRow.ExecutionTimeMinutes = ExecutionTimeMinutes;
		PerformerRow.OptionForSettingDueDate = OptionForSettingDueDate;
	Else
		IndexOfFirstRow = 0;
		If PerformersOfExecution[0].EmployeeResponsible Then
			IndexOfFirstRow = 1;
		EndIf;
		
		For CurrentRowIndex = IndexOfFirstRow To NumberOfPerformers - 1 Do
			CurrentRow = PerformersOfExecution[CurrentRowIndex];
			
			If ParticipantLineIsUnavailable(CurrentRow) Then
				Continue;
			EndIf;
			
			CurrentRow.TaskDueDate = TaskDueDate;
			CurrentRow.DueDateDays = DueDateDays;
			CurrentRow.DueDateHours = DueDateHours;
			CurrentRow.ExecutionTimeMinutes = ExecutionTimeMinutes;
			CurrentRow.OptionForSettingDueDate = OptionForSettingDueDate;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateValueOfDifferentTerms()
	
	PreviousTerm = Undefined;
	For Each ParticipantLine In PerformersOfExecution Do
		If Not ParticipantLine.EmployeeResponsible
				And PreviousTerm <> Undefined
				And PreviousTerm <> ParticipantLine.TaskDueDatePresentation Then
			DifferentTerms = True;
			Items.ButtonDifferentDates.Check = True;
			Return;
		EndIf;
		If Not ParticipantLine.EmployeeResponsible Then
			PreviousTerm = ParticipantLine.TaskDueDatePresentation;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

// Continuation of the execution procedure description of the special selection task.
//
// Parameters:
//   DetailsStructure1 - Structure - returned from the description editing Form:
//     * DescriptionIsSpecial - String
//   ParticipantLine - FormDataCollectionItem - participant string with fields:
//     * DescriptionIsSpecial - String
//
&AtClient
Procedure FinishSettingUpSpecialDescription(DetailsStructure1, ParticipantLine) Export
	
	If DetailsStructure1 = Undefined Then
		Return;
	EndIf;
	
	ParticipantLine.DescriptionIsSpecial = DetailsStructure1.LongDesc;
	Modified = True;
	
EndProcedure

&AtClient
Procedure AssignExecutorResponsible()
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.EmployeeResponsible = Not CurrentData.EmployeeResponsible;
	
	CurrentRowID = CurrentData.GetID();
	For Each PerformerRow In PerformersOfExecution Do
		If PerformerRow.GetID() = CurrentRowID Then
			Continue;
		EndIf;
		PerformerRow.EmployeeResponsible = False;
	EndDo;
	
	If CurrentData.EmployeeResponsible Then
		RowIndex = PerformersOfExecution.IndexOf(CurrentData);
		If RowIndex Then
			PerformersOfExecution.Move(RowIndex, - RowIndex);
		EndIf;
	EndIf;
	
	Items.AssignResponsible.Check = CurrentData.EmployeeResponsible;
	Modified = True;
	
	UpdateAvailabilityOfCommandsToMoveAndAssignResponsible();
	
	ClearMessages();
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfCommandsToMove()
	
	Items.MoveUp.Enabled = False;
	Items.MoveDown.Enabled = False;
	
	If Not Items.PerformersOfExecution.ChangeRowOrder Then
		Return;
	EndIf;
	
	NumberOfPerformers = PerformersOfExecution.Count();
	
	If NumberOfPerformers = 0 Then
		Return;
	EndIf;
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentIndexOfArtist = PerformersOfExecution.IndexOf(CurrentData);
	LineNumber = CurrentIndexOfArtist + 1;
	
	If LineNumber >= 2 Then
		Items.MoveUp.Enabled = Not PerformersOfExecution[CurrentIndexOfArtist - 1].Unavailable;
	EndIf;
	
	If LineNumber = 1 And NumberOfPerformers > 1 Or LineNumber > 1 And LineNumber < NumberOfPerformers Then
		Items.MoveDown.Enabled = Not PerformersOfExecution[CurrentIndexOfArtist + 1].Unavailable;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfCommandsToMoveAndAssignResponsible()
	
	Items.MoveUp.Enabled = False;
	Items.MoveDown.Enabled = False;
	Items.AssignResponsible.Enabled = False;
	
	If Not Items.PerformersOfExecution.ChangeRowOrder Then
		Return;
	EndIf;
	
	Items.AssignResponsible.Check = False;
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	NumberOfPerformers = PerformersOfExecution.Count();
	
	If NumberOfPerformers = 0 Then
		Return;
	EndIf;
	
	If PerformersOfExecution[0].EmployeeResponsible Then
		UpperBound = 2;
		MinimumNumberOfPerformersToChangeOrder = 3;
	Else
		UpperBound = 1;
		MinimumNumberOfPerformersToChangeOrder = 2;
	EndIf;
	
	LowerBound = NumberOfPerformers;
	
	// We get the line number by index, because the execution executor may not have a line number field.
	CurrentIndexOfArtist = PerformersOfExecution.IndexOf(CurrentData);
	LineNumber = CurrentIndexOfArtist + 1;
	FollowingIsAvailable = (LineNumber + 1) <= LowerBound
		And Not PerformersOfExecution[CurrentIndexOfArtist + 1].Unavailable;
	PreviousOneIsAvailable = (LineNumber - 1) >= UpperBound
		And Not PerformersOfExecution[CurrentIndexOfArtist - 1].Unavailable;
	
	If NumberOfPerformers >= MinimumNumberOfPerformersToChangeOrder Then
		
		If LineNumber < UpperBound Then
			// We don't do anything.
		ElsIf LineNumber = UpperBound Then
			Items.MoveDown.Enabled = FollowingIsAvailable;
		ElsIf LineNumber = LowerBound Then
			Items.MoveUp.Enabled = PreviousOneIsAvailable;
		Else
			Items.MoveUp.Enabled = PreviousOneIsAvailable;
			Items.MoveDown.Enabled = FollowingIsAvailable;
		EndIf;
		
	EndIf;
	
	If Not ChangeResponsiblePersonAvailability Then
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
	EndIf;
	
	Items.AssignResponsible.Check = CurrentData.EmployeeResponsible;
	SelectionOfResponsiblePersonSAvailability = New Structure("EmployeeResponsible, Unavailable", True, True);
	Items.AssignResponsible.Enabled = NumberOfPerformers > 1
		And Not PerformersOfExecution.FindRows(SelectionOfResponsiblePersonSAvailability).Count()
		And Not CurrentData.Unavailable
		And ChangeResponsiblePersonAvailability;
	
EndProcedure

&AtClient
Procedure ClearPerformerField(CurrentData)
	
	CurrentData.Performer = "";
	CurrentData.PerformerID = "";
	CurrentData.PerformerType = "";
	
	CurrentData.MainAddressingObjectPerformer = "";
	CurrentData.MainAddressingObjectPerformerID = "";
	CurrentData.MainAddressingObjectPerformerType = "";
	
	CurrentData.AdditionalAddressingObjectExecutor = "";
	CurrentData.AdditionalAddressingObjectExecutorID = "";
	CurrentData.AdditionalAddressingObjectExecutorType = "";
	
EndProcedure

&AtClient
Procedure ClearExecutionControllerField()
	
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
Procedure ClearVerifierField()
	
	Supervisor = "";
	SupervisorID = "";
	SupervisorType = "";
	
	MainAddressingObjectSupervisor = "";
	MainAddressingObjectSupervisorID = "";
	MainAddressingObjectSupervisorType = "";
	
	AdditionalAddressingObjectSupervisor = "";
	AdditionalAddressingObjectSupervisorID = "";
	AdditionalAddressingObjectSupervisorType = "";
	
EndProcedure

&AtClient
Procedure MoveArtist(Offset)
	
	CurrentData = Items.PerformersOfExecution.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Text = NStr("vi = 'Không thể điều chuyển. Có thể ấn định chỉ người thực hiện đầu tiên trong danh sách làm người chịu trách nhiệm.';
				|ru = 'Перемещение невозможно. Ответственным может быть назначен только первый исполнитель в списке.';
				|en = 'Cannot transfer. Only the first assignee in the list can be set as responsible.'; fa = 'Cannot transfer. Only the first assignee in the list can be set as responsible.';
				|it = 'Перемещение невозможно. Ответственным может быть назначен только первый исполнитель в списке.';
				|pl = 'Cannot transfer. Only the first assignee in the list can be set as responsible.';
				|tr = 'Transfer mümkün değildir. Sadece listedeki ilk atanan sorumlu olarak atanabilir.'");
	
	LineNumber = PerformersOfExecution.IndexOf(CurrentData) + 1;
	
	If Offset > 0 Then
		If LineNumber = PerformersOfExecution.Count() Then
			Return;
		EndIf;
		If LineNumber = 1
			And CurrentData.EmployeeResponsible Then
			
			CommonClient.MessageToUser(Text);
			Return;
		EndIf;
	Else
		If LineNumber = 1 Then
			Return;
		EndIf;
		If LineNumber = 2
			And PerformersOfExecution[0].EmployeeResponsible Then
			
			CommonClient.MessageToUser(Text);
			Return;
		EndIf;
	EndIf;
	
	PerformersOfExecution.Move(LineNumber - 1, Offset);
	
	Modified = True;
	
	FillInPresentationOfDeadlines();
	
	UpdateAvailabilityOfCommandsToMoveAndAssignResponsible();
	
	IndexOfModifiedRow = PerformersOfExecution.IndexOf(CurrentData);
	If Offset > 0 Then
		IndexOfModifiedRow = IndexOfModifiedRow - 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure PrepareSettingsForExecutionOfFamiliarizationForRecording()
	
	For Each TableRow In PerformersOfExecution Do
		If Not IntegrationWith1CDocumentManagement3ClientServer.IdFilledIn(
				TableRow.AssigneeID) Then
			TableRow.AssigneeID = String(New UUID);
		EndIf;
	EndDo;
	
	DeleteEmptyArtistLines();
	
EndProcedure

// Indicates that the row is unavailable, Overridable for this type of participant action.
// Called for rows with participants, i.e. the "lower" level of the tree.
// 
// Parameters:
//  TableRow - FormDataCollectionItem -
// 
// Returns:
//  Boolean - Indicates that the string should be unavailable.
&AtClient
Function ParticipantLineIsUnavailable(TableRow)
	
	ThisIsFirstElement = (PerformersOfExecution.IndexOf(TableRow) = 0);
	
	Return ReadOnly Or TableRow.Unavailable Or YouCanOnlyAddMembers And Not ThisIsFirstElement;
	
EndFunction

&AtClient
Procedure DeleteEmptyArtistLines()
	
	RowsCount = PerformersOfExecution.Count();
	For IndexOf = 1 To RowsCount Do
		String = PerformersOfExecution[RowsCount - IndexOf];
		
		If Not ValueIsFilled(String.PerformerID) Then
			PerformersOfExecution.Delete(String);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure UploadExecutionSettingsToForm()
	
	// customization.
	EditionAllowed = Parameters.EditionAllowed;
	YouCanOnlyAddMembers = Parameters.YouCanOnlyAddMembers;
	SuperiorMemberOrPoint = Parameters.Point_Id;
	UseDateAndTimeInTaskDeadlines = Parameters.UseDateAndTimeInTaskDeadlines;
	
	// data.
	PointNumber = Parameters.Number;
	DescriptionOfExecution = Parameters.DescriptionOfExecution;
	DueDate = Parameters.DueDate;
	OpeningDeadline = DueDate;
	
	// Author.
	AuthorOfExecution = Parameters.AuthorOfExecution;
	AuthorOfExecutionID = Parameters.AuthorOfExecutionID;
	AuthorOfExecutionType = Parameters.AuthorOfExecutionType;
	AuthorOfExecutionPresentation = Parameters.AuthorOfExecutionPresentation;
	
	// The controller.
	Inspector = Parameters.Inspector;
	InspectorID = Parameters.InspectorID;
	InspectorType = Parameters.InspectorType;
	InspectorPresentation = Parameters.InspectorPresentation;
	MainAddressingObjectInspector = Parameters.MainAddressingObjectInspector;
	MainAddressingObjectInspectorID = Parameters.MainAddressingObjectInspectorID;
	MainAddressingObjectInspectorType = Parameters.MainAddressingObjectInspectorType;
	AdditionalAddressingObjectController = Parameters.AdditionalAddressingObjectController;
	AdditionalAddressingObjectControllerID = Parameters.AdditionalAddressingObjectControllerID;
	AdditionalAddressingObjectControllerType = Parameters.AdditionalAddressingObjectControllerType;
	
	For Each String In Parameters.PerformersOfExecution Do
		
		If String.Function <> "PerformanceResultProcessor" Then
			// Performers.
			NewRow = PerformersOfExecution.Add();
			
			// Participant data.
			NewRow.AssigneeID = String.AssigneeID;
			NewRow.OptionForSettingDueDate = String.OptionForSettingDueDate;
			NewRow.EmployeeResponsible = String.EmployeeResponsible;
			
			// The participant.
			NewRow.Performer = String.Performer;
			NewRow.PerformerID = String.PerformerID;
			NewRow.PerformerType = String.PerformerType;
			NewRow.PerformerPresentation = String.PerformerPresentation;
			NewRow.MainAddressingObjectPerformer = String.MainAddressingObjectPerformer;
			NewRow.MainAddressingObjectPerformerID = String.MainAddressingObjectPerformerID;
			NewRow.MainAddressingObjectPerformerType = String.MainAddressingObjectPerformerType;
			NewRow.AdditionalAddressingObjectExecutor = String.AdditionalAddressingObjectExecutor;
			NewRow.AdditionalAddressingObjectExecutorID = String.AdditionalAddressingObjectExecutorID;
			NewRow.AdditionalAddressingObjectExecutorType = String.AdditionalAddressingObjectExecutorType;
			
			// Term.
			NewRow.TaskDueDate = String.TaskDueDate;
			NewRow.DueDateDays = String.DueDateDays;
			NewRow.DueDateHours = String.DueDateHours;
			NewRow.ExecutionTimeMinutes = String.ExecutionTimeMinutes;
			
			// Other data.
			NewRow.Unavailable = Not EditionAllowed Or YouCanOnlyAddMembers;
			NewRow.State = String.State;
			NewRow.PictureNumber = String.PictureNumber;
			NewRow.Result = String.Result;
			
		Else
			// The examiner.
			
			// Participant data.
			IdOfPersonChecking = String.AssigneeID;
			OptionForSettingDeadlineForProcessingExecutionResults = String.OptionForSettingDueDate;
			
			// The participant.
			Supervisor = String.Performer;
			SupervisorID = String.PerformerID;
			SupervisorType = String.PerformerType;
			SupervisorPresentation = String.PerformerPresentation;
			MainAddressingObjectSupervisor = String.MainAddressingObjectPerformer;
			MainAddressingObjectSupervisorID = String.MainAddressingObjectPerformerID;
			MainAddressingObjectSupervisorType = String.MainAddressingObjectPerformerType;
			AdditionalAddressingObjectSupervisor = String.AdditionalAddressingObjectExecutor;
			AdditionalAddressingObjectSupervisorID = String.AdditionalAddressingObjectExecutorID;
			AdditionalAddressingObjectSupervisorType = String.AdditionalAddressingObjectExecutorType;
			
			// The verification period.
			DeadlineForProcessingExecutionResults = String.TaskDueDate;
			DeadlineForProcessingResultsDaysOfExecution = String.DueDateDays;
			ProcessingTimeOfResultsHoursOfExecution = String.DueDateHours;
			ProcessingTimeOfResultsMinutesOfExecution = String.ExecutionTimeMinutes;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AdjustVisibilityOfControlsWhenCreatingForm()
	
	Items.ContinueDialogue.Visible = False;
	
	InputHint = NStr("vi = 'Nội dung mục';
					|ru = 'Содержание пункта';
					|en = 'Point content'; fa = 'Point content';
					|it = 'Содержание пункта';
					|pl = 'Point content';
					|tr = 'Madde içeriği'");
	Items.DescriptionExecution.InputHint = InputHint;
	Items.DescriptionExecution.ToolTip = InputHint;
	Items.DescriptionExecution.AutoMarkIncomplete = True;
	Items.DescriptionExecution.ChoiceButton = False;
	Title = NStr("vi = 'Địa điểm';
				|ru = 'Пункт';
				|en = 'Point'; fa = 'نقطه';
				|it = 'Пункт';
				|pl = 'Point';
				|tr = 'Madde'");
	Items.PerformersOfExecutionDescriptionIsSpecial.Visible = False;
	
	If ValueIsFilled(PointNumber) Then
		CurrentItem = Items.DescriptionExecution;
	EndIf;
	
	Items.PerformersOfExecutionPictureNumber.Visible = False;
	For Each PerformerRow In PerformersOfExecution Do
		If PerformerRow.PictureNumber > 0 Then
			Items.PerformersOfExecutionPictureNumber.Visible = True;
			Break;
		EndIf;
	EndDo;
	
	Items.FormClose.Visible = False;
	
	If Not EditionAllowed Then
		If YouCanOnlyAddMembers Then
			Items.FormWrite.Visible = True;
		Else
			Items.FormWrite.Visible = False;
			Items.FormClose.Visible = True;
			Items.FormClose.DefaultButton = True;
		EndIf;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.14.31") Then
		Items.AuthorOfExecution.Visible = False;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.17.36") Then
		Items.PerformersOfExecutionDescriptionIsSpecial.Visible = False;
	EndIf;
	
EndProcedure

// Returns the structure of parameters for the participant of the execution point.
//
// Returns:
//   Structure:
//     * Member - String
//     * MemberID - String
//     * MemberType - String
//     * MemberPresentation - String
//     * MainAddressingObjectMember - String
//     * MainAddressingObjectMemberID - String
//     * MainAddressingObjectMemberType - String
//     * AdditionalAddressingObjectParticipant - String
//     * AdditionalAddressingObjectParticipantID - String
//     * AdditionalAddressingObjectParticipantType - String
//     * Id - String
//     * EmployeeResponsible - Boolean
//     * DueDate - Date
//     * Term_Days - Number
//     * TermHours - Number
//     * TermMinutes - Number
//     * OptionForSettingDeadline - String
//     * Function - String
//
&AtServer
Function ParameterOfParticipantOfExecutionPoint()
	
	ParticipantParameters = New Structure;
	ParticipantParameters.Insert("Member", "");
	ParticipantParameters.Insert("MemberID", "");
	ParticipantParameters.Insert("MemberType", "");
	ParticipantParameters.Insert("MemberPresentation", "");
	ParticipantParameters.Insert("MainAddressingObjectMember", "");
	ParticipantParameters.Insert("MainAddressingObjectMemberID", "");
	ParticipantParameters.Insert("MainAddressingObjectMemberType", "");
	ParticipantParameters.Insert("AdditionalAddressingObjectParticipant", "");
	ParticipantParameters.Insert("AdditionalAddressingObjectParticipantID", "");
	ParticipantParameters.Insert("AdditionalAddressingObjectParticipantType", "");
	ParticipantParameters.Insert("Id", "00000000-0000-0000-0000-000000000000");
	ParticipantParameters.Insert("EmployeeResponsible", False);
	ParticipantParameters.Insert("DueDate", Date(1,1,1));
	ParticipantParameters.Insert("Term_Days", 0);
	ParticipantParameters.Insert("TermHours", 0);
	ParticipantParameters.Insert("TermMinutes", 0);
	ParticipantParameters.Insert("OptionForSettingDeadline", "");
	ParticipantParameters.Insert("Function", "");
	
	Return ParticipantParameters;
	
EndFunction

&AtServer
Function PreparePointDataIntoAction()
	
	DataIntoAction = New Structure;
	
	// data.
	DataIntoAction.Insert("Point_Id", SuperiorMemberOrPoint);
	DataIntoAction.Insert("Number", PointNumber);
	DataIntoAction.Insert("DescriptionOfExecution", DescriptionOfExecution);
	DataIntoAction.Insert("DueDate", DueDate);
	
	// Author.
	DataIntoAction.Insert("AuthorOfExecution", AuthorOfExecution);
	DataIntoAction.Insert("AuthorOfExecutionID", AuthorOfExecutionID);
	DataIntoAction.Insert("AuthorOfExecutionType", AuthorOfExecutionType);
	DataIntoAction.Insert("AuthorOfExecutionPresentation", AuthorOfExecutionPresentation);
	
	// The controller.
	DataIntoAction.Insert("Inspector", Inspector);
	DataIntoAction.Insert("InspectorID", InspectorID);
	DataIntoAction.Insert("InspectorType", InspectorType);
	DataIntoAction.Insert("InspectorPresentation", InspectorPresentation);
	DataIntoAction.Insert("MainAddressingObjectInspector", MainAddressingObjectInspector);
	DataIntoAction.Insert("MainAddressingObjectInspectorID", MainAddressingObjectInspectorID);
	DataIntoAction.Insert("MainAddressingObjectInspectorType", MainAddressingObjectInspectorType);
	DataIntoAction.Insert("AdditionalAddressingObjectController", AdditionalAddressingObjectController);
	DataIntoAction.Insert("AdditionalAddressingObjectControllerID", AdditionalAddressingObjectControllerID);
	DataIntoAction.Insert("AdditionalAddressingObjectControllerType", AdditionalAddressingObjectControllerType);
	
	// Performers.
	PerformersOfAction = New Array;
	
	For Each ExecutionParticipant In PerformersOfExecution Do
		ParticipantParameters = ParameterOfParticipantOfExecutionPoint();
		
		// Participant data.
		ParticipantParameters.Id = ExecutionParticipant.AssigneeID;
		ParticipantParameters.OptionForSettingDeadline = ExecutionParticipant.OptionForSettingDueDate;
		ParticipantParameters.EmployeeResponsible = ExecutionParticipant.EmployeeResponsible;
		
		// The participant.
		ParticipantParameters.Member = ExecutionParticipant.Performer;
		ParticipantParameters.MemberID = ExecutionParticipant.PerformerID;
		ParticipantParameters.MemberType = ExecutionParticipant.PerformerType;
		ParticipantParameters.MemberPresentation = ExecutionParticipant.PerformerPresentation;
		ParticipantParameters.MainAddressingObjectMember = ExecutionParticipant.MainAddressingObjectPerformer;
		ParticipantParameters.MainAddressingObjectMemberID = ExecutionParticipant.MainAddressingObjectPerformerID;
		ParticipantParameters.MainAddressingObjectMemberType = ExecutionParticipant.MainAddressingObjectPerformerType;
		ParticipantParameters.AdditionalAddressingObjectParticipant =
			ExecutionParticipant.AdditionalAddressingObjectExecutor;
		ParticipantParameters.AdditionalAddressingObjectParticipantID =
			ExecutionParticipant.AdditionalAddressingObjectExecutorID;
		ParticipantParameters.AdditionalAddressingObjectParticipantType =
			ExecutionParticipant.AdditionalAddressingObjectExecutorType;
		
		// Term.
		ParticipantParameters.DueDate = ExecutionParticipant.TaskDueDate;
		ParticipantParameters.Term_Days = ExecutionParticipant.DueDateDays;
		ParticipantParameters.TermHours = ExecutionParticipant.DueDateHours;
		ParticipantParameters.TermMinutes = ExecutionParticipant.ExecutionTimeMinutes;
		
		// Other data.
		ParticipantParameters.Function = "Performer";
		
		PerformersOfAction.Add(ParticipantParameters);
	EndDo;
	
	// The examiner, the verification period.
	If ValueIsFilled(SupervisorID) Then
		ParticipantParameters = ParameterOfParticipantOfExecutionPoint();
		
		// Participant data.
		ParticipantParameters.Id = IdOfPersonChecking;
		ParticipantParameters.OptionForSettingDeadline = OptionForSettingDeadlineForProcessingExecutionResults;
		ParticipantParameters.EmployeeResponsible = False;
		
		// The participant.
		ParticipantParameters.Member = Supervisor;
		ParticipantParameters.MemberID = SupervisorID;
		ParticipantParameters.MemberType = SupervisorType;
		ParticipantParameters.MemberPresentation = SupervisorPresentation;
		ParticipantParameters.MainAddressingObjectMember = MainAddressingObjectSupervisor;
		ParticipantParameters.MainAddressingObjectMemberID = MainAddressingObjectSupervisorID;
		ParticipantParameters.MainAddressingObjectMemberType = MainAddressingObjectSupervisorType;
		ParticipantParameters.AdditionalAddressingObjectParticipant = AdditionalAddressingObjectSupervisor;
		ParticipantParameters.AdditionalAddressingObjectParticipantID = AdditionalAddressingObjectSupervisorID;
		ParticipantParameters.AdditionalAddressingObjectParticipantType = AdditionalAddressingObjectSupervisorType;
		
		// Term.
		ParticipantParameters.DueDate = DeadlineForProcessingExecutionResults;
		ParticipantParameters.Term_Days = DeadlineForProcessingResultsDaysOfExecution;
		ParticipantParameters.TermHours = ProcessingTimeOfResultsHoursOfExecution;
		ParticipantParameters.TermMinutes = ProcessingTimeOfResultsMinutesOfExecution;
		
		// Other data.
		ParticipantParameters.Function = "PerformanceResultProcessor";
		
		PerformersOfAction.Add(ParticipantParameters);
	EndIf;
	
	DataIntoAction.Insert("PerformersOfExecution", PerformersOfAction);
	
	Return DataIntoAction;
	
EndFunction

&AtServer
Procedure SetAvailability()
	
	DifferentAvailabilityDates = True;
	ChangeResponsiblePersonAvailability = True;
	
	If PerformersOfExecution.Count() > 1 Then
		Items.AssignResponsible.Enabled = True;
	Else
		Items.AssignResponsible.Enabled = False;
	EndIf;
	
	If Not EditionAllowed Then
		
		Items.PointNumber.ReadOnly = True;
		Items.DueDate.ReadOnly = True;
		Items.DescriptionExecution.ReadOnly = True;
		Items.VerifierOfExecution.ReadOnly
			= ValueIsFilled(SupervisorID) And YouCanOnlyAddMembers;
		Items.DeadlineForProcessingExecutionResultsPresentation.ReadOnly
			= ValueIsFilled(SupervisorID) And YouCanOnlyAddMembers;
		
		Items.MoveUp.Enabled = False;
		Items.MoveDown.Enabled = False;
		
		Items.AuthorOfExecution.ReadOnly = True;
		
		Items.ExecutionController.ReadOnly = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InstallYourselfAsCheckerOnServer()
	
	MainEmployee = IntegrationWith1CDocumentManagement3Cached.MainEmployeeOfCurrentUser();
	If MainEmployee <> Undefined Then
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(
			ThisObject,
			MainEmployee,
			"Supervisor",
			True);
	EndIf;
	
EndProcedure

#EndRegion

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
		DueDateOnChange(Items.DueDate);
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
