
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager
Var CurHandlers; // DataProcessorObject.ExportImportDataDataImportHandlersManager
Var CurFlowOfLinkReplacement; // DataProcessorObject.ExportImportDataReferenceReplacementStream
Var ProcessedDuplicatesOfPredefined; // Map
Var FixObjectProcessing;
Var HandlersAvailability; // Structure

#EndRegion

#Region Internal

Procedure Initialize(Container, LoadableTypes, TypesToExclude, Handlers,
	RefsMap = Undefined) Export
	
	CurContainer = Container;
	CurHandlers = Handlers;
	
	FixObjectProcessing = Container.FixState();
	
	If Not CurContainer.ThisIsContinuationOfDownload() And Not CurContainer.IsChildThread() Then
		CommitImportMetadataObjects(LoadableTypes, TypesToExclude);
	EndIf;
	
	CurFlowOfLinkReplacement = DataProcessors.ExportImportDataReferenceReplacementStream.Create();
	CurFlowOfLinkReplacement.Initialize(CurContainer, CurHandlers, RefsMap);
		
	ProcessedDuplicatesOfPredefined = New Map();
	
EndProcedure

Procedure ImportData() Export
	
	PerformLinkReplacement();
	
	If UseMultithreading() Then
		
		ImportJob = ExportImportDataInternal.GetJobOfParallelExportImportData();
		
		InformationRegisters.ExportImportDataThreads.AddRecord(
			ImportJob,
			CurContainer,
			Enums.ExportImportDataThreadTypes.Managing);
		
		ImportProcessingManager = DataProcessors.ExportImportDataInfobaseDataImportManager;
		ImportProcessParameters = ImportProcessingManager.NewParametersOfInformationDatabaseDataImportProcess(
			CurContainer,
			CurFlowOfLinkReplacement);
		Jobs = ImportProcessingManager.StartDataImportThreads(
			ImportProcessParameters,
			CurContainer.ThreadsCount(),
			ExportImportDataInternal.ParallelExportImportDataThreadType(CurContainer));
		
		ExportImportDataInternal.WaitExportImportDataInThreads(Jobs, ImportProcessParameters);
		
	Else
		
		RunDataImport();
		
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.RecordEndOfProcessingMetadataObjects();
	EndIf;
			
EndProcedure

Procedure ImportDataInThread() Export
	
	ImportJob = ExportImportDataInternal.GetJobOfParallelExportImportData();
	JobID = ImportJob.UUID;
	
	While True Do
		
		GetResult1 = InformationRegisters.ExportImportMetadataObjects.GetObjectToProcessing(
			JobID, True);
		
		If Not GetResult1.HasObjectsToProcessing Then
			Break;
		EndIf;
		
		If GetResult1.Object = Undefined Then
			// We are waiting for the end of loading the data of the previous priority and repeat receiving the object for loading
			CommonCTL.Pause(5);
			Continue;
		EndIf;
		
		ExecuteImportMetadataObject(GetResult1.Object);
		
	EndDo;
	
	InformationRegisters.ExportImportDataThreads.DeleteRecord(JobID);
	
EndProcedure

// Returns: 
//  DataProcessorObject.ExportImportDataReferenceReplacementStream - the current flow of link replacement.
Function CurFlowOfLinkReplacement() Export
	
	Return CurFlowOfLinkReplacement;
	
EndFunction

//@skip-warning EmptyMethod - a feature of the implementation.
//
Procedure Close() Export
	
EndProcedure

#EndRegion

#Region Private

Procedure CommitImportMetadataObjects(LoadableTypes, TypesToExclude)
	
	TypesTable = New ValueTable();
	TypesTable.Columns.Add("Priority", New TypeDescription("Number"));
	TypesTable.Columns.Add("FullName", New TypeDescription("String"));
	TypesTable.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	MessageTemplate = NStr(
		"vi = 'Đang bỏ qua kết nhập dữ liệu của đối tượng metadata %1 vì nó được đưa vào 
		|danh sách đối tượng metadata loại trừ khi kết nhập và kết xuất dữ liệu';
		|ru = 'Загрузка данных объекта метаданных %1 пропущена, т.к. он включен в
		|список объектов метаданных, исключаемых из выгрузки и загрузки данных';
		|en = 'Data import skipped for metadata object %1, as the object is in
		|the list of metadata objects to be excluded from data import and export procedures'; fa = 'Data import skipped for metadata object %1, as the object is in
		|the list of metadata objects to be excluded from data import and export procedures';
		|it = 'Download dei dati dell''oggetto dei metadati%1 non eseguito, poiché esso è incluso nell''
		|elenco degli oggetti dei metadati esclusi da download e upload di dati';
		|pl = 'Pobieranie danych obiektu metadanych %1 jest pomijane, ponieważ znajduje się na
		|liście obiektów metadanych, które mają być wyłączone z pobierania i ładowania danych';
		|tr = '%1 meta veri nesnesinin veri içe aktarması atlandı çünkü Veri Dışa Aktarımı ve İçe Aktarımı işlemlerinin dışında bırakılan
		|meta veri nesneleri listesine dahildir'",
		Common.DefaultLanguageCode());
	LREvent = NStr(
		"vi = 'Kết xuất kết nhập dữ liệu. Đã bỏ qua kết nhập đối tượng';
		|ru = 'Выгрузка загрузка данных. Загрузка объекта пропущена';
		|en = 'Data export and import. Object import skipped'; fa = 'Data export and import. Object import skipped';
		|it = 'Download upload dati. Mancato download oggetto';
		|pl = 'Eksportowanie pobieranie danych. Pominięto pobieranie obiektu';
		|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne içe aktarma atlatıldı'",
		Common.DefaultLanguageCode());
		
	UseMultithreading = UseMultithreading();
	
	For Each MetadataObject In LoadableTypes Do
		
		If TypesToExclude.Find(MetadataObject) <> Undefined Then
			
			WriteLogEvent(
				LREvent,
				EventLogLevel.Information,
				MetadataObject,
				,
				StrTemplate(MessageTemplate, MetadataObject.FullName()));
			
			Continue;
			
		EndIf;
		
		TableRow = TypesTable.Add();
		TableRow.Priority = ExportingMetadataObjectPriority(MetadataObject);
		TableRow.FullName = MetadataObject.FullName();
		
		If UseMultithreading Then
			TableRow.ObjectCount = CurContainer.ObjectsToBeProcessedByMetadataObject(MetadataObject);
		EndIf;
		
	EndDo;
	
	TypesTable.Sort("Priority, ObjectCount DESC, FullName");
	
	CurPriority = Undefined;
	RecordSet = InformationRegisters.ExportImportMetadataObjects.CreateRecordSet();
	
	For Each TableRow In TypesTable Do
		
		If TableRow.Priority <> CurPriority Then
			CurPriority = TableRow.Priority;
			ProcessingProcedure_ = 10000 * TableRow.Priority;
		EndIf;
		
		ProcessingProcedure_ = ProcessingProcedure_ + 1;
		
		SetRecord = RecordSet.Add();
		SetRecord.ProcessingProcedure_ = ProcessingProcedure_;
		SetRecord.MetadataObject = TableRow.FullName;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

Function ExportingMetadataObjectPriority(MetadataObject)
	
	If CommonCTL.IsConstant(MetadataObject) Then
		Priority = 0;
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		If CommonCTL.IsChartOfCharacteristicTypes(MetadataObject) Then
			Priority = 1;
		ElsIf CommonCTL.IsChartOfAccounts(MetadataObject) Then
			Priority = 2;
		ElsIf CommonCTL.IsChartOfCalculationTypes(MetadataObject) Then
			Priority = 3;
		ElsIf CommonCTL.IsCatalog(MetadataObject) Then
			Priority = 4;
		ElsIf CommonCTL.IsExchangePlan(MetadataObject) Then
			Priority = 5;
		Else
			Priority = 6;
		EndIf;
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		Priority = 7;
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then // Recalculations
		Priority = 8;
	ElsIf Metadata.Sequences.Contains(MetadataObject) Then
		Priority = 9;
	Else
		
		MessageText = StrTemplate(
			NStr("vi = 'Không hỗ trợ kết xuất đối tượng metadata %1';
				|ru = 'Выгрузка объекта метаданных не поддерживается %1';
				|en = 'Import of the %1 metadata object is not supported'; fa = 'Import of the %1 metadata object is not supported';
				|it = 'Upload dell''oggetto dei metadati non supportato %1';
				|pl = 'Przesyłanie obiektu metadanych nie jest obsługiwane %1';
				|tr = 'Nesne meta verilerinin dışa aktarımı desteklenmiyor %1'"),
			MetadataObject.FullName());
		
		Raise(MessageText);
		
	EndIf;
	
	Return Priority;
	
EndFunction

Procedure PerformLinkReplacement()
	
	LinkReCreationManager = DataProcessors.ExportImportDataReferenceRegenerationManager.Create();
	LinkReCreationManager.Initialize(CurContainer, CurFlowOfLinkReplacement);
	LinkReCreationManager.ReCreateLinks();
	
	RefsMapManager = DataProcessors.ExportImportDataReferenceMappingManager.Create();
	RefsMapManager.Initialize(CurContainer, CurFlowOfLinkReplacement, CurHandlers);
	RefsMapManager.PerformLinkMatching();
	
	ExportImportDataInternal.FixLinkMatching(CurFlowOfLinkReplacement.RefsMap());
	
EndProcedure

Procedure RunDataImport()
	
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection();
	
	While ObjectSelection.Next() Do
		
		InformationRegisters.ExportImportMetadataObjects.CommitObjectProcessingStart(ObjectSelection);
		ExecuteImportMetadataObject(ObjectSelection);
		
		If Not CurContainer.ClientSessionExists() Then
			CurContainer.AbortProcessOnAbsentClientSession();
		EndIf;
		
	EndDo;
	
EndProcedure

// Load the metadata object.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure ExecuteImportMetadataObject(ObjectSelection)
	
	If FixObjectProcessing Then
		CurContainer.RecordStartOfMetadataObjectProcessing(ObjectSelection.MetadataObject);
	EndIf;
	
	Cancel = False;
	
	MetadataObject = Metadata.FindByFullName(ObjectSelection.MetadataObject);
	HandlersAvailability = CurHandlers.MetadataObjectHandlersAvailability(MetadataObject);
	
	If HandlersAvailability.BeforeImportType Then
		CurHandlers.BeforeImportType(CurContainer, MetadataObject, Cancel);
	EndIf;
	
	If Cancel And FixObjectProcessing Then
		CurContainer.ObjectsAreProcessed(
			CurContainer.ObjectsToBeProcessedByMetadataObject(MetadataObject));
	ElsIf Not Cancel Then
		UploadDataForInformationBaseObject(MetadataObject);		
	EndIf;
	
	If HandlersAvailability.AfterLoadingType Then
		CurHandlers.AfterLoadingType(CurContainer, MetadataObject);
	EndIf;
	
	If FixObjectProcessing Then
		CurContainer.CommitMetadataObjectProcessingEnd(ObjectSelection.MetadataObject);
	EndIf;
	
	InformationRegisters.ExportImportMetadataObjects.DeleteRecord(ObjectSelection);
	
EndProcedure

// Loads all necessary data for the database object.
//
// Parameters:
//	MetadataObject - MetadataObject - the metadata object to load.
//
Procedure UploadDataForInformationBaseObject(Val MetadataObject)
	
	WriteLogEvent(
		NStr("vi = 'Kết xuất kết nhập đối tượng. Kết nhập đối tượng metadata';
			|ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
			|en = 'Data export and import. Metadata object import'; fa = 'Data export and import. Metadata object import';
			|it = 'Download upload dati. Download oggetto metadati';
			|pl = 'Eksportowanie pobieranie danych. Pobieranie obiektu metadanych';
			|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne meta veri içe aktarma.'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		StrTemplate(NStr("vi = 'Bắt đầu kết nhập dữ liệu của đối tượng metadata: %1';
						|ru = 'Начало загрузки данных объекта метаданных: %1';
						|en = 'Starting to import metadata object data: %1'; fa = 'Starting to import metadata object data: %1';
						|it = 'Inizio download dei dati dell''oggetto dei metadati: %1';
						|pl = 'Rozpoczęto pobieranie danych obiektu metadanych: %1';
						|tr = 'Nesne meta veri içe aktarma başlatma:%1'", Common.DefaultLanguageCode()),
			MetadataObject.FullName()));
	
	ObjectCount = 0;
	DeferredSets = New Map;
	ParametersForRecordingChanges = Undefined;

	If Common.IsExchangePlan(MetadataObject) Then

		WriteLogEvent(
			NStr("vi = 'Kết xuất kết nhập đối tượng. Kết nhập đối tượng metadata';
				|ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
				|en = 'Data export and import. Metadata object import'; fa = 'Data export and import. Metadata object import';
				|it = 'Download upload dati. Download oggetto metadati';
				|pl = 'Eksportowanie pobieranie danych. Pobieranie obiektu metadanych';
				|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne meta veri içe aktarma.'", Common.DefaultLanguageCode()),
			EventLogLevel.Information,
			MetadataObject,
			,
			StrTemplate(NStr("vi = 'Xóa dữ liệu của đối tượng metadata: %1';
							|ru = 'Очистка данных объекта метаданных: %1';
							|en = 'Clear metadata object data: %1'; fa = 'Clear metadata object data: %1';
							|it = 'Inizio cancellazione dati dell''oggetto dei metadati: %1';
							|pl = 'Wyczyszczenie danych obiektu metadanych: %1';
							|tr = 'Nesne meta veri temizleme:%1'", Common.DefaultLanguageCode()),
				MetadataObject.FullName()));
		
		SaaSOperations.ClearMetadataObjectData(MetadataObject.FullName(), MetadataObject);
		
	EndIf;
		
	For Each FileDetails In CurContainer.GetFileDescriptionsFromFolder(ExportImportDataInternal.InfobaseData(), MetadataObject.FullName()) Do
		
		CurContainer.UnzipFile(FileDetails);
		
		CurFlowOfLinkReplacement.ReplaceLinksInFile(FileDetails);
		
		ReaderStream = DataProcessors.ExportImportDataInfobaseDataReadingStream.Create();
		ReaderStream.OpenFile(FileDetails.FullName);
				
		While ReaderStream.ReadInformationDatabaseDataObject() Do
			
			Object = ReaderStream.CurrentObject();
			Artifacts = ReaderStream.CurObjectArtifacts();
			
			If ReaderStream.TypeOfCurrentObject() = ExportImportDataInternal.InfobaseData() Then
			
				WriteObjectToInformationBase(Object, Artifacts, DeferredSets, MetadataObject);
				
			ElsIf ReaderStream.TypeOfCurrentObject() = ExportImportDataInternal.InfobaseDataChanges() Then
				
				If ParametersForRecordingChanges = Undefined Then
					
					ParametersForRecordingChanges = ParametersForRecordingChanges(MetadataObject);
					
				EndIf;
				
				If ParametersForRecordingChanges.IsConstant Then
					
					RecordConstantChange(MetadataObject, Object, Artifacts);
					
				ElsIf ParametersForRecordingChanges.IsRefData Then
					
					RecordLinkChange(MetadataObject, Object, Artifacts);
					
				ElsIf ParametersForRecordingChanges.IsRecordSet Then
					
					RecordRecordsetChange(MetadataObject, ParametersForRecordingChanges.FilterFields, Object, Artifacts);
					
				EndIf;
				
			EndIf;
			
			ObjectCount = ObjectCount + 1;
			
		EndDo;
		
		ReaderStream.Close();
		DeleteFiles(FileDetails.FullName);
		
	EndDo;
	
	For Each KeyAndValue In DeferredSets Do
		
		Object = KeyAndValue.Value.Object; // CatalogObject, DocumentObject
		ObjectArtifacts = KeyAndValue.Value.ObjectArtifacts;
		ObjectCount = ObjectCount + 1;
		
		Try
			Object.Write();
		Except
		
			Comment = StrTemplate(
				NStr("vi = 'Đối tượng metadata %1 với tên trình bày ""%2"" không được kết nhập do nguyên nhân: %3';
					|ru = 'Объекта метаданных %1 с представлением ""%2"" не загружен по причине: %3';
					|en = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3'; fa = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3';
					|it = 'Oggetto dei metadati %1 con rappresentazione ""%2"" non scaricato a causa di: %3';
					|pl = 'Obiekt metadanych %1 z widokiem ""%2"" nie został pobrany z powodu: %3';
					|tr = '""%2"" sunumu olan %1 meta veri nesnesi şu nedenle yüklenmedi: %3'", Common.DefaultLanguageCode()),
				MetadataObject.FullName(),
				String(Object),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			// @skip-check module-nstr-camelcase - verification error
			WriteLogEvent(
				NStr("vi = 'Kết xuất kết nhập dữ liệu. Kết nhập đối tượng metadata.Lỗi';
					|ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных.Ошибка';
					|en = 'Data export and import. Metadata object import.Error'; fa = 'Data export and import. Metadata object import.Error';
					|it = 'Download upload dati. Download oggetto metadati.Errore';
					|pl = 'Eksportowanie pobieranie danych. Pobieranie obiektu metadanych. Błąd';
					|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne meta veri içe aktarma.Hata'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				MetadataObject,
				,
				Comment);
			
			Raise Comment;
				
		EndTry;
			
		If HandlersAvailability.AfterImportObject Then
			CurHandlers.AfterImportObject(CurContainer, Object, ObjectArtifacts);
		EndIf;
		
	EndDo;
	
	Comment = StrTemplate(
		NStr("vi = 'Kết thúc kết nhập dữ liệu đối tượng metadata: %1
					|Đã kết nhập %2 đối tượng';
					|ru = 'Окончание загрузки данных объекта метаданных: %1
					|Загружено объектов: %2';
					|en = 'Finish importing metadata object data: %1
					|Objects imported: %2'; fa = 'Finish importing metadata object data: %1
					|Objects imported: %2';
					|it = 'Fine download dei dati dell''oggetto dei metadati: %1
					| Oggetti scaricati: %2';
					|pl = 'Koniec pobierania danych obiektu metadanych: %1
					|Pobrane obiekty: %2';
					|tr = 'Meta veri nesne verileri içe aktarma tamamlandı: %1
					|İçe aktarılan nesneler: %2'", Common.DefaultLanguageCode()),
		MetadataObject.FullName(), 
		ObjectCount);
	WriteLogEvent(
		NStr("vi = 'Kết xuất kết nhập đối tượng. Kết nhập đối tượng metadata';
			|ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных';
			|en = 'Data export and import. Metadata object import'; fa = 'Data export and import. Metadata object import';
			|it = 'Download upload dati. Download oggetto metadati';
			|pl = 'Eksportowanie pobieranie danych. Pobieranie obiektu metadanych';
			|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne meta veri içe aktarma.'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,
		MetadataObject,
		,
		Comment);
	
EndProcedure

Procedure WriteObjectToInformationBase(Object, ObjectArtifacts, DeferredSets, MetadataObject)
	
	SaveObjectToInformationDatabaseInternal(
		Object,
		ObjectArtifacts,
		DeferredSets,
		MetadataObject);
	
	If FixObjectProcessing Then
		CurContainer.ObjectProcessed();	
	EndIf;
		
EndProcedure

Procedure SaveObjectToInformationDatabaseInternal(Object, ObjectArtifacts, DeferredSets, MetadataObject)
	
	Cancel = False;
	
	If HandlersAvailability.BeforeImportObject Then
		CurHandlers.BeforeImportObject(CurContainer, Object, ObjectArtifacts, Cancel);
	EndIf;
	
	If Not Cancel Then
		
		If CommonCTL.IsConstant(MetadataObject) Then
			
			If Not ValueIsFilled(Object.Value) Then
				// Since the constants were previously cleared, rewriting of empty
				// values is not required.
				Return;
			EndIf;
			
		EndIf;
		
		Object.DataExchange.Load = True;
		
		If TypeOf(Object) <> Type("ObjectDeletion") Then
			Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		EndIf;
		
		DuplicatesOfPredefinedItems = FindDuplicatesOfPredefined(MetadataObject, Object);
		
		Try
			
			If ValueIsFilled(DuplicatesOfPredefinedItems) Then
			
				BeginTransaction();
				
				Try
					
					For Each MapItem In DuplicatesOfPredefinedItems Do
						
						DuplicateOfPredefined = MapItem.Key;
						LinksParent = MapItem.Value;
						NewParent = GetLinkToObject(Object);
						
						For Each LinkToDuplicate In LinksParent Do
							SubordinateObject = LinkToDuplicate.GetObject();
							SubordinateObject.Parent = NewParent;
							SubordinateObject.DataExchange.Load = True;
							SubordinateObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							SubordinateObject.Write();
						EndDo;
						
						DuplicateOfPredefinedObject = DuplicateOfPredefined.GetObject();
						DuplicateOfPredefinedObject.DataExchange.Load = True;
						DuplicateOfPredefinedObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
						DuplicateOfPredefinedObject.Delete();
						
					EndDo;
					
					Object.Write();
					
					CommitTransaction();
						
				Except
					RollbackTransaction();
					Raise;
				EndTry;
				
			ElsIf CommonCTL.IsInformationRegister(MetadataObject)
				And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate 
				And MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
				
				Recorder = Object.Filter.Recorder.Value;
				Try
					Object.Write();
					DeferredSets.Delete(Recorder);
				Except
					DeferredSets.Insert(Recorder, New Structure("Object, ObjectArtifacts", Object, ObjectArtifacts));
					Return;
				EndTry;
			
			Else 
				Object.Write();
			EndIf;
			
		Except
			
			LanguageCode = Common.DefaultLanguageCode();
			Comment = StrTemplate(
				NStr("vi = 'Chưa kết nhập đối tượng metadata %1 có tên trình bày ""%2"" do nguyên nhân: %3';
					|ru = 'Объекта метаданных %1 с представлением ""%2"" не загружен по причине: %3';
					|en = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3'; fa = 'Metadata object %1 with presentation ""%2"" is not imported. Reason: %3';
					|it = 'Oggetto dei metadati %1 con rappresentazione ""%2"" non scaricato a causa di: %3';
					|pl = 'Obiekt metadanych %1 z widokiem ""%2"" nie został pobrany z powodu: %3';
					|tr = '""%2"" sunumu olan %1 meta veri nesnesi şu nedenle yüklenmedi: %3'", LanguageCode),
				MetadataObject.FullName(),
				String(Object),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			// @skip-check module-nstr-camelcase - verification error
			WriteLogEvent(
				NStr("vi = 'Kết xuất kết nhập dữ liệu. Kết nhập đối tượng metadata.Lỗi';
					|ru = 'Выгрузка загрузка данных. Загрузка объекта метаданных.Ошибка';
					|en = 'Data export and import. Metadata object import.Error'; fa = 'Data export and import. Metadata object import.Error';
					|it = 'Download upload dati. Download oggetto metadati.Errore';
					|pl = 'Eksportowanie pobieranie danych. Pobieranie obiektu metadanych. Błąd';
					|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne meta veri içe aktarma.Hata'", LanguageCode),
				EventLogLevel.Error,
				MetadataObject,
				,
				Comment);
					
			Raise Comment;
			
		EndTry;
		
	EndIf;
	
	If HandlersAvailability.AfterImportObject Then
		CurHandlers.AfterImportObject(CurContainer, Object, ObjectArtifacts);
	EndIf;
		
EndProcedure

Function ParametersForRecordingChanges(MetadataObject)
	
	Result = New Structure;
	Result.Insert("IsConstant", False);
	Result.Insert("IsRefData", False);
	Result.Insert("IsRecordSet", False);
	Result.Insert("FilterFields", New Array);
	
	If CommonCTL.IsConstant(MetadataObject) Then
		
		Result.IsConstant = True;
		
	ElsIf CommonCTL.IsRefData(MetadataObject) Then
		
		Result.IsRefData = True;
		
	ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
		
		Result.IsRecordSet = True;
		
		If Metadata.InformationRegisters.Contains(MetadataObject)
			And MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
			
			If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
				And MetadataObject.MainFilterOnPeriod Then
				
				Result.FilterFields.Add("Period");
				
			EndIf;
			
			For Each Dimension In MetadataObject.Dimensions Do
				
				If Dimension.MainFilter Then
					
					Result.FilterFields.Add(Dimension.Name);
					
				EndIf;
				
			EndDo;
			
		ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent()) Then
			
			Result.FilterFields.Add("RecalculationObject");
			
		Else
			
			Result.FilterFields.Add("Recorder");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure RecordConstantChange(MetadataObject, Changes, Artifacts)
	
	ExchangePlans.RecordChanges(Changes.Node, MetadataObject);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, MetadataObject);
		
	EndIf;
	
EndProcedure

Procedure RecordLinkChange(MetadataObject, Changes, Artifacts)
	
	ExchangePlans.RecordChanges(Changes.Node, Changes.Ref);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, Changes.Ref);
		
	EndIf;
	
EndProcedure

Procedure RecordRecordsetChange(MetadataObject, FilterFields, Changes, Artifacts)
	
	ObjectManager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	RecordSet = ObjectManager.CreateRecordSet();
	
	For Each FilterField In FilterFields Do
		
		FilterElement = RecordSet.Filter[FilterField]; // FilterItem
		FilterElement.Set(Changes[FilterField]);
		
	EndDo;
	
	ExchangePlans.RecordChanges(Changes.Node, RecordSet);
	
	If ValueIsFilled(Changes.MessageNo) Then
		
		ExchangePlans.SelectChanges(Changes.Node, Changes.MessageNo, RecordSet);
		
	EndIf;
	
EndProcedure

Function UseMultithreading()
	
	If CurContainer.IsChildThread() Then
		Return False;
	EndIf;
	
	Return ExportImportDataInternal.UseMultithreading(CurContainer.ImportParameters());
	
EndFunction

Function FindDuplicatesOfPredefined(MetadataObject, Object)
	
	If TypeOf(Object) = Type("ObjectDeletion")
		Or Not CommonCTL.IsRefDataSupportingPredefinedItems(MetadataObject)
		Or Not Object.Predefined Then
		
		Return Undefined;
		
	EndIf;
	
	FullMetadataObjectName = MetadataObject.FullName();
	PredefinedItemName = Object.PredefinedDataName;
	FullPredefinedItemName = StrTemplate("%1.%2", FullMetadataObjectName, PredefinedItemName);
	
	If ProcessedDuplicatesOfPredefined.Get(FullPredefinedItemName) <> Undefined Then
		Return Undefined;
	EndIf;
	
	ProcessedDuplicatesOfPredefined.Insert(FullPredefinedItemName, True);
	Hierarchical = Not CommonCTL.IsChartOfCalculationTypes(MetadataObject) 
		And (CommonCTL.IsChartOfAccounts(MetadataObject) Or MetadataObject.Hierarchical);
	
	If Hierarchical Then
		
		QueryText = StrReplace(
			"SELECT
			|	ObjectTable.Ref AS Ref,
			|	ISNULL(TableParent.Ref, UNDEFINED) AS LinkParent
			|FROM
			|	&Table AS ObjectTable
			|		LEFT JOIN &Table AS TableParent
			|		ON ObjectTable.Ref = TableParent.Parent
			|WHERE
			|	ObjectTable.PredefinedDataName = &PredefinedItemName
			|	AND ObjectTable.Ref <> &Ref
			|TOTALS BY
			|	Ref",
			"&Table",
		 	FullMetadataObjectName);
		
	Else
		
		QueryText = StrReplace(
			"SELECT
			|	ObjectTable.Ref AS Ref,
			|	UNDEFINED AS LinkParent
			|FROM
			|	&Table AS ObjectTable
			|WHERE 
			|	ObjectTable.PredefinedDataName = &PredefinedItemName
			|	AND ObjectTable.Ref <> &Ref",
			"&Table",
		 	FullMetadataObjectName);
		 
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("PredefinedItemName", PredefinedItemName);
	Query.SetParameter("Ref", GetLinkToObject(Object));
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	DuplicatesOfPredefinedItems = New Map();
	DuplicatesSelection = Result.Select(QueryResultIteration.ByGroups);
	
	While DuplicatesSelection.Next() Do
		
		LinksParent = New Array();
		DuplicatesOfPredefinedItems.Insert(DuplicatesSelection.Ref, LinksParent);
		
		ParentSelection = DuplicatesSelection.Select();
		
		While ParentSelection.Next() Do
			
			If ValueIsFilled(ParentSelection.LinkParent) Then
				LinksParent.Add(ParentSelection.LinkParent);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return DuplicatesOfPredefinedItems;
	
EndFunction

Function GetLinkToObject(Object)
	
	Return ?(Object.IsNew(), Object.GetNewObjectRef(), Object.Ref);
	
EndFunction

#EndRegion

#EndIf
