////////////////////////////////////////////////////////////////////////////////
// Expansion of the subsystem "Individuals" for UT and ERP (localization).
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
//  NameOfIndividual - Structure - with properties
//		Last Name-String;
//		Name-String;
//		Patronymic-String.
//  Date - Date, Undefined - date for getting the full name history, it makes sense if the first parameter contains a link.
//
Procedure AddFullName(Individual, NameOfIndividual, Date = Undefined) Export
EndProcedure

// Generates a string containing the last name and initials of an individual.
// The string is formed depending on the type of parameter passed:
//	- either by the history of the full name of the element in the physical Object reference list,
// 	- or by parsing the string containing the full name.
//
// Parameters:
//  Individual - String, CatalogRef.Persons - source of information about full name
//  InitialsAndLastName - String - Surname and. O .
//  Date - Date, Undefined - date for getting the full name history, it makes sense if the first parameter contains a link.
//
Procedure AddSurnameInitialsOfIndividual(Individual, InitialsAndLastName, Date = Undefined) Export
	
EndProcedure

#EndRegion

#Region DocumentsPersons

// Fill in the structure with the data of the document of an individual.
// 
// Parameters:
//  Individual - CatalogRef.Persons - source of information about the document
//  DocumentOfTheIndividual - Structure -- the data of the document of an individual,
// 				the fields correspond to the resources of the register of documentsphysical persons.
//  DocumentKind - CatalogRef.DocumentKindsOfPersons, Undefined - type of document of an individual
//  Date - Date, Undefined - date to receive a history of documents of a natural person.
//
Procedure FillInDocumentOfIndividualByDefault(Individual, DocumentOfTheIndividual, DocumentKind = Undefined, Date = Undefined) Export
	
	
EndProcedure

// Processes the properties of the document view element of the form for processing the printapplication and return of the client's goods.
// 
// Parameters:
//  Form - ClientApplicationForm
Procedure AttributesOfPrintingApplicationForRefundProcessTypeOfDocument(Form) Export
	

EndProcedure

#EndRegion

#EndRegion
