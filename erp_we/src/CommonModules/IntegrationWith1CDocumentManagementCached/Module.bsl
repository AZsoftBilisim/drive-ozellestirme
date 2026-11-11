////////////////////////////////////////////////////////////////////////////////
// Subsystem "Integration with 1C:Document"
// Module 
////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns an array of types of IC objects for which integration rules are set.
//
// Parameters:
//   ObjectsTypesBefore - String - comma-separated list of types.
//
// Returns:
//   Array of Type
//
Function GetObjectTypesWithIntegrationRules(ObjectsTypesBefore) Export
	
	Result = New Array;
	
	TypesArray = New Array;
	For Each String In StrSplit(ObjectsTypesBefore, ",", False) Do
		TypesArray.Add(TrimAll(String));
	EndDo;
	
	Query = New Query(
		"SELECT DISTINCT
		|	ObjectTypeIS AS TypeAsString
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
		|WHERE
		|	NOT Rules.DeletionMark
		|	AND Rules.ObjectTypeDM IN (&TypesArray)");
	Query.SetParameter("TypesArray", TypesArray);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		// Outdated types in the rules should not lead to broken links.
		Try
			TypeName = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(
				Selection.TypeAsString);
			ObjectType = Type(TypeName);
		Except
			Continue;
		EndTry;
		
		If Not AccessRight("Read", Metadata.FindByType(ObjectType)) Then
			Continue;
		EndIf;
		
		Result.Add(ObjectType);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns True if the term "Correspondents" is used.
//
// Returns:
//   Boolean
//
Function UseTermCorrespondents() Export
	
	Return Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.0.1", True);
	
EndFunction

#EndRegion