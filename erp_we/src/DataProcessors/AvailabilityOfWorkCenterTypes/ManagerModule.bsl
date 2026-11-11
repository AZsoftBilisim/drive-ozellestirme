#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region ServiceExportProceduresAndFunctions

// Function-constructor of the RC schedule table
// 
// Returns:
// 	ValueTable - LongDesc:
// * WorkCenterType - CatalogRef.WorkCenterTypes - View of the work center
// * WorkCenter - CatalogRef.WorkCenters - work center
// * ScheduleDate - Date - date on schedule
// * BeginTime - Date - start time according to the schedule
// * EndTime - Date - end time according to the schedule
// * Count - Number - Count
// * ManualChangesMade - Boolean - indicates that the schedule has been manually changed
//
Function CreateTableScheduleOfRCWorkSchedules() Export

	ScheduleOfWorkSchedulesOfRC = New ValueTable;
	ScheduleOfWorkSchedulesOfRC.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("ScheduleDate", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("BeginTime", New TypeDescription("Date",,, New DateQualifiers(DateFractions.Time)));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("EndTime", New TypeDescription("Date",,, New DateQualifiers(DateFractions.Time)));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(10, 2, AllowedSign.Nonnegative)));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("ManualChangesMade", New TypeDescription("Boolean"));
	ScheduleOfWorkSchedulesOfRC.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));

	Return ScheduleOfWorkSchedulesOfRC;
	
EndFunction

Function FillInWorkSchedulesOfRC(WorkCenterType, RCData, BeginOfPeriod, PeriodEnding, ScheduleOfWorkSchedulesOfRC, PlanningInterval) Export
	
	ScheduleOfWorkSchedulesOfRCCopy = ScheduleOfWorkSchedulesOfRC.Copy();
	IntervalChange = (PlanningInterval = Enums.ProductionScheduleAccuracy.Shift);
	
	// We will delete the old data for the specified RC
	TheStructureOfTheSearch = New Structure("WorkCenterType", WorkCenterType);
	OldDataOnTypeOfRC = ScheduleOfWorkSchedulesOfRC.FindRows(TheStructureOfTheSearch);
	
	// We will get work schedules
	ListOfGraphs = New Array;
	For Each RCString In RCData Do
		For Each WorkScheduleCalendar In RCString.WorkSchedules Do
			If ListOfGraphs.Find(WorkScheduleCalendar) = Undefined Then
				ListOfGraphs.Add(WorkScheduleCalendar);
			EndIf;
		EndDo;
	EndDo;
	WorkSchedules1 = ProductionPlanning.ScheduleOfWorkOnSchedule(
		ListOfGraphs,
		BeginOfPeriod,
		PeriodEnding,
		IntervalChange);
	
	NewAvailabilityDetails = New ValueTable;
	NewAvailabilityDetails.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	NewAvailabilityDetails.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
	NewAvailabilityDetails.Columns.Add("ScheduleDate", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	NewAvailabilityDetails.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers(10, 2, AllowedSign.Nonnegative)));
	NewAvailabilityDetails.Columns.Add("WorkTimeFactor", New TypeDescription("Number", New NumberQualifiers(5, 2, AllowedSign.Nonnegative)));
	
	CheckingIntervals = New ValueTable;
	CheckingIntervals.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	CheckingIntervals.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime)));
	
	For Each RCString In RCData Do
		// Delete the old data on the RC
		ArrayOfDeletedRows = New Array;
		For RowIndex = 0 To OldDataOnTypeOfRC.UBound() Do
			ScheduleLine = OldDataOnTypeOfRC[RowIndex];
			If ScheduleLine.ScheduleDate >= BeginOfPeriod 
				And ScheduleLine.ScheduleDate <= PeriodEnding 
				And ScheduleLine.WorkCenter = RCString.WorkCenter
				And (Not IntervalChange
					Or RCString.WorkSchedules.Find(ScheduleLine.Shift) <> Undefined) Then
				ScheduleOfWorkSchedulesOfRC.Delete(ScheduleLine);
				ArrayOfDeletedRows.Add(RowIndex);
			EndIf;
		EndDo;
		
		For RowIndex = -ArrayOfDeletedRows.UBound() To 0 Do
			OldDataOnTypeOfRC.Delete(ArrayOfDeletedRows[-RowIndex]);
		EndDo; 
		
		CheckingIntervals.Clear();
		
		// Let's add new ones
		PeriodDate_ = BeginOfPeriod;
		While PeriodDate_ <= PeriodEnding Do
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("ScheduleDate", PeriodDate_);
			LinesAdded = False;
			
			For Each WorkScheduleCalendar In RCString.WorkSchedules Do
				TheStructureOfTheSearch.Insert("WorkScheduleCalendar", WorkScheduleCalendar);
				ScheduleBySchedule = WorkSchedules1.FindRows(TheStructureOfTheSearch);
				
				RollingSchedule = False;
				EndDay = '00010101';
				
				For Each LineInterval In ScheduleBySchedule Do
					ScheduleLine = ScheduleOfWorkSchedulesOfRC.Add();
					ScheduleLine.WorkCenterType = WorkCenterType;
					ScheduleLine.WorkCenter = RCString.WorkCenter;
					ScheduleLine.ScheduleDate = LineInterval.ScheduleDate;
					ScheduleLine.BeginTime = LineInterval.BeginTime;
					ScheduleLine.EndTime = LineInterval.EndTime;
					ScheduleLine.Count = LineInterval.Duration;
					If IntervalChange Then
						ScheduleLine.Shift = WorkScheduleCalendar;
					EndIf;
					
					NewAvailability = NewAvailabilityDetails.Add();
					NewAvailability.WorkCenter = RCString.WorkCenter;
					NewAvailability.ScheduleDate = LineInterval.ScheduleDate;
					NewAvailability.Count = LineInterval.Duration;
					NewAvailability.WorkTimeFactor = RCString.WorkTimeFactor;
					If IntervalChange Then
						NewAvailability.Shift = WorkScheduleCalendar;
					EndIf;
					
					// Preparing to check intervals
					VerificationLine = CheckingIntervals.Add();
					
					VerificationLine.Begin = PeriodDate_
						+ Hour(ScheduleLine.BeginTime) * 3600
						+ Minute(ScheduleLine.BeginTime) * 60;
					
					If RollingSchedule
							Or ScheduleLine.BeginTime < EndDay Then
						// This schedule interval is completely located in the rolling shift
						If Not RollingSchedule Then
							RollingSchedule = True;
						EndIf;
						
						VerificationLine.Begin = VerificationLine.Begin + 86400;
						
						If ValueIsFilled(ScheduleLine.EndTime) Then
							VerificationLine.Ending = PeriodDate_
								+ Hour(ScheduleLine.EndTime) * 3600
								+ Minute(ScheduleLine.EndTime) * 60
								+ 86400;
						Else
							VerificationLine.Ending = EndOfDay(VerificationLine.Begin) + 1;
						EndIf;
					Else
						If Not ValueIsFilled(ScheduleLine.EndTime) Then
							RollingSchedule = True;
							VerificationLine.Ending = EndOfDay(VerificationLine.Begin) + 1;
						ElsIf ScheduleLine.BeginTime = ScheduleLine.EndTime
							Or ScheduleLine.BeginTime > ScheduleLine.EndTime Then
							RollingSchedule = True;
							VerificationLine.Ending = PeriodDate_
								+ Hour(ScheduleLine.EndTime) * 3600
								+ Minute(ScheduleLine.EndTime) * 60
								+ 86400;
						Else
							VerificationLine.Ending = PeriodDate_
								+ Hour(ScheduleLine.EndTime) * 3600
								+ Minute(ScheduleLine.EndTime) * 60;
						EndIf;
					EndIf;
					
					EndDay = ScheduleLine.EndTime;
					LinesAdded = True;
				EndDo;
				
				If ScheduleBySchedule.Count() = 0 And IntervalChange Then
					ScheduleLine = ScheduleOfWorkSchedulesOfRC.Add();
					ScheduleLine.WorkCenterType = WorkCenterType;
					ScheduleLine.WorkCenter = RCString.WorkCenter;
					ScheduleLine.ScheduleDate = PeriodDate_;
					ScheduleLine.Count = 0;
					ScheduleLine.Shift = WorkScheduleCalendar;
					
					NewAvailability = NewAvailabilityDetails.Add();
					NewAvailability.WorkCenter = RCString.WorkCenter;
					NewAvailability.ScheduleDate = PeriodDate_;
					NewAvailability.Count = 0;
					NewAvailability.WorkTimeFactor = RCString.WorkTimeFactor;
					NewAvailability.Shift = WorkScheduleCalendar;
				EndIf;
			EndDo;
			
			If Not LinesAdded And Not IntervalChange Then
				ScheduleLine = ScheduleOfWorkSchedulesOfRC.Add();
				ScheduleLine.WorkCenterType = WorkCenterType;
				ScheduleLine.WorkCenter = RCString.WorkCenter;
				ScheduleLine.ScheduleDate = PeriodDate_;
				ScheduleLine.Count = 0;
				
				NewAvailability = NewAvailabilityDetails.Add();
				NewAvailability.WorkCenter = RCString.WorkCenter;
				NewAvailability.ScheduleDate = PeriodDate_;
				NewAvailability.Count = 0;
				NewAvailability.WorkTimeFactor = RCString.WorkTimeFactor;
			EndIf; 
			
			PeriodDate_ = EndOfDay(PeriodDate_) + 1;
		EndDo;
		
		// Checking the intersection of intervals
		CheckingIntervals.Sort("Begin, Ending");
		For IndexOf = 1 To CheckingIntervals.Count()-1 Do
			If CheckingIntervals[IndexOf].Begin < CheckingIntervals[IndexOf-1].Ending Then
				MessageText = StrTemplate(NStr("vi = 'Lịch biểu làm việc của nguồn lực sản xuất ""%1"" giao nhau %2.';
												|ru = 'Графики работы рабочего центра ""%1"" пересекаются %2.';
												|en = 'Work schedules of the ""%1"" work center overlap %2.'; fa = 'Work schedules of the ""%1"" work center overlap %2.';
												|it = 'Gli orari di lavoro del centro di lavoro ""%1"" sono sovrapposti %2.';
												|pl = 'Harmonogramy wykonania pracy centrum roboczego ""%1"" pokrywają się %2.';
												|tr = '""%1"" iş merkezinin çalışma takvimi %2 çakışmaktadır.'"),
					RCString.WorkCenter,
					Format(CheckingIntervals[IndexOf].Begin, "DLF=D"));
				Common.MessageToUser(MessageText, RCString.WorkCenter);
				
				ScheduleOfWorkSchedulesOfRC = ScheduleOfWorkSchedulesOfRCCopy;
				Return Undefined;
			EndIf;
		EndDo;
		
	EndDo;

	Return NewAvailabilityDetails;
	
EndFunction

Function TypesOfRCThatRequireEnteringWorkSchedule(Department) Export

	Query = New Query;
	Query.Text = RequestTextIndicatorForEnteringAvailabilityForRCSchedule();
	
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Department", Department);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	Return Selection.IndicatorValue;

EndFunction

#EndRegion

#Region ToDoList


// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	CaseForAvailabilityForProductionSchedule(ToDoList, CommonQueryParameters);
	
	EnteringAvailabilityForRCSchedule(ToDoList, CommonQueryParameters);
	
EndProcedure


Procedure CaseForAvailabilityForProductionSchedule(ToDoList, CommonQueryParameters)
	
	FormName = "DataProcessor.AvailabilityOfWorkCenterTypes.Form";
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled = UserRightsCached.RightToEnterAvailabilityOfTypesOfRC()
					And GetFunctionalOption("UseProduction");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = RequestTextIndicatorAvailabilityIndicatorForProductionSchedule();
	
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
	
	Result = Query.Execute().Unload();
	
	// Filling out cases.
	// vidyrtsrequirement of water availability
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "TypesOfRCRequiringAccessibilityInput";
	UserTaskParent.Presentation  = NStr("vi = 'Các dạng nguồn lực sản xuất yêu cầu nhập mức độ khả dụng';
										|ru = 'Виды рабочих центров, требующие ввода доступности';
										|en = 'Work center types with manual capacity'; fa = 'Work center types with manual capacity';
										|it = 'I tipi dei centri di lavoro che richiedono l''immissione di accessibilità';
										|pl = 'Rodzaje centrów roboczych, które wymagają wprowadzania dostępności';
										|tr = 'Kullanılabilirlik girişi gereken iş merkezi türleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Production;
	
	For Each ResultString1 In Result Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("WorkMode", Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule);
		FilterParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
		
		UserTaskPresentation = "";
		CaseFileID = "";
		UserTaskValue      = 0;
		For Each ResultColumn In Result.Columns Do
			ColumnValue = ResultString1[ResultColumn.Name];
			If ResultColumn.Name = "IndicatorValue" Then
				UserTaskValue = ColumnValue;
				Continue;
			EndIf;
			UserTaskPresentation = ?(UserTaskPresentation = "", "", ", ") + String(ColumnValue);
			CaseFileID = ?(CaseFileID = "", UserTaskParent.Id, CaseFileID)
				+ StrReplace(String(ColumnValue), " ", "");
			FilterParameters.Insert(ResultColumn.Name, ColumnValue);
		EndDo;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = CaseFileID;
		ToDoItem.HasToDoItems       = UserTaskValue > 0;
		ToDoItem.Presentation  = UserTaskPresentation;
		ToDoItem.Count     = UserTaskValue;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
		ToDoItem.Owner       = "TypesOfRCRequiringAccessibilityInput";
		
		If UserTaskValue > 0 Then
			UserTaskParent.HasToDoItems = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure EnteringAvailabilityForRCSchedule(ToDoList, CommonQueryParameters)
	
	FormName = "DataProcessor.AvailabilityOfWorkCenterTypes.Form";
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled = UserRightsCached.RightToEnterWorkSchedulesOfRC()
					And GetFunctionalOption("UseProduction");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = RequestTextIndicatorForEnteringAvailabilityForRCSchedule();
	
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
	
	Result = Query.Execute().Unload();
	
	// Filling out cases.
	// rctreferencesvodagraphicareferences
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "RCRequiringInputOfWorkSchedule";
	UserTaskParent.Presentation  = NStr("vi = 'Nguồn lực sản xuất yêu cầu nhập lịch biểu làm việc';
										|ru = 'Рабочие центры, требующие ввода графика работы';
										|en = 'Work centers which require entering the work schedule'; fa = 'Work centers which require entering the work schedule';
										|it = 'I centri di lavoro che richiedono l''immissione dell''orario di lavoro';
										|pl = 'Centra robocze, które wymagają wprowadzania harmonogramu pracy';
										|tr = 'Çalışma takvimi girişi gereken iş merkezleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Production;
	
	For Each ResultString1 In Result Do
		
		FilterParameters = New Structure;
		FilterParameters.Insert("WorkMode", Enums.ModesOfEditingTypeOfWorkCentersAvailability.EnterWorkCenterScheduleToGenerateWorkCenterTimetable);
		FilterParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
		
		UserTaskPresentation = "";
		CaseFileID = "";
		UserTaskValue      = 0;
		For Each ResultColumn In Result.Columns Do
			ColumnValue = ResultString1[ResultColumn.Name];
			If ResultColumn.Name = "IndicatorValue" Then
				UserTaskValue = ColumnValue;
				Continue;
			EndIf;
			UserTaskPresentation = ?(UserTaskPresentation = "", "", ", ") + String(ColumnValue);
			CaseFileID = ?(CaseFileID = "", UserTaskParent.Id, CaseFileID)
				+ StrReplace(String(ColumnValue), " ", "");
			FilterParameters.Insert(ResultColumn.Name, ColumnValue);
		EndDo;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = CaseFileID;
		ToDoItem.HasToDoItems       = UserTaskValue > 0;
		ToDoItem.Presentation  = UserTaskPresentation;
		ToDoItem.Count     = UserTaskValue;
		ToDoItem.Important         = False;
		ToDoItem.Form          = FormName;
		ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
		ToDoItem.Owner       = "RCRequiringInputOfWorkSchedule";
		
		If UserTaskValue > 0 Then
			UserTaskParent.HasToDoItems = True;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

Function RequestTextIndicatorAvailabilityIndicatorForProductionSchedule()

	QueryText = 
	"SELECT ALLOWED
	|	DatesOfFilling.Department AS Department,
	|	ISNULL(COUNT(DatesOfFilling.WorkCenterType), 0) AS IndicatorValue
	|FROM
	|	(SELECT
	|		WorkCenterTypes.Department AS Department,
	|		WorkCenterTypes.Ref AS WorkCenterType,
	|		ISNULL(MAX(AvailabilityOfWorkCenterTypes.IntervalDate), DATETIME(1, 1, 1)) AS FilledInTo
	|	FROM
	|		Catalog.BusinessStructure AS BusinessStructure
	|			INNER JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|			ON WorkCenterTypes.Department = BusinessStructure.Ref
	|				AND WorkCenterTypes.UseAvailabilityAccordingToSchedule
	|				AND NOT WorkCenterTypes.DeletionMark
	|				AND NOT WorkCenterTypes.IsFolder
	|			LEFT JOIN AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
	|			ON (AvailabilityOfWorkCenterTypes.WorkCenterType = WorkCenterTypes.Ref)
	|				AND (AvailabilityOfWorkCenterTypes.IsRecordOfWorkCentersCapacityChange)
	|				AND (WorkCenterTypes.EnterAvailabilityForWorkCenterType
	|						AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenterType
	|					OR NOT WorkCenterTypes.EnterAvailabilityForWorkCenterType
	|						AND AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters)
	|	WHERE
	|		BusinessStructure.FillInAvailabilityForProductionScheduleReminderDays <> 0
	|	
	|	GROUP BY
	|		WorkCenterTypes.Ref,
	|		WorkCenterTypes.Department) AS DatesOfFilling
	|WHERE
	|	DatesOfFilling.FilledInTo < DATEADD(&CurrentDate, DAY, DatesOfFilling.Department.FillInAvailabilityForProductionScheduleReminderDays - 1)
	|
	|GROUP BY
	|	DatesOfFilling.Department";

	Return QueryText;
	
EndFunction

Function RequestTextIndicatorForEnteringAvailabilityForRCSchedule()

	QueryText = 
	"SELECT ALLOWED
	|	DatesOfFilling.Department AS Department,
	|	ISNULL(COUNT(DatesOfFilling.WorkCenterType), 0) AS IndicatorValue
	|FROM
	|	(SELECT
	|		WorkCenterTypes.Department AS Department,
	|		WorkCenterTypes.Ref AS WorkCenterType,
	|		ISNULL(MAX(AvailabilityOfWorkCenterTypes.IntervalDate), DATETIME(1, 1, 1)) AS FilledInTo
	|	FROM
	|		Catalog.BusinessStructure AS BusinessStructure
	|			INNER JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
	|			ON WorkCenterTypes.Department = BusinessStructure.Ref
	|				AND WorkCenterTypes.PlanOperationsOfWorkCenters
	|				AND NOT WorkCenterTypes.DeletionMark
	|				AND NOT WorkCenterTypes.IsFolder
	|			LEFT JOIN AccumulationRegister.AvailabilityOfWorkCenterTypes AS AvailabilityOfWorkCenterTypes
	|			ON (AvailabilityOfWorkCenterTypes.WorkCenterType = WorkCenterTypes.Ref)
	|				AND (AvailabilityOfWorkCenterTypes.IsRecordOfWorkCentersCapacityChange)
	|				AND (AvailabilityOfWorkCenterTypes.Recorder REFS Document.AvailabilityOfWorkCenters)
	|	WHERE
	|		BusinessStructure.FillInAvailabilityForWorkCenterTimetableReminderDays <> 0
	|		AND (BusinessStructure.Ref = &Department
	|				OR &Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|	
	|	GROUP BY
	|		WorkCenterTypes.Ref,
	|		WorkCenterTypes.Department) AS DatesOfFilling
	|WHERE
	|	DatesOfFilling.FilledInTo < DATEADD(&CurrentDate, DAY, DatesOfFilling.Department.FillInAvailabilityForWorkCenterTimetableReminderDays - 1)
	|
	|GROUP BY
	|	DatesOfFilling.Department";

	Return QueryText;
	
EndFunction

#EndRegion

#EndIf