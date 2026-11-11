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

	AttributesToEdit = New Array;
	AttributesToEdit.Add("Comment");

	Return AttributesToEdit;

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
	|	ObjectReadingAllowed(Owner.FileOwner)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(Owner.FileOwner)";

	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ObjectForm" Then
		StandardProcessing = False;
		SelectedForm       = "DataProcessor.FilesOperations.Form.AttachedFileVersion";
	EndIf;
EndProcedure

#EndRegion

#Region Internal

// Registers the objects to be updated in the InfobaseUpdate exchange plan.
// 
//
// Parameters:
//  Parameters - Structure - Internal parameter to pass to the InfobaseUpdate.MarkForProcessing procedure.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = Metadata.Catalogs.FilesVersions.FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();

	QueryText =
	"SELECT TOP 1000
	|	FilesVersions.Ref AS Ref,
	|	FilesVersions.UniversalModificationDate AS UniversalModificationDate
	|FROM
	|	Catalog.FilesVersions AS FilesVersions
	|WHERE
	|	FilesVersions.FileStorageType = VALUE(Enum.FileStorageTypes.InVolumesOnHardDrive)
	|	AND (FilesVersions.UniversalModificationDate < &ModificationDate
	|	OR FilesVersions.UniversalModificationDate = &ModificationDate
	|	AND FilesVersions.Ref < &Ref)
	|
	|ORDER BY
	|	UniversalModificationDate DESC,
	|	Ref DESC";
	
	Query = New Query(QueryText);
	Query.SetParameter("ModificationDate", Date(3999, 12, 31));
	Query.SetParameter("Ref", Catalogs.FilesVersions.GetRef(
		New UUID("FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")));
	
	While True Do
		
		//@skip-check query-in-loop - Batch data processing
		TheSampleTable = Query.Execute().Unload();
		
		If TheSampleTable.Count() = 0 Then
			Break;
		EndIf;
		
		VersionsForProcessing = TheSampleTable.UnloadColumn("Ref");
		InfobaseUpdate.MarkForProcessing(Parameters, VersionsForProcessing);

		If TheSampleTable.Count() < 1000 Then
			Break;
		EndIf;
		
		LastRow = TheSampleTable[TheSampleTable.Count() - 1];
		Query.SetParameter("ModificationDate", LastRow.UniversalModificationDate);
		Query.SetParameter("Ref", LastRow.Ref);
		
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	SelectedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);

	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	For Each String In SelectedData Do
		
		If ProcessFileVersion(String.Ref) Then
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
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.FilesVersions");

EndProcedure

#EndRegion

#Region Private

Function ProcessFileVersion(VersionRef)

	Result = True;
	RepresentationOfTheReference = String(VersionRef);
	
	Block = New DataLock;
	LockItem = Block.Add("Catalog.FilesVersions");
	LockItem.SetValue("Ref", VersionRef);

	BeginTransaction();
	Try
		Block.Lock();
		
		VersionObject = Undefined;
		ItIsRequiredToRecord = False;
		
		// @skip-check query-in-loop - Batch processing of a large amount of data.
		PathToFile = Common.ObjectAttributeValue(VersionRef, "PathToFile");
		If StrStartsWith(PathToFile, "/") Or StrStartsWith(PathToFile, "\") Then
			NewFilePath = Mid(PathToFile, 2);

			VersionObject = VersionRef.GetObject();
			If VersionObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(VersionRef);
				CommitTransaction();
				Return Result;
			EndIf;
			VersionObject.PathToFile = NewFilePath;
			ItIsRequiredToRecord = True;
		EndIf;
		
		If VersionObject = Undefined Then
			VersionObject = VersionRef.GetObject();
			If VersionObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(VersionRef);
				CommitTransaction();
				Return Result;
			EndIf;
		EndIf;
		
		FileBinaryData = Undefined;
		FileBinaryDataStorage = VersionObject.FileStorage;
		FileBinaryData = ?(TypeOf(FileBinaryDataStorage) = Type("ValueStorage"),
			FileBinaryDataStorage.Get(), Undefined);
		
		If FileBinaryData <> Undefined Then
			VersionObject.FileStorage = New ValueStorage(Undefined);
			ItIsRequiredToRecord = True;
		EndIf;

		If ItIsRequiredToRecord Then
			VersionObject.Write();
		Else
			InfobaseUpdate.MarkProcessingCompletion(VersionRef);
		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();

		Result = False;
		InfobaseUpdate.WriteErrorToEventLog(VersionRef,
			RepresentationOfTheReference, ErrorInfo());

	EndTry;

	Return Result;

EndFunction

#EndRegion

#EndIf