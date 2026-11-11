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

// Returns the deduplicated file storage parameters for the specified
// BinaryDataStorage catalog item and storage type.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  FileStorageKind				- EnumRef.StorageKinds, Undefined - Value of FilesStorageKind dimension.
//
// Returns:
//  - Structure - If storage parameters exist, contains the following parameters: FileStorageType, Volume, PathToFile.
//  - Undefined - If storage parameters exist, contains the following parameters: FileStorageType, Volume, PathToFile.
//
Function DeduplicatedFileStorageInformation(BinaryDataStorageRef, FileStorageKind = Undefined) Export

	If FileStorageKind = Undefined Then
		FileStorageKind = Enums.StorageKinds.OperationalStorage;
	EndIf;

	Query = New Query;
	Query.SetParameter("BinaryDataStorage"	, BinaryDataStorageRef);
	Query.SetParameter("FileStorageKind"		, FileStorageKind);
	Query.Text = 
		"SELECT
		|	DeduplicatedFileStorageInformation.FileStorageType AS FileStorageType,
		|	DeduplicatedFileStorageInformation.Volume AS Volume,
		|	"""" AS PathToFile
		|FROM
		|	InformationRegister.DeduplicatedFileStorageInformation AS DeduplicatedFileStorageInformation
		|WHERE
		|	DeduplicatedFileStorageInformation.BinaryDataStorage = &BinaryDataStorage
		|	AND DeduplicatedFileStorageInformation.FileStorageKind = &FileStorageKind";

	DataSelection = Query.Execute().Select();
	If DataSelection.Next() Then

		Result = New Structure("FileStorageType,Volume,PathToFile");
		FillPropertyValues(Result, DataSelection);

	Else
		Result = Undefined;
	EndIf;

	Return Result;

EndFunction

// Adds an entry to the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  RecordingParametersVIB				- Structure - See FileArchiveManagementServer.ParametersForWritingToInfobase
//
Procedure AddRecord(BinaryDataStorageRef, RecordingParametersVIB) Export

	If RecordingParametersVIB.IsWriteToFileArchive Then
		FileStorageKind = Enums.StorageKinds.ArchivalStorage;
	Else
		FileStorageKind = Enums.StorageKinds.OperationalStorage;
	EndIf;

	Set = CreateRecordSet();
	Set.Filter.BinaryDataStorage.Set(BinaryDataStorageRef);
	Set.Filter.FileStorageKind.Set(FileStorageKind);

	Record = Set.Add();
	Record.BinaryDataStorage	= BinaryDataStorageRef;
	Record.FileStorageKind		= FileStorageKind;
	Record.FileStorageType			= RecordingParametersVIB.FileStorageType;
	Record.Volume						= RecordingParametersVIB.Volume;

	Set.Write();

EndProcedure

// Deletes an entry from the information register.
//
// Parameters:
//  BinaryDataStorageRef	- CatalogRef.BinaryDataStorage - Value of the BinaryDataStorage dimension.
//  FileStorageKind				- EnumRef.StorageKinds, Undefined - Value of FilesStorageKind dimension.
//
Procedure DeleteRecord(BinaryDataStorageRef, FileStorageKind = Undefined) Export
	
	Block = New DataLock();
	
	LockItem = Block.Add("InformationRegister.DeduplicatedFileStorageInformation");
	LockItem.SetValue("BinaryDataStorage", BinaryDataStorageRef);

	RecordSet = CreateRecordSet();
	RecordSet.Filter.BinaryDataStorage.Set(BinaryDataStorageRef);
	
	If ValueIsFilled(FileStorageKind) Then
		RecordSet.Filter.FileStorageKind.Set(FileStorageKind);	
	
		LockItem.SetValue("FileStorageKind", FileStorageKind);
	
	EndIf;	

	BeginTransaction();
	Try

		Block.Lock();

		RecordSet.Write();

		CommitTransaction();

	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

#Region UpdateHandlers

// Registers objects on the InfobaseUpdate exchange plan
// for which entries need to be added to the register.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	FileRepository.BinaryDataStorage AS Ref
	|FROM
	|	InformationRegister.FileRepository AS FileRepository";

	QueryResult = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, QueryResult.UnloadColumn("Ref"));

EndProcedure

// Version update handler for v.<?>:
// - Adds entries to information register DeduplicatedFilesStorageInformation
// for the used BinaryDataStorage catalog items.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	BinaryDataStorages = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.BinaryDataStorage");

	If BinaryDataStorages.Count() > 0 Then

		RegisterMetadata		= Metadata.InformationRegisters.DeduplicatedFileStorageInformation;
		RegisterPresentation	= RegisterMetadata.Presentation();		
		ProcedureName			= RegisterMetadata.FullName() + "." + "ProcessDataForMigrationToNewVersion";

		ObjectsProcessed = 0;
		ObjectsWithIssuesCount = 0;

		While BinaryDataStorages.Next() Do

			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DeduplicatedFileStorageInformation");
			DataLockItem.SetValue("BinaryDataStorage", BinaryDataStorages.Ref);
			DataLockItem.SetValue("FileStorageKind"		, Enums.StorageKinds.OperationalStorage);

			RecordingParametersVIB = FileArchiveManagementServer.ParametersForWritingToInfobase();
			RecordingParametersVIB.FileStorageType = Enums.FileStorageTypes.InInfobase;			

			BeginTransaction();
			Try		

				DataLock.Lock();		

				AddRecord(BinaryDataStorages.Ref, RecordingParametersVIB);

				InfobaseUpdate.MarkProcessingCompletion(BinaryDataStorages.Ref);
				ObjectsProcessed = ObjectsProcessed + 1;
				CommitTransaction();
				
			Except

				RollbackTransaction();

				ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Не удалось добавить запись в регистр сведений ""Сведения о хранении дедуплицированных файлов"" 
					|для элемента справочника ""Хранилище двоичных данных"" %1 по причине:
					|%2';
					|vi = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2';
					|en = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2'; fa = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2';
					|it = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2';
					|pl = 'Couldn''t add an entry to the ""Deduplicated file storage information"" information register
					|for the ""Binary data storage"" catalog item %1 due to:
					|%2';
					|tr = '""İkili veri deposu"" kılavuzunun %1 öğesi için ""Tekilleştirilmiş dosya saklama bilgileri"" 
					|bilgi kaydına satır eklenemedi. Sebep:
					|%2'"), 
					BinaryDataStorages.Ref, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

				InfobaseUpdate.WriteErrorToEventLog(
					RegisterMetadata,
					RegisterPresentation,
					MessageText);

			EndTry;
		EndDo;

		If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось обработать некоторые элементы справочника ""Хранилище двоичных данных"" (пропущены): %1';
					|vi = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1';
					|en = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1'; fa = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1';
					|it = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1';
					|pl = 'Couldn''t process (skipped) some items of the ""Binary data storage"" catalog: %1';
					|tr = '""İkili veri deposu"" kılavuzunun bazı öğeleri işlenemedi (atlandı): %1'"), 
				ObjectsWithIssuesCount);
			Raise MessageText;
		EndIf;

		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(), 
			EventLogLevel.Information, RegisterMetadata, ,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Процедура %1 обработала очередную порцию записей: %2';
					|vi = 'Procedure %1 processed yet another batch of records: %2.';
					|en = 'Procedure %1 processed yet another batch of records: %2.'; fa = 'Procedure %1 processed yet another batch of records: %2.';
					|it = 'La procedura %1 ha elaborato un''ulteriore porzione di record: %2';
					|pl = 'Procedura %1 przetworzyła kolejną część wpisów: %2';
					|tr = '%1 prosedürü diğer bir kayıt kümesini işledi: %2'"),
				ProcedureName,
				ObjectsProcessed));
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.BinaryDataStorage");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf