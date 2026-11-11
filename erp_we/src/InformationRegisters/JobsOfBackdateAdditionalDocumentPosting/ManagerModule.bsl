#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region JobGeneration

// Creating tasks in a non-operational queue.
// Called when writing a set of register entries.
// 
// Parameters:
//  RegisterManager - AccumulationRegisterManager, InformationRegisterManager - Manager of the recorded register
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateJobs(RegisterManager, KindsOfTasks, RecordSet, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export
	
	If KindsOfTasks.Count() = 0 Then
		Return;
	EndIf;

	DataForCreatingTasks = RegisterManager.DataForFormationOfTasksForNonOperationalDocumentVerification(
		RecordSet, KindsOfTasks, TempTablesManager, DataForRegisteringTasks);

	If DataForCreatingTasks.Count() > 0 Then

		CreateTasksBasedOnDataFromValueTable(DataForCreatingTasks);

	EndIf;

EndProcedure

// Creating non-operational queue jobs based on temporary table data.
// Called when writing a set of register entries.
// 
// Parameters:
//  RegisterManager - AccumulationRegisterManager, InformationRegisterManager - Manager of the recorded register
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  A set of records is a register of a set of records, a register of a set of records is a recordable set of records of the source register.
//  TempTablesManager - TempTablesManager - The data from the temporary tables will be used when creating new tasks.
//  TableName - String - Name of the table in the Temporary Table Manager
//
Procedure CreateTasksBasedOnTemporaryTableData(RegisterManager, KindsOfTasks, TempTablesManager, TableName) Export
	
	If KindsOfTasks.Count() = 0 Then
		Return;
	EndIf;

	DataForCreatingTasks = RegisterManager.DataForFormationOfTasksForNonOperationalAdditionalVerificationOfDocumentsAccordingToTTData(
		TempTablesManager, TableName, KindsOfTasks);

	If DataForCreatingTasks.Count() > 0 Then

		Jobs = CreateRecordSet();

		For Each CurrentData In DataForCreatingTasks Do
				
			If TypeOf(CurrentData.Document) = Type("DocumentRef.RegisterAdjustment") Then
				Continue;
			EndIf;
			
			NewJob = Jobs.Add();
			FillPropertyValues(NewJob, CurrentData);
			NewJob.RecordID = New UUID;

		EndDo;
		
		SetPrivilegedMode(True);
		Jobs.Write(False);
		SetPrivilegedMode(False);

	EndIf;

EndProcedure

// Create tasks when exchanging RIB data.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
//
Procedure CreateTasksWhenExchangingData(RecordSet, KindsOfTasks, TempTablesManager = Undefined,
	DataForRegisteringTasks = Undefined) Export

	RegisterMetadata = RecordSet.Metadata();
	RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());

	CreateJobs(RegisterManager, KindsOfTasks, RecordSet, TempTablesManager, DataForRegisteringTasks);
		
EndProcedure

// Creating tasks based on the data from the passed table of values.
// 
// Parameters:
//  TaskGenerationTable - See TaskGenerationTable
Procedure CreateTasksBasedOnDataFromValueTable(TaskGenerationTable) Export

	Jobs = CreateRecordSet();

	For Each CurrentData In TaskGenerationTable Do

		If TypeOf(CurrentData.Document) = Type("DocumentRef.RegisterAdjustment") Then
			Continue;
		EndIf;

		NewJob = Jobs.Add();
		NewJob.TaskPeriod = CurrentData.TaskPeriod;
		NewJob.Organization = CurrentData.Organization;
		NewJob.JobKind = CurrentData.JobKind;
		NewJob.Document = CurrentData.Document;
		NewJob.RecordID = New UUID;

	EndDo;

	SetPrivilegedMode(True);
	Jobs.Write(False);
	SetPrivilegedMode(False);

EndProcedure

// A data table for generating tasks for non-operational document verification.
// 
// Returns:
//  ValueTable - A data table for generating tasks for non-operational document verification:
// * Organization - CatalogRef.Companies - The organization for which the task will be generated
// * TaskPeriod - Date - the period of the task
// * Document - DocumentRef - Link to the document that the task is generated from
// * JobKind - CatalogRef.BackdateJobKinds - Link to the task type
//
Function TaskGenerationTable() Export

	Table = New ValueTable;
	Table.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	Table.Columns.Add("TaskPeriod", Common.DateTypeDetails(DateFractions.DateTime));
	Table.Columns.Add("Document", Documents.AllRefsType());
	Table.Columns.Add("JobKind", New TypeDescription("CatalogRef.BackdateJobKinds"));
	Table.Indexes.Add("Organization, TaskPeriod, Document, JobKind");

	Return Table;

EndFunction

// Data for the formation of tasks to reflect the RegisteredRecords of the management balance sheet.
//  
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of tasks for registration
// 
// Returns:
//  ValueTable - Data for the formation of tasks a reflection of the Registered Records of the management balance sheet:
// * Organization - CatalogRef.Companies - The organization for which the task will be generated
// * TaskPeriod - Date - the period of the task
// * Document - DocumentRef - Link to the document (registrar) that the task is generated from
// * JobKind - CatalogRef.BackdateJobKinds - Type of task
//
Function TaskFormationTableIsReflectedInManagementBalanceSheet(RecordSet, KindsOfTasks) Export
	
	DataTable = TaskGenerationTable();
	
	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) <> Undefined Then

		DataForCreatingTasks = RecordSet.Unload( , "Period, Organization, Recorder");
		DataForCreatingTasks.GroupBy("Period, Organization, Recorder");

		DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();

		For Each CurrentTypeOfTask In KindsOfTasks Do

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then

				For Each Record In DataForCreatingTasks Do

					NewRow = DataTable.Add();
					NewRow.Organization = Record.Organization;
					NewRow.TaskPeriod = Record.Period;
					NewRow.Document = Record.Recorder;
					NewRow.JobKind = CurrentTypeOfTask;

				EndDo;

			EndIf;
			
		EndDo;
		
	EndIf;

	Return DataTable;
	
EndFunction

#EndRegion

#Region DataProcessing

// Retrieves data from calculation granules for multithreaded background processing.
// 
// Parameters:
//  ThreadFormationStructure - See BackdateJobQueue.StructureOfFormationOfDataPortions
//  FreeThreadsCount - Number - Number of free threads
// 
// Returns:
//  ValueTable - Data For Multithreaded Background Processing:
// * Document - DocumentRef - Link to the document to be processed
// * Batch - Number - Portion Number
Function DataForMultithreadedBackgroundProcessing(ThreadFormationStructure, FreeThreadsCount) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentsForProcessing_.Document AS Document
	|INTO TTDocumentsForProcessing
	|FROM
	|	&DocumentsTable AS DocumentsForProcessing_
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1000
	|	DocumentsForProcessing_.Document AS Document,
	|	MIN(DocumentAssignments.TaskPeriod) AS TaskPeriod
	|FROM
	|	TTDocumentsForProcessing AS DocumentsForProcessing_
	|		INNER JOIN InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS DocumentAssignments
	|		ON DocumentAssignments.JobKind = &JobKind
	|		AND DocumentsForProcessing_.Document = DocumentAssignments.Document
	|GROUP BY
	|	DocumentsForProcessing_.Document
	|
	|ORDER BY
	|	TaskPeriod";
	
	Query.SetParameter("DocumentsTable", ThreadFormationStructure.DocumentsTable);
	Query.SetParameter("JobKind", ThreadFormationStructure.JobKind);

	Query.Text = StrReplace(Query.Text, "1000", Format(FreeThreadsCount
		* ThreadFormationStructure.MaximumBatch, "NZ=0; NG=0"));
	
	SetPrivilegedMode(True);
	DocumentsForProcessing_ = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	TableOfPortionsOfDocumentsForProcessing = TableOfCalculationGranules();
	TableOfPortionsOfDocumentsForProcessing.Columns.Add("Batch", Common.TypeDescriptionNumber(10, 0));
	TableOfPortionsOfDocumentsForProcessing.Indexes.Add("Batch");

	CurPortionSize = 0;
	ProcessingProcedure_ = 1;

	While DocumentsForProcessing_.Next() Do

		NewRow = TableOfPortionsOfDocumentsForProcessing.Add();
		FillPropertyValues(NewRow, DocumentsForProcessing_);

		If CurPortionSize >= ThreadFormationStructure.MaximumBatch Then

			ProcessingProcedure_ = ProcessingProcedure_ + 1;
			CurPortionSize = 0;

		EndIf;

		NewRow.Batch = ProcessingProcedure_;
		CurPortionSize = CurPortionSize + 1;

	EndDo;

	Return TableOfPortionsOfDocumentsForProcessing;
	
