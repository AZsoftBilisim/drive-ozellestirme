#Region Internal

// Returns a list of tax types for sales and/or purchases that are available in the configuration.
//
// Parameters:
// 	Sales - Boolean - Indicates whether you need to return the types of sales tax
// 	Purchases - Boolean - Indicates whether you need to return the purchase tax types
// 	SeparateAccounting - Boolean - Indication of the need to supplement the types of VAT activities
//
// Returns:
// 	ValueList of EnumRef.VATTaxationTypes
//
Function ApplicableTypesOfVATTaxation(Sales, Purchases, SeparateAccounting) Export
	
	Return VATAccountingERPInternal.ApplicableTypesOfVATTaxation(Sales, Purchases, SeparateAccounting)
	
EndFunction

// Returns the value of the default VAT rate.
//
// Parameters:
// 	Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate.
//  Date - Date - The date on which you need to get the default VAT rate.
//  CalculatedRate - Boolean - indicates the need to get the estimated VAT rate X/(100 + X).
//
// Returns:
//  CatalogRef.VATRates - Value of the VAT rate.
//
Function DefaultVATRate(Organization, Date, CalculatedRate = False) Export
	
	Return VATAccountingERP.DefaultVATRate(Organization, Date, CalculatedRate);
	
EndFunction

// Returns a list of insignificant VAT rates (percentage = 0)
//
// Returns:
//  ValueList of CatalogRef.VATRates - list of VAT rates with an interest rate of 0
//
Function ListOfInsignificantBets() Export
	
	ValueList = New ValueList;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	VATRates.Ref AS Ref,
		|	VATRates.Presentation AS Presentation
		|FROM
		|	Catalog.VATRates AS VATRates
		|WHERE
		|	VATRates.Rate1 = 0";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		ValueList.Add(SelectionDetailRecords.Ref, SelectionDetailRecords.Presentation);
	EndDo;
	
	Return ValueList;
	
EndFunction

// The function returns the VAT percentage.
//
// Parameters:
//	VATRate - CatalogRef.VATRates - Value of the VAT rate.
//
// Returns:
//	Number - VAT percentage.
//
Function ValueOfVATRate(VATRate) Export
	
	If Not ValueIsFilled(VATRate) Then
		Return 0;
	EndIf;

	If TypeOf(VATRate) = Type("CatalogRef.VATRates") Then
		Return Common.ObjectAttributeValue(VATRate, "Rate1");
		
		
	EndIf;
	
EndFunction

