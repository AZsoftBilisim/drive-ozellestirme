#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Clears the information register "Document Register" from broken links.
// Returns information about the number of deleted records with broken references in the register.
//
// Parameters:
//	DocumentTypes - Array of Type - the types of documents for which the register is being cleared.
//	PackageSize - Number - limiting the number of metadata object types in a single request package.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* RefsCount - Number - the number of deleted records with broken links.
//
Function ClearNonexistentLinksInDocumentRegistry(DocumentTypes = Undefined, PackageSize = 10) Export
	
	If DocumentTypes = Undefined Then
		DocumentTypes = InformationRegisters.DocumentsRegistry.TypesOfRegistryDocuments();
	EndIf;
	
	Counter = 0;
	TypesToBeProcessed       = New Array;
	NonExistentLinks = New Array;
	For Each DocumentType In DocumentTypes Do
		
		Counter = Counter + 1;
		TypesToBeProcessed.Add(DocumentType);
		
		If TypesToBeProcessed.Count() % PackageSize = 0 Or Counter = DocumentTypes.Count() Then
			QueryText = RequestTextForNonexistentDocumentRegistryLinks(TypesToBeProcessed);
			Query = New Query(QueryText);
			CommonClientServer.SupplementArray(NonExistentLinks,
				Query.Execute().Unload().UnloadColumn("Ref"));
			
			TypesToBeProcessed.Clear();
		EndIf;
		
	EndDo;
	
	For Each Ref In NonExistentLinks Do
		DeleteSetOfRegistryEntries(Ref);
	EndDo;
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("RefsCount", NonExistentLinks.Count());
	
	Return ExecutionResult;
	
EndFunction

// Returns the text of the request that receives information about non-existent links in the information register "Document Register".
//
// Parameters:
//	DocumentTypes - Array of Type - types of documents for which it is necessary to obtain information in the register.
//
// Returns:
//	String - query text.
//
Function RequestTextForNonexistentDocumentRegistryLinks(DocumentTypes) Export
	
	QueryTemplate = 
		"SELECT
		|	DocumentsRegistry.Ref
		|FROM
		|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|WHERE
		|	&RegistryLinkCondition
		|	AND NOT TRUE IN
		|				(SELECT
		|					TRUE
		|				FROM
		|					&DocumentTable AS Document
		|				WHERE
		|					DocumentsRegistry.Ref = Document.Ref)";
	
	UnionTemplate = "
		|
		|UNION ALL
		|
		|";
	
	QueryText = "";
	For Each DocumentType In DocumentTypes Do
		
		MetadataOfDocument = Metadata.FindByType(DocumentType);
		DocumentName        = MetadataOfDocument.Name;
		
		QueryText = QueryText + ?(QueryText = "", "", UnionTemplate)
			+ StrReplace(QueryTemplate, "&RegistryLinkCondition", 
				"DocumentsRegistry.Ref REFS Document." + DocumentName);
		
		QueryText = StrReplace(QueryText, "&DocumentTable", "Document." + DocumentName);
		
	EndDo;
	
	Return QueryText;
	
EndFunction

// Deletes a set of entries in the information register "Document Register" with selection by the transmitted link to the document.
//
// Parameters:
//	DocumentReference - DocumentRef - link to the document in the information database.
//
Procedure DeleteSetOfRegistryEntries(DocumentReference)
	
	RecordSet = InformationRegisters.DocumentsRegistry.CreateRecordSet();
	RecordSet.Filter.Ref.Set(DocumentReference);
	
	RecordSet.DataExchange.Load = True;
	
	// recording a set of records
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf