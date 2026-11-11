#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function AccessGroupData(AccessGroups) Export
	
	Query = New Query();
	Query.SetParameter("AccessGroups", AccessGroups);
	Query.Text = 
		"SELECT
		|	AccessGroups.Ref AS Ref,
		|	AccessGroups.Description AS Description
		|FROM
		|	Catalog.AccessGroupsOfPersons AS AccessGroups
		|WHERE
		|	AccessGroups.Ref IN (&AccessGroups)";
	Return Query.Execute().Unload();
	
EndFunction

Function UserAccessGroups(User = Undefined) Export
	
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	Query = New Query();
	Query.Text = 
		"SELECT
		|	AccessGroups.Ref AS Ref
		|FROM
		|	Catalog.AccessGroupsOfPersons AS AccessGroups";
	
	QueryResult = Query.Execute();
	
	If Not AccessManagement.ProductiveOption() And User <> Users.AuthorizedUser() Then
		Return QueryResult.Unload().UnloadColumn("Ref");
	EndIf;

	AccessGroups = New Array;

	Selection = QueryResult.Select();
	While Selection.Next() Do
		If AccessManagement.ReadingAllowed(Selection.Ref, User) Then
			AccessGroups.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	Return AccessGroups;
	
EndFunction

#EndRegion

#EndIf