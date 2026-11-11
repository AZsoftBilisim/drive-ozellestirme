///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns the settings for mixed (volumes/infobase) file storage.
//
// Returns:
//   Structure::
//    * FilesExtensions   - String - file extensions that are stored in the infobase.
//                                    Separated by space.
//    * MaximumSize - Number - Maximum size of the file being saved to the infobase, in bytes.
//
Function FilesStorageParametersInInfobase() Export
	
	SetPrivilegedMode(True);
	Return Constants.ParametersOfFilesStorageInIB.Get().Get();
	
EndFunction

// Sets the settings for mixed (volumes/infobase) file storage.
//
// Parameters:
//  StorageParameters - Structure - settings of file storage in the infobase. Properties:
//    * FilesExtensions   - String - file extensions that are stored in the infobase.
//                           Separated by space.
//    * MaximumSize - Number - a maximum size of the file being saved
//                           to the infobase, in bytes.
//
Procedure SetFilesStorageParametersInInfobase(StorageParameters) Export
	
	StorageParametersSet = New ValueStorage(StorageParameters, New Deflation(9));
	Constants.ParametersOfFilesStorageInIB.Set(StorageParametersSet);
	
EndProcedure

// Returns "True" if at least one file storage volume is configured.
//
// Returns:
//   Boolean
//
Function HasFileStorageVolumes(Val StorageVolumeType = Undefined, Val FilesStorageMethod = Undefined) Export

	If StorageVolumeType = Undefined Then
		StorageVolumeType = Enums.StorageKinds.OperationalStorage;
	EndIf;

	If FilesStorageMethod = Undefined Then
		FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.DeletionMark = FALSE
	|	AND FileStorageVolumes.StorageVolumeType = &StorageVolumeType
	|	AND (&AnyFilesStorageMethod
	|			OR FileStorageVolumes.FilesStorageMethod = &FilesStorageMethod)";

	Query.SetParameter("StorageVolumeType"		, StorageVolumeType);
	Query.SetParameter("FilesStorageMethod"		, FilesStorageMethod);
	Query.SetParameter("AnyFilesStorageMethod"	, FilesStorageMethod = "WithAnyStorageMethodInVolumes");

	SetSafeModeDisabled(True); 
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Private

// Returns the file binary data.
//
// Parameters:
//   AttachedFile - DefinedType.AttachedFile - a reference to the catalog item with file.
//   RaiseException1 - Boolean - if True, returns Undefined
//                     instead of raising an exception. The default value is True.
//   GettingFileFromArchive - Boolean 
//							  The default value is False.
//
// Returns:
//   BinaryData, Undefined - binary data of the attachment. If the binary data of the file is not found
//                               in the infobase or volumes, an exception is thrown. If the binary data is not found and the ShouldRaiseException parameter is set to False,
//                               the return value is Undefined.
//                               
//
Function FileData(AttachedFile, Val RaiseException1 = True, GettingFileFromArchive = False) Export

	FileProperties = FilePropertiesInVolume(AttachedFile);
	Try
		Return New BinaryData(FullFileNameInVolume(FileProperties));
	Except
		FileObject1 = FilesOperationsInternal.FileObject1(AttachedFile);
		FilesOperationsInternal.ReportErrorFileNotFound(FileObject1, RaiseException1, GettingFileFromArchive);
		Return Undefined;
	EndTry;
	
EndFunction

// Constructor of attached file data structure. For details,  See AppendFile.
// 
// Returns:
//   Structure:
//     The following properties must be filled in before adding a file:
//       * Ref                       - DefinedType.AttachedFile - a reference to the catalog item with files.
//       * Description                 - String - a description of the file being added.
//       * Size                       - Number - a file size.
//       * Extension                   - String - an extension of the file being added.
//       * FileOwner                - DefinedType.AttachedFilesOwner - a reference to the file owner.
//       * UniversalModificationDate - Date - the file modification date.
//       * AdditionalProperties - Structure
//    After adding you can analyze the following properties:
//       * FileStorageType - EnumRef.FileStorageTypes - the file data storage type.
//       * Volume              - CatalogRef.FileStorageVolumes - the volume to which the file was added.
//       * PathToFile       - String - a path in the volume, by which the file was placed.
//       * StoredFile     - ValueStorage - data of the added file.
//
Function FileAddingOptions() Export
	
	FileParameters = New Structure;
	FileParameters.Insert("Ref", Undefined);
	FileParameters.Insert("Volume", Catalogs.FileStorageVolumes.EmptyRef());
	FileParameters.Insert("PathToFile", "");
	FileParameters.Insert("Extension", Undefined);
	FileParameters.Insert("Size", 0);
	FileParameters.Insert("Description", "");
	FileParameters.Insert("StoredFile", Undefined);
	FileParameters.Insert("FileOwner", Undefined);
	FileParameters.Insert("FileStorageType", Undefined);
	FileParameters.Insert("UniversalModificationDate", Undefined);
	FileParameters.Insert("AdditionalProperties", New Structure);
	
	Return FileParameters;
	
EndFunction

// Adds a file to one of the volumes (which has free space) or to the infobase if
// the method for storing files in the settings is InInfobaseAndVolumesOnHardDrive and the file
// matches the infobase storage settings.
//
// Parameters:
//   AttachedFile  - See FilesOperationsInVolumesInternal.FileAddingOptions
//                       - DefinedType.AttachedFileObject - an element of the Catalog
//                         of attached files or a structure with properties whose data is stored in the volume.
//   BinaryDataOrPath - BinaryData
//                         - String - binary data of the file or the full file path.
//   FileDateInVolume - Date - if not specified, set it so the current session date.
//   FillInternalStorageAttribute - Boolean - if the parameter is True, also store
//                                       the binary file data to the FileStorage internal attribute.
//   VolumeForPlacement - CatalogRef.FileStorageVolumes
//                    - Undefined - If the parameter is filled, files will be placed to a specified volume.
//                                     Otherwise, the volume will be selected automatically.
//
Procedure AppendFile(AttachedFile, BinaryDataOrPath,
	FileDateInVolume = Undefined, FillInternalStorageAttribute = False, VolumeForPlacement = Undefined) Export
	
	FillInTheFileDetails(AttachedFile, BinaryDataOrPath, FileDateInVolume, 
		FillInternalStorageAttribute, VolumeForPlacement);
	
	If AttachedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		WriteTheFileDataToTheVolume(AttachedFile, BinaryDataOrPath);
	EndIf;
	
EndProcedure

// Fills in the attributes of the attachment by file or binary data.
// 
// If the file is stored in volumes, it generates a new file name in the volume without putting the file data in the volume.
//  
// The attachment is not saved.
// 
// Throws exceptions. 
// 
// Parameters:
//   AttachedFile  - See FilesOperationsInVolumesInternal.FileAddingOptions
//                       - DefinedType.AttachedFileObject - an element
//                                     of the attached file Catalog whose data is stored in the volume,
//                                     or a structure with the properties necessary to save data in the volume.
//   BinaryDataOrPath - BinaryData
//                         - String - binary data of the file or the full file path.
//   FileDateInVolume - Date - if it is not specified, the current session time is used.
//   FillInternalStorageAttribute - Boolean - if the parameter is True, also store
//                                       the binary file data to the FileStorage internal attribute.
//   VolumeForPlacement - CatalogRef.FileStorageVolumes
//                    - Undefined - If the parameter is filled, files will be placed to a specified volume.
//                                     Otherwise, the volume will be selected automatically.
//
Procedure FillInTheFileDetails(AttachedFile, BinaryDataOrPath, 
	FileDateInVolume = Undefined, FillInternalStorageAttribute = False, VolumeForPlacement = Undefined) Export
	
	ExpectedTypes = New Array;
	ExpectedTypes.Add(Type("BinaryData"));
	ExpectedTypes.Add(Type("String"));
	CommonClientServer.CheckParameter("FilesOperationsInternal.AddFileToVolume",
		"BinaryDataOrPath", BinaryDataOrPath, New TypeDescription(ExpectedTypes));
	
	If TypeOf(AttachedFile) = Type("Structure")
		And Not ValueIsFilled(AttachedFile.Ref) Then
		
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa điền giá trị thuộc tính %1 trong tham số %2 (Cấu hình) trong thủ tục %3.';
				|ru = 'Не заполнено значение свойства %1 в параметре %2 (Структура) в процедуре %3.';
				|en = 'Blank value of the %1 property the %2 parameter (Structure) of the %3 procedure.'; fa = 'Blank value of the %1 property the %2 parameter (Structure) of the %3 procedure.';
				|it = 'Il valore della proprietà %1 nel parametro %2 (Struttura) nella procedura %3 non è impostato.';
				|pl = 'Nie wypełniono wartości właściwości %1 w parametrze %2 (Struktura) w procedurze %3.';
				|tr = '%3 prosedüründe %2 parametrenin (Yapı) %1 özellik değeri belirtilmedi.'"),
			"Ref",
			"AttachedFile",
			"FilesOperationsInVolumesInternal.AppendFile"), ErrorCategory.ConfigurationError);
		
	EndIf;
	
	If TypeOf(BinaryDataOrPath) = Type("String") Then
		
		FileInVolume = New File(BinaryDataOrPath);
		If FileInVolume.Exists() Then
			AttachedFile.Size = FileInVolume.Size();
			AttachedFile.Extension = StrReplace(FileInVolume.Extension, ".", "");
		Else
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thêm tệp ""%1"" vào bất kỳ quyển nào vì nó không tồn tại.
				|Có thể, chương trình diệt vi-rút đã xóa tệp. Hãy liên hệ với người quản trị.';
				|ru = 'Не удалось добавить файл ""%1"" ни в один из томов, т.к. он отсутствует.
				|Возможно, файл удален антивирусом. Обратитесь к администратору.';
				|en = 'Cannot add file ""%1"" to a volume as the file is missing.
				|The file might have been deleted by antivirus software. Please contact the administrator.'; fa = 'Cannot add file ""%1"" to a volume as the file is missing.
				|The file might have been deleted by antivirus software. Please contact the administrator.';
				|it = 'Не удалось добавить файл ""%1"" ни в один из томов, т.к. он отсутствует.
				|Возможно, файл удален антивирусом. Обратитесь к администратору.';
				|pl = 'Cannot add file ""%1"" to a volume as the file is missing.
				|The file might have been deleted by antivirus software. Please contact the administrator.';
				|tr = 'Birimlerden hiçbirine ""%1"" dosyası eksik olduğundan dolayı eklenemedi. 
				|Dosya antivirüs tarafından silinmiş olabilir. Lütfen sistem yöneticinize başvurun.'"),
				AttachedFile.Description + "." + AttachedFile.Extension);
			Raise ErrorText;
			
		EndIf;
		
	Else
		AttachedFile.Size = BinaryDataOrPath.Size();
		AttachedFile.Extension = StrReplace(AttachedFile.Extension, ".", "");
	EndIf;
	
	FileStorageType = AttachedFile.FileStorageType;
	If Not ValueIsFilled(FileStorageType) Then
		FileStorageType = FilesOperationsInternal.FileStorageType(AttachedFile.Size, AttachedFile.Extension);
	EndIf;

	If FileStorageType = Enums.FileStorageTypes.InInfobase Then

		AttachedFile.FileStorageType = Enums.FileStorageTypes.InInfobase;
		AttachedFile.Volume = Undefined;
		AttachedFile.PathToFile = "";

		RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(AttachedFile);

		FileRef = AttachedFile.Ref;
		If Not ValueIsFilled(FileRef) Then
			MetadataAttachedFile = AttachedFile.Metadata(); // MetadataObject
			FileRef = Catalogs[MetadataAttachedFile.Name].GetRef();
			AttachedFile.SetNewObjectRef(FileRef);
		EndIf;

		FileData = ?(TypeOf(BinaryDataOrPath) = Type("String"),
			New BinaryData(BinaryDataOrPath), BinaryDataOrPath);
		FilesOperationsInternal.WriteFileToInfobase(FileRef, FileData, RecordingParametersVIB);
		
		If FillInternalStorageAttribute Then
			AttachedFile.FileStorage = New ValueStorage(FileData, New Deflation(9));			
		EndIf;

	Else

		If ValueIsFilled(VolumeForPlacement) Then
			AttachedFile.Volume = VolumeForPlacement;
		Else
			AttachedFile.Volume = FileArchiveManagementServer.FreeStorageVolumeByFilesStorageType(AttachedFile, 
																												FileStorageType,
																												Enums.StorageKinds.OperationalStorage);
		EndIf;
		
		If FileStorageType = Enums.FileStorageTypes.VolumesVolumeUndefined Then
			AttachedFile.FileStorageType = FileArchiveManagementServer.StorageTypeByFilesStorageVolume(AttachedFile.Volume);
		ElsIf AttachedFile.FileStorageType <> FileStorageType Then
			AttachedFile.FileStorageType = FileStorageType;
		EndIf;

		FileProperties = FilePropertiesInVolume();
		FillPropertyValues(FileProperties, AttachedFile);
		If FileProperties.FileOwner = Undefined 
			And TypeOf(AttachedFile.Ref) = Type("CatalogRef.FilesVersions") Then
			FileProperties.FileOwner = Common.ObjectAttributeValue(
				AttachedFile.Owner, "FileOwner");
		EndIf;
		
		If AttachedFile.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
			VolumePath = FullVolumePath(AttachedFile.Volume);
			PathToFile = FullFileNameInVolume(FileProperties, FileDateInVolume);
			
			AttachedFile.PathToFile = Mid(PathToFile, StrLen(VolumePath) + 1);
			AttachedFile.AdditionalProperties.Insert("VolumePath", VolumePath);
		Else
			AttachedFile.PathToFile = "";
		EndIf;

		If FillInternalStorageAttribute Then
			AttachedFile.FileStorage = New ValueStorage(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

// Copies the attachment data by the specified path.
//
// Parameters:
//   AttachedFile - DefinedType.AttachedFile
//   FilePathDestination - String - a full path (including a file name), to which the file will be copied from the volume.
//
Procedure CopyAttachedFile(AttachedFile, FilePathDestination) Export
	
	FileProperties = FilePropertiesInVolume(AttachedFile);
	FilePathSource = FullFileNameInVolume(FileProperties);
	
	SourceFile1 = New File(FilePathSource);
	If Not SourceFile1.Exists() Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xóa dữ liệu tệp. Có thể là, tệp đã bị xóa như là không cần thiết hoặc đã bị xóa bởi phần mềm diệt virus.
				|%1';
				|ru = 'Данные файла были удалены. Возможно, файл очищен как ненужный или удален антивирусом.
				|%1';
				|en = 'File data was deleted. The file might have been cleaned up as unused or deleted by the antivirus software.
				|%1'; fa = 'File data was deleted. The file might have been cleaned up as unused or deleted by the antivirus software.
				|%1';
				|it = 'Данные файла были удалены. Возможно, файл очищен как ненужный или удален антивирусом.
				|%1';
				|pl = 'File data was deleted. The file might have been cleaned up as unused or deleted by the antivirus software.
				|%1';
				|tr = 'Dosya bilgileri silindi. Dosya gereksiz olarak ya da antivirüs tarafından silinmiş olabilir.
				|%1'"), String(AttachedFile));
		Raise ErrorMessage;		
	EndIf;
	
	CopyFile(FilePathSource, FilePathDestination);
	
	// If the file is read-only, clear this attribute for 
	// the destination file to be able to edit or delete.
	FileDestination = New File(FilePathDestination);
	If FileDestination.Exists() And FileDestination.GetReadOnly() Then
		FileDestination.SetReadOnly(False);
	EndIf;
	
EndProcedure

// Deletes file from the volume.
//
// Parameters:
//   PathToFile - String - a path to the file to be deleted.
// 
// Returns:
//    Structure:
//    * Success - Boolean
//    * ErrorInfo - ErrorInfo
//
Function DeleteFile(PathToFile) Export
	Result = New Structure("Name,Success,ErrorInfo", PathToFile, True, Undefined);
	
	FileInVolume = New File(PathToFile);
	If Not FileInVolume.Exists() Then
		Return Result;
	EndIf;
		
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đang xóa tệp ""%1""';
			|ru = 'Удаляется файл ""%1""';
			|en = 'Deleting file: %1'; fa = 'Deleting file: %1';
			|it = 'Удаляется файл ""%1""';
			|pl = 'Deleting file: %1';
			|tr = '""%1"" dosyası siliniyor'"), 
		PathToFile);
	WriteLogEvent(EventLogEvent(),
		EventLogLevel.Information,,, EventLogMessage(MessageText));

	FileDirectory = FileInVolume.Path;
	Try
		FileInVolume.SetReadOnly(False);
		DeleteFiles(PathToFile);
		
		// Deleting the file directory if the directory is empty after the file deletion.
		FilesInDirectory = FindFiles(FileDirectory, GetAllFilesMask());
		If FilesInDirectory.Count() = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đang xóa thư mục con trống ""%1""';
					|ru = 'Удаляется пустой подкаталог ""%1""';
					|en = 'Deleting empty directory: %1'; fa = 'Deleting empty directory: %1';
					|it = 'Удаляется пустой подкаталог ""%1""';
					|pl = 'Deleting empty directory: %1';
					|tr = 'Boş ""%1"" alt kataloğu siliniyor'"), 
				FileDirectory);
			WriteLogEvent(EventLogEvent(),
				EventLogLevel.Information,,, EventLogMessage(MessageText));
			DeleteFiles(FileDirectory);
		EndIf;
		
	Except
		Error = ErrorInfo();
		Result.ErrorInfo = ErrorProcessing.ErrorMessageForUser(Error);
		Result.Success = False;
		WriteLogEvent(EventLogEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(Error));
	EndTry;
		
	Return Result;
