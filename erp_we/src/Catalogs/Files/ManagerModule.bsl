///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Return FilesOperations.AttributesToEditInBatchProcessing();
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(FileOwner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(FileOwner)";
	
	Restriction.TextForExternalUsers1 =
	"AllowRead
	|WHERE
	|	CASE 
	|		WHEN VALUETYPE(FileOwner) = TYPE(Catalog.FilesFolders)
	|			THEN ObjectReadingAllowed(CAST(FileOwner AS Catalog.FilesFolders))
	|		ELSE ValueAllowed(CAST(Author AS Catalog.ExternalUsers))
	|	END
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	CASE 
	|		WHEN VALUETYPE(FileOwner) = TYPE(Catalog.FilesFolders)
	|			THEN ObjectUpdateAllowed(CAST(FileOwner AS Catalog.FilesFolders))
	|		ELSE ValueAllowed(CAST(Author AS Catalog.ExternalUsers))
	|	END";
	Restriction.ByOwnerWithoutSavingAccessKeysForExternalUsers = False;
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleGeneration = Common.CommonModule("GenerateFrom");
		Return ModuleGeneration.AddGenerationCommand(GenerationCommands, Metadata.Catalogs.Files);
	EndIf;
	
	Return Undefined;
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Parameters.Count() = 0 Then
		SelectedForm = "Files"; // Opening the file list because the specific file is not specified.
		StandardProcessing = False;
	EndIf;
	If FormType = "ListForm" Then
		CurrentRow = CommonClientServer.StructureProperty(Parameters, "CurrentRow");
		If TypeOf(CurrentRow) = Type("CatalogRef.Files") And Not CurrentRow.IsEmpty() Then
			StandardProcessing = False;
			FileOwner = Common.ObjectAttributeValue(CurrentRow, "FileOwner");
			If TypeOf(FileOwner) = Type("CatalogRef.FilesFolders") Then
				Parameters.Insert("Folder", FileOwner);
				SelectedForm = "DataProcessor.FilesOperations.Form.AttachedFiles";
			Else
				Parameters.Insert("FileOwner", FileOwner);
				SelectedForm = "DataProcessor.FilesOperations.Form.AttachedFiles";
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1000
		|	Files.Ref AS Ref
		|FROM
		|	Catalog.Files AS Files
		|		LEFT JOIN InformationRegister.FilesInfo AS FilesInfo
		|		ON Files.Ref = FilesInfo.File
		|WHERE
		|	Files.Ref > &Ref
		|	AND (Files.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
		|	OR ((Files.UniversalModificationDate = DATETIME(1, 1, 1, 0, 0, 0)
		|					AND Files.CurrentVersion <> VALUE(Catalog.FilesVersions.EmptyRef)
		|				OR Files.FileStorageType = VALUE(Enum.FileStorageTypes.EmptyRef))
		|			OR FilesInfo.File IS NULL))
		|
		|ORDER BY
		|	Ref";
	
	AllFilesProcessed = False;
	Ref = "";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Catalog.Files";
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	While Not AllFilesProcessed Do
		
		Query.SetParameter("Ref", Ref);
		// @skip-check query-in-loop - Batch processing of a large amount of data.
		ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
		
		InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
		
		RefsCount = ReferencesArrray.Count();
		If RefsCount < 1000 Then
			AllFilesProcessed = True;
		ElsIf RefsCount > 0 Then
			Ref = ReferencesArrray[RefsCount - 1];
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	SelectedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	For Each String In SelectedData Do
		If ProcessFile(String.Ref) Then
			ObjectsProcessed = ObjectsProcessed + 1;
		Else
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
		EndIf;
	EndDo;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý tệp (đã bỏ qua): %1';
				|ru = 'Не удалось обработать файлы (пропущены): %1';
				|en = 'Couldn''t process (skipped) the files: %1'; fa = 'Couldn''t process (skipped) the files: %1';
				|it = 'Non è stato possibile elaborare i file (saltati): %1';
				|pl = 'Nie udało się przetworzyć plików (pominięte): %1';
				|tr = 'Dosyalar işlenemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	EndIf;

	WriteLogEvent(InfobaseUpdate.EventLogEvent(), 
		EventLogLevel.Information, , ,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xử lý một loạt tệp khác: %1';
				|ru = 'Обработана очередная порция файлов: %1';
				|en = 'Yet another batch of files is processed: %1'; fa = 'Yet another batch of files is processed: %1';
				|it = 'È stata elaborata un''altra porzione di file: %1';
				|pl = 'Przetworzono kolejną część plików: %1';
				|tr = 'Dosyaların bir grubu daha işlendi: %1'"),
			ObjectsProcessed));
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Files");
	
