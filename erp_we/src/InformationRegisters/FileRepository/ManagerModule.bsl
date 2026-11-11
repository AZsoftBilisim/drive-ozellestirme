///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure WriteBinaryData(Val File, Val BinaryData, Val RecordingParametersVIB = Undefined) Export
	
	If RecordingParametersVIB = Undefined Then
		RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(File);
	EndIf;

	HashingResults = FileArchiveManagementServer.BinaryDataHashingResult(BinaryData);
	IsEmptyBinaryData = HashingResults.IsEmptyBinaryData;
	Size					= HashingResults.Size;
	Hash						= HashingResults.Hash;

	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.BinaryDataStorage");
		LockItem.SetValue("Hash", Hash);
		Block.Lock();

		DeleteBinaryData(File);

		AreBinaryDataStoragesAvailable = FileArchiveManagementServer.AreBinaryDataStoragesAvailable();

		BinaryStorageInfo = FileArchiveManagementServer.BinaryDataStorageItemInfoByHashAndSize(Hash, Size);
		BinaryDataStorageRef = BinaryStorageInfo.BinaryDataStorageRef;

		If ValueIsFilled(BinaryDataStorageRef) Then

			If BinaryStorageInfo.StoredDataSize = 0 Then
				BinaryDataStorageObject = BinaryDataStorageRef.GetObject();
				BinaryDataStorageObject.BinaryData = ?(IsEmptyBinaryData,
					Undefined, New ValueStorage(BinaryData, New Deflation(9)));
				BinaryDataStorageObject.Write();
			EndIf;			

			If Not RecordingParametersVIB.IsWriteToFileArchive
				And Not RecordingParametersVIB.DoNotChangeBinaryData
				And AreBinaryDataStoragesAvailable
				And FileArchiveManagementServer.IsBinaryDataStorageAvailableInFileArchive(BinaryDataStorageRef) Then

				AttributeNameToWriteBinaryData = FileManagementInBinaryDataStorageInternal.DefineBinaryDataStorageAttributeByFileStorageType(RecordingParametersVIB.FileStorageType);

				BinaryDataToWrite = ?(IsEmptyBinaryData, Undefined, New ValueStorage(BinaryData, New Deflation(9)));				

				If AttributeNameToWriteBinaryData = "BinaryData" Then
					BinaryDataStorageObject = BinaryDataStorageRef.GetObject();
					BinaryDataStorageObject.BinaryData = BinaryDataToWrite;
					BinaryDataStorageObject.Write();
				Else
					BinaryDataValue = New Structure(AttributeNameToWriteBinaryData, BinaryDataToWrite);
					InformationRegisters.BinaryDataStorages.AddChangeRecord(BinaryDataStorageRef, BinaryDataValue);
				EndIf;

				InformationRegisters.DeduplicatedFileStorageInformation.AddRecord(BinaryDataStorageRef, RecordingParametersVIB);

			EndIf;				

		Else
			BinaryDataStorageObject = Catalogs.BinaryDataStorage.CreateItem();
			BinaryDataStorageObject.Size = Size;
			BinaryDataStorageObject.Hash = Hash;

			If AreBinaryDataStoragesAvailable And RecordingParametersVIB.IsWriteToFileArchive Then
				BinaryDataToWrite = ?(ValueIsFilled(RecordingParametersVIB.BinaryDataOfArchive), 
												New ValueStorage(RecordingParametersVIB.BinaryDataOfArchive, New Deflation(9)),
												Undefined);
			Else
				BinaryDataToWrite = ?(IsEmptyBinaryData, Undefined, New ValueStorage(BinaryData, New Deflation(9)));
			EndIf;

			If AreBinaryDataStoragesAvailable Then
				AttributeNameToWriteBinaryData = FileManagementInBinaryDataStorageInternal.DefineBinaryDataStorageAttributeByFileStorageType(RecordingParametersVIB.FileStorageType, RecordingParametersVIB.IsWriteToFileArchive);
			Else
				AttributeNameToWriteBinaryData = "BinaryData";
			EndIf;
			
			If AttributeNameToWriteBinaryData = "BinaryData" Then
				BinaryDataStorageObject[AttributeNameToWriteBinaryData] = BinaryDataToWrite;			
			EndIf;

			BinaryDataStorageObject.Write();
			BinaryDataStorageRef = BinaryDataStorageObject.Ref;

			If AttributeNameToWriteBinaryData <> "BinaryData" Then

				BinaryDataValue = New Structure(AttributeNameToWriteBinaryData, BinaryDataToWrite);
				InformationRegisters.BinaryDataStorages.AddChangeRecord(BinaryDataStorageRef, BinaryDataValue);

			EndIf;

			InformationRegisters.DeduplicatedFileStorageInformation.AddRecord(BinaryDataStorageRef, RecordingParametersVIB);
		EndIf;

		AddRecord(File, BinaryDataStorageRef, False);

		CommitTransaction();	
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure DeleteBinaryData(File) Export
	
	Query = New Query;
	Query.SetParameter("File", File);
	Query.Text =
	"SELECT TOP 1
	|	FileRepository.BinaryDataStorage AS BinaryDataStorage,
	|	FileRepository.BinaryDataStorage.Hash AS Hash
	|FROM
	|	InformationRegister.FileRepository AS FileRepository
	|WHERE
	|	FileRepository.File = &File";

	BeginTransaction();
	Try
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Block = New DataLock;
			LockItem = Block.Add("Catalog.BinaryDataStorage");
			LockItem.SetValue("Hash", Selection.Hash);
			Block.Lock();
			
			FileStorage1 = CreateRecordManager();
			FileStorage1.File = File;
			FileStorage1.Delete();
			
			Query = New Query;
			Query.SetParameter("BinaryDataStorage", Selection.BinaryDataStorage);
			Query.Text = 
			"SELECT TOP 1
			|	TRUE AS Validation
			|FROM
			|	InformationRegister.FileRepository AS FileRepository
			|WHERE
			|	FileRepository.BinaryDataStorage = &BinaryDataStorage";
			If Query.Execute().IsEmpty() Then

                InformationRegisters.BinaryDataStorages.DeleteRecord(Selection.BinaryDataStorage);

				InformationRegisters.DeduplicatedFileStorageInformation.DeleteRecord(Selection.BinaryDataStorage);

				DataStorage = Selection.BinaryDataStorage.GetObject();
				DataStorage.DataExchange.Load = True;
				DataStorage.Delete();
			EndIf;
		EndIf;
		
		If Not FilesOperationsInternalCached.IsDeduplicationCompleted() Then
			FileStorage1 = InformationRegisters.DeleteFilesBinaryData.CreateRecordManager();
			FileStorage1.File = File;
			FileStorage1.Delete();
		EndIf;
		
		CommitTransaction();	
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function FileURL1(File) Export

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("File", File);
	Query.Text =
	"SELECT TOP 1
	|	FileRepository.BinaryDataStorage AS BinaryDataStorage
	|FROM
	|	InformationRegister.FileRepository AS FileRepository
	|WHERE
	|	FileRepository.File = &File";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return GetURL(Selection.BinaryDataStorage, "BinaryData");
	EndIf;
	
	RecordKey = InformationRegisters.DeleteFilesBinaryData.CreateRecordKey(New Structure("File", File));
	
	Return GetURL(RecordKey, "FileBinaryData");
		