// Gets the VAT rate by tax type from the table part of the Stavkinds reference list
// 
// Parameters:
//  VATTaxationType - EnumRef.VATTaxationTypes - Data for searching the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate
//  Date -  Date - The date on which you need to get the VAT rate.
// 
// Returns:
//  CatalogRef.VATRates -
//
Function VATRateByTypeOfTaxation(VATTaxationType, Organization, Date) Export
	
	If VATTaxationType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		Return Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	
	If VATTaxationType = Enums.VATTaxationTypes.VATReverseCharge Then
		Return Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BasicVATRates.VATRate
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &Country) AS BasicVATRates
	|;
	|
	|SELECT DISTINCT
	|	VATRatesTypesOfVATTaxation.Ref AS VATRate,
	|	1 AS Priority
	|FROM
	|	Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
	|WHERE
	|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
	|	AND VATRatesTypesOfVATTaxation.Ref.Country = &Country
	|	AND (VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (ENDOFPERIOD(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod, DAY) >= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1, 1, 1))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VATRatesTypesOfVATTaxation.Ref,
	|	2
	|FROM
	|	Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
	|WHERE
	|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
	|	AND VATRatesTypesOfVATTaxation.Ref.Country = &EmptyCountry
	|	AND (VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (ENDOFPERIOD(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod, DAY) >= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1, 1, 1))
	|
	|ORDER BY
	|	Priority";
	
	Query.SetParameter("VATTaxationType", VATTaxationType);
	Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	Query.SetParameter("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
	
	QueryResults = Query.ExecuteBatch();
	
	If VATTaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		SamplingOfBasicVATRate = QueryResults[0].Select();
		If SamplingOfBasicVATRate.Next() Then
			If ValueIsFilled(SamplingOfBasicVATRate.VATRate) Then
				Return SamplingOfBasicVATRate.VATRate;
			EndIf;
		EndIf;
	EndIf;
	
	SelectionDetailRecords = QueryResults[1].Select();
	
	If SelectionDetailRecords.Count() = 1 Then
		While SelectionDetailRecords.Next() Do
			Return SelectionDetailRecords.VATRate;
		EndDo;
	EndIf;
	
	Return Catalogs.VATRates.EmptyRef();
	
EndFunction

// Returns the settings of the VAT.
//
// Returns:
// 	 Structure - VAT accounting parameters:
// 	   * UseVATAccounting - Boolean, Arbitrary - Value of the option to use VAT accounting
// 	   * BasicTaxationVATSales - EnumRef.VATTaxationTypes - The main taxation of the organization's VAT.
// 	   * MainActivityVATProcurement - EnumRef.VATTaxationTypes - Main activity VAT purchases of goods.
// 	   * SeparateVATAccounting - Boolean, Arbitrary - Indicates whether the IB has organizations that use separate VAT accounting for taxation.
// 	   * UseVATDeclarationSection7Filling - Boolean - Indicates whether Section 7 is used in the Declaration.
// 	   * SalesForExport - Boolean, Arbitrary - Application of export operations.
// 	   * ExportOfNonResourceGoods - Boolean - Indicates that non-primary goods are being exported.
// 	   * ExportOfCommoditiesServicesWorks - Boolean - Indicates that commodities, works, or services are being exported. 
// 	   * ExportSplitDate - Date - Date of application of the Federal law 150-FZ, division of exports into raw and non-raw materials.
// 	   * SellGoodsSubjectToVATAtCustomer - Boolean - Indicates that goods are being sold with reverse VAT. 
// 	                                                       When selling such goods, VAT is charged not by the seller, but by the buyer (tax agent).
// 	   * BuyGoodsSubjectToVATAtCustomer - Boolean - Indicates that goods are being purchased with reverse VAT. 
// 	   * StartDateOfVATAccountingByLineOfBusiness - Date - The date from which incoming VAT is recorded by business line.
// 	   * DateWhenRefundsAreReflectedInCorrectiveSF - Date - The date from which refunds are reflected by the CSF.
// 	   * VATReverseCharge - Boolean, Arbitrary - application of reverse VAT operations
//
Function AccountingSettings() Export
	
	AccountingSettings = New Structure();
	AccountingSettings.Insert("UseVATAccounting", GetFunctionalOption("UseVATAccounting"));
	AccountingSettings.Insert("BasicTaxationVATSales",
		?(GetFunctionalOption("UseVATAccounting"),
			Enums.VATTaxationTypes.SaleIsSubjectToVAT,
			Enums.VATTaxationTypes.SaleIsNotSubjectToVAT));
	AccountingSettings.Insert("MainActivityVATProcurement",
		?(GetFunctionalOption("UseVATAccounting"),
			Enums.VATTaxationTypes.SaleIsSubjectToVAT,
			Enums.VATTaxationTypes.SaleIsNotSubjectToVAT));
	AccountingSettings.Insert("SeparateVATAccounting",                             GetFunctionalOption("UseSeparateAccountingByTaxation"));
	AccountingSettings.Insert("UseVATDeclarationSection7Filling", False);
	AccountingSettings.Insert("SalesForExport",                              GetFunctionalOption("UseSalesForExport"));
	AccountingSettings.Insert("ExportOfNonResourceGoods",                      False);
	AccountingSettings.Insert("ExportOfCommoditiesServicesWorks",                   False);
	AccountingSettings.Insert("ExportSplitDate",                        Date(1,1,1));
	AccountingSettings.Insert("SellGoodsSubjectToVATAtCustomer",        False);
	AccountingSettings.Insert("BuyGoodsSubjectToVATAtCustomer",        False);
	AccountingSettings.Insert("StartDateOfVATAccountingByLineOfBusiness",  Date(1,1,1));
	AccountingSettings.Insert("DateWhenRefundsAreReflectedInCorrectiveSF",     Date(1,1,1));
	AccountingSettings.Insert("VATReverseCharge", GetFunctionalOption("UseVATReverseCharge"));
	
	VATAccountingLocalization.AddAccountingSettings(AccountingSettings);
	
	Return AccountingSettings;
	
EndFunction

// Fills in the list of product line types for the report "Statistical Form for tracking the movement of goods".
//
// Parameters:
//  ChoiceList - ValueList of CatalogRef,String - A list of item types to select.
//
Procedure ListOfTypesOfNomenclatureOfFCSStatform(ChoiceList) Export
	
	
EndProcedure

// The function returns the structure of the requested product parameters for filling in the hand-over
// report regimentedstatistics formaccounting of the movement of goods.
//
// Parameters:
//  Products - CatalogRef.Products,CatalogRef.ProductCrossReferences,CatalogRef.FEACN
//               - CatalogRef.Assets,CatalogRef.LeaseContract - the selected nomenclature for filling out the report.
//
// Returns:
//  - Structure - The significance of the report's indicators is regulated by the statisticsformaccounts of the movement of goods.
Function ProductCharacteristicsForStatisticsReportFormForTrackingMovementOfGoodsByVehicle(Products) Export
	
	TransmittedIndicators = New Structure;
	
	
	Return TransmittedIndicators;
	
EndFunction

#EndRegion
