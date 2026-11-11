///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Performs configuration of the composition of stored data for the attributes of the "Binary Data Storages" Catalog and the "Binary Data Storage Information Register" 
//  used to store binary data files.
//
// Parameters:
//  AttributesForDataStorage - Array - the names of the processed Attributes of the "Binary Data Storages" Catalog.
//											See FileArchiveManagementServer.FilesStorageAttributesNamesByStorageMethod.
//
Procedure ConfigureCompositionOfStoredDataFiles(Val AttributesForDataStorage) Export

	If AttributesForDataStorage.Count() = 0 Then
		Return;
	EndIf;

	If Not FileArchiveManagementServer.AreBinaryDataStoragesAvailable() Then
		Return;
	EndIf;

	FilesStorageMethod = FileArchiveManagementServer.FilesStorageMethod();
	If FilesStorageMethod = "InVolumesOnHardDrive" Then
		Return;
	EndIf;	

	ExclusiveModeInitialState = ExclusiveMode();

	SetExclusiveModeToChangeStoredDataComposition(ExclusiveModeInitialState);

	For Each ProcessedAttributes In AttributesForDataStorage Do
		// @skip-check query-in-loop - Small cycle
		ConfigureStoredDataCompositionForAttribute(ProcessedAttributes);
	EndDo;

	If ExclusiveModeInitialState <> ExclusiveMode() Then
		SetExclusiveMode(False);
	EndIf;

EndProcedure

// Verifies that no binary data storages are connected.
//
// Returns:
//  Boolean
//
Function AreBinaryDataStoragesMissing() Export

	Return Not BinaryDataStorage.GetBinaryDataStorageAvailability() And BinaryDataExternalStorages.Count() = 0;

EndFunction

// Checks whether it is necessary to configure the stored data structure for connected binary data storages.
//
// Parameters:
//  AttributeName			- String - Name of the file binary data storage attribute. 
//									   The term "attribute" refers to the following metadata object properties:
//                    * BinaryData - Attribute of the BinaryDataStorage catalog.
//                    * BinaryDataInArchive								- Resource of information register BinaryDataStorageLocations.
//                    * BinaryDataInInternalOperationalStorage	- Resource of information register BinaryDataStorageLocations.
//                    * BinaryDataInExternalOperationalStorage		- Resource of information register BinaryDataStorageLocations.
//  FilesStorageMethod	- String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  Boolean
//
Function IsSettingForStorageDataCompositionForAttributeRequired(AttributeName, FilesStorageMethod = "") Export

	Result = False;

	MetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName);	

	If AttributeName = "BinaryData" Then

		Result = Not IsStorageCompositionConfiguredForAttribute(AttributeName, , MetadataObject);

	ElsIf AttributeName = "BinaryDataInArchive" Then

		If FileArchiveManagementServer.UseFileArchive() Then

			FileArchiveExternalStorageName = FilesStorageVolumeExternalStorageName(Enums.StorageKinds.ArchivalStorage);

			If Not IsBlankString(FileArchiveExternalStorageName) 
				And Not HasErrorInBinaryDataStorageSettings(AttributeName, FileArchiveExternalStorageName) Then

				Result = Not IsStorageCompositionConfiguredForAttribute(AttributeName, FileArchiveExternalStorageName, MetadataObject);
            EndIf;
		EndIf;
	Else

		If Not ValueIsFilled(FilesStorageMethod) Then
			FilesStorageMethod = FileArchiveManagementServer.FilesStorageMethod();
		EndIf;

		If AttributeName = "BinaryDataInInternalOperationalStorage" 
				And (FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Or FilesStorageMethod = "InternalBinaryDataStorage") Then

			OperationalStorageVolume = StorageVolumeAllocatingDataInEmbeddedStorage();
			If OperationalStorageVolume <> Undefined 			
					And Not HasErrorInBinaryDataStorageSettings(AttributeName) Then

				Result = Not IsStorageCompositionConfiguredForAttribute(AttributeName, , MetadataObject);

			EndIf;

		ElsIf AttributeName = "BinaryDataInExternalOperationalStorage"
				And (FilesStorageMethod = "InInfobaseAndVolumesOnHardDrive" Or FilesStorageMethod = "ExternalBinaryDataStorage") Then

			ExternalTemporaryStorageName = FilesStorageVolumeExternalStorageName(Enums.StorageKinds.OperationalStorage);

			If Not IsBlankString(ExternalTemporaryStorageName)
				And Not HasErrorInBinaryDataStorageSettings(AttributeName, ExternalTemporaryStorageName) Then

				Result = Not IsStorageCompositionConfiguredForAttribute(AttributeName, ExternalTemporaryStorageName, MetadataObject);
			EndIf;
		EndIf;
	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region Private

#Region BackingUpInternalBinaryDataStorage

// Method of sheduled job BackupOfBuiltInBinaryDataStorage.
//
Procedure BackingUpInternalBinaryDataStorage() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.BackingUpInternalBinaryDataStorage);

	If Not FileArchiveManagementServer.AreBinaryDataStoragesAvailable() Then
		Return;
	EndIf;

	If IsBDSBackupCreationBackgroundJobRunning() Then
		Return;
	EndIf;
	
	EmbeddedBDSNewBackup();

EndProcedure

Function IsBDSBackupCreationBackgroundJobRunning()

	ScheduledJob = Metadata.ScheduledJobs.BackingUpInternalBinaryDataStorage;

	Filter = New Structure;
	Filter.Insert("MethodName", ScheduledJob.MethodName);
	Filter.Insert("State", BackgroundJobState.Active);
	CurrentBackgroundJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If CurrentBackgroundJobs.Count() = 1 Then
		CurrentSessionBackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
		Result = CurrentSessionBackgroundJob = Undefined;
		If Not Result Then
			Result = CurrentSessionBackgroundJob.UUID <> CurrentBackgroundJobs[0].UUID;
		EndIf;
	Else
		Result = CurrentBackgroundJobs.Count() > 0;
	EndIf;

	Return Result;
	
EndFunction

Procedure EmbeddedBDSNewBackup()

	SetPrivilegedMode(True);

	WriteBDSBackupEventToEventLog(
												NStr("ru = 'Начато регламентное создание резервной копии встроенного хранилища двоичных данных.';
													|vi = 'Scheduled backing up of internal binary data storage started.';
													|en = 'Scheduled backing up of internal binary data storage started.'; fa = 'Scheduled backing up of internal binary data storage started.';
													|it = 'Scheduled backing up of internal binary data storage started.';
													|pl = 'Scheduled backing up of internal binary data storage started.';
													|tr = 'Dahili ikili veri deposunun planlı yedeklemesi başlatıldı.'",
												Common.DefaultLanguageCode()));

	EventLogComment = "";
	BackupStorageDirectory = BackupsFilesStorageVerifiedDirectoryForEmbeddedBDS(EventLogComment);

	If Not ValueIsFilled(BackupStorageDirectory) Then

			WriteBDSBackupEventToEventLog(EventLogComment, EventLogLevel.Error);

		Return;
	EndIf;

	NewBackupFileName = "";
	BackupKind = Enums.InternalBinaryDataStorageBackupTypes.EmptyRef();

	FullBackupFileName = LastFullBackupFileName();
	If ValueIsFilled(FullBackupFileName) Then
		PathToFullBackupFile = BackupStorageDirectory + FullBackupFileName;
		If FileExists(PathToFullBackupFile) Then
			NewBackupFileName = BackupFileNewName();
			PathToNewDifferentialCopyFile = BackupStorageDirectory + NewBackupFileName;

			Try
				BinaryDataStorage.CreateDifferentialBackup(PathToNewDifferentialCopyFile, PathToFullBackupFile);
			Except
				
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				WriteBDSBackupEventToEventLog(ErrorDescription, EventLogLevel.Error);
				Return;
															
			EndTry;
			
			BackupKind = Enums.InternalBinaryDataStorageBackupTypes.Differential;
		EndIf;
	EndIf;

	If NewBackupFileName = "" Then
		NewBackupFileName = BackupFileNewName(True);
		PathToNewFullBackupFile = BackupStorageDirectory + NewBackupFileName;

		Try
			BinaryDataStorage.CreateFullBackup(PathToNewFullBackupFile);
		Except
			
			ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteBDSBackupEventToEventLog(ErrorDescription, EventLogLevel.Error);
			Return;
														
		EndTry;		

		BackupKind = Enums.InternalBinaryDataStorageBackupTypes.Full;
	EndIf;

	InformationRegisters.InternalBinaryDataStorageBackupHistory.AddRecord(BackupKind, CurrentSessionDate(), NewBackupFileName);
	
	WriteBDSBackupEventToEventLog(
												NStr("ru = 'Завершено регламентное создание резервной копии встроенного хранилища двоичных данных.';
													|vi = 'Scheduled backing up of internal binary data storage completed.';
													|en = 'Scheduled backing up of internal binary data storage completed.'; fa = 'Scheduled backing up of internal binary data storage completed.';
													|it = 'Scheduled backing up of internal binary data storage completed.';
													|pl = 'Scheduled backing up of internal binary data storage completed.';
													|tr = 'Dahili ikili veri deposunun planlı yedeklemesi tamamlandı.'",
												Common.DefaultLanguageCode()));

EndProcedure
											
Function BackupsFilesStorageVerifiedDirectoryForEmbeddedBDS(ErrorDescription = "")

	Result = EmbeddedBDSBackupsFilesStorageDirectory();
	
	If Not ValueIsFilled(Result) Then
		ErrorDescription = NStr("ru = 'Не заполнена константа ""Каталог резервных копий встроенного хранилища двоичных данных""';
								|vi = 'Constant is required: Backup directory for the built-in binary data storage';
								|en = 'Constant is required: Backup directory for the built-in binary data storage'; fa = 'Constant is required: Backup directory for the built-in binary data storage';
								|it = 'Constant is required: Backup directory for the built-in binary data storage';
								|pl = 'Constant is required: Backup directory for the built-in binary data storage';
								|tr = '""Dahili ikili veri deposu yedekleme dizini"" sabiti doldurulmadı'");
	Else
		Result = CommonClientServer.AddLastPathSeparator(Result);

		If Not FileExists(Result) Then

			MessageTemplate = NStr("ru = 'Не существует каталог, указанный для хранения резервных копий встроенного хранилища двоичных данных
									|%1';
									|vi = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1';
									|en = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1'; fa = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1';
									|it = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1';
									|pl = 'Directory specified for storing backups of internal binary data storage does not exist
									|%1';
									|tr = 'Dahili ikili veri deposu yedeklerinin saklanması için belirtilen dizin mevcut değil
									|%1'");
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, Result);

			Result = "";
		EndIf;		
	EndIf;

	Return Result;

EndFunction

Function LastFullBackupFileName()

	Query = New Query;
	Query.Text = 
		"SELECT
		|	InternalBinaryDataStorageBackupHistory.BackupFileName AS BackupFileName
		|FROM
		|	(SELECT
		|		InternalBinaryDataStorageBackupHistory.BackupKind AS BackupKind,
		|		MAX(InternalBinaryDataStorageBackupHistory.CreationDate) AS CreationDate
		|	FROM
		|		InformationRegister.InternalBinaryDataStorageBackupHistory AS InternalBinaryDataStorageBackupHistory
		|	WHERE
		|		InternalBinaryDataStorageBackupHistory.BackupKind = &BackupKind
		|		AND InternalBinaryDataStorageBackupHistory.CreationDate <= &CreationDate
		|	
		|	GROUP BY
		|		InternalBinaryDataStorageBackupHistory.BackupKind) AS LastFullBackupDate
		|		INNER JOIN InformationRegister.InternalBinaryDataStorageBackupHistory AS InternalBinaryDataStorageBackupHistory
		|		ON LastFullBackupDate.BackupKind = InternalBinaryDataStorageBackupHistory.BackupKind
		|			AND LastFullBackupDate.CreationDate = InternalBinaryDataStorageBackupHistory.CreationDate";

	Query.SetParameter("BackupKind", Enums.InternalBinaryDataStorageBackupTypes.Full);
	Query.SetParameter("CreationDate", CurrentSessionDate());

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = TrimAll(DataSelection.BackupFileName);
	Else
		Result = "";
	EndIf;

	Return Result;

EndFunction

Function FileExists(PathToFile)

	Result = Not IsBlankString(PathToFile);

	If Result Then
		File = New File(PathToFile);
		Result = File.Exists();
	EndIf;

	Return Result;

EndFunction

Function BackupFileNewName(IsFullCopy = False)

	BackupType = ?(IsFullCopy, "Full", "Differential");
	CopyCreationDate = Format(CurrentSessionDate(), "DF=ddMMyyyy_HHmmss");

	Return StringFunctionsClientServer.SubstituteParametersToString("%1_%2.sbd", BackupType, CopyCreationDate);

EndFunction

Procedure WriteBDSBackupEventToEventLog(Val MessageText, Val Level = Undefined)

	If Level = Undefined Then
		Level = EventLogLevel.Information;
	EndIf;

	WriteLogEvent(EmbeddedBDSBackupEventLogEvent(), Level,,, MessageText);

EndProcedure

Function EmbeddedBDSBackupEventLogEvent()
	
	Return NStr("ru = 'Резервное копирование встроенного хранилища двоичных данных';
				|vi = 'Backing up internal binary data storage';
				|en = 'Backing up internal binary data storage'; fa = 'پشتیبان‌گیری از ذخیره‌سازی داخلی داده‌های دودویی';
				|it = 'Backing up internal binary data storage';
				|pl = 'Backing up internal binary data storage';
				|tr = 'Dahili ikili veri deposu yedekleme'", Common.DefaultLanguageCode());
	
EndFunction

Function EmbeddedBDSBackupsFilesStorageDirectory()

	SetPrivilegedMode(True);

	If Common.IsWindowsServer() Then

		Result = Constants.BackupDirectoryForTheBuiltInBinaryDataStorageWindows.Get();

	Else

		Result = Constants.BackupDirectoryForTheBuiltInBinaryDataStorageLinux.Get();

	EndIf;

	Return Result;

EndFunction

#EndRegion

#Region StoredDataCompositionSetting

// Updates the stored data structure for the binary data storage assigned to the file storage volume.
//
// Parameters:
//  StorageVolumeType		- EnumRef.StorageKinds
//  FilesStorageMethod		- EnumRef.FileStorageOption
//  BinaryDataStorageName	- String - Used only for file storage option InExternalStorageUsingS3Protocol
//
Procedure ChangeStoredDataComposition(StorageVolumeType, FilesStorageMethod, BinaryDataStorageName) Export

	If Not ValueIsFilled(FilesStorageMethod) Or FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories Then
		Return;		
	EndIf;

	SetPrivilegedMode(True);

	TextDescriptionError = "";
	
	If StorageVolumeType = Enums.StorageKinds.ArchivalStorage Then
		StorageAttributeName = "BinaryDataInArchive";
	Else
		StorageAttributeName = FileArchiveManagementServer.BinaryDataStorageAttributeNameByVolumeStorageMethod(FilesStorageMethod);
	EndIf;

	If HasErrorInBinaryDataStorageSettings(StorageAttributeName, BinaryDataStorageName, TextDescriptionError) Then
		Raise TextDescriptionError;
	EndIf;

	StorageAttributeMetadataObject = Undefined;

	If Not IsStorageCompositionConfiguredForAttribute(StorageAttributeName, BinaryDataStorageName, StorageAttributeMetadataObject) Then

		ExclusiveModeInitialState = ExclusiveMode();

		SetExclusiveModeToChangeStoredDataComposition(ExclusiveModeInitialState);

		ConfigureStoredDataCompositionForAttribute(StorageAttributeName, StorageAttributeMetadataObject, BinaryDataStorageName);

		If ExclusiveModeInitialState <> ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
	EndIf;

EndProcedure

Function FilesStorageKindByAttributeName(AttributeName)

	If AttributeName = "BinaryDataInArchive" Then
		Result = Enums.StorageKinds.ArchivalStorage;
	Else
		Result = Enums.StorageKinds.OperationalStorage;
	EndIf;

	Return Result;
	
EndFunction

Function IsStorageCompositionConfiguredForAttribute(AttributeName, BinaryDataExternalStorageName = "", MetadataObject = Undefined)

	Result = False;

	MetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);

	If AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInExternalOperationalStorage" Then
		
		If Not ValueIsFilled(BinaryDataExternalStorageName) Then
			BinaryDataExternalStorageName = FilesStorageVolumeExternalStorageName(FilesStorageKindByAttributeName(AttributeName));
		EndIf;

		If ValueIsFilled(BinaryDataExternalStorageName) Then
			ExternalBinaryDataStorage = BinaryDataExternalStorages.Find(BinaryDataExternalStorageName);

			If ExternalBinaryDataStorage <> Undefined Then
				StorageStoredDataComposition = ExternalBinaryDataStorage.StoredDataContent;
				StoredDataCompositionItem = StorageStoredDataComposition.Find(MetadataObject);

				If StoredDataCompositionItem <> Undefined 
						And StoredDataCompositionItem.Location = UsingSafeModeStorage("Use") Then

					Result = True;
				EndIf;
			EndIf;
		EndIf

	ElsIf AttributeName = "BinaryDataInInternalOperationalStorage" Then

		Result = IsAttributeUsedAsPartOfEmbeddedStorageStoredData(AttributeName, MetadataObject);

	ElsIf AttributeName = "BinaryData" Then

		Result = IsAttributeUsageExplicitlyDisabledInAllBinaryDataStorages(AttributeName, MetadataObject);

	EndIf;

	Return Result;

EndFunction

Procedure SetExclusiveModeToChangeStoredDataComposition(ExclusiveModeCurrentState)

	If Not ExclusiveModeCurrentState Then

		Try
			SetExclusiveMode(True);
		Except

			ErrorTemplate = NStr("ru = 'Не удалось установить монопольный режим для настройки состава реквизитов,
										|используемых в хранилищах двоичных данных:
										|%1';
										|vi = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1';
										|en = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1'; fa = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1';
										|it = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1';
										|pl = 'Failed to set exclusive mode for configuring
										|attributes used in binary data storages:
										|%1';
										|tr = 'İkili veri depolarında kullanılan özniteliklerin yapısını ayarlamak için 
										| özel kullanım modu ayarlanamadı:
										|%1'");

			ErrorInfo	= ErrorInfo();
			ErrorDescriptionText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));			

			Raise ErrorDescriptionText;

		EndTry;
	EndIf;	
	
EndProcedure

Procedure ConfigureStoredDataCompositionForAttribute(AttributeName, MetadataObject = Undefined, ExternalStorageName = "")

	AttributeMetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);

	If AttributeName = "BinaryData" Then

		Location = UsingSafeModeStorage("DontUse");

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on

		If SetStoredDataCompositionItemForAttribute(StoredDataContent, AttributeMetadataObject, Location) Then

			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on			
		EndIf;

		For Each ExternalStorage In BinaryDataExternalStorages Do
			If SetStoredDataCompositionItemForAttribute(ExternalStorage.StoredDataContent, AttributeMetadataObject, Location) Then
				ExternalStorage.Write();
			EndIf;
		EndDo;
	ElsIf AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInExternalOperationalStorage" Then

		ExternalStorageName = FilesStorageVolumeExternalStorageName(FilesStorageKindByAttributeName(AttributeName), ExternalStorageName);

		NamesOfStoragesToExclude = NamesOfStoragesToExclude(ExternalStorageName);

		DeleteAttributeFromStoredDataCompositionOfAllStorages(AttributeName, NamesOfStoragesToExclude, AttributeMetadataObject);

		If Not IsBlankString(ExternalStorageName) Then

			ExternalStorage = BinaryDataExternalStorages.Find(ExternalStorageName);
			If ExternalStorage <> Undefined Then
			
				Location = UsingSafeModeStorage("Use");

				If SetStoredDataCompositionItemForAttribute(ExternalStorage.StoredDataContent, AttributeMetadataObject, Location) Then
					ExternalStorage.Write();
				EndIf;
			EndIf;
		EndIf;
		
	ElsIf AttributeName = "BinaryDataInInternalOperationalStorage" Then

		NamesOfStoragesToExclude = NamesOfStoragesToExclude("InternalStorage");

		DeleteAttributeFromStoredDataCompositionOfAllStorages(AttributeName, NamesOfStoragesToExclude);

		Location = UsingSafeModeStorage("Use");

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on		
		If SetStoredDataCompositionItemForAttribute(StoredDataContent, AttributeMetadataObject, Location) Then
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on
		EndIf;
	EndIf;

EndProcedure

Procedure DeleteAttributeFromStoredDataCompositionOfAllStorages(AttributeName, NamesOfStoragesToExclude = Undefined, MetadataObject = Undefined)

	AttributeMetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);

	If Not(NamesOfStoragesToExclude <> Undefined And NamesOfStoragesToExclude.Find("InternalStorage") <> Undefined) Then

		StoredDataContent = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StoredDataContent = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on		
		If DeleteAttributeFromStoredDataComposition(StoredDataContent, AttributeMetadataObject) Then
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("BinaryDataStorage.SetStoredDataContent(StoredDataContent)");
			// ACC:487-on			
		EndIf;
	EndIf;

	For Each ExternalStorage In BinaryDataExternalStorages Do

		If NamesOfStoragesToExclude <> Undefined And NamesOfStoragesToExclude.Find(ExternalStorage.Name) <> Undefined Then
			Continue;
		EndIf;

		If DeleteAttributeFromStoredDataComposition(ExternalStorage.StoredDataContent, AttributeMetadataObject) Then
			ExternalStorage.Write();
		EndIf;
	EndDo

EndProcedure

Function DeleteAttributeFromStoredDataComposition(StoredDataContent, MetadataObject)

	Result = False;

	StoredDataCompositionItem = StoredDataContent.Find(MetadataObject);
	If StoredDataCompositionItem <> Undefined Then
		StoredDataContent.Delete(StoredDataCompositionItem);
		Result = True;
	EndIf;

	Return Result;

EndFunction

Function IsAttributeUsageExplicitlyDisabledInAllBinaryDataStorages(AttributeName, MetadataObject = Undefined)

	Result = AreBinaryDataStoragesMissing();

	If Not Result Then

		IsDisabledInEmbeddedStorage = Not BinaryDataStorage.GetBinaryDataStorageAvailability();

		If Not IsDisabledInEmbeddedStorage Then

			StorageStoredDataComposition = Undefined;
			// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
			Execute("StorageStoredDataComposition = BinaryDataStorage.GetStoredDataContent()");
			// ACC:487-on

			ValueOfMetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);
			StoredDataCompositionItem = StorageStoredDataComposition.Find(ValueOfMetadataObject);

			If StoredDataCompositionItem <> Undefined Then
				IsDisabledInEmbeddedStorage = StoredDataCompositionItem.Location = UsingSafeModeStorage("DontUse");
			EndIf;
		EndIf;

		IsDisabledInExternalStorages = BinaryDataExternalStorages.Count() = 0;

		If Not IsDisabledInExternalStorages Then

			IsDisabledInExternalStorages = True;

	        ValueOfMetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);

			For Each ExternalStorage In BinaryDataExternalStorages Do
				StorageStoredDataComposition = ExternalStorage.StoredDataContent;
				StoredDataCompositionItem = StorageStoredDataComposition.Find(ValueOfMetadataObject);

				If StoredDataCompositionItem = Undefined 
						Or StoredDataCompositionItem.Location = UsingSafeModeStorage("Use") Then

					IsDisabledInExternalStorages = False;
					Break
				EndIf;
			EndDo;
		EndIf;
		
		Result = IsDisabledInEmbeddedStorage And IsDisabledInExternalStorages;
	EndIf;

	Return Result;

EndFunction

Function IsAttributeUsedAsPartOfEmbeddedStorageStoredData(AttributeName, MetadataObject = Undefined)

	Result = False;	

	If BinaryDataStorage.GetBinaryDataStorageAvailability() Then

		StorageStoredDataComposition = Undefined;
		// ACC:487-off - Support of new 1C:Enterprise methods (the executable code is safe)
		Execute("StorageStoredDataComposition = BinaryDataStorage.GetStoredDataContent()");
		// ACC:487-on

		ValueOfMetadataObject = MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject);
		StoredDataCompositionItem = StorageStoredDataComposition.Find(ValueOfMetadataObject);

		If StoredDataCompositionItem <> Undefined Then
			Result = StoredDataCompositionItem.Location = UsingSafeModeStorage("Use");
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function FilesStorageVolumeExternalStorageName(StorageVolumeType, ExternalStorageName = "")

	If ValueIsFilled(ExternalStorageName) Then

		Result = ExternalStorageName;

	Else

		Result = "";

		Query = New Query;
		Query.Text = 
		"SELECT
		|	FileStorageVolumes.BinaryDataStorageName AS BinaryDataStorageName
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	NOT FileStorageVolumes.DeletionMark
		|	AND FileStorageVolumes.StorageVolumeType = &StorageVolumeType
		|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.S3ExternalStorage)";

		Query.SetParameter("StorageVolumeType", StorageVolumeType);

		DataSelection = Query.Execute().Select();
		If DataSelection.Next() Then
			Result = DataSelection.BinaryDataStorageName;
		EndIf;		
	EndIf;

	Return Result;

EndFunction

Function HasErrorInBinaryDataStorageSettings(AttributeName, Val ExternalStorageName = "", ErrorDescription = "")

	Result = False;

	If AttributeName = "BinaryDataInArchive" Or AttributeName = "BinaryDataInExternalOperationalStorage" Then

		Result = BinaryDataExternalStorages.Count() = 0;

		If Result Then
			ErrorDescription = NStr("ru = 'Отсутствуют подключенные внешние хранилища двоичных данных';
									|vi = 'No external binary data storages are connected';
									|en = 'No external binary data storages are connected'; fa = 'No external binary data storages are connected';
									|it = 'No external binary data storages are connected';
									|pl = 'No external binary data storages are connected';
									|tr = 'Bağlı harici ikili veri deposu bulunmuyor'");
		EndIf;

		If Not Result Then

			StorageVolumeKind = FilesStorageKindByAttributeName(AttributeName);

			ExternalStorageName = FilesStorageVolumeExternalStorageName(StorageVolumeKind, ExternalStorageName);

			Result = IsBlankString(ExternalStorageName);

			If Result Then
				ErrorDescription = NStr("ru = 'Не удалось определить имя внешнего хранилища двоичных данных';
										|vi = 'Couldn''t  determine name of external binary data storage';
										|en = 'Couldn''t  determine name of external binary data storage'; fa = 'Couldn''t  determine name of external binary data storage';
										|it = 'Couldn''t  determine name of external binary data storage';
										|pl = 'Couldn''t  determine name of external binary data storage';
										|tr = 'Harici ikili veri deposunun adı belirlenemedi'");
			EndIf;

			If Not Result Then
				ExternalBinaryDataStorage = BinaryDataExternalStorages.Find(ExternalStorageName);

				Result = ExternalBinaryDataStorage = Undefined;

				If Result Then
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("ru = 'Отсутствует внешнее хранилище двоичных данных с именем %1';
													|vi = 'External binary data storage not found: %1';
													|en = 'External binary data storage not found: %1'; fa = 'External binary data storage not found: %1';
													|it = 'External binary data storage not found: %1';
													|pl = 'External binary data storage not found: %1';
													|tr = '%1 adlı harici ikili veri deposu mevcut değil'"),
												ExternalStorageName);
				EndIf;

				If Not Result Then
					Result = ExternalBinaryDataStorage.ReadWriteMode = BinaryDataStorageReadWriteMode.ReadOnly;

					If Result Then
						ErrorDescription = RecordUnavailabilityInBinaryDataStorageErrorText();
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	ElsIf AttributeName = "BinaryDataInInternalOperationalStorage" Then

		Result = BinaryDataStorageUseMode.Enable <> BinaryDataStorage.GetBinaryDataStorageUseMode();

		If Result Then
			ErrorDescription = NStr("ru = 'Встроенное хранилище двоичных данных недоступно';
									|vi = 'Internal binary data storage unavailable';
									|en = 'Internal binary data storage unavailable'; fa = 'Internal binary data storage unavailable';
									|it = 'Internal binary data storage unavailable';
									|pl = 'Internal binary data storage unavailable';
									|tr = 'Dahili ikili veri deposuna erişilemiyor'");
		EndIf;

		If Not Result Then
			Result = BinaryDataStorage.GetBinaryDataStorageReadWriteMode() = BinaryDataStorageReadWriteMode.ReadOnly;
			If Result Then
				ErrorDescription = RecordUnavailabilityInBinaryDataStorageErrorText(False);
			EndIf;
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function RecordUnavailabilityInBinaryDataStorageErrorText(ExternalStorage = True)
	
	If ExternalStorage Then
		Result = NStr("ru = 'Внешнее хранилище двоичных данных доступно только для чтения
							|В настройках хранилища отключено разрешение на запись';
							|vi = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|en = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.'; fa = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|it = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|pl = 'External data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|tr = 'Harici ikili veri deposu sadece okunabilir modda 
							| Depo ayarlarında yazma izni kapalı'");

	Else
		Result = NStr("ru = 'Встроенное хранилище двоичных данных доступно только для чтения
							|В настройках хранилища отключено разрешение на запись';
							|vi = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|en = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.'; fa = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|it = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|pl = 'Internal data storage is read-only.
							|Write permission is disabled in the storage settings.';
							|tr = 'Dahili ikili veri deposu sadece okunabilir modda
							|Depo ayarlarında yazma izni kapalı'");		
	EndIf;
	
	Return Result;
	
EndFunction

Function SetStoredDataCompositionItemForAttribute(StoredDataContent, MetadataObject, Location)

	StoredDataCompositionItem = StoredDataContent.Find(MetadataObject);

	If StoredDataCompositionItem <> Undefined Then
		If StoredDataCompositionItem.Location = Location Then
			Return False;
		Else
			StoredDataContent.Delete(StoredDataCompositionItem);
		EndIf;
	EndIf;

	StoredDataContent.Add(MetadataObject, Location);

	Return True;

EndFunction

Function NamesOfStoragesToExclude(StoragesNames = "")

	Result = Undefined;

	If Not IsBlankString(StoragesNames) Then
		Result = StrSplit(StoragesNames, ",", False);
	EndIf;

	Return Result;

EndFunction

Function StorageVolumeAllocatingDataInEmbeddedStorage()

	Result = Undefined;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	FileStorageVolumes.Ref AS OperationalStorageVolume
	|FROM
	|	Catalog.FileStorageVolumes AS FileStorageVolumes
	|WHERE
	|	NOT FileStorageVolumes.DeletionMark
	|	AND FileStorageVolumes.StorageVolumeType = VALUE(Enum.StorageKinds.OperationalStorage)
	|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.InInternalStorage)";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then
		Result = DataSelection.OperationalStorageVolume;
	EndIf;

	Return Result;

EndFunction

Function MetadataObjectForFilesStorageAttribute(AttributeName, MetadataObject = Undefined)

	Result = MetadataObject;
	If MetadataObject = Undefined Then
		If AttributeName = "BinaryData" Then
			Result = Metadata.Catalogs.BinaryDataStorage.Attributes[AttributeName];
		Else
			Result = Metadata.InformationRegisters.BinaryDataStorages.Resources[AttributeName];
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function UsingSafeModeStorage(Location)

	BRParameters = New Structure;
	BRParameters.Insert("Location", Undefined);
	
	If FileArchiveManagementServer.AreChangesInFilesStorageMethodsAvailable() Then

		If Location = "Use" Then
			Algorithm = "Parameters.Location = BinaryDataStorageLocationUse.Use";
		ElsIf Location = "DontUse" Then
			Algorithm = "Parameters.Location = BinaryDataStorageLocationUse.DontUse";
		EndIf;

		Try
			Common.ExecuteInSafeMode(Algorithm, BRParameters);	
		Except
			ErrorInfo = ErrorInfo();
		EndTry;

	EndIf;

	Return BRParameters.Location;

EndFunction

#EndRegion

#EndRegion