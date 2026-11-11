///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function GetAPDEXTop(StartDate, EndDate, AggregationPeriod, Count) Export
	
	Query = New Query;
	
	IntervalsSettingsTable = IntervalsSettingsTable();
	
	IntervalsTable = IntervalsTableForSettings(IntervalsSettingsTable);
	
	QueryTextByIntervalsFields = QueryTextSubstringForIntervals(IntervalsTable, "Measurements", "RunTime", True);
	QueryTextByIntervalsGroups = QueryTextSubstringForIntervals(IntervalsTable, "Measurements", "RunTime", False);
	
	Query = New Query;	
	Query.Text = QueryText();
	Query.Text = StrReplace(Query.Text, "&IntervalsFields,", QueryTextByIntervalsFields); 
	Query.Text = StrReplace(Query.Text, "&IntervalsGroups,", QueryTextByIntervalsGroups); 
	Query.SetParameter("StartDate", (StartDate - Date(1,1,1)) * 1000);	
	Query.SetParameter("EndDate", (EndDate - Date(1,1,1)) * 1000);
	Query.SetParameter("AggregationPeriod", AggregationPeriod);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;
EndFunction

Function QueryText()
	Return "SELECT
	|	DATEADD(DATETIME(2015,1,1),SECOND, CAST((Measurements.MeasurementStartDate/1000)/&AggregationPeriod - 0.5 AS NUMBER(11,0)) * &AggregationPeriod - 63555667200) AS Period,
	|	CatKeyOperations.Description AS KOD,
	|	CatKeyOperations.Name AS KON,
	|	CatKeyOperations.NameHash AS KOHash,
	|	Measurements.CompletedWithError AS ExecutedWithError,
	|	&IntervalsFields,
	|   COUNT(1) AS MeasurementQuantity,
	|   AVG(Measurements.MeasurementWeight) AS AvgWeight,
	|   MAX(Measurements.MeasurementWeight) AS MaxWeight
	|FROM
	|	InformationRegister.TimeMeasurements AS Measurements
	|INNER JOIN
	|	Catalog.KeyOperations AS CatKeyOperations
	|ON
	|	Measurements.KeyOperation = CatKeyOperations.Ref
	|WHERE
	|	Measurements.MeasurementStartDate BETWEEN &StartDate AND &EndDate
	|GROUP BY                             
	|	DATEADD(DATETIME(2015,1,1),SECOND, CAST((Measurements.MeasurementStartDate/1000)/&AggregationPeriod - 0.5 AS NUMBER(11,0)) * &AggregationPeriod - 63555667200),
	|	&IntervalsGroups,
	|	CatKeyOperations.Name,
	|	CatKeyOperations.NameHash,
	|	CatKeyOperations.Description,
	|	Measurements.CompletedWithError
	|ORDER BY
	|	DATEADD(DATETIME(2015,1,1),SECOND, CAST((Measurements.MeasurementStartDate/1000)/&AggregationPeriod - 0.5 AS NUMBER(11,0)) * &AggregationPeriod - 63555667200)"
EndFunction

// Returns the default interval settings table.
//
// Returns:
//   ValueTable:
//    * LowerBound  - Number
//    * UpperBound - Number
//    * Step            - Number
//
Function IntervalsSettingsTable()
	
	IntervalsSettingsTable = New ValueTable;
	IntervalsSettingsTable.Columns.Add("LowerBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsSettingsTable.Columns.Add("UpperBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsSettingsTable.Columns.Add("Step", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	
	// If the step and lower boundary are both zero, it forms an infinite interval with no lower limit (X <= "UpperBound").
	// If the step and upper boundary are both zero, it forms an infinite interval with no upper limit (X > "UpperBound").
	
	// Less than 0.5 sec.
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 0;
	NewSettingsRow.UpperBound	 = 0.5;
	NewSettingsRow.Step				 = 0;
	
	// 0.5 to 5 s with a step of 0.25 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 0.5;
	NewSettingsRow.UpperBound	 = 5;
	NewSettingsRow.Step				 = 0.25;
	
	// 5 to 7 s with a step of 0.5 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 5;
	NewSettingsRow.UpperBound	 = 7;
	NewSettingsRow.Step				 = 0.5;
	
	// 7 to 12 s with a step of 1 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 7;
	NewSettingsRow.UpperBound	 = 12;
	NewSettingsRow.Step				 = 1;
	
	// 12 to 20 s with a step of 2 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 12;
	NewSettingsRow.UpperBound	 = 20;
	NewSettingsRow.Step				 = 2;
	
	// 20 to 30 s with a step of 5 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 20;
	NewSettingsRow.UpperBound	 = 30;
	NewSettingsRow.Step				 = 5;
	
	// 30 to 80 s with a step of 10 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 30;
	NewSettingsRow.UpperBound	 = 80;
	NewSettingsRow.Step				 = 10;
	
	// 80 to 120 s with a step of 20 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 80;
	NewSettingsRow.UpperBound	 = 120;
	NewSettingsRow.Step				 = 20;
	
	// 120 to 300 s with a step of 30 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 120;
	NewSettingsRow.UpperBound	 = 300;
	NewSettingsRow.Step				 = 30;
	
	// 300 to 600 s with a step of 60 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 300;
	NewSettingsRow.UpperBound	 = 600;
	NewSettingsRow.Step				 = 60;
	
	// 600 to 1800 s with a step of 300 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 600;
	NewSettingsRow.UpperBound	 = 1800;
	NewSettingsRow.Step				 = 300;
	
	// 1800 to 3600 s with a step of 600 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 1800;
	NewSettingsRow.UpperBound	 = 3600;
	NewSettingsRow.Step				 = 600;
	
	// 3600 to 7200 s with a step of 1800 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 3600;
	NewSettingsRow.UpperBound	 = 7200;
	NewSettingsRow.Step				 = 1800;
	
	// 7200 to 42300 s with a step of 3600 s
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 7200;
	NewSettingsRow.UpperBound	 = 43200;
	NewSettingsRow.Step				 = 3600;
	
	// More than 42300 sec.
	NewSettingsRow = IntervalsSettingsTable.Add();
	NewSettingsRow.LowerBound	 = 43200;
	NewSettingsRow.UpperBound	 = 0;
	NewSettingsRow.Step				 = 0;
	
	Return IntervalsSettingsTable;
	
EndFunction

// Generates and returns a table of intervals from the interval settings table
//
// Parameters:
//  SettingsTable  - ValueTable - interval settings table.
//                 Must contain the following Number columns: LowerBound, UpperBound, Step.
//
// Returns:
//   ValueTable - with lower and upper bounds for each of the intervals.
//					   Columns: LowerBound, UpperBound.
//
Function IntervalsTableForSettings(SettingsTable)
	
	IntervalsTable = New ValueTable;
	IntervalsTable.Columns.Add("LowerBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	IntervalsTable.Columns.Add("UpperBound", New TypeDescription("Number",,, New NumberQualifiers(10, 3, AllowedSign.Nonnegative)));
	
	// Limits the number of intervals. Intervals that exceed the limit are excluded from the table.
	// The limitation prevents infinite growth of intervals as they are used to dynamically generate columns.
	// 
	// 
	MaxIntervalsCount = 80;
	TotalIntervals = 0;
		
	For Each SettingsString In SettingsTable Do
		
		// Validate the interval. If the step isn't zero, the upper
		// boundary must be greater than the lower one.
		If SettingsString.LowerBound >= SettingsString.UpperBound And SettingsString.Step <> 0
			Or SettingsString.LowerBound = SettingsString.UpperBound Then
			Continue;		
		EndIf; 
	
		If SettingsString.LowerBound = 0 And SettingsString.Step = 0 Then
			NewIntervalRow = IntervalsTable.Add();	
			NewIntervalRow.LowerBound	 = 0;
			NewIntervalRow.UpperBound	 = SettingsString.UpperBound;			
			TotalIntervals = TotalIntervals + 1;
		ElsIf SettingsString.UpperBound = 0 And SettingsString.Step = 0 Then
			NewIntervalRow = IntervalsTable.Add();	
			NewIntervalRow.LowerBound	 = SettingsString.LowerBound;
			NewIntervalRow.UpperBound	 = 0;                           			
			TotalIntervals = TotalIntervals + 1;
		Else
			CurrentValue = SettingsString.LowerBound;
			While CurrentValue < SettingsString.UpperBound Do
				// Too many columns.
				If TotalIntervals >= MaxIntervalsCount Then
					Break;
				EndIf;
				UpperValue = CurrentValue + SettingsString.Step;
				If UpperValue > SettingsString.UpperBound Then
					// Invalid interval settings. The current interval's upper boundary exceeds the upper boundary of the settings.
					Break;
				EndIf; 								
				NewIntervalRow = IntervalsTable.Add();	
				NewIntervalRow.LowerBound	 = CurrentValue;				
				NewIntervalRow.UpperBound	 = UpperValue;	
				CurrentValue = UpperValue;
				TotalIntervals = TotalIntervals + 1;
				
			EndDo; 		
		EndIf; 
	
	EndDo; 
	
	Return IntervalsTable;
	
EndFunction

// Generates and returns partial text of an interval table query
//
// Parameters:
//  IntervalsTable  - ValueTable - list of intervals.
//                 Must contain the following columns: LowerBound, UpperBound.
//
// Returns:
//   String
//
Function QueryTextSubstringForIntervals(IntervalsTable, SourceTableName, SourceColumnName, WithName)
	
	QueryText = "";	
	StringPattern = "	WHEN %1 %2 THEN %3";
	
	For Each IntervalString In IntervalsTable Do
		
		If IntervalString.LowerBound = 0 Then
			LowerBoundText = "";
			UpperBoundText = SourceTableName + "." + SourceColumnName + " <= " + Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=");
		ElsIf IntervalString.UpperBound = 0 Then
			LowerBoundText = SourceTableName + "." + SourceColumnName + " > " + Format(IntervalString.LowerBound,"NDS=.; NZ=0; NG=");
			UpperBoundText = "";
		Else
			LowerBoundText = SourceTableName + "." + SourceColumnName + " > " + Format(IntervalString.LowerBound,"NDS=.; NZ=0; NG=") + " And ";
			UpperBoundText = SourceTableName + "." + SourceColumnName + " <= " + Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=");
		EndIf;
		
		QueryTextForInterval = PerformanceMonitorClientServer.SubstituteParametersToString(StringPattern, LowerBoundText, UpperBoundText, Format(IntervalString.UpperBound,"NDS=.; NZ=0; NG=")); 		
		QueryText = QueryText + ?(IsBlankString(QueryText), "", Chars.LF) + QueryTextForInterval;
		
	EndDo;
	
	// ACC:1297-off - Queries are not localizable.
	QueryText = "CASE " + QueryText + ?(IsBlankString(QueryText), "", Chars.LF) + " Else 0 End" + ?(WithName, " AS ExecutionTime, ", ","); // @query-part-1
	// @query-part-1
// ACC:1297-on.
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
