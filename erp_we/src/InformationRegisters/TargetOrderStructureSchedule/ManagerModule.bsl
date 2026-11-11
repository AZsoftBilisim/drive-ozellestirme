#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Procedure StartCalculation() Export
	
	ExportProcedureName = "InformationRegisters.TargetOrderStructureSchedule.Calculate";
	ExportProcedureParameters = New Array();
	
	If Common.DebugMode() Or Common.FileInfobase() Then
		
		Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Return;
		
	EndIf;
	
	Var_Key = "TargetOrderStructureSchedule";
	
	SetPrivilegedMode(True);
	Jobs = BackgroundJobs.GetBackgroundJobs(New Structure("Key, State", Var_Key, BackgroundJobState.Active));
	SetPrivilegedMode(False);
	
	If Jobs.UBound() = -1 Then
		
		JobDescription = NStr("vi = 'Tính toán lịch biểu sản xuất tiêu chuẩn. Luồng điều khiển';
								|ru = 'Расчет нормативного графика производства. Управляющий поток';
								|en = 'Standard production schedule calculation. Thread of control'; fa = 'Standard production schedule calculation. Thread of control';
								|it = 'Calcolo grafico normativo di produzione. Flusso gestionale';
								|pl = 'Obliczenie normatywnego harmonogramu produkcji. Przepływ zarządzający';
								|tr = 'Standart üretim programının hesaplanması. Yönetim akışı'");
		
		JobParameters = New Array;
		
		JobParameters.Add(ExportProcedureName);
		JobParameters.Add(ExportProcedureParameters);
		
		BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
		
	EndIf;

EndProcedure

// The calculation of the regulatory schedule is performed.
// 
// Returns:
//  Boolean - Calculation is in progress
Function CalculationIsRunning() Export
	
	SearchKey = New Structure("Key, State", "TargetOrderStructureSchedule", BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	Jobs = BackgroundJobs.GetBackgroundJobs(SearchKey);
	SetPrivilegedMode(False);
	
	Return (Jobs.Count() > 0 And Jobs[0].State = BackgroundJobState.Active);
	
EndFunction

#EndRegion

#Region Internal

// Control flow
Procedure Calculate() Export
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
		Return;
	EndIf;
	
	// Batch buffer cleaning
	Query = New Query(
		"SELECT TOP 100000
		|	Buffer.Area             AS Area,
		|	Buffer.ProductionOrder AS ProductionOrder,
		|	Buffer.KeyLot          AS KeyLot,
		|	Buffer.Stage                AS Stage,
		|	Buffer.RecordSeparator   AS RecordSeparator
		|FROM
		|	InformationRegister.BufferOfTargetProductionScheduleCalculation AS Buffer");
	For Cnt = 1 To 10 Do
		SetPrivilegedMode(True);
		BufferEntries = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If BufferEntries.Count() = 0 Then
			Break;
		EndIf;
		
		Set = InformationRegisters.BufferOfTargetProductionScheduleCalculation.CreateRecordSet();
		Set.Load(BufferEntries);
		SetPrivilegedMode(True);
		Set.Write(ReplacementMode.Delete);
		SetPrivilegedMode(False);
	EndDo;
	
	// Reading assignments
	Query.Text =
		"SELECT DISTINCT
		|	Jobs.ProductionOrder AS ProductionOrder
		|INTO ExceptionOrders
		|FROM
		|	InformationRegister.TasksOfBOMOrderStructureCalculation AS Jobs
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Jobs.ProductionOrder AS ProductionOrder
		|FROM
		|	InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Jobs
		|WHERE
		|	Jobs.ProductionOrder <> VALUE(Document.ProductionOrder2_2.EmptyRef)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Jobs.ProductionOrder AS ProductionOrder
		|FROM
		|	InformationRegister.OrderStructureCalculationProtocol AS Jobs
		|WHERE
		|	Jobs.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError)
		|
		|INDEX BY
		|	ProductionOrder
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Jobs.ProductionOrder            AS ProductionOrder,
		|	Jobs.Separator                    AS Separator,
		|	Jobs.ProductionStage               AS ProductionStage,
		|	Jobs.KeyLot                     AS KeyLot,
		|	CASE
		|		WHEN RegulatorySchedule.Ending IS NULL
		|			THEN DATETIME(1, 1, 1)
		|		WHEN RegulatorySchedule.Ending = RegulatorySchedule.Begin
		|			THEN RegulatorySchedule.Ending
		|		ELSE DATEADD(RegulatorySchedule.Ending, SECOND, 1)
		|	END                                  AS IntervalMax,
		|	RegulatorySchedule.Ending IS NULL  AS CompleteRecalculation,
		|	NOT &TextOfOrderFieldHasBeenSubmittedForProduction AS CancellationOfOrder
		|FROM
		|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
		|		
		|		LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS RegulatorySchedule
		|		ON Jobs.KeyLot <> &EmptyLinkKey
		|			AND Jobs.ProductionOrder = RegulatorySchedule.ProductionOrder
		|			AND Jobs.KeyLot = RegulatorySchedule.KeyLot
		|			AND RegulatorySchedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|WHERE
		|	Jobs.ProductionOrder NOT IN (
		|		SELECT
		|			T.ProductionOrder AS ProductionOrder
		|		FROM
		|			ExceptionOrders AS T)
		|ORDER BY
		|	ProductionOrder
		|TOTALS
		|	MAX(IntervalMax),
		|	MAX(CompleteRecalculation),
		|	MAX(CancellationOfOrder)
		|BY
		|	Jobs.ProductionOrder";
	Query.Text = StrReplace(Query.Text, "&TextOfOrderFieldHasBeenSubmittedForProduction",
		OrderStructureDocumentPosting.TextOfOrderFieldHasBeenSubmittedForProduction("Jobs.ProductionOrder"));
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Jobs = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	CalculationParameters = NewCalculationParameters();
	
	While Jobs.Rows.Count() > 0 Do
		
		For IndexOf = -Jobs.Rows.Count()+1 To 0 Do
			
			Job = Jobs.Rows[-IndexOf];
			
			If Job.CancellationOfOrder Then
				
				Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
				Set.Filter.ProductionOrder.Set(Job.ProductionOrder);
				SetPrivilegedMode(True);
				Set.Write();
				SetPrivilegedMode(False);
				
				ProcessCalculationResult(Job, NewOrderCalculationResult());
				
			Else
				
				ProcedureParameters = New Structure;
				ProcedureParameters.Insert("ProductionOrder", Job.ProductionOrder);
				ProcedureParameters.Insert("Boundary", ?(Job.CompleteRecalculation, '00010101', Job.IntervalMax));
				
				PlaceInQueue = GetPlaceInCalculationQueue(CalculationParameters);
				
				ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
				ExecutionParameters.BackgroundJobDescription = StrTemplate(NStr("vi = 'Tính toán lịch biểu tiêu chuẩn (%1)';
																				|ru = 'Расчет нормативного графика (%1)';
																				|en = 'Standard schedule calculation (%1)'; fa = 'Standard schedule calculation (%1)';
																				|it = 'Calcolo grafico normativo (%1)';
																				|pl = 'Obliczenie harmonogramu normatywnego (%1)';
																				|tr = 'Standart programın hesaplanması (%1)'"),
					PlaceInQueue + 1);
				ExecutionParameters.RunNotInBackground1 = Not CalculationParameters.VectorizeCalculation;
				ExecutionParameters.ResultAddress = PutToTempStorage(Undefined,
					New UUID);
				ExecutionParameters.WaitCompletion = 0;
				
				RunResult = TimeConsumingOperations.ExecuteInBackground(
					"InformationRegisters.TargetOrderStructureSchedule.CalculateOrderSchedule",
					ProcedureParameters,
					ExecutionParameters);
				
				If RunResult.Status = "Running" Then
					QueueItem = New Structure;
					QueueItem.Insert("Id", RunResult.JobID);
					QueueItem.Insert("ResultAddress", RunResult.ResultAddress);
					QueueItem.Insert("Job", Job);
					CalculationParameters.CalculationQueue[PlaceInQueue] = QueueItem;
				Else
					If RunResult.Status = "Completed2" Then
						ProcessCalculationResult(Job, RunResult.ResultAddress);
					Else
						ProcessCalculationError(CalculationParameters, RunResult.DetailErrorDescription);
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ExpectCalculationCompletion(CalculationParameters, True);
		
		If Jobs.Rows.Count() = 0 Then
			// Continuing task processing
			Jobs = Query.Execute().Unload(QueryResultIteration.ByGroups);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure RecalculateOrderSchedule(ProductionOrder) Export
	
	BeginTransaction();
	Try
		ClearErrorLog(ProductionOrder);
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddJob(ProductionOrder);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	StartCalculation();
	
EndProcedure

#EndRegion

#Region Private

#Region StartingCalculation

Function GetPlaceInCalculationQueue(CalculationParameters)
	
	PlaceInQueue = 0;
	
	If CalculationParameters.VectorizeCalculation Then
		
		PlaceInQueue = CalculationParameters.CalculationQueue.Find(Undefined);
		
		If PlaceInQueue = Undefined Then
			
			ExpectCalculationCompletion(CalculationParameters, False);
			PlaceInQueue = CalculationParameters.CalculationQueue.Find(Undefined);
			
		EndIf;
		
	EndIf;
	
	Return PlaceInQueue;
	
EndFunction

Function ExpectCalculationCompletion(CalculationParameters, ExpectCompletionOfCalculationOfAllThreads)
	
	CalculationIsCompleted = False;
	CalculationQueue = CalculationParameters.CalculationQueue;
	
	FilterStructure1 = New Structure();
	
	SetPrivilegedMode(True);
	
	While Not CalculationIsCompleted Do
		
		ActiveTasks = New Array();
		ThereAreCompletedTasks = False;
		
		For Stream = 0 To CalculationQueue.UBound() Do
			
			If CalculationQueue[Stream] = Undefined Then
				Continue;
			EndIf;
			
			TheCalculationIsPerformed = True;
			
			QueueItem = CalculationQueue[Stream]; // Structure
			FilterStructure1.Insert("UUID", QueueItem.Id);
			JobsList = BackgroundJobs.GetBackgroundJobs(FilterStructure1);
			
			If JobsList.UBound() <> -1 Then
				
				If JobsList[0].State = BackgroundJobState.Active Then
					ActiveTasks.Add(JobsList[0].UUID);
					Continue;
				EndIf;
				
				If JobsList[0].State = BackgroundJobState.Failed Then
					
					ProcessCalculationError(
						CalculationParameters,
						DetailErrorDescription(JobsList[0].ErrorInfo));
					TheCalculationIsPerformed = False;
					
				EndIf;
				
			EndIf;
			
			If TheCalculationIsPerformed Then
				ProcessCalculationResult(CalculationQueue[Stream].Job, CalculationQueue[Stream].ResultAddress);
			EndIf;
			
			CalculationQueue[Stream] = Undefined;
			ThereAreCompletedTasks = True;
			
		EndDo;
		
		CalculationIsCompleted = (ThereAreCompletedTasks And Not ExpectCompletionOfCalculationOfAllThreads)
			Or Not ValueIsFilled(ActiveTasks);
		
		If Not CalculationIsCompleted Then
			
			Job = BackgroundJobs.FindByUUID(ActiveTasks[0]);
			
			If Job <> Undefined Then
				Job.WaitForExecutionCompletion(CalculationParameters.IntervalForCheckingCompletionOfCalculation);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return CalculationIsCompleted;
	
EndFunction

Procedure ProcessCalculationResult(Job, Result)
	
	CalculationResult2 = ?(TypeOf(Result) = Type("String"),
		GetFromTempStorage(Result),
		Result);
	
	If CalculationResult2 <> Undefined
		And Not CalculationResult2.Cancel
		And Job.Rows.Count() > 0 Then
		Set = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet();
		For Each String In Job.Rows Do
			FillPropertyValues(Set.Add(), String,
				"ProductionOrder, Separator, ProductionStage, KeyLot");
		EndDo;
		SetPrivilegedMode(True);
		Set.Write(ReplacementMode.Delete);
		SetPrivilegedMode(False);
	EndIf;
	
	Job.Owner().Rows.Delete(Job);
	
EndProcedure

Procedure ProcessCalculationError(CalculationParameters, DetailErrorDescription)
	
	If CalculationParameters.ErrorLimit = 1 Then
		Raise DetailErrorDescription;
	EndIf;
	
	CalculationParameters.ErrorLimit = CalculationParameters.ErrorLimit - 1;
	
EndProcedure

#EndRegion

#Region CalculationStart

// Calculate the order schedule.
// 
// Parameters:
//  Parameters - Structure:
//    * ProductionOrder - DocumentRef.ProductionOrder2_2
//    * Boundary - Date
//  ResultAddress - String - Address in temporary storage for placing the result.
//
Procedure CalculateOrderSchedule(Parameters, ResultAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"IntershopManagement2_2.OrderStructureCalculationOfRegulatorySchedule");
	
	CalculationResult2 = CalculateOrderScheduleInsideTimeMeasurement(Parameters.ProductionOrder, Parameters.Boundary);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(
		MeasurementDetails, CalculationResult2.NumberOfStages);
	
	PutToTempStorage(CalculationResult2, ResultAddress);
	
EndProcedure

Function CalculateOrderScheduleInsideTimeMeasurement(ProductionOrder, Boundary)
	
	CalculationResult2 = NewOrderCalculationResult();
	
	// Reading order data (only placement "To the end" and the assembly process are supported)
	Query = New Query(
		"SELECT
		|	OrderData.Ref AS ProductionOrder,
		|	CASE
		|		WHEN NOT OrderData.DemandDateIsSpecifiedInLines THEN 
		|			OrderData.DemandDate
		|		ELSE
		|			ISNULL(MAX(OrderProducts_.DemandDate), OrderData.Date)
		|	END               AS StartOfPlacement
		|INTO PlacementBoundaries
		|FROM
		|	Document.ProductionOrder2_2 AS OrderData
		|		LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
		|		ON OrderData.Ref = OrderProducts_.Ref
		|				AND NOT OrderProducts_.Canceled
		|				AND OrderData.DemandDateIsSpecifiedInLines 
		|WHERE
		|	OrderData.Ref = &ProductionOrder
		|
		|GROUP BY
		|	OrderData.Ref
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	OrderData.Ref                                  AS ProductionOrder,
		|	NOT TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			InformationRegister.TargetOrderStructureSchedule AS T
		|		WHERE
		|			T.ProductionOrder = OrderData.Ref) AS FirstCalculation,
		|	OrderData.ProductionProcessType
		|		= VALUE(Enum.ProductionProcessTypes.PerformRM) AS ThisIsRepair,
		|	OrderData.ProductionProcessType
		|		= VALUE(Enum.ProductionProcessTypes.Disassembly)                 AS ThisIsDisassembly,
		|	FALSE                                                 AS GoBackToBeginning,
		|	PlacementBoundaries.StartOfPlacement                   AS StartOfPlacement
		|FROM
		|	Document.ProductionOrder2_2 AS OrderData, PlacementBoundaries 
		|WHERE
		|	OrderData.Ref = &ProductionOrder");
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	SourceData = Query.Execute().Select();
	If Not SourceData.Next()
		Or SourceData.ThisIsDisassembly Then
		Return CalculationResult2;
	ElsIf Not ValueIsFilled(SourceData.StartOfPlacement) Then
		ErrorDescription = NewErrorDescription();
		ErrorDescription.Code = ErrorCodeDateOfNeedNotFilledIn();
		ErrorDescription.GoBackToBeginning = False;
		WriteError(ProductionOrder, ProductionOrder.UUID(), ErrorDescription);
		
		CalculationResult2.Cancel = True;
		Return CalculationResult2;
	EndIf;
	
	// Variable initialization
	CompleteCalculation = (Boundary = '00010101');
	
	UseBuffer = UseBuffer()
		And Not SourceData.FirstCalculation
		And CompleteCalculation;
	Area = ?(UseBuffer,
		New UUID(),
		New UUID("00000000-0000-0000-0000-000000000000"));
	
	// Caching the order structure
	OrderStructureCache = New TempTablesManager();
	CacheOrderStructure(OrderStructureCache, SourceData, CompleteCalculation);
	
	// Preparing to receive graph data
	CacheCharts = New TempTablesManager();
	Schedules = New Array;
	ReadCharts(CacheCharts, Schedules);
	
	// Reading stages
	If CompleteCalculation Then
		
		// Full settlement
		ScheduleForRecording = Undefined;
		PlacementData = FirstNodes(SourceData, OrderStructureCache);
		RecordSeparator = BegOfMonth(SourceData.StartOfPlacement);
		
		If Not UseBuffer
				And Not SourceData.FirstCalculation Then
			Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
			Set.Filter.ProductionOrder.Set(ProductionOrder);
			SetPrivilegedMode(True);
			Set.Write();
			SetPrivilegedMode(False);
		EndIf;
		
	Else
		
		// Recalculate
		ScheduleForRecording = Undefined;
		PlacementData = NodesToRecalculate(SourceData, OrderStructureCache, Boundary, ScheduleForRecording);
		RecordSeparator = BegOfMonth(Boundary);
		
	EndIf;
	
	// Location
	CyclesWithoutPlacement = 0;
	While PlacementData.Nodes.Count() <> 0
		Or ScheduleForRecording <> Undefined Do
		
		ClockCycleParameters = NewClockParameters();
		ClockCycleParameters.CompleteCalculation = CompleteCalculation;
		ClockCycleParameters.RecordSeparator = RecordSeparator;
		ClockCycleParameters.OrderStructureCache = OrderStructureCache;
		ClockCycleParameters.UseBuffer = UseBuffer;
		ClockCycleParameters.Area = Area;
		FillPropertyValues(ClockCycleParameters, SourceData,
			"ProductionOrder, GoBackToBeginning, StartOfPlacement, ThisIsRepair");
		
		ReadSchedule(
			ClockCycleParameters,
			CacheCharts,
			Schedules,
			RecordSeparator,
			EndOfMonth(RecordSeparator));
		
		ResultOfCycle = PerformCalculationCycle(ClockCycleParameters, PlacementData, ScheduleForRecording);
		CalculationResult2.NumberOfStages = CalculationResult2.NumberOfStages + ResultOfCycle.NumberOfStages;
		
		If ResultOfCycle.Cancel Then
			CalculationResult2.Cancel = True;
			Break;
		EndIf;
		
		If ResultOfCycle.NumberOfStages <> 0 Then
			CalculationResult2.Begin = Min(CalculationResult2.Begin, ResultOfCycle.Begin);
			CalculationResult2.Ending = Max(CalculationResult2.Ending, ResultOfCycle.Ending);
		EndIf;
		
		// Protected from looping
		CyclesWithoutPlacement = ?(ResultOfCycle.NumberOfStages = 0, CyclesWithoutPlacement + 1, 0);
		If CyclesWithoutPlacement >= 100
				And PlacementData.Nodes.Count() <> 0 Then
			Stage = PlacementData.Nodes[0].Stages[0];
			HandleCalculationLooping(ClockCycleParameters.ProductionOrder, Stage.KeyLot, Stage.Stage);
			CalculationResult2.Cancel = True;
			Break;
		EndIf;
		
		RecordSeparator = ?(SourceData.GoBackToBeginning,
			EndOfMonth(RecordSeparator)+1,
			BegOfMonth(RecordSeparator-1));
		
	EndDo;
	
	// Clearing periods on the right (left)
	If Not CompleteCalculation And Not CalculationResult2.Cancel Then
		
		QueryText = 
			"SELECT DISTINCT
			|	RegulatorySchedule.RecordSeparator AS RecordSeparator
			|FROM
			|	InformationRegister.TargetOrderStructureSchedule AS RegulatorySchedule
			|WHERE
			|	RegulatorySchedule.ProductionOrder = &ProductionOrder
			|	AND RegulatorySchedule.KeyLot <> &EmptyLinkKey
			|	AND RegulatorySchedule.RecordSeparator >= &RecordSeparator";
		
		If Not SourceData.GoBackToBeginning Then
			QueryText = StrReplace(QueryText, ">=", "<=");
		EndIf;
		
		Query = New Query(QueryText);
		Query.SetParameter("ProductionOrder", ProductionOrder);
		Query.SetParameter("RecordSeparator", RecordSeparator);
		Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
			Set.Filter.ProductionOrder.Set(ProductionOrder);
			Set.Filter.RecordSeparator.Set(Selection.RecordSeparator);
			SetPrivilegedMode(True);
			Set.Write();
			SetPrivilegedMode(False);
			
		EndDo;
		
	EndIf;
	
	If Not CalculationResult2.Cancel Then
		
		ClearErrorLog(ProductionOrder);
		
		If UseBuffer Then
			
			// Transferring data from the buffer to the graph
			Query = New Query(
				"SELECT
				|	Buffer.ProductionOrder AS ProductionOrder,
				|	Buffer.KeyLot          AS KeyLot,
				|	Buffer.Stage                AS Stage,
				|	Buffer.RecordSeparator   AS RecordSeparator,
				|	Buffer.Begin              AS Begin,
				|	Buffer.Ending           AS Ending,
				|	Buffer.StartOfPlacement    AS StartOfPlacement
				|FROM
				|	InformationRegister.BufferOfTargetProductionScheduleCalculation AS Buffer
				|WHERE
				|	Buffer.Area = &Area");
			Query.SetParameter("Area", Area);
			
			Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
			Set.Filter.ProductionOrder.Set(ProductionOrder);
			
			SetPrivilegedMode(True);
			BufferEntries = Query.Execute().Unload();
			SetPrivilegedMode(False);
			Set.Load(BufferEntries);
			
			// The final line for the order
			If CalculationResult2.NumberOfStages <> 0 Then
				Record = Set.Add();
				Record.ProductionOrder = ProductionOrder;
				Record.Stage = Catalogs.ProductionStages.EmptyRef();
				FillPropertyValues(Record, CalculationResult2, "Begin, Ending");
			EndIf;
			
			SetPrivilegedMode(True);
			Set.Write();
			SetPrivilegedMode(False);
			
			// Clearing the buffer
			Set = InformationRegisters.BufferOfTargetProductionScheduleCalculation.CreateRecordSet();
			Set.Filter.Area.Set(Area);
			SetPrivilegedMode(True);
			Set.Write();
			SetPrivilegedMode(False);
			
		Else
			
			// The final line for the order
			If CalculationResult2.NumberOfStages <> 0 Then
				If Not CompleteCalculation Then
					Query = New Query(
						"SELECT
						|	Schedule.Begin    AS Begin,
						|	Schedule.Ending AS Ending
						|FROM
						|	InformationRegister.TargetOrderStructureSchedule AS Schedule
						|WHERE
						|	Schedule.ProductionOrder = &ProductionOrder
						|	AND Schedule.KeyLot = &EmptyLinkKey
						|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)");
					Query.SetParameter("ProductionOrder", ProductionOrder);
					Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						If SourceData.GoBackToBeginning Then
							CalculationResult2.Begin = Selection.Begin;
						Else
							CalculationResult2.Ending = Selection.Ending;
						EndIf;
					EndIf;
				EndIf;
				
				Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
				Set.Filter.ProductionOrder.Set(ProductionOrder);
				Set.Filter.KeyLot.Set(New UUID("00000000-0000-0000-0000-000000000000"));
				Set.Filter.Stage.Set(Catalogs.ProductionStages.EmptyRef());
				
				Record = Set.Add();
				Record.ProductionOrder = ProductionOrder;
				Record.Stage = Catalogs.ProductionStages.EmptyRef();
				FillPropertyValues(Record, CalculationResult2, "Begin, Ending");
				
				SetPrivilegedMode(True);
				Set.Write();
				SetPrivilegedMode(False);
			Else
				// Deleting the final line
				Query = New Query(
					"SELECT TOP 2
					|	Schedule.KeyLot AS KeyLot
					|FROM
					|	InformationRegister.TargetOrderStructureSchedule AS Schedule
					|WHERE
					|	Schedule.ProductionOrder = &ProductionOrder");
				Query.SetParameter("ProductionOrder", ProductionOrder);
				Selection = Query.Execute().Select();
				If Selection.Count() = 1 Then
					Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
					Set.Filter.ProductionOrder.Set(ProductionOrder);
					Set.Filter.KeyLot.Set(New UUID("00000000-0000-0000-0000-000000000000"));
					Set.Filter.Stage.Set(Catalogs.ProductionStages.EmptyRef());
					
					SetPrivilegedMode(True);
					Set.Write();
					SetPrivilegedMode(False);
				EndIf;
			EndIf;
		
		EndIf;
		
	EndIf;
	
	OrderStructureCache.Close();
	
	Return CalculationResult2;
	
EndFunction

// Perform the calculation cycle.
// 
// Parameters:
//  ClockCycleParameters - Structure - 
//  PlacementData - Structure - 
//  ScheduleForRecording - ValueTable - Schedule to record.
// 
// Returns:
//  Structure - The result of the calculation cycle:
// * Cancel - Boolean -
// * NumberOfStages - Number -
// * Begin - Date -
// * Ending - Date -
Function PerformCalculationCycle(ClockCycleParameters, PlacementData, ScheduleForRecording)
	
	ResultOfCycle = NewResultOfCalculationCycle();
	
	KeyOfCurStage =   ?(ClockCycleParameters.GoBackToBeginning, "StageNumber", "NextStageNo");
	KeyToNextStage = ?(ClockCycleParameters.GoBackToBeginning, "NextStageNo", "StageNumber");
	
	LinkSearchStructure = New Structure("KeyIsPredecessorParty, PredecessorStage");
	SearchStructureSeparator = New Structure("RecordSeparator");
	
	SubstitutionRecording = Not ClockCycleParameters.CompleteCalculation;
	PlacementData.Stages.FillValues(True, "PlaceInCurCycle");
	
	While PlacementData.Nodes.Count() <> 0
		Or ScheduleForRecording <> Undefined Do
		
		RegulatorySchedule = ?(ClockCycleParameters.UseBuffer,
			InformationRegisters.BufferOfTargetProductionScheduleCalculation.CreateRecordSet(),
			InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet());
		NodesToRead = New Array;
		AllNodes = PlacementData.Nodes.UnloadColumn("KeyLot");
		ThereAreHostedStages = False;
		
		NodeIndex = 0;
		While NodeIndex < PlacementData.Nodes.Count() Do
			
			Node = PlacementData.Nodes[NodeIndex];
			YouCanPost = New Map;
			NodeStageIsPlaced = False;
			
			IndexStage = 0;
			While IndexStage < Node.Stages.Count() Do
				
				Stage = Node.Stages[IndexStage]; // ValueTableRow
				
				Allocate = Stage.PlaceInCurCycle
					And (// Restriction on connections within a node
						YouCanPost[Stage[KeyOfCurStage]] = Undefined
						Or YouCanPost[Stage[KeyOfCurStage]]
					)
					And Stage.StartOfPlacement >= ClockCycleParameters.RecordSeparator;
				
				// Restriction on connections between nodes
				If Allocate Then
					For IndexLink = -Stage.Links.UBound() To 0 Do
						
						Link = Stage.Links[-IndexLink];
						If ValueIsFilled(Link.StartOfPlacement) Then
							
							Stage.StartOfPlacement = ?(ClockCycleParameters.GoBackToBeginning,
								Max(Stage.StartOfPlacement, Link.StartOfPlacement),
								Min(Stage.StartOfPlacement, Link.StartOfPlacement));
							
							// The date of the link is taken into account, the line can be deleted
							PlacementData.Links.Delete(Link);
							Stage.Links.Delete(-IndexLink);
							
						Else
							Allocate = False;
							Break;
						EndIf;
						
					EndDo;
				EndIf;
				
				// Stage Placement
				If Allocate Then
					
					// Calculation of the working time of the VRC
					If Stage.ThisIsBBV And Not Stage.TimeOfRCTypesIsCalculated Then
						For Each RCView In Stage.TypesOfRC Do
							If IsBlankString(RCView.QuantityCalculationAlgorithm) Then
								ZoomRatio = Node.QuantityOfBatches;
								If Stage.SimultaneouslyProducedNumberOfBatches <> 0 Then
									ZoomRatio = Int(ZoomRatio / Stage.SimultaneouslyProducedNumberOfBatches)
										+ ?(ZoomRatio % Stage.SimultaneouslyProducedNumberOfBatches <> 0, 1, 0);
								EndIf;
								RCView.Time = RCView.Time * ZoomRatio;
							EndIf;
						EndDo;
						Stage.TimeOfRCTypesIsCalculated = True;
					EndIf;
					
					If Stage.ThisIsBBV Then
						FirstStageOfBBV(ClockCycleParameters, ResultOfCycle, Node, Stage);
					Else
						FirstStageOfUBBV(ClockCycleParameters, ResultOfCycle, Stage);
					EndIf;
					
					If ResultOfCycle.Cancel Then
						Return ResultOfCycle;
					EndIf;
					
					If Stage.Posted_ Then
						
						StageFinish = ?(Stage.Ending = Stage.Begin, Stage.Ending, Stage.Ending-1);
						
						If Not Stage.ItIsTransfer Then
							NewRecord = RegulatorySchedule.Add();
							FillPropertyValues(NewRecord, ClockCycleParameters, ?(ClockCycleParameters.UseBuffer,
								"ProductionOrder, RecordSeparator, Area",
								"ProductionOrder, RecordSeparator"));
							FillPropertyValues(NewRecord, Stage, "KeyLot, Stage, Begin, StartOfPlacement");
							NewRecord.Ending = StageFinish;
						EndIf;
						
						// Updating dates inside a node
						For FollowerIndex = IndexStage+1 To Node.Stages.UBound() Do
							FollowerStage = Node.Stages[FollowerIndex];
							If FollowerStage[KeyOfCurStage] = Stage[KeyToNextStage] Then
								FollowerStage.StartOfPlacement = ?(ClockCycleParameters.GoBackToBeginning,
									Max(FollowerStage.StartOfPlacement, Stage.Ending),
									Min(FollowerStage.StartOfPlacement, Stage.Begin));
							EndIf;
						EndDo;
						
						// Updating dates between nodes
						LinkSearchStructure.KeyIsPredecessorParty = Stage.KeyLot;
						LinkSearchStructure.PredecessorStage = Stage.Stage;
						For Each Link In PlacementData.Links.FindRows(LinkSearchStructure) Do
							If ClockCycleParameters.ThisIsRepair Then
								Link.StartOfPlacement = Stage.StartOfPlacement;
							ElsIf Not ClockCycleParameters.GoBackToBeginning Then
								Link.StartOfPlacement = Stage.Begin;
							Else
								Link.StartOfPlacement = Stage.Ending;
							EndIf;
						EndDo;
						
						// Calculation of totals by node
						Node.Begin = ?(Node.Begin = '00010101', Stage.Begin, Min(Node.Begin, Stage.Begin));
						Node.Ending = Max(Node.Ending, StageFinish);
						
						ResultOfCycle.NumberOfStages = ResultOfCycle.NumberOfStages + 1;
						NodeStageIsPlaced = True;
						
					Else
						Stage.PlaceInCurCycle = False;
					EndIf;
					
				EndIf;
				
				// Marking the possibility of placing stages inside the node
				If YouCanPost[Stage[KeyToNextStage]] = Undefined
					Or YouCanPost[Stage[KeyToNextStage]] Then
					YouCanPost.Insert(Stage[KeyToNextStage], Stage.Posted_);
				EndIf;
				
				// Removing a stage from the Placement data
				If Stage.Posted_ Then
					For Each RCView In Stage.TypesOfRC Do
						PlacementData.TypesOfRC.Delete(RCView);
					EndDo;
					PlacementData.Stages.Delete(Stage);
					Node.Stages.Delete(IndexStage);
				Else
					IndexStage = IndexStage + 1;
				EndIf;
				
			EndDo;
			
			If NodeStageIsPlaced Then
				
				If Not Node.FollowersAreRead Then
					NodesToRead.Add(Node.KeyLot);
					Node.FollowersAreRead = True;
				EndIf;
				
				ThereAreHostedStages = True;
				
				If RegulatorySchedule.Count() >= ClockCycleParameters.RecordingGranule Then
					WriteSchedule(ClockCycleParameters, RegulatorySchedule, SubstitutionRecording);
				EndIf;
				
			EndIf;
			
			If Node.Stages.UBound() = -1 Then // The node is placed
				
				// Protection against recording empty totals
				If Node.Begin <> '00010101' Then
					// Adding a summary record by node
					NewRecord = RegulatorySchedule.Add();
					FillPropertyValues(NewRecord, ClockCycleParameters, ?(ClockCycleParameters.UseBuffer,
						"ProductionOrder, RecordSeparator, Area",
						"ProductionOrder, RecordSeparator"));
					FillPropertyValues(NewRecord, Node, "KeyLot, Begin, Ending");
					NewRecord.Stage = Catalogs.ProductionStages.EmptyRef();
					
					// Results by order
					ResultOfCycle.Begin = Min(ResultOfCycle.Begin, Node.Begin);
					ResultOfCycle.Ending = Max(ResultOfCycle.Ending, Node.Ending);
				EndIf;
				
				PlacementData.Nodes.Delete(NodeIndex);
				
			Else
				NodeIndex = NodeIndex + 1;
			EndIf;
			
		EndDo;
		
		// Processing the schedule for recording
		If ScheduleForRecording <> Undefined Then
			
			SearchStructureSeparator.RecordSeparator = ClockCycleParameters.RecordSeparator;
			For Each Record In ScheduleForRecording.FindRows(SearchStructureSeparator) Do
				
				NewRecord = RegulatorySchedule.Add();
				FillPropertyValues(NewRecord, Record);
				If ClockCycleParameters.UseBuffer Then
					NewRecord.Area = ClockCycleParameters.Area;
				EndIf;
				
				If RegulatorySchedule.Count() >= ClockCycleParameters.RecordingGranule Then
					WriteSchedule(ClockCycleParameters, RegulatorySchedule, SubstitutionRecording);
				EndIf;
				
				ThereAreHostedStages = True;
				
				// Updating dates between nodes
				LinkSearchStructure.KeyIsPredecessorParty = Record.KeyLot;
				LinkSearchStructure.PredecessorStage = Record.Stage;
				For Each Link In PlacementData.Links.FindRows(LinkSearchStructure) Do
					If ClockCycleParameters.ThisIsRepair Then
						Link.StartOfPlacement = Record.StartOfPlacement;
					ElsIf Not ClockCycleParameters.GoBackToBeginning Then
						Link.StartOfPlacement = Record.Begin;
					Else
						Link.StartOfPlacement = ?(Record.Ending = Record.Begin,
							Record.Ending, Record.Ending + 1);
					EndIf;
				EndDo;
				
				ScheduleForRecording.Delete(Record);
				
			EndDo;
			
			If ScheduleForRecording.Count() = 0 Then
				ScheduleForRecording = Undefined;
			EndIf;
			
		EndIf;
		
		If SubstitutionRecording
				Or RegulatorySchedule.Count() > 0 Then
			WriteSchedule(ClockCycleParameters, RegulatorySchedule, SubstitutionRecording);
		EndIf;
		
		If NodesToRead.UBound() <> -1 Then
			ReadSubsequentNodes(ClockCycleParameters, NodesToRead, AllNodes, PlacementData);
		EndIf;
		
		If Not ThereAreHostedStages Then
			Break;
		EndIf;
		
	EndDo;
	
	Return ResultOfCycle;
	
EndFunction

Procedure WriteSchedule(ClockCycleParameters, Set, SubstitutionRecording)
	
	If ClockCycleParameters.UseBuffer Then
		
		Set.Filter.Area.Set(ClockCycleParameters.Area);
		
		SetPrivilegedMode(True);
		Set.Write(False);
		SetPrivilegedMode(False);
		
		Set = InformationRegisters.BufferOfTargetProductionScheduleCalculation.CreateRecordSet();
		
	Else
		
		Set.Filter.ProductionOrder.Set(ClockCycleParameters.ProductionOrder);
		Set.Filter.RecordSeparator.Set(ClockCycleParameters.RecordSeparator);
		SetPrivilegedMode(True);
		Set.Write(SubstitutionRecording);
		SetPrivilegedMode(False);
		
		Set = InformationRegisters.TargetOrderStructureSchedule.CreateRecordSet();
		
	EndIf;
	
	SubstitutionRecording = False;
	
EndProcedure

#EndRegion

#Region CalculationOfBBV

// Place the BBB stage.
// 
// Parameters:
//  ClockCycleParameters - Structure - 
//  ResultOfCycle - Structure - 
//  Node - ValueTableRow - Knot.
//  Stage - ValueTableRow - stage.
Procedure FirstStageOfBBV(ClockCycleParameters, ResultOfCycle, Node, Stage)
	
	StartOfPlacementBeforeChange = Stage.StartOfPlacement;
	
	// Placing the first buffer
	Buffer = ?(ClockCycleParameters.GoBackToBeginning, "PreliminaryBuffer", "FollowUpBuffer");
	If Stage[Buffer] > 0 Then
		
		Result = PlaceAccordingToUBBVSchedule(
			ClockCycleParameters,
			Stage.Department,
			Stage.StartOfPlacement,
			Stage[Buffer],
			?(ClockCycleParameters.GoBackToBeginning,
				Stage.PreliminaryBufferShouldBePlacedInDays,
				Stage.FinalBufferShouldBePlacedInDays));
		
		If Result <> Undefined Then
			
			If ClockCycleParameters.GoBackToBeginning Then
				If Stage.Begin = '00010101' Then
					Stage.Begin = Result.Begin;
				EndIf;
				If Stage[Buffer] = 0 Then
					Stage.StartOfPlacement = Result.Ending;
				EndIf;
			Else
				If Stage.Ending = '00010101' Then
					Stage.Ending = Result.Ending;
				EndIf;
				If Stage[Buffer] = 0 Then
					Stage.StartOfPlacement = Result.Begin;
				EndIf; 
			EndIf;
			
		Else
			HandleErrorUBBIntervalWasNotFound(ClockCycleParameters, ResultOfCycle, Stage, Stage.StartOfPlacement);
		EndIf;
		
	EndIf;
	
	// Placement of types of RC
	If Stage[Buffer] = 0
		And Not Stage.TypesOfRCArePlanned Then
	
		If Stage.TypesOfRC.Count() = 1 Then
			
			// Placement of a single VRC
			Performer = Stage.TypesOfRC[0];
			Interval = InitialBBBPlacementInterval(ClockCycleParameters, Stage, Performer, Stage.StartOfPlacement);
			If Interval <> Undefined Then
				
				CalculateStartOfVRCDownload(ClockCycleParameters, Stage, Interval);
				Time = LoadingVRCOnInterval(Node, Performer);
				
				If Time = 0 And Performer.Time <> 0 Then
					HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Performer);
					Interval = Undefined;
				EndIf;
				
				While Interval <> Undefined Do
					
					Performer.Time = Performer.Time - Min(Time, Performer.Time);
					If Performer.Time = 0 Then
						
						CalculateEndOfVRCDownload(ClockCycleParameters, Stage, Performer, Interval);
						Stage.TypesOfRCArePlanned = True;
						Break;
						
					Else
						Interval = NextIntervalOfPlacementOfBBV(ClockCycleParameters, Stage, Performer, Interval);
					EndIf;
					
				EndDo;
				
			Else
				HandleErrorBBBIntervalNotFound(
					ClockCycleParameters, ResultOfCycle, Stage, Performer, Stage.StartOfPlacement);
			EndIf;
			
		ElsIf Stage.TypesOfRC.Count() > 1 Then
			
			// Placement of the VRC group
			If Stage.OrderOfOperationOfTypesOfRC = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially Then
				LoadVRCGroupSequentially(ClockCycleParameters, ResultOfCycle, Node, Stage);
			ElsIf Stage.OrderOfOperationOfTypesOfRC = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously Then
				LoadVRCGroupAtSameTime(ClockCycleParameters, ResultOfCycle, Node, Stage);
			ElsIf Stage.OrderOfOperationOfTypesOfRC = Enums.OperatingProcedureOfWorkCenterTypes.Independently Then
				LoadVRCGroupIndependently(ClockCycleParameters, ResultOfCycle, Node, Stage);
			EndIf;
		
		Else
			
			// Types of RC are not specified
			If ClockCycleParameters.GoBackToBeginning Then
				If Stage.Begin = '00010101' Then
					Stage.Begin = Stage.StartOfPlacement;
				EndIf;
			Else
				If Stage.Ending = '00010101' Then
					Stage.Ending = Stage.StartOfPlacement;
				EndIf;
			EndIf;
			
			Stage.EndOfLoadingTypesOfRC = Stage.StartOfPlacement;
			Stage.TypesOfRCArePlanned = True;
			
		EndIf;
		
	EndIf;
	
	// Placing the second buffer
	If Stage.TypesOfRCArePlanned Then
		
		Buffer = ?(ClockCycleParameters.GoBackToBeginning, "FollowUpBuffer", "PreliminaryBuffer");
		If Stage[Buffer] > 0 Then
			
			Result = PlaceAccordingToUBBVSchedule(
				ClockCycleParameters,
				Stage.Department,
				Stage.EndOfLoadingTypesOfRC,
				Stage[Buffer],
				?(ClockCycleParameters.GoBackToBeginning,
					Stage.FinalBufferShouldBePlacedInDays,
					Stage.PreliminaryBufferShouldBePlacedInDays));
			
			If Result <> Undefined Then
				
				If Stage[Buffer] = 0 Then
					If ClockCycleParameters.GoBackToBeginning Then
						Stage.Ending = Result.Ending;
					Else
						Stage.Begin = Result.Begin;
					EndIf;
					Stage.Posted_ = True;
				EndIf;
				
			Else
				HandleErrorUBBIntervalWasNotFound(ClockCycleParameters, ResultOfCycle, Stage, Stage.EndOfLoadingTypesOfRC);
			EndIf;
		
		Else
			
			If ClockCycleParameters.GoBackToBeginning Then
				Stage.Ending = Stage.EndOfLoadingTypesOfRC;
			Else
				Stage.Begin = Stage.EndOfLoadingTypesOfRC;
			EndIf;
			Stage.Posted_ = True;
			
		EndIf;
		
	EndIf;
	
	Stage.StartOfPlacement = StartOfPlacementBeforeChange;
	
EndProcedure

Procedure LoadVRCGroupSequentially(ClockCycleParameters, ResultOfCycle, Node, Stage)
	
	Interval = Undefined;
	
	For IndexOf = 0 To Stage.TypesOfRC.UBound() Do
		
		Performer = Stage.TypesOfRC[IndexOf];
		If Performer.Time = 0
			And Stage.EndOfLoadingTypesOfRC <> '00010101' Then
			Continue;
		EndIf;
		
		StartOfPlacement = ?(Interval = Undefined,
			Stage.StartOfPlacement,
			?(ClockCycleParameters.GoBackToBeginning,
				Interval.Date,
				LeadToEndOfPeriod(Interval.Date, Stage.Interval)));
		
		Interval = InitialBBBPlacementInterval(ClockCycleParameters, Stage, Performer, StartOfPlacement);
		If Interval <> Undefined Then
			
			If IndexOf = 0 Then
				CalculateStartOfVRCDownload(ClockCycleParameters, Stage, Interval);
			EndIf;
			Time = LoadingVRCOnInterval(Node, Performer);
			
			If Time = 0 And Performer.Time <> 0 Then
				HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Performer);
				Return;
			EndIf;
			
			While Interval <> Undefined Do
				
				Performer.Time = Performer.Time - Min(Time, Performer.Time);
				If Performer.Time = 0 Then
					CalculateEndOfVRCDownload(ClockCycleParameters, Stage, Performer, Interval);
					Break;
				Else
					Interval = NextIntervalOfPlacementOfBBV(ClockCycleParameters, Stage, Performer, Interval);
				EndIf;
				
			EndDo;
			
			If Performer.Time <> 0 Then
				Return;
			EndIf;
			
		Else
			HandleErrorBBBIntervalNotFound(ClockCycleParameters, ResultOfCycle, Stage, Performer, StartOfPlacement);
			Return;
		EndIf;
		
	EndDo;
	
	Stage.TypesOfRCArePlanned = True;
	
EndProcedure

Procedure LoadVRCGroupAtSameTime(ClockCycleParameters, ResultOfCycle, Node, Stage)
	
	TheStructureOfTheSearch = New Structure("ChartKey, Interval, Date");
	IntervalsDoNotIntersect = True;
	
	Performer1 = Stage.TypesOfRC[0];
	Interval1 = InitialBBBPlacementInterval(ClockCycleParameters, Stage, Performer1, Stage.StartOfPlacement);
	If Interval1 <> Undefined Then
		
		CalculateStartOfVRCDownload(ClockCycleParameters, Stage, Interval1);
		
		Time = LoadingVRCOnInterval(Node, Performer1);
		If Time = 0 And Performer1.Time <> 0 Then
			HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Performer1);
			Return;
		Else
			For IndexOf = 1 To Stage.TypesOfRC.UBound() Do
				
				Time = Min(Time, LoadingVRCOnInterval(Node, Stage.TypesOfRC[IndexOf]));
				If Time = 0 And Stage.TypesOfRC[IndexOf].Time <> 0 Then
					HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Stage.TypesOfRC[IndexOf]);
					Return;
				EndIf;
				
			EndDo;
		EndIf;
		
		While Interval1 <> Undefined Do
			
			AllPerformersAreAvailable = True;
			For IndexOf = 1 To Stage.TypesOfRC.UBound() Do
				
				Performer2 = Stage.TypesOfRC[IndexOf];
				If Performer2.ChartKey = Performer1.ChartKey Then
					Continue;
				EndIf;
				
				TheStructureOfTheSearch.ChartKey = Performer2.ChartKey;
				TheStructureOfTheSearch.Interval = Performer2.Interval;
				TheStructureOfTheSearch.Date = Interval1.Date;
	
				FoundRows = ClockCycleParameters.BBVSchedule.FindRows(TheStructureOfTheSearch);
				If FoundRows.UBound() = -1 Then
					AllPerformersAreAvailable = False;
					Break;
				EndIf;
				
			EndDo;
			
			If AllPerformersAreAvailable Then
				Performer1.Time = Performer1.Time - Min(Time, Performer1.Time);
				IntervalsDoNotIntersect = False;
			EndIf;
			
			If Performer1.Time = 0 Then
				
				CalculateEndOfVRCDownload(ClockCycleParameters, Stage, Performer1, Interval1);
				Stage.TypesOfRCArePlanned = True;
				Break;
				
			Else
				Interval1 = NextIntervalOfPlacementOfBBV(ClockCycleParameters, Stage, Performer1, Interval1);
			EndIf;
			
		EndDo;
		
	Else
		HandleErrorBBBIntervalNotFound(ClockCycleParameters, ResultOfCycle, Stage, Performer1, Stage.StartOfPlacement);
		IntervalsDoNotIntersect = False;
	EndIf;
	
	If IntervalsDoNotIntersect Then
		HandleErrorIntervalsDoNotIntersect(ClockCycleParameters, ResultOfCycle, Stage);
	EndIf;
	
EndProcedure

Procedure LoadVRCGroupIndependently(ClockCycleParameters, ResultOfCycle, Node, Stage)
	
	TypesOfRCArePlanned = True;
	
	For IndexOf = 0 To Stage.TypesOfRC.UBound() Do
		
		Performer = Stage.TypesOfRC[IndexOf];
		If Performer.Time = 0
			And Stage.EndOfLoadingTypesOfRC <> '00010101' Then
			Continue;
		EndIf;
		
		Interval = InitialBBBPlacementInterval(ClockCycleParameters, Stage, Performer, Stage.StartOfPlacement);
		If Interval <> Undefined Then
			
			CalculateStartOfVRCDownload(ClockCycleParameters, Stage, Interval);
			Time = LoadingVRCOnInterval(Node, Performer);
			
			If Time = 0 And Performer.Time <> 0 Then
				HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Performer);
				Return;
			EndIf;
			
			While Interval <> Undefined Do
				
				Performer.Time = Performer.Time - Min(Time, Performer.Time);
				If Performer.Time = 0 Then
					
					CalculateEndOfVRCDownload(ClockCycleParameters, Stage, Performer, Interval);
					Break;
					
				Else
					Interval = NextIntervalOfPlacementOfBBV(ClockCycleParameters, Stage, Performer, Interval);
				EndIf;
				
			EndDo;
			
		Else
			HandleErrorBBBIntervalNotFound(ClockCycleParameters, ResultOfCycle, Stage, Performer, Stage.StartOfPlacement);
		EndIf;
		
		If Performer.Time <> 0 Then
			TypesOfRCArePlanned = False;
		EndIf;
		
	EndDo;
	
	Stage.TypesOfRCArePlanned = TypesOfRCArePlanned;
	
EndProcedure

Function InitialBBBPlacementInterval(ClockCycleParameters, Stage, Performer, StartOfPlacement)
	
	// Calculation of the interval date
	Date = '00010101';
	If Stage.IntervalHasNonStandardBoundaries Then
		
		If ClockCycleParameters.GoBackToBeginning Then
			
			IntervalEndpoint = ResultInPlanningIntervalBoundary(
				StartOfPlacement, Stage.Interval, Stage.IntervalStart);
			If StartOfPlacement <= IntervalEndpoint Then
				Date = LeadToBeginningOfPeriod(StartOfPlacement, Stage.Interval);
			Else
				Date = LeadToEndOfPeriod(StartOfPlacement, Stage.Interval);
			EndIf;
			
		Else
			
			IntervalEndpoint = ResultInPlanningIntervalBoundary(
				StartOfPlacement, Stage.Interval, Stage.IntervalEnd_);
			If StartOfPlacement >= IntervalEndpoint Then
				Date = LeadToBeginningOfPeriod(StartOfPlacement, Stage.Interval);
			Else
				Date = LeadToBeginningOfPeriod(
					LeadToBeginningOfPeriod(StartOfPlacement, Stage.Interval)-1,
					Stage.Interval);
			EndIf;
			
		EndIf;
		
	Else
		
		If Stage.Interval = Enums.ProductionScheduleAccuracy.Shift Then
			Date = StartOfPlacement;
		Else
			BeginOfPeriod = LeadToBeginningOfPeriod(StartOfPlacement, Stage.Interval);
			If ClockCycleParameters.GoBackToBeginning Then
				If StartOfPlacement = BeginOfPeriod Then
					Date = StartOfPlacement;
				Else
					Date = LeadToEndOfPeriod(StartOfPlacement, Stage.Interval);
				EndIf;
			Else
				Date = LeadToBeginningOfPeriod(BeginOfPeriod-1, Stage.Interval);
			EndIf;
		EndIf;
		
	EndIf;
	
	Result = Undefined;
	
	// Selection of the interval by search
	If Performer.Interval = Enums.ProductionScheduleAccuracy.Day Then
		NumberOfSearchIterations = 3;
		ColumnName = "Date";
	Else
		NumberOfSearchIterations = 1;
		
		If Not ClockCycleParameters.GoBackToBeginning
			And Performer.Interval = Enums.ProductionScheduleAccuracy.Shift Then
			ColumnName = "EndOfShift";
		Else
			ColumnName = "Date";
		EndIf;
	EndIf;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("ChartKey", Performer.ChartKey);
	TheStructureOfTheSearch.Insert("Interval", Performer.Interval);
	TheStructureOfTheSearch.Insert(ColumnName);
	
	For Cnt = 1 To NumberOfSearchIterations Do
		
		TheStructureOfTheSearch[ColumnName] = Date;
		FoundRows = ClockCycleParameters.BBVSchedule.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			If ClockCycleParameters.GoBackToBeginning Then
				Date = LeadToEndOfPeriod(Date, Performer.Interval);
			Else
				Date = LeadToBeginningOfPeriod(Date-1, Performer.Interval);
			EndIf;
		Else
			Result = FoundRows[0];
			Break;
		EndIf;
		
	EndDo;
	
	// Selection of the interval by brute force
	If Result = Undefined Then
		
		TheStructureOfTheSearch.Delete(ColumnName);
		FoundRows = TMCommonUse.FindRowsWithPreservingOrder(
			ClockCycleParameters.BBVSchedule, TheStructureOfTheSearch, True);
		
		For Cnt = 0 To FoundRows.UBound() Do
			If ClockCycleParameters.GoBackToBeginning And FoundRows[Cnt][ColumnName] >= Date
				Or Not ClockCycleParameters.GoBackToBeginning And FoundRows[Cnt][ColumnName] <= Date Then
				
				Result = FoundRows[Cnt];
				Break;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function NextIntervalOfPlacementOfBBV(ClockCycleParameters, Stage, Performer, Interval)
	
	Result = Undefined;
	
	IndexOf = ClockCycleParameters.BBVSchedule.IndexOf(Interval) + 1;
	If IndexOf < ClockCycleParameters.BBVSchedule.Count() Then
		
		NextInterval_ = ClockCycleParameters.BBVSchedule[IndexOf];
		If NextInterval_.ChartKey = Performer.ChartKey
			And NextInterval_.Interval = Performer.Interval Then
			
			Result = NextInterval_;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function LoadingVRCOnInterval(Node, Performer)
	
	QuantityOfBatches = ?(Int(Node.QuantityOfBatches) = Node.QuantityOfBatches And Node.QuantityOfBatches <> 0,
		Node.QuantityOfBatches,
		Int(Node.QuantityOfBatches)+1);
	
	UnitsOfEquipment = ?(Performer.ConsiderAvailability,
		Min(QuantityOfBatches, Performer.NumberOfWorkCenters),
		QuantityOfBatches);
	
	UploadingToQuantum = Performer.MaximumAvailability * UnitsOfEquipment;
	
	Return Min(Performer.Time, UploadingToQuantum);
	
