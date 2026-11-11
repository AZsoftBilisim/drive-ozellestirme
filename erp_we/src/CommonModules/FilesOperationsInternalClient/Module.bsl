///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure OpenFileInternal(Val FileData, Val ForEditing = False) Export
	
	If ForEditing Then
		EditFile(Undefined, FileData);
	Else
		OpenFileWithNotification(Undefined, FileData, , ForEditing); 
	EndIf;
	
EndProcedure

Procedure SaveFileAsInternal(Val FileData, CompletionHandler = Undefined) Export
	
	Notification = New CallbackDescription("SaveFileAsAfterSave",
		FilesOperationsInternalClient, CompletionHandler);
	
	SaveAs(Notification, FileData, Undefined);
	
EndProcedure	

Procedure ActionWithFile(FileOperationParameters) Export
	
	StandardProcessing = True;
	FilesOperationsClientOverridable.OnExecuteActionWithFile(FileOperationParameters, StandardProcessing);

	If Not StandardProcessing Then
		Return;
	EndIf;
	
	AttachedFile	= FileOperationParameters.AttachedFile;
	FileVersion			= FileOperationParameters.VersionRef;
	OwnerForm		= FileOperationParameters.OwnerForm;
	MethodName			= FileOperationParameters.FileRetrievalMethodName;	

	If MethodName = "FilesOperationsInternal.FileDataToOpenAsync"
			Or MethodName = "FilesOperationsInternal.FileDataToSaveAsync" Then
		NameOfNotificationProcedure = "EndActionWithFile";
	ElsIf MethodName = "FilesOperationsInternal.FileDataEmailManagementAsync" Then
		NameOfNotificationProcedure	= "EndActionWithFileEmailManagement";
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Используется непредусмотренный метод получения файла: %1';
					|vi = 'Unsupported file retrieval method used: %1';
					|en = 'Unsupported file retrieval method used: %1'; fa = 'Unsupported file retrieval method used: %1';
					|it = 'Unsupported file retrieval method used: %1';
					|pl = 'Unsupported file retrieval method used: %1';
					|tr = 'Öngörülmemiş dosya alma yöntemi kullanılıyor: %1'"), MethodName));
	EndIf;

	TimeConsumingOperationParameters = TimeConsumingOperationParameters(FileOperationParameters);
	
	TimeConsumingOperation = FilesOperationsInternalServerCall.StartActionWithFile(TimeConsumingOperationParameters, MethodName);

	CallbackDescription = New CallbackDescription(NameOfNotificationProcedure, FilesOperationsInternalClient, FileOperationParameters.ActionParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(OwnerForm);
	IdleParameters.MessageText = NStr("ru = 'Получение файла';
										|vi = 'Get file';
										|en = 'Get file'; fa = 'دریافت فایل';
										|it = 'Ricezione file';
										|pl = 'Pobieranie pliku';
										|tr = 'Dosya alımı'");

	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);	
	
EndProcedure

// Returns the path to the user working directory.
Function UserWorkingDirectory() Export
	
	Return FilesOperationsInternalClientCached.UserWorkingDirectory();
	
EndFunction

// Opens the folder form with the list of files.
//
// Parameters:
//   StandardProcessing - Boolean - passed "as is" from the "Opening" handler parameters.
//   Folder - CatalogRef.Files - Folder to open.
//
Procedure ReportsMailingViewFolder(StandardProcessing, Folder) Export
	
	StandardProcessing = False;
	FormParameters = New Structure("Folder", Folder);
	OpenForm("Catalog.Files.Form.Files", FormParameters, , Folder);
	
EndProcedure

Procedure MoveFiles() Export
	
	OpenForm("DataProcessor.FileTransfer.Form");
	
EndProcedure

// Creates a file in the application based on the passed path to the file and opens the card.
//
// Parameters:
//  ExecutionParameters - Structure:
//       * HandlerResults_1 - CallbackDescription
//                              - Undefined -  description of the procedure that receives the method result.
//       * FullFileName - String - optional. A full path and name of the file on the client.
//             If not specified, a dialog box to select a file will open.
//       * FileOwner - AnyRef - file owner.
//       * OwnerForm - ClientApplicationForm - a form, from which the file creation was called.
//       * NotOpenCardAfterCreateFromFile - Boolean
//             - True when the file card does not open after being created.
//       * NameOfFileToCreate - String - optional. New file name.
//
Procedure AddFormFileSystemWithExtension(ExecutionParameters) Export
	
	Result = AddFromFileSystemWithExtensionSynchronous(ExecutionParameters);
	If Not Result.FileAdded Then
		If ValueIsFilled(Result.ErrorText) Then
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, Result.ErrorText, Undefined);
		Else
			ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		EndIf;
		Return;
	EndIf;
	
	If ExecutionParameters.NotOpenCardAfterCreateFromFile <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.HandlerResults_1);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription); 
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, Result);
	EndIf;
	
EndProcedure

// Creates a file in the application based on the passed path to the file and opens the card.
//
// Parameters: 
//  ExecutionParameters - Structure:
//       * FullFileName - String - optional. A full path and name of the file on the client.
//                                   If not specified, a synchronous dialog box to select a file will open.
//       * FileOwner - AnyRef - file owner.
//       * UUID - UUID - a form ID to store the file.
//       * NameOfFileToCreate - String - optional. New file name.
//
// Returns:
//   Structure:
//       * FileAdded - Boolean - shows whether the operation is performed successfully.
//       * FileRef - CatalogRef.Files
//       * ErrorText - String
//
Function AddFromFileSystemWithExtensionSynchronous(ExecutionParameters) Export
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	DIalogBoxFilter = ?(ExecutionParameters.Property("SelectionDialogFilter"),
		ExecutionParameters.SelectionDialogFilter, StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																												|ru = 'Все файлы (%1)|%1';
																												|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																												|it = 'Все файлы (%1)|%1';
																												|pl = 'All files (%1)|%1';
																												|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask()));
		
	If Not ExecutionParameters.Property("FullFileName") Then
		FileDialog = New FileDialog(FileDialogMode.Open);
		FileDialog.Multiselect = False;
		FileDialog.Title = NStr("vi = 'Chọn tệp';
								|ru = 'Выбор файла';
								|en = 'Select file'; fa = 'انتخاب فایل';
								|it = 'Selezione del file';
								|pl = 'Wybór pliku';
								|tr = 'Dosya seç'");
		FileDialog.Filter = DIalogBoxFilter;
		FileDialog.Directory = FilesOperationsInternalServerCall.FolderWorkingDirectory(ExecutionParameters.FileOwner);
		If Not FileDialog.Choose() Then
			Return Result;
		EndIf;
		ExecutionParameters.Insert("FullFileName", FileDialog.FullFileName);
	EndIf;
	
	If Not ExecutionParameters.Property("NameOfFileToCreate") Then
		ExecutionParameters.Insert("NameOfFileToCreate", Undefined);
	EndIf;
	
	FileToAdd = New File(ExecutionParameters.FullFileName);
	If Not FileToAdd.Exists() Then
		ErrorText = NStr("vi = 'Không tồn tại tệp đã chỉ ra:
			|%1';
			|ru = 'Указанный файл не существует:
			|%1';
			|en = 'The file does not exist:
			|%1'; fa = 'The file does not exist:
			|%1';
			|it = 'Il file specificato non esiste:
			|%1';
			|pl = 'Wskazany plik nie istnieje:
			|%1';
			|tr = 'Belirtilen dosya mevcut değil:
			|%1'");
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			ExecutionParameters.FullFileName);
		Return Result;
	EndIf;

	If ExecutionParameters.Property("MaximumSize")
		And ExecutionParameters.MaximumSize > 0
		And FileToAdd.Size() > ExecutionParameters.MaximumSize*1024*1024 Then
		
		ErrorText = NStr("vi = 'Kích thước tệp vượt quá %1 Mb.';
						|ru = 'Размер файла превышает %1 Мб.';
						|en = 'The file size exceeds %1 MB.'; fa = 'The file size exceeds %1 MB.';
						|it = 'La dimensione del file supera %1 Mb.';
						|pl = 'Rozmiar pliku przekracza %1 MB.';
						|tr = 'Dosya boyutu %1 Mb aşıyor.'");
		Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			ExecutionParameters.MaximumSize);
		
		Return Result;
		
	EndIf;
	
	CheckCanImportFile(FileToAdd);
	
	CommonSettings = CommonFilesOperationsSettings();
	ExtractFilesTextsAtClient = Not CommonSettings.ExtractTextFilesOnServer;
	If ExtractFilesTextsAtClient Then
		TempTextStorageAddress = ExtractTextToTempStorage(FileToAdd.FullName,
			ExecutionParameters.OwnerForm.UUID);
	Else
		TempTextStorageAddress = "";
	EndIf;
		
	// Storing the file to a temporary storage.
	TempFileStorageAddress = "";
	
	Files = New Array;
	LongDesc = New TransferableFileDescription(FileToAdd.FullName, "");
	Files.Add(LongDesc);
	
	PlacedFiles = New Array;
	FilesPut = PutFiles(Files, PlacedFiles, , False, ExecutionParameters.OwnerForm.UUID);
	If Not FilesPut Then
		Return Result;
	EndIf;
	
	If PlacedFiles.Count() = 1 Then
		TempFileStorageAddress = PlacedFiles[0].Location;
	EndIf;
	
	FileNameAndExtension = FileNameAndExtension(FileToAdd);
	FileExtention = FileNameAndExtension.FileExtention;
	FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	
	FileEncrypted = Lower(FileExtention) = Lower(EncryptedFilesExtension());
	
	If FileEncrypted Then
		ForUnencryptedFile = New File(FileNameWithoutExtension);
		FileNameAndExtension = FileNameAndExtension(ForUnencryptedFile);
		FileExtention = FileNameAndExtension.FileExtention;
		FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	EndIf;

	If ExecutionParameters.NameOfFileToCreate <> Undefined Then
		CreationName = ExecutionParameters.NameOfFileToCreate;
	Else
		CreationName = FileNameWithoutExtension;
	EndIf;
	
	// Creating the File card in database.
	Try
		
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			
			FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", FileToAdd);
			FileInfo1.TempFileStorageAddress = TempFileStorageAddress;
			FileInfo1.TempTextStorageAddress = TempTextStorageAddress;
			FileInfo1.WriteToHistory = True;
			FileInfo1.BaseName = CreationName;
			FileInfo1.ExtensionWithoutPoint = FileExtention;
			FileInfo1.Encrypted = FileEncrypted;
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo1);
			
		Else
			
			FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
			FileParameters.FilesOwner = ExecutionParameters.FileOwner;
			FileParameters.BaseName = FileNameWithoutExtension;
			FileParameters.ExtensionWithoutPoint = FileExtention;
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
				TempFileStorageAddress, TempTextStorageAddress);
				
		EndIf;
		
		If IsTempStorageURL(TempTextStorageAddress) Then
			DeleteFromTempStorage(TempTextStorageAddress);
		EndIf;
		If IsTempStorageURL(TempFileStorageAddress) Then
			DeleteFromTempStorage(TempFileStorageAddress);
		EndIf;
		Result.FileAdded = True;
		
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	
	If Result.ErrorText <> "" Then
		Return Result;
	EndIf;
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = ExecutionParameters.FileOwner;
	NotificationParameters.FileOwner = NotificationParameters.Owner;
	NotificationParameters.File = Result.FileRef;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("vi = 'Tạo mới:';
			|ru = 'Создание:';
			|en = 'Created:'; fa = 'ایجادشده:';
			|it = 'Creazione:';
			|pl = 'Created:';
			|tr = 'Oluşturuldu:'"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.DialogInformation);
	
	Return Result;
	
EndFunction

// Continues AttachedFilesClient procedure execution.AddFiles.
Procedure AddFilesAddInSuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	FileOwner = AdditionalParameters.FileOwner;
	FormIdentifier = AdditionalParameters.FormIdentifier;
	
	If Not AdditionalParameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter","");
	EndIf;
	
	If FileSystemExtensionAttached1 Then
		
		Filter = AdditionalParameters.Filter;
		OpenCardAfterCreateFromFile = False;
		If AdditionalParameters.Property("NotOpenCardAfterCreateFromFile") Then
			OpenCardAfterCreateFromFile = Not AdditionalParameters.NotOpenCardAfterCreateFromFile;
		EndIf;
		
		SelectedFiles = New Array;
		
		If Not AdditionalParameters.Property("FullFileName") Then
			SelectingFile = New FileDialog(FileDialogMode.Open);
			SelectingFile.Multiselect = True;
			SelectingFile.Title = NStr("vi = 'Chọn tệp';
										|ru = 'Выбор файла';
										|en = 'Select file'; fa = 'انتخاب فایل';
										|it = 'Selezione del file';
										|pl = 'Wybór pliku';
										|tr = 'Dosya seç'");
			SelectingFile.Filter = ?(ValueIsFilled(Filter), Filter, NStr("vi = 'Tất cả các tệp';
																		|ru = 'Все файлы';
																		|en = 'All files'; fa = 'همه فایل‌ها';
																		|it = 'Tutti i file';
																		|pl = 'Wszystkie pliki';
																		|tr = 'Tüm dosyalar'") + " (*.*)|*.*");
			If SelectingFile.Choose() Then
				SelectedFiles = SelectingFile.SelectedFiles;
			EndIf;
		Else
			SelectedFiles.Add(AdditionalParameters.FullFileName);
		EndIf;
		
		NameOfFileToCreate = "";
		If AdditionalParameters.Property("NameOfFileToCreate") Then
			NameOfFileToCreate = AdditionalParameters.NameOfFileToCreate;
		EndIf;
		
		If SelectedFiles.Count() > 0  Then
			AttachedFilesArray = New Array;
			PutSelectedFilesInStorage(
				SelectedFiles,
				FileOwner,
				AttachedFilesArray,
				FormIdentifier,
				NameOfFileToCreate,
				AdditionalParameters.FilesGroup);
			
			If AttachedFilesArray.Count() = 1 And OpenCardAfterCreateFromFile Then
				AttachedFile = AttachedFilesArray[0];
				
				ShowUserNotification(
					NStr("vi = 'Tạo mới:';
						|ru = 'Создание:';
						|en = 'Created:'; fa = 'ایجادشده:';
						|it = 'Creazione:';
						|pl = 'Created:';
						|tr = 'Oluşturuldu:'"),
					GetURL(AttachedFile),
					AttachedFile,
					PictureLib.DialogInformation);
				
				FormParameters = New Structure("IsNew", True);
				FilesOperationsClient.OpenFileForm(AttachedFile,, FormParameters)
			EndIf;
			
			If AttachedFilesArray.Count() > 0 Then
				NotifyChanged(AttachedFilesArray[0]);
				NotifyChanged(FileOwner);
				NotificationParameters = FileWriteNotificationParameters();
				NotificationParameters.Owner = FileOwner;
				NotificationParameters.FileOwner = NotificationParameters.Owner;
				NotificationParameters.File = AttachedFilesArray[0];
				NotificationParameters.IsNew = True;
				Notify("Write_File", NotificationParameters, AttachedFilesArray);
			EndIf;
			
			If AdditionalParameters.Property("HandlerResults_1")
				And AdditionalParameters.HandlerResults_1 <> Undefined Then
				RunCallback(AdditionalParameters.HandlerResults_1, AttachedFilesArray);
			EndIf;
			
		EndIf;
		
	Else // If the web client has no extension attached.
		CallbackDescription = New CallbackDescription("AddFilesCompletion", ThisObject, AdditionalParameters);
		PutSelectedFilesInStorageWeb(CallbackDescription, FileOwner, FormIdentifier);
	EndIf;
	
EndProcedure

// Displays a standard warning.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  CommandPresentation - String - Name of the command that requires the extension.
//
Procedure Show1CEnterpriseExtensionRequiredMessageBox(HandlerResults_1, CommandPresentation = "") Export
	If Not ClientSupportsSynchronousCalls() Then
		WarningText = NStr("vi = 'Thao tác ""%1"" có sẵn chỉ trong ứng dụng client.';
							|ru = 'Действие ""%1"" доступно только в клиентском приложении.';
							|en = 'Action ""%1"" can only be performed on the client application.'; fa = 'Action ""%1"" can only be performed on the client application.';
							|it = 'Действие ""%1"" доступно только в клиентском приложении.';
							|pl = 'Action ""%1"" can only be performed on the client application.';
							|tr = '""%1"" eylemi sadece istemci uygulamada mevcuttur.'");
	Else
		WarningText = NStr("vi = 'Để thực hiện lệnh ""%1"", cần cài đặt tiện ích mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для выполнения команды ""%1"" установите расширение для работы с 1С:Предприятием.';
							|en = 'To perform ""%1"", install 1C:Enterprise Extension.'; fa = 'To perform ""%1"", install 1C:Enterprise Extension.';
							|it = 'Для выполнения команды ""%1"" установите расширение для работы с 1С:Предприятием.';
							|pl = 'To perform ""%1"", install 1C:Enterprise Extension.';
							|tr = '""%1"" komutunu uygulayabilmek için 1C:Enterprise eklentisini kurun.'");
	EndIf;
	If ValueIsFilled(CommandPresentation) Then
		WarningText = StrReplace(WarningText, "%1", CommandPresentation);
	Else
		WarningText = StrReplace(WarningText, " ""%1""", "");
	EndIf;
	ReturnResultAfterShowWarning(HandlerResults_1, WarningText, Undefined);
EndProcedure

// Saves the path to the user's working directory to the settings.
//
// Parameters:
//  DirectoryName - String - a directory name.
//
Procedure SetUserWorkingDirectory(DirectoryName) Export
	
	FilesOperationsInternalServerCall.SetUserWorkingDirectory(DirectoryName);
	
EndProcedure

// Returns My documents directory + the current user name or the folder
// previously used for data export.
//
Function DumpDirectory() Export
	
	Path = "";
	
#If Not WebClient And Not MobileClient Then
	
	Path = CommonClient.CommonSettingsStorageLoad("ExportFolderName", "ExportFolderName");
	
	If Path = Undefined Then
		If Not StandardSubsystemsClient.IsBaseConfigurationVersion() Then
			Path = MyDocumentsDirectory();
			CommonClient.CommonSettingsStorageSave(
				"ExportFolderName", "ExportFolderName", Path);
		EndIf;
	EndIf;
	
#EndIf
	
	Return Path;
	
EndFunction

// Shows the file selection dialog box to user and returns
// an array of selected files to import.
//
Function FilesToImport() Export
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName     = "";
	OpenFileDialog.Filter             = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																										|ru = 'Все файлы (%1)|%1';
																										|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																										|it = 'Все файлы (%1)|%1';
																										|pl = 'All files (%1)|%1';
																										|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title          = NStr("vi = 'Hãy chọn tệp';
										|ru = 'Выберите файлы';
										|en = 'Select files'; fa = 'انتخاب فایل‌ها';
										|it = 'Scegliete i file';
										|pl = 'Wybierz pliki';
										|tr = 'Dosyaları seçin'");
	
	FileNamesArray = New Array;
	
	If OpenFileDialog.Choose() Then
		FilesArray = OpenFileDialog.SelectedFiles;
		
		For Each FileName In FilesArray Do
			FileNamesArray.Add(FileName);
		EndDo;
		
	EndIf;
	
	Return FileNamesArray;
	
EndFunction

// Checks if the file name contains illegal characters.
//
// Parameters:
//  FileName - String - a checked file name.
//
//  DeleteInvalidCharacters - Boolean - If it is set to "True", illegal characters will be deleted
//                                        from the filename.
//
Procedure CorrectFileName(FileName, DeleteInvalidCharacters = False) Export
	
	InvalidChars = CommonClientServer.FindProhibitedCharsInFileName(FileName);
	Result = InvalidChars.Count() = 0;
	If Not Result Then	
		If DeleteInvalidCharacters Then
			FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileName, "");
		EndIf;
		
	EndIf;
	
	If Not Result Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tên tệp không được có những ký tự sau: %1';
				|ru = 'В имени файла не должно быть следующих символов: %1';
				|en = 'A file name cannot contain the following characters: %1'; fa = 'A file name cannot contain the following characters: %1';
				|it = 'Il nome del file non deve contenere i seguenti caratteri: %1';
				|pl = 'W nazwie pliku nie powinno być następujących znaków: %1';
				|tr = 'Dosya adı şu karakterleri içeremez: %1'"), 
			CommonClientServer.GetProhibitedCharsInFileName());
	EndIf;
	
EndProcedure

// Iterates through directories recursively and counts the number of files and their total size.
Procedure GetFileListSize(Path, FilesArray, TotalSize, TotalFilesCount) Export
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			
			NewPath = NewPath + GetPathSeparator();
			
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				GetFileListSize(
					NewPath, FilesArrayInDirectory, TotalSize, TotalFilesCount);
			EndIf;
		
			Continue;
		EndIf;
		
		TotalSize = TotalSize + SelectedFile.Size();
		TotalFilesCount = TotalFilesCount + 1;
		
	EndDo;
	
EndProcedure

// Returns a path to the directory of the following kind
// "C:Documents and SettingsUSERNAMEApplication Data1CFilesA8".
//
Function SelectPathToUserDataDirectory() Export
	
	DirectoryName = "";
	If Is1CEnterpriseExtensionAttached() Then
		DirectoryName = UserDataWorkDir();
	EndIf;
	
	Return DirectoryName;
	
EndFunction

// Opens Windows Explorer and selects the specified file.
Function OpenExplorerWithFile(Val FullFileName) Export
	
	FileOnHardDrive = New File(FullFileName);
	
	If Not FileOnHardDrive.Exists() Then
		Return False;
	EndIf;
	
	FileSystemClient.OpenExplorer(FileOnHardDrive.FullName);
	
	Return True;
	
EndFunction

// Returns the result of installing 1C:Enterprise Extension.
//
//  Returns:
//   Boolean - In the thin client, it is always "True"; in Chromium-based browsers, it is always "False".
//
Function Is1CEnterpriseExtensionAttached() Export
	Return ?(ClientSupportsSynchronousCalls(), AttachFileSystemExtension(), False);
EndFunction

Procedure ShowQuestionOn1CEnterpriseExtensionInstallation(CallbackDescription) Export
	If Not ClientSupportsSynchronousCalls() Then
		RunCallback(CallbackDescription, False);
		Return;
	EndIf;
	FileSystemClient.Attach1CEnterpriseExtension(CallbackDescription);
EndProcedure

Procedure SendFilesViaEmail(FilesArray, FormIdentifier, SendOptions, IsFile = False) Export
	
	If FilesArray.Count() = 0 Then
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FilesArray", FilesArray);
	Parameters.Insert("FormIdentifier", FormIdentifier);
	Parameters.Insert("IsFile", IsFile);
	Parameters.Insert("SendOptions", SendOptions);
	
	CallbackDescription = New CallbackDescription("SendFileViaEmailAccountSettingOffered", 
		ThisObject, Parameters);
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	EndIf;
	
EndProcedure

Procedure SendFileViaEmailAccountSettingOffered(AccountSetUp, AdditionalParameters) Export
	
	If AccountSetUp <> True Then
		Return;
	EndIf;
	
	AttachmentsList = FilesOperationsInternalServerCall.PutFilesInTempStorage(AdditionalParameters);
	SendOptions = AdditionalParameters.SendOptions;
	
	SendOptions.Insert("Attachments", AttachmentsList);
	SendOptions.Insert("DeleteFilesAfterSending", True);
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	
EndProcedure

Function FileUpdateParameters(HandlerResults_1, ObjectRef, FormIdentifier) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("FormIdentifier", FormIdentifier);
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("CurrentVersionAuthor");
	HandlerParameters.Insert("PassedFullFilePath", "");
	HandlerParameters.Insert("CreateNewVersion");
	HandlerParameters.Insert("VersionComment");
	HandlerParameters.Insert("ShouldShowUserNotification", True);
	HandlerParameters.Insert("ApplyToAll", False);
	HandlerParameters.Insert("UnlockFiles1", True);
	HandlerParameters.Insert("Encoding");
	Return HandlerParameters;
	
EndFunction	

// Click the Show service files command in the file list.
//
// Parameters:
//  List - DynamicList
//
// Returns:
//  Boolean - display service files on the list.
//
Function ShowServiceFilesClick(List) Export
	
	FilterElement = CommonClientServer.FindFilterItemByPresentation(List.Filter.Items, "HideInternal");
	If FilterElement = Undefined Then
		Return False;
	EndIf;
	
	ShowServiceFiles = FilterElement.Use;
	FilterElement.Use = Not ShowServiceFiles;
	Return ShowServiceFiles;
	
EndFunction

// Saves edited file to the infobase and unlocks it.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure EndEditAndNotify(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", Parameters.HandlerResults_1);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	Handler = New CallbackDescription("EndEditAndNotifyCompletion", ThisObject, ExecutionParameters);
	
	HandlerParameters = FileUpdateParameters(Handler, Parameters.ObjectRef, Parameters.FormIdentifier);
	HandlerParameters.CreateNewVersion = Parameters.CreateNewVersion;
	EndEdit(HandlerParameters);
	
EndProcedure

// Saves the file to the infobase but does not unlock it.
Procedure SaveFileChangesWithNotification(HandlerResults_1, CommandParameter, FormIdentifier) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	
	Handler = New CallbackDescription("SaveFileChangesWithNotificationCompletion", ThisObject, ExecutionParameters);
	HandlerParameters = FileUpdateParameters(Handler, CommandParameter, FormIdentifier);
	SaveFileChanges(HandlerParameters);
	
EndProcedure

// Returns string presentation of extensions associated with the file type.
//
// Parameters:
//   FileType - String - for file types, see FillListWithFilesTypes.
//
Function ExtensionsByFileType(FileType) Export
	
	If FileType = "Pictures" Then
		Return "JPG JPEG JP2 JPG2 PNG BMP TIFF";
	ElsIf FileType = "OfficeDocuments" Then
		Return "DOC DOCX DOCM DOT DOTX DOTM XLS XLSX XLSM XLT XLTM XLSB PPT PPTX PPTM PPS PPSX PPSM POT POTX POTM"
			+ "ODT OTT ODP OTP ODS OTS ODC OTC ODF OTF ODM OTH SDW STW SXW STC SXC SDC SDD STI";
	Else
		Return "";
	EndIf;
	
EndFunction

#Region IntegrationWith1CDocumentManagementSubsystem

// Checks if 1C:Document Management is used to store object attachments.
//
// Parameters:
//   AttachedFilesOwner - AnyRef - Attachment owner.
//   Form - ClientApplicationForm - File owner form.
//   Command - FormCommand - The executable command for attachment management.
//   ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient - CommonModule - Implicitly returned value,
//     a module for accessing the functionality for integrating 1C:Document Management.
//
// Returns:
//   Boolean
//
Function Is1CDocumentManagementUsedForFileStorage(AttachedFilesOwner, Form = Undefined,
		Command = Undefined, ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = Undefined) Export
	
	UseEDIToStoreObjectFiles = False;
	
	// IntegrationWith1CDocumentManagement
	If CommonClient.SubsystemExists("IntegrationWith1CDocumentManagementSubsystem") Then
		DMILVersion = "0.0.0.0";
		StandardSubsystemsClient.ClientRunParameters().Property("DMILVersion", DMILVersion);
		If CommonClientServer.CompareVersions(DMILVersion, "3.0.2.4") >= 0 Then
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = CommonClient.CommonModule(
				"IntegrationWith1CDocumentManagementCoreClient");
			If Form = Undefined Then
				Form = New Structure("UseAttachedFiles1CDocumentManagement", True);
			EndIf;
			UseEDIToStoreObjectFiles =
				ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.UseEDIToStoreObjectFiles(
					Form,
					Command,
					AttachedFilesOwner);
		EndIf;
	EndIf;
	// End IntegrationWith1CDocumentManagement
	
	Return UseEDIToStoreObjectFiles;
	
EndFunction

// Opens a form for searching files stored in 1C:Document Management.
//
// Parameters:
//   AttachedFilesOwner - AnyRef - Attachment owner.
//   Form - ClientApplicationForm - File owner form.
//   CommandExecuteParameters - CommandExecuteParameters - Opens the structure being passed to the command handler.
//
Procedure OpenFormAttachedFiles1CDocumentManagement(AttachedFilesOwner, Form = Undefined,
		CommandExecuteParameters = Undefined) Export
	
	// IntegrationWith1CDocumentManagement
	DMILVersion = "0.0.0.0";
	StandardSubsystemsClient.ClientRunParameters().Property("DMILVersion", DMILVersion);
	ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = CommonClient.CommonModule(
		"IntegrationWith1CDocumentManagementCoreClient");
	
	If CommonClientServer.CompareVersions(DMILVersion, "3.0.2.7") >= 0 Then
		Parameters = ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OptionsForOpeningListOfFiles(Form);
		If CommandExecuteParameters <> Undefined Then
			Parameters.Uniqueness = CommandExecuteParameters.Uniqueness;
			Parameters.Window = CommandExecuteParameters.Window;
		EndIf;
		ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OpenFormAttachedFiles(
			AttachedFilesOwner,
			Parameters);
	Else
		ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.OpenAttachedFiles(
			AttachedFilesOwner);
	EndIf;
	// End IntegrationWith1CDocumentManagement
	
EndProcedure

#EndRegion

#Region CryptographyProceduresAndFunctions

// Check signatures of the file data in the table.
// 
// Parameters:
//  Form - ClientApplicationForm - with attributes:
//    * Object - FormDataStructure - as the object with the Ref and Encrypted properties.
//                  For example, CatalogObject.File, CatalogObject.DocumentAttachedFiles.
//               If the object has no properties, pass the structure with properties to FileData.
//
//    * DigitalSignatures - FormDataCollection:
//       * SignatureValidationDate - Date - return value. Check date.
//       * Status              - String - return value. Check result.
//       * SignatureAddress        - String - signature data address in temporary storage.
//
//  RefToBinaryData - BinaryData - binary file data.
//                         - String - address in the temporary storage or URL.
//
//  SelectedRows - Array - a property of the DigitalSignatures parameter form table.
//                   - Undefined - validate all signatures.
//  FileData      - See FilesOperations.FileData
//
Procedure VerifySignatures(Form, RefToBinaryData, SelectedRows = Undefined, FileData = Undefined) Export
	
	// 1. Get the addresses of the binary data and signature binary data.
	// 2. If the file is encrypted, decrypt and verify it.
	
	If FileData = Undefined Then
		FileData = Form.Object; // DefinedType.AttachedFileObject
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	AdditionalParameters.Insert("SignedObject", FileData.Ref);
	AdditionalParameters.Insert("RowsForCheckingByMachineReadableLOA", New Array);
	
	If Not FileData.Encrypted Then
		CheckSignaturesAfterPrepareData(RefToBinaryData, AdditionalParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
														|ru = 'Расшифровка файла';
														|en = 'Decrypt file'; fa = 'Decrypt file';
														|it = 'Decodifica del file';
														|pl = 'Deszyfrowanie plików';
														|tr = 'Dosya detaylandırması'"));
	DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'File';
												|pl = 'File';
												|tr = 'Dosya'"));
	DataDetails.Insert("Data",                RefToBinaryData);
	DataDetails.Insert("Presentation",         FileData.Ref);
	DataDetails.Insert("Object",                FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", FileData.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New CallbackDescription("AfterFileDecryptionOnCheckSignature", ThisObject, AdditionalParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continues the VerifySignatures procedure.
Procedure CheckSignaturesAfterCheckRow(SignatureVerificationResult, AdditionalParameters) Export
	
	Result = SignatureVerificationResult.Result;
	SignatureRow = AdditionalParameters.SignatureRow;
	
	RowData = SignatureRowData();
	CheckResult = RowData.CheckResult;
	FillPropertyValues(RowData, SignatureRow);
		
	RowData.SignatureValidationDate = CommonClient.SessionDate();
	RowData.SignatureCorrect      = (Result = True);
	RowData.IsVerificationRequired = SignatureVerificationResult.IsVerificationRequired;
	If ValueIsFilled(SignatureVerificationResult.SignatureType) Then
		RowData.SignatureType        = SignatureVerificationResult.SignatureType;
	EndIf;
	If ValueIsFilled(SignatureVerificationResult.DateActionLastTimestamp) Then
		RowData.DateActionLastTimestamp = SignatureVerificationResult.DateActionLastTimestamp;
	EndIf;
	
	FillPropertyValues(CheckResult, SignatureVerificationResult);
	CheckResult.IsAdditionalAttributesCheckedManually = False;
	CheckResult.AdditionalAttributesManualCheckAuthor = Undefined;
	CheckResult.AdditionalAttributesManualCheckJustification = "";
	RowData.CheckResult = CheckResult;
	
	If SignatureRow.Property("ErrorDescription") Then
		
		If TypeOf(Result) = Type("String") Then
			RowData.ErrorDescription = Result;
		EndIf;
		FilesOperationsInternalClientServer.FillSignatureStatus(RowData, CommonClient.SessionDate());
	Else
		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClientServer = CommonClient.CommonModule("DigitalSignatureClientServer");
			ModuleDigitalSignatureClientServer.FillSignatureStatus(RowData, CommonClient.SessionDate());
		EndIf;
	EndIf;
		
	// StandardSubsystems.MachineReadableLettersOfAuthority
	If ValueIsFilled(RowData.ResultOfSignatureVerificationByMRLOA)
		And CommonClient.SubsystemExists("StandardSubsystems.MachineReadableLettersOfAuthority") Then
		
		Structure = New Structure;
		Structure.Insert("Certificate", SignatureVerificationResult.Certificate);
		Structure.Insert("SignatureDate", RowData.SignatureDate);
		Structure.Insert("IndexOf", AdditionalParameters.IndexOf);
		Structure.Insert("ResultOfSignatureVerificationByMRLOA", RowData.ResultOfSignatureVerificationByMRLOA);
		
		AdditionalParameters.RowsForCheckingByMachineReadableLOA.Add(Structure);
	EndIf;
	// End StandardSubsystems.MachineReadableLettersOfAuthority
	
	FillPropertyValues(SignatureRow, RowData);
	
	CheckSignaturesLoopStart(AdditionalParameters);

EndProcedure

Procedure ExtendActionSignatures(Form, RenewalOptions, FollowUpHandler) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;

	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.OpenRenewalFormActionsSignatures(
		Form, RenewalOptions, FollowUpHandler);
		
EndProcedure


// For the file form.
//
// Parameters:
//   Form - ClientApplicationForm
//   IsNew - Boolean - File is not written.
//
Procedure SetCommandsAvailabilityOfDigitalSignaturesList(Form, IsNew) Export
	
	Items = Form.Items;
	HasSignatures = (Form.DigitalSignatures.Count() <> 0);
	
	DigitalSignaturesOpen = Items.DigitalSignaturesOpen; // FormButton
	DigitalSignaturesOpen.Enabled = HasSignatures;
	
	DigitalSignaturesCheck = Items.DigitalSignaturesCheck; // FormButton
	DigitalSignaturesCheck.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesCheckEverything = Items.DigitalSignaturesCheckEverything; // FormButton
	DigitalSignaturesCheckEverything.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesSave = Items.DigitalSignaturesSave; // FormButton
	DigitalSignaturesSave.Enabled = HasSignatures;
	
	DigitalSignaturesDelete = Items.DigitalSignaturesDelete; // FormButton
	DigitalSignaturesDelete.Enabled = HasSignatures And Not IsNew;
	
	DigitalSignaturesExtendActionSignatures = Items.DigitalSignaturesExtendActionSignatures; // FormButton
	DigitalSignaturesExtendActionSignatures.Enabled = HasSignatures And Not IsNew;
	
EndProcedure

// For the file form.
//
// Parameters:
//   Form - ClientApplicationForm
//
Procedure SetCommandsAvailabilityOfEncryptionCertificatesList(Form) Export
	
	Object   = Form.Object;
	Items = Form.Items;
	
	EncryptionCertificatesOpen = Items.EncryptionCertificatesOpen; // FormButton
	EncryptionCertificatesOpen.Enabled = Object.Encrypted;
	
EndProcedure

#EndRegion

#Region Scanning


// Opens the dialog box of scanning and view picture.
// 
// Parameters:
//  ExecutionParameters - Structure:
//   * HandlerResults_1 - Undefined, NotifyDescription.
//   * FileOwner - Undefined, DefinedType.FilesOwner.
//   * OwnerForm - Undefined, Form.
//   * IsFile - Boolean
//  ScanningParameters - See FilesOperationsClient.ScanningParameters.
//
Procedure AddFromScanner(ExecutionParameters, ScanningParameters = Undefined) Export
	
#If MobileClient Then
	
	ResultType = ExecutionParameters.ResultType;
	
	MultimediaData = MultimediaTools.MakePhoto();
	If MultimediaData = Undefined Then
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	BaseName = "img_" + Format(CommonClient.SessionDate(), "DF=yyyyMMdd_hhmmss");
	
	ScanningResult = ScanningResult();
		
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		ScanningResult.BinaryData = MultimediaData.GetBinaryData();
		RunCallback(ExecutionParameters.HandlerResults_1, ScanningResult);
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		ImageData = MultimediaData.GetBinaryData();
		// ACC:441-off the file is a method result
		TempFileName = GetTempFileName(MultimediaData.FileExtention);
		// ACC:441-on
		ImageData.Write(TempFileName);
		ScanningResult.FileName = TempFileName;
		
		RunCallback(ExecutionParameters.HandlerResults_1, ScanningResult);
	Else
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesOwner = ExecutionParameters.FileOwner;
		FileParameters.BaseName = BaseName;
		FileParameters.ExtensionWithoutPoint = MultimediaData.FileExtention;
		
		FileAddress = PutToTempStorage(MultimediaData.GetBinaryData(),
			ExecutionParameters.OwnerForm.UUID);
			
		ScanningResult.Insert("FileAdded", True);
		ScanningResult.Insert("FileRef", FilesOperationsInternalServerCall.AppendFile(FileParameters, FileAddress));
		ReturnResult(ExecutionParameters.HandlerResults_1, ScanningResult);
	EndIf;
	
#Else
	
	ClientID = ClientID();
	
	If ScanningParameters = Undefined Then
		ScanningParameters = FilesOperationsClient.ScanningParameters(True);
	EndIf;
	
	FormParameters = New Structure("FileOwner, IsFile, NotOpenCardAfterCreateFromFile, OneFileOnly, ResultType");
	FillPropertyValues(FormParameters, ExecutionParameters);
	FormParameters.Insert("ClientID", ClientID);
	FormParameters.Insert("ScanningParameters", ScanningParameters);
	
	OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.HandlerResults_1);
	OpenForm("DataProcessor.Scanning.Form.ScanningResult", FormParameters, 
		ExecutionParameters.OwnerForm, , , , OnCloseNotifyDescription);
	
#EndIf
	
EndProcedure

Function ScanningResult() Export
	Result = New Structure;
	Result.Insert("ErrorText", "");
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef");	
	Result.Insert("BinaryData");
	Result.Insert("FileName");
	Return Result;
EndFunction

Function ClientID() Export
	SystemInfo = New SystemInfo();
	Return SystemInfo.ClientID;
EndFunction

#EndRegion

#Region CommonProceduresAndFunctionsForOSFiles

// Open file version.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData             - Structure
//  UUID - Form UUID.
//
Procedure OpenFileVersion(HandlerResults_1, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New CallbackDescription("OpenFileVersionAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See CommonClientOverridable.BeforeExit
Procedure BeforeExit(Cancel, Warnings) Export
	
	Response = CheckLockedFilesOnExit();
	If Response = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(Response) <> Type("Structure") Then
		Return;
	EndIf;
	
	UserWarning = StandardSubsystemsClient.WarningOnExit();
	UserWarning.HyperlinkText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Mở danh sách tệp đang soạn (%1)';
			|ru = 'Открыть список редактируемых файлов (%1)';
			|en = 'Open list of locked files (%1)'; fa = 'Open list of locked files (%1)';
			|it = 'Aprire l''elenco dei file in corso di modifica (%1)';
			|pl = 'Otwórz listę edytowalnych plików (%1)';
			|tr = 'Düzenlenmiş dosya listesini açın (%1)'"),
		Response.LockedFilesCount);
	UserWarning.WarningText = NStr("vi = 'Nên xem những tệp bị chếm để chỉnh sửa, chưa đưa những thay đổi vào ứng dụng.';
									|ru = 'Рекомендуется посмотреть занятые для редактирования файлы, изменения которых не помещены в приложение.';
									|en = 'Some files are being edited, and their changes are not propagated to the application. Please review them.'; fa = 'Some files are being edited, and their changes are not propagated to the application. Please review them.';
									|it = 'Some files are being edited, and their changes are not propagated to the application. Please review them.';
									|pl = 'Some files are being edited, and their changes are not propagated to the application. Please review them.';
									|tr = 'Düzenleme yapmak için işleyen ve değişiklikleri uygulamaya yerleştirilmeyen dosyalara bakılması önerilir.'");
	
	ActionOnClickHyperlink = UserWarning.ActionOnClickHyperlink;
	
	ApplicationWarningForm = Undefined;
	Response.Property("ApplicationWarningForm", ApplicationWarningForm);
	ApplicationWarningFormParameters = Undefined;
	Response.Property("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	
	Form = Undefined;
	Response.Property("Form", Form);
	FormParameters = Undefined;
	Response.Property("FormParameters", FormParameters);
	
	If ApplicationWarningForm <> Undefined Then 
		ActionOnClickHyperlink.ApplicationWarningForm = ApplicationWarningForm;
		ActionOnClickHyperlink.ApplicationWarningFormParameters = ApplicationWarningFormParameters;
	EndIf;
	If Form <> Undefined Then 
		ActionOnClickHyperlink.Form = Form;
		ActionOnClickHyperlink.FormParameters = FormParameters;
	EndIf;
	
	Warnings.Add(UserWarning);
	
EndProcedure

Function FileWriteNotificationParameters(Event = "") Export
	EventParameters = New Structure;
	EventParameters.Insert("Event", Event);
	EventParameters.Insert("IsNew", False);
	EventParameters.Insert("Owner");
	EventParameters.Insert("FileOwner"); // Intended for compatibility purposes
	EventParameters.Insert("File");
	Return EventParameters;
EndFunction

Procedure NotifyOfFilesModification(Files, FileWriteNotificationParameters = Undefined) Export
	If TypeOf(Files) <> Type("Array") Then
		FilesForNotification = CommonClientServer.ValueInArray(Files);
	Else
		FilesForNotification = Files;
	EndIf;
	
	If FileWriteNotificationParameters = Undefined Then
		FileWriteNotificationParameters = FileWriteNotificationParameters();
	EndIf;
	
	For Each File In FilesForNotification Do
		Notify("Write_File", FileWriteNotificationParameters, File);
	EndDo;
	
EndProcedure

#EndRegion

#Region TextExtraction

Procedure ExtractVersionText(FileOrFileVersion, FileAddress, Extension, UUID,
	Encoding = Undefined) Export

#If Not WebClient Then
	FileNameWithPath = GetTempFileName(Extension);
	
	If Not GetFile(FileAddress, FileNameWithPath, False) Then
		Return;
	EndIf;
	
	// For the option of storing files in volumes, delete the file from the temporary storage after receiving it.
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	ExtractionResult = "NotExtracted";
	TempTextStorageAddress = "";
	
	Text = "";
	If FileNameWithPath <> "" Then
		
		// Extracting text from the file
		Cancel = False;
		Text = ExtractText1(FileNameWithPath, Cancel, Encoding);
		
		If Cancel = False Then
			ExtractionResult = "Extracted";
			
			If Not IsBlankString(Text) Then
				TempFileName = GetTempFileName();
				TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
				TextFile.Write(Text);
				TextFile.Close();
				
				ImportResult1 = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
				If ImportResult1 <> Undefined Then
					TempTextStorageAddress = ImportResult1;
				EndIf;
				
				Try
					DeleteFiles(TempFileName);
				Except
					EventLogClient.AddMessageForEventLog(EventLogEvent(),
						"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
				EndTry;	
			EndIf;
		Else
			// If there's no one to extract "Text", it's considered standard behavior.
			// Do not generate an error report.
			ExtractionResult = "FailedExtraction";
		EndIf;
		
	EndIf;
	
	Try
		DeleteFiles(FileNameWithPath);
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
	EndTry;	
	
	FilesOperationsInternalServerCall.RecordTextExtractionResult(
		FileOrFileVersion, ExtractionResult, TempTextStorageAddress);

	If IsTempStorageURL(TempTextStorageAddress) Then
		DeleteFromTempStorage(TempTextStorageAddress);
	EndIf;

#EndIf

EndProcedure

#EndRegion

Procedure CheckDirAvailability(NotificationOfResult, DirectoryName) Export
	TestDirectoryName = DirectoryName + GetPathSeparator()+ "CheckAccess";
	Context = New Structure;
	Context.Insert("NotificationOfResult", NotificationOfResult);
	Context.Insert("TestDirectoryName", TestDirectoryName);
	
	Notification = New CallbackDescription("CheckDirAvailabilityAfterCreated", ThisObject, 
		Context, "CheckDirAvailabilityCreationError", ThisObject);
	BeginCreatingDirectory(Notification, TestDirectoryName);
EndProcedure

Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName <> "Report.VolumeIntegrityCheck" Then
		Return;
	EndIf;
	
	If Area.Details = "VolumeIntegrityCheck.RecoverFiles" Then
		StandardProcessing = False;
		Volume = ReportForm.Report.SettingsComposer.Settings.DataParameters.Items.Find("Volume").Value;
		Job = FilesOperationsInternalServerCall.RunFilesRecovery(Volume, ReportForm.UUID);

		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ReportForm",  ReportForm);
		
		CallbackOnCompletion = New CallbackDescription("AfterFilesRecovered", ThisObject, AdditionalParameters);

		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ReportForm);
		IdleParameters.Title = NStr("vi = 'Thực hiện phục hồi thông tin về tệp';
									|ru = 'Выполняется восстановление сведений о файлах';
									|en = 'Restoring file info'; fa = 'Restoring file info';
									|it = 'Выполняется восстановление сведений о файлах';
									|pl = 'Restoring file info';
									|tr = 'Dosya bilgileri geri yükleniyor'");
		IdleParameters.OutputIdleWindow = True;
		
		TimeConsumingOperationsClient.WaitCompletion(Job, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

#EndRegion

#Region Private

Procedure SetModificationUniversalTime(PathToFile, NewTimeOfChange)
	If Not ValueIsFilled(NewTimeOfChange) Then
		Return;
	EndIf;
	
	File = New File(PathToFile);
	If File.Exists() Then
		Try
			File.SetModificationUniversalTime(NewTimeOfChange);
		Except
			EventLogClient.AddMessageForEventLog(
				NStr("vi = 'Làm việc với tệp. Lỗi thiết lập thời gian thay đổi ';
					|ru = 'Работа с файлами.Ошибка установки времени изменения';
					|en = 'File management.Error setting change time'; fa = 'File management.Error setting change time';
					|it = 'File management.Error setting change time';
					|pl = 'File management.Error setting change time';
					|tr = 'Dosya yönetimi. Değişiklik zamanını ayarlama hatası'", CommonClient.DefaultLanguageCode()),
				"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
EndProcedure

// Returns True if a file with such extension can be imported.
Function CheckExtentionOfFileToDownload(FileExtention, RaiseException1 = True)
	
	CommonSettings = CommonFilesOperationsSettings();
	If Not CommonSettings.FilesImportByExtensionDenied Then
		Return True;
	EndIf;
	
	If FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.DeniedExtensionsList, FileExtention) Then
		
		If RaiseException1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cấm kết nhập các tệp có phần mở rộng ""%1"".
				           |Hãy liên hệ với người quản trị.';
				           |ru = 'Загрузка файлов с расширением ""%1"" запрещена.
				           |Обратитесь к администратору.';
				           |en = 'Uploading files with the ""%1"" extension is not allowed.
				           |Please contact the administrator.'; fa = 'Uploading files with the ""%1"" extension is not allowed.
				           |Please contact the administrator.';
				           |it = 'Il download di file con estensione ""%1"" è vietato.
				           |Rivolgetevi all''amministratore.';
				           |pl = 'Pobieranie plików z rozszerzeniem ""%1"" jest zabronione.
				           |Skontaktuj się z administratorem.';
				           |tr = '""%1"" Uzantılı dosya içe aktarılamıyor. 
				           |Yöneticinize başvurun.'"),
				FileExtention);
		Else
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

Function EncryptedFilesExtension()
	
	If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		Return ModuleDigitalSignatureClient.PersonalSettings().EncryptedFilesExtension;
	Else
		Return "p7m";
	EndIf;
	
EndFunction

// Extracts text from a file and returns it as String.
Function ExtractText1(FullFileName, Cancel = False, Encoding = Undefined)
	
	ExtractedText = "";
	
	Try
		File = New File(FullFileName);
		If Not File.Exists() Then
			Cancel = True;
			Return ExtractedText;
		EndIf;
	Except
		Cancel = True;
		Return ExtractedText;
	EndTry;
	
	Dismiss = False;
	CommonSettings = CommonFilesOperationsSettings();
	
#If Not WebClient And Not MobileClient Then
	
	FileNameExtension =
		CommonClientServer.GetFileNameExtension(FullFileName);
	
	FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TextFilesExtensionsList, FileNameExtension);
	
	If FileExtensionInList Then
		Return FilesOperationsInternalClientServer.ExtractTextFromTextFile(
			FullFileName, Encoding, Cancel);
	EndIf;
	
	Try
		Extracting = New TextExtraction(FullFileName);
		ExtractedText = Extracting.GetText();
	Except
		// If there is no handler to extract the text. This is a common scenario.
		ExtractedText = "";
		Dismiss = True;
	EndTry;
		
#EndIf
	
	If IsBlankString(ExtractedText) Then
		
		FileNameExtension =
			CommonClientServer.GetFileNameExtension(FullFileName);
		
		FileExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			CommonSettings.FilesExtensionsListOpenDocument, FileNameExtension);
		
		If FileExtensionInList Then
			Return FilesOperationsInternalClientServer.ExtractOpenDocumentText(FullFileName, Cancel);
		EndIf;
		
	EndIf;
	
	If Dismiss Then
		Cancel = True;
	EndIf;
	
	Return ExtractedText;
	
EndFunction

// Returns the path to the working directory of user data. This directory is used
// as the initial value for the user working directory.
//
// Parameters:
//  Notification - CallbackDescription - a notification that runs after the user working
//   directory is received. As a result the Structure is returned with the following properties:
//     * Directory        - String - full name of the user data working directory.
//     * ErrorDescription - String - an error text if the directory is not received.
//
Procedure GetUserDataWorkingDirectory(Notification)
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	
	BeginGettingUserDataWorkDir(New CallbackDescription(
		"GetUserDataWorkingDirectoryAfterGet", ThisObject, Context,
		"GetUserDataWorkingDirectoryAfterGetDataError", ThisObject));
	
EndProcedure

// Continue the GetUserDataWorkingDirectory procedure.
Procedure GetUserDataWorkingDirectoryAfterGetDataError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	Result = New Structure;
	Result.Insert("Directory", "");
	Result.Insert("ErrorDescription", StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể nhận được thư mục dữ liệu người sử dụng đang làm việc do nguyên nhân:
		           |%1';
		           |ru = 'Не удалось получить рабочий каталог данных пользователя по причине:
		           |%1';
		           |en = 'Cannot retrieve the user''s working directory. Reason:
		           |%1'; fa = 'Cannot retrieve the user''s working directory. Reason:
		           |%1';
		           |it = 'Non è stato possibile ottenere una directory di lavoro dei dati degli utenti a causa di:
		           |%1';
		           |pl = 'Nie udało się uzyskać katalog roboczy danych użytkownika z powodu:
		           |%1';
		           |tr = 'Aşağıdaki nedenlerden dolayı kullanıcı verilerinin 
		           |çalışma dizini alınamadı:%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo)));
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Continue the GetUserDataWorkingDirectory procedure.
Procedure GetUserDataWorkingDirectoryAfterGet(UserDataDir, Context) Export
	
	Result = New Structure;
	Result.Insert("Directory", UserDataDir);
	Result.Insert("ErrorDescription", "");
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Continues the VerifySignatures procedure.
Procedure CheckSignaturesLoopStart(AdditionalParameters)
	
	If AdditionalParameters.Collection.Count() <= AdditionalParameters.IndexOf + 1 Then
		
		// StandardSubsystems.MachineReadableLettersOfAuthority
		
		If AdditionalParameters.RowsForCheckingByMachineReadableLOA.Count() > 0 Then
			Result = FilesOperationsInternalServerCall.CheckSignaturesByMachineReadableLOA(
				AdditionalParameters.RowsForCheckingByMachineReadableLOA, AdditionalParameters.SignedObject);
			For Each CheckResult In Result Do
				Item = AdditionalParameters.Collection[CheckResult.IndexOf];
				SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
					AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
				FillPropertyValues(SignatureRow, CheckResult);
			EndDo;
		EndIf;
		
		// End StandardSubsystems.MachineReadableLettersOfAuthority
		
		Return;
	EndIf;
	
	AdditionalParameters.IndexOf = AdditionalParameters.IndexOf + 1;
	Item = AdditionalParameters.Collection[AdditionalParameters.IndexOf];
	
	AdditionalParameters.Insert("SignatureRow", ?(TypeOf(Item) <> Type("Number"), Item,
		AdditionalParameters.Form.DigitalSignatures.FindByID(Item)));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SignatureVerificationParameters = ModuleDigitalSignatureClient.SignatureVerificationParameters();
	SignatureVerificationParameters.ResultAsStructure = True;
	
	// StandardSubsystems.MobileSignatureService
	If Not ValueIsFilled(AdditionalParameters.SignatureRow.SignatureAddress) 
		And CommonClient.SubsystemExists("StandardSubsystems.MobileSignatureService") Then
		
		ModuleMobileSignatureServiceInternalClient = CommonClient.CommonModule("MobileSignatureServiceInternalClient");
		ModuleMobileSignatureServiceInternalClient.CheckExpectedSignature(
			New CallbackDescription("CheckSignaturesAfterCheckRow", ThisObject, AdditionalParameters),
			AdditionalParameters.Data, AdditionalParameters.SignatureRow.SignatureID, SignatureVerificationParameters);
		Return;
		
	EndIf;
	// End StandardSubsystems.MobileSignatureService
	
	ModuleDigitalSignatureClient.VerifySignature(
			New CallbackDescription("CheckSignaturesAfterCheckRow", ThisObject, AdditionalParameters),
			AdditionalParameters.Data,
			AdditionalParameters.SignatureRow.SignatureAddress,
			Undefined,
			AdditionalParameters.SignatureRow.SignatureDate, SignatureVerificationParameters);
	
EndProcedure

// Checks file properties in the working directory and in the file storage,
// if necessary, asks for user confirmation and returns one of the following actions:
// "OpenExistingFile", "GetFromStorageAndOpen", or "Cancel".
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileNameWithPath - String - full file name with its path in the working directory.
// 
//  FileData    - Structure:
//                   Size                       - Number.
//                   UniversalModificationDate - Date.
//                   InWorkingDirectoryForRead     - Boolean.
//
Procedure ActionOnOpenFileInWorkingDirectory(HandlerResults_1, FileNameWithPath, FileData)
	
	If FileData.Property("UpdatePathFromFileOnHardDrive") Then
		ReturnResult(HandlerResults_1, "GetFromStorageAndOpen");
		Return;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOperation", "OpenInWorkingFolder");
	Parameters.Insert("FullFileNameInWorkingDirectory", FileNameWithPath);
	
	File = New File(Parameters.FullFileNameInWorkingDirectory);
	
	Parameters.Insert("ChangeDateUniversalInFileStorage",
		FileData.UniversalModificationDate);
	Parameters.Insert("ChangeDateUniversalInWorkingDirectory",
		File.GetModificationUniversalTime());
	Parameters.Insert("ChangeDateInWorkingDirectory",
		ToLocalTime(Parameters.ChangeDateUniversalInWorkingDirectory));
	Parameters.Insert("ChangeDateInFileStorage",
		ToLocalTime(Parameters.ChangeDateUniversalInFileStorage));
	Parameters.Insert("SizeInWorkingDirectory", File.Size());
	Parameters.Insert("SizeInFileStorage", FileData.Size);
	
	DateDifference = Parameters.ChangeDateUniversalInWorkingDirectory
	           - Parameters.ChangeDateUniversalInFileStorage;
	
	If DateDifference < 0 Then
		DateDifference = -DateDifference;
	EndIf;
	
	If DateDifference <= 1 Then // Second is a possible difference (Win95 can have that).
		
		If Parameters.SizeInFileStorage <> 0
		   And Parameters.SizeInFileStorage <> Parameters.SizeInWorkingDirectory Then
			// Date is the same, but the size is different. It is a rare but possible case.
			
			Parameters.Insert("Title",
				NStr("vi = 'Dung lượng tệp là khác nhau';
					|ru = 'Размер файла отличается';
					|en = 'Different file sizes'; fa = 'Different file sizes';
					|it = 'La dimensione del file differisce';
					|pl = 'Rozmiar pliku jest inny';
					|tr = 'Dosya boyutu farklı'"));
			
			Parameters.Insert("Message",
				NStr("ru = 'Размер файла в рабочем каталоге на компьютере и его копии в приложении отличается.
				           |
				           |В некоторых случаях размер файла меняется, хотя его содержимое не затрагивается.
				           |Например, после повторного сохранения или обновлении служебной информации.
				           |
				           |Взять файл из приложения и заменить им существующий на компьютере или
				           |открыть существующий без обновления?';
				           |vi = 'The size of a file in the local working directory and its copy in the application differs.
				           |
				           |In some cases, the file size changes even though its contents are not affected.
				           |For example, after resaving or updating internal information.
				           |
				           |Do you want to take the file from the application and replace the existing local file with it,
				           |or open the existing one without updating?';
				           |en = 'The size of a file in the local working directory and its copy in the application differs.
				           |
				           |In some cases, the file size changes even though its contents are not affected.
				           |For example, after resaving or updating internal information.
				           |
				           |Do you want to take the file from the application and replace the existing local file with it,
				           |or open the existing one without updating?'; fa = 'The size of a file in the local working directory and its copy in the application differs.
				           |
				           |In some cases, the file size changes even though its contents are not affected.
				           |For example, after resaving or updating internal information.
				           |
				           |Do you want to take the file from the application and replace the existing local file with it,
				           |or open the existing one without updating?';
				           |it = 'The size of a file in the local working directory and its copy in the application differs.
				           |
				           |In some cases, the file size changes even though its contents are not affected.
				           |For example, after resaving or updating internal information.
				           |
				           |Do you want to take the file from the application and replace the existing local file with it,
				           |or open the existing one without updating?';
				           |pl = 'The size of a file in the local working directory and its copy in the application differs.
				           |
				           |In some cases, the file size changes even though its contents are not affected.
				           |For example, after resaving or updating internal information.
				           |
				           |Do you want to take the file from the application and replace the existing local file with it,
				           |or open the existing one without updating?';
				           |tr = 'Bilgisayardaki çalışma dizininde bulunan dosya boyutu ile uygulamadaki kopyasının boyutu farklıdır. 
				           |
				           | Bazı durumlarda, dosya içeriği etkilenmese bile dosya boyutu değişebilir.
				           | Örneğin, yeniden kaydettikten veya servis bilgilerini güncelledikten sonra.
				           |
				           |Dosya uygulamadan alınıp bilgisayardaki mevcut dosya ile değiştirilsin mi yoksa 
				           | mevcut dosya güncellenmeden mi açılsın?'"));
		Else
			ReturnResult(HandlerResults_1, "OpenExistingFile");
			Return;
		EndIf;
		
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        < Parameters.ChangeDateUniversalInFileStorage Then
		// The most recent file is in the file storage
		If FileData.InWorkingDirectoryForRead = False Then
			Parameters.Insert("Title", NStr("vi = 'Trong chương trình có phiên bản tệp mới hơn';
											|ru = 'В приложении более новая версия файла';
											|en = 'Newer file version in application'; fa = 'Newer file version in application';
											|it = 'В приложении более новая версия файла';
											|pl = 'Newer file version in application';
											|tr = 'Uygulamada dosyanın daha yeni sürümü mevcut'"));
			Parameters.Insert("Message",
				NStr("vi = 'Tệp trong ứng dụng được đánh dấu là bị chiếm để soạn,
				           |có ngày thay đổi muộn hơn (mới hơn) so với bản sao của nó trong thư mục làm việc trên máy tính.
				           |
				           |Lấy tệp từ ứng dụng và thay thế tệp hiện có trên máy tính hoặc
				           |mở tệp hiện có?';
				           |ru = 'Файл в приложении, отмеченный как занятый для редактирования,
				           |имеет более позднюю дату изменения (новее), чем его копия в рабочем каталоге на компьютере.
				           |
				           |Взять файл из приложения и заменить им существующий на компьютере или
				           |открыть существующий?';
				           |en = 'The file in the application was modified
				           |later than its local copy.
				           |
				           |Do you want to retrieve the file from the application
				           |or open the local copy?'; fa = 'The file in the application was modified
				           |later than its local copy.
				           |
				           |Do you want to retrieve the file from the application
				           |or open the local copy?';
				           |it = 'Файл в приложении, отмеченный как занятый для редактирования,
				           |имеет более позднюю дату изменения (новее), чем его копия в рабочем каталоге на компьютере.
				           |
				           |Взять файл из приложения и заменить им существующий на компьютере или
				           |открыть существующий?';
				           |pl = 'The file in the application was modified
				           |later than its local copy.
				           |
				           |Do you want to retrieve the file from the application
				           |or open the local copy?';
				           |tr = 'Uygulamada düzenleme için meşgul olarak işaretlenmiş bir dosya, 
				           |bilgisayarınızdaki çalışma dizinindeki kopyadan daha sonraki bir değiştirme tarihine (daha yeni) sahiptir. 
				           |
				           |Uygulamadan bir dosya alıp bilgisayarda varolan bir dosya ile değiştirilsin mi yoksa 
				           |varolan bir dosya açılsın mı?'"));
		Else
			ReturnResult(HandlerResults_1, "GetFromStorageAndOpen");
			Return;
		EndIf;
	
	ElsIf Parameters.ChangeDateUniversalInWorkingDirectory
	        > Parameters.ChangeDateUniversalInFileStorage Then
		// The most recent file is in the working directory
		
		If FileData.InWorkingDirectoryForRead = False
		   And FileData.BeingEditedBy = UsersClient.AuthorizedUser() Then
			
			// The file in the working directory is locked for editing by the current user
			ReturnResult(HandlerResults_1, "OpenExistingFile");
			Return;
		Else
			// The file in the working directory is for reading.
			Parameters.Insert("Title", NStr("vi = 'Trên máy tính có bản sao tệp mới hơn';
											|ru = 'На компьютере более новая копия файла';
											|en = 'Newer local file version'; fa = 'Newer local file version';
											|it = 'Sul computer c''è una copia più recente del file';
											|pl = 'Na komputerze nowsza kopia pliku';
											|tr = 'Bilgisayarda dosyanın daha yeni kopyası mevcut'"));
			Parameters.Insert(
				"Message",
				NStr("vi = 'Bản sao của tệp trong thư mục làm việc trên máy tính có ngày thay đổi muộn hơn (mới hơn) so với ngày trong ứng dụng. Có thể là, đã chỉnh sửa bản sao này.
				           |
				           |Mở tệp hiện có trên máy tính hoặc thay thế bởi tệp
				           |từ ứng dụng, đồng thời làm mất các thay đổi và mở ra?';
				           |ru = 'Копия файла в рабочем каталоге на компьютере имеет более позднюю дату изменения (новее), чем в приложении. Возможно, эта копия была отредактирована.
				           |
				           |Открыть существующий файл на компьютере или заменить его на файл
				           |из приложения c потерей изменений и открыть?';
				           |en = 'The local file copy was modified later than the file in the application. The local copy might have been edited.
				           |
				           |Do you want to open the local copy or replace it with the file
				           |from the application?'; fa = 'The local file copy was modified later than the file in the application. The local copy might have been edited.
				           |
				           |Do you want to open the local copy or replace it with the file
				           |from the application?';
				           |it = 'Копия файла в рабочем каталоге на компьютере имеет более позднюю дату изменения (новее), чем в приложении. Возможно, эта копия была отредактирована.
				           |
				           |Открыть существующий файл на компьютере или заменить его на файл
				           |из приложения c потерей изменений и открыть?';
				           |pl = 'The local file copy was modified later than the file in the application. The local copy might have been edited.
				           |
				           |Do you want to open the local copy or replace it with the file
				           |from the application?';
				           |tr = 'Bilgisayarınızdaki çalışma dizinindeki bir dosyanın bir kopyası, uygulamada olduğundan daha sonraki bir değişiklik tarihine (daha yeni) sahiptir. Bu kopya düzenlenmiş olabilir. 
				           |
				           |Bilgisayarınızda var olan bir dosya açılsın veya 
				           |uygulamadaki dosya ile değişiklikleri kaybederek değiştirilsin ve açılsın mı?'"));
		EndIf;
	EndIf;
	
	OpenForm("CommonForm.SelectActionOnFilesDifference", Parameters, , , , , HandlerResults_1, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

// Returns the My Documents directory.
//
Function MyDocumentsDirectory()
	Return DocumentsDir();
EndFunction

// Returns the path to the user working directory.
//
// Parameters:
//  Notification - CallbackDescription - a notification that runs after the user working
//   directory is received. As a result the Structure is returned with the following properties:
//     * Directory        - String - full name of the user working directory.
//     * ErrorDescription - String - an error text if the directory is not received.
//
Procedure GetUserWorkingDirectory(Notification)
	
	ParameterName = "StandardSubsystems.WorkingDirectoryAccessCheckExecuted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, False);
	EndIf;
	
	DirectoryName =
		StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings.PathToLocalFileCache;
	
	// Already specified.
	If DirectoryName <> Undefined
		And Not IsBlankString(DirectoryName)
		And ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] Then
		
		Result = New Structure;
		Result.Insert("Directory", DirectoryName);
		Result.Insert("ErrorDescription", "");
		
		RunCallback(Notification, Result);
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Directory", DirectoryName);
	
	GetUserDataWorkingDirectory(New CallbackDescription(
		"GetUserWorkingDirectoryAfterGetDataDirectory", ThisObject, Context));
	
EndProcedure

// Continue the GetUserWorkingDirectory procedure.
Procedure GetUserWorkingDirectoryAfterGetDataDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
#If Not WebClient Then
	
	If Result.Directory <> Context.Directory Then
		// Create a directory for files.
		Try
			CreateDirectory(Context.Directory);
			TestDirectoryName = Context.Directory + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			// Insufficient rights to create a directory, or this path does not exist.
			// Set the default settings.
			Context.Directory = Undefined;
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;
	EndIf;
	
#EndIf
	
	ApplicationParameters["StandardSubsystems.WorkingDirectoryAccessCheckExecuted"] = True;
	
	If Context.Directory = Undefined Then
		SetUserWorkingDirectory(Result.Directory);
	Else
		Result.Directory = Context.Directory;
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// Shows file editing tips in the web client
// if the Show file editing tips option is enabled.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//
Procedure OutputNotificationOnEdit(HandlerResults_1)
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If Not Is1CEnterpriseExtensionAttached() Then
			ReminderText = 
				NStr("vi = 'Bây giờ, sẽ đề xuất mở hoặc lưu tệp.
				|
				|1. Nhấp vào nút ""Lưu"" (""Save""). 
				|
				|2. Chọn thư mục để lưu tệp trên máy tính và ghi nhớ nó
				| (cần thư mục để chỉnh sửa và đưa tệp trở lại ứng dụng).
				|
				|3. Để chỉnh sửa tệp, hãy chuyển đến thư mục đã chọn trước đó, 
				|tìm tệp đã lưu ở đó và mở ra.';
				|ru = 'Сейчас будет предложено открыть или сохранить файл.
				|
				|1. Нажмите кнопку ""Сохранить"" (""Save"").
				|
				|2. Выберите каталог для сохранения файла на компьютере и запомните его
				|(каталог понадобится для редактирования и помещения файла обратно в приложение).
				|
				|3. Для редактирования файла перейдите в выбранный ранее каталог,
				|найдите там сохраненный файл и откройте его.';
				|en = 'You will be prompted to open or save the file.
				|
				|1. Click Save.
				|
				|2. Select a directory to save the file and remember its name 
				|(you will need it to edit and put the file back to the application).
				|
				|3. To edit the file, open the previously selected directory,
				|find the saved file, and open it.'; fa = 'You will be prompted to open or save the file.
				|
				|1. Click Save.
				|
				|2. Select a directory to save the file and remember its name 
				|(you will need it to edit and put the file back to the application).
				|
				|3. To edit the file, open the previously selected directory,
				|find the saved file, and open it.';
				|it = 'Сейчас будет предложено открыть или сохранить файл.
				|
				|1. Нажмите кнопку ""Сохранить"" (""Save"").
				|
				|2. Выберите каталог для сохранения файла на компьютере и запомните его
				|(каталог понадобится для редактирования и помещения файла обратно в приложение).
				|
				|3. Для редактирования файла перейдите в выбранный ранее каталог,
				|найдите там сохраненный файл и откройте его.';
				|pl = 'You will be prompted to open or save the file.
				|
				|1. Click Save.
				|
				|2. Select a directory to save the file and remember its name 
				|(you will need it to edit and put the file back to the application).
				|
				|3. To edit the file, open the previously selected directory,
				|find the saved file, and open it.';
				|tr = 'Şimdi dosyayı açmanız ya da kaydetmeniz istenecektir.
				|
				|1.Kaydet üzerine Tıklayın.
				|
				|2.Dosyayı kaydetmek için klasör seçin ve
				|bu klasörü hatırlayın (dosyayı düzenlemek ve dosyayı depolamaya geri koymak için klasöre ihtiyacınız olacaktır).
				|
				|3. Dosyayı düzenlemek için
				| önceden seçilen klasöre gidin, kaydedilmiş dosyayı bulun ve açın.'");
				
			SystemInfo = New SystemInfo;
			If StrFind(SystemInfo.UserAgentInformation, "Firefox") <> 0 Then
				ReminderText = ReminderText
				+ "
				|
				|"
				+ NStr("vi = '(Theo mặc định trình duyệt Mozilla Firefox tự động lưu tệp vào thư mục ""Văn bản của tôi"")';
						|ru = '(По умолчанию браузер Mozilla Firefox автоматически сохраняет файлы в каталоге ""Мои документы"")';
						|en = '(By default Mozilla Firefox saves files to ""My Documents"" directory.)'; fa = '(به طور پیش‌فرض Mozilla Firefox فایل‌ها را در پوشه «My Documents» ذخیره می‌کند.)';
						|it = '(Di default, Mozilla Firefox salva automaticamente i file nella cartella ""Miei Documenti"")';
						|pl = '(Domyślnie Mozilla Firefox automatycznie zapisuje pliki w katalogu Moje dokumenty)';
						|tr = '(Mozilla Firefox dosyaları varsayılan olarak ""Belgelerim"" klasörüne otomatik olarak kaydeder)'");
			EndIf;
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
										|ru = 'Продолжить';
										|en = 'Continue'; fa = 'ادامه';
										|it = 'Continuare';
										|pl = 'Kontynuuj';
										|tr = 'Devam'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Anuluj';
										|tr = 'İptal'"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
			ReminderParameters.Insert("CheckBoxText",
				NStr("vi = 'Không hiển thị thông báo này nữa';
					|ru = 'Больше не показывать это сообщение';
					|en = 'Do not show this message again'; fa = 'Do not show this message again';
					|it = 'Non mostrare più questo messaggio';
					|pl = 'Nie pokazuj więcej tego komunikatu.';
					|tr = 'Bu mesajı tekrar gösterme'"));
			ReminderParameters.Insert("Title",
				NStr("vi = 'Nhận tệp để xem hoặc soạn';
					|ru = 'Получение файла для просмотра или редактирования';
					|en = 'Get file to view or edit'; fa = 'دریافت فایل برای مشاهده یا ویرایش';
					|it = 'Ottenere un file da visualizzare o modificare';
					|pl = 'Pobieranie pliku do przeglądu lub edycji';
					|tr = 'Görüntüleme veya düzenleme için dosya al'"));
			StandardSubsystemsClient.ShowQuestionToUser(
				HandlerResults_1, ReminderText, Buttons, ReminderParameters);
			
			Return;
		EndIf;
	EndIf;
	ReturnResult(HandlerResults_1, True);
EndProcedure

// Continues the VerifySignatures procedure.
Procedure CheckSignaturesAfterPrepareData(Data, AdditionalParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	If AdditionalParameters.SelectedRows = Undefined Then
		Collection = AdditionalParameters.Form.DigitalSignatures;
	Else
		Collection = AdditionalParameters.SelectedRows;
	EndIf;
	
	If CommonClient.SubsystemExists("CloudTechnology.DigitalSignatureSaaS") Then
		ModuleDigitalSignatureSaaSClient = CommonClient.CommonModule("DigitalSignatureSaaSClient");
		UseDigitalSignatureSaaS = ModuleDigitalSignatureSaaSClient.UsageAllowed();
	Else
		UseDigitalSignatureSaaS = False;
	EndIf;
	
	UseACloudSignature = False;
	If CommonClient.SubsystemExists("StandardSubsystems.DSSElectronicSignatureService") Then
		TheDSSCryptographyServiceModuleClient = CommonClient.CommonModule("DSSCryptographyServiceClient");
		UseACloudSignature = TheDSSCryptographyServiceModuleClient.UseCloudSignatureService();
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If UseDigitalSignatureSaaS
	 Or UseACloudSignature
	 Or Not ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		
		AdditionalParameters.Insert("Data", Data);
		AdditionalParameters.Insert("Collection", Collection);
		AdditionalParameters.Insert("ModuleDigitalSignatureClient", ModuleDigitalSignatureClient);
		AdditionalParameters.Insert("IndexOf", -1);
		CheckSignaturesLoopStart(AdditionalParameters);
		Return;
	EndIf;
	
	If TypeOf(Data) = Type("BinaryData") Then
		DataAddress = PutToTempStorage(Data, AdditionalParameters.FormIdentifier);
	Else
		DataAddress = Data;
	EndIf;
	
	RowsData = New Array;
	
	For Each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		
		RowData = SignatureRowData();
		FillPropertyValues(RowData, SignatureRow);
		RowsData.Add(RowData);
		
	EndDo;
	
	FilesOperationsInternalServerCall.VerifySignatures(DataAddress, RowsData, AdditionalParameters.SignedObject);
	
	IndexOf = 0;
	For Each Item In Collection Do
		SignatureRow = ?(TypeOf(Item) <> Type("Number"), Item,
			AdditionalParameters.Form.DigitalSignatures.FindByID(Item));
		FillPropertyValues(SignatureRow, RowsData[IndexOf]);
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

Function SignatureRowData()
	
	ModuleDigitalSignatureClientServer = CommonClient.CommonModule("DigitalSignatureClientServer");
	Return ModuleDigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	
EndFunction

// Puts files from the computer into the attachment storage.
//
// Parameters:
//  SelectedFiles                 - Array of String - paths to files.
//  FileOwner                  - DefinedType.FilesOwner - a reference to the file owner.
//  FilesOperationsSettings        - Structure.
//  AttachedFilesArray      - Array of DefinedType.AttachedFile - return value. filled in with the references
//                                   to the added files.
//  FormIdentifier             - UUID - UUID.
//
Procedure PutSelectedFilesInStorage(Val SelectedFiles,
                                            Val FileOwner,
                                            AttachedFilesArray,
                                            Val FormIdentifier,
                                            Val NameOfFileToCreate = "",
                                            Val FilesGroup = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	CurrentPosition = 0;
	LastSavedFile = Undefined;
	
	For Each FullFileName In SelectedFiles Do
		
		CurrentPosition = CurrentPosition + 1;		
		File = New File(FullFileName);		
		CheckCanImportFile(File);
		
		If CommonSettings.ExtractTextFilesOnServer Then
			TempTextStorageAddress = "";
		Else
			TempTextStorageAddress = ExtractTextToTempStorage(FullFileName, FormIdentifier);
		EndIf;
	
		ModificationTimeUniversal = File.GetModificationUniversalTime();
		
		UpdateFileSavingState(SelectedFiles, File, CurrentPosition, NameOfFileToCreate);
		LastSavedFile = File;
		
		Files = New Array;
		LongDesc = New TransferableFileDescription(File.FullName, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;		
		If Not PutFiles(Files, PlacedFiles, , False, FormIdentifier) Then
			CommonClient.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xếp tệp ""%1"" vào ứng dụng.';
						|ru = 'Не удалось поместить в приложение файл ""%1"".';
						|en = 'Cannot put the ""%1"" file in the application.'; fa = 'Cannot put the ""%1"" file in the application.';
						|it = 'Не удалось поместить в приложение файл ""%1"".';
						|pl = 'Cannot put the ""%1"" file in the application.';
						|tr = '""%1"" dosya uygulamaya yerleştirilemiyor.'"),
					File.FullName) );
			Continue;
		EndIf;
		
		TempFileStorageAddress = PlacedFiles[0].Location;
		
		FileNameAndExtension = FileNameAndExtension(File);
		FileExtention = FileNameAndExtension.FileExtention;
		FileNameWithoutExtension = FileNameAndExtension.FileNameWithoutExtension;
	
		BaseName = ?(IsBlankString(NameOfFileToCreate), FileNameWithoutExtension, NameOfFileToCreate);
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesGroup = FilesGroup;
		FileParameters.FilesOwner = FileOwner;
		FileParameters.BaseName = BaseName;
		FileParameters.ExtensionWithoutPoint = FileExtention;
		FileParameters.ModificationTimeUniversal = ModificationTimeUniversal;
		
		AttachedFile = FilesOperationsInternalServerCall.AppendFile(FileParameters,
			TempFileStorageAddress, TempTextStorageAddress);
		If IsTempStorageURL(TempTextStorageAddress) Then
			DeleteFromTempStorage(TempTextStorageAddress);
		EndIf;
		If AttachedFile = Undefined Then
			Continue;
		EndIf;
		
		AttachedFilesArray.Add(AttachedFile);
		
	EndDo;
	
	UpdateFileSavingState(SelectedFiles, LastSavedFile, , BaseName);
	
EndProcedure

Procedure UpdateFileSavingState(Val SelectedFiles,
											 Val File,
											 Val CurrentPosition = Undefined,
											 NameOfFileToCreate = "");
	
	If File = Undefined Then
		Return;
	EndIf;
	
	FileNameToSave = ?(IsBlankString(NameOfFileToCreate), File.Name, NameOfFileToCreate);
	
	SizeInMB = FilesOperationsInternalClientServer.FileSizePresentation(File.Size() / (1024 * 1024));
	
	If SelectedFiles.Count() > 1 Then
		If CurrentPosition = Undefined Then
			ShowUserNotification(NStr("vi = 'Lưu tệp';
										|ru = 'Сохранение файлов';
										|en = 'Save files'; fa = 'ذخیره فایل‌ها';
										|it = 'Salvataggio dei file';
										|pl = 'Zapisywanie plików';
										|tr = 'Dosyaların kaydedilmesi'"),, NStr("vi = 'Đã lưu tệp thành công';
																	|ru = 'Сохранение файлов успешно завершено';
																	|en = 'The files are saved.'; fa = 'The files are saved.';
																	|it = 'Salvataggio dei file terminato con successo';
																	|pl = 'Zapisywanie plików pomyślnie zakończone';
																	|tr = 'Dosya kaydı başarı ile tamamlandı'"));
		EndIf;
	Else
		If CurrentPosition = Undefined Then
			ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã lưu tệp ""%1"" (%2 Mb).';
					|ru = 'Файл ""%1"" (%2 Мб) сохранен.';
					|en = 'File ""%1"" (%2 MB) is saved.'; fa = 'File ""%1"" (%2 MB) is saved.';
					|it = 'File ""%1"" (%2 Mb) salvato.';
					|pl = 'Plik ""%1"" (%2 MB) zapisany.';
					|tr = 'Dosya ""%1"" (%2 MB) kaydedildi.'"),
				FileNameToSave,
				SizeInMB);
			ShowUserNotification(NStr("vi = 'Lưu tệp';
										|ru = 'Сохранение файла';
										|en = 'Save file'; fa = 'ذخیره فایل';
										|it = 'Salvataggio del file';
										|pl = 'Zapisywanie pliku';
										|tr = 'Dosyaların kaydedilmesi'"), , ExplanationText, PictureLib.DialogInformation);
		EndIf;
	EndIf;
	
EndProcedure

// Puts a file from the computer into the attachment storage (web client).
// 
// Parameters:
//  HandlerResults_1    - CallbackDescription - Procedure to pass the control to upon completion.
//                            Parameters of the callable procedure::
//                             AttachedFile - AnyRef, Undefined - Reference to the added file.
//                                                       Undefined if the file was not put.
//                             AdditionalParameters - Arbitrary - Value specified upon creating the notification object.
//                                                                      
//  FileOwner           - reference to the file owner.
//  FilesOperationsSettings - Structure.
//  FormIdentifier      - Form UUID.
//
Procedure PutSelectedFilesInStorageWeb(HandlerResults_1, Val FileOwner, Val FormIdentifier)
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner", FileOwner);
	Parameters.Insert("HandlerResults_1", HandlerResults_1);
	
	CallbackDescription = New CallbackDescription("PutSelectedFilesInStorageWebCompletion", ThisObject, Parameters);
	BeginPutFile(CallbackDescription, , ,True, FormIdentifier);
	
EndProcedure

// Continues the PutSelectedFilesInStorageWeb procedure.
Procedure PutSelectedFilesInStorageWebCompletion(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	Handler = AdditionalParameters.HandlerResults_1; // CallbackDescription
	If Not Result Then
		RunCallback(Handler, Undefined);
		Return;
	EndIf;
	
	FileOwner = AdditionalParameters.FileOwner;
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	FilesGroup = ?(Handler.AdditionalParameters.Property("FilesGroup"),
		Handler.AdditionalParameters.FilesGroup, "");
	
	If Not IsBlankString(PathStructure.Extension) Then
		Extension = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		BaseName = PathStructure.BaseName;
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xếp tệp ""%1"" vào ứng dụng.';
				|ru = 'Не удалось поместить в приложение файл ""%1"".';
				|en = 'Cannot put the ""%1"" file in the application.'; fa = 'Cannot put the ""%1"" file in the application.';
				|it = 'Не удалось поместить в приложение файл ""%1"".';
				|pl = 'Cannot put the ""%1"" file in the application.';
				|tr = '""%1"" dosya uygulamaya yerleştirilemiyor.'"),
			SelectedFileName);
	EndIf;
	
	CheckExtentionOfFileToDownload(Extension);
	
	CommonSettings = CommonFilesOperationsSettings();
	FileToImportSize = GetFromTempStorage(Address).Size();
	If FileToImportSize > CommonSettings.MaxFileSize Then
		
		SizeInMB     = FileToImportSize / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Dung lượng tệp ""%1"" (%2 Mb)
			|vượt quá dung lượng tối đa cho phép của tệp %3 Мb.';
			|ru = 'Размер файла ""%1"" (%2 Мб)
			|превышает максимально допустимый размер %3 Мб.';
			|en = 'The size of file ""%1"" (%2 MB)
			|exceeds the limit (%3 MB).'; fa = 'The size of file ""%1"" (%2 MB)
			|exceeds the limit (%3 MB).';
			|it = 'The size of file ""%1"" (%2 MB)
			|exceeds the limit (%3 MB).';
			|pl = 'The size of file ""%1"" (%2 MB)
			|exceeds the limit (%3 MB).';
			|tr = '""%1"" dosyasının boyutu (%2 MB)
			|izin verilen dosya boyutunu aşıyor: %3 MB.'"),
			SelectedFileName,
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB),
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMBMax));
		
		Raise ErrorDescription;
		
	EndIf;
	
	FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
	FileParameters.FilesOwner = FileOwner;
	FileParameters.BaseName = BaseName;
	FileParameters.ExtensionWithoutPoint = Extension;
	If ValueIsFilled(FilesGroup) Then
		FileParameters.FilesGroup = FilesGroup;
	EndIf;
	
	// Creating file cards in the database.
	AttachedFile = FilesOperationsInternalServerCall.AppendFile(
		FileParameters, Address);
		
	RunCallback(Handler, AttachedFile);
	
EndProcedure

// Checks whether it is possible to unlock File.
//
// Parameters:
//  ObjectRef - CatalogRef.Files - file.
//
//  EditedByCurrentUser - Boolean -
//                 file is edited by the current user.
//
//  BeingEditedBy  - CatalogRef.Users - the user who locked the file.
//
//  ErrorString - String - in which the error cause is returned in case of failure
//                 (for example, "The file is locked by another user").
//
// Returns:
//  Boolean -  True if the file can be released.
//
Function AbilityToUnlockFile(ObjectRef,
                                  EditedByCurrentUser,
                                  BeingEditedBy,
                                  ErrorString = "") Export
	
	If EditedByCurrentUser Then 
		Return True;
	ElsIf Not ValueIsFilled(BeingEditedBy) Then
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể giải phóng tệp ""%1"",
			           |bởi vì nó chưa bị chiếm.';
			           |ru = 'Невозможно освободить файл ""%1"",
			           |т.к. он никем не занят.';
			           |en = 'Cannot unlock file ""%1""
			           |because it is not locked.'; fa = 'Cannot unlock file ""%1""
			           |because it is not locked.';
			           |it = 'Impossibile liberare il file ""%1""
			           |poiché non è utilizzato da nessuno.';
			           |pl = 'Nie można zwolnić pliku ""%1"",
			           |ponieważ nie jest on przez nikogo zajęty.';
			           |tr = '""
			           |"" dosyası %1 başkası tarafından işgal edildiği için kilidi açılamadı.'"),
			String(ObjectRef));
		Return False;
	Else
		If UsersClient.IsFullUser() Then
			Return True;
		EndIf;
		
		ErrorString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể giải phóng tệp ""%1"",
			           | bởi vì người dùng ""%2"" đã chiếm.';
			           |ru = 'Невозможно освободить файл ""%1"",
			           |т.к. он занят пользователем ""%2"".';
			           |en = 'Cannot unlock file ""%1""
			           |because it is locked by ""%2"".'; fa = 'Cannot unlock file ""%1""
			           |because it is locked by ""%2"".';
			           |it = 'Impossibile liberare il file ""%1""
			           |poiché è utilizzato dall''utente ""%2"".';
			           |pl = 'Nie można zwolnić pliku ""%1"",
			           |ponieważ jest on zajęty przez użytkownika ""%2"".';
			           |tr = '""
			           |"" dosyası ""%1"" kullanıcı tarafından işgal edildiği için kilidi %2 açılamadı.'"),
			String(ObjectRef),
			String(BeingEditedBy));
		Return False;
	EndIf;
	
EndFunction

Procedure UnlockFiles(ListOfFiles) Export
	FilesArray = New Array;
	For Each ListItem In ListOfFiles.SelectedRows Do
		RowData = ListOfFiles.RowData(ListItem); // DefinedType.AttachedFile
		If Not AbilityToUnlockFile(
				RowData.Ref,
				RowData.CurrentUserEditsFile,
				RowData.BeingEditedBy) Then
			Continue;
		EndIf;
		FilesArray.Add(RowData.Ref);
	EndDo;
	
	If FilesArray.Count() = 0 Then 
		Return;
	EndIf;
	
	FilesData = FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
	
	// Delete files from the working directory to avoid getting modified files during the next editing.
	Handler = New CallbackDescription;
	For Each File In FilesArray Do
		FileVersion = FilesData.FilesVersions.Get(File);
		DeleteFileFromWorkingDirectory(Handler, FileVersion, True);
	EndDo;
	
	StandardSubsystemsClient.SetClientParameter("LockedFilesCount", 
		FilesData.LockedFilesCount);
	If FilesArray.Count() > 1 Then
		NotifyChanged(TypeOf(FilesArray[0]));
		Notify("Write_File", FileWriteNotificationParameters(), Undefined);
	Else	
		NotifyChanged(FilesArray[0]);
		Notify("Write_File", FileWriteNotificationParameters(), FilesArray[0]);
	EndIf;

EndProcedure

// Unlocks file without updating it.
//
// Parameters:
//  FileData             - Structure
//  UUID - Client application form UUID.
//
Procedure UnlockFileWithoutQuestion(FileData, UUID = Undefined)
	
	FilesOperationsInternalServerCall.UnlockFile(FileData, UUID);
	ChangeLockedFilesCount();
	
	ExtensionAttached = Is1CEnterpriseExtensionAttached();
	If ExtensionAttached Then
		ReregisterFileInWorkingDirectory(FileData, True, FileData.OwnerWorkingDirectory <> "");
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã giải phóng tệp';
								|ru = 'Файл освобожден';
								|en = 'The file is released.'; fa = 'The file is released.';
								|it = 'File librato';
								|pl = 'Plik zwolniony';
								|tr = 'Dosya bırakıldı'"),
		FileData.URL, FileData.FullVersionDescription, PictureLib.DialogInformation);
	
EndProcedure

// Moves files to the specified folder.
//
// Parameters:
//  ObjectsRef - Array - an array of files.
//
//  Folder         - CatalogRef.FilesFolders - a folder,
//                  where files must be moved.
//
Procedure MoveFilesToFolder(ObjectsRef, Folder) Export
	
	FilesData = FilesOperationsInternalServerCall.MoveFiles(ObjectsRef, Folder);
	
	For Each FileData In FilesData Do
		
		ShowUserNotification(
			NStr("vi = 'Chuyển tệp';
				|ru = 'Перенос файла';
				|en = 'Move file'; fa = 'Move file';
				|it = 'Trasferimento del file';
				|pl = 'Przenoszenie pliku';
				|tr = 'Dosyayı taşı'"),
			FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp ""%1""
				           |đã chuyển sang thư mục ""%2"".';
				           |ru = 'Файл ""%1""
				           |перенесен в папку ""%2"".';
				           |en = 'File ""%1""
				           |is moved to folder ""%2"".'; fa = 'File ""%1""
				           |is moved to folder ""%2"".';
				           |it = 'Il file ""%1""
				           |è stato trasferito nella cartella ""%2"".';
				           |pl = 'Plik ""%1""
				           |został przeniesiony do folderu ""%2"".';
				           |tr = 'Dosya ""%1"" 
				           | ""%2"" klasöre taşındı.'"),
				String(FileData.Ref),
				String(Folder)),
			PictureLib.DialogInformation);
		
	EndDo;
	
EndProcedure

// Extracts text from a file and puts it to a temporary storage.
Function ExtractTextToTempStorage(FullFileName, UUID = "", Cancel = False,
	Encoding = Undefined)
	
	TempStorageAddress = "";
	
#If Not WebClient Then
		
		Text = ExtractText1(FullFileName, Cancel, Encoding);
		
		If IsBlankString(Text) Then
			Return "";
		EndIf;
		
		TempFileName = GetTempFileName();
		TextFile = New TextWriter(TempFileName, TextEncoding.UTF8);
		TextFile.Write(Text);
		TextFile.Close();
		
		ImportResult1 = PutFileFromHardDriveInTempStorage(TempFileName, , UUID);
		If ImportResult1 <> Undefined Then
			TempStorageAddress = ImportResult1;
		EndIf;
	
		Try	
			DeleteFiles(TempFileName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;	
		
#EndIf
	
	Return TempStorageAddress;
	
EndFunction

// Returns a string constant for generating event log messages.
//
// Returns:
//   String
//
Function EventLogEvent()
	
	Return NStr("vi = 'Tệp';
				|ru = 'Файлы';
				|en = 'Files'; fa = 'فایل‌ها';
				|it = 'File';
				|pl = 'Files';
				|tr = 'Dosyalar'", CommonClient.DefaultLanguageCode());
	
EndFunction

// Returns a message text about an error creating a new file.
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
Function ErrorCreatingNewFile(ErrorInfo)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể thêm tệp vào ứng dụng.
		           |%1';
		           |ru = 'Невозможно добавить файл в приложение.
		           |%1';
		           |en = 'Cannot add the file to the application.
		           |%1'; fa = 'Cannot add the file to the application.
		           |%1';
		           |it = 'Cannot add the file to the application.
		           |%1';
		           |pl = 'Cannot add the file to the application.
		           |%1';
		           |tr = 'Uygulamaya dosya eklenemiyor.
		           |%1'"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));

EndFunction

// Checks file extension and size.
//
// Parameters:
//   File - File
//   RaiseException1 - Boolean
//   FilesWithErrors - Array of Structure:
//     * FileName - String
//     * Error - String
//
Function CheckCanImportFile(File, RaiseException1 = True, FilesWithErrors = Undefined)
	
	CommonSettings = CommonFilesOperationsSettings();
	
	// A file size is too big.
	If File.Size() > CommonSettings.MaxFileSize Then
		
		SizeInMB     = File.Size() / (1024 * 1024);
		SizeInMBMax = CommonSettings.MaxFileSize / (1024 * 1024);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Dung lượng tệp ""%1"" (%2 Mb)
				|vượt quá dung lượng tối đa cho phép của tệp %3 Мb.';
				|ru = 'Размер файла ""%1"" (%2 Мб)
				|превышает максимально допустимый размер %3 Мб.';
				|en = 'The size of file ""%1"" (%2 MB)
				|exceeds the limit (%3 MB).'; fa = 'The size of file ""%1"" (%2 MB)
				|exceeds the limit (%3 MB).';
				|it = 'The size of file ""%1"" (%2 MB)
				|exceeds the limit (%3 MB).';
				|pl = 'The size of file ""%1"" (%2 MB)
				|exceeds the limit (%3 MB).';
				|tr = '""%1"" dosyasının boyutu (%2 MB)
				|izin verilen dosya boyutunu aşıyor: %3 MB.'"),
			File.Name,
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB),
			FilesOperationsInternalClientServer.FileSizePresentation(SizeInMBMax));
		
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		FilesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// Check file extension.
	If Not CheckExtentionOfFileToDownload(File.Extension, False) Then
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cấm kết nhập tệp có phần mở rộng ""%1"".
			           |Hãy liên hệ với người quản trị.';
			           |ru = 'Загрузка файлов с расширением ""%1"" запрещена.
			           |Обратитесь к администратору.';
			           |en = 'Uploading files with the ""%1"" extension is not allowed.
			           |Please contact the administrator.'; fa = 'Uploading files with the ""%1"" extension is not allowed.
			           |Please contact the administrator.';
			           |it = 'Il download di file con estensione ""%1"" è vietato.
			           |Rivolgetevi all''amministratore.';
			           |pl = 'Pobieranie plików z rozszerzeniem ""%1"" jest zabronione.
			           |Skontaktuj się z administratorem.';
			           |tr = '""%1"" Uzantılı dosya içe aktarılamıyor. 
			           |Yöneticinize başvurun.'"),
			File.Extension);
		
		If RaiseException1 Then
			Raise ErrorDescription;
		EndIf;
		
		Record = New Structure;
		Record.Insert("FileName", File.FullName);
		Record.Insert("Error",   ErrorDescription);
		
		FilesWithErrors.Add(Record);
		Return False;
	EndIf;
	
	// Word temporary files are not used.
	If StrStartsWith(File.Name, "~")
		And File.GetHidden() Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#Region CompleteFileEditAndUploadToServer

// Completes editing a file and puts it to the server.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure EndEdit(Parameters)
	
	Handler = New CallbackDescription("FinishEditAfterInstallExtension", ThisObject, Parameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	ExecutionParameters.Insert("FileData", Undefined);
	
	If Is1CEnterpriseExtensionAttached() Then
		FinishEditWithExtension(ExecutionParameters);
	Else
		FinishEditWithoutExtension(ExecutionParameters);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtension(ExecutionParameters)
	// Web client with 1C:Enterprise Extension
	// Thin client
	// Thick client
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	ExecutionParameters.FileData = FileData;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		FileData.Ref,
		FileData.CurrentUserEditsFile,
		FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", ExecutionParameters.PassedFullFilePath);
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// Check file presence.
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	
	If Not ValueIsFilled(ExecutionParameters.FullFilePath)
	 Or Not ExecutionParameters.NewVersionFile.Exists() Then
		
		If ExecutionParameters.ApplyToAll = False Then
			If Not IsBlankString(ExecutionParameters.FullFilePath) Then
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đặt tệp
					           |""%1"" (%2)
					           |vào ứng dụng, bởi vì nó không tồn tại trong thư mục làm việc trên máy tính.
					           |
					           |Giải phóng tệp?';
					           |ru = 'Не удалось поместить в приложение файл
					           |""%1"" (%2)
					           |т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?';
					           |en = 'Cannot store file
					           |""%1"" (%2)
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?'; fa = 'Cannot store file
					           |""%1"" (%2)
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';
					           |it = 'Не удалось поместить в приложение файл
					           |""%1"" (%2)
					           |т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?';
					           |pl = 'Cannot store file
					           |""%1"" (%2)
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';
					           |tr = '
					           |""%1"" (%2)
					           | dosyası bilgisayarda çalışma dizininde olmadığı için uygulamaya yerleştirilemedi.
					           |
					           |Dosya boşaltılsın mı?'"),
					String(FileData.Ref),
					ExecutionParameters.FullFilePath);
			Else
				WarningString = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể đặt tệp ""%1""
					           |vào ứng dụng, bởi vì tệp đó không tồn tại trong thư mục làm việc trên máy tính:
					           |
					           |.Giải phóng tệp?';
					           |ru = 'Не удалось поместить в приложение файл ""%1""
					           |т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?';
					           |en = 'Cannot store file ""%1""
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?'; fa = 'Cannot store file ""%1""
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';
					           |it = 'Не удалось поместить в приложение файл ""%1""
					           |т.к. он не существует в рабочем каталоге на компьютере.
					           |
					           |Освободить файл?';
					           |pl = 'Cannot store file ""%1""
					           |to the application as it does not exist in the working directory.
					           |
					           |Do you want to release the file?';
					           |tr = '""%1"" 
					           | dosyası bilgisayarda çalışma dizininde olmadığı için uygulamaya yerleştirilemedi.
					           |
					           |Dosya boşaltılsın mı?'"),
					String(FileData.Ref));
			EndIf;
			
			Handler = New CallbackDescription("FinishEditWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
			ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Else
			FinishEditWithExtensionAfterRespondQuestionUnlockFile(-1, ExecutionParameters)
		EndIf;
		
		Return;
	EndIf;
	
	Try
		ReadOnly = ExecutionParameters.NewVersionFile.GetReadOnly();
		ExecutionParameters.NewVersionFile.SetReadOnly(Not ReadOnly);
		ExecutionParameters.NewVersionFile.SetReadOnly(ReadOnly);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đặt tệp ""%1"" vào thư mục làm việc trên máy tính
				|, bởi vì có thể là tệp đã bị chiếm bởi ứng dụng khác.';
				|ru = 'Не удалось поместить файл ""%1"" в рабочий каталог на компьютер,
				|так как возможно он открыт в другом приложении.';
				|en = 'Cannot store file ""%1"" to the working directory.
				|Probably, the directory is in use by another app.'; fa = 'Cannot store file ""%1"" to the working directory.
				|Probably, the directory is in use by another app.';
				|it = 'Не удалось поместить файл ""%1"" в рабочий каталог на компьютер,
				|так как возможно он открыт в другом приложении.';
				|pl = 'Cannot store file ""%1"" to the working directory.
				|Probably, the directory is in use by another app.';
				|tr = 'Dosya ""%1"" başka bir uygulama tarafından kilitlenmiş olabileceğinden dolayı, 
				|bilgisayardaki iş dizinine yerleştirilemedi.'"),
			String(FileData.Ref));
		Raise ErrorText + Chars.LF + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	// Requesting a comment and version storage flag.
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = FileData.StoreVersions;
		If FileData.StoreVersions Then
			CreateNewVersionAvailability = FileData.CurrentVersionAuthor = FileData.BeingEditedBy;
			
			ReturnFile = New Structure;
			ReturnFile.Insert("FileRef", FileData.Ref);
			ReturnFile.Insert("VersionComment", "");
			ReturnFile.Insert("CreateNewVersion", ExecutionParameters.CreateNewVersion);
			ReturnFile.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
			
			Handler = New CallbackDescription("CompleteEditingWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
			OpenForm("DataProcessor.FilesOperations.Form.SavingFileVersion", ReturnFile, , , , , Handler);
			
		Else
			FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
		EndIf;
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If FileData.StoreVersions Then
			If FileData.CurrentVersionAuthor <> FileData.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.UnlockFiles1 = True;
		Else
			ExecutionParameters.UnlockFiles1 = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.UnlockFiles1 Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormIdentifier);
		ReturnResult(ExecutionParameters.HandlerResults_1, True);
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
Procedure CompleteEditingWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
		Return;
	EndIf;
	
	// The file with the encrypted again flag is encrypted for the same certificates.
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters)
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo1.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		Files = New Array;
		LongDesc = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;
		Try
			FilesPut = PutFiles(Files, PlacedFiles,, False, ExecutionParameters.FormIdentifier);
		Except
			ErrorInfo = ErrorInfo();
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đặt tệp từ máy tính vào ứng dụng do nguyên nhân:
				|""%1"".
				|
				|Lặp lại thao tác?';
				|ru = 'Не удалось поместить файл с компьютера в приложение по причине:
				|""%1"".
				|
				|Повторить операцию?';
				|en = 'Cannot store the file to the application. Reason:
				|""%1""
				|
				|Do you want to retry?'; fa = 'Cannot store the file to the application. Reason:
				|""%1""
				|
				|Do you want to retry?';
				|it = 'Не удалось поместить файл с компьютера в приложение по причине:
				|""%1"".
				|
				|Повторить операцию?';
				|pl = 'Cannot store the file to the application. Reason:
				|""%1""
				|
				|Do you want to retry?';
				|tr = 'Aşağıdaki nedenle bilgisayardaki dosya uygulamaya yerleştirilemedi: 
				|""%1"". 
				|
				| İşlem tekrarlansın mı?'"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			
			Notification  = New CallbackDescription("FinishEditWithExtensionAfterCheckEncryptedRepeat", ThisObject, ExecutionParameters);
			ShowQueryBox(Notification, QueryText, QuestionDialogMode.RetryCancel);
			Return;
		EndTry;
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.HandlerResults_1, False);
			Return;
		EndIf;
		
		If PlacedFiles.Count() = 1 Then
			FileInfo1.TempFileStorageAddress = PlacedFiles[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		Try
			FileInfo1.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
				ExecutionParameters.FormIdentifier,, ExecutionParameters.Encoding);
		Except
			FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
			Return;
		EndTry;
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullFilePath <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	Try
		VersionUpdated = FilesOperationsInternalServerCall.SaveChangesAndUnlockFile(ExecutionParameters.FileData, 
			FileInfo1, DontChangeRecordInWorkingDirectory, ExecutionParameters.FullFilePath, 
			UserWorkingDirectory(), ExecutionParameters.FormIdentifier);
		If IsTempStorageURL(FileInfo1.TempTextStorageAddress) Then
			DeleteFromTempStorage(FileInfo1.TempTextStorageAddress);
		EndIf;
	Except
		FinishEditWithExtensionExceptionProcessing(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	ChangeLockedFilesCount();
	
	ExecutionParameters.Insert("VersionUpdated", VersionUpdated);
	NewVersion = ExecutionParameters.FileData.CurrentVersion;
	
	If ExecutionParameters.PassedFullFilePath = "" Then
		
		PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
		DeleteFileFromLocalFileCacheOnCompleteEdit = PersonalFilesOperationsSettings.DeleteFileFromLocalFileCacheOnCompleteEdit;
		If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then
			DeleteFileFromLocalFileCacheOnCompleteEdit = False;
		EndIf;
		
		If DeleteFileFromLocalFileCacheOnCompleteEdit Then
			Handler = New CallbackDescription("FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
			DeleteFileFromWorkingDirectory(Handler, NewVersion, DeleteFileFromLocalFileCacheOnCompleteEdit);
			Return;
		Else
			File = New File(ExecutionParameters.FullFilePath);
			File.SetReadOnly(True);
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
Procedure FinishEditWithExtensionAfterCheckEncryptedRepeat(Result, Parameter) Export
	If Result = DialogReturnCode.Retry Then
		FinishEditWithExtensionAfterCheckEncrypted(Parameter);
	EndIf;
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithExtensionAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If ExecutionParameters.ShouldShowUserNotification Then
		If ExecutionParameters.VersionUpdated Then
			NoteTemplate = NStr("vi = 'Tệp ""%1""
			                             |đã cập nhật và giải phóng.';
			                             |ru = 'Файл ""%1""
			                             |обновлен и освобожден.';
			                             |en = 'File ""%1""
			                             |is updated and released.'; fa = 'File ""%1""
			                             |is updated and released.';
			                             |it = 'Il file ""%1""
			                             |è stato aggiornato e liberato.';
			                             |pl = 'Plik ""%1""
			                             |został zaktualizowany i zwolniony.';
			                             |tr = '""%1"" dosyası
			                             |güncellendi ve kilidi açıldı.'");
		Else
			NoteTemplate = NStr("vi = 'Tệp ""%1""
			                             |không thay đổi và được giải phóng.';
			                             |ru = 'Файл ""%1""
			                             |не изменился и освобожден.';
			                             |en = 'File ""%1""
			                             |is not modified and released.'; fa = 'File ""%1""
			                             |is not modified and released.';
			                             |it = 'Il file ""%1""
			                             |non è stato aggiornato e liberato.';
			                             |pl = 'Plik ""%1""
			                             |nie został zmieniony i został zwolniony.';
			                             |tr = '""%1"" dosyası
			                             |değiştirilmedi ve kilidi açılmadı.'");
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Kết thúc soạn';
				|ru = 'Редактирование закончено';
				|en = 'Editing completed'; fa = 'Editing completed';
				|it = 'Modifica terminata';
				|pl = 'Edycja zakończona';
				|tr = 'Düzenleme tamamlandı'"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.DialogInformation);
		
		If Not ExecutionParameters.VersionUpdated Then
			Handler = New CallbackDescription("FinishEditWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithExtensionExceptionProcessing(ErrorInfo, ExecutionParameters)
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể đặt tệp ""%1""
			|từ máy tính vào ứng dụng do nguyên nhân:
			|%2.';
			|ru = 'Не удалось поместить файл ""%1""
			|с компьютере в приложение по причине:
			|%2.';
			|en = 'Cannot store the ""%1"" file
			|from the computer to the application. Reason:
			|%2.'; fa = 'Cannot store the ""%1"" file
			|from the computer to the application. Reason:
			|%2.';
			|it = 'Не удалось поместить файл ""%1""
			|с компьютере в приложение по причине:
			|%2.';
			|pl = 'Cannot store the ""%1"" file
			|from the computer to the application. Reason:
			|%2.';
			|tr = '""%1"" dosyasının bilgisayardan
			|uygulamaya yerleştirilememe nedeni:
			|%2.'"),
		String(ExecutionParameters.FileData.Ref),
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EventLogClient.AddMessageForEventLog(EventLogEvent(),
		"Warning", MessageText,, True);
	QueryText = MessageText + Chars.LF + Chars.LF + NStr("vi = 'Lặp lại thao tác?';
														|ru = 'Повторить операцию?';
														|en = 'Retry the operation?'; fa = 'Retry the operation?';
														|it = 'Ripetere operazione?';
														|pl = 'Powtórzyć operację?';
														|tr = 'İşlem tekrarlansın mı?'");
	Handler = New CallbackDescription("FinishEditWithExtensionAfterRespondQuestionRepeat", 
		ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtension(ExecutionParameters)
	// Web client without 1C:Enterprise Extension.
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		ExecutionParameters.FileData  = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
		ExecutionParameters.Encoding                          = ExecutionParameters.FileData.CurrentVersionEncoding;
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FullFilePath", "");
	
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			CreateNewVersionAvailability = ExecutionParameters.CurrentVersionAuthor = ExecutionParameters.BeingEditedBy;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New CallbackDescription("CompleteEditingWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SavingFileVersion", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CompleteEditingWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New CallbackDescription("FinishEditWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result = DialogReturnCode.Cancel Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave(
			"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
	EndIf;
	
	Handler = New CallbackDescription("FinishEditWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormIdentifier);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		FinishEditWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("vi = 'Mã hóa tệp';
													|ru = 'Шифрование файла';
													|en = 'Encrypt file'; fa = 'Encrypt file';
													|it = 'Cifratura del file';
													|pl = 'Szyfrowanie pliku';
													|tr = 'Dosya şifreleme'"));
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New CallbackDescription("FinishEditWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure FinishEditWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
	
	FileInfo1.TempFileStorageAddress = Address;
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo1.BaseName = PathStructure.BaseName;
	EndIf;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	Try
		Result = FilesOperationsInternalServerCall.SaveChangesAndUnlockFileByRef(ExecutionParameters.ObjectRef,
			FileInfo1, ExecutionParameters.FullFilePath, UserWorkingDirectory(), 
			ExecutionParameters.FormIdentifier);
		ExecutionParameters.FileData = Result.FileData;
	Except
		FinishEditExceptionHandler(ErrorInfo(), ExecutionParameters);
		Return;
	EndTry;
	
	ChangeLockedFilesCount();
	
	If ExecutionParameters.ShouldShowUserNotification Then
		If Result.Success Then
			NoteTemplate = NStr("vi = 'Tệp ""%1""
			                             |đã cập nhật và giải phóng.';
			                             |ru = 'Файл ""%1""
			                             |обновлен и освобожден.';
			                             |en = 'File ""%1""
			                             |is updated and released.'; fa = 'File ""%1""
			                             |is updated and released.';
			                             |it = 'Il file ""%1""
			                             |è stato aggiornato e liberato.';
			                             |pl = 'Plik ""%1""
			                             |został zaktualizowany i zwolniony.';
			                             |tr = '""%1"" dosyası
			                             |güncellendi ve kilidi açıldı.'");
		Else
			NoteTemplate = NStr("vi = 'Tệp ""%1""
			                             |không thay đổi và được giải phóng.';
			                             |ru = 'Файл ""%1""
			                             |не изменился и освобожден.';
			                             |en = 'File ""%1""
			                             |is not modified and released.'; fa = 'File ""%1""
			                             |is not modified and released.';
			                             |it = 'Il file ""%1""
			                             |non è stato aggiornato e liberato.';
			                             |pl = 'Plik ""%1""
			                             |nie został zmieniony i został zwolniony.';
			                             |tr = '""%1"" dosyası
			                             |değiştirilmedi ve kilidi açılmadı.'");
		EndIf;
		
		ShowUserNotification(
			NStr("vi = 'Kết thúc soạn';
				|ru = 'Редактирование закончено';
				|en = 'Editing completed'; fa = 'Editing completed';
				|it = 'Modifica terminata';
				|pl = 'Edycja zakończona';
				|tr = 'Düzenleme tamamlandı'"),
			ExecutionParameters.FileData.URL,
			StringFunctionsClientServer.SubstituteParametersToString(
				NoteTemplate, String(ExecutionParameters.FileData.Ref)),
			PictureLib.DialogInformation);
		
		If Not Result.Success Then
			Handler = New CallbackDescription("FinishEditWithoutExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	FinishEditWithoutExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditExceptionHandler(ErrorInfo, ExecutionParameters)
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể đặt tệp ""%1""
		           |từ máy tính vào ứng dụng do nguyên nhân
		           |""%2"".
		           |
		           |Thử lại giao dịch?';
		           |ru = 'Не удалось поместить файл ""%1""
		           |с компьютера в приложение по причине
		           |""%2"".
		           |
		           |Повторить операцию?';
		           |en = 'Cannot store the ""%1"" file
		           |from the computer to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?'; fa = 'Cannot store the ""%1"" file
		           |from the computer to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?';
		           |it = 'Не удалось поместить файл ""%1""
		           |с компьютера в приложение по причине
		           |""%2"".
		           |
		           |Повторить операцию?';
		           |pl = 'Cannot store the ""%1"" file
		           |from the computer to the application. Reason:
		           |""%2"".
		           |
		           |Do you want to retry?';
		           |tr = '""%1"" dosyası bilgisayardan
		           |uygulamaya""%2""
		           |nedeniyle yerleştirilmedi.
		           |
		           |İşlem tekrarlansın mı?'"),
		String(ExecutionParameters.ObjectRef),
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	Handler = New CallbackDescription("FinishEditWithoutExtensionAfterRespondQuestionRepeat", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, ErrorText, QuestionDialogMode.RetryCancel);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditWithoutExtensionAfterRespondQuestionRepeat(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Cancel Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
	Else
		FinishEditWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	EndIf;
EndProcedure

#EndRegion

#Region SelectingFileForCreatingNewVersion

// Imports the file and creates a new version.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that
//                       receives the method result with the following parameters:
//    * Result               - Boolean - True if the file is updated.
//    * AdditionalParameters - Arbitrary - a value that was specified on creating
//                              the NotifyDescription object.
//  FileData        - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//  FormIdentifier - UUID - a form UUID.
//
Procedure UpdateFromFileOnHardDrive(HandlerResults_1, FileData, FormIdentifier,
	FileAddingOptions = Undefined)
	
	If Not Is1CEnterpriseExtensionAttached() Then
		ReturnResult(HandlerResults_1, False);
		Return;
	EndIf;
		
	Dialog = New FileDialog(FileDialogMode.Open);
	
	If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
		ChoicePath = FileData.OwnerWorkingDirectory;
	Else
		ChoicePath = CommonClient.CommonSettingsStorageLoad("ApplicationSettings", "FolderForUpdateFromFile");
	EndIf;
	
	If ChoicePath = Undefined Or ChoicePath = "" Then
		ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	Dialog.Title                   = NStr("vi = 'Chọn tệp';
											|ru = 'Выбор файла';
											|en = 'Select file'; fa = 'انتخاب فایل';
											|it = 'Selezione del file';
											|pl = 'Wybór pliku';
											|tr = 'Dosya seç'");
	Dialog.Preview     = False;
	Dialog.CheckFileExistence = False;
	Dialog.Multiselect          = False;
	Dialog.Directory                     = ChoicePath;
	
	Dialog.FullFileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	If FileAddingOptions <> Undefined
		And FileAddingOptions.Property("SelectionDialogFilter")
		And Not IsBlankString(FileAddingOptions.SelectionDialogFilter) Then
		
		Dialog.Filter = FileAddingOptions.SelectionDialogFilter;
		
	Else
		
		EncryptedFilesExtension = "";
		
		If CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
			
			If ModuleDigitalSignatureClient.UseEncryption() Then
				EncryptedFilesExtension =
					ModuleDigitalSignatureClient.PersonalSettings().EncryptedFilesExtension;
			EndIf;
		EndIf;
		
		If ValueIsFilled(EncryptedFilesExtension) Then
			Filter = NStr("vi = 'Tệp (*.%1)|*.%1|Tệp mã hóa (*.%2)|*.%2';
							|ru = 'Файл (*.%1)|*.%1|Зашифрованный файл (*.%2)|*.%2';
							|en = 'File (*.%1)|*.%1|Encrypted file (*.%2)|*.%2'; fa = 'File (*.%1)|*.%1|Encrypted file (*.%2)|*.%2';
							|it = 'Файл (*.%1)|*.%1|Зашифрованный файл (*.%2)|*.%2';
							|pl = 'File (*.%1)|*.%1|Encrypted file (*.%2)|*.%2';
							|tr = 'Dosya (*.%1)|*.%1|Şifreli dosya (*.%2)|*.%2'") + "|"
					+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																					|ru = 'Все файлы (%1)|%1';
																					|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																					|it = 'Все файлы (%1)|%1';
																					|pl = 'All files (%1)|%1';
																					|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension, EncryptedFilesExtension);
		Else
			Filter = NStr("vi = 'Tệp (*.%1)|*.%1';
							|ru = 'Файл (*.%1)|*.%1';
							|en = 'File (*.%1)|%1'; fa = 'File (*.%1)|%1';
							|it = 'Файл (*.%1)|*.%1';
							|pl = 'File (*.%1)|%1';
							|tr = 'Dosya (*.%1)|*.%1'") + "|"
					+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																					|ru = 'Все файлы (%1)|%1';
																					|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																					|it = 'Все файлы (%1)|%1';
																					|pl = 'All files (%1)|%1';
																					|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
			Dialog.Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, FileData.Extension);
		EndIf;
		
	EndIf;
	
	If Not Dialog.Choose() Then
		ReturnResult(HandlerResults_1, False);
		Return;
	EndIf;
	
	ChoicePathPrevious = ChoicePath;
	FileOnHardDrive = New File(Dialog.FullFileName);
	
	If FileAddingOptions <> Undefined
		And FileAddingOptions.Property("MaximumSize")
		And FileAddingOptions.MaximumSize > 0
		And FileOnHardDrive.Size() > FileAddingOptions.MaximumSize*1024*1024 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Dung lượng tệp vượt quá %1 Mb.';
				|ru = 'Размер файла превышает %1 Мб.';
				|en = 'The file size exceeds %1 MB.'; fa = 'The file size exceeds %1 MB.';
				|it = 'La dimensione del file supera %1 Mb.';
				|pl = 'Rozmiar pliku przekracza %1 MB.';
				|tr = 'Dosya boyutu %1 Mb aşıyor.'"), FileAddingOptions.MaximumSize);
		ReturnResultAfterShowWarning(HandlerResults_1, ErrorText, False);
		Return;
		
	EndIf;
	
	ChoicePath = FileOnHardDrive.Path;
	If IsBlankString(FileData.OwnerWorkingDirectory) Then
		If ChoicePathPrevious <> ChoicePath Then
			CommonClient.CommonSettingsStorageSave("ApplicationSettings", "FolderForUpdateFromFile",  ChoicePath);
		EndIf;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormIdentifier",   FormIdentifier);
	ExecutionParameters.Insert("DialogBoxFullFileName", Dialog.FullFileName);
	ExecutionParameters.Insert("CreateNewVersion",   Undefined);
	ExecutionParameters.Insert("VersionComment",   Undefined);
	
	ExecutionParameters.Insert("FileOnHardDrive", New File(ExecutionParameters.DialogBoxFullFileName));
	ExecutionParameters.Insert("FileNameAndExtensionOnHardDrive", ExecutionParameters.FileOnHardDrive.Name);
	ExecutionParameters.Insert("FileName", ExecutionParameters.FileOnHardDrive.BaseName);
	
	ExecutionParameters.Insert("ChangeTimeSelected",
		ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime());
	
	ExecutionParameters.Insert("FileExtensionOnHardDrive",
		CommonClientServer.ExtensionWithoutPoint(ExecutionParameters.FileOnHardDrive.Extension));
	
	ExecutionParameters.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	ExecutionParameters.Insert("FileEncrypted", Lower(ExecutionParameters.FileExtensionOnHardDrive)
		= Lower(ExecutionParameters.EncryptedFilesExtension));
		
	CheckCanImportFile(FileOnHardDrive);
	If Not ExecutionParameters.FileEncrypted Then
		UpdateFromFileOnHardDriveContinued(ExecutionParameters);
		Return;
	EndIf;
	
	// cutting .p7m at the end.
	Position = StrFind(ExecutionParameters.FileNameAndExtensionOnHardDrive, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.FileNameAndExtensionOnHardDrive = Left(ExecutionParameters.FileNameAndExtensionOnHardDrive, Position - 2);
	
	// cutting .p7m at the end.
	ExecutionParameters.Insert("DialogBoxFullFileNamePrevious", ExecutionParameters.DialogBoxFullFileName);
	Position = StrFind(ExecutionParameters.DialogBoxFullFileName, ExecutionParameters.FileExtensionOnHardDrive);
	ExecutionParameters.DialogBoxFullFileName = Left(ExecutionParameters.DialogBoxFullFileName, Position - 2);
	
	TempFileNonEncrypted = New File(ExecutionParameters.DialogBoxFullFileName);
	
	ExecutionParameters.FileExtensionOnHardDrive = CommonClientServer.ExtensionWithoutPoint(
		TempFileNonEncrypted.Extension);
	
	// Decrypt here and enter the same date of change, as of DialogBoxFullFileNamePrevious.
	
	Files = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileNamePrevious);
	Files.Add(FileDetails);
	
	BeginPuttingFiles(New CallbackDescription("UpdateFromFileOnHardDriveBeforeDecryption", ThisObject, ExecutionParameters),
		Files, , False, ExecutionParameters.FormIdentifier);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveBeforeDecryption(Files, ExecutionParameters) Export
	
	If Not ValueIsFilled(Files) Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
														|ru = 'Расшифровка файла';
														|en = 'Decrypt file'; fa = 'Decrypt file';
														|it = 'Decodifica del file';
														|pl = 'Deszyfrowanie plików';
														|tr = 'Dosya detaylandırması'"));
	DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'File';
												|pl = 'File';
												|tr = 'Dosya'"));
	DataDetails.Insert("Data",                Files[0].Location);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", New Array);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New CallbackDescription("UpdateFromFileOnHardDriveAfterDecryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormIdentifier);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	ExecutionParameters.Insert("FileAddress", FileAddress);
	
	TransmittedFiles = New Array;
	FileDetails = New TransferableFileDescription(ExecutionParameters.DialogBoxFullFileName, FileAddress);
	TransmittedFiles.Add(FileDetails);
	
	If Not GetFiles(TransmittedFiles, , , False) Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	SetModificationUniversalTime(ExecutionParameters.DialogBoxFullFileName, 
		ExecutionParameters.ChangeTimeSelected);
	
	ExecutionParameters.FileEncrypted = False;
	
	UpdateFromFileOnHardDriveContinued(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveContinued(ExecutionParameters)
	
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.FileData.Ref);
	PreviousVersion = ExecutionParameters.FileData.Version;
	FileNameAndExtensionInInfobase = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	CommonInternalClient.ShortenFileName(FileNameAndExtensionInInfobase);
	ExecutionParameters.Insert("FileDateInDatabase", ExecutionParameters.FileData.UniversalModificationDate);
	
	If ExecutionParameters.ChangeTimeSelected < ExecutionParameters.FileDateInDatabase Then // There is a newer one in the storage.
		
#If MobileClient Then
		QuestionTextTemplate = NStr("vi = 'Tệp được kết nhập từ thiết bị ""%1""
			|có ngày thay đổi sớm hơn tệp trong ứng dụng:
			|
			|%2 đã thay đổi tệp được kết nhập;
			|%3 đã thay đổi tệp trong ứng dụng.
			|
			|Thay thế tệp bởi phiên bản cũ hơn từ thiết bị?';
			|ru = 'Загружаемый файл с устройства ""%1"" 
			|имеет более раннюю дату изменения, чем файл в приложении:
			|
			|%2 изменен загружаемый файл;
			|%3 изменен файл в приложении.
			|
			|Заменить файл более старой версией с устройства?';
			|en = 'File ""%1"" to be imported from the device 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the device?'; fa = 'File ""%1"" to be imported from the device 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the device?';
			|it = 'Загружаемый файл с устройства ""%1"" 
			|имеет более раннюю дату изменения, чем файл в приложении:
			|
			|%2 изменен загружаемый файл;
			|%3 изменен файл в приложении.
			|
			|Заменить файл более старой версией с устройства?';
			|pl = 'File ""%1"" to be imported from the device 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the device?';
			|tr = '""%1"" 
			| cihazından yüklenen dosyanın düzenleme tarihi şu uygulamadaki dosyanın düzenleme tarihinden daha erken:
			|
			|%2yüklenen dosyaya değişiklik girildi;
			|%3uygulamadaki dosyaya değişiklik girildi.
			|
			|Dosya cihazdaki daha önceki sürümle değiştirilsin mi?'");
#Else
		QuestionTextTemplate = NStr("vi = 'Tệp được kết nhập từ máy tính ""%1"" 
			|có ngày thay đổi sớm hơn tệp trong ứng dụng:
			|
			|%2 đã thay đổi tệp được kết nhập;
			|%3 đã thay đổi tệp trong ứng dụng.
			|
			|Thay thế tệp bởi phiên bản cũ hơn từ máy tính?';
			|ru = 'Загружаемый файл с компьютера ""%1"" 
			|имеет более раннюю дату изменения, чем файл в приложении:
			|
			|%2 изменен загружаемый файл;
			|%3 изменен файл в приложении.
			|
			|Заменить файл более старой версией с компьютера?';
			|en = 'File ""%1"" to be imported from the computer 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the computer?'; fa = 'File ""%1"" to be imported from the computer 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the computer?';
			|it = 'Загружаемый файл с компьютера ""%1"" 
			|имеет более раннюю дату изменения, чем файл в приложении:
			|
			|%2 изменен загружаемый файл;
			|%3 изменен файл в приложении.
			|
			|Заменить файл более старой версией с компьютера?';
			|pl = 'File ""%1"" to be imported from the computer 
			|was modified earlier than the file in the application:
			|
			| the file to be imported was modified on %2,
			| the file in the application was modified on %3.
			|
			|Do you want to replace the file with the older version from the computer?';
			|tr = '""%1"" 
			| bilgisayardan yüklenen dosyanın düzenleme tarihi şu uygulamadaki dosyanın düzenleme tarihinden daha erken:
			|
			|%2 yüklenen dosyaya değişiklik girildi;
			|%3 programdaki dosyaya değişiklik girildi.
			|
			|Dosya cihazdaki daha önceki sürümle değiştirilsin mi?'");
#EndIf
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTextTemplate,
			String(ExecutionParameters.FileData.Ref),
			ToLocalTime(ExecutionParameters.ChangeTimeSelected),
			ToLocalTime(ExecutionParameters.FileDateInDatabase));
		
		CallbackDescription = New CallbackDescription("UpdateFromFileOnDiskOldVersion", ThisObject, ExecutionParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;

	EndIf;
	
	// Check if a file copy in the working directory is available for editing.
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	FullFileName = "";
	FileInWorkingDirectory = FileInLocalFilesCache(Undefined, PreviousVersion,
		FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	
#If Not WebClient And Not MobileClient Then
	If ExecutionParameters.FileData.CurrentUserEditsFile And FileInWorkingDirectory Then
		// Checking if the file is not locked by the application.
		Try
			SelectedFile = New File(FullFileName);
			ReadOnly = SelectedFile.GetReadOnly();
			SelectedFile.SetReadOnly(Not ReadOnly);
			SelectedFile.SetReadOnly(ReadOnly);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp ""%1"" đang mở để soạn.
					|Ban đầu cần kết thúc soạn, sau đó thao tác lại.';
					|ru = 'Файл ""%1"" открыт для редактирования.
					|Сначала необходимо закончить редактирование, а затем повторить действие.';
					|en = 'File ""%1"" is being edited.
					|Finish editing and try again.'; fa = 'File ""%1"" is being edited.
					|Finish editing and try again.';
					|it = 'Il file ""%1"" è aperto per la modifica.
					|All''inizio è necessario concludere la modifica, poi ripetere l''azione.';
					|pl = 'Plik ""%1"" jest otwarty do edycji.
					|Najpierw należy zakończyć edycję, a zatem powtórzyć działanie.';
					|tr = '""%1"" dosyası düzenleme için açık.
					|Önce düzenlemeyi tamamlayın, daha sonra işlemi tekrarlayın.'"),
				FullFileName);
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, Undefined);
			Return;
		EndTry;
	EndIf;
#EndIf
		
	If FileInWorkingDirectory And ExecutionParameters.FileNameAndExtensionOnHardDrive <> FileNameAndExtensionInInfobase Then
		Handler = New CallbackDescription("UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory", ThisObject, ExecutionParameters);
		DeleteFileFromWorkingDirectory(Handler, ExecutionParameters.FileData.CurrentVersion, True);
		Return;
	EndIf;
	
	UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnDiskOldVersion(Result, ExecutionParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.ChangeTimeSelected = ExecutionParameters.FileDateInDatabase;
	UpdateFromFileOnHardDriveContinued(ExecutionParameters);
		
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveAfterDeleteFileFromWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		If Result.Success <> True Then
			ReturnResult(ExecutionParameters.HandlerResults_1, False);
			Return;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("CurrentUserEditsFile", 
		ExecutionParameters.FileData.CurrentUserEditsFile);
	If Not ExecutionParameters.FileData.CurrentUserEditsFile Then
		
		ErrorText = "";
		CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(ExecutionParameters.FileData, ErrorText);
		If Not CanLockFile Then
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, Undefined);
			Return;
		EndIf;
		
		ErrorText = "";
		
		FileLockParameters = FilesOperationsInternalClientServer.FileLockParameters();
		FileLockParameters.UUID = ExecutionParameters.FormIdentifier;
		FileLockParameters.RaiseException1 = False;
		
		FileLocked1 = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData, ErrorText, 
			FileLockParameters);
		If Not FileLocked1 Then 
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, Undefined);
			Return;
		EndIf;
		
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		
	EndIf;
	
	NewFullFileName = "";
	ExecutionParameters.FileData.Insert("UpdatePathFromFileOnHardDrive", ExecutionParameters.DialogBoxFullFileName);
	ExecutionParameters.FileData.Extension = CommonClientServer.ExtensionWithoutPoint(
		ExecutionParameters.FileExtensionOnHardDrive);
	
	// Place the selected file to the working directory as the UpdatePathFromFileOnHardDrive property is specified.
	Handler = New CallbackDescription("UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory", ThisObject, 
		ExecutionParameters);
	GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, NewFullFileName, 
		ExecutionParameters.FormIdentifier);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure UpdateFromFileOnHardDriveAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	// The result processing is not required.
	If ExecutionParameters.FileEncrypted Then
		FilesOperationsInternalServerCall.CheckEncryptedFlag(ExecutionParameters.FileData.Ref, ExecutionParameters.FileEncrypted);
	EndIf;
	
	PassedFullFilePath = "";
	
	Handler = New CallbackDescription("UpdateFromFileOnHardDriveAfterFinishEdit", ThisObject, ExecutionParameters);
	If ExecutionParameters.CurrentUserEditsFile Then // File was already locked.
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormIdentifier);
		HandlerParameters.PassedFullFilePath = PassedFullFilePath;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		SaveFileChanges(HandlerParameters);
	Else
		HandlerParameters = FileUpdateParameters(Handler, ExecutionParameters.FileData.Ref, ExecutionParameters.FormIdentifier);
		HandlerParameters.StoreVersions = ExecutionParameters.FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = ExecutionParameters.FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = ExecutionParameters.FileData.CurrentVersionAuthor;
		HandlerParameters.PassedFullFilePath = PassedFullFilePath;
		HandlerParameters.CreateNewVersion = ExecutionParameters.CreateNewVersion;
		HandlerParameters.VersionComment = ExecutionParameters.VersionComment;
		EndEdit(HandlerParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UpdateFromFileOnHardDriveAfterFinishEdit(EditResult, ExecutionParameters) Export
	
	If ExecutionParameters.FileEncrypted Then
		DeleteFileWithoutConfirmation(ExecutionParameters.DialogBoxFullFileName);
	EndIf;
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region MarkingFileAsLockedForEditing

// Marks a file locked for editing.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result:
//      * Result - Boolean -  True if the operation is successful.
//      * AdditionalParameters - Arbitrary - a value that was specified on creating
//                                the NotifyDescription object.
//  ObjectRef            - CatalogRef.Files - file.
//  UUID - UUID - a form UUID.
//
Procedure LockFileByRef(HandlerResults_1, ObjectRef, UUID = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New CallbackDescription("LockFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	
	ErrorText = "";
	FileDataReceivedAndFileLocked = FilesOperationsInternalServerCall.GetFileDataAndLockFile(
		ExecutionParameters.ObjectRef, ExecutionParameters.FileData, ErrorText, ExecutionParameters.UUID);
		
	If Not FileDataReceivedAndFileLocked Then // If you cannot lock the file, an error message is displayed.
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	If Is1CEnterpriseExtensionAttached() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	FileData = ExecutionParameters.FileData; // See FilesOperationsInternalServerCall.FileData
	ShowUserNotification(
		NStr("vi = 'Soạn tệp';
			|ru = 'Редактирование файла';
			|en = 'Edit file'; fa = 'ویرایش فایل';
			|it = 'Modifica del file';
			|pl = 'Edycja pliku';
			|tr = 'Dosya düzenle'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp ""%1""
			           |đã bị chiếm để chỉnh sửa.';
			           |ru = 'Файл ""%1""
			           |занят для редактирования.';
			           |en = 'File ""%1""
			           |is locked for editing.'; fa = 'File ""%1""
			           |is locked for editing.';
			           |it = 'Il file ""%1""
			           |è in corso di modifica.';
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'"), String(FileData.Ref)),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(1);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region MarkingFilesAsLockedForEditing

// Marks files as locked for editing.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FilesArray - Array - an array of files.
//
Procedure LockFilesByRefs(HandlerResults_1, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New CallbackDescription("LockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// Receiving an array of these files.
	FilesData = New Array;
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, FilesData);
	InArrayBoundary  = FilesData.UBound();
	
	For Indus = 0 To InArrayBoundary Do
		FileData = FilesData[InArrayBoundary - Indus];
		
		ErrorString = "";
		If Not FilesOperationsClientServer.WhetherPossibleLockFile(FileData, ErrorString)
		 Or ValueIsFilled(FileData.BeingEditedBy) Then // Cannot lock.
			
			FilesData.Delete(InArrayBoundary - Indus);
		EndIf;
	EndDo;
	
	// Lock files.
	LockedFilesCount = 0;
	
	For Each FileData In FilesData Do
		
		If Not FilesOperationsInternalServerCall.LockFile(FileData, "") Then 
			Continue;
		EndIf;
		
		If Is1CEnterpriseExtensionAttached() Then
			ForReading = False;
			InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		LockedFilesCount = LockedFilesCount + 1;
	EndDo;
	
	ShowUserNotification(
		NStr("vi = 'Chiếm tệp';
			|ru = 'Занять файлы';
			|en = 'Lock files'; fa = 'Lock files';
			|it = 'Occupare i file';
			|pl = 'Zająć pliki';
			|tr = 'Dosyaları kilitle'"),
		,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp (%1 trong số %2) đã bị chiếm để soạn.';
				|ru = 'Файлы (%1 из %2) заняты для редактирования.';
				|en = 'Files (%1 out of %2) are locked for editing.'; fa = 'Files (%1 out of %2) are locked for editing.';
				|it = 'I file (%1 su %2) sono in corso di modifica.';
				|pl = 'Pliki (%1 z %2) zajęte do edycji.';
				|tr = 'Dosyalar (%1''in %2) düzenleme için kilitlendi.'"),
			LockedFilesCount,
			ExecutionParameters.FilesArray.Count()),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(FilesData.Count());
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region OpeningFileForEditingViaLink

// Opens file for editing.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  ObjectRef            - CatalogRef.Files - file.
//  UUID - UUID - a form ID.
//  OwnerWorkingDirectory - String - working directory of the owner.
//
Procedure EditFileByRef(HandlerResults_1, ObjectRef,
	UUID = Undefined, OwnerWorkingDirectory = Undefined)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("UUID", UUID);
	HandlerParameters.Insert("OwnerWorkingDirectory", OwnerWorkingDirectory);
	
	Handler = New CallbackDescription("EditFileByRefAfterInstallExtension", ThisObject, HandlerParameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ExtensionAttached", Is1CEnterpriseExtensionAttached());
	ExecutionParameters.Insert("FileIsAlreadyEditedByCurrentUser", False);
	
	Result = FilesOperationsInternalServerCall.BorrowFileToEdit(ExecutionParameters.ObjectRef,
		ExecutionParameters.UUID, ExecutionParameters.OwnerWorkingDirectory);
		
	ExecutionParameters.FileData = Result.FileData;
	ExecutionParameters.FileIsAlreadyEditedByCurrentUser = Result.FileIsAlreadyEditedByCurrentUser;
	If Not Result.DataReceived Then
		StandardProcessing = True;
		FilesOperationsClientOverridable.OnFileCaptureError(ExecutionParameters.FileData, StandardProcessing);
		
		If StandardProcessing Then
			// If you cannot lock the file, an error message is displayed.
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, 
				Result.MessageText, False);
			Return;
		EndIf;
		
		ReturnResult(ExecutionParameters.HandlerResults_1, True);
		Return;
	EndIf;
	
	If Not ExecutionParameters.FileIsAlreadyEditedByCurrentUser Then
		ChangeLockedFilesCount(1);
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	FileData = ExecutionParameters.FileData; // See FilesOperationsInternalServerCall.FileData
	
	ShowUserNotification(NStr("vi = 'Soạn tệp';
								|ru = 'Редактирование файла';
								|en = 'Edit files'; fa = 'Edit files';
								|it = 'Modifica del file';
								|pl = 'Edycja pliku';
								|tr = 'Dosya düzenle'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp ""%1""
			           |đã bị chiếm để chỉnh sửa.';
			           |ru = 'Файл ""%1""
			           |занят для редактирования.';
			           |en = 'File ""%1""
			           |is locked for editing.'; fa = 'File ""%1""
			           |is locked for editing.';
			           |it = 'Il file ""%1""
			           |è in corso di modifica.';
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'"), String(FileData.Ref)),
			PictureLib.DialogInformation);
	
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(ExecutionParameters.HandlerResults_1, FileData.Ref, True);
		Return;
	EndIf;
	
	If ExecutionParameters.ExtensionAttached Then
		Handler = New CallbackDescription("EditFileByRefWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, "",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		Handler = New CallbackDescription("EditFileByRefCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	FileIsAlreadyEditedByCurrentUser = False;
	If Not ExecutionParameters.FileIsAlreadyEditedByCurrentUser Then
		FileIsAlreadyEditedByCurrentUser = True;
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, FileIsAlreadyEditedByCurrentUser);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileByRefCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Result = True);
	
EndProcedure

#EndRegion

#Region OpeningFileForEditing

// Opens file for editing.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData             - Structure
//  UUID - Form UUID.
//
Procedure EditFile(HandlerResults_1, FileData, UUID = Undefined) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New CallbackDescription("EditFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	// If File is not locked, lock it.
	If Not ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		Handler = New CallbackDescription("EditFileAfterLockFile", ThisObject, ExecutionParameters);
		LockFile(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
		Return;
	EndIf;
	
	EditFileAfterLockFile(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//
Procedure EditFileAfterLockFile(FileData, ExecutionParameters) Export
	
	If FileData = Undefined Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If FileData <> -1 Then
		ExecutionParameters.FileData = FileData;
	EndIf;
	
	// If File does not have a file, open the card.
	If ExecutionParameters.FileData.Version.IsEmpty() Then 
		ReturnResultAfterShowValue(
			ExecutionParameters.HandlerResults_1, ExecutionParameters.FileData.Ref, True);
		Return;
	EndIf;
	
	If Is1CEnterpriseExtensionAttached() Then
		Handler = New CallbackDescription(
			"EditFileWithExtensionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New CallbackDescription("EditFileWithoutExtensionCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileWithExtensionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Result.FileReceived = True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditFileWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Result = True);
	
EndProcedure

#EndRegion

#Region OpenFileVersions

// Continuation of the procedure (see above).
//
// Parameters:
//   ExtensionInstalled - Boolean
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataToOpen
//
Procedure OpenFileVersionAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If Is1CEnterpriseExtensionAttached() Then
		Handler = New CallbackDescription("OpenFileVersionAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID);
	Else
		If ExecutionParameters.FileData.Property("RefToBinaryFileData") 
				And ValueIsFilled(ExecutionParameters.FileData.RefToBinaryFileData) Then
			Address = ExecutionParameters.FileData.RefToBinaryFileData;
		Else
			Address = FilesOperationsInternalServerCall.GetURLToOpen(
				ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
		EndIf;

		FileName = CommonClientServer.GetNameWithExtension(
			ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
		
		GetFile(Address, FileName, True);
		
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileVersionAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived Then
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region UnlockingFilesWithoutUpdate

// Unlocks files without updating them.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FilesArray - Array - an array of files.
//
Procedure UnlockFilesByRefs(HandlerResults_1, Val FilesArray)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("FilesArray", FilesArray);
	
	Handler = New CallbackDescription("UnlockFilesByRefsAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFilesByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	// Receiving an array of these files.
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	InArrayBoundary = ExecutionParameters.FilesData.UBound();
	
	// Checking the ability to unlock files.
	For Indus = 0 To InArrayBoundary Do
		
		FileData = ExecutionParameters.FilesData[InArrayBoundary - Indus]; // See FilesOperationsInternalServerCall.FileData
		
		ErrorText = "";
		CanUnlockFile = AbilityToUnlockFile(
			FileData.Ref,
			FileData.CurrentUserEditsFile,
			FileData.BeingEditedBy,
			ErrorText);
		If Not CanUnlockFile Then
			ExecutionParameters.FilesData.Delete(InArrayBoundary - Indus);
		EndIf;
		
	EndDo;
	
	If Not Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
	
	Handler = New CallbackDescription("UnlockFilesByRefsAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
	
	ShowQueryBox(
		Handler,
		NStr("vi = 'Việc hủy chỉnh sửa tệp có thể
		           |làm mất các thay đổi của bạn.
		           |
		           |Tiếp tục?';
		           |ru = 'Отмена редактирования файлов может
		           |привести к потере Ваших изменений.
		           |
		           |Продолжить?';
		           |en = 'If you cancel editing,
		           |you will lose the changes.
		           |
		           |Do you want to continue?'; fa = 'If you cancel editing,
		           |you will lose the changes.
		           |
		           |Do you want to continue?';
		           |it = 'L''annullamento della modifica dei file potrebbe
		           |comportare la perdita delle modifiche.
		           |
		           |Continuare?';
		           |pl = 'Anulowanie edycji plików może
		           |spowodować utratę Twoich zmian.
		           |
		           |Kontynuować?';
		           |tr = 'Dosya düzenlemenin
		           | iptali, değişikliklerinizi kaybetmenize neden olabilir. 
		           |
		           |Devam edilsin mi?'"),
		QuestionDialogMode.YesNo,
		,
		DialogReturnCode.No);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   Response - DialogReturnCode
//         - Undefined
//   ExecutionParameters - Structure:
//     * FilesData - Array of See FilesOperations.FileData
//
Procedure UnlockFilesByRefsAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	// Lock files.
	For Each FileData In ExecutionParameters.FilesData Do
		
		Parameters = FileUnlockParameters(Undefined, FileData.Ref);
		Parameters.StoreVersions = FileData.StoreVersions;
		Parameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		Parameters.BeingEditedBy = FileData.BeingEditedBy;
		Parameters.NotAskAQuestion = True;
		UnlockFile(Parameters);
		
	EndDo;
	
	ShowUserNotification(
		NStr("vi = 'Hủy soạn tệp';
			|ru = 'Отменить редактирование файлов';
			|en = 'Cancel file editing'; fa = 'Cancel file editing';
			|it = 'Annullare la modifica dei file';
			|pl = 'Anulować edycję plików';
			|tr = 'Dosya düzenlemeyi iptal et'"),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hủy soạn tệp (%1 từ %2)';
				|ru = 'Отменено редактирование файлов (%1 из %2).';
				|en = 'File editing canceled (%1 out of %2).'; fa = 'File editing canceled (%1 out of %2).';
				|it = 'Modifica dei file annullata (%1 su %2).';
				|pl = 'Anulowano edytowanie plików (%1 z %2).';
				|tr = 'Dosya düzenleme iptal edildi (%1 / %2).'"),
			ExecutionParameters.FilesData.Count(),
			ExecutionParameters.FilesArray.Count()),
		PictureLib.DialogInformation);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region ReleaseFileDiscardChanges

// Returns:
//   Structure:
//    * HandlerResults_1    - CallbackDescription
//                              - Undefined - description of the procedure that receives the method
//                                result.
//    * ObjectRef            - CatalogRef.Files - file.
//    * Version                  - CatalogRef.FilesVersions - file version.
//    * StoreVersions           - Boolean - store versions.
//    * EditedByCurrentUser - Boolean - file is edited by the current user.
//    * BeingEditedBy             - CatalogRef.Users - user who locked the file.
//    * UUID - UUID - Client application form ID.
//    * NotAskAQuestion        - Boolean - do not ask "Cancellation of a file editing
//                                         may result in the loss of your changes. Continue?".
//
Function FileUnlockParameters(HandlerResults_1, ObjectRef) Export
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("ObjectRef", ObjectRef);
	HandlerParameters.Insert("Version");
	HandlerParameters.Insert("StoreVersions");
	HandlerParameters.Insert("CurrentUserEditsFile");
	HandlerParameters.Insert("BeingEditedBy");
	HandlerParameters.Insert("UUID");
	HandlerParameters.Insert("NotAskAQuestion", False);
	Return HandlerParameters;
	
EndFunction	

// Unlocks file without updating it.
//
// Parameters:
//  FileUnlockParameters - See FileUnlockParameters.
//
Procedure UnlockFile(FileUnlockParameters)
	
	Handler = New CallbackDescription("UnlockFileAfterInstallExtension", ThisObject, FileUnlockParameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("ContinueWork", True);
	
	If ExecutionParameters.StoreVersions = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		FileData = FilesOperationsInternalServerCall.FileData(
			?(ExecutionParameters.ObjectRef <> Undefined, ExecutionParameters.ObjectRef, ExecutionParameters.Version),,FileDataParameters);
		
		If Not ValueIsFilled(ExecutionParameters.ObjectRef) Then
			ExecutionParameters.ObjectRef = FileData.Ref;
		EndIf;
		ExecutionParameters.StoreVersions                      = FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = FileData.BeingEditedBy;
		
		ExecutionParameters.FileData = FileData;
		
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	If ExecutionParameters.NotAskAQuestion = False Then
		ExecutionParameters.HandlerResults_1 = CompletionHandler(ExecutionParameters.HandlerResults_1);
		Handler = New CallbackDescription("UnlockFileAfterRespondQuestionCancelEdit", ThisObject, ExecutionParameters);
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Việc hủy chỉnh sửa tệp
			           |""%1""
			           |có thể khiến làm mất các thay đổi.
			           |
			           |Tiếp tục?';
			           |ru = 'Отмена редактирования файла
			           |""%1""
			           |может привести к потере внесенных изменений.
			           |
			           |Продолжить?';
			           |en = 'If you cancel editing file
			           |""%1"",
			           |you might lose the changes.
			           |
			           |Do you want to continue?'; fa = 'If you cancel editing file
			           |""%1"",
			           |you might lose the changes.
			           |
			           |Do you want to continue?';
			           |it = 'L''annullamento della modifica del file
			           |""%1""
			           |potrebbe comportare la perdita delle modifiche apportate.
			           |
			           |Continuare?';
			           |pl = 'Anulowanie edycji pliku
			           |""%1""
			           |może spowodować utratę wprowadzonych zmian.
			           |
			           |Kontynuować?';
			           |tr = '
			           |""%1""
			           |dosya düzenlemesinin iptali değişikliklerin kaybolmasına yol açabilir.
			           |
			           |Devam edilsin mi?'"),
			String(ExecutionParameters.ObjectRef));
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
		Return;
	EndIf;
	
	UnlockFileAfterRespondQuestionCancelEdit(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileAfterRespondQuestionCancelEdit(Response, ExecutionParameters) Export
	
	If Response <> -1 Then
		If Response = DialogReturnCode.Yes Then
			ExecutionParameters.ContinueWork = True;
		Else
			ExecutionParameters.ContinueWork = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.ContinueWork Then
		
		FilesOperationsInternalServerCall.GetFileDataAndUnlockFile(ExecutionParameters.ObjectRef,
			ExecutionParameters.FileData, ExecutionParameters.UUID);
		NotifyChanged(TypeOf(ExecutionParameters.ObjectRef));
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.ObjectRef);
		
		If Is1CEnterpriseExtensionAttached() Then
			ForReading = True;
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		If Not ExecutionParameters.NotAskAQuestion Then
			ShowUserNotification(
				NStr("vi = 'Tệp đã giải phóng';
					|ru = 'Файл освобожден';
					|en = 'File released'; fa = 'File released';
					|it = 'File librato';
					|pl = 'Plik zwolniony';
					|tr = 'Dosya bırakıldı'"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.DialogInformation);
		EndIf;
		
		ChangeLockedFilesCount();
		
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region WritingFileChanges

// Start recording the file changes.
//
// Parameters:
//   FileUpdateParameters - See FileUpdateParameters.
//
Procedure SaveFileChanges(FileUpdateParameters) 
	
	Handler = New CallbackDescription("SaveFileChangesAfterInstallExtensions", ThisObject, FileUpdateParameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
		
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesAfterInstallExtensions(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FileData", Undefined);
	ExecutionParameters.Insert("TempStorageAddress", Undefined);
	ExecutionParameters.Insert("FullFilePath", Undefined);
	
	If Is1CEnterpriseExtensionAttached() Then
		SaveFileChangesWithExtension(ExecutionParameters);
	Else
		SaveFileChangesWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtension(ExecutionParameters)
	// Code for the thin client, thick client, and web client with the attached extension.
	
	FileData = FilesOperationsInternalServerCall.FileDataAndWorkingDirectory(ExecutionParameters.ObjectRef);
	ExecutionParameters.FileData = FileData;
	ExecutionParameters.StoreVersions = FileData.StoreVersions;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		FileData.Ref,
		FileData.CurrentUserEditsFile,
		FileData.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = ExecutionParameters.PassedFullFilePath;
	If ExecutionParameters.FullFilePath = "" Then
		ExecutionParameters.FullFilePath = FileData.FullFileNameInWorkingDirectory;
	EndIf;
	
	// Checks whether there is a file on the computer.
	ExecutionParameters.Insert("NewVersionFile", New File(ExecutionParameters.FullFilePath));
	If Not ExecutionParameters.NewVersionFile.Exists() Then
		If Not IsBlankString(ExecutionParameters.FullFilePath) Then
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đặt tệp 
						   |""%1""
				           |vào ứng dụng do nó không tồn tại trên máy tính:
				           |%2.
				           |
				           |Hủy chiếm tệp?';
				           |ru = 'Не удалось поместить в приложение файл 
				           |""%1""
				           |так как он не существует на компьютере:
				           |%2.
				           |
				           |Освободить файл?';
				           |en = 'Cannot store
				           |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |%2.
				           |
				           |Do you want to release the file?'; fa = 'Cannot store
						   |the ""%1"" file
						   |to the application as it does not exist on the computer:
						   |%2.
						   |
						   |Do you want to release the file?';
				           |it = 'Не удалось поместить в приложение файл 
				           |""%1""
				           |так как он не существует на компьютере:
				           |%2.
				           |
				           |Освободить файл?';
				           |pl = 'Cannot store
				           |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |%2.
				           |
				           |Do you want to release the file?';
				           |tr = '""%1"" dosyası bilgisayarda
				           |bulunmadığından dolayı uygulamaya yerleştirilemedi:
				           |%2.
				           |
				           |Dosya boşaltılsın mı?'"),
				String(FileData.Ref),
				ExecutionParameters.FullFilePath);
		Else
			WarningString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đặt tệp 
						   |""%1""
				           |vào ứng dụng do nó không tồn tại trên máy tính.
				           |
				           |Hủy chiếm tệp?';
				           |ru = 'Не удалось поместить в приложение файл 
				           |""%1""
				           |так как он не существует на компьютере.
				           |
				           |Освободить файл?';
				           |en = 'Cannot store
				           |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |
				           |Do you want to release the file?'; fa = 'Cannot store
						   |the ""%1"" file
						   |to the application as it does not exist on the computer:
						   |
						   |Do you want to release the file?';
				           |it = 'Не удалось поместить в приложение файл 
				           |""%1""
				           |так как он не существует на компьютере.
				           |
				           |Освободить файл?';
				           |pl = 'Cannot store
				           |the ""%1"" file
				           |to the application as it does not exist on the computer:
				           |
				           |Do you want to release the file?';
				           |tr = '""%1"" dosyası bilgisayarda
				           |bulunmadığından dolayı uygulamaya yerleştirilemedi.
				           |
				           |Dosya boşaltılsın mı?'"),
				String(FileData.Ref));
		EndIf;
		
		Handler = New CallbackDescription("SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, WarningString, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	// Requesting a comment and version storage flag.
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If FileData.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			CreateNewVersionAvailability = FileData.CurrentVersionAuthor = FileData.BeingEditedBy;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
			SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
			Return;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    FileData.Ref);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New CallbackDescription("SaveFileChangesWithExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SavingFileVersion", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterRespondQuestionUnlockFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		UnlockFileWithoutQuestion(ExecutionParameters.FileData, ExecutionParameters.FormIdentifier);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, False);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ReturnCode = Result.ReturnCode;
	If ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterCheckNewVersion(ExecutionParameters)
	
	If Not ExecutionParameters.FileData.Encrypted Then
		SaveFileChangesWithExtensionAfterCheckEncrypted(ExecutionParameters);
		Return;
	EndIf;
	
	// The file with the encrypted again flag is encrypted for the same certificates.
	
	EncryptFileBeforePutFileInFileStorage(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//
Procedure SaveFileChangesWithExtensionAfterCheckEncrypted(ExecutionParameters)
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", ExecutionParameters.NewVersionFile);
	FileInfo1.Comment = ExecutionParameters.VersionComment;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	If ExecutionParameters.Property("AddressAfterEncryption") Then
		FileInfo1.TempFileStorageAddress = ExecutionParameters.AddressAfterEncryption;
	Else
		Files = New Array;
		LongDesc = New TransferableFileDescription(ExecutionParameters.FullFilePath, "");
		Files.Add(LongDesc);
		
		PlacedFiles = New Array;
		FilesPut = PutFiles(Files, PlacedFiles, , False, ExecutionParameters.FormIdentifier);
		
		If Not FilesPut Then
			ReturnResult(ExecutionParameters.HandlerResults_1, True);
			Return;
		EndIf;
		
		If PlacedFiles.Count() = 1 Then
			FileInfo1.TempFileStorageAddress = PlacedFiles[0].Location;
		EndIf;
	EndIf;
	
	CommonFilesOperationsSettings = CommonFilesOperationsSettings();
	DirectoryName = UserWorkingDirectory();
	
	RelativeFilePath = "";
	If ExecutionParameters.FileData.OwnerWorkingDirectory <> "" Then // Has working directory.
		RelativeFilePath = ExecutionParameters.FullFilePath;
	Else
		Position = StrFind(ExecutionParameters.FullFilePath, DirectoryName);
		If Position <> 0 Then
			RelativeFilePath = Mid(ExecutionParameters.FullFilePath, StrLen(DirectoryName) + 1);
		EndIf;
	EndIf;
	
	If Not CommonFilesOperationsSettings.ExtractTextFilesOnServer Then
		FileInfo1.TempTextStorageAddress = ExtractTextToTempStorage(ExecutionParameters.FullFilePath,
			ExecutionParameters.FormIdentifier);
	Else
		FileInfo1.TempTextStorageAddress = "";
	EndIf;
	
	DontChangeRecordInWorkingDirectory = False;
	If ExecutionParameters.PassedFullFilePath <> "" Then
		DontChangeRecordInWorkingDirectory = True;
	EndIf;
	
	VersionUpdated = FilesOperationsInternalServerCall.SaveFileChanges(ExecutionParameters.FileData.Ref, FileInfo1, 
		DontChangeRecordInWorkingDirectory, RelativeFilePath, ExecutionParameters.FullFilePath, 
		ExecutionParameters.FileData.OwnerWorkingDirectory <> "", ExecutionParameters.FormIdentifier);

	If IsTempStorageURL(FileInfo1.TempTextStorageAddress) Then
		DeleteFromTempStorage(FileInfo1.TempTextStorageAddress);
	EndIf;

	If ExecutionParameters.ShouldShowUserNotification Then
		If VersionUpdated Then
			ShowUserNotification(
				NStr("vi = 'Đã lưu phiên bản mới';
					|ru = 'Новая версия сохранена';
					|en = 'New version saved'; fa = 'New version saved';
					|it = 'Nuova versione salvata';
					|pl = 'Nowa wersja została zapisana';
					|tr = 'Yeni sürüm kaydedildi'"),
				ExecutionParameters.FileData.URL,
				ExecutionParameters.FileData.FullVersionDescription,
				PictureLib.DialogInformation);
		Else
			ShowUserNotification(
				NStr("vi = 'Chưa lưu phiên bản mới';
					|ru = 'Новая версия не сохранена';
					|en = 'New version not saved'; fa = 'New version not saved';
					|it = 'Nuova versione non salvata';
					|pl = 'Nowa wersja nie została zapisana';
					|tr = 'Yeni sürüm kaydedilmedi'"),,
				NStr("vi = 'Tệp không thay đổi';
					|ru = 'Файл не изменился';
					|en = 'The file is not changed.'; fa = 'The file is not changed.';
					|it = 'Il file non è stato modificato';
					|pl = 'Plik się nie zmienił';
					|tr = 'Dosya değişmedi'"),
				PictureLib.DialogInformation);
			Handler = New CallbackDescription("SaveFileChangesWithExtensionAfterShowNotification", ThisObject, ExecutionParameters);
			ShowInformationFileWasNotModified(Handler);
			Return;
		EndIf;
	EndIf;
	
	SaveFileChangesWithExtensionAfterShowNotification(-1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithExtensionAfterShowNotification(Result, ExecutionParameters) Export
	
	If  TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		CommonClient.CommonSettingsStorageSave(
			"ApplicationSettings","ShowFileNotModifiedFlag", False,,, True);
		RefreshReusableValues();
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtension(ExecutionParameters)
	
	If ExecutionParameters.StoreVersions = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
		ExecutionParameters.StoreVersions                      = ExecutionParameters.FileData.StoreVersions;
		ExecutionParameters.CurrentUserEditsFile = ExecutionParameters.FileData.CurrentUserEditsFile;
		ExecutionParameters.BeingEditedBy                        = ExecutionParameters.FileData.BeingEditedBy;
		ExecutionParameters.CurrentVersionAuthor                 = ExecutionParameters.FileData.CurrentVersionAuthor;
	EndIf;
	
	// Checking the ability to unlock the file.
	ErrorText = "";
	CanUnlockFile = AbilityToUnlockFile(
		ExecutionParameters.ObjectRef,
		ExecutionParameters.CurrentUserEditsFile,
		ExecutionParameters.BeingEditedBy,
		ErrorText);
	If Not CanUnlockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFilePath = "";
	If ExecutionParameters.CreateNewVersion = Undefined Then
		
		// Requesting a comment and version storage flag.
		ExecutionParameters.CreateNewVersion = True;
		CreateNewVersionAvailability = True;
		
		If ExecutionParameters.StoreVersions Then
			ExecutionParameters.CreateNewVersion = True;
			CreateNewVersionAvailability = ExecutionParameters.CurrentVersionAuthor = ExecutionParameters.BeingEditedBy;
		Else
			ExecutionParameters.CreateNewVersion = False;
			CreateNewVersionAvailability = False;
		EndIf;
		
		ParametersStructure = New Structure;
		ParametersStructure.Insert("FileRef",                    ExecutionParameters.ObjectRef);
		ParametersStructure.Insert("VersionComment",            "");
		ParametersStructure.Insert("CreateNewVersion",            ExecutionParameters.CreateNewVersion);
		ParametersStructure.Insert("CreateNewVersionAvailability", CreateNewVersionAvailability);
		
		Handler = New CallbackDescription("SaveFileChangesWithoutExtensionAfterPutFileOnServer", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SavingFileVersion", ParametersStructure, , , , , Handler);
		
	Else // The CreateNewVersion and VersionComment parameters are external.
		
		If ExecutionParameters.StoreVersions Then
			If ExecutionParameters.CurrentVersionAuthor <> ExecutionParameters.BeingEditedBy Then
				ExecutionParameters.CreateNewVersion = True;
			EndIf;
		Else
			ExecutionParameters.CreateNewVersion = False;
		EndIf;
		
		SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterPutFileOnServer(Result, ExecutionParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Result.ReturnCode <> DialogReturnCode.OK Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.CreateNewVersion = Result.CreateNewVersion;
	ExecutionParameters.VersionComment = Result.VersionComment;
	
	SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterCheckNewVersion(ExecutionParameters)
	
	Handler = New CallbackDescription("SaveFileChangesWithoutExtensionAfterReminder", ThisObject, ExecutionParameters);
	ShowReminderBeforePutFile(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterReminder(Result, ExecutionParameters) Export
	
	If Result.Value = DialogReturnCode.OK Then
		
		If  TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
			CommonClient.CommonSettingsStorageSave(
				"ApplicationSettings", "ShowTooltipsOnEditFiles", False,,, True);
		EndIf;
		Handler = New CallbackDescription("SaveFileChangesWithoutExtensionAfterImportFile", ThisObject, ExecutionParameters);
		BeginPutFile(Handler, , ExecutionParameters.FullFilePath, , ExecutionParameters.FormIdentifier);
		
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("ImportedFileAddress", Address);
	ExecutionParameters.Insert("SelectedFileName", SelectedFileName);
	
	If ExecutionParameters.FileData = Undefined Then
		FileDataParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataParameters.GetBinaryDataRef = False;
		FileData = FilesOperationsInternalServerCall.FileData(ExecutionParameters.ObjectRef,,FileDataParameters);
	Else
		FileData = ExecutionParameters.FileData;
	EndIf;
	If Not FileData.Encrypted Then
		SaveFileChangesWithoutExtensionAfterEncryptFile(Null, ExecutionParameters);
		Return;
	EndIf;
	If CertificatesNotSpecified(FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("vi = 'Mã hóa tệp';
													|ru = 'Шифрование файла';
													|en = 'Encrypt file'; fa = 'Encrypt file';
													|it = 'Cifratura del file';
													|pl = 'Szyfrowanie pliku';
													|tr = 'Dosya şifreleme'"));
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("Data",              Address);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New CallbackDescription("SaveFileChangesWithoutExtensionAfterEncryptFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithoutExtensionAfterEncryptFile(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
	ExecutionParameters.TempStorageAddress = Address;
	FileInfo1.TempFileStorageAddress = Address;
	FileInfo1.StoreVersions = ExecutionParameters.CreateNewVersion;
	
	PathStructure = CommonClientServer.ParseFullFileName(ExecutionParameters.SelectedFileName);
	If Not IsBlankString(PathStructure.Extension) Then
		FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
		FileInfo1.BaseName = PathStructure.BaseName;
	EndIf;
	
	Result = FilesOperationsInternalServerCall.GetFileDataAndSaveFileChanges(ExecutionParameters.ObjectRef, 
		FileInfo1, "", ExecutionParameters.FullFilePath, False, ExecutionParameters.FormIdentifier);
	ExecutionParameters.FileData = Result.FileData;
	If ExecutionParameters.ShouldShowUserNotification Then
		ShowUserNotification(
			NStr("vi = 'Đã lưu phiên bản mới';
				|ru = 'Новая версия сохранена';
				|en = 'The new version is saved.'; fa = 'The new version is saved.';
				|it = 'Nuova versione salvata';
				|pl = 'Nowa wersja została zapisana';
				|tr = 'Yeni sürüm kaydedildi'"),
			ExecutionParameters.FileData.URL,
			ExecutionParameters.FileData.FullVersionDescription,
			PictureLib.DialogInformation);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure


// For the SaveFileChanges and EndEdit procedure.
Procedure EncryptFileBeforePutFileInFileStorage(ExecutionParameters)
	
	If CertificatesNotSpecified(ExecutionParameters.FileData.EncryptionCertificatesArray) Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("vi = 'Mã hóa tệp';
													|ru = 'Шифрование файла';
													|en = 'Encrypt file'; fa = 'Encrypt file';
													|it = 'Cifratura del file';
													|pl = 'Szyfrowanie pliku';
													|tr = 'Dosya şifreleme'"));
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("Data",              ExecutionParameters.FullFilePath);
	DataDetails.Insert("Presentation",       ExecutionParameters.ObjectRef);
	DataDetails.Insert("CertificatesSet",   ExecutionParameters.ObjectRef);
	DataDetails.Insert("NoConfirmation",    True);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New CallbackDescription("EncryptFileBeforePutFileInFileStorageAfterFileEncryption",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EncryptFileBeforePutFileInFileStorageAfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails = Null Then
		Address = ExecutionParameters.ImportedFileAddress;
		
	ElsIf Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	Else
		If TypeOf(DataDetails.EncryptedData) = Type("BinaryData") Then
			Address = PutToTempStorage(DataDetails.EncryptedData,
				ExecutionParameters.FormIdentifier);
		Else
			Address = DataDetails.EncryptedData;
		EndIf;
	EndIf;
	
	ExecutionParameters.Insert("AddressAfterEncryption", Address);
	
	FinishEditWithExtensionAfterCheckEncrypted(ExecutionParameters);
	
EndProcedure

// For the SaveFileChanges and EndEdit procedure.
Function CertificatesNotSpecified(CertificatesArray)
	
	If CertificatesArray.Count() = 0 Then
		ShowMessageBox(,
			NStr("vi = 'Chưa chỉ ra chứng thư trong tệp đã mã hóa.
			           |Hãy giải mã tệp và mã hóa lại.';
			           |ru = 'У зашифрованного файла не указаны сертификаты.
			           |Расшифруйте файл и зашифруйте заново.';
			           |en = 'Certificates of the encrypted file are not specified.
			           |Please decrypt the file and then encrypt it again.'; fa = 'Certificates of the encrypted file are not specified.
			           |Please decrypt the file and then encrypt it again.';
			           |it = 'Non ci sono certificati per il file crittografato.
			           |Decrittografate il file e crittografatelo nuovamente.';
			           |pl = 'U zaszyfrowanego pliku nie są podane certyfikaty.
			           |Rozszyfruj plik i zaszyfruj ponownie.';
			           |tr = 'Şifrelenmiş dosya belirtilen sertifikalara sahip değil. 
			           |Dosyayı çöz ve tekrar şifrele.'"));
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region MarkingFileAsLockedForEditing

// Marking file locked for editing.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   FileData - Structure
//
Procedure LockFile(HandlerResults_1, FileData, UUID)
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1",    HandlerResults_1);
	HandlerParameters.Insert("FileData",             FileData);
	HandlerParameters.Insert("UUID", UUID);
	
	Handler = New CallbackDescription("LockFileAfterInstallExtension", ThisObject, HandlerParameters);
	
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExtensionInstalled - Boolean
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure LockFileAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ErrorText = "";
	CanLockFile = FilesOperationsClientServer.WhetherPossibleLockFile(
		ExecutionParameters.FileData,
		ErrorText);
	If Not CanLockFile Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, Undefined);
		Return;
	EndIf;
	
	ErrorText = "";
	
	FileLockParameters = FilesOperationsInternalClientServer.FileLockParameters();
	FileLockParameters.UUID = ExecutionParameters.UUID;
	
	FileLocked1 = FilesOperationsInternalServerCall.LockFile(ExecutionParameters.FileData,
		ErrorText, FileLockParameters);
	
	If Not FileLocked1 Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, ErrorText, Undefined);
		Return;
	EndIf;
	
	If Is1CEnterpriseExtensionAttached() Then
		ForReading = False;
		InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
		ReregisterFileInWorkingDirectory(ExecutionParameters.FileData, ForReading, InOwnerWorkingDirectory);
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Soạn tệp';
			|ru = 'Редактирование файла';
			|en = 'Edit files'; fa = 'Edit files';
			|it = 'Modifica del file';
			|pl = 'Edycja pliku';
			|tr = 'Dosya düzenle'"),
		ExecutionParameters.FileData.URL,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp ""%1""
			           |đã bị chiếm để chỉnh sửa.';
			           |ru = 'Файл ""%1""
			           |занят для редактирования.';
			           |en = 'File ""%1""
			           |is locked for editing.'; fa = 'File ""%1""
			           |is locked for editing.';
			           |it = 'Il file ""%1""
			           |è in corso di modifica.';
			           |pl = 'Plik ""%1""
			           |zajęty do edycji.';
			           |tr = 'Dosya ""%1"" 
			           | düzenlenmek üzere meşgul edildi.'"),
			String(ExecutionParameters.FileData.Ref)),
		PictureLib.DialogInformation);
	
	ChangeLockedFilesCount(1);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters.FileData);
	
EndProcedure

#EndRegion

#Region AddFilesAllowed

// Continues AttachedFilesClient procedure execution.AddFiles.
Procedure AddFilesCompletion(AttachedFile, AdditionalParameters) Export
	
	If AttachedFile = Undefined Then
		Return;
	EndIf;
	
	FileOwner = AdditionalParameters.FileOwner;
	NotifyChanged(AttachedFile);
	NotifyChanged(FileOwner);
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = FileOwner;
	NotificationParameters.FileOwner = NotificationParameters.Owner;
	NotificationParameters.File = AttachedFile;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, AttachedFile);
	
	If AdditionalParameters.Property("HandlerResults_1")
		And AdditionalParameters.HandlerResults_1 <> Undefined Then
		AttachedFilesArray = New Array;
		AttachedFilesArray.Add(AttachedFile);
		RunCallback(AdditionalParameters.HandlerResults_1, AttachedFilesArray);
	EndIf;
	
	OpenCardAfterCreateFromFile = False;
	If AdditionalParameters.Property("NotOpenCardAfterCreateFromFile") Then
		OpenCardAfterCreateFromFile = Not AdditionalParameters.NotOpenCardAfterCreateFromFile;
	EndIf;
	If OpenCardAfterCreateFromFile Then
		
		ShowUserNotification(
			NStr("vi = 'Tạo mới';
				|ru = 'Создание';
				|en = 'Create'; fa = 'ایجاد';
				|it = 'Creazione';
				|pl = 'Create';
				|tr = 'Oluştur'"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.DialogInformation);
		FilesOperationsClient.OpenFileForm(AttachedFile);
			
	EndIf;
		
EndProcedure

#EndRegion

#Region ActionWithFile

// Notification handler invoked by FilesOperationsInternalClient.ActionWithFile() to perform
//  final operations on a file. Used in methods
//	FilesOperationsInternal.FileDataToOpenAsync() and FilesOperationsInternal.FileDataToSaveAsync().
//
// Parameters:
//  ExecutionResult		- Structure - See TimeConsumingOperationsClient.NewResultLongOperation()
//  AdditionalParameters	- Arbitrary - Arbitrary data passed in the notification details.
//
Procedure EndActionWithFile(ExecutionResult, AdditionalParameters) Export

	If ExecutionResult = Undefined Then
		Return;
	EndIf;

	If ExecutionResult.Status = "Error" Then

		StandardSubsystemsClient.OutputErrorInfo(ExecutionResult.ErrorInfo);
		Return;
	EndIf;

	FileData = GetFromTempStorage(ExecutionResult.ResultAddress);

	UpdateAttachedFilesLists(FileData);

	If AdditionalParameters.ActionKind = "OpenFile" Then
	
		If AdditionalParameters.NotifyIfEncrypted And FileData.Encrypted Then
			// The file might be changed in another session
			NotifyChanged(FileData.Ref);
			Return;		
		EndIf;

		OpenFileInternal(FileData, AdditionalParameters.FileBeingEdited);
		
	ElsIf AdditionalParameters.ActionKind = "OpenFileVersion" Then

		OpenFileVersion(Undefined, FileData, AdditionalParameters.UUID);

	ElsIf AdditionalParameters.ActionKind = "OpenFileWithNotification" Then

		OpenFileWithNotification(Undefined, FileData);

	ElsIf AdditionalParameters.ActionKind = "SelectModeAndEditFile" Then

		HandlerParameters = New Structure;
		HandlerParameters.Insert("FileData", FileData);
		Handler = New CallbackDescription("ListSelectionAfterEditModeChoice", AdditionalParameters.OwnerForm, HandlerParameters);
		
		SelectModeAndEditFile(Handler, FileData, AdditionalParameters.CommandEditAvailability);
		
	ElsIf AdditionalParameters.ActionKind = "SaveAs" Then

		SaveAs(Undefined, FileData, AdditionalParameters.UUID);

	EndIf;
	
EndProcedure

// Notification handler invoked by FilesOperationsInternalClient.ActionWithFile() to perform
//  final operations on a file. Used in method
//	FilesOperationsInternal.FileDataEmailManagementAsync().
//
// Parameters:
//  ExecutionResult		- Structure - See TimeConsumingOperationsClient.NewResultLongOperation()
//  AdditionalParameters	- Arbitrary - Arbitrary data passed in the notification details.
//
Procedure EndActionWithFileEmailManagement(ExecutionResult, AdditionalParameters) Export

	If ExecutionResult = Undefined Then
		Return;
	EndIf;

	If ExecutionResult.Status = "Error" Then

		StandardSubsystemsClient.OutputErrorInfo(ExecutionResult.ErrorInfo);
		Return;
	EndIf;

	FileData = GetFromTempStorage(ExecutionResult.ResultAddress);

	If AdditionalParameters.ActionKind = "OpenFile" Then
		
		OpenFileInternal(FileData, AdditionalParameters.ForEditing);

	ElsIf AdditionalParameters.ActionKind = "SaveAs" Then

		SaveFileAsInternal(FileData);

	EndIf;

EndProcedure

Function TimeConsumingOperationParameters(FileOperationParameters)

	AttachedFile		= FileOperationParameters.AttachedFile;
	FileVersion				= FileOperationParameters.VersionRef;
	OwnerID	= FileOperationParameters.OwnerForm.UUID;	
	MethodName = FileOperationParameters.FileRetrievalMethodName;

    Result = New Structure;
	Result.Insert("OwnerID", OwnerID);
	
	If MethodName = "FilesOperationsInternal.FileDataToOpenAsync"
			Or MethodName = "FilesOperationsInternal.FileDataToSaveAsync" Then

		Result.Insert("MethodParameters", FileOperationParameters.MethodParameters);

		MethodParameters = Result.MethodParameters;
		MethodParameters.AttachedFile			= ?(ValueIsFilled(AttachedFile), AttachedFile, Undefined);
		MethodParameters.FileVersion					= ?(ValueIsFilled(FileVersion), FileVersion, Undefined);
		MethodParameters.FormIdentifier			= OwnerID;
		MethodParameters.FileGettingParameters		= FilesOperationsClientServer.FileGettingParameters();

		FileGettingParameters = MethodParameters.FileGettingParameters;
		
		FileGettingParameters.AddressInParentSession				= PutToTempStorage(Undefined, OwnerID);
		FileGettingParameters.CurrentVersionAddressInParentSession	= PutToTempStorage(Undefined, OwnerID);
		FillPropertyValues(FileGettingParameters, FileOperationParameters);
		
	ElsIf MethodName = "FilesOperationsInternal.FileDataEmailManagementAsync" Then

		Result.Insert("MethodParameters", FileOperationParameters.MethodParameters);

		MethodParameters = Result.MethodParameters;
		MethodParameters.AttachedFile		= AttachedFile;
		MethodParameters.FormIdentifier		= OwnerID;
		MethodParameters.FileGettingParameters = FilesOperationsClientServer.FileGettingParameters();
		
		ActionParameters = FileOperationParameters.ActionParameters;
		If ActionParameters.ActionKind = "OpenFile" Then
			MethodParameters.ForEditing = ActionParameters.ForEditing;
		EndIf;
		
		FileGettingParameters = MethodParameters.FileGettingParameters;
		FileGettingParameters.AddressInParentSession = PutToTempStorage(Undefined, OwnerID);
		FillPropertyValues(FileGettingParameters, FileOperationParameters);		
		
	EndIf;

	Return Result;	

EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Unlocking files without updating them.

#Region FileDeletionClearReadOnlyAttributeBeforeDelete

// Parameters:
//  FullFileName - String
//
Procedure DeleteFileWithoutConfirmation(FullFileName)
	
	File = New File(FullFileName);
	If File.Exists() Then
		Try
			File.SetReadOnly(False);
			DeleteFiles(FullFileName);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa tệp trong thư mục làm việc:
					|""%1"".
					|Có thể là tệp đang bị chiếm bởi ứng dụng khác.
					|
					|%2';
					|ru = 'Не удалось удалить файл в рабочем каталоге:
					|""%1"". 
					|Возможно он занят другим приложением.
					|
					|%2';
					|en = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2'; fa = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';
					|it = 'Non è stato possibile eliminare il file nel catalogo di lavoro:
					|""%1"".
					|Forse è impegnato da un''altra applicazione.
					|
					|%2';
					|pl = 'Nie udało się usunąć pliku w katalogu roboczym:
					|""%1"". 
					|Możliwe, że jest on zajęty przez inną aplikację.
					|
					|%2';
					|tr = 'Dosya çalışma dizininden silinemedi:
					|""%1"". 
					|Başka bir uygulama tarafından kullanılıyor olabilir.
					|
					|%2'"),
				FullFileName, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;	
	EndIf;
	
EndProcedure

// Delete the file, removing the readonly attribute.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Structure
//                       - Undefined - description of the procedure that receives
//                         the method result.
//  FullFileName - String -  a full file name.
//  AskQuestion - Boolean - ask question about deletion.
//  QuestionHeader - String - Question header - adds text to the question about deletion.
//
Procedure DeleteFile(Val HandlerResults_1, FullFileName)
	
	DeleteFileWithoutConfirmation(FullFileName);
	ReturnResult(HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region GetFileFromStorageToWorkingDir

// Receives File from the storage to working directory
// and returns a path to this file.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData        - See FilesOperationsInternalServerCall.FileDataAndWorkingDirectory
//  FullFileName     - String.
//  ForReading           - Boolean - False for reading, True for editing.
//  FormIdentifier - UUID - a form ID.
//
Procedure GetVersionFileToLocalFilesCache(HandlerResults_1, FileData, ForReading,
	FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(FileData,
		FileData.Version, ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		Return;
	EndIf;

	// Receiving a file path in the working directory and checking it for uniqueness.
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("vi = 'Không thể nhận tệp từ ứng dụng vào thư mục làm việc trên máy tính.';
				|ru = 'Не удалось получить файл из приложения в рабочий каталог на компьютере.';
				|en = 'Cannot get the file from the application to the working directory.'; fa = 'Cannot get the file from the application to the working directory.';
				|it = 'Не удалось получить файл из приложения в рабочий каталог на компьютере.';
				|pl = 'Cannot get the file from the application to the working directory.';
				|tr = 'Bilgisayarda çalışma dizinindeki uygulamadan dosya alınamıyor.'"));
		ReturnResult(HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// "File" is found in the working directory.
	// Check the change date and decide what to do next.
	Handler = New CallbackDescription("GetVersionFileToLocalFilesCacheAfterActionChoice", 
		ThisObject, ExecutionParameters);
	ActionOnOpenFileInWorkingDirectory(Handler, ExecutionParameters.FullFileName, FileData);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToLocalFilesCacheAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		Handler = New CallbackDescription("GetVersionFileToLocalFilesCacheAfterDelete", ThisObject, ExecutionParameters);
		DeleteFile(Handler, ExecutionParameters.FullFileName);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			
			RegegisterInWorkingDirectory(
				ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName,
				ExecutionParameters.ForReading,
				InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
//
Procedure GetVersionFileToLocalFilesCacheAfterDelete(FileDeleted, ExecutionParameters) Export
	
	GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
	
EndProcedure

#EndRegion

#Region GettingFileFromAppToComputer

// Get a file from the application to the computer. Returns a path to the file.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the procedure result.
//  FileData  - Structure
//  FullFileName - String - here a full file name is returned.
//  FormIdentifier - UUID - a form ID.
//
Procedure GetVersionFileToWorkingDirectory(HandlerResults_1, FileData, FullFileName,
	FormIdentifier = Undefined, AdditionalParameters = Undefined) Export
	
	DirectoryName = UserWorkingDirectory();	
	If DirectoryName = Undefined Or IsBlankString(DirectoryName) Then
		ReturnResult(HandlerResults_1, New Structure("FileReceived, FullFileName", False, FullFileName));
		Return;
	EndIf;
	
	If FileData.OwnerWorkingDirectory = "" 
		Or FileData.Version <> FileData.CurrentVersion And ValueIsFilled(FileData.CurrentVersion) Then
		GetVersionFileToLocalFilesCache(HandlerResults_1, FileData, FileData.ForReading,
			FormIdentifier, AdditionalParameters);
	Else
		
		If Not CanAccessWorkingDirectory(FileData.OwnerWorkingDirectory, FileData.Owner) Then
			GetVersionFileToLocalFilesCache(HandlerResults_1, FileData, FileData.ForReading,
			FormIdentifier, AdditionalParameters);
			Return;
		EndIf;
			
		GetVersionFileToFolderWorkingDirectory(HandlerResults_1, FileData, FullFileName, 
			FileData.ForReading, FormIdentifier, AdditionalParameters);
	EndIf;
	
EndProcedure

Function CanAccessWorkingDirectory(OwnerWorkingDirectory, Owner)

	Result = False;
	Try
		// If a directory is passed whose name is illegal in this file system,
		// no exception is thrown (however, the directory will be unavailable).
		InformationAboutTheCatalog = New File(OwnerWorkingDirectory);
		If Not InformationAboutTheCatalog.Exists() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Thư mục của thư mục tệp %1 không tồn tại.';
					|ru = 'Каталог папки файлов %1 не существует.';
					|en = 'The directory of the %1 file folder does not exist.'; fa = 'The directory of the %1 file folder does not exist.';
					|it = 'Каталог папки файлов %1 не существует.';
					|pl = 'The directory of the %1 file folder does not exist.';
					|tr = '%1 dosya klasörünün dizini mevcut değil.'"), 
				Owner);
		EndIf;
		CreateDirectory(OwnerWorkingDirectory);
		TestDirectoryName = OwnerWorkingDirectory + "CheckAccess\";
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
		Result = True;
	Except
		// Insufficient rights to create a directory, or this path does not exist.
		// Set the default settings.
		MessageText = NStr("vi = 'Thư mục làm việc %1 đối với thư mục tệp %2 không tồn tại hoặc không có quyền ghi. Đã khôi phục tùy chỉnh mặc định.
			|Thông tin kỹ thuật:
			|%3';
			|ru = 'Рабочий каталог %1 для папки файлов %2 не существует или нет права на запись. Восстановлены настройки по умолчанию.
			|Технические подробности:
			|%3';
			|en = 'Working directory %1 for file folder %2 does not exist or you don''t have write permissions. Default settings have been restored.
			|Technical details:
			|%3'; fa = 'Working directory %1 for file folder %2 does not exist or you don''t have write permissions. Default settings have been restored.
			|Technical details:
			|%3';
			|it = 'Рабочий каталог %1 для папки файлов %2 не существует или нет права на запись. Восстановлены настройки по умолчанию.
			|Технические подробности:
			|%3';
			|pl = 'Working directory %1 for file folder %2 does not exist or you don''t have write permissions. Default settings have been restored.
			|Technical details:
			|%3';
			|tr = 'Рабочий каталог %1 для папки файлов %2 не существует или нет права на запись. Восстановлены настройки по умолчанию.
			|Технические подробности:
			|%3'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, 
			OwnerWorkingDirectory, Owner, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Làm việc với tệp';
				|ru = 'Работа с файлами';
				|en = 'File management'; fa = 'مدیریت فایل';
				|it = 'Lavoro con file';
				|pl = 'Praca z plikami';
				|tr = 'Dosya işlemleri'", CommonClient.DefaultLanguageCode()),
			"Warning", MessageText, CommonClient.SessionDate(), True);

		OwnerWorkingDirectory = "";
		FilesOperationsInternalServerCall.CleanUpWorkingDirectory(Owner);
	EndTry;
	Return Result;
	
EndFunction

// See the procedure of the same name in FilesOperationsClient common module.
Procedure GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	AdditionalDefaultParameters = New Structure;
	AdditionalDefaultParameters.Insert("ForEditing", False);
	AdditionalDefaultParameters.Insert("FileData",       Undefined);
	FillPropertyValues(AdditionalDefaultParameters, AdditionalParameters);
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("AttachedFile", AttachedFile);
	Context.Insert("FormIdentifier", FormIdentifier);
	
	CommonClientServer.SupplementStructure(Context, AdditionalDefaultParameters);
	
	If TypeOf(Context.FileData) <> Type("Structure")
		Or Not ValueIsFilled(Context.FileData.RefToBinaryFileData) Then
		
		FileDataAdditionalParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataAdditionalParameters.FormIdentifier	= Context.FormIdentifier;
		FileDataAdditionalParameters.ForEditing	= Context.ForEditing;
		
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, FileDataAdditionalParameters));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("vi = 'Không thể nhận tệp vào máy tính từ ứng dụng do nguyên nhân:';
			|ru = 'Не удалось получить файл на компьютер из приложения по причине:';
			|en = 'Cannot get the file from the application. Reason:'; fa = 'Cannot get the file from the application. Reason:';
			|it = 'Не удалось получить файл на компьютер из приложения по причине:';
			|pl = 'Cannot get the file from the application. Reason:';
			|tr = 'Bilgisayarda çalışma dizinindeki uygulamadan dosya alınamıyor.'") + Chars.LF);
	
	If Context.ForEditing
	   And Context.FileData.BeingEditedBy <> UsersClient.AuthorizedUser() Then
		
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle 
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tệp đang được soạn %1.';
					|ru = 'Файл уже редактирует %1.';
					|en = 'The file is locked by %1.'; fa = 'The file is locked by %1.';
					|it = 'File già in modifica da %1';
					|pl = 'Plik już edytuje %1.';
					|tr = 'Dosya zaten %1 tarafından düzenleniyor.'"), String(Context.FileData.BeingEditedBy)));
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("ForEditing", ValueIsFilled(Context.FileData.BeingEditedBy));
	FileSystemClient.Attach1CEnterpriseExtension(New CallbackDescription(
		"GetAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("vi = 'Chưa cài đặt tiện ích mở rộng để làm việc với 1C:Enterprise.';
					|ru = 'Не установлено расширение для работы с 1С:Предприятием.';
					|en = '1C:Enterprise Extension is not installed.'; fa = '1C:Enterprise Extension is not installed.';
					|it = 'Non è stata installata l''estensione di lavoro con 1C:Enterprise.';
					|pl = 'Nie zainstalowano rozszerzenia do pracy z 1С:Enterprise.';
					|tr = '1C:Enterprise ile çalışma için uzantı yüklenmedi.'"));
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New CallbackDescription(
		"GetAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		Result = New Structure;
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory", Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	FileOperations = New Array;
	
	Action = New Structure;
	Action.Insert("Action", "CreateDirectory");
	Action.Insert("File", Context.FileDirectory);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("vi = 'Chưa tạo mới thư mục do nguyên nhân:';
				|ru = 'Создание каталога не выполнено по причине:';
				|en = 'Cannot create the directory. Reason:'; fa = 'Cannot create the directory. Reason:';
				|it = 'La creazione del catalogo non è stata effettuata a causa di:';
				|pl = 'Tworzenie katalogu nie powiodła się z powodu:';
				|tr = 'Dizin aşağıdakilerden dolayı oluşturulmadı:'"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", False));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("vi = 'Không thay đổi thuộc tính của tệp ""Chỉ xem"" do nguyên nhân:';
				|ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:';
				|en = 'Cannot change the ""Read-only"" property. Reason:'; fa = 'Cannot change the ""Read-only"" property. Reason:';
				|it = 'La modifica della proprietà del file ""Sola visualizzazione"" non è stata effettuata a causa di:';
				|pl = 'Zmiana właściwości pliku ""Tylko odczytywanie"" nie powiodło się z powodu:';
				|tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'"));
	FileOperations.Add(Action);
	
	Action = New Structure;
	Action.Insert("Action", "Get");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Address", Context.FileData.RefToBinaryFileData);
	Action.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Action);
	
	FileProperties = New Structure;
	FileProperties.Insert("ReadOnly", Not Context.ForEditing);
	FileProperties.Insert("UniversalModificationTime", Context.FileData.UniversalModificationDate);
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("vi = 'Không cài đặt thuộc tính tệp do nguyên nhân:';
				|ru = 'Установка свойств файла не выполнена по причине:';
				|en = 'Cannot set the file properties. Reason:'; fa = 'Cannot set the file properties. Reason:';
				|it = 'L''installazione delle proprietà del file non è stata effettuata a causa di:';
				|pl = 'Nie ustawiono właściwości pliku z powodu:';
				|tr = 'Dosya özellikleri şu sebeple ayarlanamıyor:'"));
	FileOperations.Add(Action);
	
	ProcessFile(New CallbackDescription(
			"GetAttachedFileAfterProcessFile", ThisObject, Context),
		FileOperations, Context.FormIdentifier);
	
EndProcedure

// Continue the GetAttachedFile procedure.
Procedure GetAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("FullFileName", "");
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
	Else
		Result.Insert("FullFileName", Context.FullFileName);
		Result.Insert("ErrorDescription", "");
	EndIf;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

// See the procedure with the same name in the AttachedFilesClient common module.
Procedure PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification",                Notification);
	Context.Insert("AttachedFile",        AttachedFile);
	Context.Insert("FormIdentifier",        FormIdentifier);
	Context.Insert("FileData",               Undefined);
	Context.Insert("FullNameOfFileToPut", Undefined);
	AdditionalParameters.Property("FileData",    Context.FileData);
	AdditionalParameters.Property("FullFileName", Context.FullNameOfFileToPut);
	
	If TypeOf(Context.FileData) <> Type("Structure") Then

		FileDataAdditionalParameters = FilesOperationsClientServer.FileDataParameters();
		FileDataAdditionalParameters.FormIdentifier				= Context.FormIdentifier;
		FileDataAdditionalParameters.GetBinaryDataRef	= False;
		
		Context.Insert("FileData", FilesOperationsInternalServerCall.GetFileData(
			Context.AttachedFile, FileDataAdditionalParameters));
	EndIf;
	
	Context.Insert("ErrorTitle",
		NStr("vi = 'Không thể sắp đặt tệp từ máy tính vào ứng dụng theo nguyên nhân:';
			|ru = 'Не удалось поместить файл с компьютера в приложение по причине:';
			|en = 'Cannot store the local file to the application. Reason:'; fa = 'Cannot store the local file to the application. Reason:';
			|it = 'Не удалось поместить файл с компьютера в приложение по причине:';
			|pl = 'Cannot store the local file to the application. Reason:';
			|tr = 'Dosya, aşağıdakilerden dolayı dosya depolama birimine yerleştirilemiyor:'") + Chars.LF);
	
	FileSystemClient.Attach1CEnterpriseExtension(New CallbackDescription(
		"PutAttachedFileAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterAttachExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		Result = New Structure;
		Result.Insert("ErrorDescription", Context.ErrorTitle
			+ NStr("vi = 'Chưa cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
					|ru = 'Не установлено расширение для работы с 1С:Предприятием.';
					|en = '1C:Enterprise Extension is not installed.'; fa = '1C:Enterprise Extension is not installed.';
					|it = 'Non è stata installata l''estensione di lavoro con 1C:Enterprise.';
					|pl = 'Nie zainstalowano rozszerzenia do pracy z 1С:Enterprise.';
					|tr = '1C:Enterprise ile çalışma için uzantı yüklenmedi.'"));
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	GetUserWorkingDirectory(New CallbackDescription(
		"PutAttachedFileAfterGetWorkingDirectory", ThisObject, Context));
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterGetWorkingDirectory(Result, Context) Export
	
	If ValueIsFilled(Result.ErrorDescription) Then
		ErrorResult = New Structure;
		ErrorResult.Insert("ErrorDescription", Context.ErrorTitle + Result.ErrorDescription);
		RunCallback(Context.Notification, ErrorResult);
		Return;
	EndIf;
	
	Context.Insert("UserWorkingDirectory", Result.Directory);
	Context.Insert("FileDirectory",   Context.UserWorkingDirectory + Context.FileData.RelativePath);
	Context.Insert("FullFileName", Context.FileDirectory + Context.FileData.FileName);
	
	File = New File(Context.FullFileName);
	
	File.BeginCheckingExistence(New CallbackDescription(
		"PutAttachedFileAfterGetWorkingDirectoryContinued",
		ThisObject,
		Context));
	
EndProcedure

Procedure PutAttachedFileAfterGetWorkingDirectoryContinued(FileExists, Context) Export
	If Not FileExists Then
		// for compatibility of the two subsystems.
		Context.Insert("FileDirectory",   Context.UserWorkingDirectory);
		Context.Insert("FullFileName", Context.FileData.FullFileNameInWorkingDirectory);
		
		If IsBlankString(Context.FileData.FullFileNameInWorkingDirectory) Then
			// the file is missing in the working directory, simply unlock it.
			UnlockFileWithoutQuestion(Context.FileData, Context.FormIdentifier);
			Return;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Context.FullNameOfFileToPut) Then
		Context.FullNameOfFileToPut = Context.FullFileName;
	EndIf;
	
	FileDetails = New TransferableFileDescription(Context.FullFileName);
	Files = New Array;
	Files.Add(FileDetails);
	
	FileOperations = New Array;
	
	Calls = New Array;
	
	If Context.FullFileName <> Context.FullNameOfFileToPut Then
		Action = New Structure;
		Action.Insert("Action", "CreateDirectory");
		Action.Insert("File", Context.FileDirectory);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("vi = 'Chưa tạo mới thư mục do nguyên nhân:';
					|ru = 'Создание каталога не выполнено по причине:';
					|en = 'Cannot create the directory. Reason:'; fa = 'Cannot create the directory. Reason:';
					|it = 'La creazione del catalogo non è stata effettuata a causa di:';
					|pl = 'Tworzenie katalogu nie powiodła się z powodu:';
					|tr = 'Dizin aşağıdakilerden dolayı oluşturulmadı:'"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "SetProperties1");
		Action.Insert("File",  Context.FullFileName);
		Action.Insert("Properties", New Structure("ReadOnly", False));
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("vi = 'Không thay đổi thuộc tính của tệp ""Chỉ xem"" do nguyên nhân:';
					|ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:';
					|en = 'Cannot change the ""Read-only"" property. Reason:'; fa = 'Cannot change the ""Read-only"" property. Reason:';
					|it = 'La modifica della proprietà del file ""Sola visualizzazione"" non è stata effettuata a causa di:';
					|pl = 'Zmiana właściwości pliku ""Tylko odczytywanie"" nie powiodło się z powodu:';
					|tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'"));
		FileOperations.Add(Action);
		
		Action = New Structure;
		Action.Insert("Action", "CopyFromSource");
		Action.Insert("File",     Context.FullFileName);
		Action.Insert("Source", Context.FullNameOfFileToPut);
		Action.Insert("ErrorTitle", Context.ErrorTitle
			+ NStr("vi = 'Không sao chép tệp do nguyên nhân:';
					|ru = 'Копирование файла не выполнено по причине:';
					|en = 'Cannot copy the file. Reason:'; fa = 'Cannot copy the file. Reason:';
					|it = 'La copia del file non è stata effettuata a causa di:';
					|pl = 'Kopiowanie pliku nie powiodło się z powodu:';
					|tr = 'Dosya aşağıdaki nedeniyle kopyalanmadı:'"));
		FileOperations.Add(Action);
		AddCall(Calls, "BeginCopyingFile", Context.FullNameOfFileToPut, Context.FullFileName, Undefined, Undefined);
	EndIf;
	
	Action = New Structure;
	Action.Insert("Action", "SetProperties1");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", New Structure("ReadOnly", True));
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("vi = 'Không thay đổi thuộc tính của tệp ""Chỉ xem"" do nguyên nhân:';
				|ru = 'Изменение свойства файла ""Только просмотр"" не выполнено по причине:';
				|en = 'Cannot change the ""Read-only"" property. Reason:'; fa = 'Cannot change the ""Read-only"" property. Reason:';
				|it = 'La modifica della proprietà del file ""Sola visualizzazione"" non è stata effettuata a causa di:';
				|pl = 'Zmiana właściwości pliku ""Tylko odczytywanie"" nie powiodło się z powodu:';
				|tr = 'Dosyanın ""Yalnızca görüntüle"" özelliğini değiştiremezsiniz:'"));
	FileOperations.Add(Action);
	
	Context.Insert("FileProperties", New Structure);
	Context.FileProperties.Insert("UniversalModificationTime");
	Context.FileProperties.Insert("BaseName");
	Context.FileProperties.Insert("Extension");
	
	Action = New Structure;
	Action.Insert("Action", "GetProperties");
	Action.Insert("File",  Context.FullFileName);
	Action.Insert("Properties", Context.FileProperties);
	Action.Insert("ErrorTitle", Context.ErrorTitle
		+ NStr("vi = 'Không nhận thuộc tính của tệp do nguyên nhân:';
				|ru = 'Получение свойств файла не выполнено по причине:';
				|en = 'Cannot get the file properties. Reason:'; fa = 'Cannot get the file properties. Reason:';
				|it = 'L''ottenimento delle proprietà del file non è stato effettuato a causa di:';
				|pl = 'Pobieranie właściwości pliku nie powiodło się z powodu:';
				|tr = 'Aşağıdakilerden dolayı dosya özellikleri alınmadı:'"));
	FileOperations.Add(Action);
	
	Context.Insert("PlacementAction", New Structure);
	Context.PlacementAction.Insert("Action", "Into");
	Context.PlacementAction.Insert("File",  Context.FullFileName);
	Context.PlacementAction.Insert("ErrorTitle", Context.ErrorTitle);
	FileOperations.Add(Context.PlacementAction);
	AddCall(Calls, "BeginPuttingFiles", Files, Undefined, False, Context.FormIdentifier);
	
	Context.Insert("FileOperations", FileOperations);
	
	BeginRequestingUserPermission(New CallbackDescription(
		"PutAttachedFileAfterGetPermissions", ThisObject, Context), Calls);
EndProcedure

Procedure AddCall(Calls, Method, P1, P2, P3, P4)
	
	Call = New Array;
	Call.Add(Method);
	Call.Add(P1);
	Call.Add(P2);
	Call.Add(P3);
	Call.Add(P4);
	
	Calls.Add(Call);
	
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterGetPermissions(PermissionsGranted, Context) Export
	
	If PermissionsGranted Then
		ProcessFile(New CallbackDescription(
				"PutAttachedFileAfterProcessFile", ThisObject, Context),
			Context.FileOperations, Context.FormIdentifier);
	EndIf;
		
EndProcedure

// Continues the PutAttachedFile procedure.
Procedure PutAttachedFileAfterProcessFile(ActionsResult, Context) Export
	
	Result = New Structure;
	
	If ValueIsFilled(ActionsResult.ErrorDescription) Then
		Result.Insert("ErrorDescription", ActionsResult.ErrorDescription);
		RunCallback(Context.Notification, Result);
		Return;
	EndIf;
	
	Result.Insert("ErrorDescription", "");
	
	Extension = Context.FileProperties.Extension;
	
	FileInfo = New Structure;
	FileInfo.Insert("UniversalModificationDate",   Context.FileProperties.UniversalModificationTime);
	FileInfo.Insert("FileAddressInTempStorage", Context.PlacementAction.Address);
	FileInfo.Insert("TempTextStorageAddress", "");
	FileInfo.Insert("BaseName",               Context.FileProperties.BaseName);
	FileInfo.Insert("Extension",                     Right(Extension, StrLen(Extension)-1));
	FileInfo.Insert("BeingEditedBy",                    Undefined);
	
	Try
		FilesOperationsInternalServerCall.UpdateAttachedFile(
			Context.AttachedFile, FileInfo);
	Except
		ErrorInfo = ErrorInfo();
		Result.Insert("ErrorDescription", Context.ErrorTitle + Chars.LF
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	RunCallback(Context.Notification, Result);
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Opening the explorer with positioning on the file.

// The procedure opens Windows Explorer positioning on File.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData          - See FilesOperationsInternalServerCall.FileData
//
Procedure FileDirectory(HandlerResults_1, FileData) Export
	
	// If File does not have the file, this operation is pointless.
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;
	
#If WebClient Then
	If Not Is1CEnterpriseExtensionAttached() Then
		Show1CEnterpriseExtensionRequiredMessageBox(HandlerResults_1);
		Return;
	EndIf;
#EndIf
	
	FullFileName = GetFilePathInWorkingDirectory(FileData);
	If OpenExplorerWithFile(FullFileName) Then
		Return;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		FileData.FullVersionDescription, FileData.Extension);
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("FileData", FileData);
	HandlerParameters.Insert("FileName", FileName);
	HandlerParameters.Insert("FullFileName", FullFileName);
	Handler = New CallbackDescription("FileDirectoryAfterRespondQuestionGetFile", ThisObject, HandlerParameters);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Lưu và mở thư mục';
													|ru = 'Сохранить и открыть каталог';
													|en = 'Save and open the directory'; fa = 'Save and open the directory';
													|it = 'Salvare e aprire la directory';
													|pl = 'Zapisz i otwórz katalog';
													|tr = 'Dizini kaydet ve aç'"));
	QuestionButtons.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
	ShowQueryBox(Handler,
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thư mục tệp không tồn tại. Tệp ""%1"" có thể chưa được mở trên máy tính này.
			|Lưu tệp vào máy tính và mở thư mục của tệp?';
			|ru = 'Каталог файла не существует. Возможно, на данном компьютере файл ""%1"" еще не открывался.
			|Сохранить файл на компьютер и открыть его каталог?';
			|en = 'The file directory does not exist. Probably file ""%1"" was never opened on this computer.
			|Do you want to save a local file copy and open its directory?'; fa = 'The file directory does not exist. Probably file ""%1"" was never opened on this computer.
			|Do you want to save a local file copy and open its directory?';
			|it = 'La directory del file è mancante. È possibile che su questo pc il file ""%1"" non è ancora stato aperto.
			|Salvare il file sul computer e aprirne la directory?';
			|pl = 'Katalog pliku nie istnieje. Być może, na tym komputerze plik ""%1"" nie był jeszcze otwierany.
			|Zapisać plik na komputerze i otworzyć jego katalog?';
			|tr = 'Dosya dizini yok. Belki de bu bilgisayarda ""%1"" dosyası henüz açılmamıştır. 
			|Dosya bilgisayara kaydedilsin ve dizini açılsın mı?'"),
			FileName),
		QuestionButtons);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FileDirectoryAfterRespondQuestionGetFile(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		Handler = New CallbackDescription("FileDirectoryAfterGetFileToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData, ExecutionParameters.FullFileName);
	Else
		FileDirectoryAfterGetFileToWorkingDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FileDirectoryAfterGetFileToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result <> -1 Then
		ExecutionParameters.FullFileName = Result.FullFileName;
		OpenExplorerWithFile(ExecutionParameters.FullFileName);
	EndIf;
	
	// For the option of storing files in volumes, delete the File from the temporary storage after receiving it.
	If IsTempStorageURL(ExecutionParameters.FileData.CurrentVersionURL) Then
		DeleteFromTempStorage(ExecutionParameters.FileData.CurrentVersionURL);
	EndIf;
	
EndProcedure

#EndRegion

#Region FileDeletionFromComputerAndInformationRegister

// Delete from the computer and information register.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  Ref  - CatalogRef.Files - file.
//  DeleteInWorkingDirectory - Boolean - delete even in the working directory.
//
Procedure DeleteFileFromWorkingDirectory(HandlerResults_1, Ref, DeleteInWorkingDirectory = False)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("Ref", Ref);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DirectoryName", UserWorkingDirectory());
	
	ExecutionParameters.Insert("FullFileNameFromRegister", Undefined);
	
	InOwnerWorkingDirectory = False;
	ExecutionParameters.FullFileNameFromRegister = FilesOperationsInternalServerCall.FullFileNameInWorkingDirectory(
		ExecutionParameters.Ref, ExecutionParameters.DirectoryName, False, InOwnerWorkingDirectory);
	
	If ExecutionParameters.FullFileNameFromRegister <> "" Then
		
		// We do not usually delete files in working directory, only if the DeleteInWorkingDirectory is passed.
		If Not InOwnerWorkingDirectory Or DeleteInWorkingDirectory = True Then
			
			FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
			
			If FileOnHardDrive.Exists() Then
				FileOnHardDrive.SetReadOnly(False);
				
				CompletionHandler = New CallbackDescription("DeleteFileFromWorkingDirectoryAfterDeleteFile", ThisObject);
				RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
				
				DeleteFile(ExecutionParameters, ExecutionParameters.FullFileNameFromRegister);
				If ExecutionParameters.AsynchronousDialog.Open = True Then
					Return;
				EndIf;
				
				DeleteFileFromWorkingDirectoryAfterDeleteFile(
					ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
				Return;
				
			EndIf;
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteFileFromWorkingDirectoryAfterDeleteFile(Result, ExecutionParameters) Export
	
	PathWithSubdirectory = ExecutionParameters.DirectoryName;
	Position = StrFind(ExecutionParameters.FullFileNameFromRegister, GetPathSeparator());
	If Position <> 0 Then
		PathWithSubdirectory = PathWithSubdirectory + Left(ExecutionParameters.FullFileNameFromRegister, Position);
	EndIf;
	
	FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
	If FilesArrayInDirectory.Count() = 0 Then
		If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
			Try
				DeleteFiles(PathWithSubdirectory);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(),
					"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			EndTry;	
		EndIf;
	EndIf;
	
	DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteFileFromWorkingDirectoryCompletion(ExecutionParameters)
	
	If ExecutionParameters.FullFileNameFromRegister = "" Then
		FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
	Else
		FileOnHardDrive = New File(ExecutionParameters.FullFileNameFromRegister);
		If Not FileOnHardDrive.Exists() Then
			FilesOperationsInternalServerCall.DeleteFromRegister(ExecutionParameters.Ref);
		EndIf;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

#EndRegion

#Region ClearUpWorkingDirectory

// Clear space to place file. If there is enough space, it does nothing.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  VersionAttributes  - See FilesOperationsInternalServerCall.FileData
//
Procedure ClearSpaceInWorkingDirectory(HandlerResults_1, VersionAttributes)

#If WebClient Then
	// The amount of free disk space cannot be determined in the web client.
	ReturnResultAfterShowWarning(
		HandlerResults_1,
		NStr("vi = 'Chỉ có thể xóa thư mục làm việc trong thin client.';
			|ru = 'Очистка рабочего каталога возможна только в тонком клиенте.';
			|en = 'You can clear the working directory only in the thin client.'; fa = 'You can clear the working directory only in the thin client.';
			|it = 'La pulizia della directory di lavoro è possibile solamente in thin client.';
			|pl = 'Oczyszczenie katalogu roboczego jest możliwe tylko w cienkim kliencie.';
			|tr = 'Çalışma dizininin temizlenmesi sadece ince istemcide yapılabilir.'"),
		Undefined);
	Return;
#EndIf
	
	MaxSize1 = PersonalFilesOperationsSettings().LocalFileCacheMaxSize;
	
	// If the size of "WorkingDirectory" is set to 0, assume that there's no limit
	// (the default limit is 10 MB).
	If MaxSize1 = 0 Then
		Return;
	EndIf;
	
	DirectoryName = UserWorkingDirectory();
	
	FilesArray = FindFiles(DirectoryName, GetAllFilesMask());
	
	WorkingDirectoryFilesSize = 0;
	TotalFilesCount = 0;
	// Calculating the full size of files in the working directory.
	GetFileListSize(DirectoryName, FilesArray, WorkingDirectoryFilesSize, TotalFilesCount);
	
	Size = VersionAttributes.Size;
	If WorkingDirectoryFilesSize + Size > MaxSize1 Then
		CleanUpWorkingDirectory(HandlerResults_1, WorkingDirectoryFilesSize, Size, False); // ClearAll = False.
	EndIf;
	
EndProcedure

// Clearing the working directory to make space. First it deletes the files 
// most recently placed in the working directory.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  WorkingDirectoryFilesSize  - Number - the size of files in working directory.
//  SizeOfFileToAdd - Number - size of the file to add.
//  ClearEverything - Boolean - delete all files in the directory (and not just delete files until the required amount of disk space is free).
//
Procedure CleanUpWorkingDirectory(HandlerResults_1, WorkingDirectoryFilesSize, SizeOfFileToAdd, ClearEverything) Export
	
#If WebClient Then
	ReturnResultAfterShowWarning(HandlerResults_1, NStr("vi = 'Chỉ có thể xóa thư mục làm việc trong ứng dụng (thin client).';
														|ru = 'Очистка рабочего каталога возможна только в приложении (тонкий клиент).';
														|en = 'You can clear the working directory only in the thin client.'; fa = 'You can clear the working directory only in the thin client.';
														|it = 'Pulizia catalogo di lavoro possibile solo nell''applicazione (thin client).';
														|pl = 'Wyczyszczenie folderu roboczego jest możliwe tylko aplikacji (cienki klient).';
														|tr = 'Çalışma dizininin temizlenmesi sadece uygulamada yapılabilir (ince istemci).'"), Undefined);
	Return;
#EndIf
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("WorkingDirectoryFilesSize", WorkingDirectoryFilesSize);
	HandlerParameters.Insert("SizeOfFileToAdd", SizeOfFileToAdd);
	HandlerParameters.Insert("ClearEverything", ClearEverything);
	
	ClearWorkingDirectoryStart(HandlerParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ClearWorkingDirectoryStart(ExecutionParameters)
	
	DirectoryName = UserWorkingDirectory();
	
	TableOfFiles = New Array;
	FilesArray = FindFiles(DirectoryName, "*");
	ProcessFilesTable(DirectoryName, FilesArray, TableOfFiles);
	
	// Server call intended for sorting.
	//  Sorting by date means that in the beginning, there will be items placed in the working directory long ago.
	FilesOperationsInternalServerCall.SortStructuresArray(TableOfFiles);
	
	PersonalSettings = PersonalFilesOperationsSettings();
	MaxSize1 = PersonalSettings.LocalFileCacheMaxSize;
	
	AverageFileSize = 1000;
	If TableOfFiles.Count() <> 0 Then
		AverageFileSize = ExecutionParameters.WorkingDirectoryFilesSize / TableOfFiles.Count();
	EndIf;
	
	If ExecutionParameters.ClearEverything Then
		AmountOfFreeSpaceRequired = 0;
	Else
		AmountOfFreeSpaceRequired = MaxSize1 / 10;
		If AverageFileSize * 3 / 2 > AmountOfFreeSpaceRequired Then
			AmountOfFreeSpaceRequired = AverageFileSize * 3 / 2;
		EndIf;
	EndIf;
	
	SpaceLeft = ExecutionParameters.WorkingDirectoryFilesSize + ExecutionParameters.SizeOfFileToAdd;
	ExecutionParameters.Insert("DirectoryName", DirectoryName);
	ExecutionParameters.Insert("MaxSize1", MaxSize1);
	ExecutionParameters.Insert("SpaceLeft", SpaceLeft);
	ExecutionParameters.Insert("AmountOfFreeSpaceRequired", AmountOfFreeSpaceRequired);
	ExecutionParameters.Insert("TableOfFiles", TableOfFiles);
	ClearWorkingDirectoryForFileToOpen(ExecutionParameters);
	
EndProcedure

// Parameters:
//   ExecutionParameters - Structure:
//     * TableOfFiles - Array of See FilesInWorkingDirectoryData
//
Procedure ClearWorkingDirectoryForFileToOpen(ExecutionParameters)
	
	IndexOf = 0;
	Title = NStr("vi = 'Xóa thư mục làm việc';
				|ru = 'Очистка рабочего каталога';
				|en = 'Clearing working directory'; fa = 'Clearing working directory';
				|it = 'Pulizia del catalogo di lavoro';
				|pl = 'Wyczyszczenie folderu roboczego';
				|tr = 'Çalışma dizininin temizlenmesi'");
	Text = NStr("vi = 'Xin vui lòng đợi...';
				|ru = 'Пожалуйста, подождите...';
				|en = 'Please wait…'; fa = 'لطفاً صبر کنید…';
				|it = 'Attendere prego...';
				|pl = 'Proszę czekać...';
				|tr = 'Lütfen bekleyin...'");
	Status(Title, 1, Text);
	For Each Item In ExecutionParameters.TableOfFiles Do
		
		IndexOf = IndexOf + 1;
		
		FullPath = ExecutionParameters.DirectoryName + Item.Path;
		FileOnHardDrive = New File(FullPath);
		FileOnHardDrive.SetReadOnly(False);
		DeleteFile(ExecutionParameters, FullPath);
		
		PathWithSubdirectory = ExecutionParameters.DirectoryName;
		Position = StrFind(Item.Path, GetPathSeparator());
		If Position <> 0 Then
			PathWithSubdirectory = ExecutionParameters.DirectoryName + Left(Item.Path, Position);
		EndIf;
		
		// If the directory is empty, deleting it.
		FilesArrayInDirectory = FindFiles(PathWithSubdirectory, "*");
		If FilesArrayInDirectory.Count() = 0 Then
			If PathWithSubdirectory <> ExecutionParameters.DirectoryName Then
				Try
					DeleteFiles(PathWithSubdirectory);
				Except
					EventLogClient.AddMessageForEventLog(EventLogEvent(),
						"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
				EndTry;	
			EndIf;
		EndIf;
		
		FilesOperationsInternalServerCall.DeleteFromRegister(Item.Version);
		
		If ExecutionParameters.AmountOfFreeSpaceRequired > 0 Then
			ExecutionParameters.SpaceLeft = ExecutionParameters.SpaceLeft - Item.Size;
			If ExecutionParameters.SpaceLeft < ExecutionParameters.MaxSize1 - ExecutionParameters.AmountOfFreeSpaceRequired Then
				Return; // If there is enough free space, exit the loop.
			EndIf;
		EndIf;
		
		If IndexOf % 10 = 0 Then
			Progress = ?(ExecutionParameters.AmountOfFreeSpaceRequired > 0,
				(ExecutionParameters.AmountOfFreeSpaceRequired - ExecutionParameters.SpaceLeft) * 100 / ExecutionParameters.AmountOfFreeSpaceRequired,
				IndexOf * 100 / ExecutionParameters.TableOfFiles.Count());
			Status(Title, Progress, Text);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region GettingFileOnServerAndRegisteringInLocalCache

// Receive the File from server and register it in the local cache.
//
// Parameters:
//   ExecutionParameters - Structure:
//     * HandlerResults_1 - CallbackDescription
//                            - Undefined - description of the procedure that receives the result.
//     * FileData - See FilesOperationsInternalServerCall.FileData
//     * FullFileNameInWorkingDirectory - String - here a full file name is returned.
//     * FileDateInDatabase - Date - file date in base.
//     * ForReading - Boolean - a file is placed for reading.
//     * FormIdentifier - UUID - Form ID.
//
Procedure GetFromServerAndRegisterInLocalFilesCache(Val ExecutionParameters)
	
	ExecutionParameters = CommonClient.CopyRecursive(ExecutionParameters);
	ExecutionParameters.Insert("InOwnerWorkingDirectory", ExecutionParameters.FileData.OwnerWorkingDirectory <> "");
	ExecutionParameters.Insert("DirectoryName", "");
	ExecutionParameters.Insert("DirectoryNamePreviousValue", "");
	ExecutionParameters.Insert("FileName", "");
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	ExecutionParameters.Insert("FileReceived", False);
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.DirectoryName = UserWorkingDirectory();
		ExecutionParameters.DirectoryNamePreviousValue = ExecutionParameters.DirectoryName;
		
		// Generating a file name with an extension.
		ExecutionParameters.FileName = ExecutionParameters.FileData.FullVersionDescription;
		If Not IsBlankString(ExecutionParameters.FileData.Extension) Then 
			ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(
				ExecutionParameters.FileName, ExecutionParameters.FileData.Extension);
		EndIf;
		
		CommonInternalClient.ShortenFileName(ExecutionParameters.FileName);
		
		ExecutionParameters.FullFileName = "";
		If Not IsBlankString(ExecutionParameters.FileName) Then
			ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName 
				+ FilesOperationsInternalClientServer.UniqueNameByWay(ExecutionParameters.DirectoryName,
					ExecutionParameters.FileName);
		EndIf;
		
		If IsBlankString(ExecutionParameters.FileName) Then
			ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
			Return;
		EndIf;
		
		ExecutionParameters.FullPathMaxSize = 260;
		If Lower(ExecutionParameters.FileData.Extension) = "xls" Or Lower(ExecutionParameters.FileData.Extension) = "xlsx" Then
			// Excel file name length together with the path cannot exceed 218 characters.
			ExecutionParameters.FullPathMaxSize = 218;
		EndIf;
		
		MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // "5" is the minimum length of "C:\1\"
		
		If ExecutionParameters.InOwnerWorkingDirectory = False Then
#If Not WebClient Then
			If StrLen(ExecutionParameters.FullFileName) > ExecutionParameters.FullPathMaxSize Then
				UserDirectoryPath = UserDataDir();
				MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
				
				// If the file name + 5 exceeds 260 characters, output the message "Replace the file name with a shorter one."
				If StrLen(ExecutionParameters.FileName) > MaxFileNameLength Then
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Độ dài đường dẫn đến tệp (thư mục làm việc cộng tên tệp) vượt quá %1 ký tự
						           |%2';
						           |ru = 'Длина пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
						           |%2';
						           |en = 'The file path (working directory + file name) is longer than %1 characters:
						           |%2'; fa = 'The file path (working directory + file name) is longer than %1 characters:
						           |%2';
						           |it = 'La lunghezza del percorso al file (directory di lavoro più il nome del file) supera i %1 caratteri
						           |%2';
						           |pl = 'Długość ścieżki do pliku (katalog roboczy plus nazwa pliku) przekracza %1 znaków
						           |%2';
						           |tr = 'Dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1karakterleri aşıyor
						           |%2'"),
						ExecutionParameters.FullPathMaxSize,
						ExecutionParameters.FullFileName);
					MessageText = MessageText + Chars.CR + Chars.CR
						+ NStr("vi = 'Hãy thay đổi tên tệp cho ngắn gọn hơn.';
								|ru = 'Измените имя файла на более короткое.';
								|en = 'Please choose a shorter file name.'; fa = 'Please choose a shorter file name.';
								|it = 'Modificate il nome del file in uno più corto.';
								|pl = 'Zmień nazwę pliku na krótszą.';
								|tr = 'Dosya adını kısaltın.'");
					ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, 
						MessageText, ExecutionParameters);
					Return;
					
				EndIf;
				
				GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
				Return;
				
			EndIf;
#EndIf
		EndIf;
		
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheContinued(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(Response, ExecutionParameters)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Độ dài đường dẫn đến tệp vượt quá %1 ký tự:
		|%2
		|
		|Chọn thư mục làm việc chính khác?';
		|ru = 'Длина пути к файлу превышает %1 символов:
		|%2
		|
		|Выбрать другой основной рабочий каталог?';
		|en = 'The file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?'; fa = 'The file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?';
		|it = 'La lunghezza del percorso al file supera i %1 simboli.
		|%2
		|
		|Selezionare un altra directory di lavoro principale?';
		|pl = 'Długość ścieżki do pliku przekracza %1 znaków:
		|%2
		|
		|Wybrać inny główny katalog roboczy?';
		|tr = 'Dosya yolu uzunluğu %1karakteri aşıyor: 
		|%2
		|
		|Farklı bir ana çalışma dizini seçilsin mi?'"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	Handler = New CallbackDescription("GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheStartToSelectDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	Title = NStr("vi = 'Hãy chọn thư mục làm việc chính khác';
				|ru = 'Выберите другой основной рабочий каталог';
				|en = 'Select another main working directory'; fa = 'Select another main working directory';
				|it = 'Selezionate un''altra directory di lavoro principale';
				|pl = 'Wybierz inny główny katalog roboczy';
				|tr = 'Başka ana çalışma dizini seçin'");
	DirectorySelected1 = ChoosePathToWorkingDirectory(ExecutionParameters.DirectoryName, Title, False);
	If Not DirectorySelected1 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.DirectoryName 
		+ FilesOperationsInternalClientServer.UniqueNameByWay(
		ExecutionParameters.DirectoryName,
		ExecutionParameters.FileName);
	
	// fits into 260 characters
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New CallbackDescription("GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.DirectoryName);
	Else
		GetFromServerAndRegisterInLocalFilesCacheOfferSelectDirectory(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		SetUserWorkingDirectory(ExecutionParameters.DirectoryName);
		GetFromServerAndRegisterInLocalFilesCacheContinued(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure GetFromServerAndRegisterInLocalFilesCacheContinued(ExecutionParameters)
	
#If Not WebClient Then
	If ExecutionParameters.InOwnerWorkingDirectory = False Then
		ClearSpaceInWorkingDirectory(Undefined, ExecutionParameters.FileData);
	EndIf;
#EndIf
	
	// Write File to directory
	ExecutionParameters.FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription,
		ExecutionParameters.FileData.Extension);
	CommonInternalClient.ShortenFileName(ExecutionParameters.FileName);
	
	FileOnHardDriveByName = New File(ExecutionParameters.FullFileName);
	NameAndExtensionInPath = FileOnHardDriveByName.Name;
	Position = StrFind(ExecutionParameters.FullFileName, NameAndExtensionInPath);
	PathToFile = "";
	If Position <> 0 Then
		PathToFile = Left(ExecutionParameters.FullFileName, Position - 1); // -"-1" is for reducing the length by one slash sign.
	EndIf;
	
	PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
	ExecutionParameters.Insert("ParameterFilePath", PathToFile);
	
	ExecutionParameters.FullFileName = PathToFile + ExecutionParameters.FileName; // Extension could have been replaced.
	
	If ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
		
		CopyFile(ExecutionParameters.FileData.UpdatePathFromFileOnHardDrive, ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
		
		Return;
	EndIf;
	
	If ExecutionParameters.FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			Return;
		EndIf;
		
		FillTemporaryFormID(ExecutionParameters.FormIdentifier, ExecutionParameters);
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			ExecutionParameters.FileData.Version,, ExecutionParameters.FormIdentifier);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
															|ru = 'Расшифровка файла';
															|en = 'Decrypt file'; fa = 'Decrypt file';
															|it = 'Decodifica del file';
															|pl = 'Deszyfrowanie plików';
															|tr = 'Dosya detaylandırması'"));
		DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
													|ru = 'Файл';
													|en = 'File'; fa = 'فایل';
													|it = 'File';
													|pl = 'File';
													|tr = 'Dosya'"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New CallbackDescription(
			"GetFromServerAndRegisterInLocalFilesCacheAfterDecryption",
			ThisObject,
			ExecutionParameters);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		
		Return;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If Not DataDetails.Success Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			ExecutionParameters.FormIdentifier);
		FileData = ExecutionParameters.HandlerResults_1.AdditionalParameters.FileData;
		FileData.Encoding = FilesOperationsInternalClientServer.DetermineBinaryDataEncoding(DataDetails.DecryptedData, FileData.Extension);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheFileSending(ExecutionParameters, FileAddress = Undefined)
	
	If FileAddress = Undefined Then
		If ExecutionParameters.FileData.Version <> ExecutionParameters.FileData.CurrentVersion Then
			FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
				ExecutionParameters.FileData.Version, ExecutionParameters.FormIdentifier);
		Else
			FileAddress = ExecutionParameters.FileData.RefToBinaryFileData;
		EndIf;
	EndIf;
	
	TransmittedFiles = New Array;
	LongDesc = New TransferableFileDescription(ExecutionParameters.FullFileName, FileAddress);
	TransmittedFiles.Add(LongDesc);
	
#If WebClient Then
	If ExecutionParameters.AdditionalParameters <> Undefined 
		And ExecutionParameters.AdditionalParameters.Property("OpenFile") Then
			
		OperationArray = New Array;
		
		CallDetails = New Array;
		CallDetails.Add("GetFiles");
		CallDetails.Add(TransmittedFiles);
		CallDetails.Add(Undefined);  // Obsolete.
		CallDetails.Add(ExecutionParameters.ParameterFilePath);
		CallDetails.Add(False);          // Interactively = False.
		OperationArray.Add(CallDetails);
		
		CallDetails = New Array;
		CallDetails.Add("RunApp");
		CallDetails.Add(ExecutionParameters.FullFileName);
		OperationArray.Add(CallDetails);
		
		If Not RequestUserPermission(OperationArray) Then
			// User did not give a permission.
			ClearTemporaryFormID(ExecutionParameters);
			ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
			Return;
		EndIf;
		
	EndIf;
#EndIf
	
	ObtainedFiles = New Array;
	If Not GetFiles(TransmittedFiles, ObtainedFiles , , False) Then
		ClearTemporaryFormID(ExecutionParameters);
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// For the option of storing files in volumes, the file is deleted from the temporary storage after being received.
	If IsTempStorageURL(FileAddress) Then
		DeleteFromTempStorage(FileAddress);
	EndIf;
	
	// Set the file change time equal to the change time of the current version.
	SetModificationUniversalTime(ExecutionParameters.FullFileName, 
		ExecutionParameters.FileData.UniversalModificationDate);
	
	GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetFromServerAndRegisterInLocalFilesCacheCompletion(ExecutionParameters)
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	
	// Because the size on the computer can differ from the size in the infobase (when adding in the web client).
	FileSize = FileOnHardDrive.Size();
	
	FileOnHardDrive.SetReadOnly(ExecutionParameters.ForReading);
	
	ExecutionParameters.DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(ExecutionParameters.FileData.Version,
		ExecutionParameters.FullFileName, ExecutionParameters.DirectoryName, ExecutionParameters.ForReading, FileSize,
		ExecutionParameters.InOwnerWorkingDirectory);
	
	If ExecutionParameters.FileData.Size <> FileSize Then
		
		If Not ExecutionParameters.FileData.Property("UpdatePathFromFileOnHardDrive") Then
			
			FilesOperationsInternalServerCall.UpdateSizeOfFileAndVersion(ExecutionParameters.FileData, 
				FileSize, ExecutionParameters.FormIdentifier);
			
			NotifyChanged(ExecutionParameters.FileData.Ref);
			NotifyChanged(ExecutionParameters.FileData.Version);
			
			NotificationParameters = FileWriteNotificationParameters();
			NotificationParameters.File = ExecutionParameters.FileData.Ref;
			NotificationParameters.Event = "FileDataChanged";
			NotificationParameters.IsNew = False;
			
			Notify("Write_File", NotificationParameters, ExecutionParameters.FileData.Ref);
		EndIf;
	EndIf;
	
	ClearTemporaryFormID(ExecutionParameters);
	
	ExecutionParameters.FileReceived = True;
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

#EndRegion

#Region GetFileFromStorageToWorkingDir

// Receives File from the storage to folder working directory
// and returns a path to this file.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData        - See FilesOperationsInternalServerCall.FileData
//  FullFileName     - String - a return value.
//  ForReading           - Boolean - False for reading, True for editing.
//  FormIdentifier - UUID
//
Procedure GetVersionFileToFolderWorkingDirectory(HandlerResults_1, FileData, FullFileName,
	ForReading, FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FileReceived", False);
	
	// Generating a file name with an extension.
	FileName = FileData.FullVersionDescription;
	If Not IsBlankString(FileData.Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(FileName, FileData.Extension);
	EndIf;
	
	CommonInternalClient.ShortenFileName(FileName);
	
	If ExecutionParameters.FullFileName = "" Then
		ExecutionParameters.FullFileName = FileData.OwnerWorkingDirectory + FileName;
		Handler = New CallbackDescription("GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength", 
			ThisObject, ExecutionParameters);
		CheckFullPathMaxLengthInWorkingDirectory(Handler, FileData, ExecutionParameters.FullFileName, FileName);
	Else
		GetVersionFileToFolderWorkingDirectoryContinued(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToFolderWorkingDirectoryAfterCheckPathLength(Result, ExecutionParameters) Export
	
	If Result = False Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	Else
		GetVersionFileToFolderWorkingDirectoryContinued(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure GetVersionFileToFolderWorkingDirectoryContinued(ExecutionParameters)
	
	// Search for file registration in working directory (full name with the path).
	FileInfo1 = FilesOperationsInternalServerCall.FilesInfoInWorkingDir(
		CommonClientServer.ValueInArray(ExecutionParameters.FullFileName));
	FileInfo1 = FileInfo1[ExecutionParameters.FullFileName];
	ExecutionParameters.Insert("FileIsInRegister", FileInfo1.FileIsInRegister);
	Version            = FileInfo1.File;
	Owner          = FileInfo1.Owner;
	InRegisterForReading = FileInfo1.InRegisterForReading;
	InRegisterFolder    = FileInfo1.InRegisterFolder;
	
	FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	FileOnHardDriveExists = FileOnHardDrive.Exists();
	
	// Deleting the file registration if it does not exist.
	If ExecutionParameters.FileIsInRegister And Not FileOnHardDriveExists Then
		FilesOperationsInternalServerCall.DeleteFromRegister(Version);
		ExecutionParameters.FileIsInRegister = False;
	EndIf;
	
	If Not ExecutionParameters.FileIsInRegister And Not FileOnHardDriveExists Then
		GetFromServerAndRegisterInFolderWorkingDirectory(
			ExecutionParameters.HandlerResults_1,
			ExecutionParameters.FileData,
			ExecutionParameters.FullFileName,
			ExecutionParameters.FileData.UniversalModificationDate,
			ExecutionParameters.ForReading,
			ExecutionParameters.FormIdentifier,
			ExecutionParameters.AdditionalParameters);
		Return;
	EndIf;
	
	// It is found that the file exists in the working directory.
	
	If ExecutionParameters.FileIsInRegister And Version <> ExecutionParameters.FileData.CurrentVersion Then
		
		If Owner = ExecutionParameters.FileData.Ref And InRegisterForReading = True Then
			// If the file versions have the same owner, and
			// the file in the working directory is registered for reading,
			// replace it with the file from the storage.
			GetFromServerAndRegisterInFolderWorkingDirectory(
				ExecutionParameters.HandlerResults_1,
				ExecutionParameters.FileData,
				ExecutionParameters.FullFileName,
				ExecutionParameters.FileData.UniversalModificationDate,
				ExecutionParameters.ForReading,
				ExecutionParameters.FormIdentifier,
				ExecutionParameters.AdditionalParameters);
			Return;
		EndIf;
		
		If ExecutionParameters.FileData.Owner = InRegisterFolder Then // The same folder.
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thư mục làm việc trên máy tính đã có tệp
				           |""%1"",
				           |tương ứng với một tệp khác trong ứng dụng.
				           |
				           |Nên đổi tên một trong các tệp trong ứng dụng.';
				           |ru = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в приложении.
				           |
				           |Рекомендуется переименовать один из файлов в приложении.';
				           |en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you rename one of the files in the application.'; fa = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you rename one of the files in the application.';
				           |it = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в приложении.
				           |
				           |Рекомендуется переименовать один из файлов в приложении.';
				           |pl = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you rename one of the files in the application.';
				           |tr = 'Bilgisayarın çalışma dizininde uygulamadaki başka bir dosya ile 
				           |eşleşen 
				           |""%1""dosyası mevcut.
				           |
				           |Uygulamadaki dosyalardan birini yeniden adlandırmanız önerilir.'"),
				ExecutionParameters.FullFileName);
		Else
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong thư mục làm việc trên máy tính đã có tệp
				           |""%1"",
				           |tương ứng với tệp khác trong ứng dụng.
				           |
				           |Nên chỉ ra thư mục làm việc khác cho một trong các thư mục của ứng dụng.
				           |(Hai thư mục không được có cùng một thư mục làm việc).';
				           |ru = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в приложении.
				           |
				           |Рекомендуется указать другой рабочий каталог для одной из папок в приложении.
				           |(У двух папок не должно быть одинакового рабочего каталога).';
				           |en = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you select another working directory for one of the application folders.
				           |(Two folders cannot have the same working directory.)'; fa = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you select another working directory for one of the application folders.
				           |(Two folders cannot have the same working directory.)';
				           |it = 'В рабочем каталоге на компьютере уже есть файл
				           |""%1"",
				           |соответствующий другому файлу в приложении.
				           |
				           |Рекомендуется указать другой рабочий каталог для одной из папок в приложении.
				           |(У двух папок не должно быть одинакового рабочего каталога).';
				           |pl = 'The working directory contains file
				           |""%1""
				           |that matches another file stored in the application.
				           |
				           |It is recommended that you select another working directory for one of the application folders.
				           |(Two folders cannot have the same working directory.)';
				           |tr = 'Bilgisayarın çalışma dizininde uygulamadaki başka bir dosya ile 
				           |eşleşen 
				           |""%1""dosyası mevcut.
				           |
				           |Uygulamadaki klasörlerden biri için başka çalışma dizinin belirtilmesi önerilir.
				           | (İki klasörde aynı çalışma dizinine sahip olmamalıdır).'"),
				ExecutionParameters.FullFileName);
		EndIf;
		
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	// The working directory contains "File".
	// It's either unregistered or registered and the version matches.
	
	// Checking the modification date and deciding what to do next.
	Handler = New CallbackDescription("GetVersionsFileToFolderWorkingDirectoryAfterActionChoice", ThisObject, ExecutionParameters);
	
	ActionOnOpenFileInWorkingDirectory(
		Handler,
		ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * AdditionalParameters - See GetVersionFileToFolderWorkingDirectory.AdditionalParameters
//
Procedure GetVersionsFileToFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// In the folder working directory, the confirmation setting during deletion is not used.
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading
			Or Not ExecutionParameters.FileIsInRegister Then
			
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			RegegisterInWorkingDirectory(ExecutionParameters.FileData.Version, 
				ExecutionParameters.FullFileName, ExecutionParameters.ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region GetFileOnServerAndRegisterInWorkingDir

// Receive the File from server and register it in the working directory.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FullFileNameInWorkingDirectory - String - a full file name is returned here.
//  FileDateInDatabase - Date - file date in base.
//  ForReading - Boolean - a file is placed for reading.
//  FormIdentifier - UUID - a form ID.
//  AdditionalParameters - Arbitrary - additional parameters of processing areas.
//
Procedure GetFromServerAndRegisterInFolderWorkingDirectory(HandlerResults_1, FileData, 
	FullFileNameInWorkingDirectory, FileDateInDatabase, ForReading, FormIdentifier, AdditionalParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileNameInWorkingDirectory", FullFileNameInWorkingDirectory);
	ExecutionParameters.Insert("FileDateInDatabase", FileDateInDatabase);
	ExecutionParameters.Insert("ForReading", ForReading);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	ExecutionParameters.Insert("AdditionalParameters", AdditionalParameters);
	
	ExecutionParameters.Insert("FullFileName", "");
	ExecutionParameters.Insert("FileReceived", False);
	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;
	
	FileInWorkingDirectory = FileInLocalFilesCache(FileData,
		FileData.Version, ExecutionParameters.FullFileName,
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		ExecutionParameters.Insert("FullFileName", ExecutionParameters.FullFileNameInWorkingDirectory);
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		Return;
	EndIf;

	// Receiving a file path in the working directory and checking it for uniqueness.
	If ExecutionParameters.FullFileName = "" Then
		CommonClient.MessageToUser(
			NStr("vi = 'Không thể nhận tệp từ ứng dụng vào thư mục làm việc trên máy tính.';
				|ru = 'Не удалось получить файл из приложения в рабочий каталог на компьютере.';
				|en = 'Cannot get the file from the application to the working directory.'; fa = 'Cannot get the file from the application to the working directory.';
				|it = 'Не удалось получить файл из приложения в рабочий каталог на компьютере.';
				|pl = 'Cannot get the file from the application to the working directory.';
				|tr = 'Bilgisayarda çalışma dizinindeki uygulamadan dosya alınamıyor.'"));
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// "File" is found in the working directory.
	// Check the change date and decide what to do next.
	Handler = New CallbackDescription("GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice", 
		ThisObject, ExecutionParameters);
	ActionOnOpenFileInWorkingDirectory(Handler, ExecutionParameters.FullFileName,
		ExecutionParameters.FileData);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * AdditionalParameters - See GetFromServerAndRegisterInFolderWorkingDirectory.AdditionalParameters
//
Procedure GetFromServerAndRegisterInFolderWorkingDirectoryAfterActionChoice(Result, ExecutionParameters) Export
	
	If Result = "GetFromStorageAndOpen" Then
		
		// In the folder working directory, the confirmation setting during deletion is not used.
		DeleteFileWithoutConfirmation(ExecutionParameters.FullFileName);		
		GetFromServerAndRegisterInLocalFilesCache(ExecutionParameters);
		
	ElsIf Result = "OpenExistingFile" Then
		
		If ExecutionParameters.FileData.InWorkingDirectoryForRead <> ExecutionParameters.ForReading Then
			InOwnerWorkingDirectory = ExecutionParameters.FileData.OwnerWorkingDirectory <> "";
			RegegisterInWorkingDirectory(ExecutionParameters.FileData.Version,
				ExecutionParameters.FullFileName, ExecutionParameters.ForReading, InOwnerWorkingDirectory);
		EndIf;
		
		ExecutionParameters.FileReceived = True;
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		
	Else // Result = "Cancel".
		ExecutionParameters.FullFileName = "";
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region CheckWorkingDirMaxLengthWithFilesReplaceAndMove

// Checks the max length and changes and moves files if necessary.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FullFileName - String - a full file name.
//  NormalFileName - String - File name without its path.
//
Procedure CheckFullPathMaxLengthInWorkingDirectory(HandlerResults_1, FileData, 
	FullFileName, NormalFileName)
	
#If WebClient Then
	ReturnResult(HandlerResults_1, True);
	Return;
#EndIf
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FullFileName", FullFileName);
	ExecutionParameters.Insert("NormalFileName", NormalFileName);
	
	ExecutionParameters.Insert("DirectoryNamePreviousValue", FileData.OwnerWorkingDirectory);
	ExecutionParameters.Insert("FullPathMaxSize", 260);
	If Lower(FileData.Extension) = "xls" Or Lower(FileData.Extension) = "xlsx" Then
		// Excel file name length together with the path cannot exceed 218 characters.
		ExecutionParameters.FullPathMaxSize = 218;
	EndIf;
	
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - 5; // "5" is the minimum length of "C:\1\"
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		ReturnResult(HandlerResults_1, True);
		Return;
	EndIf;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Độ dài đường dẫn đầy đủ đến tệp (thư mục làm việc cộng với tên tệp) vượt quá %1 ký tự
		           |""%2"".';
		           |ru = 'Длина полного пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
		           |""%2"".';
		           |en = 'The file path (working directory + file name) is longer than %1 characters:
		           |%2'; fa = 'The file path (working directory + file name) is longer than %1 characters:
		           |%2';
		           |it = 'La lunghezza del percorso completo al file (directory di lavoro più il nome del file) supera i %1 caratteri
		           |""%2"".';
		           |pl = 'Długość pełnej ścieżki do pliku (katalog roboczy plus nazwa pliku) przekracza %1 znaków
		           |""%2"".';
		           |tr = 'Dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1karakterleri aşıyor
		           |""%2"".'"),
		ExecutionParameters.FullPathMaxSize,
		ExecutionParameters.FullFileName);
	
	UserDirectoryPath = UserDataDir();
	MaxFileNameLength = ExecutionParameters.FullPathMaxSize - StrLen(UserDirectoryPath);
	
	// If the file name + 5 exceeds 260 characters, output the message "Replace the file name with a shorter one."
	If StrLen(ExecutionParameters.NormalFileName) > MaxFileNameLength Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("vi = 'Hãy thay đổi tên tệp cho ngắn gọn hơn.';
					|ru = 'Измените имя файла на более короткое.';
					|en = 'Please choose a shorter file name.'; fa = 'Please choose a shorter file name.';
					|it = 'Modificate il nome del file in uno più corto.';
					|pl = 'Zmień nazwę pliku na krótszą.';
					|tr = 'Dosya adını kısaltın.'");
		ReturnResultAfterShowWarning(HandlerResults_1, MessageText, False);
		Return;
	EndIf;
	
	// If the directory structure (path to the current directory's working directory) exceeds 260-5 (1.txt), display the user message:
	// "Rename the directories or move the directory to a different location."
	If StrLen(FileData.OwnerWorkingDirectory) > ExecutionParameters.FullPathMaxSize - 5 Then
		MessageText = MessageText + Chars.CR + Chars.CR
			+ NStr("vi = 'Hãy thay đổi tên thư mục hoặc chuyển thư mục hiện tại sang thư mục khác.';
					|ru = 'Измените имена папок или перенесите текущую папку в другую папку.';
					|en = 'Please rename the folders or move the current folder to another one.'; fa = 'Please rename the folders or move the current folder to another one.';
					|it = 'Modificate i nomi delle cartelle oppure spostate la cartella corrente in un''altra cartella.';
					|pl = 'Zmień nazwy folderów lub przenieś bieżący folder do innego folderu.';
					|tr = 'Klasör adlarını değiştirin veya bu klasörü başka bir klasöre taşıyın.'");
		ReturnResultAfterShowWarning(HandlerResults_1, MessageText, False);
		Return;
	EndIf;
	
	CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters)
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Độ dài đường dẫn tệp đầy đủ (thư mục làm việc cộng với tên tệp) vượt quá  %1 ký tự
		|""%2"".
		|
		|Chọn một thư mục làm việc chính khác?
		|(Nội dung của thư mục làm việc sẽ chuyển đến thư mục đã chọn).';
		|ru = 'Длина полного пути к файлу (рабочий каталог плюс имя файла) превышает %1 символов
		|""%2"".
		|
		|Выбрать другой основной рабочий каталог?
		|(Содержимое рабочего каталога будет перенесено в выбранный каталог).';
		|en = 'The full file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?
		|(The working directory content will be moved to the selected directory.)'; fa = 'The full file path (working directory + file name) is longer than %1 characters:
		|%2
		|
		|Do you want to select a different main working directory?
		|(The working directory content will be moved to the selected directory.)';
		|it = 'La lunghezza del percorso completo al file (directory di lavoro più il nome del file) supera i %1 caratteri
		|""%2"".
		|
		|Scegliere un altra directory di lavoro principale?
		|(Il contenuto della directory di lavoro verrà spostata nella directory scelta).';
		|pl = 'Długość pełnej ścieżki do pliku (katalog roboczy plus nazwa pliku) przekracza%1 znaków
		|""%2"".
		|
		|Wybrać inny główny katalog roboczy?
		|(Zawartość katalogu roboczego zostanie przeniesiona do wybranego katalogu).';
		|tr = 'Tam dosya yolu uzunluğu (çalışma dizini artı dosya adı) %1""
		|"" %2karakterlerini aşıyor. 
		|
		|Başka bir ana çalışma dizini seçilsin mi? 
		|(Çalışma dizininin içeriği seçilen dizine aktarılır).'"),
		ExecutionParameters.FullPathMaxSize, ExecutionParameters.FullFileName);
	Handler = New CallbackDescription("CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory", ThisObject, ExecutionParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectoryStartChooseDirectory(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	// Selecting a new path to a working directory.
	Title = NStr("vi = 'Hãy chọn thư mục làm việc khác';
				|ru = 'Выберите другой рабочий каталог';
				|en = 'Select another working directory'; fa = 'Select another working directory';
				|it = 'Scegliete un''altra directory di lavoro';
				|pl = 'Wybierz inny katalog roboczy';
				|tr = 'Başka bir çalışma dizini seç'");
	DirectorySelected1 = ChoosePathToWorkingDirectory(ExecutionParameters.FileData.OwnerWorkingDirectory, Title, True);
	If Not DirectorySelected1 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.FullFileName = ExecutionParameters.FileData.OwnerWorkingDirectory + ExecutionParameters.NormalFileName;
	
	// fits into 260 characters
	If StrLen(ExecutionParameters.FullFileName) <= ExecutionParameters.FullPathMaxSize Then
		Handler = New CallbackDescription("CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent", ThisObject, ExecutionParameters);
		MoveWorkingDirectoryContent(Handler, ExecutionParameters.DirectoryNamePreviousValue, ExecutionParameters.FileData.OwnerWorkingDirectory);
	Else
		CheckFullPathMaxLengthInWorkingDirectorySuggestChooseDirectory(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFullPathMaxLengthInWorkingDirectoryAfterMoveWorkingDirectoryContent(ContentMoved, ExecutionParameters) Export
	
	If ContentMoved Then
		// The information register "FilesInWorkingDirectory": it has the full file path.
		// Change it by replacing the common part with an SQL request
		// for the current user.
		FilesOperationsInternalServerCall.SaveFolderWorkingDirectoryAndReplacePathsInRegister(
			ExecutionParameters.FileData.Owner,
			ExecutionParameters.FileData.OwnerWorkingDirectory,
			ExecutionParameters.DirectoryNamePreviousValue);
	EndIf;
	ReturnResult(ExecutionParameters.HandlerResults_1, ContentMoved);
	
EndProcedure

#EndRegion

#Region CopyContentBetweenDirectories

// Copies all files from the specified directory to another one.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   SourceDirectory  - String - the directory previous name.
//   RecipientDirectory  - String - new name of the directory.
//
Procedure CopyDirectoryContent1(HandlerResults_1, Val SourceDirectory, Val RecipientDirectory)
	
	Result = New Structure;
	Result.Insert("ErrorOccurred",           False);
	Result.Insert("ErrorFullFileName",   "");
	Result.Insert("ErrorInfo",       "");
	Result.Insert("CopiedFilesAndFolders", New Array);
	Result.Insert("OriginalFilesAndFolders",  New Array);
	
	CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory);
	
	If Result.ErrorOccurred Then
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể sao chép tệp
			           |""%1"".
			           |Có thể là tệp đã bị chiếm bởi ứng dụng khác.
			           |
			           |Thử lại giao dịch?';
			           |ru = 'Не удалось скопировать файл
			           |""%1"".
			           |Возможно он занят другим приложением.
			           |
			           |Повторить операцию?';
			           |en = 'Cannot copy file
			           |""%1"".
			           |Probably it is locked by another application.
			           |
			           |Do you want to retry?'; fa = 'Cannot copy file
			           |""%1"".
			           |Probably it is locked by another application.
			           |
			           |Do you want to retry?';
			           |it = 'Non è stato possibile copiare il file
			           |""%1"".
			           |È possibile che sia occupato da un''altra applicazione.
			           |
			           |Ripetere l''operazione?';
			           |pl = 'Nie udało się skopiować pliku
			           |""%1"".
			           |Być może jest on zajęty przez inną aplikację.
			           |
			           |Powtórzyć operację?';
			           |tr = '""
			           |"" %1Dosyası kopyalanamadı. 
			           |Başka bir uygulama tarafından kullanılıyor olabilir. 
			           |
			           |İşlemi tekrar yapmak istiyor musunuz?'"),
			Result.ErrorFullFileName);
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
		ExecutionParameters.Insert("SourceDirectory", SourceDirectory);
		ExecutionParameters.Insert("RecipientDirectory", RecipientDirectory);
		ExecutionParameters.Insert("Result", Result);
		
		Handler = New CallbackDescription("CopyDirectoryContentAfterRespondQuestion", 
			ThisObject, ExecutionParameters);
		
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	Else
		ReturnResult(HandlerResults_1, Result);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CopyDirectoryContentAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.No Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters.Result);
	Else
		CopyDirectoryContent1(
			ExecutionParameters.HandlerResults_1,
			ExecutionParameters.SourceDirectory,
			ExecutionParameters.RecipientDirectory);
	EndIf;
	
EndProcedure

// Copies all files from the specified directory to another one.
//
// Parameters:
//   Result - Structure - Indicates copying result. See CopyDirectoryContent1
//                            (return value).
//   SourceDirectory  - String - the directory previous name.
//   RecipientDirectory  - String - new name of the directory.
//
Procedure CopyDirectoryContent(Result, SourceDirectory, RecipientDirectory)
	
	RecipientDirectory = CommonClientServer.AddLastPathSeparator(RecipientDirectory);
	SourceDirectory = CommonClientServer.AddLastPathSeparator(SourceDirectory);
	
	CreateDirectory(RecipientDirectory);
	
	Result.CopiedFilesAndFolders.Add(RecipientDirectory);
	Result.OriginalFilesAndFolders.Add(SourceDirectory);
	
	SourceFiles1 = FindFiles(SourceDirectory, "*");
	
	For Each SourceFile2 In SourceFiles1 Do
		
		SourceFullFileName = SourceFile2.FullName;
		SourceFileName2       = SourceFile2.Name;
		FullRecipientFileName = RecipientDirectory + SourceFileName2;
		
		If SourceFile2.IsDirectory() Then
			
			CopyDirectoryContent(Result, SourceFullFileName, FullRecipientFileName);
			If Result.ErrorOccurred Then
				Return;
			EndIf;
			
		Else
			
			Result.OriginalFilesAndFolders.Add(SourceFullFileName);
			
			RecipientFile = New File(FullRecipientFileName);
			If RecipientFile.Exists() Then
				// This is required for backward copying. In this case files can exist already.
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			Else
				Try
					CopyFile(SourceFullFileName, FullRecipientFileName);
				Except
					Result.ErrorOccurred         = True;
					Result.ErrorInfo     = ErrorInfo();
					Result.ErrorFullFileName = SourceFullFileName;
					Return;
				EndTry;
				Result.CopiedFilesAndFolders.Add(FullRecipientFileName);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region MoveWorkingDirContentToNewDir

// Transfers all files from the working directory to another directory (including those taken for editing).
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   SourceDirectory - String - the directory previous name.
//   RecipientDirectory - String - new name of the directory.
//
Procedure MoveWorkingDirectoryContent(HandlerResults_1, SourceDirectory, RecipientDirectory) Export
	
	// The new path is a subset of the old one. This is prohibited, because. can lead to looping.
	If StrFind(Lower(RecipientDirectory), Lower(SourceDirectory)) <> 0 Then
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thư mục làm việc đã chọn
			           |""%1""
			           |nằm trong thư mục làm việc cũ
			           |""%2"".';
			           |ru = 'Выбранный рабочий каталог
			           |""%1""
			           |входит в старый рабочий каталог
			           |""%2"".';
			           |en = 'The destination working directory
			           |""%1""
			           |is included in the source working directory
			           |""%2"".'; fa = 'The destination working directory
			           |""%1""
			           |is included in the source working directory
			           |""%2"".';
			           |it = 'La directory di lavoro scelta
			           |""%1""
			           |rientra nella vecchia directory di lavoro
			           |""%2"".';
			           |pl = 'Wybrany katalog roboczy
			           |""%1""
			           |wchodzi do starego katalogu roboczego
			           |""%2"".';
			           |tr = 'Seçilmiş çalışma dizini 
			           |""%1""
			           | eski çalışma dizini kapsamındadır 
			           |""%2"".'"),
			RecipientDirectory,
			SourceDirectory);
		ReturnResultAfterShowWarning(HandlerResults_1, WarningText, False);
		Return;
	EndIf;
	
	// Copying files from the old directory to a new one.
	HandlerParameters = New Structure;
	HandlerParameters.Insert("HandlerResults_1", HandlerResults_1);
	HandlerParameters.Insert("SourceDirectory", SourceDirectory);
	HandlerParameters.Insert("RecipientDirectory", RecipientDirectory);
	Handler = New CallbackDescription("MoveWorkingDirectoryContentAfterCopyToNewDirectory", ThisObject, HandlerParameters);
	
	CopyDirectoryContent1(Handler, SourceDirectory, RecipientDirectory);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterCopyToNewDirectory(Result, ExecutionParameters) Export
	
	If Result.ErrorOccurred Then
		// A copying error occurred and then user canceled the operation.
		
		Handler = New CallbackDescription(
			"MoveWorkingDirectoryContentAfterCancelAndClearRecipient",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.CopiedFilesAndFolders); // Clean up the recipient folder.
	Else
		// The copy was successful. Clean up the old directory.
		Handler = New CallbackDescription(
			"MoveWorkingDirectoryContentAfterSuccessAndClearSource",
			ThisObject,
			ExecutionParameters);
		
		DeleteDirectoryContent(Handler, Result.OriginalFilesAndFolders);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterCancelAndClearRecipient(RecipientDirectoryCleareed, ExecutionParameters) Export
	
	ReturnResult(ExecutionParameters.HandlerResults_1, False);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterSuccessAndClearSource(SourceDirectoryCleared, ExecutionParameters) Export
	
	If SourceDirectoryCleared Then
		// The old directory has been cleaned up. All steps succeeded.
		ReturnResult(ExecutionParameters.HandlerResults_1, True);
	Else
		// The old directory wasn't cleaned up. Roll back the entire operation.
		Handler = New CallbackDescription("MoveWorkingDirectoryContentAfterSuccessAndCancelClearing", ThisObject, ExecutionParameters);
		CopyDirectoryContent1(Handler, ExecutionParameters.RecipientDirectory, ExecutionParameters.SourceDirectory);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure MoveWorkingDirectoryContentAfterSuccessAndCancelClearing(Result, ExecutionParameters) Export
	
	// Roll back the operation.
	If Result.ErrorOccurred Then
		// Warning that an error occurred during the operation rollback.
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể sao chép lại nội dung thư mục
			           |""%1""
			           |vào thư mục
			           |""%2"".';
			           |ru = 'Не удалось скопировать обратно содержимое каталога
			           |""%1""
			           |в каталог
			           |""%2"".';
			           |en = 'Cannot copy files from directory
			           |""%1""
			           |back to directory
			           |""%2"".'; fa = 'Cannot copy files from directory
			           |""%1""
			           |back to directory
			           |""%2"".';
			           |it = 'Non è stato possibile copiare indietro il contenuto del catalogo
			           |""%1""
			           |nel catalogo
			           |""%2"".';
			           |pl = 'Nie udało się skopiować z powrotem zawartość katalogu
			           |""%1""
			           |do katalogu
			           |""%2"".';
			           |tr = '
			           |""%1""
			           | dizinin içeriği 
			           |""%2"" dizine geri kopyalanamadı.'"),
			ExecutionParameters.RecipientDirectory,
			ExecutionParameters.SourceDirectory);
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, WarningText, False);
	Else
		// The operation was rolled back successfully.
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region TransferredFileAndFolderPathsArrayDeletion

// Deletes all files and folders from the passed array.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   CopiedFilesAndFolders - Array of String - paths of files and folders.
//
Procedure DeleteDirectoryContent(HandlerResults_1, CopiedFilesAndFolders)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("CopiedFilesAndFolders", CopiedFilesAndFolders);
	DeleteDirectoryContentStart(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure DeleteDirectoryContentStart(ExecutionParameters)
	
	UpperBound = ExecutionParameters.CopiedFilesAndFolders.Count() - 1;
	For IndexOf = 0 To UpperBound Do
		Path = ExecutionParameters.CopiedFilesAndFolders[UpperBound - IndexOf];
		File = New File(Path);
		If Not File.Exists() Then
			Continue; // For example, Word temporary file ~aaa.doc could be deleted when closing Word.
		EndIf;
		
		Try
			If File.IsFile() And File.GetReadOnly() Then
				File.SetReadOnly(False);
			EndIf;
			DeleteFiles(Path);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa tệp trong thư mục làm việc:
					|""%1"". 
					|Có thể là tệp đang bị chiếm bởi người sử dụng khác.
					|
					|%2';
					|ru = 'Не удалось удалить файл в рабочем каталоге:
					|""%1"". 
					|Возможно он занят другим приложением.
					|
					|%2';
					|en = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2'; fa = 'Cannot delete the file in the working directory:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';
					|it = 'Non è stato possibile eliminare il file nel catalogo di lavoro:
					|""%1"".
					|Forse è impegnato da un''altra applicazione.
					|
					|%2';
					|pl = 'Nie udało się usunąć pliku w katalogu roboczym:
					|""%1"". 
					|Możliwe, że jest on zajęty przez inną aplikację.
					|
					|%2';
					|tr = 'Dosya çalışma dizininden silinemedi:
					|""%1"". 
					|Başka bir uygulama tarafından kullanılıyor olabilir.
					|
					|%2'"),
				Path, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;
	EndDo;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region FilesImportWithSizeCheck

// Import with auxiliary operations (checking the size limit, deleting files, and showing
// errors on import).
//
// Parameters:
//  ExecutionParameters - See FilesImportParameters.
//
Procedure ExecuteFilesImport(Val ExecutionParameters) Export
	
	InternalParameters = CommonClient.CopyRecursive(ExecutionParameters);
	Handler = New CallbackDescription("FilesImportAfterCheckSizes", ThisObject, InternalParameters);
	CheckMaxFilesSize(Handler, InternalParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportAfterCheckSizes(Result, ExecutionParameters) Export
	
	If Result.Success = False Then
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TotalFilesCount", Result.TotalFilesCount);
	If ExecutionParameters.TotalFilesCount = 0 Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, NStr("vi = 'Không có tệp để thêm';
																				|ru = 'Нет файлов для добавления';
																				|en = 'No files to add'; fa = 'No files to add';
																				|it = 'Non ci sono file da aggiungere';
																				|pl = 'Brak plików do dodania';
																				|tr = 'Eklenecek dosya yok'"), Undefined);
		Return;
	EndIf;
	
	ExecutionParameters.Insert("FirstFolderWithSameName", Undefined);
	ExecutionParameters.Insert("FolderForAddingCurrent", Undefined);
	ExecutionParameters.Insert("SelectedFilesInBoundary", ExecutionParameters.SelectedFiles.Count()-1);
	ExecutionParameters.Insert("SelectedFilesIndex", -1);
	ExecutionParameters.Insert("Indicator", 0);
	ExecutionParameters.Insert("Counter", 0);
	ExecutionParameters.Insert("FilesArray", New Array);
	ExecutionParameters.Insert("ArrayOfFilesNamesWithErrors", New Array);
	ExecutionParameters.Insert("AllFilesStructureArray", New Array);
	ExecutionParameters.Insert("AllFoldersArray", New Array);
	ExecutionParameters.Insert("FilesArrayOfThisDirectory", Undefined);
	ExecutionParameters.Insert("FolderName", Undefined);
	ExecutionParameters.Insert("Path", Undefined);
	ExecutionParameters.Insert("FolderAlreadyFound", Undefined);
	
	CompletionHandler = New CallbackDescription("ImportFilesLoopContinueImportAfterRecurringQuestions", ThisObject);
	RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportLoop(ExecutionParameters)
	
	ExecutionParameters.SelectedFilesIndex = ExecutionParameters.SelectedFilesIndex + 1;
	For IndexOf = ExecutionParameters.SelectedFilesIndex To ExecutionParameters.SelectedFilesInBoundary Do
		ExecutionParameters.SelectedFilesIndex = IndexOf;
		FileName = ExecutionParameters.SelectedFiles[IndexOf];
		
		SelectedFile = New File(FileName.Value);
		
		DirectorySelected = False;
		If SelectedFile.Exists() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			ExecutionParameters.Path = FileName.Value;
			ExecutionParameters.FilesArrayOfThisDirectory = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, ExecutionParameters.Path);
			
			ExecutionParameters.FolderName = SelectedFile.Name;
			
			ExecutionParameters.FolderAlreadyFound = False;
			
			If FilesOperationsInternalServerCall.HasFolderWithThisName(
					ExecutionParameters.FolderName,
					ExecutionParameters.FilesGroup,
					ExecutionParameters.FirstFolderWithSameName) Then
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thư mục ""%1"" đã tồn tại.
					           |
					           |Tiếp tục kết nhập thư mục?';
					           |ru = 'Папка ""%1"" уже существует.
					           |
					           |Продолжить импорт папки?';
					           |en = 'Folder ""%1"" already exists.
					           |
					           |Do you want to continue the upload?'; fa = 'Folder ""%1"" already exists.
					           |
					           |Do you want to continue the upload?';
					           |it = 'La cartella ""%1"" esiste già.
					           |
					           |Continuare l''importazione della cartella?';
					           |pl = 'Folder ""%1"" już istnieje.
					           |
					           |Kontynuować import folderu?';
					           |tr = 'Klasör ""%1"" zaten var. 
					           |
					           |Klasör içe aktarılması devam edilsin mi?'"),
					ExecutionParameters.FolderName);
				Handler = New CallbackDescription("FilesImportLoopAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
				ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
				Return;
			EndIf;
			FilesImportLoopContinueImport(ExecutionParameters);
			If ExecutionParameters.AsynchronousDialog.Open = True Then
				Return;
			EndIf;
		Else
			ExecutionParameters.FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If ExecutionParameters.FilesArray.Count() <> 0 Then
		CompletionHandler = New CallbackDescription("ImportFilesAfterLoopAfterRecurringQuestions", ThisObject);
		RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
		ImportFilesRecursively(ExecutionParameters.Owner, ExecutionParameters.FilesArray, ExecutionParameters);
		
		If ExecutionParameters.AsynchronousDialog.Open = True Then
			Return;
		EndIf;
	EndIf;
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportLoopAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		FilesImportLoopContinueImport(ExecutionParameters);
	EndIf;
	
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * AllFoldersArray - Array
//
Procedure FilesImportLoopContinueImport(ExecutionParameters)
	
	If Not ExecutionParameters.FolderAlreadyFound Then
		PathSeparator = GetPathSeparator();
		WorkingDirectory  = ExecutionParameters.Path + ?(Right(ExecutionParameters.Path, 1) = PathSeparator, "", PathSeparator);
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.Owner) Then
			ExecutionParameters.FolderForAddingCurrent = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , , WorkingDirectory);
		Else		
			ExecutionParameters.FolderForAddingCurrent = ExecutionParameters.Owner;
			ExecutionParameters.FilesGroup = FilesOperationsInternalServerCall.CreateFilesFolder(
				ExecutionParameters.FolderName, ExecutionParameters.Owner, , ExecutionParameters.FilesGroup, WorkingDirectory);
		EndIf;	
	EndIf;
	
	// File import.
	ImportFilesRecursively(ExecutionParameters.FolderForAddingCurrent, ExecutionParameters.FilesArrayOfThisDirectory, ExecutionParameters);
	If ExecutionParameters.AsynchronousDialog.Open = True Then
		Return;
	EndIf;
	
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * AllFoldersArray - Array
//
Procedure ImportFilesLoopContinueImportAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	ExecutionParameters.AsynchronousDialog.Open = False;
	ExecutionParameters.AllFoldersArray.Add(ExecutionParameters.Path);
	FilesImportLoop(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ImportFilesAfterLoopAfterRecurringQuestions(Result, ExecutionParameters) Export
	
	FilesImportAfterLoopFollowUp(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FilesImportAfterLoopFollowUp(ExecutionParameters)
	
	If ExecutionParameters.AllFilesStructureArray.Count() > 1 Then
		StateText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã hoàn thành kết nhập tệp. Đã kết nhập: %1 tệp';
				|ru = 'Импорт файлов завершен. Импортировано файлов: %1';
				|en = 'The upload is completed. Files uploaded: %1.'; fa = 'The upload is completed. Files uploaded: %1.';
				|it = 'L''importazione dei file è terminata. File importati: %1';
				|pl = 'Import plików zakończony. Importowano plików: %1';
				|tr = 'Dosyaların içe aktarımı tamamlandı. İçe aktarılan dosya sayısı: %1'"), String(ExecutionParameters.AllFilesStructureArray.Count()) );
		ShowUserNotification(StateText);
	EndIf;
	
	If ExecutionParameters.DeleteFilesAfterImport = True Then
		DeleteFilesAfterAdd(ExecutionParameters.AllFilesStructureArray, ExecutionParameters.AllFoldersArray);
	EndIf;
	
	If ExecutionParameters.AllFilesStructureArray.Count() = 1 Then
		Item0 = ExecutionParameters.AllFilesStructureArray[0];
		Ref = GetURL(Item0.File);
		ShowUserNotification(
			NStr("vi = 'Thay đổi:';
				|ru = 'Изменение:';
				|en = 'Updated:'; fa = 'Updated:';
				|it = 'Modifica:';
				|pl = 'Updated:';
				|tr = 'Değiştir:'"),
			Ref,
			Item0.File,
			PictureLib.DialogInformation);
	EndIf;
	
	// Error message output
	If ExecutionParameters.ArrayOfFilesNamesWithErrors.Count() <> 0 Then
		Parameters = New Structure;
		Parameters.Insert("ArrayOfFilesNamesWithErrors", ExecutionParameters.ArrayOfFilesNamesWithErrors);
		
		OpenForm("DataProcessor.FilesOperations.Form.ReportForm", Parameters);
	EndIf;
	
	If ExecutionParameters.SelectedFiles.Count() <> 1 Then
		ExecutionParameters.FolderForAddingCurrent = Undefined;
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

// Deletes files after import or export.
Procedure DeleteFilesAfterAdd(AllFilesStructureArray, AllFoldersArray)
	
	For Each Item In AllFilesStructureArray Do
		SelectedFile = New File(Item.FileName);
		Try
			SelectedFile.SetReadOnly(False);
			DeleteFiles(SelectedFile.FullName);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa tệp sau khi thêm vào ứng dụng:
					|""%1"". 
					|Có thể là tệp đã bị chiếm bởi ứng dụng khác.
					|
					|%2';
					|ru = 'Не удалось удалить файл после добавления в приложение:
					|""%1"". 
					|Возможно он занят другим приложением.
					|
					|%2';
					|en = 'Cannot delete the file after it was added to the application:
					|""%1"".
					|It might be locked by another application.
					|
					|%2'; fa = 'Cannot delete the file after it was added to the application:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';
					|it = 'Не удалось удалить файл после добавления в приложение:
					|""%1"". 
					|Возможно он занят другим приложением.
					|
					|%2';
					|pl = 'Cannot delete the file after it was added to the application:
					|""%1"".
					|It might be locked by another application.
					|
					|%2';
					|tr = 'Programa eklendikten sonra dosya silinemedi:
					|""%1"". 
					|Başka bir uygulama tarafından kullanılıyor olabilir.
					|
					|%2'"),
				SelectedFile.FullName, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", MessageText,, True);
		EndTry;	
	EndDo;
	
EndProcedure

#EndRegion

#Region SavingFileToComputer

// Save a file to the computer.
// 
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   FileData  - Structure
//   UUID - UUID - a form ID..
//
Procedure SaveAs(HandlerResults_1, FileData, UUID)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	
	If Is1CEnterpriseExtensionAttached() Then
		SaveAsWithExtension(ExecutionParameters);
	Else
		SaveAsWithoutExtension(ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtension(ExecutionParameters)
	
	// Checking whether the file is already in cache, and if it is, show a dialog box with a choice.
	ExecutionParameters.Insert("PathToFileInCache", "");
	If ExecutionParameters.FileData.CurrentUserEditsFile Then
		InWorkingDirectoryForRead = True;
		InOwnerWorkingDirectory = False;
		ExecutionParameters.Insert("FullFileName", "");
		
		FileInWorkingDirectory = FileInLocalFilesCache(ExecutionParameters.FileData, ExecutionParameters.FileData.Version, ExecutionParameters.FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
		If FileInWorkingDirectory Then
			
			FileDateInDatabase = ExecutionParameters.FileData.UniversalModificationDate;
			
			VersionFile = New File(ExecutionParameters.FullFileName);
			FileDateOnHardDrive = VersionFile.GetModificationUniversalTime();
			
			If FileDateOnHardDrive > FileDateInDatabase Then // The working directory has a newer one (changed by a third party user).
				FormOpenParameters = New Structure;
				FormOpenParameters.Insert("File", ExecutionParameters.FullFileName);
				
				Message = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Ngày thay đổi tệp ""%1""
					           |trong thư mục làm việc trên máy tính muộn hơn (mới hơn) so với trong ứng dụng.
					           |Có thể là, đã soạn tệp trên máy tính.';
					           |ru = 'Дата изменения файла ""%1""
					           |в рабочем каталоге на компьютере более поздняя (новее), чем в приложении.
					           |Возможно, файл на компьютере был отредактирован.';
					           |en = 'The local copy of file ""%1""
					           |was modified later than the file in the application.
					           |The local copy might have been edited.'; fa = 'The local copy of file ""%1""
					           |was modified later than the file in the application.
					           |The local copy might have been edited.';
					           |it = 'Дата изменения файла ""%1""
					           |в рабочем каталоге на компьютере более поздняя (новее), чем в приложении.
					           |Возможно, файл на компьютере был отредактирован.';
					           |pl = 'The local copy of file ""%1""
					           |was modified later than the file in the application.
					           |The local copy might have been edited.';
					           |tr = 'Bilgisayardaki çalışma dizinindeki ""%1""
					           | dosyanın değişim tarihi, uygulamadaki tarihten daha geç (yeni)dir. 
					           |Bilgisayardaki dosya düzenlenmiş olabilir.'"),
					String(ExecutionParameters.FileData.Ref));
				
				FormOpenParameters.Insert("Message", Message);
				
				Handler = New CallbackDescription("SaveAsWithExtensionAfterRespondQuestionDateNewer", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.FileCreationModeForSaveAs", FormOpenParameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	SaveAsWithExtensionContinued(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionAfterRespondQuestionDateNewer(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Cancel Or Response = Undefined Then
		ReturnResult(ExecutionParameters.HandlerResults_1, "");
		Return;
	EndIf;
	
	If Response = 1 Then // Based on file on local computer.
		ExecutionParameters.PathToFileInCache = ExecutionParameters.FullFileName;
	EndIf;
	
	SaveAsWithExtensionContinued(ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithExtensionContinued(ExecutionParameters)
	
	ExecutionParameters.Insert("ChoicePath", ExecutionParameters.FileData.FolderForSaveAs);
	If ExecutionParameters.ChoicePath = Undefined Or ExecutionParameters.ChoicePath = "" Then
		ExecutionParameters.ChoicePath = MyDocumentsDirectory();
	EndIf;
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New CallbackDescription("SaveAsWithExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, "");
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted Then
		SaveAsWithExtensionAfterDecryption(-1, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(ExecutionParameters.FileData.Version,, 
		ExecutionParameters.UUID);
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
														|ru = 'Расшифровка файла';
														|en = 'Decrypt file'; fa = 'Decrypt file';
														|it = 'Decodifica del file';
														|pl = 'Deszyfrowanie plików';
														|tr = 'Dosya detaylandırması'"));
	DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'File';
												|pl = 'File';
												|tr = 'Dosya'"));
	DataDetails.Insert("Data",                ReturnStructure.BinaryData);
	DataDetails.Insert("Presentation",         ExecutionParameters.FileData.Ref);
	DataDetails.Insert("Object",                ExecutionParameters.FileData.Ref);
	DataDetails.Insert("EncryptionCertificates", ExecutionParameters.FileData.Ref);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New CallbackDescription("SaveAsWithExtensionAfterDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SaveAsWithExtensionAfterDecryption(DataDetails, ExecutionParameters) Export
	
	If DataDetails <> -1 Then
		If Not DataDetails.Success Then
			ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
			Return;
		EndIf;
	
		If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
			FileAddress = PutToTempStorage(DataDetails.DecryptedData,
				ExecutionParameters.UUID);
		Else
			FileAddress = DataDetails.DecryptedData;
		EndIf;
	Else
		If ExecutionParameters.FileData.Property("RefToBinaryFileData") Then
			FileAddress = ExecutionParameters.FileData.RefToBinaryFileData;
			ExecutionParameters.FileData.Insert("FullVersionDescription", ExecutionParameters.FileData.Description);
		Else
			FileAddress = ExecutionParameters.FileData.CurrentVersionURL;
			If ExecutionParameters.FileData.CurrentVersion <> ExecutionParameters.FileData.Version Then
				FileAddress = FilesOperationsInternalServerCall.GetURLToOpen(
					ExecutionParameters.FileData.Version, ExecutionParameters.UUID);
			EndIf;
		EndIf;
	EndIf;
	
	NameWithExtension = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, ExecutionParameters.FileData.Extension);
	
	Extension = ExecutionParameters.FileData.Extension;
	
	If ExecutionParameters.FileData.Encrypted
	   And Not ExecutionParameters.SaveDecrypted Then
		
		If Not IsBlankString(ExecutionParameters.EncryptedFilesExtension) Then
			NameWithExtension = NameWithExtension + "." + ExecutionParameters.EncryptedFilesExtension;
			Extension = ExecutionParameters.EncryptedFilesExtension;
		EndIf;
	EndIf;
	
	SelectingFile = New FileDialog(FileDialogMode.Save);
	SelectingFile.Multiselect = False;
	SelectingFile.FullFileName = NameWithExtension;
	SelectingFile.DefaultExt = Extension;
	Filter = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tất cả tệp (*.%1)|*.%1';
			|ru = 'Все файлы (*.%1)|*.%1';
			|en = 'All files (*.%1)|*.%1'; fa = 'All files (*.%1)|*.%1';
			|it = 'Tutti file (*.%1)|*.%1';
			|pl = 'Wszystkie pliki (*.%1)|*.%1';
			|tr = 'Tüm dosyalar (*.%1)|*.%1'"), Extension);
	SelectingFile.Filter = Filter;
	SelectingFile.Directory = ExecutionParameters.ChoicePath;
	
	If Not SelectingFile.Choose() Then
		ReturnResult(ExecutionParameters.HandlerResults_1, New Structure);
		Return;
	EndIf;
	
	FullFileName = SelectingFile.FullFileName;
	
	File = New File(FullFileName);
	
	If File.Exists() Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			Try
				File.SetReadOnly(False);
				DeleteFiles(SelectingFile.FullFileName);
			Except
				EventLogClient.AddMessageForEventLog(EventLogEvent(),
					"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			EndTry;	
		EndIf;
	EndIf;
	
	If ExecutionParameters.PathToFileInCache <> "" Then
		If ExecutionParameters.PathToFileInCache <> FullFileName Then
			CopyFile(ExecutionParameters.PathToFileInCache, SelectingFile.FullFileName);
		EndIf;
	Else
		TransmittedFiles = New Array;
		LongDesc = New TransferableFileDescription(FullFileName, FileAddress);
		TransmittedFiles.Add(LongDesc);
		
		PathToFile = File.Path;
		PathToFile = CommonClientServer.AddLastPathSeparator(PathToFile);
		
		If GetFiles(TransmittedFiles,, PathToFile, False) Then
			
			// For the option of storing files in volumes, delete the File from the temporary storage after receiving it.
			If IsTempStorageURL(FileAddress) Then
				DeleteFromTempStorage(FileAddress);
			EndIf;
			
			SetModificationUniversalTime(FullFileName, 
				ExecutionParameters.FileData.UniversalModificationDate);
			
		EndIf;
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã lưu thành công tệp';
								|ru = 'Файл успешно сохранен';
								|en = 'File saved'; fa = 'File saved';
								|it = 'File salvato con successo';
								|pl = 'Plik został zapisany pomyślnie';
								|tr = 'Dosya başarıyla kaydedildi'"), , FullFileName);
	
	ChoicePathPrevious = ExecutionParameters.ChoicePath;
	ExecutionParameters.ChoicePath = File.Path;
	If ChoicePathPrevious <> ExecutionParameters.ChoicePath Then
		CommonClient.CommonSettingsStorageSave("ApplicationSettings", "FolderForSaveAs", ExecutionParameters.ChoicePath);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, New Structure("FullFileName", FullFileName));
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtension(ExecutionParameters)
	
	ExecutionParameters.Insert("SaveDecrypted", False);
	ExecutionParameters.Insert("EncryptedFilesExtension", "");
	
	If ExecutionParameters.FileData.Encrypted Then
		Handler = New CallbackDescription("SaveAsWithoutExtensionAfterSaveModeChoice",
			ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.SelectEncryptedFileSaveMode", , , , , ,
			Handler, FormWindowOpeningMode.LockWholeInterface);
	Else
		SaveAsWithoutExtensionAfterSaveModeChoice(-1, ExecutionParameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtensionAfterSaveModeChoice(Result, ExecutionParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ExecutionParameters.EncryptedFilesExtension = Result.EncryptedFilesExtension;
		
		If Result.SaveDecrypted = 1 Then
			ExecutionParameters.SaveDecrypted = True;
		Else
			ExecutionParameters.SaveDecrypted = False;
		EndIf;
		
	ElsIf Result <> -1 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, "");
		Return;
	EndIf;
	
	FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
	
	Handler = New CallbackDescription("SaveAsWithoutExtensionCompletion", ThisObject, ExecutionParameters);
	OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID,
		False, ExecutionParameters.SaveDecrypted, ExecutionParameters.EncryptedFilesExtension);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure SaveAsWithoutExtensionCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	If Not ExecutionParameters.SaveDecrypted
	   And ExecutionParameters.FileData.Encrypted
	   And ValueIsFilled(ExecutionParameters.EncryptedFilesExtension) Then
		
		Extension = ExecutionParameters.EncryptedFilesExtension;
	Else
		Extension = ExecutionParameters.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.FileData.FullVersionDescription, Extension);
	
	ReturnResult(ExecutionParameters.HandlerResults_1, New Structure("FullFileName", FileName));
	
EndProcedure

// Continuation of the FilesOperationsClient.SaveFileAs procedure.
Procedure SaveFileAsAfterSave(Result, CompletionHandler) Export
	
	If CompletionHandler = Undefined Then
		Return;
	EndIf;
	
	PathToFile = "";
	If TypeOf(Result) = Type("Structure")
		And Result.Property("FullFileName") Then
		
		PathToFile = Result.FullFileName;
	EndIf;
	
	RunCallback(CompletionHandler, PathToFile);
	
EndProcedure

#EndRegion

#Region ShowNotificationBeforeStoreFileIfConfigured

// It will show a reminder if it is set up.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//
Procedure ShowReminderBeforePutFile(HandlerResults_1)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowTooltipsOnEditFiles = True Then
		If Not Is1CEnterpriseExtensionAttached() Then
			ReminderText = 
				NStr("vi = 'Bây giờ, sẽ đề xuất chọn tệp để 
				|đặt tệp đó vào ứng dụng và hoàn tất chỉnh sửa.
				|
				| Hãy tìm tệp cần thiết trong thư mục
				| đã được chỉ định trước đó khi bắt đầu chỉnh sửa.';
				|ru = 'Сейчас будет предложено выбрать файл для того,
				|чтобы поместить его в приложение и закончить редактирование.
				|
				|Найдите нужный файл в том каталоге, который был
				|указан ранее при начале редактирования.';
				|en = 'You will be prompted to select a file
				|to commit.
				|
				|Please select the file from the directory
				|that you specified when you started editing the file.'; fa = 'You will be prompted to select a file
				|to commit.
				|
				|Please select the file from the directory
				|that you specified when you started editing the file.';
				|it = 'Сейчас будет предложено выбрать файл для того,
				|чтобы поместить его в приложение и закончить редактирование.
				|
				|Найдите нужный файл в том каталоге, который был
				|указан ранее при начале редактирования.';
				|pl = 'You will be prompted to select a file
				|to commit.
				|
				|Please select the file from the directory
				|that you specified when you started editing the file.';
				|tr = 'Şimdi uygulamaya koymak
				|ve düzenlemeyi tamamlamak için bir dosya seçin.
				|
				|Düzenlemenin başında belirttiğiniz
				|katalogda gerekli dosyayı bulun.'");
				
			Buttons = New ValueList;
			Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
										|ru = 'Продолжить';
										|en = 'Continue'; fa = 'ادامه';
										|it = 'Continuare';
										|pl = 'Kontynuuj';
										|tr = 'Devam'"));
			Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Anuluj';
										|tr = 'İptal'"));
			ReminderParameters = New Structure;
			ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
			ReminderParameters.Insert("CheckBoxText",
				NStr("vi = 'Không hiển thị thông báo này nữa';
					|ru = 'Больше не показывать это сообщение';
					|en = 'Do not show this message again'; fa = 'Do not show this message again';
					|it = 'Non mostrare più questo messaggio';
					|pl = 'Nie pokazuj więcej tego komunikatu.';
					|tr = 'Bu mesajı tekrar gösterme'"));
			ReminderParameters.Insert("Title",
				NStr("vi = 'Sắp xếp tệp';
					|ru = 'Помещение файла';
					|en = 'Store file'; fa = 'ذخیره فایل';
					|it = 'Allocazione del file';
					|pl = 'Umieszczenie pliku';
					|tr = 'Dosya yerleştirme'"));
			StandardSubsystemsClient.ShowQuestionToUser(
				HandlerResults_1, ReminderText, Buttons, ReminderParameters);
			Return;
		EndIf;
	EndIf;
	ReturnResult(HandlerResults_1, True);
	
EndProcedure

#EndRegion

#Region FileSizeChecks

// Check file size limit.
// Returns False if there are files that exceed the size limit 
// and the user selected "Cancel" in the warning dialog box about the presence of such files.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  CheckParameters - Structure:
//    * SelectedFiles - Array - an array of "File" objects.
//    * Recursively - Boolean - pass subdirectories recursively.
//    * PseudoFileSystem - Map - for a string (directory), returns an array
//                                             of strings (subdirectories and files). 
//
Procedure CheckMaxFilesSize(HandlerResults_1, CheckParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("TotalFilesCount", 0);
	ExecutionParameters.Insert("Success", False);
	
	ArrayOfTooBigFiles = New Array;
	
	Path = "";
	
	FilesArray = New Array;
	
	For Each FileName In CheckParameters.SelectedFiles Do
		
		Path = FileName.Value;
		SelectedFile = New File(Path);
		
		SelectedFile = New File(FileName.Value);
		DirectorySelected = False;
		
		If SelectedFile.Exists() Then
			DirectorySelected = SelectedFile.IsDirectory();
		EndIf;
		
		If DirectorySelected Then
			FilesArrayOfThisDirectory = FindFilesPseudo(CheckParameters.PseudoFileSystem, Path);
			FindTooBigFiles(FilesArrayOfThisDirectory, ArrayOfTooBigFiles, CheckParameters.Recursively, 
				ExecutionParameters.TotalFilesCount, CheckParameters.PseudoFileSystem);
		Else
			FilesArray.Add(SelectedFile);
		EndIf;
	EndDo;
	
	If FilesArray.Count() <> 0 Then
		FindTooBigFiles(FilesArray, ArrayOfTooBigFiles, CheckParameters.Recursively, 
			ExecutionParameters.TotalFilesCount, CheckParameters.PseudoFileSystem);
	EndIf;
	
	// There was at least one file that was too big.
	If ArrayOfTooBigFiles.Count() <> 0 Then 
		TooBigFiles = New ValueList;
		Parameters = New Structure;
		
		For Each File In ArrayOfTooBigFiles Do
			BigFile = New File(File);
			FileSizeInMB = Int(BigFile.Size() / (1024 * 1024));
			StringText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (%2 MB)';
																						|ru = '%1 (%2 МБ)';
																						|en = '%1 (%2 MB)'; fa = '%1 (%2 MB)';
																						|it = '%1 (%2 MB)';
																						|pl = '%1 (%2 MB)';
																						|tr = '%1(%2 MB)'"), String(File), String(FileSizeInMB));
			TooBigFiles.Add(StringText);
		EndDo;
		
		Parameters.Insert("TooBigFiles", TooBigFiles);
		Parameters.Insert("Title", NStr("vi = 'Cảnh báo khi kết nhập tệp';
										|ru = 'Предупреждение при загрузке файлов';
										|en = 'File upload warning'; fa = 'File upload warning';
										|it = 'Avvertimento durante il download dei file';
										|pl = 'Ostrzeżenie podczas pobierania plików';
										|tr = 'Dosya içe aktarma uyarısı'"));
		
		Handler = New CallbackDescription("CheckFileSizeLimitAfterRespondQuestion", ThisObject, ExecutionParameters);
		OpenForm("DataProcessor.FilesOperations.Form.QuestionOnFileImport", Parameters, , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ExecutionParameters.Success = True;
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure CheckFileSizeLimitAfterRespondQuestion(Response, ExecutionParameters) Export
	
	ExecutionParameters.Success = (Response = DialogReturnCode.OK);
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

#EndRegion

#Region ShowInfoThatFileUnmodified

// It will show a reminder if it is set up.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//
Procedure ShowInformationFileWasNotModified(HandlerResults_1)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	If PersonalSettings.ShowFileNotModifiedFlag Then
		ReminderText = NStr("vi = 'Chưa tạo phiên bản, bởi vì tệp không thay đổi. Không lưu ghi chú.';
							|ru = 'Версия не была создана, т.к. файл не изменен. Комментарий не сохранен.';
							|en = 'Cannot create a new version because the file has not been modified. The comment is discarded.'; fa = 'Cannot create a new version because the file has not been modified. The comment is discarded.';
							|it = 'La versione non è stata creata poiché il file non è stato modificato. Commento non salvato.';
							|pl = 'Wersja nie powstała, ponieważ plik nie został zmieniony. Uwaga nie została zapisana.';
							|tr = 'Dosya değişmediğinden sürüm oluşturulmadı. Yorum kaydedilmedi.'");
		Buttons = QuestionDialogMode.OK;
		ReminderParameters = New Structure;
		ReminderParameters.Insert("LockWholeInterface", True);
		ReminderParameters.Insert("Picture", PictureLib.DialogInformation);
		ReminderParameters.Insert("CheckBoxText",
			NStr("vi = 'Không hiển thị thông báo này nữa';
				|ru = 'Больше не показывать это сообщение';
				|en = 'Do not show this message again'; fa = 'Do not show this message again';
				|it = 'Non mostrare più questo messaggio';
				|pl = 'Nie pokazuj więcej tego komunikatu.';
				|tr = 'Bu mesajı tekrar gösterme'"));
		ReminderParameters.Insert("Title",
			NStr("vi = 'Thông tin';
				|ru = 'Информация';
				|en = 'Information'; fa = 'اطلاعات';
				|it = 'Informazione';
				|pl = 'Information';
				|tr = 'Bilgi'"));
		StandardSubsystemsClient.ShowQuestionToUser(
			HandlerResults_1, ReminderText, Buttons, ReminderParameters);
	Else
		ReturnResult(HandlerResults_1, Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportEditedFileToAppUnlockAndNotify

// Continuation of the procedure (see above).
Procedure EndEditAndNotifyCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", FileWriteNotificationParameters("EditFinished"), ExecutionParameters.CommandParameter);
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.CommandParameter);
		
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Result);
	
EndProcedure

// Saves edited files to the infobase and removes the lock.
//
// Parameters:
//   Parameters - See FileUpdateParameters.
//
Procedure FinishEditByRefsWithNotification(Parameters) Export
	
	If TypeOf(Parameters.FilesArray) <> Type("Array") Then
		ReturnResult(Parameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	Handler = New CallbackDescription("FinishEditByRefsAfterInstallExtension", ThisObject, Parameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure FinishEditByRefsAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	ExecutionParameters.Insert("FilesData", New Array);
	FilesOperationsInternalServerCall.GetDataForFilesArray(ExecutionParameters.FilesArray, ExecutionParameters.FilesData);
	
	// Complete file editing
	FilesData = ExecutionParameters.FilesData; // Array of See FilesOperationsInternalServerCall.FileData -
	For Each FileData In FilesData Do
		
		HandlerParameters = FileUpdateParameters(Undefined, FileData.Ref, ExecutionParameters.FormIdentifier);
		FillPropertyValues(HandlerParameters, ExecutionParameters);
		HandlerParameters.Insert("FileData", Undefined);
		HandlerParameters.StoreVersions = FileData.StoreVersions;
		HandlerParameters.CurrentUserEditsFile = FileData.CurrentUserEditsFile;
		HandlerParameters.BeingEditedBy = FileData.BeingEditedBy;
		HandlerParameters.CurrentVersionAuthor = FileData.BeingEditedBy;
		HandlerParameters.Encoding = FileData.CurrentVersionEncoding;
		If ExecutionParameters.CanCreateFileVersions Then
			HandlerParameters.CreateNewVersion = ExecutionParameters.StoreVersions;
		Else
			HandlerParameters.CreateNewVersion = False;
		EndIf;
		HandlerParameters.ApplyToAll = True;
		
		If ExtensionInstalled Then
			FinishEditWithExtension(HandlerParameters);
		Else
			FinishEditWithoutExtension(HandlerParameters);
		EndIf;
	EndDo;
	
	ShowUserNotification(NStr("vi = 'Kết thúc soạn tệp';
								|ru = 'Завершить редактирование файлов';
								|en = 'Commit files'; fa = 'Commit files';
								|it = 'Terminare la modifica dei file';
								|pl = 'Zakończyć edycję plików';
								|tr = 'Dosya düzenlemeyi bitir'"),,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã hoàn tất soạn tệp (%1 trong số %2).';
				|ru = 'Завершено редактирование файлов (%1 из %2).';
				|en = 'Commit files (%1 of %2).'; fa = 'Commit files (%1 of %2).';
				|it = 'Modifica dei file terminata (%1 su %2).';
				|pl = 'Zakończona edycja plików (%1 z %2).';
				|tr = 'Dosya düzenleme tamamlandı (%1 / %2).'"),
			ExecutionParameters.FilesData.Count(),
			ExecutionParameters.FilesArray.Count()),
			PictureLib.DialogInformation);
	
	HandlerResults_1 = New CallbackDescription("FinishEditFilesArrayWithNotificationCompletion", ThisObject, ExecutionParameters);
	ReturnResult(HandlerResults_1, True);

EndProcedure

Procedure FinishEditFilesArrayWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		
		For Each FileRef In ExecutionParameters.FilesArray Do
			
			Notify("Write_File", FileWriteNotificationParameters("EditFinished"), FileRef);
			NotifyChanged(FileRef);
			Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
			Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), FileRef);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds files to the list with drag-and-drop.
//
// Parameters:
//  FileOwner      - AnyRef - file owner.
//  FormIdentifier - Form UUID.
//  FileNamesArray   - Array of String - file paths.
//
Procedure AddFilesWithDrag(Val FileOwner, Val FormIdentifier, Val FileNamesArray) Export
	
	AttachedFilesArray = New Array;
	PutSelectedFilesInStorage(
		FileNamesArray,
		FileOwner,
		AttachedFilesArray,
		FormIdentifier);
	
	If AttachedFilesArray.Count() = 1 Then
		AttachedFile = AttachedFilesArray[0];
		
		ShowUserNotification(
			NStr("vi = 'Tạo mới';
				|ru = 'Создание';
				|en = 'Create'; fa = 'ایجاد';
				|it = 'Creazione';
				|pl = 'Create';
				|tr = 'Oluştur'"),
			GetURL(AttachedFile),
			AttachedFile,
			PictureLib.DialogInformation);
		
		FormParameters = New Structure("AttachedFile, IsNew", AttachedFile, True);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters, , AttachedFile);
	EndIf;
	
	If AttachedFilesArray.Count() > 0 Then
		NotifyChanged(AttachedFilesArray[0]);
		NotifyChanged(FileOwner);
		FileWriteNotificationParameters = FileWriteNotificationParameters();
		FileWriteNotificationParameters.IsNew = True;
		FileWriteNotificationParameters.Owner = FileOwner;
		FileWriteNotificationParameters.FileOwner = FileWriteNotificationParameters.Owner;
		Notify("Write_File", FileWriteNotificationParameters, AttachedFilesArray);
	EndIf;
	
EndProcedure

#EndRegion

#Region LockFileOpenEditorAndNotify

// Locks a file for editing and opens it.
Procedure EditWithNotification(HandlerResults_1, ObjectRef,
	UUID = Undefined, OwnerWorkingDirectory = Undefined) Export
	
	If ObjectRef = Undefined Then
		ReturnResult(HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("ObjectRef", ObjectRef);
	Handler = New CallbackDescription("EditWithNotificationCompletion", ThisObject, ExecutionParameters);
	EditFileByRef(Handler, ObjectRef, UUID, OwnerWorkingDirectory);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure EditWithNotificationCompletion(FileEdited, ExecutionParameters) Export
	
	If FileEdited Then
		NotifyChanged(ExecutionParameters.ObjectRef);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.ObjectRef);
		Notify("Write_File", FileWriteNotificationParameters("FileWasEdited"), ExecutionParameters.ObjectRef);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region LockFileOrFilesAndNotify

// Locks a file or several files.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   CommandParameter - either a reference to a file or an array of references to files.
//   UUID.
//
Procedure LockWithNotification(HandlerResults_1, CommandParameter, UUID = Undefined) Export
	
	If CommandParameter = Undefined Then
		ReturnResult(HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("CommandParameter", CommandParameter);
	If TypeOf(CommandParameter) = Type("Array") Then
		Handler = New CallbackDescription("LockWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		LockFilesByRefs(Handler, CommandParameter);
	Else
		Handler = New CallbackDescription("LockWIthNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		LockFileByRef(Handler, CommandParameter, UUID)
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
		NotifyChanged(FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure LockWIthNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region UnlockFileAndNotify

// Unlocks a file locked earlier.
//
// Parameters:
//   Parameters - See FileUnlockParameters.
//
Procedure UnlockFileWithNotification(Parameters) Export
	
	If Parameters.ObjectRef = Undefined Then
		ReturnResult(Parameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", Parameters.HandlerResults_1);
	ExecutionParameters.Insert("CommandParameter", Parameters.ObjectRef);
	If TypeOf(Parameters.ObjectRef) = Type("Array") Then
		Handler = New CallbackDescription("UnlockFileWithNotificationFilesArrayCompletion", ThisObject, ExecutionParameters);
		UnlockFilesByRefs(Handler, Parameters.ObjectRef);
	Else
		Handler = New CallbackDescription("UnlockFileWithNotificationOneFileCompletion", ThisObject, ExecutionParameters);
		UnlockParameters = FileUnlockParameters(Handler, Parameters.ObjectRef);
		UnlockParameters.StoreVersions = Parameters.StoreVersions;
		UnlockParameters.CurrentUserEditsFile = Parameters.CurrentUserEditsFile;
		UnlockParameters.BeingEditedBy = Parameters.BeingEditedBy;
		UnlockParameters.UUID = Parameters.UUID;
		UnlockFile(Parameters);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileWithNotificationFilesArrayCompletion(Result, ExecutionParameters) Export
	
	NotifyChanged(Type("CatalogRef.Files"));
	For Each FileRef In ExecutionParameters.CommandParameter Do
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	EndDo;
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure UnlockFileWithNotificationOneFileCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		
		NotifyChanged(ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region OpenFileAndNotify

// Opens a file.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Undefined - description of the procedure that receives the method result.
//   FileData             - Structure
//   UUID - UUID - forms.
//
Procedure OpenFileWithNotification(HandlerResults_1, FileData, UUID = Undefined, ForEditing = True) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("ForEditing", ForEditing);
	ExecutionParameters.Insert("UUID", UUID);
	
	// The file does not contain the owner, just open it by reference from the temporary storage.
	If Not ExecutionParameters.FileData.Property("Owner") Or Not ValueIsFilled(ExecutionParameters.FileData.Owner) Then
		CallbackDescription = New CallbackDescription("OpenFileAddInSuggested", FilesOperationsInternalClient, ExecutionParameters);
		ShowQuestionOn1CEnterpriseExtensionInstallation(CallbackDescription);
		Return;
	EndIf;
	
	// If File does not have a file, open the card.
	If ExecutionParameters.FileData.Version.IsEmpty() And ExecutionParameters.FileData.StoreVersions Then
		Handler = New CallbackDescription("OpenFileWithNotificationCompletion", ThisObject, ExecutionParameters);
		ShowValue(Handler, ExecutionParameters.FileData.Ref);
		Return;
	EndIf;
	
	Handler = New CallbackDescription("OpenFileWithNotificationAfterInstallExtension", ThisObject, ExecutionParameters);
	ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithNotificationAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	
	If Is1CEnterpriseExtensionAttached() Then
		Handler = New CallbackDescription("OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(
			Handler,
			ExecutionParameters.FileData,
			"",
			ExecutionParameters.UUID,
			New Structure("OpenFile", True));
	Else
		FillTemporaryFormID(ExecutionParameters.UUID, ExecutionParameters);
		
		Handler = New CallbackDescription("OpenFileWithNotificationCompletion", ThisObject, ExecutionParameters);
		OpenFileWithoutExtension(Handler, ExecutionParameters.FileData, ExecutionParameters.UUID);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithNotificationWithExtensionAfterGetVersionToWorkingDirectory(Result, ExecutionParameters) Export
	
	If Result.FileReceived = True Then
		FileOnHardDrive = New File(Result.FullFileName);
		FileOnHardDrive.SetReadOnly(Not ExecutionParameters.ForEditing);
		UUID = ?(ExecutionParameters.Property("UUID"),
			ExecutionParameters.UUID, Undefined);
		OpenFileWithApplication(ExecutionParameters.FileData, Result.FullFileName, UUID);
	EndIf;
	
	OpenFileWithNotificationCompletion(Result.FileReceived = True, ExecutionParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure OpenFileWithNotificationCompletion(Result, ExecutionParameters) Export
	
	ClearTemporaryFormID(ExecutionParameters);
	
	If Result <> True Then
		Return;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Event", "FileOpened");
	Notify("FileOpened", NotificationParameters, ExecutionParameters.FileData.Ref);
	
EndProcedure


Procedure OpenFileWithoutExtension(Notification, FileData, FormIdentifier,
		WithNotification = True, SaveDecrypted = True, EncryptedFilesExtension = "")
	
	Context = New Structure;
	Context.Insert("Notification",             Notification);
	Context.Insert("FileData",            FileData);
	Context.Insert("FormIdentifier",     FormIdentifier);
	Context.Insert("WithNotification",       WithNotification);
	Context.Insert("SaveDecrypted", SaveDecrypted);
	Context.Insert("EncryptedFilesExtension", EncryptedFilesExtension);
	
	If Context.SaveDecrypted
		And FileData.Encrypted Then
		
		If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
			RunCallback(Context.Notification, False);
			Return;
		EndIf;
		
		ReturnStructure = FilesOperationsInternalServerCall.FileDataAndBinaryData(
			FileData.Version,, FormIdentifier);
		
		DataDetails = New Structure;
		DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
															|ru = 'Расшифровка файла';
															|en = 'Decrypt file'; fa = 'Decrypt file';
															|it = 'Decodifica del file';
															|pl = 'Deszyfrowanie plików';
															|tr = 'Dosya detaylandırması'"));
		DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
													|ru = 'Файл';
													|en = 'File'; fa = 'فایل';
													|it = 'File';
													|pl = 'File';
													|tr = 'Dosya'"));
		DataDetails.Insert("Data",                ReturnStructure.BinaryData);
		DataDetails.Insert("Presentation",         FileData.Ref);
		DataDetails.Insert("Object",                FileData.Ref);
		DataDetails.Insert("EncryptionCertificates", FileData.Ref);
		DataDetails.Insert("NotifyOnCompletion",   False);
		
		FollowUpHandler = New CallbackDescription(
			"OpenFileWithoutExtensionAfterDecryption", ThisObject, Context);
		
		ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
		ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
		Return;
		
	EndIf;
	
	Context.Insert("FileAddress", FileData.RefToBinaryFileData);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionAfterDecryption(DataDetails, Context) Export
	
	If Not DataDetails.Success Then
		RunCallback(Context.Notification, False);
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			Context.FormIdentifier);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	Context.Insert("FileAddress", FileAddress);
	
	OpenFileWithoutExtensionReminder(Context);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionReminder(Context)
	
	If Context.WithNotification
		And Context.FileData.CurrentUserEditsFile Then
		
		OutputNotificationOnEdit(New CallbackDescription(
		"OpenFileWithoutExtensionFileSending", ThisObject, Context));
	Else
		OpenFileWithoutExtensionFileSending(True, Context);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure OpenFileWithoutExtensionFileSending(Result, Context) Export
	
	If (TypeOf(Result) = Type("Structure") And Result.Value = "Cancel") Or Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") And Result.Property("NeverAskAgain") And Result.NeverAskAgain Then
		FilesOperationsInternalServerCall.ShowTooltipsOnEditFiles(False);
	EndIf;
	
	If Not Context.SaveDecrypted
		And Context.FileData.Encrypted
		And ValueIsFilled(Context.EncryptedFilesExtension) Then
		
		Extension = Context.EncryptedFilesExtension;
	Else
		Extension = Context.FileData.Extension;
	EndIf;
	
	FileName = CommonClientServer.GetNameWithExtension(
		Context.FileData.FullVersionDescription, Extension);
	
	GetFile(Context.FileAddress, FileName, True);
	
	RunCallback(Context.Notification, True);
	
EndProcedure

// Fills in a temporary form ID for cases when it is not necessary
// to return data in temporary storage to the calling code, for example,
// as in the Open and OpenFileDirectory procedures in the FilesOperationsClient common module.
//
Procedure FillTemporaryFormID(FormIdentifier, ExecutionParameters)
	
	If ValueIsFilled(FormIdentifier) Then
		Return;
	EndIf;
	
	ExecutionParameters.Insert("TempForm", GetForm("DataProcessor.FilesOperations.Form.QuestionForm")); // ACC:65
	FormIdentifier = ExecutionParameters.TempForm.UUID;
	StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, True);
	
EndProcedure

// Cancels the storage of the temporary ID, filled earlier.
Procedure ClearTemporaryFormID(ExecutionParameters)
	
	If ExecutionParameters.Property("TempForm") Then
		StandardSubsystemsClient.SetFormStorageOption(ExecutionParameters.TempForm, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportFileToAppAndNotify

// Continuation of the procedure (see above).
Procedure SaveFileChangesWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.CommandParameter);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.CommandParameter);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Result);
	
EndProcedure

#EndRegion

#Region ShowFileDialogImportSelectedFileToAppAsVersionAndNotify

// Selects a file and creates a new version from it.
Procedure UpdateFromFileOnHardDriveWithNotification(HandlerResults_1, FileData, FormIdentifier,
	FileAddingOptions = Undefined) Export
	
	If Not Is1CEnterpriseExtensionAttached() Then
		Show1CEnterpriseExtensionRequiredMessageBox(HandlerResults_1);
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	Handler = New CallbackDescription("UpdateFromFileOnHardDriveWithNotificationCompletion", ThisObject, ExecutionParameters);
	UpdateFromFileOnHardDrive(Handler, FileData, FormIdentifier, FileAddingOptions);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters   - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure UpdateFromFileOnHardDriveWithNotificationCompletion(Result, ExecutionParameters) Export
	
	If Result = True Then
		NotifyChanged(ExecutionParameters.FileData.Ref);
		Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), ExecutionParameters.FileData.Ref);
		Notify("Write_File", FileWriteNotificationParameters("VersionSaved"), ExecutionParameters.FileData.Ref);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	
EndProcedure

#EndRegion

#Region FileEncryption

// Encrypt file.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileData - See FilesOperationsInternalServerCall.FileData
//  UUID - UUID - a form ID.
//
Procedure Encrypt(HandlerResults_1, FileData, UUID) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	ExecutionParameters.Insert("ThumbprintsArray", New Array);
	
	If ExecutionParameters.FileData.Encrypted Then
		WarningText = NStr("vi = 'Tệp ""%1"" đã mã hóa.';
							|ru = 'Файл ""%1"" уже зашифрован.';
							|en = 'File ""%1"" is already encrypted.'; fa = 'File ""%1"" is already encrypted.';
							|it = 'Il file ""%1"" è già cifrato.';
							|pl = 'Plik ""%1"" jest już zaszyfrowany.';
							|tr = '""%1"" Dosyası zaten şifrelenmiş.'");
		WarningText = StrReplace(WarningText, "%1", String(ExecutionParameters.FileData.Ref));
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If ValueIsFilled(ExecutionParameters.FileData.BeingEditedBy) Then
		WarningText = NStr("vi = 'Không thể mã hóa tệp đang chiếm.';
							|ru = 'Нельзя зашифровать занятый файл.';
							|en = 'Cannot encrypt the file because it is locked.'; fa = 'Cannot encrypt the file because it is locked.';
							|it = 'Non si può cifrare un file occupato.';
							|pl = 'Nie można zaszyfrować zajęty plik.';
							|tr = 'Kilitli dosya şifrelenemiyor.'");
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, WarningText, ExecutionParameters);
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(ExecutionParameters.FileData.Ref,
		ExecutionParameters.UUID);
	If VersionsArray.Count() = 0 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, False);
		Return;
	EndIf;
	
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	
	FilePresentation = String(ExecutionParameters.FileData.Ref);
	If ExecutionParameters.FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phiên bản: %1';
				|ru = 'Версий: %1';
				|en = 'Versions: %1'; fa = 'Versions: %1';
				|it = 'Versioni: %1';
				|pl = 'Wersji: %1';
				|tr = 'Sürümler: %1'"), ExecutionParameters.FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(ExecutionParameters.FileData.Ref, FilePresentation);
	
	DataSet = New Array;
	
	For Each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataElement = New Structure;
		DataElement.Insert("Data", VersionProperties.VersionURL);
		
		DataElement.Insert("ResultPlacement", New CallbackDescription(
			"OnGetEncryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataElement);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",            NStr("vi = 'Mã hóa tệp';
													|ru = 'Шифрование файла';
													|en = 'Encrypt file'; fa = 'Encrypt file';
													|it = 'Cifratura del file';
													|pl = 'Szyfrowanie pliku';
													|tr = 'Dosya şifreleme'"));
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("DataSet",         DataSet);
	DataDetails.Insert("SetPresentation", NStr("vi = 'Tệp (%1)';
												|ru = 'Файлы (%1)';
												|en = 'Files (%1)'; fa = 'Files (%1)';
												|it = 'File (%1)';
												|pl = 'Pliki (%1)';
												|tr = 'Dosyalar (%1)'"));
	DataDetails.Insert("PresentationsList", PresentationsList);
	DataDetails.Insert("NotifyOnCompletion", False);
	
	FollowUpHandler = New CallbackDescription("AfterFileEncryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Encrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Parameters:
//   CurrentExecutionParameters - Structure:
//     * ExecutionParameters - Structure:
//       ** DataArrayToStoreInDatabase - Array
//
Procedure OnGetEncryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	EncryptedData = Parameters.DataDetails.CurrentDataSetItem.EncryptedData;
	If TypeOf(EncryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(EncryptedData,
			ExecutionParameters.UUID);
	Else
		TempStorageAddress = EncryptedData;
	EndIf;
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", "");
	
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	RunCallback(Parameters.Notification, New Structure);
	
EndProcedure

// The Encrypt procedure completion. It is called from the DigitalSignature subsystem.
Procedure AfterFileEncryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		If TypeOf(DataDetails.EncryptionCertificates) = Type("String") Then
			ExecutionParameters.Insert("ThumbprintsArray", GetFromTempStorage(
				DataDetails.EncryptionCertificates));
		Else
			ExecutionParameters.Insert("ThumbprintsArray", DataDetails.EncryptionCertificates);
		EndIf;
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

#EndRegion

#Region FileDrilldown

// Decrypt file.
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//                       - Undefined - description of the procedure that receives the method result.
//  FileRef  - CatalogRef.Files - file.
//  UUID - UUID - a form ID.
//  FileData  - See FilesOperationsInternalServerCall.FileData
//
Procedure Decrypt(HandlerResults_1, FileRef, UUID, FileData) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileRef", FileRef);
	ExecutionParameters.Insert("UUID", UUID);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("Success", False);
	ExecutionParameters.Insert("DataArrayToStoreInDatabase", New Array);
	
	VersionsArray = FilesOperationsInternalServerCall.FileDataAndURLOfAllFileVersions(
		ExecutionParameters.FileRef, ExecutionParameters.UUID);
	ExecutionParameters.DataArrayToStoreInDatabase = New Array;
	ExecutionParameters.Insert("ExtractTextFilesOnServer",
		CommonFilesOperationsSettings().ExtractTextFilesOnServer);
	
	FilePresentation = String(FileData.Ref);
	If FileData.VersionsCount > 1 Then
		FilePresentation = FilePresentation + " (" + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phiên bản: %1';
				|ru = 'Версий: %1';
				|en = 'Versions: %1'; fa = 'Versions: %1';
				|it = 'Versioni: %1';
				|pl = 'Wersji: %1';
				|tr = 'Sürümler: %1'"), FileData.VersionsCount) + ")";
	EndIf;
	PresentationsList = New ValueList;
	PresentationsList.Add(FileData.Ref, FilePresentation);
	
	EncryptionCertificates = New Array;
	EncryptionCertificates.Add(FileData.Ref);
	
	DataSet = New Array;
	
	For Each VersionProperties In VersionsArray Do
		
		CurrentExecutionParameters = New Structure;
		CurrentExecutionParameters.Insert("ExecutionParameters", ExecutionParameters);
		CurrentExecutionParameters.Insert("VersionRef", VersionProperties.VersionRef);
		CurrentExecutionParameters.Insert("FileAddress",   VersionProperties.VersionURL);
		
		DataElement = New Structure;
		DataElement.Insert("Data", VersionProperties.VersionURL);
		
		DataElement.Insert("ResultPlacement", New CallbackDescription(
			"OnGetDecryptedData", ThisObject, CurrentExecutionParameters));
		
		DataSet.Add(DataElement);
	EndDo;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation",              NStr("vi = 'Giải mã tệp';
														|ru = 'Расшифровка файла';
														|en = 'Decrypt file'; fa = 'Decrypt file';
														|it = 'Decodifica del file';
														|pl = 'Deszyfrowanie plików';
														|tr = 'Dosya detaylandırması'"));
	DataDetails.Insert("DataTitle",       NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'File';
												|pl = 'File';
												|tr = 'Dosya'"));
	DataDetails.Insert("DataSet",           DataSet);
	DataDetails.Insert("SetPresentation",   NStr("vi = 'Tệp (%1)';
												|ru = 'Файлы (%1)';
												|en = 'Files (%1)'; fa = 'Files (%1)';
												|it = 'File (%1)';
												|pl = 'Pliki (%1)';
												|tr = 'Dosyalar (%1)'"));
	DataDetails.Insert("PresentationsList",   PresentationsList);
	DataDetails.Insert("EncryptionCertificates", EncryptionCertificates);
	DataDetails.Insert("NotifyOnCompletion",   False);
	
	FollowUpHandler = New CallbackDescription("AfterFileDecryption", ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails, , FollowUpHandler);
	
EndProcedure

// Parameters:
//   CurrentExecutionParameters - Structure:
//     * ExecutionParameters - Structure:
//       ** FileData - See FilesOperationsInternalServerCall.FileData
//       ** DataArrayToStoreInDatabase - Array
//
Procedure OnGetDecryptedData(Parameters, CurrentExecutionParameters) Export
	
	ExecutionParameters = CurrentExecutionParameters.ExecutionParameters;
	
	DecryptedData = Parameters.DataDetails.CurrentDataSetItem.DecryptedData;
	If TypeOf(DecryptedData) = Type("BinaryData") Then
		TempStorageAddress = PutToTempStorage(DecryptedData,
			ExecutionParameters.UUID);
#If Not WebClient Then
			DecodedBinaryData = DecryptedData;
#EndIf
	Else
		TempStorageAddress = DecryptedData;
#If Not WebClient Then
			DecodedBinaryData = GetFromTempStorage(TempStorageAddress);
#EndIf
	EndIf;
	
	TempTextStorageAddress = "";
#If Not WebClient Then
	If Not ExecutionParameters.ExtractTextFilesOnServer Then
		FullFilePath = GetTempFileName(ExecutionParameters.FileData.Extension);
		DecodedBinaryData.Write(FullFilePath);
		
		TempTextStorageAddress = ExtractTextToTempStorage(FullFilePath, ExecutionParameters.UUID);
		Try
			DeleteFiles(FullFilePath);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;	
	EndIf;
#EndIf
	
	DataToWriteAtServer = New Structure;
	DataToWriteAtServer.Insert("TempStorageAddress", TempStorageAddress);
	DataToWriteAtServer.Insert("VersionRef", CurrentExecutionParameters.VersionRef);
	DataToWriteAtServer.Insert("FileAddress",   CurrentExecutionParameters.FileAddress);
	DataToWriteAtServer.Insert("TempTextStorageAddress", TempTextStorageAddress);
	ExecutionParameters.DataArrayToStoreInDatabase.Add(DataToWriteAtServer);
	
	RunCallback(Parameters.Notification, New Structure);
	
EndProcedure

// The Decrypt procedure completion. It is called from the DigitalSignature subsystem.
Procedure AfterFileDecryption(DataDetails, ExecutionParameters) Export
	
	ExecutionParameters.Success = DataDetails.Success;
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
	
EndProcedure

// Continues the VerifySignatures procedure. It is called from the DigitalSignature subsystem.
Procedure AfterFileDecryptionOnCheckSignature(DataDetails, AdditionalParameters) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	CheckSignaturesAfterPrepareData(DataDetails.DecryptedData, AdditionalParameters);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// Procedures that follow asynchronous procedures.

#Region NewFileCreation

// Creates a new file interactively calling the dialog box of selection the File creation mode.
//
// Parameters:
//   See FilesOperationsClient.AppendFile().
//
Procedure AppendFile(
	HandlerResults_1,
	FileOwner,
	OwnerForm,
	CreateMode = 1,
	AddingOptions = Undefined) Export
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaximumSize", 0);
		ExecutionParameters.Insert("SelectionDialogFilter",  StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																															|ru = 'Все файлы (%1)|%1';
																															|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																															|it = 'Все файлы (%1)|%1';
																															|pl = 'All files (%1)|%1';
																															|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask()));
		ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", ?(AddingOptions = Undefined, False, AddingOptions));
		
	Else
		ExecutionParameters.Insert("MaximumSize", AddingOptions.MaximumSize);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
		ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", AddingOptions.NotOpenCard);
	EndIf;
	
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("FileOwner", FileOwner);
	ExecutionParameters.Insert("OwnerForm", OwnerForm);
	ExecutionParameters.Insert("IsFile", True);
	
	Handler = New CallbackDescription("AddAfterCreationModeChoice", ThisObject, ExecutionParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", CreateMode);
	
	Context = New Structure;
	Context.Insert("FormParameters", FormParameters);
	Context.Insert("Handler", Handler);
	
	FormParameters.Insert("ScanCommandAvailable", ScanAvailable());
	
	OpenForm("Catalog.Files.Form.FormNewItem", FormParameters, , , , , Context.Handler);
	
EndProcedure

Procedure AddFileFromFileSystem(FileOwner, OwnerForm) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1",                    Undefined);
	ExecutionParameters.Insert("FileOwner",                           FileOwner);
	ExecutionParameters.Insert("OwnerForm",                           OwnerForm);
	ExecutionParameters.Insert("IsFile",                                 True);
	
	AddAfterCreationModeChoice(2, ExecutionParameters);
	
EndProcedure

// Creates a new file interactively, using the specified method.
//
// Parameters:
//   CreateMode - Number - file creation mode.
//       1 - from a template (by copying another file)
//       2 - from a computer (from the file system)
//       3 - from a scanner.
//   ExecutionParameters - Structure - For value types and descriptions, see "FilesOperationsClient.AddFile".:
//       * 
//       * 
//       * OwnerForm
//       * 
//
Procedure AddAfterCreationModeChoice(CreateMode, ExecutionParameters) Export
	
	ExecutionParameters.Insert("NotOpenCardAfterCreateFromFile", True);
	
	If CreateMode = 1 Then // Copy another file.
		AddBasedOnTemplate(ExecutionParameters);
	ElsIf CreateMode = 2 Then // Import from file system.
		If Is1CEnterpriseExtensionAttached() Then
			AddFormFileSystemWithExtension(ExecutionParameters);
		Else
			AddFromFileSystemWithoutExtension(ExecutionParameters);
		EndIf;
	ElsIf CreateMode = 3 Then // Read from the scanner.
		AddingOptions = FilesOperationsClient.AddingFromScannerParameters();
		FillPropertyValues(AddingOptions, ExecutionParameters);
		AddFromScanner(AddingOptions);
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddBasedOnTemplate(ExecutionParameters) Export
	
	// Copy from the template file.
	FormParameters = New Structure;
	FormParameters.Insert("SelectTemplate1", True);
	FormParameters.Insert("CurrentRow", PredefinedValue("Catalog.FilesFolders.Templates"));
	Handler = New CallbackDescription("AddBasedOnTemplateAfterTemplateChoice", ThisObject, ExecutionParameters);
	OpeningMode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm("Catalog.Files.Form.ChoiceForm", FormParameters, , , , , Handler, OpeningMode);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddBasedOnTemplateAfterTemplateChoice(Result, ExecutionParameters) Export
	
	If Result = Undefined Then
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateMode", "FromTemplate");
	FormParameters.Insert("FilesStorageCatalogName",
		?(ExecutionParameters.Property("FilesStorageCatalogName"),
		ExecutionParameters.FilesStorageCatalogName, 
		FilesOperationsInternalServerCall.FileStoringCatalogName(ExecutionParameters.FileOwner)));
		
	OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.HandlerResults_1);
	FilesOperationsClient.CopyAttachedFile(ExecutionParameters.FileOwner, Result, FormParameters, OnCloseNotifyDescription); 
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutExtension(ExecutionParameters)
	
	// Import from file system without 1C:Enterprise Extension (web client).
	ChoiceDialog = New FileDialog(FileDialogMode.Open);
	If ExecutionParameters.Property("SelectionDialogFilter") Then
		ChoiceDialog.Filter = ExecutionParameters.SelectionDialogFilter;
	EndIf;
	
	Handler = New CallbackDescription("AddFromFileSystemWithoutFileSystemExtensionAfterImportFile", ThisObject, ExecutionParameters);
	BeginPutFile(Handler, , ChoiceDialog, , ExecutionParameters.OwnerForm.UUID);
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutFileSystemExtensionAfterImportFile(Put, Address, SelectedFileName, ExecutionParameters) Export
	
	If Not Put Then
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef",   Undefined);
	Result.Insert("ErrorText",  "");
	
	PathStructure = CommonClientServer.ParseFullFileName(SelectedFileName);
	If IsBlankString(PathStructure.Extension) Then
		QueryText = NStr("vi = 'Hãy chỉ ra tệp có phần mở rộng.';
						|ru = 'Укажите файл с расширением.';
						|en = 'Select a file with an extension.'; fa = 'Select a file with an extension.';
						|it = 'Indicare file con estensione.';
						|pl = 'Podaj plik z rozszerzeniem.';
						|tr = 'Uzantılı bir dosya belirtin.'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Retry, NStr("vi = 'Chọn tệp khác';
												|ru = 'Выбрать другой файл';
												|en = 'Select another file'; fa = 'Select another file';
												|it = 'Selezionare un altro file';
												|pl = 'Wybierz inny plik';
												|tr = 'Başka bir dosya seçin'"));
		Buttons.Add(DialogReturnCode.Cancel);
		Handler = New CallbackDescription("AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QueryText, Buttons);
		Return;
	EndIf;
	
	If ExecutionParameters.Property("MaximumSize")
		And ExecutionParameters.MaximumSize > 0 Then
		
		FileSize = GetFromTempStorage(Address).Size();
		If FileSize > ExecutionParameters.MaximumSize*1024*1024 Then
			
			ErrorText = NStr("vi = 'Kích thước tệp vượt quá %1 Mb.';
							|ru = 'Размер файла превышает %1 Мб.';
							|en = 'The file size exceeds %1 MB.'; fa = 'The file size exceeds %1 MB.';
							|it = 'La dimensione del file supera %1 Mb.';
							|pl = 'Rozmiar pliku przekracza %1 MB.';
							|tr = 'Dosya boyutu %1 Mb aşıyor.'");
			Result.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
				ExecutionParameters.MaximumSize);
			ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, Result.ErrorText, Undefined);
			Return;
			
		EndIf;
		
	EndIf;
	
	// Creating a file in the infobase.
	Try
		
		If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.FileOwner) Then
			
			FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion");
			FileInfo1.TempFileStorageAddress = Address;
			FileInfo1.BaseName = PathStructure.BaseName;
			FileInfo1.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
			Result.FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(ExecutionParameters.FileOwner, FileInfo1);
			Result.FileAdded = True;
			
		Else
			
			FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
			FileParameters.FilesOwner = ExecutionParameters.FileOwner;
			FileParameters.BaseName = PathStructure.BaseName;
			FileParameters.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(PathStructure.Extension);
			
			Result.FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,Address);
			Result.FileAdded = True;
			
		EndIf;
		
	Except
		Result.ErrorText = ErrorCreatingNewFile(ErrorInfo());
	EndTry;
	If Result.ErrorText <> "" Then
		ReturnResultAfterShowWarning(ExecutionParameters.HandlerResults_1, Result.ErrorText, Undefined);
		Return;
	EndIf;
	
	NotificationParameters = FileWriteNotificationParameters();
	NotificationParameters.Owner = ExecutionParameters.FileOwner;
	NotificationParameters.File = Result.FileRef;
	NotificationParameters.IsNew = True;
	Notify("Write_File", NotificationParameters, Result.FileRef);
	
	ShowUserNotification(
		NStr("vi = 'Tạo mới:';
			|ru = 'Создание:';
			|en = 'Created:'; fa = 'ایجادشده:';
			|it = 'Creazione:';
			|pl = 'Created:';
			|tr = 'Oluşturuldu:'"),
		GetURL(Result.FileRef),
		Result.FileRef,
		PictureLib.DialogInformation);
	
	If ExecutionParameters.NotOpenCardAfterCreateFromFile <> True Then
		FormParameters = New Structure("OpenCardAfterCreateFile", True);
		OnCloseNotifyDescription = CompletionHandler(ExecutionParameters.HandlerResults_1);
		FilesOperationsClient.OpenFileForm(Result.FileRef,, FormParameters, OnCloseNotifyDescription);
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, Result);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure AddFromFileSystemWithoutExtensionAfterRespondQuestionContinue(Response, ExecutionParameters) Export
	
	If Response = DialogReturnCode.Retry Then
		AddFromFileSystemWithoutExtension(ExecutionParameters);
	Else
		ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsToManageCryptographyFromFileForm

// Parameters:
//  Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificates(Form) Export
	
	If Form.DigitalSignatures.Count() = 0 Then
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("Form", Form);
	Context.Insert("ModuleDigitalSignatureClient",
		CommonClient.CommonModule("DigitalSignatureClient"));
	Context.Insert("ModuleDigitalSignatureInternalClientServer",
		CommonClient.CommonModule("DigitalSignatureInternalClientServer"));
	
	If Context.ModuleDigitalSignatureClient.VerifyDigitalSignaturesOnTheServer() Then
		Return;
	EndIf;
	
	BeginAttachingCryptoExtension(New CallbackDescription(
		"ReadSignaturesCertificatesAfterAttachExtension", ThisObject, Context));
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
Procedure ReadSignaturesCertificatesAfterAttachExtension(Attached, Context) Export
	
	If Not Attached Then
		Return;
	EndIf;
	
	Context.ModuleDigitalSignatureClient.CreateCryptoManager(New CallbackDescription(
			"ReadSignaturesCertificatesAfterCreateCryptoManager", ThisObject, Context),
		"GetCertificates", False);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
Procedure ReadSignaturesCertificatesAfterCreateCryptoManager(Result, Context) Export
	
	If TypeOf(Result) <> Type("CryptoManager") Then
		Return;
	EndIf;
	
	Context.Insert("IndexOf", -1);
	Context.Insert("CryptoManager", Result);
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
//
// Parameters:
//   Context - Structure:
//    * Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificatesLoopStart(Context)
	
	If Context.Form.DigitalSignatures.Count() <= Context.IndexOf + 1 Then
		Return;
	EndIf;
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("TableRow", Context.Form.DigitalSignatures[Context.IndexOf]);
	
	If ValueIsFilled(Context.TableRow.Thumbprint) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	If Not ValueIsFilled(Context.TableRow.SignatureAddress) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	// The signature was not read when writing the object
	Signature = GetFromTempStorage(Context.TableRow.SignatureAddress);
	
	If Not ValueIsFilled(Signature) Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Context.CryptoManager.BeginGettingCertificatesFromSignature(New CallbackDescription(
			"ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature", ThisObject, Context,
			"ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError", ThisObject),
		Signature);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
Procedure ReadSignatureCertificatesLoopAfterGetCertificatesFromSignatureError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
Procedure ReadSignaturesCertificatesLoopAfterGetCertificatesFromSignature(Certificates, Context) Export
	
	If Certificates.Count() = 0 Then
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndIf;
	
	Try
		If Certificates.Count() = 1 Then
			Certificate = Certificates[0]; // CryptoCertificate
		ElsIf Certificates.Count() > 1 Then
			Certificate = Context.ModuleDigitalSignatureInternalClientServer.CertificatesInOrderToRoot(Certificates)[0]; // CryptoCertificate
		EndIf;
	Except
		ReadSignaturesCertificatesLoopStart(Context);
		Return;
	EndTry;

	Context.Insert("Certificate", Certificate);
	Certificate.BeginUnloading(New CallbackDescription(
		"ReadSignaturesCertificatesLoopAfterExportCertificate", ThisObject, Context,
		"ReadSignatureCertificatesLoopAfterExportCertificateError", ThisObject));
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
Procedure ReadSignatureCertificatesLoopAfterExportCertificateError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure

// Continue the ReadSignaturesCertificates procedure.
//
// Parameters:
//   Context - Structure:
//    * Form - ClientApplicationForm
//
Procedure ReadSignaturesCertificatesLoopAfterExportCertificate(CertificateData, Context) Export
	
	TableRow = Context.TableRow;
	
	TableRow.Thumbprint = Base64String(Context.Certificate.Thumbprint);
	TableRow.CertificateAddress = PutToTempStorage(CertificateData, Context.Form.UUID);
	TableRow.CertificateOwner = Context.ModuleDigitalSignatureClient.SubjectPresentation(Context.Certificate);
	
	ReadSignaturesCertificatesLoopStart(Context);
	
EndProcedure


// Notifies by the end of Encrypt.
// Parameters:
//  FilesArrayInWorkingDirectoryToDelete - Array - an array of strings that are paths to files.
//  FileOwner  - AnyRef - file owner.
//  FileRef  - CatalogRef.Files - file.
//
Procedure InformOfEncryption(FilesArrayInWorkingDirectoryToDelete,
                                   FileOwner,
                                   FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	
	// Deleting all file versions from working directory.
	For Each FullFileName In FilesArrayInWorkingDirectoryToDelete Do
		DeleteFileWithoutConfirmation(FullFileName);
	EndDo;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectEncryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp: %1';
				|ru = 'Файл: %1';
				|en = 'File: %1'; fa = 'File: %1';
				|it = 'File: %1';
				|pl = 'Plik: %1';
				|tr = 'Dosya: %1'"), FileRef));
	
EndProcedure

// Notifies by the end of Decrypt.
// Parameters:
//  FileOwner  - AnyRef - file owner.
//  FileRef  - CatalogRef.Files - file.
//
Procedure InformOfDecryption(FileOwner, FileRef) Export
	
	NotifyChanged(FileRef);
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileEncrypted"), FileOwner);
	Notify("Write_File", FileWriteNotificationParameters("FileDataChanged"), FileRef);
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.InformOfObjectDecryption(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp: %1';
				|ru = 'Файл: %1';
				|en = 'File: %1'; fa = 'File: %1';
				|it = 'File: %1';
				|pl = 'Plik: %1';
				|tr = 'Dosya: %1'"), FileRef));
	
EndProcedure

#EndRegion

#Region DigitalSignaturesManagement

Procedure SendFileForSigning(AttachedFile, FileData, FormIdentifier,
			CompletionHandler = Undefined, HandlerOnGetSignature = Undefined, SignatureParameters = Undefined) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("AttachedFile",   AttachedFile);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormIdentifier",   FormIdentifier);
	
	FollowUpHandler = New CallbackDescription("AfterSendForSigning", ThisObject, ExecutionParameters);
	If Not CheckSignPossibility(FileData, CompletionHandler, FollowUpHandler, ExecutionParameters) Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("ShowComment", True);
	
	SignArrayOfFiles = TypeOf(AttachedFile) = Type("Array");
	DataSet = New Array;
	
	If SignArrayOfFiles  Then
		
		If AttachedFile.Count() > 1 Then
			DataDetails.Insert("Operation",            NStr("vi = 'Gửi tệp để ký tên';
															|ru = 'Отправка файлов на подписание';
															|en = 'Send file for signing'; fa = 'Send file for signing';
															|it = 'Send file for signing';
															|pl = 'Send file for signing';
															|tr = 'Dosyaları imzalanmaya gönderme'"));
			DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
													|ru = 'Файлы';
													|en = 'Files'; fa = 'فایل‌ها';
													|it = 'Files';
													|pl = 'Files';
													|tr = 'Dosyalar'"));
			DataDetails.Insert("SetPresentation", "Files (%1)");
		Else
			DataDetails.Insert("Operation",        NStr("vi = 'Gửi tệp để ký tên';
														|ru = 'Отправка файлов на подписание';
														|en = 'Send file for signing'; fa = 'Send file for signing';
														|it = 'Send file for signing';
														|pl = 'Send file for signing';
														|tr = 'Dosyaları imzalanmaya gönderme'"));
			DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
												|ru = 'Файл';
												|en = 'File'; fa = 'فایل';
												|it = 'File';
												|pl = 'File';
												|tr = 'Dosya'"));
		EndIf;
	
		FileIndex = 0;
		For Each File In AttachedFile Do
			
			DescriptionOfFileData = New Structure;
			
			Presentation = New Structure;
			Presentation.Insert("Value", File);
			Presentation.Insert("FileName", ExecutionParameters.FileData[FileIndex].FileName);
			Presentation.Insert("Presentation", Presentation.FileName);
			
			DescriptionOfFileData.Insert("Presentation", Presentation);
			DescriptionOfFileData.Insert("Data", ExecutionParameters.FileData[FileIndex].RefToBinaryFileData);
			
			If HandlerOnGetSignature = Undefined Then
				DescriptionOfFileData.Insert("Object", File);
			Else
				DescriptionOfFileData.Insert("Object", HandlerOnGetSignature);
			EndIf;
			
			DataSet.Add(DescriptionOfFileData);
			FileIndex = FileIndex + 1;
			
		EndDo;
		
	Else

		DescriptionOfFileData = New Structure;

		Presentation = New Structure;
		Presentation.Insert("Value", AttachedFile);
		Presentation.Insert("FileName", ExecutionParameters.FileData.FileName);
		Presentation.Insert("Presentation", Presentation.FileName);

		DescriptionOfFileData.Insert("Presentation", Presentation);
		DescriptionOfFileData.Insert("Data", ExecutionParameters.FileData.RefToBinaryFileData);
		If HandlerOnGetSignature = Undefined Then
			DescriptionOfFileData.Insert("Object", AttachedFile);
		Else
			DescriptionOfFileData.Insert("Object", HandlerOnGetSignature);
		EndIf;

		DataSet.Add(DescriptionOfFileData);

	EndIf;
	DataDetails.Insert("DataSet", DataSet);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	If SignatureParameters <> Undefined Then
		FillPropertyValues(SigningParameters, SignatureParameters);
	EndIf;
	ModuleDigitalSignatureClient.SendForSigning(DataDetails, FormIdentifier, FollowUpHandler, SigningParameters);
	
EndProcedure

// Completion of the SendFileForSigning procedure.
Procedure AfterSendForSigning(DataDetails, ExecutionParameters) Export
	
	If TypeOf(DataDetails) <> Type("Structure")
		Or Not DataDetails.Property("Success") Then
		
		RunCallback(ExecutionParameters.CompletionHandler, False);
		Return;
	EndIf;
	
	If DataDetails.Success Then
		If TypeOf(ExecutionParameters.AttachedFile) = Type("Array") Then
			
			For Each File In ExecutionParameters.AttachedFile Do
				NotifyChanged(File);
				Notify("Write_File", FileWriteNotificationParameters(), File);
			EndDo;
			
		Else
			NotifyChanged(ExecutionParameters.AttachedFile);
			Notify("Write_File", FileWriteNotificationParameters(), ExecutionParameters.AttachedFile);
		EndIf;
	EndIf;
	
	If ExecutionParameters.CompletionHandler <> Undefined Then
		RunCallback(ExecutionParameters.CompletionHandler, DataDetails.Success);
	EndIf;
	
EndProcedure

Procedure SignFile(AttachedFile, FileData, FormIdentifier,
			CompletionHandler = Undefined, HandlerOnGetSignature = Undefined, SignatureParameters = Undefined) Export
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("AttachedFile",   AttachedFile);
	ExecutionParameters.Insert("FileData",          FileData);
	ExecutionParameters.Insert("FormIdentifier",   FormIdentifier);
	
	FollowUpHandler = New CallbackDescription("AfterAddSignatures", ThisObject, ExecutionParameters);
	If Not CheckSignPossibility(FileData, CompletionHandler, FollowUpHandler, ExecutionParameters) Then
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("ShowComment", True);
	
	SignArrayOfFiles = TypeOf(AttachedFile) = Type("Array");
	
	If SignArrayOfFiles And AttachedFile.Count() > 1 Then
		
		DataDetails.Insert("Operation",            NStr("vi = 'Ký tệp';
														|ru = 'Подписание файлов';
														|en = 'Sign files'; fa = 'Sign files';
														|it = 'Подписание файлов';
														|pl = 'Sign files';
														|tr = 'Dosyanın imzalanması'"));
		DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
												|ru = 'Файлы';
												|en = 'Files'; fa = 'فایل‌ها';
												|it = 'Файлы';
												|pl = 'Files';
												|tr = 'Dosyalar'"));
		
		DataSet = New Array;
		FileIndex = 0;
		For Each File In AttachedFile Do
			
			DescriptionOfFileData = New Structure;
			DescriptionOfFileData.Insert("Presentation", ExecutionParameters.FileData[FileIndex].FileName);
			DescriptionOfFileData.Insert("Data", ExecutionParameters.FileData[FileIndex].RefToBinaryFileData);
			
			If HandlerOnGetSignature = Undefined Then
				DescriptionOfFileData.Insert("Object", File);
			Else
				DescriptionOfFileData.Insert("Object", HandlerOnGetSignature);
			EndIf;
			
			DataSet.Add(DescriptionOfFileData);
			FileIndex = FileIndex + 1;
			
		EndDo;
		
		DataDetails.Insert("DataSet", DataSet);
		DataDetails.Insert("SetPresentation", "Files (%1)");
		
	Else
		
		DataDetails.Insert("Operation",        NStr("vi = 'Ký tên tệp';
													|ru = 'Подписание файла';
													|en = 'Sign a file'; fa = 'Sign a file';
													|it = 'Firma del file';
													|pl = 'Podpisanie pliku';
													|tr = 'Dosya imzalama'"));
		DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
		
		If SignArrayOfFiles Then
			DataDetails.Insert("Presentation", ExecutionParameters.FileData[0].FileName);
			DataDetails.Insert("Data", ExecutionParameters.FileData[0].RefToBinaryFileData);
			If HandlerOnGetSignature = Undefined Then
				DataDetails.Insert("Object", AttachedFile[0]);
			Else
				DataDetails.Insert("Object", HandlerOnGetSignature);
			EndIf;
		Else
			DataDetails.Insert("Presentation", ExecutionParameters.FileData.FileName);
			DataDetails.Insert("Data", ExecutionParameters.FileData.RefToBinaryFileData);
			If HandlerOnGetSignature = Undefined Then
				DataDetails.Insert("Object", AttachedFile);
			Else
				DataDetails.Insert("Object", HandlerOnGetSignature);
			EndIf;
		EndIf;
		
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	SigningParameters = ModuleDigitalSignatureClient.NewSignatureType();
	If SignatureParameters <> Undefined Then
		FillPropertyValues(SigningParameters, SignatureParameters);
	EndIf;
	ModuleDigitalSignatureClient.Sign(DataDetails, FormIdentifier, FollowUpHandler, SigningParameters);
	
EndProcedure

// Finish the SignFile and AddSignatureFromFile procedures.
Procedure AfterAddSignatures(DataDetails, ExecutionParameters) Export
	
	If TypeOf(DataDetails) <> Type("Structure")
		Or Not DataDetails.Property("Success") Then
		
		RunCallback(ExecutionParameters.CompletionHandler, False);
		Return;
	EndIf;
	
	If DataDetails.Success Then
		If TypeOf(ExecutionParameters.AttachedFile) = Type("Array") Then
			
			For Each File In ExecutionParameters.AttachedFile Do
				NotifyChanged(File);
				Notify("Write_File", FileWriteNotificationParameters(), File);
			EndDo;
			
		Else
			NotifyChanged(ExecutionParameters.AttachedFile);
			Notify("Write_File", FileWriteNotificationParameters(), ExecutionParameters.AttachedFile);
		EndIf;
	EndIf;
	
	If ExecutionParameters.CompletionHandler <> Undefined Then
		RunCallback(ExecutionParameters.CompletionHandler, DataDetails.Success);
	EndIf;
	
EndProcedure

// Adds digital signatures to the file in the application from the signature files on the computer.
Procedure AddSignatureFromFile(File, FormIdentifier, CompletionHandler) Export
	
	FileProperties = FilesOperationsInternalServerCall.FileDataAndBinaryData(File, , FormIdentifier);
	FileData = FileProperties.FileData;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("CompletionHandler", CompletionHandler);
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	If Not CheckSignPossibility(ExecutionParameters.FileData,
		CompletionHandler, CompletionHandler, ExecutionParameters) Then
		
		Return;
		
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("Presentation",       FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Data",              FileProperties.BinaryData);
	
	DataDetails.Insert("Object",
		New CallbackDescription("OnGetSignatures", ThisObject, ExecutionParameters));
	
	FollowUpHandler = New CallbackDescription("AfterSignFile",
		ThisObject, ExecutionParameters);
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.AddSignatureFromFile(DataDetails,, FollowUpHandler);
	
EndProcedure

// Continue the AddSignatureFromFile procedure.
// It is called from the DigitalSignature subsystem after preparing signatures from files for non-standard
// way of adding a signature to the object.
//
// Parameters:
//   Context - Structure:
//     * FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure OnGetSignatures(Parameters, Context) Export
	
	FilesOperationsInternalServerCall.AddSignatureToFile(
		Context.FileData.Ref,
		Parameters.DataDetails.Signatures,
		Context.FormIdentifier);
	
	RunCallback(Parameters.Notification, New Structure);
	
EndProcedure

// The AddSignatureFromFile procedure completion.
Procedure AfterSignFile(DataDetails, ExecutionParameters) Export
	
	If TypeOf(DataDetails) <> Type("Structure")
		Or Not DataDetails.Property("Success") Then
		
		RunCallback(ExecutionParameters.CompletionHandler, False);
		Return;
	EndIf;
	
	If DataDetails.Success Then
		NotifyOfFileChange(ExecutionParameters.FileData);
	EndIf;
	
	ReturnResult(ExecutionParameters.CompletionHandler, DataDetails.Success);
	
EndProcedure

// For the AfterSignFile and AfterSignFiles procedures.
Procedure NotifyOfFileChange(FileData)
	
	NotifyChanged(FileData.Ref);
	NotifyChanged(FileData.CurrentVersion);
	
	Notify("Write_File", FileWriteNotificationParameters("AttachedFileSigned"), FileData.Owner);
	
EndProcedure

// Saves file with the digital signature.
Procedure SaveFileWithSignature(File, FormIdentifier) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(File);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileData", FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Object",              ExecutionParameters.FileData.Ref);
	
	DataDetails.Insert("Data",
		New CallbackDescription("OnSaveFileData", ThisObject, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Continue the SaveFileWithSignatures procedure.
// It is called from the DigitalSignature subsystem after selecting signatures to save.
//
Procedure OnSaveFileData(Parameters, Context) Export
	
	AdditionalParameters = New Structure("Notification", Parameters.Notification);
	HandlerNotifications = New CallbackDescription("OnSaveFileDataReturnResult", ThisObject, AdditionalParameters);
	SaveAs(HandlerNotifications, Context.FileData, Context.FormIdentifier);
	
EndProcedure

// Continue the SaveFileWithSignatures procedure.
// It is called from the DigitalSignature subsystem after selecting signatures to save.
//
Procedure OnSaveFileDataReturnResult(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("String") Then
		Result = ?(ValueIsFilled(Result), New Structure("FullFileName", Result), New Structure);
	EndIf;
	RunCallback(AdditionalParameters.Notification, Result);

EndProcedure

Function CheckSignPossibility(FileData, CompletionHandler, HandlerResults_1, ExecutionParameters)
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return False;
	EndIf;
	
	If TypeOf(FileData) = Type("Array") Then
		
		Warnings = New Array;
		For Each File In FileData Do
			If ValueIsFilled(File.BeingEditedBy) Then
				Warnings.Add(FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfLockedFile(File.Ref));
				Continue;
			EndIf;
			
			If File.Encrypted Then
				Warnings.Add(FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfEncryptedFile(File.Ref));
				Continue;
			EndIf;
		EndDo;
		
		If Warnings.Count() > 0 Then
			ReturnResultAfterShowWarning(HandlerResults_1, StrConcat(Warnings, Chars.LF), ExecutionParameters);
			Return False;
		EndIf;
		
	Else
	
		If ValueIsFilled(FileData.BeingEditedBy) Then
			WarningText = FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfLockedFile();
			ReturnResultAfterShowWarning(HandlerResults_1, WarningText, ExecutionParameters);
			Return False;
		EndIf;
		
		If FileData.Encrypted Then
			WarningText = FilesOperationsInternalClientServer.MessageAboutInvalidSigningOfEncryptedFile();
			ReturnResultAfterShowWarning(CompletionHandler, WarningText, ExecutionParameters);
			Return False;
		EndIf;
	
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region ImportFileAndDirTreeFromComputerToApp

// Returns:
//  Structure:
//    * HandlerResults_1      - CallbackDescription - a handler that requires the import result.
//    * Owner                  - DefinedType.AttachedFilesOwner - a folder or an owner object, to which
//                                                                                 the imported files are added.
//    * FilesGroup              - DefinedType.AttachedFile - a group of files, to which
//                                                                       the imported files are added.
//    * SelectedFiles            - ValueList - File objects imported from a computer or other device.
//    * Indicator                 - Number - a number from 0 to 100 is the progress of executing.
//    * Comment               - String - comment.
//    * StoreVersions             - Boolean - store versions.
//    * DeleteFilesAfterImport - Boolean - Delete "SelectedFiles" after import is completed.
//    * Recursively                - Boolean - pass subdirectories recursively.
//    * FormIdentifier        - UUID - a form ID.
//    * PseudoFileSystem     - Map - file system emulation, returns an array of
//                                                 strings (subdirectories and files) for a string (directory).
//    * Encoding                 - String - an encoding for text files.
//    * AddedFiles          - Array - added files, an output parameter.
//
Function FilesImportParameters() Export
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1");
	ExecutionParameters.Insert("Owner");
	ExecutionParameters.Insert("FilesGroup");
	ExecutionParameters.Insert("SelectedFiles");
	ExecutionParameters.Insert("Comment");
	ExecutionParameters.Insert("StoreVersions");
	ExecutionParameters.Insert("DeleteFilesAfterImport");
	ExecutionParameters.Insert("Recursively");
	ExecutionParameters.Insert("FormIdentifier");
	ExecutionParameters.Insert("PseudoFileSystem", New Map);
	ExecutionParameters.Insert("Encoding");
	ExecutionParameters.Insert("AddedFiles", New Array);
	Return ExecutionParameters;
EndFunction

// Recursive file import function. It takes an array of files or directories.
// - If it is a file, it simply adds it. If it is a directory, it creates a group and recursively calls itself.
//
// Parameters:
//  ExecutionParameters   - Structure:
//    * HandlerResults_1      - CallbackDescription
//                                - Structure - a handler that requires
//                                  the import result.
//    * Owner                  - AnyRef - file owner.
//    * SelectedFiles            - Array
//                                - ValueList - File objects.
//    * Indicator                 - Number - a number from 0 to 100 is the progress of executing.
//    * ArrayOfFilesNamesWithErrors - Array - an array of file names with errors.
//    * AllFilesStructureArray  - Array - a structure array of all files.
//    * Comment               - String - comment.
//    * StoreVersions             - Boolean - store versions.
//    * DeleteFilesAfterImport - Boolean - delete SelectedFiles after importing.
//    * Recursively                - Boolean - pass subdirectories recursively.
//    * TotalFilesCount       - Number - total number of imported files.
//    * Counter                   - Number - counter of processed files (file is not necessarily loaded).
//    * FormIdentifier        - UUID - a form ID.
//    * PseudoFileSystem     - Map - file system emulation, returns an array of
//                                                 strings (subdirectories and files) for a string (directory).
//    * AddedFiles          - Array - added files, an output parameter.
//    * AllFoldersArray           - Array - an array of all folders.
//    * Encoding                 - String - an encoding for text files.
//
Procedure ImportFilesRecursively(Owner, SelectedFiles, ExecutionParameters)
	
	InternalParameters = New Structure;
	For Each KeyAndValue In ExecutionParameters Do
		InternalParameters.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	InternalParameters.HandlerResults_1 = ExecutionParameters;
	InternalParameters.Owner = Owner;
	InternalParameters.SelectedFiles = SelectedFiles;
	
	InternalParameters.Insert("FoldersArrayForQuestionWhetherFolderAlreadyExists", New Array);
	ImportFilesRecursivelyWithoutDialogBoxes(InternalParameters.Owner, InternalParameters.SelectedFiles, InternalParameters, True); 
	If InternalParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		// The question is not required.
		ReturnResult(InternalParameters.HandlerResults_1, Undefined);
		Return;
	EndIf;
	
	// When the user answers the questions, write to "ExecutionParameters.SelectedFiles" the folders 
	// from "ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists".
	// Then, recursion is restarted.
	InternalParameters.SelectedFiles = New Array;
	InternalParameters.Insert("FolderToAddToSelectedFiles", Undefined);
	ImportFilesRecursivelySetNextQuestion(InternalParameters);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//  ExecutionParameters - Structure:
//   * SelectedFiles - Array
//   * FolderToAddToSelectedFiles - File
//   * FoldersArrayForQuestionWhetherFolderAlreadyExists - Array
//
Procedure ImportFilesRecursivelySetNextQuestion(ExecutionParameters)
	
	ExecutionParameters.HandlerResults_1 = CompletionHandler(ExecutionParameters.HandlerResults_1);
	ExecutionParameters.FolderToAddToSelectedFiles = ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists[0];
	ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Delete(0);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thư mục ""%1"" đã tồn tại.
		           |Tiếp tục kết nhập thư mục?';
		           |ru = 'Папка ""%1"" уже существует.
		           |Продолжить импорт папки?';
		           |en = 'Folder ""%1"" already exists.
		           |Do you want to continue the upload?'; fa = 'Folder ""%1"" already exists.
		           |Do you want to continue the upload?';
		           |it = 'La cartella ""%1"" esiste già.
		           |Continuare l''importazione della cartella?';
		           |pl = 'Folder ""%1"" już istnieje.
		           |Kontynuować import folderu?';
		           |tr = 'Klasör ""%1"" zaten var. 
		           |Klasörü içe aktarmaya devam etmek istiyor musunuz?'"),
		ExecutionParameters.FolderToAddToSelectedFiles.Name);
	
	Handler = New CallbackDescription("FilesImportRecursivelyAfterRespondQuestion", ThisObject, ExecutionParameters);
	
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

// Continuation of the procedure (see above).
//
// Parameters:
//   ExecutionParameters - Structure:
//     * SelectedFiles - Array
//
Procedure FilesImportRecursivelyAfterRespondQuestion(Response, ExecutionParameters) Export
	
	If Response <> DialogReturnCode.No Then
		ExecutionParameters.SelectedFiles.Add(ExecutionParameters.FolderToAddToSelectedFiles);
	EndIf;
	
	// After responses to all question recursion is restarted.
	If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
		ImportFilesRecursivelyWithoutDialogBoxes(ExecutionParameters.Owner,	ExecutionParameters.SelectedFiles, ExecutionParameters,
			False); // AskQuestionFolderAlreadyExists (used only for the first level of recursion).
		
		If ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Count() = 0 Then
			// There are no more questions.
			ReturnResult(ExecutionParameters.HandlerResults_1, Undefined);
			Return;
		Else
			// There are more questions.
			ExecutionParameters.SelectedFiles = New Array;
		EndIf;
	EndIf;
	
	ImportFilesRecursivelySetNextQuestion(ExecutionParameters);
	
EndProcedure

// Recursive file import function. It takes an array of files or directories.
// - If it is a file, it simply adds it. If it is a directory, it creates a group and recursively calls itself.
//
// Parameters:
//  Owner            - AnyRef - file owner.
//  SelectedFiles      - Array - an array of File objects.
//  ExecutionParameters - See ImportFilesRecursively.ExecutionParameters
//  AskQuestionFolderAlreadyExists - Boolean - True only for the first level of recursion.
//
Procedure ImportFilesRecursivelyWithoutDialogBoxes(Val Owner, Val SelectedFiles, Val ExecutionParameters, Val AskQuestionFolderAlreadyExists)
	
	Var FirstFolderWithSameName;
	
	For Each SelectedFile In SelectedFiles Do
		
		If Not SelectedFile.Exists() Then
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", NStr("vi = 'Đã có tệp trên máy tính.';
										|ru = 'Файл отсутствует на компьютере.';
										|en = 'No file on the computer.'; fa = 'No file on the computer.';
										|it = 'Файл отсутствует на компьютере.';
										|pl = 'No file on the computer.';
										|tr = 'Dosya bilgisayarda yok.'"));
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			Continue;
		EndIf;
		
		Try
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If ExecutionParameters.Recursively = True Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArray = FindFilesPseudo(ExecutionParameters.PseudoFileSystem, NewPath);
					
					// Create a group in the catalog that is the equivalent of a directory on the computer.
					If FilesArray.Count() <> 0 Then
						FileName = SelectedFile.Name;
						
						If FilesOperationsInternalServerCall.HasFolderWithThisName(FileName, ExecutionParameters.FilesGroup, FirstFolderWithSameName) Then
							
							If AskQuestionFolderAlreadyExists Then
								ExecutionParameters.FoldersArrayForQuestionWhetherFolderAlreadyExists.Add(SelectedFile);
								Continue;
							EndIf;
						EndIf;
						
						FilesFolderRef = FilesOperationsInternalServerCall.CreateFilesFolder(FileName, Owner,,ExecutionParameters.FilesGroup);
						If FilesOperationsInternalClientCached.IsDirectoryFiles(FilesFolderRef) Then
							// The parameter "AskQuestionFolderAlreadyExists" prevents asking the user on the 1st recursion level,
							// when it goes through folders for which the positive response was provided.
							ImportFilesRecursivelyWithoutDialogBoxes(FilesFolderRef, FilesArray, ExecutionParameters, True);
						Else
							CurrentFilesGroup = ExecutionParameters.FilesGroup;
							ExecutionParameters.FilesGroup = FilesFolderRef;
							// The parameter "AskQuestionFolderAlreadyExists" prevents asking the user on the 1st recursion level,
							// when it goes through folders for which the positive response was provided.
							ImportFilesRecursivelyWithoutDialogBoxes(Owner, FilesArray, ExecutionParameters, True);
							ExecutionParameters.FilesGroup = CurrentFilesGroup;
						EndIf;
						
						ExecutionParameters.AllFoldersArray.Add(NewPath);
					EndIf;
				EndIf;
				
				Continue;
			EndIf;
			
			If Not CheckCanImportFile(
			          SelectedFile, False, ExecutionParameters.ArrayOfFilesNamesWithErrors) Then
				Continue;
			EndIf;
			
			// Refresh the progress indicator.
			ExecutionParameters.Counter = ExecutionParameters.Counter + 1;
			// Calculate the percentage.
			ExecutionParameters.Indicator = Int(ExecutionParameters.Counter * 100 / ExecutionParameters.TotalFilesCount);
			SizeInMB = SelectedFile.Size() / (1024 * 1024);
			LabelMore = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đang xử lý tệp ""%1""(%2 Mb)...';
					|ru = 'Обрабатывается файл ""%1"" (%2 Мб)...';
					|en = 'Processing file ""%1"" (%2 MB)…'; fa = 'Processing file ""%1"" (%2 MB)…';
					|it = 'Il file ""%1"" sta venendo elaborato (%2 Mb)...';
					|pl = 'Jest przetwarzany plik ""%1""(%2 MB)...';
					|tr = '""%1"" (%2MB) dosyası işleniyor...'"),
				SelectedFile.Name, 
				FilesOperationsInternalClientServer.FileSizePresentation(SizeInMB));
				
			StateText = NStr("vi = 'Kết nhập tệp từ máy tính...';
							|ru = 'Загрузка файлов с компьютера...';
							|en = 'Uploading files from your computer...'; fa = 'Uploading files from your computer...';
							|it = 'Загрузка файлов с компьютера...';
							|pl = 'Uploading files from your computer...';
							|tr = 'Dosyalar bilgisayardan yükleniyor...'");
			
			Status(StateText,
				ExecutionParameters.Indicator,
				LabelMore,
				PictureLib.DialogInformation);
			
			// Create an item of the Files catalog.
			TempFileStorageAddress = "";
			
			Files = New Array;
			LongDesc = New TransferableFileDescription(SelectedFile.FullName, "");
			Files.Add(LongDesc);
			
			PlacedFiles = New Array;			
			If Not PutFiles(Files, PlacedFiles, , False, ExecutionParameters.FormIdentifier) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xếp tệp vào kho chứa tạm thời ""%1"".';
						|ru = 'Не удалось поместить файл во временное хранилище ""%1"".';
						|en = 'Cannot put the file in the ""%1"" temporary storage.'; fa = 'Cannot put the file in the ""%1"" temporary storage.';
						|it = 'Не удалось поместить файл во временное хранилище ""%1"".';
						|pl = 'Cannot put the file in the ""%1"" temporary storage.';
						|tr = '""%1"" zaman aşımındaki dosya yerleştirilemedi.'"),
					SelectedFile.FullName);
			EndIf;
			
			If PlacedFiles.Count() = 1 Then
				TempFileStorageAddress = PlacedFiles[0].Location;
			EndIf;
			
			If Not CommonFilesOperationsSettings().ExtractTextFilesOnServer Then
				TempTextStorageAddress = ExtractTextToTempStorage(SelectedFile.FullName,
					ExecutionParameters.FormIdentifier, , ExecutionParameters.Encoding);
			Else
				TempTextStorageAddress = "";
			EndIf;
			
			// Create an item of the Files catalog.
			ImportFile1(SelectedFile, Owner, ExecutionParameters, TempFileStorageAddress, 
				TempTextStorageAddress);
			If IsTempStorageURL(TempTextStorageAddress) Then
				DeleteFromTempStorage(TempTextStorageAddress);
			EndIf;
				
		Except
			ErrorInfo = ErrorInfo();
			
			ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo);
			CommonClient.MessageToUser(ErrorMessage);
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo),,True);
			
			Record = New Structure;
			Record.Insert("FileName", SelectedFile.FullName);
			Record.Insert("Error", ErrorMessage);
			ExecutionParameters.ArrayOfFilesNamesWithErrors.Add(Record);
			
		EndTry;
	EndDo;
	
EndProcedure

// Parameters:
//
// ExecutionParameters - See ImportFilesRecursively.ExecutionParameters
//
Procedure ImportFile1(Val SelectedFile, Val Owner, Val ExecutionParameters, 
	Val TempFileStorageAddress, Val TempTextStorageAddress) 

	If FilesOperationsInternalClientCached.IsDirectoryFiles(ExecutionParameters.Owner) Then
		
		FileInfo1 = FilesOperationsClientServer.FileInfo1("FileWithVersion", SelectedFile);
		FileInfo1.TempFileStorageAddress = TempFileStorageAddress;
		FileInfo1.TempTextStorageAddress = TempTextStorageAddress;
		FileInfo1.Comment = ExecutionParameters.Comment;
		FileInfo1.Encoding = ExecutionParameters.Encoding;

		FileRef = FilesOperationsInternalServerCall.CreateFileWithVersion(Owner, FileInfo1);
		
	Else
		
		FileParameters = FilesOperationsInternalClientServer.FileAddingOptions();
		FileParameters.FilesOwner = ExecutionParameters.Owner;
		FileParameters.BaseName = SelectedFile.BaseName;
		FileParameters.ExtensionWithoutPoint = CommonClientServer.ExtensionWithoutPoint(SelectedFile.Extension);
		FileParameters.FilesGroup = ExecutionParameters.FilesGroup;
		
		FileRef = FilesOperationsInternalServerCall.AppendFile(FileParameters,
			TempFileStorageAddress, TempTextStorageAddress,ExecutionParameters.Comment);
		
	EndIf;
	
	If ExecutionParameters.Encoding <> Undefined Then
		FilesOperationsInternalServerCall.WriteFileVersionEncoding(FileRef, ExecutionParameters.Encoding); 
	EndIf;
	
	DeleteFromTempStorage(TempFileStorageAddress);
	If Not IsBlankString(TempTextStorageAddress) Then
		DeleteFromTempStorage(TempTextStorageAddress);
	EndIf;
	
	AddedFileAndPath = New Structure("FileRef, Path", FileRef, SelectedFile.Path);
	ExecutionParameters.AddedFiles.Add(AddedFileAndPath);
	
	Record = New Structure;
	Record.Insert("FileName", SelectedFile.FullName);
	Record.Insert("File", FileRef);
	ExecutionParameters.AllFilesStructureArray.Add(Record);

EndProcedure

#EndRegion

#Region OtherPrivate

// When renaming the file, it updates the information in the working directory (the file name on the computer and in the register).
//
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions - file version.
//  NewName       - String - new file name.
//
Procedure RefreshInformationInWorkingDirectory(CurrentVersion, NewName) Export
	
	DirectoryName = UserWorkingDirectory();
	FullFileName = "";	
	InWorkingDirectoryForRead = True;
	InOwnerWorkingDirectory = False;	
	FileInWorkingDirectory = FileInLocalFilesCache(Undefined, CurrentVersion,
		FullFileName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		Return;
	EndIf;
	
	File = New File(FullFileName);
	OnlyName = File.Name;
	FileSize = File.Size();
	PathWithoutName = Left(FullFileName, StrLen(FullFileName) - StrLen(OnlyName));
	NewFullName = PathWithoutName + NewName + File.Extension;
	MoveFile(FullFileName, NewFullName);
	
	FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion,
		NewFullName, DirectoryName, InWorkingDirectoryForRead, FileSize, InOwnerWorkingDirectory);
	
EndProcedure

// Re-register in the working directory with the ForReading flag (if the file exists there).
// 
// Parameters:
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  ForReading - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure ReregisterFileInWorkingDirectory(FileData, ForReading, InOwnerWorkingDirectory)
	
	If FileData.Version.IsEmpty() Then 
		Return;
	EndIf;

	FullFileName = "";	
	InWorkingDirectoryForRead = True;
	FileInWorkingDirectory = FileInLocalFilesCache(FileData, FileData.CurrentVersion, FullFileName, 
		InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	If Not FileInWorkingDirectory Then
		Return;
	EndIf;
	
	DirectoryName = UserWorkingDirectory();
	FilesOperationsInternalServerCall.PutFileInformationInRegister(FileData.CurrentVersion, FullFileName, 
		DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// The function is designed to open file using the corresponding application.
//
// Parameters:
//  FileData  - See FilesOperationsInternalServerCall.FileData
//  FileToOpenName - String - a full file name.
//  OwnerID - UUID - a form owner ID.
//
Procedure OpenFileWithApplication(FileData, FileToOpenName, OwnerID = Undefined)
	
	If Not Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
		
	PersonalFilesOperationsSettings = PersonalFilesOperationsSettings();
	
	TextFilesOpeningMethod = PersonalFilesOperationsSettings.TextFilesOpeningMethod;
	If TextFilesOpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		TextFilesExtension = PersonalFilesOperationsSettings.TextFilesExtension;
		If FilesOperationsInternalClientServer.FileExtensionInList(TextFilesExtension, FileData.Extension) Then
			
			FormParameters = New Structure;
			FormParameters.Insert("File", FileData.Ref);
			FormParameters.Insert("FileData", FileData);
			FormParameters.Insert("FileToOpenName", FileToOpenName);
			FormParameters.Insert("OwnerID", OwnerID);
			
			OpenForm("DataProcessor.FilesOperations.Form.EditTextFile", 
				FormParameters, , FileData.Ref);
			Return;
			
		EndIf;
		
	EndIf;
	
#If Not MobileClient Then
	If Lower(FileData.Extension) = Lower("grs") Then
		
		Schema = New GraphicalSchema; 
		Schema.Read(FileToOpenName);
		
		FormCaption = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		
		Schema.Show(FormCaption, FileToOpenName);
		Return;
		
	EndIf;
#EndIf
	
	If Lower(FileData.Extension) = Lower("mxl") Then
		
		Files = New Array;
		Files.Add(New TransferableFileDescription(FileToOpenName));
		PlacedFiles = New Array;
		If Not PutFiles(Files, PlacedFiles, , False) Then
			Return;
		EndIf;
		SpreadsheetDocument = PlacedFiles[0].Location;
		
		FormParameters = StandardSubsystemsClient.SpreadsheetEditorParameters();
		FormParameters.DocumentName = CommonClientServer.GetNameWithExtension(
			FileData.FullVersionDescription, FileData.Extension);
		FormParameters.PathToFile = FileToOpenName;
		If Not FileData.ForReading Then
			FormParameters.Insert("AttachedFile", FileData.Ref);
		EndIf;
		StandardSubsystemsClient.ShowSpreadsheetEditor(SpreadsheetDocument, FormParameters);
		
		Return;
		
	EndIf;
	
	// Open  a file.
	FileSystemClient.OpenFile(FileToOpenName);
	
EndProcedure

// Returns parameters to work with locked files.
// Returns:
//	Undefined - if there is no files being edited or you do not need to work with them.
//	Structure - a structure with passed parameters.
// 
Function CheckLockedFilesOnExit()
	
	If UsersClient.IsExternalUserSession() Then
		Return Undefined;
	EndIf;
	
	PersonalFilesOperationsSettings = StandardSubsystemsClient.ClientParameter("PersonalFilesOperationsSettings");
	ShowLockedFilesOnExit = PersonalFilesOperationsSettings.ShowLockedFilesOnExit;
	
	If Not ShowLockedFilesOnExit Then
		Return Undefined;
	EndIf;
	
	LockedFilesCount = LockedFilesCount();
	If Not LockedFilesCount > 0 Then
		Return Undefined;
	EndIf;
	
	CurrentUser = UsersClient.AuthorizedUser();
	
	ApplicationWarningFormParameters = New Structure;
	ApplicationWarningFormParameters.Insert("MessageQuestion",      NStr("vi = 'Kết thúc làm việc với ứng dụng?';
																		|ru = 'Завершить работу с приложением?';
																		|en = 'Exit the application?'; fa = 'Exit the application?';
																		|it = 'Завершить работу с приложением?';
																		|pl = 'Exit the application?';
																		|tr = 'Uygulamadan çıkılsın mı?'"));
	ApplicationWarningFormParameters.Insert("MessageTitle",   NStr("vi = 'Tệp tiếp theo bị chiếm để soạn:';
																	|ru = 'Следующие файлы заняты для редактирования:';
																	|en = 'The following files are locked:'; fa = 'The following files are locked:';
																	|it = 'I seguenti file sono in corso di modifica:';
																	|pl = 'Następujące pliki są zajęte dla edycji:';
																	|tr = 'Aşağıdaki dosyalar düzenleme için kullanılıyor:'"));
	ApplicationWarningFormParameters.Insert("Title",            NStr("vi = 'Kết thúc công việc';
																	|ru = 'Завершение работы';
																	|en = 'Exit application'; fa = 'خروج از برنامه';
																	|it = 'Fine del lavoro';
																	|pl = 'Zakończenie pracy';
																	|tr = 'Uygulamadan çık'"));
	ApplicationWarningFormParameters.Insert("BeingEditedBy",          CurrentUser);
	
	ApplicationWarningForm = "DataProcessor.FilesOperations.Form.LockedFilesListWithQuestion";
	Form                         = "DataProcessor.FilesOperations.Form.FilesToEdit";
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("ApplicationWarningFormParameters", ApplicationWarningFormParameters);
	ReturnParameters.Insert("Form", Form);
	ReturnParameters.Insert("ApplicationWarningForm", ApplicationWarningForm);
	ReturnParameters.Insert("LockedFilesCount", LockedFilesCount);
	
	Return ReturnParameters;
	
EndFunction

// Returns the value of the LockedFilesCount client parameter.
//
Function LockedFilesCount()
	
	Return StandardSubsystemsClient.ClientParameter("LockedFilesCount");
	
EndFunction

// Changes the value of the LockedFilesCount client parameter.
//
Procedure ChangeLockedFilesCount(ChangeValue = -1) Export
	
	StandardSubsystemsClient.SetClientParameter(
		"LockedFilesCount", LockedFilesCount() + ChangeValue);
	
EndProcedure

// Returns:
//   Structure:
//     * Path - String
//     * Size - Number
//     * Version - DefinedType.AttachedFile
//     * PutFileInWorkingDirectoryDate - Date
//
Function FilesInWorkingDirectoryData()
	
	Return New Structure("Path, Size, Version, PutFileInWorkingDirectoryDate");
	
EndFunction

// Passing files in working directory recursively and collecting information about them.
//
// Parameters:
//  Path - String - a working directory path.
//  FilesArray - Array of DefinedType.AttachedFile
//  TableOfFiles - Array of See FilesInWorkingDirectoryData - Files to be deleted.
//
Procedure ProcessFilesTable(Val Path, Val FilesArray, Val TableOfFiles)
	
#If Not WebClient Then

	DirectoryName = UserWorkingDirectory();
	FilesToAnalize = New Array;
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.IsDirectory() Then
			NewPath = String(Path);
			NewPath = NewPath + GetPathSeparator();
			NewPath = NewPath + String(SelectedFile.Name);
			FilesArrayInDirectory = FindFiles(NewPath, GetAllFilesMask());
			
			If FilesArrayInDirectory.Count() <> 0 Then
				ProcessFilesTable(NewPath, FilesArrayInDirectory, TableOfFiles);
			EndIf;
		
			Continue;
		EndIf;
		
		// Do not delete Word temporary files from the working directory.
		If StrStartsWith(SelectedFile.Name, "~") And SelectedFile.GetHidden() Then
			Continue;
		EndIf;
		
		RelativePath = Mid(SelectedFile.FullName, StrLen(DirectoryName) + 1);
		FilesToAnalize.Add(RelativePath);
	EndDo;
	
	FilesInfo = FilesOperationsInternalServerCall.FilesInfoInWorkingDir(FilesToAnalize);
	For Each FileInfoKey In FilesInfo Do
		RelativePath = FileInfoKey.Key;
		FileInfo1 = FileInfoKey.Value;
		// The minimal data is considered the oldest if not found on the computer.
		// It will be deleted when cleaning up the oldest files from the working directory.
		PutFileDate = ?(FileInfo1.FileIsInRegister, FileInfo1.PutFileDate, Date('00010101'));
		
		// If it is not locked by the current user, you can delete it.
		If Not FileInfo1.FileIsInRegister 
			Or FileInfo1.FileIsInRegister And Not FileInfo1.EditedByCurrentUser Then
			Record = FilesInWorkingDirectoryData();
			Record.Path = RelativePath;
			Try
				Record.Size = SelectedFile.Size();
			Except
				Record.Size = 0;
			EndTry;
			Record.Version = FileInfo1.File;
			Record.PutFileInWorkingDirectoryDate = PutFileDate;
			TableOfFiles.Add(Record);
		EndIf;
	EndDo;
	
#EndIf
	
EndProcedure

// Receives a relative path to a file in the working directory. If the information register has the path, it is taken from there.
// Otherwise, it is generated and recorded to the information register.
//
// Parameters:
//  FileData  - Structure
//
// Returns:
//   String
//
Function GetFilePathInWorkingDirectory(FileData)
	
	PathToReturn = "";
	FullFileName = "";
	DirectoryName = UserWorkingDirectory();
	
	FullFileName = FileData.FullFileNameInWorkingDirectory;
	
	If FullFileName <> "" Then
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exists() Then
			Return FullFileName;
		EndIf;
	EndIf;
	
	FileName = FileData.FullVersionDescription;
	Extension = FileData.Extension;
	If Not IsBlankString(Extension) Then 
		FileName = CommonClientServer.GetNameWithExtension(FileName, Extension);
	EndIf;
	
	CommonInternalClient.ShortenFileName(FileName);
	
	FullFileName = "";
	If Not IsBlankString(FileName) Then
		If Not IsBlankString(FileData.OwnerWorkingDirectory) Then
			FullFileName = FileData.OwnerWorkingDirectory + FileData.FullVersionDescription + "." + FileData.Extension;
		Else
			FullFileName = FilesOperationsInternalClientServer.UniqueNameByWay(DirectoryName, FileName);
		EndIf;
	EndIf;
	
	If IsBlankString(FileName) Then
		Return "";
	EndIf;
	
	// Writing file name to the register.
	ForReading = True;
	InOwnerWorkingDirectory = FileData.OwnerWorkingDirectory <> "";
	FilesOperationsInternalServerCall.WriteFullFileNameToRegister(FileData.Version, FullFileName, ForReading, InOwnerWorkingDirectory);
	
	If FileData.OwnerWorkingDirectory = "" Then
		PathToReturn = DirectoryName + FullFileName;
	Else
		PathToReturn = FullFileName;
	EndIf;
	
	Return PathToReturn;
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Returns:
//   See FilesOperations.FilesOperationSettings
//
Function PersonalFilesOperationsSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().PersonalFilesOperationsSettings;
	
EndFunction

// Returns a structure that contains various personal settings.
Function CommonFilesOperationsSettings()
	
	CommonSettings = StandardSubsystemsClient.ClientRunParameters().CommonFilesOperationsSettings;
	
	// Verify and update the settings that are saved on the server
	// and that are calculated on the client.
	
	Return CommonSettings;
	
EndFunction

// Parameters:
//  FileData - See FilesOperationsInternalServerCall.FileData
//  CurrentVersion  - CatalogRef.FilesVersions
//  FullFileName - String - File name together with its path.
//  InWorkingDirectoryForRead - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
// Returns:
//  Boolean
//
Function FileInLocalFilesCache(FileData, CurrentVersion, FullFileName, InWorkingDirectoryForRead, 
	InOwnerWorkingDirectory)
	
	FullFileName = "";
	
	// If it is an active version, take it from the FileData.
	If FileData <> Undefined And FileData.CurrentVersion = CurrentVersion Then
		FullFileName = FileData.FullFileNameInWorkingDirectory;
		InWorkingDirectoryForRead = FileData.InWorkingDirectoryForRead;
	Else
		InWorkingDirectoryForRead = True;
		DirectoryName = UserWorkingDirectory();
		FullFileName = FilesOperationsInternalServerCall.FullFileNameInWorkingDirectory(CurrentVersion, 
			DirectoryName, InWorkingDirectoryForRead, InOwnerWorkingDirectory);
	EndIf;
	
	If FullFileName <> "" Then
		FileOnHardDrive = New File(FullFileName);
		If FileOnHardDrive.Exists() Then
			Return True;
		Else
			FullFileName = "";
			FilesOperationsInternalServerCall.DeleteFromRegister(CurrentVersion);
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Select a path to the working directory.
// Parameters:
//  DirectoryName  - String - the directory previous name.
//  Title  - String - a title of the form of directory path selection.
//  OwnerWorkingDirectory - String-  working directory of the owner.
//
// Returns:
//   Boolean  - Shows whether the operation is performed successfully.
//
Function ChoosePathToWorkingDirectory(DirectoryName, Title, OwnerWorkingDirectory) Export
	
	Mode = FileDialogMode.ChooseDirectory;
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Directory = DirectoryName;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = Title;
	
	If OpenFileDialog.Choose() Then
		
		DirectoryName = OpenFileDialog.Directory;
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
		
		// Create a directory for files
		Try
			CreateDirectory(DirectoryName);
			TestDirectoryName = DirectoryName + "CheckAccess\";
			CreateDirectory(TestDirectoryName);
			DeleteFiles(TestDirectoryName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);

			// Insufficient rights to create a directory, or this path does not exist.
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đường dẫn không hợp lệ hoặc thiếu quyền ghi vào thư mục
				           |""%1"".';
				           |ru = 'Неверный путь или отсутствуют права на запись в каталог
				           |""%1"".';
				           |en = 'Error writing to directory ""%1"".
				           |Invalid path or insufficient permissions.'; fa = 'Error writing to directory ""%1"".
				           |Invalid path or insufficient permissions.';
				           |it = 'Percorso incorretto oppure sono assenti i permessi di scrittura nella directory
				           |""%1"".';
				           |pl = 'Nieprawidłowa ścieżka lub brak prawa do zapisu w katalogu
				           |""%1"".';
				           |tr = '""%1"" 
				           |dizinine yazmak için yanlış yol veya yetersiz haklar.'"),
				DirectoryName);
			ShowMessageBox(, ErrorText);
			Return False;
		EndTry;
		
		If OwnerWorkingDirectory = False Then
#If Not WebClient Then
			FilesArrayInDirectory = FindFiles(DirectoryName, GetAllFilesMask());
			If FilesArrayInDirectory.Count() <> 0 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong thư mục làm việc đã chọn
					           |""%1""
					           |đã có tệp.
					           |
					           |Chọn thư mục khác.';
					           |ru = 'В выбранном рабочем каталоге
					           |""%1""
					           |уже есть файлы.
					           |
					           |Выберите другой каталог.';
					           |en = 'The selected working directory 
					           |""%1""
					           |contains files.
					           |
					           |Please select another directory.'; fa = 'The selected working directory 
					           |""%1""
					           |contains files.
					           |
					           |Please select another directory.';
					           |it = 'Nella directory di lavoro selezionata
					           |""%1""
					           |sono già presenti i file.
					           |
					           |Selezionate un''altra directory.';
					           |pl = 'W wybranym katalogu roboczym
					           |""%1""
					           |są już pliki.
					           |
					           |Wybierz inny katalog.';
					           |tr = 'Seçilen çalışma dizininde %1 ""
					           |""
					           | zaten dosyalar var. 
					           |
					           |Başka bir dizin seçin.'"),
					DirectoryName);
				ShowMessageBox(, ErrorText);
				Return False;
			EndIf;
#EndIf
		EndIf;
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Reregister it In working directory with another ForReading flag.
// Parameters:
//  CurrentVersion  - CatalogRef.FilesVersions - file version.
//  FullFileName - String - a full file name.
//  ForReading - Boolean - a file is placed for reading.
//  InOwnerWorkingDirectory - Boolean - a file is in owner working directory (not in the main working directory).
//
Procedure RegegisterInWorkingDirectory(CurrentVersion, FullFileName, ForReading, InOwnerWorkingDirectory)
	
	DirectoryName = UserWorkingDirectory();
	
	FilesOperationsInternalServerCall.PutFileInformationInRegister(CurrentVersion, FullFileName, DirectoryName, ForReading, 0, InOwnerWorkingDirectory);
	File = New File(FullFileName);
	File.SetReadOnly(ForReading);
	
EndProcedure

// Passing files in working directory recursively to determine the size of files.
// Parameters:
//  FilesArray - Array - an array of "File" objects.
//  ArrayOfTooBigFiles - Array - an array of files.
//  Recursively - Boolean - pass subdirectories recursively.
//  TotalFilesCount - Number - total number of imported files.
//  PseudoFileSystem - Map - file system emulation, returns an array of strings
//                                         (subdirectories and files) for a string (directory).
//
Procedure FindTooBigFiles(
				FilesArray,
				ArrayOfTooBigFiles,
				Recursively,
				TotalFilesCount,
				Val PseudoFileSystem) 
	
	MaxFileSize1 = CommonFilesOperationsSettings().MaxFileSize;
	
	For Each SelectedFile In FilesArray Do
		
		If SelectedFile.Exists() Then
			
			If SelectedFile.Extension = ".lnk" Then
				SelectedFile = DereferenceLnkFile(SelectedFile);
			EndIf;
			
			If SelectedFile.IsDirectory() Then
				
				If Recursively Then
					NewPath = String(SelectedFile.Path);
					NewPath = CommonClientServer.AddLastPathSeparator(NewPath);
					NewPath = NewPath + String(SelectedFile.Name);
					FilesArrayInDirectory = FindFilesPseudo(PseudoFileSystem, NewPath);
					
					// Recursion.
					If FilesArrayInDirectory.Count() <> 0 Then
						FindTooBigFiles(FilesArrayInDirectory, ArrayOfTooBigFiles, Recursively, TotalFilesCount, PseudoFileSystem);
					EndIf;
				EndIf;
			
				Continue;
			EndIf;
			
			TotalFilesCount = TotalFilesCount + 1;
			
			// A file size is too big.
			If SelectedFile.Size() > MaxFileSize1 Then
				ArrayOfTooBigFiles.Add(SelectedFile.FullName);
				Continue;
			EndIf;
		
		EndIf;
	EndDo;
	
EndProcedure

// Returns an array of files, emulating the work of FindFiles, not by file system, but by Map.
//  If PseudoFileSystem is blank, it works with the file system.
//
Function FindFilesPseudo(Val PseudoFileSystem, Path)
	
	If PseudoFileSystem.Count() = 0 Then
		Files = FindFiles(Path, GetAllFilesMask());
		Return Files;
	EndIf;
	
	Files = New Array;
	
	ValueFound1 = PseudoFileSystem.Get(String(Path));
	If ValueFound1 <> Undefined Then
		For Each FileName In ValueFound1 Do
			FileFromList = New File(FileName);
			Files.Add(FileFromList);
		EndDo;
	EndIf;
	
	Return Files;
	
EndFunction

// Dereference the lnk file
// Parameters:
//  SelectedFile - File - object of the File type.
//
// Returns:
//   String - what the lnk file refers to.
//
Function DereferenceLnkFile(SelectedFile)
	
#If Not WebClient And Not MobileClient Then
	ShellApplication = New COMObject("shell.application");
	FullPath = ShellApplication.NameSpace(SelectedFile.Path);// Path to the LNK file (without the filename).
	FileName = FullPath.items().item(SelectedFile.Name); // The name of the LNK file
	Ref = FileName.GetLink();
	Return New File(Ref.path);
#EndIf
	
	Return SelectedFile;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Compare versions and files.
// Compares 2 files (TXT, DOC, DOC, ODT, MXL) using Microsoft Office or OpenOffice from 1C:Enterprise script for spreadsheet documents.
//
Procedure CompareFiles(FormIdentifier, FirstFile, SecondFile, Extension, VersionOwner = Undefined) Export
	
	FileVersionsComparisonMethod = Undefined;
	
	ExtensionSupported = (
		Extension = "txt"
		Or Extension = "md"
		Or Extension = "doc"
		Or Extension = "docx"
		Or Extension = "rtf"
		Or Extension = "htm"
		Or Extension = "html"
		Or Extension = "mxl"
		Or Extension = "odt");
	
	If Not ExtensionSupported Then
		WarningText =
		NStr("vi = 'Chỉ có thể so sánh tệp có các kiểu sau:
			|   Văn bản thuần (.txt, .md)
			|   Văn bản có định dạng RTF (.rtf)
			|   Văn bản Microsoft Word (.doc, .docx)
			|   Văn bản HTML (.html, .htm)
			|   Văn bản dạng bảng (.mxl)
			|   Văn bản thuần OpenDocument (.odt)';
			|ru = 'Сравнение файлов возможно только для следующих типов:
			|   Текстовый документ (.txt, .md)
			|   Документ формата RTF (.rtf)
			|   Документ Microsoft Word (.doc, .docx)
			|   Документ HTML (.html, .htm)
			|   Табличный документ (.mxl)
			|   Текстовый документ OpenDocument (.odt)';
			|en = 'File comparison supports only the following formats:
			|   Text document (.txt, .md)
			|   RTF document (.rtf)
			|   Microsoft Word document (.doc, .docx)
			|   HTML document (.html, .htm)
			|   Spreadsheet document (.mxl)
			|   OpenDocument text document (.odt)'; fa = 'File comparison supports only the following formats:
			|   Text document (.txt, .md)
			|   RTF document (.rtf)
			|   Microsoft Word document (.doc, .docx)
			|   HTML document (.html, .htm)
			|   Spreadsheet document (.mxl)
			|   OpenDocument text document (.odt)';
			|it = 'Il confronto dei file è supportato solo per i seguenti tipi di file:
			|   Documento di testo (.txt, md)
			|   Documento formato RTF (.rtf)
			|   Documento Microsoft Word (.doc, .docx)
			|   Documento HTML (.html .htm)
			|   Documento tabellare (.mxl)
			|   Documento di testo OpenDocument ( .odt)';
			|pl = 'Porównywanie plików jest możliwe tylko dla następujących typów:
			| Dokument tekstowy (.txt)
			| Dokument w formacie RTF (.rtf) 
			|Dokument Microsoft Word (.doc, .docx)
			| Dokument HTML (.html .htm) 
			|Dokument tabelaryczny (.mxl) 
			|Dokument tekstowy OpenDocument (.odt)';
			|tr = 'Dosya karşılaştırması yalnızca aşağıdaki türdeki dosyalar için destekleniyor:
			|   Metin belgesi (.txt, .md)
			|   RTF belge (.rtf)
			|   Microsoft Word Belgesi (.doc, .docx)
			|   HTML Belgesi (.html, .htm)
			|   Tablo Belgesi (.mxl)
			|   OpenDocument Metin Belgesi (.odt)'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Extension = "odt" Then
		FileVersionsComparisonMethod = "OpenOfficeOrgWriter";
	ElsIf Extension = "htm" Or Extension = "html" Then
		FileVersionsComparisonMethod = "MicrosoftOfficeWord";
	ElsIf Extension = "mxl" Then
		FileVersionsComparisonMethod = "CompareSpreadsheetDocuments";
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileVersionsComparisonMethod", FileVersionsComparisonMethod);
	ExecutionParameters.Insert("CurrentStep",              "Step1ChooseVersionComparisonMethod");
	ExecutionParameters.Insert("FileData1",            Undefined);
	ExecutionParameters.Insert("FileData2",            Undefined);
	ExecutionParameters.Insert("Result1",              Undefined);
	ExecutionParameters.Insert("Result2",              Undefined);
	ExecutionParameters.Insert("FullFileName1",         "");
	ExecutionParameters.Insert("FullFileName2",         "");
	ExecutionParameters.Insert("UUID", FormIdentifier);
	ExecutionParameters.Insert("Ref1",                 FirstFile);
	ExecutionParameters.Insert("Ref2",                 SecondFile);
	ExecutionParameters.Insert("VersionOwner",          VersionOwner);
	CompareFilesInternal(ExecutionParameters);
	
EndProcedure

Procedure CompareFilesInternal(ExecutionParameters)
	
	If ExecutionParameters.CurrentStep = "Step1ChooseVersionComparisonMethod" Then
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			PersonalSettings = PersonalFilesOperationsSettings();
			ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
			If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
				Handler = New CallbackDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
				OpenForm("DataProcessor.FilesOperations.Form.SelectVersionCompareMethod",, ThisObject,,,, Handler);
				Return;
			EndIf;
		EndIf;
		ExecutionParameters.CurrentStep = "Step2GetDataFiles";
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step2GetDataFiles" Then
		
		If ExecutionParameters.Property("VersionOwner") And ValueIsFilled(ExecutionParameters.VersionOwner) Then
			ExecutionParameters.FileData1 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner, ExecutionParameters.Ref1, ExecutionParameters.UUID);
			ExecutionParameters.FileData2 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.VersionOwner, ExecutionParameters.Ref2, ExecutionParameters.UUID);
		Else
			ExecutionParameters.FileData1 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref1, Undefined, ExecutionParameters.UUID);
			ExecutionParameters.FileData2 = FilesOperationsInternalServerCall.FileDataToOpen(
				ExecutionParameters.Ref2, Undefined, ExecutionParameters.UUID);
		EndIf;
		
		ExecutionParameters.CurrentStep = "Step3GetFirstFile";
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step3GetFirstFile" Then
		Handler = New CallbackDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData1, 
			ExecutionParameters.FullFileName1);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step4GetSecondFile" Then
		Handler = New CallbackDescription("CompareFilesProcessingResult", ThisObject, ExecutionParameters);
		GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData2, 
			ExecutionParameters.FullFileName2);
		Return;
	EndIf;
	
	If ExecutionParameters.CurrentStep = "Step5CompareFiles" Then
		If Not ExecutionParameters.Result1 Or Not ExecutionParameters.Result2 Then
			Return;
		EndIf;	
		
		FileHeaderTemplate = NStr("vi = '%1 (phiên bản số %2)';
									|ru = '%1 (версия № %2)';
									|en = '%1 (version # %2)'; fa = '%1 (version # %2)';
									|it = '%1 (versione №%2)';
									|pl = '%1 (wersja nr %2)';
									|tr = '%1 (sürüm No %2)'");
		FirstFileData = ExecutionParameters.FileData1; // See FilesOperationsInternalServerCall.FileData
		FileName1 = CommonClientServer.GetNameWithExtension(FirstFileData.FullVersionDescription,
			FirstFileData.Extension);
		FileTitle1 = StringFunctionsClientServer.SubstituteParametersToString(FileHeaderTemplate,
			FileName1, ExecutionParameters.FileData1.VersionNumber);
			
		SecondFileData = ExecutionParameters.FileData2; // See FilesOperationsInternalServerCall.FileData
		FileName2 = CommonClientServer.GetNameWithExtension(SecondFileData.FullVersionDescription,
			SecondFileData.Extension);
		FileTitle2 = StringFunctionsClientServer.SubstituteParametersToString(FileHeaderTemplate,
			FileName2, ExecutionParameters.FileData2.VersionNumber);
			
		If ExecutionParameters.FileData1.VersionNumber < ExecutionParameters.FileData2.VersionNumber Then
			FullFileNameLeft  = ExecutionParameters.FullFileName1;
			FileHeaderLeft  = FileTitle1;
			FullFileNameRight = ExecutionParameters.FullFileName2;
			FileHeaderRight = FileTitle2;
		Else
			FullFileNameLeft  = ExecutionParameters.FullFileName2;
			FileHeaderLeft  = FileTitle2;
			FullFileNameRight = ExecutionParameters.FullFileName1;
			FileHeaderRight = FileTitle1;
		EndIf;
			
		ExecuteCompareFiles(FullFileNameLeft, FullFileNameRight,
			ExecutionParameters.FileVersionsComparisonMethod,
			FileHeaderLeft, FileHeaderRight);
	EndIf;
	
EndProcedure

Procedure CompareFilesProcessingResult(Result, ExecutionParameters) Export

	If ExecutionParameters.CurrentStep = "Step1ChooseVersionComparisonMethod" Then
		If Result <> DialogReturnCode.OK Then
			Return;
		EndIf;
		
		PersonalSettings = PersonalFilesOperationsSettings();
		ExecutionParameters.FileVersionsComparisonMethod = PersonalSettings.FileVersionsComparisonMethod;
		If ExecutionParameters.FileVersionsComparisonMethod = Undefined Then
			Return;
		EndIf;
		ExecutionParameters.CurrentStep = "Step2GetDataFiles";
		
	ElsIf ExecutionParameters.CurrentStep = "Step3GetFirstFile" Then
		ExecutionParameters.Result1      = Result.FileReceived;
		ExecutionParameters.FullFileName1 = Result.FullFileName;
		ExecutionParameters.CurrentStep = "Step4GetSecondFile";
		
	ElsIf ExecutionParameters.CurrentStep = "Step4GetSecondFile" Then
		ExecutionParameters.Result2      = Result.FileReceived;
		ExecutionParameters.FullFileName2 = Result.FullFileName;
		ExecutionParameters.CurrentStep = "Step5CompareFiles";
	EndIf;
	
	CompareFilesInternal(ExecutionParameters);

EndProcedure

Procedure ExecuteCompareFiles(PathToFile1, PathToFile2, FileVersionsComparisonMethod, TitleLeft = "", TitleRight = "") Export
	
	Try
		If FileVersionsComparisonMethod = "MicrosoftOfficeWord" Then
			CompareMicrosoftWordFiles(PathToFile1, PathToFile2);
		ElsIf FileVersionsComparisonMethod = "OpenOfficeOrgWriter" Then 
			CompareOpenOfficeOrgWriterFiles(PathToFile1, PathToFile2);
		ElsIf FileVersionsComparisonMethod = "CompareSpreadsheetDocuments" Then
			CompareSpreadsheetDocuments1(PathToFile1, PathToFile2, TitleLeft, TitleRight);
		EndIf;
		
	Except
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể so sánh các tệp do nguyên nhân: %1';
				|ru = 'Не удалось сравнить файлы по причине: %1';
				|en = 'Cannot compare the files. Reason: %1'; fa = 'Cannot compare the files. Reason: %1';
				|it = 'Non è stato possibile confrontare i file a causa di: %1';
				|pl = 'Nie można porównać plików z powodu: %1';
				|tr = 'Dosyalar şu sebeple karşılaştırılamadı: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Tệp.So sánh tệp';
				|ru = 'Файлы.Сравнение файлов';
				|en = 'Files.Compare files'; fa = 'Files.Compare files';
				|it = 'File.Confronto file';
				|pl = 'Pliki.Porównianie plików';
				|tr = 'Dosyalar.Dosya karşılaştırılması'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorMessage, , True);
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

Procedure CompareOpenOfficeOrgWriterFiles(Val PathToFile1, Val PathToFile2)
	
#If Not WebClient And Not MobileClient Then
	
	// Removing readonly, otherwise, it will not work.
	File1 = New File(PathToFile1);
	File1.SetReadOnly(False);
	
	File2 = New File(PathToFile2);
	File2.SetReadOnly(False);
	
	// Open OpenOffice.
	Try
		ServiceManagerObject = New COMObject("com.sun.star.ServiceManager");
		DesktopObject = ServiceManagerObject.createInstance("com.sun.star.frame.Desktop");
		DispatcherHelperObject = ServiceManagerObject.createInstance("com.sun.star.frame.DispatchHelper");
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Tệp.So sánh tệp';
				|ru = 'Файлы.Сравнение файлов';
				|en = 'Files.Compare files'; fa = 'Files.Compare files';
				|it = 'File.Confronto file';
				|pl = 'Pliki.Porównianie plików';
				|tr = 'Dosyalar.Dosya karşılaştırılması'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo()) + Chars.LF 
			+ NStr("vi = 'Hãy cài đặt (cài đặt lại) ứng dụng OpenOffice.org Writer.';
					|ru = 'Установите (переустановите) приложение OpenOffice.org Writer.';
					|en = 'Install or reinstall OpenOffice.org Writer.'; fa = 'Install or reinstall OpenOffice.org Writer.';
					|it = 'Installare (reinstallare) l''applicazione OpenOffice.org Writer.';
					|pl = 'Zainstaluj (ponownie zainstaluj) aplikację OpenOffice.org Writer.';
					|tr = 'OpenOffice.org Writer uygulamasını yükleyin (yeniden yükleyin).'");
	EndTry;	
	
	// Opening parameters: disabling macros.
	DocumentParameters = New COMSafeArray("VT_VARIANT", 1);
	RunMode = AssignValueToProperty(ServiceManagerObject,
		"MacroExecutionMode",
		0); // const short NEVER_EXECUTE = 0
	DocumentParameters.SetValue(0, RunMode);
	
	// Open OpenOffice document.
	DesktopObject.loadComponentFromURL(ConvertToURL(PathToFile2), "_blank", 0, DocumentParameters);
	
	CurrentWindow = DesktopObject.getCurrentFrame();
	
	// Set showing changes.
	CompareParameters = New COMSafeArray("VT_VARIANT", 1);
	CompareParameters.SetValue(0, AssignValueToProperty(ServiceManagerObject, "ShowTrackedChanges", True));
	DispatcherHelperObject.executeDispatch(CurrentWindow, ".uno:ShowTrackedChanges", "", 0, CompareParameters);
	
	// Compare with the document.
	CallParameters = New COMSafeArray("VT_VARIANT", 1);
	CallParameters.SetValue(0, AssignValueToProperty(ServiceManagerObject, "URL", ConvertToURL(PathToFile1)));
	DispatcherHelperObject.executeDispatch(CurrentWindow, ".uno:CompareDocuments", "", 0, CallParameters);

#EndIf

EndProcedure

Procedure CompareMicrosoftWordFiles(PathToFile1, PathToFile2)
	
#If Not WebClient And Not MobileClient Then
	
	Try
		WordObject = New COMObject("Word.Application");
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Tệp.So sánh tệp';
				|ru = 'Файлы.Сравнение файлов';
				|en = 'Files.Compare files'; fa = 'Files.Compare files';
				|it = 'File.Confronto file';
				|pl = 'Pliki.Porównianie plików';
				|tr = 'Dosyalar.Dosya karşılaştırılması'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo()) + Chars.LF 
			+ NStr("vi = 'Hãy cài đặt (cài đặt lại) ứng dụng Microsoft Word.';
					|ru = 'Установите (переустановите) приложение Microsoft Word.';
					|en = 'Install or reinstall Microsoft Word.'; fa = 'Install or reinstall Microsoft Word.';
					|it = 'Installare (reinstallare) l''applicazione Microsoft Word.';
					|pl = 'Zainstaluj (ponownie zainstaluj) aplikację Microsoft Word.';
					|tr = 'Microsoft Word uygulamasını yükleyin (yeniden yükleyin).'");
	EndTry;	
	WordObject.Visible = 0;
	WordObject.WordBasic.DisableAutoMacros(1);
	
	Document = WordObject.Documents.Open(PathToFile1);
	Try
		WordObject.ActiveWindow.ActivePane.View.Type = 1; // wdNormalView = 1
		Document.Merge(PathToFile2, 2, 0, 0); // MergeTarget:=wdMergeTargetSelected, DetectFormatChanges:=False, UseFormattingFrom:=wdFormattingFromCurrent
	Except
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Tệp.So sánh tệp';
				|ru = 'Файлы.Сравнение файлов';
				|en = 'Files.Compare files'; fa = 'Files.Compare files';
				|it = 'File.Confronto file';
				|pl = 'Pliki.Porównianie plików';
				|tr = 'Dosyalar.Dosya karşılaştırılması'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;	
	
	WordObject.Visible = 1;
	WordObject.Activate();
	
	Document.Close();

#EndIf

EndProcedure

Procedure CompareSpreadsheetDocuments1(PathToFile1, PathToFile2, TitleLeft, TitleRight)
	
	Files = New Array;
	Files.Add(New TransferableFileDescription(PathToFile1));
	Files.Add(New TransferableFileDescription(PathToFile2));
	
	PlacedFiles = New Array;
	If Not PutFiles(Files, PlacedFiles, , False) Then
		Return;
	EndIf;
	
	FormOpenParameters = StandardSubsystemsClient.SpreadsheetComparisonParameters();
	FormOpenParameters.TitleLeft = TitleLeft;
	FormOpenParameters.TitleRight = TitleRight;
	FormOpenParameters.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'So sánh %1 với %2';
			|ru = 'Сравнение %1 с %2';
			|en = 'Compare %1 to %2'; fa = 'Compare %1 to %2';
			|it = 'Сравнение %1 с %2';
			|pl = 'Porównanie %1 z %2';
			|tr = '%1 ile %2 karşılaştırılması'"), TitleLeft, TitleRight);
	StandardSubsystemsClient.ShowSpreadsheetComparison(PlacedFiles[0].Location, 
		PlacedFiles[1].Location, FormOpenParameters);
	
EndProcedure

// The function converts a Windows file name into OpenOffice URL.
Function ConvertToURL(FileName)
	
	Return "file:///" + StrReplace(FileName, "\", "/");
	
EndFunction

// Creating a structure for OpenOffice parameters.
Function AssignValueToProperty(Object, PropertyName, PropertyValue)
	
	Properties = Object.Bridge_GetStruct("com.sun.star.beans.PropertyValue");
	Properties.Name = PropertyName;
	Properties.Value = PropertyValue;
	
	Return Properties;
	
EndFunction

// Returns the user data directory inside the standard directory of application data.
// This directory can be used to store files locked by the current user.
// This method requires 1C:Enterprise Extension installed to operate in the web client.
//
Function UserDataDir()
	
#If WebClient Or MobileClient Then
		Return UserDataWorkDir();
#Else
		If Not CommonClient.IsWindowsClient() Then
			Return UserDataWorkDir();
		Else
			Shell = New COMObject("WScript.Shell");
			UserDataDir = Shell.ExpandEnvironmentStrings("%APPDATA%");
			Return CommonClientServer.AddLastPathSeparator(UserDataDir);
		EndIf;
#EndIf
	
EndFunction

// Opens the drag-and-drop form.
Procedure OpenDragFormFromOutside(FolderForAdding, FileNamesArray) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("FolderForAdding", FolderForAdding);
	FormParameters.Insert("FileNamesArray",   FileNamesArray);
	
	OpenForm("Catalog.Files.Form.DraggingFiles", FormParameters);
	
EndProcedure

#Region UtilityProceduresAndFunctionsForAsyncMethods

// General description of parameters:
//   Handler - Description of the message, Undefined, Structure - Procedure-handler of the asynchronous method.
//       * Undefined       - No processing required.
//       * Description of the announcement - Description of the handler procedure.
//     In rare cases, it may be necessary to interrupt code execution only
//     when it is necessary to show an asynchronous dialog (in loops, for example).
//     In such cases, the structure of the parameters of the calling code is passed to the Handler
//     with the mandatory Asynchronous Dialog key,
//     which is used when the code is interrupted and an asynchronous dialog is opened.:
//       * Structure - The structure of the parameters of the calling code.
//           ** Asynchronous dialog - Structure - 
//               *** Open - Boolean - True if the dialog was opened.
//               *** Procedure name - String - The name of the procedure of the handler of the calling code.
//               *** The module is a general module, the Client Application form is the handler module of the calling code.
//             In this case, the description of the announcement is formed from the keys "Procedure name" and "Module".
//             Attention. Not all asynchronous procedures support passing the Structure type. Read the composition of types.
//
//   The result is Arbitrary - The result that needs to be returned to the Handler.
//

// Displays the warning window, and after closing it, calls the handler with the specified result.
Procedure ReturnResultAfterShowWarning(Handler, WarningText, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", CompletionHandler(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New CallbackDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowMessageBox(Handler, WarningText);
	Else
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

// Displays the value view window, and after closing it, calls the handler with the specified result.
Procedure ReturnResultAfterShowValue(Handler, Value, Result)
	
	If Handler <> Undefined Then
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Handler", CompletionHandler(Handler));
		HandlerParameters.Insert("Result", Result);
		Handler = New CallbackDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, HandlerParameters);
		ShowValue(Handler, Value);
	Else
		ShowValue(, Value);
	EndIf;
	
EndProcedure

// Continuation of the procedure (see above).
Procedure ReturnResultAfterCloseSimpleDialog(Structure) Export
	
	If TypeOf(Structure.Handler) = Type("CallbackDescription") Then
		RunCallback(Structure.Handler, Structure.Result);
	EndIf;
	
EndProcedure

// Returns the result of a direct call when no dialogs were opened.
Procedure ReturnResult(Handler, Result) Export
	
	Handler = PrepareHandlerForDirectCall(Handler, Result);
	If TypeOf(Handler) = Type("CallbackDescription") Then
		RunCallback(Handler, Result);
	EndIf;
	
EndProcedure

// Records information necessary for the preparation of a handler for asynchronous dialogue.
Procedure RegisterCompletionHandler(ExecutionParameters, CompletionHandler) Export
	
	AsynchronousDialog = New Structure;
	AsynchronousDialog.Insert("Module",                 CompletionHandler.Module);
	AsynchronousDialog.Insert("ProcedureName",           CompletionHandler.ProcedureName);
	AsynchronousDialog.Insert("Open",                 False);
	AsynchronousDialog.Insert("ResultWhenNotOpen", Undefined);
	ExecutionParameters.Insert("AsynchronousDialog", AsynchronousDialog);
	
EndProcedure

// Preparation of a handler for asynchronous dialogue.
Function CompletionHandler(HandlerOrStructure)
	
	Handler = Undefined;
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		SetLockingFormFlag(HandlerOrStructure, True);
		AsynchronousDialog = Undefined;
		If HandlerOrStructure.Property("AsynchronousDialog", AsynchronousDialog) Then
			Handler = New CallbackDescription(AsynchronousDialog.ProcedureName, AsynchronousDialog.Module,	
				HandlerOrStructure);
		EndIf;
	Else
		Handler = HandlerOrStructure;
	EndIf;
	Return Handler;
	
EndFunction

Procedure SetLockingFormFlag(ExecutionParameters, Value) Export
	
	// Recursive registration of all handlers of the calling code.
	If ExecutionParameters.Property("HandlerResults_1") Then
		ExecutionParameters.HandlerResults_1 = CompletionHandler(ExecutionParameters.HandlerResults_1);
	EndIf;
	AsynchronousDialog = Undefined;
	If ExecutionParameters.Property("AsynchronousDialog", AsynchronousDialog) Then
		AsynchronousDialog.Open = Value;
	EndIf;
	
EndProcedure

Function LockingFormOpen(ExecutionParameters) Export
	
	AsynchronousDialog = Undefined;
	If ExecutionParameters.Property("AsynchronousDialog", AsynchronousDialog) Then
		Return AsynchronousDialog.Open;
	EndIf;
	Return False;
	
EndFunction

// Preparing a direct call handler without opening a dialog.
Function PrepareHandlerForDirectCall(HandlerOrStructure, Result)
	
	If TypeOf(HandlerOrStructure) = Type("Structure") Then
		If HandlerOrStructure.Property("AsynchronousDialog") Then
			HandlerOrStructure.AsynchronousDialog.ResultWhenNotOpen = Result;
		EndIf;
		Return Undefined; // The handler was not prepared for the dialog => The calling code did not stop.
	Else
		Return HandlerOrStructure;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Performs a batch of non-interactive actions with the file.
// If the file does not exist, then the actions will not be skipped.
//
// You can get the following properties: Name, Extension Name, Fullname, Path, Extension, Exists,
//    Time changes, Universal Time changes, only Respect, invisibility, Size, this Directory, this file.
//
// You can set the following properties: Time changes, universal Time changes, only respect, invisibility.
// You can perform actions with the file: Delete.
//
// Parameters:
//  Notification - CallbackDescription - An alert that is executed after performing
//   actions with the file. As a result, a Structure with properties is returned:
//     * ErrorDescription - String - error text if one of the actions failed.
//     * Results     - Array - contains the result for each action in the form of a structure:
//             * File       - File - initialized file object.
//                          - Undefined - file initialization error.
//             * Exists - Boolean - False if the file does not exist.
//
//  FileOperations - Array - containing structures with the name of the action and the parameters of the action:
//    * Action - String    - Get Properties, Set Properties, Delete, Copy From Source,
//                             Create A Directory, Get It, And Place It.
//    * File     - String    - full name of the file on the computer.
//               - File      - initialized file object.
//    * Properties - see properties that can be obtained or set.
//    * Source - String    - the full name of the file on the computer from which you want to create a copy.
//    * Address    - String    - the address of the file's binary data, such as the address of temporary storage.
//    * ErrorTitle - String - the text to which you want to add a newline and the errors view.
//
Procedure ProcessFile(Notification, FileOperations, FormIdentifier = Undefined)
	
	Context = New Structure;
	Context.Insert("Notification",         Notification);
	Context.Insert("FileOperations",    FileOperations);
	Context.Insert("FormIdentifier", FormIdentifier);
	
	Context.Insert("ActionsResult", New Structure);
	Context.ActionsResult.Insert("ErrorDescription", "");
	Context.ActionsResult.Insert("Results", New Array);
	
	Context.Insert("IndexOf", -1);
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//   Context - Structure:
//     * ActionsResult - Structure:
//       ** Results - Array
//
Procedure ProcessFileLoopStart(Context)
	
	If Context.IndexOf + 1 >= Context.FileOperations.Count() Then
		RunCallback(Context.Notification, Context.ActionsResult);
		Return;
	EndIf;
	
	Context.IndexOf = Context.IndexOf + 1;
	Context.Insert("ActionDetails", Context.FileOperations[Context.IndexOf]);
	
	Context.Insert("Result",  New Structure);
	Context.Result.Insert("File", Undefined);
	Context.Result.Insert("Exists", False);
	
	Context.ActionsResult.Results.Add(Context.Result);
	
	Context.Insert("PropertiesForGetting", New Structure);
	Context.Insert("PropertiesForInstalling", New Structure);
	
	Action = Context.ActionDetails.Action;
	File = Context.ActionDetails.File;
	FullFileName = ?(TypeOf(File) = Type("File"), File.FullName, File);
	
	If Action = "Delete" Then
		BeginDeletingFiles(New CallbackDescription(
			"ProcessFileAfterDeleteFiles", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "CopyFromSource" Then
		BeginCopyingFile(New CallbackDescription(
			"ProcessFileAfterCopyFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.ActionDetails.Source, FullFileName);
		Return;
	
	ElsIf Action = "CreateDirectory" Then
		BeginCreatingDirectory(New CallbackDescription(
			"ProcessFileAfterCreateDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), FullFileName);
		Return;
	
	ElsIf Action = "Get" Then
		FileDetails = New TransferableFileDescription(FullFileName, Context.ActionDetails.Address);
		FilesToObtain = New Array;
		FilesToObtain.Add(FileDetails);
		BeginGettingFiles(New CallbackDescription(
				"ProcessFileAfterGetFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			FilesToObtain, , False);
		Return;
	
	ElsIf Action = "Into" Then
		FileDetails = New TransferableFileDescription(FullFileName);
		Files = New Array;
		Files.Add(FileDetails);
		BeginPuttingFiles(New CallbackDescription(
				"ProcessFileAfterPutFiles", ThisObject, Context,
				"ProcessFileAfterError", ThisObject),
			Files, , False, Context.FormIdentifier);
		Return;
	
	ElsIf Action = "GetProperties" Then
		Context.Insert("PropertiesForGetting", Context.ActionDetails.Properties);
		
	ElsIf Action = "SetProperties1" Then
		Context.Insert("PropertiesForInstalling", Context.ActionDetails.Properties);
	EndIf;
	
	Context.Insert("File", ?(TypeOf(File) = Type("File"), File, New File(File)));
	Context.Result.Insert("File", Context.File);
	FillPropertyValues(Context.PropertiesForGetting, Context.File);
	Context.File.BeginCheckingExistence(New CallbackDescription(
		"ProcessFileAfterCheckExistence", ThisObject, Context,
		"ProcessFileAfterError", ThisObject));
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		Context.ActionsResult.ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	Else
		Context.ActionsResult.ErrorDescription = ErrorInfo;
	EndIf;
	
	If Context.ActionDetails.Property("ErrorTitle") Then
		Context.ActionsResult.ErrorDescription = Context.ActionDetails.ErrorTitle
			+ Chars.LF + Context.ActionsResult.ErrorDescription;
	EndIf;
	
	RunCallback(Context.Notification, Context.ActionsResult);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterDeleteFiles(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCopyFile(CopiedFile, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCreateDirectory(DirectoryName, Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetFiles(ObtainedFiles, Context) Export
	
	If TypeOf(ObtainedFiles) <> Type("Array") Or ObtainedFiles.Count() = 0 Then
		ProcessFileAfterError(NStr("vi = 'Đã hủy nhận tệp.';
									|ru = 'Получение файла было отменено.';
									|en = 'Getting the file was canceled.'; fa = 'Getting the file was canceled.';
									|it = 'L''ottenimento del file è stato annullato.';
									|pl = 'Pobieranie pliku zostało anulowane.';
									|tr = 'Dosya alımı iptal edildi.'"), Undefined, Context);
		Return;
	EndIf;
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterPutFiles(PlacedFiles, Context) Export
	
	If TypeOf(PlacedFiles) <> Type("Array") Or PlacedFiles.Count() = 0 Then
		ProcessFileAfterError(NStr("vi = 'Đã hủy sắp xếp tệp.';
									|ru = 'Помещение файла было отменено.';
									|en = 'Storing the file was canceled.'; fa = 'Storing the file was canceled.';
									|it = 'Il posizionamento del file è stato annullato.';
									|pl = 'Umieszczenie pliku zostało anulowane.';
									|tr = 'Dosya saklama iptal edildi.'"), Undefined, Context);
		Return;
	EndIf;
	
	Context.ActionDetails.Insert("Address", PlacedFiles[0].Location);
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//  Exists - Boolean
//  Context- Structure:
//   * Result - Structure
//
Procedure ProcessFileAfterCheckExistence(Exists, Context) Export
	
	Context.Result.Insert("Exists", Exists);
	
	If Not Context.Result.Exists Then
		ProcessFileLoopStart(Context);
		Return;
	EndIf;
	
	If Context.PropertiesForGetting.Count() = 0 Then
		ProcessFileAfterCheckIsFile(Null, Context);
		
	ElsIf Context.PropertiesForGetting.Property("Modified") Then
		Context.File.BeginGettingModificationTime(New CallbackDescription(
			"ProcessFileAfterGetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetModificationTime(Modified, Context) Export
	
	If Modified <> Null Then
		Context.PropertiesForGetting.Modified = Modified;
	EndIf;
	
	If Context.PropertiesForGetting.Property("UniversalModificationTime") Then
		Context.File.BeginGettingModificationUniversalTime(New CallbackDescription(
			"ProcessFileAfterGetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetUniversalModificationTime(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetUniversalModificationTime(UniversalModificationTime, Context) Export
	
	If UniversalModificationTime <> Null Then
		Context.PropertiesForGetting.UniversalModificationTime = UniversalModificationTime;
	EndIf;
	
	If Context.PropertiesForGetting.Property("ReadOnly") Then
		Context.File.BeginGettingReadOnly(New CallbackDescription(
			"ProcessFileAfterGetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetReadOnly(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetReadOnly(ReadOnly, Context) Export
	
	If ReadOnly <> Null Then
		Context.PropertiesForGetting.ReadOnly = ReadOnly;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Invisibility") Then
		Context.File.BeginGettingHidden(New CallbackDescription(
			"ProcessFileAfterGetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetInvisibility(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
//
// Parameters:
//  Invisibility - Boolean
//  Context - Structure:
//     * File - File
//     * PropertiesForGetting - Structure:
//       ** Size - Number
//       ** IsDirectory - Boolean
//
Procedure ProcessFileAfterGetInvisibility(Invisibility, Context) Export
	
	If Invisibility <> Null Then
		Context.PropertiesForGetting.Invisibility = Invisibility;
	EndIf;
	
	If Context.PropertiesForGetting.Property("Size") Then
		Context.File.BeginGettingSize(New CallbackDescription(
			"ProcessFileAfterGetSize", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterGetSize(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterGetSize(Size, Context) Export
	
	If Size <> Null Then
		Context.PropertiesForGetting.Size = Size;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsDirectory") Then
		Context.File.BeginCheckingIsDirectory(New CallbackDescription(
			"ProcessFileAfterCheckIsDirectory", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsDirectory(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory <> Null Then
		Context.PropertiesForGetting.IsDirectory = IsDirectory;
	EndIf;
	
	If Context.PropertiesForGetting.Property("IsFile") Then
		Context.File.BeginCheckingIsFile(New CallbackDescription(
			"ProcessFileAfterCheckIsFile", ThisObject, Context,
			"ProcessFileAfterError", ThisObject));
	Else
		ProcessFileAfterCheckIsFile(Null, Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterCheckIsFile(IsFile, Context) Export
	
	If IsFile <> Null Then
		Context.PropertiesForGetting.IsFile = IsFile;
	EndIf;
	
	If Context.PropertiesForInstalling.Count() = 0 Then
		ProcessFileAfterSetInvisibility(Context);
		
	ElsIf Context.PropertiesForInstalling.Property("Modified") Then
		Context.File.BeginSettingModificationTime(New CallbackDescription(
			"ProcessFileAfterSetModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Modified);
	Else
		ProcessFileAfterSetModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("UniversalModificationTime") Then
		Context.File.BeginSettingModificationUniversalTime(New CallbackDescription(
			"ProcessFileAfterSetUniversalModificationTime", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.UniversalModificationTime);
	Else
		ProcessFileAfterSetUniversalModificationTime(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetUniversalModificationTime(Context) Export
	
	If Context.PropertiesForInstalling.Property("ReadOnly") Then
		Context.File.BeginSettingReadOnly(New CallbackDescription(
			"ProcessFileAfterSetReadOnly", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.ReadOnly);
	Else
		ProcessFileAfterSetReadOnly(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetReadOnly(Context) Export
	
	If Context.PropertiesForInstalling.Property("Invisibility") Then
		Context.File.BeginSettingHidden(New CallbackDescription(
			"ProcessFileAfterSetInvisibility", ThisObject, Context,
			"ProcessFileAfterError", ThisObject), Context.PropertiesForInstalling.Invisibility);
	Else
		ProcessFileAfterSetInvisibility(Context);
	EndIf;
	
EndProcedure

// Continue the Processfile procedure.
Procedure ProcessFileAfterSetInvisibility(Context) Export
	
	ProcessFileLoopStart(Context);
	
EndProcedure

// Uploads a file from the client to temporary storage on the server. Does not work without an extension to work with 1C:Enterprise.
Function PutFileFromHardDriveInTempStorage(FullFileName, FileAddress = "", UUID = Undefined)
	If Not Is1CEnterpriseExtensionAttached() Then
		Return Undefined;
	EndIf;
	WhatToUpload = New Array;
	WhatToUpload.Add(New TransferableFileDescription(FullFileName, FileAddress));
	ImportResult1 = New Array;
	FileImported = PutFiles(WhatToUpload, ImportResult1, , False, UUID);
	If Not FileImported Or ImportResult1.Count() = 0 Then
		Return Undefined;
	EndIf;
	Return ImportResult1[0].Location;
EndFunction

#EndRegion

#Region ScannerProceduresAndFunctions

Procedure InitAddIn(NotificationOfReturn, SuggestInstall = False) Export
	
	If Not ScanAvailable() Then 
		AddInAttachmentResult = CommonInternalClient.AddInAttachmentResult();
		AddInAttachmentResult.Attached = False;
		AddInAttachmentResult.ErrorDescription = NStr("vi = 'Việc quét được phép chỉ khi làm việc trong Microsoft Windows hoặc Linux.';
														|ru = 'Сканирование доступно только при работе в Microsoft Windows или Linux.';
														|en = 'Scanning is supported on Windows and Linux only.'; fa = 'Scanning is supported on Windows and Linux only.';
														|it = 'Сканирование доступно только при работе в Microsoft Windows или Linux.';
														|pl = 'Scanning is supported on Windows and Linux only.';
														|tr = 'Tarama yalnızca Microsoft Windows veya Linux''ta çalışırken kullanılabilir.'");
		RunCallback(NotificationOfReturn, AddInAttachmentResult);
		Return;
	EndIf;
	
	ConnectionParameters = CommonClient.AddInAttachmentParameters();
	ConnectionParameters.ExplanationText = NStr("vi = 'Để tiếp tục, cần kết nối cấu phần scan ngoài.';
												|ru = 'Для продолжения требуется подключить внешнюю компоненту сканирования.';
												|en = 'To continue, attach a scanning add-in.'; fa = 'To continue, attach a scanning add-in.';
												|it = 'Для продолжения требуется подключить внешнюю компоненту сканирования.';
												|pl = 'To continue, attach a scanning add-in.';
												|tr = 'Devam etmek için harici bir tarama bileşeni bağlamanız gerekmektedir.'");
	ConnectionParameters.SuggestInstall = SuggestInstall;
	
	ComponentDetails = FilesOperationsInternalClientServer.ComponentDetails();
	CommonClient.AttachAddInFromTemplate(NotificationOfReturn, ComponentDetails.ObjectName, ComponentDetails.FullTemplateName, ConnectionParameters);
	
EndProcedure

Function ScanAvailable(IsSettingsCheck = False) Export
	
	If IsSettingsCheck Then
#If MobileClient Then
			Return MultimediaTools.PhotoSupported();
#ElsIf WebClient Then
			Return False;
#Else
			Return CommonClient.ClientPlatformType() = PlatformType.Windows_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Windows_x86_64
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86_64;
#EndIf
	Else
#If MobileClient Or WebClient Then
			Return False;
#Else
			Return CommonClient.ClientPlatformType() = PlatformType.Windows_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Windows_x86_64
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86 
			Or CommonClient.ClientPlatformType() = PlatformType.Linux_x86_64;
#EndIf
	EndIf;
	
EndFunction

// Returns scanning devices (array of strings).
Function EnumDevices(Form, Attachable_Module) Export
	
	Devices = ConnectedDevices(Form, Attachable_Module);
	
	Return Devices;
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresToSupportAsyncModel

Function ClientSupportsSynchronousCalls()
	
#If WebClient Then
	// Synchronous methods are not supported in Chrome and Firefox.
	SystemInfo = New SystemInfo;
	ApplicationInformationArray = StrSplit(SystemInfo.UserAgentInformation, " ", False);
	
	For Each ApplicationInformation In ApplicationInformationArray Do
		If StrFind(ApplicationInformation, "Chrome") > 0 Or StrFind(ApplicationInformation, "Firefox") > 0 Then
			Return False;
		EndIf;
	EndDo;
#EndIf
	
	Return True;
	
EndFunction

#EndRegion

#Region FileManagementCommonFormsEventHandler

// Select the file opening mode and start editing.
// Options "Edit", "Cancel".
//
// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure SelectModeAndEditFile(HandlerResults_1, FileData, CommandEditAvailability)
	
	PersonalSettings = PersonalFilesOperationsSettings();
	ResultOpen = ?(FileData.CurrentUserEditsFile And CommandEditAvailability,
		"Edit", PersonalSettings.FileOpeningOption);
	
	OpeningMethod = PersonalSettings.TextFilesOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.TextFilesExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(HandlerResults_1, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	OpeningMethod = PersonalSettings.GraphicalSchemasOpeningMethod;
	If OpeningMethod = PredefinedValue("Enum.OpenFileForViewingMethods.UsingBuiltInEditor") Then
		
		ExtensionInList = FilesOperationsInternalClientServer.FileExtensionInList(
			PersonalSettings.GraphicalSchemasExtension,
			FileData.Extension);
		
		If ExtensionInList Then
			ReturnResult(HandlerResults_1, ResultOpen);
			Return;
		EndIf;
		
	EndIf;
	
	// If you are already busy for editing, then don't ask - open it right away.
	If Not ValueIsFilled(FileData.BeingEditedBy)
		And PersonalSettings.PromptForEditModeOnOpenFile = True
		And CommandEditAvailability Then
		
		ExecutionParameters = New Structure;
		ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
		Handler = New CallbackDescription("SelectModeAndEditFileCompletion", ThisObject, ExecutionParameters);
		
		OpenForm("DataProcessor.FilesOperations.Form.HowToOpenFile", , , , , , Handler, FormWindowOpeningMode.LockWholeInterface);
		Return;
	EndIf;
	
	ReturnResult(HandlerResults_1, ResultOpen);
	
EndProcedure

Procedure SelectModeAndEditFileCompletion(Result, ExecutionParameters) Export
	
	ResultOpen = "Open";
	ResultEdit = "Edit";
	ResultCancel = "Cancel";
	
	If TypeOf(Result) <> Type("Structure") Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ResultCancel);
		Return;
	EndIf;
	
	If Result.HowToOpen = 1 Then
		ReturnResult(ExecutionParameters.HandlerResults_1, ResultEdit);
		Return;
	EndIf;
	
	ReturnResult(ExecutionParameters.HandlerResults_1, ResultOpen);
	
EndProcedure

// File commands are available, there is at least one line in the list and no grouping is highlighted.
// 
// Parameters:
//  Items - FormItems:
//    * List - FormTable
// 
// Returns:
//  Boolean
//
Function FileCommandsAvailable(Items) Export
	
	FileRef = Items.List.CurrentRow;
	
	If FileRef = Undefined Then 
		Return False;
	EndIf;
	
	If TypeOf(Items.List.CurrentRow) = Type("DynamicListGroupRow") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region PrintingSpreadsheetOrOfficeDocWithDigitalSignatureStamp

Procedure DoPrintFileWithStamp(Ref, UUID) Export
	
	AdditionalParameters = FilesOperationsClientServer.FileDataParameters();
	AdditionalParameters.FormIdentifier = UUID;
	
	FileData = FilesOperationsInternalServerCall.GetFileData(Ref, AdditionalParameters);
	If Not FileData.SignedWithDS Then
		ShowMessageBox(, NStr("vi = 'Không cho phép in có dấu chữ ký điện tử.';
								|ru = 'Печать документа со штампом электронной подписи недоступна.';
								|en = 'Cannot print documents with digital signature stamps.'; fa = 'Cannot print documents with digital signature stamps.';
								|it = 'Cannot print documents with digital signature stamps.';
								|pl = 'Cannot print documents with digital signature stamps.';
								|tr = 'Belge, elektronik imza damgası ile yazdırılamaz.'"));
		Return;
	EndIf;
	 
	If FileData.Encrypted Then
		EncryptionCertificatesArray = FileData.EncryptionCertificatesArray;
		GetDecryptedDataForPrinting(FileData, UUID);
	Else
		PrintFileWithStamp(FileData);
	EndIf;
	
EndProcedure

Procedure GetDecryptedDataForPrinting(FileData, UUID)
	
	FollowUpHandler = New CallbackDescription("PrintFileWithStampAfterDecryption", ThisObject,
		New Structure("FileData, UUID", FileData, UUID));
		
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		RunCallback(FollowUpHandler, False);
		Return;
	EndIf;
	
	DataDetails = New Structure;
	DataDetails.Insert("Operation", NStr("vi = 'Giải mã tệp';
										|ru = 'Расшифровка файла';
										|en = 'Decrypt file'; fa = 'Decrypt file';
										|it = 'Расшифровка файла';
										|pl = 'Deszyfrowanie plików';
										|tr = 'Dosya detaylandırması'"));
	DataDetails.Insert("DataTitle", NStr("vi = 'Tệp';
										|ru = 'Файл';
										|en = 'File'; fa = 'فایل';
										|it = 'Файл';
										|pl = 'File';
										|tr = 'Dosya'"));
	DataDetails.Insert("Data", FileData.RefToBinaryFileData);
	DataDetails.Insert("Presentation", FileData.Ref);
	DataDetails.Insert("EncryptionCertificates",
		PutToTempStorage(FileData.EncryptionCertificatesArray, UUID));
	DataDetails.Insert("NotifyOnCompletion", False);

	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.Decrypt(DataDetails,, FollowUpHandler);
	
EndProcedure

Procedure PrintFileWithStampAfterDecryption(DataDetails, Context) Export
	
	If Not DataDetails.Success Then
		Return;
	EndIf;
	
	If TypeOf(DataDetails.DecryptedData) = Type("BinaryData") Then
		FileAddress = PutToTempStorage(DataDetails.DecryptedData,
			Context.UUID);
	Else
		FileAddress = DataDetails.DecryptedData;
	EndIf;
	
	Context.FileData.RefToBinaryFileData = FileAddress;
	PrintFileWithStamp(Context.FileData);
	
EndProcedure

Procedure PrintFileWithStamp(FileData)
	
	Document = FilesOperationsInternalServerCall.DocumentWithStamp(FileData);
	
	DocumentName3 = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 (có dấu)';
																					|ru = '%1 (со штампом)';
																					|en = '%1 (with stamp)'; fa = '%1 (with stamp)';
																					|it = '%1 (со штампом)';
																					|pl = '%1 (with stamp)';
																					|tr = '%1 (kaşeli)'"), 
		FileData.Description);
	
	If TypeOf(Document) = Type("SpreadsheetDocument") Then
		If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
			ModulePrintManagerClient = CommonClient.CommonModule("PrintManagementClient");
			PrintFormID = "AttachedFile";
			Document.Protection = False;
			
			PrintFormsCollection = ModulePrintManagerClient.NewPrintFormsCollection(PrintFormID);
			PrintForm = ModulePrintManagerClient.PrintFormDetails(PrintFormsCollection, PrintFormID);
			PrintForm.TemplateSynonym = DocumentName3;
			PrintForm.SpreadsheetDocument = Document;
			
			ModulePrintManagerClient.PrintDocuments(PrintFormsCollection);
		Else
			Document.Print(PrintDialogUseMode.Use);
		EndIf;
	Else
		FileSystemClient.OpenFile(Document, , DocumentName3+".docx");
	EndIf;
	
EndProcedure

// Backward compatibility. Opening a file without an owner at a temporary storage address.

// Continue the OpenFile procedure.
Procedure OpenFileAddInSuggested(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	
	If FileSystemExtensionAttached1 Then
		
		UserWorkingDirectory = UserWorkingDirectory();
		FullFileNameAtClient = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		FileOnHardDrive = New File(FullFileNameAtClient);
		
		AdditionalParameters.Insert("ForEditing", ForEditing);
		AdditionalParameters.Insert("UserWorkingDirectory", UserWorkingDirectory);
		AdditionalParameters.Insert("FileOnHardDrive", FileOnHardDrive);
		AdditionalParameters.Insert("FullFileNameAtClient", FullFileNameAtClient);
		
		If ValueIsFilled(FileData.BeingEditedBy) And ForEditing And FileOnHardDrive.Exists() Then
			FileOnHardDrive.SetReadOnly(False);
			GetFile = False;
		ElsIf FileOnHardDrive.Exists() Then
			CallbackDescription = New CallbackDescription("OpenFileDialogShown", ThisObject, AdditionalParameters);
			ShowDialogNeedToGetFileFromServer(CallbackDescription, FullFileNameAtClient, FileData, ForEditing);
			Return;
		Else
			GetFile = True;
		EndIf;
		
		OpenFileDialogShown(GetFile, AdditionalParameters);
	Else
		CallbackDescription = New CallbackDescription("OpenFileReminderShown", ThisObject, AdditionalParameters);
		OutputNotificationOnEdit(CallbackDescription);
	EndIf;
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileReminderShown(ReminderResult, AdditionalParameters) Export
	
	If ReminderResult = DialogReturnCode.Cancel Or ReminderResult = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	GetFile(FileData.RefToBinaryFileData, FileData.FileName, True);
	
EndProcedure

// Continue the OpenFile procedure.
Procedure OpenFileDialogShown(GetFile, AdditionalParameters) Export
	
	If GetFile = Undefined Then
		Return;
	EndIf;
	
	FileData = AdditionalParameters.FileData;
	ForEditing = AdditionalParameters.ForEditing;
	UserWorkingDirectory = AdditionalParameters.UserWorkingDirectory;
	FileOnHardDrive = AdditionalParameters.FileOnHardDrive;
	FullFileNameAtClient = AdditionalParameters.FullFileNameAtClient;
	
	CanOpenFile = True;
	If GetFile Then
		FullFileNameAtClient = "";
		CanOpenFile = GetFileToWorkingDirectory(
			FileData.RefToBinaryFileData,
			FileData.RelativePath,
			FileData.UniversalModificationDate,
			FileData.FileName,
			UserWorkingDirectory,
			FullFileNameAtClient);
	EndIf;
		
	If CanOpenFile Then
		
		If ForEditing Then
			FileOnHardDrive.SetReadOnly(False);
		Else
			FileOnHardDrive.SetReadOnly(True);
		EndIf;
		
		UUID = ?(AdditionalParameters.Property("UUID"),
			AdditionalParameters.UUID, Undefined);
			
		OpenFileWithApplication(FileData, FullFileNameAtClient, UUID);
		
	EndIf;
		
EndProcedure

Function GetFileToWorkingDirectory(Val FileBinaryDataAddress,
                                    Val RelativePath,
                                    Val UniversalModificationDate,
                                    Val FileName,
                                    Val UserWorkingDirectory,
                                    FullFileNameAtClient)
	
	If UserWorkingDirectory = Undefined
	 Or IsBlankString(UserWorkingDirectory) Then
		
		Return False;
	EndIf;
	
	DirectoryForSave = UserWorkingDirectory + RelativePath;
	
	Try
		CreateDirectory(DirectoryForSave);
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		ErrorMessage = NStr("vi = 'Không thể tạo thư mục trên máy tính:';
							|ru = 'Не удалось создать каталог на компьютере:';
							|en = 'Couldn''t create a directory:'; fa = 'Couldn''t create a directory:';
							|it = 'Не удалось создать каталог на компьютере:';
							|pl = 'Couldn''t create a directory:';
							|tr = 'Bilgisayarda dizin oluşturulamadı:'") + " " + ErrorMessage;
		CommonClient.MessageToUser(ErrorMessage);
		Return False;
	EndTry;
	
	File = New File(DirectoryForSave + FileName);
	If File.Exists() Then
		Try
			File.SetReadOnly(False);
			DeleteFiles(DirectoryForSave + FileName);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
		EndTry;	
	EndIf;
	
	FileToReceive = New TransferableFileDescription(DirectoryForSave + FileName, FileBinaryDataAddress);
	FilesToObtain = New Array;
	FilesToObtain.Add(FileToReceive);
	
	ObtainedFiles = New Array;
	
	If GetFiles(FilesToObtain, ObtainedFiles, , False) Then
		FullFileNameAtClient = ObtainedFiles[0].FullName;
		SetModificationUniversalTime(FullFileNameAtClient, UniversalModificationDate);
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Parameters:
//   FileData - See FilesOperationsInternalServerCall.FileData
//
Procedure ShowDialogNeedToGetFileFromServer(HandlerResults_1, Val FileNameWithPath, Val FileData, 
	Val ForEditing)
	
	StandardFileData = New Structure;
	StandardFileData.Insert("UniversalModificationDate", FileData.UniversalModificationDate);
	StandardFileData.Insert("Size",                       FileData.Size);
	StandardFileData.Insert("InWorkingDirectoryForRead",     Not ForEditing);
	StandardFileData.Insert("BeingEditedBy",                  FileData.BeingEditedBy);
	
	// It was found out that there is a file in the working directory.
	// Checking the date of the change and deciding what to do next.
	
	Parameters = New Structure;
	Parameters.Insert("HandlerResults_1", HandlerResults_1);
	Parameters.Insert("FileNameWithPath", FileNameWithPath);
	CallbackDescription = New CallbackDescription("ShowDialogNeedToGetFileFromServerActionDefined", 
		ThisObject, Parameters);
	ActionOnOpenFileInWorkingDirectory(CallbackDescription, FileNameWithPath, StandardFileData);
	
EndProcedure

// Continue the procedure to show the directory and get the file Server.
Procedure ShowDialogNeedToGetFileFromServerActionDefined(Action, AdditionalParameters) Export
	FileNameWithPath = AdditionalParameters.FileNameWithPath;
	
	If Action = "GetFromStorageAndOpen" Then
		File = New File(FileNameWithPath);
		Try
			File.SetReadOnly(False);
			DeleteFiles(FileNameWithPath);
		Except
			EventLogClient.AddMessageForEventLog(EventLogEvent(),
				"Warning", ErrorProcessing.DetailErrorDescription(ErrorInfo()),, True);
			Result = Undefined;	
		EndTry;	
		Result = True;
	ElsIf Action = "OpenExistingFile" Then
		Result = False;
	Else // Action = "Cancel".
		Result = Undefined;
	EndIf;
	
	RunCallback(AdditionalParameters.HandlerResults_1, Result);
	
EndProcedure

Function IsReadyForScanning(Form, Attachable_Module) Export 
	IsDevicePresent = IsDevicePresent(Form, Attachable_Module);
	
	If IsDevicePresent Then
		Try
			ConnectedDevices(Form, Attachable_Module);
			Return True;
		Except
			Return False;
		EndTry;
	EndIf;
	Return False;
EndFunction

Function ConnectedDevices(Form, Attachable_Module)
	WriteScanLog("EnumDevices.Start");
	Try
		Devices = Attachable_Module.EnumDevices();
		ConnectedDevices = StrSplit(Devices, Chars.LF, False);
		WriteScanLog("EnumDevices.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("EnumDevices() = %1", 
			StrConcat(ConnectedDevices, "|")));
	Except   
		ConnectedDevices = New Array;
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("EnumDevices", ErrorPresentation, True);
		ShowScanError(Form, NStr("vi = 'Không thể nhận danh sách thiết bị';
								|ru = 'Не удалось получить список устройств';
								|en = 'Cannot get the list of devices'; fa = 'Cannot get the list of devices';
								|it = 'Не удалось получить список устройств';
								|pl = 'Cannot get the list of devices';
								|tr = 'Cihaz listesi alınamadı'"), ErrorPresentation);
	EndTry;
	Return ConnectedDevices;
EndFunction

// Returns the configuration of the scanner by name.
//
// Parameters:
//   Attachable_Module - Scanning Component
//   DeviceName - String - name of the scanner.
//   SettingName  - String - name of the setting,
//       such as" XRESOLUTION", or" PIXELTYPE", or" ROTATION", or"SUPPORTEDSIZES".
//
// Returns:
//   Number - the value of the scanner setting.
//
Function ScannerSetting(Form, Attachable_Module, DeviceName, SettingName) Export
	
	If Not ScanAvailable(True) Then
		Return -1;
	EndIf;
	
	Try
		WriteScanLog("GetSetting.Start", 
			StringFunctionsClientServer.SubstituteParametersToString("GetSetting(%1, %2)", 
				DeviceName, SettingName));
		SettingValue = Attachable_Module.GetSetting(DeviceName, SettingName);
		WriteScanLog("GetSetting.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("GetSetting(%1, %2) = %3", 
				DeviceName, SettingName, SettingValue));
		
		Return SettingValue;
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("GetSetting", ErrorPresentation, True);
		ShowScanError(Form, NStr("vi = 'Không thể nhận tùy chỉnh thiết bị.';
								|ru = 'Не удалось получить настройки устройства.';
								|en = 'Cannot get the device settings.'; fa = 'Cannot get the device settings.';
								|it = 'Не удалось получить настройки устройства.';
								|pl = 'Cannot get the device settings.';
								|tr = 'Cihaz ayarları alınamadı.'"), ErrorPresentation);
		Return -1;
	EndTry;
	
EndFunction

Function IsDevicePresent(Form, Attachable_Module, ShowError_ = True) Export
	WriteScanLog("IsDevicePresent.Start");
	Try
		IsDevicePresent = Attachable_Module.IsDevicePresent();
		WriteScanLog("IsDevicePresent.Result", 
			StringFunctionsClientServer.SubstituteParametersToString("IsDevicePresent() = %1", IsDevicePresent));
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("IsDevicePresent", ErrorPresentation, True);
		If ShowError_ Then
			ShowScanError(Form, NStr("vi = 'Không thể kiểm tra sẵn có thiết bị';
									|ru = 'Не удалось проверить наличие устройств';
									|en = 'Cannot check for devices'; fa = 'Cannot check for devices';
									|it = 'Не удалось проверить наличие устройств';
									|pl = 'Cannot check for devices';
									|tr = 'Cihazlar kontrol edilemedi'"), ErrorPresentation);
		EndIf;
		IsDevicePresent = False;
	EndTry;
	
	Return IsDevicePresent;
	
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//  Attachable_Module - AddInObject
//  ScanningParameters - See FilesOperationsInternalClientServer.ScanningParameters
//
Procedure StartScanning(Form, Attachable_Module, ScanningParameters) Export
	
	DeflateParameter = ?(Upper(PictureFormat) = "JPG", ScanningParameters.JPGQuality, 
		ScanningParameters.TIFFDeflation);
	
	ParameterValues = New Array;
	ParameterValues.Add("ShowDialogBox" + ": " + ScanningParameters.ShowDialogBox);
	ParameterValues.Add("SelectedDevice" + ": " + ScanningParameters.SelectedDevice);
	ParameterValues.Add("PictureFormat" + ": " + ScanningParameters.PictureFormat);
	ParameterValues.Add("Resolution" + ": " + ScanningParameters.Resolution);
	ParameterValues.Add("Chromaticity" + ": " + ScanningParameters.Chromaticity);
	ParameterValues.Add("Rotation" + ": " + ScanningParameters.Rotation);
	ParameterValues.Add("PaperSize" + ": " + ScanningParameters.PaperSize);
	ParameterValues.Add("DeflateParameter" + ": " + DeflateParameter);
	ParameterValues.Add("DuplexScanning" + ": " + ScanningParameters.DuplexScanning);
	ParameterValues.Add("DocumentAutoFeeder" + ": " + ScanningParameters.DocumentAutoFeeder);

	EventText = "StartScanning" + "(" + StrConcat(ParameterValues, ", ") + ")";
	WriteScanLog("StartScanning.Start", EventText);
		
	Try
		Attachable_Module.StartScanning(
			ScanningParameters.ShowDialogBox,
			ScanningParameters.SelectedDevice,
			ScanningParameters.PictureFormat,
			ScanningParameters.Resolution,
			ScanningParameters.Chromaticity,
			ScanningParameters.Rotation,
			ScanningParameters.PaperSize,
			DeflateParameter,
			ScanningParameters.DuplexScanning,
			ScanningParameters.DocumentAutoFeeder);
		WriteScanLog("StartScanning.Result", EventText);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("StartScanning", ErrorPresentation, True);
		ShowScanError(Form, NStr("vi = 'Không thể scan chứng từ';
								|ru = 'Не удалось отсканировать документ';
								|en = 'Cannot scan the document'; fa = 'Cannot scan the document';
								|it = 'Не удалось отсканировать документ';
								|pl = 'Cannot scan the document';
								|tr = 'Belge taranamadı'"), ErrorPresentation);
	EndTry;
	
EndProcedure

Procedure EnableScanLog(Attachable_Module, ContinueNotification, Val Restart_1 = False) Export 
	ClientID = ClientID();
	ScanLogParameters = FilesOperationsInternalServerCall.ScanLogParameters(ClientID);
	
	If Not Restart_1 Then
		Restart_1 = ScanLogParameters.ScanLogStartDate = Date(1,1,1);
	EndIf;
	
	NameOfLogFile = ScanLogParameters.NameOfLogFile;
	
	If Restart_1 And NameOfLogFile <> Undefined Then
		
		SetLogFileName(Attachable_Module, "");
		
		LogFile1 = New File(NameOfLogFile);
		If LogFile1.Exists() Then
			DeleteFiles(NameOfLogFile);
		EndIf;
		
		FileDirectory = New File(LogFile1.Path);
		If Not FileDirectory.Exists() Then
			NameOfLogFile = "";
		EndIf;
		
	EndIf;
	
	ScanLogCatalog = ScanLogParameters.ScanLogCatalog;
	UseScanLogDirectory  = ScanLogParameters.UseScanLogDirectory;
	
	Context = New Structure;
	Context.Insert("Attachable_Module", Attachable_Module);
	Context.Insert("ContinueNotification", ContinueNotification);
	
	NotificationAfterTempDirectoryToAttachLogFilesCreated = New CallbackDescription(
		"NotificationAfterTempDirectoryToAttachLogFilesCreated",
		ThisObject, Context);
	
	If UseScanLogDirectory And ScanLogCatalog <> Undefined Then
		Context = New Structure;
		Context.Insert("NotificationAfterTempDirectoryToAttachLogFilesCreated",
			NotificationAfterTempDirectoryToAttachLogFilesCreated);
		Context.Insert("ScanLogCatalog", ScanLogCatalog);
		Context.Insert("ClientID", ClientID);
		
		CheckResultNotification = New CallbackDescription("AfterScanLogDirAvailabilityChecked", 
			ThisObject, Context);	
		CheckDirAvailability(CheckResultNotification, ScanLogCatalog);
		
	ElsIf Restart_1 And Not ValueIsFilled(NameOfLogFile) Then
		FileSystemClient.CreateTemporaryDirectory(NotificationAfterTempDirectoryToAttachLogFilesCreated);
	ElsIf Restart_1 Then
		Context = New Structure;
		Context.Insert("NameOfLogFile", NameOfLogFile);
		Context.Insert("NotificationAfterTempDirectoryToAttachLogFilesCreated",
			NotificationAfterTempDirectoryToAttachLogFilesCreated);
	
		CheckResultNotification = New CallbackDescription("AfterLogFileDirAvailabilityChecked", 
			ThisObject, Context);
		LogFile1 = New File(NameOfLogFile);
		CheckDirAvailability(CheckResultNotification, LogFile1.Path);
	Else
		RunCallback(ContinueNotification);
	EndIf;
	
EndProcedure

Procedure AfterLogFileDirAvailabilityChecked(Result, ExternalContext) Export
	Notification = ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated;
	Attachable_Module = Notification.AdditionalParameters.Attachable_Module;
	If Not Result.Success Then
		FileSystemClient.CreateTemporaryDirectory(Notification);
	Else
		SetLogFileName(Attachable_Module, ExternalContext.NameOfLogFile);
		If Notification.AdditionalParameters.ContinueNotification <> Undefined Then
			RunCallback(Notification.AdditionalParameters.ContinueNotification);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AfterScanLogDirAvailabilityChecked(Result, ExternalContext) Export
	If Not Result.Success Then
		FilesOperationsInternalServerCall.ResetScanLogDirectoryParameters(ExternalContext.ClientID);
		WriteScanLog("ComponentFile", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thư mục nhật ký scan không được phép %1. Việc sử dụng thư mục bị hủy bỏ.';
				|ru = 'Каталог журнала сканирования недоступен %1. Использование каталога отменено.';
				|en = 'Cannot access the scan log directory: %1. Your choice is not saved.'; fa = 'Cannot access the scan log directory: %1. Your choice is not saved.';
				|it = 'Каталог журнала сканирования недоступен %1. Использование каталога отменено.';
				|pl = 'Cannot access the scan log directory: %1. Your choice is not saved.';
				|tr = 'Tarama günlüğü dizini %1 mevcut değil. Dizinin kullanımı iptal edildi.'"), 
			ExternalContext.ScanLogCatalog), True);
		ScanningSettings1 = New Structure;
		ScanningSettings1.Insert("ScanLogCatalog", "");
		ScanningSettings1.Insert("UseScanLogDirectory", False);
		Notify("ScanSettingsChanged", ScanningSettings1); 
		FileSystemClient.CreateTemporaryDirectory(ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated);
	Else
		RunCallback(ExternalContext.NotificationAfterTempDirectoryToAttachLogFilesCreated, 
			ExternalContext.ScanLogCatalog);
	EndIf;
	
EndProcedure

Procedure SetLogFileName(Attachable_Module, NameOfLogFile) 
	WriteScanLog("LogFilePath.ValueSetting", 
		StringFunctionsClientServer.SubstituteParametersToString("LogFilePath = %1", NameOfLogFile));
	Try
		Attachable_Module.LogFilePath = NameOfLogFile;
		WriteScanLog("LogFilePath.IsValueSet");
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteScanLog("LogFilePath", ErrorPresentation, True);
	EndTry;
EndProcedure

Procedure NotificationAfterTempDirectoryToAttachLogFilesCreated(ScanLogCatalog, Context) Export
		
	NameOfLogFile = ScanLogCatalog + GetPathSeparator() + "ImageScan.log";
	Attachable_Module = Context.Attachable_Module;
	SetLogFileName(Attachable_Module, NameOfLogFile);
	FilesOperationsInternalServerCall.SetScanLogStartParameters(NameOfLogFile);
	If Context.ContinueNotification <> Undefined Then
		RunCallback(Context.ContinueNotification);
	EndIf;
			
EndProcedure

Procedure WriteScanLog(Event, Comment = "", IsError = False) Export 
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Quét ảnh';
			|ru = 'Сканирование изображений';
			|en = 'Scan images'; fa = 'اسکن تصاویر';
			|it = 'Scansione immagini';
			|pl = 'Skanowanie obrazów';
			|tr = 'Görsel tarama'", CommonClient.DefaultLanguageCode()) + "." + Event,
		?(IsError, "Error", "Information"), Comment,, True);
	
EndProcedure

Procedure ShowScanError(Form, Title, DetailErrorDescription)
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(Form, "ErrorPresentation") Then
		Return;
	EndIf;
	
	Form.ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1: %2';
			|ru = '%1: %2';
			|en = '%1: %2'; fa = '%1: %2';
			|it = '%1: %2';
			|pl = '%1: %2';
			|tr = '%1: %2'"),
		Title,
		DetailErrorDescription);
	
	ShowMessageBox(, Title);
	
EndProcedure

Function HasScanErrorOccurred() Export
	
	ScanJobParameters = CommonClient.CommonSettingsStorageLoad(
		"ScanAddIn", "ScanJobParameters", Undefined);
	Return ScanJobParameters <> Undefined;
	
EndFunction

Procedure DeleteScanError(Attachable_Module, CompletionNotification = Undefined, 
	ShouldClearAddInLog = True) Export
	
	CommonClient.CommonSettingsStorageSave("ScanAddIn", 
		"ScanJobParameters", Undefined);
	EnableScanLog(Attachable_Module, CompletionNotification, ShouldClearAddInLog);
	
EndProcedure

Procedure GetTechnicalInformation(DetailErrorDescription, NotificationOnCompletion = Undefined) Export
	
	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.FullFileName = NStr("vi = 'Thông tin kỹ thuật';
										|ru = 'Техническая информация';
										|en = 'Technical information'; fa = 'اطلاعات فنی';
										|it = 'Informazione tecnica';
										|pl = 'Informacja techniczna';
										|tr = 'Teknik bilgi'");
	Filter = NStr("vi = 'Báo cáo về vấn đề';
					|ru = 'Отчет о проблеме';
					|en = 'Issue report'; fa = 'Issue report';
					|it = 'Отчет о проблеме';
					|pl = 'Issue report';
					|tr = 'Sorun raporu'") + "(*.zip)|*.zip";
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Lưu thông tin kỹ thuật về vấn đề';
								|ru = 'Сохранение технической информации о проблеме';
								|en = 'Save technical information about the issue'; fa = 'Save technical information about the issue';
								|it = 'Сохранение технической информации о проблеме';
								|pl = 'Save technical information about the issue';
								|tr = 'Sorunla ilgili teknik bilgilerin kaydedilmesi'");
	If Not OpenFileDialog.Choose() Then
		Return;
	EndIf;
	FilesNames = OpenFileDialog.SelectedFiles;
	If FilesNames.Count() = 0 Then
		Return;
	EndIf;
		
	Context = New Structure();
	Context.Insert("DetailErrorDescription", DetailErrorDescription);
	Context.Insert("NotificationAfterTechnicalInfoObtained", NotificationOnCompletion);
	Context.Insert("FileName", FilesNames[0]);
	CallbackDescription = New CallbackDescription("AfterLogFilesTempDirectoryCreated", ThisObject, Context);
	FileSystemClient.CreateTemporaryDirectory(CallbackDescription);

EndProcedure

Procedure AfterLogFilesTempDirectoryCreated(DirectoryName, Context) Export
#If Not WebClient Then	
	TempFilesDir = DirectoryName + GetPathSeparator();
	TechnicalInformation = FilesOperationsInternalServerCall.TechnicalInformation();
	
	FilesForDeletion = New Array;
	RecordZIP = New ZipFileWriter(Context.FileName);
	NameOfLogFile = TechnicalInformation.NameOfLogFile;
	If NameOfLogFile = Undefined Then
		WriteScanLog("ComponentFile", NStr("vi = 'Chưa xác định tên tệp nhật ký cấu phần scan.';
											|ru = 'Не задано имя файла журнала компоненты сканирования.';
											|en = 'Specify the name of the scanning add-in log file.'; fa = 'Specify the name of the scanning add-in log file.';
											|it = 'Не задано имя файла журнала компоненты сканирования.';
											|pl = 'Specify the name of the scanning add-in log file.';
											|tr = 'Tarama bileşeni günlük dosyasının adı belirtilmedi.'"), 
			True);
	Else
		Log_File = New File(NameOfLogFile);
		LogFileNameForSaving = "";
		
		If Log_File.Exists() Then
			LogFileNameForSaving = TempFilesDir + "ImageScan.log";
			MoveFile(NameOfLogFile, LogFileNameForSaving);
			RecordZIP.Add(LogFileNameForSaving);
		Else
			WriteScanLog("ComponentFile", StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tồn tại tệp nhật ký cấu phần scan. %1';
					|ru = 'Файл журнала компоненты сканирования не существует. %1';
					|en = 'The scanning add-in log file does not exist. %1'; fa = 'The scanning add-in log file does not exist. %1';
					|it = 'Файл журнала компоненты сканирования не существует. %1';
					|pl = 'The scanning add-in log file does not exist. %1';
					|tr = 'Tarama bileşeni günlük dosyası mevcut değil. %1'"), 
				NameOfLogFile), True);
		EndIf;
	EndIf;
	
	ContextOutgoing = New Structure;
	Context.Insert("RecordZIP", RecordZIP);
	Context.Insert("FilesForDeletion", FilesForDeletion);
	Context.Insert("TempFilesDir", TempFilesDir);
	Context.Insert("TechnicalInformation", TechnicalInformation);
	
	SupportInformation = StandardSubsystemsClient.SupportInformation();
	Text =  NStr("vi = 'Thông tin máy tính:';
				|ru = 'Информация о компьютере:';
				|en = 'Computer information:'; fa = 'Computer information:';
				|it = 'Informazione sul computer:';
				|pl = 'Informacje o komputerze:';
				|tr = 'Bilgisayar bilgileri:'") + Chars.LF + SupportInformation;
	Context.Insert("SummaryInfoText", Text);
		
	CallbackDescription = New CallbackDescription("SummaryInfoAfterAddInObtained", ThisObject, Context);
	InitAddIn(CallbackDescription, True);
#EndIf
EndProcedure

Procedure SummaryInfoAfterAddInObtained(InitializationResult, Context) Export
#If Not WebClient Then
	SummaryInfoText = Context.SummaryInfoText;
	TechnicalInformation = Context.TechnicalInformation;
	FilesForDeletion = Context.FilesForDeletion;
	RecordZIP = Context.RecordZIP;
	AddInInformation = "";
	Attachable_Module = Undefined;
	If InitializationResult.Attached Then
		Try
			Attachable_Module = InitializationResult.Attachable_Module;
			VersionComponents = Attachable_Module.Version();
			AddInInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phiên bản cấu phần %1: %2';
					|ru = 'Версия компоненты %1: %2';
					|en = '%1 add-in version: %2'; fa = '%1 add-in version: %2';
					|it = 'Версия компоненты %1: %2';
					|pl = '%1 add-in version: %2';
					|tr = '%1 bileşeni sürümü: %2'"), "ImageScan", VersionComponents);
		Except
			WriteScanLog("Version", ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
				True);
		EndTry;
	Else
		Return;
	EndIf;
	
	SummaryInfoText = SummaryInfoText + Chars.LF + AddInInformation
		+ Chars.LF + Chars.LF + NStr("vi = 'Thông tin kỹ thuật';
									|ru = 'Техническая информация';
									|en = 'Technical information'; fa = 'اطلاعات فنی';
									|it = 'Informazione tecnica';
									|pl = 'Informacja techniczna';
									|tr = 'Teknik bilgi'") + ":" 
		+ Chars.LF + Context.DetailErrorDescription
		+ Chars.LF + Chars.LF;
		
	If CommonClient.FileInfobase() Then
		WorkMode = ?(CommonClient.ClientConnectedOverWebServer(),
			NStr("vi = 'File-server thông qua web';
				|ru = 'Файловый через веб';
				|en = 'File mode via web'; fa = 'File mode via web';
				|it = 'Di file via web';
				|pl = 'Plikowy przez www';
				|tr = 'Web üzerinden dosya'"), NStr("vi = 'File-server';
													|ru = 'Файловый';
													|en = 'File'; fa = 'فایل';
													|it = 'Файловый';
													|pl = 'Plikowy';
													|tr = 'Dosya'"));
	Else
		WorkMode = NStr("vi = 'Client-server';
						|ru = 'Клиент-серверный';
						|en = 'Client/server'; fa = 'Client/server';
						|it = 'Клиент-серверный';
						|pl = 'Klient-serwer';
						|tr = 'İstemci/sunucu'");
	EndIf;
	
	SummaryInfoText = SummaryInfoText + NStr("vi = 'Chế độ làm việc của cơ sở thông tin';
											|ru = 'Режим работы информационной базы';
											|en = 'Infobase operation mode'; fa = 'Infobase operation mode';
											|it = 'Modalità di funzionamento del database';
											|pl = 'Tryb pracy bazy informacyjnej';
											|tr = 'Infobase çalışma modu.'")+ " - "
		+ WorkMode;
	SummaryInfoFileName = Context.TempFilesDir + "SummaryInformation.txt";
	
	SummaryInfoText = SummaryInfoText + Chars.LF 
		+ TechnicalInformation.TechnicalInfoOnExtensionsAndSubsystemsVersions + Chars.LF;
	SummaryInformation = GetBinaryDataFromString(SummaryInfoText);
	SummaryInformation.Write(SummaryInfoFileName);
	FilesForDeletion.Add(SummaryInfoFileName);
	RecordZIP.Add(SummaryInfoFileName);
	
	LogFileName = Context.TempFilesDir + "EventLog.xml";
	EventLog = TechnicalInformation.EventLog; // BinaryData
	EventLog.Write(LogFileName); // APK:287
	FilesForDeletion.Add(LogFileName);
	RecordZIP.Add(LogFileName); 
	
	CompletionContext = New Structure;
	CompletionContext.Insert("SummaryInfoFileName", SummaryInfoFileName);
	RecordZIP.Write();
	For Each FileToDelete In FilesForDeletion Do
		DeleteFiles(FileToDelete);
	EndDo;
	CompletionNotification = New CallbackDescription("SummaryInfoAfterAddInObtainedAndScanErrorDeleted", 
		ThisObject, Context);
	DeleteScanError(Attachable_Module, CompletionNotification);
#EndIf
EndProcedure

Procedure SummaryInfoAfterAddInObtainedAndScanErrorDeleted(Result, Context) Export
	If Context.NotificationAfterTechnicalInfoObtained <> Undefined Then
		RunCallback(Context.NotificationAfterTechnicalInfoObtained);
	EndIf; 
EndProcedure

#EndRegion

#EndRegion

#Region FilesAndVersionsDataDeletion

Procedure DeleteData(CompletionHandler, FileOrVersion, UUID) Export
	
	If Not ValueIsFilled(FileOrVersion) Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("FileOrVersion",           FileOrVersion);
	Context.Insert("CompletionHandler",    CompletionHandler);
	Context.Insert("UUID", UUID);
	
	If TypeOf(FileOrVersion) <> Type("CatalogRef.FilesVersions") Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Xóa vĩnh viễn tệp %1?';
				|ru = 'Удалить файл %1 без возможности восстановления?';
				|en = 'Do you want to delete the %1 file permanently?'; fa = 'Do you want to delete the %1 file permanently?';
				|it = 'Eliminare il file %1 senza possibilità di ripristino?';
				|pl = 'Usunąć plik %1 bez możliwości odzyskiwania?';
				|tr = '%1 dosyası kalıcı olarak silinsin mi?'"),
			String(FileOrVersion));
		TitleText = NStr("vi = 'Xóa tệp';
						|ru = 'Удаление файла';
						|en = 'Delete file'; fa = 'حذف فایل';
						|it = 'Cancellazione file';
						|pl = 'Usuń plik';
						|tr = 'Dosya silme'");
	Else
		QueryText   = NStr("vi = 'Xóa phiên bản tệp mà không phục hồi?';
							|ru = 'Удалить версию файла без возможности восстановления?';
							|en = 'Do you want to delete the file version permanently?'; fa = 'Do you want to delete the file version permanently?';
							|it = 'Eliminare la versione del file senza possibilità di ripristino?';
							|pl = 'Usunąć wersję pliku bez możliwości przywrócenia?';
							|tr = 'Dosyanın sürümü kalıcı olarak silinsin mi?'");
		TitleText = NStr("vi = 'Xóa bỏ phiên bản tệp';
						|ru = 'Удаление версии файла';
						|en = 'Delete file version'; fa = 'Delete file version';
						|it = 'Eliminazione della versione del file';
						|pl = 'Usunięcie wersji pliku';
						|tr = 'Dosya sürümünün silinmesi'");
	EndIf;
	
	ShowQueryBox(New CallbackDescription("DeleteDataAfterRespondQuestion", ThisObject, Context),
		QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No, TitleText, DialogReturnCode.No);
	
EndProcedure

Procedure DeleteDataAfterRespondQuestion(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Result = FilesOperationsInternalServerCall.FilesDeletionResult(
		CommonClientServer.ValueInArray(Context.FileOrVersion),
		Context.UUID);
	Result = Result[Context.FileOrVersion];
	
	If Result.Files.Count() > 0 Then
		Result.Insert("FileToRemoveIndex", 0);
		Result.Insert("CompletionHandler", Context.CompletionHandler);
		StartRemoveFileFromCache(Result);
	Else
		NotifyOfDataDeletion(Context.CompletionHandler, Result.WarningText);
	EndIf;
	
EndProcedure

Procedure StartRemoveFileFromCache(Context)
	
	Notification = New CallbackDescription("AfterRemoveFileFromCache", ThisObject, Context);
	DeleteFileFromWorkingDirectory(Notification, Context.Files[Context.FileToRemoveIndex], True);
	
EndProcedure

Procedure AfterRemoveFileFromCache(DeletionResult, Context) Export
	
	If Context.FileToRemoveIndex < Context.Files.Count() - 1 Then
		Context.FileToRemoveIndex = Context.FileToRemoveIndex + 1;
		StartRemoveFileFromCache(Context);
		Return;
	EndIf;
	
	NotifyOfDataDeletion(Context.CompletionHandler, Context.WarningText)
	
EndProcedure

Procedure NotifyOfDataDeletion(CompletionHandler, WarningText)
	
	Notify("Write_File", FileWriteNotificationParameters());
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(CompletionHandler, WarningText);
	ElsIf CompletionHandler <> Undefined Then
		RunCallback(CompletionHandler);
	EndIf;
	
EndProcedure

Procedure ChangeFilterByDeletionMark(Area, CommandButton) Export
	
	CommandButton.Check = Not CommandButton.Check;
	CommonClientServer.ChangeFilterItems(Area, "DeletionMark",
		"HideDeletionMarkByDefault", False, DataCompositionComparisonType.Equal,
		Not CommandButton.Check, DataCompositionSettingsItemViewMode.Inaccessible);
		
EndProcedure

Procedure DeleteFilesData(CompletionHandler, FilesOrVersions, UUID) Export
	
	If FilesOrVersions.Count() = 0 Then
		RunCallback(CompletionHandler, Undefined);
	EndIf;
	
	Context = New Structure;
	Context.Insert("FilesOrVersions",           FilesOrVersions);
	Context.Insert("CompletionHandler",    CompletionHandler);
	Context.Insert("UUID", UUID);
	
	FileOrVersion = FilesOrVersions[0];
	If FilesOrVersions.Count() = 1 Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Xóa vĩnh viễn tệp %1?';
				|ru = 'Удалить файл %1 без возможности восстановления?';
				|en = 'Do you want to delete the %1 file permanently?'; fa = 'Do you want to delete the %1 file permanently?';
				|it = 'Eliminare il file %1 senza possibilità di ripristino?';
				|pl = 'Usunąć plik %1 bez możliwości odzyskiwania?';
				|tr = '%1 dosyası kalıcı olarak silinsin mi?'"),
			String(FileOrVersion));
		TitleText = NStr("vi = 'Xóa tệp';
						|ru = 'Удаление файла';
						|en = 'Delete file'; fa = 'حذف فایل';
						|it = 'Cancellazione file';
						|pl = 'Usuń plik';
						|tr = 'Dosya silme'");
	Else
		QueryText = NStr("vi = 'Xóa vĩnh viễn tệp?';
						|ru = 'Удалить файлы без возможности восстановления?';
						|en = 'Do you want to delete the files permanently?'; fa = 'Do you want to delete the files permanently?';
						|it = 'Удалить файлы без возможности восстановления?';
						|pl = 'Do you want to delete the files permanently?';
						|tr = 'Dosyalar kalıcı olarak silinsin mi?'");
		TitleText = NStr("vi = 'Xóa tệp';
						|ru = 'Удаление файлов';
						|en = 'Delete files'; fa = 'حذف فایل‌ها';
						|it = 'Удаление файлов';
						|pl = 'Delete files';
						|tr = 'Dosyaların silinmesi'");
	EndIf;
	
	ShowQueryBox(New CallbackDescription("DeleteFilesDataAfterQuestionAnswered", ThisObject, Context),
		QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No, TitleText, DialogReturnCode.No);
EndProcedure

Procedure DeleteFilesDataAfterQuestionAnswered(Response, Context) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DeletionResults = FilesOperationsInternalServerCall.FilesDeletionResult(
		Context.FilesOrVersions, Context.UUID);
		
	Warnings = New Map;
	Result = New Structure("Files,FileToRemoveIndex,CompletionHandler,WarningText", 
		New Array, 0);
	
	For Each DeletionResult In DeletionResults Do
		If DeletionResult.Value.Files.Count() > 0 Then
			CommonClientServer.SupplementArray(Result.Files, DeletionResult.Value.Files);
		Else
			Warnings.Insert(DeletionResult.Key, DeletionResult.Value.WarningText);
		EndIf;
	EndDo;
	
	If Result.Files.Count() > 0 Then
		
		Result.Insert("FileToRemoveIndex", 0);
		Result.Insert("CompletionHandler", Context.CompletionHandler);
		
		StartRemoveFileFromCache(Result);
		
	EndIf;
	
	If Warnings.Count() > 0 Then
		WarningText = "";
		For Each Warning In Warnings Do
			WarningText = ?(WarningText = "", "", Chars.LF)
				+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1: %2';
																				|ru = '%1: %2';
																				|en = '%1: %2'; fa = '%1: %2';
																				|it = '%1: %2';
																				|pl = '%1: %2';
																				|tr = '%1: %2'"), 
					Warning.Key, Warning.Value);
		EndDo;
		NotifyOfDataDeletion(Context.CompletionHandler, WarningText);
	EndIf;
	
EndProcedure
	
#EndRegion

Procedure CheckDirAvailabilityAfterCreated(TestDirectoryName, Context) Export
	
	Notification = New CallbackDescription("CheckDirAvailabilityAfterDeleted", ThisObject, 
		Context, "CheckDirAvailabilityDeletionError", ThisObject);
	BeginDeletingFiles(Notification, TestDirectoryName);
	
EndProcedure

Function DirAvailabilityCheckResult()
	Result = New Structure;
	Result.Insert("Success", False);
	Result.Insert("Create", False);
	Result.Insert("Delete", False);
	Result.Insert("ErrorInfo");
	Return Result;
EndFunction

Procedure CheckDirAvailabilityAfterDeleted(Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.Success = True;
	Result.Create = True;
	Result.Delete = True;
	
	RunCallback(Context.NotificationOfResult, Result);
	
EndProcedure

Procedure CheckDirAvailabilityCreationError(ErrorInfo, StandardProcessing, Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.ErrorInfo = ErrorInfo;
	StandardProcessing = False;
	
	RunCallback(Context.NotificationOfResult, Result);

EndProcedure

Procedure CheckDirAvailabilityDeletionError(ErrorInfo, StandardProcessing, Context) Export
	
	Result = DirAvailabilityCheckResult();
	Result.Create = True;
	Result.ErrorInfo = ErrorInfo;
	StandardProcessing = False;
	
	RunCallback(Context.NotificationOfResult, Result);

EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
Procedure AfterFilesRecovered(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProgressDetailedInfo = GetFromTempStorage(Result.ResultAddress);
		If ProgressDetailedInfo.Processed < ProgressDetailedInfo.Total Then
			Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã phục hồi %1 trong số %2 thông tin bị hỏng về tệp. Xem chi tiết trong nhật ký sự kiện.';
					|ru = 'Восстановлено %1 из %2 поврежденных сведений о файлах. Подробности см. в журнале регистрации.';
					|en = 'Restored file info: %1 out of %1. For details, see Event log.'; fa = 'Restored file info: %1 out of %1. For details, see Event log.';
					|it = 'Восстановлено %1 из %2 поврежденных сведений о файлах. Подробности см. в журнале регистрации.';
					|pl = 'Restored file info: %1 out of %1. For details, see Event log.';
					|tr = 'Hasarlı dosya bilgilerinin %2 üzerinden %1 kadarı geri yüklendi. Ayrıntılar için kayıt günlüğüne bakın.'"),
				ProgressDetailedInfo.Processed, ProgressDetailedInfo.Total);
			ShowUserNotification(NStr("vi = 'Phục hồi thông tin về các tệp';
										|ru = 'Восстановление сведений о файлах';
										|en = 'Restore file info'; fa = 'Restore file info';
										|it = 'Восстановление сведений о файлах';
										|pl = 'Restore file info';
										|tr = 'Dosya bilgilerinin geri yüklenmesi'"),,
				Message, PictureLib.DialogExclamation, UserNotificationStatus.Important);
		ElsIf ProgressDetailedInfo.Total > 0 Then
			ShowUserNotification(NStr("vi = 'Phục hồi thông tin về các tệp';
										|ru = 'Восстановление сведений о файлах';
										|en = 'Restore file info'; fa = 'Restore file info';
										|it = 'Восстановление сведений о файлах';
										|pl = 'Restore file info';
										|tr = 'Dosya bilgilerinin geri yüklenmesi'"),,
				NStr("vi = 'Đã phục hồi thông tin về các tệp. Tạo lại báo cáo';
					|ru = 'Сведения о файлах восстановлены. Переформирование отчета...';
					|en = 'File info is restored. Updating the report…'; fa = 'File info is restored. Updating the report…';
					|it = 'Сведения о файлах восстановлены. Переформирование отчета...';
					|pl = 'File info is restored. Updating the report…';
					|tr = 'Dosya bilgileri geri yüklendi. Rapor yeniden oluşturuluyor...'"));
		Else
			ShowMessageBox(, NStr("vi = 'Không có tệp bị hỏng để khôi phục.';
									|ru = 'Нет поврежденных файлов для восстановления.';
									|en = 'No corrupted files to recover.'; fa = 'No corrupted files to recover.';
									|it = 'Нет поврежденных файлов для восстановления.';
									|pl = 'No corrupted files to recover.';
									|tr = 'Kurtarılacak hasarlı dosya yok.'"));
			Return;
		EndIf;
		
		AdditionalParameters.ReportForm.ComposeResult();
		
	ElsIf Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
	EndIf;
	
EndProcedure

Function FileNameAndExtension(File)
#If MobileClient Then
	PresentationOnMobileDevice = File.GetMobileDeviceLibraryFilePresentation();
	FileExtention = CommonClientServer.GetFileNameExtension(PresentationOnMobileDevice);
	FileNameWithoutExtension = StrReplace(PresentationOnMobileDevice, "." + FileExtention, "");
#Else
	FileExtention = CommonClientServer.ExtensionWithoutPoint(File.Extension);
	FileNameWithoutExtension = File.BaseName;
#EndIf
	Result = New Structure;
	Result.Insert("FileExtention", FileExtention);
	Result.Insert("FileNameWithoutExtension", FileNameWithoutExtension);
	
	Return Result;
EndFunction

// Generates technical information for support.
//
// Parameters:
//  ErrorDescription       - String - basic description of the error.
//  CompletionHandler - CallbackDescription, Undefined - The End handler that is called after
//                                                            the technical information is generated. As a result
//                                                            , a Structure with fields is returned:
//                                                              * TechnicalInformation - String - technical information.
//                                                              * AdditionalFiles - Array of See SupportRequestsInternalClient.AdditionalFileData.
//
Procedure GenerateSupportInformation(ErrorDescription, CompletionHandler = Undefined) Export

#If Not WebClient Then
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ErrorDescription", ErrorDescription);
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	CallbackDescription = New CallbackDescription(
		"ContinueGenerateSupportInformation",
		ThisObject,
		AdditionalParameters);
	
	InitAddIn(CallbackDescription, True);
	
#EndIf
	
EndProcedure

Procedure ContinueGenerateSupportInformation(Result, AdditionalParameters) Export
	
	ResultOfFormation = New Structure;
	ResultOfFormation.Insert("TechnologicalInfo", "");
	ResultOfFormation.Insert("AdditionalFiles", New Array);
	
	SupportInformation = New Array;
	SupportInformation.Add(StandardSubsystemsClient.SupportInformation());
	SupportInformation.Add(NStr("vi = 'Thông tin kỹ thuật';
								|ru = 'Техническая информация';
								|en = 'Technical information'; fa = 'اطلاعات فنی';
								|it = 'Informazione tecnica';
								|pl = 'Informacja techniczna';
								|tr = 'Teknik bilgi'"));
	SupportInformation.Add(AdditionalParameters.ErrorDescription);
	SupportInformation.Add("");
	
	Attachable_Module = Undefined;
	
	If Result.Attached Then
		
		Try
			
			Attachable_Module = Result.Attachable_Module;
			VersionComponents = Attachable_Module.Version();
			
			AddInInformation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phiên bản cấu phần %1: %2';
					|ru = 'Версия компоненты %1: %2';
					|en = 'The %1 add-in version: %2'; fa = 'The %1 add-in version: %2';
					|it = 'Версия компоненты %1: %2';
					|pl = 'The %1 add-in version: %2';
					|tr = '%1 eklentisinin sürümü: %2'"), "ImageScan", VersionComponents);
			
			SupportInformation.Add(AddInInformation);
			SupportInformation.Add("");
			
		Except
			
			DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteScanLog(NStr("vi = 'Phiên bản cấu phần';
								|ru = 'Версия компоненты';
								|en = 'Add-in version'; fa = 'نسخه افزونه';
								|it = 'Add-in version';
								|pl = 'Add-in version';
								|tr = 'Eklenti sürümü'"), DetailErrorDescription, True);
			
		EndTry;
		
	EndIf;
	
	WorkMode = ApplicationModeForSupport();
	SupportInformation.Add(WorkMode);
	
	TechnicalInformation = FilesOperationsInternalServerCall.TechnicalInformation();
	SupportInformation.Add(TechnicalInformation.TechnicalInfoOnExtensionsAndSubsystemsVersions);
	
	ResultOfFormation.TechnologicalInfo = StrConcat(SupportInformation, Chars.LF);
	
	LoggingFileData = AddInLoggingFileDataForSupport();
	
	If LoggingFileData <> Undefined Then
		ResultOfFormation.AdditionalFiles.Add(LoggingFileData);
	EndIf;
	
	RunCallback(AdditionalParameters.CompletionHandler, ResultOfFormation);
	DeleteScanError(Attachable_Module);
	
EndProcedure

Function AddInLoggingFileDataForSupport()
	
	Result = Undefined;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.SupportRequests") Then
		Return Result;
	EndIf;
	
	ScanLogParameters = FilesOperationsInternalServerCall.ScanLogParameters(
		ClientID());
	
	LoggingFileName = ScanLogParameters.NameOfLogFile;
	LoggingFile = New File(LoggingFileName);
	
	If LoggingFile.Exists() Then
		
		LogsStorageAddress = PutToTempStorage(
			New BinaryData(LoggingFileName),
			New UUID);
		
		// The technical support service supports attachments in the "txt" format.
		ModuleSupportRequestsInternalClient = CommonClient.CommonModule(
			"SupportRequestsInternalClient");
		
		Result = ModuleSupportRequestsInternalClient.AdditionalFileData(
			LogsStorageAddress,
			NStr("vi = 'ImageScan.txt';
				|ru = 'ImageScan.txt';
				|en = 'ImageScan.txt'; fa = 'ImageScan.txt';
				|it = 'ImageScan.txt';
				|pl = 'ImageScan.txt';
				|tr = 'ImageScan.txt'"));
		
	Else
		
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại tệp nhật ký cấu phần scan: %1';
				|ru = 'Файл журнала компоненты сканирования не существует: %1.';
				|en = 'The scanning add-in log file does not exist: %1.'; fa = 'The scanning add-in log file does not exist: %1.';
				|it = 'The scanning add-in log file does not exist: %1.';
				|pl = 'The scanning add-in log file does not exist: %1.';
				|tr = 'Tarama eklentisinin günlük dosyası mevcut değil %1.'"),
			LoggingFileName);
		
		WriteScanLog(NStr("vi = 'Tệp cấu phần';
							|ru = 'Файл компоненты';
							|en = 'Add-in file'; fa = 'فایل افزونه';
							|it = 'Add-in file';
							|pl = 'Add-in file';
							|tr = 'Eklenti dosyası'"), Comment, True);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ApplicationModeForSupport()
	
	Result = "";
	
	If CommonClient.FileInfobase() Then
		If CommonClient.ClientConnectedOverWebServer() Then
			Result = NStr("vi = 'Chế độ làm việc của cơ sở thông tin: File-server qua web-server';
							|ru = 'Режим работы информационной базы: Файловый через веб-сервер';
							|en = 'Mode: File infobase via web server'; fa = 'Mode: File infobase via web server';
							|it = 'Mode: File infobase via web server';
							|pl = 'Mode: File infobase via web server';
							|tr = 'Infobase''in çalışma modu: Web sunucusu üzerinden dosya tabanlı'");
		Else
			Result = NStr("vi = 'Chế độ làm việc của cơ sở thông tin: File-server';
							|ru = 'Режим работы информационной базы: Файловый';
							|en = 'Mode: File infobase'; fa = 'Mode: File infobase';
							|it = 'Mode: File infobase';
							|pl = 'Mode: File infobase';
							|tr = 'Infobase''in çalışma modu: Dosya'");
		EndIf;
	Else
		Result = NStr("vi = 'Chế độ làm việc của cơ sở thông tin: Client-server';
						|ru = 'Режим работы информационной базы: Клиент-серверный';
						|en = 'Mode: Client/server infobase'; fa = 'Mode: Client/server infobase';
						|it = 'Mode: Client/server infobase';
						|pl = 'Mode: Client/server infobase';
						|tr = 'Infobase''in çalışma modu: İstemci/sunucu'");
	EndIf;
	
	Return Result
	
EndFunction

Procedure UpdateAttachedFilesLists(FileData)

	If Not FileData.Property("UpdateFilesListsOnForms") Then
		Return;
	EndIf;

	If FileData.UpdateFilesListsOnForms Then
		FileWriteNotificationParameters = FileWriteNotificationParameters("AreFilesChangedWhenUsingArchive");
		
		If TypeOf(FileData.Ref) = Type("CatalogRef.Files") And ValueIsFilled(FileData.Version) Then
			FileRef = FileData.Version;
		Else
			FileRef = FileData.Ref;
		EndIf;
		
		Notify("Write_File", FileWriteNotificationParameters, FileRef);
	EndIf;

EndProcedure

#EndRegion