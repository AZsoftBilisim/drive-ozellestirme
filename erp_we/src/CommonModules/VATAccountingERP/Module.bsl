#Region Public

#Region GettingVATAccountingSettingsAndParameters

// Returns the settings of the VAT.
//
// Returns:
// 	 Structure: See VATAccountingERPServerCall.AccountingSettings
//
Function AccountingSettings() Export
	
	Return VATAccountingERPInternalClientServerCached.AccountingSettings();
	
EndFunction

// Returns the VAT accounting parameters set for the organization in the specified period.
//
// Parameters:
// 	Organization - CatalogRef.Companies - The organization to get parameters for.
// 	Date - Date - The date on which it is necessary to obtain the sensitivity.
// 	Warehouse - CatalogRef.Warehouses - Optional parameter. The warehouse for which you need to determine the use of UTII.
// 	Department - CatalogRef.BusinessStructure - Optional parameter. The division for which the UTII application should be determined.
//
// Returns:
// 	 Structure - VAT accounting parameters by organization:
// 		* BasicTaxationVATSales - EnumRef.VATTaxationTypes - The main taxation of the organization's VAT.
// 		* MainActivityVATProcurement - EnumRef.VATTaxationTypes - Main activity VAT purchases of goods.
// 		* TaxationOfRetailVAT - EnumRef.VATTaxationTypes - retail VAT taxation. 
// 		                                                                                   The value is obtained taking into account the transferred warehouse.
// 		* SeparateVATAccounting - Boolean - indicates the use of separate VAT accounting.
// 		* SpecialProcedureForVATAccountingInProductionOfDC - Boolean - a sign that the company accounts for VAT related to the production of products with 
// 							a long production cycle in a special way.
// 		* OptionOfVATAccountingWhenChangingTypeOfActivityToNonTaxable - EnumRef.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne 
// 		                    - determines the procedure for VAT accounting when changing an activity to non-taxable.
// 		* ExpenseItem_NotSubjectToVAT - ChartOfCharacteristicTypesRef.ExpenseItems - the article of VAT write-off when the activity is changed to non-taxable VAT.
// 		* ExpenseAnalytics_VATFree - Undefined, Characteristic.ExpenseItems - analytics of VAT write-off when the activity changes to non-taxable VAT.
// 		* ExpenseItem_IsSubjectToUTII - ChartOfCharacteristicTypesRef.ExpenseItems - the article of VAT write-off when changing an activity to a taxable envd.
// 		* CostAnalytics_SubjectToUTII - Undefined, Characteristic.ExpenseItems - analytics of VAT write-off when changing an activity to a taxable envd.
//		* GenerateVATChargedWhenIncludingInCost - Boolean - The sign of the formation of the personal income tax declared when included in the price.
//		* WriteOffVATByExpensesThatAreNotRecordedInTA - Boolean - Indicates that VAT has been deducted for expenses that are not accepted in TA.
//
Function AccountingParametersForOrganization(Val Organization, Val Date, Val Warehouse = Undefined,  Val Department = Undefined) Export
	
	AccountingParameters = New Structure();
	
	BasicTaxationOfInformationSecurity = ?(GetFunctionalOption("UseVATAccounting"),
			Enums.VATTaxationTypes.SaleIsSubjectToVAT,
			Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	
	AccountingParameters.Insert("BasicTaxationVATSales",  BasicTaxationOfInformationSecurity);
	AccountingParameters.Insert("MainActivityVATProcurement",  BasicTaxationOfInformationSecurity);
	AccountingParameters.Insert("TaxationOfRetailVAT", BasicTaxationOfInformationSecurity);
	AccountingParameters.Insert("SeparateVATAccounting", False);
	AccountingParameters.Insert("GenerateVATChargedWhenIncludingInCost", False);
	AccountingParameters.Insert("WriteOffVATByExpensesThatAreNotRecordedInTA", False);
	
	AccountingParameters.Insert("SpecialProcedureForVATAccountingInProductionOfDC", False);
	AccountingParameters.Insert("OptionOfVATAccountingWhenChangingTypeOfActivityToNonTaxable", Enums.VATAccountingOptionsOnChangingActivityTypeToNonTaxableOne.EmptyRef());
	AccountingParameters.Insert("ExpenseItem_NotSubjectToVAT", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	AccountingParameters.Insert("ExpenseAnalytics_VATFree", Undefined);
	AccountingParameters.Insert("ExpenseItem_IsSubjectToUTII", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	AccountingParameters.Insert("CostAnalytics_SubjectToUTII", Undefined);
	
	SliceDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	VATAccountingSettings = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("VATAccountingSettings",
		Organization,
		SliceDate);
	
	If VATAccountingSettings <> Undefined Then
		
		If VATAccountingSettings.VATPayer Then
			AccountingParameters.Insert("BasicTaxationVATSales", Enums.VATTaxationTypes.SaleIsSubjectToVAT);
			AccountingParameters.Insert("MainActivityVATProcurement", Enums.VATTaxationTypes.SaleIsSubjectToVAT);
			AccountingParameters.Insert("TaxationOfRetailVAT", Enums.VATTaxationTypes.SaleIsSubjectToVAT);
		Else
			AccountingParameters.Insert("BasicTaxationVATSales", Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
			AccountingParameters.Insert("MainActivityVATProcurement", Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
			AccountingParameters.Insert("TaxationOfRetailVAT", Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		EndIf;
		
		AccountingParameters.SeparateVATAccounting = VATAccountingSettings.SeparateAccountingOfGoodsByVATTaxation;
		AccountingParameters.GenerateVATChargedWhenIncludingInCost = VATAccountingSettings.GenerateVATChargedWhenIncludingInCost;
		AccountingParameters.WriteOffVATByExpensesThatAreNotRecordedInTA = VATAccountingSettings.WriteOffVATByExpensesThatAreNotRecordedInTA;
		
	EndIf;
	
	VATAccountingLocalization.AddCompanyAccountingParameters(AccountingParameters, Organization, Date, Warehouse, Department);
	
	Return AccountingParameters;
	
EndFunction

// Returns a list of available organizations that have Sales taxed on the Date of the Sale
// 
// Parameters:
//   Period - Date
//
// Returns:
// 	Array of CatalogRef.Companies - Organizations that have a Sales Tax applicable as of the Date.
//
Function OrganizationsWithoutVAT(Val Period) Export
	
	Period = EndOfMonth(Period);
	Query = New Query;
	If GetFunctionalOption("UseVATAccounting") Then 
		
		QueryText = Undefined;
		
		VATAccountingLocalization.AddToListOfOrganizationsWithoutVAT(QueryText);
		
		If QueryText = Undefined Then
		
			QueryText = "SELECT ALLOWED
			|	VATAccountingSettingsSliceLast.Organization AS Organization
			|FROM
			|	InformationRegister.VATAccountingSettings.SliceLast(&Period, NOT VATPayer) AS VATAccountingSettingsSliceLast
			|";
		
		EndIf;
		
		Query.SetParameter("Period", Period);
		
	Else		
		
		QueryText = "SELECT ALLOWED
		|	Companies.Ref AS Organization
		|FROM
		|	Catalog.Companies AS Companies";	
			
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute().Unload();	
	
	Return Result;
	
EndFunction

// Returns a list of tax types for which VAT is never accepted for refund.
//
// Returns:
// 	Array of EnumRef.VATTaxationTypes - Types of VAT activities for which VAT is included in the price.
//
Function ActivitiesVATIsIncludedInCost() Export
	
	Result = New Array();
	Result.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	VATAccountingLocalization.SupplementActivitiesVATIsIncludedInCost(Result);
	
	Return Result;
	
EndFunction

// Returns a list of activities for which VAT is accepted for refund:
// - in full or in part;
// - according to General or special rules.
//
// Returns:
// 	Array of EnumRef.VATTaxationTypes - Types of VAT activities for which VAT is deductible.
//
Function TypesOfActivitiesVATIsAcceptedForReimbursement() Export
	
	Result = New Array();
	Result.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	Result.Add(Enums.VATTaxationTypes.DeterminedByAllocation);
	Result.Add(Enums.VATTaxationTypes.ExportSale);
	VATAccountingLocalization.SupplementActivitiesVATIsAcceptedForReimbursement(Result);
	
	Return Result;
	
EndFunction

// Returns an array of tax types.
// Parameters:
//   ForAdvances - Boolean
// 
// Returns:
// 	Array of EnumRef.VATTaxationTypes - array of tax types
Function TypesOfVATTaxationNonTaxable(ForAdvances = False) Export
	TypesArray = New Array();
	TypesArray.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	VATAccountingLocalization.SupplementTypesOfVATTaxationNonTaxable(TypesArray, ForAdvances);
	
	Return TypesArray;
	
EndFunction

// Returns a list of types of VAT taxation for which VAT is not included in the cost, 
// but is subject to deduction (if the conditions are met).
// 
// Returns:
// 	Array of EnumRef.VATTaxationTypes - array of tax types
//
Function SalesTaxationVATIsNotIncludedInCost() Export
	
	Result = New Array();
	Result.Add(Enums.VATTaxationTypes.SaleIsSubjectToVAT);
	Result.Add(Enums.VATTaxationTypes.ExportSale);
	VATAccountingLocalization.SupplementSalesTaxationVATIsNotIncludedInCost(Result);
	
	Return Result;
	
EndFunction

// Returns an array of tax types that is a combination of two arrays.
// 
// Returns:
// 	Array of EnumRef.VATTaxationTypes - array of tax types
//
Function TypesOfTaxationVATIsNotIncludedInCost() Export
	
	Result = SalesTaxationVATIsNotIncludedInCost();
	CommonClientServer.SupplementArray(Result, TypesOfActivitiesVATIsAcceptedForReimbursement(), True);
	
	Return Result;
	
EndFunction

// Returns an array of VAT tax types that can be types of activities.
// 
// Returns:
// 	Array of EnumRef.VATTaxationTypes - array of tax types
Function VATActivities() Export
	
	TypesOfActivities = VATAccountingERPInternal.ApplicableVATActivities();
	TypesOfActivities.Delete(TypesOfActivities.FindByValue(Enums.VATTaxationTypes.EmptyRef()));
	Return TypesOfActivities.UnloadValues();
	
EndFunction

// Generates a temporary table of VAT accounting settings for counterparties in the temporary table manager.
//
// Parameters:
//	TempTableManager - TempTablesManager - The manager is a temporary table in which the result of receiving settings will be placed.
//	Period - Date - the period for which the settings data is received.
//
Procedure GenerateTTSettingsForAccountingOfVATCounterparties(TempTableManager, Val Period) Export
	
	TextOfRequestToDestroyW = "";
	
	If TempTableManager.Tables.Find("TTSettingsForVATAccountingOfCounterparties") <> Undefined Then
		TextOfRequestToDestroyW =
		"DROP TTSettingsForVATAccountingOfCounterparties;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	EndIf;
	
	QueryTextDefault = TextOfRequestToDestroyW +
	"SELECT
	|	VALUE(Catalog.Counterparties.EmptyRef)				AS Consignor,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS BasicTaxation,
	|	VALUE(Catalog.VATRates.EmptyRef)					AS VATRate
	|INTO TTSettingsForVATAccountingOfCounterparties
	|
	|WHERE
	|	FALSE";
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	If GetFunctionalOption("UseVATAccounting") Then
		QueryTextTT = VATAccountingLocalization.QueryTextTTCounterpartyVATAccountingSettings();
		
		If IsBlankString(QueryTextTT) Then
			QueryText = QueryTextDefault;
		Else
			QueryText = TextOfRequestToDestroyW + QueryTextTT;
			
			Query.SetParameter("Period", EndOfDay(Period));
		EndIf;
	Else
		QueryText = QueryTextDefault;
	EndIf;
	
	Query.Text = QueryText;
	Query.Execute();
	
EndProcedure

// Generates a temporary table of VAT accounting settings for organizations in the temporary tables manager.
//
// Parameters:
//	TempTableManager - TempTablesManager - The manager is a temporary table in which the result of receiving settings will be placed.
//	Period - Date - the period for which the settings data is received.
//	OrganizationsWithoutVAT - Array of CatalogRef.Companies - organizations that do not use VAT accounting.
//	GetAllowed - Boolean - indicates whether settings records are allowed by access rights.
//
Procedure CreateTTSettingsForVATAccountingForOrganizations(TempTableManager, Val Period, OrganizationsWithoutVAT, GetAllowed = False) Export
	
	TextOfRequestToDestroyW = "";
	
	If TempTableManager.Tables.Find("TTVATAccountingSettingsForOrganizations") <> Undefined Then
		TextOfRequestToDestroyW =
		"DROP TTVATAccountingSettingsForOrganizations;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	EndIf;
	
	QueryTextDefault = TextOfRequestToDestroyW +
	"SELECT
	|	VALUE(Catalog.Companies.EmptyRef)				AS Organization,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS BasicTaxation,
	|	VALUE(Catalog.VATRates.EmptyRef)					AS VATRate
	|INTO TTVATAccountingSettingsForOrganizations
	|
	|WHERE
	|	FALSE";
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	If GetFunctionalOption("UseVATAccounting") Then
		QueryTextTT = VATAccountingLocalization.QueryTextTTVATAccountingSettingsOrganizations();
		
		If IsBlankString(QueryTextTT) Then
			QueryText = QueryTextDefault;
		Else
			QueryText = TextOfRequestToDestroyW + QueryTextTT;
			QueryText = ?(Not GetAllowed,
							StrReplace(QueryText, "ALLOWED", ""),
							QueryText);
			
			Query.SetParameter("Period",				EndOfDay(Period));
			Query.SetParameter("OrganizationsWithoutVAT",	OrganizationsWithoutVAT);
		EndIf;
	Else
		QueryText = QueryTextDefault;
	EndIf;
	
	Query.Text = QueryText;
	Query.Execute();
	
EndProcedure

#EndRegion

#Region VATRates

// Returns the VAT rate of the operation for the item and type of VAT taxation.
//
// Parameters:
//   Products - CatalogRef.Products - The item from which you need to get the VAT rate.
//   VATTaxation - EnumRef.VATTaxationTypes - Taxation of VAT operations.
//   Organization - CatalogRef.Companies - Organization of the document
//   Date - Date - Transaction date
//   SpecifiedVATRate - CatalogRef.VATRates
//   OutgoingDocument - Boolean - for taxation Subject to VAT from buyers, for Outgoing documents, the VAT rate does not need to be corrected.
//   
// Returns:
//   CatalogRef.VATRates - VAT rate by nomenclature and type of taxation
//
Function VATRateForProductsAndTaxation(Products, VATTaxation, Organization, Date, SpecifiedVATRate = Undefined, OutgoingDocument = False) Export
	
	VATRate = Undefined;
	
	If ValueIsFilled(Products) And VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		VATRate = ProductItemVATRate(Products, Organization, Date);
	ElsIf VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		VATRate = VATRateByTypeOfTaxation(VATTaxation, Organization, Date);
	EndIf;
	
	Parameters = ParametersForGettingVATRate(Products, VATTaxation, Organization, Date, SpecifiedVATRate, VATRate);
	Parameters.OutgoingDocument = OutgoingDocument;
	
	VATAccountingLocalization.FillInVATRateForProductsAndTaxation(Parameters, VATRate);
	
	Return VATRate;

EndFunction

// Parameters for getting the VAT rate.
// 
// Parameters:
//  Products - CatalogRef.Products 
//  VATTaxation - EnumRef.VATTaxationTypes 
//  Organization - CatalogRef.Companies 
//  Date - Date
//  SpecifiedVATRate - CatalogRef.VATRates, Undefined - the VAT rate of 5% or 7% 
//  VATRate -  CatalogRef.VATRates 
// 
// Returns:
//  Structure:
//  * Products - CatalogRef.Products 
//  * VATTaxation - EnumRef.VATTaxationTypes
//  * Organization - CatalogRef.Companies 
//  * Date - Date 
//  * SpecifiedVATRate - CatalogRef.VATRates, Undefined - The specified VAT rate
//  * VATRate -  CatalogRef.VATRates - VAT rate
//	* OutgoingDocument - Boolean
Function ParametersForGettingVATRate(Products, VATTaxation, Organization, Date, SpecifiedVATRate, VATRate) Export
	
	Parameters = New Structure();
	Parameters.Insert("Products", Products);
	Parameters.Insert("VATTaxation", VATTaxation);
	Parameters.Insert("Organization", Organization);
	Parameters.Insert("Date", Date);
	Parameters.Insert("VATRate", VATRate);
	Parameters.Insert("SpecifiedVATRate", SpecifiedVATRate);
	Parameters.Insert("OutgoingDocument", False);
	
	Return Parameters;
	
EndFunction

// Gets the VAT rate of the item
// 
// Parameters:
//  Products - CatalogRef.Products - The item for which you need to get the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate
//  Date - Date - the date on which you need to get the VAT rate.
//           If the date is empty, the VAT rate for the current date will be received.
// 
// Returns:
//  CatalogRef.VATRates -
//
Function ProductItemVATRate(Products, Organization, Date) Export
	
	ProductsArray = New Array;
	ProductsArray.Add(Products);
	
	VATRates = VATRatesByItemArray(ProductsArray, Organization, Date);
	Return VATRates[Products];
	
EndFunction

// Returns matching VAT rates for an array of items.
//
// Parameters:
//  ProductsArray - Array of CatalogRef.Products - Massive nomenclatures for which you need to get VAT rates.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain VAT rates
//  Date - Date - the date on which you need to get the VAT rates.
//           If the date is empty, the VAT rates for the current date will be received.
//
// Returns:
//  Map of KeyAndValue:
//   * Key - CatalogRef.Products
//   * Value - CatalogRef.VATRates
//
Function VATRatesByItemArray(ProductsArray, Organization, Date) Export
	
	Result = New Map;
	
	If ProductsArray.Count() = 0 Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductsVATRates.Products AS Products,
	|	ProductsVATRates.VATRate AS VATRate
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(
	|			&Date,
	|			Products IN (&OfProductItem)
	|				AND Country = &Country) AS ProductsVATRates
	|WHERE
	|	(ProductsVATRates.VATRate.BeginOfPeriod <= &Date
	|			OR ProductsVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (ProductsVATRates.VATRate.EndOfPeriod >= &Date
	|			OR ProductsVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))
	|;
	|
	|SELECT
	|	ProductsVATRates.Products AS Products,
	|	ProductsVATRates.VATRate AS VATRate
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(
	|			&Date,
	|			Products IN (&OfProductItem)
	|				AND Country = &EmptyCountry) AS ProductsVATRates
	|WHERE
	|	(ProductsVATRates.VATRate.BeginOfPeriod <= &Date
	|			OR ProductsVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (ProductsVATRates.VATRate.EndOfPeriod >= &Date
	|			OR ProductsVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))
	|;
	|
	|SELECT
	|	BasicVATRates.VATRate AS VATRate
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &Country) AS BasicVATRates
	|WHERE
	|	(BasicVATRates.VATRate.BeginOfPeriod <= &Date
	|			OR BasicVATRates.VATRate.BeginOfPeriod = DATETIME(1, 1, 1))
	|		AND (BasicVATRates.VATRate.EndOfPeriod >= &Date
	|			OR BasicVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1))";
	
	RequestDate_ = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	CountryOfOrganization = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	Query.SetParameter("Date", RequestDate_);
	Query.SetParameter("OfProductItem", ProductsArray);
	Query.SetParameter("Country", CountryOfOrganization);
	Query.SetParameter("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
	
	QueryResult = Query.ExecuteBatch();
	
	SamplingWithCountry = QueryResult[0].Select();
	While SamplingWithCountry.Next() Do
		Result.Insert(SamplingWithCountry.Products, SamplingWithCountry.VATRate);
	EndDo;
	
	SampleWithoutCountry = QueryResult[1].Select();
	While SampleWithoutCountry.Next() Do
		If Result.Get(SampleWithoutCountry.Products) = Undefined Then
			Result.Insert(SampleWithoutCountry.Products, SampleWithoutCountry.VATRate);
		EndIf;
	EndDo;
	
	MainVATRate = Catalogs.VATRates.EmptyRef();
	
	SelectionOfMainRates = QueryResult[2].Select();
	If SelectionOfMainRates.Next() Then
		MainVATRate = SelectionOfMainRates.VATRate;
	EndIf;
	
	For Each ItemItemElement In ProductsArray Do
		If Result.Get(ItemItemElement) = Undefined Then
			Result.Insert(ItemItemElement, MainVATRate);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the value of the default VAT rate.
//
// Parameters:
//  Organization - CatalogRef.Companies - The organization for which you need to determine the default bid.
//  Date - Date - the date on which you need to get the default VAT rate
//               . if the date is empty, the VAT rate for the current date will be received.
//  CalculatedRate - Boolean - indicates the need to get the estimated VAT rate X/(100 + X).
//   VATTaxation - EnumRef.VATTaxationTypes - Taxation of VAT, for which you need to get the rate.
//   			If Undetermined, the rate is obtained for taxing the sale of the property.
// Returns:
//  CatalogRef.VATRates - Value of the VAT rate.
//
Function DefaultVATRate(Val Organization, Val Date = Undefined, Val CalculatedRate = False, Val VATTaxation = Undefined) Export
	
	VATRate = Catalogs.VATRates.EmptyRef();
	
	BidDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	
	VATAccountingLocalization.SetDefaultVATRate(VATRate, BidDate, CalculatedRate, VATTaxation, Organization);
	
	If Not ValueIsFilled(VATRate) Then
		VATRate = VATRateByTypeOfTaxation(Enums.VATTaxationTypes.SaleIsSubjectToVAT, Organization, Date);
	EndIf;
	
	Return VATRate;
	
EndFunction

// Returns the value of the VAT rate for the main country of registration.
//
// Parameters:
//  Date - Date - the date on which you need to get the default VAT rate
//               . if the date is empty, the VAT rate for the current date will be received.
// Returns:
//  CatalogRef.VATRates - Value of the VAT rate.
//
Function VATRateOfMainCountry(Val Date = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BasicVATRates.VATRate AS VATRate
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &Country) AS BasicVATRates
	|";
	Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	Query.SetParameter("Country", SettingsValueClientServerCached.MainCountry());
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.VATRates.EmptyRef();
	EndIf;
		
	Selection = QueryResult.Select();
	If Selection.Next() Then
		Return Selection.VATRate;
	EndIf;
	
EndFunction

// Determines whether the rate is insignificant (Percentage = 0)
//
// Parameters:
//  VATRate - CatalogRef.VATRates - Value of the VAT rate.
//
// Returns:
//  Boolean -
//
Function InsignificantRate(VATRate) Export
	
	ListOfBetsWithNumerator0 = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	
	IncludedInListOfInsignificantBets = Not ListOfBetsWithNumerator0.FindByValue(VATRate) = Undefined;
	
	Return IncludedInListOfInsignificantBets;
	
EndFunction

// Sets the value of the request parameters: 
// * StavkaNDSBezNDS
// * stavkandspoumolchaniyu
// * Stavkandsnaexport
// * Date
// * Country
// of registration based on the relevant types of taxation.
// 
// Parameters:
//  QueryOptions - Structure - Parameters of the data acquisition request in which parameters need to be set.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain VAT rates
//  Date - Date - The date on which the VAT rates should be received.
//
Procedure SetParametersForVATRateRequest(QueryOptions, Organization, Date) Export
	
	If Not QueryOptions.Property("VATRateWithoutVAT") Then
		QueryOptions.Insert("VATRateWithoutVAT", Catalogs.VATRates.EXCLUDINGVAT);
	EndIf;
	
	If Not QueryOptions.Property("DefaultVATRate") Then
		DefaultVATRate = DefaultVATRate(Organization, Date);
		QueryOptions.Insert("DefaultVATRate", DefaultVATRate);
	EndIf;
	
	If Not QueryOptions.Property("ExportVATRate") Then
		ExportVATRate = VATRateByTypeOfTaxation(
			Enums.VATTaxationTypes.ExportSale, Organization, Date);
		QueryOptions.Insert("ExportVATRate", ExportVATRate);
	EndIf;
	
	If Not QueryOptions.Property("Date") Then
		QueryOptions.Insert("Date", Date);
	EndIf;
	
	If Not QueryOptions.Property("RegistrationCountry") Then
		QueryOptions.Insert("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	EndIf;
	
EndProcedure

// Returns a fragment of the request to get the VAT rate based on the type of taxation.
// When using this text in the request, you must set the parameters (See VATAccountingERP.SetParametersForVATRateRequest)
// .
// 
// Parameters:
//  ExpressionVATTaxation - String - Expression for receiving tax in the request.
//  ExpressionProducts - String, Undefined - Expression for getting the item in the request. 
//                                                 If filled in, the VAT Rate for the sales tax type is levied From the item.
//                                                 If Undefined, the default VAT rate is used for the sales tax type.
//  ExpressionReturnsMultiTurnContainer - String, Undefined - Expression for the return of a multi-turn container.
//                                                                 If the container is returned, the rate "Without VAT" is used.
//                                                                 Otherwise, the VAT rate is determined according to the General rules.
//
// Returns:
// 	String - A fragment of the request text
//
Function QueryTextVATRate(ExpressionVATTaxation, ExpressionProducts = Undefined, ExpressionReturnsMultiTurnContainer = Undefined) Export
	
	If ExpressionProducts <> Undefined Then
		
		QueryText =
		"CASE
		|	WHEN &ExpressionReturnsMultiTurnContainer
		|			AND &ExpressionProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|		THEN &VATRateWithoutVAT
		|	WHEN &ExpressionVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|		THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))
		|	WHEN &ExpressionVATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
		|		THEN &ExportVATRate
		|	ELSE &VATRateWithoutVAT
		|END";
		
		VATAccountingLocalization.CompleteQueryTextVATRate(QueryText,ExpressionProducts);
		QueryText = StrReplace(QueryText, "&ExpressionVATTaxation", ExpressionVATTaxation);
		QueryText = StrReplace(QueryText, "&ExpressionProducts", ExpressionProducts);
		
		If ExpressionReturnsMultiTurnContainer <> Undefined Then
			QueryText = StrReplace(QueryText, "&ExpressionReturnsMultiTurnContainer", ExpressionReturnsMultiTurnContainer);
		Else
			QueryText = StrReplace(QueryText, "&ExpressionReturnsMultiTurnContainer", "FALSE");
		EndIf;
		
	Else
		
		QueryText =
		"CASE
		|	WHEN &ExpressionVATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|		THEN &DefaultVATRate
		|	WHEN &ExpressionVATTaxation = VALUE(Enum.VATTaxationTypes.ExportSale)
		|		THEN &ExportVATRate
		|		ELSE &VATRateWithoutVAT
		|END";
		
		VATAccountingLocalization.CompleteQueryTextVATRate(QueryText,ExpressionProducts);
		QueryText = StrReplace(QueryText, "&ExpressionVATTaxation", ExpressionVATTaxation);
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Fills in the VAT rate for payments by tax type
// 
// Parameters:
//  VATRate - CatalogRef.VATRates - Current value of the VAT rate.
//  VATTaxationType - EnumRef.VATTaxationTypes - Tax rate to search for the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to fill in the VAT rate
//  Date - CatalogRef.Companies - The date on which the VAT rate must be filled in
//
Procedure FillInVATRateForPayments_(VATRate, Val VATTaxationType, Organization, Date) Export
	
	If Not VATRateIsCorrect(VATRate, VATTaxationType, Organization, Date) Then
		
		NewVATRate = DefaultVATRate(Organization, Date);
		
		If ValueIsFilled(VATTaxationType) Then
			VATRateForTaxation = VATRateByTypeOfTaxation(VATTaxationType, Organization, Date);
			If ValueIsFilled(VATRateForTaxation) Then
				NewVATRate = VATRateForTaxation;
			EndIf;
		EndIf;

		VATAccountingLocalization.FillInVATRateForPayments(NewVATRate, VATTaxationType, Organization, Date);

		If ValueIsFilled(NewVATRate) Then
			VATRate = NewVATRate;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the data for selecting the VAT rate
//
// Parameters:
// 	 ChoiceData - ValueList of CatalogRef.VATRates - Selection data
// 	 Parameters - Structure - The selection parameters:
// 	 	* Filter - Structure - Contains:
// 	 		** Ref - EnumRef.VATTaxationTypes - 
// 	 StandardProcessing - Boolean - flag for standard event processing
//
Procedure GetDataForSelectingVATRate(ChoiceData, Parameters, StandardProcessing) Export 
	
	StandardProcessing = False;
	
	Query = New Query();
	QueryText = 
	"SELECT DISTINCT
	|	VATRatesTypesOfVATTaxation.Ref AS Ref,
	|	PRESENTATION(VATRatesTypesOfVATTaxation.Ref) AS Presentation
	|FROM
	|	Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
	|WHERE
	|	NOT VATRatesTypesOfVATTaxation.Ref.DeletionMark
	|	AND (VATRatesTypesOfVATTaxation.Ref.Country = &Country 
	|		OR VATRatesTypesOfVATTaxation.Ref.Country = VALUE(Catalog.WorldCountries.EmptyRef))
	|	AND &SelectionByDate_1
	|	AND &SelectionByTypeOfTaxation
	|	AND &SelectionByParameters
	|	AND &FilterByCalculatedRate
	|";
	
	Country = Undefined;
	If Parameters.Property("Organization") Then
		Country = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Parameters.Organization);
	ElsIf Parameters.Property("Country") Then
		Country = Parameters.Country;
	EndIf;
	If Not ValueIsFilled(Country) Then
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	Query.SetParameter("Country", Country);
	
	WithoutFilterByDate = False;
	SelectionOfCurrentOnesInPeriod = False;
	If Parameters.Property("WithoutFilterByDate") Then
		WithoutFilterByDate = Parameters.WithoutFilterByDate;
	EndIf;
	If Parameters.Property("BeginOfPeriod") And Parameters.Property("EndOfPeriod") Then
		SelectionOfCurrentOnesInPeriod = True;
	EndIf; 
	Date = CurrentSessionDate();
	If Parameters.Property("Date") And ValueIsFilled(Parameters.Date) Then
		Date = Parameters.Date;
	EndIf;
	
	WithoutFilterByDate = True;
	If WithoutFilterByDate Then
		QueryText = StrReplace(QueryText, "&SelectionByDate_1", "TRUE");
	ElsIf SelectionOfCurrentOnesInPeriod Then
		SelectionTextByDate = "";
		If ValueIsFilled(Parameters.BeginOfPeriod) Then
			SelectionTextByDate = "(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod >= &BeginOfPeriod
			|	OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1,1,1))";
			Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
		EndIf;
		If ValueIsFilled(Parameters.EndOfPeriod) Then
			SelectionTextByDate = SelectionTextByDate
				+ ?(SelectionTextByDate = "", "", " And ")
				+ "(VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &EndOfPeriod
				|	OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1,1,1))";
			Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
		EndIf;
		If SelectionTextByDate = "" Then
			SelectionTextByDate = "TRUE";
		EndIf;
		QueryText = StrReplace(QueryText, "&SelectionByDate_1", SelectionTextByDate);
	Else
		SelectionTextByDate = "(VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &DATE
							|		OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1,1,1))
							|	AND (ENDOFPERIOD(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod, DAY) >= &DATE
							|		OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1,1,1))";
		QueryText = StrReplace(QueryText, "&SelectionByDate_1", SelectionTextByDate);
		Query.SetParameter("Date", Date);
	EndIf;
	
	VATTaxation = Undefined;
	If Parameters.Property("VATTaxation", VATTaxation) Then
		If Not ValueIsFilled(VATTaxation) Then
			VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
		EndIf;
		QueryText = StrReplace(QueryText, "&SelectionByTypeOfTaxation", "VATRatesTypesOfVATTaxation.VATTaxationType IN(&TypesOfTaxation)");
		Query.SetParameter("TypesOfTaxation", VATTaxation);
	Else
		QueryText = StrReplace(QueryText, "&SelectionByTypeOfTaxation", "TRUE");
	EndIf;
	
	If Parameters.Filter.Property("Ref") Then
		QueryText = StrReplace(QueryText, "&SelectionByParameters", "VATRatesTypesOfVATTaxation.Ref IN (&FilterByReference_)");
		Query.SetParameter("FilterByReference_", Parameters.Filter.Ref);
	Else
		QueryText = StrReplace(QueryText, "&SelectionByParameters", "TRUE");
	EndIf;
	
	If Parameters.Property("ExcludeFractionalBets") And Parameters.ExcludeFractionalBets Then
		QueryText = StrReplace(QueryText, "&FilterByCalculatedRate", "VATRatesTypesOfVATTaxation.Ref.CalculatedRate = FALSE"); 
	ElsIf Parameters.Property("FractionalRatesOnly") And Parameters.FractionalRatesOnly Then
		QueryText = StrReplace(QueryText, "&FilterByCalculatedRate", "VATRatesTypesOfVATTaxation.Ref.CalculatedRate = TRUE");
	Else
		QueryText = StrReplace(QueryText, "&FilterByCalculatedRate", "TRUE");
	EndIf; 
	
	ChoiceData = New ValueList;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If Not ValueIsFilled(Parameters.SearchString)
			Or StrFind(Lower(Selection.Presentation), Lower(Parameters.SearchString)) = 1 Then
			ChoiceData.Add(Selection.Ref, Selection.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

// Gets the VAT rate by tax type from the table part of the Stavkinds reference list
// 
// Parameters:
//  VATTaxationType - EnumRef.VATTaxationTypes - Data for searching the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate
//  Date - Date - The date on which you need to get the VAT rate.
//
// Returns:
//  CatalogRef.VATRates -
//
Function VATRateByTypeOfTaxation(VATTaxationType, Organization, Date) Export
	
	Return VATAccountingERPInternalClientServerCached.VATRateByTypeOfTaxation(VATTaxationType, Organization, Date);
	
EndFunction

// Checks the VAT rate by type of taxation, organization and date
// 
// Parameters:
//  VATRate - CatalogRef.VATRates - The VAT rate being checked.
//  VATTaxationType - EnumRef.VATTaxationTypes - Data for searching the VAT rate.
//  Organization - CatalogRef.Companies - The organization for which it is necessary to obtain the VAT rate
//  Date -  Date - The date on which you need to get the VAT rate.
// 
// Returns:
//  Boolean
//
Function VATRateIsCorrect(VATRate, Val VATTaxationType, Organization, Date) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	VATRatesTypesOfVATTaxation.Ref AS VATRate
	|FROM
	|	Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
	|WHERE
	|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
	|	AND (VATRatesTypesOfVATTaxation.Ref.Country = &Country
	|			OR VATRatesTypesOfVATTaxation.Ref.Country = &EmptyCountry)
	|	AND (VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1, 1, 1))
	|	AND (ENDOFPERIOD(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod, DAY) >= &Date
	|			OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1, 1, 1))
	|	AND VATRatesTypesOfVATTaxation.Ref = &VATRate";
	
	Query.SetParameter("VATRate", VATRate);
	Query.SetParameter("VATTaxationType", VATTaxationType);
	Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	Query.SetParameter("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Returns the VAT rate for the Cur row of the table part being processed in batch processing mechanisms for rows
// of table parts. 
//
// Parameters:
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//   
// Returns:
//   CatalogRef.VATRates - The VAT rate for the item in the current line of the table part.
//
Function ItemVATRateInBatches(CachedValues) Export
	
	// see VAT accounting StavkaNDSNomenclature
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing("VATRateByItemList", CachedValues); 
	If Not DataForProcessing = Undefined 
		And DataForProcessing.Count() Then
			DataForProcessing.Sort("Priority");
			
			ResultOfReceivingVATRate = DataForProcessing[0];
			If ResultOfReceivingVATRate <> Undefined Then
				Return DataForProcessing[0].VATRate;
			Else
				Catalogs.VATRates.EmptyRef();
			EndIf;
		EndIf;
		
	Return Catalogs.VATRates.EmptyRef();
	
EndFunction

// Returns the VAT rate of operations by item and type of VAT taxation. It is used when processing rows of table
// parts.
// 
// Parameters:
//   Products - CatalogRef.Products, Undefined - The item from which you need to get the VAT rate.
//   VATTaxation - EnumRef.VATTaxationTypes - Taxation of VAT operations.
//   Date - Date - Used to get the VAT rate for an organization on a specific date
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//   SpecifiedVATRate - CatalogRef.VATRates
//   
// Returns:
//   CatalogRef.VATRates - The VAT rate according to the nomenclature in the current row of the table part and the type of taxation.
//
Function VATRateByItemAndTaxationInBatches(Products, VATTaxation, Date, CachedValues, SpecifiedVATRate = Undefined) Export
	
	VATRate = Undefined;
	CompanyForVATRate = Undefined;
	
	If ValueIsFilled(Products) And VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		VATRate = ItemVATRateInBatches(CachedValues);
	ElsIf VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		VATRate = VATRateByTypeOfTaxationInBatches(VATTaxation, CachedValues);
	EndIf;
	
	CachedValues.Property("CompanyForVATRate", CompanyForVATRate);
	If CompanyForVATRate = Undefined Then
		CompanyForVATRate = Catalogs.Companies.EmptyRef();
	EndIf;
	
	Parameters = ParametersForGettingVATRate(Products, VATTaxation, CompanyForVATRate, Date, SpecifiedVATRate, VATRate);
	Parameters.OutgoingDocument = CachedValues.OutgoingDocument;
	
	VATAccountingLocalization.FillInVATRateByItemAndTaxationInBatch(Parameters, CachedValues, VATRate);
	
	Return VATRate;

EndFunction

// Gets the VAT rate by tax type from the table part of the Stavkinds reference list
// 
// Parameters:
//  VATTaxationType - EnumRef.VATTaxationTypes - Data for searching the VAT rate.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
// Returns:
//  CatalogRef.VATRates - Value of the VAT rate.
//
Function VATRateByTypeOfTaxationInBatches(VATTaxationType, CachedValues) Export
	
	If VATTaxationType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		Return Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	
	If VATTaxationType = Enums.VATTaxationTypes.VATReverseCharge Then
		Return Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	
	If VATTaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		BasicBidsByDate = BatchProcessingOfTablePartServer.DataForStringProcessing(
			"BasicBidsByDate", CachedValues);
			
		If BasicBidsByDate <> Undefined Then
			For Each MainVATRate In BasicBidsByDate Do
				If ValueIsFilled(MainVATRate.VATRate) Then
					Return MainVATRate.VATRate;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If ValueIsFilled(VATTaxationType)
		And ValueIsFilled(CachedValues.DataForProcessing)
		And CachedValues.DataForProcessing.Property("VATRateByTypeOfTaxationAsOfDate") Then
		
		VATRateByTypeOfTaxationAsOfDate = 
			BatchProcessingOfTablePartServer.DataForStringProcessing(
				"VATRateByTypeOfTaxationAsOfDate", CachedValues);
		
		If VATRateByTypeOfTaxationAsOfDate <> Undefined Then
			VATRatePriority3 = VATRateByTypeOfTaxationAsOfDate.FindRows(New Structure("Priority", 3));
			
			If VATRateByTypeOfTaxationAsOfDate.Count() - VATRatePriority3.Count() = 1 Then
				Return VATRateByTypeOfTaxationAsOfDate[0].VATRate;
			EndIf;
		EndIf;
		
	EndIf;
	
	Return Catalogs.VATRates.EmptyRef();
	
EndFunction

// Returns the value of the default VAT rate.
//
// Parameters:
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  CalculatedRate - Boolean - indicates the need to get the estimated VAT rate X/(100 + X).
//   VATTaxation - EnumRef.VATTaxationTypes - Taxation of VAT, for which you need to get the rate.
//   			If Undetermined, the rate is obtained for taxing the sale of the property.
// Returns:
//  CatalogRef.VATRates - Value of the VAT rate.
//
Function DefaultVATRateInBatches(CachedValues, Val CalculatedRate = False, Val VATTaxation = Undefined) Export
	
	VATRate = Catalogs.VATRates.EmptyRef();
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(
		"VATRateByTypeOfTaxationAsOfDate", CachedValues); 
	If Not DataForProcessing = Undefined 
		And DataForProcessing.Count() Then
		DateFromResult 	= DataForProcessing[0].DateBidWasReceived;
		BidDate 			= ?(ValueIsFilled(DateFromResult), DateFromResult, CurrentSessionDate());;
	Else
		BidDate 			= CurrentSessionDate();
	EndIf;
	
	VATAccountingLocalization.SetDefaultVATRate(VATRate, BidDate, CalculatedRate, VATTaxation, CachedValues.CompanyForVATRate);
	
	If Not ValueIsFilled(VATRate) Then
		VATRate = VATRateByTypeOfTaxationInBatches(Enums.VATTaxationTypes.SaleIsSubjectToVAT,
			CachedValues);
	EndIf;
	
	Return VATRate;
	
EndFunction

// Returns the VAT rate by price type for the current processed row of the table part in batch processing mechanisms for rows
// of table parts. 
//
// Parameters:
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//   
// Returns:
//   Undefined - no data found.
//   Structure - the row data structure by price type.
//
Function VATRateByPriceTypeInBatches(CachedValues) Export
	
	StructureOfData = Undefined;
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing("VATRatesByPriceTypesOfNomenclature", CachedValues); 
	If	Not DataForProcessing = Undefined 
			And DataForProcessing.Count() Then
		StructureOfData = Common.ValueTableRowToStructure(DataForProcessing[0]);
	EndIf;
		
	Return StructureOfData;
	
EndFunction

// Returns the VAT rate for the Committee setting for the current processed row of the table part
// in batch processing mechanisms for rows of table parts. 
//
// Parameters:
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//   
// Returns:
//   Undefined - no data found.
//   Structure - the data structure of the line for setting up the committee.
//
Function SoftwareVATRateForSettingUpVATAccountingForCommitteesInBatches(CachedValues) Export
	
	StructureOfData = Undefined;
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing("VATRatesForSettingUpVATAccountingForCommitteeSUSN", CachedValues); 
	If	Not DataForProcessing = Undefined 
			And DataForProcessing.Count() Then
		StructureOfData = Common.ValueTableRowToStructure(DataForProcessing[0]);
	EndIf;
		
	Return StructureOfData;
	
EndFunction

// Sets the VAT rate in the specified column of the current row if the value differs from the one transmitted.
//
// Parameters:
//   CurrentRow - ValueTableRow - The line where the VAT rate is set
//   VATRate - String - The set value of the VAT rate
//   NameOfVATRateColumn - String - Name of the column to set the VAT rate for
//   CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInVATRateOfCurrentLineInBatches(CurrentRow, VATRate, NameOfVATRateColumn, CachedValues) Export

	If CurrentRow[NameOfVATRateColumn] <> VATRate Then
		
		CurrentRow[NameOfVATRateColumn] = VATRate;
		
		ProcessedRows = CachedValues.ProcessedRows; //Array
		ProcessedRows.Add(CurrentRow);
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the Bidcands field based on
// item data when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextVATRateForItemList(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	ToReturnReusablePackage = False;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInVATRate, FillInVATRateSuffix, AdjustVATRate,
			|FillInVATRateByPriceType, FillInVATRateSuffixByPriceType, FillInVATRateForSettingUpAccountingAtCommitteeSUSN",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then

		If StructureOfActionParameters.Property("BusinessOperation") Then
			BusinessOperation = StructureOfActionParameters.BusinessOperation;
		Else 
			BusinessOperation = Enums.BusinessTransactions.EmptyRef();
		EndIf;

		If StructureOfActions.Property("AdjustVATRate") Then
			
			StructureOfActionParameters.Property("ToReturnReusablePackage", ToReturnReusablePackage);
			If ToReturnReusablePackage 
				And Not BatchProcessingOfTablePartServer.ThereIsColumnInDataSource
					("ItemsType", CachedValues) Then
						QueryText =
							"SELECT
							|	Goods.IdOfTTRow AS IdOfTTRow,
							|	CatalogProducts.ItemsType AS ItemsType
							|FROM
							|	TTDataSource AS Goods
							|		LEFT JOIN Catalog.Products AS CatalogProducts
							|		ON CatalogProducts.Ref = Goods.Products";
						
						QueryDetails.QueriesTexts.Add(QueryText, "ItemTypes_Packaging");
			EndIf;
		EndIf;
		
		VATTaxationType = StructureOfActionParameters.VATTaxation;
			
		If Not SalesServer.BusinessTransactionWithRateWithoutVAT(BusinessOperation)
			Or VATTaxationType = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
			
			BatchProcessingOfTablePartServer.AddDataSourceColumns(
				QueryDetails,
				"DateBidWasReceived",
				New TypeDescription("Date", , ,New DateQualifiers(DateFractions.Date)));
				
			Date = StructureOfActionParameters.Date;
			WHtaxation = StructureOfActionParameters.Property("VATTaxationAtTabularPart")
				And StructureOfActionParameters.VATTaxationAtTabularPart;
				
			QueryDetails.QueryOptions.Insert("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
			QueryDetails.QueryOptions.Insert("Country",
				SettingsValueClientServerCached.CountryOfOrganizationRegistration(StructureOfActionParameters.Organization));
			
			QueryDetails.QueryOptions.Insert("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
			QueryDetails.QueryOptions.Insert("EmptyVATRate", Catalogs.VATRates.EmptyRef());
			QueryDetails.QueryOptions.Insert("CurrentSessionDate", CurrentSessionDate());
				
			// VAT rate by item
			If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Products", CachedValues) Then
				
				QueryText 	= 
				"SELECT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.VATRate AS VATRate,
				|	&VATTaxationType AS VATTaxation,
				|	Goods.Products AS Products,
				|	Goods.DateBidWasReceived
				|INTO DateOfReceiptOfVATRateByItemTT
				|FROM
				|	TTDataSource AS Goods
				|";
				
				If WHtaxation Then
					QueryText = StrReplace(QueryText, "&VATTaxationType", "Goods.VATTaxation"); //@Query-part-2
				Else
					QueryDetails.QueryOptions.Insert("VATTaxationType", VATTaxationType);
				EndIf;
				
				QueryDetails.QueriesTexts.Add(QueryText, "DateOfReceiptOfVATRateByItemTT");
				
				QueryText 	= "SELECT DISTINCT
				|	Goods.Products AS Products,
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.DateBidWasReceived AS DateBidWasReceived,
				|	MAX(ProductsVATRates.Period) AS Period
				|INTO VATRateTTDates
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|		LEFT JOIN InformationRegister.ProductsVATRates AS ProductsVATRates
				|		ON Goods.Products = ProductsVATRates.Products
				|		AND ProductsVATRates.Country = &Country
				|WHERE
				|	Goods.DateBidWasReceived >= ProductsVATRates.Period
				|
				|GROUP BY
				|	Goods.Products,
				|	Goods.IdOfTTRow,
				|	Goods.DateBidWasReceived
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "VATRateTTDates");
				
				QueryText 	= "SELECT DISTINCT
				|	Goods.Products AS Products,
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.DateBidWasReceived AS DateBidWasReceived,
				|	MAX(BasicVATRates.Period) AS Period
				|INTO TTDatesMainVATRates
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
				|		ON (BasicVATRates.Country = &Country)
				|WHERE
				|	Goods.DateBidWasReceived >= BasicVATRates.Period
				|
				|GROUP BY
				|	Goods.Products,
				|	Goods.IdOfTTRow,
				|	Goods.DateBidWasReceived
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "TTDatesMainVATRates");
				
				QueryText = "SELECT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.Products AS Products,
				|	1 AS Priority,
				|	ProductsVATRates.VATRate AS VATRate
				|FROM
				|	VATRateTTDates AS Goods
				|		LEFT JOIN InformationRegister.ProductsVATRates AS ProductsVATRates
				|		ON (ProductsVATRates.Products = Goods.Products)
				|			AND (ProductsVATRates.Period = Goods.Period)
				|			AND (ProductsVATRates.Country = &Country)
				|		LEFT JOIN Catalog.VATRates AS VATRates
				|		ON (ProductsVATRates.VATRate = VATRates.Ref)
				|WHERE
				|	(VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|			OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|	AND (VATRates.EndOfPeriod >= Goods.DateBidWasReceived
				|			OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|
				|UNION ALL
				|
				|SELECT
				|	Goods.IdOfTTRow,
				|	Goods.Products,
				|	2,
				|	ProductsVATRates.VATRate
				|FROM
				|	VATRateTTDates AS Goods
				|		LEFT JOIN InformationRegister.ProductsVATRates AS ProductsVATRates
				|		ON (ProductsVATRates.Products = Goods.Products)
				|			AND (ProductsVATRates.Period = Goods.Period)
				|			AND (ProductsVATRates.Country = &EmptyCountry)
				|		LEFT JOIN Catalog.VATRates AS VATRates
				|		ON (ProductsVATRates.VATRate = VATRates.Ref)
				|WHERE
				|	(VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|			OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|	AND (VATRates.EndOfPeriod >= Goods.DateBidWasReceived
				|			OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|
				|UNION ALL
				|
				|SELECT
				|	Goods.IdOfTTRow,
				|	Goods.Products,
				|	3,
				|	BasicVATRates.VATRate
				|FROM
				|	TTDatesMainVATRates AS Goods
				|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
				|		ON (BasicVATRates.Period = Goods.Period)
				|			AND (BasicVATRates.Country = &Country)
				|		LEFT JOIN Catalog.VATRates AS VATRates
				|		ON (BasicVATRates.VATRate = VATRates.Ref)
				|WHERE
				|	(VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|			OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|	AND (VATRates.EndOfPeriod >= Goods.DateBidWasReceived
				|			OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|
				|UNION ALL
				|
				|SELECT
				|	Goods.IdOfTTRow,
				|	Goods.Products,
				|	4,
				|	VALUE(Catalog.VATRates.EmptyRef)
				|FROM
				|	TTDataSource AS Goods
				|
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "VATRateByItemList");
				
				VATAccountingLocalization.CompleteQueryTextVATRateForItemList(StructureOfActions, QueryDetails);
				
			Else
				
				WHtaxation = StructureOfActionParameters.VATTaxationAtTabularPart;
				QueryText =
				"SELECT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.VATRate AS VATRate,
				|	&VATTaxationType AS VATTaxation,
				|	Goods.DateBidWasReceived AS DateBidWasReceived
				|INTO DateOfReceiptOfVATRateByItemTT
				|FROM
				|	TTDataSource AS Goods
				|";
				
				If WHtaxation Then
					QueryText = StrReplace(QueryText, "&VATTaxationType", "Goods.VATTaxation") //@Query-part-2
				Else
					QueryDetails.QueryOptions.Insert("VATTaxationType", VATTaxationType);
				EndIf;
				
				QueryDetails.QueriesTexts.Add(QueryText, "DateOfReceiptOfVATRateByItemTT");
				
				QueryText 	= "SELECT DISTINCT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.DateBidWasReceived AS DateBidWasReceived,
				|	MAX(BasicVATRates.Period) AS Period
				|INTO TTDatesMainVATRates
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
				|		ON (BasicVATRates.Country = &Country)
				|WHERE
				|	Goods.DateBidWasReceived >= BasicVATRates.Period
				|
				|GROUP BY
				|	Goods.IdOfTTRow,
				|	Goods.DateBidWasReceived
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "TTDatesMainVATRates");
				
				QueryText = "
				|SELECT
				|	Goods.IdOfTTRow,
				|	1 AS Priority,
				|	BasicVATRates.VATRate
				|FROM
				|	TTDatesMainVATRates AS Goods
				|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
				|		ON BasicVATRates.Period = Goods.Period
				|			AND BasicVATRates.Country = &Country
				|		LEFT JOIN Catalog.VATRates AS VATRates
				|			ON BasicVATRates.VATRate = VATRates.Ref
				|				AND (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|					OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|				AND (VATRates.EndOfPeriod >= Goods.DateBidWasReceived
				|					OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))";
				
				QueryDetails.QueriesTexts.Add(QueryText, "VATRateByItemList");
			
			EndIf;
			
			// VAT rate by type of Taxation
			
			If Not (VATTaxationType = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
				Or VATTaxationType = Enums.VATTaxationTypes.VATReverseCharge)
				Or WHtaxation Then
				
				QueryText = "
				|////////////////////////////////////////////////////////////////////////////////
				|//Getting the basic VAT rate by date for each line
				|SELECT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	BasicVATRates.VATRate AS VATRate
				|FROM
				|	TTDatesMainVATRates AS Goods
				|		LEFT JOIN InformationRegister.BasicVATRates AS BasicVATRates
				|		ON (BasicVATRates.Period = Goods.Period)
				|			AND (BasicVATRates.Country = &Country)
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "BasicBidsByDate");
				
				QueryText = "//getting the VAT rate by type of taxation on the date
				|SELECT DISTINCT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	Goods.DateBidWasReceived AS DateBidWasReceived,
				|	ISNULL(VATRatesTypesOfVATTaxation.Ref, &EmptyVATRate) AS VATRate,
				|	1 AS Priority
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|	LEFT JOIN Catalog.VATRates AS VATRates
				|		ON (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|				OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|			AND (ENDOFPERIOD(VATRates.EndOfPeriod, DAY) >= Goods.DateBidWasReceived
				|				OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|	LEFT JOIN Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation	
				|		ON VATRatesTypesOfVATTaxation.Ref = VATRates.Ref
				|WHERE
				|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
				|	AND VATRates.Country = &Country
				|	AND (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|			OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|	AND (ENDOFPERIOD(VATRates.EndOfPeriod, DAY) >= Goods.DateBidWasReceived
				|			OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|
				|UNION ALL
				|
				|SELECT DISTINCT
				|	Goods.IdOfTTRow,
				|	Goods.DateBidWasReceived,
				|	ISNULL(VATRatesTypesOfVATTaxation.Ref, &EmptyVATRate) AS VATRate,
				|	2
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|	LEFT JOIN Catalog.VATRates AS VATRates
				|		ON (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|				OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|			AND (ENDOFPERIOD(VATRates.EndOfPeriod, DAY) >= Goods.DateBidWasReceived
				|				OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|	LEFT JOIN Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation	
				|		ON VATRatesTypesOfVATTaxation.Ref = VATRates.Ref
				|WHERE
				|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
				|	AND VATRates.Country = &EmptyCountry
				|	AND (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|			OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|	AND (ENDOFPERIOD(VATRates.EndOfPeriod, DAY) >= Goods.DateBidWasReceived
				|			OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|
				|UNION ALL
				|
				|SELECT DISTINCT
				|	Goods.IdOfTTRow,
				|	Goods.DateBidWasReceived,
				|	&EmptyVATRate AS VATRate,
				|	3
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|
				|ORDER BY
				|	Priority";
				
				If WHtaxation Then
					QueryText = StrReplace(QueryText, "&VATTaxationType", "Goods.VATTaxation") //@Query-part-2
				Else
					QueryDetails.QueryOptions.Insert("VATTaxationType", VATTaxationType);
				EndIf;
				
				QueryDetails.QueriesTexts.Add(QueryText, "VATRateByTypeOfTaxationAsOfDate");
				
			EndIf;
			
			// Relevance of the VAT rate by date and type of taxation
			
			QueryText = "
				|SELECT DISTINCT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	CASE
				|		WHEN VATRatesTypesOfVATTaxation.Ref IS NULL
				|			THEN FALSE
				|		ELSE TRUE
				|	END AS Relevant_
				|FROM
				|	DateOfReceiptOfVATRateByItemTT AS Goods
				|	LEFT JOIN Catalog.VATRates AS VATRates
				|		ON Goods.VATRate = VATRates.Ref
				|			AND (VATRates.BeginOfPeriod <= Goods.DateBidWasReceived
				|				OR VATRates.BeginOfPeriod = DATETIME(1, 1, 1))
				|			AND (ENDOFPERIOD(VATRates.EndOfPeriod, DAY) >= Goods.DateBidWasReceived
				|				OR VATRates.EndOfPeriod = DATETIME(1, 1, 1))
				|	LEFT JOIN Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
				|		ON VATRatesTypesOfVATTaxation.Ref = VATRates.Ref
				|		AND VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
				|";
				
			If WHtaxation Then
				QueryText = StrReplace(QueryText, "&VATTaxationType", "Goods.VATTaxation") //@Query-part-2
			Else
				QueryDetails.QueryOptions.Insert("VATTaxationType", VATTaxationType);
			EndIf;
			
			QueryDetails.QueriesTexts.Add(QueryText, "RelevanceOfVATRate");
			
		Else
				
			QueryText = "
				|SELECT DISTINCT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	CASE
				|		WHEN Goods.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
				|			THEN TRUE
				|		ELSE FALSE
				|	END AS Relevant_
				|FROM
				|	TTDataSource AS Goods
				|";
				
				QueryDetails.QueriesTexts.Add(QueryText, "RelevanceOfVATRate");
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds a request to a batch of requests to get the data needed to calculate the amount including VAT during batch processing 
// of rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextRateAtVATRate(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	Var VATRate;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateVATAmount",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
			
			If StructureOfActionParameters <> Undefined 
				And StructureOfActionParameters.Property("VATRate", VATRate) Then
					
					QueryText =
					"SELECT
					|	Goods.IdOfTTRow AS IdOfTTRow,
					|	ISNULL(VATRates.Rate1, 0) AS Rate1
					|FROM
					|	TTDataSource AS Goods
					|	LEFT JOIN Catalog.VATRates AS VATRates
					|	ON &VATRateConversionParameters = VATRates.Ref
					|";
					
					QueryDetails.QueriesTexts.Add(QueryText, "VATRateByRate");
					QueryDetails.QueryOptions.Insert("VATRateConversionParameters",
						VATRate);
					
			Else
				
				QueryText =
				"SELECT
				|	Goods.IdOfTTRow AS IdOfTTRow,
				|	ISNULL(VATRates.Rate1, 0) AS Rate1
				|FROM
				|	TTDataSource AS Goods
				|	LEFT JOIN Catalog.VATRates AS VATRates
				|	ON Goods.VATRate = VATRates.Ref
				|";
				
			EndIf;
			
		QueryDetails.QueriesTexts.Add(QueryText, "VATRateByRate");
			
	EndIf;
	
EndProcedure

// Adds a request to a batch of requests to get the data needed to calculate the amount including VAT during batch processing 
// of rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddSuffixToQueryTextVATRate(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	Var VATRate;

	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateVATAmountSuffix",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
			
			If StructureOfActionParameters <> Undefined 
				And StructureOfActionParameters.Property("VATRate", VATRate) 
				And ValueIsFilled(VATRate) Then
					
					QueryText =
					"SELECT
					|	Goods.IdOfTTRow AS IdOfTTRow,
					|	ISNULL(VATRates.Rate1, 0) AS Rate1
					|FROM
					|	TTDataSource AS Goods
					|	LEFT JOIN Catalog.VATRates AS VATRates
					|	ON &VATRateConversionParameters = VATRates.Ref
					|";
					
					QueryDetails.QueriesTexts.Add(QueryText, "VATRateByRate");
					QueryDetails.QueryOptions.Insert("VATRateConversionParameters",
						VATRate);
					
			Else
				
			EndIf;
				
		QueryText =
		"SELECT
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	ISNULL(VATRates.Rate1, 0) AS Rate1
		|FROM
		|	TTDataSource AS DataSource
		|	LEFT JOIN Catalog.VATRates AS VATRates
		|	ON DataSource.VATRate = VATRates.Ref
		|";
		
		Suffix = "";
		
		If StructureOfActionParameters.Property("Suffix", Suffix)
			And Not ValueIsFilled(Suffix) Then
			Suffix = "";
		EndIf;
		
		RateWithSuffix = BatchProcessingOfTablePartClientServer.RateWithSuffix(Suffix);
		
		QueryText = StrReplace(QueryText, "DataSource.VATRate", "DataSource." + RateWithSuffix.VATRate);
		
		QueryDetails.QueriesTexts.Add(QueryText, "VATRateSuffix");
			
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the Bidcands field based on data
// from the selected Price Type and the data register "Item Prices 2.5" when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextVATRateByPriceType(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	YouNeedToPerformFollowingActions = BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInVATRateByPriceType,FillInVATRateSuffixByPriceType",
		StructureOfActions,
		CachedValues,
		StructureOfActionParameters);
	
	If YouNeedToPerformFollowingActions Then
	
		If StructureOfActionParameters.UsePriceManagementSystem25 Then
			
			If Not BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("PriceKind", CachedValues) Then
				
				StructureOfActionParameters.FillInPriceView = True;
				
				BatchProcessingOfTablePartServer.AddDataSourceColumns(
					QueryDetails,
					"PriceKind",
					New TypeDescription("CatalogRef.TypesOfPrices"));
					
			EndIf;
			
			If Not BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Series", CachedValues) Then
				BatchProcessingOfTablePartServer.AddDataSourceColumns(
					QueryDetails,
					"Series",
					New TypeDescription("CatalogRef.ItemsBatches"));
			EndIf;
			
			If Not BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues) Then
				BatchProcessingOfTablePartServer.AddDataSourceColumns(
					QueryDetails,
					"Package",
					New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			EndIf;
			
			Date = StructureOfActionParameters.Date;
			QueryDetails.QueryOptions.Insert("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
			
			TaxationOfVATExports = VATAccountingERPInternal.TaxationOfVATSalesForExport();
			ExportSale = ValueIsFilled(TaxationOfVATExports.Find(StructureOfActionParameters.VATTaxation));
			QueryDetails.QueryOptions.Insert("ExportSale", ExportSale);
			
			QueryText =
			"SELECT
			|	GoodsTable.IdOfTTRow AS IdOfTTRow,
			|	GoodsTable.PriceKind AS PriceKind,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Package AS Package
			|INTO GoodsTable
			|FROM
			|	TTDataSource AS GoodsTable
			|";
				
			QueryDetails.QueriesTexts.Add(QueryText, "GoodsTable");
				
			QueryText =
			"SELECT
			|	GoodsTable.IdOfTTRow AS IdOfTTRow,
			|	GoodsTable.PriceKind AS PriceKind,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN ProductsTable.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse)
			|				AND GoodsTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			THEN FALSE
			|		ELSE TRUE
			|	END AS CharacteristicFilledIn,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Package AS Package,
			|	ISNULL(CASE
			|		WHEN TableOfProductTypes.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
			|		ELSE CharacteristicTable.ItemsCharacteristicForPricing
			|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
			|	ISNULL(CASE
			|		WHEN TableOfProductTypes.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
			|		ELSE TableOfSeries.ItemsBatchForPricing
			|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
			|	CASE
			|		WHEN TableOfProductTypes.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
			|				OR (TableOfProductTypes.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.Use)
			|					AND PackingTableEI.Owner = VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure))
			|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|		ELSE GoodsTable.Package
			|	END AS PricingPackage,
			|	ISNULL(CASE
			|		WHEN TableTypesOfPrices.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.EmptyRef)
			|			THEN VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates)
			|		ELSE TableTypesOfPrices.OptionForSpecifyingVATRates
			|	END, VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.NotSpecifiedVATRates)) AS OptionForSpecifyingVATRates,
			|	TableTypesOfPrices.VATRate AS PriceTypeVATRate,
			|	TableTypesOfPrices.Country AS Country
			|INTO FilterTable
			|FROM
			|	GoodsTable AS GoodsTable
			|LEFT JOIN
			|	Catalog.Products AS ProductsTable
			|ON
			|	GoodsTable.Products = ProductsTable.Ref
			|LEFT JOIN
			|	Catalog.ItemsCharacteristics AS CharacteristicTable
			|ON
			|	GoodsTable.Characteristic = CharacteristicTable.Ref
			|LEFT JOIN
			|	Catalog.ItemsBatches AS TableOfSeries
			|ON
			|	GoodsTable.Series = TableOfSeries.Ref
			|LEFT JOIN
			|	Catalog.ItemKinds AS TableOfProductTypes
			|ON
			|	ProductsTable.ProductKind = TableOfProductTypes.Ref
			|LEFT JOIN
			|	Catalog.TypesOfPrices AS TableTypesOfPrices
			|ON
			|	GoodsTable.PriceKind = TableTypesOfPrices.Ref
			|LEFT JOIN
			|	Catalog.PackagesAndUnitsOfMeasure AS PackingTableEI
			|ON
			|	GoodsTable.Package = PackingTableEI.Ref
			|INDEX BY
			|	Products,
			|	PricingVariant,
			|	PricingBatch,
			|	PricingPackage,
			|	PriceKind
			|";
		
			QueryDetails.QueriesTexts.Add(QueryText, "FilterTable");
			
			QueryText =
			"SELECT
			|	Price_Table.Products AS Products,
			|	Price_Table.PricingVariant AS PricingVariant,
			|	Price_Table.PricingBatch AS PricingBatch,
			|	Price_Table.PricingPackage AS PricingPackage,
			|	Price_Table.PriceKind AS PriceKind,
			|	Price_Table.Package AS Package,
			|	Price_Table.Currency AS Currency,
			|	Price_Table.VATRate AS VATRate
			|INTO ItemPricesCrossSectionOfTheLatest
			|FROM
			|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY),
			|		(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
			|			(SELECT
			|				FilterTable.Products,
			|				FilterTable.PricingVariant,
			|				FilterTable.PricingBatch,
			|				FilterTable.PricingPackage,
			|				FilterTable.PriceKind
			|			FROM
			|				FilterTable AS FilterTable)
			|	) AS Price_Table
			|INDEX BY
			|	Products,
			|	PricingVariant,
			|	PricingBatch,
			|	PricingPackage,
			|	PriceKind";
	
			QueryDetails.QueriesTexts.Add(QueryText, "ItemPricesCrossSectionOfTheLatest");
			
			QueryText =
			"SELECT
			|	FilterTable.IdOfTTRow AS IdOfTTRow,
			|	FilterTable.PriceKind AS PriceKind,
			|	FilterTable.Products AS Products,
			|	FilterTable.Characteristic AS Characteristic,
			|	FilterTable.CharacteristicFilledIn AS CharacteristicFilledIn,
			|	FilterTable.Series AS Series,
			|	FilterTable.OptionForSpecifyingVATRates AS OptionForSpecifyingVATRates,
			|	CASE
			|		WHEN FilterTable.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifyVATRateForAllItems)
			|				OR FilterTable.OptionForSpecifyingVATRates = VALUE(Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS SpecifyVATRate,
			|	FilterTable.PriceTypeVATRate AS PriceTypeVATRate,
			|	FilterTable.Country AS Country,
			|	ISNULL(Price_Table.VATRate, VALUE(Catalog.VATRates.EmptyRef)) AS VATRate,
			|	ISNULL(VATRateTable.Rate1, 99999) AS RateValue,
			|	CASE
			|		WHEN VATRateTable.Rate1 IS NOT NULL
			|				AND ((&ExportSale AND VATRateTable.Rate1 <> 0)
			|				OR (NOT &ExportSale AND VATRateTable.Rate1 = 0))
			|			THEN TRUE
			|		ELSE 
			|			FALSE
			|	END ExportSalesError
			|FROM
			|	FilterTable AS FilterTable
			|LEFT JOIN
			|	ItemPricesCrossSectionOfTheLatest AS Price_Table
			|ON
			|	FilterTable.Products = Price_Table.Products
			|	AND FilterTable.PricingVariant = Price_Table.PricingVariant
			|	AND FilterTable.PricingBatch = Price_Table.PricingBatch
			|	AND FilterTable.PricingPackage = Price_Table.PricingPackage
			|	AND FilterTable.PriceKind = Price_Table.PriceKind
			|LEFT JOIN
			|	Catalog.VATRates AS VATRateTable
			|ON
			|	Price_Table.VATRate = VATRateTable.Ref
			|";
			
			QueryDetails.QueriesTexts.Add(QueryText, "VATRatesByPriceTypesOfNomenclature");
			
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the column of the date of receipt of the statement in the intermediate table formed on the basis of the processed rows of the tabular
// part in the mechanisms of batch processing of rows of tabular parts. 
//
// Parameters:
//  ProcessedCollection - See BatchProcessingOfTablePartServer.ProcessTSStrings.RowsCollection
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInDateOfBidReceiptColumn(ProcessedCollection, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInVATRate, FillInVATRateSuffix, AdjustVATRate,
			|FillInVATRateByPriceType, FillInVATRateSuffixByPriceType, FillInVATRateForSettingUpAccountingAtCommitteeSUSN",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
		
		If StructureOfActionParameters.Property("ByCorrectionDate")
			And StructureOfActionParameters.ByCorrectionDate Then
			StructureOfActionParameters.Date = Common.ObjectAttributeValue(StructureOfActionParameters.CorrectedDocument, "Date");
		EndIf;
		
		Date = ?(ValueIsFilled(StructureOfActionParameters.Date), StructureOfActionParameters.Date, CurrentSessionDate());
		
		UseReceiptDate = StructureOfActionParameters.Property("ByDateOfReceipt") 
			And StructureOfActionParameters.ByDateOfReceipt
			And BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("DocumentInflow", CachedValues);
		
		If UseReceiptDate Then
			ArrayOfReceipts = New Array();
			For Each Page1 In ProcessedCollection Do
				If ValueIsFilled(Page1.DocumentInflow) Then
					ArrayOfReceipts.Add(Page1.DocumentInflow);
				EndIf;
			EndDo;
			DatesOfReceipt = Common.ObjectsAttributesValues(ArrayOfReceipts, "Date"); 
		EndIf;
		
		UseDateOfShipment = StructureOfActionParameters.Property("ByShipmentDate") 
			And StructureOfActionParameters.ByShipmentDate
			And BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("DateOfShipment", CachedValues);
			
		UseImplementationDate = StructureOfActionParameters.Property("ByImplementationDate") 
			And StructureOfActionParameters.ByImplementationDate
			And BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("DocumentSalesOfGoodsAndServices", CachedValues);
		
		If UseImplementationDate Then
			ArrayOfImplementations = New Array();
			For Each Page1 In ProcessedCollection Do
				If ValueIsFilled(Page1.DocumentSalesOfGoodsAndServices) Then
					ArrayOfImplementations.Add(Page1.DocumentSalesOfGoodsAndServices);
				EndIf;
			EndDo;
			DatesOfImplementation = Common.ObjectsAttributesValues(ArrayOfImplementations, "Date"); 
		EndIf;
			
		If StructureOfActionParameters.Property("BusinessOperation") Then
			BusinessOperation = StructureOfActionParameters.BusinessOperation;
		Else 
			BusinessOperation = Enums.BusinessTransactions.EmptyRef();
		EndIf;
			
		If Not SalesServer.BusinessTransactionWithRateWithoutVAT(BusinessOperation)
			Or StructureOfActionParameters.VATTaxation
				= Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
					For Each CollectionRow In ProcessedCollection Do
						If UseDateOfShipment And ValueIsFilled(CollectionRow.DateOfShipment) Then
							CollectionRow.DateBidWasReceived = CollectionRow.DateOfShipment;
						ElsIf UseImplementationDate And ValueIsFilled(CollectionRow.DocumentSalesOfGoodsAndServices) Then
							CollectionRow.DateBidWasReceived = DatesOfImplementation[CollectionRow.DocumentSalesOfGoodsAndServices].Date;
						ElsIf UseReceiptDate And ValueIsFilled(CollectionRow.DocumentInflow) Then
							CollectionRow.DateBidWasReceived = DatesOfReceipt[CollectionRow.DocumentInflow].Date;
						Else
							CollectionRow.DateBidWasReceived = Date;
						EndIf;
					EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills for shapes "Formattocharacteriterator" Wydany column in the staging table
// formed on the basis of rows the table in the mechanisms of batch lines table parts. 
//
// Parameters:
//  ProcessedCollection - See BatchProcessingOfTablePartServer.ProcessTSStrings.RowsCollection
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInPriceTypeColumn(ProcessedCollection, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	Var ToUseTermsOfSales;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInVATRateByPriceType,FillInVATRateSuffixByPriceType",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
		
		If StructureOfActionParameters.FillInPriceView Then
			
			PriceKind = StructureOfActionParameters.PriceKind;
			If Not ValueIsFilled(PriceKind) Then
				
				CachedValues.Property("ToUseTermsOfSales", ToUseTermsOfSales);
				
				If ToUseTermsOfSales = Undefined  Then
					ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
					CachedValues.Insert("ToUseTermsOfSales", ToUseTermsOfSales);
				EndIf;
			
				CapAttributes = Undefined;
				If ValueIsFilled(StructureOfActionParameters.Partner) Then
					CapAttributes = StructureOfActionParameters.Partner;
				EndIf;
			
				If ValueIsFilled(StructureOfActionParameters.Terms) And ToUseTermsOfSales Then
					CapAttributes = StructureOfActionParameters.Terms;
				EndIf;
			
				If ValueIsFilled(CapAttributes) Then
				
					StructureOfData = Common.ObjectAttributesValues(CapAttributes, "SpecialPriceType, PricesKind");
					PriceKind = StructureOfData.PricesKind;
					If ValueIsFilled(StructureOfData.SpecialPriceType) Then
						PriceKind = StructureOfData.SpecialPriceType;
					EndIf;
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(PriceKind) Then
				For Each CollectionRow In ProcessedCollection Do
					CollectionRow.PriceKind = PriceKind;
				EndDo;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

// Procedure - To set the visibility of the Command to fill in the VAT rate
//
// Parameters:
//  Form				 - ClientApplicationForm - Form with the VAT rate Command.
//  TagName	 - String - The name of the Form Command. By default, "Products fill in the stock".
//
Procedure SetVisibilityOfCommandAndFillInVATRate(Form, TagName = "GoodsFillInVATRate") Export

	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		TagName,
		"Visible",
		ValueIsFilled(Form.Object.VATTaxation)
			And Form.Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);

EndProcedure

// Procedure - replaces the VAT rate in Catalogs
// Parameters:
//  DataGetParameters - Structure - See DataProcessors.ReplaceVATRates.DataGetParameters()
//
Procedure ReplaceVATRate(DataGetParameters) Export
	
	Query = New Query;
	Query.SetParameter("CurRate_", DataGetParameters.CurRate_);
	Query.SetParameter("Period",        DataGetParameters.Period);
	Query.SetParameter("Country",        DataGetParameters.Country);
	Query.SetParameter("DateEmpty",    Date(1,1,1));
	
	QueryTextArray = New Array;
	ChangeBidInItem = False;
		
	For Each Catalog In DataGetParameters.ListOfReferenceBooks Do
		
		If Catalog.Value = "Products" Then
			
			ChangeBidInItem = True;
			
		Else
			
			WithSelectionByPeriod = Catalog.Value <> "ItemKinds";
			QueryTextForCatalogs = QueryTextObjectsToReplace(WithSelectionByPeriod);
			QueryTextForCatalogs = StrReplace(QueryTextForCatalogs, "CounterpartyContracts", Catalog.Value);
			QueryTextArray.Add(QueryTextForCatalogs); 
			
		EndIf;
		
	EndDo;
	
	If QueryTextArray.Count() Then
		
		QueryText = StrConcat(QueryTextArray, TMCommonUse.QuerySeparatorInJoin());
		Query.Text = QueryText;
		Catalog = Query.Execute().Select();
		
		While Catalog.Next() Do
			
			If Not ValueIsFilled(Catalog.Ref) Then
				Continue;
			EndIf;
			
			BeginTransaction();
			
			Try
				
				CatalogObject = Catalog.Ref.GetObject();
				LockItem = Catalog.Ref.Metadata().FullName();
				BlockAndRecordCatalog(CatalogObject, DataGetParameters.NewBid, DataGetParameters.CurRate_, LockItem);
				CommitTransaction();
				
			Except
			
				RollbackTransaction();
				
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
	If ChangeBidInItem Then
		
		Query.Text = 
		"SELECT
		|	ProductsVATRatesSliceLast.Products AS Ref
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &Country) AS ProductsVATRatesSliceLast
		|WHERE
		|	ProductsVATRatesSliceLast.VATRate = &CurRate_
		|";
		
		RegisterRecord = Query.Execute().Select();
		
		While RegisterRecord.Next() Do
			
			If Not ValueIsFilled(RegisterRecord.Ref) Then
				Continue;
			EndIf;
			
			BeginTransaction();
			
			Try
				
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.ProductsVATRates");
				LockItem.SetValue("Country", DataGetParameters.Country);
				LockItem.SetValue("Products", RegisterRecord.Ref);
				Block.Lock();
				
				RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
				RecordSet.Filter.Period.Set(BegOfMonth(DataGetParameters.Period));
				RecordSet.Filter.Products.Set(RegisterRecord.Ref);
				RecordSet.Filter.Country.Set(DataGetParameters.Country);
				
				NewRecord = RecordSet.Add();
				NewRecord.Period       = BegOfMonth(DataGetParameters.Period);
				NewRecord.Products = RegisterRecord.Ref;
				NewRecord.Country       = DataGetParameters.Country;
				NewRecord.VATRate    = DataGetParameters.NewBid;
				
				RecordSet.AdditionalProperties.Insert("SkipUpdatingProductSVATRate");
				RecordSet.Write();
				
				CatalogObject = RegisterRecord.Ref.GetObject();
				BlockAndRecordCatalog(CatalogObject, DataGetParameters.NewBid, DataGetParameters.CurRate_, "Catalog.Products");
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), RegisterRecord.Ref);
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AccountingForIncomingVAT

#Region FillingInVATTaxationForPurchases

// Checks the compliance of the document specified in the purchase document for VAT Taxation with the operation. 
// If the passed value is not filled in or incorrect, 
// it is filled in with the value from the purchase agreement or the default value.
//
// Parameters:
// 	VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the purchase document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases.
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInVATTaxationPurchases(VATTaxation, FillParameters, CachedParameterValues = Undefined) Export
	
	CachedParameterValuesAreNotFilled = (CachedParameterValues = Undefined);
	
	ChangedParameters = VATAccountingERPInternal.ChangedParameters("ParametersForFillingInVATTaxationPurchases", FillParameters, CachedParameterValues);
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInVATTaxationPurchases", FillParameters, CachedParameterValues);

	OnlyIfEmptyOrIncorrect = True;
	If ChangedParameters.Property("Contract")
		Or (CachedParameterValuesAreNotFilled And ValueIsFilled(FillParameters.Contract)) Then
		OnlyIfEmptyOrIncorrect = False;
	EndIf;
	
	If FillParameters.VMIProcurement Then
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		Return;
	EndIf;
	
	ArrayOfAvailable = VATAccountingERPInternal.VATFreePurchases(FillParameters);
	
	If OnlyIfEmptyOrIncorrect Then
		If ValueIsFilled(VATTaxation) 
		     And ArrayOfAvailable.Find(VATTaxation) <> Undefined Then
		    Return;
		EndIf;
	EndIf;
	
	If ValueIsFilled(FillParameters.Contract) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	CounterpartyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Contract
		|	AND NOT CounterpartyContracts.VATTaxationIsDeterminedInDocuments
		|
		|UNION ALL
		|
		|SELECT
		|	IntercompanyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.IntercompanyContracts AS IntercompanyContracts
		|WHERE
		|	IntercompanyContracts.Ref = &Contract
		|	AND NOT IntercompanyContracts.VATTaxationIsDeterminedInDocuments
		|
		|UNION ALL
		|
		|SELECT
		|	LeaseContract.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.LeaseContract AS LeaseContract
		|WHERE
		|	LeaseContract.Ref = &Contract
		|";
		Query.SetParameter("Contract", FillParameters.Contract);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		If Selection.Next() Then
			VATTaxation = Selection.VATTaxation;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(VATTaxation) Or ArrayOfAvailable.Find(VATTaxation) = Undefined Then
		If ArrayOfAvailable.Count() = 1 Then
			VATTaxation = ArrayOfAvailable[0];
		Else
			UseVATAccounting = GetFunctionalOption("UseVATAccounting");
			VATTaxation = ?(UseVATAccounting, 
				                    Enums.VATTaxationTypes.SaleIsSubjectToVAT,
				                    Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the list of VAT values available for selection based on the document operation.
// 
// Parameters:
// 	ElementVATTaxation - FormField - A form element that specifies VAT taxation.
// 	VATTaxation - EnumRef.VATTaxationTypes - The value of VAT taxation selected in the document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases.
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInListOfVATTaxChoices(ElementVATTaxation, VATTaxation, FillParameters, CachedParameterValues = Undefined) Export
	
	If FillParameters.ReturnOfGoodsToConsignor
		 Or FillParameters.ConsignmentProcurement Then
		ElementVATTaxation.Title = NStr("vi = 'Thuế của người đặt ký gửi';
										|ru = 'Налогообложение комитента';
										|en = 'Consignor taxation'; fa = 'مشمولیت مالیاتی امانت‌گذار';
										|it = 'Tassazione committente';
										|pl = 'Opodatkowanie komitenta';
										|tr = 'Göndericinin vergilendirilmesi'");
	Else
		ElementVATTaxation.Title = NStr("vi = 'Tính thuế';
										|ru = 'Налогообложение';
										|en = 'Taxation'; fa = 'مالیات‌ستانی';
										|it = 'Tassazione';
										|pl = 'Taxation';
										|tr = 'Vergilendirme'");
	EndIf;
	
	ApplicableTypesOfProcurementTaxation = VATAccountingERPInternal.ApplicableTypesOfVATTaxation(False, True);
	// Redefine the view by document operation
	For Each Item In ApplicableTypesOfProcurementTaxation Do
		If Item.Value = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
			If FillParameters.ReturnOfGoodsToConsignor Or FillParameters.ConsignmentProcurement Then
				Item.Presentation = NStr("vi = 'Có tính thuế GTGT';
										|ru = 'Продажа облагается НДС';
										|en = 'Sale is subject to VAT'; fa = 'فروش مشمول مالیات بر ارزش افزوده است';
										|it = 'Vendita è soggetta ad IVA';
										|pl = 'Sprzedaż opodatkowana VAT';
										|tr = 'Satış işlemi KDV''ye tabidir'");
			ElsIf FillParameters.ReturnOfGoodsToVendor Then
				Item.Presentation = NStr("vi = 'Nhận hàng bán bị trả lại chịu thuế GTGT';
										|ru = 'Возврат товаров облагается НДС';
										|en = 'Return of goods is subject to VAT'; fa = 'Return of goods is subject to VAT';
										|it = 'Il reso delle merci è soggetto ad IVA';
										|pl = 'Zwrot towarów podlegających VAT';
										|tr = 'Ürünlerin iadesi KDV''ye tabidir'");
			EndIf;
		ElsIf Item.Value = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			If FillParameters.ReturnOfGoodsToConsignor Or FillParameters.ConsignmentProcurement Then
				Item.Presentation = NStr("vi = 'Bán hàng không chịu thuế GTGT';
										|ru = 'Продажа не облагается НДС';
										|en = 'Sale is not subject to VAT'; fa = 'فروش مشمول مالیات بر ارزش افزوده نیست';
										|it = 'Vendita non è soggetta ad IVA';
										|pl = 'Sprzedaż zwolniona z VAT';
										|tr = 'Satış işlemi KDV''ye tabi değildir'");
			ElsIf FillParameters.ReturnOfGoodsToVendor Then
				Item.Presentation = NStr("vi = 'Nhận hàng bán bị trả lại không chịu thuế GTGT';
										|ru = 'Возврат товаров не облагается НДС';
										|en = 'Return of goods is not subject to VAT'; fa = 'Return of goods is not subject to VAT';
										|it = 'Il reso delle merci non è soggetto ad IVA';
										|pl = 'Zwrot towarów nie podlegających VAT';
										|tr = 'Ürünlerin iadesi KDV''ye tabi değildir'");
			EndIf;
		EndIf;
	EndDo;
	
	AvailableTypesOfProcurementTaxation = VATAccountingERPInternal.VATFreePurchases(FillParameters);
	If ValueIsFilled(VATTaxation) And AvailableTypesOfProcurementTaxation.Find(VATTaxation) = Undefined Then
		AvailableTypesOfProcurementTaxation.Add(VATTaxation);
	EndIf;
	ElementVATTaxation.ChoiceList.Clear();
	
	For Each Value In AvailableTypesOfProcurementTaxation Do
		ListItem = ApplicableTypesOfProcurementTaxation.FindByValue(Value);
		If ListItem <> Undefined Then
			ElementVATTaxation.ChoiceList.Add(Value, ListItem.Presentation);
		Else
			ElementVATTaxation.ChoiceList.Add(Value);
		EndIf;
	EndDo;
	
	ElementVATTaxation.Visible = (ElementVATTaxation.ChoiceList.Count() <> 1); 
	
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInVATTaxationPurchases", FillParameters, CachedParameterValues);
	
EndProcedure

// Checks whether the document can be processed with the specified VAT taxation. 
//
// Parameters:
//	Object - DocumentObject - Data of the purchase document.
// 	VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the purchase document.
// 	CheckParameters - Arbitrary
// 	Cancel - Boolean - Indicates that the document was rejected.
//
Procedure CheckCompletionOfPurchaseDocumentForVATTaxation(Object, VATTaxation, CheckParameters, Cancel) Export
	
	VATAccountingLocalization.CheckCompletionOfPurchaseDocumentForVATTaxation(Object, VATTaxation, CheckParameters, Cancel);
	
EndProcedure

// Returns the structure of parameters for checking the completion of the purchase document for VAT taxation.
//
// Returns:
//	Structure - structure with fields:
//	         * TabularSectionName - String - The name of the tabular part of the purchased values.
//	         * BankingDetailsNameExpenseItem - String - the name of the Attribute of the tabular part in which the item of expenditure is indicated.
//	         * ExpenseAnalystDetailsName - String - the name of the Attribute of the tabular part that specifies the cost reflection analytics.
//
Function VerificationParametersFillingInDocumentOnVATTaxationPurchases() Export
	
	CheckParameters = New Structure();
	CheckParameters.Insert("TabularSectionName",             "");
	CheckParameters.Insert("BankingDetailsNameExpenseItem",    "");
	CheckParameters.Insert("ExpenseAnalystDetailsName", "");
	
	Return CheckParameters;
	
EndFunction

// We set the conditional registration for the VAT rate, the amount of VAT, the amount with VAT on the purchase tax.
//
// Parameters:
//  Form - ClientApplicationForm - Contains this form.
//  NameOfVATRateField - String - The name of the form element containing the VAT rate
//                                   if it is different from "Touristland".
//  NameOfVATAmountField - String - The name of the form element that contains the amount of VAT
//                                  if it is different from "Tourismos".
//  NameOfFieldWithVATAmount - String - The name of the form element that contains the amount including VAT,
//                                   if it is different from "Tourismand".
//  PathToTaxationField - String - The path to the Attribute of the form containing the value taxation.
//                                      if it is different from the "Object.Taxationsends".
Procedure EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(Form,
	                                          NameOfVATRateField = "GoodsVATRate",
	                                          NameOfVATAmountField  = "GoodsVATAmount",
	                                          NameOfFieldWithVATAmount = "GoodsAmountIncludingVAT",
	                                          PathToTaxationField = "Object.VATTaxation") Export
	
	PathParts = StrSplit(PathToTaxationField, ".");
	PathParts.Delete(PathParts.UBound()); // Deleting the Attribute name.
	Parent = TMCommonUseClientServer.DataAlongWay(
		Form,
		StrConcat(PathParts, ".")); 
	
	WHtaxation = TypeOf(Parent) = Type("FormDataCollection");
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	FormItem = FormItems[NameOfVATRateField]; // FormField, FormGroup -
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItem.Name);

	FormItem = FormItems[NameOfVATAmountField]; // FormField, FormGroup -
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItem.Name);

	FormItem = FormItems[NameOfFieldWithVATAmount]; // FormField, FormGroup -
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItem.Name);
	
	ListOfTaxation = New ValueList();
	ListOfTaxation.LoadValues(VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails(NameOfVATRateField));
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToTaxationField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTaxation;
	
	If WHtaxation Then
		ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True); 
	Else
		ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	PathToDataVATRate = FormItems[NameOfVATRateField].DataPath;
	
	FilterGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfVATAmountField].Name);
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToDataVATRate);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	RightValue =  VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RightValue.Add(Catalogs.VATRates.EmptyRef());
	ItemFilter.RightValue = RightValue;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);

	VATAccountingLocalization.SupplementConditionalAppearanceOfVATAmountsForTaxationOfPurchases(
		Form, NameOfVATRateField, NameOfVATAmountField, NameOfFieldWithVATAmount, PathToTaxationField);

EndProcedure

// We set conditional registration for the VAT amount, the amount with VAT at the purchase VAT rate.
//
// Parameters:
//  Form - ClientApplicationForm - Contains this form
//  NameOfVATRateField - String - The name of the form element containing the VAT rate
//                                  if it is different from "Touristland".
//  NameOfVATAmountField - String - The name of the form element that contains the amount of VAT
//                                  if it is different from "Tourismos".
//
Procedure SetConditionalAppearanceOfVATAmountsAtPurchaseVATRate(Form,
	                                          NameOfVATRateField = "GoodsVATRate",
	                                          NameOfVATAmountField  = "GoodsVATAmount") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	PathToDataVATRate = FormItems[NameOfVATRateField].DataPath;
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfVATAmountField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToDataVATRate);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	RightValue = VATAccountingERPInternalClientServerCached.ListOfInsignificantBets();
	RightValue.Add(Catalogs.VATRates.EmptyRef());
	ItemFilter.RightValue = RightValue;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#Region BatchProcessingOfTablePart

// Fills in the business of operation in the tabular part from the agreement or Contract.
//
// Parameters:
//	CurrentRow - Structure - The line of the tabular part in which taxation is completed.
//	StructureOfActions - Structure:
//		* FillInVATTaxationPurchases - See VATAccountingERPClientServer.ParametersOfBatchFillingInOfTaxationVATPurchases
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CompleteTaxationOfVATPurchasesInBatch(CurrentRow, StructureOfActions, CachedValues) Export
	
	ActionParameters = StructureOfActions.FillInVATTaxationPurchases;
	ObjectManager = Common.ObjectManagerByRef(ActionParameters.Document);
	FillParameters = ObjectManager.VATTaxationParameters(CurrentRow, ActionParameters);
	FillInVATTaxationPurchases(CurrentRow.VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region FillingInVATActivityType

// Fills in the type of activity for separate VAT accounting according to the passed parameters.
// Parameters:
// 	VATActivityType - EnumRef.VATTaxationTypes - Details of the purchase document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInTypeOfActivityVAT(VATActivityType, FillParameters, CachedParameterValues = Undefined) Export
	
	If FillParameters.Organization = Catalogs.Companies.EmptyRef() Then
		// The organization for the object is set, but not specified.
		// In this case, it makes no sense to fill in/check the type of VAT activity, 
		// because there is no way to get an accounting policy.
		Return;
	EndIf;
	
	ChangedParameters = VATAccountingERPInternal.ChangedParameters("ParametersForFillingInVATActivityType", FillParameters, CachedParameterValues);
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInVATActivityType", FillParameters, CachedParameterValues);
	
	OnlyIfEmptyOrIncorrect = True;
	If ChangedParameters.Property("Contract")
		Or ChangedParameters.Property("LineOfBusiness")
		Or ChangedParameters.Property("Organization")
		Or ChangedParameters.Property("Warehouse") Then
		OnlyIfEmptyOrIncorrect = False;
	EndIf;

	ArrayOfAvailable = VATAccountingERPInternal.AvailableVATActivities(FillParameters);
	
	If OnlyIfEmptyOrIncorrect Then
		If ArrayOfAvailable.Find(VATActivityType) <> Undefined Then
		    Return;
		EndIf;
	EndIf;
	
	NewVATActivity = VATActivityType;
	
	CompletedByAgreementOrActivityType = False;
	If (ChangedParameters.Property("Contract")
			And ValueIsFilled(FillParameters.Contract))
		Or (ChangedParameters.Property("LineOfBusiness")
			And ValueIsFilled(FillParameters.LineOfBusiness))
		Or (ChangedParameters.Property("Warehouse")
			And ValueIsFilled(FillParameters.Warehouse)) Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	1 AS Priority,
		|	CounterpartyContracts.PurchaseForActivity AS VATActivityType
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Contract
		|	AND NOT CounterpartyContracts.PurchaseForActivityIsDeterminedInDocument
		|
		|UNION ALL
		|
		|SELECT
		|	1 AS Priority,
		|	IntercompanyContracts.PurchaseForActivity AS VATActivityType
		|FROM
		|	Catalog.IntercompanyContracts AS IntercompanyContracts
		|WHERE
		|	IntercompanyContracts.Ref = &Contract
		|	AND NOT IntercompanyContracts.PurchaseForActivityIsDeterminedInDocument
		|
		|UNION ALL
		|
		|SELECT
		|	2 AS Priority,
		|	LinesOfBusiness.VATTaxation AS VATActivityType
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.Ref = &LineOfBusiness
		|	AND NOT LinesOfBusiness.VATTaxationIsDeterminedInDocuments
		|	AND (LinesOfBusiness.IncomeAccounting
		|		OR LinesOfBusiness.CostAccounting)
		|ORDER BY
		|	Priority";
		Query.SetParameter("Contract", FillParameters.Contract);
		Query.SetParameter("LineOfBusiness", FillParameters.LineOfBusiness);
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		If Selection.Next() Then
			NewVATActivity = Selection.VATActivityType;
			CompletedByAgreementOrActivityType = True;
		EndIf;
	EndIf;
	
	If ArrayOfAvailable.Find(NewVATActivity) = Undefined Then
		NewVATActivity = Undefined;
	EndIf;
	
	If ArrayOfAvailable.Find(Enums.VATTaxationTypes.EmptyRef()) <> Undefined Then
		NewVATActivity = Enums.VATTaxationTypes.EmptyRef();
	EndIf;
	
	If (Not CompletedByAgreementOrActivityType
			And (ChangedParameters.Property("Organization") And ValueIsFilled(FillParameters.Organization))
				Or (ChangedParameters.Property("Warehouse") And ValueIsFilled(FillParameters.Warehouse) And Not CompletedByAgreementOrActivityType))
			Or NewVATActivity = Undefined Then
		VATAccountingLocalization.FillInVATActivityTypeByParameters(NewVATActivity, VATActivityType, FillParameters);
	EndIf;
	
	If NewVATActivity = Undefined Then
		AccountingParametersForOrganization = AccountingParametersForOrganization(
				FillParameters.Organization,
				FillParameters.Date,
				FillParameters.Warehouse);
		NewVATActivity = AccountingParametersForOrganization.BasicTaxationVATSales;
	EndIf;
	
	VATActivityType = NewVATActivity;
	
EndProcedure

// Fills in the list of separate VAT accounting activities available for selection based on the accounting policy and operations of the document.
//
// Parameters:
// 	ItemTypeOfActivityVAT - FormField - A form element that specifies the type of VAT activity.
// 	VATActivityType - EnumRef.VATTaxationTypes - The value of the separate VAT accounting activity selected in the document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInVATActivityType.
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInActivitySelectionList(ItemTypeOfActivityVAT, VATActivityType, FillParameters, CachedParameterValues = Undefined) Export
	
	Presentations = VATAccountingERPInternal.ApplicableVATActivities();
	ArrayOfAvailable = VATAccountingERPInternal.AvailableVATActivities(FillParameters);
	
	If ValueIsFilled(VATActivityType) And ArrayOfAvailable.Find(VATActivityType) = Undefined Then
		ArrayOfAvailable.Add(VATActivityType);
	EndIf;
	
	ItemTypeOfActivityVAT.ChoiceList.Clear();
	For Each Value In ArrayOfAvailable Do
		PresentationElement = Presentations.FindByValue(Value);
		If PresentationElement <> Undefined Then 
			ItemTypeOfActivityVAT.ChoiceList.Add(Value, PresentationElement.Presentation);
		Else
			ItemTypeOfActivityVAT.ChoiceList.Add(Value);
		EndIf;
	EndDo;
	ItemTypeOfActivityVAT.Visible = (ItemTypeOfActivityVAT.ChoiceList.Count() > 1);
	
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInVATActivityType", FillParameters, CachedParameterValues);
	
EndProcedure

// Checks whether the document with the specified type of activity can be used for separate VAT accounting.
//
// Parameters:
// 	Object - DocumentObject - Document data.
// 	VATActivityType - EnumRef.VATTaxationTypes - Type of activity of separate VAT accounting.
// 	CheckParameters - Arbitrary
// 	Cancel - Boolean - Indicates that the document was rejected.
//
Procedure CheckCompletionOfDocumentByTypeOfVATActivity(Object, VATActivityType, CheckParameters, Cancel) Export
	
 	VATAccountingLocalization.CheckCompletionOfDocumentByTypeOfVATActivity(Object, VATActivityType, CheckParameters, Cancel)
	
EndProcedure

// Returns the structure of parameters for checking the completion of a document for the type of activity of separate VAT accounting.
//
// Returns:
// Structure - structure with keys:
// 			* TabularSectionName - String - The name of the tabular part in which the values are specified.
// 			* BankingDetailsNameExpenseItem - String - the name of the Attribute of the tabular part in which the item of expenditure reflection is indicated (optional).
// 			* ExpenseAnalystDetailsName - String - the name of the Attribute of the tabular part that specifies the cost reflection analytics (optional).
// 			* DetailsNameItemOfAssetsLiabilities - String - the name of the Attribute of the tabular part in which the item of reflection of other assets is indicated (optional).
// 			* NameOfAssetLiabilityAnalystDetails - String - the name of the Attribute of the tabular part, which indicates the analytics of the reflection of other assets (optional).
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity() Export

	CheckParameters = New Structure();
	CheckParameters.Insert("TabularSectionName", "");
	CheckParameters.Insert("BankingDetailsNameExpenseItem", "");
	CheckParameters.Insert("ExpenseAnalystDetailsName", "");
	CheckParameters.Insert("DetailsNameItemOfAssetsLiabilities", "");
	CheckParameters.Insert("NameOfAssetLiabilityAnalystDetails", "");
	
	Return CheckParameters;
	
EndFunction

#EndRegion

#Region RegistrationOfInvoicesReceived

// Returns a collection of properties that describe invoices/import statements registered based on a purchase or return document
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
// 
// Returns:
// 	Structure - structure with keys:
//		* Presentation - String, FormattedString - description of the documents registered on the basis of the purchase or return document.
//		* Invoices_ - Array of DocumentRef - Document link.Invoice received, document link.Invoice of the invoice received by the tax agent, document link.Importation of goods-links to the invoice/application for importation of goods.
//		* DocumentOnBasisIsRequired - Boolean - indicates whether you need to enter at least one document for the base
//		* ThereIsRightToInteractivelyAddDocumentOnBasisOf - Boolean - indicates whether you have the right to interactively add a document to the base.
//		* ThereAreDiscrepancies - Boolean
//
Function InvoicesReceivedOnBasisOf(RegistrationParameters) Export
	
	Result = New Structure();
	Result.Insert("Presentation", "");
	Result.Insert("Invoices_",  New Array);
	Result.Insert("DocumentOnBasisIsRequired",  False);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf",  False);
	Result.Insert("ThereAreDiscrepancies", False);
	
	
	Return Result;

EndFunction

// Called in the handler Before writing () the purchase document.
// Cancels the invoice if the purchase document is canceled or its details do not match the registration parameters.
// Marks an invoice for deletion if the purchase document is marked for deletion.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived.
// 	WriteMode - DocumentWriteMode - the recording mode of the document.
// 	DeletionMark - Boolean - Mark the deletion of the purchase document.
// 	Posted - Boolean - Marking of the document execution.
//
Procedure UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, Val WriteMode, Val DeletionMark, Val Posted) Export
	
	
EndProcedure

// Called in the procure document Processing() handler.
// Executes invoices based on the purchase document data.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived.
// 	
Procedure UpdateInvoicesReceivedDuring(RegistrationParameters) Export
	
	
EndProcedure

// Called in the procure document deletion() Handler after movements are recorded.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived.
//
Procedure UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters) Export
	
	
EndProcedure

// Returns invoices received and registered based on documents.
//
// Parameters:
// 	BasisDocuments - DocumentRef, Array  of DocumentRef - A document or array of documents-the basis of invoices received.
// 	OnlyConductedOnes - Boolean - Indicates that only completed documents should be returned.
//
// Returns:
// 	ValueTable - Table of invoices registered on the basis of:
// 	   * DocumentBasis - DocumentRef - Link to the base document that has an invoice.
// 	   * Ref - DocumentRef - Link to the invoice received.
// 	   * ManualAdjustmentOfDocumentAmounts - Boolean - True if the invoice amounts were changed manually by the user.
//
Function InvoicesReceivedOnLegalGrounds(BasisDocuments, OnlyConductedOnes = True) Export
	
	Invoices_ = New ValueTable();
	Invoices_.Columns.Add("DocumentBasis");
	Invoices_.Columns.Add("Ref");
	Invoices_.Columns.Add("ManualAdjustmentOfDocumentAmounts", New TypeDescription("Boolean"));
	
		
	Return Invoices_;

EndFunction

#EndRegion

// LongDesc
// 
// Parameters:
// 	OldTaxation - EnumRef.VATTaxationTypes -
// 	NewTaxation - EnumRef.VATTaxationTypes - 
// Returns:
// 	Boolean - LongDesc
Function VATCanBeDebited(OldTaxation, NewTaxation) Export
	
	TypesOfVATActivitiesInCost = ActivitiesVATIsIncludedInCost();
	TypesOfNdskReimbursementActivities = TypesOfActivitiesVATIsAcceptedForReimbursement();
	
	Return (TypesOfNdskReimbursementActivities.Find(OldTaxation) <> Undefined
					And TypesOfVATActivitiesInCost.Find(NewTaxation) <> Undefined);
	
EndFunction

#EndRegion

#Region AccountingForOutgoingVAT

#Region FillingInSalesVATTaxation

// Verifies that the VAT Tax value specified in the sales document matches the VAT accounting settings and the document operation. 
// If the passed value is not filled in or incorrect, it is filled in with the value from the NSI.
//
// Parameters:
// 	VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the sales document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInSalesVATTaxation(VATTaxation, FillParameters, CachedParameterValues = Undefined) Export
	
	If FillParameters.Organization = Catalogs.Companies.EmptyRef() Then
		// The organization for the object is set in principle, but is not specified.
		// In this case, it makes no sense to fill out / check taxation, 
		// because there is no way to get an accounting policy.
		Return;
	EndIf;
	
	ChangedParameters = VATAccountingERPInternal.ChangedParameters("ParametersForFillingInSalesVATTaxation",
								FillParameters,
								CachedParameterValues);
								
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInSalesVATTaxation",
								FillParameters,
								CachedParameterValues);

	OnlyIfEmptyOrIncorrect = True;
	If ChangedParameters.Property("Contract")
		Or ChangedParameters.Property("LineOfBusiness")
		Or ChangedParameters.Property("Organization")
		Or ChangedParameters.Property("Warehouse") Then
		OnlyIfEmptyOrIncorrect = False;
	EndIf;
	
	If FillParameters.TransferToStorage
		Or FillParameters.ReturnFromStorage
		Or FillParameters.TransferToCommissionAgent
		Or FillParameters.ReturnOfGoodsFromCommissionAgent Then
		
		VATTaxation = Enums.VATTaxationTypes.EmptyRef();
		Return;
		
	EndIf;
	
	ArrayOfAvailable = VATAccountingERPInternal.AvailableSalesVATTaxation(FillParameters);
	If OnlyIfEmptyOrIncorrect Then
		If ValueIsFilled(VATTaxation) And ArrayOfAvailable.Find(VATTaxation) <> Undefined Then
			Return;
		EndIf;
	EndIf;
	
	NewVATTaxation = VATTaxation;
	
	TaxationOfContract = Undefined;
	If ValueIsFilled(FillParameters.Contract) Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	CounterpartyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Contract
		|	AND NOT CounterpartyContracts.VATTaxationIsDeterminedInDocuments
		|
		|UNION ALL
		|
		|SELECT
		|	IntercompanyContracts.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.IntercompanyContracts AS IntercompanyContracts
		|WHERE
		|	IntercompanyContracts.Ref = &Contract
		|	AND NOT IntercompanyContracts.VATTaxationIsDeterminedInDocuments
		|";
		Query.SetParameter("Contract", FillParameters.Contract);
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		If Selection.Next() Then
			TaxationOfContract = Selection.VATTaxation;
		EndIf;
	EndIf;
	
	TaxationAreasOfActivity = Undefined;
	If ValueIsFilled(FillParameters.LineOfBusiness) Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	2 AS Priority,
		|	LinesOfBusiness.VATTaxation AS VATTaxation
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.Ref = &LineOfBusiness
		|	AND NOT LinesOfBusiness.VATTaxationIsDeterminedInDocuments
		|	AND LinesOfBusiness.IncomeAccounting
		|";
		Query.SetParameter("LineOfBusiness", FillParameters.LineOfBusiness);
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		If Selection.Next() Then
			TaxationAreasOfActivity = Selection.VATTaxation;
		EndIf;
	EndIf;
	
	If (ChangedParameters.Property("Contract") And ValueIsFilled(FillParameters.Contract))
			Or (ChangedParameters.Property("LineOfBusiness") And ValueIsFilled(FillParameters.LineOfBusiness)) Then
		
		If ValueIsFilled(TaxationOfContract) Then
			NewVATTaxation = TaxationOfContract;
		ElsIf ValueIsFilled(TaxationAreasOfActivity) Then
			NewVATTaxation = TaxationAreasOfActivity;
		EndIf;
		
	EndIf;
	
	OrganizationOrWarehouseChanged = 
		(ChangedParameters.Property("Organization") And ValueIsFilled(FillParameters.Organization))
			Or (ChangedParameters.Property("Warehouse") And ValueIsFilled(FillParameters.Warehouse));
	
	If (OrganizationOrWarehouseChanged And TaxationOfContract = Undefined And TaxationAreasOfActivity = Undefined)
			Or ArrayOfAvailable.Find(NewVATTaxation) = Undefined Then
		VATAccountingLocalization.FillInVATTaxationOfSalesByParameters(NewVATTaxation, VATTaxation, FillParameters);
	EndIf;
	
	If Not ValueIsFilled(NewVATTaxation) Then
		OrganizationAccountingParameters = AccountingParametersForOrganization(FillParameters.Organization,
			FillParameters.Date,
			FillParameters.Warehouse,
			FillParameters.Department);
		NewVATTaxation = OrganizationAccountingParameters.BasicTaxationVATSales;
	EndIf;
	
	VATTaxation = NewVATTaxation;
	
EndProcedure

// Fills in the list of VAT tax values available for selection based on the VAT accounting settings of the document operation.
//
// Parameters:
// 	ElementVATTaxation - FormField - A form element that specifies VAT taxation.
// 	VATTaxation - EnumRef.VATTaxationTypes - The value of VAT taxation selected in the document.
// 	FillParameters - See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
// 	CachedParameterValues - Arbitrary - The value of the details of cached values of VAT accounting parameters.
//
Procedure FillInSalesVATTaxSelectionList(ElementVATTaxation, VATTaxation, FillParameters, CachedParameterValues = Undefined) Export
	
	ApplicableTypesOfSalesTaxation = VATAccountingERPInternal.ApplicableTypesOfVATTaxation(True, False);
	For Each Item In ApplicableTypesOfSalesTaxation Do
		If Item.Value = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
			If FillParameters.ReturnOfGoodsFromCustomer Or FillParameters.ReturnOfGoodsFromCommissionAgent Then
				Item.Presentation = NStr("vi = 'Hoàn tiền phải chịu thuế GTGT';
										|ru = 'Возврат облагается НДС';
										|en = 'Return is subject to VAT'; fa = 'Return is subject to VAT';
										|it = 'Il reso è soggetto ad IVA';
										|pl = 'Zwrot podlega podatkowi VAT';
										|tr = 'İade KDV''ye tabi'");
			EndIf;
		EndIf;
		If Item.Value = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			If FillParameters.ReturnOfGoodsFromCustomer Or FillParameters.ReturnOfGoodsFromCommissionAgent Then
				Item.Presentation = NStr("vi = 'Hoàn tiền không chịu thuế GTGT';
										|ru = 'Возврат не облагается НДС';
										|en = 'Return is not subject to VAT'; fa = 'Return is not subject to VAT';
										|it = 'Il reso non è soggetto ad IVA';
										|pl = 'Zwrot nie podlega podatkowi VAT';
										|tr = 'İade KDV''ye tabi değildir'");
			EndIf;
		EndIf;
		If Item.Value = Enums.VATTaxationTypes.SaleIsSubjectToUTII Then
			If FillParameters.ReturnOfGoodsFromCustomer Or FillParameters.ReturnOfGoodsFromCommissionAgent Then
				Item.Presentation = NStr("vi = 'Hoàn tiền chịu thuế khoán';
										|ru = 'Возврат облагается ЕНВД';
										|en = 'Return is subject to UTII'; fa = 'Return is subject to UTII';
										|it = 'Il reso è soggetto ad ENVD (Imposta unica sui redditi imputabili)';
										|pl = 'Zwrot podlega JPDZ';
										|tr = 'İade Emsal Gelirde Tek Vergiye tabi'");
			EndIf;
		EndIf;
	EndDo;
		
	AvailableForSale = VATAccountingERPInternal.AvailableSalesVATTaxation(FillParameters);
	If ValueIsFilled(VATTaxation) And AvailableForSale.Find(VATTaxation) = Undefined Then
		AvailableForSale.Add(VATTaxation);
	EndIf;
	ElementVATTaxation.ChoiceList.Clear();
	
	For Each Value In AvailableForSale Do
		ListItem = ApplicableTypesOfSalesTaxation.FindByValue(Value);
		If ListItem <> Undefined Then
			ElementVATTaxation.ChoiceList.Add(Value, ListItem.Presentation);
		Else
			ElementVATTaxation.ChoiceList.Add(Value);
		EndIf;
	EndDo;
	
	ElementVATTaxation.Visible = (ElementVATTaxation.ChoiceList.Count() <> 1); 
	VATAccountingERPInternal.UpdateCachedParameterValues("ParametersForFillingInSalesVATTaxation", FillParameters, CachedParameterValues);

EndProcedure

// Sets limits on the types of inventory that can be sold at the specified tax rate
// 
// Parameters:
// 	SelectionOfStockTypes_ - See Catalogs.InventoryKinds.StockTypeSelectionParameters
// 	Organization - CatalogRef.Companies - 
// 	Date - Date -
// 	VATTaxation - Undefined, EnumRef.VATTaxationTypes -
Procedure ParametersForFillingTypesOfStocksForTaxation(SelectionOfStockTypes_, Organization, Date, VATTaxation = Undefined) Export
	
	VATAccountingLocalization.SupplementParametersForFillingTypesOfStocksForTaxation(SelectionOfStockTypes_, Organization, Date, VATTaxation);
	
EndProcedure

// We set the conditional registration of the "HS Code" field for sales taxation.
//
// Parameters:
//  Form - ClientApplicationForm - Contains this form
//  TSName - String - Name of the table part of the document, if it differs from "Products".
//                   The table part must contain the nomenclature Type field.
//  ThereIsProductRange - Boolean - attribute of product-specific sales
//
Procedure EstablishConditionalAppearanceOfHSCodeForTaxationOfSales(Form, TSName = "Goods", ThereIsProductRange = True) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItem = Form.Items[TSName + "FEACNCode"]; // FormField, FormGroup -
	
	Item = ConditionalAppearance.Items.Add();

	DataCompositionClientServer.AddFieldToCreate(
		Item.Fields,
		FormItem.Name);
	
	ListOfExportTaxation = New ValueList();
	ListOfExportTaxation.LoadValues(VATAccountingERPInternal.TaxationOfVATSalesForExport());
	
	If ThereIsProductRange Then
		DataCompositionClientServer.AddFilter(
			Item.Filter,
			"Object.VATTaxation",
			ListOfExportTaxation,
			DataCompositionComparisonType.NotInList);
	Else
		FilterGroup = DataCompositionClientServer.AddSelectionGroup(
			Item.Filter.Items,
			DataCompositionFilterItemsGroupType.OrGroup);
		
		DataCompositionClientServer.AddFilter(
			FilterGroup, 
			"Object.BusinessOperation",
			Enums.BusinessTransactions.NonCurrentAssetsSale,
			DataCompositionComparisonType.NotEqual);
			
		DataCompositionClientServer.AddFilter(
			FilterGroup, 
			"Object.VATTaxation",
			ListOfExportTaxation,
			DataCompositionComparisonType.NotInList);
	EndIf;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	///////
	
	If ThereIsProductRange Then
		ListOfProductTypes = New ValueList();
		ListOfProductTypes.LoadValues(VATAccountingERPInternal.ProductProductTypes());
		
		Item = ConditionalAppearance.Items.Add();
		
		DataCompositionClientServer.AddFieldToCreate(
			Item.Fields,
			FormItem.Name);
		
		DataCompositionClientServer.AddFilter(
			Item.Filter,
			"Object." + TSName + ".ItemsType",
			ListOfProductTypes,
			DataCompositionComparisonType.NotInList);
	
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
														|ru = '<для товаров>';
														|en = '<for goods>'; fa = '<for goods>';
														|it = '<per le merci>';
														|pl = '<dla towarów>';
														|tr = '<ürünler için>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
EndProcedure

// We set conditional registration for the VAT rate, the amount of VAT, the amount with VAT on sales taxation.
//
// Parameters:
//  Form - ClientApplicationForm - Contains this form
//  NameOfVATRateField - String - The name of the form element containing the VAT rate
//                                   if it is different from "Touristland".
//  NameOfVATAmountField - String - The name of the form element that contains the amount of VAT
//                                  if it is different from "Tourismos".
//  NameOfFieldWithVATAmount - String - The name of the form element that contains the amount including VAT,
//                                   if it is different from "Tourismand".
//
Procedure EstablishConditionalAppearanceOfVATAmountsForSalesTaxation(Form,
	                                          NameOfVATRateField = "GoodsVATRate",
	                                          NameOfVATAmountField  = "GoodsVATAmount",
	                                          NameOfFieldWithVATAmount = "GoodsAmountIncludingVAT") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items; // FormAllItems -
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfVATRateField].Name);

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfVATAmountField].Name);

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems[NameOfFieldWithVATAmount].Name);
	
	ListOfTaxation = New ValueList();
	ListOfTaxation.LoadValues(VATAccountingERPClientServer.TypesOfTaxationThatHideVATDetails());
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTaxation;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	//
	
	VATAccountingLocalization.SupplementConditionalAppearanceOfVATAmountsForSalesTaxation(Form, NameOfVATRateField, NameOfVATAmountField, NameOfFieldWithVATAmount);
	
