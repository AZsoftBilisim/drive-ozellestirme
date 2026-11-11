#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates and records the queue of production operations
//  (called when processing the queue of tasks for calculating the queue of production operations).
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Tasks for accounting for production operations", there are also service columns:
//             * ObjectOfARAP       - DocumentRef.ProductionStage2_2 -
//             * RecordID    - UUID -
//             * NotUsedRegistrationDay - Number  -
//             * RecordDate             - Date   -
//             * JobID   - UUID - Service_
//             * TaskDate_            - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure CalculateQueueDeferred(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);
	
	ErrorFields = Undefined;
	
	Stages = CommonClientServer.CollapseArray(Jobs.UnloadColumn("ObjectOfARAP"));
	
	StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages);
	
	MetaOfRegister = Undefined;
	EventName   = Undefined;
	
	For Each Stage In Stages Do
		
		Data_Stage = StageData_1[Stage];
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			LockItem = DataLock.Add("Document.ProductionStage2_2");
			LockItem.SetValue("Ref", Stage);
			LockItem.Mode = DataLockMode.Shared;
			DataLock.Lock();
			
			CalculateQueueBasedOnStageData(Stage, Data_Stage, QueueCalculationParameters());
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			If MetaOfRegister = Undefined Then
				MetaOfRegister = Metadata.InformationRegisters.JobsForCalculatingProductionOperationQueue;
				EventName   = DeferredJobs.EventName();
			EndIf;
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName, EventLogLevel.Error, MetaOfRegister,, ExceptionText);
			
			If ErrorFields = Undefined Then
				
				Jobs.Indexes.Add("ObjectOfARAP");
				
				ErrorFields = New Structure;
				ErrorFields.Insert("ObjectOfARAP");
				
				DataOfError = New Structure;
				DataOfError.Insert("ObjectOfARAP");
				
			EndIf;
			
			DataOfError.ObjectOfARAP = Stage;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, ExceptionText);
			
			FoundRows = Jobs.FindRows(DataOfError);
			For Each TableRow In FoundRows Do
				IdsOfUnprocessedRecords.Insert(TableRow.RecordID, ErrorText);
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

// Calculates and records the queue of production operations.
//
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2 - document being processed
//  Data_Stage - Structure - stage data for calculating the queue of operations (must be read responsibly)
//  CalculationParameters - See QueueCalculationParameters
//
Procedure CalculateQueueBasedOnStageData(Stage, Data_Stage, CalculationParameters) Export
	
	If Not Data_Stage.RequiredToCalculate
			And Not Data_Stage.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		Return;
	EndIf;
	
	Queue = OperationQueue(Stage, Data_Stage);
	WriteQueue(Stage, Queue);
	
	If Data_Stage.UseShiftTasks
		And Not Data_Stage.InArchive
		And CalculationParameters.CalculateShiftTasks Then
		
		InformationRegisters.OperationsToCreateShiftTasks.CalculateOperations(Stage);
		
	EndIf;
	
EndProcedure

