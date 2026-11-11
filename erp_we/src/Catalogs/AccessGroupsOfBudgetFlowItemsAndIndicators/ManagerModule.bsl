#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines whether or not the access groups for budget items and indicators are used.
//
//	Returns:
//		Boolean - if TRUE, then access groups are used.
//
Function AccessGroupsAreUsed() Export
	
	Return
		GetFunctionalOption("LimitAccessAtRecordLevel")
		And GetFunctionalOption("UseAccessGroupsOfItemKindsAndBudgetBalanceItems");
	
EndFunction

// This function determines whether the current user has the right to change budget items and indicators.
//
//	Parameters:
//		Object - FormDataCollection, CatalogObject - any collection with fields:
//			*AccessGroup - CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators - object access group.
//			*Ref - CatalogRef - link to a reference book that can be restricted by the access group of budget items and indicators.
//
//	Returns:
//		Boolean - if TRUE, then there is a right to change.
//
Function HasUpdateRight(Object) Export
	
	If Not AccessRight("Update", Metadata.FindByType(TypeOf(Object.Ref))) Then
		Return False;
	ElsIf Not AccessGroupsAreUsed() Then
		Return True;
	ElsIf Users.IsFullUser() Then
		Return True;
	ElsIf Not ValueIsFilled(Object.AccessGroup) Then
		Return False;
	EndIf;
	
	ArrayOfAccessGroups =
		AccessManagement.AccessValuesGroupsAllowingAccessValuesChange(TypeOf(Object.Ref), True);
	
	Return ArrayOfAccessGroups.Find(Object.AccessGroup) <> Undefined;
	
EndFunction

// This function returns the default access group for budget items and indicators for the current user.
//
//	Parameters:
//		Object - FormDataCollection, CatalogObject - any collection with fields:
//			*AccessGroup - CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators - object access group.
//			*Ref - CatalogRef - link to a reference book that can be restricted by the access group of budget items and indicators.
//
//	Returns:
//		CatalogRef.AccessGroupsOfBudgetFlowItemsAndIndicators - default access group.
//
Function GetDefaultAccessGroup(Object) Export
	
	DefaultAccessGroup = Catalogs.AccessGroupsOfBudgetFlowItemsAndIndicators.EmptyRef();
	
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
