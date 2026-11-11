#Region Public

// Returns the name of the regulated accounting chart of accounts.
// Matches the name of the accounting register.
// 
// Returns:
// 	String - The name of the chart of accounts or an empty line.
//
Function ChartOfAccountsName() Export
	
	Name = "";
	Return Name;
	
EndFunction

// Returns the type of the regulated accounting chart of accounts.
// 
// Returns:
// 	Type - The type of the chart of accounts is regulated or Undefined.
//
Function TypeChartOfAccounts() Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

// Returns the type of regulated accounting subcontent types.
// 
// Returns:
// 	Type - The type of types of subconto regulated accounting or Indefinite.
//
Function TypeSpeciesExtdimension() Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

// Returns an empty reference to the regulated accounting chart of accounts.
// 
// Returns:
// 	ChartOfAccountsRef - A link to the chart of accounts of regulated accounting or an empty line.
//
Function ChartOfAccountsLink() Export
	
	Result = "";
	
	
	Return Result;
		
EndFunction

// Returns an empty value for the regulated accounting sub-account.
// 
// Returns:
// 	String - empty value of the regulated accounting sub-account or Undefined.
//
Function EmptyExtdimensionValue() Export
	
	Result = "";
	Return Result;
	
EndFunction

// Returns the start date of application of the FSB standard 5/2019 " Inventory"
// 
// Returns:
// 	Date - start date of application of the FSB standard 5/2019
Function BeginningOfApplicationFSBU5_2019() Export
	
	Return '20210101000000';
	
EndFunction

// Defines the period of application of accounting for exchange rate differences in accordance with 67-FZ
// 
// Returns:
//	Structure - keys Start,End - dates
//
Function PeriodOfAccountingForExchangeRateDifferencesWELLAccordingTo67FZ() Export
	
	Period = New Structure;
	Period.Insert("Begin", '20220101');
	Period.Insert("End", EndOfYear('20240101'));
	
	Return Period;
	
EndFunction

// Checking the date for entry into the period of application of accounting for exchange differences under 67-FZ
// 
// Parameters:
//	Period - Date - Date to be checked
//
// Returns:
//	Boolean - Description - True if the date is included in the period
//
Function DateIsIncludedInPeriodOfAccountingForExchangeDifferencesWELLAccordingTo67FZ(Period) Export
	
	PeriodOfApplication = PeriodOfAccountingForExchangeRateDifferencesWELLAccordingTo67FZ();
	
	EnteringPeriod = Period >= PeriodOfApplication.Begin And Period <= PeriodOfApplication.End;
	
	Return EnteringPeriod;
	
EndFunction

// Returns an empty value for the regulated accounting sub-account.
// 
// Returns:
// 	String - empty value of the regulated accounting sub-account or Undefined.
//
Function MainValueOfClarifyingInterReportingPeriod() Export
	
	Result = 5;
	Return Result;
	
EndFunction

#EndRegion