EndFunction

// To process a portion of calculation granules.
// 
// Parameters:
//  DataParameters - See BackdateJobQueue.DataPortionProcessingParameters
//
Procedure PerformPortionProcessing(DataParameters) Export

	If DataParameters.DataPortion.Count() = 0 Then
		Return;
	EndIf;
	
	RequestingTaskIds = New Query;
	RequestingTaskIds.Text = "
	|SELECT
	|	DocumentsForProcessing_.Document AS Document
	|INTO TTDocumentsForProcessing
	|FROM
	|	&TableDocumentsForProcessing AS DocumentsForProcessing_
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentsForProcessing.Document AS Document,
	|	JobsOfBackdateAdditionalDocumentPosting.RecordID AS JobID,
	|	JobsOfBackdateAdditionalDocumentPosting.CompletedWithAnError AS CompletedWithAnError
	|FROM
	|	TTDocumentsForProcessing AS TTDocumentsForProcessing
	|		INNER JOIN InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS
	|			JobsOfBackdateAdditionalDocumentPosting
	|		ON TTDocumentsForProcessing.Document = JobsOfBackdateAdditionalDocumentPosting.Document
	|		AND JobsOfBackdateAdditionalDocumentPosting.JobKind = &JobKind";

	RequestingTaskIds.SetParameter("TableDocumentsForProcessing", DataParameters.DataPortion);
	RequestingTaskIds.SetParameter("JobKind", DataParameters.JobKind);
	SetPrivilegedMode(True);
	IdsOfDocumentTasks = RequestingTaskIds.Execute().Unload();
	SetPrivilegedMode(False);
	IdsOfDocumentTasks.Indexes.Add("Document");
	IdsOfDocumentTasks.Indexes.Add("CompletedWithAnError");
	
	SelectionOfTasksWithoutErrors = New Structure("CompletedWithAnError", False);
	
	If Not Common.FileInfobase() And Not DataParameters.CompletingTasksInTransaction Then
	
	#Region BlockingQueueRegisterEntriesByDocumentList

		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.JobsOfBackdateAdditionalDocumentPosting");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = IdsOfDocumentTasks.Copy(SelectionOfTasksWithoutErrors);
		LockItem.UseFromDataSource("RecordID", "JobID");

		PortionOfDocumentsProcessedSuccessfully = True;

		BeginTransaction();

		Try

			Block.Lock();

			DocumentsList = DataParameters.DataPortion.UnloadColumn("Document");

			SetPrivilegedMode(True);

			ParametersOfDocumentProcessing = ParametersOfDocumentProcessing(DataParameters.JobKind,
				DocumentsList);

			For Each DataForCalculation In DataParameters.DataPortion Do
				PerformDocumentProcessing(DataParameters.JobKind, DataForCalculation.Document,
					ParametersOfDocumentProcessing);
			EndDo;

			BackdateJobQueue.DeleteQueueTasks(DataParameters.QueueRegisterName,
				IdsOfDocumentTasks.UnloadColumn("JobID"));

			SetPrivilegedMode(False);

			CommitTransaction();

		Except

			RollbackTransaction();

			PortionOfDocumentsProcessedSuccessfully = False;

		EndTry;

		If PortionOfDocumentsProcessedSuccessfully Then
			DataParameters.DataPortion.Clear();
			Return;
		EndIf;
	
	#EndRegion
	
	EndIf;
	
	#Region ByDocumentProcessing
	
	ErrorsTable = TableOfCalculationGranules();
	ErrorsTable.Columns.Add("JobKind", New TypeDescription("CatalogRef.BackdateJobKinds"));
	ErrorsTable.Columns.Add("ErrorDescription", New TypeDescription("String"));
	
	QueueRegisterMetadata = Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting;

	TaskSelectionStructure = New Structure("Document");
	
	ProcessedRowsPortionsOfData = New Array;
	ProcessedJobIdsOfDocuments = New Array;
	
	AttemptNumber = 1;
	AttemptsNumber = ?(DataParameters.CompletingTasksInTransaction, 1, 3);
	While AttemptNumber <= AttemptsNumber Do
		
		If DataParameters.DataPortion.Count() = 0 Then
			Break;
		EndIf;
		
		For Each DataForCalculation In DataParameters.DataPortion Do

			DocumentProcessingCompletedSuccessfully = True;
			
			TaskSelectionStructure.Document = DataForCalculation.Document;
			TableOfDocumentIdentifiers = IdsOfDocumentTasks.Copy(TaskSelectionStructure);
			TableOfDocumentIdentifiers.Indexes.Add("CompletedWithAnError");
			
			ListOfTaskIds = TableOfDocumentIdentifiers.UnloadColumn("JobID");
			
			ExceptionReason = "BadData";
			
			BeginTransaction();

			Try
				
				ExceptionReason = "Block";
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.JobsOfBackdateAdditionalDocumentPosting");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.DataSource = TableOfDocumentIdentifiers.Copy(SelectionOfTasksWithoutErrors);
				LockItem.UseFromDataSource("RecordID", "JobID");
				Block.Lock();
				
				ExceptionReason = "BadData";
				
				SetPrivilegedMode(True);
				
				DocumentsList = CommonClientServer.ValueInArray(DataForCalculation.Document);
				ParametersOfDocumentProcessing = ParametersOfDocumentProcessing(DataParameters.JobKind,
					DocumentsList);
				PerformDocumentProcessing(DataParameters.JobKind, DataForCalculation.Document,
					ParametersOfDocumentProcessing);
				
				BackdateJobQueue.DeleteQueueTasks(DataParameters.QueueRegisterName,
					ListOfTaskIds);
					
				SetPrivilegedMode(False);
				
				CommitTransaction();

			Except

				RollbackTransaction();
				
				DocumentProcessingCompletedSuccessfully = False;

				ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				BackdateJobQueue.WriteErrorToEventLog(QueueRegisterMetadata,
					DataParameters.JobKind, ErrorText, DataForCalculation.Document);
				
				If ExceptionReason = "BadData" Or DataParameters.CompletingTasksInTransaction Then
					ErrorRecord = ErrorsTable.Add();
					ErrorRecord.Document = DataForCalculation.Document;
					ErrorRecord.JobKind = DataParameters.JobKind;
					ErrorRecord.ErrorDescription = ErrorText;
				EndIf;
				
			EndTry;
			
			If DocumentProcessingCompletedSuccessfully 
				Or (Not DataParameters.CompletingTasksInTransaction 
					And ExceptionReason = "Block" And AttemptNumber = AttemptsNumber) Then
				ProcessedRowsPortionsOfData.Add(DataForCalculation);
				CommonClientServer.SupplementArray(ProcessedJobIdsOfDocuments,
					ListOfTaskIds);
			EndIf;
			
		EndDo;
		
		If ProcessedRowsPortionsOfData.Count() > 0 Then
			
			For Each DataToDelete_1 In ProcessedRowsPortionsOfData Do
				DataParameters.DataPortion.Delete(DataToDelete_1);
			EndDo;

			ProcessedRowsPortionsOfData.Clear();

		EndIf;
		
		AttemptNumber = AttemptNumber + 1;

	EndDo;
	
	If Not DataParameters.CompletingTasksInTransaction Then
		
		If DataParameters.DataPortion.Count() > 0 Then

			RegisterDataProcessingErrors(CommonClientServer.ArraysDifference(
				IdsOfDocumentTasks.UnloadColumn("JobID"),
				ProcessedJobIdsOfDocuments), ErrorsTable);

		EndIf;
		
	Else
		
		ReportDataProcessingErrors(ErrorsTable);
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Overriding task queue parameters.
// 
// Parameters:
//  QueueName -String - Name Of the Task Queue
// 
// Returns:
//  Structure - Redefining job queue description parameters:
// * RequestParameterTaskType - String - The name of the parameter corresponding to the "Task view" field that will be used when generating query texts.
// It is overridden only if there is no "Task view" field in the task register. 
// The parameter name must be unique among all queue job registers.
// * TaskTypeValue - CatalogRef.BackdateJobKinds - The value that will be substituted in the parameter of the task request.
// The parameter is filled in only if there is no "Task view" field in the task register.
// * RequestParameterQueueNumber - String - The name of the parameter corresponding to the "Number field" that will be used when generating query texts.
// Redefined only if there is no "Task view" field in the task register.
// The parameter name must be unique among all queue job registers.
// * QueueNumberValue - Number - The value that will be substituted in the parametersprosanumeror.
// * QueryTextCalculationGranulesInProcessing - String - The Query Text that will be used to generate a temporary table with task calculation granules.
// The fields to be selected must correspond to the columns of the table of values obtained as a result of calling the Calculation tablegranul function of the Task register manager module.
// The name of the temporary table must be unique among all queue job registers.
// * QueryTextExcludedDocuments - String - The text of the request, the result of which gets a list of documents for which calculation granules are processed.
// The text of the request is generated based on the text of the request granulareadcounts in processing.
// * ProcessedGranulesTableName - String - The name of the query parameter whose value is a table of values with data of processed pellets.
// The table name must be unique among all queue job registers.
//
Function DescriptionOfQueueParameters(QueueName) Export
	
	QueueDescription = BackdateJobQueue.StructureOfDescriptionOfQueueParameters();
	
	#Region QueryTextCalculationGranulesInProcessing
	QueryTextCalculationGranulesInProcessing = "
	|SELECT DISTINCT
	|	ProcessedGranules.Document AS Document,
	|	ProcessedGranules.JobKind AS JobKind
	|INTO TTProcessedGranules
	|FROM
	|	&ProcessedGranules AS ProcessedGranules
	|
	|INDEX BY
	|	Document";
	
	QueryTextCalculationGranulesInProcessing = StrReplace(QueryTextCalculationGranulesInProcessing, "TTProcessedGranules", "TT" + QueueName);
	QueryTextCalculationGranulesInProcessing = StrReplace(QueryTextCalculationGranulesInProcessing, "&ProcessedGranules", "&ProcessedGranules" + QueueName);
	QueueDescription.Insert("QueryTextCalculationGranulesInProcessing", QueryTextCalculationGranulesInProcessing);
	QueueDescription.Insert("ProcessedGranulesTableName", "ProcessedGranules" + QueueName);
	#EndRegion
	
	#Region QueryTextExcludedDocuments
	QueryTextExcludedDocuments = "
	|SELECT
	|	ProcessedDocuments_.Document AS Document,
	|	ProcessedDocuments_.JobKind AS JobKind,
	|	ProcessedDocuments_.JobKind.QueueNumber AS QueueNumber
	|FROM
	|	TTProcessedGranules AS ProcessedDocuments_";
	
	QueryTextExcludedDocuments = StrReplace(QueryTextExcludedDocuments, "TTProcessedGranules", "TT" + QueueName);
	QueueDescription.Insert("QueryTextExcludedDocuments", QueryTextExcludedDocuments);
	#EndRegion
	
	Return QueueDescription;
	
EndFunction

// Register the problem of performing the calculation.
// 
// Parameters:
//  HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure RegisterCalculationExecutionProblem(HandlerParameters, JobKind = Undefined) Export
		
#Region Errors

	ProblemGroup = NStr("vi = 'Khi thực hiện thao tác, đã ghi nhận lỗi';
						|ru = 'При выполнении операции зарегистрированы ошибки';
						|en = 'Errors are registered while executing the operation:'; fa = 'Errors are registered while executing the operation:';
						|it = 'При выполнении операции зарегистрированы ошибки';
						|pl = 'Errors are registered while executing the operation:';
						|tr = 'İşlemin gerçekleştirilmesi sırasında hatalar kaydedildi'", Common.DefaultLanguageCode());
		
	TaskTemplateWithError = NStr("vi = 'Đã xảy ra lỗi khi thực hiện nhiệm vụ ""%1"" theo chứng từ %2.';
								|ru = 'Выполнение задания ""%1"" по документу %2 завершилось с ошибками.';
								|en = 'The ""%1"" job for the ""%2"" document is completed with errors.'; fa = 'The ""%1"" job for the ""%2"" document is completed with errors.';
								|it = 'The ""%1"" job for the ""%2"" document is completed with errors.';
								|pl = 'The ""%1"" job for the ""%2"" document is completed with errors.';
								|tr = '%2 belgesi kapsamındaki ""%1"" görevi hatalar ile tamamlandı.'", Common.DefaultLanguageCode());
	TemplateTaskFailed = NStr("vi = 'Chưa thực hiện nhiệm vụ ""%1"" theo chứng từ %2.';
								|ru = 'Задание ""%1"" по документу %2 не было выполнено.';
								|en = 'The ""%1"" job for the ""%2"" document is not completed.'; fa = 'The ""%1"" job for the ""%2"" document is not completed.';
								|it = 'The ""%1"" job for the ""%2"" document is not completed.';
								|pl = 'The ""%1"" job for the ""%2"" document is not completed.';
								|tr = '%2 belgesi kapsamındaki ""%1"" görevi tamamlanmadı.'", Common.DefaultLanguageCode());
		
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	Query.SetParameter("JobKind", JobKind);
	
	Query.Text = "
	|SELECT
	|	Jobs.Organization AS Organization,
	|	MIN(BEGINOFPERIOD(Jobs.TaskPeriod, MONTH)) AS TaskPeriod,
	|	Jobs.JobKind AS JobKind,
	|	Jobs.Document AS Document,
	|	Jobs.CompletedWithAnError AS CompletedWithAnError
	|INTO TT_Errors
	|FROM
	|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS Jobs
	|WHERE
	|	Jobs.Organization IN (&CompanyArray)
	|	AND Jobs.TaskPeriod <= &EndOfPeriod
	|	AND &FilterByTasks
	|GROUP BY
	|	Jobs.Organization,
	|	Jobs.JobKind,
	|	Jobs.Document,
	|	Jobs.CompletedWithAnError
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Errors.Organization AS Organization,
	|	TT_Errors.TaskPeriod AS TaskPeriod,
	|	TT_Errors.JobKind AS JobKind,
	|	TT_Errors.Document AS Document,
	|	TT_Errors.CompletedWithAnError AS CompletedWithAnError
	|FROM
	|	TT_Errors AS TT_Errors
	|TOTALS
	|BY
	|	Organization,
	|	TaskPeriod,
	|	JobKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_Errors";
	
	SetPrivilegedMode(True);
	Query.Text = StrReplace(Query.Text,"&FilterByTasks" , ?(JobKind = Undefined, "TRUE", "Jobs.JobKind = &JobKind"));
	SetPrivilegedMode(False);
	
	SelectionByOrganization = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SelectionByOrganization.Next() Do

		SamplingByPeriod = SelectionByOrganization.Select(QueryResultIteration.ByGroups);

		While SamplingByPeriod.Next() Do

			RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
						HandlerParameters.Data_Stage.Code, SelectionByOrganization.Organization,
				SamplingByPeriod.TaskPeriod);

			SelectionByTaskKind = SamplingByPeriod.Select(QueryResultIteration.ByGroups);

			While SelectionByTaskKind.Next() Do

				DetailedRecords = SelectionByTaskKind.Select();

				While DetailedRecords.Next() Do

					FullTextOfProblem = StringFunctionsClientServer.SubstituteParametersToString(?(
					DetailedRecords.CompletedWithAnError, TaskTemplateWithError, TemplateTaskFailed),
						SelectionByTaskKind.JobKind, DetailedRecords.Document);

					MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
							RegistrationParameters, ProblemGroup, Enums.AccountingIssueSeverity.Error,
						FullTextOfProblem, DetailedRecords.Document);

				EndDo;

			EndDo;

		EndDo;

	EndDo;
	
#EndRegion

EndProcedure

// Describes a table of calculation granules by queue register.
// 
// Returns:
//  ValueTable - Table of calculation granules for processing:
// * Document - DocumentRef - Document
//
Function TableOfCalculationGranules() Export

	CalculationGranules = New ValueTable;
	CalculationGranules.Columns.Add("Document", Documents.AllRefsType());

	Return CalculationGranules;

EndFunction

// Error data is processed based on the submitted list of documents and the type of task.
//
// Parameters:
//  DocumentsList - Undefined, Array of DocumentRef - Processed Documents
//  ErrorIds - Undefined, Array of UUID - List of processed error identifiers
//  JobKind - Undefined, CatalogRef.BackdateJobKinds - Type of task
//
Procedure UncheckCompletedWithErrorBasedOnDocuments(DocumentsList, ErrorIds, JobKind = Undefined) Export
	
	ListOfExcludedTypesOfTasks = New Array;
	ListOfExcludedTypesOfTasks.Add(Catalogs.BackdateJobKinds.ARAPAllocationByDueDates);
		
	If JobKind <> Undefined Then
		
		If ListOfExcludedTypesOfTasks.Find(JobKind) <> Undefined Then
			Return;
		EndIf;
		 
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentsList", DocumentsList);
	Query.SetParameter("JobKind", JobKind);

	Query.Text = "
	|SELECT
	|	TableQueue.TaskPeriod AS TaskPeriod,
	|	TableQueue.Organization AS Organization,
	|	TableQueue.JobKind AS JobKind,
	|	TableQueue.Document AS Document,
	|	TableQueue.RecordID AS RecordID,
	|	TableQueue.ErrorID AS ErrorID
	|INTO ErrorsData
	|FROM
	|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS TableQueue
	|WHERE
	|	TableQueue.CompletedWithAnError
	|	AND &FilterByDocuments
	|	AND &SelectionByTaskType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ErrorsData.TaskPeriod AS TaskPeriod,
	|	ErrorsData.Organization AS Organization,
	|	ErrorsData.JobKind AS JobKind,
	|	ErrorsData.Document AS Document,
	|	ErrorsData.RecordID AS RecordID,
	|	ErrorsData.ErrorID AS ErrorID
	|FROM
	|	ErrorsData AS ErrorsData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(ErrorsData.TaskPeriod) AS TaskPeriod,
	|	ErrorsData.Organization AS Organization,
	|	ErrorsData.JobKind AS JobKind,
	|	ErrorsData.Document AS Document
	|FROM
	|	ErrorsData AS ErrorsData
	|GROUP BY
	|	ErrorsData.Organization,
	|	ErrorsData.JobKind,
	|	ErrorsData.Document";
	
	If DocumentsList = Undefined Then
		Query.Text = StrReplace(Query.Text, "&FilterByDocuments", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "&FilterByDocuments", "TableQueue.Document IN (&DocumentsList)");
	EndIf;

	If JobKind = Undefined Then
		Query.Text = StrReplace(Query.Text, "&SelectionByTaskType", "TRUE");
	Else
		Query.Text = StrReplace(Query.Text, "&SelectionByTaskType", "TableQueue.JobKind = &JobKind");
	EndIf;

	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	JobsWithErrors = Result[Result.UBound() - 1].Unload();
	JobsWithErrors.Indexes.Add("Document");
	EntriesForCreatingTasks = Result[Result.UBound()].Unload();
	EntriesForCreatingTasks.Indexes.Add("Document");
	SetPrivilegedMode(False);

	If JobsWithErrors.Count() = 0 Then
		Return;
	EndIf;

	QueueRegisterMetadata = Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting;
	TaskRegisterManager = Common.ObjectManagerByFullName(QueueRegisterMetadata.FullName());
	
	Documents_With_Errors = CommonClientServer.CollapseArray(JobsWithErrors.UnloadColumn("Document"));
	
	SizeOfPortionOfTasksToDelete = 500;
	PortionOfTasksToDelete = JobsWithErrors.CopyColumns();
	PortionOfNewTasks = EntriesForCreatingTasks.CopyColumns();
	DocumentSelectionStructure = New Structure("Document");
	
	For Each DocumentWithError In Documents_With_Errors Do

		DocumentSelectionStructure.Document = DocumentWithError;
		CommonClientServer.SupplementTable(JobsWithErrors.Copy(DocumentSelectionStructure),
			PortionOfTasksToDelete);
		CommonClientServer.SupplementTable(EntriesForCreatingTasks.Copy(
			DocumentSelectionStructure), PortionOfNewTasks);

		If PortionOfTasksToDelete.Count() >= SizeOfPortionOfTasksToDelete Then

			BackdateJobQueue.DeleteTasksWithErrorsAndRegisterNewOnesWithoutErrors(TaskRegisterManager,
				PortionOfTasksToDelete, PortionOfNewTasks, ErrorIds);

		EndIf;

	EndDo;
	
	If PortionOfTasksToDelete.Count() > 0 Then
		BackdateJobQueue.DeleteTasksWithErrorsAndRegisterNewOnesWithoutErrors(TaskRegisterManager,
			PortionOfTasksToDelete, PortionOfNewTasks, ErrorIds);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure PerformDocumentProcessing(JobKind, Document, ProcessingParameters)

	If JobKind = Catalogs.BackdateJobKinds.UpdateDocumentAmountsInAccountingCurrencies Then
		
		CalculateDocumentAmountsInAccountingCurrencies(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords Then
		
		UpdateDocumentSRegisterRecordsOnFinancialRegisters(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCashCounterpartyCustomersRegisterRecords Then
		
		GenerateCashRegisterRecordsCounterparty(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCashCounterpartyVendorsRegisterRecords Then
		
		GenerateCashRegisterRecordsCounterparty(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCounterpartyCounterpartyRegisterRecords Then
		
		GenerateRegisteredRecordsCounterpartyCounterparty(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then
		
		ReflectDocumentInManagementBalanceSheet(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.RecordExciseRegisterRecords Then
		
		ToFormRegisterRecordsForExciseTaxes(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.DistributionOfSalesByLinesOfBusiness Then
		
		GenerateRevenueRegisteredRecords(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.RecordOfAssetsAndLiabilitiesRegisterRecords Then
		
		ToFormRegisterRecordsForOtherAssetsLiabilities(Document, ProcessingParameters);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdatingOperationsAndStateOfElectronicTicket Then
		
		UpdateOfOperationsAndStateOfElectronicTicket(Document, ProcessingParameters);
		
	EndIf;

EndProcedure

Function ParametersOfDocumentProcessing(JobKind, DocumentsForProcessing_)
	
	If JobKind = Catalogs.BackdateJobKinds.UpdateDocumentAmountsInAccountingCurrencies Then
		
		ProcessingParameters = ParametersForCalculatingDocumentAmountsInAccountingCurrencies(DocumentsForProcessing_);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords Then
		
		ProcessingParameters = ParametersForUpdatingRegisteredRecordsOnFinancialRegisters(DocumentsForProcessing_);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCashCounterpartyCustomersRegisterRecords Then
		
		ProcessingParameters = ParametersForUpdatingRegisteredRecordsCashCounterparty(DocumentsForProcessing_, True);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCashCounterpartyVendorsRegisterRecords Then
		
		ProcessingParameters = ParametersForUpdatingRegisteredRecordsCashCounterparty(DocumentsForProcessing_, False);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.UpdateCounterpartyCounterpartyRegisterRecords Then
		
		ProcessingParameters = ParametersForUpdatingRegisteredRecordsCounterpartyCounterparty(DocumentsForProcessing_);
		
	ElsIf JobKind = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then
		
		ProcessingParameters = ParametersOfReflectionOfDocumentsInManagementBalanceSheet(DocumentsForProcessing_);
		
	Else
		
		ProcessingParameters = New Structure;
		
	EndIf;
	
	Return ProcessingParameters;
	
EndFunction

// In the queue register, it registers errors that occurred during the processing of calculation granules.
// In case of a processing error, calculation granules: related job records are minimized (and subsequently deleted), 
// and instead a new record is created marked "Completed with an error" and the assigned error ID. 
// A detailed description of the error with the same identifier will be recorded in the information register "Job Queue Errors".
// 
// Parameters:
//  RecordIds - Array of UUID - List of IDs of entries in the queue register.
//  ErrorDescriptionTable - ValueTable - Error description table:
// * Document - DocumentRef - the document being processed.
// * JobKind - CatalogRef.BackdateJobKinds - Type of task.
// * ErrorDescription - String - detailed description of the error.
Procedure RegisterDataProcessingErrors(RecordIds, ErrorDescriptionTable) Export
	
	If ErrorDescriptionTable.Count() > 0 Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	RegisterData.TaskPeriod AS TaskPeriod,
		|	RegisterData.Organization AS Organization,
		|	RegisterData.JobKind AS JobKind,
		|	RegisterData.Document AS Document,
		|	RegisterData.RecordID AS RecordID
		|INTO CalculationGranulesWithErrors
		|FROM
		|	InformationRegister.JobsOfBackdateAdditionalDocumentPosting AS RegisterData
		|WHERE
		|	RegisterData.RecordID IN (&RecordIds)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.Document AS Document,
		|	Jobs.Organization AS Organization,
		|	MIN(Jobs.TaskPeriod) AS TaskPeriod,
		|	Jobs.JobKind AS JobKind
		|FROM
		|	CalculationGranulesWithErrors AS Jobs
		|GROUP BY
		|	Jobs.Document,
		|	Jobs.Organization,
		|	Jobs.JobKind
		|TOTALS
		|BY
		|	Document,
		|	JobKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Jobs.RecordID AS JobID,
		|	Jobs.JobKind AS JobKind,
		|	Jobs.Document AS Document
		|FROM
		|	CalculationGranulesWithErrors AS Jobs";
		
		Query.SetParameter("RecordIds", RecordIds);
		SetPrivilegedMode(True);
		Result = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		
		QueueRegisterMetadata = Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting;
		
		TaskIds = Result[Result.UBound()].Unload();
		TaskIds.Indexes.Add("Document, JobKind");

		SelectionByDocuments = Result[Result.UBound() - 1].Select(QueryResultIteration.ByGroups);
		DocumentSelectionStructure = New Structure;
		While SelectionByDocuments.Next() Do
			
			SelectionByTypeOfTasks = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
			
			While SelectionByTypeOfTasks.Next() Do
				
				ErrorID = New UUID;
	
				DocumentSelectionStructure.Insert("Document", SelectionByTypeOfTasks.Document);
				DocumentSelectionStructure.Insert("JobKind", SelectionByTypeOfTasks.JobKind);
				ErrorsTexts = ErrorDescriptionTable.Copy(DocumentSelectionStructure, "ErrorDescription").UnloadColumn(
					"ErrorDescription");
				ErrorsTexts = CommonClientServer.CollapseArray(ErrorsTexts);
				ErrorDescription = StrConcat(ErrorsTexts, Chars.LF);
	
				BeginTransaction();
	
				Try
					// Writing to the error register
					ErrorRecordset = InformationRegisters.JobQueueErrors.CreateRecordSet();
					ErrorRecording = ErrorRecordset.Add();
					ErrorRecording.ErrorID = ErrorID;
					ErrorRecording.ErrorDescription = ErrorDescription;
					ErrorRecording.RecordDate = CurrentSessionDate();
					SetPrivilegedMode(True);
					ErrorRecordset.Write(False);
					SetPrivilegedMode(False);
	
					DetailedRecords = SelectionByTypeOfTasks.Select();
	
					Jobs = CreateRecordSet();
					While DetailedRecords.Next() Do
	
						TaskWithError = Jobs.Add();
						FillPropertyValues(TaskWithError, DetailedRecords);
						TaskWithError.RecordID = New UUID;
						TaskWithError.CompletedWithAnError = True;
						TaskWithError.ErrorID = ErrorID;
	
					EndDo;
					
					SetPrivilegedMode(True);
					Jobs.Write(False);
					SetPrivilegedMode(False);
					
					IdsByDocument = TaskIds.Copy(DocumentSelectionStructure,
						"JobID").UnloadColumn("JobID");
						
					SetPrivilegedMode(True);
					BackdateJobQueue.DeleteQueueTasks(QueueRegisterMetadata.Name,
						IdsByDocument);
					SetPrivilegedMode(False);
					
					CommitTransaction();
				
				Except

					RollbackTransaction();
	
					ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	
					BackdateJobQueue.WriteErrorToEventLog(QueueRegisterMetadata, SelectionByTypeOfTasks.JobKind,
						ErrorText);

				EndTry;
				
			EndDo;
			
		EndDo;
	
	EndIf;
	
EndProcedure

Procedure ReportDataProcessingErrors(ErrorsOfDocuments)
	
	If ErrorsOfDocuments.Count() > 0 Then
		
		ErrorTemplate = NStr("vi = 'Đã kết thúc bị lỗi khi thực hiện nhiệm vụ %1 theo chứng từ %2: %3';
							|ru = 'Выполнение задания %1 по документу %2 завершилось с ошибкой: %3';
							|en = 'The ""%1"" job for the ""%2"" document is completed with an error: %3'; fa = 'The ""%1"" job for the ""%2"" document is completed with an error: %3';
							|it = 'The ""%1"" job for the ""%2"" document is completed with an error: %3';
							|pl = 'The ""%1"" job for the ""%2"" document is completed with an error: %3';
							|tr = '%2 belgesi kapsamında %1 görevi hata ile tamamlandı: %3'", Common.DefaultLanguageCode());
				
		ErrorsArray = New Array;
		For Each TaskCompletionError In ErrorsOfDocuments Do
			If ValueIsFilled(TaskCompletionError.ErrorDescription) Then
				ErrorTextByDocument = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, TaskCompletionError.JobKind,
					TaskCompletionError.Document, TaskCompletionError.ErrorDescription);
				ErrorsArray.Add(ErrorTextByDocument);
			EndIf;
		EndDo;
		
		If ErrorsArray.Count() > 0 Then
			ExceptionText = StrConcat(CommonClientServer.CollapseArray(ErrorsArray), Chars.LF);
			Raise ExceptionText;
		EndIf;

	EndIf;
	
EndProcedure

#Region CalculationOfDocumentAmountsInAccountingCurrencies

Function ParametersForCalculatingDocumentAmountsInAccountingCurrencies(DocumentsForProcessing_)
	
	ProcessingParameters = New Structure;
	
	TableOfDocumentsForRecalculation = InformationRegisters.DocumentAmountsInAccountingCurrency.TableOfDocumentsForRecalculationOfAmountsInAccountingCurrencies(
		DocumentsForProcessing_);
	
	ArrayOfDocumentsWithClients = TableOfDocumentsForRecalculation.Copy(
		New Structure("PaymentType_",Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting)).UnloadColumn("ARAPDocument");
	ArrayOfDocumentsWithSuppliers = TableOfDocumentsForRecalculation.Copy(
		New Structure("PaymentType_",Enums.PartnersARAPAccountingTypes.VendorARAPAccounting)).UnloadColumn("ARAPDocument");
	
	ProcessingParameters.Insert("ArrayOfDocumentsWithClients", ArrayOfDocumentsWithClients);
	ProcessingParameters.Insert("ArrayOfDocumentsWithSuppliers", ArrayOfDocumentsWithSuppliers);
	
	If ArrayOfDocumentsWithClients.Count() > 0 Then
		ParametersOfSettlementWithClients = InformationRegisters.DocumentAmountsInAccountingCurrency.ParametersOfCalculationOfDocumentsAccordingToDataOfMutualSettlements(
			"CustomersARAPAccounting", ArrayOfDocumentsWithClients);
		ProcessingParameters.Insert("ParametersOfSettlementWithClients", ParametersOfSettlementWithClients);
	EndIf;
	If ArrayOfDocumentsWithSuppliers.Count() > 0 Then
		ParametersOfSettlementWithSuppliers = InformationRegisters.DocumentAmountsInAccountingCurrency.ParametersOfCalculationOfDocumentsAccordingToDataOfMutualSettlements(
			"VendorsARAPAccounting", ArrayOfDocumentsWithSuppliers);
		ProcessingParameters.Insert("ParametersOfSettlementWithSuppliers", ParametersOfSettlementWithSuppliers);
	EndIf;
	
	ParametersForCalculatingDiscounting = InformationRegisters.DocumentAmountsInAccountingCurrency.ParametersForCalculatingDocumentDiscounting(
		DocumentsForProcessing_);
	ProcessingParameters.Insert("ParametersForCalculatingDiscounting", ParametersForCalculatingDiscounting);

	Return ProcessingParameters;
	
EndFunction

Procedure CalculateDocumentAmountsInAccountingCurrencies(DocumentReference, ProcessingParameters)
	
	ArrayOfDocumentsWithClients = ProcessingParameters.ArrayOfDocumentsWithClients;
	ArrayOfDocumentsWithSuppliers = ProcessingParameters.ArrayOfDocumentsWithSuppliers;
	FilterByDocument = New Structure("Ref", DocumentReference);
	
	If Not ArrayOfDocumentsWithClients.Find(DocumentReference) = Undefined Then
		
		ResultFromDocuments = ProcessingParameters.ParametersOfSettlementWithClients.ResultOfRequestForDocuments;

		SelectionByDocuments = ResultFromDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.FindNext(FilterByDocument) Do

			InformationRegisters.DocumentAmountsInAccountingCurrency.DistributeAmountsAccordingToDocumentAccordingToDataOfMutualSettlements(
				SelectionByDocuments, ProcessingParameters.ParametersOfSettlementWithClients);

		EndDo;
		
	EndIf;
	
	If Not ArrayOfDocumentsWithSuppliers.Find(DocumentReference) = Undefined Then
		
		ResultFromDocuments = ProcessingParameters.ParametersOfSettlementWithSuppliers.ResultOfRequestForDocuments;

		SelectionByDocuments = ResultFromDocuments.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.FindNext(FilterByDocument) Do

			InformationRegisters.DocumentAmountsInAccountingCurrency.DistributeAmountsAccordingToDocumentAccordingToDataOfMutualSettlements(
				SelectionByDocuments, ProcessingParameters.ParametersOfSettlementWithSuppliers);

		EndDo;
		
	EndIf;
	
	If ArrayOfDocumentsWithClients.Find(DocumentReference) = Undefined 
		And ArrayOfDocumentsWithSuppliers.Find(DocumentReference) = Undefined Then
		
		SelectionByDocuments = ProcessingParameters.ParametersForCalculatingDiscounting.SelectionByDocuments;
		
		While SelectionByDocuments.FindNext(FilterByDocument) Do

			InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDiscountingByDocument(SelectionByDocuments,
				ProcessingParameters.ParametersForCalculatingDiscounting);

		EndDo;
	
	EndIf;

EndProcedure

#EndRegion

#Region UpdateFinancialRegistersRecords

Function ParametersForUpdatingRegisteredRecordsOnFinancialRegisters(DocumentsForProcessing_)
	
	ProcessingParameters = New Structure;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	DocumentAmountsInAccountingCurrency.Recorder AS Document
	|FROM
	|	InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|WHERE
	|	DocumentAmountsInAccountingCurrency.Recorder IN (&DocumentsList)
	|	AND DocumentAmountsInAccountingCurrency.Active";
	Query.SetParameter("DocumentsList", DocumentsForProcessing_);
	
	ProcessingParameters.Insert("PostedDocuments", Query.Execute().Unload().UnloadColumn("Document"));

	Return ProcessingParameters;
	
EndFunction

Procedure UpdateDocumentSRegisterRecordsOnFinancialRegisters(Document, ProcessingParameters)
	
	PostedDocuments = ProcessingParameters.PostedDocuments;
	If PostedDocuments.Find(Document) <> Undefined Then
		InformationRegisters.DocumentAmountsInAccountingCurrency.UpdateDocumentRegisteredRecords_(Document);
	EndIf;
	
EndProcedure

#EndRegion

#Region UpdatingRegisteredRecordsOfCashCounterparty

Function ParametersForUpdatingRegisteredRecordsCashCounterparty(DocumentsForProcessing_, TheseAreSettlementsWithCustomers = True)
	
	ProcessingParameters = New Structure;
	
	TempTablesManager = New TempTablesManager;
	MovementData = ManagementAccountingPostingServer.RegisteredRecordsOfCashCounterparty(DocumentsForProcessing_,
		TheseAreSettlementsWithCustomers, TempTablesManager);
	
	ProcessingParameters.Insert("MovementData", MovementData);

	Return ProcessingParameters;
	
EndFunction

Procedure GenerateCashRegisterRecordsCounterparty(DocumentReference, ProcessingParameters)
	
	MovementData = ProcessingParameters.MovementData; //RequestReslts
	
	SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
	While SelectionByDocuments.FindNext(New Structure("Recorder", DocumentReference)) Do
		ManagementAccountingPostingServer.RecordCashFlowCounterparty(SelectionByDocuments,
			Undefined, Undefined);
	EndDo;

EndProcedure

#EndRegion

#Region UpdateCounterpartyCounterpartyRegisterRecords

Function ParametersForUpdatingRegisteredRecordsCounterpartyCounterparty(DocumentsForProcessing_)
	
	ProcessingParameters = New Structure;
	
	MovementData = ManagementAccountingPostingServer.RegisteredRecordedDataCounterpartyCounterparty(DocumentsForProcessing_);
	
	ProcessingParameters.Insert("MovementData", MovementData);

	Return ProcessingParameters;
	
EndFunction

Procedure GenerateRegisteredRecordsCounterpartyCounterparty(DocumentReference, ProcessingParameters)
	
	MovementData = ProcessingParameters.MovementData; //RequestReslts

	If Not MovementData = Undefined Then
		SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.FindNext(New Structure("Recorder", DocumentReference)) Do
			ManagementAccountingPostingServer.RecordCounterpartySRegisterRecordsCounterparty(SelectionByDocuments, Undefined);
			ManagementAccountingPostingServer.ToFormRegisterRecordsForOtherAssetsLiabilities(SelectionByDocuments);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region ReflectDocumentsInManagementBalanceSheet

Function ParametersOfReflectionOfDocumentsInManagementBalanceSheet(DocumentsForProcessing_)
	
	ProcessingParameters = New Structure;
	
	MovementData = DataProcessors.FlowOfAssetsAndLiabilities.DataOfRegisteredRecordsOfReflectionOfDocumentsInManagementBalanceSheet(
		DocumentsForProcessing_);
	
	ProcessingParameters.Insert("MovementData", MovementData);

	Return ProcessingParameters;
	
EndFunction

Procedure ReflectDocumentInManagementBalanceSheet(DocumentReference, ProcessingParameters)
	
	MovementData = ProcessingParameters.MovementData; //RequestReslts

	If Not MovementData = Undefined Then
		SelectionByDocuments = MovementData.Select(QueryResultIteration.ByGroups);
		While SelectionByDocuments.FindNext(New Structure("Recorder", DocumentReference)) Do
			DataProcessors.FlowOfAssetsAndLiabilities.RecordRegisteredRecordsOfOtherAssetsLiabilities(SelectionByDocuments);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion 

#Region ToFormRegisterRecordsForExciseTaxes

Procedure ToFormRegisterRecordsForExciseTaxes(DocumentReference, ProcessingParameters)
	
	ExcisableGoodsAccounting.RecordExciseTaxAmounts(DocumentReference);

EndProcedure

#EndRegion

#Region GenerateRevenueRegisteredRecords

Procedure GenerateRevenueRegisteredRecords(DocumentReference, ProcessingParameters)
	
	CostCalculationCostAdjustment.RecordRevenueAmounts(DocumentReference);

EndProcedure

#EndRegion
#Region ToFormRegisterRecordsForOtherAssetsLiabilities

Procedure ToFormRegisterRecordsForOtherAssetsLiabilities(DocumentReference, ProcessingParameters)
	
	OtherAssetsLiabilitiesServer.WriteDownOtherAssetsLiabilities(DocumentReference);
	
EndProcedure

#EndRegion

#Region UpdatingOfElectronicTicketsAndOperations

Procedure UpdateOfOperationsAndStateOfElectronicTicket(DocumentReference, ProcessingParameters)
	
	Documents.ElectronicTicketTransaction.UpdateOfOperationsAndStateOfElectronicTicket(DocumentReference);
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Adds information security update procedures to the list for all supported library versions or configurations.
// 
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly mode = False.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.17";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("3a7f1120-2cdb-11ef-841c-af5642bc9f0d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Ghi nhận nhiệm vụ kết chuyển bổ sung chứng từ không hiện thời';
							|ru = 'Регистрация заданий неоперативного допроведения документов';
							|en = 'Register jobs of backdate additional document posting'; fa = 'Register jobs of backdate additional document posting';
							|it = 'Register jobs of backdate additional document posting';
							|pl = 'Register jobs of backdate additional document posting';
							|tr = 'Operasyonel olmayan ek belge düzenlemesi görevlerinin kaydı'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.FullName());
	
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.JobsOfBackdateAdditionalDocumentPosting";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.JobsOfBackdateAdditionalDocumentPosting");

	Query = New Query;
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("MasterNode", ExchangePlans.MasterNode() = Undefined);
	Query.SetParameter("InitialRegistrationOfTasks", Constants.PerformedInitialRegistrationOfBackdateAdditionalDocumentPostingJobs.Get());
	Query.Text =
	"SELECT
	|	MIN(JobsForMonthEndClosing.Month) AS Month,
	|	JobsForMonthEndClosing.Organization AS Organization
	|INTO TT_PeriodsOfClosing
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|	LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
	|	ON JobsForMonthEndClosing.Organization = SetUpLockFromChanges.Organization
	|WHERE
	|	JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation)
	|	AND JobsForMonthEndClosing.Month >= ISNULL(SetUpLockFromChanges.LockUntil, DATETIME(1,1,1))
	|
	|GROUP BY
	|	JobsForMonthEndClosing.Organization
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Document AS Document
	|FROM
	|	(SELECT DISTINCT
	|		CustomersARAPAccounting.Recorder AS Document
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON CustomersARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|			AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		&NewOnlineARAPAccounting AND &MasterNode
	|		AND NOT &InitialRegistrationOfTasks
	|		AND VALUETYPE(CustomersARAPAccounting.Recorder) <> TYPE(Document.RegisterAdjustment)
	|		AND CustomersARAPAccounting.Sum <> 0
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		VendorsARAPAccounting.Recorder AS Document
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON VendorsARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|			AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		&NewOnlineARAPAccounting AND &MasterNode
	|		AND NOT &InitialRegistrationOfTasks
	|		AND VALUETYPE(VendorsARAPAccounting.Recorder) <> TYPE(Document.RegisterAdjustment)
	|		AND VendorsARAPAccounting.Sum <> 0) AS Table";
	
	Recorders = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Recorders, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "InformationRegister.JobsOfBackdateAdditionalDocumentPosting";
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Constants.PerformedInitialRegistrationOfBackdateAdditionalDocumentPostingJobs.Set(True);
		Return;
	EndIf;
	
	Query = New Query;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;

	Query = New Query;
	Query.Text = "
	|SELECT
	|	Data.Document AS Document
	|INTO TTDataToProcess
	|FROM
	|	&UpdatedData AS Data
	|
	|INDEX BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(JobsForMonthEndClosing.Month) AS Month,
	|	JobsForMonthEndClosing.Organization AS Organization
	|INTO TT_PeriodsOfClosing
	|FROM
	|	InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
	|		ON JobsForMonthEndClosing.Organization = SetUpLockFromChanges.Organization
	|WHERE
	|	JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation)
	|	AND JobsForMonthEndClosing.Month >= ISNULL(SetUpLockFromChanges.LockUntil, DATETIME(1, 1, 1))
	|GROUP BY
	|	JobsForMonthEndClosing.Organization
	|
	|INDEX BY
	|	Month,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData__.Document AS Document,
	|	DocumentData__.Organization AS Organization,
	|	MIN(DocumentData__.TaskPeriod) AS TaskPeriod
	|FROM
	|	(SELECT
	|		CustomersARAPAccounting.Recorder AS Document,
	|		CustomersARAPAccounting.Period AS TaskPeriod,
	|		CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|			INNER JOIN TTDataToProcess AS ProcessedDocuments_
	|			ON CustomersARAPAccounting.Recorder = ProcessedDocuments_.Document
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON CustomersARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|			AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		CustomersARAPAccounting.Sum <> 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		VendorsARAPAccounting.Recorder AS Document,
	|		VendorsARAPAccounting.Period AS TaskPeriod,
	|		VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|			INNER JOIN TTDataToProcess AS ProcessedDocuments_
	|			ON VendorsARAPAccounting.Recorder = ProcessedDocuments_.Document
	|			INNER JOIN TT_PeriodsOfClosing AS TT_PeriodsOfClosing
	|			ON VendorsARAPAccounting.Period >= TT_PeriodsOfClosing.Month
	|			AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = TT_PeriodsOfClosing.Organization
	|	WHERE
	|		VendorsARAPAccounting.Sum <> 0) AS DocumentData__
	|GROUP BY
	|	DocumentData__.Document,
	|	DocumentData__.Organization";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	DocumentData__ = Query.Execute().Unload();
	DocumentData__.Indexes.Add("Document");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;

	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr(
			"vi = 'Không thể xử lý chứng từ theo hàm sự kiện của biểu ghi thông tin ""Nhiệm vụ kết chuyển bổ sung chứng từ không hiện thời"":';
			|ru = 'Не удалось обработать документы по обработчику регистра сведений ""Задания неоперативного допроведения документов"":';
			|en = 'Cannot process the documents of the ""Jobs of backdate additional document posting"" information register handler:'; fa = 'Cannot process the documents of the ""Jobs of backdate additional document posting"" information register handler:';
			|it = 'Cannot process the documents of the ""Jobs of backdate additional document posting"" information register handler:';
			|pl = 'Cannot process the documents of the ""Jobs of backdate additional document posting"" information register handler:';
			|tr = '""Operasyonel olmayan ek belge düzenlemesi görevleri"" bilgi kaydı işleyicisi tarafından belgeler işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- tạo nhiệm vụ trong hàng đợi không hiện thời';
								|ru = '- создание заданий неоперативной очереди';
								|en = '- create backdate queue jobs'; fa = '- create backdate queue jobs';
								|it = '- create backdate queue jobs';
								|pl = '- create backdate queue jobs';
								|tr = '- Operasyonel olmayan kuyruk işlerinin oluşturulması'"));
	
	TypesOfRegistrarsAmountsOfDocumentsInAccountingCurrencies = Metadata.InformationRegisters.DocumentAmountsInAccountingCurrency.StandardAttributes.Recorder.Type;
	TypesOfRegistersRecordedCashCounterparty = Metadata.AccumulationRegisters.RecordsCashCounterparty.StandardAttributes.Recorder.Type;
	TypesOfRegisteredRecordsCounterpartyCounterparty = Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty.StandardAttributes.Recorder.Type;
	TypesOfRegistrarsOtherAssetsLiabilities = Metadata.AccumulationRegisters.OtherAssetsLiabilities.StandardAttributes.Recorder.Type;
	
	For Each CurrentData In UpdatedData Do

		ExceptionReason = 0;
		Recommendation = "";

		BeginTransaction();

		Try

			ExceptionReason = 1; // BadData
			Recommendation = NStr("vi = 'Kết chuyển lại chứng từ thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");

			TypeOfRegistrar = TypeOf(CurrentData.Document);
			OrganizationData = DocumentData__.FindRows(New Structure("Document", CurrentData.Document));

			RecordSet = CreateRecordSet();
			RecordSet.Filter.Document.Set(CurrentData.Document);
			
			If OrganizationData.Count() > 0 Then
				
				If TypesOfRegistrarsAmountsOfDocumentsInAccountingCurrencies.ContainsType(TypeOfRegistrar) Then
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.UpdateDocumentAmountsInAccountingCurrencies,
						OrganizationData);
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.UpdateFinancialRegistersRecords,
						OrganizationData);
				EndIf;

				If TypesOfRegistersRecordedCashCounterparty.ContainsType(TypeOfRegistrar) Then
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.UpdateCashCounterpartyCustomersRegisterRecords,
						OrganizationData);
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.UpdateCashCounterpartyVendorsRegisterRecords,
						OrganizationData);
				EndIf;

				If TypesOfRegisteredRecordsCounterpartyCounterparty.ContainsType(TypeOfRegistrar) Then
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.UpdateCounterpartyCounterpartyRegisterRecords,
						OrganizationData);
				EndIf;

				If TypesOfRegistrarsOtherAssetsLiabilities.ContainsType(TypeOfRegistrar) Then
					CreateTasksForDocument(RecordSet, CurrentData.Document,
						Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords,
						OrganizationData);
				EndIf;

				ExceptionReason = 2; // Record
				If RecordSet.Count() > 0 Then
					InfobaseUpdate.WriteRecordSet(RecordSet, False);
				Else
					InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				EndIf;
				
			Else
				ExceptionReason = 2; // Record
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;

			ObjectsProcessed = ObjectsProcessed + 1;

			CommitTransaction();

		Except

			RollbackTransaction();

			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CurrentData.Document);

			If ExceptionReason = 1 Then

				IssueDetails = InfobaseUpdateTM.DataProblem(
							CurrentData.Document, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);

			ElsIf ExceptionReason = 2 Then

				InfobaseUpdateTM.RecordBadData(
							ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);

			EndIf;

		EndTry;

	EndDo;//according to the updated data
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	If Parameters.ProcessingCompleted Then
		Constants.PerformedInitialRegistrationOfBackdateAdditionalDocumentPostingJobs.Set(True);
	EndIf;
	
EndProcedure

Procedure CreateTasksForDocument(RecordSet, Document, JobKind, TaskParameters)
	
	For Each OrganizationData_1 In TaskParameters Do
				
		NewJob = RecordSet.Add();
		NewJob.Organization = OrganizationData_1.Organization;
		NewJob.TaskPeriod = OrganizationData_1.TaskPeriod;
		NewJob.JobKind = JobKind;
		NewJob.Document = Document;
		NewJob.RecordID = New UUID();
				
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf