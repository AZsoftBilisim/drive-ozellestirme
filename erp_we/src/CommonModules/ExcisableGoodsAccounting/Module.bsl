#Region Public

#Region SettingsAndParametersForAccountingForExcisableItems

// Returns an indication of whether the import of excisable items is used.
//
// Parameters:
//  Organization - CatalogRef.Companies - The organization for which the attribute of accounting
//  											for excisable items is determined.
//  Period - Date - The date at the beginning of the month when the attribute of accounting for excisable items is determined.
//
// Returns:
//  Boolean
//
Function ImportOfExcisableItemsIsUsed(Organization, Period) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	ExcisableItemIsBeingImported = False;
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Organization,
		Period,
		False);
	
	If AccountingPolicyParameters <> Undefined Then
		ExcisableItemIsBeingImported = AccountingPolicyParameters.ImportsExcisableGoods;
	EndIf;
	
	Return ExcisableItemIsBeingImported;
	
EndFunction

// Returns an indication of the use of excisable item production.
//
// Parameters:
//  Organization - CatalogRef.Companies - The organization for which the attribute of accounting
//  											for excisable items is determined.
//  Period - Date - The date at the beginning of the month when the attribute of accounting for excisable items is determined.
//
// Returns:
//  Boolean
//
Function ProductionOfExcisableItemsIsUsed(Organization, Period) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	ExcisableItemIsProduced = False;
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Organization,
		Period,
		False);
	
	If AccountingPolicyParameters <> Undefined Then
		ExcisableItemIsProduced = AccountingPolicyParameters.ProducesExcisableGoods;
	EndIf;
	
	Return ExcisableItemIsProduced;
	
EndFunction

// Creates a temp table 'In the manufacturer of excisable goods', which contains information on the financial accounting policies
// of companies regarding the production of excisable items as of the document date.
//
// Parameters:
//	DocumentObject - DocumentObject - Document data.
//	TempTablesManager - TempTablesManager - temporary query table manager where the table is placed
//														'The manufacturer of excisable goods'.
//	ByAllCompanies - Boolean - indicates the method of getting data. FALSE - by default, information is obtained
//									from document data.
//
Procedure ManufacturersOfExcisableItems(DocumentObject, TempTablesManager, ByAllCompanies = False) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	If TempTablesManager.Tables.Find("TTManufacturersOfExcisableItems") <> Undefined Then
		Query.Text = "DROP TTManufacturersOfExcisableItems";
		
		Query.Execute();
	EndIf;
	
	If ByAllCompanies Then
		AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(TempTablesManager);
		
		QueryText =
		"SELECT
		|	Accounting_Policies.Organization AS Organization,
		|	Accounting_Policies.ProducesExcisableGoods AS ProducesExcisableGoods
		|INTO TT_AccountingPolicies
		|FROM
		|	InformationRegister.FinancialAccountingPolicy.SliceLast(&Period, Organization IN
		|		(SELECT
		|			ParentOrganizations.Organization
		|		FROM
		|			TTParentOrganizations AS ParentOrganizations)) AS Accounting_Policies
		|WHERE
		|	Accounting_Policies.ProducesExcisableGoods
		|
		|INDEX BY
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatalogCompanies.Ref	AS Organization,
		|	CASE
		|		WHEN CatalogCompanies.RegistrationCountry <> VALUE(Catalog.WorldCountries.EmptyRef)
		|			THEN CatalogCompanies.RegistrationCountry
		|		ELSE &MainCountry
		|	END							AS Country,
		|	ISNULL(TT_AccountingPolicies.ProducesExcisableGoods, FALSE) AS ProducesExcisableGoods
		|INTO TTManufacturersOfExcisableItems
		|FROM
		|	TTParentOrganizations AS ParentOrganizations
		|		LEFT JOIN TT_AccountingPolicies AS TT_AccountingPolicies
		|		ON ParentOrganizations.Organization = TT_AccountingPolicies.Organization
		|		
		|		INNER JOIN Catalog.Companies AS CatalogCompanies
		|		ON ParentOrganizations.BranchOffice = CatalogCompanies.Ref
		|
		|INDEX BY
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TT_AccountingPolicies";
		
		Period = ?(ValueIsFilled(DocumentObject.Date), DocumentObject.Date, CurrentSessionDate());
		
		Query.SetParameter("Period",			Period);
		Query.SetParameter("MainCountry",	SettingsValueClientServerCached.MainCountry());
	Else
		QueryText =
		"SELECT
		|	&Organization	AS Organization,
		|	&Country			AS Country,
		|	&ProductionOfExcisableItemsIsUsed AS ProducesExcisableGoods
		|INTO TTManufacturersOfExcisableItems";
		
		RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(DocumentObject.Organization);
		ProductionOfExcisableItemsIsUsed = ProductionOfExcisableItemsIsUsed(
														DocumentObject.Organization,
														DocumentObject.Date);
		
		Query.SetParameter("Organization",	DocumentObject.Organization);
		Query.SetParameter("Country",			RegistrationCountry);
		Query.SetParameter("ProductionOfExcisableItemsIsUsed",
									ProductionOfExcisableItemsIsUsed);
	EndIf;
	
	Query.Text = QueryText;
	
	Query.Execute();
	
EndProcedure

// Returns the Query Text of the temporary table 'In the manufacturer of excisable goods', which contains information about the financial
// accounting policies of organizations regarding the production of excisable items by period of the document.
// The executed query must contain a temporary table with columns 'Period' and 'Organization'.
// The request parameter 'Main Country' must also be set.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary query table manager where the table is placed
//														'The manufacturer of excisable goods'.
//	ProductTableName_ - String - the name of the temp table of items selected in the register.
//									The default is 'Table of Goods'.
//
// Returns:
//	String - The text of the temporary table query.
//
Function QueryTextManufacturersOfExcisableItems(TempTablesManager, ProductTableName_ = "TableOfGoods") Export
	
	AccountingPoliciesTaxSettings.AddParentOrganizationsToTemporaryTableManager(TempTablesManager);
	
	If TempTablesManager.Tables.Find("TTManufacturersOfExcisableItems") <> Undefined Then
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "DROP TTManufacturersOfExcisableItems";
		
		Query.Execute();
	EndIf;
	
	QueryText =
	"SELECT
	|	TableOfGoods.Period			AS Period,
	|	Accounting_Policies.Organization		AS Organization,
	|	MAX(Accounting_Policies.Period)	AS ActionPeriod
	|INTO TT_AccountingPolicies
	|FROM
	|	#TableOfGoods AS TableOfGoods
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS Accounting_Policies
	|		ON TableOfGoods.Period >= Accounting_Policies.Period
	|
	|GROUP BY
	|	TableOfGoods.Period,
	|	Accounting_Policies.Organization
	|
	|INDEX BY
	|	ActionPeriod,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT_AccountingPolicies.Period							AS Period,
	|	ParentOrganizations.BranchOffice	AS Organization,
	|	CASE
	|		WHEN CatalogCompanies.RegistrationCountry <> VALUE(Catalog.WorldCountries.EmptyRef)
	|			THEN CatalogCompanies.RegistrationCountry
	|		ELSE &MainCountry
	|	END											AS Country,
	|	Accounting_Policies.ProducesExcisableGoods		AS ProducesExcisableGoods
	|INTO TTManufacturersOfExcisableItems
	|FROM
	|	TT_AccountingPolicies AS TT_AccountingPolicies
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy AS Accounting_Policies
	|		ON TT_AccountingPolicies.ActionPeriod = Accounting_Policies.Period
	|			AND TT_AccountingPolicies.Organization = Accounting_Policies.Organization
	|		
	|		INNER JOIN TTParentOrganizations AS ParentOrganizations
	|		ON TT_AccountingPolicies.Organization = ParentOrganizations.Organization
	|		
	|		INNER JOIN #TableOfGoods AS TableOfGoods
	|		ON ParentOrganizations.BranchOffice = TableOfGoods.Organization
	|		
	|		INNER JOIN Catalog.Companies AS CatalogCompanies
	|		ON ParentOrganizations.BranchOffice = CatalogCompanies.Ref
	|
	|INDEX BY
	|	Period,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_AccountingPolicies";
	
	QueryText = StrReplace(QueryText, "#TableOfGoods", ProductTableName_);
	
	Return QueryText;
	
EndFunction

// Determines whether the item belongs to the excisable category of items in the country of registration of the company.
//
// Parameters:
//	Products - CatalogRef.Products - The item for which it is necessary to determine
//		whether the item belongs to the excise category.
//	Organization - CatalogRef.Companies - The company that determines the country of registration
//		for determining the excise category of the item.
//	Period - Date, Undefined - The date on which the belonging to the excise category of the item is determined.
//		If the value is not passed, the affiliation is determined as of the current date.
//
// Returns:
//	Boolean - True if the item belongs to the excisable category of items.
//
Function ThisIsExcisableProduct(Products, Organization = Undefined, Val Period = Undefined) Export
	
	ThisIsExcisableProduct = False;
	
	If Period = Undefined Then
		Period = CurrentSessionDate();
	EndIf;
	
	If Organization <> Undefined
		Or Not GetFunctionalOption("UseMultiCountryAccounting") Then
		
		If Organization <> Undefined Then
			Country = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
		Else
			Country = SettingsValueClientServerCached.MainCountry();
		EndIf;
		
		Filter = New Structure("Products, Country", Products, Country);
		ThisIsExcisableProduct =
			InformationRegisters.ExcisableGoodsCategories.GetLast(Period, Filter).ExcisableGoods;
	Else
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	TRUE AS ExcisableGoods
		|FROM
		|	InformationRegister.ExcisableGoodsCategories.SliceLast(
		|			&CurrentDate,
		|			Products = &Products) AS ExciseTaxesOfNomenclatureSectionOfLatter
		|WHERE
		|	ExciseTaxesOfNomenclatureSectionOfLatter.ExcisableGoods";
		
		Query.SetParameter("Products", Products);
		Query.SetParameter("CurrentDate", Period);
		
		Result = Query.Execute().Select();
		ThisIsExcisableProduct = Result.Next();
		
	EndIf;
	
	Return ThisIsExcisableProduct;
	
EndFunction

// Gets a table of excise categories by item.
//
// Parameters:
//	Products - CatalogRef.Products - The item for which it is necessary to determine
//		whether the item belongs to the excise category.
//	Organization - CatalogRef.Companies - The company that determines the country of registration
//		for determining the excise category of the item.
//	Period - Date, Undefined - The date on which the belonging to the excise category of the item is determined.
//		If the value is not passed, the affiliation is determined as of the current date.
//
// Returns:
//	ValueTable:
//		* ExcisableGoodsCategory - CatalogRef.ExcisableGoodsCategories - excise category;
//		* RateType - EnumRef.TypesOfExcisableCategoryRates - type of rate of excise category;
//		* Currency - CatalogRef.Currencies - bid currency;
//		* UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - The unit of the excise category;
//		* Rate1 - Number - the rate of the excise category.
//
Function ExcisableItemCategories(Products, Organization = Undefined, Val Period = Undefined) Export
	
	Country = Undefined;
	
	If Period = Undefined Then
		Period = CurrentSessionDate();
	EndIf;
	
	If Organization <> Undefined
		Or Not GetFunctionalOption("UseMultiCountryAccounting") Then
		
		If Organization <> Undefined Then
			Country = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
		Else
			Country = SettingsValueClientServerCached.MainCountry();
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ExciseCategories.ExcisableGoodsCategory AS Category
	|INTO Category_Data
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&CurrentDate, Products = &Products
	|	AND (Country = &Country
	|	OR NOT &SelectionByCountry)) AS ExciseCategories
	|WHERE
	|	ExciseCategories.ExcisableGoods
	|
	|INDEX BY
	|	Category
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExciseTaxRates.ExcisableGoodsCategory AS Category,
	|	ExciseTaxRates.Rate1 AS Rate1
	|INTO ExciseTaxRates
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&CurrentDate,
	|			ExcisableGoodsCategory IN
	|			(SELECT
	|				Category_Data.Category
	|			FROM
	|				Category_Data)) AS ExciseTaxRates
	|
	|INDEX BY
	|	Category
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Category_Data.Category AS ExcisableGoodsCategory,
	|	ExcisableGoodsCategories.RateType AS RateType,
	|	ExcisableGoodsCategories.Currency AS Currency,
	|	ExcisableGoodsCategories.UnitOfMeasure AS UnitOfMeasure,
	|	CASE
	|		WHEN ExcisableGoodsCategories.RateType IS NULL
	|			THEN 0
	|		WHEN ExcisableGoodsCategories.RateType = &FirmBet
	|			THEN ExciseTaxRates.Rate1
	|		ELSE 0
	|	END AS Rate1
	|FROM
	|	Category_Data AS Category_Data
	|		LEFT JOIN Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|		ON Category_Data.Category = ExcisableGoodsCategories.Ref
	|		LEFT JOIN ExciseTaxRates AS ExciseTaxRates
	|		ON ExciseTaxRates.Category = Category_Data.Category";
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Country", Country);
	Query.SetParameter("SelectionByCountry", Country <> Undefined);
	Query.SetParameter("CurrentDate", Period);
	Query.SetParameter("FirmBet", Enums.TypesOfExcisableCategoryRates.FixedRate);
	
	Return Query.Execute().Unload();
	
EndFunction

// Gets a table of excise categories by item.
//
// Parameters:
//	Products - CatalogRef.Products - The item for which it is necessary to determine
//		the list of excise categories.
//	Country - CatalogRef.WorldCountries, Undefined - The country by which the excise categories of the item are determined.
//	Period - Date, Undefined - The date on which the belonging to the excise category of the item is determined.
//		If the value is not passed, the affiliation is determined as of the current date.
//
// Returns:
//	ValueTable:
//		* Period - Date - the beginning of the period of validity of the excise category;
//		* Country - CatalogRef.WorldCountries - country of validity of the excise category;
//		* UnitOfProductMeasurement_ - CatalogRef.PackagesAndUnitsOfMeasure - The unit of item measurement;
//		* ExcisableGoods - Boolean - indicates that the item is excisable;
//		* ExcisableGoodsCategory - CatalogRef.ExcisableGoodsCategories - excise category;
//		* CategoryUnitOfMeasurement - CatalogRef.PackagesAndUnitsOfMeasure - The unit of the excise category;
//		* RateType - EnumRef.TypesOfExcisableCategoryRates - type of rate of excise category;
//		* Currency - CatalogRef.Currencies - bid currency;
//		* Rate1 - Number - the rate of the excise category;
//		* ConversionFactor_ - Number - conversion ratio from the unit of measurement of the nomenclature to the unit of measurement of the excise category;
//		* UnitOfItemInCategory - String - the name of the unit of measurement of the category
//			and the name of the unit of measurement of the item.
//
Function GetHistoryOfItemCategories(Products, Val Country = Undefined, Period = Undefined) Export
	
	If Not ValueIsFilled(Country)
		And Not GetFunctionalOption("UseMultiCountryAccounting") Then
		
		Country = SettingsValueClientServerCached.MainCountry();
		
	EndIf;

	Query = New Query;
	Query.Text = "SELECT
	|	ExcisableGoodsCategories.Period AS Period,
	|	ExcisableGoodsCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	ExcisableGoodsCategories.ConversionFactor_ AS ConversionFactor_,
	|	ExcisableGoodsCategories.ExcisableGoods AS ExcisableGoods,
	|	ExcisableGoodsCategories.Country AS Country
	|INTO ListOfCategories
	|FROM
	|	InformationRegister.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|WHERE
	|	ExcisableGoodsCategories.Products = &Products
	|	AND (ExcisableGoodsCategories.Country = &Country
	|	OR NOT &CountryIsFull)
	|	AND NOT &FilterByPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	ExcisableGoodsCategories.Period,
	|	ExcisableGoodsCategories.ExcisableGoodsCategory,
	|	ExcisableGoodsCategories.ConversionFactor_,
	|	ExcisableGoodsCategories.ExcisableGoods,
	|	ExcisableGoodsCategories.Country
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, Products = &Products
	|	AND (Country = &Country
	|	OR NOT &CountryIsFull)) AS ExcisableGoodsCategories
	|WHERE
	|	&FilterByPeriod
	|
	|INDEX BY
	|	ExcisableGoodsCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RatesOfExcisableGoodsCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	RatesOfExcisableGoodsCategories.Rate1 AS Rate1
	|INTO RatesOfExcisableGoodsCategories
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&Period, &FilterByPeriod
	|		AND ExcisableGoodsCategory IN
	|			(SELECT
	|				ListOfCategories.ExcisableGoodsCategory
	|			FROM
	|				ListOfCategories)) AS RatesOfExcisableGoodsCategories
	|
	|INDEX BY
	|	ExcisableGoodsCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfCategories.Period AS Period,
	|	ListOfCategories.Country AS Country,
	|	ProductData_1.UnitOfMeasure AS UnitOfProductMeasurement_,
	|	ListOfCategories.ExcisableGoods AS ExcisableGoods,
	|	ListOfCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	ListOfCategories.ExcisableGoodsCategory.UnitOfMeasure AS CategoryUnitOfMeasurement,
	|	ListOfCategories.ExcisableGoodsCategory.RateType AS RateType,
	|	ListOfCategories.ExcisableGoodsCategory.Currency AS Currency,
	|	ISNULL(RatesOfExcisableGoodsCategories.Rate1, 0) AS Rate1,
	|	ListOfCategories.ConversionFactor_ AS ConversionFactor_,
	|	CASE
	|		WHEN ListOfCategories.ConversionFactor_ > 0
	|			THEN ListOfCategories.ExcisableGoodsCategory.UnitOfMeasure.Description + ""/"" +
	|				ProductData_1.UnitOfMeasure.Description
	|		WHEN ISNULL(ListOfCategories.ExcisableGoodsCategory,
	|			VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) = VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|			THEN """"
	|	END AS UnitOfItemInCategory
	|FROM
	|	ListOfCategories AS ListOfCategories
	|		LEFT JOIN RatesOfExcisableGoodsCategories AS RatesOfExcisableGoodsCategories
	|		ON ListOfCategories.ExcisableGoodsCategory = RatesOfExcisableGoodsCategories.ExcisableGoodsCategory
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON (ProductData_1.Ref = &Products)";
	
	Query.SetParameter("Products", Products);
	Query.SetParameter("Period", Period);
	Query.SetParameter("FilterByPeriod", ValueIsFilled(Period));
	Query.SetParameter("Country", Country);
	Query.SetParameter("CountryIsFull", ValueIsFilled(Country));

	Return Query.Execute().Unload();

EndFunction

// Copies excise categories for the item.
//
// Parameters:
//	Products - CatalogRef.Products - The item for which it is necessary to copy the categories of excisable items;
//	ItemSource - CatalogRef.Products - Source for excise categories;
//	CopyCoefficient - Boolean - indicates that it is necessary to copy the conversion ratio for excise categories.
//
Procedure CopyExciseCategories(Products, ItemSource, CopyCoefficient) Export
	
	Period = CurrentSessionDate();
	DataOnExciseCategories = GetHistoryOfItemCategories(ItemSource,, Period);
	
	For Each InitialString In DataOnExciseCategories Do
		
		NewEntryOfExciseCategory = InformationRegisters.ExcisableGoodsCategories.CreateRecordManager();
		NewEntryOfExciseCategory.Products = Products;
		NewEntryOfExciseCategory.Period = InitialString.Period;
		NewEntryOfExciseCategory.Country = InitialString.Country;
		If CopyCoefficient Then
			NewEntryOfExciseCategory.ConversionFactor_ = InitialString.ConversionFactor_;
		EndIf;
		NewEntryOfExciseCategory.ExcisableGoodsCategory = InitialString.ExcisableGoodsCategory;
		NewEntryOfExciseCategory.ExcisableGoods = InitialString.ExcisableGoods;
		NewEntryOfExciseCategory.Write();
		
	EndDo;
	
EndProcedure

// Checks the beginning of the period when copying data by excise categories.
//
// Parameters:
//	ItemSource - CatalogRef.Products - Source for excise categories;
//	Cancel - Boolean - it is set to true if there is an unfilled period.
//
Procedure CheckCopyDataOfExciseCategories(ItemSource, Cancel) Export
	
	Period = CurrentSessionDate();
	DataOnExciseCategories = GetHistoryOfItemCategories(ItemSource,, Period);
	
	DateEmpty = Date(1,1,1);
	
	For Each InitialString In DataOnExciseCategories Do
		
		If InitialString.Period = DateEmpty Then
			MessageText = NStr("ru = 'Не удалось скопировать данные по акцизам. В исходных данных неверно указано начало периода.
			|Необходимо исправить исходные данные по акцизам, а затем повторить операцию копирования. Либо ввести новые данные вручную, не копируя их.';
			|vi = 'Cannot copy the excise data. The initial data has an incorrect period start specified.
			|Correct the initial excise data and try again or enter new data manually without copying it.';
			|en = 'Cannot copy the excise data. The initial data has an incorrect period start specified.
			|Correct the initial excise data and try again or enter new data manually without copying it.'; fa = 'Cannot copy the excise data. The initial data has an incorrect period start specified.
			|Correct the initial excise data and try again or enter new data manually without copying it.';
			|it = 'Cannot copy the excise data. The initial data has an incorrect period start specified.
			|Correct the initial excise data and try again or enter new data manually without copying it.';
			|pl = 'Cannot copy the excise data. The initial data has an incorrect period start specified.
			|Correct the initial excise data and try again or enter new data manually without copying it.';
			|tr = 'Tüketim vergileri kapsamında verilerin kopyalanması mümkün değildir. Kaynak verilerde yanlış bir dönem başlangıç ​​tarihi bulunmaktadır.
			|Kaynak tüketim vergisi verilerini düzeltip kopyalama işlemini tekrarlamanız gerekmektedir. Alternatif olarak, kopyalamadan yeni verileri manuel olarak girin.'");
			Common.MessageToUser(MessageText);
			Cancel = True;
			Break;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ProcessingOfTabularPart

// Adds a query to a batch of queries to get a feature for batch processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextAndFillInExcisableItemAttribute(
	StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInExcisableItemAttribute",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
		
		QueryText = QueryTextTTExcisableItems("TTDataSource");
		If QueryDetails.QueriesTexts.FindByValue(QueryText) = Undefined Then
			QueryDetails.QueriesTexts.Add(QueryText, "TTExcisableItems");
		EndIf;
		
		QueryText =
		"SELECT
		|	Goods.IdOfTTRow AS IdOfTTRow,
		|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods
		|FROM
		|	TTDataSource AS Goods
		|		LEFT JOIN TTExcisableItems AS TTExcisableItems
		|		ON Goods.Products = TTExcisableItems.Products";
		
		Date = StructureOfActionParameters.Date;
		Organization = StructureOfActionParameters.Organization;
		QueryDetails.QueryOptions.Insert("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
		QueryDetails.QueryOptions.Insert("Country",
			SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
		
		QueryDetails.QueriesTexts.Add(QueryText, "FillInExcisableItemAttribute");
		
	EndIf;
	
EndProcedure

// Adds a request to a batch of requests to get parameters for recalculating the excise tax amount during batch processing
// of rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextAndRecalculateExciseTaxAmount(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"RecalculateExciseTaxAmount",
			StructureOfActions,
			CachedValues,
			StructureOfActionParameters) Then
		
		QueryText =
		"SELECT
		|	CategoryTable.Products AS Products,
		|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
		|	CategoryTable.ConversionFactor_ AS ConversionFactor_
		|INTO TTCategoriesOfExcisableItems
		|FROM
		|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Date, (Products, Country) IN
		|		(SELECT
		|			T.Products AS Products,
		|			&Country AS Country
		|		FROM
		|			TTDataSource AS T)) AS CategoryTable
		|WHERE
		|	CategoryTable.ExcisableGoods
		|
		|INDEX BY
		|	ExcisableGoodsCategory
		|";
		
		QueryDetails.QueriesTexts.Add(QueryText, "TTCategoriesOfExcisableItems");
		
		QueryText =
		"SELECT
		|	RatesTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
		|	RatesTable.Rate1 AS Rate1
		|INTO TTRatesOfExcisableItemCategories
		|FROM
		|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&Date, ExcisableGoodsCategory IN
		|		(SELECT
		|			T.ExcisableGoodsCategory AS ExcisableGoodsCategory
		|		FROM
		|			TTCategoriesOfExcisableItems AS T)) AS RatesTable
		|
		|INDEX BY
		|	ExcisableGoodsCategory
		|";
		
		QueryDetails.QueriesTexts.Add(QueryText, "TTRatesOfExcisableItemCategories");
		
		QueryText =
		"SELECT
		|	CategoryTable.Products AS Products,
		|	ISNULL(RatesTable.Rate1, 0) AS Rate1,
		|	CategoryTable.ConversionFactor_ AS ConversionFactor_,
		|	ExcisableGoodsCategories.Ref AS Category,
		|	ISNULL(ExcisableGoodsCategories.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
		|	ISNULL(ExcisableGoodsCategories.RateType,
		|		VALUE(Enum.TypesOfExcisableCategoryRates.EmptyRef)) AS RateType,
		|	RatesTable.Rate1 IS NULL AS BidNotSet,
		|	ExcisableGoodsCategories.Ref IS NULL AS CategoryNotSpecified
		|INTO TTExciseCalculationParameters
		|FROM
		|	TTCategoriesOfExcisableItems AS CategoryTable
		|		LEFT JOIN TTRatesOfExcisableItemCategories AS RatesTable
		|		ON CategoryTable.ExcisableGoodsCategory = RatesTable.ExcisableGoodsCategory
		|		LEFT JOIN Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
		|		ON CategoryTable.ExcisableGoodsCategory = ExcisableGoodsCategories.Ref
		|
		|INDEX BY
		|	Products,
		|	Currency
		|";
		
		QueryDetails.QueriesTexts.Add(QueryText, "TTExciseCalculationParameters");
		
		QueryText =
		"SELECT
		|	CurrencyExchangeRate.Currency AS Currency,
		|	CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS ConversionFactor_
		|INTO TTExciseExchangeRates
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, (Currency, BaseCurrency) IN
		|			(SELECT
		|				T.Currency AS Currency,
		|				&BaseCurrency AS BaseCurrency
		|			FROM
		|				TTExciseCalculationParameters AS T)) AS CurrencyExchangeRate
		|WHERE
		|	CurrencyExchangeRate.CourseDenominator <> 0
		|
		|INDEX BY
		|	Currency
		|";
		
		QueryDetails.QueriesTexts.Add(QueryText, "TTExciseExchangeRates");
		
		QueryText =
		"SELECT
		|	Goods.IdOfTTRow AS IdOfTTRow,
		|	DataTable.Products IS NOT NULL AS ExcisableGoods,
		|	DataTable.Rate1 * ISNULL(ExchangeRates.ConversionFactor_, 1) AS Rate1,
		|	DataTable.ConversionFactor_ AS ConversionRatioOfUnits,
		|	PRESENTATION(DataTable.Products) AS Products,
		|	PRESENTATION(DataTable.Category) AS Category,
		|	PRESENTATION(DataTable.Currency) AS Currency,
		|	DataTable.BidNotSet AS BidNotSet,
		|	DataTable.CategoryNotSpecified AS CategoryNotSpecified,
		|	DataTable.ConversionFactor_ = 0
		|		AND DataTable.RateType = &FirmBet AS ConversionRatioIsNotSet,
		|	DataTable.Currency <> VALUE(Catalog.Currencies.EmptyRef)
		|		AND DataTable.Currency <> &BaseCurrency
		|		AND ExchangeRates.ConversionFactor_ IS NULL AS ConversionRateToLocalCurrencyIsNotSet
		|FROM
		|	TTDataSource AS Goods
		|		LEFT JOIN TTExciseCalculationParameters AS DataTable
		|		ON Goods.Products = DataTable.Products
		|		LEFT JOIN TTExciseExchangeRates AS ExchangeRates
		|		ON DataTable.Currency = ExchangeRates.Currency";
		
		QueryDetails.QueriesTexts.Add(QueryText, "RecalculateExciseTaxAmount");
		
		Date = StructureOfActionParameters.Date;
		QueryDetails.QueryOptions.Insert("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
		QueryDetails.QueryOptions.Insert("Country",
			SettingsValueClientServerCached.CountryOfOrganizationRegistration(StructureOfActionParameters.Organization));
		QueryDetails.QueryOptions.Insert("BaseCurrency",
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(StructureOfActionParameters.Organization));
		QueryDetails.QueryOptions.Insert("FirmBet", Enums.TypesOfExcisableCategoryRates.FixedRate);
		
	EndIf;
	
EndProcedure

// Fills in the service Attribute "Excisable goods" in the currently processed row of the table part in the mechanisms
// of batch processing of rows of table parts.
//
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSStrings
//  StructureOfActions - See  BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInExcisableItemInBatch(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("FillInExcisableItemAttribute") Then
		Return;
	EndIf;
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(
		"FillInExcisableItemAttribute", CachedValues);
	
	If DataForProcessing <> Undefined Then
		CurrentRow.ExcisableGoods = DataForProcessing[0].ExcisableGoods;
	Else
		CurrentRow.ExcisableGoods = False;
	EndIf;
	
EndProcedure

// Recalculates the excise tax amount for the current processed row of the tabular part in the mechanisms of batch processing
// of rows of tabular parts.
//
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSStrings
//  StructureOfActions - See  BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure RecalculateExciseTaxAmountInBatches(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	If Not StructureOfActions.Property("RecalculateExciseTaxAmount", StructureOfActionParameters) Then
		Return;
	EndIf;
	
	CurrentRow.ExciseTaxAmount = 0;
	
	If TMCommonUseClientServer.HasObjectAttribute(CurrentRow, "ExcisableGoods")
		And Not CurrentRow.ExcisableGoods
		Or Not ValueIsFilled(StructureOfActionParameters) Then
		Return;
	EndIf;
	
	DataForProcessing =
		BatchProcessingOfTablePartServer.DataForStringProcessing("RecalculateExciseTaxAmount", CachedValues); 
	
	If DataForProcessing <> Undefined Then
		
		CalculationParameters = DataForProcessing[0];
		
		If Not CalculationParameters.ExcisableGoods Then
			Return;
		EndIf;
		
		FieldNameQuantity = StructureOfActionParameters.FieldNameQuantity;
		Count = CurrentRow[FieldNameQuantity];
		
		If StructureOfActionParameters.RatePerUnitOfStorage Then
			Count = Round(Count * CalculationParameters.ConversionRatioOfUnits, 3);
		EndIf;
		
		CurrentRow.ExciseTaxAmount = Count * CalculationParameters.Rate1;
		
		ReportExciseTaxCalculationErrors(CalculationParameters, StructureOfActionParameters.Date);
		
	EndIf;
	
EndProcedure

// Calculates the excise tax amount in the Inventory Types table.
//
// Parameters:
//  DocumentObject - DocumentObject - The document in which the excise tax amount is calculated.
//  FillParameters - See InventoriesServer.ParametersForFillingInventoryTypes.
//  NameOfColumnInventoryOwnerAttribute - String - The name of the column that contains the Inventory owner attributes.
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure CalculateAmountOfExciseTax(DocumentObject, FillParameters, NameOfColumnInventoryOwnerAttribute = "", Cancel = False) Export
	
	If Cancel
		Or Not ValueIsFilled(FillParameters)
		Or Not FillParameters.CalculateAmountOfExciseTax Then
		
		Return;
		
	EndIf;
	
	If FillParameters.TableTypesOfStocks_ <> Undefined Then
		TableTypesOfStocks_ = FillParameters.TableTypesOfStocks_;
	Else
		TableTypesOfStocks_ = DocumentObject[FillParameters.NameTSTypesOfStocks];
	EndIf;
	
	If ValueIsFilled(FillParameters.ExciseAccrualPeriod) Then
		Period = FillParameters.ExciseAccrualPeriod;
	Else
		Period = DocumentObject.Date;
	EndIf;
	
	Organization = DocumentObject[FillParameters.CompanyFieldName1];
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	Query = New Query;
	
	Query.SetParameter("TableTypesOfStocks_", TableTypesOfStocks_);
	Query.SetParameter("Period", Period);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	Query.SetParameter("FirmBet", Enums.TypesOfExcisableCategoryRates.FixedRate);
	
	QueryText =
	"SELECT
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&QueryTextInventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS InventoryKinds
	|WHERE
	|	InventoryKinds.ExciseTaxAmount = 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	Dimension.Products AS Products
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	InventoryKinds.Organization = &Organization
	|	AND InventoryKinds.SubjectToExcise
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO CategoryTable
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
	|		(SELECT
	|			T.Products AS Products,
	|			&RegistrationCountry AS Country
	|		FROM
	|			TableTypesOfStocks_ AS T)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products,
	|	ExcisableGoodsCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RatesTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	RatesTable.Rate1 AS Rate1
	|INTO RatesTable
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&Period, ExcisableGoodsCategory IN
	|		(SELECT
	|			T.ExcisableGoodsCategory AS ExcisableGoodsCategory
	|		FROM
	|			CategoryTable AS T)) AS RatesTable
	|
	|INDEX BY
	|	ExcisableGoodsCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.Products AS Products,
	|	ExcisableGoodsCategories.Ref AS Category,
	|	ISNULL(RatesTable.Rate1, 0) AS Rate1,
	|	ISNULL(ExcisableGoodsCategories.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(ExcisableGoodsCategories.RateType,
	|		VALUE(Enum.TypesOfExcisableCategoryRates.EmptyRef)) AS RateType,
	|	RatesTable.Rate1 IS NULL AS BidNotSet,
	|	ExcisableGoodsCategories.Ref IS NULL AS CategoryNotSpecified,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO DataTable
	|FROM
	|	CategoryTable AS CategoryTable
	|		INNER JOIN TableTypesOfStocks_ AS TableTypesOfStocks_
	|		ON CategoryTable.Products = TableTypesOfStocks_.Products
	|		LEFT JOIN RatesTable AS RatesTable
	|		ON CategoryTable.ExcisableGoodsCategory = RatesTable.ExcisableGoodsCategory
	|		LEFT JOIN Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
	|		ON CategoryTable.ExcisableGoodsCategory = ExcisableGoodsCategories.Ref
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator / CurrencyExchangeRate.CourseDenominator AS ConversionFactor_
	|INTO ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, (Currency, BaseCurrency) IN
	|			(SELECT
	|				T.Currency AS Currency,
	|				&BaseCurrency AS BaseCurrency
	|			FROM
	|				DataTable AS T)) AS CurrencyExchangeRate
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	PRESENTATION(DataTable.Products) AS Products,
	|	PRESENTATION(DataTable.Category) AS Category,
	|	PRESENTATION(DataTable.Currency) AS Currency,
	|	DataTable.Rate1 * ISNULL(ExchangeRates.ConversionFactor_, 1) AS Rate1,
	|	DataTable.ConversionFactor_ AS ConversionRatioOfUnits,
	|	DataTable.BidNotSet
	|		AND DataTable.RateType = &FirmBet AS BidNotSet,
	|	DataTable.CategoryNotSpecified AS CategoryNotSpecified,
	|	DataTable.ConversionFactor_ = 0
	|		AND DataTable.RateType = &FirmBet AS ConversionRatioIsNotSet,
	|	DataTable.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|		AND DataTable.Currency <> &BaseCurrency
	|		AND ExchangeRates.ConversionFactor_ IS NULL AS ConversionRateToLocalCurrencyIsNotSet
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON DataTable.Currency = ExchangeRates.Currency";
	
	If IsBlankString(NameOfColumnInventoryOwnerAttribute) Then
		NameOfColumnInventoryOwnerAttribute = "InventoryOwnerAttribute";
	EndIf;
	QueryTextInventoryOwnerAttribute = StrTemplate("InventoryKinds.%1", NameOfColumnInventoryOwnerAttribute);
	QueryText = StrReplace(QueryText, "&QueryTextInventoryOwnerAttribute", QueryTextInventoryOwnerAttribute);
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ReportExciseTaxCalculationErrors(Selection, DocumentObject.Date, Cancel);
		
		If Cancel Then
			Continue;
		EndIf;
		
		InventoryOwnerAttributeLine = TableTypesOfStocks_[Selection.LineNumber - 1];
		InventoryOwnerAttributeLine.ExciseTaxAmount = Round(InventoryOwnerAttributeLine.Count * Selection.ConversionRatioOfUnits, 3)
			* Selection.Rate1;
		
	EndDo;
	
EndProcedure
#EndRegion

#Region CheckingFillingOfExcisableItems

// Generates a standard parameter structure for controlling the filling of excisable items.
//
// Returns:
//  Structure - Parameters:
//  	* ErrorTextTemplate - String - Template for the error text displayed to the user
//  	* TabularSectionName - String - Name of the tabular part containing the data to be monitored
//  	* TabularSectionPresentation - String - Presentation of the tabular part for displaying errors in the text
//  	* NameOfFieldWithError - String - Name of the field to link the error message to
//  	* CompanyFieldName1 - String -
//  	* WarehouseFieldName - String - Name of the field containing the warehouse to control
//  	* CheckingWarehouse - Boolean -
//  	* WarehouseInTablePart - Boolean -
//  	* CheckAmountOfExciseTax - Boolean -
//  	* StringsList - Undefined, Array of LineOfATabularSection - the list of rows in the table part to be checked.
//
Function ControlParametersForFillingExcisableItems() Export
	
	ControlParameters = New Structure;
	ControlParameters.Insert("ErrorTextTemplate", "");
	ControlParameters.Insert("TabularSectionName", "Goods");
	ControlParameters.Insert("TabularSectionPresentation", NStr("vi = 'Hàng hóa';
																|ru = 'Товары';
																|en = 'Goods'; fa = 'کالاها';
																|it = 'Goods';
																|pl = 'Goods';
																|tr = 'Ürünler'"));
	ControlParameters.Insert("NameOfFieldWithError", "Products");
	ControlParameters.Insert("CompanyFieldName1", "Organization");
	ControlParameters.Insert("WarehouseFieldName", "Warehouse");
	ControlParameters.Insert("CheckingWarehouse", False);
	ControlParameters.Insert("WarehouseInTablePart", False);
	ControlParameters.Insert("CheckAmountOfExciseTax", False);
	ControlParameters.Insert("StringsList", Undefined);
	
	Return ControlParameters;
	
EndFunction

// Checks the correctness of filling in excisable items in the document.
//
// Parameters:
//  DocumentObject - DocumentObject - The object to check for completion.
//  ControlParameters - See ControlParametersForFillingExcisableItems.
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure ControlOfFillingExcisableItems(DocumentObject, ControlParameters, Cancel) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return;
	EndIf;
	
	Organization = DocumentObject[ControlParameters.CompanyFieldName1];
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	
	Warehouse = Catalogs.Warehouses.EmptyRef();
	TextTableItemsWarehouse = "&Warehouse";
	
	If ControlParameters.CheckingWarehouse Then
		If ControlParameters.WarehouseInTablePart Then
			TextTableItemsWarehouse = "GoodsTable." + ControlParameters.WarehouseFieldName;
		Else
			Warehouse = DocumentObject[ControlParameters.WarehouseFieldName];
		EndIf;
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("Period", DocumentObject.Date);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("GoodsTable", DocumentObject[ControlParameters.TabularSectionName]);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("FirmBet", Enums.TypesOfExcisableCategoryRates.FixedRate);
	Query.SetParameter("ConditionForSelectingEntriesIsItemsTable", True);
	Query.SetParameter("EntrySelectionCriteriaCategoryTable", True);
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	&GoodsTableWarehouse AS Warehouse
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	&ConditionForSelectingEntriesIsItemsTable
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CategoryTable.Products AS Products
	|INTO CategoryTable
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
	|		(SELECT
	|			T.Products,
	|			&Country
	|		FROM
	|			TemporaryTableOfGoods_ AS T)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|	AND &EntrySelectionCriteriaCategoryTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	PRESENTATION(TemporaryTableOfGoods_.Products) AS Products,
	|	PRESENTATION(TemporaryTableOfGoods_.Warehouse) AS Warehouse
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		INNER JOIN CategoryTable AS CategoryTable
	|		ON TemporaryTableOfGoods_.Products = CategoryTable.Products";
	QueryText = QueryText + ?(ControlParameters.CheckingWarehouse, "
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON TemporaryTableOfGoods_.Warehouse = Warehouses.Ref
	|		AND Warehouses.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)", "");
	
	QueryText = StrReplace(QueryText, "&GoodsTableWarehouse", TextTableItemsWarehouse);
	If ControlParameters.CheckAmountOfExciseTax Then
		TextSelectionConditionExciseTaxAmount = "GoodsTable.ExciseTaxAmount = 0";
		QueryText = StrReplace(QueryText, "&ConditionForSelectingEntriesIsItemsTable", TextSelectionConditionExciseTaxAmount);
		TextSelectionCriteriaBidType = "CategoryTable.ExcisableGoodsCategory.RateType = &FirmBet";
		QueryText = StrReplace(QueryText, "&EntrySelectionCriteriaCategoryTable", TextSelectionCriteriaBidType);
	EndIf;
	
	Query.Text = QueryText;
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ErrorText = ControlParameters.ErrorTextTemplate;
		ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
		ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
		ErrorText = StrReplace(ErrorText, "%Organization%", Organization);
		ErrorText = StrReplace(ErrorText, "%Warehouse%", Selection.Warehouse);
		ErrorText = StrReplace(
			ErrorText, "%TabularSectionPresentation%", ControlParameters.TabularSectionPresentation);
		
		DataPath = CommonClientServer.PathToTabularSection(
			ControlParameters.TabularSectionName, Selection.LineNumber, ControlParameters.NameOfFieldWithError);
		
		Common.MessageToUser(ErrorText, DocumentObject, DataPath, , Cancel);
		
	EndDo;
	
EndProcedure

// Checks the compliance of the category of the received and debited excisable item in the document.
//
// Parameters:
//  DocumentObject - DocumentObject.GoodsMisgrading,
//  				 Document object.Damaged goods,
//  				 Document object.The return of the client's goods is the object that needs to be checked for filling.
//  ControlParameters - See ControlParametersForFillingExcisableItems.
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure ControlOfComplianceWithCategoryOfExcisableItems(DocumentObject, ControlParameters, Cancel) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return;
	EndIf;
	
	Organization = DocumentObject[ControlParameters.CompanyFieldName1];
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UnloadedColumns = "LineNumber, Products, ProductsRecordingAsReceived";
	GoodsTable = DocumentObject[ControlParameters.TabularSectionName].Unload(ControlParameters.StringsList, UnloadedColumns);
	
	Query = New Query;
	
	Query.SetParameter("Period", DocumentObject.Date);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("GoodsTable", GoodsTable);
	Query.SetParameter("EmptyCategory", Catalogs.ExcisableGoodsCategories.EmptyRef());
	
	Query.Text =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.ProductsRecordingAsReceived AS ProductsRecordingAsReceived
	|INTO TemporaryTableOfGoods_
	|FROM
	|	&GoodsTable AS GoodsTable
	|
	|INDEX BY
	|	Products,
	|	ProductsRecordingAsReceived
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory
	|INTO CategoryTable
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
	|		(SELECT
	|			T.Products AS Products,
	|			&Country AS Country
	|		FROM
	|			TemporaryTableOfGoods_ AS T
	|
	|		UNION ALL
	|
	|		SELECT
	|			T.ProductsRecordingAsReceived AS Products,
	|			&Country AS Country
	|		FROM
	|			TemporaryTableOfGoods_ AS T)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	PRESENTATION(TemporaryTableOfGoods_.Products) AS Products,
	|	PRESENTATION(TemporaryTableOfGoods_.ProductsRecordingAsReceived) AS ProductsRecordingAsReceived
	|FROM
	|	TemporaryTableOfGoods_ AS TemporaryTableOfGoods_
	|		LEFT JOIN CategoryTable AS Categories
	|		ON TemporaryTableOfGoods_.Products = Categories.Products
	|		LEFT JOIN CategoryTable AS CategoriesLoggingIn
	|		ON TemporaryTableOfGoods_.ProductsRecordingAsReceived = CategoriesLoggingIn.Products
	|WHERE
	|	ISNULL(Categories.ExcisableGoodsCategory,
	|		&EmptyCategory) <> ISNULL(CategoriesLoggingIn.ExcisableGoodsCategory, &EmptyCategory)";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ErrorText = ControlParameters.ErrorTextTemplate;
		ErrorText = StrReplace(ErrorText, "%Products%", Selection.Products);
		ErrorText = StrReplace(ErrorText, "%ProductsRecordingAsReceived%", Selection.ProductsRecordingAsReceived);
		ErrorText = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber);
		ErrorText = StrReplace(
			ErrorText, "%TabularSectionPresentation%", ControlParameters.TabularSectionPresentation);
		
		DataPath = CommonClientServer.PathToTabularSection(
			ControlParameters.TabularSectionName, Selection.LineNumber, ControlParameters.NameOfFieldWithError);
		
		Common.MessageToUser(ErrorText, DocumentObject, DataPath, , Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CalculationOfNumberOfExcisableItems

// Generates a standard parameter structure for calculating the number of excisable items in the document.
//
// Returns:
//  Structure - Parameters:
//   * TabularSectionName - String - The name of the tabular part containing data on the item.
//   * CompanyFieldName1 - String - The name of the field containing the company for which you want to get a sign for keeping
//  						records of excisable items.
//   * FilterParameters - Structure, Undefined - The structure key is the column ID, and
//  						the structure value is the selection value. If a selection is specified, rows with
//  						values that match the selection value will be unloaded from the table part.
//
Function ParametersForCalculatingNumberOfExcisableItems() Export
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("TabularSectionName", "Goods");
	CalculationParameters.Insert("CompanyFieldName1", "Organization");
	CalculationParameters.Insert("FilterParameters", Undefined);
	
	Return CalculationParameters;
	
EndFunction

// Starts a background task for calculating the number of excisable items in the document.
//
// Parameters:
//  DocumentObject - FormDataStructure, DocumentObject - The document to perform the calculation for
//  CalculationParameters - Structure, Undefined - See ExcisableGoodsAccounting.ParametersForCalculatingNumberOfExcisableItems
//
// Returns:
//  See TimeConsumingOperations.ExecuteInBackground
//
Function StartCalculatingNumberOfExcisableItems(DocumentObject, CalculationParameters = Undefined) Export
	
	BackgroundJobResult = New Structure;
	
	If CalculationParameters = Undefined Then
		CalculationParameters = ParametersForCalculatingNumberOfExcisableItems();
	EndIf;
	
	TabularSection = DocumentObject[CalculationParameters.TabularSectionName];
	FilterParameters = CalculationParameters.FilterParameters;
	ColumnName = "Products";
	Products = TabularSection.Unload(FilterParameters, ColumnName).UnloadColumn(ColumnName);
	Organization = DocumentObject[CalculationParameters.CompanyFieldName1];
	Country = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	Period = DocumentObject.Date;
	
	CalculationProcedure_ = "ExcisableGoodsAccounting.CalculateNumberOfExcisableItemsInBackground";
		
	JobParameters = New Array;
	JobParameters.Add(Products);
	JobParameters.Add(Country);
	JobParameters.Add(Period);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	BackgroundJobResult =
		TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_, JobParameters, ExecutionParameters);
	
	Return BackgroundJobResult;
	
EndFunction

// Determines the number of excisable items from the item array for the specified country and places
// the value in temporary storage.
//
// Parameters:
//  JobParameters - Array of CatalogRef.Products - contains the call parameters
//  StorageAddress - String - the address of the temporary storage where the execution result will be placed.
//
Procedure CalculateNumberOfExcisableItemsInBackground(JobParameters, StorageAddress) Export
	
	Products = JobParameters[0];
	Country = JobParameters[1];
	Period = JobParameters[2];
	
	NumberOfExcisableItems =
		InformationRegisters.ExcisableGoodsCategories.NumberOfExcisableItems(Products, Country, Period);
	
	PutToTempStorage(NumberOfExcisableItems, StorageAddress);
	
EndProcedure

#EndRegion

#Region UserInterface

// Updates the heading of the Form is subject to excise duty after calculating the number of excisable items in the document.
//
// Parameters:
//  Form - ClientApplicationForm - Customizable Form.
//  ToUpdateData - Boolean - If True, if necessary, the Attributes of the object are cleared with an excise tax
//  	and the division of production.
//  Period - Date - the period when the excise tax accounting settings were received.
//
Procedure UpdateElementsOfAccountingForExcisableItems(Form, ToUpdateData = True, Period = Undefined) Export
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.SubjectToExcise.Visible = Form.UseExcisableGoods;
	Items.BusinessUnitProduction.Visible = Form.UseExcisableGoods;
	Form.ItIsRequiredToUpdateTitleIsSubjectToExciseDuty = Form.UseExcisableGoods;
	
	If TypeOf(Object.Ref) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		CompanyFieldName1 = "CompanyRecipient";
	Else
		CompanyFieldName1 = "Organization";
	EndIf;
	
	If Period = Undefined Then
		Period = Object.Date;
	EndIf;
	
	ProductionOfExcisableItemsIsUsed = Form.UseExcisableGoods
		And ProductionOfExcisableItemsIsUsed(Object[CompanyFieldName1], Period);
	
	If ToUpdateData And Not ProductionOfExcisableItemsIsUsed Then
		Object.SubjectToExcise = False;
		Object.BusinessUnitProduction = Undefined;
	EndIf;
	
	Items.SubjectToExcise.ReadOnly = Not ProductionOfExcisableItemsIsUsed;
	Items.BusinessUnitProduction.Enabled = Object.SubjectToExcise;
	Items.BusinessUnitProduction.AutoMarkIncomplete = ?(Object.SubjectToExcise, Undefined, False);
EndProcedure

#EndRegion

#Region SelectionOfInventoryOwnerAttributes

// Returns parameters for generating the Query Text of the temporary table 'In the Excisable category of goods'.
//
// Returns:
//	Structure - contains the following properties:
//		* SelectingCategoriesByDate - Boolean - indicates the method for getting data from the register. TRUE - by default means
//											that the data will be obtained from the virtual table of the slice of the latest.
//		* ProductTableName_ - String - the name of the temp table of items selected in the register.
//										The default is 'Table of Goods'.
//		* CountryWH - Boolean - indicates the source of information about the country. FALSE - by default means that
//								the selection by country is set in the request parameters.
//		* FieldNamePeriod - String - the name of the period field in the item temp table. This field is used to select
//									information from the register.
//
Function ParametersOfQueryTextTTExciseCategoriesOfItems() Export
	
	RequestTextParameters = New Structure;
	RequestTextParameters.Insert("SelectingCategoriesByDate",	True);
	RequestTextParameters.Insert("ProductTableName_",	"TableOfGoods");
	RequestTextParameters.Insert("CountryWH",			False);
	RequestTextParameters.Insert("FieldNamePeriod",		"Period");
	
	Return RequestTextParameters;
	
EndFunction

// Returns the Query Text of the temporary table 'Excisable categories of goods' containing information about the categories
// of excisable items.
// The executed query must contain a temporary table of items for which it is necessary to get information about categories.
// The query parameters 'Use excisable goods', 'Date' - if
// date selection is set in the Query Text parameters, and 'Country' - if the item table does not contain a column of the same name - should also be set.
//
// Parameters:
//	TempTablesManager - TempTablesManager, Undefined - temporary table manager.
//	RequestTextParameters - See ParametersOfQueryTextTTExciseCategoriesOfItems.
//
// Returns:
//	String - Query Text of the temp table of excisable item categories.
//
Function QueryTextTTExciseCategoriesOfItems(TempTablesManager = Undefined,
													RequestTextParameters = Undefined) Export
	
	If TempTablesManager <> Undefined
		And TempTablesManager.Tables.Find("TTExciseCategoriesOfItems") <> Undefined Then
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "DROP TTExciseCategoriesOfItems";
		
		Query.Execute();
		
	EndIf;
	
	If RequestTextParameters = Undefined Then
		RequestTextParameters = ParametersOfQueryTextTTExciseCategoriesOfItems();
	EndIf;
	
	TextPeriod = ?(RequestTextParameters.SelectingCategoriesByDate,
					"TableOfGoods.Period",
					"TableOfGoods." + RequestTextParameters.FieldNamePeriod);
	TextCountry = ?(RequestTextParameters.CountryWH, "TableOfGoods.Country", "&Country");
	
	QueryText = ?(RequestTextParameters.SelectingCategoriesByDate,
					QueryTextTTExciseCategoriesOfItemsByDate(),
					QueryTextTTExciseCategoriesOfItemsByPeriod());
	QueryText = StrReplace(QueryText, "&PeriodField", TextPeriod);
	QueryText = StrReplace(QueryText, "&CountryOfTS", TextCountry);
	QueryText = StrReplace(QueryText, "&TableOfGoods", RequestTextParameters.ProductTableName_);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// Records the excise tax amounts in the register of "Excise movements".
//
// Parameters:
//	DocumentRef - DocumentRef - link to the document for which you need to record the amount of excise taxes.
//
Procedure RecordExciseTaxAmounts(DocumentRef) Export
	
	DocumentPosted = Common.ObjectAttributeValue(DocumentRef, "Posted");
	
	If DocumentPosted = Undefined Or DocumentPosted = False Then
		Return;
	EndIf;
	
	RecordSet = Undefined;
	DocumentType = TypeOf(DocumentRef);
	
	If DocumentType <> Type("DocumentRef.ReversingEntry") Then
		
		ManagerOfDocument = Common.ObjectManagerByRef(DocumentRef);
		Result = ManagerOfDocument.GetExciseTaxData(DocumentRef);
		
		RecordSet = AccumulationRegisters.RegisterRecordsByExcises.CreateRecordSet();
		RecordSet.AdditionalProperties.Insert("DeferredPosting");
		RecordSet.AdditionalProperties.Insert("ControlTables");
		RecordSet.AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		RecordSet.Filter.Recorder.Set(DocumentRef);
		
		If TypeOf(Result) = Type("QueryResult") Then
			Selection = Result.Select();
			While Selection.Next() Do
				FillPropertyValues(RecordSet.Add(), Selection);
			EndDo;
		ElsIf TypeOf(Result) = Type("ValueTable") Then
			For Each String In Result Do
				FillPropertyValues(RecordSet.Add(), String);
			EndDo;
		EndIf;
		
		DocumentReversingEntry = DocumentCorrection.ReverseDocument(DocumentRef);
		
		If DocumentReversingEntry <> Undefined Then
			AddTaskToNonOperationalQueue(DocumentReversingEntry);
		EndIf;
		
	EndIf;

	If DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
		Or DocumentType = Type("DocumentRef.InventoryConsumption")
		Or DocumentType = Type("DocumentRef.ApplicationForImportationOfGoods") Then
		
		DocumentAttributes = Common.ObjectAttributesValues(DocumentRef, "Patch, ReversedDocument, Date");
		
		If DocumentAttributes.Patch Then
			
			ManagerOfDocument = Common.ObjectManagerByRef(DocumentAttributes.ReversedDocument);
			Result = ManagerOfDocument.GetExciseTaxData(DocumentAttributes.ReversedDocument);
			
			RegisterResources = Metadata.AccumulationRegisters.RegisterRecordsByExcises.Resources;
			
			If TypeOf(Result) = Type("QueryResult") Then
				Selection = Result.Select();
				While Selection.Next() Do
					NewRow = RecordSet.Add();
					FillPropertyValues(NewRow, Selection);
					NewRow.Period = DocumentAttributes.Date;
					NewRow.ReversingEntry = True;
					For Each RegisterResource In RegisterResources Do
						NewRow[RegisterResource.Name] = -NewRow[RegisterResource.Name];
					EndDo;
				EndDo;
			ElsIf TypeOf(Result) = Type("ValueTable") Then
				For Each String In Result Do
					NewRow = RecordSet.Add();
					FillPropertyValues(RecordSet.Add(), String);
					NewRow.Period = DocumentAttributes.Date;
					NewRow.ReversingEntry = True;
					For Each RegisterResource In RegisterResources Do
						NewRow[RegisterResource.Name] = -NewRow[RegisterResource.Name];
					EndDo;
				EndDo;
			EndIf;

		EndIf;
		
	ElsIf DocumentType = Type("DocumentRef.ReversingEntry") Then
		
		DocumentAttributes = Common.ObjectAttributesValues(DocumentRef, "Date, ReversedDocument");
		
		ManagerOfDocument = Common.ObjectManagerByRef(DocumentAttributes.ReversedDocument);
		Result = ManagerOfDocument.GetExciseTaxData(DocumentAttributes.ReversedDocument);
		
		RecordSet = AccumulationRegisters.RegisterRecordsByExcises.CreateRecordSet();
		RecordSet.AdditionalProperties.Insert("DeferredPosting");
		RecordSet.AdditionalProperties.Insert("ControlTables");
		RecordSet.AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		RecordSet.Filter.Recorder.Set(DocumentRef);
		
		RegisterResources = Metadata.AccumulationRegisters.RegisterRecordsByExcises.Resources;
		Selection = Result.Select();
		While Selection.Next() Do
			NewRow = RecordSet.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.Period = DocumentAttributes.Date;
			NewRow.ReversingEntry = True;
			For Each RegisterResource In RegisterResources Do
				NewRow[RegisterResource.Name] = -NewRow[RegisterResource.Name];
			EndDo;
		EndDo;
			
	EndIf;
	
	If RecordSet <> Undefined Then
		RecordSet.Write();
	EndIf;
	
EndProcedure

// Creates a task for non-operational recording of the register of "Excise movements" according to the document.
//
// Parameters:
//	Document - DocumentObject - the document for which it is necessary to record the amount of excise taxes.
//
Procedure CreateTaskToRecordAmountOfExciseTax(Document) Export
	
	If ThisDocumentMakesRegisteredRecordsForImportedItems(Document)
		Or (ThisDocumentMakesRegisteredRecordsOfExcisableItemsProduced(Document)
			And Document.AdditionalProperties.Property("WriteDownAmountOfExciseTax")
			And Document.AdditionalProperties.WriteDownAmountOfExciseTax)
		Or ThisIsStornoDocument(Document) Then
	
		AddTaskToNonOperationalQueue(Document);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region ApplicationForImportationOfGoods

// Prepares the Query Text with data on excisable items for the document "Application for import of items from the EAEU".
//
// Parameters:
//  UseExcisableGoods - Boolean - Indicates whether the Company is using the import/production of excisable items
//  NameOfTableToSelect - String - The name of the temp table for selection containing the "Item" field
//
// Returns:
//  String - query text.
//
Function QueryTextDataOfExcisableItems(UseExcisableGoods, NameOfTableToSelect) Export
	
	If UseExcisableGoods Then
		
		QueryText =
		"SELECT
		|	CategoryTable.Products AS Products,
		|	CategoryTable.ExcisableGoods AS ExcisableGoods,
		|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
		|	CategoryTable.ConversionFactor_ AS ConversionFactor_
		|INTO CategoryTable
		|FROM
		|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
		|		(SELECT
		|			T.Products,
		|			&RegistrationCountry
		|		FROM &TableName AS T)) AS CategoryTable
		|WHERE
		|	CategoryTable.ExcisableGoods
		|
		|INDEX BY
		|	ExcisableGoodsCategory
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfBidsByCategory.ExcisableGoodsCategory AS ExcisableGoodsCategory,
		|	TableOfBidsByCategory.Rate1 AS Rate1
		|INTO TableOfBidsByCategory
		|FROM
		|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&Period,
		|		ExcisableGoodsCategory IN
		|		(SELECT
		|			T.ExcisableGoodsCategory AS ExcisableGoodsCategory
		|		FROM
		|			CategoryTable AS T)) AS TableOfBidsByCategory
		|
		|INDEX BY
		|	ExcisableGoodsCategory
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CategoryTable.Products AS Products,
		|	CategoryTable.ExcisableGoods AS ExcisableGoods,
		|	TableOfBidsByCategory.Rate1 AS Rate1,
		|	ExcisableGoodsCategories.Code AS ExciseCode,
		|	ExcisableGoodsCategories.UnitOfMeasure AS UnitOfMeasure,
		|	CategoryTable.ConversionFactor_ AS ConversionFactor_,
		|	ExcisableGoodsCategories.Currency AS Currency,
		|	ExcisableGoodsCategories.RateType AS RateType
		|INTO DataOfExcisableItems
		|FROM
		|	CategoryTable AS CategoryTable
		|		INNER JOIN TableOfBidsByCategory AS TableOfBidsByCategory
		|		ON CategoryTable.ExcisableGoodsCategory = TableOfBidsByCategory.ExcisableGoodsCategory
		|		INNER JOIN Catalog.ExcisableGoodsCategories AS ExcisableGoodsCategories
		|		ON CategoryTable.ExcisableGoodsCategory = ExcisableGoodsCategories.Ref
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrencyExchangeRate.Currency AS Currency,
		|	CurrencyExchangeRate.CourseNumerator * CurrencyExchangeRate.CourseDenominator AS ConversionFactor_
		|INTO ExchangeRates
		|FROM
		|	InformationRegister.RelativeExchangeRates.SliceLast(
		|			&Period, (Currency, BaseCurrency) IN
		|			(SELECT
		|				T.Currency AS Currency,
		|				&BaseCurrency AS BaseCurrency
		|			FROM
		|				DataOfExcisableItems AS T)) AS CurrencyExchangeRate
		|WHERE
		|	CurrencyExchangeRate.CourseDenominator <> 0
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Excisable_Items.Products AS Products,
		|	Excisable_Items.ExcisableGoods AS ExcisableGoods,
		|	Excisable_Items.Rate1 AS Rate1,
		|	Excisable_Items.ExciseCode AS ExciseCode,
		|	Excisable_Items.Rate1 * ISNULL(ExchangeRates.ConversionFactor_, 1) AS LocalBid,
		|	Excisable_Items.UnitOfMeasure AS ExciseUnit,
		|	Excisable_Items.ConversionFactor_ AS ConversionRatioOfUnits,
		|	Excisable_Items.Currency AS CurrencyOfExciseDuty,
		|	Excisable_Items.RateType AS RateType
		|INTO Excisable_Items
		|FROM
		|	DataOfExcisableItems AS Excisable_Items
		|		LEFT JOIN ExchangeRates AS ExchangeRates
		|		ON Excisable_Items.Currency = ExchangeRates.Currency
		|
		|INDEX BY
		|	Products";
		
		QueryText = StrReplace(QueryText, "&TableName", NameOfTableToSelect);
		
	Else
		
		QueryText =
		"SELECT
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	FALSE AS ExcisableGoods,
		|	0 AS Rate1,
		|	"""" AS ExciseCode,
		|	0 AS LocalBid,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS ExciseUnit,
		|	1 AS ConversionRatioOfUnits,
		|	&BaseCurrency AS CurrencyOfExciseDuty,
		|	VALUE(Enum.TypesOfExcisableCategoryRates.EmptyRef) AS RateType
		|INTO Excisable_Items
		|WHERE
		|	FALSE";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Prepares the Query Text with data on errors in the calculation of excise duty in the document "Application for the import of items from the EAEU".
//
// Parameters:
//  UseExcisableGoods - Boolean - Indicates whether the Company is using the import/production of excisable items
//
// Returns:
//  String - query text.
//
Function QueryTextErrorInExciseCalculation(UseExcisableGoods) Export
	
	If UseExcisableGoods Then
		
		QueryText =
		"SELECT
		|	*
		|FROM
		|	(SELECT
		|		CategoryTable.Products AS Products,
		|		CategoryTable.ExcisableGoodsCategory AS Category,
		|		ISNULL(TableExcisableItems.CurrencyOfExciseDuty, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
		|		CategoryTable.ExcisableGoodsCategory =
		|			VALUE(Catalog.ExcisableGoodsCategories.EmptyRef) AS CategoryNotSpecified,
		|		RatesTable.Rate1 IS NULL AS BidNotSet,
		|		TableExcisableItems.RateType IS NULL
		|			OR TableExcisableItems.ConversionRatioOfUnits = 0
		|				AND TableExcisableItems.RateType = &FirmBet AS ConversionRatioIsNotSet,
		|		TableExcisableItems.CurrencyOfExciseDuty IS NULL
		|			OR TableExcisableItems.CurrencyOfExciseDuty <> VALUE(Catalog.Currencies.EmptyRef)
		|				AND TableExcisableItems.CurrencyOfExciseDuty <> &BaseCurrency
		|				AND ExchangeRates.ConversionFactor_ IS NULL AS ConversionRateToLocalCurrencyIsNotSet
		|	FROM
		|		CategoryTable AS CategoryTable
		|			LEFT JOIN Excisable_Items AS TableExcisableItems
		|			ON CategoryTable.Products = TableExcisableItems.Products
		|			LEFT JOIN TableOfBidsByCategory AS RatesTable
		|			ON CategoryTable.ExcisableGoodsCategory = RatesTable.ExcisableGoodsCategory
		|			LEFT JOIN ExchangeRates AS ExchangeRates
		|			ON TableExcisableItems.CurrencyOfExciseDuty = ExchangeRates.Currency) AS NestedQuery
		|WHERE
		|	NestedQuery.CategoryNotSpecified
		|	OR NestedQuery.BidNotSet
		|	OR NestedQuery.ConversionRatioIsNotSet
		|	OR NestedQuery.ConversionRateToLocalCurrencyIsNotSet";
		
	Else
		
		QueryText =
		"SELECT
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ExcisableGoodsCategories.EmptyRef) AS Category,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	FALSE AS CategoryNotSpecified,
		|	FALSE AS BidNotSet,
		|	FALSE AS ConversionRatioIsNotSet,
		|	FALSE AS ConversionRateToLocalCurrencyIsNotSet
		|WHERE
		|	FALSE";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Handles excise tax calculation errors based on the request result.
//
// Parameters:
//   QueryResult - QueryResult - The result of a request containing data for error handling.
//   BidDate - Date - Date of checking the excise tax rate, for output in the message text.
//
Procedure ProcessExciseTaxCalculationErrors(QueryResult, BidDate) Export
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		ReportExciseTaxCalculationErrors(Selection, BidDate);
		
	EndDo;
	
EndProcedure

// Fills in additional data for calculating the excise tax amount in the Items table.
//
// Parameters:
//  DocumentObject - FormDataCollection - Document To Fill In
//
Procedure FillInAdditionalSignsOfItemsInImportStatement(DocumentObject) Export
	
	BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(DocumentObject.Organization);
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(DocumentObject.Organization);
	
	Query = New Query;
	
	Query.SetParameter("Products", DocumentObject.Goods.Unload().UnloadColumn("Products"));
	Query.SetParameter("Period", DocumentObject.Date);
	Query.SetParameter("Organization", DocumentObject.Organization);
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("EmptyBetType", Enums.TypesOfExcisableCategoryRates.EmptyRef());
	
	Query.Text =
	"SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoods AS ExcisableGoods,
	|	ISNULL(CategoryTable.ExcisableGoodsCategory.Currency, &BaseCurrency) AS CurrencyOfExciseDuty,
	|	ISNULL(CategoryTable.ExcisableGoodsCategory.RateType, &EmptyBetType) AS RateType
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, Products IN (&Products)
	|	AND Country = &Country) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		RowFilter = New Structure("Products", Selection.Products);
		FoundRows = DocumentObject.Goods.FindRows(RowFilter);
		For Each TableRow In FoundRows Do
			FillPropertyValues(TableRow, Selection);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

// Returns the Query Text of the temporary table in excisable goods. The request must have a parameter with
// the Date type and a parameter with the Reference Link type.Countries of the world, parameter names can be passed to a method.
// 
// Parameters:
//  NameOfTableToSelect - String - The name of the temporary table for selection containing the "Nomenclature" field.
//  NameOfDateParameter - String - The name of the parameter with the Date type. The default name is "Date".
//  NameOfCountryParameter - String - The name of the parameter of the Reference Link type.Countries of the world. The default name is "Country".
//
// Returns:
//  String - query text.
//
Function QueryTextTTExcisableItems(NameOfTableToSelect, NameOfDateParameter = "", NameOfCountryParameter = "") Export
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	If UseExcisableGoods Then
		
		QueryText =
		"SELECT
		|	CategoryTable.Products AS Products,
		|	CategoryTable.ExcisableGoods AS ExcisableGoods
		|INTO TTExcisableItems
		|FROM
		|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Date, (Products, Country) IN
		|		(SELECT
		|			T.Products AS Products,
		|			&Country AS Country
		|		FROM
		|			&TableName AS T)) AS CategoryTable
		|WHERE
		|	CategoryTable.ExcisableGoods
		|
		|INDEX BY
		|	Products";
		
		QueryText = StrReplace(QueryText, "&TableName", NameOfTableToSelect);
		
		If ValueIsFilled(NameOfDateParameter) Then
			QueryText = StrReplace(QueryText, "&Date", StrTemplate("&%1", NameOfDateParameter));
		EndIf;
		
		If ValueIsFilled(NameOfCountryParameter) Then
			QueryText = StrReplace(QueryText, "&Country", StrTemplate("&%1", NameOfCountryParameter));
		EndIf;
		
	Else
		
		QueryText =
		"SELECT
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	FALSE AS ExcisableGoods
		|INTO TTExcisableItems
		|WHERE
		|	FALSE";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns the Query Text to get the line numbers for which the excise tax amount should be cleared.
//
// Returns:
//  String - query text.
//
Function QueryTextLineNumbersForClearingExciseTaxAmount() Export
	
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	&Country AS Country
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.ExciseTaxAmount <> 0
	|
	|INDEX BY
	|	Products,
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoods AND &UseExcisableGoods AS ExcisableGoods
	|INTO TTExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Date, (Products, Country) IN
	|		(SELECT
	|			Goods.Products AS Products,
	|			Goods.Country AS Country
	|		FROM
	|			TTProducts_1 AS Goods)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	TTProducts_1 AS Goods
	|		LEFT JOIN TTExcisableItems AS Excisable_Items
	|		ON Goods.Products = Excisable_Items.Products
	|WHERE
	|	NOT ISNULL(Excisable_Items.ExcisableGoods, FALSE)";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Private

#Region SelectionOfInventoryOwnerAttributes

Function QueryTextTTExciseCategoriesOfItemsByDate()
	
	QueryText =
	"SELECT
	|	ProductItemsCategories.Period				AS Period,
	|	ProductItemsCategories.Products		AS Products,
	|	ProductItemsCategories.Country				AS Country,
	|	ProductItemsCategories.ExcisableGoods	AS ExcisableGoods,
	|	ProductItemsCategories.ExcisableGoodsCategory AS ItemCategory
	|INTO TTExciseCategoriesOfItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Date,
	|			(Products, Country) IN
	|				(SELECT DISTINCT
	|					TableOfGoods.Products	AS Products,
	|					&CountryOfTS					AS Country
	|				FROM
	|					&TableOfGoods AS TableOfGoods)
	|			AND &UseExcisableGoods
	|		) AS ProductItemsCategories
	|
	|INDEX BY
	|	Products";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExciseCategoriesOfItemsByPeriod()
	
	QueryText =
	"SELECT
	|	&PeriodField							AS Period,
	|	TableOfGoods.Products			AS Products,
	|	ProductItemsCategories.Country				AS Country,
	|	MAX(ProductItemsCategories.Period)	AS ActionPeriod
	|INTO TTExciseCategoriesByPeriod
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|		INNER JOIN InformationRegister.ExcisableGoodsCategories AS ProductItemsCategories
	|		ON TableOfGoods.Products = ProductItemsCategories.Products
	|			AND &PeriodField >= ProductItemsCategories.Period
	|			AND &CountryOfTS = ProductItemsCategories.Country
	|			AND &UseExcisableGoods
	|
	|GROUP BY
	|	&PeriodField,
	|	TableOfGoods.Products,
	|	ProductItemsCategories.Country
	|
	|INDEX BY
	|	ActionPeriod,
	|	Products,
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Period				AS Period,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Country				AS Country,
	|	ProductItemsCategories.ExcisableGoods	AS ExcisableGoods,
	|	ProductItemsCategories.ConversionFactor_ AS ConversionFactor_,
	|	ProductItemsCategories.ExcisableGoodsCategory AS ItemCategory
	|INTO TTExciseCategoriesOfItems
	|FROM
	|	TTExciseCategoriesByPeriod AS TableOfGoods
	|		INNER JOIN InformationRegister.ExcisableGoodsCategories AS ProductItemsCategories
	|		ON TableOfGoods.Products = ProductItemsCategories.Products
	|			AND TableOfGoods.ActionPeriod = ProductItemsCategories.Period
	|			AND TableOfGoods.Country = ProductItemsCategories.Country
	|
	|INDEX BY
	|	Period,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTExciseCategoriesByPeriod";
	
	Return QueryText;
	
EndFunction

#EndRegion

// Notifies about excise tax calculation errors.
//
// Parameters:
//  Selection - QueryResultSelection - A selection containing the fields not assigned category, not assigned Account performancereferences,
//  	There is no set-up for the account in the default setting, there is no set-up with the Boolean type.
//  Period - Date - Date to insert into the message text.
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure ReportExciseTaxCalculationErrors(Selection, Period, Cancel = False)
	
	MessageTemplate = NStr("vi = '%MessageText%. Chưa tính số tiền thuế TTĐB.';
							|ru = '%MessageText%. Сумма акциза не рассчитана.';
							|en = '%MessageText%. Excise amount is not calculated.'; fa = '%MessageText%. Excise amount is not calculated.';
							|it = '%MessageText%. Excise amount is not calculated.';
							|pl = '%MessageText%. Excise amount is not calculated.';
							|tr = '%MessageText%. Tüketim vergisi tutarı hesaplanmadı.'");
	
	If Selection.CategoryNotSpecified Then
		MessageText = NStr("vi = 'Chưa đặt thể loại cho hàng hóa chịu thuế TTĐB ""%Products%""';
							|ru = 'Не задана категория для подакцизного товара ""%Products%""';
							|en = 'Category for the ""%Products%"" excisable goods is not specified'; fa = 'Category for the ""%Products%"" excisable goods is not specified';
							|it = 'Category for the ""%Products%"" excisable goods is not specified';
							|pl = 'Category for the ""%Products%"" excisable goods is not specified';
							|tr = 'Tüketim vergisine tabi ""%Products%"" ürünü için kategori belirlenmedi'");
		MessageText = StrReplace(MessageText, "%Products%", Selection.Products);
		MessageText = StrReplace(MessageTemplate, "%MessageText%", MessageText);
		Common.MessageToUser(MessageText);
	EndIf;
	
	If Not ValueIsFilled(Selection.Category) Then
		Return;
	EndIf;
	
	If Selection.ConversionRatioIsNotSet Then
		MessageText = NStr("vi = 'Chưa đặt hệ số tính lại đối với thể loại ""%Category%"" của hàng hóa chịu thuế TTĐB ""%Products%""';
							|ru = 'Не задан коэффициент пересчета для категории ""%Category%"" подакцизного товара ""%Products%""';
							|en = 'Conversion ratio is not set for the ""%Category%"" category of the ""%Products%"" excisable goods'; fa = 'Conversion ratio is not set for the ""%Category%"" category of the ""%Products%"" excisable goods';
							|it = 'Conversion ratio is not set for the ""%Category%"" category of the ""%Products%"" excisable goods';
							|pl = 'Conversion ratio is not set for the ""%Category%"" category of the ""%Products%"" excisable goods';
							|tr = 'Tüketim vergisine tabi ""%Products%"" ürününün ""%Category%"" kategorisi için dönüştürme oranı belirlenmedi'");
		MessageText = StrReplace(MessageText, "%Category%", Selection.Category);
		MessageText = StrReplace(MessageText, "%Products%", Selection.Products);
		MessageText = StrReplace(MessageTemplate, "%MessageText%", MessageText);
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
	If Selection.ConversionRateToLocalCurrencyIsNotSet Then
		MessageText = NStr("vi = 'Chưa đặt tỷ giá tính lại theo tiền tệ kế toán pháp quy đối với tiền tệ %Currency% thuộc thể loại ""%Category%"" của hàng hóa chịu thuế TTĐB ""%Products%""';
							|ru = 'Не задан курс пересчета в валюту регламентированного учета для валюты %Currency% категории ""%Category%"" подакцизного товара ""%Products%""';
							|en = 'Conversion rate to the local accounting currency is not set for the %Currency% currency of the ""%Category%"" category of the ""%Products%"" excisable goods'; fa = 'Conversion rate to the local accounting currency is not set for the %Currency% currency of the ""%Category%"" category of the ""%Products%"" excisable goods';
							|it = 'Conversion rate to the local accounting currency is not set for the %Currency% currency of the ""%Category%"" category of the ""%Products%"" excisable goods';
							|pl = 'Conversion rate to the local accounting currency is not set for the %Currency% currency of the ""%Category%"" category of the ""%Products%"" excisable goods';
							|tr = 'Tüketim vergisine tabi ""%Products%"" ürününün ""%Category%"" kategorisinin %Currency% para birimi için yerel muhasebe para birimine dönüştürme kuru belirlenmedi'");
		MessageText = StrReplace(MessageText, "%Currency%", Selection.Currency);
		MessageText = StrReplace(MessageText, "%Category%", Selection.Category);
		MessageText = StrReplace(MessageText, "%Products%", Selection.Products);
		MessageText = StrReplace(MessageTemplate, "%MessageText%", MessageText);
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
	If Selection.BidNotSet Then
		MessageText = NStr("vi = 'Trong %Date% chưa đặt thuế suất đối với thể loại ""%Category%"" của hàng hóa chịu thuế TTĐB ""%Products%""';
							|ru = 'На %Date% не задана ставка для категории ""%Category%"" подакцизного товара ""%Products%""';
							|en = 'The rate for the ""%Category%"" category of the ""%Products%"" excisable goods is not set as of %Date%'; fa = 'The rate for the ""%Category%"" category of the ""%Products%"" excisable goods is not set as of %Date%';
							|it = 'The rate for the ""%Category%"" category of the ""%Products%"" excisable goods is not set as of %Date%';
							|pl = 'The rate for the ""%Category%"" category of the ""%Products%"" excisable goods is not set as of %Date%';
							|tr = 'Tüketim vergisine tabi ""%Products%"" ürününün ""%Category%"" kategorisi için %Date% kapsamında oran belirlenmedi'");
		MessageText = StrReplace(MessageText, "%Date%", Format(Period, "DLF=D;"));
		MessageText = StrReplace(MessageText, "%Category%", Selection.Category);
		MessageText = StrReplace(MessageText, "%Products%", Selection.Products);
		MessageText = StrReplace(MessageTemplate, "%MessageText%", MessageText);
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
EndProcedure

Procedure AddTaskToNonOperationalQueue(Document)

	Query = New Query;

	If Common.IsReference(TypeOf(Document)) Then
		DocumentRef = Document;
	Else
		DocumentRef = Document.Ref;
	EndIf;

	Query.SetParameter("Ref", DocumentRef);

	Query.Text = "SELECT
	|	DocumentData.Ref AS Document,
	|	DocumentData.Date AS TaskPeriod,
	|	&Organization AS Organization,
	|	VALUE(Catalog.BackdateJobKinds.RecordExciseRegisterRecords) AS JobKind
	|FROM
	|	&Document AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	If TypeOf(DocumentRef) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		Query.Text = StrReplace(Query.Text, "&Organization", "DocumentData.CompanyRecipient"); // @query-part
	Else
		Query.Text = StrReplace(Query.Text, "&Organization", "DocumentData.Organization"); // @query-part
	EndIf;
		 
	Query.Text = StrReplace(Query.Text, "&Document", "Document." + Document.Metadata().Name); // @query-part
	
	DataForRegisteringTasks = Query.Execute().Unload();
	
	TempTablesManager = Undefined;
	
	Source = AccumulationRegisters.RegisterRecordsByExcises.CreateRecordSet();
	RegisterMetadata = Metadata.AccumulationRegisters.RegisterRecordsByExcises;
	RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());
	
	TypesOfTasksToRegisterInQueue = BackdateJobQueue.TypesOfTasksToRegisterInQueue(RegisterMetadata);
	
	QueueRegister = Metadata.InformationRegisters.Find("JobsOfBackdateAdditionalDocumentPosting");
	TaskIdentifierForNonOperationalTasks = Common.MetadataObjectID(QueueRegister.FullName());
	
	If TypesOfTasksToRegisterInQueue.Count() > 0
		And TypesOfTasksToRegisterInQueue.Find(TaskIdentifierForNonOperationalTasks, "QueueRegister") = Undefined Then
		
		ArrayOfViews = New Array;
		ArrayOfViews.Add(Catalogs.BackdateJobKinds.RecordExciseRegisterRecords);
		
		InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.CreateJobs(RegisterManager, ArrayOfViews, Source,
			TempTablesManager, DataForRegisteringTasks);
		
	EndIf;
	
	For Each CurrentData In TypesOfTasksToRegisterInQueue Do
		
		TaskRegisterMetadata = Common.MetadataObjectByID(CurrentData.QueueRegister);
		TaskRegisterManager = Common.ObjectManagerByFullName(TaskRegisterMetadata.FullName());
		
		TaskRegisterManager.CreateJobs(RegisterManager, CurrentData.KindsOfTasks, Source,
			TempTablesManager, DataForRegisteringTasks);
		
	EndDo;
	
EndProcedure

// Returns an indication that the document can accrual excise taxes on imported items.
//
// Parameters:
//	Document - DocumentObject, DocumentRef - link to the document.
//
// Returns:
//	Boolean - an indication that the document can accrual excise taxes.
//
Function ThisDocumentMakesRegisteredRecordsForImportedItems(Document)
	
	DocumentType = TypeOf(Document);
	Result = False;
	
	If DocumentType = Type("DocumentObject.CCDImport")
		Or DocumentType = Type("DocumentObject.ApplicationForImportationOfGoods") Then
		
		Result = ImportOfExcisableItemsIsUsed(Document.Organization, Document.Date);
		
	ElsIf DocumentType = Type("DocumentRef.CCDImport")
		Or DocumentType = Type("DocumentRef.ApplicationForImportationOfGoods") Then
		
		Result = True;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an indication that the document is storno for a document
// that can accrual excise taxes.
//
// Parameters:
//	Document - DocumentObject, DocumentRef - link to the document.
//
// Returns:
//	Boolean - an indication that the document can accrual excise taxes.
//
Function ThisIsStornoDocument(Document)
	
	DocumentType = TypeOf(Document);
	Result = False;
	
	If DocumentType = Type("DocumentObject.ReversingEntry") Then
		
		If ThisDocumentMakesRegisteredRecordsForImportedItems(Document.ReversedDocument) Then
			
			Result = True;
		ElsIf ThisDocumentMakesRegisteredRecordsOfExcisableItemsProduced(Document.ReversedDocument) Then
		
			Result = True;

		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction
	
// Returns an indication that the document can accrual excise
// taxes for excisable items produced.
//
// Parameters:
//	Document - DocumentRef, DocumentObject - link to the document.
//
// Returns:
//	Boolean - an indication that the document can accrual excise taxes.
//
Function ThisDocumentMakesRegisteredRecordsOfExcisableItemsProduced(Document)
	
	DocumentType = TypeOf(Document);
	Result = False;
	
	If DocumentType = Type("DocumentRef.CustomerInvoice")
		Or DocumentType = Type("DocumentRef.SaleAdjustment")
		Or DocumentType = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
		Or DocumentType = Type("DocumentRef.InventoryConsumption")
		Or DocumentType = Type("DocumentRef.CustomerInvoiceIntercompany")
		Or DocumentType = Type("DocumentRef.IntercompanyGoodsReturn")
		Or DocumentType = Type("DocumentObject.CustomerInvoice")
		Or DocumentType = Type("DocumentObject.SaleAdjustment")
		Or DocumentType = Type("DocumentObject.ReturnOfGoodsFromCustomer")
		Or DocumentType = Type("DocumentObject.WriteOffOfGoodsShortages")
		Or DocumentType = Type("DocumentObject.InventoryConsumption")
		Or DocumentType = Type("DocumentObject.CustomerInvoiceIntercompany")
		Or DocumentType = Type("DocumentObject.IntercompanyGoodsReturn") Then
		
		Result = GetFunctionalOption("UseExcisableGoods");
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
