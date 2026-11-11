////////////////////////////////////////////////////////////////////////////////
// General planning procedures and functions, the result of which is cached
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Calculates the start date of the period based on the specified date and frequency
//
// Parameters:
//  Date			 - Date							 - the date by which the period start date will be calculated
//  Periodicity	 - EnumRef.Periodicity	 - the value of the "Frequency" enumeration.
// 
// Returns:
//  Date - start date of the period
//
Function CalculateStartDateOfPeriod(Val Date, Val Periodicity) Export
	
	Return PlanningClientServer.CalculateStartDateOfPeriod(Date, Periodicity);
	
EndFunction

// Calculates the end date of the period based on the specified date and frequency
//
// Parameters:
//  Date			 - Date							 - the date by which the period end date will be calculated
//  Periodicity	 - EnumRef.Periodicity	 - the value of the "Frequency" enumeration.
// 
// Returns:
//  Date - end date of the period.
//
Function CalculatePeriodEndDate(Val Date, Val Periodicity) Export
	
	Return PlanningClientServer.CalculatePeriodEndDate(Date, Periodicity);
	
EndFunction

#EndRegion
