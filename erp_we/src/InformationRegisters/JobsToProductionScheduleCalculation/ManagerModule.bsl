#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the register.
//
// Parameters:
//  Stages - DocumentRef.ProductionStage2_2, Array - the stages for which you want to add entries.
//		Tasks are not added for stages with manual placement in the schedule.
//
Procedure AddTasks(Stages) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForCalculatingProductionSchedule");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
		RecordSeparator = String(New UUID);
		
		Query = New Query(
			"SELECT
			|	Stages.ReferenceOrder    AS ReferenceOrder,
			|	Stages.Ref          AS ProductionStage,
			|	JobNumber.Value AS JobNumber,
			|	&RecordSeparator    AS RecordSeparator
			|FROM
			|	Document.ProductionStage2_2 AS Stages,
			|	Constant.NumberOfJobForCalculatingProductionSchedule AS JobNumber
			|WHERE
			|	Stages.Ref IN(&Stages)
			|	AND NOT Stages.StagePlacementInProductionSchedule
			|	AND NOT Stages.DynamicStructure");
		Query.SetParameter("Stages", Stages);
		Query.SetParameter("RecordSeparator", RecordSeparator);
		
		Set = InformationRegisters.JobsToProductionScheduleCalculation.CreateRecordSet();
		Set.Load(Query.Execute().Unload());
		Set.Write(False);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		EventName = NStr("vi = 'Thêm nhiệm vụ vào tính toán tiến độ sản xuất';
						|ru = 'Добавление заданий к расчету графика производства';
						|en = 'Add jobs for calculating production schedule'; fa = 'Add jobs for calculating production schedule';
						|it = 'Aggiunta di compiti per il calcolo del programma di produzione';
						|pl = 'Dodanie zadań do obliczeń harmonogramu produkcji';
						|tr = 'Üretim programının hesaplanmasına görev eklenmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
		
	EndTry;
	
EndProcedure

// Adds entries to the register.
//
// Parameters:
//  Stages - ValueTable - a table containing the stages for which records need to be added.
//		Tasks are not added for stages with manual placement in the schedule:
//		* ProductionStage - DocumentRef.ProductionStage2_2 - stage.
//		* ProductionStageInitiator - DocumentRef.ProductionStage2_2 - the task initiator stage.
//
Procedure AddTasksWithInitiators(Stages) Export
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForCalculatingProductionSchedule");
		LockItem.Mode = DataLockMode.Shared;
		Block.Lock();
		
		RecordSeparator = String(New UUID);
		
		Query = New Query(
			"SELECT
			|	Stages.ProductionStage          AS ProductionStage,
			|	Stages.ProductionStageInitiator AS ProductionStageInitiator
			|INTO TTStages
			|FROM &Stages AS Stages
			|
			|;
			|
			|SELECT
			|	Documents.ReferenceOrder          AS ReferenceOrder,
			|	Documents.Ref                AS ProductionStage,
			|	JobNumber.Value           AS JobNumber,
			|	&RecordSeparator              AS RecordSeparator,
			|	Stages.ProductionStageInitiator AS ProductionStageInitiator
			|FROM
			|	TTStages AS Stages
			|
			|	LEFT JOIN Document.ProductionStage2_2 AS Documents
			|	ON Stages.ProductionStage = Documents.Ref
			|
			|	LEFT JOIN Constant.NumberOfJobForCalculatingProductionSchedule AS JobNumber
			|	ON TRUE
			|WHERE
			|	NOT Documents.StagePlacementInProductionSchedule");
		Query.SetParameter("Stages", Stages);
		Query.SetParameter("RecordSeparator", RecordSeparator);
		
		Set = InformationRegisters.JobsToProductionScheduleCalculation.CreateRecordSet();
		Set.Filter.RecordSeparator.Set(RecordSeparator);
		Set.Load(Query.Execute().Unload());
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		EventName = NStr("vi = 'Thêm nhiệm vụ vào tính toán tiến độ sản xuất';
						|ru = 'Добавление заданий к расчету графика производства';
						|en = 'Add jobs for calculating production schedule'; fa = 'Add jobs for calculating production schedule';
						|it = 'Aggiunta di compiti per il calcolo del programma di produzione';
						|pl = 'Dodanie zadań do obliczeń harmonogramu produkcji';
						|tr = 'Üretim programının hesaplanmasına görev eklenmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
		
	EndTry;
	
EndProcedure

// Deletes tasks.
//
// Parameters:
//   Jobs - ValueTable - tasks to delete with the values of all measurements of the register.
//
Procedure DeleteTasks(Jobs) Export
	
	If Jobs.Count() = 0 Then
		Return;
	EndIf;
	
	Set = InformationRegisters.JobsToProductionScheduleCalculation.CreateRecordSet();
	Set.Load(Jobs);
	Set.Write(ReplacementMode.Delete);
	
EndProcedure

// Deletes stage records by the specified task number.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order
//		that the stages belong to (see the Stages parameter).
//  Stages - DocumentRef.ProductionStage2_2, Array - stages
//		the record for which you want to delete.
//  JobNumber - Number - When clearing, records with job numbers less than or equal
//		to the parameter value will be deleted.
//
Procedure DeleteTasksByNumber(ReferenceOrder, Stages, JobNumber) Export
	
	Query = New Query(
		"SELECT
		|	Jobs.ReferenceOrder              AS ReferenceOrder,
		|	Jobs.ProductionStage          AS ProductionStage,
		|	Jobs.JobNumber              AS JobNumber,
		|	Jobs.RecordSeparator         AS RecordSeparator,
		|	Jobs.ProductionStageInitiator AS ProductionStageInitiator
		|FROM
		|	InformationRegister.JobsToProductionScheduleCalculation AS Jobs
		|WHERE
		|	Jobs.ReferenceOrder = &ReferenceOrder
		|	AND Jobs.ProductionStage IN (&Stages)
		|	AND Jobs.JobNumber <= &JobNumber");
	Query.SetParameter("ReferenceOrder",  ReferenceOrder);
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("JobNumber", JobNumber);
	
	Set = InformationRegisters.JobsToProductionScheduleCalculation.CreateRecordSet();
	Set.Load(Query.Execute().Unload());
	Set.Write(ReplacementMode.Delete);
	
EndProcedure

// Deletes tasks.
//
// Parameters:
//   Filter - Structure - selection structure, the names of the dimensions for which the selection will be applied are passed as keys..
//
Procedure DeleteSelectionEntries(Filter) Export
	
	If Filter.Count() = 0 Then
		Return;
	EndIf;
	
	Set = InformationRegisters.JobsToProductionScheduleCalculation.CreateRecordSet();
	If Filter.Property("ReferenceOrder") Then
		Set.Filter.ReferenceOrder.Set(Filter.ReferenceOrder);
	EndIf;
	If Filter.Property("ProductionStage") Then
		Set.Filter.ProductionStage.Set(Filter.ProductionStage);
	EndIf;
	If Filter.Property("JobNumber") Then
		Set.Filter.JobNumber.Set(Filter.JobNumber);
	EndIf;
	If Filter.Property("RecordSeparator") Then
		Set.Filter.RecordSeparator.Set(Filter.RecordSeparator);
	EndIf;
	If Filter.Property("ProductionStageInitiator") Then
		Set.Filter.ProductionStageInitiator.Set(Filter.ProductionStageInitiator);
	EndIf;
	SetPrivilegedMode(True);
	Set.Write();
	SetPrivilegedMode(False);

EndProcedure

// Returns the flag for whether the production stage schedule is up-to-date.
//
// Parameters:
//  ProductionStage - DocumentRef.ProductionStage2_2 - the stage
//		whose schedule needs to be checked for relevance.
// 
// Returns:
//  Boolean - the relevance of the stage schedule.
//
Function StageScheduleIsRelevant(ProductionStage) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	JobsToProductionScheduleCalculation.ProductionStage
	|FROM
	|	InformationRegister.JobsToProductionScheduleCalculation AS JobsToProductionScheduleCalculation
	|WHERE
	|	JobsToProductionScheduleCalculation.ProductionStage = &ProductionStage");
	Query.SetParameter("ProductionStage", ProductionStage);
	
	QueryResult = Query.Execute();
	
	Return QueryResult.IsEmpty();
	
EndFunction

// Returns a table of tasks for this stage of production (all measurements of the register).
// 
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2
//  ProductionStage - DocumentRef.ProductionStage2_2
// 
// Returns:
//  ValueTable
//
Function TasksByStage(ReferenceOrder, ProductionStage) Export
	
	Query = New Query(
		"SELECT
		|	Jobs.ReferenceOrder              AS ReferenceOrder,
		|	Jobs.ProductionStage          AS ProductionStage,
		|	Jobs.JobNumber              AS JobNumber,
		|	Jobs.RecordSeparator         AS RecordSeparator,
		|	Jobs.ProductionStageInitiator AS ProductionStageInitiator
		|FROM
		|	InformationRegister.JobsToProductionScheduleCalculation AS Jobs
		|WHERE
		|	Jobs.ReferenceOrder = &ReferenceOrder
		|	AND Jobs.ProductionStage = &ProductionStage");
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ProductionStage", ProductionStage);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf