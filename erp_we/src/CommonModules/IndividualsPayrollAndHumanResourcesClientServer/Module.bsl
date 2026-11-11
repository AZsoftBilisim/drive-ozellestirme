 #Region Internal

// Forms the initials of the person's name and patronymic.
//
// Parameters:
//  Name			- String - Name
//  MiddleName	- String - MiddleName
//
// Returns:
//  String - the initial of the name, patronymic.
//
Function InitialsByFirstNamePatronymic(Val Name, Val MiddleName) Export
	
	If Not IsBlankString(Name) Then
		
		Names = ComponentsOfName(Name);
		If Names.Count() > 1 Then
			
			Initials = Left(Names[0], 1) + ".-"
				+ Left(Names[1], 1) + ".";
			
		Else
			Initials = Left(Name, 1) + ".";
		EndIf;
		
		If Not IsBlankString(MiddleName) Then
			Initials = Initials + " " + Left(MiddleName, 1) + ".";
		EndIf;
		
		Return Initials;
		
	EndIf;
	
	Return "";
	
EndFunction

// Generates a string with the full name from the constituent parts.
//
// Parameters:
//   NameParts - Structure - contains the fields Surname, First Name and, optionally, Patronymic
//
// Returns:
//   String - full name in the format "Surname First Name Patronymic" or "Surname First Name"
Function FullNameFromParts(NameParts) Export
	If ValueIsFilled(NameParts.MiddleName) Then
		Return TrimAll(StrConcat(
		    GenerateValuesInArray(
		        TrimAll(NameParts.LastName),
		        TrimAll(NameParts.Name),
		        TrimAll(NameParts.MiddleName)), " "));
	EndIf;
	Return TrimAll(StrConcat(
	       GenerateValuesInArray(
	           TrimAll(NameParts.LastName),
	           TrimAll(NameParts.Name))," "));
EndFunction

// Generates a brief representation of the full name of the individual.
//
// Parameters:
//  FullName - String - full name in the form of "Surname First name Patronymic";
//                     - Structure - parts of the full name:
//                        * LastName  - String - Last name;
//                        * Name      - String - Name;
//                        * MiddleName - String - patronymic.
//                        * Initials - String
//
// Returns:
//  String - last name and initials
//
// Example:
//
Function InitialsAndLastName(Val FullName) Export
	
	If TypeOf(FullName) = Type("Structure")
		Or TypeOf(FullName) = Type("FixedStructure") Then
		
		If Not IsBlankString(FullName.LastName) Then
			
			Initials = Undefined;
			FullName.Property("Initials", Initials);
			If Not ValueIsFilled(Initials) Then
				Initials = InitialsByFirstNamePatronymic(FullName.Name, FullName.MiddleName);
			EndIf;
			
			If IsBlankString(Initials) Then
				Return FullName.LastName;
			EndIf;
			
			Return FullName.LastName + " " + Initials;
			
		EndIf;
		
	EndIf;
	
	Return CatalogsPayrollAndHumanResourcesServerCall.InitialsAndLastName(FullName);
	
EndFunction


#EndRegion


#Region Private

// Forms a small array of 2 to 5 elements in size by their values.
// To create an array from a single element See CommonClientServer.ValueInArray. 
// 
// Parameters:
// 	Element<n> - array elements. 
// 
// Returns:
// 	Array of String
//
Function GenerateValuesInArray(Item1, Item2, Item3="") Export

	SmallArray = New Array;
	SmallArray.Add(Item1);
	SmallArray.Add(Item2);
	SmallArray.Add(Item3);

	Return SmallArray;

EndFunction

Function ComponentsOfName(Val Name)
	
	Names = New Array;
	
	If Not IsBlankString(Name) Then
		
		NameSeparator = "-";
		SeparatorPosition = StrFind(Name, NameSeparator);
		If SeparatorPosition = 0 Then
			NameSeparator = " ";
			SeparatorPosition = StrFind(Name, NameSeparator);
		EndIf;
		
		Names = StrSplit(Name, NameSeparator, False);
		
	EndIf;
	
	Return Names;
	
EndFunction

#EndRegion
