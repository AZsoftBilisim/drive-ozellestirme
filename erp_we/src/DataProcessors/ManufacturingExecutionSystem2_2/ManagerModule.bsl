#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Performs the calculation of operational schedules of production.
//
// Parameters:
//  CalculationParameters - See ParametersForCalculatingOperationalSchedule
//  StorageAddress - UUID, String - the address in the temporary storage where
//                                                     the results of the schedule calculation should be placed.
//
Procedure CalculateASchedule(CalculationParameters, StorageAddress) Export
	
	KeyOperation = "ManufacturingExecutionSystem.FormationOfPostoperativeSchedule";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	
	CalculationResults = CalculateScheduleInsideTimeMeasurement(CalculationParameters);
	PutToTempStorage(CalculationResults, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, CalculationResults.DataVolume);
	
EndProcedure

// Calculates the operational schedule according to the parameters of a specific planning model.
//
// Parameters:
//  PlanningParameters - See InitializePlanningParameters
//  StorageAddress - UUID - address of the temporary storage where the result of the method will be placed.
//
Procedure CalculateModelScheduleInBackground(PlanningParameters, StorageAddress) Export
	
	CalculateModelSchedule(PlanningParameters);
	
	If IsTempStorageURL(StorageAddress) Then
		PutToTempStorage(BackgroundCalculationResults(PlanningParameters), StorageAddress);
	EndIf;
	
EndProcedure

// The constructor function calculation parameters of the schedule. The calculation parameters contain all the initial
//	 and intermediate information used in the calculation of the schedule, as well as the calculation results.
// 
// Returns:
// 	Structure - schedule calculation parameters:
// * CurrentUser - CatalogRef.Users -
// * SessionNumber - Number -
// * SessionStarted - Date -
// * ProductionStages - ValueList -
// * References - ValueList -
// * Department - CatalogRef.BusinessStructure -
// * OperationalCalculation - Boolean -
// * StandardTimeToRegisterOperationExecution - Number -
// * PlanningModels - ValueTable -
// * PlanningHorizon - Number -
// * PlanningTimepoint - Date -
Function ParametersForCalculatingOperationalSchedule() Export
	
	Result = New Structure;
	Result.Insert("PlanningTimepoint", '00010101');
	Result.Insert("PlanningHorizon", 0);
	Result.Insert("PlanningModels", New ValueTable);
	Result.Insert("StandardTimeToRegisterOperationExecution", 0);
	Result.Insert("OperationalCalculation", False);
	
	Result.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	Result.Insert("References", New ValueList);
	Result.Insert("ProductionStages", New ValueList);
	
	Result.Insert("SessionStarted", '00010101');
	Result.Insert("SessionNumber", 0);
	Result.Insert("CurrentUser", Users.CurrentUser());
	
	Return Result;
	
EndFunction

// Initiates recording the calculated operational schedule in the database.
//
// Parameters:
//  JobParameters - Structure - contains Attributes identifying the set of operations
//		that make up the recorded schedule. Elements of the structure:
//		* TimetableModel - UUID - key of the calculated and recorded schedule.
//		* PlanningModel - CatalogRef.MESModels - the schedule model
//			to record data for.
//  StorageAddress - UUID - address of the temporary storage where the result of the method will be placed.
//
Procedure RecordScheduleInBackground(Val JobParameters, StorageAddress) Export
	
	TimetableModel = JobParameters.TimetableModel;
	PlanningModel = JobParameters.PlanningModel;
	
	WritingCompleted = False;
	InformationRegisters.PostOperativeSchedule2_2.RecordASchedule(TimetableModel, PlanningModel, WritingCompleted);
	PutToTempStorage(WritingCompleted, StorageAddress);
	
EndProcedure

// Calculates the operational schedule according to the parameters of the planning models.
//		it is based on the procedure for calculating the description of the model in the background Mode.
//
// Parameters:
//  PlanningParameters - See InitializePlanningParameters
//	CalculationResults - Array - contains unique identifiers - addresses of temporary stores
//		where the result of the method will be placed.
//
Procedure CalculateScheduleOfModelsInBackground(PlanningParameters, CalculationResults) Export

	NumberOfRepositories = CalculationResults.Count();
	StorageIndex = 0;
	For Each PlanningModel In PlanningParameters.ParametersOfPlanningModels Do
		
		FillInPlanningParametersBasedOnPlanningModelData(PlanningParameters, PlanningModel);
		
		CalculateModelSchedule(PlanningParameters);
		
		If StorageIndex < NumberOfRepositories And IsTempStorageURL(CalculationResults[StorageIndex]) Then
			PutToTempStorage(BackgroundCalculationResults(PlanningParameters), CalculationResults[StorageIndex]);
		EndIf;
		
		StorageIndex = StorageIndex + 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function CalculateScheduleInsideTimeMeasurement(CalculationParameters)
	
	PlanningParameters = InitializePlanningParameters();
	FillPropertyValues(PlanningParameters, CalculationParameters);
	
	Cancel = False;
	FillInPlanningParameters(PlanningParameters, Cancel);
	
	If Not Cancel Then
		
		CalculateScheduleSchedulingModels(PlanningParameters);
		
	EndIf;
	
	FillInCalculationResults(PlanningParameters);
	
	Return PlanningParameters.CalculationResults;
	
EndFunction

#Region PlanningStages_

Procedure CalculateScheduleSchedulingModels(PlanningParameters)
	
	FileSystem_ = Common.FileInfobase();
	MultipleModels = (PlanningParameters.ParametersOfPlanningModels.Count()>1);
	CalculationInBackground_ = Not FileSystem_ And MultipleModels;
	
	If CalculationInBackground_ Then
		
		CalculationResults = New Array;
		JobMethodName = "ProductionManagementWhenPlanningServer.CalculateScheduleOfModelsInBackground";
		JobDescription = NStr("vi = 'Lịch trình tính toán theo mô hình lập kế hoạch';
								|ru = 'Расчет расписания по моделям планирования';
								|en = 'Timetable calculation by planning models'; fa = 'Timetable calculation by planning models';
								|it = 'Calcolo dell''orario per modelli di pianificazione';
								|pl = 'Obliczanie harmonogramu według modeli planowania';
								|tr = 'Planlama modellerine göre çizelgenin hesaplanması'");
		For Each PlanningModel In PlanningParameters.ParametersOfPlanningModels Do
			
			StorageAddress = PutToTempStorage(Undefined);
			CalculationResults.Add(StorageAddress);
			
		EndDo;
		
		MethodParameters = New Array;
		MethodParameters.Add(PlanningParameters);
		MethodParameters.Add(CalculationResults);
		
		Job = BackgroundJobs.Execute(JobMethodName, MethodParameters,, JobDescription);	
		
		WaitForBackgroundJobsToComplete(JobMethodName, JobDescription);
		ReadResultsOfBackgroundCalculation(PlanningParameters, CalculationResults);
		
	Else
		
		If MultipleModels Then
			RefillableParameters = RefillablePlanningParameters(PlanningParameters);
		Else
			RefillableParameters = Undefined;
		EndIf;
		ReFillParameters = False;
		
		For Each PlanningModel In PlanningParameters.ParametersOfPlanningModels Do
			
			If ReFillParameters Then
				ReFillSchedulingSettings(PlanningParameters, RefillableParameters);
			Else
				ReFillParameters = True;
			EndIf;
			
			FillInPlanningParametersBasedOnPlanningModelData(PlanningParameters, PlanningModel);
			
			CalculateModelSchedule(PlanningParameters);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CalculateModelSchedule(PlanningParameters)
	
	HandlePreviousUnavailableExceptionOperations(PlanningParameters);
	PlaceFixedBatchesOfOperations(PlanningParameters);
	
	For Each Priority In PlanningParameters.StagePriorities Do
		
		CalculateScheduleOfBatchOfStages(PlanningParameters, Priority);
		
	EndDo;
	
	RecordModelCalculationResults(PlanningParameters);
	
EndProcedure

Procedure CalculateScheduleOfBatchOfStages(PlanningParameters, Val StagePriority)
	
	While True Do
		
		OperationsProcessed = False;
		
		For Each Rank In PlanningParameters.RanksOfWorkCenters Do
			
			Operations = PlanningCycleOperations(PlanningParameters, Rank.WorkCenterType, StagePriority);
			
			If ValueIsFilled(Operations) Then
				
				PerformOperationPlanningCycle(PlanningParameters, Operations, Rank.WorkCenterType);
				
				OperationsProcessed = True;
				Break;
				
			Else
				Continue;
			EndIf;
			
		EndDo;
		
		If Not OperationsProcessed Then
			Break;
		EndIf;
		
	EndDo;
	
	MoveInteropTransitionsToSchedule(PlanningParameters);
	
EndProcedure

Procedure PerformOperationPlanningCycle(PlanningParameters, Operations, Val WorkCenterType)
	
	ScheduleOptions_ = InitializeScheduleOptions(PlanningParameters, Operations);
	
	For Each ScheduleOption1_ In ScheduleOptions_ Do
		
		PerformSchedulingOfScheduleOption(PlanningParameters, ScheduleOption1_, WorkCenterType);
		
	EndDo;
	
	BestOption = BestScheduleOption(PlanningParameters, ScheduleOptions_);
	SaveScheduleOption(PlanningParameters, BestOption);
	
EndProcedure

Procedure PerformSchedulingOfScheduleOption(PlanningParameters, ScheduleOption1_, Val WorkCenterType)
	
	DuplicatePlanningParameters(PlanningParameters, ScheduleOption1_.Operations, WorkCenterType);
	
	CheckFixedBatchNumbers = PlanningParameters.BatchNumbersOfOperations.Count() > 0;
	
	For Each Operation In ScheduleOption1_.Operations Do
		
		UnitTimeInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(Operation.TimePerPiece, Operation.TimePerPieceUnitOfMeasure);
		TimeInSeconds_1 = ProductionPlanningClientServer.GetTimeInSeconds(Operation.SetupTime, Operation.SetupTimeUnitOfMeasure);
		
		LotNumber = 0;
		UnplacedFixedBatches = New Array;
		If CheckFixedBatchNumbers Then
			TheStructureOfTheSearch = New Structure("Stage, Operation, OperationID");
			FillPropertyValues(TheStructureOfTheSearch, Operation);
			FoundRows = PlanningParameters.BatchNumbersOfOperations.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() > 0 Then
				LotNumber = FoundRows[0].LotNumber;
				Operation.NumberOfPages_1 = Operation.NumberOfPages_1 - FoundRows[0].QuantityDoNotPlace;
			EndIf;
			
			UnplacedFixedBatches = PlanningParameters.UnplacedFixedBatches.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		If Operation.NumberOfPages_1 = 0 Then 
			Operation.Posted_1 = True;
			ChildOperations = RelatedOperations(PlanningParameters, Operation.Stage, Operation.OperationID, True, True);
			For Each ChildOperation In ChildOperations Do
				ChildOperation.DependsOnPreceding = False;
			EndDo;
			Continue;
		EndIf;
		
		If Operation.BatchSize = 0 Then
			BatchSize = Operation.TransferLot;
		ElsIf Operation.TransferLot = 0 Then
			BatchSize = Operation.BatchSize;
		Else
			BatchSize = Min(Operation.TransferLot, Operation.BatchSize);
		EndIf;
		If BatchSize = 0 Then 
			QuantityOfBatches = 1;
		Else
			QuantityOfBatches = Operation.NumberOfPages_1 / (BatchSize * Operation.ZoomRatio);
			If QuantityOfBatches > Int(QuantityOfBatches) Then
				QuantityOfBatches = Int(QuantityOfBatches) + 1;
			EndIf;
		EndIf;
		
		IndexOfFixed = 0;
		While Operation.NumberOfPages_1 > 0 Do
			
			BatchOperation_ = InitializeBatchOperations();
			FillPropertyValues(BatchOperation_, Operation,, "Count, TimeToPlace");
			
			If UnplacedFixedBatches.Count() = 0 
				Or IndexOfFixed = UnplacedFixedBatches.Count() Then
				LotNumber = LotNumber + 1;
				BatchOperation_.LotNumber = LotNumber;
				If QuantityOfBatches = 1 Then 
					BatchOperation_.Count = Operation.NumberOfPages_1;
					Operation.BatchSize = 0;
				Else
					BatchOperation_.TransferLot = Operation.TransferLot;
					BatchOperation_.Count = Min(BatchSize * Operation.ZoomRatio, Operation.NumberOfPages_1);
				EndIf;
			Else
				FixedBatch = UnplacedFixedBatches[IndexOfFixed];
				IndexOfFixed = IndexOfFixed + 1;
				If FixedBatch.Count = 0 Then
					Continue;
				EndIf;
				BatchOperation_.LotNumber = FixedBatch.LotNumber;
				BatchOperation_.Count = FixedBatch.Count;
				BatchOperation_.CreatedOn = FixedBatch.CreatedOn;
			EndIf;
				
			If Operation.ParallelLoad Then 
				BatchOperation_.TimeToPlace = UnitTimeInSeconds;
			ElsIf UnitTimeInSeconds > 0 Then 
				BatchOperation_.TimeToPlace = BatchOperation_.Count / Operation.ZoomRatio * UnitTimeInSeconds + TimeInSeconds_1;
			Else
				BatchOperation_.TimeToPlace = 0;
			EndIf;
			BatchOperation_.PZTimeParallelLoading = TimeInSeconds_1;
			Operation.NumberOfPages_1 = Operation.NumberOfPages_1 - BatchOperation_.Count;
			BatchOperation_.OperationString = Operation;
			
			CheckDataOfPreviousBatches(Operation, BatchOperation_);
			
			PlacementParameters = CalculateOperationPlacementParameters(PlanningParameters, BatchOperation_, ScheduleOption1_.RCSelectionRule, True);
			
			NewRow = ScheduleOption1_.Schedule.Add();
			NewRow.Stage = Operation.Stage;
			NewRow.Operation = Operation;
			NewRow.BatchOperation_ = BatchOperation_;
			NewRow.OperationID = Operation.OperationID;
			NewRow.LotNumber = LotNumber;
			NewRow.PlacementParameters = PlacementParameters;
			
			If Not PlacementParameters = Undefined Then
				
				FillPropertyValues(NewRow, PlacementParameters);
				ReflectPlacementOfOperationInPlanningParameters(PlanningParameters, Operation, PlacementParameters);
				
			EndIf;
			
		EndDo;
			
	EndDo;
	
	RestoreDuplicatedSchedulingSettings(PlanningParameters);

EndProcedure

Procedure SaveScheduleOption(PlanningParameters, Val ScheduleOption1_)
	
	For Each ScheduleOperation In ScheduleOption1_.Schedule Do
		
		If ValueIsFilled(ScheduleOperation.PlacementParameters) Then
			
			PlaceOperation(PlanningParameters, ScheduleOperation.BatchOperation_, ScheduleOperation.PlacementParameters, True);
			ScheduleOperation.Operation.Posted_1 = ScheduleOperation.BatchOperation_.Posted_1;
			
		Else
			
			ProcessUnplacedOperation(PlanningParameters, ScheduleOperation.Operation, True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PlaceOperation(PlanningParameters, Val Operation, Val PlacementParameters, Val DirectPlacement)
	
	StartOfOperation = Undefined;
	OperationEnding = Undefined;
	IntervalDuration = 0;
	MaxIndex = PlacementParameters.Intervals.UBound();
	For IndexOf = 0 To MaxIndex Do
		
		PlacementInterval = PlacementParameters.Intervals[IndexOf];
		
		FillInGeneralPlacementProperties(PlanningParameters, PlacementParameters); 
		
		If IndexOf = 0 Then 
			StartOfOperation = PlacementInterval.Begin;
			OperationEnding = PlacementInterval.Ending;
		Else
			If StartOfOperation > PlacementInterval.Begin Then 
				StartOfOperation = PlacementInterval.Begin;
			EndIf;
			If OperationEnding < PlacementInterval.Ending Then 
				OperationEnding = PlacementInterval.Ending;
			EndIf;			
		EndIf;
		
		IntervalDuration = IntervalDuration + PlacementInterval.TimePlan;
		
		If IndexOf = MaxIndex Then 
			PlacementParameters.Insert("AdditionalRecord", False);
			PlacementParameters.Insert("LeftLimit", StartOfOperation);
			PlacementParameters.Insert("RightBorder_", OperationEnding);
			PlacementParameters.Insert("IntervalDuration", IntervalDuration);
		Else
			PlacementParameters.Insert("AdditionalRecord", True);
			PlacementParameters.Insert("LeftLimit", Undefined);
			PlacementParameters.Insert("RightBorder_", Undefined);
			PlacementParameters.Insert("IntervalDuration", 0);
		EndIf;
		
		If ValueIsFilled(PlacementInterval.ChangeoverTime) Then   
			IntervalChangeover = SelectChangeoverTimeFromInterval(PlacementInterval);  
			PlacementParameters.Insert("ThisIsChangeover", True);
			AddUploadRecord(PlanningParameters, Operation, PlacementParameters, IntervalChangeover);   
			
			If PlacementInterval.TimePlan > PlacementInterval.ChangeoverTime Then
				TimeInterval_ = SelectMainTimeFromInterval(PlacementInterval);                        
				PlacementParameters.Insert("ThisIsChangeover", False);
				AddUploadRecord(PlanningParameters, Operation, PlacementParameters, TimeInterval_);   
			EndIf;
		Else
			AddUploadRecord(PlanningParameters, Operation, PlacementParameters, PlacementInterval);       
		EndIf;
		                                                                                                          
		If ValueIsFilled(PlacementParameters.AuxiliaryRC) Then
			PlaceAuxiliaryOperations(PlanningParameters, Operation, PlacementParameters, PlacementInterval);  
		EndIf;
		
	EndDo;                                                                                                        
	
	If Not PlacementParameters.Property("FixedBatch") Then
		Operation.Posted_1 = True;
		Operation.OperationString.Posted_1 = True;
	EndIf;	
	
	ReflectPlacementOfOperationInPlanningParameters(PlanningParameters, Operation, PlacementParameters);
	
	If Operation.RepetitionIsRequired = 0 Then
		
		FixChildOperationsAfterPlacingParent(PlanningParameters, Operation, PlacementParameters, DirectPlacement);

	EndIf;
	
EndProcedure

Procedure HandlePreviousUnavailableExceptionOperations(PlanningParameters)
	
	If Not PlanningParameters.Property("PreviousUnavailableExceptionOperations") Then
		Return;
	EndIf;
	
	For Each PreviousLine_0 In PlanningParameters.PreviousUnavailableExceptionOperations Do
		FixChildOperationsAfterPlacingParent(PlanningParameters, PreviousLine_0, Undefined, True);		
	EndDo;
	
EndProcedure

Procedure PlaceFixedBatchesOfOperations(PlanningParameters)
	
	IntervalsOfFixedBatches = PlanningParameters.IntervalsOfFixedBatches;
	Boundaries = PlanningBoundaries(PlanningParameters);
	
	IntervalSearchStructure = New Structure("Stage, Operation, OperationID, LotNumber, WorkCenter");
	For Each BatchString In PlanningParameters.FixedBatchesOfOperations Do
		
		PartyIsJustCreated = BatchString.Running + BatchString.Completed2 + BatchString.RepetitionIsRequired + BatchString.Skipped3 = 0;
		
		If PartyIsJustCreated Then
			UnplacedBatch = PlanningParameters.UnplacedFixedBatches.Add();
			FillPropertyValues(UnplacedBatch, BatchString);
			Continue;
		EndIf;
		
		FillPropertyValues(IntervalSearchStructure, BatchString);
		IntervalSearchStructure.WorkCenter = BatchString.WorkingCenterOfProductionOperation;
		
		RowsOfIntervals = IntervalsOfFixedBatches.FindRows(IntervalSearchStructure);
		
		If BatchString.Count = (BatchString.Completed2 + BatchString.Skipped3 - BatchString.RepetitionIsRequired) Then
			
			PlaceCompletedBatchInSchedule(PlanningParameters, BatchString, RowsOfIntervals, Boundaries);
		
		ElsIf RowsOfIntervals.Count() <> 0 Then
				
			PlaceFixedBatchInSchedule(PlanningParameters, BatchString, RowsOfIntervals, Boundaries);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region PlanningParameters

// Returns:
// 	Structure - LongDesc:
// * UnplacedFixedBatches - See InitializeTableUnplacedFixedBatches
// * BatchNumbersOfOperations - ValueTable -
// * IntervalsOfFixedBatches - ValueTable - Where:
// ** Stage - DocumentRef.ProductionStage2_2 -
// ** Operation - CatalogRef.ManufacturingOperations -
// ** OperationID - Number -
// ** LotNumber - Number -
// ** WorkCenter - String, CatalogRef.WorkCenters -
// ** Begin - Date -
// ** Ending - Date -
// ** ParallelLoadTime - UUID -
// ** TimePlan - Number -
// ** Load - Number -
// ** ThisIsChangeover - Boolean -
// ** LotQuantity - Number -
// ** ZoomRatio - Number -
// ** CreatedOn - Number -
// ** Completed2 - Number -
// ** RepetitionIsRequired - Number -
// ** Skipped3 - Number -
// ** TransferTime - Number -
// ** Department - CatalogRef.BusinessStructure -
// ** Secondary - Boolean -
// ** LeftLimit - Date -
// ** RightBorder_ - Date -
// ** AdditionalRecord - Boolean -
// ** IntervalDuration - Number -
// * FixedBatchesOfOperations - ValueTable -
// * RanksOfWorkCenters - ValueTable - LongDesc:
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** TimeToPlace - Number -
// ** Load - Boolean - 
// ** TimeIsAvailable - Number - 
// ** Rank - Number - 
// * TimetableIssues - See InitializeScheduleProblemTable
// * LoadLimitsForWorkCenters - ValueTable -
// * BusyTimeByShift - See InitializeBusyTimeByShiftTable
// * AvailableTime - See InitializeAvailableHardwareTime
// * TableOfWorkCenters - ValueTable -
// * ScheduleTable_ - See InitializeScheduleTable
// * TableOfOperationDependencies - See InitializeOperationDependencyTable
// * ParametersOfPlanningModels - ValueTable - Where:
// ** PlanningModel - CatalogRef.MESModels -
// ** PlanningScenario - CatalogRef.ManufacturingExecutionSystemScenarios -
// ** UseAvailabilityReserve - Boolean -
// ** ValueMinimizeTime - Number - 
// ** ValueMinimizeCost - Number - 
// ** LoadMethod - EnumRef.MethodsOfWorkCenterTypeLoad -
// * AuxiliaryWorkCenters - ValueTable - Where:
// ** Stage - DocumentRef.ProductionStage2_2 -
// ** Operation - CatalogRef.ManufacturingOperations -
// ** OperationID - Number -
// ** WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes -
// * ChangeoverTime_ - ValueTable -
// * InteroperableTransitions - See InitializeInteroperableTransitionsTable
// * InteroperationTransferParameters - ValueTable -
// * TransactionTable - See UnloadOperationsTable
// * Operations - ValueTable -
// * PlanningScenario - CatalogRef.ManufacturingExecutionSystemScenarios -
// * PlanningModel - CatalogRef.MESModels -
// * LoadMethod - EnumRef.MethodsOfWorkCenterTypeLoad -
// * ArrayOfWorkCenters - Array -
// * StagePriorities - Array -
// * ArrayOfStages - Array -
// * DuplicatedParameters - Structure -
// * OptimizationOptions - Structure -
// * UseAvailabilityReserve - Boolean -
// * StatusWorkingSchedule - Number -
// * ValueMinimizeCost - Number -
// * ValueMinimizeTime - Number -
// * OperationalTimeStamp - Date -
// * StartPlanning - Date -
// * TimetableModel - UUID -
Function InitializePlanningParameters()

	Result = New Structure;
	
	// Parameters with the value type "Unique identifier".
	Result.Insert("TimetableModel", New UUID);
	
	// Parameters with the "Date" type.
	Result.Insert("StartPlanning", CurrentSessionDate());
	Result.Insert("OperationalTimeStamp", CurrentSessionDate());
	
	// Parameters with the value type "Number".
	Result.Insert("ValueMinimizeTime", 0);
	Result.Insert("ValueMinimizeCost", 0);
	Result.Insert("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	// Parameters with the "Boolean" value type.
	Result.Insert("UseAvailabilityReserve", False);
	
	// Parameters with the "Structure" value type.
	Result.Insert("OptimizationOptions", New Structure);
	Result.Insert("CalculationResults", InitializeCalculationResults());
	Result.Insert("DuplicatedParameters", New Structure);
	
	// Parameters with the value type "Array".
	Result.Insert("ArrayOfStages", New Array);
	Result.Insert("StagePriorities", New Array);
	Result.Insert("ArrayOfWorkCenters", New Array);  
	
	// Parameters with the value type "Enumerationlink.Methods of loading the individual work center".
	Result.Insert("LoadMethod", Enums.MethodsOfWorkCenterTypeLoad.EmptyRef());
	
	// Parameters with the value type "Reference Link.Modeling of operational planning".
	Result.Insert("PlanningModel", Catalogs.MESModels.EmptyRef());
	
	// Parameters with the value type "Reference Link.Scenarios of operational planning".
	Result.Insert("PlanningScenario", Catalogs.ManufacturingExecutionSystemScenarios.EmptyRef());
	
	// Parameters with the value type "Value Tables".
	Result.Insert("Operations", New ValueTable);
	Result.Insert("TransactionTable", New ValueTable);
	Result.Insert("InteroperationTransferParameters", New ValueTable);
	Result.Insert("InteroperableTransitions", InitializeInteroperableTransitionsTable());
	Result.Insert("ChangeoverTime_", New ValueTable);
	Result.Insert("AuxiliaryWorkCenters", New ValueTable);
	Result.Insert("ParametersOfPlanningModels", New ValueTable);
	Result.Insert("TableOfOperationDependencies", InitializeOperationDependencyTable());
	Result.Insert("ScheduleTable_", InitializeScheduleTable());
	Result.Insert("TableOfWorkCenters", New ValueTable);
	Result.Insert("AvailableTime", New ValueTable);
	Result.Insert("BusyTimeByShift", InitializeBusyTimeByShiftTable());
	Result.Insert("LoadLimitsForWorkCenters", New ValueTable);
	Result.Insert("TimetableIssues", InitializeScheduleProblemTable());
	Result.Insert("RanksOfWorkCenters", New ValueTable);
	Result.Insert("FixedBatchesOfOperations", New ValueTable);
	Result.Insert("IntervalsOfFixedBatches", New ValueTable);
	Result.Insert("BatchNumbersOfOperations", New ValueTable); 
	Result.Insert("UnplacedFixedBatches", InitializeTableUnplacedFixedBatches());
	
	CalculationParameters = ParametersForCalculatingOperationalSchedule();
	For Each Parameter In CalculationParameters Do
		Result.Insert(Parameter.Key, Parameter.Value);
	EndDo;	
	
	Return Result;
	
EndFunction

Procedure FillInPlanningParameters(PlanningParameters, Cancel)
	
	TempTablesManager = New TempTablesManager;
	ReadOperationsForPlanning(PlanningParameters, TempTablesManager, Cancel);
	
	If Not Cancel Then
		
		DeleteOperationsOfIrrelevantStages(PlanningParameters);
		
		CommitCreatedBatchesOfOperations(PlanningParameters, TempTablesManager);
		
		PlanningParameters.Insert("TransactionTable", UnloadOperationsTable(PlanningParameters, TempTablesManager));
		
		FixOperationsTableBasedOnMissingOperations(PlanningParameters); 
		
		InitializeOperationDependencies(PlanningParameters, TempTablesManager);
		
		FillInDependenceOnPreviousOperationsInTable(PlanningParameters); 
		
		InitializeOperationStagePriorities(PlanningParameters); 
		
		FixIrrelevantOperations(PlanningParameters, TempTablesManager);
		
		InitializePlanningModelParameters(PlanningParameters);
		
		InitializeInformationAboutWorkCenters(PlanningParameters, TempTablesManager);
		
		InitializeParametersForInteroperableTransitions(PlanningParameters);
		
		InitializeChangeoverDurations(PlanningParameters);
		
		InitializeAvailableTime(PlanningParameters);
		
		InitializeWorkCenterRanks(PlanningParameters);
		
		ModifyValueTypeOfWorkCenters(PlanningParameters);
		
	EndIf;
	
EndProcedure

Procedure FillInPlanningParametersBasedOnPlanningModelData(PlanningParameters, Val ModelParameters)
	
	FillPropertyValues(PlanningParameters, ModelParameters);
	ModifyPlanningParametersAccordingToPlanningScenario(PlanningParameters);
	
EndProcedure

#Region Operations

Procedure ReadOperationsForPlanning(PlanningParameters, TempTablesManager, Cancel)
	
	BeginTransaction();
	Try
		
		LocksManager = InformationRegisters.BlockingOperationalSchedule2_2;
		LocksManager.BlockDivision(
			PlanningParameters.Department,
			DataLockMode.Exclusive);
	
		DataBlocked = LocksManager.DivisionScheduleBlocked(PlanningParameters.Department);
		
		If Not DataBlocked Then
			
			Operations = OperationsForPlanning(PlanningParameters, TempTablesManager);
			
			If ValueIsFilled(Operations) Then
				LocksManager.BlockScheduleCalculation(
					PlanningParameters.SessionNumber,
					PlanningParameters.SessionStarted,
					PlanningParameters.Department,
					PlanningParameters.CurrentUser,
					Operations);
				PlanningParameters.Insert("Operations", Operations);
				PlanningParameters.Insert("ArrayOfStages", Operations.UnloadColumn("Stage"));
			Else
				FIXErrorMissingDataForScheduling(PlanningParameters);
				Cancel = True;
			EndIf;
			
		Else
			
			FixScheduleBlockedError(PlanningParameters);
			Cancel = True;
		
		EndIf;
		
		CommitTransaction();
			
	Except
		
		RollbackTransaction();
		
 		AddLogEntry(
			EventLogLevel.Error,
			DetailErrorDescription(ErrorInfo()));
			
		Cancel = True;
 		Raise;
		
	EndTry;
	
EndProcedure

Procedure DeleteOperationsOfIrrelevantStages(PlanningParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	PostOperativeSchedule2_2.Stage AS Stage
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule2_2
	|		LEFT JOIN InformationRegister.QueueOfProductionOperations AS QueueOfProductionOperations
	|		ON PostOperativeSchedule2_2.Stage = QueueOfProductionOperations.Stage
	|		AND QueueOfProductionOperations.MainEntry_
	|WHERE
	|	PostOperativeSchedule2_2.Department = &Department
	|	AND ISNULL(QueueOfProductionOperations.InArchive, TRUE)";
	Query.SetParameter("Department", PlanningParameters.Department);
	
	StepsTable = Query.Execute().Unload();
	For Each StageString_ In StepsTable Do
		
		Set = InformationRegisters.PostOperativeSchedule2_2.CreateRecordSet();
		Set.Filter.Stage.Set(StageString_.Stage);
		
		Set.Write(True);
		
	EndDo;
		
EndProcedure

Procedure CommitCreatedBatchesOfOperations(PlanningParameters, TempTablesManager)
	
	Query = New Query;
	Documents.ProductionOperation2_2.CreateTTBatchesOfOperations(TempTablesManager, PlanningParameters.ArrayOfStages);
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TTBatchOperations.Stage AS Stage,
	|	TTBatchOperations.Operation AS Operation,
	|	CASE
	|		WHEN TTBatchOperations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN TTBatchOperations.ProductionOperation
	|		ELSE VALUE(Document.ProductionOperation2_2.EmptyRef)
	|	END AS ProductionOperation,
	|	TTBatchOperations.OperationID AS OperationID,
	|	TTBatchOperations.LotNumber AS LotNumber,
	|	TTBatchOperations.Department AS Department,
	|	TTBatchOperations.WorkCenter AS WorkingCenterOfProductionOperation,
	|	ISNULL(TTBatchOperations.Operation.Count, 1) AS ZoomRatio,
	|	SUM(CASE
	|			WHEN TTBatchOperations.Status IN (&StatusCreated, &RunningStatus, &StatusCompleted_, &StatusSkipped)
	|				THEN TTBatchOperations.Count
	|			ELSE 0
	|		END) AS CreatedOn,
	|	SUM(CASE
	|			WHEN TTBatchOperations.Status = &RunningStatus
	|				THEN TTBatchOperations.Count
	|			ELSE 0
	|		END) AS Running,
	|	SUM(CASE
	|			WHEN TTBatchOperations.Status = &StatusCompleted_
	|				THEN TTBatchOperations.Count
	|			ELSE 0
	|		END) AS Completed2,
	|	SUM(CASE
	|			WHEN TTBatchOperations.Status = &StatusCompleted_
	|					AND TTBatchOperations.RepetitionIsRequired
	|				THEN TTBatchOperations.Count
	|			ELSE 0
	|		END) AS RepetitionIsRequired,
	|	SUM(CASE
	|			WHEN TTBatchOperations.Status = &StatusSkipped
	|				THEN TTBatchOperations.Count
	|			ELSE 0
	|		END) AS Skipped3
	|INTO TTFixedBatches
	|FROM
	|	TTBatchOperations AS TTBatchOperations
	|
	|GROUP BY
	|	TTBatchOperations.Stage,
	|	TTBatchOperations.Operation,
	|	CASE
	|		WHEN TTBatchOperations.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|			THEN TTBatchOperations.ProductionOperation
	|		ELSE VALUE(Document.ProductionOperation2_2.EmptyRef)
	|	END,
	|	TTBatchOperations.OperationID,
	|	TTBatchOperations.LotNumber,
	|	TTBatchOperations.Department,
	|	TTBatchOperations.WorkCenter
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTBatchOperations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTFixedBatches.Stage AS Stage,
	|	TTFixedBatches.Operation AS Operation,
	|	TTFixedBatches.ProductionOperation AS ProductionOperation,
	|	TTFixedBatches.OperationID AS OperationID,
	|	SUM(CASE
	|			WHEN TTFixedBatches.Running + TTFixedBatches.Completed2 + TTFixedBatches.Skipped3 - TTFixedBatches.RepetitionIsRequired> 0
	|				THEN
	|					TTFixedBatches.CreatedOn - (TTFixedBatches.Running + TTFixedBatches.Completed2 + TTFixedBatches.Skipped3 - TTFixedBatches.RepetitionIsRequired)
	|			ELSE 0
	|		END) AS QuantityDoNotPlace,
	|	MAX(TTFixedBatches.LotNumber) AS LotNumber
	|FROM
	|	TTFixedBatches AS TTFixedBatches
	|
	|GROUP BY
	|	TTFixedBatches.Stage,
	|	TTFixedBatches.OperationID,
	|	TTFixedBatches.Operation,
	|	TTFixedBatches.ProductionOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BatchesOfOperations.Stage AS Stage,
	|	BatchesOfOperations.Operation AS Operation,
	|	BatchesOfOperations.OperationID AS OperationID,
	|	BatchesOfOperations.LotNumber AS LotNumber,
	|	ISNULL(BatchesOfOperations.Operation.SetupSettings, BatchesOfOperations.ProductionOperation.SetupSettings) AS SetupSettings,
	|	BatchesOfOperations.ZoomRatio AS ZoomRatio,
	|	BatchesOfOperations.CreatedOn AS CreatedOn,
	|	BatchesOfOperations.Running AS Running,
	|	BatchesOfOperations.Completed2 AS Completed2,
	|	BatchesOfOperations.RepetitionIsRequired AS RepetitionIsRequired,
	|	BatchesOfOperations.Skipped3 AS Skipped3,
	|	BatchesOfOperations.CreatedOn AS Count,
	|	ISNULL(BatchesOfOperations.Operation.TransferLot, BatchesOfOperations.ProductionOperation.TransferLot) AS TransferLot,
	|	BatchesOfOperations.Department AS Department,
	|	BatchesOfOperations.WorkingCenterOfProductionOperation AS WorkingCenterOfProductionOperation,
	|	ISNULL(BatchesOfOperations.Operation.Load, BatchesOfOperations.ProductionOperation.Load) AS Load,
	|	0 AS TimeToPlace,
	|	0 AS PZTimeParallelLoading,
	|	FALSE AS DisableToCreateOperations,
	|	&TextDetailsOfTransactionExecutor,
	|	&TextDetailsForCalculatingOperationExecutionTime
	|FROM
	|	TTFixedBatches AS BatchesOfOperations
	|
	|ORDER BY
	|	Completed2 DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTFixedBatches.Stage AS Stage,
	|	TTFixedBatches.Operation AS Operation,
	|	TTFixedBatches.OperationID AS OperationID,
	|	TTFixedBatches.LotNumber AS LotNumber,
	|	Schedule.WorkCenter AS WorkCenter,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending,
	|	Schedule.ParallelLoadTime AS ParallelLoadTime,
	|	Schedule.TimePlan AS TimePlan,
	|	Schedule.Load AS Load,
	|	Schedule.ThisIsChangeover AS ThisIsChangeover,
	|	Schedule.LotQuantity AS LotQuantity,
	|	Schedule.ZoomRatio AS ZoomRatio,
	|	Schedule.CreatedOn AS CreatedOn,
	|	Schedule.Completed2 AS Completed2,
	|	Schedule.RepetitionIsRequired AS RepetitionIsRequired,
	|	Schedule.Skipped3 AS Skipped3,
	|	Schedule.TransferTime AS TransferTime,
	|	Schedule.Department AS Department,
	|	Schedule.Secondary AS Secondary,
	|	Schedule.LeftLimit AS LeftLimit,
	|	Schedule.RightBorder_ AS RightBorder_,
	|	Schedule.AdditionalRecord AS AdditionalRecord,
	|	Schedule.IntervalDuration AS IntervalDuration
	|FROM
	|	TTFixedBatches AS TTFixedBatches
	|		INNER JOIN InformationRegister.PostOperativeSchedule2_2 AS Schedule
	|		ON TTFixedBatches.Stage = Schedule.Stage
	|			AND TTFixedBatches.Operation = Schedule.Operation
	|			AND TTFixedBatches.OperationID = Schedule.OperationID
	|			AND TTFixedBatches.LotNumber = Schedule.LotNumber
	|WHERE
	|	NOT Schedule.Modeling
	|	AND NOT Schedule.ThisIsOperationDeletion
	|
	|ORDER BY
	|	WorkCenter,
	|	Begin";
	Query.SetParameter("StatusCreated", Enums.ProductionOperationStatuses.CreatedOn_);
	Query.SetParameter("RunningStatus", Enums.ProductionOperationStatuses.Running);
	Query.SetParameter("StatusCompleted_", Enums.ProductionOperationStatuses.Executed);
	Query.SetParameter("StatusSkipped", Enums.ProductionOperationStatuses.IsSkipped);
	
	DataSourceOfOperation = InformationRegisters.QueueOfProductionOperations.QueryTextDataSourceOfOperation("BatchesOfOperations");
	
	Query.Text = StrReplace(
		Query.Text,
		"&TextDetailsOfTransactionExecutor",
		Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation(DataSourceOfOperation));
		
	Query.Text = StrReplace(
		Query.Text,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation(DataSourceOfOperation));
	
	QueryResult = Query.ExecuteBatch();
	
	BatchNumbers = QueryResult[QueryResult.UBound() - 2].Unload(); // ValueTable - 
	BatchNumbers.Indexes.Add("Stage, Operation, OperationID");
	PlanningParameters.Insert("BatchNumbersOfOperations", BatchNumbers);
	
	BatchesOfOperations = QueryResult[QueryResult.UBound() - 1].Unload();
	PlanningParameters.Insert("FixedBatchesOfOperations", BatchesOfOperations);
	
	BatchIntervals = QueryResult[QueryResult.UBound()].Unload(); // ValueTable - 
	BatchIntervals.Indexes.Add("Stage, Operation, OperationID, LotNumber");
	PlanningParameters.Insert("IntervalsOfFixedBatches", BatchIntervals);
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	TempTablesManager - TempTablesManager - LongDesc
// Returns:
// 	ValueTable - Where:
// * TimeToPlace - Number - 
// * Load - Boolean - 
// * SetupSettings - CatalogRef.SetupOptions - 
// * TransferLot - Number - 
// * StartDate2 - Date - 
// * DateOfProduction - Date - 
// * Count - Number - 
// * NumberOfPages_1 - Number - 
// * ZoomRatio - Number - 
// * Department - CatalogRef.BusinessStructure - 
// * Stage - DocumentRef.ProductionStage2_2 - 
// * Operation - CatalogRef.ManufacturingOperations - 
// * OperationID - Number - 
// * Order - Number - 
// * StageStart - Date - 
// * WorkCenterType - CatalogRef.WorkCenterTypes - 
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes - 
// * ParallelLoad- Boolean - 
// * TimePerPiece- Number - 
// * TimePerPieceUnitOfMeasure- EnumRef.TimeMeasureUnits - 
// * SetupTime- Number - 
// * SetupTimeUnitOfMeasure- EnumRef.TimeMeasureUnits - 
// * OperationNumber - Number -
// * Continuous - Boolean -
Function UnloadOperationsTable(PlanningParameters, TempTablesManager)
	
	FilterText1 = "
	|(Queue.Stage, Queue.Operation, Queue.OperationID) IN
	|		(SELECT
	|			Operations.Stage,
	|			Operations.Operation,
	|			Operations.OperationID
	|		FROM
	|			OperationsForPlanning AS Operations)
	|AND NOT Queue.InArchive";
	
	AdditionalFields = New Array;
	AdditionalFields.Add(StrTemplate("%1.%2 AS %2", InformationRegisters.QueueOfProductionOperations.QueryTextDataSourceOfOperation(), "WorkCenter"));
	AdditionalFields.Add("MAX(Queue.Order) AS Order");
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.AttributesOfTimeOfOperation = True;
	RequestTextParameters.ExtendedAttributesOfOperations = True;
	RequestTextParameters.SelectionFields1 = AdditionalFields;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add(FilterText1);
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Queue.Description AS Description,
	|	Queue.Department AS Department,
	|	Queue.Stage AS Stage,
	|	Queue.Operation AS Operation,
	|	Queue.ProductionOperation AS ProductionOperation,
	|	Queue.OperationID AS OperationID,
	|	Queue.OperationNumber AS OperationNumber,
	|	Queue.Load AS Load,
	|	Queue.Continuous AS Continuous,
	|	Queue.SetupSettings AS SetupSettings,
	|	Queue.TransferLot AS TransferLot,
	|	Queue.Scheduled - Queue.Completed2 - Queue.Running - Queue.Skipped3 AS Count,
	|	Queue.Scheduled - Queue.Completed2 - Queue.Running - Queue.Skipped3 AS NumberOfPages_1,
	|	ISNULL(Queue.Operation.Count, 1) AS ZoomRatio,
	|	CASE
	|		WHEN Queue.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN CASE
	|					WHEN ISNULL(CAST(Queue.WorkCenter AS Catalog.WorkCenterTypes).ParallelLoad, FALSE)
	|						THEN Queue.TimePerPiece + Queue.SetupTime
	|					ELSE Queue.TimePerPiece * (Queue.Scheduled - Queue.Completed2 - Queue.Running - Queue.Skipped3) + Queue.SetupTime
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(CAST(Queue.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ParallelLoad, FALSE)
	|					THEN Queue.TimePerPiece + Queue.SetupTime
	|				ELSE Queue.TimePerPiece * (Queue.Scheduled - Queue.Completed2 - Queue.Running - Queue.Skipped3) + Queue.SetupTime
	|			END
	|	END * CASE
	|		WHEN Queue.TimeUnitsOfMeasure = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN 86400
	|		WHEN Queue.TimeUnitsOfMeasure = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN 3600
	|		WHEN Queue.TimeUnitsOfMeasure = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN 60
	|		ELSE 1
	|	END AS TimeToPlace,
	|	Queue.Order AS Order,
	|	Schedule.Begin AS StageStart,
	|	Schedule.Begin AS StartDate2,
	|	Schedule.Ending AS DateOfProduction,
	|	&TextDetailsOfTransactionExecutor,
	|	&TextDetailsForCalculatingOperationExecutionTime
	|FROM
	|	TTQueue AS Queue
	|
	|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|	ON Queue.Stage = Schedule.Stage
	|		AND (Schedule.ScheduleStatus = &StatusWorkingSchedule)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTQueue
	|
	|";
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("StatusWorkingSchedule", PlanningParameters.StatusWorkingSchedule);
	
	DataSourceOfOperation = InformationRegisters.QueueOfProductionOperations.QueryTextDataSourceOfOperation();
	
	Query.Text = StrReplace(
		Query.Text,
		"&TextDetailsOfTransactionExecutor",
		Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation(DataSourceOfOperation));
		
	Query.Text = StrReplace(
		Query.Text,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("Queue.Operation"));
	
	ResultsArray = Query.ExecuteBatch();
	TransactionTable = ResultsArray[ResultsArray.UBound()-1].Unload();
	
	TransactionTable.Columns.Add("StagePriority", New TypeDescription("Number", New NumberQualifiers(5))); 
	TransactionTable.Columns.Add("Posted_1", New TypeDescription("Boolean")); 
	TransactionTable.Columns.Add("Allocate", New TypeDescription("Boolean")); 
	TransactionTable.Columns.Add("DependsOnPreceding", New TypeDescription("Boolean")); 
	TransactionTable.Columns.Add("DataFromPreviousBatches", New TypeDescription("ValueTable"));
	TransactionTable.Columns.Add("PrecedingDataIsSorted", New TypeDescription("Boolean"));  
	TransactionTable.Columns.Add("BatchSize", New TypeDescription("Number", New NumberQualifiers(5))); 
	
	TransactionTable.FillValues(True, "Allocate"); 
		
	TransactionTable.Indexes.Add("Stage, OperationID"); 
	TransactionTable.Indexes.Add("WorkCenterType, StagePriority, Allocate, Posted_1, DependsOnPreceding"); 
	TransactionTable.Indexes.Add("Stage"); 
	
	Return TransactionTable;
	
EndFunction

Procedure FixIrrelevantOperations(PlanningParameters, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	Schedule.Stage AS Stage,
	|	Schedule.Operation AS Operation,
	|	Schedule.OperationID AS OperationID,
	|	Schedule.LotNumber AS LotNumber,
	|	Schedule.WorkCenter AS WorkCenter,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS Schedule
	|WHERE
	|	NOT Schedule.Modeling
	|	AND ((Schedule.Stage, Schedule.Operation, Schedule.OperationID) IN
	|				(SELECT
	|					Operations.Stage,
	|					Operations.Operation,
	|					Operations.OperationID
	|				FROM
	|					OperationsForPlanning AS Operations)
	|			OR (Schedule.Stage, Schedule.Operation, Schedule.OperationID) IN
	|				(SELECT
	|					FixedBatches.Stage,
	|					FixedBatches.Operation,
	|					FixedBatches.OperationID
	|				FROM
	|					TTFixedBatches AS FixedBatches))";
	IrrelevantOperations = Query.Execute().Unload();
	
	If ValueIsFilled(IrrelevantOperations) Then
		
		InformationRegisters.PostOperativeSchedule2_2.RecordOperationsToDelete(PlanningParameters.TimetableModel, IrrelevantOperations);
		
	EndIf;
	
EndProcedure

Function OperationsForPlanning(PlanningParameters, TempTablesManager)
	
	ThereAreExceptions_ = False;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	InitializeOperationRequestForScheduling(Query, PlanningParameters, ThereAreExceptions_);
		
	If ThereAreExceptions_ Then
		
		QueryResult = Query.Execute();
		Query.Text = 
		"SELECT
		|	ScheduleOperations.Stage AS Stage,
		|	ScheduleOperations.Operation AS Operation,
		|	ScheduleOperations.OperationID AS OperationID,
		|	ScheduleOperations.LotNumber AS LotNumber,
		|	ScheduleOperations.Begin AS Begin,
		|	ScheduleOperations.Ending AS Ending,
		|	ScheduleOperations.Count AS Count,
		|	ScheduleOperations.ZoomRatio AS ZoomRatio,
		|	ScheduleOperations.TransferLot AS TransferLot
		|INTO Exceptions
		|FROM
		|	ScheduleOperations AS ScheduleOperations
		|WHERE
		|	&ThereAreExceptions_
		|	AND ScheduleOperations.Begin BETWEEN &StartOfException AND &EndOfException
		|	AND NOT (ScheduleOperations.Stage, ScheduleOperations.Operation, ScheduleOperations.OperationID, ScheduleOperations.LotNumber) IN
		|				(SELECT
		|					UnavailableExecutionOperations.Stage AS Stage,
		|					UnavailableExecutionOperations.Operation AS Operation,
		|					UnavailableExecutionOperations.OperationID AS OperationID,
		|					UnavailableExecutionOperations.LotNumber AS LotNumber
		|				FROM
		|					UnavailableExecutionOperations)
		|
		|INDEX BY
		|	Stage,
		|	OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionOperationsPreceding.Stage AS Stage,
		|	ProductionOperationsPreceding.Operation AS Operation_Previous,
		|	ProductionOperationsPreceding.OperationID AS OperationIDPreceding,
		|	ProductionOperations.Operation AS Operation,
		|	ProductionOperations.OperationID AS OperationID
		|INTO DependenceOfOperations
		|FROM
		|	TTOperationQueue AS ProductionOperationsPreceding
		|		INNER JOIN TTOperationQueue AS ProductionOperations
		|		ON ProductionOperationsPreceding.Stage = ProductionOperations.Stage
		|			AND ProductionOperationsPreceding.NextOperation = ProductionOperations.OperationNumber
		|WHERE
		|	NOT ProductionOperationsPreceding.NextOperation = 0
		|	AND (ProductionOperations.Stage, ProductionOperations.OperationID) IN
		|			(SELECT
		|				Exceptions.Stage AS Stage,
		|				Exceptions.OperationID AS OperationID
		|			FROM
		|				Exceptions)
		|
		|INDEX BY
		|	Stage,
		|	OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTAvailableOperations.Stage AS Stage,
		|	TTAvailableOperations.Operation AS Operation,
		|	TTAvailableOperations.OperationID AS OperationID
		|INTO OperationsForPlanning
		|FROM
		|	TTAvailableOperations AS TTAvailableOperations
		|
		|UNION ALL
		|
		|SELECT
		|	Exceptions.Stage,
		|	Exceptions.Operation,
		|	Exceptions.OperationID
		|FROM
		|	Exceptions AS Exceptions
		|		INNER JOIN DependenceOfOperations AS DependenceOfOperations
		|		ON Exceptions.Stage = DependenceOfOperations.Stage
		|			AND Exceptions.OperationID = DependenceOfOperations.OperationID
		|WHERE
		|	(DependenceOfOperations.Stage, DependenceOfOperations.OperationIDPreceding) IN
		|			(SELECT
		|				TTAvailableOperations.Stage,
		|				TTAvailableOperations.OperationID
		|			FROM
		|				TTAvailableOperations)
		|
		|INDEX BY
		|	Stage,
		|	Operation,
		|	OperationID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP UnavailableExecutionOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ScheduleOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DependenceOfOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTAvailableOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP UnavailableOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductionOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTQueue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationsForPlanning.Stage AS Stage,
		|	OperationsForPlanning.Operation AS Operation,
		|	OperationsForPlanning.OperationID AS OperationID
		|FROM
		|	OperationsForPlanning AS OperationsForPlanning
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Exceptions.Stage AS Stage,
		|	Exceptions.Operation AS Operation,
		|	Exceptions.OperationID AS OperationID,
		|	Exceptions.LotNumber AS LotNumber,
		|	Exceptions.Begin AS Begin,
		|	Exceptions.Ending AS Ending,
		|	Exceptions.Count AS Count,
		|	Exceptions.ZoomRatio AS ZoomRatio,
		|	Exceptions.TransferLot AS TransferLot
		|FROM
		|	Exceptions AS Exceptions";
		QueryResult = Query.ExecuteBatch();
		TransactionTable = QueryResult[QueryResult.UBound() - 1].Unload();
		Exceptions = QueryResult[QueryResult.UBound()].Unload();
		If Exceptions.Count() > 0 Then
			PlanningParameters.Insert("PreviousUnavailableExceptionOperations", Exceptions);
		EndIf;
		
	Else
		
		Query.Text = StrReplace(Query.Text, "TTAvailableOperations", "OperationsForPlanning");
		QueryResult = Query.Execute();
		Query.Text =
		"DROP UnavailableExecutionOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ScheduleOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP UnavailableOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductionOperations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTQueue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperationsForPlanning.Stage AS Stage,
		|	OperationsForPlanning.Operation AS Operation,
		|	OperationsForPlanning.OperationID AS OperationID
		|FROM
		|	OperationsForPlanning AS OperationsForPlanning";
		TransactionTable = Query.Execute().Unload();
		
	EndIf;
	
	TransactionTable.GroupBy("Stage, Operation, OperationID");
	
	Return TransactionTable;
	
EndFunction

Procedure InitializeOperationRequestForScheduling(Query, Val PlanningParameters, ThereAreExceptions_)
	
	Query.Text = QueryTextOperationsForPlanning();
	
	Boundaries = PlanningBoundaries(PlanningParameters);
	Query.SetParameter("Ending", Boundaries.Ending);
		
	ThereAreExceptions_ = Not PlanningParameters.OperationalCalculation Or PlanningParameters.StandardTimeToRegisterOperationExecution > 0;
						
	If ThereAreExceptions_ Then
		
		Query.SetParameter("ThereAreExceptions_", True);
		StartOfException = PlanningParameters.OperationalTimeStamp - PlanningParameters.StandardTimeToRegisterOperationExecution;
		EndOfException = PlanningParameters.PlanningTimepoint - 1;
		
	Else
		
		Query.SetParameter("ThereAreExceptions_", False);
		StartOfException = '00010101';
		EndOfException = '00010101';
		
	EndIf;
	
	Query.SetParameter("StartOfException", StartOfException);
	Query.SetParameter("EndOfException", EndOfException);
	Query.SetParameter("OperationalTimeStamp", PlanningParameters.OperationalTimeStamp);
	
	Query.SetParameter("FilterDepartment", ValueIsFilled(PlanningParameters.Department));
	Query.SetParameter("Department", PlanningParameters.Department);
	
	Query.SetParameter("FilterReferences", ValueIsFilled(PlanningParameters.References));
	Query.SetParameter("References", PlanningParameters.References);
	
	Query.SetParameter("FilterProductionStages", ValueIsFilled(PlanningParameters.ProductionStages));
	Query.SetParameter("ProductionStages", PlanningParameters.ProductionStages);
	Query.SetParameter("StatusWorkingSchedule", PlanningParameters.StatusWorkingSchedule);
	
EndProcedure

Function QueryTextOperationsForPlanning()
	
	FilterText1 = "
	|	(NOT &FilterDepartment
	|			OR Queue.Department = &Department)
	|	AND (NOT &FilterReferences
	|			OR Queue.ReferenceOrder IN (&References))
	|	AND (NOT &FilterProductionStages
	|			OR Queue.Stage IN (&ProductionStages))
	|	AND Queue.Stage.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND NOT Queue.InArchive";
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add(FilterText1);
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	QueueOfProductionOperations.Stage AS Stage,
	|	QueueOfProductionOperations.Operation AS Operation,
	|	QueueOfProductionOperations.OperationID AS OperationID,
	|	ISNULL(PostOperativeSchedule.LotNumber, UNDEFINED) AS LotNumber
	|INTO ProductionOperations
	|FROM
	|	TTQueue AS QueueOfProductionOperations
	|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|		ON QueueOfProductionOperations.ReferenceOrder = Schedule.ProductionOrder
	|			AND QueueOfProductionOperations.Stage = Schedule.Stage
	|			AND (Schedule.ScheduleStatus = &StatusWorkingSchedule)
	|		LEFT JOIN InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|		ON QueueOfProductionOperations.Stage = PostOperativeSchedule.Stage
	|			AND QueueOfProductionOperations.Operation = PostOperativeSchedule.Operation
	|			AND QueueOfProductionOperations.OperationID = PostOperativeSchedule.OperationID
	|			AND (NOT PostOperativeSchedule.ThisIsOperationDeletion)
	|			AND (NOT PostOperativeSchedule.Modeling)
	|			AND (NOT PostOperativeSchedule.AdditionalRecord)
	|			AND (NOT PostOperativeSchedule.Secondary)
	|			AND (NOT PostOperativeSchedule.ThisIsChangeover)
	|WHERE
	|	QueueOfProductionOperations.Scheduled - QueueOfProductionOperations.Skipped3 - QueueOfProductionOperations.Completed2 > 0
	|	AND Schedule.Begin <= &Ending
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID,
	|	LotNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.LotNumber AS LotNumber,
	|	PostOperativeSchedule.Department AS Department,
	|	PostOperativeSchedule.LeftLimit AS Begin,
	|	PostOperativeSchedule.RightBorder_ AS Ending,
	|	PostOperativeSchedule.LotQuantity AS Count,
	|	PostOperativeSchedule.ZoomRatio AS ZoomRatio,
	|	PostOperativeSchedule.Operation.TransferLot AS TransferLot
	|INTO ScheduleOperations
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	(PostOperativeSchedule.Stage, PostOperativeSchedule.Operation, PostOperativeSchedule.OperationID) IN
	|			(SELECT
	|				ProductionOperations.Stage AS Stage,
	|				ProductionOperations.Operation AS Operation,
	|				ProductionOperations.OperationID AS OperationID
	|			FROM
	|				ProductionOperations)
	|	AND NOT PostOperativeSchedule.ThisIsOperationDeletion
	|	AND NOT PostOperativeSchedule.Modeling
	|	AND NOT PostOperativeSchedule.AdditionalRecord
	|	AND NOT PostOperativeSchedule.Secondary
	|	AND NOT PostOperativeSchedule.ThisIsChangeover
	|
	|INDEX BY
	|	Begin
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Document.ProductionStage2_2.EmptyRef) AS Stage,
	|	VALUE(Catalog.ManufacturingOperations.EmptyRef) AS Operation,
	|	0 AS OperationID,
	|	0 AS LotNumber
	|INTO UnavailableExecutionOperations
	|WHERE
	|		FALSE
	|
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID,
	|	LotNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UnavailableExecutionOperations.Stage AS Stage,
	|	UnavailableExecutionOperations.Operation AS Operation,
	|	UnavailableExecutionOperations.OperationID AS OperationID,
	|	UnavailableExecutionOperations.LotNumber AS LotNumber
	|INTO UnavailableOperations
	|FROM
	|	UnavailableExecutionOperations AS UnavailableExecutionOperations
	|
	|UNION ALL
	|
	|SELECT
	|	ScheduleOperations.Stage,
	|	ScheduleOperations.Operation,
	|	ScheduleOperations.OperationID,
	|	ScheduleOperations.LotNumber
	|FROM
	|	ScheduleOperations AS ScheduleOperations
	|WHERE
	|	&ThereAreExceptions_
	|	AND ScheduleOperations.Begin BETWEEN &StartOfException AND &EndOfException
	|	AND NOT (ScheduleOperations.Stage, ScheduleOperations.Operation, ScheduleOperations.OperationID, ScheduleOperations.LotNumber) IN
	|				(SELECT
	|					UnavailableExecutionOperations.Stage AS Stage,
	|					UnavailableExecutionOperations.Operation AS Operation,
	|					UnavailableExecutionOperations.OperationID AS OperationID,
	|					UnavailableExecutionOperations.LotNumber AS LotNumber
	|				FROM
	|					UnavailableExecutionOperations)
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID,
	|	LotNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionOperations.Stage AS Stage,
	|	ProductionOperations.Operation AS Operation,
	|	ProductionOperations.OperationID AS OperationID,
	|	ProductionOperations.LotNumber AS LotNumber,
	|	MIN(ScheduleOfProductionStages2_2.Begin) AS StartDate2,
	|	MAX(ScheduleOfProductionStages2_2.Ending) AS DateOfProduction
	|INTO TTAvailableOperations
	|FROM
	|	ProductionOperations AS ProductionOperations
	|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|		ON ProductionOperations.Stage = ScheduleOfProductionStages2_2.Stage
	|WHERE
	|	NOT (ProductionOperations.Stage, ProductionOperations.Operation, ProductionOperations.OperationID, ProductionOperations.LotNumber) IN
	|				(SELECT
	|					UnavailableOperations.Stage AS Stage,
	|					UnavailableOperations.Operation AS Operation,
	|					UnavailableOperations.OperationID AS OperationID,
	|					UnavailableOperations.LotNumber AS LotNumber
	|				FROM
	|					UnavailableOperations)
	|
	|GROUP BY
	|	ProductionOperations.Stage,
	|	ProductionOperations.Operation,
	|	ProductionOperations.OperationID,
	|	ProductionOperations.LotNumber
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	QueueOfProductionOperations.Stage AS Stage,
	|	QueueOfProductionOperations.Operation AS Operation,
	|	QueueOfProductionOperations.OperationID AS OperationID,
	|	QueueOfProductionOperations.OperationNumber AS OperationNumber,
	|	QueueOfProductionOperations.NextOperation AS NextOperation
	|INTO TTOperationQueue
	|FROM
	|	InformationRegister.QueueOfProductionOperations AS QueueOfProductionOperations
	|WHERE
	|	QueueOfProductionOperations.Stage IN
	|			(SELECT
	|				TTAvailableOperations.Stage
	|			FROM
	|				TTAvailableOperations)
	|	AND NOT QueueOfProductionOperations.InArchive
	|
	|INDEX BY
	|	Stage,
	|	OperationNumber,
	|	NextOperation";	
	
	Return QueryText;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 - 
// * Completed2 - Number -
// * RepetitionIsRequired - Number -
// * CreatedOn - Number -
// * OperationString - ValueTableRow - 
// * Posted_1 - Boolean -
// * Allocate - Boolean -
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes - 
// * StagePriority  - Number -
// * Order - Number - 
// * Department - CatalogRef.BusinessStructure - 
// * TransferLot - Number - 
// * Operation - CatalogRef.ManufacturingOperations -
// * LotNumber - Number -
// * OperationNumber - Number -
// * Continuous - Boolean -
// * ZoomRatio - Number - 
// * Count - Number -
// * OperationID - Number -
// * Load - Boolean -
// * DependsOnPreceding - Boolean -
// * DataFromPreviousBatches - See InitializeDataFromPreviousBatches
// * StartDate2 - Date - 
// * DateOfProduction - Date - 
// * TimeToPlace - Number -
// * PZTimeParallelLoading - Number - 
// * WorkCenterType - CatalogRef.WorkCenterTypes - 
// * SetupSettings - CatalogRef.SetupOptions -
Function InitializeBatchOperations()
	
	Result = New Structure;
	Result.Insert("SetupSettings");
	Result.Insert("WorkCenterType");
	Result.Insert("PZTimeParallelLoading");
	Result.Insert("TimeToPlace");
	Result.Insert("DateOfProduction");
	Result.Insert("StartDate2");
	Result.Insert("DataFromPreviousBatches");
	Result.Insert("DependsOnPreceding");
	Result.Insert("Load");
	Result.Insert("OperationID");
	Result.Insert("Count");
	Result.Insert("ZoomRatio");
	Result.Insert("Continuous");
	Result.Insert("OperationNumber");
	Result.Insert("LotNumber");
	Result.Insert("Operation");
	Result.Insert("TransferLot");
	Result.Insert("Department");
	Result.Insert("Order");
	Result.Insert("StagePriority");
	Result.Insert("WorkCenter");
	Result.Insert("Allocate");
	Result.Insert("Posted_1");
	Result.Insert("OperationString");
	Result.Insert("CreatedOn", 0);
	Result.Insert("RepetitionIsRequired", 0);
	Result.Insert("Completed2", 0);
	Result.Insert("Stage");
	Result.Insert("Description");
	
	Return Result;
	
EndFunction

#EndRegion

#Region OtherParameters

Procedure InitializePlanningModelParameters(PlanningParameters)

	If ValueIsFilled(PlanningParameters.PlanningModels) Then
		
		Query = New Query(
		"SELECT
		|	ModelTable_.PlanningModel AS PlanningModel,
		|	ModelTable_.PlanningScenario AS PlanningScenario,
		|	ModelTable_.UseAvailabilityReserve AS UseAvailabilityReserve
		|INTO ModelTable_
		|FROM
		|	&ModelTable_ AS ModelTable_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ModelTable_.PlanningModel AS PlanningModel,
		|	ModelTable_.PlanningScenario AS PlanningScenario,
		|	ModelTable_.UseAvailabilityReserve AS UseAvailabilityReserve,
		|	MESModels.ValueMinimizeTime AS ValueMinimizeTime,
		|	MESModels.ValueMinimizeCost AS ValueMinimizeCost,
		|	MESModels.LoadMethod AS LoadMethod
		|FROM
		|	ModelTable_ AS ModelTable_
		|		INNER JOIN Catalog.MESModels AS MESModels
		|		ON ModelTable_.PlanningModel = MESModels.Ref");
		Query.SetParameter("ModelTable_", PlanningParameters.PlanningModels);
		
		Parameters = Query.Execute().Unload();
		
	Else
		
		Parameters = New ValueTable;
		Parameters.Columns.Add("PlanningModel", New TypeDescription("CatalogRef.MESModels"));
		Parameters.Columns.Add("PlanningScenario", New TypeDescription("CatalogRef.ManufacturingExecutionSystemScenarios"));
		Parameters.Columns.Add("UseAvailabilityReserve", New TypeDescription("Boolean"));
		Parameters.Columns.Add("ValueMinimizeTime", New TypeDescription("Number", New NumberQualifiers()));
		Parameters.Columns.Add("ValueMinimizeCost", New TypeDescription("Number", New NumberQualifiers()));
		Parameters.Columns.Add("LoadMethod", New TypeDescription("EnumRef.MethodsOfWorkCenterTypeLoad"));
		
		NewRow = Parameters.Add();
		NewRow.ValueMinimizeTime = 1;
		
	EndIf;
	
	PlanningParameters.Insert("ParametersOfPlanningModels", Parameters);
	
EndProcedure

// Initializes a table to store errors and warnings recorded during the calculation process.
// 
// Returns:
//  ValueTable - an empty table with columns:
//		* LineNumber - Number - Line number.
//		* Category - EnumRef.IssueCategoriesOfOperationTimetable - problem category.
//		* Type - Number - type of problem, where 1 is a warning and 2 is an error.
//		* Text - String - description of the problem for the user.
//		* WhatToDoNext - String - recommendations for fixing the problem.
//		* Properties - Structure - arbitrary data related to the problem.
//		* Key - Arbitrary - a value that uniquely identifies the problem. Used to
//			avoid multiple registration of identical problems.
//
Function InitializeScheduleProblemTable()
	
	Result = New ValueTable;
	
	Result.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(5)));
	Result.Columns.Add("Category", New TypeDescription("EnumRef.IssueCategoriesOfOperationTimetable"));
	Result.Columns.Add("Type", New TypeDescription("Number", New NumberQualifiers(1)));
	Result.Columns.Add("Text", New TypeDescription("String",, New StringQualifiers()));
	Result.Columns.Add("WhatToDoNext", New TypeDescription("String",, New StringQualifiers()));
	Result.Columns.Add("Properties", New TypeDescription("Structure"));
	Result.Columns.Add("Key");
	
	Result.Indexes.Add("Category");
	
	Return Result;
	
EndFunction

Procedure InitializeInformationAboutWorkCenters(PlanningParameters, TempTablesManager)
	
	InitializeAuxiliaryWorkCenters(PlanningParameters, TempTablesManager);
	InitializeWorkCenters(PlanningParameters, TempTablesManager);
	InitializeLoadLimitsForWorkCenters(PlanningParameters, TempTablesManager);
	
EndProcedure

Procedure InitializeAuxiliaryWorkCenters(PlanningParameters, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	OperationsForPlanning.Stage AS Stage,
	|	OperationsForPlanning.Operation AS Operation,
	|	OperationsForPlanning.OperationID AS OperationID
	|INTO TransactionTable
	|FROM
	|	OperationsForPlanning AS OperationsForPlanning
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TransactionTable.Stage AS Stage,
	|	TransactionTable.Operation AS Operation,
	|	TransactionTable.OperationID AS OperationID,
	|	ManufacturingOperationsAuxiliaryWorkCenters.WorkCenter AS WorkCenter
	|INTO TTAuxiliaryWorkCenters
	|FROM
	|	TransactionTable AS TransactionTable
	|		INNER JOIN Catalog.ManufacturingOperations.AuxiliaryWorkCenters AS ManufacturingOperationsAuxiliaryWorkCenters
	|		ON TransactionTable.Operation = ManufacturingOperationsAuxiliaryWorkCenters.Ref
	|
	|INDEX BY
	|	WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAuxiliaryWorkCenters.Stage AS Stage,
	|	TTAuxiliaryWorkCenters.Operation AS Operation,
	|	TTAuxiliaryWorkCenters.OperationID AS OperationID,
	|	TTAuxiliaryWorkCenters.WorkCenter AS WorkCenter
	|FROM
	|	TTAuxiliaryWorkCenters AS TTAuxiliaryWorkCenters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TransactionTable";
		
	PlanningParameters.Insert("AuxiliaryWorkCenters", Query.Execute().Unload());
	
EndProcedure

Procedure InitializeWorkCenters(PlanningParameters, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	&TextDetailsOfTransactionExecutor
	|INTO TTWorkCentersOfOperations
	|FROM
	|	OperationsForPlanning AS Operations
	|
	|INDEX BY
	|	WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&TextDetailsOfTransactionExecutor
	|INTO TTFixedOperationsWorkCenters
	|FROM
	|	TTFixedBatches AS Operations
	|
	|INDEX BY
	|	WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	WorkCenters.Ref AS WorkCenter
	|INTO TTWorkCenters
	|FROM
	|	Catalog.WorkCenters AS WorkCenters
	|WHERE
	|	(WorkCenters.Ref IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTWorkCentersOfOperations AS WorkCenters)
	|			OR WorkCenters.Ref IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTFixedOperationsWorkCenters AS WorkCenters)
	|			OR WorkCenters.Ref IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTAuxiliaryWorkCenters AS WorkCenters))
	|
	|UNION ALL
	|
	|SELECT
	|	WorkCenters.Ref
	|FROM
	|	Catalog.WorkCenters AS WorkCenters
	|WHERE
	|	(WorkCenters.WorkCenterType IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTWorkCentersOfOperations AS WorkCenters)
	|			OR WorkCenters.WorkCenterType IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTFixedOperationsWorkCenters AS WorkCenters)
	|			OR WorkCenters.WorkCenterType IN
	|				(SELECT
	|					WorkCenters.WorkCenter
	|				FROM
	|					TTAuxiliaryWorkCenters AS WorkCenters))
	|
	|INDEX BY
	|	WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	WorkCenters.WorkCenterType.Department AS Department,
	|	WorkCenters.WorkCenterType AS WorkCenterType,
	|	WorkCenters.Ref AS WorkCenter,
	|	WorkCenters.WorkTimeFactor AS WorkTimeFactor,
	|	WorkCenters.RateWork AS RateWork,
	|	WorkCenters.RateChangeover AS RateChangeover,
	|	WorkCenters.MaximumLoad AS MaximumLoad,
	|	WorkCenters.WorkCenterType.ParallelLoad AS ParallelLoad,
	|	CASE
	|		WHEN WorkCenters.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SynchronousLoad
	|FROM
	|	Catalog.WorkCenters AS WorkCenters
	|WHERE
	|	WorkCenters.Ref IN
	|			(SELECT
	|				TTWorkCenters.WorkCenter AS Ref
	|			FROM
	|				TTWorkCenters)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTWorkCentersOfOperations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAuxiliaryWorkCenters
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTFixedOperationsWorkCenters";
	
	Query.Text = StrReplace(
		Query.Text,
		"&TextDetailsOfTransactionExecutor",
		Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation("Operations.Operation"));
		
	TableOfWorkCenters = Query.Execute().Unload();
	
	TableOfWorkCenters.Indexes.Add("WorkCenterType");
	TableOfWorkCenters.Indexes.Add("WorkCenter");
	TableOfWorkCenters.Indexes.Add("Department");
	
	PlanningParameters.Insert("TableOfWorkCenters", TableOfWorkCenters);
	PlanningParameters.Insert("ArrayOfWorkCenters", 	TableOfWorkCenters.UnloadColumn("WorkCenter"));
	
EndProcedure

Procedure InitializeLoadLimitsForWorkCenters(PlanningParameters, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	WorkCenterTypes.Ref AS WorkCenterType,
	|	WorkCenterTypes.AvailabilityReserve AS AvailabilityReserve,
	|	100 - WorkCenterTypes.AvailabilityReserve AS MaxLoadPercentage
	|FROM
	|	Catalog.WorkCenterTypes AS WorkCenterTypes
	|WHERE
	|	WorkCenterTypes.Ref IN
	|			(SELECT DISTINCT
	|				WorkCenters.WorkCenterType AS WorkCenterType
	|			FROM
	|				Catalog.WorkCenters AS WorkCenters
	|			WHERE
	|				WorkCenters.Ref IN
	|					(SELECT
	|						WorkCenters.WorkCenter
	|					FROM
	|						TTWorkCenters AS WorkCenters))";
		
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("WorkCenterType");
	
	PlanningParameters.Insert("LoadLimitsForWorkCenters", Result);
	
EndProcedure

// Returns:
// 	ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation_Previous - CatalogRef.ManufacturingOperations -
// * OperationIDPreceding - Number -
// * PrecedingOperationIsInvolvedInCalculation - Boolean -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * OperationIsInvolvedInCalculation - Boolean -
Function InitializeOperationDependencyTable()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("Operation_Previous", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("OperationIDPreceding", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("PrecedingOperationIsInvolvedInCalculation", New TypeDescription("Boolean"));
	Result.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("OperationIsInvolvedInCalculation", New TypeDescription("Boolean"));
	
	Return Result;
	
EndFunction

Procedure InitializeOperationDependencies(PlanningParameters, TempTablesManager)
	
	DependenciesTable = PlanningParameters.TableOfOperationDependencies;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	Queue.Stage AS Stage,
	|	Queue.Operation AS Operation,
	|	Queue.OperationID AS OperationID,
	|	Queue.OperationNumber AS OperationNumber,
	|	Queue.NextOperation AS NextOperation,
	|	CASE
	|		WHEN (Queue.Stage, Queue.OperationID) IN
	|				(SELECT
	|					Operations.Stage,
	|					Operations.OperationID
	|				FROM
	|					OperationsForPlanning AS Operations)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OperationIsInvolvedInCalculation
	|FROM
	|	TTOperationQueue AS Queue";
	ProductionOperations = Query.Execute().Unload();
	ProductionOperations.Indexes.Add("Stage, OperationNumber");
	
	StructureOfSearchForFollowingOperations = New Structure("Stage, OperationNumber");
	For Each ProductionOperationLine In ProductionOperations Do
		
		If ProductionOperationLine.NextOperation = 0 Then
			Continue;
		EndIf;
		
		StructureOfSearchForFollowingOperations.Stage = ProductionOperationLine.Stage;
		StructureOfSearchForFollowingOperations.OperationNumber = ProductionOperationLine.NextOperation;
		
		LinesOfFollowingOperations = ProductionOperations.FindRows(StructureOfSearchForFollowingOperations);
		For Each LineOfFollowingOperation In LinesOfFollowingOperations Do
			DependenciesRow = DependenciesTable.Add();
			DependenciesRow.Stage = ProductionOperationLine.Stage;
			DependenciesRow.Operation_Previous = ProductionOperationLine.Operation;
			DependenciesRow.OperationIDPreceding = ProductionOperationLine.OperationID;
			DependenciesRow.PrecedingOperationIsInvolvedInCalculation = ProductionOperationLine.OperationIsInvolvedInCalculation;
			DependenciesRow.Operation = LineOfFollowingOperation.Operation;
			DependenciesRow.OperationID = LineOfFollowingOperation.OperationID;
			DependenciesRow.OperationIsInvolvedInCalculation = LineOfFollowingOperation.OperationIsInvolvedInCalculation
		EndDo;		
		
	EndDo;
	
	DependenciesTable.Indexes.Add("Stage, OperationIDPreceding");
	DependenciesTable.Indexes.Add("Stage, OperationID");
	DependenciesTable.Indexes.Add("Stage, OperationID, PrecedingOperationIsInvolvedInCalculation");
	
EndProcedure

Function RelatedOperationsNotInvolvedInCalculation(Val TableOfOperationDependencies)
	
	Result = New ValueTable;
	Result.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	
	Result.Indexes.Add("Stage, Operation, OperationID");
	
	TheStructureOfTheSearch = New Structure("Stage, Operation, OperationID");
	For Each DependenciesRow In TableOfOperationDependencies Do
		
		TheStructureOfTheSearch.Stage = DependenciesRow.Stage;
		TheStructureOfTheSearch.Operation = DependenciesRow.Operation;
		TheStructureOfTheSearch.OperationID = DependenciesRow.OperationID;
		
		If Not DependenciesRow.OperationIsInvolvedInCalculation
			And Result.FindRows(TheStructureOfTheSearch).Count() = 0 Then
			
			FillPropertyValues(Result.Add(), TheStructureOfTheSearch);
			
		EndIf;
		
		TheStructureOfTheSearch.Operation = DependenciesRow.Operation_Previous;
		TheStructureOfTheSearch.OperationID = DependenciesRow.OperationIDPreceding;
		
		If Not DependenciesRow.PrecedingOperationIsInvolvedInCalculation
			And Result.FindRows(TheStructureOfTheSearch).Count() = 0 Then
			
			FillPropertyValues(Result.Add(), TheStructureOfTheSearch);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
// 	Operations - ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// Returns:
// 	ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * Begin - Date - 
// * Ending - Date - 
// * DesignatedWorkCenter - String, CatalogRef.WorkCenters -
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes -
// * TimePerPiece - Number - 
// * SetupTime - Number - 
// * SetupSettings - CatalogRef.SetupOptions - 
// * Department - CatalogRef.BusinessStructure -
// * Scheduled - Number -
// * CreatedOn - Number -
// * PendingPredecessorCompletion - Number -
// * PreviousOnesStarted - Number -
// * ExecutionIsAllowed - Number -
// * Running - Number -
// * Completed2 - Number -
// * RepetitionIsRequired - Number -
// * Skipped3 - Number -
// * ReferenceOrder - DocumentRef.ProductionOrder2_2 -
// * TimeTotal - Number -
// * TimeUnitsOfMeasure - EnumRef.TimeMeasureUnits -
// * OperationNumber - Number -
// * NextOperation - Number -
// * Order - Number -
Function MissingOperationsData(Operations)
	
	QueryTexts = New Array;
	
	QueryText = "
	|SELECT
	|	Operations.Stage AS Stage,
	|	Operations.Operation AS Operation,
	|	Operations.OperationID AS OperationID
	|INTO TransactionTable
	|FROM
	|	&Operations AS Operations";
	QueryTexts.Add(QueryText);
	
	FilterText1 = "
	|(Queue.Stage, Queue.Operation, Queue.OperationID) IN
	|		(SELECT
	|			TransactionTable.Stage,
	|			TransactionTable.Operation,
	|			TransactionTable.OperationID
	|		FROM
	|			TransactionTable AS TransactionTable)
	|AND NOT Queue.InArchive";
	
	AdditionalFields = New Array;
	AdditionalFields.Add("MAX(Queue.Order) AS Order");
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.ExtendedAttributesOfOperations = True;
	RequestTextParameters.AttributesOfTimeOfOperation = True;
	RequestTextParameters.SelectionFields1 = AdditionalFields;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add(FilterText1);
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters);
	QueryTexts.Add(QueryText);
	
	QueryText = "
	|SELECT ALLOWED
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.WorkCenter AS DesignatedWorkCenter,
	|	MIN(PostOperativeSchedule.Begin) AS Begin,
	|	MAX(PostOperativeSchedule.Ending) AS Ending
	|INTO ScheduleData_
	|FROM
	|	TransactionTable AS TransactionTable
	|		INNER JOIN InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|		ON TransactionTable.Stage = PostOperativeSchedule.Stage
	|			AND TransactionTable.Operation = PostOperativeSchedule.Operation
	|			AND TransactionTable.OperationID = PostOperativeSchedule.OperationID
	|WHERE
	|	PostOperativeSchedule.Secondary = FALSE
	|	AND PostOperativeSchedule.Modeling = FALSE
	|
	|GROUP BY
	|	PostOperativeSchedule.Stage,
	|	PostOperativeSchedule.Operation,
	|	PostOperativeSchedule.OperationID,
	|	PostOperativeSchedule.WorkCenter
	|
	|INDEX BY
	|	Stage,
	|	Operation,
	|	OperationID";
	QueryTexts.Add(QueryText);
	
	QueryText = "
	|SELECT ALLOWED
	|	ScheduleData_.Stage AS Stage,
	|	ScheduleData_.Operation AS Operation,
	|	ScheduleData_.OperationID AS OperationID,
	|	ScheduleData_.Begin AS Begin,
	|	ScheduleData_.Ending AS Ending,
	|	ScheduleData_.DesignatedWorkCenter AS DesignatedWorkCenter,
	|	ScheduleData_.Operation.WorkCenter AS WorkCenter,
	|	ScheduleData_.Operation.TimePerPiece * CASE
	|		WHEN ScheduleData_.Operation.TimePerPieceUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN 86400
	|		WHEN ScheduleData_.Operation.TimePerPieceUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN 3600
	|		WHEN ScheduleData_.Operation.TimePerPieceUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN 60
	|		ELSE 1
	|	END AS TimePerPiece,
	|	ScheduleData_.Operation.SetupTime * CASE
	|		WHEN ScheduleData_.Operation.SetupTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN 86400
	|		WHEN ScheduleData_.Operation.SetupTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN 3600
	|		WHEN ScheduleData_.Operation.SetupTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN 60
	|		ELSE 1
	|	END AS SetupTime,
	|	ScheduleData_.Operation.SetupSettings AS SetupSettings,
	|	Queue.Department AS Department,
	|	Queue.Scheduled - Queue.RepetitionIsRequired AS Scheduled,
	|	Queue.CreatedOn AS CreatedOn,
	|	Queue.PendingPredecessorCompletion AS PendingPredecessorCompletion,
	|	Queue.PreviousOnesStarted AS PreviousOnesStarted,
	|	Queue.ExecutionIsAllowed AS ExecutionIsAllowed,
	|	Queue.Running AS Running,
	|	Queue.Completed2 AS Completed2,
	|	Queue.RepetitionIsRequired AS RepetitionIsRequired,
	|	Queue.Skipped3 AS Skipped3,
	|	Queue.ReferenceOrder AS ReferenceOrder,
	|	Queue.TimeTotal AS RunTime,
	|	Queue.TimeUnitsOfMeasure AS ExecutionTimeUnitOfMeasure,
	|	Queue.OperationNumber AS OperationNumber,
	|	Queue.NextOperation AS NextOperation,
	|	Queue.Order AS Order
	|FROM
	|	ScheduleData_ AS ScheduleData_
	|		LEFT JOIN TTQueue AS Queue
	|		ON ScheduleData_.Stage = Queue.Stage
	|			AND ScheduleData_.Operation = Queue.Operation
	|			AND ScheduleData_.OperationID = Queue.OperationID";
	QueryTexts.Add(QueryText);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.SetParameter("Operations", Operations);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure InitializeParametersForInteroperableTransitions(PlanningParameters)
	
	Query = New Query(
	"SELECT ALLOWED
	|	InteroperationTransferParameters.Department AS Department,
	|	InteroperationTransferParameters.WorkCenterTypeSource AS Source,
	|	InteroperationTransferParameters.WorkCenterTypeDestination AS Receiver,
	|	CASE
	|		WHEN InteroperationTransferParameters.TransferTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.SECOND)
	|			THEN InteroperationTransferParameters.TransferTime
	|		WHEN InteroperationTransferParameters.TransferTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN InteroperationTransferParameters.TransferTime * 60
	|		WHEN InteroperationTransferParameters.TransferTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN InteroperationTransferParameters.TransferTime * 3600
	|		WHEN InteroperationTransferParameters.TransferTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.DAY)
	|				OR InteroperationTransferParameters.TransferTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN InteroperationTransferParameters.TransferTime * 86400
	|		ELSE InteroperationTransferParameters.TransferTime
	|	END AS Time
	|FROM
	|	InformationRegister.InteroperationTransferParameters AS InteroperationTransferParameters
	|WHERE
	|	InteroperationTransferParameters.Department IN(&Departments)");
	
	Query.SetParameter("Departments", PlanningParameters.Department);
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("Department, Source, Receiver");
	
	PlanningParameters.Insert("InteroperationTransferParameters", Result);
	
EndProcedure

Procedure InitializeChangeoverDurations(PlanningParameters)
	
	ArrayTypesOfWorkCenters = PlanningParameters.TableOfWorkCenters.UnloadColumn("WorkCenterType");
	
	Query = New Query(
	"SELECT ALLOWED
	|	ChangeoverDurationTime.WorkCenterType AS WorkCenterType,
	|	ChangeoverDurationTime.CurrentSetupSettings AS CurrentSetupSettings,
	|	ChangeoverDurationTime.NextSetupSettings AS NextSetupSettings,
	|	CASE
	|		WHEN ChangeoverDurationTime.WorkCenterType.ChangeoverTimeUnit = VALUE(Enum.TimeMeasureUnits.SECOND)
	|			THEN ChangeoverDurationTime.ChangeoverTime
	|		WHEN ChangeoverDurationTime.WorkCenterType.ChangeoverTimeUnit = VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN ChangeoverDurationTime.ChangeoverTime * 60
	|		WHEN ChangeoverDurationTime.WorkCenterType.ChangeoverTimeUnit = VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN ChangeoverDurationTime.ChangeoverTime * 3600
	|		WHEN ChangeoverDurationTime.WorkCenterType.ChangeoverTimeUnit = VALUE(Enum.TimeMeasureUnits.DAY)
	|				OR ChangeoverDurationTime.WorkCenterType.ChangeoverTimeUnit = VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN ChangeoverDurationTime.ChangeoverTime * 86400
	|		ELSE ChangeoverDurationTime.ChangeoverTime
	|	END AS Time
	|FROM
	|	InformationRegister.ChangeoverDurationTime AS ChangeoverDurationTime
	|WHERE
	|	ChangeoverDurationTime.WorkCenterType IN(&WorkCenterTypes)");
	
	Query.SetParameter("WorkCenterTypes", ArrayTypesOfWorkCenters);
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("WorkCenterType, CurrentSetupSettings, NextSetupSettings");
	
	PlanningParameters.Insert("ChangeoverTime_", Result);
	
EndProcedure

Procedure InitializeAvailableTime(PlanningParameters)
	
	AvailableTime = AvailableEquipmentTime(PlanningParameters);
	FillInDataBeforeFollowingAvailableTime(PlanningParameters, AvailableTime);
	
	SortTableAvailableTime(AvailableTime);
	
	AvailableTime.Indexes.Add("WorkCenter, Period");
	AvailableTime.Indexes.Add("WorkCenter, StartOfShift");
	AvailableTime.Indexes.Add("WorkCenter");
	AvailableTime.Indexes.Add("WorkCenterType");
	
	PlanningParameters.Insert("AvailableTime", AvailableTime);
	
EndProcedure

// Returns:
// 	ValueTable - See InformationRegister.PostOperativeSchedule2_2. required fields:
// * Stage - DocumentRef.ProductionStage2_2 -
// * OperationID - Number - 
// * WorkCenter - String, CatalogRef.WorkCenters - 
// * Begin - Date - 
// * Ending - Date - 
// * TimePlan - Number - 
// * LotQuantity - Number - 
// * Completed2 - Number - 
// * TransferTime - Number - 
// * Secondary - Boolean - 
// * LeftLimit - Date - 
// * RightBorder_- Date - 
// * AdditionalRecord - Boolean - 
// * IntervalDuration - Number - 
Function InitializeScheduleTable()
	
	Result = New ValueTable;
	
	ProductionManagementWhenPlanningServer.FillInTableStructureByRegisterMetadata("InformationRegisters", "PostOperativeSchedule2_2", Result);
	
	Result.Indexes.Add("OperationID, Secondary");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * WorkCenter - CatalogRef.WorkCenters -
// * StartOfShift - Date -
// * TimeTaken - Number - 
// * ShiftTime - Number - 
Function InitializeBusyTimeByShiftTable()
	
	Result = New ValueTable;
	
	Result.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Result.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	Result.Columns.Add("StartOfShift", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("TimeTaken", DescriptionOfTypesOperationTimeDepth());
	Result.Columns.Add("ShiftTime", DescriptionOfTypesOperationTimeDepth());
	
	Result.Indexes.Add("WorkCenter, StartOfShift");
	Result.Indexes.Add("WorkCenter");
	Result.Indexes.Add("WorkCenterType");
	
	Return Result;
	
EndFunction

Procedure ModifyValueTypeOfWorkCenters(PlanningParameters)
	
	If ScenariosAreUsed(PlanningParameters) Then
		
		AddedTypes = "String";
		StringQualifiers = New StringQualifiers(100);
		
		For Each Parameter In PlanningParameters Do
			
			If TypeOf(Parameter.Value) = Type("ValueTable") Then
				
				TableOfPlanningParameters = Parameter.Value;//ValueTable - 
				
				For Each Column In TableOfPlanningParameters.Columns Do
					
					If Column.ValueType.ContainsType(Type("CatalogRef.WorkCenters"))
						And Not Column.ValueType.ContainsType(Type("String")) Then
						
						AddTypeToValueTypeOfTableColumn(Parameter.Value, Column.Name, AddedTypes,, StringQualifiers);
							
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function ScenariosAreUsed(Val PlanningParameters)
	
	Result = False;
	
	For Each String In PlanningParameters.ParametersOfPlanningModels Do
		If ValueIsFilled(String.PlanningScenario) Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure InitializeWorkCenterRanks(PlanningParameters)
	
	Ranks = PlanningParameters.TransactionTable.Copy(, "WorkCenterType, TimeToPlace, Load");
	
	For Each String In Ranks Do
		If ValueIsFilled(String.Load) Then
			String.TimeToPlace = String.TimeToPlace * String.Load;
		EndIf;
	EndDo;
	
	Ranks.GroupBy("WorkCenterType", "TimeToPlace");
	Ranks.Columns.TimeToPlace.Name = "LoadingTime";
	Ranks.Columns.Add("TimeIsAvailable", DescriptionOfTypesOperationTimeDepth());
	Ranks.Columns.Add("Rank", New TypeDescription("Number", New NumberQualifiers(10, 5)));
	
	CalculateRanksOfWorkCenters(PlanningParameters, Ranks);
	
	Ranks.Indexes.Add("WorkCenterType");

	PlanningParameters.Insert("RanksOfWorkCenters", Ranks);
	
EndProcedure

Procedure CalculateRanksOfWorkCenters(Val PlanningParameters, Ranks)
	
	TimeIsAvailable = PlanningParameters.BusyTimeByShift.Copy(, "WorkCenterType, TimeTaken, ShiftTime");
	TimeIsAvailable.GroupBy("WorkCenterType", "TimeTaken, ShiftTime");
	TimeIsAvailable.Indexes.Add("WorkCenterType");
	
	For Each String In Ranks Do
		
		SearchString = TimeIsAvailable.Find(String.WorkCenterType, "WorkCenterType");
		If SearchString = Undefined Then
			
			String.Rank = 0;
			
		Else
			
			String.TimeIsAvailable = SearchString.ShiftTime - SearchString.TimeTaken;
			
			If Not String.TimeIsAvailable = 0 Then
				
				String.Rank = String.LoadingTime / String.TimeIsAvailable;
				
			Else
				String.Rank = 0;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Ranks.Sort("Rank Asc");
	
EndProcedure

Procedure InitializeOperationStagePriorities(PlanningParameters)
	
	Priorities = PrioritiesOfStagesOfOperations(PlanningParameters);
	
	SearchCondition = New Structure("Stage");
	For Each String In Priorities Do
		
		FillPropertyValues(SearchCondition, String);
		SearchBars = PlanningParameters.TransactionTable.FindRows(SearchCondition);
		For Each Operation In SearchBars Do
			Operation.StagePriority = String.Priority;
		EndDo;
		
	EndDo;
	
	Priorities.GroupBy("Priority");
	PlanningParameters.Insert("StagePriorities", Priorities.UnloadColumn("Priority"));
	
EndProcedure

Function PrioritiesOfStagesOfOperations(PlanningParameters)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Schedule.Stage AS Stage,
	|	Schedule.ProductionOrder.Priority.AddlOrderingAttribute AS OrderPriority_,
	|	MIN(Schedule.Begin) AS Begin,
	|	MAX(Schedule.Ending) AS Ending
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|WHERE
	|	Schedule.Stage IN(&Stages)
	|	AND Schedule.ScheduleStatus = &StatusWorkingSchedule
	|
	|GROUP BY
	|	Schedule.Stage,
	|	Schedule.ProductionOrder.Priority.AddlOrderingAttribute";
	Query.SetParameter("Stages", PlanningParameters.ArrayOfStages);
	Query.SetParameter("StatusWorkingSchedule", PlanningParameters.StatusWorkingSchedule);
	Stages = Query.Execute().Unload();
	
	Stages.Columns.Add("Category", New TypeDescription("Number", New NumberQualifiers(1)));
	Stages.Columns.Add("Tension", New TypeDescription("Number"));
	Stages.Columns.Add("Priority", New TypeDescription("Number", New NumberQualifiers(5)));
	
	CalculateCategoryAndIntensityOfStages(PlanningParameters, Stages);
	Stages.Sort("Category Asc, Tension Desc, Begin Asc, OrderPriority_ Asc");
	CalculatePriorityOfStages(Stages);
	
	Return Stages;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	Stages - ValueTable - Where:
// * Stage - DocumentRef.ProductionStage2_2 -
// * OrderPriority_ - Number -
// * Begin - Date - 
// * Ending - Date - 
Procedure CalculateCategoryAndIntensityOfStages(Val PlanningParameters, Stages)
	
	For Each String In Stages Do
		
		If String.Ending <= PlanningParameters.PlanningTimepoint Then
			
			String.Category = 1;
			String.Tension = PlanningParameters.PlanningTimepoint - String.Ending;
			
		ElsIf String.Begin < PlanningParameters.PlanningTimepoint Then
			
			String.Category = 2;
			BalanceOfOperations = TimeOfUnplacedStageOperations(PlanningParameters, String.Stage);
			RestOfTime = String.Ending - PlanningParameters.PlanningTimepoint;
			String.Tension = BalanceOfOperations / RestOfTime;
			
		Else
			
			String.Category = 3;
			String.Tension = 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function TimeOfUnplacedStageOperations(Val PlanningParameters, Val Stage)
	
	Result = 0;
	
	SearchCondition = New Structure("Stage", Stage);
	SearchBars = PlanningParameters.TransactionTable.FindRows(SearchCondition);
	For Each String In SearchBars Do
		Result = Result + String.TimeToPlace;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CalculatePriorityOfStages(Stages)
	
	NumberOfStages_ = Stages.Count();
	
	If NumberOfStages_ > 0 Then
		NumberOfBatches = Round(Log(NumberOfStages_));
		NumberOfBatches = ?(NumberOfBatches > 0, NumberOfBatches, 1);
	Else
		NumberOfBatches = 1;
	EndIf;
	
	BatchSize = Round(NumberOfStages_/NumberOfBatches);
	
	CntOfStages = 0;
	LotNumber = 1;
	For Each String In Stages Do
		String.Priority = LotNumber;
		CntOfStages = CntOfStages + 1;
		
		If CntOfStages = BatchSize Then
			CntOfStages = 0;
			LotNumber = LotNumber + 1;
		EndIf;
	EndDo;
	
EndProcedure

// Returns:
// 	ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2
// * OperationID - Number
// * TransferTime - Number
Function InitializeInteroperableTransitionsTable()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Stage");
	Result.Columns.Add("OperationID");
	Result.Columns.Add("TransferTime");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * LotNumber - Number -
// * Count - Number -
// * CreatedOn - Number -
Function InitializeTableUnplacedFixedBatches()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("LotNumber", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("CreatedOn", New TypeDescription("Number", New NumberQualifiers()));
	
	Result.Indexes.Add("Stage, Operation, OperationID");
	
	Return Result;
	
EndFunction

#EndRegion

#Region AvailableTimeOfWorkCenters

Function AvailableEquipmentTime(PlanningParameters)
	
	AvailableTime = InitializeAvailableHardwareTime();
	
	TimeFoundation = EquipmentTimeFund(PlanningParameters);
	SampleRc = TimeFoundation.Select(QueryResultIteration.ByGroups);
	While SampleRc.Next() Do
		
		SampleChange = SampleRc.Select(QueryResultIteration.ByGroups);
		
		While SampleChange.Next() Do
			
			If SampleChange.ParallelLoad Then
				TimeTaken = SampleChange.BusyTimeParallelLoading;
				ShiftTime = SampleChange.ShiftTime * SampleChange.MaximumLoad;
			Else
				TimeTaken = SampleChange.TimeTaken;
				ShiftTime = SampleChange.ShiftTime;
			EndIf;
			
			RecordBusyTimeByShift(PlanningParameters, SampleChange, TimeTaken, ShiftTime);
			
			If TimeTaken < ShiftTime Then
				Selection = SampleChange.Select();
				
				If SampleChange.ParallelLoad Then
					FillAvailableShiftTimeParallelLoading(AvailableTime, Selection, SampleChange);
				Else
					FillInAvailableShiftTime(AvailableTime, Selection, SampleChange.StartOfShift, SampleChange.EndOfShift);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return AvailableTime;
	
EndFunction

Procedure FillAvailableShiftTimeParallelLoading(AvailableTime, Selection, SampleChange)
	
	Selection.Next();
	FixAvailableTime(
		AvailableTime,
		Selection,
		SampleChange.StartOfShift,
		SampleChange.EndOfShift,
		SampleChange.MaximumLoad,
		SampleChange.ShiftTime);
	
	ThereAreBusyIntervals = Selection.BusyTimeParallelLoading > 0;
	
	If ThereAreBusyIntervals Then

		AddedRow = LastRowOfAvailableTimeTable(AvailableTime);

		AddedRow.SetupSettings = Catalogs.SetupOptions.EmptyRef();

		AvailableIntervals = New Array; //Array of See LastRowOfAvailableTimeTable
		AvailableIntervals.Add(AddedRow);
		
		ExcludeIntervals = New Array;
		
		Selection.Reset();
	    While Selection.Next() Do
			
			BusyStart = Selection.BusyStart;
			BusyEnding = Selection.BusyEnding;
			
			CurrentIndex = 0;
			While CurrentIndex <= AvailableIntervals.UBound() Do
				
				AvailableInterval = AvailableIntervals[CurrentIndex]; 
				
				If BusyStart = AvailableInterval.Begin 
					And BusyEnding = AvailableInterval.Ending Then
					
					// The occupied interval is identical to the available one.
					If Selection.Load >= AvailableInterval.AvailableDownload Then
						AvailableIntervals.Delete(CurrentIndex);
					Else
						AvailableInterval.AvailableDownload = AvailableInterval.AvailableDownload - Selection.Load;
						AvailableInterval.SetupSettings = Selection.SetupSettings;
					EndIf;
					Break;
					
				ElsIf BusyStart = AvailableInterval.Begin Then
					
					// The occupied interval is pressed to the left border of the available one.
					If Selection.Load >= AvailableInterval.AvailableDownload Then
						
						If BusyEnding >= AvailableInterval.Ending Then
							BusyStart = AvailableInterval.Ending;
							AvailableIntervals.Delete(CurrentIndex);
						Else
							AvailableInterval.Begin = BusyEnding;
							AvailableInterval.Time = AvailableInterval.Ending - AvailableInterval.Begin;
							Break;
						EndIf;
						
					Else
						
						If BusyEnding >= AvailableInterval.Ending Then
							BusyStart = AvailableInterval.Ending;
							AvailableInterval.AvailableDownload = AvailableInterval.AvailableDownload - Selection.Load;
							AvailableInterval.SetupSettings = Selection.SetupSettings;
							CurrentIndex = CurrentIndex + 1;
						Else
							FixAvailableTime(AvailableTime, AvailableInterval, BusyEnding, AvailableInterval.Ending, AvailableInterval.AvailableDownload);
							AvailableIntervals.Insert(CurrentIndex + 1, LastRowOfAvailableTimeTable(AvailableTime));
							
							AvailableInterval.Ending = BusyEnding;
							AvailableInterval.Time = AvailableInterval.Ending - AvailableInterval.Begin;
							AvailableInterval.AvailableDownload = AvailableInterval.AvailableDownload - Selection.Load;
							AvailableInterval.SetupSettings = Selection.SetupSettings;
							Break;
						EndIf;
						
					EndIf;
						
				ElsIf BusyStart < AvailableInterval.Ending 
					And BusyEnding >= AvailableInterval.Ending Then
					
					// The occupied interval is pressed to the right border of the available one.
					If Selection.Load >= AvailableInterval.AvailableDownload Then
						EndingBeforeChange = AvailableInterval.Ending;
						AvailableInterval.Ending = BusyStart;
						AvailableInterval.Time = AvailableInterval.Ending - AvailableInterval.Begin;
						CurrentIndex = CurrentIndex + 1;
					Else
						AvailableDownload = AvailableInterval.AvailableDownload - Selection.Load;
						FixAvailableTime(AvailableTime, Selection, BusyStart, AvailableInterval.Ending, AvailableDownload);
						AvailableIntervals.Insert(CurrentIndex + 1, LastRowOfAvailableTimeTable(AvailableTime));
						
						CurrentIndex = CurrentIndex + 2;
						
						EndingBeforeChange = AvailableInterval.Ending;
						AvailableInterval.Ending = BusyStart;
						AvailableInterval.Time = AvailableInterval.Ending - AvailableInterval.Begin;
					EndIf;
					
					If BusyEnding > EndingBeforeChange Then
						BusyStart = EndingBeforeChange;
					Else
						Break;
					EndIf;
				
				ElsIf BusyStart > AvailableInterval.Begin 
					And BusyEnding < AvailableInterval.Ending Then
					
					// The occupied interval is inside the available one.
					If Selection.Load >= AvailableInterval.AvailableDownload Then
						FixAvailableTime(AvailableTime, AvailableInterval, BusyEnding, AvailableInterval.Ending, AvailableInterval.AvailableDownload);
						AvailableIntervals.Insert(CurrentIndex + 1, LastRowOfAvailableTimeTable(AvailableTime));
					Else
						AvailableDownload = AvailableInterval.AvailableDownload - Selection.Load;
						FixAvailableTime(AvailableTime, Selection, BusyStart, BusyEnding, AvailableDownload);
						AvailableIntervals.Insert(CurrentIndex + 1, LastRowOfAvailableTimeTable(AvailableTime));
						
						FixAvailableTime(AvailableTime, AvailableInterval, BusyEnding, AvailableInterval.Ending, AvailableInterval.AvailableDownload);
						AvailableIntervals.Insert(CurrentIndex + 2, LastRowOfAvailableTimeTable(AvailableTime));
					EndIf;
					
					AvailableInterval.Ending = BusyStart;
					AvailableInterval.Time = AvailableInterval.Ending - AvailableInterval.Begin;
					Break;
					
				Else
					CurrentIndex = CurrentIndex + 1;
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInAvailableShiftTime(AvailableTime, Selection, StartOfShift, EndOfShift)
	
	If Selection.Count() = 1 Then
		
		Selection.Next();
		If ValueIsFilled(Selection.BusyStart) Then
			
			If Not Selection.StartOfShift = Selection.BusyStart Then
				FixAvailableTime(AvailableTime, Selection, Selection.StartOfShift, Selection.BusyStart);
			EndIf;
			
			If Not Selection.BusyEnding = Selection.EndOfShift Then
				FixAvailableTime(AvailableTime, Selection, Selection.BusyEnding, Selection.EndOfShift);
			EndIf;
			
		Else
			FixAvailableTime(AvailableTime, Selection, Selection.StartOfShift, Selection.EndOfShift, , Selection.ShiftTime);
		EndIf;
		
	Else
		
		Begin = StartOfShift;
		
		While Selection.Next() Do
			
			If Selection.BusyStart = Begin Then
				Begin = Selection.BusyEnding;
				Continue;
			Else
				FixAvailableTime(AvailableTime, Selection, Begin, Selection.BusyStart);
				Begin = Selection.BusyEnding;
			EndIf;
			
		EndDo;
		
		If Not Begin = EndOfShift Then
			Selection.Reset();
			Selection.Next();
			FixAvailableTime(AvailableTime, Selection, Begin, EndOfShift);
		EndIf;
		
	EndIf;
	
EndProcedure

// Returns:
// 	ValueTable - LongDesc:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
Function InitializeAvailableHardwareTime()
	
	Result = New ValueTable;
	
	Result.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Result.Columns.Add("ParallelLoad", New TypeDescription("Boolean"));
	Result.Columns.Add("SynchronousLoad", New TypeDescription("Boolean"));
	
	Result.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	Result.Columns.Add("Period", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	
	Result.Columns.Add("StartOfShift", New TypeDescription("Date",,, New DateQualifiers));
	
	Result.Columns.Add("Time", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("ShiftTime", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.Add("MaximumLoad", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("AvailableDownload", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.Add("SetupSettings", New TypeDescription("CatalogRef.SetupOptions"));
	
	Result.Columns.Add("PrecededByLoading", New TypeDescription("Boolean"));
	Result.Columns.Add("SetupSettingsPreceding", New TypeDescription("CatalogRef.SetupOptions"));
	
	Result.Columns.Add("DownloadFollows", New TypeDescription("Boolean"));
	Result.Columns.Add("SetupSettingsFollowing", New TypeDescription("CatalogRef.SetupOptions"));
	
	Return Result;
	
EndFunction

Function EquipmentTimeFund(PlanningParameters)
	
	QueryText = QueryTextEquipmentTimeFund();
	Query = New Query(QueryText);
	
	Boundaries = PlanningBoundaries(PlanningParameters);
	
	Query.SetParameter("Begin", Boundaries.Begin);
	Query.SetParameter("Ending",  Boundaries.Ending);
	Query.SetParameter("WorkCenters", PlanningParameters.ArrayOfWorkCenters);
	Query.SetParameter("TimetableModel", PlanningParameters.TimetableModel);
	
	Return Query.Execute();
	
EndFunction

Function QueryTextEquipmentTimeFund()
	
	Result = 
	"SELECT ALLOWED
	|	PostOperativeSchedule.Stage AS Stage,
	|	PostOperativeSchedule.Operation AS Operation,
	|	PostOperativeSchedule.OperationID AS OperationID,
	|	PostOperativeSchedule.LotNumber AS LotNumber
	|INTO IrrelevantOperations
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.ThisIsOperationDeletion = TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AvailabilityOfWorkCenters.WorkCenter AS WorkCenter,
	|	AvailabilityOfWorkCenters.Begin AS Begin,
	|	AvailabilityOfWorkCenters.Ending AS Ending,
	|	DATEDIFF(AvailabilityOfWorkCenters.Begin, AvailabilityOfWorkCenters.Ending, SECOND) AS Time
	|INTO FreeTime
	|FROM
	|	InformationRegister.AvailabilityOfWorkCenters AS AvailabilityOfWorkCenters
	|WHERE
	|	(AvailabilityOfWorkCenters.Begin BETWEEN &Begin AND &Ending
	|			OR AvailabilityOfWorkCenters.Ending BETWEEN &Begin AND &Ending)
	|	AND AvailabilityOfWorkCenters.WorkCenter IN(&WorkCenters)
	|
	|INDEX BY
	|	WorkCenter,
	|	Begin,
	|	Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	WorkCenterRM.WorkCenter AS WorkCenter,
	|	WorkCenterRM.StartDate AS Begin,
	|	WorkCenterRM.CompletedOn AS Ending,
	|	WorkCenterRM.WorkCenter.MaximumLoad AS Load,
	|	VALUE(Catalog.SetupOptions.EmptyRef) AS SetupSettings
	|INTO BusyIntervals
	|FROM
	|	InformationRegister.WorkCenterRM AS WorkCenterRM
	|WHERE
	|	(WorkCenterRM.StartDate BETWEEN &Begin AND &Ending
	|			OR WorkCenterRM.CompletedOn BETWEEN &Begin AND &Ending)
	|	AND WorkCenterRM.WorkCenter IN(&WorkCenters)
	|
	|UNION ALL
	|
	|SELECT
	|	CAST(PostOperativeSchedule.WorkCenter AS Catalog.WorkCenters),
	|	PostOperativeSchedule.Begin,
	|	PostOperativeSchedule.Ending,
	|	PostOperativeSchedule.Load,
	|	PostOperativeSchedule.Operation.SetupSettings
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	(PostOperativeSchedule.Begin BETWEEN &Begin AND &Ending
	|			OR PostOperativeSchedule.Ending BETWEEN &Begin AND &Ending)
	|	AND PostOperativeSchedule.WorkCenter IN(&WorkCenters)
	|	AND NOT (PostOperativeSchedule.Stage, PostOperativeSchedule.Operation, PostOperativeSchedule.OperationID, PostOperativeSchedule.LotNumber) IN
	|				(SELECT
	|					IrrelevantOperations.Stage,
	|					IrrelevantOperations.Operation,
	|					IrrelevantOperations.OperationID,
	|					IrrelevantOperations.LotNumber
	|				FROM
	|					IrrelevantOperations)
	|	AND PostOperativeSchedule.Modeling = FALSE
	|	AND PostOperativeSchedule.LotQuantity <> (PostOperativeSchedule.Completed2 + PostOperativeSchedule.Skipped3 - PostOperativeSchedule.RepetitionIsRequired)
	|	AND (PostOperativeSchedule.CreatedOn = 0
	|			OR PostOperativeSchedule.CreatedOn <> (PostOperativeSchedule.Completed2 + PostOperativeSchedule.Skipped3 - PostOperativeSchedule.RepetitionIsRequired))
	|
	|INDEX BY
	|	WorkCenter,
	|	Begin,
	|	Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FreeTime.WorkCenter AS WorkCenter,
	|	BusyIntervals.Begin AS Begin,
	|	BusyIntervals.Ending AS Ending,
	|	BusyIntervals.Load AS Load,
	|	BusyIntervals.SetupSettings AS SetupSettings
	|INTO BusyIntervalsGiven
	|FROM
	|	BusyIntervals AS BusyIntervals
	|		INNER JOIN FreeTime AS FreeTime
	|		ON BusyIntervals.WorkCenter = FreeTime.WorkCenter
	|			AND (BusyIntervals.Begin BETWEEN FreeTime.Begin AND FreeTime.Ending)
	|			AND (BusyIntervals.Ending BETWEEN FreeTime.Begin AND FreeTime.Ending)
	|
	|UNION ALL
	|
	|SELECT
	|	FreeTime.WorkCenter,
	|	CASE
	|		WHEN BusyIntervals.Begin >= FreeTime.Begin
	|			THEN BusyIntervals.Begin
	|		ELSE FreeTime.Begin
	|	END,
	|	CASE
	|		WHEN BusyIntervals.Ending <= FreeTime.Ending
	|			THEN BusyIntervals.Ending
	|		ELSE FreeTime.Ending
	|	END,
	|	BusyIntervals.Load,
	|	BusyIntervals.SetupSettings
	|FROM
	|	BusyIntervals AS BusyIntervals
	|		INNER JOIN FreeTime AS FreeTime
	|		ON BusyIntervals.WorkCenter = FreeTime.WorkCenter
	|			AND (BusyIntervals.Begin >= FreeTime.Begin
	|					AND BusyIntervals.Begin < FreeTime.Ending
	|					AND BusyIntervals.Ending > FreeTime.Ending
	|				OR BusyIntervals.Ending > FreeTime.Begin
	|					AND BusyIntervals.Ending <= FreeTime.Ending
	|					AND BusyIntervals.Begin < FreeTime.Begin)
	|
	|UNION ALL
	|
	|SELECT
	|	FreeTime.WorkCenter,
	|	FreeTime.Begin,
	|	FreeTime.Ending,
	|	BusyIntervals.Load,
	|	BusyIntervals.SetupSettings
	|FROM
	|	BusyIntervals AS BusyIntervals
	|		INNER JOIN FreeTime AS FreeTime
	|		ON BusyIntervals.WorkCenter = FreeTime.WorkCenter
	|			AND BusyIntervals.Begin < FreeTime.Begin
	|			AND BusyIntervals.Ending > FreeTime.Ending
	|			AND (FreeTime.Begin BETWEEN BusyIntervals.Begin AND BusyIntervals.Ending)
	|
	|INDEX BY
	|	WorkCenter,
	|	Begin
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FreeTime.WorkCenter AS WorkCenter,
	|	FreeTime.WorkCenter.WorkCenterType AS WorkCenterType,
	|	FreeTime.WorkCenter.MaximumLoad AS MaximumLoad,
	|	FreeTime.WorkCenter.WorkCenterType.ParallelLoad AS ParallelLoad,
	|	CASE
	|		WHEN FreeTime.WorkCenter.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SynchronousLoad,
	|	FreeTime.Begin AS StartOfShift,
	|	FreeTime.Ending AS EndOfShift,
	|	FreeTime.Time AS ShiftTime,
	|	ISNULL(BusyIntervalsGiven.Begin, DATETIME(1, 1, 1)) AS BusyStart,
	|	ISNULL(BusyIntervalsGiven.Ending, DATETIME(1, 1, 1)) AS BusyEnding,
	|	CASE
	|		WHEN BusyIntervalsGiven.Begin IS NOT NULL 
	|			THEN DATEDIFF(BusyIntervalsGiven.Begin, BusyIntervalsGiven.Ending, SECOND)
	|		ELSE 0
	|	END AS TimeTaken,
	|	CASE
	|		WHEN BusyIntervalsGiven.Begin IS NOT NULL 
	|			THEN DATEDIFF(BusyIntervalsGiven.Begin, BusyIntervalsGiven.Ending, SECOND)
	|		ELSE 0
	|	END * ISNULL(BusyIntervalsGiven.Load, 0) AS BusyTimeParallelLoading,
	|	ISNULL(BusyIntervalsGiven.Load, 0) AS Load,
	|	ISNULL(BusyIntervalsGiven.SetupSettings, VALUE(Catalog.SetupOptions.EmptyRef)) AS SetupSettings
	|FROM
	|	FreeTime AS FreeTime
	|		LEFT JOIN BusyIntervalsGiven AS BusyIntervalsGiven
	|		ON FreeTime.WorkCenter = BusyIntervalsGiven.WorkCenter
	|			AND (BusyIntervalsGiven.Begin >= FreeTime.Begin)
	|			AND (BusyIntervalsGiven.Begin < FreeTime.Ending)
	|
	|ORDER BY
	|	StartOfShift,
	|	BusyStart
	|TOTALS
	|	MAX(MaximumLoad),
	|	MAX(EndOfShift),
	|	MAX(ShiftTime),
	|	SUM(TimeTaken),
	|	SUM(BusyTimeParallelLoading),
	|	SUM(Load)
	|BY
	|	WorkCenter,
	|	StartOfShift";
	
	Return Result;
	
EndFunction

// Parameters:
// 	AvailableTime - ValueTable - LongDesc:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
// 	FillingValues - Structure, QueryResultSelection - LongDesc:
// * SynchronousLoad - Boolean -
// * WorkCenter - String -
// 	Begin - Date - 
// 	Ending - Date - 
// 	AvailableDownload - Number - 
// 	Time - Number - 
Procedure FixAvailableTime(AvailableTime, Val FillingValues, Val Begin, Val Ending, Val AvailableDownload=0, Val Time=0)
	
	NewRow = AvailableTime.Add();
	FillPropertyValues(NewRow, FillingValues);
	
	NewRow.Period = BegOfDay(Begin);
	NewRow.Begin = Begin;
	NewRow.Ending = Ending;
	
	If ValueIsFilled(Time) Then
		NewRow.Time = Time;
	Else
		NewRow.Time = NewRow.Ending - NewRow.Begin;
	EndIf;
	
	NewRow.AvailableDownload = AvailableDownload;
	
	If ValueIsFilled(NewRow.SetupSettings) 
		And (Not NewRow.ParallelLoad
		Or NewRow.AvailableDownload = NewRow.MaximumLoad) Then
		
		NewRow.SetupSettings = Catalogs.SetupOptions.EmptyRef();
		
	EndIf;
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	FillingData - Structure, QueryResultSelection - LongDesc:
// * SynchronousLoad - Boolean -
// * ParallelLoad - Boolean -
// * MaximumLoad - Number -
// * ShiftTime - Number -
// * WorkCenter - Arbitrary -
// 	TimeTaken - Number - LongDesc
// 	ShiftTime - Number - LongDesc
Procedure RecordBusyTimeByShift(PlanningParameters, Val FillingData, Val TimeTaken, Val ShiftTime)
	
	NewRow = PlanningParameters.BusyTimeByShift.Add();
	FillPropertyValues(NewRow, FillingData);
	NewRow.TimeTaken = TimeTaken;
	NewRow.ShiftTime = ShiftTime;
	
EndProcedure

Function FillInDataBeforeFollowingAvailableTime(Val PlanningParameters, AvailableTime)
	
	AvailableTimeCopy = AvailableTime.Copy();
	AvailableTimeCopy.Columns.Add("Free");
	AvailableTimeCopy.FillValues(True, "Free");
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	PostOperativeSchedule.Begin AS Begin,
	|	PostOperativeSchedule.Ending AS Ending,
	|	CAST(PostOperativeSchedule.WorkCenter AS Catalog.WorkCenters) AS WorkCenter
	|INTO IrrelevantOperations
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS PostOperativeSchedule
	|WHERE
	|	PostOperativeSchedule.TimetableModel = &TimetableModel
	|	AND PostOperativeSchedule.ThisIsOperationDeletion = TRUE
	|
	|INDEX BY
	|	Begin,
	|	Ending,
	|	WorkCenter
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Schedule.WorkCenter.WorkCenterType AS WorkCenterType,
	|	Schedule.WorkCenter AS WorkCenter,
	|	Schedule.Begin AS Begin,
	|	Schedule.Ending AS Ending,
	|	Schedule.Operation.SetupSettings AS SetupSettings,
	|	FALSE AS Free
	|FROM
	|	InformationRegister.PostOperativeSchedule2_2 AS Schedule
	|WHERE
	|	(Schedule.Begin BETWEEN &Begin AND &Ending
	|			OR Schedule.Ending BETWEEN &Begin AND &Ending)
	|	AND Schedule.WorkCenter IN(&WorkCenters)
	|	AND NOT (Schedule.Begin, Schedule.Ending, Schedule.WorkCenter) IN
	|				(SELECT
	|					IrrelevantOperations.Begin AS Begin,
	|					IrrelevantOperations.Ending AS Ending,
	|					IrrelevantOperations.WorkCenter AS WorkCenter
	|				FROM
	|					IrrelevantOperations)
	|	AND Schedule.Modeling = FALSE
	|	AND Schedule.LotQuantity <> (Schedule.Completed2 + Schedule.Skipped3 - Schedule.RepetitionIsRequired)
	|	AND (Schedule.CreatedOn = 0
	|			OR Schedule.CreatedOn <> (Schedule.Completed2 + Schedule.Skipped3 - Schedule.RepetitionIsRequired))";
	
	Query.SetParameter("TimetableModel", PlanningParameters.TimetableModel);
	Query.SetParameter("WorkCenters", PlanningParameters.ArrayOfWorkCenters);
	
	Boundaries = PlanningBoundaries(PlanningParameters);
	Query.SetParameter("Begin", Boundaries.Begin);
	Query.SetParameter("Ending",  Boundaries.Ending);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NwRw = AvailableTimeCopy.Add();
		FillPropertyValues(NwRw, Selection);
	EndDo;
	
	AvailableTimeCopy.Sort("WorkCenter, Begin Asc, Ending Asc", New CompareValues);
	
	AvailableTime.Clear();
	For Each String In AvailableTimeCopy Do
		
		If Not String.Free Then
			Continue;
		EndIf;
		
		NwRw = AvailableTime.Add();
		FillPropertyValues(NwRw, String);
		AvailableTimeToFillInPrecedenceData(AvailableTimeCopy, String, NwRw);
		AvailableTimeToFillInFollowingData(AvailableTimeCopy, String, NwRw);
		
	EndDo;
	
EndFunction

Procedure AvailableTimeToFillInPrecedenceData(Val Table, Val CurrentRow, NewRow)
	
	PrecedingLine = PrecedingRowOfAvailableInterval(Table, CurrentRow);
	
	If PrecedingLine = Undefined
		Or PrecedingLine.Free
		And (Not PrecedingLine.ParallelLoad
		Or PrecedingLine.AvailableDownload = PrecedingLine.MaximumLoad) Then 
		Return;
	EndIf;
	
	NewRow.PrecededByLoading = True;
	NewRow.SetupSettingsPreceding = PrecedingLine.SetupSettings;
	
EndProcedure

// Parameters:
// 	Table - See InitializeAvailableHardwareTime
// 	CurrentRow - ValueTableRow - Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * WorkCenter - String, CatalogRef.WorkCenters -
// * Begin - Date -
// * Ending - Date -
// * SetupSettings - CatalogRef.SetupOptions -
// Returns:
// 	ValueTableRow - 
Function PrecedingRowOfAvailableInterval(Table, CurrentRow)
	
	Result = Undefined;
	
	If CurrentRow.ParallelLoad Then
		
		IndexOfPrevious = Table.IndexOf(CurrentRow) - 1;
		While True Do
			
			If IndexOfPrevious >= 0 Then
				
				PrecedingLine = Table[IndexOfPrevious];
				If PrecedingLine.WorkCenter = CurrentRow.WorkCenter Then
					
					If PrecedingLine.Begin = CurrentRow.Begin
						And PrecedingLine.Ending = CurrentRow.Ending Then
						
						IndexOfPrevious = IndexOfPrevious - 1;
						
					Else
						
						Result = PrecedingLine;
						Break;
						
					EndIf;
					
				Else
					Break;
				EndIf;
				
			Else
				Break;
			EndIf;
			
		EndDo;
		
	Else
		
		IndexOfPrevious = Table.IndexOf(CurrentRow) - 1;
		If IndexOfPrevious >= 0 Then
			
			PrecedingLine = Table[IndexOfPrevious];
			If PrecedingLine.WorkCenter = CurrentRow.WorkCenter Then
				Result = PrecedingLine;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AvailableTimeToFillInFollowingData(Val Table, Val CurrentRow, NewRow)
	
	NextRow = NextLineOfAvailableInterval(Table, CurrentRow);
	
	If NextRow = Undefined
		Or NextRow.Free
		And (Not NextRow.ParallelLoad
		Or NextRow.AvailableDownload = NextRow.MaximumLoad) Then 
		Return;
	EndIf;
	
	NewRow.DownloadFollows = True;
	NewRow.SetupSettingsFollowing = NextRow.SetupSettings;
	
EndProcedure

Function NextLineOfAvailableInterval(Table, CurrentRow)
	
	Result = Undefined;
	InvalidIndex = Table.Count();
	
	If CurrentRow.ParallelLoad Then
		
		IndexOfFollowing_ = Table.IndexOf(CurrentRow)+1;
		While True Do
			
			If IndexOfFollowing_ < InvalidIndex Then
				
				NextRow = Table[IndexOfFollowing_];
				If NextRow.WorkCenter = CurrentRow.WorkCenter Then
					
					If NextRow.Begin = CurrentRow.Begin
						And NextRow.Ending = CurrentRow.Ending Then
						
						IndexOfFollowing_ = IndexOfFollowing_ + 1;
						
					Else
						
						Result = NextRow;
						Break;
						
					EndIf;
					
				Else
					Break;
				EndIf;
				
			Else
				Break;
			EndIf;
			
		EndDo;
		
	Else
		
		IndexOfFollowing_ = Table.IndexOf(CurrentRow) + 1;
		If IndexOfFollowing_ < InvalidIndex Then
			NextRow = Table[IndexOfFollowing_];
			If NextRow.WorkCenter = CurrentRow.WorkCenter Then
				Result = NextRow;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region PlanningScenarios

Procedure ModifyPlanningParametersAccordingToPlanningScenario(PlanningParameters)
	
	PlanningScenario = PlanningParameters.PlanningScenario;
	
	If ValueIsFilled(PlanningScenario) Then
		
		AttributesStructure1 = New Structure("WorkCentersAdd, WorkCentersExclude, WorkSchedules");
		ModelData = Common.ObjectAttributesValues(PlanningScenario, AttributesStructure1);
		
		ReduceEquipmentFleet(PlanningParameters, ModelData);
		ChangeEquipmentSchedules(PlanningParameters, ModelData);
		IncreaseEquipmentFleet(PlanningParameters, ModelData);
		
		CalculateRanksOfWorkCenters(PlanningParameters, PlanningParameters.RanksOfWorkCenters);
		
	Else
		Return;
	EndIf;
	
EndProcedure

Procedure IncreaseEquipmentFleet(PlanningParameters, Val ModelData)
	
	TableWorkCentersAdd = ModelData.WorkCentersAdd.Unload();
	If TableWorkCentersAdd.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In TableWorkCentersAdd Do
		
		IncreaseEquipmentFleetInTableOfWorkCenters(
			PlanningParameters, String.Substitute, String.Count);
		
		IncreaseEquipmentFleetInTablesAvailableTimeAndBusyShiftTime(
			PlanningParameters, String.WorkCenterType, String.Substitute, String.Count);
		
	EndDo;
	
	SortTableAvailableTime(PlanningParameters.AvailableTime);
	
EndProcedure

Function NameOfAdditionalRC(Substitute, SequenceNumber)

	AnalogName = Common.ObjectAttributeValue(Substitute, "Description");
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 (thêm %2)';
			|ru = '%1 (доп. %2)';
			|en = '%1 (addit.%2)'; fa = '%1 (addit.%2)';
			|it = '%1 (agg. %2)';
			|pl = '%1 (dod. %2)';
			|tr = '%1 (ek %2)'"),
		AnalogName,
		SequenceNumber);
		
EndFunction

Procedure IncreaseEquipmentFleetInTableOfWorkCenters(PlanningParameters, Val Substitute, NumberOfRC)
	
	FillingValues = PlanningParameters.TableOfWorkCenters.Find(Substitute, "WorkCenter");
	
	If Not FillingValues = Undefined Then
		
		For Cnt = 1 To NumberOfRC Do
			
			NameOfAddOn = NameOfAdditionalRC(Substitute, Cnt);
		 
			NewRow = PlanningParameters.TableOfWorkCenters.Add();
			FillPropertyValues(NewRow, FillingValues);
			NewRow.WorkCenter = NameOfAddOn;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure IncreaseEquipmentFleetInTablesAvailableTimeAndBusyShiftTime(
		PlanningParameters, Val WorkCenterType, Val Substitute, Val NumberOfRC)
	
	AvailableAnalogTime = AvailableAnalogWorkCenterTime(PlanningParameters, Substitute);
	ImportParameters = ParametersOfParallelLoadingOfVRC(PlanningParameters, WorkCenterType);
	FillingValues = New Structure;
	
	For Cnt = 1 To NumberOfRC Do
		
		NameOfAddOn = NameOfAdditionalRC(Substitute, Cnt);
		For Each String In AvailableAnalogTime Do
			
			FillingValues.Insert("WorkCenterType", WorkCenterType);
			FillingValues.Insert("WorkCenter", NameOfAddOn);
			FillingValues.Insert("StartOfShift", String.Begin);
			FillingValues.Insert("ShiftTime", String.Time);
			FillingValues.Insert("MaximumLoad", ImportParameters.MaximumLoad);
			FillingValues.Insert("ParallelLoad", ImportParameters.ParallelLoad);
			FillingValues.Insert("SynchronousLoad", ImportParameters.SynchronousLoad);
			
			FixAvailableTime(
				PlanningParameters.AvailableTime,
				FillingValues,
				String.Begin,
				String.Ending,
				ImportParameters.MaximumLoad,
				String.Time);
				
			If Not ImportParameters.ParallelLoad Then
				ShiftTime = String.Time;
			Else
				ShiftTime = String.Time * ImportParameters.MaximumLoad;
			EndIf;
			
			RecordBusyTimeByShift(PlanningParameters, FillingValues, 0, ShiftTime);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function AvailableAnalogWorkCenterTime(Val PlanningParameters, Val Substitute)
	
	Boundaries = PlanningBoundaries(PlanningParameters);
	ArrayOfShoppingCenters = New Array;
	ArrayOfShoppingCenters.Add(Substitute);
	
	Result = AvailableTimeOfWorkCentersAccordingToSchedule(Boundaries.Begin, Boundaries.Ending, ArrayOfShoppingCenters);
	
	Return Result;
	
EndFunction

Procedure ReduceEquipmentFleet(PlanningParameters, Val ModelData)

	TableWorkCentersExclude = ModelData.WorkCentersExclude.Unload();
	If TableWorkCentersExclude.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In TableWorkCentersExclude Do
		
		ReduceFleetOfEquipmentInTableOfWorkCenters(PlanningParameters, String.WorkCenter);
		ReduceEquipmentFleetInTableAvailableTime(PlanningParameters, String.WorkCenter);
		ReduceEquipmentFleetInBusyTimeByShiftTable(PlanningParameters, String.WorkCenter);
		
	EndDo;
	
	SortTableAvailableTime(PlanningParameters.AvailableTime);
	
EndProcedure

Procedure ReduceFleetOfEquipmentInTableOfWorkCenters(PlanningParameters, Val WorkCenter)
	
	SearchCondition = New Structure("WorkCenter", WorkCenter);
	DeleteTableRowsByCondition(PlanningParameters.TableOfWorkCenters, SearchCondition);
	
EndProcedure

Procedure ReduceEquipmentFleetInTableAvailableTime(PlanningParameters, Val WorkCenter)
	
	SearchCondition = New Structure("WorkCenter", WorkCenter);
	DeleteTableRowsByCondition(PlanningParameters.AvailableTime, SearchCondition);
	
EndProcedure

Procedure ReduceEquipmentFleetInBusyTimeByShiftTable(PlanningParameters, Val WorkCenter)
	
	SearchCondition = New Structure("WorkCenter", WorkCenter);
	DeleteTableRowsByCondition(PlanningParameters.BusyTimeByShift, SearchCondition);
	
EndProcedure

Procedure ChangeEquipmentSchedules(PlanningParameters, Val ModelData)

	TableOfWorkSchedules = ModelData.WorkSchedules.Unload(); // ValueTable - 
	If TableOfWorkSchedules.Count() = 0 Then
		Return;
	EndIf;
		
	For Each String In TableOfWorkSchedules Do
		
		Boundaries = PlanningBoundaries(PlanningParameters);
		WorkSchedule = ScheduleOfWorkOnSchedule(String.Schedule, Boundaries.Begin, Boundaries.Ending);
		WorkCenters = WorkCentersForScheduleChanges(PlanningParameters, TableOfWorkSchedules, String);
		
		For Each WorkCenter In WorkCenters Do
			
			WorkCenterType = WorkCenterType(PlanningParameters, WorkCenter);
			ImportParameters = ParametersOfParallelLoadingOfVRC(PlanningParameters, WorkCenter);
			
			ReduceEquipmentFleetInTableAvailableTime(PlanningParameters, WorkCenter);
			ReduceEquipmentFleetInBusyTimeByShiftTable(PlanningParameters, WorkCenter);
			
			For Each WriteTimetable In WorkSchedule Do
				
				FillingValues = New Structure;
				FillingValues.Insert("WorkCenterType", WorkCenterType);
				FillingValues.Insert("WorkCenter", WorkCenter);
				FillingValues.Insert("StartOfShift", 	WriteTimetable.Begin);
				FillingValues.Insert("ShiftTime", 	WriteTimetable.Time);
				FillingValues.Insert("MaximumLoad", ImportParameters.MaximumLoad);
				FillingValues.Insert("ParallelLoad", ImportParameters.ParallelLoad);
				FillingValues.Insert("SynchronousLoad", ImportParameters.SynchronousLoad);
				
				FixAvailableTime(
				PlanningParameters.AvailableTime,
				FillingValues,
				WriteTimetable.Begin,
				WriteTimetable.Ending,
				ImportParameters.MaximumLoad,
				WriteTimetable.Time);
				
				If Not ImportParameters.ParallelLoad Then
					ShiftTime = WriteTimetable.Time;
				Else
					ShiftTime = WriteTimetable.Time * ImportParameters.MaximumLoad;
				EndIf;
				RecordBusyTimeByShift(PlanningParameters, FillingValues, 0, ShiftTime);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	SortTableAvailableTime(PlanningParameters.AvailableTime);
	
EndProcedure

Function ScheduleOfWorkOnSchedule(Schedule, Begin, Ending)
	
	Calendars = New Array;
	Calendars.Add(Schedule);
	
	Result = ProductionPlanning.ScheduleOfWorkOnSchedule(
		Calendars, Begin, Ending);
		
	Result.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Time", New TypeDescription("Number", New NumberQualifiers));
	
	Result.Columns.ScheduleDate.Name = "Period";
	
	For Each String In Result Do
		
		String.Begin = String.Period + DateTimeInSeconds(String.BeginTime);
		String.Ending = String.Begin + String.Duration;
		String.Time = String.Duration;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function WorkCentersForScheduleChanges(Val PlanningParameters, Val ModelSettings, Val CurrentSetting)
	
	Result = New Array;
	
	If ValueIsFilled(CurrentSetting.WorkCenter) Then
		Result = WorkCentersOnMeasurementValue(PlanningParameters, CurrentSetting.WorkCenter);
	ElsIf ValueIsFilled(CurrentSetting.WorkCenterType) Then
		WorkCenters = WorkCentersOnMeasurementValue(PlanningParameters, CurrentSetting.WorkCenterType);
		
		For Each WorkCenter In WorkCenters Do
			ThereIsClarifyingLine = False;
			For Each Setting In ModelSettings Do
				If Setting = CurrentSetting Then
					Continue;
				ElsIf Setting.WorkCenter = WorkCenter Then
					ThereIsClarifyingLine = True;
					Break;
				EndIf;
			EndDo;
			If Not ThereIsClarifyingLine Then
				Result.Add(WorkCenter);
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(CurrentSetting.Department) Then
		WorkCenters = WorkCentersOnMeasurementValue(PlanningParameters, CurrentSetting.Department);
		
		For Each WorkCenter In WorkCenters Do
			ThereIsClarifyingLine = False;
			WorkCenterType = WorkCenterType(PlanningParameters, WorkCenter);
			For Each Setting In ModelSettings Do
				If Setting = CurrentSetting Then
					Continue;
				ElsIf Setting.WorkCenter = WorkCenter
					Or (Setting.WorkCenterType = WorkCenterType
					And Not ValueIsFilled(Setting.WorkCenter)) Then
					ThereIsClarifyingLine = True;
					Break;
				EndIf;
			EndDo;
			If Not ThereIsClarifyingLine Then
				Result.Add(WorkCenter);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region SelectionOfWorkCenters

Function CalculateOperationPlacementParameters(PlanningParameters, Operation, RCSelectionRule, DirectPlacement)
	
	If ValueIsFilled(Operation.WorkCenter) Then
		
		TableOfAlternatives = InitializeAlternativeRCTable();
		
		WorkCenters = WorkCentersOnMeasurementValue(PlanningParameters, Operation.WorkCenter);
		If ValueIsFilled(WorkCenters) Then
			
			// First, we will exclude the RC, which do not suit us for the maximum load.
			WorkCenters = CheckAndExcludeWorkCentersByLoading(PlanningParameters, WorkCenters, Operation);
			
			If WorkCenters = Undefined Then
				Return Undefined;
			EndIf;
			
			For Each WorkCenter In WorkCenters Do
				
				PlacementParameters = SelectPlacementIntervalsOnWorkCenter(PlanningParameters, Operation, WorkCenter, DirectPlacement);
				
				If PlacementParameters = Undefined Then
					Continue;
				Else
					NewRow = TableOfAlternatives.Add();
					FillPropertyValues(NewRow, PlacementParameters);
				EndIf;
				
			EndDo;
			
			If ValueIsFilled(TableOfAlternatives) Then
				
				Result = InitializePlacementParameters();
				BetterAlternative = BestWorkCenterToAccommodate(PlanningParameters, TableOfAlternatives, RCSelectionRule);
				FillPropertyValues(Result, BetterAlternative);
				
			Else
				Result = Undefined;
			EndIf;
			
		Else
			
			FixWorkCentersNotDefinedError(PlanningParameters, Operation.WorkCenter);
			
		EndIf;
		
	Else
		
		Result = ParametersForPlacingOperationWithoutWorkCenter(PlanningParameters, Operation, WorkCenter, DirectPlacement);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function CheckAndExcludeWorkCentersByLoading(PlanningParameters, WorkCenters, Operation)
	
	If Not ValueIsFilled(Operation.Load) Then
		Return WorkCenters; // No verification is required.
	EndIf;
	
	ResultWorkCenters = New Array;
	
	For Each WorkCenter In WorkCenters Do
		
		BankingDetailsWorkCenter = Common.ObjectAttributesValues(WorkCenter, "WorkCenterType.ParallelLoad, MaximumLoad");
		
		If BankingDetailsWorkCenter.WorkCenterTypeParallelLoad 
			And Operation.Load > BankingDetailsWorkCenter.MaximumLoad  Then
			Continue;
		EndIf;
		
		ResultWorkCenters.Add(WorkCenter);
		
	EndDo;	
	
	If ResultWorkCenters.Count() = 0 Then // No RC is suitable for maximum load.
		FixErrorWorkCentersDidNotFitLoad(PlanningParameters, Operation.WorkCenter, Operation);
		Return Undefined;
	Else
		Return ResultWorkCenters;
	EndIf;
	
EndFunction

Function SelectPlacementIntervalsOnWorkCenter(PlanningParameters, Operation, WorkCenter, DirectPlacement)
	
	Result = InitializePlacementParameters();
	PickingParameters = InitializeParametersForSelectingPlacementIntervals(PlanningParameters, Operation, WorkCenter, DirectPlacement);
	
	ZeroTime = Operation.TimeToPlace = 0;
	While PickingParameters.TimePlan > 0 Or ZeroTime Do
		
		ZeroTime = False;
		Cancel = False;
		SelectIntervalAvailableForPlacement(PlanningParameters, PickingParameters, Result, Cancel);
		If Cancel Then
			Return Undefined;
		EndIf;
		
		DeterminePlacementInterval(PlanningParameters, PickingParameters, Result, Cancel);
		If Cancel Then
			Continue;
		EndIf;
		
		DeterminePlacementIntervalAuxiliary(PlanningParameters, PickingParameters, Result, Cancel);
		If Cancel Then
			Continue;
		EndIf;
		
		SavePlacementInterval(PlanningParameters, PickingParameters, Result);
		
	EndDo;
	
	Result.WorkCenter = WorkCenter;
	CalculatePlacementOfOperationOnRC(PlanningParameters, Result);
	
	RestoreOriginalPlanningParameters(PlanningParameters, PickingParameters);
	
	Return Result;
	
EndFunction

Procedure SelectIntervalAvailableForPlacement(Val PlanningParameters, PickingParameters, PlacementParameters, Cancel)
	
	PickingParameters.AvailableInterval = AvailablePlacementInterval(PlanningParameters, PickingParameters, PlacementParameters);
	
	If PickingParameters.AvailableInterval = Undefined Then
		
		FIXErrorUnavailableOSNRegionalServiceCenter(PlanningParameters, PickingParameters);
		Cancel = True;
		
	ElsIf PickingParameters.FirstInterval Then
		
		ChangeoverTime = OperationChangeoverTime(PlanningParameters, PickingParameters.AvailableInterval, PickingParameters.Operation);
		
		PickingParameters.ChangeoverTime = ChangeoverTime;
		PickingParameters.TimePlan =  PickingParameters.TimePlan + ChangeoverTime;
		PickingParameters.FirstInterval = False;
		
		PlacementParameters.ChangeoverTime = ChangeoverTime;
		
	EndIf;
	
EndProcedure

Procedure DeterminePlacementInterval(Val PlanningParameters, PickingParameters, PlacementParameters, Cancel)
	
	PlacementInterval = OperationPlacementInterval(PlanningParameters, PickingParameters);
	
	If PlacementInterval = Undefined Then
		
		ClearPlacementAndSelectionParameters(PlanningParameters, PickingParameters, PlacementParameters, False);
		Cancel = True;
		
	Else
		
		PickingParameters.PlacementInterval = PlacementInterval;
		
	EndIf;
	
EndProcedure

Procedure DeterminePlacementIntervalAuxiliary(Val PlanningParameters, PickingParameters, PlacementParameters, Cancel)
	
	If PickingParameters.PlaceAuxiliary Then
		
		AccommodationIsPossible = ItIsPossibleToPlaceAuxiliaryRCOnInterval(PlanningParameters, PickingParameters, PlacementParameters);
		
		If AccommodationIsPossible Then
				
			PickingParameters.InaccessibleAuxiliaryRC.Clear();
			
		Else
			
			FillInUnavailableAuxiliaryRC(PlacementParameters, PickingParameters.InaccessibleAuxiliaryRC);
			ClearPlacementAndSelectionParameters(PlanningParameters, PickingParameters, PlacementParameters, AccommodationIsPossible);
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SavePlacementInterval(Val PlanningParameters, PickingParameters, PlacementParameters)
	
	ChangePlanningParameters = True;
	If LastPlacementInterval(PickingParameters) Then
		
		ModifySelectionParametersWhileMaintainingInterval(PickingParameters, True);
		SaveFoundInterval(PlacementParameters, PickingParameters.AvailableInterval, PickingParameters.PlacementInterval);
		
	Else
		
		If PlacementOfIntermediateIntervalIsAcceptable(PlanningParameters, PickingParameters) Then
			
			ModifySelectionParametersWhileMaintainingInterval(PickingParameters, False);
			SaveFoundInterval(PlacementParameters, PickingParameters.AvailableInterval, PickingParameters.PlacementInterval);
			
		Else
			
			ClearPlacementAndSelectionParameters(PlanningParameters, PickingParameters, PlacementParameters,, False);
			ChangePlanningParameters = False;
			
		EndIf;
		
	EndIf;
	
	If ChangePlanningParameters Then
		
		If ValueIsFilled(PickingParameters.PlacementInterval.Load) Then
			BusyTime = PickingParameters.PlacementInterval.TimePlan * PickingParameters.PlacementInterval.Load;
		Else
			BusyTime = PickingParameters.PlacementInterval.TimePlan;
		EndIf;
		
		ReflectBusyTimeByShift(
			PlanningParameters,
			PickingParameters.AvailableInterval,
			PickingParameters.WorkCenter,
			BusyTime);
		
		CalculateIndexOfNextAvailableInterval(PlanningParameters, PickingParameters);
		
		EmptyIntervals = New Array;
		FixAvailableTime_(
			PlanningParameters,
			PickingParameters.Operation,
			PickingParameters.AvailableInterval,
			EmptyIntervals,
			PickingParameters.PlacementInterval);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	PickingParameters - See InitializeParametersForSelectingPlacementIntervals
Procedure CalculateIndexOfNextAvailableInterval(PlanningParameters, PickingParameters)
	
	AvailableTime = PlanningParameters.AvailableTime;
	AvailableInterval = PickingParameters.AvailableInterval;
	PlacementInterval = PickingParameters.PlacementInterval;
	CurrentIndex = AvailableTime.IndexOf(AvailableInterval);
	
	If AvailableInterval.ParallelLoad Then
		
		AvailableDownload = AvailableInterval.AvailableDownload - PlacementInterval.Load;
		If PlacementInterval.TimePlan = AvailableInterval.Time Then
			
			// The entire available interval is occupied.
			If AvailableDownload >= PickingParameters.LoadingMultiplicity
				And PickingParameters.UploadToReceivedAvailableIntervalIsAllowed Then
				NextIndex = CurrentIndex;
			Else
				If PickingParameters.DirectPlacement Then
					NextIndex = CurrentIndex + 1;
				Else
					NextIndex = CurrentIndex - 1;
				EndIf;
			EndIf;
			
		Else
			
			If AvailableInterval.Begin = PlacementInterval.Begin Then
				
				// The left part of the available interval is occupied.
				If AvailableDownload = 0 Then
					If PickingParameters.DirectPlacement Then
						NextIndex = CurrentIndex;
					Else
						NextIndex = CurrentIndex - 1;
					EndIf;
				Else
					If AvailableDownload >= PickingParameters.LoadingMultiplicity
						And PickingParameters.UploadToReceivedAvailableIntervalIsAllowed Then
						NextIndex = CurrentIndex;
					Else
						If PickingParameters.DirectPlacement Then
							NextIndex = CurrentIndex + 1;
						Else
							NextIndex = CurrentIndex - 1;
						EndIf;
					EndIf;
				EndIf;
				
			ElsIf AvailableInterval.Ending = PlacementInterval.Ending Then
				
				// The right part of the available interval is occupied.
				If AvailableDownload = 0 Then
					If PickingParameters.DirectPlacement Then
						NextIndex = CurrentIndex + 1;
					Else
						NextIndex = CurrentIndex;
					EndIf;
				Else
					If AvailableDownload >= PickingParameters.LoadingMultiplicity
						And PickingParameters.UploadToReceivedAvailableIntervalIsAllowed Then
						NextIndex = CurrentIndex + 1;
					Else
						If PickingParameters.DirectPlacement Then
							NextIndex = CurrentIndex + 2;
						Else
							NextIndex = CurrentIndex;
						EndIf;
					EndIf;
				EndIf;
				
			Else
				
				// The part inside the available interval is occupied.
				If AvailableDownload = 0 Then
					If PickingParameters.DirectPlacement Then
						NextIndex = CurrentIndex + 1;
					Else
						NextIndex = CurrentIndex;
					EndIf;
				Else
					If AvailableDownload >= PickingParameters.LoadingMultiplicity
						And PickingParameters.UploadToReceivedAvailableIntervalIsAllowed Then
						NextIndex = CurrentIndex + 1;
					Else
						If PickingParameters.DirectPlacement Then
							NextIndex = CurrentIndex + 2;
						Else
							NextIndex = CurrentIndex;
						EndIf;
					EndIf;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		
		If PickingParameters.DirectPlacement Then
			NextIndex = CurrentIndex + 1;
		Else
			NextIndex = CurrentIndex - 1;
		EndIf;
		
	EndIf;
	
	PickingParameters.Insert("IndexOfNextAvailableInterval", NextIndex);
	
EndProcedure

Function LastPlacementInterval(PickingParameters)
	
	AllTimesPosted = (PickingParameters.PlacementInterval.TimePlan = PickingParameters.TimePlan);
	
	If PickingParameters.ParallelLoad Then
		
		EntireDownloadIsPosted = (PickingParameters.PlacementInterval.Load = PickingParameters.Load)
								And (PickingParameters.ParallelLoadingOptions.Count() = 1);
		Result = AllTimesPosted And EntireDownloadIsPosted;
		
	Else
		
		Result = AllTimesPosted;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function PlacementOfIntermediateIntervalIsAcceptable(PlanningParameters, PickingParameters)
	
	Result = True;
	
	AllTimesPosted = (PickingParameters.PlacementInterval.TimePlan = PickingParameters.TimePlan);
	If Not AllTimesPosted Then
	
		If NextIntervalIsLoaded(PlanningParameters, PickingParameters, PickingParameters.AvailableInterval) Then
			
			Result = False;
			
		Else
			
			ExecutionIsInterrupted = OperationIsInterrupted(PlanningParameters, PickingParameters, PickingParameters.AvailableInterval);
			If ExecutionIsInterrupted Then
				
				InterruptionIsAcceptable = InterruptingOperationIsAcceptable(PlanningParameters, PickingParameters);
				If Not InterruptionIsAcceptable Then
					Result = False;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function NextIntervalIsLoaded(PlanningParameters, PickingParameters, AvailableInterval)
	
	If PickingParameters.DirectPlacement Then
		DownloadFollows = AvailableInterval.DownloadFollows;
	Else
		DownloadFollows = AvailableInterval.PrecededByLoading;
	EndIf;
	
	If DownloadFollows Then
		
		If PickingParameters.ParallelLoad Then
			
			NextInterval_ = NextAvailableIntervalByIndex(PlanningParameters, AvailableInterval, PickingParameters.DirectPlacement);
			
			If NextInterval_ = Undefined Then
				Result = True;
			Else
				
				If PickingParameters.LoadingMultiplicity > NextInterval_.AvailableDownload Then
					Result = True;
				Else
					Result = False;
				EndIf;
				
			EndIf;
			
		Else
			Result = True;
		EndIf;
		
	Else
		Result = False;		
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationIsInterrupted(PlanningParameters, PickingParameters, AvailableInterval)
	
	NextInterval_ = NextAvailableIntervalByIndex(PlanningParameters, AvailableInterval, PickingParameters.DirectPlacement);
	
	If NextInterval_ = Undefined Then
		
		Result = True;
		
	Else
		
		If PickingParameters.DirectPlacement Then
			
			If AvailableInterval.Ending = NextInterval_.Begin Then
				Result = False;
			Else
				Result = True;
			EndIf;
			
		Else
			
			If AvailableInterval.Begin = NextInterval_.Ending Then
				Result = False;
			Else
				Result = True;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	CurrentInterval - ValueTableRow, Arbitrary - LongDesc:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
// 	DirectPlacement - Boolean - LongDesc
// Returns:
// 	Undefined, ValueTableRow - Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
Function NextAvailableIntervalByIndex(PlanningParameters, CurrentInterval, DirectPlacement)
	
	AvailableTime = PlanningParameters.AvailableTime;
	CurrentIndex = AvailableTime.IndexOf(CurrentInterval);
	MaxIndex = AvailableTime.Count();
	
	NextIndex = Undefined;
	If DirectPlacement Then
		NextIndex = CurrentIndex + 1;
		If NextIndex = MaxIndex Then
			NextIndex = Undefined;
		EndIf;
	Else
		NextIndex = CurrentIndex - 1;
		If NextIndex = -1 Then
			NextIndex = Undefined;
		EndIf;
	EndIf;
	
	If NextIndex = Undefined Then
		Result = Undefined;
	Else
		NextInterval_ = AvailableTime[NextIndex];
		
		If NextInterval_.WorkCenter = CurrentInterval.WorkCenter Then
			Result = NextInterval_;
		Else
			Result = Undefined;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ModifySelectionParametersWhileMaintainingInterval(PickingParameters, Val LastInterval)
	
	If ValueIsFilled(PickingParameters.ChangeoverTime) Then
		
		PickingParameters.PlacementInterval.ChangeoverTime = Min(PickingParameters.ChangeoverTime, PickingParameters.PlacementInterval.TimePlan);
		PickingParameters.ChangeoverTime = PickingParameters.ChangeoverTime - PickingParameters.PlacementInterval.ChangeoverTime;
		
	EndIf;
	
	If LastInterval Then
		
		PickingParameters.TimePlan = 0;
		PickingParameters.Load = 0;
		
	Else
		
		If PickingParameters.ParallelLoad Then
			SetPostedTimeAndDownloadInSelectionParameters(PickingParameters);
		Else
			SetPostedTimeInSelectionParameters(PickingParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SetPostedTimeInSelectionParameters(PickingParameters)
	
	PickingParameters.TimePlan = PickingParameters.TimePlan - PickingParameters.PlacementInterval.TimePlan;
	
EndProcedure

Procedure SetPostedTimeAndDownloadInSelectionParameters(PickingParameters)
	
	CurrentParameter = PickingParameters.ParallelLoadingOptions[0];
	
	If PickingParameters.PlacementInterval.TimePlan = PickingParameters.TimePlan Then
		
		// The "clock cycle" of parallel loading is not interrupted by the unavailability interval.
		If PickingParameters.PlacementInterval.Load = PickingParameters.Load Then
			PickingParameters.ParallelLoadingOptions.Delete(CurrentParameter);
			CurrentParameter = PickingParameters.ParallelLoadingOptions[0];
		Else
			CurrentParameter.Load = CurrentParameter.Load - PickingParameters.PlacementInterval.Load;
			CurrentParameter.TimePlan = CurrentParameter.TimePlan - CurrentParameter.SetupTime;
			CurrentParameter.SetupTime = 0;
			CurrentParameter.ParallelLoadTime = New UUID;
		EndIf;
		
	Else
		
		If PickingParameters.PlacementInterval.Load = PickingParameters.Load Then
			
			CurrentParameter.LoadingMultiplicity = PickingParameters.PlacementInterval.Load;
			CurrentParameter.TimePlan = PickingParameters.TimePlan - PickingParameters.PlacementInterval.TimePlan;
			CurrentParameter.UploadToReceivedAvailableIntervalIsAllowed = False;
			
		Else
			
			// The "clock cycle" of parallel loading is interrupted by an unavailability interval.
			NewParameter1 = PickingParameters.ParallelLoadingOptions.Insert(0);
			FillPropertyValues(NewParameter1, CurrentParameter);
			NewParameter1.Load = PickingParameters.PlacementInterval.Load;
			NewParameter1.LoadingMultiplicity = PickingParameters.PlacementInterval.Load;
			NewParameter1.TimePlan = PickingParameters.TimePlan - PickingParameters.PlacementInterval.TimePlan;
			NewParameter1.UploadToReceivedAvailableIntervalIsAllowed = False;
			
			CurrentParameter.Load = CurrentParameter.Load - NewParameter1.Load;
			CurrentParameter.TimePlan = CurrentParameter.TimePlan - CurrentParameter.SetupTime;
			CurrentParameter.SetupTime = 0;
			CurrentParameter.ParallelLoadTime = New UUID;
			
			CurrentParameter = NewParameter1;
			
		EndIf;
		
	EndIf;
	
	FillPropertyValues(
		PickingParameters,
		CurrentParameter,
		"Load, LoadingMultiplicity, TimePlan, ParallelLoadTime, UploadToReceivedAvailableIntervalIsAllowed");
	
EndProcedure

// Parameters:
// 	PlacementParameters - See InitializePlacementParameters
// 	AvailableInterval - ValueTableRow - See InitializeAvailableHardwareTime Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
// 	PlacementInterval - See InitializePlacementInterval
Procedure SaveFoundInterval(PlacementParameters, Val AvailableInterval, Val PlacementInterval)
	
	PlacementParameters.Intervals.Add(PlacementInterval);
	
	CacheAvailableInterval_(PlacementParameters, AvailableInterval, PlacementInterval);
	
	If ValueIsFilled(PlacementParameters.Begin) Then
		PlacementParameters.Begin = Min(PlacementParameters.Begin, PlacementInterval.Begin);
	Else
		PlacementParameters.Begin = PlacementInterval.Begin;
	EndIf;
	
	If ValueIsFilled(PlacementParameters.Ending) Then
		PlacementParameters.Ending = Max(PlacementParameters.Ending, PlacementInterval.Ending);
	Else
		PlacementParameters.Ending = PlacementInterval.Ending;
	EndIf;
	
EndProcedure

Function AvailablePlacementInterval(Val PlanningParameters, PickingParameters, PlacementParameters)
	
	If PickingParameters.AvailableInterval = Undefined Then
		
		Result = PrimaryAvailablePlacementInterval(PlanningParameters, PickingParameters);
		
	Else
		
		Result = NextAvailablePlacementInterval(PlanningParameters, PickingParameters, PlacementParameters);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function PrimaryAvailablePlacementInterval(PlanningParameters, PickingParameters)
	
	Boundaries = PlanningBoundaries(PlanningParameters);
	TimeOfPlacement = PickingParameters.TimeOfPlacement;
	DirectPlacement = PickingParameters.DirectPlacement;
		
	SearchCondition = New Structure;
    SearchCondition.Insert("WorkCenter", PickingParameters.WorkCenter);
    
	Result = Undefined;
	While True Do
		
		SearchCondition.Insert("Period", BegOfDay(TimeOfPlacement));
		FoundRows = FindRowsInTableWhileMaintainingOrder(PlanningParameters.AvailableTime, SearchCondition);
		
		If ValueIsFilled(FoundRows) Then
			
			If PickingParameters.DirectPlacement Then
				IndexOf = 0;
			Else
				IndexOf = FoundRows.Count()-1;
			EndIf;
			
			For It = 1 To FoundRows.Count() Do
				
				Interval = FoundRows[IndexOf];
				IntervalIsSuitable = IntervalIsSuitableForPlacingOperation(PlanningParameters, Interval, PickingParameters);
				If IntervalIsSuitable Then
					Result = Interval;
					Break;
				Else
					If PickingParameters.DirectPlacement Then
						IndexOf = IndexOf + 1;
					Else
						IndexOf = IndexOf - 1;
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Result = Undefined Then
			
			If DirectPlacement Then
				
				TimeOfPlacement = EndOfDay(TimeOfPlacement) + 1;
				
				If Not TimeOfPlacement > Boundaries.Ending Then
					Continue;
				Else
					Break;
				EndIf;
			Else
				
				TimeOfPlacement = BegOfDay(TimeOfPlacement) - 1;
				If Not TimeOfPlacement < Boundaries.Begin Then
					Continue;
				Else
					Break;
				EndIf;
			EndIf;
			
		Else
			Break;			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function NextAvailablePlacementInterval(PlanningParameters, PickingParameters, PlacementParameters)
	
	Result = Undefined;
	
	CurrentIndex = PickingParameters.IndexOfNextAvailableInterval;
	MaxIndex = PlanningParameters.AvailableTime.Count();
	
	While True Do
		
		If CurrentIndex >= MaxIndex
			Or CurrentIndex = -1 Then
			Break;
		EndIf;
		
		NextInterval_ = PlanningParameters.AvailableTime[CurrentIndex];
		If NextInterval_.WorkCenter = PickingParameters.WorkCenter Then
			
			Suitable = IntervalIsSuitableForPlacingOperation(PlanningParameters, NextInterval_, PickingParameters);
			If Suitable Then
				Result = NextInterval_;
				Break;
			ElsIf Not PickingParameters.Property("FixedBatch") Then
				ClearPlacementAndSelectionParameters(PlanningParameters, PickingParameters, PlacementParameters);
			EndIf;
			
		Else
			Break;			
		EndIf;
		
		If PickingParameters.DirectPlacement Then
			CurrentIndex = CurrentIndex + 1;
		Else
			CurrentIndex = CurrentIndex - 1;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function IntervalIsSuitableForPlacingOperation(PlanningParameters, AvailableInterval, PickingParameters)
	
	Result = True;
	
	ExecutionIsInterrupted = AvailableInterval.Time < PickingParameters.TimePlan;
	If ExecutionIsInterrupted Then
		
		If AvailableInterval.Time < MinimumOperationTime() Then
			Result = False;
		ElsIf NextIntervalIsLoaded(PlanningParameters, PickingParameters, AvailableInterval) Then
			Result = False;
		EndIf;
		
	EndIf;
	
	IntervalLoadedSynchronously = AvailableIntervalIsLoadedSynchronously(AvailableInterval);
	If IntervalLoadedSynchronously 
		And Not AvailableInterval.Time = PickingParameters.TimePlan + OperationChangeoverTime(PlanningParameters, AvailableInterval, PickingParameters.Operation) Then
		
		Result = False;
		
	ElsIf PickingParameters.ParallelLoad
		And ValueIsFilled(AvailableInterval.SetupSettings)
		And Not PickingParameters.SetupSettings = AvailableInterval.SetupSettings Then
		
		Result = False;
		
	ElsIf PickingParameters.ParallelLoad
		And PickingParameters.LoadingMultiplicity > AvailableInterval.AvailableDownload
		And PickingParameters.LoadingMultiplicity <= PickingParameters.MaximumLoad Then
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function AvailableIntervalIsLoadedSynchronously(AvailableInterval)
	
	If AvailableInterval.SynchronousLoad Then
		Result = Not AvailableInterval.AvailableDownload = AvailableInterval.MaximumLoad;
	Else
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationChangeoverTime(Val PlanningParameters, Val AvailableInterval, Val Operation)
	
	PreviousVersionOfAdjustment = PreviousVersionOfAdjustment(PlanningParameters, AvailableInterval);
	SetupOptionHasChanged = ValueIsFilled(PreviousVersionOfAdjustment) And Not PreviousVersionOfAdjustment = Operation.SetupSettings;
	
	If SetupOptionHasChanged Then
		
		Time = ChangeoverTimeWhenChangingAdjustmentOption(PlanningParameters, AvailableInterval.WorkCenterType,
														PreviousVersionOfAdjustment, Operation.SetupSettings);
		
		Result = TimeAdjustedForCoefOfWorkingTime(PlanningParameters, AvailableInterval.WorkCenter, Time);
		
	Else
		Result = 0;
	EndIf;
	
	Return Result;
	
EndFunction

Function ChangeoverTimeWhenChangingAdjustmentOption(Val PlanningParameters, Val WorkCenter, Val CurrentSetupSettings, Val NextSetupSettings)
	
	If ValueTypeWorkCenter(WorkCenter) Then
		WorkCenter = WorkCenterType(PlanningParameters, WorkCenter);
	EndIf;
	
	Result = FindChangeoverTime(PlanningParameters, WorkCenter, CurrentSetupSettings, NextSetupSettings);
	If Not ValueIsFilled(Result) Then
		
		Result = FindChangeoverTime(PlanningParameters, WorkCenter,, NextSetupSettings);
		
		If Not ValueIsFilled(Result) Then
			
			Result = FindChangeoverTime(PlanningParameters, WorkCenter, CurrentSetupSettings);
			
			If Not ValueIsFilled(Result) Then
				Result = FindChangeoverTime(PlanningParameters, WorkCenter);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function FindChangeoverTime(Val PlanningParameters, Val WorkCenterType,
	Val CurrentSetupSettings = Undefined, Val NextSetupSettings = Undefined)
		
	If ValueIsFilled(PlanningParameters.ChangeoverTime_) Then
		
		If Not ValueIsFilled(CurrentSetupSettings) Then
			CurrentSetupSettings = Catalogs.SetupOptions.EmptyRef();
		EndIf;
		
		If Not ValueIsFilled(NextSetupSettings) Then
			NextSetupSettings = Catalogs.SetupOptions.EmptyRef();
		EndIf;
		
		SearchCondition = New Structure;
		SearchCondition.Insert("WorkCenterType", WorkCenterType);
		SearchCondition.Insert("CurrentSetupSettings", CurrentSetupSettings);
		SearchCondition.Insert("NextSetupSettings", NextSetupSettings);
		
		SearchBars = PlanningParameters.ChangeoverTime_.FindRows(SearchCondition);
		If ValueIsFilled(SearchBars) Then
			Return SearchBars[0].Time;
		Else
			Return 0;
		EndIf;
		
	Else
		Return 0;
	EndIf;
	
EndFunction

Function OperationPlacementInterval(Val PlanningParameters, PickingParameters)
	
	Result = InitializePlacementInterval();
	FillPropertyValues(Result, PickingParameters.AvailableInterval);
	FillPropertyValues(Result, PickingParameters, "ParallelLoadTime");
	
	CalculateBoundariesOfOperationPlacementInterval(PickingParameters, Result);
	
	If Not Result = Undefined Then
		
		CalculateLoadOfOperationPlacementInterval(PickingParameters, Result);
		CheckComplianceWithWorkCenterLoadLimits(PlanningParameters, PickingParameters, Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	PickingParameters - See InitializeParametersForSelectingPlacementIntervals
// 	PlacementInterval - See InitializePlacementInterval
Procedure CalculateBoundariesOfOperationPlacementInterval(PickingParameters, PlacementInterval)
	
	AvailableInterval = PickingParameters.AvailableInterval;
	TimeOfPlacement = PickingParameters.TimeOfPlacement;
	TimePlan = PickingParameters.TimePlan;
	DirectPlacement = PickingParameters.DirectPlacement;
	
	// The first border (left for forward, right for reverse placement).
	If DirectPlacement Then
		PlacementInterval.Begin = Max(AvailableInterval.Begin, TimeOfPlacement);
	Else
		PlacementInterval.Ending = Min(AvailableInterval.Ending, TimeOfPlacement);
	EndIf;
	
	If PlacementInterval.Begin < PlacementInterval.Ending Then
		
		// The second border (right for forward, left for reverse placement).
		IntervalTime = PlacementInterval.Ending - PlacementInterval.Begin;
		If IntervalTime > TimePlan Then
			IntervalTime = TimePlan;
			If DirectPlacement Then
				PlacementInterval.Ending = PlacementInterval.Begin + IntervalTime;
			Else
				PlacementInterval.Begin = PlacementInterval.Ending - IntervalTime;
			EndIf;
		EndIf;
	    PlacementInterval.TimePlan = IntervalTime;
		
		IntervalLoadedSynchronously = AvailableIntervalIsLoadedSynchronously(AvailableInterval);
		If IntervalLoadedSynchronously
			And (Not AvailableInterval.Begin = PlacementInterval.Begin
			Or Not AvailableInterval.Ending = PlacementInterval.Ending) Then
			
			PlacementInterval = Undefined;
			
		EndIf;
		
	Else
		PlacementInterval = Undefined;
	EndIf;
	
EndProcedure

Procedure CalculateLoadOfOperationPlacementInterval(PickingParameters, PlacementInterval)
	
	If PickingParameters.ParallelLoad 
		And ValueIsFilled(PickingParameters.Load) Then
		
		Available = PickingParameters.AvailableInterval.AvailableDownload;
		LoadBalance = PickingParameters.Load;
		LoadingMultiplicity = PickingParameters.LoadingMultiplicity;
		
		If LoadBalance <= Available Then
			PlacementInterval.Load = LoadBalance;
		Else
			
			If LoadingMultiplicity <= PickingParameters.MaximumLoad Then
				NumberOfDownloads = Int(Available/LoadingMultiplicity);
				PlacementInterval.Load = NumberOfDownloads * LoadingMultiplicity;
			Else
				PlacementInterval.Load = Available;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckComplianceWithWorkCenterLoadLimits(Val PlanningParameters, PickingParameters, PlacementInterval)
	
	AvailableInterval = PickingParameters.AvailableInterval;
	Operation = PickingParameters.Operation;
	DirectPlacement = PickingParameters.DirectPlacement;
	
	MaxLoadPercentage = MaxLoadPercentageOfWorkCenter(PlanningParameters, AvailableInterval.WorkCenterType);
	
	If ValueIsFilled(MaxLoadPercentage) 
		And Not MaxLoadPercentage = 100 Then
		
		AcceptableDownload = TimeToChangeAvailableInterval(PlanningParameters, AvailableInterval);
		CurrentImporting = BusyShiftTime(PlanningParameters, AvailableInterval.WorkCenter, AvailableInterval.StartOfShift);
		LoadingAfterPlacement = CurrentImporting + PlacementInterval.TimePlan;
		
		If LoadingAfterPlacement <= AcceptableDownload Then
			Return;
		Else
			
			If CurrentImporting >= AcceptableDownload Then
				PlacementInterval = Undefined;
			Else
				
				IntervalIsSuitable = InterruptingOperationIsAcceptable(PlanningParameters, PickingParameters);
				
				If IntervalIsSuitable Then
					
					TimeAvailable_ = AcceptableDownload - CurrentImporting;
					If TimeAvailable_ < PlacementInterval.TimePlan Then
						
						If DirectPlacement Then
							PlacementInterval.Ending = PlacementInterval.Begin + TimeAvailable_;
						Else
							PlacementInterval.Begin = PlacementInterval.Ending - TimeAvailable_;
						EndIf;
						
						PlacementInterval.TimePlan = TimeAvailable_;
						
					Else
						PlacementInterval = Undefined;
					EndIf;
					
				Else
					PlacementInterval = Undefined;
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function MaxLoadPercentageOfWorkCenter(Val PlanningParameters, Val WorkCenterType)
	
	If PlanningParameters.UseAvailabilityReserve Then
		Result = 100;
	Else
		
		SearchString = PlanningParameters.LoadLimitsForWorkCenters.Find(WorkCenterType, "WorkCenterType");
		If SearchString = Undefined Then
			Result = 100;
		Else
			Result = SearchString.MaxLoadPercentage;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function TimeToChangeAvailableInterval(Val PlanningParameters, Val AvailableInterval)
	
	MaxLoadPercentage = MaxLoadPercentageOfWorkCenter(PlanningParameters, AvailableInterval.WorkCenterType);
	
	If ValueIsFilled(MaxLoadPercentage) 
		And Not MaxLoadPercentage = 100 Then
		Result = Round(AvailableInterval.ShiftTime * (MaxLoadPercentage / 100));
	Else
		Result = AvailableInterval.ShiftTime;
	EndIf;
	
	Return Result;
	
EndFunction

Function ItIsPossibleToPlaceAuxiliaryRCOnInterval(Val PlanningParameters, PickingParameters, PlacementParameters)
	
	Operation = PickingParameters.Operation;
	AvailableInterval = PickingParameters.AvailableInterval;
	PlacementInterval = PickingParameters.PlacementInterval;
	DirectPlacement = PickingParameters.DirectPlacement;
	
	If ValueIsFilled(PlacementParameters.AuxiliaryRC) Then
		
		CheckIfDiscussingRTSAreFreeOnInterval(PlanningParameters, PlacementParameters.AuxiliaryRC, PlacementInterval);
		
	Else
		
		SelectAuxiliaryRCForOperation(PlanningParameters, Operation, PlacementParameters.AuxiliaryRC,
			AvailableInterval, PlacementInterval, DirectPlacement);
		
	EndIf;
	
	AuxiliaryRTSAreFree = BooleanValueOfTable(PlacementParameters.AuxiliaryRC, "Free");
	
	If AuxiliaryRTSAreFree Then
		
		Cancel = False;
		CacheAvailableAuxiliaryRCIntervals(PickingParameters, PlacementParameters, Cancel);
		
		Return Not Cancel;
		
	Else
		
		Return False;
	
	EndIf;
	
EndFunction

Procedure SelectAuxiliaryRCForOperation(Val PlanningParameters, Val Operation, Result,
		Val AvailableInterval, PlacementInterval, Val DirectPlacement)
	
	TableAvailability = InitializeTableOfAvailabilityOfAuxiliaryRC();
	AuxiliaryRC = AuxiliaryRCOperations(PlanningParameters, Operation.Stage, Operation.OperationID);
	
	For Each WorkCenter In AuxiliaryRC Do
		
		If ValueTypeWorkCenter(WorkCenter) Then
			ReadAvailabilityOfAuxiliaryRC(PlanningParameters, Operation, TableAvailability,
				AvailableInterval, PlacementInterval, WorkCenter, DirectPlacement);
		Else
			ReadAvailabilityOfAuxiliaryRCGroup(PlanningParameters, Operation, TableAvailability,
				AvailableInterval, PlacementInterval, WorkCenter, DirectPlacement);
		EndIf;
			
	EndDo;
	
	AllRTSAreFree = BooleanValueOfTable(TableAvailability, "Free");
	If Not AllRTSAreFree 
		And Not AvailableIntervalIsLoadedSynchronously(AvailableInterval) Then
			
		SelectAvailableIntervalOfAuxiliaryRC(PlanningParameters, Operation, TableAvailability,
				AvailableInterval, PlacementInterval, DirectPlacement);
			
	EndIf;
	
	Result = TableAvailability;
	
EndProcedure

Procedure ReadAvailabilityOfAuxiliaryRC(Val PlanningParameters, Val Operation, Result,
		Val AvailableInterval, Val PlacementInterval, Val WorkCenter, Val DirectPlacement)
	
	Intervals = AvailableTimeIntervals_(PlanningParameters, WorkCenter, PlacementInterval.Begin, PlacementInterval.Ending);
	
	AvailableIntervals = InitializeAvailableRCIntervalsTable();
	
	If DirectPlacement Then
		
		SelectAvailableRCTimeOnInterval(
			PlanningParameters,
			WorkCenter,
			PlacementInterval.Begin,
			AvailableInterval.Ending,
			AvailableIntervals,
			Intervals);
			
	Else
			
		SelectAvailableRCTimeOnInterval(
			PlanningParameters,
			WorkCenter,
			AvailableInterval.Begin,
			PlacementInterval.Ending,
			AvailableIntervals,
			Intervals);
			
	EndIf;
	
	Free = PeriodBelongsToIntervals(PlanningParameters, PlacementInterval.Begin, PlacementInterval.Ending, Intervals);
	
	ResultRow = Result.Add();
	ResultRow.WorkCenter = WorkCenter;
	ResultRow.Free = Free;
	ResultRow.AvailableIntervals = AvailableIntervals;
	ResultRow.AvailableTime = AvailableIntervals.Total("Time");
	
EndProcedure

Procedure ReadAvailabilityOfAuxiliaryRCGroup(Val PlanningParameters, Val Operation, Result,
		Val AvailableInterval, Val PlacementInterval, Val GroupOfWorkCenters, Val DirectPlacement)
		
	TableAvailability = InitializeTableOfAvailabilityOfAuxiliaryRC();
	
	WorkCenters = WorkCentersOnMeasurementValue(PlanningParameters, GroupOfWorkCenters);
	For Each WorkCenter In WorkCenters Do
		ReadAvailabilityOfAuxiliaryRC(PlanningParameters, Operation, TableAvailability,
				AvailableInterval, PlacementInterval, WorkCenter, DirectPlacement);
	EndDo;
	
	TableAvailability.Sort("Free Desc, AvailableTime Desc");
	
	RowFound = False;
	For Each String In TableAvailability Do
		
		If String.Free Then
			NewRow = Result.Add();
			FillPropertyValues(NewRow, String);
			RowFound = True;
			Break;
		EndIf;
		
	EndDo;
	
	If Not RowFound 
		And ValueIsFilled(TableAvailability) Then
		NewRow = Result.Add();
		FillPropertyValues(NewRow, TableAvailability[0]);
	EndIf;
	
EndProcedure

Procedure SelectAvailableIntervalOfAuxiliaryRC(Val PlanningParameters, Val Operation, TableAvailability,
		Val AvailableInterval, PlacementInterval, Val DirectPlacement)
	
	For Each String In TableAvailability Do
		
		If Not ValueIsFilled(String.AvailableTime) Then
			Return;
		EndIf;
		
	EndDo;
	
	If (DirectPlacement 
		And AvailableInterval.Ending = PlacementInterval.Ending)
		Or (Not DirectPlacement 
		And AvailableInterval.Begin = PlacementInterval.Begin) Then
		
		NewInterval = SelectAvailableIntervalOfAuxiliaryRCExtreme(PlanningParameters, TableAvailability,
			AvailableInterval, PlacementInterval, DirectPlacement);
	Else
		
		NewInterval = SelectAvailableIntervalOfAuxiliaryRCIdenticalLength(PlanningParameters, TableAvailability, 
			AvailableInterval, PlacementInterval, DirectPlacement);
			
		If NewInterval = Undefined Then
			NewInterval = SelectAvailableIntervalOfAuxiliaryRCExtreme(PlanningParameters, TableAvailability,
				AvailableInterval, PlacementInterval, DirectPlacement);
		EndIf;
		
	EndIf;
	
	If Not NewInterval = Undefined Then
		FillPropertyValues(PlacementInterval, NewInterval);
		TableAvailability.FillValues(True, "Free");
	EndIf;
	
EndProcedure

Function SelectAvailableIntervalOfAuxiliaryRCExtreme(Val PlanningParameters, Val TableAvailability,
		Val AvailableInterval, Val PlacementInterval, Val DirectPlacement)
	
	If DirectPlacement Then
		
		Begin = PlacementInterval.Begin;
		Ending = AvailableInterval.Ending;
		
		Time = TimeAvailableAuxiliaryRCExtremeInterval(PlanningParameters, TableAvailability,
			Begin, Ending, DirectPlacement);
		
		If ValueIsFilled(Time) Then
			
			Result = InitializePlacementInterval();
			Result.Begin = Ending - Time;
			Result.Ending = Ending;
			Result.TimePlan = Time;
			Return Result;
			
		Else
			Return Undefined;
		EndIf;
		
	Else
		
		Begin = AvailableInterval.Begin;
		Ending = PlacementInterval.Ending ;
				
		Time = TimeAvailableAuxiliaryRCExtremeInterval(PlanningParameters, TableAvailability,
			Begin, Ending, DirectPlacement);
		
		If ValueIsFilled(Time) Then
			
			Result = InitializePlacementInterval();
			Result.Begin = Begin;
			Result.Ending = Begin + Time;
			Result.TimePlan = Time;
			Return Result;
			
		Else
			Return Undefined;
		EndIf;
	
	EndIf;
	
EndFunction

Function TimeAvailableAuxiliaryRCExtremeInterval(Val PlanningParameters, Val TableAvailability,
		Val Begin, Val Ending, Val DirectPlacement)
	
	Time = 0;
	
	If DirectPlacement Then
		
		For Each RCAvailabilityLine In TableAvailability Do
			
			RCTime = 0;
			
			For Each Interval In RCAvailabilityLine.AvailableIntervals Do
				
				If Interval.Ending = Ending
					Or (Interval.Ending > Ending 
					And Interval.Begin < Ending) Then
					
					Begin = Max(Begin, Interval.Begin);
					Ending = Ending;
					IntervalTime = Ending - Begin;
					
					AvailableTime = AvailableShiftTimeBasedOnLoad(PlanningParameters, Interval.AvailableTimeLine);
					
					RCTime = Min(IntervalTime, AvailableTime);
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not ValueIsFilled(RCTime) Then
				
				Return Undefined;
				
			ElsIf ValueIsFilled(Time) Then
				
				Time = Min(Time, RCTime);
				
			Else
				Time = RCTime;
			EndIf;
			
		EndDo;
		
	Else
		
		For Each RCAvailabilityLine In TableAvailability Do
			
			RCTime = 0;
			
			For Each Interval In RCAvailabilityLine.AvailableIntervals Do
				
				If Interval.Begin = Begin
					Or (Interval.Begin < Begin 
					And Interval.Ending > Begin) Then
					
					Begin = Begin;
					Ending = Min(Ending, Interval.Ending);
					IntervalTime = Ending - Begin;
					
					AvailableTime = AvailableShiftTimeBasedOnLoad(PlanningParameters, Interval.AvailableTimeLine);
					
					RCTime = Min(IntervalTime, AvailableTime);
					
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not ValueIsFilled(RCTime) Then
				
				Return Undefined;
				
			ElsIf ValueIsFilled(Time) Then
				
				Time = Min(Time, RCTime);
				
			Else
				Time = RCTime;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Time;
	
EndFunction

Function SelectAvailableIntervalOfAuxiliaryRCIdenticalLength(Val PlanningParameters, Val TableAvailability,
		Val AvailableInterval, Val PlacementInterval, Val DirectPlacement)
	
	Time = PlacementInterval.Ending - PlacementInterval.Begin;
	If DirectPlacement Then
		Boundary = AvailableInterval.Ending;
	Else
		Boundary = AvailableInterval.Begin;
	EndIf;
	
	Interval = PickUpIdenticalIntervalRecursively(PlanningParameters, TableAvailability, Boundary, Time,
		PlacementInterval.Begin, PlacementInterval.Ending, Catalogs.WorkCenters.EmptyRef(), DirectPlacement);
	Return Interval;
	
EndFunction

Function PickUpIdenticalIntervalRecursively(Val PlanningParameters, Val TableAvailability, Val Boundary,
		Val Time, Val Begin, Val Ending, Val WorkCenter, Val DirectPlacement)
	
	For Each RCAvailabilityLine In TableAvailability Do
		
		If RCAvailabilityLine.WorkCenter = WorkCenter Then
			Continue;
		Else
			
			Free = PeriodBelongsToIntervals(
				PlanningParameters, Begin, Ending,, RCAvailabilityLine.AvailableIntervals);
				
			If Free Then
				Continue;
			Else
				
				Cancel = False;
				ShiftMomentOfPlacedInterval(Boundary, Time, Begin, Ending,
					RCAvailabilityLine.AvailableIntervals, DirectPlacement, Cancel);
					
				If Cancel Then
					Return Undefined;
				Else
					
					Free = PeriodBelongsToIntervals(
						PlanningParameters, Begin, Ending,, RCAvailabilityLine.AvailableIntervals);
						
					If Free Then
						Return PickUpIdenticalIntervalRecursively(PlanningParameters, TableAvailability, Boundary, Time,
							Begin, Ending, RCAvailabilityLine.WorkCenter, DirectPlacement);
					Else
						Return Undefined;
					EndIf;
					
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	Result = InitializePlacementInterval();
	Result.Begin = Begin;
	Result.Ending = Ending;
	Result.TimePlan = Time;
	
	Return Result;
	
EndFunction

Procedure ShiftMomentOfPlacedInterval(Val Boundary, Val Time, Begin, Ending, Val AvailableIntervals, Val DirectPlacement, Cancel)
		
	For Each Interval In AvailableIntervals Do
		
		If DirectPlacement Then
			NovBeginning = Max(Begin, Interval.Begin);
			NovEnding = NovBeginning + Time;
			
			If NovEnding <= Interval.Ending 
				And NovEnding <= Boundary Then
				
				Begin = NovBeginning;
				Ending = NovEnding;
				Return;
				
			Else
				Continue;
			EndIf;
			
		Else
			
			NovEnding = Min(Ending, Interval.Ending);
			NovBeginning = NovEnding - Time;
			
			If NovBeginning >= Interval.Begin 
				And NovBeginning >= Boundary Then
				
				Begin = NovBeginning;
				Ending = NovEnding;
				Return;
				
			Else
				Continue;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Cancel = True;
	
EndProcedure

// Returns:
// 	ValueTable - LongDesc:
// * Cost - Number -
// * ChangeoverTime - Number -
// * DownloadCoef - Number -
// * CacheOfAvailableIntervals - See InitializeCacheTableOfAvailableIntervals
// * AuxiliaryRC - See InitializeTableOfAvailabilityOfAuxiliaryRC
// * Intervals - Array -
// * Ending - Date -
// * Begin - Date -
// * WorkCenter - String, CatalogRef.WorkCenters -
// * EstimateTime - Number -
// * WeightedAssessment - Number -
Function InitializeAlternativeRCTable()
	
	Parameters = InitializePlacementParameters();
	
	Result = New ValueTable;
	For Each Parameter In Parameters Do
		Result.Columns.Add(Parameter.Key);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Cost - Number -
// * ChangeoverTime - Number -
// * DownloadCoef - Number -
// * CacheOfAvailableIntervals - See InitializeCacheTableOfAvailableIntervals
// * AuxiliaryRC - See InitializeTableOfAvailabilityOfAuxiliaryRC
// * Intervals - Array of See InitializeFixedBatchPlacementInterval -
// * Ending - Date -
// * Begin - Date -
// * WorkCenter - String, CatalogRef.WorkCenters -
Function InitializePlacementParameters()
	
	Result = New Structure;
	Result.Insert("WorkCenter");
	Result.Insert("Begin", 	'00010101');
	Result.Insert("Ending", '00010101');
	Result.Insert("Intervals", New Array);
	Result.Insert("CacheOfAvailableIntervals", InitializeCacheTableOfAvailableIntervals());
	Result.Insert("AuxiliaryRC", InitializeTableOfAvailabilityOfAuxiliaryRC());
	Result.Insert("DownloadCoef", 0);
	Result.Insert("ChangeoverTime", 0);
	Result.Insert("Cost", 0);
	
	Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	Operation - See UnloadOperationsTable
// 	WorkCenter - Arbitrary - 
// 	DirectPlacement - Boolean - 
// Returns:
// 	Structure - LongDesc:
// * InitialPlanningParameters - Structure -:
// ** BusyTimeByShift - See InitializeBusyTimeByShiftTable
// ** AvailableTime - ValueTable -
// * MaximumLoad - Number -
// * SynchronousLoad - Boolean -
// * ParallelLoad - Boolean -
// * TimeOfPlacement - Date -
// * PlaceAuxiliary - Boolean -
// * InaccessibleAuxiliaryRC - Array -
// * PlacementInterval - See InitializePlacementInterval
// * AvailableInterval - ValueTableRow - See InitializeAvailableHardwareTime Where:
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** ParallelLoad - Boolean -
// ** SynchronousLoad - Boolean -
// ** WorkCenter - CatalogRef.WorkCenters -
// ** Period - Date -
// ** Begin - Date -
// ** Ending - Date -
// ** StartOfShift - Date -
// ** Time - Number -
// ** ShiftTime - Number -
// ** MaximumLoad - Number -
// ** AvailableDownload - Number -
// ** SetupSettings - CatalogRef.SetupOptions -
// ** PrecededByLoading - Boolean -
// ** SetupSettingsPreceding - CatalogRef.SetupOptions -
// ** DownloadFollows - Boolean -
// ** SetupSettingsFollowing - CatalogRef.SetupOptions -
// * WorkTimeFactor - Number -
// * TimePlan - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * Operation - See InitializeBatchOperations
// * DirectPlacement - Boolean -
// * ParallelLoadingOptions - Undefined, ValueTable - LongDesc:
// ** Load - Number - 
// ** LoadingMultiplicity - Number - 
// ** TimePlan - Number - 
// ** SetupTime - Number - 
// ** ParallelLoadTime - UUID - 
// ** UploadToReceivedAvailableIntervalIsAllowed - Boolean - 
// * Load - Number - 
// * LoadingMultiplicity - Number - 
// * ParallelLoadTime - Undefined, UUID - 
// * UploadToReceivedAvailableIntervalIsAllowed - Boolean - 
Function InitializeParametersForSelectingPlacementIntervals(PlanningParameters, Operation, WorkCenter, DirectPlacement)
	
	PlaceAuxiliary = OperationHasAuxiliaryRC(PlanningParameters, Operation.Stage, Operation.OperationID);
	TimeOfPlacement = WhenOperationWasPlaced(PlanningParameters, Operation, DirectPlacement);
	
	Result = New Structure;
	
	Result.Insert("Operation", Operation);
	Result.Insert("SetupSettings", Operation.SetupSettings);
	Result.Insert("WorkCenter", WorkCenter);
	Result.Insert("DirectPlacement", DirectPlacement);
	Result.Insert("WorkTimeFactor", RCOperatingTimeFactor(PlanningParameters, WorkCenter));
	
	Result.Insert("AvailableInterval", Undefined);
	Result.Insert("PlacementInterval", Undefined);
	Result.Insert("InaccessibleAuxiliaryRC", New Array);
	Result.Insert("PlaceAuxiliary", PlaceAuxiliary);
	Result.Insert("TimeOfPlacement", TimeOfPlacement);
	
	Result.Insert("IndexOfNextAvailableInterval", Undefined);
	
	Result.Insert("ParallelLoad");
	Result.Insert("SynchronousLoad");
	Result.Insert("MaximumLoad");
	ImportParameters = ParametersOfParallelLoadingOfVRC(PlanningParameters, WorkCenter);
	FillPropertyValues(Result, ImportParameters);
	
	InitialPlanningParameters = New Structure;
	InitialPlanningParameters.Insert("AvailableTime", PlanningParameters.AvailableTime.Copy());
	InitialPlanningParameters.Insert("BusyTimeByShift", PlanningParameters.BusyTimeByShift.Copy());
	Result.Insert("InitialPlanningParameters", InitialPlanningParameters);
	
	InitializeReFilledIntervalSelectionParameters(PlanningParameters, Operation, WorkCenter, Result);
	
	Return Result;
	
EndFunction

Procedure InitializeReFilledIntervalSelectionParameters(Val PlanningParameters, Val Operation, Val WorkCenter, PickingParameters)
	
	PickingParameters.Insert("TimePlan", OperationTimePlan(PlanningParameters, Operation, WorkCenter));
	PickingParameters.Insert("ChangeoverTime", 0);
	PickingParameters.Insert("FirstInterval", True);
	PickingParameters.Insert("InterruptingOperationIsAcceptable", Undefined);
	
	InitializeParallelLoadingParameters(PlanningParameters, Operation, WorkCenter, PickingParameters);
	
EndProcedure

Procedure InitializeParallelLoadingParameters(Val PlanningParameters, Val Operation, Val WorkCenter, PickingParameters)
	
	If PickingParameters.ParallelLoad Then
		
		ImportParameters = New ValueTable;
		ImportParameters.Columns.Add("Load", New TypeDescription("Number", New NumberQualifiers));
		ImportParameters.Columns.Add("LoadingMultiplicity", New TypeDescription("Number", New NumberQualifiers));
		ImportParameters.Columns.Add("TimePlan", New TypeDescription("Number", New NumberQualifiers));
		ImportParameters.Columns.Add("SetupTime", New TypeDescription("Number", New NumberQualifiers));
		ImportParameters.Columns.Add("ParallelLoadTime", New TypeDescription("UUID"));
		ImportParameters.Columns.Add("UploadToReceivedAvailableIntervalIsAllowed", New TypeDescription("Boolean"));
		
		NewRow = ImportParameters.Add();
		NewRow.Load = Operation.Load * Operation.Count / Operation.ZoomRatio;
		NewRow.LoadingMultiplicity = Operation.Load;
		NewRow.TimePlan = PickingParameters.TimePlan;
		NewRow.SetupTime = OperationTimePZParallelLoading(PlanningParameters, Operation, WorkCenter);
		NewRow.ParallelLoadTime = New UUID;
		NewRow.UploadToReceivedAvailableIntervalIsAllowed = True;
		
		PickingParameters.Insert("ParallelLoadingOptions", ImportParameters);
		
		PickingParameters.Insert("Load", NewRow.Load);
		PickingParameters.Insert("LoadingMultiplicity", NewRow.LoadingMultiplicity);
		PickingParameters.Insert("ParallelLoadTime", NewRow.ParallelLoadTime);
		PickingParameters.Insert("UploadToReceivedAvailableIntervalIsAllowed",
			NewRow.UploadToReceivedAvailableIntervalIsAllowed);
		
	Else
		
		PickingParameters.Insert("ParallelLoadingOptions", Undefined);
		
		PickingParameters.Insert("Load", 0);
		PickingParameters.Insert("LoadingMultiplicity", 0);
		PickingParameters.Insert("ParallelLoadTime", Undefined);
		PickingParameters.Insert("UploadToReceivedAvailableIntervalIsAllowed", True);
		
	EndIf;
	
EndProcedure

// Returns:
// 	Structure - LongDesc:
// * ParallelLoadTime - Undefined -
// * Load - Number -
// * ChangeoverTime - Number -
// * TimePlan - Number -
// * Ending - Date -
// * Begin - Date -
Function InitializePlacementInterval()
	
	Result = New Structure;
	Result.Insert("Begin", '00010101');
	Result.Insert("Ending", '00010101');
	Result.Insert("TimePlan", 0); // Includes changeover time, incl.
	Result.Insert("ChangeoverTime", 0);
	Result.Insert("Load", 0);
	Result.Insert("ParallelLoadTime", Undefined);
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * WorkCenter - CatalogRef.WorkCenters -
// * Begin - Date -
// * StartOfShift - Date -
// * ShiftTime - Number -
Function InitializeCacheTableOfAvailableIntervals()
	
	Result = New ValueTable;
	
	Result.Columns.Add("WorkCenter");
	Result.Columns.Add("Begin");
	Result.Columns.Add("StartOfShift");
	Result.Columns.Add("ShiftTime");
	
	Result.Indexes.Add("WorkCenter, StartOfShift");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes -
// * Free - Boolean - 
// * AvailableIntervals - See InitializeAvailableRCIntervalsTable
// * AvailableTime - Undefined, Number - 
Function InitializeTableOfAvailabilityOfAuxiliaryRC()
	
	Result = New ValueTable;
	Result.Columns.Add("WorkCenter");
	Result.Columns.Add("Free");
	Result.Columns.Add("AvailableIntervals");
	Result.Columns.Add("AvailableTime");
	
	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Begin - Date - 
// * Ending - Date -
// * Time - Date -
// * AvailableTimeLine - ValueTableRow -:
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** ParallelLoad - Boolean -
// ** SynchronousLoad - Boolean -
// ** WorkCenter - CatalogRef.WorkCenters -
// ** Period - Date -
// ** Begin - Date -
// ** Ending - Date -
// ** StartOfShift - Date -
// ** Time - Number -
// ** ShiftTime - Number -
// ** MaximumLoad - Number -
// ** AvailableDownload - Number -
// ** SetupSettings - CatalogRef.SetupOptions -
// ** PrecededByLoading - Boolean -
// ** SetupSettingsPreceding - CatalogRef.SetupOptions -
// ** DownloadFollows - Boolean -
// ** SetupSettingsFollowing - CatalogRef.SetupOptions -
Function InitializeAvailableRCIntervalsTable()
	
	Result = New ValueTable;
	Result.Columns.Add("Begin");
	Result.Columns.Add("Ending");
	Result.Columns.Add("Time");
	Result.Columns.Add("AvailableTimeLine");
	
	Return Result;
	
EndFunction

Function WhenOperationWasPlaced(PlanningParameters, Operation, DirectPlacement)
	
	If DirectPlacement Then
		TimeOfPlacement = Operation.StartDate2;
	Else
		TimeOfPlacement = Operation.DateOfProduction;
	EndIf;
	TimeOfPlacement = Max(TimeOfPlacement, PlanningParameters.PlanningTimepoint);
	
	Return TimeOfPlacement;
	
EndFunction

Procedure FillInUnavailableAuxiliaryRC(Val PlacementParameters, Result)
	
	For Each String In PlacementParameters.AuxiliaryRC Do
		
		If Not String.Free Then
			
			Result.Add(String.WorkCenter);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ClearPlacementAndSelectionParameters(PlanningParameters, PickingParameters, PlacementParameters, AccommodationIsPossible = True, InterruptionIsAcceptable = True)
	
	PlacementParameters = InitializePlacementParameters();
	
	InitializeReFilledIntervalSelectionParameters(
		PlanningParameters, PickingParameters.Operation, PickingParameters.WorkCenter, PickingParameters);
	
	If PickingParameters.PlacementInterval = Undefined
		Or PickingParameters.IndexOfNextAvailableInterval = Undefined
		Or PickingParameters.DirectPlacement
		And PickingParameters.PlacementInterval.Ending >= PickingParameters.AvailableInterval.Ending 
		Or Not PickingParameters.DirectPlacement 
		And PickingParameters.PlacementInterval.Begin <= PickingParameters.AvailableInterval.Begin 
		Or Not InterruptionIsAcceptable
		And PickingParameters.PlacementInterval.TimePlan < PickingParameters.TimePlan
		Or Not AccommodationIsPossible Then
		IncreaseIndexOfNextAvailableInterval(PlanningParameters, PickingParameters);
	EndIf;
	
	RestoreOriginalPlanningParameters(PlanningParameters, PickingParameters);
	
EndFunction

Procedure IncreaseIndexOfNextAvailableInterval(PlanningParameters, PickingParameters)
	
	If ValueIsFilled(PickingParameters.IndexOfNextAvailableInterval) Then
		
		If PickingParameters.DirectPlacement Then
			PickingParameters.IndexOfNextAvailableInterval = PickingParameters.IndexOfNextAvailableInterval + 1;
		Else
			PickingParameters.IndexOfNextAvailableInterval = PickingParameters.IndexOfNextAvailableInterval - 1;
		EndIf;
		
	ElsIf ValueIsFilled(PickingParameters.AvailableInterval) Then
		
		CurrentIndex = PlanningParameters.AvailableTime.IndexOf(PickingParameters.AvailableInterval);
		If PickingParameters.DirectPlacement Then
			PickingParameters.IndexOfNextAvailableInterval = CurrentIndex + 1;
		Else
			PickingParameters.IndexOfNextAvailableInterval = CurrentIndex - 1;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure RestoreOriginalPlanningParameters(PlanningParameters, PickingParameters)
	
	For Each Parameter In PickingParameters.InitialPlanningParameters Do
		
		If TypeOf(Parameter.Value) = Type("ValueTable") Then
			PlanningParameters[Parameter.Key] = Parameter.Value.Copy();
		Else
			PlanningParameters[Parameter.Key] = Parameter.Value;
		EndIf;
		
	EndDo;
	
EndProcedure

Function MinimumOperationTime()
	
	Return 10;	
	
EndFunction

Function InterruptingOperationIsAcceptable(Val PlanningParameters, PickingParameters)
	
	If PickingParameters.InterruptingOperationIsAcceptable = Undefined Then
		
		Result = True;
		
		Continuous = PickingParameters.Operation.Continuous;
		OperationTime_ = PickingParameters.TimePlan + PickingParameters.ChangeoverTime;
		ShiftTime = TimeToChangeAvailableInterval(PlanningParameters, PickingParameters.AvailableInterval);
		
		If Continuous And OperationTime_ <= ShiftTime Then
			Result = False;
		EndIf;
		
		PickingParameters.InterruptingOperationIsAcceptable = Result;
		
	Else
		
		Result = PickingParameters.InterruptingOperationIsAcceptable;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationHasAuxiliaryRC(Val PlanningParameters, Val Stage, Val OperationID)
	
	AuxiliaryRC = AuxiliaryRCOperations(PlanningParameters, Stage, OperationID);
	Return ValueIsFilled(AuxiliaryRC);
	
EndFunction

Function AuxiliaryRCOperations(Val PlanningParameters, Val Stage, Val OperationID)
	
	Result = New Array;
	
	SearchCondition = New Structure("Stage, OperationID", Stage, OperationID);
	SearchBars = PlanningParameters.AuxiliaryWorkCenters.FindRows(SearchCondition);
	For Each String In SearchBars Do
		Result.Add(String.WorkCenter);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CheckIfDiscussingRTSAreFreeOnInterval(Val PlanningParameters, AuxiliaryRC, Val PlacementInterval)
	
	For Each String In AuxiliaryRC Do
		
		Begin = PlacementInterval.Begin;
		Ending = PlacementInterval.Ending;
		
		Intervals = AvailableTimeIntervals_(PlanningParameters, String.WorkCenter, Begin, Ending);
		
		If ValueIsFilled(Intervals) Then
			
			String.Free = PeriodBelongsToIntervals(PlanningParameters, Begin, Ending, Intervals);
			
			AvailableIntervals = InitializeAvailableRCIntervalsTable();
			
			SelectAvailableRCTimeOnInterval(
				PlanningParameters,
				String.WorkCenter,
				PlacementInterval.Begin,
				PlacementInterval.Ending,
				AvailableIntervals,
				Intervals);
				
			String.AvailableIntervals = AvailableIntervals;
			
		Else
			String.Free = False;
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	Begin - Date - LongDesc
// 	Ending - Date - LongDesc
// 	AvailableTimeIntervals - Undefined, Array of ValueTableRow - Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
// 	AvailableRCIntervals - See InitializeAvailableRCIntervalsTable
// Returns:
// 	Boolean - LongDesc
Function PeriodBelongsToIntervals(Val PlanningParameters, Val Begin, Val Ending, Val AvailableTimeIntervals = Undefined, Val AvailableRCIntervals = Undefined)
		
	If Not AvailableTimeIntervals = Undefined Then
		
		Intervals = AvailableTimeIntervals;
		IntervalsAvailableTime = True;
		
	ElsIf Not AvailableRCIntervals = Undefined Then
		
		Intervals = AvailableRCIntervals;
		IntervalsAvailableTime = False;
		
	Else
		Return False;
	EndIf;
	
	TimeBalance = Ending - Begin;
	
	For Each Interval In Intervals Do
		
		If (Begin <= Interval.Begin 
			And Ending > Interval.Begin)
			Or (Ending >= Interval.Ending 
			And Begin < Interval.Ending)
			Or (Begin >= Interval.Begin 
			And Ending <= Interval.Ending) Then
			
			OffsettingStart = Max(Begin, Interval.Begin);
			CreditEnd = Min(Ending, Interval.Ending);
			
			If IntervalsAvailableTime Then
				AvailableTime = AvailableShiftTimeBasedOnLoad(PlanningParameters, Interval);
			Else
				AvailableTime = AvailableShiftTimeBasedOnLoad(PlanningParameters, Interval.AvailableTimeLine);
			EndIf;
			
			TimeUsed = Min(AvailableTime, (CreditEnd - OffsettingStart));
			TimeBalance = TimeBalance - TimeUsed;
			
		EndIf;
		
	EndDo;
	
	Return Not (TimeBalance > 0);
	
EndFunction

Function AvailableShiftTimeBasedOnLoad(PlanningParameters, AvailableInterval)
	
	AcceptableDownload = TimeToChangeAvailableInterval(PlanningParameters, AvailableInterval);
	CurrentImporting = BusyShiftTime(PlanningParameters, AvailableInterval.WorkCenter, AvailableInterval.StartOfShift);
	
	Result = AcceptableDownload - CurrentImporting;
	
	Return Result;
	
EndFunction

Function AvailableTimeIntervals_(Val PlanningParameters, Val WorkCenter, Val PeriodBeginning, Val PeriodEnd)
    
    Result = New Array;
	    
    SearchCondition = New Structure;
    SearchCondition.Insert("WorkCenter", WorkCenter);
    SearchCondition.Insert("Period");
	
	SearchPeriod = BegOfDay(PeriodBeginning);
	While SearchPeriod < PeriodEnd Do
		
		SearchCondition.Period = SearchPeriod;
		
		SearchBars = FindRowsInTableWhileMaintainingOrder(PlanningParameters.AvailableTime, SearchCondition);
		
		For Each String In SearchBars Do
			Result.Add(String);
		EndDo;
		
		SearchPeriod = EndOfDay(SearchPeriod) + 1;
		
	EndDo;
	
    Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	WorkCenter - CatalogRef.WorkCenterTypes, CatalogRef.WorkCenters, Arbitrary - LongDesc
// 	IntervalStart - Date - LongDesc
// 	IntervalEnd_ - Date - LongDesc
// 	Result - ValueTable - LongDesc:
// * Begin - Date -
// * Ending - Date -
// * Time - Date -
// * AvailableTimeLine - ValueTableRow -:
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** ParallelLoad - Boolean -
// ** SynchronousLoad - Boolean -
// ** WorkCenter - CatalogRef.WorkCenters -
// ** Period - Date -
// ** Begin - Date -
// ** Ending - Date -
// ** StartOfShift - Date -
// ** Time - Number -
// ** ShiftTime - Number -
// ** MaximumLoad - Number -
// ** AvailableDownload - Number -
// ** SetupSettings - CatalogRef.SetupOptions -
// ** PrecededByLoading - Boolean -
// ** SetupSettingsPreceding - CatalogRef.SetupOptions -
// ** DownloadFollows - Boolean -
// ** SetupSettingsFollowing - CatalogRef.SetupOptions -
// 	Intervals - Undefined, Array of ValueTableRow - Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
Procedure SelectAvailableRCTimeOnInterval(Val PlanningParameters, Val WorkCenter, Val IntervalStart, Val IntervalEnd_, Result, Val Intervals = Undefined)
		
	If Intervals = Undefined Then
		Intervals = AvailableTimeIntervals_(PlanningParameters, WorkCenter, IntervalStart, IntervalEnd_);
	EndIf;
	
	For Each AvailableInterval In Intervals Do
		
		If AvailableInterval.Begin >= IntervalEnd_ Then
			Break;
		ElsIf AvailableInterval.Ending < IntervalStart Then
			Continue;
			
		ElsIf AvailableInterval.Begin <= IntervalStart 
			And AvailableInterval.Ending >= IntervalEnd_ Then
			
			NewRow = Result.Add();
			NewRow.Begin = IntervalStart;
			NewRow.Ending = IntervalEnd_;
			NewRow.Time = IntervalEnd_ - IntervalStart;
			NewRow.AvailableTimeLine = AvailableInterval;
			
		ElsIf AvailableInterval.Begin > IntervalStart 
			And AvailableInterval.Ending < IntervalEnd_ Then
			
			NewRow = Result.Add();
			NewRow.Begin = AvailableInterval.Begin;
			NewRow.Ending = AvailableInterval.Ending;
			NewRow.Time = AvailableInterval.Ending - AvailableInterval.Begin;
			NewRow.AvailableTimeLine = AvailableInterval;
			
		ElsIf AvailableInterval.Begin >= IntervalStart 
			And AvailableInterval.Begin < IntervalEnd_ Then 
			
			NewRow = Result.Add();
			NewRow.Begin = AvailableInterval.Begin;
			NewRow.Ending = Min(AvailableInterval.Ending, IntervalEnd_);
			NewRow.Time = NewRow.Ending - NewRow.Begin;
			NewRow.AvailableTimeLine = AvailableInterval;
			
		ElsIf AvailableInterval.Ending > IntervalStart 
			And AvailableInterval.Ending <= IntervalEnd_ Then
			
			NewRow = Result.Add();
			NewRow.Begin = Max(AvailableInterval.Begin, IntervalStart);
			NewRow.Ending = AvailableInterval.Ending;
			NewRow.Time = NewRow.Ending - NewRow.Begin;
			NewRow.AvailableTimeLine = AvailableInterval;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function BooleanValueOfTable(Val Table, Val ColumnName)
	
	Result = True;
	For Each String In Table Do
		
		If Not String[ColumnName] Then
			Result = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CalculatePlacementOfOperationOnRC(Val PlanningParameters, PlacementParameters)
	
	CalculatePlacementLoadFactor(PlanningParameters, PlacementParameters);
	CalculateCostOfAccommodation(PlanningParameters, PlacementParameters);
	
EndProcedure

Procedure CalculatePlacementLoadFactor(Val PlanningParameters, PlacementParameters)
	
	ShiftTimes = 0;
	TimeTaken = 0;
	
	For Each WriteCache In PlacementParameters.CacheOfAvailableIntervals Do
		
		ShiftTimes = ShiftTimes + WriteCache.ShiftTime;
		
		BusyInterval = BusyShiftTime(PlanningParameters, WriteCache.WorkCenter, WriteCache.StartOfShift);
		TimeTaken = TimeTaken + BusyInterval;
		
	EndDo;
	
	If ValueIsFilled(ShiftTimes) Then
		PlacementParameters.DownloadCoef = TimeTaken / ShiftTimes;
	EndIf;
	
EndProcedure

Procedure CalculateCostOfAccommodation(Val PlanningParameters, PlacementParameters)
	
	Cost = 0;
	Rates = RatesOfWorkingCenter(PlanningParameters, PlacementParameters.WorkCenter);
	
	If ValueIsFilled(Rates) Then
		
		ChangeoverTime = 0;
		TimePlan = 0;
		
		For Each Interval In PlacementParameters.Intervals Do
			
			ChangeoverTime = ChangeoverTime + Interval.ChangeoverTime;
			TimePlan = TimePlan + (Interval.TimePlan - Interval.ChangeoverTime);
			
		EndDo;
		
		CostOfWork = (TimePlan / 3600) * Rates.RateWork;
		ChangeoverCost = (ChangeoverTime / 3600) * Rates.RateChangeover;
		Cost = CostOfWork + ChangeoverCost;
		
	EndIf;
	
	PlacementParameters.Cost = Cost;
	
EndProcedure

Function RatesOfWorkingCenter(Val PlanningParameters, Val WorkCenter)
	
	SearchString = PlanningParameters.TableOfWorkCenters.Find(WorkCenter, "WorkCenter");
	
	If SearchString = Undefined Then
		
		Result = Undefined;
		
	Else
		
		Result = New Structure("RateWork, RateChangeover");
		FillPropertyValues(Result, SearchString);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CacheAvailableAuxiliaryRCIntervals(Val PickingParameters, PlacementParameters, Cancel)
	
	For Each AuxiliaryRCData In PlacementParameters.AuxiliaryRC Do
		
		AvailableInterval =	AvailableAuxiliaryRCInterval(AuxiliaryRCData.AvailableIntervals, PickingParameters.PlacementInterval);
		
		If AvailableInterval = Undefined Then
			
			Cancel = True;
			
		Else
			
			CacheAvailableInterval_(PlacementParameters, AvailableInterval, PickingParameters.PlacementInterval);
			
		EndIf;
		
	EndDo;                                                   
	
EndProcedure

Procedure CacheAvailableInterval_(PlacementParameters, Val AvailableInterval, Val PlacementInterval)
	
	CacheAvailableInterval = PlacementParameters.CacheOfAvailableIntervals.Add();
	FillPropertyValues(CacheAvailableInterval, AvailableInterval);
	CacheAvailableInterval.Begin = PlacementInterval.Begin;
	
EndProcedure

Function BestWorkCenterToAccommodate(Val PlanningParameters, TableOfAlternatives, Val RCSelectionRule)
	
	If TableOfAlternatives.Count() > 1 Then
		
		If PlanningParameters.LoadMethod = Enums.MethodsOfWorkCenterTypeLoad.LoadEquipmentEvenly Then
			AdditionalRule = ",DownloadCoef ASC";
		Else
			AdditionalRule = ",DownloadCoef DESC";
		EndIf;
		
		If RCSelectionRule = RCRuleModelSettings() Then
			
			TableOfAlternatives.Columns.Add("EstimateTime", New TypeDescription("Number", New NumberQualifiers));
			TableOfAlternatives.Columns.Add("WeightedAssessment", New TypeDescription("Number", New NumberQualifiers));
			
			CalculateTimeEstimateOfAlternativeRC(TableOfAlternatives);
			EvaluationCriteria = CriteriaForEvaluatingPlanningModel(PlanningParameters);
			CalculateWeightedScore(TableOfAlternatives, EvaluationCriteria);
			
			SortingRules = "WeightedAssessment ASC" + AdditionalRule;
			
		ElsIf RCSelectionRule = RCRuleMinimizeChangeovers() Then
			
			SortingRules = "ChangeoverTime ASC" + AdditionalRule;
			
		EndIf;
		
		TableOfAlternatives.Sort(SortingRules);
		
	EndIf;
	
	Return TableOfAlternatives[0];
	
EndFunction

Procedure CalculateTimeEstimateOfAlternativeRC(TableOfAlternatives)
	
	StartingPoint = '00010101';
	
	For Each String In TableOfAlternatives Do
		StartingPoint = ?(ValueIsFilled(StartingPoint), Min(StartingPoint, String.Begin), String.Begin);
	EndDo;
	
	MinDeviation = 0;
	
	For Each String In TableOfAlternatives Do
		Deviation = String.Ending - StartingPoint;
		String.EstimateTime = Deviation;
		MinDeviation = ?(ValueIsFilled(MinDeviation), Min(MinDeviation, Deviation), Deviation);
	EndDo;
	
	If ValueIsFilled(MinDeviation) Then
		
		For Each String In TableOfAlternatives Do
			String.EstimateTime = String.EstimateTime/MinDeviation;
		EndDo;
		
	EndIf;
	
EndProcedure

Function PreviousVersionOfAdjustment(Val PlanningParameters, Val CurrentInterval)
	
	Result = Undefined;
	
	If CurrentInterval.PrecededByLoading Then
		
		Result = CurrentInterval.SetupSettingsPreceding;
		
	Else
		
		AvailableTime = PlanningParameters.AvailableTime;
		CurrentIndex = AvailableTime.IndexOf(CurrentInterval);
		
		While True Do
			
			CurrentIndex = CurrentIndex - 1;
			If CurrentIndex = -1 Then
				
				Break;
				
			Else
				
				PrecedingInterval = AvailableTime[CurrentIndex];
				If PrecedingInterval.WorkCenter = CurrentInterval.WorkCenter Then
					
					If PrecedingInterval.PrecededByLoading Then
						Result = PrecedingInterval.SetupSettingsPreceding;
						Break;
					EndIf;
					
				Else
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	BatchString - ValueTableRow - LongDesc
// 	RowsOfIntervals - Array of ValueTableRow - Where:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * LotNumber - Number -
// * WorkCenter - String, CatalogRef.WorkCenters -
// * Begin - Date -
// * Ending - Date -
// * ParallelLoadTime - UUID -
// * TimePlan - Number -
// * Load - Number -
// * ThisIsChangeover - Boolean -
// * LotQuantity - Number -
// * ZoomRatio - Number -
// * CreatedOn - Number -
// * Completed2 - Number -
// * RepetitionIsRequired - Number -
// * Skipped3 - Number -
// * TransferTime - Number -
// * Department - CatalogRef.BusinessStructure -
// * Secondary - Boolean -
// * LeftLimit - Date -
// * RightBorder_ - Date -
// * AdditionalRecord - Boolean -
// * IntervalDuration - Number -
// 	Boundaries - Structure - LongDesc:
// * Begin - Date -
// * Ending - Date -
// Returns:
// 	Boolean - LongDesc
Function PlaceCompletedBatchInSchedule(PlanningParameters, BatchString, RowsOfIntervals, Boundaries)
	
	PlacementParameters = InitializePlacementParameters();
	PlacementParameters.Insert("OperationString", BatchString);
	PlacementParameters.Insert("FixedBatch", True);
	PlacementParameters.Insert("Begin", Boundaries.Ending);
	PlacementParameters.Insert("Ending", Boundaries.Begin);
	PlacementParameters.Insert("WorkCenter", BatchString.WorkCenter);
	FixChildOperationsAfterPlacingParent(PlanningParameters, BatchString, PlacementParameters, True);
	
	TheStructureOfTheSearch = New Structure("Stage, Operation, OperationID");
	FillPropertyValues(TheStructureOfTheSearch, BatchString);
	FoundRows = PlanningParameters.TransactionTable.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() <> 0 Then
		CheckDataOfPreviousBatches(FoundRows[0], BatchString, False);
	EndIf;
	
	
	If RowsOfIntervals.Count() = 0 Then
		ScheduleString = PlanningParameters.ScheduleTable_.Add();
		FillPropertyValues(ScheduleString, PlanningParameters);
		FillPropertyValues(ScheduleString, BatchString,, "WorkCenter");
		ScheduleString.LotQuantity = BatchString.Completed2 + BatchString.Skipped3 - BatchString.RepetitionIsRequired;
		ScheduleString.WorkCenter = BatchString.WorkingCenterOfProductionOperation;
		Return True;
	EndIf;
	
	If RowsOfIntervals[0].LotQuantity = (BatchString.Completed2 + BatchString.Skipped3 - BatchString.RepetitionIsRequired) Then
		
		For Each IntervalString In RowsOfIntervals Do
			ScheduleString = PlanningParameters.ScheduleTable_.Add();
			FillPropertyValues(ScheduleString, IntervalString);
		EndDo;
		
	Else
		
		UnitTimeInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(BatchString.TimePerPiece, BatchString.TimePerPieceUnitOfMeasure);
		TimeInSeconds_1 = ProductionPlanningClientServer.GetTimeInSeconds(BatchString.SetupTime, BatchString.SetupTimeUnitOfMeasure);
		
		If BatchString.ParallelLoad Then 
			TimeToPlace = UnitTimeInSeconds;
		ElsIf UnitTimeInSeconds > 0 Then 
			TimeToPlace = BatchString.Count / BatchString.ZoomRatio * UnitTimeInSeconds + TimeInSeconds_1;
		Else
			TimeToPlace = 0;
		EndIf;
		
		IntervalIndices = 0;
		
		TimeOfWorkCenters = New Map;
		StartOfOperation = RowsOfIntervals[0].Begin;
		OperationEnding = Undefined;
		For Each IntervalString In RowsOfIntervals Do
			CurWorkCenter = IntervalString.WorkCenter;
			If CurWorkCenter = Undefined Then
				CurWorkCenter = Catalogs.WorkCenters.EmptyRef();
			EndIf;
			If TimeOfWorkCenters.Get(CurWorkCenter) = Undefined Then
				TimeOfWorkCenters.Insert(CurWorkCenter, TimeToPlace);
			EndIf;
			
			TimePlan = TimeOfWorkCenters.Get(CurWorkCenter);
			If TimePlan = 0 Then
				Continue;
			EndIf;
			
			ScheduleString = PlanningParameters.ScheduleTable_.Add();
			FillPropertyValues(ScheduleString, IntervalString);
			ScheduleString.LotQuantity = ScheduleString.Completed2 + BatchString.Skipped3 - BatchString.RepetitionIsRequired;
			
			IntervalDuration = Min(TimePlan, IntervalString.TimePlan);
			TimePlan = TimePlan - IntervalDuration;
			TimeOfWorkCenters.Insert(IntervalString.WorkCenter, TimePlan);
			
			If ScheduleString.TimePlan > IntervalDuration Then
				ScheduleString.TimePlan = IntervalDuration;
				ScheduleString.Ending = ScheduleString.Begin + IntervalDuration;
			EndIf;
			
			If OperationEnding = Undefined Then 
				OperationEnding = IntervalString.Ending;
			Else
				If StartOfOperation > IntervalString.Begin Then 
					StartOfOperation = IntervalString.Begin;
				EndIf;
				If OperationEnding < IntervalString.Ending Then 
					OperationEnding = IntervalString.Ending;
				EndIf;			
			EndIf;
			
			If TimePlan = 0 Then 
				ScheduleString.AdditionalRecord = False;
				ScheduleString.LeftLimit = StartOfOperation;
				ScheduleString.RightBorder_ = OperationEnding;
				ScheduleString.IntervalDuration = TimeToPlace;
			Else
				ScheduleString.AdditionalRecord = True;
				ScheduleString.LeftLimit = '00010101';
				ScheduleString.RightBorder_ = '00010101';
				ScheduleString.IntervalDuration = 0;
			EndIf;
			
		EndDo;
		
	EndIf;
			
EndFunction

Function PlaceFixedBatchInSchedule(PlanningParameters, BatchString, RowsOfIntervals, Boundaries)
	
	UnitTimeInSeconds = ProductionPlanningClientServer.GetTimeInSeconds(BatchString.TimePerPiece, BatchString.TimePerPieceUnitOfMeasure);
	TimeInSeconds_1 = ProductionPlanningClientServer.GetTimeInSeconds(BatchString.SetupTime, BatchString.SetupTimeUnitOfMeasure);
	
	If BatchString.ParallelLoad Then 
		TimeToPlace = UnitTimeInSeconds;
	ElsIf UnitTimeInSeconds > 0 Then 
		TimeToPlace = BatchString.Count / BatchString.ZoomRatio * UnitTimeInSeconds + TimeInSeconds_1;
	Else
		TimeToPlace = 0;
	EndIf;
	AuxiliaryTime = TimeToPlace;
	
	PlacementParameters = InitializePlacementParameters();
	PlacementParameters.Insert("OperationString", BatchString);
	PlacementParameters.Insert("FixedBatch", True);
	
	RequiresPlacement = True;		
	For IndexOf = 0 To RowsOfIntervals.UBound() Do
		IntervalString = RowsOfIntervals[IndexOf];
		
		If IntervalString.LotQuantity = (IntervalString.Completed2 + BatchString.Skipped3 - BatchString.RepetitionIsRequired) Then
			RequiresPlacement = False;
			Break;				
		EndIf;
		
		If Not ValueIsFilled(PlacementParameters.Begin) Then
			PlacementParameters.Begin = IntervalString.Begin;
		EndIf;                                                   
		If Not ValueIsFilled(PlacementParameters.WorkCenter) Then
			PlacementParameters.WorkCenter = IntervalString.WorkCenter;
		EndIf;
		
		If IntervalString.ThisIsChangeover Then
			ChangeoverTime = IntervalString.TimePlan;
			TimePlan = 0;
		Else
			ChangeoverTime = 0;
			TimePlan = Min(TimeToPlace, IntervalString.TimePlan);
		EndIf;
		
		If BatchString.RepetitionIsRequired >0 Then
			
			BatchString.DisableToCreateOperations = True;
			
		EndIf;	
		
		If TimeToPlace > 0
			And Not IntervalString.Secondary Then 
			
			Interval = InitializeFixedBatchPlacementInterval();
			FillPropertyValues(Interval, IntervalString);
			Interval.ChangeoverTime = ChangeoverTime;
			Interval.TimePlan = ?(ChangeoverTime > 0, ChangeoverTime, TimePlan);
			Interval.Ending = Interval.Begin + ChangeoverTime + TimePlan;
			
			PlacementParameters.Intervals.Add(Interval);
			PlacementParameters.Ending = Interval.Ending;
			
			TimeToPlace = TimeToPlace - TimePlan;
			
			BatchString.TimeToPlace = TimePlan;
			BatchString.PZTimeParallelLoading = TimeInSeconds_1;
			
			SelectFixedBatchPlacementInterval(PlanningParameters, PlacementParameters, Interval);
									
		EndIf;
		
		If AuxiliaryTime > 0
			And IntervalString.Secondary Then 
			
			Intervals = AvailableTimeIntervals_(PlanningParameters, IntervalString.WorkCenter, IntervalString.Begin, IntervalString.Ending);
			
			RCString = PlacementParameters.AuxiliaryRC.Find(IntervalString.WorkCenter, "WorkCenter");
			If RCString = Undefined Then
				AvailableIntervals = InitializeAvailableRCIntervalsTable();
				RCString = PlacementParameters.AuxiliaryRC.Add();
				RCString.WorkCenter = IntervalString.WorkCenter;
				RCString.Free = True;
			Else
				AvailableIntervals = RCString.AvailableIntervals;
			EndIf;				
			
			SelectAvailableRCTimeOnInterval(PlanningParameters, IntervalString.WorkCenter,
					IntervalString.Begin, IntervalString.Ending, AvailableIntervals, Intervals);
			
			RCString.AvailableIntervals = AvailableIntervals;
			RCString.AvailableTime = AvailableIntervals.Total("Time");
			
			AvailableInterval =	AvailableAuxiliaryRCInterval(AvailableIntervals, IntervalString);
			If AvailableInterval <> Undefined Then
				CacheAvailableInterval_(PlacementParameters, AvailableInterval, IntervalString);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If RequiresPlacement Then
		
		CalculatePlacementOfOperationOnRC(PlanningParameters, PlacementParameters);
		
		PlaceOperation(PlanningParameters, BatchString, PlacementParameters, True);
		
		TheStructureOfTheSearch = New Structure("Stage, Operation, OperationID");
		FillPropertyValues(TheStructureOfTheSearch, BatchString);
		FoundRows = PlanningParameters.TransactionTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() <> 0 Then
			CheckDataOfPreviousBatches(FoundRows[0], BatchString, False);
		EndIf;
		
	Else
		
		PlacementParameters.Insert("Begin", Boundaries.Ending);
		PlacementParameters.Insert("Ending", Boundaries.Begin);
		PlacementParameters.Insert("WorkCenter", RowsOfIntervals[0].WorkCenter);
		
		FixChildOperationsAfterPlacingParent(PlanningParameters, BatchString, PlacementParameters, True);
		
	EndIf;
	
EndFunction

Function SelectFixedBatchPlacementInterval(PlanningParameters, PlacementParameters, Interval)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("DirectPlacement", True);
	PickingParameters.Insert("TimeOfPlacement", Interval.Begin);
	PickingParameters.Insert("Operation", PlacementParameters.OperationString);
	PickingParameters.Insert("SetupSettings", PlacementParameters.OperationString.SetupSettings); 
	PickingParameters.Insert("ParallelLoad");
	PickingParameters.Insert("SynchronousLoad");
	PickingParameters.Insert("MaximumLoad");
	ImportParameters = ParametersOfParallelLoadingOfVRC(PlanningParameters, Interval.WorkCenter);
	FillPropertyValues(PickingParameters, ImportParameters);
	InitializeReFilledIntervalSelectionParameters(PlanningParameters, PlacementParameters.OperationString, Interval.WorkCenter, PickingParameters);
	
	SearchCondition = New Structure;
    SearchCondition.Insert("WorkCenter", Interval.WorkCenter);
    SearchCondition.Insert("Period", BegOfDay(Interval.Begin));
	FoundRows = FindRowsInTableWhileMaintainingOrder(PlanningParameters.AvailableTime, SearchCondition);
	
	AvailableInterval = Undefined;
	For Each FoundRow In FoundRows Do
		
		If FoundRow.Begin <= Interval.Begin
			And FoundRow.Ending >= Interval.Ending
			And IntervalIsSuitableForPlacingOperation(PlanningParameters, FoundRow, PickingParameters) Then
			AvailableInterval = FoundRow;
			Break;
		EndIf;		
		
	EndDo;
	
	If Not AvailableInterval = Undefined Then
		PickingParameters.Insert("AvailableInterval", AvailableInterval);
		PlacementInterval = OperationPlacementInterval(PlanningParameters, PickingParameters);
		CacheAvailableInterval_(PlacementParameters, AvailableInterval, PlacementInterval);
	EndIf;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * Load - Number -
// * TimePlan - Number -
// * ChangeoverTime - Number -
// * Ending - Date -
// * Begin - Date -
// * WorkCenter - CatalogRef.WorkCenters - 
// * Department - CatalogRef.BusinessStructure - 
Function InitializeFixedBatchPlacementInterval()
	
	Result = New Structure;
	Result.Insert("Department");
	Result.Insert("WorkCenter");
	Result.Insert("Begin", 	'00010101');
	Result.Insert("Ending", '00010101');
	Result.Insert("ChangeoverTime", 0);
	Result.Insert("TimePlan", 0); 
	Result.Insert("Load", 0);
	
	Return Result;
	
EndFunction

#EndRegion

#Region PlanningAlgorithms

Function PlanningCycleOperations(Val PlanningParameters, Val WorkCenterType, Val StagePriority)
	
	SearchCondition = New Structure;
	SearchCondition.Insert("WorkCenterType", WorkCenterType);
	SearchCondition.Insert("StagePriority", StagePriority);
	SearchCondition.Insert("Allocate", True);
	SearchCondition.Insert("Posted_1", False);
	SearchCondition.Insert("DependsOnPreceding", False);
	
	Return PlanningParameters.TransactionTable.FindRows(SearchCondition);
	
EndFunction

Function RefillablePlanningParameters(Val PlanningParameters)
	
	Result = New Structure;
	
	ParameterNames = NamesOfPlanningParametersToBeFilledIn();
	For Each Parameter In ParameterNames Do
		
		If PlanningParameters.Property(Parameter) Then
			ParameterValue = PlanningParameters[Parameter];
			
			If TypeOf(ParameterValue) = Type("ValueTable") Then
				Result.Insert(Parameter, ParameterValue.Copy());
			Else
				Result.Insert(Parameter, ParameterValue);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ReFillSchedulingSettings(PlanningParameters, Val RefillableParameters)
	
	For Each Parameter In RefillableParameters Do
		
		If TypeOf(Parameter.Value) = Type("ValueTable") Then
			PlanningParameters.Insert(Parameter.Key, Parameter.Value.Copy());
		Else
			PlanningParameters.Insert(Parameter.Key, Parameter.Value);
		EndIf;
		
	EndDo;
	
EndProcedure

Function NamesOfPlanningParametersToBeFilledIn()
	
	Result = New Array;
	
	Result.Add("TransactionTable");
	Result.Add("BusyTimeByShift");
	
	Result.Add("InteroperableTransitions");
	Result.Add("ScheduleTable_");
	
	Result.Add("TableOfWorkCenters");
	Result.Add("RanksOfWorkCenters");
	
	Result.Add("AvailableTime");
	
	Return Result;
	
EndFunction

Function AddUploadRecord(PlanningParameters, Operation, PlacementParameters, PlacementInterval)
	
	LoadingString = PlanningParameters.ScheduleTable_.Add(); //See InitializeScheduleTable 
	
	FillPropertyValues(LoadingString, Operation);
	FillPropertyValues(LoadingString, PlacementParameters);
	FillPropertyValues(LoadingString, PlacementInterval);
	
	LoadingString.LotQuantity = Operation.Count;
	
EndFunction

Procedure FillInGeneralPlacementProperties(Val PlanningParameters, PlacementParameters)
	
	PlacementParameters.Insert("Secondary", False);
	PlacementParameters.Insert("ThisIsChangeover", False);
	PlacementParameters.Insert("PlanningModel", PlanningParameters.PlanningModel);
	
EndProcedure

Procedure PlaceAuxiliaryOperations(Val PlanningParameters, Val Operation, Val PlacementParameters, Val PlacementInterval)
	
	ParametersOfPlacementOfObsl = PlacementParametersOfAuxiliaryRC(PlanningParameters, PlacementParameters);
	PlacementIntervalObsl = PlacementIntervalOfAuxiliaryRC(PlacementInterval);
	
	For Each AuxiliaryRCData In PlacementParameters.AuxiliaryRC Do
		
		FillPropertyValues(ParametersOfPlacementOfObsl, AuxiliaryRCData);
		AddUploadRecord(PlanningParameters, Operation, ParametersOfPlacementOfObsl, PlacementIntervalObsl);
		
	EndDo;
	
EndProcedure

Function PlacementParametersOfAuxiliaryRC(PlanningParameters, OSNPlacementParameters)
	
	Result = InitializePlacementParameters();
	
	FillPropertyValues(Result, OSNPlacementParameters);
	FillInGeneralPlacementProperties(PlanningParameters, Result);
	
	Result.Secondary = True;
	
	Return Result;
	
EndFunction

Function AvailableAuxiliaryRCInterval(Val AvailableIntervals, Val OSNPlacementInterval)
	
	Result = Undefined;
	
	For Each Interval In AvailableIntervals Do
		
		If Interval.Begin <= OSNPlacementInterval.Begin
			And Interval.Ending >= OSNPlacementInterval.Ending Then
			
			Result = Interval.AvailableTimeLine;
			Break;
			
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function PlacementIntervalOfAuxiliaryRC(Val PlacementInterval)
	
	Result = InitializePlacementInterval();
	FillPropertyValues(Result, PlacementInterval);
	Result.ChangeoverTime = 0;
	
	Return Result;
	
EndFunction

Procedure ProcessUnplacedOperation(PlanningParameters, Val Operation, Val DirectPlacement)
	
	Operation.Allocate = False;
	UndoPlacementOfChildOperationsRecursively(PlanningParameters, Operation, DirectPlacement);
	
EndProcedure

Procedure UndoPlacementOfChildOperationsRecursively(PlanningParameters, Val OperationParent, Val DirectPlacement)
	
	ChildOperations = RelatedOperations(PlanningParameters, OperationParent.Stage, OperationParent.OperationID, True, DirectPlacement);
	
	For Each ChildOperation In ChildOperations Do
		
		If ChildOperation.Stage = OperationParent.Stage 
			And Not ChildOperation.Posted_1 
			And ChildOperation.Allocate Then
			
			ChildOperation.Allocate = False;
			UndoPlacementOfChildOperationsRecursively(PlanningParameters, ChildOperation, DirectPlacement);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FixAvailableTime_(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval)
	
	BusyIntervalTime = PlacementInterval.TimePlan;
	If BusyIntervalTime = AvailableInterval.Time Then
		
		SetOffIdenticalInterval(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval);
		
	ElsIf AvailableInterval.Begin = PlacementInterval.Begin Then
		
		ReadOffLoadingIntervalOnLeft(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval);
		
	ElsIf AvailableInterval.Ending = PlacementInterval.Ending Then
		
		ReadTimeIntervalOnRight(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval);
		
	Else
		
		ReadTimeIntervalInside(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval);
		
	EndIf;
	
EndProcedure

Procedure SetOffIdenticalInterval(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval)
	
	If AvailableInterval.ParallelLoad Then
		
		AvailableInterval.AvailableDownload = AvailableInterval.AvailableDownload - PlacementInterval.Load;
		AvailableInterval.SetupSettings = Operation.SetupSettings;
		If AvailableInterval.AvailableDownload = 0 Then
			
			AvailableInterval.Time = 0;
			EmptyIntervals.Add(AvailableInterval);
			
		EndIf;
		
	Else
		
		AvailableInterval.Time = 0;
		EmptyIntervals.Add(AvailableInterval);
		
	EndIf;
	
	FixPriorAvailableTimeInterval(PlanningParameters.AvailableTime, Operation, AvailableInterval);
	FixSubsequentAvailableTimeInterval(PlanningParameters.AvailableTime, Operation, AvailableInterval);
	
EndProcedure

Procedure ReadOffLoadingIntervalOnLeft(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval)
	
	AvailableTime = PlanningParameters.AvailableTime;
	
	AvailableInterval.Begin = PlacementInterval.Ending;
	AvailableInterval.Time = AvailableInterval.Time - PlacementInterval.TimePlan;
		
	If AvailableInterval.ParallelLoad Then
		
		AvailableDownload = AvailableInterval.AvailableDownload - PlacementInterval.Load;
		If AvailableDownload = 0 Then
			
			FixPriorAvailableTimeInterval(AvailableTime, Operation, AvailableInterval);
			
		Else
			
			IntervalToCur = AvailableTime.Insert(AvailableTime.IndexOf(AvailableInterval));
			FillPropertyValues(IntervalToCur, AvailableInterval);
			IntervalToCur.Begin = PlacementInterval.Begin;
			IntervalToCur.Ending = PlacementInterval.Ending;
			IntervalToCur.Time = PlacementInterval.TimePlan;
			IntervalToCur.AvailableDownload = AvailableDownload;
			IntervalToCur.SetupSettings = Operation.SetupSettings;
			
			IntervalToCur.DownloadFollows = Not (AvailableInterval.AvailableDownload = AvailableInterval.MaximumLoad);
			IntervalToCur.SetupSettingsFollowing = AvailableInterval.SetupSettings;
			
			FixPriorAvailableTimeInterval(AvailableTime, Operation, IntervalToCur);
			
		EndIf;
		
	Else
		FixPriorAvailableTimeInterval(AvailableTime, Operation, AvailableInterval);
	EndIf;
	
	SetIntervalFlagToPrecedeLoading(AvailableInterval, Operation);
	
EndProcedure

Procedure ReadTimeIntervalOnRight(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval)
	
	AvailableTime = PlanningParameters.AvailableTime;
	
	AvailableInterval.Ending = PlacementInterval.Begin;
	AvailableInterval.Time = AvailableInterval.Time - PlacementInterval.TimePlan;
	
	If AvailableInterval.ParallelLoad Then
		
		AvailableDownload = AvailableInterval.AvailableDownload - PlacementInterval.Load;
		If AvailableDownload = 0 Then
			
			FixSubsequentAvailableTimeInterval(AvailableTime, Operation, AvailableInterval);
			
		Else
			
			IntervalAfterCur = AvailableTime.Insert(AvailableTime.IndexOf(AvailableInterval)+1);
			FillPropertyValues(IntervalAfterCur, AvailableInterval);
			IntervalAfterCur.Begin = PlacementInterval.Begin;
			IntervalAfterCur.Ending = PlacementInterval.Ending;
			IntervalAfterCur.Time = PlacementInterval.TimePlan;
			IntervalAfterCur.AvailableDownload = AvailableDownload;
			IntervalAfterCur.SetupSettings = Operation.SetupSettings;
			
			IntervalAfterCur.PrecededByLoading = Not (AvailableInterval.AvailableDownload = AvailableInterval.MaximumLoad);
			IntervalAfterCur.SetupSettingsPreceding = AvailableInterval.SetupSettings;
			
			FixSubsequentAvailableTimeInterval(AvailableTime, Operation, IntervalAfterCur);
			
		EndIf;
		
	Else
		FixSubsequentAvailableTimeInterval(AvailableTime, Operation, AvailableInterval);
	EndIf;
	
	SetIntervalFlagToBeFollowedByLoading(AvailableInterval, Operation);
	
EndProcedure

Procedure ReadTimeIntervalInside(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval)
	
	AvailableTime = PlanningParameters.AvailableTime;
	
	IntervalToBusy = AvailableTime.Insert(AvailableTime.IndexOf(AvailableInterval));
	FillPropertyValues(IntervalToBusy, AvailableInterval);
	IntervalToBusy.Ending = PlacementInterval.Begin;
	IntervalToBusy.Time = IntervalToBusy.Ending - IntervalToBusy.Begin;
	SetIntervalFlagToBeFollowedByLoading(IntervalToBusy, Operation);
	
	If AvailableInterval.ParallelLoad Then
		
		AvailableDownload = AvailableInterval.AvailableDownload - PlacementInterval.Load;
		If Not AvailableDownload = 0 Then
			
			LoadedInterval = AvailableTime.Insert(AvailableTime.IndexOf(AvailableInterval));
			FillPropertyValues(LoadedInterval, AvailableInterval);
			LoadedInterval.Begin = PlacementInterval.Begin;
			LoadedInterval.Ending = PlacementInterval.Ending;
			LoadedInterval.Time = PlacementInterval.TimePlan;
			LoadedInterval.AvailableDownload = AvailableDownload;
			LoadedInterval.SetupSettings = Operation.SetupSettings;
			
			LoadedInterval.PrecededByLoading = Not (AvailableInterval.AvailableDownload = AvailableInterval.MaximumLoad);
			LoadedInterval.SetupSettingsPreceding = AvailableInterval.SetupSettings;
			LoadedInterval.DownloadFollows = Not (AvailableInterval.AvailableDownload = AvailableInterval.MaximumLoad);
			LoadedInterval.SetupSettingsFollowing = AvailableInterval.SetupSettings;
			
		EndIf;
		
	EndIf;
	
	IntervalAfterBusy = AvailableInterval;
	IntervalAfterBusy.Begin = PlacementInterval.Ending;
	IntervalAfterBusy.Time = IntervalAfterBusy.Ending - IntervalAfterBusy.Begin;
	SetIntervalFlagToPrecedeLoading(IntervalAfterBusy, Operation);
	
EndProcedure

Procedure ReflectBusyTimeByShift(PlanningParameters, Val AvailableInterval, Val WorkCenter, Val Time)
	
	BusyTimeTable = PlanningParameters.BusyTimeByShift;
	SearchCondition = New Structure("WorkCenter, StartOfShift", WorkCenter, AvailableInterval.StartOfShift);
	
	SearchBars = BusyTimeTable.FindRows(SearchCondition);
	If ValueIsFilled(SearchBars) Then
		
		FoundRow = SearchBars[0];
		FoundRow.TimeTaken = FoundRow.TimeTaken + Time;
		
	Else
		
		NewRow = BusyTimeTable.Add();
		FillPropertyValues(NewRow, AvailableInterval);
		NewRow.WorkCenter = WorkCenter;
		NewRow.TimeTaken = Time;
		
	EndIf;
	
EndProcedure

Procedure FixPriorAvailableTimeInterval(AvailableTime, Val Operation, Val CurrentInterval)
	
	IndexOfPreceding = AvailableTime.IndexOf(CurrentInterval) - 1;
	
	If IndexOfPreceding >= 0 Then
		
		PrecedingInterval = AvailableTime[IndexOfPreceding];
		
		If PrecedingInterval.WorkCenter = CurrentInterval.WorkCenter
			And Not PrecedingInterval.DownloadFollows Then
			
			SetIntervalFlagToBeFollowedByLoading(PrecedingInterval, Operation);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FixSubsequentAvailableTimeInterval(AvailableTime, Val Operation, Val CurrentInterval)
	
	IndexOfFollowing = AvailableTime.IndexOf(CurrentInterval) + 1;
	
	If IndexOfFollowing < AvailableTime.Count() Then
		
		NextInterval_ = AvailableTime[IndexOfFollowing];
		
		If NextInterval_.WorkCenter = CurrentInterval.WorkCenter
			And Not NextInterval_.PrecededByLoading Then
			
			SetIntervalFlagToPrecedeLoading(NextInterval_, Operation);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure SetIntervalFlagToBeFollowedByLoading(Interval, Val Operation)
	
	Interval.DownloadFollows = True;
	Interval.SetupSettingsFollowing = Operation.SetupSettings;
	
EndProcedure

Procedure SetIntervalFlagToPrecedeLoading(Interval, Val Operation)
	
	Interval.PrecededByLoading = True;
	Interval.SetupSettingsPreceding = Operation.SetupSettings;
	
EndProcedure

Procedure RemoveEmptyAvailableTimeIntervals(PlanningParameters, EmptyIntervals)
	
	For Each Interval In EmptyIntervals Do
		PlanningParameters.AvailableTime.Delete(Interval);
	EndDo;
	
EndProcedure

Function SelectChangeoverTimeFromInterval(Val PlacementInterval)
	
	Result = InitializePlacementInterval();
	FillPropertyValues(Result, PlacementInterval);
	
	If PlacementInterval.ChangeoverTime < PlacementInterval.TimePlan Then
		Result.Ending = PlacementInterval.Begin + PlacementInterval.ChangeoverTime;
		Result.TimePlan = PlacementInterval.ChangeoverTime;
	EndIf;
	
	Return Result;
	
EndFunction

Function SelectMainTimeFromInterval(Val PlacementInterval)
	
	Result = InitializePlacementInterval();
	FillPropertyValues(Result, PlacementInterval);
	
	Result.Begin = PlacementInterval.Begin + PlacementInterval.ChangeoverTime;
	Result.TimePlan = PlacementInterval.TimePlan - PlacementInterval.ChangeoverTime;
	
	Return Result;
	
EndFunction

Function BusyShiftTime(Val PlanningParameters, Val WorkCenter, Val StartOfShift)
	
	SearchCondition = New Structure;
	SearchCondition.Insert("WorkCenter", WorkCenter);
	SearchCondition.Insert("StartOfShift", StartOfShift);
	
	SearchBars = PlanningParameters.BusyTimeByShift.FindRows(SearchCondition);
	If ValueIsFilled(SearchBars) Then
		Result = SearchBars[0].TimeTaken;
	Else
		Result = 0;
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationTimePlan(Val PlanningParameters, Val Operation, Val WorkCenter = Undefined)
	
	WorkCenterForSearch = ?(ValueIsFilled(WorkCenter), WorkCenter, Operation.WorkCenter);
	
	If ValueTypeWorkCenter(WorkCenterForSearch) Then
		
		Result = TimeAdjustedForCoefOfWorkingTime(PlanningParameters, WorkCenterForSearch, Operation.TimeToPlace);
		
	Else
		
		Result = Operation.TimeToPlace;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationTimePZParallelLoading(Val PlanningParameters, Val Operation, Val WorkCenter = Undefined)
	
	WorkCenterForSearch = ?(ValueIsFilled(WorkCenter), WorkCenter, Operation.WorkCenter);
	
	If ValueTypeWorkCenter(WorkCenterForSearch) Then
		
		Result = TimeAdjustedForCoefOfWorkingTime(PlanningParameters, WorkCenterForSearch, Operation.PZTimeParallelLoading);
		
	Else
		
		Result = Operation.PZTimeParallelLoading;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function TimeAdjustedForCoefOfWorkingTime(Val PlanningParameters, Val WorkCenter, Val Time)
	
	Coef = RCOperatingTimeFactor(PlanningParameters, WorkCenter);
	Return Round(Time * Coef);
	
EndFunction

Function RCOperatingTimeFactor(PlanningParameters, WorkCenter)
	
	SearchString = PlanningParameters.TableOfWorkCenters.Find(WorkCenter, "WorkCenter");
	
	If SearchString = Undefined Then
		Result = 1;
	Else
		Result = ?(ValueIsFilled(SearchString.WorkTimeFactor), SearchString.WorkTimeFactor, 1)
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters See InitializePlanningParameters
// 	Operation - ValueTableRow - Where:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * LotNumber - Number -
// * WorkCenter - String, CatalogRef.WorkCenters -
// * Begin - Date -
// * Ending - Date -
// * ParallelLoadTime - UUID -
// * TimePlan - Number -
// * Load - Number -
// * ThisIsChangeover - Boolean -
// * LotQuantity - Number -
// * ZoomRatio - Number -
// * CreatedOn - Number -
// * Completed2 - Number -
// * RepetitionIsRequired - Number -
// * Skipped3 - Number -
// * TransferTime - Number -
// * Department - CatalogRef.BusinessStructure -
// * Secondary - Boolean -
// * LeftLimit - Date -
// * RightBorder_ - Date -
// * AdditionalRecord - Boolean -
// * IntervalDuration - Number -
// 	PlacementParameters - See InitializePlacementParameters
// 	DirectPlacement - Boolean - 
Procedure FixChildOperationsAfterPlacingParent(PlanningParameters, Operation, Val PlacementParameters, Val DirectPlacement)
	
	ChildOperations = RelatedOperations(PlanningParameters, Operation.Stage, Operation.OperationID, True, DirectPlacement);
	
	For Each ChildOperation In ChildOperations Do
		
		ChildOperation.DependsOnPreceding = Not ParentOperationsArePlaced(PlanningParameters, ChildOperation, DirectPlacement);
		
		If ChildOperation.DataFromPreviousBatches.Columns.Count() = 0 Then
 			InitializeDataFromPreviousBatches(ChildOperation.DataFromPreviousBatches);
			ChildOperation.PrecedingDataIsSorted = False;
		EndIf;
		PreviousBatchData = ChildOperation.DataFromPreviousBatches.Add();
		FillPropertyValues(PreviousBatchData, Operation,, "Count");
		PreviousBatchData.Count = Operation.Count / Operation.ZoomRatio;
		If ChildOperation.BatchSize = 0
			Or ChildOperation.BatchSize > Operation.TransferLot Then
			ChildOperation.BatchSize = Operation.TransferLot;
		EndIf;
		
		If PlacementParameters = Undefined Then
			PreviousBatchData.Date = ?(DirectPlacement, Operation.Ending, Operation.Begin);
		Else
			If DirectPlacement Then
				ChildOperation.StartDate2 = DateWhenChildOperationWasStarted(
					PlanningParameters, Operation, PlacementParameters.Ending, ChildOperation);
				PreviousBatchData.Date = PlacementParameters.Ending;
			Else
				ChildOperation.DateOfProduction = DateOfIssueOfChildOperation(
					PlanningParameters, Operation, PlacementParameters.Begin, ChildOperation);
				PreviousBatchData.Date = PlacementParameters.Begin;
			EndIf;
		EndIf;	
		
		//Replace the work center with the current operation recursively(Planning parameters, Operation, Child operation, placement parameters.Work center, direct placement);
		
	EndDo;
	
EndProcedure

Function ParentOperationsArePlaced(Val PlanningParameters, Val Operation, Val DirectPlacement)
	
	Result = True;
	
	ParentOperations = RelatedOperations(PlanningParameters, Operation.Stage, Operation.OperationID, False, DirectPlacement);
	
	For Each ParentOperation In ParentOperations Do
		
		If Not ParentOperation.Posted_1 Then
			Result = False;
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	Operations - Array of ValueTableRow - LongDesc
// Returns:
// 	ValueTable - LongDesc:
// * Operations - Array -
// * Schedule - See NewOptionScheduleObject
// * RCSelectionRule - String -
Function InitializeScheduleOptions(Val PlanningParameters, Val Operations)
	
	Result = NewObjectScheduleOptions();
	
	If Operations.Count() = 1 Then
		
		NewRow = Result.Add();
		NewRow.Operations = Operations;
		NewRow.Schedule = NewOptionScheduleObject();
		NewRow.RCSelectionRule = RCRuleModelSettings();
		
	Else
		
		OperationQueue = OperationQueue(PlanningParameters, Operations);
		
		OperationRules = OperationQueueRules(OperationQueue);
		RCRules = RCSelectionRules(PlanningParameters, Operations);
		
		For Each OperationRule In OperationRules Do
			
			UpOperations = QueueOperationsOrderedByRule(OperationQueue, OperationRule);
			
			For Each RCRule In RCRules Do
				
				NewRow = Result.Add();
				NewRow.Operations = UpOperations;
				NewRow.Schedule = NewOptionScheduleObject();
				NewRow.RCSelectionRule = RCRule;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationsHaveVariousAdjustmentOptions(Operations)
	
	Result = False;
	
	If ValueIsFilled(Operations) Then
		
		CurVN = Operations[0].SetupSettings;
		For Each Operation In Operations Do
			
			If Not Operation.SetupSettings = CurVN Then
				Result = True;
				Break;
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return Result;
	
EndFunction

Function NewObjectScheduleOptions()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Operations", New TypeDescription("Array"));
	Result.Columns.Add("Schedule", New TypeDescription("ValueTable"));
	Result.Columns.Add("RCSelectionRule", New TypeDescription("String",, New StringQualifiers(150)));
	
	Return Result;
	
EndFunction

Function OperationQueue(Val PlanningParameters, Val Operations)
	
	Result = InitializeOperationQueue();
	
	For Each Operation In Operations Do
		NewRow = Result.Add();
		FillPropertyValues(NewRow, Operation);
		NewRow.Operation = Operation;
	EndDo;
	
	MultipleVN = OperationsHaveVariousAdjustmentOptions(Operations);
	If MultipleVN Then
		
		FillInChainDataInOperationQueue(PlanningParameters, Result);
		
	Else
		
		For Each String In Result Do
			String.ChainLaunchDate = String.StartDate2;
			String.TimeToPlaceChain = String.TimeToPlace;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FillInChainDataInOperationQueue(Val PlanningParameters, OperationQueue)
	
	OperationQueue.Sort("StartDate2 Asc, TimeToPlace Asc");
	
	ChainNumber = 1;
	
	For Each Operation In OperationQueue Do
		
		If Not ValueIsFilled(Operation.ChainNumber) Then
			
			ChainOperations = ChainOperations(OperationQueue, Operation);
			
			TimeToPlaceChain = 0;
			For Each ChainOperation In ChainOperations Do
				TimeToPlaceChain = TimeToPlaceChain + ChainOperation.TimeToPlace;
			EndDo;
							
			For Each ChainOperation In ChainOperations Do
				ChainOperation.ChainNumber = ChainNumber;
				ChainOperation.ChainLaunchDate = Operation.StartDate2;
				ChainOperation.TimeToPlaceChain = TimeToPlaceChain;
			EndDo;
			
		    ChainNumber = ChainNumber + 1;
		
		EndIf;
		
	EndDo;
	
EndProcedure

Function ChainOperations(Val OperationQueue, Val FirstOperation)
	
	Result = New Array;
	
	Result.Add(FirstOperation);
	CompletingChain = FirstOperation.StartDate2 + FirstOperation.TimeToPlace;
	
	For IndexOf = OperationQueue.IndexOf(FirstOperation)+1 To OperationQueue.Count()-1 Do
		
		NextOperation = OperationQueue[IndexOf];
		
		If NextOperation.StartDate2 <= CompletingChain Then
			
			If NextOperation.SetupSettings = FirstOperation.SetupSettings Then
				
				Result.Add(NextOperation);
				
				CompletionOfNext = NextOperation.StartDate2 + NextOperation.TimeToPlace;
				CompletingChain = Max(CompletingChain, CompletionOfNext);
				
			EndIf;
			
		Else
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function QueueOperationsOrderedByRule(OperationQueue, Val Rule)
	
	If Rule = OpRuleLaunchDateOfVozr() Then
		SortFields = "ChainLaunchDate ASC, SetupSettings, StartDate2 ASC";
	ElsIf Rule = OpSRuleIsBigThenSmall() Then
		SortFields = "TimeToPlaceChain DESC, ChainLaunchDate ASC, SetupSettings, StartDate2 ASC";
	Else
		SortFields = "ChainLaunchDate ASC, SetupSettings, StartDate2 ASC";
	EndIf;
	
	OperationQueue.Sort(SortFields);
	
	Result = New Array;
	For Each String In OperationQueue Do
		Result.Add(String.Operation);
	EndDo;
	
	Return Result;
	
EndFunction

Function InitializeOperationQueue()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Operation", New TypeDescription("ValueTableRow"));
	Result.Columns.Add("ChainNumber", New TypeDescription("Number", New NumberQualifiers(10)));
	Result.Columns.Add("SetupSettings", New TypeDescription("CatalogRef.SetupOptions"));
	Result.Columns.Add("StartDate2", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("ChainLaunchDate", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("TimeToPlace", New TypeDescription("Number", New NumberQualifiers(10)));
	Result.Columns.Add("TimeToPlaceChain", New TypeDescription("Number", New NumberQualifiers(10)));

	Return Result;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Operation - ValueTableRow -
// * BatchOperation_ - Structure -
// * Stage - DocumentRef.ProductionStage2_2 -
// * OperationID - Number -
// * LotNumber - Number -
// * PlacementParameters - Structure -
// * Begin - Date -
// * Ending - Date -
// * EstimateTime - See TMCommonUse.MoneyFieldTypeDescription
// * Cost - See TMCommonUse.MoneyFieldTypeDescription
Function NewOptionScheduleObject()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Operation", New TypeDescription("ValueTableRow"));
	Result.Columns.Add("BatchOperation_", New TypeDescription("Structure"));
	Result.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("LotNumber", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("PlacementParameters", New TypeDescription("Structure"));
	Result.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	Result.Columns.Add("EstimateTime", TMCommonUse.MoneyFieldTypeDescription());
	Result.Columns.Add("Cost", TMCommonUse.MoneyFieldTypeDescription());
	
	Result.Indexes.Add("Stage, OperationID");
	
	Return Result;
	
EndFunction

Function BestScheduleOption(Val PlanningParameters, Val ScheduleOptions_)
	
	If ScheduleOptions_.Count() = 1 Then
		
		Return ScheduleOptions_[0];
		
	Else
		
		CalculateTimeEstimateOfScheduleOptions(ScheduleOptions_);
		
		EvaluationTable = ScheduleOptionsEvaluationTable(ScheduleOptions_);
		EvaluationCriteria = CriteriaForEvaluatingPlanningModel(PlanningParameters);
		CalculateWeightedScore(EvaluationTable, EvaluationCriteria);
		
		EvaluationTable.Sort("WeightedAssessment Asc");
		
		Return ScheduleOptions_[EvaluationTable[0].IndexOf];
		
	EndIf;
	
EndFunction

Procedure DuplicatePlanningParameters(PlanningParameters, Val Operations, Val WorkCenterType)
	
	For Each Operation In Operations Do
		Operation.NumberOfPages_1 = Operation.Count;
	EndDo;
	
	PlanningParameters.Insert("DuplicatedParameters", New Structure);
	
	AuxiliaryVRC = TypesOfAuxiliaryWorkCentersOfOperations(PlanningParameters, Operations);
	
	DuplicateAvailableTime(PlanningParameters, WorkCenterType, AuxiliaryVRC);
	DuplicateBusyTimeByShift(PlanningParameters, WorkCenterType, AuxiliaryVRC);
	
EndProcedure

Procedure DuplicateAvailableTime(PlanningParameters, Val MainVRC, Val AuxiliaryVRC)
	
	SearchCondition = New Structure("WorkCenterType", MainVRC);
	
	TableEx = PlanningParameters.AvailableTime;
	PlanningParameters.DuplicatedParameters.Insert("AvailableTime", TableEx);
	
	DoubleTable = TableEx.Copy(FindRowsInTableWhileMaintainingOrder(TableEx, SearchCondition));
	
	For Each AuxiliaryVRC_ In AuxiliaryVRC Do
		
		SearchCondition.WorkCenterType = AuxiliaryVRC_;
		SearchBars = FindRowsInTableWhileMaintainingOrder(TableEx, SearchCondition);
			
		For Each String In SearchBars Do
			NewRow = DoubleTable.Add();
			FillPropertyValues(NewRow, String);
		EndDo;
		
	EndDo;
	
	CollapseTable(DoubleTable);	
	PlanningParameters.AvailableTime = DoubleTable;
	
EndProcedure

Procedure DuplicateBusyTimeByShift(PlanningParameters, Val MainVRC, Val AuxiliaryVRC)
	
	SearchCondition = New Structure("WorkCenterType", MainVRC);
	
	TableEx = PlanningParameters.BusyTimeByShift;
	PlanningParameters.DuplicatedParameters.Insert("BusyTimeByShift", TableEx);
	
	DoubleTable = TableEx.Copy(FindRowsInTableWhileMaintainingOrder(TableEx, SearchCondition));
	
	For Each AuxiliaryVRC_ In AuxiliaryVRC Do
		
		SearchCondition.WorkCenterType = AuxiliaryVRC_;
		SearchBars = FindRowsInTableWhileMaintainingOrder(TableEx, SearchCondition);
			
		For Each String In SearchBars Do
			NewRow = DoubleTable.Add();
			FillPropertyValues(NewRow, String);
		EndDo;
		
	EndDo;
	
	CollapseTable(DoubleTable);
	PlanningParameters.BusyTimeByShift = DoubleTable;
	
EndProcedure

Procedure RestoreDuplicatedSchedulingSettings(PlanningParameters)
	
	For Each Parameter In PlanningParameters.DuplicatedParameters Do
		
		PlanningParameters[Parameter.Key] = Parameter.Value;
	
	EndDo;
	
EndProcedure

Procedure ReflectPlacementOfOperationInPlanningParameters(PlanningParameters, Val Operation, Val PlacementParameters)
	
	If ValueIsFilled(PlacementParameters.WorkCenter) Then
			
		EmptyIntervals = New Array;
		
		WorkCenters = New Array;
		WorkCenters.Add(PlacementParameters.WorkCenter);
		For Each String In PlacementParameters.AuxiliaryRC Do
			WorkCenters.Add(String.WorkCenter);
		EndDo;
		
		For Each PlacementInterval In PlacementParameters.Intervals Do
			
			For Each WorkCenter In WorkCenters Do
				
				AvailableInterval = AvailableIntervalAccordingToCacheData(PlanningParameters,
					PlacementParameters.CacheOfAvailableIntervals, PlacementInterval, WorkCenter);
				
				If Not AvailableInterval = Undefined Then
					
					If Not ValueIsFilled(PlacementInterval.Load) Then
						BusyTime = PlacementInterval.TimePlan;
					Else
						BusyTime = PlacementInterval.TimePlan * PlacementInterval.Load;
					EndIf;
					ReflectBusyTimeByShift(PlanningParameters, AvailableInterval, WorkCenter, BusyTime);
					
					FixAvailableTime_(PlanningParameters, Operation, AvailableInterval, EmptyIntervals, PlacementInterval);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		RemoveEmptyAvailableTimeIntervals(PlanningParameters, EmptyIntervals);
	
	EndIf;
	
EndProcedure

Function AvailableIntervalAccordingToCacheData(Val PlanningParameters, Val CacheOfAvailableIntervals, Val PlacementInterval, Val WorkCenter)
	
	Result = Undefined;
	
	SearchConditionCache = New Structure("WorkCenter, Begin", WorkCenter, PlacementInterval.Begin);
	SearchStringsCache = CacheOfAvailableIntervals.FindRows(SearchConditionCache);
	
	If ValueIsFilled(SearchStringsCache) Then
		
		DataOfCache = SearchStringsCache[0];
		
		SearchCondition = New Structure("WorkCenter, StartOfShift");
		FillPropertyValues(SearchCondition, DataOfCache);
		
		SearchBars = PlanningParameters.AvailableTime.FindRows(SearchCondition);
		For Each String In SearchBars Do
			
			If String.Begin <= PlacementInterval.Begin And String.Ending >= PlacementInterval.Ending Then
				
				Result = String;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function TypesOfAuxiliaryWorkCentersOfOperations(Val PlanningParameters, Val Operations)
	
	Result = New Array;
	ProcessedObjects = New Array;
	
	For Each Operation In Operations Do
		
		AuxiliaryRC = AuxiliaryRCOperations(PlanningParameters, Operation.Stage, Operation.OperationID);
		
		For Each WorkCenter In AuxiliaryRC Do
			
			If ProcessedObjects.Find(WorkCenter) = Undefined Then
				
				If ValueTypeWorkCenter(WorkCenter) Then
					
					WorkCenterType = WorkCenterType(PlanningParameters, WorkCenter);
					If ProcessedObjects.Find(WorkCenterType) = Undefined Then
						Result.Add(WorkCenterType);
						ProcessedObjects.Add(WorkCenterType);
					EndIf;
					
				Else
					
					Result.Add(WorkCenter);
					
				EndIf;
				
				ProcessedObjects.Add(WorkCenter);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function OperationQueueRules(Val OperationQueue)
	
	Result = New Array;
	
	Result.Add(OpRuleLaunchDateOfVozr());
	
	If TimeSpreadOfQueueOperationsExceedsConstant(OperationQueue, 0.25) Then
		
		Result.Add(OpSRuleIsBigThenSmall());
		
	EndIf;
	
	Return Result;
	
EndFunction

Function RCSelectionRules(Val PlanningParameters, Val Operations)
	
	Result = New Array;
	
	Result.Add(RCRuleModelSettings());
	
	MultipleVN = OperationsHaveVariousAdjustmentOptions(Operations);
	If MultipleVN Then
		Result.Add(RCRuleMinimizeChangeovers());
	EndIf;
	
	Return Result;
	
EndFunction

Function OpRuleLaunchDateOfVozr()
	
	Return "LaunchDateAscending";
	
EndFunction

Function OpSRuleIsBigThenSmall()
	
	Return "DurationDecreasing";
	
EndFunction

Function RCRuleModelSettings()
	
	Return "PlanningModelSettings";
	
EndFunction

Function RCRuleMinimizeChangeovers()
	
	Return "MinimizeChangeoverTime";
	
EndFunction

Function TimeSpreadOfQueueOperationsExceedsConstant(Val OperationQueue, Val Const)
	
	Result = False;
	
	If OperationQueue.Count() > 1 Then
		
		MinValue_ = OperationQueue[0].TimeToPlace;
		Max_Value = OperationQueue[0].TimeToPlace;
		
		For Each Operation In OperationQueue Do
			
			MinValue_ = Min(MinValue_, Operation.TimeToPlace);
			Max_Value = Max(Max_Value, Operation.TimeToPlace);
			
			If MinValue_ > 0 Then
				
				Deviation = (Max_Value - MinValue_) / MinValue_;
				If Deviation >= Const Then
					
					Result = True;
					Break;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CalculateTimeEstimateOfScheduleOptions(ScheduleOptions_)
	
	If ScheduleOptions_.Count() > 1 Then
		
		For Each ScheduleOption1_ In ScheduleOptions_ Do
			ScheduleOption1_.Schedule.Sort("OperationID Asc");
		EndDo;
		
		For IndexOf = 0 To ScheduleOptions_[0].Schedule.Count()-1 Do
			
			StartingPoint = '00010101';
			For Each ScheduleOption1_ In ScheduleOptions_ Do
				CurBeginning = ScheduleOption1_.Schedule[IndexOf].Begin;
				If ValueIsFilled(CurBeginning) Then
					StartingPoint = ?(ValueIsFilled(StartingPoint), Min(StartingPoint, CurBeginning), CurBeginning);
				EndIf;
			EndDo;
			
			If ValueIsFilled(StartingPoint) Then
				
				MinimumDeviation = 0;
				For Each ScheduleOption1_ In ScheduleOptions_ Do
					
					WriteTimetable = ScheduleOption1_.Schedule[IndexOf];
					
					If ValueIsFilled(WriteTimetable.Ending) Then
						
						Deviation = WriteTimetable.Ending - StartingPoint;
						WriteTimetable.EstimateTime = Deviation;
						MinimumDeviation = ?(ValueIsFilled(MinimumDeviation), Min(MinimumDeviation, Deviation), Deviation);
						
					EndIf;
					
				EndDo;
				
				MaximumRating = 0;
				ThereAreUnplacedOperations = False;
				For Each ScheduleOption1_ In ScheduleOptions_ Do
					
					WriteTimetable = ScheduleOption1_.Schedule[IndexOf];
					
					If ValueIsFilled(WriteTimetable.EstimateTime) Then
						
						WriteTimetable.EstimateTime = ?(MinimumDeviation = 0, WriteTimetable.EstimateTime, WriteTimetable.EstimateTime/MinimumDeviation);
						MaximumRating = ?(ValueIsFilled(MaximumRating), Max(MaximumRating, WriteTimetable.EstimateTime), WriteTimetable.EstimateTime);
						
					Else
						ThereAreUnplacedOperations = True;
					EndIf;
					
				EndDo;
				
				If ThereAreUnplacedOperations Then
					
					For Each ScheduleOption1_ In ScheduleOptions_ Do
						
						WriteTimetable = ScheduleOption1_.Schedule[IndexOf];
						
						If Not ValueIsFilled(WriteTimetable.EstimateTime) Then
							// Unplaced transactions are assigned a penalty score of two times the amount relative to the worst placement.
							WriteTimetable.EstimateTime = MaximumRating * 2;
						EndIf;
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function ScheduleOptionsEvaluationTable(Val ScheduleOptions_)
	
	Result = New ValueTable;
	
	Result.Columns.Add("IndexOf", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("EstimateTime", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("Cost", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("WeightedAssessment", New TypeDescription("Number", New NumberQualifiers));
	
	For Each ScheduleOption1_ In ScheduleOptions_ Do
		
		NewRow = Result.Add();
		NewRow.IndexOf = ScheduleOptions_.IndexOf(ScheduleOption1_);
		NewRow.EstimateTime = ScheduleOption1_.Schedule.Total("EstimateTime");
		NewRow.Cost = ScheduleOption1_.Schedule.Total("Cost");
		
	EndDo;
	
	Return Result;
	
EndFunction

Function CriteriaForEvaluatingPlanningModel(Val PlanningParameters)
	
	Result = ObjectWeightedEvaluationCriteria();
	
	NewRow = Result.Add();
	NewRow.Weight = PlanningParameters.ValueMinimizeTime;
	NewRow.Optimum = "Min";
	NewRow.ColumnName = "EstimateTime";
	
	NewRow = Result.Add();
	NewRow.Weight = PlanningParameters.ValueMinimizeCost;
	NewRow.Optimum = "Min";
	NewRow.ColumnName = "Cost";
	
	Return Result;
	
EndFunction

Procedure MoveInteropTransitionsToSchedule(PlanningParameters)
	
	For Each String In PlanningParameters.InteroperableTransitions Do
		
		SearchCondition = New Structure("Stage, OperationID, Secondary", String.Stage, String.OperationID, False);
		SearchBars = FindRowsInTableWhileMaintainingOrder(PlanningParameters.ScheduleTable_, SearchCondition);
		If ValueIsFilled(SearchBars) Then
			SearchBars[SearchBars.UBound()].TransferTime = String.TransferTime;
		EndIf;
		
	EndDo;
	
EndProcedure

Function ObjectWeightedEvaluationCriteria()
	
	Result = New ValueTable;
	
	Result.Columns.Add("Weight");
	Result.Columns.Add("Optimum");
	Result.Columns.Add("ColumnName");
	
	Return Result;
	
EndFunction

Procedure CalculateWeightedScore(Val EvaluationTable, Val EvaluationCriteria)
	
	If Not ValueIsFilled(EvaluationTable) Then
		Return;
	EndIf;
		
	For Each Criterion In EvaluationCriteria Do
		
		Total = EvaluationTable.Total(Criterion.ColumnName);
		If Total > 0 Then
			
			For Each EvaluationString In EvaluationTable Do
				Evaluation = EvaluationString[Criterion.ColumnName] / Total;
				EvaluationString.WeightedAssessment = EvaluationString.WeightedAssessment + (Evaluation * Criterion.Weight);
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Result - ValueTable - 
// Returns:
// 	ValueTable - Where:
// * Stage - DocumentRef.ProductionStage2_2 -
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationID - Number -
// * LotNumber -  Number -
// * Count -  Number -
// * Date -  Date -
Function InitializeDataFromPreviousBatches(Result)
	
	Result.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Columns.Add("Operation", New TypeDescription("CatalogRef.ManufacturingOperations"));
	Result.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("LotNumber", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers()));
	Result.Columns.Add("Date", New TypeDescription("Date",,, New DateQualifiers));
		
	Return Result;
	
EndFunction

Procedure CheckDataOfPreviousBatches(Operation, BatchOperation_, ChangeDate_ = True)
	
	If Operation.DataFromPreviousBatches.Count() = 0 Then
		Return;
	EndIf;
	
	NumberOfPages_1 = BatchOperation_.Count / BatchOperation_.ZoomRatio;
	
	If Not Operation.PrecedingDataIsSorted Then
		Operation.DataFromPreviousBatches.Sort("Count Desc, Date Asc");
		Operation.PrecedingDataIsSorted = True;
	EndIf;
	
	StartDate2 = Operation.StageStart;
	LaunchDateFound = True;
	
	PreviousOperations = Operation.DataFromPreviousBatches.Copy(, "Stage, Operation, OperationID"); // See InitializeDataFromPreviousBatches
	PreviousOperations.GroupBy("Stage, Operation, OperationID");
	
	StructureOfSelectionOfAntecedents = New Structure("Stage, Operation, OperationID");
	For Each PreviousOperation_ In PreviousOperations Do
		
		FillPropertyValues(StructureOfSelectionOfAntecedents, PreviousOperation_);
		FoundRows = Operation.DataFromPreviousBatches.FindRows(StructureOfSelectionOfAntecedents);
		
		Date = '00010101';
		Count = NumberOfPages_1;
		RemainderOfPrecedingIsSufficient = False;
		
		For Each PreviousBatchData In FoundRows Do
			If PreviousBatchData.Count = 0 Then
				Continue;
			ElsIf Count <= PreviousBatchData.Count Then
				RemainderOfPrecedingIsSufficient = True;
				PreviousBatchData.Count = PreviousBatchData.Count - Count;
				Count = 0;
			Else
				Count = Count - PreviousBatchData.Count;
				PreviousBatchData.Count = 0;
			EndIf;
			If PreviousBatchData.Date > Date Then
				Date = PreviousBatchData.Date;
			EndIf;
			If Count = 0 Then
				Break;
			EndIf;
		EndDo;
		
		If Not RemainderOfPrecedingIsSufficient
			Or Not ValueIsFilled(Date) Then
			LaunchDateFound = False;
		EndIf;
		
		If LaunchDateFound
			And Date > StartDate2 Then
			StartDate2 = Date;
		EndIf;			
		
	EndDo;
	
	If ChangeDate_
		And LaunchDateFound Then
		BatchOperation_.StartDate2 = StartDate2;
	EndIf;
	
EndProcedure

#EndRegion

#Region TimetableIssues

Procedure FIXErrorUnavailableOSNRegionalServiceCenter(PlanningParameters, Val PickingParameters)
	
	WorkCenter = PickingParameters.WorkCenter;
	AuxiliaryRC = PickingParameters.InaccessibleAuxiliaryRC;
	Operation = PickingParameters.Operation;
	DirectPlacement = PickingParameters.DirectPlacement;
	
	If ValueIsFilled(AuxiliaryRC) Then
		
		For Each AuxiliaryWorkCenter In AuxiliaryRC Do
			FixUnavailableWorkCenterError(PlanningParameters.TimetableIssues, AuxiliaryWorkCenter, PickingParameters);
		EndDo;
		
	Else
		FixUnavailableWorkCenterError(PlanningParameters.TimetableIssues, WorkCenter, PickingParameters);
	EndIf;
	
EndProcedure

Procedure FixUnavailableWorkCenterError(TimetableIssues, Val WorkCenter, Val PickingParameters)
	
	Category = Enums.IssueCategoriesOfOperationTimetable.WorkCenterIsUnavailable;
	Var_Key = WorkCenter;
	
	ProblemFixed = ProblemFixed(TimetableIssues, Category, Var_Key);
	
	If Not ProblemFixed Then
		
		NewRow = TimetableIssues.Add();
		NewRow.Category = Category;
		NewRow.Type = 2;
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có đủ thời gian trung tâm làm việc có sẵn ""%1"" của loại ""%2"".';
					|ru = 'Недостаточно доступного времени рабочего центра ""%1"" вида ""%2"".';
					|en = 'There is not enough available time of the ""%1"" work center of the ""%2"" type.'; fa = 'There is not enough available time of the ""%1"" work center of the ""%2"" type.';
					|it = 'Il tempo disponibile del centro di lavoro ""%1"" tipo ""%2"" è insufficiente.';
					|pl = 'Za mało dostępnego czasu centrum pracy ""%1"" rodzaju ""%2"".';
					|tr = '""%2"" türündeki ""%1"" iş merkezi zaman kapasitesi yetersiz.'"),
				Common.ObjectAttributeValue(WorkCenter, "Presentation"),
				Common.ObjectAttributeValue(WorkCenter, "WorkCenterType.Presentation"));
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có đủ thời gian có sẵn cho chế độ xem trung tâm làm việc ""%1"".';
					|ru = 'Недостаточно доступного времени вида рабочего центра ""%1"".';
					|en = 'There is not enough available time of the ""%1"" work center type.'; fa = 'There is not enough available time of the ""%1"" work center type.';
					|it = 'Il tempo disponibile del tipo di centro di lavoro ""%1"" è insufficiente.';
					|pl = 'Za mało dostępnego czasu rodzaju centrum pracy ""%1"".';
					|tr = '""%1"" iş merkezi zaman kapasitesi türü yetersiz.'"),
				Common.ObjectAttributeValue(WorkCenter, "Presentation"));
		EndIf;
		NewRow.Text = Text;
		
		NewRow.WhatToDoNext = NStr("vi = 'Hãy điền mức độ khả dụng của các dạng nguồn lực sản xuất hoặc mở rộng khoảng lập kế hoạch.';
									|ru = 'Заполните доступность видов рабочих центров или увеличьте горизонт планирования.';
									|en = 'Fill in capacity of work center types or increase the planning horizon.'; fa = 'Fill in capacity of work center types or increase the planning horizon.';
									|it = 'Compilare la disponibilità dei tipi dei centri di lavoro o aumentare l''orizzonte di pianificazione.';
									|pl = 'Wypełnij dostępność rodzaju centrum pracy, lub zwiększ horyzont planowania.';
									|tr = 'İş merkezleri türleri kapasitelerini doldurun veya planmala süresini artırın.'");
		
		Properties = New Structure;
		Properties.Insert("WorkCenter", WorkCenter);
		Properties.Insert("WorkCenterType", Common.ObjectAttributeValue(WorkCenter, "WorkCenterType"));
		Properties.Insert("Period", PickingParameters.TimeOfPlacement);
		NewRow.Properties = Properties;
		
		NewRow.Key = Var_Key;
		
	EndIf;
	
EndProcedure

Procedure FixScheduleBlockedError(PlanningParameters)
	
	Category = Enums.IssueCategoriesOfOperationTimetable.TimetableIsBeingCalculated;
	Var_Key = PlanningParameters.Department;
	
	ProblemFixed = ProblemFixed(PlanningParameters.TimetableIssues, Category, Var_Key);
	
	If Not ProblemFixed Then
		
		NewRow = PlanningParameters.TimetableIssues.Add();
		NewRow.Category = Category;
		NewRow.Type = 1;
		
		Text = NStr("vi = 'Kế hoạch không thể được hoàn thành vì một lý do: lịch trình ở trạng thái khấu trừ';
					|ru = 'Планирование не может быть выполнено по причине: расписание находится в состоянии расчета';
					|en = 'Cannot perform planning. Reason: the timetable is being calculated.'; fa = 'Cannot perform planning. Reason: the timetable is being calculated.';
					|it = 'La pianificazione non può essere eseguita per motivo: l''orario è in fase di calcolo';
					|pl = 'Planowanie nie może być wykonane z powodu: harmonogram znajduje się w statusie obliczenia';
					|tr = 'Planlama şu nedenden dolayı gerçekleştirilemez: Çizelge, hesaplama durumunda bulunmaktadır'");
		User = InformationRegisters.BlockingOperationalSchedule2_2.DivisionScheduleAuthorBlocking(
			PlanningParameters.Department);
		If ValueIsFilled(User) Then
			UserPresentation = Common.ObjectAttributeValue(User, "Presentation");
			Text = Text + " " + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '(người dùng: %1)';
					|ru = '(пользователь: %1 )';
					|en = '(user: %1 )'; fa = '(user: %1 )';
					|it = '(utente: %1 )';
					|pl = '(użytkownik: %1 )';
					|tr = '(kullanıcı: %1 )'"), UserPresentation);
		EndIf;
		NewRow.Text = Text;
		
		NewRow.WhatToDoNext = NStr("vi = 'Chờ cho đến khi tính toán lịch trình hoàn tất.';
									|ru = 'Дождитесь окончания расчета расписания.';
									|en = 'Please wait while the schedule is being generated.'; fa = 'Please wait while the schedule is being generated.';
									|it = 'Attendere il termine del calcolo dell''orario.';
									|pl = 'Poczekaj na zakończenia obliczania harmonogramu.';
									|tr = 'Çizelge hesaplamasının bitmesini bekleyin.'");
		NewRow.Properties = New Structure("Department", PlanningParameters.Department);
		NewRow.Key = Var_Key;
		
	EndIf;
	
EndProcedure

Procedure FIXErrorMissingDataForScheduling(PlanningParameters)
	
	Category = Enums.IssueCategoriesOfOperationTimetable.NoOperationsForScheduling;
	Var_Key = PlanningParameters.Department;
	
	ProblemFixed = ProblemFixed(PlanningParameters.TimetableIssues, Category, Var_Key);
	
	If Not ProblemFixed Then
		
		NewRow = PlanningParameters.TimetableIssues.Add();
		NewRow.Category = Category;
		NewRow.Type = 1;
		NewRow.Text = NStr("vi = 'Lập kế hoạch không thể được thực hiện vì một lý do: không có hoạt động để lập kế hoạch.';
							|ru = 'Планирование не может быть выполнено по причине: отсутствуют операции для планирования.';
							|en = 'Cannot perform planning. Reason: no operations to plan.'; fa = 'Cannot perform planning. Reason: no operations to plan.';
							|it = 'La pianificazione non può essere eseguita a causa di: non ci sono operazioni da pianificare.';
							|pl = 'Planowanie nie może być wykonane z powodu: brak operacji do planowania.';
							|tr = 'Planlama şu nedenden dolayı gerçekleştirilemez: Planlama için işlem bulunmamaktadır.'");
		NewRow.WhatToDoNext = NStr("vi = 'Tạo các công đoạn sản xuất hoặc thay đổi các thông số kế hoạch.';
									|ru = 'Создайте этапы производства, либо измените параметры планирования.';
									|en = 'Create production stages or change planning parameters.'; fa = 'Create production stages or change planning parameters.';
									|it = 'Creare le fasi di produzione o modificare i parametri di pianificazione.';
									|pl = 'Utwórz etapy produkcji, albo zmień ustawienia planowania.';
									|tr = 'Üretim aşamalarını oluşturun veya planlama parametrelerini değiştirin.'");
		NewRow.Properties = New Structure("Department", PlanningParameters.Department);
		NewRow.Key = Var_Key;
		
	EndIf;
	
EndProcedure

Procedure FixWorkCentersNotDefinedError(PlanningParameters, WorkCenterType)
	
	Category = Enums.IssueCategoriesOfOperationTimetable.WorkCentersAreNotDefined;
	Var_Key = WorkCenterType;
	
	ProblemFixed = ProblemFixed(PlanningParameters.TimetableIssues, Category, Var_Key);
	
	If Not ProblemFixed Then
		
		NewRow = PlanningParameters.TimetableIssues.Add();
		NewRow.Category = Category;
		NewRow.Type = 2;
		
		SubstitutionString = NStr("vi = 'Các trung tâm làm việc loại ''''%1'''' không được tạo';
									|ru = 'Не созданы рабочие центры вида ""%1""';
									|en = 'Work centers of the ""%1"" type are not created'; fa = 'Work centers of the ""%1"" type are not created';
									|it = 'I centri di lavoro del tipo ""%1"" non sono creati';
									|pl = 'Nie zostały utworzone centrum pracy rodzaju ""%1""';
									|tr = '""%1"" türündeki iş merkezleri oluşturulmadı'");
		PresentationOfVRC = Common.ObjectAttributeValue(WorkCenterType, "Presentation");
		NewRow.Text = StringFunctionsClientServer.SubstituteParametersToString(SubstitutionString, PresentationOfVRC);
		
		NewRow.WhatToDoNext = NStr("vi = 'Tạo mới nguồn lực sản xuất.';
									|ru = 'Создайте рабочие центры.';
									|en = 'Create work centers.'; fa = 'Create work centers.';
									|it = 'Creare i centri di lavoro.';
									|pl = 'Utwórz centrum pracy.';
									|tr = 'İş merkezlerini oluşturun.'");
		NewRow.Properties = New ValueStorage(PlanningParameters.Department);
		NewRow.Key = Var_Key;
		
	EndIf;
	
EndProcedure

Procedure FixErrorWorkCentersDidNotFitLoad(PlanningParameters, WorkCenter, Operation)
	
	Category = Enums.IssueCategoriesOfOperationTimetable.WorkCentersWereNotSuitableByLoad;
	Var_Key = WorkCenter;
	
	ProblemFixed = ProblemFixed(PlanningParameters.TimetableIssues, Category, Var_Key);
	
	If Not ProblemFixed Then
		
		NewRow = PlanningParameters.TimetableIssues.Add();
		NewRow.Category = Category;
		NewRow.Type = 2;
		
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Nguồn lực sản xuất ""%1"" không phù hợp với tải tối đa đối với thao tác ""%2""';
					|ru = 'Рабочий центр ""%1"" не подходит по максимальной загрузке для операции ""%2""';
					|en = '""%1"" work center does not fit maximum load for the ""%2"" operation'; fa = '""%1"" work center does not fit maximum load for the ""%2"" operation';
					|it = '""%1"" work center does not fit maximum load for the ""%2"" operation';
					|pl = '""%1"" work center does not fit maximum load for the ""%2"" operation';
					|tr = '""%2"" işlemi için ""%1"" iş merkezi, maksimum çalışma yüküne uygun değildir'"),
				WorkCenter, Operation.Description);
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các nguồn lực sản xuất dạng ""%1"" không phù hợp với tải tối đa đối với thao tác ""%2""';
					|ru = 'Рабочие центры вида ""%1"" не подходят по максимальной загрузке для операции ""%2""';
					|en = 'Work centers of the ""%1"" type do not fit maximum load for the ""%2"" operation'; fa = 'Work centers of the ""%1"" type do not fit maximum load for the ""%2"" operation';
					|it = 'Work centers of the ""%1"" type do not fit maximum load for the ""%2"" operation';
					|pl = 'Work centers of the ""%1"" type do not fit maximum load for the ""%2"" operation';
					|tr = '""%2"" işlemi için ""%1"" türündeki iş merkezleri, maksimum çalışma yüküne uygun değildir'"),
				WorkCenter, Operation.Description);
		EndIf;
		
		If ValueIsFilled(Operation.Operation) Then
			Text = Text + " " + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'lộ trình ""%1""';
					|ru = 'маршрута ""%1""';
					|en = 'of the ""%1"" route'; fa = 'of the ""%1"" route';
					|it = 'of the ""%1"" route';
					|pl = 'of the ""%1"" route';
					|tr = '""%1"" rotası'"),
				Common.ObjectAttributeValue(Operation.Operation, "Owner"));
		EndIf;
		
		NewRow.Text = Text;
		
		NewRow.WhatToDoNext = NStr("vi = 'Thay thế nguồn lực sản xuất trong lộ trình.';
									|ru = 'Заменить рабочий центр в маршруте.';
									|en = 'Replace work center in route.'; fa = 'Replace work center in route.';
									|it = 'Sostituire il centro di lavoro nel percorso.';
									|pl = 'Zmień centrum pracy w trasie.';
									|tr = 'Rotadaki iş merkezini değiştir.'");
		
		Properties = New Structure;
		If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenters") Then
			Properties.Insert("WorkCenter", WorkCenter);
			Properties.Insert("WorkCenterType", Common.ObjectAttributeValue(WorkCenter, "WorkCenterType"));
		Else
			Properties.Insert("WorkCenterType", WorkCenter);
		EndIf;
		NewRow.Properties = Properties;
		
		NewRow.Key = Var_Key;
		
	EndIf;
	
EndProcedure

Function ProblemFixed(Val TimetableIssues, Val Category, Val Var_Key)
	
	Result = False;
	
	SearchCondition = New Structure("Category", Category);
	SearchBars = TimetableIssues.FindRows(SearchCondition);
	
	For Each SearchString In SearchBars Do
		
		If SearchString.Key = Var_Key Then
			
			Result = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ReadProblemsFromBackgroundCalculationResults(PlanningParameters, TimetableIssues)
	
	For Each String In TimetableIssues Do
		
		If Not ProblemFixed(PlanningParameters.TimetableIssues, String.Category, String.Key) Then
			
			NewRow = PlanningParameters.TimetableIssues.Add();
			FillPropertyValues(NewRow, String);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CalculationResult2

Procedure RecordModelCalculationResults(Val PlanningParameters)
	
	InformationRegisters.PostOperativeSchedule2_2.RecordScheduleOption(
		PlanningParameters.TimetableModel,
		PlanningParameters.PlanningModel,
		PlanningParameters.ScheduleTable_);
	
EndProcedure

Function InitializeCalculationResults()
	
	Result = New Structure;
	
	Result.Insert("TimetableModel", Undefined);
	Result.Insert("OptimumPlanningModel", Catalogs.MESModels.EmptyRef());
	Result.Insert("PostedOperations", 0);
	Result.Insert("DataVolume", 0);
	Result.Insert("TheCalculationIsPerformed", False);
	Result.Insert("ScenariosAreUsed", False);
	Result.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	Result.Insert("TimetableIssues", InitializeScheduleProblemTable());
	
	Return Result;
	
EndFunction

Procedure FillInCalculationResults(PlanningParameters)
	
	CalculationResults = PlanningParameters.CalculationResults;
	FillPropertyValues(CalculationResults, PlanningParameters);
	
	PostedOperations = NumberOfOperationsPlaced(PlanningParameters);
	CalculationResults.PostedOperations = PostedOperations;
	CalculationResults.TheCalculationIsPerformed = Not (PostedOperations = 0);
	
	ScenariosAreUsed = ScenariosAreUsed(PlanningParameters);
	CalculationResults.ScenariosAreUsed = ScenariosAreUsed;
	
	If Not ScenariosAreUsed
		And ValueIsFilled(PlanningParameters.ParametersOfPlanningModels) Then
		OptimalModel = PlanningParameters.ParametersOfPlanningModels[0].PlanningModel;
		CalculationResults.OptimumPlanningModel = OptimalModel;
	EndIf;
	
	OperationsCount = PlanningParameters.Operations.Count();
	NumberOfModels = PlanningParameters.ParametersOfPlanningModels.Count();
	CalculationResults.DataVolume = OperationsCount * NumberOfModels;
	
EndProcedure

Procedure AddLogEntry(Val Level, Val Comment, Val MetadataObject=Undefined, Val Data=Undefined)
	
	EventName = NStr(
		"vi = 'Kế hoạch hoạt động 2.2';
		|ru = 'Пооперационное планирование 2.2';
		|en = 'Manufacturing execution system 2.2'; fa = 'سیستم اجرای تولید 2.2';
		|it = 'Pianificazione delle operazioni consecutive 2.2';
		|pl = 'Planowanie wg operacji 2.2';
		|tr = 'Üretim Yürütme Sistemi 2.2'",
		CommonClientServer.DefaultLanguageCode());
	
	WriteLogEvent(EventName, Level, MetadataObject, Data, Comment);
	
EndProcedure

Function NumberOfOperationsPlaced(Val PlanningParameters)
	
	Return InformationRegisters.PostOperativeSchedule2_2.NumberOfUniqueScheduleModelOperations(PlanningParameters.TimetableModel);
	
EndFunction

#EndRegion

#Region Other

Function FindRowsInTableWhileMaintainingOrder(Table, SearchCondition) Export
	
	SearchStringsWithoutOrder = Table.FindRows(SearchCondition);
	
	If SearchStringsWithoutOrder.Count() > 1 Then
		
		TableIndexes__ = IndexesOfTableAndFoundTableRows(Table, SearchStringsWithoutOrder);
		RowsAreOrdered = IndexTableIsOrdered(TableIndexes__);
		
		If RowsAreOrdered Then
			Return SearchStringsWithoutOrder;
		Else
			TableIndexes__.Sort("TableIndex ASC");
			SearchStringsWithOrder = New Array;
			For Each String In TableIndexes__ Do
				SearchStringsWithOrder.Add(SearchStringsWithoutOrder[String.ArrayIndex]);
			EndDo;
			
			Return SearchStringsWithOrder;
		EndIf;
		
	Else
		Return SearchStringsWithoutOrder;
	EndIf;
	
EndFunction

Function IndexesOfTableAndFoundTableRows(Table, SearchStringsWithoutOrder)
	
	Result = New ValueTable;
	Result.Columns.Add("ArrayIndex", New TypeDescription("Number", New NumberQualifiers));
	Result.Columns.Add("TableIndex", New TypeDescription("Number", New NumberQualifiers));
	
	IndexOf = 0;
	For Each String In SearchStringsWithoutOrder Do
		NewRow = Result.Add();
		NewRow.ArrayIndex = IndexOf;
		NewRow.TableIndex = Table.IndexOf(String);
		
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return Result;
	
EndFunction

Function IndexTableIsOrdered(TableIndexes__)
	
	Result = True;
	
	PrecedingLine = Undefined;
	For Each String In TableIndexes__ Do
		
		If Not PrecedingLine = Undefined Then
			
			If String.TableIndex < PrecedingLine.TableIndex Then
				Result = False;
				Break;
			EndIf;
			
		EndIf;
		
		PrecedingLine = String;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure WaitForBackgroundJobsToComplete(Val JobMethodName, Val JobDescription)
	
	FilterOfTasks = New Structure;
	FilterOfTasks.Insert("MethodName", JobMethodName);
	FilterOfTasks.Insert("Description", JobDescription);
	FilterOfTasks.Insert("State", BackgroundJobState.Active);
	
	Jobs = BackgroundJobs.GetBackgroundJobs(FilterOfTasks);
	If ValueIsFilled(Jobs) Then
		BackgroundJobs.WaitForCompletion(Jobs);
	EndIf;
	
EndProcedure

Function ValueTypeWorkCenter(Val Value)
	
	If TypeOf(Value) = Type("CatalogRef.WorkCenters")
		Or TypeOf(Value) = Type("String") Then
		Result = True;
	Else
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

Function WorkCenterType(Val PlanningParameters, Val WorkCenter)
	
	SearchString = PlanningParameters.TableOfWorkCenters.Find(WorkCenter, "WorkCenter");
	
	If SearchString = Undefined Then
		Result = Undefined;
	Else
		Result = SearchString.WorkCenterType;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixOperationsTableBasedOnMissingOperations(PlanningParameters)
	
	SearchCondition = New Structure("Stage, OperationID");
	SearchConditionForPresh = New Structure("Stage, OperationIDPreceding");
	
	MissingOperations = RelatedOperationsNotInvolvedInCalculation(PlanningParameters.TableOfOperationDependencies);
	If Not ValueIsFilled(MissingOperations) Then
		Return;
	EndIf;
	
	OperationData_ = MissingOperationsData(MissingOperations);
	For Each Missing_ In OperationData_ Do
		
		SearchCondition.Stage = Missing_.Stage;
		SearchCondition.OperationID = Missing_.OperationID;
		DependenciesStrings = PlanningParameters.TableOfOperationDependencies.FindRows(SearchCondition);
		For Each Dependence In DependenciesStrings Do
			
			OperationString = OperationTableOfOperations(PlanningParameters, 
							Dependence.Stage, Dependence.OperationIDPreceding);
				
			If ValueIsFilled(OperationString) Then
				
				OperationString.DateOfProduction = DateOfIssueOfChildOperation(
					PlanningParameters, Missing_, Missing_.Begin, OperationString);
					
				ReplaceWorkCenterOfChildOperationsRecursively(
					PlanningParameters, Missing_, OperationString, Missing_.DesignatedWorkCenter, False);
				
			EndIf;
			
		EndDo;
		
		SearchConditionForPresh.OperationIDPreceding = Missing_.OperationID;
		DependenciesStrings = PlanningParameters.TableOfOperationDependencies.FindRows(SearchConditionForPresh);
		For Each Dependence In DependenciesStrings Do
			
			OperationString = OperationTableOfOperations(PlanningParameters, 
							Dependence.Stage, Dependence.OperationID);
				
			If ValueIsFilled(OperationString) Then
				
				OperationString.StartDate2 = DateWhenChildOperationWasStarted(
					PlanningParameters, Missing_, Missing_.Ending, OperationString);
				
				ReplaceWorkCenterOfChildOperationsRecursively(
					PlanningParameters, Missing_, OperationString, Missing_.DesignatedWorkCenter, True);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function FindInteroperableTransitionTime(Val PlanningParameters, Val Department,
	Val Source = Undefined, Val Receiver = Undefined)
	
	If ValueIsFilled(PlanningParameters.InteroperationTransferParameters) Then
		
		If Not ValueIsFilled(Source) Then
			Source = Catalogs.WorkCenterTypes.EmptyRef();
		EndIf;
		
		If Not ValueIsFilled(Receiver) Then
			Receiver = Catalogs.WorkCenterTypes.EmptyRef();
		EndIf;
		
		SearchCondition = New Structure;
		SearchCondition.Insert("Department", Department);
		SearchCondition.Insert("Source", Source);
		SearchCondition.Insert("Receiver", Receiver);
		
		SearchBars = PlanningParameters.InteroperationTransferParameters.FindRows(SearchCondition);
		If ValueIsFilled(SearchBars) Then
			Return SearchBars[0].Time;
		Else
			Return 0;
		EndIf;
		
	Else
		Return 0;
	EndIf;

EndFunction

Procedure FillInDependenceOnPreviousOperationsInTable(PlanningParameters)
	
	TransactionTable = PlanningParameters.TransactionTable;
	DependenciesTable = PlanningParameters.TableOfOperationDependencies;
	
	TransactionTable.FillValues(True, "DependsOnPreceding");
	
	SearchCondition = New Structure("PrecedingOperationIsInvolvedInCalculation, OperationID, Stage", True);
	For Each String In TransactionTable Do
		
		SearchCondition.Stage = String.Stage;
		SearchCondition.OperationID = String.OperationID;
		
		SearchBars = DependenciesTable.FindRows(SearchCondition);
		If Not ValueIsFilled(SearchBars) Then
			String.DependsOnPreceding = False;
		EndIf;
		
	EndDo;
	
EndProcedure

Function DescriptionOfTypesOperationTimeDepth()
	
	Result = New TypeDescription("Number", New NumberQualifiers(15, 1));
	Return Result;
	
EndFunction

Procedure AddTypeToValueTypeOfTableColumn(Table, Val ColumnName, Val AddedTypes,
	Val NumberQualifiers=Undefined, Val StringQualifiers=Undefined, Val DateQualifiers=Undefined)
	
	If NumberQualifiers = Undefined Then
		NumberQualifiers = New NumberQualifiers;
	EndIf;
	
	If StringQualifiers = Undefined Then
		StringQualifiers = New StringQualifiers;
	EndIf;
	
	If DateQualifiers = Undefined Then
		DateQualifiers = New DateQualifiers;
	EndIf;
	
	DescriptionOfNewTypes = New TypeDescription(Table.Columns[ColumnName].ValueType,
		AddedTypes,, NumberQualifiers, StringQualifiers, DateQualifiers);
	ColumnNameNew = ColumnName + "Copy";
	Table.Columns.Add(ColumnNameNew, DescriptionOfNewTypes);
	
	For Each String In Table Do
		String[ColumnNameNew] = String[ColumnName];
	EndDo;
	
	Table.Columns.Delete(ColumnName);
	Table.Columns[ColumnNameNew].Name = ColumnName;
	
EndProcedure

// Parameters:
// 	Begin - Date -
// 	Ending - Date -
// 	WorkCenters - Array -
// Returns:
// 	ValueTable - Where:
// * Begin - Date -
// * Ending - Date -
// * WorkCenter - CatalogRef.WorkCenters -
// * Time - Date -
Function AvailableTimeOfWorkCentersAccordingToSchedule(Begin, Ending, WorkCenters)
	
	Query = New Query(
	"SELECT ALLOWED
	|	AvailabilityOfWorkCenters.Begin AS Begin,
	|	AvailabilityOfWorkCenters.Ending AS Ending,
	|	AvailabilityOfWorkCenters.WorkCenter AS WorkCenter,
	|	DATEDIFF(AvailabilityOfWorkCenters.Begin, AvailabilityOfWorkCenters.Ending, SECOND) AS Time
	|FROM
	|	InformationRegister.AvailabilityOfWorkCenters AS AvailabilityOfWorkCenters
	|WHERE
	|	(AvailabilityOfWorkCenters.Begin BETWEEN &Begin AND &Ending
	|			OR AvailabilityOfWorkCenters.Ending BETWEEN &Begin AND &Ending)
	|	AND AvailabilityOfWorkCenters.WorkCenter IN(&WorkCenters)");
	
	Query.SetParameter("Begin", Begin);
	Query.SetParameter("Ending", Ending);
	Query.SetParameter("WorkCenters", WorkCenters);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure SortTableAvailableTime(Table)
	
	Table.Sort("WorkCenter, Begin Asc, Ending Asc", New CompareValues);
	
EndProcedure

Procedure DeleteTableRowsByCondition(Table, Val SearchCondition)
	
	SearchBars = Table.FindRows(SearchCondition);
	For Each SearchString In SearchBars Do
		Table.Delete(SearchString);
	EndDo;
	
EndProcedure

Function DateTimeInSeconds(DateTime)
	
	Result = Hour(DateTime)*3600 + Minute(DateTime)*60 + Second(DateTime);
	Return Result;
	
EndFunction

Procedure FixTimeOfInteroperableTransition(PlanningParameters, Val SenderOperation, Val Time)
	
	NewRow = PlanningParameters.InteroperableTransitions.Add();
	FillPropertyValues(NewRow, SenderOperation);
	NewRow.TransferTime = Time;
	
EndProcedure

Function PlanningBoundaries(Val PlanningParameters)
	
	Horizon = PlanningParameters.PlanningHorizon;
	Begin = BegOfDay(PlanningParameters.PlanningTimepoint);
	Ending = EndOfDay(PlanningParameters.PlanningTimepoint + (86400 * Horizon));
	
	Return New Structure("Begin, Ending", Begin, Ending);
	
EndFunction

Function DateWhenChildOperationWasStarted(PlanningParameters, Val OperationParent, Val ParentRelease, Val OperationDescendant)
	
	TransferTime = InteroperableTransitionTime(PlanningParameters, OperationParent.Department,
		OperationParent.WorkCenter, OperationDescendant.WorkCenter);
	If ValueIsFilled(TransferTime) Then
		FixTimeOfInteroperableTransition(PlanningParameters, OperationParent, TransferTime);
	EndIf;
	
	DescendantLaunch = ParentRelease + TransferTime;
	Result = Max(OperationDescendant.StartDate2, DescendantLaunch);
	
	Return Result;
	
EndFunction

Function DateOfIssueOfChildOperation(PlanningParameters, Val OperationParent, Val ParentLaunch, Val OperationDescendant)
	
	TransferTime = InteroperableTransitionTime(PlanningParameters, OperationDescendant.Department,
		OperationDescendant.WorkCenter, OperationParent.WorkCenter);
	If ValueIsFilled(TransferTime) Then
		FixTimeOfInteroperableTransition(PlanningParameters, OperationDescendant, TransferTime);
	EndIf;
	
	DescendantIssue = ParentLaunch - TransferTime;
	Result = Min(OperationDescendant.DateOfProduction, DescendantIssue);
	
	Return Result;
	
EndFunction

Procedure ReplaceWorkCenterOfChildOperationsRecursively(PlanningParameters, Val Operation, DependentOperation, Val WorkCenter, Val DirectPlacement)
	
	If TypeOf(Operation.WorkCenter) = Type("CatalogRef.WorkCenterTypes")
		And ValueIsFilled(Operation.WorkCenter)
		And TypeOf(DependentOperation.WorkCenter) = Type("CatalogRef.WorkCenterTypes")
		And Operation.WorkCenter = DependentOperation.WorkCenter Then
		
		DependentOperations = RelatedOperations(PlanningParameters, 
							DependentOperation.Stage, DependentOperation.OperationID, True, DirectPlacement);
		For Each DependentDependentOperation In DependentOperations Do
			ReplaceWorkCenterOfChildOperationsRecursively(
				PlanningParameters, DependentOperation, DependentDependentOperation, WorkCenter, DirectPlacement);
		EndDo;
		
		DependentOperation.WorkCenter = WorkCenter;
		
	Else
		Return;
	EndIf;
	
EndProcedure

Function RelatedOperations(Val PlanningParameters, Val Stage, Val OperationID, Val Subsidiaries, Val DirectPlacement)
	
	If (DirectPlacement And Subsidiaries) 
		Or (Not DirectPlacement And Not Subsidiaries)	Then
		
		DependentOperations = SubsequentOperations(PlanningParameters, Stage, OperationID);
		
	Else
		
		DependentOperations = PreviousOperations(PlanningParameters, Stage, OperationID);
		
	EndIf;
	
	Return DependentOperations;
	
EndFunction

Function OperationTableOfOperations(Val PlanningParameters, Val Stage, Val OperationID)
	
	TheStructureOfTheSearch = New Structure("Stage, OperationID");
	TheStructureOfTheSearch.Stage = Stage;
	TheStructureOfTheSearch.OperationID = OperationID;
	
	Operations = PlanningParameters.TransactionTable.FindRows(TheStructureOfTheSearch);
	
	If Operations.Count() = 0 Then
		Operation = Undefined;
	Else
		Operation = Operations[0];
	EndIf;
	
	Return Operation;
	
EndFunction

Function SubsequentOperations(Val PlanningParameters, Val Stage, Val OperationID)
	
	Result = New Array;
	
	SearchCondition = New Structure("Stage, OperationIDPreceding", Stage, OperationID);
	SearchBars = PlanningParameters.TableOfOperationDependencies.FindRows(SearchCondition);
	For Each String In SearchBars Do
		
		Operation = OperationTableOfOperations(PlanningParameters, String.Stage, String.OperationID);
		If Not Operation = Undefined Then
			Result.Add(Operation);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function PreviousOperations(Val PlanningParameters, Val Stage, Val OperationID)
	
	Result = New Array;
	
	SearchCondition = New Structure("Stage, OperationID", Stage, OperationID);
	SearchBars = PlanningParameters.TableOfOperationDependencies.FindRows(SearchCondition);
	For Each String In SearchBars Do
		
		Operation = OperationTableOfOperations(PlanningParameters, String.Stage, String.OperationIDPreceding);
		If Not Operation = Undefined Then
			Result.Add(Operation);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function InteroperableTransitionTime(Val PlanningParameters, Val Department, Val Source, Val Receiver)
	
	If ValueTypeWorkCenter(Source) Then
		Source = WorkCenterType(PlanningParameters, Source);
	EndIf;
	If ValueTypeWorkCenter(Receiver) Then
		Receiver = WorkCenterType(PlanningParameters, Receiver);
	EndIf;
	
	Result = FindInteroperableTransitionTime(PlanningParameters, Department, Source, Receiver);
	If Not ValueIsFilled(Result) Then
		Result = FindInteroperableTransitionTime(PlanningParameters, Department,, Receiver);
		If Not ValueIsFilled(Result) Then
			Result = FindInteroperableTransitionTime(PlanningParameters, Department, Source);
			If Not ValueIsFilled(Result) Then
				Result = FindInteroperableTransitionTime(PlanningParameters, Department);
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
		
EndFunction

Function WorkCentersOnMeasurementValue(Val PlanningParameters, Val Dimension)
	
	Result = New Array;
	
	If ValueTypeWorkCenter(Dimension) Then
		
		Result.Add(Dimension);
		
	ElsIf TypeOf(Dimension) = Type("CatalogRef.WorkCenterTypes")
		Or TypeOf(Dimension) = Type("CatalogRef.BusinessStructure") Then
		
		If TypeOf(Dimension) = Type("CatalogRef.WorkCenterTypes") Then
			SearchCondition = New Structure("WorkCenterType", Dimension);
		ElsIf TypeOf(Dimension) = Type("CatalogRef.BusinessStructure") Then
			SearchCondition = New Structure("Department", Dimension);
		EndIf;
		
		SearchBars = PlanningParameters.TableOfWorkCenters.FindRows(SearchCondition);
		For Each SearchString In SearchBars Do
			Result.Add(SearchString.WorkCenter);
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function BackgroundCalculationResults(PlanningParameters)
	
	Result = New Structure;
	Result.Insert("TimetableIssues", PlanningParameters.TimetableIssues);
	
	Return Result;
	
EndFunction

Procedure ReadResultsOfBackgroundCalculation(PlanningParameters, Results)
	
	For Each StorageAddress In Results Do
		
		If IsTempStorageURL(StorageAddress) Then
			
			Result = GetFromTempStorage(StorageAddress);
			
			If TypeOf(Result) = Type("Structure") 
				And Result.Property("TimetableIssues") Then
				
				ReadProblemsFromBackgroundCalculationResults(PlanningParameters, Result.TimetableIssues);
				
			EndIf;
			
		EndIf;
	EndDo;
	
EndProcedure

Function ParametersForPlacingOperationWithoutWorkCenter(PlanningParameters, Operation, WorkCenter, DirectPlacement)
	
	TimeOfPlacement = WhenOperationWasPlaced(PlanningParameters, Operation, DirectPlacement);
	OperationTime_ = Operation.TimeToPlace;
	
	Result = InitializePlacementParameters();
	If DirectPlacement Then
		Result.Begin = TimeOfPlacement;
		Result.Ending = TimeOfPlacement + OperationTime_;
	Else
		Result.Begin = TimeOfPlacement - OperationTime_;
		Result.Ending = TimeOfPlacement;
	EndIf;
	
	Interval = InitializePlacementInterval();
	FillPropertyValues(Interval, Result);
	Interval.TimePlan = OperationTime_;
	
	Result.Intervals.Add(Interval);
	
	Return Result;
	
EndFunction

Function ParametersOfParallelLoadingOfVRC(PlanningParameters, WorkCenter)
	
	Result = New Structure;
	Result.Insert("ParallelLoad", False);
	Result.Insert("SynchronousLoad", False);
	Result.Insert("MaximumLoad", 0);
	
	If TypeOf(WorkCenter) = Type("CatalogRef.WorkCenterTypes") Then
		FoundRow = PlanningParameters.TableOfWorkCenters.Find(WorkCenter, "WorkCenterType");
	Else
		FoundRow = PlanningParameters.TableOfWorkCenters.Find(WorkCenter, "WorkCenter");
	EndIf;
	
	If Not FoundRow = Undefined Then
		FillPropertyValues(Result, FoundRow);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	Table - See InitializeAvailableHardwareTime
// Returns:
// 	ValueTableRow - Where:
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * ParallelLoad - Boolean -
// * SynchronousLoad - Boolean -
// * WorkCenter - CatalogRef.WorkCenters -
// * Period - Date -
// * Begin - Date -
// * Ending - Date -
// * StartOfShift - Date -
// * Time - Number -
// * ShiftTime - Number -
// * MaximumLoad - Number -
// * AvailableDownload - Number -
// * SetupSettings - CatalogRef.SetupOptions -
// * PrecededByLoading - Boolean -
// * SetupSettingsPreceding - CatalogRef.SetupOptions -
// * DownloadFollows - Boolean -
// * SetupSettingsFollowing - CatalogRef.SetupOptions -
Function LastRowOfAvailableTimeTable(Table)
	
	If Table.Count() > 0 Then
		Return Table[Table.Count()-1];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function CollapseTable(Table)
	
	ColumnsByRow = "";
	For Each Column In Table.Columns Do
		If Not ColumnsByRow = "" Then
			ColumnsByRow = ColumnsByRow + ", ";
		EndIf;
		ColumnsByRow = ColumnsByRow + Column.Name;
	EndDo;			
	Table.GroupBy(ColumnsByRow);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
