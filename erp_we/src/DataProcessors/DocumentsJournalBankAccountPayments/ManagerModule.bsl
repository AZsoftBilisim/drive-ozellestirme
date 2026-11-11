#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines related organizations
//
// Parameters:
//    Organization - CatalogRef.Companies - The organization for which a search is made for related organizations
//
// Returns:
//    ValueList - List of related organizations
//
Function RelatedOrganizations(Organization) Export
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed
		|");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	Return CompaniesList;
	
EndFunction

#EndRegion

#EndIf
