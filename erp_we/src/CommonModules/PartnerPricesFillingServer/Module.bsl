#Region Public

// Fills in the "Price" field in the product table.
//
// Parameters:
// 	TabularSection - FormDataCollection, TabularSection - Product table part of the document
// 	SelectedRows - Array, Undefined - An array of selected rows if Undefined, it will be filled in ALL rows
// 	FillParameters - See NewFillOptionsFillPrices
// 	StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSString.StructureOfActions
// 	CachedValues - Structure - The structure of the cached values.
// 		
// Returns:
//   Boolean - True if the prices are successfully filled.
//
Function FillInPrices(
	TabularSection, 
	SelectedRows, 
	FillParameters, 
	StructureOfActions = Undefined, 
	CachedValues = Undefined) Export
	
	PricesAreFilledOut = False;
	
	If FillParameters = Undefined Then
		Raise NStr("vi = 'Chưa chỉ ra tham số điền';
					|ru = 'Параметры заполнения не указаны';
					|en = 'Filling parameters are not specified'; fa = 'Filling parameters are not specified';
					|it = 'Parametri di compilazione non indicati';
					|pl = 'Parametry wypełnienia nie są wskazane';
					|tr = 'Doldurma parametreleri belirtilmedi'");
	EndIf;
	
	// Getting the default parameter structure
	Parameters = NewFillOptionsFillPrices();
	
	TMCommonUseClientServer.SupplementStructure(Parameters, FillParameters, True);
	
	// Checking incoming data
	If Not ValueIsFilled(Parameters.Terms) And Not ValueIsFilled(Parameters.VendorPriceKind) Then
		If StrFind(FillParameters.PopulationFields, "VATRate") = 0 Then
			Return False;
		EndIf;
	ElsIf Not ValueIsFilled(Parameters.Date) Or Not ValueIsFilled(Parameters.Currency) Then
		Return False;
	EndIf;
	
	VendorPriceKind = Catalogs.VendorPriceTypes.EmptyRef();
	If ValueIsFilled(Parameters.Terms) And Not ValueIsFilled(FillParameters.VendorPriceKind) Then
		VendorPriceKind = Common.ObjectAttributeValue(Parameters.Terms, "VendorPriceKind");
	Else
		VendorPriceKind = Parameters.VendorPriceKind;
	EndIf;
	
	Terms = Parameters.Terms;
	
	// Getting the upload by the tabular part
	ThereIsPackage_ = False;
	If TypeOf(TabularSection) = Type("ValueTable") Then
		ThereIsPackage_ = TabularSection.Columns.Find("Package") <> Undefined;
	Else
		ThereIsPackage_ = TabularSection.Unload(New Array).Columns.Find("Package") <> Undefined;
	EndIf;
	
	If ThereIsPackage_ Then
		TableColumns1 = "LineNumber, Products, Characteristic, Package";
	Else
		TableColumns1 = "LineNumber, Products, Characteristic";
	EndIf;
	
	Table = TMCommonUse.ExportValuesTable(
		TabularSection,
		SelectedRows,
		TableColumns1,
		Parameters.ColumnsByValue,
		Parameters.OtherColumnNames);
	
	If Not ThereIsPackage_ Then
		Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	EndIf;
	
	// Receiving a request
	Query = New Query;
	Query.SetParameter("Date", ?(ValueIsFilled(Parameters.Date), Parameters.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Parameters.Currency);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("VendorPriceKind", VendorPriceKind);
	Query.SetParameter("VATTaxation", ?(Parameters.Property("VATTaxation"), Parameters.VATTaxation, Enums.VATTaxationTypes.EmptyRef()));
	Query.SetParameter("ToReturnReusablePackage", ?(Parameters.Property("ToReturnReusablePackage"), Parameters.ToReturnReusablePackage, False));
	Query.SetParameter("Table", Table);
	
	If ValueIsFilled(Parameters.Organization) Then
		Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Parameters.Organization));
	Else
		Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.MainCountry());
	EndIf;
	
	Query.Text = GetQueryTextForTemporaryProductTable("TTTableProducts")
	             + GetQueryTextOfTemporaryPriceTable("TTPriceTable_", "TTTableProducts", Query.Parameters)
	             + "SELECT
	               |	TTPriceTable_.LineNumber AS LineNumber,
	               |	TTPriceTable_.VendorPriceKind AS VendorPriceKind,
	               |	TTPriceTable_.VATRate AS VATRate,
	               |	TTPriceTable_.Price
	               |FROM
	               |	TTPriceTable_ AS TTPriceTable_";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return PricesAreFilledOut;
	EndIf;
	
	FillingStructure = New Structure(Parameters.PopulationFields);
	RowsToProcess = New Array();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		FillPropertyValues(FillingStructure, Selection);
		TSRow = TabularSection[Selection.LineNumber - 1];
		FillPropertyValues(TSRow, FillingStructure);
		If StructureOfActions <> Undefined Then
			RowsToProcess.Add(TSRow);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		CachedValues);
	
	Return True;
	
EndFunction

// Returns supplier price data for the passed rows.
//
// Parameters:
//	Table - ValueTable - with the following fields:
//		* LineNumber       - Number -
//		* Products      - CatalogRef.Products -
//		* Characteristic    - CatalogRef.ItemsCharacteristics -
//		* Package          - CatalogRef.PackagesAndUnitsOfMeasure - 
//		* VendorPriceKind - EnumRef.VATTaxationTypes -
//	ParametersForGettingPrices - See NewParametersForGettingPartnerProductPrices 
//
// Returns:
// 	QueryResult - query result with the following fields:
// 		* LineNumber - Number - 
// 		* VATRate   - CatalogRef.VATRates - 
// 		* Price        - Number - 
//
Function PartnerProductPrices(Table, ParametersForGettingPrices) Export
	
	Query = New Query;
	Query.SetParameter("Table",                      Table);
	Query.SetParameter("Date",                         ParametersForGettingPrices.Date);
	Query.SetParameter("Currency",                       ParametersForGettingPrices.Currency);
	Query.SetParameter("VATTaxation",           ParametersForGettingPrices.VATTaxation);
	Query.SetParameter("ReturnReusablePackage", ParametersForGettingPrices.ReturnReusablePackage);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.MainCountry());
	
	Query.Text =
		"SELECT
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	Table.Package              AS Package,
		|	CAST(Table.VendorPriceKind AS Catalog.VendorPriceTypes) AS VendorPriceKind
		|INTO TTTableOfGoodsPrev
		|FROM
		|	&Table AS Table
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	Table.Package              AS Package,
		|	Table.VendorPriceKind     AS VendorPriceKind,
		|	Table.VendorPriceKind.Owner AS Partner
		|INTO TTTableProducts
		|FROM
		|	TTTableOfGoodsPrev AS Table
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	VendorPriceKind,
		|	Partner
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	ItemsPricesOfVendor.Products              AS Products,
		|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
		|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
		|	ItemsPricesOfVendor.Currency                    AS Currency,
		|	ItemsPricesOfVendor.Package                  AS Package,
		|	ItemsPricesOfVendor.Price                      AS Price
		|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
		|FROM
		|	InformationRegister.ItemsPricesOfVendor.SliceLast(ENDOFPERIOD(&Date, DAY),
		|				(Products, Characteristic, VendorPriceKind, Partner) IN
		|				(SELECT
		|					TemporaryTableOfGoods_.Products,
		|					TemporaryTableOfGoods_.Characteristic,
		|					TemporaryTableOfGoods_.VendorPriceKind,
		|					TemporaryTableOfGoods_.Partner
		|				FROM
		|					TTTableProducts AS TemporaryTableOfGoods_)
		|) AS ItemsPricesOfVendor
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	VendorPriceKind,
		|	Currency
		|;
		|
		|SELECT ALLOWED
		|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
		|	CASE
		|		WHEN
		|			&ReturnReusablePackage 
		|			AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|		THEN
		|			VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			OR &VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		THEN
		|			ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))
		|		ELSE
		|			VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|	END AS VATRate,
		|	CASE
		|		WHEN
		|			TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		THEN
		|			&QueryTextPackagingFactor1
		|		ELSE
		|			1
		|	END
		|	* PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price/ISNULL(&QueryTextPackagingFactor2,1)
		|	* CASE
		|		WHEN &Currency <> PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency
		|			THEN CASE
		|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
		|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
		|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|					THEN 
		|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
		|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS Price
		|FROM
		| TTTableProducts AS TemporaryTableOfGoods_
		|
		|LEFT JOIN
		|	PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS PricesOfSupplierNomenclatureCrossSectionOfTheLatest
		|ON
		|	TemporaryTableOfGoods_.Products = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products
		|	AND TemporaryTableOfGoods_.Characteristic = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Characteristic
		|	AND TemporaryTableOfGoods_.VendorPriceKind = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.VendorPriceKind
		|LEFT JOIN
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
		|ON 
		|	PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
		|	
		|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
		|	ON TRUE
		|
		|	LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS ProductsVATRates
		|	ON TemporaryTableOfGoods_.Products = ProductsVATRates.Products
		|	LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|	ON TRUE
		|;
		|";
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
		
	QueryResult = Query.Execute();
	
	Return QueryResult;
	
EndFunction

// Returns the price for the passed selection.
//
// Parameters:
//		FilterParameters - See NewSelectionParametersGetPriceBySelection 
//
// Returns:
// 		Number - Price
//
Function GetPriceBySelection(FilterParameters) Export
	
	Query = New Query;
	For Each Parameter In FilterParameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	If ValueIsFilled(FilterParameters.Organization) Then
		Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(FilterParameters.Organization));
	Else
		Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.MainCountry());
	EndIf;
	
	Query.Text =
	"SELECT
	|	1 AS LineNumber,
	|	Products.Ref AS Products,
	|	CAST(&Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
	|INTO TTTableProducts
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref = &Products
	|;" + GetQueryTextOfTemporaryPriceTable("TTPriceTable", "TTTableProducts", Query.Parameters) + "
	|SELECT
	|	TTPriceTable.Price AS Price
	|FROM
	|	TTPriceTable AS TTPriceTable
	|";
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	Selection = Result.Select();
	If Selection.Next() Then
		Return Selection.Price;
	EndIf;
	
EndFunction

#Region Constructors

// Constructor of the partner's price Nomenclature method(). 
// 
// Returns:
// 		Structure - : 
// 			* Date - Date -
// 			* Currency - CatalogRef.Currencies -
// 			* VATTaxation - EnumRef.VATTaxationTypes - AO-default, empty link.
// 			* ReturnReusablePackage - Boolean - by default, False 
//
Function NewParametersForGettingPartnerProductPrices() Export
	
	ParametersForGettingPrices = New Structure();
	ParametersForGettingPrices.Insert("Date", Date(1,1,1));
	ParametersForGettingPrices.Insert("Currency",PredefinedValue("Catalog.Currencies.EmptyRef"));
	ParametersForGettingPrices.Insert("VATTaxation", 
		PredefinedValue("Enum.VATTaxationTypes.EmptyRef"));
	ParametersForGettingPrices.Insert("ReturnReusablePackage", False);
		
	Return ParametersForGettingPrices;

EndFunction

// The constructor function of the selection structure for getting the price is used to get the atomic value of the price.
// Is used as a parameter of the method, Animatedaudioplayer.Get the sample price().  
// 
// Returns:
//	Structure - Structure of parameters for filling in the selection field. (shared fields first) :
//		shared fields. 
//			* Date - Date - the date on which the price should be received.
//			* Currency - CatalogRef.Currencies -
//			* Products - CatalogRef.Products -
//			* Characteristic - CatalogRef.ItemsCharacteristics -
//			* Package - CatalogRef.PackagesAndUnitsOfMeasure -
//			* VendorPriceKind - CatalogRef.VendorPriceTypes -
//			* Terms - CatalogRef.TermsOfPurchaseFromVendors -
//			* VATTaxation - EnumRef.VATTaxationTypes -
//			* ToReturnReusablePackage - Boolean - indicates whether a multi-turn container must be returned.
//
Function NewSelectionParametersGetPriceBySelection() Export
	
	FilterParameterStructure = New Structure;
	FilterParameterStructure.Insert("Date",Date(1,1,1));
	FilterParameterStructure.Insert("Organization",Catalogs.Companies.EmptyRef());
	FilterParameterStructure.Insert("Currency",Catalogs.Currencies.EmptyRef());
	FilterParameterStructure.Insert("Products",Catalogs.Products.EmptyRef());
	FilterParameterStructure.Insert("Characteristic",Catalogs.ItemsCharacteristics.EmptyRef());
	FilterParameterStructure.Insert("Package",Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	FilterParameterStructure.Insert("VendorPriceKind",Catalogs.VendorPriceTypes.EmptyRef());
	FilterParameterStructure.Insert("Terms",Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	FilterParameterStructure.Insert("VATTaxation",Enums.VATTaxationTypes.EmptyRef());
	FilterParameterStructure.Insert("ToReturnReusablePackage",False);
	
	Return FilterParameterStructure; 
	
EndFunction	

// Constructor for parameters of the fill in the Price method.
//
// Returns:
// 	Structure - Structure of filling parameters:
//		Required fields.
//			* Date - Date - Document date
//			* Currency - CatalogRef.Currencies - The document currency
//			* Terms - CatalogRef.TermsOfPurchaseFromVendors - Document Agreement
//					if the key is missing, then the parameter "Type of supplier" must be filled in.
//			* VendorPriceKind - CatalogRef.VendorPriceTypes - Supplier's price type
//					if the parameter is missing, then the "Agreement" parameter must be filled in.
//		Optional fields.
// 			* PopulationFields - String - A row listing the fields to be filled in in the table; 
// 					default value: "Price"; additional fields - "Type of supplier, StavkaNDS".
// 			* ColumnsByValue - See TMCommonUse.ExportValuesTable.ColumnsByValue
// 			* OtherColumnNames - See TMCommonUse.ExportValuesTable.NewColumnNames
// 			* VATTaxation - EnumRef.VATTaxationTypes -  
//
Function NewFillOptionsFillPrices() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("Date",Date(1,1,1));
	ParametersStructure.Insert("Organization", PredefinedValue("Catalog.Companies.EmptyRef"));
	ParametersStructure.Insert("Currency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	ParametersStructure.Insert("Terms", 
		PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	ParametersStructure.Insert("VendorPriceKind",
		PredefinedValue("Catalog.VendorPriceTypes.EmptyRef"));
	ParametersStructure.Insert("PopulationFields", "Price");
	ParametersStructure.Insert("ColumnsByValue", New Structure);
	ParametersStructure.Insert("OtherColumnNames", New Structure);
	ParametersStructure.Insert("VATTaxation", Enums.VATTaxationTypes.EmptyRef());
	
	Return ParametersStructure; 
	
EndFunction

#EndRegion

#Region BatchProcessingOfTableParts

// Adds a request to the request package to get the data needed to get the purchase price.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInPurchasePrice(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInPurchasePrice",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		ColumnsNames = EnterprisePricesFillingServer.ColumnNamesOfTemporaryProductTable();
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues) Then
			ColumnsNames.ColumnNamePackaging = "Package";
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Partner", CachedValues) Then
			ColumnsNames.ColumnNamePartner = "Partner";
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("VendorPriceKind", CachedValues) Then
			
			ColumnsNames.ColumnNamePriceType = "VendorPriceKind";
			
		ElsIf ActionParameters.Property("VendorPriceKind")
			And ValueIsFilled(ValueIsFilled(ActionParameters.VendorPriceKind)) Then
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				ActionParameters.VendorPriceKind);
			
		ElsIf ActionParameters.UseAgreementFromTable Then 
			
			ColumnsNames.ColumnNameAgreement = "Terms";
			
		ElsIf ValueIsFilled(ActionParameters.Terms) Then
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				Common.ObjectAttributeValue(
					ActionParameters.Terms,
					"VendorPriceKind"));
			
		Else
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				Catalogs.VendorPriceTypes.EmptyRef());
			
		EndIf;
		
		If ValueIsFilled(ActionParameters.Organization) Then
			RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(ActionParameters.Organization);
		Else
			RegistrationCountry = SettingsValueClientServerCached.MainCountry();
		EndIf;
		
		If Not ActionParameters.Property("ToReturnReusablePackage") Then
			ActionParameters.Insert("ToReturnReusablePackage", False);
		EndIf;
		
		QueriesTexts = QueryTextsForFillingInPricesBatchProcessing(ActionParameters, ColumnsNames);
		For Each Query In QueriesTexts Do
			QueryDetails.QueriesTexts.Add(Query.Value, Query.Presentation);
		EndDo;
		
		FilterParameterStructure = NewSelectionParametersGetPriceBySelection();
		CommonClientServer.SupplementStructure(FilterParameterStructure, ActionParameters, True);
		
		For Each Parameter In FilterParameterStructure Do
			QueryDetails.QueryOptions.Insert(Parameter.Key, Parameter.Value);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		QueryDetails.QueryOptions.Insert("RegistrationCountry", RegistrationCountry);
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to get the purchase conditions.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInPurchaseConditions(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInTermsOfPurchase",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		ColumnsNames = EnterprisePricesFillingServer.ColumnNamesOfTemporaryProductTable();
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues) Then
			ColumnsNames.ColumnNamePackaging = "Package";
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("VendorPriceKind", CachedValues) Then
			ColumnsNames.ColumnNamePriceType = "VendorPriceKind";
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Partner", CachedValues) Then
			ColumnsNames.ColumnNamePartner = "Partner";
		EndIf;
			
		If ActionParameters.Property("VendorPriceKind")
			And ValueIsFilled(ActionParameters.VendorPriceKind) Then
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				ActionParameters.VendorPriceKind);
			
		ElsIf ActionParameters.UseAgreementFromTable Then 
			
			ColumnsNames.ColumnNameAgreement = "Terms";
			
		ElsIf ValueIsFilled(ActionParameters.Terms) Then
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				Common.ObjectAttributeValue(
					ActionParameters.Terms,
					"VendorPriceKind"));
					
		Else
			
			QueryDetails.QueryOptions.Insert("VendorPriceKind",
				Catalogs.VendorPriceTypes.EmptyRef());
			
		EndIf;
		
		If ValueIsFilled(ActionParameters.Organization) Then
			RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(ActionParameters.Organization);
		Else
			RegistrationCountry = SettingsValueClientServerCached.MainCountry();
		EndIf;
		
		If Not ActionParameters.Property("ToReturnReusablePackage") Then
			ActionParameters.Insert("ToReturnReusablePackage", False);
		EndIf;
		
		QueriesTexts = QueryTextsForFillingInPurchaseConditionsBatchProcessing(ActionParameters, ColumnsNames);
		For Each Query In QueriesTexts Do
			QueryDetails.QueriesTexts.Add(Query.Value, Query.Presentation);
		EndDo;
		
		For Each Parameter In ActionParameters Do
			QueryDetails.QueryOptions.Insert(Parameter.Key, Parameter.Value);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		QueryDetails.QueryOptions.Insert("RegistrationCountry", RegistrationCountry);
	
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Returns the query text for the temporary product table
//
// Parameters:
// 		TableName - String - Name string for the temporary table.
//
// Returns:
// 		String - The text of the temporary table query.
//
Function GetQueryTextForTemporaryProductTable(TableName)
	
	QueryText =  "
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package
	|INTO TableName
	|FROM
	|	&Table AS Table
	|;
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);
	
	Return QueryText;
	
EndFunction

// Returns the query text for the temporary table of product prices by row numbers
//
// Parameters:
// 		TableName - String - Name string for a temporary table
// 		NameOfTemporaryProductTable - String - Name string of the temporary product table
// 		Vidtsenkakparameter-Boolean-True if the query "Vidtsen" should be used as a parameter; False-if as a field in the temporary table of products.
//
// Returns:
// 		String - The text of the temporary table query.
//
Function GetQueryTextOfTemporaryPriceTable(TableName, NameOfTemporaryProductTable, QueryOptions)
	
	QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	QueryOptions.Insert("Partner", Common.ObjectAttributeValue(QueryOptions.VendorPriceKind, "Owner"));
	
	QueryText = "
	|SELECT
	|	ItemsPricesOfVendor.Products              AS Products,
	|	ItemsPricesOfVendor.Characteristic            AS Characteristic,
	|	ItemsPricesOfVendor.Currency                    AS Currency,
	|	ItemsPricesOfVendor.VendorPriceKind         AS VendorPriceKind,
	|	ItemsPricesOfVendor.Package                  AS Package,
	|	ItemsPricesOfVendor.Price                      AS Price
	|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(ENDOFPERIOD(&Date, DAY),
	|				Partner = &Partner AND
	|				VendorPriceKind = &VendorPriceKind AND
	|				(Products, Characteristic) IN
	|				(SELECT
	|					TemporaryTableOfGoods_.Products,
	|					TemporaryTableOfGoods_.Characteristic
	|				FROM
	|					&NameOfTemporaryProductTable AS TemporaryTableOfGoods_)
	|) AS ItemsPricesOfVendor
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Currency
	|;
	|
	|SELECT ALLOWED
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	&VendorPriceKind AS VendorPriceKind,
	|	CASE
	|		WHEN
	|			&ToReturnReusablePackage = TRUE
	|			AND TemporaryTableOfGoods_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))
	|		ELSE VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|	END AS VATRate,
	|	CASE
	|		WHEN
	|			TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		THEN
	|			&QueryTextPackagingFactor1
	|		ELSE
	|			1
	|	END
	|	* ISNULL(PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price, 0)/ISNULL(&QueryTextPackagingFactor2,1)
	|	* CASE
	|		WHEN &Currency <> PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|					WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|						AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|						AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN 
	|						(CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						/ (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS Price
	|INTO TableName
	|FROM
	| &NameOfTemporaryProductTable AS TemporaryTableOfGoods_
	|
	|LEFT JOIN
	|	PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|ON
	|	TemporaryTableOfGoods_.Products = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products
	|	AND TemporaryTableOfGoods_.Characteristic = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Characteristic
	|LEFT JOIN
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|ON 
	|	PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|	
	|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON TRUE
	|	
	|LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
	|		Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|	ON TemporaryTableOfGoods_.Products = ProductsVATRates.Products
	|LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
	|	ON TRUE
	|;
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);

	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"TemporaryTableOfGoods_.Package",
		"TemporaryTableOfGoods_.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
		"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
		
	Return QueryText
	
EndFunction

#Region BatchProcessingOfTablePartsIsService

// Get the texts of requests to receive purchase prices.
//
// Parameters:
// 	ActionParameters - Structure - parameters for getting purchase prices.
// 	ColumnsNames - See EnterprisePricesFillingServer.ColumnNamesOfTemporaryProductTable.
//
// Returns:
// 	ValueList of String - texts of requests to get prices to insert.
//
Function QueryTextsForFillingInPricesBatchProcessing(ActionParameters, ColumnsNames) Export
	
	Result = New ValueList();
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS Products,
	|	TTDataSource.Characteristic AS Characteristic,
	|	ISNULL(PackingTable_.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	&Partner AS Partner,
	|	&VendorPriceKind AS VendorPriceKind
	|INTO FillInPurchasePricePreparatory
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|		ON &TextOfPackagingUnitField = PackingTable_.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind";
	
	If ValueIsFilled(ColumnsNames.ColumnNamePackaging) Then
		TextOfPackagingUnitField = StrTemplate("TTDataSource.%1", ColumnsNames.ColumnNamePackaging);
	Else
		TextOfPackagingUnitField = "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
	EndIf;
	
	If ActionParameters.PriceIncludesVAT <> Undefined Then
		TextPriceTypeWithSelection =
		"CASE
		|		WHEN CAST(&VendorPriceKind AS Catalog.VendorPriceTypes).PriceIncludesVAT = &PriceIncludesVAT
		|			THEN &VendorPriceKind
		|		ELSE VALUE(Catalog.VendorPriceTypes.EmptyRef)
		|	END"; //@Query-part
		QueryText = StrReplace(QueryText, "&VendorPriceKind", TextPriceTypeWithSelection);
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&TextOfPackagingUnitField",
		TextOfPackagingUnitField);
		
	If ValueIsFilled(ColumnsNames.ColumnNamePartner) Then
		
		PartnerFieldText = StrTemplate(
			"TTDataSource.%1",
			ColumnsNames.ColumnNamePartner);
		
		QueryText = StrReplace(QueryText,
			"&Partner",
			PartnerFieldText);
		
	EndIf;
	
	If ValueIsFilled(ColumnsNames.ColumnNamePriceType) Then
		
		TextOfPriceTypeField = StrTemplate(
			"TTDataSource.%1",
			ColumnsNames.ColumnNamePriceType);
		
		QueryText = StrReplace(QueryText,
			"&VendorPriceKind",
			TextOfPriceTypeField);
		
	EndIf;
		
	If ValueIsFilled(ColumnsNames.ColumnNameAgreement) Then
		TextOfPriceTypeField = StrTemplate(
			"CASE WHEN TTDataSource.%1 = UNDEFINED THEN
			|		VALUE(Catalog.VendorPriceTypes.EmptyRef)
			|	ELSE
			|		ISNULL(CAST(TTDataSource.%1 AS Catalog.TermsOfPurchaseFromVendors).VendorPriceKind,
			|				 VALUE(Catalog.VendorPriceTypes.EmptyRef))
			|	END",
			ColumnsNames.ColumnNameAgreement);
			
		QueryText = StrReplace(QueryText,
			"&VendorPriceKind",
			TextOfPriceTypeField);
	EndIf;
	
	Result.Add(QueryText, "FillInPurchasePricePreparatory");
	
	QueryText =
	"SELECT
	|	RateTable.Currency AS Currency,
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO PurchasePrices_ExchangeRate
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RateTable
	|
	|INDEX BY
	|	Currency";
	
	Result.Add(QueryText, "PurchasePrices_ExchangeRate");
	
	QueryText =
	"SELECT
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO PurchasePrices_ExchangeRateConversion
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency
	|	AND BaseCurrency = &BaseCurrency) AS RateTable";
	
	Result.Add(QueryText, "PurchasePrices_ExchangeRateConversion");
	
	QueryText =
	"SELECT
	|	TableOfVATRates.Products AS Products,
	|	TableOfVATRates.VATRate AS VATRate
	|INTO PurchasePrices_VATRates
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(&Date, Products IN
	|		(SELECT
	|			TTDataSource.Products
	|		FROM
	|			TTDataSource AS TTDataSource)
	|	AND Country IN (&RegistrationCountry, VALUE(Catalog.WorldCountries.EmptyRef))) AS TableOfVATRates
	|
	|INDEX BY
	|	Products";
	
	Result.Add(QueryText, "PurchasePrices_VATRates");
	
	QueryText =
	"SELECT
	|	TableOfVATRates.VATRate AS VATRate
	|INTO PurchasePrices_BasicVATRates
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS TableOfVATRates";
	
	Result.Add(QueryText, "PurchasePrices_BasicVATRates");
	
	QueryText =
	"SELECT
	|	RegisterTable.Products AS Products,
	|	RegisterTable.Characteristic AS Characteristic,
	|	RegisterTable.VendorPriceKind AS VendorPriceKind,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.Package AS Package,
	|	RegisterTable.Price AS Price
	|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, Characteristic,
	|		Partner, VendorPriceKind) IN
	|		(SELECT
	|			TableOfGoods.Products AS Products,
	|			TableOfGoods.Characteristic AS Characteristic,
	|			TableOfGoods.Partner AS Partner,
	|			TableOfGoods.VendorPriceKind AS VendorPriceKind
	|		FROM
	|			FillInPurchasePricePreparatory AS TableOfGoods)) AS RegisterTable
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind";
	
	Result.Add(QueryText, "PricesOfSupplierNomenclatureCrossSectionOfTheLatest");
	
	QueryText =
	"SELECT
	|	DataSourceTable.IdOfTTRow AS IdOfTTRow,
	|	CASE
	|		WHEN &ToReturnReusablePackage = TRUE
	|		AND ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|				VALUE(Catalog.VATRates.EmptyRef)))
	|		ELSE VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|	END AS VATRate,
	|	CASE
	|		WHEN DataSourceTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		ELSE 1
	|	END * ISNULL(PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor2, 1) *
	|		CASE
	|		WHEN &Currency <> PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END AS Price
	|FROM
	|	FillInPurchasePricePreparatory AS DataSourceTable
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON DataSourceTable.Products = ProductsTable.Ref
	|		LEFT JOIN PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|		ON DataSourceTable.Products = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products
	|		AND DataSourceTable.Characteristic = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Characteristic
	|		AND DataSourceTable.VendorPriceKind = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.VendorPriceKind
	|		LEFT JOIN PurchasePrices_ExchangeRate AS CurrencyRatesPrices
	|		ON (PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency)
	|		LEFT JOIN PurchasePrices_ExchangeRateConversion AS Currency_Rates
	|		ON (TRUE)
	|		LEFT JOIN PurchasePrices_VATRates AS ProductsVATRates
	|		ON DataSourceTable.Products = ProductsVATRates.Products
	|		LEFT JOIN PurchasePrices_BasicVATRates AS BasicVATRates
	|		ON (TRUE)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DataSourceTable.Package",
			"DataSourceTable.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, "FillInPurchasePrice");
	
	Return Result;
	
EndFunction

// Get the texts of requests to receive purchase terms.
//
// Parameters:
// 	ActionParameters - Structure - parameters for getting purchase prices.
// 	ColumnsNames - See EnterprisePricesFillingServer.ColumnNamesOfTemporaryProductTable.
//
// Returns:
// 	ValueList of String - texts of requests to get prices to insert.
//
Function QueryTextsForFillingInPurchaseConditionsBatchProcessing(ActionParameters, ColumnsNames) Export
	
	Result = New ValueList();
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS Products,
	|	TTDataSource.Characteristic AS Characteristic,
	|	ISNULL(PackingTable_.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	&Partner AS Partner,
	|	&VendorPriceKind AS VendorPriceKind
	|INTO FillInTermsOfProcurementPreparatory
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|		ON &TextOfPackagingUnitField = PackingTable_.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	If ValueIsFilled(ColumnsNames.ColumnNamePackaging) Then
		TextOfPackagingUnitField = StrTemplate("TTDataSource.%1", ColumnsNames.ColumnNamePackaging);
	Else
		TextOfPackagingUnitField = "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)";
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&TextOfPackagingUnitField",
		TextOfPackagingUnitField);
		
	If ValueIsFilled(ColumnsNames.ColumnNamePartner) Then
		
		PartnerFieldText = StrTemplate(
			"TTDataSource.%1",
			ColumnsNames.ColumnNamePartner);
		
		QueryText = StrReplace(QueryText,
			"&Partner",
			PartnerFieldText);
		
	EndIf;
	
	If ActionParameters.PriceIncludesVAT <> Undefined Then
		TextPriceTypeWithSelection =
		"CASE WHEN CAST(&VendorPriceKind AS Catalog.VendorPriceTypes).PriceIncludesVAT = &PriceIncludesVAT THEN
		| 		&VendorPriceKind
		|	ELSE
		|		VALUE(Catalog.VendorPriceTypes.EmptyRef)
		|	END"; //@Query-part
		QueryText = StrReplace(QueryText, "&VendorPriceKind", TextPriceTypeWithSelection);
	EndIf;
	
	If ValueIsFilled(ColumnsNames.ColumnNamePriceType) Then
			
		TextOfPriceTypeField = StrTemplate(
			"CASE
			|		WHEN &VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
			|			THEN TTDataSource.%1
			|		ELSE &VendorPriceKind
			|	END",
			ColumnsNames.ColumnNamePriceType);
		
		QueryText = StrReplace(QueryText,
			"&VendorPriceKind",
			TextOfPriceTypeField);
		
	EndIf;
	
	If ValueIsFilled(ColumnsNames.ColumnNameAgreement) Then
		TextOfPriceTypeField = StrTemplate(
			"CASE WHEN TTDataSource.%1 = UNDEFINED THEN
			|		VALUE(Catalog.VendorPriceTypes.EmptyRef)
			|	ELSE
			|		ISNULL(CAST(TTDataSource.%1 AS Catalog.TermsOfPurchaseFromVendors).VendorPriceKind,
			|				 VALUE(Catalog.VendorPriceTypes.EmptyRef))
			|	END",
			ColumnsNames.ColumnNameAgreement);
			
		QueryText = StrReplace(QueryText,
			"&VendorPriceKind",
			TextOfPriceTypeField);
	EndIf;
	
	Result.Add(QueryText, "FillInTermsOfProcurementPreparatory");
	
	QueryText =
	"SELECT
	|	RateTable.Currency AS Currency,
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO TermsOfPurchase_ExchangeRate
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RateTable
	|
	|INDEX BY
	|	Currency";
	
	Result.Add(QueryText, "TermsOfPurchase_ExchangeRate");
	
	QueryText =
	"SELECT
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO TermsOfPurchase_ExchangeRateConversion
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency
	|	AND BaseCurrency = &BaseCurrency) AS RateTable";
	
	Result.Add(QueryText, "TermsOfPurchase_ExchangeRateConversion");
	
	QueryText =
	"SELECT
	|	TableOfVATRates.Products AS Products,
	|	TableOfVATRates.VATRate AS VATRate
	|INTO TermsOfPurchase_VATRates
	|FROM
	|	InformationRegister.ProductsVATRates.SliceLast(&Date, Products IN
	|		(SELECT
	|			TTDataSource.Products
	|		FROM
	|			TTDataSource AS TTDataSource)
	|	AND Country IN (&RegistrationCountry, VALUE(Catalog.WorldCountries.EmptyRef))) AS TableOfVATRates
	|
	|INDEX BY
	|	Products";
	
	Result.Add(QueryText, "TermsOfPurchase_VATRates");
	
	QueryText =
	"SELECT
	|	TableOfVATRates.VATRate AS VATRate
	|INTO TermsOfPurchase_BasicVATRates
	|FROM
	|	InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS TableOfVATRates";
	
	Result.Add(QueryText, "TermsOfPurchase_BasicVATRates");
	
	QueryText =
	"SELECT
	|	RegisterTable.Products AS Products,
	|	RegisterTable.Characteristic AS Characteristic,
	|	RegisterTable.VendorPriceKind AS VendorPriceKind,
	|	RegisterTable.Currency AS Currency,
	|	RegisterTable.Package AS Package,
	|	RegisterTable.Price AS Price
	|INTO PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|FROM
	|	InformationRegister.ItemsPricesOfVendor.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, Characteristic,
	|		Partner, VendorPriceKind) IN
	|		(SELECT
	|			TableOfGoods.Products AS Products,
	|			TableOfGoods.Characteristic AS Characteristic,
	|			TableOfGoods.Partner AS Partner,
	|			TableOfGoods.VendorPriceKind AS VendorPriceKind
	|		FROM
	|			FillInTermsOfProcurementPreparatory AS TableOfGoods)) AS RegisterTable
	|
	|INDEX BY
	|	Products,
	|	Characteristic";
	
	Result.Add(QueryText, "PricesOfSupplierNomenclatureCrossSectionOfTheLatest");
	
	QueryText =
	"SELECT
	|	DataSourceTable.IdOfTTRow AS IdOfTTRow,
	|	DataSourceTable.VendorPriceKind VendorPriceKind,
	|	CASE
	|		WHEN &ToReturnReusablePackage = TRUE
	|		AND ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|				VALUE(Catalog.VATRates.EmptyRef)))
	|		ELSE VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|	END AS VATRate,
	|	CASE
	|		WHEN DataSourceTable.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		ELSE 1
	|	END * ISNULL(PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor2, 1) *
	|		CASE
	|		WHEN &Currency <> PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END AS Price
	|FROM
	|	FillInTermsOfProcurementPreparatory AS DataSourceTable
	|		LEFT JOIN Catalog.Products AS ProductsTable
	|		ON DataSourceTable.Products = ProductsTable.Ref
	|		LEFT JOIN PricesOfSupplierNomenclatureCrossSectionOfTheLatest AS PricesOfSupplierNomenclatureCrossSectionOfTheLatest
	|		ON DataSourceTable.Products = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products
	|		AND DataSourceTable.Characteristic = PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Characteristic
	|		LEFT JOIN TermsOfPurchase_ExchangeRate AS CurrencyRatesPrices
	|		ON (PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency)
	|		LEFT JOIN TermsOfPurchase_ExchangeRateConversion AS Currency_Rates
	|		ON (TRUE)
	|		LEFT JOIN TermsOfPurchase_VATRates AS ProductsVATRates
	|		ON DataSourceTable.Products = ProductsVATRates.Products
	|		LEFT JOIN TermsOfPurchase_BasicVATRates AS BasicVATRates
	|		ON (TRUE)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DataSourceTable.Package",
			"DataSourceTable.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
			"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, "FillInTermsOfPurchase");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
