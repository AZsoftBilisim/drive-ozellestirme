//@strict-types

#Region Public

// Initializes the parameter structure to receive a file from the server to the client.
// For use in the filesclient.Get the filenteractive.
//
// Returns:
//  Structure - File Receipt Parameters:
//    * FileNameOrAddress - String - The address in the temporary storage, or the file name on the server (without a path) to
//        be received by the client. If an address is specified in the temporary storage, an exception will be thrown when trying to retrieve files
//        larger than 4GB.
//    * WindowsFilePath - String - The path to the file when the session is running on the Windows server. The value is ignored
//        if the File Name or Address parameter specifies the address in the temporary storage or specifies the name of the registered
//        temporary storage file.
//    * LinuxFilePath - String - The path to the file when the session is running on a Linux server. The value is ignored
//        if the File Name or Address parameter specifies an address in the temporary storage or the name of the registered
//        temporary storage file is specified.
//    * CallbackDescriptionOnCompletion - CallbackDescription, Undefined - Contains a description of the procedure that
//        will be called after receiving the file. If specified Undefined, no handler
//        will be started. The procedure being called must have parameters:
//           The result is a structure, Undefined - if you refuse to receive the file, either a structure with the properties:
//             Filenames or addresses - String - Address in temporary storage, or file name on the server (without path)
//             Filenames Client -String - full name of the client file received by the client
//           Additional parameters - Arbitrary - the value that was specified when creating
//            the item description of the announcement.
//    * BlockedForm - ClientApplicationForm, Undefined - Owner of the form for getting the file to block.
//        If specified Indeterminately, the entire interface will be blocked for the duration of loading.
//    * TitleOfSaveDialog - String, Undefined - the title of the file selection dialog and the file upload form.
//        If specified Undefined, the headers will be generated automatically.
//    * GetOperationHeader - String, Undefined - the title of the form that displays a long operation.
//    * FilterSaveDialog - String, Undefined - filter of the dialog for selecting the file to save.
//        If you have specified is Undefined in the dialog you can select any file.
//    * FileNameOfSaveDialog - String - The name of the client file that will be suggested in the dialog 
//        box for selecting the file to save.
//    * ShowQuestionOpenSave - Boolean - indicates that when you receive a file, you need
//        to additionally ask a question, and if the answer is positive, immediately open the file. If it is False,
//        the question will not be asked. If the filename or Address parameter specifies an address in temporary storage,
//        the parameter value is ignored and the behavior is regulated by the platform.
Function FileGettingParameters() Export
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("CallbackDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSaveDialog", Undefined);
	Result.Insert("GetOperationHeader", Undefined);
	Result.Insert("FilterSaveDialog", Undefined);
	Result.Insert("FileNameOfSaveDialog", "");
	Result.Insert("ShowQuestionOpenSave", False);
	
	Return Result;
	
EndFunction

// Initializes the parameter structure for placing a file from the client's file system to the server.
// For use in the Client file.Place the file interactively.
//
// Returns:
//  Structure - with properties:
//    * PlacingFileMethod - String - the method of placing the file. Possible values: Temporary storage, File Server,
//        or Upload Service. If not specified, it is determined by the Filename or Address parameter.
//    * FileNameOrAddress - String - The address in temporary storage, or the file name on the server (without a path)
//        for the room. If the address is specified in temporary storage, an exception will be thrown if you try to place files larger than 4 GB
//        , and if you place a file larger than 100 MB, you will need an extension to work with files.
//        If you specify the path to the file on the server, the result will be written to the file, and to work successfully on the web, 
//        you will also need to install the file extension.
//    * WindowsFilePath - String - The path to the file when the session is running on the Windows server. The value is ignored
//        if the File Name or Address parameter specifies the address in the temporary storage or specifies the name of the registered
//        temporary storage file.
//    * LinuxFilePath - String - The path to the file when the session is running on a Linux server. The value is ignored
//        if the File Name or Address parameter specifies an address in the temporary storage or the name of the registered
//        temporary storage file is specified.
//    * CallbackDescriptionOnCompletion - CallbackDescription, Undefined - Contains a description of the procedure that
//        will be called after the file is placed. If specified Undefined, no handler will be started
//        The procedure being called must have parameters:
//           The result is a structure, Undefined - Undefined in case of failure, or a structure with the properties:
//             Filename or Address - String - Address in temporary storage, or file name on the server (without path)
//             Filename Client- String - full name of the client file placed on the server
//          Additional parameters - Arbitrary - the value that was specified when creating the object
//            Description of the Annunciation.
//    * BlockedForm - ClientApplicationForm, Undefined - Owner of the file upload form for blocking.
//        If specified Indefinitely, the entire interface will be blocked for the duration of the download.
//    * TitleOfSelectionDialog - String, Undefined - the title of the file selection dialog.
//    * PutOperationHeader - String, Undefined - the title of the form displaying a lengthy upload operation.
//    * SelectionDialogFilter - String, Undefined - filter of the file selection dialog. If specified Undefined,
//        any file can be selected in the dialog.
//    * FileNameOfSelectionDialog - String - Name of the client file that will be offered in the file selection dialog
//    * MaximumSize - Number, Undefined - the maximum size of the client file available for placement
//      on the server. If specified Indefinitely, the size of the client file will not be monitored.
Function FileLocationParameters() Export
	
	Result = New Structure();
	Result.Insert("PlacingFileMethod", "");
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("CallbackDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSelectionDialog", Undefined);
	Result.Insert("PutOperationHeader", Undefined);
	Result.Insert("SelectionDialogFilter", Undefined);
	Result.Insert("FileNameOfSelectionDialog", "");
	Result.Insert("MaximumSize", Undefined);
	
	Return Result;
	
