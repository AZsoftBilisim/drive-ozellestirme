#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds entries to the task register.
//
// Parameters:
//  Scenario	 - CatalogRef.SalesOperationsPlanningScenarios
//  ProductionPlan	 - DocumentRef.ProductionPlan	 - the document for which you want to add the assignment.
//  AutoStart		 - Boolean							 - automatically starts the calculation as a background task.
//
Procedure AddJob(Scenario, ProductionPlan, AutoStart = True) Export
	
	Jobs = New Array();
	
	NewJob = New Structure();
	NewJob.Insert("State", Enums.StatesOfProductionPlanCalculation.CalculationIsRequired);
	NewJob.Insert("Scenario", Scenario);
	NewJob.Insert("ProductionPlan", ProductionPlan);
	Jobs.Add(NewJob);
	
	If GetFunctionalOption("UseBudgeting") Then
		NewJob = New Structure();
		NewJob.Insert("State", Enums.StatesOfProductionPlanCalculation.RecordInBudgetingIsRequired);
		NewJob.Insert("Scenario", Scenario);
		NewJob.Insert("ProductionPlan", ProductionPlan);
		Jobs.Add(NewJob);
	EndIf;
	
	IDs = ProductionServer.AddTaskToQueue("QueueOfProductionPlanCalculation", Jobs);
	
	If AutoStart Then
		Priority = New Structure("ProductionPlan", ProductionPlan);
		ProductionServer.StartQueueProcessingJob("QueueOfProductionPlanCalculation", Priority, IDs);
	EndIf;
	
EndProcedure

// Runs production planning in the background
//
Procedure RunJob() Export
	
	ProductionServer.StartQueueProcessingJob("QueueOfProductionPlanCalculation");
	
EndProcedure

// Checks the activity of the production plan calculation
// 
// Returns:
//  Boolean - True if the job queue is being processed
//
Function QueueProcessingIsInProgress() Export
	
	Result = ProductionServer.QueueProcessingIsInProgress("QueueOfProductionPlanCalculation");
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ProcessingParameters() Export
	
	ProcessingParameters = New Structure();
	ProcessingParameters.Insert("Handler", "InformationRegisters.QueueOfProductionPlanCalculation.ProcessTasks_");
	ProcessingParameters.Insert("DonTRunInBackground", Common.FileInfobase());
	ProcessingParameters.Insert("AdditionalData", New Structure);
	Return ProcessingParameters;
	
EndFunction

