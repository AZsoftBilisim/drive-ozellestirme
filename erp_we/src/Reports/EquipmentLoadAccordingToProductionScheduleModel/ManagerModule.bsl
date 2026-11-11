#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Generates a table with the most loaded equipment based on the production schedule model data.
//
// Parameters:
//  Parameters  - Structure - report generation parameters:
//		* ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order whose schedule needs to be analyzed.
//		* QuantityOfUnits - Number - the maximum number of RC types that need to be returned.
//			Data sampling and traversal are performed in descending order of download volume.
//  StorageAddress - String - address of the storage where the result will be placed.
//
Procedure GetMostLoadedHardware(Parameters, StorageAddress) Export
	
	ReferenceOrder = Parameters.ReferenceOrder;
	UnitsLeft = Parameters.QuantityOfUnits;
	
	Result = New ValueTable;
	Result.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Result.Columns.Add("LoadingPercentages", New TypeDescription("Number", New NumberQualifiers(5)));
	Result.Indexes.Add("WorkCenterType");
	
	Load = EquipmentLoadAsPercentage(ReferenceOrder);
	Load.Sort("LoadingPercentages Desc");
	
	For IndexOf = 0 To Load.Count()-1 Do
		
		String = Load[IndexOf];
		
		If Not ValueIsFilled(String.LoadingPercentages) Then
			Break;
		EndIf;
		
		If Result.Find(String.WorkCenterType, "WorkCenterType") = Undefined Then
			
			NewRow = Result.Add();
			FillPropertyValues(NewRow, String);
			
			UnitsLeft = UnitsLeft - 1;
			If UnitsLeft = 0 Then
				Break;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.EquipmentLoadAccordingToProductionScheduleModel);
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function LoadingByModelAndIntervalFormat(ReferenceOrder) Export
	
	Return GetLoadingByModelAndIntervalFormat(ReferenceOrder);
	
EndFunction

Function GetLoadingByModelAndIntervalFormat(ReferenceOrder)
	
	QueryText =
	"SELECT
	|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
	|	CreatingScheduleForWorkCenterTypes.IntervalDate,
	|	SUM(CreatingScheduleForWorkCenterTypes.Busy) AS Load
	|INTO TTLoad
	|FROM
	|	InformationRegister.CreatingScheduleForWorkCenterTypes AS CreatingScheduleForWorkCenterTypes
	|WHERE
	|	CreatingScheduleForWorkCenterTypes.ReferenceOrder = &ReferenceOrder
	|	AND CreatingScheduleForWorkCenterTypes.ScheduleStatus = &ScheduleStatus
	|
	|GROUP BY
	|	CreatingScheduleForWorkCenterTypes.WorkCenterType,
	|	CreatingScheduleForWorkCenterTypes.IntervalDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Enabled.WorkCenterType AS WorkCenterType,
	|	Enabled.IntervalDate AS IntervalDate,
	|	SUM(CASE
	|			WHEN Enabled.WorkCenterType.EnterAvailabilityForWorkCenterType
	|				THEN Enabled.WorkCenterTypeSchedule
	|			ELSE Enabled.WorkCenterSchedule
	|		END) AS Available
	|INTO TTAvailability
	|FROM
	|	AccumulationRegister.AvailabilityOfWorkCenterTypes AS Enabled
	|WHERE
	|	Enabled.IsRecordOfWorkCentersCapacityChange
	|	AND Enabled.Active
	|	AND (Enabled.WorkCenterType, Enabled.IntervalDate) IN
	|			(SELECT
	|				TTLoad.WorkCenterType,
	|				TTLoad.IntervalDate
	|			FROM
	|				TTLoad)
	|
	|GROUP BY
	|	Enabled.WorkCenterType,
	|	Enabled.IntervalDate
	|
	|HAVING
	|	SUM(CASE
	|			WHEN Enabled.WorkCenterType.EnterAvailabilityForWorkCenterType
	|				THEN Enabled.WorkCenterTypeSchedule
	|			ELSE Enabled.WorkCenterSchedule
	|		END) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTLoad.WorkCenterType AS WorkCenterType,
	|	TTLoad.WorkCenterType.AvailabilityReserve AS AvailabilityReserveInterest,
	|	TTLoad.IntervalDate AS IntervalDate,
	|	BEGINOFPERIOD(TTLoad.IntervalDate, TENDAYS) AS Interval,
	|	ISNULL(TTAvailability.Available, 0) AS Available,
	|	TTLoad.Load AS Load,
	|	CASE
	|		WHEN TTLoad.Load > ISNULL(TTAvailability.Available, 0)
	|			THEN TTLoad.Load - ISNULL(TTAvailability.Available, 0)
	|		ELSE 0
	|	END AS Overload
	|FROM
	|	TTLoad AS TTLoad
	|		LEFT JOIN TTAvailability AS TTAvailability
	|		ON TTLoad.WorkCenterType = TTAvailability.WorkCenterType
	|			AND TTLoad.IntervalDate = TTAvailability.IntervalDate";
	
	Periodicity = FrequencyOfIntervals(ReferenceOrder);
	QueryText = StrReplace(QueryText, "TENDAYS", Periodicity.Unit);
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ScheduleStatus", StatusChartModel());
	
	Result = New Structure;
	Result.Insert("LoadingEquipment", Query.Execute().Unload());
	Result.Insert("IntervalFormat", Periodicity.Format);
		
	Return Result;
	
EndFunction

Function FrequencyOfIntervals(ReferenceOrder)
	
	Query = New Query(
	"SELECT
	|	MIN(ScheduleOfProductionStages2_2.Begin) AS Begin,
	|	MAX(ScheduleOfProductionStages2_2.Ending) AS Ending
	|FROM
	|	InformationRegister.ScheduleOfProductionStages2_2 AS ScheduleOfProductionStages2_2
	|WHERE
	|	ScheduleOfProductionStages2_2.ProductionOrder = &ReferenceOrder
	|	AND ScheduleOfProductionStages2_2.ScheduleStatus = &ScheduleStatus
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|			THEN 1
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN 2
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN 2
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN 3
	|		ELSE 4
	|	END AS IntervalCode,
	|	CASE
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|			THEN ""Hour""
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN ""Day""
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN ""Day""
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN ""Week""
	|		ELSE ""Month""
	|	END AS Interval,
	|	CASE
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.HOUR)
	|			THEN &FormatHour
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.DAY)
	|			THEN &FormatDay
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.Shift)
	|			THEN &FormatDay
	|		WHEN NestedQuery.PlanningInterval = VALUE(Enum.ProductionScheduleAccuracy.WEEK)
	|			THEN &WeekFormat
	|		ELSE &FormatMonth
	|	END AS Format
	|FROM
	|	(SELECT DISTINCT
	|		CreatingScheduleForWorkCenterTypes.WorkCenterType.Department.PlanningInterval AS PlanningInterval
	|	FROM
	|		InformationRegister.CreatingScheduleForWorkCenterTypes AS CreatingScheduleForWorkCenterTypes
	|	WHERE
	|		CreatingScheduleForWorkCenterTypes.ReferenceOrder = &ReferenceOrder
	|		AND CreatingScheduleForWorkCenterTypes.ScheduleStatus = &ScheduleStatus) AS NestedQuery");
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("ScheduleStatus", StatusChartModel());
	Query.SetParameter("FormatHour", "DF='dd.MM HH:mm'");
	Query.SetParameter("FormatDay", "DLF=D");
	Query.SetParameter("WeekFormat", "DLF=D");
	
	FormatMonth = "DF='MMMM yyyy'";
	Query.SetParameter("FormatMonth", FormatMonth);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Boundaries = ResultsArray[0].Select();
	SubdivisionIntervals = ResultsArray[1].Select();
	
	If Boundaries.Next() And ValueIsFilled(Boundaries.Begin) Then
		
		ScaleSettings = ProductionManagementClientServer.GanttChartScaleSettingsInAllDataMode(
			Boundaries.Begin, Boundaries.Ending, 9);
			
		Format = ScaleSettings.Format;
		If ScaleSettings.Unit = TimeScaleUnitType.Hour Then
			IntervalCode = 1;
			Interval = "HOUR";
		ElsIf ScaleSettings.Unit = TimeScaleUnitType.Day Then
			IntervalCode = 2;
			Interval = "DAY";
		ElsIf ScaleSettings.Unit = TimeScaleUnitType.Week Then
			IntervalCode = 3;
			Interval = "WEEK";
		ElsIf ScaleSettings.Unit = TimeScaleUnitType.Month Then
			IntervalCode = 4;
			Interval = "MONTH";
		Else
			IntervalCode = 5;
			If ScaleSettings.Unit = TimeScaleUnitType.Quarter Then
				Interval = "QUARTER";
			ElsIf ScaleSettings.Unit = TimeScaleUnitType.Year Then
				Interval = "YEAR";
			Else
				Interval = "MONTH";
			EndIf;
		EndIf;
		
		While SubdivisionIntervals.Next() Do
			If SubdivisionIntervals.IntervalCode > IntervalCode Then
				IntervalCode = SubdivisionIntervals.IntervalCode;
				Interval = SubdivisionIntervals.Interval;
				Format = SubdivisionIntervals.Format;
			EndIf;
		EndDo;
		
		Unit = Interval;
		
	Else
		
		Unit = "MONTH";
		Format = FormatMonth;
		
	EndIf;
	
	Result = New Structure("Unit, Format", Unit, Format);
	Return Result;
	
EndFunction

Function StatusChartModel()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusChartModel();
	
EndFunction

Function EquipmentLoadAsPercentage(ReferenceOrder)
	
	Data = GetLoadingByModelAndIntervalFormat(ReferenceOrder);
	
	Result = Data.LoadingEquipment;
	Result.Columns.Add("LoadingPercentages", New TypeDescription("Number", New NumberQualifiers(5)));
	
	For Each String In Result Do
		If ValueIsFilled(String.Available) Then
			String.LoadingPercentages = String.Load/String.Available*100;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf