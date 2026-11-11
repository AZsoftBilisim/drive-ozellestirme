///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FilesManagementCommands

// Opens a file for viewing or editing.
// If the file is opened for viewing,
// the procedure searches for the file in the user working directory and suggest to open it or to get the file from the server.
// When the file is opened for editing, the procedure opens it in the working directory (if it exist) or
// retrieves the file from the server.
//
// Parameters:
//  FileData       - See FilesOperations.FileData.
//  ForEditing - Boolean - True to open the file for editing, False otherwise.
//
Procedure OpenFile(Val FileData, Val ForEditing = False) Export

	If FileData.Property("AsynchronousFileReceipt") Then
		
		FilesOperationsInternalClient.ActionWithFile(FileData);
		
	Else

		FilesOperationsInternalClient.OpenFileInternal(FileData, ForEditing);

	EndIf;

EndProcedure

// Opens the directory on the computer
// where the specified file is located in the standard viewer (explorer).
//
// Parameters:
//  FileData - See FilesOperations.FileData.
//
Procedure OpenFileDirectory(FileData) Export
	
	FilesOperationsInternalClient.FileDirectory(Undefined, FileData);
	
EndProcedure

// Opens a file selection dialog box for storing one or more files to the application.
// This checks the necessary conditions:
// - file does not exceed the maximum allowed size,
// - file has a valid extension,
// - volume has enough space (when storing files in volumes),
// - other conditions.
//
// Parameters:
//  FileOwner      - DefinedType.AttachedFilesOwner - a file folder or an object, to which
//                       you need to attach the file.
//  FormIdentifier - UUID - a form UUID,
//                       whose temporary storage the file will be placed to.
//  Filter             - String - filter of a file being selected, for example, pictures for products.
//  FilesGroup       - DefinedType.AttachedFile - a catalog group with files, to which 
//                       a new file will be added.
//  HandlerResults_1 - CallbackDescription - Description of a procedure to be called after adding files.
//                         This procedure takes the following parameters:
//        Result - Array - References to the added files. If no files are added, an empty array.
//        AdditionalParameters - Arbitrary - Value specified when creating the NotifyDescription.
//
Procedure AddFiles(Val FileOwner, Val FormIdentifier, Val Filter = "", FilesGroup = Undefined,
	HandlerResults_1 = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("vi = 'Chưa đặt giá trị tham số %1 trong %2.';
						|ru = 'Не задано значение параметра %1 в %2.';
						|en = 'The %1 parameter value is not set in %2.'; fa = 'The %1 parameter value is not set in %2.';
						|it = 'Non indicato valore del parametro %1 in %2.';
						|pl = 'Nie zadano wartości parametru %1 w %2.';
						|tr = '%2''da %1 parametre değeri ayarlanmadı.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner", 
			"FilesOperationsClient.AddFiles");
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("FileOwner",        FileOwner);
	Parameters.Insert("FormIdentifier",   FormIdentifier);
	Parameters.Insert("Filter",               Filter);
	Parameters.Insert("FilesGroup",         FilesGroup);
	Parameters.Insert("HandlerResults_1", HandlerResults_1);
	
	CallbackDescription = New CallbackDescription("AddFilesAddInSuggested", FilesOperationsInternalClient, Parameters);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(CallbackDescription);
	
EndProcedure

// Opens a file selection dialog box for storing a single file to the application.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription - Description of a procedure to be called after adding a file.
//                        This procedure takes the following parameters:
//                    * Result - Structure:
//                       ** FileRef - DefinedType.AttachedFile - a reference to the catalog item with the file
//                                     if it was added, Undefined otherwise.
//                       ** FileAdded - Boolean - True if file is added.
//                       ** ErrorText  - String - an error text if the file was not added.
//                    * AdditionalParameters - Arbitrary - a value specified when creating a notification object.
//
//   FileOwner - DefinedType.AttachedFilesOwner - a file folder or an object, to which
//                 you need to attach the file.
//   OwnerForm - ClientApplicationForm - a form from which the file creation was called.
//   CreateMode - Undefined
//                 - Number - file creation mode:
//                 - Undefined - show a dialog box to select a file creation mode.
//                 - Number - Create a file using the given method::
//                           1 - From a template (by copying another file)
//                           2 - From a computer (from the file system)
//                           3 - From a scanner.
//
//   AddingOptions - Structure - additional parameters of adding files:
//     * MaximumSize  - Number - a restriction on the size of the file (in megabytes) imported from the file system.
//                           If the value is 0, size is not checked. The property is ignored
//                           if its value is bigger than it is specified in the MaxFileSize constant.
//     * SelectionDialogFilter - String - a filter set in the selection dialog when adding a file.
//                           See the format description in the Filter property of the FileSelectionDialog object in Syntax Assistant.
//     * NotOpenCard - Boolean - an action after file creation. If it is True, a file card
//                           will not open after creation, otherwise, it will open.
//
Procedure AppendFile(HandlerResults_1, FileOwner, OwnerForm, CreateMode = Undefined, 
	AddingOptions = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("vi = 'Chưa đặt giá trị tham số %1 trong %2.';
						|ru = 'Не задано значение параметра %1 в %2.';
						|en = 'The %1 parameter value is not set in %2.'; fa = 'The %1 parameter value is not set in %2.';
						|it = 'Non indicato valore del parametro %1 in %2.';
						|pl = 'Nie zadano wartości parametru %1 w %2.';
						|tr = '%2''da %1 parametre değeri ayarlanmadı.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner",
			"FilesOperationsClient.AppendFile");
	EndIf;
	
	ExecutionParameters = New Structure;
	If AddingOptions = Undefined
		Or TypeOf(AddingOptions) = Type("Boolean") Then
		
		ExecutionParameters.Insert("MaximumSize" , 0);
		ExecutionParameters.Insert("NotOpenCard", ?(AddingOptions = Undefined, False, AddingOptions));
		ExecutionParameters.Insert("SelectionDialogFilter",  
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask()));
		
	Else
		ExecutionParameters.Insert("MaximumSize" , AddingOptions.MaximumSize);
		ExecutionParameters.Insert("NotOpenCard", AddingOptions.NotOpenCard);
		ExecutionParameters.Insert("SelectionDialogFilter", AddingOptions.SelectionDialogFilter);
	EndIf;
	
	If CreateMode = Undefined Then
		FilesOperationsInternalClient.AppendFile(HandlerResults_1, FileOwner, OwnerForm, , ExecutionParameters);
	Else
		ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
		ExecutionParameters.Insert("FileOwner", FileOwner);
		ExecutionParameters.Insert("OwnerForm", OwnerForm);
		ExecutionParameters.Insert("OneFileOnly", True);
		FilesOperationsInternalClient.AddAfterCreationModeChoice(CreateMode, ExecutionParameters);
	EndIf;
	
EndProcedure

// Opens the form for setting the parameters of the working directory from the application user personal settings.
// A working directory is a folder on the user personal computer where files
// received from a viewer or editor are temporarily stored.
//
Procedure OpenWorkingDirectorySettingsForm() Export
	
	OpenForm("CommonForm.WorkingDirectorySettings");
	
EndProcedure

// Show a warning before closing the object form
// if the user still has captured files attached to this object.
// Called from the BeforeClose event of forms with files.
//
// If the captured files remain, then the Cancel parameter is set to True,
// and the user is asked a question. If the user answers yes, the form closes.
//
// Parameters:
//   Form            - ClientApplicationForm - a form, where the file is edited.
//   Cancel            - Boolean - BeforeClose event parameter.
//   Exit - Boolean - indicates whether the form closes when a user exits the application.
//   FilesOwner   - DefinedType.AttachedFilesOwner - a file folder or an object, to which
//                      files are attached.
//   AttributeName     - String - name of the Boolean type attribute, which stores the flag showing that
//                      the question has already been output.
//
// Example:
//
//	&AtClient
//	Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
//		FilesOperationsClient.ShowConfirmationOfCloseFormWithFiles(ThisObject, Cancel, WorkCompletion, Object.Ref);
//	EndProcedure
//
Procedure ShowConfirmationForClosingFormWithFiles(Form, Cancel, Exit, FilesOwner,
	AttributeName = "CanCloseFormWithFiles") Export
	
	ProcedureName = "FilesOperationsClient.ShowConfirmationForClosingFormWithFiles";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "Cancel", Cancel, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "Exit", Exit, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "AttributeName", AttributeName, Type("String"));
		
	If Form[AttributeName] Then
		Return;
	EndIf;
	
	If Exit Then
		Return;
	EndIf;
	
	Count = FilesOperationsInternalServerCall.FilesLockedByCurrentUserCount(FilesOwner);
	If Count = 0 Then
		Return;
	EndIf;
	
	Cancel = True;
	
	QueryText = NStr("vi = 'Một hoặc nhiều tệp đang bị chiếm để chỉnh sửa.
	                          |
	                          |Tiếp tục?';
	                          |ru = 'Один или несколько файлов заняты для редактирования.
	                          |
	                          |Продолжить?';
	                          |en = 'One or several files are locked for editing.
	                          |
	                          |Do you want to continue?'; fa = 'One or several files are locked for editing.
	                          |
	                          |Do you want to continue?';
	                          |it = 'Uno o più file sono in corso di modifica.
	                          |
	                          |Continuare?';
	                          |pl = 'Jeden lub kilka plików są zajęte dla edycji.
	                          |
	                          |Kontynuować?';
	                          |tr = 'Bir veya birkaç dosya düzenlemek için kilitlendi. 
	                          |
	                          | Devam edilsin mi?'");
	CommonClient.ShowArbitraryFormClosingConfirmation(Form, Cancel, Exit, QueryText, AttributeName);
	
EndProcedure

// Opens a new file form with a copy of the specified file.
//
// Parameters:
//  FileOwner - DefinedType.AttachedFilesOwner - a file folder or an object, to which a file is attached.
//  BasisFile - DefinedType.AttachedFile - a file being copied.
//  AdditionalParameters - Structure - form opening parameters:
//    * FilesStorageCatalogName - String - defines a catalog to store a file copy.
//  OnCloseNotifyDescription - CallbackDescription - Description of a procedure to be called when the form is closed.
//                                This procedure takes the following parameters:
//                                <ClosingResult> - Value passed when calling Close() of the form.
//                                <AdditionalParameters> - Value specified when creating OnCloseNotifyDescription.
//                                If the parameter is not specified, no procedure is called on close.
//                                
//
Procedure CopyAttachedFile(FileOwner, BasisFile, AdditionalParameters = Undefined,
	OnCloseNotifyDescription = Undefined) Export
	
	If Not ValueIsFilled(FileOwner) Then
		Template = NStr("vi = 'Chưa đặt giá trị tham số %1 trong %2.';
						|ru = 'Не задано значение параметра %1 в %2.';
						|en = 'The %1 parameter value is not set in %2.'; fa = 'The %1 parameter value is not set in %2.';
						|it = 'Non indicato valore del parametro %1 in %2.';
						|pl = 'Nie zadano wartości parametru %1 w %2.';
						|tr = '%2''da %1 parametre değeri ayarlanmadı.'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(Template, "FileOwner",
			"FilesOperationsClient.CopyAttachedFile");
	EndIf;
	
	AreFiles = TypeOf(BasisFile) = Type("CatalogRef.Files");
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
		FilesStorageCatalogName = Undefined;
		If AdditionalParameters.Property("FilesStorageCatalogName", FilesStorageCatalogName) Then
			AreFiles = (FilesStorageCatalogName = "Files");
		EndIf;
	EndIf;
	
	FormParameters.Insert("CopyingValue", BasisFile);
	FormParameters.Insert("FileOwner", FileOwner);
	
	If AreFiles Then
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,,,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// Opens a list of file digital signatures and prompts to choose signatures
// to save with the file by the user-selected path.
// The file signature name is generated from the file name and the signature author with the "p7s" extension.
//
// If there is no "Digital signature" subsystem in the configuration, the file will not be saved.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with file.
//  FormIdentifier - UUID  - a form UUIDthat is used to lock the file.
//
Procedure SaveWithDigitalSignature(Val AttachedFile, Val FormIdentifier) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToSave(AttachedFile);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("AttachedFile", AttachedFile);
	ExecutionParameters.Insert("FileData",        FileData);
	ExecutionParameters.Insert("FormIdentifier", FormIdentifier);
	
	DataDetails = New Structure;
	DataDetails.Insert("DataTitle",     NStr("vi = 'Tệp';
											|ru = 'Файл';
											|en = 'File'; fa = 'فایل';
											|it = 'File';
											|pl = 'File';
											|tr = 'Dosya'"));
	DataDetails.Insert("ShowComment", True);
	DataDetails.Insert("Presentation",       ExecutionParameters.FileData.Ref);
	DataDetails.Insert("Object",              AttachedFile);
	
	DataDetails.Insert("Data",
		New CallbackDescription("OnSaveFileData", FilesOperationsInternalClient, ExecutionParameters));
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	ModuleDigitalSignatureClient.SaveDataWithSignature(DataDetails);
	
EndProcedure

// Opens a save file dialog box where the user can define a path and a name to save the file.
//
// Parameters:
//   FileData           - See FilesOperations.FileData.
//   CompletionHandler  - CallbackDescription
//                         - Undefined - Description of a procedure to be called once this procedure
//                           is competed. It takes the following parameters::
//      PathToFile - String - Full path to the saved file.
//      AdditionalParameters - Arbitrary - Value that was specified when creating the NotifyDescription object.
//
Procedure SaveFileAs(Val FileData, CompletionHandler = Undefined) Export

	If FileData.Property("AsynchronousFileReceipt") Then

		FilesOperationsInternalClient.ActionWithFile(FileData);

	Else

		FilesOperationsInternalClient.SaveFileAsInternal(FileData, CompletionHandler);

	EndIf;

EndProcedure

// Opens the file selection form.
// Used in selection handler for overriding the default behavior.
//
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner - a file folder or an object,
//                   to which files to select are attached.
//  FormItem   - FormTable
//                 - FormField - the form item that will receive
//                   a selection notification.
//  StandardProcessing - Boolean - a return value. Always set to False.
//  ChoiceNotificationDetails - CallbackDescription - Description of a procedure to be called when the form is closed. 
//                                                   This procedure takes the following parameters:
//    SelectionValue - DefinedType.AttachedFile
//                   - Undefined - if a value has been selected, 
//                     the selected value is returned. Otherwise, Undefined is returned.
//    AdditionalParameters - Arbitrary - a value specified when creating OnCloseNotifyDescription.
//
Procedure OpenFileChoiceForm(Val FilesOwner, Val FormItem, StandardProcessing = False,
	ChoiceNotificationDetails = Undefined) Export
	
	StandardProcessing = False;

	If FilesOwner.IsEmpty() Then
		OnCloseNotifyHandler = New CallbackDescription("PromptForWriteRequiredAfterCompletion", ThisObject);
		ShowQueryBox(OnCloseNotifyHandler,
			NStr("vi = 'Dữ liệu vẫn chưa được ghi lại. 
				|Chỉ có thể chuyển sang ""Tệp đính kèm"" sau khi ghi lại dữ liệu.';
				|ru = 'Данные еще не записаны. 
				|Переход к ""Присоединенные файлы"" возможен только после записи данных.';
				|en = 'You have unsaved data.
				|You can open ""Attachments"" after saving the data.'; fa = 'You have unsaved data.
				|You can open ""Attachments"" after saving the data.';
				|it = 'I dati non sono ancora stati registrati. 
				|Il passaggio a ""File allegati"" è possibile solo dopo la registrazione dei dati.';
				|pl = 'Dane nie są jeszcze zapisane. 
				|Przejście do ""Dołączone pliki"" możliwy jest tylko po zapisaniu danych.';
				|tr = 'Veriler henüz kaydedilmedi. 
				|""Ekli dosyalara"" geçiş yalnızca veri kaydından sonra mümkündür.'"),
				QuestionDialogMode.OK);
	Else
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("FileOwner", FilesOwner);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters, FormItem,,,,
						?(ChoiceNotificationDetails <> Undefined, ChoiceNotificationDetails, Undefined));
	EndIf;
	
EndProcedure

// Opens the file list form.
// 
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner - a file folder or an object,
//                   to which files to select are attached.
//  FormParameters - See FileListFormOpeningParameters 
//  FormOwner - ClientApplicationForm
//  ClosingNotification1 - CallbackDescription
//
Procedure OpenFileListForm(Val FilesOwner, Val FormParameters = Undefined, 
	FormOwner = Undefined, ClosingNotification1 = Undefined) Export
	
	If FilesOperationsInternalClient.Is1CDocumentManagementUsedForFileStorage(FilesOwner) Then
		
		// IntegrationWith1CDocumentManagement
		FilesOperationsInternalClient.OpenFormAttachedFiles1CDocumentManagement(FilesOwner);
		// End IntegrationWith1CDocumentManagement
		
	Else
		If FormParameters = Undefined Then
			FormParameters = FileListFormOpeningParameters(FilesOwner);
		EndIf;
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters, FormOwner, , , , 
			ClosingNotification1);
	EndIf;
	
EndProcedure

// Constructor of file list form opening parameters for "OpenFileListForm".
// 
// Parameters:
//  FilesOwner - DefinedType.AttachedFilesOwner - File folder or an object,
//                   to which files to select are attached.
//  FixedSettings - DataCompositionSettings - Dynamic list settings
// 
// Returns:
//  Structure:
//    * FileOwner - DefinedType.AttachedFilesOwner - File folder or an object,
//                      to which files to select are attached.
//    * ShouldHideOwner - Boolean - Flag indicating whether the element is shown on the file owner form.
//    * FixedSettings - DataCompositionSettings - Dynamic list settings.
//
Function FileListFormOpeningParameters(FilesOwner, FixedSettings = Undefined) Export

	FormParameters = New Structure;
	FormParameters.Insert("FileOwner", FilesOwner);
	FormParameters.Insert("ShouldHideOwner", False);
	FormParameters.Insert("FixedSettings", FixedSettings);
	
	Return FormParameters;
			
EndFunction

// Opens the file form.
// Can be used as a file opening handler.
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with file.
//  StandardProcessing    - Boolean - a return value. Always set to False.
//  AdditionalParameters - Structure - form opening parameters.
//  OnCloseNotifyDescription - CallbackDescription - Description of a procedure to be called when the form is closed.
//                                This procedure takes the following parameters:
//                                <ClosingResult> - Value passed when calling Close() of the form.
//                                <AdditionalParameters> - Value specified when creating OnCloseNotifyDescription. 
//                                If the parameter is not specified, no procedure is called on close. 
//                                
//
Procedure OpenFileForm(Val AttachedFile, StandardProcessing = False, AdditionalParameters = Undefined, 
	OnCloseNotifyDescription = Undefined) Export
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(AttachedFile) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		FormParameters = CommonClient.CopyRecursive(AdditionalParameters);
	EndIf;	
	If TypeOf(AttachedFile) = Type("CatalogRef.Files") Then
		FormParameters.Insert("Key", AttachedFile);
		OpenForm("Catalog.Files.ObjectForm", FormParameters,,,,, OnCloseNotifyDescription);
	Else	
		FormParameters.Insert("AttachedFile", AttachedFile);
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFile", FormParameters,, AttachedFile,,, OnCloseNotifyDescription);
	EndIf;
	
EndProcedure

// Prints files.
//
// Parameters:
//  Files              - DefinedType.AttachedFile
//                     - Array of DefinedType.AttachedFile
//  FormIdentifier - UUID - a form UUID,
//                       whose temporary storage the file will be placed to.
//
Procedure PrintFiles(Val Files, FormIdentifier = Undefined) Export
	
	If TypeOf(Files) <> Type("Array") Then
		Files = CommonClientServer.ValueInArray(Files);
	EndIf;
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileNumber",   0);
	ExecutionParameters.Insert("FilesData", Files);
	ExecutionParameters.Insert("FileData",  Files);
	ExecutionParameters.Insert("UUID", FormIdentifier);
	PrintFilesExecution(Undefined, ExecutionParameters);
	
EndProcedure

// Signs a file with a digital signature.
// If the "Digital signature" subsystem isn't integrated, warns users that signing is unavailable.
// 
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with file.
//                          - Array of DefinedType.AttachedFile
//  FormIdentifier      - UUID - a form UUID
//                            that is used to lock the file.
//  AdditionalParameters - Undefined - Standard behavior (see below).
//                          - Structure:
//       * FileData            - See FilesOperations.FileData
//                                - Array of See FilesOperations.FileData
//       * ResultProcessing    - CallbackDescription - when called, a Boolean value is passed,
//                                  if True, the file is signed successfully, otherwise it is not signed
//                                  . if the property is not present, the alert will not be called.
//  SignatureParameters         - See DigitalSignatureClient.NewSignatureType
//
Procedure SignFile(AttachedFile, FormIdentifier, AdditionalParameters = Undefined,
	SignatureParameters = Undefined) Export
	
	If Not ValueIsFilled(AttachedFile) Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn tệp cần ký.';
								|ru = 'Не выбран файл, который нужно подписать.';
								|en = 'Please select a file to sign.'; fa = 'Please select a file to sign.';
								|it = 'Non è selezionato il file che bisogna firmare.';
								|pl = 'Nie wybrano pliku, który należy podpisać.';
								|tr = 'İmzalanacak dosya seçilmedi.'"));
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ShowMessageBox(, NStr("vi = 'Việc thêm chữ ký điện tử không hợp lệ trong phiên bản này của ứng dụng.';
								|ru = 'Добавление электронных подписей не доступно в этой версии приложения.';
								|en = 'This app version doesn''t support adding digital signatures.'; fa = 'This app version doesn''t support adding digital signatures.';
								|it = 'Добавление электронных подписей не доступно в этой версии приложения.';
								|pl = 'This app version doesn''t support adding digital signatures.';
								|tr = 'Uygulamanın bu versiyonunda elektronik imza ekleme özelliği mevcut değildir.'"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If Not ModuleDigitalSignatureClient.UseDigitalSignature() Then
		ShowMessageBox(,
			NStr("vi = 'Đã cấm thêm chữ ký điện tử trong tùy chỉnh ứng dụng.';
				|ru = 'Добавление электронных подписей запрещено в настройках приложения.';
				|en = 'Digital signatures cannot be added due to the app settings.'; fa = 'Digital signatures cannot be added due to the app settings.';
				|it = 'Добавление электронных подписей запрещено в настройках приложения.';
				|pl = 'Digital signatures cannot be added due to the app settings.';
				|tr = 'Uygulamanın ayarlarında elektronik imza ekleme özelliği yasaktır.'"));
		Return;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("FileData") Then
		AdditionalParameters.Insert("FileData", FilesOperationsInternalServerCall.FileDataForSigning(
			AttachedFile, FormIdentifier));
	EndIf;
	
	ResultProcessing = Undefined;
	AdditionalParameters.Property("ResultProcessing", ResultProcessing);
	
	FilesOperationsInternalClient.SignFile(AttachedFile,
		AdditionalParameters.FileData, FormIdentifier, ResultProcessing, Undefined, SignatureParameters);
	
EndProcedure

// Sends a file to the mobile signing service.
// If the "Digital signature" and "Mobile signing service" subsystems aren't integrated,
// warns the user that signing is unavailable.
//
// Parameters:
//  AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with file.
//                          - Array of DefinedType.AttachedFile
//  FormIdentifier      - UUID - a form UUID
//                            that is used to lock the file.
//  AdditionalParameters - Undefined - Standard behavior (see below).
//                          - Structure:
//       * FileData            - See FilesOperations.FileData
//                                - Array of See FilesOperations.FileData
//       * ResultProcessing    - CallbackDescription - when calling, a Boolean value is passed
//                                  . If True, the file was successfully sent for signature, otherwise it was not sent
//                                  . If there is no property, the alert will not be triggered.
//  SignatureParameters         - See DigitalSignatureClient.NewSignatureType
//
Procedure SendFileForSigning(AttachedFile, FormIdentifier, AdditionalParameters = Undefined,
	SignatureParameters = Undefined) Export
	
	If Not ValueIsFilled(AttachedFile) Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn tệp cần ký.';
								|ru = 'Не выбран файл, который нужно подписать.';
								|en = 'Please select a file to sign.'; fa = 'Please select a file to sign.';
								|it = 'Non è selezionato il file che bisogna firmare.';
								|pl = 'Nie wybrano pliku, który należy podpisać.';
								|tr = 'İmzalanacak dosya seçilmedi.'"));
		Return;
	EndIf;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ShowMessageBox(, NStr("vi = 'Việc thêm chữ ký điện tử không hợp lệ trong phiên bản này của ứng dụng.';
								|ru = 'Добавление электронных подписей не доступно в этой версии приложения.';
								|en = 'This app version doesn''t support adding digital signatures.'; fa = 'This app version doesn''t support adding digital signatures.';
								|it = 'Добавление электронных подписей не доступно в этой версии приложения.';
								|pl = 'This app version doesn''t support adding digital signatures.';
								|tr = 'Uygulamanın bu versiyonunda elektronik imza ekleme özelliği mevcut değildir.'"));
		Return;
	EndIf;
	
	ModuleDigitalSignatureClient = CommonClient.CommonModule("DigitalSignatureClient");
	
	If Not ModuleDigitalSignatureClient.UseDigitalSignature() Then
		ShowMessageBox(,
			NStr("vi = 'Đã cấm thêm chữ ký điện tử trong tùy chỉnh ứng dụng.';
				|ru = 'Добавление электронных подписей запрещено в настройках приложения.';
				|en = 'Digital signatures cannot be added due to the app settings.'; fa = 'Digital signatures cannot be added due to the app settings.';
				|it = 'Добавление электронных подписей запрещено в настройках приложения.';
				|pl = 'Digital signatures cannot be added due to the app settings.';
				|tr = 'Uygulamanın ayarlarında elektronik imza ekleme özelliği yasaktır.'"));
		Return;
	EndIf;
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If Not AdditionalParameters.Property("FileData") Then
		AdditionalParameters.Insert("FileData", FilesOperationsInternalServerCall.FileDataForSigning(
			AttachedFile, FormIdentifier));
	EndIf;
	
	ResultProcessing = Undefined;
	AdditionalParameters.Property("ResultProcessing", ResultProcessing);
	
	FilesOperationsInternalClient.SendFileForSigning(AttachedFile,
		AdditionalParameters.FileData, FormIdentifier, ResultProcessing, Undefined, SignatureParameters);
	
EndProcedure

// Returns the structured file information. It is used in variety of file operation commands
// and as FileData parameter value in other procedures and functions.
//
// Parameters:
//   FileRef - DefinedType.AttachedFile - a reference to the catalog item with file.
//   FormIdentifier             - UUID - a form UUID. The method puts the file to the temporary storage
//                                     of this form and returns the address in the RefToBinaryFileData property.
//   GetBinaryDataRef - Boolean - if False, reference to the binary data in the RefToBinaryFileData
//                                     is not received thus significantly speeding up execution for large binary data.
//   ForEditing              - Boolean - if you specify True, a file will be locked for editing.
//
// Returns:
//   See FilesOperations.FileData
//
Function FileData(Val FileRef,
                    Val FormIdentifier = Undefined,
                    Val GetBinaryDataRef = True,
                    Val ForEditing = False) Export

	AdditionalParameters = FilesOperationsClientServer.FileDataParameters();
	AdditionalParameters.FormIdentifier				= FormIdentifier;
	AdditionalParameters.GetBinaryDataRef	= GetBinaryDataRef;
	AdditionalParameters.ForEditing				= ForEditing;

	Return FilesOperationsInternalServerCall.GetFileData(FileRef, AdditionalParameters);

EndFunction

// Receives a file from the file storage to the user working directory.
// This is an alternative to the "View" or "Edit" interactive actions without opening the received file.
// The ReadOnly property of the received file will be set depending on
// whether the file is locked for editing or not. If it is not locked, the read only mode is set.
// If there is an existing file in the working directory, it will be deleted and replaced by the file,
// received from the file storage.
//
// Parameters:
//  Notification - CallbackDescription - Notification that is triggered after the user's working directory
//   receives the file. The return value is a structure with the following properties::
//     FullFileName - String - Full file name (with the path).
//     ErrorDescription - String - Error text if the file was not received.
//
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with file.
//  FormIdentifier - UUID - a form UUID,
//                       whose temporary storage the file will be placed to.
//
//  AdditionalParameters - Undefined - use the default values.
//                          - Structure - with optional properties:
//         * ForEditing - Boolean    - initial value is False. If True,
//                                           the file will be locked for editing.
//         * FileData       - Structure - file properties that can be passed for acceleration
//                                           if they were previously received by the client from the server.
//
Procedure GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.GetAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters);
	
EndProcedure

// Places the file from the user working directory into the file storage.
// It is an alternative to the "Finish Editing" interactive action.
//
// Parameters:
//  Notification - CallbackDescription - Notification that is triggered after the file storage receives a file.
//   The return value is a structure with the following property::
//     ErrorDescription - String - Error text if the file was not received.
//
//  AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with file.
//  FormIdentifier - UUID - a form UUID.
//          The method puts data to the temporary storage of this form and returns the new address.
//
//  AdditionalParameters - Undefined - use the default values.
//                          - Structure - with optional properties:
//         * FullFileName - String - if filled, the specified file will be placed in the
//                                     user working directory, and then in the file storage.
//         * FileData    - Structure - file properties that can be passed for acceleration
//                                        if they were previously received by the client from the server.
//
Procedure PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters = Undefined) Export
	
	FilesOperationsInternalClient.PutAttachedFile(Notification, AttachedFile, FormIdentifier, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region ScannerOperations

// Opens the scan settings form from user settings.
//
Procedure OpenScanSettingForm() Export
	
	If Not FilesOperationsInternalClient.ScanAvailable() Then
		MessageText = NStr("vi = 'Việc quét được phép trong ứng dụng đối với Microsoft Windows và Linux.';
							|ru = 'Сканирование доступно в приложении для Microsoft Windows и Linux.';
							|en = 'Scanning is supported for MS Windows and Linux OS.'; fa = 'Scanning is supported for MS Windows and Linux OS.';
							|it = 'Сканирование доступно в приложении для Microsoft Windows и Linux.';
							|pl = 'Scanning is supported for MS Windows and Linux OS.';
							|tr = 'Tarama, Microsoft Windows ve Linux için uygulamada mevcuttur.'");
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
	
	Handler = New CallbackDescription("OpenScanSettingFormCompletion", ThisObject);
	
	FilesOperationsInternalClient.InitAddIn(Handler, True);
		
EndProcedure

// Constructor of parameters to convert graphic documents to PDF.
// 
// Returns:
//  Structure:
//   * ResultType - See ConversionResultTypeFileName
//                   - See ConversionResultTypeBinaryData
//                   - See ConversionResultTypeAttachedFile
//   * ResultFormat - String - the format of the resulting file is "pdf" or "tif"
//   * ResultFileName - See ConversionResultTypeFileName
//   * UseImageMagick - Boolean - whether to use the ImageMagick utility
//
Function GraphicDocumentConversionParameters() Export
	
	ConversionParameters_SSLy = New Structure;
	ConversionParameters_SSLy.Insert("ResultType", ConversionResultTypeFileName());
	ConversionParameters_SSLy.Insert("ResultFormat", "pdf");
	ConversionParameters_SSLy.Insert("ResultFileName", "");
	
	UserScanSettings = GetUserScanSettings();
	
	ConversionParameters_SSLy.Insert("UseImageMagick", 
		UserScanSettings.UseImageMagickToConvertToPDF);
		
	Return ConversionParameters_SSLy;
	
EndFunction

// Returns the result type of conversion to a file on the client.
// 
// Returns:
//  String
//
Function ConversionResultTypeFileName() Export
	
	Return "File";
	
EndFunction

// Returns the result type of conversion to binary data.
// 
// Returns:
//  String
//
Function ConversionResultTypeBinaryData() Export
	
	Return "BinaryData";
	
EndFunction

// Indicates the result type of conversion to an attachment.
// 
// Returns:
//  String
//
Function ConversionResultTypeAttachedFile() Export
	
	Return "AttachedFile";
	
EndFunction


// Merge an array of transferred documents into one with the possibility of conversion.
// 
// Parameters:
//  NotificationOfReturn - CallbackDescription - procedure that will be executed after merging the files.
//  ObjectsForMerging - Array of BinaryData, DefinedType.AttachedFile, String - 
//                          Objects can be input as binary data, a reference to an attachment, or as a path to files
//                          on the client.
//  GraphicDocumentConversionParameters - See FilesOperationsClient.GraphicDocumentConversionParameters.
// 
Procedure MergeIntoMultiPageFile(NotificationOfReturn, ObjectsForMerging, GraphicDocumentConversionParameters) Export
	
	Result = ResultOfMergeIntoMultipageDocument();
	UserScanSettings = GetUserScanSettings();
	
	UseImageMagick = GraphicDocumentConversionParameters.UseImageMagick; 
	PathToConverterApplication = UserScanSettings.PathToConverterApplication;
	
		Context = New Structure;
	Context.Insert("NotificationOfReturn", NotificationOfReturn);
	Context.Insert("ObjectsForMerging", ObjectsForMerging);
	Context.Insert("GraphicDocumentConversionParameters", GraphicDocumentConversionParameters);
	Context.Insert("UserScanSettings", UserScanSettings);
	
	If ObjectsForMerging.Count() = 0 Then
		Result.ErrorDescription = NStr("vi = 'Chưa chỉ ra hình ảnh để hợp nhất.';
										|ru = 'Не указаны изображения для объединения.';
										|en = 'Images for merging are not specified.'; fa = 'Images for merging are not specified.';
										|it = 'Не указаны изображения для объединения.';
										|pl = 'Images for merging are not specified.';
										|tr = 'Birleştirilecek görsel belirtilmedi.'");
		RunCallback(NotificationOfReturn, Result);
		Return;
	ElsIf UseImageMagick And Not ValueIsFilled(PathToConverterApplication) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa chỉ ra đường dẫn đến ứng dụng %1.
			|Thực hiện hợp nhất các văn bản có nhiều trang bằng các công cụ thông thường.';
			|ru = 'Не указан путь к приложению %1.
			|Объединение многостраничных документов выполняется штатными средствами.';
			|en = 'Path to %1 is missing.
			|Multipage documents are merged using 1C:Enterprise tools.'; fa = 'Path to %1 is missing.
			|Multipage documents are merged using 1C:Enterprise tools.';
			|it = 'Path to %1 is missing.
			|Multipage documents are merged using 1C:Enterprise tools.';
			|pl = 'Path to %1 is missing.
			|Multipage documents are merged using 1C:Enterprise tools.';
			|tr = '%1 uygulamasının yolu belirtilmedi.
			|Çok sayfalı belgelerin birleştirilmesi standart araçlar kullanılarak gerçekleştirilmektedir.'"), 
			"ImageMagick");
		
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorText,, True);
		Context.GraphicDocumentConversionParameters.UseImageMagick = False;
		MergeIntoMultiPageFileContinued(Context);
		Return;
	EndIf;
	
#If Not WebClient And Not MobileClient Then
	If UseImageMagick Then
		NotificationOfResult = New CallbackDescription("AfterCheckIfConversionAppInstalled", ThisObject, Context);
		StartCheckConversionAppPresence(PathToConverterApplication, NotificationOfResult);
		Return;
	EndIf;
	
	MergeIntoMultiPageFileContinued(Context);
#EndIf
EndProcedure

// Constructor of scanning parameters.
// 
// Parameters:
//  Fill - Boolean - fill with current values saved for the user.
// 
// Returns:
//  Structure:
//   * ShowDialogBox - Boolean - indicates whether the scanning dialog box (provided by the scanner driver) with available resolution and other settings
//                                  is opened.
//   * SelectedDevice - String - scanner name.
//   * PictureFormat - String - picture format requested from the driver.
//   * Resolution - Number - DPI resolution.
//   * Chromaticity - Number - possible values: 0 (black and white), 1 (grayscale), 2 (colored).
//   * Rotation - Number - Rotation angle. Valid values: 0, 90, 180, 270. Some scanners do not support rotation. 
//                       
//   * PaperSize - Number - Valid values:
//     0 - Not specified
//     11 - A3
//     1 - A4
//     5 - A5
//     6 - B4
//     2 - B5
//     7 - B6
//     14 - C4
//     15 - C5
//     16 - C6
//     3 - USLetter
//     4 - USLegal
//     10 - USExecutive
//                            Some scanners do not support paper size.
//   * JPGQuality - Number - quality for JPG format (from 1 to 100 where 100 is the maximum quality
//                           and maximum size).
//   * TIFFDeflation - Number - Compression. Valid values::
//     2 - LZW
//     3 - CCITT3
//     4 - CCITT4
//     5 - RLE
//     6 - No compression
//   * DuplexScanning - Boolean - Scan both sides.
//   * DocumentAutoFeeder - Boolean - Use the auto feeder.
//   * ShouldSaveAsPDF - Boolean
//   * UseImageMagickToConvertToPDF - Boolean
//
Function ScanningParameters(Fill = False) Export
	ScanningParameters = FilesOperationsInternalClientServer.ScanningParameters();
	ClientID = FilesOperationsInternalClient.ClientID();
	
	If Fill And ClientID <> Undefined Then
		FilesOperationsInternalServerCall.FillScanSettings(ScanningParameters, ClientID);
	EndIf;
	Return ScanningParameters;
EndFunction

// Constructor of addition parameters from a scanner.
// 
// Returns:
//  Structure:
//    * HandlerResults_1 - Undefined, CallbackDescription - notification that will be called after getting the images.
//    * FileOwner - Undefined, DefinedType.FilesOwner - owner of the file to get images
//                                                                     to attachments.
//    * OwnerForm - Undefined, Form - form from which the file is added.
//    * NotOpenCardAfterCreateFromFile - Boolean - for the attachment creation mode.
//    * IsFile - Boolean
//    * ResultType - See ConversionResultTypeFileName 
//                    - See ConversionResultTypeBinaryData
//                    - See ConversionResultTypeAttachedFile
//    * OneFileOnly - Boolean - scan only one image.
//
Function AddingFromScannerParameters() Export
	AddingOptions = New Structure;
	AddingOptions.Insert("HandlerResults_1", Undefined);
	AddingOptions.Insert("FileOwner", Undefined);
	AddingOptions.Insert("OwnerForm", Undefined);
	AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
	AddingOptions.Insert("IsFile", True);
	AddingOptions.Insert("ResultType", ConversionResultTypeAttachedFile());
	AddingOptions.Insert("OneFileOnly", False);
	Return AddingOptions;
EndFunction

// Add from a scanner. If the scanner management is not set up beforehand, 
// the scanner settings form is called.
// 
// Parameters:
//  AddingOptions - See AddingFromScannerParameters
//  ScanningParameters - See ScanningParameters
//
Procedure AddFromScanner(AddingOptions, ScanningParameters = Undefined) Export
	
	FilesOperationsInternalClient.AddFromScanner(AddingOptions, ScanningParameters);
	
EndProcedure

// Checks if the client supports scanners.
// Only Windows and Linux x86/x64 support scanning. 
// 
// Returns:
//   Boolean
//
Function ScanAvailable() Export
	Return FilesOperationsInternalClient.ScanAvailable();
EndFunction

// Checks if the client has scanner management restrictions, if a scan add-in is installed, 
// and if there is a plugged scanner.
// 
// Parameters:
//  NotificationOfResult - CallbackDescription - procedure to which the check result will be passed:
//   * Result - Boolean - scanner availability flag.
//   * AdditionalParameters - Arbitrary - value specified when creating notification details.
//
Procedure ScanCommandAvailable(NotificationOfResult) Export
	
	If ScanAvailable() Then
		CallbackDescription = New CallbackDescription("ScanCommandAvailableCompletion", ThisObject, NotificationOfResult);
		FilesOperationsInternalClient.InitAddIn(CallbackDescription);
	Else
		RunCallback(NotificationOfResult, False);
	EndIf;
	
EndProcedure

// Gets user scanning settings.
// 
// Parameters:
//  ClientID - UUID - client iD
// 
// Returns:
//   See FilesOperationsClientServer.UserScanSettings
//
Function GetUserScanSettings(ClientID = Undefined) Export
	
	If ClientID = Undefined Then
		ClientID = FilesOperationsInternalClient.ClientID();
	EndIf;
	
	Return FilesOperationsInternalServerCall.GetUserScanSettings(ClientID);
	
EndFunction

// Saves user scanning settings.
// 
// Parameters:
//  UserScanSettings - See FilesOperationsClientServer.UserScanSettings
//  ClientID - UUID - client iD
//
Procedure SaveUserScanSettings(UserScanSettings, ClientID = Undefined) Export
	
	If ClientID = Undefined Then
		ClientID = FilesOperationsInternalClient.ClientID();
	EndIf;
	
	FilesOperationsInternalServerCall.SaveUserScanSettings(UserScanSettings, ClientID);
	
EndProcedure

#EndRegion

#Region AttachedFilesManagement

// OnOpen event handler of a file owner form.
//
// Parameters:
//  Form - ClientApplicationForm - File owner form.
//  Cancel - Boolean - Standard parameter of the OnOpen event.
//
Procedure OnOpen(Form, Cancel) Export
	ScannerExistence = FilesOperationsInternalClient.ScanAvailable();
	If Not ScannerExistence Then
		ChangeAdditionalCommandsVisibility(Form);
	EndIf;
EndProcedure

// NotificationProcessing event handler of a file owner form.
//
// Parameters:
//  Form      - ClientApplicationForm - File owner form.
//  EventName - String - Standard parameter of the NotificationProcessing event.
//
Procedure NotificationProcessing(Form, EventName) Export
	
	If EventName <> "Write_File" Then
		Return;
	EndIf;
		
	For ItemNumber = 0 To Form.FilesOperationsParameters.FormElementsDetails.UBound() Do
		
		DisplayCount = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].DisplayCount;
		If Not DisplayCount Then
			Continue;
		EndIf;
		
		AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
		AttachedFilesCount = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner);
		AttachedFilesCountAsString = Format(AttachedFilesCount, "NG=");
		
		Hyperlink = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix() + FilesOperationsClientServer.OpenListCommandName() + ItemNumber);
		If Hyperlink = Undefined Then
			Continue;
		EndIf;
			
		CountPositionInTitle = StrFind(Hyperlink.Title, "(");
		If CountPositionInTitle = 0 Then
			Hyperlink.Title = Hyperlink.Title 
						+ ?(AttachedFilesCount = 0, "",
						" (" + AttachedFilesCountAsString + ")");
		Else
			Hyperlink.Title = Left(Hyperlink.Title, CountPositionInTitle - 1)
						+ ?(AttachedFilesCount = 0, "",
						"(" + AttachedFilesCountAsString + ")");
		EndIf;
		
	EndDo;
	
EndProcedure

// A handler for executing additional commands for managing the attachments.
//
// Parameters:
//  Form   - ClientApplicationForm - File owner form.
//  Command - FormCommand - a running command.
//
Procedure AttachmentsControlCommand(Form, Command) Export
	
	Position = StrFind(Command.Name, "_",SearchDirection.FromEnd);
	If Position = 0 Then
		Return;
	EndIf;
	
	NumAsString = Mid(Command.Name, Position + 1);
	
	ItemNumber = Number(StrReplace(NumAsString, FilesOperationsClientServer.OneFileOnlyText(), ""));
	AttachedFilesOwner = AttachedFileParameterValue(Form, ItemNumber, "PathToOwnerData");
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "CommandExecution");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Command", Command);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		AttachmentsControlCommandCompletion(Form, Command, AttachedFilesOwner);
	EndIf;
	
EndProcedure

// Handler of clicking the preview field.
//
// Parameters:
//  Form                - ClientApplicationForm - File owner form.
//  Item              - FormField - Preview field.
//  StandardProcessing - Boolean - Standard parameter of the Click event.
//  View             - Boolean - if the parameter value is True, a file
//                        is opened for view. Otherwise, a file from the computer is loaded.
//                       The default value is False.
//
Procedure PreviewFieldClick(Form, Item, StandardProcessing, View = False) Export
	
	StandardProcessing = False;
	If Form.ReadOnly Or Item.ReadOnly Then
		Return;
	EndIf;
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	If Not ValueIsFilled(AttachedFilesOwner) Then
		
		HandlerParameters = New Structure;
		HandlerParameters.Insert("Action", "PreviewClick");
		HandlerParameters.Insert("Form", Form);
		HandlerParameters.Insert("Item", Item);
		HandlerParameters.Insert("View", View);
		HandlerParameters.Insert("ItemNumber", ItemNumber);
		HandlerParameters.Insert("OneFileOnly", OneFileOnly);
		
		AskQuestionAboutOwnerRecord(HandlerParameters);
		
	Else
		PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
			View, OneFileOnly);
	EndIf;
	
EndProcedure

// Preview field drag-and-drop handler.
//
// Parameters:
//  Form                   - ClientApplicationForm - File owner form.
//  Item                 - FormField - Preview field.
//  DragParameters - DragParameters - Standard parameter of the Drag event. 
//                          
//  StandardProcessing    - Boolean - Standard parameter of the Drag event.
//
Procedure PreviewFieldDrag(Form, Item, DragParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	If Form.ReadOnly Or Item.ReadOnly Then
		Return;
	EndIf;
	
	ItemNumber = Number(StrReplace(Item.Name, "AttachedFilePictureField", ""));
	OneFileOnly = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].OneFileOnly;
	AttachedFilesOwner = AttachedFileParameterValue(Form, Number(ItemNumber), "PathToOwnerData");
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("Action", "Drag");
	HandlerParameters.Insert("Form", Form);
	HandlerParameters.Insert("Item", Item);
	HandlerParameters.Insert("ItemNumber", ItemNumber);
	HandlerParameters.Insert("OneFileOnly", OneFileOnly);
	HandlerParameters.Insert("DragParameters", DragParameters);
	HandlerParameters.Insert("AttachedFilesOwner", AttachedFilesOwner);
	
	If Not ValueIsFilled(AttachedFilesOwner) Then
		AskQuestionAboutOwnerRecord(HandlerParameters);
	Else
		InstallationNotification = New CallbackDescription("PreviewFieldDragCompletion", ThisObject, HandlerParameters);
		FileSystemClient.Attach1CEnterpriseExtension(InstallationNotification, , False);
	EndIf;
	
EndProcedure

// Preview field drag-and-drop check handler.
//
// Parameters:
//  Form                   - ClientApplicationForm - File owner form.
//  Item                 - FormField - Preview field.
//  DragParameters - DragParameters - Standard parameter of the DragCheck event.
//                          
//  StandardProcessing    - Boolean - Standard parameter of the DragCheck event.
//
Procedure PreviewFieldCheckDragging(Form, Item, DragParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
EndProcedure

// Initializes the structure of parameters to asynchronously retrieve an attachment.
//
// Parameters:
//  ActionKind - String - A valid action for retrieving a file.
//                         The action depends on the given file data retrieval method.
//						   Default is Undefined.
//  MethodName	- String - The name of the common module method used to retrieve attachment data.
//						   Default is Undefined.
//						   The following methods can be used for retrieval::
//						   1. FilesOperationsInternal.FileDataToOpenAsync
//								Valid actions:
//								i. OpenFile
//								ii. OpenFileVersion
//								iii. OpenFileWithNotification
//								iv. SelectModeAndEditFile
//						   2. FilesOperationsInternal.FileDataToSaveAsync
//								Valid actions:
//								i. SaveAs
//						   3. FilesOperationsInternal.FileDataEmailManagementAsync
//								Valid actions:
//								i. OpenFile
//								ii. SaveAs
//
// Returns:
//   Structure:
//    * AsynchronousFileReceipt	 - Boolean - Asynchronous file retrieval flag.
//									 This property is verified within the parameter structure.
//                                   Default is False.
//    * AttachedFile			 - See FilesOperations.FileBinaryData.AttachedFile.
//    * VersionRef				 - CatalogRef.FilesVersions - The file version used for data retrieval.
//                                   If not specified, the current version or file is used.
//						   			 Default is Undefined.
//    * CheckForFileInArchive - Boolean - If False is passed, the attachment data retrieval methods
//                                              will not check whether the file is stored in an archive.
//									 Intended for cases where the attachment is accessed from 
//									 a metadata object form that has confirmed the file presence
//									 in the archive.
//                                   Default is True.
//    * FileInArchive					 - Boolean - Used when ... property is False.
//									 The property contains the result of the check that verifies the file's presence in the archive.
//                                   Default is False.
//    * OwnerForm				 - ClientApplicationForm - Form that is accessing the attachment.
//    * FileRetrievalMethodName		 - String - Name of the common server method that retrieves attachment data.
//									 Default is FilesOperationsInternal.FileDataToOpenAsync.
//									 
//    * MethodParameters				 - Structure - List of parameters for the method specified in property FileRetrievalMethodName.
//    * ActionParameters			 - Structure - Parameters of the action used to retrieve attachment data. Must include the following property:
//                   * ActionKind - String - Value of the TypeOfAction parameter.
//									 Additional action parameters are added in method FilesOperationsClient.SupplementParametersOfFilesOperations().
//
Function ParametersForAsynchronousFileReceipt(Val ActionKind = Undefined, Val MethodName = Undefined) Export
	
	If MethodName = Undefined Then
		MethodName = "FilesOperationsInternal.FileDataToOpenAsync";
	EndIf;
	
	If ActionKind = Undefined Then
		If MethodName = "FilesOperationsInternal.FileDataToSaveAsync" Then
			ActionKind = "SaveAs";
		Else
			ActionKind = "OpenFile";
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AsynchronousFileReceipt"		, False);
	Result.Insert("AttachedFile");
	Result.Insert("VersionRef"					, Undefined);
	Result.Insert("CheckForFileInArchive"	, True);
	Result.Insert("FileInArchive"					, False);
	Result.Insert("OwnerForm");

	Result.Insert("FileRetrievalMethodName", MethodName);
	Result.Insert("MethodParameters"		, New Structure);	
	Result.Insert("ActionParameters"		, New Structure);
	
	Result.ActionParameters.Insert("ActionKind", ActionKind);

	If MethodName = "FilesOperationsInternal.FileDataToOpenAsync" Then
		// Valid options are
		// OpenFile, OpenFileVersion, OpenFileWithNotification, SelectModeAndEditFile
		MethodParameters = Result.MethodParameters;
		MethodParameters.Insert("AttachedFile");
		MethodParameters.Insert("FileVersion");
		MethodParameters.Insert("FormIdentifier"		, Undefined);
		MethodParameters.Insert("OwnerWorkingDirectory"	, Undefined);
		MethodParameters.Insert("FilePreviousURL"		, Undefined);
		MethodParameters.Insert("FileGettingParameters"	, Undefined);

	ElsIf MethodName = "FilesOperationsInternal.FileDataToSaveAsync" Then
		// Valid options is
		// SaveAs
		MethodParameters = Result.MethodParameters;
		MethodParameters.Insert("AttachedFile");
		MethodParameters.Insert("FileVersion");
		MethodParameters.Insert("FormIdentifier"		, Undefined);
		MethodParameters.Insert("OwnerWorkingDirectory"	, Undefined);
		MethodParameters.Insert("FileGettingParameters"	, Undefined);

	ElsIf MethodName = "FilesOperationsInternal.FileDataEmailManagementAsync" Then
		// Valid options are
		// OpenFile, SaveAs
		MethodParameters = Result.MethodParameters;
		MethodParameters.Insert("AttachedFile");
		MethodParameters.Insert("FormIdentifier"				, Undefined);
		MethodParameters.Insert("GetBinaryDataRef"	, True);
		MethodParameters.Insert("ForEditing"				, False);
		MethodParameters.Insert("FileGettingParameters"			, Undefined);

	EndIf;

	SupplementFileOperationParameters(Result);

	Return Result;

EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use FilesOperationsClient.OpenFileForm.
// Opens the file form from the file catalog item form. Closes the item form.
// 
// Parameters:
//  Form     - ClientApplicationForm - a form of the attached file catalog.
//
Procedure GoToFileForm(Val Form) Export
	
	AttachedFile = Form.Key;
	
	Form.Close();
	
	For Each ApplicationWindow In GetWindows() Do
		
		Content = ApplicationWindow.GetContent();
		
		If Content = Undefined Then
			Continue;
		EndIf;
		
		If Content.FormName = "DataProcessor.FilesOperations.Form.AttachedFile" Then
			If Content.Parameters.Property("AttachedFile")
				And Content.Parameters.AttachedFile = AttachedFile Then
				ApplicationWindow.Activate();
				Return;
			EndIf;
		EndIf;
		
	EndDo;
	
	OpenFileForm(AttachedFile);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// The procedure is designed to print the file by the appropriate application.
//
// Parameters:
//  FileData          - See FilesOperations.FileData.
//  FileToOpenName - String
//
Procedure PrintFileByApplication(FileData, FileToOpenName)
	
#If MobileClient Then
	ShowMessageBox(, NStr("vi = 'Chỉ có thể in tệp có kiểu này từ ứng dụng dành cho Windows hoặc Linux.';
							|ru = 'Печать файлов данного типа возможна только из приложения для Windows или Linux.';
							|en = 'You can print this type of files only from an application for Windows or Linux.'; fa = 'You can print this type of files only from an application for Windows or Linux.';
							|it = 'La stampa dei file di questo tipo è possibile solo dall''applicazione per Windows o Linux.';
							|pl = 'Wydruk plików tego typu jest możliwy tylko z aplikacji dla Windows lub Linux.';
							|tr = 'Bu dosya türü yalnızca bir Windows veya Linux uygulamasından yazdırılabilir.'"));
	Return;
#Else
	ExtensionsExceptions = 
		" m3u, m4a, mid, midi, mp2, mp3, mpa, rmi, wav, wma, 
		| 3g2, 3gp, 3gp2, 3gpp, asf, asx, avi, m1v, m2t, m2ts, m2v, m4v, mkv, mov, mp2v, mp4, mp4v, mpe, mpeg, mts, vob, wm, wmv, wmx, wvx,
		| 7z, zip, rar, arc, arh, arj, ark, p7m, pak, package, 
		| app, com, exe, jar, dll, res, iso, isz, mdf, mds,
		| cf, dt, epf, erf";
	
	Extension = Lower(FileData.Extension);
	
	If StrFind(ExtensionsExceptions, " " + Extension + ",") > 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể in tệp kiểu này.';
								|ru = 'Печать файлов данного типа недоступна.';
								|en = 'Cannot print this type of files.'; fa = 'Cannot print this type of files.';
								|it = 'La stampa dei file di questo tipo non è disponibile.';
								|pl = 'Drukowanie plików tego typu jest niedostępny.';
								|tr = 'Bu dosya türü yazdırılamaz.'"));
		Return;
	ElsIf Extension = "grs" Then
		Schema = New GraphicalSchema;
		Schema.Read(FileToOpenName);
		Schema.Print();
		Return;
	EndIf;

	If CommonClient.IsWindowsClient() Then
		FileToOpenName = StrReplace(FileToOpenName, "/", "\");
	EndIf;

	Try
		PrintFromApplicationByFileName(FileToOpenName);
	Except
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể in tệp do:
				|%1';
				|ru = 'Не удалось распечатать файл по причине:
				|%1';
				|en = 'Cannot print the file. Reason:
				|%1'; fa = 'Cannot print the file. Reason:
				|%1';
				|it = 'Non è stato possibile stampare il file a causa di:
				|%1';
				|pl = 'Nie udało się wydrukować pliku z powodu:
				|%1';
				|tr = 'Dosya şu sebeple yazdırılamadı:
				|%1'"), ErrorProcessing.BriefErrorDescription(ErrorInfo()))); 
	EndTry;
#EndIf

EndProcedure

// File printing procedure
//
// Parameters:
//  HandlerResults_1 - CallbackDescription
//  ExecutionParameters  - Structure:
//        * FileNumber               - Number - a current file number.
//        * FileData              - Structure
//        * UUID  - UUID
//
Procedure PrintFilesExecution(HandlerResults_1, ExecutionParameters) Export
	
	UserInterruptProcessing();
	
	If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
		Return;
	EndIf;
	ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataToPrint(
		ExecutionParameters.FilesData[ExecutionParameters.FileNumber],
		ExecutionParameters.UUID);
		
#If WebClient Then
	If ExecutionParameters.FileData.Extension <> "mxl" Then
		Text = NStr("vi = 'Hãy lưu tệp trên máy tính, sau đó in tệp thông qua ứng dụng làm việc với tệp này.';
					|ru = 'Сохраните файл на компьютер, после чего распечатайте его при помощи приложения, предназначенного для работы с данным файлом.';
					|en = 'Save the file to your computer and then print it from an application that can open this file.'; fa = 'Save the file to your computer and then print it from an application that can open this file.';
					|it = 'Salvare il file su computer, poi stamparlo tramite l''applicazione prevista per il lavoro con tali file.';
					|pl = 'Zapisz plik na komputerze, po czym wydrukuj go za pomocą aplikacji, przeznaczonej do pracy z tym plikiem.';
					|tr = 'Dosyayı bilgisayara kaydedin ve ardından bu dosyayla çalışmak üzere tasarlanmış bir uygulama kullanarak yazdırın.'");
		ShowMessageBox(, Text);
		Return;
	EndIf;
#EndIf
	
	If ExecutionParameters.FileData.Property("SpreadsheetDocument") Then
		ExecutionParameters.FileData.SpreadsheetDocument.Print();
		// proceeding to print the next file.
		ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
		Handler = New CallbackDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
		RunCallback(Handler);
		Return
	EndIf;
	
	If FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Handler = New CallbackDescription("PrintFileAfterReceiveVersionInWorkingDirectory", ThisObject, 
			ExecutionParameters);
		FilesOperationsInternalClient.GetVersionFileToWorkingDirectory(Handler, ExecutionParameters.FileData,
			"", ExecutionParameters.UUID);
	Else
		ExecutionParameters.FileData = FilesOperationsInternalServerCall.FileDataToOpen(
			ExecutionParameters.FilesData[ExecutionParameters.FileNumber], Undefined);
		OpenFile(ExecutionParameters.FileData, False);
	EndIf;
EndProcedure

// The procedure of printing the File after receiving it to the computer.
//
// Parameters:
//  Result - Structure:
//    * FileReceived - Boolean
//    * FullFileName - String
//  ExecutionParameters  - Structure:
//    * FileNumber               - Number - a current file number.
//    * FileData              - Structure
//    * UUID  - UUID
//
Procedure PrintFileAfterReceiveVersionInWorkingDirectory(Result, ExecutionParameters) Export

	If Result.FileReceived Then
		
		If ExecutionParameters.FileNumber >= ExecutionParameters.FilesData.Count() Then
			Return;
		EndIf;
	
		PrintFileByApplication(ExecutionParameters.FileData, Result.FullFileName);
		
	EndIf;

	// proceeding to print the next file.
	ExecutionParameters.FileNumber = ExecutionParameters.FileNumber + 1;
	Handler = New CallbackDescription("PrintFilesExecution", ThisObject, ExecutionParameters);
	RunCallback(Handler);
	
EndProcedure

// Prints file by an external application.
//
// Parameters:
//  FileToOpenName - String
//
Procedure PrintFromApplicationByFileName(FileToOpenName)
	
	FileSystemClient.PrintFromApplicationByFileName(FileToOpenName);

EndProcedure

Procedure OpenScanSettingFormCompletion(InitializationCheckResult, ExecutionParameters) Export
	
	AddInInstalled = InitializationCheckResult.Attached;
	
	If Not AddInInstalled Then
		If ValueIsFilled(InitializationCheckResult.ErrorDescription) Then
			ShowMessageBox(, InitializationCheckResult.ErrorDescription);
		EndIf;
		Return;
	EndIf;
	
	ContinueNotification = New CallbackDescription("OpenScanSetupFormAfterLogEnabled", 
		ThisObject, AddInInstalled);
	
	FilesOperationsInternalClient.EnableScanLog(InitializationCheckResult.Attachable_Module, 
		ContinueNotification);
EndProcedure

Procedure OpenScanSetupFormAfterLogEnabled(Result, AddInInstalled) Export
	ClientID = FilesOperationsInternalClient.ClientID();
	
	FormParameters = New Structure;
	FormParameters.Insert("AddInInstalled", AddInInstalled);
	FormParameters.Insert("ClientID",  ClientID);
	
	OpenForm("DataProcessor.Scanning.Form.ScanningSettings", FormParameters);
	
EndProcedure

Procedure PromptForWriteRequiredAfterCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		Return;
	EndIf;
	
EndProcedure

Function ImagesForMerging(ObjectsForMerging, UseImageMagick = False)
	
	ImagesForMerging = New Array;
	
	If UseImageMagick Then
		For Each ObjectForMerging In ObjectsForMerging Do
			FileName = Undefined;
#If Not WebClient And Not MobileClient Then
			// ACC:441-off the file is a method result
			TempFileName = GetTempFileName();
			// ACC:441-on
#Else
			TempFileName = Undefined;			
#EndIf
			
			If ObjectForMerging = Undefined Then
				Continue;
			ElsIf TypeOf(ObjectForMerging) = Type("BinaryData") Then
				FileName = TempFileName;
				ObjectForMerging.Write(FileName);
			ElsIf TypeOf(ObjectForMerging) = Type("String") Then
				If IsTempStorageURL(ObjectForMerging) Then
					AddressContent = GetFromTempStorage(ObjectForMerging);
					If TypeOf(AddressContent) = Type("BinaryData") Then
						FileName = TempFileName;
						AddressContent.Write(FileName);
					ElsIf TypeOf(AddressContent) = Type("Picture") Then
						PictureData = AddressContent.GetBinaryData();
						FileName = TempFileName;
						PictureData.Write(FileName);
					EndIf;
				Else
					FileName = ObjectForMerging;
				EndIf;
			ElsIf FilesOperationsInternalServerCall.IsFilesOperationsItem(ObjectForMerging) Then
				FileData = FilesOperationsInternalServerCall.FileData(ObjectForMerging);
				AddressContent = GetFromTempStorage(FileData.RefToBinaryFileData);
				FileName = TempFileName;
				AddressContent.Write(FileName);
			EndIf;
			
			If FileName <> Undefined Then
				ImagesForMerging.Add(FileName);
			EndIf;
			
		EndDo;
	Else
		For Each ObjectForMerging In ObjectsForMerging Do
			Image = Undefined;
			If ObjectForMerging = Undefined Then
				Continue;
			ElsIf TypeOf(ObjectForMerging) = Type("BinaryData") Then
				Image = New Picture(ObjectForMerging);
			ElsIf TypeOf(ObjectForMerging) = Type("String") Then
				If IsTempStorageURL(ObjectForMerging) Then
					AddressContent = GetFromTempStorage(ObjectForMerging);
					If TypeOf(AddressContent) = Type("BinaryData") Then
						Image = New Picture(AddressContent);
					ElsIf TypeOf(AddressContent) = Type("Picture") Then
						Image = AddressContent;
					EndIf;
				Else
					Image = New Picture(ObjectForMerging);
				EndIf;
			ElsIf FilesOperationsInternalServerCall.IsFilesOperationsItem(ObjectForMerging) Then
				FileData = FilesOperationsInternalServerCall.FileData(ObjectForMerging);
				AddressContent = GetFromTempStorage(FileData.RefToBinaryFileData);
				Image = New Picture(AddressContent);
			EndIf;
			
			If Image <> Undefined Then
				ImagesForMerging.Add(Image);
			EndIf;
			
		EndDo;
	EndIf;
	
	Return ImagesForMerging;
EndFunction

Function ResultOfMergeIntoMultipageDocument()
	Result = New Structure;
	Result.Insert("ResultFileName", "");
	Result.Insert("BinaryData");
	Result.Insert("ErrorDescription", "");
	Result.Insert("Success", False);	
	Return Result;
EndFunction

Procedure MergeIntoMultipageFileAfterCommandExecuted(ImageMagickResult, Context) Export

	ImageFiles = Context.ImageFiles;
	ResultType = Context.ResultType;
	ResultFileName = Context.ResultFileName;
	NotificationOfReturn = Context.NotificationOfReturn;
	
	Result = ResultOfMergeIntoMultipageDocument();

	If ImageMagickResult.ReturnCode <> 0 Then
		Result.ErrorDescription = ImageMagickResult.ErrorDescription;
		RunCallback(NotificationOfReturn, Result);
		Return;
	EndIf;
	
	For Each ImageFile In ImageFiles Do
		DeleteFiles(ImageFile);
	EndDo;
	
	If ResultType = ConversionResultTypeFileName() Then
		Result.ResultFileName = ResultFileName;
	ElsIf ResultType = ConversionResultTypeBinaryData() Then
		PDFData = New BinaryData(ResultFileName);
		DeleteFiles(ResultFileName);
		Result.BinaryData =  PDFData;
	EndIf;
	Result.Success = True;
	
	RunCallback(NotificationOfReturn, Result);
		
EndProcedure

Procedure ScanCommandAvailableCompletion(InitializationCheckResult, NotificationOfResult) Export

	InitializationCheckResult.Insert("NotificationOfResult", NotificationOfResult);
	
	CompletionNotification = New CallbackDescription("ScanCommandAvailableAfterLogEnabled", ThisObject, 
		InitializationCheckResult);
	If InitializationCheckResult.Attached Then
		FilesOperationsInternalClient.EnableScanLog(InitializationCheckResult.Attachable_Module, 
			CompletionNotification);
	Else
		RunCallback(CompletionNotification);
	EndIf;
	
EndProcedure

Procedure ScanCommandAvailableAfterLogEnabled(Result, Context) Export
	
	ScanCommandAvailable = Context.Attached 
		And FilesOperationsInternalClient.IsDevicePresent(Undefined, Context.Attachable_Module, False);

	RunCallback(Context.NotificationOfResult, ScanCommandAvailable);
	
EndProcedure

Procedure AfterCheckIfConversionAppInstalled(RunResult, Context) Export
	If StrFind(RunResult.OutputStream, "ImageMagick") = 0  Then
		UserScanSettings = Context.UserScanSettings;
		PathToConverterApplication = UserScanSettings.PathToConverterApplication;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chỉ ra đường dẫn đến ứng dụng không chính xác %1.
		|Thực hiện hợp nhất các văn bản có nhiều trang bằng các công cụ thông thường.
		|Đã chỉ ra đường dẫn: %2';
		|ru = 'Ошибочно указан путь к приложению %1.
		|Объединение многостраничных документов выполняется штатными средствами.
		|Указан путь: %2';
		|en = 'Specified path to the %1 application is incorrect.
		|Multipage documents are merged using 1C:Enterprise tools.
		|Specified path: %2'; fa = 'Specified path to the %1 application is incorrect.
		|Multipage documents are merged using 1C:Enterprise tools.
		|Specified path: %2';
		|it = 'Ошибочно указан путь к приложению %1.
		|Объединение многостраничных документов выполняется штатными средствами.
		|Указан путь: %2';
		|pl = 'Specified path to the %1 application is incorrect.
		|Multipage documents are merged using 1C:Enterprise tools.
		|Specified path: %2';
		|tr = '%1 uygulama yolu yanlış belirtildi.
		|Çok sayfalı belgelerin birleştirilmesi standart araçlar kullanılarak gerçekleştirilmektedir.
		|Belirtilen yol: %2'"), "ImageMagick", PathToConverterApplication); 
		EventLogClient.AddMessageForEventLog(EventLogEvent(),
			"Warning", ErrorText,, True);
		Context.GraphicDocumentConversionParameters.UseImageMagick = False;
	EndIf;
	MergeIntoMultiPageFileContinued(Context);
EndProcedure
	
Procedure MergeIntoMultiPageFileContinued(Context)
	NotificationOfReturn = Context.NotificationOfReturn;
	ObjectsForMerging = Context.ObjectsForMerging;
	GraphicDocumentConversionParameters = Context.GraphicDocumentConversionParameters;
	UserScanSettings = Context.UserScanSettings;
	
	UseImageMagick = GraphicDocumentConversionParameters.UseImageMagick; 
	PathToConverterApplication = UserScanSettings.PathToConverterApplication;
	
	Result = ResultOfMergeIntoMultipageDocument();
	
#If Not WebClient And Not MobileClient Then
	ResultFileName = GraphicDocumentConversionParameters.ResultFileName;
	
	If Not ValueIsFilled(ResultFileName) Then
		// ACC:441-off the file is not deleted if it is a method result
		ResultFileName = GetTempFileName(GraphicDocumentConversionParameters.ResultFormat);
		// ACC:441-on
	EndIf;
	
	If Not UseImageMagick Then
		ImagesForMerging = ImagesForMerging(ObjectsForMerging);
		If GraphicDocumentConversionParameters.ResultFormat = "pdf" Then
			SpreadsheetDocument = FilesOperationsInternalServerCall.NewSpreadsheetAtServer(ImagesForMerging.Count());
			Stream = New MemoryStream();
			SpreadsheetDocument.Write(Stream, SpreadsheetDocumentFileType.PDF);
			
			PDFDocument = New PDFDocument();
			PDFDocument.Read(Stream);
			For ObjectIndex = 0 To ImagesForMerging.UBound() Do
				LongDesc = New PDFRepresentationObjectDescription;
				LongDesc.Name           = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hình ảnh số %1';
																										|ru = 'Изображение № %1';
																										|en = 'Image #%1'; fa = 'Image #%1';
																										|it = 'Изображение № %1';
																										|pl = 'Image #%1';
																										|tr = 'Görsel No. %1'"), ObjectIndex);
				Image = ImagesForMerging[ObjectIndex];
				Width = Image.Width();
				Height = Image.Height();
				RatioA4 = 210/297;
				
				If RatioA4*Height > Width Then
					LongDesc.Height        = 269; //297
					LongDesc.Width        = LongDesc.Height * Width/Height; //210
				Else
					LongDesc.Width        = 190; //210
					LongDesc.Height        = LongDesc.Width * Height/Width; //297 
				EndIf;
				LongDesc.Left          = 0;
				LongDesc.Top          = 0;
				LongDesc.PageNumber = ObjectIndex+1;
				LongDesc.Object        = Image;
				PDFDocument.AddRepresentationObject(LongDesc);
			EndDo;
			PDFDocument.Write(Stream);
			ResultData = Stream.CloseAndGetBinaryData();
		ElsIf GraphicDocumentConversionParameters.ResultFormat = "tif" Then
			TIFImage = FilesOperationsInternalServerCall.MergeImagesIntoTIFFile(ImagesForMerging);
			ResultData = TIFImage.GetBinaryData();
		EndIf;
		
		If GraphicDocumentConversionParameters.ResultType = ConversionResultTypeFileName() Then
			ResultData.Write(ResultFileName);
			Result.ResultFileName = ResultFileName;
			Result.Success = True;
		ElsIf GraphicDocumentConversionParameters.ResultType = ConversionResultTypeBinaryData() Then
			Result.BinaryData = ResultData;
			Result.Success = True;
		EndIf;
		
		RunCallback(NotificationOfReturn, Result);
	Else
		ImageFiles = ImagesForMerging(ObjectsForMerging, True);
		
		ImageFilesAsString = """" + StrConcat(ImageFiles, """" + " " + """") + """";
		SystemCommands = """" + PathToConverterApplication + """" +" "+ ImageFilesAsString + " " +""""+ ResultFileName+"""";
		
		Context = New Structure;
		Context.Insert("ImageFiles", ImageFiles);
		Context.Insert("ResultType", GraphicDocumentConversionParameters.ResultType);
		Context.Insert("ResultFileName", ResultFileName);
		Context.Insert("NotificationOfReturn", NotificationOfReturn);
		
		ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
		ApplicationStartupParameters.WaitForCompletion = True;
		ApplicationStartupParameters.Notification = New CallbackDescription("MergeIntoMultipageFileAfterCommandExecuted", 
			ThisObject, Context);
		FileSystemClient.StartApplication(SystemCommands, ApplicationStartupParameters);
				
	EndIf;
	
#EndIf
EndProcedure

#Region AttachedFilesManagement

Function ManagementCommandParameters(Form)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("Form",              Form);
	ExecutionParameters.Insert("Action",           "ImportFile_");
	ExecutionParameters.Insert("ItemNumber",      "");
	ExecutionParameters.Insert("FormIdentifier", Form.UUID);
	Return ExecutionParameters;
	
EndFunction

Function AttachedFileParameterValue(Form, Val ItemNumber, ParameterName)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber][ParameterName];
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	If DataPathParts.Count() > 0 Then
		
		ParameterValue = Form[DataPathParts[0]];
		For IndexOf = 1 To DataPathParts.UBound() Do
			ParameterValue = ParameterValue[DataPathParts[IndexOf]];
		EndDo;
		
		Return ParameterValue;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure AskQuestionAboutOwnerRecord(CompletionHandlerParameters)
	
	QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
		|Chỉ có thể chuyển đến các tệp đính kèm sau khi ghi dữ liệu.
		|Dữ liệu sẽ được ghi lại.';
		|ru = 'Данные еще не записаны.
		|Переход к присоединенным файлам возможен только после записи данных.
		|Данные будут записаны.';
		|en = 'You have unsaved data.
		|You can open the attachments after saving the data.
		|Do you want to save the data?'; fa = 'You have unsaved data.
		|You can open the attachments after saving the data.
		|Do you want to save the data?';
		|it = 'Dati non ancora registrati.
		|Il passaggio ai file allegati è possibile solo dopo la registrazione dei dati.
		|I dati saranno registrati.';
		|pl = 'Dane nie zostały jeszcze zarejestrowane.
		|Przejście do załączonych plików jest możliwe dopiero po zapisaniu danych.
		|Dane zostaną zapisane.';
		|tr = 'Veriler henüz kaydedilmedi.
		|Ekli dosyaları yalnızca veri kaydedildikten sonra açabilirsiniz.
		|Verileri kaydetmek istiyor musunuz?'");
	HandlerNotifications = New CallbackDescription("ShowNewOwnerRecordQuestion", ThisObject, CompletionHandlerParameters);
	
	ShowQueryBox(HandlerNotifications, QueryText, QuestionDialogMode.OKCancel);
	
EndProcedure

// Parameters:
//   Response - DialogReturnCode
//         - Undefined
//   AdditionalParameters - Structure
//
Procedure ShowNewOwnerRecordQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		
		Form = AdditionalParameters.Form; // ManagedFormExtensionForCatalogs
		If Not Form.Write() Then
			Return;
		EndIf;
		
		StandardProcessing = False;
		AttachedFilesOwner = AttachedFileParameterValue(Form, 
			AdditionalParameters.ItemNumber, "PathToOwnerData");
		
		If Not ValueIsFilled(AttachedFilesOwner) Then
			Return;
		EndIf;
		
		If AdditionalParameters.Action = "CommandExecution" Then
			AttachmentsControlCommandCompletion(Form, AdditionalParameters.Command, AttachedFilesOwner);
		ElsIf AdditionalParameters.Action = "PreviewClick" Then
			PreviewFieldClickCompletion(Form, AttachedFilesOwner,
				AdditionalParameters.Item, StandardProcessing,
				AdditionalParameters.View, AdditionalParameters.OneFileOnly);
		ElsIf AdditionalParameters.Action = "Drag" Then
			InstallationNotification = New CallbackDescription("PreviewFieldDragCompletion", ThisObject, AdditionalParameters);
			FileSystemClient.Attach1CEnterpriseExtension(InstallationNotification, , False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AttachmentsControlCommandCompletion(Form, Command, AttachedFilesOwner)
	
	CommandName = StrReplace(Command.Name, FilesOperationsClientServer.CommandsPrefix(), "");
	ItemNumber = "";

	Position = StrFind(CommandName, "_", SearchDirection.FromEnd);
	If Position > 0 Then 
		ItemNumber = StrReplace(Mid(CommandName, Position + 1), FilesOperationsClientServer.OneFileOnlyText(), "");
		CommandName    = Left(CommandName, Position - 1);
	EndIf;
	
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = ItemNumber;
	
	CompletionHandler = New CallbackDescription("CommandWithNotificationExecutionCompletion",
		ThisObject, ExecutionParameters);
		
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaximumSize",
		Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].MaximumSize);
	FileAddingOptions.Insert("SelectionDialogFilter",
		Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].SelectionDialogFilter);
	FileAddingOptions.Insert("NotOpenCard", True);
	
	ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient = Undefined;
	UseEDIToStoreObjectFiles =
		FilesOperationsInternalClient.Is1CDocumentManagementUsedForFileStorage(
			AttachedFilesOwner,
			Form,
			Command,
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient);
	
	If StrStartsWith(CommandName, "OpenList") Then
		
		If UseEDIToStoreObjectFiles Then
			
			// IntegrationWith1CDocumentManagement
			FilesOperationsInternalClient.OpenFormAttachedFiles1CDocumentManagement(
				AttachedFilesOwner,
				Form);
			// End IntegrationWith1CDocumentManagement
			
		Else
			
			FormParameters = New Structure;
			FormParameters.Insert("FileOwner", AttachedFilesOwner);
			FormParameters.Insert("ShouldHideOwner", True);
			OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters);
			
		EndIf;
		
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ImportFileCommandName()) Then
		
		If UseEDIToStoreObjectFiles Then
			
			// IntegrationWith1CDocumentManagement
			ModuleIntegrationWith1CDocumentManagementBasicFunctionalityClient.AddFileFromDiskToICObject(
				AttachedFilesOwner,
				Form.UUID);
			// End IntegrationWith1CDocumentManagement
			
		Else
			
			CommandName = StrReplace(CommandName, FilesOperationsClientServer.ImportFileCommandName(), "");
			OwnerFiles = FilesOperationsInternalServerCall.AttachedFilesCount(AttachedFilesOwner, True);
			If StrStartsWith(CommandName, "OneFileOnly")
				And OwnerFiles.Count > 0 Then
				
				FileData = OwnerFiles.FileData; // See FilesOperations.FileData
				
				ExecutionParameters.Action = "ReplaceFile";
				ExecutionParameters.Insert("PicturesFile", FileData.Ref);
				
				FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler,
					FileData, Form.UUID, FileAddingOptions);
				
			Else
				AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
			EndIf;
			
		EndIf;
		
	ElsIf StrStartsWith(CommandName, "AttachedFileTitle") Then
		
		Location = AttachedFileParameterValue(Form, ExecutionParameters.ItemNumber, "PathToPlacementAttribute");
		If Not ValueIsFilled(Location) Then
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		Else
			ExecutionParameters.Action = "ViewFile1";
			ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
		EndIf;
		
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.CreateFromTemplateCommandName()) Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 1, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ScanCommandName()) Then
		AppendFile(CompletionHandler, AttachedFilesOwner, Form, 3, FileAddingOptions);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.SelectFileCommandName()) Then
		ExecutionParameters.Action = "SelectFile";
		OpenFileChoiceForm(AttachedFilesOwner, Undefined, False, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ViewFileCommandName()) Then
		ExecutionParameters.Action = "ViewFile1";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.ClearCommandName()) Then
		UpdateAttachedFileStorageAttribute(Form, ExecutionParameters.ItemNumber, Undefined);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.OpenFormCommandName()) Then
		ExecutionParameters.Action = "OpenForm";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.EditFileCommandName()) Then
		ExecutionParameters.Action = "EditFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.PutFileCommandName()) Then
		ExecutionParameters.Action = "PutFile";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	ElsIf StrStartsWith(CommandName, FilesOperationsClientServer.CancelEditCommandName()) Then
		ExecutionParameters.Action = "CancelEdit";
		ExecuteActionWithFile(ExecutionParameters, CompletionHandler);
	EndIf;
	
EndProcedure

Procedure PreviewFieldClickCompletion(Form, AttachedFilesOwner, Item, StandardProcessing,
	View = False, OneFileOnly = False)
	
	StandardProcessing = False;
	ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = ItemNumber;
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	FileOperationsParameters = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber];
	FileAddingOptions = New Structure;
	FileAddingOptions.Insert("MaximumSize", FileOperationsParameters.MaximumSize);
	FileAddingOptions.Insert("SelectionDialogFilter", FileOperationsParameters.SelectionDialogFilter);


	FileAddingOptions.Insert("NotOpenCard", True);
	PlacementAttribute = Undefined;
	If FileOperationsParameters.Property("PathToPictureData") And ValueIsFilled(FileOperationsParameters.PathToPlacementAttribute) Then
		PathToPlacementAttribute = FileOperationsParameters.PathToPlacementAttribute;
		PathElements = StrSplit(PathToPlacementAttribute, ".", False);
		PlacementAttribute = PathElements[PathElements.UBound()];
	EndIf;
	
	ImageAddingOptions = FilesOperationsInternalServerCall.ImageAddingOptions(AttachedFilesOwner, PlacementAttribute);
	If View
		Or (Not ImageAddingOptions.InsertRight1 And Not ImageAddingOptions.EditRight) Then
		
		ExecutionParameters.Action = "ViewFile1";
		ExecuteActionWithFile(ExecutionParameters, Undefined);

	Else
		
		CompletionHandler = New CallbackDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		If OneFileOnly Then
			
			OwnerFiles = ImageAddingOptions.OwnerFiles;
			If OwnerFiles.FilesCount > 0 Then
				
				FileData = OwnerFiles.FileData; // See FilesOperations.FileData
				ExecutionParameters.Action = "ReplaceFile";
				ExecutionParameters.Insert("PicturesFile", FileData.Ref);
				
				FilesOperationsInternalClient.UpdateFromFileOnHardDriveWithNotification(CompletionHandler, FileData,
					Form.UUID, FileAddingOptions);
				
			Else
				AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
			EndIf;
			
		Else
			AppendFile(CompletionHandler, AttachedFilesOwner, Form, 2, FileAddingOptions);
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters:
//   ExtensionInstalled - Boolean
//   AdditionalParameters - Structure:
//     * Item - FormField
//
Procedure PreviewFieldDragCompletion(ExtensionInstalled, AdditionalParameters) Export
	
	If Not ExtensionInstalled Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	Item = AdditionalParameters.Item;
	DragParameters = AdditionalParameters.DragParameters;
	AttachedFilesOwner = AdditionalParameters.AttachedFilesOwner;
	
	ExecutionParameters = ManagementCommandParameters(Form);
	ExecutionParameters.ItemNumber = StrReplace(Item.Name, "AttachedFilePictureField", "");
	
	NumberType = New TypeDescription("Number");
	ItemNumber = NumberType.AdjustValue(ExecutionParameters.ItemNumber);
	If TypeOf(DragParameters.Value) = Type("FileRef")
		And FilesOperationsInternalServerCall.HasAccessRight("Insert", AttachedFilesOwner) Then // @Access-right-2
		
		File = DragParameters.Value.File;
		If File = Undefined Then
			Return;
		EndIf;
		
		ExecutionParameters.Action = "CompleteDragging";
		CompletionHandler = New CallbackDescription("CommandWithNotificationExecutionCompletion",
			ThisObject, ExecutionParameters);
		
		AddingOptions = New Structure;
		AddingOptions.Insert("HandlerResults_1", CompletionHandler);
		AddingOptions.Insert("FullFileName", File.FullName);
		AddingOptions.Insert("FileOwner", AttachedFilesOwner);
		AddingOptions.Insert("OwnerForm", Form);
		AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
		AddingOptions.Insert("NameOfFileToCreate", File.BaseName);
		AddingOptions.Insert("MaximumSize",
			Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].MaximumSize);
		AddingOptions.Insert("SelectionDialogFilter",
			Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].SelectionDialogFilter);
			
		FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		
	EndIf;
	
