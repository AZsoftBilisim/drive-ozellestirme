///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Abbreviates a person's name.
//
// Parameters:
//  FullName - String - For example, "John Quentin Doe".
//            - Structure:
//                        * LastName  - String
//                        * Name      - String
//                        * MiddleName - String
//  FullNameFormat - String - "LastName, FirstName, MiddleName" (the default order) or "FirstName, MiddleName, LastName".
//  IsInitialsComeFirst    - Boolean - If set to "False" (the default value), returns "Doe J. Q."
//                                Otherwise, returns "J. Q. Doe".
//  Result - String - Last name and initials. For example, "Doe J. Q." 
//
Procedure OnDefineSurnameAndInitials(Val FullName, Val FullNameFormat, Val IsInitialsComeFirst, Result) Export
EndProcedure

// Splits a person's name into first name, middle name, and last name.
// If a name (usually, Central Asian) ends with "oğlu", " "qızı", "kizi", "uulu", or "kyzy",
// they are considered a part of the middle name.
//
// Parameters:
//  FullName - String - Full name in the format "LastName FirstName MiddleName".
//  NameFormat - String - Determines the order of name components.
//                         The default order is "LastName,FirstName,MiddleName".
//                         The alternative order is "FirstName,MiddleName,LastName".
//  Result - Structure:
//   * LastName  - String - Last name.
//   * Name      - String - First name.
//   * MiddleName - String - Middle name.
//
// Example:
//   "IndividualsClientServer.NameParts()" returns a structure with the following values: 
//    - If "John Doe" is passed,  returns "John", "Doe", "".
//    - If "Sidorova Anna Ivanovna" is passed, returns "Sidorova", "Anna", "Ivanovna". 
//    - If "Aliev Akhmed Oktai oglu" is passed, returns "Aliev", "Akhmed", "Oktai oglu".
//    
//   
//
Procedure OnDefineFullNameComponents(Val FullName, Val NameFormat, Result) Export
EndProcedure

// Validates a person's name.
//
// Parameters:
//  LastFirstName - String - Full name.
//  IsOnlyNationalScriptLetters - Boolean - Flag indicating that valid names should contain only national alphabet letters.
//  CheckResult - Boolean - Return value. If "True", the name is valid.
//
Procedure FullNameWrittenCorrectly(Val LastFirstName, Val IsOnlyNationalScriptLetters, CheckResult) Export
	
	
EndProcedure

#EndRegion

