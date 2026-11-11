///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region LoadFiles

// Shows a file selection dialog box and places the selected file into a temporary storage.
// This method provides the functionality of both BeginPutFile and BeginPuttingFiles global context methods.
// Its return value is not affected by the availability of 1C:Enterprise Extension.
// Restrictions:
//   Not used to select catalogs. This option is not supported in the web client mode.
//
// Parameters:
//   CompletionHandler - CallbackDescription - Describes the procedure to be called after the file import.
//                                               Parameters:
//      # FileThatWasPut - Structure - File selected by the user:
//                           ## Location - String - Address of the file binary data in the temporary storage.
//                           ## Name - String - For thin client and web client with 1C:Enterprise Extension,
//                                        the local path the file was obtained by. For web client without the extension,
//                                        the full name of the file.
//                                        
//                        - Undefined - User canceled out of selection dialog or another program is using the file.
//      # AdditionalParameters - Arbitrary - Value specified when creating a "NotifyDescription" object.
//                                                 
//   ImportParameters         - See FileSystemClient.FileImportParameters.
//   FileName                  - String - Full path to the file that will be offered to the user at the beginning of
//                             interactive selection or will be put to the temporary storage in non-interactive one. 
//                             If noninteractive mode is selected and the parameter is not filled, an exception will be called.
//   AddressInTempStorage - String - the address where the file will be saved.
//
// Example:
//   Notification = New NotifyDescription("SelectFileAfterPutFiles", ThisObject, Context);
//   ImportParameters = FileSystemClient.FileImportParameters();
//   ImportParameters.FormIdentifier = UUID;
//   FileSystemClient.ImportFile(Notification, ImportParameters);
//
Procedure ImportFile_(CompletionHandler, ImportParameters = Undefined, FileName = "",
	AddressInTempStorage = "") Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	ElsIf Not ImportParameters.Interactively And IsBlankString(FileName) Then
		Raise NStr("vi = 'Chưa chỉ ra tên tệp để kết nhập ở chế độ không trực tác.';
					|ru = 'Не указано имя файла для загрузки в неинтерактивном режиме.';
					|en = 'Import in non-interactive mode failed. The name of the file to import is not specified.'; fa = 'Import in non-interactive mode failed. The name of the file to import is not specified.';
					|it = 'Nome file per il download in modalità non interattiva non indicato.';
					|pl = 'Nie określono nazwy pliku podczas pobierania w trybie nieinteraktywnym.';
					|tr = 'İnteraktif olmayan modda içe aktarım hatası. İçe aktarılacak dosyanın adı belirtilmedi.'");
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormIdentifier) Then
		ImportParameters.FormIdentifier = New UUID;
	EndIf;
	
	FileDetails = New TransferableFileDescription(FileName, AddressInTempStorage);
	ImportParameters.Insert("FilesToUpload", FileDetails);
	
	ImportParameters.Dialog.FullFileName     = FileName;
	ImportParameters.Dialog.Multiselect = False;
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

// Shows a file selection dialog and puts the selected files to a temporary storage.
// This method provides the functionality of both BeginPutFile and BeginPuttingFiles global context methods.
// Its return value is not affected by the availability of 1C:Enterprise Extension.
// Restrictions:
//   Not used to select catalogs. This option is not supported in the web client mode.
//   Multiple selection in the web client is only supported if 1C:Enterprise Extension is installed.
//
// Parameters:
//   CompletionHandler - CallbackDescription - Contains the details of the procedure to be called following file import.
//                             Procedure parameters:
//      # FilesThatWerePut - Undefined - User canceled out of selection dialog or another program is using the file.
//                        - Array of Structure - File selected by the user:
//                           ## Location - String - Address of the file binary data in the temporary storage.
//                           ## Name - String - For thin client and web client with 1C:Enterprise Extension,
//                                        the local path the file was obtained by. For web client without the extension,
//                                        the full name of the file.
//                                        ## FullName - String - For thin client and web client with 1C:Enterprise Extension,
//                           the local path the file was obtained by.
//                                         For web client without the extension, "".
//                                         ## FileName - String - Full filename.
//                                         # AdditionalParameters - Arbitrary - Value specified during the creation of the NotifyDescription object.
//                           
//      
//   ImportParameters    - See FileSystemClient.FileImportParameters.
//   FilesToUpload     - Array - contains objects of the TransferableFileDetails type. Can be filled completely.
//                        In this case the files being imported will be saved to the specified addresses. Can be filled
//                        partially. Only the names of the array items are filled. In this case the files being imported will be
//                        placed in new temporary storages. Array can be empty. In this case the files
//                        to put are defined by the values specified in the ImportParameters parameter. If noninteractive mode is selected in
//                        import parameters, and the "FilesToUpload" parameter is unfilled, an exception is called.
//                        
//
// Example:
//   Notification = New NotifyDescription("LoadExtensionAfterPutFiles", ThisObject, Context);
//   ImportParameters = FileSystemClient.FileImportParameters();
//   ImportParameters.FormIdentifier = UUID;
//   FileSystemClient.ImportFiles(Notification, ImportParameters);
//
Procedure ImportFiles(CompletionHandler, ImportParameters = Undefined, FilesToUpload = Undefined) Export
	
	If ImportParameters = Undefined Then
		ImportParameters = FileImportParameters();
	EndIf;
	
	If Not ImportParameters.Interactively
		And (FilesToUpload = Undefined 
		Or (TypeOf(FilesToUpload) = Type("Array")
		And FilesToUpload.Count() = 0)) Then
		
		Raise NStr("vi = 'Chưa chỉ ra tệp để kết nhập ở chế độ không trực tác.';
					|ru = 'Не указаны файлы для загрузки в неинтерактивном режиме.';
					|en = 'Import in non-interactive mode failed. The files to import are not specified.'; fa = 'Import in non-interactive mode failed. The files to import are not specified.';
					|it = 'File per il downlod in modalità non interattiva non indicati.';
					|pl = 'Brak plików do pobrania nieinteraktywnego.';
					|tr = 'İnteraktif olmayan modda içe aktarım hatası. İçe aktarılacak dosyalar belirtilmedi.'");
		
	EndIf;
	
	If FilesToUpload = Undefined Then
		FilesToUpload = New Array;
	EndIf;
	
	If Not ValueIsFilled(ImportParameters.FormIdentifier) Then
		ImportParameters.FormIdentifier = New UUID;
	EndIf;
	
	ImportParameters.Dialog.Multiselect = True;
	ImportParameters.Insert("FilesToUpload", FilesToUpload);
	ShowPutFile(CompletionHandler, ImportParameters);
	
EndProcedure

#EndRegion

#Region ModifiesStoredData

// Gets the file and saves it to the local file system of the user.
//
// Parameters:
//   CompletionHandler      - Undefined
//                             - CallbackDescription - Describes the procedure to be called upon completion.
//                                                    Parameters:
//      # ReceivedFiles - Array of TransferredFileDescription - Saved files.
//                             - Undefined - Files were not obtained.
//      # AdditionalParameters - Arbitrary - Value that was created during the creation of the "NotifyDescription" object.
//   FileLocation1         - String - Address in the temporary storage or URL to the ValueStorage-type 
//                                        attribute containing the file's binary data.
//   FileName                  - String - a full path according to which the received file and the file name
//                                        with an extension must be saved.
//   SavingParameters       - See FileSystemClient.FileSavingParameters
//
// Example:
//   Notification = New NotifyDescription("SaveCertificateAfterFilesReceipt", ThisObject, Context);
//   SavingParameters = FileSystemClient.FileSavingParameters();
//   FileSystemClient.SaveFile(Notification, Context.CertificateAddress, FileName, SavingParameters);
//
Procedure SaveFile(CompletionHandler, FileLocation1, FileName = "", 
	SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FileSavingParameters();
	EndIf;
	
	FileData = New TransferableFileDescription(FileName, FileLocation1);
	
	FilesToSave = New Array;
	FilesToSave.Add(FileData);
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

// Gets the files and saves them to the local file system of the user.
// To save files in noninteractive mode, the Name property of the FilesToSave parameter must have
// the full path to the file being saved, or if the Name property contains only the file name with extension, the Directory property of the Dialog item of the SavingParameters parameter is to be
// filled. Otherwise, an exception
// will be called.
//
// Parameters:
//   CompletionHandler - Undefined
//                        - CallbackDescription - Describes the procedure that is called upon completion.
//                                               Parameters:
//     * ObtainedFiles         - Array of TransferredFileDescription - Saved files.
//                               - Undefined - Files haven't been received.
//     * AdditionalParameters - Arbitrary - a value that was specified on creating
//                                                the NotifyDescription object.
//   FilesToSave     - Array of TransferableFileDescription
//   SavingParameters  - See FileSystemClient.FileSavingParameters
//
// Example:
//   Notification = New NotifyDescription("SavePrintFormToFileAfterGetFiles", ThisObject);
//   SavingParameters = FileSystemClient.FilesSavingParameters();
//   FileSystemClient.SaveFiles(Notification, FilesToGet, SavingParameters);
//
Procedure SaveFiles(CompletionHandler, FilesToSave, SavingParameters = Undefined) Export
	
	If SavingParameters = Undefined Then
		SavingParameters = FilesSavingParameters();
	EndIf;
	
	ShowDownloadFiles(CompletionHandler, FilesToSave, SavingParameters);
	
EndProcedure

#EndRegion

#Region Parameters

// Initializes a parameter structure to import the file from the file system.
// To be used in FileSystemClient.ImportFile and FileSystemClient.ImportFiles
//
// Returns:
//  Structure:
//    * FormIdentifier                  - UUID - a UUID of the form
//                                          used to place files. If the parameter is filled,
//                                          the DeleteFromTempStorage global context method is to be called
//                                          after completing the operation with the binary data. Default
//                                          value is Undefined.
//    * Interactively                        - Boolean - Indicates interactive mode usage when a file selection dialog is shown to
//                                          the user. The default
//                                          value is True.
//    * Dialog                              - FileDialog - See the properties in Syntax Assistant.
//                                          It is used if the "Interactively" property is set to True,
//                                          and 1C:Enterprise Extension is attached.
//    * SuggestionText                    - String - a text of a suggestion to install the extension. If the parameter
//                                          takes the value "", the standard suggestion text will be output.
//                                          Default value - "".
//    * AcrtionBeforeStartPutFiles - CallbackDescription
//                                          - Undefined - Contains the details of the procedure
//                                          that must be called right before a file is stored to the temporary storage.
//                                          If set to "Undefined", no procedure will be called.
//                                          By default, "Undefined". Parameters of the callable procedure
//                                          # FilesToPut - FileReference:
//        
//                                  - Array of FileRef - Reference to a file that is ready to be put into temporary storage.
//                                    Or an array of references for multiple files.
//        # RefusalToPlaceFile - Boolean - Indicates that the file placement is interrupted. If set to "True" within the handler procedure,
//                                    then the file placement will be canceled.
//        # AdditionalParameters - Arbitrary - Value specified during the creation of the "NotifyDescription" object.
//
// Example:
//  ImportParameters = FileSystemClient.FileImportParameters();
//  ImportParameters.Dialog.Title = NStr("en = 'Select a document'; fa = 'Select a document'");
//  ImportParameters.Dialog.Filter = NStr("en = 'MS Word files (*.doc;*.docx)|*.doc;*.docx|All files (*.*)|*.*'; fa = 'MS Word files (*.doc;*.docx)|*.doc;*.docx|All files (*.*)|*.*'");
//  FileSystemClient.ImportFile(Notification, ImportParameters);
//
Function FileImportParameters() Export
	
	ImportParameters = OperationContext(FileDialogMode.Open);
	ImportParameters.Insert("FormIdentifier", Undefined);
	ImportParameters.Insert("AcrtionBeforeStartPutFiles", Undefined);
	Return ImportParameters;
	
EndFunction

// Initializes a parameter structure to save the file to the file system.
// To be used in FileSystemClient.SaveFile.
//
// Returns:
//  Structure:
//    * Interactively     - Boolean - Indicates interactive mode usage when a file selection dialog is shown to
//                       the user. The default
//                       value is True.
//    * Dialog           - FileDialog - See the properties in Syntax Assistant.
//                       It is used if the "Interactively" property is set to True,
//                       and 1C:Enterprise Extension is attached.
//    * SuggestionText - String - a text of a suggestion to install the extension. If the parameter
//                       takes the value "", the standard suggestion text will be output.
//                       Default value - "".
//
// Example:
//  SavingParameters = FileSystemClient.FileSavingParameters();
//  SavingParameters.Dialog.Title = NStr("en = 'Save key operation profile to file");
//  SavingParameters.Dialog.Filter = "Key operation profile files (*.xml)|*.xml";
//  FileSystemClient.SaveFile(Undefined, SaveKeyOperationsProfileToServer(), , SavingParameters);
//
Function FileSavingParameters() Export
	
	Return OperationContext(FileDialogMode.Save);
	
EndFunction

// Initializes a parameter structure to save the file to the file system.
// To be used in "FileSystemClient.SaveFiles".
//
// Returns:
//  Structure:
//    * Interactively     - Boolean - Indicates interactive mode usage when a file selection dialog is shown to
//                       the user. The default
//                       value is True.
//    * Dialog           - FileDialog - See the properties in Syntax Assistant.
//                       It is used if the "Interactively" property is set to True,
//                       and 1C:Enterprise Extension is attached.
//    * SuggestionText - String - a text of a suggestion to install the extension. If the parameter
//                       takes the value "", the standard suggestion text will be output.
//                       Default value - "".
//
// Example:
//  SavingParameters = FileSystemClient.FilesSavingParameters();
//  SavingParameters.Dialog.Title = NStr("en ='Select a folder to save generated document'; fa = 'Select a folder to save generated document'");
//  FileSystemClient.SaveFiles(Notification, FilesToGet, SavingParameters);
//
Function FilesSavingParameters() Export
	
	Return OperationContext(FileDialogMode.ChooseDirectory);
	
EndFunction

// Initializes a parameter structure to open the file.
// To be used in "FileSystemClient.OpenFile".
//
// Returns:
//  Structure:
//    *Encoding         - String - The text file encoding. By default, "".
//                       If the parameter is not specified, the text format will be determined automatically. 
//                       For the encodings list, see text document's "Write" method in Syntax Assistant.
//    *ForEditing - Boolean - True to open the file for editing, False otherwise. If
//                       the parameter takes the True value, waiting for application closing, and if in the
//                       FileLocation parameter the address is stored in the temporary storage, it updates the file data.
//                       Default value is False.
//
Function FileOpeningParameters() Export
	
	Context = New Structure;
	Context.Insert("Encoding", "");
	Context.Insert("ForEditing", False);
	Return Context;
	
EndFunction

#EndRegion

#Region RunExternalApplications

// Opens a file for viewing or editing.
// If the file is opened from the binary data in a temporary storage, it is previously saved
// to the temporary directory.
//
// Parameters:
//  FileLocation1    - String - Full path to the file in the file system, address in the temporary storage, 
//                         or URL to the ValueStorage-type attribute containing the file's binary data.
//  CompletionHandler - CallbackDescription
//                       - Undefined - Details of the procedure that accepts the result of another procedure's execution with
//                         the following parameters::
//    # TheModifiedFile - Boolean - Indicates whether the file on disk or the binary data in storage was modified.
//    # AdditionalParameters - Arbitrary - Value - The value that was specified when creating the
//                              "NotifyDescription" object.
//  FileName             - String - the name of the file with an extension or the file extension without the dot. If
//                         the FileLocation parameter contains the address in a temporary storage and the parameter
//                         FileName is empty, an exception is thrown.
//  OpeningParameters    - See FileSystemClient.FileOpeningParameters.
//
Procedure OpenFile(FileLocation1, CompletionHandler = Undefined, FileName = "",
	OpeningParameters = Undefined) Export
		
	If OpeningParameters = Undefined Then
		OpeningParameters = FileOpeningParameters();
	EndIf;
	
	OpeningParameters.Insert("CompletionHandler", CompletionHandler);
	If Not IsTempStorageURL(FileLocation1)
		And Not CommonInternalClient.IsURL(FileLocation1) Then

		FileSystemInternalClient.OpenFileAfterSaving(
			New Structure("FullName", FileLocation1), OpeningParameters);
		Return;
	EndIf;
		
	If IsBlankString(FileName) Then
		Raise NStr("vi = 'Chưa chỉ ra tên tệp.';
					|ru = 'Не указано имя файла.';
					|en = 'The file name is not specified.'; fa = 'The file name is not specified.';
					|it = 'Nome file non indicato.';
					|pl = 'Nazwa pliku nie została podana.';
					|tr = 'Dosya adı belirtilmedi.'");
	EndIf;
	
	PathToFile = TempFileFullName(FileName);
	ShortenFullFileNameToAllowedNTFSLength(PathToFile);
	
	OpeningParameters.Insert("PathToFile", PathToFile);
	OpeningParameters.Insert("AddressOfBinaryDataToUpdate", FileLocation1);
	OpeningParameters.Insert("DeleteAfterDataUpdate", True);
	
	SavingParameters = FileSavingParameters();
	SavingParameters.Interactively = False;
	
	CallbackDescription = New CallbackDescription(
		"OpenFileAfterSaving", FileSystemInternalClient, OpeningParameters);
	
	SaveFile(CallbackDescription, FileLocation1, PathToFile, SavingParameters);
	
EndProcedure

// Opens Windows Explorer to the specified directory.
// If a file path is specified, the pointer is placed on the file.
//
// Parameters:
//  PathToDirectoryOrFile - String - The full path to a local file or directory.
//
// Example:
//  // For Windows OS
//  FileSystemClient.OpenExplorer("C:\Users");
//  FileSystemClient.OpenExplorer("C:\Program Files\1cv8\common\1cestart.exe");
//  // For Linux OS
//  FileSystemClient.OpenExplorer("/home/");
//  FileSystemClient.OpenExplorer("/opt/1C/v8.3/x86_64/1cv8c");
//
Procedure OpenExplorer(PathToDirectoryOrFile) Export
	
	FileInfo3 = New File(PathToDirectoryOrFile);
	
	Context = New Structure;
	Context.Insert("FileInfo3", FileInfo3);
	
	Notification = New CallbackDescription(
		"OpenExplorerAfterCheck1CEnterpriseExtension", FileSystemInternalClient, Context);
		
	SuggestionText = NStr("vi = 'Để mở thư mục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для открытия папки установите расширение для работы с 1С:Предприятием.';
							|en = 'To open the folder, install 1C:Enterprise extension.'; fa = 'To open the folder, install 1C:Enterprise extension.';
							|it = 'Per l''apertura della cartella installare l''estensione per il lavoro con 1C:Enterprise.';
							|pl = 'Aby otworzyć folder zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
							|tr = 'Klasörü açmak için 1C:Enterprise ile çalışma uzantısını yükleyin.'");
	Attach1CEnterpriseExtension(Notification, SuggestionText, False);
	
EndProcedure

// Opens a URL in an application associated with URL protocol.
// Valid protocols: http, https, e1c, v8help, mailto, tel, skype.
//
// Do not use protocol file:// to open Explorer or a file.
// - To open Explorer See OpenExplorer.
// - To open a file in an associated application, use OpenFileInViewer.
//
// Parameters:
//  URL - String - a link to open.
//  Notification - CallbackDescription - notification on file open attempt.
//      If the notification is not specified and an error occurs, the method shows a warning.
//      ApplicationStarted - Boolean - True if the external application opened successfully.
//      AdditionalParameters - Arbitrary - a value that was specified when creating the NotifyDescription object.
//
// Example:
//  FileSystemClient.OpenURL("e1cib/navigationpoint/startpage"); // Home page.
//  FileSystemClient.OpenURL("v8help://1cv8/QueryLanguageFullTextSearchInData");
//  FileSystemClient.OpenURL("https://1c.ru");
//  FileSystemClient.OpenURL("mailto:help@1c.ru");
//  FileSystemClient.OpenURL("skype:echo123?call");
//
Procedure OpenURL(URL, Val Notification = Undefined) Export
	
	// ACC:534-off - This function provides safe startup methods.
	
	Context = New Structure;
	Context.Insert("URL", URL);
	Context.Insert("Notification", Notification);
	
	ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể chuyển đến tham chiếu ""%1"" do nguyên nhân: 
		           |Đã đặt sai tham chiếu dẫn hướng.';
		           |ru = 'Не удалось перейти по ссылке ""%1"" по причине: 
		           |Неверно задана навигационная ссылка.';
		           |en = 'Cannot open URL ""%1"".
		           |The URL is invalid.'; fa = 'Cannot open URL ""%1"".
		           |The URL is invalid.';
		           |it = 'Non è stato possibile seguire il link ""%1"" a causa di: 
		           |Link di navigazione passato incorrettamente.';
		           |pl = 'Nie udało się przejść pod odnośnikiem ""%1"" z powodu: 
		           |Błędnie jest podany odnośnik nawigacyjny.';
		           |tr = 'Aşağıdaki nedenle ""%1"" linke geçemedi: 
		           |Gezinme bağlantısı yanlış ayarlandı.'"),
		URL);
	
	If Not FileSystemInternalClient.IsAllowedRef(URL) Then 
		
		FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		
	ElsIf FileSystemInternalClient.IsWebURL(URL)
		Or CommonInternalClient.IsURL(URL) Then 
		
		Try
		
#If ThickClientOrdinaryApplication Then
			
			// 1C:Enterprise design feature: GotoURL is not supported by ordinary applications running in the thick client.
			Notification = New CallbackDescription(
				,, Context,
				"OpenURLOnProcessError", FileSystemInternalClient);
			BeginRunningApplication(Notification, URL);
#Else
			GotoURL(URL);
#EndIf
			
			If Notification <> Undefined Then 
				ApplicationStarted = True;
				RunCallback(Notification, ApplicationStarted);
			EndIf;
			
		Except
			FileSystemInternalClient.OpenURLNotifyOnError(ErrorDescription, Context);
		EndTry;
		
	ElsIf FileSystemInternalClient.IsHelpRef(URL) Then 
		
		OpenHelp(URL);
		
	Else 
		
		Notification = New CallbackDescription(
			"OpenURLAfterCheck1CEnterpriseExtension", FileSystemInternalClient, Context);
		
		SuggestionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để mở tham chiếu ""%1"", hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
				|ru = 'Для открытия ссылки ""%1"" установите расширение для работы с 1С:Предприятием.';
				|en = 'To open link %1, install 1C:Enterprise extension.'; fa = 'To open link %1, install 1C:Enterprise extension.';
				|it = 'Per l''apertura del collegamento ""%1"" installare l''estensione per il lavoro con 1C:Enterprise.';
				|pl = 'Aby otworzyć odnośnik ""%1"" zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
				|tr = '""%1"" URL''sini açmak için 1C:Enterprise Extension yükleyin.'"),
			URL);
		Attach1CEnterpriseExtension(Notification, SuggestionText, False);
		
	EndIf;
	
	// ACC:534-on
	
EndProcedure

// Parameter constructor for FileSystemClient.StartApplication.
//
// Returns:
//  Structure:
//    * CurrentDirectory - String - sets the current directory of the application being started up.
//    * Notification - CallbackDescription - Notification about exiting the running app. 
//          If not specified, then a warning will be displayed. Completion handler parameters are:
//          # Result - Structure - Output of the app:
//              ## ApplicationStarted - Boolean - "True" if the app was successfully launched.
//              ## ErrorDetails - String - Brief error details. Or empty string if the user interrupted the launch.
//              ## ReturnCode - Number  - Return code of the app.
//              ## OutputStream - String - App output directed to the stdout stream.
//                             For web client, always set to "".
//              ## ErrorStream - String - Execution errors directed to the stderr stream.
//                             For web client, always set to "".
//          # AdditionalParameters - Arbitrary - Value specified during the creation of the NotifyDescription object.
//    * WaitForCompletion - Boolean - True, wait for the running application to end before proceeding.
//    * GetOutputStream - Boolean - False - result is passed to stdout.
//         Ignored if WaitForCompletion is not specified.
//    * GetErrorStream - Boolean - False - errors are passed to stderr stream.
//         Ignored if WaitForCompletion is not specified.
//    * ThreadsEncoding - TextEncoding
//                       - String - The encoding used to read stdout and stderr.
//         The default is "CP866" for Windows and "UTF-8" for other operating systems.
//    * ExecutionEncoding - String
//                          - Number - an encoding set in Windows using the chcp command,
//         the possible values ​​are "OEM", "CP866", "UTF8" or the code page number.
//         On Linux, it is set by the environment variable "LANGUAGE" for a particular command.
//         Possible values ​​can be determined by executing the "locale -a" command, for example, "en_EN.UTF-8".
//         Ignored when under MacOS.
//    * ExecuteWithFullRights - Boolean - True, if the application must be run
//          with full system privileges:
//          Windows: UAC query;
//          Linux: execution with pkexec command;
//          macOS, web client, and mobile client: Result.ErrorDetails will be returned.
//    * ExecutionEnvironment - String - an empty string if the runtime is not Windows. Used when identifying 
//								   invalid characters in the launch string.
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("Notification", Undefined);
	Parameters.Insert("WaitForCompletion", True);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ThreadsEncoding", Undefined);
	Parameters.Insert("ExecutionEncoding", Undefined);
	Parameters.Insert("ExecuteWithFullRights", False);
	
	ExecutionEnvironment = ?(CommonClient.IsWindowsClient(), "Windows", ""); 
	Parameters.Insert("ExecutionEnvironment", ExecutionEnvironment);
	
	Return Parameters;
	
EndFunction

// Starts up an external application for execution (for example, * .exe, * bat), 
// or a system command (for example, ping, tracert or traceroute, access the rac client),
// It also allows you to get a return code and the values ​​of output streams (stdout) and errors (stderr)
//
// When an external program is started up in batch mode, the output stream and error stream may return in an unexpected language. 
// To pass to the external application the language in which the expected result must be, you need to:
// - Specify the language in the startup parameter of this application (if such a parameter is provided). 
//   For example, batch mode of 1C:Enterprise has the "/L en" key;
// - In other cases, explicitly set the encoding for the batch command execution.
//   See the ExecutionEncoding property in the return value of FileSystemClient.ApplicationStartupParameters. 
//
// Parameters:
//  StartupCommand - String - application startup command line.
//                 - Array of String - The first element is the path to the application, 
//                   the rest of the elements are its startup parameters.
//                                      The procedure generates an "argv" string from the array.
//  ApplicationStartupParameters - See FileSystemClient.ApplicationStartupParameters.
//
// 
//	// 
//  
//  
// Example:
//  Passing arguments as an array:
//  Setup.exe -args "PIDKEY=***":
//  StartupCommand = New Array;
//  StartupCommand.Add("-args);
//  StartupCommand.Add("PIDKEY =***);
//  FileSystemClient.StartApplication(StartupCommand);
//  Startup with waiting for exit and obtaining the return code:
//
//  ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters ();
//  ApplicationStartupParameters.WaitForCompletion = True;
//  ApplicationStartupParameters.GetOutputStream = True;
//  ApplicationStartupParameters.GetErrorStream = True;
//  ApplicationStartupParameters.Notification = New NotifyDescription("OnGetAppStartupResult", ThisObject);
//  FileSystemClient.StartApplication("ping 127.0.0.1 -n 5", ApplicationStartupParameters );
//
//  Example of notification handling
//   
//  &AtClient
//  Procedure OnGetAppStartupResult(Result, AdditionalParameters) Export
//  ReturnCode = Result.ReturnCode;
//      ErrorStream = Result.OutputStream;
//      ErrorStream = Result.ErrorStream;
//      EndProcedure 
//  
//
Procedure StartApplication(Val StartupCommand, Val ApplicationStartupParameters = Undefined) Export
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CommandString = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	OutputThreadFileName = "";
	ErrorsThreadFileName = "";
	
#If Not WebClient Then
	If ApplicationStartupParameters.WaitForCompletion Then
		
		// ACC:441-off - Temporary files are deleted after asynchronous operations.
		
		If ApplicationStartupParameters.GetOutputStream Then
			OutputThreadFileName = GetTempFileName("stdout.tmp");
			CommandString = CommandString + " > """ + OutputThreadFileName + """";
		EndIf;
		
		If ApplicationStartupParameters.GetErrorStream Then 
			ErrorsThreadFileName = GetTempFileName("stderr.tmp");
			CommandString = CommandString + " 2> """ + ErrorsThreadFileName + """";
		EndIf;
		
		// ACC:441-on
		
	EndIf;
#EndIf
	
	Context = New Structure;
	Context.Insert("CommandString", CommandString);
	Context.Insert("CurrentDirectory", ApplicationStartupParameters.CurrentDirectory);
	Context.Insert("Notification", ApplicationStartupParameters.Notification);
	Context.Insert("WaitForCompletion", ApplicationStartupParameters.WaitForCompletion);
	Context.Insert("ThreadsEncoding", ApplicationStartupParameters.ThreadsEncoding);
	Context.Insert("ExecutionEncoding", ApplicationStartupParameters.ExecutionEncoding);
	Context.Insert("GetOutputStream", ApplicationStartupParameters.GetOutputStream);
	Context.Insert("GetErrorStream", ApplicationStartupParameters.GetErrorStream);
	Context.Insert("OutputThreadFileName", OutputThreadFileName);
	Context.Insert("ErrorsThreadFileName", ErrorsThreadFileName);
	Context.Insert("ExecuteWithFullRights", ApplicationStartupParameters.ExecuteWithFullRights);
	
	Notification = New CallbackDescription("StartApplicationAfterCheck1CEnterpriseExtension", 
		FileSystemInternalClient, Context);
	Attach1CEnterpriseExtension(Notification, 
		NStr("vi = 'Để tạo thư mục tạm thời, cần cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
			|ru = 'Для создания временной папки необходимо установить расширение для работы с 1С:Предприятием.';
			|en = 'To create a temporary folder, install 1C:Enterprise Extension.'; fa = 'To create a temporary folder, install 1C:Enterprise Extension.';
			|it = 'Per la creazione di una cartella temporanea è necessario installare l''estensione per il lavoro con 1C:Enterprise.';
			|pl = 'W celu utworzenia czasowego folderu należy zainstalować rozszerzenie do pracy z 1С:Enterprise.';
			|tr = 'Geçici klasörü oluşturmak için 1C:Enterprise ile çalışma uzantısı yüklenmelidir.'"), False);
	
EndProcedure

// Prints file by an external application.
//
// Parameters:
//  FileToOpenName - String
//
Procedure PrintFromApplicationByFileName(FileToOpenName) Export
	
	If Not ValueIsFilled(FileToOpenName) Then
		Return;
	EndIf;
	
#If Not MobileClient Then
	If CommonClient.IsWindowsClient() Then
		Shell = New COMObject("Shell.Application");
		Shell.ShellExecute(FileToOpenName, "", "", "print", 1);
	ElsIf CommonClient.IsLinuxClient() Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("FileToOpenName", FileToOpenName);
		CallbackDescription = New CallbackDescription("PrintFromTheApplicationByTheLinuxFileName", 
			ThisObject, AdditionalParameters);
		SystemProperties  = New SystemInfo();
		If StrFind(Upper(SystemProperties.OSVersion), "UBUNTU") > 0 Or StrFind(Upper(SystemProperties.OSVersion), "ASTRA") > 0 Then
			CheckIfTheLinuxProgramIsInstalled("Unoconv", CallbackDescription);
		Else
			CallbackDescription = New CallbackDescription("PrintFromTheApplicationByTheLinuxFileNameRunningUnoconv", 
				ThisObject, AdditionalParameters);
			GetTheFullNameOfTheTemporaryFile(CallbackDescription);
		EndIf;
	Else
		ShowMessageBox(, NStr("vi = 'Chỉ có thể in tệp có kiểu này từ ứng dụng dành cho Windows hoặc Linux.';
								|ru = 'Печать файлов данного типа возможна только из приложения для Windows или Linux.';
								|en = 'You can print this type of files only from an application for Windows or Linux.'; fa = 'You can print this type of files only from an application for Windows or Linux.';
								|it = 'La stampa dei file di questo tipo è possibile solo dall''applicazione per Windows o Linux.';
								|pl = 'Wydruk plików tego typu jest możliwy tylko z aplikacji dla Windows lub Linux.';
								|tr = 'Bu dosya türü yalnızca bir Windows veya Linux uygulamasından yazdırılabilir.'"));
		Return;
	EndIf;
#EndIf

EndProcedure

#EndRegion

#Region Other

// Calls directory selection dialog.
//
// Parameters:
//   CompletionHandler - CallbackDescription - Contains the details of the follow-up procedure that is called after the dialog is closed.
//                        The procedure parameters are:
//      # PathToDirectory - String - The full path to the directory. Returns an empty String if
//                        the 1C:Enterprise Extension is not installed or the user canceled out of the dialog.
//      # AdditionalParameters - Arbitrary - The value specified during the creation of the "NotifyDescription" object.
//   Title - String - a title of the directory selection dialog.
//   Directory   - String - the initial default directory value.
//
Procedure SelectDirectory(CompletionHandler, Title = "", Directory = "") Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Title", Title);
	Context.Insert("Directory", Directory);
	
	CallbackDescription = New CallbackDescription(
		"SelectDirectoryOnAttach1CEnterpriseExtension", FileSystemInternalClient, Context);
	Attach1CEnterpriseExtension(CallbackDescription);
	
EndProcedure

// Shows a file selection dialog window.
// In the web client, it prompts the user to install 1C:Enterprise Extension
// (if it's not installed).
//
// Parameters:
//   CompletionHandler - CallbackDescription - Describes the procedure to be called once the selection dialog is closed.
//           Parameters:
//      # Result - Array of String - Selected filenames.
//                        - String - An empty string if the user canceled out of the installation of the extension.
//                        - Undefined - If the user canceled out of the file selection dialog.
//      # AdditionalParameters - Arbitrary - Additional notification parameters.
//   Dialog - FileDialog - See the properties in Syntax Assistant.
//
Procedure ShowSelectionDialog(CompletionHandler, Dialog) Export
	
	Context = New Structure;
	Context.Insert("CompletionHandler", CompletionHandler);
	Context.Insert("Dialog", Dialog);
	
	CallbackDescription = New CallbackDescription(
		"ShowSelectionDialogOnAttach1CEnterpriseExtension", FileSystemInternalClient, Context);
	Attach1CEnterpriseExtension(CallbackDescription);
	
EndProcedure

// Gets temporary directory name.
//
// Parameters:
//  Notification - CallbackDescription - Notification about the acquisition details. Parameters::
//    # DirectoryName - String - Path to the created directory.
//    # AdditionalParameters - Arbitrary - Value specified during the creation of the "NotifyDescription" object.
//  Extension - String - the suffix in the directory name, which helps to identify the directory for analysis.
//
Procedure CreateTemporaryDirectory(Val Notification, Extension = "") Export 
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Extension", Extension);
	
	Notification = New CallbackDescription("CreateTemporaryDirectoryAfterCheck1CEnterpriseExtension",
		FileSystemInternalClient, Context);
	Attach1CEnterpriseExtension(Notification, 
		NStr("vi = 'Để tạo thư mục tạm thời, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
			|ru = 'Для создания временной папки установите расширение для работы с 1С:Предприятием.';
			|en = 'To create a temporary folder, install 1C:Enterprise Extension.'; fa = 'To create a temporary folder, install 1C:Enterprise Extension.';
			|it = 'Per la creazione della cartella temporanea installare l''estensione per il lavoro con 1C:Enterprise.';
			|pl = 'Aby utworzyć folder tymczasowy zainstaluj rozszerzenie do pracy z 1С:Enterprise.';
			|tr = 'Geçici dosya oluşturmak için 1C:Enterprise ile çalışma uzantısını yükleyin.'"), False);
	
EndProcedure

// Prompts the user to install 1C:Enterprise Extension in the web client.
// Incorporate the procedure at the beginning of code areas that process files.
//
// Parameters:
//  OnCloseNotifyDescription - CallbackDescription - Describes the procedure that is called once the form is closed.
//                                                     Parameters:
//    # ExtensionAttached - Boolean - "True" if the extension is attached.
//    AdditionalParameters - Arbitrary - Parameters specified in "OnCloseNotifyDescription".
//  SuggestionText - String - the message text. If the text is not specified, the default text is displayed.
//  CanContinueWithoutInstalling - Boolean - If True, displays the ContinueWithoutInstalling button.
//          If False, displays the Cancel button.
//
// Example:
//
//  Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//  MessageText = NStr("en = 'To print the document, install 1C:Enterprise Extension.'; fa = 'To print the document, install 1C:Enterprise Extension.'");
//  FileSystemClient.Attach1CEnterpriseExtension(Notification, MessageText);
//
//  Procedure PrintDocumentCompletion(ExtensionAttached, AdditionalParameters) Export
//    If ExtensionAttached Then
//     // Script that prints a document only if 1C:Enterprise Extension is attached.
//     // …
//    Else
//     // Script that prints a document if 1C:Enterprise Extension is not attached.
//     // …
//    EndIf;
//
Procedure Attach1CEnterpriseExtension(OnCloseNotifyDescription, SuggestionText = "",
	CanContinueWithoutInstalling = True) Export
	
	CallbackDescriptionCompletion = New CallbackDescription(
		"StartAttach1CEnterpriseExtensionWhenAnsweringToInstallationQuestion", FileSystemInternalClient,
		OnCloseNotifyDescription);
	
#If Not WebClient Then
	// In thin, thick, and web clients, the extension is always attached.
	RunCallback(CallbackDescriptionCompletion, "AttachmentNotRequired");
	Return;
#EndIf
	
	Context = New Structure;
	Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	Context.Insert("SuggestionText",             SuggestionText);
	Context.Insert("CanContinueWithoutInstalling", CanContinueWithoutInstalling);
	
	Notification = New CallbackDescription(
		"StartAttach1CEnterpriseExtension", FileSystemInternalClient, Context);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

// Generates a unique file name in the specified folder and adds a sequence number to the name if needed.
// For example: "file (2).txt", "file (3).txt", and so on.
//
// Parameters:
//   FileName - String - a full name of the file and folder. For example: "C:\Documents\file.txt".
//
// Returns:
//   String - For example: "C:\Documents\file (2).txt" if "file.txt" already exists in the folder.
//
Function UniqueFileName(Val FileName) Export
	
	Return FileSystemInternalClientServer.UniqueFileName(FileName);

EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use "Attach1CEnterpriseExtension"
// Prompts the user to install 1C:Enterprise Extension in the web client.
// Incorporate the procedure at the beginning of code areas that process files.
//
// Parameters:
//  OnCloseNotifyDescription - CallbackDescription - Describes the procedure that is called once the form is closed.
//                                                     Parameters:
//    # ExtensionAttached - Boolean - "True" if the extension is attached.
//    AdditionalParameters - Arbitrary - Parameters specified in "OnCloseNotifyDescription".
//  SuggestionText - String - the message text. If the text is not specified, the default text is displayed.
//  CanContinueWithoutInstalling - Boolean - If True, displays the ContinueWithoutInstalling button.
//          If False, displays the Cancel button.
//
// Example:
//
//  Notification = New NotifyDescription("PrintDocumentCompletion", ThisObject);
//  MessageText = NStr("en = 'To print the document, install 1C:Enterprise Extension.'; fa = 'To print the document, install 1C:Enterprise Extension.'");
//  FileSystemClient.AttachFileOperationsExtension(Notification, MessageText);
//
//  Procedure PrintDocumentCompletion(ExtensionAttached, AdditionalParameters) Export
//    If ExtensionAttached Then
//     // Script that prints a document only if 1C:Enterprise Extension is attached.
//     // …
//    Else
//     // Script that prints a document if 1C:Enterprise Extension is not attached.
//     // …
//    EndIf;
//
Procedure AttachFileOperationsExtension(OnCloseNotifyDescription, SuggestionText = "",
	CanContinueWithoutInstalling = True) Export
	
	CallbackDescriptionCompletion = New CallbackDescription(
		"StartAttach1CEnterpriseExtensionWhenAnsweringToInstallationQuestion", FileSystemInternalClient,
		OnCloseNotifyDescription);
	
#If Not WebClient Then
	// In thin, thick, and web clients, the extension is always attached.
	RunCallback(CallbackDescriptionCompletion, "AttachmentNotRequired");
	Return;
#EndIf
	
	Context = New Structure;
	Context.Insert("CallbackDescriptionCompletion", CallbackDescriptionCompletion);
	Context.Insert("SuggestionText",             SuggestionText);
	Context.Insert("CanContinueWithoutInstalling", CanContinueWithoutInstalling);
	
	Notification = New CallbackDescription(
		"StartAttach1CEnterpriseExtension", FileSystemInternalClient, Context);
	BeginAttachingFileSystemExtension(Notification);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Initializes a parameter structure to interact with the file system.
//
// Parameters:
//  DialogMode - FileDialogMode - the run mode of generating file selection dialog. 
//
// Returns:
//  Structure:
//   * Dialog - FileDialog
//   * Interactively - Boolean
//   * SuggestionText - String
//
Function OperationContext(DialogMode)
	
	Context = New Structure();
	Context.Insert("Dialog", New FileDialog(DialogMode));
	Context.Insert("Interactively", True);
	Context.Insert("SuggestionText", "");
	
	Return Context;
	
EndFunction

// Puts the selected files to a temporary storage.
// See FileSystemClient.ImportFile_and FileSystemClient.ImportFiles
//
Procedure ShowPutFile(CompletionHandler, PutParameters)
	
	PutParameters.Insert("CompletionHandler", CompletionHandler);
	CallbackDescription = New CallbackDescription(
		"ShowPutFileOnAttach1CEnterpriseExtension", FileSystemInternalClient, PutParameters);
	Attach1CEnterpriseExtension(CallbackDescription, PutParameters.SuggestionText);
	
EndProcedure

// Saves files from temporary storage to the file system.
// See FileSystemClient.SaveFileand FileSystemClient.SaveFiles
//
Procedure ShowDownloadFiles(CompletionHandler, FilesToSave, ReceivingParameters)
	
	ReceivingParameters.Insert("FilesToObtain",      FilesToSave);
	ReceivingParameters.Insert("CompletionHandler", CompletionHandler);
	
	CallbackDescription = New CallbackDescription(
		"ShowDownloadFilesOnAttach1CEnterpriseExtension", FileSystemInternalClient, ReceivingParameters);
	Attach1CEnterpriseExtension(CallbackDescription, ReceivingParameters.SuggestionText);
	
EndProcedure

// Gets the path to save the file in the temporary files catalog.
//
// Parameters:
//  FileName - String - the name of the file with an extension or the file extension without the dot.
//
// Returns:
//  String - path to save the file.
//
Function TempFileFullName(Val FileName)

#If WebClient Then
	
	Return ?(StrFind(FileName, ".") = 0, 
		Format(CommonClient.SessionDate(), "DF=yyyyMMddHHmmss") + "." + FileName, FileName);
	
#Else
	
	ExtensionPosition = StrFind(FileName, ".");
	If ExtensionPosition = 0 Then
		Return GetTempFileName(FileName);
	Else
		Return TempFilesDir() + FileName;
	EndIf;
	
#EndIf

EndFunction

// Trims the file name length based on the rule that the length of a full file path must be 260 characters maximum.
//
// Parameters:
//  FullFileName - String - a full file name with the path and extension.
//
Procedure ShortenFullFileNameToAllowedNTFSLength(FullFileName)
	
	AllowedNTFSLength = 260;
	FullFileNameLength = StrLen(FullFileName);
	
	If FullFileNameLength <= AllowedNTFSLength Then
		Return;
	EndIf;
	
	File = New File(FullFileName);
	
	ExtensionLength = StrLen(File.Extension);
	PathLength       = StrLen(File.Path);
	
	// Analyze the directory path length. 1 character is the minimum length of the directory name.
	If PathLength > AllowedNTFSLength - ExtensionLength - 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đường dẫn đến tệp quá dài:
		|%1';
		|ru = 'Путь к файлу слишком длинный:
		|%1';
		|en = 'File path is too long:
		|%1'; fa = 'File path is too long:
		|%1';
		|it = 'Il percorso al file è troppo lungo:
		|%1';
		|pl = 'Ścieżka do pliku jest zbyt długa:
		|%1';
		|tr = 'Dosya yolu çok uzun:
		|%1'"), FullFileName);
	EndIf;
	
	BaseName = Mid(File.BaseName, 1, AllowedNTFSLength - PathLength - ExtensionLength - 1);
	
	FullFileName = File.Path + BaseName + File.Extension;
	
EndProcedure

Procedure CheckIfTheLinuxProgramIsInstalled(ApplicationName, Notification)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Notification", Notification);
	TheLinuxProgramIsInstalledCompletion = New CallbackDescription("CheckTheLinuxProgramIsInstalledCompletion", 
		ThisObject, AdditionalParameters);
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetOutputStream", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", TheLinuxProgramIsInstalledCompletion);
	
	StartApplication(StringFunctionsClientServer.SubstituteParametersToString(
		"dpkg -s '%1'", String(ApplicationName)), ApplicationStartupParameters);
	
EndProcedure

Procedure CheckTheLinuxProgramIsInstalledCompletion(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	TheResultOfTheProcedure = StrFind(Result.OutputStream, "Status: install ok installed") <> False;
	RunCallback(Parameters.Notification, TheResultOfTheProcedure);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileName(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result = False Then
		ShowMessageBox(, StringFunctionsClient.FormattedString(
			NStr("vi = 'Để in chứng từ, cần cài đặt trên máy tính gói <a href=""%1"">Unoconv</a>.
			|
			|Để thực hiện điều này, hãy mở thiết bị và nhập:
			|%2
			|
			|Hoặc liên hệ với người quản trị.';
			|ru = 'Для печати документа требуется установить на компьютере пакет <a href=""%1"">Unoconv</a>.
			|
			|Для этого откройте терминал и введите:
			|%2
			|
			|Или обратитесь к администратору.';
			|en = 'To print out the document, install <a href=""%1"">Unoconv</a>.
			|
			|To do so, open the terminal and run:
			|%2
			|
			|Alternatively, send a request to the administrator.'; fa = 'To print out the document, install <a href=""%1"">Unoconv</a>.
			|
			|To do so, open the terminal and run:
			|%2
			|
			|Alternatively, send a request to the administrator.';
			|it = 'Для печати документа требуется установить на компьютере пакет <a href=""%1"">Unoconv</a>.
			|
			|Для этого откройте терминал и введите:
			|%2
			|
			|Или обратитесь к администратору.';
			|pl = 'To print out the document, install <a href=""%1"">Unoconv</a>.
			|
			|To do so, open the terminal and run:
			|%2
			|
			|Alternatively, send a request to the administrator.';
			|tr = 'Bir belgeyi yazdırmak için bilgisayarınıza <a href=""%1"">Unoconv</a> paketini yüklemeniz gerekir.
			|
			|Bunu yapmak için bir terminal açın ve şunu girin:
			|%2
			|
			|Veya yöneticinizle iletişime geçin.'"),
			"https://docs.moodle.org/404/en/Universal_Office_Converter_%28unoconv%29", 
			"sudo apt update
			|sudo apt install unoconv"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("PrintFromTheApplicationByTheLinuxFileNameRunningUnoconv", 
		ThisObject, Parameters);
	GetTheFullNameOfTheTemporaryFile(CallbackDescription);
		
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameRunningUnoconv(TempFileName, Parameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TheFileOfTheConvertedData", TempFileName);
	
	CallbackDescription = New CallbackDescription("PrintFromTheApplicationByTheLinuxFileNameRunningLpr", 
		ThisObject, AdditionalParameters);
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", CallbackDescription);
	
	CommandString = StringFunctionsClientServer.SubstituteParametersToString("unoconv --stdout '%1' >""%2""",
		Parameters.FileToOpenName, TempFileName);
	StartApplication(CommandString, ApplicationStartupParameters);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameRunningLpr(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Not Result.ApplicationStarted Then
		ShowMessageBox(, Result.ErrorDescription);
		Return;
	EndIf;
		
	Parameters.Insert("ErrorDescription", Result.ErrorDescription);
		
	CallbackDescription = New CallbackDescription("PrintFromTheApplicationByTheLinuxFileNameCompletion", ThisObject, Parameters);
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.Insert("WaitForCompletion", True);
	ApplicationStartupParameters.Insert("GetErrorStream", True);
	ApplicationStartupParameters.Insert("Notification", CallbackDescription);
	
	StartApplication(
		StringFunctionsClientServer.SubstituteParametersToString("lpr %1", Parameters.TheFileOfTheConvertedData), 
		ApplicationStartupParameters);
	
EndProcedure

Procedure PrintFromTheApplicationByTheLinuxFileNameCompletion(Result, Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	// ACC:566-off - Applicable only for Linux
	File = New File(Parameters.TheFileOfTheConvertedData);
	If File.Exists() Then
		DeleteFiles(Parameters.TheFileOfTheConvertedData);
	EndIf;
	// ACC:566-on
	
	If Not Result.ApplicationStarted Or ValueIsFilled(Result.ErrorDescription) 
		Or ValueIsFilled(Result.ErrorStream) Then

		ErrorDescription = TrimAll(?(ValueIsFilled(Result.ErrorDescription), 
			Result.ErrorDescription + Chars.LF, "") + Result.ErrorStream);
		
		Recommendation = ""; 
		If StrFind(Lower(ErrorDescription), "no default destination") > 0 Then
			Recommendation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Hãy xác định máy in mặc định:
					|• Hãy nhập trong thiết bị ""%1"" và chọn máy in cần thiết từ danh sách.
					|• Sau đó, hãy nhập trong thiết bị: %2 ""tên máy in cần thiết"".
					|Hoặc liên hệ với người quản trị.';
					|ru = 'Задайте принтер по умолчанию:
					|• Введите в терминале ""%1"" и выберите из списка нужный принтер.
					|• Затем введите в терминале: %2 ""имя нужного принтера"".
					|Или обратитесь к администратору.';
					|en = 'Set the default printer:
					|1. In the terminal window, run ""%1"" and select a printer from the list.
					|2. In the terminal window, run: %2 ""printer name"".
					|Alternatively, send a request to the administrator.'; fa = 'Set the default printer:
					|1. In the terminal window, run ""%1"" and select a printer from the list.
					|2. In the terminal window, run: %2 ""printer name"".
					|Alternatively, send a request to the administrator.';
					|it = 'Задайте принтер по умолчанию:
					|• Введите в терминале ""%1"" и выберите из списка нужный принтер.
					|• Затем введите в терминале: %2 ""имя нужного принтера"".
					|Или обратитесь к администратору.';
					|pl = 'Set the default printer:
					|1. In the terminal window, run ""%1"" and select a printer from the list.
					|2. In the terminal window, run: %2 ""printer name"".
					|Alternatively, send a request to the administrator.';
					|tr = 'Varsayılan yazıcıyı ayarlayın:
					|• Terminalde ""%1"" girin ve listeden istediğiniz yazıcıyı seçin.
					|• Ardından terminalde şunu girin: %2 ""istenen yazıcının adı"".
					|Veya yöneticinizle iletişime geçin.'"),
					"lpstat -p -d",
					"lpoptions -d");
		EndIf;
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể in chứng từ do:
				|%1';
				|ru = 'Не удалось распечатать документ по причине:
				|%1';
				|en = 'Couldn''t print the file. Reason:
				|%1'; fa = 'Couldn''t print the file. Reason:
				|%1';
				|it = 'Не удалось распечатать документ по причине:
				|%1';
				|pl = 'Couldn''t print the file. Reason:
				|%1';
				|tr = 'Dosya şu sebeple yazdırılamadı:
				|%1'"),
			ErrorDescription, Result.ReturnCode);
		If Result.ReturnCode <> 0 Then
			ErrorDescription = ErrorDescription 
				+ StringFunctionsClientServer.SubstituteParametersToString(" (%1)", Result.ReturnCode);
		EndIf;
		If Not IsBlankString(Recommendation) Then
			ErrorDescription = ErrorDescription + Chars.LF + Chars.LF + Recommendation;
		EndIf;
		
		EventLogClient.AddMessageForEventLog(NStr("vi = 'Phân hệ chuẩn';
													|ru = 'Стандартные подсистемы';
													|en = 'Standard subsystems'; fa = 'زیرسیستم‌های استاندارد';
													|it = 'Sottosistemi standard';
													|pl = 'Standardowe podsystemy';
													|tr = 'Standart alt sistemler'", 
				CommonClient.DefaultLanguageCode()),
			"Warning",,, True);
		ShowMessageBox(, ErrorDescription);
	EndIf;
	
EndProcedure

#Region GetTheFullNameOfTheTemporaryFile

// Getting the name of the temporary file.
//
// Parameters:
//  Notification - CallbackDescription - Notification about the acquisition details. Parameters::
//    # TemporaryFileName - String - Path to the temporary file.
//    # AdditionalParameters - Arbitrary - Value specified during the creation of the "NotifyDescription" object.
//  Extension - String - the extension of the temporary file.
//
Procedure GetTheFullNameOfTheTemporaryFile(Val Notification, Extension = "")
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Extension", Extension);
	
	Notification = New CallbackDescription("GetTheNameOfATemporaryFileAfterCheckingTheFileExtension",
		ThisObject, Context);
	Attach1CEnterpriseExtension(Notification, 
		NStr("vi = 'Để nhận tên của tệp tạm thời, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
			|ru = 'Для получения имени временного файла установите расширение для работы с 1С:Предприятием.';
			|en = 'To get a temporary file name, install 1C:Enterprise Extension.'; fa = 'To get a temporary file name, install 1C:Enterprise Extension.';
			|it = 'Per ricevere il nome del file temporaneo, installare l''estensione per il lavoro con 1C:Enterprise.';
			|pl = 'W celu uzyskania nazwy pliku tymczasowego zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
			|tr = 'Geçici dosya adını alabilmek için 1C:Enterprise çalışma uzantısını kurun.'"), False);
	
EndProcedure

// Continue the GetFullTempFileName procedure.
// 
// Parameters:
//  ExtensionAttached - Boolean
//  Context - Structure:
//   * Notification - CallbackDescription
//   * Extension - String
//
Procedure GetTheNameOfATemporaryFileAfterCheckingTheFileExtension(ExtensionAttached, Context) Export
	
	If ExtensionAttached Then
#If WebClient Then
		Notification = New CallbackDescription(
			"GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory", ThisObject, Context,
			"GetTheNameOfATemporaryFileWhenProcessingAnError", ThisObject);
		BeginGettingTempFilesDir(Notification);
#Else
		GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory("", Context);
#EndIf
	Else
		GetTheNameOfTheTemporaryFileNotifyAboutTheError(NStr("vi = 'Không thể cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
															|ru = 'Не удалось установить расширение для работы с 1С:Предприятием.';
															|en = 'Cannot install 1C:Enterprise Extension.'; fa = 'Cannot install 1C:Enterprise Extension.';
															|it = 'Impossibile installare l''estensione per il lavoro con 1C:Enterprise.';
															|pl = 'Nie udało się zainstalować folderu do pracy z 1C:Enterprise.';
															|tr = '1C:Enterprise ile çalışma için uzantı yüklenemedi.'"), 
			Context);
	EndIf;
	
EndProcedure

// Continue the GetFullTempFileName procedure.
// 
// Parameters:
//  TempFilesDirName - String
//  Context - Structure:
//   * Notification - CallbackDescription
//   * Extension - String
//
Procedure GetTheNameOfTheTemporaryFileAfterGettingTheTemporaryDirectory(TempFilesDirName, Context) Export
	
	Notification = Context.Notification;
	Extension = Context.Extension;
	
#If WebClient Then
	TempFileName = TempFilesDirName + String(New UUID);
#Else
	TempFileName = GetTempFileName(Extension); // ACC:441 - The function is a temporary file name getter.
#EndIf
	
	If Not IsBlankString(Extension) Then 
		TempFileName = TempFileName + "." + Extension;
	EndIf;
	
	RunCallback(Notification, TempFileName);
	
EndProcedure

// Continue the GetFullTempFileName procedure.
Procedure GetTheNameOfATemporaryFileWhenProcessingAnError(ErrorInfo, StandardProcessing, Context) Export
	
	StandardProcessing = False;
	ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	GetTheNameOfTheTemporaryFileNotifyAboutTheError(ErrorDescription, Context);
	
EndProcedure

// Continue the GetFullTempFileName procedure.
Procedure GetTheNameOfTheTemporaryFileNotifyAboutTheError(ErrorDescription, Context)
	
	ShowMessageBox(, ErrorDescription);
	TempFileName = "";
	RunCallback(Context.Notification, TempFileName);
	
EndProcedure

#EndRegion

#EndRegion