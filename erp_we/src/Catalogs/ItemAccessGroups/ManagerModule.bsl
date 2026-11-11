#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines whether or not item access groups are used.
//
//	Returns:
//		Boolean - if TRUE, then access groups are used.
//
Function AccessGroupsAreUsed() Export
	
	Return
		GetFunctionalOption("LimitAccessAtRecordLevel")
		And GetFunctionalOption("UseItemAccessGroups");
	
EndFunction

// This function determines whether the current user has the right to change the item.
//
// Parameters:
//  Object	 - FormDataCollection, CatalogObject	 - any collection with fields:
//  	*AccessGroup - CatalogRef.ItemAccessGroups - object access group
//  	*Ref - CatalogRef - a link to a reference list that can be restricted by the item's access group.
// 
// Returns:
//  Boolean - if TRUE, then there is a right to change.
//
Function HasUpdateRight(Object) Export
	
	If Users.IsFullUser() Then
		Return True;
	ElsIf Not AccessRight("Update", Metadata.FindByType(TypeOf(Object.Ref))) Then
		Return False;
	ElsIf Not AccessGroupsAreUsed() Then
		Return True;
	ElsIf Not ValueIsFilled(Object.AccessGroup) Then
		Return True;
	EndIf;
	
	ArrayOfAccessGroups =
		AccessManagement.AccessValuesGroupsAllowingAccessValuesChange(TypeOf(Object.Ref), True);
	
	Return ArrayOfAccessGroups.Find(Object.AccessGroup) <> Undefined;
	
EndFunction

// The function returns the default item access group for the current user.
//
// Parameters:
//  Object	 - FormDataCollection, CatalogObject	 - any collection with fields:
//  	*AccessGroup - CatalogRef.ItemAccessGroups - object access group
//  	*Ref - CatalogRef - a link to a reference list that can be restricted by the item's access group.
// 
// Returns:
//  CatalogRef.ItemAccessGroups - default access group.
//
Function GetDefaultAccessGroup(Object) Export
	
	DefaultAccessGroup = Catalogs.ItemAccessGroups.EmptyRef();
	
	ArrayOfAccessGroups =
		AccessManagement.AccessValuesGroupsAllowingAccessValuesChange(TypeOf(Object.Ref), True);
	
	If ValueIsFilled(Object.AccessGroup) Then
		If ArrayOfAccessGroups.Find(Object.AccessGroup) <> Undefined Then
			DefaultAccessGroup = Object.AccessGroup;
		EndIf;
	ElsIf ArrayOfAccessGroups.Count() = 1 Then
		DefaultAccessGroup = ArrayOfAccessGroups[0];
	EndIf;
	
	Return DefaultAccessGroup;
	
EndFunction

#EndRegion

#EndIf
