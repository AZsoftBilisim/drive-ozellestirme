#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ForUnloading;
Var ForImport;
Var IsChildThread;

Var ContainerInitialized;
Var TempDirectory;
Var UploadFileName;
Var Archive;
Var NumberOfFilesByType;
Var UploadStartTime;
Var Content; // ValueTable
Var ArbitraryFilesCount;
Var ArbitraryFilesSize;
Var FilesUsed; // Array of String
Var Warnings; // See Warnings
Var UploadTo;
Var ExportToClient;
Var PartsExportedToClient;
Var MultipartUpload; // See NewMultipartUpload
Var UploadExtensionData;
Var ExportDataFromPlusExtensions;
Var UnloadDifferentialCopy;
Var ForTechnicalSupport;
Var Parameters; // Structure
Var ExtensionsFrameVersions;
Var PlusExtensionsAgent;
Var ImportFileData;
Var DuplicatesOfPredefinedItems; // Map
Var ProcessID;
Var MessageNumberInStream; // Number
Var ThreadNumber; // Number
Var ClientSessionNumber; // Number

Var FixState;
Var StateRecording;
Var NextStateRecordMinimumDate;
Var ProcessedObjectsAfterCalculatingState;
Var ObjectsProcessedDuringCurrentSession;
Var ObjectsAtCompletionPercentage;
Var ProcessingObjectsCount; // ValueTable
Var ProcessedObjectsByMetadata; // Map
Var MetadataObjectForProcessingFullName; // String

#EndRegion

#Region Internal

#Region Upload0

// Initializes the upload.
//
// Parameters:
//	ExportingParameters - See ExportImportData.UploadCurAreaDataToArchive.ExportingParameters
//
Procedure InitializeUpload(Val ExportingParameters) Export
	
	CheckingContainerInitialization(True);
	
	ForUnloading = True;
	Parameters = ExportingParameters;
	ProcessID = New UUID();
	
	InitializeExportVariables();
	InitializeAdditionalUploadProperties();
		
	UploadStartTime = CurrentSessionDate();	

	TempDirectory = GetTempFileName("zip") + GetPathSeparator();
	CreateDirectory(TempDirectory);
	
	UploadFileName = Undefined;
	ExportingParameters.Property("UploadFileName", UploadFileName);
	
	If Not ValueIsFilled(UploadFileName) Then
		UploadFileName = GetTempFileName("zip");
	EndIf;
	
	Archive = ZIPArchives.Create(UploadFileName);
		
	If Not ExportingParameters.Property("UploadTo", UploadTo) Then
		UploadTo = False;
	EndIf;
	
	If Not ExportingParameters.Property("ExportToClient", ExportToClient) Then
		ExportToClient = False;
	EndIf;
	PartsExportedToClient = 0;
	
	If Not ExportingParameters.Property("UploadExtensionData", UploadExtensionData) Then
		UploadExtensionData = False;
	EndIf;
	
	If Not ExportingParameters.Property("ExportDataFromPlusExtensions", ExportDataFromPlusExtensions) Then
		ExportDataFromPlusExtensions = False;
	EndIf;
	
	If Not ExportingParameters.Property("UnloadDifferentialCopy", UnloadDifferentialCopy) Then
		UnloadDifferentialCopy = False;
	EndIf;
	
	If Not ExportingParameters.Property("ExtensionsFrameVersions", ExtensionsFrameVersions) Then
		ExtensionsFrameVersions = New Map();
	EndIf;
	
	If Not ExportingParameters.Property("Extensions1CPlus", PlusExtensionsAgent) Then
		PlusExtensionsAgent = New Map();
	EndIf;
	
	If Not ExportingParameters.Property("ExportModeForTechnicalSupport", ForTechnicalSupport) Then
		ForTechnicalSupport = False;
	EndIf;
	
	ClientSessionNumber = ExportImportDataInternal.ClientSessionNumberFromParameters(ExportingParameters);
	
	SetCountOfProcessedObjects();
	InitializeState();
	
	ContainerInitialized = True;
	
EndProcedure

Procedure InitializeUploadInThread(StreamParameters) Export
	
	InitializeVariablesInThread(StreamParameters);
	InitializeExportVariables();
	InitializeAdditionalUploadProperties();
	InitializeStateVariables();
	
	ContainerInitialized = True;
	
EndProcedure

// The parameters of discharge
// 
// Returns: 
//  Structure - containing data upload parameters:
//		* TypesToExport - Array of MetadataObject  - the data that you want to upload to the archive
//      * UnloadUsers - Boolean - to upload information about users of the information base,
//      * ExportUserSettings - Boolean - ignored if Unloaded users = False.
//    Also, the structure may contain additional keys that can be processed inside
//      arbitrary data upload handlers.
Function ExportingParameters() Export
	
	CheckingContainerInitialization();
	
	If ForUnloading Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("vi = 'Chưa khởi tạo nơi chứa để kết xuất dữ liệu.';
					|ru = 'Контейнер не инициализирован для выгрузки данных.';
					|en = 'The container is not initialized for data export.'; fa = 'The container is not initialized for data export.';
					|it = 'Il contenitore non è inizializzato per caricare i dati.';
					|pl = 'Kontener nie został zainicjowany w celu przesłania danych.';
					|tr = 'Kapsayıcı, veri dışa aktarmak için başlatılmadı.'");
	EndIf;
	
EndFunction

Function ForTechnicalSupport() Export
	
	Return ForTechnicalSupport;
	
EndFunction

Procedure SetUploadParameters(ExportingParameters) Export
	
	Parameters = ExportingParameters;
	
EndProcedure

// Creates a file in the upload folder.
//
// Parameters:
//	FileKind - String - type of upload file.
//	DataType - String - data type.
//
// Returns:
//	String - file name.
//
Function CreateFile(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return AppendFile(FileKind, "xml", DataType);
	
EndFunction

// Creates an arbitrary upload file.
//
// Parameters:
//	Extension - String - file extension.
//	DataType - String - data type.
//
// Returns:
//	String - file name.
//
Function CreateCustomFile(Val Extension, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return AppendFile(ExportImportDataInternal.CustomData(), Extension, DataType);
	
EndFunction

Procedure SetNumberOfObjects(Val FullFilePath, Val NumberOfObjects = Undefined) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow = Undefined Then
		Raise NStr("vi = 'Không tìm thấy tệp';
					|ru = 'Файл не найден';
					|en = 'File not found'; fa = 'File not found';
					|it = 'Il file non è stato trovato';
					|pl = 'Plik nie został znaleziony';
					|tr = 'Dosya bulunamadı'");
	EndIf;
	
	CompositionRow.NumberOfObjects = NumberOfObjects;
	
EndProcedure

Procedure ExcludeFile(Val FullFilePath) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow <> Undefined Then
		
		FilesCount = NumberOfFilesByType[CompositionRow.FileKind];
		NumberOfFilesByType.Insert(CompositionRow.FileKind, FilesCount - 1);
		Content.Delete(CompositionRow);
		
	EndIf;
		
	FilesUsed.Delete(FilesUsed.Find(FullFilePath));
	DeleteFiles(FullFilePath);
	
EndProcedure

Procedure FileRecorded(Val FullFilePath) Export
	
	File = New File(FullFilePath);
	ArbitraryFileSize = Undefined;
	
	CompositionRow = FindCompositionLine(FullFilePath, "FullName");
	If CompositionRow <> Undefined Then
		CompositionRow.Size = File.Size();
	Else
		ArbitraryFileSize = File.Size();
	EndIf;
	
	RelativeName = Mid(FullFilePath, StrLen(TempDirectory));
	ArchiveDirectory = GetTempFileName("zip");
	Parts = StrSplit(RelativeName, GetPathSeparator());
	Parts.Delete(Parts.UBound());
	CreateDirectory(ArchiveDirectory + StrConcat(Parts, GetPathSeparator()));
	MoveFile(FullFilePath, ArchiveDirectory + RelativeName);
	FilesUsed.Delete(FilesUsed.Find(FullFilePath));
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("ArchiveDirectory", ArchiveDirectory);

		If ArbitraryFileSize <> Undefined Then
			
			MessageData.Insert("ArbitraryFilesSize", ArbitraryFileSize);
			MessageData.Insert("ArbitraryFilesCount", 1);
			
		EndIf;
		
		ExportImportDataInternal.SendMessageToParentThread(
			ThisObject,
			"FileRecorded",
			MessageData);
		
	Else
		
		If ArbitraryFileSize <> Undefined Then
			
			ArbitraryFilesSize = ArbitraryFilesSize + ArbitraryFileSize;
			ArbitraryFilesCount = ArbitraryFilesCount + 1;
			
		EndIf;

		AddFileToArchive(ArchiveDirectory);
		
	EndIf;
	
EndProcedure

// Returns whether the differential copy is unloaded
// 
// Returns:
// 	Boolean - 
Function UnloadDifferentialCopy() Export
	
	Return UnloadDifferentialCopy;
	
EndFunction

Function ThisIsBackup() Export
	
	If Parameters.Property("ThisIsBackup") Then
		Return Parameters.ThisIsBackup;
	EndIf;
	
	Return False;
	
EndFunction

// Completes the upload. Writes the upload information to a file.
//
// Returns:
//   String - full file name or file ID.
//
Function FinalizeUpload() Export
	
	CheckingContainerInitialization();
	
	DigestFileName = CreateFile(ExportImportDataInternal.Digest(), ExportImportDataInternal.CustomData());
	RecordDigest(DigestFileName);
	
	RecordUploadWarnings();
	RecordDuplicatesOfPredefined();
	
	RecordInformationAboutExtensions();
	
	RecordAppTypeInformation();
	
	NameOfContentFile = CreateFile(ExportImportDataInternal.PackageContents(), ExportImportDataInternal.CustomData());
	WriteContainerContentsToFile(NameOfContentFile);
	
	For Each FoundFile In FindFiles(TempDirectory, "*", True) Do
		If FoundFile.IsFile() Then
			FileRecorded(FoundFile.FullName);
		EndIf;
	EndDo;
	
	DeleteFiles(TempDirectory);
	
	If FilesUsed.Count() > 0 Then
		Template = NStr("vi = 'Đã tìm thấy tệp bị mất: %1';
						|ru = 'Обнаружены потерянные файлы: %1';
						|en = 'Missing files were found: %1'; fa = 'Missing files were found: %1';
						|it = 'Обнаружены потерянные файлы: %1';
						|pl = 'Missing files were found: %1';
						|tr = 'Kayıp dosyalar algılandı: %1'");
		Raise StrTemplate(Template, StrConcat(FilesUsed, Chars.LF));
	EndIf;
	
	ZIPArchives.ExitApp(Archive);
	
	If UploadTo Then
		If MultipartUpload = Undefined Then
			File = New File(Archive.FileName);
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("FileName", File.Name);
			AdditionalParameters.Insert("FileSize", File.Size());
			AdditionalParameters.Insert("FileType", "BackupDataArea_");
			AdditionalParameters.Insert("DataArea", SaaSOperations.SessionSeparatorValue());
			AdditionalParameters.Insert("DataAreaKey", Constants.DataAreaKey.Get());
			AdditionalParameters.Insert("S3Support", True);
			
			FileID = SaaSOperations.PlaceFileInStorageOfServiceManager(File, , AdditionalParameters);
			DeleteFiles(Archive.FileName);
			Return FileID;
		Else
			Result = ServiceProgrammingInterface.NewPart(MultipartUpload.FileID, MultipartUpload.Parts.Count() + 1);
			If Result.Type = "s3" Then
				SendPartOfS3File(Result, Archive.FileName);
				ServiceProgrammingInterface.CompleteMultipartUpload(MultipartUpload.FileID, MultipartUpload.Parts);
			Else
				SendPartOfDTFile(Result, Archive.FileName, True);
			EndIf;
			DeleteFiles(Archive.FileName);
			Return MultipartUpload.FileID;
		EndIf;
	ElsIf ExportToClient Then
		
		PartsExportedToClient = PartsExportedToClient + 1;
		Prefix = StrTemplate("data2xml-%1", Format(PartsExportedToClient, "NG=0"));
		TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile(Prefix, "zip", 120);
		UploadFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
		MoveFile(Archive.FileName, UploadFileName);
		RegisterExportPart(PartsExportedToClient, TemporaryStorageFileName);
		
	EndIf;
	
	If FixState Then
		SaveEndState();
	EndIf;
	
	Return Archive.FileName;
	
EndFunction

// This is a data upload.
// 
// Returns:
//  Boolean - This Is A Data Upload
Function ThisIsDataExport() Export
	
	CheckingContainerInitialization();
	
	Return ForUnloading;
	
EndFunction

#EndRegion

#Region Load

// Initializes the download.
//
// Parameters:
//	FileData - String, UUID, Structure - file name, file ID, or file data obtained using ziparchives.Read the archive().
//	ImportParameters - See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
//
Procedure InitializeDownload(Val FileData, Val ImportParameters) Export
	
	CheckingContainerInitialization(True);
	
	ForImport = True;
	ImportFileData = FileData;
	Parameters = ImportParameters;
	ProcessID = New UUID();
	
	InitializeImportVariables(FileData);

	PathSeparator = GetPathSeparator();
	 
	TempDirectory = GetTempFileName("zip") + PathSeparator;
	CreateDirectory(TempDirectory);
	
	CompositionFileName = GetFileName(ExportImportDataInternal.PackageContents());
	UnzipFileByName(CompositionFileName);
	
	Content = ExportImportDataInternal.ArchiveContent(TempDirectory + CompositionFileName);
	
	Content.Columns.Add("FullName", New TypeDescription("String"));
	For Each CompositionRow In Content Do
		CompositionRow.FullName = TempDirectory + CompositionRow.Directory + PathSeparator + CompositionRow.Name;
	EndDo;
		
	Content.Indexes.Add("FileKind, DataType");
	Content.Indexes.Add("FileKind");
	Content.Indexes.Add("FullName");
	Content.Indexes.Add("Directory");
	Content.Indexes.Add("Name");
	
	SearchParameters = ExportImportDataInternal.NewFileFromArchiveSearchParameters();
	SearchParameters.Name = GetFileName(ExportImportDataInternal.Digest());
	
	DigestFileParameters = ExportImportDataInternal.GetFileParametersFromArchive(
		Content, SearchParameters);
	DigestFileName = DigestFileParameters.Name;
	DigestDirectoryName = DigestFileParameters.Directory;
	
	UnzipFileByName(DigestFileName, DigestDirectoryName);
	
	ForTechnicalSupport = ExportImportDataInternal.ExportForTechnicalSupportMode(
		TempDirectory + DigestDirectoryName + PathSeparator + DigestFileName);
	ClientSessionNumber = ExportImportDataInternal.ClientSessionNumberFromParameters(ImportParameters);
	
	SetCountOfProcessedObjects();
	InitializeState();
	
	ContainerInitialized = True;
	
EndProcedure

Procedure InitializeImportInThread(StreamParameters) Export
	
	InitializeVariablesInThread(StreamParameters);
	InitializeImportVariables(StreamParameters.FileData);
	InitializeStateVariables();
	
	ContainerInitialized = True;
	
EndProcedure

// Boot parameter
// 
// Returns: See ExportImportData.DownloadCurAreaDataFromArchive.ImportParameters
Function ImportParameters() Export
	
	CheckingContainerInitialization();
	
	If ForImport Then
		Return New FixedStructure(Parameters);
	Else
		Raise NStr("vi = 'Chưa khởi tạo nơi chứa để kết nhập dữ liệu.';
					|ru = 'Контейнер не инициализирован для загрузки данных.';
					|en = 'Export container is not initialized for data import.'; fa = 'Export container is not initialized for data import.';
					|it = 'Contenitore non inizializzato pe ril download dei dati.';
					|pl = 'Kontener nie został zainicjowany w celu przesyłania danych.';
					|tr = 'Kapsayıcı, veri içe aktarmak için başlatılmadı.'");
	EndIf;
	
EndFunction

Procedure SetDownloadParameters(ImportParameters) Export
	
	Parameters = ImportParameters;
	
EndProcedure

// Retrieves a file from a folder.
//
// Parameters:
//	FileKind - String - type of upload file.
//	DataType - String - data type.
//
// Returns:
//	ValueTableRow
//
Function GetFileFromFolder(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Files = GetFilesFromComposition(FileKind, DataType);
	If Files.Count() = 0 Then
		Return Undefined;
	ElsIf Files.Count() > 1 Then
		Template = NStr("vi = 'Khi kết xuất có chứa tệp trùng lặp, dạng tệp: %1, kiểu dữ liệu: %2, số lượng:%3';
						|ru = 'В выгрузке содержатся дубли файлов, вид файла: %1, тип данных: %2, количество: %3';
						|en = 'Export contains duplicate files, file type: %1, data type: %2, quantity: %3'; fa = 'Export contains duplicate files, file type: %1, data type: %2, quantity: %3';
						|it = 'Upload contiene duplicati di file, tipo di file: %1, tipo di dati: %2, quantità: %3';
						|pl = 'Eksportowanie zawiera duplikaty plików, rodzaj pliku: %1, typ danych: %2, ilość: %3';
						|tr = 'Dışa aktarma, tekrarlanan dosyalar içeriyor, dosya türü: %1, veri türü: %2, miktar: %3'");
		Raise StrTemplate(Template, FileKind, DataType, Files.Count());
	EndIf;
	
	Return Files[0];
	
EndFunction

// Retrieves an arbitrary file from a folder.
//
// Parameters:
//	DataType - String - data type.
//
// Returns:
//	String
//
Function GetCustomFile(Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Files = GetFilesFromComposition(ExportImportDataInternal.CustomData() , DataType);
	If Files.Count() = 0 Then
		Raise StrTemplate(NStr("vi = 'Khi kết xuất không có tệp tùy ý có kiểu dữ liệu %1.';
								|ru = 'В выгрузке отсутствует произвольный файл с типом данным %1.';
								|en = 'There is no arbitrary file with the %1 data type in export.'; fa = 'There is no arbitrary file with the %1 data type in export.';
								|it = 'Non ci sono file liberi con tipo di dati %1 nell''upload.';
								|pl = 'W przesyłaniu brak arbitralnego pliku z typem danych%1.';
								|tr = 'Dışa aktarmada, %1 veri tipine sahip serbest dosya eksik.'"),
			DataType);
	ElsIf Files.Count() > 1 Then
		Template = NStr("vi = 'Khi kết xuất có chứa các tệp trùng lặp tùy ý: kiểu dữ liệu: %1, số lượng:%2';
						|ru = 'В выгрузке содержатся дубли произвольных файлов, тип данных: %1, количество: %2';
						|en = 'Export contains duplicate arbitrary files, data type: %1, quantity: %2'; fa = 'Export contains duplicate arbitrary files, data type: %1, quantity: %2';
						|it = 'Upload contiene duplicati di file liberi, tipo di dati: %1, quantità: %2';
						|pl = 'Eksportowanie zawiera duplikaty dowolnych plików, typ danych: %1, ilość: %2';
						|tr = 'Dışa aktarma serbest dosyaların kopyalarını içeriyor, veri tipi: %1, miktar: %2'");
		Raise StrTemplate(Template, DataType, Files.Count());
	EndIf;
	
	UnzipFile(Files[0]);
	
	Return Files[0].FullName;
	
EndFunction

// Get files from a directory.
// 
// Parameters: 
//	FileKind - String - type of upload file.
//	DataType - String - data type.
// 
// Returns:  
//  See GetFileDescriptionsFromFolder
Function GetFilesFromDirectory(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return GetFileDescriptionsFromFolder(FileKind, DataType);
	
EndFunction

// Get file descriptions from a folder
// 
// Parameters: 
//	FileKind - String - type of upload file.
//	DataType - String - data type.
// 
// Returns: 
//  ValueTable:
// * Name - String
// * Directory - String
// * FullName - String
// * Size - Number
// * FileKind - String
// * Hash - String
// * NumberOfObjects - Number
// * DataType - String
Function GetFileDescriptionsFromFolder(Val FileKind, Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	TableWithFiles = ExportImportDataInternal.NewContent();
	
	If TypeOf(FileKind) = Type("Array") Then 
		
		For Each SeparateView In FileKind Do
			AddFilesToValueTable(TableWithFiles, GetFilesFromComposition(SeparateView , DataType));
		EndDo;
		Return TableWithFiles;
		
	ElsIf TypeOf(FileKind) = Type("String") Then 
		
		Return GetFilesFromComposition(FileKind, DataType);
		
	Else
		
		Raise NStr("vi = 'Dạng tệp không xác định';
					|ru = 'Неизвестный вид файла';
					|en = 'Unknown file type'; fa = 'Unknown file type';
					|it = 'Tipo di file sconosciuto';
					|pl = 'Nieznany rodzaj pliku';
					|tr = 'Bilinmeyen dosya türü'");
		
	EndIf;
	
EndFunction

// Get custom files
// 
// Parameters: 
//  DataType - String - data type.
// 
// Returns: 
//  Array of String
Function GetArbitraryFiles(Val DataType = Undefined) Export
	
	CheckingContainerInitialization();
	
	Return GetDescriptionsOfArbitraryFiles(DataType).UnloadColumn("FullName");
	
EndFunction

// Get the full file name
// 
// Parameters: 
//  RelativeFileName - String
// 
// Returns: 
//  String - full file name.
Function GetFullFileName(Val RelativeFileName) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = Content.Find(RelativeFileName, "Name");
	
	If CompositionRow = Undefined Then
		
		PathParts = StrSplit(RelativeFileName, "/\");
		
		CompositionRow = New Structure;
		CompositionRow.Insert("Name", PathParts[PathParts.UBound()]);
		CompositionRow.Insert("FullName", TempDirectory + StrConcat(PathParts, GetPathSeparator()));
		PathParts.Delete(PathParts.UBound());
		CompositionRow.Insert("Directory", StrConcat(PathParts, GetPathSeparator()));
		
	EndIf;
	
	UnzipFile(CompositionRow);
	Return CompositionRow.FullName;
	
EndFunction

// Gets the relative file name
// 
// Parameters: 
//  FullFileName - String
// 
// Returns: 
//  String - relative file name.
Function GetRelativeFileName(Val FullFileName) Export
	
	CheckingContainerInitialization();
	
	CompositionRow = FindCompositionLine(FullFileName, "FullName");
	
	If CompositionRow = Undefined Then
		Return StrReplace(FullFileName, TempDirectory, "");
	Else
		Return CompositionRow.Name;
	EndIf;
	
EndFunction

Procedure FinalizeDownload() Export
	
	CheckingContainerInitialization();
	ClearTemporaryImportingData();
		
	If FixState Then
		SaveEndState();
	EndIf;
	
EndProcedure

Procedure ClearTemporaryImportingData() Export
	
	DeleteFiles(TempDirectory);
	
EndProcedure

Procedure UnzipFile(FileRow) Export
	
	For ReverseIndex = 1 - FilesUsed.Count() To 0 Do
		FullFileName = FilesUsed[-ReverseIndex];
		File = New File(FullFileName);
		If Not File.Exists() Then
			FilesUsed.Delete(-ReverseIndex);
		ElsIf FileIsWritable(FullFileName) Then
			DeleteFiles(FullFileName);
			FilesUsed.Delete(-ReverseIndex);
		EndIf;
	EndDo;
	
	UnzipFileByName(FileRow.Name, FileRow.Directory);
	FilesUsed.Add(FileRow.FullName);
	
EndProcedure

// Reads an object from a file.
// 
// Parameters: 
//  File - ValueTableRow
// 
// Returns:
//  Arbitrary
Function ReadObjectFromFile(File) Export
	
	UnzipFile(File);
	Result = ExportImportData.ReadObjectFromFile(File.FullName);
	DeleteFiles(File.FullName);
	
	Return Result;
	
EndFunction

Function ThisIsContinuationOfDownload() Export
	
	ThisIsContinuationOfDownload = False;
	
	If Parameters.Property("ItIsPossibleToContinueLoadingProcedure") Then
		ThisIsContinuationOfDownload = Parameters.ItIsPossibleToContinueLoadingProcedure;
	EndIf;
	
	Return ThisIsContinuationOfDownload;
	
EndFunction

#EndRegion

#Region ExportImportState

Function FixState() Export
	Return FixState;	
EndFunction

Procedure SetNumberOfProcessedObjects(ProcessedObjectsCount1) Export
	StateRecording.ProcessedObjectsCount1 = ProcessedObjectsCount1;
	RefreshStatus(CurrentUniversalDate());
EndProcedure

Procedure SetStartDate(StartDate) Export
	StateRecording.StartDate = StartDate;
EndProcedure

Procedure AddTotalNumberOfObjects(Count) Export
	
	StateRecording.TotalObjectCount = StateRecording.TotalObjectCount + Count;
	
	CalculateObjectsByCompletionPercentage();
	
	AdditionDate = CurrentUniversalDate();
		
	RefreshStatus(AdditionDate);
	
	RecordState(AdditionDate);
	
EndProcedure

// Record the start of processing of the metadata object.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
Procedure RecordStartOfMetadataObjectProcessing(MetadataObject) Export
	
	ProcessingStartDate = CurrentUniversalDate();
	MetadataObjectForProcessingFullName = MetadataObject;
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("ProcessingStartDate", DateToString(ProcessingStartDate));
		MessageData.Insert("MetadataObject", MetadataObject);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ThisObject,
			"RecordStartOfMetadataObjectProcessing",
			MessageData);
		
	Else
	
		CommitMetadataObjectProcessingStartInParentThread(MetadataObject, ProcessingStartDate);
		
	EndIf;
	
EndProcedure

// Record the end of processing of the metadata object.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
Procedure CommitMetadataObjectProcessingEnd(MetadataObject) Export
	
	EndProcessingDate = CurrentUniversalDate();
	
	If IsChildThread() Then
		
		MessageData = New Structure();
		MessageData.Insert("EndProcessingDate", DateToString(EndProcessingDate));
		MessageData.Insert("MetadataObject", MetadataObject);
		MessageData.Insert("ProcessedObjectsCount1", ProcessedObjectsAfterCalculatingState);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ThisObject,
			"CommitMetadataObjectProcessingEnd",
			MessageData);
		
		ProcessedObjectsAfterCalculatingState = 0;
		
	Else
		
		CommitMetadataObjectProcessingEndInParentThread(
			MetadataObject,
			EndProcessingDate);
		
	EndIf;
	
EndProcedure

Function ObjectsToBeProcessedByMetadataObject(MetadataObject) Export
		
	NumberOfProcessedObjectsCountString = ProcessingObjectsCount.Find(
		MetadataObject.FullName(),
		"FullName");
		
	If NumberOfProcessedObjectsCountString = Undefined Then
		Return 0;
	EndIf;
	
	Return NumberOfProcessedObjectsCountString.NumberOfObjects;
	
EndFunction

Procedure ObjectProcessed() Export
	
	ObjectsAreProcessed(1);
	
EndProcedure

Procedure ObjectsAreProcessed(Count) Export
	
	ObjectProcessedDate = CurrentUniversalDate();
	
	If IsChildThread() Then
		
		ProcessedObjectsAfterCalculatingState = ProcessedObjectsAfterCalculatingState + Count;
		
		If ObjectProcessedDate < NextStateRecordMinimumDate Then
			Return;
		EndIf;
					
		MessageData = New Structure();
		MessageData.Insert("DateOfProcessing", DateToString(ObjectProcessedDate));
		MessageData.Insert("MetadataObject", MetadataObjectForProcessingFullName);
		MessageData.Insert("ProcessedObjectsCount1", ProcessedObjectsAfterCalculatingState);
		
		ExportImportDataInternal.SendMessageToParentThread(
			ThisObject,
			"ObjectsAreProcessed",
			MessageData);
		
		ProcessedObjectsAfterCalculatingState = 0;
		NextStateRecordMinimumDate = ObjectProcessedDate + 5;
		
	Else
			
		CommitObjectsProcessingInParentThread(
			MetadataObjectForProcessingFullName,
			ObjectProcessedDate,
			Count);
		 
	EndIf;
	
EndProcedure

Procedure RecordEndOfProcessingMetadataObjects() Export
	
	ProcessingEndDate = CurrentUniversalDate();
	
	AddObjectsProcessedAfterCalculatingState();		

	If ForUnloading Or Not ExportImportDataInternal.IsFullBackup(Parameters) Then 
		StateRecording.EndPercentage = 100;	
	EndIf;
	
	StateRecording.ProcessedObjectsUpToCurrentMetadataObject = Undefined;
	StateRecording.NameOfMetadataObjectBeingProcessed = Undefined;
	StateRecording.ObjectProcessingEndDate = ProcessingEndDate;
	
	RecordState(ProcessingEndDate);
	
EndProcedure

#EndRegion

#Region ParallelExportImport

Function GetInitialParametersInThread() Export
	
	ParametersProperties = New Array();
	ParametersProperties.Add("ThreadsCount");
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("ForUnloading", ForUnloading);
	InitializationParameters.Insert("ForImport", ForImport);
	InitializationParameters.Insert("TempDirectory", TempDirectory);
	InitializationParameters.Insert("ForTechnicalSupport", ForTechnicalSupport);
	InitializationParameters.Insert("FixState", FixState);
	InitializationParameters.Insert("ProcessingObjectsCount", ProcessingObjectsCount);
	InitializationParameters.Insert("ProcessID", ProcessID);
	InitializationParameters.Insert("ClientSessionNumber", ClientSessionNumber);
	InitializationParameters.Insert("Parameters", New Structure());
	
	If ForImport Then
		InitializationParameters.Insert("FileData", ImportFileData);
		InitializationParameters.Insert("Content", Content);
	EndIf;
	
	For Each PropertyName In ParametersProperties Do
		
		If Parameters.Property(PropertyName) Then
			InitializationParameters.Parameters.Insert(PropertyName, Parameters[PropertyName]);
		EndIf;
		
	EndDo;
	
	Return New FixedStructure(InitializationParameters);
	
EndFunction

// Process the stream message.
// 
// Parameters:
//  MethodName - String - Method name
//  MessageData - Structure - Message data
Procedure ProcessThreadMessage(MethodName, MessageData) Export
	
	If MethodName = "RecordStartOfMetadataObjectProcessing" Then
		
		CommitMetadataObjectProcessingStartInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.ProcessingStartDate));
			
	ElsIf MethodName = "CommitMetadataObjectProcessingEnd" Then
		
		CommitObjectsProcessing(
			MessageData.MetadataObject,
			MessageData.ProcessedObjectsCount1);
		CommitMetadataObjectProcessingEndInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.EndProcessingDate));
			
	ElsIf MethodName = "ObjectsAreProcessed" Then
		
		CommitObjectsProcessingInParentThread(
			MessageData.MetadataObject,
			Date(MessageData.DateOfProcessing),
			MessageData.ProcessedObjectsCount1);
		
	ElsIf MethodName = "FileRecorded" Then
		
		AddFileToArchive(MessageData.ArchiveDirectory);
		
		If MessageData.Property("ArbitraryFilesSize") Then
			
			ArbitraryFilesSize = ArbitraryFilesSize + MessageData.ArbitraryFilesSize;
			
		EndIf;
		
		If MessageData.Property("ArbitraryFilesCount") Then
			
			ArbitraryFilesCount = ArbitraryFilesCount + MessageData.ArbitraryFilesCount;
			
		EndIf;
		
	ElsIf MethodName = "ExportEnd" Then 
		
		For Each ElementComposition In MessageData.Content Do
			FillPropertyValues(Content.Add(), ElementComposition);
		EndDo;
		
		For Each ArrayElement In MessageData.FilesUsed Do
			FilesUsed.Add(ArrayElement);
		EndDo;
		
		For Each ArrayElement In MessageData.Warnings Do
			Warnings.Add(ArrayElement);
		EndDo;
		
		DuplicatesOfPredefinedFromThread = Common.ValueFromXMLString(MessageData.DuplicatesOfPredefinedItems);
		
		For Each MapItem In DuplicatesOfPredefinedFromThread Do
			DuplicatesOfPredefinedItems.Insert(MapItem.Key, MapItem.Value);
		EndDo;
		
	Else
		Raise StrTemplate(NStr("vi = 'Phương thức xử lý thông báo luồng không xác định: %1';
								|ru = 'Неизвестный метод обработки сообщения потока: %1';
								|en = 'Unknown thread message processing method: %1'; fa = 'Unknown thread message processing method: %1';
								|it = 'Неизвестный метод обработки сообщения потока: %1';
								|pl = 'Unknown thread message processing method: %1';
								|tr = 'Bilinmeyen iş parçacığı mesajını işleme yöntemi: %1'"), MethodName);
	EndIf;
	
EndProcedure

Function ProcessID() Export
	
	Return ProcessID;
	
EndFunction

Function IsChildThread() Export
	
	Return IsChildThread;
	
EndFunction

Function ThreadsCount() Export
	
	ThreadsCount = 0;
	
	If Parameters.Property("ThreadsCount") Then
		ThreadsCount = Parameters.ThreadsCount;
	EndIf;
	
	If Not ValueIsFilled(ThreadsCount) Or ThreadsCount < 1 Then
		ThreadsCount = 1;
	EndIf;
	
	Return ThreadsCount;
	
EndFunction

// The next message number in the stream.
// 
// Returns:
//  Number - The Next Message Number In The Stream
Function NextMessageNumberInStream() Export
	
	MessageNumberInStream = MessageNumberInStream + 1;
	
	Return MessageNumberInStream;
	
EndFunction

Function JobKind() Export
	
	If Parameters.Property("JobKind") And ValueIsFilled(Parameters.JobKind) Then
		Return Parameters.JobKind;
	ElsIf ForImport Then
		Return Enums.ExportImportDataJobTypes.OtherDataImport;
	Else
		Return Enums.ExportImportDataJobTypes.OtherDataExport;
	EndIf;
	
EndFunction

// The next stream number.
// 
// Returns:
//  Number - Next Stream Number
Function NextStreamNumber() Export
	
	ThreadNumber = ThreadNumber + 1;
	
	Return ThreadNumber;
	
EndFunction

#EndRegion

#Region Other

// Returns: 
//  Array of String
Function Warnings() Export
	
	Return Warnings;
	
EndFunction

// Returns:
//  ValueTable
Function Content() Export
	
	Return Content;
	
EndFunction

// Returns:
//  Array of String
Function FilesUsed() Export
	
	Return FilesUsed;
	
EndFunction

// Returns:
//  Map
Function DuplicatesOfPredefinedItems() Export
	
	Return DuplicatesOfPredefinedItems;
	
EndFunction

// Returns:
//  Boolean
Function ClientSessionExists() Export
	
	If Not ValueIsFilled(ClientSessionNumber) Then
		Return True;
	EndIf;
	
	For Each IBSession In GetInfoBaseSessions() Do
		
		If IBSession.SessionNumber = ClientSessionNumber Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Procedure AbortProcessOnAbsentClientSession() Export
	
	ExceptionText = StrTemplate(
		NStr("vi = '%1 dữ liệu bị gián đoạn, không có phiên làm việc client đang chờ quá trình hoàn tất.';
			|ru = '%1 данных прервана, отсутствует клиентский сеанс ожидающий окончания процесса.';
			|en = 'data %1 is interrupted, there is no client session waiting for the end of the process.'; fa = 'data %1 is interrupted, there is no client session waiting for the end of the process.';
			|it = 'data %1 is interrupted, there is no client session waiting for the end of the process.';
			|pl = 'data %1 is interrupted, there is no client session waiting for the end of the process.';
			|tr = '%1 verisi kesintiye uğradı, işlemin tamamlanmasını bekleyen istemci oturumu yoktur.'"),
		?(ThisIsDataExport(), NStr("vi = 'Kết xuất';
									|ru = 'Выгрузка';
									|en = 'Export'; fa = 'خروج اطلاعات';
									|it = 'Upload';
									|pl = 'Eksportowanie';
									|tr = 'Dışa aktarma'"), NStr("vi = 'Kết nhập';
															|ru = 'Загрузка';
															|en = 'Import'; fa = 'ورود اطلاعات';
															|it = 'Scaricamento';
															|pl = 'Pobieranie';
															|tr = 'İçe aktarma'")));
	
	Raise ExceptionText;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Parameters:
// 	FileID - UUID
// 	
// Returns:
// 	Structure:
// 	* FileID - UUID
// 	* Parts - Array of String
// 	* Sent - Number
// 	
Function NewMultipartUpload(FileID) 
	
	NewMultipartUpload = New Structure;
	NewMultipartUpload.Insert("FileID", FileID);
	NewMultipartUpload.Insert("Parts", New Array);
	NewMultipartUpload.Insert("Sent", 0);

	Return NewMultipartUpload;
	
EndFunction

Function GetFilesFromComposition(Val FileKind = Undefined, Val DataType = Undefined)
	
	Filter = New Structure;
	If FileKind <> Undefined Then
		Filter.Insert("FileKind", FileKind);
	EndIf;
	If DataType <> Undefined Then
		Filter.Insert("DataType", DataType);
	EndIf;
	
	Return Content.Copy(Filter);
	
EndFunction

Procedure CheckingContainerInitialization(Val DuringInitialization = False)
	
	If ForUnloading And ForImport Then
		Raise NStr("vi = 'Khởi tạo sai nơi chứa.';
					|ru = 'Некорректная инициализация контейнера.';
					|en = 'Incorrect container initialization.'; fa = 'Incorrect container initialization.';
					|it = 'Inizializzazione errata del contenitore.';
					|pl = 'Niepoprawna inicjalizacja kontenera.';
					|tr = 'Kapsayıcının hatalı başlatılması.'");
	EndIf;
	
	If DuringInitialization Then
		
		If ContainerInitialized <> Undefined And ContainerInitialized Then
			Raise NStr("vi = 'Đã khởi tạo từ trước nơi chứa kết xuất.';
						|ru = 'Контейнер выгрузки уже был инициализирован ранее.';
						|en = 'Export container has been initialized.'; fa = 'Export container has been initialized.';
						|it = 'Il contenitore di upload è stato già precedentemente inizializzato.';
						|pl = 'Kontener przesyłania został już zainicjowany.';
						|tr = 'Dışa aktarma kapsayıcı zaten daha önce başlatıldı.'");
		EndIf;
		
	Else
		
		If Not ContainerInitialized Then
			Raise NStr("vi = 'Chưa khởi tạo nơi chứa kết xuất.';
						|ru = 'Контейнер выгрузки не инициализирован.';
						|en = 'Export container is not initialized.'; fa = 'Export container is not initialized.';
						|it = 'Il contenitore di upload non è stato inizializzato.';
						|pl = 'Kontener przesyłania nie został zainicjowany.';
						|tr = 'Dışa aktarma kapsayıcı başlatılmadı.'");
		EndIf;
		
	EndIf;
	
EndProcedure

#Region ContainerFilesOperations

// Parameters: 
//  FileKind - String - File type
//  Extension - String - Extension
//  DataType - Undefined, String - Data type
// 
// Returns: 
//  String - full file name.
//
Function AppendFile(Val FileKind, Val Extension = "xml", Val DataType = Undefined)
	
	For ReverseIndex = 1 - FilesUsed.Count() To 0 Do
		FullFileName = FilesUsed[-ReverseIndex];
		File = New File(FullFileName);
		If File.Exists() And FileIsWritable(FullFileName) Then
			FileRecorded(FullFileName);
		EndIf;
	EndDo;
	
	FileName = GetFileName(FileKind, Extension);
	
	Directory = "";
	
	If FileKind = ExportImportDataInternal.Digest()
		Or FileKind = ExportImportDataInternal.Extensions() 
		Or FileKind = ExportImportDataInternal.CustomExtensions()
		Or FileKind = ExportImportDataInternal.DumpWarnings()
		Or FileKind = ExportImportDataInternal.PredefinedDataDuplicates()
		Or FileKind = ExportImportDataInternal.ApplicationTypes() Then
		
		FileKind = "CustomData";
		
	EndIf;
	
	If Not ExportImportDataInternal.RulesForCreatingDirectoryStructure().Property(FileKind, Directory) Then
		Raise StrTemplate(NStr("vi = 'Không hỗ trợ dạng tệp %1.';
								|ru = 'Вид файла %1 не поддерживается.';
								|en = 'The %1 file type is not supported.'; fa = 'The %1 file type is not supported.';
								|it = 'Tipo di file %1 non supportato.';
								|pl = 'Rodzaj pliku %1 nie jest obsługiwany.';
								|tr = '%1 dosya türü desteklenmiyor.'"), FileKind);
	EndIf;
	
	If IsBlankString(Directory) Then
		FullName = TempDirectory + FileName;
	Else
			
		FilesCount = 0;
		If Not NumberOfFilesByType.Property(FileKind, FilesCount) Then
			FilesCount = 0;
		EndIf;
		FilesCount = FilesCount + 1;
		NumberOfFilesByType.Insert(FileKind, FilesCount);
		
		MaximumNumberOfFilesInDirectory = 1000;
		
		DirectoryNumber = Int((FilesCount - 1) / MaximumNumberOfFilesInDirectory) + 1;
		Directory = Directory + ?(DirectoryNumber = 1, "", Format(DirectoryNumber, "NG=0"));
		
		If FilesCount % MaximumNumberOfFilesInDirectory = 1 Then
			CreateDirectory(TempDirectory + Directory);
		EndIf;
		
		FullName = TempDirectory + Directory + GetPathSeparator() + FileName;
		
	EndIf;
	
	If DataType <> Undefined Then

		File = Content.Add();
		File.Name = FileName;
		File.Directory = Directory;
		File.FullName = FullName;
		File.DataType = DataType;
		File.FileKind = FileKind;

	EndIf;
	
	FilesUsed.Add(FullName);
	
	Return FullName;
	
EndFunction

Procedure AddFileToArchive(ArchiveDirectory)
	
	ZIPArchives.AppendFile(Archive, ArchiveDirectory);
	DeleteFiles(ArchiveDirectory);
	
	If UploadTo And ZIPArchives.Size(Archive) > 1024 * 1024 * 1024 Then
		
		TimeFile = GetTempFileName();
		ZIPArchives.SeparatePart(Archive, TimeFile);
		
		If MultipartUpload = Undefined Then
			Result = ServiceProgrammingInterface.StartMultipartUpload(
				ExportImportDataClientServer.NameOfDataUploadFile(), 0, 
				"DataAreaBackup", SaaSOperations.SessionSeparatorValue());
			MultipartUpload = NewMultipartUpload(Result.FileID);
		Else
			Result = ServiceProgrammingInterface.NewPart(MultipartUpload.FileID, 
				MultipartUpload.Parts.Count() + 1);
		EndIf;
		
		If Result.Type = "s3" Then
			SendPartOfS3File(Result, TimeFile);
		Else
			SendPartOfDTFile(Result, TimeFile, False);
		EndIf;
		
		DeleteFiles(TimeFile);
		
	ElsIf ExportToClient And ZIPArchives.Size(Archive) > 10 * 1024 * 1024 Then 
		
		PartsExportedToClient = PartsExportedToClient + 1;
		Prefix = StrTemplate("data2xml-%1", Format(PartsExportedToClient, "NG=0"));
		TemporaryStorageFileName = FilesCTL.NewTemporaryStorageFile(Prefix, "zip", 120);
		UploadFileName = FilesCTL.FullTemporaryStorageFileName(TemporaryStorageFileName);
		ZIPArchives.SeparatePart(Archive, UploadFileName);
		RegisterExportPart(PartsExportedToClient, TemporaryStorageFileName);
		ExpectPartsDownloading();
		
	EndIf;
	
EndProcedure 

Procedure RegisterExportPart(PartNumber, TemporaryStorageFileName)
	
	Record = InformationRegisters.ExportImportDataAreasParts.CreateRecordManager();
	Record.Id = StateRecording.Id;
	Record.PartNumber = PartNumber;
	Record.TemporaryStorageFileName = TemporaryStorageFileName;
	Record.Write();
	
EndProcedure

Procedure ExpectPartsDownloading()
	
	Query = New Query();
	Query.SetParameter("Id", StateRecording.Id);
	
	Query.Text =
	"SELECT
	|	COUNT(*) AS Count
	|FROM
	|	InformationRegister.ExportImportDataAreasParts AS ExportImportDataAreasParts
	|WHERE
	|	ExportImportDataAreasParts.Id = &Id";
	
	While True Do
		
		Selection = Query.Execute().Select();
		
		If Not Selection.Next() Or Selection.Count < 3 Then
			Return;
		EndIf;
		
		If Not ClientSessionExists() Then
			AbortProcessOnAbsentClientSession();
		EndIf;
		
		CommonCTL.Pause(5);
		
	EndDo;
	
EndProcedure

Function FileIsWritable(FileName)
	
	Try
		DataWriter = New DataWriter(FileName);
		DataWriter.Close();
		Return True;
	Except
		Return False;
	EndTry;
	
EndFunction

Function GetFileName(Val FileKind, Val Extension = "xml")
	
	Return ExportImportDataInternal.GetFileName(FileKind, Extension);
	
EndFunction

#EndRegion

#Region ContainerContentsDescriptionOperations

Procedure WriteContainerContentsToFile(FileName)
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Data");
	
	FileType_ = XDTOFactory.Type("http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1", "File");
	For Each String In Content Do
		
		FileInformation = XDTOFactory.Create(FileType_);
		
		FileInformation.Name = String.Name;
		FileInformation.Type = String.FileKind;
		If ValueIsFilled(String.Directory) Then
			FileInformation.Directory = String.Directory;
		EndIf;
		If ValueIsFilled(String.Size) Then
			FileInformation.Size = String.Size;
		EndIf;
		If ValueIsFilled(String.NumberOfObjects) Then
			FileInformation.Count = String.NumberOfObjects;
		EndIf;
		If ValueIsFilled(String.DataType) Then
			FileInformation.DataType = String.DataType;
		EndIf;
		
		XDTOFactory.WriteXML(WriteStream, FileInformation);
		
	EndDo;
	
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
EndProcedure

Procedure RecordDigest(FileName)
	
	ConfigurationInformation = New SystemInfo();
	
	NumberOfObjects = Content.Total("NumberOfObjects") + ArbitraryFilesCount;
	DataSize  = Content.Total("Size") + ArbitraryFilesSize;
	
	DurationOfUnloading = CurrentSessionDate() - UploadStartTime;
	
	WriteStream = New XMLWriter();
	WriteStream.OpenFile(FileName);
	WriteStream.WriteXMLDeclaration();
	WriteStream.WriteStartElement("Digest");
	
	WriteStream.WriteStartElement("Platform");
	WriteStream.WriteText(ConfigurationInformation.AppVersion);
	WriteStream.WriteEndElement(); 
	
	If SaaSOperations.DataSeparationEnabled() Then
		WriteStream.WriteStartElement("Zone");
		WriteStream.WriteText(XMLString(SaaSOperations.SessionSeparatorValue()));
		WriteStream.WriteEndElement();
	EndIf; 
	
	WriteStream.WriteStartElement("ObjectCount");
	WriteStream.WriteText(Format(NumberOfObjects, "NG=0"));
	WriteStream.WriteEndElement();

	WriteStream.WriteStartElement("DataSize");
	WriteStream.WriteAttribute("Measure", "Byte");
	WriteStream.WriteText(Format(DataSize, "NFD=1; NG=0"));
	WriteStream.WriteEndElement();
	
	WriteStream.WriteStartElement("Duration");
	WriteStream.WriteAttribute("Measure", "Second");
	WriteStream.WriteText(Format(DurationOfUnloading, "NG=0"));
	WriteStream.WriteEndElement();
	
	If DurationOfUnloading <>0 Then
		WriteStream.WriteStartElement("SerializationSpeed");
		WriteStream.WriteAttribute("Measure", "Byte/Second");
		WriteStream.WriteText(Format(DataSize / DurationOfUnloading, "NFD=1; NG=0"));
		WriteStream.WriteEndElement();
	EndIf;
	
	If ForTechnicalSupport Then
		ExportType = "TechnicalSupport"
	Else                                  
		ExportType = "Ordinary"	
	EndIf;
	
	WriteStream.WriteStartElement("DataDumpType");	
	WriteStream.WriteText(ExportType); 
	WriteStream.WriteEndElement(); 
	
	WriteStream.WriteStartElement("DumpWarningsCount");
	WriteStream.WriteText(Format(Warnings.Count(), "NZ=0; NG=0;"));
	WriteStream.WriteEndElement();
	
	WriteStream.WriteStartElement("ContainsRegisteredChangesForExchangePlanNodes");
	WriteStream.WriteText(XMLString(ExportImportExchangePlansNodes.UploadRegisteredChangesForExchangePlanNodes(ThisObject)));
	WriteStream.WriteEndElement();
		
	WriteStream.WriteEndElement();
	WriteStream.Close();
	
EndProcedure

Procedure RecordUploadWarnings()
	
	NameOfUploadWarningsFile = AppendFile(ExportImportDataInternal.DumpWarnings(), "json",
		"CustomData");
	
	RecordingWarnings = New JSONWriter;
	RecordingWarnings.OpenFile(NameOfUploadWarningsFile);
	WriteJSON(RecordingWarnings, Warnings);
	RecordingWarnings.Close();
	
	FileRecorded(NameOfUploadWarningsFile);
	
EndProcedure

Procedure RecordInformationAboutExtensions()

	FileNameOfSuppliedExtensions = CreateFile(ExportImportDataInternal.Extensions(), ExportImportDataInternal.CustomData());
	RecordingSuppliedExtensions = New XMLWriter;
	RecordingSuppliedExtensions.OpenFile(FileNameOfSuppliedExtensions);
	RecordingSuppliedExtensions.WriteXMLDeclaration();
	RecordingSuppliedExtensions.WriteStartElement("Data");

	InformationAboutCustomExtensions = New Array;
	DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();

	If DataSeparationEnabled Then
		SuppliedExtensions = ExtensionsSaaS.CurDataAreaExtensions();
	EndIf;
	
	NamesOfInstalledFixes = NamesOfInstalledFixes();
	AppTypesExtensionNames = AppTypesExtensionNames();
	PlusExtensions = InstalledPlusExtensions();
	
	AllAreaExtensionsList = New Array;
	For Each ConfigurationExtension In ConfigurationExtensions.Get() Do
		
		If DataSeparationEnabled
			And ConfigurationExtension.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		
		ModifiesDataStructure = ConfigurationExtension.ModifiesDataStructure();
		If ModifiesDataStructure And Not ConfigurationExtension.Active Then
			Continue;
		EndIf;
		
		AllAreaExtensionsList.Add(ConfigurationExtension.Name);
		
	EndDo;
	
	ActiveExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
	For Each ConfigurationExtension In ActiveExtensions Do

		If DataSeparationEnabled Then
		
			If ConfigurationExtension.Scope <> ConfigurationExtensionScope.DataSeparation  Then
				Continue;
			EndIf;
			
			RecordingSuppliedExtension = SuppliedExtensions.Find(ConfigurationExtension.UUID,
				"ExtensionToUse");
		
		Else
			RecordingSuppliedExtension = ExtensionsFrameVersions.Get(
				ConfigurationExtension.UUID);
		EndIf;
		
		ModifiesDataStructure = ConfigurationExtension.ModifiesDataStructure();
		
		If (ModifiesDataStructure And Not ConfigurationExtension.Active)
			Or AllAreaExtensionsList.Find(ConfigurationExtension.Name) = Undefined Then
			Continue;
		EndIf;
		
		If DataOfSuppliedExtensionIsSufficientForBackup(RecordingSuppliedExtension) Then

			ExtensionName = ?(ValueIsFilled(RecordingSuppliedExtension.Description),
				RecordingSuppliedExtension.Description,
				ConfigurationExtension.Synonym);
			
			RecordingSuppliedExtensions.WriteStartElement("Extension");
			RecordingSuppliedExtensions.WriteAttribute("ModifiesDataStructure", Format(ModifiesDataStructure,
				"BF=false; BT=true"));
			RecordingSuppliedExtensions.WriteAttribute("Name", ExtensionName);
			RecordingSuppliedExtensions.WriteAttribute("VersionUUID", String(
				RecordingSuppliedExtension.VersionID));
			
			If ModifiesDataStructure Then
				
				FrameData = GetFrameworkForExtensionVersion(RecordingSuppliedExtension.VersionID);
				If FrameData = Undefined Then
					If ExtensionsFrameVersions[ConfigurationExtension.UUID] <> Undefined Then
						FrameData = ConfigurationExtension.GetData();
						AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData);
					Else
						WriteLogEvent(NStr("vi = 'Kết xuất dữ liệu. Không tìm thấy phiên bản khung của phần mở rộng';
											|ru = 'Выгрузка данных. Не найдена каркасная версия расширения';
											|en = 'Data export. Extension framework version is not found'; fa = 'Data export. Extension framework version is not found';
											|it = 'Upload dati. Non è stata trovata la versione cornice della versione dell''estensione';
											|pl = 'Eksport danych. Nie znaleziono wersji szkieletowej rozszerzenia';
											|tr = 'Veri dışa aktarımı. Uzantının çerçeve sürümü bulunamadı'", 
							Common.DefaultLanguageCode()), 
							EventLogLevel.Warning, , ,
							StrTemplate(NStr("vi = 'Tên phần mở rộng: %1, Tên định danh của phiên bản: %2';
											|ru = 'Имя расширения: %1, Идентификатор версии: %2';
											|en = 'Extension name: %1. Version ID: %2'; fa = 'Extension name: %1. Version ID: %2';
											|it = 'Nome estensione:%1, ID versione: %2';
											|pl = 'Nazwa rozszerzenia: %1, Identyfikator wersji: %2';
											|tr = 'Uzantı ismi: %1, Kimlik sürümü: %2'"), 
								ExtensionName,
								String(RecordingSuppliedExtension.VersionID)));
					EndIf;
				Else
					AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData);
				EndIf;
				
			EndIf;
			
			RecordingSuppliedExtensions.WriteEndElement();

		Else
		
			If NamesOfInstalledFixes.Find(ConfigurationExtension.Name) <> Undefined 
				Or AppTypesExtensionNames.Find(ConfigurationExtension.Name) <> Undefined Then
				
				Continue;
			EndIf;
			
			UserExtensionInformation = New Structure;
			UserExtensionInformation.Insert("Active", ConfigurationExtension.Active);
			UserExtensionInformation.Insert("SafeMode", ConfigurationExtension.SafeMode);
			UserExtensionInformation.Insert("UnsafeOperationWarnings",
				ConfigurationExtension.UnsafeActionProtection.UnsafeOperationWarnings);
			UserExtensionInformation.Insert("Name", ConfigurationExtension.Name);
			UserExtensionInformation.Insert("UseDefaultRolesForAllUsers", 
				ConfigurationExtension.UseDefaultRolesForAllUsers);
			UserExtensionInformation.Insert("UsedInDistributedInfoBase", 
				ConfigurationExtension.UsedInDistributedInfoBase);
			UserExtensionInformation.Insert("Synonym", ConfigurationExtension.Synonym);
			UserExtensionInformation.Insert("ModifiesDataStructure", ModifiesDataStructure);
			
			PlusExtensionData = PlusExtensions.Get(ConfigurationExtension.UUID);
			
			If UploadExtensionData And PlusExtensionData = Undefined Then
				NameOfUserExtensionDataFile = CreateCustomFile("cfe", "ExtensionData");
				
				WriteExtensionToFile(ConfigurationExtension, NameOfUserExtensionDataFile);			
				UserExtensionInformation.Insert("FileName", GetRelativeFileName(
					NameOfUserExtensionDataFile));
			EndIf;
			
			UserExtensionInformation.Insert("UUID", XMLString(ConfigurationExtension.UUID));
			
			UserExtensionInformation.Insert("PlusExtVersionId", "");
			UserExtensionInformation.Insert("PlusExtId", "");
			UserExtensionInformation.Insert("Version", ConfigurationExtension.Version);
			
			If PlusExtensionData <> Undefined Then
				If ExportDataFromPlusExtensions Then
					NameOfUserExtensionDataFile = CreateCustomFile("cfe", "ExtensionData");
					WriteExtensionToFile(
						ConfigurationExtension, 
						NameOfUserExtensionDataFile);
					NameOfUserExtensionDataFile = 
						GetRelativeFileName(NameOfUserExtensionDataFile)
				Else
					NameOfUserExtensionDataFile = PlusExtensionData.Extension_VersionId + ".cfe";
				EndIf;
				
				UserExtensionInformation.PlusExtVersionId = PlusExtensionData.Extension_VersionId;
				UserExtensionInformation.PlusExtId = PlusExtensionData.Extension_Id;
				UserExtensionInformation.Insert("FileName", NameOfUserExtensionDataFile);
				UserExtensionInformation.Insert("FileSaved", ExportDataFromPlusExtensions);
				
				If PlusExtensionData.Property("InstallationJob") Then
					UserExtensionInformation.Insert(
						"InstallTask", PlusExtensionData.InstallationJob.Get());					
				EndIf;
				
			EndIf;
				
			InformationAboutCustomExtensions.Add(UserExtensionInformation);

		EndIf;
	EndDo;

	RecordingSuppliedExtensions.WriteEndElement();
	RecordingSuppliedExtensions.Close();
	FileRecorded(FileNameOfSuppliedExtensions);

	FileNameOfCustomExtensions = AppendFile(ExportImportDataInternal.CustomExtensions(), "json",
		"CustomData");
	WritingCustomExtensions = New JSONWriter;
	WritingCustomExtensions.OpenFile(FileNameOfCustomExtensions);
	WriteJSON(WritingCustomExtensions, InformationAboutCustomExtensions);
	WritingCustomExtensions.Close();
	FileRecorded(FileNameOfCustomExtensions);

EndProcedure

Procedure WriteExtensionToFile(ConfigurationExtension, NameOfUserExtensionDataFile)
	ExtensionData = ConfigurationExtension.GetData();
	If ExtensionData = Undefined Then
		Raise StrTemplate(NStr("vi = 'Không thể nhận dữ liệu phần mở rộng: %1
			|Cần xóa phần mở rộng này và thử lại kết xuất.';
			|ru = 'Не удалось получить данные расширения: %1
			|Необходимо удалить данное расширение и повторить выгрузку.';
			|en = 'Cannot receive the extension data: %1
			|Delete the extension and try to export again.'; fa = 'Cannot receive the extension data: %1
			|Delete the extension and try to export again.';
			|it = 'Не удалось получить данные расширения: %1
			|Необходимо удалить данное расширение и повторить выгрузку.';
			|pl = 'Cannot receive the extension data: %1
			|Delete the extension and try to export again.';
			|tr = 'Uzantı verileri alınamadı: %1
			|Bu uzantıyı kaldırmanız ve tekrar yüklemeyi denemeniz gerekiyor.'"),
		ConfigurationExtension.Name);
	Else
		ExtensionData.Write(NameOfUserExtensionDataFile);
	EndIf;
	
	FileRecorded(NameOfUserExtensionDataFile);
EndProcedure

Function InstalledPlusExtensions()
	SetPrivilegedMode(True);
	Result = New Map();
	
	If PlusExtensionsAgent.Count() <> 0 Then
		For Each KeyValue In PlusExtensionsAgent Do
			Result.Insert(KeyValue.Key, 
				New Structure("Extension_Id, Extension_VersionId", 
					KeyValue.Value.ExtId, KeyValue.Value.ExtVersionId));
		EndDo;
		
		Return Result;
	EndIf;
	
	ExportImportDataInternal.FillInInstalledPlusExtensions(Result);
	
	Return Result;
EndFunction

Procedure AddInformationAboutFrames(RecordingSuppliedExtensions, FrameData)	
	FrameDataFileName = CreateCustomFile("cfe", "ExtensionData");
	FrameData.Write(FrameDataFileName);
	RecordingSuppliedExtensions.WriteAttribute("FileName", GetRelativeFileName(FrameDataFileName));
	RecordingSuppliedExtensions.WriteAttribute("IsFrame", Format(True, "BF=false; BT=true"));
EndProcedure

Procedure RecordAppTypeInformation()
	
	AppTypes = New Structure;
	AppTypes.Insert("AppTypes", New Array);
	
	IndexOf = 0;
	AppTypeNameCustom = AppTypesServer.CurrentCustomAppTypeName();
	If Not IsBlankString(AppTypeNameCustom) Then
		AppTypeData = New Structure;
		AppTypeData.Insert("Name", AppTypeNameCustom);
		AppTypeData.Insert("Presentation", AppTypesServer.CurrentAppTypePresentation());
		
		AppTypes.AppTypes.Insert(IndexOf, AppTypeData);
		AppTypes.Insert("CustomAppTypeIndex", IndexOf);
		
		IndexOf = IndexOf + 1;
	EndIf;
	
	AppTypeProperties = AppTypesServer.AppTypePropertiesByName(
		AppTypesServer.CurrentAppTypeName());
	
	AppTypeData = New Structure;
	AppTypeData.Insert("Name", AppTypeProperties.Name);
	AppTypeData.Insert("Presentation", AppTypeProperties.Presentation);
	
	AppTypes.AppTypes.Insert(IndexOf, AppTypeData);
	AppTypes.Insert("AppTypeIndex", IndexOf);
	
	FileName = AppendFile(ExportImportDataInternal.ApplicationTypes(), "json", "CustomData");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, AppTypes);
	JSONWriter.Close();
	
	FileRecorded(FileName);
	
EndProcedure

#EndRegion

Function GetFrameworkForExtensionVersion(VersionID)
	
	LinkExtensionVersion = Catalogs.BuiltInExtensionVersions.GetRef(VersionID);
	If Common.RefExists(LinkExtensionVersion) Then
		
		Return LinkExtensionVersion.ExtensionFrameworkStorage.Get();
				
	EndIf;
	
	Return Undefined;
		
EndFunction

Function DataOfSuppliedExtensionIsSufficientForBackup(RecordingSuppliedExtension)

	Result = False;
	BlankID = CommonClientServer.BlankUUID();
	If ValueIsFilled(RecordingSuppliedExtension)
		And RecordingSuppliedExtension.VersionID <> BlankID Then
	
		Result = True;
	
	EndIf;
	
	Return Result;

EndFunction

Function NamesOfInstalledFixes()

	Result = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then 
		
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");		
		InstalledPatches = ModuleConfigurationUpdate.InstalledPatches();
		
		For Each Patch In InstalledPatches Do
			Result.Add(Patch.Description);	
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function AppTypesExtensionNames()
	
	Result = New Array;
	
	If Common.SubsystemExists("CloudTechnology.AppTypes") Then 
		ModuleAppTypes = Common.CommonModule("AppTypesServer");
		ModuleAppTypes.AppTypesExtensionNames(Result);
	EndIf;
	
	Return Result;
	
EndFunction

Function GetDescriptionsOfArbitraryFiles(Val DataType = Undefined)
	
	CheckingContainerInitialization();
	
	Return GetFilesFromComposition(ExportImportDataInternal.CustomData(), DataType);
	
EndFunction

Procedure AddFilesToValueTable(TableWithFiles, Val FilesFromComposition)
	
	If TableWithFiles = Undefined Then 
		TableWithFiles = FilesFromComposition;
		Return;
	EndIf;
	
	CommonClientServer.SupplementTable(FilesFromComposition, TableWithFiles);
	
EndProcedure

Procedure UnzipFileByName(Val Name, Val Path = "")
	
	ExportImportDataInternal.UnzipArchiveFile(
		Archive,
		TempDirectory,
		Name,
		Path);
	
EndProcedure

Procedure SendPartOfS3File(Result, FileName)
	
	URIStructure = CommonClientServer.URIStructure(Result.Address);
	If URIStructure.Schema = "https" Then
		SecureConnection = CommonClientServer.NewSecureConnection( , New OSCertificationAuthorityCertificates);
	EndIf;
	Join = New HTTPConnection(URIStructure.Host, URIStructure.Port, , , GetFilesFromInternet.GetProxy(URIStructure.Schema), 600, SecureConnection);
	Query = New HTTPRequest(URIStructure.PathAtServer, Result.Headers);
	Query.SetBodyFileName(FileName);
	Response = Join.CallHTTPMethod("PUT", Query);
	If Response.StatusCode <> 200 Then
		ServiceProgrammingInterface.CancelMultipartUpload(MultipartUpload.FileID);
		Raise StrTemplate(NStr("vi = 'Không gửi được một phần của tệp, mã phản hồi: %1%2%3';
								|ru = 'Не удалось отправить часть файла, код ответа: %1%2%3';
								|en = 'Cannot send the file part. Response code: %1%2%3'; fa = 'Cannot send the file part. Response code: %1%2%3';
								|it = 'Impossibile inviare una parte del file, codice di risposta: %1%2%3';
								|pl = 'Nie udało się wysłać części pliku, kod odpowiedzi: %1%2%3';
								|tr = 'Dosyanın bir kısmı gönderilemedi, cevap kodu: %1%2%3'"), 
			Response.StatusCode, Chars.LF, Response.GetBodyAsString());
	EndIf;
	MultipartUpload.Parts.Add(CommonCTLClientServer.HTTPHeader(Response, "ETag"));
			
EndProcedure

Procedure SendPartOfDTFile(Result, FileName, LastPart)
	
	SetPrivilegedMode(True);
	AccessParameters = New Structure;
	AccessParameters.Insert("URL", SaaSOperations.InternalServiceManagerURL());
	AccessParameters.Insert("UserName", SaaSOperations.ServiceManagerInternalUserName());
	AccessParameters.Insert("Password", SaaSOperations.ServiceManagerInternalUserPassword());
	SetPrivilegedMode(False);
	
	SendOptions = New Structure;
	SendOptions.Insert("Location", Result.Address);
	SendOptions.Insert("SetCookie", CommonCTLClientServer.HTTPHeader(Result, "SetCookie"));
	
	Result = DataTransferServer.SendPartOfFileToLogicalStorage(AccessParameters, SendOptions, FileName, LastPart, MultipartUpload.Sent);
	If Result = Undefined Then
		Raise NStr("vi = 'Không gửi được một phần của tệp';
					|ru = 'Не удалось отправить часть файла';
					|en = 'Cannot send the file part'; fa = 'Cannot send the file part';
					|it = 'Impossibile inviare una parte del file';
					|pl = 'Nie udało się wysłać części pliku';
					|tr = 'Dosyanın bir kısmı gönderilemedi'");		
	EndIf;
	
	If Not LastPart Then
		MultipartUpload.Sent = Result;
	EndIf;		
	
EndProcedure

// Searches for a string from the end, because it is faster when the rows are > 100k
Function FindCompositionLine(Value, Column)
	
	For ReverseIndex = 1 - Content.Count() To Min(4 - Content.Count(), 0) Do
		If Content[-ReverseIndex][Column] = Value Then
			Return Content[-ReverseIndex];
		EndIf;
	EndDo;
	
	Return Content.Find(Value, Column);
	
EndFunction

Procedure AddWarning(Warning) Export
	
	Warnings.Add(Warning);
	
EndProcedure

Procedure AddDuplicatesOfPredefined(MetadataObject, Duplicates) Export
	
	DuplicatesOfPredefinedItems.Insert(MetadataObject.FullName(), Duplicates);
	
EndProcedure

Procedure RecordDuplicatesOfPredefined()
	
	If DuplicatesOfPredefinedItems.Count() = 0 Then
		Return;
	EndIf;
	
	FileName = AppendFile(ExportImportDataInternal.PredefinedDataDuplicates(), "json", "CustomData");
	
	JSONWriter = New JSONWriter;
	JSONWriter.OpenFile(FileName);
	WriteJSON(JSONWriter, DuplicatesOfPredefinedItems);
	JSONWriter.Close();
	
	FileRecorded(FileName);
	
EndProcedure

Procedure InitializeImportVariables(FileData)
	
	Archive = ExportImportDataInternal.ReadArchive(FileData);
	Warnings = New Array();

EndProcedure

Procedure InitializeExportVariables()
	
	Content = ExportImportDataInternal.NewContent();
	Content.Columns.Add("FullName", New TypeDescription("String"));
	
	ArbitraryFilesCount = 0;
	ArbitraryFilesSize = 0;
	
	Warnings = New Array();
	DuplicatesOfPredefinedItems = New Map();
	
EndProcedure

Procedure InitializeAdditionalUploadProperties()
	
	AdditionalProperties.Insert(
		"GeneralDataRequiringLinkMatching",
		ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading());
	
	AdditionalProperties.Insert(
		"LocalCacheOfDelimiterCompositions",
		New Map());
	
EndProcedure

Function DateToString(Date)
	
	Return Format(Date, "DF=yyyyMMddHHmmss;");
	
EndFunction

#Region ExportImportState

Procedure RefreshStatus(UpdateDate)
	
	AddObjectsProcessedAfterCalculatingState();
	
	TotalObjectCount = StateRecording.TotalObjectCount;
	ProcessedObjectsCount1 = StateRecording.ProcessedObjectsCount1;
	
	If TotalObjectCount = 0 Or ProcessedObjectsCount1 <= ObjectsAtCompletionPercentage  Then
		Return;
	EndIf;
	
	StateRecording.EndPercentage = Min(Int(ProcessedObjectsCount1 / TotalObjectCount * 100), 100); 	
	
	If ProcessedObjectsCount1 >= TotalObjectCount Or ObjectsProcessedDuringCurrentSession <= ObjectsAtCompletionPercentage Then
		Return;
	EndIf;
	
	SecondsSinceStartOfObjectProcessing = UpdateDate - StateRecording.ObjectProcessingStartedDate;
	ProcessObjectsRemaining = TotalObjectCount - ObjectsProcessedDuringCurrentSession;
	ProcessObjectsTimeLeft = Int(
		SecondsSinceStartOfObjectProcessing * ProcessObjectsRemaining / ObjectsProcessedDuringCurrentSession);
	StateRecording.EstimatedEndDate = UpdateDate + Max(ProcessObjectsTimeLeft, 5);
			
EndProcedure

Procedure RecordState(UpdateDate)
	
	StateRecording.UpdateDate = UpdateDate;
	StateRecording.Write();

EndProcedure

Procedure SaveEndState()
	CompletedOn = CurrentUniversalDate();
	StateRecording.ActualEndDate = CompletedOn;
	RecordState(CompletedOn);	
EndProcedure

Procedure CalculateObjectsByCompletionPercentage()
	ObjectsAtCompletionPercentage = Int(StateRecording.TotalObjectCount / 100);		
EndProcedure

Procedure AddObjectsProcessedAfterCalculatingState()
	StateRecording.ProcessedObjectsCount1 = StateRecording.ProcessedObjectsCount1 + ProcessedObjectsAfterCalculatingState;
	ObjectsProcessedDuringCurrentSession = ObjectsProcessedDuringCurrentSession + ProcessedObjectsAfterCalculatingState;
	ProcessedObjectsAfterCalculatingState = 0;
EndProcedure

Procedure SetCountOfProcessedObjects()
	
	If Not ExportImportData.NeedToCountObjectsNumber(Parameters) Then
		Return;
	EndIf;
	
	If ForImport Then
		
		ProcessingObjectsCount = ExportImportDataInternal.NumberOfImportObjectsByMetadataObjects(
			Content,
			Parameters.LoadableTypes,
			ForTechnicalSupport);
		
	Else
		
		ProcessingObjectsCount = ExportImportDataInternal.ImportObjectsdByMetadataObjectsCount(
			Parameters.TypesToExport,
			Parameters.UnloadedTypesOfSharedData,
			ForTechnicalSupport);
		
	EndIf;
	
	ProcessingObjectsCount.Indexes.Add("FullName");

EndProcedure

Procedure InitializeState()
	
	FixState = ExportImportData.ItIsNecessaryToRecordExportImportDataAreaState(
		Parameters); 

	If Not FixState Then
		Return;
	EndIf;
	
	InitializeStateVariables();
	
	TotalObjectCount = Undefined;
	
	If Not Parameters.Property("TotalObjectCount", TotalObjectCount) Then
		TotalObjectCount = ProcessingObjectsCount.Total("NumberOfObjects");
	EndIf;
		
	StateRecording = InformationRegisters.ExportImportDataAreasStates.CreateRecordManager();
	StateRecording.Id = Parameters.StateID;
	StateRecording.importDataArea = ForImport;
	StateRecording.StartDate = CurrentUniversalDate();
	StateRecording.TotalObjectCount = TotalObjectCount;
	
	CalculateObjectsByCompletionPercentage();
	
EndProcedure

Procedure InitializeStateVariables()
	
	NextStateRecordMinimumDate = Date(1, 1, 1);
	ProcessedObjectsAfterCalculatingState = 0;
	ObjectsProcessedDuringCurrentSession = 0;
	MetadataObjectForProcessingFullName = "";
	ProcessedObjectsByMetadata = New Map();
	
EndProcedure

// Record the start of processing of the metadata object in the parent stream.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
//  ProcessingStartDate - Date - Start Date Of Processing
Procedure CommitMetadataObjectProcessingStartInParentThread(MetadataObject, ProcessingStartDate)
	
	ProcessedObjectsCountByMetadata(MetadataObject);
	
	If Not ValueIsFilled(StateRecording.ObjectProcessingStartedDate) Then
		StateRecording.ObjectProcessingStartedDate = ProcessingStartDate;
	EndIf;
	
	StateRecording.NameOfMetadataObjectBeingProcessed = GetMetadataObjectNameForProcessing(MetadataObject);
	
	RecordState(ProcessingStartDate);
	
EndProcedure

// To record the completion of processing of the metadata object in the parent stream.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
//  EndProcessingDate - Date - End Date Of Processing
Procedure CommitMetadataObjectProcessingEndInParentThread(MetadataObject, EndProcessingDate)
	
	AddObjectsProcessedAfterCalculatingState();
	
	ProcessedObjectsUpToCurrentMetadataObject = StateRecording.ProcessedObjectsUpToCurrentMetadataObject
		+ ProcessedObjectsCountByMetadata(MetadataObject);
	ProcessedObjectsByMetadata.Delete(MetadataObject);
	
	StateRecording.ProcessedObjectsUpToCurrentMetadataObject = ProcessedObjectsUpToCurrentMetadataObject;
	StateRecording.NameOfMetadataObjectBeingProcessed = GetMetadataObjectNameForProcessing("");
	
	RecordState(EndProcessingDate);
	
EndProcedure

// Fix the processing of objects in the parent thread.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
//  DateOfProcessing - Date - Date objects were processed
//  Count - Number - Processed objects
Procedure CommitObjectsProcessingInParentThread(MetadataObject, DateOfProcessing, Count)
	
	CommitObjectsProcessing(MetadataObject, Count);
	
	If ProcessedObjectsAfterCalculatingState <= ObjectsAtCompletionPercentage Then
		Return;
	EndIf;
		
	RefreshStatus(DateOfProcessing);
					
	If DateOfProcessing < NextStateRecordMinimumDate Then
		Return;
	EndIf;
				
	RecordState(DateOfProcessing);
	
	NextStateRecordMinimumDate = DateOfProcessing + 5;
	
EndProcedure

// Fix object processing.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
//  Count - Number - Processed objects
Procedure CommitObjectsProcessing(MetadataObject, Count)
	
	ProcessedObjectsAfterCalculatingState = ProcessedObjectsAfterCalculatingState + Count;
	ProcessedObjectsCount1 = ProcessedObjectsCountByMetadata(MetadataObject) + Count;
	
	ProcessedObjectsByMetadata.Insert(MetadataObject, ProcessedObjectsCount1);
	
EndProcedure

// Get the name of the metadata object being processed.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
// 
// Returns:
//  String - Name Of The Metadata Object Being Processed
Function GetMetadataObjectNameForProcessing(MetadataObject)
	
	If ProcessedObjectsByMetadata.Count() <= 1 Then
		Return MetadataObject;
	EndIf;
	
	MaximumNameLength = 255;
	NameSeparator = ", ";
	ObjectsToProcess = New Array();
	
	For Each ProcessingElement In ProcessedObjectsByMetadata Do
		ObjectsToProcess.Add(ProcessingElement.Key);
	EndDo;
	
	NameOfMetadataObjectBeingProcessed = StrConcat(ObjectsToProcess, NameSeparator);
	
	If StrLen(NameOfMetadataObjectBeingProcessed) > MaximumNameLength Then
		
		NameOfMetadataObjectBeingProcessed = "";
		NameEnding = NStr("vi = 'và khác';
							|ru = 'и другие';
							|en = 'and other'; fa = 'and other';
							|it = 'и другие';
							|pl = 'and other';
							|tr = 've diğerleri'");
		NameEndingLength = StrLen(NameEnding) + 1;
		NameSeparatorLength = StrLen(NameSeparator);
		
		For Each MetadataObjectName In ObjectsToProcess Do
			
			FutureNameLength = StrLen(NameOfMetadataObjectBeingProcessed)
				+ NameSeparatorLength
				+ StrLen(MetadataObjectName)
				+ NameEndingLength;
			
			If FutureNameLength > MaximumNameLength Then
				NameOfMetadataObjectBeingProcessed = NameOfMetadataObjectBeingProcessed + " " + NameEnding;
				Break;
			EndIf;
			
			NameOfMetadataObjectBeingProcessed = NameOfMetadataObjectBeingProcessed
				+ NameSeparator
				+ MetadataObjectName;
			
		EndDo;
		
	EndIf;
	
	Return NameOfMetadataObjectBeingProcessed;
	
EndFunction

// The number of processed objects by metadata.
// 
// Parameters:
//  MetadataObject - String - full name of the metadata object
// 
// Returns:
//  Number
Function ProcessedObjectsCountByMetadata(MetadataObject)
	
	ProcessedObjectsCount1 = ProcessedObjectsByMetadata.Get(MetadataObject);
	
	If ProcessedObjectsCount1 = Undefined Then
		ProcessedObjectsCount1 = 0;
		ProcessedObjectsByMetadata.Insert(MetadataObject, 0);
	EndIf;
	
	Return ProcessedObjectsCount1;
	
EndFunction

#EndRegion

#Region ParallelExportImport

Procedure InitializeVariablesInThread(ContainerParameters)
	
	CheckingContainerInitialization(True);
	
	IsChildThread = True;
	ForUnloading = ContainerParameters.ForUnloading;
	ForImport = ContainerParameters.ForImport;
	TempDirectory = ContainerParameters.TempDirectory;
	ForTechnicalSupport = ContainerParameters.ForTechnicalSupport;
	FixState = ContainerParameters.FixState;
	ProcessingObjectsCount = ContainerParameters.ProcessingObjectsCount;
	ProcessID = ContainerParameters.ProcessID;
	Parameters = ContainerParameters.Parameters;
	
	If ForImport Then
		Content = ContainerParameters.Content;
	EndIf;
	
	ClientSessionNumber = ExportImportDataInternal.ClientSessionNumberFromParameters(ContainerParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

// Initializing the default container state

AdditionalProperties = New Structure();

NumberOfFilesByType = New Structure();
FilesUsed = New Array;

ForUnloading = False;
ForImport = False;
IsChildThread = False;
MessageNumberInStream = 0;
ThreadNumber = 0;
ClientSessionNumber = 0;

ExtensionsFrameVersions = New Map();
PlusExtensionsAgent = New Map();

#EndRegion

#EndIf