EndFunction

Function EventLogEvent()
	
	Return NStr("vi = 'Tệp.Xóa tệp trong quyển';
				|ru = 'Файлы.Удаление файлов в томе';
				|en = 'Files.Delete files in volume'; fa = 'Files.Delete files in volume';
				|it = 'Файлы.Удаление файлов в томе';
				|pl = 'Pliki.Usuwanie plików w woluminie';
				|tr = 'Dosyalar. Dosyaları birimden sil'", Common.DefaultLanguageCode());
	
EndFunction

Function EventLogMessage(MessageText)
	
	If Not Common.DebugMode() Then
		Return MessageText;
	EndIf;
	
	Try
		Raise MessageText;
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
EndFunction

// Renames a file in the volume.
//
// Parameters:
//   AttachedFile      - DefinedType.AttachedFile - a reference to the catalog item with file.
//   NewName                - String - a name that will be set to the file in the volume.
//   OldName               - String - the current file name in the volume. If the parameter is not filled in, the description of the attached file will be considered the current
//                           name.
//   UUID - UUID - a form ID to lock the attached
//                           file when writing a new file path to the volume.
//
Procedure RenameFile(AttachedFile,Val NewName,
	Val OldName = "", UUID = Undefined) Export
	
	BeginTransaction();
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add(
			Metadata.FindByType(TypeOf(AttachedFile)).FullName());
		DataLockItem.SetValue("Ref", AttachedFile);
		DataLock.Lock();
		
		AttachedFileObject = AttachedFile.GetObject();
		LockDataForEdit(AttachedFile, , UUID);
		
		FileProperties = FilePropertiesInVolume();
		FillPropertyValues(FileProperties, AttachedFileObject);
		
		VolumePath = FullVolumePath(AttachedFileObject.Volume);
		CurrentFilePath = FullFileNameInVolume(FileProperties);
		
		FileInVolume = New File(CurrentFilePath);
		NameForReplacement = ?(IsBlankString(OldName), AttachedFileObject.Description, OldName);
		NewNameOfFile = StrReplace(FileInVolume.BaseName, NameForReplacement, NewName) + FileInVolume.Extension;

		NewFilePath = FileInVolume.Path
			+ FilesOperationsInternalClientServer.UniqueNameByWay(FileInVolume.Path, NewNameOfFile);
			
		MoveFile(CurrentFilePath, NewFilePath);
		
		AttachedFileObject.PathToFile = StrReplace(NewFilePath, VolumePath, "");
		AttachedFileObject.Write();
		
		UnlockDataForEdit(AttachedFile, UUID);
		CommitTransaction();
		
	Except
		RollbackTransaction();
		UnlockDataForEdit(AttachedFile, UUID);
		Raise;
	EndTry;
	
EndProcedure

// Initializes the file property structure to get the full path to the file in the volume.
// 
// If version storage is used for a file and there are no versions, 
// then the data will be filled in by the file, and empty values will be returned as the Volume and path.
//
// Parameters:
//   File - DefinedType.AttachedFile
//        - Undefined - If the parameter value is filled,
//          properties are filled with values of respective file attributes of the same name. Otherwise, the properties take the Undefined values.
//
// Returns:
//   Structure:
//     * Description - String - a file description.
//     * Volume - CatalogRef.FileStorageVolumes
//     * PathToFile - String - a path to file.
//     * FileOwner - DefinedType.AttachedFilesOwner
//                     - DefinedType.FilesOwner
//                     - Undefined
//     * Extension - String - a file extension.
//     * VersionNumber - String - the file version number.
//
Function FilePropertiesInVolume(File = Undefined) Export
	
	FileProperties = New Structure;
	FileProperties.Insert("Description", "");
	FileProperties.Insert("Extension", "");
	FileProperties.Insert("Volume", Catalogs.FileStorageVolumes.EmptyRef());
	FileProperties.Insert("PathToFile", "");
	FileProperties.Insert("FileOwner", Undefined);
	FileProperties.Insert("VersionNumber", "");
	
	If ValueIsFilled(File) Then
		
		If TypeOf(File) = Type("CatalogRef.Files") Then
			RefToVersion = Common.ObjectAttributeValue(File, "CurrentVersion");
		Else
			RefToVersion = File;
		EndIf;
		
		// During file deletion there could be no file versions.
		PropertyToCheck = New Structure("DataVersion");
		FillPropertyValues(PropertyToCheck, RefToVersion);
		If Not ValueIsFilled(PropertyToCheck.DataVersion) Then
			RefToVersion = File;
		EndIf;
		
		FileAttributes = New Array;
		FileAttributes.Add("Description");
		FileAttributes.Add("Extension");
		FileAttributes.Add("Volume");
		FileAttributes.Add("PathToFile");
		If TypeOf(RefToVersion) = Type("CatalogRef.FilesVersions") Then
			FileAttributes.Add("Owner");
			FileAttributes.Add("VersionNumber");
		Else
			FileAttributes.Add("FileOwner");
		EndIf;
		
		AttributesNames = StrConcat(FileAttributes, ",");
		FileAttributes = Common.ObjectAttributesValues(RefToVersion, AttributesNames);
		FillPropertyValues(FileProperties, FileAttributes);
		 
		If FileAttributes.Property("Owner") And ValueIsFilled(FileAttributes.Owner) Then
			FileProperties.FileOwner = Common.ObjectAttributeValue(FileAttributes.Owner, "FileOwner");
		EndIf;
		
	EndIf;
	
	If TypeOf(FileProperties.VersionNumber) <> Type("String") Then
		FileProperties.VersionNumber = String(FileProperties.VersionNumber);
	EndIf;
	
	Return FileProperties;
	
EndFunction

// Returns a full name for the file in the volume, considering file storage
// settings in volumes and separator values.
//
// Parameters:
//   FileProperties - See FilePropertiesInVolume.
//   FileDateInVolume - Date
//   
// Returns:
//   String
//
Function FullFileNameInVolume(FileProperties, FileDateInVolume = Undefined) Export
	
	Separator = GetPathSeparator();
	
	If Not ValueIsFilled(FileProperties.Volume) Then
		Return "";
	EndIf;
	
	FullVolumePath = FullVolumePath(FileProperties.Volume);
	If Not IsBlankString(FileProperties.PathToFile) Then
		Return FullVolumePath + FileProperties.PathToFile;
	EndIf;
	
	RootDirectory1 = FullVolumePath + ?(Right(FullVolumePath, 1) = Separator, "", Separator);
	If CreateSubdirectoriesWithOwnersNames() Then
		FileOwnerDirectoryName = FileOwnerDirectoryName(FileProperties.FileOwner);
		RootDirectory1 = RootDirectory1 + FileOwnerDirectoryName + ?(FileOwnerDirectoryName = "", "", Separator);
	EndIf;
	
	PlacementDate = ?(ValueIsFilled(FileDateInVolume), FileDateInVolume, CurrentSessionDate());
	RootDirectory1 = RootDirectory1 + Format(PlacementDate, "DF=yyyyMMdd") + Separator;
	
	VersionNumber = ?(ValueIsFilled(FileProperties.VersionNumber), "." + FileProperties.VersionNumber, "");
	AddPoint = ValueIsFilled(FileProperties.Extension) And StrFind(FileProperties.Extension, ".") = 0;
	FileName = CommonClientServer.ReplaceProhibitedCharsInFileName(FileProperties.Description)
		+ VersionNumber + ?(AddPoint, ".", "") + FileProperties.Extension;
		
	Common.ShortenFileName(FileName);
	
	Try
		Return RootDirectory1
			+ FilesOperationsInternalClientServer.UniqueNameByWay(RootDirectory1, FileName);
	Except
		Volume = New File(FullVolumePath);
		If Not Volume.Exists() Or Not Volume.IsDirectory() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tồn tại thư mục mạng đối với quyển lưu tệp ""%1"": %2
					|Hãy liên hệ với người quản trị.';
					|ru = 'Не существует сетевой каталог для тома хранения файлов ""%1"": %2
					|Обратитесь к администратору.';
					|en = 'A network directory for the ""%1"" storage volume does not exist: %2
					|Contact your administrator.'; fa = 'A network directory for the ""%1"" storage volume does not exist: %2
					|Contact your administrator.';
					|it = 'Non esiste catalogo di rete per il tomo di salvataggio dei file ""%1"":%2
					|Rivolgersi all''amministratore.';
					|pl = 'Nie istnieje sieciowego katalogu dla wolumina przechowywania plików""%1"": %2
					|Skontaktuj się z administratorem.';
					|tr = '""%1"" dosya depolama birimi için ağ dizini yok: %2
					|Lütfen yöneticinize başvurun.'"), FileProperties.Volume, FullVolumePath);
		EndIf;
		Raise;
	EndTry	
EndFunction

// Returns a full path to the root directory of a file storage volume.
//
// Parameters:
//   Volume - CatalogRef.FileStorageVolumes - the volume whose root directory path is to be received.
//
// Returns:
//   String - Full path to the volume's root directory.
//
Function FullVolumePath(Volume) Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	RootDirectory1 = Common.ObjectAttributeValue(Volume,
		?(Common.IsWindowsServer(), "FullPathWindows", "FullPathLinux"));
	
	If Common.DataSeparationEnabled() Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SeparatorValue = "";
		If VolumePathIgnoreRegionalSettings() Then
			SeparatorValue = ?(ModuleSaaSOperations.SessionSeparatorUsage(),
									Format(ModuleSaaSOperations.SessionSeparatorValue(), "NG=;"),
									"");
		Else
			SeparatorValue = ?(ModuleSaaSOperations.SessionSeparatorUsage(),
									ModuleSaaSOperations.SessionSeparatorValue(),
									"");
		EndIf;
	Else
		SeparatorValue = "";
	EndIf;
	
	Return StrReplace(RootDirectory1, "%z",SeparatorValue);
	
EndFunction

// Returns the total size of all files in the volume in bytes.
//
// Parameters:
//   Volume - CatalogRef.FileStorageVolumes - a volume whose size must be calculated.
//
// Returns:
//   Number - Total size of the volume files.
//
Function VolumeSize(Volume) Export
	
	VolumeSize = 0;
	If Not Common.SeparatedDataUsageAvailable() Then
		Return VolumeSize;
	EndIf;
	
	Query = New Query;
	AttachedFilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(SUM(Versions.Size), 0) AS FilesSize
	|FROM
	|	Catalog.FilesVersions AS Versions
	|WHERE
	|	Versions.Volume = &Volume";
	
	For Each Type In AttachedFilesTypes Do
		
		If Type = Type("CatalogRef.FilesVersions")
			Or Type = Type("CatalogRef.MetadataObjectIDs") Then
			
			Continue;
		EndIf;
		
		CatalogMetadata = Metadata.FindByType(Type);
		If CatalogMetadata.Attributes.Find("CurrentVersion") <> Undefined Then
			Continue;
		EndIf;
		
		QueryTextByDirectory = "SELECT
		|	ISNULL(SUM(AttachedFiles.Size), 0)
		|FROM
		|	&CatalogName AS AttachedFiles
		|WHERE
		|	AttachedFiles.Volume = &Volume";
		
		Query.Text = Query.Text + "
		|
		|UNION ALL
		|
		|" + StrReplace(QueryTextByDirectory, "&CatalogName",
			Metadata.FindByType(Type).FullName());
		
	EndDo;
	
	Query.Parameters.Insert("Volume", Volume);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		VolumeSize = VolumeSize + Selection.FilesSize;
	EndDo;
			
	Return VolumeSize;
	
EndFunction

// Checks whether the file is on the volume.
//
// Parameters:
//   AttachedFile - DefinedType.AttachedFile - catalog item with a file.
//
// Returns:
//   Boolean
//
Function IsAttachedFileInVolume(AttachedFile) Export
	
	FileProperties = FilePropertiesInVolume(AttachedFile);
	PathToFile = FullFileNameInVolume(FileProperties);
	If Not ValueIsFilled(PathToFile) Then
		Return False;
	EndIf;
			
	FileToCheck = New File(PathToFile);
	If FileToCheck.Exists() Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

#Region AccountingAudit

// See AccountingAuditOverridable.OnDefineChecks
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	Validation = Checks.Add();
	Validation.GroupID          = "SystemChecks";
	Validation.Description                 = NStr("vi = 'Tìm kiếm tham chiếu đến tệp không tồn tại trong các quyển lưu trữ';
													|ru = 'Поиск ссылок на несуществующие файлы в томах хранения';
													|en = 'Search for references to missing files in storage volumes'; fa = 'Search for references to missing files in storage volumes';
													|it = 'Ricerca di collegamenti a file inesistenti nei volumi di archiviazione';
													|pl = 'Wyszukiwanie linków do nieistniejących plików w woluminach przechowywania';
													|tr = 'Depolama birimlerinde varolmayan dosyalara bağlantılar bulma'");
	Validation.Reasons                      = NStr("vi = 'Tệp đã bị xóa sạch hoặc chuyển vào máy tính do phần mềm diệt virus,
		|do thao tác không chủ ý của người quản trị...';
		|ru = 'Файл был физически удален или перемещен на компьютере вследствие работы антивируса,
		|непреднамеренных действий администратора и.т.д.';
		|en = 'The file was deleted or moved by the antivirus software,
		|unintentional actions of the administrator, or similar reasons.'; fa = 'The file was deleted or moved by the antivirus software,
		|unintentional actions of the administrator, or similar reasons.';
		|it = 'Файл был физически удален или перемещен на компьютере вследствие работы антивируса,
		|непреднамеренных действий администратора и.т.д.';
		|pl = 'The file was deleted or moved by the antivirus software,
		|unintentional actions of the administrator, or similar reasons.';
		|tr = 'Dosya, antivirüs programları, istenmeyen yönetici eylemleri vb.
		|nedeniyle fiziksel olarak silinmiş veya bilgisayara taşınmıştır.'");
	Validation.Recommendation                 = NStr("vi = '• Đặt dấu xóa tệp trong ứng dụng;
		|• Hoặc khôi phục tệp trong quyển từ bản sao dự phòng.';
		|ru = '• Пометить файл в приложении на удаление;
		|• Или восстановить файл в томе из резервной копии.';
		|en = '• Mark the file for deletion.
		|• Restore the volume file from a backup.'; fa = '• Mark the file for deletion.
		|• Restore the volume file from a backup.';
		|it = '• Пометить файл в приложении на удаление;
		|• Или восстановить файл в томе из резервной копии.';
		|pl = '• Mark the file for deletion.
		|• Restore the volume file from a backup.';
		|tr = 'Uygulamadaki dosyayı silinmek üzere işaretle;
		|• Veya birimdeki dosyayı yedekleme kısmından geri yükle.'");
	Validation.Id                = "StandardSubsystems.ReferenceToNonexistingFilesInVolumeCheck";
	Validation.HandlerChecks           = "FilesOperationsInVolumesInternal.ReferenceToNonexistingFilesInVolumeCheck";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.TurnedOff                    = True;
	
EndProcedure

Procedure ReferenceToNonexistingFilesInVolumeCheck(Validation, CheckParameters) Export
	
	If Common.DataSeparationEnabled()
		Or Not ShouldStoreFilesInVolumes() Then
		Return;
	EndIf;
	
	AvailableVolumes = AvailableVolumes(CheckParameters);
	If AvailableVolumes.Count() = 0 Then
		Return;
	EndIf;
	
	ModuleSaaSOperations = Undefined;
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	EndIf;
	
	MetadataObjectsKinds = New Array;
	MetadataObjectsKinds.Add(Metadata.Catalogs);
	MetadataObjectsKinds.Add(Metadata.Documents);
	MetadataObjectsKinds.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsKinds.Add(Metadata.Tasks);
	
	For Each MetadataObjectKind In MetadataObjectsKinds Do
		For Each MetadataObject In MetadataObjectKind Do
			If ModuleSaaSOperations <> Undefined 
				And Not ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject.FullName()) Then
				Continue;
			EndIf;
			If Not CheckAttachedFilesObject(MetadataObject) Then
				Continue;
			EndIf;
			// @skip-check query-in-loop - Batch processing of a large amount of data.
			SearchRefsToNonExistingFilesInVolumes(MetadataObject, CheckParameters, AvailableVolumes);
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

// Returns a flag indicating whether files can be stored in disk volumes.
//
// Returns:
//  Boolean
//
Function ShouldStoreFilesInVolumes() Export
	
	SetPrivilegedMode(True);
	FilesStorageMethod = Constants.FilesStorageMethod.Get();
	
	Return FilesOperationsClientServer.ShouldStoreFilesInVolumes(FilesStorageMethod);
	
EndFunction

// Fills the "PathToFile" attribute for attachments.
// 
// Parameters:
//  FilesToRecover - ValueTable:
//   * File - DefinedType.AttachedFile - File
//   * FullName - String - File's full name in the given volume.
//  VolumePath - String
// 
// Returns:
//  Structure:
//   * Processed - Number
//   * Total - Number
//
Function SetFilesStoragePaths(FilesToRecover, VolumePath) Export
	Result = New Structure;
	Result.Insert("Processed", 0);
	Result.Insert("Total", FilesToRecover.Count());
	
	If FilesToRecover.Count() = 0 Then
		Return Result;
	EndIf;
	
	FilesTypes = New Map;
	
	For Each FileToRecover In FilesToRecover Do
		FileType = TypeOf(FileToRecover.File);
		If FilesTypes[FileType] = Undefined Then
			FilesTypes.Insert(FileType, New Array);
		EndIf;
		
		FilesTypes[FileType].Add(FilesToRecover.IndexOf(FileToRecover));
	EndDo;
	
	Portions = New Array;
	PortionSize = 100;
	
	For Each FileType In FilesTypes Do
		NewBatch = True;
		For Each RowIndex In FileType.Value Do
			If NewBatch Then
				FilesInBatch = New ValueTable;
				FilesInBatch.Columns.Add("File", New TypeDescription(CommonClientServer.ValueInArray(FileType.Key)));
				FilesInBatch.Columns.Add("FullName", New TypeDescription("String"));
				NewBatch = False;
			EndIf;
			NewRecord = FilesInBatch.Add();
			FileToRecover = FilesToRecover[RowIndex];
			NewRecord.File = FileToRecover.File;
			NewRecord.FullName = FileToRecover.FullName;
			IsBatchWritten = False;
			If FilesInBatch.Count() = PortionSize Then
				Portions.Add(FilesInBatch);
				NewBatch = True;
				IsBatchWritten = True;
			EndIf;
		EndDo;
		If Not IsBatchWritten Then
			Portions.Add(FilesInBatch);
		EndIf;
	EndDo;
	
	For Each Batch In Portions Do
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add(Batch[0].File.Metadata().FullName());
			LockItem.DataSource = Batch;
			LockItem.UseFromDataSource("Ref", "File");
			Block.Lock();
			
			FilesStoragePaths = Common.ObjectsAttributeValue(Batch.UnloadColumn("File"), "PathToFile");
			For Each FileToFix In Batch Do
				FileStoragePath = FilesStoragePaths[FileToFix.File];
				If VolumePath = "" Then
					PathToFileInVolume = TrimR(FileToFix.FullName);
				ElsIf StrStartsWith(FileToFix.FullName, VolumePath) Then
					PathToFileInVolume = TrimR(Mid(FileToFix.FullName, StrLen(VolumePath) + 1));
				Else
					PathToFileInVolume = Undefined;
				EndIf;
				
				If PathToFileInVolume <> FileStoragePath Then
					FileToWrite = FileToFix.File.GetObject();
					FileToWrite.PathToFile = PathToFileInVolume;
					FileToWrite.AdditionalProperties.Insert("FileConversion", True);
					FileToWrite.Write();
				EndIf;
			EndDo;
			Result.Processed = Result.Processed + Batch.Count(); 
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteLogEvent(
				NStr("vi = 'Tệp.Phục hồi tệp trong quyển';
					|ru = 'Файлы.Восстановление файлов в томе';
					|en = 'Files.File recovery in volume'; fa = 'Files.File recovery in volume';
					|it = 'Файлы.Восстановление файлов в томе';
					|pl = 'Files.File recovery in volume';
					|tr = 'Dosyalar.Birimdeki dosyaların geri yüklenmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	Return Result;
EndFunction

// Returns sizes of all files in each specified volume in bytes.
//
// Parameters:
//   Volumes - Array of CatalogRef.FileStorageVolumes
//
// Returns:
//   Map of KeyAndValue:
//     * Key - CatalogRef.FileStorageVolumes
//     * Value - Number
//
Function SizesOfVolumes(Volumes)
	
	Result = New Map;
	For Each Volume In Volumes Do
		Result[Volume] = 0;
	EndDo; 
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return Result;
	EndIf;
	
	AttachedFilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	QueriesTexts = New Array;
	
	QueryText = 
	"SELECT
	|	Versions.Volume AS Volume,
	|	ISNULL(Versions.Size, 0) AS FilesSize
	|FROM
	|	Catalog.FilesVersions AS Versions
	|WHERE
	|	Versions.Volume IN (&Volumes)";
	QueriesTexts.Add(QueryText);
	
	QueryTextTemplate2 = "SELECT
	|	AttachedFiles.Volume,
	|	ISNULL(AttachedFiles.Size, 0)
	|FROM
	|	&CatalogName AS AttachedFiles
	|WHERE
	|	AttachedFiles.Volume IN (&Volumes)";
	
	For Each Type In AttachedFilesTypes Do
		
		If Type = Type("CatalogRef.FilesVersions")
			Or Type = Type("CatalogRef.MetadataObjectIDs") Then
			
			Continue;
		EndIf;
		
		CatalogMetadata = Metadata.FindByType(Type);
		If CatalogMetadata.Attributes.Find("CurrentVersion") <> Undefined Then
			Continue;
		EndIf;
		
		QueriesTexts.Add(StrReplace(QueryTextTemplate2, "&CatalogName", 
			Metadata.FindByType(Type).FullName()));
	EndDo;
	
	QueryText = 
		"SELECT
		|	NestedQuery.Volume,
		|	SUM(NestedQuery.FilesSize) AS FilesSize
		|FROM
		|	&AttachmentsQueryText AS NestedQuery
		|GROUP BY
		|	NestedQuery.Volume";
	QueryText = StrReplace(QueryText, "&AttachmentsQueryText", 
		"(" + StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF) + ")"); // @query-part-3
	
	Query = New Query(QueryText); 
	Query.Parameters.Insert("Volumes", Volumes);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result[Selection.Volume] = Selection.FilesSize;
	EndDo;
			
	Return Result;
	
EndFunction

// For the function, See FullVolumePath.
// 
// Returns:
//  Boolean
//
Function VolumePathIgnoreRegionalSettings() Export
	Return FilesOperationsInternalCached.VolumePathIgnoreRegionalSettings();
EndFunction

// Saves the binary file data to a volume, or copies data from the file by the passed path.
// Before calling, fill in the file information (See FillInTheFileDetails)
// 
// .
// 
// Cannot be called with the safe mode enabled (throws exceptions). 
// 
// Parameters:
//   AttachedFile - DefinedType.AttachedFileObject
//   BinaryDataOrPath - BinaryData
//                         - String - binary data of the file or the full file path.
//
Procedure WriteTheFileDataToTheVolume(AttachedFile, BinaryDataOrPath)
	
	SetPrivilegedMode(True);
	
	ErrorDescriptionTemplate = "";
	ExceptionString = "";
	VolumePath = CommonClientServer.StructureProperty(AttachedFile.AdditionalProperties, "VolumePath", "");
	
	FileProperties = FilePropertiesInVolume();
	FillPropertyValues(FileProperties, AttachedFile);
	
	PathToFile = FullFileNameInVolume(FileProperties);
				
	Try
		
		If TypeOf(BinaryDataOrPath) = Type("String") Then
			
			File = New File(PathToFile);
			
			If File.Exists() Then
				File.SetReadOnly(False);
			Else
				Path = File.Path;
				Directory = New File(Path);
				If Not Directory.Exists() Then
					CreateDirectory(Path);
				EndIf;
			EndIf;
				
			CopyFile(BinaryDataOrPath, PathToFile);
			
		Else
			BinaryDataOrPath.Write(PathToFile);
		EndIf;
		
		
		FilesOperationsInternal.SetModificationUniversalTime(PathToFile, AttachedFile.UniversalModificationDate);
		
		File = New File(PathToFile);
		If File.Exists() Then
			File.SetReadOnly(True);
		EndIf;
		
	Except
		
		ErrorDescriptionTemplate = NStr("vi = 'Lỗi khi thêm tệp ""%1""
			|vào quyển ""%2"" (%3):
			|""%4"".';
			|ru = 'Ошибка при добавлении файла ""%1""
			|в том ""%2"" (%3):
			|""%4"".';
			|en = 'An error occurred when adding file ""%1""
			|to volume ""%2"" (%3):
			|""%4"".'; fa = 'An error occurred when adding file ""%1""
			|to volume ""%2"" (%3):
			|""%4"".';
			|it = 'Errore durante l''aggiunta del file ""%1""
			|nel tomo ""%2"" (%3):
			|""%4"".';
			|pl = 'Błąd podczas dodawania pliku ""%1""
			|do woluminu ""%2"" (%3):
			|""%4"".';
			|tr = '""%1"" 
			|Dosyası eklenirken hata oluştu ""%2"" (%3): 
			|""%4"".'");
		
		WriteLogEvent(NStr("vi = 'Tệp.Bổ sung tệp';
							|ru = 'Файлы.Добавление файла';
							|en = 'Files.Add file'; fa = 'Files.Add file';
							|it = 'File.Aggiunta del file';
							|pl = 'Plik.Dodawanie pliku';
							|tr = 'Dosyalar. Dosya ekle'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			StringFunctionsClientServer.SubstituteParametersToString(
				ErrorDescriptionTemplate,
				AttachedFile.Description + "." + AttachedFile.Extension,
				String(AttachedFile.Volume),
				VolumePath,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		
		If Users.IsFullUser() Then
			
			ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorDescriptionTemplate,
				AttachedFile.Description + "." + AttachedFile.Extension,
				String(AttachedFile.Volume),
				VolumePath,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		Else
			
			// Message to end user.
			ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thêm tệp:
				|""%1%2"".
				|
				|Vui lòng liên hệ với người quản trị.';
				|ru = 'Не удалось добавить файл:
				|""%1%2"".
				|
				|Обратитесь к администратору.';
				|en = 'Cannot add file:
				|""%1.%2"".
				|
				|Please contact the administrator.'; fa = 'Cannot add file:
				|""%1.%2"".
				|
				|Please contact the administrator.';
				|it = 'Non è stato possibile aggiungere il file:
				|""%1%2"".
				|
				|Rivolgetevi all''amministratore.';
				|pl = 'Nie udało się dodać pliku:
				|""%1%2"".
				|
				|Skontaktuj się z administratorem.';
				|tr = 'Dosya eklenemedi: 
				|""%1%2"" 
				|
				|Lütfen sistem yöneticinize başvurun.'"),
				AttachedFile.Description,
				AttachedFile.Extension);
				
		EndIf;
		
		Raise ExceptionString;
		
	EndTry; 
	
	If ValueIsFilled(AttachedFile.Ref) Then
		InformationRegisters.FileRepository.DeleteBinaryData(AttachedFile.Ref);
	EndIf;
	
EndProcedure

Procedure ClearDeletedFiles() Export
	If Not ShouldStoreFilesInVolumes() Then
		Return;
	EndIf;
	
	ProcessedVolumes = AvailableVolumes();
	DescriptionOfVolumes = Common.ObjectsAttributesValues(ProcessedVolumes, 
		"Ref, LastFilesCleanupTime, DeletionMark, FullPathLinux, FullPathWindows");
		
	ProcessedDirectories = New Map; // Several volumes can store files in the same directory.
	For Each VolumeDescription In DescriptionOfVolumes Do
		RootDirectory1 = FullVolumePath(VolumeDescription.Key);
		
		SearchDirectoryForDeletedFiles = ProcessedDirectories[RootDirectory1];
		If SearchDirectoryForDeletedFiles = Undefined Then
			SearchDirectoryForDeletedFiles = SearchDirectoryForDeletedFiles(RootDirectory1);
			ProcessedDirectories.Insert(RootDirectory1, SearchDirectoryForDeletedFiles);
		EndIf;
		
		AddVolume(SearchDirectoryForDeletedFiles, VolumeDescription.Value);
	EndDo;
	
	For Each Volume In ProcessedDirectories Do
		// @skip-check query-in-loop - A small number of calls.
		ClearDeletedFilesInTheVolume(Volume.Value);
	EndDo;
EndProcedure

// Parameters:
//  Path - String - Path.
// 
// Returns:
//  Structure - directory of search of files to delete:
//   * Path - String
//   * Volumes - ValueTable:
//   ** Ref - CatalogRef.FileStorageVolumes
//   ** LastFilesCleanupTime - Date
//   ** DeletionMark - Boolean
//   * LastFilesCleanupTime - Date
//   * Process - Boolean
//
Function SearchDirectoryForDeletedFiles(Path)
	Directory = New Structure;
	Directory.Insert("Path", Path);
	
	VolumeTable = New ValueTable;
	VolumeTable.Columns.Add("Ref", New TypeDescription("CatalogRef.FileStorageVolumes"));
	VolumeTable.Columns.Add("LastFilesCleanupTime", New TypeDescription("Date"));
	VolumeTable.Columns.Add("DeletionMark", New TypeDescription("Boolean"));
	
	Directory.Insert("Volumes", VolumeTable);
	Directory.Insert("LastFilesCleanupTime", Date(1,1,1));
	Directory.Insert("Process", True);
	Return Directory;
EndFunction

// Parameters:
//  SearchDirectoryForDeletedFiles - See SearchDirectoryForDeletedFiles
//
Procedure AddVolume(SearchDirectoryForDeletedFiles, Volume)
	// Skip processing of volumes marked for deletion.
	If Volume.DeletionMark <> Undefined And Volume.DeletionMark Then
		SearchDirectoryForDeletedFiles.Process = False;
		Return;
	EndIf;
	
	// Cannot separate deleted files from files in other areas when separation is enabled 
	// and the volumes are shared (volumes are not divided into areas).
	If Common.DataSeparationEnabled() 
			And (ValueIsFilled(Volume.FullPathLinux) And StrFind(Volume.FullPathLinux, "%z") = 0
				Or ValueIsFilled(Volume.FullPathWindows) And StrFind(Volume.FullPathWindows, "%z") = 0) Then
		
		SearchDirectoryForDeletedFiles.Process = False;	
		Return;
	EndIf;
	
	LastFilesCleanupTime = ?(SearchDirectoryForDeletedFiles.LastFilesCleanupTime < Volume.LastFilesCleanupTime,
									Volume.LastFilesCleanupTime,
									SearchDirectoryForDeletedFiles.LastFilesCleanupTime);
	SearchDirectoryForDeletedFiles.LastFilesCleanupTime = LastFilesCleanupTime;
	
	VolumeRow = SearchDirectoryForDeletedFiles.Volumes.Add();
	FillPropertyValues(VolumeRow, Volume);
EndProcedure

// Parameters:
//  Directory - See SearchDirectoryForDeletedFiles
//
Procedure ClearDeletedFilesInTheVolume(Directory)
	If Not Directory.Process Then
		Return;
	EndIf;
	
	TimeOfLastCleaning = Directory.LastFilesCleanupTime;
	RootDirectory1 = Directory.Path;
	
	FilesForDeletion = FilesForDeletion(RootDirectory1, TimeOfLastCleaning);
	
	DeleteVolumesFiles(DeletedFiles(Directory.Volumes, RootDirectory1, FilesForDeletion));
	
	Volume = New Structure("Ref");
	BeginTransaction();
	Try
		Block = New DataLock();
		Item = Block.Add(Metadata.Catalogs.FileStorageVolumes.FullName());
		Item.DataSource = Directory.Volumes;
		Item.UseFromDataSource("Ref", "Ref");
		Block.Lock();
		
		For Each Volume In Directory.Volumes Do
			VolumeObject = Volume.Ref.GetObject();
			VolumeObject.LastFilesCleanupTime = CurrentUniversalDate();
			VolumeObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Error = ErrorInfo();
		WriteLogEvent(NStr("vi = 'Làm việc với tệp.Xóa tệp';
							|ru = 'Работа с файлами.Очистка файлов';
							|en = 'File management.File cleanup'; fa = 'File management.File cleanup';
							|it = 'Lavoro con file. Cancellazione dei file';
							|pl = 'Praca z plikami.Czyszczenie plików';
							|tr = 'Dosya yönetimi.Dosya temizleme'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.FileStorageVolumes,
			Volume.Ref,
			ErrorProcessing.DetailErrorDescription(Error));
	EndTry;

EndProcedure

// Returns deleted files.
// 
// Parameters:
//  Volumes - Array of CatalogRef.FileStorageVolumes
//  RootDirectory1 - String
//  FilesForDeletion - Array of File
// 
// Returns:
//   Array of File
//  
Function DeletedFiles(Volumes, RootDirectory1, FilesForDeletion)
	Result = New Array;
	
	FileSystemProperties = FileSystemProperties(RootDirectory1);
	
	ShouldFixFilePaths = Not FileSystemProperties.HasFilenameLeadingWhitespace
		Or Not FileSystemProperties.HasFilenameTrailingDot;
	
	TableFiles = New ValueTable();
	StringLength = Metadata.Catalogs.Files.Attributes.PathToFile.Type;
	TableFiles.Columns.Add("Path", StringLength);
	
	If ShouldFixFilePaths Then
		TableFiles.Columns.Add("AlternativePath", StringLength);
		TableFiles.Columns.Add("ShouldUseAlternativePath", New TypeDescription("Boolean"));
	EndIf;
	
	For Each File In FilesForDeletion Do
		RelativePath = StrReplace(File, RootDirectory1, "");
		FileString = TableFiles.Add();
		FileString.Path = RelativePath;
		
		If ShouldFixFilePaths Then
			
			FileProperties = New File(RelativePath);
			
			AlternativePath = RelativePath;
			ShouldAddWhitespaceString = False;
			If Not FileSystemProperties.HasFilenameLeadingWhitespace
				And Left(FileProperties.Name, 1) <> " " Then
				AlternativePath = FileProperties.Path + " " + FileProperties.Name;
				ShouldAddWhitespaceString = True;
			EndIf;
			
			ShouldAddDotString = False;
			If Not FileSystemProperties.HasFilenameTrailingDot 
				And FileProperties.Extension = "" Then
				AlternativePath = AlternativePath + ".";
				ShouldAddDotString = True;
			EndIf;
			
			If ShouldAddWhitespaceString Or ShouldAddDotString Then
				FileString = TableFiles.Add();
				FileString.Path = RelativePath;
				FileString.ShouldUseAlternativePath = True;
				FileString.AlternativePath = AlternativePath;
			EndIf;
			
			If ShouldAddWhitespaceString And ShouldAddDotString Then
				FileString = TableFiles.Add();
				FileString.Path = RelativePath;
				FileString.ShouldUseAlternativePath = True;
				FileString.AlternativePath = FileProperties.Path + " " + FileProperties.Name;

				FileString = TableFiles.Add();
				FileString.Path = RelativePath;
				FileString.ShouldUseAlternativePath = True;
				FileString.AlternativePath = RelativePath + ".";
			EndIf;
		EndIf;
	EndDo;
	
	If ShouldFixFilePaths Then
		Query = QueryExistingFilesWithRestoredLinks(TableFiles);
		Query.SetParameter("Volumes", Volumes);
		QueryResults = Query.ExecuteBatch();
		UnnecessaryFiles = QueryResults[QueryResults.UBound() - 1];
		
		FilesToFix = QueryResults[QueryResults.UBound()].Unload();
		SetFilesStoragePaths(FilesToFix, "");
	Else
		Query = RequestToVerifyTheExistenceOfFiles(TableFiles);
		Query.SetParameter("Volumes", Volumes);
		UnnecessaryFiles = Query.Execute();
	EndIf;
	
	Selection = UnnecessaryFiles.Select();
	While Selection.Next() Do
		Result.Add(RootDirectory1 + TrimAll(Selection.Path));
	EndDo;
	
	Return Result;
EndFunction

// File length in the query is limited:
// Metadata name (80) + date (6) + subdirectory to exclude repetition (6) + file name (150).
// Total: 242 characters.
//
Function RequestToVerifyTheExistenceOfFiles(Val TableFiles)
	TableManager = New TempTablesManager();
	Query = New Query("SELECT
	|	CAST(Files.Path AS STRING(1024)) AS Path
	|INTO Files
	|FROM
	|	&Files AS Files");  
	
	Query.TempTablesManager = TableManager;
	Query.SetParameter("Files", TableFiles);
	Query.Execute();
	
	QueryPartsForFoundFiles = New Array;
	
	QueryHeaderForFoundFiles = "SELECT
	|	"""" AS Path
	|INTO ExistingFiles
	|WHERE 
	|	FALSE";
	QueryPartsForFoundFiles.Add(QueryHeaderForFoundFiles);
	
	QueryTemplateForFoundFiles = "
	|SELECT
	|	Files.Path AS Path
	|FROM
	|	Files AS Files
	|	INNER JOIN &AttachedFilesCatalog AS AttachedFiles
	|		ON AttachedFiles.Volume IN (&Volumes)
	|		AND CAST(AttachedFiles.PathToFile AS STRING(1024)) = Files.Path";
	
	AttachedFilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	For Each Type In AttachedFilesTypes Do
		MetadataAttachedFiles = Metadata.FindByType(Type);
		QueryText = StrReplace(QueryTemplateForFoundFiles, "&AttachedFilesCatalog", MetadataAttachedFiles.FullName());
		QueryPartsForFoundFiles.Add(QueryText);
	EndDo;
	
	Separator = "
	|UNION ALL
	|";
	
	QueryText = StrConcat(QueryPartsForFoundFiles, Separator);
	
	QueryText = QueryText + Common.QueryBatchSeparator() + "
	|SELECT 
	|	Files.Path AS Path
	|FROM
	|	Files AS Files
	|WHERE
	|	NOT Files.Path IN (
	|		SELECT
	|			ExistingFiles.Path AS Path
	|		FROM
	|			ExistingFiles AS ExistingFiles)";

	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Return Query;
EndFunction

Function QueryExistingFilesWithRestoredLinks(Val TableFiles)
	TableManager = New TempTablesManager();
	Query = New Query("SELECT
	|	CAST(Files.AlternativePath AS STRING(1024)) AS AlternativePath,
	|	CAST(Files.ShouldUseAlternativePath AS BOOLEAN) AS ShouldUseAlternativePath,
	|	CAST(Files.Path AS STRING(1024)) AS Path
	|INTO Files
	|FROM
	|	&Files AS Files");  
	
	Query.TempTablesManager = TableManager;
	Query.SetParameter("Files", TableFiles);
	Query.Execute();
	
	QueryPartsForFoundFiles = New Array;

	QueryHeaderForFoundFiles = "SELECT
	|	FALSE AS IsAlternativePathUsed,
	|	VALUE(Catalog.Files.EmptyRef) AS Ref,
	|	"""" AlternativePath,
	|	"""" AS Path
	|INTO ExistingFiles
	|WHERE 
	|	FALSE";
	QueryPartsForFoundFiles.Add(QueryHeaderForFoundFiles);

	QueryTemplateForFoundFiles = "
	|SELECT
	|	Files.ShouldUseAlternativePath AS IsAlternativePathUsed,
	|	AttachedFiles.Ref,
	|	Files.AlternativePath,
	|	Files.Path AS Path
	|FROM
	|	Files AS Files
	|	INNER JOIN &AttachedFilesCatalog AS AttachedFiles
	|		ON AttachedFiles.Volume IN (&Volumes)
	|		AND ((NOT Files.ShouldUseAlternativePath AND CAST(AttachedFiles.PathToFile AS STRING(1024)) = Files.Path)
	|			OR (Files.ShouldUseAlternativePath AND CAST(AttachedFiles.PathToFile AS STRING(1024)) = Files.AlternativePath))";
	
	AttachedFilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	For Each Type In AttachedFilesTypes Do
		MetadataAttachedFiles = Metadata.FindByType(Type);
		QueryText = StrReplace(QueryTemplateForFoundFiles, "&AttachedFilesCatalog", MetadataAttachedFiles.FullName());
		QueryPartsForFoundFiles.Add(QueryText);
	EndDo;
	
	Separator = "
	|UNION ALL
	|";
	
	QueryText = StrConcat(QueryPartsForFoundFiles, Separator);
	
	QueryText = QueryText + Common.QueryBatchSeparator() + 
	"SELECT
	|	ExistingFiles.Ref AS File,
	|	ExistingVersionFiles.Ref AS Version
	|INTO VersionFiles
	|FROM
	|	ExistingFiles AS ExistingFiles
	|		INNER JOIN ExistingFiles AS ExistingVersionFiles
	|		ON (CASE
	|				WHEN TYPE(Catalog.FilesVersions) = VALUETYPE(ExistingVersionFiles.Ref)
	|						AND CAST(ExistingVersionFiles.Ref AS Catalog.FilesVersions).Owner = ExistingFiles.Ref
	|					THEN TRUE
	|				ELSE FALSE
	|			END)
	|			AND ExistingFiles.Path = ExistingVersionFiles.Path
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExistingFiles.Path AS Path
	|INTO UniqueLinks
	|FROM
	|	ExistingFiles AS ExistingFiles
	|		LEFT JOIN VersionFiles AS VersionFiles
	|		ON (ExistingFiles.Ref = VersionFiles.File
	|				OR ExistingFiles.Ref = VersionFiles.Version)
	|
	|GROUP BY
	|	ExistingFiles.Path
	|
	|HAVING
	|	SUM(CASE
	|			WHEN ExistingFiles.Ref = ISNULL(VersionFiles.File, ExistingFiles.Ref)
	|				THEN 1
	|			ELSE 0
	|		END) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Files.Path AS Path
	|FROM
	|	Files AS Files
	|WHERE
	|	NOT Files.Path IN
	|				(SELECT
	|					UniqueLinks.Path AS Path
	|				FROM
	|					UniqueLinks AS UniqueLinks)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExistingFiles.Path AS FullName,
	|	ExistingFiles.Ref AS File
	|FROM
	|	ExistingFiles AS ExistingFiles
	|WHERE
	|	ExistingFiles.IsAlternativePathUsed = TRUE
	|	AND ExistingFiles.Path IN
	|			(SELECT
	|				UniqueLinks.Path AS Path
	|			FROM
	|				UniqueLinks AS UniqueLinks)";

	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Return Query;
EndFunction

Function FilesForDeletion(Directory, TimeOfLastCleaning)
	FilesForDeletion = New Array;
	
	CatalogDescription_ = New File(Directory);
	CheckFilesInTheCurrentDirectory = TimeOfLastCleaning <= CatalogDescription_.GetModificationUniversalTime();
	For Each File In FindFiles(Directory, GetAllFilesMask(), False) Do
		If File.IsDirectory() Then
			CommonClientServer.SupplementArray(
				FilesForDeletion,
				FilesForDeletion(File.FullName, TimeOfLastCleaning));
		Else
			If CheckFilesInTheCurrentDirectory And Not File.IsDirectory() Then
				FilesForDeletion.Add(File.FullName);
			EndIf;
		EndIf;
	EndDo;
	
	Return FilesForDeletion;
EndFunction

// It is called before the transaction start.
// All these files must be filled in for new files.
// 
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//
Procedure BeforeUpdatingTheFileData(Context) Export
	Context.AttributesToChange.Insert("PathToFile", "");
	Context.AttributesToChange.Insert("Volume", Catalogs.FileStorageVolumes.EmptyRef());
	Context.AttributesToChange.Insert("FileStorageType", Undefined);
	If Not Context.IsNew Then
		FileStorageTypeChecked = Context.FileAddingOptions.FileStorageType;
		If FileStorageTypeChecked <> Enums.FileStorageTypes.ExternalBinaryDataStorage
				And FileStorageTypeChecked <> Enums.FileStorageTypes.InternalBinaryDataStorage Then
			FileProperties = FilePropertiesInVolume(Context.AttachedFile);
			Context.OldFilePath = FullFileNameInVolume(FileProperties);
		EndIf;
	EndIf;
	
	FilePropertiesContainer = FileAddingOptions();
	FilePropertiesContainer.Ref = Context.AttachedFile;
	FillPropertyValues(FilePropertiesContainer, Context.FileAddingOptions,,"Ref");
	FilePropertiesContainer.PathToFile = ""; // Always create a new version in the volume without overwriting the old one.
	
	SetSafeModeDisabled(True);
	AppendFile(FilePropertiesContainer, Context.FileData,,,FilePropertiesContainer.Volume);
	SetSafeModeDisabled(False);

	Context.AttributesToChange.PathToFile = FilePropertiesContainer.PathToFile;
	Context.AttributesToChange.Volume = FilePropertiesContainer.Volume;
	Context.AttributesToChange.FileStorageType = FilePropertiesContainer.FileStorageType;
EndProcedure

// It is called in a modification transaction.
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  AttachedFile - DefinedType.AttachedFileObject
//
Procedure BeforeWritingFileData(Context, AttachedFile) Export
	FillPropertyValues(AttachedFile, Context.AttributesToChange);
EndProcedure

// It is called in a modification transaction.
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  AttachedFile - DefinedType.AttachedFile
//
Procedure WhenUpdatingFileData(Context, AttachedFile) Export
	Return; // Obsolete.
EndProcedure

// It is called after the transaction is committed or rolled back.
// 
// Parameters:
//  Context - See FilesOperationsInternal.FileUpdateContext
//  Success - Boolean - True if the transaction is successfully committed.
//
Procedure AfterUpdatingTheFileData(Context, Success) Export
	If Not Success Then
		FileProperties = FilePropertiesInVolume();
		FillPropertyValues(FileProperties, Context.FileAddingOptions);
		FillPropertyValues(FileProperties, Context.AttributesToChange);
		NewFilePath = FullFileNameInVolume(FileProperties);
		DeletedFile = New File(NewFilePath);
		If DeletedFile.Exists() Then
			DeleteFile(NewFilePath);			
		EndIf;
		Return;
	EndIf;

	AttachedFile = Context.AttachedFile;
	ThisIsTheVersion = TypeOf(AttachedFile) = Type("CatalogRef.FilesVersions");
	MainFile = ?(ThisIsTheVersion, Common.ObjectAttributeValue(AttachedFile, "Owner"), AttachedFile);
	ThisIsAnEncryptedFile = Common.HasObjectAttribute("Encrypted", MainFile.Metadata())
		And Common.ObjectAttributeValue(MainFile, "Encrypted");
		
	// Always try to delete the old file if it's encrypted (the external transactions is active).
	//  
	// See FilesOperationsInternal.WriteEncryptionInformation
	If ThisIsAnEncryptedFile Or Not TransactionActive() Then
		
		FileProperties = FilePropertiesInVolume(AttachedFile);
		NewFilePath = FullFileNameInVolume(FileProperties);
		
		If NewFilePath <> Context.OldFilePath Then
			SetSafeModeDisabled(True);
			DeleteFile(Context.OldFilePath);
		EndIf;
	EndIf;

EndProcedure

// Parameters:
//  FilesForDeletion - Array of String - Full file path.
// 
// Returns:
//  Structure:
//   * Total - Number
//   * Deleted - Number
//   * DeletionErrors - Array of Structure:
//   * Error - String - Error details.
//   * Name - String - Filename.
// 
Function DeleteVolumesFiles(FilesForDeletion) Export
	Result = New Structure;
	Result.Insert("Total", FilesForDeletion.Count());
	Result.Insert("Deleted", 0);
	Result.Insert("DeletionErrors", New Array);
	
	For Each File In FilesForDeletion Do
		DeletionResult = DeleteFile(File);
		If DeletionResult.Success Then
			Result.Deleted = Result.Deleted + 1;
		Else
			Error = New Structure;
			Error.Insert("Error", DeletionResult.ErrorInfo);
			Error.Insert("Name", DeletionResult.Name);
			Result.DeletionErrors.Add(Error);
		EndIf; 
	EndDo;
	
	Return Result;
EndFunction

#Region FilesStorageInVolumesSettings

// Returns a flag that files can be stored in volumes and in the infobase.
//
// Returns:
//   Boolean
//
Function ShouldStoreFilesInVolumesAndInfobase()
	
	SetPrivilegedMode(True);
	Return Constants.FilesStorageMethod.Get() = "InInfobaseAndVolumesOnHardDrive";
	
EndFunction

// Returns a flag that files in volumes are stored in subdirectories with the owner name.
//
// Returns:
//   Boolean
//
Function CreateSubdirectoriesWithOwnersNames()
	
	SetPrivilegedMode(True);
	Return Constants.CreateSubdirectoriesWithOwnersNames.Get();
	
EndFunction

#EndRegion

#Region DataExchange

// Puts the binary file data from the volume into internal attribute FileStorage.
//
// Parameters:
//   DataElement - CatalogObject.FilesVersions
//                 - DefinedType.AttachedFile
// 
Procedure PutFileInCatalogAttribute(DataElement) Export
	
	FileData = FileData(DataElement.Ref, False);
	
	DataElement.Volume = Catalogs.FileStorageVolumes.EmptyRef();
	DataElement.PathToFile = "";
	DataElement.FileStorage = New ValueStorage(FileData, New Deflation(9));
	DataElement.FileStorageType = Enums.FileStorageTypes.InInfobase;
	
EndProcedure

// Adds files to volumes and sets references in FileVersions.
//
Procedure AddFilesToVolumes(WindowsArchivePath, PathToArchiveLinux) Export
	
	FullFileNameZip = "";
	If Common.IsWindowsServer() Then
		FullFileNameZip = WindowsArchivePath;
	Else
		FullFileNameZip = PathToArchiveLinux;
	EndIf;
	
	DirectoryName = FileSystem.CreateTemporaryDirectory();
	CreateDirectory(DirectoryName);
	
	ZipFile = New ZipFileReader(FullFileNameZip);
	ZipFile.ExtractAll(DirectoryName, ZIPRestoreFilePathsMode.DontRestore);
	
	FilesPathsMap = New Map;
	
	For Each ZIPItem In ZipFile.Items Do
		FullFilePath1 = DirectoryName + "\" + ZIPItem.Name;
		// For filename generation, See FilesOperationsInternal.
		CatalogUUID = ZIPItem.Name;
		
		FilesPathsMap.Insert(CatalogUUID, FullFilePath1);
	EndDo;
	
	BeginTransaction();
	Try
		AddFilesToVolumesOnPlace(FilesPathsMap, FilesOperationsInternal.FilesStorageTyoe());
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	FileSystem.DeleteTemporaryDirectory(DirectoryName);
	
EndProcedure

// Adds a file to volumes when executing the "store initial image files" command.
//
// Parameters:
//   FilesPathsMap - Map - mapping of the UUID of the file and the path to the file.
//   FileStorageType        - EnumRef.FileStorageTypes - file storage type.
//
Procedure AddFilesToVolumesOnPlace(FilesPathsMap, FileStorageType)
		
	For Each FileInformationPath In FilesPathsMap Do
		
		FullPathNew = "";
		FileInfo1 = FileInformationFromTheName(FileInformationPath.Key);
		If Not FileInfo1.Full_ Then
			Continue;
		EndIf;
		
		FileRef = Catalogs[FileInfo1.CatalogName].GetRef(FileInfo1.UUID);
		If FileRef.IsEmpty() Then
			Continue;
		EndIf;
		
		FullFilePathInVolume = FileInformationPath.Value;
		
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("Catalog." + FileInfo1.CatalogName);
			DataLockItem.SetValue("Ref", FileRef);
			DataLock.Lock();
			
			Object = FileRef.GetObject(); // DefinedType.AttachedFileObject

			BinaryData = New BinaryData(FullFilePathInVolume);

			FileArchiveManagementServer.FillFileStorageParameters(Object, BinaryData, Object.Size, Object.Extension);

			If FileManagementInBinaryDataStorageInternal.StorageTypeDoesNotUseDisks(Object.FileStorageType) Then

				// In the destination, files must be stored within the infobase.
				// Therefore, save them to the infobase even if originally they are stored in volumes.

				RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(Object);
				FilesOperationsInternal.WriteFileToInfobase(Object.Ref, BinaryData, RecordingParametersVIB);

			Else
				
				// In the destination base, files must be stored in volumes. Move the unzipped file to the volume.
				FileSource = New File(FullFilePathInVolume);
				FileName = CommonClientServer.GetNameWithExtension(Object.Description, Object.Extension);
				Common.ShortenFileName(FileName);
				FullPathNew = FileSource.Path + FileName;
				MoveFile(FullFilePathInVolume, FullPathNew);

				AppendFile(Object, FullPathNew,,,Object.Volume);

			EndIf;
			
			Object.AdditionalProperties.Insert("FilePlacementInVolumes", True); // Intended to successfully write signed files.
			InfobaseUpdate.WriteObject(Object);
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
		EndTry;
		
		If Not IsBlankString(FullPathNew) Then
			DeleteFiles(FullPathNew);
		EndIf;

	EndDo;
	
EndProcedure

Function FileInformationFromTheName(FileName)
	FileInfo1 = New Structure;
	FileInfo1.Insert("CatalogName", "");
	FileInfo1.Insert("UUID", "");
	FileInfo1.Insert("Full_", False);
	
	NameParts = StrSplit(FileName, ".");
	If NameParts.Count() = 2 Then
		CatalogName = NameParts[0];
		FileInfo1.CatalogName = ?(Metadata.Catalogs.Find(CatalogName) = Undefined, "", CatalogName);
		FileInfo1.UUID = New UUID(NameParts[1]);
		FileInfo1.Full_ = ValueIsFilled(FileInfo1.CatalogName) And ValueIsFilled(FileInfo1.UUID);
	EndIf;
		
	Return FileInfo1;
EndFunction

#EndRegion

#Region CleanUpUnusedFiles

// Constructor of a table with unreferenced  files in volumes.
// 
// Returns:
//   ValueTable:
//      * Name                - String
//      * File               - String
//      * BaseName   - String
//      * FullName          - String
//      * Path               - String
//      * Volume                - String
//      * Extension         - String
//      * CheckStatus     - String - "OK", "UnnecessaryFileInVolume", "NoFileInVolume", "FixingPossible"
//      * Count         - String
//      * WasEditedBy     - String
//      * EditDate - String
//
Function UnnecessaryFilesInVolume() Export
	Result = New ValueTable;
	
	Result.Columns.Add("Name");
	Result.Columns.Add("File");
	Result.Columns.Add("BaseName");
	Result.Columns.Add("FullName");
	Result.Columns.Add("Path");
	Result.Columns.Add("Volume");
	Result.Columns.Add("Extension");
	Result.Columns.Add("CheckStatus");
	Result.Columns.Add("Count");
	Result.Columns.Add("WasEditedBy");
	Result.Columns.Add("EditDate");

	Result.Indexes.Add("FullName");
	Result.Indexes.Add("CheckStatus");
	
	Return Result;
EndFunction

// Parameters:
//   TableOfFilesInVolume - See FilesOperationsInVolumesInternal.UnnecessaryFilesInVolume
//   Volume                  - CatalogRef.FileStorageVolumes - volume reference.
//
Procedure FillInExtraFiles(TableOfFilesInVolume, Volume) Export
	
	FilesTypes = Metadata.DefinedTypes.AttachedFile.Type.Types();
	
	Query = New Query;
	FirstRequestText = True;
	For Each CatalogFiles_ In FilesTypes Do
		
		CatalogMetadata = Metadata.FindByType(CatalogFiles_);
		IsVersionsCatalog = Common.HasObjectAttribute("ParentVersion", CatalogMetadata);
		
		QueryFragment = 
		"SELECT
		|	CatalogAttachedFiles.Ref,
		|	&FileOwner AS FileOwner,
		|	CatalogAttachedFiles.Extension,
		|	CatalogAttachedFiles.Description,
		|	CatalogAttachedFiles.Volume,
		|	&WasEditedBy AS WasEditedBy,
		|	CatalogAttachedFiles.UniversalModificationDate AS FileModificationDate,
		|	CatalogAttachedFiles.PathToFile,
		|	CatalogAttachedFiles.DeletionMark
		|FROM
		|	&CatalogAttachedFiles AS CatalogAttachedFiles
		|WHERE
		|	CatalogAttachedFiles.Volume = &Volume
		|	AND CatalogAttachedFiles.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
		|	AND &ConditionCurrentVersion";
		
		QueryFragment = StrReplace(QueryFragment, "&FileOwner", 
			"CatalogAttachedFiles." + ?(IsVersionsCatalog, "Owner.FileOwner", "FileOwner"));
		QueryFragment = StrReplace(QueryFragment, "&WasEditedBy", 
			"CatalogAttachedFiles." + ?(IsVersionsCatalog, "Author", "ChangedBy"));
		QueryFragment = StrReplace(QueryFragment, "&CatalogAttachedFiles", 
			"Catalog." + CatalogMetadata.Name);
		
		If Not IsVersionsCatalog
			And Common.HasObjectAttribute("CurrentVersion", CatalogMetadata) Then
			
			FilesVersionsCatalog = Metadata.FindByType(
				CatalogMetadata.Attributes.CurrentVersion.Type.Types()[0]);
			QueryFragment = StrReplace(QueryFragment, "&ConditionCurrentVersion",
				"CatalogAttachedFiles.CurrentVersion = VALUE(Catalog."
				+ FilesVersionsCatalog.Name + ".EmptyRef)");
			
		Else
			QueryFragment = StrReplace(QueryFragment, "&ConditionCurrentVersion", "TRUE");
		EndIf;
		
		Query.Text = Query.Text + ?(FirstRequestText,"", "
			|UNION ALL
			|") + QueryFragment;
		
		FirstRequestText = False;
		
	EndDo;
	
	Query.SetParameter("Volume", Volume);
	Selection = Query.Execute().Select();
	
	FileProperties = FilePropertiesInVolume();
	FileProperties.Volume = Volume; 
	
	FullVolumePath = FullVolumePath(Volume);
	VolumeFileSystemProperties =  FileSystemProperties(FullVolumePath);
	
	While Selection.Next() Do
		
		VersionRef = Selection.Ref;
		PathToFile   = Selection.PathToFile;
		
		If ValueIsFilled(Selection.PathToFile)
			And ValueIsFilled(Selection.Volume) Then
			
			FileProperties.PathToFile = PathToFile;
			
			FullFilePath1 = FullFileNameInVolume(FileProperties);
			ExistingFile = TableOfFilesInVolume.FindRows(New Structure("FullName", FullFilePath1));
			
			ShouldSearchUsingAlternativePath = False;
			
			If ExistingFile.Count() = 0 And (Not VolumeFileSystemProperties.HasFilenameTrailingDot
				Or Not VolumeFileSystemProperties.HasFilenameLeadingWhitespace) Then
				
				If Not VolumeFileSystemProperties.HasFilenameTrailingDot And Right(PathToFile, 1) = "." Then
					PathToFile = Left(PathToFile, StrLen(PathToFile)-1);
				EndIf;
				
				If Not VolumeFileSystemProperties.HasFilenameLeadingWhitespace 
					And StrFind(PathToFile, GetPathSeparator()+" ") > 0 Then
					FileParameters = New File(PathToFile);
					PathToFile = FileParameters.Path+TrimAll(FileParameters.Name);
				EndIf;
				
				If Selection.PathToFile <> PathToFile Then
					FileProperties.PathToFile = PathToFile;
				
					FullFilePath1 = FullFileNameInVolume(FileProperties);
					ExistingFile = TableOfFilesInVolume.FindRows(New Structure("FullName", FullFilePath1));
					ShouldSearchUsingAlternativePath = True;
				EndIf;
			EndIf;
			
			If ExistingFile.Count() = 0 Then
				NonExistingFile = TableOfFilesInVolume.Add();
				NonExistingFile.File = VersionRef;
				NonExistingFile.FullName = FullFilePath1;
				NonExistingFile.Extension = Selection.Extension;
				NonExistingFile.Name = Selection.Description;
				NonExistingFile.Volume = Volume;
				NonExistingFile.WasEditedBy = Selection.WasEditedBy;
				NonExistingFile.EditDate = Selection.FileModificationDate;
				NonExistingFile.Count = 1;
				NonExistingFile.CheckStatus = ?(Selection.DeletionMark, "OK", "NoFileInVolume");
			ElsIf ShouldSearchUsingAlternativePath Then
				ExistingFile[0].File = VersionRef;
				ExistingFile[0].CheckStatus = "FixingPossible";
				ExistingFile[0].EditDate = Selection.FileModificationDate;
				ExistingFile[0].Count = 1;
				ExistingFile[0].WasEditedBy = Selection.WasEditedBy;
			Else
				ExistingFile[0].File = VersionRef;
				ExistingFile[0].CheckStatus = "OK";
			EndIf;
			
		EndIf;
		
	EndDo;

EndProcedure

// For the VolumeIntegrityCheck DCS report.
Function ViewStatusChecks(Val CheckStatus) Export
	If CheckStatus = "OK" Then
		Return NStr("vi = 'Dữ liệu toàn vẹn';
					|ru = 'Целостные данные';
					|en = 'Data integrity check passed'; fa = 'Data integrity check passed';
					|it = 'Dati integri';
					|pl = 'Holistyczne dane';
					|tr = 'Bütünsel veriler'");
	ElsIf CheckStatus = "ExtraFileInTome" Then 
		Return NStr("vi = 'Tệp thừa (có trong quyển, nhưng không có thông tin về chúng)';
					|ru = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
					|en = 'Unreferenced files (files in the volume that have no entries in the application)'; fa = 'Unreferenced files (files in the volume that have no entries in the application)';
					|it = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
					|pl = 'Unreferenced files (files in the volume that have no entries in the application)';
					|tr = 'Fazlalık dosyalar (birimde mevcut, ancak haklarında bilgi yok)'");
	ElsIf CheckStatus = "NoFileInVolume" Then
		Return NStr("vi = 'Không có tệp trong quyển';
					|ru = 'Отсутствуют файлы в томе';
					|en = 'No files in the volume'; fa = 'No files in the volume';
					|it = 'Отсутствуют файлы в томе';
					|pl = 'No files in the volume';
					|tr = 'Birimde dosya yok'");
	ElsIf CheckStatus = "FixingPossible" Then
		Return NStr("vi = 'Hỏng thông tin về tệp';
					|ru = 'Поврежденные сведения о файлах';
					|en = 'Corrupted file info'; fa = 'اطلاعات فایل خراب';
					|it = 'Поврежденные сведения о файлах';
					|pl = 'Corrupted file info';
					|tr = 'Hasarlı dosya bilgileri'");
	EndIf;
EndFunction

#EndRegion

#Region AccountingAudit

Function AvailableVolumes(CheckParameters = Undefined) Export
	
	Query = New Query(
	"SELECT
	|	FileStorageVolumes.Ref AS VolumeRef,
	|	FileStorageVolumes.Description AS VolumePresentation,
	|	CASE
	|		WHEN &IsWindowsServer
	|			THEN FileStorageVolumes.FullPathWindows
	|		ELSE FileStorageVolumes.FullPathLinux
	|	END AS FullPath
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.StorageVolumeType = VALUE(Enum.StorageKinds.OperationalStorage)
	|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.NetworkDirectories)");
	Query.SetParameter("IsWindowsServer", Common.IsWindowsServer());
	Result = Query.Execute().Select();
	
	AvailableVolumes = New Array;
	While Result.Next() Do
		
		If VolumeAvailable(Result.VolumeRef, Result.VolumePresentation, Result.FullPath, CheckParameters) Then
			AvailableVolumes.Add(Result.VolumeRef);
		EndIf;
		
	EndDo;
	
	Return AvailableVolumes;
	
EndFunction

Function VolumeAvailable(Volume, VolumePresentation, Path, CheckParameters)
	
	If IsBlankString(Path) Then
		
		IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong quyển lưu tệp ""%1"" chưa xác định đường dẫn đến thư mục mạng. Không thể lưu tệp vào đó.';
				|ru = 'У тома хранения файлов ""%1"" не задан путь к сетевому каталогу. Сохранение файлов в него невозможно.';
				|en = 'Couldn''t save files to file storage volume ""%1"" as it does not have a path to the network directory.'; fa = 'Couldn''t save files to file storage volume ""%1"" as it does not have a path to the network directory.';
				|it = 'Nel tomo di archiviazione dei file ""%1"" non è indicato il path alla directory di rete. Il salvataggio di file in essa non è possibile.';
				|pl = 'W woluminie przechowywania plików ""%1"" nie określono ścieżkę do sieciowego katalogu. Zapisywanie plików w niego jest niemożliwe.';
				|tr = 'Dosya depolama birimin ""%1"" ağ kataloğu kısayolu bulunamadı. Dosyaların depolanması mümkün değil.'"), 
			VolumePresentation);
		WriteVolumeIssue(Volume, IssueSummary, CheckParameters);
		Return False;
		
	EndIf;
		
	TestDirectoryName = Path + "CheckAccess" + GetPathSeparator();
	
	Try
		CreateDirectory(TestDirectoryName);
		DeleteFiles(TestDirectoryName);
	Except
		
		IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quyển lưu tệp ""%1"" không khả dụng do: 
				|%2
				|
				|Thư mục mạng được chỉ định có thể đã bị ngắt kết nối hoặc thiếu quyền truy cập.
				|Không thể làm việc với tất cả các tệp được lưu trữ trên ổ đĩa này.';
				|ru = 'Том хранения файлов ""%1"" недоступен по причине: 
				|%2
				|
				|Указанный сетевой каталог мог быть отключен или к нему отсутствуют права доступа.
				|Невозможна работа со всеми файлами, хранящимися в этом томе.';
				|en = 'File storage volume ""%1"" is unavailable. Reason:
				|%2
				|
				|The network directory might be unavailable, or you have insufficient access rights.
				|Cannot access the files stored in the volume.'; fa = 'File storage volume ""%1"" is unavailable. Reason:
				|%2
				|
				|The network directory might be unavailable, or you have insufficient access rights.
				|Cannot access the files stored in the volume.';
				|it = 'Il tomo di archiviazione dei file ""%1"" non è disponibile a causa di: 
				|%2
				|
				|Il catalogo di rete indicato potrebbe essere scollegato oppure si potrebbe non disporre di diritti sufficienti per accedervi.
				|È impossibile lavorare con tutti i file archiviati in questo tomo.';
				|pl = 'Wolumin przechowywania plików ""%1"" jest niedostępny z powodu: 
				|%2
				|
				|Podany w folder sieciowy mógł być wyłączony lub brak do niego prawa dostępu.
				|Nie jest możliwa praca ze wszystkimi plikami znajdującymi się w tym woluminie.';
				|tr = 'Dosya depolama birimi ""%1"" nedeniyle kullanılamaz: 
				|%2
				|
				|belirtilen ağ dizini devre dışı bırakılabilir veya erişim hakları yoktur. 
				|Bu birimde depolanan tüm dosyalarla çalışmak imkansızdır.'"),
				Path, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		IssueSummary = IssueSummary + Chars.LF;
		WriteVolumeIssue(Volume, IssueSummary, CheckParameters);
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure WriteVolumeIssue(Volume, IssueSummary, CheckParameters)
	
	If CheckParameters = Undefined Then
		Return;
	EndIf;
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	Issue1 = ModuleAccountingAudit.IssueDetails(Volume, CheckParameters);
	Issue1.IssueSummary = IssueSummary;
	ModuleAccountingAudit.WriteIssue(Issue1, CheckParameters);
	
EndProcedure

Procedure SearchRefsToNonExistingFilesInVolumes(MetadataObject, CheckParameters, AvailableVolumes)
	
	ModuleAccountingAudit = Common.CommonModule("AccountingAudit");
	
	QueryText =
	"SELECT TOP 1000
	|	MetadataObject.Ref AS ObjectWithIssue,
	|	&OwnerField AS Owner,
	|	REFPRESENTATION(MetadataObject.Ref) AS File,
	|	REFPRESENTATION(MetadataObject.Volume) AS Volume,
	|	MetadataObject.PathToFile AS PathToFile,
	|	MetadataObject.Volume AS VolumeRef1,
	|	MetadataObject.FileStorage AS FileStorage,
	|	&Author AS Author
	|FROM
	|	&MetadataObject AS MetadataObject
	|WHERE
	|	MetadataObject.Ref > &Ref
	|	AND MetadataObject.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
	|	AND MetadataObject.Volume IN(&AvailableVolumes)
	|
	|ORDER BY
	|	MetadataObject.Ref";
	
	FullName = MetadataObject.FullName();
	FullFileVersionName = Metadata.Catalogs.FilesVersions.FullName();
	QueryText = StrReplace(QueryText, "&MetadataObject", FullName);
	QueryText = StrReplace(QueryText, "&Author", 
		?(MetadataObject.Attributes.Find("Author") <> Undefined, "MetadataObject.Author", "NULL"));
		
	OwnerField = ?(FullName = FullFileVersionName, "REFPRESENTATION(MetadataObject.Owner) ","UNDEFINED "); //  @query-part-1, @query-part-2
	QueryText = StrReplace(QueryText, "&OwnerField", OwnerField);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Common.ObjectManagerByFullName(FullName).EmptyRef());
	Query.SetParameter("AvailableVolumes", AvailableVolumes);
	Result = Query.Execute().Unload();
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			If Not ValueIsFilled(ResultString1.VolumeRef1) Then
				Continue;
			EndIf;
			
			If Not ValueIsFilled(ResultString1.PathToFile) Then
				If ResultString1.Owner <> Undefined Then
					IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong phiên bản ""%1"" của tệp  ""%2"" chưa chỉ ra đường dẫn đầy đủ đến tệp trong quyển ""%3"".';
							|ru = 'У версии ""%1"" файла ""%2"" не указан полный путь к файлу в томе ""%3"".';
							|en = 'Full path to version %1 of file %2 is not specified in volume %3.'; fa = 'Full path to version %1 of file %2 is not specified in volume %3.';
							|it = 'Full path to version %1 of file %2 is not specified in volume %3.';
							|pl = 'Full path to version %1 of file %2 is not specified in volume %3.';
							|tr = '""%2"" dosyasının ""%1"" sürümünde, ""%3"" birimindeki dosyaya tam yolu gösterilmemiş.'"),
						ResultString1.File, ResultString1.Owner, ResultString1.Volume);
				Else
					IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong tệp ""%1"" chưa chỉ ra đường dẫn đầy đủ đến tệp trong quyển ""%2"".';
							|ru = 'У файла ""%1"" не указан полный путь к файлу в томе ""%2"".';
							|en = 'Full path to file %1 is not specified in volume %2.'; fa = 'Full path to file %1 is not specified in volume %2.';
							|it = 'Full path to file %1 is not specified in volume %2.';
							|pl = 'Full path to file %1 is not specified in volume %2.';
							|tr = '""%1"" dosyasında, ""%2"" birimindeki dosyaya tam yolu gösterilmemiş.'"),
						ResultString1.File, ResultString1.Volume);
				EndIf;
				
				RegisterNonExistentFileInVolume(ModuleAccountingAudit, CheckParameters,
					ResultString1, IssueSummary);
			EndIf;
			
			If TypeOf(ResultString1.FileStorage) = Type("ValueStorage")
				And ResultString1.FileStorage.Get() <> Undefined Then

				If ResultString1.Owner <> Undefined Then
					IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong phiên bản ""%1"" của tệp ""%2"" được lưu trong quyển ""%3"" có dữ liệu nhị phân dư thừa trong cơ sở dữ liệu thông tin.';
							|ru = 'У версии ""%1"" файла ""%2"", хранящегося в томе ""%3"", избыточно хранятся двоичные данные в информационной базе.';
							|en = 'The infobase retains redundant binary data of version %1 of file %2 stored in volume %3.'; fa = 'The infobase retains redundant binary data of version %1 of file %2 stored in volume %3.';
							|it = 'The infobase retains redundant binary data of version %1 of file %2 stored in volume %3.';
							|pl = 'The infobase retains redundant binary data of version %1 of file %2 stored in volume %3.';
							|tr = '""%3"" biriminde kaydedilen ""%2"" dosyasının ""%1"" sürümü, infobase''de kaydedilen gereksiz mükerrer verilere sahiptir.'"),
						ResultString1.File, ResultString1.Owner, ResultString1.Volume);
				Else
					IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong tệp ""%1"" được lưu trong quyển ""%2"" có dữ liệu nhị phân dư thừa trong cơ sở dữ liệu thông tin.';
							|ru = 'У файла ""%1"", хранящегося в томе ""%2"", избыточно хранятся двоичные данные в информационной базе.';
							|en = 'The infobase retains redundant binary data of file %1 stored in volume %2.'; fa = 'The infobase retains redundant binary data of file %1 stored in volume %2.';
							|it = 'The infobase retains redundant binary data of file %1 stored in volume %2.';
							|pl = 'The infobase retains redundant binary data of file %1 stored in volume %2.';
							|tr = '""%2"" biriminde kaydedilen ""%1"" dosyası, infobase''de kaydedilen gereksiz mükerrer verilere sahiptir.'"),
						ResultString1.File, ResultString1.Volume);
				EndIf;
				
				RegisterNonExistentFileInVolume(ModuleAccountingAudit, CheckParameters,
					ResultString1, IssueSummary);
			EndIf;
			
			If Not ValueIsFilled(ResultString1.PathToFile) Then
				Continue;
			EndIf;
			
			FullVolumePath = FullVolumePath(ResultString1.VolumeRef1);
			PathToFile = FullVolumePath + ResultString1.PathToFile;
			FileToCheck = New File(PathToFile);
			If FileToCheck.Exists() Then
				Continue;
			EndIf;
				
			If ResultString1.Owner <> Undefined Then
				IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Phiên bản ""%1"" của tệp ""%2"" không tồn tại trong quyển ""%3 (%4).';
						|ru = 'Версия ""%1"" файла ""%2"" не существует в томе ""%3"" (%4).';
						|en = 'Version ""%1"" of file ""%2"" does not exist in volume ""%3"" (%4).'; fa = 'Version ""%1"" of file ""%2"" does not exist in volume ""%3"" (%4).';
						|it = 'Version ""%1"" of file ""%2"" does not exist in volume ""%3"" (%4).';
						|pl = 'Version ""%1"" of file ""%2"" does not exist in volume ""%3"" (%4).';
						|tr = '""%2"" dosyasının ""%1"" sürümü ""%3"" (%4) biriminde mevcut değil.'"),
					ResultString1.File, ResultString1.Owner, ResultString1.Volume,
					PathToFile);
			Else
				IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không tồn tại tệp ""%1"" trong quyển ""%2"" (%3).';
						|ru = 'Файл ""%1"" не существует в томе ""%2"" (%3).';
						|en = 'File ""%1"" does not exist in volume ""%2"" (%3).'; fa = 'File ""%1"" does not exist in volume ""%2"" (%3).';
						|it = 'File ""%1"" does not exist in volume ""%2"" (%3).';
						|pl = 'File ""%1"" does not exist in volume ""%2"" (%3).';
						|tr = 'Dosya ""%1"" ""%2"" (%3) biriminde mevcut değil.'"),
					ResultString1.File, ResultString1.Volume, PathToFile);
			EndIf;
			
			RegisterNonExistentFileInVolume(ModuleAccountingAudit, CheckParameters,
				ResultString1, IssueSummary);
			
		EndDo;
		
		Query.SetParameter("Ref", ResultString1.ObjectWithIssue);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - Batch data processing
		
	EndDo;
	
EndProcedure

Procedure RegisterNonExistentFileInVolume(ModuleAccountingAudit, CheckParameters,
	ResultString1, IssueSummary)
	
	Issue1 = ModuleAccountingAudit.IssueDetails(ResultString1.ObjectWithIssue, CheckParameters);
	Issue1.IssueSummary = IssueSummary;
	If ValueIsFilled(ResultString1.Author) Then
		Issue1.Insert("EmployeeResponsible", ResultString1.Author);
	EndIf;
	
	ModuleAccountingAudit.WriteIssue(Issue1, CheckParameters);
	
EndProcedure

Function CheckAttachedFilesObject(MetadataObject)
	
	If StrEndsWith(MetadataObject.Name, FilesOperationsInternal.CatalogSuffixAttachedFiles())
		Or MetadataObject.FullName()= "Catalog.FilesVersions" 
		Or MetadataObject.FullName()= "Catalog.Files" Then
		
		Return MetadataObject.Attributes.Find("PathToFile") <> Undefined
			And MetadataObject.Attributes.Find("Volume") <> Undefined;
		
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.SharedData = True;
	Handler.Procedure = "FilesOperationsInVolumesInternal.SetTheWayToFormTheVolumePath";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.SharedData = True;
	Handler.Procedure = "FilesOperationsInVolumesInternal.UpdateVolumePathLinux";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.2.65";
	Handler.SharedData = True;
	Handler.Procedure = "FilesOperationsInVolumesInternal.FillFilesStorageSettings";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.11.80";
	Handler.Procedure = "Catalogs.FilesVersions.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.Comment = NStr("vi = 'Chỉnh sửa sai đường dẫn lưu trữ tệp trong các ổ đĩa, đồng thời xóa bỏ dữ liệu nhị phân dư thừa trong các phiên bản tệp.';
							|ru = 'Исправляет ошибочные пути хранения файлов в томах, а также удаление избыточные двоичных данных в версиях файлов.';
							|en = 'Fixes invalid file storage paths in volumes and removes redundant binary data in file versions.'; fa = 'Fixes invalid file storage paths in volumes and removes redundant binary data in file versions.';
							|it = 'Fixes invalid file storage paths in volumes and removes redundant binary data in file versions.';
							|pl = 'Fixes invalid file storage paths in volumes and removes redundant binary data in file versions.';
							|tr = 'Birimlerdeki hatalı dosya kaydetme yollarını düzeltir ve dosya sürümlerindeki gereksiz mükerrer verileri siler.'");
	Handler.Id = New UUID("06354049-b702-4f27-8e99-f49b86f7f152");
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "Catalog.FilesVersions";
	Handler.UpdateDataFillingProcedure = "Catalogs.FilesVersions.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead = "Catalog.FilesVersions";
	Handler.ObjectsToChange = "Catalog.FilesVersions";
	Handler.Multithreaded = True;
	
EndProcedure

// Sets the FilesStorageMethod constant value depending on the StoreFilesInVolumesOnHardDrive constant
// value and initializes the ParametersOfFilesStorageInIB constant.
//
Procedure FillFilesStorageSettings() Export
	
	Constants.FilesStorageMethod.Set(
		?(Constants.StoreFilesInVolumesOnHardDrive.Get(),
		"InVolumesOnHardDrive", "InInfobase"));
		
	SetFilesStorageParametersInInfobase(
		New Structure("FilesExtensions, MaximumSize", "", 0));
	
EndProcedure

Procedure UpdateVolumePathLinux() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FileStorageVolumes.Ref
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	FileStorageVolumes.FullPathLinux LIKE ""%/\"" ESCAPE ""~""";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("Catalog.FileStorageVolumes");
			DataLockItem.SetValue("Ref", Selection.Ref);
			DataLock.Lock();
			
			Volume = Selection.Ref.GetObject(); // CatalogObject.FileStorageVolumes
			Volume.FullPathLinux = StrReplace(Volume.FullPathLinux , "/\", "/");
			Volume.Write();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý quyển lưu tệp %1 do nguyên nhân:
				|%2';
				|ru = 'Не удалось обработать том хранения файлов %1 по причине:
				|%2';
				|en = 'Couldn''t process file storage volume %1. Reason:
				|%2'; fa = 'Couldn''t process file storage volume %1. Reason:
				|%2';
				|it = 'Non è stato possibile elaborare il tomo di salvataggio dei file %1 a causa di:
				|%2';
				|pl = 'Nie udało się przetworzyć wolumin przechowywania plików %1 z powodu:
				|%2';
				|tr = '%1dosya depolama birimi şu sebeple işlenemedi:
				|%2'"), 
				Selection.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Warning,
				Selection.Ref.Metadata(), Selection.Ref, MessageText);
			
		EndTry;
		
	EndDo;
	
EndProcedure

// For the function, See FullVolumePath
//
Procedure SetTheWayToFormTheVolumePath() Export
	Constants.VolumePathIgnoreRegionalSettings.Set(True);
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

// Returns the name of the subdirectory in the volume by the file owner type.
// The subdirectory name is generated as a concatenation of the first 30 characters of the name
// of the file owner metadata object + CRC32 hash from the remaining characters.
//
// Parameters:
//   FileOwner - DefinedType.AttachedFilesOwner
//                 - DefinedType.FilesOwner - reference to
//                 the file owner whose metadata is used to form the subdirectory name.
//
// Returns:
//   String - a directory name.
//
Function FileOwnerDirectoryName(FileOwner)
	
	If Not ValueIsFilled(FileOwner) Then
		Return "";
	EndIf;
	
	MetadataObjectName = FileOwner.Metadata().Name;
	If StrLen(MetadataObjectName) > 30 Then
		RemainderHash = New DataHashing(HashFunction.CRC32);
		RemainderHash.Append(Mid(MetadataObjectName, 31));
		RemainderHashSum = RemainderHash.HashSum;
	Else
		RemainderHashSum = "";
	EndIf;
	
	Return Left(MetadataObjectName, 30) + RemainderHashSum;
	
EndFunction

// Returns a storage type of the uploaded file depending on its extension and size.
// 
// Parameters:
//   FileSize - Number - a size of the file to be added in bytes.
//   FileExtention - String - an extension of the file being added.
//   FilesStorageMethod - String, Undefined - For allowed values, see constant
//                                                 FilesStorageMethod. Default is  Undefined.
//
// Returns:
//   EnumRef.FileStorageTypes - If the file storage method in the settings is InVolumesOnHardDrive,
//      the return value is InVolumesOnHardDrive. If the file storage method is
//       InInfobaseAndVolumesOnHardDrive, the return value is InInfobase
//      when the file matches the infobase storage parameters. Otherwise, the return value is InVolumesOnHardDrive.
//
Function FileStorageType(Val FileSize, Val FileExtention, Val FilesStorageMethod = Undefined) Export

	If FilesStorageMethod = Undefined Then
		StorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
	Else
		StorageType = FileArchiveManagementServer.FileStorageTypeByStorageMethod(FilesStorageMethod);
	EndIf;

	If ShouldStoreFilesInVolumesAndInfobase() Then
		
		StorageParameters = FilesStorageParametersInInfobase();
		If FileSize <= StorageParameters.MaximumSize Then
			StorageType = Enums.FileStorageTypes.InInfobase;
		Else
			FileExtention = Lower(TrimAll(FileExtention));
			If StrStartsWith(FileExtention, ".") Then
				FileExtention = Mid(FileExtention, 2, StrLen(FileExtention) - 1);
			EndIf;
			If StrFind(Lower(StorageParameters.FilesExtensions), FileExtention) > 0 Then
				StorageType = Enums.FileStorageTypes.InInfobase;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return StorageType;
	
EndFunction

// Returns the first volume, to which you can place the specified file, in the filling order.
//
// Parameters:
//   AttachedFile - DefinedType.AttachedFileObject
//                      - See FilesOperationsInVolumesInternal.FileAddingOptions
//   StorageVolumeType	- EnumRef.StorageKinds - Volume storage option. Default is Undefined.
//   FilesStorageMethod	- EnumRef.FilesStorageMethods, String
//
// Returns:
//   CatalogRef.FileStorageVolumes
//
Function FreeVolume(AttachedFile, Val StorageVolumeType = Undefined, Val FilesStorageMethod = Undefined) Export

	If StorageVolumeType = Undefined Then
		StorageVolumeType = Enums.StorageKinds.OperationalStorage;
	EndIf;

	SetPrivilegedMode(True);

	Query = New Query;
	Query.Text = 
	"SELECT
	|	FileStorageVolumes.Ref AS Ref,
	|	FileStorageVolumes.MaximumSize AS MaximumSize
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	FileStorageVolumes.DeletionMark = FALSE
	|	AND FileStorageVolumes.StorageVolumeType = &StorageVolumeType
	|	AND (&AnyFilesStorageMethod
	|			OR FileStorageVolumes.FilesStorageMethod = &FilesStorageMethod)
	|
	|ORDER BY
	|	FileStorageVolumes.FillOrder";

	Query.SetParameter("StorageVolumeType"		, StorageVolumeType);
	Query.SetParameter("FilesStorageMethod"		, FilesStorageMethod);
	Query.SetParameter("AnyFilesStorageMethod"	, FilesStorageMethod = "WithAnyStorageMethodInVolumes");

	Result = Query.Execute();
	If Result.IsEmpty() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể thêm tệp ""%1"", 
				|bởi vì chưa tùy chỉnh quyển nào để lưu tệp.
				|Hãy liên hệ với người quản trị.';
				|ru = 'Не удалось добавить файл ""%1"", 
				|т.к. не настроено ни одного тома для хранения файлов.
				|Обратитесь к администратору.';
				|en = 'Cannot add the %1 file 
				|as no file storage volume is configured.
				|Contact the administrator.'; fa = 'Cannot add the %1 file 
				|as no file storage volume is configured.
				|Contact the administrator.';
				|it = 'Не удалось добавить файл ""%1"", 
				|т.к. не настроено ни одного тома для хранения файлов.
				|Обратитесь к администратору.';
				|pl = 'Cannot add the %1 file 
				|as no file storage volume is configured.
				|Contact the administrator.';
				|tr = '""%1"" dosyası eklenemedi,
				|çünkü dosyaların saklanması için herhangi bir cilt ayarlanmamış.
				|Yöneticiye ulaşın.'"),
			AttachedFile.Description + "." + AttachedFile.Extension);
	EndIf;
	
	FileStorageVolumes = Result.Unload();
	SizesOfVolumes = Undefined;
	
	For Each FileStorageVolume In FileStorageVolumes Do
		
		If FileStorageVolume.MaximumSize = 0 Then
			Return FileStorageVolume.Ref;
		EndIf;

		If SizesOfVolumes = Undefined Then
			// @skip-check query-in-loop - One-time call
			SizesOfVolumes = SizesOfVolumes(FileStorageVolumes.UnloadColumn("Ref"));
		EndIf;
		VolumeSize = SizesOfVolumes[FileStorageVolume.Ref];
		If VolumeSize + AttachedFile.Size <= FileStorageVolume.MaximumSize * 1024 * 1024 Then
			Return FileStorageVolume.Ref;
		EndIf;
		
	EndDo;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
	NStr("vi = 'Không thể thêm tệp ""%1"", 
		|bởi vì không đủ dung lượng trong các quyển lưu tệp.
		|Hãy liên hệ với người quản trị.';
		|ru = 'Не удалось добавить файл ""%1"", 
		|т.к. в томах хранения файлов недостаточно места.
		|Обратитесь к администратору.';
		|en = 'Cannot add the %1 file 
		|as the file storage volumes do not have enough space.
		|Contact the administrator.'; fa = 'Cannot add the %1 file 
		|as the file storage volumes do not have enough space.
		|Contact the administrator.';
		|it = 'Не удалось добавить файл ""%1"", 
		|т.к. в томах хранения файлов недостаточно места.
		|Обратитесь к администратору.';
		|pl = 'Cannot add the %1 file 
		|as the file storage volumes do not have enough space.
		|Contact the administrator.';
		|tr = '""%1"" dosyası eklenemedi,
		|çünkü dosyaların ciltte saklanması için yeterli alan yok.
		|Yöneticiye ulaşın.'"),
		AttachedFile.Description + "." + AttachedFile.Extension);
	Raise ErrorText;	
	
EndFunction

Function FileSystemProperties(Directory)
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	TestDirName = Directory + "CheckAccess"+Format(CurrentSessionDate(), "DF=ddMMyy_HHmmss;");
	TestFileName = TestDirName + GetPathSeparator() + " FileNameCheck.";
	CreateDirectory(TestDirName);
	
	TextFile = New TextDocument;
	TextFile.Write(TestFileName);
	
	Result = New Structure;
	Result.Insert("HasFilenameLeadingWhitespace", False);
	Result.Insert("HasFilenameTrailingDot", False);
	FilesFound = FindFiles(TestDirName,"*FileNameCheck*", True);
	For Each FoundFile In FilesFound Do
		If StrEndsWith(FoundFile.FullName, " FileNameCheck.") Then
			Result.HasFilenameLeadingWhitespace = True;
			Result.HasFilenameTrailingDot = True;
			Break;
		ElsIf StrEndsWith(FoundFile.FullName, "FileNameCheck.") Then
			Result.HasFilenameLeadingWhitespace = False;
			Result.HasFilenameTrailingDot = True;
			Break;
		ElsIf StrEndsWith(FoundFile.FullName, " FileNameCheck") Then
			Result.HasFilenameLeadingWhitespace = True;
			Result.HasFilenameTrailingDot = False;
			Break;
		EndIf;
	EndDo;
	DeleteFiles(TestDirName);
	Return Result;
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateVolumePathLinux");
	Methods.Insert("FillFilesStorageSettings");
	Methods.Insert("SetTheWayToFormTheVolumePath");
	Methods.Insert("ReferenceToNonexistingFilesInVolumeCheck");
	
EndProcedure

#EndRegion