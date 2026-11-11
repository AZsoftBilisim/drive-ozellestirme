////////////////////////////////////////////////////////////////////////////////
// Production planning procedures and functions
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Converts time from the specified time units to seconds
//
// Parameters:
//  Time					 - Number								 - Time
//  TimeUnitOfMeasure	 - EnumRef.TimeMeasureUnits	 - the unit of time.
// 
// Returns:
//   - Number - time in seconds
//
Function GetTimeInSeconds(Time, TimeUnitOfMeasure) Export
	
	If Time = 0 Then
		
		Return 0;
		
	EndIf;
	
	If TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") 
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day") Then
		
		TimeInSeconds = Time * 86400; // 60 * 60 * 24
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute") Then
		
		TimeInSeconds = Time * 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Hour") Then
		
		TimeInSeconds = Time * 3600; //60 * 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Second") Then
		
		TimeInSeconds = Time;
		
	Else
		
		TimeInSeconds = 0;
		
	EndIf;

	Return TimeInSeconds;
	
EndFunction

// Converts time in seconds to time in the specified time units
//
// Parameters:
//  TimeInSeconds			 - Number								 - time in seconds
//  TimeUnitOfMeasure	 - EnumRef.TimeMeasureUnits	 - the unit of time.
// 
// Returns:
//   - Number - time in a unit of measurement.
//
Function GetTimeInUnit(TimeInSeconds, TimeUnitOfMeasure) Export
	
	If TimeInSeconds = 0 Then
		
		Return 0;
		
	EndIf;
	
	If TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1")
		Or TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day") Then
		
		Time = TimeInSeconds / 86400; // 60 / 60 / 24;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute") Then
		
		Time = TimeInSeconds / 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Hour") Then
		
		Time = TimeInSeconds / 3600; // 60 / 60;
		
	ElsIf TimeUnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Second") Then
		
		Time = TimeInSeconds;
		
	Else
		
		Time = 0;
		
	EndIf;

	Return  Time;
	
EndFunction

// Forms a time representation as a string
//
// Parameters:
//  Time                   - Number - Time
//	TimeUnitOfMeasure - EnumRef.TimeMeasureUnits - if the parameter is set, 
//								the time is output in the unit measurement format, otherwise the format "HH:mm:SS"is used.
//
// Returns:
//   String   - Time by line
//
Function GetTimeByString(Val Time, TimeUnitOfMeasure = Undefined) Export

	Result = "";
	
	If TimeUnitOfMeasure = Undefined Then
		
		If Time < 0 Then
			
			Time = -Time;
			Result = "-"
			
		EndIf;
		
		If Time >= 3600 Then
			
			Result = Result + Format(Int(Time / 3600), "NG=0") + ":";
			
		EndIf;
		
		If Time > 0 Then
			
			Result = Result + Format(Int(Time % 3600 / 60), "ND=2; NZ=; NLZ=; NG=0") + ":" + Format(Time % 60, "ND=2; NZ=; NLZ=; NG=0");
			
		EndIf;
		
	Else
		
		Result = Format(Time, "NGS=; NZ=; NG=") + " " + String(TimeUnitOfMeasure);
		
	EndIf;
		
	Return Result;

EndFunction

// The function returns a date aligned with the beginning of the planning interval
//
// Parameters:
//  Period				 - Date - the original date 
//  PlanningInterval - EnumRef.ProductionScheduleAccuracy - the planning interval
//  StartOfRange		 - Date - start of the planning interval
// Returns:
//  Date - the date aligned with the boundary of the planning interval.
Function PlanningIntervalStart(Period, PlanningInterval, StartOfRange = '00010101') Export
	
	Return AlignPeriodToPlanningIntervalBoundary(Period, PlanningInterval, StartOfRange);
	
EndFunction

// The function returns a date aligned with the end of the planning interval
//
// Parameters:
//  Period				 - Date - the original date
//  PlanningInterval - EnumRef.ProductionScheduleAccuracy - the planning interval
//  EndOfTheInterval	 - Date - end of the planning interval
// Returns:
//  Date - the date aligned with the boundary of the planning interval.
Function PlanningIntervalEnd(Period, PlanningInterval, EndOfTheInterval = '00010101') Export
	
	If EndOfTheInterval = '00010101' Then
		
		Result = Period;
		
		If PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour") Then
			
			Result = EndOfHour(Result);
			
		ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day")
			Or PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift") Then
			
			Result = EndOfDay(Result);
			
		ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Week") Then
			
			Result = EndOfWeek(Result);
			
		ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Month") Then
			
			Result = EndOfMonth(Result);
			
		EndIf;
		
		Return Result;
		
	Else
		
		Return AlignPeriodToPlanningIntervalBoundary(Period, PlanningInterval, EndOfTheInterval);
		
	EndIf;
	
EndFunction

// The function returns the next planning interval received from the passed period.
//
// Parameters:
//  Period						 - Date - the original date
//  PlanningInterval		 - EnumRef.ProductionScheduleAccuracy - the planning interval
//  PlanningIntervalStart	 - Date - start of the planning interval
//  AlignToBorder			 - Boolean - determines whether the period should be aligned with the planning interval boundary
//                                           . used when placing and defining
//                                           the current interval. not used when calculating the boundaries of the BBB stages at the moment
// Returns:
//  Date - the start date of the next planning interval.
Function NextSchedulingInterval(Period, PlanningInterval, Val PlanningIntervalStart = '00010101', Val AlignToBorder = False) Export
	
	Result = PlanningIntervalStart(Period, PlanningInterval, PlanningIntervalStart);
	
	If Result >= Period Then
		
		Return ?(AlignToBorder, Result, PlanningIntervalStart(Period, PlanningInterval)); 
		
	ElsIf AlignToBorder Then
		
		Return PlanningIntervalStart(PlanningIntervalEnd(Period, PlanningInterval) + 1, PlanningInterval, PlanningIntervalStart);
		
	Else
		
		Return PlanningIntervalStart(PlanningIntervalEnd(Period, PlanningInterval) + 1, PlanningInterval);
		
	EndIf;
	
EndFunction

// The function returns the previous planning interval received from the passed period.
//
// Parameters:
//  Period							 - Date - the original date
//  PlanningInterval			 - EnumRef.ProductionScheduleAccuracy - the planning interval
//  PlanningIntervalEnd	 - Date - end of the planning interval
//  AlignToBorder			     - Boolean - determines whether the period should be aligned with the planning interval boundary
//                                               . used when placing and defining
//                                               the current interval. not used when calculating the boundaries of the BBB stages at the moment
// Returns:
//  Date - the end date of the previous planning interval.
Function PreviousSchedulingInterval(Period, PlanningInterval, Val PlanningIntervalEnd = '00010101', Val AlignToBorder = False) Export
	
	Result = PlanningIntervalEnd(Period, PlanningInterval, PlanningIntervalEnd);
	
	If Result <= Period Then
		
		Return ?(AlignToBorder, Result, PlanningIntervalEnd(Period, PlanningInterval)); 
		
	ElsIf AlignToBorder Then
		
		Return PlanningIntervalEnd(PlanningIntervalStart(Period, PlanningInterval) - 1, PlanningInterval, PlanningIntervalEnd);
		
	Else
		
		Return PlanningIntervalEnd(PlanningIntervalStart(Period, PlanningInterval) - 1, PlanningInterval);
		
	EndIf;
	
EndFunction

// The function returns the standard interval duration in a unit of measurement
//
// Parameters:
//  Interval - EnumRef.ProductionScheduleAccuracy - the planning interval
//  UnitOfMeasure - EnumRef.TimeMeasureUnits - The unit of measurement that
//                                                                  the standard interval duration should be reduced to
//                                                                  The default value is "Day".
// 
// Returns:
//   - Number - The standard duration of the interval (in a unit of measurement).
//
Function GetNormativeIntervalDuration(Val Interval, Val UnitOfMeasure = Undefined) Export
	
	If UnitOfMeasure = Undefined
		Or UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Day")
		Or UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Days1") Then
		
		If Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day")
			Or Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift") Then
			Return 1;
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour") Then
			Return 1/24;
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Week") Then
			Return 7;
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Month") Then
			Return 30;
		Else
			Return 0;
		EndIf;
		
	Else
		
		If Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day")
			Or Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift") Then
			Return GetTimeInUnit(86400, UnitOfMeasure);
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour") Then
			Return GetTimeInUnit(3600, UnitOfMeasure);
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Week") Then
			Return GetTimeInUnit(86400*7, UnitOfMeasure);
		ElsIf Interval = PredefinedValue("Enum.ProductionScheduleAccuracy.Month") Then
			Return GetTimeInUnit(86400*30, UnitOfMeasure);
		Else
			Return 0;
		EndIf;
		
	EndIf;
	
EndFunction


#EndRegion

#Region Private


#Region Other

Function AlignPeriodToPlanningIntervalBoundary(Period, PlanningInterval, Boundary)
	
	Result = Period;
	
	If PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour") Then
		
		Result = BegOfHour(Result) + (Boundary - '00010101');
		
	ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day")
		Or PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift") Then
		
		Result = BegOfDay(Result) + (Boundary - '00010101');
		
	ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Week") Then
		
		Result = BegOfWeek(Result) + (Boundary - '00010101');
		
	ElsIf PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Month") Then
		
		If EndOfMonth(Result) > Boundary Then
		
			Result = BegOfMonth(Result) + (Boundary - '00010101');
			
		Else
			
			Result = EndOfMonth(Result) - (86400 - (Boundary - '00010101') % 86400) + 1;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ParametersForRecalculatingNumberOfUnits(CurrentRow, TabularSectionName) Export

	If TabularSectionName = "MaterialsAndServices" And Not CurrentRow.OrderToWarehouse Then
		RecalculationParameters = New Structure("MustBeRoundOff", False);
		Return RecalculationParameters;
	ElsIf (TabularSectionName = "ManufacturedProducts" Or TabularSectionName = "RecyclableWaste") 
		And Not ValueIsFilled(CurrentRow.Warehouse) Then
		RecalculationParameters = New Structure("MustBeRoundOff", False);
		Return RecalculationParameters;
	EndIf;

	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
