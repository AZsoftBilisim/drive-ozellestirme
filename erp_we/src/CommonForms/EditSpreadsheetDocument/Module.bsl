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
Var RecipientOfDraggedValue, WaitHanderParametersAddress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Common.IsMobileClient() Then
		Raise NStr("vi = 'Không thể chỉnh sửa văn bản dạng bảng trong mobile-client.
		|Hãy sử dụng thin client hoặc web-client.';
		|ru = 'Редактирование табличного документа недоступно в мобильном клиенте.
		|Используйте тонкий клиент или веб-клиент.';
		|en = 'Cannot edit a spreadsheet document in mobile client.
		|Use thin client or web client.'; fa = 'Cannot edit a spreadsheet document in mobile client.
		|Use thin client or web client.';
		|it = 'Modifica del documento tabellare non disponibile su client mobile.
		|Utilizzare thin client o web client.';
		|pl = 'Edycja dokumentu tabelarycznego jest niedostępna w kliencie mobilnym.
		|Używaj cienkiego klienta lub klienta webowego.';
		|tr = 'Mobil istemcide tablo belge düzenlenemez.
		|İnce istemciyi ya da web-istemcisini kullanın.'");
	EndIf;
	
	If Parameters.WindowOpeningMode <> Undefined Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;

	SpreadsheetDocument.LanguageCode = Common.DefaultLanguageCode();
	
	IdentifierOfTemplate = Parameters.TemplateMetadataObjectName;
	RefTemplate = Parameters.Ref;
	If ValueIsFilled(RefTemplate) Then
		KeyOfEditObject  = RefTemplate;
		LockDataForEdit(KeyOfEditObject,, UUID);
	ElsIf ValueIsFilled(IdentifierOfTemplate) Then
		If Common.SubsystemExists("StandardSubsystems.Print") Then
			ModulePrintManager = Common.CommonModule("PrintManagement");
			KeyOfEditObject = ModulePrintManager.GetTemplateRecordKey(IdentifierOfTemplate);
			If KeyOfEditObject <> Undefined Then
				LockDataForEdit(KeyOfEditObject,, UUID);
			EndIf;
		EndIf;
	EndIf;
	
	IsPrintForm = Parameters.IsPrintForm;
	IsTemplate = Not IsBlankString(IdentifierOfTemplate) Or IsPrintForm;
	SpreadsheetDocument.Template = IsTemplate;
	
	Items.ButtonShowHideOriginal.Visible = IsTemplate;
	Items.ButtonShowHideOriginalAllActions.Visible = IsTemplate;
	Items.DeleteStampEP.Visible = IsTemplate;
	
	TemplateForObjectExport = Parameters.TemplateForObjectExport;
	ExportSaveFormat = Parameters.ExportSaveFormat;
	If TemplateForObjectExport
	   And Not ValueIsFilled(ExportSaveFormat) Then
		
		ExportSaveFormat = Enums.ObjectsExportFormats.XLSX;
		
	EndIf;
	
	Items.ExportSaveFormat.Visible = TemplateForObjectExport;
	Items.TextAssignment.Enabled = Not TemplateForObjectExport;
	Items.AssignmentTitle.Enabled = Not TemplateForObjectExport;
	
	ExportFormatsWithAreas = ExportFormatsRequiringAreas();
	OutputAreaNameCommands =
		(TemplateForObjectExport
		 And ExportFormatsWithAreas.Find(ExportSaveFormat) <> Undefined);
	Items.SetName.Visible = OutputAreaNameCommands;
	Items.RemoveName.Visible = OutputAreaNameCommands;
	
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
	
	DocumentName = Parameters.DocumentName;
	DefaultPrintForm = Parameters.DefaultPrintForm;
	PrintFormDescription = Parameters.PrintFormDescription;
	
	Items.ChangeTemplateSettings.Visible = ValueIsFilled(Parameters.Ref) 
		Or IsBlankString(IdentifierOfTemplate) And IsBlankString(Parameters.PathToFile);
	
	Items.DeleteLayoutLanguage.Visible = Not ValueIsFilled(Parameters.Ref) And IsBlankString(Parameters.PathToFile);

	If Parameters.SpreadsheetDocument = Undefined Then
		If Not IsBlankString(IdentifierOfTemplate) Then
			EditingDenied = Not Parameters.Edit;
			LoadSpreadsheetDocumentFromMetadata(Parameters.LanguageCode);
			If Parameters.Copy Then
				IDOfTemplateBeingCopied = IdentifierOfTemplate;
				IdentifierOfTemplate = "";
			EndIf;
		EndIf;
	ElsIf TypeOf(Parameters.SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		FillSpreadsheetDocument(SpreadsheetDocument, Parameters.SpreadsheetDocument);
	Else
		SpreadsheetDocument.LanguageCode = Undefined;
		BinaryData = GetFromTempStorage(Parameters.SpreadsheetDocument); // BinaryData
		TempFileName = GetTempFileName("mxl");
		BinaryData.Write(TempFileName);
		SpreadsheetDocument.Read(TempFileName);
		DeleteFiles(TempFileName);
	EndIf;
	
	Items.SpreadsheetDocument.Edit = Parameters.Edit;
	Items.SpreadsheetDocument.ShowGroups = True;
	Items.SpreadsheetDocument.ShowRowAndColumnNames = SpreadsheetDocument.Template;
	Items.SpreadsheetDocument.ShowCellNames = SpreadsheetDocument.Template;
	
	Items.Warning.Visible = IsTemplate And Not IsPrintForm And Parameters.Edit;
	Items.EditInExternalApplication.Visible = Common.IsWebClient() 
		And Not IsBlankString(IdentifierOfTemplate) And Common.SubsystemExists("StandardSubsystems.Print");
	
	AvailableTranslationLayout = False;
	If IsTemplate Then
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
			PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
			AvailableTranslationLayout = PrintManagementModuleNationalLanguageSupport.AvailableTranslationLayout(IdentifierOfTemplate);
			If IsPrintForm Or PrintManagementModuleNationalLanguageSupport.AvailableTranslationLayout(IdentifierOfTemplate) Then
				PrintManagementModuleNationalLanguageSupport.FillInTheLanguageSubmenu(ThisObject, Parameters.LanguageCode);
				AutomaticTranslationAvailable = PrintManagementModuleNationalLanguageSupport.AutomaticTranslationAvailable(CurrentLanguage);
			EndIf;
		EndIf;
	EndIf;
	
	Items.Language.Enabled = (IsPrintForm Or AvailableTranslationLayout) And ValueIsFilled(IdentifierOfTemplate);
	Items.LanguageAllActions.Enabled = Items.Language.Enabled;
	
	Items.Translate.Visible = AutomaticTranslationAvailable;
	Items.TranslateAllActions.Visible = Items.Translate.Visible;
	
	If Common.IsMobileClient() Then
		CommonClientServer.SetFormItemProperty(Items, "CommandBar", "Visible", False);
		CommonClientServer.SetFormItemProperty(Items, "Warning", "Visible", False);
	EndIf;
	
	If IsPrintForm And Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormula = Common.CommonModule("FormulasConstructor");
		
		DataSource = Parameters.DataSource;
		If Not ValueIsFilled(Parameters.DataSource) Then
			DataSource = DataSources[0].Value;
		EndIf;

		MetadataObject = Common.MetadataObjectByID(DataSource);
		PickupSample(MetadataObject);
		
		Items.Edit.Visible = False;
		FieldSelectionBackColor = StyleColors.NavigationColor;
		
		Items.TextToCopy.Visible = Common.IsWebClient();
		
		AddingOptions = ModuleConstructorFormula.ParametersForAddingAListOfFields();
		AddingOptions.ListName = NameOfTheFieldList();
		AddingOptions.LocationOfTheList = Items.AvailableFieldsGroup;
		AddingOptions.FieldsCollections = FieldsCollections(DataSources.UnloadValues(), EditParameters());
		AddingOptions.HintForEnteringTheSearchString = PromptInputStringSearchFieldList();
		AddingOptions.WhenDefiningAvailableFieldSources = "PrintManagement";
		AddingOptions.ListHandlers.Insert("Selection", "Attachable_ListOfFieldsSelection");
		AddingOptions.ListHandlers.Insert("BeforeRowChange", "Attachable_AvailableFieldsBeforeStartOfChange");
		AddingOptions.ListHandlers.Insert("OnEditEnd", "Attachable_AvailableFieldsAtEndOfEditing");
		AddingOptions.UseBackgroundSearch = True;
		
		ModuleConstructorFormula.AddAListOfFieldsToTheForm(ThisObject, AddingOptions);
				
		AddingOptions = ModuleConstructorFormula.ParametersForAddingAListOfFields();
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
		AddingOptions.ListHandlers.Insert("DragStart", "Attachable_OperatorsDragStart");
		AddingOptions.ListHandlers.Insert("DragEnd", "Attachable_OperatorsDragEnd");
		
		ModuleConstructorFormula.AddAListOfFieldsToTheForm(ThisObject, AddingOptions);
		
		FillSpreadsheetDocument(SpreadsheetDocument, ReadLayout());
		ReadTextInFooterField(SpreadsheetDocument.Header.LeftText, TopLeftText);
		ReadTextInFooterField(SpreadsheetDocument.Header.CenterText, TopMiddleText);
		ReadTextInFooterField(SpreadsheetDocument.Header.RightText, TopRightText);
		ReadTextInFooterField(SpreadsheetDocument.Footer.LeftText, BottomLeftText);
		ReadTextInFooterField(SpreadsheetDocument.Footer.CenterText, BottomCenterText);
		ReadTextInFooterField(SpreadsheetDocument.Footer.RightText, BottomRightText);
	
		ExpandFieldList();
		
		SpreadsheetDocument.Template = True;
		
		If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
			ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
			AttachedFilesTypes = ModuleFilesOperationsInternal.AttachedFilesTypes();
		EndIf;
	EndIf;
	
	If Not IsPrintForm Then
		Items.ShowHeadersAndFooters.Visible = False;
		Items.SettingsCurrentRegion.Visible = False;
		Items.ButtonAvailableFields.Visible = False;
		Items.ViewPrintableForm.Visible = False;
		Items.RepeatAtTopofPage.Visible = False;
		Items.RepeatAtEndPage.Visible = False;
	EndIf;
	
	TextControlButtonVisibility(ThisObject);
	
	Items.Header.Visible = False;
	Items.Footer.Visible = False;

	Items.GroupTemplateAssignment.Visible = IsPrintForm;
	Items.GroupTemplateAssignment.Enabled = Parameters.IsValAvailable;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(Parameters.PathToFile) Then
		File = New File(Parameters.PathToFile);
		If IsBlankString(DocumentName) Then
			DocumentName = File.BaseName;
		EndIf;
		File.BeginGettingReadOnly(New CallbackDescription("OnCompleteGetReadOnly", ThisObject));
		Return;
	EndIf;
	
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.ViewPrintableForm.Check Then
		Cancel = True;
		ViewPrintableForm(Undefined);
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ConfirmAndClose", ThisObject);
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lưu lại thay đổi vào %1?';
																				|ru = 'Сохранить изменения в %1?';
																				|en = 'Do you want to save the changes you made to %1?'; fa = 'Do you want to save the changes you made to %1?';
																				|it = 'Salvare le modifiche in %1?';
																				|pl = 'Zapisać zmiany do %1?';
																				|tr = '%1'' de değişiklikleri kaydetmek istiyor musunuz?'"), DocumentName);
	CommonClient.ShowFormClosingConfirmation(CallbackDescription, Cancel, Exit, QueryText);
	
	If Modified Or Exit Then
		Return;
	EndIf;
	
	If Not IsNew() Then
		NotifyAboutTheTableDocumentEntry();
	EndIf;
	
	If  Not Cancel And Not Exit And ValueIsFilled(KeyOfEditObject) Then
		UnlockAtServer(); 
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	CallbackDescription = New CallbackDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(CallbackDescription);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "SpreadsheetDocumentsToEditNameRequest" And Source <> ThisObject Then
		DocumentNames = Parameter; // Array -
		DocumentNames.Add(DocumentName);
	ElsIf EventName = "OwnerFormClosing" And Source = FormOwner Then
		Close();
		If IsOpen() Then
			Parameter.Cancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentOnActivate(Item)
	UpdateCommandBarButtonMarks();
	SynchronizeTheLayoutViewport();
	AttachIdleHandler("ClearHighlight", 0.1, True);
	AttachIdleHandler("UpdateAreaSettingsSelectedCells", 0.1, True);
EndProcedure

&AtClient
Procedure SuppliedTemplateOnActivate(Item)
	
	SynchronizeTheLayoutViewport();
	
EndProcedure

&AtClient
Procedure TemplateOwnersClick(Item)
	
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
Procedure ExportSaveFormatOnChange(Item)
	
	ExportFormatsWithAreas = ExportFormatsRequiringAreas();
	OutputAreaNameCommands = 
		(TemplateForObjectExport And ExportFormatsWithAreas.Find(ExportSaveFormat) <> Undefined);
	Items.SetName.Visible = OutputAreaNameCommands;
	Items.RemoveName.Visible = OutputAreaNameCommands;
	TextControlButtonVisibility(ThisObject);
	Modified = True;
	
EndProcedure

&AtClient
Procedure ExportSaveFormatClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Actions with the document

&AtClient
Procedure WriteAndClose(Command)
	CallbackDescription = New CallbackDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(CallbackDescription, True);
EndProcedure

&AtClient
Procedure Write(Command)
	WriteSpreadsheetDocument();
	NotifyAboutTheTableDocumentEntry();
EndProcedure

&AtClient
Procedure Edit(Command)
	Items.SpreadsheetDocument.Edit = Not Items.SpreadsheetDocument.Edit;
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
EndProcedure

&AtClient
Procedure EditInExternalApplication(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		OpeningParameters = New Structure;
		OpeningParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
		OpeningParameters.Insert("TemplateMetadataObjectName", IdentifierOfTemplate);
		OpeningParameters.Insert("IdentifierOfTemplate", IdentifierOfTemplate);
		OpeningParameters.Insert("TemplateType", "MXL");
		CallbackDescription = New CallbackDescription("EditInExternalApplicationCompletion", ThisObject);
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.EditTemplateInExternalApplication(CallbackDescription, OpeningParameters, ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure SaveToFile(Command)
	
	ClearHighlight();
	
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.FullFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(DocumentName);
	FileDialog.Filter = NStr("vi = 'Văn bản dạng bảng';
							|ru = 'Табличный документ';
							|en = 'Spreadsheet document'; fa = 'سند صفحه‌گسترده';
							|it = 'Foglio elettronico';
							|pl = 'Dokument tabelaryczny';
							|tr = 'E-tablo belgesi'") + " (*.mxl)|*.mxl";
	
	CallbackDescription = New CallbackDescription("ContinueSavingToFile", ThisObject);
	FileSystemClient.ShowSelectionDialog(CallbackDescription, FileDialog);	
	
EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Filter = NStr("vi = 'Văn bản dạng bảng';
							|ru = 'Табличный документ';
							|en = 'Spreadsheet document'; fa = 'سند صفحه‌گسترده';
							|it = 'Foglio elettronico';
							|pl = 'Dokument tabelaryczny';
							|tr = 'E-tablo belgesi'") + " (*.mxl)|*.mxl";
	FileDialog.Multiselect = False;
	
	CallbackDescription = New CallbackDescription("ContinueDownloadFromFile", ThisObject);
	FileSystemClient.ShowSelectionDialog(CallbackDescription, FileDialog);	
	
EndProcedure

&AtClient
Procedure ChangeFont(Command)
	
	If Items.SpreadsheetDocument.CurrentArea = Undefined Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ChangeFontContinued", ThisObject);
	OpenForm("CommonForm.FontChoiceForm",, ThisObject,,,, CallbackDescription);
	
EndProcedure

// Formatting

&AtClient
Procedure IncreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size + IncreaseFontSizeChangeStep(Size);
		Area.Font = New Font(Area.Font,,Size); // ACC:1345 - Don't apply styles.
	EndDo;
	
EndProcedure

&AtClient
Procedure DecreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size - DecreaseFontSizeChangeStep(Size);
		If Size < 1 Then
			Size = 1;
		EndIf;
		Area.Font = New Font(Area.Font,,Size); // ACC:1345 - Don't apply styles.
	EndDo;
	
EndProcedure

&AtClient
Procedure Strikeout(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Strikeout = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,,,ValueToSet); // ACC:1345 - Don't apply styles.
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
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
	Buttons.Add(DialogReturnCode.No, NStr("vi = 'Chưa thực hiện';
											|ru = 'Не выполнять';
											|en = 'Do not translate'; fa = 'ترجمه نشود';
											|it = 'Non tradurre';
											|pl = 'Nie wykonuj';
											|tr = 'Yapılmasın'"));
	
	CallbackDescription = New CallbackDescription("WhenAnsweringAQuestionAboutTranslatingALayout", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, Buttons);
	
EndProcedure

&AtClient
Procedure TopLeftTextOnChange(Item)
	
	SpreadsheetDocument.Header.LeftText = TopLeftText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Header);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure TopMiddleTextOnChange(Item)
	
	SpreadsheetDocument.Header.CenterText = TopMiddleText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Header);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure TopRightTextOnChange(Item)
	
	SpreadsheetDocument.Header.RightText = TopRightText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Header);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure BottomLeftTextOnChange(Item)
	
	SpreadsheetDocument.Footer.LeftText = BottomLeftText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Footer);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure BottomCenterTextOnChange(Item)
	
	SpreadsheetDocument.Footer.CenterText = BottomCenterText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Footer);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure BottomRightTextOnChange(Item)
	
	SpreadsheetDocument.Footer.RightText = BottomRightText.GetFormattedString();
	SetHeaderAndFooterOutput(SpreadsheetDocument.Footer);
	Modified = True;
	RecipientOfDraggedValue = Item;
	
EndProcedure

&AtClient
Procedure AlignTop(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.VerticalAlign = VerticalAlign.Top;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignMiddle(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.VerticalAlign = VerticalAlign.Center;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignBottom(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.VerticalAlign = VerticalAlign.Bottom;
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure ChangeTemplateSettings(Command)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TemplateDescr", DocumentName);
	ParametersStructure.Insert("IdentifierOfTemplate", IdentifierOfTemplate);
	ParametersStructure.Insert("LanguageCode", CurrentLanguage);
	ParametersStructure.Insert("LayoutOwner", Pattern);
	
	OnChangeTemplateSettings(ParametersStructure);
	
EndProcedure

&AtClient
Procedure ChangeBorderColor(Command)
	
	CallbackDescription = New CallbackDescription("ChangeBorderColorCompletion", ThisObject);
	OpenForm("CommonForm.ColorChoiceForm",, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ChangeTextColor(Command)
	
	CallbackDescription = New CallbackDescription("ChangeTextColorCompletion", ThisObject);
	OpenForm("CommonForm.ColorChoiceForm",, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ChangeBackgroundColor(Command)
	
	CallbackDescription = New CallbackDescription("ChangeBackgroundColorCompletion", ThisObject);
	OpenForm("CommonForm.ColorChoiceForm",, ThisObject,,,, CallbackDescription);

EndProcedure

&AtClient
Procedure AlignmentAuto(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto;
	EndDo;
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignmentFill(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Block;
	EndDo;
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignmentClip(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut;
	EndDo;
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure AlignmentWrap(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap;
	EndDo;
	UpdateCommandBarButtonMarks();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure LoadSpreadsheetDocumentFromMetadata(Val LanguageCode = Undefined)
	
	TranslationRequired = False;
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		PrintFormTemplate = ModulePrintManager.PrintFormTemplate(IdentifierOfTemplate, LanguageCode);
		FillSpreadsheetDocument(SpreadsheetDocument, PrintFormTemplate);
		If Not ValueIsFilled(RefTemplate) Then
			SuppliedTemplate = ModulePrintManager.SuppliedTemplate(IdentifierOfTemplate, LanguageCode);
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
	EndIf;
	
EndProcedure

&AtClient
Procedure SetHeaderAndFooterOutput(HeaderOrFooter)
	HeaderOrFooter.Enabled = Not IsBlankString(HeaderOrFooter.LeftText) Or Not IsBlankString(HeaderOrFooter.RightText) Or Not IsBlankString(HeaderOrFooter.CenterText);
	HeaderOrFooter.StartPage = 1;	
EndProcedure

&AtClient
Procedure SetUpSpreadsheetDocumentRepresentation()
	Items.SpreadsheetDocument.ShowHeaders = Items.SpreadsheetDocument.Edit;
	Items.SpreadsheetDocument.ShowGrid = Items.SpreadsheetDocument.Edit;
EndProcedure

&AtClient
Procedure UpdateCommandBarButtonMarks();
	
#If Not WebClient And Not MobileClient Then
	Area = Items.SpreadsheetDocument.CurrentArea;
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	// Font.
	Font = Area.Font;
	Items.SpreadsheetDocumentBold.Check = Font <> Undefined And Font.Bold = True;
	Items.SpreadsheetDocumentItalic.Check = Font <> Undefined And Font.Italic = True;
	Items.SpreadsheetDocumentUnderline.Check = Font <> Undefined And Font.Underline = True;
	
	Items.SpreadsheetUnderlineAllActions.Check = Items.SpreadsheetDocumentBold.Check;
	Items.SpreadsheetItalicAllActions.Check = Items.SpreadsheetDocumentItalic.Check;
	Items.SpreadsheetUnderlineAllActions.Check = Items.SpreadsheetDocumentUnderline.Check;
	Items.StrikethroughAllActions.Check = Font <> Undefined And Font.Strikeout = True;
	
	// Horizontal orientation.
	Items.SpreadsheetDocumentAlignLeft.Check = Area.HorizontalAlign = HorizontalAlign.Left;
	Items.SpreadsheetDocumentAlignCenter.Check = Area.HorizontalAlign = HorizontalAlign.Center;
	Items.SpreadsheetDocumentAlignRight.Check = Area.HorizontalAlign = HorizontalAlign.Right;
	Items.SpreadsheetDocumentJustify.Check = Area.HorizontalAlign = HorizontalAlign.Justify;
	
	Items.SpreadsheetAlignLeftAllActions.Check = Items.SpreadsheetDocumentAlignLeft.Check;
	Items.SpreadsheetDocAlignCenterAllActions.Check = Items.SpreadsheetDocumentAlignCenter.Check;
	Items.SpreadsheetAlignRightAllActions.Check = Items.SpreadsheetDocumentAlignRight.Check;
	Items.SpreadsheetJustifyAllActions.Check = Items.SpreadsheetDocumentJustify.Check;
	
	// Vertical orientation.
	Items.AlignTop.Check = Area.VerticalAlign = VerticalAlign.Top;
	Items.AlignMiddle.Check = Area.VerticalAlign = VerticalAlign.Center;
	Items.AlignBottom.Check = Area.VerticalAlign = VerticalAlign.Bottom;
	
	Items.AlignTopAllActions.Check = Items.AlignTop.Check;
	Items.AlignMiddleAllActions.Check = Items.AlignMiddle.Check;
	Items.AlignBottomAllActions.Check = Items.AlignBottom.Check;
	
	// Location
	Items.AlignmentAuto.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto);
	Items.AlignmentWrap.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap);
	Items.AlignmentFill.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Block);
	Items.AlignmentClip.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut);
	
	Items.AlignmentAutoMore.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto);
	Items.AlignmentWrapMore.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Wrap);
	Items.AlignmentFillMore.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Block);
	Items.AlignmentClipMore.Check = (Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Cut);
	
#EndIf
	
EndProcedure

&AtClient
Function IncreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return 10;
	EndIf;
	
	If Size < 10 Then
		Return 1;
	ElsIf 10 <= Size And  Size < 20 Then
		Return 2;
	ElsIf 20 <= Size And  Size < 48 Then
		Return 4;
	ElsIf 48 <= Size And  Size < 72 Then
		Return 6;
	ElsIf 72 <= Size And  Size < 96 Then
		Return 8;
	Else
		Return Round(Size / 10);
	EndIf;
EndFunction

&AtClient
Function DecreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return -8;
	EndIf;
	
	If Size <= 11 Then
		Return 1;
	ElsIf 11 < Size And Size <= 23 Then
		Return 2;
	ElsIf 23 < Size And Size <= 53 Then
		Return 4;
	ElsIf 53 < Size And Size <= 79 Then
		Return 6;
	ElsIf 79 < Size And Size <= 105 Then
		Return 8;
	Else
		Return Round(Size / 11);
	EndIf;
EndFunction

// Returns:
//   Array of SpreadsheetDocumentRange
//
&AtClient
Function AreaListForChangingFont()
	
	Result = New Array;
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		If AreaToProcess.Font <> Undefined Then
			Result.Add(AreaToProcess);
			Continue;
		EndIf;
		
		AreaToProcessTop = AreaToProcess.Top;
		AreaToProcessBottom = AreaToProcess.Bottom;
		AreaToProcessLeft = AreaToProcess.Left;
		AreaToProcessRight = AreaToProcess.Right;
		
		If AreaToProcessTop = 0 Then
			AreaToProcessTop = 1;
		EndIf;
		
		If AreaToProcessBottom = 0 Then
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		If AreaToProcessLeft = 0 Then
			AreaToProcessLeft = 1;
		EndIf;
		
		If AreaToProcessRight = 0 Then
			AreaToProcessRight = SpreadsheetDocument.TableWidth;
		EndIf;
		
		If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			AreaToProcessTop = AreaToProcess.Bottom;
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
			
		For ColumnNumber = AreaToProcessLeft To AreaToProcessRight Do
			ColumnWidth = Undefined;
			For LineNumber = AreaToProcessTop To AreaToProcessBottom Do
				Cell = SpreadsheetDocument.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
				If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
					If ColumnWidth = Undefined Then
						ColumnWidth = Cell.ColumnWidth;
					EndIf;
					If Cell.ColumnWidth <> ColumnWidth Then
						Continue;
					EndIf;
				EndIf;
				If Cell.Font <> Undefined Then
					Result.Add(Cell);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure CloseFormAfterWriteSpreadsheetDocument(Close, AdditionalParameters) Export
	If Close Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure WriteSpreadsheetDocument(CompletionHandler = Undefined, UnlockFile = False)

	ClearHighlight();
	
	If TemplateForObjectExport Then
		
		If Not ValueIsFilled(ExportSaveFormat) Then
			
			MessageText = NStr("vi = 'Chưa điền trường ""Định dạng lưu""';
								|ru = 'Поле ""Формат сохранения"" не заполнено';
								|en = 'Format is required'; fa = 'Format is required';
								|it = 'Format is required';
								|pl = 'Format is required';
								|tr = '""Kaydetme formatı"" alanı doldurulmamış'");
			CommonClient.MessageToUser(MessageText,, "ExportSaveFormat");
			Return;
			
		Else
			
			CheckForUnusedProperties(CompletionHandler, UnlockFile);
			
		EndIf;
		
	Else
	
		ThereIsARef = ValueIsFilled(Parameters.Ref);
		If IsNew() And Not IsTemplate And Not ThereIsARef Or EditingDenied Then
			StartFileSavingDialog(CompletionHandler, UnlockFile);
			Return;
		EndIf;
			
		WriteSpreadsheetDocumentFileNameSelected(CompletionHandler, UnlockFile);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteSpreadsheetDocumentFileNameSelected(Val CompletionHandler, UnlockFile)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	AdditionalParameters.Insert("UnlockFile", UnlockFile);
	
	If IsBlankString(Parameters.PathToFile) Then
		TemplateAddressInTempStorage = "";
		AdditionalParameters.Insert("TemplateAddressInTempStorage", TemplateAddressInTempStorage);
		ClearMessages();
		
		If WriteTemplate(True, AdditionalParameters.TemplateAddressInTempStorage) Then
			AfterWriteSpreadsheetDocument(AdditionalParameters.CompletionHandler, UnlockFile);
		Else
			
			If Not TemplateForObjectExport Then
				
				CallbackDescription = New CallbackDescription(
					"ContinueWritingTabularDocument",
					ThisObject,
					AdditionalParameters);
				QueryText = NStr("vi = 'Đã điền sai khuôn in. Tiếp tục ghi?';
								|ru = 'Макет заполнен некорректно. Продолжить запись?';
								|en = 'Some entries are invalid. Save the template anyway?'; fa = 'Some entries are invalid. Save the template anyway?';
								|it = 'Макет заполнен некорректно. Продолжить запись?';
								|pl = 'Some entries are invalid. Save the template anyway?';
								|tr = 'Şablon yanlış doldurulmuştur. Kayda devam etmek istiyor musunuz?'");
				ShowQueryBox(
					CallbackDescription,
					QueryText,
					QuestionDialogMode.YesNo,
					,
					DialogReturnCode.No);
				
			EndIf;
			
		EndIf;
	Else
		SpreadsheetDocument.BeginWriting(
			New CallbackDescription("ProcessSpreadsheetDocumentWritingResult", ThisObject, AdditionalParameters),
			Parameters.PathToFile);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueWritingTabularDocument(DialogResult, AdditionalParameters) Export
	
	If DialogResult = DialogReturnCode.Yes Then
		WriteTemplate(False, AdditionalParameters.TemplateAddressInTempStorage);
		AfterWriteSpreadsheetDocument(AdditionalParameters.CompletionHandler, AdditionalParameters.UnlockFile);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSpreadsheetDocumentWritingResult(Result, AdditionalParameters) Export 
	If Result <> True Then 
		Return;
	EndIf;
	
	EditingDenied = False;
	AfterWriteSpreadsheetDocument(AdditionalParameters.CompletionHandler, AdditionalParameters.UnlockFile);
EndProcedure

&AtClient
Procedure AfterWriteSpreadsheetDocument(CompletionHandler, UnlockFile)
	WritingCompleted = True;
	Modified = False;
	SetHeader();
	TemplateSavedLangs.Add(CurrentLanguage);
	
	If Parameters.DefaultPrintForm <> DefaultPrintForm Then
		RefreshReusableValues();
		Parameters.DefaultPrintForm = DefaultPrintForm
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		If ValueIsFilled(Parameters.AttachedFile) Then
			ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
			If UnlockFile Then
				FileUpdateParameters = ModuleFilesOperationsInternalClient.FileUpdateParameters(
					CompletionHandler, Parameters.AttachedFile, UUID);
				ModuleFilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
			Else
				ModuleFilesOperationsInternalClient.SaveFileChangesWithNotification(CompletionHandler, 
					Parameters.AttachedFile, UUID);
			EndIf;
			Return;
		EndIf;
	EndIf;
	
	RunCallback(CompletionHandler, True);
EndProcedure

&AtClient
Procedure StartFileSavingDialog(Val CompletionHandler, UnlockFile)
	
	Var SaveFileDialog, CallbackDescription;
	
	SaveFileDialog = New FileDialog(FileDialogMode.Save);
	SaveFileDialog.FullFileName = CommonClientServer.ReplaceProhibitedCharsInFileName(DocumentName);
	SaveFileDialog.Filter = NStr("vi = 'Văn bản dạng bảng';
								|ru = 'Табличный документ';
								|en = 'Spreadsheet documents'; fa = 'اسناد صفحه‌گسترده';
								|it = 'Foglio elettronico';
								|pl = 'Dokument tabelaryczny';
								|tr = 'E-tablo belgesi'") + " (*.mxl)|*.mxl";
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	AdditionalParameters.Insert("UnlockFile", UnlockFile);
		
	CallbackDescription = New CallbackDescription("OnCompleteFileSelectionDialog", ThisObject, AdditionalParameters);
	FileSystemClient.ShowSelectionDialog(CallbackDescription, SaveFileDialog);
	
EndProcedure

&AtClient
Procedure OnCompleteFileSelectionDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullFileName = SelectedFiles[0];
	
	Parameters.PathToFile = FullFileName;
	DocumentName = Mid(FullFileName, StrLen(FileDetails(FullFileName).Path) + 1);
	If Lower(Right(DocumentName, 4)) = ".mxl" Then
		DocumentName = Left(DocumentName, StrLen(DocumentName) - 4);
	EndIf;
	
	WriteSpreadsheetDocumentFileNameSelected(AdditionalParameters.CompletionHandler, AdditionalParameters.UnlockFile);
	
EndProcedure

&AtClient
Function FileDetails(FullName)
	
	SeparatorPosition = StrFind(FullName, GetPathSeparator(), SearchDirection.FromEnd);
	
	Name = Mid(FullName, SeparatorPosition + 1);
	Path = Left(FullName, SeparatorPosition);
	
	ExtensionPosition = StrFind(Name, ".", SearchDirection.FromEnd);
	
	BaseName = Left(Name, ExtensionPosition - 1);
	Extension = Mid(Name, ExtensionPosition + 1);
	
	Result = New Structure;
	Result.Insert("FullName", FullName);
	Result.Insert("Name", Name);
	Result.Insert("Path", Path);
	Result.Insert("BaseName", BaseName);
	Result.Insert("Extension", Extension);
	
	Return Result;
	
EndFunction
	
&AtClient
Function NewDocumentName()
	Return NStr("vi = 'Mới';
				|ru = 'Новый';
				|en = 'New'; fa = 'جدید';
				|it = 'Nuovo';
				|pl = 'New';
				|tr = 'Yeni'");
EndFunction

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
									|it = 'creazione';
									|pl = 'tworzenie';
									|tr = 'oluştur'") + ")";
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
Procedure SetUpCommandPresentation()
	
	DocumentIsBeingEdited = Items.SpreadsheetDocument.Edit;
	Items.Edit.Check = DocumentIsBeingEdited;
	Items.EditingCommands.Enabled = DocumentIsBeingEdited;
	Items.WriteAndClose.Enabled = DocumentIsBeingEdited Or Modified;
	Items.Write.Enabled = DocumentIsBeingEdited Or Modified;

	If DocumentIsBeingEdited And IsTemplate And Not IsPrintForm Then
		Items.Warning.Visible = True;
	EndIf;
	
	Items.Edit.Enabled = DocumentIsBeingEdited Or Not IsTemplate;
	Items.LoadFromFile.Enabled = DocumentIsBeingEdited Or Not IsTemplate;
	Items.StrikethroughAllActions.Enabled = DocumentIsBeingEdited Or Not IsTemplate;
	Items.CurrentValue.Enabled = DocumentIsBeingEdited;
	Items.ShowHeadersAndFooters.Enabled = DocumentIsBeingEdited;
	Items.Translate.Enabled = DocumentIsBeingEdited;
	SetAvailabilityRecursively(Items.EditingCommands);
	SetAvailabilityRecursively(Items.LangsToAdd, DocumentIsBeingEdited);
	
EndProcedure

&AtClient
Function IsNew()
	Return Not ValueIsFilled(Parameters.Ref) And IsBlankString(IdentifierOfTemplate) And IsBlankString(Parameters.PathToFile);
EndFunction

&AtClient
Procedure EditInExternalApplicationCompletion(ImportedSpreadsheetDocument, AdditionalParameters) Export
	If ImportedSpreadsheetDocument = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	UpdateSpreadsheetDocument(ImportedSpreadsheetDocument);
EndProcedure

&AtServer
Procedure UpdateSpreadsheetDocument(Val ImportedSpreadsheetDocument)
	FillSpreadsheetDocument(SpreadsheetDocument, ImportedSpreadsheetDocument);
EndProcedure

// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - Input/output parameter.
//  ImportedSpreadsheetDocument - SpreadsheetDocument
//
&AtServerNoContext
Procedure FillSpreadsheetDocument(SpreadsheetDocument, Val ImportedSpreadsheetDocument)
	For LineNumber = 1 To ImportedSpreadsheetDocument.TableHeight Do
		For ColumnNumber = 1 To ImportedSpreadsheetDocument.TableWidth Do
			OriginalCell = ImportedSpreadsheetDocument.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			If OriginalCell.FillType <> SpreadsheetDocumentAreaFillType.Text Then
				SpreadsheetDocument = ImportedSpreadsheetDocument;
				Return;
			EndIf;
		EndDo;
	EndDo;
	
	SpreadsheetDocument.Clear();
	SpreadsheetDocument.Put(ImportedSpreadsheetDocument);
	
	
	SpreadsheetDocument.Header.LeftText = ImportedSpreadsheetDocument.Header.LeftText;
	SpreadsheetDocument.Header.CenterText = ImportedSpreadsheetDocument.Header.CenterText;
	SpreadsheetDocument.Header.RightText = ImportedSpreadsheetDocument.Header.RightText;
	SpreadsheetDocument.Footer.LeftText = ImportedSpreadsheetDocument.Footer.LeftText;
	SpreadsheetDocument.Footer.CenterText = ImportedSpreadsheetDocument.Footer.CenterText;
	SpreadsheetDocument.Footer.RightText = ImportedSpreadsheetDocument.Footer.RightText;
	
	TableOfAreas = TableOfAreas(ImportedSpreadsheetDocument, True);
	For Each CurrentArea In TableOfAreas Do
		
		Area = SpreadsheetDocument.Areas.Find(CurrentArea.Name);
		If Area = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
			And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows
			Or TypeOf(Area) = Type("SpreadsheetDocumentDrawing") Then
				CopyArea = ImportedSpreadsheetDocument.Areas.Find(Area.Name);
				If CopyArea = Undefined Then
					Continue;
				EndIf;
				Area.DetailsParameter = CopyArea.DetailsParameter;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure SetInitialFormSettings()
	
	If Not IsBlankString(Parameters.PathToFile) And Not EditingDenied Then
		Items.SpreadsheetDocument.Edit = True;
	EndIf;
	
	SetDocumentName();
	SetHeader();
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();

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
Procedure OnCompleteGetReadOnly(Var_ReadOnly, AdditionalParameters) Export
	
	EditingDenied = Var_ReadOnly;
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure Attachable_SwitchLanguage(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.SwitchLanguage(ThisObject, Command);
		
		Items.DeleteLayoutLanguage.Visible = Not ValueIsFilled(Parameters.Ref) 
			Or CurrentLanguage <> CommonClient.DefaultLanguageCode();
			
		Items.ButtonShowHideOriginal.Enabled = SuppliedTemplate.TableHeight > 0;
		If IsPrintForm Then
			FillSpreadsheetDocument(SpreadsheetDocument, ReadLayout());
		EndIf;
		
		If CurrentLanguage = CommonClient.DefaultLanguageCode() Then
			Items.DeleteLayoutLanguage.Title = NStr("vi = 'Xóa tất cả thay đổi của khuôn in';
													|ru = 'Удалить все изменения макета';
													|en = 'Delete all template changes'; fa = 'Delete all template changes';
													|it = 'Удалить все изменения макета';
													|pl = 'Delete all template changes';
													|tr = 'Tüm şablon değişikliklerini sil'");
		Else
			Items.DeleteLayoutLanguage.Title = NStr("vi = 'Xóa khuôn in bằng ngôn ngữ hiện tại';
													|ru = 'Удалить макет на текущем языке';
													|en = 'Delete template in current language'; fa = 'Delete template in current language';
													|it = 'Удалить макет на текущем языке';
													|pl = 'Delete template in current language';
													|tr = 'Mevcut dildeki şablonu sil'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteLayoutLanguage(Command)
	
	DeleteLayoutInCurrentLanguage();

	WritingCompleted = True;
	NotifyAboutTheTableDocumentEntry();

	Items.DeleteLayoutLanguage.Visible = Not ValueIsFilled(Parameters.Ref)
		Or CurrentLanguage <> CommonClient.DefaultLanguageCode();
	
	SetHeader();
EndProcedure

&AtClient
Procedure Attachable_WhenSwitchingTheLanguage(LanguageCode, AdditionalParameters) Export
	
	SetHeader();
	LoadSpreadsheetDocumentFromMetadata(LanguageCode);
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
												|it = 'Non eseguire';
												|pl = 'Nie wykonuj';
												|tr = 'Yapılmasın'"));
		
		CallbackDescription = New CallbackDescription("WhenAnsweringAQuestionAboutTranslatingALayout", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenAnsweringAQuestionAboutTranslatingALayout(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport.TextTranslation") Then
		CallbackDescription = New CallbackDescription("OnCompleteTranslation", ThisObject);
		ModuleTranslationOfTextIntoOtherLanguagesClient = CommonClient.CommonModule("TextTranslationToolClient");
		ModuleTranslationOfTextIntoOtherLanguagesClient.TranslateSpreadsheetTexts(
			SpreadsheetDocument, CurrentLanguage, CommonClient.DefaultLanguageCode(), ThisObject, CallbackDescription);
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OnCompleteTranslation(TranslatedSpreadsheetDocument, AdditionalParameters) Export
	
	If TypeOf(TranslatedSpreadsheetDocument) = Type("SpreadsheetDocument") Then
		SpreadsheetDocument = TranslatedSpreadsheetDocument;
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowHideOriginal(Command)
	
	Items.ButtonShowHideOriginal.Check = Not Items.ButtonShowHideOriginal.Check;
	Items.SuppliedTemplate.Visible = Items.ButtonShowHideOriginal.Check;
	If Items.ButtonShowHideOriginal.Check Then
		Items.SpreadsheetDocument.TitleLocation = FormItemTitleLocation.Auto;
	Else
		Items.SpreadsheetDocument.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizeTheLayoutViewport()
	
	If Not Items.SuppliedTemplate.Visible Then
		Return;
	EndIf;
	
	ManagedElement = Items.SuppliedTemplate;
	If CurrentItem <> Items.SpreadsheetDocument Then
		ManagedElement = Items.SpreadsheetDocument;
		CurrentItem = Items.SuppliedTemplate;
	EndIf;
	
	Area = CurrentItem.CurrentArea;
	If Area = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Area) = Type("SpreadsheetDocumentRange") Then
		ManagedElement.CurrentArea = ThisObject[CurrentItem.Name].Area(
			Area.Top, Area.Left, Area.Bottom, Area.Right);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyAboutTheTableDocumentEntry()
	
	NotificationParameters = StandardSubsystemsClient.NewNotificationParameterForSpreadsheetDocumentWrite();
	NotificationParameters.PathToFile = Parameters.PathToFile;
	NotificationParameters.TemplateMetadataObjectName = IdentifierOfTemplate;
	NotificationParameters.LanguageCode = CurrentLanguage;
	NotificationParameters.Presentation = DocumentName;
	NotificationParameters.DataSources = DataSources.UnloadValues();
	NotificationParameters.DefaultPrintForm = DefaultPrintForm;
	NotificationParameters.PrintFormDescription = PrintFormDescription;
	NotificationParameters.ExportSaveFormat = ExportSaveFormat;
	NotificationParameters.TemplateForObjectExport = TemplateForObjectExport;
	
	If WritingCompleted Then
		EventName = "Write_SpreadsheetDocument";
	Else
		EventName = "CancelEditSpreadsheetDocument";
	EndIf;
	Notify(EventName, NotificationParameters, ThisObject);
	
	WritingCompleted = False;
	
EndProcedure

&AtServer
Procedure UnlockAtServer() 
	UnlockDataForEdit(KeyOfEditObject, UUID);
EndProcedure

&AtClient
Procedure ChangeFontContinued(Result, Var_Parameters) Export 
	
	CurrentArea = Items.SpreadsheetDocument.CurrentArea;
	
	If Result = Undefined Then 
		Return;
	ElsIf Result = -1 Then 
		FontChooseDialog = New FontChooseDialog;
		CallbackDescription = New CallbackDescription("CompletionChangeFont", ThisObject);
		FontChooseDialog.Font = CurrentArea.Font;
		FontChooseDialog.Show(CallbackDescription);
	Else 
		CurrentArea.Font = New Font(CurrentArea.Font, Result);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompletionChangeFont(Font, Var_Parameters) Export

	If Font = Undefined Then
		Return;
	EndIf;
	
	CurrentArea = Items.SpreadsheetDocument.CurrentArea;
	CurrentArea.Font = Font;
	Modified = True;
		
EndProcedure

&AtClient
Procedure ChangeBorderColorCompletion(Color, Var_Parameters) Export
	
	SpecifyColor("BorderColor", Color);
	
EndProcedure


&AtClient
Procedure ChangeTextColorCompletion(Color, Var_Parameters) Export
	
	SpecifyColor("TextColor", Color);
	
EndProcedure

&AtClient
Procedure ChangeBackgroundColorCompletion(Color, Var_Parameters) Export
	
	SpecifyColor("BackColor", Color);
	
EndProcedure

&AtClient
Procedure SpecifyColor(FieldName, Color)
	CurrentArea = Items.SpreadsheetDocument.CurrentArea;
	If TypeOf(Color) = Type("Color")Then
		CurrentArea[FieldName] = Color;
		Modified = True;
	ElsIf Color = "OtherColors" Then
		ColorChooseDialog = New ColorChooseDialog();
		CallbackDescription = New CallbackDescription("AfterColorSelected", ThisObject, FieldName);
		ColorChooseDialog.Show(CallbackDescription);
	EndIf;
EndProcedure

&AtClient
Procedure AfterColorSelected(Color, FieldName) Export
	SpecifyColor(FieldName, Color);
EndProcedure

#Region PrintableFormConstructor

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

&AtClient
Procedure SpreadsheetDocumentDrag(Item, DragParameters, StandardProcessing, Area)

	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
	
		AreaNameEditing = Area.Name;
		CurrentValue = Area.Text;
		
		If TypeOf(DragParameters.Value) <> Type("String") Then 
			Return;
		EndIf;
		
		SelectedField = ModuleConstructorFormulaClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheFieldList());
		If SelectedField = Undefined Then
			Return;
		EndIf;
		
		PlaceFigureInSpreadsheetDocument(SelectedField, Area.Left, Area.Top, StandardProcessing);
		
		If StandardProcessing Then
			StandardProcessing = False;
			Area = SpreadsheetDocument.Area(Area.Top, Area.Left); // Get the area of the merged cells.
			Area.Text = ?(ValueIsFilled(Area.Text), TrimR(Area.Text) + " ", "") + DragParameters.Value;
		EndIf;
	EndIf;
	RecipientOfDraggedValue = Item;

EndProcedure

// Parameters:
//  SelectedField - See FormulasConstructorClient.TheSelectedFieldInTheFieldList
//  Left - Number
//  Top - Number
//  StandardProcessing - Number - Output parameter.
//
&AtServer
Procedure PlaceFigureInSpreadsheetDocument(Val SelectedField, Val Left, Val Top, StandardProcessing)
	
	Area = SpreadsheetDocument.Area(Top, Left, Top, Left);
	
	If StrStartsWith(SelectedField.Name, "Print") Then
		StandardProcessing = False;
		
		Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		Drawing.Name = PickupRegionName(SpreadsheetDocument, SelectedField.Name);
		Drawing.DetailsParameter = "[" + SelectedField.DataPath + "]";
		Drawing.Picture = PictureLib["CompanySeal"];
		Drawing.Place(Area);
		Drawing.Height = 40;
		Drawing.Width = 40;
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		Drawing.BackColor = DefaultColor();
		Drawing.PictureSize = PictureSize.Proportionally;
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;

	If StrStartsWith(SelectedField.Name, "Signature") Then
		StandardProcessing = False;
		Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		Drawing.Name = PickupRegionName(SpreadsheetDocument, SelectedField.Name);
		Drawing.DetailsParameter = "[" + SelectedField.DataPath + "]";
		Drawing.Picture = PictureLib["Signature"];
		Drawing.Place(Area);
		Drawing.Height = 10;
		Drawing.Width = 30;
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		Drawing.BackColor = DefaultColor();
		Drawing.PictureSize = PictureSize.Proportionally;
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;
	
	If SelectedField.Name = "DSStamp" Then
		StandardProcessing = False;

		RowArea_ = SpreadsheetDocument.Area(Area.Top, , Area.Top + 6);
		RowArea_.CreateFormatOfRows();
		
		StampArea = SpreadsheetDocument.Area(Area.Top, Area.Left, Area.Top + 6, Area.Left + 1);
		StampArea.Name = PickupRegionName(SpreadsheetDocument, "DSStamp");
		
		StampArea = SpreadsheetDocument.Area(Area.Top, Area.Left, Area.Top + 6, Area.Left);
		StampArea.ColumnWidth = 10;
		StampArea = SpreadsheetDocument.Area(Area.Top, Area.Left + 1, Area.Top + 6, Area.Left + 1);
		StampArea.ColumnWidth = 30;
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;
	
	If SelectedField.Name = "QRCode" Then
		StandardProcessing = False;
		
		Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		Drawing.Name = PickupRegionName(SpreadsheetDocument, SelectedField.Name);
		Drawing.DetailsParameter = "[" + SelectedField.DataPath + "]";
		Drawing.Place(Area);
		Drawing.Height = 40;
		Drawing.Width = 40;
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		Drawing.BackColor = DefaultColor();
		Drawing.PictureSize = PictureSize.Proportionally;
		Drawing.Picture = PictureLib["PlaceForQRCode"];
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;
	
	If SelectedField.Name = "BarcodeIcon" Then
		StandardProcessing = False;
		
		Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		Drawing.Name = PickupRegionName(SpreadsheetDocument, SelectedField.Name);
		Drawing.DetailsParameter = "[" + SelectedField.DataPath + "]";
		Drawing.Place(Area);
		Drawing.Height = 25.93;
		Drawing.Width = 37.29;
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		Drawing.BackColor = DefaultColor();
		Drawing.PictureSize = PictureSize.Proportionally;
		Drawing.Picture = PictureLib["PlaceForBarCode"];
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;
	
	ThisisAttachedFile = SelectedField.Type.Types().Count() = 1
		And AttachedFilesTypes.ContainsType(SelectedField.Type.Types()[0]);
		
	If ThisisAttachedFile Then
		StandardProcessing = False;
		
		Drawing = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		Drawing.Name = PickupRegionName(SpreadsheetDocument, "Drawing");
		Drawing.DetailsParameter = "[" + SelectedField.DataPath + "]";
		Drawing.Picture = PictureLib["PlaceForPicture"];
		Drawing.Place(Area);
		Drawing.Height = 20;
		Drawing.Width = 20;
		Drawing.Line = New Line(SpreadsheetDocumentDrawingLineType.None);
		Drawing.BackColor = DefaultColor();
		Drawing.PictureSize = PictureSize.Proportionally;
		
		Items.SpreadsheetDocument.CurrentArea = Area;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SpreadsheetDocumentDragCheck(Item, DragParameters, StandardProcessing, Area)

	If TypeOf(DragParameters.Value) <> Type("Array")
		Or DragParameters.Value.Count() <> 1 
		Or Not DragParameters.Value[0].Table Then
		Return;
	EndIf;
	
	ColumnsCount = DragParameters.Value[0].Items.Count();
	If ColumnsCount = 0 Then
		AreaWidth = ?(Area.Left > 1, 2, 1);
		Area = SpreadsheetDocument.Area(Area.Top, Area.Left, Area.Top, Area.Left + AreaWidth - 1);
		Item.CurrentArea = Area;
		Return;
	EndIf;
	
	StandardProcessing = False;
	Area = SpreadsheetDocument.Area(Area.Top, Area.Left, Area.Top + 1, Area.Left + ColumnsCount - 1);
	Item.CurrentArea = Area;
	
EndProcedure

&AtClient
Procedure UpdateInputFieldCurrentCellValue()
	
	CurrentArea = SpreadsheetDocument.CurrentArea;
	EditingAvailable = Items.SpreadsheetDocument.Edit And CurrentArea <> Undefined 
		And TypeOf(CurrentArea) = Type("SpreadsheetDocumentRange");
	Items.CurrentValue.Enabled = EditingAvailable;
	If EditingAvailable Then
		CurrentValue = CurrentArea.Text;
	Else
		CurrentValue = "";
	EndIf;
	
	Items.RepeatAtTopofPage.Enabled = False;
	Items.RepeatAtEndPage.Enabled = False;
	
	ViewArea = NStr("vi = 'Nội dung ô được chọn';
					|ru = 'Текст выбранной ячейки';
					|en = 'Text of the selected cell'; fa = 'متن سلول انتخاب‌شده';
					|it = 'Testo della cella selezionata';
					|pl = 'Tekst wybranej komórki';
					|tr = 'Seçilen hücrenin metni'");
	If TypeOf(CurrentArea) = Type("SpreadsheetDocumentRange") Then
		If CurrentArea.AreaType = SpreadsheetDocumentCellAreaType.Rows
			And ValueIsFilled(CurrentArea.Top) Then
			Span = CurrentArea.Top;
			If CurrentArea.Top <> CurrentArea.Bottom Then
				Span = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1-%2';
						|ru = '%1-%2';
						|en = '%1-%2'; fa = '%1-%2';
						|it = '%1-%2';
						|pl = '%1-%2';
						|tr = '%1-%2'"), CurrentArea.Top, CurrentArea.Bottom);
				ViewArea = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Điều kiện hiển thị dòng %1';
						|ru = 'Условия вывода строк %1';
						|en = 'Output conditions for rows %1'; fa = 'Output conditions for rows %1';
						|it = 'Condizioni di uscita riga %1';
						|pl = 'Warunki wyświetlenia wierszy %1';
						|tr = 'Satırların%1 görüntüleme koşulları'"), Span);
			Else
				ViewArea = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Điều kiện hiển thị dòng %1';
						|ru = 'Условия вывода строки %1';
						|en = 'Output conditions for row %1'; fa = 'Output conditions for row %1';
						|it = 'Condizioni di uscita riga %1';
						|pl = 'Warunki wyświetlenia wierszy %1';
						|tr = 'Satır %1 görüntüleme koşulları'"), Span);
			EndIf;
			Items.RepeatAtTopofPage.Enabled = True;
			Items.RepeatAtEndPage.Enabled = True;
			
			If ValueIsFilled(CurrentArea.Name) Then
				CurrentValue = CurrentArea.DetailsParameter;
			EndIf;
		EndIf;
		If ValueIsFilled(CurrentArea.Left) And Not ValueIsFilled(CurrentArea.Top) Then
			Span = CurrentArea.Left;
			If CurrentArea.Left <> CurrentArea.Right Then
				Span = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1-%2';
						|ru = '%1-%2';
						|en = '%1-%2'; fa = '%1-%2';
						|it = '%1-%2';
						|pl = '%1-%2';
						|tr = '%1-%2'"), CurrentArea.Left, CurrentArea.Right);
				ViewArea = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Điều kiện hiển thị cột %1';
						|ru = 'Условия вывода колонок %1';
						|en = 'Output conditions for columns %1'; fa = 'Output conditions for columns %1';
						|it = 'Condizioni di uscita colonne %1';
						|pl = 'Warunki wyświetlenia kolumn %1';
						|tr = 'Sütünleri%1 görüntüleme koşulları'"), Span);
			Else
				ViewArea = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Điều kiện hiển thị cột %1';
						|ru = 'Условия вывода колонки %1';
						|en = 'Output conditions for column %1'; fa = 'Output conditions for column %1';
						|it = 'Condizioni di uscita colonne %1';
						|pl = 'Warunki wyświetlenia kolumny %1';
						|tr = 'Sütün %1 görüntüleme koşulları'"), Span);
			EndIf;
		EndIf;
		If ValueIsFilled(CurrentArea.Left) And ValueIsFilled(CurrentArea.Top) Then
			If CurrentArea.Left <> CurrentArea.Right Or CurrentArea.Top <> CurrentArea.Bottom Then
				ViewArea = NStr("vi = 'Nội dung trong vùng đã chọn';
								|ru = 'Текст в выбранной области';
								|en = 'Text in the selected area'; fa = 'Text in the selected area';
								|it = 'Testo nell''area selezionata';
								|pl = 'Tekst w wybranym obszarze';
								|tr = 'Seçilen alan metni'");
			Else
				ViewArea = NStr("vi = 'Nội dung ô được chọn';
								|ru = 'Текст выбранной ячейки';
								|en = 'Text of the selected cell'; fa = 'متن سلول انتخاب‌شده';
								|it = 'Testo della cella selezionata';
								|pl = 'Tekst wybranej komórki';
								|tr = 'Seçilen hücrenin metni'");
			EndIf;
		EndIf;
		AreaName = ViewArea;
	EndIf;
	
	Items.DeleteStampEP.Enabled = TypeOf(CurrentArea) = Type("SpreadsheetDocumentRange")
		And StrStartsWith(CurrentArea.Name, "DSStamp");
	
	If TypeOf(CurrentArea) = Type("SpreadsheetDocumentRange")
		And CurrentArea.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			Items.RepeatAtTopofPage.Check = CurrentArea.PageTop;
			Items.RepeatAtEndPage.Check = CurrentArea.PageBottom;
	Else
		Items.RepeatAtTopofPage.Check = False;
		Items.RepeatAtEndPage.Check = False;
	EndIf;
	
	TextControlButtonAvailability(CurrentArea);
	
EndProcedure

&AtServer
Procedure PickupSample(MetadataObject)
	
	QueryText =
	"SELECT TOP 1 ALLOWED
	|	SpecifiedTableAlias.Ref AS Ref
	|FROM
	|	&Table AS SpecifiedTableAlias
	|
	|ORDER BY
	|	Ref DESC";
	
	QueryText = StrReplace(QueryText, "&Table", MetadataObject.FullName());
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Pattern = Selection.Ref;
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeHeadersFooters(Command)
	
	Items.ShowHeadersAndFooters.Check = Not Items.ShowHeadersAndFooters.Check;
	Items.Header.Visible = Items.ShowHeadersAndFooters.Check;
	Items.Footer.Visible = Items.ShowHeadersAndFooters.Check;
	Items.EditingCommands.Visible = Not Items.EditingCommands.Visible;
	Items.CommandPanelFooterPanel.Visible = Not Items.EditingCommands.Visible;
	Items.CurrentValue.Visible = Not Items.ShowHeadersAndFooters.Check;
	Items.SettingsCurrentRegion.Visible = Not Items.ShowHeadersAndFooters.Check;
	Items.SpreadsheetDocument.ReadOnly = Items.ShowHeadersAndFooters.Check;
		
	StateText = ?(Items.ShowHeadersAndFooters.Check, NStr("vi = 'Soạn tiêu đề đầu trang đáy trang';
															|ru = 'Редактирование колонтитулов';
															|en = 'Edit headers and footers'; fa = 'Edit headers and footers';
															|it = 'Modifica piè di pagina';
															|pl = 'Edycja nagłówków i stopek';
															|tr = 'Başlık düzenlemesi'"), "");
	DisplayCurrentPrintFormState(StateText);
	
	If Items.ShowHeadersAndFooters.Check Then
		ToggleVisibilityCommandsFooters();
	Else
		DetachIdleHandler("ToggleVisibilityCommandsFooters");
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearFormat(Command)
	
	CurrentArea = Items.SpreadsheetDocument.CurrentArea;
	ClearAreaFormat(CurrentArea);
	Modified = True;
	
EndProcedure

&AtClient
Procedure ClearAreaFormat(Area)
	
	Area.Font = Undefined;
	Area.BorderColor = DefaultColor();
	Area.TextColor = DefaultColor();
	Area.PatternColor = DefaultColor();
	Area.BackColor = DefaultColor();
	Area.VerticalAlign = Undefined;
	Area.PictureVerticalAlign = Undefined;
	Area.HorizontalAlign = Undefined;
	Area.PictureHorizontalAlign = Undefined;
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultColor()
	Return New Color;
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
							|it = 'DLF=D';
							|pl = 'DLF=D';
							|tr = 'DLF=D'");
		Else
			Format = NStr("vi = 'DLF=DT';
							|ru = 'ДЛФ=DT';
							|en = 'DLF=DT'; fa = 'DLF=DT';
							|it = 'DLF=DT';
							|pl = 'DLF=DT';
							|tr = 'DLF=DT'");
		EndIf;
	ElsIf Type = Type("Boolean") Then
		Format = NStr("vi = 'BF=Không; BT=Có';
						|ru = 'БЛ=Нет; БИ=Да';
						|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
						|it = 'BF=No; BT=Si';
						|pl = 'BF=Nie; BT=Tak';
						|tr = 'BF=Hayır; BT=Evet'");
	EndIf;
	
	Return Format;
	
EndFunction

&AtClient
Procedure HighlightCellsWithSelectedField()
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	If CurrentData = Undefined Or Not ValueIsFilled(CurrentData.RepresentationOfTheDataPath) Then
		Return;
	EndIf;
	
	ClearHighlight();
	TreatedAreas = New Map();
	
	ModulePrintManagerClient = Undefined;
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
	Else
		Return;
	EndIf;
	
	For LineNumber = 1 To SpreadsheetDocument.TableHeight Do
		For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
			Area = SpreadsheetDocument.Area(LineNumber, ColumnNumber);

			AreaID = ModulePrintManagerClient.AreaID(Area);
			If TreatedAreas[AreaID] <> Undefined Then
				Continue;
			EndIf;
			TreatedAreas[AreaID] = True;
			
			If CurrentData.Table
				And StrFind(Area.Text, "[" + CurrentData.RepresentationOfTheDataPath + ".") > 0
				Or StrFind(Area.Text, "[" + CurrentData.RepresentationOfTheDataPath + "]") > 0 Then
				HighlightedRegions.Add(Area.BackColor, Area.Name);
				Area.BackColor = FieldSelectionBackColor;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearHighlight()
	
	For Each Item In HighlightedRegions Do
		BackColor = Item.Value;
		AreaName = Item.Presentation;
		
		Area = SpreadsheetDocument.Area(AreaName);
		Area.BackColor = BackColor;
	EndDo;
	
	HighlightedRegions.Clear();
	
EndProcedure

&AtClient
Procedure AvailableFields(Command)
	
	Items.ButtonAvailableFields.Check = Not Items.ButtonAvailableFields.Check;
	Items.FieldsAndOperatorsGroup.Visible = Items.ButtonAvailableFields.Check;
	
EndProcedure

&AtClient
Procedure DisplayCurrentPrintFormState(StateText = "")
	
	ShowStatus = Not IsBlankString(StateText);
	
	SpreadsheetDocumentField = Items.SpreadsheetDocument;
	
	StatePresentation = SpreadsheetDocumentField.StatePresentation;
	StatePresentation.Text = StateText;
	StatePresentation.Visible = ShowStatus;
	StatePresentation.AdditionalShowMode = 
		?(ShowStatus, AdditionalShowMode.Irrelevance, AdditionalShowMode.DontUse);
		
	SpreadsheetDocumentField.ReadOnly = ShowStatus Or SpreadsheetDocumentField.Output = UseOutput.Disable;
	
EndProcedure

&AtClient
Procedure UpdateAreaSettingsSelectedCells()
	UpdateInputFieldCurrentCellValue();
	AreaNameEditing = "";
EndProcedure

&AtClient
Procedure RepeatOnEachPage(Command)
	
	CurrentArea = SpreadsheetDocument.CurrentArea;
	If CurrentArea = Undefined Or TypeOf(CurrentArea) <> Type("SpreadsheetDocumentRange")
		Or CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rows Then
		Return;
	EndIf;

	Items.RepeatAtTopofPage.Check = Not Items.RepeatAtTopofPage.Check;
	CurrentArea.PageTop = Items.RepeatAtTopofPage.Check;
	
EndProcedure

&AtClient
Procedure RepeatAtEndPage(Command)
	
	CurrentArea = SpreadsheetDocument.CurrentArea;
	If CurrentArea = Undefined Or TypeOf(CurrentArea) <> Type("SpreadsheetDocumentRange")
		Or CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rows Then
		Return;
	EndIf;

	Items.RepeatAtEndPage.Check = Not Items.RepeatAtEndPage.Check;
	CurrentArea.PageBottom = Items.RepeatAtEndPage.Check;
	
EndProcedure

&AtClient
Procedure CurrentValueOnChange(Item)
	
	UpdateTextInCellsArea();
	RecipientOfDraggedValue = Item;
	
EndProcedure

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

&AtServer
Function ListOfOperators()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.ListOfOperators();
	EndIf;
	
EndFunction

#Region PlugInListOfFields

&AtClient
Procedure Attachable_ListOfFieldsBeforeExpanding(Item, String, Cancel)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.ListOfFieldsBeforeExpanding(ThisObject, Item, String, Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExpandTheCurrentFieldListItem()
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.ExpandTheCurrentFieldListItem(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_FillInTheListOfAvailableFields(FillParameters) Export // ACC:78 - Called from FormulaConstructorClient.
	
	FillInTheListOfAvailableFields(FillParameters);
	
EndProcedure

&AtServer
Procedure FillInTheListOfAvailableFields(FillParameters)
	
	If Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormula = Common.CommonModule("FormulasConstructor");
		ModuleConstructorFormula.FillInTheListOfAvailableFields(ThisObject, FillParameters);
		
		If FillParameters.ListName = NameOfTheFieldList() Then
			CurrentData = ThisObject[FillParameters.ListName].FindByID(FillParameters.RowID);
			SetExamplesValues(CurrentData);
			SetFormatValuesDefault(CurrentData);
			If (CurrentData.Folder Or CurrentData.Table) And CurrentData.GetParent() = Undefined Then
				MarkCommonFields(CurrentData);
			Else
				SetCommonFIeldFlagForSubordinateFields(CurrentData);
			EndIf;
		EndIf
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ListOfFieldsStartDragging(Item, DragParameters, Perform)
	
	Attribute = ThisObject[NameOfTheFieldList()].FindByID(DragParameters.Value);
	
	If Attribute.Folder Or Attribute.Table 
		Or Items.ShowHeadersAndFooters.Check
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
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.SearchStringEditTextChange(ThisObject, Item, Text, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PerformASearchInTheListOfFields()
	
	PerformASearchInTheListOfFields();
	
EndProcedure

&AtServer
Procedure PerformASearchInTheListOfFields()
	
	If Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormula = Common.CommonModule("FormulasConstructor");
		ModuleConstructorFormula.PerformASearchInTheListOfFields(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_SearchStringClearing(Item, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.SearchStringClearing(ThisObject, Item, StandardProcessing);
	EndIf;
	
EndProcedure

&AtServer
Procedure Attachable_FormulaEditorHandlerServer(Parameter, AdditionalParameters) // ACC:1412 - The parameters return to the client.
	If Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormula = Common.CommonModule("FormulasConstructor");
		ModuleConstructorFormula.FormulaEditorHandler(ThisObject, Parameter, AdditionalParameters);
	EndIf;          
	
	If AdditionalParameters.OperationKey = "HandleSearchMessage" Then
		MarkCommonFields();
		SetFormatValuesDefault();
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_FormulaEditorHandlerClient(Parameter, AdditionalParameters = Undefined) Export // ACC:78 - Procedure is called from FormulaConstructorClient.StartSearchInFieldsList.
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.FormulaEditorHandler(ThisObject, Parameter, AdditionalParameters);
		If AdditionalParameters <> Undefined And AdditionalParameters.RunAtServer Then
			Attachable_FormulaEditorHandlerServer(Parameter, AdditionalParameters);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_StartSearchInFieldsList()

	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		ModuleConstructorFormulaClient.StartSearchInFieldsList(ThisObject);
	EndIf;
	
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

// Parameters:
//  Item - FormTable
//  RowSelected - Number
//  Field - FormField
//  StandardProcessing - Boolean
//
&AtClient
Procedure Attachable_ListOfFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ModuleConstructorFormulaClient = Undefined;
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
	Else
		Return;
	EndIf;
	
	If Field.Name = Item.Name + "Presentation" Then
		StandardProcessing = False;
		SelectedField = ModuleConstructorFormulaClient.TheSelectedFieldInTheFieldList(ThisObject);
		If ValueIsFilled(CurrentValue) Then
			CurrentValue = TrimR(CurrentValue) + " ";
		Else
			CurrentValue = "";
		EndIf;
		If Item.Name = NameOfTheFieldList() Then
			CurrentValue = CurrentValue + "[" + SelectedField.RepresentationOfTheDataPath + "]";
		Else
			
			DragValue = ModuleConstructorFormulaClient.ExpressionToInsert(SelectedField);
			AddBrackets(
				SelectedField,
				RecipientOfDraggedValue,
				DragValue,
				True);
			
			CurrentValue = CurrentValue + DragValue;
			AreaNameEditing = "";
			
		EndIf;
		
		UpdateTextInCellsArea();
	EndIf;
	
	If Field = Items[NameOfTheFieldList() + "ButtonSettingsFormat"] And ValueIsFilled(Items[NameOfTheFieldList()].CurrentData.Format) Then
		StandardProcessing = False;
		Designer = New FormatStringWizard(Items[NameOfTheFieldList()].CurrentData.Format);
		Designer.AvailableTypes = Items[NameOfTheFieldList()].CurrentData.Type;
		CallbackDescription = New CallbackDescription("WhenFormatFieldSelection", ThisObject);
		Designer.Show(CallbackDescription);
	EndIf;	
	
EndProcedure

&AtClient
Procedure Attachable_OperatorsDragStart(Item, DragParameters, Perform)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		
		Operator = ModuleConstructorFormulaClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheListOfOperators());
		DragParameters.Value = ModuleConstructorFormulaClient.ExpressionToInsert(Operator);
		If Operator.DataPath = "PrintControl_NumberofLines" Then
			CurrentTablePresentation = CurrentTablePresentation();
			Perform = CurrentTablePresentation <> Undefined;
			DragParameters.Value = StrReplace(DragParameters.Value, "()", "(["+CurrentTablePresentation+"])");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OperatorsDragEnd(Item, DragParameters, StandardProcessing)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		SelectedField = ModuleConstructorFormulaClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheListOfOperators());
		Context = New Structure("DataPath, Title");
		FillPropertyValues(Context, SelectedField);
		
		DragValue = DragParameters.Value;
		AddBrackets(SelectedField, RecipientOfDraggedValue, DragValue);
		
		If DragParameters.Value <> DragValue Then
			
			DragParameters.Value = DragValue;
			
		EndIf;
		
		If Context.DataPath = "Format" Then
			RowFormat = New FormatStringWizard;
			Context.Insert("RowFormat", RowFormat);
			Context.Insert("AreaNameEditing", AreaNameEditing);
			NotificationOfDraggingEndCompletion = New CallbackDescription("OperatorsDragEndCompletion", ThisObject, Context);
			RowFormat.Show(NotificationOfDraggingEndCompletion);
		EndIf;
	EndIf;
	
	AreaNameEditing = "";
	
EndProcedure

&AtClient
Procedure OperatorsDragEndCompletion(Text, Context) Export
	
	If Text = Undefined Then
		Return;
	EndIf;
	
	TextsToReplace = New Structure("ForSearch, ForReplacement", "", "");
	
	If Context.DataPath = "Format" Then
		RowFormat = Context.RowFormat;
		If ValueIsFilled(RowFormat.Text) Then
			TextsToReplace.ForReplacement = Context.Title + "( , """ + RowFormat.Text + """)";
			TextsToReplace.ForSearch = Context.Title + "(,,)";
			TextsToReplace.Insert("AreaNameEditing", Context.AreaNameEditing);
		EndIf;
	EndIf;
	
	WaitHanderParametersAddress = PutToTempStorage(TextsToReplace, UUID);
	
	AttachIdleHandler("SetValAfterDragging", 0.1, True);
	
EndProcedure

#EndRegion

&AtClient
Procedure SetValAfterDragging()
	
	TextsToReplace = GetFromTempStorage(WaitHanderParametersAddress);
	
	If RecipientOfDraggedValue = Items.CurrentValue Or RecipientOfDraggedValue = Undefined Then
		
		CurrentValue = StrReplace(CurrentValue, TextsToReplace.ForSearch, TextsToReplace.ForReplacement);
		UpdateTextInCellsArea();
		
	Else
		CurrentAttribute = ThisObject[RecipientOfDraggedValue.Name];
		If TypeOf(CurrentAttribute) = Type("FormattedDocument") Then
			TextToPlace = StrReplace(CurrentAttribute.GetText(), TextsToReplace.ForSearch, TextsToReplace.ForReplacement);
			FormattedText = New FormattedString(TextToPlace);
			CurrentAttribute.Delete();
			CurrentAttribute.SetFormattedString(FormattedText);
		ElsIf TypeOf(CurrentAttribute) = Type("SpreadsheetDocument") Then
			
			If TextsToReplace.Property("AreaNameEditing")
			   And TextsToReplace.AreaNameEditing <> "" Then
				CurrentArea = SpreadsheetDocument.Area(TextsToReplace.AreaNameEditing);
			Else
				CurrentArea = CurrentAttribute.CurrentArea;
			EndIf;
			CurrentArea.Text = StrReplace(CurrentArea.Text, TextsToReplace.ForSearch, TextsToReplace.ForReplacement);
			CurrentValue = CurrentAttribute.CurrentArea.Text;
			
		Else
			CurrentAttribute = StrReplace(CurrentAttribute, TextsToReplace.ForSearch, TextsToReplace.ForReplacement);
		EndIf;
	EndIf;
	RecipientOfDraggedValue = Undefined;
EndProcedure

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
	TemplateParameters1.Insert("TemplateType", "MXL");
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.WriteTemplatesInAdditionalLangs(TemplateParameters1);
	EndIf;
	
EndProcedure

&AtServer
Function PrepareLayoutForRecording(SetLanguageCode = True, Cancel = False)

	LanguageCode = Undefined;
	If SetLanguageCode Then
		LanguageCode = SpreadsheetDocument.LanguageCode;
	EndIf;
	
	Template = CopySpreadsheetDocument(SpreadsheetDocument, LanguageCode);
	If Not IsPrintForm Then
		Return Template;
	EndIf;
	
	TreatedAreas = New Map();
	FirstFilledRowNumber = 0;
	FirstFilledColumnNumber = 0;
	ArrayOfColumnNames = New Array; // Array of String
	
	For LineNumber = 1 To Template.TableHeight Do
		For ColumnNumber = 1 To Template.TableWidth Do
			Area = Template.Area(LineNumber, ColumnNumber);
			
			If Common.SubsystemExists("StandardSubsystems.Print") Then
				ModulePrintManager = Common.CommonModule("PrintManagement");
				AreaID = ModulePrintManager.AreaID(Area);
				If TreatedAreas[AreaID] <> Undefined Then
					Continue;
				EndIf;
				TreatedAreas[AreaID] = True;
			EndIf;
			
			If ValueIsFilled(Area.Text) Then
				FieldPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'dòng %1 số lượng %2';
																									|ru = 'стр. %1 кол. %2';
																									|en = 'string %1 column %2'; fa = 'string %1 column %2';
																									|it = 'riga %1 colo.%2';
																									|pl = 'str. %1 il. %2';
																									|tr = 'sf. %1 süt. %2'"), LineNumber, ColumnNumber);
				ReplaceViewParameters(Area.Text, , Cancel, FieldPresentation);
				
				If FirstFilledRowNumber = 0 Then
					FirstFilledRowNumber = LineNumber;
					FirstFilledColumnNumber = ColumnNumber;
				EndIf;
				
			EndIf;
			
			If TemplateForObjectExport Then
				
				DataToCheck = New Structure;
				DataToCheck.Insert("FirstFilledRowNumber", FirstFilledRowNumber);
				DataToCheck.Insert("FirstFilledColumnNumber", FirstFilledColumnNumber);
				DataToCheck.Insert("LineNumber", LineNumber);
				DataToCheck.Insert("ColumnNumber", ColumnNumber);
				DataToCheck.Insert("Template", Template);
				DataToCheck.Insert("Area", Area);
				DataToCheck.Insert("CellText", Area.Text);
				
				CheckExportFields(DataToCheck, ArrayOfColumnNames, Cancel);
				
			EndIf;
			
		EndDo;
	EndDo;
	
	ReplaceViewParameters(Template.Header.LeftText, "TopLeftText", Cancel, NStr("vi = 'đề mục đầu trang bên trái';
																				|ru = 'верхний колонтитул слева';
																				|en = 'header on the left'; fa = 'header on the left';
																				|it = 'intestazione sinistra';
																				|pl = 'nagłówek z lewej strony';
																				|tr = 'üst sol başlık'"));
	ReplaceViewParameters(Template.Header.CenterText, "TopMiddleText", Cancel, NStr("vi = 'đề mục đầu trang chính giữa';
																					|ru = 'верхний колонтитул в центре';
																					|en = 'header in the center'; fa = 'header in the center';
																					|it = 'intestazione centro';
																					|pl = 'nagłówek po środku';
																					|tr = 'üst ortadaki başlık'"));
	ReplaceViewParameters(Template.Header.RightText, "TopRightText", Cancel, NStr("vi = 'đề mục đầu trang bên phải';
																					|ru = 'верхний колонтитул справа';
																					|en = 'header on the right'; fa = 'header on the right';
																					|it = 'intestazione destra';
																					|pl = 'nagłówek z prawej strony';
																					|tr = 'üst sağ başlık'"));
	ReplaceViewParameters(Template.Footer.LeftText, "BottomLeftText", Cancel, NStr("vi = 'đề mục cuối trang bên trái';
																					|ru = 'нижний колонтитул слева';
																					|en = 'footer on the left'; fa = 'footer on the left';
																					|it = 'piè di pagina sinistra';
																					|pl = 'stopka z lewej strony';
																					|tr = 'alt sol başlık'"));
	ReplaceViewParameters(Template.Footer.CenterText, "BottomCenterText", Cancel, NStr("vi = 'đề mục cuối trang ở giữa';
																						|ru = 'нижний колонтитул в центре';
																						|en = 'footer in the center'; fa = 'footer in the center';
																						|it = 'piè di pagina centro';
																						|pl = 'stopka po środku';
																						|tr = 'alt ortadaki başlık'"));
	ReplaceViewParameters(Template.Footer.RightText, "BottomRightText", Cancel, NStr("vi = 'đề mục cuối trang bên phải';
																					|ru = 'нижний колонтитул справа';
																					|en = 'footer on the right'; fa = 'footer on the right';
																					|it = 'piè di pagina destra';
																					|pl = 'stopka z prawej strony';
																					|tr = 'alt sağ başlık'"));
	
	FillDrilldownParameters(Template);
	RenameConditionalAreas(Template, ConditionalAreaPrefix(), TemplateForObjectExport);
	
	If TemplateForObjectExport Then
		
		CheckExportAreas(Template, Cancel);
		
	EndIf;
	
	Return Template;
	
EndFunction

&AtServerNoContext
Procedure CheckForMergedCells(Val Area, Val LineNumber, Val ColumnNumber, Cancel)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Template = NStr("vi = 'Đã cấm hợp nhất các ô (dòng %1 cột %2)';
						|ru = 'Объединение ячеек запрещено (стр. %1 кол. %2)';
						|en = 'Cannot merge cells (row %1, column %2)'; fa = 'Cannot merge cells (row %1, column %2)';
						|it = 'Cannot merge cells (row %1, column %2)';
						|pl = 'Cannot merge cells (row %1, column %2)';
						|tr = 'Hücreler birleştirilemez (sf. %1 süt. %2)'");
		AreaID = ModulePrintManager.AreaID(Area);
		AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AreaID, ":");
		
		If AddressArray[0] <> AddressArray[2]
		 Or AddressArray[1] <> AddressArray[3] Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				LineNumber,
				ColumnNumber);
			Common.MessageToUser(ErrorText,,,, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckDBFFieldName(Val CellText, Val LineNumber, Val ColumnNumber, Cancel)
	
	If StrLen(CellText) > 10 Then
		
		Template = NStr("vi = 'Tên trường không vượt quá 10 giá trị (dòng %1 cột %2)';
						|ru = 'Имя поля не может превышать 10 знаков (стр. %1 кол. %2)';
						|en = 'Field name must not exceed 10 characters (row %1, column %2)'; fa = 'Field name must not exceed 10 characters (row %1, column %2)';
						|it = 'Field name must not exceed 10 characters (row %1, column %2)';
						|pl = 'Field name must not exceed 10 characters (row %1, column %2)';
						|tr = 'Alan adı 10 karakteri geçemez (sf. %1 süt. %2)'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			LineNumber, 
			ColumnNumber);
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	AllowedChars = "0123456789_";
	For IndexOf = 1 To StrLen(CellText) Do
		
		Char = Mid(CellText, IndexOf, 1);
		If StrFind(AllowedChars, Char) <> 0 Then
			Continue;
		EndIf;
		
		CharCode = CharCode(Char);
		
		FirstLatinCharUpper = 65;
		LastLatinCharUpper = 90;
		FirstLatinCharLower = 97;
		LastLatinCharLower = 122;
		
		CharCodeError = ((CharCode < FirstLatinCharUpper)
						 Or (CharCode > LastLatinCharUpper 
						    And CharCode < FirstLatinCharLower)
						 Or (CharCode > LastLatinCharLower));
		If CharCodeError Then
			
			Template = NStr("vi = 'Tên trường chỉ được chứa các chữ cái Latin, chữ số và dấu gạch dưới (dòng %1 cột %2)';
							|ru = 'Имена полей могут содержать только латинские буквы, цифры и символ подчеркивания (стр. %1 кол. %2)';
							|en = 'Field name can only contain letters, numbers, and underscores (row %1, column %2)'; fa = 'Field name can only contain letters, numbers, and underscores (row %1, column %2)';
							|it = 'Field name can only contain letters, numbers, and underscores (row %1, column %2)';
							|pl = 'Field name can only contain letters, numbers, and underscores (row %1, column %2)';
							|tr = 'Alan adları yalnızca Latin harfleri, rakamlar ve alt çizgiler içerebilir (sf. %1 süt. %2)'");
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				LineNumber,
				ColumnNumber);
			Common.MessageToUser(ErrorText,,,, Cancel);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure CheckExportFieldsDBF(Val DataToCheck, ArrayOfColumnNames, Cancel)
	
	FieldNamesRowNumber = DataToCheck.FirstFilledRowNumber;
	LineNumber = DataToCheck.LineNumber;
	ColumnNumber = DataToCheck.ColumnNumber;
	Template = DataToCheck.Template;
	Area = DataToCheck.Area;
	CellText = DataToCheck.CellText;
	
	If FieldNamesRowNumber = 0 Then
		Return;
	EndIf;
	
	CheckForMergedCells(Area, LineNumber, ColumnNumber, Cancel);
	
	If Not IsBlankString(CellText) Then
		
		If LineNumber = FieldNamesRowNumber Then
			
			If ArrayOfColumnNames.Find(CellText) <> Undefined Then
				
				Var_232_Template = NStr("vi = 'Tên không đơn trị của cột (dòng %1 cột %2)';
										|ru = 'Неуникальное имя колонки (стр. %1 кол. %2)';
										|en = 'Column name is not unique (row %1, column %2)'; fa = 'Column name is not unique (row %1, column %2)';
										|it = 'Column name is not unique (row %1, column %2)';
										|pl = 'Column name is not unique (row %1, column %2)';
										|tr = 'Benzersiz olmayan sütun adı (sf. %1 süt. %2)'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Var_232_Template,
					LineNumber,
					ColumnNumber);
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			Else
				
				CheckDBFFieldName(CellText, LineNumber, ColumnNumber,  Cancel);
				ArrayOfColumnNames.Add(CellText);
				
			EndIf;
			
		Else
			
			ColumnNamesArea = Template.Area(FieldNamesRowNumber, ColumnNumber);
			NamesCellText = ColumnNamesArea.Text;
				
			If LineNumber > FieldNamesRowNumber + 1 Then
				
				Var_232_Template = NStr("vi = 'Dữ liệu kết xuất cần được chỉ ra trong dòng %1 (dòng %2 cột %3)';
										|ru = 'Данные выгрузки должны указываться в строке %1 (стр. %2 кол. %3)';
										|en = 'Row %1 must contain export data (row %2, column %3)'; fa = 'Row %1 must contain export data (row %2, column %3)';
										|it = 'Row %1 must contain export data (row %2, column %3)';
										|pl = 'Row %1 must contain export data (row %2, column %3)';
										|tr = 'Yükleme verileri %1. satırda raporlanmalıdır (sf. %2 süt. %3)'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Var_232_Template,
					FieldNamesRowNumber + 1,
					LineNumber, 
					ColumnNumber);
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
				
			If IsBlankString(NamesCellText) Then
				
				Var_232_Template = NStr("vi = 'Chưa chỉ ra tên cột (cột %1)';
										|ru = 'Не указано имя колонки (кол. %1)';
										|en = 'Column name is required (column %1)'; fa = 'Column name is required (column %1)';
										|it = 'Column name is required (column %1)';
										|pl = 'Column name is required (column %1)';
										|tr = 'Sütun adı belirtilmemiş (sütun %1)'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Var_232_Template,
					ColumnNumber);
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckExportFieldsXML_JSON(Val DataToCheck, IsXML, Cancel)
	
	LineNumber = DataToCheck.LineNumber;
	ColumnNumber = DataToCheck.ColumnNumber;
	Area = DataToCheck.Area;
	Template = DataToCheck.Template;
	CellText = DataToCheck.CellText;
	
	CheckForMergedCells(Area, LineNumber, ColumnNumber, Cancel);
	
	FieldNamesColumnNumber = 1;
	ValuesColumnNumber = 2;
	
	If ColumnNumber > ValuesColumnNumber
	   And Not IsBlankString(CellText) Then
		
		Var_243_Template = NStr("vi = 'Cần đặt tên các trường và giá trị của chúng trong %1 và trong %2 cột tương ứng (dòng %3 cột %4)';
								|ru = 'Имена полей и их значения должны располагаться в %1 и во %2 колонке соответственно (стр. %3 кол. %4)';
								|en = 'Field names and values must be placed in the columns %1 and %2, respectively (row %3, column %4)'; fa = 'Field names and values must be placed in the columns %1 and %2, respectively (row %3, column %4)';
								|it = 'Field names and values must be placed in the columns %1 and %2, respectively (row %3, column %4)';
								|pl = 'Field names and values must be placed in the columns %1 and %2, respectively (row %3, column %4)';
								|tr = 'Alan adları ve değerleri sırasıyla %1. ve %2. sütunda yerleştirilmelidir (sf. %3 süt. %4)'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			Var_243_Template,
			FieldNamesColumnNumber,
			ValuesColumnNumber,
			LineNumber,
			ColumnNumber);
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	If ColumnNumber = FieldNamesColumnNumber Then
		
		If Not IsBlankString(CellText) Then
			
			CheckCellChars(CellText, LineNumber, ColumnNumber, IsXML, Cancel);
			
		EndIf;
		
		AreaValue = Template.Area(LineNumber, ColumnNumber + 1);
		ValueText = AreaValue.Text;
		
		If IsBlankString(CellText) <> IsBlankString(ValueText) Then
			
			Var_243_Template = NStr("vi = 'Tên trường và giá trị của nó không được so sánh (dòng %1)';
									|ru = 'Имя поля и его значение не сопоставлены (стр. %1)';
									|en = 'Field name is not mapped to field value (row %1)'; fa = 'Field name is not mapped to field value (row %1)';
									|it = 'Field name is not mapped to field value (row %1)';
									|pl = 'Field name is not mapped to field value (row %1)';
									|tr = 'Alan adı ve değeri eşleşmiyor (sf. %1)'");
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Var_243_Template,
				LineNumber);
			Common.MessageToUser(ErrorText,,,, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TextMeetsNamingRequirements(Val Text, IsXML = True, ForbiddenSubstring = Undefined)
	
	Result = New Structure;
	Result.Insert("HasForbiddenSubstring", False);
	Result.Insert("MeetsNamingRequirements", True);
	
	If IsXML Then
		ExpressionPattern = "^[\p{L}_]+[\w.-]*$";
	Else
		ExpressionPattern = "^[\p{L}_]\w*$";
	EndIf;
	
	If ForbiddenSubstring <> Undefined Then
		
		ForbiddenSubstringLength = StrLen(ForbiddenSubstring);
		CharsCount = Min(StrLen(TrimAll(Text)), ForbiddenSubstringLength);
		CheckedSubstring = Left(TrimAll(Text), CharsCount);
		Result.HasForbiddenSubstring = (Lower(CheckedSubstring) = Lower(ForbiddenSubstring));
		
	EndIf;
	
	Expression = Text;
	ResultOfExpression = StrFindByRegularExpression(Expression, ExpressionPattern);
	Result.MeetsNamingRequirements = (ResultOfExpression.Length <> 0);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure CheckCellChars(Val CellText, Val LineNumber, Val ColumnNumber, Val IsXML, Cancel)
	
	ForbiddenSubstring = Undefined;
	If IsXML Then
		
		TemplateNotCompliant = NStr("vi = 'Tên trường ""%1"" không tương ứng với yêu cầu đối với tên token XML (dòng %2 cột %3)';
									|ru = 'Имя поля ""%1"" не соответствует требованиям к именам токенов XML (стр. %2 кол. %3)';
									|en = 'Field name ""%1"" does not comply with XML token naming convention (row %2, column %3)'; fa = 'Field name ""%1"" does not comply with XML token naming convention (row %2, column %3)';
									|it = 'Field name ""%1"" does not comply with XML token naming convention (row %2, column %3)';
									|pl = 'Field name ""%1"" does not comply with XML token naming convention (row %2, column %3)';
									|tr = 'Alan adı ""%1"", XML token''ları için gereksinimleri karşılamıyor (sf. %2 süt. %3)'");
		ForbiddenSubstring = "xml";
		
	Else
		
		TemplateNotCompliant = NStr("vi = 'Tên trường ""%1"" không tương ứng với yêu cầu đối với tên biến (dòng %2 cột %3)';
									|ru = 'Имя поля ""%1"" не соответствует требованиям к именам переменных (стр. %2 кол. %3)';
									|en = 'Field name ""%1"" does not comply with variable naming convention (row %2, column %3)'; fa = 'Field name ""%1"" does not comply with variable naming convention (row %2, column %3)';
									|it = 'Field name ""%1"" does not comply with variable naming convention (row %2, column %3)';
									|pl = 'Field name ""%1"" does not comply with variable naming convention (row %2, column %3)';
									|tr = 'Alan adı ""%1"", değişken adlar için gereksinimleri karşılamıyor (sf. %2 süt. %3)'");
		
	EndIf;
	
	CheckResult = TextMeetsNamingRequirements(CellText, IsXML, ForbiddenSubstring);
	
	If CheckResult.HasForbiddenSubstring Then 
		
		TemplateForbiddenString = NStr("vi = 'Tên trường ""%1"" không thể bắt đầu từ ""%2"" (dòng %3 cột %4)';
										|ru = 'Имя поля ""%1"" не может начинаться с ""%2"" (стр. %3 кол. %4)';
										|en = 'Field name ""%1"" must not start with ""%2"" (row %3, column %4)'; fa = 'Field name ""%1"" must not start with ""%2"" (row %3, column %4)';
										|it = 'Field name ""%1"" must not start with ""%2"" (row %3, column %4)';
										|pl = 'Field name ""%1"" must not start with ""%2"" (row %3, column %4)';
										|tr = 'Alan adı ""%1"", ""%2"" ile başlayamaz  (sf. %3 süt. %4)'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateForbiddenString,
			CellText,
			ForbiddenSubstring,
			LineNumber,
			ColumnNumber);
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	If Not CheckResult.MeetsNamingRequirements Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			TemplateNotCompliant,
			CellText,
			LineNumber,
			ColumnNumber);
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckExportFields(Val DataToCheck, ArrayOfColumnNames, Cancel)
	
	If Not ValueIsFilled(ExportSaveFormat)
	 Or Not Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
		Return;
	EndIf;
	
	ArrayOfFormatsNotUsingSpreadsheet = New Array; // Array of EnumRef.ObjectsExportFormats
	
	ModuleExportObjectsToFiles = Common.CommonModule("ExportObjectsToFiles");
	ArrayOfFormatsNotUsingSpreadsheet =
		ModuleExportObjectsToFiles.ExportFormatsWithoutUsingSpreadsheet();
	
	If ArrayOfFormatsNotUsingSpreadsheet.Find(ExportSaveFormat) = Undefined Then
		Return;
	EndIf;
	
	If ExportSaveFormat = Enums.ObjectsExportFormats.DBF Then
		CheckExportFieldsDBF(DataToCheck, ArrayOfColumnNames, Cancel);
	ElsIf ExportSaveFormat = Enums.ObjectsExportFormats.XML Then
		CheckExportFieldsXML_JSON(DataToCheck, True, Cancel);
	Else
		CheckExportFieldsXML_JSON(DataToCheck, False, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
//  Template - SpreadsheetDocument
//  AllAreas - Boolean - Flag indicating that all areas are selected.
// 
// Returns:
//  ValueTable:
// * Name - String 
// * Top - Number 
// * Bottom - Number
// * DetailsParameter - String 
// * Priority - Number
// * IsOutputConditionArea - Boolean 
// * AreaNumber - Number
//
&AtServerNoContext
Function TableOfAreas(Val Template, AllAreas = False)
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsNumber = New TypeDescription("Number");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	TableOfAreas = New ValueTable;
	TableOfAreas.Columns.Add("Name", TypesDetailsString);
	TableOfAreas.Columns.Add("Top", TypesDetailsNumber);
	TableOfAreas.Columns.Add("Bottom", TypesDetailsNumber);
	TableOfAreas.Columns.Add("DetailsParameter", TypesDetailsString);
	TableOfAreas.Columns.Add("Priority", TypesDetailsNumber);
	TableOfAreas.Columns.Add("IsOutputConditionArea", TypesDetailsBoolean);
	TableOfAreas.Columns.Add("IsPictureArea", TypesDetailsBoolean);
	
	For Each Area In Template.Areas Do
		
		ShouldAddAreaToTable = False;
		
		If AllAreas 
		 Or ((TypeOf(Area) = Type("SpreadsheetDocumentRange")
		      And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows)
		 Or TypeOf(Area) = Type("SpreadsheetDocumentDrawing")) Then
			
			ShouldAddAreaToTable = True;
			
		EndIf;
		
		If ShouldAddAreaToTable Then
			
			NewRow = TableOfAreas.Add();
			FillPropertyValues(NewRow, Area); 
			NewRow.IsPictureArea = (TypeOf(Area) = Type("SpreadsheetDocumentDrawing"));
			
			If Not IsBlankString(Area.DetailsParameter)
			   And TypeOf(Area) = Type("SpreadsheetDocumentRange")
			   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
				
				NewRow.IsOutputConditionArea = True;
				NewRow.Priority = 100;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	TableOfAreas.Sort("Top, Priority");
	
	Return TableOfAreas;
	
EndFunction

&AtServer
Procedure FillDrilldownParameters(Template, TemplateRead = False)
	
	If TemplateForObjectExport
	   And (ExportSaveFormat = Enums.ObjectsExportFormats.JSON
	      Or ExportSaveFormat = Enums.ObjectsExportFormats.XML) Then
		
		FillDecryptionParametersByTableOfAreas(Template, TemplateRead);
		
	Else
		
		FillDecryptionParametersByTemplateAreas(Template, TemplateRead);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDecryptionParametersByTableOfAreas(Template, TemplateRead)
	
	TableOfAreas = TableOfAreas(Template, True);
	
	For Each CurrentArea In TableOfAreas Do
		
		Area = Template.Areas.Find(CurrentArea.Name);
		
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			If TemplateForObjectExport
			   And Not ValueIsFilled(CurrentArea.DetailsParameter) Then
				Continue;
			EndIf;
			
			If TemplateRead Then
				
				Area.DetailsParameter = FormulaPresentation(CurrentArea.DetailsParameter);
				
			Else
				
				Area.DetailsParameter = TheFormulaFromTheView(CurrentArea.DetailsParameter);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillDecryptionParametersByTemplateAreas(Template, TemplateRead)
	
	For Each Area In Template.Areas Do
		
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			If TemplateForObjectExport
			   And Not ValueIsFilled(Area.DetailsParameter) Then
				Continue;
			EndIf;
			
			If TemplateRead Then
				
				Area.DetailsParameter = FormulaPresentation(Area.DetailsParameter);
				
			Else
				
				Area.DetailsParameter = TheFormulaFromTheView(Area.DetailsParameter);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckForUnusedProperties(CompletionHandler, UnlockFile)
	
	If Not ValueIsFilled(ExportSaveFormat) Then
		Return;
	EndIf;
	
	HasUnusedProperties = HasFormattingAndAreasNotUsedInExportFormat();
	
	If HasUnusedProperties Then
		
		StartPropertyDeletionDialog(CompletionHandler, UnlockFile);
		
	Else
		
		WriteSpreadsheetDocumentFileNameSelected(CompletionHandler, UnlockFile);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure StartPropertyDeletionDialog(Val CompletionHandler, UnlockFile) 
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CompletionHandler", CompletionHandler);
	NotificationParameters.Insert("UnlockFile", UnlockFile);
	
	Notification = New CallbackDescription("StartPropertyDeletionDialogCompletion", ThisObject, NotificationParameters);
	
	WarningText = NStr("vi = 'Việc tạo khuôn in hoặc nội dung của nó không tương ứng với yêu cầu của định dạng. Khi lưu khuôn in sẽ xóa các tùy chỉnh không phù hợp.';
						|ru = 'Форматирование макета или его содержимое не соответствует требованиям формата. При сохранении макета будут очищены неподходящие настройки.';
						|en = 'Template formatting or content does not meet format requirements. When you save the template, incompatible settings will be cleared.'; fa = 'Template formatting or content does not meet format requirements. When you save the template, incompatible settings will be cleared.';
						|it = 'Template formatting or content does not meet format requirements. When you save the template, incompatible settings will be cleared.';
						|pl = 'Template formatting or content does not meet format requirements. When you save the template, incompatible settings will be cleared.';
						|tr = 'Formatlama şablonu veya içeriği, format gereksinimlerine uygun değil. Şablonu kaydettiğinizde, uygun olmayan ayarlar silinecektir.'");
	
	Buttons = New ValueList();
	Buttons.Add("ClearAndSave", NStr("vi = 'Xóa và lưu';
									|ru = 'Очистить и сохранить';
									|en = 'Clear and save'; fa = 'Clear and save';
									|it = 'Clear and save';
									|pl = 'Clear and save';
									|tr = 'Temizle ve kaydet'"));
	Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
								|ru = 'Отмена';
								|en = 'Cancel'; fa = 'انصراف';
								|it = 'Cancel';
								|pl = 'Cancel';
								|tr = 'İptal'"));
	
	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.Picture = PictureLib.DialogExclamation;
	QuestionParameters.DefaultButton = "ClearAndSave";
	QuestionParameters.PromptDontAskAgain = False;
	QuestionParameters.Title = "";
	
	StandardSubsystemsClient.ShowQuestionToUser(Notification, WarningText, Buttons, QuestionParameters);
	
EndProcedure

&AtClient 
Procedure StartPropertyDeletionDialogCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> Undefined Then
		
		If QuestionResult.Value = "ClearAndSave" Then
			
			CompletionHandler = AdditionalParameters.CompletionHandler;
			UnlockFile = AdditionalParameters.UnlockFile;
			
			DeleteUnusedProperties();
			WriteSpreadsheetDocumentFileNameSelected(CompletionHandler, UnlockFile);
			NotifyAboutTheTableDocumentEntry();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteUnusedProperties()
	
	ProcessSpreadsheetDocumentAreas();
	
	FormatsWithoutTextFormatting = ExportFormatsNotRequiringTextManagement();
	
	If FormatsWithoutTextFormatting.Find(ExportSaveFormat) <> Undefined Then
		
		For LineNumber = 1 To SpreadsheetDocument.TableHeight Do
			
			For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
				
				Area = SpreadsheetDocument.Area(LineNumber, ColumnNumber);
				ClearAreaFormat(Area);
				Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSpreadsheetDocumentAreas()
	
	ExportFormatsWithAreas =  ExportFormatsAreasAllowed();
	FormatsWithPictures = ExportFormatsPicturesAllowed();
	
	ArrayOfPictureAreas = New Array;
	ArrayOfForbiddenAreas = New Array;
	
	If FormatsWithPictures.Find(ExportSaveFormat) = Undefined Then
		
		For Each CurrentArea In SpreadsheetDocument.Drawings Do
			ArrayOfPictureAreas.Add(CurrentArea);
		EndDo;
		
	EndIf;
	
	TableToAnalyze = TableOfAreas(SpreadsheetDocument, True);
	
	For Each CurrentTableRow In TableToAnalyze Do
		
		If CurrentTableRow.IsOutputConditionArea
		 Or CurrentTableRow.IsPictureArea Then
			Continue;
		EndIf;
		
		CurrentArea = SpreadsheetDocument.Area(CurrentTableRow.Name);
		
		If ExportFormatsWithAreas.Find(ExportSaveFormat) = Undefined Then
			
			ArrayOfForbiddenAreas.Add(CurrentArea);
			
		Else
			
			If CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rows Then
				
				ArrayOfForbiddenAreas.Add(CurrentArea);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each CurrentArea In ArrayOfPictureAreas Do
		SpreadsheetDocument.Drawings.Delete(CurrentArea);
	EndDo;
	
	For Each CurrentArea In ArrayOfForbiddenAreas Do
		CurrentArea.Name = "";
	EndDo;
	
EndProcedure

&AtClient
Function HasFormattingAndAreasNotUsedInExportFormat()
	
	HasUnusedModifications = HasAreasNotUsedInExportFormat();
	
	FormatsWithoutTextFormatting = ExportFormatsNotRequiringTextManagement();
	
	If Not HasUnusedModifications
	   And FormatsWithoutTextFormatting.Find(ExportSaveFormat) <> Undefined Then
		
		NewShreadsheet = New SpreadsheetDocument;
		DefaultArea = NewShreadsheet.Area(1, 1, 1, 1);
		DefaultFont = DefaultArea.Font;
		DefaultColor = DefaultColor();
		
		For LineNumber = 1 To SpreadsheetDocument.TableHeight Do
			
			For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
				
				Area = SpreadsheetDocument.Area(LineNumber, ColumnNumber);
				
				HasUnusedModifications = IsAreaModified(
					Area,
					DefaultArea,
					DefaultFont,
					DefaultColor);
				
				If HasUnusedModifications Then
					Break;
				EndIf;
				
			EndDo;
			
			If HasUnusedModifications Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return HasUnusedModifications;
	
EndFunction

&AtClient
Function IsAreaModified(Area, DefaultArea, DefaultFont, DefaultColor)
	
	Return Not (Area.Font = DefaultFont
		And Area.BorderColor = DefaultColor
		And Area.TextColor = DefaultColor
		And Area.PatternColor = DefaultColor
		And Area.BackColor = DefaultColor
		And Area.VerticalAlign = DefaultArea.VerticalAlign
		And Area.PictureVerticalAlign = DefaultArea.PictureVerticalAlign
		And Area.HorizontalAlign = DefaultArea.HorizontalAlign
		And Area.PictureHorizontalAlign = DefaultArea.PictureHorizontalAlign
		And Area.TextPlacement = SpreadsheetDocumentTextPlacementType.Auto);
	
EndFunction

&AtServer
Function HasAreasNotUsedInExportFormat()
	
	HasForbiddenAreas = False;
	HasAreasWithPictures = False;
	
	ExportFormatsWithAreas =  ExportFormatsAreasAllowed();
	FormatsWithPictures = ExportFormatsPicturesAllowed();
	
	TableToAnalyze = TableOfAreas(SpreadsheetDocument, True);
	
	For Each CurrentTableRow In TableToAnalyze Do
		
		If CurrentTableRow.IsOutputConditionArea
		 Or CurrentTableRow.IsPictureArea Then
			Continue;
		EndIf;
		
		If ExportFormatsWithAreas.Find(ExportSaveFormat) = Undefined Then
			
			HasForbiddenAreas = True;
			Break;
			
		Else
			
			CurrentArea = SpreadsheetDocument.Area(CurrentTableRow.Name);
			
			If CurrentArea.AreaType <> SpreadsheetDocumentCellAreaType.Rows Then
				
				HasForbiddenAreas = True;
				Break;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If FormatsWithPictures.Find(ExportSaveFormat) = Undefined Then
		
		HasAreasWithPictures = (SpreadsheetDocument.Drawings.Count() > 0);
		
	EndIf;
	
	Return Max(HasForbiddenAreas, HasAreasWithPictures);
	
EndFunction

&AtServer
Procedure CheckConditionsAreas(Val TableOfAreas, Cancel)
	
	AreaRowNumber = 0;
	For Each TemplateArea In TableOfAreas Do
		
		If AreaRowNumber <> TemplateArea.Top Then
			
			AreaRowNumber = TemplateArea.Top;
			Continue;
			
		EndIf;
		
		If TemplateArea.IsOutputConditionArea Then
			
			Template = NStr("vi = 'Vùng điều kiện phải nằm dưới vùng đối tượng chủ ít nhất một dòng (dòng %1)';
							|ru = 'Область условия должна располагаться ниже области владельца хотя бы на одну строку (стр. %1)';
							|en = 'Condition area must be placed at least one row below the owner area (row %1)'; fa = 'Condition area must be placed at least one row below the owner area (row %1)';
							|it = 'Condition area must be placed at least one row below the owner area (row %1)';
							|pl = 'Condition area must be placed at least one row below the owner area (row %1)';
							|tr = 'Koşul alanı, sahip alanının en az bir satır altında yer almalıdır (sf. %1)'");
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				TemplateArea.Top);
			Common.MessageToUser(ErrorText,,,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckAreaNames(Val TableOfAreas, Cancel)
	
	If ExportSaveFormat <> Enums.ObjectsExportFormats.XML Then
		Return;
	EndIf;
	
	ForbiddenSubstring = "xml";
	TemplateNotCompliant = NStr("vi = 'Tên vùng ""%1"": không tương ứng với các yêu cầu cho tên token XML (dòng %2)';
								|ru = 'Имя области ""%1"" не соответствует требованиям к именам токенов XML (стр. %2)';
								|en = 'Area name ""%1"" does not comply with XML token naming convention (row %2)'; fa = 'Area name ""%1"" does not comply with XML token naming convention (row %2)';
								|it = 'Area name ""%1"" does not comply with XML token naming convention (row %2)';
								|pl = 'Area name ""%1"" does not comply with XML token naming convention (row %2)';
								|tr = 'Bölge adı ""%1"", XML token''ları için gereksinimleri karşılamıyor (sf. %2)'");
	TemplateForbiddenString = NStr("vi = 'Tên vùng ""%1"" không bắt đầu từ ""%2"" (dòng %3)';
									|ru = 'Имя области ""%1"" не может начинаться с ""%2"" (стр. %3)';
									|en = 'Area name ""%1"" must not start with ""%2"" (row %3)'; fa = 'Area name ""%1"" must not start with ""%2"" (row %3)';
									|it = 'Area name ""%1"" must not start with ""%2"" (row %3)';
									|pl = 'Area name ""%1"" must not start with ""%2"" (row %3)';
									|tr = 'Bölge adı ""%1"", ""%2"" ile başlayamaz (sf. %3)'");
	
	For Each TemplateArea In TableOfAreas Do
		
		If TemplateArea.IsOutputConditionArea Then
			Continue;
		EndIf;
		
		AreaName = TemplateArea.Name;
		NamesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(AreaName, "_");
		
		If NamesArray.Count() = 1 Then
			
			CheckResult = TextMeetsNamingRequirements(AreaName,, ForbiddenSubstring);
			
			If CheckResult.HasForbiddenSubstring Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateForbiddenString,
					AreaName,
					ForbiddenSubstring,
					TemplateArea.Top);
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
			If Not CheckResult.MeetsNamingRequirements Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateNotCompliant,
					AreaName,
					TemplateArea.Top);
				Common.MessageToUser(ErrorText,,,, Cancel);
				
			EndIf;
			
		Else
			
			CheckAreaNamesArray(AreaName, NamesArray, TemplateArea, ForbiddenSubstring, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckAreaNamesArray(Val AreaName, Val NamesArray, TemplateArea, ForbiddenSubstring, Cancel)
	
	Top = TemplateArea.Top;
	ArrayCounter = 0;
	FirstSubstringNumber = 1;
	SecondSubstringNumber = 2;
	
	TemplateNotCompliantBefore = NStr("vi = 'Phần tên vùng ""%1"" trước ký tự đầu tiên ''_'' không tương ứng với các yêu cầu cho tên token XML (dòng %2)';
										|ru = 'Часть имени области ""%1"" до первого символа ''_'' не соответствует требованиям к именам токенов XML (стр. %2)';
										|en = 'The portion of the area name ""%1"" before the first underscore does not comply with XML token naming conventions (row %2)'; fa = 'The portion of the area name ""%1"" before the first underscore does not comply with XML token naming conventions (row %2)';
										|it = 'The portion of the area name ""%1"" before the first underscore does not comply with XML token naming conventions (row %2)';
										|pl = 'The portion of the area name ""%1"" before the first underscore does not comply with XML token naming conventions (row %2)';
										|tr = '""%1"" bölge adının ilk ""_"" karakterine kadar olan kısmı, XML token''ları için gereksinimleri karşılamıyor (sf. %2)'");
	TemplateNotCompliantAfter = NStr("vi = 'Phần tên vùng ""%1"" sau ký tự đầu tiên ''_'' không tương ứng với các yêu cầu cho tên token XML (dòng %2)';
									|ru = 'Часть имени области ""%1"" после первого символа ''_'' не соответствует требованиям к именам токенов XML (стр. %2)';
									|en = 'The portion of the area name ""%1"" after the first underscore does not comply with XML token naming conventions (row %2)'; fa = 'The portion of the area name ""%1"" after the first underscore does not comply with XML token naming conventions (row %2)';
									|it = 'The portion of the area name ""%1"" after the first underscore does not comply with XML token naming conventions (row %2)';
									|pl = 'The portion of the area name ""%1"" after the first underscore does not comply with XML token naming conventions (row %2)';
									|tr = '""%1"" bölge adının ilk ""_"" karakterinden sonraki kısmı, XML token''ları için gereksinimleri karşılamıyor (sf. %2)'");
	TemplateForbiddenString = NStr("vi = 'Tên vùng không bắt đầu từ ""%1"" (dòng %2) ';
									|ru = 'Имя области не может начинаться с ""%1"" (стр. %2)';
									|en = 'Area name must not start with ""%1"" (row %2)'; fa = 'Area name must not start with ""%1"" (row %2)';
									|it = 'Area name must not start with ""%1"" (row %2)';
									|pl = 'Area name must not start with ""%1"" (row %2)';
									|tr = 'Bölge adı ""%1"" ile başlayamaz (sf. %2)'");
	TemplateForbiddenStringAfter = NStr("vi = 'Phần tên vùng ""%1"" sau ký tự đầu tiên ''_'' không thể bắt đầu từ  ""%2"" (dòng %3)';
										|ru = 'Часть имени области ""%1"" после первого символа ''_'' не может начинаться с ""%2"" (стр. %3)';
										|en = 'The portion of the area name ""%1"" after the first underscore must not start with ""%2"" (row %3)'; fa = 'The portion of the area name ""%1"" after the first underscore must not start with ""%2"" (row %3)';
										|it = 'The portion of the area name ""%1"" after the first underscore must not start with ""%2"" (row %3)';
										|pl = 'The portion of the area name ""%1"" after the first underscore must not start with ""%2"" (row %3)';
										|tr = '""%1"" bölge adının ilk ""_"" karakterinden sonraki kısmı ""%2"" ile başlayamaz (sf. %3)'");
	
	For Each CurrentName In NamesArray Do
		
		ArrayCounter = ArrayCounter + 1;
		
		If ArrayCounter > SecondSubstringNumber Then
			Break;
		EndIf;
		
		CheckResult = TextMeetsNamingRequirements(CurrentName,, ForbiddenSubstring);
		
		If CheckResult.HasForbiddenSubstring Then
			
			If ArrayCounter = FirstSubstringNumber Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateForbiddenString,
					AreaName,
					ForbiddenSubstring,
					Top);
				
			Else
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateForbiddenStringAfter,
					AreaName,
					ForbiddenSubstring,
					Top);
				
			EndIf;
			Common.MessageToUser(ErrorText,,,, Cancel);
			
		EndIf;
		
		If Not CheckResult.MeetsNamingRequirements Then
			
			If ArrayCounter = FirstSubstringNumber Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateNotCompliantBefore,
					AreaName,
					Top);
				
			Else
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					TemplateNotCompliantAfter,
					AreaName,
					Top);
				
			EndIf;
			Common.MessageToUser(ErrorText,,,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckAreasOverlap(Val TableOfAreas, Cancel)
	
	AreasTableToQuery = TableOfAreas.Copy();
	AreasTableToQuery.Columns.Add("AreaNumber", New TypeDescription("Number"));
	AreasTableToQuery.Columns.Top.Name = "TopOfArea";
	AreasTableToQuery.Columns.Bottom.Name = "BottomOfArea";
	
	LineCounter = 0;
	For Each CurrentRow In AreasTableToQuery Do
		
		LineCounter = LineCounter + 1;
		CurrentRow.AreaNumber = LineCounter;
		
	EndDo;
	
	Query = New Query;
	Query.SetParameter("TableOfAreas", AreasTableToQuery);
	Query.Text =
	"SELECT
	|	TableOfAreas.Name AS Name,
	|	TableOfAreas.TopOfArea AS TopOfArea,
	|	TableOfAreas.BottomOfArea AS BottomOfArea,
	|	TableOfAreas.AreaNumber AS AreaNumber
	|INTO TT_TableOfAreas
	|FROM
	|	&TableOfAreas AS TableOfAreas
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_TableOfAreas.Name AS AreaName,
	|	TT_AreasTableOverlap.Name AS AreaNameIntersections
	|FROM
	|	TT_TableOfAreas AS TT_TableOfAreas
	|		INNER JOIN TT_TableOfAreas AS TT_AreasTableOverlap
	|		ON TT_TableOfAreas.TopOfArea < TT_AreasTableOverlap.TopOfArea
	|			AND TT_TableOfAreas.BottomOfArea < TT_AreasTableOverlap.BottomOfArea
	|			AND TT_TableOfAreas.BottomOfArea >= TT_AreasTableOverlap.TopOfArea
	|			AND TT_TableOfAreas.AreaNumber <> TT_AreasTableOverlap.AreaNumber
	|
	|ORDER BY
	|	TT_TableOfAreas.AreaNumber";
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Template = NStr("vi = 'Đối với kiểu khuôn in kết xuất ""%1"" không cho phép giao nhau giữa các vùng ""%2"" và ""%3""';
						|ru = 'Для типа макета выгрузки ""%1"" не допускается пересечение областей ""%2"" и ""%3""';
						|en = 'Export templates of type ""%1"" do not support overlapping or areas ""%2"" and ""%3""'; fa = 'Export templates of type ""%1"" do not support overlapping or areas ""%2"" and ""%3""';
						|it = 'Export templates of type ""%1"" do not support overlapping or areas ""%2"" and ""%3""';
						|pl = 'Export templates of type ""%1"" do not support overlapping or areas ""%2"" and ""%3""';
						|tr = 'Yükleme şablonu türü ""%1"" için ""%2"" ve ""%3"" alanları arasında çakışmaya izin verilmez'");
		Selection = Result.Select();
		While Selection.Next() Do
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				Template,
				ExportSaveFormat,
				Selection.AreaName,
				Selection.AreaNameIntersections);
			Common.MessageToUser(ErrorText,,,, Cancel);
		
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckForTableInclusion(Val Template, Val TableOfAreas, Cancel)
	
	If Not Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Pattern) Then
		Return;
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	ModuleExportObjectsToFiles = Common.CommonModule("ExportObjectsToFiles");
	
	FieldsCollection = ThisObject[NameOfTheFieldList()];
	
	Objects = CommonClientServer.ValueInArray(Pattern);
	DisplayedFields = FillListDisplayedFields(FieldsCollection);
	
	Try
		
		PrintData = ModulePrintManager.PrintData(Objects, DisplayedFields, CurrentLanguage);
		
	Except
		
		UnlockDataForEdit(KeyOfEditObject, UUID);
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
	TemplateAreas = ModulePrintManager.TemplateAreas(Template, PrintData);
	AreasTables = TemplateAreas.AreasTables;
	
	TemplateTables = ModuleExportObjectsToFiles.TemplateTables(Template, AreasTables);
	AreasTemplateTables = TemplateTables.Copy();
	AreasTemplateTables.Clear();
	AreasTemplateTables.Columns.Add("AreaName", New TypeDescription("String"));
	
	For Each TemplateCurrentTable In TemplateTables Do 
		
		TableTop = TemplateCurrentTable.Top;
		TableBottom = TemplateCurrentTable.Bottom;
		MaxAreaTop = 0;
		MinAreaBottom = 9999999999;
		
		For Each CurrentArea In TableOfAreas Do
			
			If CurrentArea.IsOutputConditionArea Then
				Continue;
			EndIf;
			
			TopOfArea = CurrentArea.Top;
			BottomOfArea = CurrentArea.Bottom;
			
			If TopOfArea <= TableTop
			   And BottomOfArea >= TableBottom Then
				
				MaxAreaTop = Max(MaxAreaTop, TopOfArea);
				MinAreaBottom = Min(MinAreaBottom, BottomOfArea);
				
			EndIf;
			
		EndDo;
		
		If MaxAreaTop <> 0 Then
			
			Filter = New Structure;
			Filter.Insert("Top", MaxAreaTop);
			Filter.Insert("Bottom", MinAreaBottom);
			FoundRows = TableOfAreas.FindRows(Filter);
			
			If FoundRows.Count() Then
				
				AreaName = FoundRows[0].Name;
				NewRow = AreasTemplateTables.Add();
				FillPropertyValues(NewRow, TemplateCurrentTable);
				NewRow.AreaName = AreaName;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	AreasTemplateTables.Sort("AreaName, Top");
	AnalyzeAreasTemplateTable(AreasTemplateTables, TableOfAreas, Cancel);
	
EndProcedure

&AtServer
Procedure AnalyzeAreasTemplateTable(Val AreasTemplateTables, Val TableOfAreas, Cancel)
	
	If AreasTemplateTables.Count() <= 1 Then
		Return;
	EndIf;
	
	For Each CurrentArea In TableOfAreas Do
		
		If CurrentArea.IsOutputConditionArea Then
			Continue;
		EndIf;
		
		AreaName = CurrentArea.Name;
		Filter = New Structure;
		Filter.Insert("AreaName", AreaName);
		
		FoundRows = AreasTemplateTables.FindRows(Filter);
		
		If FoundRows.Count() <= 1 Then
			Continue;
		EndIf;
			
		TableName = FoundRows[0].Name;
		
		For Each FoundRow In FoundRows Do
			
			TableNameCurrent = FoundRow.Name;
			
			If TableName = TableNameCurrent Then
				Continue;
			EndIf;
			
			Template = NStr("vi = 'Trong vùng ""%1""đã có bảng ""%2"". Vùng có thể chứa chỉ một bảng (dòng %3)';
							|ru = 'В области ""%1"" уже есть таблица ""%2"". Область может содержать только одну таблицу (стр. %3)';
							|en = 'Area ""%1"" already contains table ""%2"". An area can contain only one table (row %3)'; fa = 'Area ""%1"" already contains table ""%2"". An area can contain only one table (row %3)';
							|it = 'Area ""%1"" already contains table ""%2"". An area can contain only one table (row %3)';
							|pl = 'Area ""%1"" already contains table ""%2"". An area can contain only one table (row %3)';
							|tr = '""%1"" bölgesi içinde zaten bir tablo ""%2"" bulunmaktadır. Bir bölge yalnızca bir tablo içerebilir (sf. %3)'");
			
			TopOfArea = FoundRow.Top;
			BottomOfArea = FoundRow.Bottom;
			
			While TopOfArea <= BottomOfArea Do
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					AreaName,
					TableName,
					TopOfArea);
				Common.MessageToUser(ErrorText,,,, Cancel);
				TopOfArea = TopOfArea + 1;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckExportAreas(Val Template, Cancel)
	
	TableOfAreas = TableOfAreas(Template);
	AreAreasPresent = (TableOfAreas.Count() > 0);
	
	If AreAreasPresent Then
		
		ConditionsAreaError = False;
		CheckConditionsAreas(TableOfAreas, ConditionsAreaError);
		If ConditionsAreaError Then
			Cancel = True;
		EndIf;
		
		If ExportSaveFormat = Enums.ObjectsExportFormats.XML
		 Or ExportSaveFormat = Enums.ObjectsExportFormats.JSON Then
			
			If Not ConditionsAreaError Then
				
				CheckAreaNames(TableOfAreas, Cancel);
				
			EndIf;
			
			CheckAreasOverlap(TableOfAreas, Cancel);
			CheckForTableInclusion(Template, TableOfAreas, Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReplaceViewParameters(String, Field = Undefined, Cancel = False, FieldPresentation = "")
	
	ReplacementParameters = FormulasFromText(String(String));
	
	For Each Parameter In ReplacementParameters Do
		Formula = Parameter.Key;
		If StrOccurrenceCount(Formula, "[") > 1 Then
			Formula = Mid(Formula, 2, StrLen(Formula) - 2);
		EndIf;		
		
		ErrorText = "";
		If Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
			ModuleConstructorFormulaInternal = Common.CommonModule("FormulasConstructorInternal");
			ErrorText = ModuleConstructorFormulaInternal.CheckFormula(ThisObject, Formula);
		EndIf;
			
		If ValueIsFilled(ErrorText) Then
			If ValueIsFilled(FieldPresentation) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 (%2)';
						|ru = '%1 (%2)';
						|en = '%1 (%2)'; fa = '%1 (%2)';
						|it = '%1 (%2)';
						|pl = '%1 (%2)';
						|tr = '%1 (%2)'"),
					ErrorText,
					FieldPresentation);
			EndIf;
			
			Common.MessageToUser(ErrorText, , Field, , Cancel);
		EndIf;
	EndDo;
	
	If TypeOf(String) = Type("FormattedString") Then
		String = ReplaceInFormattedString(String, ReplacementParameters);
	Else
		String = ReplaceInline(String, ReplacementParameters);
	EndIf;
	
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
Function ReplaceInFormattedString(String, ReplacementParameters)

	FormattedDocument = New FormattedDocument;
	FormattedDocument.SetFormattedString(String);
	
	For Each Item In ReplacementParameters Do
		SearchSubstring = Item.Key;
		ReplaceSubstring = Item.Value;

		FoundArea = FormattedDocument.FindText(SearchSubstring);
		While FoundArea <> Undefined Do
			Particles = FormattedDocument.GenerateItems(FoundArea.BeginBookmark, FoundArea.EndBookmark);
			For IndexOf = 1 To Particles.UBound() Do
				Particles[0].Text = Particles[0].Text + Particles[IndexOf].Text;
				Particles[IndexOf].Text = "";
			EndDo;
			Particles[0].Text = StrReplace(Particles[0].Text, SearchSubstring, ReplaceSubstring);
	
			FoundArea = FormattedDocument.FindText(SearchSubstring, FoundArea.EndBookmark);
		EndDo;
	EndDo;
	
	Return FormattedDocument.GetFormattedString();

EndFunction

&AtServer
Function FormulasFromText(Val Text)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.FormulasFromText(Text, ThisObject);
	EndIf;
	
EndFunction

&AtServer
Function TheFormulaFromTheView(Presentation)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.TheFormulaFromTheView(ThisObject, Presentation);
	EndIf;
	
	Return Presentation;
	
EndFunction

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
Function ReadLayout(Val BinaryData = Undefined)
	
	LanguageCode = SpreadsheetDocument.LanguageCode;
	
	If BinaryData <> Undefined Then
		SpreadsheetDocument.LanguageCode = Undefined;
		SpreadsheetDocument.Read(BinaryData.OpenStreamForRead());
	EndIf;
	
	Template = CopySpreadsheetDocument(SpreadsheetDocument, LanguageCode);
	
	If Not IsPrintForm Then
		Return Template;
	EndIf;
	
	TreatedAreas = New Map();
	
	For LineNumber = 1 To Template.TableHeight Do
		For ColumnNumber = 1 To Template.TableWidth Do
			Area = Template.Area(LineNumber, ColumnNumber);

			If Common.SubsystemExists("StandardSubsystems.Print") Then
				ModulePrintManager = Common.CommonModule("PrintManagement");
				AreaID = ModulePrintManager.AreaID(Area);
				If TreatedAreas[AreaID] <> Undefined Then
					Continue;
				EndIf;
				TreatedAreas[AreaID] = True;
			EndIf;
			
			If ValueIsFilled(Area.Text) Then
				ReplaceParametersWithViews(Area.Text);
			EndIf;
		EndDo;
	EndDo;
	
	ReplaceParametersWithViews(Template.Header.LeftText);
	ReplaceParametersWithViews(Template.Header.CenterText);
	ReplaceParametersWithViews(Template.Header.RightText);
	ReplaceParametersWithViews(Template.Footer.LeftText);
	ReplaceParametersWithViews(Template.Footer.CenterText);
	ReplaceParametersWithViews(Template.Footer.RightText);
	
	FillDrilldownParameters(Template, True);
	RenameConditionalAreas(Template, LocalizedPrefixOfConditionalArea(), TemplateForObjectExport);
	
	Return Template;
	
EndFunction

&AtServer
Procedure ReplaceParametersWithViews(String)
	
	ReplacementParameters = RepresentationTextParameters(String(String));
	
	If TypeOf(String) = Type("FormattedString") Then
		String = ReplaceInFormattedString(String, ReplacementParameters);
	Else
		String = ReplaceInline(String, ReplacementParameters);
	EndIf;
	
EndProcedure

&AtServer
Function FormulaPresentation(Val Formula)
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		Return ModulePrintManager.FormulaPresentation(ThisObject, Formula);
	EndIf;
	
	Return Formula;
	
EndFunction

// Returns:
//  SpreadsheetDocument
//
&AtServerNoContext
Function CopySpreadsheetDocument(SpreadsheetDocument, LanguageCode)
	
	Result = New SpreadsheetDocument;
	Result.Template = SpreadsheetDocument.Template;
	Result.LanguageCode = LanguageCode;
	Result.Put(SpreadsheetDocument);
	
	ProcessedCells = New Map;
	For LineNumber = 1 To SpreadsheetDocument.TableHeight Do
		For ColumnNumber = 1 To SpreadsheetDocument.TableWidth Do
			CellToCopy = SpreadsheetDocument.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			
			If Common.SubsystemExists("StandardSubsystems.Print") Then
				ModulePrintManager = Common.CommonModule("PrintManagement");
				AreaID = ModulePrintManager.AreaID(CellToCopy);
				If ProcessedCells[AreaID] <> Undefined Then
					Continue;
				EndIf;
				ProcessedCells[AreaID] = True;
			EndIf;
			
			If CellToCopy.FillType = SpreadsheetDocumentAreaFillType.Text Then
				Continue;
			EndIf;
			
			Cell = Result.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			FillPropertyValues(Cell, CellToCopy, , "FormatOfRows");
			
			If CellToCopy.FillType = SpreadsheetDocumentAreaFillType.Template Then
				Cell.Text = CellToCopy.Text;
			EndIf;
		EndDo;
	EndDo;
	
	Result.Header.LeftText = SpreadsheetDocument.Header.LeftText;
	Result.Header.CenterText = SpreadsheetDocument.Header.CenterText;
	Result.Header.RightText = SpreadsheetDocument.Header.RightText;
	Result.Footer.LeftText = SpreadsheetDocument.Footer.LeftText;
	Result.Footer.CenterText = SpreadsheetDocument.Footer.CenterText;
	Result.Footer.RightText = SpreadsheetDocument.Footer.RightText;
	
	TableOfAreas = TableOfAreas(SpreadsheetDocument, True);
	For Each CurrentArea In TableOfAreas Do
		
		Area = Result.Areas.Find(CurrentArea.Name);
		If Area = Undefined Then
			Continue;
		EndIf;

		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
			And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows
			Or TypeOf(Area) = Type("SpreadsheetDocumentDrawing") 
			And Area.DrawingType <> SpreadsheetDocumentDrawingType.Group Then
				CopyArea = SpreadsheetDocument.Areas.Find(Area.Name);
				If CopyArea = Undefined Then
					Continue;
				EndIf;
				Area.DetailsParameter = CopyArea.DetailsParameter;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction	

&AtClientAtServerNoContext
Procedure ReadTextInFooterField(Val Text, HeaderOrFooter)
	
	FormattedString = Text;
	If TypeOf(Text)  = Type("String") Then
		FormattedString = New FormattedString(Text);
	EndIf;

	HeaderOrFooter.SetFormattedString(FormattedString);
	
EndProcedure

&AtClient
Procedure ToggleVisibilityCommandsFooters()
	
	If CurrentItem = Items.TopLeftText
		Or CurrentItem = Items.TopMiddleText
		Or CurrentItem = Items.TopRightText
		Or CurrentItem = Items.BottomLeftText
		Or CurrentItem = Items.BottomCenterText
		Or CurrentItem = Items.BottomRightText Then
	
		ToggleItemVisibility(Items.CommandsTextLeftHeader, CurrentItem = Items.TopLeftText);
		ToggleItemVisibility(Items.CommandsTextInCenterHeader, CurrentItem = Items.TopMiddleText);
		ToggleItemVisibility(Items.CommandsTextHeaderRight, CurrentItem = Items.TopRightText);

		ToggleItemVisibility(Items.CommandsTextLeftFooter, CurrentItem = Items.BottomLeftText);
		ToggleItemVisibility(Items.CommandsTextInCenterFooter, CurrentItem = Items.BottomCenterText);
		ToggleItemVisibility(Items.CommandsTextFooterRight, CurrentItem = Items.BottomRightText);
	
	EndIf;
	
	AttachIdleHandler("ToggleVisibilityCommandsFooters", 0.5, True);
	
EndProcedure

&AtClient
Procedure ToggleItemVisibility(Item, Visible)
	
	If Item.Visible <> Visible Then
		Item.Visible = Visible;
	EndIf;

EndProcedure

&AtServer
Function WriteTemplate(AbortRecordingIfThereAreErrorsInLayout = False, TemplateAddressInTempStorage = "")
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		Cancel = False;

		If Not ValueIsFilled(TemplateAddressInTempStorage) Then
			If IsPrintForm Then
				Template = PrepareLayoutForRecording(, Cancel);
			Else
				Template = SpreadsheetDocument;
			EndIf;
			
			TemplateAddressInTempStorage = PutToTempStorage(Template, UUID);
		EndIf;
		
		If Cancel And AbortRecordingIfThereAreErrorsInLayout Then
			Return False;
		EndIf;
		
		ModulePrintManager = Common.CommonModule("PrintManagement");
		TemplateDetails = ModulePrintManager.TemplateDetails();
		TemplateDetails.TemplateMetadataObjectName = IdentifierOfTemplate;
		TemplateDetails.TemplateAddressInTempStorage = TemplateAddressInTempStorage;
		TemplateDetails.LanguageCode = CurrentLanguage;
		TemplateDetails.Description = DocumentName;
		TemplateDetails.Ref = RefTemplate;
		TemplateDetails.TemplateType = "MXL";
		TemplateDetails.DataSources = DataSources.UnloadValues();
		TemplateDetails.DefaultPrintForm = DefaultPrintForm;
		TemplateDetails.PrintFormDescription = PrintFormDescription;
		TemplateDetails.TemplateForObjectExport = TemplateForObjectExport;
		TemplateDetails.ExportSaveFormat = ExportSaveFormat;
		
		IdentifierOfTemplate = ModulePrintManager.WriteTemplate(TemplateDetails);
		If Not ValueIsFilled(RefTemplate) Then
			RefTemplate = ModulePrintManager.RefTemplate(IdentifierOfTemplate);
		EndIf;
		
		WriteTemplatesInAdditionalLangs();
		
		If Not Items.Language.Enabled Then
			
			Items.Language.Enabled  = True;
			FillPropertyValues(Parameters, TemplateDetails);
			
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

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
	
	ColumnNamePresentation = NameOfTheFieldList() + "Presentation";
	If Common.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaInternal = Common.CommonModule("FormulasConstructorInternal");
		ColumnNamePresentation = ModuleConstructorFormulaInternal.ColumnNamePresentation(NameOfTheFieldList());
	EndIf;
	
	ColumnPresentation = Items[ColumnNamePresentation];
	ColumnPresentation.Title = NStr("vi = 'Trường';
									|ru = 'Поле';
									|en = 'Field'; fa = 'فیلد';
									|it = 'Campo';
									|pl = 'Field';
									|tr = 'Alan'");
	
	ColumnPattern = Items.Add(NameOfTheFieldList() + "Pattern", Type("FormField"), FieldList);
	ColumnPattern.DataPath = NameOfTheFieldList() + "." + "Pattern";
	ColumnPattern.Type = FormFieldType.InputField;
	ColumnPattern.Title = NStr("vi = 'Mẫu';
								|ru = 'Образец';
								|en = 'Preview'; fa = 'پیش‌نمایش';
								|it = 'Esempio';
								|pl = 'Preview';
								|tr = 'Örnek'");
	ColumnPattern.SetAction("OnChange", "Attachable_SampleWhenChanging");
	ColumnPattern.ShowInFooter = False;
	ColumnPattern.ClearButton = True;
	
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

&AtClient
Procedure Attachable_AvailableFieldsWhenLineIsActivated(Item)
	
	CurrentData = Items[NameOfTheFieldList()].CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.GetParent() = Undefined Then
		Items["SearchString" + NameOfTheFieldList()].InputHint = PromptInputStringSearchFieldList();
	Else
		Items["SearchString" + NameOfTheFieldList()].InputHint = CurrentData.RepresentationOfTheDataPath;
	EndIf;

	SystemInfo = New SystemInfo;
	PlatformVersion = SystemInfo.AppVersion;

	AttachIdleHandler("HighlightCellsWithSelectedField", 0.1, True);
	
EndProcedure

&AtClient
Procedure Attachable_AvailableFieldsBeforeStartOfChange(Item, Cancel)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FormulasConstructor") Then
		ModuleConstructorFormulaClient = CommonClient.CommonModule("FormulasConstructorClient");
		
		CurrentData = Items[NameOfTheFieldList()].CurrentData;
		CurrentData.Pattern = CurrentData.Value;
		InputField = Items[NameOfTheFieldList() + "Pattern"];
		SelectedField = ModuleConstructorFormulaClient.TheSelectedFieldInTheFieldList(ThisObject, NameOfTheFieldList());
		InputField.TypeRestriction = SelectedField.Type;
	EndIf;
	
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
	
	If Items.LayoutPages.CurrentPage = Items.PagePreview Then
		GeneratePrintForm();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RenameConditionalAreas(Template, Prefix, TemplateForExport)
	
	If TemplateForExport Then
		Return;
	EndIf;
	
	Areas = New Array;
	
	For Each Area In Template.Areas Do
		If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			Areas.Add(Area);
			
		EndIf;
	EndDo;

	For Each Area In Areas Do
		PickupRegionName(Template, Prefix, Area);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function PickupRegionName(Val SpreadsheetDocument, Val Prefix, Area = Undefined)
	
	UsedNames = New Map;
	
	For Each Item In SpreadsheetDocument.Areas Do
		If Area = Undefined Or Item.Name <> Area.Name Then
			UsedNames.Insert(Item.Name, True);
		EndIf;
	EndDo;
	
	IndexOf = 1;
	While UsedNames[AreaName(Prefix, IndexOf)] <> Undefined Do
		IndexOf = IndexOf + 1;
	EndDo;
	
	NewAreaName = AreaName(Prefix, IndexOf);
	
	If Area <> Undefined And Area.Name <> NewAreaName Then
		Area.Name = NewAreaName;
	EndIf;
	
	Return NewAreaName;
	
EndFunction

&AtClientAtServerNoContext
Function AreaName(AreaName, IndexOf)
	
	Return AreaName + Format(IndexOf, "NG=0;");
	
EndFunction

&AtClientAtServerNoContext
Function PromptInputStringSearchFieldList()
	
	Return NStr("vi = 'Tìm kiếm trường...';
				|ru = 'Найти поле...';
				|en = 'Find field…'; fa = 'Find field…';
				|it = 'Trovare campo...';
				|pl = 'Znajdź pole...';
				|tr = 'Alan bul...'");
	
EndFunction

&AtClient
Procedure ViewPrintableForm(Command)
	
	If Items.ViewPrintableForm.Check Then
		Items.LayoutPages.CurrentPage = Items.PageTemplate;
	Else
		If Not ValueIsFilled(Pattern) Then
			Items[NameOfTheFieldList()].CurrentRow = ThisObject[NameOfTheFieldList()].GetItems()[0].GetID();
			CommonClient.MessageToUser(
				NStr("vi = 'Hãy chọn mẫu để tạo mẫu in';
					|ru = 'Выберите образец, по данным которого будет формироваться печатная форма';
					|en = 'Select a template whose data will be used to generate a print form'; fa = 'Select a template whose data will be used to generate a print form';
					|it = 'Selezionare esempio in base ai cui dati sarà creato il modulo di stampa';
					|pl = 'Wybierz wzór, według danych którego będzie utworzony formularz wydruku';
					|tr = 'Yazdırma formunun bilgilerine dayanarak oluşturulacak örneklemi seçin'"), , NameOfTheFieldList() + "[0].Pattern");
			Return;
		EndIf;
		
		ExportFormats = New Array; // Array of EnumRef.ObjectsExportFormats
		ExportFormats.Add(PredefinedValue("Enum.ObjectsExportFormats.JSON"));
		ExportFormats.Add(PredefinedValue("Enum.ObjectsExportFormats.XML"));
		
		If ExportFormats.Find(ExportSaveFormat) <> Undefined Then
			
			ClearMessages();
			GenerateExportStructure();
			Items.LayoutPages.CurrentPage = Items.PageExportPreview;
			
		Else
			
			GeneratePrintForm();
			Items.LayoutPages.CurrentPage = Items.PagePreview;
			
		EndIf;
		
	EndIf;
	
	Items.ViewPrintableForm.Check = Not Items.ViewPrintableForm.Check;
	Items.SettingsCurrentRegion.Visible = Not Items.ViewPrintableForm.Check;
	Items.SecondCommandBar.Enabled = Not Items.ViewPrintableForm.Check;
	Items.ShowHeadersAndFooters.Enabled = Not Items.ViewPrintableForm.Check;
	Items.ActionsWithDocument.Enabled = Not Items.ViewPrintableForm.Check;
	Items.Language.Enabled = Not Items.ViewPrintableForm.Check;
	Items.ExportSaveFormat.Enabled = Not Items.ViewPrintableForm.Check;
	
EndProcedure

&AtServer
Procedure GeneratePrintForm()
	
	References = CommonClientServer.ValueInArray(Pattern);
	PrintObjects = New ValueList;
	Template = PrepareLayoutForRecording();
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		PrintForm = ModulePrintManager.GenerateSpreadsheetDocument(
			Template, References, PrintObjects, CurrentLanguage);
	EndIf;
	
EndProcedure

&AtServer
Procedure GenerateExportStructure()
	
	If Not Common.SubsystemExists("StandardSubsystems.ExportObjectsToFiles") Then
		Return;
	EndIf;
	
	Cancel = False;
	Template = PrepareLayoutForRecording(, Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	References = CommonClientServer.ValueInArray(Pattern);
	Upload0 = "";
	
	ModuleExportObjectsToFiles = Common.CommonModule("ExportObjectsToFiles");
	Result = ModuleExportObjectsToFiles.GenerateStructureForExport(
		Template,
		ExportSaveFormat,
		References,
		CurrentLanguage);
		
	StructureWithData = Result[Pattern];
	
	ExportPresentation = "";
	FullFileName = "";
	
	If ExportSaveFormat = Enums.ObjectsExportFormats.XML Then
		
		ModuleExportObjectsToFiles.ExecuteExportToXML(
			StructureWithData, 
			FullFileName,
			ExportPresentation);
		
	ElsIf ExportSaveFormat = Enums.ObjectsExportFormats.JSON Then
		
		ModuleExportObjectsToFiles.ExecuteExportToJSON(
			StructureWithData,
			FullFileName,
			ExportPresentation);
		
	EndIf;
	
	Upload0 = ExportPresentation;
	
EndProcedure

&AtClient
Procedure DeleteStampEP(Command)
	
	For Each Area In Items.SpreadsheetDocument.GetSelectedAreas() Do
		If StrStartsWith(Area.Name, "DSStamp") Then
			Area.Name = "";
#If WebClient Then
				// It is required for the display update
				Area.Protection = Area.Protection;
#EndIf
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteLayoutInCurrentLanguage()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.DeleteTemplate(IdentifierOfTemplate, CurrentLanguage);
	EndIf;
	
	LoadSpreadsheetDocumentFromMetadata(CurrentLanguage);
	If IsPrintForm Then
		FillSpreadsheetDocument(SpreadsheetDocument, ReadLayout());
	EndIf;
	
	Modified = False;
	
	If Not ValueIsFilled(CurrentLanguage) Or CurrentLanguage = Common.DefaultLanguageCode() Then
		Return;
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
	
EndProcedure

&AtClient
Procedure ContinueSavingToFile(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullFileName = SelectedFiles[0];
	
	ClearHighlight();
	Template = PrepareLayoutForRecording(False);
	Template.Write(FullFileName);
	
EndProcedure

&AtClient
Procedure ContinueDownloadFromFile(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullFileName = SelectedFiles[0];
	
	CallbackDescription = New CallbackDescription("ResumeImportFromFileAfterDataObtained", ThisObject);
	BeginCreateBinaryDataFromFile(CallbackDescription, FullFileName);
EndProcedure

&AtClient
Procedure ResumeImportFromFileAfterDataObtained(BinaryData, AdditionalParameters) Export
	
	FinishImportFromFile(BinaryData);
	Modified = True;
	
EndProcedure

&AtServer
Procedure FinishImportFromFile(Val BinaryData)
	
	LanguageCode = SpreadsheetDocument.LanguageCode;
	Template = ReadLayout(BinaryData);
	SpreadsheetDocument.LanguageCode = LanguageCode;
	
	FillSpreadsheetDocument(SpreadsheetDocument, Template);
	
EndProcedure

&AtClient
Procedure UpdateTextInCellsArea()
	
	CurrentArea = SpreadsheetDocument.CurrentArea;
	If CurrentArea = Undefined Or TypeOf(CurrentArea) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	Modified = True;
	
	If CurrentArea.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
		CurrentArea.Text = CurrentValue;
	ElsIf CurrentArea.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
		
		If Not TemplateForObjectExport Then
			
			CurrentArea.Name = "";
			
			InitializeFirstRowCell(CurrentArea);
			
			CurrentArea.DetailsParameter = CurrentValue;
			
			If ValueIsFilled(CurrentValue) Then
				PickupRegionName(SpreadsheetDocument, LocalizedPrefixOfConditionalArea(), CurrentArea);
			EndIf;
			
		Else
			
			RefreshUploadConditionArea(CurrentArea);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshUploadConditionArea(CurrentArea)
	
	AreaName = CurrentArea.Name;
	AreaID = DefaultRowsAreaName(CurrentArea);
	
	InitializeFirstRowCell(CurrentArea);
	
	CurrentArea.DetailsParameter = CurrentValue;
	
	If ValueIsFilled(CurrentValue)
	   And AreaName = AreaID Then
		
		PickupRegionName(SpreadsheetDocument, LocalizedPrefixOfConditionalArea(), CurrentArea);
		
	ElsIf Not ValueIsFilled(CurrentValue) Then
		
		CurrentArea.Name = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure InitializeFirstRowCell(CurrentArea)
	
	Area = SpreadsheetDocument.Area(CurrentArea.Top, 1, CurrentArea.Top, 1);
	If Area.Text = "" Then
		Area.Text = "";
	EndIf;
	
EndProcedure

// Name of default row area.
// 
// Parameters:
//  CurrentArea - SpreadsheetDocumentRange - current area
// 
// Returns:
//  String
//
&AtClientAtServerNoContext
Function DefaultRowsAreaName(CurrentArea)
	
	If CurrentArea = Undefined Then
		AreaName = "";
	ElsIf CurrentArea.Top = CurrentArea.Bottom Then
		AreaName = "R" + Format(CurrentArea.Top, "NG=0;");
	Else
		AreaName = "R" + Format(CurrentArea.Top, "NG=0;") + ":R" + Format(CurrentArea.Bottom, "NG=0;");
	EndIf;
	
	Return AreaName;
	
EndFunction

&AtServerNoContext
Function ConditionalAreaPrefix()
	
	Return "Condition" + "_";
	
EndFunction

&AtClientAtServerNoContext
Function LocalizedPrefixOfConditionalArea()
	
	Return NStr("vi = 'Điều kiện';
				|ru = 'Условие';
				|en = 'Condition'; fa = 'شرط';
				|it = 'Условие';
				|pl = 'Condition';
				|tr = 'Koşul'") + "_";
	
EndFunction

&AtClient
Procedure OnSelectingLayoutName(NewTemplateName, AdditionalParameters) Export
	
	If NewTemplateName = Undefined Then
		Return;
	EndIf;
	
	If DocumentName <> NewTemplateName Then
		Modified = True;
	EndIf;
	
	DocumentName = NewTemplateName;
	SetHeader();
	
EndProcedure

#EndRegion

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
			FieldDetails.GetItems().Clear();
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

&AtClient
Procedure OnChangeTemplateSettings(ParametersStructure)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print")
	   And Not TemplateForObjectExport Then
		
		CallbackDescription = New CallbackDescription(
			"CompleteOpeningTemplateSettings", ThisObject, New Structure("Form", ThisObject));
			
		ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
		ModulePrintManagerClient.OnChangeTemplateSettings(ParametersStructure, CallbackDescription);
	Else
		CallbackDescription = New CallbackDescription("OnSelectingLayoutName", ThisObject);
		ShowInputString(CallbackDescription, DocumentName, NStr("vi = 'Hãy nhập tên gọi khuôn in';
																|ru = 'Введите наименование макета';
																|en = 'Enter a template description'; fa = 'Enter a template description';
																|it = 'Inserire denominazione modello';
																|pl = 'Wprowadź nazwę makiety';
																|tr = 'Şablon adını girin'"), 100, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteOpeningTemplateSettings(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each KeyValue In Result Do
		
		AttributeName = KeyValue.Key;
		NewValue = Result[AttributeName];
		
		If NewValue <> ThisObject[AttributeName] Then
			ThisObject[AttributeName] = NewValue;
			Modified = True;
			
			If AttributeName = "DocumentName" Then
				SetHeader();
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ExportFormatsRequiringAreas()
	
	FormatArray = New Array;
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.JSON"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.XML"));
	
	Return FormatArray;
	
EndFunction

&AtClientAtServerNoContext
Function ExportFormatsNotRequiringTextManagement()
	
	FormatArray = New Array;
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.JSON"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.XML"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.DBF"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.ANSITXT"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.TXT"));
	
	Return FormatArray;
	
EndFunction

&AtClientAtServerNoContext
Function ExportFormatsAreasAllowed()
	
	FormatArray = New Array;
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.JSON"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.XML"));
	
	Return FormatArray;
	
EndFunction

&AtClientAtServerNoContext
Function ExportFormatsPicturesAllowed()
	
	FormatArray = New Array;
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.XLS"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.XLSX"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.HTML5"));
	FormatArray.Add(PredefinedValue("Enum.ObjectsExportFormats.MXL"));
	
	Return FormatArray;
	
EndFunction

&AtClientAtServerNoContext
Procedure TextControlButtonVisibility(Form)
	
	ExportSaveFormat = Form.ExportSaveFormat;
	TemplateForObjectExport = Form.TemplateForObjectExport;
	
	If Not TemplateForObjectExport Then
		Return;
	EndIf;
	
	Items = Form.Items;
	Items.ShowHeadersAndFooters.Visible = False;
	Items.RepeatAtTopofPage.Visible = False;
	Items.RepeatAtEndPage.Visible = False;
	
	ExportFormats = ExportFormatsNotRequiringTextManagement();
	ItemVisibility = (ExportFormats.Find(ExportSaveFormat) = Undefined);
	
	Items.TextFormatting.Visible = ItemVisibility;
	
	Items.SpreadsheetDocumentFont.Visible = ItemVisibility;
	Items.DecreaseFontSize.Visible = ItemVisibility;
	Items.IncreaseFontSize.Visible = ItemVisibility;
	
	Items.SpreadsheetDocumentBold.Visible = ItemVisibility;
	Items.SpreadsheetDocumentItalic.Visible = ItemVisibility;
	Items.SpreadsheetDocumentUnderline.Visible = ItemVisibility;
	
	Items.SpreadsheetDocumentAlignLeft.Visible = ItemVisibility;
	Items.SpreadsheetDocumentAlignCenter.Visible = ItemVisibility;
	Items.SpreadsheetDocumentAlignRight.Visible = ItemVisibility;
	Items.SpreadsheetDocumentJustify.Visible = ItemVisibility;
	
	Items.AlignTop.Visible = ItemVisibility;
	Items.AlignMiddle.Visible = ItemVisibility;
	Items.AlignBottom.Visible = ItemVisibility;
	
	Items.SpreadsheetDocumentBackColor.Visible = ItemVisibility;
	Items.SpreadsheetDocumentTextColor.Visible = ItemVisibility;
	Items.SpreadsheetDocumentBorderColor.Visible = ItemVisibility;
	Items.SpreadsheetDocumentClearFormat.Visible = ItemVisibility;
	
	Items.TextFormattingAllActions.Visible = ItemVisibility;
	
	Items.SpreadsheetFontAllActions.Visible = ItemVisibility;
	Items.DecreaseFontAllActions.Visible = ItemVisibility;
	Items.IncreaseFontAllActions.Visible = ItemVisibility;
	
	Items.SpreadsheetBoldAllActions.Visible = ItemVisibility;
	Items.SpreadsheetItalicAllActions.Visible = ItemVisibility;
	Items.SpreadsheetUnderlineAllActions.Visible = ItemVisibility;
	Items.StrikethroughAllActions.Visible = ItemVisibility;
	
	Items.SpreadsheetAlignLeftAllActions.Visible = ItemVisibility;
	Items.SpreadsheetDocAlignCenterAllActions.Visible = ItemVisibility;
	Items.SpreadsheetAlignRightAllActions.Visible = ItemVisibility;
	Items.SpreadsheetJustifyAllActions.Visible = ItemVisibility;
	
	Items.AlignTopAllActions.Visible = ItemVisibility;
	Items.AlignMiddleAllActions.Visible = ItemVisibility;
	Items.AlignBottomAllActions.Visible = ItemVisibility;
	
	Items.SpreadsheetBackgroundColorAllActions.Visible = ItemVisibility;
	Items.SpreadsheetTextColorAllActions.Visible = ItemVisibility;
	Items.SpreadsheetBorderColorAllActions.Visible = ItemVisibility;
	Items.SpreadsheetClearFormattingAllActions.Visible = ItemVisibility;
	
	Items.SpreadsheetDocumentMerge.Visible = ItemVisibility;
	
	Items.Drawings.Visible = ItemVisibility;
	Items.Picture.Visible = ItemVisibility;
	Items.Text.Visible = ItemVisibility;
	Items.Rectangle.Visible = ItemVisibility;
	Items.Line.Visible = ItemVisibility;
	Items.Ellipse.Visible = ItemVisibility;
	Items.Group.Visible = ItemVisibility;
	Items.Ungroup.Visible = ItemVisibility;
	
	Items.Boundaries.Visible = ItemVisibility;
	Items.SpreadsheetDocumentLeftBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentTopBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentRightBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentBottomBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentAllBorders.Visible = ItemVisibility;
	Items.SpreadsheetDocumentOutsideBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentInsideBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentThickOutsideBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentThickTopBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentThickBottomBorder.Visible = ItemVisibility;
	Items.SpreadsheetDocumentNoBorder.Visible = ItemVisibility;
	
	Items.Table.Visible = ItemVisibility; // ACC:351 - Standard "Table" spreadsheet submenu.
	
	Items.AlignmentAuto.Visible = ItemVisibility;
	Items.AlignmentWrap.Visible = ItemVisibility;
	Items.AlignmentFill.Visible = ItemVisibility;
	Items.AlignmentClip.Visible = ItemVisibility;
	Items.TextAlignmentMore.Visible = ItemVisibility;
	Items.AlignmentAutoMore.Visible = ItemVisibility;
	Items.AlignmentWrapMore.Visible = ItemVisibility;
	Items.AlignmentFillMore.Visible = ItemVisibility;
	Items.AlignmentClipMore.Visible = ItemVisibility;
	
EndProcedure

&AtClient
Procedure TextControlButtonAvailability(CurrentArea)
	
	ElementAvailability = (TypeOf(CurrentArea) = Type("SpreadsheetDocumentRange"));
	
	Items.Font.Enabled = ElementAvailability;
	Items.VerticalAlignment.Enabled = ElementAvailability;
	Items.SpreadsheetDocumentTextColor.Enabled = ElementAvailability;
	Items.SpreadsheetDocumentBorderColor.Enabled = ElementAvailability;
	Items.SpreadsheetDocumentClearFormat.Enabled = ElementAvailability;
	Items.TextFormattingAllActions.Enabled = ElementAvailability;
	Items.TextPlacement.Enabled = ElementAvailability;
	Items.TextAlignmentMore.Enabled = ElementAvailability;
	Items.SetName.Enabled = ElementAvailability;
	Items.RemoveName.Enabled = ElementAvailability;
	
EndProcedure

&AtClient
Function HasOpenBrackets(Text)
	
	OpenBracketsCount = StrOccurrenceCount(Text, "[");
	ClosedBracketsCount = StrOccurrenceCount(Text, "]");
	
	Return (OpenBracketsCount > ClosedBracketsCount);
	
EndFunction

&AtClient
Function DocumentCurrentArea()
	
	If AreaNameEditing <> "" Then
		Area = SpreadsheetDocument.Area(AreaNameEditing);
	Else
		Area = SpreadsheetDocument.CurrentArea;
	EndIf;
	
	If TypeOf(Area) = Type("SpreadsheetDocumentRange")
	   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
		Area = Undefined;
	EndIf;
	
	Return Area;
	
EndFunction

&AtClient
Procedure FillSelectedTextData(SelectedTextData)
	
	Text = "";
	InitialSelectionString = 0;
	InitialSelectionColumn = 0;
	SelectionFinalString = 0;
	SelectionFinalColumn = 0;
	Items.CurrentValue.GetTextSelectionBounds(
		InitialSelectionString,
		InitialSelectionColumn,
		SelectionFinalString,
		SelectionFinalColumn);
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(CurrentValue);
	For Cnt = 0 To InitialSelectionString - 1 Do
		Text = Text + TextDocument.GetLine(Cnt);
	EndDo;
	RowToAnalyze = TextDocument.GetLine(InitialSelectionString);
	RowToAnalyze = Left(RowToAnalyze, InitialSelectionColumn - 1);
	Text = Text + RowToAnalyze;
	
	SelectedTextData.Text = Text;
	SelectedTextData.InitialSelectionString = InitialSelectionString;
	SelectedTextData.InitialSelectionColumn = InitialSelectionColumn;
	SelectedTextData.SelectionFinalString = SelectionFinalString;
	SelectedTextData.SelectionFinalColumn = SelectionFinalColumn;
	
EndProcedure

&AtClient
Procedure AddBrackets(Operator, RecipientOfDraggedValue, DragValue, SelectingFromList = False)
	
	IsFunction = False;
	If ValueIsFilled(Operator.Parent)
	   And Not ValueIsFilled(Operator.ExpressionToInsert) Then
		
		OperatorsGroup = Operator.Parent; // see TheSelectedFieldInTheFieldList
		OperatorGroupName = OperatorsGroup.Name;
		IsFunction = Not (OperatorGroupName = "LogicalOperatorsAndConstants");
		
	EndIf;
	
	Area = DocumentCurrentArea();
	
	If Not IsFunction
	 Or Area = Undefined Then
		Return;
	EndIf;
	
	If AreaNameEditing = ""
	   And Not SelectingFromList Then
		
		SelectedTextData = New Structure;
		SelectedTextData.Insert("Text", "");
		SelectedTextData.Insert("InitialSelectionString", 0);
		SelectedTextData.Insert("InitialSelectionColumn", 0);
		SelectedTextData.Insert("SelectionFinalString", 0);
		SelectedTextData.Insert("SelectionFinalColumn", 0);
		
		RecipientOfDraggedValue = Items.CurrentValue;
		FillSelectedTextData(SelectedTextData);
		Text = SelectedTextData.Text;
		
		If Not HasOpenBrackets(Text) Then
			
			PreviousValue2 = DragValue;
			DragValue = "[" + DragValue + "]";
			
			SelectedText = Items.CurrentValue.SelectedText;
			If StrFind(SelectedText, PreviousValue2) > 0 Then
				SelectedText = StrReplace(SelectedText, PreviousValue2, DragValue);
			Else
				SelectedText = DragValue;
			EndIf;
			
			Items.CurrentValue.SelectedText = SelectedText;
			Move = 2;
			Items.CurrentValue.SetTextSelectionBounds(
				SelectedTextData.InitialSelectionString,
				SelectedTextData.InitialSelectionColumn,
				SelectedTextData.SelectionFinalString,
				SelectedTextData.SelectionFinalColumn + Move);
			
		Else
			
			Items.CurrentValue.SelectedText = DragValue;
			
		EndIf;
		
	Else
		
		DragValue = "[" + DragValue + "]";
		Area.Text = DragValue;
		
	EndIf;
	
EndProcedure

#EndRegion
