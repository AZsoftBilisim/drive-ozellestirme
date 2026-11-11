#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("AvailabilityOfWorkCenters");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.AvailabilityOfWorkCenters") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	TablesForRegisteredRecords = New Structure;
	GenerateTablesForRegisteredRecords(TablesForRegisteredRecords, DocumentRef, Registers);
	Return TablesForRegisteredRecords;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
	
EndProcedure

// Adds a command to create the document "availability of work centers".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow
//  - Undefined
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AvailabilityOfWorkCenters) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AvailabilityOfWorkCenters.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AvailabilityOfWorkCenters);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure GenerateTablesForRegisteredRecords(TablesForRegisteredRecords, DocumentRef, Registers = Undefined)
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Attributes.WorkCenterType.Department AS Department,
	|	Attributes.WorkCenterType AS WorkCenterType,
	|	Attributes.WorkCenterType.Department.PlanningInterval AS PlanningInterval
	|FROM
	|	Document.AvailabilityOfWorkCenters AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref
	|
	|GROUP BY
	|	Attributes.WorkCenterType,
	|	Attributes.WorkCenterType.Department.PlanningInterval
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Intervals.Shift AS Shift,
	|	COUNT(DISTINCT Intervals.WorkCenter) AS NumberOfWorkCenters
	|FROM
	|	Document.AvailabilityOfWorkCenters.Intervals AS Intervals
	|WHERE
	|	Intervals.Ref = &Ref
	|
	|GROUP BY
	|	Intervals.Shift
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Intervals.ScheduleDate AS Date,
	|	Intervals.BeginTime AS BeginTime,
	|	Intervals.EndTime AS EndTime,
	|	Intervals.WorkCenter,
	|	Intervals.WorkCenter.WorkTimeFactor AS WorkTimeFactor,
	|	Intervals.Shift,
	|	Intervals.Count
	|FROM
	|	Document.AvailabilityOfWorkCenters.Intervals AS Intervals
	|WHERE
	|	Intervals.Ref = &Ref
	|ORDER BY
	|	Intervals.LineNumber";
	
	QueryResults = Query.ExecuteBatch();
	
	Attributes = QueryResults[0].Select();
	Attributes.Next();
	
	NumberOfRTSInShifts = New Map;
	Selection = QueryResults[1].Select();
	While Selection.Next() Do
		NumberOfRTSInShifts.Insert(Selection.Shift, Selection.NumberOfWorkCenters);
	EndDo;
	
	Interval = QueryResults[2].Select();
	
	// We form the availability of RC types by planning intervals
	TableAvailabilityOfTypesOfWorkCenters = New ValueTable;
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("Period",            New TypeDescription("Date"));
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("Department",     New TypeDescription("CatalogRef.BusinessStructure"));
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("IntervalDate",     New TypeDescription("Date"));
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("WorkCenterSchedule",   New TypeDescription("Number", New NumberQualifiers(8,1)));
	TableAvailabilityOfTypesOfWorkCenters.Columns.Add("Shift",             New TypeDescription("CatalogRef.Calendars"));
	
	TableAvailabilityOfWorkCenters = New ValueTable;
	TableAvailabilityOfWorkCenters.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	TableAvailabilityOfWorkCenters.Columns.Add("Begin", New TypeDescription("Date",,, New DateQualifiers));
	TableAvailabilityOfWorkCenters.Columns.Add("Ending", New TypeDescription("Date",,, New DateQualifiers));
	
	StateTableOfWorkCenters = New ValueTable;
	StateTableOfWorkCenters.Columns.Add("Period", New TypeDescription("Date"));
	StateTableOfWorkCenters.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	StateTableOfWorkCenters.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	StateTableOfWorkCenters.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	StateTableOfWorkCenters.Columns.Add("TimeAvailable",   New TypeDescription("Number", New NumberQualifiers(10)));
	
	ShiftsData = New ValueTable;
	ShiftsData.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenters"));
	ShiftsData.Columns.Add("Shift", New TypeDescription("CatalogRef.Calendars"));
	ShiftsData.Columns.Add("IntervalDate", New TypeDescription("Date"));
	ShiftsData.Columns.Add("RollingSchedule", New TypeDescription("Boolean"));
	ShiftsData.Columns.Add("EndDay", New TypeDescription("Date"));
	
	ShiftsData.Indexes.Add("WorkCenter, Shift");
	SearchStructureStart = New Structure("WorkCenter, Shift");
	
	If Attributes.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		While Interval.Next() Do
			FillPropertyValues(SearchStructureStart, Interval);
			FoundRows = ShiftsData.FindRows(SearchStructureStart);
			If FoundRows.Count() = 0 Then
				IntervalDate = BegOfDay(Interval.Date)
					+ Hour(Interval.BeginTime) * 3600
					+ Minute(Interval.BeginTime) * 60;
				
				LineChange = ShiftsData.Add();
				FillPropertyValues(LineChange, Interval);
				LineChange.IntervalDate = IntervalDate;
			Else
				LineChange = FoundRows[0];
			EndIf;
			
			AvailabilityLine_ = TableAvailabilityOfTypesOfWorkCenters.Add();
			AvailabilityLine_.Period            = LineChange.IntervalDate;
			AvailabilityLine_.WorkCenterType = Attributes.WorkCenterType;
			AvailabilityLine_.Department     = Attributes.Department;
			AvailabilityLine_.IntervalDate     = LineChange.IntervalDate;
			AvailabilityLine_.WorkCenterSchedule   = Interval.Count / Interval.WorkTimeFactor;
			AvailabilityLine_.Shift             = Interval.Shift;
			
			// Availability of work centers
			Begin = BegOfDay(Interval.Date)
				+ Hour(Interval.BeginTime) * 3600
				+ Minute(Interval.BeginTime) * 60;
			
			If LineChange.RollingSchedule
					Or Interval.BeginTime < LineChange.EndDay Then
				// This schedule interval is completely located in the rolling shift
				If Not LineChange.RollingSchedule Then
					LineChange.RollingSchedule = True;
				EndIf;
				
				Begin = Begin + 86400;
				
				If ValueIsFilled(Interval.EndTime) Then
					Ending = BegOfDay(Interval.Date)
						+ Hour(Interval.EndTime) * 3600
						+ Minute(Interval.EndTime) * 60
						+ 86400;
				Else
					Ending = EndOfDay(Begin) + 1;
				EndIf;
				
				RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
				RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
				RCAvailabilityLine.Begin = Begin;
				RCAvailabilityLine.Ending = Ending;
			Else
				If Not ValueIsFilled(Interval.EndTime) Then
					LineChange.RollingSchedule = True;
					Ending = EndOfDay(Begin) + 1;
					
					RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
					RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
					RCAvailabilityLine.Begin = Begin;
					RCAvailabilityLine.Ending = Ending;
				ElsIf Interval.BeginTime = Interval.EndTime
					Or Interval.BeginTime > Interval.EndTime Then
					LineChange.RollingSchedule = True;
					Ending = BegOfDay(Interval.Date)
						+ Hour(Interval.EndTime) * 3600
						+ Minute(Interval.EndTime) * 60
						+ 86400;
					
					RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
					RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
					RCAvailabilityLine.Begin = Begin;
					RCAvailabilityLine.Ending = EndOfDay(Begin) + 1;
					
					RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
					RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
					RCAvailabilityLine.Begin = EndOfDay(Begin) + 1;
					RCAvailabilityLine.Ending = Ending;
				Else
					Ending = BegOfDay(Interval.Date)
						+ Hour(Interval.EndTime) * 3600
						+ Minute(Interval.EndTime) * 60;
					
					RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
					RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
					RCAvailabilityLine.Begin = Begin;
					RCAvailabilityLine.Ending = Ending;
				EndIf;
			EndIf;
			
			LineChange.EndDay = Interval.EndTime;
		EndDo;
	Else
		While Interval.Next() Do
			If Attributes.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
				// With an Hour interval, the schedule periods may include several intervals
				// It is necessary to determine which intervals are included in the schedule period and how many seconds are in them.
				
				IntervalTime = BegOfHour(Interval.BeginTime);
				IntervalEnd_ = ?(ValueIsFilled(Interval.EndTime),
					Interval.EndTime,
					EndOfDay(Interval.BeginTime));
				While IntervalTime < IntervalEnd_ - 1 Do
					
					BeginTime = Max(Interval.BeginTime, IntervalTime);
					EndTime = Min(EndOfHour(IntervalTime) + 1, IntervalEnd_);
					
					IntervalDate = BegOfHour(Interval.Date + Hour(IntervalTime) * 3600 + Minute(IntervalTime) * 60 + Second(IntervalTime));
					
					If Not ValueIsFilled(EndTime) 
						Or EndOfMinute(EndTime) = '00010101235959' Then
						IntervalInSeconds = EndOfDay(EndTime) - BeginTime + 1;
					Else
						IntervalInSeconds = EndTime - BeginTime;
					EndIf;
					
					AvailabilityLine_ = TableAvailabilityOfTypesOfWorkCenters.Add();
					AvailabilityLine_.Period            = IntervalDate;
					AvailabilityLine_.WorkCenterType = Attributes.WorkCenterType;
					AvailabilityLine_.Department     = Attributes.Department;
					AvailabilityLine_.IntervalDate     = IntervalDate;
					AvailabilityLine_.WorkCenterSchedule   = IntervalInSeconds / Interval.WorkTimeFactor;
					IntervalTime = IntervalTime + 3600;
					
				EndDo;
			Else
				// For the remaining scheduling intervals, the schedule periods are always included in the scheduling interval.
				
				If Attributes.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
					IntervalDate = BegOfDay(Interval.Date);
				ElsIf Attributes.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
					IntervalDate = BegOfWeek(Interval.Date);
				Else
					IntervalDate = BegOfMonth(Interval.Date);
				EndIf;
				
				If Not ValueIsFilled(Interval.EndTime) 
					Or EndOfMinute(Interval.EndTime) = '00010101235959' Then
					IntervalInSeconds = EndOfDay(Interval.EndTime) - Interval.BeginTime + 1;
				Else
					IntervalInSeconds = Interval.EndTime - Interval.BeginTime;
				EndIf;
				
				AvailabilityLine_ = TableAvailabilityOfTypesOfWorkCenters.Add();
				AvailabilityLine_.Period            = IntervalDate;
				AvailabilityLine_.WorkCenterType = Attributes.WorkCenterType;
				AvailabilityLine_.Department     = Attributes.Department;
				AvailabilityLine_.IntervalDate     = IntervalDate;
				AvailabilityLine_.WorkCenterSchedule   = IntervalInSeconds / Interval.WorkTimeFactor;
			EndIf;
		
			BeginTime = Hour(Interval.BeginTime)*3600 + Minute(Interval.BeginTime)*60 + Second(Interval.BeginTime);
			StartOfRange = Interval.Date + BeginTime;
			EndOfTheInterval = StartOfRange + Interval.Count;
			
			RCAvailabilityLine = TableAvailabilityOfWorkCenters.Add();
			RCAvailabilityLine.WorkCenter = Interval.WorkCenter;
			RCAvailabilityLine.Begin = StartOfRange;
			RCAvailabilityLine.Ending = EndOfTheInterval;
			
			RCStateBar = StateTableOfWorkCenters.Add();
			FillPropertyValues(RCStateBar, Attributes);
			RCStateBar.Period = StartOfRange;
			RCStateBar.WorkCenter = Interval.WorkCenter;
			RCStateBar.TimeAvailable = Interval.Count;
		EndDo;
	EndIf;
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("AvailabilityOfWorkCenterTypes", Registers) Then
		
		TableAvailabilityOfTypesOfWorkCenters.GroupBy("IntervalDate, WorkCenterType, Department, Period, Shift", "WorkCenterSchedule");
		
		TableAvailabilityOfTypesOfWorkCenters.Columns.Add("MaximumAvailability", New TypeDescription("Number", New NumberQualifiers(8,1)));
		TableAvailabilityOfTypesOfWorkCenters.Columns.Add("IsRecordOfWorkCentersCapacityChange", New TypeDescription("Boolean"));
		TableAvailabilityOfTypesOfWorkCenters.Columns.Add("ThisIsProductionOrderrecord", New TypeDescription("Boolean"));
		TableAvailabilityOfTypesOfWorkCenters.Columns.Add("ThisIsOperationSheetRecord", New TypeDescription("Boolean"));
		
		For Each AvailabilityLine_ In TableAvailabilityOfTypesOfWorkCenters Do
			
			NumberOfRC = NumberOfRTSInShifts[AvailabilityLine_.Shift];
			If NumberOfRC <> Undefined Then
				AvailabilityLine_.MaximumAvailability = AvailabilityLine_.WorkCenterSchedule / NumberOfRC;
			EndIf;
			
			AvailabilityLine_.IsRecordOfWorkCentersCapacityChange     = True;
			AvailabilityLine_.ThisIsProductionOrderrecord = False;
			AvailabilityLine_.ThisIsOperationSheetRecord     = False;
			
		EndDo;
		
		TablesForRegisteredRecords.Insert("Table" + "AvailabilityOfWorkCenterTypes", TableAvailabilityOfTypesOfWorkCenters);
		
	EndIf;
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("AvailabilityOfWorkCenters", Registers) Then
		TablesForRegisteredRecords.Insert("Table" + "AvailabilityOfWorkCenters", TableAvailabilityOfWorkCenters);
	EndIf;
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("StatesOfWorkCenters", Registers) Then
		TablesForRegisteredRecords.Insert("Table" + "StatesOfWorkCenters", StateTableOfWorkCenters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
