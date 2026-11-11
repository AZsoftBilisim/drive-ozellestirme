#Region Public

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Constants.DoNotUsePayrollAndHumanResources.SetConstantOfNotUsingPayrollAndPersonnel";   
	Handler.Version = "2.5.26.62";
	Handler.ExecutionMode = "Exclusively";
	Handler.Id = New UUID("941b0689-a598-4ab1-bc32-398c00a11479");
	CommentTemplate = NStr("ru = 'Установка константы ""%1"". Заполняется значением обратным значению константы %2.';
							|vi = 'Setting the ""%1"" constant. Filled in with the value opposite to the value of the ""%2"" constant.';
							|en = 'Setting the ""%1"" constant. Filled in with the value opposite to the value of the ""%2"" constant.'; fa = 'Setting the ""%1"" constant. Filled in with the value opposite to the value of the ""%2"" constant.';
							|it = 'Setting the ""%1"" constant. Filled in with the value opposite to the value of the ""%2"" constant.';
							|pl = 'Setting the ""%1"" constant. Filled in with the value opposite to the value of the ""%2"" constant.';
							|tr = '“%1“ sabiti ayarlanıyor. Sabitin %2 ters değeriyle doldurulur'");
	Handler.Comment = StrTemplate(CommentTemplate, Metadata.Constants.DoNotUsePayrollAndHumanResources.Name, 
													Metadata.Constants.PayrollAndHumanResourcesWE.Name);
	ItemsToRead = New Array;
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Constants.DoNotUsePayrollAndHumanResources.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Constants.DoNotUsePayrollAndHumanResources.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Generates a brief Presentation of the array of individuals.
// It is used for Presentation of a brief composition of documents.
//
// Parameters:
//   Individuals - Array of CatalogRef.Persons - array of elements of the Reference Link type.Physical Beauty
//   UpdateDate - Date - the date for obtaining the surname, first name and patronymic
//   MaxStringLength - Number - optional, maximum length of the resulting string
//
// Returns:
//   String - short list of persons
Function ShortListOfIndividuals(Individuals, UpdateDate, MaxStringLength = 100) Export
	
	FullNameOfIndividuals = MatchingNamesOfIndividualsToLinks(UpdateDate, Individuals);
	
	ShortComposition = "";
	For Each Person In Individuals Do
		If Not IsBlankString(ShortComposition) Then
			ShortComposition = ShortComposition + ", ";
		EndIf;
		LastFirstName = FullNameOfIndividuals[Person];
		If Not LastFirstName = Undefined Then
			ShortComposition = ShortComposition + LastFirstName.LastNameIO;
		EndIf;
	EndDo;
	If StrLen(ShortComposition) > MaxStringLength Then
		ShortComposition = Left(ShortComposition, MaxStringLength - 3) + "...";
	EndIf;
	
	Return ShortComposition;

EndFunction

// Returns the correspondence with the full name of individuals as of the date.
//
// Parameters:
//	UpdateDate - Date - the date on which the full name is determined.
//	Persons - Array of CatalogRef.Persons
//
// Returns:
//	Map of KeyAndValue:
//	 * Key - CatalogRef.Persons
//	 * Value - String - LastFirstName
//
Function MatchingNamesOfIndividualsToLinks(UpdateDate, Persons) Export

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	Persons.Ref AS Ref,
	|	FullNameOfPersonsSliceLast.LastName AS LastName,
	|	FullNameOfPersonsSliceLast.Initials AS Initials,
	|	1 AS Priority
	|INTO AllFullNames
	|FROM
	|	InformationRegister.FullNameOfPersons.SliceLast(&Period, Individual IN (&Persons)) AS
	|		FullNameOfPersonsSliceLast
	|		LEFT JOIN Catalog.Persons AS Persons
	|		ON FullNameOfPersonsSliceLast.Individual = Persons.Ref
	|WHERE
	|	Persons.Ref IN (&Persons)
	|
	|UNION ALL
	|
	|SELECT
	|	Persons.Ref,
	|	Persons.LastName,
	|	Persons.Initials,
	|	2
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Ref IN (&Persons)
	|	AND NOT Persons.LastName = """"
	|
	|UNION ALL
	|
	|SELECT
	|	Persons.Ref,
	|	Persons.Description,
	|	"""",
	|	3
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.Ref IN (&Persons)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllFullNames.Ref AS Ref,
	|	MIN(AllFullNames.Priority) AS Priority
	|INTO Sorted
	|FROM
	|	AllFullNames AS AllFullNames
	|GROUP BY
	|	AllFullNames.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Sorted.Ref AS Ref,
	|	AllFullNames.LastName AS LastName,
	|	AllFullNames.Initials AS Initials
	|FROM
	|	AllFullNames AS AllFullNames
	|		INNER JOIN Sorted AS Sorted
	|		ON AllFullNames.Ref = Sorted.Ref
	|		AND AllFullNames.Priority = Sorted.Priority
	|";
	
	Query.Parameters.Insert("Persons", Persons);
	Query.Parameters.Insert("Period", UpdateDate);

	PersonsWithFullNames = New Map;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		LastFirstName = New Structure("LastName, Initials, LastNameIO");
		LastFirstName.LastName = Selection.LastName;
		LastFirstName.Initials = Selection.Initials;
		LastFirstName.LastNameIO = TrimAll(LastFirstName.LastName + " " + LastFirstName.Initials);
		If ValueIsFilled(LastFirstName.LastNameIO) Then
			PersonsWithFullNames.Insert(Selection.Ref, LastFirstName);
		EndIf;
	EndDo;

	Return PersonsWithFullNames;

EndFunction

#EndRegion