EndFunction

Procedure TransferData_(ShouldReportProgress = False, ResultAddress = Undefined) Export
	
	ProgressTemplate = NStr("vi = 'Đã xử lý %1 (%2 Mb) tệp từ %3 (%4 Mb)';
							|ru = 'Обработано %1 (%2 Мб) файлов из %3 (%4 Мб)';
							|en = '%1 (%2 MB) out of %3 (%4 MB) files processed'; fa = '%1 (%2 MB) out of %3 (%4 MB) files processed';
							|it = 'Обработано %1 (%2 Мб) файлов из %3 (%4 Мб)';
							|pl = '%1 (%2 MB) out of %3 (%4 MB) files processed';
							|tr = '%3 (%4 MB) dosyasından %1 (%2 MB) dosya işlendi'");
	TotalRecords = 0;
	TotalSizeMB = 0;
	If ShouldReportProgress Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	COUNT(*) AS TotalRecords
		|FROM
		|	InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData";
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			TotalRecords = Selection.TotalRecords;
		EndIf;
		
		IncludeObjects = New Array();
		IncludeObjects.Add(Metadata.InformationRegisters.DeleteFilesBinaryData);
		TotalSizeMB = Round(GetDatabaseDataSize(, IncludeObjects) / 1024 / 1024, 0);
		Text = StringFunctionsClientServer.SubstituteParametersToString(ProgressTemplate, 
			0, 0, TotalRecords, TotalSizeMB);
		TimeConsumingOperations.ReportProgress(0, Text);
	EndIf;
	
	Selection = InformationRegisters.DeleteFilesBinaryData.Select();
	ProcessedRecordsCount = 0;
	ProcessedSizeCount = 0;
	Errors = New Array;
	While Selection.Next() Do
		File = Selection.File;
		FileDescription = String(File);
		BeginTransaction();
		Try
			
			Block = New DataLock();
			Block.Add("InformationRegister.DeleteFilesBinaryData").SetValue("File", File);
			Block.Add("InformationRegister.FileRepository").SetValue("File", File);
			Block.Lock();
			
			BinaryData = Selection.FileBinaryData.Get();
			If TypeOf(BinaryData) = Type("Picture") Then

				BinaryData = BinaryData.GetBinaryData();

			ElsIf TypeOf(BinaryData) <> Type("BinaryData") Then
				ErrorText = NStr("vi = 'Trong biểu ghi thông tin ""%1"" đối với tệp ""%2"" có lưu dữ liệu kiểu ""%3"", nhưng dự kiến là ""%4"".';
								|ru = 'В регистре сведений ""%1"" для файла ""%2"" хранятся данные типа ""%3"", а ожидалось ""%4"".';
								|en = 'Detected data type: %3. Expected data type: %4. Information register: %1. File: %2'; fa = 'Detected data type: %3. Expected data type: %4. Information register: %1. File: %2';
								|it = 'В регистре сведений ""%1"" для файла ""%2"" хранятся данные типа ""%3"", а ожидалось ""%4"".';
								|pl = 'Detected data type: %3. Expected data type: %4. Information register: %1. File: %2';
								|tr = '""%2"" dosyası için bilgi kaydı ""%1"", ""%4"" beklerken ""%3"" tipindeki verileri saklar.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
					Metadata.InformationRegisters.DeleteFilesBinaryData.Name,
					FileDescription,
					TypeOf(BinaryData),
					Type("BinaryData"));
				ErrorDescription = New Structure;
				ErrorDescription.Insert("FileName", Common.SubjectString(File));
				ErrorDescription.Insert("Error", ErrorText);
				ErrorDescription.Insert("DetailErrorDescription", ErrorText);
				ErrorDescription.Insert("Version", File);
				Errors.Add(ErrorDescription);
				
				WriteLogEvent(NStr("vi = 'Tệp.Lỗi sao chép tệp.';
									|ru = 'Файлы.Ошибка дедупликации файла.';
									|en = 'Files.File deduplication error.'; fa = 'Files.File deduplication error.';
									|it = 'Файлы.Ошибка дедупликации файла.';
									|pl = 'Files.File deduplication error.';
									|tr = 'Dosyalar. Dosya tekilleştirme hatası.'", Common.DefaultLanguageCode()),
					EventLogLevel.Error, , File, ErrorText);
				RollbackTransaction();
				Continue;
			EndIf;
			
			// @skip-check query-in-loop - Batch processing of large amounts of data. 
			If Not RecordExists(File) Then
				RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(File);
				WriteBinaryData(File, BinaryData, RecordingParametersVIB);
			EndIf;
			
			Record = InformationRegisters.DeleteFilesBinaryData.CreateRecordManager();
			Record.File = File;
			Record.Delete();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		If ShouldReportProgress Then
			ProcessedRecordsCount = ProcessedRecordsCount + 1;
			ProcessedSizeCount = ProcessedSizeCount + BinaryData.Size();
			If ProcessedRecordsCount % 100 = 0 Then
				Percent = Round(ProcessedRecordsCount * 100 / TotalRecords);
				Text = StringFunctionsClientServer.SubstituteParametersToString(ProgressTemplate, 
					ProcessedRecordsCount, Round(ProcessedSizeCount / 1024 / 1024), TotalRecords, TotalSizeMB);
				TimeConsumingOperations.ReportProgress(Percent, Text);
			EndIf;
		EndIf;
	EndDo; 
	
	If ValueIsFilled(ResultAddress) And Errors.Count() > 0 Then
		PutToTempStorage(Errors, ResultAddress);
	EndIf;
	
EndProcedure

Procedure AddRecord(File, BinaryDataStorageRef, Replace = True) Export

	Record = CreateRecordManager();
	Record.File = File;
	Record.BinaryDataStorage = BinaryDataStorageRef;
	Record.Write(Replace);	

EndProcedure

#Region UpdateHandlers

// Registers objects, 
// for which it is necessary to update register records on the "InfobaseUpdate" exchange plan.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesVersions.Ref
		|FROM
		|	Catalog.FilesVersions AS FilesVersions
		|		LEFT JOIN InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
		|		ON FilesVersions.Ref = DeleteFilesBinaryData.File
		|WHERE
		|	DeleteFilesBinaryData.File IS NULL
		|	AND FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InInfobase)
		|
		|ORDER BY
		|	FilesVersions.UniversalModificationDate DESC";
	
	ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DeleteFilesBinaryData.File AS Ref
	|FROM
	|	InformationRegister.DeleteFilesBinaryData AS DeleteFilesBinaryData
	|WHERE
	|	VALUETYPE(DeleteFilesBinaryData.File) = &FileType";
	
	Query.SetParameter("FileType", TypeOf(Catalogs.Files.EmptyRef()));
	
	ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.FilesVersions");
	If Selection.Count() > 0 Then
		TransferFilesBinaryDataToFileStorageInfoRegister(Selection);
	EndIf;
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Files");
	If Selection.Count() > 0 Then
		ToCreateTheMissingVersionFile(Selection);
	EndIf;
	
	ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.FilesVersions")
		And InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Files");
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure TransferFilesBinaryDataToFileStorageInfoRegister(Selection)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DeleteStoredVersionFiles");
			DataLockItem.SetValue("FileVersion", Selection.Ref);
			DataLockItem.Mode = DataLockMode.Shared;
			DataLock.Lock();
			
			WriteFileVersionManager = InformationRegisters.DeleteStoredVersionFiles.CreateRecordManager();
			WriteFileVersionManager.FileVersion = Selection.Ref;
			WriteFileVersionManager.Read();
			
			BinaryData = WriteFileVersionManager.StoredFile.Get();
			RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(Selection.Ref);
			// @skip-check query-in-loop - Batch processing of large amounts of data.
			WriteBinaryData(Selection.Ref, BinaryData, RecordingParametersVIB);

			InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			// If processing for a document failed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý dữ liệu nhị phân của tệp %1 do:
				|%2';
				|ru = 'Не удалось обработать двоичные данные файла %1 по причине:
				|%2';
				|en = 'Couldn''t process binary data of file %1. Reason:
				|%2'; fa = 'Couldn''t process binary data of file %1. Reason:
				|%2';
				|it = 'Non è stato possibile elaborare i dati binari del file: %1 a causa di:
				|%2';
				|pl = 'Nie udało się przetworzyć danych binarnych pliku %1 z powodu:
				|%2';
				|tr = 'Bu nedenle %1 dosyasının ikili verileri işlenilemedi:
				|%2'"), 
				Selection.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
				EventLogLevel.Warning, Selection.Ref.Metadata(), Selection.Ref, 
				MessageText);
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số dữ liệu nhị phân của tệp (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые двоичные данные файла (пропущены): %1';
				|en = 'Couldn''t process (skipped) some binary data of the file: %1'; fa = 'Couldn''t process (skipped) some binary data of the file: %1';
				|it = 'Non è stato possibile elaborare alcuni dati binari del file (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych danych binarnych pliku (pominięte): %1';
				|tr = 'Dosyanın ikili verileri işlenilemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Information, Metadata.Catalogs.FilesVersions,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý một loạt dữ liệu nhị phân khác của tệp: %1';
					|ru = 'Обработана очередная порция двоичных данных файлов: %1';
					|en = 'Another batch of file binary data is processed: %1'; fa = 'Another batch of file binary data is processed: %1';
					|it = 'È stata elaborata un''altra porzione di dati binari di file: %1';
					|pl = 'Przetworzono kolejną część binarnych danych plików: %1';
					|tr = 'Dosyaların ikili verilerin bir grubu daha işlendi: %1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

Procedure ToCreateTheMissingVersionFile(Selection)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	While Selection.Next() Do
		
		FileRef = Selection.Ref; // CatalogRef.Files
		RepresentationOfTheReference = String(FileRef);
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.Files");
		LockItem.SetValue("Ref", FileRef);
		
		LockItem = Block.Add("InformationRegister.DeleteFilesBinaryData");
		LockItem.SetValue("File", FileRef);
		
		BeginTransaction();
		Try
			Block.Lock();
			
			FileObject1 = FileRef.GetObject();
			
			If FileObject1 <> Undefined Then
				
				Version = Catalogs.FilesVersions.CreateItem();
				Version.SetNewCode();
				
				PropertiesSet = "Author,Owner,UniversalModificationDate,CreationDate,PictureIndex,
				|Description,DeletionMark, PathToFile,Size,Extension,TextExtractionStatus,
				|TextStorage, FileStorageType, Volume";
				
				FillPropertyValues(Version, FileObject1, PropertiesSet);
				Version.VersionNumber = 1;
				Version.Owner = FileRef;
				
				InfobaseUpdate.WriteObject(Version);
				
				FileObject1.CurrentVersion = Version.Ref;
				InfobaseUpdate.WriteObject(FileObject1);
				
				BinaryFilesData = InformationRegisters.DeleteFilesBinaryData.CreateRecordManager();
				BinaryFilesData.File = FileRef;
				BinaryFilesData.Read();
				If BinaryFilesData.Selected() Then
					RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(Version);
					// @skip-check query-in-loop - Batch processing of large amounts of data.
					WriteBinaryData(Version.Ref, BinaryFilesData.FileBinaryData.Get(), RecordingParametersVIB);
					BinaryFilesData.Delete();
				EndIf;
				
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			
			RollbackTransaction();
			// If processing for a file failed, try again.
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				FileRef,
				RepresentationOfTheReference,
				ErrorInfo());
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số tệp (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые файлы (пропущены): %1';
				|en = 'Couldn''t process (skipped) some files: %1'; fa = 'Couldn''t process (skipped) some files: %1';
				|it = 'Non è stato possibile elaborare alcuni file (saltati): %1';
				|pl = 'Nie udało się przetworzyć niektórych plików (pominięte): %1';
				|tr = 'Bazı dosyalar işlenilemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.FilesVersions,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý một loạt tệp khác: %1';
					|ru = 'Обработана очередная порция файлов: %1';
					|en = 'Another batch of files is processed: %1'; fa = 'Another batch of files is processed: %1';
					|it = 'È stata elaborata un''altra porzione di file: %1';
					|pl = 'Przetworzono kolejną część plików: %1';
					|tr = 'Dosyaların bir grubu daha işlendi: %1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

Function RecordExists(File)
	
	Query = New Query;
	Query.SetParameter("File", File);
	Query.Text =
	"SELECT TOP 1
	|	1 AS Validation
	|FROM
	|	InformationRegister.FileRepository AS FileRepository
	|WHERE
	|	FileRepository.File = &File";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("TransferData_", True);
	
EndProcedure

#EndRegion


#EndIf