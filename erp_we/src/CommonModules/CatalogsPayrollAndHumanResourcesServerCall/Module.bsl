#Region Internal

// Blocks data for editing in the Form
// 
// Parameters:
// 	IndividualRef - CatalogRef.Persons - Link to a reference list item
// 	PersonDataVersion - String - version of the object being blocked
// 	FormUUID - UUID - Unique identifier of the form
// 
// Returns:
// Boolean - returns the blocking flag
//
Function LockIndividualOnEditAtServer(IndividualRef, PersonDataVersion, FormUUID) Export
	Return CatalogsSalaryAndPersonnelServer.LockIndividualOnEditAtServer(IndividualRef, PersonDataVersion, FormUUID);
EndFunction

// Forms a structure with the values: Last name First name Patronymic
// 
// Parameters:
// 	LastFirstName - String - Last Name First Name Patronymic
// 
// Returns:
// Structure:
//		*LastName - String - LastName
//		*Name - String - Name
//		*MiddleName - String - MiddleName 
//
Function FullName(LastFirstName) Export
	
	Return PersonsTM.FullName(LastFirstName);
	
EndFunction	

// Generates a string containing the last name and initials of an individual.
// The string is formed depending on the type of parameter passed:
//	- either by the history of the full name of the element in the physical Object reference list,
// 	- or by parsing the string containing the full name.
//
// Parameters:
//  FullName - String, CatalogRef.Persons - source of information about full name
//
// Returns:
//  String - Surname and. O . 
//
Function InitialsAndLastName(Val FullName) Export

	Return PersonsTM.IndividualShortName(FullName);

EndFunction

Function SimilarIndividuals(SearchParameters) Export
	
	Return CatalogsSalaryAndPersonnelServer.SimilarIndividuals(SearchParameters);
	
EndFunction	

#EndRegion
