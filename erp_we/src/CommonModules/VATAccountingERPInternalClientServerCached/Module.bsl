#Region Internal

// The function returns the VAT percentage.
//
// Parameters:
//	VATRate - CatalogRef.VATRates - Value of the VAT rate.
//
// Returns:
//	Number - VAT percentage.
//
Function ValueOfVATRate(VATRate) Export
	
	Return VATAccountingERPServerCall.ValueOfVATRate(VATRate);
	
EndFunction

// Gets the VAT rate by tax type from the table part of the Stavkinds reference list
// 
// Parameters:
//  VATTaxationType - EnumRef.VATTaxationTypes - Data for searching the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate
//  Date - Date - The date on which you need to get the VAT rate. If Undefined, the bid is returned on the current date.
//  
// Returns:
//  CatalogRef.VATRates - 
//
Function VATRateByTypeOfTaxation(VATTaxationType, Organization, Date = Undefined) Export
	
	Return VATAccountingERPServerCall.VATRateByTypeOfTaxation(VATTaxationType, Organization, Date);
	
EndFunction

// Returns a list of insignificant VAT rates (percentage = 0)
//
// Returns:
//  ValueList of CatalogRef.VATRates - list of VAT rates with an interest rate of 0
//
Function ListOfInsignificantBets() Export
	
	Return VATAccountingERPServerCall.ListOfInsignificantBets();
	
EndFunction

// Returns the settings of the VAT.
//
// Returns:
// 	 Structure: See VATAccountingERPServerCall.AccountingSettings
//
Function AccountingSettings() Export
	
	Return VATAccountingERPServerCall.AccountingSettings();
	
EndFunction

#EndRegion

