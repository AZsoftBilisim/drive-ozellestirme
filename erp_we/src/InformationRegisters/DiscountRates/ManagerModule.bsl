#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function gets the current discount rate.
//
// Parameters:
//  Period - Date - The period of the applied settings of the accounting policy of financial accounting .
//  Organization - CatalogRef.Companies - Organization of the contract.
//  Currency - CatalogRef.Currencies - The currency of the mutual settlements of the agreement.
//
// Returns:
//  Number - The default discount rate value.
//
Function GetDefaultDiscountRate(Period, Organization, Currency) Export
	
	If Not ValueIsFilled(Organization) Or Not ValueIsFilled(Currency) Then
		Return 0;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Organization", Common.ObjectAttributeValue(Organization, "ParentCompany"));
	Filter.Insert("Currency", Currency);
	ResourcesStructure = InformationRegisters.DiscountRates.Get(Period, Filter);
	
	Return ResourcesStructure.DiscountRate;
	
EndFunction

// Defines an array of organizations that use discounting or have used it before
//
// Returns:
//  Array of CatalogRef.Companies - Companies 
//
Function GetOrganizationsWithDiscountingEnabled() Export
	
	Result = New Array;
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	Companies.Ref AS Organization
		|FROM
		|	Catalog.Companies AS Companies
		|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS FinancialAccountingPolicy
		|		ON Companies.ParentCompany = FinancialAccountingPolicy.Organization
		|WHERE
		|	FinancialAccountingPolicy.AccountingForDiscountedAccountsPayableToVendors";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Organization);
	EndDo;
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion
	
#EndIf