EndFunction

// Calculate the start of loading the VRC.
// 
// Parameters:
//  ClockCycleParameters - Structure - 
//  Stage - ValueTableRow - stage.
//  Interval - ValueTableRow - Interval.
Procedure CalculateStartOfVRCDownload(ClockCycleParameters, Stage, Interval)
	
	If ClockCycleParameters.GoBackToBeginning Then
		
		Date = ?(Stage.IntervalHasNonStandardBoundaries,
			ResultInPlanningIntervalBoundary(Interval.Date, Stage.Interval, Stage.IntervalStart),
			Interval.Date);
		
		If Stage.Begin = '00010101' Then
			Stage.Begin = Date;
		Else
			Stage.Begin = Min(Stage.Begin, Date);
		EndIf;
		
	Else
		
		If Stage.Interval = Enums.ProductionScheduleAccuracy.Shift Then
			Date = Interval.EndOfShift;
		Else
			Date = ?(Stage.IntervalHasNonStandardBoundaries,
				ResultInPlanningIntervalBoundary(Interval.Date, Stage.Interval, Stage.IntervalEnd_) + 1,
				LeadToEndOfPeriod(Interval.Date, Stage.Interval));
		EndIf;
		
		If Stage.Ending = '00010101' Then
			Stage.Ending = Date;
		Else
			Stage.Ending = Max(Stage.Ending, Date);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CalculateEndOfVRCDownload(ClockCycleParameters, Stage, Performer, Interval)
	
	If ClockCycleParameters.GoBackToBeginning Then
		
		If Stage.Interval = Enums.ProductionScheduleAccuracy.Shift Then
			Date = Interval.EndOfShift;
		Else
			Date = ?(Stage.IntervalHasNonStandardBoundaries,
				ResultInPlanningIntervalBoundary(Interval.Date, Stage.Interval, Stage.IntervalEnd_) + 1,
				LeadToEndOfPeriod(Interval.Date, Stage.Interval));
		EndIf;
		
		If Stage.EndOfLoadingTypesOfRC = '00010101' Then
			Stage.EndOfLoadingTypesOfRC = Date;
		Else
			Stage.EndOfLoadingTypesOfRC = Max(Stage.EndOfLoadingTypesOfRC, Date);
		EndIf;
		
	Else
		
		Date = ?(Stage.IntervalHasNonStandardBoundaries,
			ResultInPlanningIntervalBoundary(Interval.Date, Stage.Interval, Stage.IntervalStart),
			Interval.Date);
		
		If Stage.EndOfLoadingTypesOfRC = '00010101' Then
			Stage.EndOfLoadingTypesOfRC = Date;
		Else
			Stage.EndOfLoadingTypesOfRC = Min(Stage.EndOfLoadingTypesOfRC, Date);
		EndIf;
		
	EndIf;
	
EndProcedure

Function ResultInPlanningIntervalBoundary(Date, Interval, IntervalEndpoint)
	
	Return LeadToBeginningOfPeriod(Date, Interval)
		+ LimitOfIntervalInSeconds(IntervalEndpoint, Interval);
	
EndFunction

Function LimitOfIntervalInSeconds(IntervalEndpoint, Interval)
	
	If Interval = Enums.ProductionScheduleAccuracy.Day Then
		
		Return Hour(IntervalEndpoint) * 3600
			+ Minute(IntervalEndpoint) * 60
			+ Second(IntervalEndpoint);
			
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Week Then
		
		Return (WeekDay(IntervalEndpoint)-1) * 86400
			+ Hour(IntervalEndpoint) * 3600
			+ Minute(IntervalEndpoint) * 60
			+ Second(IntervalEndpoint);
		
	Else
		Return 0;
	EndIf;
	
EndFunction

#EndRegion

#Region CalculationOfUBBV

// Place the UBBV stage.
// 
// Parameters:
//  ClockCycleParameters - Structure - 
//  ResultOfCycle - Structure - 
//  Stage - ValueTableRow - Stage
Procedure FirstStageOfUBBV(ClockCycleParameters, ResultOfCycle, Stage)
	
	If Stage.StageDuration > 0 Then
		
		Result = PlaceAccordingToUBBVSchedule(
			ClockCycleParameters,
			Stage.Department,
			Stage.StartOfPlacement,
			Stage.StageDuration,
			Stage.StageToPlaceInDays);
		
		If Result <> Undefined Then
			
			If ClockCycleParameters.GoBackToBeginning Then
				If Stage.Begin = '00010101' Then
					Stage.Begin = Result.Begin;
				EndIf;
				If Stage.StageDuration = 0 Then
					Stage.Ending = Result.Ending;
					Stage.Posted_ = True;
				EndIf;
			Else
				If Stage.Ending = '00010101' Then
					Stage.Ending = Result.Ending;
				EndIf;
				If Stage.StageDuration = 0 Then
					Stage.Begin = Result.Begin;
					Stage.Posted_ = True;
				EndIf; 
			EndIf;
			
		Else
			HandleErrorUBBIntervalWasNotFound(ClockCycleParameters, ResultOfCycle, Stage, Stage.StartOfPlacement);
		EndIf;
		
	Else
		
		Stage.Posted_ = True;
		Stage.Begin = Stage.StartOfPlacement;
		Stage.Ending = Stage.StartOfPlacement;
		
	EndIf;
	
EndProcedure

Function PlaceAccordingToUBBVSchedule(ClockCycleParameters, Department, StartOfPlacement, Time, PostInDays)
	
	Interval = ?(PostInDays,
		InitialIntervalOfPlacementOfUBBVOnCalendar(ClockCycleParameters, Department, StartOfPlacement),
		InitialIntervalOfPlacementOfUBBVAccordingToSchedule(ClockCycleParameters, Department, StartOfPlacement));
	
	If Interval = Undefined Then
		Return Undefined;
	EndIf;
	
	Begin = StartOfUBBVPlacement(
		ClockCycleParameters.GoBackToBeginning, StartOfPlacement, Interval, PostInDays);
	Ending = Begin;
	
	While Interval <> Undefined Do
		
		ShiftUbbvPlacementBoundary(
			ClockCycleParameters.GoBackToBeginning, Interval, Ending, Time, PostInDays);
		
		If Time > 0 Then
			Interval = NextUBBVPlacementInterval(
				ClockCycleParameters.UbbwSchedule, Interval, PostInDays);
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Result = New Structure("Begin, Ending", '00010101', '00010101');
	If Begin <> Ending Then
		
		// Normalization of dates
		If Not ClockCycleParameters.GoBackToBeginning Then
			StartDateOfPlacement = Begin;
			Begin = Ending;
			Ending = StartDateOfPlacement;
		EndIf;
		
		// Bringing dates to schedule boundaries
		If PostInDays
			And ClockCycleParameters.UBBVIndex[Department].ThereAreBoundaries Then
			
			Boundaries = BoundariesOfDayAccordingToSchedule(ClockCycleParameters.UbbwSchedule, Department, BegOfDay(Begin));
			If ValueIsFilled(Boundaries.Begin) Then
				Begin = BegOfDay(Begin) + TimeInSeconds_(Boundaries.Begin);
			EndIf;
			
			ScheduleDateEnd = BegOfDay(Ending-1);
			If BegOfDay(Begin) <> ScheduleDateEnd Then
				Boundaries = BoundariesOfDayAccordingToSchedule(ClockCycleParameters.UbbwSchedule, Department, ScheduleDateEnd);
			EndIf;
			If ValueIsFilled(Boundaries.Ending)
				And Boundaries.Ending <> '00010101235959' Then
				Ending = ScheduleDateEnd + TimeInSeconds_(Boundaries.Ending);
			EndIf;
	
		EndIf;
		
		Result.Begin = Begin;
		Result.Ending = Ending;
		
	EndIf;
	
	Return Result
	
EndFunction

Function InitialIntervalOfPlacementOfUBBVOnCalendar(ClockCycleParameters, Department, StartOfPlacement)
	
	If ClockCycleParameters.GoBackToBeginning Then
		
		Date = ?(StartOfPlacement = BegOfDay(StartOfPlacement),
			StartOfPlacement,
			EndOfDay(StartOfPlacement) + 1);
		TheStructureOfTheSearch = New Structure("Department, Date", Department, Date);
		
		FoundRows = ClockCycleParameters.UbbwSchedule.FindRows(TheStructureOfTheSearch);
		If FoundRows.UBound() <> -1 Then
			Return FoundRows[0];
		ElsIf ClockCycleParameters.UBBVIndex[Department] <> Undefined Then
			For IndexOf = ClockCycleParameters.UBBVIndex[Department].Begin
					To ClockCycleParameters.UBBVIndex[Department].Ending Do
				If ClockCycleParameters.UbbwSchedule[IndexOf].Date >= Date Then
					Return ClockCycleParameters.UbbwSchedule[IndexOf];
				EndIf;
			EndDo;
		EndIf;
	
	Else
		
		Date = BegOfDay(StartOfPlacement - 86400);
		TheStructureOfTheSearch = New Structure("Department, Date", Department, Date);
		
		FoundRows = ClockCycleParameters.UbbwSchedule.FindRows(TheStructureOfTheSearch);
		If FoundRows.UBound() <> -1 Then
			Return FoundRows[0];
		ElsIf ClockCycleParameters.UBBVIndex[Department] <> Undefined Then
			For IndexOf = ClockCycleParameters.UBBVIndex[Department].Begin
					To ClockCycleParameters.UBBVIndex[Department].Ending Do
				If ClockCycleParameters.UbbwSchedule[IndexOf].Date <= Date Then
					Return ClockCycleParameters.UbbwSchedule[IndexOf];
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function InitialIntervalOfPlacementOfUBBVAccordingToSchedule(ClockCycleParameters, Department, StartOfPlacement)
	
	If ClockCycleParameters.UBBVIndex[Department] = Undefined Then
		Return Undefined;
	EndIf;
	
	If ClockCycleParameters.GoBackToBeginning Then
		
		For IndexOf = ClockCycleParameters.UBBVIndex[Department].Begin
				To ClockCycleParameters.UBBVIndex[Department].Ending Do
			If StartOfPlacement < ClockCycleParameters.UbbwSchedule[IndexOf].Ending Then
				Return ClockCycleParameters.UbbwSchedule[IndexOf];
			EndIf;
		EndDo;
		
	Else
		
		For IndexOf = ClockCycleParameters.UBBVIndex[Department].Begin
				To ClockCycleParameters.UBBVIndex[Department].Ending Do
			If StartOfPlacement > ClockCycleParameters.UbbwSchedule[IndexOf].Begin Then
				Return ClockCycleParameters.UbbwSchedule[IndexOf];
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function StartOfUBBVPlacement(GoBackToBeginning, StartOfPlacement, Interval, PostInDays)
	
	If PostInDays Then
		
		If GoBackToBeginning Then
			Result = Interval.Date;
		Else
			Result = EndOfDay(Interval.Date) + 1;
		EndIf;
		
	Else
		
		If StartOfPlacement >= Interval.Begin
			And StartOfPlacement <= Interval.Ending Then
			Result = StartOfPlacement;
		Else
			If GoBackToBeginning Then
				Result = Interval.Begin;
			Else
				Result = Interval.Ending;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ShiftUbbvPlacementBoundary(GoBackToBeginning, Interval, PlacementBoundary, ItRemainsToPlace, PostInDays)
	
	If PostInDays Then
		
		If GoBackToBeginning Then
			PlacementBoundary = EndOfDay(Interval.Date) + 1;
		Else
			PlacementBoundary = Interval.Date;
		EndIf;
		
		ItRemainsToPlace = ItRemainsToPlace - 1;
		
	Else
		
		If PlacementBoundary >= Interval.Begin
			And PlacementBoundary <= Interval.Ending Then
			
			If GoBackToBeginning Then
				
				AvailableTime = Interval.Ending - PlacementBoundary;
				OffsetTime = Min(ItRemainsToPlace, AvailableTime);
				PlacementBoundary = PlacementBoundary + OffsetTime;
				
			Else
				
				AvailableTime = PlacementBoundary - Interval.Begin;
				OffsetTime = Min(ItRemainsToPlace, AvailableTime);
				PlacementBoundary = PlacementBoundary - OffsetTime;
				
			EndIf;
			
			ItRemainsToPlace = ItRemainsToPlace - OffsetTime;
			
		Else
			
			OffsetTime = Min(ItRemainsToPlace, Interval.Duration);
			
			If GoBackToBeginning Then
				PlacementBoundary = Interval.Begin + OffsetTime;
			Else
				PlacementBoundary = Interval.Ending - OffsetTime;
			EndIf;
			
			ItRemainsToPlace = ItRemainsToPlace - OffsetTime;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The next interval of placement of UBBV.
// 
// Parameters:
//  UbbwSchedule - ValueTable - UBBV schedule
//  Interval - ValueTableRow - Interval
//  PostInDays - Boolean - Place in days
// 
// Returns:
//  Undefined - Next UBBV placement interval
Function NextUBBVPlacementInterval(UbbwSchedule, Interval, PostInDays)
	
	Result = Undefined;
	For IndexOf = UbbwSchedule.IndexOf(Interval)+1 To UbbwSchedule.Count()-1 Do
		
		NextInterval_ = UbbwSchedule[IndexOf];
		If NextInterval_.Department = Interval.Department Then
			
			If PostInDays Then
				If NextInterval_.Date <> Interval.Date  Then
					Result = NextInterval_;
					Break;
				EndIf;
			Else
				Result = NextInterval_;
				Break;
			EndIf;
			
		Else
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function BoundariesOfDayAccordingToSchedule(UbbwSchedule, Department, Date)
	
	Result = New Structure("Begin, Ending", '00010101', '00010101');
	
	TheStructureOfTheSearch = New Structure("Department, Date", Department, Date);
	FoundRows = UbbwSchedule.FindRows(TheStructureOfTheSearch);
		
	For IndexOf = 0 To FoundRows.UBound() Do
		
		If IndexOf = 0 Then
			Result.Begin = FoundRows[IndexOf].BeginTime;
			Result.Ending = FoundRows[IndexOf].EndTime;
		Else
			Result.Begin = Min(Result.Begin, FoundRows[IndexOf].BeginTime);
			Result.Ending = Max(Result.Ending, FoundRows[IndexOf].EndTime);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ReadingStages

