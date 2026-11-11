#Region Public

// Sets the types of interaction items, such as orders, vacancies, and so on.
// Used if at least one interaction item is defined in the configuration. 
//
// Parameters:
//  SubjectsTypes  - Array - interaction items (String),
//                            for example, " document Link.Customer's order", etc.
//
Procedure OnDeterminePossibleSubjects(SubjectsTypes) Export

	
EndProcedure

// Sets descriptions of possible types of contacts and interactions, for example: partners, contact persons, and so on.
// See InteractionsClientServerOverridable.OnDeterminePossibleContacts
//
Procedure OnDeterminePossibleContacts(ContactsTypes) Export
			
	
EndProcedure

#EndRegion