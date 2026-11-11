
#Region Public

#Region ProceduresForProcessingRoutineTasks

// Fills the data register "abcxyzclassification of Clients" with the results of ABC classification of partners.
//
Procedure PerformABCClassificationOfPartnersRoutineTask() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ABCPartnerClassification);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	PerformABCClassificationOfPartners();

EndProcedure

// Fills the data register "abcxyzclassification of Clients" with the results of XYZ classification of partners.
//
Procedure PerformXYZClassificationOfPartnersRoutineTask() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.XYZPartnerClassification);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	PerformXYZClassificationOfPartners();

EndProcedure

// Fills the information register "abcxyzclassicationof the Nomenclature" with the results of the ABC classification of the nomenclature.
//
Procedure PerformABCProductClassificationRoutineAssignment() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ABCInventoryClassification);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	PerformABCProductClassification();

EndProcedure

// Fills the information register "abcxyzclassicationof the Nomenclature" with the results of the XYZ classification of the nomenclature.
//
Procedure PerformXYZProductClassificationRoutineAssignment() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.XYZInventoryClassification);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	PerformXYZProductClassification();

EndProcedure

// Fills the data register "abcxyzclassification of Clients" with the results of ABC classification of partners.
//
// Parameters:
//  ClassificationDate  - Date - the date on which the classification is performed.
//
Procedure PerformABCClassificationOfPartners(ClassificationDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	UseGrossProfitClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit");
	UseRevenueClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue");
	UseQuantityClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales");

	If Not UseGrossProfitClassification And Not UseRevenueClassification And Not UseQuantityClassification Then

		Return;

	EndIf;

	ClassificationPeriod = Constants.PeriodOfABCClassificationOfPartners.Get();
	NumberOfClassificationPeriods = Constants.NumberOfPeriodsOfABCClassificationOfPartners.Get();

	If ClassificationPeriod.IsEmpty() Or NumberOfClassificationPeriods = 0 Then

		Return;

	EndIf;

	Query = New Query(
		"SELECT
		|	InformationRegisterAccountingDimensionByPartners.Partner AS Partner,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) - SUM(RevenueAndCostOfSalesTurnover.CostTurnover) - SUM(RevenueAndCostOfSalesTurnover.AddExpensesForGoodsTurnover) AS GrossProfit,
		|	SUM(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover) AS Revenue,
		|	SUM(CASE
		|			WHEN RevenueAndCostOfSalesTurnover.Recorder REFS Document.CustomerInvoice
		|				THEN 1
		|			ELSE 0
		|		END) AS Count
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, Recorder,(NOT AccountingDimensionByPartners.Partner.Predefined) AND (NOT AccountingDimensionByPartners.Partner = VALUE(Catalog.Partners.EmptyRef))) AS RevenueAndCostOfSalesTurnover
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS InformationRegisterAccountingDimensionByPartners
		|		ON RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners = InformationRegisterAccountingDimensionByPartners.DimensionKey
		|GROUP BY
		|	InformationRegisterAccountingDimensionByPartners.Partner");

	Period = TMCommonUseClientServer.ExtendedPeriod(?(ClassificationDate = Undefined, CurrentSessionDate(), ClassificationDate), ClassificationPeriod, - NumberOfClassificationPeriods);
	Query.SetParameter("BeginOfPeriod", Period.StartDate);
	Query.SetParameter("PeriodEnding", Period.EndDate);

	ClassificationResult = Query.Execute().Unload();

	If UseGrossProfitClassification Then

		PerformABCClassification(ClassificationResult, "GrossProfit");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.ABC,
			Enums.TypesOfClassificationParameters.GrossProfit,
			Period.EndDate, Enums.ABCClassification.NotClassified);

	EndIf;

	If UseRevenueClassification Then

		PerformABCClassification(ClassificationResult, "Revenue");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.ABC,
			Enums.TypesOfClassificationParameters.Revenue,
			Period.EndDate, Enums.ABCClassification.NotClassified);

	EndIf;

	If UseQuantityClassification Then

		PerformABCClassification(ClassificationResult, "Count");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.ABC,
			Enums.TypesOfClassificationParameters.Count,
			Period.EndDate, Enums.ABCClassification.NotClassified);

	EndIf;

EndProcedure

// Fills the data register "abcxyzclassification of Clients" with the results of XYZ classification of partners.
//
// Parameters:
//  ClassificationDate  - Date - the date on which the classification is performed.
//
Procedure PerformXYZClassificationOfPartners(ClassificationDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	UseGrossProfitClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByGrossProfit");
	UseRevenueClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByRevenue");
	UseQuantityClassification = GetFunctionalOption("UseABCXYZClassificationOfPartnersByNumberOfSales");

	If Not UseGrossProfitClassification And Not UseRevenueClassification And Not UseQuantityClassification Then

		Return;

	EndIf;

	ClassificationPeriod = Constants.PeriodOfXYZClassificationOfPartners.Get();
	NumberOfClassificationPeriods = Constants.NumberOfPeriodsOfXYZClassificationOfPartners.Get();
	ClassificationSubperiod = Constants.SubperiodOfXYZClassificationOfPartners.Get();

	If ClassificationPeriod.IsEmpty() Or NumberOfClassificationPeriods = 0 Or ClassificationSubperiod.IsEmpty() Then

		Return;

	EndIf;

	Query = New Query(
	"SELECT
	|	0 AS ClassificationSeparator,
	|	InformationRegisterAccountingDimensionByPartners.Partner AS Partner,
	|	BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, MONTH) AS Period,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS Revenue,
	|	ISNULL(RevenueAndCostOfSalesTurnover.RevenueAmountTurnover, 0) - ISNULL(RevenueAndCostOfSalesTurnover.CostTurnover, 0) - ISNULL(RevenueAndCostOfSalesTurnover.AddExpensesForGoodsTurnover, 0) AS GrossProfit,
	|	CASE
	|		WHEN RevenueAndCostOfSalesTurnover.Recorder REFS Document.CustomerInvoice
	|			THEN 1
	|		ELSE 0
	|	END AS Count
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(
	|		&StartOfSubstitutionPeriod,
	|		&EndOfPeriodSubstitution,
	|		Recorder,
	|		 (NOT AccountingDimensionByPartners.Partner.Predefined)
	|			 AND (NOT AccountingDimensionByPartners.Partner = VALUE(Catalog.Partners.EmptyRef))) AS RevenueAndCostOfSalesTurnover
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS InformationRegisterAccountingDimensionByPartners
	|		ON RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners = InformationRegisterAccountingDimensionByPartners.DimensionKey
	|TOTALS
	|	MAX(ClassificationSeparator),
	|	SUM(Revenue),
	|	SUM(GrossProfit),
	|	SUM(Count)
	|BY
	|	Partner,
	|	Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)");
	
	Substitution = "";
	StartOfPeriodSubstitution = "";
	SubstitutionEndOfPeriod = "";
	SubstitutionRevenue = "";
	If ClassificationSubperiod = Enums.Periodicity.Year Then
		Substitution = "Period PERIODS(YEAR, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, YEAR)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, YEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, YEAR)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.TenDays Then
		Substitution = "Period PERIODS(TENDAYS, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, TENDAYS)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, TENDAYS)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, TENDAYS)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Day Then
		Substitution = "Period PERIODS(DAY, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, DAY)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, DAY)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, DAY)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Quarter Then
		Substitution = "Period PERIODS(QUARTER, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, QUARTER)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, QUARTER)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, QUARTER)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Month Then
		Substitution = "Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, MONTH)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, MONTH)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, MONTH)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Week Then
		Substitution = "Period PERIODS(WEEK, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, WEEK)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, WEEK)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, WEEK)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.HalfYear Then
		Substitution = "Period PERIODS(HALFYEAR, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		SubstitutionRevenue = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, HALFYEAR)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, HALFYEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, HALFYEAR)";
	EndIf;
	TextToReplace = "Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
	Query.Text = StrReplace(Query.Text, TextToReplace, Substitution);
	TextToReplace = "BEGINOFPERIOD(RevenueAndCostOfSalesTurnover.Period, MONTH)";
	Query.Text = StrReplace(Query.Text, TextToReplace, SubstitutionRevenue);
	Query.Text = StrReplace(Query.Text, "&StartOfSubstitutionPeriod", StartOfPeriodSubstitution);
	Query.Text = StrReplace(Query.Text, "&EndOfPeriodSubstitution", SubstitutionEndOfPeriod);
	Period = TMCommonUseClientServer.ExtendedPeriod(?(ClassificationDate = Undefined, CurrentSessionDate(), ClassificationDate), ClassificationPeriod, - NumberOfClassificationPeriods);
	Query.SetParameter("BeginOfPeriod", Period.StartDate);
	Query.SetParameter("PeriodEnding", Period.EndDate);

	DataSource = New Structure("DataSource", Query.Execute());

	If UseGrossProfitClassification Then

		ClassificationResult = PerformXYZClassification(DataSource, "GrossProfit", "Products");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.GrossProfit,
			Period.EndDate, Enums.XYZClassification.NotClassified);

	EndIf;

	If UseRevenueClassification Then

		ClassificationResult = PerformXYZClassification(DataSource, "Revenue", "Products");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.Revenue,
			Period.EndDate, Enums.XYZClassification.NotClassified);

	EndIf;

	If UseQuantityClassification Then

		ClassificationResult = PerformXYZClassification(DataSource, "Count", "Products");
		UpdatePartnerClassificationData(
			ClassificationResult, Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.Count,
			Period.EndDate, Enums.XYZClassification.NotClassified);

	EndIf;

EndProcedure

// Calculates the ABC class of the item and writes it to the register
//
//	Parameters:
//		ClassificationDate - Date - the end date of the period for which you want to select data for
//			classification, if Undefined, the current date is used.
//
Procedure PerformABCProductClassification(ClassificationDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	UseGrossProfitClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByGrossProfit");
	UseRevenueClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByRevenue");
	UseQuantityClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByNumberOfSales");
	TakeIntoAccountRulesOfInternalCommodityMovement = Constants.RecordInternalInventoryTransferRulesInCaseOfABCClassificationOfInventory.Get();
	
	If Not UseGrossProfitClassification And Not UseRevenueClassification And Not UseQuantityClassification Then
		Return;
	EndIf;
	
	ClassificationPeriod = Constants.PeriodOfABCClassificationOfInventory.Get();
	NumberOfClassificationPeriods = Constants.NumberOfPeriodsOfABCClassificationOfInventory.Get();
	
	If ClassificationPeriod.IsEmpty() Or NumberOfClassificationPeriods = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners.Organization AS Organization,
	|	RevenueAndCostOfSalesTurnover.Department AS Department,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products AS Products,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover - RevenueAndCostOfSalesTurnover.AddExpensesForGoodsTurnover AS GrossProfit,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS Revenue,
	|	RevenueAndCostOfSalesTurnover.CountTurnover AS Count
	|INTO DataSource
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(&BeginOfPeriod, &PeriodEnding, , ) AS RevenueAndCostOfSalesTurnover
	|WHERE
	|	RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS ClassificationSeparator,
	|	UNDEFINED AS ClassificationSection,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	SUM(DataSource.GrossProfit) AS GrossProfit,
	|	SUM(DataSource.Revenue) AS Revenue,
	|	SUM(DataSource.Count) AS Count
	|INTO TT_Section0
	|FROM
	|	DataSource AS DataSource
	|
	|GROUP BY
	|	DataSource.Products,
	|	DataSource.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataSource.Products   AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	DataSource.Warehouse          AS Warehouse
	|INTO TTProducts_1
	|FROM
	|	DataSource AS DataSource
	|WHERE
	|	&TakeIntoAccountRulesOfInternalCommodityMovement
	|	AND VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|	AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|;
	|
	|///////////////////////////////////////////////////////////
	|" + StrReplace(InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE"), "ALLOWED", "") + "
	|;
	|
	|////////////////////////////////////
	|SELECT
	|	1 AS ClassificationSeparator,
	|	DataSource.Warehouse AS ClassificationSection,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	SUM(DataSource.GrossProfit) AS GrossProfit,
	|	SUM(DataSource.Revenue) AS Revenue,
	|	SUM(DataSource.Count) AS Count
	|INTO TT_Section1
	|FROM
	|	(SELECT
	|		DataSource.Warehouse AS Warehouse,
	|		DataSource.Products AS Products,
	|		DataSource.Characteristic AS Characteristic,
	|		DataSource.GrossProfit AS GrossProfit,
	|		DataSource.Revenue AS Revenue,
	|		DataSource.Count AS Count
	|	FROM
	|		DataSource AS DataSource
	|	WHERE
	|		VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|		AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CatSupplyMethods.SourceOfDemandSupply,
	|		DataSource.Products,
	|		DataSource.Characteristic,
	|		DataSource.GrossProfit,
	|		DataSource.Revenue,
	|		DataSource.Count
	|	FROM
	|		DataSource AS DataSource
	|			
	|			LEFT JOIN TTWaysToEnsure AS TableOfSecurityMethods
	|			ON TableOfSecurityMethods.Warehouse          = DataSource.Warehouse
	|			 AND TableOfSecurityMethods.Products   = DataSource.Products
	|			 AND TableOfSecurityMethods.Characteristic = DataSource.Characteristic
	|			
	|			LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethods
	|			ON CatSupplyMethods.Ref = TableOfSecurityMethods.ProcurementStrategy
	|	WHERE
	|		&TakeIntoAccountRulesOfInternalCommodityMovement
	|		AND VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|		AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|		AND CatSupplyMethods.SupplyType = VALUE(Enum.SupplyTypes.Move)
	|		AND CatSupplyMethods.SourceOfDemandSupply REFS Catalog.Warehouses
	|		AND CatSupplyMethods.SourceOfDemandSupply <> VALUE(Catalog.Warehouses.EmptyRef)) AS DataSource
	|
	|GROUP BY
	|	DataSource.Warehouse,
	|	DataSource.Products,
	|	DataSource.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	2 AS ClassificationSeparator,
	|	DataSource.Organization AS ClassificationSection,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	SUM(DataSource.GrossProfit) AS GrossProfit,
	|	SUM(DataSource.Revenue) AS Revenue,
	|	SUM(DataSource.Count) AS Count
	|INTO TT_Section2
	|FROM
	|	DataSource AS DataSource
	|
	|GROUP BY
	|	DataSource.Organization,
	|	DataSource.Products,
	|	DataSource.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	3 AS ClassificationSection,
	|	DataSource.Department AS Department,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	SUM(DataSource.GrossProfit) AS GrossProfit,
	|	SUM(DataSource.Revenue) AS Revenue,
	|	SUM(DataSource.Count) AS Count
	|INTO TT_Section3
	|FROM
	|	DataSource AS DataSource
	|
	|GROUP BY
	|	DataSource.Department,
	|	DataSource.Products,
	|	DataSource.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Section0.ClassificationSeparator AS ClassificationSeparator,
	|	TT_Section0.ClassificationSection AS ClassificationSection,
	|	TT_Section0.Products AS Products,
	|	TT_Section0.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TT_Section0.GrossProfit > 0
	|			THEN TT_Section0.GrossProfit
	|		ELSE 0
	|	END AS GrossProfit,
	|	CASE
	|		WHEN TT_Section0.Revenue > 0
	|			THEN TT_Section0.Revenue
	|		ELSE 0
	|	END AS Revenue,
	|	CASE
	|		WHEN TT_Section0.Count > 0
	|			THEN TT_Section0.Count
	|		ELSE 0
	|	END AS Count
	|FROM
	|	TT_Section0 AS TT_Section0
	|
	|UNION ALL
	|
	|SELECT
	|	TT_Section1.ClassificationSeparator,
	|	TT_Section1.ClassificationSection,
	|	TT_Section1.Products,
	|	TT_Section1.Characteristic,
	|	CASE
	|		WHEN TT_Section1.GrossProfit > 0
	|			THEN TT_Section1.GrossProfit
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN TT_Section1.Revenue > 0
	|			THEN TT_Section1.Revenue
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN TT_Section1.Count > 0
	|			THEN TT_Section1.Count
	|		ELSE 0
	|	END
	|FROM
	|	TT_Section1 AS TT_Section1
	|
	|UNION ALL
	|
	|SELECT
	|	TT_Section2.ClassificationSeparator,
	|	TT_Section2.ClassificationSection,
	|	TT_Section2.Products,
	|	TT_Section2.Characteristic,
	|	CASE
	|		WHEN TT_Section2.GrossProfit > 0
	|			THEN TT_Section2.GrossProfit
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN TT_Section2.Revenue > 0
	|			THEN TT_Section2.Revenue
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN TT_Section2.Count > 0
	|			THEN TT_Section2.Count
	|		ELSE 0
	|	END
	|FROM
	|	TT_Section2 AS TT_Section2";
	
	Period = TMCommonUseClientServer.ExtendedPeriod(
		?(ClassificationDate = Undefined, CurrentSessionDate(), ClassificationDate), 
			ClassificationPeriod, -NumberOfClassificationPeriods);
	
	Query.SetParameter("BeginOfPeriod", Period.StartDate);
	Query.SetParameter("PeriodEnding", Period.EndDate);
	Query.SetParameter("TakeIntoAccountRulesOfInternalCommodityMovement", TakeIntoAccountRulesOfInternalCommodityMovement);

	ClassificationResult = Query.Execute().Unload();
	
	If UseGrossProfitClassification Then
		PerformABCClassification(ClassificationResult, "GrossProfit");
		UpdateProductClassificationData(ClassificationResult, Enums.TypesOfClassification.ABC, 
			Enums.TypesOfClassificationParameters.GrossProfit, Period.EndDate, Enums.ABCClassification.NotClassified);
	EndIf;
	
	If UseRevenueClassification Then
		PerformABCClassification(ClassificationResult, "Revenue");
		UpdateProductClassificationData(ClassificationResult, Enums.TypesOfClassification.ABC, 
			Enums.TypesOfClassificationParameters.Revenue, Period.EndDate, Enums.ABCClassification.NotClassified);
	EndIf;
	
	If UseQuantityClassification Then
		PerformABCClassification(ClassificationResult, "Count");
		UpdateProductClassificationData(ClassificationResult, Enums.TypesOfClassification.ABC, 
			Enums.TypesOfClassificationParameters.Count, Period.EndDate, Enums.ABCClassification.NotClassified);
	EndIf;
	
EndProcedure

// Calculates the XYZ class of the item and writes it to the register
//
//	Parameters:
//		ClassificationDate - Date - the end date of the period for which you want to select data for
//			classification, if Undefined, the current date is used.
//
Procedure PerformXYZProductClassification(ClassificationDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	UseGrossProfitClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByGrossProfit");
	UseRevenueClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByRevenue");
	UseQuantityClassification = GetFunctionalOption("UseABCXYZClassificationOfInventoryByNumberOfSales");
	TakeIntoAccountRulesOfInternalCommodityMovement = Constants.RecordInternalInventoryTransferRulesInCaseOfXYZClassificationOfInventory.Get();
	
	If Not UseGrossProfitClassification And Not UseRevenueClassification And Not UseQuantityClassification Then
		Return;
	EndIf;
	
	ClassificationPeriod = Constants.PeriodOfXYZClassificationOfInventory.Get();
	NumberOfClassificationPeriods = Constants.NumberOfPeriodsOfXYZClassificationOfInventory.Get();
	ClassificationSubperiod = Constants.SubperiodOfXYZClassificationOfInventory.Get();
	
	If ClassificationPeriod.IsEmpty() Or NumberOfClassificationPeriods = 0 Or ClassificationSubperiod.IsEmpty() Then
		Return;
	EndIf;
	
	Query = New Query;
	Period = TMCommonUseClientServer.ExtendedPeriod(
		?(ClassificationDate = Undefined, CurrentSessionDate(), ClassificationDate),
		ClassificationPeriod,
		- NumberOfClassificationPeriods);
	
	Query.SetParameter("BeginOfPeriod",    Period.StartDate);
	Query.SetParameter("PeriodEnding", Period.EndDate);
	Query.SetParameter("TakeIntoAccountRulesOfInternalCommodityMovement", TakeIntoAccountRulesOfInternalCommodityMovement);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text =
	"SELECT
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners.Organization AS Organization,
	|	RevenueAndCostOfSalesTurnover.Department AS Department,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products AS Products,
	|	RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	RevenueAndCostOfSalesTurnover.Period AS Period,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover - RevenueAndCostOfSalesTurnover.CostTurnover - RevenueAndCostOfSalesTurnover.AddExpensesForGoodsTurnover AS GrossProfit,
	|	RevenueAndCostOfSalesTurnover.RevenueAmountTurnover AS Revenue,
	|	RevenueAndCostOfSalesTurnover.CountTurnover AS Count
	|INTO DataSource
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, Month,) AS RevenueAndCostOfSalesTurnover
	|WHERE
	|	RevenueAndCostOfSalesTurnover.AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|	AND RevenueAndCostOfSalesTurnover.ItemsLocationAttributes.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataSource.Products   AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	DataSource.Warehouse          AS Warehouse
	|INTO TTProducts_1
	|FROM
	|	DataSource AS DataSource
	|WHERE
	|	&TakeIntoAccountRulesOfInternalCommodityMovement
	|	AND VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|	AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)";
	
	StartOfPeriodSubstitution = "";
	SubstitutionEndOfPeriod = "";
	If ClassificationSubperiod = Enums.Periodicity.Year Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, YEAR,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, YEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, YEAR)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.TenDays Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, TENDAYS,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, TENDAYS)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, TENDAYS)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Day Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, DAY,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, DAY)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, DAY)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Quarter Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, QUARTER,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, QUARTER)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, QUARTER)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Month Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, MONTH,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, MONTH)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, MONTH)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Week Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, WEEK,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, WEEK)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, WEEK)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.HalfYear Then
		Substitution = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, HALFYEAR,)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, HALFYEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, HALFYEAR)";
	EndIf;
	TextToReplace = "AccumulationRegister.RevenueAndCOGS.Turnovers(&StartOfSubstitutionPeriod, &EndOfPeriodSubstitution, MONTH,)";
	Query.Text = StrReplace(Query.Text, TextToReplace, Substitution);
	Query.Text = StrReplace(Query.Text, "&StartOfSubstitutionPeriod", StartOfPeriodSubstitution);
	Query.Text = StrReplace(Query.Text, "&EndOfPeriodSubstitution", SubstitutionEndOfPeriod);

	Query.Execute();
	
	Query.Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE");
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
	"SELECT
	|	0 AS ClassificationSeparator,
	|	UNDEFINED AS ClassificationSection,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	DataSource.Period AS Period,
	|	DataSource.GrossProfit AS GrossProfit,
	|	DataSource.Revenue AS Revenue,
	|	DataSource.Count AS Count
	|FROM
	|	DataSource AS DataSource
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	DataSource.Warehouse,
	|	DataSource.Products,
	|	DataSource.Characteristic,
	|	DataSource.Period,
	|	DataSource.GrossProfit,
	|	DataSource.Revenue,
	|	DataSource.Count
	|FROM
	|	DataSource AS DataSource
	|WHERE
	|	VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|	AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	ISNULL(CatSupplyMethods.SourceOfDemandSupply, VALUE(Catalog.Warehouses.EmptyRef)),
	|	DataSource.Products,
	|	DataSource.Characteristic,
	|	DataSource.Period,
	|	DataSource.GrossProfit,
	|	DataSource.Revenue,
	|	DataSource.Count
	|FROM
	|	DataSource AS DataSource
	|			
	|			LEFT JOIN TTWaysToEnsure AS TableOfSecurityMethods
	|			ON TableOfSecurityMethods.Warehouse          = DataSource.Warehouse
	|			 AND TableOfSecurityMethods.Products   = DataSource.Products
	|			 AND TableOfSecurityMethods.Characteristic = DataSource.Characteristic
	|			
	|			LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethods
	|			ON CatSupplyMethods.Ref = TableOfSecurityMethods.ProcurementStrategy
	|WHERE
	|	&TakeIntoAccountRulesOfInternalCommodityMovement
	|	AND VALUETYPE(DataSource.Warehouse) = TYPE(Catalog.Warehouses)
	|	AND DataSource.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND CatSupplyMethods.SupplyType = VALUE(Enum.SupplyTypes.Move)
	|	AND CatSupplyMethods.SourceOfDemandSupply REFS Catalog.Warehouses
	|	AND CatSupplyMethods.SourceOfDemandSupply <> VALUE(Catalog.Warehouses.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	DataSource.Organization,
	|	DataSource.Products,
	|	DataSource.Characteristic,
	|	DataSource.Period,
	|	DataSource.GrossProfit,
	|	DataSource.Revenue,
	|	DataSource.Count
	|FROM
	|	DataSource AS DataSource
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	DataSource.Department,
	|	DataSource.Products,
	|	DataSource.Characteristic,
	|	DataSource.Period,
	|	DataSource.GrossProfit,
	|	DataSource.Revenue,
	|	DataSource.Count
	|FROM
	|	DataSource AS DataSource
	|
	|ORDER BY
	|	ClassificationSeparator
	|TOTALS
	|	MAX(ClassificationSeparator),
	|	SUM(GrossProfit),
	|	SUM(Revenue),
	|	SUM(Count)
	|BY
	|	ClassificationSection,
	|	Products,
	|	Characteristic,
	|	Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
	
	Substitution = "";
	StartOfPeriodSubstitution = "";
	SubstitutionEndOfPeriod = "";
	If ClassificationSubperiod = Enums.Periodicity.Year Then
		Substitution = "Period PERIODS(YEAR, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, YEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, YEAR)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.TenDays Then
		Substitution = "Period PERIODS(TENDAYS, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, TENDAYS)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, TENDAYS)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Day Then
		Substitution = "Period PERIODS(DAY, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, DAY)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, DAY)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Quarter Then
		Substitution = "Period PERIODS(QUARTER, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, QUARTER)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, QUARTER)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Month Then
		Substitution = "Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, MONTH)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, MONTH)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.Week Then
		Substitution = "Period PERIODS(WEEK, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, WEEK)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, WEEK)";
	ElsIf ClassificationSubperiod = Enums.Periodicity.HalfYear Then
		Substitution = "Period PERIODS(HALFYEAR, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
		StartOfPeriodSubstitution = "BEGINOFPERIOD(&BeginOfPeriod, HALFYEAR)";
		SubstitutionEndOfPeriod = "ENDOFPERIOD(&PeriodEnding, HALFYEAR)";
	EndIf;
	TextToReplace = "Period PERIODS(MONTH, &StartOfSubstitutionPeriod, &EndOfPeriodSubstitution)";
	Query.Text = StrReplace(Query.Text, TextToReplace, Substitution);
	Query.Text = StrReplace(Query.Text, "&StartOfSubstitutionPeriod", StartOfPeriodSubstitution);
	Query.Text = StrReplace(Query.Text, "&EndOfPeriodSubstitution", SubstitutionEndOfPeriod);
	
	DataSource = New Structure("DataSource", Query.Execute());
	
	If UseGrossProfitClassification Then
		
		ClassificationResult =
			PerformXYZClassification(
				DataSource, 
				"GrossProfit", 
				"ClassificationSection, Products, Characteristic");
		UpdateProductClassificationData(
			ClassificationResult,
			Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.GrossProfit,
			Period.EndDate,
			Enums.XYZClassification.NotClassified);
		
	EndIf;
	
	If UseRevenueClassification Then
	
		ClassificationResult =
			PerformXYZClassification(
				DataSource,
				"Revenue",
				"ClassificationSection, Products, Characteristic");
		UpdateProductClassificationData(
			ClassificationResult,
			Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.Revenue,
			Period.EndDate,
			Enums.XYZClassification.NotClassified);
		
	EndIf;
	
	If UseQuantityClassification Then
		
		ClassificationResult =
			PerformXYZClassification(
				DataSource,
				"Count",
				"ClassificationSection, Products, Characteristic");
		UpdateProductClassificationData(
			ClassificationResult,
			Enums.TypesOfClassification.XYZ,
			Enums.TypesOfClassificationParameters.Count,
			Period.EndDate,
			Enums.XYZClassification.NotClassified);

	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

// Performs object classification using ABC analysis.
// The source data for analysis is a table of values
// containing the values of the classification parameter for the analyzed objects.
// The analysis result is placed in the "Avclass"column to be added.
//
// Parameters:
//  DataSource - ValueTable - a table with the column "Values of the classification parameter",
//                   which contains the values of the parameter by which the
//                   classification is performed for the current object.
//  NameOfClassificationParameter - String - the name of the column in the data source that contains the value
//                              of the classification parameter.
//
Procedure PerformABCClassification(DataSource, NameOfClassificationParameter)
	
	// The data source is empty, classification is not required.
	If DataSource.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	// Classification without division.
	If DataSource.Columns.Find("ClassificationSeparator") = Undefined Then
		
		DataSource.Columns.Add("ClassificationSeparator");
		DataSource.FillValues(0, "ClassificationSeparator");
		
	EndIf;
	
	// The data source is ordered in ascending order of the separator and descending order of the classification parameter.
	SortingColumns = "ClassificationSeparator Asc";
	
	ThereIsClassificationSection = False;
	
	If DataSource.Columns.Find("ClassificationSection") <> Undefined Then
		
		SortingColumns = SortingColumns + ", ClassificationSection Asc";
		ThereIsClassificationSection = True;
		
	EndIf;
	
	SortingColumns = SortingColumns + ", " + NameOfClassificationParameter + " Desc";
	
	If DataSource.Columns.Find("Products") <> Undefined Then
		
		SortingColumns = SortingColumns + ", Products Asc";
		
		If DataSource.Columns.Find("Characteristic") <> Undefined Then
			
			SortingColumns = SortingColumns + ", Characteristic Asc";
			
		EndIf;
		
	EndIf;
	
	DataSource.Sort(SortingColumns, New CompareValues);
	
	// The classification result will be placed in the "Class" column.
	If DataSource.Columns.Find("Class") = Undefined Then
		
		DataSource.Columns.Add("Class");
		
	EndIf;
	
	DataSource.FillValues(Enums.ABCClassification.CClass, "Class");
	
	// The column "Values of the classification parameters" will contain the value by which the classification was performed.
	If DataSource.Columns.Find("ClassificationParameterValue") = Undefined Then
		
		DataSource.Columns.Add("ClassificationParameterValue");
		
	EndIf;
	
	DataSource.FillValues(0, "ClassificationParameterValue");
	
	ValueOfClassificationParameterTotal = 0;
	ShareOnCumulativeBasis = New Array;
	CurShareOnCumulativeBasis = 0;
	
	DataSourceRowIndex = 0;
	DataSourceStringOffset = 0;
	
	While DataSourceRowIndex < DataSource.Count() Do
		
		// The overall result of the separator.
		ValueOfClassificationParameterTotal = ValueOfClassificationParameterTotal + DataSource[DataSourceRowIndex][NameOfClassificationParameter];
		ShareOnCumulativeBasis.Add(DataSource[DataSourceRowIndex][NameOfClassificationParameter]);
		DataSource[DataSourceRowIndex].ClassificationParameterValue = DataSource[DataSourceRowIndex][NameOfClassificationParameter];
		
		// The last row or data on the current separator or classification section has ended.
		If DataSourceRowIndex = DataSource.Count() - 1
			Or DataSource[DataSourceRowIndex].ClassificationSeparator <> DataSource[DataSourceRowIndex + 1].ClassificationSeparator
			Or (ThereIsClassificationSection And DataSource[DataSourceRowIndex].ClassificationSection <> DataSource[DataSourceRowIndex + 1].ClassificationSection) Then
			
			ShareCumulativeTotalAmount = 0;
			
			For IndexOf = 0 To ShareOnCumulativeBasis.UBound() Do
				
				If ValueOfClassificationParameterTotal <> 0 Then
					
					CurShareOnCumulativeBasis = CurShareOnCumulativeBasis + ShareOnCumulativeBasis[IndexOf] * 100 / ValueOfClassificationParameterTotal;
					
				EndIf;
				
				ShareOnCumulativeBasis[IndexOf] = CurShareOnCumulativeBasis;
				ShareCumulativeTotalAmount = ShareCumulativeTotalAmount + CurShareOnCumulativeBasis;
				
			EndDo;
			
			AverageValue = ShareCumulativeTotalAmount / (ShareOnCumulativeBasis.Count() + 1);
			
			CurrentClass = Enums.ABCClassification.AClass;
			
			For IndexOf = 0 To ShareOnCumulativeBasis.UBound() - 1 Do
				
				If ShareOnCumulativeBasis[IndexOf] > AverageValue Then
					
					If CurrentClass = Enums.ABCClassification.AClass Then
						
						CurrentClass = Enums.ABCClassification.BClass;
						
					Else
						
						Break;
						
					EndIf;
					
					AverageValue = ShareCumulativeTotalAmount / (ShareOnCumulativeBasis.Count() - IndexOf);
					
				EndIf;
				
				ShareCumulativeTotalAmount = ShareCumulativeTotalAmount - ShareOnCumulativeBasis[IndexOf];
				DataSource[DataSourceStringOffset + IndexOf].Class = CurrentClass;
				
			EndDo;
			
			ValueOfClassificationParameterTotal = 0;
			ShareOnCumulativeBasis = New Array;
			CurShareOnCumulativeBasis = 0;
			
			DataSourceStringOffset = DataSourceRowIndex + 1;
			
		EndIf;
		
		DataSourceRowIndex = DataSourceRowIndex + 1;
		
	EndDo;
	
EndProcedure

// Performs the classification of objects using XYZ-analysis.
// The source data for analysis is the query result
// containing the final values of the classification parameter for the analyzed
// objects and periods.
// The analysis result is placed in the "XYZ Class" column to be added.
//
// Parameters:
//  DataSource - QueryResult - the result of the query containing the key fields of the classification object,
//                   the period, and the "Value of the classification parameter" field containing
//                   the values of the parameter by which the
//                   classification is performed for the current object.
//  NameOfClassificationParameter - String - the name of the column in the data source that contains the value
//                              of the classification parameter.
//  ClassificationObjectKeys - String - a string containing a comma-separated list of field names
//                              that identify the classification object. 
//
// Returns: 
//  ValueTable - A table containing the classification result.
//
Function PerformXYZClassification(DataSource, NameOfClassificationParameter, Val ClassificationObjectKeys) Export
	
	Result = New ValueTable;
	
	For Each Column In DataSource.DataSource.Columns Do
		
		Result.Columns.Add(Column.Name, Column.ValueType);
		
	EndDo;
	
	Result.Columns.Add("Class", New TypeDescription("EnumRef.XYZClassification, EnumRef.ABCClassification"));
	Result.Columns.Add("ClassificationParameterValue", TMCommonUse.GetDescriptionOfNumberTypes(15, 2));
	
	If DataSource.DataSource.IsEmpty() Then
		
		Return Result;
		
	EndIf;
	
	ClassificationObjectsSelection = New Array(StrLineCount(StrReplace(ClassificationObjectKeys, ",", Chars.LF)));
	
	IndexOfClassificationObject = 0;
	ClassificationObjectsSelection[IndexOfClassificationObject] = DataSource.DataSource.Select(QueryResultIteration.ByGroups);
	
	While True Do
		
		If ClassificationObjectsSelection[IndexOfClassificationObject] = Undefined Then
			
			// Formation of a new sample.
			ClassificationObjectsSelection[IndexOfClassificationObject] = ClassificationObjectsSelection[IndexOfClassificationObject - 1].Select(QueryResultIteration.ByGroups);
			
		EndIf;
		
		If ClassificationObjectsSelection[IndexOfClassificationObject].Next() Then
			
			If IndexOfClassificationObject = ClassificationObjectsSelection.UBound() Then // The last level.
				
				NewRow = Result.Add();
				FillPropertyValues(NewRow, ClassificationObjectsSelection[IndexOfClassificationObject]);
				
				SamplePeriod = ClassificationObjectsSelection[IndexOfClassificationObject].Select(QueryResultIteration.ByGroups, "Period", "All");
				
				NumberOfPeriods = SamplePeriod.Count();
				AverageValue = ClassificationObjectsSelection[IndexOfClassificationObject][NameOfClassificationParameter] / NumberOfPeriods;
				ClassificationParameterValue = 0;
				
				While SamplePeriod.Next() Do
					
					ClassificationParameterValue = ClassificationParameterValue + Pow((?(SamplePeriod[NameOfClassificationParameter] = Null, 0, SamplePeriod[NameOfClassificationParameter]) - AverageValue), 2);
					
				EndDo;
				
				NewRow[NameOfClassificationParameter] = ?(AverageValue <> 0, Sqrt(ClassificationParameterValue / NumberOfPeriods) * 100 / AverageValue, 0);
				
				If NewRow[NameOfClassificationParameter] < 0 Then // the average could have been negative because of the returns
					NewRow[NameOfClassificationParameter] = - NewRow[NameOfClassificationParameter];
				EndIf;
				
				NewRow.ClassificationParameterValue = NewRow[NameOfClassificationParameter];
				
			Else
				
				// Go to the next level.
				IndexOfClassificationObject = IndexOfClassificationObject + 1;
				
			EndIf;
			
		Else
			
			// At the top level, the recordings ended.
			// Processing is completed.
			If IndexOfClassificationObject = 0 Then
				
				Break;
				
			// Records have ended at the current level.
			// It is necessary to move to the next entry at the previous level.
			Else
			
				ClassificationObjectsSelection[IndexOfClassificationObject] = Undefined;
				IndexOfClassificationObject = IndexOfClassificationObject - 1;
				Continue;
				
			EndIf;
				
		EndIf;
		
	EndDo;
	
	Result.FillValues(Enums.XYZClassification.XClass, "Class");
	
	SortingColumns = "ClassificationSeparator Asc";
	
	ThereIsClassificationSection = False;
	
	If Result.Columns.Find("ClassificationSection") <> Undefined Then
		
		SortingColumns = SortingColumns + ", ClassificationSection Asc";
		ThereIsClassificationSection = True;
		
	EndIf;
	
	SortingColumns = SortingColumns + ", " + NameOfClassificationParameter + " Desc";
	
	If Result.Columns.Find("Products") <> Undefined Then
		
		SortingColumns = SortingColumns + ", Products Asc";
		
		If Result.Columns.Find("Characteristic") <> Undefined Then
			
			SortingColumns = SortingColumns + ", Characteristic Asc";
			
		EndIf;
		
	EndIf;
	
	Result.Sort(SortingColumns, New CompareValues);
	
	ValueOfClassificationParameterTotal = 0;
	ShareOnCumulativeBasis = New Array;
	CurShareOnCumulativeBasis = 0;
	
	IndexOfResultRow = 0;
	OffsetOfResultRow = 0;
	
	While IndexOfResultRow < Result.Count() Do
		
		// The overall result of the separator.
		ValueOfClassificationParameterTotal = ValueOfClassificationParameterTotal + Result[IndexOfResultRow][NameOfClassificationParameter];
		ShareOnCumulativeBasis.Add(Result[IndexOfResultRow][NameOfClassificationParameter]);
		Result[IndexOfResultRow].ClassificationParameterValue = Result[IndexOfResultRow][NameOfClassificationParameter];
		
		// The last row or data on the current separator or classification section has ended.
		If IndexOfResultRow = Result.Count() - 1
			Or Result[IndexOfResultRow].ClassificationSeparator <> Result[IndexOfResultRow + 1].ClassificationSeparator
			Or (ThereIsClassificationSection And Result[IndexOfResultRow].ClassificationSection <> Result[IndexOfResultRow + 1].ClassificationSection) Then
			
			ShareCumulativeTotalAmount = 0;
			
			For IndexOf = 0 To ShareOnCumulativeBasis.UBound() Do
				
				If ValueOfClassificationParameterTotal <> 0 Then
					
					CurShareOnCumulativeBasis = CurShareOnCumulativeBasis + ?(ValueOfClassificationParameterTotal = 0, 0, ShareOnCumulativeBasis[IndexOf] * 100 / ValueOfClassificationParameterTotal);
					
				EndIf;
				
				ShareOnCumulativeBasis[IndexOf] = CurShareOnCumulativeBasis;
				ShareCumulativeTotalAmount = ShareCumulativeTotalAmount + CurShareOnCumulativeBasis;
				
			EndDo;
			
			AverageValue = ShareCumulativeTotalAmount / (ShareOnCumulativeBasis.Count() + 1);
			
			CurrentClass = Enums.XYZClassification.ZClass;
			
			For IndexOf = 0 To ShareOnCumulativeBasis.UBound() - 1 Do
				
				If ShareOnCumulativeBasis[IndexOf] > AverageValue Then
					
					If CurrentClass = Enums.XYZClassification.ZClass Then
						
						CurrentClass = Enums.XYZClassification.YClass;
						
					Else
						
						Break;
						
					EndIf;
					
					AverageValue = ShareCumulativeTotalAmount / (ShareOnCumulativeBasis.Count() - IndexOf);
					
				EndIf;
				
				ShareCumulativeTotalAmount = ShareCumulativeTotalAmount - ShareOnCumulativeBasis[IndexOf];
				Result[OffsetOfResultRow + IndexOf].Class = CurrentClass;
				
			EndDo;
			
			ValueOfClassificationParameterTotal = 0;
			ShareOnCumulativeBasis = New Array;
			CurShareOnCumulativeBasis = 0;
			
			OffsetOfResultRow = IndexOfResultRow + 1;
			
		EndIf;
		
		IndexOfResultRow = IndexOfResultRow + 1;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Checks whether the date is a calendar day off.
// Parameters:
//  CalendarDate - Date - Date to be checked
//  Calendar - CatalogRef.Calendars - the calendar that the check is being performed on
//  CalendarWeekends - Map - previously obtained data on calendar days off.
//
// Returns: 
// Boolean
//  The date is a calendar day off.
//
Function ItSDayOff(CalendarDate, Calendar, CalendarWeekends) Export
	
	CalendarYear = Number(Format(CalendarDate, "DF=yyyy"));
	
	If CalendarWeekends.Get(Calendar) = Undefined Then
		
		CalendarWeekends.Insert(Calendar, New Map);
		CalendarWeekends[Calendar].Insert(CalendarYear, GetCalendarScheduleWeekends(Calendar, CalendarYear));
		
	ElsIf CalendarWeekends[Calendar].Get(CalendarYear) = Undefined Then
		
		CalendarWeekends[Calendar].Insert(CalendarYear, GetCalendarScheduleWeekends(Calendar, CalendarYear));
		
	EndIf;
	
	Return CalendarWeekends[Calendar][CalendarYear].Find(CalendarDate) <> Undefined;
	
EndFunction

// Returns the service level coefficient by reference to the enumeration value
// Parameters:
//		ServiceLevel - EnumRef.ServiceLevels
// Returns:
//		Number
Function GetServiceLevelFactor(ServiceLevel) Export
	
	// These coefficients are still set in the request for a dynamic list of the form of the list of the register of forecastpackages.
	
	If ServiceLevel = Enums.ServiceLevels.ServiceLevel50_0 Then

		Return 0;

	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel57_9 Then
		
		Return 0.2;
        	
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel65_5 Then

		Return 0.4;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel72_6 Then

		Return 0.6;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel78_8 Then

		Return 0.8;
  	
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel84_0 Then
		
		Return 1.0;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel88_5 Then
		
		Return 1.2;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel91_9 Then
		
		Return 1.4;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel94_5 Then
		
		Return 1.6;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel96_4 Then
		
		Return 1.8;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel97_7 Then
		
		Return 2.0;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel98_6 Then
		
		Return 2.2;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel99_2 Then
		
		Return 2.4;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel99_5 Then
		
		Return 2.6;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel99_7 Then
		
		Return 2.8;
		
	ElsIf ServiceLevel = Enums.ServiceLevels.ServiceLevel99_9 Then
		
		Return 3.0;
		
	Else
		
		Return 1.0;
		
	EndIf;
	
EndFunction

Function GetCalendarScheduleWeekends(Calendar, CalendarYear)
	
	Query = New Query(
	"SELECT
	|	CalendarSchedules.ScheduleDate AS CalendarDate
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.Calendar = &Calendar
	|	AND CalendarSchedules.Year = &CalendarYear
	|	AND (NOT CalendarSchedules.DayAddedToSchedule)");;
	
	Query.SetParameter("Calendar", Calendar);
	Query.SetParameter("CalendarYear", CalendarYear);
	
	Return Query.Execute().Unload().UnloadColumn("CalendarDate");
	
EndFunction

Procedure UpdatePartnerClassificationData(ClassificationResult, ClassificationType, ClassificationParameterType, ClassificationPeriod, NotClassified)

	If ClassificationResult.Columns.Find("Period") = Undefined Then

		ClassificationResult.Columns.Add("Period");

	EndIf;

	If ClassificationResult.Columns.Find("ClassificationParameterType") = Undefined Then

		ClassificationResult.Columns.Add("ClassificationParameterType");

	EndIf;

	If ClassificationResult.Columns.Find("ClassificationType") = Undefined Then

		ClassificationResult.Columns.Add("ClassificationType");

	EndIf;

	ClassificationResult.FillValues(ClassificationPeriod, "Period");
	ClassificationResult.FillValues(ClassificationParameterType, "ClassificationParameterType");
	ClassificationResult.FillValues(ClassificationType, "ClassificationType");

	RecordSet = InformationRegisters.ABCXYZCustomerClassification.CreateRecordSet();
	RecordSet.Filter.Period.Set(ClassificationPeriod);
	RecordSet.Filter.ClassificationType.Set(ClassificationType);
	RecordSet.Filter.ClassificationParameterType.Set(ClassificationParameterType);

	RecordSet.Load(ClassificationResult);
	RecordSet.Write(True);

	Query = New Query(
		"SELECT
		|	BEGINOFPERIOD(&ClassificationPeriod, DAY) AS Period,
		|	ABCXYZCustomerClassificationSliceLast.Partner AS Partner,
		|	ABCXYZCustomerClassificationSliceLast.ClassificationParameterType AS ClassificationParameterType,
		|	ABCXYZCustomerClassificationSliceLast.ClassificationType AS ClassificationType,
		|	&NotClassified AS Class,
		|	0 AS ClassificationParameterValue
		|FROM
		|	InformationRegister.ABCXYZCustomerClassification.SliceLast(
		|			DATEADD(&ClassificationPeriod, SECOND, -1),
		|			(NOT Partner IN
		|						(SELECT
		|							ABCXYZCustomerClassification.Partner AS Partner
		|						FROM
		|							InformationRegister.ABCXYZCustomerClassification AS ABCXYZCustomerClassification
		|						WHERE
		|							ABCXYZCustomerClassification.Period = BEGINOFPERIOD(&ClassificationPeriod, DAY)
		|							AND ABCXYZCustomerClassification.ClassificationParameterType = &ClassificationParameterType
		|							AND ABCXYZCustomerClassification.ClassificationType = &ClassificationType))
		|				AND ClassificationParameterType = &ClassificationParameterType
		|				AND ClassificationType = &ClassificationType) AS ABCXYZCustomerClassificationSliceLast");

	Query.SetParameter("ClassificationPeriod", ClassificationPeriod);
	Query.SetParameter("ClassificationType", ClassificationType);
	Query.SetParameter("ClassificationParameterType", ClassificationParameterType);
	Query.SetParameter("NotClassified", NotClassified);

	QueryResult = Query.Execute();

	If Not QueryResult.IsEmpty() Then

		RecordSet.Load(QueryResult.Unload());
		RecordSet.Write(False);

	EndIf;

EndProcedure

Procedure UpdateProductClassificationData(ClassificationResult, ClassificationType, ClassificationParameterType, ClassificationPeriod, NotClassified)
	
	If ClassificationResult.Columns.Find("Period") = Undefined Then
		ClassificationResult.Columns.Add("Period");
	EndIf;
	
	If ClassificationResult.Columns.Find("ClassificationParameterType") = Undefined Then
		ClassificationResult.Columns.Add("ClassificationParameterType");
	EndIf;
	
	If ClassificationResult.Columns.Find("ClassificationType") = Undefined Then
		ClassificationResult.Columns.Add("ClassificationType");
	EndIf;
	
	ClassificationResult.FillValues(ClassificationPeriod, 		"Period");
	ClassificationResult.FillValues(ClassificationParameterType, "ClassificationParameterType");
	ClassificationResult.FillValues(ClassificationType, 			"ClassificationType");

	RecordSet = InformationRegisters.ABCXYZInventoryClassification.CreateRecordSet();
	RecordSet.Filter.Period.Set(ClassificationPeriod);
	RecordSet.Filter.ClassificationType.Set(ClassificationType);
	RecordSet.Filter.ClassificationParameterType.Set(ClassificationParameterType);

	RecordSet.Load(ClassificationResult);
	RecordSet.Write(True);
	
	Query = New Query(
	"SELECT
	|	ABCXYZInventoryClassification.Products AS Products,
	|	ABCXYZInventoryClassification.Characteristic AS Characteristic,
	|	ABCXYZInventoryClassification.ClassificationSection AS ClassificationSection
	|INTO ClassificationResult
	|FROM
	|	InformationRegister.ABCXYZInventoryClassification AS ABCXYZInventoryClassification
	|WHERE
	|	ABCXYZInventoryClassification.Period = BEGINOFPERIOD(&ClassificationPeriod, DAY)
	|	AND ABCXYZInventoryClassification.ClassificationParameterType = &ClassificationParameterType
	|	AND ABCXYZInventoryClassification.ClassificationType = &ClassificationType
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	ClassificationSection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BEGINOFPERIOD(&ClassificationPeriod, DAY) AS Period,
	|	ABCXYZInventoryClassificationSliceLast.Products AS Products,
	|	ABCXYZInventoryClassificationSliceLast.Characteristic AS Characteristic,
	|	ABCXYZInventoryClassificationSliceLast.ClassificationSection AS ClassificationSection,
	|	ABCXYZInventoryClassificationSliceLast.ClassificationParameterType AS ClassificationParameterType,
	|	ABCXYZInventoryClassificationSliceLast.ClassificationType AS ClassificationType,
	|	&NotClassified AS Class,
	|	0 AS ClassificationParameterValue
	|FROM
	|	InformationRegister.ABCXYZInventoryClassification.SliceLast(
	|			DATEADD(&ClassificationPeriod, SECOND, -1),
	|			(NOT (Products, Characteristic, ClassificationSection) IN
	|						(SELECT
	|							ClassificationResult.Products AS Products,
	|							ClassificationResult.Characteristic AS Characteristic,
	|							ClassificationResult.ClassificationSection AS ClassificationSection
	|						FROM
	|							ClassificationResult AS ClassificationResult))
	|				AND ClassificationParameterType = &ClassificationParameterType
	|				AND ClassificationType = &ClassificationType) AS ABCXYZInventoryClassificationSliceLast");
	
	Query.SetParameter("ClassificationPeriod", 		ClassificationPeriod);
	Query.SetParameter("ClassificationType", 			ClassificationType);
	Query.SetParameter("ClassificationParameterType", 	ClassificationParameterType);
	Query.SetParameter("NotClassified", 			NotClassified);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		RecordSet.Load(QueryResult.Unload());
		RecordSet.Write(False);
		
	EndIf;
	
EndProcedure

#EndRegion
