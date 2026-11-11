#Region Public

// Returns the name of the enumeration value Periodicity
//
// Parameters:
// 	Periodicity - EnumRef.Periodicity - the value of the frequency.
// 					- Undefined - if the periodicity value is not set.
//
// Returns:
// 	String - The name of the periodicity enumeration enumeration, an empty string if the periodicity value is not specified.
//
Function PeriodicityByString(Periodicity) Export
	
	Return FinancialReportingServerCall.PeriodicityByString(Periodicity);
	
EndFunction

#EndRegion

