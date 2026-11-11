
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Writes operation_2_2 data to the register of Operations that are to be deleted when
//	the schedule is saved later at the user's command.
//
// Parameters:
//  TimetableModel - UUID - the model identity (version) of the schedule.
//  Operations - ValueTable - operation data, columns:
//		* Stage - DocumentRef.ProductionStage2_2 -
//		* Operation - CatalogRef.ManufacturingOperations -
//		* OperationID - Number - the operation identifier.
//		* WorkCenter - String, CatalogRef.WorkCenters - the work center where the operation is performed.
//		* Begin - Date - start of the operation execution interval.
//		* Ending - Date - end of the operation execution interval.
//
Procedure RecordOperationsToDelete(Val TimetableModel, Val Operations) Export
	
	If ValueIsFilled(TimetableModel) And ValueIsFilled(Operations) Then
		
		Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
		Set.Filter.TimetableModel.Set(TimetableModel);
		Set.Filter.ThisIsOperationDeletion.Set(True);
		Set.Load(Operations);
		
		For Each Record In Set Do
			
			Record.TimetableModel = TimetableModel;
			Record.Modeling = True;
			Record.ThisIsOperationDeletion = True;
			
		EndDo;
	    	
		Set.Write();
		
	EndIf;
	
EndProcedure

// Writes the schedule option to the IB. A variant is understood as a schedule,
//	before it is saved by the user's command (see the procedure to record the schedule).
//
// Parameters:
//  TimetableModel - UUID - the model identity (version) of the schedule.
//  PlanningModel - CatalogRef.MESModels - the planning model
//		that the calculation is based on.
//  Schedule - ValueTable - the table structure is similar to the structure of the operation_2_2 register.
//
Procedure RecordScheduleOption(Val TimetableModel, Val PlanningModel, Val Schedule) Export
	
	If ValueIsFilled(TimetableModel) And ValueIsFilled(Schedule) Then
		
		Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
		Set.Filter.TimetableModel.Set(TimetableModel);
		Set.Filter.PlanningModel.Set(PlanningModel);
		Set.Filter.ThisIsOperationDeletion.Set(False);
		Set.Load(Schedule);
		
		For Each Record In Set Do
			
			Record.TimetableModel = TimetableModel;
			Record.PlanningModel = PlanningModel;
			Record.Modeling = True;
			
		EndDo;
		
		Set.Write();
		
	EndIf;
	
EndProcedure

// Updates the production schedule-saves the selected schedule option and clears the temporary simulation data.
//
// Parameters:
//  TimetableModel - UUID - the model identity (version) of the schedule.
//  PlanningModel - CatalogRef.MESModels - the scheduling model
//		that the recorded schedule belongs to.
//  WritingCompleted	- Boolean - flag for successful recording.
//
Procedure RecordASchedule(Val TimetableModel, Val PlanningModel, WritingCompleted) Export
	
	BeginTransaction();
	
	Try
		
		If ValueIsFilled(TimetableModel) Then
			UpdateSchedule(TimetableModel, PlanningModel);
			ClearScheduleScheduleModel(TimetableModel);
		EndIf;
		
		WritingCompleted = True;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Ghi lại lịch trình giao dịch';
				|ru = 'Запись пооперационного расписания';
				|en = 'Save operation timetable'; fa = 'Save operation timetable';
				|it = 'Registrazione dell''orario delle operazioni';
				|pl = 'Zapis harmonogramu operacyjnego';
				|tr = 'Yürütme çizelgesi kaydı'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
		WritingCompleted = False;
		
		Raise;
		
	EndTry;
	
EndProcedure

// Defines the number of hosted operations that belong to the schedule model.
//
// Parameters:
//  TimetableModel - UUID - the model identity (version) of the schedule.
//
// Returns:
//  Number - the number of operations.
//
Function NumberOfUniqueScheduleModelOperations(Val TimetableModel) Export
	
	Query = New Query(
	"SELECT ALLOWED
	|	NestedQuery.PlanningModel AS PlanningModel,
	|	SUM(NestedQuery.OperationsCount) AS OperationsCount
	|FROM
	|	(SELECT
	|		PostOperativeSchedule.PlanningModel AS PlanningModel,
	|		PostOperativeSchedule.Stage AS Stage,
	|		COUNT(DISTINCT PostOperativeSchedule.OperationID) AS OperationsCount
	|	FROM
	|		InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|	WHERE
	|		PostOperativeSchedule.TimetableModel = &TimetableModel
	|		AND PostOperativeSchedule.Modeling = TRUE
	|		AND PostOperativeSchedule.ThisIsOperationDeletion = FALSE
	|	
	|	GROUP BY
	|		PostOperativeSchedule.PlanningModel,
	|		PostOperativeSchedule.Stage) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.PlanningModel
	|TOTALS
	|	SUM(OperationsCount)
	|BY
	|	OVERALL");
	
	Query.SetParameter("TimetableModel", TimetableModel);
	Selection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	If Selection.Next() And ValueIsFilled(Selection.OperationsCount) Then
		Result = Selection.OperationsCount;
	Else
		Result = 0;
	EndIf;
	
	Return Result;
	
EndFunction

// Clears the simulation data for the operational schedule.
//
// Parameters:
//  TimetableModel - UUID - ID of the model (variant) to clear the schedule for.
//
Procedure ClearScheduleScheduleModel(Val TimetableModel) Export
	
	Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
	Set.Filter.TimetableModel.Set(TimetableModel);
	Set.Write();
	
EndProcedure

// Recalculates quantitative resources for the specified process operation.
//
// Parameters:
//  OperationKey - Structure - Where:
//  *Stage	 	 - DocumentRef.ProductionStage2_2		 - stage of production.
//  *Operation 	 - CatalogRef.ManufacturingOperations	 - technological operation.
//  LotNumber - Number		 							 - batch number for the operation.
//  Cancel	 - Boolean									 - indicates that processing of the event has been interrupted.
//
Procedure RecalculateQuantitativeResourcesByKey(Val OperationKey, LotNumber, Cancel = False) Export
	
	BlockScheduleForRecordingByKey(OperationKey, LotNumber, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	OperationEnvironment = OperationEnvironmentInSchedule(OperationKey);
	
	OperationKey.Insert("LotNumber", LotNumber);
	OperationData = FindOperationByKey(OperationEnvironment, OperationKey);
	If OperationData = Undefined Then
		Return;
	EndIf;
	
	BlockDataForCalculatingOperation(OperationKey.Stage, OperationData, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	RecalculateByOperation(OperationKey.Stage, OperationData, LotNumber, Cancel);
	
EndProcedure

// Returns operation data from the schedule
//
// Parameters:
//  OperationKey - Structure - Where:
//  *Stage	 	 - DocumentRef.ProductionStage2_2		 - stage of production.
//  *Operation 	 - CatalogRef.ManufacturingOperations	 - technological operation.
//  LotNumber	 - Number		 							 - batch number for the operation.
//  WorkCenter - CatalogRef.WorkCenters	 		 - operation work center.
// 
// Returns:
//   - Structure - operation data from the schedule.
//
Function ScheduleOperationData(OperationKey, LotNumber, WorkCenter) Export
	
	QueryText = "
	|SELECT
	|	Schedule.Department AS Department,
	|	Schedule.Operation AS Operation,
	|	Schedule.WorkCenter.WorkCenterType AS WorkCenterType,
	|	Schedule.WorkCenter AS WorkCenter,
	|	Schedule.Operation.UnitOfMeasure AS UnitOfMeasure,
	|	ISNULL(Schedule.Operation.Skippable, FALSE) AS Skippable,
	|	Schedule.Stage AS Stage,
	|	Schedule.LotQuantity AS Scheduled,
	|	CASE
	|		WHEN Schedule.LotQuantity + Schedule.RepetitionIsRequired > Schedule.CreatedOn
	|			THEN Schedule.LotQuantity + Schedule.RepetitionIsRequired - Schedule.CreatedOn
	|		ELSE 0
	|	END AS WaitingForCreation,
	|	Schedule.PendingPredecessorCompletion AS PendingPredecessorCompletion,
	|	Schedule.PreviousOnesStarted AS PreviousOnesStarted,
	|	Schedule.ExecutionIsAllowed AS ExecutionIsAllowed,
	|	Schedule.Running AS Running,
	|	Schedule.Completed2 AS Completed2,
	|	Schedule.RepetitionIsRequired AS RepetitionIsRequired,
	|	Schedule.Skipped3 AS Skipped3,
	|	Schedule.LotNumber AS LotNumber,
	|	Schedule.OperationID AS OperationID,
	|	&TechProcessParameters
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS Schedule
	|
	|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|	ON Schedule.Stage = TechnicalProcess.Stage
	|
	|WHERE
	|	Schedule.Stage = &Stage
	|	AND Schedule.Operation = &Operation
	|	AND Schedule.OperationID = &OperationID
	|	AND Schedule.LotNumber = &LotNumber
	|	AND NOT Schedule.ThisIsOperationDeletion
	|	AND NOT Schedule.Secondary
	|	AND NOT Schedule.Modeling
	|	AND NOT Schedule.AdditionalRecord";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage("Schedule.Stage"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", OperationKey.Stage);
	Query.SetParameter("Operation", OperationKey.Operation);
	Query.SetParameter("OperationID", OperationKey.OperationID);
	Query.SetParameter("LotNumber", LotNumber);
		
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	OperationData = New Structure();
	
	For Each Column In QueryResult.Columns Do
		OperationData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	FillPropertyValues(OperationData, Selection);
	
	Return OperationData;
	
EndFunction

// Clears the operation schedule data by operation key.
//
// Parameters:
//  OperationKey - Structure - key of the operation to clear the schedule for.
//	LotNumber - Number - the batch number of the transaction.
//	Cancel	 - Boolean - indicates that processing of the event has been interrupted.
//
Procedure ClearScheduleByKey(OperationKey, LotNumber, Cancel = False) Export
	
	Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
	Set.Filter.Stage.Set(OperationKey.Stage);
	Set.Filter.Operation.Set(OperationKey.Operation);
	Set.Filter.OperationID.Set(OperationKey.OperationID);
	Set.Filter.LotNumber.Set(LotNumber);
	Set.Write();
	
EndProcedure

#EndRegion

#Region Private

Procedure UpdateSchedule(Val TimetableModel, Val PlanningModel)
	
	QueryText = RequestTextUpdatingSchedule();
	Query = New Query(QueryText);
	Query.SetParameter("TimetableModel", TimetableModel);
	Query.SetParameter("PlanningModel", PlanningModel);
	
	SetTable = New ValueTable;
	ProductionManagementWhenPlanningServer.FillInTableStructureByRegisterMetadata("InformationRegisters", "PostOperativeSchedule2_2", SetTable);
	SetTable.Columns.Add("Required2", New TypeDescription("Number", New NumberQualifiers()));
	SetTable.Columns.Add("OperationNumber", New TypeDescription("Number", New NumberQualifiers()));
	SetTable.Columns.Add("NextOperation", New TypeDescription("Number", New NumberQualifiers()));
	
	SamplingStages = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingStages.Next() Do
		
		SetTable.Clear();
		Selection = SamplingStages.Select();
		While Selection.Next() Do
			
			SetRow = SetTable.Add();
			FillPropertyValues(SetRow, Selection);
			
		EndDo;
		
		BatchTable_ = SetTable.Copy(, "Operation, OperationID, LotNumber, WorkCenter");//ValueTable - 
		BatchTable_.GroupBy("Operation, OperationID, LotNumber, WorkCenter");
		FilterStructure1 = New Structure("Operation, OperationID, LotNumber, WorkCenter");
		For Each BatchString In BatchTable_ Do
			
			FillPropertyValues(FilterStructure1, BatchString);
			SetStrings = SetTable.FindRows(FilterStructure1);
			CalculateOperationPerformanceIndicators(SetStrings, SetStrings[0]);
			
		EndDo;
		
		Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
		Set.Filter.Stage.Set(SamplingStages.Stage);
		Set.Load(SetTable);
		
		Set.Write();
		
	EndDo;
	
EndProcedure

Function RequestTextUpdatingSchedule()
	
	Result = 
	"SELECT
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.LotNumber AS LotNumber,
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	PostOperativeSchedule.WorkCenter AS WorkCenter
	|INTO DeleteOperations_3
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.ThisIsOperationDeletion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.LotNumber AS LotNumber,
	|	PostOperativeSchedule.WorkCenter AS WorkCenter,
	|	PostOperativeSchedule.TimetableModel AS TimetableModel,
	|	PostOperativeSchedule.PlanningModel AS PlanningModel,
	|	PostOperativeSchedule.ThisIsOperationDeletion AS ThisIsOperationDeletion,
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	PostOperativeSchedule.ParallelLoadTime AS ParallelLoadTime,
	|	PostOperativeSchedule.TimePlan AS TimePlan,
	|	PostOperativeSchedule.Load AS Load,
	|	PostOperativeSchedule.ThisIsChangeover AS ThisIsChangeover,
	|	PostOperativeSchedule.LotQuantity AS LotQuantity,
	|	PostOperativeSchedule.ZoomRatio AS ZoomRatio,
	|	PostOperativeSchedule.CreatedOn AS CreatedOn,
	|	PostOperativeSchedule.PendingPredecessorCompletion AS PendingPredecessorCompletion,
	|	PostOperativeSchedule.PreviousOnesStarted AS PreviousOnesStarted,
	|	PostOperativeSchedule.ExecutionIsAllowed AS ExecutionIsAllowed,
	|	PostOperativeSchedule.Running AS Running,
	|	PostOperativeSchedule.Completed2 AS Completed2,
	|	PostOperativeSchedule.RepetitionIsRequired AS RepetitionIsRequired,
	|	PostOperativeSchedule.Skipped3 AS Skipped3,
	|	PostOperativeSchedule.TransferTime AS TransferTime,
	|	PostOperativeSchedule.Department AS Department,
	|	PostOperativeSchedule.Secondary AS Secondary,
	|	PostOperativeSchedule.Modeling AS Modeling,
	|	PostOperativeSchedule.LeftLimit AS LeftLimit,
	|	PostOperativeSchedule.RightBorder_ AS RightBorder_,
	|	PostOperativeSchedule.AdditionalRecord AS AdditionalRecord,
	|	PostOperativeSchedule.IntervalDuration AS IntervalDuration,
	|	PostOperativeSchedule.DisableToCreateOperations AS DisableToCreateOperations
	|INTO ScheduleOption1_
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.PlanningModel = &PlanningModel
	|	AND PostOperativeSchedule.Modeling
	|	AND NOT PostOperativeSchedule.ThisIsOperationDeletion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Stage AS Stage
	|INTO ProductionStages
	|FROM
	|	(SELECT
	|		DeleteOperations_3.Stage AS Stage
	|	FROM
	|		DeleteOperations_3 AS DeleteOperations_3
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ScheduleOption1_.Stage
	|	FROM
	|		ScheduleOption1_ AS ScheduleOption1_) AS NestedQuery
	|
	|INDEX BY
	|	Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostOperativeSchedule.TimetableModel AS TimetableModel,
	|	PostOperativeSchedule.PlanningModel AS PlanningModel,
	|	PostOperativeSchedule.Modeling AS Modeling,
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.LotNumber AS LotNumber,
	|	PostOperativeSchedule.WorkCenter AS WorkCenter,
	|	PostOperativeSchedule.TimetableModel AS TimetableModel1,
	|	PostOperativeSchedule.PlanningModel AS PlanningModel1,
	|	PostOperativeSchedule.ThisIsOperationDeletion AS ThisIsOperationDeletion,
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	PostOperativeSchedule.ParallelLoadTime AS ParallelLoadTime,
	|	PostOperativeSchedule.TimePlan AS TimePlan,
	|	PostOperativeSchedule.Load AS Load,
	|	PostOperativeSchedule.ThisIsChangeover AS ThisIsChangeover,
	|	PostOperativeSchedule.LotQuantity AS LotQuantity,
	|	PostOperativeSchedule.ZoomRatio AS ZoomRatio,
	|	PostOperativeSchedule.CreatedOn AS CreatedOn,
	|	PostOperativeSchedule.PendingPredecessorCompletion AS PendingPredecessorCompletion,
	|	PostOperativeSchedule.PreviousOnesStarted AS PreviousOnesStarted,
	|	PostOperativeSchedule.ExecutionIsAllowed AS ExecutionIsAllowed,
	|	PostOperativeSchedule.Running AS Running,
	|	PostOperativeSchedule.Completed2 AS Completed2,
	|	PostOperativeSchedule.RepetitionIsRequired AS RepetitionIsRequired,
	|	PostOperativeSchedule.Skipped3 AS Skipped3,
	|	PostOperativeSchedule.TransferTime AS TransferTime,
	|	PostOperativeSchedule.Department AS Department,
	|	PostOperativeSchedule.Secondary AS Secondary,
	|	PostOperativeSchedule.Modeling AS Modeling1,
	|	PostOperativeSchedule.LeftLimit AS LeftLimit,
	|	PostOperativeSchedule.RightBorder_ AS RightBorder_,
	|	PostOperativeSchedule.AdditionalRecord AS AdditionalRecord,
	|	PostOperativeSchedule.IntervalDuration AS IntervalDuration,
	|	PostOperativeSchedule.DisableToCreateOperations AS DisableToCreateOperations,
	|	QueueOfProductionOperations.Required2 AS Required2,
	|	QueueOfProductionOperations.OperationNumber AS OperationNumber,
	|	QueueOfProductionOperations.NextOperation AS NextOperation
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS QueueOfProductionOperations
	|		ON PostOperativeSchedule.Stage = QueueOfProductionOperations.Stage
	|			AND PostOperativeSchedule.Operation = QueueOfProductionOperations.Operation
	|			AND PostOperativeSchedule.OperationID = QueueOfProductionOperations.OperationID
	|			AND QueueOfProductionOperations.MainEntry_
	|WHERE
	|	PostOperativeSchedule.Stage IN
	|			(SELECT
	|				ProductionStages.Stage AS Stage
	|			FROM
	|				ProductionStages)
	|	AND NOT (PostOperativeSchedule.Stage, PostOperativeSchedule.Operation, PostOperativeSchedule.OperationID, PostOperativeSchedule.LotNumber) IN
	|				(SELECT
	|					DeleteOperations_3.Stage AS Stage,
	|					DeleteOperations_3.Operation AS Operation,
	|					DeleteOperations_3.OperationID AS OperationID,
	|					DeleteOperations_3.LotNumber AS LotNumber
	|				FROM
	|					DeleteOperations_3)
	|	AND NOT PostOperativeSchedule.Modeling
	|
	|UNION ALL
	|
	|SELECT
	|	UNDEFINED,
	|	UNDEFINED,
	|	FALSE,
	|	ScheduleOption1_.Stage,
	|	ScheduleOption1_.Operation,
	|	ScheduleOption1_.OperationID,
	|	ScheduleOption1_.LotNumber,
	|	ScheduleOption1_.WorkCenter,
	|	ScheduleOption1_.TimetableModel,
	|	ScheduleOption1_.PlanningModel,
	|	ScheduleOption1_.ThisIsOperationDeletion,
	|	ScheduleOption1_.Begin,
	|	ScheduleOption1_.Ending,
	|	ScheduleOption1_.ParallelLoadTime,
	|	ScheduleOption1_.TimePlan,
	|	ScheduleOption1_.Load,
	|	ScheduleOption1_.ThisIsChangeover,
	|	ScheduleOption1_.LotQuantity,
	|	ScheduleOption1_.ZoomRatio,
	|	ScheduleOption1_.CreatedOn,
	|	ScheduleOption1_.PendingPredecessorCompletion,
	|	ScheduleOption1_.PreviousOnesStarted,
	|	ScheduleOption1_.ExecutionIsAllowed,
	|	ScheduleOption1_.Running,
	|	ScheduleOption1_.Completed2,
	|	ScheduleOption1_.RepetitionIsRequired,
	|	ScheduleOption1_.Skipped3,
	|	ScheduleOption1_.TransferTime,
	|	ScheduleOption1_.Department,
	|	ScheduleOption1_.Secondary,
	|	ScheduleOption1_.Modeling,
	|	ScheduleOption1_.LeftLimit,
	|	ScheduleOption1_.RightBorder_,
	|	ScheduleOption1_.AdditionalRecord,
	|	ScheduleOption1_.IntervalDuration,
	|	ScheduleOption1_.DisableToCreateOperations,
	|	QueueOfProductionOperations.Required2,
	|	QueueOfProductionOperations.OperationNumber,
	|	QueueOfProductionOperations.NextOperation
	|FROM
	|	ScheduleOption1_ AS ScheduleOption1_
	|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS QueueOfProductionOperations
	|		ON ScheduleOption1_.Stage = QueueOfProductionOperations.Stage
	|			AND ScheduleOption1_.Operation = QueueOfProductionOperations.Operation
	|			AND ScheduleOption1_.OperationID = QueueOfProductionOperations.OperationID
	|			AND QueueOfProductionOperations.MainEntry_
	|TOTALS BY
	|	Stage";
	
	Return Result;
	
EndFunction

#Region RecalculationByOperation

Procedure BlockScheduleForRecordingByKey(OperationKey, LotNumber, Cancel = False) Export
	
	DataLock = New DataLock;
	
	LockItem = DataLock.Add("InformationRegister.PostOperativeSchedule2_2");
	LockItem.Mode = DataLockMode.Exclusive;
	
	LockItem.SetValue("Stage", OperationKey.Stage);
	LockItem.SetValue("Operation", OperationKey.Operation);
	LockItem.SetValue("OperationID", OperationKey.OperationID);
	LockItem.SetValue("LotNumber", LotNumber);
	
	Try
		DataLock.Lock();
	Except
		
		MessageText = NStr("vi = 'Không thể chặn lịch giao dịch: %Cause%';
							|ru = 'Не удалось заблокировать пооперационное расписание: %Cause%';
							|en = 'Cannot lock the operation timetable. Reason: %Cause%'; fa = 'Cannot lock the operation timetable. Reason: %Cause%';
							|it = 'Impossibile bloccare il programma operativo:%Cause%';
							|pl = 'Nie można zablokować harmonogramu operacyjnego: %Cause%';
							|tr = 'Yürütme çizelgesi bloke edilemedi: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", BriefErrorDescription(ErrorInfo()));
		
		CommonClientServer.MessageToUser(
				MessageText,
				,
				,
				, 
				Cancel); 
			
	EndTry;
	
EndProcedure

Procedure BlockDataForCalculatingOperation(Stage, OperationData, Cancel)
	
	DataLock = New DataLock;
	
	Sequence = OperationData.Owner();
	
	For Each CurrentRow In Sequence Do
		
		LockItem = DataLock.Add("Document.ProductionOperation2_2");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem.SetValue("Stage",     Stage);
		LockItem.SetValue("Operation", CurrentRow.Operation);
		LockItem.SetValue("OperationID", CurrentRow.OperationID);
		LockItem.SetValue("LotNumber", CurrentRow.LotNumber);
		
		If CurrentRow.OperationNumber = OperationData.NextOperation 
			Or CurrentRow = OperationData Then
		
			LockItem = DataLock.Add("InformationRegister.PostOperativeSchedule2_2");
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem.SetValue("Stage",     Stage);
			LockItem.SetValue("Operation", CurrentRow.Operation);
			LockItem.SetValue("OperationID", CurrentRow.OperationID);
			LockItem.SetValue("LotNumber", CurrentRow.LotNumber);
			
		EndIf;
		
	EndDo;
	
	Try
		DataLock.Lock();
	Except
		
		MessageText = NStr("vi = 'Không thể chặn lịch giao dịch: %Cause%';
							|ru = 'Не удалось заблокировать пооперационное расписание: %Cause%';
							|en = 'Cannot lock the operation timetable. Reason: %Cause%'; fa = 'Cannot lock the operation timetable. Reason: %Cause%';
							|it = 'Impossibile bloccare il programma operativo:%Cause%';
							|pl = 'Nie można zablokować harmonogramu operacyjnego: %Cause%';
							|tr = 'Yürütme çizelgesi bloke edilemedi: %Cause%'");
		MessageText = StrReplace(MessageText, "%Cause%", BriefErrorDescription(ErrorInfo()));
		
		CommonClientServer.MessageToUser(
				MessageText,
				,
				,
				, 
				Cancel); 
			
	EndTry;
	
EndProcedure

Procedure RecalculateByOperation(Stage, OperationData, LotNumber, Cancel)
	
	AddExecutionResultsToOperations(Stage, OperationData.Owner());
	
	Sequence = FollowingOperations(OperationData);
	Operations = OtherBatchOperations(OperationData);
	For It = 0 To Operations.UBound() Do
		Sequence.Insert(It, Operations[It]);
	EndDo;
	Sequence.Insert(0, OperationData);
	
	Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
	
	For Each CurrentRow In Sequence Do
		
		Set.Filter.Stage.Set(Stage);
		Set.Filter.Operation.Set(CurrentRow.Operation);
		Set.Filter.OperationID.Set(CurrentRow.OperationID);
		Set.Filter.LotNumber.Set(CurrentRow.LotNumber);
		
		Set.Read();
		
		If Set.Count() = 0 Then
			InformUserAboutCalculationError(Cancel);
			Return;
		EndIf;
		
		CalculateOperationPerformanceIndicators(Set, CurrentRow);
		
		Try
			Set.Write(True);
		Except
			InformUserAboutCalculationError(Cancel);
			Return;
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Sequence

Function PreviousOperations_(Cursor)
	
	Filter = New Structure("NextOperation", Cursor.OperationNumber);
	
	Return Cursor.Owner().FindRows(Filter);
	
EndFunction

Function FollowingOperations(Cursor)
	
	Filter = New Structure("OperationNumber", Cursor.NextOperation);
	
	Return Cursor.Owner().FindRows(Filter);
	
EndFunction

Function OtherBatchOperations(Cursor)
	
	Result = New Array;
	Filter = New Structure;
	Filter.Insert("OperationNumber", Cursor.OperationNumber);
	Filter.Insert("OperationID", Cursor.OperationID);
	Filter.Insert("AdditionalRecord", False);
	Filter.Insert("ThisIsChangeover", False);
	Filter.Insert("Secondary", False);
	
	FoundRows = Cursor.Owner().FindRows(Filter);
	For Each FoundRow In FoundRows Do
		If FoundRow.LotNumber = Cursor.LotNumber Then
			Continue;
		EndIf;
		Result.Add(FoundRow);
	EndDo;			 
	
	Return Result;
	
EndFunction

Function OperationEnvironmentInSchedule(OperationKey)
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.AttributesOfContractorOfOperation = True;
	RequestTextParameters.AttributesOfTimeOfOperation = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage = &Stage");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrentOperation.Operation AS Operation,
	|	CurrentOperation.ProductionOperation AS ProductionOperation,
	|	CurrentOperation.OperationID AS OperationID,
	|	CurrentOperation.OperationNumber AS OperationNumber,
	|	CurrentOperation.NextOperation AS NextOperation,
	|	CurrentOperation.Required2 AS Required2,
	|	CurrentOperation.Scheduled - CurrentOperation.RepetitionIsRequired AS Scheduled,
	|	CurrentOperation.TimeUnitsOfMeasure AS ExecutionTimeUnitOfMeasure
	|INTO TTCurOperation
	|FROM
	|	TTQueue AS CurrentOperation
	|WHERE
	|	CurrentOperation.OperationID = &OperationID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FollowingOperations.Operation AS Operation,
	|	FollowingOperations.ProductionOperation AS ProductionOperation,
	|	FollowingOperations.OperationID AS OperationID,
	|	FollowingOperations.OperationNumber AS OperationNumber,
	|	FollowingOperations.NextOperation AS NextOperation,
	|	FollowingOperations.Required2 AS Required2,
	|	FollowingOperations.Scheduled - FollowingOperations.RepetitionIsRequired AS Scheduled,
	|	FollowingOperations.TimeUnitsOfMeasure AS ExecutionTimeUnitOfMeasure
	|INTO TTFollowingOperations
	|FROM
	|	TTQueue AS FollowingOperations
	|WHERE
	|	FollowingOperations.OperationNumber IN
	|			(SELECT
	|				CurrentOperation.NextOperation
	|			FROM
	|				TTCurOperation AS CurrentOperation)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FollowingOperations.Operation AS Operation,
	|	FollowingOperations.ProductionOperation AS ProductionOperation,
	|	FollowingOperations.OperationID AS OperationID,
	|	FollowingOperations.OperationNumber AS OperationNumber,
	|	FollowingOperations.NextOperation AS NextOperation,
	|	FollowingOperations.Required2 AS Required2,
	|	FollowingOperations.Scheduled AS Scheduled,
	|	FollowingOperations.ExecutionTimeUnitOfMeasure AS ExecutionTimeUnitOfMeasure
	|INTO TTOperations
	|FROM
	|	TTFollowingOperations AS FollowingOperations
	|
	|UNION ALL
	|
	|SELECT
	|	PreviousOperations_.Operation,
	|	PreviousOperations_.ProductionOperation,
	|	PreviousOperations_.OperationID,
	|	PreviousOperations_.OperationNumber,
	|	PreviousOperations_.NextOperation,
	|	PreviousOperations_.Required2,
	|	PreviousOperations_.Scheduled - PreviousOperations_.RepetitionIsRequired,
	|	PreviousOperations_.TimeUnitsOfMeasure
	|FROM
	|	TTQueue AS PreviousOperations_
	|WHERE
	|	PreviousOperations_.NextOperation IN
	|			(SELECT
	|				CurrentOperation.OperationNumber
	|			FROM
	|				TTCurOperation AS CurrentOperation
	|		
	|			UNION ALL
	|		
	|			SELECT
	|				FollowingOperations.OperationNumber
	|			FROM
	|				TTFollowingOperations AS FollowingOperations)
	|
	|UNION ALL
	|
	|SELECT
	|	CurrentOperation.Operation,
	|	CurrentOperation.ProductionOperation,
	|	CurrentOperation.OperationID,
	|	CurrentOperation.OperationNumber,
	|	CurrentOperation.NextOperation,
	|	CurrentOperation.Required2,
	|	CurrentOperation.Scheduled,
	|	CurrentOperation.ExecutionTimeUnitOfMeasure
	|FROM
	|	TTCurOperation AS CurrentOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Operations.Operation AS Operation,
	|	Operations.ProductionOperation AS ProductionOperation,
	|	Operations.OperationID AS OperationID,
	|	Operations.OperationNumber AS OperationNumber,
	|	Operations.NextOperation AS NextOperation,
	|	Operations.Required2 AS Required2,
	|	Operations.Scheduled AS Scheduled,
	|	Operations.ExecutionTimeUnitOfMeasure AS ExecutionTimeUnitOfMeasure,
	|	PostOperativeSchedule2_2.LotNumber AS LotNumber,
	|	PostOperativeSchedule2_2.WorkCenter AS WorkCenter,
	|	PostOperativeSchedule2_2.LotQuantity AS PlannedForParty,
	|	PostOperativeSchedule2_2.ZoomRatio AS ZoomRatio,
	|	PostOperativeSchedule2_2.AdditionalRecord AS AdditionalRecord,
	|	PostOperativeSchedule2_2.Secondary AS Secondary,
	|	PostOperativeSchedule2_2.ThisIsChangeover AS ThisIsChangeover,
	|	PostOperativeSchedule2_2.Begin AS Begin
	|FROM
	|	TTOperations AS Operations
	|		INNER JOIN InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule2_2
	|		ON Operations.Operation = PostOperativeSchedule2_2.Operation
	|			AND Operations.OperationID = PostOperativeSchedule2_2.OperationID
	|WHERE
	|	PostOperativeSchedule2_2.Stage = &Stage
	|	AND NOT PostOperativeSchedule2_2.ThisIsOperationDeletion
	|	AND NOT PostOperativeSchedule2_2.Modeling
	|	AND NOT PostOperativeSchedule2_2.AdditionalRecord
	|	AND NOT PostOperativeSchedule2_2.Secondary
	|
	|ORDER BY
	|	PostOperativeSchedule2_2.Begin";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", OperationKey.Stage);
	Query.SetParameter("OperationID", OperationKey.OperationID);
	
	Return Query.Execute().Unload();
	
EndFunction

Function FindOperationByKey(TransactionList, OperationKey)
	
	FilterOperation = New Structure("Operation, OperationID, LotNumber");
	FillPropertyValues(FilterOperation, OperationKey);
	FilterOperation.Insert("AdditionalRecord", False);
	FilterOperation.Insert("Secondary", False);
	
	FoundRows = TransactionList.FindRows(FilterOperation);
	If FoundRows.UBound() <> -1 Then
		Return FoundRows[0];
	EndIf;
	Return Undefined;

EndFunction

#EndRegion

#Region Other

// Parameters:
// 	Stage - DocumentRef.ProductionStage2_2 - 
// 	Operations - ValueTable - from a query in the Operationsreferences()
//
Procedure AddExecutionResultsToOperations(Stage, Operations)
	
	ExecutionOfOperations = ResultOfOperations(
		Stage, 
		Operations.Copy(,"Operation, OperationID, LotNumber"));
		
	TypeDescription = New TypeDescription(
		"Number", 
		New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	Operations.Columns.Add("CreatedOn",     TypeDescription);
	Operations.Columns.Add("PendingPredecessorCompletion",     TypeDescription);
	Operations.Columns.Add("PreviousOnesStarted", TypeDescription);
	Operations.Columns.Add("ExecutionIsAllowed",   TypeDescription);
	Operations.Columns.Add("Running", TypeDescription);
	Operations.Columns.Add("Completed2",   TypeDescription);
	Operations.Columns.Add("RepetitionIsRequired", TypeDescription);
	Operations.Columns.Add("Skipped3",         TypeDescription);
		
	FilterOperation = New Structure("Operation, OperationID, LotNumber");
	
	For Each OperationData In Operations Do
		
		FillPropertyValues(FilterOperation, OperationData);
		FoundRows = ExecutionOfOperations.FindRows(FilterOperation);
		
		If FoundRows.UBound() <> -1 Then
			
			FillPropertyValues(
				OperationData,
				FoundRows[0],
				"CreatedOn,
				|Running,
				|Completed2,
				|RepetitionIsRequired,
				|Skipped3");
						
		EndIf;
		
	EndDo;
	
EndProcedure

Function ResultOfOperations(Stage, Operations)
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	FilterOperations.Operation AS Operation,
	|	FilterOperations.OperationID AS OperationID,
	|	FilterOperations.LotNumber AS LotNumber
	|INTO TTOperationSelection
	|FROM
	|	&FilterOperations AS FilterOperations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionOperation.Operation AS Operation,
	|	ProductionOperation.OperationID AS OperationID,
	|	ProductionOperation.LotNumber AS LotNumber,
	|	SUM(CASE
	|			WHEN ProductionOperation.Status IN (&CreatedStatus, &RunningStatus, &StatusSkipped)
	|				THEN ProductionOperation.Count
	|						- ProductionOperation.CountCanceled
	|			WHEN ProductionOperation.Status = &StatusCompleted
	|				THEN ProductionOperation.CountReal
	|						+ ProductionOperation.FollowUp
	|						+ ProductionOperation.QuantityUnderRevision
	|						+ ProductionOperation.DefectiveGoodsCount
	|			ELSE 0
	|		END) AS CreatedOn,
	|	SUM(CASE
	|			WHEN ProductionOperation.Status = &RunningStatus
	|				THEN ProductionOperation.Count
	|						- ProductionOperation.CountCanceled
	|						- ProductionOperation.DefectiveGoodsCount
	|						- ProductionOperation.CountReal
	|			ELSE 0
	|		END) AS Running,
	|	SUM(CASE
	|			WHEN ProductionOperation.Status IN (&RunningStatus, &StatusCompleted)
	|				THEN ProductionOperation.CountReal
	|			ELSE 0
	|		END) AS Completed2,
	|	SUM(CASE
	|			WHEN ProductionOperation.Status = &StatusCompleted
	|					AND ProductionOperation.RepetitionIsRequired
	|				THEN ProductionOperation.CountReal
	|			ELSE 0
	|		END) AS RepetitionIsRequired,
	|	SUM(CASE
	|			WHEN ProductionOperation.Status = &StatusSkipped
	|				THEN ProductionOperation.Count
	|						- ProductionOperation.CountCanceled
	|			ELSE 0
	|		END) AS Skipped3
	|FROM
	|	Document.ProductionOperation2_2 AS ProductionOperation
	|WHERE
	|	ProductionOperation.Stage = &Stage
	|	AND (ProductionOperation.Operation, ProductionOperation.OperationID, ProductionOperation.LotNumber) IN
	|			(SELECT
	|				TTOperationSelection.Operation,
	|				TTOperationSelection.OperationID,
	|				TTOperationSelection.LotNumber
	|			FROM
	|				TTOperationSelection AS TTOperationSelection)
	|	AND ProductionOperation.Status <> &StatusFailed
	|	AND ProductionOperation.Posted
	|
	|GROUP BY
	|	ProductionOperation.Operation,
	|	ProductionOperation.OperationID,
	|	ProductionOperation.LotNumber";
	
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("FilterOperations", Operations);
	Query.SetParameter("CreatedStatus", Enums.ProductionOperationStatuses.CreatedOn_);
	Query.SetParameter("RunningStatus", Enums.ProductionOperationStatuses.Running);
	Query.SetParameter("StatusCompleted", Enums.ProductionOperationStatuses.Executed);
	Query.SetParameter("StatusSkipped", Enums.ProductionOperationStatuses.IsSkipped);
	Query.SetParameter("StatusFailed", Enums.ProductionOperationStatuses.NotExecuted);
	
	Result = Query.Execute().Unload();
	Result.Indexes.Add("Operation, OperationID, LotNumber");
	
	Return Result;
	
EndFunction

Function CalculateOperationPerformanceIndicators(SetOfOperations, OperationData)
	
	Operation = SetOfOperations[0];
	FillPropertyValues(
		Operation,
		OperationData,
		"CreatedOn,
		|Running,
		|Completed2,
		|RepetitionIsRequired,
		|Skipped3");
		
	Operation.PendingPredecessorCompletion = 0;
	Operation.PreviousOnesStarted   = 0;
	Operation.ExecutionIsAllowed         = 0;
	
	PreviousOperations_ = PreviousOperations_(OperationData);
	If PreviousOperations_.Count() = 0 Then
		
		Operation.ExecutionIsAllowed = Max(Operation.LotQuantity + Operation.RepetitionIsRequired, Operation.CreatedOn)
			- (Operation.Running + Operation.Completed2 + Operation.Skipped3);
			
	Else
		
		ArrayOfPreviousOnes = New Array;
		ArrayOfQuantities = New Array;
		
		For Each PreviousOperation In PreviousOperations_ Do
			
			ZoomRatio = 1;
			If PreviousOperation.Required2 > 0 Then
				ZoomRatio = OperationData.Required2 / PreviousOperation.Required2;
			EndIf;
			
			IndexOf = ArrayOfPreviousOnes.Find(PreviousOperation.OperationID);
			If IndexOf = Undefined Then
				
				ArrayOfPreviousOnes.Add(PreviousOperation.OperationID);
				StructureOfQuantities = New Structure;
				StructureOfQuantities.Insert("PerformedByPrevious", PreviousOperation.Running * ZoomRatio);
				StructureOfQuantities.Insert("CompletedPrevious", 
					(PreviousOperation.Completed2 - PreviousOperation.RepetitionIsRequired + PreviousOperation.Skipped3) * ZoomRatio);
				ArrayOfQuantities.Add(StructureOfQuantities);
				
			Else
				
				PreviousQuantities = ArrayOfQuantities[IndexOf];
				PreviousQuantities.PerformedByPrevious = PreviousQuantities.PerformedByPrevious + PreviousOperation.Running * ZoomRatio;
				PreviousQuantities.CompletedPrevious = PreviousQuantities.CompletedPrevious 
					+ (PreviousOperation.Completed2 - PreviousOperation.RepetitionIsRequired + PreviousOperation.Skipped3) * ZoomRatio;

			EndIf;
			
		EndDo;
		
		OtherParties = OtherBatchOperations(OperationData);
		
		PreviousOnesStarted = -1;
		PerformedPrevious = -1;
		
		For Each PreviousQuantities In ArrayOfQuantities Do
			
			PreviousOnesStarted = ?(PreviousOnesStarted = -1, PreviousQuantities.PerformedByPrevious + PreviousQuantities.CompletedPrevious, 
									Min(PreviousQuantities.PerformedByPrevious + PreviousQuantities.CompletedPrevious, PreviousOnesStarted));
									
			PerformedPrevious = ?(PerformedPrevious = -1, PreviousQuantities.CompletedPrevious, 
									Min(PreviousQuantities.CompletedPrevious, PerformedPrevious));
			
		EndDo;
		
		For Each AnotherParty In OtherParties Do
			
			PreviousOnesStarted = PreviousOnesStarted - AnotherParty.PreviousOnesStarted - AnotherParty.ExecutionIsAllowed - AnotherParty.Running - AnotherParty.Completed2;
			PerformedPrevious = PerformedPrevious - AnotherParty.ExecutionIsAllowed - AnotherParty.Running - AnotherParty.Completed2;
			
		EndDo;
		
		PerformedPrevious = Max(PerformedPrevious, 0);
		PreviousOnesStarted = Max(PreviousOnesStarted - PerformedPrevious, 0);		
		
		PendingExecution = Max(Operation.LotQuantity + Operation.RepetitionIsRequired, Operation.CreatedOn)
			- (Operation.Running + Operation.Completed2 + Operation.Skipped3);
		
		Operation.ExecutionIsAllowed = Max(Min(PerformedPrevious - Operation.Running - Operation.Completed2 - Operation.Skipped3, PendingExecution), 0);
		
		Operation.PreviousOnesStarted = Min(PreviousOnesStarted, PendingExecution - Operation.ExecutionIsAllowed);
		Operation.PendingPredecessorCompletion = PendingExecution - Operation.ExecutionIsAllowed - Operation.PreviousOnesStarted;
		
		FillPropertyValues(OperationData, Operation, "PendingPredecessorCompletion, PreviousOnesStarted, ExecutionIsAllowed");
		
	EndIf;
	
	If Not SetOfOperations.Count() = 1 Then
		
		PropertyString = "CreatedOn, PendingPredecessorCompletion, PreviousOnesStarted, PreviousOnesStarted, ExecutionIsAllowed, Running, Completed2, 
		|RepetitionIsRequired, Skipped3";
		For IndexOf = 1 To SetOfOperations.Count() - 1 Do
			FillPropertyValues(SetOfOperations[IndexOf], Operation, PropertyString);
		EndDo;
	EndIf;
	
EndFunction

Procedure InformUserAboutCalculationError(Cancel)
	
	MessageText = NStr("vi = 'Không thể tính toán giao dịch sản xuất.';
						|ru = 'Не удалось рассчитать выполнение производственных операций.';
						|en = 'Cannot calculate routing operation execution.'; fa = 'Cannot calculate routing operation execution.';
						|it = 'Impossibile calcolare l''esecuzione delle operazioni di produzione.';
						|pl = 'Nie udało się obliczyć wykonanie operacji produkcyjnych.';
						|tr = 'Rota işlemlerinin gerçekleştirilmesi hesaplanamadı.'");
	
	CommonClientServer.MessageToUser(
			MessageText,
			,
			,
			, 
			Cancel);

EndProcedure

#EndRegion

#EndRegion

#EndIf