Function FirstNodes(SourceData, OrderStructureCache)
	
	QueryTexts = New Array;
	
	QueryTexts.Add(
		"SELECT DISTINCT
		|	OrderStructure.KeyLot AS KeyLot
		|INTO TTPartiesWithoutIssue
		|FROM
		|	TTCacheOrderStructure AS OrderStructure
		|
		|	LEFT JOIN TTCacheNumberOfBatches AS LotReferenceIssue
		|	ON OrderStructure.KeyLot = LotReferenceIssue.KeyLot
		|WHERE
		|	NOT OrderStructure.ThisIsRelease
		|	AND LotReferenceIssue.KeyLot IS NULL
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	OrderStructure1.KeyLot AS KeyLot,
		|	CASE
		|		WHEN OrderStructure1.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN OrderStructure1.ProductionLot
		|		WHEN OrderStructure1.ItIsTransfer
		|			THEN UNDEFINED
		|		ELSE OrderStructure1.BillOfMaterials
		|	END                       AS Ref,
		|	CASE
		|		WHEN OrderStructure1.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN &NodeTypeBatchOfStages
		|		WHEN OrderStructure1.ItIsTransfer
		|			THEN &NodeViewMoving
		|		ELSE &TypeOfNodeBatchStructure
		|	END                       AS NodeView,
		|	ISNULL(MIN(OrderProducts_.DemandDate), &StartOfPlacement) AS StartOfPlacement
		|	 
		|INTO TTNodes
		|FROM
		|	TTCacheOrderStructure AS OrderStructure1
		|	
		|	LEFT JOIN TTCacheOrderStructure AS OrderStructure2
		|	ON OrderStructure1.KeyProducts = OrderStructure2.KeyProducts
		|		AND OrderStructure1.KeyLot <> OrderStructure2.KeyLot
		|		AND OrderStructure1.ThisIsRelease = &ThisIsRelease
		|		AND OrderStructure2.ThisIsRelease <> &ThisIsRelease
		|	
		|	LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
		|	ON OrderProducts_.Ref = &ProductionOrder
		|		AND OrderProducts_.KeyProducts = OrderStructure1.KeyProducts
		|		AND OrderProducts_.DemandDate <> DATETIME(1,1,1) 
		|		AND OrderStructure1.ThisIsRelease = &ThisIsRelease
		|	
		|	LEFT JOIN TTPartiesWithoutIssue AS BatchSenderWithoutIssue
		|	ON OrderStructure1.KeyLot = BatchSenderWithoutIssue.KeyLot
		|	
		|	LEFT JOIN TTPartiesWithoutIssue AS BatchRecipientWithoutIssue
		|	ON OrderStructure2.KeyLot = BatchRecipientWithoutIssue.KeyLot
		|	
		|GROUP BY
		|	OrderStructure1.KeyLot,
		|	CASE
		|		WHEN OrderStructure1.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN OrderStructure1.ProductionLot
		|		WHEN OrderStructure1.ItIsTransfer
		|			THEN UNDEFINED
		|		ELSE OrderStructure1.BillOfMaterials
		|	END,
		|	CASE
		|		WHEN OrderStructure1.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN &NodeTypeBatchOfStages
		|		WHEN OrderStructure1.ItIsTransfer
		|			THEN &NodeViewMoving
		|		ELSE &TypeOfNodeBatchStructure
		|	END
		|
		|HAVING
		|	(
		|		MIN(OrderStructure2.KeyLot IS NULL) = TRUE
		|		OR COUNT(DISTINCT OrderStructure2.KeyLot) = COUNT(DISTINCT BatchRecipientWithoutIssue.KeyLot)
		|	)
		|	AND MIN(BatchSenderWithoutIssue.KeyLot IS NULL) = TRUE
		|
		|INDEX BY
		|	NodeView");
		
	QueryTexts.Add(RequestTextNodesStagesTypesOfRC(SourceData.GoBackToBeginning));
	QueryTexts.Add("DROP TTNodes");
	
	QueryText = StrConcat(QueryTexts, ";");
	
	Query = New Query(QueryText);
	Query.TempTablesManager = OrderStructureCache;
	
	Query.SetParameter("ProductionOrder", SourceData.ProductionOrder);
	Query.SetParameter("StartOfPlacement", SourceData.StartOfPlacement);
	Query.SetParameter("ThisIsRelease", Not SourceData.GoBackToBeginning);
	Query.SetParameter("NodeTypeBatchOfStages", NodeTypeBatchOfStages());
	Query.SetParameter("NodeViewMoving", NodeViewMoving());
	Query.SetParameter("TypeOfNodeBatchStructure", TypeOfNodeBatchStructure());
	
	QueryResults = Query.ExecuteBatch();
	
	SamplingNodes = QueryResults[QueryResults.UBound()-3].Select();
	SamplingStages = QueryResults[QueryResults.UBound()-2].Select();
	SamplingTypesOfRC = QueryResults[QueryResults.UBound()-1].Select();
	
	If Not SamplingStages.Next() Then
		SamplingStages = Undefined;
	EndIf;
	If Not SamplingTypesOfRC.Next() Then
		SamplingTypesOfRC = Undefined;
	EndIf;
	
	PlacementData = NewPlacementData();
	
	While SamplingNodes.Next() Do
		
		NewLineNodes = PlacementData.Nodes.Add();
		FillPropertyValues(NewLineNodes, SamplingNodes);
		NewLineNodes.Stages = New Array;
		
		While SamplingStages <> Undefined
			And SamplingStages.KeyLot = SamplingNodes.KeyLot Do
			
			NewLineStages = PlacementData.Stages.Add();
			FillPropertyValues(NewLineStages, SamplingStages);
			NewLineNodes.Stages.Add(NewLineStages);
			
			If SamplingStages.ThisIsBBV Then
				
				NewLineStages.TypesOfRC = New Array;
				
				While SamplingTypesOfRC <> Undefined
					And SamplingTypesOfRC.KeyLot = SamplingStages.KeyLot
					And SamplingTypesOfRC.Stage = SamplingStages.Stage Do
					
					NewRowTypesOfRC = PlacementData.TypesOfRC.Add();
					FillPropertyValues(NewRowTypesOfRC, SamplingTypesOfRC);
					NewLineStages.TypesOfRC.Add(NewRowTypesOfRC);
					
					If Not SamplingTypesOfRC.Next() Then
						SamplingTypesOfRC = Undefined;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			If Not SamplingStages.Next() Then
				SamplingStages = Undefined;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return PlacementData;
	
EndFunction

Function NodesToRecalculate(SourceData, OrderStructureCache, Boundary, ScheduleForRecording)
	
	QueryTexts = New Array;
	
	// Schedule to record (batches placed to the left and right of the recalculation boundary)
	If SourceData.GoBackToBeginning Then
		QueryTexts.Add(
			"SELECT
			|	Schedule.ProductionOrder AS ProductionOrder,
			|	Schedule.RecordSeparator   AS RecordSeparator,
			|	Schedule.KeyLot          AS KeyLot,
			|	Schedule.Begin              AS Begin,
			|	Schedule.Ending           AS Ending,
			|	Schedule.Stage                AS Stage,
			|	Schedule.StartOfPlacement    AS StartOfPlacement
			|INTO TTScheduleToRecord
			|FROM
			|	InformationRegister.TargetOrderStructureSchedule AS Schedule
			|WHERE
			|	Schedule.ProductionOrder = &ProductionOrder
			|	AND Schedule.KeyLot <> &EmptyLinkKey
			|	AND Schedule.RecordSeparator >= &RecordSeparator
			|	AND TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					InformationRegister.TargetOrderStructureSchedule AS PredecessorGraph
			|				WHERE
			|					PredecessorGraph.ProductionOrder = &ProductionOrder
			|					AND PredecessorGraph.KeyLot = Schedule.KeyLot
			|					AND PredecessorGraph.Begin < &RecordSeparator)
			|INDEX BY
			|	KeyLot");
	Else
		QueryTexts.Add(
			"SELECT
			|	Schedule.ProductionOrder AS ProductionOrder,
			|	Schedule.RecordSeparator   AS RecordSeparator,
			|	Schedule.KeyLot          AS KeyLot,
			|	Schedule.Begin              AS Begin,
			|	Schedule.Ending           AS Ending,
			|	Schedule.Stage                AS Stage,
			|	Schedule.StartOfPlacement    AS StartOfPlacement
			|INTO TTScheduleToRecord
			|FROM
			|	InformationRegister.TargetOrderStructureSchedule AS Schedule
			|WHERE
			|	Schedule.ProductionOrder = &ProductionOrder
			|	AND Schedule.KeyLot <> &EmptyLinkKey
			|	AND Schedule.RecordSeparator <= &RecordSeparator
			|	AND TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					InformationRegister.TargetOrderStructureSchedule AS PredecessorGraph
			|				WHERE
			|					PredecessorGraph.ProductionOrder = &ProductionOrder
			|					AND PredecessorGraph.KeyLot = Schedule.KeyLot
			|					AND CASE
			|						WHEN PredecessorGraph.Ending = PredecessorGraph.Begin
			|							THEN PredecessorGraph.Ending
			|						ELSE DATEADD(PredecessorGraph.Ending, SECOND, 1)
			|					END > &NextRecordSeparator)
			|						
			|INDEX BY
			|	KeyLot");
	EndIf;
	
	// TTNodes
	If SourceData.GoBackToBeginning Then
		
		QueryTexts.Add(
			"// Nodes To Recalculate
			|SELECT
			|	OrderStructure.KeyLot AS KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END                      AS Ref,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END                      AS NodeView,
			|	&StartOfPlacement          AS StartOfPlacement
			|INTO TTNodes
			|FROM
			|	TTCacheOrderStructure AS OrderStructure
			|
			|	INNER JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
			|	ON Schedule.ProductionOrder = &ProductionOrder
			|		AND OrderStructure.KeyLot = Schedule.KeyLot
			|
			|	LEFT JOIN TTCacheOrderStructure AS Predecessors
			|	ON NOT OrderStructure.ThisIsRelease
			|		AND Predecessors.ThisIsRelease
			|		AND OrderStructure.KeyProducts = Predecessors.KeyProducts
			|	
			|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS PredecessorSSchedule
			|	ON PredecessorSSchedule.ProductionOrder = &ProductionOrder
			|		AND Predecessors.KeyLot = PredecessorSSchedule.KeyLot
			|		AND CASE
			|				WHEN PredecessorSSchedule.Ending = PredecessorSSchedule.Begin
			|					THEN PredecessorSSchedule.Ending
			|				ELSE DATEADD(PredecessorSSchedule.Ending, SECOND, 1)
			|			END > &Boundary
			|
			|GROUP BY
			|	OrderStructure.KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END
			|
			|HAVING
			|	MIN(Schedule.Begin) >= &Boundary
			|	AND MIN(PredecessorSSchedule.Stage IS NULL) = TRUE
			|
			|UNION ALL
			|
			|// Chart followers to record
			|SELECT
			|	OrderStructure.KeyLot AS KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END                      AS Ref,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END                      AS NodeView,
			|	&StartOfPlacement          AS StartOfPlacement
			|FROM
			|	TTCacheOrderStructure AS OrderStructure
			|
			|	INNER JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
			|	ON Schedule.ProductionOrder = &ProductionOrder
			|		AND OrderStructure.KeyLot = Schedule.KeyLot
			|
			|WHERE
			|	OrderStructure.KeyProducts IN (
			|		SELECT
			|			Precursors.KeyProducts
			|		FROM
			|			TTKeyConnectionCache AS Precursors
			|		WHERE
			|			Precursors.KeyLot IN (
			|				SELECT
			|					ScheduleForRecording.KeyLot
			|				FROM
			|					TTScheduleToRecord AS ScheduleForRecording)
			|			AND Precursors.ThisIsRelease <> &FollowerIsRelease)
			|	AND OrderStructure.ThisIsRelease = &FollowerIsRelease
			|
			|GROUP BY
			|	OrderStructure.KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END
			|
			|HAVING
			|	MIN(Schedule.Begin) >= &Boundary
			|
			|INDEX BY
			|	NodeView");
		
	Else
		
		QueryTexts.Add(
			"SELECT
			|	OrderStructure.KeyLot AS KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END                      AS Ref,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END                      AS NodeView,
			|	ISNULL(MIN(OrderProducts_.DemandDate), &StartOfPlacement) AS StartOfPlacement
			|INTO TTNodes
			|FROM
			|	TTCacheOrderStructure AS OrderStructure
			|
			|	INNER JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
			|	ON Schedule.ProductionOrder = &ProductionOrder
			|		AND OrderStructure.KeyLot = Schedule.KeyLot
			|
			|	LEFT JOIN TTCacheOrderStructure AS Successors
			|	ON OrderStructure.ThisIsRelease
			|		AND NOT Successors.ThisIsRelease
			|		AND OrderStructure.KeyProducts = Successors.KeyProducts
			|	
			|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS FollowerGraph
			|	ON FollowerGraph.ProductionOrder = &ProductionOrder
			|		AND Successors.KeyLot = FollowerGraph.KeyLot
			|		AND FollowerGraph.Begin < &Boundary
			|
			|	LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
			|	ON OrderProducts_.Ref = &ProductionOrder
			|		AND OrderProducts_.KeyProducts = OrderStructure.KeyProducts
			|		AND OrderProducts_.DemandDate <> DATETIME(1,1,1) 
			|
			|GROUP BY
			|	OrderStructure.KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END
			|
			|HAVING
			|	MAX(
			|		CASE
			|			WHEN Schedule.Ending = Schedule.Begin
			|				THEN Schedule.Ending
			|			ELSE DATEADD(Schedule.Ending, SECOND, 1)
			|		END) <= &Boundary
			|	AND MIN(FollowerGraph.Stage IS NULL) = TRUE
			|
			|UNION ALL
			|
			|// Chart followers to record
			|SELECT
			|	OrderStructure.KeyLot AS KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END                      AS Ref,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END                      AS NodeView,
			|	ISNULL(MIN(OrderProducts_.DemandDate), &StartOfPlacement) AS StartOfPlacement
			|FROM
			|	TTCacheOrderStructure AS OrderStructure
			|
			|	INNER JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
			|	ON Schedule.ProductionOrder = &ProductionOrder
			|		AND OrderStructure.KeyLot = Schedule.KeyLot
			|
			|	LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
			|	ON OrderProducts_.Ref = &ProductionOrder
			|		AND OrderProducts_.KeyProducts = OrderStructure.KeyProducts
			|		AND OrderProducts_.DemandDate <> DATETIME(1,1,1) 
			| 
			|WHERE
			|	OrderStructure.KeyProducts IN (
			|		SELECT
			|			Precursors.KeyProducts
			|		FROM
			|			TTKeyConnectionCache AS Precursors
			|		WHERE
			|			Precursors.KeyLot IN (
			|				SELECT
			|					ScheduleForRecording.KeyLot
			|				FROM
			|					TTScheduleToRecord AS ScheduleForRecording)
			|			AND Precursors.ThisIsRelease <> &FollowerIsRelease)
			|	AND OrderStructure.ThisIsRelease = &FollowerIsRelease
			|
			|GROUP BY
			|	OrderStructure.KeyLot,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN OrderStructure.ProductionLot
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN UNDEFINED
			|		ELSE OrderStructure.BillOfMaterials
			|	END,
			|	CASE
			|		WHEN OrderStructure.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
			|			THEN &NodeTypeBatchOfStages
			|		WHEN OrderStructure.ItIsTransfer
			|			THEN &NodeViewMoving
			|		ELSE &TypeOfNodeBatchStructure
			|	END
			|
			|HAVING
			|	MAX(
			|		CASE
			|			WHEN Schedule.Ending = Schedule.Begin
			|				THEN Schedule.Ending
			|			ELSE DATEADD(Schedule.Ending, SECOND, 1)
			|		END) <= &Boundary
			|
			|INDEX BY
			|	NodeView");
		
	EndIf;
	
	QueryTexts.Add(RequestTextNodesStagesTypesOfRC(SourceData.GoBackToBeginning));
	QueryTexts.Add(QueryTextNodeConnections(SourceData.GoBackToBeginning, False, SourceData.ThisIsRepair));
	
	QueryTexts.Add(
		"SELECT
		|	Schedule.ProductionOrder AS ProductionOrder,
		|	Schedule.RecordSeparator   AS RecordSeparator,
		|	Schedule.KeyLot          AS KeyLot,
		|	Schedule.Begin              AS Begin,
		|	Schedule.Ending           AS Ending,
		|	Schedule.Stage                AS Stage,
		|	Schedule.StartOfPlacement    AS StartOfPlacement
		|FROM
		|	TTScheduleToRecord AS Schedule");
	
	QueryTexts.Add("DROP TTScheduleToRecord");
	QueryTexts.Add("DROP TTNodes");
	
	Query = New Query(StrConcat(QueryTexts, ";"));
	Query.TempTablesManager = OrderStructureCache;
	
	Query.SetParameter("ProductionOrder", SourceData.ProductionOrder);
	Query.SetParameter("StartOfPlacement", SourceData.StartOfPlacement);
	Query.SetParameter("RecordSeparator", BegOfMonth(Boundary));
	Query.SetParameter("NextRecordSeparator", EndOfMonth(Boundary)+1);
	Query.SetParameter("NodeTypeBatchOfStages", NodeTypeBatchOfStages());
	Query.SetParameter("NodeViewMoving", NodeViewMoving());
	Query.SetParameter("TypeOfNodeBatchStructure", TypeOfNodeBatchStructure());
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("UseBuffer", False);
	Query.SetParameter("Area", New UUID("00000000-0000-0000-0000-000000000000"));
	
	If SourceData.GoBackToBeginning Then
		Query.SetParameter("Boundary", BegOfMonth(Boundary));
		Query.SetParameter("StartOfSchedule", BegOfMonth(SourceData.StartOfPlacement));
		Query.SetParameter("EndOfSchedule", BegOfMonth(BegOfMonth(Boundary)-1));
		Query.SetParameter("FollowerIsRelease", False);
	Else
		Query.SetParameter("Boundary", EndOfMonth(Boundary)+1);
		Query.SetParameter("StartOfSchedule", EndOfMonth(Boundary)+1);
		Query.SetParameter("EndOfSchedule", BegOfMonth(SourceData.StartOfPlacement));
		Query.SetParameter("FollowerIsRelease", True);
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SamplingNodes = QueryResults[QueryResults.UBound()-6].Select();
	SamplingStages = QueryResults[QueryResults.UBound()-5].Select();
	SamplingTypesOfRC = QueryResults[QueryResults.UBound()-4].Select();
	LinkSelection = QueryResults[QueryResults.UBound()-3].Select();
	ScheduleForRecording = QueryResults[QueryResults.UBound()-2].Unload();
	
	If Not SamplingStages.Next() Then
		SamplingStages = Undefined;
	EndIf;
	If Not SamplingTypesOfRC.Next() Then
		SamplingTypesOfRC = Undefined;
	EndIf;
	If Not LinkSelection.Next() Then
		LinkSelection = Undefined;
	EndIf;
	
	PlacementData = NewPlacementData();
	
	While SamplingNodes.Next() Do
		
		NewLineNodes = PlacementData.Nodes.Add();
		FillPropertyValues(NewLineNodes, SamplingNodes);
		NewLineNodes.Stages = New Array;
		
		While SamplingStages <> Undefined
			And SamplingStages.KeyLot = SamplingNodes.KeyLot Do
			
			// Stages
			NewLineStages = PlacementData.Stages.Add();
			FillPropertyValues(NewLineStages, SamplingStages);
			NewLineNodes.Stages.Add(NewLineStages);
			
			// Types of RC
			If SamplingStages.ThisIsBBV Then
				While SamplingTypesOfRC <> Undefined
					And SamplingTypesOfRC.KeyLot = SamplingStages.KeyLot
					And SamplingTypesOfRC.Stage = SamplingStages.Stage Do
					
					NewRowTypesOfRC = PlacementData.TypesOfRC.Add();
					FillPropertyValues(NewRowTypesOfRC, SamplingTypesOfRC);
					NewLineStages.TypesOfRC.Add(NewRowTypesOfRC);
					
					If Not SamplingTypesOfRC.Next() Then
						SamplingTypesOfRC = Undefined;
					EndIf;
					
				EndDo;
			EndIf;
			
			// Links
			While LinkSelection <> Undefined
				And LinkSelection.KeyLot = SamplingStages.KeyLot
				And LinkSelection.Stage = SamplingStages.Stage Do
				
				NewLinkString = PlacementData.Links.Add();
				FillPropertyValues(NewLinkString, LinkSelection);
				NewLineStages.Links.Add(NewLinkString);
				
				If Not LinkSelection.Next() Then
					LinkSelection = Undefined;
				EndIf;
				
			EndDo;
			
			If Not SamplingStages.Next() Then
				SamplingStages = Undefined;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If ScheduleForRecording.Count() = 0 Then
		ScheduleForRecording = Undefined;
	Else
		ScheduleForRecording.Indexes.Add("RecordSeparator");
	EndIf;
	
	Return PlacementData;
	
EndFunction

Procedure ReadSubsequentNodes(ClockCycleParameters, Nodes, ExcludeNodes, PlacementData)
	
	QueryTexts = New Array;
	QueryTexts.Add(
		"SELECT DISTINCT
		|	Successors.KeyLot AS KeyLot,
		|	CASE
		|		WHEN Successors.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN Successors.ProductionLot
		|		WHEN Successors.ItIsTransfer
		|			THEN UNDEFINED
		|		ELSE Successors.BillOfMaterials
		|	END                    AS Ref,
		|	CASE
		|		WHEN Successors.ProductionLot <> VALUE(Catalog.ProductionLots.EmptyRef)
		|			THEN &NodeTypeBatchOfStages
		|		WHEN Successors.ItIsTransfer
		|			THEN &NodeViewMoving
		|		ELSE &TypeOfNodeBatchStructure
		|	END                      AS NodeView,
		|	&StartOfPlacement          AS StartOfPlacement
		|INTO TTNodes
		|FROM
		|	TTCacheOrderStructure AS Successors
		|WHERE
		|	Successors.KeyProducts IN (
		|		SELECT
		|			Precursors.KeyProducts
		|		FROM
		|			TTKeyConnectionCache AS Precursors
		|		WHERE
		|			Precursors.KeyLot IN (&Nodes)
		|			AND Precursors.ThisIsRelease <> &FollowerIsRelease)
		|	AND Successors.ThisIsRelease = &FollowerIsRelease
		|	AND Successors.KeyLot NOT IN (&ExcludeNodes)
		|
		|INDEX BY
		|	NodeView");
	
	QueryTexts.Add(RequestTextNodesStagesTypesOfRC(ClockCycleParameters.GoBackToBeginning));
	QueryTexts.Add(QueryTextNodeConnections(
		ClockCycleParameters.GoBackToBeginning, ClockCycleParameters.UseBuffer, ClockCycleParameters.ThisIsRepair));
	QueryTexts.Add("DROP TTNodes");
	
	Query = New Query(StrConcat(QueryTexts, ";"));
	Query.TempTablesManager = ClockCycleParameters.OrderStructureCache;
	Query.SetParameter("ProductionOrder", ClockCycleParameters.ProductionOrder);
	Query.SetParameter("StartOfPlacement", ClockCycleParameters.StartOfPlacement);
	Query.SetParameter("Nodes", Nodes);
	Query.SetParameter("ExcludeNodes", ExcludeNodes);
	Query.SetParameter("NodeTypeBatchOfStages", NodeTypeBatchOfStages());
	Query.SetParameter("NodeViewMoving", NodeViewMoving());
	Query.SetParameter("TypeOfNodeBatchStructure", TypeOfNodeBatchStructure());
	Query.SetParameter("UseBuffer", ClockCycleParameters.UseBuffer);
	Query.SetParameter("Area", ClockCycleParameters.Area);
	
	If ClockCycleParameters.GoBackToBeginning Then
		Query.SetParameter("StartOfSchedule", BegOfMonth(ClockCycleParameters.StartOfPlacement));
		Query.SetParameter("EndOfSchedule", ClockCycleParameters.RecordSeparator);
		Query.SetParameter("FollowerIsRelease", False);
	Else
		Query.SetParameter("StartOfSchedule", ClockCycleParameters.RecordSeparator);
		Query.SetParameter("EndOfSchedule", BegOfMonth(ClockCycleParameters.StartOfPlacement));
		Query.SetParameter("FollowerIsRelease", True);
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	SamplingNodes = QueryResults[QueryResults.UBound()-4].Select();
	SamplingStages = QueryResults[QueryResults.UBound()-3].Select();
	SamplingTypesOfRC = QueryResults[QueryResults.UBound()-2].Select();
	LinkSelection = QueryResults[QueryResults.UBound()-1].Select();
	
	If Not SamplingStages.Next() Then
		SamplingStages = Undefined;
	EndIf;
	If Not SamplingTypesOfRC.Next() Then
		SamplingTypesOfRC = Undefined;
	EndIf;
	If Not LinkSelection.Next() Then
		LinkSelection = Undefined;
	EndIf;
	
	If PlacementData.Links.Indexes.Count() = 1 Then
		PlacementData.Links.Indexes.Delete(0);
	EndIf;
	
	While SamplingNodes.Next() Do
		
		// Nodes
		NewLineNodes = PlacementData.Nodes.Add();
		FillPropertyValues(NewLineNodes, SamplingNodes);
		
		While SamplingStages <> Undefined
			And SamplingStages.KeyLot = SamplingNodes.KeyLot Do
			
			// Stages
			NewLineStages = PlacementData.Stages.Add();
			FillPropertyValues(NewLineStages, SamplingStages);
			NewLineStages.PlaceInCurCycle = True;
			NewLineNodes.Stages.Add(NewLineStages);
			
			// Types of RC
			If SamplingStages.ThisIsBBV Then
				While SamplingTypesOfRC <> Undefined
					And SamplingTypesOfRC.KeyLot = SamplingStages.KeyLot
					And SamplingTypesOfRC.Stage = SamplingStages.Stage Do
					
					NewRowTypesOfRC = PlacementData.TypesOfRC.Add();
					FillPropertyValues(NewRowTypesOfRC, SamplingTypesOfRC);
					NewLineStages.TypesOfRC.Add(NewRowTypesOfRC);
					
					If Not SamplingTypesOfRC.Next() Then
						SamplingTypesOfRC = Undefined;
					EndIf;
					
				EndDo;
			EndIf;
			
			// Links
			While LinkSelection <> Undefined
				And LinkSelection.KeyLot = SamplingStages.KeyLot
				And LinkSelection.Stage = SamplingStages.Stage Do
				
				NewLinkString = PlacementData.Links.Add();
				FillPropertyValues(NewLinkString, LinkSelection);
				NewLineStages.Links.Add(NewLinkString);
				
				If Not LinkSelection.Next() Then
					LinkSelection = Undefined;
				EndIf;
				
			EndDo;
			
			If Not SamplingStages.Next() Then
				SamplingStages = Undefined;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	PlacementData.Links.Indexes.Add("KeyIsPredecessorParty, PredecessorStage");
	
EndProcedure

Function RequestTextNodesStagesTypesOfRC(GoBackToBeginning)
	
	QueryText = 
		"SELECT
		|	Lots.KeyLot       AS KeyLot,
		|	Lots.QuantityOfBatches AS QuantityOfBatches
		|FROM
		|	TTCacheNumberOfBatches AS Lots
		|WHERE
		|	Lots.KeyLot IN (
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTNodes AS T)
		|
		|ORDER BY
		|	Lots.KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Nodes.KeyLot                                    AS KeyLot,
		|	Stages.Ref                                       AS Stage,
		|	Stages.Department                                AS Department,
		|	Stages.Department.PlanningInterval           AS Interval,
		|	Stages.Department.PlanningIntervalStart    AS IntervalStart,
		|	Stages.Department.PlanningIntervalEnd AS IntervalEnd_,
		|	CASE
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, DAY) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, DAY) <> Stages.Department.PlanningIntervalEnd
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, WEEK) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, WEEK) <> Stages.Department.PlanningIntervalEnd
		|		ELSE FALSE
		|	END                                              AS IntervalHasNonStandardBoundaries,
		|	Stages.StageNumber                                   AS StageNumber,
		|	Stages.NextStageNo                         AS NextStageNo,
		|	Stages.PlanOperationsOfWorkCenterTypes         AS ThisIsBBV,
		|	Stages.OperatingProcedureOfWorkCenterTypes             AS OrderOfOperationOfTypesOfRC,
		|	FALSE                                               AS TimeOfRCTypesIsCalculated,
		|	CASE Stages.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.StageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.StageDuration * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.StageDuration * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.StageDuration
		|	END                                              AS StageDuration,
		|	Stages.UnitOfMeasureOfStageDuration = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS StageToPlaceInDays,
		|	CASE Stages.UnitOfMeasureOfPreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.PreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.PreliminaryBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.PreliminaryBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.PreliminaryBuffer
		|	END                                              AS PreliminaryBuffer,
		|	Stages.UnitOfMeasureOfPreliminaryBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS PreliminaryBufferShouldBePlacedInDays,
		|	CASE Stages.UnitOfMeasureOfFollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.FollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.FollowUpBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.FollowUpBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.FollowUpBuffer
		|	END                                              AS FollowUpBuffer,
		|	Stages.UnitOfMeasureOfFollowUpBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS FinalBufferShouldBePlacedInDays,
		|	FALSE                                               AS Posted_,
		|	Nodes.StartOfPlacement                              AS StartOfPlacement,
		|	FALSE                                               AS ItIsTransfer,
		|	Stages.QuantityOfProductUnitsLotsProducedSimultaneously AS SimultaneouslyProducedNumberOfBatches
		|FROM
		|	TTNodes AS Nodes
		|	
		|	INNER JOIN Catalog.ProductionStages AS Stages
		|	ON Nodes.Ref = Stages.Owner
		|
		|WHERE
		|	Nodes.NodeView = &TypeOfNodeBatchStructure
		|	AND NOT Stages.DeletionMark
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCacheNumberOfBatches AS T
		|		WHERE
		|			T.KeyLot = Nodes.KeyLot)
		|
		|UNION ALL
		|
		|SELECT
		|	Nodes.KeyLot                                    AS KeyLot,
		|	Stages.Ref                                       AS Stage,
		|	Stages.Department                                AS Department,
		|	Stages.Department.PlanningInterval           AS Interval,
		|	Stages.Department.PlanningIntervalStart    AS IntervalStart,
		|	Stages.Department.PlanningIntervalEnd AS IntervalEnd_,
		|	CASE
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, DAY) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, DAY) <> Stages.Department.PlanningIntervalEnd
		|		WHEN Stages.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN BEGINOFPERIOD(Stages.Department.PlanningIntervalStart, WEEK) <> Stages.Department.PlanningIntervalStart
		|								OR ENDOFPERIOD(Stages.Department.PlanningIntervalEnd, WEEK) <> Stages.Department.PlanningIntervalEnd
		|		ELSE FALSE
		|	END                                              AS IntervalHasNonStandardBoundaries,
		|	Stages.StageNumber                                   AS StageNumber,
		|	Stages.NextStageNo                         AS NextStageNo,
		|	Stages.PlanOperationsOfWorkCenterTypes         AS ThisIsBBV,
		|	Stages.OperatingProcedureOfWorkCenterTypes             AS OrderOfOperationOfTypesOfRC,
		|	TRUE                                             AS TimeOfRCTypesIsCalculated,
		|	CASE Stages.UnitOfMeasureOfStageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.StageDuration
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.StageDuration * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.StageDuration * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.StageDuration
		|	END                                              AS StageDuration,
		|	Stages.UnitOfMeasureOfStageDuration = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS StageToPlaceInDays,
		|	CASE Stages.UnitOfMeasureOfPreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.PreliminaryBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.PreliminaryBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.PreliminaryBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.PreliminaryBuffer
		|	END                                              AS PreliminaryBuffer,
		|	Stages.UnitOfMeasureOfPreliminaryBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS PreliminaryBufferShouldBePlacedInDays,
		|	CASE Stages.UnitOfMeasureOfFollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|			THEN Stages.FollowUpBuffer
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Stages.FollowUpBuffer * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Stages.FollowUpBuffer * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.SECOND)
		|			THEN Stages.FollowUpBuffer
		|	END                                              AS FollowUpBuffer,
		|	Stages.UnitOfMeasureOfFollowUpBuffer = VALUE(
		|		Enum.TimeMeasureUnits.DAY)     AS FinalBufferShouldBePlacedInDays,
		|	FALSE                                               AS Posted_,
		|	Nodes.StartOfPlacement                              AS StartOfPlacement,
		|	FALSE                                               AS ItIsTransfer,
		|	1                                                  AS SimultaneouslyProducedNumberOfBatches
		|FROM
		|	TTNodes AS Nodes
		|	
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Nodes.Ref = Stages.ProductionLot
		|
		|WHERE
		|	Nodes.NodeView = &NodeTypeBatchOfStages
		|	AND Stages.Posted
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCacheNumberOfBatches AS T
		|		WHERE
		|			T.KeyLot = Nodes.KeyLot)
		|
		|UNION ALL
		|
		|SELECT
		|	Nodes.KeyLot   AS KeyLot,
		|	VALUE(Catalog.ProductionStages.EmptyRef)    AS Stage,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	UNDEFINED      AS Interval,
		|	UNDEFINED      AS IntervalStart,
		|	UNDEFINED      AS IntervalEnd_,
		|	FALSE              AS IntervalHasNonStandardBoundaries,
		|	0                 AS StageNumber,
		|	0                 AS NextStageNo,
		|	FALSE              AS ThisIsBBV,
		|	UNDEFINED      AS OrderOfOperationOfTypesOfRC,
		|	FALSE              AS TimeOfRCTypesIsCalculated,
		|	ISNULL(TransferDurationDays.ProductionDurationDays, 0) AS StageDuration,
		|	TRUE            AS StageToPlaceInDays,
		|	0                 AS PreliminaryBuffer,
		|	FALSE              AS PreliminaryBufferShouldBePlacedInDays,
		|	0                 AS FollowUpBuffer,
		|	FALSE              AS FinalBufferShouldBePlacedInDays,
		|	FALSE              AS Posted_,
		|	Nodes.StartOfPlacement AS StartOfPlacement,
		|	TRUE            AS ItIsTransfer,
		|	1                 AS SimultaneouslyProducedNumberOfBatches
		|FROM
		|	TTNodes AS Nodes
		|	
		|	LEFT JOIN TTCacheDurationOfMove AS TransferDurationDays
		|	ON Nodes.KeyLot = TransferDurationDays.KeyLot
		|WHERE
		|	Nodes.NodeView = &NodeViewMoving
		|
		|ORDER BY
		|	KeyLot,
		|	&ConditionForOrderingStages,
		|	Stage
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Nodes.KeyLot                          AS KeyLot,
		|	Stages.Ref                             AS Stage,
		|	Stages.StageNumber                         AS StageNumber,
		|	Kinds.LineNumber                         AS LineNumber,
		|	Kinds.WorkCenterType                                     AS WorkCenterType,
		|	Kinds.WorkCenterType.UseAvailabilityAccordingToSchedule AS ConsiderAvailability,
		|	CASE Kinds.WorkCenterType.UnitOfMeasureOfWorkCenterSchedule
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Kinds.WorkCenterType.MaximumWorkCenterAvailability * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Kinds.WorkCenterType.MaximumWorkCenterAvailability * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|			THEN Kinds.WorkCenterType.MaximumWorkCenterAvailability * 86400
		|	END                                    AS MaximumAvailability,
		|	CASE
		|		WHEN Kinds.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|			THEN Stages.Department
		|		ELSE Kinds.WorkCenterType.Calendar
		|	END                                    AS ChartKey,
		|	Stages.Department.PlanningInterval AS Interval,
		|	CASE Kinds.UnitOfMeasure
		|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|			THEN Kinds.OperationTime * 60
		|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|			THEN Kinds.OperationTime * 3600
		|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|			THEN Kinds.OperationTime * 86400
		|		ELSE Kinds.OperationTime
		|	END                                    AS Time,
		|	Kinds.QuantityCalculationAlgorithm           AS QuantityCalculationAlgorithm,
		|	CASE
		|		WHEN Kinds.WorkCenterType.EnterAvailabilityForWorkCenterType
		|			THEN Kinds.WorkCenterType.NumberOfWorkCenters
		|		ELSE ISNULL(NumberOfRC.NumberOfWorkCenters, 0)
		|	END                                    AS NumberOfWorkCenters
		|FROM
		|	TTNodes AS Nodes
		|
		|		INNER JOIN Catalog.ProductionStages AS Stages
		|		ON Nodes.Ref = Stages.Owner
		|
		|		INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS Kinds
		|		ON Stages.Ref = Kinds.Ref
		|
		|		LEFT JOIN TTCacheNumberOfRC AS NumberOfRC
		|		ON Kinds.WorkCenterType = NumberOfRC.WorkCenterType
		|WHERE
		|	Nodes.NodeView = &TypeOfNodeBatchStructure
		|	AND NOT Stages.DeletionMark
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCacheNumberOfBatches AS T
		|		WHERE
		|			T.KeyLot = Nodes.KeyLot)
		|
		|UNION ALL
		|
		|SELECT
		|	Nodes.KeyLot                          AS KeyLot,
		|	Stages.Ref                             AS Stage,
		|	Stages.StageNumber                         AS StageNumber,
		|	Kinds1.LineNumber                        AS LineNumber,
		|	ISNULL(Kinds2.WorkCenterType, Kinds1.WorkCenterType)  AS WorkCenterType,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN Kinds2.WorkCenterType.UseAvailabilityAccordingToSchedule
		|		ELSE Kinds1.WorkCenterType.UseAvailabilityAccordingToSchedule
		|	END AS ConsiderAvailability,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE Kinds2.WorkCenterType.UnitOfMeasureOfWorkCenterSchedule
		|					WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|						THEN Kinds2.WorkCenterType.MaximumWorkCenterAvailability * 60
		|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|						THEN Kinds2.WorkCenterType.MaximumWorkCenterAvailability * 3600
		|					WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|						THEN Kinds2.WorkCenterType.MaximumWorkCenterAvailability * 86400
		|				END
		|		ELSE
		|			CASE Kinds1.WorkCenterType.UnitOfMeasureOfWorkCenterSchedule
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN Kinds1.WorkCenterType.MaximumWorkCenterAvailability * 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN Kinds1.WorkCenterType.MaximumWorkCenterAvailability * 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN Kinds1.WorkCenterType.MaximumWorkCenterAvailability * 86400
		|			END
		|	END AS MaximumAvailability,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE
		|					WHEN Kinds2.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|						THEN Stages.Department
		|					ELSE Kinds2.WorkCenterType.Calendar
		|				END
		|		ELSE
		|			CASE
		|				WHEN Kinds1.WorkCenterType.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN Stages.Department
		|				ELSE Kinds1.WorkCenterType.Calendar
		|			END
		|	END                                    AS ChartKey,
		|	Stages.Department.PlanningInterval AS Interval,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE Kinds2.UnitOfMeasure
		|					WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|						THEN Kinds2.OperationTime * 60
		|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|						THEN Kinds2.OperationTime * 3600
		|					WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|						THEN Kinds2.OperationTime * 86400
		|					ELSE Kinds2.OperationTime
		|				END
		|		ELSE
		|			CASE Kinds1.UnitOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN Kinds1.OperationTime * 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN Kinds1.OperationTime * 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN Kinds1.OperationTime * 86400
		|				ELSE Kinds1.OperationTime
		|			END
		|	END                                    AS Time,
		|	""""                                     AS QuantityCalculationAlgorithm,
		|	CASE
		|		WHEN Kinds2.WorkCenterType IS NOT NULL
		|			THEN
		|				CASE
		|					WHEN Kinds2.WorkCenterType.EnterAvailabilityForWorkCenterType
		|						THEN Kinds2.WorkCenterType.NumberOfWorkCenters
		|					ELSE ISNULL(NumberOfRC2.NumberOfWorkCenters, 0)
		|				END
		|		ELSE
		|			CASE
		|				WHEN Kinds1.WorkCenterType.EnterAvailabilityForWorkCenterType
		|					THEN Kinds1.WorkCenterType.NumberOfWorkCenters
		|				ELSE ISNULL(NumberOfRC1.NumberOfWorkCenters, 0)
		|			END
		|	END                                    AS NumberOfWorkCenters
		|FROM
		|	TTNodes AS Nodes
		|
		|	INNER JOIN Document.ProductionStage2_2 AS Stages
		|	ON Nodes.Ref = Stages.ProductionLot
		|
		|	INNER JOIN Document.ProductionStage2_2.WorkCenterTypes AS Kinds1
		|	ON Stages.Ref = Kinds1.Ref
		|
		|	LEFT JOIN Document.ProductionStage2_2.AlternateWorkCenterTypes AS Kinds2
		|	ON Stages.Ref = Kinds2.Ref
		|		AND Kinds1.ConnectionKey = Kinds2.LinkKeyWorkCenterTypes
		|		AND NOT Kinds1.Use
		|		AND Kinds2.Use
		|
		|	LEFT JOIN TTCacheNumberOfRC AS NumberOfRC1
		|	ON Kinds1.WorkCenterType = NumberOfRC1.WorkCenterType
		|
		|	LEFT JOIN TTCacheNumberOfRC AS NumberOfRC2
		|	ON Kinds2.WorkCenterType = NumberOfRC2.WorkCenterType
		|
		|WHERE
		|	Nodes.NodeView = &NodeTypeBatchOfStages
		|	AND Stages.Posted
		|	AND (Kinds1.Use OR ISNULL(Kinds2.Use, FALSE))
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCacheNumberOfBatches AS T
		|		WHERE
		|			T.KeyLot = Nodes.KeyLot)
		|
		|ORDER BY
		|	KeyLot,
		|	&ConditionForOrderingStages,
		|	Stage,
		|	&ConditionForOrderingTypesOfRC";
	
	QueryText = StrReplace(QueryText,
		"&ConditionForOrderingStages",
		?(GoBackToBeginning, "StageNumber ASC", "StageNumber DESC"));
	
	QueryText = StrReplace(QueryText,
		"&ConditionForOrderingTypesOfRC",
		?(GoBackToBeginning, "LineNumber ASC", "LineNumber DESC"));
	
	Return QueryText;
	
EndFunction

Function QueryTextNodeConnections(GoBackToBeginning, UseBuffer, ThisIsRepair)
	
	QueryText = 
		"SELECT DISTINCT
		|	Links.KeyLot               AS KeyLot,
		|	Links.Stage                     AS Stage,
		|	Links.KeyIsPredecessorParty AS KeyIsPredecessorParty,
		|	Links.PredecessorStage       AS PredecessorStage,
		|	&ScheduleStartOfPlacement        AS StartOfPlacement,
		|	Links.StageNumber               AS StageNumber
		|FROM
		|	TTNodeCommunicationCache AS Links
		|
		|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS Schedule
		|	ON &UseBuffer = FALSE
		|		AND Schedule.ProductionOrder = &ProductionOrder
		|		AND Links.KeyIsPredecessorParty = Schedule.KeyLot
		|		AND Links.PredecessorStage = Schedule.Stage
		|		AND Schedule.RecordSeparator BETWEEN &StartOfSchedule AND &EndOfSchedule
		|
		|	LEFT JOIN InformationRegister.BufferOfTargetProductionScheduleCalculation AS Buffer
		|	ON &UseBuffer = TRUE
		|		AND Buffer.Area = &Area
		|		AND Buffer.ProductionOrder = &ProductionOrder
		|		AND Links.KeyIsPredecessorParty = Buffer.KeyLot
		|		AND Links.PredecessorStage = Buffer.Stage
		|		AND Buffer.RecordSeparator BETWEEN &StartOfSchedule AND &EndOfSchedule
		|WHERE
		|	Links.KeyLot IN (
		|		SELECT
		|			T.KeyLot
		|		FROM
		|			TTNodes AS T)
		|	AND TRUE IN (
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			TTCacheNumberOfBatches AS T
		|		WHERE
		|			T.KeyLot = Links.KeyLot)
		|
		|ORDER BY
		|	KeyLot,
		|	&OrderingConditionTTNodeCommunicationCache,
		|	Stage";
	
	If GoBackToBeginning Then
		QueryText = StrReplace(QueryText, "&ScheduleStartOfPlacement",
			?(UseBuffer,
				"CASE
				|	WHEN Buffer.Ending IS NULL
				|		THEN DATETIME(1,1,1)
				|	WHEN Buffer.Ending = Buffer.Begin
				|		THEN Buffer.Ending
				|	ELSE DATEADD(Buffer.Ending, SECOND, 1)
				|END",
				"CASE
				|	WHEN Schedule.Ending IS NULL
				|		THEN DATETIME(1,1,1)
				|	WHEN Schedule.Ending = Schedule.Begin
				|		THEN Schedule.Ending
				|	ELSE DATEADD(Schedule.Ending, SECOND, 1)
				|END"));
		QueryText = StrReplace(QueryText, "&OrderingConditionTTNodeCommunicationCache", "StageNumber ASC");
	ElsIf ThisIsRepair Then
		QueryText = StrReplace(QueryText, "&ScheduleStartOfPlacement",
			?(UseBuffer,
				"ISNULL(Buffer.StartOfPlacement, DATETIME(1,1,1))",
				"ISNULL(Schedule.StartOfPlacement, DATETIME(1,1,1))"));
		QueryText = StrReplace(QueryText, "&OrderingConditionTTNodeCommunicationCache", "StageNumber DESC");
	Else
		QueryText = StrReplace(QueryText, "&ScheduleStartOfPlacement",
			?(UseBuffer,
				"ISNULL(Buffer.Begin, DATETIME(1,1,1))",
				"ISNULL(Schedule.Begin, DATETIME(1,1,1))"));
		QueryText = StrReplace(QueryText, "&OrderingConditionTTNodeCommunicationCache", "StageNumber DESC");
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure CacheOrderStructure(OrderStructureCache, SourceData, CompleteCalculation)
	
	QueryText = 
		"SELECT
		|	NestedQuery.KeyProducts   AS KeyProducts,
		|	NestedQuery.KeyLot         AS KeyLot,
		|	NestedQuery.Stage               AS Stage,
		|	NestedQuery.Products       AS Products,
		|	NestedQuery.Characteristic     AS Characteristic,
		|	NestedQuery.SupplyMethod  AS SupplyMethod,
		|	NestedQuery.ThisIsRelease          AS ThisIsRelease,
		|	NestedQuery.ItIsTransfer     AS ItIsTransfer,
		|	NestedQuery.ProductionLot AS ProductionLot,
		|	MAX(NestedQuery.StageNumber)         AS StageNumber,
		|	MAX(NestedQuery.StageIsRelevant)       AS StageIsRelevant,
		|	NestedQuery.Products.ProductKind AS ProductKind,
		|	MAX(NestedQuery.BillOfMaterials)       AS BillOfMaterials,
		|	MAX(NestedQuery.WarehouseFromTransfer)   AS WarehouseFromTransfer,
		|	SUM(NestedQuery.Scheduled)         AS Scheduled,
		|	SUM(NestedQuery.Launched)              AS Launched
		|INTO TTCacheOrderStructure
		|FROM
		|	(
		|		SELECT
		|			OrderStructure.KeyProducts AS KeyProducts,
		|			OrderStructure.KeyLot       AS KeyLot,
		|			OrderStructure.BillOfMaterials     AS BillOfMaterials,
		|			OrderStructure.Stage             AS Stage,
		|			OrderStructure.Products     AS Products,
		|			OrderStructure.Characteristic   AS Characteristic,
		|			CASE
		|				WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
		|					THEN OrderStructure.Warehouse
		|				ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|			END                            AS WarehouseFromTransfer,
		|			ISNULL(NSICache.SupplyMethod, VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS SupplyMethod,
		|			OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) AS ThisIsRelease,
		|			OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
		|				OR OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|					AND TRUE IN (
		|						SELECT TOP 1
		|							TRUE
		|						FROM
		|							InformationRegister.OrderStructure AS OrderStructureMoving
		|						WHERE
		|							OrderStructureMoving.KeyLot = OrderStructure.KeyLot
		|							AND OrderStructureMoving.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)) AS ItIsTransfer,
		|			ISNULL(StagesDocument.ProductionLot, VALUE(Catalog.ProductionLots.EmptyRef)) AS ProductionLot,
		|			ISNULL(StagesCatalog.StageNumber, ISNULL(StagesDocument.StageNumber, 0)) AS StageNumber,
		|			ISNULL(NOT StagesCatalog.DeletionMark, ISNULL(StagesDocument.Posted, TRUE)) AS StageIsRelevant,
		|			OrderStructure.Scheduled AS Scheduled,
		|			OrderStructure.Launched AS Launched,
		|			OrderStructure.AllocatedInFreeProductionLots + OrderStructure.AllocatedInAssignedProductionLots AS AllocatedInFreeProductionLots,
		|			OrderStructure.ToSupply - OrderStructure.Replaced AS Required2
		|		FROM
		|			InformationRegister.OrderStructure AS OrderStructure
		|				
		|				LEFT JOIN InformationRegister.CacheOfOrderStructureMasterData AS NSICache
		|				ON OrderStructure.Products = NSICache.Products
		|					AND OrderStructure.Characteristic = NSICache.Characteristic
		|					AND OrderStructure.Warehouse = NSICache.Warehouse
		|					AND OrderStructure.Purpose = NSICache.Purpose
		|					AND OrderStructure.ProductionOrder = NSICache.ProductionOrder
		|				
		|				LEFT JOIN Catalog.ProductionStages AS StagesCatalog
		|				ON OrderStructure.Stage = StagesCatalog.Ref
		|				
		|				LEFT JOIN Document.ProductionStage2_2 AS StagesDocument
		|				ON OrderStructure.Stage = StagesDocument.Ref
		|		WHERE
		|			OrderStructure.ProductionOrder = &ProductionOrder
		|			AND OrderStructure.LineKind <> VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyProducts,
		|	NestedQuery.KeyLot,
		|	NestedQuery.Stage,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.SupplyMethod,
		|	NestedQuery.ThisIsRelease,
		|	NestedQuery.ItIsTransfer,
		|	NestedQuery.ProductionLot,
		|	NestedQuery.Products.ProductKind
		|
		|HAVING
		|	SUM(NestedQuery.Required2) > 0
		|	OR SUM(NestedQuery.Scheduled) > 0
		|	OR SUM(NestedQuery.Launched) > 0
		|	OR SUM(NestedQuery.AllocatedInFreeProductionLots) > 0
		|
		|INDEX BY SETS (
		|	(KeyProducts),
		|	(KeyLot, ThisIsRelease),
		|	(Products)
		|)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	OrderStructure.KeyLot       AS KeyLot,
		|	OrderStructure.KeyProducts AS KeyProducts,
		|	OrderStructure.ThisIsRelease        AS ThisIsRelease
		|INTO TTKeyConnectionCache
		|FROM
		|	TTCacheOrderStructure AS OrderStructure
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	NestedQuery.KeyLot                 AS KeyLot,
		|	MAX(NestedQuery.QuantityOfBatches) AS QuantityOfBatches
		|INTO TTCacheNumberOfBatches
		|FROM
		|	(
		|		SELECT
		|			Nodes.KeyLot              AS KeyLot,
		|			Nodes.Products            AS Products,
		|			Nodes.Characteristic          AS Characteristic,
		|			SUM((Nodes.Scheduled + Nodes.Launched)
		|					/ (ISNULL(ProductsBOM.NumberOfPackagesPerStartingLotUnit, 1) * ISNULL(&QueryTextPackagingFactor, 1))
		|				) AS QuantityOfBatches
		|		FROM
		|			TTCacheOrderStructure AS Nodes
		|			
		|			LEFT JOIN InformationRegister.ProductsBOM AS ProductsBOM
		|			ON Nodes.BillOfMaterials = ProductsBOM.BillOfMaterials
		|				AND Nodes.ProductKind = ProductsBOM.ProductKind
		|				AND ProductsBOM.Products   IN (Nodes.Products, VALUE(Catalog.Products.EmptyRef))
		|				AND ProductsBOM.Characteristic IN (Nodes.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|		WHERE
		|			Nodes.ThisIsRelease
		|
		|		GROUP BY
		|			Nodes.KeyLot,
		|			Nodes.Products,
		|			Nodes.Characteristic
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.KeyLot
		|
		|HAVING
		|	MAX(NestedQuery.QuantityOfBatches) > 0
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Successors.KeyLot      AS KeyLot,
		|	Successors.Stage            AS Stage,
		|	Successors.StageNumber      AS StageNumber,
		|	Precursors.KeyLot     AS KeyIsPredecessorParty,
		|	Precursors.Stage           AS PredecessorStage
		|INTO TTNodeCommunicationCache
		|FROM
		|	TTCacheOrderStructure AS Successors
		|
		|	INNER JOIN TTCacheOrderStructure AS Precursors
		|	ON Successors.KeyProducts = Precursors.KeyProducts
		|
		|	INNER JOIN TTCacheNumberOfBatches AS LotReferenceIssue
		|	ON Precursors.KeyLot = LotReferenceIssue.KeyLot
		|WHERE
		|	Successors.ThisIsRelease = &FollowerIsRelease
		|	AND Successors.StageIsRelevant
		|	AND Precursors.ThisIsRelease <> &FollowerIsRelease
		|	AND Precursors.StageIsRelevant
		|
		|INDEX BY
		|	KeyLot
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	WorkCenters.WorkCenterType  AS WorkCenterType,
		|	COUNT(WorkCenters.Ref) AS NumberOfWorkCenters
		|INTO TTCacheNumberOfRC
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	NOT WorkCenters.DeletionMark
		|	AND NOT WorkCenters.WorkCenterType.EnterAvailabilityForWorkCenterType
		|
		|GROUP BY
		|	WorkCenters.WorkCenterType
		|
		|INDEX BY
		|	WorkCenterType
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Warehouses.Ref AS Warehouse
		|INTO TTWarehousesWithQualityControl
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.ControlQualityOfReceivedGoods
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Supply.KeyLot AS KeyLot,
		|	MAX(
		|		ISNULL(Demand.SupplyMethod.OrderFulfillmentPeriod, 0)
		|		+ CASE
		|			WHEN WarehousesWithQualityControl.Warehouse IS NOT NULL
		|					AND ISNULL(Demand.Products.ControlQualityOfReceivedGoods, FALSE)
		|				THEN Demand.Products.TermOfQualityControl
		|			ELSE 0
		|		END) AS ProductionDurationDays
		|INTO TTCacheDurationOfMove
		|FROM
		|	TTCacheOrderStructure AS Demand
		|
		|	INNER JOIN TTCacheOrderStructure AS Supply
		|	ON Demand.KeyProducts = Supply.KeyProducts
		|
		|	LEFT JOIN TTWarehousesWithQualityControl AS WarehousesWithQualityControl
		|	ON Supply.WarehouseFromTransfer = WarehousesWithQualityControl.Warehouse
		|WHERE
		|	NOT Demand.ThisIsRelease
		|	AND Supply.ThisIsRelease
		|	AND Supply.ItIsTransfer
		|
		|GROUP BY
		|	Supply.KeyLot
		|
		|INDEX BY
		|	KeyLot
		|;";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsBOM.Package",
			"ProductsBOM.Products"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = OrderStructureCache;
	Query.SetParameter("ProductionOrder", SourceData.ProductionOrder);
	Query.SetParameter("GoBackToBeginning", SourceData.GoBackToBeginning);
	Query.SetParameter("CompleteCalculation", CompleteCalculation);
	
	If SourceData.GoBackToBeginning Then
		Query.SetParameter("FollowerIsRelease", False);
	Else
		Query.SetParameter("FollowerIsRelease", True);
	EndIf;
	
	Query.Execute();

EndProcedure

#EndRegion

#Region ReadWorkSchedules

Procedure ReadCharts(CacheCharts, Schedules)
	
	Query = New Query(
		"SELECT
		|	BusinessStructure.Ref                                           AS ChartKey,
		|	BusinessStructure.PlanningInterval                             AS Interval,
		|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS Schedule
		|INTO TTBBVGraphics
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON BusinessStructure.Ref = Schedules.Ref
		|
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)
		|WHERE
		|	BusinessStructure.ProductionBusinessUnit
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	WorkCenterTypes.Calendar                          AS ChartKey,
		|	WorkCenterTypes.Department.PlanningInterval AS Interval,
		|	WorkCenterTypes.Calendar                          AS Schedule
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|WHERE
		|	WorkCenterTypes.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	BusinessStructure.Ref                                           AS Department,
		|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS Schedule
		|INTO TTChartsUBBV
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON BusinessStructure.Ref = Schedules.Ref
		|
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)
		|WHERE
		|	BusinessStructure.ProductionBusinessUnit
		|
		|UNION ALL
		|
		|// A graph for calculating movements
		|SELECT
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	MainEnterpriseCalendar.Value                  AS Schedule
		|FROM
		|	Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	Schedules.Schedule AS Schedule
		|FROM
		|	TTBBVGraphics AS Schedules
		|
		|UNION
		|
		|SELECT
		|	MainEnterpriseCalendar.Value AS Schedule
		|FROM
		|	Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar");
	
	Query.TempTablesManager = CacheCharts;
	Schedules = Query.Execute().Unload().UnloadColumn("Schedule");
	
EndProcedure

Procedure ReadSchedule(ClockCycleParameters, CacheCharts, Schedules, Begin, Ending)
	
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(CacheCharts, Schedules, Begin, Ending, False);
	
	QueryText = 
		"SELECT DISTINCT
		|	Schedules.ChartKey AS ChartKey,
		|	Schedules.Interval    AS Interval,
		|	CASE Schedules.Interval
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
		|			THEN BEGINOFPERIOD(WorkSchedules1.ScheduleDate, DAY)
		|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
		|			THEN BEGINOFPERIOD(WorkSchedules1.ScheduleDate, WEEK)
		|		ELSE BEGINOFPERIOD(WorkSchedules1.ScheduleDate, MONTH)
		|	END               AS Date,
		|	DATETIME(1, 1, 1, 1, 1, 1) AS EndOfShift
		|FROM
		|	TTBBVGraphics AS Schedules
		|	
		|	INNER JOIN TTWorkSchedules AS WorkSchedules1
		|	ON Schedules.Schedule = WorkSchedules1.WorkScheduleCalendar
		|WHERE
		|	Schedules.Interval IN (
		|			VALUE(Enum.ProductionScheduleAccuracy.DAY),
		|			VALUE(Enum.ProductionScheduleAccuracy.WEEK),
		|			VALUE(Enum.ProductionScheduleAccuracy.MONTH))
		|
		|UNION ALL
		|
		|SELECT
		|	Schedules.ChartKey AS ChartKey,
		|	Schedules.Interval    AS Interval,
		|	MIN(DATEADD(WorkSchedules1.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1))))) AS Date,
		|	MAX(
		|		CASE
		|			WHEN WorkSchedules1.EndTime IS NULL 
		|				OR WorkSchedules1.EndTime = DATETIME(1, 1, 1)
		|				THEN DATEADD(WorkSchedules1.ScheduleDate, DAY, 1)
		|			ELSE DATEADD(WorkSchedules1.ScheduleDate, MINUTE,
		|				HOUR(WorkSchedules1.EndTime)*60 + MINUTE(WorkSchedules1.EndTime))
		|		END) AS EndOfShift
		|FROM
		|	TTBBVGraphics AS Schedules
		|	
		|	INNER JOIN TTWorkSchedules AS WorkSchedules1
		|	ON Schedules.Schedule = WorkSchedules1.WorkScheduleCalendar
		|WHERE
		|	Schedules.Interval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
		|	AND WorkSchedules1.Period >= &Begin
		|
		|GROUP BY
		|	Schedules.ChartKey,
		|	Schedules.Interval,
		|	WorkSchedules1.WorkScheduleCalendar,
		|	WorkSchedules1.Period
		|
		|ORDER BY
		|	ChartKey,
		|	Interval,
		|	&OrderingConditionDate
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedules.ChartKey                                  AS ChartKey,
		|	Schedules.Interval                                     AS Interval,
		|
		|	WorkSchedules1.ScheduleDate                               AS Date,
		|	ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)) AS BeginTime,
		|	CASE
		|		WHEN WorkSchedules1.EndTime IS NULL 
		|				OR WorkSchedules1.EndTime = DATETIME(1, 1, 1)
		|			THEN DATEDIFF(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)), DATETIME(1, 1, 1, 23, 59, 59), SECOND) + 1
		|		ELSE DATEDIFF(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)), WorkSchedules1.EndTime, SECOND)
		|	END                                                AS Duration
		|FROM
		|	TTBBVGraphics AS Schedules
		|	
		|	INNER JOIN TTWorkSchedules AS WorkSchedules1
		|	ON Schedules.Schedule = WorkSchedules1.WorkScheduleCalendar
		|WHERE
		|	Schedules.Interval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	Schedules.Department                                   AS Department, 
		|	WorkSchedules1.ScheduleDate                                  AS Date,
		|	ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1))    AS BeginTime,
		|	CASE
		|		WHEN WorkSchedules1.EndTime IS NULL
		|				OR WorkSchedules1.EndTime = DATETIME(1, 1, 1)
		|			THEN DATETIME(1, 1, 1, 23, 59, 59)
		|		ELSE WorkSchedules1.EndTime
		|	END AS EndTime,
		|
		|	CASE
		|		WHEN WorkSchedules1.EndTime IS NULL
		|				OR WorkSchedules1.EndTime = DATETIME(1, 1, 1)
		|			THEN DATEDIFF(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)), DATETIME(1, 1, 1, 23, 59, 59), SECOND) + 1
		|		ELSE DATEDIFF(ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)), WorkSchedules1.EndTime, SECOND)
		|	END                                                   AS Duration,
		|
		|	ISNULL(WorkSchedules1.BeginTime, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
		|		OR ISNULL(WorkSchedules1.EndTime, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1) AS ThereAreBoundaries
		|
		|FROM
		|	TTChartsUBBV AS Schedules
		|	
		|	INNER JOIN TTWorkSchedules AS WorkSchedules1
		|	ON Schedules.Schedule = WorkSchedules1.WorkScheduleCalendar
		|
		|ORDER BY
		|	Department,
		|	&OrderingConditionDate,
		|	&OrderingConditionTime";
	
	QueryText = StrReplace(QueryText,
		"&OrderingConditionDate",
		?(ClockCycleParameters.GoBackToBeginning, "DATE ASC", "DATE DESC"));
	QueryText = StrReplace(QueryText,
		"&OrderingConditionTime",
		?(ClockCycleParameters.GoBackToBeginning, "BeginTime ASC", "BeginTime DESC"));
	
	Query = New Query(QueryText);
	Query.TempTablesManager = CacheCharts;
	Query.SetParameter("Begin", Begin);
	QueryResults = Query.ExecuteBatch();
	
	TMCommonUse.DestroyTemporaryTables(CacheCharts,, "TTBBVGraphics,TTChartsUBBV");
	
	// BBB
	BBVSchedule = QueryResults[0].Unload();
	
	If Not QueryResults[1].IsEmpty() Then
		
		Selection = QueryResults[1].Select();
		While Selection.Next() Do
			
			BeginTime = Date(Year(Selection.Date), Month(Selection.Date), Day(Selection.Date),
				Hour(Selection.BeginTime), Minute(Selection.BeginTime), Second(Selection.BeginTime));
			EndTime = BeginTime + Selection.Duration;
			
			If Not BeginTime = BegOfHour(BeginTime) Then
				BeginTime = EndOfHour(BeginTime) + 1;
			EndIf;
			
			While BeginTime < EndTime Do
				
				NewRow = BBVSchedule.Add();
				FillPropertyValues(NewRow, Selection, "ChartKey, Interval");
				NewRow.Date = BeginTime;
				
				BeginTime = EndOfHour(BeginTime) + 1;
				
			EndDo;
			
		EndDo;
		
		BBVSchedule.Sort(
			"ChartKey, Interval, Date " + ?(ClockCycleParameters.GoBackToBeginning, "ASC", "DESC"));
		
	EndIf;
	
	TMCommonUse.AddSequenceNumberOfRowsToTable(BBVSchedule);
	
	BBVSchedule.Indexes.Add("ChartKey, Interval, Date");
	BBVSchedule.Indexes.Add("ChartKey, Interval, EndOfShift");
	
	ClockCycleParameters.BBVSchedule = BBVSchedule;
	
	// UBBV
	UbbwSchedule = QueryResults[2].Unload();
	UbbwSchedule.Columns.Add("Begin", New TypeDescription("Date"));
	UbbwSchedule.Columns.Add("Ending", New TypeDescription("Date"));
	
	UBBVIndex = New Map;
	
	If UbbwSchedule.Count() > 0 Then
		
		Department = UbbwSchedule[0].Department;
		ThereAreBoundaries = False;
		
		UBBVIndex.Insert(Department, New Structure("Begin, Ending, ThereAreBoundaries", 0));
		
		For IndexOf = 0 To UbbwSchedule.Count()-1 Do
			
			String = UbbwSchedule[IndexOf];
			
			If String.Department <> Department Then
				
				UBBVIndex[Department].Ending = IndexOf - 1;
				UBBVIndex[Department].ThereAreBoundaries = ThereAreBoundaries;
				
				Department = String.Department;
				ThereAreBoundaries = False;
				UBBVIndex.Insert(Department, New Structure("Begin, Ending, ThereAreBoundaries", IndexOf));
				
			EndIf;
			
			String.Begin = Date(Year(String.Date), Month(String.Date), Day(String.Date),
				Hour(String.BeginTime), Minute(String.BeginTime), Second(String.BeginTime));
			String.Ending = String.Begin + String.Duration;
			
			If String.ThereAreBoundaries And Not ThereAreBoundaries Then
				ThereAreBoundaries = True;
			EndIf;
			
		EndDo;
		
		UBBVIndex[Department].Ending = IndexOf - 1;
		UBBVIndex[Department].ThereAreBoundaries = ThereAreBoundaries;
		
		UbbwSchedule.Indexes.Add("Department, Date");
		
	EndIf;
	
	ClockCycleParameters.UbbwSchedule = UbbwSchedule;
	ClockCycleParameters.UBBVIndex = UBBVIndex;
	
EndProcedure

#EndRegion

#Region Constructors

Function NewCalculationParameters()
	
	Result = New Structure();
	
	Result.Insert("VectorizeCalculation", Not Common.FileInfobase());
	Result.Insert("ThreadsCount", ?(Result.VectorizeCalculation, 8, 1));
	Result.Insert("CalculationQueue", New Array(Result.ThreadsCount));
	Result.Insert("IntervalForCheckingCompletionOfCalculation", 2);
	Result.Insert("ErrorLimit", 3);
	
	Return Result;
	
EndFunction

Function NewOrderCalculationResult()
	
	Result = New Structure;
	Result.Insert("Cancel", False);
	Result.Insert("NumberOfStages", 0);
	Result.Insert("Begin", '39991231');
	Result.Insert("Ending", '00010101');
	
	Return Result;
	
EndFunction

Function NewResultOfCalculationCycle()
	
	Result = New Structure;
	Result.Insert("Cancel", False);
	Result.Insert("NumberOfStages", 0);
	Result.Insert("Begin", '39991231');
	Result.Insert("Ending", '00010101');
	
	Return Result;
	
EndFunction

// New clock cycle parameters.
// 
// Returns:
//  Structure - New Clock Parameters:
// * ProductionOrder - DocumentRef.ProductionOrder2_2 -
// * GoBackToBeginning - Boolean -
// * StartOfPlacement - Date -
// * CompleteCalculation - Boolean -
// * ThisIsRepair - Boolean -
// * RecordSeparator - Date -
// * BBVSchedule - ValueTable -
// * UbbwSchedule - ValueTable -
// * UBBVIndex - Map of KeyAndValue - collection for quick search of schedule lines:
//   ** Key - CatalogRef.BusinessStructure - division;
//   ** Value - Structure:
//     *** Begin - Number - the address of the new binary data of the file.
//     *** Ending - Number - the address of the new binary text data.
//     *** ThereAreBoundaries - Boolean - the address of the new binary text data.
// * OrderStructureCache - TempTablesManager -
// * RecordingGranule - Number -
// * UseBuffer - Boolean -
// * Area - Undefined -
Function NewClockParameters()
	
	Result = New Structure;
	
	Result.Insert("ProductionOrder", Documents.ProductionOrder2_2.EmptyRef());
	Result.Insert("GoBackToBeginning", False);
	Result.Insert("StartOfPlacement", '00010101');
	Result.Insert("CompleteCalculation", True);
	Result.Insert("ThisIsRepair", False);
	Result.Insert("RecordSeparator", '00010101');
	Result.Insert("BBVSchedule", Undefined);
	Result.Insert("UbbwSchedule", Undefined);
	Result.Insert("UBBVIndex", Undefined);
	Result.Insert("OrderStructureCache", Undefined);
	Result.Insert("RecordingGranule", 4000);
	Result.Insert("UseBuffer", False);
	Result.Insert("Area", Undefined);
	
	Return Result;
	
EndFunction

// New placement data.
// 
// Returns:
//  Structure - New Placement Data:
// * Nodes - ValueTable -:
// ** KeyLot 
// ** QuantityOfBatches - Number -
// ** Stages - Array -
// ** FollowersAreRead - Boolean -
// ** Begin - Date -
// ** Ending - Date -
// * Stages - ValueTable -:
// ** KeyLot 
// ** Stage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 -
// ** Department - CatalogRef.BusinessStructure -
// ** Interval - EnumRef.ProductionScheduleAccuracy -
// ** IntervalStart - Date -
// ** IntervalEnd_ - Date -
// ** IntervalHasNonStandardBoundaries - Boolean -
// ** PlaceInCurCycle - Boolean -
// ** Posted_ - Boolean -
// ** StartOfPlacement - Date -
// ** Begin - Date -
// ** Ending - Date -
// ** StageNumber - Number -
// ** NextStageNo - Number -
// ** ThisIsBBV - Boolean -
// ** OrderOfOperationOfTypesOfRC - EnumRef.OperatingProcedureOfWorkCenterTypes -
// ** TimeOfRCTypesIsCalculated - Boolean -
// ** SimultaneouslyProducedNumberOfBatches - Number -
// ** TypesOfRCArePlanned - Boolean -
// ** EndOfLoadingTypesOfRC - Date -
// ** StageDuration - Number -
// ** PreliminaryBuffer - Number -
// ** FollowUpBuffer - Number -
// ** StageToPlaceInDays - Boolean -
// ** PreliminaryBufferShouldBePlacedInDays - Boolean -
// ** FinalBufferShouldBePlacedInDays - Boolean -
// ** ItIsTransfer - Boolean -
// ** ErrorCounter - Number -
// ** TypesOfRC - Array -
// ** Links - Array -
// * TypesOfRC - ValueTable -:
// ** KeyLot 
// ** Stage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 -
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** ConsiderAvailability - Boolean -
// ** MaximumAvailability - Number -
// ** ChartKey - CatalogRef.BusinessStructure, CatalogRef.Calendars -
// ** Interval - EnumRef.ProductionScheduleAccuracy -
// ** Time - Number -
// ** QuantityCalculationAlgorithm - String -
// ** NumberOfWorkCenters - Number -
// * Links - ValueTable -:
// ** KeyLot 
// ** Stage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 -
// ** KeyIsPredecessorParty 
// ** PredecessorStage - CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2 -
// ** StartOfPlacement - Date -
Function NewPlacementData()
	
	// Nodes
	Nodes = New ValueTable();
	Nodes.Columns.Add("KeyLot", Metadata.DefinedTypes.OrderStructureConnectionKey.Type);
	Nodes.Columns.Add("QuantityOfBatches", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	Nodes.Columns.Add("Stages", New TypeDescription("Array"));
	Nodes.Columns.Add("FollowersAreRead", New TypeDescription("Boolean"));
	Nodes.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers()));
	Nodes.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers()));
	
	// Stages
	Stages = New ValueTable();
	Stages.Columns.Add("KeyLot", Metadata.DefinedTypes.OrderStructureConnectionKey.Type);
	Stages.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	
	Stages.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	Stages.Columns.Add("Interval", New TypeDescription("EnumRef.ProductionScheduleAccuracy"));
	Stages.Columns.Add("IntervalStart", New TypeDescription("Date",,, New DateQualifiers()));
	Stages.Columns.Add("IntervalEnd_", New TypeDescription("Date",,, New DateQualifiers()));
	Stages.Columns.Add("IntervalHasNonStandardBoundaries", New TypeDescription("Boolean"));
	
	Stages.Columns.Add("PlaceInCurCycle", New TypeDescription("Boolean"));
	
	Stages.Columns.Add("Posted_", New TypeDescription("Boolean"));
	Stages.Columns.Add("StartOfPlacement", New TypeDescription("Date",,, New DateQualifiers()));
	Stages.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers()));
	Stages.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers()));
	
	Stages.Columns.Add("StageNumber", New TypeDescription("Number", New NumberQualifiers(4)));
	Stages.Columns.Add("NextStageNo", New TypeDescription("Number", New NumberQualifiers(4)));
	
	Stages.Columns.Add("ThisIsBBV", New TypeDescription("Boolean"));
	Stages.Columns.Add("OrderOfOperationOfTypesOfRC", 
		New TypeDescription("EnumRef.OperatingProcedureOfWorkCenterTypes"));
	Stages.Columns.Add("TimeOfRCTypesIsCalculated", New TypeDescription("Boolean"));
	Stages.Columns.Add("SimultaneouslyProducedNumberOfBatches",
			New TypeDescription("Number", New NumberQualifiers(15, 3)));
	
	Stages.Columns.Add("TypesOfRCArePlanned", New TypeDescription("Boolean"));
	Stages.Columns.Add("EndOfLoadingTypesOfRC", New TypeDescription("Date",,, New DateQualifiers()));
	
	Stages.Columns.Add("StageDuration", New TypeDescription("Number", New NumberQualifiers(10)));
	Stages.Columns.Add("PreliminaryBuffer", New TypeDescription("Number", New NumberQualifiers(4)));
	Stages.Columns.Add("FollowUpBuffer", New TypeDescription("Number", New NumberQualifiers(4)));
	Stages.Columns.Add("StageToPlaceInDays", New TypeDescription("Boolean"));
	Stages.Columns.Add("PreliminaryBufferShouldBePlacedInDays", New TypeDescription("Boolean"));
	Stages.Columns.Add("FinalBufferShouldBePlacedInDays", New TypeDescription("Boolean"));
	
	Stages.Columns.Add("ItIsTransfer", New TypeDescription("Boolean"));
	
	Stages.Columns.Add("ErrorCounter", New TypeDescription("Number", New NumberQualifiers(2)));
	
	Stages.Columns.Add("TypesOfRC", New TypeDescription("Array"));
	Stages.Columns.Add("Links", New TypeDescription("Array"));
	
	// Types of RC
	TypesOfRC = New ValueTable;
	TypesOfRC.Columns.Add("KeyLot", Metadata.DefinedTypes.OrderStructureConnectionKey.Type);
	TypesOfRC.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	TypesOfRC.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	TypesOfRC.Columns.Add("ConsiderAvailability", New TypeDescription("Boolean"));
	TypesOfRC.Columns.Add("MaximumAvailability", New TypeDescription("Number", New NumberQualifiers(12)));
	TypesOfRC.Columns.Add("ChartKey",
			New TypeDescription("CatalogRef.BusinessStructure, CatalogRef.Calendars"));
	TypesOfRC.Columns.Add("Interval", New TypeDescription("EnumRef.ProductionScheduleAccuracy"));
	TypesOfRC.Columns.Add("Time", New TypeDescription("Number", New NumberQualifiers(15, 1)));
	TypesOfRC.Columns.Add("QuantityCalculationAlgorithm", New TypeDescription("String",, New StringQualifiers()));
	TypesOfRC.Columns.Add("NumberOfWorkCenters", New TypeDescription("Number", New NumberQualifiers(6, 1)));
	
	// Connections between nodes
	Links = New ValueTable;
	Links.Columns.Add("KeyLot", Metadata.DefinedTypes.OrderStructureConnectionKey.Type);
	Links.Columns.Add("Stage", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	Links.Columns.Add("KeyIsPredecessorParty", Metadata.DefinedTypes.OrderStructureConnectionKey.Type);
	Links.Columns.Add("PredecessorStage", New TypeDescription("CatalogRef.ProductionStages, DocumentRef.ProductionStage2_2"));
	Links.Columns.Add("StartOfPlacement", New TypeDescription("Date",,, New DateQualifiers()));
	
	Result = New Structure;
	Result.Insert("Nodes", Nodes);
	Result.Insert("Stages", Stages);
	Result.Insert("TypesOfRC", TypesOfRC);
	Result.Insert("Links", Links);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Errors

Procedure HandleCalculationLooping(ProductionOrder, KeyLot, Stage)
	
	BeginTransaction();
	Try
		// Task convolution
		Set = InformationRegisters.OrderStructureCalculationJobsProductionSchedule.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(ProductionOrder);
		SetPrivilegedMode(True);
		Set.Write();
		SetPrivilegedMode(False);
		
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddJob(ProductionOrder);
		
		// Error Recording
		ErrorDescription = NewErrorDescription();
		ErrorDescription.Code = ErrorCodeCalculationLooping();
		ErrorDescription.Stage = Stage;
		WriteError(ProductionOrder, KeyLot, ErrorDescription);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Tính toán lịch sản xuất theo định mức';
				|ru = 'Расчет нормативного графика производства';
				|en = 'Standard production schedule calculation'; fa = 'Standard production schedule calculation';
				|it = 'Standard production schedule calculation';
				|pl = 'Standard production schedule calculation';
				|tr = 'Standart üretim çizelgesinin hesaplanması'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.InformationRegisters.TargetOrderStructureSchedule,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise;
	EndTry;
	
EndProcedure

Procedure WriteError(ProductionOrder, ErrorID, ErrorDescription)
	
	Errors = New ValueTable();
	Errors.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	Errors.Columns.Add("ErrorID", New TypeDescription("UUID"));
	Errors.Columns.Add("Protocol", New TypeDescription("ValueStorage"));
	
	Error = Errors.Add();
	Error.ProductionOrder = ProductionOrder;
	Error.ErrorID = ErrorID;
	Error.Protocol = New ValueStorage(ErrorDescription);
	
	ErrorsStructure = New Structure;
	ErrorsStructure.Insert("Errors", Errors);
	ErrorsStructure.Insert("ErrorType",
		Enums.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError);
	
	InformationRegisters.OrderStructureCalculationProtocol.RegisterErrors(ErrorsStructure);
	
EndProcedure

Procedure HandleErrorUBBIntervalWasNotFound(ClockCycleParameters, ResultOfCycle, Stage, StartOfPlacement)
	
	If Stage.ErrorCounter = ErrorLimit() Then
		
		ErrorDescription = NewErrorDescription();
		If Stage.ItIsTransfer Then
			ErrorDescription.Code = ErrorCodeNotFoundMainScheduleInterval();
		Else
			ErrorDescription.Code = ErrorCodeNotFoundDivisionInterval();
			ErrorDescription.Department = Stage.Department;
		EndIf;
		ErrorDescription.Date = StartOfPlacement;
		ErrorDescription.GoBackToBeginning = ClockCycleParameters.GoBackToBeginning;
		
		WriteError(ClockCycleParameters.ProductionOrder, Stage.KeyLot, ErrorDescription);
		
		ResultOfCycle.Cancel = True;
		
	Else
		Stage.ErrorCounter = Stage.ErrorCounter + 1;
	EndIf;
	
EndProcedure

Procedure HandleErrorBBBIntervalNotFound(ClockCycleParameters, ResultOfCycle, Stage, Performer, StartOfPlacement)
	
	If Stage.ErrorCounter = ErrorLimit() Then
		
		ErrorDescription = NewErrorDescription();
		ErrorDescription.Code = ErrorCodeNotFoundBBBInterval();
		ErrorDescription.WorkCenterType = Performer.WorkCenterType;
		ErrorDescription.Date = StartOfPlacement;
		ErrorDescription.GoBackToBeginning = ClockCycleParameters.GoBackToBeginning; 
		
		WriteError(ClockCycleParameters.ProductionOrder, Stage.KeyLot, ErrorDescription);
		
		ResultOfCycle.Cancel = True;
		
	Else
		Stage.ErrorCounter = Stage.ErrorCounter + 1;
	EndIf;
	
EndProcedure

Procedure HandleErrorIntervalsDoNotIntersect(ClockCycleParameters, ResultOfCycle, Stage)
	
	If Stage.ErrorCounter = ErrorLimit() Then
		
		ErrorDescription = NewErrorDescription();
		ErrorDescription.Code = ErrorCodeIntervalsDoNotIntersect();
		ErrorDescription.Stage = Stage.Stage;
		
		WriteError(ClockCycleParameters.ProductionOrder, Stage.KeyLot, ErrorDescription);
		
		ResultOfCycle.Cancel = True;
		
	Else
		Stage.ErrorCounter = Stage.ErrorCounter + 1;
	EndIf;
	
EndProcedure

Procedure HandleErrorZeroLoadingTimeOfVRC(ClockCycleParameters, ResultOfCycle, Stage, Performer)
	
	If Performer.ConsiderAvailability
		And Performer.NumberOfWorkCenters = 0 Then
		
		ErrorDescription = NewErrorDescription();
		ErrorDescription.Code = ErrorCodeZeroVRCLoadingTime();
		ErrorDescription.WorkCenterType = Performer.WorkCenterType;
		
		WriteError(ClockCycleParameters.ProductionOrder, Stage.KeyLot, ErrorDescription);
		
		ResultOfCycle.Cancel = True;
		
	EndIf;
	
EndProcedure

Function ErrorCodeNotFoundDivisionInterval()
	
	Return 1;
	
EndFunction

Function ErrorCodeNotFoundBBBInterval()
	
	Return 2;
	
EndFunction

Function ErrorCodeIntervalsDoNotIntersect()
	
	Return 3;
	
EndFunction

Function ErrorCodeZeroVRCLoadingTime()
	
	Return 4;
	
EndFunction

// Planning error code - the interval of the main schedule was not found.
// 
// Returns:
//  Number - error code
Function ErrorCodeNotFoundMainScheduleInterval() Export
	
	Return 5;
	
EndFunction

Function ErrorCodeCalculationLooping()
	
	Return 6;
	
EndFunction

Function ErrorCodeDateOfNeedNotFilledIn()
	
	Return 7;
	
EndFunction

Function ErrorLimit()
	Return 11;
EndFunction

Function NewErrorDescription()
	
	Result = New Structure;
	
	Result.Insert("Code", 0);
	Result.Insert("Department", Undefined);
	Result.Insert("WorkCenterType", Undefined);
	Result.Insert("Stage", Undefined);
	Result.Insert("Date", '00010101');
	Result.Insert("GoBackToBeginning", Undefined);
	
	Return Result;
	
EndFunction

Procedure OutputErrorLog(Parameters, StorageAddress) Export
	
	DataSets = New Structure("ErrorLog", ErrorLog(Parameters.OrderDocument));

	DataCompositionSchema = InformationRegisters.TargetOrderStructureSchedule.GetTemplate("ErrorLog");
	
	DetailsData = New DataCompositionDetailsData;
	
	DataCompositionSettings = DataCompositionSchema.SettingVariants.Find("Main").Settings; // DataCompositionSettings
	TemplateComposer = New DataCompositionTemplateComposer;
	
	LayoutTemplateParameter = DataCompositionSettings.OutputParameters.Items.Find("AppearanceTemplate");
	LayoutTemplateParameter.Value = "ReportingBeige";
	LayoutTemplateParameter.Use = True;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		DataCompositionSettings,
		DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	
	CompositionProcessor.Initialize(
		CompositionTemplate,
		DataSets,
		DetailsData,
		True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(SpreadsheetDocument);
	OutputProcessor.Output(CompositionProcessor, True);
	
	Result = New Structure();
	
	Result.Insert("SpreadsheetDocument", SpreadsheetDocument);
	Result.Insert("DataCompositionSchema", DataCompositionSchema);
	Result.Insert("DetailsData", DetailsData);

	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function ErrorLog(OrderDocument)
	
	Result = New ValueTable();
	Result.Columns.Add("MessageText", New TypeDescription("String"));
	Result.Columns.Add("Details",
		New TypeDescription(
			"CatalogRef.BusinessStructure,
			|CatalogRef.Calendars,
			|CatalogRef.WorkCenterTypes,
			|CatalogRef.ProductionStages,
			|DocumentRef.ProductionStage2_2,
			|DocumentRef.ProductionOrder2_2"));
	
	Query = New Query(
		"SELECT
		|	Errors.Protocol AS ErrorDescription
		|FROM
		|	InformationRegister.OrderStructureCalculationProtocol AS Errors
		|WHERE
		|	Errors.ProductionOrder = &ProductionOrder
		|	AND Errors.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError)");
	Query.SetParameter("ProductionOrder", OrderDocument);
	Selection = Query.Execute().Select();
	
	Errors = New Array;
	Departments = New Array;
	WorkCenterTypes = New Array;
	
	While Selection.Next() Do
		DescriptionOfStorageError = Selection.ErrorDescription; // ValueStorage
		ErrorDescription = DescriptionOfStorageError.Get();
		Errors.Add(ErrorDescription);
		
		If ErrorDescription.Code = ErrorCodeNotFoundDivisionInterval() Then
			Departments.Add(ErrorDescription.Department);
		ElsIf ErrorDescription.Code = ErrorCodeNotFoundBBBInterval() Then
			WorkCenterTypes.Add(ErrorDescription.WorkCenterType);
		EndIf;
	EndDo;
	
	Query.Text =
		"SELECT
		|	BusinessStructure.Ref                                           AS Ref,
		|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS Schedule,
		|	ISNULL(Schedules.WorkScheduleCalendar.Description,
		|		MainEnterpriseCalendar.Value.Description)               AS SchedulePresentation
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|
		|	LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|	ON BusinessStructure.Ref = Schedules.Ref
		|
		|	LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|	ON (TRUE)
		|WHERE
		|	BusinessStructure.Ref IN (&Departments)
		|
		|ORDER BY
		|	ISNULL(Schedules.LineNumber, 0)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	WorkCenterTypes.Ref AS Ref,
		|	CASE
		|		WHEN WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|			THEN ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value)
		|		ELSE WorkCenterTypes.Calendar
		|	END                     AS Schedule,
		|	CASE
		|		WHEN WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|			THEN ISNULL(Schedules.WorkScheduleCalendar.Description, MainEnterpriseCalendar.Value.Description)
		|		ELSE WorkCenterTypes.Calendar.Description
		|	END                     AS SchedulePresentation
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|
		|	LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|	ON WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|		AND WorkCenterTypes.Department = Schedules.Ref
		|
		|	LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|	ON WorkCenterTypes.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|WHERE
		|	WorkCenterTypes.Ref IN (&WorkCenterTypes)";
	Query.SetParameter("Departments", Departments);
	Query.SetParameter("WorkCenterTypes", WorkCenterTypes);
	
	QueryResults = Query.ExecuteBatch();
	
	DivisionsSchedules = QueryResults[0].Unload();
	DivisionsSchedules.Indexes.Add("Ref");
	
	GraphsOfTypesOfRC = QueryResults[1].Unload();
	GraphsOfTypesOfRC.Indexes.Add("Ref");
	
	For Each ErrorDescription In Errors Do
		
		If ErrorDescription.Code = ErrorCodeNotFoundDivisionInterval() Then
			
			NewRow = Result.Add();
			
			LineOfGraphics = DivisionsSchedules.Find(ErrorDescription.Department, "Ref");
			
			If LineOfGraphics = Undefined Or Not ValueIsFilled(LineOfGraphics.Schedule) Then
				Template = NStr("vi = 'Lịch làm việc của bộ phận ""%1"" chưa được xác định';
								|ru = 'Не определен график работы подразделения ""%1"".';
								|en = 'The ""%1"" business unit schedule is not specified.'; fa = 'The ""%1"" business unit schedule is not specified.';
								|it = 'The ""%1"" business unit schedule is not specified.';
								|pl = 'The ""%1"" business unit schedule is not specified.';
								|tr = '""%1"" departmanının çalışma takvimi tanımlı değil.'");
				
				NewRow.MessageText = StrTemplate(Template, ErrorDescription.Department);
				NewRow.Details = ErrorDescription.Department;
			Else
				Template = ?(ErrorDescription.GoBackToBeginning,
					NStr("vi = 'Lịch làm việc của bộ phận ""%1"" sau %2 (lịch ""%3"") chưa được điền.';
						|ru = 'Не заполнен график работы подразделения ""%1"" после %2 (график ""%3"").';
						|en = 'The ""%1"" business unit schedule is not filled in after %2 (the ""%3"" schedule).'; fa = 'The ""%1"" business unit schedule is not filled in after %2 (the ""%3"" schedule).';
						|it = 'The ""%1"" business unit schedule is not filled in after %2 (the ""%3"" schedule).';
						|pl = 'The ""%1"" business unit schedule is not filled in after %2 (the ""%3"" schedule).';
						|tr = '""%1"" departmanının çalışma takvimi %2 sonrasında doldurulmadı (takvim ""%3"").'"),
					NStr("vi = 'Lịch làm việc của bộ phận ""%1"" trước %2 (lịch ""%3"") chưa được điền.';
						|ru = 'Не заполнен график работы подразделения ""%1"" ранее %2 (график ""%3"").';
						|en = 'The ""%1"" business unit schedule is not filled in before %2 (the ""%3"" schedule).'; fa = 'The ""%1"" business unit schedule is not filled in before %2 (the ""%3"" schedule).';
						|it = 'The ""%1"" business unit schedule is not filled in before %2 (the ""%3"" schedule).';
						|pl = 'The ""%1"" business unit schedule is not filled in before %2 (the ""%3"" schedule).';
						|tr = '""%1"" departmanının çalışma takvimi %2 öncesinde doldurulmadı (takvim ""%3"").'"));
				
				NewRow.MessageText = StrTemplate(
					Template,
					ErrorDescription.Department,
					Format(ErrorDescription.Date, "DLF=D"),
					LineOfGraphics.SchedulePresentation);
				NewRow.Details = LineOfGraphics.Schedule;
			EndIf;
		
		ElsIf ErrorDescription.Code = ErrorCodeNotFoundMainScheduleInterval() Then
			
			Template = ?(ErrorDescription.GoBackToBeginning,
				NStr("vi = 'Chưa xác định lịch làm việc chính của doanh nghiệp hoặc chưa điền dữ liệu lịch biểu sau %1.';
					|ru = 'Не определен основной график работы предприятия или данные графика не заполнены после %1.';
					|en = 'The main enterprise work schedule is not determined or the schedule data is not filled after %1.'; fa = 'The main enterprise work schedule is not determined or the schedule data is not filled after %1.';
					|it = 'Il grafico di lavoro principale dell''impresa non è definito o i dati del grafico non sono compilati dopo %1.';
					|pl = 'Nie jest określony podstawowy harmonogram pracy przedsiębiorstwa lub dane harmonogramu nie są wypełnione po %1.';
					|tr = 'İşletmenin temel çalışma takvimi tanımlanmadı veya %1 sonrasında takvim verileri doldurulmadı.'"),
				NStr("vi = 'Chưa xác định lịch biểu làm việc chính của doanh nghiệp hoặc chưa điền dữ liệu lịch biểu trước %1.';
					|ru = 'Не определен основной график работы предприятия или данные графика не заполнены ранее %1.';
					|en = 'The main enterprise work schedule is not determined or the schedule data is not filled before %1.'; fa = 'The main enterprise work schedule is not determined or the schedule data is not filled before %1.';
					|it = 'Il grafico di lavoro principale dell''impresa non è definito o i dati del grafico non sono compilati prima %1.';
					|pl = 'Nie jest określony podstawowy harmonogram pracy przedsiębiorstwa lub dane harmonogramu nie są wypełnione przed %1.';
					|tr = 'İşletmenin temel çalışma takvimi tanımlanmadı veya %1 öncesinde takvim verileri doldurulmadı.'"));
				
			NewRow = Result.Add();
			NewRow.MessageText = StrTemplate(
				Template,
				Format(ErrorDescription.Date, "DLF=D"));
			NewRow.Details = Constants.MainEnterpriseCalendar.Get();
			
		ElsIf ErrorDescription.Code = ErrorCodeNotFoundBBBInterval() Then
			
			NewRow = Result.Add();
			
			LineOfGraphics = GraphsOfTypesOfRC.Find(ErrorDescription.WorkCenterType, "Ref");
			
			If LineOfGraphics = Undefined Or Not ValueIsFilled(LineOfGraphics.Schedule) Then
				Template = NStr("vi = 'Lịch làm việc của loại trung tâm phân phối ""%1"" chưa được xác định.';
								|ru = 'Не определен график работы вида РЦ ""%1"".';
								|en = 'The ""%1"" work center type schedule is not specified.'; fa = 'The ""%1"" work center type schedule is not specified.';
								|it = 'The ""%1"" work center type schedule is not specified.';
								|pl = 'The ""%1"" work center type schedule is not specified.';
								|tr = '""%1"" İM çalışma takvimi tanımlı değil.'");
				
				NewRow.MessageText = StrTemplate(Template, ErrorDescription.WorkCenterType);
				NewRow.Details = ErrorDescription.WorkCenterType;
			Else
				Template = ?(ErrorDescription.GoBackToBeginning,
					NStr("vi = 'Lịch làm việc của loại trung tâm phân phối ""%1"" sau %2 (lịch ""%3"") chưa được điền.';
						|ru = 'Не заполнен график работы вида РЦ ""%1"" после %2 (график ""%3"").';
						|en = 'The ""%1"" work center type schedule is not filled in after %2 (the ""%3"" schedule).'; fa = 'The ""%1"" work center type schedule is not filled in after %2 (the ""%3"" schedule).';
						|it = 'The ""%1"" work center type schedule is not filled in after %2 (the ""%3"" schedule).';
						|pl = 'The ""%1"" work center type schedule is not filled in after %2 (the ""%3"" schedule).';
						|tr = '""%1"" İM çalışma takvimi %2 sonrasında doldurulmadı (çalışma takvimi ""%3"").'"),
					NStr("vi = 'Lịch làm việc của loại trung tâm phân phối ""%1"" trước %2 (lịch ""%3"") chưa được điền.';
						|ru = 'Не заполнен график работы вида РЦ ""%1"" ранее %2 (график ""%3"").';
						|en = 'The ""%1"" work center type schedule is not filled in before %2 (the ""%3"" schedule).'; fa = 'The ""%1"" work center type schedule is not filled in before %2 (the ""%3"" schedule).';
						|it = 'The ""%1"" work center type schedule is not filled in before %2 (the ""%3"" schedule).';
						|pl = 'The ""%1"" work center type schedule is not filled in before %2 (the ""%3"" schedule).';
						|tr = '""%1"" İM çalışma takvimi %2 öncesinde doldurulmadı (çalışma takvimi ""%3"").'"));
			
				NewRow.MessageText = StrTemplate(
					Template,
					ErrorDescription.WorkCenterType,
					Format(ErrorDescription.Date, "DLF=D"),
					LineOfGraphics.SchedulePresentation);
				NewRow.Details = LineOfGraphics.Schedule;
			EndIf;
			
		ElsIf ErrorDescription.Code = ErrorCodeIntervalsDoNotIntersect() Then
			
			BillOfMaterialsPresentation = ?(TypeOf(ErrorDescription.Stage) = Type("CatalogRef.ProductionStages"),
				Common.ObjectAttributeValue(ErrorDescription.Stage, "Owner.Presentation"),
				Common.ObjectAttributeValue(ErrorDescription.Stage, "BillOfMaterials.Presentation"));
			
			NewRow = Result.Add();
			NewRow.MessageText = StrTemplate(
				NStr("vi = 'Khoảng thời gian làm việc của dạng nguồn lực sản xuất trong công đoạn ""%1"" (bảng kê chi tiết ""%2"") không giao nhau.';
					|ru = 'Интервалы работы видов РЦ этапа ""%1"" (спецификация ""%2"") не пересекаются.';
					|en = 'The intervals of operations of the work center types of the ""%1"" stage (the ""%2"" bill of materials) do not overlap.'; fa = 'The intervals of operations of the work center types of the ""%1"" stage (the ""%2"" bill of materials) do not overlap.';
					|it = 'Gli intervalli di lavoro del tipo CL della fase ""%1"" (specifica ""%2"") non coincidono.';
					|pl = 'Interwały pracy rodzajów gniazd produkcyjnych etapu ""%1"" (specyfikacja ""%2"") nie przecinają się.';
					|tr = '""%1"" aşamasının İM türlerinin çalışma aralıkları (""%2"" ürün reçetesi) çakışmamaktadır.'"),
				ErrorDescription.Stage,
				BillOfMaterialsPresentation);
			NewRow.Details = ErrorDescription.Stage;
			
		ElsIf ErrorDescription.Code = ErrorCodeZeroVRCLoadingTime() Then
			
			NewRow = Result.Add();
			NewRow.MessageText = StrTemplate(
				NStr("vi = 'Đối với dạng nguồn lực sản xuất ""%1"" chưa đặt nguồn lực sản xuất (số lượng nguồn lực sản xuất).';
					|ru = 'Для вида РЦ ""%1"" не заданы рабочие центры (количество рабочих центров).';
					|en = 'Work centers (number of work centers) are not specified for the ""%1"" work center type.'; fa = 'Work centers (number of work centers) are not specified for the ""%1"" work center type.';
					|it = 'Per il tipo CL ""%1"" non sono indicati i centri di lavoro (quantità di centri di lavoro).';
					|pl = 'Dla rodzaju gniazda produkcyjnego ""%1"" nie są określone gniazda produkcyjne (ilość gniazd produkcyjnych).';
					|tr = '""%1"" İM türü için iş merkezleri belirtilmedi (iş merkezlerinin miktarı).'"),
				ErrorDescription.WorkCenterType);
			NewRow.Details = ErrorDescription.WorkCenterType;
			
		ElsIf ErrorDescription.Code = ErrorCodeCalculationLooping() Then
			
			NewRow = Result.Add();
			If ValueIsFilled(ErrorDescription.Stage) Then
				BillOfMaterialsPresentation = ?(TypeOf(ErrorDescription.Stage) = Type("CatalogRef.ProductionStages"),
					Common.ObjectAttributeValue(ErrorDescription.Stage, "Owner.Presentation"),
					Common.ObjectAttributeValue(ErrorDescription.Stage, "BillOfMaterials.Presentation"));
				NewRow.MessageText = StrTemplate(
					NStr("vi = 'Trong quá trình tính toán lịch biểu tiêu chuẩn đã diễn ra vòng lặp thủ tục xử lý dữ liệu (bảng kê chi tiết ""%1""). Ngừng thực hiện.';
						|ru = 'В процессе расчета нормативного графика произошло зацикливание процедуры обработки данных (спецификация ""%1""). Выполнение прервано.';
						|en = 'The looping of the data processing procedure occurred during the standard schedule calculation (the ""%1"" bill of materials). Execution terminated.'; fa = 'The looping of the data processing procedure occurred during the standard schedule calculation (the ""%1"" bill of materials). Execution terminated.';
						|it = 'Nel processo di calcolo del grafico normativo si è verificata una ciclicità delle procedure di elaborazione dei dati (specifica ""%1""). Esecuzione interrotta.';
						|pl = 'W trakcie obliczenia harmonogramu normatywnego wystąpiło zapętlenie procedury przetwarzania danych (specyfikacja ""%1""). Wykonanie zostało przerwane.';
						|tr = 'Standart programın hesaplanması sürecinde, veri işleme prosedürü döngüsel olarak yürütüldü (%1"" ürün reçetesi). Gerçekleştirme durduruldu.'"),
					BillOfMaterialsPresentation);
			Else
				NewRow.MessageText = 
					NStr("vi = 'Trong quá trình tính toán lịch biểu tiêu chuẩn đã diễn ra vòng lặp thủ tục xử lý dữ liệu. Ngừng thực hiện.';
						|ru = 'В процессе расчета нормативного графика произошло зацикливание процедуры обработки данных. Выполнение прервано.';
						|en = 'The looping of the data processing procedure occurred during the calculation of the standard schedule. Execution is terminated.'; fa = 'The looping of the data processing procedure occurred during the calculation of the standard schedule. Execution is terminated.';
						|it = 'Nel processo di calcolo del grafico normativo si è verificata una ciclicità della procedura di elaborazione dati. Esecuzione interrotta';
						|pl = 'W trakcie obliczenia harmonogramu normatywnego wystąpiło zapętlenie procedury przetwarzania danych. Wykonanie zostało przerwane.';
						|tr = 'Standart programın hesaplanması sürecinde, veri işleme prosedürü döngüsel olarak yürütüldü. Gerçekleştirme durduruldu.'");
			EndIf;
			
		ElsIf ErrorDescription.Code = ErrorCodeDateOfNeedNotFilledIn() Then
			
			NewRow = Result.Add();
			NewRow.MessageText = NStr("vi = 'В заказе не заполнена желаемая дата выпуска.';
										|ru = 'В заказе не заполнена желаемая дата выпуска.';
										|en = 'The requested release date is not filled in the order.'; fa = 'The requested release date is not filled in the order.';
										|it = 'В заказе не заполнена желаемая дата выпуска.';
										|pl = 'The requested release date is not filled in the order.';
										|tr = 'Emirde talep edilen bitiş tarihi doldurulmadı.'");
			NewRow.Details = OrderDocument;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ClearErrorLog(ProductionOrder)
	
	Query = New Query(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.OrderStructureCalculationProtocol AS OrderStructureCalculationProtocol
		|WHERE
		|	OrderStructureCalculationProtocol.ProductionOrder = &ProductionOrder
		|	AND OrderStructureCalculationProtocol.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError)");
	Query.SetParameter("ProductionOrder", ProductionOrder);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Set = InformationRegisters.OrderStructureCalculationProtocol.CreateRecordSet();
		Set.Filter.ProductionOrder.Set(ProductionOrder);
		Set.Filter.ErrorType.Set(
			Enums.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError);
		Set.Write();
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function LeadToBeginningOfPeriod(Date, Interval)
	
	If Interval = Enums.ProductionScheduleAccuracy.Day Then
		Return BegOfDay(Date);
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Week Then
		Return BegOfWeek(Date);
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Month Then
		Return BegOfMonth(Date);
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Hour Then
		Return BegOfHour(Date);
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Shift Then
		Return Date;
	EndIf;
	
EndFunction

Function LeadToEndOfPeriod(Date, Interval)
	
	If Interval = Enums.ProductionScheduleAccuracy.Day Then
		Return EndOfDay(Date) + 1;
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Week Then
		Return EndOfWeek(Date) + 1;
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Month Then
		Return EndOfMonth(Date) + 1;
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Hour Then
		Return EndOfHour(Date) + 1;
	ElsIf Interval = Enums.ProductionScheduleAccuracy.Shift Then
		Return Date;
	EndIf;
	
EndFunction

Function TimeInSeconds_(Time)
	
	Return Hour(Time)*3600 + Minute(Time)*60 + Second(Time);
	
EndFunction

Function NodeTypeBatchOfStages()
	Return 1;
EndFunction

Function NodeViewMoving()
	Return 2;
EndFunction

Function TypeOfNodeBatchStructure()
	Return 3;
EndFunction

// Function for redefining behavior
Function UseBuffer()
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
