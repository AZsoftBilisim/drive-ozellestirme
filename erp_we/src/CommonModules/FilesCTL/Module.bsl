//@strict-types

#Region Public

// The path of the shared directory of temporary files for access between sessions.
//
// Returns:
//   String - the full path to the directory.
//
Function SharedDirectoryOfTemporaryFiles() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If Common.IsLinuxServer() Then
		SharedTemporaryDirectory = Constants.FileExchangeDirectorySaaSLinux.Get();
	Else
		SharedTemporaryDirectory = Constants.FileExchangeDirectorySaaS.Get();
	EndIf;
	
	If IsBlankString(SharedTemporaryDirectory) Then
		SharedTemporaryDirectory = TrimAll(TempFilesDir());
	Else
		SharedTemporaryDirectory = TrimAll(SharedTemporaryDirectory);
	EndIf;
	
	If Not StrEndsWith(SharedTemporaryDirectory, GetPathSeparator()) Then
		SharedTemporaryDirectory = SharedTemporaryDirectory + GetPathSeparator();
	EndIf;
	
	Return SharedTemporaryDirectory;
	
EndFunction

// Registers a unique file name in the temporary storage.
// 
// Parameters:
//  Prefix - String - The prefix of the file name. Only English letters and numbers, up to 20 characters
//  Extension - String - File extension. English letters and numbers only, up to 4 characters
//  MinutesOfStorage - Number - Minutes of file storage. At least one minute
// 
// Returns:
//  String - the name of the registered temporary file.
Function NewTemporaryStorageFile(Val Prefix, Val Extension, MinutesOfStorage) Export

	If Not ValueIsFilled(MinutesOfStorage) Then
		Raise NStr("vi = 'Chưa chỉ ra thời hạn lưu tệp mới của kho chứa tạm thời';
					|ru = 'Не указан срок хранения нового файла временного хранилища';
					|en = 'The retention period for the new temporary storage file is not specified'; fa = 'The retention period for the new temporary storage file is not specified';
					|it = 'Periodo non indicato di stoccaggio del nuovo file nell''archivio temporaneo';
					|pl = 'Nie jest podany okres przechowywania nowego repozytorium tymczasowego';
					|tr = 'Yeni geçici depolama dosyası için saklama süresi belirtilmedi'");
	EndIf;
	
	If Extension <> Undefined Then
		Extension = FileNamePart(Extension, 4);
		If ValueIsFilled(Extension) Then
			Extension = "." + Extension;
		EndIf;
	EndIf;

	If Prefix <> Undefined Then
		Prefix = FileNamePart(Prefix, 20);
		If ValueIsFilled(Prefix) Then
			Prefix = Prefix + "_";
		EndIf;
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled() And SaaSOperations.SeparatedDataUsageAvailable() Then
		DataArea = SaaSOperations.SessionSeparatorValue();
	Else
		DataArea = 0;
	EndIf;

	FileName = "tmp_" + Format(DataArea, "NZ=0; NG=0;") + "_" + Prefix + New UUID
		+ Extension;

	SetSafeModeDisabled(True);
	RegisterATemporaryStorageFile(FileName, MinutesOfStorage);

	Return FileName;

EndFunction

// Properties of the temporary storage file.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
// 
// Returns:
//  Structure - Properties of the temporary storage file:
// * Registered - Boolean
// * RegistrationDate - Date
// * ShelfLife - Date
// * WindowsPath - String
// * LinuxPath - String 
Function TemporaryStorageFileProperties(FileName) Export

	Result = New Structure;
	Result.Insert("Registered", False);
	Result.Insert("RegistrationDate", Date(1, 1, 1));
	Result.Insert("ShelfLife", Date(1, 1, 1));
	Result.Insert("WindowsPath", "");
	Result.Insert("LinuxPath", "");
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();

	Result.Registered = Record.Selected();
	If Result.Registered Then
		FillPropertyValues(Result, Record);
	EndIf;

	Return Result;

EndFunction

// The full name of the temporary storage file.
// 
// Parameters: 
//  FileName - String - the name of the file registered in the temporary storage
// 
// Returns: 
//  String, Undefined - the full name of the file. Undefined - if the file is not registered
Function FullTemporaryStorageFileName(FileName) Export
	
	FileProperties = TemporaryStorageFileProperties(FileName);
	
	If Not FileProperties.Registered Then
		Return Undefined;
	EndIf;
	
	Return FullNameOfFileInSession(FileName, FileProperties.WindowsPath, FileProperties.LinuxPath);
	
EndFunction

// The full name of the file in the session, depending on the operating system of the working server.
// 
// Parameters: 
//  Name - String
//  WindowsPath - String
//  LinuxPath - String
// 
// Returns: 
//  String - the full name of the file in the session.
Function FullNameOfFileInSession(Name, WindowsPath, LinuxPath) Export
	
	If Common.IsLinuxServer() Then
		Path = LinuxPath;
	Else
		Path = WindowsPath;
	EndIf;
	
	If IsBlankString(Path) Then
		Path = TempFilesDir();
	EndIf;
	
	Separator = GetPathSeparator();
	If Not StrEndsWith(Path, Separator) Then
		Path = Path + Separator;
	EndIf;
	
	Return Path + Name;
	
EndFunction

// Delete the temporary storage file.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
Procedure DeleteTemporaryStorageFile(FileName) Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();
	If Not Record.Selected() Then
		Return;
	EndIf;
	
	FullFileName = FullNameOfFileInSession(FileName, Record.WindowsPath, Record.LinuxPath);
	If Not DeleteFilesInAttempt(FullFileName, NStr("vi = 'Xóa tệp. Tệp kho chứa tạm thời';
													|ru = 'Удаление файла. Файл временного хранилища';
													|en = 'Delete file. Temporary storage file'; fa = 'Delete file. Temporary storage file';
													|it = 'Eliminazione file. File dell''archivio temporale';
													|pl = 'Usunięcie pliku. Plik repozytorium tymczasowego';
													|tr = 'Dosya silinmesi. Zaman aşımı dosyaları'",
		Common.DefaultLanguageCode())) Then
		Return;
	EndIf;
		
	Record.Delete();

EndProcedure

// Delete all temporary storage files except the blocked ones.
// 
// Parameters:
//  Boundary - Date - Universal date before which files should be deleted
Procedure DeleteAllTemporaryStorageFiles(Boundary) Export
	
	SetSafeModeDisabled(True);
	DeleteTemporaryStorageFiles(Boundary);
	
EndProcedure

// Lock the temporary storage file.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
//  FormIdentifier - UUID, Undefined - id of the form for the lifetime of which the file will
//  remain blocked. 
// 
// Returns:
//  Boolean - True if the lock is set
Function LocATemporaryStorageFile(FileName, FormIdentifier = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);

	Try
		LockDataForEdit(Var_Key, Undefined, FormIdentifier);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Unlock the temporary storage file.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
//  FormIdentifier - UUID, Undefined - id of the form in which the file was blocked 
Procedure UnlockTemporaryStorageFile(FileName, FormIdentifier = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);
	UnlockDataForEdit(Var_Key, FormIdentifier);
	
EndProcedure

// The temporary storage file is blocked.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
// 
// Returns:
//  Boolean
Function TemporaryStorageFileBlocked(FileName) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);
	
	Try
		LockDataForEdit(Var_Key);
	Except
		Return True;
	EndTry;
	
	UnlockDataForEdit(Var_Key);
	
	Return False;
	
