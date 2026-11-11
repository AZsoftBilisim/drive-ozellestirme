
#Region Internal

// Returns the value of the main accounting country
// 
// Returns:
// 	CatalogRef.WorldCountries - 
Function MainCountry() Export
	
	Return Constants.MainCountry.Get();
	
EndFunction

// Returns the country of registration of the organization. If an organization is transferred, it returns the country of the organization.
// If the organization is not transferred or empty, then the main country.
//
// Parameters:
//   Organization - CatalogRef.Companies - 
//
// Returns:
//   CatalogRef.WorldCountries - 
//
Function CountryOfOrganizationRegistration(Val Organization = Undefined) Export
	
	If Not ValueIsFilled(Organization) Then
		Return Constants.MainCountry.Get();
	Else
		RegistrationCountry = Common.ObjectAttributeValue(Organization, "RegistrationCountry");
		If GetFunctionalOption("UseMultiCountryAccounting") Then
			Return RegistrationCountry;
		ElsIf ValueIsFilled(RegistrationCountry) Then
			Return RegistrationCountry;
		Else
			Return Constants.MainCountry.Get();
		EndIf;
	EndIf;
	
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
	
	Return SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
EndFunction

#EndRegion