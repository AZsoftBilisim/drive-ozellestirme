#Region Internal

Procedure RunDataExchangeByScenario(ExchangeScenarioCode) Export
	
	If Not ValueIsFilled(ExchangeScenarioCode) Then		
		Raise NStr("vi = 'Chưa đặt kịch bản trao đổi dữ liệu.';
					|ru = 'Не задан сценарий обмена данными.';
					|en = 'Data exchange scenario not specified.'; fa = 'Data exchange scenario not specified.';
					|it = 'Non è indicato uno scenario di scambio dati.';
					|pl = 'Nie jest podany scenariusz wymiany danych.';
					|tr = 'Veri değişimi senaryosu belirtilmemiş.'");		
	EndIf;
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataSynchronization);
	
	Query = New Query;
	Query.SetParameter("Code", ExchangeScenarioCode);
	
	Query.Text = 
		"SELECT
		|	DataExchangeScenarios.Ref AS Ref,
		|	DataExchangeScenarios.IsAutoDisabled AS IsAutoDisabled,
		|	DataExchangeScenarios.UseScheduledJob AS UseScheduledJob
		|FROM
		|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
		|WHERE
		|	DataExchangeScenarios.Code = &Code
		|	AND NOT DataExchangeScenarios.DeletionMark";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		Scenario = Selection.Ref;
		
		If Not Selection.UseScheduledJob And Selection.IsAutoDisabled Then
			Return;
		EndIf;
		
		If ExecuteScheduledJobExchangeScenario(Scenario) Then
			DataExchangeServer.ExecuteDataExchangeByScheduledJob(ExchangeScenarioCode);
			Return;
		EndIf;
		
	Else	
		
		MessageString = NStr("vi = 'Không tìm thấy kịch bản trao đổi dữ liệu có mã %1.';
							|ru = 'Сценарий обмена данными с кодом %1 не найден.';
							|en = 'Data exchange scenario with code %1 is not found.'; fa = 'Data exchange scenario with code %1 is not found.';
							|it = 'Lo scenario di scambio dati con codice %1 non è stato trovato.';
							|pl = 'Scenariusz wymiany danych z kodem %1 nie znaleziono.';
							|tr = '%1Kodu ile veri değişim betiği bulunamadı.'");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeScenarioCode);
		Raise MessageString;
		
	EndIf;
		
	DeleteObsoleteTasks(Scenario);
	
	If DisableScenarioOnDemand(Scenario) Then
		Return;
	EndIf;
	
	// Jobs from the last runtime scenario must be completed.
	FirstTask = Undefined;
	If Not IsTaskQueueCompleted(Scenario, , , FirstTask) Then
		
		MessageText = NStr("vi = 'Đã tìm thấy nhiệm vụ đồng bộ hóa theo kịch bản của phiên trước đó.';
							|ru = 'Обнаружены задачи синхронизации по сценарию предыдущей сессии.';
							|en = 'Found sync tasks based on the previous session''s scenario.'; fa = 'Found sync tasks based on the previous session''s scenario.';
							|it = 'Found sync tasks based on the previous session''s scenario.';
							|pl = 'Found sync tasks based on the previous session''s scenario.';
							|tr = 'Geçmiş oturum senaryosundaki senkronizasyon görevleri saptanacaktır.'",
			Common.DefaultLanguageCode());
		
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Information,,,MessageText);
		
		If ValueIsFilled(FirstTask) Then
			
			RunTaskQueue(FirstTask);
			
		EndIf;
		
	Else
		
		FirstTask = Undefined;
		RunTaskByScenario(Scenario, FirstTask);
		
		RunTaskQueue(FirstTask);
		
	EndIf;
	
EndProcedure

Procedure RunDataExchangeManually(Node, ExchangeParameters, ExportAddition = Undefined) Export
	
	DeleteObsoleteTasks(, True);
	
	ExchangeID = String(New UUID);
	
	ExchangeParameters = New Structure;
	ExchangeParameters.Insert("Node", Node);
	ExchangeParameters.Insert("ExchangeID", ExchangeID);
	ExchangeParameters.Insert("Cancel", False);
	ExchangeParameters.Insert("ErrorMessage", "");
	
	FirstTask = Undefined;
	PopulatesTasksForManualExchange(Node, ExchangeID, FirstTask, ExportAddition);

	ProcedureParameters = New Array;
	ProcedureParameters.Add(FirstTask);
	
	Var_Key = FirstTask.TaskID__;

	JobParameters = New Structure;
	JobParameters.Insert("Key", Left(Var_Key, 120));
	JobParameters.Insert("MethodName"    , "DataExchangeInternalPublication.RunTaskQueue");
	JobParameters.Insert("DataArea", SessionParameters.DataAreaValue);
	JobParameters.Insert("Use", True);
	JobParameters.Insert("Parameters", ProcedureParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	JobParameters.Insert("RestartIntervalOnFailure", 900);
	
	SetPrivilegedMode(True); // In a separated infobase, internal publication, limited access rights
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	ModuleJobsQueue.AddJob(JobParameters);
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure RunTaskQueue(Task, JobPrev = "") Export
	
	If Task = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Task) = Type("String") Then
		CurrTask = TaskByID(Task);
	Else
		CurrTask = Task;
	EndIf;
		
	Cancel = False;
	If CurrTask.TaskNumber = 1 Then
		
		ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(CurrTask.InfobaseNode, CurrTask.Action, Cancel);
		
		If Cancel Then
			Return;
		EndIf;
		
		DataExchangeServer.RecordExchangeStartInInformationRegister(ExchangeSettingsStructure);
		
		MessageString = NStr("vi = 'Bắt đầu quá trình trao đổi dữ liệu đối với nút %1';
							|ru = 'Начало процесса обмена данными для узла %1';
							|en = 'Data exchange started. Node: %1.'; fa = 'Data exchange started. Node: %1.';
							|it = 'Inizio del processo di scambio dati per il nodo %1';
							|pl = 'Początek procesu  wymiany danych dla węzła %1';
							|tr = '%1Ünite için veri değişimi süreci başlatılıyor'", Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
		DataExchangeServer.WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	EndIf;
	
	// Actions running in the source infobase. The next task can start after their completion.
	ActionsInSource = New Array;
	ActionsInSource.Add(Enums.ActionsAtCancelInternalPublication.DataExport);
	ActionsInSource.Add(Enums.ActionsAtCancelInternalPublication.DataImport);
	ActionsInSource.Add(Enums.ActionsAtCancelInternalPublication.AdditionalRegistration);
	
	Cancel = False;
	While True Do
		
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		ExchangeParameters.Insert("TaskIDPrev", JobPrev);
		
		ExecuteTask(CurrTask, ExchangeParameters, Cancel);	
		
		If Not Cancel And ActionsInSource.Find(CurrTask.Action) <> Undefined Then
			
			JobPrev = CurrTask.TaskID__;
			CurrTask = NextTask(CurrTask.TaskID__);
			
		Else
			
			Break;
			
		EndIf;
		
		// No more tasks left.
		If CurrTask = Undefined Then
			Break;
		EndIf;
		
	EndDo;
		
EndProcedure

Function TaskByID(TaskID__) Export

	Query = New Query;
	Query.Text = 
		"SELECT
		|	Tasks.CreationDate AS CreationDate,
		|	Tasks.Scenario AS Scenario,
		|	Tasks.InfobaseNode AS InfobaseNode,
		|	Tasks.TaskNumber AS TaskNumber,
		|	Tasks.TaskID__ AS TaskID__,
		|	Tasks.ExchangeID AS ExchangeID,
		|	Tasks.Action AS Action,
		|	Tasks.OperationSuccessful AS OperationSuccessful,
		|	Tasks.OperationFailed AS OperationFailed,
		|	Tasks.Error AS Error,
		|	Tasks.Parameters AS Parameters,
		|	Tasks.Mode AS Mode,
		|	Tasks.CorrespondentDataArea AS CorrespondentDataArea
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.TaskID__ = &TaskID__";
	
	Query.SetParameter("TaskID__", TaskID__);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = StructureOfTask();
		FillPropertyValues(Result, Selection);
		Return Result;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function NextTask(TaskID__) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TaskNxt.CreationDate AS CreationDate,
		|	TaskNxt.Scenario AS Scenario,
		|	TaskNxt.InfobaseNode AS InfobaseNode,
		|	TaskNxt.TaskNumber AS TaskNumber,
		|	TaskNxt.TaskID__ AS TaskID__,
		|	TaskNxt.ExchangeID AS ExchangeID,
		|	TaskNxt.Action AS Action,
		|	TaskNxt.OperationSuccessful AS OperationSuccessful,
		|	TaskNxt.OperationFailed AS OperationFailed,
		|	TaskNxt.Error AS Error,
		|	TaskNxt.Parameters AS Parameters,
		|	TaskNxt.Mode AS Mode,
		|	TaskNxt.CorrespondentDataArea AS CorrespondentDataArea
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Task
		|		INNER JOIN InformationRegister.DataExchangeTasksInternalPublication AS TaskNxt
		|		ON Task.ExchangeID = TaskNxt.ExchangeID
		|			AND (Task.TaskNumber + 1 = TaskNxt.TaskNumber)
		|WHERE
		|	Task.TaskID__ = &TaskID__";
	
	Query.SetParameter("TaskID__", TaskID__);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = StructureOfTask();
		FillPropertyValues(Result, Selection);
		Return Result;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function HasNodeScheduledExchange(Node, Scenario = "", ExchangeID = "") Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Tasks.Scenario AS Scenario,
		|	Tasks.ExchangeID AS ExchangeID
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.InfobaseNode = &Node
		|	AND NOT Tasks.OperationSuccessful
		|	AND NOT Tasks.OperationFailed
		|
		|ORDER BY
		|	Tasks.CreationDate DESC,
		|	Tasks.TaskNumber";
	
	Query.SetParameter("Node", Node);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Scenario = Selection.Scenario;
		ExchangeID = Selection.ExchangeID;
		
		Return Not IsTaskQueueCompleted(, Selection.ExchangeID);
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure CancelTaskQueue(Node, Scenario, ExchangeID, DataArea) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Tasks.CreationDate AS CreationDate,
		|	Tasks.InfobaseNode AS InfobaseNode,
		|	Tasks.TaskNumber AS TaskNumber,
		|	Tasks.ExchangeID AS ExchangeID,
		|	Tasks.TaskID__ AS TaskID__,
		|	Tasks.OperationSuccessful AS OperationSuccessful,
		|	Tasks.OperationFailed AS OperationFailed,
		|	Tasks.Action AS Action
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.ExchangeID = &ExchangeID";
	
	Query.SetParameter("ExchangeID", ExchangeID);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
		
	Selection = Result.Select();
	
	SourceTasks = New Array;
	
	If ValueIsFilled(Scenario) Then
		GUIDScheduledJob = Common.ObjectAttributeValue(Scenario, "GUIDScheduledJob");
		
		If ValueIsFilled(GUIDScheduledJob) Then
			SourceTasks.Add(GUIDScheduledJob);
		EndIf;
	EndIf;
	
	DestinationTasks = New Array;
		
	While Selection.Next() Do
		
		If (Selection.Action = Enums.ActionsAtCancelInternalPublication.DataExportPeer
			Or Selection.Action = Enums.ActionsAtCancelInternalPublication.DataImportPeer)
			And Not Selection.OperationSuccessful Then
			
			DestinationTasks.Add(Selection.TaskID__);
			
		ElsIf Selection.Action = Enums.ActionsAtCancelInternalPublication.DataExport
			Or Selection.Action = Enums.ActionsAtCancelInternalPublication.DataImport
			Or Selection.Action = Enums.ActionsAtCancelInternalPublication.AdditionalRegistration
			And Not Selection.OperationSuccessful Then
			
			SourceTasks.Add(Selection.TaskID__);
			
		EndIf;
		
		BeginTransaction();
		
		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DataExchangeTasksInternalPublication");
			DataLockItem.SetValue("CreationDate", Selection.CreationDate);
			DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			DataLockItem.SetValue("TaskNumber", Selection.TaskNumber);
			DataLockItem.SetValue("ExchangeID", Selection.ExchangeID);
			DataLockItem.SetValue("TaskID__", Selection.TaskID__);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.Delete();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Обмен данными.Отмена очереди задач';
						|ru = 'Обмен данными.Отмена очереди задач';
						|en = 'Data exchange.Cancel the task queue'; fa = 'Data exchange.Cancel the task queue';
						|it = 'Обмен данными.Отмена очереди задач';
						|pl = 'Data exchange.Cancel the task queue';
						|tr = 'Обмен данными.Отмена очереди задач'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.DataExchangeTasksInternalPublication, , ErrorMessage);
		EndTry;
		
	EndDo;
	
	SetPrivilegedMode(True);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	For Each TaskID__ In SourceTasks Do
		
		Filter = New Structure("Key", TaskID__); 
		Jobs = ModuleJobsQueue.GetJobs(Filter);

		For Each Job In Jobs Do
			
			JobParameters = New Structure;
			JobParameters.Insert("RestartCountOnFailure", 0);
			
			ModuleJobsQueue.ChangeJob(Job.Id, JobParameters);
			ModuleJobsQueue.DeleteJob(Job.Id);
			
			BackgrJobUUID = Common.ObjectAttributeValue(
				Job.Id, "ActiveBackgroundJob");
				
			TimeConsumingOperations.CancelJobExecution(BackgrJobUUID);
		
		EndDo;
		
	EndDo;
	
	If DestinationTasks.Count() > 0 Then
		
		Proxy = Undefined;
		ExchangeSettingsStructure = Undefined;
		Cancel = False;
		Error = "";
		
		ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(Node, "UserCanceledOperation", Cancel);
		ProxyInitialization(Proxy, ExchangeSettingsStructure, Cancel, Error);
		
		If Cancel <> True
			Or Proxy <> Undefined Then
			
			Proxy.StopTasks(XDTOSerializer.WriteXDTO(DestinationTasks), DataArea);
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure MarkTaskAsCompleted(Task, Error) Export
	
	If TypeOf(Task) = Type("String") Then
		CurrTask = TaskByID(Task);
	Else
		CurrTask = Task;
	EndIf;
	
	If ValueIsFilled(CurrTask) Then
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DataExchangeTasksInternalPublication");
			DataLockItem.SetValue("CreationDate", CurrTask.CreationDate);
			DataLockItem.SetValue("InfobaseNode", CurrTask.InfobaseNode);
			DataLockItem.SetValue("TaskNumber", CurrTask.TaskNumber);
			DataLockItem.SetValue("ExchangeID", CurrTask.ExchangeID);
			DataLockItem.SetValue("TaskID__", CurrTask.TaskID__);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
			FillPropertyValues(Record, CurrTask);
			Record.Read();

			If Error = "" Then
				Record.OperationSuccessful = True;
			Else
				Record.OperationFailed = True;
				Record.Error = Error;
			EndIf;

			Record.Write();

			CommitTransaction();
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("vi = 'Обмен данными.Отметка выполнения задачи';
						|ru = 'Обмен данными.Отметка выполнения задачи';
						|en = 'Data exchange.Task completion flag'; fa = 'Data exchange.Task completion flag';
						|it = 'Обмен данными.Отметка выполнения задачи';
						|pl = 'Data exchange.Task completion flag';
						|tr = 'Обмен данными.Отметка выполнения задачи'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.DataExchangeTasksInternalPublication, , ErrorMessage);
		EndTry;

	EndIf;
	
EndProcedure

Procedure OnWaitForExportData(ExchangeParameters, ContinueWait) Export
	
	Error = "";
	ContinueWait = Not IsTaskQueueCompleted(,ExchangeParameters.ExchangeID, Error);

	If Error <> "" Then
		ExchangeParameters.Cancel = True;
		ExchangeParameters.ErrorMessage = Error;
	EndIf;	
		
EndProcedure

Procedure NodeFormOnCreateAtServer(Form, Cancel) Export
	
	SetFuncOptionsForNode(Form);
	SetUpFormElementsForMigrationToWS(Form);
	
EndProcedure

#Region DestinationTasks

Procedure ExportToFileTransferServiceForInfobaseNode(ExchangePlanName, InfobaseNodeCode, TaskID__) Export
	
	SetPrivilegedMode(True);
	
	MessageFileName = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(),
		DataExchangeServer.UniqueExchangeMessageFileName());
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ErrorPresentation = "";
	Try
		
		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
		
		NameOfFileToPutInStorage = MessageFileName;

		NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
			DataExchangeServer.TempFilesStorageDirectory(),
			DataExchangeServer.UniqueExchangeMessageFileName("zip"));
		
		Archiver = New ZipFileWriter(NameOfFileToPutInStorage, , , , ZIPCompressionLevel.Maximum);
		Archiver.Add(MessageFileName);
		Archiver.Write();
		
	Except
				
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		CallingBack(ExchangePlanName, InfobaseNodeCode, TaskID__, ErrorPresentation);
		
		DeleteFiles(MessageFileName);
		Raise ErrorPresentation;
		
	EndTry;
	
	DeleteFiles(MessageFileName);
	
	DataExchangeServer.PutFileInStorage(NameOfFileToPutInStorage, TaskID__);
		
	CallingBack(ExchangePlanName, InfobaseNodeCode, TaskID__);
		
EndProcedure

Procedure ImportFromFileTransferServiceForInfobaseNode(ExchangePlanName, InfobaseNodeCode, TaskID__, FileID) Export
	
	SetPrivilegedMode(True);
	
	MessageFileName = DataExchangeServer.GetFileFromStorage(FileID,, False);
	
	DataExchangeParameters = DataExchangeServer.DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = MessageFileName;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ErrorPresentation = "";
	
	Try

		DataExchangeServer.ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
		
	Except
		
		ErrorPresentation = IndicatesWhetherTaskHasBeenCanceledAgain();
		ErrorPresentation = ErrorPresentation + ":" + ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(DataExchangeSaaS.DataSyncronizationLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	DeleteFiles(MessageFileName);
	
	// Deleting information about message file from the storage.
	RecordStructure = New Structure;
	RecordStructure.Insert("MessageID", String(FileID));
		
	If Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then

		InformationRegisters.DataAreasDataExchangeMessages.DeleteRecord(RecordStructure);
	
	Else

		InformationRegisters.DataExchangeMessages.DeleteRecord(RecordStructure);

	EndIf;
	
	CallingBack(ExchangePlanName, InfobaseNodeCode, TaskID__, ErrorPresentation);
	
EndProcedure

#EndRegion

#Region AvailabilityOfExchangeAdministrationManage_3_0_1_1

Function HasInServiceExchangeAdministrationManage_3_0_1_1() Export
	
	If Not Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	ConnectionParameters = New Structure;
	SetPrivilegedMode(True);
	ConnectionParameters.Insert("URL", ModuleSaaSOperations.InternalServiceManagerURL());
	ConnectionParameters.Insert("UserName", ModuleSaaSOperations.ServiceManagerInternalUserName());
	ConnectionParameters.Insert("Password", ModuleSaaSOperations.ServiceManagerInternalUserPassword());
	SetPrivilegedMode(False);
	
	Versions = Common.GetInterfaceVersions(ConnectionParameters, "ExchangeAdministrationManage");
	
	Return Versions.Find("3.0.1.1") <> Undefined;
	
EndFunction

#EndRegion

Function ExchangeSettingsForInfobaseNode(Node, Action, Cancel) Export
	
	If Action = Enums.ActionsAtCancelInternalPublication.DataImport
		Or Action = Enums.ActionsAtCancelInternalPublication.DataExportPeer Then		
		
		ActionOnExchange = Enums.ActionsOnExchange.DataImport;		
		
	ElsIf Action = Enums.ActionsAtCancelInternalPublication.DataExport 
		Or Action = Enums.ActionsAtCancelInternalPublication.DataImportPeer Then		
		
		ActionOnExchange = Enums.ActionsOnExchange.DataExport;
		
	Else
		
		ActionOnExchange = Action;
		
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(Node, ActionOnExchange, "SM");
	
	If ExchangeSettingsStructure.Cancel Then
		// If a setting contains errors, canceling the exchange, Canceled status.
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		Cancel = True;
		Return Undefined;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	Return ExchangeSettingsStructure;
	
EndFunction

Procedure DeleteTasksAccordingToScriptWithError(Scenario) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Tasks.ExchangeID AS ExchangeID
		|INTO TT_Tasks
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.Scenario = &Scenario
		|	AND Tasks.OperationFailed
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataExchangeTasksInternalPublication.CreationDate AS CreationDate,
		|	DataExchangeTasksInternalPublication.InfobaseNode AS InfobaseNode,
		|	DataExchangeTasksInternalPublication.TaskNumber AS TaskNumber,
		|	DataExchangeTasksInternalPublication.ExchangeID AS ExchangeID,
		|	DataExchangeTasksInternalPublication.TaskID__ AS TaskID__
		|FROM
		|	TT_Tasks AS TT_Tasks
		|		LEFT JOIN InformationRegister.DataExchangeTasksInternalPublication AS DataExchangeTasksInternalPublication
		|		ON TT_Tasks.ExchangeID = DataExchangeTasksInternalPublication.ExchangeID";
	
	Query.SetParameter("Scenario", Scenario);
	
	Selection = Query.Execute().Select();
	
	BeginTransaction();
	
	Try
			
		Block = New DataLock;
		LockItem = Block.Add("Catalog.DataExchangeScenarios");
		LockItem.SetValue("Ref", Scenario);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		While Selection.Next() Do
			
			Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			Record.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(EventLogEventScenarioDisabled(),
			EventLogLevel.Error, , , ErrorMessage);
			
	EndTry;
	
EndProcedure

Function IndicatesWhetherTaskHasBeenCanceledAgain() Export
	
	Return NStr("vi = '#ОтменитьПовторноеВыполнениеЗадачи#';
				|ru = '#ОтменитьПовторноеВыполнениеЗадачи#';
				|en = '#ОтменитьПовторноеВыполнениеЗадачи#'; fa = '#ОтменитьПовторноеВыполнениеЗадачи#';
				|it = '#ОтменитьПовторноеВыполнениеЗадачи#';
				|pl = '#ОтменитьПовторноеВыполнениеЗадачи#';
				|tr = '#ОтменитьПовторноеВыполнениеЗадачи#'");
	
EndFunction

#EndRegion

#Region Private

#Region Tasks

Procedure DeleteObsoleteTasks(Scenario = Undefined, ManualExchange = False)
	
	BeginTransaction();
	
	Try
		
		// Delete records with broken references
		Query = New Query;
		Query.Text = 
			"SELECT ALLOWED
			|	Tasks.CreationDate AS CreationDate,
			|	Tasks.InfobaseNode AS InfobaseNode,
			|	Tasks.TaskNumber AS TaskNumber,
			|	Tasks.ExchangeID AS ExchangeID,
			|	Tasks.TaskID__ AS TaskID__
			|FROM
			|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
			|WHERE
			|	Tasks.InfobaseNode.Code IS NULL";
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do 
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.DataExchangeTasksInternalPublication");
			LockItem.SetValue("CreationDate", Selection.CreationDate);
			LockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			LockItem.SetValue("TaskNumber", Selection.TaskNumber);
			LockItem.SetValue("ExchangeID", Selection.ExchangeID);
			LockItem.SetValue("TaskID__", Selection.TaskID__);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			
			If Record.Selected() Then
				Record.Delete();
			EndIf;
			
		EndDo;
			
		// Keep N newest records.
		Query = New Query;
		Query.Text =
		"SELECT TOP 5
		|	Tasks.ExchangeID AS ExchangeID
		|INTO TTLastSync
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.Scenario = &Scenario
		|
		|GROUP BY
		|	Tasks.ExchangeID
		|
		|ORDER BY
		|	MAX(Tasks.CreationDate) DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Tasks.CreationDate AS CreationDate,
		|	Tasks.InfobaseNode AS InfobaseNode,
		|	Tasks.TaskNumber AS TaskNumber,
		|	Tasks.ExchangeID AS ExchangeID,
		|	Tasks.TaskID__ AS TaskID__
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|		FULL JOIN TTLastSync AS TTLastSync
		|		ON Tasks.ExchangeID = TTLastSync.ExchangeID
		|WHERE
		|	TTLastSync.ExchangeID IS NULL
		|	AND Tasks.Scenario = &Scenario
		|
		|ORDER BY
		|	CreationDate";
		
		If ValueIsFilled(Scenario) Then
			Query.SetParameter("Scenario", Scenario);
		Else
			Query.SetParameter("Scenario", Catalogs.DataExchangeScenarios.EmptyRef());	
		EndIf;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.DataExchangeTasksInternalPublication");
			LockItem.SetValue("CreationDate", Selection.CreationDate);
			LockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
			LockItem.SetValue("TaskNumber", Selection.TaskNumber);
			LockItem.SetValue("ExchangeID", Selection.ExchangeID);
			LockItem.SetValue("TaskID__", Selection.TaskID__);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
			FillPropertyValues(Record, Selection);
			Record.Read();
			
			If Record.Selected() Then
				Record.Delete();
			EndIf;
			
		EndDo;
		
		CommitTransaction();
	
	Except
				
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		Event = NStr("vi = 'Trao đổi dữ liệu. Xóa bản ghi của biểu ghi nhiệm vụ';
					|ru = 'Обмен данными.Удаление записей регистра задач';
					|en = 'Data exchange.Delete task register records'; fa = 'Data exchange.Delete task register records';
					|it = 'Обмен данными.Удаление записей регистра задач';
					|pl = 'Data exchange.Delete task register records';
					|tr = 'Veri alışverişi.Görev kaydı girişlerinin silinmesi'", Common.DefaultLanguageCode());
		
		WriteLogEvent(Event, EventLogLevel.Error, , , ErrorMessage);
	
	EndTry;
	
EndProcedure

Function DisableScenarioOnDemand(Scenario)
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT TOP 3
		|	Tasks.CreationDate AS CreationDate,
		|	Tasks.Scenario AS Scenario,
		|	Tasks.ExchangeID AS ExchangeID
		|INTO TTDates
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.Scenario = &Scenario
		|
		|ORDER BY
		|	CreationDate DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Tasks.CreationDate AS CreationDate
		|FROM
		|	TTDates AS TTDates
		|		INNER JOIN InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|		ON TTDates.CreationDate = Tasks.CreationDate
		|			AND TTDates.ExchangeID = Tasks.ExchangeID
		|			AND (Tasks.OperationFailed)";
	
	Query.SetParameter("Scenario", Scenario);
	
	Result = Query.Execute().Unload();
	
	If Result.Count() >= 3 Then
			
		ScenarioObject = Scenario.GetObject();
		ScenarioObject.UseScheduledJob = False;
		ScenarioObject.IsAutoDisabled = True;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.DataExchangeScenarios");
			LockItem.SetValue("Ref", Scenario);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ScenarioObject.Write();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
			WriteLogEvent(EventLogEventScenarioDisabled(),
				EventLogLevel.Error, , , ErrorMessage);
			
		EndTry;
				
		Return True;
			
	EndIf;
	
	Return False;
	
EndFunction

Function IsTaskQueueCompleted(Scenario = Undefined, ExchangeID = "", Error = "", FoundSyncTask = Undefined)
	
	// Assume that the scenario (or manual exchange) is completed if "CompletedSuccessfully" is set to "True" for all tasks, or an error occurred. 
	If ValueIsFilled(Scenario) And Not ValueIsFilled(ExchangeID) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT TOP 1
			|	Tasks.ExchangeID AS ExchangeID
			|FROM
			|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
			|WHERE
			|	Tasks.Scenario = &Scenario
			|
			|ORDER BY
			|	Tasks.CreationDate DESC";
		
		Query.SetParameter("Scenario", Scenario);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			ExchangeID = Selection.ExchangeID;		
		Else	
			Return True;	
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Tasks.CreationDate AS CreationDate,
		|	Tasks.InfobaseNode AS InfobaseNode,
		|	Tasks.TaskNumber AS TaskNumber,
		|	Tasks.ExchangeID AS ExchangeID,
		|	Tasks.TaskID__ AS TaskID__,
		|	Tasks.Action AS Action,
		|	Tasks.OperationSuccessful AS OperationSuccessful,
		|	Tasks.OperationFailed AS OperationFailed,
		|	Tasks.Error AS Error,
		|	CASE
		|		WHEN Tasks.TaskCheckTime = DATETIME(1, 1, 1)
		|			THEN Tasks.CreationDate
		|		ELSE Tasks.TaskCheckTime
		|	END AS TaskCheckTime
		|INTO TTTasks
		|FROM
		|	InformationRegister.DataExchangeTasksInternalPublication AS Tasks
		|WHERE
		|	Tasks.ExchangeID = &ExchangeID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTTasks.TaskID__ AS TaskID__,
		|	TTTasks.Action AS Action,
		|	TTTasks.Error AS Error
		|FROM
		|	TTTasks AS TTTasks
		|WHERE
		|	TTTasks.OperationFailed
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TRUE AS Completed2
		|FROM
		|	TTTasks AS TTTasks
		|
		|HAVING
		|	SUM(CASE
		|			WHEN TTTasks.OperationSuccessful
		|				THEN 1
		|			ELSE 0
		|		END) = MAX(TTTasks.TaskNumber)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TTTasks.CreationDate AS CreationDate,
		|	TTTasks.InfobaseNode AS InfobaseNode,
		|	TTTasks.TaskNumber AS TaskNumber,
		|	TTTasks.ExchangeID AS ExchangeID,
		|	TTTasks.TaskID__ AS TaskID__,
		|	TTTasks.Action AS Action,
		|	DATEDIFF(TTTasks.TaskCheckTime, &CurrentDate, HOUR) AS LastCheck
		|FROM
		|	TTTasks AS TTTasks
		|WHERE
		|	NOT TTTasks.OperationSuccessful
		|	AND NOT TTTasks.OperationFailed
		|
		|ORDER BY
		|	TaskNumber";
		
	Query.SetParameter("ExchangeID", ExchangeID);
	Query.SetParameter("CurrentDate", CurrentUniversalDate());
	
	Result = Query.ExecuteBatch();
	
	// Completed with errors
	Selection = Result[1].Select();
	If Selection.Next() Then
		Error = Selection.Error;
		Return True;
	EndIf;
	
	// All tasks completed
	Selection = Result[2].Select();
	If Selection.Next() Then
		Return True;
	EndIf;
	
	// Current task
	Selection = Result[3].Select();
	
	If Selection.Next() Then
		
		If (Selection.Action = Enums.ActionsAtCancelInternalPublication.DataImport
			Or Selection.Action = Enums.ActionsAtCancelInternalPublication.DataExport
			Or Selection.Action = Enums.ActionsAtCancelInternalPublication.AdditionalRegistration) Then
			
			FoundSyncTask = Selection.TaskID__;
			Return False;
			
		EndIf;
		
		// Check the task queue on the peer infobase
		
		State = "";
		
		If Selection.LastCheck >= 1 Then
			
			Proxy = Undefined;
			Cancel = False;
			
			ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
				Selection.InfobaseNode, "CheckingStateOfTask", Cancel);
			
			Try
				ProxyInitialization(Proxy, ExchangeSettingsStructure, Cancel, Error);
				State = Proxy.TaskStatus(Selection.TaskID__);
			Except
				// Perhaps, an issue with accessing the peer infobase
				Return False;
			EndTry
		Else
			
			Return False;
			
		EndIf;
			
		If State = "Scheduled" Or State = "Running" Then
			
			BeginTransaction();
			
			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add("InformationRegister.DataExchangeTasksInternalPublication");
				DataLockItem.SetValue("CreationDate", Selection.CreationDate);
				DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
				DataLockItem.SetValue("TaskNumber", Selection.TaskNumber);
				DataLockItem.SetValue("ExchangeID", Selection.ExchangeID);
				DataLockItem.SetValue("TaskID__", Selection.TaskID__);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();
				
				Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
				FillPropertyValues(Record, Selection);
				Record.Read();
				Record.TaskCheckTime = CurrentUniversalDate();
				
				Record.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				Event = NStr("vi = 'Обмен данными.Запись';
							|ru = 'Обмен данными.Запись';
							|en = 'Data exchange.Record'; fa = 'Data exchange.Record';
							|it = 'Обмен данными.Запись';
							|pl = 'Data exchange.Record';
							|tr = 'Обмен данными.Запись'", Common.DefaultLanguageCode());
				
				WriteLogEvent(Event, EventLogLevel.Error, Metadata.InformationRegisters.DataExchangeTasksInternalPublication, , ErrorMessage);
			EndTry;
			
			Return False;
			
		Else
			
			BeginTransaction();
			
			Try
				DataLock = New DataLock;
				DataLockItem = DataLock.Add("InformationRegister.DataExchangeTasksInternalPublication");
				DataLockItem.SetValue("CreationDate", Selection.CreationDate);
				DataLockItem.SetValue("InfobaseNode", Selection.InfobaseNode);
				DataLockItem.SetValue("TaskNumber", Selection.TaskNumber);
				DataLockItem.SetValue("ExchangeID", Selection.ExchangeID);
				DataLockItem.SetValue("TaskID__", Selection.TaskID__);
				DataLockItem.Mode = DataLockMode.Exclusive;
				DataLock.Lock();
				
				Record = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordManager();
				FillPropertyValues(Record, Selection);
				Record.Read();
			
				Template = NStr("vi = 'Chưa tìm thấy nhiệm vụ trao đổi đang hoạt động trong cơ sở trao đổi dữ liệu. 
					|Xem nhật ký sự kiện của cơ sở trao đổi dữ liệu (%1).';
					|ru = 'Не обнаружено активных задач обмена в корреспонденте. 
					|См. журнал регистрации корреспондента (%1).';
					|en = 'Active exchange tasks not found in the peer infobase.
					|For information, see the event log in the peer infobase (%1).'; fa = 'Active exchange tasks not found in the peer infobase.
					|For information, see the event log in the peer infobase (%1).';
					|it = 'Не обнаружено активных задач обмена в корреспонденте. 
					|См. журнал регистрации корреспондента (%1).';
					|pl = 'Active exchange tasks not found in the peer infobase.
					|For information, see the event log in the peer infobase (%1).';
					|tr = 'Muhabirde hiçbir aktif değişim görevi tespit edilmedi. 
					|Muhabir olay günlüğüne bakın (%1).'", Common.DefaultLanguageCode());
			
				Error = StrTemplate(Template, Selection.InfobaseNode);
				
				DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);	
				
				Record.OperationFailed = True;
				Record.Error = Error; 
			
				Record.Write();
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				
				Event = NStr("vi = 'Обмен данными.Запись';
							|ru = 'Обмен данными.Запись';
							|en = 'Data exchange.Record'; fa = 'Data exchange.Record';
							|it = 'Обмен данными.Запись';
							|pl = 'Data exchange.Record';
							|tr = 'Обмен данными.Запись'", Common.DefaultLanguageCode());
				
				WriteLogEvent(Event, EventLogLevel.Error, Metadata.InformationRegisters.DataExchangeTasksInternalPublication, , ErrorMessage);
				
				Return False;
			EndTry;
			
			Return True;
			
		EndIf;
		
	EndIf;
		
	Return True;

EndFunction

Function StructureOfTask()
	
	Task = New Structure;
	Task.Insert("CreationDate");
	Task.Insert("Scenario");
	Task.Insert("InfobaseNode");
	Task.Insert("TaskNumber");
	Task.Insert("ExchangeID");
	Task.Insert("TaskID__");
	Task.Insert("Action");
	Task.Insert("OperationSuccessful");
	Task.Insert("OperationFailed");
	Task.Insert("TaskCheckTime");
	Task.Insert("Mode");
	Task.Insert("CorrespondentDataArea");
	Task.Insert("Parameters");
	
	Return Task;
	
EndFunction

Procedure RunTaskByScenario(Scenario, FirstTask = Undefined) 
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ExchangeSettings.InfobaseNode AS InfobaseNode,
		|	ExchangeSettings.CurrentAction AS CurrentAction
		|FROM
		|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeSettings
		|WHERE
		|	ExchangeSettings.Ref = &Ref
		|	AND NOT ExchangeSettings.InfobaseNode.Code IS NULL
		|
		|ORDER BY
		|	ExchangeSettings.LineNumber";
	
	Query.SetParameter("Ref", Scenario);
	
	Selection = Query.Execute().Select(); // ACC:1328 - Lock not required.
	
	TaskNumber = 1;
	
	Record = StructureOfTask();
	Record.CreationDate = CurrentUniversalDate();
	Record.Scenario = Scenario;
	Record.OperationSuccessful = False;
	Record.OperationFailed = False;
	Record.ExchangeID = String(New UUID);
	
	Set = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordSet();
		
	While Selection.Next() Do
		
		Record.Insert("InfobaseNode", Selection.InfobaseNode);
		
		TransportSettings = ExchangeMessagesTransport.TransportSettings(Selection.InfobaseNode, "SM");	
		
		Record.CorrespondentDataArea = TransportSettings.CorrespondentDataArea;
		Record.Mode = NStr("vi = 'Tự động';
							|ru = 'Автоматический';
							|en = 'Automatic'; fa = 'خودکار';
							|it = 'Автоматический';
							|pl = 'Automatic';
							|tr = 'Otomatik'", Common.DefaultLanguageCode());
		
		If Selection.CurrentAction = Enums.ActionsOnExchange.DataImport Then
			
			//
			Record.Action = Enums.ActionsAtCancelInternalPublication.DataExportPeer;
			Record.TaskID__ = String(New UUID);
			Record.TaskNumber = TaskNumber;
						
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, Record);
			
			If FirstTask = Undefined Then
				FirstTask = Common.CopyRecursive(Record, False);
			EndIf;
			
			TaskNumber = TaskNumber + 1;
			
			//
			Record.Action = Enums.ActionsAtCancelInternalPublication.DataImport;
			Record.TaskID__ = String(New UUID);
			Record.TaskNumber = TaskNumber;
			
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, Record);
			
			TaskNumber = TaskNumber + 1;
			
		Else
			
			//
			Record.Action = Enums.ActionsAtCancelInternalPublication.DataExport;
			Record.TaskID__ = String(New UUID);
			Record.TaskNumber = TaskNumber;
			
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, Record);
			
			If FirstTask = Undefined Then
				FirstTask = Common.CopyRecursive(Record, False);
			EndIf;
			
			TaskNumber = TaskNumber + 1;
			
			//
			Record.Action = Enums.ActionsAtCancelInternalPublication.DataImportPeer;
			Record.TaskID__ = String(New UUID);
			Record.TaskNumber = TaskNumber;
			
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, Record);
			
			TaskNumber = TaskNumber + 1;
			
		EndIf;
		
	EndDo;
	
	Set.Write(False);
	
EndProcedure

Procedure PopulatesTasksForManualExchange(InfobaseNode, ExchangeID, FirstTask, ExportAddition)
	
	Record = StructureOfTask();
	Record.CreationDate = CurrentUniversalDate();
	Record.InfobaseNode = InfobaseNode;
	Record.OperationSuccessful = False;
	Record.OperationFailed = False;
	Record.ExchangeID = ExchangeID;
	
	TransportSettings = ExchangeMessagesTransport.TransportSettings(InfobaseNode, "SM");
	
	Record.CorrespondentDataArea = TransportSettings.CorrespondentDataArea;
	Record.Mode = NStr("vi = 'Thủ công';
						|ru = 'Ручной';
						|en = 'Manual'; fa = 'دستی';
						|it = 'Ручной';
						|pl = 'Manual';
						|tr = 'Manuel'", Common.DefaultLanguageCode());
		
	Set = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordSet();
	
	TaskNumber = 1;
			
	// Receive data (UploadDataInt)
	Record.Action = Enums.ActionsAtCancelInternalPublication.DataExportPeer;
	Record.TaskID__ = String(New UUID);
	Record.TaskNumber = TaskNumber;
	NewRecord = Set.Add();
	FillPropertyValues(NewRecord, Record);
	
	TaskNumber = TaskNumber + 1;
			
	FirstTask = Common.CopyRecursive(Record, False);
	
	// Receive data (Load)
	Record.Action = Enums.ActionsAtCancelInternalPublication.DataImport;
	Record.TaskID__ = String(New UUID);
	Record.TaskNumber = TaskNumber;
	NewRecord = Set.Add();
	FillPropertyValues(NewRecord, Record);
	
	TaskNumber = TaskNumber + 1;
	
	// Additional registration
	If ExportAddition <> Undefined Then

		Record.Action = Enums.ActionsAtCancelInternalPublication.AdditionalRegistration;
		Record.TaskID__ = String(New UUID);
		Record.TaskNumber = TaskNumber;
		NewRecord = Set.Add();
		FillPropertyValues(NewRecord, Record);
		NewRecord.Parameters = New ValueStorage(ExportAddition);
		
		TaskNumber = TaskNumber + 1;
	
	EndIf;
		
	// Send data (Upload0)
	Record.Action = Enums.ActionsAtCancelInternalPublication.DataExport;
	Record.TaskID__ = String(New UUID);
	Record.TaskNumber = TaskNumber;
	NewRecord = Set.Add();
	FillPropertyValues(NewRecord, Record);
	
	TaskNumber = TaskNumber + 1;
		
	// Send data (DownloadDataInt)
	Record.Action = Enums.ActionsAtCancelInternalPublication.DataImportPeer;
	Record.TaskID__ = String(New UUID);
	Record.TaskNumber = TaskNumber;	
	NewRecord = Set.Add();
	FillPropertyValues(NewRecord, Record);	
			
	Set.Write(False);
	
EndProcedure

Procedure CallingBack(ExchangePlanName, InfobaseNodeCode, TaskID__, Error = "")
	
	Node = ExchangePlans[ExchangePlanName].FindByCode(InfobaseNodeCode);
	
	TransportSettings = ExchangeMessagesTransport.TransportSettings(Node, "SM");
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	TransportSettingsWS = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(TransportSettings.CorrespondentEndpoint);

	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", TransportSettingsWS.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", TransportSettingsWS.WSUserName);
	ConnectionParameters.Insert("Password", TransportSettingsWS.WSPassword);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, Error);
	
	If Proxy = Undefined Then
		ExceptionText = NStr("vi = 'Không thể tạo kết nối đến cơ sở trao đổi dữ liệu';
							|ru = 'Не удалось создать подключение к базе корреспонденту';
							|en = 'Couldn''t connect to the peer infobase'; fa = 'Couldn''t connect to the peer infobase';
							|it = 'Не удалось создать подключение к базе корреспонденту';
							|pl = 'Couldn''t connect to the peer infobase';
							|tr = 'Muhabir veritabanıyla bağlantı oluşturulamadı'",
			Common.DefaultLanguageCode());
		Raise ExceptionText;
	EndIf;
	
	Try
		Proxy.Callback(TaskID__, Error, TransportSettings.CorrespondentDataArea);
	Except
		ErrorPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Raise ErrorPresentation;	
	EndTry;

EndProcedure

Procedure ExecuteTask(Task, ExchangeParameters, Cancel) Export
	
	// Syncing might be canceled by user.
	If Task.OperationFailed Then
		Cancel = True;
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	CheckTaskLock(Task, Cancel);
	If Cancel = True Then
		
		Return;
		
	EndIf;
	
	Proxy = Undefined;
	ExchangeSettingsStructure = Undefined;
	
	Error = "";
	Node = Task.InfobaseNode;
	Action = Task.Action;
	CorrespondentDataArea = Task.CorrespondentDataArea;
	
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(Node, Action, Cancel);
	ProxyInitialization(Proxy, ExchangeSettingsStructure, Cancel, Error);
	
	Template = NStr("vi = 'Thực hiện bước của kịch bản đồng bộ hóa.
                   |SốThứTự: %1, Ứng dụng: %2, Hoạt động: %3, Chế độ: %4.';
                   |ru = 'Выполнение шага сценария синхронизации.
                   |ПорядковыйНомер: %1, Приложение: %2, Действие: %3, Режим: %4.';
                   |en = 'Running a synchronization scenario step.
                   |SequenceNumber: %1; App: %2; Action: %3; Mode: %4.'; fa = 'Running a synchronization scenario step.
                   |SequenceNumber: %1; App: %2; Action: %3; Mode: %4.';
                   |it = 'Выполнение шага сценария синхронизации.
                   |ПорядковыйНомер: %1, Приложение: %2, Действие: %3, Режим: %4.';
                   |pl = 'Running a synchronization scenario step.
                   |SequenceNumber: %1; App: %2; Action: %3; Mode: %4.';
                   |tr = 'Bir senkronizasyon komut dosyası adımı yürütülüyor.
                   |Sıra Numarası: %1, Uygulama: %2, Eylem: %3, Mod: %4.'");
	
	Comment = StrTemplate(Template, Task.TaskNumber, Task.CorrespondentDataArea, Task.Action, Task.Mode); 
		
	WriteLogEvent(DataExchangeSaaS.DataSyncronizationLogEvent(),
		EventLogLevel.Information, , , Comment);
	
	If Action = Enums.ActionsAtCancelInternalPublication.DataExportPeer Then
		
		RunTaskExportDataPeer(Task, Proxy, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, Error);
		
	ElsIf Action = Enums.ActionsAtCancelInternalPublication.DataImport Then
		
		ImportDataImportTask(Task, Proxy, ExchangeParameters, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, Error);
		MarkTaskAsCompleted(Task, Error);
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
	
		DeleteIssuesWhenErrorOccurs(Cancel, Task);
		
	ElsIf Action = Enums.ActionsAtCancelInternalPublication.DataExport Then
		
		PerformTaskDataExport(Task, Proxy, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, Error);
		MarkTaskAsCompleted(Task, Error);
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
								
	ElsIf Action = Enums.ActionsAtCancelInternalPublication.DataImportPeer Then
		
		RunTaskImportDataPeer(Task, Proxy, ExchangeParameters, ExchangeSettingsStructure, CorrespondentDataArea, Cancel, Error)
		
	ElsIf Action = Enums.ActionsAtCancelInternalPublication.AdditionalRegistration Then
		
		PerformTaskAdditionalRegistration(Task, Cancel, Error);	
		MarkTaskAsCompleted(Task, Error);
		
	EndIf;
				
EndProcedure

Procedure RunTaskExportDataPeer(Task, Proxy, ExchangeSettingsStructure, DataArea, Cancel, Error)
	
	If Cancel Then
		Return;
	EndIf;
	
	Try
		
		Proxy.UploadDataInt(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			Task.TaskID__,
			DataArea);
								
	Except
		
		Error = StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1%2';
								|ru = 'Ошибка в базе-корреспонденте:%1 %2';
								|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
								|it = 'Errore nella base corrispondente: %1 %2';
								|pl = 'Błąd w bazie korespondencie:%1 %2';
								|tr = 'Muhabir tabanındaki hata: %1%2'"),
			Chars.LF,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Cancel = True;
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			
	EndTry;

EndProcedure

Procedure ImportDataImportTask(Task, Proxy, ExchangeParameters, ExchangeSettingsStructure, DataArea, Cancel, Error)
	
	If Cancel Then
		Return;
	EndIf;

	Try
			
		UIDOfTheMessageFile = New UUID(ExchangeParameters.TaskIDPrev);
		FileExchangeMessages = DataExchangeWebService.GetFileFromStorageInService(
			Proxy, UIDOfTheMessageFile, ExchangeSettingsStructure.InfobaseNode, 
			1024, DataArea);
		
	Except
		
		Error = StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1%2';
								|ru = 'Ошибка в базе-корреспонденте:%1 %2';
								|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
								|it = 'Errore nella base corrispondente: %1 %2';
								|pl = 'Błąd w bazie korespondencie:%1 %2';
								|tr = 'Muhabir tabanındaki hata: %1%2'"), 
			Chars.LF, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
	
	EndTry;
		
	If ExchangeResultCompletedWithError(ExchangeSettingsStructure, Cancel, Error) Then
		Return;
	EndIf;
	
	Try
		
		DataExchangeServer.ReadMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages);
		
	Except
		
		Error = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;

	EndTry;
	
	If ExchangeResultCompletedWithError(ExchangeSettingsStructure, Cancel, Error) Then
		Return;
	EndIf;
	
	MessageRead = DataExchangeServer.ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult);
	
	If MessageRead And Common.SeparatedDataUsageAvailable() Then
		InformationRegisters.DataSyncEventHandlers.ExecuteHandlers(ExchangeSettingsStructure.InfobaseNode, "AfterGetData");
	EndIf;
	
	Try
		If Not IsBlankString(FileExchangeMessages) Then
			DeleteFiles(FileExchangeMessages);
		EndIf;
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;

EndProcedure

Procedure PerformTaskDataExport(Task, Proxy, ExchangeSettingsStructure, DataArea, Cancel, Error)

	If Cancel Then
		Return;
	EndIf;

	TempFilesStorageDirectory = DataExchangeServer.TempFilesStorageDirectory();
	
	TempDirectory = CommonClientServer.GetFullFileName(TempFilesStorageDirectory, "{" + String(New UUID) + "}");
	CreateDirectory(TempDirectory);
	
	FileExchangeMessages = CommonClientServer.GetFullFileName(TempDirectory, DataExchangeServer.UniqueExchangeMessageFileName());
	
	Try
		DataExchangeServer.WriteMessageWithNodeChanges(ExchangeSettingsStructure, FileExchangeMessages);
	Except
		Cancel = True;
		Error = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
	EndTry;
	
	If ExchangeResultCompletedWithError(ExchangeSettingsStructure, Cancel, Error) Then
		Return;
	EndIf;
		
	If DataExchangeServer.ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) And Not Cancel Then
		
		Try
			
			FileID = Task.TaskID__;
			
			DataExchangeWebService.PutFileInStorageInService(Proxy, FileExchangeMessages, 1024,
				FileID, DataArea); 
				
			If ExchangeResultCompletedWithError(ExchangeSettingsStructure, Cancel, Error) Then
				Return;
			EndIf;
			
		Except
			
			Cancel = True;
			Error = StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1%2';
									|ru = 'Ошибка в базе-корреспонденте:%1 %2';
									|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
									|it = 'Errore nella base corrispondente: %1 %2';
									|pl = 'Błąd w bazie korespondencie:%1 %2';
									|tr = 'Muhabir tabanındaki hata: %1%2'"),
				Chars.LF,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			
		EndTry;
		
	EndIf;
	
	Try
		DeleteFiles(TempDirectory);
	Except
		WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure RunTaskImportDataPeer(Task, Proxy, ExchangeParameters, ExchangeSettingsStructure, DataArea, Cancel, Error)
	
	If Cancel Then
		Return;
	EndIf;

	Try
		
		Proxy.DownloadDataInt(
			ExchangeSettingsStructure.ExchangePlanName,
			ExchangeSettingsStructure.CurrentExchangePlanNodeCode1,
			Task.TaskID__,
			ExchangeParameters.TaskIDPrev,
			DataArea);
		
	Except
		
		Cancel = True;
		
		Error = StrTemplate(NStr("vi = 'Lỗi trong cơ sở trao đổi dữ liệu:%1 %2';
								|ru = 'Ошибка в базе-корреспонденте:%1 %2';
								|en = 'Peer infobase error: %1 %2'; fa = 'Peer infobase error: %1 %2';
								|it = 'Errore nella base corrispondente: %1 %2';
								|pl = 'Błąd w bazie korespondencie:%1 %2';
								|tr = 'Muhabir tabanındaki hata: %1%2'"),
			Chars.LF,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		
	EndTry;

EndProcedure	

Procedure PerformTaskAdditionalRegistration(Task, Cancel, Error)
	
	If Cancel Then
		Return;
	EndIf;

	ExportAddition = Task.Parameters.Get();
	
	ObjectExportAddition = DataProcessors.InteractiveExportChange.Create();
	FillPropertyValues(ObjectExportAddition, ExportAddition, , "AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	ObjectExportAddition.AllDocumentsFilterComposer.LoadSettings(ExportAddition.AllDocumentsSettingFilterComposer);
		
	DataExchangeServer.FillValueTable(ObjectExportAddition.AdditionalRegistration, ExportAddition.AdditionalRegistration);
	DataExchangeServer.FillValueTable(ObjectExportAddition.AdditionalNodeScenarioRegistration, ExportAddition.AdditionalNodeScenarioRegistration);
	
	If Not ExportAddition.AllDocumentsComposer = Undefined Then
		ObjectExportAddition.AllDocumentsComposerAddress = PutToTempStorage(ExportAddition.AllDocumentsComposer);
	EndIf;
	
	// Saving export addition settings.
	DataExchangeServer.InteractiveExportChangeSaveSettings(ObjectExportAddition, 
		DataExchangeServer.ExportAdditionSettingsAutoSavingName());
	
	// Register additional data.
	Try
		DataExchangeServer.InteractiveExportChangeRegisterAdditionalData(ObjectExportAddition);
	Except
		
		Cancel = True;
		
		Information = ErrorInfo();
		
		Error = NStr("vi = 'Đã xảy ra lỗi khi thêm dữ liệu để kết xuất:';
					|ru = 'Возникла проблема при добавлении данных к выгрузке:';
					|en = 'An issue occurred while adding data to export:'; fa = 'An issue occurred while adding data to export:';
					|it = 'Si è verificato un problema durante l''aggiunta di dati per upload:';
					|pl = 'Wystąpił problem podczas dodawania danych do ładowania:';
					|tr = 'Veriler dışa aktarmaya eklendiğinde bir sorun oluştu:'") 
			+ Chars.LF + ErrorProcessing.BriefErrorDescription(Information)
			+ Chars.LF + NStr("vi = 'Hãy thay đổi điều kiện lọc.';
								|ru = 'Измените условия отбора.';
								|en = 'Edit filter criteria.'; fa = 'Edit filter criteria.';
								|it = 'Modificare le condizioni di filtro.';
								|pl = 'Zmień warunki filtru.';
								|tr = 'Filtre koşullarını değiştirin'");
			
		WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(Information));
			
	EndTry;
	
EndProcedure

Procedure CheckTaskLock(Task, Cancel)
	Var TaskID__, CreationDate, InfobaseNode, TaskNumber, ExchangeID, Scenario;
	
	If TypeOf(Task) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	Try
		
		RegisterKey = InformationRegisters.DataExchangeTasksInternalPublication.CreateRecordKey(Task);
		LockDataForEdit(RegisterKey);
		
	Except
		
		Cancel = True;
		TextTemplate1 = NStr("vi = 'Nhiệm vụ có ID [%1] bị phong tỏa.
			|Có lẽ, nhiệm vụ đang ở trạng thái thực hiện.
			|	Ngày tạo: %2
			|	Nút CSTT: %3
			|	Số: %4
			|	ID Trao đổi: %5
			|	Kịch bản: %6';
			|ru = 'Задача с идентификатором [%1] заблокирована.
			|Вероятно она находится в состоянии выполнения.
			|	Дата создания: %2
			|	Узел ИБ: %3
			|	Номер: %4
			|	Идентификатор Обмена: %5
			|	Сценарий: %6';
			|en = 'Task with ID [%1] is locked.
			|Perhaps, it is still in progress.
			|	Created on: %2
			|	Infobase node: %3
			|	Number: %4
			|	Exchange ID: %5
			|	Scenario: %6'; fa = 'Task with ID [%1] is locked.
			|Perhaps, it is still in progress.
			|	Created on: %2
			|	Infobase node: %3
			|	Number: %4
			|	Exchange ID: %5
			|	Scenario: %6';
			|it = 'Task with ID [%1] is locked.
			|Perhaps, it is still in progress.
			|	Created on: %2
			|	Infobase node: %3
			|	Number: %4
			|	Exchange ID: %5
			|	Scenario: %6';
			|pl = 'Task with ID [%1] is locked.
			|Perhaps, it is still in progress.
			|	Created on: %2
			|	Infobase node: %3
			|	Number: %4
			|	Exchange ID: %5
			|	Scenario: %6';
			|tr = '[%1] tanımlayıcılı görev engellendi. 
			|Büyük ihtimalle yürütme işleminde kaldı.
			|	 Oluşturulma tarihi: %2
			|	Infobase düğümü: %3
			|	Sayı: %4
			|	Değişim Kimliği: %5
			|	Senaryo: %6'", Common.DefaultLanguageCode());
		
		Task.Property("TaskID__", TaskID__);
		Task.Property("CreationDate", CreationDate);
		Task.Property("InfobaseNode", InfobaseNode);
		Task.Property("TaskNumber", TaskNumber);
		Task.Property("ExchangeID", ExchangeID);
		Task.Property("Scenario", Scenario);
		
		Comment = StrTemplate(TextTemplate1, TaskID__, CreationDate,
			InfobaseNode, TaskNumber, ExchangeID, Scenario);
			
		EventName = DataExchangeSaaS.DataSyncronizationLogEvent();
		WriteLogEvent(EventName, EventLogLevel.Information, , , Comment);
		
	EndTry;
	
EndProcedure

#EndRegion

#Region NodeFormSetup

Procedure SetFuncOptionsForNode(Form)

	SetPrivilegedMode(True);
	
	Node = Form.Object.Ref;
	
	TransportID = Undefined;
	TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(Node, TransportID);
	
	UseScenarios = (TransportID = "SM" And TransportSettings.InternalPublication)
		Or TransportID = "WS"
		Or TransportID = "HTTP";
	
	UseConnectionSettings = 
		TransportID = "SM" And TransportSettings.InternalPublication
		Or TransportID = "WS" 
		Or TransportID = "PassiveMode";
	
	BeginTransaction();

	Try
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.CommonInfobasesNodesSettings");
		DataLockItem.SetValue("InfobaseNode", Node);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();

		RecordingSettings = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordManager();
		RecordingSettings.InfobaseNode = Node;
		RecordingSettings.Read();

		If RecordingSettings.UseScenariosInSaaS <> UseScenarios
			Or RecordingSettings.UseConnectionsSettingsInSaaS <> UseConnectionSettings Then

			RecordingSettings.UseScenariosInSaaS = UseScenarios;
			RecordingSettings.UseConnectionsSettingsInSaaS = UseConnectionSettings;

			RecordingSettings.Write();

		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();

		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

		Event = NStr("vi = 'Обмен данными.Установка функциональных опций';
					|ru = 'Обмен данными.Установка функциональных опций';
					|en = 'Data exchange.Set functional options'; fa = 'Data exchange.Set functional options';
					|it = 'Обмен данными.Установка функциональных опций';
					|pl = 'Data exchange.Set functional options';
					|tr = 'Обмен данными.Установка функциональных опций'", Common.DefaultLanguageCode());

		WriteLogEvent(Event, EventLogLevel.Error,
			Metadata.InformationRegisters.CommonInfobasesNodesSettings, , ErrorMessage);
	EndTry;

	Form.SetFormFunctionalOptionParameters(New Structure("GeneralSettingsNodes", Node))
	
EndProcedure

Procedure SetUpFormElementsForMigrationToWS(Form)

	SetPrivilegedMode(True);
	
	Items = Form.Items;
	Node = Form.Object.Ref;
	
	TransportID = Undefined;
	TransportSettings = ExchangeMessagesTransport.DefaultTransportSettings(Node, TransportID);
	
	ThisIsExchangeThroughInternalPublication = TransportID = "SM" And TransportSettings.InternalPublication;
	HasExchangeAdministrationManage_3_0_1_1 = HasInNodeExchangeAdministrationManage_3_0_1_1(Node) = True;
		
	If Not Users.IsFullUser()
		Or Node.IsEmpty()
		Or	ThisIsExchangeThroughInternalPublication
		Or Not HasExchangeAdministrationManage_3_0_1_1
		Or Not DataExchangeCached.IsXDTOExchangePlan(Node)
		Or Not DataExchangeServer.SynchronizationSetupCompleted(Node) Then
		
		CommonClientServer.SetFormItemProperty(
			Form.Items,
			"FormCommonCommandMigrationToExchangeOverInternetWizardInternalPublication",
			"Visible",
			False);
			
		Return; 
				 
	EndIf;
	
	Items = Form.Items;
	
	CommonClientServer.SetFormItemProperty(
		Form.Items,
		"FormCommonCommandMigrationToExchangeOverInternetWizardInternalPublication",
		"LocationInCommandBar",
		ButtonLocationInCommandBar.InAdditionalSubmenu);
		
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Settings.InfobaseNode AS InfobaseNode,
		|	Settings.MigrationToWebService_Step AS MigrationToWebService_Step
		|FROM
		|	InformationRegister.CommonInfobasesNodesSettings AS Settings
		|WHERE
		|	Settings.InfobaseNode = &Node";
	
	Query.SetParameter("Node", Node);
		
	Selection = Query.Execute().Select();
								
	IsMigrationToWebServiceStillInProgress = Selection.Next() And Selection.MigrationToWebService_Step > 0;
	ShouldMutePromptToMigrateToWebService = DataExchangeInternalPublicationServerCall.SettingFlagShouldMutePromptToMigrateToWebService(Node);
	PanelText = "";
	
	If IsMigrationToWebServiceStillInProgress Then
		
		PanelText = 
			NStr("vi = '<br>Chưa hoàn tất chuyển sang trao đổi qua Internet (web-sevice). 
                  |<br> 
                  |<br>Hãy sử dụng <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>trợ giúp</a> để hoàn tất chuyển đổi.';
                  |ru = '<br>Не завершен переход на обмен через Интернет (веб-сервис). 
                  |<br> 
                  |<br>Воспользуйтесь <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>помощником</a> для завершения перехода.';
                  |en = '<br>You have not completely switched to exchange over the Internet (web service). 
                  |<br> 
                  |<br>Use the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>wizard</a> to complete the operation.'; fa = '<br>You have not completely switched to exchange over the Internet (web service). 
                  |<br> 
                  |<br>Use the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>wizard</a> to complete the operation.';
                  |it = '<br>Не завершен переход на обмен через Интернет (веб-сервис). 
                  |<br> 
                  |<br>Воспользуйтесь <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>помощником</a> для завершения перехода.';
                  |pl = '<br>You have not completely switched to exchange over the Internet (web service). 
                  |<br> 
                  |<br>Use the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>wizard</a> to complete the operation.';
                  |tr = '<br>Internet (web servisi) üzerinden değişime geçiş tamamlanmadı. 
                  |<br> 
                  |<br> Geçişi tamamlamak için <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация> sihirbazını</a> kullanın.'"); 
			
	ElsIf Not ShouldMutePromptToMigrateToWebService Then
												
		PanelText = 
			NStr("vi = 'Đối với đồng bộ này, có tính năng tùy chỉnh trao đổi qua Internet (web-service).
                  |<br>Điều này sẽ tăng tốc độ trao đổi và thiết lập lịch biểu đồng bộ linh hoạt hơn. 
                  |<br>Để chuyển sang trao đổi theo công cụ web-service, hãy sử dụng <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>trợ giúp chuyển đổi</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Không nên chuyển sang web-service nữa</a>. (Có thể gọi ra trợ giúp chuyển qua menu <b>Hơn nữa<b>)';
                  |ru = 'Для данной синхронизации есть возможность настроить обмен через Интернет (веб-сервис). 
                  |<br>Это позволит ускорить обмен и более гибко настроить график синхронизации. 
                  |<br>Для перехода на обмен посредством веб-сервиса, воспользуйтесь <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>помощником перехода</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Больше не предлагать перейти на веб-сервис</a>. (Вызвать помощник перехода можно через меню <b>Еще<b>)';
                  |en = 'For this synchronization, you can configure exchange over the Internet (web service).
                  |<br>It allows you to speed up the exchange and set up a more flexible synchronization schedule.
                  |<br>To switch to exchange using a web service, use the switch to the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>Internet connection wizard</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Do not offer to switch to a web service again</a>. You can call the wizard in the <b>More<b> menu.'; fa = 'For this synchronization, you can configure exchange over the Internet (web service).
                  |<br>It allows you to speed up the exchange and set up a more flexible synchronization schedule.
                  |<br>To switch to exchange using a web service, use the switch to the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>Internet connection wizard</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Do not offer to switch to a web service again</a>. You can call the wizard in the <b>More<b> menu.';
                  |it = 'Для данной синхронизации есть возможность настроить обмен через Интернет (веб-сервис). 
                  |<br>Это позволит ускорить обмен и более гибко настроить график синхронизации. 
                  |<br>Для перехода на обмен посредством веб-сервиса, воспользуйтесь <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>помощником перехода</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Больше не предлагать перейти на веб-сервис</a>. (Вызвать помощник перехода можно через меню <b>Еще<b>)';
                  |pl = 'For this synchronization, you can configure exchange over the Internet (web service).
                  |<br>It allows you to speed up the exchange and set up a more flexible synchronization schedule.
                  |<br>To switch to exchange using a web service, use the switch to the <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>Internet connection wizard</a>.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Do not offer to switch to a web service again</a>. You can call the wizard in the <b>More<b> menu.';
                  |tr = 'Bu senkronizasyon için İnternet (web servisi) üzerinden değişim ayarlamak mümkündür.
                  |<br>Bu, değişimi hızlandıracak ve senkronizasyon programının daha esnek bir şekilde ayarlanmasını sağlayacaktır.
                  |<br>Web servisi aracılığıyla değişim yapmak için </a>geçiş <a href=ФормаПомощникПереходаНаИнтернетВнутренняяПубликация>sihirbazını kullanın.
                  |<br><br>
                  |<a href=НеПредлагатьПерейтиНаВебСервис>Web </a>servisine gitmeyi bir daha önerme. (Geçiş sihirbazını <b>Daha fazla<b> menüsünden çağırabilirsiniz)'");
									
	EndIf;
	
	If Not IsBlankString(PanelText) Then
		
		TagName = "InfoAboutMigrationToWebService"; 
		
		Group = Items.Insert(TagName, Type("FormGroup"), Form, Items.FormCommandBar);
		Group.Kind 			= FormGroupType.UsualGroup;
		Group.Group 	= ChildFormItemsGroup.AlwaysHorizontal;
		Group.BackColor 	= WebColors.PaleGreen;
		Group.ShowTitle = False;
		
		IndentDecoration = Items.Add("Indent" + TagName, Type("FormDecoration"), Group);
		IndentDecoration.Kind = FormDecorationType.Label;
		
		PictureDecoration = Items.Add("Picture" + TagName, Type("FormDecoration"), Group);
		PictureDecoration.Kind 		= FormDecorationType.Picture;
		PictureDecoration.Picture 	= PictureLib.Information;
		PictureDecoration.Height 	= 3;
		PictureDecoration.Width 	= 5;
		PictureDecoration.PictureSize = PictureSize.Proportionally;
		
		FormattedDoc = New FormattedDocument;
		FormattedDoc.SetHTML("<html>" + PanelText + "</html>", New Structure);
		
		LabelDecoration = Items.Add("Label" + TagName, Type("FormDecoration"), Group);
		LabelDecoration.Kind 						= FormDecorationType.Label;
		LabelDecoration.AutoMaxWidth 	= False;
		LabelDecoration.HorizontalStretch 	= True;
		LabelDecoration.Title 					= FormattedDoc.GetFormattedString();
		LabelDecoration.SetAction("URLProcessing", "Attachable_URLProcessing");
	
	EndIf;
		
EndProcedure

#EndRegion

#Region Other

Function HasInNodeExchangeAdministrationManage_3_0_1_1(Node)
	
	Available = InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Node, "HasExchangeAdministrationManage_3_0_1_1");
	
	Return Available = True;
		
EndFunction

Procedure ProxyInitialization(Proxy, ExchangeSettingsStructure, Cancel, Error)
	
	If Cancel Then
		Return;
	EndIf;
		
	TransportParameters = ExchangeMessagesTransport.TransportSettings(ExchangeSettingsStructure.InfobaseNode, "SM");
	
	ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
	TransportSettingsWS = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(TransportParameters.CorrespondentEndpoint);

	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", TransportSettingsWS.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", TransportSettingsWS.WSUserName);
	ConnectionParameters.Insert("Password", TransportSettingsWS.WSPassword);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, Error);
	
	If Proxy = Undefined Then
		Cancel = True;
	EndIf;
	
	If Cancel Then
		DataExchangeServer.WriteEventLogDataExchange(Error, ExchangeSettingsStructure, True);
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
	EndIf;

EndProcedure

Function EventLogEventScenarioDisabled()
	
	Return NStr("vi = 'Trao đổi dữ liệu. Tắt sử dụng kịch bản';
				|ru = 'Обмен данными.Отключение сценария';
				|en = 'Data exchange.Disable scenario'; fa = 'Data exchange.Disable scenario';
				|it = 'Scambio dati.Disattivazione scenario';
				|pl = 'Wymiana danych.Wyłączenie scenariusza';
				|tr = 'Veri değişimi.Senaryoyu devre dışı bırak'", Common.DefaultLanguageCode());
	
EndFunction

Function ExchangeResultCompletedWithError(ExchangeSettingsStructure, Cancel, Error)
	
	If ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error
		Or ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport Then
		
		Cancel = True;
		Error = ExchangeSettingsStructure.ErrorMessageString;
		
		Return True;
		
	EndIf;
	
	Return False;
	
EndFunction

Procedure DeleteIssuesWhenErrorOccurs(Cancel, Task)
	
	If Cancel Then
		FilterOfTasks = New Structure;
		FilterOfTasks.Insert("Key", Task.TaskID__);
		
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		
		FoundJobs = ModuleJobsQueue.GetJobs(FilterOfTasks);
		
		If FoundJobs.Count() Then
			DataArea   = SessionParameters["DataAreaValue"];
			FoundTask = FoundJobs[0];
			
			ModuleJobsQueue.DeleteJob(FoundTask.Id);
			
			ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
			ModuleDataExchangeInternalPublication.CancelTaskQueue(FoundTask.Id, Undefined, String(Task.ExchangeID), DataArea);
		EndIf;
	EndIf;
	
EndProcedure

Function ExecuteScheduledJobExchangeScenario(Scenario)
	
	Query = New Query;
	Query.Text = "SELECT
	|	1
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeSettings
	|WHERE
	|	ExchangeSettings.Ref = &Ref
	|	AND ExchangeSettings.TransportID LIKE ""HTTP""
	|
	|UNION ALL
	|
	|SELECT
	|	1
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenariosExchangeSettings
	|WHERE
	|	DataExchangeScenariosExchangeSettings.TransportID LIKE ""WS""
	|	AND DataExchangeScenariosExchangeSettings.Ref = &Ref";
	
	Query.SetParameter("Ref", Scenario);
	
	QueryResult = Query.Execute();
	
	Result = False;
	
	If Not QueryResult.IsEmpty() Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
