///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Calculates totals of all accounting registers and accumulations for which they are enabled.
Procedure CalculateTotals() Export
	
	SessionDate = CurrentSessionDate();
	AccumulationRegisterPeriod  = EndOfMonth(AddMonth(SessionDate, -1)); // End of the last month.
	AccountingRegisterPeriod = EndOfMonth(SessionDate); // End of the current month.
	
	ShouldSetMinPeriod = False;
	AccumulationRegistersCalculatedTotalsMinPeriod = Date(1,1,1);
	AccountingRegistersCalculatedTotalsMinPeriod = Date(1,1,1);
	
	MonthsCountInCalculatedTotalsMinPeriod =
		Constants.MonthsCountInCalculatedTotalsMinPeriod.Get();
	If ValueIsFilled(MonthsCountInCalculatedTotalsMinPeriod) Then
		ShouldSetMinPeriod = True;
		
		AccumulationRegistersCalculatedTotalsMinPeriod =
			BegOfMonth(AddMonth(SessionDate, -(MonthsCountInCalculatedTotalsMinPeriod - 1)));
		AccountingRegistersCalculatedTotalsMinPeriod =
			BegOfMonth(AddMonth(SessionDate, -(MonthsCountInCalculatedTotalsMinPeriod - 2)));
	EndIf;
	
	Cache = SplitCheckCache();
	
	// Totals calculation for accumulation registers.
	KindBalance = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> KindBalance Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name]; // AccumulationRegisterManager
		CalculatedTotalsMaxPeriod = AccumulationRegisterManager.GetMaxTotalsPeriod();
		CalculatedTotalsMinPeriod = AccumulationRegisterManager.GetMinTotalsPeriod();
		If CalculatedTotalsMaxPeriod >= AccumulationRegisterPeriod
			And (Not ShouldSetMinPeriod 
				Or CalculatedTotalsMinPeriod = AccumulationRegistersCalculatedTotalsMinPeriod)Then
			Continue;
		EndIf;
		If CalculatedTotalsMaxPeriod < AccumulationRegisterPeriod
			And (ShouldSetMinPeriod
				And CalculatedTotalsMinPeriod <> AccumulationRegistersCalculatedTotalsMinPeriod) Then
				AccumulationRegisterManager.SetMinAndMaxTotalsPeriods(
					AccumulationRegistersCalculatedTotalsMinPeriod, AccumulationRegisterPeriod);
		ElsIf CalculatedTotalsMaxPeriod < AccumulationRegisterPeriod Then
			AccumulationRegisterManager.SetMaxTotalsPeriod(AccumulationRegisterPeriod);
		ElsIf ShouldSetMinPeriod
			And CalculatedTotalsMinPeriod <> AccumulationRegistersCalculatedTotalsMinPeriod Then
			AccumulationRegisterManager.SetMinTotalsPeriod(AccumulationRegistersCalculatedTotalsMinPeriod);
		EndIf;
		If Not AccumulationRegisterManager.GetTotalsUsing()
			Or Not AccumulationRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccumulationRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// Totals calculation for accounting registers.
	For Each MetadataRegister In Metadata.AccountingRegisters Do
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccountingRegisterManager = AccountingRegisters[MetadataRegister.Name]; // AccountingRegisterManager
		CalculatedTotalsMaxPeriod = AccountingRegisterManager.GetTotalsPeriod();
		CalculatedTotalsMinPeriod = AccountingRegisterManager.GetMinTotalsPeriod();
		If CalculatedTotalsMaxPeriod >= AccountingRegisterPeriod
			And (Not ShouldSetMinPeriod 
				Or CalculatedTotalsMinPeriod = AccountingRegistersCalculatedTotalsMinPeriod) Then
			Continue;
		EndIf;
		If CalculatedTotalsMaxPeriod < AccountingRegisterPeriod
			And (ShouldSetMinPeriod
				And CalculatedTotalsMinPeriod <> AccountingRegistersCalculatedTotalsMinPeriod) Then
				AccountingRegisterManager.SetMinAndMaxTotalsPeriods(
					AccountingRegistersCalculatedTotalsMinPeriod, AccountingRegisterPeriod);
		ElsIf CalculatedTotalsMaxPeriod < AccountingRegisterPeriod Then
			AccountingRegisterManager.SetMaxTotalsPeriod(AccountingRegisterPeriod);
		ElsIf ShouldSetMinPeriod
			And CalculatedTotalsMinPeriod <> AccountingRegistersCalculatedTotalsMinPeriod Then
			AccountingRegisterManager.SetMinTotalsPeriod(AccountingRegistersCalculatedTotalsMinPeriod);
		EndIf;
		If Not AccountingRegisterManager.GetTotalsUsing()
			Or Not AccountingRegisterManager.GetPresentTotalsUsing() Then
			Continue;
		EndIf;
		AccountingRegisterManager.RecalcPresentTotals();
	EndDo;
	
	// Register data.
	If LocalFileOperationMode() Then
		TotalsParameters = TotalsAndAggregatesParameters();
		TotalsParameters.TotalsCalculationDate = BegOfMonth(SessionDate);
		WriteTotalsAndAggregatesParameters(TotalsParameters);
	EndIf;
