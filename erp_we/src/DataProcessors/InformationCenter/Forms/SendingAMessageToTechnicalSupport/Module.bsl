#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("UserCode") 
		And ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	DataArea = SaaSOperations.SessionSeparatorValue();
	
	CreateSupportRequest = Parameters.CreateSupportRequest;
	SupportRequestID = Parameters.SupportRequestID;
	
	If Parameters.Property("Subject") And ValueIsFilled(Parameters.Subject) Then
		Subject = Parameters.Subject;
	EndIf;
	
	MessageText = "";
	If Parameters.Property("Text") And ValueIsFilled(Parameters.Text) Then
		MessageText = EscapeCharacters(Parameters.Text);
	EndIf;
	
	If Parameters.Property("Attachments") And ValueIsFilled(Parameters.Attachments) Then
		For Each Attachment In Parameters.Attachments Do
			File = New File(Attachment.FileName);
			PlaceFilesWithoutExtensionOnServer(
				Attachment.AddressInTempStorage, New Structure("Name, Extension", File.BaseName, File.Extension));
		EndDo;
	EndIf;
	
	Use_StandardTemplate = True;
	If Parameters.Property("Use_StandardTemplate") Then
		Use_StandardTemplate = Parameters.Use_StandardTemplate;
	EndIf;
	
	FillInContent(MessageText, Use_StandardTemplate);

	If Parameters.Property("AdditionalData") And ValueIsFilled(Parameters.AdditionalData) Then
		AdditionalData = Parameters.AdditionalData;
	EndIf;

	ResponseAddress = InformationCenterServer.DetermineUserSEmailAddress();
	If IsBlankString(ResponseAddress) Then 
		Items.ReplyToAddress.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetCursorInTextTemplate();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Parameters:
// 	Item - FormDecoration - form element.
//
&AtClient
Procedure Attachable_DeleteFile(Item)
	
	ButtonName = Item.Name;
	DeleteFileServer(ButtonName);
	
EndProcedure

&AtClient
Procedure Attachable_DownloadFile(Item, DeleteButtonName, StandardProcessing)
	
	StandardProcessing = False;
		
	FilterFiles_ = New Structure;
	FilterFiles_.Insert("DeleteButtonName", DeleteButtonName);
	FileStrings = SelectedFiles.FindRows(FilterFiles_);
	
	If FileStrings.Count() = 0 Then
		Return;
	EndIf;
	
	FileString = FileStrings[0];
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp để lưu';
										|ru = 'Выберите файл для сохранения';
										|en = 'Select file to download'; fa = 'Select file to download';
										|it = 'Scegliete un file per il salvataggio';
										|pl = 'Wybierz plik do zapisania';
										|tr = 'Kaydedilecek dosyayı seçin'");
	SavingParameters.Dialog.Filter    = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tệp (*%1)|*%1|Tất cả tệp (%2)|%2';
			|ru = 'Файлы (*%1)|*%1|Все файлы (%2)|%2';
			|en = 'Files (*%1)|*%1|All files (%2)|%2'; fa = 'Files (*%1)|*%1|All files (%2)|%2';
			|it = 'Файлы (*%1)|*%1|Все файлы (%2)|%2';
			|pl = 'Files (*%1)|*%1|All files (%2)|%2';
			|tr = 'Dosyalar (*%1)|*%1|Tüm dosyalar (%2)|%2'"), FileString.Extension, GetAllFilesMask());
		
	FileSystemClient.SaveFile(
		New CallbackDescription("AfterFileSaved", ThisObject),
		FileString.StorageAddress,
		FileString.FileName + FileString.Extension, 
		SavingParameters);
			
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Send(Command)
	
	If Items.ReplyToAddress.Visible Then
		 
		If IsBlankString(ResponseAddress) Then 
			Raise NStr("vi = 'Cần nhập địa chỉ E-mail để trả lời';
						|ru = 'Необходимо ввести адрес электронной почты для ответа';
						|en = 'Enter email address for the response'; fa = 'Enter email address for the response';
						|it = 'È necessario inserire l''indirizzo di posta elettronica per la risposta';
						|pl = 'Musisz podać adres e-mail, aby odpowiedzieć';
						|tr = 'Cevap için e-posta adresi girin'");
		EndIf;
		
		Result = ParseStringWithEmailAddresses(ResponseAddress);
		
		If Result.Count() = 0 Then
			 
			Notification = New CallbackDescription("SendingMessageToSupport", ThisObject);
			QueryText = NStr("vi = 'Có thể là đã nhập sai địa chỉ E-mail. Gửi thông báo?';
							|ru = 'Адрес электронной почты возможно введен неверно. Отправить сообщение?';
							|en = 'Email address might be incorrect. Send the message?'; fa = 'Email address might be incorrect. Send the message?';
							|it = 'L''indirizzo di posta elettronica è inserito in modo scoretto. Inviare il messaggio?';
							|pl = 'Adres e-mail mógł zostać wprowadzony niepoprawnie. Wysłać wiadomość?';
							|tr = 'E-posta adresi hatalı girilmiş olabilir. Mesaj gönderilsin mi?'");
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	SendMessageServer();
	ShowUserNotification(NStr("vi = 'Đã gửi thông báo đến bộ phận hỗ trợ.';
								|ru = 'Сообщение в службу поддержки отправлено.';
								|en = 'Message to the technical support is sent.'; fa = 'Message to the technical support is sent.';
								|it = 'Messaggio è stato inviato al servizio di assistenza.';
								|pl = 'Wiadomość wysłana do zespołu wsparcia.';
								|tr = 'Destek mesajı gönderildi.'"));
	Notify("SendingAMessageToTechnicalSupport");
	Close(True);
	
EndProcedure

&AtClient
Procedure AttachFile(Command)
	
#If WebClient Then
	CallbackDescription = New CallbackDescription("AttachAlertFile", ThisObject);
	BeginAttachingFileSystemExtension(CallbackDescription);
#Else
	AddExternalFiles(True);
#EndIf
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DeleteFileServer(DeleteButtonName)
	
	Filter = New Structure("DeleteButtonName", DeleteButtonName);
	FoundRows = SelectedFiles.FindRows(Filter);
	If FoundRows.Count() = 0 Then 
		Return;
	EndIf;
	
	FoundRow = FoundRows.Get(0);
	NameIndex = GetIndexOfFormElement(DeleteButtonName);
	RemoveAllSubordinateElements(NameIndex);
	DeleteFromTempStorage(FoundRow.StorageAddress);
	
	IndexOf = SelectedFiles.IndexOf(FoundRow);
	SelectedFiles.Delete(IndexOf);
	
EndProcedure

&AtClient
Procedure SendingMessageToSupport(Result) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SendMessageServer();
	ShowUserNotification(NStr("vi = 'Đã gửi thông báo đến bộ phận hỗ trợ.';
								|ru = 'Сообщение в службу поддержки отправлено.';
								|en = 'Message to the technical support is sent.'; fa = 'Message to the technical support is sent.';
								|it = 'Messaggio è stato inviato al servizio di assistenza.';
								|pl = 'Wiadomość wysłana do zespołu wsparcia.';
								|tr = 'Destek mesajı gönderildi.'"));
	Notify("SendingAMessageToTechnicalSupport");
	Close(True);
	
EndProcedure

&AtServer
Procedure RemoveAllSubordinateElements(ElementIndex)
	
	FoundItem_ = Items.Find("FileGroup_" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
	FoundItem_ = Items.Find("FileNameText" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
	FoundItem_ = Items.Find("DeleteFileButton" + String(ElementIndex));
	If FoundItem_ <> Undefined Then 
		Items.Delete(FoundItem_);
	EndIf;
	
EndProcedure

&AtServer
Function GetIndexOfFormElement(TagName)
	
	StartOfPosition = StrLen("DeleteFileButton") + 1;
	Return Number(Mid(TagName, StartOfPosition));
	
EndFunction

&AtClient
Procedure AttachAlertFile(Attached, Context) Export
	
	AddExternalFiles(Attached);
	
EndProcedure

&AtClient
Procedure AddExternalFiles(ExtensionAttached)
	
	If ExtensionAttached Then 
		PlaceFilesWithExtension();
	Else
		PlaceFilesWithoutExtension();
	EndIf;
	
EndProcedure

&AtClient
Procedure PlaceFilesWithExtension()
	
	// Opening the file selection dialog.
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("vi = 'Hãy chọn tệp';
						|ru = 'Выберите файл';
						|en = 'Select file'; fa = 'انتخاب فایل';
						|it = 'Selezionare un file';
						|pl = 'Wybierz plik';
						|tr = 'Dosya seç'");
	Dialog.Multiselect = False;
	
	CallbackDescription = New CallbackDescription("PlaceFileWithAlertExtension", ThisObject);
	InformationCenterClient.PlacingFiles(CallbackDescription,, Dialog, True, UUID);
	
EndProcedure

&AtClient
Procedure PlaceFileWithAlertExtension(SelectedFiles, CompletionHandler) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	SelectedFile = SelectedFiles.Get(0); // TransferredFileDescription
	FullName = SelectedFile.FullName;
	FullFileName = ?(IsBlankString(FullName), SelectedFile.Name, FullName);
	StorageAddress = SelectedFile.Location;
	
	// Checking for the correctness of the total file size.
	File = New File;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FullFileName", FullFileName);
	AdditionalParameters.Insert("StorageAddress", StorageAddress);
	
	CallbackDescription = New CallbackDescription("StartInitializationAlert", ThisObject, AdditionalParameters);
	//@skip-warning DeprecatedMethod - a feature of the implementation.
	File.BeginInitialization(CallbackDescription, FullFileName);
	
	
EndProcedure

// Parameters:
// 	File - File - file. 
// 	AdditionalParameters - Structure - advanced setting.
//
&AtClient
Procedure StartInitializationAlert(File, AdditionalParameters) Export
	
	CallbackDescription = New CallbackDescription(
		"PlaceFileWithExtensionAlertSizeAlert", ThisObject, AdditionalParameters);
	File.BeginGettingSize(CallbackDescription);
	
EndProcedure

&AtClient
Procedure PlaceFileWithExtensionAlertSizeAlert(Size, AdditionalParameters) Export
	
	If Size = 0 Then
		
		WarningText = NStr("vi = 'Không thể thêm tệp. Dung lượng tệp đã chọn bằng 0';
							|ru = 'Не удалось добавить файл. Размер выбранного файла равен 0';
							|en = 'Cannot add the file. The size of the selected file is 0'; fa = 'Cannot add the file. The size of the selected file is 0';
							|it = 'Не удалось добавить файл. Размер выбранного файла равен 0';
							|pl = 'Cannot add the file. The size of the selected file is 0';
							|tr = 'Dosya eklenemedi. Seçili dosyanın boyutu 0'");
		ClearMessages();
		ShowMessageToUser(WarningText);

		Return;
		
	EndIf;
	
	Status(NStr("vi = 'Thêm tệp vào thông báo.';
				|ru = 'Файл добавляется к сообщению.';
				|en = 'The file is being attached to the message.'; fa = 'The file is being attached to the message.';
				|it = 'File viene aggiunto al messaggio.';
				|pl = 'Plik zostanie dodany do wiadomości.';
				|tr = 'Dosya mesaja eklendi.'"));

	// Add files to the table.
	FileNameAndExtension = GetFileNameAndExtension(AdditionalParameters.FullFileName);
	PlaceFilesWithoutExtensionOnServer(AdditionalParameters.StorageAddress, FileNameAndExtension);
	
	Status();
	
	CreateFormElementsForAttachedFile();
	
EndProcedure

&AtClient
Procedure PlaceFilesWithoutExtension()
	
	AfterPutFile = New CallbackDescription("AfterPutFiles", ThisObject);
	
	InformationCenterClient.PuttingFile(AfterPutFile,,, True, UUID);
	
EndProcedure

&AtClient
Procedure AfterPutFiles(Result, StorageAddress, SelectedFileName, AdditionalParameters) Export
	
	If Result Then
		
		FileNameAndExtension = GetFileNameAndExtension(SelectedFileName);
		PlaceFilesWithoutExtensionOnServer(StorageAddress, FileNameAndExtension);
		
	EndIf;
	
EndProcedure

&AtServer
Function GetFileNameAndExtension(Val SelectedFileName)
	
	Result = CommonClientServer.ParseFullFileName(SelectedFileName);
	
	FileNameAndExtension = New Structure;
	FileNameAndExtension.Insert("Name", Result.BaseName);
	FileNameAndExtension.Insert("Extension", Result.Extension);
	
	Return FileNameAndExtension;
	
EndFunction

&AtServer
Procedure PlaceFilesWithoutExtensionOnServer(StorageAddress, FileNameAndExtension)
	
	NewFile = GetFromTempStorage(StorageAddress);
	
	// Checking for the correctness of the total file size.
	FileSize = NewFile.Size();
	
	TableRow = SelectedFiles.Add();
	TableRow.FileName = FileNameAndExtension.Name;
	TableRow.Extension = FileNameAndExtension.Extension;
	TableRow.Size = FileSize;
	TableRow.StorageAddress = StorageAddress;
	
	CreateFormElementsForAttachedFile();
	
EndProcedure

&AtServer
Procedure SendMessageServer()
	
	HTMLText = "";
	HTMLAttachments = New Structure;
	Content.GetHTML(HTMLText, HTMLAttachments);
    Base64Attachments = ConvertPicturesToBase64(HTMLAttachments);
    DataProcessors.InformationCenter.AddAppInformation(HTMLText, Base64Attachments, AdditionalData);
        
	MessageText = Content.GetText();
    If IsBlankString(MessageText) Then 
		Raise NStr("vi = 'Không được để trống nội dung thông báo.';
					|ru = 'Текст сообщения не может быть пустым.';
					|en = 'Message text cannot be blank.'; fa = 'Message text cannot be blank.';
					|it = 'Il testo del messaggio non può essere vuoto';
					|pl = 'Tekst wiadomości nie może być pusty.';
					|tr = 'Metin mesajı boş olamaz.'");
	EndIf;
	
	If IsBlankString(Subject) Then 
		MessageSubject1 = DefineTheme();
	Else
		MessageSubject1 = Subject;
	EndIf;
	
	Try
		
		WSProxy = InformationCenterServer.GetSupportProxy();
		
		ListOfXDTOFiles = GenerateListOfXDTOFiles(WSProxy.XDTOFactory);
		
		WSProxy.addComments(UserCode, String(SupportRequestID), MessageSubject1, 
			HTMLText, CreateSupportRequest,  ListOfXDTOFiles, DataArea, ResponseAddress);
		
		For Each StringAttachments In SelectedFiles Do
			DeleteFromTempStorage(StringAttachments.StorageAddress);
		EndDo;
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
EndProcedure

&AtServer 
Function ConvertPicturesToBase64(Attachments)
	
	Base64Attachments = New Structure;
	For Each KiZ In Attachments Do
		Base64Attachments.Insert(KiZ.Key,Base64String(KiZ.Value.GetBinaryData()));
	EndDo;
	
	Return Base64Attachments;
	
EndFunction

&AtServer
Function DefineTheme()
	
	If Not IsBlankString(Subject) Then 
		Return Subject;
	EndIf;
	
	MessageText = Content.GetText();
	MessageText = StrReplace(MessageText, "Hello.", "");
	MessageText = Left(MessageText, 500);
	MessageText = StrReplace(MessageText, Chars.LF, " ");
	MessageText = StrReplace(MessageText, "  ", " ");
	
	Return TrimAll(MessageText);
	
EndFunction

&AtServer
Function GenerateListOfXDTOFiles(Factory)
	
	FileListType = Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "ListFile");
	ListOfFiles = Factory.Create(FileListType);
	
	For Each CurrentFile In SelectedFiles Do 
		
		FileType = Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "File");
		FileObject1 = Factory.Create(FileType);
		FileObject1.Name = CurrentFile.FileName;
		FileObject1.Data = GetFromTempStorage(CurrentFile.StorageAddress);
		FileObject1.Extension = CurrentFile.Extension;
		FileObject1.Size = CurrentFile.Size;
		
		DataProcessors.InformationCenter.AddValueToXDTOList(ListOfFiles, "Files", FileObject1);
		
	EndDo;
	
	Return ListOfFiles;
	
EndFunction

&AtClient
Procedure SetCursorInTextTemplate()
	
	AttachIdleHandler("HandlerSetCursorInTextTemplate", 0.5, True);
	
EndProcedure

&AtClient
Procedure HandlerSetCursorInTextTemplate()
	
	CurrentItem = Items.Content;
	Bookmark = Content.GetPositionBookmark(CursorPosition);
	Items.Content.SetTextSelectionBounds(Bookmark, Bookmark);
	
EndProcedure

&AtServer
Procedure CreateFormElementsForAttachedFile()
	
	For Each SelectedFile_ In SelectedFiles Do
		
		If Not IsBlankString(SelectedFile_.DeleteButtonName) Then 
			Continue;
		EndIf;
		
		FilePresentation = SelectedFile_.FileName + SelectedFile_.Extension
			+ " (" + Round(SelectedFile_.Size / 1024, 2) + " " + NStr("vi = 'Kb';
																		|ru = 'Кб';
																		|en = 'kB'; fa = 'kB';
																		|it = 'Kb';
																		|pl = 'KB';
																		|tr = 'Kb'") +")";
		
		IndexOf = SelectedFile_.GetID();
		
		FileGroup_ = 
			Items.Add("FileGroup_" + String(IndexOf), Type("FormGroup"), Items.AttachedFileGroup);
		FileGroup_.Type = FormGroupType.UsualGroup;
		FileGroup_.ShowTitle = False;
		FileGroup_.Group = ChildFormItemsGroup.Horizontal;
		FileGroup_.Representation = UsualGroupRepresentation.None;
		
		DeleteButtonName = StrTemplate("DeleteFileButton%1", String(IndexOf));
		
		FileNameText = Items.Add("FileNameText" + String(IndexOf), Type("FormDecoration"), FileGroup_);
		FileNameText.Type = FormDecorationType.Label;
		FileNameText.Title = StringFunctions.FormattedString(
			"<a href=""%1"">%2</a>", DeleteButtonName, FilePresentation);
		FileNameText.AutoMaxWidth = False;
		FileNameText.HorizontalStretch = True;
		FileNameText.SetAction("URLProcessing", "Attachable_DownloadFile");
		
		DeleteFileButton = Items.Add(DeleteButtonName, Type("FormDecoration"), FileGroup_);
		DeleteFileButton.Type = FormDecorationType.Picture;
		DeleteFileButton.Picture = PictureLib.DeleteDirectly;
		DeleteFileButton.ToolTip = NStr("vi = 'Xóa tệp';
										|ru = 'Удалить файл';
										|en = 'Delete file'; fa = 'حذف فایل';
										|it = 'Elimina il file';
										|pl = 'Usuń plik';
										|tr = 'Dosyayı sil'");
		DeleteFileButton.Width = 2;
		DeleteFileButton.Height = 1;
		DeleteFileButton.PictureSize = PictureSize.Stretch;
		DeleteFileButton.Hyperlink = True;
		DeleteFileButton.SetAction("Click", "Attachable_DeleteFile");
		
		SelectedFile_.DeleteButtonName = DeleteButtonName;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ShowMessageToUser(Text)
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.Message();
	
EndProcedure

&AtServer
Function ParseStringWithEmailAddresses(ResponseAddress)
	
	Return CommonClientServer.ParseStringWithEmailAddresses(ResponseAddress, False);
	
EndFunction

&AtServerNoContext
Function EscapeCharacters(TextToProcess)
	
	Result = StrReplace(TextToProcess, "&",  "&amp;");
	Result = StrReplace(Result, "'",  "&apos;");
	Result = StrReplace(Result, "<",  "&lt;");
	Result = StrReplace(Result, ">",  "&gt;");
	Result = StrReplace(Result, """", "&quot;");
	Return Result;
	
EndFunction

&AtServer
Procedure FillInContent(MessageText, Use_StandardTemplate = True)
	
	If Use_StandardTemplate Then
		Text = InformationCenterServer.TextTemplateInTech(MessageText);
	Else
		Text = MessageText;
	EndIf;
	
	LineCursorPosition = "CursorPosition";
	CursorPosition = StrFind(Text, LineCursorPosition)- 4;
	Text = StrReplace(Text, LineCursorPosition, "");
	Text = StrReplace(Text, Chars.LF, "<br>");
	Content.SetHTML(Text, New Structure);
	
EndProcedure

&AtClient
Procedure AfterFileSaved(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		FileSystemClient.OpenExplorer(Result[0].FullName);
	EndIf;
	
EndProcedure

#EndRegion