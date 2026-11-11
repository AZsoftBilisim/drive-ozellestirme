#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Calculates and fills in the register.
//
// Parameters:
//  Stages - Array of DocumentRef.ProductionStage2_2, DocumentRef.ProductionStage2_2 - documents for which
//    you need to perform the calculation.
//  ShiftJobs - Array of DocumentRef.ShiftTask, DocumentRef.ShiftTask - the shift task in
//    the context of which the action is performed. If it is not transmitted (or an empty link is transmitted), then it is assumed that
//    the calculation is related to the recalculation of the unassigned part (base) at this stage. Used to lock data.
//
Procedure CalculateOperations(Stages, ShiftJobs = Undefined) Export
	
	If ShiftJobs = Undefined Then
		ArrayOfTasks = CommonClientServer.ValueInArray(Documents.ShiftTask.EmptyRef());
	Else
		ArrayOfTasks = ?(TypeOf(ShiftJobs) = Type("Array"),
			ShiftJobs,
			CommonClientServer.ValueInArray(ShiftJobs));
		If ArrayOfTasks.Find(Documents.ShiftTask.EmptyRef()) = Undefined Then
			ArrayOfTasks.Add(Documents.ShiftTask.EmptyRef());
		EndIf;
	EndIf;
	
	ArrayOfStages = ?(TypeOf(Stages) = Type("Array"), Stages, CommonClientServer.ValueInArray(Stages));
	
	LockSource = New ValueTable;
	LockSource.Columns.Add("ShiftTask", New TypeDescription("DocumentRef.ShiftTask"));
	LockSource.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	
	For Each Job In ArrayOfTasks Do
		For Each Stage In ArrayOfStages Do
			NewRow = LockSource.Add();
			NewRow.ShiftTask = Job;
			NewRow.Stage = Stage;
		EndDo;
	EndDo;
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("ShiftTask", "ShiftTask");
		LockItem.UseFromDataSource("Stage", "Stage");
		
		LockItem = DataLock.Add("InformationRegister.QueueOfProductionOperations");
		LockItem.Mode = DataLockMode.Shared;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("Stage", "Stage");
		
		LockItem = DataLock.Add("Document.ProductionOperation2_2");
		LockItem.Mode = DataLockMode.Shared;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("Stage", "Stage");
		
		DataLock.Lock();
		
		Query = New Query(
			"SELECT DISTINCT
			|	Operations.Stage AS Stage
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Operations
			|WHERE
			|	Operations.Stage IN (&Stages)
			|	AND Operations.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)");
		Query.SetParameter("Stages", ArrayOfStages);
		StagesWithEmptyTask = Query.Execute().Unload().UnloadColumn("Stage");
		
		For Each Stage In ArrayOfStages Do
			Operations = CalculateRegisterData(Stage);
			Operations.Sort("ShiftTask");
			MaxIndex = Operations.Count() - 1;
			ThereAreOperationsOfOperationsWithEmptyJob = False;
			
			Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
			
			For IndexOf = 0 To MaxIndex Do
				Operation = Operations[IndexOf];
				FillPropertyValues(Set.Add(), Operation);
				
				If IndexOf = MaxIndex
					Or Operation.ShiftTask <> Operations[IndexOf + 1].ShiftTask Then
					Set.Filter.ShiftTask.Set(Operation.ShiftTask);
					Set.Filter.Stage.Set(Stage);
					Set.AdditionalProperties.Insert(KeyIsNotToControlDataWhenWriting());
					Set.Write();
					
					Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
					
					If Not ValueIsFilled(Operation.ShiftTask) Then
						ThereAreOperationsOfOperationsWithEmptyJob = True;
					EndIf;
				EndIf;
			EndDo;
			
			If Not ThereAreOperationsOfOperationsWithEmptyJob
				And StagesWithEmptyTask.Find(Stage) <> Undefined Then
				Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
				Set.Filter.ShiftTask.Set(Documents.ShiftTask.EmptyRef());
				Set.Filter.Stage.Set(Stage);
				Set.AdditionalProperties.Insert(KeyIsNotToControlDataWhenWriting());
				Set.Write();
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể tính toán các giao dịch để tạo công việc theo ca';
					|ru = 'Не удалось рассчитать операции к созданию сменных заданий';
					|en = 'Cannot calculate operations to create shift tasks'; fa = 'Cannot calculate operations to create shift tasks';
					|it = 'Non è stato possibile calcolare le operazioni per creare assegnazioni di turno';
					|pl = 'Nie można obliczyć operacji, aby utworzyć zadania zmianowe';
					|tr = 'Vardiya işlerin oluşturulmasına yönelik işlemler hesaplanamadı'");
		
	EndTry;
	
EndProcedure

// Assigns operations to performers, work centers, and types of RC.
//
// Parameters:
//  OperationKeys - Array of InformationRegisterRecordKey.OperationsToCreateShiftTasks
//  Parameters - Structure - destination parameters (composition See ParametersForAssigningOperations
//                          ).
//
Procedure AssignOperations(OperationKeys, Parameters) Export
	
	BeginTransaction();
	
	Try
		
		Order = CurrentUniversalDateInMilliseconds();
		Operations = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet().UnloadColumns();
		
		For Each Var_Key In OperationKeys Do
			NewRow = Operations.Add();
			FillPropertyValues(NewRow, Var_Key);
			NewRow.Order = Order;
			
			Order = Order + 1;
		EndDo;
		
		LockSource = Operations.Copy(, "ShiftTask, Stage");
		LockSource.GroupBy("ShiftTask, Stage");
		For Each Stage In LockSource.UnloadColumn("Stage") Do
			NewRow = LockSource.Add();
			NewRow.ShiftTask = Parameters.Dimensions.ShiftTask;
			NewRow.Stage = Stage;
		EndDo;
		
		DataLock = New DataLock;
			
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("ShiftTask", "ShiftTask");
		LockItem.UseFromDataSource("Stage", "Stage");
		
		DataLock.Lock();
		
		TempTablesManager = New TempTablesManager;
		
		CreateVTOperationAssignment(TempTablesManager, Operations, Parameters);
		
		ChangeOperations(TempTablesManager);
		
		QueueCalculationParameters = InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters();
		QueueCalculationParameters.CalculateShiftTasks = False;
		For Each Var_Key In OperationKeys Do
			InformationRegisters.QueueOfProductionOperations.RecalculateQueue(Var_Key, QueueCalculationParameters);
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể phân công giao dịch';
					|ru = 'Не удалось назначить операции';
					|en = 'Cannot assign operations'; fa = 'Cannot assign operations';
					|it = 'Non è stato possibile assegnare le operazioni';
					|pl = 'Nie udało się wyznaczyć operacje';
					|tr = 'İşlem atanamadı'");
		
	EndTry;
	
EndProcedure

// Deletes operations from the register for the specified record keys.
//
// Parameters:
//  OperationKeys - Array - array of register values for the record key.
//
Procedure DeleteKeyOperations(OperationKeys) Export
	
	BeginTransaction();
	
	Try
		
		Operations = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet().UnloadColumns();
		For Each Var_Key In OperationKeys Do
			FillPropertyValues(Operations.Add(), Var_Key);
		EndDo;
		
		DataLock = New DataLock;
			
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = Operations;
		LockItem.UseFromDataSource("ShiftTask", "ShiftTask");
		LockItem.UseFromDataSource("Stage", "Stage");
		
		DataLock.Lock();
		
		TempTablesManager = New TempTablesManager;
		
		CreateTTDeleteOperation(TempTablesManager, Operations);
		
		ChangeOperations(TempTablesManager);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể xóa các giao dịch';
					|ru = 'Не удалось удалить операции';
					|en = 'Cannot delete operations'; fa = 'Cannot delete operations';
					|it = 'Non è stato possibile cancellare le operazioni';
					|pl = 'Nie udało się usunąć operacje';
					|tr = 'İşlem silinemedi'");
		
	EndTry;
	
EndProcedure

// Deletes operations that belong to the specified shift task.
//
// Parameters:
//  ShiftTask - DocumentRef.ShiftTask - the job change.
//
Procedure DeleteJobOperations(ShiftTask) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
			
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		DataLock.Lock();
		
		Query = New Query(
			"SELECT DISTINCT
			|	OperationsToCreateShiftTasks.Stage AS Stage
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
			|WHERE
			|	OperationsToCreateShiftTasks.ShiftTask = &ShiftTask");
		Query.SetParameter("ShiftTask", ShiftTask);
		Selection = Query.Execute().Select();
		
		Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
		Set.Filter.ShiftTask.Set(ShiftTask);
		Set.Write();
		
		StageProcessingParameters = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
		StageProcessingParameters.RefreshStatus = True;
	
		While Selection.Next() Do
			
			CalculateOperations(Selection.Stage, ShiftTask);
			
			InformationRegisters.JobsForProcessingProductionStages.AddJob(Selection.Stage, StageProcessingParameters);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể xóa các giao dịch';
					|ru = 'Не удалось удалить операции';
					|en = 'Cannot delete operations'; fa = 'Cannot delete operations';
					|it = 'Non è stato possibile cancellare le operazioni';
					|pl = 'Nie udało się usunąć operacje';
					|tr = 'İşlem silinemedi'");
		
	EndTry;
	
EndProcedure

// Creates production Operation2_2 documents based on register data and deletes the corresponding records.
//
// Parameters:
//  ShiftTask - DocumentRef.ShiftTask - the job operation which you want to create.
//  StatusOfDocuments - EnumRef.ProductionOperationStatuses - status of documents being created.
//
Procedure RegisterInDocuments(ShiftTask, StatusOfDocuments) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
			
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		DataLock.Lock();
		
		DataFillingArray = DataForFillingInOperations(ShiftTask);
		
		If DataFillingArray.Count() = 0 Then
			CommitTransaction();
			Return;
		EndIf;
		
		Stages = New Array;
		DataLock = New DataLock;
		
		// Creating Production operations
		For Each FillingData In DataFillingArray Do
			
			FillingData.Status = StatusOfDocuments;
			
			CreateProductionOfOperation(FillingData);
			
			If Stages.Find(FillingData.OperationKey.Stage) = Undefined Then
				Stages.Add(FillingData.OperationKey.Stage);
				LockItem = DataLock.Add("Document.ProductionStage2_2");
				LockItem.SetValue("Ref", FillingData.OperationKey.Stage);
				LockItem.Mode = DataLockMode.Shared;
			EndIf;
			
		EndDo;
		
		// Clearing the Operation register to create Replacement tasks
		Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
		Set.Filter.ShiftTask.Set(ShiftTask);
		Set.Write();
		
		// Recalculation of related data
		Actions = Undefined;
		If StatusOfDocuments = Enums.ProductionOperationStatuses.Executed Then
			Actions = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
			Actions.RefreshStatus = True;
			Actions.FillInAccordingToOperations = True;
		EndIf;
		
		QueueCalculationParameters = InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters();
		QueueCalculationParameters.CalculateShiftTasks = False;
		
		DataLock.Lock();
		StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages, True);
		
		For Each FillingData In DataFillingArray Do
			
			Stage = FillingData.OperationKey.Stage;
			ElementIndex = Stages.Find(Stage);
			If ElementIndex = Undefined Then
				Continue;
			EndIf;
			
			Data_Stage = StageData_1.Get(Stage);
			
			InformationRegisters.QueueOfProductionOperations.CalculateQueueBasedOnStageData(Stage, Data_Stage, QueueCalculationParameters);
			
			If StatusOfDocuments = Enums.ProductionOperationStatuses.Executed Then
				InformationRegisters.JobsForProcessingProductionStages.AddJob(Stage, Actions);
			EndIf;
			
			Stages.Delete(ElementIndex);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể tạo ra giao dịch sản xuất.';
					|ru = 'Не удалось создать производственные операции';
					|en = 'Cannot create routing operations'; fa = 'Cannot create routing operations';
					|it = 'Non è stato possibile creare operazioni di produzione';
					|pl = 'Nie udało się utworzyć operacji produkcyjnych';
					|tr = 'Rota işlemi oluşturulamadı'");
		
	EndTry;
	
EndProcedure

// Fills in the register according to the production Operation2_2 documents and deletes the documents.
//
// Parameters:
//  ShiftTask - DocumentRef.ShiftTask - the task whose operations you want to delete.
//
Procedure DocumentsInRegister(ShiftTask) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		DataLock.Lock();
		
		Query = New Query(
			"SELECT
			|	Operations.Department         AS Department,
			|	Operations.ShiftTask        AS ShiftTask,
			|	Operations.Stage                  AS Stage,
			|	Operations.Operation              AS Operation,
			|	Operations.OperationID AS OperationID,
			|	CASE
			|		WHEN Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
			|			THEN VALUE(Catalog.Persons.EmptyRef)
			|		ELSE Operations.Performer
			|	END                          AS Performer,
			|	CASE
			|		WHEN Operations.WorkCenter REFS Catalog.WorkCenters
			|			THEN Operations.WorkCenter
			|		ELSE
			|			VALUE(Catalog.WorkCenters.EmptyRef)
			|	END                                                          AS WorkCenter,
			|	CASE
			|		WHEN Operations.WorkCenter REFS Catalog.WorkCenterTypes
			|			THEN Operations.WorkCenter
			|		ELSE
			|			Operations.WorkCenter.WorkCenterType
			|	END                                                          AS WorkCenterType,
			|	SUM(Operations.Count - Operations.CountCanceled)       AS Count,
			|	Queue.TimePerPiece           AS TimePerPiece,
			|	Queue.SetupTime                AS SetupTime,
			|	Queue.TimeUnitsOfMeasure             AS TimeUnitsOfMeasure,
			|	Operations.Stage.ReferenceOrder     AS ReferenceOrder,
			|	Queue.OperationNumber          AS OperationNumber,
			|	Queue.NextOperation AS NextOperation
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
			|		ON Operations.Department = Queue.Department
			|			AND Operations.Stage = Queue.Stage
			|			AND Operations.Operation = Queue.Operation
			|			AND Operations.OperationID = Queue.OperationID
			|			AND Queue.MainEntry_
			|WHERE
			|	Operations.ShiftTask = &ShiftTask
			|	AND Operations.Posted
			|	AND (Operations.BasedOnMasterData
			|		OR Operations.IncludedInTechnologicalProcess)
			|
			|GROUP BY
			|	Queue.TimePerPiece,
			|	Queue.SetupTime,
			|	Queue.TimeUnitsOfMeasure,
			|	Operations.Department,
			|	Operations.Stage,
			|	Operations.Operation,
			|	Operations.OperationID,
			|	Operations.ShiftTask,
			|	CASE
			|		WHEN Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
			|			THEN VALUE(Catalog.Persons.EmptyRef)
			|		ELSE Operations.Performer
			|	END,
			|	CASE
			|		WHEN Operations.WorkCenter REFS Catalog.WorkCenters
			|			THEN Operations.WorkCenter
			|		ELSE
			|			VALUE(Catalog.WorkCenters.EmptyRef)
			|	END,
			|	CASE
			|		WHEN Operations.WorkCenter REFS Catalog.WorkCenterTypes
			|			THEN Operations.WorkCenter
			|		ELSE
			|			Operations.WorkCenter.WorkCenterType
			|	END,
			|	Operations.Stage.ReferenceOrder,
			|	Queue.OperationNumber,
			|	Queue.NextOperation
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Operations.Ref                                   AS Ref,
			|	Operations.Operation                                 AS Operation,
			|	Operations.OperationID                    AS OperationID,
			|	Operations.Stage                                     AS Stage,
			|	Operations.Stage.ReferenceOrder                        AS ReferenceOrder,
			|	Operations.Stage.ProductionLot                  AS ProductionLot,
			|	Operations.DataVersion                             AS DataVersion,
			|	Operations.BasedOnMasterData                           AS BasedOnMasterData,
			|	Operations.Count - Operations.CountCanceled AS Count
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|WHERE
			|	Operations.ShiftTask = &ShiftTask");
		Query.SetParameter("ShiftTask", ShiftTask);
		
		ResultsArray = Query.ExecuteBatch();
		
		If ResultsArray[1].IsEmpty() Then
			CommitTransaction();
			Return;
		EndIf;
		
		// Deleting production operations
		Stages = New Array;
		DataLock = New DataLock();
		Selection = ResultsArray[1].Select();
		
		SetPrivilegedMode(True);
		
		While Selection.Next() Do
			
			OperationObject = Selection.Ref.GetObject(); // DocumentObject.ProductionOperation2_2
			ProductionAccounting.BlockProductionOperation(OperationObject);
			If OperationObject.DataVersion <> Selection.DataVersion Then
				OperationObject.Unlock();
				Raise NStr("vi = 'Đã thay đổi các thao tác sản xuất, cần đọc lại dữ liệu của nhiệm vụ.';
							|ru = 'Производственные операции изменены, необходимо перечитать данные задания.';
							|en = 'Routing operations are changed, reread these jobs.'; fa = 'Routing operations are changed, reread these jobs.';
							|it = 'Производственные операции изменены, необходимо перечитать данные задания.';
							|pl = 'Routing operations are changed, reread these jobs.';
							|tr = 'Üretim işlemleri değişti ve verilen emirlerin yeniden okunması gerekiyor.'");
			EndIf;
			If Selection.BasedOnMasterData Then
				OperationObject.Delete();
			Else
				FillPropertyValues(OperationObject, ProductionAccountingClientServer.StructureOfResultsConstructor());
				OperationObject.Protocol.Clear();
				OperationObject.Count = Selection.Count;
				OperationObject.Status = ProductionAccountingClientServer.InitialStatusOfProductionOfOperation(OperationObject);
				OperationObject.ShiftTask = Documents.ShiftTask.EmptyRef();
				OperationObject.SetGroupProcessingMode();
				OperationObject.Write();
			EndIf;
			
			If Stages.Find(Selection.Stage) = Undefined Then
				Stages.Add(Selection.Stage);
				LockItem = DataLock.Add("Document.ProductionStage2_2");
				LockItem.SetValue("Ref", Selection.Stage);
				LockItem.Mode = DataLockMode.Shared;
			EndIf;
			
		EndDo;
		
		SetPrivilegedMode(False);
		
		DataLock.Lock();
		StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages, True);
		
		// Recalculation of related data
		QueueCalculationParameters = InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters();
		QueueCalculationParameters.CalculateShiftTasks = False;
		For Each Stage In Stages Do
			InformationRegisters.QueueOfProductionOperations.CalculateQueueBasedOnStageData(
				Stage, StageData_1.Get(Stage), QueueCalculationParameters);
		EndDo;
		
		// The register entry
		Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
		Set.Filter.ShiftTask.Set(ShiftTask);
		
		Order = CurrentUniversalDateInMilliseconds();
		
		Selection = ResultsArray[0].Select();
		While Selection.Next() Do
			
			Record = Set.Add();
			FillPropertyValues(Record, Selection);
			Record.Order = Order;
			
			Order = Order + 1;
			
		EndDo;
		
		Set.Write();
		
		// Case recalculation
		CalculateOperations(Stages, ShiftTask);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể tải dữ liệu từ các giao dịch sản xuất.';
					|ru = 'Не удалось загрузить данные из производственных операций';
					|en = 'Cannot import data from routing operations'; fa = 'Cannot import data from routing operations';
					|it = 'Non è stato possibile caricare i dati dalle operazioni di produzione';
					|pl = 'Nie udało się wczytać dane z operacji produkcyjnych';
					|tr = 'Rota işlemlerinden veriler yüklenemedi'");
		
	EndTry;
	
EndProcedure

// Constructor of the structure that is used for assigning operations.
// 
// Returns:
//  Structure - structure with keys:
//		* Dimensions - Structure - destination sections:
//			** ShiftTask - DocumentRef.ShiftTask
//			** Performer - CatalogRef.Teams, CatalogRef.Persons - executor.
//			** WorkCenter - CatalogRef.WorkCenters
//			** WorkCenterType - CatalogRef.WorkCenterTypes
//		* Count - Number, Undefined - the quantity to assign.
//			If passed Undefined, the operation is assigned in full.
//		* AssignThePart - Boolean - it only makes sense if the Quantity is passed.
//			True-modifiable operations will be reduced by the Number. For example
//			, if you assign a part of an operation that was not assigned earlier, you should pass True.
//			In this case, part of the operation will be assigned, and the remaining part will remain unassigned.
//			False-modifiable operations will be reduced by the full number. For example
//			, if a previously assigned operation is changed in a quantity smaller than the one originally assigned,
//			then you should subtract the full quantity from the old set of dimensions, and add a new record
//			with the specified quantity. Accordingly, the parameter in this case must be set to False.
//
Function ParametersForAssigningOperations() Export
	
	Result = New Structure;
	
	Dimensions = New Structure;
	Dimensions.Insert("ShiftTask", Undefined);
	Dimensions.Insert("Performer", Undefined);
	Dimensions.Insert("WorkCenter", Undefined);
	Dimensions.Insert("WorkCenterType", Undefined);
	
	Result.Insert("Dimensions", Dimensions);
	Result.Insert("Count", Undefined);
	
	Result.Insert("AssignThePart", False);
	
	Return Result;
	
EndFunction

// Deletes operations that have a broken assignment order from the shift task.
//
// Parameters:
//  ShiftTask - DocumentRef.ShiftTask - the job change.
//
Procedure ExcludeOperationsThatViolateAssignmentOrder(ShiftTask) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		DataLock.Lock();
		
		Query = New Query(
			"SELECT
			|	Operations.*
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Operations
			|WHERE
			|	Operations.ShiftTask = &ShiftTask
			|	AND NOT Operations.AssignmentProcedureIsViolated
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	Operations.Stage AS Stage
			|FROM
			|	InformationRegister.OperationsToCreateShiftTasks AS Operations
			|WHERE
			|	Operations.ShiftTask = &ShiftTask
			|	AND Operations.AssignmentProcedureIsViolated");
		Query.SetParameter("ShiftTask", ShiftTask);
		
		ResultsArray = Query.ExecuteBatch();
		
		Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
		Set.Filter.ShiftTask.Set(ShiftTask);
		Set.Load(ResultsArray[0].Unload());
		Set.AdditionalProperties.Insert(KeyIsNotToControlDataWhenWriting());
		Set.Write();
		
		CalculateOperations(ResultsArray[1].Unload().UnloadColumn("Stage"), ShiftTask);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể loại trừ các giao dịch';
					|ru = 'Не удалось исключить операции';
					|en = 'Cannot exclude operations'; fa = 'Cannot exclude operations';
					|it = 'Non è stato possibile escludere le operazioni';
					|pl = 'Nie można wykluczyć operacji';
					|tr = 'İşlem hariç tutulamadı'");
		
	EndTry;
	
EndProcedure

// Corrects the number of operations with a violation of the assignment order if
// a partial assignment is available for them. Otherwise, operations are removed from the task.
//
// Parameters:
//  ShiftTask - DocumentRef.ShiftTask - the job change.
//
Procedure AdjustOperationsThatViolateAssignmentOrder(ShiftTask) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		DataLock.Lock();
		
		Query = New Query(RequestTextAdjustingOperations());
		Query.SetParameter("ShiftTask", ShiftTask);
		
		ResultsArray = Query.ExecuteBatch(); 
		
		Links = ResultsArray[1].Unload();
		Links.Indexes.Add("OperationID");
		Links.Indexes.Add("IDOfPreshOperation");
		
		IdSearchSt = New Structure("OperationID");
		SearchIDPredsh = New Structure("IDOfPreshOperation");
		
		Selection = ResultsArray[2].Select();
		
		Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
		Set.Filter.ShiftTask.Set(ShiftTask);
		Set.Load(ResultsArray[3].Unload());
		
		StagesRecalculation = New Array;
		
		While Selection.Next() Do
			
			Standards = Links.Find(Selection.OperationID, "IDOfPreshOperation");
			
			Coef = Undefined;
			
			IdSearchSt.OperationID = Selection.OperationID;
			For Each String In Links.FindRows(IdSearchSt) Do
				
				If String.OperationID = String.IDOfPreshOperation Then
					Continue;
				EndIf;
				
				Coef = ?(Coef = Undefined Or String.Count/String.TotalCount1 < Coef,
					String.Count/String.TotalCount1,
					Coef);
				
				If Coef = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			AvailableForAppointment = Standards.TotalCount1*Coef;
			
			If AvailableForAppointment > Standards.Count Then
				
				Record = Set.Add();
				FillPropertyValues(Record, Selection);
				Record.AssignmentProcedureIsViolated = False;
				
				If Standards.Count + Record.Count > AvailableForAppointment Then
					Record.Count = AvailableForAppointment - Standards.Count;
				EndIf;
				
				SearchIDPredsh.IDOfPreshOperation = Selection.OperationID;
				For Each String In Links.FindRows(SearchIDPredsh) Do
					String.Count = String.Count + Record.Count;
				EndDo;
				
			EndIf;
			
			If StagesRecalculation.Find(Selection.Stage) = Undefined Then
				
				StagesRecalculation.Add(Selection.Stage);
				
			EndIf;
			
		EndDo;
		
		Set.AdditionalProperties.Insert(KeyIsNotToControlDataWhenWriting());
		Set.Write();
		
		If StagesRecalculation.UBound() <> -1 Then
			CalculateOperations(StagesRecalculation, ShiftTask);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể điều chỉnh giao dịch';
					|ru = 'Не удалось скорректировать операции';
					|en = 'Cannot adjust operations'; fa = 'Cannot adjust operations';
					|it = 'Non è stato possibile correggere le operazioni';
					|pl = 'Nie można korygować operacji';
					|tr = 'İşlem düzeltilemedi'");
		
	EndTry;
	
EndProcedure

// Adds the operation to the job change. It can only be used for operations that are not assigned to another task.
// If the task status is "Generated", operations are assigned. If the task status is "Generated",
// the "Production operation" documents are created.
//
// Parameters:
//  Operations - ValueTable - Operation Data:
//		* OperationKey - InformationRegisterRecordKey.OperationsToCreateShiftTasks
//		* Performer - CatalogRef.Teams, CatalogRef.Persons - executor.
//		* WorkCenterType - CatalogRef.WorkCenterTypes
//		* WorkCenter - CatalogRef.WorkCenters
//		* Count - Number
//  ShiftTask - DocumentRef.ShiftTask - the job change.
//
Procedure AddToTask(Operations, ShiftTask) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("ShiftTask", ShiftTask);
		
		LockItem = DataLock.Add("Document.ShiftTask");
		LockItem.Mode = DataLockMode.Shared;
		LockItem.SetValue("Ref", ShiftTask);
		
		DataLock.Lock();
		
		Stages = New Array;
		TaskLimits = Common.ObjectAttributesValues(ShiftTask, "Status, ProductionArea");
		
		If TaskLimits.Status = Enums.ShiftTaskStatuses.BeingGenerated Then
			
			// Writing to the register
			
			Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
			Set.Filter.ShiftTask.Set(ShiftTask);
			
			Order = CurrentUniversalDateInMilliseconds();
			TransactionTable = Set.UnloadColumns();
			
			For Each Operation In Operations Do
				
				NewRow = TransactionTable.Add();
				
				FillPropertyValues(NewRow, Operation);
				
				NewRow.ShiftTask = ShiftTask;
				NewRow.Order = Order;
				
				Order = Order + 1;
				
				If Stages.Find(Operation.Stage) = Undefined Then
				
					Stages.Add(Operation.Stage);
					
				EndIf;
			
			EndDo;
			
			Query = New Query(
				"SELECT
				|	Operations.Department         AS Department,
				|	Operations.ShiftTask        AS ShiftTask,
				|	Operations.Stage                  AS Stage,
				|	Operations.Operation              AS Operation,
				|	Operations.OperationID AS OperationID,
				|	CASE
				|		WHEN Operations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
				|			THEN VALUE(Catalog.Persons.EmptyRef)
				|		ELSE Operations.Performer
				|	END                          AS Performer,
				|	Operations.WorkCenter          AS WorkCenter,
				|	Operations.WorkCenterType     AS WorkCenterType,
				|	Operations.Count            AS Count,
				|	Operations.Order               AS Order
				|INTO TTOperations
				|FROM
				|	&Operations AS Operations
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	NestedQuery.Department            AS Department,
				|	NestedQuery.ShiftTask           AS ShiftTask,
				|	NestedQuery.Stage                     AS Stage,
				|	NestedQuery.Operation                 AS Operation,
				|	NestedQuery.OperationID    AS OperationID,
				|	NestedQuery.Performer              AS Performer,
				|	NestedQuery.WorkCenter             AS WorkCenter,
				|	NestedQuery.WorkCenterType        AS WorkCenterType,
				|	NestedQuery.AssignNotEarlierThan         AS AssignNotEarlierThan,
				|	NestedQuery.TimePerPiece             AS TimePerPiece,
				|	NestedQuery.SetupTime                  AS SetupTime,
				|	NestedQuery.TimeUnitsOfMeasure               AS TimeUnitsOfMeasure,
				|	NestedQuery.AssignmentIsAllowed           AS AssignmentIsAllowed,
				|	NestedQuery.ToBeAssigned           AS ToBeAssigned,
				|	NestedQuery.AssignmentProcedureIsViolated AS AssignmentProcedureIsViolated,
				|	NestedQuery.ReferenceOrder             AS ReferenceOrder,
				|	NestedQuery.OperationNumber            AS OperationNumber,
				|	NestedQuery.NextOperation   AS NextOperation,
				|	SUM(NestedQuery.Count)        AS Count,
				|	MAX(NestedQuery.Order)        AS Order
				|FROM
				|	(SELECT
				|		OperationsRegister.Department          AS Department,
				|		OperationsRegister.ShiftTask         AS ShiftTask,
				|		OperationsRegister.Stage                   AS Stage,
				|		OperationsRegister.Operation               AS Operation,
				|		OperationsRegister.OperationID  AS OperationID,
				|		OperationsRegister.Performer            AS Performer,
				|		OperationsRegister.WorkCenter           AS WorkCenter,
				|		OperationsRegister.WorkCenterType      AS WorkCenterType,
				|		DATETIME(1, 1, 1)                     AS AssignNotEarlierThan,
				|		OperationsRegister.Count             AS Count,
				|		OperationsRegister.TimePerPiece           AS TimePerPiece,
				|		OperationsRegister.SetupTime                AS SetupTime,
				|		OperationsRegister.TimeUnitsOfMeasure             AS TimeUnitsOfMeasure,
				|		FALSE                                   AS AssignmentIsAllowed,
				|		FALSE                                   AS ToBeAssigned,
				|		CASE
				|			WHEN OperationsRegister.Stage IN (&Stages)
				|				THEN FALSE
				|			ELSE OperationsRegister.AssignmentProcedureIsViolated
				|		END                                  AS AssignmentProcedureIsViolated,
				|		OperationsRegister.ReferenceOrder           AS ReferenceOrder,
				|		OperationsRegister.OperationNumber          AS OperationNumber,
				|		OperationsRegister.NextOperation AS NextOperation,
				|		OperationsRegister.Order                AS Order
				|	FROM
				|		InformationRegister.OperationsToCreateShiftTasks AS OperationsRegister
				|	WHERE
				|		OperationsRegister.ShiftTask = &ShiftTask
				|	
				|	UNION ALL
				|	
				|	SELECT
				|		OperationsAssignment.Department,
				|		OperationsAssignment.ShiftTask,
				|		OperationsAssignment.Stage,
				|		OperationsAssignment.Operation,
				|		OperationsAssignment.OperationID,
				|		OperationsAssignment.Performer,
				|		OperationsAssignment.WorkCenter,
				|		OperationsAssignment.WorkCenterType,
				|		DATETIME(1, 1, 1),
				|		OperationsAssignment.Count,
				|		Queue.TimePerPiece,
				|		Queue.SetupTime,
				|		Queue.TimeUnitsOfMeasure,
				|		FALSE,
				|		FALSE,
				|		FALSE,
				|		Queue.ReferenceOrder,
				|		Queue.OperationNumber,
				|		Queue.NextOperation,
				|		OperationsAssignment.Order
				|	FROM
				|		TTOperations AS OperationsAssignment
				|			LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
				|			ON OperationsAssignment.Department = Queue.Department
				|				AND OperationsAssignment.Stage = Queue.Stage
				|				AND OperationsAssignment.Operation = Queue.Operation
				|				AND OperationsAssignment.OperationID = Queue.OperationID
				|				AND Queue.MainEntry_) AS NestedQuery
				|
				|GROUP BY
				|	NestedQuery.WorkCenterType,
				|	NestedQuery.AssignmentIsAllowed,
				|	NestedQuery.AssignmentProcedureIsViolated,
				|	NestedQuery.TimePerPiece,
				|	NestedQuery.SetupTime,
				|	NestedQuery.TimeUnitsOfMeasure,
				|	NestedQuery.ReferenceOrder,
				|	NestedQuery.Stage,
				|	NestedQuery.Performer,
				|	NestedQuery.AssignNotEarlierThan,
				|	NestedQuery.ToBeAssigned,
				|	NestedQuery.WorkCenter,
				|	NestedQuery.Operation,
				|	NestedQuery.Department,
				|	NestedQuery.ShiftTask,
				|	NestedQuery.OperationID,
				|	NestedQuery.OperationNumber,
				|	NestedQuery.NextOperation");
			Query.SetParameter("Operations", TransactionTable);
			Query.SetParameter("ShiftTask", ShiftTask);
			Query.SetParameter("Stages", Stages);
			
			Set.Load(Query.Execute().Unload());
			Set.Write();
			
			// Recalculation of related data
			JobParameters = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
			JobParameters.RefreshStatus = True;
			
			For Each Stage In Stages Do
				
				CalculateOperations(Stage, ShiftTask);
				InformationRegisters.JobsForProcessingProductionStages.AddJob(Stage, JobParameters);
				
			EndDo;
			
		Else
			
			DataFillingArray = DataForFillingInOperations(ShiftTask, Operations);
			
			DataLock = New DataLock;
			
			// Creating Production operations
			For Each FillingData In DataFillingArray Do
				
				FillingData.ProductionArea = TaskLimits.ProductionArea;
				
				CreateProductionOfOperation(FillingData);
				
				If Stages.Find(FillingData.OperationKey.Stage) = Undefined Then
					Stages.Add(FillingData.OperationKey.Stage);
					LockItem = DataLock.Add("Document.ProductionStage2_2");
					LockItem.SetValue("Ref", FillingData.OperationKey.Stage);
					LockItem.Mode = DataLockMode.Shared;
				EndIf;
				
			EndDo;
			
			DataLock.Lock();
			StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages, True);
			
			// Recalculation of related data
			JobParameters = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
			JobParameters.RefreshStatus = True;
			QueueCalculationParameters = InformationRegisters.QueueOfProductionOperations.QueueCalculationParameters();
			QueueCalculationParameters.CalculateShiftTasks = False;
			
			For Each FillingData In DataFillingArray Do
				
				Stage = FillingData.OperationKey.Stage;
				ElementIndex = Stages.Find(Stage);
				If ElementIndex = Undefined Then
					Continue;
				EndIf;
				
				Data_Stage = StageData_1.Get(Stage);
				
				InformationRegisters.QueueOfProductionOperations.CalculateQueueBasedOnStageData(Stage, Data_Stage, QueueCalculationParameters);
				CalculateOperations(Stage, ShiftTask);
				InformationRegisters.JobsForProcessingProductionStages.AddJob(Stage, JobParameters);
				
				Stages.Delete(ElementIndex);
				
			EndDo;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteErrorToEventLog(ErrorInfo());
		
		Raise NStr("vi = 'Không thể thêm thao tác';
					|ru = 'Не удалось добавить операции';
					|en = 'Cannot add operations'; fa = 'Cannot add operations';
					|it = 'Non è stato possibile aggiungere operazioni';
					|pl = 'Nie można dodać operacji';
					|tr = 'İşlem eklenemedi'");
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Internal

// Returns the request text for calculating the operation execution time.
//
// Parameters:
//  TableNameRegister - String - synonym of the operation information register table for creating variable Tasks in the query text.
// 
// Returns:
//  String - the text to be substituted into the query.
//
Function QueryTextOperationTime_(TableNameRegister) Export
	
	Return	StrReplace(
		"(
		|	CASE
		|		WHEN ISNULL(Register.WorkCenterType.ParallelLoad, FALSE)
		|			THEN Register.TimePerPiece * ISNULL(Register.WorkCenter.WorkTimeFactor, 1)
		|		ELSE Register.TimePerPiece * ISNULL(Register.WorkCenter.WorkTimeFactor, 1) * Register.Count / ISNULL(Register.Operation.Count, 1)
		|	END + Register.SetupTime
		|)",
		"Register",
		TableNameRegister);
	
EndFunction

#EndRegion

#Region Private

Function CalculateRegisterData(Stage)
	
	Query = New Query(TextOfOperationRequestForCalculation());
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Stage", Stage);
	
	ResultsArray = Query.ExecuteBatch(); 
	
	Operations = ResultsArray[ResultsArray.UBound()-3].Unload();
	
	LinksOfOperations = ResultsArray[ResultsArray.UBound()-2].Unload();
	LinksOfOperations.Indexes.Add("OperationID");
	LinksOfOperations.Indexes.Add("IDOfPreshOperation");
	
	Selection = ResultsArray[ResultsArray.UBound()-1].Select();
	
	AssignedOperations = ResultsArray[ResultsArray.UBound()].Unload();
	TMCommonUse.AddSequenceNumberOfRowsToTable(AssignedOperations);
	AssignedOperations.Indexes.Add("OperationID");
	AssignedOperations.Indexes.Add("IDOfPreshOperation, Date");
	
	IdSearchSt = New Structure("OperationID");
	SearchIDPredsh = New Structure("IDOfPreshOperation");
	SearchStIDPreshDate = New Structure("IDOfPreshOperation, Date");
	KeySearchSt = New Structure(
		"Department, ShiftTask, Stage, Operation, OperationID, Performer, WorkCenter, WorkCenterType, AssignNotEarlierThan");
	
	// Resource calculation of assigned operations: the assignment order is violated
	
	IndexByKeys = Operations.Indexes.Add(
		"Department, ShiftTask, Stage, Operation, OperationID, Performer, WorkCenter, WorkCenterType, AssignNotEarlierThan");
	
	Totals = New Map;             // Contains the cumulative totals of operations in full
	ResultsWithoutViolations = New Map; // Contains cumulative totals excluding operations that violate the order of assignment
	
	While Selection.Next() Do
		
		If Totals[Selection.OperationID] = Undefined Then
			Totals.Insert(Selection.OperationID, Selection.Count);
			ResultsWithoutViolations.Insert(Selection.OperationID, 0);
		Else
			Totals[Selection.OperationID] = Totals[Selection.OperationID] + Selection.Count;
		EndIf;
		
		If Selection.IsDocument Then
			ResultsWithoutViolations[Selection.OperationID] = ResultsWithoutViolations[Selection.OperationID] + Selection.Count;
			Continue;
		EndIf;
		
		IdSearchSt.OperationID = Selection.OperationID;
		Predecessors = LinksOfOperations.FindRows(IdSearchSt);
		
		If Predecessors.UBound() = -1 Then
			ResultsWithoutViolations[Selection.OperationID] = ResultsWithoutViolations[Selection.OperationID] + Selection.Count;
			Continue;
		EndIf;
		
		AssignmentProcedureIsViolated = False;
		
		For Each Link In Predecessors Do
			
			If ResultsWithoutViolations[Link.IDOfPreshOperation] = Undefined
				Or Totals[Link.OperationID] / Link.TotalCount1 
				  > ResultsWithoutViolations[Link.IDOfPreshOperation] / Link.NumberOfTotalPredsh Then
				
				AssignmentProcedureIsViolated = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If AssignmentProcedureIsViolated Then
			
			FillPropertyValues(KeySearchSt, Selection);
			Operations.FindRows(KeySearchSt)[0].AssignmentProcedureIsViolated = True;
			
			// An operation with a violation of the assignment order should be excluded from the calculation of the "assignable" resource
			SearchStIDPreshDate.IDOfPreshOperation = Selection.OperationID;
			SearchStIDPreshDate.Date = Selection.Date;
			FoundRows = AssignedOperations.FindRows(SearchStIDPreshDate);
			If FoundRows.UBound() <> -1 Then
				FoundRows[0].Count = FoundRows[0].Count - Selection.Count;
			EndIf;
			
		Else
			ResultsWithoutViolations[Selection.OperationID] = ResultsWithoutViolations[Selection.OperationID] + Selection.Count;
		EndIf;
		
	EndDo;
	
	Operations.Indexes.Delete(IndexByKeys);
	
	// Calculation of the resources of unassigned operations: can/should be assigned, assign not earlier
	
	OperationsToProcess = Operations.FindRows(New Structure("Assigned_", False));
	For Each Operation In OperationsToProcess Do
		
		QuantityAssigned = Operation.TotalCount1 - Operation.Count;
		
		// Calculation of the "need to assign" quantity
		Fraction = Undefined;
		
		SearchIDPredsh.IDOfPreshOperation = Operation.OperationID;
		Successors = LinksOfOperations.FindRows(SearchIDPredsh);
		
		For Each String In Successors Do
			FractionIsNew = ProductionServer.Fraction(String.QuantityAssigned, String.TotalCount1);
			If Fraction = Undefined Then
				Fraction = FractionIsNew;
			Else
				Fraction = ?(FractionIsNew.Value > Fraction.Value, FractionIsNew, Fraction);
			EndIf;
		EndDo;
		
		QuantityMustBeAssigned = 0;
		If Fraction <> Undefined And Fraction.Value > 0 Then
			
			Count = Round(Operation.TotalCount1 * Fraction.Numerator/Fraction.Denominator, 3) - QuantityAssigned;
			
			If Count > 0 Then
				QuantityMustBeAssigned = Count;
			EndIf;
			
		EndIf;
		
		// Initialization of the buffer accumulating the number of assigned previous operations
		Buffer = New Map;
		AllPredecessorsAreAppointed = True;
		
		IdSearchSt.OperationID = Operation.OperationID;
		Predecessors = LinksOfOperations.FindRows(IdSearchSt);
		
		If Predecessors.UBound() <> -1 Then
			For Each String In Predecessors Do
				
				Buffer.Insert(String.IDOfPreshOperation,
					New Structure("Count, TotalCount1", 0, String.NumberOfTotalPredsh));
				
				If AllPredecessorsAreAppointed Then
					
					If ResultsWithoutViolations.Get(String.IDOfPreshOperation) = Undefined
						Or ResultsWithoutViolations[String.IDOfPreshOperation] <> String.NumberOfTotalPredsh Then
						
						AllPredecessorsAreAppointed = False;
						
					EndIf;
					
				EndIf;
				
			EndDo;
		Else
			Operation.AssignmentIsAllowed = True;
			Operation.ToBeAssigned = QuantityMustBeAssigned > 0;
			Continue;
		EndIf;
		
		// Calculation of the quantity to the destination by dates
		AssignmentByDate = New Array;
		Predecessors = TMCommonUse.FindRowsWithPreservingOrder(AssignedOperations, IdSearchSt, True);
		
		For IndexOf = 0 To Predecessors.UBound() Do
			
			Predecessor = Predecessors[IndexOf];
			
			If Predecessor.Count = 0 Then
				Continue;
			EndIf;
			
			Buffer[Predecessor.IDOfPreshOperation].Count = 
				Buffer[Predecessor.IDOfPreshOperation].Count + Predecessor.Count;
			
			Fraction = Undefined;
			For Each KeyAndValue In Buffer Do
				FractionIsNew = ProductionServer.Fraction(KeyAndValue.Value.Count, KeyAndValue.Value.TotalCount1);
				If Fraction = Undefined Then
					Fraction = FractionIsNew;
				Else
					Fraction = ?(FractionIsNew.Value < Fraction.Value, FractionIsNew, Fraction);
				EndIf;
			EndDo;
				
			If Fraction.Value = 0 Then
				Continue;
			EndIf;
			
			For Each KeyAndValue In Buffer Do
				
				KeyAndValue.Value.Count = KeyAndValue.Value.Count
					- Round(KeyAndValue.Value.TotalCount1 * Fraction.Numerator/Fraction.Denominator, 3);
				
			EndDo;
				
			Count = Round(Operation.TotalCount1 * Fraction.Numerator/Fraction.Denominator, 3);
			
			// Offset of the assigned amount
			If QuantityAssigned > 0 Then
				
				If QuantityAssigned >= Count Then
					
					QuantityAssigned = QuantityAssigned - Count;
					Continue;
					
				Else
					
					Count = Count - QuantityAssigned;
					QuantityAssigned = 0;
					
				EndIf;
				
			EndIf;
			
			UBound = AssignmentByDate.UBound();
			If UBound = -1
				Or AssignmentByDate[UBound].AssignNotEarlierThan <> Predecessor.Date Then
				
				AssignmentByDate.Add(
					New Structure("AssignNotEarlierThan, Count",
						Predecessor.Date, Count));
				
			Else
				
				AssignmentByDate[UBound].Count = AssignmentByDate[UBound].Count + Count;
				
			EndIf;
			
		EndDo;
		
		// Marking operations to destination
		For IndexOf = 0 To AssignmentByDate.UBound() Do
			
			If AllPredecessorsAreAppointed And IndexOf = AssignmentByDate.UBound()
				Or AssignmentByDate[IndexOf].Count >= Operation.Count Then
				
				Operation.AssignmentIsAllowed = True;
				Operation.AssignNotEarlierThan = AssignmentByDate[IndexOf].AssignNotEarlierThan;
				Operation.ToBeAssigned = QuantityMustBeAssigned > 0;
				
				Break;
				
			ElsIf Not ProductionProcessEditorClientServer.ThisOperationIsIndividual(Operation) Then
				
				NewOperation = Operations.Add();
				FillPropertyValues(NewOperation, Operation);
				FillPropertyValues(NewOperation, AssignmentByDate[IndexOf],
					"AssignNotEarlierThan, Count");
				NewOperation.AssignmentIsAllowed = True;
				NewOperation.ToBeAssigned = QuantityMustBeAssigned > 0;
				
				Operation.Count = Operation.Count - NewOperation.Count;
				QuantityMustBeAssigned = QuantityMustBeAssigned - Min(QuantityMustBeAssigned, NewOperation.Count);
				
			EndIf;
			
		EndDo;
		
		If Not Operation.ToBeAssigned And QuantityMustBeAssigned > 0 Then
			Operation.ToBeAssigned = True;
		EndIf;
		
	EndDo;
	
	Return Operations;
	
EndFunction

Function TextOfOperationRequestForCalculation()
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.AttributesOfTimeOfOperation = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage = &Stage");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Operations.Stage                                                    AS Stage,
		|	Operations.OperationID                                   AS OperationID,
		|	PreshOperations.OperationID                              AS IDOfPreshOperation,
		|	MAX(Operations.CreatedOn)
		|		- MAX(Operations.RepetitionIsRequired)
		|		+ SUM(ISNULL(AssignedOperations.Count, 0))         AS QuantityAssigned,
		|	MAX(Operations.Scheduled
		|		- Operations.RepetitionIsRequired)    AS TotalCount1,
		|	MAX(PreshOperations.Scheduled
		|		- PreshOperations.RepetitionIsRequired)
		|		- MAX(PreshOperations.DefectiveGoods)                               AS NumberOfTotalPredsh
		|INTO TTCommunicationOperations
		|FROM
		|	TTQueue AS Operations
		|		INNER JOIN TTQueue AS PreshOperations
		|		ON Operations.Department = PreshOperations.Department
		|			AND Operations.Stage = PreshOperations.Stage
		|			AND Operations.OperationNumber = PreshOperations.NextOperation
		|		LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|		ON Operations.Stage = AssignedOperations.Stage
		|			AND Operations.OperationID = AssignedOperations.OperationID
		|			AND (AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef))
		|
		|GROUP BY
		|	Operations.Stage,
		|	Operations.OperationID,
		|	PreshOperations.OperationID
		|
		|INDEX BY
		|	Stage,
		|	IDOfPreshOperation,
		|	OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Department                  AS Department,
		|	NestedQuery.Stage                           AS Stage,
		|	NestedQuery.Operation                       AS Operation,
		|	NestedQuery.OperationID          AS OperationID,
		|	NestedQuery.ShiftTask                 AS ShiftTask,
		|	NestedQuery.Performer                    AS Performer,
		|	NestedQuery.WorkCenterType              AS WorkCenterType,
		|	NestedQuery.WorkCenter                   AS WorkCenter,
		|	NestedQuery.AssignNotEarlierThan               AS AssignNotEarlierThan,
		|	SUM(NestedQuery.Count)              AS Count,
		|	NestedQuery.TimePerPiece                   AS TimePerPiece,
		|	NestedQuery.SetupTime                        AS SetupTime,
		|	NestedQuery.TimeUnitsOfMeasure                     AS TimeUnitsOfMeasure,
		|	FALSE                                           AS AssignmentIsAllowed,
		|	FALSE                                           AS ToBeAssigned,
		|	FALSE                                           AS AssignmentProcedureIsViolated,
		|	NestedQuery.ReferenceOrder                   AS ReferenceOrder,
		|	NestedQuery.OperationNumber                  AS OperationNumber,
		|	NestedQuery.NextOperation         AS NextOperation,
		|	MAX(NestedQuery.TotalCount1)      AS TotalCount1,
		|	NestedQuery.ShiftTask <> UNDEFINED AS Assigned_,
		|	MAX(NestedQuery.Order)              AS Order
		|FROM
		|	(SELECT
		|		Queue.Department                                               AS Department,
		|		Queue.Stage                                                        AS Stage,
		|		Queue.Operation                                                    AS Operation,
		|		Queue.OperationID                                       AS OperationID,
		|		UNDEFINED                                                        AS ShiftTask,
		|		VALUE(Catalog.Persons.EmptyRef)                    AS Performer,
		|		&FieldsWorkCenter1,
		|		UNDEFINED                                                        AS AssignNotEarlierThan,
		|		Queue.Scheduled - Queue.CreatedOn                             AS Count,
		|		Queue.TimePerPiece                                                AS TimePerPiece,
		|		Queue.SetupTime                                                     AS SetupTime,
		|		Queue.TimeUnitsOfMeasure                                                  AS TimeUnitsOfMeasure,
		|		Queue.ReferenceOrder                                                AS ReferenceOrder,
		|		Queue.OperationNumber                                               AS OperationNumber,
		|		Queue.NextOperation                                      AS NextOperation,
		|		Queue.Scheduled - Queue.RepetitionIsRequired                   AS TotalCount1,
		|		0                                                                   AS Order
		|	FROM
		|		TTQueue AS Queue
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		OperationsToCreateShiftTasks.Department,
		|		OperationsToCreateShiftTasks.Stage,
		|		OperationsToCreateShiftTasks.Operation,
		|		OperationsToCreateShiftTasks.OperationID,
		|		UNDEFINED,
		|		VALUE(Catalog.Persons.EmptyRef),
		|		&WorkCenter2Fields,
		|		UNDEFINED,
		|		-OperationsToCreateShiftTasks.Count,
		|		OperationsToCreateShiftTasks.TimePerPiece,
		|		OperationsToCreateShiftTasks.SetupTime,
		|		OperationsToCreateShiftTasks.TimeUnitsOfMeasure,
		|		OperationsToCreateShiftTasks.ReferenceOrder,
		|		Queue.OperationNumber,
		|		Queue.NextOperation,
		|		0,
		|		0
		|	FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|			LEFT JOIN TTQueue AS Queue
		|			ON OperationsToCreateShiftTasks.OperationID = Queue.OperationID
		|	WHERE
		|		OperationsToCreateShiftTasks.Stage = &Stage
		|		AND OperationsToCreateShiftTasks.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		OperationsToCreateShiftTasks.Department,
		|		OperationsToCreateShiftTasks.Stage,
		|		OperationsToCreateShiftTasks.Operation,
		|		OperationsToCreateShiftTasks.OperationID,
		|		OperationsToCreateShiftTasks.ShiftTask,
		|		OperationsToCreateShiftTasks.Performer,
		|		OperationsToCreateShiftTasks.WorkCenterType,
		|		OperationsToCreateShiftTasks.WorkCenter,
		|		OperationsToCreateShiftTasks.AssignNotEarlierThan,
		|		OperationsToCreateShiftTasks.Count,
		|		OperationsToCreateShiftTasks.TimePerPiece,
		|		OperationsToCreateShiftTasks.SetupTime,
		|		OperationsToCreateShiftTasks.TimeUnitsOfMeasure,
		|		OperationsToCreateShiftTasks.ReferenceOrder,
		|		Queue.OperationNumber,
		|		Queue.NextOperation,
		|		0,
		|		OperationsToCreateShiftTasks.Order
		|	FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|			LEFT JOIN TTQueue AS Queue
		|			ON OperationsToCreateShiftTasks.OperationID = Queue.OperationID
		|	WHERE
		|		OperationsToCreateShiftTasks.Stage = &Stage
		|		AND OperationsToCreateShiftTasks.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Department,
		|	NestedQuery.Stage,
		|	NestedQuery.Operation,
		|	NestedQuery.OperationID,
		|	NestedQuery.ShiftTask,
		|	NestedQuery.Performer,
		|	NestedQuery.WorkCenterType,
		|	NestedQuery.WorkCenter,
		|	NestedQuery.AssignNotEarlierThan,
		|	NestedQuery.TimePerPiece,
		|	NestedQuery.SetupTime,
		|	NestedQuery.TimeUnitsOfMeasure,
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.OperationNumber,
		|	NestedQuery.NextOperation,
		|	NestedQuery.ShiftTask <> UNDEFINED
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTCommunicationOperations.OperationID      AS OperationID,
		|	TTCommunicationOperations.IDOfPreshOperation AS IDOfPreshOperation,
		|	TTCommunicationOperations.QuantityAssigned        AS QuantityAssigned,
		|	TTCommunicationOperations.TotalCount1            AS TotalCount1,
		|	TTCommunicationOperations.NumberOfTotalPredsh       AS NumberOfTotalPredsh
		|FROM
		|	TTCommunicationOperations AS TTCommunicationOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Operations.Department         AS Department,
		|	Operations.ShiftTask        AS ShiftTask,
		|	Operations.Stage                  AS Stage,
		|	Operations.Operation              AS Operation,
		|	Operations.OperationID AS OperationID,
		|	Operations.Performer           AS Performer,
		|	Operations.WorkCenter          AS WorkCenter,
		|	Operations.WorkCenterType     AS WorkCenterType,
		|	Operations.AssignNotEarlierThan      AS AssignNotEarlierThan,
		|	Operations.ShiftTask.Date   AS Date,
		|	Queue.OperationNumber          AS OperationNumber,
		|	Operations.Order               AS Order,
		|	FALSE                           AS IsDocument,
		|	Operations.Count            AS Count
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN TTQueue AS Queue
		|		ON Operations.OperationID = Queue.OperationID
		|WHERE
		|	Operations.Stage = &Stage
		|	AND Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	ProzvOperation.Department,
		|	ProzvOperation.ShiftTask,
		|	ProzvOperation.Stage,
		|	ProzvOperation.Operation,
		|	ProzvOperation.OperationID,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	UNDEFINED,
		|	ProzvOperation.ShiftTask.Date,
		|	0,
		|	0,
		|	TRUE,
		|	SUM(ProzvOperation.Count - ProzvOperation.CountCanceled)
		|FROM
		|	Document.ProductionOperation2_2 AS ProzvOperation
		|WHERE
		|	ProzvOperation.Stage = &Stage
		|	AND ProzvOperation.Posted
		|	AND (ProzvOperation.BasedOnMasterData
		|		OR ProzvOperation.IncludedInTechnologicalProcess)
		|	AND NOT ProzvOperation.RepetitionIsRequired
		|	AND NOT ProzvOperation.Status IN (
		|				VALUE(Enum.ProductionOperationStatuses.BeingGenerated),
		|				VALUE(Enum.ProductionOperationStatuses.NotExecuted))
		|
		|GROUP BY
		|	ProzvOperation.Operation,
		|	ProzvOperation.ShiftTask,
		|	ProzvOperation.Department,
		|	ProzvOperation.Stage,
		|	ProzvOperation.OperationID,
		|	ProzvOperation.ShiftTask.Date
		|
		|ORDER BY
		|	Date,
		|	OperationNumber,
		|	Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.OperationID      AS OperationID,
		|	NestedQuery.IDOfPreshOperation AS IDOfPreshOperation,
		|	NestedQuery.Date                       AS Date,
		|	SUM(NestedQuery.Count)          AS Count
		|FROM
		|	(SELECT
		|		Links.OperationID      AS OperationID,
		|		Links.IDOfPreshOperation AS IDOfPreshOperation,
		|		Job.Date                     AS Date,
		|		Operations.Count              AS Count
		|	FROM
		|		TTCommunicationOperations AS Links
		|			INNER JOIN InformationRegister.OperationsToCreateShiftTasks AS Operations
		|			ON Links.Stage = Operations.Stage
		|				AND Links.IDOfPreshOperation = Operations.OperationID
		|			LEFT JOIN Document.ShiftTask AS Job
		|			ON (Operations.ShiftTask = Job.Ref)
		|	WHERE
		|		Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Links.OperationID,
		|		Links.IDOfPreshOperation,
		|		CASE
		|			WHEN Job.Date IS NOT NULL
		|				THEN Job.Date
		|			WHEN ProzvOperation.Status = VALUE(Enum.ProductionOperationStatuses.Executed)
		|				THEN ProzvOperation.ExecutionEnd
		|			WHEN ProzvOperation.Status = VALUE(Enum.ProductionOperationStatuses.Running)
		|				THEN ProzvOperation.ExecutionStarted
		|			ELSE ProzvOperation.Date
		|		END,
		|		ProzvOperation.Count - ProzvOperation.CountCanceled
		|	FROM
		|		TTCommunicationOperations AS Links
		|			INNER JOIN Document.ProductionOperation2_2 AS ProzvOperation
		|			ON Links.Stage = ProzvOperation.Stage
		|				AND Links.IDOfPreshOperation = ProzvOperation.OperationID
		|			LEFT JOIN Document.ShiftTask AS Job
		|			ON (ProzvOperation.ShiftTask = Job.Ref)
		|	WHERE
		|		ProzvOperation.Posted
		|		AND NOT ProzvOperation.RepetitionIsRequired
		|		AND NOT ProzvOperation.Status IN (
		|				VALUE(Enum.ProductionOperationStatuses.BeingGenerated),
		|				VALUE(Enum.ProductionOperationStatuses.NotExecuted))
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.OperationID,
		|	NestedQuery.IDOfPreshOperation,
		|	NestedQuery.Date
		|
		|ORDER BY
		|	OperationID,
		|	Date";
		
	QueryText = StrReplace(QueryText,
		"&FieldsWorkCenter1,",
		Catalogs.ManufacturingOperations.QueryTextOfRCVRC("(CASE
		|	WHEN Queue.Operation <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|		THEN Queue.Operation
		|	ELSE Queue.ProductionOperation
		|END)"));
		
	QueryText = StrReplace(QueryText,
		"&WorkCenter2Fields,",
		Catalogs.ManufacturingOperations.QueryTextOfRCVRC("(CASE
		|	WHEN OperationsToCreateShiftTasks.Operation <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|		THEN OperationsToCreateShiftTasks.Operation
		|	ELSE Queue.ProductionOperation
		|END)"));
		
	Return QueryText;
	
EndFunction

Procedure CreateVTOperationAssignment(TempTablesManager, Operations, Parameters)
	
	QueryText =
		"SELECT
		|	Operations.Department         AS Department,
		|	Operations.Stage                  AS Stage,
		|	Operations.Operation              AS Operation,
		|	Operations.OperationID AS OperationID,
		|	Operations.ShiftTask        AS ShiftTask,
		|	Operations.Performer           AS Performer,
		|	Operations.WorkCenter          AS WorkCenter,
		|	Operations.WorkCenterType     AS WorkCenterType,
		|	Operations.AssignNotEarlierThan      AS AssignNotEarlierThan,
		|	Operations.Order               AS Order
		|INTO TTOperationAssignment
		|FROM
		|	&Operations AS Operations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationsAssignment.Department                         AS Department,
		|	OperationsAssignment.Stage                                  AS Stage,
		|	OperationsAssignment.Operation                              AS Operation,
		|	OperationsAssignment.OperationID                 AS OperationID,
		|	OperationsAssignment.ShiftTask                        AS ShiftTask,
		|	OperationsAssignment.Performer                           AS Performer,
		|	OperationsAssignment.WorkCenter                          AS WorkCenter,
		|	OperationsAssignment.WorkCenterType                     AS WorkCenterType,
		|	OperationsAssignment.AssignNotEarlierThan                      AS AssignNotEarlierThan,
		|	ISNULL(OperationsToCreateShiftTasks.Count, 1)  AS Count,
		|		// ISNULL(..., 1) converted to -1 in the next step;
		|		// a negative value will not pass the control - you cannot assign operations that are not in the register
		|	OperationsToCreateShiftTasks.TimePerPiece             AS TimePerPiece,
		|	OperationsToCreateShiftTasks.SetupTime                  AS SetupTime,
		|	OperationsToCreateShiftTasks.TimeUnitsOfMeasure               AS TimeUnitsOfMeasure,
		|	OperationsToCreateShiftTasks.AssignmentIsAllowed           AS AssignmentIsAllowed,
		|	OperationsToCreateShiftTasks.ToBeAssigned           AS ToBeAssigned,
		|	OperationsToCreateShiftTasks.AssignmentProcedureIsViolated AS AssignmentProcedureIsViolated,
		|	OperationsToCreateShiftTasks.ReferenceOrder             AS ReferenceOrder,
		|	OperationsToCreateShiftTasks.OperationNumber            AS OperationNumber,
		|	OperationsToCreateShiftTasks.NextOperation   AS NextOperation,
		|	OperationsToCreateShiftTasks.Order                  AS OrderIsOld,
		|	OperationsAssignment.Order                               AS NewOrder_1
		|INTO TTRecords
		|FROM
		|	TTOperationAssignment AS OperationsAssignment
		|		LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|		ON OperationsAssignment.Department = OperationsToCreateShiftTasks.Department
		|			AND OperationsAssignment.Stage = OperationsToCreateShiftTasks.Stage
		|			AND OperationsAssignment.Operation = OperationsToCreateShiftTasks.Operation
		|			AND OperationsAssignment.OperationID = OperationsToCreateShiftTasks.OperationID
		|			AND OperationsAssignment.ShiftTask = OperationsToCreateShiftTasks.ShiftTask
		|			AND OperationsAssignment.Performer = OperationsToCreateShiftTasks.Performer
		|			AND OperationsAssignment.WorkCenter = OperationsToCreateShiftTasks.WorkCenter
		|			AND OperationsAssignment.WorkCenterType = OperationsToCreateShiftTasks.WorkCenterType
		|			AND OperationsAssignment.AssignNotEarlierThan = OperationsToCreateShiftTasks.AssignNotEarlierThan
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OldRecords.Department            AS Department,
		|	OldRecords.Stage                     AS Stage,
		|	OldRecords.Operation                 AS Operation,
		|	OldRecords.OperationID    AS OperationID,
		|	OldRecords.ShiftTask           AS ShiftTask,
		|	OldRecords.Performer              AS Performer,
		|	OldRecords.WorkCenter             AS WorkCenter,
		|	OldRecords.WorkCenterType        AS WorkCenterType,
		|	OldRecords.AssignNotEarlierThan         AS AssignNotEarlierThan,
		|	-OldRecords.Count              AS Count,
		|	OldRecords.TimePerPiece             AS TimePerPiece,
		|	OldRecords.SetupTime                  AS SetupTime,
		|	OldRecords.TimeUnitsOfMeasure               AS TimeUnitsOfMeasure,
		|	OldRecords.AssignmentIsAllowed           AS AssignmentIsAllowed,
		|	OldRecords.ToBeAssigned           AS ToBeAssigned,
		|	OldRecords.AssignmentProcedureIsViolated AS AssignmentProcedureIsViolated,
		|	OldRecords.ReferenceOrder             AS ReferenceOrder,
		|	OldRecords.OperationNumber            AS OperationNumber,
		|	OldRecords.NextOperation   AS NextOperation,
		|	OldRecords.OrderIsOld            AS Order
		|INTO TTOperations
		|FROM
		|	TTRecords AS OldRecords
		|
		|UNION ALL
		|
		|SELECT
		|	NewRecords.Department,
		|	NewRecords.Stage,
		|	NewRecords.Operation,
		|	NewRecords.OperationID,
		|	&ShiftTask,
		|	NewRecords.Performer,
		|	CASE
		|		WHEN WorkCenters.WorkCenterType IS NOT NULL
		|				AND NewRecords.WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|				AND WorkCenters.WorkCenterType <> NewRecords.WorkCenterType
		|			THEN VALUE(Catalog.WorkCenters.EmptyRef)
		|		WHEN WorkCenters.ProductionArea IS NOT NULL
		|				AND WorkCenters.ProductionArea <> Job.ProductionArea
		|			THEN VALUE(Catalog.WorkCenters.EmptyRef)
		|		ELSE NewRecords.WorkCenter
		|	END,
		|	CASE
		|		WHEN Job.ProductionArea <> VALUE(Catalog.ProductionSites.EmptyRef)
		|			AND NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.WorkCenters AS T
		|				WHERE
		|					T.WorkCenterType = NewRecords.WorkCenterType
		|					AND T.ProductionArea = Job.ProductionArea)
		|			THEN VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|		ELSE NewRecords.WorkCenterType
		|	END,
		|	NewRecords.AssignNotEarlierThan,
		|	NewRecords.Count,
		|	NewRecords.TimePerPiece,
		|	NewRecords.SetupTime,
		|	NewRecords.TimeUnitsOfMeasure,
		|	NewRecords.AssignmentIsAllowed,
		|	NewRecords.ToBeAssigned,
		|	NewRecords.AssignmentProcedureIsViolated,
		|	NewRecords.ReferenceOrder,
		|	NewRecords.OperationNumber,
		|	NewRecords.NextOperation,
		|	NewRecords.NewOrder_1
		|FROM
		|	TTRecords AS NewRecords
		|		LEFT JOIN Catalog.WorkCenters AS WorkCenters
		|		ON NewRecords.WorkCenter = WorkCenters.Ref
		|		LEFT JOIN Document.ShiftTask AS Job
		|		ON Job.Ref = &ShiftTask";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Operations", Operations);
	Query.SetParameter("ShiftTask", Parameters.Dimensions.ShiftTask);
	
	If Parameters.Dimensions.Performer <> Undefined Then
		
		QueryText = StrReplace(QueryText, "NewRecords.Performer", "&Performer");
		Query.SetParameter("Performer", Parameters.Dimensions.Performer);
		
	EndIf;
	
	If Parameters.Dimensions.WorkCenter <> Undefined Then
		
		QueryText = StrReplace(QueryText, "NewRecords.WorkCenter", "&WorkCenter");
		Query.SetParameter("WorkCenter", Parameters.Dimensions.WorkCenter);
		
	EndIf;
	
	If Parameters.Dimensions.WorkCenterType <> Undefined Then
		
		QueryText = StrReplace(QueryText, "NewRecords.WorkCenterType", "&WorkCenterType");
		Query.SetParameter("WorkCenterType", Parameters.Dimensions.WorkCenterType);
		
	EndIf;
	
	If Parameters.Count <> Undefined Then
		
		If Parameters.AssignThePart Then
			QueryText = StrReplace(QueryText, "OldRecords.Count",
				"CASE
				|	WHEN &Count >= OldRecords.Count
				|		THEN OldRecords.Count
				|	ELSE &Count
				|END");
		EndIf;
		
		QueryText = StrReplace(QueryText, "NewRecords.Count", "&Count");
		Query.SetParameter("Count", Parameters.Count);
		
	EndIf;
	
	Query.Text = QueryText;
	
	Query.Execute();
	
EndProcedure

Procedure CreateTTDeleteOperation(TempTablesManager, Operations)
	
	Query = New Query(
		"SELECT
		|	Operations.Department         AS Department,
		|	Operations.Stage                  AS Stage,
		|	Operations.Operation              AS Operation,
		|	Operations.OperationID AS OperationID,
		|	Operations.ShiftTask        AS ShiftTask,
		|	Operations.Performer           AS Performer,
		|	Operations.WorkCenter          AS WorkCenter,
		|	Operations.WorkCenterType     AS WorkCenterType,
		|	Operations.AssignNotEarlierThan      AS AssignNotEarlierThan
		|INTO TTOperationKeys
		|FROM
		|	&Operations AS Operations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTOperationKeys.Department                            AS Department,
		|	TTOperationKeys.Stage                                     AS Stage,
		|	TTOperationKeys.Operation                                 AS Operation,
		|	TTOperationKeys.OperationID                    AS OperationID,
		|	TTOperationKeys.ShiftTask                           AS ShiftTask,
		|	TTOperationKeys.Performer                              AS Performer,
		|	TTOperationKeys.WorkCenter                             AS WorkCenter,
		|	TTOperationKeys.WorkCenterType                        AS WorkCenterType,
		|	TTOperationKeys.AssignNotEarlierThan                         AS AssignNotEarlierThan,
		|	-ISNULL(OperationsToCreateShiftTasks.Count, 1) AS Count,
		|		// -THERE is a NULL(..., 1) negative value will not pass the control - you cannot delete operations that are missing in the register
		|	OperationsToCreateShiftTasks.TimePerPiece             AS TimePerPiece,
		|	OperationsToCreateShiftTasks.SetupTime                  AS SetupTime,
		|	OperationsToCreateShiftTasks.TimeUnitsOfMeasure               AS TimeUnitsOfMeasure,
		|	OperationsToCreateShiftTasks.AssignmentIsAllowed           AS AssignmentIsAllowed,
		|	OperationsToCreateShiftTasks.ToBeAssigned           AS ToBeAssigned,
		|	OperationsToCreateShiftTasks.AssignmentProcedureIsViolated AS AssignmentProcedureIsViolated,
		|	OperationsToCreateShiftTasks.ReferenceOrder             AS ReferenceOrder,
		|	OperationsToCreateShiftTasks.OperationNumber            AS OperationNumber,
		|	OperationsToCreateShiftTasks.NextOperation   AS NextOperation,
		|	OperationsToCreateShiftTasks.Order                  AS Order
		|INTO TTOperations
		|FROM
		|	TTOperationKeys AS TTOperationKeys
		|		LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|		ON TTOperationKeys.Department = OperationsToCreateShiftTasks.Department
		|			AND TTOperationKeys.Stage = OperationsToCreateShiftTasks.Stage
		|			AND TTOperationKeys.Operation = OperationsToCreateShiftTasks.Operation
		|			AND TTOperationKeys.OperationID = OperationsToCreateShiftTasks.OperationID
		|			AND TTOperationKeys.ShiftTask = OperationsToCreateShiftTasks.ShiftTask
		|			AND TTOperationKeys.Performer = OperationsToCreateShiftTasks.Performer
		|			AND TTOperationKeys.WorkCenter = OperationsToCreateShiftTasks.WorkCenter
		|			AND TTOperationKeys.WorkCenterType = OperationsToCreateShiftTasks.WorkCenterType
		|			AND TTOperationKeys.AssignNotEarlierThan = OperationsToCreateShiftTasks.AssignNotEarlierThan");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Operations", Operations);
	Query.Execute();
	
EndProcedure

Procedure ChangeOperations(TemporaryTableManager)
	
	ShiftJobs = New Array;
	
	StageProcessingParameters = InformationRegisters.JobsForProcessingProductionStages.StructureOfActions();
	StageProcessingParameters.RefreshStatus = True;
	
	Query = New Query(QueryTextChangeOperations());
	Query.TempTablesManager = TemporaryTableManager;
	
	SampleStage = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleStage.Next() Do
		ShiftJobs.Clear();
		
		SelectionShiftTask = SampleStage.Select(QueryResultIteration.ByGroups);
		While SelectionShiftTask.Next() Do
			ShiftJobs.Add(SelectionShiftTask.ShiftTask);
			
			Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
			Set.Filter.ShiftTask.Set(SelectionShiftTask.ShiftTask);
			Set.Filter.Stage.Set(SampleStage.Stage);
			
			Selection = SelectionShiftTask.Select();
			While Selection.Next() Do
				If Selection.Count < 0 Then
					Raise NStr("vi = 'Cố gắng sửa đổi một giao dịch không tồn tại';
								|ru = 'Попытка изменить несуществующую операцию';
								|en = 'Attempt to change a non-existing operation'; fa = 'Attempt to change a non-existing operation';
								|it = 'Tentativo di modifica di operazione inesistente';
								|pl = 'Próba zmiany operacji nieistniejącej';
								|tr = 'Var olmayan bir işlemi değiştirme denemesi'");
				ElsIf Selection.Count > 0 Then
					FillPropertyValues(Set.Add(), Selection);
				EndIf;
			EndDo;
			
			Set.Write();
		EndDo;
		
		CalculateOperations(SampleStage.Stage, ShiftJobs);
		
		InformationRegisters.JobsForProcessingProductionStages.AddJob(SampleStage.Stage, StageProcessingParameters);
	EndDo;
	
EndProcedure

Function QueryTextChangeOperations()
	
	Return
		"SELECT
		|	NestedQuery.Department          AS Department,
		|	NestedQuery.Stage                   AS Stage,
		|	NestedQuery.Operation               AS Operation,
		|	NestedQuery.OperationID  AS OperationID,
		|	NestedQuery.ShiftTask         AS ShiftTask,
		|	NestedQuery.Performer            AS Performer,
		|	NestedQuery.WorkCenter           AS WorkCenter,
		|	NestedQuery.WorkCenterType      AS WorkCenterType,
		|	CASE
		|		WHEN NestedQuery.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)
		|			THEN NestedQuery.AssignNotEarlierThan
		|		ELSE DATETIME(1, 1, 1)
		|	END                                  AS AssignNotEarlierThan,
		|	SUM(NestedQuery.Count)      AS Count,
		|	NestedQuery.TimePerPiece           AS TimePerPiece,
		|	NestedQuery.SetupTime                AS SetupTime,
		|	NestedQuery.TimeUnitsOfMeasure             AS TimeUnitsOfMeasure,
		|	FALSE                                   AS AssignmentIsAllowed,
		|	FALSE                                   AS ToBeAssigned,
		|	FALSE                                   AS AssignmentProcedureIsViolated,
		|	NestedQuery.ReferenceOrder           AS ReferenceOrder,
		|	NestedQuery.OperationNumber          AS OperationNumber,
		|	NestedQuery.NextOperation AS NextOperation,
		|	MAX(CASE
		|		WHEN NestedQuery.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|			THEN NestedQuery.Order
		|		ELSE 0
		|	END)                                 AS Order
		|FROM
		|	(SELECT
		|		OperationsToCreateShiftTasks.Department            AS Department,
		|		OperationsToCreateShiftTasks.Stage                     AS Stage,
		|		OperationsToCreateShiftTasks.Operation                 AS Operation,
		|		OperationsToCreateShiftTasks.OperationID    AS OperationID,
		|		OperationsToCreateShiftTasks.ShiftTask           AS ShiftTask,
		|		OperationsToCreateShiftTasks.Performer              AS Performer,
		|		OperationsToCreateShiftTasks.WorkCenter             AS WorkCenter,
		|		OperationsToCreateShiftTasks.WorkCenterType        AS WorkCenterType,
		|		OperationsToCreateShiftTasks.AssignNotEarlierThan         AS AssignNotEarlierThan,
		|		OperationsToCreateShiftTasks.Count               AS Count,
		|		OperationsToCreateShiftTasks.TimePerPiece             AS TimePerPiece,
		|		OperationsToCreateShiftTasks.SetupTime                  AS SetupTime,
		|		OperationsToCreateShiftTasks.TimeUnitsOfMeasure               AS TimeUnitsOfMeasure,
		|		OperationsToCreateShiftTasks.ReferenceOrder             AS ReferenceOrder,
		|		OperationsToCreateShiftTasks.OperationNumber            AS OperationNumber,
		|		OperationsToCreateShiftTasks.NextOperation   AS NextOperation,
		|		OperationsToCreateShiftTasks.Order                  AS Order
		|	FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|	WHERE
		|		OperationsToCreateShiftTasks.Stage IN
		|				(SELECT DISTINCT
		|					T.Stage
		|				FROM
		|					TTOperations AS T)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTOperations.Department,
		|		TTOperations.Stage,
		|		TTOperations.Operation,
		|		TTOperations.OperationID,
		|		TTOperations.ShiftTask,
		|		CASE
		|			WHEN TTOperations.Performer IN (UNDEFINED, VALUE(Catalog.Teams.EmptyRef))
		|				THEN VALUE(Catalog.Persons.EmptyRef)
		|			ELSE TTOperations.Performer
		|		END,
		|		TTOperations.WorkCenter,
		|		TTOperations.WorkCenterType,
		|		TTOperations.AssignNotEarlierThan,
		|		TTOperations.Count,
		|		TTOperations.TimePerPiece,
		|		TTOperations.SetupTime,
		|		TTOperations.TimeUnitsOfMeasure,
		|		TTOperations.ReferenceOrder,
		|		TTOperations.OperationNumber,
		|		TTOperations.NextOperation,
		|		TTOperations.Order
		|	FROM
		|		TTOperations AS TTOperations) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ReferenceOrder,
		|	NestedQuery.TimePerPiece,
		|	NestedQuery.SetupTime,
		|	NestedQuery.TimeUnitsOfMeasure,
		|	NestedQuery.Department,
		|	NestedQuery.WorkCenterType,
		|	NestedQuery.Operation,
		|	NestedQuery.ShiftTask,
		|	NestedQuery.Performer,
		|	NestedQuery.Stage,
		|	NestedQuery.WorkCenter,
		|	NestedQuery.OperationID,
		|	NestedQuery.OperationNumber,
		|	NestedQuery.NextOperation,
		|	CASE
		|		WHEN NestedQuery.ShiftTask = VALUE(Document.ShiftTask.EmptyRef)
		|			THEN NestedQuery.AssignNotEarlierThan
		|		ELSE DATETIME(1, 1, 1)
		|	END
		|TOTALS BY
		|	Stage,
		|	ShiftTask";
	
EndFunction

Procedure WriteErrorToEventLog(ErrorInfo)
	
	WriteLogEvent(
		NStr("vi = 'Giao dịch tạo việc làm theo ca';
			|ru = 'Операции к созданию сменных заданий';
			|en = 'Operations to create shift tasks'; fa = 'عملیات برای ایجاد وظایف شیفت';
			|it = 'Operazione per creare i compiti di turno';
			|pl = 'Operacje do tworzenia zadań zmianowych';
			|tr = 'Vardiyalı görevlerin oluşturulma işlemleri'", CommonClientServer.DefaultLanguageCode()),
		EventLogLevel.Error,,,
		DetailErrorDescription(ErrorInfo));
	
EndProcedure

Function KeyIsNotToControlDataWhenWriting() Export
	
	Return "DoNotControlDataWhenWriting";
	
EndFunction

Function RequestTextAdjustingOperations()
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("(Queue.Stage, Queue.Operation) IN (&SelectionTextOfOperationStage)");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	AssignedOperations.ShiftTask.Date                         AS Date,
		|	Operations.Stage                                                   AS Stage,
		|	Operations.OperationID                                  AS OperationID,
		|	PreshOperations.OperationID                             AS IDOfPreshOperation,
		|	PreshOperations.Scheduled - PreshOperations.RepetitionIsRequired   AS TotalCount1
		|INTO TTCommunicationOperations
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|		LEFT JOIN TTQueue AS Operations
		|		ON AssignedOperations.Department = Operations.Department
		|			AND AssignedOperations.Stage = Operations.Stage
		|			AND AssignedOperations.Operation = Operations.Operation
		|			AND AssignedOperations.OperationID = Operations.OperationID
		|		LEFT JOIN TTQueue AS PreshOperations
		|		ON AssignedOperations.Department = PreshOperations.Department
		|			AND AssignedOperations.Stage = PreshOperations.Stage
		|			AND (Operations.OperationNumber = PreshOperations.NextOperation)
		|WHERE
		|	AssignedOperations.ShiftTask = &ShiftTask
		|	AND AssignedOperations.AssignmentProcedureIsViolated
		|	
		|UNION ALL
		|
		|SELECT DISTINCT
		|	AssignedOperations.ShiftTask.Date               AS Date,
		|	Operations.Stage                                         AS Stage,
		|	Operations.OperationID                        AS OperationID,
		|	Operations.OperationID                        AS IDOfPreshOperation,
		|	Operations.Scheduled - Operations.RepetitionIsRequired   AS TotalCount1
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|		LEFT JOIN TTQueue AS Operations
		|		ON AssignedOperations.Department = Operations.Department
		|			AND AssignedOperations.Stage = Operations.Stage
		|			AND AssignedOperations.Operation = Operations.Operation
		|			AND AssignedOperations.OperationID = Operations.OperationID
		|WHERE
		|	AssignedOperations.ShiftTask = &ShiftTask
		|	AND AssignedOperations.AssignmentProcedureIsViolated
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.OperationID      AS OperationID,
		|	NestedQuery.IDOfPreshOperation AS IDOfPreshOperation,
		|	NestedQuery.TotalCount1            AS TotalCount1,
		|	SUM(NestedQuery.Count)          AS Count
		|FROM
		|	(SELECT
		|		Links.OperationID      AS OperationID,
		|		Links.IDOfPreshOperation AS IDOfPreshOperation,
		|		Links.TotalCount1            AS TotalCount1,
		|		ISNULL(Operations.Count, 0) AS Count
		|	FROM
		|		TTCommunicationOperations AS Links
		|			LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS Operations
		|			ON Links.Stage = Operations.Stage
		|				AND Links.IDOfPreshOperation = Operations.OperationID
		|				AND (Operations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef))
		|				AND Links.Date >= Operations.ShiftTask.Date
		|				AND (NOT Operations.AssignmentProcedureIsViolated)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Links.OperationID,
		|		Links.IDOfPreshOperation,
		|		Links.TotalCount1,
		|		ISNULL(Operations.Count - Operations.CountCanceled, 0)
		|	FROM
		|		TTCommunicationOperations AS Links
		|			LEFT JOIN Document.ProductionOperation2_2 AS Operations
		|			ON Links.Stage = Operations.Stage
		|				AND Links.IDOfPreshOperation = Operations.OperationID
		|				AND Links.Date >= Operations.ShiftTask.Date
		|				AND (Operations.Posted)
		|				AND (NOT Operations.RepetitionIsRequired)
		|				AND (Operations.Status <> VALUE(Enum.ProductionOperationStatuses.NotExecuted))) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.OperationID,
		|	NestedQuery.IDOfPreshOperation,
		|	NestedQuery.TotalCount1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationsToCreateShiftTasks.*
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|WHERE
		|	OperationsToCreateShiftTasks.ShiftTask = &ShiftTask
		|	AND OperationsToCreateShiftTasks.AssignmentProcedureIsViolated
		|
		|ORDER BY
		|	OperationsToCreateShiftTasks.Stage,
		|	OperationsToCreateShiftTasks.OperationNumber,
		|	OperationsToCreateShiftTasks.Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationsToCreateShiftTasks.*
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS OperationsToCreateShiftTasks
		|WHERE
		|	OperationsToCreateShiftTasks.ShiftTask = &ShiftTask
		|	AND NOT OperationsToCreateShiftTasks.AssignmentProcedureIsViolated";
	
	SelectionTextOfOperationStage = "
		|	SELECT
		|		AssignedOperations.Stage,
		|		AssignedOperations.Operation
		|	 FROM
		|		InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|	 WHERE
		|		AssignedOperations.ShiftTask = &ShiftTask";
	
	QueryText = StrReplace(QueryText, "&SelectionTextOfOperationStage", SelectionTextOfOperationStage);
	
	Return QueryText;
	
EndFunction

Procedure AddToTaskInBackground(Parameters, StorageAddress) Export
	
	Try
		
		AddToTask(Parameters.Operations, Parameters.ShiftTask);
		
	Except
		
		PutToTempStorage(
			New Structure("Messages", GetUserMessages()),
			StorageAddress);
		
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Procedure DeleteUnassignedOperationsOfOperations(Stage) Export
	
	Set = InformationRegisters.OperationsToCreateShiftTasks.CreateRecordSet();
	Set.Filter.ShiftTask.Set(Documents.ShiftTask.EmptyRef());
	Set.Filter.Stage.Set(Stage);
	Set.Write();
	
EndProcedure

Function FillingDataConstructor()
	
	FillingData = New Structure;
	FillingData.Insert("FillingMethod", "FillInByOperation");
	FillingData.Insert("Status", Enums.ProductionOperationStatuses.CreatedOn_);
	FillingData.Insert("OperationKey", ProductionManagementClientServer.ProductionOperationKey());
	FillingData.Insert("ShiftTask");
	FillingData.Insert("ReferenceOrder");
	FillingData.Insert("Department");
	FillingData.Insert("ProductionOperation");
	FillingData.Insert("ProductionArea");
	FillingData.Insert("WorkCenter");
	FillingData.Insert("SetupSettings");
	FillingData.Insert("Performer");
	FillingData.Insert("Count");
	FillingData.Insert("BOMStage");
	FillingData.Insert("ProductionLot");
	
	Return FillingData;
	
EndFunction

Function DataForFillingInOperations(ShiftTask, TransactionTable = Undefined)
	
	Result = New Array;
	Stages = New Array;
	
	Query = New Query;
	
	If TransactionTable = Undefined Then
		
		QueryText = "
		|SELECT
		|	Operations.Stage.ReferenceOrder           AS ReferenceOrder,
		|	Operations.Department               AS Department,
		|	Operations.Stage                        AS Stage,
		|	Operations.OperationID       AS OperationID,
		|	Operations.Operation                    AS Operation,
		|	Queue.ProductionOperation     AS ProductionOperation,
		|	Operations.WorkCenterType           AS WorkCenterType,
		|	Operations.WorkCenter                AS WorkCenter,
		|	Operations.Performer                 AS Performer,
		|	Operations.Count                  AS Count,
		|	Operations.Stage.Stage                   AS BOMStage,
		|	Operations.Stage.ProductionLot     AS ProductionLot,
		|	ISNULL(Operations.ShiftTask.ProductionArea, VALUE(Catalog.ProductionSites.EmptyRef))   AS ProductionArea,
		|	ISNULL(Operations.Operation.SetupSettings, Queue.ProductionOperation.SetupSettings)            AS SetupSettings
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS Operations
		|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS Queue
		|		ON Operations.Stage = Queue.Stage
		|		AND Operations.Operation = Queue.Operation
		|		AND Operations.OperationID = Queue.OperationID
		|		AND Queue.MainEntry_
		|WHERE
		|	Operations.ShiftTask = &ShiftTask
		|
		|";
		
		Query.Text = QueryText;
		Query.SetParameter("ShiftTask", ShiftTask);
		
		TransactionTable = Query.Execute().Unload();
		
	EndIf;
	
	For Each TableRow In TransactionTable Do
		
		FillingData = FillingDataConstructor();
		
		FillingData.ShiftTask = ShiftTask;
		FillingData.WorkCenter = ?(ValueIsFilled(TableRow.WorkCenter), TableRow.WorkCenter, TableRow.WorkCenterType);
		
		FillPropertyValues(FillingData, TableRow,
			"ReferenceOrder,Department,Performer,SetupSettings,ProductionArea,ProductionOperation,Count,BOMStage,ProductionLot");
			
		FillPropertyValues(FillingData.OperationKey, TableRow,
			"Stage,Operation,OperationID");
			
		Result.Add(FillingData);
		
		Stages.Add(FillingData.OperationKey.Stage);
		
	EndDo;
	
	If GetFunctionalOption("StoreOperationsInBillsOfMaterials") Then
		
		StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages);
		
		ItemList = Catalogs.BillsOfMaterials.ItemList();
		ItemList.Columns.Add("Stage");
		
		For Each KeyAndValue In StageData_1 Do
			
			Data_Stage = KeyAndValue.Value;
			
			NewRow = ItemList.Add();
			FillPropertyValues(NewRow, Data_Stage);
			NewRow.Count = Data_Stage.NumberOfPackagesPlan * Data_Stage.PackagingFactor;
			NewRow.Stage       = KeyAndValue.Key;
			
		EndDo;
		
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters();
		SelectionParameters.ListOfData.Add("Operations");
		SelectionParameters.OverridingReleasePartySetting.Use = True;
		SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
		SelectionParameters.IntermediateSemiFinishedProducts = ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet();
		
		SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(ItemList, SelectionParameters);
		
		ItemList.Indexes.Add("Stage");
		For Each FillingData In Result Do
			
			String = ItemList.Find(FillingData.OperationKey.Stage, "Stage");
			If String <> Undefined Then
				SpecificationData = SpecificationsData[ItemList.IndexOf(String)];
				Catalogs.BillsOfMaterials.ApplySelectionBasedOnSpecificationData(
								SpecificationData, New Structure("Stage", FillingData.BOMStage));
				FillingData.Insert("SpecificationData", SpecificationData);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function CreateProductionOfOperation(FillingData)
	
	MessageTemplateCreating  = NStr("vi = 'Khi tạo giao dịch sản xuất ""%1"" đã xảy ra lỗi';
									|ru = 'При создании производственной операции ""%1"" возникли ошибки';
									|en = 'Errors occurred when creating routing operation ""%1""'; fa = 'Errors occurred when creating routing operation ""%1""';
									|it = 'Si sono verificati degli errori durante la creazione dell''operazione di produzione ""%1""';
									|pl = 'Wystąpiły błędy podczas tworzenia operacji produkcyjnych ""%1""';
									|tr = '""%1"" rota işlemi oluşturulurken hata oluştu'");
	ExceptionPatternCreating = NStr("vi = 'Lỗi tạo hoạt động sản xuất';
									|ru = 'Ошибка создания производственной операции';
									|en = 'An error occurred when creating routing operation'; fa = 'An error occurred when creating routing operation';
									|it = 'Errore creazione dell''operazione di produzione';
									|pl = 'Nie można utworzyć operacji produkcyjnej';
									|tr = 'Rota işlemi oluşturulurken hata oluştu'");
	MessageTemplateAdd = NStr("vi = 'Đã vượt quá số lượng giao dịch được phép ""%1""';
								|ru = 'Превышено доступное количество операции ""%1""';
								|en = 'Available number of the ""%1"" operation is exceeded'; fa = 'Available number of the ""%1"" operation is exceeded';
								|it = 'Available number of the ""%1"" operation is exceeded';
								|pl = 'Available number of the ""%1"" operation is exceeded';
								|tr = '""%1"" işleminin mevcut miktarı aşıldı'");
	ExceptionTemplateAdd = NStr("vi = 'Lỗi thêm giao dịch sản xuất vào ca làm việc';
								|ru = 'Ошибка добавления производственной операции в сменное задание';
								|en = 'An error occurred when adding a routing operation to the shift task'; fa = 'An error occurred when adding a routing operation to the shift task';
								|it = 'An error occurred when adding a routing operation to the shift task';
								|pl = 'An error occurred when adding a routing operation to the shift task';
								|tr = 'Vardiyalı göreve rota işlemi eklenirken hata oluştu'");
	
	RecordOperations = New Array;
	
	If Not ValueIsFilled(FillingData.OperationKey.Operation)
		And ValueIsFilled(FillingData.ProductionOperation) Then
		
		OperationObjectIndividual = FillingData.ProductionOperation.GetObject(); // DocumentObject.ProductionOperation2_2
		ProductionAccounting.BlockProductionOperation(OperationObjectIndividual);
		
		If FillingData.Count = OperationObjectIndividual.Count - OperationObjectIndividual.CountCanceled Then
			OperationObject = OperationObjectIndividual;
		ElsIf FillingData.Count > OperationObjectIndividual.Count - OperationObjectIndividual.CountCanceled Then
			Common.MessageToUser(StrTemplate(MessageTemplateAdd, OperationObjectIndividual.Description));
			Raise ExceptionTemplateAdd;
		Else
			Parameters = Documents.ProductionOperation2_2.SplittingParametersOfOperationConstructor();
			Parameters.Count = FillingData.Count;
			Parameters.RunTime = OperationObjectIndividual.RunTime * (FillingData.Count/OperationObjectIndividual.Count);
			OperationObjectIndividual.SetSplitMode();
			OperationObject = Documents.ProductionOperation2_2.SelectOperation_(OperationObjectIndividual, Parameters);
			RecordOperations.Add(OperationObjectIndividual);
		EndIf;
		
		FillPropertyValues(OperationObject, FillingData, "ShiftTask,Status,Performer,ProductionArea,WorkCenter");
		RecordOperations.Add(OperationObject);
		
	Else
		
		OperationObject = Documents.ProductionOperation2_2.CreateDocument();
		OperationObject.Fill(FillingData);
		
		RecordOperations.Add(OperationObject);
		
	EndIf;
	
	For Each OperationObject In RecordOperations Do
		
		If FillingData.Status = Enums.ProductionOperationStatuses.Executed
				And Not OperationObject.CheckFilling() Then
				
				Common.MessageToUser(StrTemplate(MessageTemplateCreating, OperationObject.Description));
				Raise ExceptionPatternCreating;
				
		EndIf;
		
		OperationObject.SetGroupProcessingMode();
		OperationObject.Write(DocumentWriteMode.Posting);
		
	EndDo;
	
	Return OperationObject;
	
EndFunction

#EndRegion

#EndIf
