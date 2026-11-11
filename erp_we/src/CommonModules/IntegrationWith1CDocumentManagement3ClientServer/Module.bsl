////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document management"
// Module integration1sdocumentoclientserver: client, server
////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region GeneralProceduresAndFunctions

// Returns options for setting the due date.
//
// Returns:
//   Structure:
//     * Exact_Date - String
//     * RelativeTerm - String
//
Function OptionsForSettingDueDate() Export
	
	Result = New Structure;
	Result.Insert("Exact_Date", "ExactDate");
	Result.Insert("RelativeTerm", "RelativeDate");
	
	Return Result;
	
EndFunction

// Constructor of the structure describing the processing data.
//
// Parameters:
//   SubjectOfID - String - ID of the processing item.
//   SubjectOfType - String - XDTO is the type of processing item.
//   CurrentStatus - String - The Cur State of processing. Enumeration of the DMObjectProcessingState type.
//   ReasonForInterruption - String - the reason for the processing interruption.
//
// Returns:
//   Structure:
//     * SubjectOfID - String
//     * SubjectOfType - String
//     * CurrentStatus - String
//     * ReasonForInterruption - String
//     * RequiredInteractiveAction - See IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction
//
Function DataProcessorData(SubjectOfID, SubjectOfType, CurrentStatus = "", ReasonForInterruption = "") Export
	
	DataProcessorData = New Structure;
	DataProcessorData.Insert("SubjectOfID", SubjectOfID);
	DataProcessorData.Insert("SubjectOfType", SubjectOfType);
	DataProcessorData.Insert("CurrentStatus", CurrentStatus);
	DataProcessorData.Insert("ReasonForInterruption", ReasonForInterruption);
	DataProcessorData.Insert("RequiredInteractiveAction", RequiredInteractiveAction());
	
	Return DataProcessorData;
	
EndFunction

// Constructor of the structure describing the task.
//
// Parameters:
//   ID - String - ID of the workflow task.
//   Type - String - XDTO is a type of Workflow task.
//   Title - String - task title.
//   URL - String - navigation link to the object BEFORE.
//
// Returns:
//   Structure:
//     * TaskAction - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * New - Boolean
//     * Overdue - Boolean
//     * PresentationHTML - String
//     * AdditionalDataAddress - String
//     * Flag - String
//     * ActionResult - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * ResultOfActionInText - String
//     * DataVersionOfTaskAction - String
//     * RequiredInteractiveAction - See IntegrationWith1CDocumentManagement3ClientServer.RequiredInteractiveAction
//
Function DataByTask(ID, Type, Title = "", URL = "") Export
	
	DataByTask = New Structure;
	DataByTask.Insert("TaskAction",
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
			ID,
			Type,
			Title,,
			URL));
	DataByTask.Insert("New", False);
	DataByTask.Insert("Overdue", False);
	DataByTask.Insert("PresentationHTML", "");
	DataByTask.Insert("AdditionalDataAddress", "");
	DataByTask.Insert("Flag", "");
	DataByTask.Insert("ActionResult",
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM("", ""));
	DataByTask.Insert("ResultOfActionInText", "");
	DataByTask.Insert("DataVersionOfTaskAction", "");
	DataByTask.Insert("RequiredInteractiveAction", RequiredInteractiveAction());
	
	Return DataByTask;
	
EndFunction

// Determines whether the ID is empty or filled in.
//
// Parameters:
//   Id_String - String - string Presentation of the identifier.
//
// Returns:
//   Boolean
//
Function IdFilledIn(Id_String) Export
	
	Return StringFunctionsClientServer.IsUUID(Id_String)
		And Id_String <> "00000000-0000-0000-0000-000000000000";
	
EndFunction

// List of columns in the "Quick Search" table to be filled in.
//
// Returns:
//   String
//
Function QuickSearchColumns() Export
	
	Return "Parameter, Value, ValueID, ValueType, ParameterPresentation, Type, ValuePresentation,
		|Fixed, DefaultValue, DefaultValueID, DefaultValueType";
	
EndFunction

// Constructor of the structure describing the new Workflow object.
//
// Parameters:
//   ID - String - ID of the new Document management object.
//   Type - String - The XDTO type of the new Workflow object.
//   ObjectReference - AnyRef - reference to the source object of the integrated system.
//
// Returns:
//   Structure:
//     * ID - String - ID of the new Document management object.
//     * Type - String - The XDTO type of the new Workflow object.
//     * ObjectReference - AnyRef - reference to the source object of the integrated system.
//
Function NewObjectBefore(ID, Type, ObjectReference) Export
	
	NewObjectBefore = New Structure;
	NewObjectBefore.Insert("ID", ID);
	NewObjectBefore.Insert("Type", Type);
	NewObjectBefore.Insert("ObjectReference", ObjectReference);
	
	Return NewObjectBefore;
	
EndFunction

// Redraws the list of buttons for switching pages of the dynamic list on the form.
//
// Parameters:
//   Form - ClientApplicationForm - the form on which the dynamic list is located.
//   CurrentPage - Number - the Cur page number.
//   TotalPages - Number - maximum number of pages.
//
Procedure UpdateDynamicListButtons(Form, CurrentPage, TotalPages) Export
	
	If CurrentPage > TotalPages Then
		CurrentPage = TotalPages;
	EndIf;
	
	If TotalPages = 1 Then
		Form.Items.SwitchingPages.Visible = False;
		Return;
	Else
		Form.Items.SwitchingPages.Visible = True;
	EndIf;
	
	If (TotalPages > 1) And (TotalPages < 9) Then
		
		For ButtonNumber = 1 To TotalPages Do
			Form.Items["Page" + ButtonNumber].Visible = True;
		EndDo;
		For ButtonNumber = (TotalPages + 1) To 9 Do
			Form.Items["Page" + ButtonNumber].Visible = False;
		EndDo;
		
	Else
		
		For ButtonNumber = 1 To 9 Do
			Form.Items["Page" + ButtonNumber].Visible = True;
		EndDo;
		
	EndIf;
	
	ThereIsExcess = (TotalPages > 9);
	ThereIsLeftSelectionButton = ThereIsExcess And (CurrentPage > 5);
	ThereIsRightSelectionButton = ThereIsExcess And (CurrentPage < (TotalPages - 4));
	
	If ThereIsLeftSelectionButton Then
		Form.Items.Page2.Title = "...";
	Else
		Form.Items.Page2.Title = "2";
	EndIf;
	
	If ThereIsLeftSelectionButton And ThereIsRightSelectionButton Then
		
		CurCurrentButton = 5;
		Form.Items.Page3.Title = CurrentPage - 2;
		Form.Items.Page4.Title = CurrentPage - 1;
		Form.Items.Page5.Title = CurrentPage;
		Form.Items.Page6.Title = CurrentPage + 1;
		Form.Items.Page7.Title = CurrentPage + 2;
		
	ElsIf ThereIsLeftSelectionButton Then
		
		CurCurrentButton = 9 - (TotalPages - CurrentPage);
		Form.Items.Page3.Title = TotalPages - 6;
		Form.Items.Page4.Title = TotalPages - 5;
		Form.Items.Page5.Title = TotalPages - 4;
		Form.Items.Page6.Title = TotalPages - 3;
		Form.Items.Page7.Title = TotalPages - 2;
		Form.Items.Page8.Title = TotalPages - 1;
		
	Else
		
		CurCurrentButton = CurrentPage;
		Form.Items.Page3.Title = "3";
		Form.Items.Page4.Title = "4";
		Form.Items.Page5.Title = "5";
		Form.Items.Page6.Title = "6";
		Form.Items.Page7.Title = "7";
		Form.Items.Page8.Title = "8";
		
	EndIf;
	
	If ThereIsRightSelectionButton Then
		Form.Items.Page8.Title = "...";
	EndIf;
	
	Form.Items.Page9.Title = TotalPages;
	
	For ButtonNumber = 1 To 9 Do
		Form.Items["Page" + ButtonNumber].Check = (ButtonNumber = CurCurrentButton);
	EndDo;
	
	Form.Items.Back.Enabled = (CurrentPage > 1);
	Form.Items.GoForward.Enabled = (CurrentPage < TotalPages);
	
EndProcedure

// Constructor of the structure that describes the parameters for changing the deadline for the Presentation.
//
// Returns:
//   Structure:
//     * TextOfWarningMessage - String - the returned text of the message/warning in case of an error.
//     * Performer - String
//     * PerformerID - String
//     * PerformerType - String
//     * MainAddressingObjectPerformer - String
//     * MainAddressingObjectPerformerID - String
//     * MainAddressingObjectPerformerType - String
//     * AdditionalAddressingObjectExecutor - String
//     * AdditionalAddressingObjectExecutorID - String
//     * AdditionalAddressingObjectExecutorType - String
//
Function ParametersForChangingDeadlineForSubmission() Export
	
	TermChangeParameters = New Structure;
	TermChangeParameters.Insert("TextOfWarningMessage", "");
	TermChangeParameters.Insert("Performer", "");
	TermChangeParameters.Insert("PerformerID", "");
	TermChangeParameters.Insert("PerformerType", "");
	TermChangeParameters.Insert("MainAddressingObjectPerformer", "");
	TermChangeParameters.Insert("MainAddressingObjectPerformerID", "");
	TermChangeParameters.Insert("MainAddressingObjectPerformerType", "");
	TermChangeParameters.Insert("AdditionalAddressingObjectExecutor", "");
	TermChangeParameters.Insert("AdditionalAddressingObjectExecutorID", "");
	TermChangeParameters.Insert("AdditionalAddressingObjectExecutorType", "");
	
	Return TermChangeParameters;
	
EndFunction

// Constructor of the structure describing the parameters of the task list form.
//
// Returns:
//   Structure:
//     * CurrentPage - Number
//     * DynamicListPageSize - Number
//     * SortingField - String
//     * FieldSortingDirection - Boolean
//     * DisplayFilters - ValueList
//     * QuickSearch - ValueTable
//     * DisplayingTaskCard - EnumRef.HowToDisplayReadingPane
//
Function TaskListFormParameters() Export
	
	TaskListFormParameters = New Structure;
	TaskListFormParameters.Insert("CurrentPage", 0);
	TaskListFormParameters.Insert("DynamicListPageSize", 0);
	TaskListFormParameters.Insert("SortingField", "");
	TaskListFormParameters.Insert("FieldSortingDirection", True);
	TaskListFormParameters.Insert("DisplayFilters", New ValueList);
	TaskListFormParameters.Insert("QuickSearch", Undefined);
	TaskListFormParameters.Insert("DisplayingTaskCard",
		PredefinedValue("Enum.HowToDisplayReadingPane.EmptyRef"));
	
	Return TaskListFormParameters;
	
EndFunction

// Returns a Presentation of the due date in the form of date (duration) or duration (date).
//
// Parameters:
//   Date - Date - due date.
//   Days - Number - duration, days.
//   Hours1 - Number - duration, hours.
//   Minutes1 - Number - duration, minutes.
//   UseDateAndTimeInDeadlines - Boolean - indicates whether the date and time are used in deadlines.
//   OptionForSettingDeadline - String - option to set the due date.
//
// Returns:
//   String
//
Function PresentationOfDeadline(Date, Days, Hours1, Minutes1,
		UseDateAndTimeInDeadlines, OptionForSettingDeadline) Export
	
	Presentation = "";
	
	ExactDeadlineHasBeenFilledIn = ValueIsFilled(Date);
	
	RelativeTermIsFilledIn = Days > 0
		Or (UseDateAndTimeInDeadlines And (Hours1 > 0 Or Minutes1 > 0));
	
	If Not ExactDeadlineHasBeenFilledIn And Not RelativeTermIsFilledIn Then
		Return Presentation;
	EndIf;
	
	DateForm = DateAndTimeFormat(UseDateAndTimeInDeadlines);
	
	If ExactDeadlineHasBeenFilledIn And RelativeTermIsFilledIn Then
		
		OptionsForSettingDeadline = OptionsForSettingDueDate();
		
		If OptionForSettingDeadline = OptionsForSettingDeadline.Exact_Date Then
			FirstPartOfPresentation = Format(Date, DateForm);
			If UseDateAndTimeInDeadlines Then
				SecondPartOfPresentation = DurationPresentation(Days, Hours1, Minutes1);
			Else
				SecondPartOfPresentation = DurationPresentation(Days, 0, 0);
			EndIf;
		Else
			SecondPartOfPresentation = Format(Date, DateForm);
			If UseDateAndTimeInDeadlines Then
				FirstPartOfPresentation = DurationPresentation(Days, Hours1, Minutes1);
			Else
				FirstPartOfPresentation = DurationPresentation(Days, 0, 0);
			EndIf;
		EndIf;
		
		Presentation = StrTemplate("%1 (%2)",
			FirstPartOfPresentation,
			SecondPartOfPresentation);
		
	ElsIf ExactDeadlineHasBeenFilledIn Then
		Presentation = Format(Date, DateForm);
	Else
		Presentation = DurationPresentation(Days, Hours1, Minutes1);
	EndIf;
	
	Return Presentation;
	
EndFunction

// Returns a Presentation of the Document Flow object type XDTO by type name.
// By default, it returns a singular Presentation.
//
// Parameters:
//   XDTOType - String - the name of the XDTO object type.
//   PluralForm - Boolean - It is required to return the Presentation in the plural.
//   ForFormOfSelection - Boolean - it is required to return a Presentation for the selection Form starting with "Selection ...".
//
// Returns:
//   String - representation of the type of the Document Flow object XDTO by type name.
//
Function ObjectTypePresentationXDTO(XDTOType, PluralForm = False, ForFormOfSelection = False) Export
	
	TypesPresentation1 = New Map;
	
	AddCatalogViews(PluralForm, ForFormOfSelection, TypesPresentation1);
	AddEnumerationViews(PluralForm, ForFormOfSelection, TypesPresentation1);
	
	TypePresentation = TypesPresentation1.Get(XDTOType);
	
	If ValueIsFilled(TypePresentation) Then
		Return TypePresentation;
	Else
		Return XDTOType;
	EndIf;
	
EndFunction

// Forms a Presentation of the order of execution of the action step.
//
// Parameters:
//   XDTOOrder - String - enumeration of the DMOrderOfExecutionActionStage type.
//
// Returns:
//   String
//
Function PresentationOfOrderOfExecutionOfActionStep(XDTOOrder) Export
	
	If XDTOOrder = "" Then
		Return "";
	ElsIf XDTOOrder = "AllAtOnce" Then
		Return NStr("vi = 'Tất cả ngay lập tức';
					|ru = 'Все сразу';
					|en = 'All at once'; fa = 'همه به‌طور همزمان';
					|it = 'Все сразу';
					|pl = 'All at once';
					|tr = 'Hepsi birden'");
	ElsIf XDTOOrder = "OneByOne" Then
		Return NStr("vi = 'Theo thứ tự';
					|ru = 'Один за другим';
					|en = 'One by one'; fa = 'یکی‌یکی';
					|it = 'Один за другим';
					|pl = 'One by one';
					|tr = 'Tek tek sırayla'");
	EndIf;
	
EndFunction

// Forms the Presentation of the participant of the action.
//
// Parameters:
//   ParticipantLine - FormDataTreeItem - a row of the value tree of Participants in the Form of an action.
//   AdditionalDetails - String - additional description of the participant.
//   RowPrefix - String - prefix of the participant string.
//
// Returns:
//   String - Presentation of the participant of the action.
//
Function ParticipantPresentation(ParticipantLine, AdditionalDetails = "", RowPrefix = "") Export
	
	PresentationOfStringArray = New Array;
	If ValueIsFilled(RowPrefix) Then
		PresentationOfStringArray.Add(RowPrefix);
	EndIf;
	If ValueIsFilled(ParticipantLine.MemberID) Then
		PresentationOfStringArray.Add(ParticipantLine.MemberPresentation);
	EndIf;
	If ValueIsFilled(ParticipantLine.MemberID) And ValueIsFilled(AdditionalDetails) Then
		PresentationOfStringArray.Add(AdditionalDetails);
	Else
		PresentationOfStringArray.Add("                              ");
	EndIf;
	
	Return StrConcat(PresentationOfStringArray);
	
EndFunction

// Constructor of a structure that describes the type of operation on the task.
//
// Returns:
//   Structure:
//     * ToBegin - Boolean
//     * Abort - Boolean
//     * Stop - Boolean
//     * Continue - Boolean
//     * Fill - Boolean
//     * Restart - Boolean
//
Function TypeOfOperationWithProcessing() Export
	
	OperationType = New Structure;
	OperationType.Insert("ToBegin", False);
	OperationType.Insert("Abort", False);
	OperationType.Insert("Stop", False);
	OperationType.Insert("Continue", False);
	OperationType.Insert("Fill", False);
	OperationType.Insert("Restart", False);
	
	Return OperationType;
	
EndFunction

// Constructor of the structure describing the required interactive action.
//
// Returns:
//   Structure:
//     * BackToTask - Boolean
//     * SelectTaskExecutor - Boolean
//     * PerformSigning - Boolean
//     * AskRandomQuestion - Boolean
//     * AskQuestionAboutCycleLimit - Boolean
//     * ChangeProcessParameters - Boolean
//     * Context - Structure, String - Arbitrary data required to perform an interactive action.
//         For example, a list of possible task executors, or a link to the process whose parameters
//         you want to change. It can also contain the result of an interactive action.
//         For example, it may contain the selected actual task executor, or the parameters of the modified process.
//                - Undefined - if the context is not required to perform an interactive action.
//     * CacheOfPreviousResults - String
//
Function RequiredInteractiveAction() Export
	
	RequiredInteractiveAction = New Structure;
	// Required interactive action.
	RequiredInteractiveAction.Insert("BackToTask", False);
	RequiredInteractiveAction.Insert("SelectTaskExecutor", False);
	RequiredInteractiveAction.Insert("PerformSigning", False);
	RequiredInteractiveAction.Insert("AskRandomQuestion", False);
	RequiredInteractiveAction.Insert("AskQuestionAboutCycleLimit", False);
	RequiredInteractiveAction.Insert("ChangeProcessParameters", False);
	// Data required to perform an interactive action.
	RequiredInteractiveAction.Insert("Context", Undefined);
	RequiredInteractiveAction.Insert("CacheOfPreviousResults", "");
	
	Return RequiredInteractiveAction;
	
EndFunction

#EndRegion

#Region Tasks

// Constructor of the structure describing the object to create based on the task.
//
// Returns:
//   Structure:
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - contains a link to the
//         integration rule for creating an IP object.
//                         - Undefined - if you want to create an IP document based on an EDI document.
//     * DocumentEDI - See IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM
//     * ObjectPresentationIS - String - Presentation of the IC object being created.
//
Function ObjectToCreateBasedOnTask() Export
	
	SuitableObject = New Structure;
	SuitableObject.Insert("IntegrationRule", Undefined);
	SuitableObject.Insert("DocumentEDI",
		IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM("", ""));
	SuitableObject.Insert("ObjectPresentationIS", "");
	
	Return SuitableObject;
	
EndFunction

// Returns a document line from the task application tree corresponding to the Cur line.
//
// Parameters:
//   CurrentRow - FormDataTreeItem, ValueTreeRow - The Cur row in the application tree on the Form.
//
// Returns:
//   FormDataTreeItem
//   String of Tree Assignments
//   Undefined - if the current line does not refer to any document.
//
Function DocumentLineInApplicationTree(Val CurrentRow) Export
	
	While CurrentRow <> Undefined And CurrentRow.ApplicationType <> "DMDocument" Do
		If TypeOf(CurrentRow) = Type("FormDataTreeItem") Then
			CurrentRow = CurrentRow.GetParent();
		ElsIf TypeOf(CurrentRow) = Type("ValueTreeRow") Then
			CurrentRow = CurrentRow["Parent"];
		EndIf;
	EndDo;
	
	Return CurrentRow;
	
EndFunction

#EndRegion

#Region Actions

// Checks the presence of at least one protected participant in the transmitted action stage.
//
// Parameters:
//   Stage - FormDataTreeItem - a stage string from the tree of processing participants.
//
// Returns:
//   Boolean - there are protected participants.
//
Function ThereAreProtectedParticipantsInAction(Stage) Export
	
	Result = False;
	
	Attendees = Stage.GetItems();
	For Each Member In Attendees Do
		If Member.IsProtected Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Checks for action steps.
//
// Parameters:
//   Attendees - FormDataTree - a tree with participants.
//   StageID - String - the predefined identifier of the participant of the action, which we do not take into account.
//   IdOfPersonProcessingResult - String - the predefined ID of the action processing the result,
//     which we do not take into account.
//
// Returns:
//   Boolean - there are protected participants.
//
Function ThereAreStagesOfAction(Attendees, StageID, IdOfPersonProcessingResult) Export
	
	ElementsStages = Attendees.GetItems();
	ThereAreStages = False;
	For Each ElementStage In ElementsStages Do
		If ElementStage.Id = StageID
				Or ElementStage.Id = IdOfPersonProcessingResult Then
			Continue;
		EndIf;
		ThereAreStages = True;
		Break;
	EndDo;
	
	Return ThereAreStages;
	
EndFunction

// Returns the field names of the action participants table on the form.
//
// Returns:
//   String
//
Function FieldNamesOfActionParticipantsTable() Export
	
	FieldsNames = "MemberID,MemberType,MainAddressingObjectMemberID,MainAddressingObjectMemberType,
		|AdditionalAddressingObjectParticipantID,AdditionalAddressingObjectParticipantType,Id";
	
	Return StrReplace(FieldsNames, Chars.LF, "");
	
EndFunction

// Sets the description, hint, and display of the start delay of the action.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//   LaunchPresentation - String - description of the launch delay.
//   ClearDelayHint - String - an implicitly returned value, a hint of the Form's Clear Retention Command.
//   DescriptionOfDelayedStartOfExecutionHint - String - an implicitly returned value, a hint for an element
//     of the Form DescriptionThe initial execution step.
//
Procedure ConfigureDisplayOfDelayedStartOfAction(Form, LaunchPresentation = "",
		ClearDelayHint = "", DescriptionOfDelayedStartOfExecutionHint = "") Export
	
	DelayedStartOfExecutionDays = Form.DelayedStartOfExecutionDays;
	DelayedStartOfExecutionHours = Form.DelayedStartOfExecutionHours;
	Items = Form.Items;
	Items.ClearDelay.Visible = True;
	Items.DescriptionOfDelayedStartOfExecution.TitleLocation = FormItemTitleLocation.Auto;
	Items.DescriptionOfDelayedStartOfExecution.TitleHeight = 1;
	
	If Items.Find("DeferredAction") <> Undefined Then
		Items.DeferredAction.Visible = False;
	EndIf;
	ClearDelayHint = NStr("vi = 'Xóa bỏ hoãn bắt đầu thực hiện thao tác';
							|ru = 'Очистить отложенное начало выполнения действия';
							|en = 'Clear the deferred action start'; fa = 'Clear the deferred action start';
							|it = 'Очистить отложенное начало выполнения действия';
							|pl = 'Clear the deferred action start';
							|tr = 'Eylemin gerçekleştirilme başlangıcını temizle'");
	
	If ValueIsFilled(LaunchPresentation) Then
		
		Form.DescriptionOfDelayedStartOfExecution = LaunchPresentation;
		Items.DescriptionOfDelayedStartOfExecution.ToolTip =
			NStr("vi = 'Việc thực hiện thao tác được bắt đầu trong thời gian cụ thể';
				|ru = 'Выполнение действия начнется в указанное время';
				|en = 'Action execution will start at the specified time'; fa = 'Action execution will start at the specified time';
				|it = 'Выполнение действия начнется в указанное время';
				|pl = 'Action execution will start at the specified time';
				|tr = 'Eylemin gerçekleştirilmesi belirtilen zamanda başlayacaktır'");
		Items.DescriptionOfDelayedStartOfExecution.Width = 20;
		Items.DescriptionOfDelayedStartOfExecution.TitleLocation = FormItemTitleLocation.None;
		If Items.Find("DeferredAction") <> Undefined Then
			Items.DeferredAction.Visible = True;
		EndIf;
		ClearDelayHint = NStr("vi = 'Bắt đầu thực hiện thao tác ngay lập tức';
								|ru = 'Начать выполнение действия немедленно';
								|en = 'Start the action execution immediately'; fa = 'Start the action execution immediately';
								|it = 'Начать выполнение действия немедленно';
								|pl = 'Start the action execution immediately';
								|tr = 'Eylemin gerçekleştirilmesine hemen başla'");
		Return;
		
	Else
		
		If ValueIsFilled(Form.DeferredExecutionDate) Then
			Form.DescriptionOfDelayedStartOfExecution = StrTemplate(
				NStr("vi = 'cho %1';
					|ru = 'на %1';
					|en = 'as of %1'; fa = 'as of %1';
					|it = 'на %1';
					|pl = 'as of %1';
					|tr = '%1 doğrultusunda'"),
				Format(Form.DeferredExecutionDate, NStr("vi = 'ДФ=''дд.ММ.гггг ЧЧ:мм''';
														|ru = 'ДФ=''HH:mm dd.MM.yyyy''';
														|en = 'DF=''HH:mm MM/dd/yyyy'''; fa = 'DF=''HH:mm MM/dd/yyyy''';
														|it = 'ДФ=''ЧЧ:мм дд.ММ.гггг''';
														|pl = 'DF=''HH:mm MM/dd/yyyy''';
														|tr = 'DF=''HH:mm dd.MM.yyyy'''")));
			Items.DescriptionOfDelayedStartOfExecution.Width = 15;
			
		ElsIf ValueIsFilled(DelayedStartOfExecutionDays) And ValueIsFilled(DelayedStartOfExecutionHours) Then
			Form.DescriptionOfDelayedStartOfExecution = StrTemplate(
				NStr("vi = '%1 %2 và %3 %4';
					|ru = '%1 %2 и %3 %4';
					|en = '%1 %2 and %3 %4'; fa = '%1 %2 and %3 %4';
					|it = '%1 %2 e %3 %4';
					|pl = '%1 %2 i %3 %4';
					|tr = '%1 %2 ve %3 %4'"),
				String(DelayedStartOfExecutionDays),
				CaptionForNumberOfDays(DelayedStartOfExecutionDays),
				String(DelayedStartOfExecutionHours),
				CaptionToNumberOfHours(DelayedStartOfExecutionHours));
			Items.DescriptionOfDelayedStartOfExecution.Width = 11;
			
		ElsIf ValueIsFilled(DelayedStartOfExecutionDays) Then
			Form.DescriptionOfDelayedStartOfExecution = StrTemplate(
				NStr("vi = '%1 %2';
					|ru = '%1 %2';
					|en = '%1 %2'; fa = '%1 %2';
					|it = '%1 %2';
					|pl = '%1 %2';
					|tr = '%1 %2'"),
				String(DelayedStartOfExecutionDays),
				CaptionForNumberOfDays(DelayedStartOfExecutionDays));
			Items.DescriptionOfDelayedStartOfExecution.Width = 5;
			
		ElsIf ValueIsFilled(DelayedStartOfExecutionHours) Then
			Form.DescriptionOfDelayedStartOfExecution = StrTemplate(
				NStr("vi = '%1 %2';
					|ru = '%1 %2';
					|en = '%1 %2'; fa = '%1 %2';
					|it = '%1 %2';
					|pl = '%1 %2';
					|tr = '%1 %2'"),
				String(DelayedStartOfExecutionHours),
				CaptionToNumberOfHours(DelayedStartOfExecutionHours));
			Items.DescriptionOfDelayedStartOfExecution.Width = 5;
			
		Else
			Form.DescriptionOfDelayedStartOfExecution = NStr("vi = 'chưa tùy chỉnh';
															|ru = 'не настроено';
															|en = 'not configured'; fa = 'not configured';
															|it = 'не настроено';
															|pl = 'not configured';
															|tr = 'ayarlanmadı'");
			Items.ClearDelay.Visible = False;
			Items.DescriptionOfDelayedStartOfExecution.Width = 9;
			
		EndIf;
		
	EndIf;
	
	DescriptionOfDelayedStartOfExecutionHint =
		NStr("vi = 'Nếu đã xác định thì việc thực hiện thao tác diễn ra trong thời gian cụ thể hoặc qua số lượng ngày/giờ cụ thể';
			|ru = 'Если задано, то выполнение действия произойдет в указанное время или через указанное количество календарных дней/часов';
			|en = 'If set, the action will be performed at the specified time or after a specified number of calendar days/hours'; fa = 'If set, the action will be performed at the specified time or after a specified number of calendar days/hours';
			|it = 'Если задано, то выполнение действия произойдет в указанное время или через указанное количество календарных дней/часов';
			|pl = 'If set, the action will be performed at the specified time or after a specified number of calendar days/hours';
			|tr = 'Ayarlanırsa, eylem belirtilen zamanda veya belirtilen takvim günü/saat sayısından sonra gerçekleşir'");
	
EndProcedure

// Returns the number of the image from the collectionresultsreferences.
//
// Parameters:
//   Result - String - the result of the action.
//   State - String - The State of the action.
//   ThereIsRequestForRefusal - Boolean
//
// Returns:
//   Number
//
Function NumberOfImageOfResultOfAction(Result, State = Undefined, ThereIsRequestForRefusal = False) Export
	
	If ThereIsRequestForRefusal Then
		Return 5; // Refusal.
	EndIf;
	
	If Not ValueIsFilled(Result) Then
		If ValueIsFilled(State) And (State = "Performing" Or State = "DelayedStart") Then
			Return 6;
			
		ElsIf ValueIsFilled(State) And State = "InTheExecutionQueue" Then
			Return 7;
			
		ElsIf ValueIsFilled(State) And State = "Skipped" Then
			Return 8;
			
		ElsIf ValueIsFilled(State) And State = "OnPause" Then
			Return 11;
			
		ElsIf ValueIsFilled(State) And State = "Completed" Then
			Return 1;
			
		EndIf;
	EndIf;
	
	Rank = RankOfActionResult(Result);
	
	If Rank = 0 Then
		Return 0; // Empty.
		
	ElsIf Rank = 1 Then
		Return 5; // Refusal.
		
	ElsIf Rank = 4 Then
		Return 1; // Completed.
		
	ElsIf Rank = 2 Then
		Return 2; // Performed with a negative result.
		
	ElsIf Rank = 3 Then
		Return 3; // Performed positively with comments.
		
	ElsIf Rank = 5 Then
		Return 4; // Performed positively.
		
	Else
		Return 0;
		
	EndIf;
	
EndFunction

// Returns the total result of the two results of the participants in the action.
//
//
// Parameters:
//   Result1 - String - the result of the action.
//   Result2 - String - the result of the action.
//
// Returns:
//   String
//
Function OverallResultOfAction(Result1, Result2) Export
	
	ToSelectMinimum = False;
	If Result1 = "NotApproved" Or Result2 = "NotApproved" Then
		ToSelectMinimum = True;
	EndIf;
	If Result1 = "NotSigned" Or Result2 = "NotSigned" Then
		ToSelectMinimum = True;
	EndIf;
	
	If Not ValueIsFilled(Result1)
			Or Result1 = Result2
			Or RankOfActionResult(Result1, ToSelectMinimum)
				>= RankOfActionResult(Result2, ToSelectMinimum) Then
		Return Result2;
		
	Else
		Return Result1;
		
	EndIf;
	
EndFunction

// Returns the general State of the two participants in the action.
//
// Parameters:
//   State1 - String - The State of the action.
//   State2 - String - The State of the action.
//
// Returns:
//   String
//
Function GeneralStateOfAction(State1, State2) Export
	
	If Not ValueIsFilled(State1)
			Or State1 = State2
			Or RankOfActionState(State1, True) >= RankOfActionState(State2, True) Then
		Return State2;
		
	Else
		Return State1;
		
	EndIf;
	
EndFunction

// Checks whether participants have changed in the action card.
// It works in conjunction with the integration procedure 1 and document flow3.Fill in the Action Participant table.
//
// Parameters:
//   Form - See DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExecutionAction
//
// Returns:
//   Boolean
//
Function ParticipantsOfActionHaveBeenChangedInCard(Form) Export
	
	RecordsCount = Form.ParticipantsAtOpening.Count();
	ThereAreDifferences = RecordsCount <> Form.AttendeesBeforeWrite.Count();
	
	If Not ThereAreDifferences Then
		
		FieldsForComparison = StrSplit(FieldNamesOfActionParticipantsTable(), ",");
		For Cnt = 0 To RecordsCount - 1 Do
			For Each FieldName In FieldsForComparison Do
				If Form.ParticipantsAtOpening[Cnt][FieldName] <> Form.AttendeesBeforeWrite[Cnt][FieldName] Then
					Return True;
				EndIf;
			EndDo;
		EndDo;
		
	EndIf;
	
	Return ThereAreDifferences;
	
EndFunction

// Returns True if the specified action is an execution action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsExecutionAction(ActionType) Export
	
	Return ActionType = "DMActionPerformance";
	
EndFunction

// Returns True if the specified action is a matching action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsMatchingAction(ActionType) Export
	
	Return ActionType = "DMActionApproval";
	
EndFunction

// Returns True if the specified action is a familiarization action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsFamiliarizationAction(ActionType) Export
	
	Return ActionType = "DMActionExamination";
	
EndFunction

// Returns True if the specified action is a signing action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsSigningAction(ActionType) Export
	
	Return ActionType = "DMActionSigning";
	
EndFunction

// Returns True if the specified action is a registration action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsRegistrationAction(ActionType) Export
	
	Return ActionType = "DMActionRegistration";
	
EndFunction

// Returns True if the specified action is an assertion action.
//
// Parameters:
//   ActionType - String - the name of the type XDTO.
//
// Returns:
//   Boolean
//
Function ThisIsAssertionAction(ActionType) Export
	
	Return ActionType = "DMActionConfirmation";
	
EndFunction

// Returns True if the parameter is a function of the participant processing the result.
//
// Parameters:
//   ParticipantFunction - String - the function of the participant of the action.
//
// Returns:
//   Boolean
//
Function ThisIsFunctionToProcessResult(ParticipantFunction) Export
	
	If ParticipantFunction = "PerformanceResultProcessor"
			Or ParticipantFunction = "ProcessingResolution"
			Or ParticipantFunction = "SigningResultProcessor"
			Or ParticipantFunction = "RegistrationResultProcessor"
			Or ParticipantFunction = "ApprovalResultProcessor"
			Or ParticipantFunction = "ConfirmationResultProcessor" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region Links

// Searches for a row in the relationship tree by ID.
//
// Parameters:
//   Items - FormDataTreeItemCollection - a collection of elements of the relationship tree.
//   ID - String - ID of the linked object being searched for.
//   Type - String - type of the linked object you are looking for.
//
// Returns:
//   FormDataTreeItem
//   Undefined - if the linked object is not in the tree.
//
Function LinkByID(Items, ID, Type = Undefined) Export
	
	If Not ValueIsFilled(ID) Then
		Return Undefined;
	EndIf;
	
	For Each Item In Items Do
		If Item.LinkedObjectID = ID And ((Type = Undefined) Or (Item.LinkedObjectType = Type)) Then
			Return Item;
		Else
			String = LinkByID(Item.GetItems(), ID, Type);
			If String <> Undefined Then
				Return String;
			EndIf;
		EndIf;
	EndDo;
	
EndFunction

// Returns a document line from the link tree corresponding to the current line.
//
// Parameters:
//   CurrentRow - FormDataTreeItem, ValueTreeRow - the current row in the link tree on the Form.
//
// Returns:
//   FormDataTreeItem
//   String of Tree Assignments
//   Undefined - if the current line does not refer to any document.
//
Function DocumentStringInLinkTree(Val CurrentRow) Export
	
	While CurrentRow <> Undefined And CurrentRow.LinkedObjectType <> "DMDocument" Do
		If TypeOf(CurrentRow) = Type("FormDataTreeItem") Then
			CurrentRow = CurrentRow.GetParent();
		ElsIf TypeOf(CurrentRow) = Type("ValueTreeRow") Then
			CurrentRow = CurrentRow["Parent"];
		EndIf;
	EndDo;
	
	Return CurrentRow;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Procedure AddEnumerationViews(PluralForm, ForFormOfSelection, TypesPresentation1)
	
	SingularForm = Not PluralForm And Not ForFormOfSelection;
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Тип ответа';
							|en = 'Response type'; fa = 'نوع پاسخ';
							|it = 'Tipo di risposta';
							|pl = 'Typ odpowiedzi';
							|tr = 'Yanıt türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu phản hồi';
							|ru = 'Выбор типа ответа';
							|en = 'Select a response type'; fa = 'Select a response type';
							|it = 'Selezione del tipo di risposta';
							|pl = 'Wybór typu odpowiedzi';
							|tr = 'Yanıt türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Типы ответа';
							|en = 'Response types'; fa = 'Response types';
							|it = 'Tipi di risposta';
							|pl = 'Typy odpowiedzi';
							|tr = 'Yanıt türleri'");
	EndIf;
	TypesPresentation1.Insert("DMEMailAnswerType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng câu hỏi thực hiện nhiệm vụ';
							|ru = 'Вид вопросов выполнения задач';
							|en = 'Question kind of task execution'; fa = 'Question kind of task execution';
							|it = 'Aspetto di problemi di esecuzione dei compiti';
							|pl = 'Rodzaj pytań wykonania zadań';
							|tr = 'Görev tamamlama soruları türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng câu hỏi thực hiện nhiệm vụ';
							|ru = 'Выбор вида вопросов выполнения задач';
							|en = 'Select a question kind of task execution'; fa = 'Select a question kind of task execution';
							|it = 'Scelta dell''aspetto di problemi di esecuzione dei compiti';
							|pl = 'Rodzaj pytań wykonania zadań';
							|tr = 'Görev tamamlama soruları türünün seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng vấn đề thực hiện nhiệm vụ';
							|ru = 'Виды вопросов выполнения задач';
							|en = 'Issue kinds of task execution'; fa = 'Issue kinds of task execution';
							|it = 'Tipi di problema di completamento dei compiti';
							|pl = 'Rodzaje pytań wykonania zadań';
							|tr = 'Görev tamamlama sorularının türleri'");
	EndIf;
	TypesPresentation1.Insert("DMIssueType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trình tự gia hạn';
							|ru = 'Порядок продления';
							|en = 'Extension procedure'; fa = 'رویه تمدید';
							|it = 'Ordine di proroga';
							|pl = 'Tryb przedłużenia';
							|tr = 'Uzatma prosedürü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trình tự gia hạn';
							|ru = 'Выбор порядка продления';
							|en = 'Select an extension procedure'; fa = 'Select an extension procedure';
							|it = 'Scelta dell''ordine di proroga';
							|pl = 'Wybór trybu przedłużenia';
							|tr = 'Uzatma prosedürü seçimi'");
	Else
		Presentation = NStr("vi = 'Trình tự gia hạn';
							|ru = 'Порядки продления';
							|en = 'Extension procedures'; fa = 'Extension procedures';
							|it = 'Ordini di proroga';
							|pl = 'Tryby przedłużenia';
							|tr = 'Uzatma prosedürleri'");
	EndIf;
	TypesPresentation1.Insert("DMProlongationProcedure", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái văn bản';
							|ru = 'Состояние документа';
							|en = 'Document state'; fa = 'وضعیت سند';
							|it = 'Stato del documento';
							|pl = 'Status dokumentu';
							|tr = 'Belge durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái chứng từ';
							|ru = 'Выбор состояния документа';
							|en = 'Select document state'; fa = 'Select document state';
							|it = 'Selezione stato documento';
							|pl = 'Wybór statusu dokumentu';
							|tr = 'Belge durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái văn bản';
							|ru = 'Состояния документов';
							|en = 'Document states'; fa = 'وضعیت‌های سند';
							|it = 'Stati documenti';
							|pl = 'Statusy dokumentów';
							|tr = 'Belge durumları'");
	EndIf;
	TypesPresentation1.Insert("DMDocumentStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái cuộc họp';
							|ru = 'Состояние мероприятия';
							|en = 'Event state'; fa = 'Event state';
							|it = 'Stato evento';
							|pl = 'Status wydarzenia';
							|tr = 'Etkinlik durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái cuộc họp';
							|ru = 'Выбор состояния мероприятия';
							|en = 'Select event state'; fa = 'Select event state';
							|it = 'Selezione stato dell''evento';
							|pl = 'Wybór statusu wydarzenia';
							|tr = 'Etkinlik durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái cuộc họp';
							|ru = 'Состояния мероприятий';
							|en = 'Event states'; fa = 'Event states';
							|it = 'Stati eventi';
							|pl = 'Statusy wydarzeń';
							|tr = 'Etkinliklerin durumları'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái biên bản cuộc họp';
							|ru = 'Состояние протокола мероприятия';
							|en = 'Event protocol state'; fa = 'Event protocol state';
							|it = 'Stato del protocollo dell''evento';
							|pl = 'Status protokołu wydarzenia';
							|tr = 'Etkinlik protokol durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái biên bản cuộc họp';
							|ru = 'Выбор состояния протокола мероприятия';
							|en = 'Select an event protocol state'; fa = 'Select an event protocol state';
							|it = 'Selezione stato del protocollo dell''evento';
							|pl = 'Wybór statusu protokołu wydarzenia';
							|tr = 'Etkinlik protokol durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái biên bản cuộc họp';
							|ru = 'Состояния протоколов мероприятий';
							|en = 'Event protocol states'; fa = 'Event protocol states';
							|it = 'Stati dei protocolli degli eventi';
							|pl = 'Statusy protokołów wydarzeń';
							|tr = 'Etkinliklerin protokol durumları'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingMinutesItemStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Pháp nhân\cá nhân';
							|ru = 'Юридическое\физическое лицо';
							|en = 'Business entity\person'; fa = 'Business entity\person';
							|it = 'Entità giuridica \ persona fisica';
							|pl = 'Osoba prawna\fizyczna';
							|tr = 'Tüzel\gerçek kişi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn pháp nhân\cá nhân';
							|ru = 'Выбор юр\физ лица';
							|en = 'Select a legal entity\person'; fa = 'Select a legal entity\person';
							|it = 'Selezione persona giuridica\fisica';
							|pl = 'Wybór osoby prawnej\fizycznej';
							|tr = 'Tüzel\gerçek kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Pháp nhân\cá nhân';
							|ru = 'Юридическое\физическое лица';
							|en = 'Legal entity\person'; fa = 'Legal entity\person';
							|it = 'Persone giuridiche \ fisiche';
							|pl = 'Osoba prawna\fizyczna';
							|tr = 'Tüzel\gerçek kişi'");
	EndIf;
	TypesPresentation1.Insert("DMLegalPrivatePerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thuế suất GTGT';
							|ru = 'Ставка НДС';
							|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
							|it = 'Aliquota IVA';
							|pl = 'Stawka VAT';
							|tr = 'KDV oranı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thuế suất GTGT';
							|ru = 'Выбор ставки НДС';
							|en = 'Select a VAT rate'; fa = 'Select a VAT rate';
							|it = 'Selezione aliquota IVA';
							|pl = 'Wybór stawki VAT';
							|tr = 'KDV oranı seçimi'");
	Else
		Presentation = NStr("vi = 'Thuế suất GTGT';
							|ru = 'Ставки НДС';
							|en = 'VAT rates'; fa = 'نرخ‌های مالیات بر ارزش افزوده';
							|it = 'Aliquote IVA';
							|pl = 'Stawki VAT';
							|tr = 'KDV oranları'");
	EndIf;
	TypesPresentation1.Insert("DMVATRate", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Phương án ký';
							|ru = 'Вариант подписания';
							|en = 'How to sign'; fa = 'How to sign';
							|it = 'Variante di firma';
							|pl = 'Wariant podpisania';
							|tr = 'İmza seçeneği'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn phương án ký';
							|ru = 'Выбор варианта подписания';
							|en = 'Select how to sign'; fa = 'Select how to sign';
							|it = 'Scelta di un''opzione di firma';
							|pl = 'Wybór wariantu podpisania';
							|tr = 'İmza seçeneği seçimi'");
	Else
		Presentation = NStr("vi = 'Phương án ký';
							|ru = 'Варианты подписания';
							|en = 'Signing options'; fa = 'Signing options';
							|it = 'Opzioni di firma';
							|pl = 'Warianty podpisania';
							|tr = 'İmza seçenekleri'");
	EndIf;
	TypesPresentation1.Insert("DMSignatureOption", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu thông tin liên hệ';
							|ru = 'Тип контактной информации';
							|en = 'Contact information type'; fa = 'نوع اطلاعات تماس';
							|it = 'Tipo di informazione di contatto';
							|pl = 'Rodzaj informacji kontaktowych';
							|tr = 'İletişim bilgileri türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu thông tin liên hệ';
							|ru = 'Выбор типа контактной информации';
							|en = 'Select a contact information type'; fa = 'Select a contact information type';
							|it = 'Selezione del tipo di informazione di contatto';
							|pl = 'Wybór typu informacji kontaktowych ';
							|tr = 'İletişim bilgileri türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu thông tin liên hệ';
							|ru = 'Типы контактной информации';
							|en = 'Contact information types'; fa = 'انواع اطلاعات تماس';
							|it = 'Tipi di informazione di contatto';
							|pl = 'Rodzaje informacji kontaktowych';
							|tr = 'İletişim bilgisi tipleri'");
	EndIf;
	TypesPresentation1.Insert("DMContactInformationType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thể loại hồ sơ';
							|ru = 'Категория дел';
							|en = 'Case category'; fa = 'Case category';
							|it = 'Categoria pratiche';
							|pl = 'Kategoria spraw';
							|tr = 'Yapılacaklar öğesi kategorisi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thể loại hồ sơ';
							|ru = 'Выбор категории дел';
							|en = 'Select a case category'; fa = 'Select a case category';
							|it = 'Selezione categoria pratiche';
							|pl = 'Wybór kategorii spraw';
							|tr = 'Yapılacaklar öğesi kategorisinin seçimi'");
	Else
		Presentation = NStr("vi = 'Thể loại hồ sơ';
							|ru = 'Категории дел';
							|en = 'Case categories'; fa = 'Case categories';
							|it = 'Categorie pratiche';
							|pl = 'Kategorie spraw';
							|tr = 'Yapılacaklar öğesi kategorileri'");
	EndIf;
	TypesPresentation1.Insert("DMCategoriesOfCases", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Ngày trong tuần';
							|ru = 'День недели';
							|en = 'Week day'; fa = 'روز هفته';
							|it = 'Giorno della settimana';
							|pl = 'Dzień tygodnia';
							|tr = 'Haftanın günü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn ngày trong tuần';
							|ru = 'Выбор дня недели';
							|en = 'Select a week day'; fa = 'Select a week day';
							|it = 'Scelta del giorno della settimana';
							|pl = 'Wybór dnia tygodnia';
							|tr = 'Haftanın günü seçimi'");
	Else
		Presentation = NStr("vi = 'Ngày trong tuần';
							|ru = 'Дни недели';
							|en = 'Week days'; fa = 'روزهای هفته';
							|it = 'Giorni della settimana';
							|pl = 'Dni tygodnia';
							|tr = 'İş günleri'");
	EndIf;
	TypesPresentation1.Insert("DMDaysOfTheWeek", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng ngày';
							|ru = 'Вид дня';
							|en = 'Day type'; fa = 'نوع روز';
							|it = 'Tipo del giorno';
							|pl = 'Rodzaj dnia';
							|tr = 'Gün türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng ngày';
							|ru = 'Выбор вида дня';
							|en = 'Select a day kind'; fa = 'Select a day kind';
							|it = 'Selezione del tipo di giorno';
							|pl = 'Wybór dnia tygodnia';
							|tr = 'Gün türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng ngày';
							|ru = 'Виды дней';
							|en = 'Day kinds'; fa = 'Day kinds';
							|it = 'Tipi di giorni';
							|pl = 'Rodzaje dni';
							|tr = 'Gün türleri'");
	EndIf;
	TypesPresentation1.Insert("DMKindsOfDays", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Chính sách ghi nhận thời gian làm việc';
							|ru = 'Политика учета рабочего времени';
							|en = 'Working time tracking policy'; fa = 'Working time tracking policy';
							|it = 'Politica contabile dell''orario di lavoro';
							|pl = 'Polityka ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikası'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn chính sách ghi nhận thời gian làm việc';
							|ru = 'Выбор политики учета рабочего времени';
							|en = 'Select a working time tracking policy'; fa = 'Select a working time tracking policy';
							|it = 'Selezione politica contabile dell''orario di lavoro.';
							|pl = 'Wybór polityki ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikası seçimi'");
	Else
		Presentation = NStr("vi = 'Chính sách ghi nhận thời gian làm việc';
							|ru = 'Политики учета рабочего времени';
							|en = 'Working time tracking policies'; fa = 'Working time tracking policies';
							|it = 'Politiche contabili dell''orario di lavoro';
							|pl = 'Polityki ewidencji czasu pracy';
							|tr = 'Çalışma zamanının raporlanma politikaları'");
	EndIf;
	TypesPresentation1.Insert("DMTimeTrackingPolicy", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Тип ответа';
							|en = 'Response type'; fa = 'نوع پاسخ';
							|it = 'Tipo di risposta';
							|pl = 'Typ odpowiedzi';
							|tr = 'Yanıt türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu phản hồi';
							|ru = 'Выбор типа ответа';
							|en = 'Select a response type'; fa = 'Select a response type';
							|it = 'Selezione del tipo di risposta';
							|pl = 'Wybór typu odpowiedzi';
							|tr = 'Yanıt türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu phản hồi';
							|ru = 'Типы ответа';
							|en = 'Response types'; fa = 'Response types';
							|it = 'Tipi di risposta';
							|pl = 'Typy odpowiedzi';
							|tr = 'Yanıt türleri'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingEMailAnswerType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Trạng thái mời họp';
							|ru = 'Состояние приглашения';
							|en = 'Invitation state'; fa = 'Invitation state';
							|it = 'Stato di invito';
							|pl = 'Status zaproszenia';
							|tr = 'Davet durumu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn trạng thái mời họp';
							|ru = 'Выбор состояния приглашения';
							|en = 'Select an invitation state'; fa = 'Select an invitation state';
							|it = 'Selezione stato dell''invito';
							|pl = 'Wybór statusu zaproszenia';
							|tr = 'Davet durumu seçimi'");
	Else
		Presentation = NStr("vi = 'Trạng thái mời họp';
							|ru = 'Состояния приглашения';
							|en = 'Invitation states'; fa = 'Invitation states';
							|it = 'Stati di invito';
							|pl = 'Statusy zaproszenia';
							|tr = 'Davet durumu'");
	EndIf;
	TypesPresentation1.Insert("DMInvitationStatus", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Способ указания времени';
							|vi = 'Time specification method';
							|en = 'Time specification method'; fa = 'روش تعیین زمان';
							|it = 'Metodo di indicazione di tempo';
							|pl = 'Sposób wskazania czasu';
							|tr = 'Zaman belirtme yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор способа указания времени';
							|vi = 'Select time specification method';
							|en = 'Select time specification method'; fa = 'Select time specification method';
							|it = 'Select time specification method';
							|pl = 'Select time specification method';
							|tr = 'Zaman belirtme yöntemi seçimi'");
	Else
		Presentation = NStr("ru = 'Способы указания времени';
							|vi = 'Time specification methods ';
							|en = 'Time specification methods '; fa = 'Time specification methods ';
							|it = 'Metodi di indicazione di tempo';
							|pl = 'Sposoby wskazania czasu';
							|tr = 'Zaman belirtme yöntemleri'");
	EndIf;
	TypesPresentation1.Insert("DMTimeInputMethod", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Важность писем';
							|vi = 'Email importance ';
							|en = 'Email importance '; fa = 'Email importance ';
							|it = 'Importanza posta';
							|pl = 'Ważność wiadomości';
							|tr = 'Mektup önemliliği'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор важности писем';
							|vi = 'Email importance selection';
							|en = 'Email importance selection'; fa = 'Email importance selection';
							|it = 'Email importance selection';
							|pl = 'Email importance selection';
							|tr = 'E-posta önemi seçimi'");
	Else
		Presentation = NStr("ru = 'Важность писем';
							|vi = 'Email importance ';
							|en = 'Email importance '; fa = 'Email importance ';
							|it = 'Importanza posta';
							|pl = 'Ważność wiadomości';
							|tr = 'Mektup önemliliği'");
	EndIf;
	TypesPresentation1.Insert("DMEMailImportance", Presentation);
	
EndProcedure

Procedure AddCatalogViews(PluralForm, ForFormOfSelection, TypesPresentation1)
	
	SingularForm = Not PluralForm And Not ForFormOfSelection;
	
	If SingularForm Then
		Presentation = NStr("ru = 'Контрагент, Организация, Сотрудник';
							|vi = 'Counterparty, Company, Employee';
							|en = 'Counterparty, Company, Employee'; fa = 'Counterparty, Company, Employee';
							|it = 'Counterparty, Company, Employee';
							|pl = 'Counterparty, Company, Employee';
							|tr = 'Cari hesap, İş yeri, Çalışan'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn bên';
							|ru = 'Выбор стороны';
							|en = 'Select a party'; fa = 'Select a party';
							|it = 'Selezione della parte';
							|pl = 'Wybór strony';
							|tr = 'Taraf seçimi'");
	Else
		Presentation = NStr("ru = 'Контрагенты, Организации, Сотрудники';
							|vi = 'Counterparties, Companies, Employees';
							|en = 'Counterparties, Companies, Employees'; fa = 'Counterparties, Companies, Employees';
							|it = 'Counterparties, Companies, Employees';
							|pl = 'Counterparties, Companies, Employees';
							|tr = 'Cari hesaplar, İş yerleri, Çalışanlar'");
	EndIf;
	TypesPresentation1.Insert("DMParty", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dự án';
							|ru = 'Проект';
							|en = 'Project'; fa = 'پروژه';
							|it = 'Progetto';
							|pl = 'Projekt';
							|tr = 'Proje'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dự án';
							|ru = 'Выбор проекта';
							|en = 'Select project '; fa = 'Select project ';
							|it = 'Selezione del progetto';
							|pl = 'Wybór projektu';
							|tr = 'Proje seçimi'");
	Else
		Presentation = NStr("vi = 'Dự án';
							|ru = 'Проекты';
							|en = 'Projects'; fa = 'پروژه‌ها';
							|it = 'Progetti';
							|pl = 'Projekty';
							|tr = 'Projeler'");
	EndIf;
	TypesPresentation1.Insert("DMProject", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhiệm vụ dự án';
							|ru = 'Проектная задача';
							|en = 'Project task'; fa = 'وظیفه پروژه';
							|it = 'Compito del progetto';
							|pl = 'Zadanie projektowe';
							|tr = 'Proje görevi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhiệm vụ dự án';
							|ru = 'Выбор проектной задачи';
							|en = 'Select project task'; fa = 'Select project task';
							|it = 'Selezione del compito di progetto';
							|pl = 'Wybór zadania projektowego';
							|tr = 'Proje görevi seçimi'");
	Else
		Presentation = NStr("vi = 'Nhiệm vụ dự án';
							|ru = 'Проектные задачи';
							|en = 'Project tasks'; fa = 'وظایف پروژه';
							|it = 'Compiti del progetto';
							|pl = 'Zadania projektowe';
							|tr = 'Proje görevleri'");
	EndIf;
	TypesPresentation1.Insert("DMProjectTask", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng dự án';
							|ru = 'Вид проекта';
							|en = 'Project type'; fa = 'نوع پروژه';
							|it = 'Вид проекта';
							|pl = 'Project type';
							|tr = 'Proje türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng dự án';
							|ru = 'Выбор вида проекта';
							|en = 'Select a project type'; fa = 'Select a project type';
							|it = 'Выбор вида проекта';
							|pl = 'Select a project type';
							|tr = 'Proje türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng dự án';
							|ru = 'Виды проектов';
							|en = 'Project types'; fa = 'Project types';
							|it = 'Виды проектов';
							|pl = 'Project types';
							|tr = 'Proje türleri'");
	EndIf;
	TypesPresentation1.Insert("DMProjectType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Chủ đề thảo luận';
							|ru = 'Тема обсуждения';
							|en = 'Discussion topic'; fa = 'Discussion topic';
							|it = 'Argomento di discussione';
							|pl = 'Temat dyskusji';
							|tr = 'Tartışma konusu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn chủ đề thảo luận';
							|ru = 'Выбор темы обсуждений';
							|en = 'Select a discussion topic'; fa = 'Select a discussion topic';
							|it = 'Selezionare l''argomento di discussione';
							|pl = 'Wybór tematu dyskusji';
							|tr = 'Tartışma konusu seçimi'");
	Else
		Presentation = NStr("vi = 'Chủ đề thảo luận';
							|ru = 'Темы обсуждений';
							|en = 'Discussion topics'; fa = 'Discussion topics';
							|it = 'Argomenti di discussione';
							|pl = 'Tematy dyskusji';
							|tr = 'Tartışma konuları'");
	EndIf;
	TypesPresentation1.Insert("DMDiscussionTopic", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thông báo thảo luận';
							|ru = 'Сообщение обсуждения';
							|en = 'Discussion message'; fa = 'Discussion message';
							|it = 'Messaggio discussione';
							|pl = 'Wiadomość dyskusji';
							|tr = 'Tartışma mesajı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thông báo thảo luận';
							|ru = 'Выбор сообщения обсуждений';
							|en = 'Select a discussion message'; fa = 'Select a discussion message';
							|it = 'Selezionare messaggio di discussioni';
							|pl = 'Wybór wiadomości dyskusji';
							|tr = 'Tartışma mesajı seçimi'");
	Else
		Presentation = NStr("vi = 'Thông báo thảo luận';
							|ru = 'Сообщения обсуждений';
							|en = 'Discussion messages'; fa = 'Discussion messages';
							|it = 'Messaggi discussioni';
							|pl = 'Wiadomości dyskusji';
							|tr = 'Tartışma mesajı'");
	EndIf;
	TypesPresentation1.Insert("DMDiscussionMessage", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Tệp';
							|ru = 'Файл';
							|en = 'File'; fa = 'فایل';
							|it = 'File';
							|pl = 'Plik';
							|tr = 'Dosya'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn tệp';
							|ru = 'Выбор файла';
							|en = 'Select file'; fa = 'انتخاب فایل';
							|it = 'Selezione del file';
							|pl = 'Wybór pliku';
							|tr = 'Dosya seçimi'");
	Else
		Presentation = NStr("vi = 'Tệp';
							|ru = 'Файлы';
							|en = 'Files'; fa = 'فایل‌ها';
							|it = 'File';
							|pl = 'Pliki';
							|tr = 'Dosyalar'");
	EndIf;
	TypesPresentation1.Insert("DMFile", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thư mục tệp';
							|ru = 'Папка файлов';
							|en = 'File folder'; fa = 'پوشه فایل';
							|it = 'Cartella di file';
							|pl = 'Folder plików';
							|tr = 'Dosya klasörleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thư mục tệp';
							|ru = 'Выбор папки файлов';
							|en = 'Select file folder'; fa = 'Select file folder';
							|it = 'Selezione cartella file';
							|pl = 'Wybór folderu plików';
							|tr = 'Dosya klasörleri seçimi'");
	Else
		Presentation = NStr("vi = 'Thư mục tệp';
							|ru = 'Папки файлов';
							|en = 'File folders'; fa = 'پوشه‌های فایل';
							|it = 'Cartelle di file';
							|pl = 'Fołdery plików';
							|tr = 'Dosya klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMFileFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thư mục văn bản';
							|ru = 'Папка документов';
							|en = 'Document folder'; fa = 'Document folder';
							|it = 'Cartella documenti';
							|pl = 'Folder dokumentów';
							|tr = 'Belge klasörleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thư mục văn bản';
							|ru = 'Выбор папки документов';
							|en = 'Select a document folder'; fa = 'Select a document folder';
							|it = 'Scelta della cartella documenti';
							|pl = 'Wybór folderu dokumentów';
							|tr = 'Belge klasörleri seçimi'");
	Else
		Presentation = NStr("vi = 'Thư mục văn bản';
							|ru = 'Папки документов';
							|en = 'Document folders'; fa = 'Document folders';
							|it = 'Cartelle documenti';
							|pl = 'Foldery dokumentów';
							|tr = 'Belge klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMDocumentFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thư mục cuộc họp.';
							|ru = 'Папка мероприятий';
							|en = 'Event folder'; fa = 'Event folder';
							|it = 'Cartella eventi';
							|pl = 'Folder wydarzeń';
							|tr = 'Etkinlikleri klasörü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thư mục cuộc họp';
							|ru = 'Выбор папки мероприятий';
							|en = 'Select an event folder'; fa = 'Select an event folder';
							|it = 'Scelta della cartella eventi';
							|pl = 'Wybór folderu wydarzeń';
							|tr = 'Etkinlikleri klasörü seçimi'");
	Else
		Presentation = NStr("vi = 'Thư mục cuộc họp';
							|ru = 'Папки мероприятий';
							|en = 'Event folders'; fa = 'Event folders';
							|it = 'Cartelle eventi';
							|pl = 'Foldery wydarzeń';
							|tr = 'Etkinliklerin klasörleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingFolder", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Người sử dụng';
							|ru = 'Пользователь';
							|en = 'User'; fa = 'کاربر';
							|it = 'Utente';
							|pl = 'Użytkownik';
							|tr = 'Kullanıcı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn người sử dụng';
							|ru = 'Выбор пользователя';
							|en = 'Select user'; fa = 'انتخاب کاربر';
							|it = 'Scelta di un utente';
							|pl = 'Wybór użytkownika';
							|tr = 'Kullanıcı seçimi'");
	Else
		Presentation = NStr("vi = 'Người sử dụng';
							|ru = 'Пользователи';
							|en = 'Users'; fa = 'کاربران';
							|it = 'Utenti';
							|pl = 'Użytkownicy';
							|tr = 'Kullanıcılar'");
	EndIf;
	TypesPresentation1.Insert("DMUser", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhóm người sử dụng';
							|ru = 'Группа пользователей';
							|en = 'User group'; fa = 'گروه کاربران';
							|it = 'Gruppo di utenti';
							|pl = 'Grupa użytkowników';
							|tr = 'Kullanıcı grubu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhóm người sử dụng';
							|ru = 'Выбор группы пользователей';
							|en = 'Select user group'; fa = 'انتخاب گروه کاربری';
							|it = 'Selezione del gruppo di utenti';
							|pl = 'Wybór grupy użytkowników';
							|tr = 'Kullanıcı grubunu seçin'");
	Else
		Presentation = NStr("vi = 'Nhóm người sử dụng';
							|ru = 'Группы пользователей';
							|en = 'User groups'; fa = 'گروه‌های کاربران';
							|it = 'Gruppi di utenti';
							|pl = 'Grupy użytkowników';
							|tr = 'Kullanıcı grupları'");
	EndIf;
	TypesPresentation1.Insert("DMUserGroup", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhân viên';
							|ru = 'Сотрудник';
							|en = 'Employee'; fa = 'کارمند';
							|it = 'Dipendente';
							|pl = 'Pracownik';
							|tr = 'Çalışan'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhân viên';
							|ru = 'Выбор сотрудника';
							|en = 'Select an employee'; fa = 'انتخاب کارمند';
							|it = 'Scelta dipendente';
							|pl = 'Wybór pracownika';
							|tr = 'Çalışan seçimi'");
	Else
		Presentation = NStr("vi = 'Nhân viên';
							|ru = 'Сотрудники';
							|en = 'Employees'; fa = 'کارکنان';
							|it = 'Dipendenti';
							|pl = 'Pracownicy';
							|tr = 'Çalışanlar'");
	EndIf;
	TypesPresentation1.Insert("DMEmployee", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Vấn đề nghiệp vụ';
							|ru = 'Вопрос деятельности';
							|en = 'Activity issue'; fa = 'موضوع فعالیت';
							|it = 'Problema di attività';
							|pl = 'Kwestia działalności';
							|tr = 'Faaliyet sorusu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn lĩnh vực hoạt động';
							|ru = 'Выбор вопроса деятельности';
							|en = 'Select activity issue'; fa = 'Select activity issue';
							|it = 'Selezione problema di attività';
							|pl = 'Wybór kwestii działalności';
							|tr = 'Faaliyet sorusu seçimi'");
	Else
		Presentation = NStr("vi = 'Vấn đề nghiệp vụ';
							|ru = 'Вопросы деятельности';
							|en = 'Activity issues'; fa = 'Activity issues';
							|it = 'Problemi di attività';
							|pl = 'Kwestie działalności';
							|tr = 'Faaliyet soruları'");
	EndIf;
	TypesPresentation1.Insert("DMActivityMatter", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Tiền tệ';
							|ru = 'Валюта';
							|en = 'Currency'; fa = 'ارز';
							|it = 'Valuta';
							|pl = 'Waluta';
							|tr = 'Para birimi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn tiền tệ';
							|ru = 'Выбор валюты';
							|en = 'Select currency '; fa = 'Select currency ';
							|it = 'Selezione valuta';
							|pl = 'Wybór waluty';
							|tr = 'Para birimi seçimi'");
	Else
		Presentation = NStr("vi = 'Tiền tệ';
							|ru = 'Валюты';
							|en = 'Currencies'; fa = 'ارزها';
							|it = 'Valute';
							|pl = 'Waluty';
							|tr = 'Para birimleri'");
	EndIf;
	TypesPresentation1.Insert("DMCurrency", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Ngân hàng';
							|ru = 'Банк';
							|en = 'Bank'; fa = 'بانک';
							|it = 'Банк';
							|pl = 'Bank';
							|tr = 'Banka'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn ngân hàng';
							|ru = 'Выбор банка';
							|en = 'Select a bank'; fa = 'Select a bank';
							|it = 'Выбор банка';
							|pl = 'Select a bank';
							|tr = 'Banka seçimi'");
	Else
		Presentation = NStr("vi = 'Ngân hàng';
							|ru = 'Банки';
							|en = 'Banks'; fa = 'بانک‌ها';
							|it = 'Банки';
							|pl = 'Banks';
							|tr = 'Bankalar'");
	EndIf;
	TypesPresentation1.Insert("DMBank", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Quốc gia';
							|ru = 'Страна';
							|en = 'Country'; fa = 'کشور';
							|it = 'Страна';
							|pl = 'Country';
							|tr = 'Ülke'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn quốc gia';
							|ru = 'Выбор страны';
							|en = 'Select a country'; fa = 'Select a country';
							|it = 'Выбор страны';
							|pl = 'Select a country';
							|tr = 'Ülke seçimi'");
	Else
		Presentation = NStr("vi = 'Quốc gia';
							|ru = 'Страны';
							|en = 'Countries'; fa = 'کشورها';
							|it = 'Страны';
							|pl = 'Countries';
							|tr = 'Ülkeler'");
	EndIf;
	TypesPresentation1.Insert("DMCountry", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Thuế suất GTGT';
							|ru = 'Ставка НДС';
							|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
							|it = 'Ставка НДС';
							|pl = 'Stawka VAT';
							|tr = 'KDV oranı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn thuế suất GTGT';
							|ru = 'Выбор ставки НДС';
							|en = 'Select a VAT rate'; fa = 'Select a VAT rate';
							|it = 'Выбор ставки НДС';
							|pl = 'Wybór stawki VAT';
							|tr = 'KDV oranı seçimi'");
	Else
		Presentation = NStr("vi = 'Thuế suất GTGT';
							|ru = 'Ставки НДС';
							|en = 'VAT rates'; fa = 'نرخ‌های مالیات بر ارزش افزوده';
							|it = 'Ставки НДС';
							|pl = 'Stawki VAT';
							|tr = 'KDV oranları'");
	EndIf;
	TypesPresentation1.Insert("DMVATRateUniversal", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Văn bản';
							|ru = 'Документ';
							|en = 'Document'; fa = 'سند';
							|it = 'Documento';
							|pl = 'Dokument';
							|tr = 'Belge'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn văn bản';
							|ru = 'Выбор документа';
							|en = 'Select document'; fa = 'انتخاب سند';
							|it = 'Scelta documento';
							|pl = 'Wybór dokumentu';
							|tr = 'Belge seçimi'");
	Else
		Presentation = NStr("vi = 'Văn bản';
							|ru = 'Документы';
							|en = 'Documents'; fa = 'اسناد';
							|it = 'Documenti';
							|pl = 'Dokumenty';
							|tr = 'Belgeler'");
	EndIf;
	TypesPresentation1.Insert("DMDocument", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cuộc họp';
							|ru = 'Мероприятие';
							|en = 'Activity'; fa = 'فعالیت';
							|it = 'Evento';
							|pl = 'Przedsięwzięcie';
							|tr = 'Etkinlik'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cuộc họp';
							|ru = 'Выбор мероприятия';
							|en = 'Select an activity'; fa = 'Select an activity';
							|it = 'Scelta evento';
							|pl = 'Wybór wydarzenia';
							|tr = 'Etkinlik seçimi'");
	Else
		Presentation = NStr("vi = 'Cuộc họp';
							|ru = 'Мероприятия';
							|en = 'Activities'; fa = 'Activities';
							|it = 'Eventi';
							|pl = 'Wydarzenia';
							|tr = 'Etkinlik'");
	EndIf;
	TypesPresentation1.Insert("DMMeeting", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организация';
							|en = 'Company'; fa = 'Company';
							|it = 'Azienda';
							|pl = 'Firma';
							|tr = 'İş yeri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn doanh nghiệp';
							|ru = 'Выбор организации';
							|en = 'Select company'; fa = 'Select company';
							|it = 'Selezione azienda';
							|pl = 'Wybór firmy';
							|tr = 'İş yeri seçimi'");
	Else
		Presentation = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организации';
							|en = 'Companies'; fa = 'شرکت‌ها';
							|it = 'Aziende';
							|pl = 'Organizacje';
							|tr = 'İş yerleri'");
	EndIf;
	TypesPresentation1.Insert("DMOrganization", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Đối tác';
							|ru = 'Контрагент';
							|en = 'Counterparty'; fa = 'طرف حساب';
							|it = 'Controparte';
							|pl = 'Kontrahent';
							|tr = 'Cari hesap'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn đối tác';
							|ru = 'Выбор контрагента';
							|en = 'Select a counterparty'; fa = 'Select a counterparty';
							|it = 'Selezione controparte';
							|pl = 'Wybór kontrahenta';
							|tr = 'Cari hesap seçimi'");
	Else
		Presentation = NStr("vi = 'Đối tác';
							|ru = 'Контрагенты';
							|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
							|it = 'Controparti';
							|pl = 'Kontrahenci';
							|tr = 'Cari hesaplar'");
	EndIf;
	TypesPresentation1.Insert("DMCorrespondent", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Người liên hệ';
							|ru = 'Контактное лицо';
							|en = 'Contact person'; fa = 'شخص تماس';
							|it = 'Contatto';
							|pl = 'Osoba do kontaktu';
							|tr = 'İrtibat kişisi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn người liên hệ';
							|ru = 'Выбор контактного лица';
							|en = 'Select contact person'; fa = 'Select contact person';
							|it = 'Selezione contatto';
							|pl = 'Wybór osoby kontaktowej';
							|tr = 'İlgili kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Người liên hệ';
							|ru = 'Контактные лица';
							|en = 'Contact persons'; fa = 'اشخاص تماس';
							|it = 'Persone di contatto';
							|pl = 'Osoby kontaktowe';
							|tr = 'İlgili kişiler'");
	EndIf;
	TypesPresentation1.Insert("DMContactPerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Độ mật';
							|ru = 'Гриф доступа';
							|en = 'Access label'; fa = 'برچسب دسترسی';
							|it = 'Dicitura di accesso';
							|pl = 'Poziom dostępu';
							|tr = 'Erişim etiketi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn độ mật';
							|ru = 'Выбор грифа доступа';
							|en = 'Select access label'; fa = 'Select access label';
							|it = 'Selezione dicitura di accesso';
							|pl = 'Wybór poziomu dostępu';
							|tr = 'Erişim etiketi seçimi'");
	Else
		Presentation = NStr("vi = 'Độ mật';
							|ru = 'Грифы доступа';
							|en = 'Access labels'; fa = 'Access labels';
							|it = 'Diciture di accesso';
							|pl = 'Poziomy dostępu';
							|tr = 'Erişim etiketleri'");
	EndIf;
	TypesPresentation1.Insert("DMAccessLevel", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Phương thức truyền';
							|ru = 'Способ доставки';
							|en = 'Delivery method'; fa = 'روش تحویل';
							|it = 'Metodo di consegna';
							|pl = 'Sposób dostarczenia';
							|tr = 'Teslimat yöntemi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn phương thức truyền';
							|ru = 'Выбор способа доставки';
							|en = 'Select delivery method'; fa = 'Select delivery method';
							|it = 'Selezione metodo di consegna';
							|pl = 'Wybór sposobu dostawy';
							|tr = 'Teslimat yöntemi seçimi'");
	Else
		Presentation = NStr("vi = 'Phương thức truyền';
							|ru = 'Способы доставки';
							|en = 'Delivery methods'; fa = 'روش‌های تحویل';
							|it = 'Metodi di consegna';
							|pl = 'Sposoby dostawy';
							|tr = 'Teslimat yöntemleri'");
	EndIf;
	TypesPresentation1.Insert("DMDeliveryMethod", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Bộ phận';
							|ru = 'Подразделение';
							|en = 'Business unit'; fa = 'Business unit';
							|it = 'Reparto';
							|pl = 'Dział';
							|tr = 'Departman'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn bộ phận';
							|ru = 'Выбор подразделения';
							|en = 'Select business unit'; fa = 'Select business unit';
							|it = 'Selezione del reparto';
							|pl = 'Wybór działu';
							|tr = 'Departman seçimi'");
	Else
		Presentation = NStr("vi = 'Bộ phận';
							|ru = 'Подразделения';
							|en = 'Business units'; fa = 'واحدهای تجاری';
							|it = 'Reparti';
							|pl = 'Działy';
							|tr = 'Departman'");
	EndIf;
	TypesPresentation1.Insert("DMSubdivision", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng văn bản';
							|ru = 'Вид документа';
							|en = 'Document kind'; fa = 'نوع سند';
							|it = 'Tipologia di documento';
							|pl = 'Rodzaj dokumentu';
							|tr = 'Belge türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng văn bản';
							|ru = 'Выбор вида документов';
							|en = 'Select a document kind'; fa = 'Select a document kind';
							|it = 'Selezione del tipo di documento';
							|pl = 'Wybór rodzaju dokumentów';
							|tr = 'Belge türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng văn bản';
							|ru = 'Виды документов';
							|en = 'Document kinds'; fa = 'انواع سند';
							|it = 'Tipi di documenti';
							|pl = 'Rodzaje dokumentów';
							|tr = 'Belge türleri'");
	EndIf;
	TypesPresentation1.Insert("DMDocumentType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng cuộc họp';
							|ru = 'Вид мероприятия';
							|en = 'Event type'; fa = 'نوع رویداد';
							|it = 'Tipo di evento';
							|pl = 'Rodzaj wydarzenia';
							|tr = 'Etkinlik türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng cuộc họp';
							|ru = 'Выбор вида мероприятия';
							|en = 'Select an event type'; fa = 'Select an event type';
							|it = 'Selezione del tipo di evento';
							|pl = 'Wybór rodzaju wydarzenia';
							|tr = 'Etkinlik türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng cuộc họp';
							|ru = 'Виды мероприятий';
							|en = 'Event types'; fa = 'Event types';
							|it = 'Tipi di eventi';
							|pl = 'Rodzaje wydarzeń';
							|tr = 'Etkinlik türleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeetingType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng công việc';
							|ru = 'Вид работ';
							|en = 'Activity kind'; fa = 'نوع فعالیت';
							|it = 'Tipo di lavori';
							|pl = 'Rodzaj prac';
							|tr = 'İş türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng công việc';
							|ru = 'Выбор вида работ';
							|en = 'Select activity kind'; fa = 'Select activity kind';
							|it = 'Selezione del tipo di lavori';
							|pl = 'Wybór rodzaju prac';
							|tr = 'İş türü seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng công việc';
							|ru = 'Виды работ';
							|en = 'Activity kinds'; fa = 'انواع فعالیت';
							|it = 'Tipi di lavori';
							|pl = 'Rodzaje prac';
							|tr = 'İş türleri'");
	EndIf;
	TypesPresentation1.Insert("DMWorkType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Kiểu liên kết';
							|ru = 'Тип связей';
							|en = 'Link type'; fa = 'نوع پیوند';
							|it = 'Tipo di connessioni';
							|pl = 'Typ powiązań';
							|tr = 'Bağlantı türü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn kiểu liên kết';
							|ru = 'Выбор типа связей';
							|en = 'Select a link type'; fa = 'Select a link type';
							|it = 'Selezione del tipo di connessioni';
							|pl = 'Wybór typu powiązań';
							|tr = 'Bağlantı türü seçimi'");
	Else
		Presentation = NStr("vi = 'Kiểu liên kết';
							|ru = 'Типы связей';
							|en = 'Link types'; fa = 'انواع پیوند';
							|it = 'Tipi di connessioni';
							|pl = 'Typy powiązań';
							|tr = 'Bağlantı türleri'");
	EndIf;
	TypesPresentation1.Insert("DMRelationType", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Giá trị thuộc tính đối tượng';
							|ru = 'Значение свойств объектов';
							|en = 'Object property value'; fa = 'Object property value';
							|it = 'Valori delle proprietà degli oggetti';
							|pl = 'Wartość właściwości obiektów';
							|tr = 'Nesnelerin özellik değerleri'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn giá trị thuộc tính đối tượng';
							|ru = 'Выбор значения свойств объектов';
							|en = 'Select an object property value'; fa = 'Select an object property value';
							|it = 'Scelta valori delle proprietà degli oggetti';
							|pl = 'Wybór wartości właściwości obiektów';
							|tr = 'Nesnelerin özellik değeri seçimi'");
	Else
		Presentation = NStr("vi = 'Giá trị thuộc tính đối tượng';
							|ru = 'Значения свойств объектов';
							|en = 'Object property values'; fa = 'Object property values';
							|it = 'Valori delle proprietà degli oggetti';
							|pl = 'Wartości właściwości obiektów';
							|tr = 'Nesnelerin özellik değeri'");
	EndIf;
	TypesPresentation1.Insert("DMObjectPropertyValue", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cá nhân';
							|ru = 'Физическое лицо';
							|en = 'Person'; fa = 'شخص';
							|it = 'Persona fisica';
							|pl = 'Osoba fizyczna';
							|tr = 'Gerçek kişi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cá nhân';
							|ru = 'Выбор физического лица';
							|en = 'Select person'; fa = 'Select person';
							|it = 'Selezione persona fisica';
							|pl = 'Wybór osoby fizycznej';
							|tr = 'Gerçek kişi seçimi'");
	Else
		Presentation = NStr("vi = 'Cá nhân';
							|ru = 'Физические лица';
							|en = 'Persons'; fa = 'اشخاص';
							|it = 'Persone fisiche';
							|pl = 'Osoby fizyczne';
							|tr = 'Gerçek kişiler'");
	EndIf;
	TypesPresentation1.Insert("DMPrivatePerson", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Điều kiện lộ trình hóa';
							|ru = 'Условие маршрутизации';
							|en = 'Routing condition'; fa = 'Routing condition';
							|it = 'Condizioni di routing';
							|pl = 'Warunek trasowania';
							|tr = 'Yönlendirme koşulu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn điều kiện lộ trình hóa';
							|ru = 'Выбор условия маршрутизации';
							|en = 'Select a routing condition'; fa = 'Select a routing condition';
							|it = 'Scelta condizioni di routing';
							|pl = 'Wybór warunku trasowania';
							|tr = 'Yönlendirme koşulunun seçimi'");
	Else
		Presentation = NStr("vi = 'Điều kiện lộ trình hóa';
							|ru = 'Условия маршрутизации';
							|en = 'Routing conditions'; fa = 'Routing conditions';
							|it = 'Condizioni di routing';
							|pl = 'Warunki trasowania';
							|tr = 'Yönlendirme koşulu'");
	EndIf;
	TypesPresentation1.Insert("DMRoutingCondition", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Cá nhân nhận:';
							|ru = 'Личный адресат';
							|en = 'Personal addressee'; fa = 'Personal addressee';
							|it = 'Destinatario personale';
							|pl = 'Adresat osobisty';
							|tr = 'Kişisel alıcı'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn cá nhân nhận';
							|ru = 'Выбор личного адресата';
							|en = 'Select a personal addressee'; fa = 'Select a personal addressee';
							|it = 'Scelta destinatario personale';
							|pl = 'Wybór adresatu osobistego';
							|tr = 'Kişisel alıcı seçimi'");
	Else
		Presentation = NStr("vi = 'Cá nhân nhận';
							|ru = 'Личные адресаты';
							|en = 'Personal addressees'; fa = 'مخاطبان شخصی';
							|it = 'Destinatari personali';
							|pl = 'Adresaci osobiste';
							|tr = 'Kişisel alıcılar'");
	EndIf;
	TypesPresentation1.Insert("DMPersonalRecipient", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Nhóm cá nhân nhận';
							|ru = 'Группа личных адресатов';
							|en = 'Personal addressees group'; fa = 'Personal addressees group';
							|it = 'Gruppo di destinatari personali';
							|pl = 'Grupa adresatów osobistych';
							|tr = 'Kişisel alıcılar grubu'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn nhóm cá nhân nhận';
							|ru = 'Выбор группы личных адресатов';
							|en = 'Select personal addressees group'; fa = 'Select personal addressees group';
							|it = 'Scelta gruppo di destinatari personali';
							|pl = 'Wybór grupy adresatów osobistych';
							|tr = 'Kişisel alıcılar grubu seçimi'");
	Else
		Presentation = NStr("vi = 'Nhóm cá nhân nhận';
							|ru = 'Группы личных адресатов';
							|en = 'Personal addressee groups'; fa = 'Personal addressee groups';
							|it = 'Gruppi dei destinatari personali';
							|pl = 'Grupy adresatów osobistych';
							|tr = 'Kişisel alıcı grupları'");
	EndIf;
	TypesPresentation1.Insert("DMPersonalRecipientGroup", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Vai trò người thực hiện';
							|ru = 'Роль исполнителя';
							|en = 'Business role'; fa = 'نقش کسب‌وکار';
							|it = 'Ruolo dell''esecutore';
							|pl = 'Rola wykonawcy';
							|tr = 'Atanan rolü'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn vai trò người thực hiện';
							|ru = 'Выбор роли исполнителей';
							|en = 'Select a business role'; fa = 'Select a business role';
							|it = 'Scelta del ruolo degli esecutori';
							|pl = 'Wybór roli wykonawcy';
							|tr = 'Yürütücü rolü seçimi'");
	Else
		Presentation = NStr("vi = 'Vai trò người thực hiện';
							|ru = 'Роли исполнителей';
							|en = 'Assignee roles'; fa = 'Assignee roles';
							|it = 'Ruoli degli esecutori';
							|pl = 'Role wykonawców';
							|tr = 'Yürütücülerin rolleri'");
	EndIf;
	TypesPresentation1.Insert("DMBusinessProcessExecutorRole", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Dạng lưu chuyển tiền tệ';
							|ru = 'Статья движения денежных средств';
							|en = 'Cash flow item'; fa = 'قلم جریان وجوه نقد';
							|it = 'Voce flussi di denaro';
							|pl = 'Kierunek ruchu środków pieniężnych';
							|tr = 'Nakit akışı öğesi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn dạng lưu chuyển tiền tệ';
							|ru = 'Выбор статьи движения денежных средств';
							|en = 'Select a cash flow item'; fa = 'Select a cash flow item';
							|it = 'Scelta delle voci del flusso di denaro';
							|pl = 'Wybór pozycji przepływów pieniężnych';
							|tr = 'Nakit akışı öğeleri seçimi'");
	Else
		Presentation = NStr("vi = 'Dạng lưu chuyển tiền tệ';
							|ru = 'Статьи движения денежных средств';
							|en = 'Cash flow items'; fa = 'اقلام جریان وجوه نقد';
							|it = 'Voci flusso di denaro';
							|pl = 'Pozycje przepływów środków pieniężnych';
							|tr = 'Nakit akışı öğeleri'");
	EndIf;
	TypesPresentation1.Insert("DMCashFlowItem", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Đơn vị tính';
							|ru = 'Единица измерения';
							|en = 'Unit'; fa = 'واحد';
							|it = 'Unità di misura';
							|pl = 'Jednosta miary';
							|tr = 'Ölçü birimi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn đơn vị tính';
							|ru = 'Выбор единицы измерения';
							|en = 'Select a unit'; fa = 'Select a unit';
							|it = 'Scelta dell''unità di misura';
							|pl = 'Wybór jednostki miary';
							|tr = 'Ölçü birimi seçimi'");
	Else
		Presentation = NStr("vi = 'Đơn vị tính';
							|ru = 'Единицы измерения';
							|en = 'Units of measure'; fa = 'واحدهای اندازه‌گیری';
							|it = 'Unità di misura';
							|pl = 'Jednostki miary';
							|tr = 'Ölçü birimleri'");
	EndIf;
	TypesPresentation1.Insert("DMMeasurementUnit", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Hàng hóa, dịch vụ';
							|ru = 'Товар, услуга';
							|en = 'Good, service'; fa = 'کالا، خدمت';
							|it = 'Articolo, servizio';
							|pl = 'Towar, usługa';
							|tr = 'Ürün, hizmet'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn mặt hàng';
							|ru = 'Выбор номенклатуры';
							|en = 'Select items'; fa = 'انتخاب اقلام';
							|it = 'Selezionare gli articoli';
							|pl = 'Wybór nomenklatury';
							|tr = 'Öğe seçimi'");
	Else
		Presentation = NStr("vi = 'Hàng hóa và dịch vụ';
							|ru = 'Товары и услуги';
							|en = 'Goods and services'; fa = 'کالاها و خدمات';
							|it = 'Articoli e servizi';
							|pl = 'Towary i usługi';
							|tr = 'Ürünler ve hizmetler'");
	EndIf;
	TypesPresentation1.Insert("DMProduct", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'Mục tin / thông tin bổ sung';
							|ru = 'Дополнительный реквизит / сведение';
							|en = 'Additional attribute or information record'; fa = 'ویژگی تکمیلی یا رکورد اطلاعاتی';
							|it = 'Requisito/informazione aggiuntivi';
							|pl = 'Dodatkowy rekwizyt / informacja';
							|tr = 'Ek öznitelik / bilgi'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn mục tin bổ sung';
							|ru = 'Выбор дополнительного реквизита';
							|en = 'Select an additional attribute'; fa = 'Select an additional attribute';
							|it = 'Scelta dell''attributo aggiuntivo';
							|pl = 'Wybór atrybutu dodatkowego';
							|tr = 'Ek öznitelik seçimi'");
	Else
		Presentation = NStr("vi = 'Mục tin và thông tin bổ sung';
							|ru = 'Дополнительные реквизиты и сведения';
							|en = 'Additional attributes and information'; fa = 'Additional attributes and information';
							|it = 'Requisiti e informazioni aggiuntivi';
							|pl = 'Dodatkowe rekwizyty i informacje';
							|tr = 'Ek öznitelikler ve bilgiler'");
	EndIf;
	TypesPresentation1.Insert("DMAdditionalProperty", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'E-mail đến';
							|ru = 'Входящее письмо';
							|en = 'Incoming mail'; fa = 'ایمیل ورودی';
							|it = 'E-mail in arrivo';
							|pl = 'Przychodzący list';
							|tr = 'Gelen e-posta'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn email đến';
							|ru = 'Выбор входящего письма';
							|en = 'Select incoming email'; fa = 'Select incoming email';
							|it = 'Selezione posta in entrata';
							|pl = 'Wybór wiadomości wchodzącej';
							|tr = 'Gelen ileti seçimi'");
	Else
		Presentation = NStr("vi = 'E-mail đến';
							|ru = 'Входящие письма';
							|en = 'Incoming mails'; fa = 'ایمیل‌های ورودی';
							|it = 'Mail in entrata';
							|pl = 'Wiadomości e-mail przychodzące';
							|tr = 'Gelen e-posta'");
	EndIf;
	TypesPresentation1.Insert("DMIncomingEMail", Presentation);
	
	If SingularForm Then
		Presentation = NStr("vi = 'E-mail đi';
							|ru = 'Исходящее письмо';
							|en = 'Outgoing mail'; fa = 'ایمیل خروجی';
							|it = 'Messaggio in uscita';
							|pl = 'List wychodzący';
							|tr = 'Giden e-posta'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("vi = 'Chọn E-mail đi';
							|ru = 'Выбор исходящего письма';
							|en = 'Select outgoing email'; fa = 'Select outgoing email';
							|it = 'Selezione posta in uscita';
							|pl = 'Wybór wiadomości wychodzącej';
							|tr = 'Giden ileti seçimi'");
	Else
		Presentation = NStr("vi = 'E-mail đi';
							|ru = 'Исходящие письма';
							|en = 'Outgoing mails'; fa = 'ایمیل‌های خروجی';
							|it = 'Lettere in uscita';
							|pl = 'Wiadomości wychodzące';
							|tr = 'Giden e-posta'");
	EndIf;
	TypesPresentation1.Insert("DMOutgoingEMail", Presentation);
	
	If SingularForm Then
		Presentation = NStr("ru = 'Ежедневный отчет';
							|vi = 'Daily report';
							|en = 'Daily report'; fa = 'گزارش روزانه';
							|it = 'Report giornaliero';
							|pl = 'Codzienny raport';
							|tr = 'Günlük rapor'");
	ElsIf ForFormOfSelection Then
		Presentation = NStr("ru = 'Выбор ежедневного отчета';
							|vi = 'Select daily report';
							|en = 'Select daily report'; fa = 'Select daily report';
							|it = 'Selezione report giornaliero';
							|pl = 'Wybór raportu codziennego';
							|tr = 'Günlük rapor seçimi'");
	Else
		Presentation = NStr("ru = 'Ежедневные отчеты';
							|vi = 'Daily reports';
							|en = 'Daily reports'; fa = 'گزارش‌های روزانه';
							|it = 'Report giornalieri';
							|pl = 'Codzienne raporty';
							|tr = 'Günlük raporlar'");
	EndIf;
	TypesPresentation1.Insert("DMDailyReport", Presentation);
	
EndProcedure

// Caption to the number of days by declination.
//
// Parameters:
//   NumberOfDays - Number - Number of days.
//
// Returns:
//   String
//
Function CaptionForNumberOfDays(NumberOfDays)
	
	If NumberOfDays > 10 And NumberOfDays < 20 Then
		Signature = NStr("vi = 'ngày';
						|ru = 'дней';
						|en = 'days'; fa = 'روز';
						|it = 'дней';
						|pl = 'dni';
						|tr = 'gün'");
	Else
		LastTwoDigits = NumberOfDays - Int(NumberOfDays / 100) * 100;
		LastDigit = NumberOfDays - Int(NumberOfDays / 10) * 10;
		
		If LastDigit = 0 Then
			Signature = NStr("vi = 'ngày';
							|ru = 'дней';
							|en = 'days'; fa = 'روز';
							|it = 'дней';
							|pl = 'dni';
							|tr = 'gün'");
		ElsIf LastTwoDigits > 10 And LastTwoDigits < 20 Then
			Signature = NStr("vi = 'ngày';
							|ru = 'дней';
							|en = 'days'; fa = 'روز';
							|it = 'дней';
							|pl = 'dni';
							|tr = 'gün'");
		ElsIf LastTwoDigits < 10 Or LastTwoDigits > 20 Then
			If LastDigit = 1 Then
				Signature = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'Day'; fa = 'روز';
								|it = 'дня';
								|pl = 'dnia';
								|tr = 'gün'");
			ElsIf LastDigit < 5 Then
				Signature = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'day'; fa = 'روز';
								|it = 'дня';
								|pl = 'dnia';
								|tr = 'gün'");
			Else
				Signature = NStr("vi = 'ngày';
								|ru = 'дней';
								|en = 'days'; fa = 'روز';
								|it = 'дней';
								|pl = 'dni';
								|tr = 'gün'");
			EndIf;
		EndIf;
	EndIf;
	
	Return Signature;
	
EndFunction

// Caption to the number of hours by declension.
//
// Parameters:
//   NumberOfHours - Number - the number of hours.
//
// Returns:
//   String
//
Function CaptionToNumberOfHours(NumberOfHours)
	
	If NumberOfHours > 10 And NumberOfHours < 20 Then
		Signature = NStr("vi = 'giờ';
						|ru = 'часов';
						|en = 'hours'; fa = 'ساعت';
						|it = 'часов';
						|pl = 'godzin';
						|tr = 'saat'");
	Else
		LastTwoDigits = NumberOfHours - Int(NumberOfHours / 100) * 100;
		LastDigit = NumberOfHours - Int(NumberOfHours / 10) * 10;
		
		If LastDigit = 0 Then
			Signature = NStr("vi = 'giờ';
							|ru = 'часов';
							|en = 'hours'; fa = 'ساعت';
							|it = 'часов';
							|pl = 'godzin';
							|tr = 'saat'");
		ElsIf LastTwoDigits > 10 And LastTwoDigits < 20 Then
			Signature = NStr("vi = 'giờ';
							|ru = 'часов';
							|en = 'hours'; fa = 'ساعت';
							|it = 'часов';
							|pl = 'godzin';
							|tr = 'saat'");
		ElsIf LastTwoDigits < 10 Or LastTwoDigits > 20 Then
			If LastDigit = 1 Then
				Signature = NStr("vi = 'giờ';
								|ru = 'час';
								|en = 'hour'; fa = 'hour';
								|it = 'час';
								|pl = 'godzina';
								|tr = 'saat'");
			ElsIf LastDigit < 5 Then
				Signature = NStr("vi = 'giờ';
								|ru = 'часов';
								|en = 'hours'; fa = 'ساعت';
								|it = 'часов';
								|pl = 'godzin';
								|tr = 'saat'");
			Else
				Signature = NStr("vi = 'giờ';
								|ru = 'часов';
								|en = 'hours'; fa = 'ساعت';
								|it = 'часов';
								|pl = 'godzin';
								|tr = 'saat'");
			EndIf;
		EndIf;
	EndIf;
	
	Return Signature;
	
EndFunction

// Returns a Presentation of the duration.
//
// Parameters:
//   Days - Number - duration, days.
//   Hours1 - Number - duration, hours.
//   Minutes1 - Number - duration, minutes.
//
// Returns:
//   String - Presentation of duration by string.
//
Function DurationPresentation(Days, Hours1, Minutes1)
	
	If Days = 0 And Hours1 = 0 And Minutes1 = 0 Then
		Return NStr("vi = 'không xác định';
					|ru = 'не определен';
					|en = 'undefined'; fa = 'undefined';
					|it = 'не определен';
					|pl = 'undefined';
					|tr = 'belirlenmedi'");
	EndIf;
	
	ArrayPresentation_ = New Array;
	
	ThereAreDays = ValueIsFilled(Days);
	ThereIsClock = ValueIsFilled(Hours1);
	ThereAreMinutes = ValueIsFilled(Minutes1);
	
	If ThereAreDays Then
		
		If ThereIsClock And ThereAreMinutes Then
			ArrayPresentation_.Add(StrTemplate(NStr("vi = '%1 ngày';
													|ru = '%1 дн.';
													|en = '%1 days'; fa = '%1 days';
													|it = '%1 giorni.';
													|pl = '%1 dn.';
													|tr = '%1 gün'"), Days));
		Else
			ArrayPresentation_.Add(
				StringWithNumber(
					NStr("vi = ';%1 ngày;;%1 ngày;%1 ngày;%1 ngày';
						|ru = ';%1 день;;%1 дня;%1 дней;%1 дня';
						|en = ';%1 day;;;;%1 days'; fa = ';%1 day;;;;%1 days';
						|it = ';%1 giorno;;%1 giorno;%1 giorni;%1 giorno';
						|pl = ';%1 dzień;;%1 dnia;%1 dni;%1 dnia';
						|tr = ';%1 gün;;%1 gün;%1 gün;%1 gün'"),
					Days,
					NumericValueType.Cardinal));
		EndIf;
		
	EndIf;
	
	If ThereIsClock Then
		
		If ThereAreDays And ThereAreMinutes Then
			ArrayPresentation_.Add(StrTemplate(NStr("vi = '%1 g';
													|ru = '%1 ч.';
													|en = '%1 h.'; fa = '%1 h.';
													|it = '%1 ore.';
													|pl = '%1 g.';
													|tr = '%1 sa.'"), Hours1));
		Else
			ArrayPresentation_.Add(
				StringWithNumber(
					NStr("vi = ';%1 giờ;;%1 giờ;%1 giờ;%1 giờ';
						|ru = ';%1 час;;%1 часа;%1 часов;%1 часа';
						|en = ';%1 hour;;;;%1 hours'; fa = ';%1 hour;;;;%1 hours';
						|it = ';%1 ora;;%1 ora;%1 ore;%1 ora';
						|pl = ';%1 godzina;;%1 godziny;%1 godzin;%1 godzin';
						|tr = ';%1 saat;;%1 saat;%1 saat;%1 saat'"),
					Hours1,
					NumericValueType.Cardinal));
		EndIf;
		
	EndIf;
	
	If ThereAreMinutes Then
		
		If ThereAreDays And ThereIsClock Then
			ArrayPresentation_.Add(StrTemplate(NStr("vi = '%1 phút';
													|ru = '%1 мин.';
													|en = '%1 min'; fa = '%1 min';
													|it = '%1 мин.';
													|pl = '%1 min';
													|tr = '%1 dk.'"), Minutes1));
		Else
			ArrayPresentation_.Add(
				StringWithNumber(
					NStr("vi = ';%1 phút;;%1 phút;%1 phút;%1 phút';
						|ru = ';%1 минута;;%1 минуты;%1 минут;%1 минуты';
						|en = ';%1 minute;;;;%1 minutes'; fa = ';%1 minute;;;;%1 minutes';
						|it = ';%1 минута;;%1 минуты;%1 минут;%1 минуты';
						|pl = ';%1 minute;;;;%1 minutes';
						|tr = ';%1 dakika;;%1 dakika;%1 dakika;%1 dakika'"),
					Minutes1,
					NumericValueType.Cardinal));
		EndIf;
		
	EndIf;
	
	Return StrConcat(ArrayPresentation_, " ");
	
EndFunction

// Converts all the results of actions to a single numerical scale according to the degree of success.
//
// Parameters:
//   Result - String - the result of the action.
//   ToSelectMinimum - Boolean - the mode of clipping non-significant values by a higher rank.
//
// Returns:
//   Number - from 0 to 9.
//
Function RankOfActionResult(Result, ToSelectMinimum = False)
	
	If Result = "" Then
		Return ?(ToSelectMinimum, 8, 0);
		
	ElsIf Result = "Signed" Or Result = "Received"
			Or Result = "Confirmed" Or Result = "Approved"
			Or Result = "Registered" Then
		Return 5;
		
	ElsIf Result = "Performed" Or Result = "Completed"
			Or Result = "Reviewed" Or Result = "Examined" Then
		Return 4;
		
	ElsIf Result = "ApprovedWithReservations" Then
		Return 3;
		
	ElsIf Result = "NotApproved" Or Result = "NotConfirmed"
			Or Result = "NotSigned" Or Result = "NotAccepted"
			Or Result = "NotRegistered" Then
		Return 2;
		
	ElsIf Result = "RefusalOfExamination" Or Result = "RefusalOfPerformance"
			Or Result = "RefusalOfReview" Then
		Return ?(ToSelectMinimum, 9, 1);
		
	Else
		Return 4;
		
	EndIf;
	
EndFunction

// Converts the State of the action to a single numerical scale according to the degree of success.
//
// Parameters:
//   State - String - The State of the action.
//   ToSelectMinimum - Boolean
//
// Returns:
//   Number - from 0 to 5.
//
Function RankOfActionState(State, ToSelectMinimum = False)
	
	If State = "" Then
		Return ?(ToSelectMinimum, 5, 0);
		
	ElsIf State = "Completed" Or State = "OnPause" Then
		Return 3;
		
	ElsIf State = "InTheExecutionQueue" Then
		Return 1;
	Else
		Return 2;
		
	EndIf;
	
EndFunction

// Returns the date format for deadlines, depending on the use of time in deadlines.
//
// Parameters:
//   UseDateAndTimeInDeadlines - Boolean
//
// Returns:
//   String
//
Function DateAndTimeFormat(UseDateAndTimeInDeadlines)
	
	If UseDateAndTimeInDeadlines Then
		Return NStr("ru = 'ДФ=''dd.MM.yy HH:mm''; ДП=''не определен''';
					|vi = 'DF=''MM/dd/yy HH:mm''; DE=''undefined''';
					|en = 'DF=''MM/dd/yy HH:mm''; DE=''undefined'''; fa = 'DF=''MM/dd/yy HH:mm''; DE=''undefined''';
					|it = 'DF=''MM/dd/yy HH:mm''; DE=''undefined''';
					|pl = 'DF=''MM/dd/yy HH:mm''; DE=''undefined''';
					|tr = 'DF=''dd.MM.yy HH:mm''; DE=tanımlanmamış'");
	Else
		Return NStr("ru = 'ДФ=''dd.MM.yy''; ДП=''не определен''';
					|vi = 'DF=''MM/dd/yy''; DE=''undefined''';
					|en = 'DF=''MM/dd/yy''; DE=''undefined'''; fa = 'DF=''MM/dd/yy''; DE=''undefined''';
					|it = 'DF=''MM/dd/yy''; DE=''undefined''';
					|pl = 'DF=''MM/dd/yy''; DE=''undefined''';
					|tr = 'DF=''dd.MM.yy; DE=tanımlanmamış'");
	EndIf;
	
EndFunction

#EndRegion