// Adds a new task to the task queue for calculating register data.
//
// Parameters:
//  Stage				 - DocumentRef.ProductionStage2_2	 - stage of production.
//  RemovalOfBody	 - Boolean								 - indicates whether the deletion is processed.
//  Cancel				 - Boolean								 - indicates that processing of the event has been interrupted.
//
Procedure AddTaskToQueueCalculation(Stage, RemovalOfBody = False, Cancel = False) Export
	
	BlockDataForQueueCalculation(Stage, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	Data_Stage = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stage)[Stage];
	
	PerformControlBeforeCalculatingQueue(Data_Stage, RemovalOfBody, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	If Data_Stage.UseShiftTasks Then
		InformationRegisters.OperationsToCreateShiftTasks.DeleteUnassignedOperationsOfOperations(Stage);
	EndIf;
	
	If Data_Stage.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		Calculate = True;
	Else
		ClearQueue(Stage);
		Calculate = Data_Stage.RequiredToCalculate And Not RemovalOfBody;
	EndIf;
	
	If Calculate Then
		InformationRegisters.JobsForCalculatingProductionOperationQueue.AddTasks(Stage);
	EndIf;
	
EndProcedure

// Recalculates the queue for the specified process operation.
//
// Parameters:
//  OperationKey - See ProductionManagementClientServer.ProductionOperationKey
//  CalculationParameters - See QueueCalculationParameters
//  Cancel - Boolean - indicates that processing of the event has been interrupted.
//
Procedure RecalculateQueue(OperationKey, CalculationParameters, Cancel = False) Export
	
	BlockQueueForWritingByKey(OperationKey, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	Operations = EnvironmentOfQueuedOperation(OperationKey, CalculationParameters);
	
	OperationData = FindOperationByKey(Operations, OperationKey);
	If OperationData = Undefined Then
		ReportQueueCalculationErrorToUser(Cancel);
		Return;
	EndIf;
	
	Stage = OperationKey.Stage;
	
	BlockDataForCalculatingQueueForOperation(Stage, OperationData, CalculationParameters, Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	RecalculateQueueByOperation(Stage, OperationData, CalculationParameters, Cancel);
	
EndProcedure

// Parameters for recalculating the queue for the specified technological Operation.
// 
// Returns:
//  Structure - Queue recalculation parameters:
// * CalculateAllSubsequentOperations - Boolean - indicates the need to recalculate all of operations after the specified
// * CalculateShiftTasks - Boolean - indicates whether the data in the "operations to create shift tasks" register should be calculated"
Function QueueCalculationParameters() Export
	
	Result = New Structure;
	
	Result.Insert("CalculateAllSubsequentOperations", False);
	Result.Insert("CalculateShiftTasks", True);
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Constructors

// Production queue Constructor of operations
// 
// Returns:
//  InformationRegisterRecordSet.QueueOfProductionOperations
Function OperationQueueConstructor() Export
	
	RecordSet = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
	
	Return RecordSet.UnloadColumns();
	
EndFunction

Function ProgressIndicatorsConstructor()
	
	Result = New Structure;
	
	Result.Insert("BeingGenerated",            0);
	Result.Insert("CreatedOn",                0);
	Result.Insert("Running",            0);
	Result.Insert("Completed2",              0);
	Result.Insert("RepetitionIsRequired",      0);
	Result.Insert("Skipped3",              0);
	Result.Insert("UnderControl",             0);
	Result.Insert("UnderRevision",            0);
	Result.Insert("DefectiveGoods",                   0);
	Result.Insert("Canceled",               0);
	Result.Insert("CancelledInd",            0);
	Result.Insert("TimeOfOperationsCreated", 0);
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculateByStage_

// Blocking data for queue calculation.
// 
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2
// 
// Returns:
//  DataLock - Blocking Data For Queue Calculation
Function BlockingDataForQueueCalculation(Stage) Export
	
	DataLock = New DataLock;
	
	LockItem = DataLock.Add("InformationRegister.QueueOfProductionOperations");
	LockItem.SetValue("Stage", Stage);
	LockItem.Mode = DataLockMode.Exclusive;
	
	If GetFunctionalOption("UseManufacturingExecutionSystem") Then
		LockItem = DataLock.Add("InformationRegister.PostOperativeSchedule2_2");
		LockItem.SetValue("Stage", Stage);
		LockItem.Mode = DataLockMode.Exclusive;
	EndIf;
	
	If GetFunctionalOption("UseShiftTasks") Then
		LockItem = DataLock.Add("InformationRegister.OperationsToCreateShiftTasks");
		LockItem.SetValue("ShiftTask", Documents.ShiftTask.EmptyRef());
		LockItem.SetValue("Stage", Stage);
		LockItem.Mode = DataLockMode.Exclusive;
	EndIf;
	
	Return DataLock;
	
EndFunction

Procedure BlockDataForQueueCalculation(Stage, Cancel)
	
	DataLock = BlockingDataForQueueCalculation(Stage);
	
	Try
		DataLock.Lock();
	Except
		MessageText = StrTemplate(NStr("vi = 'Không thể phong tỏa hàng đợi các giao dịch sản xuất: %1';
										|ru = 'Не удалось заблокировать очередь производственных операций: %1';
										|en = 'Cannot lock the queue of routing operations: %1'; fa = 'Cannot lock the queue of routing operations: %1';
										|it = 'Не удалось заблокировать очередь производственных операций: %1';
										|pl = 'Cannot lock the queue of routing operations: %1';
										|tr = 'Rota işlemleri kuyruğu engellenemedi: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(MessageText,,,,Cancel);
	EndTry;
	
EndProcedure

Function OperationQueue(Stage, Data_Stage)
	
	KeyOperation = "IntershopManagement2_2.CalculationOfQueueOfProductionOperations";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	
	OperationQueue = QueueOfOperationsInsideTimeMeasurement(Stage, Data_Stage);
	
	MeasurementStartTime = MeasurementDetails.Get("BeginTime");
	If MeasurementStartTime <> Undefined
		And CurrentUniversalDateInMilliseconds() - MeasurementStartTime > 0 Then
		DataVolume = OperationQueue.Count();
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	EndIf;
	
	Return OperationQueue;
	
EndFunction

Function QueueOfOperationsInsideTimeMeasurement(Stage, Data_Stage)
	
	OperationQueue = OperationQueueConstructor();
	
	TransactionList = ListOfOperationsAccordingToStageData(Data_Stage, True);
	AddExecutionResultsToOperations(Stage, TransactionList);
	AddFillInServiceAttributesOfOperations(TransactionList);
	
	For IndexOf = 0 To TransactionList.Count() - 1 Do
		
		OperationData = TransactionList[IndexOf];
		
		NewOperation = OperationQueue.Add();
		NewOperation.Stage      = Stage;
		NewOperation.Required2 = OperationData.QuantityPerBatch;
		
		FillPropertyValues(
			NewOperation,
			OperationData,
			"Operation,
			|OperationID,
			|ControlOperationID,
			|OperationNumber,
			|NextOperation,
			|WorkCenter,
			|ProductionOperation
			|");
		
		FillPropertyValues(
			NewOperation,
			Data_Stage,
			"ReferenceOrder,
			|Department,
			|InArchive");
			
		FillInAttributesOfTechnologicalProcess(NewOperation, OperationData, Data_Stage);
		
		CalculateOperationPerformanceIndicators(NewOperation, OperationData);
		
		ExpandResultOfOperation(OperationQueue, NewOperation, OperationData, Data_Stage.UseShiftTasks);
		
	EndDo;
	
	Return OperationQueue;
	
EndFunction

// List of operations according to stage data.
// 
// Parameters:
//  Data_Stage - See Documents.ProductionStage2_2.DataForCalculatingOperationQueue
//  ApplyProcessLimitations - Boolean - determines whether the route needs to be shortened by the batch division settings
// 
// Returns:
//  See Catalogs.ManufacturingOperations.OperationTableConstructor 
Function ListOfOperationsAccordingToStageData(Data_Stage, ApplyProcessLimitations = False) Export
	
	LaborCosts = New ValueTable();
	
	RationingAndPricingOfWorksOnTariffGrids = False;
	
	ListOfData = "Operations";
	
	ListOfData = ListOfData + ?(RationingAndPricingOfWorksOnTariffGrids, ",LaborCosts", "");
	
	If Data_Stage.Property("Operations") Then
		
		Operations = Data_Stage.Operations; //ValueTable
	
	ElsIf TypeOf(Data_Stage.TechnologicalProcess) = Type("CatalogRef.BillsOfMaterials") Then
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		ItemData_3.Products   = Data_Stage.Products;
		ItemData_3.Characteristic = Data_Stage.Characteristic;
		ItemData_3.BillOfMaterials   = Data_Stage.TechnologicalProcess;
		ItemData_3.Count     = Data_Stage.NumberOfPackagesPlan * Data_Stage.PackagingFactor;
		
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
		SelectionParameters.OverridingReleasePartySetting.Use = True;
		SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
		
		SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
			ItemData_3,
			SelectionParameters,
			New Structure("Stage", Data_Stage.BOMStage));
		
		Operations = SpecificationData.Operations; // ValueTable
		
		If RationingAndPricingOfWorksOnTariffGrids Then
			LaborCosts = SpecificationData.LaborCosts;
		EndIf;
		
	ElsIf TypeOf(Data_Stage.TechnologicalProcess) = Type("CatalogRef.TechnologicalProcesses") Then
		
		ItemData_3 = Catalogs.TechnologicalProcesses.ItemData_3();
		ItemData_3.Products   = Data_Stage.Products;
		ItemData_3.Characteristic = Data_Stage.Characteristic;
		ItemData_3.Count = Data_Stage.NumberOfPackagesPlan * Data_Stage.PackagingFactor;
		
		SelectionParameters = Catalogs.TechnologicalProcesses.DataSamplingParameters(ListOfData);
		
		TechProcessData = Catalogs.TechnologicalProcesses.ProcessDataByNomenclature(
			Data_Stage.TechnologicalProcess,
			Data_Stage.TechnologicalProcessFactor,
			ItemData_3,
			SelectionParameters);
			
		Operations = TechProcessData.Operations; // ValueTable
		
		If RationingAndPricingOfWorksOnTariffGrids Then
			LaborCosts = TechProcessData.LaborCosts;
		EndIf;
		
	ElsIf TypeOf(Data_Stage.TechnologicalProcess) = Type("CatalogRef.RouteSheets") Then
	
		RouteMapData = Catalogs.RouteSheets.RouteMapData(
			Data_Stage.TechnologicalProcess,
			Data_Stage.TechnologicalProcessFactor,
			Undefined,
			Undefined,
			ListOfData);
			
		Operations = RouteMapData.Operations; // ValueTable
		
		If RationingAndPricingOfWorksOnTariffGrids Then
			LaborCosts = RouteMapData.LaborCosts;
		EndIf;
		
	Else
		
		Operations = Catalogs.ManufacturingOperations.OperationTableConstructor();
		
	EndIf;
	
	If ApplyProcessLimitations Then
		
		ApplyProcessLimitations(Operations, Data_Stage);
		
	EndIf;
	
	
	Return Operations;
	
EndFunction

Procedure WriteQueue(Stage, Queue)
	
	SetPrivilegedMode(True);
	
	Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
	Set.Filter.Stage.Set(Stage);
	
	Set.Load(Queue);
	
	Set.Write(True);

EndProcedure

Procedure ClearQueue(Stage)

	SetPrivilegedMode(True);
	
	Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
	Set.Filter.Stage.Set(Stage);
	
	Set.Write(True);
	
EndProcedure

// Apply process restrictions.
// 
// Parameters:
//  Operations - See Catalogs.ManufacturingOperations.OperationTableConstructor
//  ProcessLimitations - See InformationRegisters.TechnologicalProcessesOfProductionStages.LimitationsOfConstructorProcess
Procedure ApplyProcessLimitations(Operations, ProcessLimitations) Export
	
	// Route abbreviation on the left
	If ProcessLimitations.FirstOperationID <> 0 Then
		Operation = Operations.Find(ProcessLimitations.FirstOperationID, "OperationID");
		If Operation <> Undefined Then
			Operations.Indexes.Add("NextOperation");
			TheStructureOfTheSearch = New Structure("NextOperation", Operation.OperationNumber);
			Queue = Operations.FindRows(TheStructureOfTheSearch);
			While Queue.UBound() <> -1 Do
				TheStructureOfTheSearch.NextOperation = Queue[0].OperationNumber;
				For Each String In Operations.FindRows(TheStructureOfTheSearch) Do
					Queue.Add(String);
				EndDo;
				Operations.Delete(Queue[0]);
				Queue.Delete(0);
			EndDo;
		EndIf;
	EndIf;
	
	// Route shortcut on the right
	If ProcessLimitations.LastOperationID <> 0 Then
		Operation = Operations.Find(ProcessLimitations.LastOperationID, "OperationID");
		If Operation <> Undefined Then
			Operations.Indexes.Add("OperationNumber");
			TheStructureOfTheSearch = New Structure("OperationNumber", Operation.NextOperation);
			Queue = Operations.FindRows(TheStructureOfTheSearch);
			While Queue.UBound() <> -1 Do
				TheStructureOfTheSearch.OperationNumber = Queue[0].NextOperation;
				For Each String In Operations.FindRows(TheStructureOfTheSearch) Do
					Queue.Add(String);
				EndDo;
				Operations.Delete(Queue[0]);
				Queue.Delete(0);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region CalculateByOperation

Procedure BlockQueueForWritingByKey(OperationKey, Cancel = False) Export
	
	DataLock = New DataLock;
	
	LockItem = DataLock.Add("InformationRegister.QueueOfProductionOperations");
	LockItem.Mode = DataLockMode.Exclusive;
	
	LockItem.SetValue("Stage", OperationKey.Stage);
	LockItem.SetValue("Operation", OperationKey.Operation);
	LockItem.SetValue("OperationID", OperationKey.OperationID);

	Try
		DataLock.Lock();
	Except
		
		MessageText = StrTemplate(NStr("vi = 'Không thể phong tỏa hàng đợi các giao dịch sản xuất: %1';
										|ru = 'Не удалось заблокировать очередь производственных операций: %1';
										|en = 'Cannot lock the queue of routing operations: %1'; fa = 'Cannot lock the queue of routing operations: %1';
										|it = 'Не удалось заблокировать очередь производственных операций: %1';
										|pl = 'Cannot lock the queue of routing operations: %1';
										|tr = 'Rota işlemleri kuyruğu engellenemedi: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndTry;
	
EndProcedure

Procedure BlockDataForCalculatingQueueForOperation(Stage, OperationData, CalculationParameters, Cancel)
	
	DataLock = New DataLock;
	
	For Each CurrentRow In OperationData.Owner() Do
		
		LockItem = DataLock.Add("Document.ProductionOperation2_2");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem.SetValue("Stage", Stage);
		
		LockItem.SetValue("Operation", CurrentRow.Operation);
		LockItem.SetValue("OperationID", CurrentRow.OperationID);
		
		If CurrentRow.OperationNumber = OperationData.NextOperation
			Or (CalculationParameters.CalculateAllSubsequentOperations
					And CurrentRow.OperationNumber >= OperationData.NextOperation)
			Or CurrentRow = OperationData Then
		
			LockItem = DataLock.Add("InformationRegister.QueueOfProductionOperations");
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem.SetValue("Stage", Stage);
			
			LockItem.SetValue("Operation", CurrentRow.Operation);
			LockItem.SetValue("OperationID", CurrentRow.OperationID);
			
		EndIf;
		
	EndDo;
	
	Try
		DataLock.Lock();
	Except
		
		MessageText = StrTemplate(NStr("vi = 'Không thể phong tỏa hàng đợi các giao dịch sản xuất: %1';
										|ru = 'Не удалось заблокировать очередь производственных операций: %1';
										|en = 'Cannot lock the queue of routing operations: %1'; fa = 'Cannot lock the queue of routing operations: %1';
										|it = 'Не удалось заблокировать очередь производственных операций: %1';
										|pl = 'Cannot lock the queue of routing operations: %1';
										|tr = 'Rota işlemleri kuyruğu engellenemedi: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(MessageText,,,, Cancel);
			
	EndTry;
	
EndProcedure

Procedure RecalculateQueueByOperation(Stage, OperationData, CalculationParameters, Cancel)
	
	AddExecutionResultsToOperations(Stage, OperationData.Owner());
	
	Operations = FollowingOperations(OperationData, CalculationParameters.CalculateAllSubsequentOperations);
	Operations.Insert(0, OperationData);
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(OperationData.Department);
	
	Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
	
	For IndexOf = 0 To Operations.UBound() Do
		
		CurrentRow = Operations[IndexOf];
		
		Set.Clear();
		Set.Filter.Stage.Set(Stage);
		Set.Filter.Operation.Set(CurrentRow.Operation);
		Set.Filter.OperationID.Set(CurrentRow.OperationID);
		
		NewRecord = Set.Add();
		FillPropertyValues(NewRecord, CurrentRow);
		
		CalculateOperationPerformanceIndicators(NewRecord, CurrentRow);
		
		ExpandResultOfOperation(Set, NewRecord, CurrentRow, DivisionParameters.UseShiftTasks);
		
		Try
			Set.Write(True);
		Except
			ReportQueueCalculationErrorToUser(Cancel);
			Return;
		EndTry;
		
	EndDo;
	
	If DivisionParameters.UseShiftTasks
			And CalculationParameters.CalculateShiftTasks Then
		InformationRegisters.OperationsToCreateShiftTasks.CalculateOperations(Stage);
	EndIf;
	
EndProcedure

#Region Sequence

Function EnvironmentOfQueuedOperation(OperationKey, CalculationParameters)
	
	AdditionalFields = New Array;
	AdditionalFields.Add("MAX(Queue.Required2)  AS Required2");
	AdditionalFields.Add("SUM(Queue.Scheduled - Queue.RepetitionIsRequired) AS QuantityPerBatch");
	
	RequestTextParameters = RequestTextParametersQueueOfOperations();
	RequestTextParameters.NormativeIndicators = False;
	RequestTextParameters.AttributesOfContractorOfOperation = True;
	RequestTextParameters.AttributesForCalculatingTimeOfOperation = True;
	RequestTextParameters.SelectionFields1 = AdditionalFields;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage = &Stage");
	
	QueryText = QueryTextOperationQueue(RequestTextParameters) + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.*
	|FROM
	|	TTQueue AS Operations
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			TTQueue AS CurrentOperation
	|				FULL JOIN TTQueue AS FollowingOperations
	|				ON FollowingOperations.OperationNumber = CurrentOperation.NextOperation
	|					OR &AllSubsequentOperations
	|						AND (FollowingOperations.OperationNumber >= CurrentOperation.NextOperation
	|							AND CurrentOperation.NextOperation <> 0)
	|				FULL JOIN TTQueue AS PreviousOperations_
	|				ON PreviousOperations_.NextOperation = CurrentOperation.OperationNumber
	|					OR PreviousOperations_.NextOperation = FollowingOperations.OperationNumber
	|		WHERE
	|			CurrentOperation.OperationID = &OperationID
	|			AND Operations.OperationID IN (
	|				CurrentOperation.OperationID,
	|					FollowingOperations.OperationID,
	|						PreviousOperations_.OperationID))
	|ORDER BY
	|	Operations.OperationNumber,
	|	Operations.Description
	|";
	
	Query = New Query;
	Query.Text = QueryText;
		
	Query.SetParameter("Stage", OperationKey.Stage);
	Query.SetParameter("OperationID", OperationKey.OperationID);
	Query.SetParameter("AllSubsequentOperations", CalculationParameters.CalculateAllSubsequentOperations);
	
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("OperationNumber");
	Result.Indexes.Add("NextOperation");
	Result.Indexes.Add("Operation,OperationID");
	
	Return Result;
	
EndFunction

Function PreviousOperations_(Cursor, All = False)
	
	Operations = Cursor.Owner();
	
	If All Then
		Result = New Array;
		For IndexOf = 0 To Operations.Count()-1 Do
			Operation = Operations[IndexOf];
			If Operation.NextOperation <= Cursor.OperationNumber Then
				Result.Add(Operation);
			EndIf;
		EndDo;
	Else
		Result = Operations.FindRows(New Structure("NextOperation", Cursor.OperationNumber));
	EndIf;
	
	Return Result;
	
EndFunction

Function FollowingOperations(Cursor, All = False)
	
	Operations = Cursor.Owner();
	
	If All Then
		Result = New Array;
		For IndexOf = 0 To Operations.Count()-1 Do
			Operation = Operations[IndexOf];
			If Operation.OperationNumber >= Cursor.NextOperation
					And Cursor.NextOperation <> 0 Then
				Result.Add(Operation);
			EndIf;
		EndDo;
	Else
		Result = Operations.FindRows(New Structure("OperationNumber", Cursor.NextOperation));
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CollapseGroupsOfIndividualOperations(Operations, RowsArray)
	
	If RowsArray.Count() <= 1 Then
		Return;
	EndIf;
	
	Result = New Array;
	
	GroupsTable = Operations.CopyColumns();
	TheStructureOfTheSearch = New Structure("OperationNumber,NextOperation");
	
	For IndexOf = 0 To RowsArray.Count()-1 Do
		
		OperationData = RowsArray[IndexOf];
		
		If ProductionProcessEditorClientServer.ThisOperationIsIndividual(OperationData) Then
			FillPropertyValues(TheStructureOfTheSearch, OperationData);
			FoundRows = GroupsTable.FindRows(TheStructureOfTheSearch);
			If Not ValueIsFilled(FoundRows) Then
				DataOfGroup = GroupsTable.Add();
				FillPropertyValues(DataOfGroup, OperationData);
			Else
				DataOfGroup = FoundRows[0];
				DataOfGroup.Required2 = DataOfGroup.Required2 + OperationData.Required2;
				DataOfGroup.QuantityPerBatch = DataOfGroup.QuantityPerBatch + OperationData.QuantityPerBatch;
				CommonClientServer.SupplementArray(DataOfGroup.Result, OperationData.Result);
				For Each KeyAndValue In DataOfGroup.ResultResults Do
					DataOfGroup.ResultResults[KeyAndValue.Key] =
						DataOfGroup.ResultResults[KeyAndValue.Key] + OperationData.ResultResults[KeyAndValue.Key];
				EndDo;
			EndIf;
		Else
			Result.Add(OperationData);
		EndIf;
		
	EndDo;
	
	If GroupsTable.Count() > 0 Then
		
		For Each DataOfGroup In GroupsTable Do
			Result.Add(DataOfGroup);
		EndDo;
		
	EndIf;
	
	RowsArray = Result;
	
EndProcedure

Function FindOperationByKey(Operations, OperationKey)
	
	FilterOperation = New Structure("Operation,OperationID");
	FillPropertyValues(FilterOperation, OperationKey);
	
	FoundRows = Operations.FindRows(FilterOperation);
	If FoundRows.UBound() <> -1 Then
		Return FoundRows[0];
	EndIf;
	Return Undefined;

EndFunction

// Adds and fills in the service details for the list of operations.
// 
// Parameters:
//  Operations  - ValueTable - list of operations
Procedure AddFillInServiceAttributesOfOperations(Operations) Export
	
	FillInIdOfControlOfOperation = False;
	IsRequiredToFillIn = False;
	
	If Operations.Columns.Find("ControlOperationID") = Undefined Then
		TypeDescription = New TypeDescription("Number",
			New NumberQualifiers(20, 0, AllowedSign.Nonnegative));
		Operations.Columns.Add("ControlOperationID", TypeDescription);
		FillInIdOfControlOfOperation = True;
	EndIf;
	
	If Operations.Columns.Find("Required2") = Undefined Then
		TypeDescription = New TypeDescription("Number",
			New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
		Operations.Columns.Add("Required2", TypeDescription);
		IsRequiredToFillIn = True;
	EndIf;
	
	If FillInIdOfControlOfOperation Or IsRequiredToFillIn Then
		For Index1 = 0 To Operations.Count() - 1 Do
			LineOperation = Operations[Index1];
			If IsRequiredToFillIn Then
				LineOperation.Required2 = LineOperation.QuantityPerBatch;
			EndIf;
			If FillInIdOfControlOfOperation Then
				If LineOperation.Control = Enums.ManufacturingOperationControlOptions.NotRequired Then
					Continue;
				ElsIf LineOperation.Control = Enums.ManufacturingOperationControlOptions.Required2 Then
					LineOperation.ControlOperationID = LineOperation.OperationID;
				ElsIf LineOperation.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations Then
					For IndexOf2 = Index1+1 To Operations.Count()-1 Do
						LineControlOperation = Operations[IndexOf2];
						If LineControlOperation.Control = Enums.ManufacturingOperationControlOptions.Required2 Then
							LineOperation.ControlOperationID = LineControlOperation.OperationID;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region QueryTextOperationQueue

// Parameters of the Query Text of operations queue.
// 
// Returns:
//  Structure - From:
// * Filters - Array of String - Filters
// * SelectionFields1 - Array of String
// * SortFields - Array of String
// * IndexingFields - Array of String
// * NormativeIndicators - Boolean - add regulatory indicators of operations to the request
// * ExecutionIndicators - Boolean - add accumulated progress indicators to the request
// * AttributesOfContractorOfOperation - Boolean - the need to obtain data on the VRC / RC
// * AttributesForCalculatingTimeOfOperation - Boolean - the need to calculate time indicators for NSI
// * AttributesOfTimeOfOperation - Boolean - the need to add temporary indicators from the queue to the selection
// * ExtendedAttributesOfOperations - Boolean - extended set of technical Attributes. OF operations
// * ProductionOperations - Number - (0 - none, 1 - only individual, 2 - all)
// * OutputTableName - String - name of the temporary table
Function RequestTextParametersQueueOfOperations() Export
	
	Result = New Structure;
	
	Result.Insert("NormativeIndicators",                     True);
	Result.Insert("ExecutionIndicators",                      False);
	Result.Insert("ProductionOperations",                  1);
	
	Result.Insert("AttributesOfContractorOfOperation",              False);
	Result.Insert("AttributesForCalculatingTimeOfOperation", False);
	Result.Insert("AttributesOfTimeOfOperation",        False);
	Result.Insert("ExtendedAttributesOfOperations",              False);
	
	Result.Insert("Filters",             New Array);
	Result.Insert("SelectionFields1",        New Array);
	Result.Insert("SortFields",     New Array);
	Result.Insert("IndexingFields", New Array);
	
	Result.Insert("PacketSeparator",  False);
	Result.Insert("OutputTableName", "");
	
	Return Result;
	
EndFunction

// Query Text queue of operations.
// 
// Parameters:
//  QueryOptions - See RequestTextParametersQueueOfOperations
// 
// Returns:
//  String - Query text
Function QueryTextOperationQueue(QueryOptions) Export
	
	QueryText = "
	|SELECT
	|	Queue.Department                       AS Department,
	|	Queue.ReferenceOrder                        AS ReferenceOrder,
	|	Queue.Stage                                AS Stage,
	|	Queue.Operation                            AS Operation,
	|	Queue.OperationID               AS OperationID,
	|	Queue.ControlOperationID    AS ControlOperationID,
	|	Queue.OperationNumber                       AS OperationNumber,
	|	Queue.NextOperation              AS NextOperation,
	|	Queue.TechnologicalProcess              AS TechnologicalProcess,
	|	Queue.TechnologicalProcessFactor AS TechnologicalProcessFactor,
	|	Queue.InArchive                             AS InArchive,
	|	ISNULL(Queue.Operation.Count, 1)    AS Count,
	|	&TextAdditionalSelectionFields
	|FROM
	|	InformationRegister.QueueOfProductionOperations AS Queue
	|";
	
	TextOfAdditionalFields = New Array;
	
	If QueryOptions.ProductionOperations = 1 Then
		TextOfAdditionalFields.Add("CASE
		|	WHEN Queue.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|		THEN Queue.ProductionOperation
		|	ELSE VALUE(Document.ProductionOperation2_2.EmptyRef)
		|END AS ProductionOperation");
	ElsIf QueryOptions.ProductionOperations = 2 Then
		TextOfAdditionalFields.Add("Queue.ProductionOperation AS ProductionOperation");
	EndIf;
	
	If QueryOptions.AttributesOfContractorOfOperation Then
		TextOfAdditionalFields.Add(Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation(
			QueryTextDataSourceOfOperation()));
	EndIf;
	
	If QueryOptions.AttributesForCalculatingTimeOfOperation Then
		TextOfAdditionalFields.Add(Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation(
			QueryTextDataSourceOfOperation()));
	EndIf;
	
	TransactionDetails = New Array;
	TransactionDetails.Add("Description");
	If QueryOptions.ExtendedAttributesOfOperations Then
		TransactionDetails.Add("CLASSIFIEROFTECHNOLOGICALOPERATIONS");
		TransactionDetails.Add("OperationKind");
		TransactionDetails.Add("ProductionArea");
		TransactionDetails.Add("SetupSettings");
		TransactionDetails.Add("Control");
		TransactionDetails.Add("Repeatable");
		TransactionDetails.Add("Skippable");
		TransactionDetails.Add("Load");
		TransactionDetails.Add("TransferLot");
		TransactionDetails.Add("Continuous");
		TransactionDetails.Add("UnitOfMeasure");
	EndIf;
	For Each Attribute In TransactionDetails Do
		TextOfAdditionalFields.Add(StrTemplate("%1.%2 AS %2", QueryTextDataSourceOfOperation(), Attribute));
	EndDo;
	
	QueryText = StrReplace(QueryText, "&TextAdditionalSelectionFields", StrConcat(TextOfAdditionalFields, ","+Chars.LF));
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	Package = QuerySchema.QueryBatch[0];
	
	For Each FilterElement In QueryOptions.Filters Do
		Package.Operators[0].Filter.Add(FilterElement);
	EndDo;
	
	If QueryOptions.NormativeIndicators Then
		TextIndicatorsOfStandard = "
		|	MAX(Queue.Required2)  AS Required2,
		|	MAX(Queue.Required2)  AS QuantityPerBatch
		|";
		AddFieldsToRequestPackage(Package, TextIndicatorsOfStandard);
	EndIf;
	
	If QueryOptions.ExecutionIndicators Then
		TextPerformanceIndicators = "
		|	SUM(Queue.Scheduled)          AS Scheduled,
		|	SUM(Queue.CreatedOn)                AS CreatedOn,
		|	SUM(Queue.Running)            AS Running,
		|	SUM(Queue.Completed2)              AS Completed2,
		|	SUM(Queue.RepetitionIsRequired)      AS RepetitionIsRequired,
		|	SUM(Queue.Skipped3)              AS Skipped3,
		|	SUM(Queue.UnderControl)             AS UnderControl,
		|	SUM(Queue.UnderRevision)            AS UnderRevision,
		|	SUM(Queue.DefectiveGoods)                   AS DefectiveGoods,
		|	SUM(Queue.PendingPredecessorCompletion) AS PendingPredecessorCompletion,
		|	SUM(Queue.PreviousOnesStarted)   AS PreviousOnesStarted,
		|	SUM(Queue.ExecutionIsAllowed)         AS ExecutionIsAllowed
		|";
		AddFieldsToRequestPackage(Package, TextPerformanceIndicators);
	EndIf;
	
	If QueryOptions.AttributesOfTimeOfOperation
		And Not QueryOptions.AttributesForCalculatingTimeOfOperation Then
		AttributesOfExecutionTime = "
		|	SUM(Queue.TimeTotal) AS TimeTotal,
		|	Queue.TimePerPiece      AS TimePerPiece,
		|	Queue.SetupTime           AS SetupTime,
		|	Queue.TimeUnitsOfMeasure        AS TimeUnitsOfMeasure
		|";
		AddFieldsToRequestPackage(Package, AttributesOfExecutionTime);
	EndIf;
	
	For Each Field In QueryOptions.SelectionFields1 Do
		AddFieldsToRequestPackage(Package, Field);
	EndDo;
	
	For Each Field In QueryOptions.SortFields Do
		Package.Order.Add(Field);
	EndDo;
	
	If ValueIsFilled(QueryOptions.OutputTableName) Then
		Package.PlacementTable = QueryOptions.OutputTableName;
		For Each Field In QueryOptions.IndexingFields Do
			Package.Index.Add(Field);
		EndDo;
	EndIf;
	
	QueryText = QuerySchema.GetQueryText();
	If QueryOptions.PacketSeparator Then
		QueryText = QueryText + Common.QueryBatchSeparator();
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure AddFieldsToRequestPackage(Package, Field)
	
	If ProductDataManagement.IsExpression(Field) Then
		FieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Field, ","+Chars.LF);
		For Each NestedField In FieldArray Do
			PositionOfAliasDefinition = StrFind(NestedField, " AS", SearchDirection.FromEnd);
			If PositionOfAliasDefinition > 0 Then
				ExpressionText  = Mid(NestedField, 1, PositionOfAliasDefinition);
				AliasText = Mid(NestedField, PositionOfAliasDefinition+4);
				AddFieldToRequestPackage(Package, TrimAll(ExpressionText), TrimAll(AliasText));
			ElsIf Not ProductDataManagement.IsExpression(NestedField) Then
				AddFieldToRequestPackage(Package, NestedField, NestedField);
			Else
				AddFieldToRequestPackage(Package, NestedField);
			EndIf;
		EndDo;
	Else
		AddFieldToRequestPackage(Package, Field, Field);
	EndIf;
	
EndProcedure

Procedure AddFieldToRequestPackage(Package, Expression, Alias = "")
	
	Package.Operators[0].SelectedFields.Add(Expression);
	If Not IsBlankString(Alias) Then
		Package.Columns[Package.Columns.Count()-1].Alias = Alias;
	EndIf;
	
EndProcedure

// Query Text data source of operation.
// 
// Parameters:
//  TableName - String - table name
// 
// Returns:
//  String
Function QueryTextDataSourceOfOperation(TableName = "") Export
	
	Result = "(CASE
	|	WHEN Queue.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|		THEN Queue.ProductionOperation
	|	ELSE Queue.Operation END)";
	
	If Not IsBlankString(TableName) Then
		Result = StrReplace(Result, "Queue", TableName);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region IndicatorsCalculation

Procedure AddExecutionResultsToOperations(Stage, Operations)
	
	FilterStructure1 = New Structure("OperationID");
	
	ResultOfOperations = ResultOfOperations(Stage, Operations.UnloadColumn("OperationID"));
	ResultOfOperations.Indexes.Add("OperationID");
	
	Operations.Columns.Add("Result");
	Operations.Columns.Add("ResultResults");
	
	For Each OperationData In Operations Do
		
		FilterStructure1.OperationID = OperationData.OperationID;
		
		Result      = ResultOfOperations.FindRows(FilterStructure1);
		ResultResults = ProgressIndicatorsConstructor();
		
		For Each FoundRow In Result Do
			For Each KeyAndValue In ResultResults Do
				ResultResults[KeyAndValue.Key] = ResultResults[KeyAndValue.Key] + FoundRow[KeyAndValue.Key];
			EndDo;
		EndDo;
		
		OperationData.Result      = Result;
		OperationData.ResultResults = ResultResults;

	EndDo;
	
EndProcedure

Function ResultOfOperations(Stage, OperationIds)
	
	QueryText =
		"SELECT
		|	NestedQuery.OperationID              AS OperationID,
		|	NestedQuery.ProductionOperation           AS ProductionOperation,
		|	NestedQuery.RoutesOperationStatus     AS RoutesOperationStatus,
		|	NestedQuery.ShiftTask                     AS ShiftTask,
		|	NestedQuery.WorkCenter                       AS WorkCenter,
		|	NestedQuery.Performer                        AS Performer,
		|	NestedQuery.IsDocument                        AS IsDocument,
		|	SUM(NestedQuery.CreatedOn)                     AS CreatedOn,
		|	SUM(NestedQuery.Running)                 AS Running,
		|	SUM(NestedQuery.Completed2)                   AS Completed2,
		|	SUM(NestedQuery.RepetitionIsRequired)           AS RepetitionIsRequired,
		|	SUM(NestedQuery.Skipped3)                   AS Skipped3,
		|	SUM(NestedQuery.UnderControl)                  AS UnderControl,
		|	SUM(NestedQuery.UnderRevision)                 AS UnderRevision,
		|	SUM(NestedQuery.DefectiveGoods)                        AS DefectiveGoods,
		|	SUM(NestedQuery.BeingGenerated)                 AS BeingGenerated,
		|	SUM(NestedQuery.Canceled)                    AS Canceled,
		|	SUM(NestedQuery.CancelledInd)                 AS CancelledInd,
		|	SUM(NestedQuery.TimeOfOperationsCreated)      AS TimeOfOperationsCreated
		|FROM
		|	(
		|	SELECT
		|		ProductionOperation.OperationID AS OperationID,
		|		ProductionOperation.Ref                AS ProductionOperation,
		|		ProductionOperation.Status                AS RoutesOperationStatus,
		|		ProductionOperation.ShiftTask        AS ShiftTask,
		|		ProductionOperation.WorkCenter          AS WorkCenter,
		|		ProductionOperation.Performer           AS Performer,
		|		TRUE                                         AS IsDocument,
		|		CASE
		|			WHEN ProductionOperation.Status = &StatusIsGenerated
		|				THEN ProductionOperation.Count
		|						- ProductionOperation.CountCanceled
		|			ELSE 0
		|		END AS BeingGenerated,
		|		CASE
		|			WHEN ProductionOperation.Status IN (&CreatedStatus, &RunningStatus, &StatusSkipped)
		|				THEN ProductionOperation.Count
		|						- ProductionOperation.CountCanceled
		|			WHEN ProductionOperation.Status = &StatusCompleted
		|				THEN ProductionOperation.CountReal
		|						+ ProductionOperation.FollowUp
		|						+ ProductionOperation.QuantityUnderRevision
		|						+ ProductionOperation.DefectiveGoodsCount
		|			ELSE 0
		|		END AS CreatedOn,
		|		CASE
		|			WHEN ProductionOperation.Status = &RunningStatus
		|				THEN ProductionOperation.Count
		|						- ProductionOperation.FollowUp
		|						- ProductionOperation.QuantityUnderRevision
		|						- ProductionOperation.DefectiveGoodsCount
		|						- ProductionOperation.CountReal
		|						- ProductionOperation.CountCanceled
		|			ELSE 0
		|		END AS Running,
		|		CASE
		|			WHEN ProductionOperation.Status IN (&RunningStatus, &StatusCompleted)
		|				THEN ProductionOperation.CountReal
		|			ELSE 0
		|		END AS Completed2,
		|		CASE
		|			WHEN ProductionOperation.Status = &StatusCompleted
		|					AND ProductionOperation.RepetitionIsRequired
		|				THEN ProductionOperation.CountReal
		|			ELSE 0
		|		END AS RepetitionIsRequired,
		|		CASE
		|			WHEN ProductionOperation.Status = &StatusSkipped
		|				THEN ProductionOperation.Count
		|						- ProductionOperation.CountCanceled
		|			ELSE 0
		|		END AS Skipped3,
		|		CASE
		|			WHEN ProductionOperation.Status IN (&RunningStatus, &StatusCompleted)
		|				THEN ProductionOperation.FollowUp
		|			ELSE 0
		|		END AS UnderControl,
		|		CASE
		|			WHEN ProductionOperation.Status IN (&RunningStatus, &StatusCompleted)
		|				THEN ProductionOperation.QuantityUnderRevision
		|			ELSE 0
		|		END AS UnderRevision,
		|		CASE
		|			WHEN ProductionOperation.Status IN (&RunningStatus, &StatusCompleted)
		|				THEN ProductionOperation.DefectiveGoodsCount
		|			ELSE 0
		|		END AS DefectiveGoods,
		|		CASE
		|			WHEN ProductionOperation.Status = &StatusFailed
		|				THEN ProductionOperation.Count
		|			ELSE ProductionOperation.CountCanceled
		|		END AS Canceled,
		|		CASE
		|			WHEN ProductionOperation.Operation = VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|				THEN CASE
		|						WHEN ProductionOperation.Status = &StatusFailed
		|							THEN ProductionOperation.Count
		|						ELSE ProductionOperation.CountCanceled
		|				END
		|		ELSE 0
		|		END AS CancelledInd,
		|		CASE ProductionOperation.ExecutionTimeUnitOfMeasure
		|			WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|				THEN 60
		|			WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|				THEN 3600
		|			WHEN VALUE(Enum.TimeMeasureUnits.DAY)
		|				THEN 86400
		|			WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|				THEN 86400
		|			ELSE 1
		|		END * ProductionOperation.RunTime AS TimeOfOperationsCreated
		|	FROM
		|		Document.ProductionOperation2_2 AS ProductionOperation
		|	WHERE
		|		ProductionOperation.Stage = &Stage
		|		AND ProductionOperation.OperationID IN (&OperationIds)
		|		AND ProductionOperation.Posted
		|
		|	UNION ALL
		|
		|	SELECT
		|		TechnicalProcess.LastOperationID                      AS OperationID,
		|		VALUE(Document.ProductionOperation2_2.EmptyRef)    AS ProductionOperation,
		|		UNDEFINED                                                   AS RoutesOperationStatus,
		|		UNDEFINED                                                   AS ShiftTask,
		|		UNDEFINED                                                   AS WorkCenter,
		|		UNDEFINED                                                   AS Performer,
		|		FALSE                                                           AS IsDocument,
		|		0                                                              AS BeingGenerated,
		|		TechnicalProcess.CanceledLastOperation                           AS CreatedOn,
		|		0                                                              AS Running,
		|		0                                                              AS Completed2,
		|		0                                                              AS RepetitionIsRequired,
		|		TechnicalProcess.CanceledLastOperation                           AS Skipped3,
		|		0                                                              AS UnderControl,
		|		0                                                              AS UnderRevision,
		|		0                                                              AS DefectiveGoods,
		|		0                                                              AS Canceled,
		|		0                                                              AS CancelledInd,
		|		0                                                              AS TimeOfOperationsCreated
		|	FROM
		|		InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
		|
		|	WHERE
		|		TechnicalProcess.Stage = &Stage
		|		AND TechnicalProcess.LastOperationID IN (&OperationIds)
		|		AND TechnicalProcess.CanceledLastOperation <> 0
		|
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.OperationID,
		|	NestedQuery.ProductionOperation,
		|	NestedQuery.RoutesOperationStatus,
		|	NestedQuery.ShiftTask,
		|	NestedQuery.WorkCenter,
		|	NestedQuery.Performer,
		|	NestedQuery.IsDocument
		|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Stage", Stage);
	Query.SetParameter("OperationIds", OperationIds);
	Query.SetParameter("StatusIsGenerated", Enums.ProductionOperationStatuses.BeingGenerated);
	Query.SetParameter("CreatedStatus", Enums.ProductionOperationStatuses.CreatedOn_);
	Query.SetParameter("RunningStatus", Enums.ProductionOperationStatuses.Running);
	Query.SetParameter("StatusCompleted", Enums.ProductionOperationStatuses.Executed);
	Query.SetParameter("StatusSkipped", Enums.ProductionOperationStatuses.IsSkipped);
	Query.SetParameter("StatusFailed", Enums.ProductionOperationStatuses.NotExecuted);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure CalculateOperationPerformanceIndicators(Operation, OperationData)
	
	Operation.PendingPredecessorCompletion = 0;
	Operation.PreviousOnesStarted   = 0;
	Operation.ExecutionIsAllowed         = 0;
	
	ResultsOfOperation = OperationData.ResultResults;
	
	PreviousOperations_ = PreviousOperations_(OperationData);
	
	CollapseGroupsOfIndividualOperations(OperationData.Owner(), PreviousOperations_);
	
	If PreviousOperations_.UBound() <> -1 Then
		
		If ProductionProcessEditorClientServer.ThisOperationIsIndividual(Operation) Then
			Operation.Scheduled = Operation.Required2;
		Else
			Operation.Scheduled = NonconformityCorrectionFactor(PreviousOperations_) * Operation.Required2;
			OperationData.QuantityPerBatch = Operation.Scheduled;
		EndIf;
		
		YouCanPerformCalculation       = -1;
		StartedPriorSettlement = -1;
		
		If Operation.Scheduled > 0 Then
		
			For Each PreviousOperation In PreviousOperations_ Do
				
				ZoomRatio = CoefficientOfReductionOfStandards(Operation, PreviousOperation);
				
				PreviousOperationResults = PreviousOperation.ResultResults;
				
				EstimatedQuantity = ZoomRatio * (PreviousOperationResults.Completed2 - PreviousOperationResults.RepetitionIsRequired
													+ PreviousOperationResults.Skipped3 + PreviousOperationResults.CancelledInd);
				
				YouCanPerformCalculation = ?(
					YouCanPerformCalculation > -1, Min(YouCanPerformCalculation, EstimatedQuantity), EstimatedQuantity);
				
			EndDo;
			
			For Each PreviousOperation In PreviousOperations_ Do
				
				ZoomRatio = CoefficientOfReductionOfStandards(Operation, PreviousOperation);
				
				PreviousOperationResults = PreviousOperation.ResultResults;
				
				EstimatedQuantity = ZoomRatio * (PreviousOperationResults.Running + PreviousOperationResults.UnderControl + PreviousOperationResults.UnderRevision)
									+ Max(ZoomRatio * (PreviousOperationResults.Completed2 - PreviousOperationResults.RepetitionIsRequired
													+ PreviousOperationResults.Skipped3 + PreviousOperationResults.CancelledInd)
													- YouCanPerformCalculation,
											0);
				
				StartedPriorSettlement = ?(
					StartedPriorSettlement > -1, Min(StartedPriorSettlement, EstimatedQuantity),  EstimatedQuantity);
				
			EndDo;
		
		EndIf;
		
		StartedPriorSettlement = Max(StartedPriorSettlement, 0);
		YouCanPerformCalculation       = Max(YouCanPerformCalculation, 0);

		PendingExecution = Max(Operation.Scheduled + ResultsOfOperation.RepetitionIsRequired, ResultsOfOperation.CreatedOn)
			- (ResultsOfOperation.Running
					+ ResultsOfOperation.Completed2
					+ ResultsOfOperation.UnderControl
					+ ResultsOfOperation.UnderRevision
					+ ResultsOfOperation.DefectiveGoods
					+ ResultsOfOperation.Skipped3
					+ ResultsOfOperation.CancelledInd);
		
		If YouCanPerformCalculation < Max(Operation.Scheduled + ResultsOfOperation.RepetitionIsRequired, ResultsOfOperation.CreatedOn) Then
			Operation.ExecutionIsAllowed = YouCanPerformCalculation
				- (ResultsOfOperation.Running
						+ ResultsOfOperation.Completed2
						+ ResultsOfOperation.UnderControl
						+ ResultsOfOperation.UnderRevision
						+ ResultsOfOperation.DefectiveGoods
						+ ResultsOfOperation.Skipped3
						+ ResultsOfOperation.CancelledInd
						- ResultsOfOperation.RepetitionIsRequired);
		Else
			Operation.ExecutionIsAllowed = PendingExecution;
		EndIf;
		
		Operation.PreviousOnesStarted = Min(StartedPriorSettlement, PendingExecution);
		Operation.PendingPredecessorCompletion = PendingExecution - Operation.ExecutionIsAllowed - Operation.PreviousOnesStarted;
		
	Else
		
		Operation.Scheduled  = Operation.Required2;
		Operation.ExecutionIsAllowed = Max(Operation.Scheduled + ResultsOfOperation.RepetitionIsRequired, ResultsOfOperation.CreatedOn)
				- (ResultsOfOperation.Running
						+ ResultsOfOperation.Completed2
						+ ResultsOfOperation.UnderControl
						+ ResultsOfOperation.UnderRevision
						+ ResultsOfOperation.DefectiveGoods
						+ ResultsOfOperation.Skipped3
						+ ResultsOfOperation.CancelledInd);
		
	EndIf;
	
EndProcedure

Procedure ExpandResultOfOperation(Operations, Operation, OperationData, UseShiftTasks) 
	
	GroupOfOperations = OperationQueueConstructor();
	GroupOfOperations.Columns.Add("ResultString1");
	
	IndividualOFOperation = ProductionProcessEditorClientServer.ThisOperationIsIndividual(Operation);
	
	For Each ResultString1 In OperationData.Result Do
		
		NewRow = GroupOfOperations.Add();
		
		FillPropertyValues(NewRow, Operation);
		FillPropertyValues(NewRow, ResultString1);
		
		NewRow.ResultString1 = ResultString1;
		NewRow.Scheduled    = Max(ResultString1.BeingGenerated, ResultString1.CreatedOn);
		
		If Not IndividualOFOperation Then
			
			PendingExecution = NewRow.Scheduled
								- (ResultString1.Running
										+ ResultString1.Completed2
										+ ResultString1.UnderControl
										+ ResultString1.UnderRevision
										+ ResultString1.DefectiveGoods
										+ ResultString1.Skipped3
										+ ResultString1.CancelledInd);
			
			NewRow.ExecutionIsAllowed         = Min(Operation.ExecutionIsAllowed, PendingExecution);
			NewRow.PreviousOnesStarted   = Min(PendingExecution - NewRow.ExecutionIsAllowed, Operation.PreviousOnesStarted);
			NewRow.PendingPredecessorCompletion = Min(PendingExecution - NewRow.ExecutionIsAllowed - NewRow.PreviousOnesStarted, Operation.PendingPredecessorCompletion);
			
			Operation.Scheduled          = Operation.Scheduled          - NewRow.Scheduled + ResultString1.RepetitionIsRequired;
			Operation.ExecutionIsAllowed         = Operation.ExecutionIsAllowed         - NewRow.ExecutionIsAllowed;
			Operation.PendingPredecessorCompletion = Operation.PendingPredecessorCompletion - NewRow.PendingPredecessorCompletion;
			Operation.PreviousOnesStarted   = Operation.PreviousOnesStarted   - NewRow.PreviousOnesStarted;
			
		EndIf;
		
	EndDo;
	
	If Not IndividualOFOperation Then
		
		If Operation.ExecutionIsAllowed > 0 Then
			NewRow = GroupOfOperations.Insert(0);
			FillPropertyValues(NewRow, Operation);
			NewRow.Scheduled          = Operation.ExecutionIsAllowed;
			NewRow.ExecutionIsAllowed         = Operation.ExecutionIsAllowed;
			NewRow.PendingPredecessorCompletion = 0;
			NewRow.PreviousOnesStarted   = 0;
			Operation.Scheduled = Operation.Scheduled - NewRow.Scheduled;
		EndIf;
		
		If Operation.Scheduled > 0 Or GroupOfOperations.Count() = 0 Then
			NewRow = GroupOfOperations.Insert(0);
			FillPropertyValues(NewRow, Operation);
			NewRow.Scheduled          = Operation.Scheduled;
			NewRow.ExecutionIsAllowed         = 0;
			NewRow.PendingPredecessorCompletion = Operation.PendingPredecessorCompletion;
			NewRow.PreviousOnesStarted   = Operation.PreviousOnesStarted;
		EndIf;
	
	EndIf;
	
	Operations.Delete(Operation);
	
	If GroupOfOperations.Count() > 0 Then
		
		GroupOfOperations[0].MainEntry_ = True;
		
		For Each GroupOperation In GroupOfOperations Do
			
			ResultString1 = GroupOperation.ResultString1;
			
			GroupOperation.State = ActionState(GroupOperation, ResultString1, UseShiftTasks);
			GroupOperation.Order   = OperationProcedure(GroupOperation,  ResultString1);
			
			CalculateTimeIndicatorsOfOperation(GroupOperation, OperationData, ResultString1);
			
			FillPropertyValues(Operations.Add(), GroupOperation);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CalculateTimeIndicatorsOfOperation(Operation, OperationData, ExecutionResult = Undefined)
	
	CalculationStructure = ProductionAccountingClientServer.StructureOfCalculationOfTotalExecutionTime();
	FillPropertyValues(CalculationStructure, OperationData);
	
	ZoomRatio = Operation.Scheduled / OperationData.Count;
	
	ProductionAccountingClientServer.CalculateTotalOperationTime(CalculationStructure, ZoomRatio);
	
	Operation.TimeUnitsOfMeasure = CalculationStructure.ExecutionTimeUnitOfMeasure;
	
	If ZoomRatio = 0 Then
		Operation.TimeTotal = 0;
	ElsIf ExecutionResult <> Undefined And ExecutionResult.CreatedOn > 0 Then
		Operation.TimeTotal = ProductionPlanningClientServer.GetTimeInUnit(
				ExecutionResult.TimeOfOperationsCreated, Operation.TimeUnitsOfMeasure);
	Else
		Operation.TimeTotal = CalculationStructure.RunTime;
	EndIf;
	
	If OperationData.TimePerPiece > 0 Then
		If OperationData.TimePerPieceUnitOfMeasure = Operation.TimeUnitsOfMeasure Then
			Operation.TimePerPiece = OperationData.TimePerPiece;
		Else
			Operation.TimePerPiece = ProductionPlanningClientServer.GetTimeInUnit(
				ProductionPlanningClientServer.GetTimeInSeconds(
					OperationData.TimePerPiece,
					OperationData.TimePerPieceUnitOfMeasure),
				Operation.TimeUnitsOfMeasure);
		EndIf;
	EndIf;
	
	If OperationData.SetupTime > 0 Then
		If OperationData.SetupTimeUnitOfMeasure = Operation.TimeUnitsOfMeasure Then
			Operation.SetupTime = OperationData.SetupTime;
		Else
			Operation.SetupTime = ProductionPlanningClientServer.GetTimeInUnit(
				ProductionPlanningClientServer.GetTimeInSeconds(
					OperationData.SetupTime,
					OperationData.SetupTimeUnitOfMeasure),
				Operation.TimeUnitsOfMeasure);
		EndIf;
	EndIf;
	
EndProcedure

Function ActionState(Operation, ExecutionResult, UseShiftTasks)
	
	Result = Enums.OperationStates.EmptyRef();
	
	ThereIsAssignedDocumentOfOperation = ValueIsFilled(ExecutionResult)
		And ValueIsFilled(ExecutionResult.ProductionOperation)
		And Not ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.BeingGenerated;
	
	If (ThereIsAssignedDocumentOfOperation
				And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.NotExecuted)
			Or Operation.Scheduled = 0 Then
		Result = Enums.OperationStates.RolledBack;
	ElsIf (ThereIsAssignedDocumentOfOperation
				And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.IsSkipped)
			Or Operation.Skipped3 >= Operation.Scheduled Then
		Result = Enums.OperationStates.IsSkipped;
	ElsIf ThereIsAssignedDocumentOfOperation
			And Operation.UnderRevision > 0
			And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.Running Then
		Result = Enums.OperationStates.UnderRevision;
	ElsIf ThereIsAssignedDocumentOfOperation
			And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.Running Then
		Result = Enums.OperationStates.Running;
	ElsIf ThereIsAssignedDocumentOfOperation
			And Operation.UnderControl > 0
			And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.Executed Then
		Result = Enums.OperationStates.UnderControl;
	ElsIf ThereIsAssignedDocumentOfOperation
			And ExecutionResult.RoutesOperationStatus = Enums.ProductionOperationStatuses.Executed Then
		Result = Enums.OperationStates.Executed;
	ElsIf Not ThereIsAssignedDocumentOfOperation
			And UseShiftTasks
			And Operation.ExecutionIsAllowed > 0 Then
		Result = Enums.OperationStates.ToAssign;
	ElsIf Operation.ExecutionIsAllowed > 0
			And (Operation.PendingPredecessorCompletion + Operation.PreviousOnesStarted) = 0 Then
		Result = Enums.OperationStates.ForCompletion;
	Else
		Result = Enums.OperationStates.PendingPredecessorCompletion;
	EndIf;
	
	Return Result;
	
EndFunction

Function OperationProcedure(Operation, ExecutionResult = Undefined)
	
	Result = 1000 * Enums.OperationStates.OrderInList(Operation.State);
	
	Return Result;
	
EndFunction

Procedure FillInAttributesOfTechnologicalProcess(Operation, OperationData, Data_Stage)
	
	If ValueIsFilled(OperationData.TechnologicalProcess) Then
		Operation.TechnologicalProcess = OperationData.TechnologicalProcess;
		Operation.TechnologicalProcessFactor = OperationData.TechnologicalProcessFactor;
	Else
		Operation.TechnologicalProcess = Data_Stage.TechnologicalProcess;
		Operation.TechnologicalProcessFactor = Data_Stage.TechnologicalProcessFactor;
	EndIf;
	
EndProcedure

Function NonconformityCorrectionFactor(PreviousOperations_)
	
	Result = 1;
	
	For Each PreviousOperation In PreviousOperations_ Do
		If PreviousOperation.Required2 > 0 Then
			Result = Min(Result,
				(PreviousOperation.QuantityPerBatch
					- PreviousOperation.ResultResults.DefectiveGoods) / PreviousOperation.Required2);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function CoefficientOfReductionOfStandards(Operation, PreviousOperation)
	
	If ProductionProcessEditorClientServer.ThisOperationIsIndividual(Operation) Then
		Result = Operation.Required2/PreviousOperation.QuantityPerBatch;
	Else
		Result = Operation.Required2/PreviousOperation.Required2;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Function PerformControlBeforeCalculatingQueue(Data_Stage, RemovalOfBody = False, Cancel = False)
	
	HasError = False;
	
	If Data_Stage.RequiredToCalculate And Not RemovalOfBody Then
		
		If Data_Stage.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.AlternateType
			Or (Data_Stage.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Standard
					And Not GetFunctionalOption("StoreOperationsInBillsOfMaterials")) Then
		
			Query = New Query(
			"SELECT
			|	SUM(Queue.CreatedOn) > 0 AS ErrorInOperations
			|FROM
			|	InformationRegister.QueueOfProductionOperations AS Queue
			|	LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
			|	ON Queue.Department = AssignedOperations.Department
			|		AND Queue.Stage = AssignedOperations.Stage
			|		AND Queue.Operation = AssignedOperations.Operation
			|		AND Queue.OperationID = AssignedOperations.OperationID
			|		AND AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
			|WHERE
			|	Queue.Stage = &Stage
			|
			|HAVING
			|	(SUM(Queue.CreatedOn) > 0 
			|		OR MAX(AssignedOperations.Stage IS NOT NULL) = TRUE)
			|	AND (MAX(CASE
			|				WHEN Queue.TechnologicalProcess <> &TechnologicalProcess
			|					THEN TRUE
			|				ELSE FALSE
			|			END) = TRUE
			|		OR MAX(CASE
			|				WHEN Queue.TechnologicalProcessFactor <> &TechnologicalProcessFactor
			|					THEN TRUE
			|				ELSE FALSE
			|			END) = TRUE)");
			Query.SetParameter("Stage", Data_Stage.Ref);
			Query.SetParameter("TechnologicalProcess", Data_Stage.TechnologicalProcess);
			Query.SetParameter("TechnologicalProcessFactor", Data_Stage.TechnologicalProcessFactor);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				HasError = True;
				
				If Selection.ErrorInOperations Then
					MessageText = NStr("vi = 'Cấm thay đổi quy trình công nghệ và hệ số sau khi tạo ra các giao dịch sản xuất.';
										|ru = 'Запрещено изменять технологический процесс и коэффициент после создания производственных операций.';
										|en = 'Cannot edit the technological process or the factor after creating routing operations.'; fa = 'Cannot edit the technological process or the factor after creating routing operations.';
										|it = 'Cannot edit the technological process or the factor after creating routing operations.';
										|pl = 'Cannot edit the technological process or the factor after creating routing operations.';
										|tr = 'Rota işlemleri oluşturulduktan sonra teknolojik süreç ve katsayı değişikliği yapmak yasaktır.'");
				Else
					MessageText = NStr("vi = 'Cấm thay đổi quy trình công nghệ và hệ số sau khi tạo ra các ca làm việc.';
										|ru = 'Запрещено изменять технологический процесс и коэффициент после создания сменных заданий.';
										|en = 'Cannot edit the technological process or the factor after creating shift tasks.'; fa = 'Cannot edit the technological process or the factor after creating shift tasks.';
										|it = 'Cannot edit the technological process or the factor after creating shift tasks.';
										|pl = 'Cannot edit the technological process or the factor after creating shift tasks.';
										|tr = 'Vardiyalı görevler oluşturulduktan sonra teknolojik süreç ve katsayı değişikliği yapmak yasaktır.'");
				EndIf;
				
			EndIf;
		
		EndIf;
		
	Else
		
		Query = New Query(
		"SELECT TOP 1
		|	TRUE AS ErrorInOperations
		|FROM
		|	Document.ProductionOperation2_2 AS Operations
		|WHERE
		|	Operations.Stage = &Stage
		|	AND (Operations.BasedOnMasterData
		|		OR Operations.Status <> VALUE(Enum.ProductionOperationStatuses.BeingGenerated))
		|	AND NOT Operations.DeletionMark
		|	AND NOT &EndOfStage
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	FALSE
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|WHERE
		|	AssignedOperations.Stage = &Stage
		|	AND AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)");
		Query.SetParameter("Stage", Data_Stage.Ref);
		Query.SetParameter("EndOfStage", Data_Stage.Status = Enums.StatusesOfProductionStages2_2.Completed And Not RemovalOfBody);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			HasError = True;
			
			If Selection.ErrorInOperations Then
				MessageText = NStr("vi = 'Các công đoạn tạo ra giao dịch.';
									|ru = 'По этапу созданы операции.';
									|en = 'Operations are created for the stage.'; fa = 'Operations are created for the stage.';
									|it = 'Operazioni create per fase.';
									|pl = 'Wg etapu stworzone operacji.';
									|tr = 'Aşamaya göre işlemler oluşturuldu.'");
			Else
				MessageText = NStr("vi = 'Công đoạn tạo ra các nhiệm vụ thay đổi.';
									|ru = 'По этапу созданы сменные задания.';
									|en = 'Shift tasks are created by the stage.'; fa = 'Shift tasks are created by the stage.';
									|it = 'Compiti sostituibili creati per fase.';
									|pl = 'Wg etapu stworzone zadania zmianowe.';
									|tr = 'Aşamaya göre vardiyalı görevler oluşturuldu.'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If HasError Then
		
		MessageText = StrTemplate(NStr("vi = 'Lỗi tính toán hàng đợi của giao dịch sản xuất. %1';
										|ru = 'Ошибка расчета очереди производственных операций. %1';
										|en = 'An error occurred while calculating routing operation queue. %1'; fa = 'An error occurred while calculating routing operation queue. %1';
										|it = 'Errore nel calcolo della coda delle operazioni di produzione. %1';
										|pl = 'Błąd podczas obliczania kolejki operacji produkcyjnych. %1';
										|tr = 'Rota işlemleri kuyruğu hesaplanırken hata oluştu. %1'"), MessageText);
		
		Common.MessageToUser(
				MessageText,
				,
				,
				,
				Cancel);
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure ReportQueueCalculationErrorToUser(Cancel)
	
	MessageText = NStr("vi = 'Không thể tính toán hàng đợi sản xuất.';
						|ru = 'Не удалось рассчитать очередь производственных операций.';
						|en = 'Cannot calculate the routing operation queue.'; fa = 'Cannot calculate the routing operation queue.';
						|it = 'Impossibile calcolare la coda di produzione.';
						|pl = 'Nie udało się obliczyć kolejki operacji produkcyjnych.';
						|tr = 'Rota işlemleri kuyruğu hesaplanamadı.'");
	
	Common.MessageToUser(
			MessageText,
			,
			,
			, 
			Cancel);

EndProcedure


#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.QueueOfProductionOperations.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.25.12";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("833b3f93-6c82-4ec3-805d-fc4f9f10a11a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.QueueOfProductionOperations.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Chuyển đổi hàng đợi sang định dạng lưu trữ mới, xóa các bản ghi lưu trữ.';
							|ru = 'Конвертация очереди в новый формат хранения, удаление архивных записей.';
							|en = 'Convert the queue to a new storage format, delete archived records.'; fa = 'Convert the queue to a new storage format, delete archived records.';
							|it = 'Convert the queue to a new storage format, delete archived records.';
							|pl = 'Convert the queue to a new storage format, delete archived records.';
							|tr = 'Sıranın yeni depolama biçimine dönüştürülmesi, arşivlenmiş kayıtların silinmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.QueueOfProductionOperations.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.DeleteQueueOfRoutingOperations.FullName());
	ItemsToRead.Add(Metadata.Documents.ProductionStage2_2.FullName());
	ItemsToRead.Add(Metadata.Documents.ProductionOperation2_2.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.QueueOfProductionOperations.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.QueueOfProductionOperations.FullName());
	ToLock.Add(Metadata.InformationRegisters.OperationsToCreateShiftTasks.FullName());
	ToLock.Add(Metadata.InformationRegisters.PostOperativeSchedule2_2.FullName());
	ToLock.Add(Metadata.Documents.ProductionStage2_2.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "InformationRegisters.TechnologicalProcessesOfProductionStages.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.QueueOfProductionOperations";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Stage.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Stage");
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	QueryText = "
	|SELECT
	|	QueueIsOld.Stage AS Stage
	|FROM
	|	InformationRegister.DeleteQueueOfRoutingOperations AS QueueIsOld
	|WHERE
	|	QueueIsOld.Stage.Status IN (
	|		VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
	|		VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.QueueOfProductionOperations AS QueueNew
	|				WHERE
	|					QueueNew.Stage = QueueIsOld.Stage)
	|	AND NOT QueueIsOld.InArchive
	|
	|UNION
	|
	|SELECT
	|	QueueNew.Stage AS Stage
	|FROM
	|	InformationRegister.QueueOfProductionOperations AS QueueNew
	|WHERE
	|	QueueNew.Operation <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|	AND QueueNew.TimePerPiece <> 0
	|	AND QueueNew.SetupTime = 0
	|	AND CASE
	|		WHEN QueueNew.Operation.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN CASE
	|					WHEN CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenterTypes).ParallelLoad
	|							AND CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenterTypes).ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|						THEN CASE
	|								WHEN CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenterTypes).SetupSettingsAreUsed
	|									THEN QueueNew.Operation.SetupSettings.UnitOfMeasure
	|								ELSE CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenterTypes).UnitOfMeasure
	|							END
	|					ELSE QueueNew.Operation.TimePerPieceUnitOfMeasure
	|				END
	|		ELSE CASE
	|				WHEN CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ParallelLoad
	|						AND CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|					THEN CASE
	|							WHEN CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenters).WorkCenterType.SetupSettingsAreUsed
	|								THEN QueueNew.Operation.SetupSettings.UnitOfMeasure
	|							ELSE CAST(QueueNew.Operation.WorkCenter AS Catalog.WorkCenters).WorkCenterType.UnitOfMeasure
	|						END
	|				ELSE QueueNew.Operation.TimePerPieceUnitOfMeasure
	|			END
	|	END <> QueueNew.TimeUnitsOfMeasure
	|	AND QueueNew.Operation.SetupTimeUnitOfMeasure = QueueNew.TimeUnitsOfMeasure
	|	AND NOT QueueNew.InArchive
	|";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(
		Parameters,
		Query.Execute().Unload(),
		AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.QueueOfProductionOperations";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Stages = New Array;
	For Each Selection In UpdatedData Do
		Stages.Add(Selection.Stage);
	EndDo;
	
	BadData = New Map;
	StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Stages);
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Data_Stage = StageData_1[Selection.Stage]; // Structure
			
			DataLock = BlockingDataForQueueCalculation(Selection.Stage);
			LockItem = DataLock.Add("Document.ProductionStage2_2");
			LockItem.SetValue("Ref", Selection.Stage);
			LockItem.Mode = DataLockMode.Shared;
			DataLock.Lock();
			
			RecordSet = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
			RecordSet.Filter.Stage.Set(Selection.Stage);
			
			Queue = OperationQueue(Selection.Stage, Data_Stage);
			RecordSet.Load(Queue);
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("ru = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2';
						|vi = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2';
						|en = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2'; fa = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2';
						|it = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2';
						|pl = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2';
						|tr = 'Не удалось записать очередь операций по этапу ""%1"", по причине: %2'"),
					Selection.Stage,
					ErrorProcessing.DetailErrorDescription((ErrorInfo())));
					
			BadData.Insert(Selection.Stage, MessageText);
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.InformationRegisters.QueueOfProductionOperations,,
				MessageText);
			
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullRegisterName);
		
	For Each UnprocessedObject In BadData Do
		InfobaseUpdate.FileIssueWithData(UnprocessedObject.Key, UnprocessedObject.Value);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
