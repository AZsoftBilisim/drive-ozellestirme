///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region FilesImportFromFileSystem

// Continues the procedure "FileSystemClient.ShowPutFile".
Procedure ShowPutFileOnAttach1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	Interactively = Context.Interactively;
	
	If Not ExtensionAttached
		And Not Interactively Then
		Raise NStr("vi = 'Không thể kết nhập tệp mà không có phần mở rộng được cài đặt để làm việc với 1C:Enterprise.';
					|ru = 'Невозможно загрузить файл без установленного расширения для работы с 1С:Предприятием.';
					|en = 'Cannot import the file as 1C:Enterprise Extension is not installed.'; fa = 'Cannot import the file as 1C:Enterprise Extension is not installed.';
					|it = 'Невозможно загрузить файл без установленного расширения для работы с 1С:Предприятием.';
					|pl = 'Cannot import the file as 1C:Enterprise Extension is not installed.';
					|tr = '1C:Enterprise ile çalışmak üzere yüklenmiş uzantı olmadan dosya yüklemek mümkün değildir.'");
	EndIf;
		
	Try
		StartProcessingPuttingFiles(Context);
	Except
		Dialog               = Context.Dialog; // FileDialog
		Interactively         = Context.Interactively;
		CompletionHandler = Context.CompletionHandler;
	
		ProcessingResultsParameters = New Structure;
		ProcessingResultsParameters.Insert("MultipleChoice",   Dialog.Multiselect);
		ProcessingResultsParameters.Insert("CompletionHandler", CompletionHandler);
		
		CallbackDescription = New CallbackDescription(
			"AfterWarnedAboutFileUnavailability", ThisObject, ProcessingResultsParameters);
		ErrorInfo = ErrorInfo();
		ErrorDescription = ErrorInfo.Cause.Description;
		If StrFind(ErrorDescription, "32(0x00000020)") Then 
			ShowMessageBox(CallbackDescription, NStr("vi = 'Kết thúc công việc với tệp trong ứng dụng khác.';
													|ru = 'Завершите работу с файлом в другом приложении.';
													|en = 'Complete the operation with the file in another application.'; fa = 'Complete the operation with the file in another application.';
													|it = 'Завершите работу с файлом в другом приложении.';
													|pl = 'Complete the operation with the file in another application.';
													|tr = 'Başka bir uygulamada dosya yönetimi tamamlandı.'"),, 
				NStr("vi = 'Tệp đang mở trong ứng dụng khác';
					|ru = 'Файл открыт в другом приложении';
					|en = 'The file is opened in another application'; fa = 'The file is opened in another application';
					|it = 'Файл открыт в другом приложении';
					|pl = 'The file is opened in another application';
					|tr = 'Dosya başka bir uygulamada açık'"));
				Return;
		EndIf;

		Raise;
		
	EndTry;

EndProcedure

// Runs after a warning about an unavailable file.
// 
// Parameters:
//  ProcessingResultsParameters - Structure:
//   * MultipleChoice - Boolean
//   * CompletionHandler - CallbackDescription
//
Procedure AfterWarnedAboutFileUnavailability(ProcessingResultsParameters) Export

	If ProcessingResultsParameters.MultipleChoice Then
		ProcessPutFilesResult(Undefined, ProcessingResultsParameters);
	Else
		ProcessPutFileResult(False, Undefined, Undefined,	ProcessingResultsParameters);
	EndIf;
	
EndProcedure
	
Procedure StartProcessingPuttingFiles(Context)
	
	Dialog               = Context.Dialog; // FileDialog - 
	Interactively         = Context.Interactively;
	FilesToUpload     = Context.FilesToUpload;
	FormIdentifier   = Context.FormIdentifier;
	CompletionHandler = Context.CompletionHandler;
	
	ProcessingResultsParameters = New Structure;
	ProcessingResultsParameters.Insert("MultipleChoice",   Dialog.Multiselect);
	ProcessingResultsParameters.Insert("CompletionHandler", CompletionHandler);
			
	If Dialog.Multiselect Then
		
		Files = ?(Interactively, Dialog, FilesToUpload);
		CallbackDescription = New CallbackDescription(
			"ProcessPutFilesResult", ThisObject, ProcessingResultsParameters);
		
		If ValueIsFilled(FormIdentifier) Then
			BeginPuttingFiles(CallbackDescription, Files, Interactively,
				FormIdentifier, Context.AcrtionBeforeStartPutFiles);
		Else
			BeginPuttingFiles(CallbackDescription, Files, Interactively, ,
				Context.AcrtionBeforeStartPutFiles);
		EndIf;
		
	Else
		
		File = ?(Interactively, Dialog, FilesToUpload.Name);
		CallbackDescription = New CallbackDescription(
			"ProcessPutFileResult", ThisObject, ProcessingResultsParameters);
		
		If ValueIsFilled(FormIdentifier) Then
			BeginPutFile(CallbackDescription, FilesToUpload.Location, File,
				Interactively, FormIdentifier, Context.AcrtionBeforeStartPutFiles);
		Else
			BeginPutFile(CallbackDescription, FilesToUpload.Location, File,
				Interactively, , Context.AcrtionBeforeStartPutFiles);
		EndIf;
		
	EndIf;
EndProcedure

// Putting files completion.
Procedure ProcessPutFilesResult(PlacedFiles, ProcessingResultsParameters) Export
	
	ProcessPutFileResult(PlacedFiles <> Undefined, PlacedFiles, Undefined,
		ProcessingResultsParameters);
	
EndProcedure

// Putting file completion.
Procedure ProcessPutFileResult(SelectionDone, AddressOrSelectionResult, SelectedFileName,
		ProcessingResultsParameters) Export
	
	If SelectionDone = True Then
		
		If TypeOf(AddressOrSelectionResult) = Type("Array") Then
			
			PutFilesToServe = New Array;
			For Each File In AddressOrSelectionResult Do
				
				FileProperties = New Structure("Name, FullName, Location");
				FillPropertyValues(FileProperties, File);
				
				FileProperties.Insert("FileName", File.Name);
				If Not IsBlankString(File.FullName) Then
					FileProperties.Name = File.FullName;
				EndIf;
				
				PutFilesToServe.Add(FileProperties);
				
			EndDo;
			
		Else
			
			PutFilesToServe = New Structure;
			PutFilesToServe.Insert("Location", AddressOrSelectionResult);
			PutFilesToServe.Insert("Name",      SelectedFileName);
			
		EndIf;
		
	Else
		PutFilesToServe = Undefined;
	EndIf;
	
	RunCallback(ProcessingResultsParameters.CompletionHandler, PutFilesToServe);
	
EndProcedure

#EndRegion

#Region ModifiesStoredDataToFileSystem

// Continuation of procedure FileSystemClient.ShowDownloadFiles procedure.
Procedure ShowDownloadFilesOnAttach1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		If Context.Interactively Then
			ShowDownloadFilesToDirectory(Context);
		ElsIf Not IsBlankString(Context.Dialog.Directory)Then
			Context.Dialog = Context.Dialog.Directory;
			ShowDownloadFilesToDirectory(Context);
		Else
			
			DirectoryReceiptNotification = New CallbackDescription(
				"ShowDownloadFilesAfterGetTempFilesDirectory", ThisObject, Context);
			BeginGettingTempFilesDir(DirectoryReceiptNotification);
				
		EndIf;
		
	Else
		
		For Each FileToReceive In Context.FilesToObtain Do
			GetFile(FileToReceive.Location, FileToReceive.Name, True);
		EndDo;
		
		If Context.CompletionHandler <> Undefined Then
			RunCallback(Context.CompletionHandler, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.ShowDownloadFiles procedure.
Procedure ShowDownloadFilesAfterGetTempFilesDirectory(TempFilesDirName, Context) Export
	
	Context.Dialog = TempFilesDirName;
	ShowDownloadFilesToDirectory(Context);
	
EndProcedure

// Continuation of procedure FileSystemClient.ShowDownloadFiles procedure.
Procedure ShowDownloadFilesToDirectory(Context)
	
#If MobileClient Then
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Title = NStr("vi = 'Hãy chọn thư mục để lưu';
						|ru = 'Выберите каталог для сохранения';
						|en = 'Select a directory for saving'; fa = 'Select a directory for saving';
						|it = 'Select a directory for saving';
						|pl = 'Select a directory for saving';
						|tr = 'Kaydedilecek dizini seçin'");
	CallbackDescription = New CallbackDescription("AfterSelectingDirectory", ThisObject, Context);
	Dialog.Show(CallbackDescription);
	
#Else
	
	CallbackOnCompletion = New CallbackDescription("NotifyGetFilesCompletion", ThisObject, Context);
	BeginGettingFiles(CallbackOnCompletion, Context.FilesToObtain, Context.Dialog, Context.Interactively);
	
#EndIf

EndProcedure

Procedure AfterSelectingDirectory(ReceivedDirectory, Context) Export
	
	If ReceivedDirectory = Undefined Then
		Return;
	EndIf;
	
	DirectoryName = ReceivedDirectory.Get(0);
	
	CallbackOnCompletion = New CallbackDescription("NotifyGetFilesCompletion", ThisObject, Context);
	
	GetFilesArchiveParameters       = New GetFilesArchiveParameters();
	GetFilesArchiveParameters.Mode = GetFilesArchiveMode.GetArchiveWhenRequired;
	
	BeginGetFilesFromServer(CallbackOnCompletion, Context.FilesToObtain, DirectoryName, GetFilesArchiveParameters);
	
EndProcedure

// Continuation of procedure FileSystemClient.ShowDownloadFiles procedure.
Procedure NotifyGetFilesCompletion(ObtainedFiles, AdditionalParameters) Export
	
	If AdditionalParameters.CompletionHandler <> Undefined Then
		RunCallback(AdditionalParameters.CompletionHandler, ObtainedFiles);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpeningFiles

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileAfterSaving(SavedFiles, OpeningParameters) Export
	
	If SavedFiles = Undefined Then
		RunCallback(OpeningParameters.CompletionHandler, False);
	Else
		
		FileDetails = 
			?(TypeOf(SavedFiles) = Type("Array"), 
				SavedFiles[0], 
				SavedFiles);
		
		OpeningParameters.Insert("PathToFile", FileDetails.FullName);
		CompletionHandler = New CallbackDescription(
			"OpenFileAfterEditingCompletion", ThisObject, OpeningParameters);
		
		OpenFileInViewer(FileDetails.FullName, CompletionHandler, OpeningParameters.ForEditing);
		
	EndIf;
	
EndProcedure

// Continues the FileSystemClient.OpenFile procedure.
// Opens the file in the application associated with the file type.
// Prevents executable files from opening.
//
// Parameters:
//  PathToFile        - String - The full path to the file to open.
//  Notification        - CallbackDescription - Notifies about file opening attempt.
//                    If not specified and an error occurs, the method returns a warning.:
//   * ApplicationStarted      - Boolean - True if the external application opened successfully.
//   * AdditionalParameters - Arbitrary - a value that was specified on creating the NotifyDescription object.
//  ForEditing - Boolean - True to open the file for editing, False otherwise.
//
Procedure OpenFileInViewer(PathToFile, Val Notification = Undefined,
		Val ForEditing = False)
	
	FileInfo3 = New File(PathToFile);
	
	Context = New Structure;
	Context.Insert("FileInfo3",          FileInfo3);
	Context.Insert("Notification",        Notification);
	Context.Insert("ForEditing", ForEditing);
	
	Notification = New CallbackDescription(
		"OpenFileInViewerAfterCheck1CEnterpriseExtension", ThisObject, Context);
	
	SuggestionText = NStr("vi = 'Để mở tệp, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для открытия файла установите расширение для работы с 1С:Предприятием.';
							|en = 'To open the file, install 1C:Enterprise extension.'; fa = 'To open the file, install 1C:Enterprise extension.';
							|it = 'Per aprire il file installare l''estensione per il lavoro con 1C:Enterprise.';
							|pl = 'Aby otworzyć plik zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
							|tr = 'Dosyayı açmak için 1C:Enterprise ile çalışma uzantısını yükleyin.'");
	FileSystemClient.Attach1CEnterpriseExtension(Notification, SuggestionText, False);
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheck1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	If ExtensionAttached Then
		
		Notification = New CallbackDescription(
			"OpenFileInViewerAfterCheckIfExists", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingExistence(Notification);
		
	Else
		
		ErrorDescription = NStr("vi = 'Chưa cài đặt phần mở rộng để làm việc với 1C:Enterprise, không thể mở tệp.';
								|ru = 'Не установлено расширение для работы с 1С:Предприятием, открытие файла недоступно.';
								|en = 'Cannot open the file because 1C:Enterprise Extension is not installed.'; fa = 'Cannot open the file because 1C:Enterprise Extension is not installed.';
								|it = 'Non è stata installata l''estensione di lavoro con 1C:Enterprise, impossibile aprire il file.';
								|pl = 'Nie zainstalowano rozszerzenia do pracy z 1С:Enterprise, otwarcie pliku jest niedostępne.';
								|tr = '1C:Enterprise Extension yüklü olmadığı için dosya açılamıyor.'");
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheckIfExists(Exists, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	If Exists Then
		 
		Notification = New CallbackDescription(
			"OpenFileInViewerAfterCheckIsFIle", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsFile(Notification);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại tệp mở ra:
			           |%1';
			           |ru = 'Не существует открываемый файл:
			           |%1';
			           |en = 'The file to open does not exist:
			           |%1'; fa = 'The file to open does not exist:
			           |%1';
			           |it = 'Non esiste il file apribile:
			           |%1';
			           |pl = 'Nie istnieje otwieranego pliku:
			           |%1';
			           |tr = 'Açılan dosya mevcut değil:
			           |%1'"),
			FileInfo3.FullName);
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterCheckIsFIle(IsFile, Context) Export
	
	// ACC:534-off - This function provides safe startup methods.
	
	FileInfo3 = Context.FileInfo3;
	If IsFile Then
		
		If IsBlankString(FileInfo3.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tên tệp không chứa phần mở rộng:
				           |%1';
				           |ru = 'Имя файла не содержит расширения:
				           |%1';
				           |en = 'The file name is missing extension:
				           |%1.'; fa = 'The file name is missing extension:
				           |%1.';
				           |it = 'Il nome del file non contiene l''estensione:
				           |%1';
				           |pl = 'Nazwa pliku nie zawiera rozszerzenia:
				           |%1';
				           |tr = 'Dosya adı uzantı içermiyor:
				           |%1.'"),
				FileInfo3.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		If IsExecutableFileExtension(FileInfo3.Extension) Then 
			
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cấm mở các tệp thực thi:
				           |%1';
				           |ru = 'Исполняемые файлы открывать запрещено:
				           |%1';
				           |en = 'Opening executable files is disabled:
				           |%1.'; fa = 'Opening executable files is disabled:
				           |%1.';
				           |it = 'I file in esecuzione non possono essere aperti:
				           |%1';
				           |pl = 'Otwarcie wykоnywanych plików jest zabronione:
				           |%1';
				           |tr = 'Yürütülen dosyalar açılamaz: 
				           |%1'"),
				FileInfo3.FullName);
			
			OpenFileInViewerNotifyOnError(ErrorDescription, Context);
			Return;
			
		EndIf;
		
		Notification          = Context.Notification;
		WaitForCompletion = Context.ForEditing;
		
		Notification = New CallbackDescription(
			"OpenFileInViewerAfterStartApplication", ThisObject, Context,
			"OpenFileInViewerOnProcessError", ThisObject);
		BeginRunningApplication(Notification, FileInfo3.FullName,, WaitForCompletion);
		
	Else 
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại tệp mở ra:
			           |%1';
			           |ru = 'Не существует открываемый файл:
			           |%1';
			           |en = 'The file to open does not exist:
			           |%1'; fa = 'The file to open does not exist:
			           |%1';
			           |it = 'Non esiste il file apribile:
			           |%1';
			           |pl = 'Nie istnieje istniejącego pliku:
			           |%1';
			           |tr = 'Açılan dosya mevcut değil:
			           |%1'"),
			FileInfo3.FullName);
			
		OpenFileInViewerNotifyOnError(ErrorDescription, Context);
		
	EndIf;
	
	// ACC:534-on
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0);
		RunCallback(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerOnProcessError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	OpenFileInViewerNotifyOnError("", Context);
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileAfterEditingCompletion(ApplicationStarted, OpeningParameters) Export
	
	If ApplicationStarted
		And OpeningParameters.Property("AddressOfBinaryDataToUpdate") Then
		
		Notification = New CallbackDescription(
			"OpenFileAfterDataUpdateInStorage", ThisObject, OpeningParameters);
			
		BeginPutFile(Notification, OpeningParameters.AddressOfBinaryDataToUpdate,
			OpeningParameters.PathToFile, False);
		
	Else
		RunCallback(OpeningParameters.CompletionHandler, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileAfterDataUpdateInStorage(IsDataUpdated, DataAddress, FileName,
		OpeningParameters) Export
	
	If OpeningParameters.Property("DeleteAfterDataUpdate") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("IsDataUpdated", IsDataUpdated);
		AdditionalParameters.Insert("OpeningParameters", OpeningParameters);
		
		CallbackDescription = New CallbackDescription(
			"OpenFileAfterTempFileDeletion", ThisObject, AdditionalParameters);
			
		BeginDeletingFiles(CallbackDescription, FileName);
		
	Else
		RunCallback(OpeningParameters.CompletionHandler, IsDataUpdated);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileAfterTempFileDeletion(AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.OpeningParameters.CompletionHandler,
		AdditionalParameters.IsDataUpdated);
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenFile.
Procedure OpenFileInViewerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
	ApplicationStarted = False;
	RunCallback(Context.Notification, ApplicationStarted);
	
EndProcedure

// Parameters:
//  Extension - String - the Extension property of the File object.
//
Function IsExecutableFileExtension(Val Extension)
	
	Extension = Upper(Extension);
	
	// Windows
	Return Extension = ".BAT" // Batch File
		Or Extension = ".BIN" // Binary Executable
		Or Extension = ".CMD" // Command Script
		Or Extension = ".COM" // MS-DOS application.
		Or Extension = ".CPL" // Control Panel Extension
		Or Extension = ".EXE" // Executable file.
		Or Extension = ".GADGET" // Binary Executable
		Or Extension = ".HTA" // HTML Application
		Or Extension = ".INF1" // Setup Information File
		Or Extension = ".INS" // Internet Communication Settings
		Or Extension = ".INX" // InstallShield Compiled Script
		Or Extension = ".ISU" // InstallShield Uninstaller Script
		Or Extension = ".JOB" // Windows Task Scheduler Job File
		Or Extension = ".LNK" // File Shortcut
		Or Extension = ".MSC" // Microsoft Common Console Document
		Or Extension = ".MSI" // Windows Installer Package
		Or Extension = ".MSP" // Windows Installer Patch
		Or Extension = ".MST" // Windows Installer Setup Transform File
		Or Extension = ".OTM" // Microsoft Outlook macro.
		Or Extension = ".PAF" // Portable Application Installer File
		Or Extension = ".PIF" // Program Information File
		Or Extension = ".PS1" // Windows PowerShell Cmdlet
		Or Extension = ".REG" // Registry Data File
		Or Extension = ".RGS" // Registry Script
		Or Extension = ".SCT" // Windows Scriptlet
		Or Extension = ".SHB" // Windows Document Shortcut
		Or Extension = ".SHS" // Shell Scrap Object
		Or Extension = ".U3P" // U3 Smart Application
		Or Extension = ".VB"  // VBScript File
		Or Extension = ".VBE" // VBScript Encoded Script
		Or Extension = ".VBS" // VBScript File
		Or Extension = ".VBSCRIPT" // Visual Basic Script
		Or Extension = ".WS"  // Windows Script
		Or Extension = ".WSF" // Windows Script
	// Linux
		Or Extension = ".CSH" // C Shell Script
		Or Extension = ".KSH" // Unix Korn Shell Script
		Or Extension = ".OUT" // Executable file.
		Or Extension = ".RUN" // Executable file.
		Or Extension = ".SH"  // Shell Script
	// macOS
		Or Extension = ".ACTION" // Automator Action
		Or Extension = ".APP" // Executable file.
		Or Extension = ".COMMAND" // Terminal Command
		Or Extension = ".OSX" // Executable file.
		Or Extension = ".WORKFLOW" // Automator Workflow
	// Other OS
		Or Extension = ".AIR" // Adobe AIR distribution package
		Or Extension = ".COFFIE" // CoffeeScript (JavaScript) script.
		Or Extension = ".JAR" // Java archive.
		Or Extension = ".JS"  // JScript File
		Or Extension = ".JSE" // JScript Encoded File
		Or Extension = ".PLX" // Perl executable file
		Or Extension = ".PYC" // Python compiled file
		Or Extension = ".PYO"; // Python optimized code.
	
EndFunction

#EndRegion

#Region OpenExplorer

// Continuation of procedure FileSystemClient.OpenExplorer.
Procedure OpenExplorerAfterCheck1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	FileInfo3 = Context.FileInfo3;
	
	If ExtensionAttached Then
		Notification = New CallbackDescription(
			"OpenExplorerAfterCheckIfExists", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingExistence(Notification);
	Else
		ErrorDescription = NStr("vi = 'Để mở thư mục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
								|ru = 'Для того чтобы открыть папку, установите расширение для работы с 1С:Предприятием.';
								|en = 'To open the folder, install 1C:Enterprise Extension.'; fa = 'To open the folder, install 1C:Enterprise Extension.';
								|it = 'Per poter aprire la cartella, installare l''estensione per il lavoro con 1C:Enterprise.';
								|pl = 'Aby otworzyć odnośnik, zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
								|tr = 'Dosyayı açmak için 1C:Enterprise ile çalışma uzantısını yükleyin.'");
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenExplorer.
Procedure OpenExplorerAfterCheckIfExists(Exists, Context) Export 
	
	FileInfo3 = Context.FileInfo3;
	
	If Exists Then 
		Notification = New CallbackDescription(
			"OpenExplorerAfterCheckIsFIle", ThisObject, Context, 
			"OpenExplorerOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsFile(Notification);
	Else 
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại thư mục cần mở trong File Explorer:
			           |""%1""';
			           |ru = 'Каталог, который требуется открыть в проводнике, не существует:
			           |""%1""';
			           |en = 'The directory to be opened in the Explorer, does not exist:
			           |""%1""'; fa = 'The directory to be opened in the Explorer, does not exist:
			           |""%1""';
			           |it = 'La directory che richiede l''apertura nella guida è inesistente:
			           |""%1""';
			           |pl = 'Katalog, który należy otworzyć w Eksploratorze, nie istnieje:
			           |""%1""';
			           |tr = 'Gezginde açılması gereken katalog mevcut değil:
			           |""%1""'"),
			FileInfo3.FullName);
		OpenExplorerNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenExplorer.
Procedure OpenExplorerAfterCheckIsFIle(IsFile, Context) Export 
	
	// ACC:534-off - This function provides safe startup methods.
	
	FileInfo3 = Context.FileInfo3;
	
	Notification = New CallbackDescription(,,, "OpenExplorerOnProcessError", ThisObject);
	If IsFile Then
		If CommonClient.IsWindowsClient() Then
			BeginRunningApplication(Notification, "explorer.exe /select, """ + FileInfo3.FullName + """");
		Else // It is Linux or macOS.
			BeginRunningApplication(Notification, "file:///" + FileInfo3.Path);
		EndIf;
	Else // It is a directory.
		BeginRunningApplication(Notification, "file:///" + FileInfo3.FullName);
	EndIf;
	
	// ACC:534-on
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenExplorer.
Procedure OpenExplorerOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenExplorerNotifyOnError("", Context);
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenExplorer.
Procedure OpenExplorerNotifyOnError(ErrorDescription, Context)
	
	If Not IsBlankString(ErrorDescription) Then 
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#Region OpenURL

// Continuation of procedure FileSystemClient.OpenURL.
Procedure OpenURLAfterCheck1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	// ACC:534-off - This function provides safe startup methods.
	
	URL = Context.URL;
	
	If ExtensionAttached Then
		
		Notification          = Context.Notification;
		WaitForCompletion = (Notification <> Undefined);
		
		Notification = New CallbackDescription(
			"OpenURLAfterStartApplication", ThisObject, Context,
			"OpenURLOnProcessError", ThisObject);
		BeginRunningApplication(Notification, URL,, WaitForCompletion);
		
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa cài đặt phần mở rộng để làm việc với 1C:Enterprise, không thể chuyển theo tham chiếu ""%1"".';
				|ru = 'Расширение для работы с 1С:Предприятием не установлено, переход по ссылке ""%1"" невозможен.';
				|en = 'Cannot follow the link ""%1"" as 1C:Enterprise Extension is not installed.'; fa = 'Cannot follow the link ""%1"" as 1C:Enterprise Extension is not installed.';
				|it = 'Расширение для работы с 1С:Предприятием не установлено, переход по ссылке ""%1"" невозможен.';
				|pl = 'Cannot follow the link ""%1"" as 1C:Enterprise Extension is not installed.';
				|tr = '1C:Enterprise ile çalışma uzantısı yüklü değil, ""%1"" bağlantısına geçiş mümkün değildir.'"),
			URL);
		OpenURLNotifyOnError(ErrorDescription, Context);
	EndIf;
	
	// ACC:534-on
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenURL.
Procedure OpenURLAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	
	If Notification <> Undefined Then 
		ApplicationStarted = (ReturnCode = 0 Or ReturnCode = Undefined);
		RunCallback(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenURL.
Procedure OpenURLOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	OpenURLNotifyOnError("", Context);
	
EndProcedure

// Continuation of procedure FileSystemClient.OpenURL.
Procedure OpenURLNotifyOnError(ErrorDescription, Context) Export
	
	Notification = Context.Notification;
	
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then 
			ShowMessageBox(, ErrorDescription);
		EndIf;
	Else 
		ApplicationStarted = False;
		RunCallback(Notification, ApplicationStarted);
	EndIf;
	
EndProcedure

// Checks whether the passed string is a web URL.
// 
// Parameters:
//  String - String - passed URL.
// 
// Returns:
//  Boolean
// 
Function IsWebURL(String) Export
	
	Return StrStartsWith(String, "http://")  // A common connection.
		Or StrStartsWith(String, "https://");// A secure connection.
	
EndFunction

// Checks whether the passed string is a reference to the online help.
// 
// Parameters:
//  String - String - passed URL.
// 
// Returns:
//  Boolean
//
Function IsHelpRef(String) Export
	
	Return StrStartsWith(String, "v8help://");
	
EndFunction

// Checks whether the passed string is a valid reference to the protocol whitelist.
// 
// Parameters:
//  String - String - passed URL.
// 
// Returns:
//  Boolean
//
Function IsAllowedRef(String) Export
	
	Return StrStartsWith(String, "e1c:")
		Or StrStartsWith(String, "e1cib/")
		Or StrStartsWith(String, "e1ccs/")
		Or StrStartsWith(String, "v8help:")
		Or StrStartsWith(String, "http:")
		Or StrStartsWith(String, "https:")
		Or StrStartsWith(String, "mailto:")
		Or StrStartsWith(String, "tel:")
		Or StrStartsWith(String, "skype:")
		Or StrStartsWith(String, "market:")
		Or StrStartsWith(String, "itms-apps:");
	
EndFunction

#EndRegion

#Region StartApplication

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationAfterCheck1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		
		CurrentDirectory = Context.CurrentDirectory;
		
		If IsBlankString(CurrentDirectory) Then
			StartApplicationBeginRunning(Context);
		Else 
			FileInfo3 = New File(CurrentDirectory);
			Notification = New CallbackDescription(
				"StartApplicationAfterCheckIfExists", ThisObject, Context,
				"StartApplicationOnProcessError", ThisObject);
			FileInfo3.BeginCheckingExistence(Notification);
		EndIf;
		
	Else
		ErrorDescription = NStr("vi = 'Chưa cài đặt phần mở rộng để làm việc với 1C:Enterprise, không thể khởi động ứng dụng.';
								|ru = 'Не установлено расширение для работы с 1С:Предприятием, запуск приложения невозможен.';
								|en = 'Cannot start the application because 1C:Enterprise Extension is not installed.'; fa = 'Cannot start the application because 1C:Enterprise Extension is not installed.';
								|it = 'Не установлено расширение для работы с 1С:Предприятием, запуск приложения невозможен.';
								|pl = 'Cannot start the application because 1C:Enterprise Extension is not installed.';
								|tr = '1C:Enterprise ile çalışma uzantısı yüklü değil, uygulama başlatılamaz.'");
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationAfterCheckIfExists(Exists, Context) Export
	
	CurrentDirectory = Context.CurrentDirectory;
	FileInfo3 = New File(CurrentDirectory);
	
	If Exists Then 
		Notification = New CallbackDescription(
			"StartApplicationAfterCheckIsDirectory", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		FileInfo3.BeginCheckingIsDirectory(Notification);
	Else 
		CommandString = Context.CommandString;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể khởi động ứng dụng
			           |%1
			           |bởi vì không tồn tại thư mục:
					   |%2';
					   |ru = 'Не удалось запустить приложение
					   |%1
					   |т.к. папка не существует:
					   |%2';
					   |en = 'Cannot start
					   |%1
					   |as the folder does not exist:
					   |%2'; fa = 'Cannot start
			           |%1
			           |as the folder does not exist:
			           |%2';
					   |it = 'Не удалось запустить приложение
					   |%1
					   |т.к. папка не существует:
					   |%2';
					   |pl = 'Cannot start
					   |%1
					   |as the folder does not exist:
					   |%2';
					   |tr = 'Dosya mevcut olmadığından 
					   |%1
					   | uygulaması başlatılamadı:
					   |%2'"),
			CommandString, CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemInternalClient.StartFileSystemExtensionAttaching.
//
Procedure StartApplicationAfterCheckIsDirectory(IsDirectory, Context) Export
	
	If IsDirectory Then
		StartApplicationBeginRunning(Context);
	Else
		CommandString = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể khởi động ứng dụng
			           |%1
			           |vì đối tượng chỉ ra không phải là thư mục:
					   |%2';
					   |ru = 'Не удалось запустить приложение
					   |%1
					   |т.к. указанный объект не является папкой:
					   |%2';
					   |en = 'Cannot start
					   |%1
					   |as the specified object is not a folder:
					   |%2'; fa = 'Cannot start
			           |%1
			           |as the specified object is not a folder:
			           |%2';
					   |it = 'Не удалось запустить приложение
					   |%1
					   |т.к. указанный объект не является папкой:
					   |%2';
					   |pl = 'Cannot start
					   |%1
					   |as the specified object is not a folder:
					   |%2';
					   |tr = 'Belirtilen nesne klasör olmadığından 
					   |%1
					   | uygulaması başlatılamadı:
					   |%2'"),
			CommandString, CurrentDirectory);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationBeginRunning(Context)
	
	// ACC:534-off - This function provides safe startup methods.
	
	If Context.ThreadsEncoding = Undefined Then 
		Context.ThreadsEncoding = StandardStreamEncoding();
	EndIf;
	
	// Hardcode the default code page since cmd does not always take the current code page.
	If Context.ExecutionEncoding = Undefined And CommonClient.IsWindowsClient() Then 
		Context.ExecutionEncoding = "CP866";
	EndIf;

	If Context.ExecuteWithFullRights Then 
		StartApplicationWithFullRights(Context);
		Return;
	EndIf;
		
	ExecuteUsingPlatformMethod = True;
		
#If Not WebClient And Not MobileClient Then
		If CommonClient.IsWindowsClient() Then
			ExecuteUsingPlatformMethod = False; 
			CommandString = Context.CommandString;
			CurrentDirectory = Context.CurrentDirectory;
			ExecutionEncoding = Context.ExecutionEncoding;
			WaitForCompletion = Context.WaitForCompletion;
			
			CommandString = CommonInternalClientServer.TheWindowsCommandStartLine(CommandString, CurrentDirectory, WaitForCompletion, ExecutionEncoding);
			
			Try
				Shell = New COMObject("Wscript.Shell");
				ReturnCode = Shell.Run(CommandString, 0, WaitForCompletion);
				Shell = Undefined;
			Except
				Shell = Undefined;
				ErrorInfo = ErrorInfo();
				StandardProcessing = True;
				StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context);
				Return;
			EndTry;
			
			If ReturnCode = Undefined Then 
				ReturnCode = 0;
			EndIf;
			
			StartApplicationAfterStartApplication(ReturnCode, Context);
		EndIf;
#EndIf
	
	If ExecuteUsingPlatformMethod Then 
		CommandString = Context.CommandString;
		CurrentDirectory = Context.CurrentDirectory;
		WaitForCompletion = Context.WaitForCompletion;
		ExecutionEncoding = Context.ExecutionEncoding;
		
		If CommonClient.IsLinuxClient() And ValueIsFilled(ExecutionEncoding) Then
			CommandString = "LANGUAGE=" + ExecutionEncoding + " " + CommandString;
		EndIf;
		
		Notification = New CallbackDescription(
			"StartApplicationAfterStartApplication", ThisObject, Context,
			"StartApplicationOnProcessError", ThisObject);
		BeginRunningApplication(Notification, CommandString, CurrentDirectory, WaitForCompletion);
	EndIf;
	// ACC:534-on
	
EndProcedure

// Returns the encoding of the standard output and error streams for the current OS.
//
// Returns:
//  TextEncoding
//
Function StandardStreamEncoding()
	
	Return ?(CommonClient.IsWindowsClient(), "CP866", "UTF-8");
	
EndFunction

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationAfterStartApplication(ReturnCode, Context) Export 
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		Return;
	EndIf;
		
	Result = ApplicationStartResult();
	If Context.WaitForCompletion And ReturnCode = Undefined Then
		Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra tình huống bất thường khi khởi động ứng dụng
				|%1';
				|ru = 'Возникла непредвиденная ситуация при запуске приложения
				|%1';
				|en = 'An unexpected error occurred upon the startup of
				|%1'; fa = 'An unexpected error occurred upon the startup of
				|%1';
				|it = 'Возникла непредвиденная ситуация при запуске приложения
				|%1';
				|pl = 'An unexpected error occurred upon the startup of
				|%1';
				|tr = '
				| %1 Uygulama başlatılırken öngörülemeyen bir durum oluştu:'"),
			Context.CommandString);
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra tình huống bất thường khi khởi động ứng dụng:
				|Xâu ký tự khởi động: %1
				|Thư mục hiện tại: %2
				|Mã phản hồi: %3
				|Đợi hoàn tất: %4';
				|ru = 'Возникла непредвиденная ситуация при запуске приложения:
				|Строка запуска: %1
				|Текущий каталог: %2
				|Код возврата: %3
				|Дождаться завершения: %4';
				|en = 'An unexpected error occurred upon the startup:
				|Command line: %1
				|Directory: %2
				|Return code: %3
				|Wait for completion: %4'; fa = 'An unexpected error occurred upon the startup:
				|Command line: %1
				|Directory: %2
				|Return code: %3
				|Wait for completion: %4';
				|it = 'Возникла непредвиденная ситуация при запуске приложения:
				|Строка запуска: %1
				|Текущий каталог: %2
				|Код возврата: %3
				|Дождаться завершения: %4';
				|pl = 'An unexpected error occurred upon the startup:
				|Command line: %1
				|Directory: %2
				|Return code: %3
				|Wait for completion: %4';
				|tr = 'Uygulama başlatılırken beklenmeyen bir durum oluştu:
				|Başlat dizesi: %1
				|Geçerli dizin: %2
				|Dönüş kodu: %3
				|Tamamlanmayı bekleyin:%4'"),
			Context.CommandString,
			Context.CurrentDirectory,
			ReturnCode,
			Context.WaitForCompletion);
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Phân hệ chuẩn';
				|ru = 'Стандартные подсистемы';
				|en = 'Standard subsystems'; fa = 'زیرسیستم‌های استاندارد';
				|it = 'Sottosistemi standard';
				|pl = 'Standardowe podsystemy';
				|tr = 'Standart alt sistemler'", CommonClient.DefaultLanguageCode()),
			"Error", ErrorDescription);
	Else
		Result.ApplicationStarted = True;
	EndIf;
	
	Result.ReturnCode = ?(ReturnCode <> Undefined, ReturnCode, -1);
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	RunCallback(Notification, Result);
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	StartApplicationNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationNotifyOnError(ErrorDescription, Context)
	
	Notification = Context.Notification;
	If Notification = Undefined Then
		If Not IsBlankString(ErrorDescription) Then
			ShowMessageBox(, ErrorDescription);
		EndIf;
		Return;
	EndIf;
		
	Result = ApplicationStartResult();
	Result.ErrorDescription = ErrorDescription;
	If Context.WaitForCompletion Then
		FillThreadResult(Result, Context);
	EndIf;
	RunCallback(Notification, Result);
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
Function ApplicationStartResult()
	
	Result = New Structure;
	Result.Insert("ApplicationStarted", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ReturnCode", -13);
	Result.Insert("OutputStream", "");
	Result.Insert("ErrorStream", "");
	
	Return Result;
	
EndFunction

// Continues the FileSystemClient.StartApplication procedure.
Procedure StartApplicationWithFullRights(Context)
	
#If WebClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể khởi động ứng dụng
		           |%1
		           |vì lý do:
		           |Không được phép khởi động ứng dụng có nâng cao đặc quyền trong web-client.';
		           |ru = 'Не удалось запустить приложение
		           |%1
		           |по причине:
		           |Запуск приложений с повышением привилегий недоступен в веб-клиенте.';
		           |en = 'Cannot start
		           |%1.
		           |Reason:
		           |The web client does not support starting applications with elevated privileges.'; fa = 'Cannot start
		           |%1.
		           |Reason:
		           |The web client does not support starting applications with elevated privileges.';
		           |it = 'Не удалось запустить приложение
		           |%1
		           |по причине:
		           |Запуск приложений с повышением привилегий недоступен в веб-клиенте.';
		           |pl = 'Cannot start
		           |%1.
		           |Reason:
		           |The web client does not support starting applications with elevated privileges.';
		           |tr = '
		           |%1
		           | uygulamasıı şu sebeple başlatılamadı:
		           |Web istemcisinde yükseltilmiş ayrıcalıklara sahip uygulamalar çalıştırılamaz.'"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#ElsIf MobileClient Then
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể khởi động ứng dụng
		           |%1
		           |vì lý do:
		           |Không được phép khởi động ứng dụng có nâng cao đặc quyền trong web-client.';
		           |ru = 'Не удалось запустить приложение
		           |%1
		           |по причине:
		           |Запуск приложений с повышением привилегий недоступен в мобильном клиенте.';
		           |en = 'Cannot start
		           |%1.
		           |Reason:
		           |The mobile client does not support starting applications with elevated privileges.'; fa = 'Cannot start
		           |%1.
		           |Reason:
		           |The mobile client does not support starting applications with elevated privileges.';
		           |it = 'Не удалось запустить приложение
		           |%1
		           |по причине:
		           |Запуск приложений с повышением привилегий недоступен в мобильном клиенте.';
		           |pl = 'Cannot start
		           |%1.
		           |Reason:
		           |The mobile client does not support starting applications with elevated privileges.';
		           |tr = '
		           |%1
		           | uygulaması şu sebeple başlatılamadı:
		           |Mobil istemcisinde yükseltilmiş ayrıcalıklara sahip uygulamalar çalıştırılamaz.'"),
		Context.CommandString);
	StartApplicationNotifyOnError(ErrorDescription, Context);
#Else
	
	If CommonClient.IsWindowsClient() Then 
		StartApplicationWithFullWindowsRights(Context);
	ElsIf CommonClient.IsLinuxClient() Then 
		StartApplicationWithFullLinuxRights(Context);
	Else
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể khởi động ứng dụng
			           |%1
			           |vì lý do:
			           |Không thể khởi chạy ứng dụng có nâng cao đặc quyền chỉ trên Windows và Linux.';
			           |ru = 'Не удалось запустить приложение
			           |%1
			           |по причине:
			           |Запуск приложений с повышением привилегий доступен только в Windows и Linux.';
			           |en = 'Cannot start
			           |%1.
			           |Reason:
			           |Starting applications with elevated privileges is supported for Windows and Linux only.'; fa = 'Cannot start
			           |%1.
			           |Reason:
			           |Starting applications with elevated privileges is supported for Windows and Linux only.';
			           |it = 'Не удалось запустить приложение
			           |%1
			           |по причине:
			           |Запуск приложений с повышением привилегий доступен только в Windows и Linux.';
			           |pl = 'Cannot start
			           |%1.
			           |Reason:
			           |Starting applications with elevated privileges is supported for Windows and Linux only.';
			           |tr = '
			           |%1
			           | uygulaması şu sebeple başlatılamadı:
			           |Yükseltilmiş ayrıcalıklara sahip uygulamalar yalnızca Windows ve Linux''da çalıştırılabilir.'"),
			Context.CommandString);
		StartApplicationNotifyOnError(ErrorDescription, Context);
	EndIf;
	
#EndIf
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
//
Procedure FillThreadResult(Result, Context)
	
#If Not WebClient Then
		
	If Context.GetOutputStream
		And Not IsBlankString(Context.OutputThreadFileName) Then
		Result.OutputStream = ReadThreadFile(Context.OutputThreadFileName, Context.ThreadsEncoding);
	EndIf;
	
	If Context.GetErrorStream
		And Not IsBlankString(Context.ErrorsThreadFileName) Then
		Result.ErrorStream = ReadThreadFile(Context.ErrorsThreadFileName, Context.ThreadsEncoding);
	EndIf;
		
#EndIf

EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
//
Function ReadThreadFile(PathToFile, ThreadsEncoding)
	
	// ACC:566-off - Synchronous calls outside the thin client.
	
#If WebClient Then
	Return "";
#Else
	ThreadFile = New File(PathToFile);
	If Not ThreadFile.Exists() Then
		Return "";
	EndIf;
	
	ReadThreadFile1 = New TextReader(PathToFile, ThreadsEncoding);
	Result = ReadThreadFile1.Read();
	ReadThreadFile1.Close();
	
	DeleteFiles(PathToFile);
	
	Return ?(Result = Undefined, "", Result);
#EndIf
	
	// ACC:566-on
	
EndFunction

#If Not WebClient And Not MobileClient Then

// Continues the FileSystemClient.StartApplication procedure.
//
Procedure StartApplicationWithFullWindowsRights(Context)
	
	// ACC:534-off - This function provides safe startup methods.
	
	CommandString = Context.CommandString;
	CurrentDirectory = Context.CurrentDirectory;
	ExecutionEncoding = Context.ExecutionEncoding;
	
	WaitForCompletion = False;
	
	CommandString = CommonInternalClientServer.TheWindowsCommandStartLine(CommandString, 
		CurrentDirectory, WaitForCompletion, ExecutionEncoding);
	
	Try
		Shell = New COMObject("Shell.Application");
		// Run with elevated privileges.
		ReturnCode = Shell.ShellExecute("cmd", "/c """ + CommandString + """",, "runas", 0);
		Shell = Undefined;
	Except
		Shell = Undefined;
		ErrorInfo = ErrorInfo();
		StandardProcessing = True;
		StartApplicationOnProcessError(ErrorInfo, StandardProcessing, Context);
		Return;
	EndTry;
	
	If ReturnCode = Undefined Then 
		ReturnCode = 0;
	EndIf;
	
	StartApplicationAfterStartApplication(ReturnCode, Context);
	
	// ACC:534-on
	
EndProcedure

// Continues the FileSystemClient.StartApplication procedure.
//
Procedure StartApplicationWithFullLinuxRights(Context)
	
	// ACC:534-off - This function provides safe startup methods.
	
	CurrentDirectory = Context.CurrentDirectory;
	CommandString = Context.CommandString;
	
	CommandWithPrivilegeEscalation = "pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY " + CommandString;
	WaitForCompletion = True;
	
	Notification = New CallbackDescription(
		"StartApplicationAfterStartApplication", ThisObject, Context,
		"StartApplicationOnProcessError", ThisObject);
	BeginRunningApplication(Notification, CommandWithPrivilegeEscalation, CurrentDirectory, WaitForCompletion);
	
	// ACC:534-on
	
EndProcedure

#EndIf

#EndRegion

#Region ChooseDirectory

// Continues the FileSystemClient.SelectDirectory procedure.
Procedure SelectDirectoryOnAttach1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		RunCallback(Context.CompletionHandler, "");
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription(
		"SelectDirectoryAtSelectionEnd", ThisObject, Context.CompletionHandler);
	
	Dialog = New FileDialog(FileDialogMode.ChooseDirectory);
	Dialog.Multiselect = False;
	If Not IsBlankString(Context.Title) Then
		Dialog.Title = Context.Title;
	EndIf;
	If Not IsBlankString(Context.Directory) Then
		Dialog.Directory = Context.Directory;
	EndIf;
	
	Dialog.Show(CallbackDescription);
	
EndProcedure

// Continues the FileSystemClient.SelectDirectory procedure.
Procedure SelectDirectoryAtSelectionEnd(DirectoriesArray, CompletionHandler) Export
	
	PathToDirectory = 
		?(DirectoriesArray = Undefined Or DirectoriesArray.Count() = 0,
			"", 
			DirectoriesArray[0]);
	
	RunCallback(CompletionHandler, PathToDirectory);
	
EndProcedure

#EndRegion

#Region ShowSelectionDialog

// Continues the procedure "FileSystemClient.ShowSelectionDialog"
//
Procedure ShowSelectionDialogOnAttach1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If Not ExtensionAttached Then
		RunCallback(Context.CompletionHandler, "");
		Return;
	EndIf;
	
	Context.Dialog.Show(Context.CompletionHandler);
	
EndProcedure

#EndRegion

#Region ExtensionFor1CEnterpriseApplication

Procedure StartAttach1CEnterpriseExtension(Attached, Context) Export
	
	If Attached Then
		RunCallback(Context.CallbackDescriptionCompletion, "AttachmentNotRequired");
		Return;
	EndIf;
	
	// In the web client on macOS, the extension is available only in the Chrome browser.
	If CommonClient.IsMacOSClient() 
			And Not Is1CEnterpriseExtensionAvailable() Then
		RunCallback(Context.CallbackDescriptionCompletion);
		Return;
	EndIf;
	
	ParameterName = "StandardSubsystems.SuggestFileSystemExtensionInstallation";
	FirstCallDuringSession = ApplicationParameters[ParameterName] = Undefined;
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, ShouldPromptToInstall1CEnterpriseExtension());
	EndIf;
	
	ShouldPromptToInstallExtension = ApplicationParameters[ParameterName] Or FirstCallDuringSession;
	If Context.CanContinueWithoutInstalling And Not ShouldPromptToInstallExtension Then
		RunCallback(Context.CallbackDescriptionCompletion);
		Return;
	EndIf;
		
	FormParameters = New Structure;
	FormParameters.Insert("SuggestionText", Context.SuggestionText);
	FormParameters.Insert("CanContinueWithoutInstalling", Context.CanContinueWithoutInstalling);
	OpenForm("CommonForm.QuestionOn1CEnterpriseExtensionInstallation", FormParameters,,,,,  
		Context.CallbackDescriptionCompletion);
		
EndProcedure

Procedure StartAttach1CEnterpriseExtensionWhenAnsweringToInstallationQuestion(Action, ClosingNotification1) Export
	
	ExtensionAttached = (Action = "ExtensionAttached" Or Action = "AttachmentNotRequired");
	
#If WebClient Then
	If Action = "DoNotPrompt"
		Or Action = "ExtensionAttached" Then
		
		SystemInfo = New SystemInfo();
		ClientID = SystemInfo.ClientID;
		ApplicationParameters["StandardSubsystems.SuggestFileSystemExtensionInstallation"] = False;
		CommonClient.CommonSettingsStorageSave(
			"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, False);
		
	EndIf;
#EndIf
	
	RunCallback(ClosingNotification1, ExtensionAttached);
	
EndProcedure

Function ShouldPromptToInstall1CEnterpriseExtension()
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	Return CommonClient.CommonSettingsStorageLoad(
		"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
	
EndFunction

Function Is1CEnterpriseExtensionAvailable()

	SystemInfo = New SystemInfo;
	Return StrFind(SystemInfo.UserAgentInformation, "Chrome") > 0;

EndFunction

#EndRegion

#Region TemporaryFiles

#Region CreateTemporaryDirectory

// Continuation of procedure FileSystemClient.CreateTemporaryDirectory.
// 
// Parameters:
//  ExtensionAttached - Boolean
//  Context - Structure:
//   * Notification - CallbackDescription
//   * Extension - String
//
Procedure CreateTemporaryDirectoryAfterCheck1CEnterpriseExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
		Notification = New CallbackDescription(
			"CreateTemporaryDirectoryAfterGetTemporaryDirectory", ThisObject, Context,
			"CreateTemporaryDirectoryOnProcessError", ThisObject);
		BeginGettingTempFilesDir(Notification);
	Else
		CreateTemporaryDirectoryNotifyOnError(NStr("vi = 'Không thể cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
													|ru = 'Не удалось установить расширение для работы с 1С:Предприятием.';
													|en = 'Cannot install 1C:Enterprise Extension.'; fa = 'Cannot install 1C:Enterprise Extension.';
													|it = 'Impossibile installare l''estensione per il lavoro con 1C:Enterprise.';
													|pl = 'Nie udało się zainstalować folderu do pracy z 1C:Enterprise.';
													|tr = '1C:Enterprise ile çalışma için uzantı yüklenemedi.'"), 
			Context);
	EndIf;
	
EndProcedure

// Continuation of procedure FileSystemClient.CreateTemporaryDirectory.
// 
// Parameters:
//  TempFilesDirName - String
//  Context - Structure:
//   * Notification - CallbackDescription
//   * Extension - String
//
Procedure CreateTemporaryDirectoryAfterGetTemporaryDirectory(TempFilesDirName, Context) Export 
	
	Notification = Context.Notification;
	Extension = Context.Extension;
	
	DirectoryName = "v8_" + String(New UUID);
	
	If Not IsBlankString(Extension) Then 
		DirectoryName = DirectoryName + "." + Extension;
	EndIf;
	
	BeginCreatingDirectory(Notification,
		CommonClientServer.AddLastPathSeparator(TempFilesDirName) + DirectoryName);
	
EndProcedure

// Continuation of procedure FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryOnProcessError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context);
	
EndProcedure

// Continuation of procedure FileSystemClient.CreateTemporaryDirectory.
Procedure CreateTemporaryDirectoryNotifyOnError(ErrorDescription, Context)
	
	ShowMessageBox(, ErrorDescription);
	DirectoryName = "";
	RunCallback(Context.Notification, DirectoryName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion