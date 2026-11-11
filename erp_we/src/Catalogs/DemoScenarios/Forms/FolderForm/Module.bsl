
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then 
		
		DemoScenarios.FillScenarioDescriptionsInFormWithScenariosOfAnotherObject(Parameters.CopyingValue, ScenarioDescriptions);
		Object.Status    = Enums.ProcessDetailsStatuses.InProgress;
		Object.GroupType = Enums.TypesOfProcessDetailsGroups.Ordinary;
		OnCreatReadAtServer(); 
		
	EndIf;
	
	DemoScenarios.ProcessSearchParametersPassedToObjectForm(ThisObject, Parameters);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	DemoScenarios.FillInScenarioDescriptions(CurrentObject, ScenarioDescriptions);
	
	OnCreatReadAtServer();
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If GroupTypeNumber = 0 Then
		
		CurrentObject.GroupType = Enums.TypesOfProcessDetailsGroups.Ordinary;
		
	Else
		
		CurrentObject.GroupType = Enums.TypesOfProcessDetailsGroups.Branching;
		
	EndIf;
	
	DemoScenarios.WriteNewScenarioDescriptionsFromObjectForm(ThisObject, CurrentObject, Cancel);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DemoScenarios_SearchAndReplace" Then
		
		 DemoScenariosClient.HandleSearchAndReplaceEvent(Parameter, ThisObject);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
	
EndProcedure

&AtClient
Procedure GroupTypeViewOnChange(Item)
	
	VisibilityManagement(ThisObject);
	
EndProcedure 

&AtClient
Procedure ScriptTextReadingOnClick(Item, EventData, StandardProcessing)
	
	DemoScenariosClient.WhenYouClickInHTMLDocumentField(ThisObject, Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ScenarioTextOnClick(Item, EventData, StandardProcessing)
	
	DemoScenariosClient.WhenYouClickInHTMLDocumentField(ThisObject,Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ScenarioTextDocumentComplete(Item)
	
	If SearchParametersWhenOpening <> Undefined Then
		
		DemoScenariosClient.OpenSearchForm(ThisObject);
		SearchParametersWhenOpening = Undefined;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TranslateFromViewingLanguage(Command) 
	
	ClearMessages();
	
	DemoScenariosClient.TranslateFromViewingLanguage(
		ThisObject, ScriptTextReading, ScenarioText, ScenarioLanguageReading, ScriptLanguage, "ScenarioText");
	
EndProcedure

&AtClient
Procedure FindAndReplace(Command)
	
	OpenForm("Catalog.DemoScenarios.Form.SearchAndReplace",,ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ProcessAlbum(Command)
	
	If Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	ReportScenarios = New Array;
	ReportScenarios.Add(Object.Ref);
	
	FormParameters = New Structure("ReportScenarios",          ReportScenarios);
	FormParameters = New Structure("DoNotCallPrintCommand", True);
	
	OpenForm("Catalog.DemoScenarios.Form.ProcessAlbum",
	             FormParameters, 
	             ThisObject,
	             True);
	
EndProcedure

#Region EditingScripts

&AtClient
Procedure EndEdit(Command)
	
	AttachedScriptFile = DemoScenariosClientServer.AttachedScriptFile(ThisObject, ScriptLanguage);
	
	If AttachedScriptFile = Undefined Then
		Return;
	EndIf;
	
	HandlerNotifications = New CallbackDescription("AfterEndOfEditingFile", ThisObject);
	
	FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(HandlerNotifications, AttachedScriptFile, UUID);
	
	FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
	
EndProcedure

&AtClient
Procedure Edit(Command)
	
	ClearMessages();
	
	If Modified
		Or Not DemoScenariosClientServer.AttachedFileHasBeenCreatedAccordingToScript(ThisObject, ScriptLanguage) Then
		
		NotificationAfterRecordingQuestion = New CallbackDescription("AfterQuestionRecordBeginningOfEditing", ThisObject);
		QueryText = NStr("vi = 'Trước khi bắt đầu chỉnh sửa nội dung kịch bản, bạn cần viết nó ra. Tiếp tục?';
						|ru = 'Перед началом редактирования текста сценария, его необходимо записать. Продолжить?';
						|en = 'Before editing the scenario text, save it. Continue?'; fa = 'Before editing the scenario text, save it. Continue?';
						|it = 'Перед началом редактирования текста сценария, его необходимо записать. Продолжить?';
						|pl = 'Before editing the scenario text, save it. Continue?';
						|tr = 'Senaryo metnini düzenlemeye başlamadan önce kaydetmeniz gerekmektedir. Devam edilsin mi?'");
		
		ShowQueryBox(NotificationAfterRecordingQuestion, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		
	Else
		
		StartEditingScriptOnClient();
			
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelEdit(Command)
	
	AttachedScriptFile = DemoScenariosClientServer.AttachedScriptFile(ThisObject, ScriptLanguage);
	
	If AttachedScriptFile = Undefined Then
		Return;
	EndIf;
	
	FilesArray = New Array;
	FilesArray.Add(AttachedScriptFile);
	
	FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
	
	UpdateDataOfAttachedScriptFiles();
	
EndProcedure

#EndRegion

#Region ChangingTheDisplayMode

&AtClient
Procedure SetViewOption(Command)
	
	SwitchDisplayOptionOnClient("View");
	
EndProcedure

&AtClient
Procedure SetEditOption(Command)
	
	SwitchDisplayOptionOnClient("Edit");
	
EndProcedure

&AtClient
Procedure SetTranslationOption(Command)
	
	SwitchDisplayOptionOnClient("Translation");
	
EndProcedure 

#EndRegion

#Region StatusChange

&AtClient
Procedure SetStatus_InProgress(Command)
	
	ChangeStatus_(PredefinedValue("Enum.ProcessDetailsStatuses.InProgress"));
	
EndProcedure

&AtClient
Procedure SetStatusThereAreComments(Command)
	
	ChangeStatus_(PredefinedValue("Enum.ProcessDetailsStatuses.RemarksFound"));
	
EndProcedure

&AtClient
Procedure SetStatusForVerification(Command)
	
	ChangeStatus_(PredefinedValue("Enum.ProcessDetailsStatuses.OnValidation"));
	
EndProcedure

&AtClient
Procedure SetStatus_Checked(Command)
	
	ChangeStatus_(PredefinedValue("Enum.ProcessDetailsStatuses.Checked"));
	
EndProcedure

#EndRegion

#Region SwitchingLanguages

&AtClient
Procedure Attachable_ChangeEditingLanguage(Command)

	CommandName = Command.Name;
	LanguageCode     = DemoScenariosClientServer.LanguageCodeFromCommandName(CommandName, "SwitchToEditingLanguage_");
	SwitchScriptLanguage(ThisObject, LanguageCode);
	
EndProcedure

&AtClient
Procedure Attachable_ChangeViewingLanguage(Command)
	
	CommandName = Command.Name;
	LanguageCode = DemoScenariosClientServer.LanguageCodeFromCommandName(CommandName, "SwitchToViewingLanguage_");
	ScenarioLanguageReading = LanguageCode;
	WhenChangingViewingLanguageOnServer( LanguageCode);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region InitializationOfVisibilityManagement

&AtServer
Procedure OnCreatReadAtServer()
	
	If Object.GroupType = Enums.TypesOfProcessDetailsGroups.Branching Then
		
		GroupTypeNumber = 1;
		
	Else
		
		GroupTypeNumber = 0;
		
	EndIf;
	
	CurrentUser = Users.CurrentUser();
	ColorIsCapturedByCurUser = StyleColors.FileLockedByCurrentUser;
	ColorIsCapturedByAnotherUser  = StyleColors.FileLockedByAnotherUser;
	ThereIsTheRightToEdit          = AccessRight("Update", Metadata.Catalogs.DemoScenarios);
	
	DemoScenarios.SetConfigurationLanguagesInForm(ThisObject);
	DemoScenarios.CreateFormElementsConfigurationLanguages(ThisObject);
	DemoScenarios.SetLanguageSettingInForm(ThisObject, "ScenarioLanguageReading", "ScriptLanguage");
	
	SetDataOfDisplayedScripts(ThisObject);
	
	DemoScenariosClientServer.ReflectCurStatusOnForm(ThisObject);
	
	DemoScenarios.LoadSettingForFormDisplayOption(
		ThisObject,
		DemoScenarios.AvailableDisplayOptions(True),
		Metadata.Catalogs.DemoScenarios);
		
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject, "ScenarioLanguageReading", "ScriptLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(ScenarioLanguageReading, ScriptLanguage, Items.Translate);
	
	ScenarioText = GetDescriptionInLanguage(ThisObject, ScriptLanguage);
	ScriptTextReading = GetDescriptionInLanguage(ThisObject, ScenarioLanguageReading);
	AddListOfGroupStepsToText();
	
	VisibilityManagement(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	Items = Form.Items;
	
	ThisIsEditingMode = (Form.FormDisplayOption = "Edit");
	ThisIsTranslationMode        = (Form.FormDisplayOption = "Translation");
	ThisIsViewMode       = (Form.FormDisplayOption = "View");
	
	Items.PageHeaderDisplayOptions.CurrentPage = 
		?(ThisIsEditingMode, Items.PageDisplayOptionEdit, Items.PageDisplayOptionView);
	
	Items.GroupCommentParent.Visible  = ThisIsEditingMode Or ThisIsTranslationMode; 
	Items.EditGroup.Visible       = ThisIsEditingMode Or ThisIsTranslationMode;
	Items.StatusSubmenu.Visible              = ThisIsEditingMode Or ThisIsTranslationMode;
	
	Items.Translate.Visible = ThisIsTranslationMode
	                               And Form.CurScriptIsAvailableForEditing
	                               And Not Form.CurrentScriptIsBeingEditedByCurrentUser
	                               And Not Form.Object.Ref.IsEmpty(); 
	
	Items.SubmenuViewingLanguage.Visible = ThisIsViewMode Or ThisIsTranslationMode;
	Items.ReadingGroup.Visible         = ThisIsViewMode Or ThisIsTranslationMode;
	
	Items.EditScriptText.Visible           = Form.CurScriptIsAvailableForEditing;
	Items.ScriptTextFinishEditing.Visible = Form.CurrentScriptIsBeingEditedByCurrentUser;
	Items.ScriptTextUndoEditing.Visible  = Form.CurrentScriptIsBeingEditedByCurrentUser;
	
	Items.FindAndReplaceScriptText.Visible          = Form.CurScriptIsAvailableForEditing
	                                                          And Not Form.CurrentScriptIsBeingEditedByCurrentUser;
	
	If Form.CurScriptIsAvailableForEditing Then
		Items.CommandGroupWithLanguage.Group                                = ChildFormItemsGroup.Vertical;
		Items.DecorationStateOfEditing.HorizontalAlign        = ItemHorizontalLocation.Left;
		Items.DecorationStateOfEditing.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
	Else
		Items.CommandGroupWithLanguage.Group = ChildFormItemsGroup.AlwaysHorizontal;
		Items.DecorationStateOfEditing.HorizontalAlign        = ItemHorizontalLocation.Right;
		Items.DecorationStateOfEditing.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	EndIf;
	
	Items.DecorationStateOfEditing.Visible = Not IsBlankString(Items.DecorationStateOfEditing.Title);
	
	DemoScenariosClientServer.MarkCommandsForSwitchingFormDisplayOption(Form);
	
	Items.FormProcessAlbum.Visible = Not Form.Object.Ref.IsEmpty();
	
EndProcedure

#EndRegion

#Region StatusChange

&AtClient
Procedure ChangeStatus_(NewStatus)

	If NewStatus = Object.Status
		Or Not ValueIsFilled(NewStatus) Then
		Return;
	EndIf; 
	
	Object.Status = NewStatus;
	
	DemoScenariosClientServer.ReflectCurStatusOnForm(ThisObject);
	
EndProcedure

#EndRegion

#Region SwitchingDisplayOptions

&AtClient
Procedure SwitchDisplayOptionOnClient(NewOption)
	
	SwitchingParameters = DemoScenariosClientServer.NewDisplayOptionSwitchingOptions();
	SwitchingParameters.Form                          = ThisObject;
	SwitchingParameters.NewOption                   = NewOption;
	SwitchingParameters.AttributeNameLanguageReading         = "ScenarioLanguageReading";
	SwitchingParameters.AttributeNameLanguageEditing = "ScriptLanguage";
	SwitchingParameters.ConfigurationLanguages              = ConfigurationLanguages;
	
	DemoScenariosClientServer.SwitchDisplayOption(SwitchingParameters); 
	
	If SwitchingParameters.LanguageSwitchingCompleted Then
		
		If SwitchingParameters.AttributeNameLanguageSwitched = "ScenarioLanguageReading" Then
			WhenChangingViewingLanguageOnServer( SwitchingParameters.SwitchedToLanguage);
		ElsIf SwitchingParameters.AttributeNameLanguageSwitched = "ScriptLanguage" Then
			SwitchScriptLanguage(ThisObject, SwitchingParameters.SwitchedToLanguage);
		EndIf;
		
	EndIf;
	
	VisibilityManagement(ThisObject);
	
EndProcedure

#EndRegion

#Region InstallingTheseScripts

&AtClientAtServerNoContext
Procedure SetDataOfDisplayedScripts(Form)

	SetScriptDataInLanguage(Form, Form.ScriptLanguage);
	Form.ScriptTextReading = GetDescriptionInLanguage(Form, Form.ScenarioLanguageReading);

EndProcedure 

&AtClientAtServerNoContext
Procedure SetScriptDataInLanguage(Form, LanguageCode)

	ScenarioData = DemoScenariosClientServer.ScriptDataInLanguage(Form, LanguageCode, "ScenarioDescriptions");
	
	Form.ScenarioText = ScenarioData.HTMLText;
	Form.CurScriptIsAvailableForEditing            = ScenarioData.CurScriptIsAvailableForEditing;
	Form.CurrentScriptIsBeingEditedByCurrentUser    = ScenarioData.CurrentScriptIsBeingEditedByCurrentUser;
	Form.Items.DecorationStateOfEditing.Title = ScenarioData.PresentationOfEditingState;

EndProcedure

&AtServer
Procedure WhenChangingViewingLanguageOnServer(LanguageCode)
	
	ScriptTextReading = GetDescriptionInLanguage(ThisObject, ScenarioLanguageReading);
	AddListOfGroupStepsToText();
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject, "ScenarioLanguageReading", "ScriptLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(ScenarioLanguageReading, ScriptLanguage, Items.Translate); 
	VisibilityManagement(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Function GetDescriptionInLanguage(Form, LanguageCode)
	
	Return DemoScenariosClientServer.HTMLTextByLanguageCode(Form, LanguageCode, "ScenarioDescriptions", "HTMLText");
	
EndFunction 

&AtClientAtServerNoContext
Procedure SwitchScriptLanguage(Form, LanguageCode)
	
	Form.ScriptLanguage = LanguageCode;
	SetScriptDataInLanguage(Form, Form.ScriptLanguage);
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(Form, "ScenarioLanguageReading", "ScriptLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(Form.ScenarioLanguageReading, Form.ScriptLanguage, Form.Items.Translate);
	
	VisibilityManagement(Form);
	
EndProcedure

&AtServer
Procedure AddListOfGroupStepsToText();
	
	If Object.Ref.IsEmpty() Then
		TextSteps = ScriptTextReading;
	EndIf;
	
	CurElementNumberOfOccurrences = StrOccurrenceCount(Object.FullCode, "/");
	GroupFont              = StyleFonts.FontGroupGroupSteps;
	FontTitle           = StyleFonts.FontTitleGroupSteps;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DemoScenarios.FullCode     AS FullCode,
	|	DemoScenarios.Description  AS Description,
	|	DemoScenarios.Ref        AS Ref,
	|	DemoScenarios.Presentation AS Presentation,
	|	DemoScenarios.GroupType     AS GroupType,
	|	DemoScenarios.IsFolder     AS IsFolder,
	|	DemoScenarios.Parent      AS Parent
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Parent IN HIERARCHY(&Parent)
	|	AND NOT DemoScenarios.DeletionMark
	|
	|ORDER BY
	|	FullCode HIERARCHY
	|	"; 
	
	NameOfFieldToChange = DemoScenarios.NameOfMultilingualAttribute("Description");
	NationalLanguageSupportServer.ChangeRequestFieldUnderCurrentLanguage(Query.Text, "Description");
	
	Query.SetParameter("Parent", Object.Ref);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	TextListOfGroupSteps = New FormattedDocument;
	TextListOfGroupSteps.SetHTML(ScriptTextReading, New Structure);
	
	TextListOfGroupSteps.Add(Chars.LF);
	TextListOfGroupSteps.Add(Chars.LF);
	
	TextStepsInGroup = StrTemplate(NStr("vi = 'Các bước trong nhóm: %1';
										|ru = 'Шаги в группе: %1';
										|en = 'Steps in the group: %1'; fa = 'Steps in the group: %1';
										|it = 'Шаги в группе: %1';
										|pl = 'Steps in the group: %1';
										|tr = 'Gruptaki adımlar: %1'"), Selection.Count());
	
	Item = TextListOfGroupSteps.Add(TextStepsInGroup);
	Item.Font = FontTitle; 
	
	TextListOfGroupSteps.Add(Chars.LF);
	TextListOfGroupSteps.Add(Chars.LF);
	
	While Selection.Next() Do
		
		URL = GetURL(Selection.Ref);
		StepPresentation = StrTemplate("%1 - %2 %3", Selection.FullCode, Selection[NameOfFieldToChange], Chars.LF);
		NumberOfOccurrences = StrOccurrenceCount(Selection.Ref.FullCode(), "/");
		Indent = "";
		
		For Indus = CurElementNumberOfOccurrences + 2 To NumberOfOccurrences Do
			Indent = "    "+Indent;
		EndDo;
		
		StepPresentation = Indent + StepPresentation;
		Item = TextListOfGroupSteps.Add(StepPresentation);
		Item.URL = URL;    
		
		If Selection.IsFolder Then
			Item.Font = GroupFont;
		Else
			Item.Font = StyleFonts.NormalTextFont;
		EndIf;
		
	EndDo;
	
	TextSteps = "";
	Attachments = New Structure;
	
	TextListOfGroupSteps.GetHTML(TextSteps, Attachments);
	
EndProcedure

#EndRegion

#Region EndEventHandlersForAttachedFiles

&AtClient
Procedure AfterYouStartEditingFile(Result, AdditionalParameters) Export

	If Result = Undefined Then
		UpdateDataOfAttachedScriptFiles();
	EndIf;

EndProcedure

&AtClient
Procedure AfterEndOfEditingFile(Result, AdditionalParameters) Export

	If Result = True Then
		UpdateDataOfAttachedScriptFiles();
	EndIf;
	
EndProcedure 

&AtServer
Procedure UpdateDataOfAttachedScriptFiles()

	DemoScenarios.FillInScenarioDescriptions(Object, ScenarioDescriptions);
	SetDataOfDisplayedScripts(ThisObject);
	AddListOfGroupStepsToText();
	VisibilityManagement(ThisObject);

EndProcedure

#EndRegion 

#Region EditingScript

&AtClient
Procedure AfterQuestionRecordBeginningOfEditing(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		RecordingResult = Write();
		If RecordingResult Then
			StartEditingScriptOnClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartEditingScriptOnClient()
	
	AttachedScriptFile = DemoScenariosClientServer.AttachedScriptFile(ThisObject, ScriptLanguage);
	
	HandlerNotifications = New CallbackDescription("AfterYouStartEditingFile", ThisObject);
	
	FilesOperationsInternalClient.EditWithNotification(HandlerNotifications, AttachedScriptFile, UUID);
	
EndProcedure

#EndRegion 

&AtClient
Procedure AfterClosingSearchAndReplaceForm(Result, AdditionalParameters) Export

	DemoScenariosClient.AfterClosingSearchAndReplaceForm(ThisObject);

EndProcedure

&AtClient
Procedure AfterAnsweringQuestionAfterTranslation(Result, AdditionalParameters) Export
	
	DemoScenariosClient.AfterAcceptingTranslationResults(ThisObject, Result, AdditionalParameters);
	
EndProcedure

#EndRegion