EndProcedure

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Version              = "2.4.1.1";
	Handler.Procedure           = "TotalsAndAggregatesManagementInternal.UpdateScheduledJobUsage";
	Handler.ExecutionMode     = "Seamless";
	Handler.Id       = New UUID("16ec32f9-d68f-4283-9e6f-924a8655d2e4");
	Handler.Comment         = NStr("vi = 'Bật hoặc tắt sử dụng cập nhật và tái tạo phần thống kê theo lịch biểu.';
									|ru = 'Включает или отключает обновление и перестроение агрегатов по расписанию.';
									|en = 'Toggles the update and rebuild schedule for aggregates.'; fa = 'Toggles the update and rebuild schedule for aggregates.';
									|it = 'Включает или отключает обновление и перестроение агрегатов по расписанию.';
									|pl = 'Toggles the update and rebuild schedule for aggregates.';
									|tr = 'Toplamaların planlanmış güncellenmesini ve yeniden oluşturulmasını etkinleştirir veya devre dışı bırakır.'");
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	If Not LocalFileOperationMode() Then
		Return;
	EndIf;
	
	// Run the operations after all update handlers are completed.
	// (They might change the states (usage) of totals and aggregates.)
	
	GenerateTotalsAndAggregatesParameters();
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.UpdateAggregates.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.RebuildAggregates.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.TotalsPeriodSetup.Name);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	If Not LocalFileOperationMode() Then
		Return;
	EndIf;
	
	ProcessMetadata = Metadata.DataProcessors.ShiftTotalsBoundary;
	If Not AccessRight("Use", ProcessMetadata) Then
		Return;
	EndIf;
	
	ProcessFullName = ProcessMetadata.FullName();
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	Sections = ModuleToDoListServer.SectionsForObject(ProcessFullName);
	
	Prototype = New Structure("HasToDoItems, Important, Form, Presentation, ToolTip");
	Prototype.HasToDoItems = MustMoveTotalsBorder();
	Prototype.Important   = True;
	Prototype.Form    = ProcessFullName + ".Form";
	Prototype.Presentation = NStr("vi = 'Tối ưu hóa công việc của ứng dụng';
									|ru = 'Оптимизировать работу приложения';
									|en = 'Optimize performance'; fa = 'Optimize performance';
									|it = 'Оптимизировать работу приложения';
									|pl = 'Optimize performance';
									|tr = 'Uygulamayı etkinleştir.'");
	Prototype.ToolTip     = NStr("vi = 'Đẩy nhanh quá trình kết chuyển chứng từ và lập báo cáo.
		|Thủ tục bắt buộc hàng tháng có thể mất nhiều thời gian.';
		|ru = 'Ускорить проведение документов и формирование отчетов.
		|Обязательная ежемесячная процедура, может занять некоторое время.';
		|en = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while. '; fa = 'Speed up document posting and report generation.
		|Required monthly procedure, this might take a while. ';
		|it = 'Accelerare la registrazione dei documenti e la generazione dei report.
		|Procedura mensile obbligatoria, può richiedere qualche tempo.';
		|pl = 'Przyspieszyć prowadzenie dokumentów i generowanie raportów.
		|Obowiązkowa miesięczna procedura może zająć trochę czasu.';
		|tr = 'Belgelerin kaydedilmesini ve raporların oluşturulmasını hızlandırın.
		|Zorunlu aylık prosedür biraz zaman alabilir.'");
	
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = StrReplace(Prototype.Form, ".", "") + StrReplace(Section.FullName(), ".", "");
		ToDoItem.Owner       = Section;
		FillPropertyValues(ToDoItem, Prototype);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ScheduledJobsExecution

// TotalsPeriodSetup scheduled job handler.
Procedure TotalsPeriodSetupJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup);
	
	CalculateTotals();
	
EndProcedure

// UpdateAggregates scheduled job handler.
Procedure UpdateAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdateAggregates);
	
	UpdateAggregates();
	
EndProcedure

// RebuildAggregates scheduled job handler.
Procedure RebuildAggregatesJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.RebuildAggregates);
	
	RebuildAggregates();
	
EndProcedure

// For internal use.
Procedure UpdateAggregates()
	
	Cache = SplitCheckCache();
	
	// Aggregates update for turnover accumulation registers.
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// Update aggregates.
		AccumulationRegisterManager.UpdateAggregates();
	EndDo;
EndProcedure

// For internal use.
Procedure RebuildAggregates()
	
	Cache = SplitCheckCache();
	
	// Aggregates rebuild for turnover accumulation registers.
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		// Rebuild aggregates.
		AccumulationRegisterManager.RebuildAggregatesUsing();
	EndDo;
EndProcedure

#EndRegion

#Region ForOperatingInFileMode

// Returns True if the infobase operates in the file mode and split is disabled.
Function LocalFileOperationMode()
	Return Common.FileInfobase() And Not Common.DataSeparationEnabled();
EndFunction

// Checks whether totals and aggregates are actual. Returns True if there are no registers.
Function MustMoveTotalsBorder() Export
	Parameters = TotalsAndAggregatesParameters();
	Return Parameters.HasTotalsRegisters And AddMonth(Parameters.TotalsCalculationDate, 2) < CurrentSessionDate();
EndFunction

// Gets a value of the TotalsAndAggregatesParameters constant.
Function TotalsAndAggregatesParameters()
	SetPrivilegedMode(True);
	Parameters = Constants.TotalsAndAggregatesParameters.Get().Get();
	If TypeOf(Parameters) <> Type("Structure") Or Not Parameters.Property("HasTotalsRegisters") Then
		Parameters = GenerateTotalsAndAggregatesParameters();
	EndIf;
	Return Parameters;
EndFunction

// Overwrites the TotalsAndAggregatesParameters constant.
Function GenerateTotalsAndAggregatesParameters()
	Parameters = New Structure;
	Parameters.Insert("HasTotalsRegisters", False);
	Parameters.Insert("TotalsCalculationDate",  '39991231235959'); // 12/1/3999 11:59:59 PM, the maximum date.
	
	KindBalance = Metadata.ObjectProperties.AccumulationRegisterType.Balance;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType = KindBalance Then
			AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name]; // AccumulationRegisterManager
			Date = AccumulationRegisterManager.GetMaxTotalsPeriod() + 1;
			Parameters.HasTotalsRegisters = True;
			Parameters.TotalsCalculationDate  = Min(Parameters.TotalsCalculationDate, Date);
		EndIf;
	EndDo;
	
	If Not Parameters.HasTotalsRegisters Then
		Parameters.Insert("TotalsCalculationDate", '00010101');
	EndIf;
	
	WriteTotalsAndAggregatesParameters(Parameters);
	
	Return Parameters;
EndFunction

// Writes a value of the TotalsAndAggregatesParameters constant.
Procedure WriteTotalsAndAggregatesParameters(Parameters) Export
	Constants.TotalsAndAggregatesParameters.Set(New ValueStorage(Parameters));
EndProcedure

#EndRegion

#Region InfobaseUpdate

// [2.3.4.7] Updates usage of UpdateAggregates and RebuildAggregates scheduled jobs.
Procedure UpdateScheduledJobUsage() Export
	// UpdateAggregates and RebuildAggregates scheduled jobs.
	HasRegistersWithAggregates = HasRegistersWithAggregates();
	UpdateScheduledJob(Metadata.ScheduledJobs.UpdateAggregates, HasRegistersWithAggregates);
	UpdateScheduledJob(Metadata.ScheduledJobs.RebuildAggregates, HasRegistersWithAggregates);
	
	// Scheduled job TotalsPeriodSetup.
	UpdateScheduledJob(Metadata.ScheduledJobs.TotalsPeriodSetup, True);
EndProcedure

#EndRegion

#Region Others

// Secondary for UpdateScheduledJobsUsage procedure.
Procedure UpdateScheduledJob(ScheduledJobMetadata, Use)
	FoundItems = ScheduledJobsServer.FindJobs(New Structure("Metadata", ScheduledJobMetadata));
	For Each Job In FoundItems Do
		Changes = New Structure("Use", Use);
		// Change the schedule only if not set and only in on-prem.
		If Not ScheduleFilled(Job.Schedule)
			And Not Common.DataSeparationEnabled() Then
			Changes.Insert("Schedule", DefaultSchedule(ScheduledJobMetadata));
		EndIf;
		ScheduledJobsServer.ChangeJob(Job, Changes);
	EndDo;
EndProcedure

// Defines whether the job schedule is set.
//
// Parameters:
//   Schedule - JobSchedule - scheduled job schedule.
//
// Returns:
//   Boolean - True if the job schedule is set.
//
Function ScheduleFilled(Schedule)
	Return Schedule <> Undefined
		And String(Schedule) <> String(New JobSchedule);
EndFunction

// Returns the default job schedule.
//   The function is used instead of MetadataObject: ScheduledJob.Schedule property
//   as its value is always set to Undefined.
//
Function DefaultSchedule(ScheduledJobMetadata)
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 1;
	If ScheduledJobMetadata = Metadata.ScheduledJobs.UpdateAggregates Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 01, 00, 00));
		AddDetailedSchedule(Schedule, "BeginTime", Date(1, 1, 1, 14, 00, 00));
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.RebuildAggregates Then
		Schedule.BeginTime = Date(1, 1, 1, 03, 00, 00);
		SetWeekDays(Schedule, "6");
	ElsIf ScheduledJobMetadata = Metadata.ScheduledJobs.TotalsPeriodSetup Then
		Schedule.BeginTime = Date(1, 1, 1, 01, 00, 00);
		Schedule.DayInMonth = 5;
	Else
		Return Undefined;
	EndIf;
	Return Schedule;
EndFunction

// Secondary for the DefaultSchedule function.
Procedure AddDetailedSchedule(Schedule, Var_Key, Value)
	DetailedSchedule = New JobSchedule;
	FillPropertyValues(DetailedSchedule, New Structure(Var_Key, Value));
	Array = Schedule.DetailedDailySchedules;
	Array.Add(DetailedSchedule);
	Schedule.DetailedDailySchedules = Array;
EndProcedure

// Secondary for the DefaultSchedule function.
Procedure SetWeekDays(Schedule, WeekDaysInRow)
	WeekDays = New Array;
	RowsArray = StrSplit(WeekDaysInRow, ",", False);
	For Each WeekDayNumberRow In RowsArray Do
		WeekDays.Add(Number(TrimAll(WeekDayNumberRow)));
	EndDo;
	Schedule.WeekDays = WeekDays;
EndProcedure

Function SplitCheckCache()
	Cache = New Structure;
	Cache.Insert("SaaSModel", Common.DataSeparationEnabled());
	If Cache.SaaSModel Then
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			MainDataSeparator = ModuleSaaSOperations.MainDataSeparator();
			AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
		Else
			MainDataSeparator = Undefined;
			AuxiliaryDataSeparator = Undefined;
		EndIf;
		
		Cache.Insert("InDataArea",                   Common.SeparatedDataUsageAvailable());
		Cache.Insert("MainDataSeparator",        MainDataSeparator);
		Cache.Insert("AuxiliaryDataSeparator", AuxiliaryDataSeparator);
	EndIf;
	Return Cache;
EndFunction

Function MetadataObjectAvailableOnSplit(Cache, MetadataObject)
	If Not Cache.SaaSModel Then
		Return True;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
	Else
		IsSeparatedMetadataObject = False;
	EndIf;
	
	Return Cache.InDataArea = IsSeparatedMetadataObject;
EndFunction

Function HasRegistersWithAggregates()
	Cache = SplitCheckCache();
	TurnoversKind = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers;
	For Each MetadataRegister In Metadata.AccumulationRegisters Do
		If MetadataRegister.RegisterType <> TurnoversKind Then
			Continue;
		EndIf;
		If Not MetadataObjectAvailableOnSplit(Cache, MetadataRegister) Then
			Continue;
		EndIf;
		AccumulationRegisterManager = AccumulationRegisters[MetadataRegister.Name];
		If Not AccumulationRegisterManager.GetAggregatesMode()
			Or Not AccumulationRegisterManager.GetAggregatesUsing() Then
			Continue;
		EndIf;
		Return True;
	EndDo;
	
	Return False;
EndFunction

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateScheduledJobUsage");
	
EndProcedure

#EndRegion