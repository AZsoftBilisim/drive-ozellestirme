#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Records VAT rates for the entire item. Used in a long-term "Workplace" operation
//
// Parameters:
//  Schema - DataCompositionSchema
//  Settings - DataCompositionSettings
//  Parameters - Structure - additional parameters for recording
//
Procedure SetVATRateOfProductItemForCurSelection(Schema, Settings, Parameters) Export
	
	DataCompositionClientServer.AddFilter(Settings, "IsFolder", False);
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(Schema, Settings, , ,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Query = New Query;
	Query.Text = CompositionTemplate.DataSets.DynamicListDataSet.Query;	
	For Each ParameterValue In CompositionTemplate.ParameterValues Do
		Query.SetParameter(ParameterValue.Name,ParameterValue.Value);
	EndDo;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AddRegisterEntry(Selection, Parameters);
	EndDo;
	
EndProcedure

// Records the VAT rates for the item list. Used in a long-term "Workplace" operation
//
// Parameters:
//  ItemList - ValueList - List of nomenclature
//  Parameters - Structure - additional parameters for recording
//
Procedure SetProductSVATRateBasedOnSelectedLines(ItemList, Parameters) Export
	
	ValueTable = New ValueTable();
	ValueTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	
	For Each String In ItemList Do
		If String.Value.IsFolder Then
			ProcessProductGroup(ValueTable, String.Value);
		Else
			NewRow = ValueTable.Add();
			NewRow.Products = String.Value;
		EndIf;
	EndDo;
	
	For Each String In ValueTable Do
		AddRegisterEntry(String, Parameters);
	EndDo;
	
EndProcedure

// Records the current VAT rate for the nomenclature for the main country in the RS.StavkiNDSNomenclature.
//
// Parameters:
//  Products - CatalogRef.Products
//  VATRate - CatalogRef.VATRates
//  RecordingNew - Boolean
//  Date - Date - Optional, if not specified, then an entry occurs on the date 01.01.1980
//
Procedure SetCurrentVATRateOfProductForMainCountry(Products, VATRate, RecordingNew, Date = '00010101') Export
	
	MainCountry = SettingsValueClientServerCached.MainCountry();
	
	If ValueIsFilled(Date) Then
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	ProductsVATRates.Period AS Period,
			|	ProductsVATRates.Products AS Products,
			|	ProductsVATRates.Country AS Country
			|FROM
			|	InformationRegister.ProductsVATRates AS ProductsVATRates
			|WHERE
			|	ProductsVATRates.Products = &Products
			|	AND ProductsVATRates.Country = &Country
			|	AND ProductsVATRates.Period > &Period";
		
		Query.SetParameter("Country", MainCountry);
		Query.SetParameter("Products", Products);
		Query.SetParameter("Period", Date);
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			
			While Selection.Next() Do
				RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
				RecordSet.Filter.Period.Set(Selection.Period);
				RecordSet.Filter.Products.Set(Selection.Products);
				RecordSet.Filter.Country.Set(MainCountry);
				
				RecordSet.Write();
			EndDo;
			
		EndIf;
		
	EndIf;
	
	If RecordingNew Then
		Date = Date("19800101");
	EndIf;
	
	RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(BegOfMonth(Date));
	RecordSet.Filter.Products.Set(Products);
	RecordSet.Filter.Country.Set(MainCountry);

	NewRecord = RecordSet.Add();
	NewRecord.Period = BegOfMonth(Date);
	NewRecord.Products = Products;
	NewRecord.Country = MainCountry;
	NewRecord.VATRate = VATRate;
	
	RecordSet.AdditionalProperties.Insert("SkipUpdatingProductSVATRate");
	RecordSet.Write();
	
EndProcedure

// Gets the current VAT rate for the nomenclature for the main country from the RS.StavkiNDSNomenclature.
//
// Parameters:
//  Products - CatalogRef.Products
//
// Returns:
//  CatalogRef.VATRates
//
Function CurrentVATRateOfProductByMainCountry(Products) Export
	
	VATRate = Catalogs.VATRates.EmptyRef();
	MainCountry = SettingsValueClientServerCached.MainCountry();
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	ProductsVATRatesSliceLast.VATRate AS VATRate
		|FROM
		|	InformationRegister.ProductsVATRates.SliceLast(
		|			,
		|			(Country = &Country
		|				OR Country = VALUE(Catalog.WorldCountries.EmptyRef))
		|				AND Products = &Products) AS ProductsVATRatesSliceLast";
	
	Query.SetParameter("Country", MainCountry);
	Query.SetParameter("Products", Products);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		VATRate = Selection.VATRate;
	EndIf;
	
	Return VATRate;
	
EndFunction

// Gets a table of VAT rates for the item.
//
// Parameters:
//  Products - CatalogRef.Products - 
//  SelectionByCountry - CatalogRef.WorldCountries - If without selection, then it is uncertain
//  FilterByPeriod - Date - If without selection, then it is uncertain
//
// Returns:
//  ValueTable - contains columns:
//  	* Period - Date -
//  	* Country - CatalogRef.WorldCountries -
//  	* VATRate - CatalogRef.VATRates -
//  	* BasicRate - CatalogRef.VATRates -
Function TableOfProductVATRates(Products, SelectionByCountry = Undefined, FilterByPeriod = Undefined)  Export
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	ProductsVATRates.Period AS Period,
	|	ProductsVATRates.Country AS Country,
	|	ProductsVATRates.VATRate AS VATRate,
	|	CASE
	|		WHEN ProductsVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 1, 1)
	|		ELSE ProductsVATRates.VATRate.EndOfPeriod
	|	END AS VATRateIsValidUntil,
	|	CASE
	|		WHEN ProductsVATRates.Country = VALUE(Catalog.WorldCountries.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS InitialFilling
	|INTO ProductsVATRates
	|FROM
	|	InformationRegister.ProductsVATRates AS ProductsVATRates
	|WHERE
	|	ProductsVATRates.Products = &Products
	|	AND (&FilterByCountry1
	|			OR ProductsVATRates.Country = VALUE(Catalog.WorldCountries.EmptyRef))
	|
	|INDEX BY
	|	Period,
	|	Country,
	|	InitialFilling
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductsVATRates.Country AS Country
	|INTO CountriesOfProductVATRates
	|FROM
	|	ProductsVATRates AS ProductsVATRates
	|WHERE
	|	NOT ProductsVATRates.InitialFilling
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsVATRates.Period AS Period,
	|	CountriesOfProductVATRates.Country AS Country,
	|	ProductsVATRates.VATRate AS VATRate,
	|	ProductsVATRates.VATRateIsValidUntil AS VATRateIsValidUntil
	|INTO VATRatesOfProductsByCountry
	|FROM
	|	ProductsVATRates AS ProductsVATRates
	|		LEFT JOIN CountriesOfProductVATRates AS CountriesOfProductVATRates
	|		ON (TRUE)
	|WHERE
	|	ProductsVATRates.InitialFilling
	|	AND NOT CountriesOfProductVATRates.Country IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	ProductsVATRates.Period,
	|	ProductsVATRates.Country,
	|	ProductsVATRates.VATRate,
	|	ProductsVATRates.VATRateIsValidUntil
	|FROM
	|	ProductsVATRates AS ProductsVATRates
	|WHERE
	|	NOT ProductsVATRates.InitialFilling
	|
	|INDEX BY
	|	Period,
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesOfProductsByCountry.Period AS Begin,
	|	DATEADD(CASE
	|			WHEN VATRatesOfProductsByCountry.VATRateIsValidUntil > MIN(ISNULL(VATRatesOfProductsByCountry1.Period, VATRatesOfProductsByCountry.VATRateIsValidUntil))
	|				THEN MIN(ISNULL(VATRatesOfProductsByCountry1.Period, VATRatesOfProductsByCountry.VATRateIsValidUntil))
	|			ELSE VATRatesOfProductsByCountry.VATRateIsValidUntil
	|		END, DAY, 1) AS Ending,
	|	VATRatesOfProductsByCountry.Country AS Country,
	|	VATRatesOfProductsByCountry.VATRate AS VATRate
	|INTO VATRatesForProductsByPeriod
	|FROM
	|	VATRatesOfProductsByCountry AS VATRatesOfProductsByCountry
	|		LEFT JOIN VATRatesOfProductsByCountry AS VATRatesOfProductsByCountry1
	|		ON VATRatesOfProductsByCountry.Period < VATRatesOfProductsByCountry1.Period
	|			AND VATRatesOfProductsByCountry.Country = VATRatesOfProductsByCountry1.Country
	|
	|GROUP BY
	|	VATRatesOfProductsByCountry.Period,
	|	VATRatesOfProductsByCountry.Country,
	|	VATRatesOfProductsByCountry.VATRate,
	|	VATRatesOfProductsByCountry.VATRateIsValidUntil
	|
	|INDEX BY
	|	Country,
	|	Begin
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesForProductsByPeriod.Country AS Country,
	|	MAX(VATRatesForProductsByPeriod.Ending) AS Ending
	|INTO VATRatesForProductsMaxDate
	|FROM
	|	VATRatesForProductsByPeriod AS VATRatesForProductsByPeriod
	|
	|GROUP BY
	|	VATRatesForProductsByPeriod.Country
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesForProductsByPeriod.Country AS Country,
	|	MIN(VATRatesForProductsByPeriod.Begin) AS Begin
	|INTO VATRatesOfProductItemsMinDate
	|FROM
	|	VATRatesForProductsByPeriod AS VATRatesForProductsByPeriod
	|
	|GROUP BY
	|	VATRatesForProductsByPeriod.Country
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRates.Period AS Period,
	|	BasicVATRates.Country AS Country,
	|	BasicVATRates.VATRate AS VATRate,
	|	CASE
	|		WHEN BasicVATRates.VATRate.EndOfPeriod = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 1, 1)
	|		ELSE BasicVATRates.VATRate.EndOfPeriod
	|	END AS VATRateIsValidUntil
	|INTO BasicVATRates
	|FROM
	|	InformationRegister.BasicVATRates AS BasicVATRates
	|WHERE
	|	&FilterByCountry2
	|
	|INDEX BY
	|	Period,
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRates.Period AS Begin,
	|	DATEADD(CASE
	|			WHEN BasicVATRates.VATRateIsValidUntil > MIN(ISNULL(BasicVATRates1.Period, BasicVATRates.VATRateIsValidUntil))
	|				THEN MIN(ISNULL(BasicVATRates1.Period, BasicVATRates.VATRateIsValidUntil))
	|			ELSE BasicVATRates.VATRateIsValidUntil
	|		END, DAY, 1) AS Ending,
	|	BasicVATRates.Country AS Country,
	|	BasicVATRates.VATRate AS VATRate
	|INTO BasicVATRatesByPeriod
	|FROM
	|	BasicVATRates AS BasicVATRates
	|		LEFT JOIN BasicVATRates AS BasicVATRates1
	|		ON BasicVATRates.Country = BasicVATRates1.Country
	|			AND BasicVATRates.Period < BasicVATRates1.Period
	|
	|GROUP BY
	|	BasicVATRates.Period,
	|	BasicVATRates.Country,
	|	BasicVATRates.VATRate,
	|	BasicVATRates.VATRateIsValidUntil
	|
	|INDEX BY
	|	Country,
	|	Begin,
	|	Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRatesByPeriod.Country AS Country,
	|	MAX(BasicVATRatesByPeriod.Ending) AS Ending
	|INTO BasicVATRatesMaxDate
	|FROM
	|	BasicVATRatesByPeriod AS BasicVATRatesByPeriod
	|
	|GROUP BY
	|	BasicVATRatesByPeriod.Country
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRatesByPeriod.Country AS Country,
	|	MIN(BasicVATRatesByPeriod.Begin) AS Begin
	|INTO BasicVATRatesMinDate
	|FROM
	|	BasicVATRatesByPeriod AS BasicVATRatesByPeriod
	|
	|GROUP BY
	|	BasicVATRatesByPeriod.Country
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesForProductsByPeriod.Country AS Country,
	|	MAX(ISNULL(VATRatesForProductsByPeriod1.Ending, VATRatesForProductsByPeriod.Begin)) AS EmptyIntervalStart,
	|	VATRatesForProductsByPeriod.Begin AS EmptyIntervalEnd
	|INTO EmptyIntervalsPreliminary
	|FROM
	|	VATRatesForProductsByPeriod AS VATRatesForProductsByPeriod
	|		LEFT JOIN VATRatesForProductsByPeriod AS VATRatesForProductsByPeriod1
	|		ON VATRatesForProductsByPeriod.Country = VATRatesForProductsByPeriod1.Country
	|			AND VATRatesForProductsByPeriod.Begin > VATRatesForProductsByPeriod1.Begin
	|
	|GROUP BY
	|	VATRatesForProductsByPeriod.Country,
	|	VATRatesForProductsByPeriod.Begin
	|
	|UNION ALL
	|
	|SELECT
	|	BasicVATRatesMinDate.Country,
	|	BasicVATRatesMinDate.Begin,
	|	VATRatesOfProductItemsMinDate.Begin
	|FROM
	|	VATRatesOfProductItemsMinDate AS VATRatesOfProductItemsMinDate
	|		INNER JOIN BasicVATRatesMinDate AS BasicVATRatesMinDate
	|		ON VATRatesOfProductItemsMinDate.Country = BasicVATRatesMinDate.Country
	|WHERE
	|	BasicVATRatesMinDate.Begin < VATRatesOfProductItemsMinDate.Begin
	|
	|UNION ALL
	|
	|SELECT
	|	VATRatesForProductsMaxDate.Country,
	|	VATRatesForProductsMaxDate.Ending,
	|	BasicVATRatesMaxDate.Ending
	|FROM
	|	VATRatesForProductsMaxDate AS VATRatesForProductsMaxDate
	|		INNER JOIN BasicVATRatesMaxDate AS BasicVATRatesMaxDate
	|		ON VATRatesForProductsMaxDate.Country = BasicVATRatesMaxDate.Country
	|WHERE
	|	VATRatesForProductsMaxDate.Ending < BasicVATRatesMaxDate.Ending
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmptyIntervalsPreliminary.Country AS Country,
	|	EmptyIntervalsPreliminary.EmptyIntervalStart AS EmptyIntervalStart,
	|	EmptyIntervalsPreliminary.EmptyIntervalEnd AS EmptyIntervalEnd
	|INTO EmptyIntervals
	|FROM
	|	EmptyIntervalsPreliminary AS EmptyIntervalsPreliminary
	|WHERE
	|	EmptyIntervalsPreliminary.EmptyIntervalEnd > EmptyIntervalsPreliminary.EmptyIntervalStart
	|
	|INDEX BY
	|	Country,
	|	EmptyIntervalStart,
	|	EmptyIntervalEnd
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasicVATRates.Country AS Country
	|INTO AdditionalCountries
	|FROM
	|	BasicVATRates AS BasicVATRates
	|WHERE
	|	NOT BasicVATRates.Country IN
	|				(SELECT
	|					T.Country
	|				FROM
	|					CountriesOfProductVATRates AS T)
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductsVATRates.Period AS Begin,
	|	AdditionalCountries.Country AS Country,
	|	ProductsVATRates.VATRate AS VATRate,
	|	CASE
	|		WHEN ProductsVATRates.VATRateIsValidUntil > BasicVATRatesSliceFirst.Period
	|			THEN BasicVATRatesSliceFirst.Period
	|		ELSE ProductsVATRates.VATRateIsValidUntil
	|	END AS Ending,
	|	FALSE AS BasicRate
	|INTO BasicVATRatesSupplement
	|FROM
	|	ProductsVATRates AS ProductsVATRates
	|		LEFT JOIN AdditionalCountries AS AdditionalCountries
	|			LEFT JOIN InformationRegister.BasicVATRates.SliceFirst AS BasicVATRatesSliceFirst
	|			ON AdditionalCountries.Country = BasicVATRatesSliceFirst.Country
	|		ON (TRUE)
	|WHERE
	|	ProductsVATRates.InitialFilling
	|	AND NOT AdditionalCountries.Country IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	BasicVATRatesByPeriod.Begin,
	|	BasicVATRatesByPeriod.Country,
	|	BasicVATRatesByPeriod.VATRate,
	|	BasicVATRatesByPeriod.Ending,
	|	TRUE
	|FROM
	|	BasicVATRatesByPeriod AS BasicVATRatesByPeriod
	|WHERE
	|	BasicVATRatesByPeriod.Country IN
	|			(SELECT
	|				T.Country
	|			FROM
	|				AdditionalCountries AS T)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmptyIntervals.Country AS Country,
	|	CASE
	|		WHEN EmptyIntervals.EmptyIntervalStart > BasicVATRatesByPeriod.Begin
	|			THEN EmptyIntervals.EmptyIntervalStart
	|		ELSE BasicVATRatesByPeriod.Begin
	|	END AS Begin,
	|	BasicVATRatesByPeriod.Ending AS Ending,
	|	BasicVATRatesByPeriod.VATRate AS VATRate
	|INTO BasicNDSKRatesForEmptyPeriods
	|FROM
	|	EmptyIntervals AS EmptyIntervals
	|		LEFT JOIN BasicVATRatesByPeriod AS BasicVATRatesByPeriod
	|		ON EmptyIntervals.EmptyIntervalStart < BasicVATRatesByPeriod.Ending
	|			AND EmptyIntervals.EmptyIntervalEnd >= BasicVATRatesByPeriod.Begin
	|			AND EmptyIntervals.Country = BasicVATRatesByPeriod.Country
	|WHERE
	|	EmptyIntervals.EmptyIntervalStart <> EmptyIntervals.EmptyIntervalEnd
	|	AND NOT BasicVATRatesByPeriod.VATRate IS NULL
	|
	|INDEX BY
	|	Country
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATRatesForProductsByPeriod.Country AS Country,
	|	VATRatesForProductsByPeriod.Begin AS Period,
	|	VATRatesForProductsByPeriod.Ending AS Ending,
	|	VATRatesForProductsByPeriod.VATRate AS VATRate,
	|	FALSE AS BasicRate
	|INTO TT_Preliminary
	|FROM
	|	VATRatesForProductsByPeriod AS VATRatesForProductsByPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	BasicVATRatesSupplement.Country,
	|	BasicVATRatesSupplement.Begin,
	|	BasicVATRatesSupplement.Ending,
	|	BasicVATRatesSupplement.VATRate,
	|	BasicVATRatesSupplement.BasicRate
	|FROM
	|	BasicVATRatesSupplement AS BasicVATRatesSupplement
	|
	|UNION ALL
	|
	|SELECT
	|	BasicNDSKRatesForEmptyPeriods.Country,
	|	BasicNDSKRatesForEmptyPeriods.Begin,
	|	BasicNDSKRatesForEmptyPeriods.Ending,
	|	BasicNDSKRatesForEmptyPeriods.VATRate,
	|	TRUE
	|FROM
	|	BasicNDSKRatesForEmptyPeriods AS BasicNDSKRatesForEmptyPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Preliminary.Country AS Country,
	|	MAX(ISNULL(TT_Preliminary1.Ending, TT_Preliminary.Period)) AS Period,
	|	TT_Preliminary.Period AS Ending
	|INTO PeriodsOfEmptyRates
	|FROM
	|	TT_Preliminary AS TT_Preliminary
	|		LEFT JOIN TT_Preliminary AS TT_Preliminary1
	|		ON TT_Preliminary.Country = TT_Preliminary1.Country
	|			AND TT_Preliminary.Period > TT_Preliminary1.Period
	|
	|GROUP BY
	|	TT_Preliminary.Country,
	|	TT_Preliminary.Period
	|
	|HAVING
	|	TT_Preliminary.Period > MAX(ISNULL(TT_Preliminary1.Ending, TT_Preliminary.Period))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Preliminary.Period AS Period,
	|	TT_Preliminary.Country AS Country,
	|	TT_Preliminary.VATRate AS VATRate,
	|	TT_Preliminary.BasicRate AS BasicRate,
	|	FALSE AS EmptyRate
	|FROM
	|	TT_Preliminary AS TT_Preliminary
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN VATRatesForProductsMaxDate.Ending > BasicVATRatesMaxDate.Ending
	|			THEN VATRatesForProductsMaxDate.Ending
	|		ELSE BasicVATRatesMaxDate.Ending
	|	END,
	|	VATRatesForProductsMaxDate.Country,
	|	VALUE(Catalog.VATRates.EmptyRef),
	|	FALSE,
	|	TRUE
	|FROM
	|	VATRatesForProductsMaxDate AS VATRatesForProductsMaxDate
	|		FULL JOIN BasicVATRatesMaxDate AS BasicVATRatesMaxDate
	|		ON VATRatesForProductsMaxDate.Country = BasicVATRatesMaxDate.Country
	|WHERE
	|	CASE
	|			WHEN VATRatesForProductsMaxDate.Ending > BasicVATRatesMaxDate.Ending
	|				THEN VATRatesForProductsMaxDate.Ending
	|			ELSE BasicVATRatesMaxDate.Ending
	|		END < &CurrentDate
	|
	|UNION ALL
	|
	|SELECT
	|	PeriodsOfEmptyRates.Period,
	|	PeriodsOfEmptyRates.Country,
	|	VALUE(Catalog.VATRates.EmptyRef),
	|	FALSE,
	|	TRUE
	|FROM
	|	PeriodsOfEmptyRates AS PeriodsOfEmptyRates
	|
	|ORDER BY
	|	Period
	|TOTALS BY
	|	Country";
	
	QueryText = StrReplace(QueryText, "&FilterByCountry1",
			?(ValueIsFilled(SelectionByCountry), "ProductsVATRates.Country = &Country", "TRUE"));
	QueryText = StrReplace(QueryText, "&FilterByCountry2",
			?(ValueIsFilled(SelectionByCountry), "BasicVATRates.Country = &Country", "TRUE"));
			
	Query.Text = QueryText;

	Query.SetParameter("Products", Products);
	Query.SetParameter("MainCountry", SettingsValueClientServerCached.MainCountry());
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	If ValueIsFilled(SelectionByCountry) Then
		Query.SetParameter("Country", SelectionByCountry);	
	EndIf;
	
	QueryResult = Query.Execute();
	
	BidTable = New ValueTable;
	BidTable.Columns.Add("Period");
	BidTable.Columns.Add("Country");
	BidTable.Columns.Add("VATRate");
	BidTable.Columns.Add("BasicRate");
	BidTable.Columns.Add("EmptyRate");

	SampleCountry = QueryResult.Select(QueryResultIteration.ByGroups);
	While SampleCountry.Next() Do
	
		SelectionDetailRecords = SampleCountry.Select();
	    BidInPeriod = Undefined;
		While SelectionDetailRecords.Next() Do
			If SelectionDetailRecords.VATRate <> BidInPeriod Then
				If ValueIsFilled(FilterByPeriod) And SelectionDetailRecords.Period > FilterByPeriod Then
					Continue;
				EndIf;					
				NewRow = BidTable.Add();
				NewRow.Country = SampleCountry.Country;
				FillPropertyValues(NewRow, SelectionDetailRecords);
				BidInPeriod = SelectionDetailRecords.VATRate;
			EndIf;
		EndDo;
	EndDo;
	
	Return BidTable;
	
EndFunction

#EndRegion

#Region Private

Procedure ProcessProductGroup(ValueTable, Group)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Products.Ref AS Ref
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Ref IN HIERARCHY(&Group)
		|	AND NOT Products.IsFolder";
	
	Query.SetParameter("Group", Group);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			NewRow = ValueTable.Add();
			NewRow.Products = Selection.Ref;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure AddRegisterEntry(Data, Parameters)
	
	RecordSet = InformationRegisters.ProductsVATRates.CreateRecordSet();
	RecordSet.Filter.Period.Set(Parameters.Period);
	RecordSet.Filter.Products.Set(Data.Products);
	RecordSet.Filter.Country.Set(Parameters.Country);
	
	NewRecord = RecordSet.Add();
	FillPropertyValues(NewRecord, Data);
	FillPropertyValues(NewRecord, Parameters);
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf
