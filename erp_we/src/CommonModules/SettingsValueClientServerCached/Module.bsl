
#Region Public

// Returns the value of the main accounting country
// 
// Returns:
// 	CatalogRef.WorldCountries - 
Function MainCountry() Export
	
	Return ValueOfServerCallSettings.MainCountry();
	
EndFunction

// Returns the country of registration of the organization. If an organization is transferred, it returns the country of registration of the organization.
// If the organization is not transferred, then the main country.
//
// Parameters:
//   Organization - CatalogRef.Companies - The currency to fill in.
//
// Returns:
//   CatalogRef.Currencies - default currency.
//
Function CountryOfOrganizationRegistration(Val Organization = Undefined) Export
	
	Return ValueOfServerCallSettings.CountryOfOrganizationRegistration(Organization);
	
EndFunction

// Returns the regulated accounting currency defined for the organization.
//
// Parameters:
//   Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the currency of regulated accounting.
//
// Returns:
//   CatalogRef.Currencies - 
//
Function CurrencyOfOrganizationSRegulatedAccounting(Val Organization) Export
	
	Return ValueOfServerCallSettings.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
EndFunction

#EndRegion
