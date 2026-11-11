///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region TextExtraction

// Adds and removes records in the TextExtractionQueue information register on change
// state of file version text extraction.
//
// Parameters:
//  TextSource - DefinedType.AttachedFile - file with changed text extraction state.
//  TextExtractionState - EnumRef.FileTextExtractionStatuses - a new status.
//
Procedure UpdateTextExtractionQueueState(TextSource, TextExtractionState) Export
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TextExtractionQueue.CreateRecordSet();
	RecordSet.Filter.DataAreaAuxiliaryData.Set(ModuleSaaSOperations.SessionSeparatorValue());
	RecordSet.Filter.TextSource.Set(TextSource);
	
	If TextExtractionState = Enums.FileTextExtractionStatuses.NotExtracted
			Or TextExtractionState = Enums.FileTextExtractionStatuses.EmptyRef() Then
			
		Record = RecordSet.Add();
		Record.DataAreaAuxiliaryData = ModuleSaaSOperations.SessionSeparatorValue();
		Record.TextSource = TextSource;
			
	EndIf;
		
	RecordSet.Write();
	
EndProcedure

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ExtractTextFromFiles");
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ClearExcessiveFiles");
	NamesAndAliasesMap.Insert("FilesOperationsInternal.ScheduledFileSynchronizationWebdav");
	NamesAndAliasesMap.Insert("InformationRegisters.FileRepository.TransferData_");
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage.
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "TextExtractionPlanningSaaS";
	
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		NewRow.Use = ModuleFullTextSearchServer.UseFullTextSearch();
	Else
		NewRow.Use = False;
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.CleanUpUnusedFiles.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.FilesSynchronization.Name);
	
EndProcedure

// See ODataInterfaceOverridable.OnPopulateDependantTablesForODataImportExport
Procedure OnPopulateDependantTablesForODataImportExport(Tables) Export
	
	DependentTables = FilesCatalogsAndStorageOptionObjects().StorageObjects;
	For Each DependentTable In DependentTables Do
		Tables.Add(DependentTable.Key);
	EndDo;
	
EndProcedure

// CloudTechnology.ExportImportData

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	
	Types.Add(Metadata.InformationRegisters.TextExtractionQueue);
	Types.Add(Metadata.InformationRegisters.DeleteFilesBinaryData);
	Types.Add(Metadata.Constants.VolumePathIgnoreRegionalSettings);
	
	TypesToExclude = FilesCatalogsAndStorageOptionObjects().StorageObjects;
	For Each TypeToExclude In TypesToExclude Do
		ModuleExportImportData.AddTypeExcludedFromUploadingUploads(
			Types,
			Common.MetadataObjectByFullName(TypeToExclude.Key),
			ModuleExportImportData.ActionWithLinksDoNotChange());	
	EndDo;
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataExportHandlers.
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	CatalogsFiles_ = FilesCatalogsAndStorageOptionObjects().CatalogsFiles_;
	For Each CatalogFiles_ In CatalogsFiles_ Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Common.MetadataObjectByFullName(CatalogFiles_.Key);
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = "1.0.0.1";
		
	EndDo;
	
	If HandlersTable.Find(Metadata.Catalogs.Files, "MetadataObject") = Undefined Then
	
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Metadata.Catalogs.Files;
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeExportObject = True;
		NewHandler.Version = "1.0.0.1";
	
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnRegisterDataImportHandlers.
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	CatalogsFiles_ = FilesCatalogsAndStorageOptionObjects().CatalogsFiles_;
	For Each CatalogFiles_ In CatalogsFiles_ Do
		
		NewHandler = HandlersTable.Add();
		NewHandler.MetadataObject = Common.MetadataObjectByFullName(CatalogFiles_.Key);
		NewHandler.Handler = FilesOperationsInternalSaaS;
		NewHandler.BeforeImportObject = True;
		NewHandler.Version = "1.0.0.1";
		
	EndDo;
	
EndProcedure