EndProcedure

Procedure UpdateAttachedFileStorageAttribute(Form, Val ItemNumber, File)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumber = Number(ItemNumber);
	EndIf;
	
	DataPath = Form.FilesOperationsParameters.FormElementsDetails[ItemNumber].PathToPlacementAttribute;
	DataPathParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".", True, True);
	
	If DataPathParts.Count() > 0 Then
		
		AttributeLocationLevel = DataPathParts.Count();
		If AttributeLocationLevel = 1 Then
			Form[DataPathParts[0]] = File;
		ElsIf AttributeLocationLevel = 2 Then
			Form[DataPathParts[0]][DataPathParts[1]] = File;
		Else
			Return;
		EndIf;
		
		UpdatePreviewArea(Form, ItemNumber, File);
		
		Form.Modified = True;
		
	EndIf;
	
EndProcedure

Procedure UpdatePreviewArea(Form, ItemNumber, File)
	
	If TypeOf(ItemNumber) = Type("String") Then
		ItemNumAsNumber = Number(ItemNumber);
		ItemNumAsString = ItemNumber;
	Else
		ItemNumAsNumber = ItemNumber;
		ItemNumAsString = Format(ItemNumber, "NG=;");
	EndIf;
	
	AttributeName = Form.FilesOperationsParameters.FormElementsDetails[ItemNumAsNumber].PathToPictureData;
	PictureItem = Form.Items.Find("AttachedFilePictureField" + ItemNumAsString);
	TitleItem = Form.Items.Find("AttachedFileTitle" + ItemNumAsString);
	
	DataParameters = FilesOperationsClientServer.FileDataParameters();
	DataParameters.RaiseException1 = False;
	DataParameters.FormIdentifier = Form.UUID;
	
	UpdateData = FilesOperationsInternalServerCall.ImageFieldUpdateData(
		File, DataParameters);
		
	FileData = UpdateData.FileData;
	If PictureItem <> Undefined Then
		
		NonselectedPictureText = Form.FilesOperationsParameters.FormElementsDetails[ItemNumAsNumber].NonselectedPictureText;
		If FileData = Undefined Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NonselectedPictureText;
		ElsIf UpdateData.FileCorrupted Then
			Form[AttributeName] = Undefined;
			PictureItem.NonselectedPictureText = NStr("vi = 'Không có hình ảnh';
														|ru = 'Изображение отсутствует';
														|en = 'No image'; fa = 'بدون تصویر';
														|it = 'Nessuna immagine';
														|pl = 'Brak obrazu';
														|tr = 'Görsel yok'");
		Else
			Form[AttributeName] = FileData.RefToBinaryFileData;
			PictureItem.NonselectedPictureText = NonselectedPictureText;
		EndIf;
		
		PictureItem.TextColor = UpdateData.TextColor;
		
	EndIf;
	
	If TitleItem <> Undefined Then
		
		If FileData = Undefined Then
			TitleItem.Title = NStr("vi = 'tải lên';
									|ru = 'загрузить';
									|en = 'upload'; fa = 'upload';
									|it = 'scaricare';
									|pl = 'upload';
									|tr = 'İçe aktar'");
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.None;
		Else
			TitleItem.Title = FileData.FileName;
			TitleItem.ToolTipRepresentation = ToolTipRepresentation.Auto;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteActionWithFile(ExecutionParameters, CompletionHandler)
	
	Form = ExecutionParameters.Form;
	Location = AttachedFileParameterValue(Form, Number(ExecutionParameters.ItemNumber), "PathToPlacementAttribute");
	If ValueIsFilled(Location) Then
		
		If ExecutionParameters.Action = "ViewFile1" Then

			FileGettingParameters = ParametersForAsynchronousFileReceipt("OpenFile");
			FileGettingParameters.AttachedFile	= Location;
			FileGettingParameters.OwnerForm		= Form;

			OpenFile(FileGettingParameters);

		ElsIf ExecutionParameters.Action = "OpenForm" Then
			OpenFileForm(Location);
		ElsIf ExecutionParameters.Action = "EditFile" Then
			FilesOperationsInternalClient.EditWithNotification(CompletionHandler, Location);
		ElsIf ExecutionParameters.Action = "PutFile" Then
			
			FileUpdateParameters = FilesOperationsInternalClient.FileUpdateParameters(CompletionHandler,
				Location, Form.UUID);
			FileUpdateParameters.Insert("CreateNewVersion", False);
			FilesOperationsInternalClient.EndEditAndNotify(FileUpdateParameters);
			
		ElsIf ExecutionParameters.Action = "CancelEdit" Then
			
			FilesArray = New Array;
			FilesArray.Add(Location);
			
			FilesOperationsInternalServerCall.UnlockFiles(FilesArray);
			CommandWithNotificationExecutionCompletion(Undefined, ExecutionParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CommandWithNotificationExecutionCompletion(Result, AdditionalParameters) Export
	
	If AdditionalParameters.Action = "ReplaceFile" Then
		
		UpdatePreviewArea(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			AdditionalParameters.PicturesFile);
		
	ElsIf (AdditionalParameters.Action = "ImportFile_"
		Or AdditionalParameters.Action = "CompleteDragging")
		And Result <> Undefined
		And Result.FileAdded Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result.FileRef);
		
	ElsIf AdditionalParameters.Action = "SelectFile"
		And Result <> Undefined Then
		
		UpdateAttachedFileStorageAttribute(AdditionalParameters.Form, AdditionalParameters.ItemNumber,
			Result);
		
	ElsIf AdditionalParameters.Action = "EditFile" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, True);
	ElsIf AdditionalParameters.Action = "PutFile"
		Or AdditionalParameters.Action = "CancelEdit" Then
		ChangeButtonsAvailability(AdditionalParameters.Form, AdditionalParameters.ItemNumber, False);
	EndIf;
	
EndProcedure

// Parameters:
//
// Form - ClientApplicationForm
//
Procedure ChangeButtonsAvailability(Form, ItemNumber, EditStart)
	
	CommandPrefix                   = FilesOperationsClientServer.CommandsPrefix();
	PutFileCommandName          = FilesOperationsClientServer.PutFileCommandName();
	CancelEditCommandName = FilesOperationsClientServer.CancelEditCommandName();
	EditFileCommandName      = FilesOperationsClientServer.EditFileCommandName();
	
	Buttons = New ValueList;
	Buttons.Add(CommandPrefix + PutFileCommandName + ItemNumber,, EditStart);
	Buttons.Add(CommandPrefix + CancelEditCommandName + ItemNumber,, EditStart);
	Buttons.Add(CommandPrefix + EditFileCommandName + ItemNumber,, Not EditStart);
	Buttons.Add(PutFileCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, EditStart);
	Buttons.Add(CancelEditCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, EditStart);
	Buttons.Add(EditFileCommandName + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ItemNumber,, Not EditStart);
	
	Items = Form.Items;
	For Each Button In Buttons Do
		
		FormButton = Items.Find(Button.Value);
		If FormButton <> Undefined Then
			FormButton.Enabled = Button.Check;
		EndIf;
		
	EndDo;
		
EndProcedure

Procedure ChangeAdditionalCommandsVisibility(Form)
	
	Try
		HasFileManagementParameters = TypeOf(Form["FilesOperationsParameters"]) = Type("FixedStructure");
	Except
		// The FilesOperationsParameters attribute is either absent from the form or not initialized.
		HasFileManagementParameters = False;
	EndTry;
	
	If Not HasFileManagementParameters Then
		Return;
	EndIf;
	
	CommandPrefix = FilesOperationsClientServer.CommandsPrefix();
	
	For ElementIndex = 0 To Form.FilesOperationsParameters.FormElementsDetails.UBound() Do
		
		CommandsSubmenu                 = Form.Items.Find("AddingFileSubmenu" + ElementIndex);
		CommandSelectButton          = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.SelectFileCommandName() + ElementIndex);
		CommandSelectButton          = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.SelectFileCommandName() + ElementIndex);
		CommandLoadButton        = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.ImportFileCommandName() + ElementIndex);
		CommandScanButton      = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.ScanCommandName() + ElementIndex);
		CommandCreateFromTemplateButton = Form.Items.Find(CommandPrefix + FilesOperationsClientServer.CreateFromTemplateCommandName() + ElementIndex);
		
		If CommandScanButton <> Undefined Then
			CommandScanButton.Visible = False;
			CommandScanFromContextMenuButton = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix()
				+ FilesOperationsClientServer.ScanCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ElementIndex);
			If CommandScanFromContextMenuButton <> Undefined Then
				CommandScanFromContextMenuButton.Visible = False;
			EndIf;
		EndIf;
		
		If CommandCreateFromTemplateButton <> Undefined Then
			CommandCreateFromTemplateButton.Visible = False;
			CommandCreateFromTemplateFromContextMenuButton = Form.Items.Find(FilesOperationsClientServer.CommandsPrefix() 
				+ FilesOperationsClientServer.ScanCommandName() + FilesOperationsClientServer.NameOfAdditionalCommandFromContextMenu() + ElementIndex);
			If CommandCreateFromTemplateFromContextMenuButton <> Undefined Then
				CommandCreateFromTemplateFromContextMenuButton.Visible = False;
			EndIf;
		EndIf;
		
		SubmenuVisibility = False;
		If CommandsSubmenu <> Undefined Then
			SubmenuVisibility = CommandSelectButton <> Undefined;
			CommandsSubmenu.Visible = SubmenuVisibility;
		EndIf;
		
		If CommandLoadButton <> Undefined Then
			CommandLoadButton.Visible = Not SubmenuVisibility;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure StartCheckConversionAppPresence(PathToConverterApplication, NotificationOfResult) Export
	
	SystemCommands = """" + PathToConverterApplication + """ -version";
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetErrorStream = True;
	ApplicationStartupParameters.GetOutputStream = True;
	
	ApplicationStartupParameters.Notification = NotificationOfResult;
	FileSystemClient.StartApplication(SystemCommands, ApplicationStartupParameters);
EndProcedure

Function EventLogEvent()
	
	Return NStr("vi = 'Tệp';
				|ru = 'Файлы';
				|en = 'Files'; fa = 'فایل‌ها';
				|it = 'Файлы';
				|pl = 'Files';
				|tr = 'Dosyalar'", CommonClient.DefaultLanguageCode());
	
EndFunction

Procedure SupplementFileOperationParameters(FileGettingParameters)

	MethodName			= FileGettingParameters.FileRetrievalMethodName;
	ActionParameters	= FileGettingParameters.ActionParameters;
	ActionKind			= ActionParameters.ActionKind;

	If MethodName = "FilesOperationsInternal.FileDataToOpenAsync" Then
		
		If ActionKind = "OpenFile" Then
			
			ActionParameters.Insert("NotifyIfEncrypted", False);
			ActionParameters.Insert("FileBeingEdited"		, False);
		ElsIf ActionKind = "OpenFileVersion" Then
			
			ActionParameters.Insert("UUID");
		ElsIf ActionKind = "SelectModeAndEditFile" Then

			ActionParameters.Insert("OwnerForm");
			ActionParameters.Insert("CommandEditAvailability");
		ElsIf ActionKind = "OpenFileWithNotification" Then
			
		EndIf;
	ElsIf MethodName = "FilesOperationsInternal.FileDataEmailManagementAsync" Then
		If ActionKind = "OpenFile" Then
			ActionParameters.Insert("ForEditing"	, False);
		EndIf;
	ElsIf MethodName = "FilesOperationsInternal.FileDataToSaveAsync" Then
		
		ActionParameters.Insert("UUID");
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion