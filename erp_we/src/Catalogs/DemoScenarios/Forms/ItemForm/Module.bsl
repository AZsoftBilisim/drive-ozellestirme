
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing) 
	
	If Object.Ref.IsEmpty() Then
		
		DemoScenarios.FillScenarioDescriptionsInFormWithScenariosOfAnotherObject(Parameters.CopyingValue, ScenarioDescriptions);
		Object.Status = Enums.ProcessDetailsStatuses.InProgress;
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
Procedure ScenarioTextOnClick(Item, EventData, StandardProcessing)
	
	DemoScenariosClient.WhenYouClickInHTMLDocumentField(ThisObject, Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ScriptTextReadingOnClick(Item, EventData, StandardProcessing)
	
	DemoScenariosClient.WhenYouClickInHTMLDocumentField(ThisObject, Item, EventData, StandardProcessing);
	
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
	
	DemoScenariosClient.OpenSearchForm(ThisObject);
	
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
	
	SwitchDisplayOption(ThisObject, "View");
	ConfigureDisplayOfInformationViewingMode();
	
EndProcedure

&AtClient
Procedure SetEditOption(Command)
	
	SwitchDisplayOption(ThisObject, "Edit");
	
EndProcedure 

&AtClient
Procedure SetTranslationOption(Command)
	
	SwitchDisplayOption(ThisObject, "Translation");
	ConfigureDisplayOfInformationViewingMode();
	
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

#Region DemoScenariosReport

&AtClient
Procedure DemoScenariosViewObjects(Command)
	
	CurrentData = Items.NameConfigurationObjects.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.Value) Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng hiện tại';
								|ru = 'Команда не может быть выполнена для текущего объекта';
								|en = 'Cannot run the command for the current object'; fa = 'Cannot run the command for the current object';
								|it = 'Команда не может быть выполнена для текущего объекта';
								|pl = 'Cannot run the command for the current object';
								|tr = 'Komut mevcut nesne için yürütülemez'"));
		Return
	EndIf;
	
	OpenDemoScenariosReport(CurrentData.Value);
	
EndProcedure

&AtClient
Procedure DemoScenariosViewProfiles(Command)
	
	CurrentData = Items.Assignees.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.Value) Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng hiện tại';
								|ru = 'Команда не может быть выполнена для текущего объекта';
								|en = 'Cannot run the command for the current object'; fa = 'Cannot run the command for the current object';
								|it = 'Команда не может быть выполнена для текущего объекта';
								|pl = 'Cannot run the command for the current object';
								|tr = 'Komut mevcut nesne için yürütülemez'"));
		Return
	EndIf;
	
	OpenDemoScenariosReport(CurrentData.Value);

EndProcedure

&AtClient
Procedure DemoScenariosEditingObjects(Command)
	
	CurrentData = Items.ConfigurationObjects.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.ConfigurationObject) Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng hiện tại';
								|ru = 'Команда не может быть выполнена для текущего объекта';
								|en = 'Cannot run the command for the current object'; fa = 'Cannot run the command for the current object';
								|it = 'Команда не может быть выполнена для текущего объекта';
								|pl = 'Cannot run the command for the current object';
								|tr = 'Komut mevcut nesne için yürütülemez'"));
		Return
	EndIf;
	
	OpenDemoScenariosReport(CurrentData.ConfigurationObject);
	
EndProcedure

&AtClient
Procedure DemoScenariosEditingProfiles(Command)
	
	CurrentData = Items.AccessGroupProfiles.CurrentData;
	If CurrentData = Undefined
		Or Not ValueIsFilled(CurrentData.Profile) Then
		
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng hiện tại';
								|ru = 'Команда не может быть выполнена для текущего объекта';
								|en = 'Cannot run the command for the current object'; fa = 'Cannot run the command for the current object';
								|it = 'Команда не может быть выполнена для текущего объекта';
								|pl = 'Cannot run the command for the current object';
								|tr = 'Komut mevcut nesne için yürütülemez'")); 
		Return;
		
	EndIf;
	
	OpenDemoScenariosReport(CurrentData.Profile);
	
EndProcedure

&AtClient
Procedure OpenDemoScenariosReport(OpeningParameter)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CommandParameter", OpeningParameter);
	
	OpenForm("Report.ObjectDemoScenarios.ObjectForm", OpeningParameters, ThisObject,
	             ,,,, FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region ChangeLanguage

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
	
	SwitchScriptLanguageToRead(ThisObject, LanguageCode);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer() 
	
	ThisIsNotBasicVersion = GetFunctionalOption("NotBaseVersion");
	Items.AccessGroupsProfilesGroup.Visible = ThisIsNotBasicVersion;
	
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
	
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(ThisObject, "ScenarioLanguageReading", "ScriptLanguage" );
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(ScenarioLanguageReading, ScriptLanguage, Items.Translate);
	
	ConfigureDisplayOfInformationViewingMode();
	VisibilityManagement(ThisObject);
	
EndProcedure

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

&AtClientAtServerNoContext
Function GetDescriptionInLanguage(Form, LanguageCode)
	
	Return DemoScenariosClientServer.HTMLTextByLanguageCode(Form, LanguageCode, "ScenarioDescriptions", "HTMLText");
	
EndFunction

&AtClientAtServerNoContext
Procedure SwitchScriptLanguageToRead(Form, LanguageCode)

	Form.ScenarioLanguageReading  = LanguageCode;
	Form.ScriptTextReading = GetDescriptionInLanguage(Form, Form.ScenarioLanguageReading);
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(Form, "ScenarioLanguageReading", "ScriptLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(Form.ScenarioLanguageReading, Form.ScriptLanguage, Form.Items.Translate);
	
	VisibilityManagement(Form);

EndProcedure 

&AtClientAtServerNoContext
Procedure SwitchScriptLanguage(Form, LanguageCode)
	
	Form.ScriptLanguage = LanguageCode;
	SetScriptDataInLanguage(Form, Form.ScriptLanguage);
	DemoScenariosClientServer.ReflectCurLanguagesOnForm(Form, "ScenarioLanguageReading", "ScriptLanguage");
	DemoScenariosClientServer.GenerateTitleOfTranslationCommands(Form.ScenarioLanguageReading, Form.ScriptLanguage, Form.Items.Translate);
	
	VisibilityManagement(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	Items = Form.Items;
	
	ThisIsEditingMode = (Form.FormDisplayOption = "Edit");
	ThisIsTranslationMode        = (Form.FormDisplayOption = "Translation");
	ThisIsViewMode       = (Form.FormDisplayOption = "View");
	
	Items.PageHeaderDisplayOptions.CurrentPage = 
		?(ThisIsEditingMode, Items.PageDisplayOptionEdit, Items.PageDisplayOptionView);
	
	Items.SubmenuViewEditMode.Visible = Form.ThereIsTheRightToEdit;
	
	Items.AdvancedGroup.Visible       = ThisIsEditingMode; 
	Items.Comment.Visible               = ThisIsEditingMode;
	Items.RelatedObjectsGroup.Visible    = ThisIsEditingMode;
	Items.AccessGroupsProfilesGroup.Visible = ThisIsEditingMode; 
	Items.EditGroup.Visible      = ThisIsEditingMode Or ThisIsTranslationMode;
	Items.StatusSubmenu.Visible             = ThisIsEditingMode Or ThisIsTranslationMode;
	
	Items.Translate.Visible = ThisIsTranslationMode
	                               And Form.CurScriptIsAvailableForEditing
	                               And Not Form.CurrentScriptIsBeingEditedByCurrentUser
	                               And Not Form.Object.Ref.IsEmpty(); 
	
	Items.SubmenuViewingLanguage.Visible = ThisIsViewMode Or ThisIsTranslationMode;
	Items.ReadingGroup.Visible         = ThisIsViewMode Or ThisIsTranslationMode;
	
	Items.EditScriptText.Visible           = Form.CurScriptIsAvailableForEditing And Not Form.Object.DeletionMark;
	Items.ScriptTextFinishEditing.Visible = Form.CurrentScriptIsBeingEditedByCurrentUser;
	Items.ScriptTextUndoEditing.Visible  = Form.CurrentScriptIsBeingEditedByCurrentUser;
	
	Items.FindAndReplaceScriptText.Visible          = Form.CurScriptIsAvailableForEditing
	                                                          And Not Form.CurrentScriptIsBeingEditedByCurrentUser
	                                                          And Not Form.Object.Ref.IsEmpty();
	
	If Form.CurScriptIsAvailableForEditing
		And Form.ThereIsTheRightToEdit Then
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
	
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchDisplayOption(Form, NewOption)
	
	SwitchingParameters = DemoScenariosClientServer.NewDisplayOptionSwitchingOptions();
	SwitchingParameters.Form                          = Form;
	SwitchingParameters.NewOption                   = NewOption;
	SwitchingParameters.AttributeNameLanguageReading         = "ScenarioLanguageReading";
	SwitchingParameters.AttributeNameLanguageEditing = "ScriptLanguage";
	SwitchingParameters.ConfigurationLanguages              = Form.ConfigurationLanguages;
	
	DemoScenariosClientServer.SwitchDisplayOption(SwitchingParameters); 
	
	If SwitchingParameters.LanguageSwitchingCompleted Then
		
		If SwitchingParameters.AttributeNameLanguageSwitched = "ScenarioLanguageReading" Then
			SwitchScriptLanguageToRead(Form, SwitchingParameters.SwitchedToLanguage);
		ElsIf SwitchingParameters.AttributeNameLanguageSwitched = "ScriptLanguage" Then
			SwitchScriptLanguage(Form, SwitchingParameters.SwitchedToLanguage);
		EndIf;
		
	EndIf;
	
	VisibilityManagement(Form);
	
EndProcedure

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

#Region PresentationsForViewingMode

&AtServer
Function PresentationOfMetadataObject()
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Presentation",          "");
	ReturnStructure.Insert("Count",              0);
	ReturnStructure.Insert("MetadataViews", New ValueList);

	SetPrivilegedMode(True);
	
	If Object.ConfigurationObjects.Count() = 0 Then
		ReturnStructure.Presentation = NStr("vi = 'Chưa chỉ ra việc sử dụng trong các đối tượng cấu hình';
											|ru = 'Использование в объетках конфигурации не указано';
											|en = 'Usage in configuration objects is not specified'; fa = 'Usage in configuration objects is not specified';
											|it = 'Использование в объетках конфигурации не указано';
											|pl = 'Usage in configuration objects is not specified';
											|tr = 'Konfigürasyon nesnelerinde kullanım belirtilmedi'");
		Return ReturnStructure;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MetadataObjectIDs.Ref       AS Ref,
	|	MetadataObjectIDs.Description AS Description
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Ref IN(&MetadataObjects)";
	
	Query.SetParameter("MetadataObjects", Object.ConfigurationObjects.Unload().UnloadColumn("ConfigurationObject"));
	
	Selection = Query.Execute().Select(); 
	While Selection.Next() Do
		 ReturnStructure.MetadataViews.Add(Selection.Ref, Selection.Description);
	EndDo;
	
	ReturnStructure.Count = ReturnStructure.MetadataViews.Count();
	ReturnStructure.Presentation = DemoScenarios.LinePresentationWithMore(NStr("vi = 'Đối tượng cấu hình:';
																				|ru = 'Объекты конфигурации:';
																				|en = 'Configuration objects:'; fa = 'Configuration objects:';
																				|it = 'Объекты конфигурации:';
																				|pl = 'Configuration objects:';
																				|tr = 'Konfigürasyon nesneleri:'"),
	                                                                                   ReturnStructure.MetadataViews, 80);
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure ConfigureDisplayOfInformationViewingMode()

	PresentationOfMetadataObject = PresentationOfMetadataObject();
	
	NameConfigurationObjects = PresentationOfMetadataObject.MetadataViews;
	Items.GroupPresentationConfigurationObjects.Title = PresentationOfMetadataObject.Presentation;
	
	If ThisIsNotBasicVersion Then
		
		PresentationOfPerformers = PresentationOfPerformers(); 
		
		Assignees = PresentationOfPerformers.MetadataViews;
		Items.GroupPresentationOfPerformers.Title = PresentationOfPerformers.Presentation;
		Items.GroupPresentationOfPerformers.Visible = True;
		
	Else
		
		Items.GroupPresentationOfPerformers.Visible = False;
		
	EndIf;
	
EndProcedure 

&AtServer
Function PresentationOfPerformers()
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Presentation",           "");
	ReturnStructure.Insert("Count",              0);
	ReturnStructure.Insert("MetadataViews", New ValueList);

	SetPrivilegedMode(True);
	
	If Object.AccessGroupProfiles.Count() = 0 Then
		ReturnStructure.Presentation = NStr("vi = 'Chưa chỉ ra người thực hiện';
											|ru = 'Исполнители не указаны';
											|en = 'Assignees are not specified'; fa = 'Assignees are not specified';
											|it = 'Исполнители не указаны';
											|pl = 'Assignees are not specified';
											|tr = 'Atananlar belirtilmedi'");
		Return ReturnStructure;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	AccessGroupProfiles.Ref       AS Ref,
	|	AccessGroupProfiles.Description AS Description
	|FROM
	|	Catalog.AccessGroupProfiles AS AccessGroupProfiles
	|WHERE
	|	AccessGroupProfiles.Ref IN(&Assignees)";
	
	Query.SetParameter("Assignees", Object.AccessGroupProfiles.Unload().UnloadColumn("Profile"));
	
	Selection = Query.Execute().Select(); 
	While Selection.Next() Do
		 ReturnStructure.MetadataViews.Add(Selection.Ref, Selection.Description);
	EndDo;
	
	ReturnStructure.Count = ReturnStructure.MetadataViews.Count();
	ReturnStructure.Presentation = DemoScenarios.LinePresentationWithMore(NStr("vi = 'Người thực hiện:';
																				|ru = 'Исполнители:';
																				|en = 'Assignees:'; fa = 'Assignees:';
																				|it = 'Исполнители:';
																				|pl = 'Assignees:';
																				|tr = 'Atananlar:'"), ReturnStructure.MetadataViews, 80);
	
	Return ReturnStructure;
	
EndFunction

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
	VisibilityManagement(ThisObject);

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
