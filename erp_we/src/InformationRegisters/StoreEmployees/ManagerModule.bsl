#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets employee access to the Dispatching, Assembly, and Delivery sections.
// 
// Parameters:
// 	User - CatalogRef.Users - used to set the request parameter.
// 
// Returns:
//	Structure - Structure of roles and permissions.
//	
Function GetAvailableRoles(User) Export

	RoleStructure = RoleStructure();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ISNULL(MAX(StoreEmployees.Courier), FALSE) AS Courier,
		|	ISNULL(MAX(StoreEmployees.Picker), FALSE) AS Picker,
		|	ISNULL(MAX(StoreEmployees.Dispatcher), FALSE) AS Dispatcher
		|FROM
		|	Catalog.Users AS Users
		|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
		|		ON Users.Individual = StoreEmployees.Employee
		|WHERE
		|	Users.Ref = &User";
	
	Query.SetParameter("User", User);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		RoleStructure.Insert("Dispatcher", Selection.Dispatcher);
		RoleStructure.Insert("Picker",   Selection.Picker);
		RoleStructure.Insert("Courier",    Selection.Courier);
	EndDo;
	
	Return RoleStructure;
	
EndFunction


#EndRegion

#Region Private

Function RoleStructure()

	RoleStructure = New Structure();
	RoleStructure.Insert("Dispatcher", False);
	RoleStructure.Insert("Picker", False);
	RoleStructure.Insert("Courier", False);
	
	Return RoleStructure;
	
EndFunction

#EndRegion

#EndIf
