///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns file binary data extracted from the ZIP archive.
//
// Parameters:
//  ZipArchiveBinaryData	- BinaryData - Binary file data.
//  AttachedFile		- DefinedType.AttachedFile - a reference to the catalog item with file.
//
// Returns:
//  - BinaryData
//  - Undefined
//
Function BinaryDataOfFileExtractedFromZipArchive(ZipArchiveBinaryData, AttachedFile) Export

	Result = Undefined;

	If TypeOf(ZipArchiveBinaryData) = Type("BinaryData") Then

		ErrorDescription = NStr("ru = 'Ошибка при извлечении файла из Zip-архива';
								|vi = 'Error extracting file from ZIP archive';
								|en = 'Error extracting file from ZIP archive'; fa = 'Error extracting file from ZIP archive';
								|it = 'Error extracting file from ZIP archive';
								|pl = 'Error extracting file from ZIP archive';
								|tr = 'Zip arşivinden dosya çıkarılırken hata oluştu'");
		
		TempDirectory = NewTempDirectoryToWorkWithZipArchive(ErrorDescription);

		Try
			AttributesValues = Common.ObjectAttributesValues(AttachedFile, "Description,Extension");

			ExtractedFileName = CommonClientServer.GetNameWithExtension(AttributesValues.Description, AttributesValues.Extension);

			ExtractedFileData = ExtractFileFromZipArchive(ZipArchiveBinaryData, ExtractedFileName, TempDirectory);

			Result = New BinaryData(ExtractedFileData.FileName);

			DeleteTempDirectoryForZipArchiveOperations(TempDirectory);

		Except

			DeleteTempDirectoryForZipArchiveOperations(TempDirectory);

		    ErrorInfo = ErrorInfo();
		    Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, ErrorDescription);

		    Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);			
		EndTry;
	EndIf;

	Return Result;

EndFunction

// Checks if storing files in binary storage is available.
// SSL supports binary storage starting from 1C:Enterprise v. 8.3.26.1000.
// File infobases don't support binary storage.
// Distributed infobases don't support binary storage.
//
// Returns:
//  Boolean
//
Function AreBinaryDataStoragesAvailable() Export	

	Result = Not Common.FileInfobase();

	If Result Then
		Result = Not Common.IsDistributedInfobase()
	EndIf;	

	If Result Then
		Result = AreChangesInFilesStorageMethodsAvailable();
	EndIf;

	Return Result;

EndFunction

// Retrieves the minimum 1C:Enterprise version with updated file storage options.
//	Now, files can be stored in binary storage. Old storage methods were renamed.
// 
// Returns:
//  Boolean
//
Function AreChangesInFilesStorageMethodsAvailable() Export

	Result = True;	

	Info = New SystemInfo;
	MinVersion = MinPlatformVersionToWorkWithBinaryDataStorages();

	If CommonClientServer.CompareVersions(
		Info.AppVersion, MinVersion) < 0 Then
		Result = False;
	EndIf;	
	
	Return Result;

EndFunction

// Checks if the application supports file archives.
// Only CORP applications support file archives.
// File infobases don't support file archives.
// Distributed infobases don't support file archives.
//
// Returns:
//  Boolean
//
Function IsFileArchiveAvailable() Export

	Result = FilesOperationsInternal.FilesSettings().IsFileArchiveAvailable;

	If Result Then
		Result = Not Common.FileInfobase();
	EndIf;

	If Result Then
		Result = Not Common.IsDistributedInfobase()
	EndIf;

	Return Result;

EndFunction

// Returns the storage option in storage volumes matching the specified file storage option.
//
// Parameters:
//  FileStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  - EnumRef.FileStorageOption	- In case the passed storage method is InInfobaseAndVolumesOnDisk.
//  - String									- In case the passed storage method is InInfobaseAndVolumesOnDisk.
//
Function StorageMethodToSelectStorageVolumes(Val FileStorageMethod = "") Export

	If Not ValueIsFilled(FileStorageMethod) Then
		FileStorageMethod = FilesStorageMethod();
	EndIf;	

	If FileStorageMethod = "InVolumesOnHardDrive" Then
		Result = Enums.FileStorageOption.NetworkDirectories;
	ElsIf FileStorageMethod = "InternalBinaryDataStorage" Then
		Result = Enums.FileStorageOption.InInternalStorage;
	ElsIf FileStorageMethod = "ExternalBinaryDataStorage" Then
		Result = Enums.FileStorageOption.S3ExternalStorage;
	ElsIf FileStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then
		Result = "WithAnyStorageMethodInVolumes";
	EndIf;

	Return Result;

EndFunction

// Returns an array of attribute names from the BinaryDataStorage catalog
// matching the specified file storage method.
//
// Parameters:
//  FilesStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  Array
//
Function FilesStorageAttributesNamesByStorageMethod(FilesStorageMethod) Export

	Result = New Array;
	Result.Add("BinaryData");

	If FilesStorageMethod = "InternalBinaryDataStorage" Then

		Result.Add("BinaryDataInInternalOperationalStorage");

	ElsIf FilesStorageMethod = "ExternalBinaryDataStorage" Then

		Result.Add("BinaryDataInExternalOperationalStorage");

	ElsIf FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then

		Result.Add("BinaryDataInInternalOperationalStorage");
		Result.Add("BinaryDataInExternalOperationalStorage");

	EndIf;

	Return Result;

EndFunction

// Controls the visibility of the ImageNumberIsArchive field on the list form
// based on the use of file archive functionality.
// 
// Parameters:
//   Form - ClientApplicationForm
//
Procedure IsArchivePictureNumberListFieldVisibility(FormField) Export

	FormField.Visible = UseFileArchive();

EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.InitialFilling	= True;
	Handler.SharedData			= True;
	Handler.Version				= "3.1.12.38";
	Handler.Procedure			= "FileArchiveManagementServer.ConstantsInitialFilling";
	Handler.ExecutionMode		= "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling	= True;
	Handler.Version				= "3.1.12.38";
	Handler.Procedure			= "FileArchiveManagementServer.InitialFillingFileArchiveOperationsSettings";
	Handler.ExecutionMode		= "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version				= "3.1.12.38";	
	Handler.Comment			= NStr("ru = 'Заполнение новых реквизитов в справочнике ""Тома хранения файлов""';
										|vi = 'Populating new attributes in the Storage volumes catalog';
										|en = 'Populating new attributes in the Storage volumes catalog'; fa = 'Populating new attributes in the Storage volumes catalog';
										|it = 'Populating new attributes in the Storage volumes catalog';
										|pl = 'Populating new attributes in the Storage volumes catalog';
										|tr = '""Dosya saklama birimleri"" kılavuzunda yeni özniteliklerin doldurulması'");
	Handler.SharedData			= True;
	Handler.Procedure			= "Catalogs.FileStorageVolumes.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode		= "Seamless";

	Handler = Handlers.Add();
	Handler.Version				= "3.1.12.38";
	Handler.Comment			= NStr("ru = 'Заполнение недостающих сведений о хранении дедуплицированных файлов.';
										|vi = 'Completing missing information on deduplicated file storage.';
										|en = 'Completing missing information on deduplicated file storage.'; fa = 'Completing missing information on deduplicated file storage.';
										|it = 'Completing missing information on deduplicated file storage.';
										|pl = 'Completing missing information on deduplicated file storage.';
										|tr = 'Tekilleştirilmiş dosya saklama bilgilerindeki eksik verilerin doldurulması.'");
	Handler.Id		= New UUID("c36f86c4-77e8-4fe9-a07e-798d85929cf9");
	Handler.Procedure			= "InformationRegisters.DeduplicatedFileStorageInformation.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode		= "Deferred";
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DeduplicatedFileStorageInformation.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure	= "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToRead      = "InformationRegister.FileRepository";
	Handler.ObjectsToChange    = "InformationRegister.DeduplicatedFileStorageInformation";
	Handler.ObjectsToLock   = "InformationRegister.FileRepository";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Order	= "Any";

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Populates the list with the available storage options for file storage volumes.
//
// Parameters:
//  ChoiceList			- ValueList - a value list to be filled in.
//  StorageVolumeType	- EnumRef.StorageKinds
//
Procedure FilesStorageMethodFillChoiceList(ChoiceList, StorageVolumeType) Export

	ChoiceList.Add(Enums.FileStorageOption.NetworkDirectories);

	If AreBinaryDataStoragesAvailable() Then
		ChoiceList.Add(Enums.FileStorageOption.S3ExternalStorage);
		If StorageVolumeType = Enums.StorageKinds.OperationalStorage Then	
			ChoiceList.Add(Enums.FileStorageOption.InInternalStorage);	
		EndIf;
	EndIf;

EndProcedure

// Returns the FilesStorageMethod constant value.
//
// Returns:
//  String - See Constant.FilesStorageMethod
//
Function FilesStorageMethod() Export

	SetPrivilegedMode(True);
	Result = Constants.FilesStorageMethod.Get();

	Return Result;

EndFunction

// Returns the value of constant ShouldUseFileArchive.
//
// Returns:
//  Boolean - See Constant.UseFileArchive
//
Function UseFileArchive() Export

	SetPrivilegedMode(True);
	Result = Constants.UseFileArchive.Get();

	Return Result;

EndFunction

// Returns the value of constant TransferredFilesPortionSize.
//
// Returns:
//  Number - See Constant.BatchSizeOfTransferedFiles
//
Function BatchSizeOfTransferedFiles()

	SetPrivilegedMode(True);
	Result = Constants.BatchSizeOfTransferedFiles.Get();

	If Result = 0 Then
		Result = TransferredFilesPortionSizeDefaultValue();
	EndIf;
	
	Return Result;

EndFunction

// Returns the value of constant UserNotificationTextForUnavailableArchivedFile.
//
// Returns:
//  String - See Constant.NotificationAboutFileUnavailabilityInTheArchive
//
Function NotificationAboutFileUnavailabilityInTheArchive() Export

	SetPrivilegedMode(True);
	Result = Constants.NotificationAboutFileUnavailabilityInTheArchive.Get();
	SetPrivilegedMode(False);

	If Not ValueIsFilled(Result) Then
		Result = UserNotificationTextForUnavailableArchivedFileDefaultValue();
	EndIf;

	Return Result;	

EndFunction

// Returns the name of the attribute of the BinaryDataStorage catalog matching the specified volume storage method.
//
// Parameters:
//  FilesStorageMethod - EnumRef. ... - Refer to the FilesStorageMethod attribute of the FileStorageVolumes catalog.
//
// Returns:
//  String
//
Function BinaryDataStorageAttributeNameByVolumeStorageMethod(VolumeStorageMethod) Export

	Result = "";

	If VolumeStorageMethod = Enums.FileStorageOption.InInternalStorage Then

		Result = "BinaryDataInInternalOperationalStorage";

	ElsIf VolumeStorageMethod = Enums.FileStorageOption.S3ExternalStorage Then

		Result = "BinaryDataInExternalOperationalStorage";

	EndIf;

	Return Result;	

EndFunction

// Returns the storage option matching the specified file storage option.
//
// Parameters:
//  FileStorageMethod - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  EnumRef.FileStorageTypes
//
Function FileStorageTypeByStorageMethod(Val FileStorageMethod = "") Export

	If IsBlankString(FileStorageMethod) Then
		FileStorageMethod = FilesStorageMethod();
	EndIf;

	If FileStorageMethod = "InVolumesOnHardDrive" Then
		Result = Enums.FileStorageTypes.InVolumesOnHardDrive;
	ElsIf FileStorageMethod = "InternalBinaryDataStorage" Then
		Result = Enums.FileStorageTypes.InternalBinaryDataStorage;
	ElsIf FileStorageMethod = "ExternalBinaryDataStorage" Then
		Result = Enums.FileStorageTypes.ExternalBinaryDataStorage;
	ElsIf FileStorageMethod = "InInfobaseAndVolumesOnHardDrive" Then
		Result = Enums.FileStorageTypes.VolumesVolumeUndefined;
	Else
		Result = Enums.FileStorageTypes.InInfobase;
	EndIf;

	Return Result;

EndFunction

// Returns the file storage type that matches the specified storage volume or volume storage option.
//
// Parameters:
//  VolumeOrFilesStorageMethod - CatalogRef.FileStorageVolumes, EnumRef.FilesStorageMethods
//
// Returns:
//  - EnumRef.FileStorageTypes
//  - Undefined
//
Function StorageTypeByFilesStorageVolume(VolumeOrFilesStorageMethod = Undefined) Export

	If ValueIsFilled(VolumeOrFilesStorageMethod) Then

		If TypeOf(VolumeOrFilesStorageMethod) = Type("CatalogRef.FileStorageVolumes") Then
			StorageMethod = Common.ObjectAttributeValue(VolumeOrFilesStorageMethod, "FilesStorageMethod");
		Else
			StorageMethod = VolumeOrFilesStorageMethod;
		EndIf;

		If StorageMethod = Enums.FileStorageOption.NetworkDirectories Then
			Result = Enums.FileStorageTypes.InVolumesOnHardDrive;
		ElsIf StorageMethod = Enums.FileStorageOption.InInternalStorage Then
			Result = Enums.FileStorageTypes.InternalBinaryDataStorage;
		ElsIf StorageMethod = Enums.FileStorageOption.S3ExternalStorage Then
			Result = Enums.FileStorageTypes.ExternalBinaryDataStorage;
		Else
			Result = Undefined;
		EndIf;
	Else
		Result = Enums.FileStorageTypes.InInfobase;
	EndIf;

	Return Result;

EndFunction

// Verifies that the archive contains the attachment associated with the passed item of the BinaryDataStorage catalog.
//
// Parameters:
//  Var_BinaryDataStorage - CatalogRef.BinaryDataStorage
//
// Returns:
//  Boolean
//
Function IsBinaryDataStorageAvailableInFileArchive(Var_BinaryDataStorage) Export

	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	CatalogBinaryDataStorage.Ref AS Ref
		|FROM
		|	Catalog.BinaryDataStorage AS CatalogBinaryDataStorage
		|		INNER JOIN InformationRegister.FileRepository AS FileRepository
		|		ON (CatalogBinaryDataStorage.Ref = &BinaryDataStorage)
		|			AND CatalogBinaryDataStorage.Ref = FileRepository.BinaryDataStorage
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON (FileRepository.File = FilesInfo.File)
		|			AND (NOT FilesInfo.DeletionMark)
		|		LEFT JOIN Catalog.FilesVersions AS FilesVersions
		|		ON (FileRepository.File = FilesVersions.Ref)
		|			AND (NOT FilesVersions.Owner.DeletionMark)
		|WHERE
		|	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
		|	AND ISNULL(FilesInfo.ArchivingDate, ISNULL(FilesVersions.ArchivingDate, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1)";

	Query.SetParameter("BinaryDataStorage", Var_BinaryDataStorage);

	Return Not Query.Execute().IsEmpty();

EndFunction

// Verifies that the archive contains the attachment.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile, CatalogRef.FilesVersions - Reference to the catalog item
//                                                                                           that contains the file.
//
// Returns:
//  Boolean
//
Function IsFileTransferredToFileArchive(AttachedFile) Export

	Result = False;

	If ValueIsFilled(AttachedFile) Then 
		If TypeOf(AttachedFile) = Type("CatalogRef.FilesVersions") Then

			ArchivingDate = Common.ObjectAttributeValue(AttachedFile, "ArchivingDate");

		ElsIf TypeOf(AttachedFile) = Type("CatalogRef.Files") Then

			CurrentFileVersion = Common.ObjectAttributeValue(AttachedFile, "CurrentVersion");

			ArchivingDate = Common.ObjectAttributeValue(CurrentFileVersion, "ArchivingDate");

		Else

			Query = New Query;
			Query.Text = 
				"SELECT
				|	FilesInfo.ArchivingDate AS ArchivingDate
				|FROM
				|	InformationRegister.FilesInfo AS FilesInfo
				|WHERE
				|	FilesInfo.File = &File";

			Query.SetParameter("File", AttachedFile);

			SetPrivilegedMode(True);
			
			DataSelection = Query.Execute().Select();
			If DataSelection.Next() Then
				ArchivingDate = DataSelection.ArchivingDate;
			Else
				ArchivingDate = Date(1,1,1);			
			EndIf;
		EndIf;

		Result = ValueIsFilled(ArchivingDate);

	EndIf;

	Return Result;

EndFunction

// Returns a structure containing the hash result of the binary data.
//
// Parameters:
//  BinaryData - BinaryData, Undefined
//
// Returns:
//  Structure - See FileArchiveManagementServer.
//
Function BinaryDataHashingResult(BinaryData) Export

	Hashing = New DataHashing(HashFunction.SHA256);

	IsEmptyBinaryData = (BinaryData = Undefined);
	If IsEmptyBinaryData Then
		EmptyBinaryData = GetBinaryDataFromString("");
		Hashing.Append(EmptyBinaryData);
		Size = EmptyBinaryData.Size();
	Else
		Hashing.Append(BinaryData);
		Size = BinaryData.Size();
	EndIf;
	Hash = GetBase64StringFromBinaryData(Hashing.HashSum);	

	Result = BinaryDataHashingResultParameters();
	
	Result.IsEmptyBinaryData = IsEmptyBinaryData;
	Result.Size = Size;
	Result.Hash = Hash;

	Return Result;

EndFunction

// Returns information on the BinaryDataStorage catalog item that matches the specified hash and size.
//
// Parameters:
//  Hash		- String - A Base64 string generated by the 1C:Enterprise method GetBase64StringFromBinaryData.
//  Size	- Number
//
// Returns:
//  Structure - Information on the BinaryDataStorage catalog item:
//   * BinaryDataStorageRef - CatalogRef.BinaryDataStorage - If a matching BinaryDataStorage
//                                                                                catalog item has been found.
//									 - Undefined - If no matching BinaryDataStorage catalog item has been found.
//   * StoredDataSize			 - Number - The size of the binary data in bytes.
//
Function BinaryDataStorageItemInfoByHashAndSize(Hash, Size) Export

	Result = New Structure;
	Result.Insert("BinaryDataStorageRef"	, Undefined);
	Result.Insert("StoredDataSize"			, 0);
	
	Query = New Query;
	Query.SetParameter("Hash"		, Hash);
	Query.SetParameter("Size"	, Size);
	Query.Text =
		"SELECT
		|	BinaryDataStorage.Ref AS BinaryDataStorageRef,
		|	STOREDDATASIZE(BinaryDataStorage.BinaryData) AS StoredDataSize
		|FROM
		|	Catalog.BinaryDataStorage AS BinaryDataStorage
		|WHERE
		|	BinaryDataStorage.Hash = &Hash
		|	AND BinaryDataStorage.Size = &Size";

	Selection = Query.Execute().Select();

	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;

	Return Result;

EndFunction

// Populates attachment attributes FileStorageType and Volume with data obtained from information register DeduplicatedFilesStorageInformation.
//
// Parameters:
//  AttachedFile	- DefinedType.AttachedFileObject, CatalogObject.FilesVersions - Catalog item object the file belongs to.
//  BinaryData		- BinaryData - binary file data.
//
Procedure FillFilePropertiesByExistingBinaryDataStorageItem(AttachedFile, BinaryData) Export

	If TypeOf(BinaryData) <> Type("BinaryData") Or Not AreBinaryDataStoragesAvailable() Then
		Return;
	EndIf;

	StoringFilesInfo = DeduplicatedFileStorageParameters(BinaryData);
	If StoringFilesInfo <> Undefined Then
		FillPropertyValues(AttachedFile, StoringFilesInfo);
	EndIf;	

EndProcedure

// Returns a structure with deduplicated file storage parameters retrieved from information register DeduplicatedFilesStorageInformation.
//
// Parameters:
//  BinaryData			- BinaryData - The binary data for which the item of the BinaryDataStorage catalog needs to be retrieved.
//  Var_BinaryDataStorage - CatalogRef.BinaryDataStorage - Used for optimization when the BinaryDataStorage
//                                                                       catalog item is already known.
//  FileStorageKind		- EnumRef.StorageKinds
//
// Returns:
//  - Structure		- In case no deduplicated file storage parameters exist in DeduplicatedFilesStorageInformation.
//  - Undefined	- In case no deduplicated file storage parameters exist in DeduplicatedFilesStorageInformation.
//
Function DeduplicatedFileStorageParameters(BinaryData, Var_BinaryDataStorage = Undefined, FileStorageKind = Undefined)

	SetPrivilegedMode(True);
	
	If ValueIsFilled(Var_BinaryDataStorage) Then
		BinaryDataStorageRef = Var_BinaryDataStorage;
	Else
		BinaryDataStorageRef = BinaryDataStorageItemByBinaryData(BinaryData);
	EndIf;

	If ValueIsFilled(BinaryDataStorageRef) Then
		Result = InformationRegisters.DeduplicatedFileStorageInformation.DeduplicatedFileStorageInformation(BinaryDataStorageRef, FileStorageKind);
	Else
		Result = Undefined;
	EndIf;	

	Return Result;

EndFunction

// Returns the item of the BinaryDataStorage catalog that matches the specified binary data.
//
// Parameters:
//  BinaryData - BinaryData - Attachment binary data.
//
// Returns:
//  - CatalogRef.BinaryDataStorage - If the catalog item is found.
//  - Undefined - If the catalog item is found.
//
Function BinaryDataStorageItemByBinaryData(BinaryData)

	HashingResults = BinaryDataHashingResult(BinaryData);

	BinaryStorageInfo = BinaryDataStorageItemInfoByHashAndSize(HashingResults.Hash, HashingResults.Size);
	Result = BinaryStorageInfo.BinaryDataStorageRef;	

	Return Result;

EndFunction

// Returns a vacant storage volume suitable for storing the attachment.
//
// Parameters:
//  AttachedFile		- DefinedType.AttachedFileObject
//                      		- See FilesOperationsInVolumesInternal.FileAddingOptions
//  FilesStorageTyoe		- EnumRef.FileStorageTypes
//  StorageVolumeType	- EnumRef.StorageKinds
//
// Returns:
//   CatalogRef.FileStorageVolumes
//
Function FreeStorageVolumeByFilesStorageType(AttachedFile, FilesStorageTyoe, StorageVolumeType) Export

	StorageMethodInVolumes = StorageMethodToSelectStorageVolumesByFilesStorageType(FilesStorageTyoe);

	Result = FilesOperationsInVolumesInternal.FreeVolume(AttachedFile, StorageVolumeType, StorageMethodInVolumes);

	Return Result;

EndFunction

// Returns a structure of parameters used for writing binary data to the files' binary storage attributes.
//
// Returns:
//  Structure
//
Function ParametersForWritingToInfobase() Export

	Result = New Structure;
	Result.Insert("FileStorageType");
	Result.Insert("Volume");
	Result.Insert("PathToFile"					, "");
	Result.Insert("IsWriteToFileArchive"	, False);
	Result.Insert("DoNotChangeBinaryData"	, False);
	Result.Insert("BinaryDataOfArchive");

	Return Result;

EndFunction

// Returns a structure of parameters used for writing
// binary data to the files' binary storage attributes.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile, DefinedType.AttachedFileObject, Structure -
//                       Source of parameter values.
//
// Returns:
//  Structure
//
Function FilledWriteParametersToInfobase(AttachedFile) Export

	Result = ParametersForWritingToInfobase();

	If Common.IsReference(TypeOf(AttachedFile)) Then
		AttributesValues = Common.ObjectAttributesValues(AttachedFile, "FileStorageType,Volume,PathToFile");
		FillPropertyValues(Result, AttributesValues);
	Else
		FillPropertyValues(Result, AttachedFile);
	EndIf;

	Return Result;

EndFunction

// Populates the following attachment's attributes: FileStorageType, Volume, PathToFile.
//
// Parameters:
//  AttachedFile	- DefinedType.AttachedFileObject, CatalogObject.FilesVersions - Catalog item object the file belongs to
//  BinaryData		- BinaryData - Binary file data
//  Size				- Number
//  Extension			- String
//
Procedure FillFileStorageParameters(AttachedFile, BinaryData, Size, Extension) Export
	
	AttachedFile.FileStorageType = Undefined;
	AttachedFile.Volume = Undefined;
	AttachedFile.PathToFile = Undefined;

	FillFilePropertiesByExistingBinaryDataStorageItem(AttachedFile, BinaryData);
	
	If Not ValueIsFilled(AttachedFile.FileStorageType) Then
		AttachedFile.FileStorageType = FilesOperationsInternal.FileStorageType(Size, Extension);

		If AttachedFile.FileStorageType <> Enums.FileStorageTypes.InInfobase Then
			
			AttachedFile.Volume = FreeStorageVolumeByFilesStorageType(AttachedFile, 
																												AttachedFile.FileStorageType,
																												Enums.StorageKinds.OperationalStorage);
			If AttachedFile.FileStorageType = Enums.FileStorageTypes.VolumesVolumeUndefined Then
				AttachedFile.FileStorageType = StorageTypeByFilesStorageVolume(AttachedFile.Volume);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// Creates a temporary folder and returns its full path.
//
// Parameters:
//  ErrorDescriptionString - String - Extended error text
//
// Returns:
//  String - Full path to the temporary directory.
//
Function NewTempDirectoryToWorkWithZipArchive(ErrorDescriptionString = "")

	Try

		FilesTempDirectory = FileSystem.CreateTemporaryDirectory();

	Except

		ErrorDescriptionTemplate = NStr("ru = '""%1""
			|Не создан временный каталог для работы с zip-архивом
			|""%2""';
			|vi = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""';
			|en = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""'; fa = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""';
			|it = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""';
			|pl = '""%1""
			|Temporary directory for the ZIP archive was not created
			|""%2""';
			|tr = '""%1""
			|Zip arşiviyle çalışmak için geçici dizin oluşturulmadı
			|""%2""'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ErrorDescriptionString,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		WriteLogEvent(NStr("ru = 'Выполнение операций с файловым архивом';
							|vi = 'File archive operations';
							|en = 'File archive operations'; fa = 'File archive operations';
							|it = 'File archive operations';
							|pl = 'File archive operations';
							|tr = 'Dosya arşivi işlemlerinin yürütülmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ExceptionString);

		Raise ExceptionString;

	EndTry;

	Return FilesTempDirectory;

EndFunction

// Retrieves the file entry extracted from a ZIP archive. If a file with the specified name is not found,
// returns the first entry in the archive.
//
// Parameters:
//  ZIPReader				- ZipFileReader - ZIP archive.
//  ExtractedFileName	- String - Full name of the extracted file.
//
// Returns:
//  ZipFileEntries	- A ZIP file entry, if found by the passed filename, or the first entry in the archive if no matching file is found.
//  Undefined - If the ZIP entry could not be determined.		
//
Function ExtractedFileItem(ZIPReader, ExtractedFileName)

	Result = ZIPReader.Items.Find(ExtractedFileName);

	If Result = Undefined Then
		If ZIPReader.Items.Count() > 0 Then
			Result = ZIPReader.Items[0];
		Else
			Result = Undefined;
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function PrepareBinaryDataToWrite(DataToWrite)

	If TypeOf(DataToWrite) = Type("BinaryData") Then
		Result = New ValueStorage(DataToWrite, New Deflation(9));
	Else
		Result = DataToWrite;
	EndIf;

	Return Result;

EndFunction

Function MinPlatformVersionToWorkWithBinaryDataStorages()
	
	Return "8.3.26.1000";
	
EndFunction

Function TransferredFilesPortionSizeDefaultValue()
	Return 10;
EndFunction

Function UserNotificationTextForUnavailableArchivedFileDefaultValue()

	Return NStr("ru = 'Для получения файла обратитесь к администратору';
				|vi = 'To get the file, contact the administrator';
				|en = 'To get the file, contact the administrator'; fa = 'To get the file, contact the administrator';
				|it = 'To get the file, contact the administrator';
				|pl = 'To get the file, contact the administrator';
				|tr = 'Dosyayı almak için yöneticinize başvurun'");

EndFunction

Function StorageMethodToSelectStorageVolumesByFilesStorageType(FileStorageType)

	If FileStorageType = Enums.FileStorageTypes.ExternalBinaryDataStorage Then
		Result = Enums.FileStorageOption.S3ExternalStorage;
	ElsIf FileStorageType = Enums.FileStorageTypes.InternalBinaryDataStorage Then
		Result = Enums.FileStorageOption.InInternalStorage;
	ElsIf FileStorageType = Enums.FileStorageTypes.VolumesVolumeUndefined Then
		Result = "WithAnyStorageMethodInVolumes";
	Else
		Result = Enums.FileStorageOption.NetworkDirectories;
	EndIf;		

	Return Result;

EndFunction

Function BinaryDataHashingResultParameters()

	Result = New Structure;
	Result.Insert("IsEmptyBinaryData", False);
	Result.Insert("Size"					, 0);
	Result.Insert("Hash"					, "");	

	Return Result;

EndFunction

Procedure DeleteTempDirectoryForZipArchiveOperations(TempDirectory)

	Try
		DeleteFiles(TempDirectory);
	Except

		ErrorDescriptionTemplate = NStr("ru = 'Не получилось удалить временный каталог для работы с zip-архивом
			|%1
			|%2';
			|vi = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2';
			|en = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2'; fa = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2';
			|it = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2';
			|pl = 'Couldn''t delete the temporary directory created for the ZIP archive
			|%1
			|%2';
			|tr = 'Zip arşiviyle çalışmak için kullanılan geçici dizin silinemedi
			|%1
			|%2'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			TempDirectory,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));		
		
		WriteLogEvent(NStr("ru = 'Выполнение операций с файловым архивом';
							|vi = 'File archive operations';
							|en = 'File archive operations'; fa = 'File archive operations';
							|it = 'File archive operations';
							|pl = 'File archive operations';
							|tr = 'Dosya arşivi işlemlerinin yürütülmesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ExceptionString);		
	EndTry;	
	
EndProcedure

Function TempDirectoryForNonUniqueFile(TempDirectory, FileName)

	FileOnHardDrive = New File(TempDirectory + FileName);
	If FileOnHardDrive.Exists() Then
		UniqueName = FilesOperationsInternalClientServer.UniqueNameByWay(TempDirectory, FileName);

		Result = TempDirectory + StrReplace(UniqueName, FileName, "");
	Else
		Result = TempDirectory;
	EndIf;

	Return Result;

EndFunction

Procedure ConstantsInitialFilling() Export

	Constants.BatchSizeOfTransferedFiles.Set(
				TransferredFilesPortionSizeDefaultValue());

	Constants.NotificationAboutFileUnavailabilityInTheArchive.Set(
				UserNotificationTextForUnavailableArchivedFileDefaultValue());
	
EndProcedure

Procedure InitialFillingFileArchiveOperationsSettings() Export
	
	RecordSetDefaultValue = InformationRegisters.FileArchiveSettings.CreateRecordSet();

	RecordSetDefaultValue.Filter.FileOwner.Set(Undefined);
	RecordSetDefaultValue.Filter.FileOwnerType.Set(Undefined);
	
	RsRecording = RecordSetDefaultValue.Add();
	RsRecording.FileOwner						= Undefined;
	RsRecording.FileOwnerType					= Undefined;
	RsRecording.ArchiveAfterDays	= 365;	
	
	InfobaseUpdate.WriteData(RecordSetDefaultValue);	
	
EndProcedure

// Creates a ZIP archive file and adds the passed file to it.
//
// Parameters:
//  PathToArchiveFile		- String - Path to the ZIP archive.
//  PathToFileBeingArchived	- String - Path to the source file.
//
// Returns:
//  Structure
//
Function PackFileToZipArchive(PathToArchiveFile, PathToFileBeingArchived)

	ZipArchiveFile = New File(PathToArchiveFile);
	If ZipArchiveFile.Exists() Then
		DeleteFiles(PathToArchiveFile);
	EndIf;

	RecordZIP = New ZipFileWriter(PathToArchiveFile);
	RecordZIP.Add(PathToFileBeingArchived, ZIPStorePathMode.DontStorePath);
	RecordZIP.Write();

	ZipArchiveFile = New File(PathToArchiveFile);

	Result = New Structure;
	Result.Insert("FileName"	, PathToArchiveFile);
	Result.Insert("Size"		, ZipArchiveFile.Size());	

	Return Result;

EndFunction

// Extracts a file with the specified name from a ZIP archive to the designated directory.
//
// Parameters:
//  ZipArchiveBinaryData - BinaryData - Binary ZIP archive data.
//  ExtractedFileName	- String - Full name of the extracted file.
//  TempDirectory		- String - Destination directory.
//
// Returns:
//  Structure
//
Function ExtractFileFromZipArchive(ZipArchiveBinaryData, ExtractedFileName, TempDirectory)

	ReadStream = ZipArchiveBinaryData.OpenStreamForRead();

	ZIPReader = New ZipFileReader(ReadStream);

	ExtractedFileItem = ExtractedFileItem(ZIPReader, ExtractedFileName);

	If ExtractedFileItem = Undefined Then 
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Файл %1 не найден в zip-архиве';
																			|vi = 'File not found in ZIP archive: %1';
																			|en = 'File not found in ZIP archive: %1'; fa = 'File not found in ZIP archive: %1';
																			|it = 'File not found in ZIP archive: %1';
																			|pl = 'File not found in ZIP archive: %1';
																			|tr = '%1 dosyası zip arşivinde bulunamadı'"), ExtractedFileName);
	EndIf;

	TempDirectoryForFileExtraction = TempDirectoryForNonUniqueFile(TempDirectory, ExtractedFileName);

	ZIPReader.Extract(ExtractedFileItem, TempDirectoryForFileExtraction);

	PathToExtractedFile = TempDirectoryForFileExtraction + ExtractedFileItem.OriginalName;

	ZIPReader.Close();
	ReadStream.Close();

	ExtractedFile = New File(PathToExtractedFile);
	If ExtractedFile.Exists() Then
		Result = New Structure;
		Result.Insert("FileName"	, PathToExtractedFile);
		Result.Insert("Size"		, ExtractedFile.Size());
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не удалось извлечь файл %1 из zip-архива';
																			|vi = 'Failed to extract file from ZIP archive: %1';
																			|en = 'Failed to extract file from ZIP archive: %1'; fa = 'Failed to extract file from ZIP archive: %1';
																			|it = 'Failed to extract file from ZIP archive: %1';
																			|pl = 'Failed to extract file from ZIP archive: %1';
																			|tr = '%1 dosyası zip arşivinde bulunamadı'"), ExtractedFileName);
	EndIf;

	Return Result;

EndFunction

#Region TransferFilesBetweenOperationalStorageAndArchive

// Method of sheduled job TransferFilesBetweenOperationalStorageAndFileArchive.
//
// Parameters:
//  Parameters		- Structure - Arbitrary ProcedureParameters. 
//									See TimeConsumingOperations.ExecuteInBackgroundfor the ProcedureName parameter
//  ResultAddress - String    - Address of the temporary storage where the result will be stored.
//									See TimeConsumingOperations.ExecuteInBackgroundfor the ProcedureName parameter
//
Procedure TransferFilesBetweenOperationalStorageAndFileArchive(Parameters = Undefined, ResultAddress = Undefined) Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TransferFilesBetweenOperationalStorageAndArchive);
	
	If Not UseFileArchive() Then
		Return;
	EndIf;

	SetPrivilegedMode(True);

	FilesTransferSettings = InformationRegisters.FileArchiveSettings.GetFileArchiveOperationsSettingsToTransferFiles();
	TransferSettingForMetadataObjects = FilesTransferSettings.FindRows(New Structure("IsFilesTransferDetailedSetting", False));

	If TransferSettingForMetadataObjects.Count() > 0 Then

		PortionSize = BatchSizeOfTransferedFiles();

		QueryText = FilesPortionQueryText(PortionSize);

		AdditionalTransferParameters = AdditionalFilesTransferParameters();
		AdditionalTransferParameters.QueryTextGettingFilesPortionToTransferToArchive = QueryText;

		QueryText = FilesPortionQueryText(PortionSize, False);
		AdditionalTransferParameters.QueryTextGettingFilesPortionToRestoreFromArchive = QueryText;
		AdditionalTransferParameters.FilesStorageMethod = FilesStorageMethod();
		
		DefaultStorageDaysCount = InformationRegisters.FileArchiveSettings.GetStorageDaysCountFromDefaultSetting();

		For Each Setting In TransferSettingForMetadataObjects Do

			ExceptionsArray = New Array;

			DetailedSettings = FilesTransferSettings.FindRows(New Structure(
																"OwnerCommonID, IsFilesTransferDetailedSetting",
																Setting.OwnerCommonID,
																True));

			If DetailedSettings.Count() > 0 Then
				ParentStorageDaysCount = NumberOfDaysOfStorageBeforeTransferToFileArchive(Setting, DefaultStorageDaysCount);					
					
				For Each DetalizedSetting In DetailedSettings Do

					PerformOperationsWithFiles(DetalizedSetting, ExceptionsArray, ParentStorageDaysCount, AdditionalTransferParameters);

				EndDo;
			EndIf;

			PerformOperationsWithFiles(Setting, ExceptionsArray, DefaultStorageDaysCount, AdditionalTransferParameters);

		EndDo;
	EndIf; 
	
EndProcedure

Procedure PerformOperationsWithFiles(Setting, ExceptionsArray, ParentStorageDaysCount, AdditionalTransferParameters)

	OperationalStorageDaysCount = NumberOfDaysOfStorageBeforeTransferToFileArchive(Setting, ParentStorageDaysCount);
	
	TransferFilesToFileArchive(Setting, ExceptionsArray, OperationalStorageDaysCount, AdditionalTransferParameters);

	RestoreFilesFromFileArchive(Setting, ExceptionsArray, OperationalStorageDaysCount, AdditionalTransferParameters);

	ExceptionsArray.Add(Setting.FileOwner);

EndProcedure

Procedure RestoreFilesFromFileArchive(Setting, ExceptionsArray, OperationalStorageDaysCount, AdditionalTransferParameters)

	TempTablesManager = New TempTablesManager;

	FillTemporaryTableToRestoreFiles(Setting, ExceptionsArray, OperationalStorageDaysCount, TempTablesManager);

	InfoToSelectVolume				= InfoAboutFilesToSelectVolume();
	SelectedStorageVolumeInfo	= Undefined;

	LastRef = EmptyLinkToAttachedFile(Setting);

	QueryText = AdditionalTransferParameters.QueryTextGettingFilesPortionToRestoreFromArchive;

	FilesToTransfer = NextFilesPortion(TempTablesManager, LastRef, QueryText);

	While FilesToTransfer.Count() > 0 Do

		ErrorDescriptionString = ErrorDescriptionStringOnOperationsWithTempDirectory(False);

		For Each FileBeingProcessed In FilesToTransfer Do

			If FileBeingProcessed.DeduplicatedFilesCount > 0 Then
				//@skip-warning Query not performed for all iterations of the loop.
				If Not IsFileTransferredToFileArchive(FileBeingProcessed.AttachedFile) Then
					Continue;
				EndIf;
			EndIf;

			TempDirectory = NewTempDirectoryToWorkWithZipArchive(ErrorDescriptionString);

			AttachedFileRef = FileBeingProcessed.AttachedFile;
			
			Block = New DataLock;
			DataLockItem = Block.Add(AttachedFileRef.Metadata().FullName());
			DataLockItem.SetValue("Ref", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FileRepository.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);			

			BeginTransaction();
			Try

				Block.Lock();
				
				OperationParametersList = RecoveryOperationExecutionParameters();
				OperationParametersList.TempDirectory	= TempDirectory;

				ExtractedFile = FileExtractedFromZipArchive(FileBeingProcessed, OperationParametersList);

				NewFileStorageType = Undefined;

				If ValueIsFilled(FileBeingProcessed.FileStorageTypeOperational) Then
					NewFileStorageType = FileBeingProcessed.FileStorageTypeOperational;

					StorageVolumeInfo = StorageVolumeInfo();
					StorageVolumeInfo.Ref				= FileBeingProcessed.VolumeOperational;
					StorageVolumeInfo.NewFileStorageType = NewFileStorageType;

					OperationParametersList.AreStorageParametersReceived	= True;

				Else

					BinaryData = New BinaryData(ExtractedFile.FileName);

					FileStorageParameters = DeduplicatedFileStorageParameters(
																			BinaryData, 
																			FileBeingProcessed.BinaryDataStorage,
																			Enums.StorageKinds.OperationalStorage);

					If FileStorageParameters <> Undefined Then
						NewFileStorageType = FileStorageParameters.FileStorageType;

						StorageVolumeInfo = StorageVolumeInfo();
						StorageVolumeInfo.Ref				= FileStorageParameters.Volume;
						StorageVolumeInfo.NewFileStorageType = NewFileStorageType;

						OperationParametersList.AreStorageParametersReceived = True;
					EndIf;
				EndIf;

				IsFileStorageNewTypePredefined = ValueIsFilled(NewFileStorageType);

				If Not IsFileStorageNewTypePredefined Then

					FileSize = FileSize(ExtractedFile.FileName);
					// A deduplicated file may be transferred to a disk volume.
					// In this case, a copy of each deduplicated file will be stored on disk.
					// Therefore, when selecting a storage volume, the total required free space is taken into account.
					InfoToSelectVolume.Size = Max(1, FileBeingProcessed.DeduplicatedFilesCount) * FileSize;

					NewFileStorageType = FilesOperationsInternal.FileStorageType(InfoToSelectVolume.Size, FileBeingProcessed.Extension);

					If NewFileStorageType = Enums.FileStorageTypes.InInfobase Then

						StorageVolumeInfo = StorageVolumeInfo();
						StorageVolumeInfo.NewFileStorageType = NewFileStorageType;

					Else
						If SelectedStorageVolumeInfo = Undefined 
								Or SelectedStorageVolumeInfo.MaximumSize <> 0 And SelectedStorageVolumeInfo.FreeVolume_ - InfoToSelectVolume.Size < 0 Then

							SelectedStorageVolumeInfo = PickStorageVolume(InfoToSelectVolume, 
																					Enums.StorageKinds.OperationalStorage,
																					NewFileStorageType);
						EndIf;

						StorageVolumeInfo = SelectedStorageVolumeInfo;

						// If a file is transferred to a volume that stores data on a disk partition, the volume
						// space is reduced by the file size, since files in such volumes are deduplicated.
						If StorageVolumeInfo.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
							FileSize = InfoToSelectVolume.Size;
						EndIf;
					EndIf;
				EndIf;

				OperationParametersList.StorageVolumeInfo = StorageVolumeInfo;

				// @skip-check query-in-loop - Batch processing of large amounts of data.
				RestoreFileFromFileArchive(FileBeingProcessed, ExtractedFile, OperationParametersList);

				If Not IsFileStorageNewTypePredefined Then
					If ValueIsFilled(NewFileStorageType) And NewFileStorageType <> Enums.FileStorageTypes.InInfobase Then
						If StorageVolumeInfo.MaximumSize <> 0 Then

							StorageVolumeInfo.FreeVolume_ = StorageVolumeInfo.FreeVolume_ - FileSize;

						EndIf;					
					EndIf;
				EndIf;

				CommitTransaction();

			Except

				RollbackTransaction();

				ExceptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteFilesTransferEventToEventLog(ExceptionString, EventLogLevel.Error);

				DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);
				Continue;
			EndTry;

			DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);

		EndDo;

		LastRef = FileBeingProcessed.AttachedFile;

		// @skip-check query-in-loop - Batch processing of large amounts of data.
		FilesToTransfer = NextFilesPortion(TempTablesManager, LastRef, QueryText);

	EndDo;	

EndProcedure

Procedure FillTemporaryTableToRestoreFiles(FilesTransferSetting, ExceptionsArray, OperationalStorageDaysCount, TempTablesManager)
	
	SetPrivilegedMode(True);

	If FilesTransferSetting.IsFilesTransferDetailedSetting Then
		FileOwner		= FilesTransferSetting.OwnerID;
		ExceptionItem	= FilesTransferSetting.FileOwner;
	Else
		FileOwner		= FilesTransferSetting.FileOwner;
		ExceptionItem	= Undefined;
	EndIf;	

	QueryText = QueryTextToRestoreFilesFromFileArchive(FileOwner, FilesTransferSetting, ExceptionsArray, ExceptionItem);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	Query.SetParameter("OwnerType"		, TypeOf(Common.ObjectAttributeValue(FileOwner, "EmptyRefValue")));
	Query.SetParameter("DaysCount"		, OperationalStorageDaysCount);
	Query.SetParameter("DateOfProcessing"		, CurrentSessionDate());
	Query.SetParameter("RestoreAllFiles", FilesTransferSetting.Action = Enums.FileArchivingBehavior.DontAddToArchive);

	If ExceptionsArray.Count() > 0 Then

		Query.SetParameter("ExceptionsArray", ExceptionsArray);

	EndIf;

	If FilesTransferSetting.IsFilesTransferDetailedSetting Then

		Query.SetParameter("FilterByDetalizedSetting", ExceptionItem);

	EndIf;	

	Query.Execute();	

EndProcedure

Function QueryTextToRestoreFilesFromFileArchive(FileOwner, Setting, ExceptionsArray, ExceptionItem)

	FilesCatalogAttributes = Common.ObjectAttributesValues(Setting.FileOwnerType, "FullName, Name");

	FilesOwnerMedatada = Common.MetadataObjectByID(FileOwner);
	FilesOwnerFullName = FilesOwnerMedatada.FullName();

	FilesObjectMetadata = Common.MetadataObjectByID(Setting.FileOwnerType);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);

	BatchQueryText = New Array;

	If HasAbilityToStoreVersions Then

		FilesVersionsCatalog	= Common.MetadataObjectID(FilesObjectMetadata.Attributes.CurrentVersion.Type.Types()[0]);
		FilesVersionsMetadata	= Common.MetadataObjectByID(FilesVersionsCatalog);

		FullFilesVersionsCatalogName = FilesVersionsMetadata.FullName();

		QueryText = 
           "SELECT
           |	FilesVersions.Ref AS AttachedFile,
           |	FilesVersions.FileStorageType AS FileStorageType,
           |	FilesVersions.Volume AS Volume,
           |	FilesVersions.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS IsStoringOnDisk,
           |	FilesVersions.Description AS Description,
           |	FilesVersions.Extension AS Extension,
           |	FilesVersions.Owner AS FileToWriteInformationRecords,
           |	FilesVersions.VersionNumber AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	DATEADD(FilesVersions.CreationDate, DAY, &DaysCount) AS TransferToArchivePlannedDate,
           |	FilesVersions.Presentation AS FilePresentation
           |INTO TT_DataPreparationForRestore
           |FROM
           |	#FullFilesCatalogName AS Files
           |		INNER JOIN #FullFilesVersionsCatalogName AS FilesVersions
           |		ON Files.Ref = FilesVersions.Owner
           |			AND (NOT Files.DeletionMark)
           |			AND (NOT FilesVersions.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&FilterByDetalizedSetting)
           |			AND (&IsFilterByExceptions)
           |			AND (CASE
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
           |							OR NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.ExternalBinaryDataStorage)
           |					THEN NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE FALSE
           |			END)
           |			AND (FilesVersions.ArchivingDate <> DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON (FilesVersions.Ref = FileRepository.File)";

		QueryText = StrReplace(QueryText, "#FullFilesCatalogName"		, FilesCatalogAttributes.FullName);
		QueryText = StrReplace(QueryText, "#FullFilesVersionsCatalogName", FullFilesVersionsCatalogName);

		BatchQueryText.Add(QueryText);

	Else // Not HasAbilityToStoreVersions

		QueryText = 
           "SELECT
           |	Files.Ref AS AttachedFile,
           |	Files.FileStorageType AS FileStorageType,
           |	Files.Volume AS Volume,
           |	Files.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS IsStoringOnDisk,
           |	Files.Description AS Description,
           |	Files.Extension AS Extension,
           |	Files.Ref AS FileToWriteInformationRecords,
           |	0 AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	DATEADD(Files.CreationDate, DAY, &DaysCount) AS TransferToArchivePlannedDate,
           |	Files.Presentation AS FilePresentation
           |INTO TT_DataPreparationForRestore
           |FROM
           |	#FileOwnerType AS Files
           |		INNER JOIN #CatalogFileOwner AS CatalogFileOwner
           |		ON Files.FileOwner = CatalogFileOwner.Ref
           |			AND (NOT CatalogFileOwner.DeletionMark)
           |			AND (NOT Files.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&FilterByDetalizedSetting)
           |			AND (&IsFilterByExceptions)
           |			AND (CASE
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
           |							OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.ExternalBinaryDataStorage)
           |					THEN NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE FALSE
           |			END)
           |		INNER JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON Files.Ref = FilesInfo.File
           |			AND (FilesInfo.ArchivingDate <> DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON Files.Ref = FileRepository.File";

		QueryText = StrReplace(QueryText, "#FileOwnerType", "Catalog." + FilesCatalogAttributes.Name);
		QueryText = StrReplace(QueryText, "#CatalogFileOwner", FilesOwnerFullName);		   

		BatchQueryText.Add(QueryText);

	EndIf;	

	QueryText = 
           "SELECT DISTINCT
           |	TT_DataPreparationForRestore.BinaryDataStorage AS BinaryDataStorage
           |INTO TT_DataForDeduplicationCheck
           |FROM
           |	TT_DataPreparationForRestore AS TT_DataPreparationForRestore
           |WHERE
           |	NOT TT_DataPreparationForRestore.IsStoringOnDisk
           |
           |INDEX BY
           |	TT_DataPreparationForRestore.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	FileRepository.BinaryDataStorage AS BinaryDataStorage,
           |	COUNT(*) AS DeduplicatedFilesCount,
           |	COUNT(*) - SUM(CASE
           |			WHEN ISNULL(FilesInfo.ArchivingDate, ISNULL(FilesVersions.ArchivingDate, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1)
           |				THEN CAST(1 AS NUMBER(17, 0))
           |			ELSE 0
           |		END) > 0 AS SubjectToRestorationDueToNewFiles
           |INTO TT_DeduplicatedFiles
           |FROM
           |	TT_DataForDeduplicationCheck AS TT_DataForDeduplicationCheck
           |		INNER JOIN InformationRegister.FileRepository AS FileRepository
           |		ON TT_DataForDeduplicationCheck.BinaryDataStorage = FileRepository.BinaryDataStorage
           |		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON (FileRepository.File = FilesInfo.File)
           |		LEFT JOIN Catalog.FilesVersions AS FilesVersions
           |		ON (FileRepository.File = FilesVersions.Ref)
           |			AND (NOT FilesVersions.Owner.DeletionMark)
           |WHERE
           |	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
           |
           |GROUP BY
           |	FileRepository.BinaryDataStorage
           |
           |HAVING
           |	COUNT(*) > 1
           |
           |INDEX BY
           |	FileRepository.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	TT_DataPreparationForRestore.AttachedFile AS AttachedFile,
           |	TT_DataPreparationForRestore.FileStorageType AS FileStorageType,
           |	TT_DataPreparationForRestore.Volume AS Volume,
           |	TT_DataPreparationForRestore.PathToFile AS PathToFile,
           |	TT_DataPreparationForRestore.BinaryDataStorage AS BinaryDataStorage,
           |	TT_DataPreparationForRestore.Description AS Description,
           |	TT_DataPreparationForRestore.Extension AS Extension,
           |	TT_DataPreparationForRestore.FileToWriteInformationRecords AS FileToWriteInformationRecords,
           |	TT_DataPreparationForRestore.VersionNumber AS VersionNumber,
           |	TT_DataPreparationForRestore.FileOwner AS FileOwner,
           |	NOT TT_DataPreparationForRestore.IsStoringOnDisk AS ReceiveBinaryData,
           |	ISNULL(TT_DeduplicatedFiles.DeduplicatedFilesCount, 0) AS DeduplicatedFilesCount,
           |	ISNULL(DeduplicatedFileStorageInformation.FileStorageType, VALUE(Enum.FileStorageTypes.EmptyRef)) AS FileStorageTypeOperational,
           |	ISNULL(DeduplicatedFileStorageInformation.Volume, VALUE(Catalog.FileStorageVolumes.EmptyRef)) AS VolumeOperational,
           |	"""" AS PathToFileOperational,
           |	TT_DataPreparationForRestore.FilePresentation AS FilePresentation
           |INTO TT_DataForTransfer
           |FROM
           |	TT_DataPreparationForRestore AS TT_DataPreparationForRestore
           |		LEFT JOIN TT_DeduplicatedFiles AS TT_DeduplicatedFiles
           |		ON TT_DataPreparationForRestore.BinaryDataStorage = TT_DeduplicatedFiles.BinaryDataStorage
           |		LEFT JOIN InformationRegister.DeduplicatedFileStorageInformation AS DeduplicatedFileStorageInformation
           |		ON TT_DataPreparationForRestore.BinaryDataStorage = DeduplicatedFileStorageInformation.BinaryDataStorage
           |			AND (DeduplicatedFileStorageInformation.FileStorageKind = VALUE(Enum.StorageKinds.OperationalStorage))
           |WHERE
           |	(&RestoreAllFiles
           |			OR ISNULL(TT_DeduplicatedFiles.SubjectToRestorationDueToNewFiles, FALSE)
           |			OR TT_DataPreparationForRestore.TransferToArchivePlannedDate > &DateOfProcessing)
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DataForDeduplicationCheck
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DeduplicatedFiles
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DataPreparationForRestore";

	BatchQueryText.Add(QueryText);

	QueryText = StrConcat(BatchQueryText, Common.QueryBatchSeparator());

	If ExceptionsArray.Count() > 0 Then
		QueryText = StrReplace(QueryText, "&IsFilterByExceptions", "NOT Files.FileOwner IN HIERARCHY (&ExceptionsArray)");
	Else 
		QueryText = StrReplace(QueryText, "&IsFilterByExceptions", "TRUE");
	EndIf;

	If ExceptionItem <> Undefined Then
		QueryText = StrReplace(QueryText, "&FilterByDetalizedSetting", "Files.FileOwner IN HIERARCHY (&FilterByDetalizedSetting)");
	Else
		QueryText = StrReplace(QueryText, "&FilterByDetalizedSetting", "TRUE");
	EndIf;

	If FilesObjectMetadata.Hierarchical Then
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "NOT Files.IsFolder");
	Else
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "TRUE");
	EndIf;

	Return QueryText;

EndFunction

Procedure TransferFilesToFileArchive(Setting, ExceptionsArray, OperationalStorageDaysCount, AdditionalTransferParameters)

	If Setting.Action = Enums.FileArchivingBehavior.DontAddToArchive Then
		Return;
	EndIf;

	TempTablesManager = New TempTablesManager;

	FillingTemporaryTableForFilesTransfer(Setting, ExceptionsArray, OperationalStorageDaysCount, TempTablesManager);

	InfoToSelectVolume	= InfoAboutFilesToSelectVolume();
	StorageVolumeInfo	= Undefined;

	LastRef = EmptyLinkToAttachedFile(Setting);

	FilesToTransfer = NextFilesPortion(TempTablesManager, LastRef, AdditionalTransferParameters.QueryTextGettingFilesPortionToTransferToArchive);

	While FilesToTransfer.Count() > 0 Do

		ErrorDescriptionString = ErrorDescriptionStringOnOperationsWithTempDirectory(True);

		For Each FileBeingProcessed In FilesToTransfer Do

			If FileBeingProcessed.DeduplicatedFilesCount > 0 Then
				If Not FileBeingProcessed.SubjectToConditionalTransfer Then
					If FileBeingProcessed.FileBeingEdited Then
						Continue;
					EndIf;
					
					//@skip-warning Query not performed for all iterations of the loop.
					If IsFileTransferredToFileArchive(FileBeingProcessed.AttachedFile) Then
						Continue;
					EndIf;
				ElsIf FileBeingProcessed.MarkedAsArchived Then
					Continue;
				EndIf;
			EndIf;
			
			TempDirectory = NewTempDirectoryToWorkWithZipArchive(ErrorDescriptionString);
			
			AttachedFileRef = FileBeingProcessed.AttachedFile;
			
			Block = New DataLock;
			DataLockItem = Block.Add(AttachedFileRef.Metadata().FullName());
			DataLockItem.SetValue("Ref", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);
			
			DataLockItem = Block.Add(Metadata.InformationRegisters.FileRepository.FullName());
			DataLockItem.SetValue("File", AttachedFileRef);

			BeginTransaction();			
			Try   

				Block.Lock();

				If FileBeingProcessed.SubjectToConditionalTransfer Then

					If Not FileBeingProcessed.MarkedAsArchived Then

						ExecuteConditionalFileTransfer(FileBeingProcessed);

					EndIf;

				Else			

					OperationParametersList = TransferOperationExecutionParameters();
					OperationParametersList.TempDirectory	= TempDirectory;

					NewZipArchive = FileToTransferZipArchive(FileBeingProcessed, OperationParametersList);

					FileSize = NewZipArchive.Size;
					// A deduplicated file may be transferred to a disk volume.
					// In this case, a copy of each deduplicated file will be stored on disk.
					// Therefore, when selecting a storage volume, the total required free space is taken into account.
					InfoToSelectVolume.Size = Max(1, FileBeingProcessed.DeduplicatedFilesCount) * FileSize;

					If StorageVolumeInfo = Undefined 
							Or StorageVolumeInfo.MaximumSize <> 0 And StorageVolumeInfo.FreeVolume_ - InfoToSelectVolume.Size < 0 Then
						// File archives can contain only disk volumes or S3 volumes; therefore, the value VolumeUndefinedInVolumes is used.
						StorageVolumeInfo = PickStorageVolume(InfoToSelectVolume, 
																	Enums.StorageKinds.ArchivalStorage,
																	Enums.FileStorageTypes.VolumesVolumeUndefined);
					EndIf;

					OperationParametersList.StorageVolumeInfo = StorageVolumeInfo;

					// @skip-check query-in-loop - Batch processing of large amounts of data.
					TransferFileToFileArchive(FileBeingProcessed, NewZipArchive, OperationParametersList);

					If StorageVolumeInfo.MaximumSize <> 0 Then

						// If a file is transferred to a volume that stores data on a disk partition, the volume
						// space is reduced by the file size, since files in such volumes are deduplicated.
						If StorageVolumeInfo.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
							FileSize = InfoToSelectVolume.Size;
						EndIf;

						StorageVolumeInfo.FreeVolume_ = StorageVolumeInfo.FreeVolume_ - FileSize;

					EndIf;				
				EndIf;
				CommitTransaction();
			Except
				RollbackTransaction();

				ExceptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteFilesTransferEventToEventLog(ExceptionString, EventLogLevel.Error);
				
				DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);
				Continue;				
			EndTry;
		EndDo;

		DeleteTemporaryDirectory(TempDirectory, ErrorDescriptionString);

		LastRef = FileBeingProcessed.AttachedFile;

		// @skip-check query-in-loop - Batch processing of large amounts of data.
		FilesToTransfer = NextFilesPortion(TempTablesManager, LastRef, AdditionalTransferParameters.QueryTextGettingFilesPortionToTransferToArchive);

	EndDo;

EndProcedure

Function StorageVolumeInfo()

	Result = New Structure;
	Result.Insert("Ref"					, Catalogs.FileStorageVolumes.EmptyRef());
	Result.Insert("MaximumSize"		, 0);
	Result.Insert("FreeVolume_"			, 0);
	Result.Insert("VolumePath"				, "");
	Result.Insert("NewFileStorageType"	, Enums.FileStorageTypes.EmptyRef());

	Return Result;

EndFunction

Function PickStorageVolume(AttachedFile, StorageVolumeType, FileStorageType)

	NewFileStorageType = FileStorageType;

	Result = StorageVolumeInfo();

	FreeVolume = FreeStorageVolumeByFilesStorageType(AttachedFile, NewFileStorageType, StorageVolumeType);
	If NewFileStorageType = Enums.FileStorageTypes.VolumesVolumeUndefined Then
		NewFileStorageType = StorageTypeByFilesStorageVolume(FreeVolume);
	EndIf;	

	VolumeAttributesValues = Common.ObjectAttributesValues(FreeVolume, "Ref, MaximumSize");

	Result.Ref				= VolumeAttributesValues.Ref;
	Result.MaximumSize	= VolumeAttributesValues.MaximumSize;

	If Result.MaximumSize <> 0 Then

		Result.FreeVolume_ = Result.MaximumSize * 1024 * 1024 - FilesOperationsInVolumesInternal.VolumeSize(FreeVolume);

	EndIf;

	Result.NewFileStorageType = NewFileStorageType;
	If NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
		Result.VolumePath = FilesOperationsInVolumesInternal.FullVolumePath(FreeVolume);
	EndIf;

	Return Result;

EndFunction

Procedure RestoreFileFromFileArchive(FileBeingProcessed, ExtractedFile, OperationParametersList)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("Volume"						, OperationParametersList.StorageVolumeInfo.Ref);
	AttributesToChange.Insert("FileStorageType"			, OperationParametersList.StorageVolumeInfo.NewFileStorageType);
	AttributesToChange.Insert("MarkedAsArchived"	, False); // Reset the archivation flag
	AttributesToChange.Insert("ArchivingDate"		, Date(1,1,1));	

	If OperationParametersList.StorageVolumeInfo.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

		If FileBeingProcessed.DeduplicatedFilesCount = 0 Then

			RestoreExtractedFileToTemporaryVolumeOnDisk(FileBeingProcessed, ExtractedFile, OperationParametersList);

			DeleteInitialFile = False;

			If FileBeingProcessed.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				DeleteInitialFile = True;
			Else
				InformationRegisters.FileRepository.DeleteBinaryData(FileBeingProcessed.AttachedFile);
			EndIf;

			AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
			ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange);

			If DeleteInitialFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.InitialFilePath);
			EndIf;

		Else

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(FileBeingProcessed.BinaryDataStorage, True);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				RestoreExtractedFileToTemporaryVolumeOnDisk(DeduplicatedFile, ExtractedFile, OperationParametersList);
				InformationRegisters.FileRepository.DeleteBinaryData(DeduplicatedFile.AttachedFile);

				AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
				ChangeAttachedFileAttributes(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;

	Else

		AttributesToChange.Insert("PathToFile", "");
		FileToProcessBinaryData = New BinaryData(ExtractedFile.FileName);

		RecordingParametersVIB = ParametersForWritingToInfobase();
		FillPropertyValues(RecordingParametersVIB, AttributesToChange);

		If FileBeingProcessed.DeduplicatedFilesCount = 0 Then

			DeleteInitialFile = False;			

			If FileBeingProcessed.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

				If OperationParametersList.AreStorageParametersReceived Then
					// The operational storage parameters have already been retrieved, so we only need to update the attachment attributes
					// and add an entry to the FileRepository information register. The binary data remains unchanged.
					RecordingParametersVIB.DoNotChangeBinaryData = True;
				EndIf;

				InformationRegisters.FileRepository.WriteBinaryData(FileBeingProcessed.AttachedFile, FileToProcessBinaryData, RecordingParametersVIB);

				DeleteInitialFile = True;
			Else
				RestoreFileToTemporaryStorage(FileBeingProcessed.BinaryDataStorage, FileToProcessBinaryData, OperationParametersList);
			EndIf;

			ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange);

			If DeleteInitialFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.InitialFilePath);
			EndIf;
			
		Else

			RestoreFileToTemporaryStorage(FileBeingProcessed.BinaryDataStorage, FileToProcessBinaryData, OperationParametersList);

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(FileBeingProcessed.BinaryDataStorage, True);

			For Each DeduplicatedFile In DeduplicatedFiles Do
				ChangeAttachedFileAttributes(DeduplicatedFile, AttributesToChange);
			EndDo;
		EndIf
	EndIf;

EndProcedure

Procedure RestoreFileToTemporaryStorage(Var_BinaryDataStorage, BinaryData, OperationParametersList)

	FileStorageType = OperationParametersList.StorageVolumeInfo.NewFileStorageType;

	StorageAttributesValues = New Structure;
	StorageAttributesValues.Insert("BinaryDataInArchive", Undefined);	

	If Not OperationParametersList.AreStorageParametersReceived Then

		AddBinaryDataStorageAttributeToChange(StorageAttributesValues, FileStorageType, BinaryData);

		RecordingParametersVIB = ParametersForWritingToInfobase();	
		RecordingParametersVIB.FileStorageType			= FileStorageType;
		RecordingParametersVIB.Volume						= OperationParametersList.StorageVolumeInfo.Ref;

		InformationRegisters.DeduplicatedFileStorageInformation.AddRecord(Var_BinaryDataStorage, RecordingParametersVIB);
	EndIf;

	WriteBinaryDataToInfobase(Var_BinaryDataStorage, StorageAttributesValues);	

	InformationRegisters.DeduplicatedFileStorageInformation.DeleteRecord(Var_BinaryDataStorage, Enums.StorageKinds.ArchivalStorage);												

EndProcedure

Procedure TransferFileToFileArchive(FileBeingProcessed, ZipArchive, OperationParametersList)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("Volume"						, OperationParametersList.StorageVolumeInfo.Ref);
	AttributesToChange.Insert("FileStorageType"			, OperationParametersList.StorageVolumeInfo.NewFileStorageType);
	AttributesToChange.Insert("MarkedAsArchived"	, False);
	AttributesToChange.Insert("ArchivingDate"		, CurrentSessionDate());	

	If OperationParametersList.StorageVolumeInfo.NewFileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

		If FileBeingProcessed.DeduplicatedFilesCount = 0 Then

			TransferZipArchiveToArchiveVolumeOnDisk(FileBeingProcessed, ZipArchive, OperationParametersList);			

			DeleteInitialFile = False;
			If FileBeingProcessed.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				DeleteInitialFile = True;
			Else
				InformationRegisters.FileRepository.DeleteBinaryData(FileBeingProcessed.AttachedFile);
			EndIf;

			AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);
			ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange);

			If DeleteInitialFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.InitialFilePath);
			EndIf;
		Else

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(FileBeingProcessed.BinaryDataStorage);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				TransferZipArchiveToArchiveVolumeOnDisk(DeduplicatedFile, ZipArchive, OperationParametersList);
				InformationRegisters.FileRepository.DeleteBinaryData(DeduplicatedFile.AttachedFile);

				AttributesToChange.Insert("PathToFile", OperationParametersList.NewPathToFileInsideVolume);				
				ChangeAttachedFileAttributes(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;
	Else
        // Transfer to S3 archive storage
		// If the file was stored in internal storage, only the storage attribute is updated.
		// If the file was stored on disk, the system locates or creates a BinaryDataStorage and
		// adds a record to FileRepository information register.

		AttributesToChange.Insert("PathToFile", "");

		If FileBeingProcessed.DeduplicatedFilesCount = 0 Then

			DeleteInitialFile = False;

			If FileBeingProcessed.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then
				// Transfer the file from the disk to the internal storage. (Should be checked for deduplicated elements.)
				FileToProcessBinaryData = New BinaryData(OperationParametersList.InitialFilePath);
				BinaryDataStorageRef = BinaryDataStorageItemByBinaryData(FileToProcessBinaryData);

				If BinaryDataStorageRef <> Undefined Then
					If IsBinaryDataStorageAvailableInFileArchive(BinaryDataStorageRef) Then
						// The common binary data storage has been moved to the archive, so no transfer is required.
						// The attachment's storage parameters are updated using data from DeduplicatedFilesStorageInformation.
						// Attribute TransferToArchiveDate is set to the current session date.
						DeduplicatedFilesStorageKind = Enums.StorageKinds.ArchivalStorage;
					Else
						// The common binary data storage is absent from the archive, so no transfer is required.
						// The attachment's storage parameters are updated using data from DeduplicatedFilesStorageInformation.
						// Attribute TransferToArchiveDate is cleared, and MarkedAsArchived is set to True.
						DeduplicatedFilesStorageKind = Enums.StorageKinds.OperationalStorage;
						AttributesToChange.Insert("MarkedAsArchived"	, True);
						AttributesToChange.Insert("ArchivingDate"		, Date(1,1,1));
					EndIf;

					StoringFilesInfo = InformationRegisters.DeduplicatedFileStorageInformation.DeduplicatedFileStorageInformation(
																								BinaryDataStorageRef,
																								DeduplicatedFilesStorageKind);

					If StoringFilesInfo = Undefined Then

						Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
														"ru = 'В регистре сведений ""Сведения о хранении дедуплицированных файлов"" отсутствуют данные для 
														|элемента справочника ""Хранилище двоичных данных"": %1 по виду хранения файлов: %2';
														|vi = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2';
														|en = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2'; fa = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2';
														|it = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2';
														|pl = 'The ""Deduplicated file storage information"" information register is missing an entry
														|for the ""Binary data storage"" catalog: %1. Storage method: %2';
														|tr = '""Tekilleştirilmiş dosya saklama bilgileri"" bilgi kaydında, ""İkili veri deposu"" kılavuzunun 
														| öğesi için veri bulunmuyor: %1, dosya saklama türüne göre: %2'"),
														BinaryDataStorageRef,
														DeduplicatedFilesStorageKind);
					EndIf;
					
					FillPropertyValues(AttributesToChange, StoringFilesInfo);
					
					InformationRegisters.FileRepository.AddRecord(FileBeingProcessed.AttachedFile, BinaryDataStorageRef);
					
				Else
					// Create in the BinaryDataStorage catalog a new item whose binary data will be stored in the file archive.
					RecordingParametersVIB = ParametersForWritingToInfobase();
					FillPropertyValues(RecordingParametersVIB,AttributesToChange);
					RecordingParametersVIB.IsWriteToFileArchive = True;
					RecordingParametersVIB.BinaryDataOfArchive = New BinaryData(ZipArchive.FileName);
					
					InformationRegisters.FileRepository.WriteBinaryData(FileBeingProcessed.AttachedFile, FileToProcessBinaryData, RecordingParametersVIB);
				EndIf;

				DeleteInitialFile = True;
			Else
				// Deduplication is not supported for disk storage. Therefore, for a file with a different storage type,
				// a BinaryDataStorage catalog item has already been created. The data must be moved from the operational storage attribute
				// to the archival storage attribute, and the attachment's attributes must be updated.
				TransferZipArchiveToArchiveVolumeS3Storage(FileBeingProcessed, ZipArchive, OperationParametersList);
			EndIf;

			ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange);

			If DeleteInitialFile Then
				FilesOperationsInVolumesInternal.DeleteFile(OperationParametersList.InitialFilePath);
			EndIf;

		Else
			// Deduplication is not supported for disk storage. Therefore, the presence of other deduplicated files indicates that
			// a BinaryDataStorage directory item has already been created. You should move the binary data from the operational storage attribute to
			// the archive storage attribute and update the attributes of all deduplicated files by setting the storage parameters and
			// the TransferToArchiveDate attribute.
			TransferZipArchiveToArchiveVolumeS3Storage(FileBeingProcessed, ZipArchive, OperationParametersList);

			DeduplicatedFiles = DeduplicatedFilesByBinaryDataStorage(FileBeingProcessed.BinaryDataStorage);

			For Each DeduplicatedFile In DeduplicatedFiles Do

				ChangeAttachedFileAttributes(DeduplicatedFile, AttributesToChange);

			EndDo;
		EndIf;
	EndIf;

EndProcedure

Function TransferOperationExecutionParameters()

	Result = New Structure;
	Result.Insert("StorageVolumeInfo");
	Result.Insert("ZipArchiveNameWithoutExtension"	, "");
	Result.Insert("ZipArchiveExtension"		, "");
	Result.Insert("NewPathToFileInsideVolume"	, "");
	Result.Insert("InitialFilePath"			, "");
	Result.Insert("TempDirectory"			, "");

	Return Result;

EndFunction

Function RecoveryOperationExecutionParameters()

	Result = New Structure;
	Result.Insert("StorageVolumeInfo");
	Result.Insert("NewPathToFileInsideVolume"		, "");
	Result.Insert("InitialFilePath"				, "");
	Result.Insert("TempDirectory"				, "");
	Result.Insert("AreStorageParametersReceived"		, False);
	Result.Insert("FilesStorageMethod"			, "");

	Return Result;

EndFunction

Procedure AddBinaryDataStorageAttributeToChange(AttributesToChange, FileStorageType, AttributeValue = Undefined)

	AttributeName = FileManagementInBinaryDataStorageInternal.DefineBinaryDataStorageAttributeByFileStorageType(FileStorageType);
	If AttributeName <> Undefined Then
		AttributesToChange.Insert(AttributeName, AttributeValue);
	EndIf;

EndProcedure

Procedure WriteBinaryDataToInfobase(Var_BinaryDataStorage, StorageAttributesValues)

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	BeginTransaction();
	Try

		If StorageAttributesValues.Property("BinaryData") Then

			Block = New DataLock;
			Block.Add("Catalog.BinaryDataStorage").SetValue("Ref", Var_BinaryDataStorage);
			Block.Lock();

			BinaryDataStorageObject = Var_BinaryDataStorage.GetObject();
			BinaryDataStorageObject.Lock();
			
			BinaryDataStorageObject.BinaryData = PrepareBinaryDataToWrite(StorageAttributesValues.BinaryData);
			BinaryDataStorageObject.Write();

		EndIf;
		
		If ShouldUseBinaryDataStorageLocations(StorageAttributesValues) Then

			RecordAttributesValues = New Structure;
			For Each AttributeValue In StorageAttributesValues Do
				
				If AttributeValue.Key <> "BinaryData" Then
					RecordAttributesValues.Insert(AttributeValue.Key, PrepareBinaryDataToWrite(AttributeValue.Value));
				EndIf;
				
			EndDo;

			InformationRegisters.BinaryDataStorages.AddChangeRecord(Var_BinaryDataStorage, RecordAttributesValues);
		EndIf;

		CommitTransaction();	
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Function ShouldUseBinaryDataStorageLocations(StorageAttributesValues)

	For Each StorageAttributeValue In StorageAttributesValues Do
		If StorageAttributeValue.Key = "BinaryDataInArchive"
				Or StorageAttributeValue.Key = "BinaryDataInInternalOperationalStorage"
				Or StorageAttributeValue.Key = "BinaryDataInExternalOperationalStorage" Then
			Return True;
		EndIf;
	EndDo;

	Return False;	

EndFunction

Procedure RestoreExtractedFileToTemporaryVolumeOnDisk(FileBeingProcessed, ExtractedFile, OperationParametersList)

	PathToSourceFile = ExtractedFile.FileName;

	FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume();
	FileProperties.Description	= FileBeingProcessed.Description;
	FileProperties.Extension	= FileBeingProcessed.Extension;
	FileProperties.Volume			= OperationParametersList.StorageVolumeInfo.Ref;
	FileProperties.PathToFile	= "";
	FileProperties.VersionNumber	= FileBeingProcessed.VersionNumber;
	FileProperties.FileOwner = FileBeingProcessed.FileOwner;

	PathToCopyFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);

	OperationParametersList.NewPathToFileInsideVolume = Mid(PathToCopyFile, StrLen(OperationParametersList.StorageVolumeInfo.VolumePath) + 1);

	CopyFileWithCheck(PathToSourceFile, PathToCopyFile);
	
EndProcedure

Procedure CopyFileWithCheck(PathToSourceFile, PathToCopyFile)
		
	SourceFileSize = FileSize(PathToSourceFile);
	
	CopyFile(PathToSourceFile, PathToCopyFile);
	
	CopyFileSize = FileSize(PathToCopyFile);

	If SourceFileSize <> CopyFileSize Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Не совпадает размер исходного и скопированного файла
					|		
					|Исходный файл
					|Путь к файлу: ""%1"" 
					|Размер файла: %2
					|
					|Файл копия
					|Путь к файлу: ""%3"" 
					|Размер файла: %4';
					|vi = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4';
					|en = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4'; fa = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4';
					|it = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4';
					|pl = 'The size of the original and copied file does not match
					|		
					|Original file
					|Path: %1
					|Size: %2
					|
					|Copied file
					|Path: %3
					|Size: %4';
					|tr = 'Kaynak dosya ile kopyalanan dosyanın boyutu uyuşmuyor
					|		
					|Kaynak dosya
					| Dosya yolu: ""%1"" 
					|Dosya boyutu: %2
					|
					|Dosya kopyası
					|Dosya yolu: ""%3"" 
					|Dosya boyutu: %4'"), PathToSourceFile, SourceFileSize, PathToCopyFile, CopyFileSize);
	EndIf;
	
EndProcedure

Procedure TransferZipArchiveToArchiveVolumeOnDisk(FileBeingProcessed, ZipArchive, OperationParametersList, GenerateZipArchiveNewName = False)

	PathToSourceFile = ZipArchive.FileName;
	
	FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume();
	FileProperties.Description	= ?(GenerateZipArchiveNewName, NewZipArchiveFileName(), OperationParametersList.ZipArchiveNameWithoutExtension);
	FileProperties.Extension	= OperationParametersList.ZipArchiveExtension;
	FileProperties.Volume			= OperationParametersList.StorageVolumeInfo.Ref;
	FileProperties.PathToFile	= "";
	FileProperties.VersionNumber	= FileBeingProcessed.VersionNumber;
	FileProperties.FileOwner = FileBeingProcessed.FileOwner;

	PathToCopyFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);

	OperationParametersList.NewPathToFileInsideVolume = Mid(PathToCopyFile, StrLen(OperationParametersList.StorageVolumeInfo.VolumePath) + 1);

	CopyFileWithCheck(PathToSourceFile, PathToCopyFile);

EndProcedure

Procedure TransferZipArchiveToArchiveVolumeS3Storage(FileBeingProcessed, ZipArchive, OperationParametersList)

	StorageAttributesValues = New Structure;
	StorageAttributesValues.Insert("BinaryDataInArchive", New BinaryData(ZipArchive.FileName));
	AddBinaryDataStorageAttributeToChange(StorageAttributesValues, FileBeingProcessed.FileStorageType);

	WriteBinaryDataToInfobase(FileBeingProcessed.BinaryDataStorage, StorageAttributesValues);

	RecordingParametersVIB = ParametersForWritingToInfobase();	
	RecordingParametersVIB.FileStorageType			= OperationParametersList.StorageVolumeInfo.NewFileStorageType;
	RecordingParametersVIB.Volume						= OperationParametersList.StorageVolumeInfo.Ref;
	RecordingParametersVIB.IsWriteToFileArchive	= True;

	InformationRegisters.DeduplicatedFileStorageInformation.AddRecord(
										FileBeingProcessed.BinaryDataStorage, 
										RecordingParametersVIB);

	InformationRegisters.DeduplicatedFileStorageInformation.DeleteRecord(FileBeingProcessed.BinaryDataStorage, Enums.StorageKinds.OperationalStorage);

EndProcedure

Function InfoAboutFilesToSelectVolume()

	Result = New Structure;
	Result.Insert("Size"			, 0);
	Result.Insert("Description"	, "");
	Result.Insert("Extension"		, "");

	Return Result;

EndFunction

Function FileSize(PathToFile, RaiseException1 = True)

	Result = 0;

	File = New File(PathToFile);
	If File.Exists() Then
		Result = File.Size();
	ElsIf RaiseException1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Файл ""%1"" не найден.';
			|vi = 'File ""%1"" is not found.';
			|en = 'File ""%1"" is not found.'; fa = 'File ""%1"" is not found.';
			|it = 'File ""%1"" non trovato.';
			|pl = 'Nie znaleziono pliku ""%1"".';
			|tr = '""%1"" dosya bulunmadı.'"), PathToFile);		
	EndIf;

	Return Result;

EndFunction

Function ExtractedFileProperties()

	Result = New Structure;
	Result.Insert("FileName"		, "");
	Result.Insert("NameWithExtension", "");
	Result.Insert("Size"			, 0);

	Return Result;

EndFunction

Function FileExtractedFromZipArchive(FileBeingProcessed, OperationParametersList)

	Result = ExtractedFileProperties();

	Try

		TempDirectory = OperationParametersList.TempDirectory;

		If FileBeingProcessed.FileStorageType <> Enums.FileStorageTypes.InVolumesOnHardDrive Then
			
			ZipArchiveBinaryData = FileBinaryData(FileBeingProcessed, False);

		Else
			PathToArchiveFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(
											New Structure("Volume, PathToFile", FileBeingProcessed.Volume, FileBeingProcessed.PathToFile));

			FileOnHardDrive = New File(PathToArchiveFile);
			If Not FileOnHardDrive.Exists() Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Файл ""%1"" не найден.';
					|vi = 'File ""%1"" is not found.';
					|en = 'File ""%1"" is not found.'; fa = 'File ""%1"" is not found.';
					|it = 'File ""%1"" non trovato.';
					|pl = 'Nie znaleziono pliku ""%1"".';
					|tr = '""%1"" dosya bulunmadı.'"), PathToArchiveFile);
			EndIf;

			OperationParametersList.InitialFilePath = PathToArchiveFile;

			ZipArchiveBinaryData = New BinaryData(PathToArchiveFile);
		EndIf;

		ExtractedFileName = CommonClientServer.GetNameWithExtension(FileBeingProcessed.Description, FileBeingProcessed.Extension);

		ExtractedFileData = ExtractFileFromZipArchive(ZipArchiveBinaryData, ExtractedFileName, TempDirectory);

		Result.Size = ExtractedFileData.Size;

		Result.FileName			= ExtractedFileData.FileName;
		Result.NameWithExtension	= ExtractedFileName;

	Except
		ErrorDescriptionTemplate = NStr("ru = 'Ошибка при восстановлении файла ""%1""
			|Не удалось извлечь файл из zip-архива
			|""%2"".';
			|vi = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1';
			|en = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1'; fa = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1';
			|it = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1';
			|pl = 'Failed to extract file from ZIP archive.
			|Archive: %2
			|File: %1';
			|tr = '""%1"" dosyası geri yüklenirken hata oluştu
			|Dosya zip arşivinden çıkarılamadı
			| ""%2"".'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ExtractedFileName,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Raise ExceptionString;
	EndTry;

	Return Result;

EndFunction

Function FileToTransferZipArchive(FileBeingProcessed, OperationParametersList)

	Try	

		TempDirectory = OperationParametersList.TempDirectory;

		If FileBeingProcessed.FileStorageType <> Enums.FileStorageTypes.InVolumesOnHardDrive Then
			PathToFileBeingArchived = PathToFileBeingArchivedInTempDirectory(FileBeingProcessed, TempDirectory);

			FileBinaryData = FileBinaryData(FileBeingProcessed);

			If TypeOf(FileBinaryData) <> Type("BinaryData") Then
				ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("ru = 'Данных файла имеют неверный тип: ""%1""
															|Верный тип: ""ДвоичныеДанные""';
															|vi = 'The file data has an invalid type.
															|Expected BinaryData, got %1';
															|en = 'The file data has an invalid type.
															|Expected BinaryData, got %1'; fa = 'The file data has an invalid type.
															|Expected BinaryData, got %1';
															|it = 'The file data has an invalid type.
															|Expected BinaryData, got %1';
															|pl = 'The file data has an invalid type.
															|Expected BinaryData, got %1';
															|tr = 'Dosya verileri yanlış türde: ""%1""
															|Doğru tür: ""İkiliVeri""'"), TypeOf(FileBinaryData));
				Raise ExceptionString;
			EndIf;
			
			FileBinaryData.Write(PathToFileBeingArchived);
		Else
			PathToFileBeingArchived = FilesOperationsInVolumesInternal.FullFileNameInVolume(
											New Structure("Volume, PathToFile", FileBeingProcessed.Volume, FileBeingProcessed.PathToFile));

			FileOnHardDrive = New File(PathToFileBeingArchived);
			If Not FileOnHardDrive.Exists() Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Архивируемый файл ""%1"" не найден.';
					|vi = 'File to add to archive not found: %1.';
					|en = 'File to add to archive not found: %1.'; fa = 'File to add to archive not found: %1.';
					|it = 'File to add to archive not found: %1.';
					|pl = 'File to add to archive not found: %1.';
					|tr = 'Arşivlenecek ""%1"" dosyası bulunamadı.'"), PathToFileBeingArchived);
			EndIf;											

			OperationParametersList.InitialFilePath = PathToFileBeingArchived;
		EndIf;

		ArchiveFileNameWithoutExtension = NewZipArchiveFileName();
		NameOfArchiveFile = CommonClientServer.GetNameWithExtension(ArchiveFileNameWithoutExtension, "zip");

		PathToArchiveFile = TempDirectory + NameOfArchiveFile;

		NewZipArchive = PackFileToZipArchive(PathToArchiveFile, PathToFileBeingArchived);

		OperationParametersList.ZipArchiveNameWithoutExtension = ArchiveFileNameWithoutExtension;
		OperationParametersList.ZipArchiveExtension		= "zip";

	Except	

		ErrorDescriptionTemplate = NStr("ru = 'Ошибка при переносе файла ""%1""
			|Не создан zip-архив
			|""%2"".';
			|vi = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.';
			|en = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.'; fa = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.';
			|it = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.';
			|pl = 'Couldn''t move file %1.
			|The ZIP archive was not created:
			|%2.';
			|tr = '""%1"" dosyası taşınırken hata oluştu
			|Zip arşivi oluşturulmadı
			|""%2"".'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			FileBeingProcessed.Description + "." + FileBeingProcessed.Extension,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));

		Raise ExceptionString;

	EndTry;

	Return NewZipArchive;

EndFunction

Function NewZipArchiveFileName()

	Return String(New UUID);

EndFunction

Function FileBinaryData(FileBeingProcessed, IsTransferToFileArchive = True)

	Result = FileBeingProcessed.FileBinaryData;

	If TypeOf(Result) = Type("ValueStorage") Then
		Result = Result.Get();
		If TypeOf(Result) = Type("BinaryData") Then
			Return Result;
		EndIf;
	EndIf;

	If IsTransferToFileArchive Then
		If Not ValueIsFilled(Result) Or TypeOf(Result) <> Type("BinaryData") Then
			Result = FilesOperations.FileBinaryData(FileBeingProcessed.AttachedFile);
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function PathToFileBeingArchivedInTempDirectory(FileBeingProcessed, TempDirectory = "")

	SetPrivilegedMode(True);

	If TempDirectory = "" Then
		ErrorDescriptionString = ErrorDescriptionStringOnOperationsWithTempDirectory(True);
		TempDirectory = NewTempDirectoryToWorkWithZipArchive(ErrorDescriptionString);
	EndIf;

	FileName = CommonClientServer.GetNameWithExtension(FileBeingProcessed.Description, FileBeingProcessed.Extension);

	Return TempDirectory + FileName;

EndFunction

Procedure ExecuteConditionalFileTransfer(FileBeingProcessed)

	AttributesToChange = New Structure;
	AttributesToChange.Insert("MarkedAsArchived", True);
	ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange);	

EndProcedure

Procedure ChangeAttachedFileAttributes(FileBeingProcessed, AttributesToChange)

	FileRef = FileBeingProcessed.AttachedFile;

	HasAttributesMissingInDetails = HasAttributesMissingInDetails(AttributesToChange, FileRef);
	
	Block = New DataLock;
	DataLockItem = Block.Add(FileRef.Metadata().FullName());
	DataLockItem.SetValue("Ref", FileRef);

	If HasAttributesMissingInDetails Then	
		DataLockItem = Block.Add(Metadata.InformationRegisters.FilesInfo.FullName());
		DataLockItem.SetValue("File", FileBeingProcessed.FileToWriteInformationRecords);
	EndIf;
	
	BeginTransaction();	
	Try

		Block.Lock();

		FileObject1 = FileRef.GetObject();
		FileObject1.Lock();
		
		FillPropertyValues(FileObject1, AttributesToChange);
		FileObject1.Write();

		If HasAttributesMissingInDetails Then

			SetOfPCRecords = InformationRegisters.FilesInfo.CreateRecordSet();
			SetOfPCRecords.Filter.File.Set(FileBeingProcessed.FileToWriteInformationRecords);
			SetOfPCRecords.Read();
			
			If SetOfPCRecords.Count() = 1 Then
				RsRecording = SetOfPCRecords[0];
			Else
				RsRecording = SetOfPCRecords.Add();
			EndIf;
			
			If Not ValueIsFilled(RsRecording.File) Then
				RsRecording.File = FileBeingProcessed.FileToWriteInformationRecords;
				FillPropertyValues(RsRecording, FileBeingProcessed.FileToWriteInformationRecords);
			EndIf;

			FillPropertyValues(RsRecording, AttributesToChange);		

			SetOfPCRecords.Write();

		EndIf;

		CommitTransaction();

	Except
		RollbackTransaction();

		NameForLog = CommonClientServer.GetNameWithExtension(FileBeingProcessed.Description,
			FileBeingProcessed.Extension);

		Error = DataProcessors.FileTransfer.TransferError(FileRef, ErrorInfo());
		Error.FileName = NameForLog;

		FileLinkPresentation = AttachedFilePresentation(FileRef, FileBeingProcessed.FilePresentation);
		
		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
															NStr("ru = 'Не удалось перенести файл %1
															|%2
															|по причине:
															|%3"".';
															|vi = 'Couldn''t move file %1
															|%2
															|due to:
															|%3"".';
															|en = 'Couldn''t move file %1
															|%2
															|due to:
															|%3"".'; fa = 'Couldn''t move file %1
															|%2
															|due to:
															|%3"".';
															|it = 'Не удалось перенести файл %1
															|%2
															|по причине:
															|%3"".';
															|pl = 'Couldn''t move file %1
															|%2
															|due to:
															|%3"".';
															|tr = '%1
															|%2
															|dosyası şu nedenle aktarılamadı:
															|%3"".'"),
															FileLinkPresentation, 
															NameForLog, Error.DetailErrorDescription);

		Raise ExceptionString;

	EndTry;		

EndProcedure

Function AttachedFilePresentation(AttachedFileRef, FilePresentation)
	
	FileAttachedMetadata = AttachedFileRef.Metadata();

	ObjectPresentation = FileAttachedMetadata.ObjectPresentation;
	If IsBlankString(ObjectPresentation) Then
		ObjectPresentation = FileAttachedMetadata.Presentation();
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", FilePresentation, ObjectPresentation);	

EndFunction

Function HasAttributesMissingInDetails(AttributesToChange, FileRef)

	Result = False;
	
	Attributes = FileRef.Metadata().Attributes;
	For Each Attribute In AttributesToChange Do
		If Attributes.Find(Attribute.Key) = Undefined Then
			Result = True;
			Break;
		EndIf;
	EndDo;

	Return Result;

EndFunction

Function EmptyLinkToAttachedFile(Setting)

	If Setting.IsFile Then
		Result = Catalogs.FilesVersions.EmptyRef();
	Else
		Result = Common.ObjectAttributeValue(Setting.FileOwnerType, "EmptyRefValue");
	EndIf;

	Return Result;

EndFunction

Procedure FillingTemporaryTableForFilesTransfer(FilesTransferSetting, ExceptionsArray, OperationalStorageDaysCount, TempTablesManager)

	SetPrivilegedMode(True);

	If FilesTransferSetting.IsFilesTransferDetailedSetting Then
		FileOwner		= FilesTransferSetting.OwnerID;
		ExceptionItem	= FilesTransferSetting.FileOwner;
	Else
		FileOwner		= FilesTransferSetting.FileOwner;
		ExceptionItem	= Undefined;
	EndIf;	

	QueryText = QueryTextToTransferFilesToFileArchive(FileOwner, FilesTransferSetting, ExceptionsArray, ExceptionItem);

	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;

	Query.SetParameter("OwnerType"	, TypeOf(Common.ObjectAttributeValue(FileOwner, "EmptyRefValue")));
	Query.SetParameter("DaysCount"	, OperationalStorageDaysCount);
	Query.SetParameter("DateOfProcessing"	, CurrentSessionDate());
	
	EmptyUsers = New Array;
	EmptyUsers.Add(Undefined);
	EmptyUsers.Add(Catalogs.Users.EmptyRef());
	EmptyUsers.Add(Catalogs.ExternalUsers.EmptyRef());
	EmptyUsers.Add(Catalogs.FileSynchronizationAccounts.EmptyRef());
	
	Query.SetParameter("EmptyUsers", EmptyUsers);

	If ExceptionsArray.Count() > 0 Then

		Query.SetParameter("ExceptionsArray", ExceptionsArray);

	EndIf;

	If FilesTransferSetting.IsFilesTransferDetailedSetting Then

		Query.SetParameter("FilterByDetalizedSetting", ExceptionItem);

	EndIf;	

	Query.Execute();

EndProcedure

Function NextFilesPortion(TempTablesManager, LastRef, QueryText)

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("LastRef", LastRef);

	Return Query.Execute().Unload();

EndFunction

Function FilesPortionQueryText(PortionSize, IsTransferToFileArchive = True)

	Result = 
       "SELECT TOP 10
       |	TT_DataForTransfer.AttachedFile AS AttachedFile,
       |	TT_DataForTransfer.FilePresentation AS FilePresentation,	   
       |	TT_DataForTransfer.FileStorageType AS FileStorageType,
       |	TT_DataForTransfer.BinaryDataStorage AS BinaryDataStorage,
       |	TT_DataForTransfer.Volume AS Volume,
       |	TT_DataForTransfer.PathToFile AS PathToFile,
       |	TT_DataForTransfer.Description AS Description,
       |	TT_DataForTransfer.Extension AS Extension,
       |	TT_DataForTransfer.DeduplicatedFilesCount AS DeduplicatedFilesCount,
       |	TT_DataForTransfer.FileToWriteInformationRecords AS FileToWriteInformationRecords,
       |	TT_DataForTransfer.VersionNumber AS VersionNumber,
       |	TT_DataForTransfer.FileOwner AS FileOwner,
       |	&AdditionalFields AS AdditionalFields,
       |	&BinaryDataField AS FileBinaryData
       |FROM
       |	TT_DataForTransfer AS TT_DataForTransfer
       |		LEFT JOIN Catalog.BinaryDataStorage AS BinaryDataStorageCatalog
       |		ON TT_DataForTransfer.BinaryDataStorage = BinaryDataStorageCatalog.Ref
       |			AND (TT_DataForTransfer.ReceiveBinaryData)
       |		LEFT JOIN InformationRegister.BinaryDataStorages AS BinaryDataStorages
       |		ON TT_DataForTransfer.BinaryDataStorage = BinaryDataStorages.BinaryDataStorage
       |WHERE
       |	TT_DataForTransfer.AttachedFile > &LastRef
       |
       |ORDER BY
       |	AttachedFile";
	
	If IsTransferToFileArchive Then

		Result = StrReplace(Result, "&BinaryDataField", 
	       "ISNULL(CASE
	       |			WHEN TT_DataForTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)
	       |				THEN BinaryDataStorageCatalog.BinaryData
	       |			WHEN TT_DataForTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.InternalBinaryDataStorage)
		   |				THEN ISNULL(BinaryDataStorages.BinaryDataInInternalOperationalStorage, UNDEFINED)
	       |			WHEN TT_DataForTransfer.FileStorageType = VALUE(Enum.FileStorageTypes.ExternalBinaryDataStorage)
	       |		   		THEN ISNULL(BinaryDataStorages.BinaryDataInExternalOperationalStorage, UNDEFINED)
	       |			ELSE UNDEFINED
	       |		END, UNDEFINED)");

		Result = StrReplace(Result, "&AdditionalFields AS AdditionalFields", 
			"TT_DataForTransfer.MarkedAsArchived AS MarkedAsArchived,
	       	|	TT_DataForTransfer.SubjectToConditionalTransfer AS SubjectToConditionalTransfer,
			|	TT_DataForTransfer.FileBeingEdited AS FileBeingEdited");

	Else
		Result = StrReplace(Result, "&BinaryDataField", "ISNULL(BinaryDataStorages.BinaryDataInArchive, UNDEFINED)");

		Result = StrReplace(Result, "&AdditionalFields AS AdditionalFields",
			"TT_DataForTransfer.FileStorageTypeOperational AS FileStorageTypeOperational,
			|	TT_DataForTransfer.VolumeOperational AS VolumeOperational,
			|	TT_DataForTransfer.PathToFileOperational AS PathToFileOperational");
	EndIf;

	If PortionSize <> 10 Then
		Result = StrReplace(Result, "10", Format(PortionSize, "NG=0"));
	EndIf;	

	Return Result;

EndFunction

Function QueryTextToTransferFilesToFileArchive(FileOwner, Setting, ExceptionsArray, ExceptionItem)

	FilesCatalogAttributes = Common.ObjectAttributesValues(Setting.FileOwnerType, "FullName, Name");

	FilesOwnerMedatada = Common.MetadataObjectByID(FileOwner);
	FilesOwnerFullName = FilesOwnerMedatada.FullName();

	FilesObjectMetadata = Common.MetadataObjectByID(Setting.FileOwnerType);
	HasAbilityToStoreVersions = Common.HasObjectAttribute("CurrentVersion", FilesObjectMetadata);

	BatchQueryText = New Array;

	If HasAbilityToStoreVersions Then

		FilesVersionsCatalog	= Common.MetadataObjectID(FilesObjectMetadata.Attributes.CurrentVersion.Type.Types()[0]);
		FilesVersionsMetadata	= Common.MetadataObjectByID(FilesVersionsCatalog);

		FullFilesVersionsCatalogName = FilesVersionsMetadata.FullName();

		QueryText = 
           "SELECT
           |	FilesVersions.Ref AS AttachedFile,
           |	FilesVersions.FileStorageType AS FileStorageType,
           |	FilesVersions.Volume AS Volume,
           |	FilesVersions.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS IsStoringOnDisk,
           |	FilesVersions.Description AS Description,
           |	FilesVersions.Extension AS Extension,
           |	FilesVersions.Owner AS FileToWriteInformationRecords,
           |	FilesVersions.VersionNumber AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	FilesVersions.MarkedAsArchived AS MarkedAsArchived,
           |	FilesVersions.Presentation AS FilePresentation
           |INTO TT_DataPreparationForTransfer
           |FROM
           |	#FullFilesCatalogName AS Files
           |		INNER JOIN #FullFilesVersionsCatalogName AS FilesVersions
           |		ON Files.Ref = FilesVersions.Owner
           |			AND (NOT Files.DeletionMark)
           |			AND (NOT FilesVersions.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&FilterByDetalizedSetting)
           |			AND (&IsFilterByExceptions)
           |			AND (CASE
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(FilesVersions.PathToFile AS STRING(100))) <> """"
           |							OR NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InternalBinaryDataStorage)
           |						OR FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.ExternalBinaryDataStorage)
           |					THEN NOT FilesVersions.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE TRUE
           |			END)
           |			AND (DATEADD(FilesVersions.CreationDate, DAY, &DaysCount) <= &DateOfProcessing)
           |			AND (FilesVersions.ArchivingDate = DATETIME(1,1,1))
           |			AND (Files.CurrentVersion <> FilesVersions.Ref
           |				OR Files.BeingEditedBy IN (&EmptyUsers))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON (FilesVersions.Ref = FileRepository.File)";

		QueryText = StrReplace(QueryText, "#FullFilesCatalogName", FilesCatalogAttributes.FullName);
		QueryText = StrReplace(QueryText, "#FullFilesVersionsCatalogName", FullFilesVersionsCatalogName);

		BatchQueryText.Add(QueryText);

	Else // Not HasAbilityToStoreVersions

		QueryText = 
           "SELECT
           |	Files.Ref AS AttachedFile,
           |	Files.FileStorageType AS FileStorageType,
           |	Files.Volume AS Volume,
           |	Files.PathToFile AS PathToFile,
           |	ISNULL(FileRepository.BinaryDataStorage, VALUE(Catalog.BinaryDataStorage.EmptyRef)) AS BinaryDataStorage,
           |	Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive) AS IsStoringOnDisk,
           |	Files.Description AS Description,
           |	Files.Extension AS Extension,
           |	Files.Ref AS FileToWriteInformationRecords,
           |	0 AS VersionNumber,
           |	Files.FileOwner AS FileOwner,
           |	FilesInfo.MarkedAsArchived AS MarkedAsArchived,
           |	Files.Presentation AS FilePresentation
           |INTO TT_DataPreparationForTransfer
           |FROM
           |	#FileOwnerType AS Files
           |		INNER JOIN #CatalogFileOwner AS CatalogFileOwner
           |		ON Files.FileOwner = CatalogFileOwner.Ref
           |			AND (NOT CatalogFileOwner.DeletionMark)
           |			AND (NOT Files.DeletionMark)
           |			AND (&ThisIsNotGroup)
           |			AND (VALUETYPE(Files.FileOwner) = &OwnerType)
           |			AND (&FilterByDetalizedSetting)
           |			AND (&IsFilterByExceptions)
           |			AND (CASE
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
           |					THEN (CAST(Files.PathToFile AS STRING(100))) <> """"
           |							OR NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				WHEN Files.FileStorageType = VALUE(Enum.FileStorageTypes.InternalBinaryDataStorage)
           |						OR Files.FileStorageType = VALUE(Enum.FileStorageTypes.ExternalBinaryDataStorage)
           |					THEN NOT Files.Volume = VALUE(Catalog.FileStorageVolumes.EmptyRef)
           |				ELSE TRUE
           |			END)
           |			AND (DATEADD(Files.CreationDate, DAY, &DaysCount) <= &DateOfProcessing)
           |			AND (Files.BeingEditedBy IN (&EmptyUsers))
           |		INNER JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON Files.Ref = FilesInfo.File
           |			AND (FilesInfo.ArchivingDate = DATETIME(1,1,1))
           |		LEFT JOIN InformationRegister.FileRepository AS FileRepository
           |		ON Files.Ref = FileRepository.File";

		QueryText = StrReplace(QueryText, "#FileOwnerType", "Catalog." + FilesCatalogAttributes.Name);
		QueryText = StrReplace(QueryText, "#CatalogFileOwner", FilesOwnerFullName);		   

		BatchQueryText.Add(QueryText);

	EndIf;

	QueryText = 
           "SELECT DISTINCT
           |	TT_DataPreparationForTransfer.BinaryDataStorage AS BinaryDataStorage
           |INTO TT_DataForDeduplicationCheck
           |FROM
           |	TT_DataPreparationForTransfer AS TT_DataPreparationForTransfer
           |WHERE
           |	NOT TT_DataPreparationForTransfer.IsStoringOnDisk
           |
           |INDEX BY
           |	TT_DataPreparationForTransfer.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	FileRepository.BinaryDataStorage AS BinaryDataStorage,
           |	COUNT(*) AS DeduplicatedFilesCount,
           |	COUNT(*) - SUM(CASE
           |			WHEN ISNULL(FilesInfo.MarkedAsArchived, ISNULL(FilesVersions.MarkedAsArchived, FALSE))
           |				THEN CAST(1 AS NUMBER(17, 0))
           |			ELSE 0
           |		END) AS ConditionalTransferCriterion,
           |	MAX(CASE
           |			WHEN NOT FilesVersions.Ref IS NULL
           |				THEN FilesVersions.Owner.CurrentVersion = FilesVersions.Ref
           |						AND NOT FilesVersions.Owner.BeingEditedBy IN (&EmptyUsers)
           |			ELSE NOT FilesInfo.BeingEditedBy IN (&EmptyUsers)
           |		END) AS FileBeingEdited
           |INTO TT_DeduplicatedFiles
           |FROM
           |	TT_DataForDeduplicationCheck AS TT_DataForDeduplicationCheck
           |		INNER JOIN InformationRegister.FileRepository AS FileRepository
           |		ON TT_DataForDeduplicationCheck.BinaryDataStorage = FileRepository.BinaryDataStorage
           |		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
           |		ON (FileRepository.File = FilesInfo.File)
           |		LEFT JOIN Catalog.FilesVersions AS FilesVersions
           |		ON (FileRepository.File = FilesVersions.Ref)
           |			AND (NOT FilesVersions.Owner.DeletionMark)
           |WHERE
           |	NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
           |
           |GROUP BY
           |	FileRepository.BinaryDataStorage
           |
           |HAVING
           |	COUNT(*) > 1
           |
           |INDEX BY
           |	FileRepository.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |SELECT
           |	TT_DataPreparationForTransfer.AttachedFile AS AttachedFile,
           |	TT_DataPreparationForTransfer.FileStorageType AS FileStorageType,
           |	TT_DataPreparationForTransfer.Volume AS Volume,
           |	TT_DataPreparationForTransfer.PathToFile AS PathToFile,
           |	TT_DataPreparationForTransfer.BinaryDataStorage AS BinaryDataStorage,
           |	TT_DataPreparationForTransfer.Description AS Description,
           |	TT_DataPreparationForTransfer.Extension AS Extension,
           |	TT_DataPreparationForTransfer.FileToWriteInformationRecords AS FileToWriteInformationRecords,
           |	TT_DataPreparationForTransfer.VersionNumber AS VersionNumber,
           |	TT_DataPreparationForTransfer.FileOwner AS FileOwner,
           |	CASE
           |		WHEN ISNULL(TT_DeduplicatedFiles.ConditionalTransferCriterion, 0) = 1
           |			THEN TT_DataPreparationForTransfer.MarkedAsArchived
           |		WHEN ISNULL(TT_DeduplicatedFiles.ConditionalTransferCriterion, 0) > 1
           |			THEN TRUE
           |		ELSE FALSE
           |	END AS SubjectToConditionalTransfer,
           |	NOT TT_DataPreparationForTransfer.IsStoringOnDisk
           |		AND NOT CASE
           |				WHEN ISNULL(TT_DeduplicatedFiles.ConditionalTransferCriterion, 0) = 1
           |					THEN TT_DataPreparationForTransfer.MarkedAsArchived
           |				WHEN ISNULL(TT_DeduplicatedFiles.ConditionalTransferCriterion, 0) > 1
           |					THEN TRUE
           |				ELSE FALSE
           |			END AS ReceiveBinaryData,
           |	ISNULL(TT_DeduplicatedFiles.DeduplicatedFilesCount, 0) AS DeduplicatedFilesCount,
           |	TT_DataPreparationForTransfer.MarkedAsArchived AS MarkedAsArchived,
           |	ISNULL(TT_DeduplicatedFiles.FileBeingEdited, FALSE) AS FileBeingEdited,
           |	TT_DataPreparationForTransfer.FilePresentation AS FilePresentation
           |INTO TT_DataForTransfer
           |FROM
           |	TT_DataPreparationForTransfer AS TT_DataPreparationForTransfer
           |		LEFT JOIN TT_DeduplicatedFiles AS TT_DeduplicatedFiles
           |		ON TT_DataPreparationForTransfer.BinaryDataStorage = TT_DeduplicatedFiles.BinaryDataStorage
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DataForDeduplicationCheck
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DeduplicatedFiles
           |;
           |
           |////////////////////////////////////////////////////////////////////////////////
           |DROP TT_DataPreparationForTransfer";

	BatchQueryText.Add(QueryText);

	Separator = 
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";

	QueryText = StrConcat(BatchQueryText, Separator);

	If ExceptionsArray.Count() > 0 Then
		QueryText = StrReplace(QueryText, "&IsFilterByExceptions", "NOT Files.FileOwner IN HIERARCHY (&ExceptionsArray)");
	Else 
		QueryText = StrReplace(QueryText, "&IsFilterByExceptions", "TRUE");
	EndIf;

	If ExceptionItem <> Undefined Then
		QueryText = StrReplace(QueryText, "&FilterByDetalizedSetting", "Files.FileOwner IN HIERARCHY (&FilterByDetalizedSetting)");
	Else
		QueryText = StrReplace(QueryText, "&FilterByDetalizedSetting", "TRUE");
	EndIf;

	If FilesObjectMetadata.Hierarchical Then
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "NOT Files.IsFolder");
	Else
		QueryText = StrReplace(QueryText, "&ThisIsNotGroup", "TRUE");
	EndIf;

	Return QueryText;

EndFunction

Function NumberOfDaysOfStorageBeforeTransferToFileArchive(FilesTransferSetting, DefaultValue)

	If FilesTransferSetting.ArchiveAfterDays = 0 Then
		Result = DefaultValue;
	Else
		Result = FilesTransferSetting.ArchiveAfterDays;
	EndIf;	

	Return Result;

EndFunction

Procedure DeleteTemporaryDirectory(FullFileName, Val ErrorDescriptionTitle = Undefined, Val RaiseException1 = False)

	If IsBlankString(FullFileName) Then
		Return;
	EndIf;

	Try
		DeleteFiles(FullFileName);
	Except
		
		If ErrorDescriptionTitle = Undefined Then
			ErrorDescriptionTitle = NStr("ru = 'Ошибка переноса файлов';
										|vi = 'File transfer error';
										|en = 'File transfer error'; fa = 'File transfer error';
										|it = 'File transfer error';
										|pl = 'File transfer error';
										|tr = 'Dosya taşıma hatası'");
		EndIf;

		ErrorDescriptionTemplate = NStr("ru = '%1 
			|Не удален временный каталог
			|""%2"".';
			|vi = '%1 
			|Temporary directory not deleted:
			|%2.';
			|en = '%1 
			|Temporary directory not deleted:
			|%2.'; fa = '%1 
			|Temporary directory not deleted:
			|%2.';
			|it = '%1 
			|Temporary directory not deleted:
			|%2.';
			|pl = '%1 
			|Temporary directory not deleted:
			|%2.';
			|tr = '%1 
			|Geçici dizin silinmedi
			|""%2"".'");

		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorDescriptionTemplate,
			ErrorDescriptionTitle,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		WriteFilesTransferEventToEventLog(ExceptionString, EventLogLevel.Error);			

		If RaiseException1 Then;
			Raise ExceptionString;
		EndIf;

	EndTry;

EndProcedure

Function ErrorDescriptionStringOnOperationsWithTempDirectory(IsTransferToFileArchive)

	If IsTransferToFileArchive Then
		Result = NStr("ru = 'Ошибка при переносе в файловый архив';
						|vi = 'Error transferring files to archive';
						|en = 'Error transferring files to archive'; fa = 'Error transferring files to archive';
						|it = 'Error transferring files to archive';
						|pl = 'Error transferring files to archive';
						|tr = 'Dosya arşivine taşıma sırasında hata oluştu'");
	Else
		Result = NStr("ru = 'Ошибка при восстановлении из файлового архива';
						|vi = 'Error restoring file from archive';
						|en = 'Error restoring file from archive'; fa = 'Error restoring file from archive';
						|it = 'Error restoring file from archive';
						|pl = 'Error restoring file from archive';
						|tr = 'Dosya arşivinden geri yükleme sırasında hata oluştu'");
	EndIf;

	Return Result;

EndFunction

Procedure WriteFilesTransferEventToEventLog(Val MessageText, Val Level = Undefined)

	If Level = Undefined Then
		Level = EventLogLevel.Information;
	EndIf;

	WriteLogEvent(FilesTransferEventLogEvent(), Level,,, MessageText);

EndProcedure

Function FilesTransferEventLogEvent()

	Return NStr("ru = 'Выполнение операций с файловым архивом';
				|vi = 'File archive operations';
				|en = 'File archive operations'; fa = 'File archive operations';
				|it = 'File archive operations';
				|pl = 'File archive operations';
				|tr = 'Dosya arşivi işlemlerinin yürütülmesi'", Common.DefaultLanguageCode());

EndFunction

Function DeduplicatedFilesByBinaryDataStorage(Var_BinaryDataStorage, OnlyFilesInArchive = False)

	Query = New Query;	
	Query.Text = 
		"SELECT
		|	FileRepository.File AS AttachedFile,
		|	ISNULL(FilesVersions.Description, ISNULL(FilesInfo.Description, """")) AS Description,
		|	ISNULL(FilesVersions.Extension, ISNULL(FilesInfo.Extension, """")) AS Extension,
		|	ISNULL(FilesVersions.Owner, FileRepository.File) AS FileToWriteInformationRecords,
		|	ISNULL(FilesVersions.VersionNumber, 0) AS VersionNumber,
		|	ISNULL(FilesVersions.Owner.FileOwner, ISNULL(FilesInfo.FileOwner, UNDEFINED)) AS FileOwner
		|FROM
		|	InformationRegister.FileRepository AS FileRepository
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON FileRepository.File = FilesInfo.File
		|			AND (NOT FilesInfo.DeletionMark)
		|		LEFT JOIN Catalog.FilesVersions AS FilesVersions
		|		ON FileRepository.File = FilesVersions.Ref
		|			AND (NOT FilesVersions.Owner.DeletionMark)
		|WHERE
		|	FileRepository.BinaryDataStorage = &BinaryDataStorage
		|	AND NOT ISNULL(FilesInfo.DeletionMark, ISNULL(FilesVersions.DeletionMark, FALSE))
		|	AND (&AllFiles
		|			OR ISNULL(FilesInfo.ArchivingDate, ISNULL(FilesVersions.ArchivingDate, DATETIME(1, 1, 1))) <> DATETIME(1, 1, 1))";

	Query.SetParameter("BinaryDataStorage"	, Var_BinaryDataStorage);
	Query.SetParameter("AllFiles"				, Not OnlyFilesInArchive);

	Return Query.Execute().Unload();

EndFunction

Function AdditionalFilesTransferParameters()

	Result = New Structure;
	Result.Insert("QueryTextGettingFilesPortionToTransferToArchive"			, "");
	Result.Insert("QueryTextGettingFilesPortionToRestoreFromArchive"	, "");
	Result.Insert("FilesStorageMethod"										, "");

	Return Result;

EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ConstantsInitialFilling");
	Methods.Insert("InitialFillingFileArchiveOperationsSettings");
	
EndProcedure

#EndRegion