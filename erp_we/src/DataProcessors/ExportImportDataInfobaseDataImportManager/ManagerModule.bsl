#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Loads data from the information database.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Handlers - CommonModule
//				- DataProcessorManager
//	RefsMap - Map of AnyRef - matching links
// Returns:
//	DataProcessorObject.ExportImportDataReferenceReplacementStream
//
Function DownloadDatabaseData(Container, Handlers, RefsMap = Undefined) Export
	
	LoadableTypes = Container.ImportParameters().LoadableTypes;
	TypesToExclude = ExportImportDataInternalEvents.GetTypesExcludedFromUploadUpload();
	
	DownloadManager = Create();
	DownloadManager.Initialize(
		Container,
		LoadableTypes,
		TypesToExclude,
		Handlers,
		RefsMap);
	DownloadManager.ImportData();
	
	Return DownloadManager.CurFlowOfLinkReplacement();
	
EndFunction

// Upload database data in a stream.
// 
// Parameters:
//  StreamParameters - Structure - see the Parameters property in
//  	Processing Object.Unloaded and unloaded data from the manager and unloaded data from the information database.Start a stream of data uploads
// 
Procedure ImportInfoBaseDataInThread(StreamParameters) Export
	
	Container = DataProcessors.ExportImportDataContainerManager.Create();
	Container.InitializeImportInThread(StreamParameters.Container);
	
	Handlers = DataProcessors.ExportImportDataDataImportHandlersManager.Create();
	Handlers.Initialize();
	
	LoadableTypes = Undefined;
	TypesToExclude = Undefined;
	RefsMap = New Map(StreamParameters.LinkReplacementFlow.RefsMap);
		
	DownloadManager = Create();
	DownloadManager.Initialize(
		Container,
		LoadableTypes,
		TypesToExclude,
		Handlers,
		RefsMap);
	DownloadManager.ImportDataInThread();
	
EndProcedure

// Start data loading streams.
// 
// Parameters:
//  ImportProcessParameters - See NewParametersOfInformationDatabaseDataImportProcess
//  ThreadsCount - Number
//  ThreadTypes - EnumRef.ExportImportDataThreadTypes
// 
// Returns:
//  Array of BackgroundJob - Running data loading tasks
Function StartDataImportThreads(ImportProcessParameters, ThreadsCount = 1, ThreadTypes = Undefined) Export
	
	ThreadsParameters = ExportImportDataInternal.NewExportImportDataThreadsParameters();
	ThreadsParameters.ThisIsDownload = True;
	ThreadsParameters.ThreadsCount = ThreadsCount;
	
	If ValueIsFilled(ThreadTypes) Then
		ThreadsParameters.ThreadTypes = ThreadTypes;
	EndIf;
	
	ThreadsParameters.Parameters.Insert(
		"Container",
		ImportProcessParameters.Container.GetInitialParametersInThread());
	ThreadsParameters.Parameters.Insert(
		"LinkReplacementFlow",
		ImportProcessParameters.LinkReplacementFlow.GetInitialParametersInThread());
	
	Return ExportImportDataInternal.StartDataExportImportThreads(
		ThreadsParameters, ImportProcessParameters.Container);
	
EndFunction

// New parameters of the information database data loading process.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
//  LinkReplacementFlow - DataProcessorObject.ExportImportDataReferenceReplacementStream
// 
// Returns:
//  Structure - New Parameters Of The Information Database Data Upload Process:
// * Container - DataProcessorObject.ExportImportDataContainerManager 
// * LinkReplacementFlow - DataProcessorObject.ExportImportDataReferenceReplacementStream 
Function NewParametersOfInformationDatabaseDataImportProcess(Container, LinkReplacementFlow) Export
	
	ImportProcessParameters = New Structure();
	ImportProcessParameters.Insert("Container", Container);
	ImportProcessParameters.Insert("LinkReplacementFlow", LinkReplacementFlow);
	
	Return ImportProcessParameters;
	
EndFunction

#EndRegion

#EndIf
