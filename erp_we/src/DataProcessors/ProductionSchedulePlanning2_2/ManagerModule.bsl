#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region SchedulePlanning

// Plans the model and / or preliminary production schedule for a single order.
//
// Parameters:
//  Settings - Structure - schedule calculation settings. For the composition of the keys
//		, see the function -constructor of the setingplanning Setinggraphics.
//  StorageAddress - String - address of the storage where the planning result will be placed.
//
Procedure PlanPreliminarySchedule(Settings, StorageAddress) Export
	
	FileSystem_ = Common.FileInfobase();
	PlanningInBackground = Not FileSystem_
		And Settings.PlanSchedule
		And Settings.PlanModel;
	
	NumberOfJobForCalculatingProductionSchedule = FixTaskNumberForCalculatingProductionSchedule();
	
	If PlanningInBackground Then
		
		JobMethodName = "ProductionManagement.PlanAndRecordScheduleInBackground";
		JobDescription = NStr("vi = 'Lập kế hoạch sản xuất';
								|ru = 'Планирование графика производства';
								|en = 'Production schedule creating'; fa = 'Production schedule creating';
								|it = 'Programmazione del piano di produzione';
								|pl = 'Planowanie harmonogramu produkcji';
								|tr = 'Üretim programını planlama'");
		ResultAddresses = New Array;
		
		For Cnt = 1 To 2 Do
			
			If Cnt = 1 Then
				PlanningSettings = PlanningSettingsPreliminarySchedule(
					Settings, NumberOfJobForCalculatingProductionSchedule);
			Else
				PlanningSettings = SchedulingSettingsGraphModel(
					Settings, NumberOfJobForCalculatingProductionSchedule);
			EndIf;
			
			ResultAddress = PutToTempStorage(Undefined);
			ResultAddresses.Add(ResultAddress);
			
			MethodParameters = New Array;
			MethodParameters.Add(PlanningSettings);
			MethodParameters.Add(ResultAddress);
			Job = BackgroundJobs.Execute(JobMethodName, MethodParameters,, JobDescription);
			
		EndDo;
		
		WaitForBackgroundJobsToComplete(JobMethodName, JobDescription);
		
		BackgroundPlanningResults = ResultsOfBackgroundSchedulePlanning(ResultAddresses);
		GraphResults_ = BackgroundPlanningResults.GraphResults_;
		ModelResults = BackgroundPlanningResults.ModelResults;
		
	Else
		
		If Settings.PlanSchedule Then
			PlanningSettings = PlanningSettingsPreliminarySchedule(
				Settings, NumberOfJobForCalculatingProductionSchedule);
			GraphResults_ = PlanAndRecordSchedule(PlanningSettings);
		Else
			GraphResults_ = Undefined;
		EndIf;
		
		If Settings.PlanModel Then
			PlanningSettings = SchedulingSettingsGraphModel(
				Settings, NumberOfJobForCalculatingProductionSchedule);
			ModelResults = PlanAndRecordSchedule(PlanningSettings);
		Else
			ModelResults = Undefined;
		EndIf;
		
	EndIf;
	
	Result = PreliminarySchedulePlanningResults(
		GraphResults_,
		ModelResults,
		NumberOfJobForCalculatingProductionSchedule,
		Settings.CancelManualChangesOfSchedule);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Records the results of the preliminary calculation of the schedule in the current (working) production schedule.
//
// Parameters:
//  Parameters - Structure - contains the following data:
//		* ReferenceOrder - DocumentRef.ProductionOrder2_2 - order, the schedule for which you want to record.
//		* PlacedStages - Array - array of production stages that belong to the order,
//			the schedule of which must be recorded.
//		* NumberOfJobForCalculatingProductionSchedule - Number - the value of the constant of the same name, fixed
//			before planning the schedule.
//		* CancelManualChangesOfSchedule - Boolean - the value of the setting of the same name used during planning.
//  StorageAddress - String - address of the storage where the result of the procedure can be placed.
//
Procedure WritePreliminaryScheduleToWorkingOne(Parameters, StorageAddress) Export
	
	BeginTransaction();
	Try
		
		ReferenceOrder = Parameters.ReferenceOrder;
		Stages = Parameters.PlacedStages;
		NumberOfJobForCalculatingProductionSchedule = Parameters.NumberOfJobForCalculatingProductionSchedule;
		CancelManualChangesOfSchedule = Parameters.CancelManualChangesOfSchedule;
		
		InformationRegisters.ScheduleOfProductionStages2_2.WritePreliminaryScheduleToWorkingOne(
			ReferenceOrder);
		
		InformationRegisters.CreatingScheduleForWorkCenterTypes.WritePreliminaryScheduleToWorkingOne(
			ReferenceOrder,
			Stages);
		
		WhenRecordingWorkSchedule(
			ReferenceOrder,
			Stages,
			NumberOfJobForCalculatingProductionSchedule,
			CancelManualChangesOfSchedule);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Comment = DetailErrorDescription(ErrorInfo());
		LogGraphRecordingError(Comment);
		
		Raise;
		
	EndTry;
	
EndProcedure

// Clears the results of pre-planning the production schedule.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - an order whose preliminary schedule needs to be cleared.
//  StorageAddress - String - address of the storage where the result of the procedure can be placed.
//
Procedure ClearPreliminarySchedule(ReferenceOrder, StorageAddress) Export
	
	BeginTransaction();
	Try
		
		InformationRegisters.ScheduleOfProductionStages2_2.ClearPreliminarySchedule(ReferenceOrder);
		InformationRegisters.CreatingScheduleForWorkCenterTypes.ClearPreliminarySchedule(ReferenceOrder);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
 		
		EventName = NStr("vi = 'Lịch biểu sản xuất';
						|ru = 'График производства';
						|en = 'Production schedule'; fa = 'برنامه زمان‌بندی تولید';
						|it = 'Piano di produzione';
						|pl = 'Harmonogram produkcji';
						|tr = 'Üretim programı'", CommonClientServer.DefaultLanguageCode())
			+ "."
			+ NStr("vi = 'Xóa bỏ';
					|ru = 'Очистка';
					|en = 'Cleanup'; fa = 'پاک‌سازی';
					|it = 'Cancellazione';
					|pl = 'Oczyszczenie';
					|tr = 'Temizleme'", CommonClientServer.DefaultLanguageCode());
		Level = EventLogLevel.Error;
		Comment = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventName, Level,,, Comment);
		
		Raise;
		
	EndTry;
	
EndProcedure

// A list of interactive settings that can be edited in the Layout setingsposition form.
// 
// Returns:
//  Structure - available calculation settings.
//
Function PreScheduleSchedulingSettings() Export
	
	Result = New Structure;
	
	Result.Insert("ProductionOrder");
	Result.Insert("DynamicStructure");
	
	Result.Insert("PlanSchedule", False);
	Result.Insert("ActivateTheAvailabilityReserveSchedule", False);
	
	Result.Insert("PlanModel", False);
	Result.Insert("ActivateTheAvailabilityReserveModel", False);
	
	Result.Insert("AllMaterialsInStock", False);
	Result.Insert("UnlimitedEquipmentFleet", False);
	Result.Insert("RoundTheClockWorkSevenDaysAWeek", False);
	Result.Insert("NoOtherOrders", False);
	
	Result.Insert("FullReplanning", False);
	Result.Insert("CancelManualChangesOfSchedule", False);
	
	Return Result;
	
EndFunction

// Determines whether you have access to schedule production scheduling
// 
// Returns:
//   - Boolean - True, if there is an access right.
//
Function PlanningIsAvailable() Export
	
	Result = False;
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
		
		Result = AccessRight("Use", Metadata.DataProcessors.ProductionSchedulePlanning2_2);
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ErrorCodesConstants

// Returns the schedule planning error code: insufficient available time.
// 
// Returns:
//  Number - error code.
//
Function ErrorCodeVRCAvailability() Export
	
	Return 1;
	
EndFunction

// Returns the error code of the planning graph: the division's work schedule is missing.
// 
// Returns:
//  Number - error code.
//
Function ErrorCodeDivisionSchedule() Export
	
	Return 2;
	
EndFunction

// Returns the error code of the planning graph: there is no business schedule.
// 
// Returns:
//  Number - error code.
//
Function ErrorCodeBusinessHours() Export
	
	Return 5;
	
EndFunction

// Returns the error code of the planning graph: there is no schedule for the predecessor stage.
// 
// Returns:
//  Number - error code.
//
Function ErrorCodeMissingPredecessorGraph() Export
	
	Return 3;
	
EndFunction

// Returns the error code of the planning graph: looping connections steps.
// 
// Returns:
//  Number - error code.
//
Function ErrorCodeThereAreCyclesInChainOfStages() Export
	
	Return 4;
	
EndFunction

#EndRegion

#Region AvailabilityOfPerformers

// Puts a temporary table in the Manager that contains data about the available time of work centers.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager - the Manager where
//		the generated temporary table will be placed.
//  TempTableName		 - String - name of the temporary table.
//  VRCArray				 - Array - an array that supports the types of working cements that need to be accessed.
//  ArrayOfStages			 - Array - stages of this order that do not reduce the availability of types of work centers.
//		Accordingly, other stages of this order will reduce the availability of types of work centers. For example, when calculating
//		the order schedule, you should pass all the stages whose schedule will be recalculated, since they should not take up time.
//  Begin					 - Date - start of the data sampling interval.
//  Ending				 - Date - end of the data sampling interval.
//  Parameters				 - Structure - other data sampling parameters:
//		* ProductionOrder - DocumentRef.ProductionOrder2_2 - planned production order.
//		* GoBackToBeginning - Boolean - the direction of placement of issue.
//		* NoOtherOrders - Boolean - setting up planning.
//		* CancelManualChangesOfSchedule - Boolean - setting up planning.
//		* KeyLot - UUID - optional parameter.
//
Procedure CreateTTAvailabilityOfRCTypes(TempTablesManager, TempTableName, VRCArray, ArrayOfStages, Begin, Ending, Parameters) Export
	
	ReferenceOrder = Parameters.ProductionOrder;
	Backward = Parameters.GoBackToBeginning;
	NoOtherOrders = Parameters.NoOtherOrders;
	CancelManualChangesOfSchedule = Parameters.CancelManualChangesOfSchedule;
	RoundTheClockWorkSevenDaysAWeek = Parameters.RoundTheClockWorkSevenDaysAWeek;
	
	Query = New Query;
	Query.SetParameter("VRCArray", VRCArray);
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ArrayOfStages", ArrayOfStages);
	Query.SetParameter("Backward", Backward);
	Query.SetParameter("NoOtherOrders", NoOtherOrders);
	Query.SetParameter("CancelManualChangesOfSchedule", CancelManualChangesOfSchedule);
	Query.SetParameter("RoundTheClockWorkSevenDaysAWeek", RoundTheClockWorkSevenDaysAWeek);
	Query.SetParameter("BegOfHour", BegOfHour(Begin));
	Query.SetParameter("BegOfDay", BegOfDay(Begin));
	Query.SetParameter("BegOfWeek", BegOfWeek(Begin));
	Query.SetParameter("BegOfMonth", BegOfMonth(Begin));
	Query.SetParameter("EndOfHour", EndOfHour(Ending));
	Query.SetParameter("EndDay", EndOfDay(Ending));
	Query.SetParameter("EndingOfWeek", EndOfWeek(Ending));
	Query.SetParameter("EndOfMonth_", EndOfMonth(Ending));
	
	If Parameters.Property("KeyLot") Then
		Query.SetParameter("KeyLot", Parameters.KeyLot);
	Else
		Query.SetParameter("KeyLot", New UUID());
	EndIf;
	
	Query.TempTablesManager = TempTablesManager;
	
	QueryText = 
	"SELECT
	|	TypesOfRC.Ref AS Performer,
	|	TypesOfRC.Department AS Department,
	|	TypesOfRC.Department.PlanningInterval AS PlanningInterval,
	|	TypesOfRC.Calendar AS Calendar,
	|	TypesOfRC.AvailabilityReserve AS AvailabilityReserve,
	|	CASE TypesOfRC.Department.PlanningInterval
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|			THEN &BegOfHour
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN &BegOfDay
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN &BegOfDay
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN &BegOfWeek
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|			THEN &BegOfMonth
	|	END AS Begin,
	|	CASE TypesOfRC.Department.PlanningInterval
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|			THEN &EndOfHour
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN &EndDay
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN &EndDay
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN &EndingOfWeek
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|			THEN &EndOfMonth_
	|	END AS Ending
	|INTO TTTypesOfRC
	|FROM
	|	Catalog.WorkCenterTypes AS TypesOfRC
	|WHERE
	|	TypesOfRC.Ref IN(&VRCArray)
	|	AND TypesOfRC.UseAvailabilityAccordingToSchedule
	|
	|INDEX BY
	|	Performer,
	|	Begin,
	|	Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TypesOfRC.Performer AS Performer,
	|	CASE
	|		WHEN TypesOfRC.Calendar <> VALUE(Catalog.Calendars.EmptyRef)
	|			THEN TypesOfRC.Calendar
	|		ELSE ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value)
	|	END AS WorkScheduleCalendar
	|INTO TTWorkSchedules_
	|FROM
	|	TTTypesOfRC AS TypesOfRC
	|
	|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
	|		ON TypesOfRC.Department = Schedules.Ref
	|			AND TypesOfRC.Calendar = VALUE(Catalog.Calendars.EmptyRef)
	|
	|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
	|		ON (TRUE)
	|WHERE
	|	TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|	AND NOT &RoundTheClockWorkSevenDaysAWeek
	|
	|INDEX BY
	|	WorkScheduleCalendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	WorkSchedules.WorkScheduleCalendar AS WorkScheduleCalendar
	|FROM
	|	TTWorkSchedules_ AS WorkSchedules";
	Query.Text = QueryText;
	
	Schedules = Query.Execute().Unload().UnloadColumn("WorkScheduleCalendar");
	
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager, Schedules, BegOfDay(Begin), Ending, False);
	
	Documents.ProductionOrder2_2.CreateTTOrdersWithHighPriority(
		TempTablesManager,
		"TTPriorityOrders_",
		ReferenceOrder);
	
	QueryText = 
	"SELECT
	|	WorkSchedules.Performer AS Performer,
	|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
	|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
	|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS IntervalDate,
	|	MAX(
	|		CASE
	|			WHEN Schedule.EndTime IS NULL 
	|				OR Schedule.EndTime = DATETIME(1, 1, 1)
	|				THEN DATEADD(Schedule.ScheduleDate, DAY, 1)
	|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
	|				HOUR(Schedule.EndTime)*60 + MINUTE(Schedule.EndTime))
	|		END) AS EndOfTheInterval
	|INTO TTShiftBoundaries
	|FROM
	|	TTWorkSchedules_ AS WorkSchedules
	|		INNER JOIN TTWorkSchedules AS Schedule
	|		ON WorkSchedules.WorkScheduleCalendar = Schedule.WorkScheduleCalendar
	|WHERE
	|	Schedule.Period >= &BegOfDay
	|
	|GROUP BY
	|	WorkSchedules.Performer,
	|	WorkSchedules.WorkScheduleCalendar,
	|	Schedule.Period
	|
	|INDEX BY
	|	Performer,
	|	IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Enabled.WorkCenterType AS Performer,
	|	CASE
	|		WHEN &RoundTheClockWorkSevenDaysAWeek
	|			AND TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN BEGINOFPERIOD(Enabled.IntervalDate, DAY)
	|		ELSE Enabled.IntervalDate
	|	END AS IntervalDate,
	|	CASE
	|		WHEN NOT &RoundTheClockWorkSevenDaysAWeek
	|			AND TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN ISNULL(ShiftBoundaries.EndOfTheInterval, ENDOFPERIOD(Enabled.IntervalDate, DAY))
	|		ELSE DATETIME(1,1,1,1,1,1)
	|	END AS EndOfTheInterval,
	|	SUM(CASE
	|			WHEN NOT Enabled.IsRecordOfWorkCentersCapacityChange
	|				THEN 0
	|			WHEN Enabled.WorkCenterType.EnterAvailabilityForWorkCenterType
	|				THEN Enabled.WorkCenterTypeSchedule
	|			ELSE Enabled.WorkCenterSchedule
	|		END) AS CountReceipt,
	|	SUM(CASE
	|			WHEN Enabled.IsRecordOfWorkCentersCapacityChange
	|				THEN 0
	|			ELSE Enabled.Busy
	|		END) AS CountExpense,
	|	MAX(CASE
	|				WHEN &RoundTheClockWorkSevenDaysAWeek
	|					AND TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|					THEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|				ELSE TypesOfRC.PlanningInterval
	|			END) AS PlanningInterval,
	|	MAX(TypesOfRC.AvailabilityReserve) AS AvailabilityReserve
	|INTO ttResult
	|FROM
	|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
	|		INNER JOIN TTTypesOfRC AS TypesOfRC
	|		ON (TypesOfRC.Performer = Enabled.WorkCenterType)
	|			AND Enabled.IntervalDate >= TypesOfRC.Begin
	|			AND (Enabled.IntervalDate <= TypesOfRC.Ending
	|				OR &Backward)
	|
	|		LEFT JOIN TTPriorityOrders_ AS PriorityOrders2_2
	|		ON Enabled.ReferenceOrder = PriorityOrders2_2.Ref
	|
	|		LEFT JOIN TTShiftBoundaries AS ShiftBoundaries
	|		ON Enabled.WorkCenterType = ShiftBoundaries.Performer
	|			AND Enabled.IntervalDate = ShiftBoundaries.IntervalDate
	|
	|WHERE
	|	(Enabled.IsRecordOfWorkCentersCapacityChange
	|			OR NOT Enabled.IsRecordOfWorkCentersCapacityChange
	|				AND PriorityOrders2_2.Ref IS NOT NULL
	|			OR NOT Enabled.IsRecordOfWorkCentersCapacityChange
	|				AND Enabled.Recorder REFS Document.ProductionStage2_2
	|				AND CAST(Enabled.Recorder AS Document.ProductionStage2_2).Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|			OR NOT Enabled.IsRecordOfWorkCentersCapacityChange
	|				AND Enabled.Recorder REFS Document.ProductionStage2_2
	|				AND CAST(Enabled.Recorder AS Document.ProductionStage2_2).ReferenceOrder = &ReferenceOrder
	|				AND (NOT CAST(Enabled.Recorder AS Document.ProductionStage2_2) IN (&ArrayOfStages)
	|					OR CAST(Enabled.Recorder AS Document.ProductionStage2_2).StagePlacementInProductionSchedule
	|						AND NOT &CancelManualChangesOfSchedule)
	|			OR NOT Enabled.IsRecordOfWorkCentersCapacityChange
	|				AND Enabled.Recorder REFS Document.ProductionScheduleRecorder
	|				AND NOT Enabled.KeyLot = &KeyLot)
	|	AND (Enabled.IsRecordOfWorkCentersCapacityChange
	|			OR NOT &NoOtherOrders)
	|	AND Enabled.Active
	|
	|GROUP BY
	|	Enabled.WorkCenterType,
	|	CASE
	|		WHEN &RoundTheClockWorkSevenDaysAWeek
	|			AND TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN BEGINOFPERIOD(Enabled.IntervalDate, DAY)
	|		ELSE Enabled.IntervalDate
	|	END,
	|	CASE
	|		WHEN NOT &RoundTheClockWorkSevenDaysAWeek
	|			AND TypesOfRC.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN ISNULL(ShiftBoundaries.EndOfTheInterval, ENDOFPERIOD(Enabled.IntervalDate, DAY))
	|		ELSE DATETIME(1,1,1,1,1,1)
	|	END
	|
	|INDEX BY
	|	Performer,
	|	IntervalDate";
	
	QueryText = StrReplace(QueryText, "ttResult", TempTableName);
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other

// Calculates the date when buffers are placed according to the division's work schedule.
//
// Parameters:
//  Department - CatalogRef.BusinessStructure - unit
//		according to the schedule which you want to place buffers.
//  Buffers - Array - contains structures describing the buffers to be placed. Structure keys:
//		* Duration - Number - size of the allocated buffer.
//		* UnitOfMeasure - EnumRef.TimeMeasureUnits - unit of measurement for buffer duration.
//		* Date - Date - the date from which to place the buffer.
//		* DirectPlacement - Boolean - direction of the buffer placement. If True, the buffer is deferred
//			to the future from the start date of placement. Otherwise, the placement is performed in the past,
//			relative to the placement date.
//		* PlacementDate - Date - result of placing the buffer. If the placement failed,
//			the date will be empty.
//
Procedure PlaceBuffers(Department, Buffers) Export
	
	// Initialization of planning parameters
	PlanningParameters = InitializePlanningParameters(
		InitializeSchedulingSettings(1));
	PlanningParameters.RoundTheClockWorkSevenDaysAWeek = False;
	
	// Reading the schedule
	WorkScheduleCalendar = 1;
	
	TempTablesManager = New TempTablesManager;
	ProductionServer.CreateTTDivisionSchedules(
		Department, TempTablesManager, "TTWorkSchedules_");
	
	Query = New Query(
		"SELECT
		|	&WorkScheduleCalendar                AS WorkScheduleCalendar,
		|	TTWorkSchedules_.WorkScheduleCalendar AS WorkScheduleLink
		|FROM
		|	TTWorkSchedules_ AS TTWorkSchedules_");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	Schedules = Query.Execute().Unload();
	
	UbbwSchedule = UbbwSchedule(Schedules, '00010101', '39991231');
	AddIndexesAndServiceFieldsToUBBWSchedule(UbbwSchedule);
	PlanningParameters.UbbwSchedule = UbbwSchedule;
	
	// Placement of buffers
	For Each Buffer In Buffers Do
		
		PlacementDate = '00010101';
		
		If ValueIsFilled(Buffer.Date) And ValueIsFilled(Buffer.Duration) Then
			
			PlacementResults = PlaceAccordingToUBBVSchedule(
				PlanningParameters,
				WorkScheduleCalendar,
				Buffer.DirectPlacement,
				Buffer.Date,
				Buffer.Duration,
				Buffer.UnitOfMeasure);
			
			If PlacementResults.PlacementCompleted Then
				
				If Buffer.DirectPlacement Then
					PlacementDate = PlacementResults.Ending;
				Else
					PlacementDate = PlacementResults.Begin;
				EndIf;
				
			EndIf;
			
		ElsIf ValueIsFilled(Buffer.Date) And Not ValueIsFilled(Buffer.Duration) Then
			
			PlacementDate = Buffer.Date;
			
		EndIf;
		
		Buffer.Insert("PlacementDate", PlacementDate);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Wrapper for preparing settings - order calculation (as part of recalculating the order list).
// 
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2
//  ExternalSettings - Structure
// 
// Returns:
//  Structure
//
Function PlanningSettingsWorkingScheduleOfOrders(ProductionOrder, ExternalSettings = Undefined) Export
	
	PlanningSettings = InitializeSchedulingSettings();
	
	If ExternalSettings <> Undefined Then
		
		ListOfExternalSettings = New Array;
		ListOfExternalSettings.Add("FullReplanning");
		ListOfExternalSettings.Add("CancelManualChangesOfSchedule");
		
		For Each Setting In ListOfExternalSettings Do
			
			If Not ExternalSettings.Property(Setting, PlanningSettings[Setting]) Then
				PlanningSettings[Setting] = False;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PlanningSettings.ProductionOrder = ProductionOrder;
	PlanningSettings.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
	PlanningSettings.AllMaterialsInStock = False;
	PlanningSettings.UnlimitedEquipmentFleet = False;
	PlanningSettings.RoundTheClockWorkSevenDaysAWeek = False;
	PlanningSettings.NoOtherOrders = False;
	
	Return PlanningSettings;
	
EndFunction

// Wrapper for preparing settings - calculation of the list of stages.
// 
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2
//  Stages - Array of DocumentRef.ProductionStage2_2
//  ExternalSettings - Structure
// 
// Returns:
//  Structure
//
Function PlanningSettingsWorkingScheduleOfStages(ProductionOrder, Stages, ExternalSettings) Export
	
	PlanningSettings = InitializeSchedulingSettings();
	
	ListOfExternalSettings = New Array;
	ListOfExternalSettings.Add("CancelManualChangesOfSchedule");
	
	For Each Setting In ListOfExternalSettings Do
		
		If Not ExternalSettings.Property(Setting, PlanningSettings[Setting]) Then
			PlanningSettings[Setting] = False;
		EndIf;
		
	EndDo;
	
	PlanningSettings.ProductionOrder = ProductionOrder;
	PlanningSettings.Stages = Stages;
	PlanningSettings.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
	PlanningSettings.FullReplanning = True;
	
	PlanningSettings.AllMaterialsInStock = False;
	PlanningSettings.UnlimitedEquipmentFleet = False;
	PlanningSettings.RoundTheClockWorkSevenDaysAWeek = False;
	PlanningSettings.NoOtherOrders = False;
	
	Return PlanningSettings;
	
EndFunction

Function PlanAndRecordSchedule(PlanningSettings) Export
	
	KeyOperation = "IntershopManagement2_2.ProductionSchedulePlanning";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	
	SetPrivilegedMode(True);
	PlanningResults = PlanAndRecordScheduleInsideTimeMeasurement(PlanningSettings);
	SetPrivilegedMode(False);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, PlanningResults.DataVolume);
	
	Return PlanningResults;
	
EndFunction

Function NameOfScheduleCalculationTask() Export
	
	Return NStr("vi = 'Планирование графика производства заказа';
				|ru = 'Планирование графика производства заказа';
				|en = 'Production schedule planning for order'; fa = 'Production schedule planning for order';
				|it = 'Планирование графика производства заказа';
				|pl = 'Planowanie harmonogramu produkcji zlecenia';
				|tr = 'Sirariş için üretim programını planlama'");
	
EndFunction

#EndRegion

#Region Private

#Region SchedulePlanning

Function PlanAndRecordScheduleInsideTimeMeasurement(PlanningSettings)
	
	InformationRegisters.JobsForTargetProductionScheduleCalculation.RunJob(
		PlanningSettings.ProductionOrder);
	
	Cancel = False;
	PlanningParameters = PlanningParameters(PlanningSettings, False, Cancel);
	
	If Not Cancel Then
		
		PerformChecksBeforeScheduling(PlanningParameters, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		ProductionManagementOverridable.AfterFillingInPlanningParameters(PlanningParameters);
		PlanScheduleByParameters(PlanningParameters);
		
		If PlanningParameters.ChangePlanningDirection Then
		
			PlanningParameters = PlanningParameters(PlanningSettings, True, Cancel);
			
			If Not Cancel Then
				
				ProductionManagementOverridable.AfterFillingInPlanningParameters(PlanningParameters);
				AddNotificationWhenPlanningDirectionChanges(PlanningParameters);
				PlanScheduleByParameters(PlanningParameters);
				
			EndIf;
			
		EndIf;
		
		If Not Cancel Then
			
			OncePlanningIsComplete(PlanningParameters);
			
			If PlanningParameters.PlanningResults.ScheduleIsPlanned Then
				
				ProductionManagementOverridable.BeforeRecordingPlanningResults(PlanningParameters);
				WriteSchedule(PlanningParameters);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PlanningResults = PlanningParameters.PlanningResults;
	PlanningResults.DataVolume = NumberOfProcessedData(PlanningParameters);
	
	PlanningParameters = Undefined;
	
	Return PlanningResults;
	
EndFunction

Procedure PlanScheduleByParameters(PlanningParameters)
	
	MaxIndex_ = PlanningParameters.Stages.Count()-1;
	For IndexOf = 0 To MaxIndex_ Do
		
		Stage = PlanningParameters.Stages[IndexOf];
		
		If Stage.Allocate Then
			
			PlacementParameters = InitializeStagePlacementParameters(PlanningParameters, Stage);
			
			If Not StageIsPlacedManually(PlanningParameters, Stage) Then
				
				FillInStageSecurityDate(PlanningParameters, Stage, PlacementParameters);
				CalculateMomentOfStagePlacement(PlanningParameters, Stage, PlacementParameters);
				
				If ThisIsUBBVStage(Stage) Then
					FirstStageOfUBBV(PlanningParameters, Stage, PlacementParameters);
				Else
					FirstStageOfBBV(PlanningParameters, Stage, PlacementParameters);
				EndIf;
				
				PlacementParameters = Undefined;
				
				If PlanningParameters.ChangePlanningDirection Then
					Return;
				EndIf;
				
			Else
				
				PlaceStageWithManualPlacement(PlanningParameters, Stage, PlacementParameters);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// 	Stage - ValueTableRow -
// Returns:
// 	Structure - LongDesc:
// * LoadingVRC - ValueTable -:
// ** Stage - DocumentRef.ProductionStage2_2 -
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** IntervalDate - Date -
// ** Busy - Number -
// ** VRCAvailabilityLine - ValueTableRow - Where:
// *** WorkCenterType - CatalogRef.WorkCenterTypes -
// *** IntervalDate - Date -
// *** Enabled - Number -
// *** Busy - Number -
// * PlacementErrorCode - Number -
// * PlanNotEarlierThan - Date -
// * SupplyDate - Date -
// * TimeOfPlacement - Date -
// * ProductionScheduling - EnumRef.WayOfLinkingProductionOperations -
// * EquipmentLimited - Boolean -
// * MaterialLimited - Boolean -
// * ItLimitsProductionDate - Boolean -
// * OnCriticalPath - Boolean -
// * NextStageStart - Date -
// * FollowUpBufferStart - Date -
// * PreliminaryBufferEnd - Date -
// * Ending - Date -
// * Begin - Date -
// * Stage - DocumentRef.ProductionStage2_2 -
Function InitializeStagePlacementParameters(PlanningParameters, Stage)
	
	Result = New Structure;
	
	Attributes = ProductionScheduleDetails();
	For Each Attribute In Attributes Do
		Result.Insert(Attribute.Key, Attribute.Value.AdjustValue());
	EndDo;
	
	Result.Insert("TimeOfPlacement", '00010101');
	Result.Insert("SupplyDate", '00010101');
	Result.Insert("PlanNotEarlierThan", '00010101');
	Result.Insert("PlacementErrorCode", 0);
	
	If Not ThisIsUBBVStage(Stage) Or StageIsPlacedManually(PlanningParameters, Stage) Then
		LoadingVRC = InitializeVRCDownloadAccountingTable();
		LoadingVRC.Columns.Add("VRCAvailabilityLine", New TypeDescription("ValueTableRow"));
		Result.Insert("LoadingVRC", LoadingVRC);
	EndIf;
	
	Result.Stage = Stage.ProductionStage;
	Result.PlanNotEarlierThan = Stage.PlanNotEarlierThan;
	Result.ProductionScheduling = ?(PlanningParameters.GoBackToBeginning,
		Enums.WayOfLinkingProductionOperations.Backward,
		Enums.WayOfLinkingProductionOperations.ToFinish);
	
	Return Result;
	
EndFunction

Procedure FillInStageSecurityDate(PlanningParameters, Stage, PlacementParameters)
	
	If Not PlanningParameters.AllMaterialsInStock
		And PlanningParameters.DatesOfProvision <> Undefined Then
		
		FoundRow = PlanningParameters.DatesOfProvision.Find(Stage.ProductionStage, "ProductionStage");
		
		If Not FoundRow = Undefined Then
			
			PlacementParameters.SupplyDate = FoundRow.SupplyDate;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CalculateMomentOfStagePlacement(PlanningParameters, Stage, PlacementParameters)
	
	If PlanningParameters.GoBackToBeginning Then
		
		// Limitation by previous and launch date.
		TimeOfPlacement = Max(Stage.DateOfPreviousPosts, PlacementParameters.PlanNotEarlierThan, PlanningParameters.EarliestStartDate);
		
		// Current date limit.
		CurrentDate = CurrentSessionDate();
		ThisIsUBBVStage = ThisIsUBBVStage(Stage);
		ShiftToPrior = ThisIsUBBVStage // The zero-duration UBB stages do not "break away" from the previous stages
			And Not ValueIsFilled(Stage.StageDuration)
			And ValueIsFilled(Stage.DateOfPreviousPosts)
			And EndOfDay(Stage.DateOfPreviousPosts) = EndOfDay(CurrentDate);
		
		If TimeOfPlacement < CurrentDate
			And PlacementParameters.SupplyDate < CurrentDate
			And Not ShiftToPrior Then
			
			// Placement must be performed in the current or next interval.
			
			If ThisIsUBBVStage Then
				
				Boundaries = BoundariesOfDayAccordingToSchedule(PlanningParameters, Stage.WorkScheduleCalendar, BegOfDay(CurrentDate));
				If ValueIsFilled(Boundaries.Begin) Then
					
					BegOfDay = Boundaries.Begin;
					If CurrentDate <= BegOfDay Then
						CurDateGiven = BegOfDay(CurrentDate);
					Else
						CurDateGiven = EndOfDay(CurrentDate)+1;
					EndIf;
					
				Else
				
					CurDateGiven = EndOfDay(CurrentDate)+1;
						
				EndIf;
				
			Else
				
				NonStandardBoundaries = SchedulingIntervalHasNonStandardBoundaries(Stage);
				If NonStandardBoundaries Then
					
					EndOfTheInterval = ResultInPlanningIntervalBoundary(
						CurrentDate,
						Stage.PlanningInterval,
						Stage.PlanningIntervalEnd);
					
					If CurrentDate <= EndOfTheInterval Then
						CurDateGiven = LeadToBeginningOfPeriod(CurrentDate, Stage.PlanningInterval);
					Else
						CurDateGiven = LeadToEndOfPeriod(CurrentDate, Stage.PlanningInterval);
					EndIf;
					
				Else
					
					CurDateGiven = LeadToBeginningOfPeriod(CurrentDate, Stage.PlanningInterval);
					
				EndIf;
				
			EndIf;
			
			TimeOfPlacement = CurDateGiven;
			
		Else
			
			// Restriction on the date of provision of materials.
			If ValueIsFilled(PlacementParameters.SupplyDate) 
				And PlacementParameters.SupplyDate > TimeOfPlacement Then
					
				TimeOfPlacement = PlacementParameters.SupplyDate;
				MarkStageBasedOnMaterials(PlacementParameters);
					
			EndIf;
			
		EndIf;
		
	Else
		
		// Limitation by previous and launch date.
		If ValueIsFilled(Stage.DateOfPreviousPosts) Then
			TimeOfPlacement = Stage.DateOfPreviousPosts;
		Else
			TimeOfPlacement = PlanningParameters.DemandDate;
		EndIf;
		
	EndIf;
	
	PlacementParameters.TimeOfPlacement = TimeOfPlacement;
	
EndProcedure

Procedure AddStageToSchedule(PlanningParameters, Stage, PlacementParameters)
	
	Stage.Posted_ = True;
	
	RecordingGraph = PlanningParameters.ProductionSchedule.Add();
	FillPropertyValues(RecordingGraph, PlacementParameters);
	
	If Not ThisIsUBBVStage(Stage) Or StageIsPlacedManually(PlanningParameters, Stage) Then
		AddVrcvGraphUpload(PlanningParameters, PlacementParameters);
	EndIf;
	
	FillInPlacementDateForSubsequentStages(
		PlanningParameters,
		Stage,
		PlacementParameters.Begin,
		PlacementParameters.Ending);
	
EndProcedure

Procedure AddVrcvGraphUpload(PlanningParameters, PlacementParameters)
	
	For Each String In PlacementParameters.LoadingVRC Do
		
		NewRow = PlanningParameters.LoadingVRC.Add();
		FillPropertyValues(NewRow, String);
		
		If ValueIsFilled(String.VRCAvailabilityLine) Then
			
			String.VRCAvailabilityLine.Available = String.VRCAvailabilityLine.Available - String.Busy;
			String.VRCAvailabilityLine.Busy = String.VRCAvailabilityLine.Busy + String.Busy;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInPlacementDateForSubsequentStages(PlanningParameters, ParentStage, BeginningOfParentStage, EndOfParentStage)
	
	SubsequentStages = RelatedStageData(PlanningParameters, ParentStage.ProductionStage, True);
	For Each Stage In SubsequentStages Do
		
		If PlanningParameters.GoBackToBeginning Then
			Stage.DateOfPreviousPosts = Max(Stage.DateOfPreviousPosts, EndOfParentStage);
		Else
			Stage.DateOfPreviousPosts = 
				?(ValueIsFilled(Stage.DateOfPreviousPosts),
					Min(Stage.DateOfPreviousPosts, BeginningOfParentStage),
					BeginningOfParentStage);
		EndIf;
		
	EndDo;
	
EndProcedure

Function RelatedStageData(PlanningParameters, ProductionStage, SubsequentStages = True)
	
	Result = New Array;
	
	RelatedStages = RelatedStages(
		PlanningParameters.StageDependencies,
		ProductionStage,
		PlanningParameters.GoBackToBeginning,
		SubsequentStages);
	
	For Each RelatedStage In RelatedStages Do
		
		Stage = PlanningParameters.Stages.Find(RelatedStage, "ProductionStage");
		If Not Stage = Undefined Then
			Result.Add(Stage);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function RelatedStages(StageDependencies, ProductionStage, GoBackToBeginning, SubsequentStages = True)
	
	Result = New Array;
	
	If (GoBackToBeginning And SubsequentStages)
		Or (Not GoBackToBeginning And Not SubsequentStages) Then
		
		TheStructureOfTheSearch = New Structure("ProductionStage", ProductionStage);
		FoundRows = StageDependencies.FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			Result.Add(String.NextStage);
		EndDo;
		
	Else
		
		TheStructureOfTheSearch = New Structure("NextStage", ProductionStage);
		FoundRows = StageDependencies.FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			Result.Add(String.ProductionStage);
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FixResultsOfStagePlacement(PlanningParameters, Stage, PlacementParameters, Stage2_)
	
	If Stage2_ Then
		
		If Not PlanningParameters.GoBackToBeginning
			And StagePlacementBoundaryViolated(PlanningParameters, Stage, PlacementParameters) Then
			
			PlanningParameters.ChangePlanningDirection = True;
			
		Else
			
			AddStageToSchedule(PlanningParameters, Stage, PlacementParameters);
			
			If Not ThisIsUBBVStage(Stage) Then
				DisplacePrecedingStagesOfUBBV(PlanningParameters, Stage, PlacementParameters.Begin);
			EndIf;
			
		EndIf;
		
	Else
		
		If Not PlanningParameters.GoBackToBeginning Then
			
			PlanningParameters.ChangePlanningDirection = True;
			
		Else
			
			ExcludeSubsequentStepsFromCalculationRecursively(PlanningParameters, Stage);
			FixStagePlacementError(PlanningParameters, Stage, PlacementParameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function StagePlacementBoundaryViolated(PlanningParameters, Stage, PlacementParameters)
	
	SecurityDateViolated = ValueIsFilled(PlacementParameters.SupplyDate)
		And PlacementParameters.Begin < PlacementParameters.SupplyDate;
	
	PrecedenceIsBroken = StageIsPlacedManually(PlanningParameters, Stage)
		And ValueIsFilled(Stage.DateOfPreviousPosts)
		And Stage.DateOfPreviousPosts < PlacementParameters.Ending;
	
	Return SecurityDateViolated
		Or PrecedenceIsBroken
		Or PlacementParameters.Begin < PlacementParameters.PlanNotEarlierThan
		Or PlacementParameters.Begin < CurrentSessionDate();
	
EndFunction

Procedure NoteStageIsLimitedByHardware(PlacementParameters)
	
	PlacementParameters.EquipmentLimited = True;
	
EndProcedure

Procedure MarkStageBasedOnMaterials(PlacementParameters)
	
	PlacementParameters.MaterialLimited = True;
	
EndProcedure

Procedure OncePlanningIsComplete(PlanningParameters)
	
	PlacedStages = ArrayOfPlacedStages(PlanningParameters);
	
	FillInPlanningResults(PlanningParameters, PlacedStages);
	
	If PlanningParameters.PlanningResults.ScheduleIsPlanned Then
		
		FillInInterdependentDetailsOfStagesOfSchedule(PlanningParameters, PlacedStages);
		BringGraphDatesToCustomPresentation(PlanningParameters);
		PlanningParameters.LoadingVRC.GroupBy("Stage,WorkCenterType,IntervalDate,EndOfTheInterval","Busy");
		
	EndIf;
	
EndProcedure

Procedure FillInPlanningResults(PlanningParameters, PlacedStages)
	
	Results = PlanningParameters.PlanningResults;
	
	ScheduleIsPlanned = Not Results.HasErrors
		And PlanningParameters.ProductionSchedule.Count() > 0;
	
	Results.ScheduleIsPlanned = ScheduleIsPlanned;
	Results.ScheduleStatus = PlanningParameters.ScheduleStatus;
	Results.PlacedStages = PlacedStages;
	
EndProcedure

Procedure FillInInterdependentDetailsOfStagesOfSchedule(PlanningParameters, PlacedStages)
	
	TempTablesManager = New TempTablesManager;
	Documents.ProductionStage2_2.CreateTTCommunicationStagesByOrder(
		TempTablesManager,
		PlanningParameters.ProductionOrder,
		True);
	
	CalculateCriticalPath(PlanningParameters, TempTablesManager, PlacedStages);
	CalculateBeginningOfNextSteps(PlanningParameters, TempTablesManager, PlacedStages);
	
EndProcedure

Procedure CalculateCriticalPath(PlanningParameters, TempTablesManager, PlacedStages)
	
	SupplementGraphWithEntriesForCalculatingCriticalPath(PlanningParameters);
	
	ExtremeStages = ExtremeStagesOfCriticalPath(PlanningParameters, TempTablesManager);
	
	Query = New Query(
	"SELECT
	|	TTCommunicationStages.Stage AS ProductionStage,
	|	TTCommunicationStages.NextStage AS NextStage
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStage2_2.Ref
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.ReferenceOrder = &ReferenceOrder
	|	AND ProductionStage2_2.StagePlacementInProductionSchedule
	|	AND (NOT &CancelManualChangesOfSchedule
	|			OR NOT ProductionStage2_2.Ref IN (&PlacedStages))
	|	AND ProductionStage2_2.Posted");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ReferenceOrder", PlanningParameters.ProductionOrder);
	Query.SetParameter("CancelManualChangesOfSchedule",
		PlanningParameters.CancelManualChangesOfSchedule);
	Query.SetParameter("PlacedStages", PlacedStages);
	
	ResultsArray = Query.ExecuteBatch();
	StageDependencies = ResultsArray[0].Unload();
	ManuallyPlacedStages = ResultsArray[1].Unload().UnloadColumn("Ref");
	
	For Each ProductionStage In ExtremeStages Do
		
		MarkStageOnCriticalPathRecursively(
			PlanningParameters, ProductionStage, StageDependencies, ManuallyPlacedStages);
		
	EndDo;
	
EndProcedure

Procedure SupplementGraphWithEntriesForCalculatingCriticalPath(PlanningParameters)
	
	Query = New Query(
	"SELECT
	|	ScheduleOfProductionStages2_2.ProductionOrder AS ProductionOrder,
	|	ScheduleOfProductionStages2_2.Stage AS Stage,
	|	ScheduleOfProductionStages2_2.ScheduleStatus AS ScheduleStatus,
	|	ScheduleOfProductionStages2_2.Begin AS Begin,
	|	DATEADD(ScheduleOfProductionStages2_2.Ending, SECOND, 1) AS Ending,
	|	ScheduleOfProductionStages2_2.PreliminaryBufferEnd AS PreliminaryBufferEnd,
	|	CASE
	|		WHEN ScheduleOfProductionStages2_2.FollowUpBufferStart = ScheduleOfProductionStages2_2.Ending
	|			THEN DATEADD(ScheduleOfProductionStages2_2.FollowUpBufferStart, SECOND, 1)
	|		ELSE ScheduleOfProductionStages2_2.FollowUpBufferStart
	|	END AS FollowUpBufferStart,
	|	ScheduleOfProductionStages2_2.NextStageStart AS NextStageStart,
	|	FALSE AS OnCriticalPath,
	|	FALSE AS ItLimitsProductionDate,
	|	ScheduleOfProductionStages2_2.MaterialLimited AS MaterialLimited,
	|	ScheduleOfProductionStages2_2.EquipmentLimited AS EquipmentLimited,
	|	ScheduleOfProductionStages2_2.ProductionScheduling AS ProductionScheduling
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
	|	AND NOT ScheduleOfProductionStages2_2.Stage IN (&ProductionStages)
	|	AND ScheduleOfProductionStages2_2.Stage.Status IN(&StageStatuses_2)");
	
	Query.SetParameter("ProductionOrder", PlanningParameters.ProductionOrder);
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("ProductionStages", 
		PlanningParameters.ProductionSchedule.UnloadColumn("Stage"));
	Query.SetParameter("StageStatuses_2", StatusesStageCanBeScheduled());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = PlanningParameters.ProductionSchedule.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
EndProcedure

Function ExtremeStagesOfCriticalPath(PlanningParameters, TempTablesManager)
	
	If PlanningParameters.GoBackToBeginning Then
		
		// The extreme right.
		QueryText = 
		"SELECT DISTINCT
		|	Dependencies1.NextStage AS ProductionStage
		|FROM
		|	TTCommunicationStages AS Dependencies1
		|		LEFT JOIN TTCommunicationStages AS Dependencies2
		|		ON Dependencies1.NextStage = Dependencies2.Stage
		|WHERE
		|	Dependencies2.Stage IS NULL";
		
	Else
		
		// The extreme left.
		QueryText = 
		"SELECT DISTINCT
		|	Dependencies1.Stage AS ProductionStage
		|FROM
		|	TTCommunicationStages AS Dependencies1
		|		LEFT JOIN TTCommunicationStages AS Dependencies2
		|		ON Dependencies1.Stage = Dependencies2.NextStage
		|WHERE
		|	Dependencies2.Stage IS NULL";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Return Query.Execute().Unload().UnloadColumn("ProductionStage");
	
EndFunction

Procedure MarkStageOnCriticalPathRecursively(PlanningParameters, ProductionStage, StageDependencies, ManuallyPlacedStages)
	
	RecordingGraph = PlanningParameters.ProductionSchedule.Find(ProductionStage, "Stage");
	
	If Not RecordingGraph = Undefined Then
		
		If Not RecordingGraph.OnCriticalPath Then
			
			RecordingGraph.OnCriticalPath = True;
			
			PlacedManually = Not ManuallyPlacedStages.Find(ProductionStage) = Undefined;
			
			If RecordingGraph.EquipmentLimited
				Or RecordingGraph.MaterialLimited
				Or PlacedManually Then
				
				RecordingGraph.ItLimitsProductionDate = True;
				
			Else
				
				StagesOfJourney = SubsequentStagesOfCriticalPath(PlanningParameters, StageDependencies, ProductionStage);
				
				If ValueIsFilled(StagesOfJourney) Then
					
					For Each Stage In StagesOfJourney Do
						MarkStageOnCriticalPathRecursively(
							PlanningParameters, Stage, StageDependencies, ManuallyPlacedStages);
					EndDo;
					
				Else
					
					RecordingGraph.ItLimitsProductionDate = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function SubsequentStagesOfCriticalPath(PlanningParameters, StageDependencies, ProductionStage)
	
	Result = New Array;
	
	If PlanningParameters.GoBackToBeginning Then
		BorderField = "Ending";
	Else
		BorderField = "Begin";
	EndIf;
	
	PreviousStages_ = RelatedStages(
		StageDependencies,
		ProductionStage,
		PlanningParameters.GoBackToBeginning,
		False);
	
	DateBorder = '00010101';
	
	For Each Stage In PreviousStages_ Do
		
		RecordingGraph = PlanningParameters.ProductionSchedule.Find(Stage, "Stage");
		If Not RecordingGraph = Undefined Then
			
			If Not ValueIsFilled(DateBorder) Then
				
				Result.Add(Stage);
				DateBorder = RecordingGraph[BorderField];
				
			Else
				
				If DateBorder = RecordingGraph[BorderField] Then
					
					Result.Add(Stage);
					
				ElsIf (PlanningParameters.GoBackToBeginning And RecordingGraph[BorderField] > DateBorder)
					Or (Not PlanningParameters.GoBackToBeginning And RecordingGraph[BorderField] < DateBorder) Then
					
					Result.Clear();
					Result.Add(Stage);
					DateBorder = RecordingGraph[BorderField];
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure CalculateBeginningOfNextSteps(PlanningParameters, TempTablesManager, PlacedStages)
	
	SupplementGraphWithRecordsOfAdjacentStages(
		PlanningParameters, TempTablesManager, PlacedStages);
	
	Query = New Query(
	"SELECT
	|	TTCommunicationStages.Stage AS ProductionStage,
	|	TTCommunicationStages.NextStage AS NextStage
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages");
	Query.TempTablesManager = TempTablesManager;
	StageDependencies = Query.Execute().Unload();
	
	For Each ProductionStage In PlacedStages Do
		FillInBeginningOfNextStage(PlanningParameters, StageDependencies, ProductionStage);
	EndDo;
	
	For Each ProductionStage In PlanningParameters.PreviousStagesOfProduction Do
		FillInBeginningOfNextStage(PlanningParameters, StageDependencies, ProductionStage);
	EndDo;
	
EndProcedure

Procedure SupplementGraphWithRecordsOfAdjacentStages(PlanningParameters, TempTablesManager, PlacedStages)
	
	Query = New Query(
	"SELECT DISTINCT
	|	TTCommunicationStages.NextStage AS ProductionStage
	|INTO TTStages
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|WHERE
	|	TTCommunicationStages.Stage IN(&PreviousStages_)
	|	AND NOT TTCommunicationStages.NextStage IN (&PlacedStages)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	TTCommunicationStages.NextStage
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|WHERE
	|	TTCommunicationStages.Stage IN(&PlacedStages)
	|	AND NOT TTCommunicationStages.NextStage IN (&PlacedStages)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	ProductionStage.Ref
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage
	|WHERE
	|	ProductionStage.Ref IN(&PreviousStages_)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfProductionStages2_2.ProductionOrder,
	|	ScheduleOfProductionStages2_2.Stage,
	|	ScheduleOfProductionStages2_2.ScheduleStatus,
	|	ScheduleOfProductionStages2_2.Begin,
	|	ScheduleOfProductionStages2_2.Ending,
	|	ScheduleOfProductionStages2_2.PreliminaryBufferEnd,
	|	ScheduleOfProductionStages2_2.FollowUpBufferStart,
	|	ScheduleOfProductionStages2_2.NextStageStart,
	|	ScheduleOfProductionStages2_2.OnCriticalPath,
	|	ScheduleOfProductionStages2_2.ItLimitsProductionDate,
	|	ScheduleOfProductionStages2_2.MaterialLimited,
	|	ScheduleOfProductionStages2_2.EquipmentLimited
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ProductionOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &StatusWorkingSchedule
	|	AND ScheduleOfProductionStages2_2.Stage IN
	|			(SELECT
	|				TTStages.ProductionStage
	|			FROM
	|				TTStages)
	|	AND NOT ScheduleOfProductionStages2_2.Stage IN (&ScheduleStages)");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("PreviousStages_", PlanningParameters.PreviousStagesOfProduction);
	Query.SetParameter("PlacedStages", PlacedStages);
	Query.SetParameter("ProductionOrder", PlanningParameters.ProductionOrder);
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("ScheduleStages", 
		PlanningParameters.ProductionSchedule.UnloadColumn("Stage"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = PlanningParameters.ProductionSchedule.Add();
		FillPropertyValues(NewRow, Selection);
		
	EndDo;
	
EndProcedure

Procedure FillInBeginningOfNextStage(PlanningParameters, StageDependencies, ProductionStage)
	
	RecordingGraph = PlanningParameters.ProductionSchedule.Find(ProductionStage, "Stage");
	If RecordingGraph = Undefined Then
		Return;
	EndIf;
	
	RecordingGraph.NextStageStart = '00010101';
	
	NextSteps_ = RelatedStages(StageDependencies, ProductionStage, True, True);
	For Each NextStage In NextSteps_ Do
		
		RecordingNextStage = PlanningParameters.ProductionSchedule.Find(NextStage, "Stage");
		
		If Not RecordingNextStage = Undefined Then
			
			If ValueIsFilled(RecordingGraph.NextStageStart) Then
				
				RecordingGraph.NextStageStart = Min(
					RecordingGraph.NextStageStart,
					RecordingNextStage.Begin);
					
			Else
				
				RecordingGraph.NextStageStart = RecordingNextStage.Begin;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PlaceStageWithManualPlacement(PlanningParameters, Stage, PlacementParameters)
	
	ScheduleData = PlanningParameters.GraphOfManuallyPlacedStages.Find(
		Stage.ProductionStage, "ProductionStage");
	
	If Not ScheduleData = Undefined Then
		
		Stage2_ = True;
		FillPropertyValues(PlacementParameters, ScheduleData);
		
		TheStructureOfTheSearch = New Structure("Stage", Stage.ProductionStage);
		FoundRows = PlanningParameters.LoadingManuallyPlacedStages.FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			
			NewRow = PlacementParameters.LoadingVRC.Add();
			FillPropertyValues(NewRow, String);
			
		EndDo;
		
	Else
		
		Stage2_ = False;
		
	EndIf;
	
	FixResultsOfStagePlacement(PlanningParameters, Stage, PlacementParameters, Stage2_);
	
EndProcedure

Procedure PerformChecksBeforeScheduling(PlanningParameters, Cancel)
	
	StageError = Documents.ProductionStage2_2.EmptyRef();
	
	If Documents.ProductionStage2_2.ThereAreCyclesInChainOfStages(PlanningParameters.ProductionOrder, StageError) Then
		
		FixErrorThereAreCyclesInChainOfStages(PlanningParameters, StageError);
		Cancel = True;
		
	EndIf;
	
EndProcedure

Function NumberOfProcessedData(PlanningParameters)
	
	If TypeOf(PlanningParameters.Stages) = Type("ValueTable") Then
		
		Result = PlanningParameters.Stages.Count();
		
	Else
		
		Result = 0;
		
	EndIf;
	
	Return Result;
	
EndFunction

#Region PlanningUBBV

Procedure FirstStageOfUBBV(PlanningParameters, Stage, PlacementParameters)
	
	If ValueIsFilled(Stage.StageDuration) Then
		
		PlacementResults = PlaceAccordingToUBBVSchedule(
			PlanningParameters,
			Stage.WorkScheduleCalendar,
			PlanningParameters.GoBackToBeginning,
			PlacementParameters.TimeOfPlacement,
			Stage.StageDuration,
			Stage.UnitOfMeasureOfStageDuration);
		
		If PlacementResults.PlacementCompleted Then
				
			Stage2_ = True;
			PlacementParameters.Begin = PlacementResults.Begin;
			PlacementParameters.Ending = PlacementResults.Ending;
			
		Else
			Stage2_ = False;
		EndIf;
		
	Else
		
		Stage2_ = True;
		PlacementParameters.Begin = PlacementParameters.TimeOfPlacement;
		PlacementParameters.Ending = PlacementParameters.TimeOfPlacement;
		
	EndIf;
	
	If Not Stage2_ Then
		PlacementParameters.PlacementErrorCode = ErrorCodeMissingScheduleUbbvStage(Stage);
	EndIf;
	
	FixResultsOfStagePlacement(PlanningParameters, Stage, PlacementParameters, Stage2_);
	
EndProcedure

Function PlaceAccordingToUBBVSchedule(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement, Time, TimeUnitsOfMeasure)
	
	PostInDays = ProductionDurationDays(TimeUnitsOfMeasure);
	ItRemainsToPlace = DurationOfUbbvLoading(Time, TimeUnitsOfMeasure, PostInDays);
	
	PlotInterval = InitialUBBVPlacementInterval(
		PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement, PostInDays);
	
	If Not PlotInterval = Undefined Then
		
		StartOfPlacement = StartOfUBBVPlacement(GoBackToBeginning, TimeOfPlacement, PlotInterval, PostInDays);
		EndOfPlacement = StartOfPlacement;
		
		While Not PlotInterval = Undefined Do
			
			ShiftUbbvPlacementBoundary(
				GoBackToBeginning, PlotInterval, EndOfPlacement, ItRemainsToPlace, PostInDays);
			
			If ItRemainsToPlace > 0 Then
				PlotInterval = NextUBBVPlacementInterval(
					PlanningParameters, GoBackToBeginning, WorkScheduleCalendar, PlotInterval, PostInDays);
			Else
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure("PlacementCompleted, Begin, Ending");
	If Max(0, ItRemainsToPlace) = 0 Then
		
		Result.PlacementCompleted = True;
		If GoBackToBeginning Then
			Result.Begin = StartOfPlacement;
			Result.Ending = EndOfPlacement;
		Else
			Result.Begin = EndOfPlacement;
			Result.Ending = StartOfPlacement;
		EndIf;
		
		If PostInDays Then
			FixUbbvsCalendarBoundariesOnSchedule(
				PlanningParameters, WorkScheduleCalendar, Result.Begin, Result.Ending);
		EndIf;
		
	Else
		
		Result.PlacementCompleted = False;
		
	EndIf;
	
	Return Result
	
EndFunction

Function DurationOfUbbvLoading(Time, TimeUnitsOfMeasure, PostInDays)
	
	If PostInDays Then
		ItRemainsToPlace = Time;
	Else
		ItRemainsToPlace = ProductionPlanningClientServer.GetTimeInSeconds(Time, TimeUnitsOfMeasure);
	EndIf;
	
	Return ItRemainsToPlace;
	
EndFunction

Function ProductionDurationDays(Ed)
	
	Return Ed = Enums.TimeMeasureUnits.Day;
	
EndFunction

Function InitialUBBVPlacementInterval(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement, PostInDays)
	
	If PostInDays Then
		Result = InitialIntervalOfPlacementOfUBBVOnCalendar(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement);
	Else
		Result = InitialIntervalOfPlacementOfUBBVAccordingToSchedule(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement);
	EndIf;
	
	Return Result;
	
EndFunction

Function InitialIntervalOfPlacementOfUBBVOnCalendar(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement)
	
	If TimeOfPlacement = BegOfDay(TimeOfPlacement) Then
		If GoBackToBeginning Then
			StartDateOfSchedule = TimeOfPlacement;
		Else
			StartDateOfSchedule = BegOfDay(TimeOfPlacement-1);
		EndIf;
	Else
		If GoBackToBeginning Then
			StartDateOfSchedule = EndOfDay(TimeOfPlacement) + 1;
		Else
			StartDateOfSchedule = BegOfDay(TimeOfPlacement - 86400);
		EndIf;
	EndIf;
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		Result = UbbvPlacementIntervalRoundClockOperation(WorkScheduleCalendar, StartDateOfSchedule);
		
	Else
		
		Result = Undefined;
		UbbwSchedule = PlanningParameters.UbbwSchedule;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkScheduleCalendar", WorkScheduleCalendar);
		
		For Cnt = 1 To 3 Do
			
			TheStructureOfTheSearch.Insert("ScheduleDate", StartDateOfSchedule);
			FoundRows = UbbwSchedule.FindRows(TheStructureOfTheSearch);
			
			If ValueIsFilled(FoundRows) Then
				Result = FoundRows[0];
				Break;
			Else
				If GoBackToBeginning Then
					StartDateOfSchedule = StartDateOfSchedule + 86400;
				Else
					StartDateOfSchedule = StartDateOfSchedule - 86400;
				EndIf;
			EndIf;
			
		EndDo;
		
		If Result = Undefined Then
			
			TheStructureOfTheSearch = New Structure("WorkScheduleCalendar", WorkScheduleCalendar);
			FoundRows = FindRowsWithPreservingOrder(UbbwSchedule, TheStructureOfTheSearch, True);
			
			MaxIndex_ = FoundRows.UBound();
			If GoBackToBeginning Then
				
				For Cnt = 0 To MaxIndex_ Do
					String = FoundRows[Cnt];
					If String.ScheduleDate >= StartDateOfSchedule Then
						Result = String;
						Break;
					EndIf;
				EndDo;
				
			Else
				
				For Cnt = 0 To MaxIndex_ Do
					String = FoundRows[MaxIndex_-Cnt];
					If String.ScheduleDate <= StartDateOfSchedule Then
						Result = String;
						Break;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InitialIntervalOfPlacementOfUBBVAccordingToSchedule(PlanningParameters, WorkScheduleCalendar, GoBackToBeginning, TimeOfPlacement)
	
	ScheduleDate = BegOfDay(TimeOfPlacement);
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		Result = UbbvPlacementIntervalRoundClockOperation(WorkScheduleCalendar, ScheduleDate);
		
	Else
		
		UbbwSchedule = PlanningParameters.UbbwSchedule;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkScheduleCalendar", WorkScheduleCalendar);
		TheStructureOfTheSearch.Insert("ScheduleDate", ScheduleDate);
		
		FoundRows = FindRowsWithPreservingOrder(UbbwSchedule, TheStructureOfTheSearch, True);
		
		Result = ScheduledUbbvPlacementInterval(GoBackToBeginning, TimeOfPlacement, FoundRows);
		If Result = Undefined Then
			
			TheStructureOfTheSearch = New Structure("WorkScheduleCalendar", WorkScheduleCalendar);
			FoundRows = FindRowsWithPreservingOrder(UbbwSchedule, TheStructureOfTheSearch, True);
			
			Result = ScheduledUbbvPlacementInterval(GoBackToBeginning, TimeOfPlacement, FoundRows);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction


Function ScheduledUbbvPlacementInterval(GoBackToBeginning, TimeOfPlacement, ScheduleLines)
	
	Result = Undefined;
	
	MaxIndex_ = ScheduleLines.UBound();
	If GoBackToBeginning Then
		
		For Cnt = 0 To MaxIndex_ Do
			String = ScheduleLines[Cnt];
			If TimeOfPlacement < String.Ending Then
				
				Result = String;
				Break;
				
			EndIf;
		EndDo;
		
	Else
		
		For Cnt = 0 To MaxIndex_ Do
			String = ScheduleLines[MaxIndex_-Cnt]; // See ScheduleUBBVLineConstructor
			If TimeOfPlacement > String.Begin Then
				
				Result = String;
				Break;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function StartOfUBBVPlacement(GoBackToBeginning, TimeOfPlacement, PlotInterval, PostInDays)
	
	If PostInDays Then
		
		If GoBackToBeginning Then
			Result = PlotInterval.ScheduleDate;
		Else
			Result = EndOfDay(PlotInterval.ScheduleDate) + 1;
		EndIf;
		
	Else
		
		If TimeOfPlacement >= PlotInterval.Begin
			And TimeOfPlacement <= PlotInterval.Ending Then
			Result = TimeOfPlacement;
		Else
			If GoBackToBeginning Then
				Result = PlotInterval.Begin;
			Else
				Result = PlotInterval.Ending;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ShiftUbbvPlacementBoundary(GoBackToBeginning, PlotInterval, PlacementBoundary, ItRemainsToPlace, PostInDays)
	
	If PostInDays Then
		
		If GoBackToBeginning Then
			PlacementBoundary = EndOfDay(PlotInterval.ScheduleDate) + 1;
		Else
			PlacementBoundary = PlotInterval.ScheduleDate;
		EndIf;
		
		ItRemainsToPlace = ItRemainsToPlace - 1;
		
	Else
		
		If PlacementBoundary >= PlotInterval.Begin
			And PlacementBoundary <= PlotInterval.Ending Then
			
			If GoBackToBeginning Then
				
				AvailableTime = PlotInterval.Ending - PlacementBoundary;
				OffsetTime = Min(ItRemainsToPlace, AvailableTime);
				PlacementBoundary = PlacementBoundary + OffsetTime;
				
			Else
				
				AvailableTime = PlacementBoundary - PlotInterval.Begin;
				OffsetTime = Min(ItRemainsToPlace, AvailableTime);
				PlacementBoundary = PlacementBoundary - OffsetTime;
				
			EndIf;
			
			ItRemainsToPlace = ItRemainsToPlace - OffsetTime;
			
		Else
			
			OffsetTime = Min(ItRemainsToPlace, PlotInterval.Duration);
			
			If GoBackToBeginning Then
				PlacementBoundary = PlotInterval.Begin + OffsetTime;
			Else
				PlacementBoundary = PlotInterval.Ending - OffsetTime;
			EndIf;
			
			ItRemainsToPlace = ItRemainsToPlace - OffsetTime;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function NextUBBVPlacementInterval(PlanningParameters, GoBackToBeginning, WorkScheduleCalendar, PlotInterval, PostInDays)
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		If GoBackToBeginning Then
			ScheduleDate = EndOfDay(PlotInterval.ScheduleDate)+1;
		Else
			ScheduleDate = BegOfDay(PlotInterval.ScheduleDate)-86400;
		EndIf;
		
		Result = UbbvPlacementIntervalRoundClockOperation(WorkScheduleCalendar, ScheduleDate);
		
	Else
		
		Result = Undefined;
		UbbwSchedule = PlanningParameters.UbbwSchedule;
		IndexOf = UbbwSchedule.IndexOf(PlotInterval);
		
		If GoBackToBeginning Then
			
			IndexOf = IndexOf + 1;
			While IndexOf < UbbwSchedule.Count() Do
				
				NextInterval_ = UbbwSchedule[IndexOf];
				If NextInterval_.WorkScheduleCalendar = WorkScheduleCalendar Then
					
					If PostInDays Then
						If Not PlotInterval.ScheduleDate = NextInterval_.ScheduleDate Then
							Result = NextInterval_;
						EndIf;
					Else
						Result = NextInterval_;
					EndIf;
					
				Else
					Break;
				EndIf;
				
				If Not Result = Undefined Then
					Break;
				Else
					IndexOf = IndexOf + 1;
				EndIf;
				
			EndDo;
			
		Else
			
			IndexOf = IndexOf - 1;
			While IndexOf >= 0 Do
				
				NextInterval_ = UbbwSchedule[IndexOf];
				If NextInterval_.WorkScheduleCalendar = WorkScheduleCalendar Then
					
					If PostInDays Then
						If Not PlotInterval.ScheduleDate = NextInterval_.ScheduleDate Then
							Result = NextInterval_;
						EndIf;
					Else
						Result = NextInterval_;
					EndIf;
					
				Else
					Break;
				EndIf;
				
				If Not Result = Undefined Then
					Break;
				Else
					IndexOf = IndexOf - 1;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure DisplacePrecedingStagesOfUBBV(PlanningParameters, Stage, Val TimeOfPlacement)
	
	If Not PlanningParameters.GoBackToBeginning 
		Or Not Stage.OffsetPriorStagesOfUBBV Then
		
		Return;
		
	EndIf;
	
	PreviousStages_ = RelatedStageData(PlanningParameters, Stage.ProductionStage, False);
	For Each PreviousStage_ In PreviousStages_ Do
		
		If ThisIsUBBVStage(PreviousStage_)
			And Stage.ProductionLot = PreviousStage_.ProductionLot Then
			
			If ValueIsFilled(PreviousStage_.StageDuration) Then
				
				PlacementResults = PlaceAccordingToUBBVSchedule(
					PlanningParameters,
					PreviousStage_.WorkScheduleCalendar,
					False,
					TimeOfPlacement,
					PreviousStage_.StageDuration,
					PreviousStage_.UnitOfMeasureOfStageDuration);
					
			Else
				
				PlacementResults = New Structure;
				PlacementResults.Insert("PlacementCompleted", True);
				PlacementResults.Insert("Begin", TimeOfPlacement);
				PlacementResults.Insert("Ending", TimeOfPlacement);
				
			EndIf;
			
			If PlacementResults.PlacementCompleted Then
				
				RecordingGraph = PlanningParameters.ProductionSchedule.Find(PreviousStage_.ProductionStage, "Stage");
				If Not RecordingGraph = Undefined Then
					
					RecordingGraph.Begin = PlacementResults.Begin;
					RecordingGraph.Ending = PlacementResults.Ending;
					RecordingGraph.ProductionScheduling = Enums.WayOfLinkingProductionOperations.ToFinish;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function UbbvPlacementIntervalRoundClockOperation(WorkScheduleCalendar, ScheduleDate)
	
	Result = New Structure;
	Result.Insert("WorkScheduleCalendar", WorkScheduleCalendar);
	Result.Insert("ScheduleDate", ScheduleDate);
	Result.Insert("Begin", BegOfDay(ScheduleDate));
	Result.Insert("Ending", EndOfDay(ScheduleDate)+1);
	Result.Insert("Duration", 86400);
	
	Return Result;
	
EndFunction

Procedure FixUbbvsCalendarBoundariesOnSchedule(PlanningParameters, WorkScheduleCalendar, Begin, Ending)
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		Return;
	EndIf;
	
	Boundaries = BoundariesOfDayAccordingToSchedule(PlanningParameters, WorkScheduleCalendar, BegOfDay(Begin));
	
	If ValueIsFilled(Boundaries.Begin) Then
		Begin = Boundaries.Begin;
	EndIf;
	
	ScheduleDateEnd = BegOfDay(Ending-1);
	If Not BegOfDay(Begin) = ScheduleDateEnd Then
		Boundaries = BoundariesOfDayAccordingToSchedule(PlanningParameters, WorkScheduleCalendar, ScheduleDateEnd);
	EndIf;
	
	If ValueIsFilled(Boundaries.Ending) Then
		Ending = Boundaries.Ending;
	EndIf;
	
EndProcedure

Function BoundariesOfDayAccordingToSchedule(PlanningParameters, WorkScheduleCalendar, ScheduleDate)
	
	Result = New Structure("Begin, Ending", '00010101', '00010101');
	
	If Not PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		TheStructureOfTheSearch = New Structure("WorkScheduleCalendar, ScheduleDate", WorkScheduleCalendar, ScheduleDate);
		FoundRows = PlanningParameters.UbbwSchedule.FindRows(TheStructureOfTheSearch);
		
		For IndexOf = 0 To FoundRows.UBound() Do
			
			If IndexOf = 0 Then
				Result.Begin = FoundRows[IndexOf].Begin;
				Result.Ending = FoundRows[IndexOf].Ending;
			Else
				Result.Begin = Min(Result.Begin, FoundRows[IndexOf].Begin);
				Result.Ending = Max(Result.Ending, FoundRows[IndexOf].Ending);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ErrorCodeMissingScheduleUbbvStage(Stage)
	
	If Stage.ProductionByThirdParty Then
		
		Result = ErrorCodeBusinessHours();
		
	Else
		
		Result = ErrorCodeDivisionSchedule();
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region PlanningOfBBV

Procedure FirstStageOfBBV(PlanningParameters, Stage, PlacementParameters)
	
	Cancel = False;
	
	ShiftMomentOfPlacementBySizeOfBuffer(PlanningParameters, Stage, PlacementParameters, Cancel);
	
	If Cancel Then
		PlacementParameters.PlacementErrorCode = ErrorCodeDivisionSchedule();
	EndIf;
	
	If Not Cancel Then
		
		WorkCenterTypes = TypesOfWorkingStageCenters(PlanningParameters, Stage);
		If WorkCenterTypes.Count() = 1 Then
			
			DownloadSingleVRC(PlanningParameters, Stage, WorkCenterTypes[0], PlacementParameters, Cancel);
			
		ElsIf WorkCenterTypes.Count() > 1 Then
			
			UploadVRCGroup(PlanningParameters, Stage, WorkCenterTypes, PlacementParameters, Cancel);
			
		EndIf;
		
		If Cancel Then
			PlacementParameters.PlacementErrorCode = ErrorCodeVRCAvailability();
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		CalculateStageBufferBoundaries(PlanningParameters, Stage, PlacementParameters, Cancel);
		
		If Cancel Then
			PlacementParameters.PlacementErrorCode = ErrorCodeDivisionSchedule();
		EndIf;
		
	EndIf;
	
	FixResultsOfStagePlacement(PlanningParameters, Stage, PlacementParameters, Not Cancel);
	
EndProcedure

Procedure ShiftMomentOfPlacementBySizeOfBuffer(PlanningParameters, Stage, PlacementParameters, Cancel)
	
	If PlanningParameters.GoBackToBeginning Then
		
		BufferEdISM = Stage.UnitOfMeasureOfPreliminaryBuffer;
		Buffer = ConsideredBufferSize(Stage.PreliminaryBuffer, BufferEdISM, Stage);
		
	Else
		
		BufferEdISM = Stage.UnitOfMeasureOfFollowUpBuffer;
		Buffer = ConsideredBufferSize(Stage.FollowUpBuffer, BufferEdISM, Stage);
		
	EndIf;
	
	If ValueIsFilled(Buffer) Then
		
		PlacementResults = PlaceAccordingToUBBVSchedule(
			PlanningParameters,
			Stage.WorkScheduleCalendar,
			PlanningParameters.GoBackToBeginning,
			PlacementParameters.TimeOfPlacement,
			Buffer,
			BufferEdISM);
			
		If PlacementResults.PlacementCompleted Then
			
			If PlanningParameters.GoBackToBeginning Then
				
				PlacementParameters.TimeOfPlacement = PlacementResults.Ending;
				
			Else
				
				PlacementParameters.TimeOfPlacement = PlacementResults.Begin;
				
			EndIf;
			
		Else
			
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DownloadSingleVRC(PlanningParameters, Stage, StageExecutor, PlacementParameters, Cancel)
	
	ItRemainsToPlace = StageExecutor.Time;
	PlacementInterval = InitialBBBPlacementInterval(
		PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementParameters.TimeOfPlacement);
	
	While Not PlacementInterval = Undefined Do
		
		Duration = LoadingVRCOnInterval(Stage, StageExecutor,  PlacementInterval, ItRemainsToPlace);
		AddVRCUpload(
			PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementInterval, Duration);
		ItRemainsToPlace = ItRemainsToPlace - Duration;
		
		If ItRemainsToPlace > 0 Then
			
			ContinuousPlacement = True;
			PlacementInterval = NextIntervalOfPlacementOfBBV(
				PlanningParameters, StageExecutor, PlacementInterval, ContinuousPlacement);
			
			If Stage.Continuous_ And Not ContinuousPlacement Then
				ItRemainsToPlace = StageExecutor.Time;
				PlacementParameters.LoadingVRC.Clear();
				NoteStageIsLimitedByHardware(PlacementParameters);
			EndIf;
			
		Else
			Break;
		EndIf;
		
	EndDo;
	
	If ItRemainsToPlace = 0 Then
		CalculateVRCLoadingLimits(PlanningParameters, Stage, PlacementParameters);
	Else
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure UploadVRCGroup(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel)
	
	Order = Enums.OperatingProcedureOfWorkCenterTypes;
	
	If Stage.OperatingProcedureOfWorkCenterTypes = Order.Sequentially Then
		
		LoadVRCGroupSequentially(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel);
		
	ElsIf Stage.OperatingProcedureOfWorkCenterTypes = Order.Simultaneously Then
		
		LoadVRCGroupAtSameTime(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel);
		
	ElsIf Stage.OperatingProcedureOfWorkCenterTypes = Order.Independently Then
		
		LoadVRCGroupIndependently(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		CalculateVRCLoadingLimits(PlanningParameters, Stage, PlacementParameters);
	EndIf;
	
EndProcedure

Procedure LoadVRCGroupSequentially(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel)
	
	IntervalOfFirstPerformer = Undefined;
	PlacementInterval = Undefined;
	
	If PlanningParameters.GoBackToBeginning Then
		InitialIndex = 0;
		MaxIndex = StagePerformers.Count()-1;
	Else
		InitialIndex = -(StagePerformers.Count()-1);
		MaxIndex = 0;
	EndIf;
	IndexOf = InitialIndex;
	
	TheStructureOfTheSearch = New Structure("WorkCenterType, IntervalDate, Stage");
	
	While IndexOf <= MaxIndex Do
		
		If PlanningParameters.GoBackToBeginning Then
			StageExecutor = StagePerformers[IndexOf];
		Else
			StageExecutor = StagePerformers[-IndexOf];
		EndIf;
		
		ItRemainsToPlace = StageExecutor.Time;
		RepeatCrawling = False;
		
		If IndexOf = InitialIndex Then
			If IntervalOfFirstPerformer = Undefined Then
				PlacementInterval = InitialBBBPlacementInterval(
					PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementParameters.TimeOfPlacement);
			Else
				PlacementInterval = NextIntervalOfPlacementOfBBV(
					PlanningParameters, StageExecutor, IntervalOfFirstPerformer);
			EndIf;
			IntervalOfFirstPerformer = PlacementInterval;
		Else
			
			If PlanningParameters.GoBackToBeginning Then
				TimeOfPlacement = PlacementInterval.IntervalDate;
			Else
				TimeOfPlacement = LeadToEndOfPeriod(
					PlacementInterval.IntervalDate, StageExecutor.PlanningInterval);
			EndIf;
				
			PlacementInterval = InitialBBBPlacementInterval(
				PlanningParameters, Stage, StageExecutor, PlacementParameters, TimeOfPlacement);
			
			If PlacementInterval <> Undefined Then
				TheStructureOfTheSearch.WorkCenterType = StageExecutor.WorkCenterType;
				TheStructureOfTheSearch.IntervalDate = PlacementInterval.IntervalDate;
				TheStructureOfTheSearch.Stage = Stage.ProductionStage;
				
				If PlacementParameters.LoadingVRC.FindRows(TheStructureOfTheSearch).Count() <> 0 Then
					ContinuousPlacement = True;
					PlacementInterval = NextIntervalOfPlacementOfBBV(
						PlanningParameters, StageExecutor, PlacementInterval, ContinuousPlacement);
					
					If Stage.Continuous_ And Not ContinuousPlacement Then
						
						PlacementParameters.LoadingVRC.Clear();
						NoteStageIsLimitedByHardware(PlacementParameters);
						
						RepeatCrawling = True;
						PlacementInterval = Undefined;
						
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
		
		While Not PlacementInterval = Undefined Do
			
			Duration = LoadingVRCOnInterval(Stage, StageExecutor,  PlacementInterval, ItRemainsToPlace);
			AddVRCUpload(
				PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementInterval, Duration);
			ItRemainsToPlace = ItRemainsToPlace - Duration;
			
			If ItRemainsToPlace > 0 Then
				
				ContinuousPlacement = True;
				PlacementInterval = NextIntervalOfPlacementOfBBV(
					PlanningParameters, StageExecutor, PlacementInterval, ContinuousPlacement);
				
				If Stage.Continuous_ And Not ContinuousPlacement Then
					
					PlacementParameters.LoadingVRC.Clear();
					NoteStageIsLimitedByHardware(PlacementParameters);
					
					If IndexOf <> InitialIndex Then
						RepeatCrawling = True;
						Break;
					EndIf;
					
				EndIf;
				
			Else
				Break;
			EndIf;
			
		EndDo;
		
		If RepeatCrawling Then
			
			IndexOf = InitialIndex;
			Continue;
			
		ElsIf ItRemainsToPlace > 0 Then
			
			Cancel = True;
			Break;
			
		EndIf;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
EndProcedure

Procedure LoadVRCGroupAtSameTime(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel)
	
	FirstPerformer = StagePerformers[0];
	
	ItRemainsToPlace = FirstPerformer.Time;
	PlacementInterval = InitialBBBPlacementInterval(
		PlanningParameters, Stage, FirstPerformer, PlacementParameters, PlacementParameters.TimeOfPlacement);
	
	While Not PlacementInterval = Undefined Do
		
		Intervals = New Map;
		Intervals.Insert(0, PlacementInterval);
		
		For IndexOf = 1 To StagePerformers.Count()-1 Do
			
			VRCTimeInterval = BBBPlacementIntervalByIntervalDate(
				PlanningParameters, StagePerformers[IndexOf], PlacementInterval.IntervalDate);
			
			If VRCTimeInterval <> Undefined Then
				Intervals.Insert(IndexOf, VRCTimeInterval);
			Else
				
				If Stage.Continuous_ Then
					ItRemainsToPlace = FirstPerformer.Time;
					PlacementParameters.LoadingVRC.Clear();
					NoteStageIsLimitedByHardware(PlacementParameters);
				EndIf;
				
				Break;
				
			EndIf;
			
		EndDo;
		
		If Intervals.Count() = StagePerformers.Count() Then
			
			Duration = 0;
			
			For Each KeyAndValue In Intervals Do
				
				CurPerformer = StagePerformers[KeyAndValue.Key];
				CurInterval = KeyAndValue.Value;
							
				IntervalDuration = LoadingVRCOnInterval(Stage, CurPerformer, CurInterval, ItRemainsToPlace);
				
				Duration = ?(Duration > 0, Min(Duration, IntervalDuration), IntervalDuration);
				
			EndDo;
			
			For Each KeyAndValue In Intervals Do
				
				CurPerformer = StagePerformers[KeyAndValue.Key];
				CurInterval = KeyAndValue.Value;
				
				AddVRCUpload(
					PlanningParameters, Stage, CurPerformer, PlacementParameters, CurInterval, Duration);
					
			EndDo;
			
			ItRemainsToPlace = ItRemainsToPlace - Duration;
			
		EndIf;
		
		If ItRemainsToPlace > 0 Then
			
			ContinuousPlacement = True;
			PlacementInterval = NextIntervalOfPlacementOfBBV(
				PlanningParameters, FirstPerformer, PlacementInterval, ContinuousPlacement);
			
			If Stage.Continuous_ And Not ContinuousPlacement Then
				ItRemainsToPlace = FirstPerformer.Time;
				PlacementParameters.LoadingVRC.Clear();
				NoteStageIsLimitedByHardware(PlacementParameters);
			EndIf;
			
		Else
			Break;
		EndIf;
		
	EndDo;
	
	If ItRemainsToPlace > 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure LoadVRCGroupIndependently(PlanningParameters, Stage, StagePerformers, PlacementParameters, Cancel)
	
	For Each StageExecutor In StagePerformers Do
		
		ItRemainsToPlace = StageExecutor.Time;
		PlacementInterval = InitialBBBPlacementInterval(
			PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementParameters.TimeOfPlacement);
		
		While Not PlacementInterval = Undefined Do
			
			Duration = LoadingVRCOnInterval(Stage, StageExecutor,  PlacementInterval, ItRemainsToPlace);
			
			AddVRCUpload(
				PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementInterval, Duration);
			
			ItRemainsToPlace = ItRemainsToPlace - Duration;
			
			If ItRemainsToPlace > 0 Then
				
				ContinuousPlacement = True;
				PlacementInterval = NextIntervalOfPlacementOfBBV(
				PlanningParameters, StageExecutor, PlacementInterval, ContinuousPlacement);
				
				If Stage.Continuous_ And Not ContinuousPlacement Then
					
					ItRemainsToPlace = StageExecutor.Time;
					
					TheStructureOfTheSearch = New Structure("WorkCenterType", StageExecutor.WorkCenterType);
					FoundRows = PlacementParameters.LoadingVRC.FindRows(TheStructureOfTheSearch);
					For Each String In FoundRows Do
						PlacementParameters.LoadingVRC.Delete(String);
					EndDo;
					
					NoteStageIsLimitedByHardware(PlacementParameters);
					
				EndIf;
				
			Else
				Break;
			EndIf;
			
		EndDo;
		
		If ItRemainsToPlace > 0 Then
			Cancel = True;
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Function InitialBBBPlacementInterval(PlanningParameters, Stage, StageExecutor, PlacementParameters, TimeOfPlacement)
	
	IntervalDate = DateOfInitialBBBInterval(PlanningParameters, Stage, TimeOfPlacement);
	
	Result = Undefined;
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		#Region RoundClockWork
		
		PlacementInterval = InitializePlacementIntervalRoundClockOperation();
		PlacementInterval.WorkCenterType = StageExecutor.WorkCenterType;
		
		FillInPlacementIntervalRoundClockWork(PlanningParameters, StageExecutor, PlacementInterval, IntervalDate);
		
		Result = PlacementInterval;
		
		#EndRegion
		
	Else
		
		If StageExecutor.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
			NumberOfSearchIterations = 3;
		Else
			NumberOfSearchIterations = 1;
		EndIf;
	
		If StageExecutor.ConsiderAvailability Then
			
			#Region SearchByDate
			
			PerformIntervalTraversal = True;
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("WorkCenterType", StageExecutor.WorkCenterType);
			
			For Cnt = 1 To NumberOfSearchIterations Do
				
				If Not PlanningParameters.GoBackToBeginning
					And Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
					TheStructureOfTheSearch.Insert("EndOfShift", IntervalDate);
				Else
					TheStructureOfTheSearch.Insert("IntervalDate", IntervalDate);
				EndIf;
				FoundRows = PlanningParameters.WCKAvailability.FindRows(TheStructureOfTheSearch);
				
				If FoundRows.Count() = 0 Then
					
					If PlanningParameters.GoBackToBeginning Then
						IntervalDate = LeadToEndOfPeriod(IntervalDate, StageExecutor.PlanningInterval);
					Else
						IntervalDate = LeadToBeginningOfPeriod(IntervalDate-1, StageExecutor.PlanningInterval);
					EndIf;
					
				Else 
					
					String = FoundRows[0];
					If String.Available > 0 Then
						
						Result = String;
						
					Else
						
						NoteStageIsLimitedByHardware(PlacementParameters);
						
						PerformIntervalTraversal = False;
						
						If PlanningParameters.GoBackToBeginning Then
							RowIndex = PlanningParameters.WCKAvailability.IndexOf(String) + 1;
							MaxIndex_ = PlanningParameters.WCKAvailability.Count() - 1;
						Else
							RowIndex = -(PlanningParameters.WCKAvailability.IndexOf(String) - 1);
							MaxIndex_ = 0;
						EndIf;
						
						For IndexOf = RowIndex To MaxIndex_ Do
							
							If PlanningParameters.GoBackToBeginning Then
								String = PlanningParameters.WCKAvailability[IndexOf];
							Else
								String = PlanningParameters.WCKAvailability[-IndexOf];
							EndIf;
							
							If Not String.WorkCenterType = StageExecutor.WorkCenterType Then
								Break;
							ElsIf String.Available > 0 Then
								Result = String;
								Break;
							EndIf;
							
						EndDo;
						
					EndIf;
					
					Break;
					
				EndIf;
				
			EndDo;
			
			#EndRegion
			
			#Region TraversingIntervals
			
			If Result = Undefined And PerformIntervalTraversal Then
				
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("WorkCenterType", StageExecutor.WorkCenterType);
				FoundRows = FindRowsWithPreservingOrder(
					PlanningParameters.WCKAvailability, TheStructureOfTheSearch, True);
				
				MaxIndex_ = FoundRows.UBound();
				
				If PlanningParameters.GoBackToBeginning Then
					
					For Cnt = 0 To MaxIndex_ Do
						String = FoundRows[Cnt];
						If String.IntervalDate >= IntervalDate Then
							
							If String.Available > 0 Then
								
								Result = String;
								Break;
								
							Else
								
								NoteStageIsLimitedByHardware(PlacementParameters);
								
							EndIf;
							
						EndIf;
					EndDo;
					
				Else
					
					ColumnName = ?(Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift,
						"EndOfShift",
						"IntervalDate");
					
					For Cnt = 0 To MaxIndex_ Do
						String = FoundRows[MaxIndex_-Cnt];
						If String[ColumnName] <= IntervalDate Then
							
							If String.Available > 0 Then
								
								Result = String;
								Break;
								
							Else
								
								NoteStageIsLimitedByHardware(PlacementParameters);
								
							EndIf;
							
						EndIf;
					EndDo;
					
				EndIf;
				
			EndIf;
			
			#EndRegion
			
		Else
			
			#Region SearchByDate
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("WorkScheduleCalendar", StageExecutor.WorkScheduleCalendar);
			
			For Cnt = 1 To NumberOfSearchIterations Do
				
				If Not PlanningParameters.GoBackToBeginning
					And Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
					TheStructureOfTheSearch.Insert("EndOfShift", IntervalDate);
				Else
					TheStructureOfTheSearch.Insert("IntervalDate", IntervalDate);
				EndIf;
				
				FoundRows = PlanningParameters.BBVSchedule.FindRows(TheStructureOfTheSearch);
				
				If FoundRows.Count() = 0 Then
					
					If PlanningParameters.GoBackToBeginning Then
						IntervalDate = LeadToEndOfPeriod(IntervalDate, StageExecutor.PlanningInterval);
					Else
						IntervalDate = LeadToBeginningOfPeriod(IntervalDate-1, StageExecutor.PlanningInterval);
					EndIf;
					
				Else
					
					Result = FoundRows[0];
					Break;
					
				EndIf;
				
			EndDo;
			
			#EndRegion
			
			#Region TraversingIntervals
			
			If Result = Undefined Then
				
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("WorkScheduleCalendar", StageExecutor.WorkScheduleCalendar);
				FoundRows = FindRowsWithPreservingOrder(
					PlanningParameters.BBVSchedule, TheStructureOfTheSearch, True);
				
				MaxIndex_ = FoundRows.UBound();
				Result = Undefined;
				If PlanningParameters.GoBackToBeginning Then
					
					For Cnt = 0 To MaxIndex_ Do
						String = FoundRows[Cnt];
						If String.IntervalDate >= IntervalDate Then
							
							Result = String;
							Break;
							
						EndIf;
					EndDo;
					
				Else
					
					ColumnName = ?(Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift,
						"EndOfShift",
						"IntervalDate");
					
					For Cnt = 0 To MaxIndex_ Do
						String = FoundRows[MaxIndex_-Cnt];
						If String[ColumnName] <= IntervalDate Then
							
							Result = String;
							Break;
							
						EndIf;
					EndDo;
					
				EndIf;
				
			EndIf;
			
			#EndRegion
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function NextIntervalOfPlacementOfBBV(PlanningParameters, StageExecutor, PlacementInterval, ContinuousPlacement = True)
	
	Result = Undefined;
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		#Region RoundClockWork
		
		If PlanningParameters.GoBackToBeginning Then
			
			IntervalDate = LeadToEndOfPeriod(
				PlacementInterval.IntervalDate, StageExecutor.PlanningInterval);
			
		Else
			
			IntervalDate = LeadToBeginningOfPeriod(
				PlacementInterval.IntervalDate-1, StageExecutor.PlanningInterval);
			
		EndIf;
		
		FillInPlacementIntervalRoundClockWork(PlanningParameters, StageExecutor, PlacementInterval, IntervalDate, ContinuousPlacement);
		
		Result = PlacementInterval;
		
		#EndRegion
		
	Else
		
		If StageExecutor.ConsiderAvailability Then
			
			#Region ConsiderAvailability
			
			IntervalsTable = PlanningParameters.WCKAvailability;
			IndexOf = IntervalsTable.IndexOf(PlacementInterval);
			
			If PlanningParameters.GoBackToBeginning Then
				
				IndexOf = IndexOf + 1;
				While IndexOf < IntervalsTable.Count() Do
					
					NextInterval_ = IntervalsTable[IndexOf];
					If NextInterval_.WorkCenterType = PlacementInterval.WorkCenterType Then
						
						If NextInterval_.Available > 0 Then
							Result = NextInterval_;
						Else
							ContinuousPlacement = False;
						EndIf;
						
					Else
						Break;
					EndIf;
					
					If Not Result = Undefined Then
						Break;
					Else
						IndexOf = IndexOf + 1;
					EndIf;
					
				EndDo;
				
			Else
				
				IndexOf = IndexOf - 1;
				While IndexOf >= 0 Do
					
					NextInterval_ = IntervalsTable[IndexOf];
					If NextInterval_.WorkCenterType = PlacementInterval.WorkCenterType Then
						
						If NextInterval_.Available > 0 Then
							Result = NextInterval_;
						Else
							ContinuousPlacement = False;
						EndIf;
						
					Else
						Break;
					EndIf;
					
					If Not Result = Undefined Then
						Break;
					Else
						IndexOf = IndexOf - 1;
					EndIf;
					
				EndDo;
				
			EndIf;
			
			#EndRegion
			
		Else
			
			#Region NotConsiderAvailability
			
			IntervalsTable = PlanningParameters.BBVSchedule;
			IndexOf = IntervalsTable.IndexOf(PlacementInterval);
			
			If PlanningParameters.GoBackToBeginning Then
				IndexOf = IndexOf + 1;
				If IndexOf >= IntervalsTable.Count() Then
					IndexOf = Undefined;
				EndIf;
			Else
				IndexOf = IndexOf - 1;
				If IndexOf < 0 Then
					IndexOf = Undefined;
				EndIf;
			EndIf;
			
			If Not IndexOf = Undefined Then
				
				NextInterval_ = IntervalsTable[IndexOf];
				If NextInterval_.WorkScheduleCalendar = PlacementInterval.WorkScheduleCalendar
					And NextInterval_.PlanningInterval = PlacementInterval.PlanningInterval Then
					
					Result = NextInterval_;
					
				EndIf;
				
			EndIf;
			
			#EndRegion
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function BBBPlacementIntervalByIntervalDate(PlanningParameters, StageExecutor, IntervalDate)
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		
		PlacementInterval = InitializePlacementIntervalRoundClockOperation();
		PlacementInterval.WorkCenterType = StageExecutor.WorkCenterType;
		
		FillInPlacementIntervalRoundClockWork(PlanningParameters, StageExecutor, PlacementInterval, IntervalDate);
		
		If PlacementInterval <> Undefined
			And PlacementInterval.IntervalDate = IntervalDate Then
			Result = PlacementInterval;
		Else
			Result = Undefined;
		EndIf;
		
	Else
		
		If StageExecutor.ConsiderAvailability Then
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("WorkCenterType", StageExecutor.WorkCenterType);
			TheStructureOfTheSearch.Insert("IntervalDate", IntervalDate);
			
			FoundRows = PlanningParameters.WCKAvailability.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() = 1 
				And FoundRows[0].Available > 0 Then
				Result = FoundRows[0];
			Else
				Result = Undefined;
			EndIf;
			
		Else
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("WorkScheduleCalendar", StageExecutor.WorkScheduleCalendar);
			TheStructureOfTheSearch.Insert("IntervalDate", IntervalDate);
			
			FoundRows = PlanningParameters.BBVSchedule.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() = 1 Then
				Result = FoundRows[0];
			Else
				Result = Undefined;
			EndIf
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddVRCUpload(PlanningParameters, Stage, StageExecutor, PlacementParameters, PlacementInterval, Duration)
	
	NewRow = PlacementParameters.LoadingVRC.Add();
	NewRow.WorkCenterType = StageExecutor.WorkCenterType;
	NewRow.IntervalDate = PlacementInterval.IntervalDate;
	NewRow.EndOfTheInterval = PlacementInterval.EndOfShift;
	NewRow.Stage = Stage.ProductionStage;
	
	If StageExecutor.ConsiderAvailability Then
		
		If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
			NewRow.VRCAvailabilityLine = PlacementInterval.VRCAvailabilityLine;
		Else
			NewRow.VRCAvailabilityLine = PlacementInterval;
		EndIf;
		
	EndIf;
	
	NewRow.Busy = Duration;
	
EndProcedure

Function LoadingVRCOnInterval(Stage, StageExecutor,  PlacementInterval, ItRemainsToPlace)
	
	If StageExecutor.ConsiderAvailability And PlacementInterval.Available = 0 Then
		
		Result = 0;
		
	Else
		
		MaxLoadPerQuantum = MaximumLoadPerQuantum(Stage, StageExecutor);
		
		If StageExecutor.ConsiderAvailability Then
			
			Result = Min(ItRemainsToPlace, MaxLoadPerQuantum, PlacementInterval.Available);
			
		Else
			
			Result = Min(ItRemainsToPlace, MaxLoadPerQuantum);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function MaximumLoadPerQuantum(Stage, StageExecutor)
	
	QuantityOfBatches = ?(Int(Stage.QuantityOfBatches) = Stage.QuantityOfBatches,
		Stage.QuantityOfBatches,
		Int(Stage.QuantityOfBatches)+1);
	
	UnitsOfEquipment = ?(StageExecutor.ConsiderAvailability,
		Min(QuantityOfBatches, StageExecutor.NumberOfWorkCenters),
		QuantityOfBatches);
	
	Return StageExecutor.MaximumAvailability * UnitsOfEquipment;
	
EndFunction

Function DateOfInitialBBBInterval(PlanningParameters, Stage, TimeOfPlacement)
	
	If Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Return TimeOfPlacement;
	EndIf;
	
	NonStandardBoundaries = SchedulingIntervalHasNonStandardBoundaries(Stage);
	
	If NonStandardBoundaries Then
		
		If PlanningParameters.GoBackToBeginning Then
			
			TimeOfPlacementReferences = ResultInPlanningIntervalBoundary(
				TimeOfPlacement,
				Stage.PlanningInterval,
				Stage.PlanningIntervalStart);
				
			If TimeOfPlacement <= TimeOfPlacementReferences Then
				
				Result = LeadToBeginningOfPeriod(TimeOfPlacement, Stage.PlanningInterval);
				
			Else
				
				Result = LeadToEndOfPeriod(TimeOfPlacement, Stage.PlanningInterval);
				
			EndIf;
			
		Else
			
			TimeOfPlacementReferences = ResultInPlanningIntervalBoundary(
				TimeOfPlacement,
				Stage.PlanningInterval,
				Stage.PlanningIntervalEnd);
			
			If TimeOfPlacement >= TimeOfPlacementReferences Then
				
				Result = LeadToBeginningOfPeriod(TimeOfPlacement, Stage.PlanningInterval);
				
			Else
				
				Result = LeadToBeginningOfPeriod(
					LeadToBeginningOfPeriod(TimeOfPlacement, Stage.PlanningInterval)-1, Stage.PlanningInterval);
				
			EndIf;
			
		EndIf;
		
	Else
		
		TimeOfPlacementReferences = LeadToBeginningOfPeriod(TimeOfPlacement, Stage.PlanningInterval);
		If PlanningParameters.GoBackToBeginning Then
			
			If TimeOfPlacement = TimeOfPlacementReferences Then
				Result = TimeOfPlacement;
			Else
				Result = LeadToEndOfPeriod(TimeOfPlacement, Stage.PlanningInterval);
			EndIf;
			
		Else
			
			Result = LeadToBeginningOfPeriod(TimeOfPlacementReferences-1, Stage.PlanningInterval);
				
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CalculateVRCLoadingLimits(PlanningParameters, Stage, PlacementParameters)
	
	StartLoading = '39991231';
	EndOfDownload = '00010101';
	
	If Stage.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		For Each LoadingInterval In PlacementParameters.LoadingVRC Do
			StartLoading = Min(StartLoading, LoadingInterval.IntervalDate);
			EndOfDownload = Max(EndOfDownload, LoadingInterval.EndOfTheInterval);
		EndDo;
	Else
		For Each LoadingInterval In PlacementParameters.LoadingVRC Do
			StartLoading = Min(StartLoading, LoadingInterval.IntervalDate);
			EndOfDownload = Max(EndOfDownload, LoadingInterval.IntervalDate);
		EndDo;
		
		NonStandardBoundaries = SchedulingIntervalHasNonStandardBoundaries(Stage);
		
		If NonStandardBoundaries
			And Not PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
			
			StartLoading = ResultInPlanningIntervalBoundary(
				StartLoading,
				Stage.PlanningInterval,
				Stage.PlanningIntervalStart);
			
			EndOfDownload = ResultInPlanningIntervalBoundary(
				EndOfDownload,
				Stage.PlanningInterval,
				Stage.PlanningIntervalEnd) + 1;
			
		Else
			
			EndOfDownload = LeadToEndOfPeriod(
				EndOfDownload, Stage.PlanningInterval);
			
		EndIf;
	EndIf;
	
	PlacementParameters.PreliminaryBufferEnd = StartLoading;
	PlacementParameters.FollowUpBufferStart = EndOfDownload;
	
EndProcedure

Procedure CalculateStageBufferBoundaries(PlanningParameters, Stage, PlacementParameters, Cancel)
	
	// Placement of the pre-buffer.
	
	BufferEdISM = Stage.UnitOfMeasureOfPreliminaryBuffer;
	Buffer = ConsideredBufferSize(Stage.PreliminaryBuffer, BufferEdISM, Stage);
	PreliminaryBufferEnd = ?(
		ValueIsFilled(PlacementParameters.PreliminaryBufferEnd),
		PlacementParameters.PreliminaryBufferEnd,
		PlacementParameters.TimeOfPlacement);
	
	If ValueIsFilled(Buffer) Then
		
		PlacementResults = PlaceAccordingToUBBVSchedule(
			PlanningParameters,
			Stage.WorkScheduleCalendar,
			False,
			PreliminaryBufferEnd,
			Buffer,
			BufferEdISM);
		
		If PlacementResults.PlacementCompleted Then
			
			PlacementParameters.Begin = PlacementResults.Begin;
			
		Else
			
			Cancel = True;
			
		EndIf;
		
	Else
		
		PlacementParameters.Begin = PreliminaryBufferEnd;
		
	EndIf;
	
	// Placement of the terminating buffer.
	
	BufferEdISM = Stage.UnitOfMeasureOfFollowUpBuffer;
	Buffer = ConsideredBufferSize(Stage.FollowUpBuffer, BufferEdISM, Stage);
	FollowUpBufferStart = ?(
		ValueIsFilled(PlacementParameters.FollowUpBufferStart),
		PlacementParameters.FollowUpBufferStart,
		PlacementParameters.TimeOfPlacement);
	
	If ValueIsFilled(Buffer) Then
		
		PlacementResults = PlaceAccordingToUBBVSchedule(
			PlanningParameters,
			Stage.WorkScheduleCalendar,
			True,
			FollowUpBufferStart,
			Buffer,
			BufferEdISM);
		
		If PlacementResults.PlacementCompleted Then
			
			PlacementParameters.Ending = PlacementResults.Ending;
			
		Else
			
			Cancel = True;
			
		EndIf;
		
	Else
		
		PlacementParameters.Ending = FollowUpBufferStart;
		
	EndIf;
	
EndProcedure

Function SchedulingIntervalInSeconds(PlanningInterval, DateOfMonth = Undefined)
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		Result = 3600; // 60 * 60
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day
		Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Result = 86400; // 60 * 60 * 24
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		Result = 604800; // 60 * 60 * 24 * 7
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		If DateOfMonth = Undefined Then
			Result = 2592000; // 60 * 60 * 24 * 30
		Else
			Result = 60 * 60 * 24 * Day(EndOfMonth(DateOfMonth));
		EndIf;
	Else
		Result = 0;
	EndIf;
	
	Return Result;
	
EndFunction

Function ConsideredBufferSize(Buffer, BufferEdISM, Stage)
	
	If Stage.MinimumSignificantBuffer = 0 Then
		
		Result = Buffer;
		
	Else
		
		IntervalTime = SchedulingIntervalInSeconds(Stage.PlanningInterval);
		BufferTime = ProductionPlanningClientServer.GetTimeInSeconds(Buffer, BufferEdISM);
		
		If (BufferTime / IntervalTime * 100) >= Stage.MinimumSignificantBuffer Then
			
			Result = Buffer;
			
		Else
			
			Result = 0;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InitializePlacementIntervalRoundClockOperation()
	
	Result = New Structure;
	Result.Insert("WorkCenterType");
	Result.Insert("IntervalDate");
	Result.Insert("EndOfShift");
	Result.Insert("Available");
	Result.Insert("VRCAvailabilityLine");
	
	Return Result;
	
EndFunction

Procedure FillInPlacementIntervalRoundClockWork(
		PlanningParameters, StageExecutor, PlacementInterval, IntervalDate, ContinuousPlacement = True)
	
	MaximumAvailability = SchedulingIntervalInSeconds(StageExecutor.PlanningInterval, IntervalDate);
	
	If StageExecutor.ConsiderAvailability Then
		
		If StageExecutor.NumberOfWorkCenters = 0 Then
			
			PlacementInterval = Undefined;
			Return;
			
		EndIf;
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkCenterType", StageExecutor.WorkCenterType);
		
		While True Do
			
			AccessibilityStandard = MaximumAvailability * StageExecutor.NumberOfWorkCenters;
			
			TheStructureOfTheSearch.Insert("IntervalDate", IntervalDate);
			FoundRows = PlanningParameters.WCKAvailability.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() = 0 Then
				VRCAvailabilityLine = AddEntryToVRCAvailability(PlanningParameters, TheStructureOfTheSearch);
				LAvailability = AccessibilityStandard;
			Else
				VRCAvailabilityLine = FoundRows[0];
				LAvailability = AccessibilityStandard - VRCAvailabilityLine.Busy;
			EndIf;
			
			If LAvailability > 0 Then
				
				PlacementInterval.IntervalDate = IntervalDate;
				PlacementInterval.Available = LAvailability;
				PlacementInterval.VRCAvailabilityLine = VRCAvailabilityLine;
				Break;
				
			Else
				
				If PlanningParameters.GoBackToBeginning Then
					IntervalDate = LeadToEndOfPeriod(IntervalDate, StageExecutor.PlanningInterval);
				Else
					IntervalDate = LeadToBeginningOfPeriod(IntervalDate-1, StageExecutor.PlanningInterval);
				EndIf;
				
				MaximumAvailability = SchedulingIntervalInSeconds(StageExecutor.PlanningInterval, IntervalDate);
				
				ContinuousPlacement = False;
				
			EndIf;
			
		EndDo;
		
	Else
		
		PlacementInterval.IntervalDate = IntervalDate;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region PlanningSettings

// Parameters:
// 	NumberOfJobForCalculatingProductionSchedule - Undefined, Arbitrary, Number - LongDesc
// Returns:
// 	Structure - LongDesc:
// * NumberOfJobForCalculatingProductionSchedule - Undefined, Number -
// * UseAvailabilityReserve - Boolean -
// * ScheduleStatus - Number - 
// * Stages - Array of DocumentRef.ProductionStage2_2 -
// * Orders - DocumentRef.ProductionOrder2_2 -
// * CancelManualChangesOfSchedule - Boolean -
// * FullReplanning - Boolean -
// * NoOtherOrders - Boolean -
// * RoundTheClockWorkSevenDaysAWeek - Boolean -
// * UnlimitedEquipmentFleet - Boolean -
// * AllMaterialsInStock - Boolean -
// * ProductionOrder - DocumentRef.ProductionOrder2_2 -
// * ActivateTheAvailabilityReserveModel - Boolean -
// * PlanModel - Boolean -
// * ActivateTheAvailabilityReserveSchedule - Boolean -
// * PlanSchedule - Boolean -
Function InitializeSchedulingSettings(NumberOfJobForCalculatingProductionSchedule = Undefined)
	
	Result = New Structure;
	
	Settings = PreScheduleSchedulingSettings();
	For Each Item In Settings Do
		Result.Insert(Item.Key, Item.Value);
	EndDo;
	
	Result.Insert("Orders");
	Result.Insert("Stages");
	Result.Insert("ScheduleStatus", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Result.Insert("UseAvailabilityReserve", Undefined);
	
	If NumberOfJobForCalculatingProductionSchedule = Undefined Then
		NumberOfJobForCalculatingProductionSchedule = FixTaskNumberForCalculatingProductionSchedule();
	EndIf;
	Result.Insert("NumberOfJobForCalculatingProductionSchedule", NumberOfJobForCalculatingProductionSchedule);
	
	Return Result;
	
EndFunction

// Wrapper for preparing settings - calculation of the preliminary order schedule
//
Function PlanningSettingsPreliminarySchedule(ExternalSettings, NumberOfJobForCalculatingProductionSchedule)
	
	PlanningSettings = InitializeSchedulingSettings(NumberOfJobForCalculatingProductionSchedule);
	FillPropertyValues(PlanningSettings, ExternalSettings);
	
	PlanningSettings.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule();
	PlanningSettings.UseAvailabilityReserve = ExternalSettings.ActivateTheAvailabilityReserveSchedule;
	
	PlanningSettings.AllMaterialsInStock = False;
	PlanningSettings.UnlimitedEquipmentFleet = False;
	PlanningSettings.RoundTheClockWorkSevenDaysAWeek = False;
	PlanningSettings.NoOtherOrders = False;
	
	Return PlanningSettings;
	
EndFunction

// Wrapper for preparing settings - calculation of the order schedule model
//
Function SchedulingSettingsGraphModel(ExternalSettings, NumberOfJobForCalculatingProductionSchedule)
	
	PlanningSettings = InitializeSchedulingSettings(NumberOfJobForCalculatingProductionSchedule);
	FillPropertyValues(PlanningSettings, ExternalSettings);
	
	PlanningSettings.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel();
	PlanningSettings.UseAvailabilityReserve = ExternalSettings.ActivateTheAvailabilityReserveModel;
	
	Return PlanningSettings;
	
EndFunction

#EndRegion

#Region PlanningParameters

Function PlanningParameters(PlanningSettings, ChangePlanningDirection, Cancel)
	
	PlanningParameters = InitializePlanningParameters(PlanningSettings);
	FillPropertyValues(PlanningParameters, PlanningSettings);
	
	PlanningParameters.PlanningResults = InitializeSchedulingResultsParameter(PlanningParameters);
	
	ReadUpdateOrderDetails(PlanningParameters, PlanningSettings.ProductionOrder, True);
	
	ChangePlanningDirection(PlanningParameters, ChangePlanningDirection);
	
	ReadStagesWithDependencies(
		PlanningParameters,
		PlanningSettings.ProductionOrder,
		PlanningSettings.Stages,
		Cancel);
		
	If Not Cancel Then
		
		ReadStagePerformers(PlanningParameters);
		READSecurityDates(PlanningParameters);
		ReadVRCAvailability(PlanningParameters);
		ReadBBVSchedule(PlanningParameters);
		ReadUBBWSchedule(PlanningParameters);
		
		InitializeProductionScheduleParameter(PlanningParameters);
		InitializeLoadingVRCParameter(PlanningParameters);
		
	EndIf;
	
	Return PlanningParameters;
	
EndFunction

// Constructor of a structure that describes parameters for calculating the production schedule.
// 
// Parameters:
// 	PlanningSettings - See InitializeSchedulingSettings
// Returns:
// 	Structure - LongDesc:
// * PlanningResults - See InitializeSchedulingResultsParameter
// * LoadingVRC - See InitializeVRCDownloadAccountingTable
// * ProductionSchedule - ValueTable - Where:
// ** ProductionScheduling - EnumRef.WayOfLinkingProductionOperations -
// ** EquipmentLimited - Boolean -
// ** MaterialLimited - Boolean -
// ** ItLimitsProductionDate - Boolean -
// ** OnCriticalPath - Boolean -
// ** NextStageStart - Date -
// ** FollowUpBufferStart - Date -
// ** PreliminaryBufferEnd - Date -
// ** Ending - Date -
// ** Begin - Date -
// ** Stage - DocumentRef.ProductionStage2_2 -
// * UbbwSchedule - See UbbwSchedule
// * BBVSchedule - See BBVSchedule
// * WCKAvailability - ValueTable - Where:
// ** WorkCenterType - CatalogRef.WorkCenterTypes -
// ** IntervalDate - Date -
// ** Enabled - Number -
// ** Busy - Number -
// * LoadingManuallyPlacedStages - ValueTable - 
// * GraphOfManuallyPlacedStages - ValueTable - 
// * PreviousStagesOfProduction - Array - 
// * StagePerformers_ - ValueTable - 
// * StageDependencies - ValueTable - 
// * Stages - ValueTable - 
// * DatesOfProvision - ValueTable - 
// * ChangePlanningDirection - Boolean -
// * GoBackToBeginning - Boolean - 
// * DemandDate - Date -
// * EarliestStartDate - Date - 
// * ProductionOrder - DocumentRef.ProductionOrder2_2 -
// * CancelManualChangesOfSchedule - Boolean -
// * FullReplanning - Boolean -
// * NoOtherOrders - Boolean -
// * RoundTheClockWorkSevenDaysAWeek - Boolean -
// * UnlimitedEquipmentFleet - Boolean -
// * AllMaterialsInStock - Boolean -
// * ActivateTheAvailabilityReserveModel - Boolean -
// * PlanModel - Boolean -
// * ActivateTheAvailabilityReserveSchedule - Boolean -
// * PlanSchedule - Boolean -
Function InitializePlanningParameters(PlanningSettings)
	
	Result = New Structure;
	
	Result.Insert("ProductionOrder");
	Result.Insert("EarliestStartDate");
	Result.Insert("DemandDate");
	Result.Insert("GoBackToBeginning");
	Result.Insert("ChangePlanningDirection", False);
	Result.Insert("DatesOfProvision");
	
	Result.Insert("Stages");
	Result.Insert("StagesPlaced");
	Result.Insert("StageDependencies");
	Result.Insert("StagePerformers_");
	Result.Insert("PreviousStagesOfProduction");
	
	Result.Insert("GraphOfManuallyPlacedStages");
	Result.Insert("LoadingManuallyPlacedStages");
	
	Result.Insert("WCKAvailability");
	Result.Insert("BBVSchedule");
	Result.Insert("UbbwSchedule");
	
	Result.Insert("ProductionSchedule");
	Result.Insert("LoadingVRC");
	Result.Insert("PlanningResults");
	
	For Each Setting In PlanningSettings Do
		Result.Insert(Setting.Key);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure ReadUpdateOrderDetails(PlanningParameters, OrderDocument, ToChangeOrder) Export
	
	Query = New Query(
		"SELECT
		|	ProductionOrder2_2.Ref                         AS ProductionOrder,
		|	ProductionOrder2_2.Number                          AS Number,
		|	ProductionOrder2_2.EarliestStartDate                  AS EarliestStartDate,
		|	ProductionOrder2_2.DemandDate                AS DemandDate,
		|	ProductionOrder2_2.UseAvailabilityReserve AS UseAvailabilityReserve,
		|	CASE
		|		WHEN ProductionOrder2_2.ProductionScheduling = VALUE(Enum.WayOfLinkingProductionOperations.Backward)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                 AS GoBackToBeginning
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrder2_2
		|WHERE
		|	ProductionOrder2_2.Ref = &OrderDocument");
	Query.SetParameter("OrderDocument", OrderDocument);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(PlanningParameters, Selection,
		"ProductionOrder, EarliestStartDate, DemandDate, GoBackToBeginning");
	
	If PlanningParameters.UseAvailabilityReserve = Undefined Then
		PlanningParameters.UseAvailabilityReserve = Selection.UseAvailabilityReserve;
	ElsIf PlanningParameters.UseAvailabilityReserve <> Selection.UseAvailabilityReserve
		And PlanningParameters.ScheduleStatus <> InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel()
		And ToChangeOrder Then
		
		DocumentObject = OrderDocument.GetObject();
		Try
			DocumentObject.Lock();
			DocumentObject.UseAvailabilityReserve = PlanningParameters.UseAvailabilityReserve;
			DocumentObject.DataExchange.Load = True;
			DocumentObject.Write(DocumentWriteMode.Write);
			DocumentObject.Unlock();
		Except
			Event = NStr("vi = 'Đơn hàng sản xuất';
						|ru = 'Заказ на производство';
						|en = 'Production order'; fa = 'سفارش تولید';
						|it = 'Ordine di produzione';
						|pl = 'Zlecenie produkcyjne';
						|tr = 'Üretim emri'", Common.DefaultLanguageCode()) + "."
					+ NStr("vi = 'Thay đổi khi tính lịch';
							|ru = 'Изменение при расчете графика';
							|en = 'Change upon schedule calculation'; fa = 'Change upon schedule calculation';
							|it = 'Change upon schedule calculation';
							|pl = 'Change upon schedule calculation';
							|tr = 'Takvim hesaplama sırasında değişiklik'", Common.DefaultLanguageCode());
			
			WriteLogEvent(
				Event,
				EventLogLevel.Error,
				OrderDocument.Metadata(),
				OrderDocument,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(
				Selection.Number, False, True);
			
			If PlanningParameters.UseAvailabilityReserve Then
				Notification = StrTemplate(
					NStr("vi = 'Không thể thay đổi đơn hàng sản xuất %1 (thiết lập dấu hiệu Sử dụng dự phòng khả dụng).
						|Có thể đơn hàng đang được mở bởi người dùng khác hoặc đã bắt đầu chỉnh sửa đơn hàng.';
						|ru = 'Не удалось изменить заказ на производство %1 (установка признака Задействовать резерв доступности).
						|Возможно, заказ открыт другим пользователем или начато редактирование заказа.';
						|en = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.'; fa = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|it = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|pl = 'Cannot change the %1 production order (select the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|tr = '%1 üretim emri değiştirilemedi (Rezerve edilmiş kapasiteyi kullan bayrağı ayarlama).
						|Emir başka bir kullanıcı tarafından açık olabilir veya emrin düzenlemesine başlanmış olabilir.'"),
					OrderNumber);
			Else
				Notification = StrTemplate(
					NStr("vi = 'Không thể thay đổi đơn hàng sản xuất %1 (bỏ dấu hiệu Sử dụng dự phòng khả dụng).
						|Có thể đơn hàng đang được mở bởi người dùng khác hoặc đã bắt đầu chỉnh sửa đơn hàng.';
						|ru = 'Не удалось изменить заказ на производство %1 (снятие признака Задействовать резерв доступности).
						|Возможно, заказ открыт другим пользователем или начато редактирование заказа.';
						|en = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.'; fa = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|it = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|pl = 'Cannot change the %1 production order (clear the ""Use reserved work center capacity"" checkbox).
						|The order may be opened by another user or being edited.';
						|tr = '%1 üretim emri değiştirilemedi (Rezerve edilmiş kapasiteyi kullan bayrağı kaldırma).
						|Emir başka bir kullanıcı tarafından açık olabilir veya emrin düzenlemesine başlanmış olabilir.'"),
					OrderNumber);
			EndIf;
			
			PlanningParameters.PlanningResults.Notifications.Insert(Notification, Undefined);
		EndTry;
	EndIf;
	
EndProcedure

Procedure ChangePlanningDirection(PlanningParameters, ChangePlanningDirection)
	
	If ChangePlanningDirection Then
		
		PlanningParameters.GoBackToBeginning = Not PlanningParameters.GoBackToBeginning;
		
	ElsIf Not PlanningParameters.GoBackToBeginning And PlanningParameters.DemandDate <= CurrentSessionDate() Then
		
		AddNotificationWhenPlanningDirectionChanges(PlanningParameters);
		PlanningParameters.GoBackToBeginning = True;
		
	EndIf;
	
EndProcedure

Procedure ReadStagesWithDependencies(PlanningParameters, ReferenceOrder, ArrayOfStages, Cancel)
	
	TempTablesManager = New TempTablesManager;
	
	Documents.ProductionStage2_2.CreateTTCommunicationStagesByOrder(
		TempTablesManager,
		ReferenceOrder,
		False);
	
	Query = InitializeRequestStepsWithDependencies(PlanningParameters, ReferenceOrder, ArrayOfStages);
	Query.TempTablesManager = TempTablesManager;
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	MaxIndex_ = ResultsArray.UBound();
	
	Stages = ResultsArray[MaxIndex_-4].Unload();// ValueTable - 
	
	If Stages.Count() > 0 Then
		
		AddServiceColumnsToStages(Stages);
		Stages.Indexes.Add("ProductionStage");
		Stages.Indexes.Add("Allocate");
		Stages.Indexes.Add("Posted_");
		PlanningParameters.Stages = Stages;
		PlanningParameters.StagesPlaced = ArrayOfStagesToPlace(PlanningParameters);
		
		StageDependencies = ResultsArray[MaxIndex_-3].Unload();// ValueTable - 
		StageDependencies.Indexes.Add("ProductionStage");
		StageDependencies.Indexes.Add("NextStage");
		PlanningParameters.StageDependencies = StageDependencies;
		
		PreviousStages_ = ResultsArray[MaxIndex_-2].Unload();
		If PreviousStages_.Find(True, "NoSchedule") = Undefined Then
			FillInDateOfPlacementOfPreviousStages(
				PlanningParameters, PreviousStages_);
		Else
			FixErrorsThereIsNoScheduleOfPreviousStages(
				PlanningParameters, PreviousStages_);
			Cancel = True;
		EndIf;
		PlanningParameters.PreviousStagesOfProduction = PreviousStages_.UnloadColumn("ProductionStage");
		
		GraphOfManuallyPlacedStages = ResultsArray[MaxIndex_-1].Unload();// ValueTable - 
		GraphOfManuallyPlacedStages.Indexes.Add("ProductionStage");
		PlanningParameters.GraphOfManuallyPlacedStages = GraphOfManuallyPlacedStages;
		
		LoadingManuallyPlacedStages = ResultsArray[MaxIndex_].Unload();// ValueTable - 
		LoadingManuallyPlacedStages.Indexes.Add("Stage");
		PlanningParameters.LoadingManuallyPlacedStages = LoadingManuallyPlacedStages;
		
	Else
		
		AddAlertMissingStagesForPlanning(PlanningParameters);
		Cancel = True;
		
	EndIf;
	
EndProcedure

Function InitializeRequestStepsWithDependencies(PlanningParameters, ReferenceOrder, ArrayOfStages)
	
	BatchQueryText = New Array;
	
	QueryText = 
	"SELECT
	|	MAX(&SortByDurationField) AS DurationUntilLaunchRelease
	|INTO NumberOfFirstIrrelevantStage
	|FROM
	|	InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
	|WHERE
	|	NOT &FullReplanning
	|	AND StandardScheduleOfProductionStages.ProductionStage IN
	|			(SELECT
	|				T.ProductionStage AS ProductionStage
	|			FROM
	|				InformationRegister.JobsToProductionScheduleCalculation AS T
	|			WHERE
	|				T.ReferenceOrder = &ReferenceOrder
	|				AND T.JobNumber <= &NumberOfJobForCalculatingProductionSchedule)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStage2_2.Ref AS ProductionStage,
	|	&PlanningByProductionResourcesIsUsed
	|		AND (ProductionStage2_2.PlanOperationsOfWorkCenterTypes
	|			OR ProductionStage2_2.StagePlacementInProductionSchedule
	|				AND &CancelManualChangesOfSchedule
	|				AND TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						Document.ProductionStage2_2.WorkCenterTypes AS T
	|					WHERE
	|						T.Ref = ProductionStage2_2.Ref)) AS PlanOperationsOfWorkCenterTypes
	|INTO TTStages
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|		INNER JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
	|		ON ProductionStage2_2.Ref = StandardScheduleOfProductionStages.ProductionStage
	|		LEFT JOIN NumberOfFirstIrrelevantStage AS NumberOfFirstIrrelevantStage
	|		ON (NOT &FullReplanning)
	|WHERE
	|	ProductionStage2_2.ReferenceOrder = &ReferenceOrder
	|	AND ProductionStage2_2.Posted
	|	AND ProductionStage2_2.Status IN(&StageStatuses_2)
	|	AND (NOT &FilterByStages
	|				AND &FullReplanning
	|			OR &FilterByStages
	|				AND ProductionStage2_2.Ref IN (&Stages)
	|			OR NOT &FullReplanning
	|				AND &SortByDurationField <= NumberOfFirstIrrelevantStage.DurationUntilLaunchRelease)
	|
	|INDEX BY
	|	ProductionStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ProductionStage AS ProductionStage,
	|	MIN(NestedQuery.WorkCenterType.MinimumSignificantBuffer) AS MinimumSignificantBuffer
	|INTO TTSignificantBuffers
	|FROM
	|	(SELECT
	|		WorkCenterTypes.Ref AS ProductionStage,
	|		WorkCenterTypes.WorkCenterType AS WorkCenterType
	|	FROM
	|		Document.ProductionStage2_2.WorkCenterTypes AS WorkCenterTypes
	|	WHERE
	|		WorkCenterTypes.Ref IN
	|				(SELECT
	|					TTStages.ProductionStage
	|				FROM
	|					TTStages
	|				WHERE
	|					TTStages.PlanOperationsOfWorkCenterTypes)
	|		AND WorkCenterTypes.Use
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AlternateWorkCenterTypes.Ref,
	|		AlternateWorkCenterTypes.WorkCenterType
	|	FROM
	|		Document.ProductionStage2_2.AlternateWorkCenterTypes AS AlternateWorkCenterTypes
	|	WHERE
	|		AlternateWorkCenterTypes.Ref IN
	|				(SELECT
	|					TTStages.ProductionStage
	|				FROM
	|					TTStages
	|				WHERE
	|					TTStages.PlanOperationsOfWorkCenterTypes)
	|		AND AlternateWorkCenterTypes.Use) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.ProductionStage
	|
	|INDEX BY
	|	ProductionStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCommunicationStages.Stage AS ProductionStage,
	|	TTCommunicationStages.NextStage AS NextStage
	|INTO TTDependencies
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|WHERE
	|	(TTCommunicationStages.Stage IN
	|				(SELECT
	|					TTStages.ProductionStage
	|				FROM
	|					TTStages)
	|			OR TTCommunicationStages.NextStage IN
	|				(SELECT
	|					TTStages.ProductionStage
	|				FROM
	|					TTStages))
	|
	|INDEX BY
	|	ProductionStage,
	|	NextStage";
	BatchQueryText.Add(QueryText);
	
	QueryText = InformationRegisters.ScheduleOfProductionStages2_2.QueryTextTTTermsOfStages(
		"TTDependencies", "&VTDependencyFieldIsSynonymOfPredecessor");
	BatchQueryText.Add(QueryText);
	
	QueryText = 
	"SELECT
	|	TTDependencies1.ProductionStage AS ProductionStage
	|INTO TTFirstStagesOfUBBV
	|FROM
	|	TTDependencies AS TTDependencies1
	|		LEFT JOIN TTDependencies AS TTDependencies2
	|		ON TTDependencies1.ProductionStage = TTDependencies2.NextStage
	|			AND (CAST(TTDependencies2.ProductionStage AS Document.ProductionStage2_2).ProductionLot = CAST(TTDependencies2.NextStage AS Document.ProductionStage2_2).ProductionLot)
	|WHERE
	|	TTDependencies1.ProductionStage IN
	|			(SELECT
	|				TTStages.ProductionStage
	|			FROM
	|				TTStages
	|			WHERE
	|				NOT TTStages.PlanOperationsOfWorkCenterTypes)
	|	AND TTDependencies2.NextStage IS NULL
	|	AND &PlanningByProductionResourcesIsUsed
	|
	|GROUP BY
	|	TTDependencies1.ProductionStage
	|
	|HAVING
	|	SUM(1) = 1
	|
	|INDEX BY
	|	ProductionStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTDependencies.NextStage AS ProductionStage
	|INTO TTOffsetOfUBBWStages
	|FROM
	|	TTDependencies AS TTDependencies
	|		INNER JOIN TTFirstStagesOfUBBV AS TTFirstStagesOfUBBV
	|		ON TTDependencies.ProductionStage = TTFirstStagesOfUBBV.ProductionStage
	|			AND (CAST(TTDependencies.ProductionStage AS Document.ProductionStage2_2).ProductionLot = CAST(TTDependencies.NextStage AS Document.ProductionStage2_2).ProductionLot)
	|WHERE
	|	TTDependencies.NextStage IN
	|		(SELECT
	|			TTStages.ProductionStage
	|		FROM
	|			TTStages
	|		WHERE
	|			TTStages.PlanOperationsOfWorkCenterTypes)
	|
	|INDEX BY
	|	ProductionStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CAST(&VTDependencyFieldIsPredecessor AS Document.ProductionStage2_2) AS ProductionStage,
	|	ScheduleOfStages.StageStart AS StageStart,
	|	CASE
	|		WHEN ScheduleOfStages.StageEnd IS NOT NULL 
	|			THEN DATEADD(ScheduleOfStages.StageEnd, SECOND, 1)
	|		ELSE NULL
	|	END AS StageEnd,
	|	CASE
	|		WHEN ScheduleOfStages.ProductionStage IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NoSchedule
	|INTO TTStagesPredecessors
	|FROM
	|	TTStages AS TTStages
	|		INNER JOIN TTDependencies AS TTDependencies
	|			LEFT JOIN TTTermsOfStages AS ScheduleOfStages
	|			ON (&VTDependencyFieldIsPredecessor = ScheduleOfStages.ProductionStage)
	|		ON (TTStages.ProductionStage = &TTFollowerField)
	|WHERE
	|	NOT &VTDependencyFieldIsPredecessor IN
	|				(SELECT
	|					TTStages.ProductionStage
	|				FROM
	|					TTStages)
	|	AND &VTDependencyFieldStatusPredecessor <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|
	|INDEX BY
	|	ProductionStage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTStages.ProductionStage AS ProductionStage
	|INTO TTAllStages
	|FROM
	|	TTStages AS TTStages
	|
	|UNION
	|
	|SELECT
	|	TTStagesPredecessors.ProductionStage
	|FROM
	|	TTStagesPredecessors AS TTStagesPredecessors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStage2_2.Ref                                 AS ProductionStage,
	|	ProductionStage2_2.ProductionByThirdParty                  AS ProductionByThirdParty,
	|	ProductionStage2_2.ProductionLot                     AS ProductionLot,
	|	ProductionStage2_2.Continuous_                            AS Continuous_,
	|	ISNULL(TTStages.PlanOperationsOfWorkCenterTypes,
	|		ProductionStage2_2.PlanOperationsOfWorkCenterTypes
	|		AND &PlanningByProductionResourcesIsUsed) AS PlanOperationsOfWorkCenterTypes,
	|	ProductionStage2_2.OperatingProcedureOfWorkCenterTypes       AS OperatingProcedureOfWorkCenterTypes,
	|	ProductionStage2_2.StageDuration                      AS StageDuration,
	|	CASE
	|		WHEN ProductionStage2_2.UnitOfMeasureOfStageDuration = VALUE(Enum.TimeMeasureUnits.EmptyRef)
	|			THEN &TheBasicUnitOfTimeForTheDurationOfTheUBBWStage
	|		ELSE ProductionStage2_2.UnitOfMeasureOfStageDuration
	|	END                                                      AS UnitOfMeasureOfStageDuration,
	|	ProductionStage2_2.PreliminaryBuffer                   AS PreliminaryBuffer,
	|	ProductionStage2_2.FollowUpBuffer                       AS FollowUpBuffer,
	|	ProductionStage2_2.UnitOfMeasureOfPreliminaryBuffer AS UnitOfMeasureOfPreliminaryBuffer,
	|	ProductionStage2_2.UnitOfMeasureOfFollowUpBuffer     AS UnitOfMeasureOfFollowUpBuffer,
	|	ISNULL(TTSignificantBuffers.MinimumSignificantBuffer, 0)     AS MinimumSignificantBuffer,
	|	ProductionStage2_2.StageName                      AS StageName,
	|	ProductionStage2_2.Number                                  AS StageNumber,
	|	CASE
	|		WHEN ProductionStage2_2.QuantityPerReleaseLotUnit = 0
	|			THEN 1
	|		ELSE ProductionStage2_2.NumberOfPackagesPlan
	|				* ISNULL(&CoefficientPackingPlan, 1)
	|				/ ProductionStage2_2.QuantityPerReleaseLotUnit
	|	END                                                      AS QuantityOfBatches,
	|	ProductionStage2_2.Department                          AS Department,
	|	CASE
	|		WHEN &RoundTheClockWorkSevenDaysAWeek
	|			AND ProductionStage2_2.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|		ELSE ProductionStage2_2.Department.PlanningInterval
	|	END                                                            AS PlanningInterval,
	|	ProductionStage2_2.Department.PlanningIntervalStart    AS PlanningIntervalStart,
	|	ProductionStage2_2.Department.PlanningIntervalEnd AS PlanningIntervalEnd,
	|	ProductionStage2_2.StagePlacementInProductionSchedule               AS StagePlacementInProductionSchedule,
	|	0                                                          AS WorkScheduleCalendar,
	|	CASE
	|		WHEN VALUETYPE(ProductionStage2_2.PlanNotEarlierThan) = TYPE(DATE)
	|			THEN ProductionStage2_2.PlanNotEarlierThan
	|		WHEN NOT &GoBackToBeginning
	|				AND ProductionStage2_2.PlanNotEarlierThan REFS Document.ProductionStage2_2
	|				AND ProductionStage2_2.PlanNotEarlierThan <> VALUE(Document.ProductionStage2_2.EmptyRef)
	|				AND NOT TRUE IN
	|					(SELECT TOP 1
	|						TRUE
	|					FROM
	|						TTStages AS Stages
	|					WHERE
	|						Stages.ProductionStage = ProductionStage2_2.PlanNotEarlierThan)
	|			THEN ISNULL(ScheduleToPlanNoEarlier.Ending, DATETIME(1, 1, 1))
	|		ELSE DATETIME(1, 1, 1)
	|	END                                                      AS PlanNotEarlierThan,
	|	TTOffsetOfUBBWStages.ProductionStage IS NOT NULL         AS OffsetPriorStagesOfUBBV,
	|	TTStages.ProductionStage IS NOT NULL                      AS Allocate,
	|	&SortByDurationField                              AS SortByDurationField
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|		LEFT JOIN InformationRegister.StandardScheduleOfProductionStages AS StandardScheduleOfProductionStages
	|		ON ProductionStage2_2.Ref = StandardScheduleOfProductionStages.ProductionStage
	|		LEFT JOIN TTSignificantBuffers AS TTSignificantBuffers
	|		ON ProductionStage2_2.Ref = TTSignificantBuffers.ProductionStage
	|		LEFT JOIN TTOffsetOfUBBWStages AS TTOffsetOfUBBWStages
	|		ON ProductionStage2_2.Ref = TTOffsetOfUBBWStages.ProductionStage
	|		LEFT JOIN TTStages AS TTStages
	|		ON ProductionStage2_2.Ref = TTStages.ProductionStage
	|		LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleToPlanNoEarlier
	|		ON ProductionStage2_2.PlanNotEarlierThan = ScheduleToPlanNoEarlier.Stage
	|			AND ScheduleToPlanNoEarlier.ScheduleStatus = &ScheduleStatus
	|WHERE
	|	ProductionStage2_2.Ref IN
	|			(SELECT
	|				TTAllStages.ProductionStage
	|			FROM
	|				TTAllStages)
	|
	|ORDER BY
	|	&SortByDurationField DESC,
	|	StandardScheduleOfProductionStages.ResourceIntensity DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTDependencies.ProductionStage AS ProductionStage,
	|	TTDependencies.NextStage    AS NextStage
	|FROM
	|	TTDependencies AS TTDependencies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTStagesPredecessors.ProductionStage                    AS ProductionStage,
	|	TTStagesPredecessors.StageStart                         AS StageStart,
	|	TTStagesPredecessors.StageEnd                      AS StageEnd,
	|	TTStagesPredecessors.NoSchedule                   AS NoSchedule,
	|	TTStagesPredecessors.ProductionStage.ReferenceOrder       AS ReferenceOrder,
	|	TTStagesPredecessors.ProductionStage.ReferenceOrder.Number AS OrderNumber__
	|FROM
	|	TTStagesPredecessors AS TTStagesPredecessors
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleOfProductionStages2_2.Stage                            AS ProductionStage,
	|	ScheduleOfProductionStages2_2.Begin                          AS Begin,
	|	ScheduleOfProductionStages2_2.Ending                       AS Ending,
	|	ScheduleOfProductionStages2_2.PreliminaryBufferEnd AS PreliminaryBufferEnd,
	|	ScheduleOfProductionStages2_2.FollowUpBufferStart        AS FollowUpBufferStart
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.Stage IN
	|			(SELECT
	|				TTStages.ProductionStage
	|			FROM
	|				TTStages)
	|	AND ScheduleOfProductionStages2_2.Stage.StagePlacementInProductionSchedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionStage2_2OccupancyOfWorkCenterTypes.Ref            AS Stage,
	|	ProductionStage2_2OccupancyOfWorkCenterTypes.WorkCenterType AS WorkCenterType,
	|	ProductionStage2_2OccupancyOfWorkCenterTypes.IntervalDate     AS IntervalDate,
	|	ProductionStage2_2OccupancyOfWorkCenterTypes.Count        AS Busy
	|FROM
	|	Document.ProductionStage2_2.OccupancyOfWorkCenterTypes AS ProductionStage2_2OccupancyOfWorkCenterTypes
	|WHERE
	|	ProductionStage2_2OccupancyOfWorkCenterTypes.Ref IN
	|			(SELECT
	|				TTStages.ProductionStage
	|			FROM
	|				TTStages)
	|	AND ProductionStage2_2OccupancyOfWorkCenterTypes.Ref.StagePlacementInProductionSchedule";
	BatchQueryText.Add(QueryText);
	
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	QueryText = StrConcat(BatchQueryText, Separator);
	
	If PlanningParameters.GoBackToBeginning Then
		
		QueryText = StrReplace(QueryText,
			"&SortByDurationField",
			"StandardScheduleOfProductionStages.DurationBeforeProductionIssue");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldIsPredecessor",
			"TTDependencies.ProductionStage");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldIsSynonymOfPredecessor",
			"ProductionStage");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldStatusPredecessor",
			"TTDependencies.ProductionStage.Status");
		QueryText = StrReplace(QueryText,
			"&TTFollowerField",
			"TTDependencies.NextStage");
		
	Else
		
		QueryText = StrReplace(QueryText,
			"&SortByDurationField",
			"StandardScheduleOfProductionStages.DurationBeforeStart");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldIsPredecessor",
			"TTDependencies.NextStage");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldIsSynonymOfPredecessor",
			"NextStage");
		QueryText = StrReplace(QueryText,
			"&VTDependencyFieldStatusPredecessor",
			"TTDependencies.NextStage.Status");
		QueryText = StrReplace(QueryText,
			"&TTFollowerField",
			"TTDependencies.ProductionStage");
		
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&CoefficientPackingPlan",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductionStage2_2.PackagePlan",
			"ProductionStage2_2.ProductionLot.MainProductProducts"));
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("GoBackToBeginning", PlanningParameters.GoBackToBeginning);
	Query.SetParameter("FilterByStages", ValueIsFilled(ArrayOfStages));
	Query.SetParameter("Stages", ?(ValueIsFilled(ArrayOfStages), ArrayOfStages, New Array));
	Query.SetParameter("FullReplanning", PlanningParameters.FullReplanning);
	Query.SetParameter("NumberOfJobForCalculatingProductionSchedule",
		PlanningParameters.NumberOfJobForCalculatingProductionSchedule);
	Query.SetParameter("TheBasicUnitOfTimeForTheDurationOfTheUBBWStage",
		Catalogs.ProductionStages.TheBasicUnitOfTimeForTheDurationOfTheUBBWStage());
	Query.SetParameter("ScheduleStatus",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("StageStatuses_2", StatusesStageCanBeScheduled());
	Query.SetParameter("PlanningByProductionResourcesIsUsed",
		PlanningByProductionResourcesIsUsed());
	Query.SetParameter("CancelManualChangesOfSchedule",
		PlanningParameters.CancelManualChangesOfSchedule);
	Query.SetParameter("ScheduleStatus",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("RoundTheClockWorkSevenDaysAWeek",
		PlanningParameters.RoundTheClockWorkSevenDaysAWeek);
	
	Return Query;
	
EndFunction

Procedure AddServiceColumnsToStages(Stages)
	
	Stages.Columns.Add("DateOfPreviousPosts", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	Stages.Columns.Add("Posted_", New TypeDescription("Boolean"));
	
EndProcedure

Procedure FillInDateOfPlacementOfPreviousStages(PlanningParameters, PreviousStages_)
	
	For Each String In PreviousStages_ Do
		
		Stage = PlanningParameters.Stages.Find(String.ProductionStage, "ProductionStage");
		If Not Stage = Undefined Then
			
			FillInPlacementDateForSubsequentStages(
				PlanningParameters,
				Stage,
				String.StageStart,
				String.StageEnd);
				
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadStagePerformers(PlanningParameters)
	
	Query = New Query(
	"SELECT
	|	WorkCenterTypes.Ref AS ProductionStage,
	|	WorkCenterTypes.WorkCenterType AS WorkCenterType,
	|	WorkCenterTypes.UnitOfMeasure AS UnitOfMeasure,
	|	WorkCenterTypes.OperationTime AS OperationTime,
	|	WorkCenterTypes.LineNumber AS LineNumber
	|INTO TTPerformers
	|FROM
	|	Document.ProductionStage2_2.WorkCenterTypes AS WorkCenterTypes
	|WHERE
	|	WorkCenterTypes.Ref IN(&ProductionStages)
	|	AND WorkCenterTypes.Use
	|	AND &PlanningByProductionResourcesIsUsed
	|	AND (WorkCenterTypes.Ref.PlanOperationsOfWorkCenterTypes
	|			OR WorkCenterTypes.Ref.StagePlacementInProductionSchedule
	|				AND &CancelManualChangesOfSchedule)
	|
	|UNION ALL
	|
	|SELECT
	|	AlternateWorkCenterTypes.Ref,
	|	AlternateWorkCenterTypes.WorkCenterType,
	|	AlternateWorkCenterTypes.UnitOfMeasure,
	|	AlternateWorkCenterTypes.OperationTime,
	|	WorkCenterTypes.LineNumber
	|FROM
	|	Document.ProductionStage2_2.AlternateWorkCenterTypes AS AlternateWorkCenterTypes
	|		LEFT JOIN Document.ProductionStage2_2.WorkCenterTypes AS WorkCenterTypes
	|		ON AlternateWorkCenterTypes.Ref = WorkCenterTypes.Ref
	|			AND AlternateWorkCenterTypes.LinkKeyWorkCenterTypes = WorkCenterTypes.ConnectionKey
	|WHERE
	|	AlternateWorkCenterTypes.Ref IN(&ProductionStages)
	|	AND AlternateWorkCenterTypes.Use
	|	AND &PlanningByProductionResourcesIsUsed
	|	AND (AlternateWorkCenterTypes.Ref.PlanOperationsOfWorkCenterTypes
	|			OR AlternateWorkCenterTypes.Ref.StagePlacementInProductionSchedule
	|				AND &CancelManualChangesOfSchedule)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPerformers.ProductionStage AS ProductionStage,
	|	TTPerformers.WorkCenterType AS WorkCenterType,
	|	CASE
	|		WHEN &UnlimitedEquipmentFleet
	|			THEN FALSE
	|		ELSE TTPerformers.WorkCenterType.UseAvailabilityAccordingToSchedule
	|	END AS ConsiderAvailability,
	|	0 AS WorkScheduleCalendar,
	|	CASE
	|		WHEN &RoundTheClockWorkSevenDaysAWeek
	|			AND TTPerformers.ProductionStage.Department.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|		ELSE TTPerformers.ProductionStage.Department.PlanningInterval
	|	END AS PlanningInterval,
	|	CASE
	|		WHEN &RoundTheClockWorkSevenDaysAWeek 
	|			THEN CASE TTPerformers.ProductionStage.Department.PlanningInterval
	|				WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|					THEN &MaximumAvailabilityDay
	|				WHEN VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|					THEN &MaximumAvailabilityDay
	|				WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|					THEN &MaximumAvailabilityWeek
	|				WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|					THEN &MaximumAvailabilityMonth
	|				WHEN VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|					THEN &MaximumAvailabilityHour
	|				ELSE 0
	|			END
	|		ELSE
	|			CASE TTPerformers.WorkCenterType.UnitOfMeasureOfWorkCenterSchedule
	|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
	|					THEN TTPerformers.WorkCenterType.MaximumWorkCenterAvailability * 60
	|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
	|					THEN TTPerformers.WorkCenterType.MaximumWorkCenterAvailability * 3600
	|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
	|					THEN TTPerformers.WorkCenterType.MaximumWorkCenterAvailability * 86400
	|				ELSE 0
	|			END
	|	END AS MaximumAvailability,
	|	CASE TTPerformers.UnitOfMeasure
	|		WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
	|			THEN TTPerformers.OperationTime * 60
	|		WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
	|			THEN TTPerformers.OperationTime * 3600
	|		WHEN VALUE(Enum.TimeMeasureUnits.Days1)
	|			THEN TTPerformers.OperationTime * 86400
	|		ELSE TTPerformers.OperationTime
	|	END AS Time,
	|	TTPerformers.LineNumber AS LineNumber
	|INTO TTDataOfPerformers
	|FROM
	|	TTPerformers AS TTPerformers
	|
	|INDEX BY
	|	WorkCenterType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkCenters.WorkCenterType AS WorkCenterType,
	|	COUNT(WorkCenters.Ref) AS NumberOfWorkCenters
	|INTO TTNumberOfRC
	|FROM
	|	Catalog.WorkCenters AS WorkCenters
	|WHERE
	|	WorkCenters.WorkCenterType IN
	|			(SELECT
	|				TTPerformers.WorkCenterType
	|			FROM
	|				TTPerformers
	|			WHERE
	|				TTPerformers.WorkCenterType.EnterAvailabilityForWorkCenterType = FALSE)
	|
	|GROUP BY
	|	WorkCenters.WorkCenterType
	|
	|INDEX BY
	|	WorkCenterType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDataOfPerformers.LineNumber AS LineNumber,
	|	TTDataOfPerformers.ProductionStage AS ProductionStage,
	|	TTDataOfPerformers.WorkCenterType AS WorkCenterType,
	|	TTDataOfPerformers.ConsiderAvailability AS ConsiderAvailability,
	|	TTDataOfPerformers.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	TTDataOfPerformers.PlanningInterval AS PlanningInterval,
	|	TTDataOfPerformers.MaximumAvailability AS MaximumAvailability,
	|	TTDataOfPerformers.Time AS Time,
	|	CASE
	|		WHEN TTDataOfPerformers.WorkCenterType.EnterAvailabilityForWorkCenterType
	|			THEN TTDataOfPerformers.WorkCenterType.NumberOfWorkCenters
	|		ELSE ISNULL(TTNumberOfRC.NumberOfWorkCenters, 0)
	|	END AS NumberOfWorkCenters
	|FROM
	|	TTDataOfPerformers AS TTDataOfPerformers
	|		LEFT JOIN TTNumberOfRC AS TTNumberOfRC
	|		ON TTDataOfPerformers.WorkCenterType = TTNumberOfRC.WorkCenterType
	|WHERE
	|	TTDataOfPerformers.ProductionStage.OperatingProcedureOfWorkCenterTypes = &Sequentially
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TTDataOfPerformers.LineNumber) AS LineNumber,
	|	TTDataOfPerformers.ProductionStage AS ProductionStage,
	|	TTDataOfPerformers.WorkCenterType AS WorkCenterType,
	|	TTDataOfPerformers.ConsiderAvailability AS ConsiderAvailability,
	|	TTDataOfPerformers.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	TTDataOfPerformers.PlanningInterval AS PlanningInterval,
	|	TTDataOfPerformers.MaximumAvailability AS MaximumAvailability,
	|	SUM(TTDataOfPerformers.Time) AS Time,
	|	CASE
	|		WHEN TTDataOfPerformers.WorkCenterType.EnterAvailabilityForWorkCenterType
	|			THEN TTDataOfPerformers.WorkCenterType.NumberOfWorkCenters
	|		ELSE ISNULL(TTNumberOfRC.NumberOfWorkCenters, 0)
	|	END AS NumberOfWorkCenters
	|FROM
	|	TTDataOfPerformers AS TTDataOfPerformers
	|		LEFT JOIN TTNumberOfRC AS TTNumberOfRC
	|		ON TTDataOfPerformers.WorkCenterType = TTNumberOfRC.WorkCenterType
	|WHERE
	|	TTDataOfPerformers.ProductionStage.OperatingProcedureOfWorkCenterTypes <> &Sequentially
	|
	|GROUP BY
	|	TTDataOfPerformers.ProductionStage,
	|	TTDataOfPerformers.WorkCenterType,
	|	TTDataOfPerformers.ConsiderAvailability,
	|	TTDataOfPerformers.WorkScheduleCalendar,
	|	TTDataOfPerformers.PlanningInterval,
	|	TTDataOfPerformers.MaximumAvailability,
	|	CASE
	|		WHEN TTDataOfPerformers.WorkCenterType.EnterAvailabilityForWorkCenterType
	|			THEN TTDataOfPerformers.WorkCenterType.NumberOfWorkCenters
	|		ELSE ISNULL(TTNumberOfRC.NumberOfWorkCenters, 0)
	|	END
	|ORDER BY
	|	ProductionStage,
	|	LineNumber");
	
	Query.SetParameter("ProductionStages",
		ArrayOfStagesToPlace(PlanningParameters));
	Query.SetParameter("UnlimitedEquipmentFleet",
		PlanningParameters.UnlimitedEquipmentFleet);
	Query.SetParameter("PlanningByProductionResourcesIsUsed",
		PlanningByProductionResourcesIsUsed());
	Query.SetParameter("CancelManualChangesOfSchedule",
		PlanningParameters.CancelManualChangesOfSchedule);
	Query.SetParameter("Sequentially", Enums.OperatingProcedureOfWorkCenterTypes.Sequentially);
	Query.SetParameter("RoundTheClockWorkSevenDaysAWeek", PlanningParameters.RoundTheClockWorkSevenDaysAWeek);
	Query.SetParameter("MaximumAvailabilityDay", 
		SchedulingIntervalInSeconds(Enums.ProductionScheduleAccuracy.Day));
	Query.SetParameter("MaximumAvailabilityWeek",
		SchedulingIntervalInSeconds(Enums.ProductionScheduleAccuracy.Week));
	Query.SetParameter("MaximumAvailabilityMonth",
		SchedulingIntervalInSeconds(Enums.ProductionScheduleAccuracy.Month));
	Query.SetParameter("MaximumAvailabilityHour",
		SchedulingIntervalInSeconds(Enums.ProductionScheduleAccuracy.Hour));
	
	SetPrivilegedMode(True);
	StagePerformers_ = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	IndexOf = 0;
	While IndexOf < StagePerformers_.Count()-1 Do
		String = StagePerformers_[IndexOf];
		NextRow = StagePerformers_[IndexOf+1];
		If String.ProductionStage = NextRow.ProductionStage
			And String.WorkCenterType = NextRow.WorkCenterType Then
			NextRow.Time = NextRow.Time + String.Time;
			StagePerformers_.Delete(String);
		Else
			IndexOf = IndexOf + 1;
		EndIf;
	EndDo;
	
	AddSequenceNumberOfRowsToTable(StagePerformers_);
	
	StagePerformers_.Indexes.Add("ProductionStage");
	
	PlanningParameters.StagePerformers_ = StagePerformers_;
	
EndProcedure

Procedure READSecurityDates(PlanningParameters)
	
	If PlanningParameters.AllMaterialsInStock Then
		Return;
	EndIf;
	
	DatesOfProvision = ProductionManagement.CalculateProductionScheduleConstraintsOnMaterials(
		PlanningParameters.ProductionOrder);
	
	If DatesOfProvision <> Undefined Then
		DatesOfProvision.Indexes.Add("ProductionStage");
	EndIf;
	
	PlanningParameters.DatesOfProvision = DatesOfProvision;
	
EndProcedure

Procedure InitializeProductionScheduleParameter(PlanningParameters)
	
	ProductionSchedule = New ValueTable;
	
	Attributes = ProductionScheduleDetails();
	For Each Attribute In Attributes Do
		ProductionSchedule.Columns.Add(Attribute.Key, Attribute.Value);
	EndDo;
	
	ProductionSchedule.Indexes.Add("Stage");
	
	PlanningParameters.ProductionSchedule = ProductionSchedule;
	
EndProcedure

// Returns:
// 	Structure - LongDesc:
// * ProductionScheduling - EnumRef.WayOfLinkingProductionOperations -
// * EquipmentLimited - Boolean -
// * MaterialLimited - Boolean -
// * ItLimitsProductionDate - Boolean -
// * OnCriticalPath - Boolean -
// * NextStageStart - Date -
// * FollowUpBufferStart - Date -
// * PreliminaryBufferEnd - Date -
// * Ending - Date -
// * Begin - Date -
// * Stage - DocumentRef.ProductionStage2_2 -
Function ProductionScheduleDetails()
	
	Result = New Structure;
	
	Result.Insert("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Result.Insert("Begin", New TypeDescription("Date"));
	Result.Insert("Ending", New TypeDescription("Date"));
	Result.Insert("PreliminaryBufferEnd", New TypeDescription("Date"));
	Result.Insert("FollowUpBufferStart", New TypeDescription("Date"));
	Result.Insert("NextStageStart", New TypeDescription("Date"));
	Result.Insert("OnCriticalPath", New TypeDescription("Boolean"));
	Result.Insert("ItLimitsProductionDate", New TypeDescription("Boolean"));
	Result.Insert("MaterialLimited", New TypeDescription("Boolean"));
	Result.Insert("EquipmentLimited", New TypeDescription("Boolean"));
	Result.Insert("ProductionScheduling",
		New TypeDescription("EnumRef.WayOfLinkingProductionOperations"));
	
	Return Result;
	
EndFunction

Procedure InitializeLoadingVRCParameter(PlanningParameters)
	
	PlanningParameters.LoadingVRC = InitializeVRCDownloadAccountingTable();
	
EndProcedure

// Parameters:
// 	PlanningParameters - See InitializePlanningParameters
// Returns:
// 	Structure - LongDesc:
// * PlacedStages - Array -
// * Notifications - Map -
// * Errors - See InitializeSchedulingErrors
// * HasErrors - Boolean -
// * ScheduleIsPlanned - Boolean -
Function InitializeSchedulingResultsParameter(PlanningParameters)
	
	PlanningResults = New Structure;
	PlanningResults.Insert("ScheduleIsPlanned", False);
	PlanningResults.Insert("ScheduleStatus", PlanningParameters.ScheduleStatus);
	PlanningResults.Insert("HasErrors", False);
	PlanningResults.Insert("Errors", InitializeSchedulingErrors());
	PlanningResults.Insert("Notifications", New Map);
	PlanningResults.Insert("PlacedStages", New Array);
	PlanningResults.Insert("DataVolume", 0);
	
	Return PlanningResults;
	
EndFunction

Procedure ReadBBVSchedule(PlanningParameters, Begin = Undefined, Ending = Undefined) Export
	
	TheStructureOfTheSearch = New Structure("ConsiderAvailability", False);
	Assignees = PlanningParameters.StagePerformers_.FindRows(TheStructureOfTheSearch);
	If Assignees.Count() = 0 Then
		Return;
	EndIf;
	
	TypesOfRC = New Array;
	For Each String In Assignees Do
		TypesOfRC.Add(String.WorkCenterType);
	EndDo;
	
	Chartsreferences = ProductionServer.WorkSchedulesOfRCTypes(TypesOfRC);
	
	Schedules = New ValueTable;
	Schedules.Columns.Add("WorkScheduleCalendar", New TypeDescription("Number", New NumberQualifiers));
	Schedules.Columns.Add("WorkScheduleLink", New TypeDescription("CatalogRef.Calendars"));
	Schedules.Columns.Add("PlanningInterval", New TypeDescription("EnumRef.ProductionScheduleAccuracy"));
	
	Cnt = 1;
	For Each String In Assignees Do
		
		LinkStrings = Chartsreferences.FindRows(New Structure("Ref", String.WorkCenterType));
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("WorkScheduleLink", LinkStrings[0].WorkScheduleCalendar);
		TheStructureOfTheSearch.Insert("PlanningInterval", String.PlanningInterval);
		GraphLinesByReference = Schedules.FindRows(TheStructureOfTheSearch);
		
		WorkScheduleCalendar = 0;
		
		// Search for a graph code that matches the composition of the graphs
		For Each StringByRef In GraphLinesByReference Do
			
			GraphLinesByCode = Schedules.FindRows(New Structure("WorkScheduleCalendar", StringByRef.WorkScheduleCalendar));
			
			If LinkStrings.Count() = GraphLinesByCode.Count() Then
				
				GraphsAreIdentical = True;
				
				If LinkStrings.Count() > 1 Then
					For Each LinkString_ In LinkStrings Do
						
						TheStructureOfTheSearch = New Structure;
						TheStructureOfTheSearch.Insert("WorkScheduleCalendar", StringByRef.WorkScheduleCalendar);
						TheStructureOfTheSearch.Insert("WorkScheduleLink", LinkString_.WorkScheduleCalendar);
						TheStructureOfTheSearch.Insert("PlanningInterval", String.PlanningInterval);
						
						If Schedules.FindRows(TheStructureOfTheSearch).Count() = 0 Then
							GraphsAreIdentical = False;
							Break;
						EndIf;
						
					EndDo;
				EndIf;
				
				If GraphsAreIdentical Then
					WorkScheduleCalendar = StringByRef.WorkScheduleCalendar;
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		// Adding new code
		If WorkScheduleCalendar = 0 Then
			
			WorkScheduleCalendar = Cnt;
			Cnt = Cnt + 1;
			
			For Each LinkString_ In LinkStrings Do
				NewRow = Schedules.Add();
				NewRow.WorkScheduleCalendar = WorkScheduleCalendar;
				NewRow.WorkScheduleLink = LinkString_.WorkScheduleCalendar;
				NewRow.PlanningInterval = String.PlanningInterval;
			EndDo;
			
		EndIf;
		
		String.WorkScheduleCalendar = WorkScheduleCalendar;
		
	EndDo;
	
	If Begin = Undefined Or Ending = Undefined Then
		
		Period = CalendarDataSamplingPeriod(PlanningParameters);
		Begin = ?(Begin = Undefined, Period.Begin, Begin);
		Ending = ?(Ending = Undefined, Period.Ending, Ending);
		
	EndIf;
	
	BBVSchedule = BBVSchedule(Schedules, Begin, Ending); //ValueTable - 
	
	AddSequenceNumberOfRowsToTable(BBVSchedule);
	
	BBVSchedule.Indexes.Add("WorkScheduleCalendar, IntervalDate");
	BBVSchedule.Indexes.Add("WorkScheduleCalendar");
	
	PlanningParameters.BBVSchedule = BBVSchedule;
	
EndProcedure

Procedure ReadUBBWSchedule(PlanningParameters)
	
	If PlanningParameters.RoundTheClockWorkSevenDaysAWeek Then
		Return;
	EndIf;
	
	Stages = New Array;
	Departments = New Array;
	
	For Each Stage In PlanningParameters.Stages Do
		If ThisIsUBBVStage(Stage)
			Or ValueIsFilled(Stage.PreliminaryBuffer)
			Or ValueIsFilled(Stage.FollowUpBuffer) Then
			
			Stages.Add(Stage);
			
			If Not Stage.ProductionByThirdParty And Departments.Find(Stage.Department) = Undefined Then
				Departments.Add(Stage.Department);
			EndIf;
			
		EndIf;
	EndDo;
	
	If Stages.Count() = 0 Then
		Return;
	EndIf;
	
	Chartsreferences = Undefined;
	If Departments.Count() > 0 Then
		Chartsreferences = ProductionServer.DivisionWorkSchedules(Departments);
	EndIf;
	
	Schedules = New ValueTable;
	Schedules.Columns.Add("WorkScheduleCalendar", New TypeDescription("Number", New NumberQualifiers));
	Schedules.Columns.Add("WorkScheduleLink", New TypeDescription("CatalogRef.Calendars"));
	
	Cnt = 1;
	GraphOnSide = Constants.MainEnterpriseCalendar.Get();
	For Each String In Stages Do
		
		WorkScheduleCalendar = 0;
		
		If String.ProductionByThirdParty Then
			
			TheStructureOfTheSearch = New Structure("WorkScheduleLink", GraphOnSide);
			GraphLinesByReference = Schedules.FindRows(TheStructureOfTheSearch);
			
			// Search for a graph code that matches the composition of the graphs
			For Each StringByRef In GraphLinesByReference Do
				
				GraphLinesByCode = Schedules.FindRows(New Structure("WorkScheduleCalendar", StringByRef.WorkScheduleCalendar));
				
				If GraphLinesByCode.Count() = 1 Then
					WorkScheduleCalendar = StringByRef.WorkScheduleCalendar;
					Break;
				EndIf;
				
			EndDo;
			
			// Adding new code
			If WorkScheduleCalendar = 0 Then
				
				WorkScheduleCalendar = Cnt;
				Cnt = Cnt + 1;
							
				NewRow = Schedules.Add();
				NewRow.WorkScheduleCalendar = WorkScheduleCalendar;
				NewRow.WorkScheduleLink = GraphOnSide;
				
			EndIf;
			
		Else
			
			LinkStrings = Chartsreferences.FindRows(New Structure("Ref", String.Department));
		
			TheStructureOfTheSearch = New Structure("WorkScheduleLink", LinkStrings[0].WorkScheduleCalendar);
			GraphLinesByReference = Schedules.FindRows(TheStructureOfTheSearch);
			
			// Search for a graph code that matches the composition of the graphs
			For Each StringByRef In GraphLinesByReference Do
				
				GraphLinesByCode = Schedules.FindRows(New Structure("WorkScheduleCalendar", StringByRef.WorkScheduleCalendar));
				
				If LinkStrings.Count() = GraphLinesByCode.Count() Then
					
					GraphsAreIdentical = True;
					
					If LinkStrings.Count() > 1 Then
						For Each LinkString_ In LinkStrings Do
							
							TheStructureOfTheSearch = New Structure;
							TheStructureOfTheSearch.Insert("WorkScheduleCalendar", StringByRef.WorkScheduleCalendar);
							TheStructureOfTheSearch.Insert("WorkScheduleLink", LinkString_.WorkScheduleCalendar);
							
							If Schedules.FindRows(TheStructureOfTheSearch).Count() = 0 Then
								GraphsAreIdentical = False;
								Break;
							EndIf;
							
						EndDo;
					EndIf;
					
					If GraphsAreIdentical Then
						WorkScheduleCalendar = StringByRef.WorkScheduleCalendar;
						Break;
					EndIf;
					
				EndIf;
				
			EndDo;
			
			// Adding new code
			If WorkScheduleCalendar = 0 Then
				
				WorkScheduleCalendar = Cnt;
				Cnt = Cnt + 1;
				
				For Each LinkString_ In LinkStrings Do
					NewRow = Schedules.Add();
					NewRow.WorkScheduleCalendar = WorkScheduleCalendar;
					NewRow.WorkScheduleLink = LinkString_.WorkScheduleCalendar;
				EndDo;
				
			EndIf;
		    
		EndIf;
		
		String.WorkScheduleCalendar = WorkScheduleCalendar;
		
	EndDo;
	
	Period = CalendarDataSamplingPeriod(PlanningParameters);
	
	UbbwSchedule = UbbwSchedule(Schedules, Period.Begin, Period.Ending);
	AddIndexesAndServiceFieldsToUBBWSchedule(UbbwSchedule);
	
	PlanningParameters.UbbwSchedule = UbbwSchedule;
	
EndProcedure

Procedure AddIndexesAndServiceFieldsToUBBWSchedule(UbbwSchedule)
	
	AddSequenceNumberOfRowsToTable(UbbwSchedule);
	
	UbbwSchedule.Indexes.Add("WorkScheduleCalendar, ScheduleDate");
	UbbwSchedule.Indexes.Add("WorkScheduleCalendar");
	
EndProcedure

// Constructor function for typing
//
// Returns:
// 	ValueTableRow - Contains:
//		* Begin - Date
Function ScheduleUBBVLineConstructor() Export
	
	Return Undefined;
	
EndFunction

Procedure ReadVRCAvailability(PlanningParameters)
	
	If PlanningParameters.UnlimitedEquipmentFleet
		Or PlanningParameters.StagePerformers_.Count() = 0 Then
		Return;
	EndIf;
	
	Query = InitializeVRCAvailabilityRequest(PlanningParameters);
	WCKAvailability = Query.Execute().Unload();
	
	AddSequenceNumberOfRowsToTable(WCKAvailability);
	
	WCKAvailability.Indexes.Add("WorkCenterType, IntervalDate");
	WCKAvailability.Indexes.Add("WorkCenterType");
	
	PlanningParameters.WCKAvailability = WCKAvailability;
	
EndProcedure

Function AddEntryToVRCAvailability(PlanningParameters, FillingValues)
	
	TableAvailability = PlanningParameters.WCKAvailability; // ValueTable
	
	NewRow = TableAvailability.Add();
	FillPropertyValues(NewRow, FillingValues);
	NewRow.Available = 0;
	NewRow.Busy = 0;
	
	Return NewRow;
	
EndFunction

Function InitializeVRCAvailabilityRequest(PlanningParameters)
	
	ArrayOfStages = ArrayOfStagesToPlace(PlanningParameters);
	Period = CalendarDataSamplingPeriod(PlanningParameters);
	
	TempTablesManager = New TempTablesManager;
	CreateTTAvailabilityOfRCTypes(
		TempTablesManager,
		"TTAvailabilityTypesOfRC",
		PlanningParameters.StagePerformers_.UnloadColumn("WorkCenterType"),
		ArrayOfStages,
		CurrentSessionDate(),
		Period.Ending,
		PlanningParameters);
	
	Query = New Query(
	"SELECT
	|	NestedQuery.Performer AS WorkCenterType,
	|	NestedQuery.IntervalDate AS IntervalDate,
	|	NestedQuery.EndOfTheInterval AS EndOfShift,
	|	CASE
	|		WHEN NestedQuery.Available > 0
	|			THEN NestedQuery.Available
	|		ELSE 0
	|	END AS Available,
	|	NestedQuery.Busy AS Busy
	|FROM
	|	(SELECT
	|		TAvailability.Performer AS Performer,
	|		TAvailability.IntervalDate AS IntervalDate,
	|		TAvailability.EndOfTheInterval AS EndOfTheInterval,
	|		CASE
	|			WHEN &UseAvailabilityReserve
	|				THEN TAvailability.CountReceipt - TAvailability.CountExpense
	|			ELSE (CAST(TAvailability.CountReceipt * (100 - TAvailability.AvailabilityReserve) / 100 AS NUMBER(15, 0))) - TAvailability.CountExpense
	|		END AS Available,
	|		TAvailability.CountExpense AS Busy
	|	FROM
	|		TTAvailabilityTypesOfRC AS TAvailability
	|	WHERE
	|		TAvailability.CountReceipt > 0) AS NestedQuery
	|
	|ORDER BY
	|	WorkCenterType,
	|	IntervalDate");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("UseAvailabilityReserve",
		PlanningParameters.UseAvailabilityReserve);
	
	Return Query;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * Stage - DocumentRef.ProductionStage2_2 -
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * IntervalDate - Date -
// * Busy - Number -
Function InitializeVRCDownloadAccountingTable()
	
	LoadingVRC = New ValueTable;
	LoadingVRC.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	LoadingVRC.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	LoadingVRC.Columns.Add("IntervalDate", New TypeDescription("Date"));
	LoadingVRC.Columns.Add("EndOfTheInterval", New TypeDescription("Date"));
	LoadingVRC.Columns.Add("Busy", New TypeDescription("Number"));
	
	Return LoadingVRC;
	
EndFunction

// Returns:
// 	ValueTable - LongDesc:
// * LongDesc - String -
// * Details - Structure -
// * Key - AnyRef -
// * ScheduleStatus - Number -
Function InitializeSchedulingErrors()
	
	Result = New ValueTable;
	
	Result.Columns.Add("LongDesc", New TypeDescription("String"));
	Result.Columns.Add("Details");
	Result.Columns.Add("Key");
	Result.Columns.Add("ScheduleStatus", New TypeDescription("Number"));
	
	Return Result;
	
EndFunction

// Parameters:
// 	ChartTable_ - ValueTable - LongDesc:
// * WorkScheduleCalendar - Number -
// * WorkScheduleLink - CatalogRef.Calendars -
// * PlanningInterval - EnumRef.ProductionScheduleAccuracy -
// * WorkScheduleCalendar - Number -
// * WorkScheduleLink - CatalogRef.Calendars -
// * PlanningInterval - EnumRef.ProductionScheduleAccuracy -
// * WorkScheduleCalendar - Number -
// * WorkScheduleLink - CatalogRef.Calendars -
// * PlanningInterval - EnumRef.ProductionScheduleAccuracy -
// * WorkScheduleCalendar - Number -
// * WorkScheduleLink - CatalogRef.Calendars -
// * PlanningInterval - EnumRef.ProductionScheduleAccuracy -
// 	Begin - Undefined - LongDesc
// 	Ending - Undefined - LongDesc
// Returns:
// 	ValueTable - LongDesc
Function BBVSchedule(ChartTable_, Begin, Ending)
	
	TempTablesManager = New TempTablesManager;
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager, ChartTable_.UnloadColumn("WorkScheduleLink"), Begin, Ending, False);
	
	Query = New Query(
	"SELECT
	|	Schedules.WorkScheduleCalendar,
	|	Schedules.WorkScheduleLink,
	|	Schedules.PlanningInterval
	|INTO Schedules
	|FROM
	|	&Schedules AS Schedules
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Schedules.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	Schedules.PlanningInterval AS PlanningInterval,
	|	CASE Schedules.PlanningInterval
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, DAY)
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, WEEK)
	|		WHEN VALUE(Enum.ProductionScheduleAccuracy.MONTH)
	|			THEN BEGINOFPERIOD(Schedule.ScheduleDate, MONTH)
	|		ELSE DATETIME(1, 1, 1, 1, 1, 1)
	|	END AS IntervalDate,
	|	DATETIME(1, 1, 1, 1, 1, 1) AS EndOfShift
	|FROM
	|	Schedules AS Schedules
	|		INNER JOIN TTWorkSchedules AS Schedule
	|		ON Schedules.WorkScheduleLink = Schedule.WorkScheduleCalendar
	|WHERE
	|	Schedules.PlanningInterval IN (
	|		VALUE(Enum.ProductionScheduleAccuracy.DAY),
	|		VALUE(Enum.ProductionScheduleAccuracy.WEEK),
	|		VALUE(Enum.ProductionScheduleAccuracy.MONTH))
	|
	|UNION ALL
	|
	|SELECT
	|	Schedules.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	Schedules.PlanningInterval AS PlanningInterval,
	|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
	|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
	|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS IntervalDate,
	|	MAX(
	|		CASE
	|			WHEN Schedule.EndTime IS NULL 
	|				OR Schedule.EndTime = DATETIME(1, 1, 1)
	|				THEN DATEADD(Schedule.ScheduleDate, DAY, 1)
	|			ELSE DATEADD(Schedule.ScheduleDate, MINUTE,
	|				HOUR(Schedule.EndTime)*60 + MINUTE(Schedule.EndTime))
	|		END) AS EndOfShift
	|FROM
	|	Schedules AS Schedules
	|		INNER JOIN TTWorkSchedules AS Schedule
	|		ON Schedules.WorkScheduleLink = Schedule.WorkScheduleCalendar
	|WHERE
	|	Schedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|	AND Schedule.Period >= &Begin
	|
	|GROUP BY
	|	Schedules.WorkScheduleCalendar,
	|	Schedules.PlanningInterval,
	|	Schedule.WorkScheduleCalendar,
	|	Schedule.Period
	|
	|ORDER BY
	|	WorkScheduleCalendar,
	|	IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Schedules.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	Schedules.PlanningInterval AS PlanningInterval,
	|	Schedule.ScheduleDate AS ScheduleDate,
	|	ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)) AS BeginTime,
	|	CASE
	|		WHEN Schedule.EndTime IS NULL 
	|				OR Schedule.EndTime = DATETIME(1, 1, 1)
	|			THEN DATEDIFF(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)), DATETIME(1, 1, 1, 23, 59, 59), SECOND) + 1
	|		ELSE DATEDIFF(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)), Schedule.EndTime, SECOND)
	|	END AS Duration
	|FROM
	|	Schedules AS Schedules
	|		INNER JOIN TTWorkSchedules AS Schedule
	|		ON Schedules.WorkScheduleLink = Schedule.WorkScheduleCalendar
	|WHERE
	|	Schedules.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|
	|ORDER BY
	|	WorkScheduleCalendar,
	|	ScheduleDate,
	|	BeginTime");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Schedules", ChartTable_);
	Query.SetParameter("Begin", Begin);
	ResultsArray = Query.ExecuteBatch();
	
	Result = ResultsArray[1].Unload();//ValueTable - 
	
	Selection = ResultsArray[2].Select();
	While Selection.Next() Do
		
		Begin = Date(Year(Selection.ScheduleDate), Month(Selection.ScheduleDate), Day(Selection.ScheduleDate),
			Hour(Selection.BeginTime), Minute(Selection.BeginTime), Second(Selection.BeginTime));
		Ending = Begin + Selection.Duration;
		
		If Not Begin = BegOfHour(Begin) Then
			Begin = EndOfHour(Begin) + 1;
		EndIf;
		
		While Begin < Ending Do
			
			NewRow = Result.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.IntervalDate = Begin;
			
			Begin = EndOfHour(Begin) + 1;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
// 	ChartTable_ - ValueTable - LongDesc:
// * WorkScheduleCalendar - Number -
// * WorkScheduleLink - CatalogRef.Calendars -
// 	Begin - Date - LongDesc
// 	Ending - Date - LongDesc
// Returns:
// 	ValueTable - Where:
// * WorkScheduleCalendar - Number -
// * ScheduleDate - Date -
// * BeginTime - Date -
// * EndTime - Date -
// * Begin - Date -
// * Ending - Date -
Function UbbwSchedule(ChartTable_, Begin, Ending) Export
	
	TempTablesManager = New TempTablesManager;
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager,
		ChartTable_.UnloadColumn("WorkScheduleLink"),
		Begin,
		Ending,
		False);
	
	Query = New Query(
		"SELECT
		|	Schedules.WorkScheduleCalendar       AS WorkScheduleCalendar,
		|	Schedules.WorkScheduleLink AS WorkScheduleLink
		|INTO Schedules
		|FROM
		|	&Schedules AS Schedules
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Schedules.WorkScheduleCalendar                                    AS WorkScheduleCalendar,
		|	Schedule.ScheduleDate                                  AS ScheduleDate,
		|	ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))    AS BeginTime,
		|	ISNULL(Schedule.EndTime, DATETIME(1, 1, 1)) AS EndTime,
		|	CASE
		|		WHEN Schedule.EndTime IS NULL
		|				OR Schedule.EndTime = DATETIME(1, 1, 1)
		|			THEN DATEDIFF(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)), DATETIME(1, 1, 1, 23, 59, 59), SECOND) + 1
		|		ELSE DATEDIFF(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)), Schedule.EndTime, SECOND)
		|	END                                                   AS Duration
		|FROM
		|	Schedules AS Schedules
		|		INNER JOIN TTWorkSchedules AS Schedule
		|		ON Schedules.WorkScheduleLink = Schedule.WorkScheduleCalendar
		|
		|ORDER BY
		|	WorkScheduleCalendar,
		|	ScheduleDate,
		|	BeginTime");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Schedules", ChartTable_);
	
	Result = Query.Execute().Unload(); // ValueTable -
	
	Result.Columns.Add("Begin", New TypeDescription("Date"));
	Result.Columns.Add("Ending", New TypeDescription("Date"));
	
	For Each String In Result Do
		String.Begin = Date(Year(String.ScheduleDate), Month(String.ScheduleDate), Day(String.ScheduleDate),
			Hour(String.BeginTime), Minute(String.BeginTime), Second(String.BeginTime));
		String.Ending = String.Begin + String.Duration;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region NotificationErrors

Procedure FixStagePlacementError(PlanningParameters, Stage, PlacementParameters)
	
	PlacementErrorCode = PlacementParameters.PlacementErrorCode;
	
	Details = New Structure;
	Details.Insert("ErrorCode", PlacementErrorCode);
	
	If PlacementErrorCode = ErrorCodeVRCAvailability() Then
		
		Cause = NStr("vi = 'không đủ thời gian truy cập của các trung tâm làm việc';
					|ru = 'недостаточно доступного времени видов рабочих центров';
					|en = 'there is not enough available time of work center types'; fa = 'there is not enough available time of work center types';
					|it = 'tempo disponibile insufficiente dei tipi di centri di lavoro';
					|pl = 'niedostatecznie dostępnego czasu rodzajów centrów roboczych';
					|tr = 'iş merkezi türlerinin yeterli müsait zamanı yok'");
		Var_Key = Stage.ProductionStage;
		
		Details.Insert("ProductionStage", Stage.ProductionStage);
		Details.Insert("Period", PlacementParameters.TimeOfPlacement);
		Details.Insert("Department", Stage.Department);
		
		WorkCenterTypes = TypesOfWorkingStageCenters(PlanningParameters, Stage);
		If WorkCenterTypes.Count() > 0 Then
			WorkCenterType = WorkCenterTypes[0].WorkCenterType;
		Else
			WorkCenterType = Undefined;
		EndIf;
		Details.Insert("WorkCenterType", WorkCenterType);
		
	ElsIf PlacementErrorCode = ErrorCodeDivisionSchedule() Then
		
		Cause = NStr("vi = 'lịch trình làm việc của đơn vị không được xác định hoặc dữ liệu lịch trình không được điền';
					|ru = 'не определен график работы подразделения или данные графика не заполнены';
					|en = 'business unit work schedule is not specified or schedule data is not filled in'; fa = 'business unit work schedule is not specified or schedule data is not filled in';
					|it = 'l''orario di lavoro del reparto non è definito o i dati dell''orario non sono compilati';
					|pl = 'nie jest zdefiniowany harmonogram pracy działu lub dane harmonogramu nie są wypełnione';
					|tr = 'Departmanın çalışma takvimi belirtilmedi veya takvim verileri doldurulmadı'");
		Var_Key = Stage.Department;
		Details.Insert("Department", Stage.Department);
		
	ElsIf PlacementErrorCode = ErrorCodeBusinessHours() Then
		
		Cause = NStr("vi = 'lịch trình của doanh nghiệp không được xác định hoặc dữ liệu lịch trình không được điền';
					|ru = 'не определен график работы предприятия или данные графика не заполнены';
					|en = 'enterprise schedule is not specified or schedule data is not filled in'; fa = 'enterprise schedule is not specified or schedule data is not filled in';
					|it = 'l''orario di lavoro della società non è definito o i dati dell''orario non sono compilati';
					|pl = 'nie jest zdefiniowany harmonogram pracy przedsiębiorstwa lub dane harmonogramu nie są wypełnione';
					|tr = 'işletmenin çalışma takvimi tanımlanmadı veya program verileri doldurulmadı'");
		Var_Key = "EnterpriseSchedule";
		
	EndIf;
	
	ScheduleStatus = PlanningParameters.ScheduleStatus;
	TheStructureOfTheSearch = New Structure("Key, ScheduleStatus", Var_Key, ScheduleStatus);
	FoundRows = PlanningParameters.PlanningResults.Errors.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() = 0 Then
		
		PlanningArea = PresentationOfPlanningArea(ScheduleStatus);
		PresentationStage = PresentationStage(Stage.ProductionStage);
		
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi lập kế hoạch %1, công đoạn ""%2"" không được đặt do: %3.';
					|ru = 'При планировании %1 не размещен этап ""%2"" по причине: %3.';
					|en = 'When planning %1, stage %2 was not placed. Reason: %3.'; fa = 'When planning %1, stage %2 was not placed. Reason: %3.';
					|it = 'Durante la pianificazione %1 non è stata collocata la fase ""%2"" a causa di: %3.';
					|pl = 'Przy planowaniu %1 nie został umieszczony etap ""%2"" z powodu: %3.';
					|tr = '%1 planlanırken ""%2"" aşamasının yerleştirilmeme nedeni: %3.'"),
				PlanningArea,
				PresentationStage,
				Cause);
		
		NewRow = PlanningParameters.PlanningResults.Errors.Add();
		NewRow.LongDesc = LongDesc;
		NewRow.Details = Details;
		NewRow.Key = Var_Key;
		NewRow.ScheduleStatus = ScheduleStatus;
		
	EndIf;
	
	PlanningParameters.PlanningResults.HasErrors = True;
	
EndProcedure

Procedure FixErrorsThereIsNoScheduleOfPreviousStages(PlanningParameters, PreviousStages_)
	
	For Each String In PreviousStages_ Do
		
		If String.NoSchedule Then
			
			Var_Key = String.ProductionStage;
			ScheduleStatus = PlanningParameters.ScheduleStatus;
			TheStructureOfTheSearch = New Structure("Key, ScheduleStatus", Var_Key, ScheduleStatus);
			FoundRows = PlanningParameters.PlanningResults.Errors.FindRows(TheStructureOfTheSearch);
			
			If FoundRows.Count() = 0 Then
				
				PlanningArea = PresentationOfPlanningArea(ScheduleStatus);
				PresentationStage = PresentationStage(String.ProductionStage);
				TheNumberOfTheOrder = ObjectsPrefixesClientServer.NumberForPrinting(
					String.OrderNumber__,
					False,
					True);
				LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã xảy ra lỗi trong khi lập kế hoạch %1: không có lịch trình cho công đoạn trước ""%2"" (số thứ tự %3).';
						|ru = 'При планировании %1 возникла ошибка: отсутствует график предшествующего этапа ""%2"" (заказ № %3).';
						|en = 'An error occurred when planning %1: there is no schedule of the previous stage ""%2"" (order No. %3).'; fa = 'An error occurred when planning %1: there is no schedule of the previous stage ""%2"" (order No. %3).';
						|it = 'Durante la pianificazione %1 si è verificato un errore: manca l''orario per la fase precedente ""%2"" (ordine № %3).';
						|pl = 'Przy planowaniu %1 wystąpił błąd: brak harmonogramu poprzedniego etapu ""%2"" (zlecenie №%3).';
						|tr = '%1 planlanırken hata oluştu: Önceki ""%2"" aşamasının programı bulunmamaktadır (%3 sipariş numaralı).'"),
					PlanningArea,
					PresentationStage,
					TheNumberOfTheOrder);
				
				Details = New Structure;
				Details.Insert("ErrorCode", ErrorCodeMissingPredecessorGraph());
				Details.Insert("ProductionStage", String.ProductionStage);
				Details.Insert("ReferenceOrder", String.ReferenceOrder);
				
				NewRow = PlanningParameters.PlanningResults.Errors.Add();
				NewRow.LongDesc = LongDesc;
				NewRow.Details = Details;
				NewRow.Key = Var_Key;
				NewRow.ScheduleStatus = ScheduleStatus;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	PlanningParameters.PlanningResults.HasErrors = True;
	
EndProcedure

Procedure FixErrorThereAreCyclesInChainOfStages(PlanningParameters, StageError)
	
	Var_Key = PlanningParameters.ProductionOrder;
	ScheduleStatus = PlanningParameters.ScheduleStatus;
	PlanningArea = PresentationOfPlanningArea(ScheduleStatus);
	
	If ValueIsFilled(StageError) Then
		
		PresentationStage = PresentationStage(StageError);
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi khi lập kế hoạch %1: một vòng lặp của các công đoạn sản xuất đã được phát hiện trên chứng từ ""%2"".';
				|ru = 'При планировании %1 возникла ошибка: обнаружено зацикливание этапов производства на документе ""%2"".';
				|en = 'An error occurred when planning %1: production stage loop on the ""%2"" document detected.'; fa = 'An error occurred when planning %1: production stage loop on the ""%2"" document detected.';
				|it = 'Durante la pianificazione %1 si è verificato un errore: rilevato un ciclo nelle fasi di produzione nel documento ""%2"".';
				|pl = 'Przy planowaniu %1 wystąpił błąd: wykryto zapętlanie etapów produkcji na dokumencie ""%2"".';
				|tr = '%1 planlanırken hata oluştu: ""%2"" belgesindeki üretim aşamalarının döngüsü tespit edildi.'"),
			PlanningArea,
			PresentationStage);
		
	Else
		
		LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xảy ra lỗi trong khi lập kế hoạch %1: một chu kỳ của các công đoạn sản xuất đã được phát hiện.';
				|ru = 'При планировании %1 возникла ошибка: обнаружено зацикливание этапов производства.';
				|en = 'An error occurred when planning %1: production stage loop detected.'; fa = 'An error occurred when planning %1: production stage loop detected.';
				|it = 'Durante la pianificazione %1 si è verificato un errore: rilevato un ciclo nelle fasi di produzione.';
				|pl = 'Przy planowaniu %1 wystąpił błąd: wykryto zapętlanie etapów produkcji.';
				|tr = '%1 planlanırken hata oluştu: Üretim aşamalarının döngüsü tespit edildi.'"),
			PlanningArea);
		
	EndIf;
	
	Details = New Structure;
	Details.Insert("ErrorCode", ErrorCodeThereAreCyclesInChainOfStages());
	Details.Insert("ProductionStage", StageError);
	Details.Insert("ReferenceOrder", PlanningParameters.ProductionOrder);
	
	NewRow = PlanningParameters.PlanningResults.Errors.Add();
	NewRow.LongDesc = LongDesc;
	NewRow.Details = Details;
	NewRow.Key = Var_Key;
	NewRow.ScheduleStatus = ScheduleStatus;
	
EndProcedure

Procedure AddNotificationWhenPlanningDirectionChanges(PlanningParameters)
	
	TheNumberOfTheOrder = ObjectsPrefixesClientServer.NumberForPrinting(
		Common.ObjectAttributeValue(PlanningParameters.ProductionOrder, "Number"),
		False,
		True);
	
	Notification = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Khi lập kế hoạch đặt hàng số %1, phương pháp đặt vấn đề ""Bắt đầu"" đã được sử dụng.';
			|ru = 'При планировании заказа № %1 использован способ размещения выпуска ""К началу"".';
			|en = 'When planning order No.%1 the ""Backward"" production scheduling method was used.'; fa = 'When planning order No.%1 the ""Backward"" production scheduling method was used.';
			|it = 'Durante la pianificazione dell''ordine № %1 è usato il metodo di collocamento di emissione ""All''inizio"".';
			|pl = 'Przy planowaniu zlecenia № %1 zastosowano sposób rozmieszczenia produkcji ""Do początku"".';
			|tr = '%1  No.lu sipariş planladığında ""İleriye dönük"" üretim planlama yöntemi kullanıldı.'"),
		TheNumberOfTheOrder);
	
	PlanningParameters.PlanningResults.Notifications.Insert(Notification, Undefined);
	
EndProcedure

Procedure AddAlertMissingStagesForPlanning(PlanningParameters)
	
	TheNumberOfTheOrder = ObjectsPrefixesClientServer.NumberForPrinting(
		Common.ObjectAttributeValue(PlanningParameters.ProductionOrder, "Number"),
		False,
		True);
	
	Notification = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Thiếu các công đoạn của đơn hàng # %1 để lập kế hoạch.';
			|ru = 'Отсутствуют этапы заказа № %1 для планирования.';
			|en = 'Stages of order No. %1 for planning are missing.'; fa = 'Stages of order No. %1 for planning are missing.';
			|it = 'Mancano le fasi dell''ordine № %1 per la pianificazione.';
			|pl = 'Brak etapów zlecenia № %1 dla planowania.';
			|tr = 'Planlama için %1 No.lu sipariş aşaması eksiktir.'"),
		TheNumberOfTheOrder);
	
	PlanningParameters.PlanningResults.Notifications.Insert(Notification, Undefined);
	
EndProcedure

Function PresentationOfPlanningArea(ScheduleStatus)
	
	If ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
		Result = NStr("vi = 'mô hình';
						|ru = 'модели';
						|en = 'models'; fa = 'models';
						|it = 'del modello';
						|pl = 'modele';
						|tr = 'model'");
	Else
		Result = NStr("vi = 'lịch biểu';
						|ru = 'графика';
						|en = 'schedule'; fa = 'زمان‌بندی';
						|it = 'del piano';
						|pl = 'harmonogramu';
						|tr = 'program'");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region TermsOfProduction

Procedure ReadProductReleaseDates(Parameters, StorageAddress) Export
	
	Result = InitializeProductionDates();
	
	ReferenceOrder = Parameters.ReferenceOrder;
	ScheduleIsPlanned = Parameters.ScheduleIsPlanned;
	ModelIsPlanned = Parameters.ModelIsPlanned;
	DynamicStructure = Parameters.DynamicStructure;
	
	Query = New Query();
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ScheduleIsPlanned", ScheduleIsPlanned);
	Query.SetParameter("ModelIsPlanned", ModelIsPlanned);
	Query.SetParameter("StatusWorkingSchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("StatusPreliminarySchedule",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule());
	Query.SetParameter("StatusChartModel",
		InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel());
	Query.SetParameter("EmptyLinkKey",
		New UUID("00000000-0000-0000-0000-000000000000"));
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If DynamicStructure Then
		Query.Text = QueryTextManufacturedProductsDatesAreDynamic(ModelIsPlanned);
	Else
		Query.Text = QueryTextTermsOfProduction(ScheduleIsPlanned, ModelIsPlanned);
	
		Documents.ProductionOrder2_2.CreateTTStagesProvidingOrders(
			TempTablesManager,
			CommonClientServer.ValueInArray(ReferenceOrder));
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = Result.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.ProcessType = Enums.ProductionProcessTypes.Disassembly Then
			
			NewRow.LaunchDateSchedule = Selection.StartProduction;
			NewRow.ReleaseDateSchedule = Selection.EndOfOrder;
			NewRow.LaunchDateModel = Selection.StartModelProduction;
			NewRow.ReleaseDateModel = Selection.EndingModelOrder;
			
		Else
			
			NewRow.LaunchDateSchedule = Selection.BeginningOfLife;
			NewRow.ReleaseDateSchedule = Selection.EndOfProduction;
			NewRow.LaunchDateModel = Selection.BeginningOfModel;
			NewRow.ReleaseDateModel = Selection.EndingModelProducts;
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function InitializeProductionDates()
	
	ArrayOfRecipientTypes = New Array;
	ArrayOfRecipientTypes.Add(Type("CatalogRef.BusinessStructure"));
	ArrayOfRecipientTypes.Add(Type("CatalogRef.Warehouses"));
	
	Result = New ValueTable;
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	Result.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Result.Columns.Add("Recipient", New TypeDescription(ArrayOfRecipientTypes));
	Result.Columns.Add("NumberOfPackages", New TypeDescription("Number"));
	Result.Columns.Add("NumberOfPackagesIsReady", New TypeDescription("Number"));
	Result.Columns.Add("LaunchDateSchedule", New TypeDescription("Date"));
	Result.Columns.Add("ReleaseDateSchedule", New TypeDescription("Date"));
	Result.Columns.Add("LaunchDateModel", New TypeDescription("Date"));
	Result.Columns.Add("ReleaseDateModel", New TypeDescription("Date"));
	Result.Columns.Add("DemandDate", New TypeDescription("Date"));
	
	Return Result;
	
EndFunction

Function QueryTextManufacturedProductsDatesAreDynamic(ModelIsPlanned)
	
	QueryText =
		"SELECT
		|	TabularSection.Products       AS Products,
		|	TabularSection.Characteristic     AS Characteristic,
		|	CASE 
		|		WHEN TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|				OR TabularSection.ToExpenseAs
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Warehouse
		|	END                             AS Warehouse,
		|	CASE
		|		WHEN TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
		|				AND NOT TabularSection.ToExpenseAs
		|			THEN TabularSection.Ref.AssignmentProducts
		|		ELSE TabularSection.Purpose
		|	END                             AS Purpose,
		|	TabularSection.Ref             AS ProductionOrder,
		|	TabularSection.KeyProducts   AS KeyProducts,
		|	TabularSection.Count         AS Count,
		|	TabularSection.NumberOfPackages AS NumberOfPackages,
		|	TabularSection.Package           AS Package,
		|	ISNULL(&PackagingFactor, 1) AS PackagingFactor,
		|	TabularSection.LineNumber        AS LineNumber,
		|	TabularSection.DemandDate    AS DemandDate,
		|	TabularSection.Ref.ProductionProcessType AS ProcessType
		|INTO TTOrderDetails
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|WHERE
		|	TabularSection.Ref = &ReferenceOrder
		|	AND NOT TabularSection.Canceled
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, ProductionOrder, KeyProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderData.Products       AS Products,
		|	OrderData.Characteristic     AS Characteristic,
		|	OrderData.Warehouse              AS Recipient,
		|	OrderData.Purpose         AS Purpose,
		|	OrderData.NumberOfPackages AS NumberOfPackages,
		|	OrderData.Package           AS Package,
		|	OrderData.LineNumber        AS LineNumber,
		|	OrderData.DemandDate    AS DemandDate,
		|	OrderData.ProcessType        AS ProcessType,
		|	CASE
		|		WHEN OrderData.Count = SUM(ISNULL(OrderStructure.Done, 0))
		|			THEN OrderData.NumberOfPackages
		|		ELSE SUM(ISNULL(OrderStructure.Done, 0)) / OrderData.PackagingFactor
		|	END                             AS NumberOfPackagesIsReady,
		|	MIN(Schedule.Begin)            AS StartProduction,
		|	MAX(Schedule.Ending)        AS EndOfProduction,
		|	MIN(ChartModel.Begin)     AS StartModelProduction,
		|	MAX(ChartModel.Ending) AS EndingModelProducts,
		|	MIN(GraphTotal.Begin)            AS BeginningOfLife,
		|	MAX(GraphTotal.Ending)        AS EndOfOrder,
		|	MIN(GraphModelTotals.Begin)     AS BeginningOfModel,
		|	MAX(GraphModelTotals.Ending) AS EndingModelOrder
		|FROM
		|	TTOrderDetails AS OrderData
		|
		|	LEFT JOIN InformationRegister.OrderStructure AS OrderStructure
		|	ON OrderData.Products = OrderStructure.Products
		|		AND OrderData.Characteristic = OrderStructure.Characteristic
		|		AND OrderData.Warehouse = OrderStructure.Warehouse
		|		AND OrderData.Purpose = OrderStructure.Purpose
		|		AND OrderData.ProductionOrder = OrderStructure.ProductionOrder
		|		AND OrderData.KeyProducts = OrderStructure.KeyProducts
		|		AND OrderStructure.LineKind IN (
		|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct))
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|	ON OrderData.ProductionOrder = Schedule.ProductionOrder
		|		AND Schedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|		AND OrderStructure.KeyLot = Schedule.KeyLot
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS GraphTotal
		|	ON OrderData.ProductionOrder = GraphTotal.ProductionOrder
		|		AND GraphTotal.ScheduleStatus = &StatusWorkingSchedule
		|		AND GraphTotal.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|		AND GraphTotal.KeyLot = &EmptyLinkKey
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS ChartModel
		|	ON OrderData.ProductionOrder = ChartModel.ProductionOrder
		|		AND ChartModel.ScheduleStatus = &StatusChartModel
		|		AND ChartModel.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|		AND OrderStructure.KeyLot = ChartModel.KeyLot
		|		AND &ModelIsPlanned
		|
		|	LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS GraphModelTotals
		|	ON OrderData.ProductionOrder = GraphModelTotals.ProductionOrder
		|		AND GraphModelTotals.ScheduleStatus = &StatusChartModel
		|		AND GraphModelTotals.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
		|		AND GraphModelTotals.KeyLot = &EmptyLinkKey
		|		AND &ModelIsPlanned
		|
		|GROUP BY
		|	OrderData.Products,
		|	OrderData.Characteristic,
		|	OrderData.Warehouse,
		|	OrderData.Purpose,
		|	OrderData.Count,
		|	OrderData.NumberOfPackages,
		|	OrderData.Package,
		|	OrderData.PackagingFactor,
		|	OrderData.LineNumber,
		|	OrderData.DemandDate,
		|	OrderData.ProcessType
		|
		|ORDER BY
		|	LineNumber";
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TabularSection.Package",
			"TabularSection.Products"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTermsOfProduction(ScheduleIsPlanned, ModelIsPlanned)
	
	Return 
		"SELECT
		|	NestedQuery.ProductionStage AS ProductionStage,
		|	MIN(NestedQuery.StageStart) AS StageStart,
		|	MAX(NestedQuery.StageEnd) AS StageEnd,
		|	MIN(NestedQuery.StartOfModelStage) AS StartOfModelStage,
		|	MAX(NestedQuery.EndOfModelStage) AS EndOfModelStage
		|INTO TTChart
		|FROM
		|	(SELECT
		|		WorkingSchedule.Stage AS ProductionStage,
		|		WorkingSchedule.Begin AS StageStart,
		|		WorkingSchedule.Ending AS StageEnd,
		|		NULL AS StartOfModelStage,
		|		NULL AS EndOfModelStage
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS WorkingSchedule
		|			LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS PreliminarySchedule
		|			ON WorkingSchedule.Stage = PreliminarySchedule.Stage
		|				AND (PreliminarySchedule.ScheduleStatus = &StatusPreliminarySchedule)
		|				AND (&ScheduleIsPlanned)
		|	WHERE
		|		WorkingSchedule.ProductionOrder = &ReferenceOrder
		|		AND WorkingSchedule.ScheduleStatus = &StatusWorkingSchedule
		|		AND PreliminarySchedule.ProductionOrder IS NULL
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		PreliminarySchedule.Stage,
		|		PreliminarySchedule.Begin,
		|		PreliminarySchedule.Ending,
		|		NULL,
		|		NULL
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS PreliminarySchedule
		|	WHERE
		|		PreliminarySchedule.ProductionOrder = &ReferenceOrder
		|		AND PreliminarySchedule.ScheduleStatus = &StatusPreliminarySchedule
		|		AND &ScheduleIsPlanned
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ChartModel.Stage,
		|		NULL,
		|		NULL,
		|		ChartModel.Begin,
		|		ChartModel.Ending
		|	FROM
		|		InformationRegister.ScheduleOfProductionStages2_2 AS ChartModel
		|	WHERE
		|		ChartModel.ProductionOrder = &ReferenceOrder
		|		AND ChartModel.ScheduleStatus = &StatusChartModel
		|		AND &ModelIsPlanned) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.ProductionStage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(TTChart.StageStart) AS Begin,
		|	MAX(TTChart.StageEnd) AS Ending,
		|	MIN(TTChart.StartOfModelStage) AS StartModel,
		|	MAX(TTChart.EndOfModelStage) AS EndingModel
		|INTO TTTermsOfOrders
		|FROM
		|	TTChart AS TTChart
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Document.ProductionProcessType AS ProcessType,
		|	TabularSection.Products AS Products,
		|	TabularSection.Characteristic AS Characteristic,
		|	TabularSection.Purpose AS Purpose,
		|	CASE
		|		WHEN TabularSection.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Warehouse
		|	END AS Recipient,
		|	TabularSection.Package AS Package,
		|	MIN(TabularSection.NumberOfPackages) AS NumberOfPackages,
		|	TTTermsOfOrders.Begin AS BeginningOfLife,
		|	TTTermsOfOrders.Ending AS EndOfOrder,
		|	TTTermsOfOrders.StartModel AS BeginningOfModel,
		|	TTTermsOfOrders.EndingModel AS EndingModelOrder,
		|	MIN(TTChart.StageStart) AS StartProduction,
		|	MAX(TTChart.StageEnd) AS EndOfProduction,
		|	MIN(TTChart.StartOfModelStage) AS StartModelProduction,
		|	MAX(TTChart.EndOfModelStage) AS EndingModelProducts,
		|	TabularSection.LineNumber AS LineNumber,
		|	TabularSection.DemandDate AS DemandDate
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|		LEFT JOIN TTStagesProvidingOrders AS TTStages
		|		ON TabularSection.Products = TTStages.Products
		|			AND TabularSection.Characteristic = TTStages.Characteristic
		|			AND TabularSection.Purpose = TTStages.Purpose
		|			AND TabularSection.Warehouse = TTStages.Warehouse
		|			AND TabularSection.BillOfMaterials = TTStages.BillOfMaterials
		|		LEFT JOIN TTTermsOfOrders AS TTTermsOfOrders
		|		ON (TRUE)
		|		LEFT JOIN TTChart AS TTChart
		|		ON (TTStages.Stage = TTChart.ProductionStage)
		|		LEFT JOIN Document.ProductionOrder2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	TabularSection.Ref = &ReferenceOrder
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	CASE
		|		WHEN TabularSection.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN TabularSection.Department
		|		ELSE TabularSection.Warehouse
		|	END,
		|	Document.ProductionProcessType,
		|	TabularSection.Products,
		|	TabularSection.Purpose,
		|	TabularSection.Package,
		|	TabularSection.Characteristic,
		|	TTTermsOfOrders.Begin,
		|	TTTermsOfOrders.StartModel,
		|	TTTermsOfOrders.Ending,
		|	TTTermsOfOrders.EndingModel,
		|	TabularSection.LineNumber,
		|	TabularSection.DemandDate
		|
		|ORDER BY
		|	TabularSection.LineNumber";
	
EndFunction

#EndRegion

#Region Other

Procedure PlanAndRecordScheduleInBackground(PlanningSettings, StorageAddress) Export
	
	PlanningResults = PlanAndRecordSchedule(PlanningSettings);
	PutToTempStorage(PlanningResults, StorageAddress);
	
EndProcedure

Function FixTaskNumberForCalculatingProductionSchedule()
	
	BeginTransaction();
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("Constant.NumberOfJobForCalculatingProductionSchedule");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		JobNumber = Constants.NumberOfJobForCalculatingProductionSchedule.Get();
		Constants.NumberOfJobForCalculatingProductionSchedule.Set(JobNumber+1);
		
		CommitTransaction();
			
	Except
		
		RollbackTransaction();
		
 		EventName = NStr("vi = 'Lịch biểu sản xuất';
							|ru = 'График производства';
							|en = 'Production schedule'; fa = 'برنامه زمان‌بندی تولید';
							|it = 'Piano di produzione';
							|pl = 'Harmonogram produkcji';
							|tr = 'Üretim programı'", CommonClientServer.DefaultLanguageCode())
			+ "."
			+ NStr("vi = 'Lập kế hoạch';
					|ru = 'Планирование';
					|en = 'Planning'; fa = 'برنامه‌ریزی';
					|it = 'Pianificazione';
					|pl = 'Planowanie';
					|tr = 'Planlama'", CommonClientServer.DefaultLanguageCode());
 		Level = EventLogLevel.Error;
		Comment = DetailErrorDescription(ErrorInfo());
		WriteLogEvent(EventName, Level,,, Comment);
		
		Raise;
		
	EndTry;
	
	Return JobNumber;
	
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

Function PreliminarySchedulePlanningResults(
													GraphResults_,
													ModelResults,
													NumberOfJobForCalculatingProductionSchedule,
													CancelManualChangesOfSchedule)
	
	Result = New Structure;
	
	Errors = InitializeSchedulingErrors();
	Notifications = New Map;
	
	For Cnt = 1 To 2 Do
		
		If Cnt = 1 Then
			PlanningResults = GraphResults_;
			FlagName = "ScheduleIsPlanned";
		Else
			PlanningResults = ModelResults;
			FlagName = "ModelIsPlanned";
		EndIf;
		
		If ValueIsFilled(PlanningResults) Then
			
			Result.Insert(FlagName, PlanningResults.ScheduleIsPlanned);
			
			For Each String In PlanningResults.Errors Do
				NewRow = Errors.Add();
				FillPropertyValues(NewRow, String);
			EndDo;
			
			For Each KeyAndValue In PlanningResults.Notifications Do
				Notifications.Insert(KeyAndValue.Key, KeyAndValue.Value);
			EndDo;
			
		Else
			Result.Insert(FlagName, False);
		EndIf;
		
	EndDo;
	
	Result.Insert("Errors", Errors);
	Result.Insert("Notifications", Notifications);
	
	PlacedStages = ?(GraphResults_ = Undefined, New Array, GraphResults_.PlacedStages);
	Result.Insert("PlacedStages", PlacedStages);
	
	Result.Insert("NumberOfJobForCalculatingProductionSchedule", NumberOfJobForCalculatingProductionSchedule);
	Result.Insert("CancelManualChangesOfSchedule", CancelManualChangesOfSchedule);
	
	Return Result;
	
EndFunction

Function ResultsOfBackgroundSchedulePlanning(ResultAddresses)
	
	Result = New Structure("GraphResults_, ModelResults", Undefined, Undefined);
	
	For Each StorageAddress In ResultAddresses Do
		
		If IsTempStorageURL(StorageAddress) Then
			
			PlanningResults = GetFromTempStorage(StorageAddress);
			
			If TypeOf(PlanningResults) = Type("Structure") Then
				
				If PlanningResults.ScheduleStatus =
					InformationRegisters.ScheduleOfProductionStages2_2.StatusPreliminarySchedule() Then
					
					Result.GraphResults_ = PlanningResults;
					
				ElsIf PlanningResults.ScheduleStatus =
					InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel() Then
					
					Result.ModelResults = PlanningResults;
					
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure WriteSchedule(PlanningParameters)
	
	BeginTransaction();
	Try
		
		InformationRegisters.ScheduleOfProductionStages2_2.RecordPlanningResults(
			PlanningParameters.ProductionOrder,
			PlanningParameters.ScheduleStatus,
			PlanningParameters.ProductionSchedule);
		
		If PlanningParameters.ScheduleStatus = InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule() Then
			
			Stages = ArrayOfPlacedStages(PlanningParameters);
			
			AccumulationRegisters.AvailabilityOfWorkCenterTypes.RecordBusyProductionSchedule(
				Stages,
				PlanningParameters.LoadingVRC);
			
			WhenRecordingWorkSchedule(
				PlanningParameters.ProductionOrder,
				Stages,
				PlanningParameters.NumberOfJobForCalculatingProductionSchedule,
				PlanningParameters.CancelManualChangesOfSchedule);
			
		Else
			
			InformationRegisters.CreatingScheduleForWorkCenterTypes.RecordPlanningResults(
				PlanningParameters.ProductionOrder,
				PlanningParameters.ScheduleStatus,
				PlanningParameters.LoadingVRC);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Comment = DetailErrorDescription(ErrorInfo());
		LogGraphRecordingError(Comment);
		
		Raise;
		
	EndTry;
	
EndProcedure

Function ThisIsUBBVStage(Stage)
	
	Return Not Stage.PlanOperationsOfWorkCenterTypes Or Stage.ProductionByThirdParty;
	
EndFunction

Function CalendarDataSamplingPeriod(PlanningParameters)
	
	Result = New Structure("Begin, Ending");
	
	Result.Begin = BegOfDay(CurrentSessionDate());
	
	If PlanningParameters.GoBackToBeginning Then
		Result.Ending = '39991201235959';
	Else
		Result.Ending = EndOfDay(PlanningParameters.DemandDate);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddSequenceNumberOfRowsToTable(Table)
	
	TMCommonUse.AddSequenceNumberOfRowsToTable(Table);
	
EndProcedure

Function FindRowsWithPreservingOrder(Table, SearchCondition, LinesAreNumbered=False)
	
	Return TMCommonUse.FindRowsWithPreservingOrder(Table, SearchCondition,LinesAreNumbered);
	
EndFunction

Function LeadToBeginningOfPeriod(Date, PlanningInterval)
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		Result = BegOfDay(Date);
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		Result = BegOfWeek(Date);
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		Result = BegOfMonth(Date);
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		Result = BegOfHour(Date);
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Result = Date;
	EndIf;
	
	Return Result;
	
EndFunction

Function LeadToEndOfPeriod(Date, PlanningInterval)
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		Result = EndOfDay(Date) + 1;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		Result = EndOfWeek(Date) + 1;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		Result = EndOfMonth(Date) + 1;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		Result = EndOfHour(Date) + 1;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Result = Date;
	EndIf;
	
	Return Result;
	
EndFunction

Function ResultInPlanningIntervalBoundary(Date, PlanningInterval, IntervalEndpoint)
	
	Return LeadToBeginningOfPeriod(Date, PlanningInterval)
		+ LimitOfIntervalInSeconds(IntervalEndpoint, PlanningInterval);
	
EndFunction

Function LimitOfIntervalInSeconds(Date, PlanningInterval)
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		Result = Hour(Date) * 3600 + Minute(Date) * 60 + Second(Date);
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		Result = (WeekDay(Date)-1) * 86400 + Hour(Date) * 3600 + Minute(Date) * 60 + Second(Date);
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ExcludeSubsequentStepsFromCalculationRecursively(PlanningParameters, ParentStage)
	
	SubsequentStages = RelatedStageData(PlanningParameters, ParentStage.ProductionStage, True);
	For Each Stage In SubsequentStages Do
		
		If Stage.Allocate Then
			
			Stage.Allocate = False;
			ExcludeSubsequentStepsFromCalculationRecursively(PlanningParameters, Stage);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function SchedulingIntervalHasNonStandardBoundaries(Stage)
	
	PlanningInterval = Stage.PlanningInterval;
	Begin = Stage.PlanningIntervalStart;
	Ending = Stage.PlanningIntervalEnd;
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		
		Result = Not BegOfDay(Begin) = Begin
			Or Not EndOfDay(Ending) = Ending;
			
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		
		Result = Not BegOfWeek(Begin) = Begin
			Or Not EndOfWeek(Ending) = Ending;
			
	Else
		
		Result = False;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure BringGraphDatesToCustomPresentation(PlanningParameters)
	
	For Each String In PlanningParameters.ProductionSchedule Do
		
		If String.Begin = String.Ending Then
			Continue;
		EndIf;
		
		If String.FollowUpBufferStart = String.Ending Then
			String.FollowUpBufferStart = String.FollowUpBufferStart - 1;
		EndIf;
		String.Ending = String.Ending - 1;
		
	EndDo;
	
EndProcedure

Procedure WhenRecordingWorkSchedule(ReferenceOrder, Stages, JobNumber, CancelManualChangesOfSchedule)
	
	InformationRegisters.JobsToProductionScheduleCalculation.DeleteTasksByNumber(ReferenceOrder, Stages, JobNumber);

	ProductionManagement.CheckOrderOfSteps(Stages);
	
	If CancelManualChangesOfSchedule Then
		Query = New Query(
			"SELECT
			|	T.Ref AS Stage
			|FROM
			|	Document.ProductionStage2_2 AS T
			|WHERE
			|	T.Ref IN(&Stages)
			|	AND T.StagePlacementInProductionSchedule
			|	AND T.Posted");
		Query.SetParameter("Stages", Stages);
		StagesToCancellation = Query.Execute().Unload().UnloadColumn("Stage");
		
		Documents.ProductionStage2_2.CancelManualPlacementOfStagesInSchedule(StagesToCancellation);
	EndIf;
	
	UniversalQueueOfRealTimeJobs.ProcessTasks_(
		Stages,
		Enums.UniversalQueueTasks.UpdatingScheduleOfRegisteredRecordsOfGoodsByStagesOfProduction);
		
	RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
	RegistersToBeReflected.StatesOfProductionOrders = True;
	DocumentsStates.AddTasksToStateOfOrders(Undefined, ReferenceOrder,, RegistersToBeReflected);
	
EndProcedure

Function TypesOfWorkingStageCenters(PlanningParameters, Stage)
	
	TheStructureOfTheSearch = New Structure("ProductionStage", Stage.ProductionStage);
	
	Return FindRowsWithPreservingOrder(
		PlanningParameters.StagePerformers_,
		TheStructureOfTheSearch,
		True);
	
EndFunction

Function PresentationStage(ProductionStage)
	
	Attributes = Common.ObjectAttributesValues(ProductionStage, "StageName, Number");
	
	Return Attributes.StageName + " (" + Attributes.Number + ")";
	
EndFunction

Function ArrayOfStagesToPlace(PlanningParameters)
	
	TheStructureOfTheSearch = New Structure("Allocate", True);
	Table_Selection = PlanningParameters.Stages.Copy(TheStructureOfTheSearch, "ProductionStage");
	Return Table_Selection.UnloadColumn("ProductionStage");
	
EndFunction

Function ArrayOfPlacedStages(PlanningParameters)
	
	TheStructureOfTheSearch = New Structure("Posted_", True);
	Table_Selection = PlanningParameters.Stages.Copy(TheStructureOfTheSearch, "ProductionStage");
	Return Table_Selection.UnloadColumn("ProductionStage");
	
EndFunction

Function SchedulePlanningOptions() Export
	
	PlanningSettings = InitializeSchedulingSettings(1);
	Result = InitializePlanningParameters(PlanningSettings);
	FillPropertyValues(Result, PlanningSettings);
	
	Return Result;
	
EndFunction

Procedure LogGraphRecordingError(Comment)
	
	EventName = NStr("vi = 'Lịch biểu sản xuất';
					|ru = 'График производства';
					|en = 'Production schedule'; fa = 'برنامه زمان‌بندی تولید';
					|it = 'Piano di produzione';
					|pl = 'Harmonogram produkcji';
					|tr = 'Üretim programı'", CommonClientServer.DefaultLanguageCode())
		+ "."
		+ NStr("vi = 'Bản ghi';
				|ru = 'Запись';
				|en = 'Record'; fa = 'ثبت';
				|it = 'Registrazione';
				|pl = 'Zapis';
				|tr = 'Kayıt'", CommonClientServer.DefaultLanguageCode());
	Level = EventLogLevel.Error;
	
	WriteLogEvent(EventName, Level,,, Comment);
	
EndProcedure

Function StageIsPlacedManually(PlanningParameters, Stage)
	
	Return Stage.StagePlacementInProductionSchedule And Not PlanningParameters.CancelManualChangesOfSchedule;
	
EndFunction

Procedure ReadNumberOfObjectsToSchedule(
													PlacedManually_,
													CalculateTheSchedule,
													ThereArePriorities,
													ThereAreEntriesInSchedule,
													References,
													TempTablesManager,
													TempTableName) Export
	
	Query = New Query(
	"SELECT
	|	COUNT(DISTINCT ProductionStage2_2.Ref) AS Count
	|FROM
	|	Document.ProductionStage2_2 AS ProductionStage2_2
	|WHERE
	|	ProductionStage2_2.ReferenceOrder IN (&References)
	|	AND ProductionStage2_2.Status IN(&StageStatuses_2)
	|	AND ProductionStage2_2.StagePlacementInProductionSchedule = TRUE
	|	AND ProductionStage2_2.Posted = TRUE
	|
	|HAVING
	|	COUNT(DISTINCT ProductionStage2_2.Ref) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DISTINCT JobsToProductionScheduleCalculation.ProductionStage) AS Count
	|FROM
	|	InformationRegister.JobsToProductionScheduleCalculation AS JobsToProductionScheduleCalculation
	|WHERE
	|	JobsToProductionScheduleCalculation.ReferenceOrder IN (&References)
	|
	|HAVING
	|	COUNT(DISTINCT JobsToProductionScheduleCalculation.ProductionStage) > 0
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
	|WHERE
	|	Jobs.ProductionOrder IN (&References)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	JobsToProductionScheduleCalculation.ProductionStage AS ProductionStage
	|FROM
	|	InformationRegister.JobsToProductionScheduleCalculation AS JobsToProductionScheduleCalculation
	|WHERE
	|	JobsToProductionScheduleCalculation.ReferenceOrder IN
	|			(SELECT
	|				T.Ref
	|			FROM
	|				TTPriorityOrders AS T)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
	|WHERE
	|	Schedule.ProductionOrder IN (&References)
	|	AND Schedule.ScheduleStatus = &StatusWorkingSchedule
	|	AND Schedule.Stage <> VALUE(Catalog.ProductionStages.EmptyRef)");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("References", References);
	Query.SetParameter("StageStatuses_2", StatusesStageCanBeScheduled());
	Query.SetParameter("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	
	ResultsArray = Query.ExecuteBatch(); 
	
	Selection = ResultsArray[0].Select();
	If Selection.Next() And ValueIsFilled(Selection.Count) Then
		PlacedManually_ = Selection.Count;
	Else
		PlacedManually_ = 0;
	EndIf;
	
	Selection = ResultsArray[1].Select();
	If Selection.Next() And ValueIsFilled(Selection.Count) Then
		CalculateTheSchedule = Selection.Count;
	Else
		CalculateTheSchedule = 0;
	EndIf;
	
	Selection = ResultsArray[2].Select();
	If Selection.Next() And ValueIsFilled(Selection.ProductionStage) Then
		ThereArePriorities = True;
	Else
		ThereArePriorities = False;
	EndIf;
	
	ThereAreEntriesInSchedule = Not ResultsArray[3].IsEmpty();
	
EndProcedure

Function PlanningByProductionResourcesIsUsed()
	
	Settings = ProductionServer.SubsystemSettingsProduction();
	
	Return Settings.PlanningByProductionResourcesIsUsed;
	
EndFunction

Function StatusesStageCanBeScheduled()
	
	Result = New Array;
	Result.Add(Enums.StatusesOfProductionStages2_2.BeingGenerated);
	Result.Add(Enums.StatusesOfProductionStages2_2.Generated1);
	Result.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
	
#EndIf