EndProcedure

// Defines the type of activity of separate VAT accounting based on the VAT taxation of sales.
//
// Parameters:
//	VATTaxation - EnumRef.VATTaxationTypes -
//	Organization - CatalogRef.Companies
//	Date - Date
//
// Returns:
//	EnumRef.VATTaxationTypes -
//
Function TypeOfVATTaxationActivity(VATTaxation, Organization = Undefined, Date = Undefined) Export
	
	VATActivityType = Undefined;
	VATAccountingLocalization.EstablishTypeOfVATTaxationActivity(VATActivityType, VATTaxation, Organization, Date);
	If VATActivityType = Undefined Then
		VATActivityType = VATTaxation;
	EndIf;
	
	Return VATActivityType;
		
EndFunction

// Returns the text of the request to check whether the item selection is correct for VAT taxation in the sales document
//
// Parameters:
//	QueryOptions - Structure - Parameters of the control request that can be supplemented
//
// Returns:
// 	String - Query text
//
Function TextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales(QueryOptions) Export
	
	QueryText = "SELECT TRUE AS Result;";
	VATAccountingLocalization.CompleteTextOfRequestCorrectnessOfSelectionOfProductsForTaxationOfVATSales(QueryText, QueryOptions);
	
	Return QueryText;
	
EndFunction

// Processes the result of checking the correctness of the selection of the item for VAT taxation in the sales document
//
// Parameters:
//	Selection - QueryResultSelection - Result of the control request
//	DocumentSales - DocumentRef - Document that was used for monitoring
//	TSName - String - Name of the table part for generating the error message
//	PresentationOfTS - String - View of a tabular portion for the formation of the error message
//	Cancel - Boolean - Failure flag to set if there are problems.
//
Procedure ReportErrorsCorrectSelectionOfProductsForVATSales(Val Selection, Val DocumentSales, Val TSName, Val PresentationOfTS, Cancel) Export
	
	VATAccountingLocalization.ReportErrorsCorrectSelectionOfProductsForVATSales(Selection, DocumentSales, TSName, PresentationOfTS, Cancel);
	
EndProcedure

// Sets parameters for filling inventory types for commission sales.
//
// Parameters:
//	FillParameters - See InventoriesServer.ParametersForFillingInventoryTypes
//
Procedure SetParametersForFillingInventoryTypesForCommissionSales(FillParameters) Export
	
	VATAccountingLocalization.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
	
EndProcedure

#EndRegion

#Region FormationOfInvoicesIssued

// Returns 
// - text for displaying invoices registered on the basis of the sales document.
// - links to invoice data.
// 
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
// Returns:
// 	Structure - LongDesc:
// * ThereIsRightToInteractivelyAddDocumentOnBasisOf - Boolean -
// * DocumentOnBasisIsRequired - Boolean -
// * Invoices_ - Array of DocumentRef
// * Presentation - FormattedString -
Function InvoicesIssuedOnBasisOf(RegistrationParameters) Export
	
	Result = New Structure();
	Result.Insert("Presentation", New FormattedString(""));
	Result.Insert("Invoices_",  New Array);
	Result.Insert("DocumentOnBasisIsRequired",  False);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf",  False);
	
	
	Return Result;

EndFunction

// Returns 
// - text for displaying invoices registered on the basis of the sales document.
// - links to invoice data.
// 
// Parameters:
// 	ParametersForRegisteringIssuedSF - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
// 	ParametersForRegisteringReceivedSF - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
// Returns:
// 	Structure - LongDesc:
// * Presentation - FormattedString - A line for presenting invoices in a sales document.
// * Invoices_ - Array of DocumentRef - Array of invoices registered based on the sales document.
// * ThereIsRightToInteractivelyAddDocumentOnBasisOf - Boolean -
// * DocumentOnBasisIsRequired - Boolean -.
Function InvoicesGeneralOnBasisOf(ParametersForRegisteringIssuedSF, ParametersForRegisteringReceivedSF) Export
	
	Result = New Structure();
	Result.Insert("Presentation", New FormattedString(""));
	Result.Insert("Invoices_",  New Array);
	Result.Insert("DocumentOnBasisIsRequired", False);
	Result.Insert("ThereIsRightToInteractivelyAddDocumentOnBasisOf", False);
	
	ResultIssued = InvoicesIssuedOnBasisOf(ParametersForRegisteringIssuedSF);
	ResultObtained = InvoicesReceivedOnBasisOf(ParametersForRegisteringReceivedSF);
	
	Result.Presentation = ResultIssued.Presentation;
	Result.DocumentOnBasisIsRequired = ResultIssued.DocumentOnBasisIsRequired;
	Result.ThereIsRightToInteractivelyAddDocumentOnBasisOf = 
		ResultIssued.ThereIsRightToInteractivelyAddDocumentOnBasisOf;
	If ResultIssued.Invoices_.Count() > 0 Then
		Result.Invoices_ = ResultIssued.Invoices_;
	ElsIf ResultObtained.Invoices_.Count() > 0 Then
		Result.Invoices_ = ResultObtained.Invoices_;
		Result.Presentation = ResultObtained.Presentation;
		Result.DocumentOnBasisIsRequired = ResultObtained.DocumentOnBasisIsRequired;
		Result.ThereIsRightToInteractivelyAddDocumentOnBasisOf = 
			ResultObtained.ThereIsRightToInteractivelyAddDocumentOnBasisOf;
	ElsIf ResultObtained.DocumentOnBasisIsRequired Then
		Result.Presentation = ResultObtained.Presentation;
		Result.DocumentOnBasisIsRequired = ResultObtained.DocumentOnBasisIsRequired;
		Result.ThereIsRightToInteractivelyAddDocumentOnBasisOf = 
			ResultObtained.ThereIsRightToInteractivelyAddDocumentOnBasisOf;
	EndIf;
	
	Return Result;

EndFunction

// Called in the handler before Writing () the sales document.
// Cancels invoicing if the sales document is canceled or its details do not match the registration parameters.
// Marks an invoice for deletion if the sales document is marked for deletion.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued.
// 	WriteMode - DocumentWriteMode - the recording mode of the document.
// 	DeletionMark - Boolean - Mark the deletion of the sales document.
// 	Posted - Boolean - Marking of the document execution.
//
Procedure UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, Val WriteMode, Val DeletionMark, Val Posted) Export
	
	
EndProcedure

// Called in the sales document Processing() handler.
// Executes invoices based on the sales document data.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued.
//
Procedure UpdateInvoicesIssuedDuringTransaction(RegistrationParameters) Export
	
	
EndProcedure

// Called in the sales document deletion Processing() handler after movements are recorded.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued.
//
Procedure UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters) Export
	
	
EndProcedure

// Returns the invoice is issued, formed on the basis of documents of sale.
//
// Parameters:
// 	BasisDocuments - DocumentRef, Array of DocumentRef - A document or array of documents-the basis of invoices issued.
// 	OnlyConductedOnes - Boolean - Indicates that only completed invoices should be returned.
//
// Returns:
// 	ValueTable - Table of invoices registered on the basis of:
// 		* DocumentBasis - DocumentRef - Link to the base document that has an invoice.
// 		* Ref - DocumentRef - Link to the issued invoice.
// 		* Corrective - Boolean - a sign of a Corrective invoice.
// 		* Patch - Boolean - the sign of the Correction invoice.
//
Function InvoicesIssuedOnLegalGrounds(BasisDocuments, OnlyConductedOnes = True) Export
	
	Invoices_ = New ValueTable();
	Invoices_.Columns.Add("DocumentBasis");
	Invoices_.Columns.Add("Ref");
	Invoices_.Columns.Add("Corrective");
	Invoices_.Columns.Add("Patch");
	Invoices_.Columns.Add("ManualAdjustmentOfDocumentAmounts", New TypeDescription("Boolean"));
	
	
	Return Invoices_;

EndFunction

// Returns the full name of the document invoice Issued
// 
// Returns:
// 	String, Undefined - LongDesc
Function FullNameOfInvoiceIssued() Export
	
	Result = Undefined;
	Return Result;
	
EndFunction

// Fills in the Invoice issued according to the passed registration parameters, performs the document execution.
// If it was not possible to hold the document, it writes the document.
//
// Parameters:
//  TaxInvoice - DocumentObject, DocumentRef - an object or reference of the invoice issued
//  RegistrationParameters - Structure - Values of the invoice details. See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
// Returns:
// 	Structure:
// 		* ErrorMessage - String - Error message if the document could not be processed.
// 		* Posted - Boolean - If it was possible to hold the document, then the Truth. Otherwise - A Lie.
//
Function FillInInvoiceIssued(TaxInvoice, RegistrationParameters) Export
	
	Result = New Structure;
	Result.Insert("Posted", True);
	Result.Insert("ErrorMessage", "");
	
	
	Return Result;
	
EndFunction

// Generates corrective invoices issued on the basis of changed documents.
// 
// Parameters:
//  TableOfModifiedDocuments	- ValueTable - modified sales documents and their Attributes:
//  	* Document - DefinedType.BaseDocumentIssuedTaxInvoice - The Foundation document.
//  	* Organization - CatalogRef.Companies - Organization of the Foundation document.
//  	* Date - Date - Date of the Foundation document.
//  	* EmployeeResponsible - CatalogRef.Users - Responsible for the Foundation document.
// 
// Returns:
//  Array of DocumentRef
//
Function GenerateCorrectiveInvoicesForChangedDocuments(TableOfModifiedDocuments) Export
	
	GeneratedDocuments = New Array;
	
	
	Return GeneratedDocuments;
	
EndFunction

// Checks the need to generate invoices issued according to the passed registration parameters.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued.
//
// Returns:
// 	Boolean - Indicates whether an invoice needs to be generated.
//
Function InvoiceIssuedIsNotRequired(RegistrationParameters) Export
	
	NoInvoiceRequired = True;
	
	
	Return NoInvoiceRequired;
	
EndFunction

#EndRegion

#Region FormationOfInvoicesToCommissionAgent
	
// Returns 
// - text display invoices that are registered on the basis of the report of the Commission.
// - links to invoice data.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent
// 
// Returns:
// 	Structure:
//		* Presentation - FormattedString - The line of submission of invoices in the report to the commission agent.
// 		* Invoices_ - Array of DocumentRef - Array of invoices registered based on the commission agent's report.
//
Function InvoicesToCommissionAgentOnBasisOf(RegistrationParameters) Export
	
	Result = New Structure();
	Result.Insert("Presentation", New FormattedString(""));
	Result.Insert("Invoices_",  New Array);
	
	
	Return Result;
	
EndFunction

// Called in the handler Before writing () the Commission agent report.
// Cancels the execution of invoices if the Commission agent's report is canceled or its details do not match the registration parameters.
// Marks an invoice for deletion if the Commission agent's report is marked for deletion.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent
// 	WriteMode - DocumentWriteMode - The recording mode of the document
// 	DeletionMark - Boolean - Mark the deletion of the Commission agent's report.
// 	Posted - Boolean - Marking of the document execution.
//
Procedure UpdateInvoicesToCommissionAgentBeforeRecording(RegistrationParameters, Val WriteMode, Val DeletionMark, Val Posted) Export
	
	
EndProcedure

// Called in the Commission agent report Processing() handler.
// Executes invoices based on the Commission agent's report.
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent
//
Procedure UpdateInvoicesToCommissionAgentWhenConducting(RegistrationParameters) Export
	
	
EndProcedure

// Called in the handler for processing the removal of the Report() of the Commission agent after recording the movements.
// Updates orders for issuing invoices to the Commission agent. 
//
// Parameters:
// 	RegistrationParameters - See VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent
//
Procedure UpdateInvoicesToCommissionAgentWhenDeletingThem(RegistrationParameters) Export
	
	
EndProcedure

#EndRegion

#Region RegistrationOfCommitteeInvoices

// Called in the report Processing() handler for the report to the Commitee.
// Is updating regulations for the registration of invoices of the principal. 
//
// Parameters:
// 	InvoicesIssuedToCustomers - Array of DocumentRef - Invoices issued to customers whose parameters were reported to the Committee.
// 	Cancel - Boolean -
//
Procedure UpdateCommitteeSInvoicesWhenConducting(InvoicesIssuedToCustomers, Cancel = False ) Export
	
	
EndProcedure

// Invoked in the handler of Operationalenvironment() report of the principal after a call to record movements.
// Is updating regulations for the registration of invoices of the principal. 
//
// Parameters:
// 	InvoicesIssuedToCustomers - Array of DocumentRef - Invoices issued to customers whose parameters were reported to the Committee.
//
Procedure UpdateCommitteeSInvoicesWhenDeletingThem(InvoicesIssuedToCustomers) Export
	
	
EndProcedure

// Supplements the temporary table of goods for the preparation of the report to the committee with the "Invoice" column.
// This column is filled in with invoices selected by parameters, issued to the buyer of commission goods.
// The initial temporary table should contain columns for which invoices are selected.
// 	Buyer - Reference link.Counterparties, reference link.company - buyer of commission goods.
// 	Documentrealization - Documentlink - A document of the sale of commission goods.
// 	Invoice Data - Date - The date the invoice was issued.
// 	Invoice AccountNumber - Line - Invoice number. 
//
// Parameters:
// 	TempTablesManager - TempTablesManager - A temporary table Manager that contains a table of products to be processed.
// 	TableName - String - Name of the temporary table of products to report to the Commitee.
//
Procedure SupplementTableWithDataOfInvoicesIssuedToCustomers(TempTablesManager, TableName) Export
	
	QueryText = 
	"SELECT
	|	&TableFields,
	|	TableName.Customer AS Customer,
	|	TableName.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableName.TaxInvoiceDate AS TaxInvoiceDate,
	|	TableName.TaxInvoiceNumber AS TaxInvoiceNumber,
	|	""""  AS TaxInvoice
	|INTO TableNamePreliminary
	|FROM
	|	TableName AS TableName
	|;
	|
	|/////////////////////////////////////////////////////////////////
	|DROP TableName
	|;
	|
	|/////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO TableName
	|FROM
	|	TableNamePreliminary
	|;
	|
	|/////////////////////////////////////////////////////////////////
	|DROP TableNamePreliminary";
	
	TempTable = TempTablesManager.Tables.Find(TableName);
	SelectionFields1 = New Array;
	For Each Column In TempTable.Columns Do
		If Column.Name <>"Customer"
				And Column.Name <>"DocumentSalesOfGoodsAndServices"
				And Column.Name <>"TaxInvoiceDate"
				And Column.Name <>"TaxInvoiceNumber" Then
			SelectionField = StrTemplate("	%1.%2 AS %2", TableName, Column.Name);
			SelectionFields1.Add(SelectionField);
		EndIf;
	EndDo;
	Separator = ",
		|";
	SelectionFieldString__ = StrConcat(SelectionFields1, Separator);
	QueryText = StrReplace(QueryText, "&TableFields", SelectionFieldString__);
	QueryText = StrReplace(QueryText, "TableName", TableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
EndProcedure

#EndRegion

// Procedure - To establish the visibility of the Form Attributes of the Country of implementation
//
// Parameters:
//  Form				 - ClientApplicationForm - A Form with the Attributes of the Country of sale.
//
Procedure EstablishVisibilityOfCountryOfImplementation(Form) Export
	
	TMCommonUseClientServer.SetFormItemProperty(
		Form.Items,
		"CountryOfSale",
		"Visible",
		False);
		

EndProcedure

#EndRegion

#Region VATTransferToBudgetByCertainTransactions

// Updates the header of the command to view the status of VAT payment for a document when the 
// event change in the payment status of the Invoice occurs.
// 
// Parameters:
// 	TaxInvoice - DefinedType.TaxInvoice - A document requiring payment of VAT.
// 	StateCommand - FormButton - An element of the status view command.
// 	PaymentViaSinglePersonalAccount - Boolean - indication of payment of customs payments via a single personal account
Procedure SetTitleOfStateOfVATPaymentOnInvoice(TaxInvoice, StateCommand, PaymentViaSinglePersonalAccount = False) Export
	
	Title = Undefined;
	
	If Title = Undefined Or PaymentViaSinglePersonalAccount Then
		StateCommand.Visible = False;
	Else
		StateCommand.Visible = True;
		StateCommand.Title = Title;
	EndIf;

EndProcedure

#EndRegion

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VATInvoiced);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.LotsVATForAllocation);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsToVendor);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VATRegisterRecords);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.VATInvoiced);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.LotsVATForAllocation);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsToVendor);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer);

	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.VATInvoiced);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.VATPrepaymentsToVendor);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.VATRegisterRecords);
	EndIf;
	VATAccountingLocalization.AddParametersForDocument(Parameters, Document, Properties);
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of String - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.VATInvoiced;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.VATPrepaymentsToVendor;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.VATRegisterRecords;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.LotsVATForAllocation;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryText = DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument);
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
	EndIf;
	
	VATAccountingLocalization.AddTextsOfCancellationRequests(QueriesTexts, MetadataOfDocument);
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of String - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("VATInvoicedUpdate", 
		AccumulationRegisters.VATInvoiced.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableVATPrepaymentsFromCustomer", 
		AccumulationRegisters.VATPrepaymentsFromCustomer.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableVATPrepaymentsToVendor", 
		AccumulationRegisters.VATPrepaymentsToVendor.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of VAT.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , Metadata.AccumulationRegisters.VATInvoiced.Name);
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , Metadata.AccumulationRegisters.LotsVATForAllocation.Name);
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , Metadata.AccumulationRegisters.VATPrepaymentsToVendor.Name);
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Name);
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords , Metadata.AccumulationRegisters.VATRegisterRecords.Name);
	
	VATAccountingLocalization.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel);
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	VATAccountingLocalization.AddChangeControlRequest(Query, QueryTexts, Document);
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	VATAccountingLocalization.ReportChangeControlResults(ControlResults, Document, Cancel);
	
EndProcedure

// Checks whether it is necessary to generate movements based on VAT registers
//
// Parameters:
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	
// Returns:
// 	Boolean - True if VAT movement is necessary
Function VATRegistrationRequired(Registers) Export 
	
	For Each KeyAndValue In VATRegisters_() Do
		If DocumentsPosting.RequiresTableForRegisteredRecords(KeyAndValue.Key, Registers) Then
			Return True;
		EndIf;
	EndDo;
	
	AdditionalTablesOfConduct = New Array; // Tables are obtained during the execution, but are not recorded in registers.
	VATAccountingLocalization.SupplementPostingTables(AdditionalTablesOfConduct);
	For Each TableName In AdditionalTablesOfConduct Do
		If DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Supplements the text of the request for the document with the text of the reflection of the balance of own goods in the accounting of incoming VAT.
// The operation generates traffic registers Nbsprecycling, Annyeonghaseyo.
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the request to receive the data of the purchase document.
// 	     The request should return a selection with the following fields:
// 	    Attributes for ENTERING The Balance Of Goods.
// 	     * Period - Date - The date when the Balance entry was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * OBEntry22 - Boolean - Indicates that the document was created on version 2.2 or earlier.
// 	     * Organization - CatalogRef.Companies - The organization where the Balance of goods is entered.
// 	     * Department - CatalogRef.BusinessStructure - The division where the Balance of goods is entered.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Supplier of goods.
// 	     * BatchPurchaseOfGoods - DefinedType.TaxInvoice - Link to the document-the batch of goods purchased.
// 	     * VATActivityType - EnumRef.VATTaxationTypes - the activity type of separate VAT accounting for which Balances of goods are entered.
// 	    information about the Balance of goods.
// 	     * Products - CatalogRef.Products - product.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - characteristics of goods.
// 	     * VATRate - CatalogRef.VATRates - The product's VAT rate.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of Balance of goods.
// 	     * CCDNumber - CatalogRef.CCDNumbers - The number of the CCD through which the goods were imported.
// 	     * AmountExcludingVATCompl - Number - The amount excluding VAT of the Balance of the goods in the currency of Local accounting.
// 	     * VATAmountCompl - Number - The amount of VAT of the Balance of the goods in the currency of Local accounting. 
// 	     * VATAmountMan - Number - The amount of VAT of the Balance of the goods in the currency of the Man. accounting.
// 	     * RowID - String, UUID - ID of the line in the Balance entry document.
//
Procedure ReflectEntryOfBalancesOfOwnGoods(Query, QueryTexts, Registers, TextProducts_1) Export
	
	#Region VATInvoiced
	
	Query.SetParameter("ManagementAccountingOfOrganizationsIsIncluded_", CalculationOfCostCached.CompanyManagementAccounting());
	Query.SetParameter("StartDateOfManagementAccountingOfOrganizations", CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations());

	QueryTextVATInvoiced = 
	"SELECT
	|	Goods.Ref AS Recorder,
	|	Goods.Period AS Period,
	|	Goods.Organization AS Organization,
	|	Goods.BatchPurchaseOfGoods AS TaxInvoice,
	|	Goods.Counterparty AS Vendor,
	|	ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass,
	|							VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	Goods.VATRate AS VATRate,
	|	Goods.VATActivityType AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|
	|	Goods.AmountExcludingVATCompl AS AmountExcludingVAT,
	|	Goods.VATAmountCompl    AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Goods.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN Goods.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|
	|	VALUE(Enum.EventsChargedVAT.EmptyRef) AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
	|	Goods.RowID AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	Goods.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryCostOfOwnedInventoryInOurWarehouse) AS BusinessTransactionSetting
	|FROM
	|	#Goods AS Goods
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Goods.Products = CatProducts.Ref
	|WHERE
	|	Goods.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND ((&OBEntry22 AND Goods.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.ExportSale),
	|				VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks),
	|				VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)))
	|	   OR Goods.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage))
	|";
	
	#EndRegion

	If ValueIsFilled(Query.Parameters)
		And Query.Parameters.Property("Ref")
		And TypeOf(Query.Parameters.Ref) = Type("DocumentRef.OBEntryGoods") Then
		
		QueryTextVATInvoiced = StrReplace(QueryTextVATInvoiced, "&OBEntry22", "FALSE")
	Else
		QueryTextVATInvoiced = StrReplace(QueryTextVATInvoiced, "&OBEntry22", "Goods.OBEntry22");
	EndIf;

	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATInvoiced", Registers) Then
		ReflectionTemplateTexts.Insert("VATInvoiced", QueryTextVATInvoiced);
	EndIf;
	
	TextsOfDocumentDataRequests = New Structure("Goods", TextProducts_1);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectEntryOfBalancesOfOwnGoods(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

// Supplements the texts of the request for the document with texts reflecting the purchase of goods, works, services, and other assets in the accounting of incoming VAT.
// The operation generates movements according to the NDSPREDECLARED registers, by party distribution (if VAT is subject to distribution by base), and data on the basis of invoice accounts.
// 
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	ValueText_ - String - The text of the request to receive the data of the purchase document.
// 	     The request should return a selection with the following fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization in which the acquisition is reflected.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the acquisition document is registered.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Supplier of values.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract for the acquisition of valuables.
// 	     * Shipper - CatalogRef.Counterparties - Shipper of valuables.
// 	     * DocumentAcquisitions - DefinedType.TaxInvoice - Link to the purchase document.
// 	     * ErrorCorrection - Boolean - Indicates that the purchase document is being corrected.
// 	     * AdjustmentUnderApprovalOfParties - Boolean - An indication that the purchase document is being adjusted by agreement of the parties.
// 	     * ReduceAmountVATDeduction - Boolean - A sign that the adjustment by agreement of the parties to the reduction will not restore the VAT in the sales book, but will reduce the VAT deductible for the original purchase document in the purchase book (as ISF).
// 	     * PurchaseAdjustmentDocument - DocumentRef.PurchaseAdjustment - Link to the purchase adjustment document. 
// 	                                           Filled in if errors have been corrected or side alignment has been adjusted.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the acquisition document.
// 	     * VATActivityType - EnumRef.VATTaxationTypes - Type of activity of separate VAT accounting of the purchase document.
// 	                            Determines the procedure for accounting for incoming VAT, if it could not be determined by Purpose or by Expense Item.
// 	     * PurchasePerBatchOfProduction - Boolean - A sign that the line of business under which the acquisition is reflected is stored in the analytics of the direction of activity of the Production Party.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business transaction to be reflected in financial accounting.
// 	     * FinRecordID - String - A unique identifier that is used to link movements in corresponding financial registers.
// 	    Purchased goods.
// 	     * Products - CatalogRef.Products - The purchased product, work or service.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the purchased product, work or service.
// 	     * VATRate - CatalogRef.VATRates - VAT rate of purchased valuables.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of purchased goods.
// 	     * CCDNumber - CatalogRef.CCDNumbers - The CCD number for which the purchased goods were imported.
// 	     * RowID - String, UUID - ID of the line of the purchase document for receiving 
// 	                                                              the amounts of the document in the currency of management or regulated accounting.
// 	    analytics of accounting for purchased goods, works, services, and other assets.
// 	     * LineOfBusiness - CatalogRef.LinesOfBusiness - Line of business, under which the acquisition is reflected, for item-by-item costs.
// 	                                 For nomenclature costs, the line of business is taken from the Destination.
// 	     * LineOfBusinessOfProductionParty - CatalogRef.LinesOfBusiness - The line of business under which the acquisition of a production batch is reflected is used when the Attribute of the acquisition of a production batch = True.
// 	     * ToExpenseAs - Boolean - Indicates whether the acquired value has been written off for expenses.
// 	     * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - The item of expenditure on which the acquired values are written off.
// 	     * DimensionOfExpenses - Characteristic.ExpenseItems - Cost reflection analytics.
// 	     * ItemOfOtherAssets - ChartOfCharacteristicTypesRef.AssetLiabilityItems - The article reflects the acquisition of other assets.
// 	     * AnalyticsOfOtherAssets - Characteristic.AssetLiabilityItems - Analytics of reflection of other assets.
// 	     * Purpose - CatalogRef.Assignments - In the case of acquisition for a separate need determines the type of activity of separate VAT accounting.
// 	     * AccountingDivision - CatalogRef.BusinessStructure - A division that accounts for purchased goods, works, services, and assets.
//
Procedure ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_) Export
	
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost", ActivitiesVATIsIncludedInCost());
	Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	Query.SetParameter("StartDateOfVATAccountingByLineOfBusiness", AccountingSettings().StartDateOfVATAccountingByLineOfBusiness);
	Query.SetParameter("ManagementAccountingOfOrganizationsIsIncluded_", CalculationOfCostCached.CompanyManagementAccounting());
	Query.SetParameter("StartDateOfManagementAccountingOfOrganizations", CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations());
	
	If Query.Parameters.Property("CompanyRecipient") And Query.Parameters.Property("Period") Then
		Query.SetParameter("UseSeparateAccountingOfGoodsForVATTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
		Query.SetParameter("GenerateVATChargedWhenIncludingInCost",
			AccountingPoliciesTaxSettingsCached.GenerateVATChargedWhenIncludingInCost(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
		Query.SetParameter("WriteOffVATByExpensesThatAreNotRecordedInTA",
			AccountingPoliciesTaxSettingsCached.WriteOffVATByExpensesThatAreNotRecordedInTA(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
		Query.SetParameter("UseSeparateFAAccountingByTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateFAAccountingByVATTaxation(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
		Query.SetParameter("UseSeparateAccountingOfItemByItemProductionCostsForVATTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateAccountingOfItemizedProductionCostsForVATTaxation(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
	ElsIf Query.Parameters.Property("Organization") And Query.Parameters.Property("Period") Then
		Query.SetParameter("UseSeparateAccountingOfGoodsForVATTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Query.Parameters.Organization, Query.Parameters.Period));
		Query.SetParameter("GenerateVATChargedWhenIncludingInCost",
			AccountingPoliciesTaxSettingsCached.GenerateVATChargedWhenIncludingInCost(Query.Parameters.Organization, Query.Parameters.Period));
		Query.SetParameter("WriteOffVATByExpensesThatAreNotRecordedInTA",
			AccountingPoliciesTaxSettingsCached.WriteOffVATByExpensesThatAreNotRecordedInTA(Query.Parameters.Organization, Query.Parameters.Period));
		Query.SetParameter("UseSeparateFAAccountingByTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateFAAccountingByVATTaxation(Query.Parameters.Organization, Query.Parameters.Period));
		Query.SetParameter("UseSeparateAccountingOfItemByItemProductionCostsForVATTaxation",
			AccountingPoliciesTaxSettingsCached.SeparateAccountingOfItemizedProductionCostsForVATTaxation(Query.Parameters.Organization, Query.Parameters.Period));
	Else
		Query.SetParameter("UseSeparateAccountingOfGoodsForVATTaxation", True);
		Query.SetParameter("GenerateVATChargedWhenIncludingInCost", False);
		Query.SetParameter("WriteOffVATByExpensesThatAreNotRecordedInTA", False);
		Query.SetParameter("UseSeparateFAAccountingByTaxation", GetFunctionalOption("UseSeparateFAAccountingByTaxation"));
		Query.SetParameter("UseSeparateAccountingOfItemByItemProductionCostsForVATTaxation", False);
	EndIf;
	
#Region VATInvoiced
	
	QueryTextVATInvoiced = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|			THEN CASE
	|				WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|						OR (Assets_.ReduceAmountVATDeduction AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0)
	|					THEN Assets_.OriginalTradeDocument
	|				ELSE Assets_.PurchaseAdjustmentDocument
	|			END
	|		ELSE Assets_.DocumentAcquisitions
	|	END AS TaxInvoice,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|				AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0
	|				AND NOT Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				AND NOT Assets_.ReduceAmountVATDeduction
	|			THEN VALUE(Enum.AssetKinds.ReverseByCorrectiveTaxInvoice)
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|				AND NOT Assets_.ToExpenseAs = TRUE
	|				AND NOT CatInventoryKinds.Ref IS NULL 
	|               AND &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN ISNULL(CatInventoryKinds.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) 
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|				AND NOT Assets_.ToExpenseAs = TRUE
	|			THEN ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN ExpenseItems.VATAssetTaxClass
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN CASE
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.Assets)
	|					THEN VALUE(Enum.AssetKinds.FA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.IntangibleAssets)
	|					THEN VALUE(Enum.AssetKinds.IA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.ConstructionObjects)
	|					THEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			END
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                                                             AS AssetTaxClass,
	|	Assets_.VATRate                                                AS VATRate,
	|	CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END 
	|		WHEN NOT ExpenseItems.Ref IS NULL AND ExpenseItems.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToInventoryCost) 
	|			THEN 
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE 
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END AS VATActivityType,
	|	CASE
	|		WHEN Assets_.ErrorCorrection 
	|			THEN Assets_.PurchaseAdjustmentDocument
	|		ELSE UNDEFINED
	|	END AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN CASE
	|				WHEN Assets_.PurchasePerBatchOfProduction AND ISNULL(LinesOfBusinessOfProductionParty.CostAccounting, FALSE)
	|						THEN Assets_.LineOfBusinessOfProductionParty
	|				WHEN ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					THEN 
	|					CASE WHEN ISNULL(Assignments.LineOfBusiness.CostAccounting, FALSE) THEN
	|							Assignments.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|					WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|						THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					ELSE
	|						CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|							Assets_.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|
	|	CASE
	|		WHEN FALSE
	|			THEN VALUE(Enum.EventsChargedVAT.EmptyRef)
	|		ELSE
	|			VALUE(Enum.EventsChargedVAT.EmptyRef)
	|	END AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
	|	Assets_.RowID AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	#Assets_ AS Assets_
	|	LEFT JOIN 
	|		Catalog.Products AS CatProducts
	|	ON 
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		Assets_.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON
	|		Assets_.ItemOfOtherAssets = AssetLiabilityItems.Ref
	|
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.Products = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusinessOfProductionParty
	|	ON
	|		Assets_.LineOfBusinessOfProductionParty = LinesOfBusinessOfProductionParty.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (NOT CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		WHEN NOT ExpenseItems.Ref IS NULL AND ExpenseItems.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END IN (&TypesOfTaxationVATIsIncludedInCost)
	|		OR &GenerateVATChargedWhenIncludingInCost
	|		OR &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting)
	|	AND NOT ISNULL(Assignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|			THEN CASE
	|				WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|						OR (Assets_.ReduceAmountVATDeduction AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0)
	|					THEN Assets_.OriginalTradeDocument
	|				ELSE Assets_.PurchaseAdjustmentDocument
	|			END
	|		ELSE Assets_.DocumentAcquisitions
	|	END AS TaxInvoice,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|				AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0
	|				AND NOT Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				AND NOT Assets_.ReduceAmountVATDeduction
	|			THEN VALUE(Enum.AssetKinds.ReverseByCorrectiveTaxInvoice)
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|				AND NOT Assets_.ToExpenseAs = TRUE
	|				AND NOT CatInventoryKinds.Ref IS NULL
	|               AND &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN ISNULL(CatInventoryKinds.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) 
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|				AND NOT Assets_.ToExpenseAs = TRUE
	|			THEN ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN ExpenseItems.VATAssetTaxClass
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN CASE
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.Assets)
	|					THEN VALUE(Enum.AssetKinds.FA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.IntangibleAssets)
	|					THEN VALUE(Enum.AssetKinds.IA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.ConstructionObjects)
	|					THEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			END
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                                                             AS AssetTaxClass,
	|	Assets_.VATRate                                                AS VATRate,
	|	CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END 
	|		WHEN NOT ExpenseItems.Ref IS NULL AND ExpenseItems.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToInventoryCost) 
	|			THEN 
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE 
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END AS VATActivityType,
	|	CASE
	|		WHEN Assets_.ErrorCorrection 
	|			THEN Assets_.PurchaseAdjustmentDocument
	|		ELSE UNDEFINED
	|	END AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN CASE
	|				WHEN Assets_.PurchasePerBatchOfProduction AND ISNULL(LinesOfBusinessOfProductionParty.CostAccounting, FALSE)
	|						THEN Assets_.LineOfBusinessOfProductionParty
	|				WHEN ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					THEN 
	|					CASE WHEN ISNULL(Assignments.LineOfBusiness.CostAccounting, FALSE) THEN
	|							Assignments.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|					WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|						THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					ELSE
	|						CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|							Assets_.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses)
	|		ELSE VALUE(Enum.EventsChargedVAT.IncludeVATInCostExpenses)
	|	END AS Event,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN UNDEFINED
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	END AS CorVATActivityTypes,
	|	Assets_.RowID AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.AccountingDivision AS Department,
	|	Assets_.LineOfBusiness AS CorLineOfBusiness,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN &ExpenseItemVATWriteOff
	|		ELSE Assets_.ExpenseItem
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN &ExpenseDimensionVATWriteOff
	|		ELSE Assets_.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	CASE
	|		WHEN Assets_.RowID = """"
	|			THEN Assets_.FinRecordID
	|		ELSE Assets_.RowID
	|	END AS FinRecordID,
	|	CASE
	|		WHEN &WriteOffVATByExpensesThatAreNotRecordedInTA
	|				AND NOT ExpenseItems.Ref IS NULL
	|				AND NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	END AS BusinessTransactionSetting
	|FROM
	|	#Assets_ AS Assets_
	|	LEFT JOIN 
	|		Catalog.Products AS CatProducts
	|	ON 
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		Assets_.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON
	|		Assets_.ItemOfOtherAssets = AssetLiabilityItems.Ref
	|
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.Products = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusinessOfProductionParty
	|	ON
	|		Assets_.LineOfBusinessOfProductionParty = LinesOfBusinessOfProductionParty.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		WHEN NOT ExpenseItems.Ref IS NULL AND ExpenseItems.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND &GenerateVATChargedWhenIncludingInCost
	|		OR
	|	(&WriteOffVATByExpensesThatAreNotRecordedInTA AND NOT ExpenseItems.Ref IS NULL AND NOT ExpenseItems.EnteredInTaxAccounting))
	|	AND NOT ISNULL(Assignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|";
	
#EndRegion

#Region LotsVATForAllocation
	
	QueryTextLotsVATForAllocation =
	// Formation of movements on distributable expenses
	"SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	Assets_.AccountingDivision AS Department,
	|	CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN Assets_.ExpenseItem
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN Assets_.ItemOfOtherAssets
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN Assets_.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN Assets_.AnalyticsOfOtherAssets
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	| 			THEN CASE
	|				WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													 VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|						OR (Assets_.ReduceAmountVATDeduction AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0)
	|					THEN Assets_.OriginalTradeDocument
	|				ELSE Assets_.PurchaseAdjustmentDocument
	|			END
	|		ELSE Assets_.DocumentAcquisitions
	|	END AS ExpenseReceiptDocument,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|				AND NOT Assets_.ToExpenseAs = TRUE
	|			THEN ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN ExpenseItems.VATAssetTaxClass
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN CASE
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.Assets)
	|					THEN VALUE(Enum.AssetKinds.FA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.IntangibleAssets)
	|					THEN VALUE(Enum.AssetKinds.IA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.ConstructionObjects)
	|					THEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			END
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	Assets_.VATRate AS VATRate,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN CASE
	|				WHEN Assets_.PurchasePerBatchOfProduction AND ISNULL(LinesOfBusinessOfProductionParty.CostAccounting, FALSE)
	|						THEN Assets_.LineOfBusinessOfProductionParty
	|				WHEN ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					THEN 
	|					CASE WHEN ISNULL(Assignments.LineOfBusiness.CostAccounting, FALSE) THEN
	|							Assignments.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|					WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|						THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					ELSE
	|						CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|							Assets_.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END AS VATActivityType,
	|	
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS LocalCost,
	|	DocumentAmounts_.VATAmountCompl AS VATLocal,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|	
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem_,
	|	UNDEFINED AS ExpensesPostingDimension,
	|	FALSE AS LotCalculation,
	|	DATETIME(1,1,1) AS BasePeriod,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
	|
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		Assets_.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON
	|		Assets_.ItemOfOtherAssets = AssetLiabilityItems.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusinessOfProductionParty
	|	ON
	|		Assets_.LineOfBusinessOfProductionParty = LinesOfBusinessOfProductionParty.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes, VALUE(Enum.ItemsTypes.Work_5))
	|			THEN
	|				CASE
	|					WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateAccountingOfGoodsForVATTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|	AND (NOT ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) IN (
	|			VALUE(Enum.CostAllocationOptions.ToInventoryCost),
	|			VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|		OR ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) = VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|	AND NOT (Assets_.AdjustmentUnderApprovalOfParties
	|			AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0
	|			AND NOT Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|												VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			AND NOT Assets_.ReduceAmountVATDeduction)
	|	AND NOT (&WriteOffVATByExpensesThatAreNotRecordedInTA
	|		AND NOT ExpenseItems.Ref IS NULL AND NOT ExpenseItems.EnteredInTaxAccounting)
	|
	// The condition for selecting records must match the function:
	// Batches of other expenses.The text of the request for the table of the author's partyand other expenses()
	|	AND NOT (ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			AND ExpenseItems.SeparateVATAccountingOption <> VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			AND &UseSeparateAccountingOfItemByItemProductionCostsForVATTaxation)
	|
	|UNION ALL
	|
	// Formation of movements on indirect expenses for raw materials exports
	|SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	Assets_.AccountingDivision AS Department,
	|	Assets_.ExpenseItem AS ExpenseItem,
	|	Assets_.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	| 			THEN CASE
	|				WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|						OR Assets_.ReduceAmountVATDeduction
	|					THEN Assets_.OriginalTradeDocument
	|				ELSE Assets_.PurchaseAdjustmentDocument
	|			END
	|		ELSE Assets_.DocumentAcquisitions
	|	END AS ExpenseReceiptDocument,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|				AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0
	|				AND NOT Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|													VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|				AND NOT Assets_.ReduceAmountVATDeduction
	|			THEN VALUE(Enum.AssetKinds.ReverseByCorrectiveTaxInvoice)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	Assets_.VATRate AS VATRate,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN
	|				CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|					Assets_.LineOfBusiness
	|				ELSE
	|					UNDEFINED
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	Assets_.VATActivityType AS VATActivityType,
	|	
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS LocalCost,
	|	DocumentAmounts_.VATAmountCompl AS VATLocal,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|	
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem_,
	|	UNDEFINED AS ExpensesPostingDimension,
	|	FALSE AS LotCalculation,
	|	DATETIME(1,1,1) AS BasePeriod,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
	|
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		Assets_.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ExportOfCommoditiesServicesWorks)
	|	AND ExpenseItems.SeparateVATAccountingOption <> VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|	AND (ExpenseItems.CostAllocationOptionLocal IN
	|			(VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)))
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|	AND NOT (Assets_.AdjustmentUnderApprovalOfParties
	|			AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) < 0
	|			AND NOT Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|												VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			AND NOT Assets_.ReduceAmountVATDeduction)
	|	AND (NOT &WriteOffVATByExpensesThatAreNotRecordedInTA
	|		OR ExpenseItems.EnteredInTaxAccounting)
	|
	|UNION ALL
	|
	// Formation of movements by OS and HMA
	|SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	Assets_.AccountingDivision AS Department,
	|	CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN Assets_.ExpenseItem
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN Assets_.ItemOfOtherAssets
	|		ELSE UNDEFINED
	|	END AS ExpenseItem,
	|	CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN Assets_.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN Assets_.AnalyticsOfOtherAssets
	|		ELSE UNDEFINED
	|	END AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	|			THEN Assets_.PurchaseAdjustmentDocument
	|		ELSE Assets_.DocumentAcquisitions
	|	END AS ExpenseReceiptDocument,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|			THEN ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN ExpenseItems.VATAssetTaxClass
	|		WHEN NOT AssetLiabilityItems.Ref IS NULL
	|			THEN CASE
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.Assets)
	|					THEN VALUE(Enum.AssetKinds.FA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.IntangibleAssets)
	|					THEN VALUE(Enum.AssetKinds.IA)
	|				WHEN VALUETYPE(Assets_.AnalyticsOfOtherAssets) = TYPE(Catalog.ConstructionObjects)
	|					THEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|			END
	|				ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	Assets_.VATRate AS VATRate,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN
	|				CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|					Assets_.LineOfBusiness
	|				ELSE
	|					UNDEFINED
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|	END AS VATActivityType,
	|
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS LocalCost,
	|	DocumentAmounts_.VATAmountCompl AS VATLocal,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|	
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem_,
	|	UNDEFINED AS ExpensesPostingDimension,
	|	FALSE AS LotCalculation,
	|	DATETIME(1,1,1) AS BasePeriod,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
	|
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		Assets_.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON
	|		Assets_.ItemOfOtherAssets = AssetLiabilityItems.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (NOT ExpenseItems.Ref IS NULL OR NOT AssetLiabilityItems.Ref IS NULL)
	|	AND (CASE
	|		WHEN NOT ExpenseItems.Ref IS NULL
	|			THEN
	|				CASE
	|					WHEN ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|						                                                           VALUE(Enum.AssetKinds.IA))
	|						  AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|						  AND ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						  AND &UseSeparateFAAccountingByTaxation
	|						THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|					WHEN ISNULL(ExpenseItems.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|						THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|					WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					      AND Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|						THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					ELSE Assets_.VATActivityType
	|				END
	|		ELSE
	|			CASE
	|				WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|					  AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|					THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE Assets_.VATActivityType
	|			END
	|		END = VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		OR (ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			AND ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA),
	|			                                                           VALUE(Enum.AssetKinds.IA)))
	|			AND &UseSeparateFAAccountingByTaxation)
	|	AND ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|	AND NOT (&WriteOffVATByExpensesThatAreNotRecordedInTA
	|		AND NOT ExpenseItems.Ref IS NULL AND NOT ExpenseItems.EnteredInTaxAccounting)
	// The condition for selecting records must match the function:
	// Batches of other expenses.The text of the request for the table of the author's partyand other expenses()
	|	AND NOT (ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			AND ExpenseItems.SeparateVATAccountingOption <> VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			AND &UseSeparateAccountingOfItemByItemProductionCostsForVATTaxation)
	|";
	
#EndRegion
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATInvoiced", Registers) Then
		ReflectionTemplateTexts.Insert("VATInvoiced", QueryTextVATInvoiced);
	EndIf;
	If DocumentsPosting.RequiresTableForRegisteredRecords("LotsVATForAllocation", Registers) Then
		ReflectionTemplateTexts.Insert("LotsVATForAllocation", QueryTextLotsVATForAllocation);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Assets_", ValueText_);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

// Supplements the texts of the document reflection request with texts reflecting the return of goods from the buyer.
// The operation generates movements according to the registers NDSPREDECLARED, ndsprecords, purchase book, datafoundationsfacture accounts.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	ValueText_ - String - The text of the receipt request from the refund document.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization where the refund is reflected.
// 	     * Department - CatalogRef.BusinessStructure - The division where the refund is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - The buyer returning the goods.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract with the buyer.
// 	     * Shipper - CatalogRef.Counterparties - The shipper of the returned goods.
// 	     * CustomerVATExempt - Boolean - Indicates that the buyer returning the goods is not a VAT payer and an invoice is not expected from him.
// 	     * RetailCustomer - Boolean - Indicates that the product is being returned by a retail customer.
// 	     * FundsReturnedToRetailBuyer - Boolean - Indicates that the funds have been returned to the retail customer.
// 	     * CashReturnDocumentNumberToRetailBuyer - String - The number of the refund document to the retail buyer.
// 	     * DateOfDocumentOfReturnOfCashToRetailBuyer - Date - The date of the refund document to the retail buyer.
// 	     * DocumentReturnPolicy - DefinedType.TaxInvoice - Document of return of goods.
// 	     * DocumentSalesOfGoodsAndServices - DefinedType.TaxInvoice - A link to the sales document for which the refund is issued. 
// 	                                                           If the refund is from a non-payer of VAT, then filling out the sales document is mandatory.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlements with the client.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT refund taxation in case of a refund from the VAT payer. 
// 	                                                                        If the buyer is not a VAT payer, then the taxation of the sale.
// 	     * VATActivityType - EnumRef.VATTaxationTypes - The type of activity of separate VAT accounting, which includes incoming VAT.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business transaction to be reflected in financial accounting.
// 	     * FinRecordID - String - A unique identifier that is used to link movements in corresponding financial registers.
// 	    Returned items.
// 	     * Products - CatalogRef.Products - The returned product.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the returned product.
// 	     * Series - CatalogRef.ItemsBatches - a series of Products.
// 	     * ProductsInSet - CatalogRef.Products - The set to be returned.
// 	     * ItemVariantOfSet - CatalogRef.ItemsCharacteristics - Characteristics of the returned set.
// 	     * Count - Number - number of returned items
// 	     * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - The unit of measurement of the returned product.
// 	     * QuantityByGBRN - Number - the quantity of the product in traceability units.
// 	     * VATRate - CatalogRef.Products - VAT rate of returned valuables.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of the returned product.
// 	     * FEACNCode - CatalogRef.FEACN - HS code of the returned product.
// 	     * CCDNumber - CatalogRef.CCDNumbers - The CCD number of the returned product.
// 	     * RowID - String, UUID - ID of the return document line.
// 	     * LineNumber - Number - line number of the original (primary) invoice.
// 	    analytics for tracking returned items.
// 	     * LineOfBusiness - CatalogRef.LinesOfBusiness - The line of activity under which the refund is reflected.
// 	     * Purpose - CatalogRef.Assignments - A separate need provided by the return.
//
Procedure ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, ValueText_) Export
	
	AccountingSettings = AccountingSettings();
	
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost", ActivitiesVATIsIncludedInCost());
	Query.SetParameter("InventoryTypesOwn", VATAccountingERPInternal.InventoryTypesOwn());
	Query.SetParameter("StartDateOfVATAccountingByLineOfBusiness", AccountingSettings.StartDateOfVATAccountingByLineOfBusiness);
	Query.SetParameter("DateWhenRefundsAreReflectedInCorrectiveSF", AccountingSettings.DateWhenRefundsAreReflectedInCorrectiveSF);
	Query.SetParameter("ManagementAccountingOfOrganizationsIsIncluded_", CalculationOfCostCached.CompanyManagementAccounting());
	Query.SetParameter("StartDateOfManagementAccountingOfOrganizations", CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations());
	
#Region VATInvoiced
	
	QueryTextVATInvoiced = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Assets_.Ref                        AS Recorder,
	|	Assets_.Period                        AS Period,
	|	Assets_.Organization                   AS Organization,
	|	CASE
	|		WHEN Assets_.CustomerVATExempt 
	|			THEN Assets_.DocumentSalesOfGoodsAndServices
	|		ELSE Assets_.DocumentReturnPolicy
	|	END                                  AS TaxInvoice,
	|	CASE
	|		WHEN Assets_.CustomerVATExempt 
	|			THEN Assets_.Organization 
	|		ELSE Assets_.Counterparty
	|	END                                  AS Vendor,
	|	ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, 
	|		VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	Assets_.VATRate                     AS VATRate,
	|	CASE 
	|		WHEN Assets_.CustomerVATExempt
	|			THEN Assets_.VATTaxation
	|		WHEN ISNULL(Assignments.VATActivityType,
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Assignments.VATActivityType
	|		ELSE Assets_.VATActivityType
	|	END                                  AS VATActivityType,
	|	UNDEFINED                           AS CorrectedTaxInvoice,
	|	UNDEFINED                           AS SaleExport,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN CASE WHEN ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					THEN 
	|					CASE WHEN ISNULL(Assignments.LineOfBusiness.CostAccounting, FALSE) THEN
	|							Assignments.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|					ELSE 
	|						CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|							Assets_.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|	
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal > 0
	|			THEN -DocumentAmounts_.VATBaseLocal
	|		WHEN DocumentAmounts_.VATBaseLocal < 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		WHEN DocumentAmounts_.AmountExcludingVATCompl > 0
	|			THEN -DocumentAmounts_.AmountExcludingVATCompl
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END                                  AS AmountExcludingVAT,
	|	CASE
	|		WHEN DocumentAmounts_.VATAmountCompl > 0
	|			THEN -DocumentAmounts_.VATAmountCompl
	|		ELSE DocumentAmounts_.VATAmountCompl
	|	END                                  AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			  AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN 
	|				CASE
	|					WHEN DocumentAmounts_.VATAmountMan > 0
	|				THEN -DocumentAmounts_.VATAmountMan
	|					ELSE DocumentAmounts_.VATAmountMan
	|				END
	|			ELSE 0
	|	END                                  AS VATManag,
	|	
	|	VALUE(Enum.EventsChargedVAT.EmptyRef)       AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)        AS CorVATActivityTypes,
	|	Assets_.RowID                                      AS RowID,
	|	FALSE                                                              AS PeriodEndTransaction,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)            AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)         AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)      AS ExpenseItem,
	|	UNDEFINED                                                      AS DimensionOfExpenses,
	|	Assets_.FinRecordID                                   AS FinRecordID,
	|	Assets_.BusinessTransactionSetting                           AS BusinessTransactionSetting
	|
	|FROM
	|	#Assets_ AS Assets_
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|	
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND CatInventoryKinds.InventoryType IN (&InventoryTypesOwn)
	|	AND CASE 
	|		WHEN Assets_.Period < &DateWhenRefundsAreReflectedInCorrectiveSF AND (Assets_.CustomerVATExempt OR Assets_.RetailCustomer)
	|			THEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		ELSE
	|			NOT (CASE
	|					WHEN ISNULL(Assignments.VATActivityType,
	|							VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|						THEN Assignments.VATActivityType
	|					ELSE Assets_.VATActivityType
	|				END) IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND Assets_.Period < &DateWhenRefundsAreReflectedInCorrectiveSF
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Assets_.Ref                        AS Recorder,
	|	Assets_.Period                        AS Period,
	|	Assets_.Organization                   AS Organization,
	|	CASE
	|		WHEN Assets_.CustomerVATExempt
	|			THEN Assets_.DocumentSalesOfGoodsAndServices
	|		ELSE Assets_.DocumentReturnPolicy
	|	END                                  AS TaxInvoice,
	|	CASE
	|		WHEN Assets_.CustomerVATExempt 
	|			THEN Assets_.Organization 
	|		ELSE Assets_.Counterparty
	|	END                                  AS Vendor,
	|	ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	Assets_.VATRate                     AS VATRate,
	|	CASE 
	|		WHEN Assets_.CustomerVATExempt
	|			THEN Assets_.VATTaxation
	|		WHEN ISNULL(Assignments.VATActivityType,
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Assignments.VATActivityType
	|		ELSE Assets_.VATActivityType
	|	END                                  AS VATActivityType,
	|	UNDEFINED                           AS CorrectedTaxInvoice,
	|	UNDEFINED                           AS SaleExport,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			THEN CASE WHEN ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|					THEN 
	|					CASE WHEN ISNULL(Assignments.LineOfBusiness.CostAccounting, FALSE) THEN
	|							Assignments.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|					ELSE 
	|						CASE WHEN ISNULL(LinesOfBusiness.CostAccounting, FALSE) THEN
	|							Assets_.LineOfBusiness
	|						ELSE
	|							UNDEFINED
	|						END
	|				END
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal > 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		WHEN DocumentAmounts_.VATBaseLocal < 0
	|			THEN -DocumentAmounts_.VATBaseLocal
	|		WHEN DocumentAmounts_.AmountExcludingVATCompl > 0
	|			THEN DocumentAmounts_.AmountExcludingVATCompl
	|		ELSE -DocumentAmounts_.AmountExcludingVATCompl
	|	END                                  AS AmountExcludingVAT,
	|	CASE
	|		WHEN DocumentAmounts_.VATAmountCompl > 0
	|			THEN DocumentAmounts_.VATAmountCompl
	|		ELSE -DocumentAmounts_.VATAmountCompl
	|	END                                  AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			  AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN 
	|				CASE
	|					WHEN DocumentAmounts_.VATAmountMan > 0
	|				THEN DocumentAmounts_.VATAmountMan
	|					ELSE -DocumentAmounts_.VATAmountMan
	|				END
	|			ELSE 0
	|	END                                  AS VATManag,
	|
	|	VALUE(Enum.EventsChargedVAT.VATAcceptedForDeduction)   AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)        AS CorVATActivityTypes,
	|	Assets_.RowID                                      AS RowID,
	|	FALSE                                                              AS PeriodEndTransaction,
	|	VALUE(Catalog.BusinessStructure.EmptyRef)            AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef)         AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)      AS ExpenseItem,
	|	UNDEFINED                                                      AS DimensionOfExpenses,
	|	Assets_.FinRecordID                                   AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATDeduction) AS BusinessTransactionSetting
	|
	|FROM
	|	#Assets_ AS Assets_
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		Catalog.LinesOfBusiness AS LinesOfBusiness
	|	ON
	|		Assets_.LineOfBusiness = LinesOfBusiness.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	CASE 
	|		WHEN Assets_.Period >= &DateWhenRefundsAreReflectedInCorrectiveSF
	|			THEN FALSE
	|		WHEN Assets_.CustomerVATExempt 
	|			THEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		WHEN Assets_.RetailCustomer
	|			THEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					AND Assets_.FundsReturnedToRetailBuyer
	|		ELSE FALSE
	|	END
	|	AND Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Assets_.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|";
	
#EndRegion

#Region VATRegisterRecords
	QueryTextVATRegisterRecords = 
	"SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	CASE
	|		WHEN Assets_.ReturnOfGoodsViaCommissionAgent
	|			THEN Assets_.ConsignedGoodsCustomer
	|		ELSE Assets_.Counterparty
	|	END AS Counterparty,
	|	Assets_.DocumentReturnPolicy AS TaxInvoice,
	|	Assets_.VATRate AS VATRate,
	|	ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN -DocumentAmounts_.VATBaseLocal
	|		ELSE -DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	-DocumentAmounts_.VATAmountCompl AS VAT,
	|	-DocumentAmounts_.VATAmountMan AS VATManag,
	|	Assets_.ARAPObject AS ARAPObject,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|	
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND CatInventoryKinds.InventoryType IN (&InventoryTypesOwn)
	|	AND Assets_.Period >= &DateWhenRefundsAreReflectedInCorrectiveSF
	|
	|UNION ALL 
	|
	|SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	Assets_.Counterparty AS Counterparty,
	|	Assets_.DocumentReturnPolicy AS TaxInvoice,
	|	Assets_.VATRate AS VATRate,
	|	ISNULL(CatProducts.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	DocumentAmounts_.VATAmountMan AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATDeduction) AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|	
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|WHERE
	|	CASE 
	|		WHEN Assets_.Period >= &DateWhenRefundsAreReflectedInCorrectiveSF
	|			THEN FALSE
	|		WHEN Assets_.CustomerVATExempt 
	|			THEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		WHEN Assets_.RetailCustomer
	|			THEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|					AND Assets_.FundsReturnedToRetailBuyer
	|		ELSE FALSE
	|	END
	|	AND Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Assets_.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|";
#EndRegion

	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATInvoiced", Registers) Then 
		ReflectionTemplateTexts.Insert("VATInvoiced", QueryTextVATInvoiced);
	EndIf;
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATRegisterRecords", Registers) Then 
		ReflectionTemplateTexts.Insert("VATRegisterRecords", QueryTextVATRegisterRecords);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Assets_", ValueText_);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

// Supplements the texts of the document request with texts reflecting the sale of goods, services, works or other assets in VAT accounting.
// The operation generates movements in the registers of Sales book records, sales Realization0 (in the case of export sales), data on the basis of invoice accounts.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//  
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	ValueText_ - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization on whose behalf the implementation is reflected.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the implementation is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Buyer of valuables.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract of implementation.
// 	     * Shipper - CatalogRef.Counterparties - Shipper of goods.
// 	     * GoodsRecipient - CatalogRef.Counterparties - Consignee of goods.
// 	     * RetailSaleOfGoods - Boolean - A sign that the product is sold at retail.
// 	     * DocumentSalesOfGoodsAndServices - DefinedType.TaxInvoice - Link to the implementation document.
// 	     * ErrorCorrection - Boolean - A sign that error correction is reflected in the implementation document.
// 	     * AdjustmentUnderApprovalOfParties - Boolean - A sign that the implementation adjustment is reflected by agreement of the parties.
// 	     * ImplementationAdjustmentDocument - Undefined, DocumentRef.SaleAdjustment - Link to the implementation adjustment document.
// 	                                              Filled in if error correction or side alignment correction is reflected.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlements with the client.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the sales document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business transaction to be reflected in financial accounting.
// 	     * FinRecordID - String - A unique identifier that is used to link movements in corresponding financial registers.
// 	    The implemented nomenclature.
// 	     * Products - CatalogRef.Products - A product, job, or service.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the Product to be implemented.
// 	     * ProductsInSet - CatalogRef.Products - the implemented set.
// 	     * ItemVariantOfSet - CatalogRef.ItemsCharacteristics - characteristics of the set.
// 	     * Series - CatalogRef.ItemsBatches - a series of Products.
// 	     * Count - Number - the number of Products sold
// 	     * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - The unit of measurement of the Product.
// 	     * QuantityByGBRN - Number - the quantity of the product in traceability units.
// 	     * Content - String - description of the services provided.
// 	     * VATRate - CatalogRef.VATRates - The VAT rate at which sales are taxed.
// 	     * FEACNCode - CatalogRef.FEACN - HS code of the goods being sold.
// 	     * CCDNumber - CatalogRef.CCDNumbers - The CCD number of the product being sold.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of goods sold.
// 	     * RowID - String, UUID - Unique ID of the implementation document line.
// 	     * LineNumber - Number - line number of the original (primary) invoice.
//
Procedure ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_) Export
	
	Query.SetParameter("InventoryTypesOwn", VATAccountingERPInternal.InventoryTypesOwn());
	Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	
	#Region VATRegisterRecords
	QueryTextVATRegisterRecords = 
	"SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	CASE
	|		WHEN Assets_.SalesViaCommissionAgent
	|			THEN Assets_.ConsignedGoodsCustomer
	|		ELSE Assets_.Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN Assets_.AdjustmentUnderApprovalOfParties
	| 			THEN Assets_.ImplementationAdjustmentDocument
	|		ELSE Assets_.DocumentSalesOfGoodsAndServices
	|	END AS TaxInvoice,
	|	Assets_.VATRate AS VATRate,
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSalesOfWorkServices)
	|			THEN VALUE(Enum.AssetKinds.ServicesOutsideTerritoryOfRF)
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SalesAreSubjectToVATInEEU)
	|			THEN VALUE(Enum.AssetKinds.GoodsToPersonsInEEUElectronicPlatforms)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|			THEN VALUE(Enum.AssetKinds.Goods)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	DocumentAmounts_.VATAmountMan AS VATManag,
	|	CASE 
	|		WHEN Assets_.BusinessTransactionSetting IN (
	|				VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsSaleWithDeferredTitleTransfer),
	|				VALUE(Catalog.BusinessTransactionsSettings.SaleWithDeferredTransferOfTitle),
	|				VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgentGoodsInTransit))
	|		THEN UNDEFINED
	|		ELSE Assets_.ARAPObject
	|	END AS ARAPObject,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.FinRecordID AS FinRecordID,
	|	CASE 
	|		WHEN Assets_.BusinessTransactionSetting IN (
	|				VALUE(Catalog.BusinessTransactionsSettings.FixedAssetsSaleWithDeferredTitleTransfer),
	|				VALUE(Catalog.BusinessTransactionsSettings.SaleWithDeferredTransferOfTitle),
	|				VALUE(Catalog.BusinessTransactionsSettings.SalesViaCommissionAgentGoodsInTransit))
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
	|		ELSE Assets_.BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|	ON
	|		Assets_.Characteristic = ItemsCharacteristics.Ref
	|
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|			THEN ISNULL(CatInventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) IN (&InventoryTypesOwn)
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN (ISNULL(ItemsCharacteristics.Principal, CatProducts.Principal) = UNDEFINED
	|					OR ISNULL(ItemsCharacteristics.Principal, CatProducts.Principal) = Assets_.Organization)
	|		ELSE TRUE
	|	END
	|";
#EndRegion
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATRegisterRecords", Registers) Then 
		ReflectionTemplateTexts.Insert("VATRegisterRecords", QueryTextVATRegisterRecords);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Assets_", ValueText_);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

// Supplements the Query Text of the document with texts reflecting the shipment of goods in VAT accounting.
// of operation generates Register Records according to the registers of the Realization0 state (in case of export sales), given the basis of the accounts of the products.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	ValueText_ - String - The Query Text for getting document data.
//
Procedure ReflectShipmentToCustomer(Query, QueryTexts, Registers, ValueText_) Export
	
	Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	
	VATAccountingLocalization.ReflectShipmentToCustomer(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

// Supplements the texts of the document request with texts reflecting the return of goods to the supplier in VAT accounting.
// The request is generated by a table of movements according to the register of record books of sales, the data of the basis of the accounts of the products.
//
// The document should announce the export procedure for the formation of the Total document in the Account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// ..
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the request to receive the data of the purchase document.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization on whose behalf the refund is reflected.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the refund is reflected.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Supplier of goods.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract of implementation.
// 	     * Shipper - CatalogRef.Counterparties - The shipper of the returned goods.
// 	     * GoodsRecipient - CatalogRef.Counterparties - The consignee of the returned goods.
// 	     * CustomerVATExempt - Boolean - Indicates that the buyer returning the goods is not a VAT payer and an invoice is not expected from him.
// 	     * DocumentReturnPolicy - DefinedType.BaseDocumentIssuedTaxInvoice - Link to the return document.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the refund document.
// 	     * DocumentInflow - DefinedType.TaxInvoice - A link to the document of receipt of goods for which the refund is made.
// 	     * VATActivityType - EnumRef.VATTaxationTypes - Type of activity of separate VAT accounting of the purchase document.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business transaction to be reflected in financial accounting.
// 	     * FinRecordID - String - A unique identifier that is used to link movements in corresponding financial registers.
// 	    The item to return.
// 	     * Products - CatalogRef.Products - The returned product.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the returned product.
// 	     * VATRate - CatalogRef.VATRates - The VAT rate of the returned goods.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of the returned product.
// 	     * Purpose - CatalogRef.Assignments - In the case of acquisition for a separate need determines the type of activity of separate VAT accounting.
// 	     * RowID - String, UUID - Unique ID of the return document line.
//
Procedure ReflectReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextProducts_1) Export
	
	AccountingSettings = AccountingSettings();
	
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost", ActivitiesVATIsIncludedInCost());
	Query.SetParameter("DateWhenRefundsAreReflectedInCorrectiveSF", AccountingSettings.DateWhenRefundsAreReflectedInCorrectiveSF);
	Query.SetParameter("StartDateOfVATAccountingByLineOfBusiness", AccountingSettings.StartDateOfVATAccountingByLineOfBusiness);
	Query.SetParameter("ManagementAccountingOfOrganizationsIsIncluded_", CalculationOfCostCached.CompanyManagementAccounting());
	Query.SetParameter("StartDateOfManagementAccountingOfOrganizations", CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations());
	Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	Query.SetParameter("InventoryTypesOwn", VATAccountingERPInternal.InventoryTypesOwn());
	
#Region VATInvoiced

	TextsOfGeneralVATRequestSubmitted = New Array;
	
	QueryTextAccountingPolicy =
	"SELECT
	|	Assets_.Ref       AS Ref,
	|	Assets_.Organization  AS Organization,
	|	Assets_.Period       AS Period,
	|	MAX(TaxationSystemSettings.Period) AS AccountingPolicyPeriod
	|INTO PeriodsOfAdjustmentOfTaxSystem
	|FROM
	|	#Assets_ AS Assets_
	|	INNER JOIN
	|		InformationRegister.TaxationSystemSettings AS TaxationSystemSettings
	|	ON
	|		Assets_.Organization = TaxationSystemSettings.Organization
	|		AND Assets_.Period >= TaxationSystemSettings.Period
	|
	|GROUP BY
	|	Assets_.Ref,
	|	Assets_.Organization,
	|	Assets_.Period
	|	
	|INDEX BY
	|	Ref,
	|	Organization
	|;
	|
	|SELECT DISTINCT
	|	Assets_.Ref        AS Ref,
	|	Assets_.Organization   AS Organization,
	|	Assets_.Period        AS Period,
	|	MAX (CASE WHEN TaxationSystemSettings.TaxationSystem IS NULL
	|		THEN FALSE
	|		ELSE TaxationSystemSettings.TaxationSystem <> VALUE(Enum.TaxationSystems.Shared3) 
	|	END) AS STSIsApplied,
	|	TRUE AS GeneralVATRatesApply
	|
	|INTO AccountingPoliciesOfOrganizations
	|FROM
	|	#Assets_ AS Assets_
	|	
	|	LEFT JOIN
	|		PeriodsOfAdjustmentOfTaxSystem AS PeriodsOfAdjustmentOfTaxSystem
	|ON
	|		Assets_.Ref = PeriodsOfAdjustmentOfTaxSystem.Ref
	|		AND Assets_.Organization = PeriodsOfAdjustmentOfTaxSystem.Organization
	|		AND Assets_.Period = PeriodsOfAdjustmentOfTaxSystem.Period
	|	
	|	LEFT JOIN
	|		InformationRegister.TaxationSystemSettings AS TaxationSystemSettings
	|	ON
	|		PeriodsOfAdjustmentOfTaxSystem.Organization = TaxationSystemSettings.Organization
	|		AND PeriodsOfAdjustmentOfTaxSystem.AccountingPolicyPeriod = TaxationSystemSettings.Period
	|
	|GROUP BY
	|	Assets_.Ref,
	|	Assets_.Organization,
	|	Assets_.Period
	|
	|INDEX BY
	|	Ref,
	|	Organization
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PeriodsOfAdjustmentOfTaxSystem
	|;
	|";
	
	VATAccountingLocalization.AddGeneralVATRatesToUSNSText(QueryTextAccountingPolicy);
	
	TextsOfGeneralVATRequestSubmitted.Add(QueryTextAccountingPolicy);
		
	QueryTextVATInvoiced = 
	"SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	CASE
	|		WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|											VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			THEN Assets_.DocumentInflow
	|		ELSE Assets_.DocumentReturnPolicy
	|	END AS TaxInvoice,
	|	Assets_.Counterparty AS Vendor,
	|	CASE
	|		WHEN Assets_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|											VALUE(Enum.VATTaxationTypes.SpaceActivity))
	|			THEN VALUE(Enum.AssetKinds.Goods)
	|		ELSE VALUE(Enum.AssetKinds.ReverseByCorrectiveTaxInvoice)
	|	END AS AssetTaxClass,
	|	Assets_.VATRate                          AS VATRate,
	|	CASE
	|		WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Assignments.VATActivityType
	|		WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		WHEN AccountingPoliciesOfOrganizations.STSIsApplied AND NOT AccountingPoliciesOfOrganizations.GeneralVATRatesApply
	|			THEN Assets_.VATActivityType
	|		WHEN Assets_.DocumentInflow IS NULL
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		ELSE Assets_.VATActivityType
	|	END AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	CASE
	|		WHEN Assets_.Period >= &StartDateOfVATAccountingByLineOfBusiness
	|			AND ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		THEN Assignments.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN -DocumentAmounts_.VATBaseLocal
	|		ELSE -DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	-DocumentAmounts_.VATAmountCompl AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN -DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|
	|	VALUE(Enum.EventsChargedVAT.EmptyRef) AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
	|	Assets_.RowID AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		AccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations
	|	ON
	|		Assets_.Ref = AccountingPoliciesOfOrganizations.Ref
	|		AND Assets_.Period = AccountingPoliciesOfOrganizations.Period
	|
	|	LEFT JOIN
	|		Catalog.Assignments AS Assignments
	|	ON
	|		Assets_.Purpose = Assignments.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND NOT CASE
	|		WHEN ISNULL(Assignments.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Assignments.VATActivityType
	|		WHEN Assets_.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			AND Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		WHEN AccountingPoliciesOfOrganizations.STSIsApplied AND NOT AccountingPoliciesOfOrganizations.GeneralVATRatesApply
	|			THEN Assets_.VATActivityType
	|		WHEN Assets_.DocumentInflow IS NULL
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|		ELSE Assets_.VATActivityType
	|	END IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|	AND NOT ISNULL(Assignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND Assets_.Period >= &DateWhenRefundsAreReflectedInCorrectiveSF 
	|
	|";
	
	TextsOfGeneralVATRequestSubmitted.Add(QueryTextVATInvoiced);
	
#EndRegion
	
#Region VATRegisterRecords
	QueryTextVATRegisterRecords =
	"// VAT accrual
	|SELECT
	|	Assets_.Period AS Period,
	|	Assets_.Ref AS Recorder,
	|	VALUE(Enum.VATRegisterRecordTypes.Incoming) AS EntryType,
	|	Assets_.Organization AS Organization,
	|	Assets_.Counterparty AS Counterparty,
	|	Assets_.DocumentReturnPolicy AS TaxInvoice,
	|	VALUE(Enum.AssetKinds.Goods) AS AssetTaxClass,
	|	Assets_.VATRate AS VATRate,
	|
	|	-DocumentAmounts_.VATBaseLocal AS AmountExcludingVAT,
	|	-DocumentAmounts_.VATAmountCompl AS VAT,
	|	-DocumentAmounts_.VATAmountMan AS VATManag,
	|
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE AS ReversingEntry
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Assets_.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn)
	|	AND Assets_.VATTaxation IN (
	|		VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|		VALUE(Enum.VATTaxationTypes.ProductionWithLongCycle),
	|		VALUE(Enum.VATTaxationTypes.SpaceActivity),
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|		VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer))
	|	AND Assets_.Period < &DateWhenRefundsAreReflectedInCorrectiveSF
	|";
	
#EndRegion

	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATInvoiced", Registers) Then 
		ReflectionTemplateTexts.Insert("VATInvoiced", StrConcat(TextsOfGeneralVATRequestSubmitted));
	EndIf;
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATRegisterRecords", Registers) Then 
		ReflectionTemplateTexts.Insert("VATRegisterRecords", QueryTextVATRegisterRecords);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Assets_", TextProducts_1);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the reflection of the commission agent's report in VAT accounting.
// The operation generates movements according to the registers of the data bases of the invoice accounts.
// Based on these movements, orders for processing invoices to the commission agent are registered.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization on whose behalf the commission agent's report is reflected.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the commission agent's report is drawn up.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Commission agent.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Commission Contract.
// 	     * Shipper - CatalogRef.Counterparties - Shipper of goods.
// 	     * ConsignmentReportFromCustomer - DefinedType.TaxInvoice - Commission agent's report.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the commission agent's report.
// 	     * ARAPObject - CatalogRef.ARAPObjects - The object of settlements with the commission agent.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up a business transaction to be reflected in financial accounting.
// 	     * FinRecordID - String - A unique identifier that is used to link movements in corresponding financial registers.
// 	    Implemented nomenclature, information about invoices issued to customers.
// 	     * Products - CatalogRef.Products - A product or service sold through an intermediary.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the Product to be implemented.
// 	     * VATRate - CatalogRef.VATRates - The VAT rate at which the sale of commission goods is taxed.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of goods sold.
// 	     * DateOfTaxInvoiceIssuedByCommissionAgent - Date - The date the invoice was issued by the commission agent to the buyer.
// 	     * CommissionAgentSTaxInvoiceNumber - Date - The invoice number issued by the commission agent to the buyer.
// 	     * ConsignedGoodsCustomer - CatalogRef.Counterparties - Buyer of goods and services.
// 	     * RowID - String, UUID - Unique ID of the report line to the commission agent.
// 	     * ErrorCorrection - Boolean - Indicates that the line refers to an implementation correction with the Error Correction operation
//
Procedure ReflectCommissionAgentSReport(Query, QueryTexts, Registers, TextProducts_1) Export
	
	Query.SetParameter("InventoryTypesOwn", VATAccountingERPInternal.InventoryTypesOwn());
	Query.SetParameter("ProductProductTypes", VATAccountingERPInternal.ProductProductTypes());
	
	#Region VATRegisterRecords
	QueryTextVATRegisterRecords = 
	"SELECT
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	Assets_.Counterparty AS Counterparty,
	|	Assets_.ConsignmentReportFromCustomer AS TaxInvoice,
	|	Assets_.VATRate AS VATRate,
	|	CASE
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.ExportSalesOfWorkServices)
	|			THEN VALUE(Enum.AssetKinds.ServicesOutsideTerritoryOfRF)
	|		WHEN Assets_.VATTaxation = VALUE(Enum.VATTaxationTypes.SalesAreSubjectToVATInEEU)
	|			THEN VALUE(Enum.AssetKinds.GoodsToPersonsInEEUElectronicPlatforms)
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|			THEN VALUE(Enum.AssetKinds.Goods)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	DocumentAmounts_.VATAmountMan AS VATManag,
	|	Assets_.ARAPObject AS ARAPObject,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	Assets_.BusinessOperation AS BusinessOperation,
	|	FALSE AS ReversingEntry
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		Catalog.Products AS CatProducts
	|	ON
	|		Assets_.Products = CatProducts.Ref
	|
	|	LEFT JOIN
	|		Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|	ON
	|		Assets_.Characteristic = ItemsCharacteristics.Ref
	|
	|	LEFT JOIN
	|		Catalog.InventoryKinds AS CatInventoryKinds
	|	ON
	|		Assets_.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) IN (&ProductProductTypes)
	|			THEN ISNULL(CatInventoryKinds.InventoryType, UNDEFINED) IN (&InventoryTypesOwn)
	|		ELSE TRUE
	|	END
	|	AND CASE
	|		WHEN ISNULL(CatProducts.ItemsType, UNDEFINED) = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN (ISNULL(ItemsCharacteristics.Principal, CatProducts.Principal) = UNDEFINED
	|					OR ISNULL(ItemsCharacteristics.Principal, CatProducts.Principal) = Assets_.Organization)
	|		ELSE TRUE
	|	END
	|";
#EndRegion
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATRegisterRecords", Registers) Then 
		ReflectionTemplateTexts.Insert("VATRegisterRecords", QueryTextVATRegisterRecords);
	EndIf;
	If ReflectionTemplateTexts.Count() > 0 Then
		ManagerOfDocument = Common.ObjectManagerByRef(Query.Parameters.Ref);
		ManagerOfDocument.GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("Assets_", TextProducts_1);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
	VATAccountingLocalization.ReflectCommissionAgentSReport(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the report to the committee in VAT accounting.
// The operation generates movements according to the registers of the data bases of the invoice accounts.
// Based on these movements, orders for the registration of invoices from the committee are formed.
//
// The document should announce the export procedure for the formation of the Total document in the Account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * Organization - CatalogRef.Companies - The organization on whose behalf the report is reflected to the committee.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the report is issued to the committee.
// 	     * Counterparty - CatalogRef.Counterparties, CatalogRef.Companies - Committee.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts - Contract with the committee.
// 	     * ConsignmentReportToVendor - DefinedType.BaseDocumentIssuedTaxInvoice - Report to the committee.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - taxation of VAT report to the committee.
// 	    The implemented nomenclature, invoices issued to customers.
// 	     * Products - CatalogRef.Products - A sold product or service.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the implemented Product range.
// 	     * VATRate - CatalogRef.VATRates - The VAT rate at which the sale of commission goods is taxed.
// 	     * InventoryOwnerAttribute - CatalogRef.InventoryKinds - Type of inventory of goods sold.
// 	     * DateOfInvoiceIssuedToBuyer - Date - Date of the invoice issued to the buyer.
// 	     * ConsignedGoodsCustomer - CatalogRef.Counterparties, CatalogRef.Companies - Buyer of a Commission product.
// 	     * InvoiceIssuedToBuyer - DocumentRef - Link to the invoice issued to the buyer or sub-commissioner.
// 	     * RowID - String, UUID - Unique ID of the report line to the committee.
// 	     * ErrorCorrection - Boolean - Indicates that the line refers to an implementation correction with the Error Correction operation
//
Procedure ReflectReportToCommittee(Query, QueryTexts, Registers, TextProducts_1) Export
	
	VATAccountingLocalization.ReflectReportToCommittee(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

// Supplements the texts of the document request with texts reflecting the write-off of amounts from the incoming VAT accounting contour.
// The operation generates movements according to the NDSPREDECLARED register.
// 
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String- List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	ValueText_ - String - The text of the request to receive the data of the purchase document.
// 	      The request should return a selection:
// 	      with fields. 
// 	     * RecordType - AccumulationRecordType  - Type of traffic Flow.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * Period - Date - date when the operation was reflected.
// 	     * Organization - CatalogRef.Companies - The organization where the VAT write-off is reflected.
// 	     * TaxInvoice - DefinedType.TaxInvoice - Link to the purchase document.
// 	     * Vendor - CatalogRef.Counterparties - Supplier of values.
// 	     * AssetTaxClass - EnumRef.AssetKinds - The type of acquired values.
// 	     * VATRate - CatalogRef.VATRates - VAT rate of purchased valuables.
// 	     * VATActivityType - EnumRef.VATTaxationTypes - Type of activity of separate VAT accounting of the purchase document.
// 	     * CorrectedTaxInvoice - Undefined
// 	     * SaleExport - Undefined               
// 	     * LineOfBusiness - CatalogRef.LinesOfBusiness - The line of business under which the VAT write-off is reflected.
// 	     * AmountExcludingVAT - Number - The amount excluding VAT.
// 	     * VAT - Number - amount of VAT.
// 	     * VATManag - Number - the amount of vat in the currency of Man. accounting.
// 	     * Event - EnumRef.EventsChargedVAT - Event - deduction of VAT on expenses.
// 	     * CorVATActivityTypes - EnumRef.VATTaxationTypes - Cor. type of activity.
// 	     * RowID - String, UUID - ID of the purchase document line 
// 	     * PeriodEndTransaction - Boolean - A lie.
// 	     * Department - CatalogRef.BusinessStructure - A division that accounts for purchased goods, works, services, and assets.
// 	     * CorLineOfBusiness - CatalogRef.LinesOfBusiness - Cor. direction of activity.          
// 	     * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - Item of expenses.          
// 	     * DimensionOfExpenses - Characteristic.ExpenseItems - Analysis of VAT write-off.          
// 	     * FinRecordID - String - ID to display the entry in financial accounting.
// 	     * BusinessTransactionSetting - CatalogRef.BusinessTransactionsSettings - Setting up for reflection in accounting.
//
Procedure ReflectVATDeductionForExpenses(Query, QueryTexts, Registers, ValueText_) Export
	
	Query.SetParameter("ManagementAccountingOfOrganizationsIsIncluded_", CalculationOfCostCached.CompanyManagementAccounting());
	Query.SetParameter("StartDateOfManagementAccountingOfOrganizations", CalculationOfCostCached.StartDateOfManagementAccountingOfOrganizations());
	
#Region VATInvoiced
	
	QueryTextVATInvoiced = 
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Assets_.Ref AS Recorder,
	|	Assets_.Period AS Period,
	|	Assets_.Organization AS Organization,
	|	Assets_.TaxInvoice AS TaxInvoice,
	|	Assets_.Counterparty AS Vendor,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	Assets_.VATRate AS VATRate,
	|	Assets_.VATActivityType AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	Assets_.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentAmounts_.VATBaseLocal <> 0
	|			THEN DocumentAmounts_.VATBaseLocal
	|		ELSE DocumentAmounts_.AmountExcludingVATCompl
	|	END AS AmountExcludingVAT,
	|	DocumentAmounts_.VATAmountCompl AS VAT,
	|	CASE
	|		WHEN &ManagementAccountingOfOrganizationsIsIncluded_
	|			  AND Assets_.Period >= &StartDateOfManagementAccountingOfOrganizations
	|			THEN DocumentAmounts_.VATAmountMan
	|		ELSE 0
	|	END AS VATManag,
	|
	|	VALUE(Enum.EventsChargedVAT.VATWritingOffAsExpenses) AS Event,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
	|	Assets_.RowID AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	Assets_.AccountingDivision AS Department,
	|	Assets_.LineOfBusiness AS CorLineOfBusiness,
	|	Assets_.ExpenseItemVATWriteOff AS ExpenseItem,
	|	Assets_.ExpenseDimensionVATWriteOff AS DimensionOfExpenses,
	|	Assets_.FinRecordID AS FinRecordID,
	|	Assets_.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	#Assets_ AS Assets_
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		Assets_.Ref = DocumentAmounts_.Ref
	|		AND Assets_.RowID = DocumentAmounts_.RowID
	|
	|WHERE
	|	Assets_.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND ISNULL(DocumentAmounts_.VATAmountCompl, 0) <> 0
	|";
	
#EndRegion
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("VATInvoiced", Registers) Then
		ReflectionTemplateTexts.Insert("VATInvoiced", QueryTextVATInvoiced);
	EndIf;
	
	TextsOfDocumentDataRequests = New Structure("Assets_", ValueText_);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);
	
EndProcedure

// Supplements the texts of the request for the document with the texts of the reflection of the report to the committee on purchases in VAT accounting.
// The operation generates a table of fillingtovars with data.
//
// The document should declare the export procedure for the formation of the Total document in the account account,
// which initializes the total document in the account account (See InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument)
// .
//
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextProducts_1 - String - The text of the request to get document data.
// 	     The request should return a selection of fields:
// 	    Attributes of the operation.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * Organization - CatalogRef.Companies - the company on whose behalf the implementation is reflected.
// 	    Values in the re-submitted invoice.
// 	     * Products - CatalogRef.Products - A product, job, or service.
// 	     * Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
// 	     * ProductsInSet - CatalogRef.Products - set.
// 	     * ItemVariantOfSet - CatalogRef.ItemsCharacteristics - characteristics of the set.
// 	     * Count - Number - number of values
// 	     * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - The unit of measurement of value.
// 	     * Content - String - description of the services provided
// 	     * VATRate - CatalogRef.VATRates - The VAT rate at which sales are taxed.
// 	     * CCDNumber - CatalogRef.CCDNumbers - the product's GTD number.
// 	     * DocumentAcquisitions - DocumentRef.VendorInvoice - The original document of the acquisition of values.
// 	     * VendorInvoiceReceived - DocumentRef - The reissued invoice received from the supplier.
// 	     * RowID - String, UUID - Unique ID of the report line to the committee.
//
Procedure ReflectReportToPurchasingCommittee(Query, QueryTexts, Registers, TextProducts_1) Export
	
	VATAccountingLocalization.ReflectReportToPurchasingCommittee(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

// The procedure for the formation of Registered Records for independent registers of VAT accounting settings.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
	
	VATAccountingLocalization.RecordVATAccountingSettingsDataForCommitteeSUSN(TablesForRegisteredRecords, Document, TempTablesManager, Cancel);
	
EndProcedure

#EndRegion

#Region OtherProgrammingInterface

#Region DescriptionOfClosingStagesOfMonth

#Region VATAllocation

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID
//
Procedure AddStage_VATAllocation(StepsTable,CurrentParent) Export

	PreviousStage_ = Catalogs.MonthEndClosingOperations.LotsAndCostCalculation;
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.VATAllocation,,,,
		PreviousStage_);
	
	NewRow.MultilingualName = "vi = 'Phân bổ thuế GTGT';
								|ru = 'Распределение НДС';
								|en = 'VAT allocation';
								|it = 'Ripartizione IVA';
								|pl = 'Podział VAT';
								|tr = 'KDV Tahsisi'"; // @NStr-1
	NewRow.PreviousStages_.Add(Catalogs.MonthEndClosingOperations.LotsAndCostCalculation);
	NewRow.TextExecute = NStr("vi = 'Phân bổ';
								|ru = 'Распределить';
								|en = 'Allocate'; fa = 'تسهیم';
								|it = 'Ripartire';
								|pl = 'Allocate';
								|tr = 'Dağıt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"VATAccountingERP.Use_DistributionOfVAT");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"VATAccountingERP.Perform_VATDistribution");
	NewRow.ActionMoreDetails = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.VATAllocation.Forms.ListForm.FullName());
	
EndProcedure

// Stage handlers.

#Region StageHandlers

Procedure Use_DistributionOfVAT(HandlerParameters) Export
	
	If HandlerParameters.Data_Stage.State = Enums.StatesOfMonthEndClosingOperations.NotRequired Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.CheckAvailabilityOfTasksByEndOfMonth(HandlerParameters, False);
	VATAccountingLocalization.AdditionalChecksForVATDistribution(HandlerParameters);
	
	If MonthEndTransactionsServer.StageStateDefined(HandlerParameters.Data_Stage)
	 And MonthEndTransactionsServer.StageRecalculationIsRequired(HandlerParameters.Data_Stage) Then
		Return;
	EndIf;
	
	MonthEndTransactionsServer.CheckAvailabilityOfRegulatoryDocumentOfClosingStageOfMonth(
		HandlerParameters,
		Metadata.Documents.VATAllocation.Name);
	
EndProcedure

Procedure Perform_VATDistribution(HandlerParameters) Export
	
	CalculationParameters = HandlerParameters.CalculationParameters;
	
	BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndOfPeriod  = EndOfMonth(CalculationParameters.RegistrationPeriod);
	
	TaskNumberBeforeCalculation = MonthEndTransactionsServer.IncreaseTaskNumber();
	
	BeginTransaction();
	
	Try
		
		MonthEndTransactionsServer.BlockTaskRegister(TaskNumberBeforeCalculation, CalculationParameters.CompanyArray, HandlerParameters.Data_Stage.Code);
		
		DataToDistribution = MonthEndTransactionsServer.MonthlyTasks(
			BeginOfPeriod,
			EndOfPeriod,
			TaskNumberBeforeCalculation,
			CalculationParameters.CompanyArray,
			HandlerParameters.Data_Stage.Code);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
				|%2';
				|ru = 'При выполнении расчета за период %1 произошла ошибка:
				|%2';
				|en = 'An error occurred when calculating for the %1 period:
				|%2'; fa = 'An error occurred when calculating for the %1 period:
				|%2';
				|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
				|%2';
				|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
				|%2';
				|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
		
		MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
			HandlerParameters,
			ErrorText,
			CalculationParameters.CompanyArray,
			CalculationParameters.RegistrationPeriod);
		
	EndTry;
	
	ResultOfVATDistribution = Documents.VATAllocation.DistributeVAT(
		HandlerParameters.CalculationParameters.RegistrationPeriod, 
		DataToDistribution.Organization);
	
	If ResultOfVATDistribution.CalculatedOrganizations.Count() > 0 Then
		
		BeginTransaction();
		
		Try
			
			MonthEndTransactionsServer.BlockTaskRegister(
				TaskNumberBeforeCalculation,
				CalculationParameters.CompanyArray,
				HandlerParameters.Data_Stage.Code);
			
			MonthEndTransactionsServer.FixCalculation(
				Undefined,
				HandlerParameters.Data_Stage.Code,
				DataToDistribution.TemporaryTable);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Khi tính toán trong kỳ %1 đã xảy ra lỗi:
					|%2';
					|ru = 'При выполнении расчета за период %1 произошла ошибка:
					|%2';
					|en = 'An error occurred when calculating for the %1 period:
					|%2'; fa = 'An error occurred when calculating for the %1 period:
					|%2';
					|it = 'Durante l''esecuzione dei calcoli secondo il periodo %1 si è verificato un''errore:
					|%2';
					|pl = 'Podczas wykonania rozliczenia za okres %1 zaistniał błąd:
					|%2';
					|tr = 'Dönem %1 için hesaplama yapılırken hata oluştu:
					|%2'", Common.DefaultLanguageCode()),
				CostCalculationProtocol.PresentationOfCalculationPeriod(BeginOfPeriod),
				DetailErrorDescription(ErrorInfo()));
			
			MonthEndTransactionsServer.FixProblemWhenPerformingCalculation(
				HandlerParameters,
				ErrorText,
				CalculationParameters.CompanyArray,
				CalculationParameters.RegistrationPeriod);
			
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region PostingGenerationInVATAccounting

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
Procedure AddStage_PostingGenerationInVATAccounting(StepsTable,CurrentParent) Export
	
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.PostingGenerationInVATAccounting,
		True, False, False);
	
	NewRow.MultilingualName = "vi = 'Lập lưu chuyển Thuế GTGT';
								|ru = 'Формирование движений по НДС';
								|en = 'Generate VAT records';
								|it = 'Generazione di movimenti IVA';
								|pl = 'Formowanie przepływów wg VAT';
								|tr = 'KDV kayıtlarını oluşturma'"; // @NStr-1
	NewRow.TextExecute = NStr("vi = 'Lập báo cáo';
								|ru = 'Сформировать';
								|en = 'Generate'; fa = 'ایجاد';
								|it = 'Generare';
								|pl = 'Generate';
								|tr = 'Oluştur'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"VATAccountingERP.Usage_FormationOfVATRegisteredRecords");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_PerformCalculation(
		"VATAccountingERP.Perform_GenerationRegisteredRecordsForVAT");
	NewRow.PerformedAtPreliminaryClosingOfMonth = True;
	
EndProcedure

#Region StageHandlers

Procedure Usage_FormationOfVATRegisteredRecords(HandlerParameters) Export
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	Query.Text =
	"SELECT
	|	MAX(RegisterData.Period) AS EndDate,
	|	COUNT(DISTINCT RegisterData.Recorder) AS Count
	|FROM
	|	AccumulationRegister.VATInvoiced AS RegisterData
	|WHERE
	|	RegisterData.PeriodEndTransaction
	|	AND RegisterData.Period <= &EndOfPeriod
	|	AND (RegisterData.Organization IN (&CompanyArray)
	|		OR &ByAllCompanies)
	|
	|HAVING
	|	COUNT(RegisterData.Recorder) > 0
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(RegisterData.Month) AS StartDate,
	|	COUNT(DISTINCT RegisterData.TaxInvoice) AS Count
	|FROM
	|	InformationRegister.JobsForGeneratingVATRecords AS RegisterData
	|WHERE
	|	RegisterData.Month <= &EndOfPeriod
	|	AND (RegisterData.Organization IN (&CompanyArray)
	|		OR &ByAllCompanies)
	|
	|HAVING
	|	COUNT(RegisterData.TaxInvoice) > 0
	|";
	
	Query.SetParameter("ByAllCompanies", False);
	
	ResultsArray = Query.ExecuteBatch();
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters,
		ResultsArray[0].Unload().Count()
		+ ResultsArray[1].Unload().Count());
	
	ThereAreReflectedInAccounting                = Not ResultsArray[0].IsEmpty();
	ThereArePendingReflections              = Not ResultsArray[1].IsEmpty();
	
	If ThereArePendingReflections Then
		
		MonthEndTransactionsServer.SetStateFailed(
			HandlerParameters,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đang chờ phản ánh trong kế toán thuế GTGT: %1';
					|ru = 'Ожидает отражения в учете НДС: %1';
					|en = 'Awaiting recording in VAT accounting: %1'; fa = 'Awaiting recording in VAT accounting: %1';
					|it = 'Si aspetta una visualizzazione nella contabilizzazione dell''IVA: %1';
					|pl = 'Oczekuje odzwierciedlenia w ewidencji VAT: %1';
					|tr = 'KDV muhasebesinde yansıtılması bekleniyor: %1'", Common.DefaultLanguageCode()),
				TrimAll(ResultsArray[1].Unload()[0].Count)));
		
	EndIf;
	
	If Not ThereArePendingReflections And Not ThereAreReflectedInAccounting Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có chứng từ để xử lý.';
				|ru = 'Нет документов для обработки.';
				|en = 'No documents for processing.'; fa = 'No documents for processing.';
				|it = 'Non ci sono documenti da elaborare.';
				|pl = 'Brak dokumentów do przetwarzania.';
				|tr = 'İşleme için belge mevcut değil'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

Procedure Perform_GenerationRegisteredRecordsForVAT(HandlerParameters) Export
	
	ExecuteGenerationRegisteredRecordsForVAT( 
		EndOfMonth(HandlerParameters.CalculationParameters.RegistrationPeriod),
		HandlerParameters.CalculationParameters.CompanyArray);
	
		
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region JobGeneration

#Region JobsForGeneratingVATRecords 

// Creates register entries based on data from documents that affect VAT accounting
//
// Parameters:
//   DocumentsArray - Array of DocumentRef - links to documents.
//
Procedure GenerateTasksBasedOnDocuments(DocumentsArray) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		// In RIB, this register is processed only in the main node.
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Table = New ValueTable;
	Table.Columns.Add("Type");
	Table.Columns.Add("Ref");
	
	For Each Document In DocumentsArray Do
		NewRow = Table.Add();
		NewRow.Ref = Document;
		NewRow.Type    = TypeOf(Document);
	EndDo;
	Table.Sort("Type");
	
	TypesTable = Table.Copy(, "Type");
	TypesTable.GroupBy("Type");
	
	For Each TypeRow In TypesTable Do
		
		Filter = New Structure("Type", TypeRow.Type);
		ReferencesArrray = Table.Copy(Filter, "Ref").UnloadColumn("Ref");
		
		If TypeRow.Type = Type("DocumentRef.VATAllocation") Then
			VATAccountingERPInternal.GenerateTasksBasedOnVATDistributionDocuments(ReferencesArrray);
		ElsIf TypeRow.Type = Type("DocumentRef.IssuedTaxInvoicePrepayment") Then
			VATAccountingERPInternal.GenerateTasksBasedOnDocumentsInvoiceAdvancePayment(ReferencesArrray);
		ElsIf TypeRow.Type = Type("DocumentRef.ReceivedTaxInvoicePrepayment") Then
			VATAccountingERPInternal.GenerateTasksBasedOnDocumentsInvoiceReceivedAdvance(ReferencesArrray);
		Else
			VATAccountingLocalization.GenerateTasksBasedOnDocuments(TypeRow.Type, ReferencesArrray);
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates entries in the register of VAT accounting tasks when changing entries in the control registers.
//
// Parameters:
//  Document - DocumentObject - the Registrar registers the movements
//  TempTablesManager - TempTablesManager - a temporary table Manager that contains tables of register changes.
//
Procedure ReflectEntriesInRegisterTasksForGeneratingVATRegisteredRecords(Document, TempTablesManager) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then // tasks are installed only in the main node.
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("VATAccountingERP.ReflectEntriesInRegisterTasksForGeneratingVATRegisteredRecords");
	
	SampleRequestTemplate = "
	|SELECT DISTINCT
	|	Table.Month        AS Month,
	|	Table.Organization  AS Organization,
	|	Table.TaxInvoice  AS TaxInvoice
	|FROM
	|	&TempTable AS Table
	|";
	
	ArrayOfTaskSelectionRequests = New Array;
	ArrayOfRequestsForTTDestruction = New Array;	
	
	For Each TempTable In TempTablesManager.Tables Do
		
		If StrFind(TempTable.FullName, "_JobsForGeneratingVATRecords") > 0 Then
			If DocumentsPosting.ThereAreRecordsInTable(Document, TempTable.FullName) Then
				QueryText = StrReplace(SampleRequestTemplate, "&TempTable", TempTable.FullName);
				ArrayOfTaskSelectionRequests.Add(QueryText);
				
				DestructionRequestText = StrReplace("DROP &TempTable", "&TempTable", TempTable.FullName);
				ArrayOfRequestsForTTDestruction.Add(DestructionRequestText);
			EndIf;
		EndIf;
		
	EndDo;
	
	If ArrayOfTaskSelectionRequests.Count() > 0 Then
		
		QueryTextSamples = StrConcat(ArrayOfTaskSelectionRequests, TMCommonUse.QuerySeparatorInJoin());
		TextOfRequestToDestroyW = StrConcat(ArrayOfRequestsForTTDestruction, Common.QueryBatchSeparator());
		
		ArrayOfRequestTexts = New Array();
		ArrayOfRequestTexts.Add(QueryTextSamples);
		ArrayOfRequestTexts.Add(TextOfRequestToDestroyW);
		QueryText = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
		
		Query = New Query(QueryText);
		Query.TempTablesManager = TempTablesManager;
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
		
			Selection = Result.Select();
			While Selection.Next() Do
				InformationRegisters.JobsForGeneratingVATRecords.CreateRegisterEntry(
					Selection.Month,
					Selection.TaxInvoice,
					Selection.Organization);
			EndDo;
			
		EndIf;

	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

#EndRegion

#Region JobsForMonthEndClosing

// Complements the request text of the mechanism for generating monthly closing tasks.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//	SourceOfDocumentProperties - DocumentObject, Structure - the document being conducted or the result of the document execution function.Document emulation() for batch generation of tasks
Procedure AddTextOfRequestForTasksByEndOfMonth(Query, QueryText, TempTablesQueryText, TemporaryTableNames, SourceOfDocumentProperties) Export
	RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA = False;
	RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed = False;
	RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA = False;
	If SourceOfDocumentProperties <> Undefined
		And TypeOf("SourceOfDocumentProperties") = Type("Structure") Then
			
		RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA = 
			SourceOfDocumentProperties.Property(FACostCalculation.NameOfFlagOfOperation());
		
		RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed = 
			SourceOfDocumentProperties.Property(DeferredFARecordGeneration.NameOfFlagOfOperation());
		
		RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA = 
			SourceOfDocumentProperties.Property(FACostCalculation.NameOfSignOfOperationOfOperationUpdatingRegisteredRecordsFA());
		
	ElsIf SourceOfDocumentProperties <> Undefined Then
	
		RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA = 
			FACostCalculation.RegisteredRecordsAreRecordedWhenOperationIsPerformed(SourceOfDocumentProperties);
			
		RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed = 
			DeferredFARecordGeneration.RegisteredRecordsAreRecordedWhenOperationIsPerformed(SourceOfDocumentProperties);
			
		RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA = 
			FACostCalculation.RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA(SourceOfDocumentProperties);
			
	EndIf;
	
	Query.SetParameter("RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA", RegisteredRecordsAreRecordedWhenCalculatingCostOfVNA); 
	Query.SetParameter("RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed", RegisteredRecordsAreRecordedWhenFormationOfVNARegisteredRecordsIsDelayed); 
	Query.SetParameter("RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA", RegisteredRecordsAreRecordedWhenUpdatingRegisteredRecordsFA); 
	MatchingRequests = VATAccountingERPInternal.MatchingRequestsToControlRegisters(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTableNamesForTasks(Query, MapItem.Key);
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			QueryText,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
EndProcedure

// Performs additional processing of tasks to close the month before recording.
//
// Parameters:
// 	Month - Date - The month for which the task is generated.
// 	Operation - CatalogRef.MonthEndClosingOperations - The operation of closing the month, the performance of which is formed the job.
// 	Organization - CatalogRef.Companies - The organization that the task is generated for.
// 	Document - DocumentRef - The document that initiates the task.
//
Procedure BeforeWritingTaskToEndOfMonth(Month, Operation, Organization, Document) Export
	
	VATAccountingLocalization.BeforeWritingTaskToEndOfMonth(Month, Operation, Organization, Document);
		
EndProcedure

#EndRegion

#Region OtherTaskGenerationInterface

// Returns a table describing changes in calculations for generating tasks to reflect in VAT accounting
//
// Returns:
//   ValueTable   - Table of values with columns:
//     * Document - DocumentRef - payment document, a settlement document for which an invoice is issued
//     * Period - Date - period of changes in the status of payments for the document
//     * Counterparty - CatalogRef.Counterparties - the counterparty for which the calculations were changed.
//     * Organization - CatalogRef.Companies - the organization for which the calculations changed.
//
Function NewCalculationChangeTable() Export
	
	ChangesTable = New ValueTable;
	ChangesTable.Columns.Add("Document", Documents.AllRefsType());
	ChangesTable.Columns.Add("Period", Common.DateTypeDetails(DateFractions.Date));
	ChangesTable.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	ChangesTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	
	Return ChangesTable;
	
EndFunction // New Table of Account Changes()

// Reflects changes in the status of settlements with suppliers in VAT accounting.
//
// Parameters:
// 	ChangesTable - ValueTable - Table of values with columns:
//		* Document - DocumentRef - document for which the settlement status has changed
//		* Period - Date - change period
//
Procedure ReflectChangesInSettlementsWithSuppliersInVATAccounting(ChangesTable) Export
	
	If ChangesTable.Count() = 0 Then
		Return;
	EndIf;
	
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	VATAccountingLocalization.ReflectChangesInSettlementsWithSuppliersInVATAccounting(ChangesTable);
	
EndProcedure

// Reflects changes in the status of settlements with customers in VAT accounting.
//
// Parameters:
// 	ChangesTable - ValueTable - Table of values with columns:
//		* Document - DocumentRef - document for which the settlement status has changed
//		* Period - Date - change period
//
Procedure ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable) Export
	
	If ChangesTable.Count() = 0 Then
		Return;
	EndIf;
	
	Documents.IssuedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
	VATAccountingLocalization.ReflectChangesInSettlementsWithCustomersInVATAccounting(ChangesTable);
	
EndProcedure

// performs VAT accounting for changes in the State of settlements on financial instruments.
//
// Parameters:
// 	ChangesTable - ValueTable - Table of values with columns:
//		* Document - DocumentRef - the document according to which the State of the calculations has changed
//		* Period - Date - change period
//
Procedure ReflectInVATAccountingChangesInSettlementsOnFinancialInstruments(ChangesTable) Export
	
	If ChangesTable.Count() = 0 Then
		Return;
	EndIf;
	
	Documents.ReceivedTaxInvoicePrepayment.CreateTasksForGeneratingVATRegisteredRecords(ChangesTable);
	
	VATAccountingLocalization.ReflectInVATAccountingChangesInSettlementsOnFinancialInstruments(ChangesTable);
	
EndProcedure

#EndRegion

#EndRegion

#Region ExecutionOfRoutineOperations

// Performs the reflection documents in the VAT.
// 
// Parameters:
// 	 EndOfPeriod - Date - The period for which the reflection should be performed.
// 	 ReferencesArrray - Array of DocumentRef - Documents that need to be reflected in the VAT accounting.
//
Procedure ReflectDocumentsInVATAccounting(Val EndOfPeriod, Val ReferencesArrray) Export
	
	Invoices_ = New Array;
	CommonClientServer.SupplementArray(Invoices_, ReferencesArrray);
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	VATInvoiced.TaxInvoice AS TaxInvoice
	|FROM
	|	AccumulationRegister.VATInvoiced AS VATInvoiced
	|WHERE
	|	VATInvoiced.Recorder IN (&ReferencesArrray)
	|	AND VATInvoiced.TaxInvoice <> VATInvoiced.Recorder";
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	QueryResult = Query.Execute();
	CommonClientServer.SupplementArray(Invoices_, QueryResult.Unload().UnloadColumn("TaxInvoice"));
	
	VATAccountingLocalization.AddInvoicesToVATRecords(Invoices_, ReferencesArrray);
	
	If Invoices_.Count() > 0 Then
		VATAccountingERPInternal.CompleteTasksForGeneratingVATRegisteredRecords(EndOfMonth(EndOfPeriod), Undefined, Invoices_);
	EndIf;
	
EndProcedure

// Reflects documents in VAT accounting, if there are tasks.
//
// Parameters:
// 	EndOfPeriod - Date - The period for which it is necessary to perform the job.
// 	Organization - CatalogRef.Companies, Array of CatalogRef.Companies - The organization or pattern of organizations for the selection of tasks.
// 	Invoices_ - DocumentRef, Array of DocumentRef - A VAT accounting document or an array of documents that you need to complete tasks for.
//
Procedure ExecuteGenerationRegisteredRecordsForVAT(EndOfPeriod, Organization = Undefined, Invoices_ = Undefined) Export
	
	If Organization <> Undefined Then
		CompanyArray = TMCommonUseClientServer.Array(Organization);
	Else
		CompanyArray = Undefined;
	EndIf;
	
	If Invoices_ <> Undefined Then
		ArrayOfInvoices_ = TMCommonUseClientServer.Array(Invoices_);
	Else
		ArrayOfInvoices_ = Undefined;
	EndIf;
	
	VATAccountingERPInternal.CompleteTasksForGeneratingVATRegisteredRecords(EndOfPeriod, CompanyArray, ArrayOfInvoices_);
	
EndProcedure

#EndRegion

#Region RegulatedReporting

// Sets the parameters of the Form for selecting the document of the basis for filling 
//  out the report "Statistical Form of accounting for the movement of goods".
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of document selection is the basis for filling out the statform. 
//
//
Procedure SetPropertiesOfFormOfChoiceForVFTSStatform(Form) Export
	
	Parameters = Form.Parameters;
	Items = Form.Items;
	FormName = Form.FormName;
	
	ListName = "List";
	
	If FormName = "Document.CustomerInvoice.Form.ChoiceForm" Then
		ListName = "ListGoodsServicesSale";
	EndIf;
	
	If Parameters.Statform Then
		
		
	Else
		
		Items.GroupSelectionsForStatform.Visible = False;
		
		If FormName = "Document.CustomerInvoice.Form.ChoiceForm" Then
			Items[ListName + "CustomerCounterparty"].Visible = False;
		EndIf;
		
		Items[ListName + "CountryOfSale"].Visible = False;
		Items[ListName + "VATTaxation"].Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DescriptionOfDocumentsForJournals

// Adds business transactions and VAT accounting documents for the Purchase document log to the passed table
//
// Parameters:
//  BusinessTransactionsAndDocuments - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure DescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments) Export
	
	// Importation Statement
	
	LineApplicationForImportOfGoods = BusinessTransactionsAndDocuments.Add();
	String = LineApplicationForImportOfGoods;
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEU;
	String.AddButtonCreate		= True;
	String.DocumentType 				= Type("DocumentRef.ApplicationForImportationOfGoods");
	String.FullDocumentName			= "Document.ApplicationForImportationOfGoods";
	String.PurposeUseKey 	= "ImportApplicationsForRegistration";
	String.WorkplaceTitle = NStr("vi = 'Chứng từ mua hàng (đơn xin nhập khẩu)';
								|ru = 'Документы закупки (заявления о ввозе)';
								|en = 'Purchase documents (import applications)'; fa = 'Purchase documents (import applications)';
								|it = 'Documenti di acquisto (dichiarazione di importazione)';
								|pl = 'Dokumenty zakupu (oświadczenie o imporcie)';
								|tr = 'Satın alma belgeleri (i̇thalat başvurusu)'");
	String.HyperlinkCalculationManagerForRegistration = "Document.ApplicationForImportationOfGoods";
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineApplicationForImportOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit;
	
	String = BusinessTransactionsAndDocuments.Add();
	FillPropertyValues(String,LineApplicationForImportOfGoods);
	String.BusinessOperation 		= Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	VATAccountingLocalization.CompleteDescriptionOfOperationsAndDocumentTypesForProcurementDocumentLog(BusinessTransactionsAndDocuments);
	
EndProcedure

// Adds business transactions and VAT accounting documents for the Sales document journal to the passed table
//
// Parameters:
//  VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure DescriptionOfOperationsAndDocumentTypesForSalesDocumentLog(VTBusinessTransactionsAndDocumentTypes) Export
	
	VATAccountingLocalization.CompleteDescriptionOfOperationsAndDocumentTypesForSalesDocumentLog(VTBusinessTransactionsAndDocumentTypes);

EndProcedure

// Adds business transactions and VAT accounting documents to the transmitted table for the processing document log 2.4
//
// Parameters:
//  VTBusinessTransactionsAndDocumentTypes - See TMCommonUse.NewTableBusinessOperationsAndDocuments
//
Procedure DescriptionOfOperationsAndDocumentTypesForProcessingDocumentLog(VTBusinessTransactionsAndDocumentTypes) Export
	
	VATAccountingLocalization.CompleteDescriptionOfOperationsAndDocumentTypesForProcessingDocumentLog(VTBusinessTransactionsAndDocumentTypes);

EndProcedure

// Adds business transactions and VAT accounting documents to the transferred table for the log of documents transferred for processing 2.5
//
// Parameters:
//  VTBusinessTransactionsAndDocumentTypes - ValueTable - document log operations table
//
Procedure DescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsOfTransferToProcessing2_5(VTBusinessTransactionsAndDocumentTypes) Export
	
	VATAccountingLocalization.CompleteDescriptionOfOperationsAndDocumentTypesForJournalOfDocumentsTransferredToProcessing2_5(VTBusinessTransactionsAndDocumentTypes);
	
EndProcedure

// Adds business transactions and VAT accounting documents to the transmitted table for the log of documents accepted for processing 2.5
//
// Parameters:
//  VTBusinessTransactionsAndDocumentTypes - ValueTable - document log operations table
//
Procedure DescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsAcceptedForProcessing2_5(VTBusinessTransactionsAndDocumentTypes) Export
	
	VATAccountingLocalization.ToCompleteDescriptionOfOperationsAndTypesOfDocumentsForJournalOfDocumentsAcceptedForProcessing2_5(VTBusinessTransactionsAndDocumentTypes);

EndProcedure

#EndRegion

#Region KBSPConnection

// Parameters:
//  Objects - Array of MetadataObject
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.VATWritingOffAsExpenses);
	Objects.Add(Metadata.Documents.VATAllocation);
	Objects.Add(Metadata.Documents.IssuedTaxInvoicePrepayment);
	Objects.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment);
	Objects.Add(Metadata.Documents.ApplicationForImportationOfGoods);
	
	VATAccountingLocalization.DefineObjectsWithReportCommands(Objects);

EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
	Reports.AnalysisOfVATAccrualsFromAdvancePaymentsReceived.CustomizeReportOptions(Settings);
	Reports.VATAccountingAnalysisOnPrepaymentsFromCustomerSettlement.CustomizeReportOptions(Settings);
	Reports.VATAccountingAnalysisOnPrepaymentsToVendorSettlement.CustomizeReportOptions(Settings);
	Reports.TurnoversByVAT.CustomizeReportOptions(Settings);
	Reports.StatementOnVATCharged.CustomizeReportOptions(Settings);
		
	VATAccountingLocalization.CustomizeReportsOptions(Settings);
	
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
									
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VATInvoiced.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VATPrepaymentsToVendor.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.VATRegisterRecords.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.VATWritingOffAsExpenses.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.VATAllocation.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.IssuedTaxInvoicePrepayment.FullName(),
										"PrepaymentReceiptDate",
										"Sales",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceivedTaxInvoicePrepayment.FullName(),
										"RecordingInAccountingDate",
										"Purchases",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReverseVATAccrual.FullName(),
										"Date",
										"Purchases",
										"Organization");

	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ApplicationForImportationOfGoods.FullName(),
										"Date",
										"Purchases",
										"Organization");
	
	VATAccountingLocalization.FillDataSourcesForPeriodClosingCheck(DataSources);

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
//	
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	VATAccountingLocalization.OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands);
	
EndProcedure

//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.VATAllocation);
	Objects.Add(Metadata.Documents.IssuedTaxInvoicePrepayment);
	Objects.Add(Metadata.Documents.ReceivedTaxInvoicePrepayment);
	Objects.Add(Metadata.Documents.ApplicationForImportationOfGoods);
	
	VATAccountingLocalization.OnDefineObjectsWithCreationBasedOnCommands(Objects)
	
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
//
Procedure OnDefinePrintSettings(Settings) Export
	
	ListOfObjects = Settings.PrintObjects;
	
	ListOfObjects.Add(Documents.VATWritingOffAsExpenses);
	ListOfObjects.Add(Documents.VATAllocation);
	ListOfObjects.Add(Documents.IssuedTaxInvoicePrepayment);
	ListOfObjects.Add(Documents.ReceivedTaxInvoicePrepayment);
	ListOfObjects.Add(Documents.ApplicationForImportationOfGoods);
	
	VATAccountingLocalization.OnDefinePrintSettings(Settings);
	
EndProcedure

// Defines configuration objects, in the manager modules of which the Add Print Command procedure is placed,
// which forms a list of print commands provided by this object.
// For the syntax of the Add Print Command procedure, see the documentation for the subsystem.
// Parameters:
//  ListOfObjects - Array of DocumentObject - object managers with the add print Command procedure.
//
Procedure OnDefineObjectsWithPrintCommands(ListOfObjects) Export
	VATAccountingLocalization.OnDefineObjectsWithPrintCommands(ListOfObjects);
EndProcedure 

// Overrides the list of print commands received by the print Management function.Comodification.
// Used for General forms that do not have a Manager module for placing the add command Print procedure in it,
// for cases when there are not enough regular tools for adding commands to such forms. For example, if you need your own commands
// that are not available in other objects.
// 
// Parameters:
//  FormName             - String - full name of the form to add print commands to;
//  PrintCommands        - See PrintManagement.CreatePrintCommandsCollection
//  StandardProcessing - Boolean - if set to False, the print Command collection will not be automatically populated.
//
Procedure BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing) Export
	
	VATAccountingLocalization.BeforeAddPrintCommands(FormName, PrintCommands, StandardProcessing);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Documents.VATWritingOffAsExpenses, True);
	Lists.Insert(Metadata.Documents.VATAllocation, True);
	Lists.Insert(Metadata.Documents.IssuedTaxInvoicePrepayment, True);
	Lists.Insert(Metadata.Documents.ReceivedTaxInvoicePrepayment, True);
	Lists.Insert(Metadata.Documents.ApplicationForImportationOfGoods, True);
	Lists.Insert(Metadata.AccumulationRegisters.VATPrepaymentsToVendor, True);
	Lists.Insert(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer, True);
	Lists.Insert(Metadata.AccumulationRegisters.VATInvoiced, True);
	Lists.Insert(Metadata.AccumulationRegisters.VATRegisterRecords, True);
	Lists.Insert(Metadata.Catalogs.IssuedTaxInvoicePrepaymentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReceivedTaxInvoicePrepaymentAttachedFiles, True);
	
	VATAccountingLocalization.OnFillListsWithAccessRestriction(Lists);
	
EndProcedure

#EndRegion

// Returns the structure of VAT registers
// 
// Returns:
// 	Structure - The structure of VAT registers, where:
// 	     * Key - String - Register name
// 	     * Value - AccumulationRegisterRecordSet - a set of register entries.
Function VATRegisters_() Export
	
	VATRegisters = New Structure();
	VATRegisters.Insert(Metadata.AccumulationRegisters.VATInvoiced.Name, AccumulationRegisters.VATInvoiced.CreateRecordSet());
	VATRegisters.Insert(Metadata.AccumulationRegisters.VATPrepaymentsToVendor.Name, AccumulationRegisters.VATPrepaymentsToVendor.CreateRecordSet());
	VATRegisters.Insert(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Name, AccumulationRegisters.VATPrepaymentsFromCustomer.CreateRecordSet());
	VATRegisters.Insert(Metadata.AccumulationRegisters.LotsVATForAllocation.Name, AccumulationRegisters.LotsVATForAllocation.CreateRecordSet());
	VATRegisters.Insert(Metadata.AccumulationRegisters.VATRegisterRecords.Name, AccumulationRegisters.VATRegisterRecords.CreateRecordSet());
	
	VATAccountingLocalization.AddVATRegisters(VATRegisters);
	
	Return VATRegisters;
	
EndFunction

// Returns VAT registers that can be used as a source of household data. operations in MFIs and Budgeting.
// 
// Returns:
// 	ValueList of MetadataObject
//
Function SourcesOfBusinessTransactionData() Export
	
	VATRegisters = New ValueList();
	VATRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Name, Metadata.AccumulationRegisters.VATPrepaymentsFromCustomer.Synonym);
	VATRegisters.Add(Metadata.AccumulationRegisters.VATPrepaymentsToVendor.Name, Metadata.AccumulationRegisters.VATPrepaymentsToVendor.Synonym);
	VATRegisters.Add(Metadata.AccumulationRegisters.VATRegisterRecords.Name, Metadata.AccumulationRegisters.VATRegisterRecords.Synonym);
	Return VATRegisters;
	
EndFunction

// Returns the selection for the item selection list according to the operation's taxation 
// 
// Parameters:
// 	VATTaxation - EnumRef.VATTaxationTypes - taxation of the operation in which the selection is made
// 
// Returns:
// 	Array of Structure - array of selection structures for the Nomenclature directory:
// 	* Attribute - String
// 	* ComparisonType - DataCompositionComparisonType
// 	* Value - EnumRef.VATTaxationTypes
//
Function RestrictionOfGoodsOnTaxation(VATTaxation) Export
	
	Restrictions = New Array;
	
	VATAccountingLocalization.SupplementRestrictionOfGoodsOnTaxation(Restrictions, VATTaxation);
	
	Return Restrictions;
	
EndFunction

// Generates a description of technological parameters.
// 
// Returns:
// 	ValueTable:
//  * Name - String -
//  * Description - String -
//  * LongDesc - String -
//  * OldNames - String -
//  * Parent - String -
//  * ValueType - TypeDescription -
//  * RangeWith - Number, Date -
//  * RangeBy - Number, Date -
//  * Hide - Boolean -
//  * DefaultValue - Arbitrary -
//  * AdditionalProperties - Arbitrary -
// 
Function DescriptionOfParametersOfMonthClosingOperation() Export
	
	ParametersDetails = Constants.MonthEndClosingSettings.CreateValueManager().InitializeDescriptionOfOperationParameters();
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name 				  = "NumberOfTasksForVATCalculation";
	ParameterDetails.Description 		  = NStr("vi = 'Số lượng nhiệm vụ để tính thuế GTGT từng phần';
													|ru = 'Количество заданий для порционного расчета НДС';
													|en = 'Number of tasks for batch VAT calculation'; fa = 'Number of tasks for batch VAT calculation';
													|it = 'Quantità di compiti per il calcolo IVA parziale';
													|pl = 'Ilość zadań dla porcjowego obliczenia VAT';
													|tr = 'KDV''nin orantılı hesaplanması için görev sayısı'");
	ParameterDetails.ValueType   	  = New TypeDescription("Number",,, New NumberQualifiers(10, 0, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith     	  = 100;
	ParameterDetails.DefaultValue = 1000;
	ParameterDetails.LongDesc =
		NStr("vi = 'Không phải tất cả nhiệm vụ đều tính thuế GTGT cuối tháng cùng một lúc mà tính từng phần riêng biệt.
              |Thực chất đây là các yêu cầu theo chu kỳ nên hiệu suất bị giảm. Mặt khác, dung lượng bộ nhớ máy chủ cần thiết để tính toán bị giảm nghiêm trọng.
              |Có thể tăng dung lượng tính toán để tìm ra sự tương thích giữa bộ nhớ máy chủ và thời lượng tính toán của giai đoạn.';
              |ru = 'Расчет НДС в закрытии месяца выполняется не для всех заданий разом, а обсчитываются отдельные порции.
              |По сути это запросы в цикле, поэтому снижается производительность. Зато критично уменьшается требуемый объем памяти сервера для расчета.
              |Можно увеличить размер порции расчета, чтобы найти компромисс между памятью сервера и длительностью расчета этапа.';
              |en = 'VAT calculation in the month-end closing is not performed for all tasks at once, but separate batches are calculated.
              |These are requests in a loop, so performance is degraded. The required amount of server memory for calculation is significantly reduced.
              |You can increase the calculation batch size to find a compromise between the server memory and the stage calculation duration.'; fa = 'VAT calculation in the month-end closing is not performed for all tasks at once, but separate batches are calculated.
              |These are requests in a loop, so performance is degraded. The required amount of server memory for calculation is significantly reduced.
              |You can increase the calculation batch size to find a compromise between the server memory and the stage calculation duration.';
              |it = 'Calcolo IVA alla fine del mese eseguito non per tutti i compiti insieme, ma a porzioni separate.
              |Fondamentalmente sono richieste cicliche, e dunque la produttività viene ridotta. Inoltre diminuisce in maniera critica il volume richiesto di memoria del server per il calcolo.
              |Inoltre è possibile aumentare la dimensione delle porzioni di calcolo per trovare un compromesso tra la memoria di server e la durata della fase di calcolo.';
              |pl = 'Obliczenie VAT w zamknięciu miesiąca nie dla wszystkich zadań od razu, a są obliczane oddzielne porcje.
              |W istocie te zapytania w cyklu, dlatego zmniejsza się wydajność. Natomiast krytycznie zmniejsza się wymagana  objętość pamięci serwera w celu obliczenia.
              |Można zwiększyć rozmiar porcji obliczenia, aby znaleźć kompromis między pamięcią a czasem trwania obliczenia etapu.';
              |tr = 'Ay sonu kapanışında KDV hesaplaması tüm görevler için bir kerede yapılmaz, ancak farklı bölümler hesaplanır.
              |Özünde, bunlar bir döngü içindeki sorgulardır, bu nedenle performans azalır. Aynı zamanda, hesaplama için gereken sunucu belleği miktarı da ciddi ölçüde azalır.
              |Sunucu belleği ile aşama hesaplamasının süresi arasında bir uzlaşma bulmak için hesaplama bölümünün boyutunu artırabilirsiniz.'");
	
	ParameterDetails = ParametersDetails.Add();
	ParameterDetails.Name 				  = "RoundingErrorWriteOffThreshold";
	ParameterDetails.Description 		  = NStr("vi = 'Ngưỡng giảm sai số làm tròn';
													|ru = 'Порог списания погрешностей округления';
													|en = 'Threshold of error rounding write-off'; fa = 'Threshold of error rounding write-off';
													|it = 'Limite del margine di errore dovuto all''arrotondamento';
													|pl = 'Próg rozchodu błędów zaokrąglenia';
													|tr = 'Yuvarlama hatasının silinmesi eşiği'");
	ParameterDetails.ValueType   	  = New TypeDescription("Number",,, New NumberQualifiers(3, 2, AllowedSign.Nonnegative));
	ParameterDetails.RangeWith     	  = 0;
	ParameterDetails.DefaultValue = 0;
	ParameterDetails.LongDesc =
		NStr("vi = 'Khi tính lô hàng có thuế GTGT, có thể xuất hiện sai số làm tròn, do đó trong biểu ghi ""Thuế GTGT tạm tính"" có thể có số dư bằng đồng.
              |Nếu chỉ ra ngưỡng khác 0 khi giảm sai số làm tròn thì tất cả số dư trong ngưỡng này sẽ được ghi giảm vào chi phí có dạng ""Chênh lệch trong giá trị hàng hóa"".
              |Nếu ngưỡng này bằng 0 thì không thực hiện thao tác giảm sai số làm tròn.';
              |ru = 'При расчете партий НДС могут возникать погрешности округления, из-за которых в регистре “НДС предъявленный” могут оставаться копеечные остатки.
              |Если указать ненулевой порог списания погрешности округления, то все остатки в пределах этого порога будут списаны на расходы на статью “Отклонение в стоимости товаров”.
              |Если порог равен нулю, то операция списания погрешностей округления не выполняется.';
              |en = 'When calculating VAT lots, rounding errors may occur, which may result in pennyworth balances in the ""Charged VAT"" register.
              |If you specify a non-zero threshold for writing off a rounding error, then all balances within this threshold will be written off as expenses to the ""Goods cost variance"" item.
              |If the threshold is equal to zero, then the rounding error write-off is not performed.'; fa = 'When calculating VAT lots, rounding errors may occur, which may result in pennyworth balances in the ""Charged VAT"" register.
              |If you specify a non-zero threshold for writing off a rounding error, then all balances within this threshold will be written off as expenses to the ""Goods cost variance"" item.
              |If the threshold is equal to zero, then the rounding error write-off is not performed.';
              |it = 'Nel calcolare IVA, si possono verificare errori dovuti all''arrotondamento, a causa dei quali nel registro ""IVA fatturata"" possono essere presenti delle differenze di qualche centesimo.
              |Se viene indicato un limite del margine di errore dovuto all''arrotondamento diverso da zero, tutti i saldi che rientrano in tale limite saranno stornati come ""Variazione nel costo delle merci"".
              |Se il limite è pari a zero, l''operazione di storno delle differenze dovute all''arrotondamento non verrà eseguita.';
              |pl = 'Przy obliczeniu partii VAT mogą występować błędy zaokrąglenia z powodu których w rejestrze “VAT zgłoszony” mogą pozostawać reszty w groszach.
              |Jeśli podać niezerowy próg rozchodu błędu zaokrąglenia, to wszystkie reszty w zakresie tego progu zostaną wyrejestrowane na rozchody na pozycję “Odchylenie w wartości towarów”.
              |Jeśli próg ma wartość zero, to operacja rozchodu błędów zaokrąglenia nie jest wykonywania.';
              |tr = 'KDV lotları hesaplanırken, ""Yüklenilen KDV"" kaydında kuruş bakiyeleri bırakabilecek yuvarlama hataları oluşabilir.
              |Yuvarlama hatalarını gider yazmak için sıfır olmayan bir eşik belirlenirse, bu eşik dahilindeki tüm bakiyeler ""Ürünlerin değerindeki sapma"" kalemine giderleştirilir.
              |Eşik sıfırsa, yuvarlama hatası gider yazma işlemi gerçekleştirilmez.'");
	
	Return ParametersDetails;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function QueryTextObjectsToReplace(WithSelectionByPeriod)
	
	If WithSelectionByPeriod Then
		
		QueryText = "
		|SELECT
		|	Catalog.Ref AS Ref
		|FROM
		|	Catalog.CounterpartyContracts AS Catalog
		|WHERE
		|	Catalog.VATRate = &CurRate_
		|	AND Catalog.Status <> VALUE(Enum.CounterpartyContractStatuses.Closed)
		|	AND NOT Catalog.DeletionMark
		|	AND (Catalog.ValidityEndDate >= &Period
		|			OR Catalog.ValidityEndDate = &DateEmpty)
		|";
		
	Else
		
		QueryText = "
		|SELECT
		|	Catalog.Ref AS Ref
		|FROM
		|	Catalog.CounterpartyContracts AS Catalog
		|WHERE
		|	Catalog.VATRate = &CurRate_
		|	AND NOT Catalog.DeletionMark
		|";
		
	EndIf;
		
	Return QueryText;
	
EndFunction

Procedure BlockAndRecordCatalog(CatalogObject, VATRate, Current_VATRate, LockItem)
	
	If CatalogObject.VATRate <> Current_VATRate Then
		Return;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add(LockItem);
	LockItem.Mode = DataLockMode.Exclusive;
	LockItem.SetValue("Ref", CatalogObject.Ref);
	Block.Lock();
	
	CatalogObject.VATRate = VATRate;
	CatalogObject.DataExchange.Load = True;
	
	CatalogObject.Write();
	
EndProcedure

#EndRegion
