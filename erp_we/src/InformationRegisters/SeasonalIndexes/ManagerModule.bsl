#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the coefficients according to the statistics of sales
//
// Parameters:
//  Parameters		- Structure - contains settings for calculating coefficients
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CalculateCoefficientsBasedOnSalesStatistics(Parameters, StorageAddress) Export
	
	DataCompositionSchema = InformationRegisters.SeasonalIndexes.GetTemplate("CalculationBySaleStatistics");
	
	Settings = Common.CommonSettingsStorageLoad(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID);
		
	UserSettings = Undefined;
	Settings.Property("UserSettings", UserSettings);
	
	// Loading Settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	If UserSettings <> Undefined Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "BegOfYear", Date("00010101"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Parameters.StartDate);
	DataCompositionClientServer.SetParameter(SettingsComposer, "EndOfPeriod", Parameters.EndDate);
	DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfYears", Parameters.NumberOfYears);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Periodicity", Parameters.Periodicity);
	If Parameters.Periodicity = Enums.Periodicity.Day Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 365);
	ElsIf Parameters.Periodicity = Enums.Periodicity.Week Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 53);
	ElsIf Parameters.Periodicity = Enums.Periodicity.Month Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 12);
	ElsIf Parameters.Periodicity = Enums.Periodicity.Quarter Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 4);
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "NumberOfPeriods", 1);
	EndIf;
	
	If Settings.Property("FilterSeasonalGroups") Then
	
		DataCompositionClientServer.AddFilter(SettingsComposer, 
			"ItemsGroup", 
			Settings.FilterSeasonalGroups, 
			DataCompositionComparisonType.InListByHierarchy,,
			New Structure("ToUserSettings", True));
	
	EndIf; 
	
	If Parameters.Property("CalculationOption") Then
	
		DataCompositionClientServer.SetParameter(SettingsComposer, "CalculationOption", Parameters.CalculationOption);
	
	EndIf;
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	
	// The table of values in which the result will be received
	TableOfCoefficients = New ValueTable;
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(TableOfCoefficients);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	PutToTempStorage(TableOfCoefficients, StorageAddress);
	
	SetPrivilegedMode(True);
	Common.CommonSettingsStorageDelete(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID, Users.CurrentUser());
	
EndProcedure

// changes the specified table details to a seasonal coefficient
//
// Parameters:
//  ProductsTable	- ValueTable - Table that should contain the "item" field 
//							and the required details
//  Parameters			- Structure - Additional parameters for the calculation of the seasonal factors.
//
Procedure ChangeToTheSeasonalIndex(ProductsTable, Parameters) Export 
	
	StartDate                  = Parameters.StartDate;
	EndDate               = Parameters.EndDate;
	StartDateShift             = Parameters.StartDateShift;
	EndDateShift          = Parameters.EndDateShift;
	Periodicity               = Parameters.Periodicity;
	PeriodOffsetIsUsed = Parameters.PeriodOffsetIsUsed;
	PeriodOffset             = Parameters.PeriodOffset;
	FieldName                     = Parameters.FieldName;
	FieldNameCoefficient          = "";
	Partner                     = Parameters.Partner;
	Warehouse                       = Parameters.Warehouse;
	BitRounding       = Parameters.RoundingPrecision + 3;
	
	If Parameters.Property("FieldNameCoefficient") Then
		FieldNameCoefficient = Parameters.FieldNameCoefficient;
	EndIf;
	
	MustBeBrokenDownIntoPeriods = False;
	If ProductsTable.Columns.Find("Period") = Undefined Then
		
		TimeIntervals = New Array;
		CurShiftDate = StartDateShift;
		
		While True Do
			
			CurShiftDate = TMCommonUseClientServer.CalculateStartDateOfNearestPeriod(CurShiftDate, Periodicity);
			
			If CurShiftDate > EndDateShift Then
				Break;
			EndIf; 
			
			TimeIntervals.Add(BegOfDay(CurShiftDate));
			CurShiftDate = CurShiftDate + 1;
		
		EndDo; 
		
		If TimeIntervals.Count() >= 2 Then
			
			MustBeBrokenDownIntoPeriods = True;
			
			TableOfProductsWithPeriod = ProductsTable.CopyColumns();
			TableOfProductsWithPeriod.Columns.Add("Period", New TypeDescription("Date"));
			
			For Each TableRow In ProductsTable Do
				
				For Each PeriodDate_ In TimeIntervals Do
					
					StringWithPeriod = TableOfProductsWithPeriod.Add();
					FillPropertyValues(StringWithPeriod, TableRow);
					StringWithPeriod.Period = PeriodDate_;
					
				EndDo; 
				
			EndDo;
			
			ProductsTable = TableOfProductsWithPeriod;
			
		EndIf; 
		
	Else
		TablePeriods = ProductsTable.Copy(,"Period");
		TablePeriods.GroupBy("Period");
		TimeIntervals = TablePeriods.UnloadColumn("Period")
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&PeriodField AS Period,
	|	&PartnerField AS Partner,
	|	&WarehouseField AS Warehouse,
	|	ProductsTable.Products
	|INTO ProductsTable
	|FROM
	|	&ProductsTable AS ProductsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&PeriodStartField_ AS Period,
	|	&PeriodEndField AS PeriodEnd,
	|	&PeriodFieldWithoutShiftStart AS PeriodWithoutShift,
	|	&PeriodFieldWithoutShiftEnd AS PeriodWithoutShiftEnding,
	|	ProductsTable.Products,
	|	ProductsTable.Partner,
	|	ProductsTable.Warehouse,
	|   &FieldSeasonalGroupBusinessRegion AS SeasonalGroupOfBusinessRegion,
	|	CatProducts.ItemsGroup
	|INTO SeasonalGroups
	|FROM
	|	ProductsTable AS ProductsTable
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON ProductsTable.Products = CatProducts.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Period,
	|	NestedQuery.Products,
	|	NestedQuery.Partner,
	|	NestedQuery.Warehouse,
	|	SUM(NestedQuery.ZoomRatio) AS ZoomRatio,
	|	SUM(NestedQuery.CoefficientShift) AS CoefficientShift
	|INTO Coefficients
	|FROM
	|	(SELECT
	|		SeasonalGroups.Period AS Period,
	|		SeasonalGroups.Products AS Products,
	|		SeasonalGroups.Partner AS Partner,
	|		SeasonalGroups.Warehouse AS Warehouse,
	|		SUM(SeasonalIndexes.ZoomRatio) AS ZoomRatio,
	|		SUM(0) AS CoefficientShift
	|	FROM
	|		SeasonalGroups AS SeasonalGroups
	|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
	|			ON SeasonalGroups.ItemsGroup = SeasonalIndexes.ItemsGroup
	|				AND SeasonalGroups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
	|				AND (SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY))
	|				AND (CASE
	|					WHEN YEAR(SeasonalGroups.PeriodWithoutShift) <> YEAR(SeasonalGroups.PeriodWithoutShiftEnding)
	|						THEN SeasonalIndexes.PeriodNumber >= 1
	|									AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(SeasonalGroups.PeriodWithoutShiftEnding)
	|								OR SeasonalIndexes.PeriodNumber >= DAYOFYEAR(SeasonalGroups.PeriodWithoutShift)
	|									AND SeasonalIndexes.PeriodNumber <= 365
	|					ELSE SeasonalIndexes.PeriodNumber >= DAYOFYEAR(SeasonalGroups.PeriodWithoutShift)
	|							AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(SeasonalGroups.PeriodWithoutShiftEnding)
	|				END)
	|	
	|	GROUP BY
	|		SeasonalGroups.Products,
	|		SeasonalGroups.Period,
	|		SeasonalGroups.Partner,
	|		SeasonalGroups.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SeasonalGroups.Period,
	|		SeasonalGroups.Products,
	|		SeasonalGroups.Partner AS Partner,
	|		SeasonalGroups.Warehouse AS Warehouse,
	|		SUM(0),
	|		SUM(SeasonalIndexes.ZoomRatio)
	|	FROM
	|		SeasonalGroups AS SeasonalGroups
	|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
	|			ON SeasonalGroups.ItemsGroup = SeasonalIndexes.ItemsGroup
	|				AND SeasonalGroups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
	|				AND (SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY))
	|				AND (CASE
	|					WHEN YEAR(SeasonalGroups.Period) <> YEAR(SeasonalGroups.PeriodEnd)
	|						THEN SeasonalIndexes.PeriodNumber >= 1
	|									AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(SeasonalGroups.PeriodEnd)
	|								OR SeasonalIndexes.PeriodNumber >= DAYOFYEAR(SeasonalGroups.Period)
	|									AND SeasonalIndexes.PeriodNumber <= 365
	|					ELSE SeasonalIndexes.PeriodNumber >= DAYOFYEAR(SeasonalGroups.Period)
	|							AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(SeasonalGroups.PeriodEnd)
	|				END)
	|	
	|	GROUP BY
	|		SeasonalGroups.Products,
	|		SeasonalGroups.Period,
	|		SeasonalGroups.Partner,
	|		SeasonalGroups.Warehouse) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Period,
	|	NestedQuery.Partner,
	|	NestedQuery.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Coefficients.Products AS Products,
	|	Coefficients.Partner AS Partner,
	|	Coefficients.Warehouse AS Warehouse,
	|	SUM(Coefficients.ZoomRatio) AS FactorDenominator
	|INTO DenominatorCoefficients
	|FROM
	|	Coefficients AS Coefficients
	|		
	|		GROUP BY
	|			Coefficients.Products,
	|			Coefficients.Partner,
	|			Coefficients.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Coefficients.Period AS Period,
	|	Coefficients.Products AS Products,
	|	Coefficients.Partner AS Partner,
	|	Coefficients.Warehouse AS Warehouse,
	|	Coefficients.CoefficientShift AS PartitionCoefficientNumerator,
	|	DenominatorCoefficients.FactorDenominator AS PartitionCoefficientDenominator,
	|	CASE
	|		WHEN Coefficients.ZoomRatio = 0
	|			THEN 0
	|		ELSE Coefficients.CoefficientShift / Coefficients.ZoomRatio
	|	END AS ZoomRatio
	|FROM
	|	Coefficients AS Coefficients
	|		LEFT JOIN DenominatorCoefficients AS DenominatorCoefficients
	|		ON Coefficients.Products = DenominatorCoefficients.Products
	|			AND Coefficients.Partner = DenominatorCoefficients.Partner
	|			AND Coefficients.Warehouse = DenominatorCoefficients.Warehouse
	|
	|ORDER BY
	|	Products,
	|	Partner,
	|	Warehouse,
	|	Period";
	
	
	Query.SetParameter("ProductsTable",         ProductsTable);
	Query.SetParameter("Periodicity",               Periodicity);
	Query.SetParameter("PeriodOffsetIsUsed", PeriodOffsetIsUsed);
	Query.SetParameter("PeriodOffset",             PeriodOffset);
	
	ThereIsPeriodColumn           = ProductsTable.Columns.Find("Period")          <> Undefined;
	ThereIsPartnerColumn          = ProductsTable.Columns.Find("Partner")         <> Undefined;
	ThereIsColumnWarehouse            = ProductsTable.Columns.Find("Warehouse")           <> Undefined;
	ThereIsColumnCharacteristic   = ProductsTable.Columns.Find("Characteristic") <> Undefined;
	ThereIsDestinationColumn       = ProductsTable.Columns.Find("Purpose")      <> Undefined;
	
	If ThereIsPartnerColumn Then
		
		PartnerField = "ProductsTable.Partner";
		
	Else 
		
		PartnerField = "&Partner";
		Query.SetParameter("Partner", Partner);
	
	EndIf; 
	
	If ThereIsColumnWarehouse Then
		
		WarehouseField = "ProductsTable.Warehouse";
		
	Else 
		
		WarehouseField = "&Warehouse";
		Query.SetParameter("Warehouse", Warehouse);
	
	EndIf; 
	
	If GetFunctionalOption("UseBusinessRegions") Then
		
		FieldSeasonalGroupBusinessRegion = 
		"CASE
		|		WHEN NOT ProductsTable.Partner.BusinessRegion.ItemsGroup IS NULL AND NOT ProductsTable.Partner.BusinessRegion.ItemsGroup = VALUE(Catalog.SeasonalGroupsOfBusinessRegions.EmptyRef)
		|			THEN ProductsTable.Partner.BusinessRegion.ItemsGroup
		|		WHEN NOT ProductsTable.Warehouse.BusinessRegion.ItemsGroup IS NULL AND NOT ProductsTable.Warehouse.BusinessRegion.ItemsGroup = VALUE(Catalog.SeasonalGroupsOfBusinessRegions.EmptyRef)
		|			THEN ProductsTable.Warehouse.BusinessRegion.ItemsGroup
		|		ELSE VALUE(Catalog.SeasonalGroupsOfBusinessRegions.OtherItems)
		|END";
		
	Else 
		
		FieldSeasonalGroupBusinessRegion = "VALUE(Catalog.SeasonalGroupsOfBusinessRegions.OtherItems)";
		
	EndIf;
	
	If ThereIsPeriodColumn Then
		
		PeriodField = "ProductsTable.Period AS Period,";
		PeriodStartField_ = "ProductsTable.Period";
		PeriodEndField = "CASE &Periodicity
		|		WHEN VALUE(Enum.Periodicity.Week)
		|			THEN ENDOFPERIOD(ProductsTable.Period, WEEK)
		|		WHEN VALUE(Enum.Periodicity.TenDays)
		|			THEN ENDOFPERIOD(ProductsTable.Period, TENDAYS)
		|		WHEN VALUE(Enum.Periodicity.Month)
		|			THEN ENDOFPERIOD(ProductsTable.Period, MONTH)
		|		WHEN VALUE(Enum.Periodicity.Quarter)
		|			THEN ENDOFPERIOD(ProductsTable.Period, QUARTER)
		|		WHEN VALUE(Enum.Periodicity.HalfYear)
		|			THEN ENDOFPERIOD(ProductsTable.Period, HALFYEAR)
		|		WHEN VALUE(Enum.Periodicity.Year)
		|			THEN ENDOFPERIOD(ProductsTable.Period, YEAR)
		|		ELSE ENDOFPERIOD(ProductsTable.Period, DAY)
		|	END";
		If PeriodOffsetIsUsed Then
			
			PeriodFieldWithoutShiftStart = "CASE &Periodicity
			|		WHEN VALUE(Enum.Periodicity.Week)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, WEEK, &PeriodOffset), WEEK)
			|		WHEN VALUE(Enum.Periodicity.TenDays)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, TENDAYS, &PeriodOffset), TENDAYS)
			|		WHEN VALUE(Enum.Periodicity.Month)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, MONTH, &PeriodOffset), MONTH)
			|		WHEN VALUE(Enum.Periodicity.Quarter)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, QUARTER, &PeriodOffset), QUARTER)
			|		WHEN VALUE(Enum.Periodicity.HalfYear)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, HALFYEAR, &PeriodOffset), HALFYEAR)
			|		WHEN VALUE(Enum.Periodicity.Year)
			|			THEN BEGINOFPERIOD(DATEADD(ProductsTable.Period, YEAR, &PeriodOffset), YEAR)
			|		ELSE BEGINOFPERIOD(DATEADD(ProductsTable.Period, DAY, &PeriodOffset), DAY)
			|	END";
		
		Else
			PeriodFieldWithoutShiftStart = "ProductsTable.Period";
		EndIf; 
		
		If PeriodOffsetIsUsed Then
			
			PeriodFieldWithoutShiftEnd = "CASE &Periodicity
			|		WHEN VALUE(Enum.Periodicity.Week)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, WEEK, &PeriodOffset), WEEK)
			|		WHEN VALUE(Enum.Periodicity.TenDays)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, TENDAYS, &PeriodOffset), TENDAYS)
			|		WHEN VALUE(Enum.Periodicity.Month)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, MONTH, &PeriodOffset), MONTH)
			|		WHEN VALUE(Enum.Periodicity.Quarter)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, QUARTER, &PeriodOffset), QUARTER)
			|		WHEN VALUE(Enum.Periodicity.HalfYear)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, HALFYEAR, &PeriodOffset), HALFYEAR)
			|		WHEN VALUE(Enum.Periodicity.Year)
			|			THEN ENDOFPERIOD(DATEADD(ProductsTable.Period, YEAR, &PeriodOffset), YEAR)
			|		ELSE ENDOFPERIOD(DATEADD(ProductsTable.Period, DAY, &PeriodOffset), DAY)
			|	END";
		
		Else
			PeriodFieldWithoutShiftEnd = "CASE &Periodicity
			|		WHEN VALUE(Enum.Periodicity.Week)
			|			THEN ENDOFPERIOD(ProductsTable.Period, WEEK)
			|		WHEN VALUE(Enum.Periodicity.TenDays)
			|			THEN ENDOFPERIOD(ProductsTable.Period, TENDAYS)
			|		WHEN VALUE(Enum.Periodicity.Month)
			|			THEN ENDOFPERIOD(ProductsTable.Period, MONTH)
			|		WHEN VALUE(Enum.Periodicity.Quarter)
			|			THEN ENDOFPERIOD(ProductsTable.Period, QUARTER)
			|		WHEN VALUE(Enum.Periodicity.HalfYear)
			|			THEN ENDOFPERIOD(ProductsTable.Period, HALFYEAR)
			|		WHEN VALUE(Enum.Periodicity.Year)
			|			THEN ENDOFPERIOD(ProductsTable.Period, YEAR)
			|		ELSE ENDOFPERIOD(ProductsTable.Period, DAY)
			|	END";
		EndIf;
		
	Else
		
		PeriodField = "";
		PeriodStartField_ = "&StartDateShift";
		PeriodEndField = "&EndDateShift";
		PeriodFieldWithoutShiftStart = "&StartDate";
		PeriodFieldWithoutShiftEnd = "&EndDate";
		
		Query.SetParameter("StartDate", StartDate);
		Query.SetParameter("EndDate", EndDate);
		Query.SetParameter("StartDateShift", StartDateShift);
		Query.SetParameter("EndDateShift", EndDateShift);
		
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&PeriodField AS Period,",          PeriodField);
	Query.Text = StrReplace(Query.Text, "&PeriodStartField_",                PeriodStartField_);
	Query.Text = StrReplace(Query.Text, "&PeriodEndField",             PeriodEndField);
	Query.Text = StrReplace(Query.Text, "&PeriodFieldWithoutShiftStart",       PeriodFieldWithoutShiftStart);
	Query.Text = StrReplace(Query.Text, "&PeriodFieldWithoutShiftEnd",    PeriodFieldWithoutShiftEnd);
	Query.Text = StrReplace(Query.Text, "&PartnerField",                     PartnerField);
	Query.Text = StrReplace(Query.Text, "&WarehouseField",                       WarehouseField);
	Query.Text = StrReplace(Query.Text, "&FieldSeasonalGroupBusinessRegion", FieldSeasonalGroupBusinessRegion);
	
	If Periodicity = Enums.Periodicity.Month Then
		Query.Text = StrReplace(Query.Text, "SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.Day)",
												 "SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.Month)");
		Query.Text = StrReplace(Query.Text, "DAYOFYEAR",
												 "MONTH");
	EndIf;
	
	QueryResult = Query.Execute();

	SeasonalIndexes = QueryResult.Unload();
	NumberOfPeriods = TimeIntervals.Count();
	
	SelectionCoefficientGroup = New Structure("Products", Undefined);
	CurrentCharacteristic = Undefined;
	CurAssignment = Undefined;
	If ThereIsPartnerColumn Then
		SelectionCoefficientGroup.Insert("Partner", Undefined);
	EndIf;
	If ThereIsColumnWarehouse Then
		SelectionCoefficientGroup.Insert("Warehouse", Undefined);
	EndIf;
	
	SaveCoefficientToTS = ValueIsFilled(FieldNameCoefficient);
	
	For Each TSRow In ProductsTable Do
		
		If SelectionCoefficientGroup.Products <> TSRow.Products
			Or (ThereIsColumnCharacteristic And CurrentCharacteristic <> TSRow.Characteristic)
			Or (ThereIsDestinationColumn And CurAssignment <> TSRow.Purpose)
			Or (ThereIsPartnerColumn And SelectionCoefficientGroup.Partner <> TSRow.Partner)
			Or (ThereIsColumnWarehouse And SelectionCoefficientGroup.Warehouse <> TSRow.Warehouse) Then
			
			SelectionCoefficientGroup.Insert("Products", TSRow.Products);
			If ThereIsColumnCharacteristic Then
				CurrentCharacteristic = TSRow.Characteristic;
			EndIf;
			If ThereIsDestinationColumn Then
				CurAssignment = TSRow.Purpose;
			EndIf;
			If ThereIsPartnerColumn Then
				SelectionCoefficientGroup.Insert("Partner", TSRow.Partner);
			EndIf;
			If ThereIsColumnWarehouse Then
				SelectionCoefficientGroup.Insert("Warehouse", TSRow.Warehouse);
			EndIf;
			
			GroupOfSeasonalCoefficients = SeasonalIndexes.FindRows(SelectionCoefficientGroup);
			
			Coefficients = New Array();
			If GroupOfSeasonalCoefficients.Count() > 0 Then
				For Each SeasonalFactor In GroupOfSeasonalCoefficients Do
					Coefficients.Add(SeasonalFactor.PartitionCoefficientNumerator);	
				EndDo;
			Else
				For Each Period In TimeIntervals Do
					Coefficients.Add(1);	
				EndDo;
			EndIf;
				
			DistributionQuantity = CommonClientServer.DistributeAmountInProportionToCoefficients(
				TSRow[FieldName], 
				Coefficients,
				3 + Parameters.RoundingPrecision);
				
			MatchingDistributionPeriod = New Map;
			IndexOf = 0;
			If GroupOfSeasonalCoefficients.Count() > 0 Then
				For Each SeasonalFactor In GroupOfSeasonalCoefficients Do
					MatchingDistributionPeriod.Insert(SeasonalFactor.Period,
							?(DistributionQuantity = Undefined, 0, DistributionQuantity[IndexOf]));
					IndexOf = IndexOf + 1;
				EndDo;
			Else
				For Each Period In TimeIntervals Do
					MatchingDistributionPeriod.Insert(Period, 
							?(DistributionQuantity = Undefined, 0, DistributionQuantity[IndexOf]));
					IndexOf = IndexOf + 1;
				EndDo;
			EndIf;
			
		EndIf;
		
		
		Filter = New Structure;
		Filter.Insert("Products", TSRow.Products);
		
		If ThereIsPeriodColumn Then
			Filter.Insert("Period", TSRow.Period);
		EndIf; 
		If ThereIsPartnerColumn Then
			Filter.Insert("Partner", TSRow.Partner);
		EndIf;
		If ThereIsColumnWarehouse Then
			Filter.Insert("Warehouse", TSRow.Warehouse);
		EndIf;
		
		FoundRows = SeasonalIndexes.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			
			If MustBeBrokenDownIntoPeriods Then
				
				If FoundRows[0].PartitionCoefficientDenominator = null Or FoundRows[0].PartitionCoefficientDenominator = 0 Then
					TSRow[FieldName] = 0;
				Else 
					
					If SaveCoefficientToTS Then
						TSRow[FieldNameCoefficient] = MatchingDistributionPeriod.Get(TSRow.Period) / TSRow[FieldName];
					EndIf;
					
					TSRow[FieldName] = MatchingDistributionPeriod.Get(TSRow.Period);
					
				EndIf; 
				
			Else 
				
				If SaveCoefficientToTS Then
					TSRow[FieldNameCoefficient] = FoundRows[0].ZoomRatio;
				EndIf;
				
				TSRow[FieldName] = TSRow[FieldName] * FoundRows[0].ZoomRatio;
				
			EndIf; 
			
		ElsIf MustBeBrokenDownIntoPeriods Then
			
			If SaveCoefficientToTS Then
				TSRow[FieldNameCoefficient] = MatchingDistributionPeriod.Get(TSRow.Period) / TSRow[FieldName];
			EndIf;
			
			TSRow[FieldName] = MatchingDistributionPeriod.Get(TSRow.Period);
			
		EndIf; 
		
	EndDo; 
	
EndProcedure
 

#EndRegion

#EndIf