// Attached in ExportImportDataOverridable.OnRegisterDataExportHandlers.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	If TypeOf(Object) = Type("CatalogObject.Files") Then
		ClearRefToFilesStorageVolume(Object);
		If Object.StoreVersions Then
			Return;
		EndIf;
	EndIf;
	
	If Object.IsFolder Then
		Return;
	EndIf;
	
	CatalogsFiles_ = FilesCatalogsAndStorageOptionObjects().CatalogsFiles_;
	
	Handler = CatalogsFiles_.Get(Object.Metadata().FullName());
	
	If Handler = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý đối tượng metadata %1 bởi hàm sự kiện
				|%2.';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком
				|%2.';
				|en = 'Handler %2 cannot handle
				|metadata object %1.'; fa = 'Handler %2 cannot handle
				|metadata object %1.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dall''gestore 
				|%2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania 
				|%2.';
				|tr = '%1 meta veri nesnesi bu işleyici tarafından işlenemez
				|%2.'",
				Common.DefaultLanguageCode()),
			Object.Metadata().FullName(), "FilesOperationsInternalSaaS.BeforeExportObject()");
		
	EndIf;
	
	HandlerModule = Common.CommonModule(Handler);
	FileExtention = HandlerModule.FileExtention(Object);
	FileName = Container.CreateCustomFile(FileExtention);
	
	Try
		
		HandlerModule.ExportFile(Object, FileName);
		
		Artifact = XDTOFactory.Create(FileArtifactType());
		Artifact.RelativeFilePath = Container.GetRelativeFileName(FileName);
		Artifacts.Add(Artifact);
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
		
			ModuleSaaSTechnology = Common.CommonModule("CloudTechnology");
			If CommonClientServer.CompareVersions(ModuleSaaSTechnology.LibraryVersion(), "2.0.2.15") >= 0 Then
				Warning = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã bỏ qua kết xuất tệp %1 (kiểu %2) do nguyên nhân
					|%3';
					|ru = 'Выгрузка файла %1 (тип %2) пропущена по причине
					|%3';
					|en = 'Export of file %1 (type %2) is skipped due to 
					|%3'; fa = 'Export of file %1 (type %2) is skipped due to 
					|%3';
					|it = 'Caricamente file %1 (TIPO %2) non riuscito a causa di 
					|%3';
					|pl = 'Wyładowanie pliku %1 (typ %2) została przepuszczona z powodu
					|%3';
					|tr = '%1 dosyasının (%2 türü) dışa aktarımı atlandı çünkü 
					|%3'"),
					Object,
					Object.Metadata().FullName(),
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				Container.AddWarning(Warning);
			EndIf;
			
		EndIf;
		
		WriteLogEvent(
			NStr("vi = 'Tệp.Kết xuất dữ liệu để chuyển đến dịch vụ';
				|ru = 'Файлы.Выгрузка данных для перехода в сервис';
				|en = 'Files.Export data for cloud migration'; fa = 'Files.Export data for cloud migration';
				|it = 'I file. Caricamento dati per passare al servizio';
				|pl = 'Pliki. Eksport danych do przejścia do serwisu';
				|tr = 'Dosyalar.Hizmete geçmek için veri dışa aktarımı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Object.Metadata(),
			Object.Ref,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
			
		Container.ExcludeFile(FileName);
		
	EndTry;
	
	ClearRefToFilesStorageVolume(Object);
	
EndProcedure

// Attached in ExportImportDataOverridable.OnRegisterDataImportHandlers.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeImportObject(Container, Object, Artifacts, Cancel) Export
	
	CatalogsFiles_ = FilesCatalogsAndStorageOptionObjects().CatalogsFiles_;
	
	Handler = CatalogsFiles_.Get(Object.Metadata().FullName());
	
	If Handler = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý đối tượng metadata %1 bởi hàm sự kiện
				|%2.';
				|ru = 'Объект метаданных %1 не может быть обработан обработчиком
				|%2.';
				|en = 'Handler %2 cannot handle
				|metadata object %1.'; fa = 'Handler %2 cannot handle
				|metadata object %1.';
				|it = 'L''oggetto dei metadati %1 non può essere elaborato dall''gestore 
				|%2.';
				|pl = 'Obiekt metadanych %1 nie może być przetworzony przez procedurę przetwarzania 
				|%2.';
				|tr = '%1 meta veri nesnesi bu işleyici tarafından işlenemez
				|%2.'", Common.DefaultLanguageCode()),
			Object.Metadata().FullName(), "FilesOperationsInternalSaaS.BeforeExportObject()");
		
	EndIf;
	
	HandlerModule = Common.CommonModule(Handler);
	
	For Each Artifact In Artifacts Do
		
		If Artifact.Type() = FileArtifactType() Then
			
			HandlerModule.ImportFile_(Object, Container.GetFullFileName(Artifact.RelativeFilePath));
			
		EndIf;
		
	EndDo;
	
EndProcedure

// End CloudTechnology.ExportImportData

// Creates and queues jobs that will transfer data to the file
// storage with deduplication for the used data areas.
//
Procedure StartDeduplication() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		
		Return;
		
	EndIf;
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	Query = New Query( 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)");
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		JobParameters = New Structure;
		JobParameters.Insert("DataArea", Selection.DataArea);
		JobParameters.Insert("MethodName", "InformationRegisters.FileRepository.TransferData_");
		
		If ModuleJobsQueue.GetJobs(JobParameters).Count() = 0 Then
			
			JobParameters.Insert("Use", True);
			JobParameters.Insert("RestartCountOnFailure", 3);
			ModuleJobsQueue.AddJob(JobParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// ACC:299-disable - event and infobase update handlers.

#Region InfobaseUpdate

// Fills text extraction queue for the current data area. Is used for initial filling on
// refresh.
//
Procedure FillTextExtractionQueue() Export
	
	IsSeparatedConfiguration = False;
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
	EndIf;
	
	If Not IsSeparatedConfiguration Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = FilesOperationsInternal.QueryTextToExtractText(True);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		UpdateTextExtractionQueueState(Selection.Ref,
			Enums.FileTextExtractionStatuses.NotExtracted);
	EndDo;
	
EndProcedure

#EndRegion

// ACC:299-on

#Region TextExtraction

// Determines the list of data areas where text extraction is required and plans
// it using the job queue.
//
Procedure HandleTextExtractionQueue() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TextExtractionPlanningSaaS);
	
	If Not Common.DataSeparationEnabled()
		Or Not Common.IsWindowsServer() Then
		Return;
	EndIf;
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	SetPrivilegedMode(True);
	
	SeparatedMethodName = "FilesOperationsInternal.ExtractTextFromFiles";
	
	QueryText = 
	"SELECT DISTINCT
	|	TextExtractionQueue.DataAreaAuxiliaryData AS DataArea,
	|	CASE
	|		WHEN TimeZones.Value = """"
	|			THEN UNDEFINED
	|		ELSE ISNULL(TimeZones.Value, UNDEFINED)
	|	END AS TimeZone
	|FROM
	|	InformationRegister.TextExtractionQueue AS TextExtractionQueue
	|		LEFT JOIN Constant.DataAreaTimeZone AS TimeZones
	|		ON TextExtractionQueue.DataAreaAuxiliaryData = TimeZones.DataAreaAuxiliaryData
	|		LEFT JOIN InformationRegister.DataAreas AS DataAreas
	|		ON TextExtractionQueue.DataAreaAuxiliaryData = DataAreas.DataAreaAuxiliaryData
	|WHERE
	|	NOT TextExtractionQueue.DataAreaAuxiliaryData IN (&DataAreasToProcess)
	|	AND DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)";
	Query = New Query(QueryText);
	Query.SetParameter("DataAreasToProcess", ModuleJobsQueue.GetJobs(
		New Structure("MethodName", SeparatedMethodName)));
		
	If TransactionActive() Then
		Raise(NStr("vi = 'Giao tác đang hoạt động. Không thể thực hiện truy vấn trong giao tác.';
					|ru = 'Транзакция активна. Выполнение запроса в транзакции невозможно.';
					|en = 'The transaction is active. Cannot execute a query in the transaction.'; fa = 'The transaction is active. Cannot execute a query in the transaction.';
					|it = 'La transazione è attiva. Non è possibile completare la richiesta nella transazione.';
					|pl = 'Transakcja jest aktywna. Wykonanie zapytania w transakcji jest niemożliwa.';
					|tr = 'İşlem aktif. İşlemin içinde bir sorgu yürütülemiyor.'"));
	EndIf;
	
	AttemptsNumber = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // Reading outside a transaction. This might cause the following error:
			                                // "Could not continue scan with NOLOCK due to data movement"
			                                // In case of the error, try to read again.
			Break;
		Except
			AttemptsNumber = AttemptsNumber + 1;
			If AttemptsNumber = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
		
	Selection = Result.Select();
	While Selection.Next() Do
		// Check for data area lock.
		If ModuleSaaSOperations.DataAreaLocked(Selection.DataArea) Then
			// The area is locked, proceeding to the next record.
			Continue;
		EndIf;
		
		NewJob = New Structure();
		NewJob.Insert("DataArea", Selection.DataArea);
		NewJob.Insert("ScheduledStartTime", ToLocalTime(CurrentUniversalDate(), Selection.TimeZone));
		NewJob.Insert("MethodName", SeparatedMethodName);
		ModuleJobsQueue.AddJob(NewJob);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function FileArtifactType()
	
	Return XDTOFactory.Type(Package(), "FileArtefact");
	
EndFunction

Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/Files/1.0.0.1";
	
EndFunction

Function FilesCatalogsAndStorageOptionObjects()
	
	Return FilesOperationsInternalSaaSCached.FilesCatalogsAndStorageOptionObjects();
	
EndFunction

Procedure ClearRefToFilesStorageVolume(Object)
	
	For Each ObjectAttribute In Object.Metadata().Attributes Do
		If ObjectAttribute.Type.ContainsType(Type("CatalogRef.FileStorageVolumes")) 
			And ValueIsFilled(Object[ObjectAttribute.Name]) Then
			Object[ObjectAttribute.Name] = Undefined;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
