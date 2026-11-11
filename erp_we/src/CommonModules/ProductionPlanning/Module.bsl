////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of production planning and production schedule calculation
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of production 2.1.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	Return; // empty handler
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

#EndRegion


#Region RoutineAssignment_CalculationOfProductionSchedule

// Searches for a predefined routine task "production schedule Calculation" using its metadata.
// 
// Returns:
//  ScheduledJob - the routine task "Calculation of the production schedule".
//
Function TaskCalculationOfProductionSchedule() Export
	
	PredefinedMetadata = Metadata.ScheduledJobs.Find("CreateProductionSchedule");
	
	If PredefinedMetadata = Undefined Then
		Job = Undefined;
	Else
	
		Filter = New Structure("Metadata", PredefinedMetadata);
		
		FoundJobs = ScheduledJobsServer.FindJobs(Filter);
		Job = ?(FoundJobs.Count() > 0, FoundJobs[0], Undefined);
	
	EndIf;
	
	Return Job;
	
EndFunction

// Checks usage and, if necessary, disables the scheduled task "production schedule Calculation".
//
Procedure CheckDisableRoutineTaskProductionScheduleCalculation() Export
	
	If Constants.UseProductionManagement.Get()
		Or Constants.UseProductionManagement2_2.Get() 
			And (Constants.UsePlanningByMaterialResources.Get()
				Or Constants.UsePlanningByProductionResources.Get()
			) Then
			Return;
	EndIf;
	
	Job = TaskCalculationOfProductionSchedule();
	If Job = Undefined Then
		Return;
	EndIf;
	ScheduledJobsServer.ChangeJob(Job, New Structure("Use", False));
	
EndProcedure

// Returns a predefined schedule for automatically scheduling the production schedule in the service model.
// Completing the task every day at 01: 00.
// 
// Returns:
//   - JobSchedule - predefined schedule of routine tasks.
//
Function PredefinedSchedule() Export
	
	Months = New Array;
	Months.Add(1);
	Months.Add(2);
	Months.Add(3);
	Months.Add(4);
	Months.Add(5);
	Months.Add(6);
	Months.Add(7);
	Months.Add(8);
	Months.Add(9);
	Months.Add(10);
	Months.Add(11);
	Months.Add(12);
	
	WeekDays = New Array;
	WeekDays.Add(1);
	WeekDays.Add(2);
	WeekDays.Add(3);
	WeekDays.Add(4);
	WeekDays.Add(5);
	WeekDays.Add(6);
	WeekDays.Add(7);
	
	Schedule = New JobSchedule;
	Schedule.Months            = Months;
	Schedule.WeekDays         = WeekDays;
	Schedule.BeginTime       = Date('00010101010000'); // 01:00
	Schedule.DaysRepeatPeriod = 1; // every day
	
	Return Schedule;
EndFunction

// Calculates the production schedule for a queue of orders with an outdated schedule
//
//
Procedure CreateProductionSchedule() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CreateProductionSchedule);
	
	If IsBlankString(UserName()) Then
		
		SetPrivilegedMode(True);
		
	EndIf;
	
	Settings = ProductionServer.SubsystemSettingsProduction();
	
	
	If Settings.ProductionIsUsed22 And Settings.TheProductionScheduleIsPlanned Then
		
		ProductionManagement.ScheduleQueueOfProductionOrders();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Returns the work schedule specified in the work schedules
//
// Parameters:
//	ListOfGraphs - Array - list of calendars
//	BeginOfPeriod - Date - beginning of the period for which you want to generate
//	PeriodEnding - Date - end of the period.
//  RollingShifts - Boolean - if True, then the schedule intervals may cross the border of the day.
//
// Returns:
//   ValueTable   - Work schedule.
//
Function ScheduleOfWorkOnSchedule(ListOfGraphs, BeginOfPeriod, PeriodEnding, RollingShifts = False) Export

	Schedule = CalendarSchedules.WorkSchedulesForPeriod(ListOfGraphs, BeginOfPeriod, PeriodEnding, RollingShifts);
	
	Schedule.Columns.Add("Duration", New TypeDescription("Number", New NumberQualifiers(10)));
	
	For Each ScheduleLine In Schedule Do
		If ScheduleLine.BeginTime = NULL Then
			ScheduleLine.BeginTime = '000101010000';
		EndIf; 
		If ScheduleLine.EndTime = NULL Then
			ScheduleLine.EndTime = '00010101235959';
		EndIf; 
		
		ScheduleLine.Duration = ProductionManagementClientServer.DurationOfScheduleInterval(
			ScheduleLine.BeginTime, ScheduleLine.EndTime);
	EndDo;

	Return Schedule;
	
EndFunction

#EndRegion

#EndRegion

#Region Supply


#EndRegion