EndProcedure

Function ProcessFile(Ref)
	
	Result = True;
	RepresentationOfTheReference = String(Ref);
	
	DataLockFile = New DataLock;
	DataLockItem = DataLockFile.Add("Catalog.Files");
	DataLockItem.SetValue("Ref", Ref);
	
	BeginTransaction();
	Try
		DataLockFile.Lock();
		
		FileToUpdate = Undefined;
		ItIsRequiredToRecord = False;
		// @skip-check query-in-loop - Batch processing of a large amount of data.
		FileAttributes = Common.ObjectAttributesValues(Ref, 
			"UniversalModificationDate,CurrentVersion,FileStorageType");
			
		If ValueIsFilled(FileAttributes.CurrentVersion) 
			And (Not ValueIsFilled(FileAttributes.UniversalModificationDate)
				Or Not ValueIsFilled(FileAttributes.FileStorageType)) Then
			
			FileToUpdate = Ref.GetObject(); // CatalogObject.Files
			If FileToUpdate = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(Ref);
				CommitTransaction();
				Return Result;
			EndIf;

			// @skip-check query-in-loop - Batch processing of a large amount of data.
			CurrentVersionAttributes = Common.ObjectAttributesValues(FileAttributes.CurrentVersion, 
				"UniversalModificationDate,FileStorageType");
			FileToUpdate.UniversalModificationDate = CurrentVersionAttributes.UniversalModificationDate;
			FileToUpdate.FileStorageType             = CurrentVersionAttributes.FileStorageType;
			
			RecordSet = InformationRegisters.FilesInfo.CreateRecordSet();
			RecordSet.Filter.File.Set(Ref);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				FileInfo1 = RecordSet.Add();
				FillPropertyValues(FileInfo1, FileToUpdate);
				FileInfo1.File          = FileToUpdate.Ref;
				FileInfo1.Author         = FileToUpdate.Author;
				FileInfo1.FileOwner = FileToUpdate.FileOwner;
				
				If FileToUpdate.SignedWithDS And FileToUpdate.Encrypted Then
					FileInfo1.SignedEncryptedPictureNumber = 2;
				ElsIf FileToUpdate.Encrypted Then
					FileInfo1.SignedEncryptedPictureNumber = 1;
				ElsIf FileToUpdate.SignedWithDS Then
					FileInfo1.SignedEncryptedPictureNumber = 0;
				Else
					FileInfo1.SignedEncryptedPictureNumber = -1;
				EndIf;
				InfobaseUpdate.WriteRecordSet(RecordSet);
			EndIf;
			ItIsRequiredToRecord = True;
		EndIf;
		
		If FileAttributes.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive Then

			If FileToUpdate = Undefined Then
				FileToUpdate = Ref.GetObject(); // CatalogObject.Files
				If FileToUpdate = Undefined Then
					InfobaseUpdate.MarkProcessingCompletion(Ref);
					CommitTransaction();
					Return Result;
				EndIf;
			EndIf;
			FileBinaryData = Undefined;
			FileBinaryDataStorage = FileToUpdate.FileStorage;
			FileBinaryData = ?(TypeOf(FileBinaryDataStorage) = Type("ValueStorage"),
				FileBinaryDataStorage.Get(), Undefined);
			
			If FileBinaryData <> Undefined Then
				FileToUpdate.FileStorage = New ValueStorage(Undefined);
				ItIsRequiredToRecord = True;
			EndIf;
			
		EndIf;
		
		If ItIsRequiredToRecord Then
			InfobaseUpdate.WriteObject(FileToUpdate);
		Else
			InfobaseUpdate.MarkProcessingCompletion(Ref);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Result = False;
		InfobaseUpdate.WriteErrorToEventLog(Ref,
			RepresentationOfTheReference, ErrorInfo());
	EndTry;
		
	Return Result;

EndFunction	

#EndRegion

#EndIf

