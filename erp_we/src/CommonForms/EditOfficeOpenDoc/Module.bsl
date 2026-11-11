///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var ReClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
			
	If Common.IsMobileClient() Then
		Raise NStr("vi = 'Không thể soạn tài liệu văn phòng trên mobile client.
		|Hãy sử dụng thin client hoặc web-client.';
		|ru = 'Редактирование офисного документа недоступно в мобильном клиенте.
		|Используйте тонкий клиент или веб-клиент.';
		|en = 'Cannot edit an office document in the mobile client.
		|Use thin client or web client.'; fa = 'Cannot edit an office document in the mobile client.
		|Use thin client or web client.';
		|it = 'Редактирование офисного документа недоступно в мобильном клиенте.
		|Используйте тонкий клиент или веб-клиент.';
		|pl = 'Cannot edit an office document in the mobile client.
		|Use thin client or web client.';
		|tr = 'Mobil istemcide ofis belgesi düzenlenemez.
		|İnce istemciyi ya da web-istemcisini kullanın.'");
	EndIf;
	
	IsLinuxClient = Common.IsLinuxClient();
	
	If IsLinuxClient Then
		Commands.PutToClipboard.Shortcut = New Shortcut(Key.None, False, False, False);
		Items.PutToClipboard.Visible = False;
	EndIf;
	
	DisplayInstruction();
	Items.InstructionDocumentField.Visible = True;
	Items.DisplayInstruction.Check = Items.InstructionDocumentField.Visible;
	
	If Parameters.WindowOpeningMode <> Undefined Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	
	LanguageCode = Common.DefaultLanguageCode();
	IdentifierOfTemplate = Parameters.TemplateMetadataObjectName;
	RefTemplate = Parameters.Ref;
	
	If ValueIsFilled(RefTemplate) Then
		KeyOfEditObject  = RefTemplate;
		LockDataForEdit(KeyOfEditObject,,UUID);
	ElsIf ValueIsFilled(IdentifierOfTemplate) Then
		KeyOfEditObject = InformationRegisters.UserPrintTemplates.GetTemplateRecordKey(IdentifierOfTemplate);
		If KeyOfEditObject <> Undefined Then
			LockDataForEdit(KeyOfEditObject,,UUID);
		EndIf;
	EndIf;

	IsPrintForm = Parameters.IsPrintForm;
	EditingDenied = Not Parameters.Edit;
	IsTemplate = Not IsBlankString(IdentifierOfTemplate) Or IsPrintForm;
	
	If IsTemplate Then
		If Common.SubsystemExists("StandardSubsystems.Print") Then
			ModulePrintManager = Common.CommonModule("PrintManagement");
			TemplateDataSource = ModulePrintManager.TemplateDataSource(IdentifierOfTemplate);
			For Each DataSource In TemplateDataSource Do
				DataSources.Add(DataSource);
			EndDo;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Parameters.DataSource) Then
		If Not ValueIsFilled(DataSources) Then
			DataSources.Add(Parameters.DataSource);
		EndIf;
	EndIf;
	Items.TextAssignment.Title = PresentationOfDataSource(DataSources);
	
	TemplateType = Parameters.TemplateType;
	TemplatePresentation = Parameters.DocumentName;
	TemplateFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(TemplatePresentation) + "." + Lower(TemplateType);
	
	DocumentName = Parameters.DocumentName;
	Items.Rename.Visible = ValueIsFilled(Parameters.Ref) 
		Or IsBlankString(IdentifierOfTemplate) And IsBlankString(Parameters.PathToFile);
	
	ImportOfficeDocFromMetadata(Parameters.LanguageCode);
	If Parameters.Copy Then
		IDOfTemplateBeingCopied = IdentifierOfTemplate;
		IdentifierOfTemplate = "";
	EndIf;
	
	PreparedTemplate = GetFromTempStorage(TemplateFileAddress);
		
	AvailableTranslationLayout = False;
	If IsTemplate Then
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
			PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
			AvailableTranslationLayout = PrintManagementModuleNationalLanguageSupport.AvailableTranslationLayout(IdentifierOfTemplate);
			If IsPrintForm Or AvailableTranslationLayout Then
				PrintManagementModuleNationalLanguageSupport.FillInTheLanguageSubmenu(ThisObject, Parameters.LanguageCode);
				AutomaticTranslationAvailable = PrintManagementModuleNationalLanguageSupport.AutomaticTranslationAvailable(CurrentLanguage);
			EndIf;
		EndIf;
	EndIf;
	
	Items.Language.Enabled = (IsPrintForm Or AvailableTranslationLayout) And ValueIsFilled(IdentifierOfTemplate);
	
	Items.Translate.Visible = AutomaticTranslationAvailable;
	Items.ButtonShowOriginal.Visible = Items.Translate.Visible;
	Items.ButtonShowOriginal.Enabled = CurrentLanguage <> Common.DefaultLanguageCode();
	
	Items.LanguageAllActions.Enabled = Items.Language.Enabled;
	Items.TranslateAllActions.Visible = Items.Translate.Visible;
	Items.ButtonShowOriginalAllActions.Visible = Items.ButtonShowOriginal.Visible;
	Items.ButtonShowOriginalAllActions.Enabled = Items.ButtonShowOriginal.Enabled;
	
	DataSource = Parameters.DataSource;
	If Not ValueIsFilled(Parameters.DataSource) Then
		DataSource = DataSources[0].Value;
	EndIf;

	MetadataObject = Common.MetadataObjectByID(DataSource);
	PickupSample(MetadataObject);

	AddingOptions = FormulasConstructor.ParametersForAddingAListOfFields();
	AddingOptions.ListName = NameOfTheFieldList();
	AddingOptions.LocationOfTheList = Items.AvailableFieldsGroup;
	AddingOptions.FieldsCollections = FieldsCollections(DataSources.UnloadValues(), EditParameters());
	AddingOptions.HintForEnteringTheSearchString = PromptInputStringSearchFieldList();
	AddingOptions.WhenDefiningAvailableFieldSources = "PrintManagement";
	AddingOptions.ListHandlers.Insert("Selection", "Attachable_ListOfFieldsSelection");
	AddingOptions.ListHandlers.Insert("BeforeRowChange", "Attachable_AvailableFieldsBeforeStartOfChange");
	AddingOptions.ListHandlers.Insert("OnEditEnd", "Attachable_AvailableFieldsAtEndOfEditing");
	AddingOptions.UseBackgroundSearch = True;
	
	If Not IsLinuxClient Then
		AddingOptions.ContextMenu.Insert("Copy", "PutToClipboard");
	EndIf;
	
	FormulasConstructor.AddAListOfFieldsToTheForm(ThisObject, AddingOptions);
	
	AddingOptions = FormulasConstructor.ParametersForAddingAListOfFields();
	AddingOptions.ListName = NameOfTheListOfOperators();
	AddingOptions.LocationOfTheList = Items.OperatorsAndFunctionsGroup;
	AddingOptions.FieldsCollections.Add(ListOfOperators());
	AddingOptions.HintForEnteringTheSearchString = NStr("vi = 'Tìm kiếm toán tử hoặc hàm...';
														|ru = 'Найти оператор или функцию...';
														|en = 'Find operator or function…'; fa = 'Find operator or function…';
														|it = 'Ricerca operatore o funzione...';
														|pl = 'Znajdź operator lub funkcję...';
														|tr = 'Operatör veya fonksiyon bul...'");
	AddingOptions.ViewBrackets = False;
	AddingOptions.ListHandlers.Insert("Selection", "Attachable_ListOfFieldsSelection");
	AddingOptions.ListHandlers.Insert("OnActivateRow", "Attachable_FieldListRowActivation");
	AddingOptions.ListHandlers.Insert("DragStart", "Attachable_OperatorsDragStart");
			
	If Not IsLinuxClient Then
		AddingOptions.ContextMenu.Insert("Copy", "PutToClipboard");
	EndIf;
	
	FormulasConstructor.AddAListOfFieldsToTheForm(ThisObject, AddingOptions);
	PrepareTemplateForOpening(PreparedTemplate);
	ExpandFieldList();
	
	PutToTempStorage(PreparedTemplate, TemplateFileAddress);
	EditableTemplateHash = GetTemplateHash(TemplateFileAddress);
	TemplateModificationCheckTime =	CurrentUniversalDateInMilliseconds();
	Items.GroupTemplateAssignment.Enabled = Parameters.IsValAvailable;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

#If WebClient Then
		HideDragZone = False;
#Else
		HideDragZone = True;
#EndIf

	If IsLinuxClient Then
		HideDragZone = False;
	EndIf;

	If Not HideDragZone Then
		Items.GroupHTMLPages.CurrentPage = Items.PageWebClient;
	Else
		Items.GroupHTMLPages.CurrentPage = Items.PageThinClient;
		MoveGroupOfOperatorsAndFunctions();
	EndIf;

	PrepareInstruction();
	MinimizeInterface();
	SetInitialFormSettings();
	
EndProcedure


&AtClient
Procedure OnClose(Exit)
	If Not Exit Then
		ReturnInterface();
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "SpreadsheetDocumentsToEditNameRequest" And Source <> ThisObject Then
		DocumentNames = Parameter; // Array -
		DocumentNames.Add(DocumentName);
	ElsIf EventName = "OwnerFormClosing" And Source = FormOwner Then
		If IsOpen() Then
			Close();
			Parameter.Cancel = True;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Exit Then
		If Modified And Not CancelSavingChanges Then
			WarningText = NStr("vi = 'Khuôn in của mẫu in được soạn trong ứng dụng khác. 
				|Hãy nhấn Ghi lại để không mất các thay đổi.';
				|ru = 'Макет печатной формы отредактирован в другом приложении. 
				|Нажмите Записать, чтобы не потерять изменения.';
				|en = 'The print form''s template has been edited in another application.
				|Click ""Save"" to save the changes.'; fa = 'The print form''s template has been edited in another application.
				|Click ""Save"" to save the changes.';
				|it = 'Макет печатной формы отредактирован в другом приложении. 
				|Нажмите Записать, чтобы не потерять изменения.';
				|pl = 'The print form''s template has been edited in another application.
				|Click ""Save"" to save the changes.';
				|tr = 'Basılı formun şablonu başka bir uygulamada düzenlendi. 
				|Değişikliklerinizi kaybetmemek için Kaydet''i tıklayın'");
			Cancel = True;
		EndIf;
		Return;
	EndIf;

	If Not CancelSavingChanges Then
		
		If Not WritingCompleted Then
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("Cancel", Cancel);
			Notification = New CallbackDescription("BeforeCloseEnd", ThisObject, AdditionalParameters);
			ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);

			ReadTemplateEditableFile(Notification, ErrorAlert);
			Cancel = True;
		Else
			BeforeCloseCompletion(False, Undefined);
		EndIf;
	EndIf;
	
	If Not Cancel And ValueIsFilled(KeyOfEditObject) Then
		UnlockAtServer(); 
	EndIf;
		
EndProcedure


#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionDocumentFieldOnClick(Item, EventData, StandardProcessing)
	If EventData.Event.type = "click" And StrFind(EventData.Element.href, "CallHelp")<> 0 Then
		OpenHelp("CommonForm.EditOfficeOpenDoc");
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtClient
Procedure ShowInstruction(Command)
	Items.InstructionDocumentField.Visible = Not Items.InstructionDocumentField.Visible;
	Items.DisplayInstruction.Check = Items.InstructionDocumentField.Visible; 
EndProcedure

&AtClient
Procedure Write(Command)
	Notification = New CallbackDescription("WriteContinued", ThisObject);
	ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
EndProcedure

&AtClient
Procedure Rename(Command)
	
	CallbackDescription = New CallbackDescription("OnSelectingLayoutName", ThisObject);
	ShowInputString(CallbackDescription, DocumentName, NStr("vi = 'Hãy nhập tên gọi khuôn in';
															|ru = 'Введите наименование макета';
															|en = 'Enter a template description'; fa = 'Enter a template description';
															|it = 'Inserire denominazione modello';
															|pl = 'Wprowadź nazwę makiety';
															|tr = 'Şablon adını girin'"), 100, False);
	
EndProcedure

&AtClient
Procedure Translate(Command)
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thực hiện dịch tự động sang %1?';
			|ru = 'Выполнить автоматический перевод на %1 язык?';
			|en = 'Do you want to automatically translate into the %1 language?'; fa = 'Do you want to automatically translate into the %1 language?';
			|it = 'Tradurre automaticamente in %1?';
			|pl = 'Wykonać automatyczne tłumaczenie na język %1?';
			|tr = '%1 diline otomatik çeviri yapılsın mı?'"), Items.Language.Title);
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Thực hiện dịch';
											|ru = 'Выполнить перевод';
											|en = 'Translate'; fa = 'ترجمه';
											|it = 'Tradurre';
											|pl = 'Wykonaj tłumaczenie';
											|tr = 'Çevir'"));
	Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không thực hiện';
											|ru = 'Не выполнять';
											|en = 'Do not translate'; fa = 'ترجمه نشود';
											|it = 'Non tradurre';
											|pl = 'Nie wykonuj';
											|tr = 'Yapılmasın'"));
	
	CallbackDescription = New CallbackDescription("WhenAnsweringAQuestionAboutTranslatingALayout", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, Buttons);
EndProcedure

&AtClient
Procedure ShowOriginal(Command)
	TemplateOpenParameters = GetTemplateOpeningParameters(TemplateFileAddress);
	TemplateOpenParameters.NameOfFileToOpen = "Original.docx";
	TemplateOpenParameters.ReadOnly = True;
	
	OpenTemplate(TemplateOpenParameters);
EndProcedure

&AtClient
Procedure OpenEditor(Command)
	Notification = New CallbackDescription("OpenEditorContinued", ThisObject);
	ErrorAlert = New CallbackDescription("ErrorOpeningFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
	
	If Not IsNew() Then
		Modified = True;
	EndIf;

EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tài liệu văn phòng';
										|ru = 'Выберите офисный документ';
										|en = 'Select an office document'; fa = 'Select an office document';
										|it = 'Выберите офисный документ';
										|pl = 'Select an office document';
										|tr = 'Ofis belgesi seçin'");
	ImportParameters.Dialog.Filter = NStr("vi = 'Tài liệu văn phòng';
											|ru = 'Офисный документ';
											|en = 'Office document'; fa = 'Office document';
											|it = 'Офисный документ';
											|pl = 'Office document';
											|tr = 'Ofis belgesi'") + " (*.docx)|*.docx";

	CallbackDescription = New CallbackDescription("ContinueDownloadFromFile", ThisObject);
	FileSystemClient.ImportFile_(CallbackDescription, ImportParameters,, TemplateFileAddress);
EndProcedure

&AtClient
Procedure SaveToFile(Command)
	Notification = New CallbackDescription("SaveToFileContinued", ThisObject);
	ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
EndProcedure

&AtClient
Procedure ExitAppUpdate(Command)
	Notification = New CallbackDescription("ExitAppUpdateCompletion", ThisObject);
	ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
EndProcedure

&AtClient
Procedure PutToClipboard(Command)
	
	HTMLDocument = Items.HTMLField.Document;
	HTMLDocument.defaultView.value_to_copy = GetCurrentRowValue();
	Button = HTMLDocument.getElementById("myb");
	If Button = Undefined Then
		ShowMessageBox(,NStr("vi = 'Hãy chọn trường đối tượng, toán tử hoặc hàm.';
							|ru = 'Выберите поле объекта, оператор или функцию.';
							|en = 'Select an object field, operator, or function.'; fa = 'Select an object field, operator, or function.';
							|it = 'Выберите поле объекта, оператор или функцию.';
							|pl = 'Select an object field, operator, or function.';
							|tr = 'Nesne alanı, operatör veya fonksiyon seçiniz.'"));
	Else
		Button.onclick();
	EndIf;
	
EndProcedure

&AtClient
Procedure ViewPrintableForm(Command)
	Notification = New CallbackDescription("ViewPrintableFormContinued", ThisObject);
	ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
EndProcedure

&AtClient
Procedure ViewPrintableFormContinued(Result, Context) Export
	PrintForm = GetPrintForm();
	SampleAddress = PrintForm.Key;
	If SampleAddress <> Undefined Then
		TemplateOpenParameters = GetTemplateOpeningParameters(SampleAddress);
		TemplateOpenParameters.ShouldPrepareTemplate = False;
		TemplateOpenParameters.ShouldReadHash = False;
		CurrentDate = CommonClient.SessionDate();
		TemplateOpenParameters.NameOfFileToOpen = NStr("vi = 'Mẫu';
														|ru = 'Образец';
														|en = 'Preview'; fa = 'پیش‌نمایش';
														|it = 'Образец';
														|pl = 'Preview';
														|tr = 'Örnek'")+" "+ StrReplace(CurrentDate, ":", "_")+".docx";
		OpenTemplate(TemplateOpenParameters);
	EndIf;
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure MoveGroupOfOperatorsAndFunctions()
	Items.Move(Items.OperatorsAndFunctionsGroup, Items.PageThinClient);
EndProcedure

&AtClient
Procedure OpenEditorContinued(Result, AdditionalParameters) Export
	TemplateOpenParameters = GetTemplateOpeningParameters(TemplateFileAddress);
	TemplateOpenParameters.ShouldPrepareTemplate = False;
	TemplateOpenParameters.ShouldReadHash = True;
	TemplateOpenParameters.NameOfFileToOpen = TemplateFileName;
	OpenTemplate(TemplateOpenParameters);
EndProcedure

&AtClient
Procedure ReadTemplateEditableFile(ContinueNotification, ErrorAlert)
	If PathToTemplateFile = "" Then
		RunCallback(ContinueNotification, Undefined);
		Return;
	EndIf;

	NotificationParameters = New Structure("ContinueNotification, ErrorAlert");
	NotificationParameters.ContinueNotification = ContinueNotification;
	NotificationParameters.ErrorAlert = ErrorAlert;
	
	CallbackDescription = New CallbackDescription("OnImportFileToStorage", ThisObject, NotificationParameters);
#If WebClient Then
	RequestCheckPermissionsAndImportFile(CallbackDescription);
#Else
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	FileSystemClient.ImportFile_(CallbackDescription, ImportParameters, PathToTemplateFile, TemplateFileAddress);
#EndIf
	
EndProcedure

&AtClient
Procedure RequestCheckPermissionsAndImportFile(DetailsOfNotificationFollowUp)
	
	AfterPermissionsHandler = New CallbackDescription("AfterRequestedPermissionsToCheckFile", ThisObject, DetailsOfNotificationFollowUp);
	
	ArrayOfFilesToPut = New Array;
	ArrayOfFilesToPut.Add(New TransferableFileDescription(PathToTemplateFile, TemplateFileAddress));
	
	ArrayOfCalls = New Array;
	Call = New Array;
	Call.Add("BeginPuttingFiles");
	Call.Add(ArrayOfFilesToPut);
	Call.Add(Undefined);
	Call.Add(False);
	Call.Add(UUID);
	ArrayOfCalls.Add(Call);
		
	Call = New Array;
	Call.Add("BeginDeletingFiles");
	Call.Add(PathToTemplateFile);
	Call.Add("");
	Call.Add();
	ArrayOfCalls.Add(Call);

	BeginRequestingUserPermission(AfterPermissionsHandler, ArrayOfCalls);
	
EndProcedure

&AtClient
Procedure AfterRequestedPermissionsToCheckFile(PermissionsGranted, DetailsOfNotificationFollowUp) Export
	If Not PermissionsGranted Then
		Return;
	EndIf;
	CallbackDescription = New CallbackDescription("OnImportFileToStorageCheckReading", ThisObject, DetailsOfNotificationFollowUp);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	FileSystemClient.ImportFile_(CallbackDescription, ImportParameters, PathToTemplateFile, TemplateFileAddress);
EndProcedure

//
// Parameters:
//  FileThatWasPut - Undefined
//                 - Structure:   
//                                    * Location  - String
//                                    * Name       - String
//
&AtClient 
Procedure OnImportFileToStorageCheckReading(FileThatWasPut, DetailsOfNotificationFollowUp) Export
	Context = New Structure("DetailsOfNotificationCompletion", DetailsOfNotificationFollowUp);
	Context.Insert("FilesToUpload", FileThatWasPut);
	CallbackDescription = New CallbackDescription("AfterCheckingExistence", ThisObject, Context);
	File = New File(FileThatWasPut.Name);
	File.BeginCheckingExistence(CallbackDescription);
EndProcedure


// Parameters:
//  Result - Boolean
//  Context - Structure: 
//               * DetailsOfNotificationCompletion - CallbackDescription
//               * FilesToUpload - See OnImportFileToStorageCheckReading.FileThatWasPut
//
&AtClient
Procedure AfterCheckingExistence(Result, Context) Export
	DetailsStartMovingFile = New CallbackDescription("AfterTryToDelete", ThisObject, Context, "FileDeletionError", ThisObject);	
	If Result Then
		BeginDeletingFiles(DetailsStartMovingFile, Context.FilesToUpload.Name);  
	EndIf;
EndProcedure

&AtClient
Procedure AfterTryToDelete(Context) Export
	PathToTemplateFile = "";
	FileStorageStructure = New Structure("Location", TemplateFileAddress);
	RunCallback(Context.DetailsOfNotificationCompletion, FileStorageStructure);
EndProcedure

&AtClient
Procedure FileDeletionError(ErrorInfo, StandardProcessing, Context) Export
	StandardProcessing = False;
	WarnAboutLockAndOpenApp();	
EndProcedure

&AtClient
Procedure ErrorOpeningFile(Result, Context) Export
	OpenFileCompletion(PathToTemplateFile);	
EndProcedure

&AtClient
Procedure ErrorReadingFile(Result, Context) Export
	OpenFileCompletion(PathToTemplateFile);	
EndProcedure

&AtClient
Procedure OnImportFileToStorage(File, NotificationParameters) Export
	
	If File <> Undefined Then
		TemplateFileAddress = File.Location;
		RunCallback(NotificationParameters.ContinueNotification, Undefined);
	Else
		RunCallback(NotificationParameters.ErrorAlert);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveToFileContinued(Result, AdditionalParameters) Export
	
	Template = TemplateFromTempStorage();
	PrepareTemplateForSaving(Template);
	TemplateAddressInTempStorage = PutToTempStorage(Template, UUID);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Lưu khuôn in vào tệp';
										|ru = 'Сохранение макета в файл';
										|en = 'Save template to file'; fa = 'Save template to file';
										|it = 'Сохранение макета в файл';
										|pl = 'Save template to file';
										|tr = 'Şablonu bir dosyaya kaydetme'");
	SavingParameters.Dialog.Filter = NStr("vi = 'Tài liệu văn phòng';
											|ru = 'Офисный документ';
											|en = 'Office document'; fa = 'Office document';
											|it = 'Офисный документ';
											|pl = 'Office document';
											|tr = 'Ofis belgesi'") + " (*.docx)|*.docx";
	FileSystemClient.SaveFile(Undefined, TemplateAddressInTempStorage, DocumentName, SavingParameters);
	
EndProcedure

&AtClient
Procedure ExitAppUpdateCompletion(Result, AdditionalParameters) Export
	CallbackDescription = New CallbackDescription("OnImportFile", ThisObject);
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = Not ValueIsFilled(PathToTemplateFile);
	FileSystemClient.ImportFile_(CallbackDescription, ImportParameters, PathToTemplateFile);
EndProcedure

&AtClient
Procedure WriteContinued(Result, AdditionalParameters) Export
	
	If IsTempStorageURL(TemplateFileAddress) Then
		Template = TemplateFromTempStorage();
		EditableTemplateHash = GetTemplateHash(Template);
		WriteTemplate(Template);
		NotifyWhenOfficeDocSaved();
	EndIf;
	SetHeader();
	
EndProcedure

// Parameters:
//  FileThatWasPut - See OnImportFileToStorageCheckReading.FileThatWasPut
//
&AtClient
Procedure ContinueDownloadFromFile(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	NameArray = StrSplit(FileThatWasPut.Name, "\/");
	
	TemplateOpenParameters = GetTemplateOpeningParameters(TemplateFileAddress);
	TemplateOpenParameters.ShouldPrepareTemplate = HasParameters(TemplateFileAddress);
	TemplateOpenParameters.NameOfFileToOpen = NameArray[NameArray.UBound()];
	
	Modified = TemplateChanged();
	OpenTemplate(TemplateOpenParameters);
	
EndProcedure

&AtServer
Function HasParameters(AddressOfTemplate)
	Template = GetFromTempStorage(AddressOfTemplate);
	TreeOfTemplate = PrintManagement.InitializeTemplateOfDCSOfficeDoc(Template);
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	DocumentTree = DocumentStructure.DocumentTree;
	ParameterNode = PrintManagementInternal.FindNodeByContent(DocumentTree, "w:textInput");
	Return ParameterNode <> Undefined;
EndFunction

&AtServer
Procedure ImportOfficeDocFromMetadata(Val LanguageCode = Undefined)
	
	TranslationRequired = False;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		
		If IdentifierOfTemplate = "" Then
			TemplateFileAddress = PutToTempStorage(GetCommonTemplate("EmptyDOCXTemplate"), UUID);
		Else
			TemplateFileAddress = PutToTempStorage(ModulePrintManager.PrintFormTemplate(IdentifierOfTemplate, LanguageCode), UUID);
		EndIf;
		
		If IdentifierOfTemplate <> "" And Not ValueIsFilled(RefTemplate) Then
			AddressOf1CSuppliedTemplate = PutToTempStorage(ModulePrintManager.SuppliedTemplate(IdentifierOfTemplate, LanguageCode), UUID);
		EndIf;
	EndIf;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		If ValueIsFilled(LanguageCode) Then
			AvailableTabularDocumentLanguages = PrintManagementModuleNationalLanguageSupport.LayoutLanguages(IdentifierOfTemplate);
			TranslationRequired = AvailableTabularDocumentLanguages.Find(LanguageCode) = Undefined;
		EndIf;
		
		If LanguageCode <> "" Then
			LayoutLanguages = PrintManagementModuleNationalLanguageSupport.LayoutLanguages(IdentifierOfTemplate);
			Modified = Modified Or (LayoutLanguages.Find(LanguageCode) = Undefined);
		EndIf;
		
		AutomaticTranslationAvailable = PrintManagementModuleNationalLanguageSupport.AutomaticTranslationAvailable(CurrentLanguage);
		Items.Translate.Visible = AutomaticTranslationAvailable;
		Items.ButtonShowOriginal.Visible = Items.Translate.Visible;

		Items.TranslateAllActions.Visible = Items.Translate.Visible;
		Items.ButtonShowOriginalAllActions.Visible = Items.ButtonShowOriginal.Visible;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyWhenOfficeDocSaved()
	
	NotificationParameters = StandardSubsystemsClient.NewNotificationParameterForSpreadsheetDocumentWrite();
	NotificationParameters.PathToFile = PathToTemplateFile;
	NotificationParameters.TemplateMetadataObjectName = IdentifierOfTemplate;
	NotificationParameters.LanguageCode = CurrentLanguage;
	NotificationParameters.Presentation = DocumentName;
	NotificationParameters.DataSources = DataSources.UnloadValues();
	
	If WritingCompleted Then
		EventName = "Write_OfficeDocument";
	Else
		EventName = "CancelEditingOfficeDoc";
	EndIf;
	Notify(EventName, NotificationParameters, ThisObject);
	
	WritingCompleted = False;
	
EndProcedure


&AtServer
Procedure UnlockAtServer() 
	UnlockDataForEdit(KeyOfEditObject, UUID);
EndProcedure

&AtClient
Procedure BeforeCloseEnd(Result, AdditionalParameters) Export
	
	Cancel = AdditionalParameters.Cancel;
	
	If ReClosing <> True Then
		Modified = Modified Or TemplateChanged();
	EndIf;
	ReClosing = True;
	
	CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
	LanguageDetails = ?(ValueIsFilled(CurrentLanguage), " (" + CurrentLanguage + ")", "");
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lưu các thay đổi vào %1%2?';
																				|ru = 'Сохранить изменения в %1%2?';
																				|en = 'Do you want to save the changes to %1%2?'; fa = 'Do you want to save the changes to %1%2?';
																				|it = 'Сохранить изменения в %1%2?';
																				|pl = 'Do you want to save the changes to %1%2?';
																				|tr = '%1%2 kısmı değişiklikleri kaydedilsin mi?'"), 
		DocumentName, LanguageDetails);
	CommonClient.ShowFormClosingConfirmation(CallbackDescription, Cancel, False, QueryText);
	
	If Modified Then
		Return;
	EndIf;
	
	If Not Cancel Then
		CancelSavingChanges = True;
		Close();
	EndIf;
EndProcedure

&AtServer
Function TemplateChanged()
	
	Template = GetFromTempStorage(TemplateFileAddress);
	If Template <> Undefined Then 	
		Hashing = New DataHashing(HashFunction.CRC32);
		Hashing.Append(Template);
		CacheOfCurrentTemplate =	Hashing.HashSum;
		TemplateModificationCheckTime = CurrentUniversalDateInMilliseconds();
	Else
		CacheOfCurrentTemplate = EditableTemplateHash;
	EndIf;
	
	Return CacheOfCurrentTemplate <> EditableTemplateHash;
EndFunction 

&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export
	
	If Not CancelSavingChanges And Not WritingCompleted Then
		TemplateImported = True;
		Template = TemplateFromTempStorage();
		WriteTemplate(Template);
	EndIf;
	Close(Template);
	
	If Not IsNew() Then
		NotifyWhenOfficeDocSaved();
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayInstruction()
	 
	Template = GetCommonTemplate("GuideHowToSetUpOpenOfficeTemplate");
	InstructionDocumentField = Template.GetText();
		
EndProcedure

&AtClient
Procedure PrepareInstruction()
	
	If Not HideDragZone Then
		InstructionDocumentField = StrReplace(InstructionDocumentField, ".thinclient{", ".webclient{");
	EndIf;
	
EndProcedure


&AtClient
Procedure SetInHTMLField(Value)
	
	If ValueIsFilled(Value) Then
		If IsLinuxClient Then
			HTMLText = "<!DOCTYPE html>
						|
						|<html>
						|
						|<head>
						|    <title>%2</title>
						|    <style type=""text/css"">
						|        body {
						|            background: rgb(255, 255, 255);
						|            overflow-y: hidden;
						|            overflow-x: hidden;
						|        }
						|        
						|        .draggable {
						|            font-weight: normal;
						|            position: relative;
						|            display: block;
						|            border-color: rgb(253, 205, 143);
						|            border-style: dashed;
						|            border-radius: 10px;
						|            border-width: 4px;
						|        }
						|        
						|        .draggabletext {
						|            margin-left: 5px;
						|        }
        				|
						|        .draggabletab {
						|            font-size: xx-small;
						|        }
        				|
						|        .draggablebackground {
						|            position: absolute;
						|            top: 0;
						|            bottom: 0;
						|            z-index: -1;
						|            background-color: rgb(254, 242, 199);
						|            color: rgb(253, 205, 143);
						|            width: 100%%;
						|            height: 100%%;
						|            text-align: right;
						|        }
						|        
						|        .draggablebackgroundtest {
						|            position: absolute;
						|            color: rgb(253, 205, 143);
						|            width: 97%%;
						|            text-align: right;
						|        }
						|        
						|        .myButton {
						|            background-color: #ffec64;
						|            border-radius: 4px;
						|            float: none;
						|            position: absolute;
						|            bottom: 1%%;
						|            right: 1%%;
						|            display: none;
						|            background-color: rgb(254, 242, 199);
						|        }
						|    </style>
						|</head>
						|
						|<body style=""font-family:Arial, Helvetica, sans-serif;"">
						|    <div id=""field"" class=""draggable"" draggable=""true"" ondragstart=""onDragStart(event);"">
						|        <div class=""draggablebackground"">
						|            <Div class=""draggabletab""> <br></Div>
						|
						|            <div class=""draggablebackgroundtest"">
						|                %3
						|            </div>
						|        </div>
						|        <p>
						|            <div class=""draggabletext"">%1</div>
						|        </p>
						|    </div>
						|    <button id=""myb"" class=""myButton"" onclick=""copytext();"">%4</button>
						|    <script type=""text/javascript"">
						|    var value_to_copy = null;
						|        function onDragStart(event) {
						|            event
						|                .dataTransfer
						|                .setData('text/plain', value_to_copy);
						|        }
						|
        				|		function copytext() {
						|            var area = document.createElement('textarea');
						|
						|            document.body.appendChild(area);
						|            area.value = value_to_copy;
						|            area.select();
						|            document.execCommand(""copy"");
						|            document.body.removeChild(area);
						|        }
						|    </script>
						|</body>
						|
						|</html>";
		Else
			HTMLText = "<!DOCTYPE html>
						|<html>
						|
						|<head>
						|    <title>%2</title>
						|    <style type=""text/css"">
						|        body {
						|            background: rgb(255, 255, 255);
						|            overflow-y: hidden;
						|            overflow-x: hidden;
						|        }
						|
						|		  .draggable {
						|            font-weight: normal;
						|            position: relative;
						|            display: block;
						|            border-color: rgb(253, 205, 143);
						|            border-style: dashed;
						|            border-radius: 10px;
						|            border-width: 4px;
						|        }
						|        
						|        .draggabletext {
						|            margin-left:5px;
						|
						|        }
						|
						|        .draggablebackground {
						|            position: absolute;
						|            top: 0;
						|            bottom: 0;
						|            z-index: -1;
						|            background-color: rgb(254, 242, 199);
						|            color: rgb(253, 205, 143);
						|            width: 100%%;
						|            height: 100%;
						|            text-align: right;
						|        }
						|        .draggablebackgroundtest {
						|            position: absolute;
						|            top: 50%%;
						|            color: rgb(253, 205, 143);
						|            width: 97%%;
						|            text-align: right;
						|            transform: translateY(-50%%);
						|        }
						|
						|        .myButton {
						|
						|            background-color: #ffec64;
						|            border-radius: 4px;
						|            float: none;
						|            position: absolute;
						|            bottom: 1%%;
						|            right: 1%%;
						|            display: none;
						|			 background-color: rgb(254, 242, 199);
						|        }
						|    </style>
						|</head>
						|
						|<body style=""font-family:Arial, Helvetica, sans-serif;"">
						|    <div id=""field"" class=""draggable"" draggable=""true"" ondragstart=""onDragStart(event);"">
						|		<div class=""draggablebackground"">
	                    |       	<div class=""draggablebackgroundtest"">
	                    | 				%3
	                    |   	    </div>
	                    |    	</div>
	                    |    	<p><div class=""draggabletext"">%1</div></p>
						|    </div>
						|    <button id=""myb"" class=""myButton"" onclick=""copytext();"">%4</button>
						|    <script type=""text/javascript"">
						|    var value_to_copy = null;
						|        function onDragStart(event) {
						|            event
						|                .dataTransfer
						|                .setData('text/plain', value_to_copy);
						|        }
						|        function copytext() {
						|            var area = document.createElement('textarea');
						|
						|            document.body.appendChild(area);
						|            area.value = value_to_copy;
						|            area.select();
						|            document.execCommand(""copy"");
						|            document.body.removeChild(area);
						|        }
						|    </script>
						|</body>
						|
						|</html>";
		EndIf;
									
	Else
		
		HTMLText = "<!DOCTYPE html>
					|
					|<html>
					|
					|<head>
					|    <title>%2</title>
					|    <style type=""text/css"">
					|        body {
					|            background: rgb(255, 255, 255);
					|            overflow-y: hidden;
					|            overflow-x: hidden;
					|        }
					|
					|        .draggable {
					|            font-weight: normal;
					|            position: relative;
					|            display: block;
					|            border-color: rgb(253, 205, 143);
					|            color: rgb(253, 205, 143);
					|            background-color: rgb(254, 242, 199);
					|            border-style: dashed;
					|            border-radius: 10px;
					|            border-width: 4px;
					|            font-size: large;
					|            text-align: center;
					|        }
					|        
					|    </style>
					|</head>
					|
					|<body style=""font-family:Arial, Helvetica, sans-serif;"">
					|    <div class=""draggable"">
					|        <p><b>%5</b></p>
					|    </div>
					|    
					|</body>
					|
					|</html>";
	EndIf;
	
	HTMLField = StringFunctionsClientServer.SubstituteParametersToString(HTMLText,
		StrReplace(Value, """", "&quot;"),
		NStr("vi = 'Chuyển văn bản';
			|ru = 'Перенос текста';
			|en = 'Wrap the text'; fa = 'Wrap the text';
			|it = 'Перенос текста';
			|pl = 'Wrap the text';
			|tr = 'Metin transferi'"),
		NStr("vi = 'Hãy kéo<br> vào bộ soạn';
			|ru = 'Перетащите<br> в редактор';
			|en = 'Drag<br> to the editor'; fa = 'Drag<br> to the editor';
			|it = 'Перетащите<br> в редактор';
			|pl = 'Drag<br> to the editor';
			|tr = 'Düzenleyiciye<br> sürükle'"),
		NStr("vi = 'Sao chép';
			|ru = 'Скопировать';
			|en = 'Copy'; fa = 'کپی';
			|it = 'Скопировать';
			|pl = 'Copy';
			|tr = 'Kopyala'"),
		NStr("vi = 'Chọn trường';
			|ru = 'Выберите поле';
			|en = 'Select a field'; fa = 'Select a field';
			|it = 'Selezionare campo';
			|pl = 'Wybierz pole';
			|tr = 'Alan seçin'"));
	HTMLField = StrReplace(HTMLField, "%%", "%");
EndProcedure


&AtClient
Procedure OnImportFile(File, AdditionalParameters) Export
	
	TemplateImported = File <> Undefined;
	If TemplateImported Then
		TemplateFileAddress = File.Location;
		TemplateFileName = File.Name;
	EndIf;
	
	WriteTemplateAndClose();
	
EndProcedure

&AtClient
Procedure WriteTemplateAndClose()
	Template = Undefined;
	If TemplateImported Then
		Template = TemplateFromTempStorage();
		WriteTemplate(Template);
		WritingCompleted = True;
	EndIf;
	
	Close(Template);
EndProcedure


&AtServer
Function TemplateFromTempStorage()
	Template = GetFromTempStorage(TemplateFileAddress); 
	Return Template;
EndFunction

&AtServer
Procedure WriteTemplate(Template)
	
	PrepareTemplateForSaving(Template);
	
	TemplateAddressInTempStorage = PutToTempStorage(Template, UUID);
	TemplateDetails = PrintManagement.TemplateDetails();
	TemplateDetails.TemplateMetadataObjectName = IdentifierOfTemplate;
	TemplateDetails.TemplateAddressInTempStorage = TemplateAddressInTempStorage;
	TemplateDetails.LanguageCode = CurrentLanguage;
	TemplateDetails.Description = DocumentName;
	TemplateDetails.Ref = RefTemplate;
	TemplateDetails.TemplateType = "DOCX";
	TemplateDetails.DataSources = DataSources.UnloadValues();
	
	IdentifierOfTemplate = PrintManagement.WriteTemplate(TemplateDetails);
	If Not ValueIsFilled(RefTemplate) Then
		RefTemplate = PrintManagement.RefTemplate(IdentifierOfTemplate);
	EndIf;
	
	WriteTemplatesInAdditionalLangs();
	
	If Not Items.Language.Enabled Then
		Items.Language.Enabled  = True;
	EndIf;
	
	TemplateSavedLangs.Add(CurrentLanguage);
	WritingCompleted = True;
	Modified = False;
	
EndProcedure

&AtServer
Procedure WriteTemplatesInAdditionalLangs()
	
	TemplateParameters1 = New Structure;
	TemplateParameters1.Insert("IDOfTemplateBeingCopied", IDOfTemplateBeingCopied);
	TemplateParameters1.Insert("CurrentLanguage", CurrentLanguage);
	TemplateParameters1.Insert("UUID", UUID);
	TemplateParameters1.Insert("IdentifierOfTemplate", IdentifierOfTemplate);
	TemplateParameters1.Insert("LayoutOwner", LayoutOwner);
	TemplateParameters1.Insert("DocumentName", DocumentName);
	TemplateParameters1.Insert("RefTemplate", RefTemplate);
	TemplateParameters1.Insert("TemplateType", "DOCX");
	
	PrintManagement.WriteTemplatesInAdditionalLangs(TemplateParameters1);
	
EndProcedure

&AtServer
Procedure PrepareTemplateForSaving(Template)
	TreeOfTemplate = PrintManagement.InitializeTemplateOfDCSOfficeDoc(Template);
	ReplacementsMap = New Map();
	For Each TextParameter In TreeOfTemplate.DocumentStructure.TextParameters Do
		TextParameterKey = TextParameter;
		ReplaceViewParameters(TextParameter);
		ReplacementsMap.Insert(TextParameterKey, TextParameter);
	EndDo;
	AreaPopulationParameters = PrintManagement.AreaPopulationParameters();
	AreaPopulationParameters.ShouldAddLinks = False;
	PrintManagement.SpecifyParameters(TreeOfTemplate, ReplacementsMap, AreaPopulationParameters);
	Address = PrintManagementInternal.GetPrintForm(TreeOfTemplate);
	Template = GetFromTempStorage(Address);
		
EndProcedure

&AtServer
Procedure PrepareTemplateForOpening(Template, PopulateTemplateFileAddress = False)
	TreeOfTemplate = PrintManagement.InitializeTemplateOfDCSOfficeDoc(Template);
	DocumentStructure = TreeOfTemplate.DocumentStructure;
	DocumentTree = DocumentStructure.DocumentTree;
	PrintManagement.ConvertParameters(DocumentTree);
	For Each HeaderOrFooter In DocumentStructure.HeaderFooter Do
		PrintManagement.ConvertParameters(HeaderOrFooter.Value);
	EndDo;
	
	ReplacementsMap = New Map();
	For Each TextParameter In TreeOfTemplate.DocumentStructure.TextParameters Do
		TextParameterKey = TextParameter;
		ReplaceParametersWithViews(TextParameter);
		ReplacementsMap.Insert(TextParameterKey, TextParameter);
	EndDo;
	
	AreaPopulationParameters = PrintManagement.AreaPopulationParameters();
	AreaPopulationParameters.ShouldAddLinks = False;
	PrintManagement.SpecifyParameters(TreeOfTemplate, ReplacementsMap, AreaPopulationParameters);
	If PopulateTemplateFileAddress Then
		Address = PrintManagementInternal.GetPrintForm(TreeOfTemplate, TemplateFileAddress);
	Else
		Address = PrintManagementInternal.GetPrintForm(TreeOfTemplate);
	EndIf;
	
	Template = GetFromTempStorage(Address);
EndProcedure

&AtServer
Procedure ReplaceParametersWithViews(String)
	
	ReplacementParameters = RepresentationTextParameters(String(String));
	
	String = ReplaceInline(String, ReplacementParameters);
	
EndProcedure

&AtServer
Function RepresentationTextParameters(Val Text)
	
	Result = New Map();
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.RepresentationTextParameters(Text, ThisObject);
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ReplaceViewParameters(String)
	
	ReplacementParameters = FormulasFromText(String(String));
	
	For Each Parameter In ReplacementParameters Do
		Formula = Parameter.Key;
		If StrOccurrenceCount(Formula, "[") > 1 Then
			Formula = Mid(Formula, 2, StrLen(Formula) - 2);
		EndIf;		
		
		ErrorText = FormulasConstructorInternal.CheckFormula(ThisObject, Formula);
			
		If ValueIsFilled(ErrorText) Then
			Common.MessageToUser(ErrorText);
		EndIf;
	EndDo;
	
	String = ReplaceInline(String, ReplacementParameters);
	
EndProcedure

&AtServer
Function ReplaceInline(Val String, ReplacementParameters)
	
	For Each Item In ReplacementParameters Do
		SearchSubstring = Item.Key;
		ReplaceSubstring = Item.Value;
		String = StrReplace(String, SearchSubstring, ReplaceSubstring);
	EndDo;
	
	Return String;
	
EndFunction

&AtServer
Function FormulasFromText(Val Text)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.FormulasFromText(Text, ThisObject);
	EndIf;
	
EndFunction

&AtClient
Procedure SetInitialFormSettings()
			
	SetDocumentName();
	SetHeader();
	SetUpCommandPresentation();

EndProcedure

&AtClient
Procedure SetDocumentName()

	If IsBlankString(DocumentName) Then
		UsedNames = New Array;
		Notify("SpreadsheetDocumentsToEditNameRequest", UsedNames, ThisObject);
		
		IndexOf = 1;
		While UsedNames.Find(NewDocumentName() + IndexOf) <> Undefined Do
			IndexOf = IndexOf + 1;
		EndDo;
		
		DocumentName = NewDocumentName() + IndexOf;
	EndIf;

EndProcedure

&AtClient
Function NewDocumentName()
	Return NStr("vi = 'Mới';
				|ru = 'Новый';
				|en = 'New'; fa = 'جدید';
				|it = 'Новый';
				|pl = 'New';
				|tr = 'Yeni'");
EndFunction

&AtClient
Function GetTemplateOpeningParameters(DocumentAddress)
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DocumentAddress", DocumentAddress);
	OpeningParameters.Insert("ShouldPrepareTemplate", True);
	OpeningParameters.Insert("ShouldReadHash", False);
	OpeningParameters.Insert("NameOfFileToOpen", "");
	OpeningParameters.Insert("ReadOnly", EditingDenied);
	Return OpeningParameters;
EndFunction

&AtClient
Procedure OpenTemplate(OpeningParameters)

	CompletionHandler = New CallbackDescription("OpenAfterSavedAtClient", ThisObject, OpeningParameters);

	Template = GetFromTempStorage(OpeningParameters.DocumentAddress);
	
	If OpeningParameters.ShouldPrepareTemplate Then
		PrepareTemplateForOpening(Template, OpeningParameters.DocumentAddress = TemplateFileAddress);
	EndIf;
	
	If OpeningParameters.ShouldReadHash Then
		EditableTemplateHash = GetTemplateHash(Template);
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	AdditionalParameters.Insert("TempDirectory", TempDirectory);
	AfterAttachExtension = New CallbackDescription("AfterAttachExtension", ThisObject, AdditionalParameters);
	FileSystemClient.Attach1CEnterpriseExtension(AfterAttachExtension);
	
	Items.OpenEditor.DefaultButton = False;
	Items.WriteAndClose.DefaultButton = True;
	
	Items.InstructionDocumentField.Visible = False;
	Items.DisplayInstruction.Check = False;
EndProcedure

&AtClient
Procedure AfterAttachExtension(Attached, AdditionalParameters) Export
	If Attached Then
		Handler = New CallbackDescription("OpenTemplateAfterGotTempDir", ThisObject, AdditionalParameters.CompletionHandler);
		If TempDirectory = "" Then
#If WebClient Then
			FileSystemClient.SelectDirectory(Handler);	
#Else
			FileSystemClient.CreateTemporaryDirectory(Handler);
#EndIf
		Else
			RunCallback(Handler, TempDirectory);
		EndIf;
	Else
		Handler = New CallbackDescription("AfterRequestPermissionsToOpenTemplate", ThisObject, AdditionalParameters);
		RunCallback(Handler);
	EndIf;
EndProcedure

// Parameters:
//  CreatedTempDir - String
//  CompletionHandler - CallbackDescription
//
&AtClient
Procedure OpenTemplateAfterGotTempDir(CreatedTempDir, CompletionHandler) Export
	TempDirectory = CommonClientServer.AddLastPathSeparator(
		CreatedTempDir);
	
	OpeningParameters = CompletionHandler.AdditionalParameters;
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("TempDirectory", TempDirectory);
	
	AfterPermissionsHandler = New CallbackDescription("AfterRequestPermissionsToOpenTemplate", ThisObject, Context);
	
	ArrayOfReceivedFiles = New Array;
	ArrayOfReceivedFiles.Add(New TransferableFileDescription(TempDirectory+OpeningParameters.NameOfFileToOpen,OpeningParameters.DocumentAddress));
	
	ArrayOfCalls = New Array;
	Call = New Array;
	Call.Add("BeginGettingFiles");
	Call.Add(ArrayOfReceivedFiles);
	Call.Add(TempDirectory);
	Call.Add(False);
	ArrayOfCalls.Add(Call);
		
	Call = New Array;
	Call.Add("BeginRunningApplication");
	Call.Add(TempDirectory+OpeningParameters.NameOfFileToOpen);
	Call.Add();
	Call.Add(False);
	ArrayOfCalls.Add(Call);
	
	BeginRequestingUserPermission(AfterPermissionsHandler, ArrayOfCalls);
EndProcedure

&AtClient
Procedure AfterRequestPermissionsToOpenTemplate(PermissionsGranted, Context) Export
	
	If PermissionsGranted = False Then
		Return;
	EndIf;
	
	AfterPermissionsHandler = Context.CompletionHandler; // CallbackDescription
	TempDirectory = Context.TempDirectory;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	
#If WebClient Then
		SavingParameters.Interactively = True;
#Else
		SavingParameters.Interactively = False;
#EndIf

	OpeningParameters = AfterPermissionsHandler.AdditionalParameters;		
	FileSystemClient.SaveFile(AfterPermissionsHandler, OpeningParameters.DocumentAddress, TempDirectory+OpeningParameters.NameOfFileToOpen, SavingParameters);
EndProcedure

&AtClient
Procedure OpenAfterSavedAtClient(ObtainedFiles, OpeningParameters) Export

	If ObtainedFiles <> Undefined Then		
		PathToFile = ObtainedFiles[0].FullName;
		
		If OpeningParameters.DocumentAddress = TemplateFileAddress Then
			PathToTemplateFile = PathToFile;
		EndIf;
		
		FileOnHardDrive = New File(PathToFile);
		DetailsAfterSetReadOnly = New CallbackDescription("OpenFileCompletion", ThisObject, PathToFile);
		FileOnHardDrive.BeginSettingReadOnly(DetailsAfterSetReadOnly, OpeningParameters.ReadOnly);
	EndIf;
EndProcedure

&AtClient
Procedure OpenFileCompletion(PathToFile) Export		
	FileOpeningParameters = FileSystemClient.FileOpeningParameters();
	FileSystemClient.OpenFile(PathToFile,,,FileOpeningParameters);
EndProcedure

&AtServerNoContext
Function GetTemplateHash(AddressOrData)
	Hashing = New DataHashing(HashFunction.CRC32);
	If TypeOf(AddressOrData) = Type("String") 
		And IsTempStorageURL(AddressOrData) Then
		
		Hashing.Append(GetFromTempStorage(AddressOrData));
	Else
		Hashing.Append(AddressOrData);
	EndIf;
	Return Hashing.HashSum;
EndFunction

&AtClient
Procedure MinimizeInterface()
	
	MinimizeInterfaceAtServer();
	RefreshInterface();
	ReturnInterfaceAtServer();
	
EndProcedure

&AtServer
Procedure MinimizeInterfaceAtServer()
	InterfaceCurrentSettings = SystemSettingsStorage.Load("Common/ClientApplicationInterfaceSettings");
	PanelsSettingAddress = PutToTempStorage(InterfaceCurrentSettings, UUID);
	
	CompositionSettings1 = New ClientApplicationInterfaceContentSettings;
	InterfaceSettings = New ClientApplicationInterfaceSettings;
	InterfaceSettings.SetContent(CompositionSettings1);
	SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings", , InterfaceSettings);
	
EndProcedure

&AtClient
Procedure ReturnInterface()
	
	RefreshInterface();
	
EndProcedure

&AtServer
Procedure ReturnInterfaceAtServer()
	
	If IsTempStorageURL(PanelsSettingAddress) Then
		InterfaceSettings = GetFromTempStorage(PanelsSettingAddress);
		SystemSettingsStorage.Save("Common/ClientApplicationInterfaceSettings", , InterfaceSettings);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetHeader()
	
	Title = DocumentName;
	
	If ValueIsFilled(CurrentLanguage) Then 
		CurrentLanguagePresentation = Items["Language_"+CurrentLanguage].Title; 
		Title = Title + " ("+CurrentLanguagePresentation+")";
	EndIf;
	
	If IsNew() Then
		Title = Title + " (" + NStr("vi = 'tạo mới';
									|ru = 'создание';
									|en = 'create'; fa = 'ایجاد';
									|it = 'создание';
									|pl = 'tworzenie';
									|tr = 'oluşturma'") + ")";
	ElsIf EditingDenied Then
		Title = Title + " (" + NStr("vi = 'chỉ xem';
									|ru = 'только просмотр';
									|en = 'read-only'; fa = 'read-only';
									|it = 'solo visualizzazione';
									|pl = 'tylko podgląd';
									|tr = 'sadece görüntüleme'") + ")";
	EndIf;
	
EndProcedure

&AtClient
Function IsNew()
	Return Not ValueIsFilled(Parameters.Ref) And IsBlankString(IdentifierOfTemplate) And IsBlankString(Parameters.PathToFile);
EndFunction

&AtClient
Procedure WhenFormatFieldSelection(Format, AdditionalParameters) Export
	
	If Format = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.Format = Format;
	CurrentData.Pattern = Format(CurrentData.Value, CurrentData.Format);
	
	PopulateHTMLFIeldByCurrField();
EndProcedure

&AtClient
Procedure Attachable_SwitchLanguage(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	ParametersForResuming = New Structure("Command", Command);
	Notification = New CallbackDescription("SwitchLangAfterImportFileFollowUp", ThisObject, ParametersForResuming);
	ErrorAlert = New CallbackDescription("ErrorReadingFile", ThisObject);
	ReadTemplateEditableFile(Notification, ErrorAlert);
EndProcedure

&AtClient
Procedure Attachable_WhenSwitchingTheLanguage(LanguageCode, AdditionalParameters) Export
	
	ImportOfficeDocFromMetadata(LanguageCode);
	If TranslationRequired And AutomaticTranslationAvailable Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khuôn in vẫn chưa được dịch sang %1.
			|Dịch tự động?';
			|ru = 'Макет еще не переведен на %1 язык.
			|Выполнить автоматический перевод?';
			|en = 'Template has not been translated into the %1 language yet.
			|Do you want to translate it automatically?'; fa = 'Template has not been translated into the %1 language yet.
			|Do you want to translate it automatically?';
			|it = 'Il modello non è ancora stato tradotto in %1.
			|Tradurre automaticamente?';
			|pl = 'Makieta jeszcze nie jest przetłumaczona na język %1.
			|Wykonać automatyczne tłumaczenie?';
			|tr = 'Şablon henüz %1 diline çevrilmedi.
			|Otomatik çeviri yapılsın mı?'"), Items.Language.Title);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Dịch';
												|ru = 'Выполнить перевод';
												|en = 'Translate'; fa = 'ترجمه';
												|it = 'Tradurre';
												|pl = 'Wykonaj tłumaczenie';
												|tr = 'Çevir'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không thực hiện';
												|ru = 'Не выполнять';
												|en = 'Do not translate'; fa = 'ترجمه نشود';
												|it = 'Non tradurre';
												|pl = 'Nie wykonuj';
												|tr = 'Yapılmasın'"));
		
		CallbackDescription = New CallbackDescription("WhenAnsweringAQuestionAboutTranslatingALayout", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		TemplateOpenParameters = GetTemplateOpeningParameters(TemplateFileAddress);
		TemplateOpenParameters.ShouldReadHash = True;
		TemplateOpenParameters.NameOfFileToOpen = TemplateFileName;
		OpenTemplate(TemplateOpenParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchLangAfterImportFileFollowUp(Result, AdditionalParameters) Export
	
	Modified = Modified Or TemplateChanged();
	
	ParametersForResuming = New Structure("Command", AdditionalParameters.Command);
	CallbackDescription = New CallbackDescription("SwitchLanguageContinued", ThisObject, ParametersForResuming);
	
	If Modified Then
		LanguageDetails = ?(ValueIsFilled(CurrentLanguage), " (" + CurrentLanguage + ")", "");
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lưu các thay đổi vào %1%2?';
																					|ru = 'Сохранить изменения в %1%2?';
																					|en = 'Do you want to save the changes to %1%2?'; fa = 'Do you want to save the changes to %1%2?';
																					|it = 'Сохранить изменения в %1%2?';
																					|pl = 'Do you want to save the changes to %1%2?';
																					|tr = '%1%2 kısmı değişiklikleri kaydedilsin mi?'"), DocumentName, LanguageDetails);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel, ,
			DialogReturnCode.Yes);
	Else
		RunCallback(CallbackDescription, DialogReturnCode.No);
	EndIf;
			
EndProcedure

&AtClient
Procedure SwitchLanguageContinued(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	ElsIf Response = DialogReturnCode.Yes Then
	
		Template = TemplateFromTempStorage();
		WriteTemplate(Template);
		
		Modified = False;
	ElsIf Response = DialogReturnCode.No Then
		Modified = False;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.SwitchLanguage(ThisObject, AdditionalParameters.Command);
		SetHeader();
		Items.DeleteLayoutLanguage.Visible = CurrentLanguage <> CommonClient.DefaultLanguageCode();
		Items.ButtonShowOriginal.Enabled = CurrentLanguage <> CommonClient.DefaultLanguageCode();
	EndIf;	
EndProcedure

&AtClient
Procedure DeleteLayoutLanguage(Command)
	
	If CurrentLanguage = CommonClient.DefaultLanguageCode() Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("DeleteLayoutLanguageContinued", ThisObject, , "ErrorMovingDeletingFile", ThisObject);
	BeginDeletingFiles(CallbackDescription, PathToTemplateFile);
	
EndProcedure

&AtClient
Procedure ErrorMovingDeletingFile(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	StandardProcessing = False;
	WarnAboutLockAndOpenApp();	
EndProcedure

&AtClient
Procedure WarnAboutLockAndOpenApp()
	CallbackDescription = New CallbackDescription("OpenFileCompletion", ThisObject, PathToTemplateFile);
	ShowMessageBox(CallbackDescription, NStr("vi = 'Kết thúc công việc với tệp trong ứng dụng khác.';
											|ru = 'Завершите работу с файлом в другом приложении.';
											|en = 'Complete the operation with the file in another application.'; fa = 'Complete the operation with the file in another application.';
											|it = 'Завершите работу с файлом в другом приложении.';
											|pl = 'Complete the operation with the file in another application.';
											|tr = 'Başka bir uygulamada dosya yönetimi tamamlandı.'"), , NStr("vi = 'Tệp đang mở trong ứng dụng khác';
																															|ru = 'Файл открыт в другом приложении';
																															|en = 'The file is opened in another application'; fa = 'The file is opened in another application';
																															|it = 'Файл открыт в другом приложении';
																															|pl = 'The file is opened in another application';
																															|tr = 'Dosya başka bir uygulamada açık'"));
EndProcedure

&AtServer
Procedure DeleteLayoutInCurrentLanguage()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.DeleteTemplate(IdentifierOfTemplate, CurrentLanguage);
	EndIf;
	
	MenuLang = Items.Language;
	LangsToAdd = Items.LangsToAdd;
	LangOfFormToDelete = CurrentLanguage;
	CurrentLanguage = Common.DefaultLanguageCode();
	For Each LangButton In MenuLang.ChildItems Do
		If StrEndsWith(LangButton.Name, LangOfFormToDelete) Then
			LangButton.Check = False;
			LangButton.Visible = False;
		EndIf;
		
		If StrEndsWith(LangButton.Name, CurrentLanguage) Then
			LangButton.Check = True;
		EndIf;
	EndDo;
	
	For Each ButtonForAddedLang In LangsToAdd.ChildItems Do
		If StrEndsWith(ButtonForAddedLang.Name, LangOfFormToDelete) Then
			ButtonForAddedLang.Visible = True;
		EndIf;
	EndDo;
	
	MenuLanguageAllActions = Items.LanguageAllActions;
	LangsToAddAllActions = Items.LangsToAddAllActions;
	For Each LangButton In MenuLanguageAllActions.ChildItems Do
		If TypeOf(LangButton) = Type("FormButton") Then
			If StrEndsWith(LangButton.CommandName, LangOfFormToDelete) Then
				LangButton.Check = False;
				LangButton.Visible = False;
			EndIf;
			
			If StrEndsWith(LangButton.CommandName, CurrentLanguage) Then
				LangButton.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	For Each ButtonForAddedLang In LangsToAddAllActions.ChildItems Do
		If TypeOf(ButtonForAddedLang) = Type("FormButton") Then
			If StrEndsWith(ButtonForAddedLang.CommandName, LangOfFormToDelete) Then
				ButtonForAddedLang.Visible = True;
			EndIf;
		EndIf;
	EndDo;
	
	Items.Language.Title = Items["Language_"+CurrentLanguage].Title;
	Items.LanguageAllActions.Title = Items["Language_"+CurrentLanguage].Title;
	
	ImportOfficeDocFromMetadata(CurrentLanguage);
	PreparedTemplate = GetFromTempStorage(TemplateFileAddress);
	
	PrepareTemplateForOpening(PreparedTemplate);
	PutToTempStorage(PreparedTemplate, TemplateFileAddress);
	EditableTemplateHash = GetTemplateHash(TemplateFileAddress);
	TemplateModificationCheckTime =	CurrentUniversalDateInMilliseconds();
	
	
	Modified = False;
	
EndProcedure

&AtClient
Procedure DeleteLayoutLanguageContinued(AdditionalParameters) Export
	PathToTemplateFile = "";
	DeleteLayoutInCurrentLanguage();

	WritingCompleted = True;
	NotifyWhenOfficeDocSaved();

	Items.DeleteLayoutLanguage.Visible = CurrentLanguage <> CommonClient.DefaultLanguageCode();
	Items.ButtonShowOriginal.Enabled = False;
	SetHeader();
EndProcedure

&AtClient
Procedure WhenAnsweringAQuestionAboutTranslatingALayout(Response, AdditionalParameters) Export
	
	TemplateOpenParameters = GetTemplateOpeningParameters(TemplateFileAddress);
	TemplateOpenParameters.ShouldReadHash = True;
	TemplateOpenParameters.NameOfFileToOpen = TemplateFileName;
	
	If Response <> DialogReturnCode.Yes Then
		OpenTemplate(TemplateOpenParameters);
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport.TextTranslation") Then
		CallbackDescription = New CallbackDescription("OnCompleteTranslationSettingsCheck", ThisObject, TemplateOpenParameters);
		ModuleTranslationOfTextIntoOtherLanguagesClient = CommonClient.CommonModule("TextTranslationToolClient");
		ModuleTranslationOfTextIntoOtherLanguagesClient.CheckSettings(ThisObject, CallbackDescription);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteTranslationSettingsCheck(SetupExecuted, TemplateOpenParameters) Export
	
	If Not SetupExecuted Then
		Return;
	EndIf;
	
	TranslateLayoutTexts();
	OpenTemplate(TemplateOpenParameters);
	
EndProcedure

&AtServer
Procedure TranslateLayoutTexts()
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		PrintManagementModuleNationalLanguageSupport.TranslateOfficeDoc(TemplateFileAddress, CurrentLanguage, Common.DefaultLanguageCode());
		
		Modified = True;
	EndIf;
	
EndProcedure


#Region PrintableFormConstructor

&AtServer
Procedure PickupSample(MetadataObject)
	
	QueryText =
	"SELECT TOP 1
	|	SpecifiedTableAlias.Ref AS Ref
	|FROM
	|	&Table AS SpecifiedTableAlias
	|ORDER BY
	|	Ref DESC";
	
	QueryText = StrReplace(QueryText, "&Table", MetadataObject.FullName());
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Pattern = Selection.Ref;
	EndIf;
	
EndProcedure

&AtServer
Procedure ExpandFieldList()
	
	AttributesToBeAdded = New Array;
	AttributesToBeAdded.Add(New FormAttribute("Pattern", New TypeDescription, NameOfTheFieldList()));
	AttributesToBeAdded.Add(New FormAttribute("Format", New TypeDescription("String"), NameOfTheFieldList()));
	AttributesToBeAdded.Add(New FormAttribute("DefaultFormat", New TypeDescription("String"), NameOfTheFieldList()));
	AttributesToBeAdded.Add(New FormAttribute("ButtonSettingsFormat", New TypeDescription("Number"), NameOfTheFieldList()));
	AttributesToBeAdded.Add(New FormAttribute("Value", New TypeDescription, NameOfTheFieldList()));
	AttributesToBeAdded.Add(New FormAttribute("Common", New TypeDescription("Boolean"), NameOfTheFieldList()));
	
	ChangeAttributes(AttributesToBeAdded);
	
	FieldList = Items[NameOfTheFieldList()];
	FieldList.Header = True;
	FieldList.SetAction("OnActivateRow", "Attachable_AvailableFieldsWhenLineIsActivated");
	
	ColumnNamePresentation = FormulasConstructorInternal.ColumnNamePresentation(NameOfTheFieldList());
	
	ColumnPresentation = Items[ColumnNamePresentation];
	ColumnPresentation.Title = NStr("vi = 'Trường';
									|ru = 'Поле';
									|en = 'Field'; fa = 'فیلد';
									|it = 'Поле';
									|pl = 'Field';
									|tr = 'Alan'");
	
	ColumnPattern = Items.Add(NameOfTheFieldList() + "Pattern", Type("FormField"), FieldList);
	ColumnPattern.DataPath = NameOfTheFieldList() + "." + "Pattern";
	ColumnPattern.Type = FormFieldType.InputField;
	ColumnPattern.Title = NStr("vi = 'Mẫu';
								|ru = 'Образец';
								|en = 'Preview'; fa = 'پیش‌نمایش';
								|it = 'Образец';
								|pl = 'Preview';
								|tr = 'Örnek'");
	ColumnPattern.SetAction("OnChange", "Attachable_SampleWhenChanging");
	ColumnPattern.ShowInFooter = False;
	
	ButtonSettingsFormat = Items.Add(NameOfTheFieldList() + "ButtonSettingsFormat", Type("FormField"), FieldList);
	ButtonSettingsFormat.DataPath = NameOfTheFieldList() + "." + "ButtonSettingsFormat";
	ButtonSettingsFormat.Type = FormFieldType.PictureField;
	ButtonSettingsFormat.ShowInHeader = True;
	ButtonSettingsFormat.HeaderPicture = PictureLib.DataCompositionOutputParameters;	
	ButtonSettingsFormat.ValuesPicture = PictureLib.DataCompositionOutputParameters;	
	ButtonSettingsFormat.Title = NStr("vi = 'Tùy chỉnh định dạng';
										|ru = 'Настройка формата';
										|en = 'Configure format'; fa = 'Configure format';
										|it = 'Impostazione formato';
										|pl = 'Ustawienie formatu';
										|tr = 'Format ayarlama'");
	ButtonSettingsFormat.TitleLocation = FormItemTitleLocation.None;
	ButtonSettingsFormat.CellHyperlink = True;
	ButtonSettingsFormat.ShowInFooter = False;
		
	SetExamplesValues();
	SetFormatValuesDefault();
	SetUpFieldSample();
	MarkCommonFields();
	
	For Each AppearanceItem In ConditionalAppearance.Items Do
		For Each FormattedField In AppearanceItem.Fields.Items Do
			If FormattedField.Field = New DataCompositionField(NameOfTheFieldList() + "Presentation") Then
				FormattedField = AppearanceItem.Fields.Items.Add();
				FormattedField.Field = New DataCompositionField(NameOfTheFieldList() + "Pattern");
				FormattedField = AppearanceItem.Fields.Items.Add();
				FormattedField.Field = New DataCompositionField(NameOfTheFieldList() + "ButtonSettingsFormat");
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	// Color of the fields that are not common for the selected objects.
	
	AppearanceItem = ConditionalAppearance.Items.Add();
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(NameOfTheFieldList());
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(NameOfTheFieldList() + ".Common");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = False;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);	
	
EndProcedure

&AtServer
Function FillListDisplayedFields(FieldsCollection, Result = Undefined)
	
	If Result = Undefined Then
		Result = New Array;
	EndIf;
	
	For Each Item In FieldsCollection.GetItems() Do
		If Not ValueIsFilled(Item.DataPath) Then
			Continue;
		EndIf;
		Result.Add(Item.DataPath);
		FillListDisplayedFields(Item, Result);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetExamplesValues(FieldsCollection = Undefined, PrintData = Undefined)
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Return;
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");

	If FieldsCollection = Undefined Then
		FieldsCollection = ThisObject[NameOfTheFieldList()];
	EndIf;
	
	If PrintData = Undefined Then
		If Not ValueIsFilled(Pattern) Then
			Return;
		EndIf;
		Objects = CommonClientServer.ValueInArray(Pattern);
		DisplayedFields = FillListDisplayedFields(FieldsCollection);
		If Common.SubsystemExists("StandardSubsystems.Print") Then
			Try
				PrintData = ModulePrintManager.PrintData(Objects, DisplayedFields, CurrentLanguage);
			Except
				UnlockDataForEdit(KeyOfEditObject, UUID);
				Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
			EndTry;
			GetUserMessages(True);
		Else
			Return;
		EndIf;
	EndIf;
	
	ModulePrintManager.SetExamplesValues(FieldsCollection, PrintData, Pattern);
	
EndProcedure

&AtServer
Procedure SetFormatValuesDefault(FieldsCollection = Undefined)
	
	If FieldsCollection = Undefined Then
		FieldsCollection = ThisObject[NameOfTheFieldList()];
	EndIf;
	
	For Each Item In FieldsCollection.GetItems() Do
		If Not ValueIsFilled(Item.DataPath) Then
			Continue;
		EndIf;
		
		If Not ValueIsFilled(Item.DefaultFormat) Then
			Item.DefaultFormat = DefaultFormat(Item.Type);
		EndIf;
		
		Item.Format = Item.DefaultFormat;
		
		If ValueIsFilled(Item.Format) Then
			Item.Pattern = Format(Item.Pattern, Item.Format);
		Else
			Item.ButtonSettingsFormat = -1;
		EndIf;
			
		SetFormatValuesDefault(Item);
	EndDo;
	
EndProcedure

&AtServer
Function DefaultFormat(TypeDescription)
	
	Format = "";
	If TypeDescription.Types().Count() <> 1 Then
		Return Format;
	EndIf;
	
	Type = TypeDescription.Types()[0];
	
	If Type = Type("Number") Then
		Format = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'ND=%1; NFD=%2';
				|ru = 'ЧЦ=%1; ЧДЦ=%2';
				|en = 'ND=%1; NFD=%2'; fa = 'ND=%1; NFD=%2';
				|it = 'ND=%1; NFD=%2';
				|pl = 'ND=%1; NFD=%2';
				|tr = 'ND=%1; NFD=%2'"),
			TypeDescription.NumberQualifiers.Digits,
			TypeDescription.NumberQualifiers.FractionDigits);
	ElsIf Type = Type("Date") Then
		If TypeDescription.DateQualifiers.DateFractions = DateFractions.Date Then
			Format = NStr("vi = 'DLF=D';
							|ru = 'ДЛФ=D';
							|en = 'DLF=D'; fa = 'DLF=D';
							|it = 'ДЛФ=D';
							|pl = 'DLF=D';
							|tr = 'DLF=G'");
		Else
			Format = NStr("vi = 'DLF=DT';
							|ru = 'ДЛФ=DT';
							|en = 'DLF=DT'; fa = 'DLF=DT';
							|it = 'ДЛФ=DT';
							|pl = 'DLF=DT';
							|tr = 'DLF=DT'");
		EndIf;
	ElsIf Type = Type("Boolean") Then
		Format = NStr("vi = 'BF=Không; BT=Có';
						|ru = 'БЛ=Нет; БИ=Да';
						|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
						|it = 'BF=No; BT=Si';
						|pl = 'BF=Nie; BT=Tak';
						|tr = 'BL=Hayır; BI=Evet'");
	EndIf;
	
	Return Format;
	
EndFunction

&AtServer
Function LayoutOwner()
	
	If ValueIsFilled(LayoutOwner) Then
		Return Common.MetadataObjectByID(LayoutOwner);
	EndIf;
	
	TemplatePath = IdentifierOfTemplate;
	
	PathParts = StrSplit(TemplatePath, ".", True);
	If PathParts.Count() <> 2 And PathParts.Count() <> 3 Then
		Return Undefined;
	EndIf;
	
	If PathParts.Count() <> 3 Then
		Return Undefined;
	EndIf;
	
	PathParts.Delete(PathParts.UBound());
	ObjectName = StrConcat(PathParts, ".");
	
	If IsBlankString(ObjectName) Then
		Return Undefined;
	EndIf;
	
	Return Common.MetadataObjectByFullName(ObjectName);
	
EndFunction

&AtServerNoContext
Function FieldsCollections(DataSources, EditParameters)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Try
			Return ModulePrintManager.CollectionOfDataSourcesFields(DataSources);
		Except
			UnlockDataForEdit(EditParameters.KeyOfEditObject, EditParameters.UUID);
			Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry
	EndIf;

	Return New Array;
	
EndFunction

&AtClient
Procedure OnSelectingLayoutName(NewTemplateName, AdditionalParameters) Export
	
	If NewTemplateName = Undefined Then
		Return;
	EndIf;
	
	If DocumentName <> NewTemplateName Then
		Modified = True;
		DocumentName = NewTemplateName;
		SetHeader();
	EndIf;
	
EndProcedure

&AtServer
Function ListOfOperators()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
				
		ModulePrintManager = Common.CommonModule("PrintManagement");
		
		AdditionalFields = New Structure;
		
		DetailsOfAdditionalFields = New Structure("Presentation, Type");
		DetailsOfAdditionalFields.Presentation = NStr("vi = 'Bắt đầu điều kiện';
														|ru = 'Начало условия';
														|en = 'Condition start'; fa = 'Condition start';
														|it = 'Начало условия';
														|pl = 'Condition start';
														|tr = 'Şartların başlangıcı'");
		DetailsOfAdditionalFields.Type = New TypeDescription("Boolean");
		AdditionalFields.Insert("AreaStart", DetailsOfAdditionalFields);
		
		DetailsOfAdditionalFields = New Structure("Presentation, Type");
		DetailsOfAdditionalFields.Presentation = NStr("vi = 'Kết thúc điều kiện';
														|ru = 'Окончание условия';
														|en = 'Condition end'; fa = 'Condition end';
														|it = 'Окончание условия';
														|pl = 'Condition end';
														|tr = 'Şartların bitişi'");
		DetailsOfAdditionalFields.Type = New TypeDescription("Boolean");
		AdditionalFields.Insert("EndOfRegion", DetailsOfAdditionalFields);
		
		
		AdditionalFieldsGroupDetails = New Structure("Presentation, Order, Picture");
		AdditionalFieldsGroupDetails.Insert("Items", AdditionalFields);
		AdditionalFieldsGroupDetails.Presentation = NStr("vi = 'Hiển thị có điều kiện';
														|ru = 'Условный вывод';
														|en = 'Conditional display'; fa = 'Conditional display';
														|it = 'Условный вывод';
														|pl = 'Conditional display';
														|tr = 'Şartlı görüntüleme'");
		AdditionalFieldsGroupDetails.Order = 7;
		
		GroupsOfAdditionalFields = New Structure;
		GroupsOfAdditionalFields.Insert("ConditionalOutput", AdditionalFieldsGroupDetails);
		
		Return ModulePrintManager.ListOfOperators(GroupsOfAdditionalFields);
	EndIf;
	
EndFunction

&AtClient
Function TagNameCondition()
	Return PrintManagementClientServer.TagNameCondition();
EndFunction

#Region PlugInListOfFields

&AtClient
Procedure Attachable_ListOfFieldsBeforeExpanding(Item, String, Cancel)
	
	FormulasConstructorClient.ListOfFieldsBeforeExpanding(ThisObject, Item, String, Cancel);
	
EndProcedure

&AtClient
Procedure Attachable_ExpandTheCurrentFieldListItem()
	
	FormulasConstructorClient.ExpandTheCurrentFieldListItem(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_FillInTheListOfAvailableFields(FillParameters) Export // ACC:78 - Called from FormulaConstructorClient.
	
	FillInTheListOfAvailableFields(FillParameters);
	
EndProcedure

&AtServer
Procedure FillInTheListOfAvailableFields(FillParameters)
	
	FormulasConstructor.FillInTheListOfAvailableFields(ThisObject, FillParameters);

	CurrentData = ThisObject[NameOfTheFieldList()].FindByID(FillParameters.RowID);
	SetExamplesValues(CurrentData);
	SetFormatValuesDefault(CurrentData);
	If (CurrentData.Folder Or CurrentData.Table) And CurrentData.GetParent() = Undefined Then
		MarkCommonFields(CurrentData);
	Else
		SetCommonFIeldFlagForSubordinateFields(CurrentData);
	EndIf;		
	
EndProcedure

&AtClient
Procedure Attachable_ListOfFieldsStartDragging(Item, DragParameters, Perform)
	
	Attribute = ThisObject[NameOfTheFieldList()].FindByID(DragParameters.Value);
	
	If Attribute.Folder Or Attribute.Table 
		And Not StrStartsWith(Attribute.DataPath, "CommonAttributes.") Then
		Perform = False;
		Return;
	EndIf;
	
	DragParameters.Value = "[" + Attribute.RepresentationOfTheDataPath + "]";

	If Item = Items[NameOfTheFieldList()]
		And ValueIsFilled(Attribute.Format) And Attribute.Format <> Attribute.DefaultFormat Then
		
		DragParameters.Value = StringFunctionsClientServer.SubstituteParametersToString(
			"[Format(%1, %2)]", DragParameters.Value, """" + Attribute.Format + """");
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_SearchStringEditTextChange(Item, Text, StandardProcessing)
	
	FormulasConstructorClient.SearchStringEditTextChange(ThisObject, Item, Text, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_PerformASearchInTheListOfFields()
	
	PerformASearchInTheListOfFields();
	
EndProcedure

&AtServer
Procedure PerformASearchInTheListOfFields()
	
	FormulasConstructor.PerformASearchInTheListOfFields(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_SearchStringClearing(Item, StandardProcessing)
	
	FormulasConstructorClient.SearchStringClearing(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtServer
Procedure Attachable_FormulaEditorHandlerServer(Parameter, AdditionalParameters)

	FormulasConstructor.FormulaEditorHandler(ThisObject, Parameter, AdditionalParameters);
	If AdditionalParameters.OperationKey = "HandleSearchMessage" Then
		MarkCommonFields();
		SetFormatValuesDefault();
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_FormulaEditorHandlerClient(Parameter, AdditionalParameters = Undefined) Export  // ACC:78 - The procedure is called from "FormulaConstructorClient.StartSearchInFieldsList".
		
	FormulasConstructorClient.FormulaEditorHandler(ThisObject, Parameter, AdditionalParameters);
	If AdditionalParameters <> Undefined And AdditionalParameters.RunAtServer Then
		Attachable_FormulaEditorHandlerServer(Parameter, AdditionalParameters);
	EndIf;

EndProcedure

&AtClient
Procedure Attachable_StartSearchInFieldsList()

	FormulasConstructorClient.StartSearchInFieldsList(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Function NameOfTheFieldList()
	
	Return "AvailableFields";
	
EndFunction

&AtClientAtServerNoContext
Function NameOfTheListOfOperators()
	
	Return "ListOfOperators";
	
EndFunction

#EndRegion


#Region AdditionalHandlersForConnectedLists

&AtClient
Procedure Attachable_AvailableFieldsWhenLineIsActivated(Item)
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;

	If CurrentData.GetParent() = Undefined Then
		Items["SearchString" + NameOfTheFieldList()].InputHint = PromptInputStringSearchFieldList();
	Else
		Items["SearchString" + NameOfTheFieldList()].InputHint = CurrentData.RepresentationOfTheDataPath;
	EndIf;
	
	PopulateHTMLFIeldByCurrField();
	
EndProcedure

&AtClient
Procedure PopulateHTMLFIeldByCurrField()
	
	Value = GetCurrentRowValue();
	
	SetInHTMLField(Value);
	
EndProcedure

&AtClient
Function GetCurrentRowValue()
	CurrentRow = Items[NameOfTheFieldList()].CurrentRow; 	
	Attribute = ThisObject[NameOfTheFieldList()].FindByID(CurrentRow);
	
	If Attribute.Folder Or Attribute.Table 
		And Not StrStartsWith(Attribute.DataPath, "CommonAttributes.") Then
		Return "";
	EndIf;
	
	Value = "[" + Attribute.RepresentationOfTheDataPath + "]";

	If CurrentItem = Items[NameOfTheFieldList()]
		And ValueIsFilled(Attribute.Format) And Attribute.Format <> Attribute.DefaultFormat Then
		
		Value = StringFunctionsClientServer.SubstituteParametersToString(
			"[Format(%1, %2)]", Value, """" + Attribute.Format + """");
	EndIf;
	
	Return Value;
	
EndFunction

&AtClient
Procedure Attachable_AvailableFieldsBeforeStartOfChange(Item, Cancel)
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	CurrentData.Pattern = CurrentData.Value;
	InputField = Items[NameOfTheFieldList() + "Pattern"];
	SelectedField = FormulasConstructorClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheFieldList());
	InputField.TypeRestriction = SelectedField.Type;
	
EndProcedure

// Parameters:
//  Item - FormTable
//  RowSelected - Number
//  Field - FormField
//  StandardProcessing - Boolean
//
&AtClient
Procedure Attachable_ListOfFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = Item.Name + "Presentation" Then
		StandardProcessing = False;
		SelectedField = FormulasConstructorClient.TheSelectedFieldInTheFieldList(ThisObject);
		If ValueIsFilled(CurrentValue) Then
			CurrentValue = TrimR(CurrentValue) + " ";
		Else
			CurrentValue = "";
		EndIf;
		If Item.Name = NameOfTheFieldList() Then
			CurrentValue = CurrentValue + "[" + SelectedField.RepresentationOfTheDataPath + "]";
		Else
			CurrentValue = CurrentValue + FormulasConstructorClient.ExpressionToInsert(SelectedField);
		EndIf;
	EndIf;
	
	If Field = Items[NameOfTheFieldList() + "ButtonSettingsFormat"] Then
		StandardProcessing = False;
		Designer = New FormatStringWizard(Items[NameOfTheFieldList()].CurrentData.Format);
		Designer.AvailableTypes = Items[NameOfTheFieldList()].CurrentData.Type;
		CallbackDescription = New CallbackDescription("WhenFormatFieldSelection", ThisObject);
		Designer.Show(CallbackDescription);
	EndIf;	
	
EndProcedure

&AtClient
Procedure Attachable_FieldListRowActivation(Item)
	
	Operator = FormulasConstructorClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheListOfOperators());
	
	If ValueIsFilled(Operator.Parent) Then
		OperatorsGroup = Operator.Parent; // See FormulasConstructorClient.TheSelectedFieldInTheFieldList
		OperatorGroupName = OperatorsGroup.Name;
		
		If OperatorGroupName = "ConditionalOutput" Then
			If Operator.Name = "AreaStart" Then
				SetInHTMLField(StrTemplate("{%1 *text conditions*}", TagNameCondition()));
			ElsIf Operator.Name = "EndOfRegion" Then
				SetInHTMLField(StrTemplate("{/%1}", TagNameCondition()));
			EndIf;
			Return;
		EndIf;
	EndIf;
	
	SetInHTMLField(FormulasConstructorClient.ExpressionToInsert(Operator));
	
EndProcedure

&AtClient
Procedure Attachable_OperatorsDragStart(Item, DragParameters, Perform)
	
	Operator = FormulasConstructorClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheListOfOperators());
	
	If ValueIsFilled(Operator.Parent) Then
		OperatorsGroup = Operator.Parent; // See FormulasConstructorClient.TheSelectedFieldInTheFieldList
		OperatorGroupName = OperatorsGroup.Name;
		
		If OperatorGroupName = "ConditionalOutput" Then
			If Operator.Name = "AreaStart" Then
				DragParameters.Value = "{v8 Condition *text conditions*}";
			ElsIf Operator.Name = "EndOfRegion" Then
				DragParameters.Value = "{/v8 Condition}";
			EndIf;
			Return;
		EndIf;
	EndIf;
	
	DragParameters.Value = FormulasConstructorClient.ExpressionToInsert(Operator);
	
	If Operator.DataPath = "PrintControl_NumberofLines" Then
		CurrentTablePresentation = CurrentTablePresentation();
		Perform = CurrentTablePresentation <> Undefined;
		DragParameters.Value = StrReplace(DragParameters.Value, "()", "(["+CurrentTablePresentation+"])");
	EndIf;
	
	If ValueIsFilled(Operator.Parent)
	   And Not IsBlankString(DragParameters.Value)
	   And Not ValueIsFilled(Operator.ExpressionToInsert) Then
		
		OperatorsGroup = Operator.Parent; // See TheSelectedFieldInTheFieldList
		OperatorGroupName = OperatorsGroup.Name;
		If Not OperatorGroupName = "LogicalOperatorsAndConstants" Then
			
			DragParameters.Value = "[" + DragParameters.Value + "]";
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AvailableFieldsAtEndOfEditing(Item, NewRow, CancelEdit)
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	If ValueIsFilled(CurrentData.Format) Then
		CurrentData.Pattern = Format(CurrentData.Value, CurrentData.Format);
	EndIf;

	If CurrentData.DataPath = "Ref" Then
		Pattern = CurrentData.Pattern;
	EndIf;
	AttachIdleHandler("WhenChangingSample", 0.1,  True);
	
EndProcedure

&AtClient
Procedure Attachable_SampleWhenChanging(Item)
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	CurrentData.Value = CurrentData.Pattern;
	
EndProcedure

&AtClient
Procedure WhenChangingSample()

	WhenChangingSampleOnServer();
	
EndProcedure

&AtServer
Procedure WhenChangingSampleOnServer()
	
	SetExamplesValues();
		
EndProcedure

#EndRegion

#EndRegion


&AtClientAtServerNoContext
Function PromptInputStringSearchFieldList()
	
	Return NStr("vi = 'Tìm kiếm trường...';
				|ru = 'Найти поле...';
				|en = 'Find field…'; fa = 'Find field…';
				|it = 'Trovare campo...';
				|pl = 'Znajdź pole...';
				|tr = 'Alan bul...'");
	
EndFunction

&AtServer
Function GetPrintForm()
	
	References = CommonClientServer.ValueInArray(Pattern);
	PrintObjects = New ValueList;
	Template = GetFromTempStorage(TemplateFileAddress);
	PrepareTemplateForSaving(Template);
	PrintParameters = New Structure;
		
	OfficeDocuments = PrintManagement.GenerateOfficeDoc(Template, References, PrintObjects, LanguageCode, PrintParameters);
	If OfficeDocuments.Count() > 0 Then
		For Each OfficeDocument In OfficeDocuments Do
			Return OfficeDocument;
		EndDo;
	Else 
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Function CurrentTablePresentation()
	For Each AttachedFieldList In ThisObject["ConnectedFieldLists"] Do
		If AttachedFieldList.NameOfTheFieldList <> NameOfTheListOfOperators() Then
			If Items[AttachedFieldList.NameOfTheFieldList].CurrentData <> Undefined
				And Items[AttachedFieldList.NameOfTheFieldList].CurrentData.Table Then
					Return Items[AttachedFieldList.NameOfTheFieldList].CurrentData.RepresentationOfTheDataPath;
			EndIf;			
		EndIf;
	EndDo;	
	Return Undefined;
EndFunction

&AtClient
Procedure TemplateAssignmentClick(Item)
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.SelectedMetadataObjects = CommonClient.CopyRecursive(DataSources);
	PickingParameters.ChooseRefs = True;
	PickingParameters.Title = NStr("vi = 'Mục đích khuôn in';
									|ru = 'Назначение макета';
									|en = 'Template assignment'; fa = 'تخصیص الگو';
									|it = 'Назначение макета';
									|pl = 'Template assignment';
									|tr = 'Şablon ataması'");
	PickingParameters.FilterByMetadataObjects = ObjectsWithPrintCommands();
	
	CallbackDescription = New CallbackDescription("OnChooseTemplateOwners", ThisObject);
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, CallbackDescription);

EndProcedure

&AtClient
Procedure OnChooseTemplateOwners(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	DataSources.LoadValues(Result.UnloadValues());
	Items.TextAssignment.Title = PresentationOfDataSource(DataSources);
	UpdateListOfAvailableFields();
	
EndProcedure

&AtClientAtServerNoContext
Function PresentationOfDataSource(DataSources)
	
	Values = New Array;
	For Each Item In DataSources Do
		Values.Add(Item.Value);
	EndDo;
	
	Result = StrConcat(Values, ", ");
	If Not ValueIsFilled(Result) Then
		Result = "<" + NStr("vi = 'chưa chọn';
							|ru = 'не выбрано';
							|en = 'not selected'; fa = 'not selected';
							|it = 'не выбрано';
							|pl = 'not selected';
							|tr = 'seçilmedi'") + ">";
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ObjectsWithPrintCommands()
	
	ObjectsWithPrintCommands = New ValueList;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		For Each MetadataObject In ModulePrintManager.PrintCommandsSources() Do
			ObjectsWithPrintCommands.Add(MetadataObject.FullName());
		EndDo;
	EndIf;

	Return ObjectsWithPrintCommands;
	
EndFunction

&AtServer
Procedure UpdateListOfAvailableFields()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.UpdateListOfAvailableFields(ThisObject, 
			FieldsCollections(DataSources.UnloadValues(), EditParameters()), NameOfTheFieldList());
		
		SetUpFieldSample();
		MarkCommonFields();
		SetFormatValuesDefault();
			
		If DataSources.Count() > 0 Then
			DataSource = DataSources[0].Value;
			MetadataObject = Common.MetadataObjectByID(DataSource);
			PickupSample(MetadataObject);
			SetExamplesValues();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpFieldSample()

	FieldsCollection = ThisObject[NameOfTheFieldList()].GetItems(); // FormDataTreeItemCollection
	Offset = 0;
	For Each FieldDetails In FieldsCollection Do
		If FieldDetails.DataPath = "Ref" Then
			FieldDetails.Title = NStr("vi = 'Mẫu';
										|ru = 'Образец';
										|en = 'Preview'; fa = 'پیش‌نمایش';
										|it = 'Образец';
										|pl = 'Preview';
										|tr = 'Örnek'");
			If Offset <> 0 Then
				IndexOf = FieldsCollection.IndexOf(FieldDetails);
				FieldsCollection.Move(IndexOf, Offset);
			EndIf;
			Break;
		EndIf;
		Offset = Offset - 1;
	EndDo;
	
EndProcedure

&AtServer
Function CommonFieldsOfDataSources()
	
	CommonFieldsOfDataSources = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		CommonFieldsOfDataSources = ModulePrintManager.CommonFieldsOfDataSources(DataSources.UnloadValues());
	EndIf;
	
	Return CommonFieldsOfDataSources;
	
EndFunction

&AtServer
Procedure MarkCommonFields(Val FieldsCollection = Undefined, Val CommonFields = Undefined)
	
	If FieldsCollection = Undefined Then
		FieldsCollection = ThisObject[NameOfTheFieldList()];
	EndIf;
	
	If CommonFields = Undefined Then
		CommonFields = CommonFieldsOfDataSources();
	EndIf;
	
	For Each FieldDetails In FieldsCollection.GetItems() Do
		If FieldDetails.Folder And FieldDetails.Field = New DataCompositionField("CommonAttributes")
			Or FieldDetails.GetParent() <> Undefined And FieldDetails.GetParent().Field = New DataCompositionField("CommonAttributes") Then
			FieldDetails.Common = True;
			SetCommonFIeldFlagForSubordinateFields(FieldDetails);
			Continue;
		EndIf;
		
		If CommonFields.Find(FieldDetails.Field) <> Undefined Then
			FieldDetails.Common = True;
			If Not FieldDetails.Folder And Not FieldDetails.Table Then
				SetCommonFIeldFlagForSubordinateFields(FieldDetails);
			EndIf;
		EndIf;
		If FieldDetails.Common And (FieldDetails.Folder Or FieldDetails.Table) Then
			MarkCommonFields(FieldDetails, CommonFields);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetCommonFIeldFlagForSubordinateFields(FieldsCollection)
	
	For Each FieldDetails In FieldsCollection.GetItems() Do
		FieldDetails.Common = FieldsCollection.Common;
		SetCommonFIeldFlagForSubordinateFields(FieldDetails);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetUpCommandPresentation()
	
	Items.WriteAndClose.Visible = Not EditingDenied;
	Items.Close.Visible = EditingDenied;
	Items.Write.Enabled = Not EditingDenied;
	Items.Translate.Enabled = Not EditingDenied;
	Items.TranslateAllActions.Enabled = Items.Translate.Enabled;
	Items.Rename.Enabled = Not EditingDenied;
	Items.DeleteLayoutLanguage.Enabled = Not EditingDenied;
	Items.LoadFromFile.Enabled = Not EditingDenied;
	SetAvailabilityRecursively(Items.LangsToAdd, Not EditingDenied);
	
EndProcedure

&AtClient
Procedure SetAvailabilityRecursively(Item, Var_Enabled = Undefined)
	If Var_Enabled = Undefined Then
		Var_Enabled = Item.Enabled;
	EndIf;
	
	For Each SubordinateItem In Item.ChildItems Do
		If TypeOf(SubordinateItem) = Type("FormButton") And SubordinateItem.CommandName <> "" Then
			SubordinateItem.Enabled = Var_Enabled;
		EndIf;
		
		If TypeOf(SubordinateItem) = Type("FormGroup") Then
			SetAvailabilityRecursively(SubordinateItem, Var_Enabled);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function EditParameters()
	Result = New Structure;
	Result.Insert("KeyOfEditObject", KeyOfEditObject);
	Result.Insert("UUID", UUID);
	Return Result;
EndFunction

#EndRegion