Function JobsQueue(Filter = Undefined) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query(
	"SELECT DISTINCT
	|	CalculationQueue.State AS State,
	|	CalculationQueue.ProductionPlan AS ProductionPlan,
	|	CalculationQueue.Scenario AS Scenario
	|INTO CalculationQueue
	|FROM
	|	InformationRegister.QueueOfProductionPlanCalculation AS CalculationQueue
	|WHERE
	|	CalculationQueue.State IN (
	|			VALUE(Enum.StatesOfProductionPlanCalculation.CalculationIsRequired),
	|			VALUE(Enum.StatesOfProductionPlanCalculation.RecordInBudgetingIsRequired)
	|		)
	|	AND &Filter
	|	AND NOT CalculationQueue.HasErrors
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	JobsForCalculating.State        AS State,
	|	JobsForCalculating.ProductionPlan AS ProductionPlan,
	|	JobsForCalculating.Scenario AS Scenario,
	|	JobsForCalculating.Id    AS Id,
	|	JobsForCalculating.RegistrationDay  AS RegistrationDay,
	|	JobsForCalculating.HasErrors       AS HasErrors
	|INTO ProcessedTasks
	|FROM
	|	InformationRegister.QueueOfProductionPlanCalculation AS JobsForCalculating
	|WHERE
	|	(JobsForCalculating.State, JobsForCalculating.ProductionPlan) IN
	|			(SELECT
	|				CalculationQueue.State,
	|				CalculationQueue.ProductionPlan
	|			FROM
	|				CalculationQueue AS CalculationQueue)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VALUE(Enum.StatesOfProductionPlanCalculation.ClearUnusedDataIsRequired),
	|	CalculationQueue.ProductionPlan,
	|	CalculationQueue.Scenario,
	|	&BlankID,
	|	DATETIME(1,1,1),
	|	FALSE
	|FROM
	|	CalculationQueue AS CalculationQueue
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CalculationQueue
	|");
	Query.SetParameter("BlankID", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.TempTablesManager = TempTablesManager;
	
	If Filter <> Undefined Then
		Query.Text = StrReplace(Query.Text, "&Filter", "CalculationQueue.ProductionPlan = &ProductionPlan");
		Query.SetParameter("ProductionPlan", Filter.ProductionPlan);
	Else
		Query.Text = StrReplace(Query.Text, "&Filter", "TRUE");
	EndIf;
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If ResultsArray[1].Unload()[0].Count = 0 Then
		Return Undefined;
	EndIf;
	
	Return TempTablesManager;
	
EndFunction

Function SelectFromQueue(TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	CalculationQueue.State               AS State,
	|	CalculationQueue.ProductionPlan        AS ProductionPlan,
	|	CalculationQueue.Scenario                AS Scenario,
	|	MAX(CalculationQueue.Id) AS Id
	|FROM
	|	ProcessedTasks AS CalculationQueue
	|WHERE 
	|	NOT CalculationQueue.HasErrors
	|
	|GROUP BY
	|	CalculationQueue.Scenario,
	|	CalculationQueue.ProductionPlan,
	|	CalculationQueue.State
	|
	|ORDER BY
	|	ProductionPlan,
	|	State");
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Result = New Array();
	While Selection.Next() Do
		Job = New Structure("ProductionPlan,Scenario,State,Id");
		FillPropertyValues(Job, Selection);
		Result.Add(Job);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ProcessTasks_(Job, SkipTask = False, AdditionalData = Undefined) Export
	
	CalculationStart = RecordStartEndOfCalculation(Job.ProductionPlan);
	
	If Job.State = Enums.StatesOfProductionPlanCalculation.CalculationIsRequired Then
		
		OperationName = NStr("vi = 'Tính toán (điều chỉnh) kế hoạch sản xuất';
							|ru = 'Расчет (корректировка) плана производства';
							|en = 'Production plan calculation (adjustment)'; fa = 'Production plan calculation (adjustment)';
							|it = 'Calcolo (correzione) del piano di produzione';
							|pl = 'Obliczenia (korekta) planu produkcji';
							|tr = 'Muhasebe (düzenleme) üretim planı'");
		CalculationOfProductionPlan.Calculate(Job.ProductionPlan);
		
	ElsIf Job.State = Enums.StatesOfProductionPlanCalculation.RecordInBudgetingIsRequired Then
		
		OperationName = NStr("vi = 'Phản ánh ngân sách';
							|ru = 'Отражение в бюджетировании';
							|en = 'Record in budgeting'; fa = 'ثبت در بودجه‌بندی';
							|it = 'Visualizzazione nel budgeting';
							|pl = 'Odzwierciedlenie w budżetowaniu';
							|tr = 'Bütçelemede yansıma'");
		InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.AddJob(Job.ProductionPlan);
		InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.RunJob();
		
	ElsIf Job.State = Enums.StatesOfProductionPlanCalculation.ClearUnusedDataIsRequired Then
		
		OperationName = NStr("vi = 'Xóa dữ liệu không sử dụng';
							|ru = 'Очистка неиспользуемых данных';
							|en = 'Clear unused data'; fa = 'پاک‌سازی داده‌های استفاده‌نشده';
							|it = 'Cancellazione di dati non utilizzati';
							|pl = 'Czyszczenie zbędnych danych';
							|tr = 'Kullanılmayan verilerin temizlenmesi'");
		CalculationOfProductionPlan.ClearUnusedData(Job.ProductionPlan);
		
	EndIf;
	
	CalculationEnd = RecordStartEndOfCalculation(Job.ProductionPlan, True);
	
	RecordCalculationProtocolInLog(Job.ProductionPlan, OperationName, CalculationStart, CalculationEnd);
	
EndProcedure

Procedure RecordCalculationProtocolInLog(ProductionPlan, OperationName, CalculationStart, CalculationEnd)
	
	EventName = CalculationOfProductionPlan.EventLogEvent();
	
	TimeInSeconds = CalculationEnd - CalculationStart;
	
	Hours1 = Int(TimeInSeconds/3600);
	Minutes1 = Int((TimeInSeconds - Hours1 * 3600) / 60);
	Seconds = Max(TimeInSeconds - Hours1 * 3600 - Minutes1 * 60, 1);
	
	DurationHours = ?(Hours1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giờ';
																									|ru = '%1 час';
																									|en = '%1 hour'; fa = '%1 hour';
																									|it = '%1 ora';
																									|pl = '%1 godzina';
																									|tr = '%1 saat'"), Hours1));
	DurationMinutes = ?(Minutes1 = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 phút';
																										|ru = '%1 мин';
																										|en = '%1 min'; fa = '%1 min';
																										|it = '%1 minuto';
																										|pl = '%1 min';
																										|tr = '%1 dk.'"), Minutes1));
	DurationSeconds = ?(Seconds = 0, "", StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 giây';
																										|ru = '%1 сек';
																										|en = '%1 sec'; fa = '%1 sec';
																										|it = '%1 sec-';
																										|pl = '%1 sek';
																										|tr = '%1 sn.'"), Seconds));
	DurationOfCalculation = DurationHours + " " + DurationMinutes + " " + DurationSeconds;
	DurationOfCalculation = TrimAll(DurationOfCalculation);
	
	MessageText = StrTemplate(NStr("vi = 'Đã hoàn tất thao tác ""%1"", thời lượng %2';
									|ru = 'Завершено выполнение операции ""%1"", продолжительность %2';
									|en = 'Operation completed ""%1"", duration %2'; fa = 'Operation completed ""%1"", duration %2';
									|it = 'Esecuzione dell''operazione ""%1"" completata, durata %2';
									|pl = 'Zakończono wykonywanie operacji ""%1"" czas trwania %2';
									|tr = 'Operasyon ""%1"" in doldurması bitti,süreklilik %2'"), OperationName, DurationOfCalculation);
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Information,
		Metadata.InformationRegisters.QueueOfProductionPlanCalculation,
		ProductionPlan,
		MessageText);

EndProcedure

Procedure DeleteJob(Job, TempTablesManager) Export
	
	If ThisIsVirtualJob(Job) Then
		Return;
	EndIf;
	
	ProductionServer.DeleteJob("QueueOfProductionPlanCalculation", Job, TempTablesManager);
	
EndProcedure

// Record the error.
// 
// Parameters:
//  Job - Structure - From:
//   * State - EnumRef.StatesOfProductionPlanCalculation
//   * ProductionPlan - DocumentRef.ProductionPlan
//   * Id - UUID
//   * Scenario - CatalogRef.SalesOperationsPlanningScenarios
//  SkipTask - Boolean
//  ErrorInfo - ErrorInfo
Procedure WriteError(Job, SkipTask, ErrorInfo) Export
	
	ErrorText = DetailErrorDescription(ErrorInfo);
	
	If Not ThisIsVirtualJob(Job) Then
		
		Try
			
			Set = InformationRegisters.QueueOfProductionPlanCalculation.CreateRecordSet();
			
			Set.Filter.State.Set(Job.State);
			Set.Filter.ProductionPlan.Set(Job.ProductionPlan);
			Set.Filter.Id.Set(Job.Id);
			
			Set.Read();
			
			For Each Record In Set Do
				Record.HasErrors = True;
				Record.ErrorText = ErrorText;
			EndDo;
			
			SetPrivilegedMode(True);
			Set.Write(True);
			SetPrivilegedMode(False);
			
			SkipTask = True;
			
		Except
			// no additional actions are required, the error message will be recorded in the log
		EndTry;
		
	Else
		SkipTask = True;
	EndIf;
	
	ProductionServer.RecordTaskQueueProcessingError("QueueOfProductionPlanCalculation", ErrorText, Job, Job.ProductionPlan);
	
EndProcedure

Function RecordStartEndOfCalculation(ProductionPlan, CalculationIsCompleted = False)
	
	Set = InformationRegisters.QueueOfProductionPlanCalculation.CreateRecordSet();
	Set.Filter.State.Set(Enums.StatesOfProductionPlanCalculation.Calculating);
	
	If Not CalculationIsCompleted Then
		Record = Set.Add();
		Record.State = Enums.StatesOfProductionPlanCalculation.Calculating;
		Record.ProductionPlan = ProductionPlan;
	EndIf;
	
	Set.DataExchange.Load = True;
	
	SetPrivilegedMode(True);
	Set.Write(True);
	SetPrivilegedMode(False);
	
	Return CurrentSessionDate();
	
EndFunction

Function ThisIsVirtualJob(Job)
	
	Return (Job.State = Enums.StatesOfProductionPlanCalculation.ClearUnusedDataIsRequired); // the task is not written to the database
	
EndFunction

#EndRegion

#EndIf
