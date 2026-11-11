
#Region Public

// Returns the structure of the document details intended for storing information about responsible persons.
// The details of the responsible person of the document must
//	- have the reference Link type.Otvetstvennosti
// 	- contain a selection parameter with the link Enumeration type.Responsible organizations ("type" of responsible).
//
// Parameters:
//  DocumentName - String - name of the document in the configuration metadata.
//
// Returns:
// 	Structure - structure of responsible persons of the document
// 		Key - the name of the document details
// 		The value is the "type" of the responsible person of the document.
//
Function DetailsOfResponsiblePersonsOfDocument(DocumentName) Export
	
	MetadataOfDocument    = Metadata.Documents[DocumentName];
	StructureOfResponsiblePersons = New Structure;
	
	AttributeType 	  = Type("CatalogRef.PersonsResponsibleAndCompanies");
	TypeOfSelectionValue = Type("EnumRef.PersonsResponsibleAndCompanies");
	
	For Each Attribute In MetadataOfDocument.Attributes Do
		
		If Not Attribute.Type.ContainsType(AttributeType)
		 Or StrFind(Lower(Attribute.Name), "delete") = 1 Then
			Continue;
		EndIf;
		
		// We found the details of the responsible person in the document.
		For IndexOf = 0 To Attribute.ChoiceParameters.Count() - 1 Do
			
			SelectionValue = Attribute.ChoiceParameters.Get(IndexOf).Value;
			
			If TypeOf(SelectionValue) = TypeOfSelectionValue Then
				// We found the "type" of the responsible person's props.
				StructureOfResponsiblePersons.Insert(Attribute.Name, SelectionValue);
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return StructureOfResponsiblePersons;
	
EndFunction

// Checks whether the details intended for storing information about responsible persons are present in the document metadata.
//
// Parameters:
//  DocumentName - String - name of the document in the configuration metadata.
//
// Returns:
// 	Boolean - a sign of the presence of details in the metadata of the document.
//
Function ThereAreDetailsOfResponsiblePersonsOfDocument(DocumentName) Export
	
	Return ResponsiblePersonsCached.DetailsOfResponsiblePersonsOfDocument(DocumentName).Count() > 0;
	
EndFunction

#EndRegion