EndFunction

// Set the retention period of the temporary storage file relative to the current universal date.
// 
// Parameters:
//  FileName - String - the name of the file registered in the temporary storage
//  MinutesOfStorage - Number - Minutes of file storage
// 
// Returns:
//  Boolean - True if the retention period is set
Function SetTemporaryStorageFileRetentionPeriod(FileName, MinutesOfStorage) Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();
	
	If Not Record.Selected() Then
		Return False;
	EndIf;
	
	Record.ShelfLife = CurrentUniversalDate() + MinutesOfStorage * 60;
	Record.Write();
	
	Return True;
	
EndFunction

#EndRegion

#Region Internal

// Deleting temporary storage files. The method of the same-named routine task
Procedure DeletingTemporaryStorageFiles() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.DeletingTemporaryStorageFiles);

	SetSafeModeDisabled(True);
	DeleteTemporaryStorageFiles(CurrentUniversalDate());

EndProcedure

// Delete files in an attempt.
// 
// Parameters:
//  FileName - String
//  EventNameLR - Undefined, String - Name of the log event
// 
// Returns:
//  Boolean - True if the deletion was successful
Function DeleteFilesInAttempt(FileName, EventNameLR = Undefined) Export
	
	Try

		DeleteFiles(FileName);
		Return True;

	Except

		If EventNameLR = Undefined Then
			EventNameLR = NStr("vi = 'Xóa tệp';
								|ru = 'Удаление файла';
								|en = 'Deleting file'; fa = 'Deleting file';
								|it = 'Cancellazione file';
								|pl = 'Usuń plik';
								|tr = 'Dosya silme'", Common.DefaultLanguageCode());
		EndIf;

		CommentOnLREvent = CloudTechnology.DetailedErrorText(ErrorInfo());
		WriteLogEvent(EventNameLR, EventLogLevel.Error, Undefined, Undefined,
			CommentOnLREvent);

	EndTry;

	Return False;

EndFunction

// Send the next batch of data to the server.
// 
// Parameters:
//  FileNameAtServer - String - The name of the file on the server
//  FileData - BinaryData - Binary file data
//  Begin - Number - Start recording file data
Procedure SendAnotherPortion(FileNameAtServer, FileData, Begin) Export

	OpeningMode = ?(Begin = 0, FileOpenMode.Create, FileOpenMode.Append); // FileOpenMode
	WriteStream = FileStreams.Open(FileNameAtServer, OpeningMode, FileAccess.Write);
	SizeOfRecordedFragment = WriteStream.Size();
	
	If SizeOfRecordedFragment <> Begin Then
		
		Raise StrTemplate(
			NStr("vi = 'Kích thước tệp %1 không khớp với dự kiến %2';
				|ru = 'Размер файла %1 не соответствует ожидаемому %2';
				|en = 'Size of file %1 does not match the expected size %2'; fa = 'Size of file %1 does not match the expected size %2';
				|it = 'La dimensione del file %1 non corrisponde al previsto %2';
				|pl = 'Rozmiar pliku %1 nie odpowiada oczekiwanemu %2';
				|tr = '%1 dosyasının boyutu beklenen %2 ile eşleşmiyor'"),
			SizeOfRecordedFragment,
			Begin);
		
	EndIf;

	DataStream = FileData.OpenStreamForRead();
	DataStream.CopyTo(WriteStream);
	WriteStream.Close();
	DataStream.Close();
	WriteStream = Undefined;
	DataStream = Undefined;

EndProcedure

#EndRegion

#Region Private

// @unavailable-in-safemode
Procedure DeleteTemporaryStorageFiles(Boundary)

	SetPrivilegedMode(True);

	Query = New Query;
	Query.SetParameter("Boundary", Boundary);
	Query.Text =
	"SELECT
	|	TemporaryStorageFiles.FileName AS FileName,
	|	TemporaryStorageFiles.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.TemporaryStorageFiles AS TemporaryStorageFiles
	|WHERE
	|	TemporaryStorageFiles.ShelfLife < &Boundary";

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		If TemporaryStorageFileBlocked(Selection.FileName) Then
			Continue;
		EndIf;
		
		Record = TemporaryStorageFileManagerRecord(Selection.FileName, Selection.DataArea);
		Record.Read();
		If Not Record.Selected() Then
			Continue;
		EndIf;

		FullFileName = FullNameOfFileInSession(Record.FileName, Record.WindowsPath, Record.LinuxPath);
		If Not DeleteFilesInAttempt(FullFileName, NStr("vi = 'Xóa tệp. Tệp kho chứa tạm thời';
														|ru = 'Удаление файла. Файл временного хранилища';
														|en = 'Delete file. Temporary storage file'; fa = 'Delete file. Temporary storage file';
														|it = 'Eliminazione file. File dell''archivio temporaneo ';
														|pl = 'Usunięcie pliku. Plik repozytorium tymczasowego';
														|tr = 'Dosya silinmesi. Zaman aşımı dosyaları'",
			Common.DefaultLanguageCode())) Then
			Continue;
		EndIf;
		Record.Delete();

	EndDo;
	
EndProcedure

// @unavailable-in-safemode
Procedure RegisterATemporaryStorageFile(FileName, MinutesOfStorage)
	
	SetPrivilegedMode(True);
	FilePaths = TemporaryFilesSharedDirectoryNames();
	
	RegistrationDate = CurrentUniversalDate();
	Record = InformationRegisters.TemporaryStorageFiles.CreateRecordManager();
	Record.FileName = FileName;
	Record.RegistrationDate = RegistrationDate;
	Record.ShelfLife = RegistrationDate + Max(1, MinutesOfStorage) * 60;
	Record.WindowsPath = FilePaths.WindowsPath; 
	Record.LinuxPath = FilePaths.LinuxPath;
	Record.Write();
	
EndProcedure

Function TemporaryFilesSharedDirectoryNames()
	
	Result = New Structure;

	IsLinux = Common.IsLinuxServer();

	Result.Insert("WindowsPath", ExchangeDirectoryFromConstant(
		Constants.FileExchangeDirectorySaaS.Get(), Not IsLinux, "\"));
	
	Result.Insert("LinuxPath", ExchangeDirectoryFromConstant(
		Constants.FileExchangeDirectorySaaSLinux.Get(), IsLinux, "/"));

	Return Result;

EndFunction

Function ExchangeDirectoryFromConstant(ExchangeDirectory, DefaultDirectoryOfTemporaryFiles, Separator)

	ExchangeDirectory = TrimAll(ExchangeDirectory);
	If IsBlankString(ExchangeDirectory) And DefaultDirectoryOfTemporaryFiles Then
		ExchangeDirectory = TempFilesDir();
	EndIf;
	
	If ValueIsFilled(ExchangeDirectory) And Not StrEndsWith(ExchangeDirectory, Separator) Then
		ExchangeDirectory = ExchangeDirectory + Separator;
	EndIf;
	
	Return ExchangeDirectory;

EndFunction

Function FileNamePart(InitialString, MaxLength)

	Result = "";
	ResultLength = 0;
	For CharacterNumber = 1 To StrLen(InitialString) Do
		Code = CharCode(InitialString, CharacterNumber);
		If (Code >= 48 And Code <= 57)
			Or (Code >= 65 And Code <= 90)
			Or (Code >= 97 And Code <= 122) Then
			Result = Result + Char(Code);
			ResultLength = ResultLength + 1;
			If ResultLength > MaxLength Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function TemporaryStorageFileDataArea(FileName)
	
	Query = New Query;
	Query.SetParameter("FileName", FileName);
	Query.Text =
	"SELECT TOP 1
	|	TemporaryStorageFiles.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.TemporaryStorageFiles AS TemporaryStorageFiles
	|WHERE
	|	TemporaryStorageFiles.FileName = &FileName";

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DataArea;
	EndIf;

	Return Undefined;

EndFunction

// Temporary storage file recording manager.
// 
// Parameters:
//  FileName - String
//  DataArea - Number
// 
// Returns:
//  InformationRegisterRecordManager.TemporaryStorageFiles
Function TemporaryStorageFileManagerRecord(FileName, DataArea = Undefined)

	Record = InformationRegisters.TemporaryStorageFiles.CreateRecordManager();
	Record.FileName = FileName;

	If SaaSOperations.SeparatedDataUsageAvailable() Then
		Return Record;
	EndIf;

	If DataArea = Undefined Then
		DataArea = TemporaryStorageFileDataArea(FileName);
	EndIf;

	If ValueIsFilled(DataArea) Then
		Record.DataAreaAuxiliaryData = DataArea;
	EndIf;

	Return Record;

EndFunction

// The key of the register entry is temporary storage files.
// 
// Parameters:
//  FileName - String - file name
//  DataArea - Number, Undefined - Data area
// 
// Returns:
//  InformationRegisterRecordKey.TemporaryStorageFiles - Register entry key temporary storage files
Function TemporaryStorageFileEntryKey(FileName, DataArea = Undefined)
	
	KeyValues = New Structure;
	KeyValues.Insert("FileName", FileName);
	
	If DataArea = Undefined Then
		DataArea = TemporaryStorageFileDataArea(FileName);
	EndIf;
	If ValueIsFilled(DataArea) Then
		KeyValues.Insert("DataAreaAuxiliaryData", DataArea);
	EndIf;

	Return SaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.TemporaryStorageFiles, KeyValues);

EndFunction

#EndRegion