////////////////////////////////////////////////////////////////////////////////
// Expansion of the subsystem "Individuals" for UT and ERP.
//
// Instead of the functions of the BSP module of the Physical Client Server, designed to
// obtain various information about the full name of an individual,
// you should use the functions of the same name of this module.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FullNameOfPersons

// Forms a structure containing information about the surname, first name, and patronymic of an individual.
// The string is formed depending on the type of parameter passed:
//	- either by the history of the full name of the element in the physical Object reference list,
// 	- or by parsing the string containing the full name.
//
// Parameters:
//  Individual - String, CatalogRef.Persons - source of information about full name
//  Date - Date - date for getting the full name history, it makes sense if the first parameter contains a link.
//
// Returns:
//	Structure - with properties:
//		* LastName  - String
//		* Name      - String
//		* MiddleName - String
//
Function FullName(Individual, Date = Undefined) Export
	NameOfIndividual = New Structure("LastName, Name, MiddleName", "", "", "");
	
	If ValueIsFilled(Individual) Then
		
		If TypeOf(Individual) = Type("CatalogRef.Persons") Then
			
			// We will get a slice of the register of information of physical and Physical persons on the desired date
			SetPrivilegedMode(True);
			
			SliceTable = InformationRegisters.FullNameOfPersons.SliceLast(
				?(ValueIsFilled(Date), Date, CurrentSessionDate()),
				New Structure("Individual", Individual));
			
			SetPrivilegedMode(False);
			
			If SliceTable.Count() > 0 Then
				// If there is data in the register, then fill in the returned structure
				FillPropertyValues(NameOfIndividual, SliceTable[0]);
			EndIf;
			
		Else
			
			// The result is obtained by parsing the line containing the full name
			FillPropertyValues(
				NameOfIndividual,
				PersonsClientServer.NameParts(TrimAll(Individual), "LastName,Name"));
			
		EndIf;
		
	EndIf;
	PersonsLocalization.AddFullName(Individual, NameOfIndividual, Date);
	Return NameOfIndividual;
EndFunction

// Generates a string containing the last name and initials of an individual.
// The string is formed depending on the type of parameter passed:
//	- either by the history of the full name of the element in the physical Object reference list,
// 	- or by parsing the string containing the full name.
//
// Parameters:
//  Individual - String, CatalogRef.Persons - source of information about full name
//  Date - Date - date for getting the full name history, it makes sense if the first parameter contains a link.
//
// Returns:
//  String - Surname and. O . 
//
Function IndividualShortName(Individual, Date = Undefined) Export
	InitialsAndLastName = "";
	PersonsLocalization.AddSurnameInitialsOfIndividual(Individual, InitialsAndLastName, Date); 
	If InitialsAndLastName = "" Then
		InitialsAndLastName = TrimAll(Individual);
	EndIf;
	Return InitialsAndLastName;
EndFunction

// Converts the passed array of individuals to a string.
// Used to present a summary of documents.
//
// Parameters:
//	Persons - Array of CatalogRef.Persons - array of elements of the reference Link type.Physical particle,
//	UpdateDate - Date - date for getting the last name, first name, and patronymic.
//  MaxStringLength - Number - Maximum line length
//
// Returns:
//  String - Short List Of Individuals
// 
Function ShortListOfIndividuals(Persons, UpdateDate, MaxStringLength = 100) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FullNameOfPersons.LastName  AS LastName,
	|	FullNameOfPersons.Name      AS Name,
	|	FullNameOfPersons.MiddleName AS MiddleName
	|FROM
	|	InformationRegister.FullNameOfPersons.SliceLast(&UpdateDate) AS FullNameOfPersons
	|WHERE
	|	FullNameOfPersons.Individual IN(&Persons)
	|";
	Query.SetParameter("UpdateDate", UpdateDate);
	Query.SetParameter("Persons",   Persons);
	
	ShortComposition = "";
	FullNameTemplate = "%1 %2";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Not IsBlankString(ShortComposition) Then
			ShortComposition = ShortComposition + ", ";
		EndIf;
		
		If Not IsBlankString(Selection.Name) Then
			
			Names = ComponentsOfName(Selection.Name);
			If Names.Count() > 1 Then
				Initials = Left(Names[0], 1) + ".-" + Left(Names[1], 1) + ".";
			Else
				Initials = Left(Selection.Name, 1) + ".";
			EndIf;
			
			If Not IsBlankString(Selection.MiddleName) Then
				Initials = Initials + Left(Selection.MiddleName, 1) + ".";
			EndIf;
			
		EndIf;
			
		ShortComposition = ShortComposition + TrimAll(StrTemplate(FullNameTemplate, Selection.LastName, Initials));
		
	EndDo;
	
	If StrLen(ShortComposition) > MaxStringLength Then
		ShortComposition = Left(ShortComposition, MaxStringLength - 3) + "...";
	EndIf;
	
	Return ShortComposition;
	
EndFunction

// Creates a temporary table of physical and physical faces. Table composition:
//  Physical Person Reference link.Physical beauty.
//  Period - Date - the date on which the name of the individual was received.
//  Last name is a String.
//  The name is a String.
//  Patronymic - String.
//  Lastname - String.
//  Surname Initials - String.
//
// Parameters:
//  TempTablesManager - TempTablesManager - the manager containing the incoming table filter "VT periodyphysical faces":
//   *Individual - CatalogRef.Persons - an individual who needs to get a full name.
//   *Period - Date  - the date on which you want to get your full name.
//  NameOfIncomingTable  - String - The name of the incoming filter table, which is contained in the temporary table manager,
//                                 the default value is "In the period of physical data".
//  NameOfOutgoingTable - String - the name of the resulting table, which will contain the full names of individuals,
//                                 the default value is "Vtfiophysical persons".
//
Procedure CreateVTFIOOfIndividuals(TempTablesManager, NameOfIncomingTable = "TTPeriodsOfIndividuals", NameOfOutgoingTable = "VTFIOOfIndividuals") Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	PeriodsOfIndividuals.Individual AS Individual,
	|	PeriodsOfIndividuals.Period AS Period,
	|	MAX(FullNameOfPersons.Period) AS SliceDate
	|INTO TTFilterForCutOffOfLastFullName
	|FROM
	|	TTPeriodsOfIndividuals AS PeriodsOfIndividuals
	|		INNER JOIN InformationRegister.FullNameOfPersons AS FullNameOfPersons
	|		ON PeriodsOfIndividuals.Individual = FullNameOfPersons.Individual
	|			AND PeriodsOfIndividuals.Period >= FullNameOfPersons.Period
	|WHERE
	|	FullNameOfPersons.Individual REFS Catalog.Persons
	|
	|GROUP BY
	|	PeriodsOfIndividuals.Individual,
	|	PeriodsOfIndividuals.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FilterForCuttingRecentFullNames.Individual AS Individual,
	|	FilterForCuttingRecentFullNames.Period AS Period,
	|	FullNameOfPersons.LastName AS LastName,
	|	FullNameOfPersons.Name AS Name,
	|	FullNameOfPersons.MiddleName AS MiddleName,
	|	FullNameOfPersons.LastName + CASE
	|		WHEN FullNameOfPersons.Name = """"
	|			THEN """"
	|		ELSE "" "" + FullNameOfPersons.Name
	|	END + CASE
	|		WHEN FullNameOfPersons.LastName = """"
	|			THEN """"
	|		ELSE "" "" + FullNameOfPersons.MiddleName
	|	END AS FullName,
	|	FullNameOfPersons.LastName + CASE
	|		WHEN FullNameOfPersons.Name = """"
	|			THEN """"
	|		ELSE "" "" + SUBSTRING(FullNameOfPersons.Name, 1, 1) + "".""
	|	END + CASE
	|		WHEN FullNameOfPersons.LastName = """"
	|			THEN """"
	|		ELSE "" "" + SUBSTRING(FullNameOfPersons.MiddleName, 1, 1) + "".""
	|	END AS InitialsAndLastName
	|INTO VTFIOOfIndividuals
	|FROM
	|	TTFilterForCutOffOfLastFullName AS FilterForCuttingRecentFullNames
	|		INNER JOIN InformationRegister.FullNameOfPersons AS FullNameOfPersons
	|		ON FilterForCuttingRecentFullNames.Individual = FullNameOfPersons.Individual
	|			AND FilterForCuttingRecentFullNames.SliceDate = FullNameOfPersons.Period
	|WHERE
	|	FullNameOfPersons.Individual REFS Catalog.Persons
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTFilterForCutOffOfLastFullName";
	
	Query.Text = StrReplace(Query.Text, "TTPeriodsOfIndividuals", NameOfIncomingTable);
	Query.Text = StrReplace(Query.Text, "VTFIOOfIndividuals", NameOfOutgoingTable);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#Region OtherInformationAboutIndividuals

// Gets the division of the specified individual.
//
// Parameters:
//  Individual - CatalogRef.Persons - source of information about the division.
//
// Returns:
//  CatalogRef.BusinessStructure - The user's division.
//
Function DivisionOfIndividual(Individual) Export
	
	Department = Catalogs.BusinessStructure.EmptyRef();
	
	If ValueIsFilled(Individual) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED TOP 1
		|	Users.Department AS Department
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.Individual = &Individual
		|	AND Users.DeletionMark = FALSE
		|	AND Users.Invalid = FALSE";
		
		Query.SetParameter("Individual", Individual);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Department = Selection.Department;
		EndIf;
		
	EndIf;
	
	Return Department;
	
EndFunction

// Retrieves data from an individual's document.
// If the document is not found or there are more than one documents, an empty structure is returned.
//
// Parameters:
//  Individual - CatalogRef.Persons - source of information about the document
//  DocumentKind - CatalogRef.DocumentKindsOfPersons - type of document of an individual
//  Date - Date - date to receive a history of documents of a natural person.
//
// Returns:
//  Structure - the data of the document of an individual,
//		the fields correspond to the resources of the register of documentsphysical persons.
//
Function GetIndividualSDefaultDocument(Individual, DocumentKind = Undefined, Date = Undefined) Export
	
	DocumentOfTheIndividual = New Structure;
	DocumentOfTheIndividual.Insert("DocumentKind");
	DocumentOfTheIndividual.Insert("Series", "");
	DocumentOfTheIndividual.Insert("Number", "");
	DocumentOfTheIndividual.Insert("DateOfIssue1", Date(1,1,1));
	DocumentOfTheIndividual.Insert("ValidityPeriod", Date(1,1,1));
	DocumentOfTheIndividual.Insert("IssuedBy", "");
	If GetFunctionalOption("LocalizationRFService") Then
		DocumentOfTheIndividual.Insert("BusinessUnitCode", "");
		DocumentOfTheIndividual.Insert("FTSCode", "");
	EndIf;
	DocumentOfTheIndividual.Insert("ThisIsAnIdentityDocument", False);
	DocumentOfTheIndividual.Insert("Presentation", "");
	
	If ValueIsFilled(Individual) Then
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 2
		|	DocumentsPersons.DocumentKind,
		|	DocumentsPersons.DocumentKind.FTSCode AS FTSCode,
		|	DocumentsPersons.Series,
		|	DocumentsPersons.Number,
		|	DocumentsPersons.DateOfIssue1,
		|	DocumentsPersons.ValidityPeriod,
		|	DocumentsPersons.IssuedBy,
		|	DocumentsPersons.BusinessUnitCode,
		|	DocumentsPersons.ThisIsAnIdentityDocument,
		|	DocumentsPersons.Presentation
		|FROM
		|	InformationRegister.DocumentsPersons.SliceLast(
		|			&Date,
		|			Person = &Individual
		|				AND (DocumentKind = &DocumentKind
		|					OR &DocumentKind = UNDEFINED)) AS DocumentsPersons";
		
		Query.SetParameter("Date", 		    ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
		Query.SetParameter("DocumentKind",   ?(ValueIsFilled(DocumentKind), DocumentKind, Undefined));
		Query.SetParameter("Individual", Individual);
		
		Selection = Query.Execute().Select();
		
		If Selection.Count() = 1 Then
			// If there is only one document in the database, then we will return its data.
			// If there are more than one documents, then we do not return anything because it is not clear which document data is needed.
			Selection.Next();
			FillPropertyValues(DocumentOfTheIndividual, Selection);
			
		EndIf;
		
	EndIf;
	
	PersonsLocalization.FillInDocumentOfIndividualByDefault(Individual, DocumentOfTheIndividual);
	
	Return DocumentOfTheIndividual;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Other

Procedure FillCheckProcessingAtServer(Form, Cancel, CheckedAttributes) Export
	
	IndividualObject = Form.FormAttributeToValue("Object");
	
	If ValueIsFilled(Form.Object.TIN) Then
		PhysicalSample = TinAlreadyAssignedToAnotherIndividual(Form.Object.TIN, Form.Object.Ref);
		If PhysicalSample <> Undefined Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã tìm thấy bản ghi về người có MST như vậy (%1)';
					|ru = 'Найдена запись о человеке, имеющем такой же ИНН (%1)';
					|en = 'Entry about a person with the same TIN (%1) is found'; fa = 'Entry about a person with the same TIN (%1) is found';
					|it = 'Найдена запись о человеке, имеющем такой же ИНН (%1)';
					|pl = 'Entry about a person with the same TIN (%1) is found';
					|tr = 'Aynı VKN (%1) olan bir kişinin kaydı bulundu'"),
				PhysicalSample.Presentation);
			CommonClientServer.MessageToUser(
				MessageText,
				,
				"Object.TIN",
				,
				Cancel);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ListOfConstraints = New ValueList;
	SimilarIndividuals = SimilarIndividuals(IndividualObject.Ref, IndividualObject.Description);
	ListOfConstraints.LoadValues(SimilarIndividuals.UnloadColumn("NameClarification"));
	
	ValueFound = ListOfConstraints.FindByValue(IndividualObject.NameClarification);
	If ValueFound <> Undefined Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Trong danh sách đã có cá nhân với họ tên như vậy %1.
				|Hãy nhập xâu ký tự bổ sung để phân biệt giữa hai người này.';
				|ru = 'В списке уже есть физическое лицо с такими ФИО %1.
				|Введите дополнительную строку по которой вы будете отличать этого человека.';
				|en = 'A person with the %1 full name already exists in the list.
				|Add an extra line by which you will distinguish this person.'; fa = 'A person with the %1 full name already exists in the list.
				|Add an extra line by which you will distinguish this person.';
				|it = 'В списке уже есть физическое лицо с такими ФИО %1.
				|Введите дополнительную строку по которой вы будете отличать этого человека.';
				|pl = 'A person with the %1 full name already exists in the list.
				|Add an extra line by which you will distinguish this person.';
				|tr = 'Listede zaten böyle tam adı %1 olan bir kişi mevcuttur.
				|Bu kişiyi ayırt edecek ek bir satır girin.'"),
			IndividualObject.Description);
		
		If ListOfConstraints.Count() <> 1 Or Not IsBlankString(ListOfConstraints[0].Value) Then
			
			MessageText = MessageText + Chars.LF + Chars.LF
				+ NStr("vi = 'Để nhận dạng, sử dụng các cách bổ sung sau đây: %1';
						|ru = 'Для идентификации уже используются следующие дополнения: %1';
						|en = 'The following additions are already used for identification: %1'; fa = 'The following additions are already used for identification: %1';
						|it = 'Для идентификации уже используются следующие дополнения: %1';
						|pl = 'The following additions are already used for identification: %1';
						|tr = 'Aşağıdaki ekler kimlik için zaten kullanılmaktadır: %1'");
			
			TextOfConstraints = "";
			For Each Refinement In ListOfConstraints Do
				
				If IsBlankString(Refinement.Value) Then
					Continue;
				EndIf;
				
				TextOfConstraints = TextOfConstraints + Chars.LF + " - " + Refinement.Value;
				
			EndDo;
			
			MessageText = StrTemplate(MessageText, TextOfConstraints);
			
		EndIf;
		
		Common.MessageToUser(MessageText, , "Object.NameClarification", , Cancel);
		
	EndIf;
	
EndProcedure

// Determines whether there is an individual with the same TIN in the database.
//
// Parameters:
//  TIN  - String - verified INN
//  ExcludingLink  - CatalogRef.Persons - an individual who is excluded from verification.
//
// Returns:
//   QueryResultSelection, Undefined   - a sample with the data of a found individual with the same TIN
// 		or Indefinite if the desired TIN is not assigned to anyone.
//
Function TinAlreadyAssignedToAnotherIndividual(TIN, ExcludingLink = Undefined)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Persons.Ref,
	|	PRESENTATION(Persons.Description) AS Presentation
	|FROM
	|	Catalog.Persons AS Persons
	|WHERE
	|	Persons.TIN = &TIN
	|	AND Persons.Ref <> &Ref";
	
	Query.SetParameter("TIN",	TIN);
	Query.SetParameter("Ref", ExcludingLink);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function SimilarIndividuals(IndividualRef, IndividualName)
	
	Query = New Query;
	
	Query.Text =
		"SELECT ALLOWED
		|	Persons.Ref AS Ref,
		|	Persons.Description AS Description,
		|	Persons.NameClarification AS NameClarification
		|FROM
		|	Catalog.Persons AS Persons
		|WHERE
		|	Persons.Ref <> &Individual
		|	AND Persons.Description LIKE &FullName ESCAPE ""~""";
	
	Query.SetParameter("Individual", IndividualRef);
	Query.SetParameter("FullName", TrimAll(IndividualName));
	
	TableOfSimilar = Query.Execute().Unload();
	TableOfSimilar.Indexes.Add("Ref");
	
	Return TableOfSimilar;
	
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

#EndRegion
