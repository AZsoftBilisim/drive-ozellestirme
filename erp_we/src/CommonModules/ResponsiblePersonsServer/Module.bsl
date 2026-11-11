
#Region Public

// Returns a structure containing information about the organization's responsible person.
//
// Parameters:
//	Organization - CatalogRef.Companies - selection of the organization
//	Date - Date - selection by date
//  EmployeeInCharge_ - EnumRef.PersonsResponsibleAndCompanies - "type" of the responsible person.
//
// Returns:
// 	Structure - Contains keys:
//		* StructuralUnit - CatalogRef.BusinessStructure - 
//		* EmployeeInCharge_ - EnumRef.PersonsResponsibleAndCompanies - 
//		* Individual - CatalogRef.Persons -
//		* JobTitle - String, CatalogRef -
//
Function GetDataOfResponsiblePerson(Organization, Date = Undefined, EmployeeInCharge_ = Undefined) Export
	
	If Not ValueIsFilled(EmployeeInCharge_) Then
		EmployeeInCharge_ = Enums.PersonsResponsibleAndCompanies.Director;
	EndIf;
	
	StructureOfResponsiblePersons = GetResponsiblePersonsOfOrganization(Organization, Date);
	Result 			   = New Structure("StructuralUnit, EmployeeInCharge_", Organization, EmployeeInCharge_);
	
	For Each MetaViewResponsible In Metadata.Enums.PersonsResponsibleAndCompanies.EnumValues Do
		
		Var_Key = MetaViewResponsible.Name;
		If EmployeeInCharge_ = Enums.PersonsResponsibleAndCompanies[Var_Key] Then
			Result.Insert("Individual", StructureOfResponsiblePersons[Var_Key]);
			Result.Insert("JobTitle", 	 StructureOfResponsiblePersons[Var_Key + "JobTitle"]);
			Break;
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a structure containing information about the organization's responsible persons.
//
// Parameters:
//	Organization - CatalogRef.Companies - selection of the organization
//	Date - Date - selection by date.
//
// Returns:
// Structure - Contains keys of the form:
//		%Type of responsible% - Reference link.Physical person - a natural person corresponding to the responsible person
//		%Type of responsible%Position - Line - position of the responsible person
//
// In the keys, instead of %type of responsible%, the name of the value of the enumeration of responsible organizations is substituted as it is specified in the configurator.
// The number of each of these keys corresponds to the number of enumeration values of the responsible organizations.
//
Function GetResponsiblePersonsOfOrganization(Organization, Date = Undefined) Export
	
	If Date = Undefined Then
		Date = CurrentSessionDate();
	EndIf;
	
	StructureOfResponsiblePersons = New Structure;
	
	FilterStructure1 	 = New Structure("Date, Owner", Date, Organization);
	TableOfResponsiblePersons = GetTableOfResponsiblePersonsForSelection(FilterStructure1);
	TableOfResponsiblePersons.Indexes.Add("EmployeeInCharge_, SignatureRight");
	
	For Each MetaViewResponsible In Metadata.Enums.PersonsResponsibleAndCompanies.EnumValues Do
		
		Var_Key 			  = MetaViewResponsible.Name;
		TypeOfResponsiblePerson = Enums.PersonsResponsibleAndCompanies[Var_Key];
		TableRow 	  = Undefined; // the person responsible has not yet been determined
		
		// We will try to find a suitable responsible person
		FilterStructure1 = New Structure("EmployeeInCharge_", TypeOfResponsiblePerson);
		TableRows = TableOfResponsiblePersons.FindRows(FilterStructure1);
		
		If TableRows.Count() = 1 Then
			
			// If there is only one responsible person of this type, we will return it
			TableRow = TableRows[0];
			
		ElsIf TableRows.Count() > 1 Then
			
			FilterStructure1.Insert("SignatureRight", False);
			
			TableRows = TableOfResponsiblePersons.FindRows(FilterStructure1);
			If TableRows.Count() = 1 Then
				// If there is a main responsible person of this type, we will return it
				TableRow = TableRows[0];
			EndIf;
			
		EndIf;
		
		If TableRow = Undefined Then
			
			// The responsible person of this type could not be identified
			StructureOfResponsiblePersons.Insert(Var_Key, 				         Catalogs.Persons.EmptyRef());
			StructureOfResponsiblePersons.Insert(Var_Key + "JobTitle",          "");
			StructureOfResponsiblePersons.Insert(Var_Key + "JobTitleRef",    Undefined);
			StructureOfResponsiblePersons.Insert(Var_Key + "Description",       "");
			StructureOfResponsiblePersons.Insert(Var_Key + "Ref", 	         Catalogs.PersonsResponsibleAndCompanies.EmptyRef());
		Else
			
			// The main responsible person of this type has been found
			StructureOfResponsiblePersons.Insert(Var_Key, 				         TableRow.Individual);
			StructureOfResponsiblePersons.Insert(Var_Key + "JobTitle",          TableRow.JobTitle);
			StructureOfResponsiblePersons.Insert(Var_Key + "JobTitleRef",    TableRow.JobTitleRef);
			StructureOfResponsiblePersons.Insert(Var_Key + "Description",       TableRow.Description);
			StructureOfResponsiblePersons.Insert(Var_Key + "Ref", 	         TableRow.Ref);
			
		EndIf;
		
	EndDo;
	
	Return StructureOfResponsiblePersons;
	
EndFunction

// Returns a table of responsible persons formed according to a random selection.
//
// Parameters:
//  Filter - Structure of KeyAndValue - structure containing data selection parameters of the Catalog of Responsible Organizations:
//		* Key - String - name of the reference list's details
//		* Value - Arbitrary - the value for selection as the key
//	AllowedMarkedForDeletion - Boolean - output items marked for deletion to the result table.
//	SearchString - String - Search string. Optional.
//	
// Returns:
//	ValueTable - contains columns:
//		* Ref - CatalogRef.PersonsResponsibleAndCompanies - 
//		* Owner - CatalogRef.Companies - 
//		* EmployeeInCharge_ - EnumRef.PersonsResponsibleAndCompanies -
//		* Individual - CatalogRef.Persons - 
//		* JobTitle - String -
//		* SignatureRight - Boolean - 
//		* SignatureRightBasis - String -
//		* StartDate - Date -
//		* EndDate - Date -
//		* SignatureRightDocument - String - 
//		* NumberOfSignatureRightDocument - String - 
//		* DateOfDocumentSignatureRight - Date -
//
Function GetTableOfResponsiblePersonsForSelection(Val Filter, AllowedMarkedForDeletion = False, SearchString = "") Export
	
	Query = New Query;
	
	TextSelectableFields = "";
	FilterText1 = "";
	SelectionNumber_ = 0;
	
	FilterFields = SettingsValueCached.CatalogAttributes("PersonsResponsibleAndCompanies");
	
	If Filter.Property("Date") Then
		
		// Selection by the period of validity of the record of the responsible person
		FilterText1 =
			FilterText1
			+ ?(FilterText1 = "", "", " And ") + "PersonsResponsibleAndCompanies.StartDate <= &SelectionByDate_1
			| AND (PersonsResponsibleAndCompanies.EndDate >= &SelectionByDate_1 
			|	 OR PersonsResponsibleAndCompanies.EndDate = DATETIME(1,1,1,0,0,0))
			|";
		Query.SetParameter("SelectionByDate_1", BegOfDay(Filter.Date));
		
		Filter.Delete("Date");
		
	EndIf;
	
	If Filter.Property("Organization") Then
		Filter.Insert("Owner", Filter.Organization);
		Filter.Delete("Organization");
	EndIf;
	
	If Not AllowedMarkedForDeletion Then
		Filter.Insert("DeletionMark", False);
	EndIf;
	
	// We form the "WHERE" section of the request, set the request parameters
	For Each CurrentFilter In Filter Do
		
		If Not FilterFields.Property(CurrentFilter.Key) Then
			Continue;
		EndIf;
		
		SelectionNumber_ = SelectionNumber_ + 1;
		
		FilterText1 =
			FilterText1
			+ ?(FilterText1 = "", "", " And ") + "PersonsResponsibleAndCompanies." + CurrentFilter.Key 
				+ ?(TypeOf(CurrentFilter.Value) = Type("Array") Or TypeOf(CurrentFilter.Value) = Type("FixedArray"), " In ", " = ")
				+ "(&FilterValue" + TrimAll(SelectionNumber_) + ")
			|";
		
		Query.SetParameter("FilterValue" + TrimAll(SelectionNumber_), CurrentFilter.Value);
		
	EndDo;
	
	If ValueIsFilled(SearchString) Then
		
		FilterText1 =
			FilterText1
			+ ?(FilterText1 = "", "", " And ") + "PersonsResponsibleAndCompanies.Description LIKE &SelectionByPresentation
			|";
		Query.SetParameter("SelectionByPresentation", SearchString + "%");
		
	EndIf;
	
	If Not ValueIsFilled(FilterText1) Then
		FilterText1 = "TRUE";
	EndIf;
	
	For Each Field In FilterFields Do
		TextSelectableFields = TextSelectableFields
			+ ?(TextSelectableFields = "", "", ",") + "
			|PersonsResponsibleAndCompanies." + Field.Key + " AS " + Field.Key;
	EndDo;
	
	// We form a request, get the data
	QueryText =
	"SELECT ALLOWED
	|	&SelectedFields
	|FROM
	|	Catalog.PersonsResponsibleAndCompanies AS PersonsResponsibleAndCompanies
	|WHERE
	|	&Filter
	|
	|ORDER BY
	|	Owner,
	|	EmployeeInCharge_,
	|	SignatureRight,
	|	StartDate,
	|	EndDate,
	|	Individual";
	
	QueryText = StrReplace(QueryText, "&SelectedFields", TextSelectableFields);
	QueryText = StrReplace(QueryText, "&Filter", FilterText1);
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();
	
EndFunction

// Default settings for responsible persons.
// 
// Returns:
//  Structure - Default Parameters Of Responsible Persons:
// * CompanyAttributeName - String - 
// * DetailsResponsiblePersons - Undefined, Structure - In the structure:
//		* Key - String - name of the field in the request to get the value of the responsible person
//		* Value - EnumRef.PersonsResponsibleAndCompanies - "type" of the responsible person
// * TableNameResponsiblePersons - String - 
// * AliasesOfDataOfResponsiblePersons - String, Undefined - 
Function DefaultParametersOfResponsiblePersons() Export
	
	Structure = New Structure;
	Structure.Insert("CompanyAttributeName", "Organization");
	Structure.Insert("DetailsResponsiblePersons", Undefined);
	Structure.Insert("TableNameResponsiblePersons", "TableResponsiblePersons");
	Structure.Insert("AliasesOfDataOfResponsiblePersons", Undefined);
	
	Return Structure;
	
EndFunction

// Creates a temporary table containing information about responsible persons in the context of documents.
// Used for forming printed forms of documents by the printing subsystem
//	- call this procedure before selecting data from the document header
//	- when selecting data, create a left connection of the document table with the temporary table of the table responsible For the Link field.
//
// Parameters:
//	FilterDocuments - Array of DocumentRef - links to documents for which you need to get responsible persons.
//		Important: if an array is passed, all its elements must have the same type.
//	TempTablesManager - TempTablesManager - it is placed in a temporary table formed by Tablecategories
//	ParametersOfResponsiblePersons- Undefined, Structure - In the structure:
//		* CompanyAttributeName - String - Name of the document field to get the owner organization of the responsible person
//		* DetailsResponsiblePersons - Undefined, Structure - In the structure:
//			* Key - String - name of the field in the request to get the value of the responsible person
//			* Value - EnumRef.PersonsResponsibleAndCompanies - "type" of the responsible person
//		* TableNameResponsiblePersons - String - allows you to set a name for the temporary table being generated
//		* AliasesOfDataOfResponsiblePersons - Undefined - Match - contains data:
//			* Key - EnumRef.PersonsResponsibleAndCompanies
//			* Value - See ResponsiblePersonsServer.DataAliasesOfResponsiblePersonsByDefault
// The number of rows in the table "Table of responsiblity" corresponds to the number of elements in the selection documents.
//
// The structure of the temporary table "The table is responsible for the matrix"
//		Link - a link to a document from the Selection Documents
//		%
//		%
//		%
//		%
//		%
// For fields starting with %
// The number of each of these fields corresponds to the number of Attributes of the responsible persons of the document.
//
// For example, if there are two Attributes of responsible persons in the metadata of a document - a Manager and an Accountant,
// then the table of tables will have the following structure:
//	Link
//	Chief Executive Officer
//	Head of the Physics Department
//	Directornames
//	Supervisor's duty
//	The head of the basis of the right of the signature
//	Accountant
//	Bookkeeping Physics
//	Bookkeeping Naming
//	Bookkeeping duty
//	Bookkeepreferences
//
Procedure CreateTemporaryTableOfResponsiblePersonsOfDocuments(FilterDocuments, TempTablesManager, ParametersOfResponsiblePersons = Undefined) Export
	
	If ParametersOfResponsiblePersons = Undefined Then
		ParametersOfResponsiblePersons = DefaultParametersOfResponsiblePersons();
	EndIf;
	
	CompanyAttributeName = ParametersOfResponsiblePersons.CompanyAttributeName;
	DetailsResponsiblePersons = ParametersOfResponsiblePersons.DetailsResponsiblePersons;
	TableNameResponsiblePersons = ParametersOfResponsiblePersons.TableNameResponsiblePersons;
	AliasesOfDataOfResponsiblePersons = ParametersOfResponsiblePersons.AliasesOfDataOfResponsiblePersons;
	
	If (TypeOf(FilterDocuments) = Type("Array") Or TypeOf(FilterDocuments) = Type("FixedArray"))
	 And FilterDocuments.Count() = 0 Then
		Return;
	EndIf;
	
	If TypeOf(FilterDocuments) <> Type("Array") And TypeOf(FilterDocuments) <> Type("FixedArray") Then // this is a link to the document
		ObjectsArray = New Array;
		ObjectsArray.Add(FilterDocuments);
	Else // this is an array of links to documents
		ObjectsArray = FilterDocuments;
	EndIf;
	
	MetadataOfDocument = ObjectsArray[0].Metadata(); // MetadataObjectDocument - 
	
	FieldNamesPassedInParameters = (DetailsResponsiblePersons <> Undefined);
	If Not FieldNamesPassedInParameters Then
		DetailsResponsiblePersons = ResponsiblePersonsCached.DetailsOfResponsiblePersonsOfDocument(MetadataOfDocument.Name);
	EndIf;
	
	If Not ValueIsFilled(DetailsResponsiblePersons) Then
		Return;
	EndIf;
	
	CompanyAttributeName = "DocumentForPrint." + CompanyAttributeName;
	
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	// We will get the data from the documents
	QueryTemplate = 
	"SELECT
	|	DocumentForPrint.Ref AS Ref,
	|	BEGINOFPERIOD(DocumentForPrint.Date, DAY) AS Date,
	|	&Organization AS Organization,
	|	&SelectedResponsiblePerson AS SelectedResponsiblePerson,
	|	&EmployeeInCharge_ AS EmployeeInCharge_
	|INTO TTDocumentData
	|FROM
	|	&TableDocument AS DocumentForPrint
	|WHERE
	|	DocumentForPrint.Ref IN(&ObjectsArray)";
	
	If MetadataOfDocument.Attributes.Find("CorrectedDocument") <> Undefined Then
		QueryTemplate = StrReplace(QueryTemplate,
			"DocumentForPrint.Date",
			"ISNULL(DocumentForPrint.CorrectedDocument.Date, DocumentForPrint.Date)");
	EndIf;
	
	QueryTemplate = StrReplace(QueryTemplate, "&TableDocument", "Document." + MetadataOfDocument.Name);
		
	IndexOf = 0;
	For Each KeyAndValue In DetailsResponsiblePersons Do
		
		IndexOf 		 = IndexOf + 1;
		QueryText = QueryTemplate;
		
		If IndexOf > 1 Then
			QueryText = "
			|UNION ALL
			|" + QueryText;
		EndIf;
		
		QueryText = StrReplace(QueryText , "&Organization", CompanyAttributeName);
		QueryText = StrReplace(QueryText , "&SelectedResponsiblePerson", "DocumentForPrint." + KeyAndValue.Key);
		
		TextResponsiblePerson_ = StrTemplate("VALUE(%1)", GetPredefinedValueFullName(KeyAndValue.Value));
		QueryText = StrReplace(QueryText , "&EmployeeInCharge_", TextResponsiblePerson_);
		
		If IndexOf <> 1 Then
			QueryText = StrReplace(QueryText , "INTO TTDocumentData", "");
		EndIf;
		
		Query.Text = Query.Text + QueryText;
		
	EndDo;
	
	Query.Text = Query.Text + "
	|
	|INDEX BY
	|	Organization,
	|	EmployeeInCharge_,
	|	DATE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	// Fill in the empty fields of responsible persons with default values
	Query.Text = Query.Text +
	"SELECT DISTINCT
	|	TTDocumentData.Organization AS Organization,
	|	TTDocumentData.EmployeeInCharge_ AS EmployeeInCharge_,
	|	TTDocumentData.Date AS Date
	|INTO TTUnfilledResponsible
	|FROM
	|	TTDocumentData AS TTDocumentData
	|WHERE
	|	TTDocumentData.SelectedResponsiblePerson = VALUE(Catalog.PersonsResponsibleAndCompanies.EmptyRef)
	|
	|INDEX BY
	|	Organization,
	|	EmployeeInCharge_,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTUnfilledResponsible.Organization AS Organization,
	|	TTUnfilledResponsible.EmployeeInCharge_ AS EmployeeInCharge_,
	|	TTUnfilledResponsible.Date AS Date,
	|	PersonsResponsibleAndCompanies.Ref AS EmployeeResponsible,
	|	PersonsResponsibleAndCompanies.SignatureRight AS SignatureRight
	|INTO TTCandidatesInChargeByDefault
	|FROM
	|	TTUnfilledResponsible AS TTUnfilledResponsible
	|		INNER JOIN Catalog.PersonsResponsibleAndCompanies AS PersonsResponsibleAndCompanies
	|		ON TTUnfilledResponsible.Organization = PersonsResponsibleAndCompanies.Owner
	|			AND TTUnfilledResponsible.EmployeeInCharge_ = PersonsResponsibleAndCompanies.EmployeeInCharge_
	|			AND TTUnfilledResponsible.Date >= PersonsResponsibleAndCompanies.StartDate
	|			AND (TTUnfilledResponsible.Date <= PersonsResponsibleAndCompanies.EndDate
	|				OR PersonsResponsibleAndCompanies.EndDate = DATETIME(1, 1, 1))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCandidatesInChargeByDefault.Organization,
	|	TTCandidatesInChargeByDefault.EmployeeInCharge_,
	|	TTCandidatesInChargeByDefault.Date,
	|	TTCandidatesInChargeByDefault.DefaultResponsiblePerson
	|INTO TTResponsibleByDefault
	|FROM
	|	(SELECT
	|		TTCandidatesInChargeByDefault.Organization AS Organization,
	|		TTCandidatesInChargeByDefault.EmployeeInCharge_ AS EmployeeInCharge_,
	|		TTCandidatesInChargeByDefault.Date AS Date,
	|		TTCandidatesInChargeByDefault.EmployeeResponsible AS DefaultResponsiblePerson
	|	FROM
	|		TTCandidatesInChargeByDefault AS TTCandidatesInChargeByDefault
	|	WHERE
	|		NOT TTCandidatesInChargeByDefault.SignatureRight
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTCandidatesInChargeByDefault.Organization,
	|		TTCandidatesInChargeByDefault.EmployeeInCharge_,
	|		TTCandidatesInChargeByDefault.Date,
	|		MIN(TTCandidatesInChargeByDefault.EmployeeResponsible)
	|	FROM
	|		TTCandidatesInChargeByDefault AS TTCandidatesInChargeByDefault
	|
	|	GROUP BY
	|		TTCandidatesInChargeByDefault.Organization,
	|		TTCandidatesInChargeByDefault.EmployeeInCharge_,
	|		TTCandidatesInChargeByDefault.Date
	|	
	|	HAVING
	|		COUNT(DISTINCT TTCandidatesInChargeByDefault.EmployeeResponsible) = 1
	|	) AS TTCandidatesInChargeByDefault
	|
	|INDEX BY
	|	Organization,
	|	EmployeeInCharge_,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentData.Ref,
	|	TTDocumentData.Date,
	|	TTDocumentData.EmployeeInCharge_,
	|	CASE
	|		WHEN TTDocumentData.SelectedResponsiblePerson = VALUE(Catalog.PersonsResponsibleAndCompanies.EmptyRef)
	|			THEN ISNULL(TTResponsibleByDefault.DefaultResponsiblePerson, VALUE(Catalog.PersonsResponsibleAndCompanies.EmptyRef))
	|		ELSE TTDocumentData.SelectedResponsiblePerson
	|	END AS DefaultResponsiblePerson
	|INTO TTDocumentsWithResponsiblePersons
	|FROM
	|	TTDocumentData AS TTDocumentData
	|		LEFT JOIN TTResponsibleByDefault AS TTResponsibleByDefault
	|		ON TTDocumentData.Organization = TTResponsibleByDefault.Organization
	|			AND TTDocumentData.EmployeeInCharge_ = TTResponsibleByDefault.EmployeeInCharge_
	|			AND TTDocumentData.Date = TTResponsibleByDefault.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual AS Individual,
	|	TTDocumentsWithResponsiblePersons.Ref,
	|	MAX(FullNameOfPersons.Period) AS Period
	|INTO TTPeriodsFullNameOfIndividuals
	|FROM
	|	TTDocumentsWithResponsiblePersons AS TTDocumentsWithResponsiblePersons
	|		LEFT JOIN InformationRegister.FullNameOfPersons AS FullNameOfPersons
	|		ON TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual = FullNameOfPersons.Individual
	|			AND TTDocumentsWithResponsiblePersons.Date >= FullNameOfPersons.Period
	|WHERE
	|	TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual <> VALUE(Catalog.Persons.EmptyRef)
	|	AND TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual IS NOT NULL 
	|	AND FullNameOfPersons.Period IS NOT NULL 
	|
	|GROUP BY
	|	TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual,
	|	TTDocumentsWithResponsiblePersons.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTPeriodsFullNameOfIndividuals.Individual,
	|	TTPeriodsFullNameOfIndividuals.Ref,
	|	CAST(FullNameOfPersons.LastName + CASE
	|			WHEN FullNameOfPersons.Name = """"
	|				THEN """"
	|			ELSE "" "" + SUBSTRING(FullNameOfPersons.Name, 1, 1) + "".""
	|		END + CASE
	|			WHEN FullNameOfPersons.MiddleName = """"
	|				THEN """"
	|			ELSE "" "" + SUBSTRING(FullNameOfPersons.MiddleName, 1, 1) + "".""
	|		END AS STRING(50)) AS LastFirstName
	|INTO TTIndividualNames
	|FROM
	|	TTPeriodsFullNameOfIndividuals AS TTPeriodsFullNameOfIndividuals
	|		LEFT JOIN InformationRegister.FullNameOfPersons AS FullNameOfPersons
	|		ON TTPeriodsFullNameOfIndividuals.Individual = FullNameOfPersons.Individual
	|			AND TTPeriodsFullNameOfIndividuals.Period = FullNameOfPersons.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDocumentsWithResponsiblePersons.Ref,
	|	TTDocumentsWithResponsiblePersons.EmployeeInCharge_,
	|	TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson,
	|	ISNULL(TTIndividualNames.LastFirstName, """") AS LastFirstName
	|INTO TTDocumentsSFIOResponsible
	|FROM
	|	TTDocumentsWithResponsiblePersons AS TTDocumentsWithResponsiblePersons
	|		LEFT JOIN TTIndividualNames AS TTIndividualNames
	|		ON TTDocumentsWithResponsiblePersons.DefaultResponsiblePerson.Individual = TTIndividualNames.Individual
	|			AND TTDocumentsWithResponsiblePersons.Ref = TTIndividualNames.Ref";
	
	Query.Text = Query.Text + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	// Collapse the result - put all responsible in one record of the query selection
	QueryTemplate = "
	|SELECT
	|	&QuerySelection
	|INTO TTDocumentsSFIOCollapsed
	|FROM
	|	&NestedQuery AS TTDocumentsSFIOResponsible
	|
	|GROUP BY
	|	TTDocumentsSFIOResponsible.Ref
	|";
	
	NestedRequestTemplate = "
	|SELECT
	|	&SelectingNestedRequest
	|FROM
	|	TTDocumentsSFIOResponsible AS TTDocumentsSFIOResponsible
	|WHERE
	|	TTDocumentsSFIOResponsible.EmployeeInCharge_ = &EmployeeInCharge_
	|";
	
	IndexOf = 0;
	QuerySelectionString = "TTDocumentsSFIOResponsible.Ref";
	TheTextOfASubquery = "";
	
	DataAliasesArePassedInParameters = (AliasesOfDataOfResponsiblePersons <> Undefined);
	If Not DataAliasesArePassedInParameters Then
		AliasesOfDataOfResponsiblePersons = AliasesOfDataOfResponsiblePersons();
	EndIf;
	
	For Each KeyAndValue In DetailsResponsiblePersons Do
		
		IndexOf = IndexOf + 1;
		
		NestedQuerySelectionString = "TTDocumentsSFIOResponsible.Ref";
		For Each KeyAndValue2 In DetailsResponsiblePersons Do
			
			If KeyAndValue.Key = KeyAndValue2.Key Then
				NestedQuerySelectionString = NestedQuerySelectionString + ",
				|	TTDocumentsSFIOResponsible.DefaultResponsiblePerson AS " + KeyAndValue2.Key + ",
				|	TTDocumentsSFIOResponsible.DefaultResponsiblePerson.JobTitle AS %AttributesOfJobTitle%,
				|	TTDocumentsSFIOResponsible.DefaultResponsiblePerson.SignatureRightBasis AS %AttributeBasisOfRightToSign%,
				|	TTDocumentsSFIOResponsible.LastFirstName AS %FULLNAMEAttributes%";
			Else
				NestedQuerySelectionString = NestedQuerySelectionString + ",
				|	VALUE(Catalog.PersonsResponsibleAndCompanies.EmptyRef) AS " + KeyAndValue2.Key + ",
				|	"""" AS %AttributesOfJobTitle%,
				|	"""" AS %AttributeBasisOfRightToSign%,
				|	"""" AS %FULLNAMEAttributes%";
			EndIf;

			If DataAliasesArePassedInParameters Then
				NamesStructure2 = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue2.Key);
			Else
				NamesStructure2 = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue2.Value);
			EndIf;

			NestedQuerySelectionString = StrReplace(NestedQuerySelectionString, "%FULLNAMEAttributes%", NamesStructure2.LASTFIRSTNAME);
			NestedQuerySelectionString = StrReplace(NestedQuerySelectionString, "%AttributesOfJobTitle%", NamesStructure2.JobTitle);
			NestedQuerySelectionString = StrReplace(NestedQuerySelectionString, "%AttributeBasisOfRightToSign%", NamesStructure2.SignatureRightBasis);
			
		EndDo;
		
		If IndexOf > 1 Then
			TheTextOfASubquery = TheTextOfASubquery + "
			|UNION ALL
			|";
		EndIf;
		TheTextOfASubquery = TheTextOfASubquery + NestedRequestTemplate;
		
		TheTextOfASubquery = StrReplace(TheTextOfASubquery , "&SelectingNestedRequest", NestedQuerySelectionString);
		
		TextResponsiblePerson =  StrTemplate("VALUE(%1)", GetPredefinedValueFullName(KeyAndValue.Value));
		TheTextOfASubquery = StrReplace(TheTextOfASubquery , "&EmployeeInCharge_", TextResponsiblePerson);
		
		QuerySelectionString = QuerySelectionString + ",
		|	MAX(TTDocumentsSFIOResponsible." + KeyAndValue.Key + ") AS " + KeyAndValue.Key + ",
		|	MAX(TTDocumentsSFIOResponsible.%AttributesOfJobTitle%) AS %AttributesOfJobTitle%,
		|	MAX(TTDocumentsSFIOResponsible.%AttributeBasisOfRightToSign%) AS %AttributeBasisOfRightToSign%,
		|	MAX(TTDocumentsSFIOResponsible.%FULLNAMEAttributes%) AS %FULLNAMEAttributes%";
		
		If DataAliasesArePassedInParameters Then
			NamesStructure = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue.Key);
		Else
			NamesStructure = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue.Value);
		EndIf;

		QuerySelectionString = StrReplace(QuerySelectionString, "%FULLNAMEAttributes%", NamesStructure.LASTFIRSTNAME);
		QuerySelectionString = StrReplace(QuerySelectionString, "%AttributesOfJobTitle%", NamesStructure.JobTitle);
		QuerySelectionString = StrReplace(QuerySelectionString, "%AttributeBasisOfRightToSign%", NamesStructure.SignatureRightBasis);
		
	EndDo;
	
	QueryText = StrReplace(QueryTemplate , "&QuerySelection", QuerySelectionString);
	QueryText = StrReplace(QueryText ,  "&NestedQuery", "(" + TheTextOfASubquery + ")");
	
	Query.Text = Query.Text + QueryText;
	
	// Decipher the data - select the necessary details of the responsible persons in separate fields
	QueryTemplate = "
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Selection
	|INTO TempTableName
	|FROM
	|	TTDocumentsSFIOCollapsed AS TTCollapsed
	|";
	
	SampleStringTemplate = ",
	|	TTCollapsed.%Attribute% AS %Attribute%,
	|	ISNULL(TTCollapsed.%Attribute%.Individual, VALUE(Catalog.Persons.EmptyRef)) AS %Attribute%Individual,
	|	TTCollapsed.%FULLNAMEAttributes% 
	|		+ CASE
	|			WHEN TTCollapsed.%AttributeBasisOfRightToSign% IS NULL
	|				OR TTCollapsed.%AttributeBasisOfRightToSign% = """"
	|			THEN """"
	|			ELSE "", "" + TTCollapsed.%AttributeBasisOfRightToSign%
	|		  END AS %AttributeDescription%,
	|	ISNULL(TTCollapsed.%AttributesOfJobTitle%, """") AS %AttributesOfJobTitle%,
	|	ISNULL(TTCollapsed.%AttributeBasisOfRightToSign%, """") AS %AttributeBasisOfRightToSign%";

	RowSelection = "TTCollapsed.Ref AS Ref";
	For Each KeyAndValue In DetailsResponsiblePersons Do
		CurrentRowSelection = StrReplace(SampleStringTemplate, "%Attribute%", KeyAndValue.Key);
		
		If DataAliasesArePassedInParameters Then
			NamesStructure = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue.Key);
		Else
			NamesStructure = AliasesOfDataOfResponsiblePersons.Get(KeyAndValue.Value);
		EndIf;

		CurrentRowSelection = StrReplace(CurrentRowSelection, "%FULLNAMEAttributes%", NamesStructure.LASTFIRSTNAME);
		CurrentRowSelection = StrReplace(CurrentRowSelection, "%AttributeDescription%", NamesStructure.Description);
		CurrentRowSelection = StrReplace(CurrentRowSelection, "%AttributesOfJobTitle%", NamesStructure.JobTitle);
		CurrentRowSelection = StrReplace(CurrentRowSelection, "%AttributeBasisOfRightToSign%", NamesStructure.SignatureRightBasis);
		
		RowSelection = RowSelection + CurrentRowSelection;
	EndDo;
	
	QueryText = StrReplace(QueryTemplate, "&Selection", RowSelection);
	QueryText = StrReplace(QueryText, "TempTableName", TableNameResponsiblePersons);
	
	// Delete unnecessary temporary tables
	Query.Text = Query.Text + QueryText + "
	|;
	|DROP TTDocumentData
	|;
	|DROP TTUnfilledResponsible
	|;
	|DROP TTResponsibleByDefault
	|;
	|DROP TTCandidatesInChargeByDefault
	|;
	|DROP TTDocumentsWithResponsiblePersons
	|;
	|DROP TTPeriodsFullNameOfIndividuals
	|;
	|DROP TTIndividualNames
	|;
	|DROP TTDocumentsSFIOResponsible
	|;
	|DROP TTDocumentsSFIOCollapsed
	|";
	
	Query.Execute();
	
EndProcedure

// Clears the responsible person in the document.
// 
// Parameters:
//  Object - DocumentObject - Accounting document.
//
Procedure ClearResponsiblePersonInDocument(Object) Export
	
	SetPrivilegedMode(True);
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	EmployeeInChargeInDocuments = GetFunctionalOption("EmployeeInChargeInDocuments");
	UUIDInternal = New UUID("aa00559e-ad84-4494-88fd-f0826edc46f0");
	StandardRef = Catalogs.Users.GetRef(UUIDInternal);
	CurrentUser = Users.AuthorizedUser();
	MetadataOfDocument = Object.Metadata();
	
	If Not EmployeeInChargeInDocuments Or (StandardRef = CurrentUser 
		And Common.ObjectAttributeValue(CurrentUser, "IsInternal")) Then
		
		If MetadataOfDocument.Attributes.Find("EmployeeResponsible") <> Undefined Then
			Object.EmployeeResponsible = Undefined;
		EndIf;
			
		If MetadataOfDocument.Attributes.Find("Manager") <> Undefined Then
			Object.Manager = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the Manager in the document for the contract, agreement, and partner
// 
// Parameters:
//  DocumentObject - DocumentObject, FormDataStructure - object to fill in
//  Refill - Boolean - if True, then fill in even the filled value.
//  SearchFields - String - a comma-separated path to the data that contains the value Of the Manager attribute.
//                        The path consists of the name of the document item, a dot, and the name of the item
//                        that contains a link to the Manager. For Example, " Client.Main Manager, Contract.Manager"
Procedure FillInManager_(DocumentObject, Refill = True, SearchFields = "") Export
	
	If TypeOf(DocumentObject) = Type("FormDataStructure") Then
		MetadataOfDocument = DocumentObject.Ref.Metadata();
	Else
		MetadataOfDocument = DocumentObject.Metadata();
	EndIf;
	
	If MetadataOfDocument.Attributes.Find("Manager") = Undefined Then
		Return;
	EndIf;
	
	UnspecifiedUserRef = Users.UnspecifiedUserRef();
	
	If Not Refill And ValueIsFilled(DocumentObject.Manager)
		And DocumentObject.Manager <> UnspecifiedUserRef Then
		Return;
	EndIf;
		
	If IsBlankString(SearchFields) Then
		If MetadataOfDocument.Attributes.Find("Contract") <> Undefined
			And ValueIsFilled(DocumentObject.Contract) Then
			AttributeName = "Manager";
			If TypeOf(DocumentObject.Contract) = Type("CatalogRef.LoanAndDepositContracts") 
				Or TypeOf(DocumentObject.Contract) = Type("CatalogRef.LeaseContract")
				Then
				AttributeName = "EmployeeResponsible";
			EndIf;
			Manager = Common.ObjectAttributeValue(DocumentObject.Contract, AttributeName);
			If ValueIsFilled(Manager) And Manager <> UnspecifiedUserRef Then
				DocumentObject.Manager = Manager;
				Return;
			EndIf;
		EndIf;
		If MetadataOfDocument.Attributes.Find("Terms") <> Undefined
			And ValueIsFilled(DocumentObject.Terms) Then
			Manager = Common.ObjectAttributeValue(DocumentObject.Terms, "Manager");
			If ValueIsFilled(Manager) And Manager <> UnspecifiedUserRef Then
				DocumentObject.Manager = Manager;
				Return;
			EndIf;
		EndIf;
		If MetadataOfDocument.Attributes.Find("Partner") <> Undefined
			And ValueIsFilled(DocumentObject.Partner) Then
			Manager = Common.ObjectAttributeValue(DocumentObject.Partner, "MainManager");
			If ValueIsFilled(Manager) And Manager <> UnspecifiedUserRef Then
				DocumentObject.Manager = Manager;
			EndIf;
		EndIf;
	Else
		SearchFieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SearchFields, , True, True);
		For Each SearchString In SearchFieldArray Do
			CompositionOfPath = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
				SearchString, ".", True, True);
			If ValueIsFilled(DocumentObject[CompositionOfPath[0]]) Then
				Manager = Common.ObjectAttributeValue(DocumentObject[CompositionOfPath[0]], CompositionOfPath[1]);
				If ValueIsFilled(Manager) And Manager <> UnspecifiedUserRef Then
					DocumentObject.Manager = Manager;
					Return;
				EndIf;
			EndIf;
		EndDo;

	EndIf;
	
EndProcedure

// Returns an empty structure of data aliases for responsible persons.
//
// Returns:
//		Structure - Contains:
//			* Description - String - name.
//			* LASTFIRSTNAME - String - FULL NAME.
//			* JobTitle - String - Position.
//			* SignatureRightBasis - String - The basis of the right of the signature.
Function DataAliasesOfResponsiblePersonsByDefault() Export
	
	Aliases = New Structure();
	Aliases.Insert("Description", "");
	Aliases.Insert("LASTFIRSTNAME", "");
	Aliases.Insert("JobTitle", "");
	Aliases.Insert("SignatureRightBasis", "");
	
	Return Aliases;
	
EndFunction

// Returns a structure containing information about the organization's responsible persons for the payroll and personnel subsystem.
//
// Parameters:
//		Organization - CatalogRef.Companies - Link to the organization
//		InformationRecords - String - string with comma-separated identifiers
//		Date - Date - date the information was received.
//
// Returns:
//		Structure - structure with properties that match the "Information" parameter:
//			* Director - CatalogRef.Persons - head of organisation
//			* JobTitleExecutive - String, CatalogRef - Manager's position
//			* ChiefAccountant - CatalogRef.Persons - chief accountant of the organization
//			* Cashier - CatalogRef.Persons - The cashier of the organization
//			* CashierPosition - String, CatalogRef -the position of cashier
//			* HRDirector - CatalogRef.Persons - Head of HR Department
//			* PositionOfHeadOfPersonnelService - String, CatalogRef - Position of head of HR Department
//			* AssigneeForMaintainingOfMilitaryRegistration - CatalogRef.Persons - Responsible for VUR
//			* PositionOfPersonResponsibleForVUR - String, CatalogRef - Position of the person responsible for the VUR.
//
Function InformationAboutResponsiblePersonsSalaryAndPersonnel(Organization, InformationRecords, Date) Export
	
	SetPrivilegedMode(True);
	
	ResponsiblePersons = GetResponsiblePersonsOfOrganization(Organization, Date);
	
	ThisIsStructure = TypeOf(InformationRecords) = Type("Structure");
	
	If ThisIsStructure Then
		Result = InformationRecords;
	Else
		Result = New Structure;
	EndIf;
	
	If StrFind(InformationRecords, "Director") > 0 Or ThisIsStructure And InformationRecords.Property("Director") Then
		Result.Insert("Director", ResponsiblePersons.Director);
	EndIf;
	
	If StrFind(InformationRecords, "JobTitleExecutive") > 0 Or ThisIsStructure And InformationRecords.Property("JobTitleExecutive") Then
		Result.Insert("JobTitleExecutive", ResponsiblePersons.DirectorJobTitleRef);
	EndIf;
	
	If StrFind(InformationRecords, "ManagerPositionByLine") > 0 Or ThisIsStructure And InformationRecords.Property("ManagerPositionByLine") Then
		Result.Insert("ManagerPositionByLine", ResponsiblePersons.DirectorJobTitle);
	EndIf;
		
	If StrFind(InformationRecords, "ChiefAccountant") > 0 Or ThisIsStructure And InformationRecords.Property("ChiefAccountant") Then
		Result.Insert("ChiefAccountant", ResponsiblePersons.ChiefAccountant);
	EndIf;
	
	If StrFind(InformationRecords, "Cashier") > 0 Or ThisIsStructure And InformationRecords.Property("Cashier") Then
		Result.Insert("Cashier", ResponsiblePersons.Cashier);
	EndIf;
	
	If StrFind(InformationRecords, "CashierPosition") > 0 Or ThisIsStructure And InformationRecords.Property("CashierPosition") Then
		Result.Insert("CashierPosition", ResponsiblePersons.CashierJobTitleRef);
	EndIf;
	
	If StrFind(InformationRecords, "CashierPositionByLine") > 0 Or ThisIsStructure And InformationRecords.Property("CashierPositionByLine") Then
		Result.Insert("CashierPositionByLine", ResponsiblePersons.CashierJobTitle);
	EndIf;

	If StrFind(InformationRecords, "HRDirector") > 0 Or ThisIsStructure And InformationRecords.Property("HRDirector") Then
		Result.Insert("HRDirector", ResponsiblePersons.HRDirector);
	EndIf;
	
	If StrFind(InformationRecords, "PositionOfHeadOfPersonnelService") > 0 Or ThisIsStructure And InformationRecords.Property("PositionOfHeadOfPersonnelService") Then
		Result.Insert("PositionOfHeadOfPersonnelService", ResponsiblePersons.HeadOfHRDepartmentPositionReference);
	EndIf;
	
	If StrFind(InformationRecords, "PositionOfHeadOfPersonnelServiceLine") > 0 Or ThisIsStructure And InformationRecords.Property("PositionOfHeadOfPersonnelServiceLine") Then
		Result.Insert("PositionOfHeadOfPersonnelServiceLine", ResponsiblePersons.HeadOfHRDepartmentPosition);
	EndIf;
	
	If StrFind(InformationRecords, "AssigneeForMaintainingOfMilitaryRegistration") > 0 Or ThisIsStructure And InformationRecords.Property("AssigneeForMaintainingOfMilitaryRegistration") Then
		Result.Insert("AssigneeForMaintainingOfMilitaryRegistration", ResponsiblePersons.AssigneeForMaintainingOfMilitaryRegistration);
	EndIf;
	
	If StrFind(InformationRecords, "PositionOfPersonResponsibleForVUR") > 0 Or ThisIsStructure And InformationRecords.Property("PositionOfPersonResponsibleForVUR") Then
		Result.Insert("PositionOfPersonResponsibleForVUR", ResponsiblePersons.AssigneeForMaintainingOfMilitaryRegistrationJobTitleRef);
	EndIf;
	
	If StrFind(InformationRecords, "PositionOfPersonResponsibleForVurLine") > 0 Or ThisIsStructure And InformationRecords.Property("PositionOfPersonResponsibleForVurLine") Then
		Result.Insert("PositionOfPersonResponsibleForVurLine", ResponsiblePersons.AssigneeForMaintainingOfMilitaryRegistrationJobTitle);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters for filling in the manager.
// 
// Returns:
//   Structure - Manager's Fill-In Parameters:
//     * Refill - Boolean - 
//     * Manager_Name - String - 
//     * FillInTheDepartment - Boolean - 
//     * Division_Name - String - 
//
Function ManagerSFillInParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Refill", True);
	Parameters.Insert("Manager_Name", "Manager");
	Parameters.Insert("FillInTheDepartment", False);
	Parameters.Insert("Division_Name", "Department");
	
	Return Parameters;
	
EndFunction

// Sets the manager from the base document, according to statistics, by the Cur user.
// 
// Parameters:
//   Object - DocumentObject, FormDataStructure - the object to fill in.
//   DocumentBasis - DocumentRef, Undefined - document Foundation.
//   FillParameters - Structure, Undefined - See ManagerSFillInParameters
// 
Procedure InstallManager(Object, DocumentBasis = Undefined, FillParameters = Undefined) Export
	
	If FillParameters = Undefined Then
		FillParameters = ManagerSFillInParameters();
	EndIf;
	
	Refill = FillParameters.Refill;
	Manager_Name = FillParameters.Manager_Name;
	FillInTheDepartment = FillParameters.FillInTheDepartment;
	Division_Name = FillParameters.Division_Name;
	
	If ValueIsFilled(Object[Manager_Name]) And Not Refill Then
		Return;
	EndIf;
	
	ValueBeforeChanges = Object[Manager_Name];
	ManagerIsInstalled = False;
	
	// Manager from the foundation document
	If ValueIsFilled(DocumentBasis) Then
		SetPrivilegedMode(True);
		FoundationManager = Undefined;
		If Common.HasObjectAttribute(Manager_Name, DocumentBasis.Metadata()) Then
			FoundationManager = Common.ObjectAttributeValue(DocumentBasis, Manager_Name);
		ElsIf Common.HasObjectAttribute("EmployeeResponsible", DocumentBasis.Metadata()) Then
			FoundationManager = Common.ObjectAttributeValue(DocumentBasis, "EmployeeResponsible");
		EndIf;
		If ValueIsFilled(FoundationManager) Then
			Object[Manager_Name] = FoundationManager;
			ManagerIsInstalled = True;
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	// Fill in the statistics manager
	If Not ManagerIsInstalled Then
		
		LinkForStatistics = Object.Ref;
		StatisticsCollectionSections = New Array;
		DetailsForSelection = New Structure;
		
		If Common.HasObjectAttribute("Partner", LinkForStatistics.Metadata())
			And ValueIsFilled(Object.Partner) Then
			StatisticsCollectionSections.Add("Partner");
			DetailsForSelection.Insert("Partner", Object.Partner);
		EndIf;
		If Common.HasObjectAttribute("Terms", LinkForStatistics.Metadata())
			And ValueIsFilled(Object.Terms) Then
			StatisticsCollectionSections.Add("Terms");
			DetailsForSelection.Insert("Terms", Object.Terms);
		EndIf;
		If Common.HasObjectAttribute("Contract", LinkForStatistics.Metadata())
			And ValueIsFilled(Object.Contract) Then
			StatisticsCollectionSections.Add("Contract");
			DetailsForSelection.Insert("Contract", Object.Contract);
		EndIf;
		If Common.HasObjectAttribute("Organization", LinkForStatistics.Metadata())
			And ValueIsFilled(Object.Organization) Then
			StatisticsCollectionSections.Add("Organization");
			DetailsForSelection.Insert("Organization", Object.Organization);
		EndIf;
		
		If StatisticsCollectionSections.Count() > 0 Then
			AttributesDetails1 = New Structure;
			Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
			Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = StrConcat(StatisticsCollectionSections, ", ");
			
			If Common.HasObjectAttribute("Author", LinkForStatistics.Metadata()) Then
				Parameters.StatisticsCollectionSections.UseAlways = "Author";
				Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
			EndIf;
			
			ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, Manager_Name, Parameters);
			DetailsToFillIn = ObjectsFillingByStatistics.GetBankingDetailsValues(
				LinkForStatistics, AttributesDetails1, DetailsForSelection);
				
			If ValueIsFilled(DetailsToFillIn[Manager_Name]) Then
				Object[Manager_Name] = DetailsToFillIn[Manager_Name];
				ManagerIsInstalled = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Cur current user
	If Not ManagerIsInstalled Then
		If Users.IsExternalUserSession() Then
			Object[Manager_Name] = SelfServiceServer.PrimaryExternalUserManager(Users.AuthorizedUser());
		Else
			Object[Manager_Name] = Users.CurrentUser();
		EndIf;
	EndIf;
	
	// Subordinate Attributes
	If ValueBeforeChanges <> Object[Manager_Name] And FillInTheDepartment Then
		Object[Division_Name] = SettingsValueCached.UserDivision(Object[Manager_Name]);
	EndIf;
	
EndProcedure

// Fills in the manager's selection list.
// 
// Parameters:
//  ManagerElement - FormField - The Form element that specifies the Manager.
//  Object - FormDataStructure - the object whose details are used for filling in.
//
Procedure FillInManagerSelectionList_(ManagerElement, Object) Export
	
	ChoiceList = ManagerElement.ChoiceList;
	ChoiceList.Clear();
	
	Attributes = New Structure("Partner, Terms, Contract");
	FillPropertyValues(Attributes, Object);
	
	SetPrivilegedMode(True);
	
	If ValueIsFilled(Attributes.Partner) Then
		Manager = Common.ObjectAttributeValue(Attributes.Partner, "MainManager");
		If ValueIsFilled(Manager) Then
			ChoiceList.Add(Manager,
				StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", Manager, NStr("vi = 'Bạn hàng';
																									|ru = 'Партнер';
																									|en = 'Partner'; fa = 'شریک تجاری';
																									|it = 'Партнер';
																									|pl = 'Partner';
																									|tr = 'İş ortağı'")));
		EndIf;
	EndIf;
	
	If ValueIsFilled(Attributes.Terms) Then
		Manager = Common.ObjectAttributeValue(Attributes.Terms, "Manager");
		If ValueIsFilled(Manager) Then
			ChoiceList.Add(Manager,
				StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", Manager, NStr("vi = 'Thỏa thuận';
																									|ru = 'Соглашение';
																									|en = 'Agreement'; fa = 'توافق‌نامه';
																									|it = 'Соглашение';
																									|pl = 'Porozumienie';
																									|tr = 'Anlaşma'")));
		EndIf;
	EndIf;
	
	If ValueIsFilled(Attributes.Contract) Then
		Manager = Common.ObjectAttributeValue(Attributes.Contract, "Manager");
		If ValueIsFilled(Manager) Then
			ChoiceList.Add(Manager,
				StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", Manager, NStr("vi = 'Hợp đồng';
																									|ru = 'Договор';
																									|en = 'Contract'; fa = 'قرارداد';
																									|it = 'Договор';
																									|pl = 'Contract';
																									|tr = 'Sözleşme'")));
		EndIf;
	EndIf;
	
	SetPrivilegedMode(False);
	
	CurrentUser = Users.CurrentUser();
	Presentation = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", CurrentUser, NStr("vi = 'Người sử dụng hiện tại';
																										|ru = 'Текущий пользователь';
																										|en = 'Current user'; fa = 'کاربر فعلی';
																										|it = 'Текущий пользователь';
																										|pl = 'Bieżący użytkownik';
																										|tr = 'Mevcut kullanıcı'"));
	ChoiceList.Add(CurrentUser, Presentation);
	
	Managers = CommonClientServer.CollapseArray(ChoiceList.UnloadValues());
	If Managers.Count() = 1 Then
		ChoiceList.Clear();
		ChoiceList.Add(Managers[0]);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersChangeResponsiblePersons

// Event handler for "when Changing" key document details (date, Organization).
// Checks the compliance of the responsible persons with the document and key details.
//
// Parameters:
//	Object - FormDataStructure - the "Object" property of the document form.
//
Procedure WhenChangingRelatedDocumentDetails(Object) Export
	
	FillInResponsiblePersonsOfDocument(Object,, True);
	
EndProcedure


// The event subscription handler is responsible for the document processingofill.
// Fills in the details of the responsible persons of the document with the default values.
//
// Parameters:
// 	Source - DocumentObject -
// 	FillingData - Arbitrary -
// 	StandardProcessing - Boolean - 
// 
Procedure EmployeesInChargeOfFillingDocument(Source, FillingData, StandardProcessing) Export
	
	If Not ResponsiblePersonsCached.ThereAreDetailsOfResponsiblePersonsOfDocument(Source.Metadata().Name) Then
		Return;
	EndIf;
	
	FillInResponsiblePersonsOfDocument(Source, FillingData);
	
EndProcedure

// The event subscription handler is responsible for the copy-to-document.
// Fills in the details of the responsible persons of the document with default values.
//
// Parameters:
// 	Source - DocumentObject -
// 	CopiedObject - DocumentObject -
// 
Procedure EmployeesInChargeOfOnCopyDocument(Source, CopiedObject) Export
	
	If Not ResponsiblePersonsCached.ThereAreDetailsOfResponsiblePersonsOfDocument(Source.Metadata().Name) Then
		Return;
	EndIf;
	
	FillInResponsiblePersonsOfDocument(Source, CopiedObject);
	
EndProcedure

// The event subscription handler is responsible for documentprocessingcheckfill.
// Checks the correctness of filling in the details of the responsible persons of the document.
//
// Parameters:
// 	Source - DocumentObject -
// 	Cancel - Boolean -
// 	CheckedAttributes - Array of String -
//
Procedure EmployeesInChargeOfFillCheckProcessingDocument(Source, Cancel, CheckedAttributes) Export
	
	If Not ResponsiblePersonsCached.ThereAreDetailsOfResponsiblePersonsOfDocument(Source.Metadata().Name) Then
		Return;
	EndIf;
	
	DataStructureOfResponsiblePersons = DataStructureOfResponsiblePersonsOfDocument(Source);
	
	DetailsResponsiblePersons = DataStructureOfResponsiblePersons.DetailsResponsiblePersons;
	
	CheckStructure = New Structure;
	CheckStructure.Insert("Organization", DetailsResponsiblePersons);
	If DataStructureOfResponsiblePersons.Property("AttributesOfResponsiblePersonsOfCounterpartySOrganization") Then
		CheckStructure.Insert("Counterparty", DataStructureOfResponsiblePersons.AttributesOfResponsiblePersonsOfCounterpartySOrganization);
	EndIf;
	
	For Each KeyAndValueOfValidationStructure In CheckStructure Do
		
		For Each KeyAndValue In KeyAndValueOfValidationStructure.Value Do
			
			ValueOfResponsiblePerson = DataStructureOfResponsiblePersons[KeyAndValue.Key];
			If ValueIsFilled(ValueOfResponsiblePerson) Then
				
				VerificationDetails_ =
					New Structure(
						"Date, Organization, EmployeeInCharge_",
						DataStructureOfResponsiblePersons.Date, 
						DataStructureOfResponsiblePersons[KeyAndValueOfValidationStructure.Key], 
						KeyAndValue.Value);
				
				// If the Attribute is filled in incorrectly, we will inform the user and set the parameter Denial = True.
				If Not CheckComplianceOfDetailsAndResponsiblePerson(VerificationDetails_, ValueOfResponsiblePerson) Then
					
					AttributeRepresentation = Source.Metadata().Attributes.Find(KeyAndValue.Key).Synonym;
					
					ErrorMessage = NStr("vi = 'Người chịu trách nhiệm ""%AttributeRepresentation%"" vào ngày %DatePresentation% không có quyền ký chứng từ này.';
										|ru = 'Ответственное лицо ""%AttributeRepresentation%"" на дату %DatePresentation% не имеет права подписи этого документа.';
										|en = 'The responsible person ""%AttributeRepresentation%"" does not have the right to sign this document as of %DatePresentation%.'; fa = 'The responsible person ""%AttributeRepresentation%"" does not have the right to sign this document as of %DatePresentation%.';
										|it = 'Il responsabile %AttributeRepresentation% in data %DatePresentation% non possiede i diritti di firma per questo documento.';
										|pl = 'Osoba odpowiedzialna ""%AttributeRepresentation%"" na dzień %DatePresentation% nie ma prawa do podpisywania tego dokumentu.';
										|tr = '""%AttributeRepresentation%"" sorumlu kişi %DatePresentation% tarihine bu belgeni imzalama yetkisine sahip değil.'");
					ErrorMessage = StrReplace(ErrorMessage, "%AttributeRepresentation%", AttributeRepresentation);
					ErrorMessage = StrReplace(ErrorMessage, "%DatePresentation%", Format(DataStructureOfResponsiblePersons.Date, "DLF=D"));
					CommonClientServer.MessageToUser(
						ErrorMessage,
						,
						"Object." + KeyAndValue.Key,
						,
						Cancel);
					
				EndIf;
					
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region AncillaryServiceProcedures

// Creates a structure containing information about the responsible persons of the document
//	
//	Parameters:
//		Object - DocumentObject, FormDataStructure - the object for which to get the data
//	Returns:
//		Structure - with keys:
//			* DetailsResponsiblePersons - Structure of KeyAndValue - Contains:
//				** Key - String - name of the document details that store information about the responsible person
//				** Value - EnumRef.PersonsResponsibleAndCompanies - "type" of the responsible person
//			* Ref - DocumentRef -
//			* Date   - Date - Document date
//          * Organization - CatalogRef.Companies - the organization for which you want to responsible persons
//          <Markwiesenstrasse> - Spravochnike.Responsible persons of organizations - the current responsible
//              persons specified in the document.
//			
Function DataStructureOfResponsiblePersonsOfDocument(Object)
	
	StructureOfData = New Structure("Ref, Date, Organization");
	StructureOfData.Insert(
		"DetailsResponsiblePersons",
		ResponsiblePersonsCached.DetailsOfResponsiblePersonsOfDocument(Object.Ref.Metadata().Name));
	If TypeOf(Object) <> Type("FormDataStructure")
		And Object.AdditionalProperties.Property("ResponsiblePersons") Then
		StructureOfData.Insert(
			"DetailsResponsiblePersons",
			Object.AdditionalProperties.ResponsiblePersons.DetailsResponsiblePersons);
		StructureOfData.Insert(
			"AttributesOfResponsiblePersonsOfCounterpartySOrganization",
			Object.AdditionalProperties.ResponsiblePersons.AttributesOfResponsiblePersonsOfCounterpartySOrganization);
		For Each StructureItem In StructureOfData.AttributesOfResponsiblePersonsOfCounterpartySOrganization Do
			StructureOfData.Insert(StructureItem.Key);
		EndDo;
		StructureOfData.Insert("Counterparty", Catalogs.Companies.EmptyRef());
	EndIf;
	
	For Each StructureItem In StructureOfData.DetailsResponsiblePersons Do
		StructureOfData.Insert(StructureItem.Key);
	EndDo;
	
	FillPropertyValues(StructureOfData, Object);
	
	Return StructureOfData;
	
EndFunction

// Checks compliance of the responsible person and key details of the document.
//
// Parameters:
//	VerificationDetails_ - Structure - structure of Attributes of a document with keys:
//		* Date - Date - 
//		* Organization - CatalogRef.Companies - 
//		* EmployeeInCharge_ - EnumRef.PersonsResponsibleAndCompanies - "type" of the responsible person
//		* DeletionMark - Boolean - optional, check the mark for deleting the responsible person
//	ResponsiblePersonForVerification - CatalogRef.PersonsResponsibleAndCompanies - responsible person.
//
// Returns:
//	Boolean - Test result
//
Function CheckComplianceOfDetailsAndResponsiblePerson(VerificationDetails_, ResponsiblePersonForVerification)
	
	If Not ValueIsFilled(ResponsiblePersonForVerification) Then
		Return True;
	EndIf;
	
	DetailsOfResponsiblePerson =
		Common.ObjectAttributesValues(
			ResponsiblePersonForVerification,
			"Owner, EmployeeInCharge_, StartDate, EndDate, DeletionMark"); 
	
	Date = BegOfDay(VerificationDetails_.Date);
	
	If DetailsOfResponsiblePerson.Owner <> VerificationDetails_.Organization
	 Or DetailsOfResponsiblePerson.EmployeeInCharge_ <> VerificationDetails_.EmployeeInCharge_
	 Or DetailsOfResponsiblePerson.StartDate > Date
	 Or (ValueIsFilled(DetailsOfResponsiblePerson.EndDate) And DetailsOfResponsiblePerson.EndDate < Date)
	 Or (VerificationDetails_.Property("DeletionMark")
	 		And DetailsOfResponsiblePerson.DeletionMark <> VerificationDetails_.DeletionMark) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Checks whether the values of the details of the responsible persons of the document and the key details of the document match.
// If the values do not match, the procedure selects the appropriate value for the responsible person.
// Parameters:
// 	Document requisites - document Object, Structure-document data
//		- key details (date, Organization, Link)
//		- details of responsible persons.
//
// Returns:
//  Structure - the structure of the changed details of the responsible persons of the document
//		Key - the name of the changed document details
//		Value - the new value of the props.
//
Function CorrectResponsiblePersonsOfDocument(DataStructureOfResponsiblePersons)
	
	ChangedBankingDetails = New Structure;
	
	DetailsResponsiblePersons = DataStructureOfResponsiblePersons.DetailsResponsiblePersons;
	Date = ?(ValueIsFilled(DataStructureOfResponsiblePersons.Date), DataStructureOfResponsiblePersons.Date, CurrentSessionDate());
	
	AdjustmentStructure = New Structure;
	AdjustmentStructure.Insert("Organization", DetailsResponsiblePersons);
	If DataStructureOfResponsiblePersons.Property("AttributesOfResponsiblePersonsOfCounterpartySOrganization") Then
		AdjustmentStructure.Insert(
			"Counterparty", 
			DataStructureOfResponsiblePersons.AttributesOfResponsiblePersonsOfCounterpartySOrganization);
	EndIf;
	
	For Each KeyAndMeaningOfAdjustmentStructure In AdjustmentStructure Do
		
		OrganizationForAdjustments = DataStructureOfResponsiblePersons[KeyAndMeaningOfAdjustmentStructure.Key];
		
		TableOfResponsiblePersons = GetTableOfResponsiblePersonsForSelection(
			New Structure("Date, Organization", Date, OrganizationForAdjustments));
		
		For Each KeyAndValue In KeyAndMeaningOfAdjustmentStructure.Value Do
			
			ValueOfResponsiblePerson = DataStructureOfResponsiblePersons[KeyAndValue.Key];
			
			VerificationDetails_ = New Structure;
			VerificationDetails_.Insert("Date", 			   Date);
			VerificationDetails_.Insert("Organization", 	   OrganizationForAdjustments);
			VerificationDetails_.Insert("EmployeeInCharge_", KeyAndValue.Value);
			VerificationDetails_.Insert("DeletionMark",   False);
			
			// If an unsuitable responsible person is selected, then we will clear it
			If ValueIsFilled(ValueOfResponsiblePerson)
			 And Not CheckComplianceOfDetailsAndResponsiblePerson(VerificationDetails_, ValueOfResponsiblePerson) Then
				ValueOfResponsiblePerson = Catalogs.PersonsResponsibleAndCompanies.EmptyRef();
			EndIf;
			
			// If the responsible person is not selected, then we will try to pick him up
			If Not ValueIsFilled(ValueOfResponsiblePerson) Then
				TableRows = TableOfResponsiblePersons.FindRows(New Structure("EmployeeInCharge_", KeyAndValue.Value));
				If TableRows.Count() = 1 Then
					ValueOfResponsiblePerson = TableRows[0].Ref; // it is possible to uniquely identify the responsible
				EndIf;
			EndIf;
			
			// Let's remember the change of props
			If DataStructureOfResponsiblePersons[KeyAndValue.Key] <> ValueOfResponsiblePerson Then
				ChangedBankingDetails.Insert(KeyAndValue.Key, ValueOfResponsiblePerson);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return ChangedBankingDetails;
	
EndFunction

// Fills in the values of the document's responsible persons with the default values.
//
// Parameters:
//	Object - DocumentObject - the document whose Attributes need to be filled in:
//  	* AdditionalProperties - Structure - Additional object properties:
//  		** DisableObjectFillingBasedOnStatistics - Boolean - True if you need to disable filling in details based on statistics.
//  		                                                     For example, in the scenario of loading objects from another system.
//         - FormDataStructure - document data when called from the form.
//	FillingData - Arbitrary - an object that contains data for filling in the document.
//	FillInNonEmptyDetails - Boolean - the need to re-fill the details even when they already contain values.
//
Procedure FillInResponsiblePersonsOfDocument(Object, FillingData = Undefined, FillInNonEmptyDetails = False)
	
	DataStructureOfResponsiblePersons = DataStructureOfResponsiblePersonsOfDocument(Object);
	
	// Fill in the empty details with non-empty values from the data to be filled in, while
	// - we do not fill in the system details
	// - we do not take the date (in case of copying the document or entering on the basis).
	If FillingData <> Undefined Then
		
		For Each KeyAndValue In DataStructureOfResponsiblePersons Do
			
			If KeyAndValue.Key = "DetailsResponsiblePersons"
			 Or KeyAndValue.Key = "Ref"
			 Or (KeyAndValue.Key = "Date" And TypeOf(FillingData) <> Type("Structure"))
			 Or TypeOf(FillingData) = Type("String") // autotesting
			 Or ValueIsFilled(KeyAndValue.Value) Then
				Continue;
			EndIf;
			
			DetailsToFillIn_ = New Structure(KeyAndValue.Key);
			FillPropertyValues(DetailsToFillIn_, FillingData);
			If ValueIsFilled(DetailsToFillIn_[KeyAndValue.Key]) Then
				FillPropertyValues(DataStructureOfResponsiblePersons, DetailsToFillIn_);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FillInDetailsOfResponsiblePersonsForStatistics(DataStructureOfResponsiblePersons, Object, FillInNonEmptyDetails);
	
	// We will check the compliance of the responsible persons with the date and organization of the document.
	// If it does not match, we will fill in the responsible persons by default.
	ChangedBankingDetails = CorrectResponsiblePersonsOfDocument(DataStructureOfResponsiblePersons);
	FillPropertyValues(DataStructureOfResponsiblePersons, ChangedBankingDetails);
	
	// Transfer the details to the object
	FillPropertyValues(Object, DataStructureOfResponsiblePersons, , "Ref, Date");
	
EndProcedure

Procedure FillInDetailsOfResponsiblePersonsForStatistics(DataStructureOfResponsiblePersons, Object, FillInNonEmptyDetails)
	
	If TypeOf(Object) <> Type("FormDataStructure")
		And Object.AdditionalProperties.Property("DisableObjectFillingBasedOnStatistics")
		And Object.AdditionalProperties.DisableObjectFillingBasedOnStatistics Then
		Return;
	EndIf;
	
	FillInAccordingToStatistics = CommonSettingsStorage.Load(
		"DocumentSettings_", "FillInDocumentAttributesUsingStatisticalData");
	If FillInAccordingToStatistics = False Then
		Return;
	EndIf;
	
	// We will get the values of the details of the responsible persons according to statistics
	AttributesDetails1 = New Structure;
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	If TMCommonUseClientServer.HasObjectAttribute(Object, "Author") Then
		Parameters.StatisticsCollectionSections.UseAlways = "Author";
		Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	EndIf;
	For Each Attribute In DataStructureOfResponsiblePersons.DetailsResponsiblePersons Do
		ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, Attribute.Key, Parameters);
	EndDo;
	DetailsForSelection = New Structure("Organization", DataStructureOfResponsiblePersons.Organization);
	DetailsToFillIn = ObjectsFillingByStatistics.GetBankingDetailsValues(
		DataStructureOfResponsiblePersons.Ref, AttributesDetails1, DetailsForSelection);
	
	For Each KeyAndValue In DataStructureOfResponsiblePersons.DetailsResponsiblePersons Do
		If (FillInNonEmptyDetails Or Not ValueIsFilled(DataStructureOfResponsiblePersons[KeyAndValue.Key]))
		 And ValueIsFilled(DetailsToFillIn[KeyAndValue.Key]) Then
			DataStructureOfResponsiblePersons[KeyAndValue.Key] = DetailsToFillIn[KeyAndValue.Key];
		EndIf;
	EndDo;
	
EndProcedure

// Generates the names of the responsible persons' Attributes fields for each value from the link enumeration.Responsibilitiesorganizations
// 
// Returns:
//		Map - contains data:
//			* Key - EnumRef.PersonsResponsibleAndCompanies
//			* Value - See ResponsiblePersonsServer.DataAliasesOfResponsiblePersonsByDefault.
Function AliasesOfDataOfResponsiblePersons()
	
	FieldsMap = New Map();
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "DirectorDescription";
	StructureOfAliases.LASTFIRSTNAME = "DirectorLastFirstName";
	StructureOfAliases.JobTitle = "DirectorJobTitle";
	StructureOfAliases.SignatureRightBasis = "DirectorSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.Director, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "ChiefAccountantDescription";
	StructureOfAliases.LASTFIRSTNAME = "ChiefAccountantLastFirstName";
	StructureOfAliases.JobTitle = "ChiefAccountantJobTitle";
	StructureOfAliases.SignatureRightBasis = "ChiefAccountantSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.ChiefAccountant, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "HeadOfHRDepartmentName";
	StructureOfAliases.LASTFIRSTNAME = "HeadOfHRDepartmentFULLName";
	StructureOfAliases.JobTitle = "HeadOfHRDepartmentPosition";
	StructureOfAliases.SignatureRightBasis = "HeadOfPersonnelServiceBasisOfRightOfSignature";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.HRDirector, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "CashierDescription";
	StructureOfAliases.LASTFIRSTNAME = "CashierLastFirstName";
	StructureOfAliases.JobTitle = "CashierJobTitle";
	StructureOfAliases.SignatureRightBasis = "CashierSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.Cashier, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "AssigneeForMaintainingOfAccountingRegistersDescription";
	StructureOfAliases.LASTFIRSTNAME = "AssigneeForMaintainingOfAccountingRegistersLastFirstName";
	StructureOfAliases.JobTitle = "AssigneeForMaintainingOfAccountingRegistersJobTitle";
	StructureOfAliases.SignatureRightBasis = "AssigneeForMaintainingOfAccountingRegistersSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.AssigneeForMaintainingOfAccountingRegisters, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "AssigneeForMaintainingOfTaxRegistersDescription";
	StructureOfAliases.LASTFIRSTNAME = "AssigneeForMaintainingOfTaxRegistersLastFirstName";
	StructureOfAliases.JobTitle = "AssigneeForMaintainingOfTaxRegistersJobTitle";
	StructureOfAliases.SignatureRightBasis = "AssigneeForMaintainingOfTaxRegistersSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.AssigneeForMaintainingOfTaxRegisters, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "AuthorizedRepresentativeInTaxAuthorityDescription";
	StructureOfAliases.LASTFIRSTNAME =  "AuthorizedRepresentativeInTaxAuthorityLastFirstName";
	StructureOfAliases.JobTitle =  "AuthorizedRepresentativeInTaxAuthorityJobTitle";
	StructureOfAliases.SignatureRightBasis =  "AuthorizedRepresentativeInTaxAuthoritySignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.AuthorizedRepresentativeInTaxAuthority, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "PerformerDescription";
	StructureOfAliases.LASTFIRSTNAME = "PerformerLastFirstName";
	StructureOfAliases.JobTitle = "PerformerJobTitle";
	StructureOfAliases.SignatureRightBasis = "PerformerSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.Performer, StructureOfAliases);
	
	StructureOfAliases = DataAliasesOfResponsiblePersonsByDefault();
	StructureOfAliases.Description = "AssigneeForMaintainingOfMilitaryRegistrationDescription";
	StructureOfAliases.LASTFIRSTNAME = "AssigneeForMaintainingOfMilitaryRegistrationLastFirstName";
	StructureOfAliases.JobTitle = "AssigneeForMaintainingOfMilitaryRegistrationJobTitle";
	StructureOfAliases.SignatureRightBasis = "AssigneeForMaintainingOfMilitaryRegistrationSignatureRightBasis";
	FieldsMap.Insert(Enums.PersonsResponsibleAndCompanies.AssigneeForMaintainingOfMilitaryRegistration, StructureOfAliases);
	
	Return FieldsMap;
	
EndFunction

#EndRegion

#EndRegion
