
#Region Public

// To set restrictions on the user
//
// Parameters:
//  Ref - CatalogRef.Users - user.
// 
// Returns:
//  CatalogRef.SalesSettingsForUsers, Undefined - Setting up user restrictions.
//
Function SettingObjectRestrictions(Ref) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SalesSettingsForUsers.Ref AS Ref
	|FROM
	|	Catalog.SalesSettingsForUsers AS SalesSettingsForUsers
	|WHERE
	|	SalesSettingsForUsers.Owner = &Owner";
	
	Query.SetParameter("Owner", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		Return Selection.Ref;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#EndRegion