EndFunction

// Retrieves a file located in temporary storage or on the server disk, and saves it on the client
// in the user's local file system.
//
// Parameters:
//   FileGettingParameters - See FileGettingParameters
Procedure GetFileInteractively(FileGettingParameters) Export
	
	AllParameters = AllFileReceiptParameters();
	FillPropertyValues(AllParameters, FileGettingParameters);
	
	If Not ValueIsFilled(AllParameters.FileNameOrAddress) Then
		ErrorText = NStr("vi = 'Chưa chỉ ra lưu trữ tệp gốc trên server';
						|ru = 'Не указано исходное хранение файла на сервере';
						|en = 'Original file storage on the server is not specified'; fa = 'Original file storage on the server is not specified';
						|it = 'Не указано исходное хранение файла на сервере';
						|pl = 'Original file storage on the server is not specified';
						|tr = 'Dosyanın sunucudaki ilk saklama alanı belirtilmemiş'");
		Raise ErrorText;
	EndIf;

	If IsTempStorageURL(AllParameters.FileNameOrAddress) 
		Or StrStartsWith(AllParameters.FileNameOrAddress, "e1cib/data/") Then
		UseBatchTransfer = False;
	Else
		UseBatchTransfer = True;
	EndIf;
	AllParameters.UseBatchTransfer = UseBatchTransfer;

	Notification = New CallbackDescription("AfterConnectingExtensionToGet", ThisObject, AllParameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, , Not UseBatchTransfer);

EndProcedure

// Places the file selected on the client from the user's local file system in temporary storage
// or in a file on the server disk.
//
// Parameters:
//   FileLocationParameters - See FileLocationParameters
Procedure PlaceFileInteractively(FileLocationParameters) Export
	
	If Not ValueIsFilled(FileLocationParameters.PlacingFileMethod) Then
		If IsTempStorageURL(FileLocationParameters.FileNameOrAddress) Then
			FileLocationParameters.PlacingFileMethod = "TemporaryStorage";
		Else
			FileLocationParameters.PlacingFileMethod = "FileOnServer";
		EndIf;
	EndIf;
	
	AllParameters = AllFileLocationParameters();
	FillPropertyValues(AllParameters, FileLocationParameters);
	
	If AllParameters.PlacingFileMethod = "ImportToService"
		And Not FilesCTLServerCall.ImportToServiceAvailable() Then
		ErrorText = NStr("vi = 'Để kết nhập tệp vào dịch vụ, cần bật sử dụng đăng nhập bằng token truy cập';
						|ru = 'Для загрузки файлов в сервис необходимо включить аутентификацию токенами доступа';
						|en = 'To import files to the service, enable access token authentication'; fa = 'To import files to the service, enable access token authentication';
						|it = 'Для загрузки файлов в сервис необходимо включить аутентификацию токенами доступа';
						|pl = 'To import files to the service, enable access token authentication';
						|tr = 'Dosyaları hizmete yükleyebilmek için erişim jetonları ile doğrulama etkinleştirilmelidir'");
		Raise ErrorText;
	EndIf;
	
	If AllParameters.PlacingFileMethod <> "ImportToService"
		And Not ValueIsFilled(AllParameters.FileNameOrAddress) Then
		ErrorText = NStr("vi = 'Chưa chỉ ra lưu trữ tệp đích trên máy chủ';
						|ru = 'Не указано целевое хранение файла на сервере';
						|en = 'Targeted file storage on the server is not specified'; fa = 'Targeted file storage on the server is not specified';
						|it = 'Allocazione di destinazione del file sul server non è indicata';
						|pl = 'Nie podano celowego przechowywania pliku na serwerze';
						|tr = 'Sunucuda dosyanın hedef depolaması belirtilmedi'");
		Raise ErrorText;
	EndIf;

	If AllParameters.PlacingFileMethod = "TemporaryStorage" Then
		UseBatchTransfer = False;
		MaximumSize = FilesCTLClientServer.MaximumSizeOfTemporaryStorage();
		If AllParameters.MaximumSize = Undefined Then
			AllParameters.MaximumSize = MaximumSize;
		Else
			AllParameters.MaximumSize = Min(AllParameters.MaximumSize, MaximumSize);
		EndIf;
	Else
		UseBatchTransfer = True;
	EndIf;

	AllParameters.UseBatchTransfer = UseBatchTransfer;

	SuggestionText = StrTemplate(NStr("vi = 'Để tải lên các tệp có dung lượng lớn hơn %1, cần cài đặt phần mở rộng để làm việc với 1C: Enterprise. 
									  |Với tiện ích mở rộng này, làm việc trong web-client sẽ trở nên thuận tiện hơn không chỉ khi làm việc với các tệp lớn.';
									  |ru = 'Для загрузки файлов, размером более %1, требуется установить расширение для работы с 1С:Предприятием.
									  |С этим расширением работа в веб-клиенте станет удобней не только при работе с большими файлами.';
									  |en = 'To import files with the size more than %1, install 1C:Enterprise Extension.
									  |This extension improves file management in web client.'; fa = 'To import files with the size more than %1, install 1C:Enterprise Extension.
									  |This extension improves file management in web client.';
									  |it = 'Per scaricare il file di dimensione maggiore di %1 è richiesta l''estensione di lavoro con 1C:Enterprise.
									  | Questa estensione faciliterà il lavoro nel client web e non esclusivamente per il lavoro con i file di grandi dimensioni.';
									  |pl = 'Do pobierania plików o rozmiarze ponad %1, wymaga się zainstalowanie rozszerzenia do pracy z 1С:Enterprise.
									  |Z tym rozszerzeniem praca w kliencie web stanie się bardziej wygodna nie tylko przy pracy z dużymi plikami.';
									  |tr = '%1''den büyük dosyaları yüklemek için, 1C:Enterprise ile çalışmaya yönelik uzantıyı yüklemeniz gerekir.
									  |Bu uzantıyla, web istemcisinde, yalnızca büyük dosyalarla çalışırken değil, çalışmak daha kolay hale gelecektir.'"),
		FilesCTLClientServer.FileSizePresentation(FilesCTLClientServer.AcceptableSizeOfTemporaryStorage()));

	Notification = New CallbackDescription("AfterConnectingExtensionForRoom", ThisObject, AllParameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText,
		Not UseBatchTransfer);

EndProcedure

#EndRegion

#Region Internal

// Place the file on the server.
// 
// Parameters:
//  FileNameAtClient - String - File name on the client
//  FileNameAtServer - String - The name of the file on the server
// 
// Returns:
//  Promise - Place The File On The Server
Async Function PlaceFileOnServer(FileNameAtClient, FileNameAtServer) Export
	
	FSObject = New File(FileNameAtClient);
	FileExists = Await FSObject.ExistsAsync();
	
	If Not FileExists Then
		Return False;
	EndIf;
	
	IsFile = Await FSObject.IsFileAsync();
	
	If Not IsFile Then
		Return False;
	EndIf;
	
	FileSize = Await FSObject.SizeAsync();
	Position = 0;
	
	Stream = Await FileStreams.OpenAsync(FileNameAtClient, FileOpenMode.Open, FileAccess.Read);
	Buffer = New BinaryDataBuffer(FilesCTLClientServer.ProcessingPortionSize(FileSize));
	
	While Position < FileSize Do
		
		BytesReadCount = Await Stream.ReadAsync(Buffer, 0, Buffer.Size);
		Position = Stream.CurrentPosition();
		Buffer = ?(Buffer.Size = BytesReadCount, Buffer, Buffer.Read(0, BytesReadCount));
		
		FilesCTLServerCall.SendAnotherPortion(
			FileNameAtServer,
			GetBinaryDataFromBinaryDataBuffer(Buffer),
			Position - BytesReadCount);
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

// After connecting the extension to work with files to receive.
// 
// Parameters:
//  Attached - Boolean
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterConnectingExtensionToGet(Attached, AdditionalParameters) Export
	
	AdditionalParameters.ExtensionAttached = Attached;

	If Not AdditionalParameters.UseBatchTransfer Then

		If Attached Then

			Notification = New CallbackDescription("AfterGettingFileFromRepository", ThisObject, AdditionalParameters);
			FilesToObtain = New Array; // Array of TransferableFileDescription 
			FilesToObtain.Add(New TransferableFileDescription(AdditionalParameters.FileNameOfSaveDialog,
				AdditionalParameters.FileNameOrAddress));
			Dialog = New FileDialog(FileDialogMode.Save);
			Dialog.Title = AdditionalParameters.TitleOfSaveDialog;
			Dialog.FullFileName = AdditionalParameters.FileNameOfSaveDialog;
			Dialog.Filter = AdditionalParameters.FilterSaveDialog;
			BeginGettingFiles(Notification, FilesToObtain, Dialog, True);

		Else

			GetFile(AdditionalParameters.FileNameOrAddress, AdditionalParameters.FileNameOfSaveDialog,
				True);

			FileDetails = New Structure;
			FileDetails.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
			FileDetails.Insert("FileNameAtClient", Undefined);
			RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, FileDetails);

		EndIf;

		Return;

	EndIf;

	If Not Attached Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	If AdditionalParameters.ShowQuestionOpenSave Then
		ReceivingParameters = New Structure;
		ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
		ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
		ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
		If ValueIsFilled(AdditionalParameters.GetOperationHeader) Then
			ReceivingParameters.Insert("DialogTitle", AdditionalParameters.GetOperationHeader);
		Else
			ReceivingParameters.Insert("DialogTitle", AdditionalParameters.TitleOfSaveDialog);
		EndIf;
		ReceivingParameters.Insert("FilterSaveDialog", AdditionalParameters.FilterSaveDialog);
		ReceivingParameters.Insert("FileNameOfSaveDialog", AdditionalParameters.FileNameOfSaveDialog);
		OpenForm("DataProcessor.FilesCTL.Form.GetFile", ReceivingParameters,
			AdditionalParameters.BlockedForm, , , , AdditionalParameters.CallbackDescriptionOnCompletion);
		Return;
	EndIf;

	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.Title = AdditionalParameters.TitleOfSaveDialog;
	Dialog.FullFileName = AdditionalParameters.FileNameOfSaveDialog;
	Dialog.Filter = AdditionalParameters.FilterSaveDialog;
	Dialog.Show(New CallbackDescription("AfterSelectingFileNameToGet", ThisObject, AdditionalParameters));

EndProcedure

// After selecting the file name to receive.
// 
// Parameters:
//  SelectedFiles - Array of String, Undefined - selected names or Undefined if no selection is made
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterSelectingFileNameToGet(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
	ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
	ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
	If ValueIsFilled(AdditionalParameters.GetOperationHeader) Then
		ReceivingParameters.Insert("DialogTitle", AdditionalParameters.GetOperationHeader);
	Else
		ReceivingParameters.Insert("DialogTitle", AdditionalParameters.TitleOfSaveDialog);
	EndIf;
	ReceivingParameters.Insert("FileNameAtClient", SelectedFiles[0]);
	OpenForm("DataProcessor.FilesCTL.Form.GetFile", ReceivingParameters,
		AdditionalParameters.BlockedForm, , , , AdditionalParameters.CallbackDescriptionOnCompletion);

EndProcedure

// After receiving the file from the repository.
// 
// Parameters:
//  ObtainedFiles - Array of TransferredFileDescription, Undefined
//  AdditionalParameters See AllFileReceiptParameters
Procedure AfterGettingFileFromRepository(ObtainedFiles, AdditionalParameters) Export

	If ValueIsFilled(ObtainedFiles) Then
		FileDetails = New Structure();
		FileDetails.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
		FileDetails.Insert("FileNameAtClient", ObtainedFiles[0].FullName);
	Else
		FileDetails = Undefined;
	EndIf;
	
	RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, FileDetails);

EndProcedure

// After connecting the extension to work with files for the room.
// 
// Parameters:
//  Attached - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterConnectingExtensionForRoom(Attached, AdditionalParameters) Export
	
	AdditionalParameters.ExtensionAttached = Attached;

	If AdditionalParameters.BlockedForm = Undefined Then
		FormID = New UUID;
	Else
		FormID = AdditionalParameters.BlockedForm.UUID;
	EndIf;
	AdditionalParameters.Insert("FormIdentifier", FormID);

	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = AdditionalParameters.TitleOfSelectionDialog;
	Dialog.Filter = AdditionalParameters.SelectionDialogFilter;
	Dialog.FullFileName = AdditionalParameters.FileNameOfSelectionDialog;
	Dialog.CheckFileExistence = True;
	AdditionalParameters.Insert("FileDialog", Dialog);

	If AdditionalParameters.UseBatchTransfer = Undefined
		Or Not AdditionalParameters.UseBatchTransfer Then

		NotificationAfter = New CallbackDescription("AfterPlacingFileInStorage", ThisObject, AdditionalParameters);
		NotificationBefore = New CallbackDescription("BeforePuttingFileInStorage", ThisObject,
			AdditionalParameters);
		BeginPutFile(NotificationAfter, Undefined, Dialog, True, AdditionalParameters.FormIdentifier,
			NotificationBefore);

		Return;

	EndIf;

	If Not Attached Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	Dialog.Show(New CallbackDescription("AfterSelectingFileNameInDialog", ThisObject, AdditionalParameters));

EndProcedure

// After placing the file in the storage.
// 
// Parameters:
//  SelectionDone - Boolean - False if the user refused to perform the operation in the file selection dialog
//  Address - String - location of the new file
//  SelectedFileName - String
//  ImportParameters See AllFileLocationParameters
Procedure AfterPlacingFileInStorage(SelectionDone, Address, SelectedFileName, ImportParameters) Export
	
	If SelectionDone Then
		FileDetails = New Structure();
		FileDetails.Insert("FileNameOrAddress", Address);
		FileDetails.Insert("FileNameAtClient", SelectedFileName);
	Else
		FileDetails = Undefined;
	EndIf;
	
	TimeConsumingOperation = ImportParameters.TimeConsumingOperation; // See DataProcessor.FilesCTL.Form.TimeConsumingOperation
	If TimeConsumingOperation <> Undefined Then
		If TimeConsumingOperation.OperationAborted Then
			DeleteFromTempStorage(Address);
			FileDetails = Undefined;
		EndIf;
		If TimeConsumingOperation.IsOpen() Then
			TimeConsumingOperation.AbortAllowed = True;
			TimeConsumingOperation.Close();
		EndIf;
		TimeConsumingOperation = Undefined;
	EndIf;
	
	RunCallback(ImportParameters.CallbackDescriptionOnCompletion, FileDetails);
	
EndProcedure

// Before placing the file in storage.
// 
// Parameters:
//  FileRef - FileRef - a link to a file ready to be placed in temporary storage.
//  Cancel - Boolean - a sign of refusal to place the file further
//  ImportParameters See AllFileLocationParameters
Procedure BeforePuttingFileInStorage(FileRef, Cancel, ImportParameters) Export
	
	FileProperties = NewFileProperties(FileRef.Name, FileRef.Extension, FileRef.Size());

	CheckingFileBeforePlacing(FileProperties, Cancel, ImportParameters);

	If Cancel Then
		Return;
	EndIf;

	OperationProperties = New Structure;
	OperationProperties.Insert("DialogTitle", ImportParameters.PutOperationHeader);
	OperationProperties.Insert("AbortAllowed", True);
	ImportParameters.TimeConsumingOperation = OpenForm("DataProcessor.FilesCTL.Form.TimeConsumingOperation",
		OperationProperties, ImportParameters.BlockedForm);

EndProcedure

// After selecting the file name in the dialog.
// 
// Parameters:
//  SelectedFiles - Array of String
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterSelectingFileNameInDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;
	
	FileNameAtClient = SelectedFiles[0];
	AdditionalParameters.FileNameAtClient = FileNameAtClient;
	
	Notification = New CallbackDescription("AfterCheckingExistence", ThisObject, AdditionalParameters);
	FSObject = New File(FileNameAtClient);
	FSObject.BeginCheckingExistence(Notification);
	
EndProcedure

// After the existence check.
// 
// Parameters:
//  Exists - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterCheckingExistence(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;
		
	Notification = New CallbackDescription("AfterCheckIsFile", ThisObject, AdditionalParameters);
	FSObject = New File(AdditionalParameters.FileNameAtClient);
	FSObject.BeginCheckingIsFile(Notification);

EndProcedure

// After checking it is a file.
// 
// Parameters:
//  IsFile - Boolean
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterCheckIsFile(IsFile, AdditionalParameters) Export

	If Not IsFile Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	Notification = New CallbackDescription("AfterGettingSize", ThisObject, AdditionalParameters);
	FSObject = New File(AdditionalParameters.FileNameAtClient);
	FSObject.BeginGettingSize(Notification);
	
EndProcedure

// After getting the size.
// 
// Parameters:
//  Size - Number
//  AdditionalParameters See AllFileLocationParameters
Procedure AfterGettingSize(Size, AdditionalParameters) Export
	
	AdditionalParameters.Insert("FileSize", Size);

	FSObject = New File(AdditionalParameters.FileNameAtClient);

	FileProperties = NewFileProperties(FSObject.Name, FSObject.Extension, Size);

	Cancel = False;
	CheckingFileBeforePlacing(FileProperties, Cancel, AdditionalParameters);

	If Cancel Then
		RunCallback(AdditionalParameters.CallbackDescriptionOnCompletion, Undefined);
		Return;
	EndIf;

	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("PlacingFileMethod", AdditionalParameters.PlacingFileMethod);
	ReceivingParameters.Insert("FileNameOrAddress", AdditionalParameters.FileNameOrAddress);
	ReceivingParameters.Insert("WindowsFilePath", AdditionalParameters.WindowsFilePath);
	ReceivingParameters.Insert("LinuxFilePath", AdditionalParameters.LinuxFilePath);
	ReceivingParameters.Insert("DialogTitle", AdditionalParameters.PutOperationHeader);
	ReceivingParameters.Insert("FileNameAtClient", AdditionalParameters.FileNameAtClient);
	ReceivingParameters.Insert("FilePresentation", FilesCTLClientServer.FilePresentation(
		AdditionalParameters.FileNameAtClient, Size));
	ReceivingParameters.Insert("FileSize", Size);
	OpenForm("DataProcessor.FilesCTL.Form.PuttingFile", ReceivingParameters,
		AdditionalParameters.BlockedForm, , , , AdditionalParameters.CallbackDescriptionOnCompletion);

EndProcedure

// New file properties
// 
// Parameters:
//  Name - String
//  Extension - String
//  Size - Number
// 
// Returns:
//  Structure:
// * Name - String
// * Extension - String
// * Size - Number
Function NewFileProperties(Name, Extension, Size)
	
	FileProperties = New Structure;
	FileProperties.Insert("Name", Name);
	FileProperties.Insert("Extension", Extension);
	FileProperties.Insert("Size", Size);
	
	Return FileProperties;
	
EndFunction

// Checking the file before placing.
// 
// Parameters:
//  FileRef - See NewFileProperties
//  Cancel - Boolean
//  CheckParameters See AllFileLocationParameters
Procedure CheckingFileBeforePlacing(FileRef, Cancel, CheckParameters)
	
	If FileRef = Undefined Then
		HandleValidationError(Cancel, NStr("vi = 'Chưa chỉ ra tham chiếu đến tệp';
											|ru = 'Не указана ссылка на файл';
											|en = 'Reference to the file is not specified'; fa = 'Reference to the file is not specified';
											|it = 'Riferimento al file non è indicato';
											|pl = 'Nie podano odnośnika do pliku';
											|tr = 'Dosyaya bağlantı belirtilmemiş'"));
		Return;
	EndIf;

	FilterProperties = DialogFilterProperties(CheckParameters.SelectionDialogFilter);
	If FilterProperties <> Undefined And FilterProperties.Extensions.Find(Lower(FileRef.Extension)) = Undefined
		And FilterProperties.Extensions.Find("*") = Undefined Then
		HandleValidationError(Cancel, StrTemplate(NStr("vi = 'Đã chọn sai kiểu tệp. Vui lòng chọn:
													   |%1';
													   |ru = 'Выбран неверный тип файла. Выберите:
													   |%1';
													   |en = 'Incorrect file type is selected. Select:
													   |%1'; fa = 'Incorrect file type is selected. Select:
													   |%1';
													   |it = 'Tipo errato di file selezionato. Selezionate:
													   |%1';
													   |pl = 'Wybrano nieprawidłowy typ pliku. Wybierz:
													   |%1';
													   |tr = 'Hatalı dosya türü seçilmiştir. Seçin:
													   |%1'"), StrConcat(FilterProperties.Presentations, Chars.LF)));
		Return;
	EndIf;

	If Not CheckParameters.ExtensionAttached Then
		MaxSizeWithoutExtension = FilesCTLClientServer.AcceptableSizeOfTemporaryStorage();
		If FileRef.Size > MaxSizeWithoutExtension Then
			HandleValidationError(Cancel, StrTemplate(NStr("vi = 'Đã chọn tệp %1 lớn hơn %2 
				|Để làm việc với các tệp như vậy trong web-client, bạn cần cài đặt phần mở rộng 1C:Enterprise. 
				|Sử dụng thin client hoặc cài đặt tiện ích mở rộng';
				|ru = 'Выбран файл %1 больше %2
				|Для работы в веб клиенте с такими файлами требуется установка расширения 1С:Предприятия.
				|Воспользуйтесь тонким клиентом, либо установите расширение';
				|en = 'File %1 with size more than %2 is selected
				|To use such files in web client, install 1C:Enterprise Extension.
				|Use thin client or install the extension'; fa = 'File %1 with size more than %2 is selected
				|To use such files in web client, install 1C:Enterprise Extension.
				|Use thin client or install the extension';
				|it = 'Il file selezionato %1 supera %2
				| Per il lavoro nel client web con questi file è richiesta l''installazione dell''estensione 1C:Enterprise.
				| Usate thin client o installate l''estensione';
				|pl = 'Wybrano plik %1 ponad %2
				|Do pracy w kliencie web z takimi plikami wymaga się zainstalowanie rozszerzenia 1С:Enterprise.
				|Skorzystaj z cienkiego klienta albo zainstaluj rozszerzenie';
				|tr = 'Seçilen %1 dosyası %2''den büyük
				|Web istemcisinde bu tür dosyalarla çalışmak için 1C:Enterprise uzantısını yüklemeniz gerekir.
				|İnce istemci kullanın veya uzantıyı yükleyin'"),
				FileRef.Name, FilesCTLClientServer.FileSizePresentation(MaxSizeWithoutExtension)));
		EndIf;
	EndIf;

	MaximumSize = CheckParameters.MaximumSize;
	If MaximumSize = Undefined Then
		Return;
	EndIf;

	If FileRef.Size > MaximumSize Then
		If MaximumSize <= 0 Then
			ErrorText = StrTemplate(NStr("vi = 'Kích thước tệp phải là %1';
										|ru = 'Размер файла должен быть равен %1';
										|en = 'File size must be %1'; fa = 'File size must be %1';
										|it = 'La dimensione del file deve essere pari a %1';
										|pl = 'Rozmiar pliku powinien wynosić równać się %1';
										|tr = 'Dosya boyutu %1 eşit olmak zorunda'"),
				FilesCTLClientServer.FileSizePresentation(0));
		Else
			ErrorText = StrTemplate(NStr("vi = 'Tệp %1 quá lớn. Hãy chọn tệp nhỏ hơn %2';
										|ru = 'Файл %1 слишком большой. Выберите файл менее %2';
										|en = 'File %1 is too large. Select a file with size less than %2'; fa = 'File %1 is too large. Select a file with size less than %2';
										|it = 'Il file %1 è troppo grande. Selezionate un file minore di %2';
										|pl = 'Plik %1 jest zbyt duży. Wybierz plik mniej niż %2';
										|tr = '%1 dosyası çok büyük. %2 küçük olan dosyayı seçin'"), FileRef.Name,
				FilesCTLClientServer.FileSizePresentation(MaximumSize));
		EndIf;
		HandleValidationError(Cancel, ErrorText);
		Return;
	EndIf;

EndProcedure

Procedure HandleValidationError(Cancel, WarningText)
	
	Cancel = True;
	ShowMessageBox(Undefined, WarningText);
	
EndProcedure

Function DialogFilterProperties(DIalogBoxFilter)
	
	If Not ValueIsFilled(DIalogBoxFilter) Then
		Return Undefined;
	EndIf;

	Presentations = New Array; // Array of String
	Masks = New Array; // Array of String
	Extensions = New Array; // Array of String
	Result = New Structure("Presentations, Masks, Extensions", Presentations, Masks, Extensions);

	FilterElements = StrSplit(DIalogBoxFilter, "|");
	While FilterElements.UBound() > 0 Do

		Presentation = FilterElements[0];
		Mask = FilterElements[1];

		Result.Presentations.Add(Presentation);
		Result.Masks.Add(Mask);

		MaskElements = StrSplit(Mask, ";");
		For Each MaskElement In MaskElements Do
			If MaskElement = "*.*" Or MaskElement = "*" Then
				Result.Extensions.Add("*");
				Break;
			Else
				Pos = StrFind(MaskElement, ".", SearchDirection.FromEnd);
				If Pos > 0 Then
					Result.Extensions.Add(Lower(Mid(MaskElement, Pos)));
				Else
					Result.Extensions.Add("");
				EndIf;
			EndIf;
		EndDo;

		FilterElements.Delete(0);
		FilterElements.Delete(0);

	EndDo;

	Return Result;

EndFunction

// All parameters of getting the file.
//
// Returns:
//  Structure:
//    * FileNameOrAddress - String
//    * WindowsFilePath - String
//    * LinuxFilePath - String
//    * CallbackDescriptionOnCompletion - CallbackDescription, Undefined -
//    * BlockedForm - ClientApplicationForm, Undefined -
//    * TitleOfSaveDialog - String
//    * GetOperationHeader - String
//    * FilterSaveDialog - String
//    * FileNameOfSaveDialog - String
//    * ShowQuestionOpenSave - Boolean
//    * UseBatchTransfer - Boolean 
//    * ExtensionAttached - Boolean
Function AllFileReceiptParameters()
	
	Result = New Structure();
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("CallbackDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSaveDialog", "");
	Result.Insert("GetOperationHeader", "");
	Result.Insert("FilterSaveDialog", "");
	Result.Insert("FileNameOfSaveDialog", "");
	Result.Insert("ShowQuestionOpenSave", False);
	Result.Insert("UseBatchTransfer", False);
	Result.Insert("ExtensionAttached", False);
	
	Return Result;
	
EndFunction

// All parameters of the file location.
// 
// Returns:
//  Structure:
// * PlacingFileMethod - String
// * FileNameOrAddress - String
// * WindowsFilePath - String
// * LinuxFilePath - String
// * CallbackDescriptionOnCompletion - CallbackDescription, Undefined -
// * BlockedForm - ClientApplicationForm, Undefined -
// * TitleOfSelectionDialog - String
// * PutOperationHeader - String
// * SelectionDialogFilter - String
// * FileNameOfSelectionDialog - String
// * MaximumSize - Number, Undefined -
// * UseBatchTransfer - Boolean
// * ExtensionAttached - Boolean
// * TimeConsumingOperation - ClientApplicationForm, Undefined -
// * FileNameAtClient - String
Function AllFileLocationParameters()
	
	Result = New Structure();
	Result.Insert("PlacingFileMethod", "");
	Result.Insert("FileNameOrAddress", "");
	Result.Insert("WindowsFilePath", "");
	Result.Insert("LinuxFilePath", "");
	Result.Insert("CallbackDescriptionOnCompletion", Undefined);
	Result.Insert("BlockedForm", Undefined);
	Result.Insert("TitleOfSelectionDialog", "");
	Result.Insert("PutOperationHeader", "");
	Result.Insert("SelectionDialogFilter", "");
	Result.Insert("FileNameOfSelectionDialog", "");
	Result.Insert("MaximumSize", Undefined);
	Result.Insert("UseBatchTransfer", False);
	Result.Insert("ExtensionAttached", False);
	Result.Insert("TimeConsumingOperation", Undefined);
	Result.Insert("FileNameAtClient", "");
	
	Return Result;
	
EndFunction

#EndRegion