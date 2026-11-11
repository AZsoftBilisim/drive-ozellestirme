#Region Public

// Fills in the "Price" field in the product table.
//
// Parameters:
// 		TabularSection - FormDataCollection, TabularSection - The commodity tabular part of the document. Contains including:
// 			* LineNumber			- Number - Line number
// 			* Products			- CatalogRef.Products - Products
// 			* Characteristic		- CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
// 			* Count			- Number - Count
// 			* NumberOfPackages	- Number - Number of packages
// 	SelectedRows - Array, Undefined - Array of selected rows 
// 												. if Undefined, ALL rows will be filled in.
// 	FillParameters - See NewFillOptionsFillPrices 
// 	StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSString.StructureOfActions
// 		
// Returns:
//   Boolean - True if the prices are successfully filled.
//
Function FillInPrices(TabularSection,
	SelectedRows = Undefined, 
	FillParameters = Undefined,
	StructureOfActions = Undefined) Export
	
	PricesAreFilledOut = False;
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(FillParameters.Date);
	
	If FillParameters = Undefined Then
		Raise NStr("vi = 'Chưa chỉ ra tham số điền';
					|ru = 'Параметры заполнения не указаны';
					|en = 'Filling parameters are not specified'; fa = 'Filling parameters are not specified';
					|it = 'Parametri di compilazione non indicati';
					|pl = 'Parametry wypełnienia nie są wskazane';
					|tr = 'Doldurma parametreleri belirtilmedi'");
		Return PricesAreFilledOut;
	EndIf;
	
	CachedValues = Undefined;
	
	ColumnNamePackaging = "Package";
	If FillParameters.Property("ColumnNamePackaging") Then
		ColumnNamePackaging = FillParameters.ColumnNamePackaging;
	EndIf;
	
	// Getting the default parameter structure
	Parameters = NewFillOptionsFillPrices();
	TMCommonUseClientServer.SupplementStructure(Parameters, FillParameters, True);
	
	// Checking incoming data
	If Not ValueIsFilled(Parameters.Terms) And Not ValueIsFilled(Parameters.PriceKind) And Not ValueIsFilled(Parameters.Partner) Then
		Return PricesAreFilledOut;
	ElsIf Not ValueIsFilled(Parameters.Currency) Then
		Return PricesAreFilledOut;
	EndIf;
	
	AvailabilityOfTableColumns = AvailabilityOfTableColumns(TabularSection,
		"NumberOfPackages,
		|RowCode,
		|SalesOrder,
		|Series,
		|Price,
		|PriceKind");
	
	AdditionalColumns  = "";
	ThereIsNumberOfPackages = AvailabilityOfTableColumns.NumberOfPackages;
	ThereIsSeries = AvailabilityOfTableColumns.Series;
	ThereIsLineCode = AvailabilityOfTableColumns.RowCode And AvailabilityOfTableColumns.SalesOrder;
	ThereIsPrice = AvailabilityOfTableColumns.Price;
	ThereIsPriceType = AvailabilityOfTableColumns.PriceKind;
	
	If ThereIsNumberOfPackages Then
		AdditionalColumns = ?(Parameters.CalculateSets, "," + "Count, NumberOfPackages, ProductsInSet, ItemVariantOfSet", "");
	Else
		AdditionalColumns = ?(Parameters.CalculateSets, "," + "Count, ProductsInSet, ItemVariantOfSet", "");
	EndIf;
	
	If ThereIsSeries Then
		AdditionalColumns = ""+ AdditionalColumns + ", Series";
	EndIf;
	
	// Getting the upload by the tabular part
	Table = TMCommonUse.ExportValuesTable(
		TabularSection,
		SelectedRows,
		"LineNumber, Products, Characteristic, " + ColumnNamePackaging + AdditionalColumns,
		Parameters.ColumnsByValue,
		Parameters.OtherColumnNames);
		
	MaximumRowIndex_ = 0;
	For Each TSRow In TabularSection Do
		If TSRow.LineNumber > MaximumRowIndex_ Then
			MaximumRowIndex_ = TSRow.LineNumber;
		EndIf;
	EndDo;
	
	CoefficientsOfProportionalityOfCalculationOfPricesOfSets = Undefined;
	DataOnNumberOfSets = Undefined;
	If Parameters.CalculateSets Then
		
		If Not ThereIsNumberOfPackages Then
			Table.Columns.Add("NumberOfPackages", TMCommonUse.DescriptionOfQuantitativeFieldType());
			For Each TSRow In Table Do
				TSRow.NumberOfPackages = TSRow.Count;
			EndDo;
		EndIf;
		
		CoefficientsOfProportionalityOfCalculationOfPricesOfSets = SetsServer.DistributionCoefficients(Table, Parameters);
		DataOnNumberOfSets = NumberOfSets(Table);
		
		Sets = CoefficientsOfProportionalityOfCalculationOfPricesOfSets.Copy();
		Sets.GroupBy("ProductsInSet, ItemVariantOfSet");
		IndexOf = MaximumRowIndex_;
		For Each String In Sets Do
			
			IndexOf = IndexOf + 1;
			
			NewRow = Table.Add();
			NewRow.LineNumber         = IndexOf;
			NewRow.Products        = String.ProductsInSet;
			NewRow.Characteristic      = String.ItemVariantOfSet;
			NewRow[ColumnNamePackaging] = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndDo;
		
		Table.Columns.Delete("Count");
		Table.Columns.Delete("NumberOfPackages");
		
	EndIf;
	
	If UsePriceManagementSystem25 And Not ThereIsSeries Then
		Table.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	
	// Receiving a request
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Date", ?(ValueIsFilled(Parameters.Date), Parameters.Date, CurrentSessionDate()));
	Query.SetParameter("Currency", Parameters.Currency);
	Query.SetParameter("Table", Table);
	Query.SetParameter("PriceKind", Catalogs.TypesOfPrices.EmptyRef());
	
	ColumnsNames = ColumnNamesOfTemporaryProductTable();
	ColumnsNames.ColumnNameRowNumber = 	"LineNumber";
	ColumnsNames.ColumnNameSeries = 			"Series";
	ColumnsNames.ColumnNamePackaging = 		ColumnNamePackaging;
	
	If UsePriceManagementSystem25 Then
		Query.Text = Query.Text + GetQueryTextForTemporaryProductTable2_5("", "TTTableProducts", ColumnsNames);
	Else
		Query.Text = Query.Text + GetQueryTextForTemporaryProductTable("", "TTTableProducts", ColumnsNames);
	EndIf;
	
	DonTClearArbitraryPrices = False;
	If ValueIsFilled(Parameters.PriceKind) Then
		
		Query.SetParameter("PriceKind", Parameters.PriceKind);
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		
		If UsePriceManagementSystem25 Then
			Query.Text = Query.Text + GetQueryTextOfTemporaryPriceTable2_5("TTPriceTable_", "TTTableProducts", True);
		Else
			Query.Text = Query.Text + GetQueryTextOfTemporaryPriceTable("TTPriceTable_", "TTTableProducts", True);
		EndIf;
		Query.Text = Query.Text + StrReplace("
		|;
		|SELECT
		|	TTTableProducts.LineNumber AS LineNumber,
		|	TTPriceTable_.PriceKind AS ReplacementPriceTypeField,
		|	TTPriceTable_.Price AS ReplacementPriceField,
		|	&VATRate AS VATRate
		|FROM
		|	TTTableProducts AS TTTableProducts
		|		LEFT JOIN TTPriceTable_ AS TTPriceTable_
		|		ON (TTPriceTable_.LineNumber = TTTableProducts.LineNumber)
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(
		|				&Date,
		|				(Country = &RegistrationCountry
		|					OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|					AND Products IN
		|						(SELECT
		|							T.Products
		|						FROM
		|							TTTableProducts AS T)) AS ProductsVATRates
		|		ON (TTTableProducts.Products = ProductsVATRates.Products)
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)",
		"&VATRate",
		VATAccountingERP.QueryTextVATRate(
			"&VATTaxation",
			"TTTableProducts.Products",
			"&ReturnReusablePackage"));
		
		Query.SetParameter("VATTaxation", Parameters.VATTaxation);
		Query.SetParameter("ReturnReusablePackage", Parameters.ReturnReusablePackage);
		VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Parameters.Organization, Parameters.Date);
		
		Query.Text = StrReplace(Query.Text, "ReplacementPriceField", Parameters.PriceField);
		Query.Text = StrReplace(Query.Text, "ReplacementPriceTypeField", Parameters.PriceTypeField);
		
	ElsIf ValueIsFilled(Parameters.Terms) Then
		
		If TypeOf(Parameters.Terms) = Type("CatalogRef.TermsOfSale")
			And SalesServer.ThisIsAgreementOnNewCommission(Parameters.Terms) Then
				// For "New Commission agreements", filling in prices must be carried out according to the Contract
			Return PricesAreFilledOut;
		EndIf;
		
		DonTClearArbitraryPrices = ThereIsPrice And ThereIsPriceType;
		
		Query.SetParameter("Terms", Parameters.Terms);
		Query.SetParameter("Organization", Parameters.Organization);
		Query.SetParameter("VATTaxation", Parameters.VATTaxation);
		Query.SetParameter("ReturnReusablePackage", Parameters.ReturnReusablePackage);
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());

		If UsePriceManagementSystem25 Then
			
			TypesOfAgreementPrices = TypesOfPartnerPrices(Parameters.Terms);
			If TypesOfAgreementPrices.Count() = 0 Then
				Return PricesAreFilledOut;
			EndIf;
			
			Query.SetParameter("TypesOfPrices", TypesOfAgreementPrices);
			Query.SetParameter("LowPriorityShift", TypesOfAgreementPrices.Count());
			Query.Text = Query.Text + QueryTextPrices_2_5("TTTableProducts", True);
		Else
			Query.Text = Query.Text + GetQueryTextOfTemporaryPriceTableByAgreement("TTPriceTableByAgreement", "TTTableProducts");
			Query.Text = Query.Text + GetQueryTextOfTemporaryPriceTable("TTPriceTableByPriceType", "TTPriceTableByAgreement", False);
			Query.Text = Query.Text + "
			|;
			|SELECT
			|	TTPriceTableByAgreement.LineNumber AS LineNumber,
			|	TTPriceTableByAgreement.PriceKind AS PriceKind,
			|	TTPriceTableByAgreement.VATRate AS VATRate,
			|	TTPriceTableByAgreement.DeliveryPeriodDays AS DeliveryPeriodDays,
			|	CASE
			|		WHEN TTPriceTableByAgreement.Price = 0
			|			THEN TTPriceTableByPriceType.Price
			|		ELSE TTPriceTableByAgreement.Price
			|	END AS Price
			|FROM
			|	TTPriceTableByAgreement AS TTPriceTableByAgreement
			|		LEFT JOIN TTPriceTableByPriceType AS TTPriceTableByPriceType
			|		ON (TTPriceTableByPriceType.LineNumber = TTPriceTableByAgreement.LineNumber)";
		EndIf;
		
		VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Parameters.Organization, Parameters.Date);
		
	ElsIf Parameters.Property("Partner") And ValueIsFilled(Parameters.Partner) And UsePriceManagementSystem25 Then
		
		Query.SetParameter("Partner", Parameters.Partner);
		Query.SetParameter("Organization", ?(Parameters.Property("Organization"), Parameters.Organization, Catalogs.Companies.EmptyRef()));
		Query.SetParameter("VATTaxation", ?(Parameters.Property("VATTaxation"), Parameters.VATTaxation, Enums.VATTaxationTypes.EmptyRef()));
		Query.SetParameter("ReturnReusablePackage", ?(Parameters.Property("ReturnReusablePackage"), Parameters.ReturnReusablePackage, False));
		Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());

		Query.Text = Query.Text + QueryTextPrices_2_5("TTTableProducts");
		TypesOfPartnerPrices = TypesOfPartnerPrices(Parameters.Partner);
		If TypesOfPartnerPrices.Count() = 0 Then
			Return PricesAreFilledOut;
		EndIf;
		Query.SetParameter("TypesOfPrices", TypesOfPartnerPrices);
		Query.SetParameter("LowPriorityShift", TypesOfPartnerPrices.Count());
		VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Parameters.Organization, Parameters.Date);

	Else

		Return PricesAreFilledOut;

	EndIf;
	
	Query.Text = Query.Text +
		"
		|ORDER BY
		|	LineNumber"; // @Query-part-1
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return PricesAreFilledOut;
	EndIf;
	
	RowsToProcess = New Array;
	ProcessedLinesTakingIntoAccountError = New Array;
	Errors_ = New Map();
	
	FillingStructure = New Structure(Parameters.PopulationFields);
	ThereIsPriceFilling = FillingStructure.Property("Price");
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		// Calculation of the prices of the components of the set
		If Selection.LineNumber > MaximumRowIndex_ Then
			
			FoundRows = Table.FindRows(New Structure("LineNumber", Selection.LineNumber));
			If FoundRows.Count() = 0 Then
				Continue;
			EndIf;
		
			Filter = New Structure;
			Filter.Insert("ProductsInSet", FoundRows[0].Products);
			Filter.Insert("ItemVariantOfSet", FoundRows[0].Characteristic);
			
			FoundRows = CoefficientsOfProportionalityOfCalculationOfPricesOfSets.FindRows(Filter); // Array of LineOfATabularSection
			
			NumberOfSets = 1;
			DataOnNumberOfSetsOfRowsFound = DataOnNumberOfSets.FindRows(Filter);
			If DataOnNumberOfSetsOfRowsFound.Count() > 0 Then
				NumberOfSets = DataOnNumberOfSetsOfRowsFound[0].MinimumQuantity;
			EndIf;
			
			TotalCost = 0;
			AmountForAllocation = Selection.Price * NumberOfSets;
			
			ServiceTS = New ValueTable;
			ServiceTS.Columns.Add("TSRow");
			ServiceTS.Columns.Add("Count");
			ServiceTS.Columns.Add("Cost");
			For Each CurrentRow In FoundRows Do
				
				TSRow = TabularSection[CurrentRow.LineNumber - 1];

				If ThereIsLineCode And TSRow.RowCode <> 0 Then
					Continue;
				EndIf;
				
				Cost = CurrentRow.Price;
				Count = ?(ThereIsNumberOfPackages, TSRow.NumberOfPackages, TSRow.Count);
				
				NewRow = ServiceTS.Add();
				NewRow.TSRow   = TSRow;
				NewRow.Cost  = Cost;
				NewRow.Count = Count;
				
				TotalCost = TotalCost + CurrentRow.Price;
				
			EndDo;
			ServiceTS.Sort("Count DESC");
			
			LineNumber = 0;
			RowsCount = ServiceTS.Count();
			For Each CurrentRow In ServiceTS Do
				
				TSRow = CurrentRow.TSRow;
				Cost = CurrentRow.Cost;
				Count = CurrentRow.Count;
				
				LineNumber = LineNumber + 1;
				
				FillPropertyValues(FillingStructure, Selection);
				FillPropertyValues(TSRow, FillingStructure);
				
				If Count <> 0 And TotalCost <> 0 Then
					TSRow.Price = Round(((Cost / TotalCost) * AmountForAllocation) / Count, 2);
				Else
					TSRow.Price = 0;
				EndIf;
				
				TotalCost = TotalCost - Cost;
				AmountForAllocation = AmountForAllocation - TSRow.Price * Count;
				
				Error_ = 0;
				If LineNumber = RowsCount Then
					Error_ = AmountForAllocation;
				EndIf;
				
				If StructureOfActions <> Undefined Then
					Errors_.Insert(TSRow, Error_);
					ProcessedLinesTakingIntoAccountError.Add(TSRow);
				EndIf;
				
			EndDo;
			
		Else
			
			FillPropertyValues(FillingStructure, Selection);
			If TypeOf(TabularSection) <> Type("ValueTable") Then
				TSRow = TabularSection[Selection.LineNumber - 1];
			Else
				FoundRows = TabularSection.FindRows(New Structure("LineNumber", Selection.LineNumber));
				If FoundRows.Count() > 0 Then
					TSRow = FoundRows[0];
				Else
					Continue;
				EndIf;
			EndIf;
			
			If DonTClearArbitraryPrices And ThereIsPriceFilling
				And Not ValueIsFilled(Selection.PriceKind) And Not ValueIsFilled(Selection.Price)
				And Not ValueIsFilled(TSRow.PriceKind) And ValueIsFilled(TSRow.Price) Then
				// The price did not come up. In TS, an arbitrary one is set. Do not overfill.
				Continue;
			EndIf;
			
			FillPropertyValues(TSRow, FillingStructure);
			
			If StructureOfActions <> Undefined Then
				RowsToProcess.Add(TSRow);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If StructureOfActions <> Undefined Then
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			TabularSection,
			CachedValues);
		
		If ProcessedLinesTakingIntoAccountError.Count() Then
			StructureOfActions.Insert("RecalculateAmountTakingIntoAccountRoundingError",
				New Structure("ErrorsByLines", Errors_));
				
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				ProcessedLinesTakingIntoAccountError,
				StructureOfActions,
				TabularSection,
				CachedValues);
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

// Setting a conditional design for the price type.
//
// Parameters:
//  Form - ClientApplicationForm - Contains this form 
//  NameOfPriceTypeInputField - String - Name of the form element containing the type of price,
//                                  if it differs from the "product price".
//  PathToSelectionField - String - Full path to the "view Price" attribute,
//                             if it differs from " Object.Goods.View prices".
//
Procedure EstablishConditionalAppearanceOfPriceTypes(Form,
											   NameOfPriceTypeInputField = "GoodsPriceKind",
											   PathToSelectionField = "Object.Goods.PriceKind") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[NameOfPriceTypeInputField]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<tùy ý>';
																		|ru = '<произвольная>';
																		|en = '<custom>'; fa = '<سفارشی>';
																		|it = '<arbitraria>';
																		|pl = '<custom>';
																		|tr = '<isteğe bağlı>'"));	
	
EndProcedure

// Setting the conditional design for the amount with VAT field 
//		, depending on the "price includes"flag.
//
// Parameters:
//	Form - ClientApplicationForm - Contains this form 
//	NameOfFieldWithVATAmount - String - The name of the form element that contains the amount including VAT,
//                                   if it is different from "Tourismand".
//
Procedure SetConditionalAppearancePriceIncludesVAT(
	Form,
	NameOfFieldWithVATAmount = "GoodsAmountIncludingVAT") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	FormField = FormItems[NameOfFieldWithVATAmount]; // FormField
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PriceIncludesVAT");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

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
		If Parameter.Key = "Characteristic" And TypeOf(Parameter.Value) <> Type("CatalogRef.ItemsCharacteristics") Then
			Query.SetParameter(Parameter.Key, Catalogs.ItemsCharacteristics.EmptyRef());
		ElsIf Parameter.Key = "Series" And TypeOf(Parameter.Value) <> Type("CatalogRef.ItemsBatches") Then
			Query.SetParameter(Parameter.Key, Catalogs.ItemsBatches.EmptyRef());
		Else		
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndIf;
	EndDo;
	
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25(FilterParameters.Date) Then
		QueryText =
		"SELECT
		|	CAST(&PriceKind AS Catalog.TypesOfPrices) AS PriceKind,
		|	CAST(&Products AS Catalog.Products) AS Products,
		|	CAST(&Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
		|	CAST(&Series AS Catalog.ItemsBatches) AS Series,
		|	CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
		|INTO GoodsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.PriceKind AS PriceKind,
		|	GoodsTable.Products AS Products,
		|	CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE GoodsTable.Characteristic.ItemsCharacteristicForPricing
		|	END AS PricingVariant,
		|	ISNULL(CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
		|		ELSE GoodsTable.Series.ItemsBatchForPricing
		|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
		|	CASE
		|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		ELSE GoodsTable.Package
		|	END AS PricingPackage
		|INTO FilterTable
		|FROM
		|	GoodsTable AS GoodsTable
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = GoodsTable.Products.ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) /
		|		ISNULL(&QueryTextPackagingFactor2, 1) * CASE
		|		WHEN &Currency <> ItemPricesCrossSectionOfTheLatest.Currency
		|			THEN CASE
		|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
		|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
		|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|					THEN CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
		|				ELSE 0
		|			END
		|		ELSE 1
		|	END AS Price
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, PricingVariant,
		|		PricingBatch, PricingPackage, PriceKind) IN
		|		(SELECT
		|			T.Products,
		|			T.PricingVariant,
		|			T.PricingBatch,
		|			T.PricingPackage,
		|			T.PriceKind
		|		FROM
		|			FilterTable AS T)) AS ItemPricesCrossSectionOfTheLatest
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
		|		ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
		|		ON TRUE
		|";
	Else		
		QueryText =
		"SELECT
		|	ISNULL(&QueryTextPackagingFactor1, 1)
		|	* ISNULL(ItemPricesCrossSectionOfTheLatest.Price,0)/ISNULL(&QueryTextPackagingFactor2,1)
		|	* CASE
		|		WHEN &Currency <> ItemPricesCrossSectionOfTheLatest.Currency
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
		|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY), 
		|				PriceKind = CAST(&PriceKind AS Catalog.TypesOfPrices)
		|				AND Products = CAST(&Products AS Catalog.Products)
		|				AND Characteristic = CAST(&Characteristic AS Catalog.ItemsCharacteristics)
		|) AS ItemPricesCrossSectionOfTheLatest
		|
		|LEFT JOIN
		|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
		|ON 
		|	ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
		|	
		|LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
		|	ON TRUE
		|";
	EndIf;
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
		"CAST(&Products AS Catalog.Products)"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemPricesCrossSectionOfTheLatest.Package",
		"ItemPricesCrossSectionOfTheLatest.Products"));
		
	Query.Text = QueryText;	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 0;
	EndIf;
	Selection = Result.Select();
	If Selection.Next() Then
		Return Round(Selection.Price, 2);
	EndIf;
	
EndFunction

// Get the text of the request for prices to be inserted into other requests.
// 
// Parameters:
//  NameOfTemporaryProductTable - String - The name of the temporary table of products of the higher-level request (the table of products at the entrance)
//  NameOfTemporaryPriceTable - String - Name of the temporary output price table
//  ColumnsNames - See ColumnNamesOfTemporaryProductTable
//  RequestDate_ - Undefined, Date - The date of the request, to obtain information which pricing option to apply
// 
// Returns:
//  String - Get the text of the request to receive prices for insertion
Function GetTextOfRequestToGetPricesToInsert(NameOfTemporaryProductTable, 
	NameOfTemporaryPriceTable = Undefined, 
	ColumnsNames = Undefined, 
	RequestDate_ = Undefined) Export

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(RequestDate_);
	
	If ColumnsNames = Undefined Then
		ColumnsNames = ColumnNamesOfTemporaryProductTable();
	EndIf;
	
	PriceViewAsParameter = IsBlankString(ColumnsNames.ColumnNamePriceType);

	If UsePriceManagementSystem25 Then
		QueryText = GetQueryTextForTemporaryProductTable2_5(NameOfTemporaryProductTable, "TTTableProductsForCommunication", ColumnsNames);
		QueryText = QueryText + GetQueryTextOfTemporaryPriceTable2_5(NameOfTemporaryPriceTable, "TTTableProductsForCommunication", PriceViewAsParameter);
	Else
		QueryText = GetQueryTextForTemporaryProductTable(NameOfTemporaryProductTable, "TTTableProductsForCommunication", ColumnsNames);
		QueryText = QueryText + GetQueryTextOfTemporaryPriceTable(NameOfTemporaryPriceTable, "TTTableProductsForCommunication", PriceViewAsParameter);
	EndIf;

	Return QueryText;
	
EndFunction

#Region BatchProcessingOfTableParts

// Adds a request to the request package to get the data needed to get the price of the Transfer of products to the giver.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
Procedure CompleteQueryTextAndFillInPriceOfTransferringManufacturedProductsToGiver(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters, PropertyValue;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInPriceOfTransferringProductsToGiver",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		KindOfTransferPrice = Undefined;
		KindOfTransferPrice = Catalogs.TypesOfPrices.DefaultPriceType(KindOfTransferPrice,
			New Structure("UseWhileTransferringProductsToMaterialProvider", True));
		
		If ValueIsFilled(KindOfTransferPrice) Then
			
			ColumnsNames = ColumnNamesOfTemporaryProductTable();
			ColumnsNames.ColumnNameRowNumber = "IdOfTTRow";
			
			If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues)
				And Not (ActionParameters.Property("ProcessBarcodes", PropertyValue)
					And PropertyValue.NotUsePackages) Then
				
				ColumnsNames.ColumnNamePackaging = "Package";
				
			EndIf;
			
			If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Series", CachedValues) Then
				ColumnsNames.ColumnNameSeries = "Series";
			EndIf;
			
			ListOfRequests = QueryTextsForFillingInPricesBatchProcessing("TTDataSource",
				"FillInPriceOfTransferringProductsToGiver",
				ColumnsNames,
				ActionParameters.Date);
			
			For Each Query In ListOfRequests Do
				QueryDetails.QueriesTexts.Add(Query.Value, Query.Presentation);
			EndDo;
			
			QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
			QueryDetails.QueryOptions.Insert("Currency", ActionParameters.Currency);
			QueryDetails.QueryOptions.Insert("PriceKind", KindOfTransferPrice);
			QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to get the issue price.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
Procedure CompleteQueryTextCheckFillInIssuePrice(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters, PropertyValue;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckFillIssuePrice",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		If Not ActionParameters.Property("PriceKind") Then
			ActionParameters.Insert("PriceKind", Catalogs.TypesOfPrices.EmptyRef());
		EndIf;
		
		ColumnsNames = ColumnNamesOfTemporaryProductTable();
		ColumnsNames.ColumnNameRowNumber 	= "IdOfTTRow";
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Package", CachedValues)
			And Not (ActionParameters.Property("ProcessBarcodes", PropertyValue)
				And PropertyValue.NotUsePackages) Then
			ColumnsNames.ColumnNamePackaging = "Package";
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Series", CachedValues) Then
			ColumnsNames.ColumnNameSeries = "Series";
		EndIf;
		
		ListOfRequests = QueryTextsForFillingInPricesBatchProcessing("TTDataSource",
			"CheckFillIssuePrice",
			ColumnsNames,
			ActionParameters.Date);
		
		For Each Query In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(Query.Value, Query.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		QueryDetails.QueryOptions.Insert("Currency", ActionParameters.Currency);
		QueryDetails.QueryOptions.Insert("PriceKind", ActionParameters.PriceKind);
		QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to get the sales price.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInSalesPrice(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters, PropertyValue;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInSalePrice",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ColumnsNames = ColumnNamesOfTemporaryProductTable();
		ColumnsNames.ColumnNameRowNumber = "IdOfTTRow";
		
		ColumnNamePackaging = CommonClientServer.StructureProperty(ActionParameters, "ColumnNamePackaging", "Package");
		ColumnNamePriceType = CommonClientServer.StructureProperty(ActionParameters, "ColumnNamePriceType", "PriceKind");
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource(ColumnNamePackaging, CachedValues)
			And Not (ActionParameters.Property("ProcessBarcodes", PropertyValue)
				And PropertyValue.NotUsePackages) Then
			ColumnsNames.ColumnNamePackaging = ColumnNamePackaging;
		EndIf;
		
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Series", CachedValues) Then
			ColumnsNames.ColumnNameSeries = "Series";
		EndIf;
		
		If ActionParameters.Property("PriceKind") Then
			QueryDetails.QueryOptions.Insert("PriceKind", ActionParameters.PriceKind);
		Else
			ColumnsNames.ColumnNamePriceType = ColumnNamePriceType;
		EndIf;
		
		ListOfRequests = QueryTextsForFillingInPricesBatchProcessing("TTDataSource",
			"FillInSalePrice",
			ColumnsNames,
			ActionParameters.Date);
		
		For Each Query In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(Query.Value, Query.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
		QueryDetails.QueryOptions.Insert("Currency", ActionParameters.Currency);
		QueryDetails.QueryOptions.Insert("Date", ActionParameters.Date);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Constructors

// Constructor for parameters of the fill in the Price method.
// 
// Returns:
// 	Structure - Structure of filling parameters:
// 		Required fields.
// 			* Date - Date - Document date
// 			* Currency - CatalogRef.Currencies - The document currency
// 			* Terms - CatalogRef.TermsOfSale - 
// 							if the key is missing, then the "Price view" parameter must be filled in.
// 			* PriceKind - CatalogRef.TypesOfPrices - 
// 							if the parameter is missing, then the "Agreement" parameter must be filled in.
// 		Optional fields.
// 			* PopulationFields - String - A row listing the fields to be filled in in the table; 
// 					default value: "Price"; additional fields - "Price type, Delivery time, StavkaNDS".
// 			* ColumnsByValue - See TMCommonUse.ExportValuesTable.ColumnsByValue
// 			* OtherColumnNames - See TMCommonUse.ExportValuesTable.NewColumnNames
// 			* CalculateSets - Boolean
// 			* Organization - CatalogRef.Companies
// 			* VATTaxation - EnumRef.VATTaxationTypes
// 			* ReturnReusablePackage - Boolean
//
Function NewFillOptionsFillPrices() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("Date",Date(1,1,1));
	ParametersStructure.Insert("Currency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	ParametersStructure.Insert("PriceKind", PredefinedValue("Catalog.TypesOfPrices.EmptyRef"));
	ParametersStructure.Insert("Terms",PredefinedValue("Catalog.TermsOfSale.EmptyRef"));
	ParametersStructure.Insert("Partner",PredefinedValue("Catalog.Partners.EmptyRef"));
	
	ParametersStructure.Insert("PopulationFields", "Price");
	ParametersStructure.Insert("ColumnsByValue", New Structure);
	ParametersStructure.Insert("OtherColumnNames", New Structure);
	ParametersStructure.Insert("CalculateSets", False);
	
	ParametersStructure.Insert("Organization", PredefinedValue("Catalog.Companies.EmptyRef"));
	ParametersStructure.Insert("VATTaxation", PredefinedValue("Enum.VATTaxationTypes.EmptyRef"));
	ParametersStructure.Insert("ReturnReusablePackage", False);
	ParametersStructure.Insert("PriceField", "Price");
	ParametersStructure.Insert("PriceTypeField", "PriceKind");
	
	Return ParametersStructure; 
	
EndFunction

// The constructor function of the selection structure for getting the price is used to get the atomic value of the price.
// Used as a parameter of the Getsceneselection () method.  
// 
// Returns:
//	Structure - Structure of parameters for filling in the selection field:
//		* Date - Date - the date on which the price should be received.
//		* Currency - CatalogRef.Currencies -
//		* Products - CatalogRef.Products -
//		* Characteristic - CatalogRef.ItemsCharacteristics -
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure -
//		* Series - CatalogRef.ItemsBatches -
//		* PriceKind - CatalogRef.TypesOfPrices - .
//
Function NewSelectionParametersGetPriceBySelection() Export
	
	FilterParameterStructure = New Structure;
	FilterParameterStructure.Insert("Date",Date(1,1,1));
	FilterParameterStructure.Insert("Currency",Catalogs.Currencies.EmptyRef());
	FilterParameterStructure.Insert("Products",Catalogs.Products.EmptyRef());
	FilterParameterStructure.Insert("Characteristic",Catalogs.ItemsCharacteristics.EmptyRef());
	FilterParameterStructure.Insert("Package",Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	FilterParameterStructure.Insert("Series",Catalogs.ItemsBatches.EmptyRef());
	FilterParameterStructure.Insert("PriceKind",Catalogs.TypesOfPrices.EmptyRef());
	
	Return FilterParameterStructure; 
	
EndFunction

// Column names of the temporary table of products.
// 
// Returns:
//  Structure - Column Names Of The Temporary Product Table:
// * ColumnNameRowNumber - String - By default, "Line numbers"
// * ColumnNameSeries - String - By default, "Series"
// * ColumnNamePackaging - String - By default, "Packaging"
// * ColumnNamePriceType - String - If there are no columns in the table, then the "View Price" parameter is used
// * ColumnNameCurrency - String - If there is no column in the table, then the "Currency" parameter is used
// * ColumnNameAgreement - String - If there is no column in the table, then the "Agreement" parameter is used
// * ColumnNamePartner - String - If there is no column in the table, then the Partner parameter is used
Function ColumnNamesOfTemporaryProductTable() Export
	
	ColumnsNames = New Structure;
	ColumnsNames.Insert("ColumnNameRowNumber",	"");
	ColumnsNames.Insert("ColumnNameSeries",		"");
	ColumnsNames.Insert("ColumnNamePackaging",		"");
	ColumnsNames.Insert("ColumnNamePriceType",		"");
	ColumnsNames.Insert("ColumnNameCurrency",		"");
	ColumnsNames.Insert("ColumnNameAgreement",	"");
	ColumnsNames.Insert("ColumnNamePartner",		"");
	
	Return ColumnsNames; 
	
EndFunction	

// Constructor of parameters for checking the type of contract prices to be filled in.
//
// Returns:
//	Structure - Structure of parameters for checking the Contract price type:  
// 	* TabularSectionName           - String - Name of the tabular part of the document
// 	* TabularSectionPresentation - String - Representation of the name of the tabular part
// 	* TypeOfContractPrice             - CatalogRef.TypesOfPrices - Selected type of contract prices
// 	* FieldPriceType                 - String - Name of the contract price type field
// 	* PriceIncludesVAT             - Boolean - indicates whether VAT is included in the price for the selected type of prices.
//
Function NewParametersForCheckingTypeOfContractPrices() Export
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("TabularSectionName", "Goods");
	ParametersStructure.Insert("TabularSectionPresentation", NStr("vi = 'Hàng hóa';
																	|ru = 'Товары';
																	|en = 'Goods'; fa = 'کالاها';
																	|it = 'Merci';
																	|pl = 'Goods';
																	|tr = 'Ürünler'"));
	ParametersStructure.Insert("PriceKind", Catalogs.TypesOfPrices.EmptyRef());
	ParametersStructure.Insert("PriceIncludesVAT", Undefined);
	ParametersStructure.Insert("FieldPriceType", "PriceKind");
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function NumberOfSets(Table)
	
	Query = New Query(
	"SELECT
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Package             AS Package,
	|	Table.NumberOfPackages   AS NumberOfPackages
	|INTO _SetComposition
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Package             AS Package,
	|	Table.NumberOfPackages   AS NumberOfPackages
	|INTO SetComposition
	|FROM
	|	_SetComposition AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|WHERE
	|	ProductKitConfigurations.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|                                                                VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConfigurationOptionsForProductRange.Ref.Owner       AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	ConfigurationOptionsForProductRange.Package       AS Package,
	|	SUM(ConfigurationOptionsForProductRange.NumberOfPackages) AS DefaultNumberOfPackages,
	|	SUM(0) AS NumberOfPackages
	|INTO Table
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM SetComposition AS T)
	|
	|GROUP BY
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	0,
	|	Table.NumberOfPackages
	|FROM
	|	SetComposition AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	SUM(Table.DefaultNumberOfPackages) AS DefaultNumberOfPackages,
	|	SUM(Table.NumberOfPackages) AS NumberOfPackages
	|INTO Result
	|FROM
	|	Table AS Table
	|
	|GROUP BY
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultNumberOfPackages <> 0
	|				THEN Result.NumberOfPackages / Result.DefaultNumberOfPackages
	|			ELSE NULL
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumQuantity
	|FROM
	|	Result AS Result
	|GROUP BY
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|");
	
	Query.SetParameter("Table", Table);
	
	ReturnValue = Query.Execute().Unload();
	
	Return ReturnValue;
	
EndFunction

// Returns the query text for the temporary table of product prices by row numbers
//
// Parameters:
// 		TableName - String, Undefined - Name string for a temporary table
// 		NameOfTemporaryProductTable - String - Name string of the temporary product table
// 		Vidtsenkakparameter-Boolean-True if the query "Vidtsen" should be used as a parameter; False-if as a field in the temporary table of products.
//
// Returns:
// 		String - The text of the temporary table query.
//
Function GetQueryTextOfTemporaryPriceTable(TableName, NameOfTemporaryProductTable, PriceViewAsParameter = True)
	
	QueryText =
	"SELECT ALLOWED
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CASE
	|		WHEN
	|			TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		THEN
	|			&QueryTextPackagingFactor1
	|		ELSE
	|			1
	|	END
	|	* ISNULL(ItemPricesCrossSectionOfTheLatest.Price,0)/ISNULL(&QueryTextPackagingFactor2,1)
	|	* CASE
	|		WHEN TemporaryTableOfGoods_.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
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
	|	LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				ENDOFPERIOD(&Date, DAY), 
	|				(Products, Characteristic, PriceKind) IN
	|					(SELECT
	|						TemporaryTableOfGoods_.Products,
	|						TemporaryTableOfGoods_.Characteristic,
	|						TemporaryTableOfGoods_.PriceKind
	|					FROM
	|						&NameOfTemporaryProductTable AS TemporaryTableOfGoods_)) AS ItemPricesCrossSectionOfTheLatest
	|	ON TemporaryTableOfGoods_.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND TemporaryTableOfGoods_.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|		AND TemporaryTableOfGoods_.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON Currency_Rates.Currency = TemporaryTableOfGoods_.Currency 
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", ?(ValueIsFilled(TableName),"INTO " + TableName, ""));

	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);

	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
			
	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
			
	Return QueryText;
EndFunction

// Returns the query text for the temporary product table
//
// Parameters:
//    ProductTableName_ - String - The name of the product table. If it is not filled in, then it will be passed to the request as a parameter
//    TableName - String - Name string for the temporary table.
//    ColumnsNames - See ColumnNamesOfTemporaryProductTable
//  
// Returns:
//    String - The text of the temporary table query.
//
Function GetQueryTextForTemporaryProductTable(ProductTableName_, TableName, ColumnsNames)
	
	QueryText = "
	|SELECT DISTINCT
	|	&NameLineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	&NamePackaging AS Package,
	|	&PriceKind AS PriceKind,
	|	&Currency AS Currency
	|INTO TableName
	|FROM
	|	&Table AS Table
	|;
	|";

	If Not IsBlankString(ProductTableName_) Then
		QueryText = StrReplace(QueryText, "&Table", ProductTableName_);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNameRowNumber) Then
		QueryText = StrReplace(QueryText, "&NameLineNumber", "0");
	Else
		QueryText = StrReplace(QueryText, "&NameLineNumber", "Table." + ColumnsNames.ColumnNameRowNumber);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNamePackaging) Then
		QueryText = StrReplace(QueryText, "&NamePackaging", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NamePackaging", "Table." + ColumnsNames.ColumnNamePackaging);
	EndIf;

	If Not IsBlankString(ColumnsNames.ColumnNamePriceType) Then
		QueryText = StrReplace(QueryText, "&PriceKind", "Table." + ColumnsNames.ColumnNamePriceType);
	EndIf;

	If Not IsBlankString(ColumnsNames.ColumnNameCurrency) Then
		QueryText = StrReplace(QueryText, "&Currency", "Table." + ColumnsNames.ColumnNameCurrency);
	EndIf;

	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);
	
	Return QueryText;
	
EndFunction

// Returns the query text for the temporary table of product prices by row numbers
//
// Parameters:
// 		TableName - String - Name string for a temporary table
// 		NameOfTemporaryProductTable - String - Name string of the temporary product table.
//
// Returns:
// 		String - The text of the temporary table query.
//
Function GetQueryTextOfTemporaryPriceTableByAgreement(TableName, NameOfTemporaryProductTable)
	
	QueryText = "
	|SELECT ALLOWED
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.Products AS Products,
	|	TemporaryTableOfGoods_.Characteristic AS Characteristic,
	|	TemporaryTableOfGoods_.Package AS Package,
	|	TemporaryTableOfGoods_.Currency AS Currency,
	|	&VATRate AS VATRate,
	|	CASE
	|		WHEN ISNULL(AgreementGoods.Price, 0) > 0
	|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|		WHEN AgreementGoods.PriceKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				AND AgreementGoods.PriceKind IS NOT NULL 
	|			THEN AgreementGoods.PriceKind
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND AgreementPriceGroups.PricesKind IS NOT NULL 
	|				AND AgreementPriceGroups.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN AgreementPriceGroups.PricesKind
	|		WHEN (AgreementGoods.PriceKind = VALUE(Catalog.TypesOfPrices.EmptyRef)
	|				OR AgreementGoods.PriceKind IS NULL )
	|				AND (AgreementPriceGroups.PricesKind IS NULL 
	|					OR AgreementPriceGroups.PricesKind = VALUE(Catalog.TypesOfPrices.EmptyRef))
	|				AND AgreementHeader_.PricesKind <> VALUE(Catalog.TypesOfPrices.EmptyRef)
	|			THEN AgreementHeader_.PricesKind
	|	END AS PriceKind,
	|	ISNULL(&QueryTextPackagingFactor1, 1) * ISNULL(AgreementGoods.Price, 0) / ISNULL(&QueryTextPackagingFactor3, 1) * CASE
	|		WHEN TemporaryTableOfGoods_.Currency <> AgreementHeader_.Currency
	|			THEN CASE
	|					WHEN ISNULL(CutRatesAgreementCurrency.CourseDenominator, 0) > 0
	|							AND ISNULL(CutRatesAgreementCurrency.CourseNumerator, 0) > 0
	|							AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
	|							AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
	|						THEN CutRatesAgreementCurrency.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * CutRatesAgreementCurrency.CourseDenominator)
	|					ELSE 0
	|				END
	|		ELSE 1
	|	END AS Price,
	|	CASE
	|		WHEN ISNULL(AgreementGoods.DeliveryPeriodDays, 0) > 0
	|			THEN AgreementGoods.DeliveryPeriodDays
	|		ELSE CASE
	|				WHEN ISNULL(AgreementPriceGroups.DeliveryPeriodDays, 0) > 0
	|					THEN AgreementPriceGroups.DeliveryPeriodDays
	|				ELSE AgreementHeader_.DeliveryPeriodDays
	|			END
	|	END AS DeliveryPeriodDays
	|INTO TableName
	|FROM
	|	&NameOfTemporaryProductTable AS TemporaryTableOfGoods_
	|		LEFT JOIN Catalog.TermsOfSale.Goods AS AgreementGoods
	|		ON (AgreementGoods.Ref = &Terms)
	|			AND TemporaryTableOfGoods_.Products = AgreementGoods.Products
	|			AND TemporaryTableOfGoods_.Characteristic = AgreementGoods.Characteristic
	|		LEFT JOIN Catalog.TermsOfSale AS AgreementHeader_
	|		ON (AgreementHeader_.Ref = &Terms)
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = TemporaryTableOfGoods_.Products)
	|		LEFT JOIN Catalog.TermsOfSale.PriceGroups AS AgreementPriceGroups
	|		ON (AgreementHeader_.Ref = AgreementPriceGroups.Ref)
	|			AND (CatalogProducts.Ref.PriceGroup = AgreementPriceGroups.PriceGroup)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CrossSectionRatesDocumentCurrency
	|		ON CrossSectionRatesDocumentCurrency.Currency = TemporaryTableOfGoods_.Currency 
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CutRatesAgreementCurrency
	|		ON (CutRatesAgreementCurrency.Currency = AgreementHeader_.Currency)
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date, (Country = &RegistrationCountry
	|					OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
	|					AND Products IN (SELECT T.Products FROM &NameOfTemporaryProductTable AS T)) AS ProductsVATRates
	|	ON TemporaryTableOfGoods_.Products = ProductsVATRates.Products
	|	LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
	|	ON (TRUE)
	|;
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);

	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);

	QueryText = StrReplace(QueryText,
		"&VATRate",
		VATAccountingERP.QueryTextVATRate(
			"&VATTaxation",
			"TemporaryTableOfGoods_.Products",
			"&ReturnReusablePackage"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"AgreementGoods.Package",
			"AgreementGoods.Products"));
		
	Return QueryText
	
EndFunction

// Returns the Query Text of product prices by line number
//
// Parameters:
//  NameOfTemporaryProductTable - String - Name of the input temporary table.
//  ToGetVATRate - Boolean - For backward compatibility. If True, then in addition to calculating the price, it receives the VAT rate
//
// Returns:
//  String - query text.
//
Function QueryTextPrices_2_5(NameOfTemporaryProductTable, ToGetVATRate = False)
	
	QueryText = 
	"SELECT
	| TypesOfPrices.LineNumber AS Priority,
	| TypesOfPrices.PriceKind AS PriceKind
	|INTO TypesOfPrices
	|FROM
	| &TypesOfPrices AS TypesOfPrices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FilterTable.LineNumber AS LineNumber,
	|	FilterTable.Products AS Products,
	|	FilterTable.PricingVariant AS PricingVariant,
	|	FilterTable.PricingBatch AS PricingBatch,
	|	FilterTable.PricingPackage AS PricingPackage,
	|	FilterTable.Package AS Package,
	|	TemporaryTableTypesOfPrices.PriceKind AS PriceKind,
	|	MIN(TemporaryTableTypesOfPrices.Priority) AS Priority
	|INTO FilterTable
	|FROM
	|	&NameOfTemporaryProductTable AS FilterTable
	|		LEFT JOIN TypesOfPrices AS TemporaryTableTypesOfPrices
	|		ON TRUE
	|GROUP BY
	|	FilterTable.LineNumber,
	|	FilterTable.Products,
	|	FilterTable.PricingVariant,
	|	FilterTable.PricingBatch,
	|	FilterTable.PricingPackage,
	|	FilterTable.Package,
	|	TemporaryTableTypesOfPrices.PriceKind
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Prices.Products AS Products,
	|	Prices.PricingVariant AS PricingVariant,
	|	Prices.PricingBatch AS PricingBatch,
	|	Prices.PricingPackage AS PricingPackage,
	|	Prices.Package AS Package,
	|	Prices.PriceKind AS PriceKind,
	|	Prices.Currency AS Currency,
	|	Prices.Price AS Price
	|INTO Prices
	|FROM
	|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY),
	|		(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
	|		(SELECT
	|			T.Products,
	|			T.PricingVariant,
	|			T.PricingBatch,
	|			T.PricingPackage,
	|			T.PriceKind
	|		FROM
	|			FilterTable AS T)) AS Prices
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FilterTable.LineNumber AS LineNumber,
	|	FilterTable.PriceKind AS PriceKind,
	|	FilterTable.Priority
	|	// If the price is not found, then you need to fill in the price type and the empty price. Such filling should have a lower priority of filling
	|		+ CASE WHEN Prices.Products IS NULL THEN &LowPriorityShift ELSE 0 END AS Priority,
	|	ISNULL(Prices.Currency, VALUE(Catalog.Currencies.EmptyRef)) AS Currency,
	|	ISNULL(Prices.Price, 0) AS Price,
	|	FilterTable.Products AS Products,
	|	FilterTable.Package AS GoodsPackaging,
	|	ISNULL(Prices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS PricePackaging
	|INTO AffordablePrices
	|FROM
	|	FilterTable AS FilterTable
	|		LEFT JOIN Prices AS Prices
	|		ON FilterTable.Products = Prices.Products
	|			AND FilterTable.PricingVariant = Prices.PricingVariant
	|			AND FilterTable.PricingBatch = Prices.PricingBatch
	|			AND FilterTable.PricingPackage = Prices.PricingPackage
	|			AND FilterTable.PriceKind = Prices.PriceKind
	|
	|INDEX BY
	|	LineNumber,
	|	Priority
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ExchangeRatesPrices.Currency AS Currency,
	|	ExchangeRatesPrices.CourseNumerator AS CourseNumerator,
	|	ExchangeRatesPrices.CourseDenominator AS CourseDenominator
	|INTO ExchangeRatesPrices
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, 
	|		(BaseCurrency, Currency) IN 
	|		(SELECT
	|			&BaseCurrency AS BaseCurrency,
	|			AffordablePrices.Currency AS Currency
	|		FROM
	|			AffordablePrices AS AffordablePrices)) AS ExchangeRatesPrices
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AffordablePrices.LineNumber AS LineNumber,
	|	MIN(AffordablePrices.Priority) AS Priority
	|INTO TopPriorities
	|FROM
	|	AffordablePrices AS AffordablePrices
	|GROUP BY
	|	AffordablePrices.LineNumber 
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	AffordablePrices.LineNumber AS LineNumber,
	|	&VATRate AS VATRate,
	|	AffordablePrices.PriceKind AS PriceKind,
	|	ISNULL(&QueryTextPackagingFactor1, 1) * AffordablePrices.Price /
	|		ISNULL(&QueryTextPackagingFactor2, 1) * CASE
	|		WHEN &Currency <> AffordablePrices.Currency
	|			THEN CASE
	|				WHEN ISNULL(ExchangeRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(ExchangeRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN ExchangeRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator / (Currency_Rates.CourseNumerator * ExchangeRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END AS Price
	|FROM
	|	AffordablePrices AS AffordablePrices
	|		INNER JOIN TopPriorities AS TopPriorities
	|		ON AffordablePrices.LineNumber = TopPriorities.LineNumber
	|			AND AffordablePrices.Priority = TopPriorities.Priority
	|
	|		LEFT JOIN ExchangeRatesPrices AS ExchangeRatesPrices
	|		ON AffordablePrices.Currency = ExchangeRatesPrices.Currency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS Currency_Rates
	|		ON TRUE";
	
	#Region BackwardCompatibility
	If ToGetVATRate Then
		
		QueryText = QueryText + "
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(
		|				&DATE,
		|				(Country = &RegistrationCountry
		|					OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|					AND Products IN
		|						(SELECT
		|							T.Products
		|						FROM
		|							AffordablePrices AS T)) AS ProductsVATRates
		|		ON (AffordablePrices.Products = ProductsVATRates.Products)
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&DATE, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)";
		
		QueryText = StrReplace(QueryText,
			"&VATRate",
			VATAccountingERP.QueryTextVATRate(
				"&VATTaxation",
				"AffordablePrices.Products",
				"&ReturnReusablePackage"));
	
	Else
		
		QueryText = StrReplace(QueryText, "&VATRate AS VATRate,", "");
	
	EndIf;
	#EndRegion
	
	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);

	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"AffordablePrices.GoodsPackaging",
		"AffordablePrices.Products"));
		
	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"AffordablePrices.PricePackaging",
			"AffordablePrices.Products"));
		
	Return QueryText;
	
EndFunction

// Returns the query text for the temporary table of product prices by row numbers
//
// Parameters:
// 		TableName - String, Undefined - Name string for the temporary price table (to pass on)
// 		NameOfTemporaryProductTable - String - The name string of the temporary product table
// 		PriceViewAsParameter - Boolean - True if the "Price view" should be used as a parameter in the query; False if it should be used as a field in the temporary product table.
//
// Returns:
// 		String - The text of the temporary table query.
//
Function GetQueryTextOfTemporaryPriceTable2_5(TableName, NameOfTemporaryProductTable, PriceViewAsParameter = True)
	
	QueryText =
	"SELECT ALLOWED
	|	TemporaryTableOfGoods_.LineNumber AS LineNumber,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CASE
	|		WHEN
	|			TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		THEN
	|			&QueryTextPackagingFactor1
	|		ELSE
	|			1
	|	END
	|	* ISNULL(ItemPricesCrossSectionOfTheLatest.Price,0)/ISNULL(&QueryTextPackagingFactor2,1)
	|	* CASE
	|		WHEN TemporaryTableOfGoods_.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
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
	|	LEFT JOIN InformationRegister.ItemsPrices25.SliceLast(
	|			ENDOFPERIOD(&Date, DAY), 
	|			(Products, PricingVariant, PricingBatch, PricingPackage, PriceKind) IN
	|				(SELECT
	|					TemporaryTableOfGoods_.Products,
	|					TemporaryTableOfGoods_.PricingVariant,
	|					TemporaryTableOfGoods_.PricingBatch,
	|					TemporaryTableOfGoods_.PricingPackage,
	|					TemporaryTableOfGoods_.PriceKind
	|				FROM
	|					&NameOfTemporaryProductTable AS TemporaryTableOfGoods_)) AS ItemPricesCrossSectionOfTheLatest
	|	ON TemporaryTableOfGoods_.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND TemporaryTableOfGoods_.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND TemporaryTableOfGoods_.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND TemporaryTableOfGoods_.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND TemporaryTableOfGoods_.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS CurrencyRatesPrices
	|	ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|	
	|	LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS Currency_Rates
	|	ON Currency_Rates.Currency = TemporaryTableOfGoods_.Currency
	|";
	
	QueryText = StrReplace(QueryText, "INTO TableName", ?(ValueIsFilled(TableName),"INTO " + TableName, ""));

	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);

	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
			
	QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
			
	Return QueryText;
	
EndFunction

// Returns the query text for the temporary product table
// 
// Parameters:
//  ProductTableName_ - String - The name of the product table. If it is not filled in, then it will be passed to the request as a parameter
//  TableName - String - Name string for the temporary table.
//  ColumnsNames - See ColumnNamesOfTemporaryProductTable
// 
// Returns:
//  String --- The text of the temporary table query.
Function GetQueryTextForTemporaryProductTable2_5(ProductTableName_, TableName, ColumnsNames)
	
	QueryText = "
	|SELECT DISTINCT
	|	&NameLineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	&NameSeries AS Series,
	|	&NamePackaging AS Package,
	|	&PriceKind AS PriceKind,
	|	&Currency AS Currency
	|INTO TTTableProductsSubG
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	ISNULL(CASE
	|		WHEN TableOfProductTypes.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				OR GoodsTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
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
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Currency AS Currency
	|INTO TableName
	|FROM
	|	TTTableProductsSubG AS GoodsTable
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
	|	Catalog.PackagesAndUnitsOfMeasure AS PackingTableEI
	|ON
	|	GoodsTable.Package = PackingTableEI.Ref
	|;
	|";
	
	If Not IsBlankString(ProductTableName_) Then
		QueryText = StrReplace(QueryText, "&Table", ProductTableName_);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNameRowNumber) Then
		QueryText = StrReplace(QueryText, "&NameLineNumber", "0");
	Else
		QueryText = StrReplace(QueryText, "&NameLineNumber", "Table." + ColumnsNames.ColumnNameRowNumber);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNameSeries) Then
		QueryText = StrReplace(QueryText, "&NameSeries", "VALUE(Catalog.ItemsBatches.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NameSeries", "Table." + ColumnsNames.ColumnNameSeries);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNamePackaging) Then
		QueryText = StrReplace(QueryText, "&NamePackaging", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NamePackaging", "Table." + ColumnsNames.ColumnNamePackaging);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNamePriceType) Then
		QueryText = StrReplace(QueryText, "&PriceKind", "Table." + ColumnsNames.ColumnNamePriceType);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNameCurrency) Then
		QueryText = StrReplace(QueryText, "&Currency", "Table." + ColumnsNames.ColumnNameCurrency);
	EndIf;
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);
	
	Return QueryText;
	
EndFunction

Function TypesOfPartnerPrices(Partner)

	TypesOfPrices = New ValueTable();
	TypesOfPrices.Columns.Add("PriceKind", New TypeDescription("CatalogRef.TypesOfPrices"));

	PartnerDetails_ = Common.ObjectAttributesValues(Partner, "SpecialPriceType, PricesKind");
	If ValueIsFilled(PartnerDetails_.SpecialPriceType) Then
		NewRow = TypesOfPrices.Add();
		NewRow.PriceKind = PartnerDetails_.SpecialPriceType;
	EndIf;
	If ValueIsFilled(PartnerDetails_.PricesKind) Then
		NewRow = TypesOfPrices.Add();
		NewRow.PriceKind = PartnerDetails_.PricesKind;
	EndIf;
	TMCommonUse.NumberValueTable(TypesOfPrices, "LineNumber");

	Return TypesOfPrices;

EndFunction

Function AvailabilityOfTableColumns(Table, ColumnsNames)
	
	If TypeOf(Table) = Type("ValueTable") Then
		TableColumns1 = Table.Columns;
	Else
		TableColumns1 = Table.Unload(New Array).Columns;
	EndIf; 
	
	AvailabilityOfColumns = New Structure(ColumnsNames);
	FillPropertyValues(AvailabilityOfColumns, TableColumns1);
	
	For Each KeyAndValue In AvailabilityOfColumns Do
		AvailabilityOfColumns[KeyAndValue.Key] = KeyAndValue.Value <> Undefined;
	EndDo;
	
	Return AvailabilityOfColumns;
	
EndFunction

#Region BatchProcessingOfTablePartsIsService

// Returns the query texts of the temporary product price table by row IDs
//
// Parameters:
// 	NameOfPriceTable - String, Undefined - Name of the resulting price table
// 	NameOfTemporaryProductTable - String - Name Of The Temporary Product Table
//
// Returns:
// 	ValueList of String - Temporary table query texts.
//
Function QueryTextsOfTempTableOfPricesBatchProcessing(NameOfPriceTable, NameOfTemporaryProductTable)
	
	Result = New ValueList();
	
	QueryText =
	"SELECT
	|	Price_Table.Products AS Products,
	|	Price_Table.Characteristic AS Characteristic,
	|	Price_Table.PriceKind AS PriceKind,
	|	Price_Table.Price AS Price,
	|	Price_Table.Package AS Package,
	|	Price_Table.Currency AS Currency
	|INTO FillingInPrices_PricesAreSliceOfLatest
	|FROM
	|	InformationRegister.ItemsPrices.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, Characteristic, PriceKind) IN
	|		(SELECT
	|			TemporaryTableOfGoods_.Products,
	|			TemporaryTableOfGoods_.Characteristic,
	|			TemporaryTableOfGoods_.PriceKind
	|		FROM
	|			&NameOfTemporaryProductTable AS TemporaryTableOfGoods_)) AS Price_Table
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	PriceKind";
	
	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);
	
	Result.Add(QueryText, "FillingInPrices_PricesAreSliceOfLatest");
	
	QueryText =
	"SELECT
	|	RateTable.Currency AS Currency,
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO FillingInPrices_ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RateTable
	|
	|INDEX BY
	|	Currency";
	
	Result.Add(QueryText, "FillingInPrices_ExchangeRates");
	
	QueryText =
	"SELECT ALLOWED
	|	TemporaryTableOfGoods_.IdOfTTRow AS IdOfTTRow,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CAST((CASE
	|		WHEN TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		ELSE 1
	|	END * ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor2, 1) * CASE
	|		WHEN TemporaryTableOfGoods_.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator) / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END) AS NUMBER(31, 2)) AS Price
	|FROM
	|	&NameOfTemporaryProductTable AS TemporaryTableOfGoods_
	|		LEFT JOIN FillingInPrices_PricesAreSliceOfLatest AS ItemPricesCrossSectionOfTheLatest
	|		ON TemporaryTableOfGoods_.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND TemporaryTableOfGoods_.Characteristic = ItemPricesCrossSectionOfTheLatest.Characteristic
	|		AND TemporaryTableOfGoods_.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN FillingInPrices_ExchangeRates AS CurrencyRatesPrices
	|		ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|		LEFT JOIN FillingInPrices_ExchangeRates AS Currency_Rates
	|		ON Currency_Rates.Currency = TemporaryTableOfGoods_.Currency";
	
	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, NameOfPriceTable);
		
	Return Result;
	
EndFunction

// Returns the query texts of the temporary product table
//
// Parameters:
// 	ProductTableName_ - String - Name of the product table.
// 	TableName - String - Name string for the temporary table.
// 	ColumnsNames - See ColumnNamesOfTemporaryProductTable
//
// Returns:
// 	ValueList of String - Temporary table query texts.
//
Function QueryTextsOfTempTableOfGoodsBatchProcessing(ProductTableName_, TableName, ColumnsNames)
	
	Result = New ValueList();
	
	QueryText =
	"SELECT DISTINCT
	|	&NameLineNumber AS IdOfTTRow,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	ISNULL(PackingTable_.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	&PriceKind AS PriceKind,
	|	&Currency AS Currency
	|INTO TableName
	|FROM
	|	&Table AS Table
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|		ON &NamePackaging = PackingTable_.Ref";
	
	QueryText = StrReplace(QueryText, "&Table", ProductTableName_);
	
	If IsBlankString(ColumnsNames.ColumnNameRowNumber) Then
		QueryText = StrReplace(QueryText, "&NameLineNumber", "0");
	Else
		QueryText = StrReplace(QueryText, "&NameLineNumber", "Table." + ColumnsNames.ColumnNameRowNumber);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNamePackaging) Then
		QueryText = StrReplace(QueryText, "&NamePackaging", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NamePackaging", "Table." + ColumnsNames.ColumnNamePackaging);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNamePriceType) Then
		QueryText = StrReplace(QueryText, "&PriceKind", "Table." + ColumnsNames.ColumnNamePriceType);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNameCurrency) Then
		QueryText = StrReplace(QueryText, "&Currency", "Table." + ColumnsNames.ColumnNameCurrency);
	EndIf;
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);
	
	Result.Add(QueryText, TableName);
	
	Return Result;
	
EndFunction

// Returns the query texts of the temporary product price table by row IDs
//
// Parameters:
// 	NameOfPriceTable - String, Undefined - Name of the resulting price table
// 	NameOfTemporaryProductTable - String - Name Of The Temporary Product Table
//
// Returns:
// 	ValueList of String - Temporary table query texts.
//
Function QueryTextsOfTempTableOfPrices2_5BatchProcessing(NameOfPriceTable, NameOfTemporaryProductTable)
	
	Result = New ValueList();
	
	QueryText =
	"SELECT
	|	Price_Table.Products AS Products,
	|	Price_Table.PricingVariant AS PricingVariant,
	|	Price_Table.PricingBatch AS PricingBatch,
	|	Price_Table.PricingPackage AS PricingPackage,
	|	Price_Table.PriceKind AS PriceKind,
	|	Price_Table.Price AS Price,
	|	Price_Table.Package AS Package,
	|	Price_Table.Currency AS Currency
	|INTO FillingInPrices25_PricesSliceOfLatest
	|FROM
	|	InformationRegister.ItemsPrices25.SliceLast(ENDOFPERIOD(&Date, DAY), (Products, PricingVariant, PricingBatch,
	|		PricingPackage, PriceKind) IN
	|		(SELECT
	|			TemporaryTableOfGoods_.Products,
	|			TemporaryTableOfGoods_.PricingVariant,
	|			TemporaryTableOfGoods_.PricingBatch,
	|			TemporaryTableOfGoods_.PricingPackage,
	|			TemporaryTableOfGoods_.PriceKind
	|		FROM
	|			&NameOfTemporaryProductTable AS TemporaryTableOfGoods_)) AS Price_Table
	|
	|INDEX BY
	|	Products,
	|	PricingVariant,
	|	PricingBatch,
	|	PricingPackage,
	|	PriceKind";
	
	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);
	
	Result.Add(QueryText, "FillingInPrices25_PricesSliceOfLatest");
	
	QueryText =
	"SELECT
	|	RateTable.Currency AS Currency,
	|	RateTable.CourseNumerator AS CourseNumerator,
	|	RateTable.CourseDenominator AS CourseDenominator
	|INTO FillingInPrices25_ExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS RateTable
	|
	|INDEX BY
	|	Currency";
	
	Result.Add(QueryText, "FillingInPrices25_ExchangeRates");
	
	QueryText =
	"SELECT ALLOWED
	|	TemporaryTableOfGoods_.IdOfTTRow AS IdOfTTRow,
	|	TemporaryTableOfGoods_.PriceKind AS PriceKind,
	|	CAST((CASE
	|		WHEN TemporaryTableOfGoods_.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN &QueryTextPackagingFactor1
	|		ELSE 1
	|	END * ISNULL(ItemPricesCrossSectionOfTheLatest.Price, 0) / ISNULL(&QueryTextPackagingFactor2, 1) * CASE
	|		WHEN TemporaryTableOfGoods_.Currency <> ItemPricesCrossSectionOfTheLatest.Currency
	|			THEN CASE
	|				WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|				AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|				AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|					THEN (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator) / (Currency_Rates.CourseNumerator *
	|						CurrencyRatesPrices.CourseDenominator)
	|				ELSE 0
	|			END
	|		ELSE 1
	|	END) AS NUMBER(31, 2)) AS Price
	|FROM
	|	&NameOfTemporaryProductTable AS TemporaryTableOfGoods_
	|		LEFT JOIN FillingInPrices25_PricesSliceOfLatest AS ItemPricesCrossSectionOfTheLatest
	|		ON TemporaryTableOfGoods_.Products = ItemPricesCrossSectionOfTheLatest.Products
	|		AND TemporaryTableOfGoods_.PricingVariant = ItemPricesCrossSectionOfTheLatest.PricingVariant
	|		AND TemporaryTableOfGoods_.PricingBatch = ItemPricesCrossSectionOfTheLatest.PricingBatch
	|		AND TemporaryTableOfGoods_.PricingPackage = ItemPricesCrossSectionOfTheLatest.PricingPackage
	|		AND TemporaryTableOfGoods_.PriceKind = ItemPricesCrossSectionOfTheLatest.PriceKind
	|		LEFT JOIN FillingInPrices25_ExchangeRates AS CurrencyRatesPrices
	|		ON ItemPricesCrossSectionOfTheLatest.Currency = CurrencyRatesPrices.Currency
	|		LEFT JOIN FillingInPrices25_ExchangeRates AS Currency_Rates
	|		ON Currency_Rates.Currency = TemporaryTableOfGoods_.Currency";
	
	QueryText = StrReplace(QueryText, "&NameOfTemporaryProductTable", NameOfTemporaryProductTable);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TemporaryTableOfGoods_.Package",
			"TemporaryTableOfGoods_.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	Result.Add(QueryText, NameOfPriceTable);
	
	Return Result;
	
EndFunction

// Returns the query texts of the temporary product table
//
// Parameters:
// 	ProductTableName_ - String - Name of the product table.
// 	TableName - String - Name string for the temporary table.
// 	ColumnsNames - See ColumnNamesOfTemporaryProductTable
//
// Returns:
// 	ValueList of String - Temporary table query texts.
//
Function QueryTextsOfTempTableOfGoods2_5BatchProcessing(ProductTableName_, TableName, ColumnsNames)
	
	Result = New ValueList();
	
	QueryText =
	"SELECT DISTINCT
	|	&NameLineNumber AS IdOfTTRow,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	&NameSeries AS Series,
	|	ISNULL(PackingTable_.Ref, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS Package,
	|	&PriceKind AS PriceKind,
	|	&Currency AS Currency
	|INTO TTTableProductsSubG
	|FROM
	|	&Table AS Table
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|		ON &NamePackaging = PackingTable_.Ref";
	
	QueryText = StrReplace(QueryText, "&Table", ProductTableName_);
	
	If IsBlankString(ColumnsNames.ColumnNameRowNumber) Then
		QueryText = StrReplace(QueryText, "&NameLineNumber", "0");
	Else
		QueryText = StrReplace(QueryText, "&NameLineNumber", "Table." + ColumnsNames.ColumnNameRowNumber);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNameSeries) Then
		QueryText = StrReplace(QueryText, "&NameSeries", "VALUE(Catalog.ItemsBatches.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NameSeries", "Table." + ColumnsNames.ColumnNameSeries);
	EndIf;
	
	If IsBlankString(ColumnsNames.ColumnNamePackaging) Then
		QueryText = StrReplace(QueryText, "&NamePackaging", "VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	Else
		QueryText = StrReplace(QueryText, "&NamePackaging", "Table." + ColumnsNames.ColumnNamePackaging);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNamePriceType) Then
		QueryText = StrReplace(QueryText, "&PriceKind", "Table." + ColumnsNames.ColumnNamePriceType);
	EndIf;
	
	If Not IsBlankString(ColumnsNames.ColumnNameCurrency) Then
		QueryText = StrReplace(QueryText, "&Currency", "Table." + ColumnsNames.ColumnNameCurrency);
	EndIf;
	
	Result.Add(QueryText, "TTTableProductsSubG");
	
	QueryText =
	"SELECT
	|	GoodsTable.IdOfTTRow AS IdOfTTRow,
	|	GoodsTable.Products AS Products,
	|	CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|				OR GoodsTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE GoodsTable.Characteristic.ItemsCharacteristicForPricing
	|	END AS PricingVariant,
	|	ISNULL(CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE GoodsTable.Series.ItemsBatchForPricing
	|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE GoodsTable.Package
	|	END AS PricingPackage,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Currency AS Currency
	|INTO TableName
	|FROM
	|	TTTableProductsSubG AS GoodsTable
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON ItemKinds.Ref = GoodsTable.Products.ProductKind";
	
	QueryText = StrReplace(QueryText, "INTO TableName", "INTO " + TableName);
	
	Result.Add(QueryText, TableName);
	
	Return Result;
	
EndFunction

// Get the texts of requests to get prices to insert into other requests.
//
// Parameters:
// 	NameOfTemporaryProductTable - String - The name of the temporary table of goods of the higher-level request (the table of goods at the entrance).
// 	NameOfPriceTable - String - Name of the resulting price table.
// 	ColumnsNames - See ColumnNamesOfTemporaryProductTable.
// 	RequestDate_ - Undefined, Date - The date of the request, to get information about which pricing option to apply.
//
// Returns:
// 	ValueList of String - texts of requests to get prices to insert.
// 
Function QueryTextsForFillingInPricesBatchProcessing(NameOfTemporaryProductTable,
	NameOfPriceTable = Undefined,
	ColumnsNames = Undefined,
	RequestDate_ = Undefined) Export
	
	If ColumnsNames = Undefined Then
		ColumnsNames = ColumnNamesOfTemporaryProductTable();
	EndIf;
	
	Result = New ValueList();
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(RequestDate_);
	If UsePriceManagementSystem25 Then
		
		CommonClientServer.SupplementList(Result,
			QueryTextsOfTempTableOfGoods2_5BatchProcessing(NameOfTemporaryProductTable,
				"TTTableProductsForCommunication",
				ColumnsNames));
		
		CommonClientServer.SupplementList(Result,
			QueryTextsOfTempTableOfPrices2_5BatchProcessing(NameOfPriceTable,
				"TTTableProductsForCommunication"));
		
	Else
		
		CommonClientServer.SupplementList(Result,
			QueryTextsOfTempTableOfGoodsBatchProcessing(NameOfTemporaryProductTable,
				"TTTableProductsForCommunication",
				ColumnsNames));
		
		CommonClientServer.SupplementList(Result,
			QueryTextsOfTempTableOfPricesBatchProcessing(NameOfPriceTable,
				"TTTableProductsForCommunication"));
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
