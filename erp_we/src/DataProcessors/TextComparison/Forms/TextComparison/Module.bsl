#Region Variables

&AtClient
Var EditorSBookmarks;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeFormData();
	
	TextForComparison1 = Parameters.TextForComparison1;
	TextForComparison2 = Parameters.TextForComparison2;
	TextDetails1 = Parameters.TextDetails1;
	TextDetails2 = Parameters.TextDetails2;
	
	Title = Parameters.FormCaption;
	
	If Not IsBlankString(Parameters.InitialMapping) Then
		
		If Parameters.InitialMapping <> "DifferencesInOneWindow" Then
			
			ShowDifferencesInTwoColumns = True;
			
		EndIf;
		
	Else
		
		ShowDifferencesInTwoColumns = Common.CommonSettingsStorageLoad(
			"FileCompare", 
			"ShowDifferencesInTwoColumns");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If Not WebClient Then
	
	EditorSCatalog = GetTempFileName();  //@skip DeletionInProgress when closing the Form
	CreateDirectory(EditorSCatalog);
	ItIsNecessaryToDeleteEditorDirectory = True;
	
	File = New File(EditorSCatalog);
	If Not File.Exists() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không tồn tại thư mục <%1>.';
			|ru = 'Каталог <%1> не существует.';
			|en = 'The <%1> directory does not exist.'; fa = 'The <%1> directory does not exist.';
			|it = 'Каталог <%1> не существует.';
			|pl = 'The <%1> directory does not exist.';
			|tr = '<%1> dizini mevcut değil.'"),EditorSCatalog);
	EndIf;
	
	BinaryData = GetFromTempStorage(EditorTemplate);
	DeleteFromTempStorage(EditorTemplate);
	EditorTemplate = ""; 
	ZipFileReader = New ZipFileReader(BinaryData.OpenStreamForRead());
	ZipFileReader.ExtractAll(EditorSCatalog, ZIPRestoreFilePathsMode.Restore);
	ZipFileReader.Close();
	
	File = New File(EditorSCatalog);
	If Not File.Exists() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại thư mục <%1>.';
				|ru = 'Каталог <%1> не существует.';
				|en = 'The <%1> directory does not exist.'; fa = 'The <%1> directory does not exist.';
				|it = 'Каталог <%1> не существует.';
				|pl = 'The <%1> directory does not exist.';
				|tr = '<%1> dizini mevcut değil.'"),EditorSCatalog);
	EndIf;
	
	EditorLink = CommonClientServer.AddLastPathSeparator(EditorSCatalog) + "index.html?localeCode=" + Left(CurrentSystemLanguage(), 2);
	
	#EndIf
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ItIsNecessaryToDeleteEditorDirectory Then
		Try
			DeleteFiles(EditorSCatalog);
		Except
			EventLogClient.AddMessageForEventLog("ScriptEditor","Error",ErrorDescription());
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure EditorSLinkDocumentIsGenerated(Item)
	
	InitializeEditor();
	
EndProcedure

&AtClient
Procedure ShowDifferencesInTwoColumnsOnChange(Item)
	
	EditorSBookmarks.current.editor.setSideBySide(ShowDifferencesInTwoColumns);
	ShouldSaveSettingsServer(ShowDifferencesInTwoColumns);
	
EndProcedure

&AtClient
Procedure EditorOnClick(Item, EventData, StandardProcessing)
	
	YouNeedToCloseForm = False;
	
	EventElement = EventData.Element; 
	
	If EventElement.id = "VanessaEditorEventForwarder" Then
		
		While True Do
			
			EditorSMessage = Items.Editor.Document.defaultView.popVanessaMessage();
			If (EditorSMessage = Undefined) Then
				Break;
			EndIf;
			
			If EditorSMessage.type = "PRESS_ESCAPE" Then
				YouNeedToCloseForm = True;
			EndIf;
			
		EndDo;
	EndIf;
	
	If YouNeedToCloseForm Then
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToPreviousChange(Command)
	
	EditorSBookmarks.previousDiff();
	
EndProcedure

&AtClient
Procedure GoToNextChange(Command) 
	
	EditorSBookmarks.nextDiff();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure InitializeEditor()
	
	DefaultView_    = Items.Editor.Document.defaultView;
	EditorSBookmarks = DefaultView_.createVanessaTabs();
	
	EditorSBookmarks.diff(
		TextForComparison1,
		TextDetails1,
		"File1",
		TextForComparison2,
		TextDetails2,
		"File2",
		StrTemplate(NStr("vi = 'So sánh <%1> với <%2>';
						|ru = 'Сравнивается <%1> с <%2>';
						|en = 'Comparing <%1> with <%2>'; fa = 'Comparing <%1> with <%2>';
						|it = 'Сравнивается <%1> с <%2>';
						|pl = 'Comparing <%1> with <%2>';
						|tr = '<%1>, <%2> ile karşılaştırılmaktadır'"), TextDetails1, TextDetails2),
		0,
		True, True); 
		
	EditorSBookmarks.current.editor.setSideBySide(ShowDifferencesInTwoColumns);
	
	Items.PagesEditorWaiting.CurrentPage = Items.PageEditor;
	
EndProcedure

&AtServerNoContext
Procedure ShouldSaveSettingsServer(ShowDifferencesInTwoColumns)
	
	Common.CommonSettingsStorageSave("FileCompare",
	                                                 "ShowDifferencesInTwoColumns",
	                                                 ShowDifferencesInTwoColumns
	                                                 ,
	                                                 ,
	                                                 ,
	                                                 True);
	
EndProcedure

&AtServer
Procedure InitializeFormData()
	
	BinaryData = DataProcessors.TextComparison.GetTemplate("TextEditor");
	EditorTemplate = PutToTempStorage(BinaryData, UUID);
	
	SetStateToBeUpdated(Items.UpdateIsUnderway, PictureLib.TimeConsumingOperation48);
	Items.PagesEditorWaiting.CurrentPage = Items.PageWait;
	
EndProcedure

&AtServer
Procedure SetStateToBeUpdated(SpreadsheetDocumentField, PictureTimeConsumingOperation)

	StatePresentation = SpreadsheetDocumentField.StatePresentation;
	StatePresentation.Visible                      = True;
	StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	StatePresentation.Picture                       = PictureTimeConsumingOperation;
	StatePresentation.Text                          = NStr("vi = 'Dữ liệu đang được cập nhật, vui lòng đợi...';
															|ru = 'Данные обновляются, ожидайте...';
															|en = 'Updating data. Please wait...'; fa = 'Updating data. Please wait...';
															|it = 'Данные обновляются, ожидайте...';
															|pl = 'Updating data. Please wait...';
															|tr = 'Veriler güncelleniyor, lütfen bekleyin...'");

EndProcedure

#EndRegion