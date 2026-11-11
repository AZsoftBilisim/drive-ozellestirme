#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Records the results of production schedule planning in a register.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - the planned order.
//  ScheduleStatus - Number - status of the production schedule.
//  LoadingVRC	- ValueTable - Data to write to the register.
//
Procedure RecordPlanningResults(ReferenceOrder, ScheduleStatus, LoadingVRC) Export
	
	BeginTransaction();
	
	Try
		
		Set = InformationRegisters.CreatingScheduleForWorkCenterTypes.CreateRecordSet();
		
		Set.Filter.ReferenceOrder.Set(ReferenceOrder);
		Set.Filter.ScheduleStatus.Set(ScheduleStatus);
		
		For Each String In LoadingVRC Do
			
			Record = Set.Add();
			FillPropertyValues(Record, String);
			Record.ReferenceOrder = ReferenceOrder;
			Record.ScheduleStatus = ScheduleStatus;
			
		EndDo;
		
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		EventName = NStr("vi = 'Ghi lại kết quả lập kế hoạch loại khối lượng công việc của xưởng';
						|ru = 'Запись результатов планирования загрузки видов рабочих центров';
						|en = 'Save results of planning load for work center types'; fa = 'Save results of planning load for work center types';
						|it = 'Registrare i risultati della pianificazione dei tipi di carico di lavoro dei centri di lavoro';
						|pl = 'Zapis wyników planowania pobrania stanowisk pracy';
						|tr = 'İş merkezi türlerinin çalışma yüklerini planlama sonuçlarının kaydı'", CommonClientServer.DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
  		Raise;
		
	EndTry;
	
EndProcedure

// Converts chart data from the preliminary status to the working status.
// Along with recording the work schedule, data from the preliminary schedule and model is cleared.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order to record the data for.
//  Stages - Array - production stages that need to be recorded.
//
Procedure WritePreliminaryScheduleToWorkingOne(ReferenceOrder, Stages) Export
	
	Query = New Query(
	"SELECT
	|	CreatingScheduleForWorkCenterTypes.Stage,
	|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
	|	CreatingScheduleForWorkCenterTypes.IntervalDate,
	|	CreatingScheduleForWorkCenterTypes.Busy
	|FROM
	|	InformationRegister.CreatingScheduleForWorkCenterTypes AS CreatingScheduleForWorkCenterTypes
	|WHERE
	|	CreatingScheduleForWorkCenterTypes.ReferenceOrder = &ReferenceOrder
	|	AND CreatingScheduleForWorkCenterTypes.ScheduleStatus = &StatusPreliminarySchedule");
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("StatusPreliminarySchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule());
	
	ProductionSchedule = Query.Execute().Unload();
	
	AccumulationRegisters.AvailabilityOfWorkCenterTypes.RecordBusyProductionSchedule(
		Stages,
		ProductionSchedule);
	
	ClearPreliminarySchedule(ReferenceOrder);
	
EndProcedure

// Clears the schedule of the specified order.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order to clear the schedule for.
//
Procedure ClearPreliminarySchedule(ReferenceOrder) Export
	
	BeginTransaction();
	
	Try
		
		Set = InformationRegisters.CreatingScheduleForWorkCenterTypes.CreateRecordSet();
		Set.Filter.ReferenceOrder.Set(ReferenceOrder);
		Set.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		EventName = NStr("vi = 'Xóa lịch trình sơ bộ';
						|ru = 'Очистка предварительного графика';
						|en = 'Clear preliminary schedule'; fa = 'Clear preliminary schedule';
						|it = 'Cancellazione del piano preliminare';
						|pl = 'Czyszczenie wstępnego harmonogramu';
						|tr = 'Ön programın temizlenmesi'", CommonClientServer.DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
  		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndIf