
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Uploads data from the information database.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager - Manager 
//		of data upload handlers. 
//	Serializer - XDTOSerializer - an XDTO serializer with type annotation. 
//
Procedure UploadDatabaseData(Container, Handlers, Serializer) Export
	
	ExportProcessParameters = NewInfoBaseDataExportProcessParameters(
		Container, Handlers, Serializer);
	
	CommitExportMetadataObjects(ExportProcessParameters);
	
	If ExportProcessParameters.UseMultithreading Then
		
		ExportsJob = ExportImportDataInternal.GetJobOfParallelExportImportData();
		
		InformationRegisters.ExportImportDataThreads.AddRecord(
			ExportsJob,
			Container,
			Enums.ExportImportDataThreadTypes.Managing);
		
		Jobs = StartDataExportThread(
			ExportProcessParameters,
			Container.ThreadsCount(),
			ExportImportDataInternal.ParallelExportImportDataThreadType(Container));
			
		ExportImportDataInternal.WaitExportImportDataInThreads(Jobs, ExportProcessParameters);
		
	Else
		
		ExportMainData(ExportProcessParameters, ExportProcessParameters.MainNode);
		
	EndIf;
	
	If ExportProcessParameters.AdditionalNode = Undefined Then
		
		// Unloading in exclusive mode
		CompleteUpload(ExportProcessParameters, ExportProcessParameters.MainNode);
				
	Else
		 
		// Unloading objects changed during unloading
		// If there are a lot of objects, then unload without a transaction
		ExportAccumulatedMainData(ExportProcessParameters, ExportProcessParameters.AdditionalNode);
		
		UnloadingInTransactionIsCompleted = False;
		
		For AttemptNumber = 1 To 3 Do
			
			UnloadingInTransactionIsCompleted = CompleteUnloadingInTransaction(
				ExportProcessParameters, 
				ExportProcessParameters.AdditionalNode);
			
			If UnloadingInTransactionIsCompleted Then
				Break;
			EndIf;
			
			CommonCTL.Pause(60);
			
		EndDo;
		
		If Not UnloadingInTransactionIsCompleted Then
			Raise NStr("vi = 'Không thể phong tỏa vùng, chưa thực hiện sao lưu dự phòng.';
						|ru = 'Не удалось заблокировать область, резервная копия не сделана.';
						|en = 'Cannot lock the area. Not backed up.'; fa = 'Cannot lock the area. Not backed up.';
						|it = 'Impossibile bloccare l''area, backup non effettuato.';
						|pl = 'Nie udało się zablokować obszaru, nie zrobiono kopii zapasowej.';
						|tr = 'Alan kilitlenemedi, yedek yapılmadı.'");
		EndIf;
		
	EndIf;
	
	UploadGeneralData(ExportProcessParameters);
	
	ExportProcessParameters.StreamRecordingOfReCreatedLinks.Close();
	ExportProcessParameters.RecordFlowOfMappedLinks.Close();
	
	If Container.FixState() Then
		Container.RecordEndOfProcessingMetadataObjects();	
	EndIf;
	
EndProcedure

// Upload database data in a stream.
// 
// Parameters:
//  StreamParameters - Structure
// 
Procedure ExportInfoBaseDataInThread(StreamParameters) Export
	
	ExportsJob = ExportImportDataInternal.GetJobOfParallelExportImportData();
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeUploadInThread(StreamParameters.Container);
	
	Handlers = DataProcessors.ExportImportDataDataExportHandlersManager.Create();
	Handlers.Initialize(Container);
	
	Serializer = ExportImportDataInternal.XdtoSerializerWithTypeAnnotation();
	
	ExportProcessParameters = NewInfoBaseDataExportProcessParameters(
		Container, Handlers, Serializer, StreamParameters.RecordFlowOfMappedLinks);
	
	ExportMainDataInThread(ExportProcessParameters, StreamParameters.MainNode, ExportsJob);
	
	ExportProcessParameters.StreamRecordingOfReCreatedLinks.Close();
	ExportProcessParameters.RecordFlowOfMappedLinks.Close();
	
	MessageData = New Structure();
	MessageData.Insert(
		"Content",
		Common.ValueTableToArray(ExportProcessParameters.Container.Content()));
	MessageData.Insert(
		"FilesUsed",
		New FixedArray(ExportProcessParameters.Container.FilesUsed()));
	MessageData.Insert(
		"Warnings",
		New FixedArray(ExportProcessParameters.Container.Warnings()));
	MessageData.Insert(
		"DuplicatesOfPredefinedItems",
		Common.ValueToXMLString(ExportProcessParameters.Container.DuplicatesOfPredefinedItems()));
	
	ExportImportDataInternal.SendMessageToParentThread(
		ExportProcessParameters.Container,
		ExportImportDataInternal.StreamMessageMethodName_ExportEnd(),
		MessageData);
	
	While True Do
		
		// We are waiting for the files to be processed by the control thread. Upon End of processing, the control thread will complete this task.
		ExportsJob = ExportsJob.WaitForExecutionCompletion(5);
		
		If Not Container.ClientSessionExists() Then
			Container.AbortProcessOnAbsentClientSession();
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns whether a differential copy is possible
// 
// Returns:
// 	Boolean - LongDesc
Function UnloadingDifferentialCopyIsPossible() Export
	
	Node = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
	
	Return ValueIsFilled(Node);
	
EndFunction

// Start data loading streams.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  ThreadsCount - Number
//  ThreadTypes - EnumRef.ExportImportDataThreadTypes
// 
// Returns:
//  Array of BackgroundJob - Running data upload tasks
Function StartDataExportThread(ExportProcessParameters, ThreadsCount = 1, ThreadTypes = Undefined) Export
	
	ThreadsParameters = ExportImportDataInternal.NewExportImportDataThreadsParameters();
	ThreadsParameters.IsExport = True;
	ThreadsParameters.ThreadsCount = ThreadsCount;
	
	If ValueIsFilled(ThreadTypes) Then
		ThreadsParameters.ThreadTypes = ThreadTypes;
	EndIf;
	
	ThreadsParameters.Parameters.Insert(
		"Container",
		ExportProcessParameters.Container.GetInitialParametersInThread());
	ThreadsParameters.Parameters.Insert(
		"RecordFlowOfMappedLinks",
		ExportProcessParameters.RecordFlowOfMappedLinks.GetInitialParametersInThread());
	ThreadsParameters.Parameters.Insert("MainNode", ExportProcessParameters.MainNode);
	
	Return ExportImportDataInternal.StartDataExportImportThreads(
		ThreadsParameters, ExportProcessParameters.Container);
	
EndFunction

#EndRegion

#Region Private

// New parameters of the process of uploading information database data.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container
//  Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager - Handlers
//  Serializer - XDTOSerializer - XDTO Serializer with Type annotation
//  LinkMappingInitializationParameters - See DataProcessorObject.ExportImportDataMappedReferencesWritingStream.GetInitialParametersInThread
// 
// Returns:
//  Structure - New Parameters Of The Information Database Data Upload Process:
// * Container - DataProcessorObject.ExportImportDataContainerManager 
// * Handlers - DataProcessorObject.ExportImportDataDataExportHandlersManager 
// * Serializer - XDTOSerializer 
// * StreamRecordingOfReCreatedLinks - DataProcessorObject.ExportImportDataRegeneratedReferencesWritingStream
// * RecordFlowOfMappedLinks - DataProcessorObject.ExportImportDataMappedReferencesWritingStream
// * TypesToExport - Array of MetadataObject
// * TypesToExclude - Array of MetadataObject
// * UseMultithreading - Boolean
// * MainNode - ExchangePlanRef.ApplicationsMigration, Undefined -
// * AdditionalNode - ExchangePlanRef.ApplicationsMigration, Undefined -
Function NewInfoBaseDataExportProcessParameters(
	Container, Handlers, Serializer, LinkMappingInitializationParameters = Undefined)
	
	StreamRecordingOfReCreatedLinks = DataProcessors.ExportImportDataRegeneratedReferencesWritingStream.Create();
	StreamRecordingOfReCreatedLinks.Initialize(Container, Serializer);
	
	RecordFlowOfMappedLinks = DataProcessors.ExportImportDataMappedReferencesWritingStream.Create();
	RecordFlowOfMappedLinks.Initialize(Container, Serializer, LinkMappingInitializationParameters);
	
	ExportProcessParameters = New Structure();
	ExportProcessParameters.Insert("Container", Container);
	ExportProcessParameters.Insert("Handlers", Handlers);
	ExportProcessParameters.Insert("Serializer", Serializer);
	ExportProcessParameters.Insert("StreamRecordingOfReCreatedLinks", StreamRecordingOfReCreatedLinks);
	ExportProcessParameters.Insert("RecordFlowOfMappedLinks", RecordFlowOfMappedLinks);
	
	If Container.IsChildThread() Then
		
		ExportProcessParameters.Insert("TypesToExport", New Array());
		ExportProcessParameters.Insert("TypesToExclude", New Array());
		ExportProcessParameters.Insert("UseMultithreading", False);
		ExportProcessParameters.Insert("MainNode", Undefined);
		ExportProcessParameters.Insert("AdditionalNode", Undefined);
		
	Else
		
		ExportingParameters = Container.ExportingParameters();
		TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
		UseMultithreading = ExportImportDataInternal.UseMultithreading(ExportingParameters);
		NodesBC = GetBackupNodes(Container, TypesToExclude);
		
		ExportProcessParameters.Insert("TypesToExport", ExportingParameters.TypesToExport);
		ExportProcessParameters.Insert("TypesToExclude", TypesToExclude);
		ExportProcessParameters.Insert("UseMultithreading", UseMultithreading);
		ExportProcessParameters.Insert("MainNode", NodesBC.MainNode);
		ExportProcessParameters.Insert("AdditionalNode", NodesBC.AdditionalNode);
		
	EndIf;
	
	Return ExportProcessParameters;
	
EndFunction

// Upload basic data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan sub-asset
Procedure ExportMainData(ExportProcessParameters, Node)
	
	ObjectSelection = InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection();
	
	While ObjectSelection.Next() Do
		InformationRegisters.ExportImportMetadataObjects.CommitObjectProcessingStart(ObjectSelection);
		UploadMetadataObjectData(ObjectSelection, ExportProcessParameters, Node);
	EndDo;
	
EndProcedure

// Upload the main data in the stream.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan sub-asset
//  ExportsJob - BackgroundJob - Upload Task
Procedure ExportMainDataInThread(ExportProcessParameters, Node, ExportsJob)
	
	JobID = ExportsJob.UUID;
	
	While True Do
		
		GetResult1 = InformationRegisters.ExportImportMetadataObjects.GetObjectToProcessing(
			JobID);
		
		If Not GetResult1.HasObjectsToProcessing Then
			Break;
		EndIf;
		
		If GetResult1.Object <> Undefined Then
			UploadMetadataObjectData(GetResult1.Object, ExportProcessParameters, Node);
		EndIf;
		
	EndDo;
	
	InformationRegisters.ExportImportDataThreads.DeleteRecord(JobID);
	
EndProcedure

// Upload metadata object data.
// 
// Parameters:
//  ObjectSelection - QueryResultSelection - Object selection
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan sub-asset
Procedure UploadMetadataObjectData(ObjectSelection, ExportProcessParameters, Node)
	
	MetadataObject = Metadata.FindByFullName(ObjectSelection.MetadataObject);
	UploadMetadataObject(ExportProcessParameters, MetadataObject, Node);
	
	InformationRegisters.ExportImportMetadataObjects.DeleteRecord(ObjectSelection);
	
EndProcedure

// Upload the accumulated basic data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  AdditionalNode - ExchangePlanRef.ApplicationsMigration - Exchange plan sub-asset
//  IsExportEnd - Boolean - The End of the upload flag
Procedure ExportAccumulatedMainData(ExportProcessParameters, AdditionalNode, IsExportEnd = False)
	
	ModifiedObjectsData = ApplicationsMigration.GetModifiedObjectsData(AdditionalNode);
	MinimumChangesCount = ?(IsExportEnd, 0, 99);
	
	If ModifiedObjectsData.ObjectCount <= MinimumChangesCount Then
		Return;
	EndIf;
	
	CheckAndRecordExportedObjectsTable(
		ModifiedObjectsData.ObjectsTable,
		ExportProcessParameters.TypesToExclude);
	
	If ExportProcessParameters.Container.FixState() Then
		ExportProcessParameters.Container.AddTotalNumberOfObjects(
			ModifiedObjectsData.ObjectsTable.Total("ObjectCount"));
	EndIf;
	
	ExportMainData(ExportProcessParameters, AdditionalNode);
	
	If Not IsExportEnd Then
		ExchangePlans.DeleteChangeRecords(AdditionalNode, 1);
	EndIf;
	
EndProcedure

// Record the uploaded metadata objects.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
Procedure CommitExportMetadataObjects(ExportProcessParameters)
	
	ObjectsTable = New ValueTable();
	ObjectsTable.Columns.Add("FullName", New TypeDescription("String"));
	ObjectsTable.Columns.Add("ObjectCount", New TypeDescription("Number"));
	
	For Each MetadataObject In ExportProcessParameters.TypesToExport Do
		
		If MetadataObjectExcludedFromExport(MetadataObject, ExportProcessParameters.TypesToExclude) Then
			Continue;
		EndIf;
		
		TableRow = ObjectsTable.Add();
		TableRow.FullName = MetadataObject.FullName();
		
		If ExportProcessParameters.UseMultithreading Then
			TableRow.ObjectCount
				= ExportProcessParameters.Container.ObjectsToBeProcessedByMetadataObject(MetadataObject);
		EndIf;
		
	EndDo;
	
	RecordExportObjectsTable(ObjectsTable);
		
EndProcedure

// Check and record the table of unloaded objects.
// 
// Parameters:
//  ObjectsTable - ValueTable - Table of objects:
// * FullName - String - full name of the metadata object
// * ObjectCount - Number - Number of objects
//  TypesToExclude - FixedArray of MetadataObject - Excluded types
Procedure CheckAndRecordExportedObjectsTable(ObjectsTable, TypesToExclude)
	
	RowIndex = ObjectsTable.Count() - 1;
	
	While RowIndex >= 0 Do
		
		TableRow = ObjectsTable[RowIndex];
		MetadataObject = Metadata.FindByFullName(TableRow.FullName);
		
		If MetadataObjectExcludedFromExport(MetadataObject, TypesToExclude) Then
			ObjectsTable.Delete(RowIndex);
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	RecordExportObjectsTable(ObjectsTable);
	
EndProcedure

// Write a table of unloaded objects.
// 
// Parameters:
//  ObjectsTable - ValueTable - Table of objects:
// * FullName - String - full name of the metadata object
// * ObjectCount - Number - Number of objects
Procedure RecordExportObjectsTable(ObjectsTable)
	
	If Not ValueIsFilled(ObjectsTable) Then
		Return;
	EndIf;
	
	ObjectsTable.Sort("ObjectCount DESC, FullName");
	
	ProcessingProcedure_ = 0;
	RecordSet = InformationRegisters.ExportImportMetadataObjects.CreateRecordSet();
	
	For Each TableRow In ObjectsTable Do
		
		ProcessingProcedure_ = ProcessingProcedure_ + 1;
		
		SetRecord = RecordSet.Add();
		SetRecord.ProcessingProcedure_ = ProcessingProcedure_;
		SetRecord.MetadataObject = TableRow.FullName;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

// Get backup nodes.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager - Container
//  TypesToExclude - FixedArray of MetadataObject - Excluded types
// 
// Returns:
//  Structure - Get Backup Nodes:
// * MainNode - ExchangePlanRef.ApplicationsMigration, Undefined - Main Node
// * AdditionalNode - ExchangePlanRef.ApplicationsMigration, Undefined - Additional Node
Function GetBackupNodes(Container, TypesToExclude)
	
	// Unloading using the exchange plan:
	//   - in monopoly mode, it is unloaded in one stage
	//   - without monopoly mode: first, all data is unloaded, then from an additional node.
	
	If Container.ThisIsBackup() And Not Container.UnloadDifferentialCopy() Then
		
		Node = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
		UseDifferentialBackup
			= Constants.UseDifferentialBackup.Get();
		
		If ValueIsFilled(Node) Then
			
			BeginTransaction();
			
			Try
				
				BlockAllUnloadedObjects(TypesToExclude, Container);
				
				ExchangePlans.DeleteChangeRecords(Node);
				
				If Not UseDifferentialBackup Then
					
					ObjectNode = Node.GetObject();
					ObjectNode.DataExchange.Load = True;
					ObjectNode.Delete();
					
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				Raise;
				
			EndTry;
			
		ElsIf UseDifferentialBackup Then
			 
			ObjectNode = ExchangePlans.ApplicationsMigration.CreateNode();
			ObjectNode.Code = MainNodeCode();
			ObjectNode.Description = NStr(
				"vi = 'Sao lưu dự phòng (nút chính)';
				|ru = 'Резервное копирование (основной узел)';
				|en = 'Backup (master node)'; fa = 'Backup (master node)';
				|it = 'Backup (nodo principale)';
				|pl = 'Kopiowanie zapasowe (węzeł podstawowy)';
				|tr = 'Yedekleme (ana düğüm)'",
				Common.DefaultLanguageCode());
			ObjectNode.Write();
			
		EndIf;
		
	EndIf;
	
	AdditionalNode = Undefined;
	
	If Not SaaSOperations.MonopolyModeIsSet() Then
		
		// Before unloading, you need to create an additional node to register all the objects 
		// that have changed during unloading
		Block = New DataLock();
		LockItem = Block.Add("ExchangePlan.ApplicationsMigration");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Code", AdditionalNodeCode());
		
		BeginTransaction();
		
		Try
			
			Block.Lock();
			
			AdditionalNode = ExchangePlans.ApplicationsMigration.FindByCode(AdditionalNodeCode());
			
			If ValueIsFilled(AdditionalNode) Then
				
				// So it's left over from the last time			
				BlockAllUnloadedObjects(TypesToExclude, Container);
				ExchangePlans.DeleteChangeRecords(AdditionalNode);
				
			Else
				
				ObjectNode = ExchangePlans.ApplicationsMigration.CreateNode();
				ObjectNode.Code = AdditionalNodeCode();
				ObjectNode.Description = NStr(
					"vi = 'Sao lưu dự phòng (nút bổ sung)';
					|ru = 'Резервное копирование (дополнительный узел)';
					|en = 'Backup (additional node)'; fa = 'Backup (additional node)';
					|it = 'Backup (nodo supplementare)';
					|pl = 'Kopiowanie zapasowe (węzeł dodatkowy)';
					|tr = 'Yedekleme (ek düğüm)'",
					Common.DefaultLanguageCode());
				ObjectNode.Write();
				
				AdditionalNode = ObjectNode.Ref;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			Raise;
			
		EndTry;
		
		Try
			LockDataForEdit(AdditionalNode);
		Except
			Raise NStr("vi = 'Không thể khởi động kết xuất dữ liệu, một nhiệm vụ khác cũng đang thực hiện kết xuất.
				|Hãy chờ đến khi kết thúc thực hiện hoặc buộc kết thúc phiên làm việc.';
				|ru = 'Не удалось запустить выгрузку данных, выгрузка уже выполняется другим заданием.
				|Дождитесь его завершения или принудительно завершите сеанс.';
				|en = 'Cannot start data export because another export job is currently in progress.
				|Please wait for the current job to complete or forcefully close the session.'; fa = 'Cannot start data export because another export job is currently in progress.
				|Please wait for the current job to complete or forcefully close the session.';
				|it = 'Non è stato possibile avviare l''upload dei dati, upload già in corso da parte di un altro compito.
				|Attendere il completamento o interrompere la sessione.';
				|pl = 'Nie udało się uruchomić eksportu danych, eksport jest już wykonywane przez inne zadanie.
				|Doczekaj się go zakończenia lub wymuszenia zakończenia sesji.';
				|tr = 'Veriler içe aktarılamadı, içe aktarma başka bir görev tarafından devam etmekte.
				|Lütfen tamamlanana kadar bekleyin veya oturumu kapatın.'")
				+ Chars.LF + CloudTechnology.DetailedErrorText(ErrorInfo());
		EndTry;
		
	EndIf;
	
	MainNode = Undefined; // The sub-asset is not used for a full copy
	
	If Container.UnloadDifferentialCopy() Then
		MainNode = ExchangePlans.ApplicationsMigration.FindByCode(MainNodeCode());
	EndIf;
	
	NodesBC = New Structure();
	NodesBC.Insert("MainNode", MainNode);
	NodesBC.Insert("AdditionalNode", AdditionalNode);
	
	Return NodesBC;

EndFunction

// The metadata object is excluded from the upload.
// 
// Parameters:
//  MetadataObject - MetadataObject - metadata object
//  TypesToExclude - Array of MetadataObject - Excluded types
// 
// Returns:
//  Boolean - Metadata Object Excluded From Upload
Function MetadataObjectExcludedFromExport(MetadataObject, TypesToExclude)
	
	If MetadataObject = Metadata.Catalogs.Users
		Or Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return True;
	EndIf;
	
	If ThisIsExcludedType(TypesToExclude, MetadataObject) Then
		Return True;
	EndIf;
	
	// If the object was added by an extension and is not included in the Application Migration plan, then
	// it is necessary to upload data at the End of the upload, after the exclusive mode is set
	If Not ExclusiveMode()
		And MetadataObject.ConfigurationExtension() <> Undefined
		And Not Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject) Then
		Return True;	
	EndIf;
	
	Return False;
	
EndFunction

// Upload general data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
Procedure UploadGeneralData(ExportProcessParameters)
	
	TypesToExport = ExportProcessParameters.Container.ExportingParameters().UnloadedTypesOfSharedData;
	
	For Each MetadataObject In TypesToExport Do
		
		If ThisIsExcludedType(ExportProcessParameters.TypesToExclude, MetadataObject) Then
			Continue;
		EndIf;
		
		UploadMetadataObject(ExportProcessParameters, MetadataObject);
		
	EndDo;
	
EndProcedure

// Upload the accumulated basic data.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  AdditionalNode - ExchangePlanRef.ApplicationsMigration, Undefined - Exchange plan sub-asset
Function CompleteUnloadingInTransaction(ExportProcessParameters, AdditionalNode)
	
	NotifyUsersAboutExportEnd();
	
	BeginTransaction();
	
	Try
		
		Try
			
			BlockAllUnloadedObjects(
				ExportProcessParameters.TypesToExclude,
				ExportProcessParameters.Container);
			
		Except
			
			RollbackTransaction();
			Return False;
			
		EndTry;
		
		ExportAccumulatedMainData(ExportProcessParameters, AdditionalNode, True);
		CompleteUpload(ExportProcessParameters, AdditionalNode);
			
		AdditionalNode.GetObject().Delete();
					
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return True;
	
EndFunction

Procedure NotifyUsersAboutExportEnd()
	
	If Not Common.DataSeparationEnabled()
		Or Metadata.CommonModules.Find("UsersNotificationCTL") = Undefined Then
		Return;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		Return;
	EndIf;
	
	CurrentInfobaseUser = InfoBaseUsers.CurrentUser();
	CurrentUserID = Undefined;
	 
	If CurrentInfobaseUser <> Undefined Then
		CurrentUserID = CurrentInfobaseUser.UUID;
	EndIf;
	
	SessionSeparatorValue = SaaSOperations.SessionSeparatorValue();
	InteractiveApplicationNames = CommonCTL.InteractiveApplicationNames();
	
	UserNotification = New Structure();
	UserNotification.Insert("NotificationKind", "WarningAboutBlockingWork");
	UserNotification.Insert("JobID", String(BackgroundJob.UUID));
	
	Notifications = New Array();
	
	For Each Session In GetInfoBaseSessions() Do
		
		SessionUser = Session.User;
		
		If SessionUser = Undefined 
			Or SessionUser.UUID = CurrentUserID Then
			Continue;
		EndIf;
		
		If InteractiveApplicationNames.Find(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
			
		Notification = New Structure();
		Notification.Insert("DataArea", SessionSeparatorValue);
		Notification.Insert("UserName", Session.User.Name);
		Notification.Insert("SessionNumber", Session.SessionNumber);
		Notification.Insert("UserNotification", UserNotification);
		
		Notifications.Add(Notification);

	EndDo;
	
	If ValueIsFilled(Notifications) Then
		
		ModuleUsersNotificationCTL = Common.CommonModule("UsersNotificationCTL");
		ModuleUsersNotificationCTL.DeliverAlerts(Notifications);
		
		CommonCTL.Pause(30);
		
	EndIf;
	
EndProcedure

Procedure CompleteUpload(ExportProcessParameters, Node)
	
	MetadataObject_Users = Metadata.Catalogs.Users;
	UploadExtensionData = ValueIsFilled(Node);
	
	For Each MetadataObject In ExportProcessParameters.TypesToExport Do
		
		If ThisIsExcludedType(ExportProcessParameters.TypesToExclude, MetadataObject) Then
			Continue;
		EndIf;
		
		If CommonCTL.IsSequenceRecordSet(MetadataObject) Then
			
			ExportImportSequencesBoundaryData.BeforeUnloadingType(
				ExportProcessParameters.Container,
				ExportProcessParameters.Serializer,
				MetadataObject,
				False);
				
			Continue;
			
		EndIf;
		
		ExportMetadataObject = MetadataObject = MetadataObject_Users
			Or Metadata.ExchangePlans.Contains(MetadataObject);
			
		If Not ExportMetadataObject And UploadExtensionData Then
			ExportMetadataObject = MetadataObject.ConfigurationExtension() <> Undefined
				And Not Metadata.ExchangePlans.ApplicationsMigration.Content.Contains(MetadataObject);
		EndIf;
		
		If ExportMetadataObject Then
			UploadMetadataObject(ExportProcessParameters, MetadataObject);
		EndIf;
		
	EndDo;
	
EndProcedure

Function MainNodeCode()
	
	Return "c191c628-b094-11ea-a48c-0242ac130016";
		
EndFunction

Function AdditionalNodeCode()
	
	Return "974d5c6d-2d7e-4067-9614-dac005823e0e";
		
EndFunction

Function ThisIsExcludedType(TypesToExclude, MetadataObject)
	
	If TypesToExclude.Find(MetadataObject) = Undefined Then
		Return False;
	EndIf;
	
	Event = NStr(
		"vi = 'Kết xuất kết nhập dữ liệu. Đã bỏ qua kết xuất đối tượng';
		|ru = 'Выгрузка загрузка данных. Выгрузка объекта пропущена';
		|en = 'Data export and import. Object export skipped'; fa = 'Data export and import. Object export skipped';
		|it = 'Upload download dati. Mancato upload oggetto';
		|pl = 'Eksportowanie pobieranie danych. Pominięto eksportowanie obiektu';
		|tr = 'Veri Dışa Aktarımı ve İçe Aktarımı.Nesne dışa aktarma atlatıldı'",
		Common.DefaultLanguageCode());
	Comment = StrTemplate(
		NStr("vi = 'Đã bỏ qua kết xuất dữ liệu của đối tượng metadata %1 vì nó được đưa vào 
			 |danh sách các đối tượng metadata được loại trừ khi kết nhập và kết xuất dữ liệu';
			 |ru = 'Выгрузка данных объекта метаданных %1 пропущена, т.к. он включен в
			 |список объектов метаданных, исключаемых из выгрузки и загрузки данных';
			 |en = 'Data export skipped for metadata object %1, as the object is in
			 |the list of metadata objects to be excluded from data import and export procedures'; fa = 'Data export skipped for metadata object %1, as the object is in
			 |the list of metadata objects to be excluded from data import and export procedures';
			 |it = 'Upload dei dati dell''oggetto dei metadati %1 non eseguito, poiché esso è incluso nell''
			 |elenco degli oggetti dei metadati esclusi da download e upload di dati';
			 |pl = 'Przesyłanie danych obiektu metadanych %1 jest pomijane, ponieważ znajduje się na
			 |liście obiektów metadanych, które mają być wyłączone z pobierania i ładowania danych';
			 |tr = '%1 meta veri nesnesinin veri dışa aktarması atlandı çünkü Veri Dışa Aktarımı ve İçe Aktarımı işlemlerinin dışında bırakılan
			 |meta veri nesneleri listesine dahildir'"),
		MetadataObject.FullName());
	
	WriteLogEvent(Event, EventLogLevel.Information, MetadataObject, , Comment);
		
	Return True;
	
EndFunction

// Upload a metadata object.
// 
// Parameters:
//  ExportProcessParameters - See NewInfoBaseDataExportProcessParameters
//  MetadataObject - MetadataObject - The metadata object being uploaded
//  Node - ExchangePlanRef.ApplicationsMigration, Undefined - Node
Procedure UploadMetadataObject(ExportProcessParameters, MetadataObject, Node = Undefined)
			
	ObjectExportManager = Create();
	
	ObjectExportManager.Initialize(
		ExportProcessParameters.Container,
		MetadataObject,
		Node,
		ExportProcessParameters.Handlers,
		ExportProcessParameters.Serializer,
		ExportProcessParameters.StreamRecordingOfReCreatedLinks,
		ExportProcessParameters.RecordFlowOfMappedLinks);
	
	ObjectExportManager.ExportData();
	
	ObjectExportManager.Close();
	
EndProcedure

Procedure BlockAllUnloadedObjects(TypesToExclude, Container)
	
	Block = New DataLock();
	For Each MetadataObject In Container.ExportingParameters().TypesToExport Do
		If TypesToExclude.Find(MetadataObject) = Undefined Then
			If SaaSOperations.ThisIsFullNameOfRecalculation(MetadataObject.FullName()) Then
				LockSpaceByParts = New Array;
				LockSpaceByParts.Add("Recalculation");
				LockSpaceByParts.Add(MetadataObject.Name);
				LockSpaceByParts.Add("RecordSet");
				Block.Add(StrConcat(LockSpaceByParts, "."));
			Else
				Block.Add(MetadataObject.FullName());
			EndIf;
		EndIf;
	EndDo;
	//@skip-check lock-out-of-try
	Block.Lock();
	
EndProcedure

#EndRegion

#EndIf
