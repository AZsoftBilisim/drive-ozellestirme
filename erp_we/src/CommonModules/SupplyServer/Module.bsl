////////////////////////////////////////////////////////////////////////////////
// The "Provisioning Server" module contains procedures and functions for
// working with the provision of needs and updating relevant data.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Supplements the request with the parameters necessary for executing the request for calculating consumption statistics,
//
// Parameters:
//   Query - Query - request containing the text for calculating consumption statistics
//   ClassificationPeriod - StandardPeriod - the period for which you want to calculate statistics.
//
Procedure SetParametersForStatisticsCalculationRequest(Query, ClassificationPeriod = Undefined) Export
	
	If ClassificationPeriod = Undefined Then
		Periodicity = Constants.PeriodOfGoodsLimitationCalculation.Get();
		NumberOfClassificationPeriods = Constants.NumberOfCommercialRestrictionCalculationPeriods.Get();
		ClassificationPeriod = TMCommonUseClientServer.ExtendedPeriod(CurrentSessionDate(),
			Periodicity, - NumberOfClassificationPeriods);
	Else
		Periodicity = Enums.Periodicity.Day;
		NumberOfClassificationPeriods = (ClassificationPeriod.EndDate - ClassificationPeriod.StartDate + 1) / 86400;
	EndIf;
	PayrollPeriod = TMCommonUseClientServer.ExtendedPeriod(CurrentSessionDate(), Periodicity);
	
	Query.SetParameter("ClassificationPeriodStartDate",    ClassificationPeriod.StartDate);
	Query.SetParameter("ClassificationPeriodEndDate", ClassificationPeriod.EndDate);
	Query.SetParameter("NumberOfClassificationPeriods",  NumberOfClassificationPeriods);
	Query.SetParameter("BillingPeriodStartDate",        PayrollPeriod.StartDate);
	Query.SetParameter("BillingPeriodEndDate",     PayrollPeriod.EndDate);
	
	Query.SetParameter("OptimizeDistributionCenterInventory",
		GetFunctionalOption("UseAdvancedDemandFulfillment")
			And Constants.OptimizeDistributionCenterInventory.Get());
	
EndProcedure

// Returns a temporary table with the statistics of consumption (Unstatistically).
//
// Parameters:
//  Query - Query - A request containing the parameters needed to calculate the statistics. This same query is added to the calculation result
//                    "Unstatistically".
//  NameOfProductsTable - String - The name of a temporary table with the products, default: "Towary".
//
Procedure AddTemporaryTableOfConsumptionStatistics(Query, NameOfProductsTable) Export
	
	CalculateSeasonalityByProductCategories =
		GetFunctionalOption("UseAdvancedDemandFulfillment")
			And Constants.SeasonalFluctuationsRegistrationOption.Get()
				= Enums.SeasonalFluctuationsAccounting.BySamePeriodOfLastYear;
	
	If Not CalculateSeasonalityByProductCategories Then
		
		EnergyConsumptionStatistics(Query, NameOfProductsTable, "TTConsumptionStatistics");
		
	Else
		
		// Input: <Product Name>
		// Output:
		// Commodity categories: Warehouse,Nomenclature,Characteristic - Commodity category
		AddTemporaryTableProductCategories(Query, NameOfProductsTable);
		
		Text =
			"SELECT
			|	Goods.Warehouse          AS Warehouse,
			|	Goods.Products   AS Products,
			|	Goods.Characteristic AS Characteristic
			|INTO ProductsCurPeriod
			|FROM
			|	GoodsOverridable AS Goods
			|WHERE
			|	Goods.Products.ProductCategory = VALUE(Catalog.ProductCategories.EmptyRef)
			|
			|UNION ALL
			|
			|SELECT
			|	Goods.Warehouse          AS Warehouse,
			|	Goods.Products   AS Products,
			|	Goods.Characteristic AS Characteristic
			|FROM
			|	ProductCategories AS Goods
			|;
			|
			|///////////////////////////////////////////////////////
			|SELECT
			|	Goods.Warehouse          AS Warehouse,
			|	Goods.Products   AS Products,
			|	Goods.Characteristic AS Characteristic
			|INTO ProductsLastPeriod
			|FROM
			|	GoodsOverridable AS Goods
			|WHERE
			|	Goods.Products.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)";
		
		Query.Text = StrReplace(Text, "GoodsOverridable", NameOfProductsTable);
		Query.Execute();
		
		ClassificationPeriodStartDate = Query.Parameters.ClassificationPeriodStartDate;
		ClassificationPeriodEndDate = Query.Parameters.ClassificationPeriodEndDate;
		
		EnergyConsumptionStatistics(Query, "ProductsCurPeriod", "ConsumptionStatisticsForCurPeriod");
		
		Query.SetParameter("ClassificationPeriodStartDate",    AddMonth(ClassificationPeriodStartDate, - 12));
		Query.SetParameter("ClassificationPeriodEndDate", AddMonth(ClassificationPeriodEndDate, - 12));
		
		EnergyConsumptionStatistics(Query, "ProductCategories", "ConsumptionStatisticsLastPeriod");
		
		Query.SetParameter("ClassificationPeriodStartDate",    AddMonth(Query.Parameters.BillingPeriodStartDate, - 12));
		Query.SetParameter("ClassificationPeriodEndDate", AddMonth(Query.Parameters.BillingPeriodEndDate, - 12));
		
		EnergyConsumptionStatistics(Query, "ProductsLastPeriod", "ConsumptionStatisticsLastBillingPeriod");
		
		Query.SetParameter("ClassificationPeriodStartDate",    ClassificationPeriodStartDate);
		Query.SetParameter("ClassificationPeriodEndDate", ClassificationPeriodEndDate);
		
		Query.Text =
			"SELECT
			|	ConsumptionStatistics.Products.ProductCategory  AS ProductCategory,
			|	ConsumptionStatistics.Warehouse                           AS Warehouse,
			|	SUM(ConsumptionStatistics.AverageDailyConsumption) AS AverageDailyConsumption
			|INTO StatisticsByCategoryCurPeriod
			|FROM
			|	ConsumptionStatisticsForCurPeriod AS ConsumptionStatistics
			|WHERE
			|	ConsumptionStatistics.Products.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
			|GROUP BY
			|	ConsumptionStatistics.Products.ProductCategory,
			|	ConsumptionStatistics.Warehouse
			|INDEX BY
			|	ProductCategory, Warehouse
			|
			|;
			|/////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ConsumptionStatistics.Products.ProductCategory  AS ProductCategory,
			|	ConsumptionStatistics.Warehouse                           AS Warehouse,
			|	SUM(ConsumptionStatistics.AverageDailyConsumption) AS AverageDailyConsumption
			|INTO StatisticsByCategoryPastPeriod
			|FROM
			|	ConsumptionStatisticsLastPeriod AS ConsumptionStatistics
			|WHERE
			|	ConsumptionStatistics.Products.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
			|GROUP BY
			|	ConsumptionStatistics.Products.ProductCategory,
			|	ConsumptionStatistics.Warehouse
			|INDEX BY
			|	ProductCategory, Warehouse
			|
			|;
			|/////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Goods.Products                                             AS Products,
			|	Goods.Characteristic                                           AS Characteristic,
			|	Goods.Warehouse                                                    AS Warehouse,
			|	&ClassificationPeriodStartDate                                  AS BeginningDateOfPeriod,
			|	&ClassificationPeriodEndDate                               AS EndingDateOfPeriod,
			|	ConsumptionStatistics.Consumption                               AS Consumption,
			|	ConsumptionStatistics.AverageDailyConsumption                  AS AverageDailyConsumption,
			|	ConsumptionStatistics.VarianceOfConsumption                      AS VarianceOfConsumption,
			|	ConsumptionStatistics.ConsumptionIsStable                      AS ConsumptionIsStable
			|INTO TTConsumptionStatistics
			|FROM
			|	GoodsOverridable AS Goods
			|		
			|		LEFT JOIN ConsumptionStatisticsForCurPeriod AS ConsumptionStatistics
			|		ON Goods.Products   = ConsumptionStatistics.Products
			|		 AND Goods.Characteristic = ConsumptionStatistics.Characteristic
			|		 AND Goods.Warehouse          = ConsumptionStatistics.Warehouse
			|		 AND ConsumptionStatistics.Products.ProductCategory = VALUE(Catalog.ProductCategories.EmptyRef)
			|WHERE
			|	NOT ConsumptionStatistics.Products IS NULL
			|
			|UNION ALL
			|
			|SELECT
			|	Goods.Products                                                            AS Products,
			|	Goods.Characteristic                                                          AS Characteristic,
			|	Goods.Warehouse                                                                   AS Warehouse,
			|	DATEADD(&BillingPeriodStartDate, MONTH, -12)                          AS BeginningDateOfPeriod,
			|	DATEADD(&BillingPeriodEndDate, MONTH, -12)                       AS EndingDateOfPeriod,
			|	ConsumptionStatistics.Consumption                                              AS Consumption,
			|	ConsumptionStatistics.AverageDailyConsumption
			|		* CASE WHEN ISNULL(StatisticsByCategoryPastPeriod.AverageDailyConsumption, 0) = 0 THEN
			|					1
			|				ELSE
			|					ISNULL(StatisticsByCategoryCurPeriod.AverageDailyConsumption, 0)
			|						/ StatisticsByCategoryPastPeriod.AverageDailyConsumption
			|			END                                                                  AS AverageDailyConsumption,
			|	ConsumptionStatistics.VarianceOfConsumption                                     AS VarianceOfConsumption,
			|	ConsumptionStatistics.ConsumptionIsStable                                     AS ConsumptionIsStable
			|FROM
			|	GoodsOverridable AS Goods
			|		
			|		LEFT JOIN ConsumptionStatisticsLastBillingPeriod AS ConsumptionStatistics
			|		ON Goods.Products   = ConsumptionStatistics.Products
			|		 AND Goods.Characteristic = ConsumptionStatistics.Characteristic
			|		 AND Goods.Warehouse          = ConsumptionStatistics.Warehouse
			|		
			|		LEFT JOIN StatisticsByCategoryCurPeriod AS StatisticsByCategoryCurPeriod
			|		ON Goods.Products.ProductCategory = StatisticsByCategoryCurPeriod.ProductCategory
			|		 AND Goods.Warehouse                          = StatisticsByCategoryCurPeriod.Warehouse
			|		
			|		LEFT JOIN StatisticsByCategoryPastPeriod AS StatisticsByCategoryPastPeriod
			|		ON Goods.Products.ProductCategory = StatisticsByCategoryPastPeriod.ProductCategory
			|		 AND Goods.Warehouse                          = StatisticsByCategoryPastPeriod.Warehouse
			|WHERE
			|	NOT ConsumptionStatistics.Products IS NULL
			|;
			|
			|///////////////////////////////////////////////////////////////////////////
			|DROP ConsumptionStatisticsForCurPeriod;
			|DROP ConsumptionStatisticsLastPeriod;
			|DROP StatisticsByCategoryCurPeriod;
			|DROP StatisticsByCategoryPastPeriod;
			|DROP ProductsCurPeriod;
			|DROP ProductCategories";
		Query.Text = StrReplace(Query.Text, "GoodsOverridable", NameOfProductsTable);
		
		Query.Execute();
		
	EndIf;
	
EndProcedure

// Combines data from a collection and a table and puts it in the collection.
//
// Parameters:
//  Collection - FormDataCollection - Collection with data sorted by key fields,
//  Table - ValueTable - Contains data to add to the collection, sorted by key fields,
//  String_Key - String - Fields that are used to search for a row in the collection,
//              to make a decision about updating an existing row in the collection or adding a new one,
//  Parameters - Structure - contains settings for the Association.
//
Procedure UpdateCollectionWithDataFromTable(Collection, Table, String_Key, Parameters = Undefined) Export

	If Parameters = Undefined Then
		Parameters = SupplyClientServer.TableJoinParameters();
	EndIf;

	If Parameters.AddLines_ Then
		Parameters.NewLines      = Collection.CopyColumns();
		Parameters.ModifiedRows = Collection.CopyColumns();
	EndIf;

	KeyFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(String_Key);
	ReceiverIndex = 0;
	IndexOf = 0;
	CompareValues = New CompareValues();
	While IndexOf < Table.Count() Do

		String = Table[IndexOf];

		If ReceiverIndex < Collection.Count() Then

			DestinationRow = Collection[ReceiverIndex];

			KeyComparisonResult = 0;
			For Each Field In KeyFields Do

				FieldComparisonResult = CompareValues.Compare(String[Field], DestinationRow[Field]);
				If FieldComparisonResult < 0 Then
					KeyComparisonResult = -1;
					Break;
				ElsIf FieldComparisonResult > 0 Then
					KeyComparisonResult = 1;
					Break;
				EndIf;

			EndDo;

		Else
			KeyComparisonResult = 1;
		EndIf;

		If KeyComparisonResult < 0 Then

			If Parameters.AddLines_ Then
				NewRow = Parameters.NewLines.Add();
				FillPropertyValues(NewRow, String);
			EndIf;

			IndexOf = IndexOf + 1;

		ElsIf KeyComparisonResult = 0 Then

			If Parameters.AddLines_ Then
				NewRow = Parameters.ModifiedRows.Add();
				FillPropertyValues(NewRow, DestinationRow);
				FillPropertyValues(NewRow, String);
			ElsIf Parameters.UpdateRows Then
				FillPropertyValues(DestinationRow, String);
				ReceiverIndex = ReceiverIndex + 1;
			EndIf;

			IndexOf = IndexOf + 1;

		// Resultsreferences of the key > 0
		ElsIf ReceiverIndex < Collection.Count() Then

			If Parameters.Defaults <> Undefined Then

				FillPropertyValues(DestinationRow, Parameters.Defaults);

				If Parameters.AddLines_ Then
					NewRow = Parameters.ModifiedRows.Add();
					FillPropertyValues(NewRow, String);
				EndIf;

			EndIf;

			ReceiverIndex = ReceiverIndex + 1;

		Else

			If Parameters.AddLines_ Then
				NewRow = Parameters.NewLines.Add();
				FillPropertyValues(NewRow, String);
			EndIf;

			IndexOf = IndexOf + 1;

		EndIf;

	EndDo;

EndProcedure

// It is used for splitting a table of values into several tables based on combinations of values in the key fields of the table.
//
// Parameters:
//   Table            - ValueTable      - a table that needs to be split into several tables.
//   KeyFields          - String               - names of table columns that form the table row key.
//   KeyFieldsToDelete - String, Undefined - the names of the columns from the key that you want to delete
//                                               from the resulting split tables.
// Returns:
//  Array of Structure:
//    * Key    - Structure       - a structure with fields whose names are passed in the "key Fields" parameter.
//                                  Contains a combination of field values of the table passed by the "table" parameter.
//    * Table - ValueTable - a table with fields that match the fields of the table passed in the "table" parameter
//                                  does not contain fields whose names are passed in the "keyfields to Delete"parameter.
//                                  Contains a copy of the table rows passed by the "table" parameter, selected by
//                                  the field values listed in the "Key" structure.
//
Function SplitTableByKeyValue(Table, KeyFields, KeyFieldsToDelete = Undefined) Export

	Var_Key = New Structure(KeyFields);
	FieldsToDelete = New Structure(?(KeyFieldsToDelete = Undefined, KeyFields, KeyFieldsToDelete));

	KeylessTable = Table.CopyColumns();
	For Each Property In FieldsToDelete Do
		KeylessTable.Columns.Delete(Property.Key);
	EndDo;

	ArrayOfTables = New Array();

	For Counter = 0 To Table.Count() - 1 Do

		FillingData = Table[Counter];
		If KeyChanged(Var_Key, FillingData) Then

			Var_Key = New Structure(KeyFields);
			KeylessTable = KeylessTable.CopyColumns();
			ArrayOfTables.Add(New Structure("Key, Table", Var_Key, KeylessTable));
			FillPropertyValues(Var_Key, FillingData);

		EndIf;

		NewRow = KeylessTable.Add();
		FillPropertyValues(NewRow, FillingData);

	EndDo;

	Return ArrayOfTables;

EndFunction

// Checks the key for changes.
//
// Parameters:
//   Var_Key              - Structure                                                     - contains previously set
//                                                                                       key values.
//   RowToValidate - FormDataCollectionItem, ValueTableRow, Structure - data containing the current
//                                                                                       key values.
// 
// Returns:
//   Boolean - a sign that the key has changed.
//
Function KeyChanged(Var_Key, RowToValidate) Export
	
	For Each Property In Var_Key Do
	
		If RowToValidate[Property.Key] <> Property.Value Then
			Return True;
		EndIf;
	
	EndDo;
	
	Return False;

EndFunction

#EndRegion

#Region Internal

Procedure UseControlOfMovementOfSeparateGoodsToCalculateAndWrite() Export
	
	Query = New Query();
	Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.CostAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Constant.AllowAssignmentOfGoodsBeyondDemand AS AllowAssignmentOfGoodsBeyondDemand
		|WHERE
		|	AllowAssignmentOfGoodsBeyondDemand.Value
		|
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Constant.UseTollManufacturing2_5 AS UseTollManufacturing2_5
		|WHERE
		|	UseTollManufacturing2_5.Value
		|;
		|/////////////////////////////////////////////
		|SELECT
		|	1
		|FROM
		|	Constant.UseGoodsTransfer AS UseGoodsTransfer
		|WHERE
		|	UseGoodsTransfer.Value
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Constant.UseProductionManagement2_2 AS UseProductionManagement2_2
		|WHERE
		|	UseProductionManagement2_2.Value";
		
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.UseManageTransferOfGoodsAssigned");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		ResultsPackage = Query.ExecuteBatch();
		
		ValueToSet = Not ResultsPackage[0].IsEmpty() And Not ResultsPackage[1].IsEmpty();
		ManagerOfConstant = Constants.UseManageTransferOfGoodsAssigned.CreateValueManager();
		ManagerOfConstant.Read();
		If ManagerOfConstant.Value <> ValueToSet Then
			ManagerOfConstant.Value = ValueToSet;
			ManagerOfConstant.AdditionalProperties.Insert("ConstantIsCalculatedAfterLocking", True);
			ManagerOfConstant.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise NStr("vi = 'Không thể ghi lại giá trị hằng ""Sử dụng quản lý điều chuyển hàng hóa đặt riêng""';
					|ru = 'Не удалось записать значение константы ""Использовать управление перемещением обособленных товаров""';
					|en = 'Cannot save ""Use management of assigned goods transfer"" constant value'; fa = 'Cannot save ""Use management of assigned goods transfer"" constant value';
					|it = 'Impossibile salvare il valore della costante ""Utilizzare gestione della movimentazione merci separate""';
					|pl = 'Nie udało się zapisać wartości stałej ""Używaj sterowania przemieszczeniem odrębnych wierszy pozycji""';
					|tr = '""Ayrıştırılmış ürün hareketi kontrolünü kullan"" sabitinin değeri kaydedilmedi'");
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function PartnerSTermsOfPurchase(Partner, Price = 0) Export

	Result = New Structure();
	
	CurrencyOfManAccounting_ = Constants.ManagementAccountingCurrency.Get();
	Result.Insert("Terms",             Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
	Result.Insert("Currency",                 CurrencyOfManAccounting_);
	Result.Insert("Price",                   Price);
	Result.Insert("MinimumOrderAmount", 0);
	Result.Insert("VendorPriceKind",      Catalogs.VendorPriceTypes.EmptyRef());
	
	PurchaseConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner);
	If PurchaseConditions <> Undefined And ValueIsFilled(PurchaseConditions.Terms) Then
		
		Result.Terms             = PurchaseConditions.Terms;
		Result.Currency                 = PurchaseConditions.Currency;
		Result.VendorPriceKind      = PurchaseConditions.VendorPriceKind;
		Result.MinimumOrderAmount = PurchaseConditions.MinimumOrderAmount;
		
		If Price <> 0 Then
			
			ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
				CurrencyOfManAccounting_, PurchaseConditions.Currency, CurrentSessionDate());
			Result.Price = Result.Price * ZoomRatio;
			
		EndIf;
		
	EndIf;

	Return Result;

EndFunction

// The function of the rightaccessorescription of the method or method. Gets the right to change/add to the logistics registers.
// In particular, it is used when setting up forms for working with logistics parameters.
// 
// Returns:
//  Structure - structure with the following fields:
//   * SupplyOptions - Boolean - true, if there are the necessary rights to the registers "Product supply options", "Work supply options".
//	 * ProductRestrictions - Boolean - true if there are the necessary rights to the "Commodity restrictions" register.
//
Function WriteAccessRightsForMethodOrMethod() Export
	
	Result = New Structure("SupplyOptions, ProductRestrictions");
	Result.SupplyOptions = AccessRight("Update", Metadata.InformationRegisters.GoodsProcurementStrategy)
		And AccessRight("Update", Metadata.InformationRegisters.WorksProcurementStrategy);
	Result.ProductRestrictions = AccessRight("Update", Metadata.InformationRegisters.ProductRestrictions);
	Return Result;
	
EndFunction

// Method of routine task calculation of recommendations for maintaining Supplies.
// Calculates consumption statistics and recommendations for changing the maintenance of inventory in warehouses.
//
Procedure CalculationOfStockReplenishmentRecommendations() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CalculationOfStockReplenishmentRecommendations);
	
	ClassificationPeriod = Constants.PeriodOfGoodsLimitationCalculation.Get();
	NumberOfClassificationPeriods = Constants.NumberOfCommercialRestrictionCalculationPeriods.Get();
	Period = TMCommonUseClientServer.ExtendedPeriod(
		CurrentSessionDate(), ClassificationPeriod, - NumberOfClassificationPeriods);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
		"SELECT
		|	ProductRestrictions.Products AS Products,
		|	ProductRestrictions.Characteristic AS Characteristic,
		|	ProductRestrictions.Warehouse AS Warehouse
		|INTO TTProducts_1
		|FROM
		|	InformationRegister.ProductRestrictions AS ProductRestrictions
		|WHERE
		|	ProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND (ProductRestrictions.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			OR ProductRestrictions.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse))
		|
		|UNION
		|
		|SELECT
		|	GoodsInWarehousesTurnover.Products,
		|	GoodsInWarehousesTurnover.Characteristic,
		|	GoodsInWarehousesTurnover.Warehouse
		|FROM
		|	AccumulationRegister.ProductStock.Turnovers(&StartDate, &EndDate, , ) AS GoodsInWarehousesTurnover";
	
	Query.SetParameter("StartDate", Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	InformationRegisters.ProductRestrictions.CalculateStatisticsOfConsumptionOfGoods(Query.TempTablesManager);
	
EndProcedure

Procedure CalculationOfStockMaintenanceRecommendations(Parameters, StorageAddress) Export
	
	ClassificationPeriod = Constants.PeriodOfGoodsLimitationCalculation.Get();
	NumberOfClassificationPeriods = Constants.NumberOfCommercialRestrictionCalculationPeriods.Get();
	Period = TMCommonUseClientServer.ExtendedPeriod(
		CurrentSessionDate(), ClassificationPeriod, - NumberOfClassificationPeriods);
		
	UpdateDate = ?(Parameters.Property("UpdateDate"), Parameters.UpdateDate, Period.EndDate);
		
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
		"SELECT
		|	ProductsForRecommendations.Products AS Products,
		|	ProductsForRecommendations.Characteristic AS Characteristic,
		|	ProductsForRecommendations.Warehouse AS Warehouse
		|INTO TTProducts_1
		|FROM
		|	(SELECT
		|		ProductRestrictions.Products AS Products,
		|		ProductRestrictions.Characteristic AS Characteristic,
		|		ProductRestrictions.Warehouse AS Warehouse,
		|		ProductRestrictions.RecommendationCalculationDate AS RecommendationCalculationDate
		|	FROM
		|		InformationRegister.ProductRestrictions AS ProductRestrictions
		|	WHERE
		|		ProductRestrictions.Warehouse = &Warehouse
		|		AND ProductRestrictions.Products <> VALUE(Catalog.Products.EmptyRef)
		|		AND (ProductRestrictions.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|				OR ProductRestrictions.Products.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsInWarehousesTurnover.Products,
		|		GoodsInWarehousesTurnover.Characteristic,
		|		GoodsInWarehousesTurnover.Warehouse,
		|		DATETIME(1, 1, 1)
		|	FROM
		|		AccumulationRegister.ProductStock.Turnovers(&StartDate, &EndDate, , Warehouse = &Warehouse) AS GoodsInWarehousesTurnover) AS ProductsForRecommendations
		|
		|GROUP BY
		|	ProductsForRecommendations.Products,
		|	ProductsForRecommendations.Warehouse,
		|	ProductsForRecommendations.Characteristic
		|
		|HAVING
		|	MAX(ProductsForRecommendations.RecommendationCalculationDate) < &UpdateDate";
	
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	Query.SetParameter("StartDate",    Period.StartDate);
	Query.SetParameter("EndDate", Period.EndDate);
	Query.SetParameter("UpdateDate", UpdateDate);
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	InformationRegisters.ProductRestrictions.CalculateStatisticsOfConsumptionOfGoods(Query.TempTablesManager);
	
EndProcedure

Procedure UseNonOrderingAssignmentsToCalculateAndWrite() Export
	
	Query = New Query();
	Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.CostAccounting
		|
		|
		|UNION ALL
		|
		|SELECT
		|	1
		|FROM
		|	Constant.UseTollManufacturing2_5 AS UseTollManufacturing2_5
		|WHERE
		|	UseTollManufacturing2_5.Value
		|
		|;
		|/////////////////////////////////////////////
		|SELECT
		|	1
		|FROM
		|	Constant.UseOrderSupplyWithAssignment AS UseOrderSupplyWithAssignment
		|WHERE
		|	UseOrderSupplyWithAssignment.Value";
		
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.UseAssignmentsWithoutOrder");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		ResultsPackage = Query.ExecuteBatch();
		
		ValueToSet = Not ResultsPackage[0].IsEmpty() And Not ResultsPackage[1].IsEmpty();
		ManagerOfConstant = Constants.UseAssignmentsWithoutOrder.CreateValueManager();
		ManagerOfConstant.Read();
		If ManagerOfConstant.Value <> ValueToSet Then
			ManagerOfConstant.Value = ValueToSet;
			ManagerOfConstant.AdditionalProperties.Insert("ConstantIsCalculatedAfterLocking", True);
			ManagerOfConstant.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise NStr("vi = 'Không thể ghi lại giá trị hằng ""Sử dụng mục đích mà không có đơn hàng""';
					|ru = 'Не удалось записать значение константы ""Использовать назначения без заказа""';
					|en = 'Cannot save ""Use assignments without order"" constant value'; fa = 'Cannot save ""Use assignments without order"" constant value';
					|it = 'Impossibile salvare valore della costante ""Utilizzare assegnazione senza ordine""';
					|pl = 'Nie udało się zapisać wartości stałej ""Używaj przeznaczenia bez zamówienia""';
					|tr = '""Atamaları siparişsiz kullan"" sabitinin değeri kaydedilmedi'");
	EndTry;
	
EndProcedure

Procedure NotUseNonOrderingAssignmentsToCalculateAndWrite() Export
	
	Query = New Query();
	Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.LinesOfBusiness AS LinesOfBusiness
		|WHERE
		|	LinesOfBusiness.CostAccounting
		|
		|;
		|/////////////////////////////////////////////
		|SELECT
		|	1
		|FROM
		|	Constant.UseOrderSupplyWithAssignment AS UseOrderSupplyWithAssignment
		|WHERE
		|	UseOrderSupplyWithAssignment.Value";
		
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.NotUseAssignmentsWithoutOrder");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		ResultsPackage = Query.ExecuteBatch();
		
		ValueToSet = ResultsPackage[0].IsEmpty() Or ResultsPackage[1].IsEmpty();
		ManagerOfConstant = Constants.NotUseAssignmentsWithoutOrder.CreateValueManager();
		ManagerOfConstant.Read();
		If ManagerOfConstant.Value <> ValueToSet Then
			ManagerOfConstant.Value = ValueToSet;
			ManagerOfConstant.AdditionalProperties.Insert("ConstantIsCalculatedAfterLocking", True);
			ManagerOfConstant.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise NStr("vi = 'Không thể ghi lại giá trị hằng ""Không sử dụng mục đích mà không có đơn hàng""';
					|ru = 'Не удалось записать значение константы ""Не использовать назначения без заказа""';
					|en = 'Cannot save ""Do not use assignments without order"" constant value'; fa = 'Cannot save ""Do not use assignments without order"" constant value';
					|it = 'Impossibile salvare valore della costante ""Non utilizzare assegnazione senza ordine""';
					|pl = 'Nie udało się zapisać wartości stałej ""Nie używaj przeznaczenia bez zamówienia""';
					|tr = '""Atamaları siparişsiz kullanma"" sabitinin değeri kaydedilmedi'");
	EndTry;
	
EndProcedure

Procedure DoNotUseNonOrderAssignmentsComputeAndWriteByInversion() Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("Constant.NotUseAssignmentsWithoutOrder");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		ValueToSet = Not Constants.UseAssignmentsWithoutOrder.Get();
		ManagerOfConstant = Constants.NotUseAssignmentsWithoutOrder.CreateValueManager();
		ManagerOfConstant.Read();
		If ManagerOfConstant.Value <> ValueToSet Then
			ManagerOfConstant.Value = ValueToSet;
			ManagerOfConstant.AdditionalProperties.Insert("ConstantIsCalculatedAfterLocking", True);
			ManagerOfConstant.Write();
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise NStr("vi = 'Không thể ghi lại giá trị hằng ""Không sử dụng mục đích mà không có đơn hàng""';
					|ru = 'Не удалось записать значение константы ""Не использовать назначения без заказа""';
					|en = 'Cannot save ""Do not use assignments without order"" constant value'; fa = 'Cannot save ""Do not use assignments without order"" constant value';
					|it = 'Impossibile salvare valore della costante ""Non utilizzare assegnazione senza ordine""';
					|pl = 'Nie udało się zapisać wartości stałej ""Nie używaj przeznaczenia bez zamówienia""';
					|tr = '""Atamaları siparişsiz kullanma"" sabitinin değeri kaydedilmedi'");
	EndTry;
		
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Private

Procedure AddTemporaryWarehouseTopologyTables(Query, NameOfProductsTable)
	
	QueriesTexts = New Array();
	
	QueriesTexts.Add(Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False));
	Text =
		"SELECT DISTINCT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic
		|INTO DifferentProducts
		|FROM
		|	GoodsOverridable AS Goods
		|WHERE
		|	&OptimizeDistributionCenterInventory";
	Text = StrReplace(Text, "GoodsOverridable", NameOfProductsTable);
	QueriesTexts.Add(Text);
	Query.Text = StrConcat(QueriesTexts);
	Query.Execute();
	
	InformationRegisters.SupplySchemes.TemporaryTableWarehouseTopology(Query, "DifferentProducts");
	
	QueriesTexts = New Array();
	QueriesTexts.Add("DROP TTWarehouseFormats");
	QueriesTexts.Add("DROP DifferentProducts");
	
	QueriesTexts.Add(InformationRegisters.SupplySchemes.TemporaryTableOfVariousGoodsAndWarehouses(NameOfProductsTable, False));
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryTablesOfExpenseBalancesAndRefunds(Query)
	
	Query.Text =
		"SELECT
		|	ProductStock.Warehouse                             AS Warehouse,
		|	ProductStock.Products                      AS Products,
		|	ProductStock.Characteristic                    AS Characteristic,
		|	BEGINOFPERIOD(ProductStock.Period, DAY)       AS Date,
		|	ProductStock.InStockClosingBalance > 0       AS IsClosingBalance,
		|	ProductStock.InStockOpeningBalance > 0
		|		AND ProductStock.InStockClosingBalance > 0 AS IsBalance
		|INTO SignsOfBalancesByDate
		|FROM
		|	AccumulationRegister.ProductStock.BalanceAndTurnovers(
		|		&ClassificationPeriodStartDate,
		|		&ClassificationPeriodEndDate,
		|		Day,
		|		RegisterRecordsAndPeriodBoundaries,
		|		Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			AND (Products, Characteristic, Warehouse) IN(
		|				SELECT
		|					Goods.Products   AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse          AS Warehouse
		|				FROM
		|					VariousGoodsAndWarehouses AS Goods)) AS ProductStock
		|WHERE
		|	ProductStock.Period < &ClassificationPeriodEndDate
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Shipment.Products     AS Products,
		|	Shipment.Characteristic   AS Characteristic,
		|	Shipment.Warehouse            AS Sender,
		|	Shipment.Recipient       AS Recipient,
		|	Shipment.Period           AS Period,
		|	Shipment.ToShipExpense  AS Shipped
		|INTO MovementRegisteredRecords
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			&ClassificationPeriodStartDate,
		|			&ClassificationPeriodEndDate,
		|			Day,
		|			Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|				AND VALUETYPE(Recipient) = TYPE(Catalog.Warehouses)
		|				AND VALUETYPE(DocumentShipments) IN(
		|					TYPE(Document.TransferOrder),
		
		|					TYPE(Document.OrderOfMaterialsForProduction),
		|					TYPE(Document.MovementOfProductsAndMaterials),
		
		|					TYPE(Document.InventoryTransfer))
		|				AND (Products, Characteristic, Warehouse) IN(
		|					SELECT
		|						Goods.Products   AS Products,
		|						Goods.Characteristic AS Characteristic,
		|						Goods.Warehouse          AS Warehouse
		|					FROM
		|						VariousGoodsAndWarehouses AS Goods)
		|				AND Warehouse IN(
		|					SELECT
		|						Warehouses.Ref AS Warehouse
		|					FROM
		|						Catalog.Warehouses AS Warehouses)) AS Shipment
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Shipment.Products     AS Products,
		|	Shipment.Characteristic   AS Characteristic,
		|	Shipment.Sender      AS Sender,
		|	Shipment.Recipient       AS Recipient,
		|	SUM(Shipment.Shipped) AS Shipped
		|INTO MovingShipmentWithoutDates
		|FROM
		|	MovementRegisteredRecords AS Shipment
		|GROUP BY
		|	Shipment.Products,
		|	Shipment.Characteristic,
		|	Shipment.Sender,
		|	Shipment.Recipient
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Set.Products   AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Sender    AS Sender,
		|	Set.Recipient     AS Recipient,
		|	SUM(Set.Accepted) AS Accepted
		|INTO MovingAcceptance
		|FROM(
		|	SELECT
		|		Receiving.Products             AS Products,
		|		Receiving.Characteristic           AS Characteristic,
		|		Receiving.Sender              AS Sender,
		|		Receiving.Warehouse                    AS Recipient,
		|		Receiving.GoodsReceiptNotesToRegisterExpense AS Accepted
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Turnovers(
		|				&ClassificationPeriodStartDate,
		|				&ClassificationPeriodEndDate,
		|				,
		|				Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					AND ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|					AND Sender REFS Catalog.Warehouses
		|					AND (Products, Characteristic, Warehouse) IN(
		|						SELECT
		|							Goods.Products   AS Products,
		|							Goods.Characteristic AS Characteristic,
		|							Goods.Warehouse          AS Warehouse
		|						FROM
		|							VariousGoodsAndWarehouses AS Goods)) AS Receiving
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Receiving.Products   AS Products,
		|		Receiving.Characteristic AS Characteristic,
		|		CASE WHEN NOT Transfers.Ref IS NULL THEN
		|					Transfers.SourceWarehouse
		|				WHEN NOT ProductionMovements.Ref IS NULL THEN
		|					ProductionMovements.Sender
		|			END              AS Sender,
		|		Receiving.Warehouse          AS Recipient,
		|		Receiving.InStock       AS Accepted
		|	FROM
		|		AccumulationRegister.ProductStock AS Receiving
		|			
		|			LEFT JOIN Document.InventoryTransfer AS Transfers
		|			ON Transfers.Ref = Receiving.Recorder
		|			 AND NOT Transfers.LockedGoodsTransfer
		|			
		|			LEFT JOIN Document.MovementOfProductsAndMaterials AS ProductionMovements
		|			ON ProductionMovements.Ref = Receiving.Recorder
		|			AND ProductionMovements.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom)
		|	WHERE
		|		Receiving.Active
		|			AND Receiving.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND Receiving.Period BETWEEN &ClassificationPeriodStartDate AND &ClassificationPeriodEndDate
		|			AND Receiving.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND (Receiving.Products, Receiving.Characteristic, Receiving.Warehouse) IN(
		|				SELECT
		|					Goods.Products   AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse          AS Warehouse
		|				FROM
		|					VariousGoodsAndWarehouses AS Goods)
		|			AND NOT (Transfers.Ref IS NULL
		|					AND ProductionMovements.Ref IS NULL
		|				)) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Sender,
		|	Set.Recipient
		|
		|INDEX BY
		|	Products, Characteristic, Sender, Recipient
		|;
		|
		|//////////////////////////////////////////
		|SELECT
		|	Set.Warehouse             AS Warehouse,
		|	Set.Products      AS Products,
		|	Set.Characteristic    AS Characteristic,
		|	SUM(Set.Return)    AS Count
		|INTO RefundsInformationSecurityData
		|FROM(
		|	SELECT
		|		Transfers.Products       AS Products,
		|		Transfers.Characteristic     AS Characteristic,
		|		Transfers.Sender        AS Warehouse,
		|		CASE WHEN SUM(Receiving.Accepted) > SUM(Transfers.Shipped) THEN
		|					SUM(Transfers.Shipped)
		|				ELSE
		|					SUM(Receiving.Accepted)
		|			END AS Return
		|	FROM
		|		MovingShipmentWithoutDates AS Transfers
		|			
		|			LEFT JOIN MovingAcceptance AS Receiving
		|			ON Receiving.Products   = Transfers.Products
		|			 AND Receiving.Characteristic = Transfers.Characteristic
		|			 AND Receiving.Recipient     = Transfers.Sender
		|			 AND Receiving.Sender    = Transfers.Recipient
		|			
		|			LEFT JOIN WarehouseTopology AS SenderTopology
		|			ON SenderTopology.Products   = Transfers.Products
		|			 AND SenderTopology.Characteristic = Transfers.Characteristic
		|			 AND SenderTopology.Warehouse          = Transfers.Sender
		|			
		|			LEFT JOIN WarehouseTopology AS ReceiverTopology
		|			ON ReceiverTopology.Products   = Transfers.Products
		|			 AND ReceiverTopology.Characteristic = Transfers.Characteristic
		|			 AND ReceiverTopology.Warehouse          = Transfers.Recipient
		|			 AND ReceiverTopology.Center          = SenderTopology.Center
		|	WHERE
		|		NOT Receiving.Products IS NULL
		|			AND Transfers.Sender.WarehouseStore = VALUE(Enum.TypesOfWarehouses.WholesaleWarehouse)
		|			AND ReceiverTopology.Products IS NULL
		|	GROUP BY
		|		Transfers.Products,
		|		Transfers.Characteristic,
		|		Transfers.Sender
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Return.Products             AS Products,
		|		Return.Characteristic           AS Characteristic,
		|		Return.Warehouse                    AS Warehouse,
		|		Return.GoodsReceiptNotesToRegisterExpense AS Return
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Turnovers(
		|				&ClassificationPeriodStartDate,
		|				&ClassificationPeriodEndDate,
		|				,
		|				Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					AND (Products, Characteristic, Warehouse) IN(
		|						SELECT
		|							Goods.Products   AS Products,
		|							Goods.Characteristic AS Characteristic,
		|							Goods.Warehouse          AS Warehouse
		|						FROM
		|							VariousGoodsAndWarehouses AS Goods)
		|					AND BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PutOutOfOperation),
		|						VALUE(Enum.BusinessTransactions.ReturnFromProduction),
		|						VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction),
		|						VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
		|						VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
		|						VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
		|						VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
		|						VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer))) AS Return
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Return.Products   AS Products,
		|		Return.Characteristic AS Characteristic,
		|		Return.Warehouse          AS Warehouse,
		|		Return.InStock       AS Return
		|	FROM
		|		AccumulationRegister.ProductStock AS Return
		|	WHERE
		|		Return.Active
		|			AND Return.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND Return.Period BETWEEN &ClassificationPeriodStartDate AND &ClassificationPeriodEndDate
		|			AND Return.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND (Return.Products, Return.Characteristic, Return.Warehouse) IN(
		|				SELECT
		|					Goods.Products   AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse          AS Warehouse
		|				FROM
		|					VariousGoodsAndWarehouses AS Goods)
		|				
		|			AND CASE WHEN VALUETYPE(Return.Recorder) = TYPE(Document.OtherGoodsRecordingAsReceived) THEN
		|						CAST(Return.Recorder AS Document.OtherGoodsRecordingAsReceived).BusinessOperation
		|							= VALUE(Enum.BusinessTransactions.PutOutOfOperation)
		|					WHEN VALUETYPE(Return.Recorder) = TYPE(Document.MovementOfProductsAndMaterials) THEN
		|						CAST(Return.Recorder AS Document.MovementOfProductsAndMaterials).BusinessOperation
		|							= VALUE(Enum.BusinessTransactions.ReturnOfMaterialsFromProduction)
		|					WHEN VALUETYPE(Return.Recorder) = TYPE(Document.ProductionStage2_2) THEN
		|						TRUE IN(
		|							SELECT TOP 1
		|								TRUE
		|							FROM
		|								Document.ProductionStage2_2.UnusedMaterials AS Savings
		|							WHERE
		|								Savings.Ref = Return.Recorder
		|									AND Savings.Products = Return.Products
		|									AND Savings.Characteristic = Return.Characteristic
		|									AND Savings.Recipient = Return.Warehouse)
		|					ELSE
		|						VALUETYPE(Return.Recorder) IN(
		|							TYPE(Document.ReceiptOfGoodsFromCustodian),
		|							TYPE(Document.CashRegisterReceiptReturn),
		|							TYPE(Document.ReturnOfGoodsFromCustomer))
		|				END
		|) AS Set
		|GROUP BY
		|	Set.Warehouse,
		|	Set.Products,
		|	Set.Characteristic
		|;
		|
		|//////////////////////////////////////////////////
		|SELECT
		|	Set.Warehouse             AS Warehouse,
		|	Set.Products      AS Products,
		|	Set.Characteristic    AS Characteristic,
		|	Set.Period            AS Date,
		|	SUM(Set.Count) AS Count
		|INTO ConsumptionByDayInformationSecurityData
		|FROM(
		|	SELECT
		|		ProductStock.Products   AS Products,
		|		ProductStock.Characteristic AS Characteristic,
		|		ProductStock.Warehouse          AS Warehouse,
		|		ProductStock.Period         AS Period,
		|		ProductStock.InStockExpense AS Count
		|	FROM
		|		AccumulationRegister.ProductStock.Turnovers(
		|			&ClassificationPeriodStartDate,
		|			&ClassificationPeriodEndDate,
		|			Day,
		|			Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				AND ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|				AND (Products, Characteristic, Warehouse) IN(
		|					SELECT
		|						Goods.Products   AS Products,
		|						Goods.Characteristic AS Characteristic,
		|						Goods.Warehouse          AS Warehouse
		|					FROM
		|						VariousGoodsAndWarehouses AS Goods)) AS ProductStock
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductStock.Products   AS Products,
		|		ProductStock.Characteristic AS Characteristic,
		|		ProductStock.Warehouse          AS Warehouse,
		|		BEGINOFPERIOD(ProductStock.Period, DAY) AS Period,
		|		-ProductStock.InStock      AS Count
		|	FROM
		|		AccumulationRegister.ProductStock AS ProductStock
		|	WHERE
		|		ProductStock.Active
		|			AND ProductStock.Period BETWEEN &ClassificationPeriodStartDate AND &ClassificationPeriodEndDate
		|			AND ProductStock.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND ProductStock.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			AND VALUETYPE(ProductStock.Recorder) = TYPE(Document.GoodsTransferNote)
		|			AND ProductStock.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND (Products, Characteristic, Warehouse) IN(
		|				SELECT
		|					Goods.Products   AS Products,
		|					Goods.Characteristic AS Characteristic,
		|					Goods.Warehouse          AS Warehouse
		|				FROM
		|					VariousGoodsAndWarehouses AS Goods)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Transfers.Products   AS Products,
		|		Transfers.Characteristic AS Characteristic,
		|		Transfers.Sender    AS Warehouse,
		|		Transfers.Period         AS Period,
		|		-Transfers.Shipped     AS Count
		|	FROM
		|		MovementRegisteredRecords AS Transfers
		|			
		|			LEFT JOIN WarehouseTopology AS SenderTopology
		|			ON SenderTopology.Products   = Transfers.Products
		|			 AND SenderTopology.Characteristic = Transfers.Characteristic
		|			 AND SenderTopology.Warehouse          = Transfers.Sender
		|			
		|			LEFT JOIN WarehouseTopology AS ReceiverTopology
		|			ON ReceiverTopology.Products   = Transfers.Products
		|			 AND ReceiverTopology.Characteristic = Transfers.Characteristic
		|			 AND ReceiverTopology.Warehouse          = Transfers.Recipient
		|			 AND ReceiverTopology.Center          = ReceiverTopology.Center
		|	WHERE
		|		NOT ReceiverTopology.Products IS NULL
		|			OR Transfers.Sender.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)) AS Set
		|GROUP BY
		|	Set.Warehouse,
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Period
		|INDEX BY
		|	Products, Characteristic, Warehouse, Date
		|;
		|
		|//////////////////////////////////////////////////
		|DROP MovementRegisteredRecords;
		|DROP MovingShipmentWithoutDates;
		|DROP MovingAcceptance";
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryTableAverageDailyConsumption(Query)
	
	Query.Text =
		"SELECT DISTINCT
		|	Topology.Center AS Center,
		|	Topology.Warehouse AS Warehouse,
		|	CASE WHEN Topology.Center.Calendar = VALUE(Catalog.Calendars.EmptyRef) THEN
		|					MainCalendar.Value
		|				ELSE
		|					Topology.Center.Calendar
		|			END AS CalendarCenter,
		|	CASE WHEN Topology.Center.Calendar = VALUE(Catalog.Calendars.EmptyRef) THEN
		|					MainCalendar.Value
		|				ELSE
		|					Topology.Center.Calendar
		|			END AS CalendarWarehouse
		|INTO CalendarDiffers
		|FROM
		|	WarehouseTopology AS Topology
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainCalendar
		|		ON TRUE
		|WHERE
		|	Topology.Center.Calendar <> Topology.Warehouse.Calendar
		|INDEX BY
		|	Center, Warehouse
		|;
		|
		|///////////////////////////////////
		|SELECT
		|	Schedule.Calendar AS Calendar,
		|	COUNT(*)    AS Count
		|INTO NumberOfWorkingDaysOfSchedule
		|FROM
		|	ScheduleOfWorkAccordingToCalendar AS Schedule
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE
		|		FROM
		|			CalendarDiffers AS CalendarDiffers
		|		WHERE
		|			Schedule.Calendar IN(
		|				CalendarDiffers.CalendarCenter,
		|				CalendarDiffers.CalendarWarehouse))
		|GROUP BY
		|	Schedule.Calendar
		|INDEX BY
		|	Calendar
		|;
		|
		|///////////////////////////////////
		|SELECT
		|	Signs.Warehouse AS Warehouse,
		|	Signs.Products AS Products,
		|	Signs.Characteristic AS Characteristic,
		|	SUM(CASE WHEN Signs.Consider THEN
		|				1
		|			ELSE
		|				0
		|		END) AS DaysCount,
		|	SUM(CASE WHEN Signs.DaysOfFullSales THEN
		|				1
		|			ELSE
		|				0
		|		END) AS NumberOfDaysOfFullSales
		|INTO CountedDays
		|FROM
		|	SignsOfAccountingDays AS Signs
		|WHERE
		|	Signs.Consider
		|		OR Signs.DaysOfFullSales
		|GROUP BY
		|	Signs.Warehouse,
		|	Signs.Products,
		|	Signs.Characteristic
		|INDEX BY
		|	Warehouse, Products, Characteristic
		|;
		|
		|//////////////////////////////////////////
		|SELECT
		|	Expense.Warehouse AS Warehouse,
		|	Expense.Products AS Products,
		|	Expense.Characteristic AS Characteristic,
		|	Expense.Count AS Expense,
		|	
		|	CASE WHEN CountedDays.NumberOfDaysOfFullSales = 0
		|					OR Expense.Count / CountedDays.DaysCount >
		|							Expense.QuantityOnDaysOfFullSales / CountedDays.NumberOfDaysOfFullSales THEN
		|					
		|					(Expense.Count - ISNULL(Returns.Count, 0)) / CountedDays.DaysCount
		|					
		|			ELSE
		|					
		|					(Expense.QuantityOnDaysOfFullSales - ISNULL(Returns.Count, 0)) / CountedDays.NumberOfDaysOfFullSales
		|					
		|		END AS Count,
		|	
		|	CASE WHEN CountedDays.NumberOfDaysOfFullSales = 0
		|					OR Expense.Count / CountedDays.DaysCount >
		|							Expense.QuantityOnDaysOfFullSales / CountedDays.NumberOfDaysOfFullSales THEN
		|					
		|					Expense.QuantitySquare / CountedDays.DaysCount
		|					
		|			ELSE
		|					
		|					Expense.QuantityOnDaysOfFullSalesSquare / CountedDays.NumberOfDaysOfFullSales
		|					
		|		END AS NumberSquaredForVariance,
		|	
		|	CASE WHEN CountedDays.NumberOfDaysOfFullSales = 0
		|					OR Expense.Count / CountedDays.DaysCount >
		|							Expense.QuantityOnDaysOfFullSales / CountedDays.NumberOfDaysOfFullSales THEN
		|					
		|					Expense.Count / CountedDays.DaysCount
		|					
		|			ELSE
		|					
		|					Expense.QuantityOnDaysOfFullSales / CountedDays.NumberOfDaysOfFullSales
		|					
		|		END AS QuantityForVariance,
		|	
		|	CASE WHEN CountedDays.NumberOfDaysOfFullSales = 0
		|					OR Expense.Count / CountedDays.DaysCount >
		|							Expense.QuantityOnDaysOfFullSales / CountedDays.NumberOfDaysOfFullSales THEN
		|					
		|					CountedDays.DaysCount
		|					
		|			ELSE
		|					
		|					CountedDays.NumberOfDaysOfFullSales
		|					
		|		END AS NumberOfDaysForVariance
		|	
		|INTO AverageDailyConsumptionExcludingRC
		|FROM
		|	Expenses AS Expense
		|		
		|		LEFT JOIN CountedDays AS CountedDays
		|		ON CountedDays.Warehouse          = Expense.Warehouse
		|		 AND CountedDays.Products   = Expense.Products
		|		 AND CountedDays.Characteristic = Expense.Characteristic
		|		
		|		LEFT JOIN Returns AS Returns
		|		ON Returns.Warehouse          = Expense.Warehouse
		|		 AND Returns.Products   = Expense.Products
		|		 AND Returns.Characteristic = Expense.Characteristic
		|WHERE
		|	NOT CountedDays.Products IS NULL
		|;
		|
		|//////////////////////////////////////////
		|SELECT
		|	Set.Warehouse             AS Warehouse,
		|	Set.Products      AS Products,
		|	Set.Characteristic    AS Characteristic,
		|	SUM(Set.Expense)     AS Expense,
		|	SUM(Set.Count) AS Count,
		|	SUM(Set.Variance)  AS Variance,
		|	CASE WHEN SUM(Set.QuantityForVariance * Set.QuantityForVariance) = 0 THEN
		|				FALSE
		|			ELSE
		|				SUM(Set.Variance) / SUM(Set.QuantityForVariance * Set.QuantityForVariance) < 0.0025
		|		END AS ConsumptionIsStable
		|INTO AverageDailyConsumption
		|FROM(
		|	SELECT
		|		Consumption.Warehouse          AS Warehouse,
		|		Consumption.Products   AS Products,
		|		Consumption.Characteristic AS Characteristic,
		|		Consumption.Expense         AS Expense,
		|		Consumption.Count     AS Count,
		|		Consumption.QuantityForVariance AS QuantityForVariance,
		|		CASE WHEN Consumption.NumberOfDaysForVariance = 1 THEN
		|					0
		|				ELSE
		|					Consumption.NumberOfDaysForVariance
		|						/ (Consumption.NumberOfDaysForVariance - 1)
		|							*(Consumption.NumberSquaredForVariance
		|								- Consumption.QuantityForVariance * Consumption.QuantityForVariance)
		|			END AS Variance
		|	FROM
		|		AverageDailyConsumptionExcludingRC AS Consumption
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Topology.Center                                                                  AS Warehouse,
		|		Consumption.Products                                                         AS Products,
		|		Consumption.Characteristic                                                       AS Characteristic,
		|		Consumption.Expense                                                               AS Expense,
		|		CASE WHEN CalendarDiffers.Warehouse IS NULL THEN
		|					Consumption.Count
		|				ELSE
		|					Consumption.Count * TotalWarehouseDays.Count / TotalCenterDays.Count
		|			END AS Count,
		|		Consumption.QuantityForVariance AS QuantityForVariance,
		|		CASE WHEN Consumption.NumberOfDaysForVariance = 1 THEN
		|					0
		|				ELSE
		|					Consumption.NumberOfDaysForVariance
		|						/ (Consumption.NumberOfDaysForVariance - 1)
		|							*(Consumption.NumberSquaredForVariance
		|								- Consumption.QuantityForVariance * Consumption.QuantityForVariance)
		|			END AS Variance
		|	FROM
		|		AverageDailyConsumptionExcludingRC AS Consumption
		|			
		|			LEFT JOIN WarehouseTopology AS Topology
		|			ON Topology.Products   = Consumption.Products
		|			 AND Topology.Characteristic = Consumption.Characteristic
		|			 AND Topology.Warehouse          = Consumption.Warehouse
		|			 AND Topology.Center         <> Consumption.Warehouse
		|			
		|			LEFT JOIN CalendarDiffers AS CalendarDiffers
		|			ON CalendarDiffers.Center = Topology.Center
		|			 AND CalendarDiffers.Warehouse = Topology.Warehouse
		|			
		|			LEFT JOIN NumberOfWorkingDaysOfSchedule AS TotalCenterDays
		|			ON TotalCenterDays.Calendar = CalendarDiffers.CalendarCenter
		|			
		|			LEFT JOIN NumberOfWorkingDaysOfSchedule AS TotalWarehouseDays
		|			ON TotalWarehouseDays.Calendar = CalendarDiffers.CalendarWarehouse
		|	WHERE
		|		CalendarDiffers.Warehouse IS NULL OR TotalCenterDays.Count > 0) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse
		|;
		|
		|///////////////////////////////////////////////////////////
		|DROP CalendarDiffers;
		|DROP NumberOfWorkingDaysOfSchedule;
		|DROP CountedDays;
		|DROP AverageDailyConsumptionExcludingRC";
	
	Query.Execute();
	
EndProcedure

#Region CalculationOfConsumptionStatisticsCore

Procedure EnergyConsumptionStatistics(Query, NameOfProductsTable, TableNameResult)
	
	// Stage number 1.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** Product tabletablename - Temporary query tabletable - Login. The table name is set by the following parameter.
	//    *** Different types of orders - Time table of the request - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference link.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//    *** Topologysclades - Temporary Query table - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference link.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Center - Reference link.Warehouses - a warehouse that is the center of the distribution network
	//                     for the original item and warehouse.
	// Product Tablename - String is the name of the table, the first table of the temp table manager. 
	AddTemporaryWarehouseTopologyTables(Query, NameOfProductsTable);
	
	// Stage number 2.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** Various types of orders - Time table of the request - Input. calculated at stage #1.
	//    *** Seasonal Effects - Temporary Query table - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference link.Items
	//        **** Coefficient - Number - seasonal coefficient for each item and warehouse transferred to the entrance.
	AddTemporaryTableSeasonalCoefficients(Query);
	
	// Stage number 3.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** Various types of orders - Time table of the request - Input. calculated at stage #1.
	//    *** Schedule of work according to the calendar - Time table of the request - Output. Table with fields:
	//        **** Calendar - Reference link.Calendars
	//        **** Date - Date - date according to the warehouse calendar in the period of calculation of statistics, for reissued warehouses.
	AddTemporaryCalendarScheduleTable(Query);
	
	// Stage number 4.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** Various types of orders - Time table of the request - Input. calculated at stage #1.
	//    *** Topologysclades - Temporary Query table - Input. calculated at stage #1.
	//    *** signinaliciyostatepodatam - Temporary Query table - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference referenceslink.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Date - Date
	//        **** There is a finite state - Boolean - if there is a finite Balance on the date
	//        **** There are dates - Boolean - if there is an initial or final Balance on the date
	//    *** The flow rate is raised by the data from the - time table of the query - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference link.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Date - Date
	//        **** Quantity - Number - expense on this date
	//    *** Returnedannyib - Time table of the query - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference link.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Date - Date
	//        **** Quantity - Number - Return on this date
	AddTemporaryTablesOfExpenseBalancesAndRefunds(Query);
	
	// Stage number 5.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** The flow rate of the data is the time table of the request - Input. calculated at stage No. 4.
	//    *** returnedannyib - Time table of the request - Input. calculated at stage #4.
	//    *** Seasonal Effects - Time table of the request - Input. calculated at stage #4.
	//    *** Schedule of work according to the calendar - Time table of the request - Input. calculated at stage #2.
	//    *** signingstatepodatam - Temporary Query table - Input. calculated at stage #4.
	//    *** Consumption by day - The time table of the query - The output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Nomenclature - Reference link.Nomenclature
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Date - Date
	//        **** Quantity - Number - expense on this date
	//        **** Quantity - Number - expense on this date, if there was an initial and final Balance on this date.
	//    *** Expenses - Temporary Query table - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Nomenclature - Reference link.Nomenclature
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Quantity - Number - expense for the entire calculation period
	//        **** The number of full sales - The number - the expense for the entire calculation period, only on the dates when there was an initial and final Balance.
	//        **** Quantity Square - Number - square consumption for the entire calculation period
	//        **** The quantity of non-full sales is square - The number is the consumption of the square for the entire calculation period, only on the dates when there was an initial and final Balance.
	//    *** Refunds - Temporary Request table - Exit. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Nomenclature - Reference link.Nomenclature
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Quantity - Number - refund for the entire calculation period
	TakeIntoAccountSeasonalityFactorsWorkingDaysAndDaysOfIncompleteSales(Query);
	
	// Stage number 6.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** Schedule of work according to the calendar - Time table of the request - Input. calculated at stage #2.
	//    *** signingstatepodatam - Temporary Query table - Input. calculated at stage #4.
	//    *** Consumption by day - Time table of the request - Input. calculated at stage #5.
	//    *** The sign of the account is later - the time table of the request is the output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference referenceslink.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Date - Date
	//        **** Consider - Boolean - you need to consider the date as the date of sales
	//        **** Take into account the days of full sales - The number - you need to take into account the date as the date of sales, when there was both the initial and final Balance
	AddTemporaryTableToAccountForDays(Query);
	
	// Stage number 7.
	// Parameters:
	// Request - Request:
	//  * Time Table Manager - Time Table Manager:
	//   ** Tables - Time TableQuery:
	//    *** The sign of the account is Today - the time table of the request is the input. calculated at stage #6.
	//    *** Expenses - Temporary Request table - Input. calculated at stage #5.
	//    *** Refunds - Temporary Request table - Input. calculated at step #5.
	//    *** Schedule of work according to the calendar - Time table of the request - Input. calculated at stage #2.
	//    *** Topologysclades - Temporary Query table - Input. calculated at stage #1.
	//    *** Average daily consumption - Temporary Query table - Output. Table with fields:
	//        **** Warehouse - Reference link.Warehouses
	//        **** Item - Reference referenceslink.Items
	//        **** Feature - Reference link.Nomenclature specificationsreferences
	//        **** Quantity - Number
	//        **** Consumption - Number
	//        **** Variance is a number
	//        **** Consumption is stable - The number
	AddTemporaryTableAverageDailyConsumption(Query);
	
	QueryTexts = New Array();
	Text =
		"SELECT
		|	Goods.Products                                                AS Products,
		|	Goods.Characteristic                                              AS Characteristic,
		|	Goods.Warehouse                                                       AS Warehouse,
		|	&ClassificationPeriodStartDate                                     AS BeginningDateOfPeriod,
		|	&ClassificationPeriodEndDate                                  AS EndingDateOfPeriod,
		|	ISNULL(AverageDailyConsumptionOfGoods.Expense, 0)                 AS Consumption,
		|	ISNULL(AverageDailyConsumptionOfGoods.Count, 0)             AS AverageDailyConsumption,
		|	ISNULL(AverageDailyConsumptionOfGoods.Variance, 0)              AS VarianceOfConsumption,
		|	ISNULL(AverageDailyConsumptionOfGoods.ConsumptionIsStable, FALSE)AS ConsumptionIsStable
		|INTO ResultOverridable
		|FROM
		|	GoodsOverridable AS Goods
		|		
		|		LEFT JOIN AverageDailyConsumption AS AverageDailyConsumptionOfGoods
		|		ON AverageDailyConsumptionOfGoods.Products   = Goods.Products
		|		 AND AverageDailyConsumptionOfGoods.Characteristic = Goods.Characteristic
		|		 AND AverageDailyConsumptionOfGoods.Warehouse          = Goods.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	
	Text = StrReplace(Text, "GoodsOverridable", NameOfProductsTable);
	Text = StrReplace(Text, "ResultOverridable", TableNameResult);
	QueryTexts.Add(Text);
	
	QueryTexts.Add("DROP VariousGoodsAndWarehouses");
	QueryTexts.Add("DROP WarehouseTopology");
	QueryTexts.Add("DROP ScheduleOfWorkAccordingToCalendar");
	QueryTexts.Add("DROP SignsOfBalancesByDate");
	QueryTexts.Add("DROP SeasonalIndexes");
	QueryTexts.Add("DROP ConsumptionByDayInformationSecurityData");
	QueryTexts.Add("DROP RefundsInformationSecurityData");
	QueryTexts.Add("DROP ConsumptionByDay");
	QueryTexts.Add("DROP Expenses");
	QueryTexts.Add("DROP Returns");
	QueryTexts.Add("DROP SignsOfAccountingDays");
	QueryTexts.Add("DROP AverageDailyConsumption");
	QueryTexts.Add("DROP TTChart");
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryTableProductCategories(Query, NameOfProductsTable)
	
	Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products.ProductCategory AS ProductCategory
		|INTO CategoryWarehouses
		|FROM
		|	GoodsOverridable AS Goods
		|WHERE
		|	Goods.Products.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref            AS Products,
		|	CatProducts.ProductCategory AS ProductCategory
		|INTO CategoryProducts
		|FROM
		|	Catalog.Products AS CatProducts
		|WHERE
		|	NOT CatProducts.DeletionMark
		|		AND CatProducts.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				GoodsOverridable AS Goods
		|			WHERE
		|				Goods.Products.ProductCategory = CatProducts.ProductCategory)
		|INDEX BY
		|	Products
		|;
		|
		|//////////////////////////////////////////////
		|SELECT DISTINCT
		|	ProductStock.Products   AS Products,
		|	ProductStock.Characteristic AS Characteristic
		|INTO ProductCategoriesInCirculation
		|FROM
		|	AccumulationRegister.ProductStock.Turnovers(
		|		DATEADD(&ClassificationPeriodStartDate, MONTH, -12),
		|		&ClassificationPeriodEndDate,
		|		,
		|		Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|			AND ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			AND Products IN(
		|				SELECT
		|					Filter.Products
		|				FROM
		|					CategoryProducts AS Filter)) AS ProductStock
		|WHERE
		|	ProductStock.InStockExpense > 0
		|INDEX BY
		|	Products, Characteristic
		|;
		|
		|//////////////////////////////////////////////
		|SELECT
		|	Warehouses.Warehouse                                  AS Warehouse,
		|	ProductCategoriesInCirculation.Products   AS Products,
		|	ProductCategoriesInCirculation.Characteristic AS Characteristic,
		|	Warehouses.ProductCategory                      AS ProductCategory
		|INTO ProductCategories
		|FROM
		|	CategoryWarehouses AS Warehouses
		|		
		|		LEFT JOIN ProductCategoriesInCirculation AS ProductCategoriesInCirculation
		|		ON ProductCategoriesInCirculation.Products.ProductCategory = Warehouses.ProductCategory
		|WHERE
		|	NOT ProductCategoriesInCirculation.Products IS NULL
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|//////////////////////////////////////////////
		|DROP CategoryWarehouses;
		|DROP CategoryProducts;
		|DROP ProductCategoriesInCirculation";
		
	Query.Text = StrReplace(Text, "GoodsOverridable", NameOfProductsTable);
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryTableSeasonalCoefficients(Query)
	
	If GetFunctionalOption("UseAdvancedDemandFulfillment")
		And Constants.SeasonalFluctuationsRegistrationOption.Get() = Enums.SeasonalFluctuationsAccounting.BySeasonalIndexes Then
		
		Texts = New Array();
		Text =
			"SELECT DISTINCT
			|	Goods.Products AS Products,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Products.ItemsGroup AS ItemsGroup,
			|	CASE WHEN Goods.Warehouse.BusinessRegion.ItemsGroup <> VALUE(Catalog.SeasonalGroupsOfBusinessRegions.EmptyRef) THEN
			|			Goods.Warehouse.BusinessRegion.ItemsGroup
			|		ELSE
			|			VALUE(Catalog.SeasonalGroupsOfBusinessRegions.OtherItems)
			|	END AS SeasonalGroupOfBusinessRegion
			|INTO VariousGoodsAndWarehousesWithoutCharacteristics
			|FROM
			|	VariousGoodsAndWarehouses AS Goods
			|INDEX BY
			|	ItemsGroup, SeasonalGroupOfBusinessRegion
			|;
			|
			|///////////////////////////////////////////
			|SELECT DISTINCT
			|	Goods.ItemsGroup AS ItemsGroup,
			|	Goods.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion
			|INTO SeasonalGroups
			|FROM
			|	VariousGoodsAndWarehousesWithoutCharacteristics AS Goods
			|INDEX BY
			|	ItemsGroup, SeasonalGroupOfBusinessRegion
			|;
			|
			|///////////////////////////////////////////////////////////////////
			// Full years.
			|SELECT
			|	Set.ItemsGroup AS ItemsGroup,
			|	Set.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|	SUM(Set.ZoomRatio) AS ZoomRatio,
			|	SUM(Set.NumberOfDays) AS NumberOfDays,
			|	SUM(Set.CoefficientIsCalculated) AS CoefficientIsCalculated,
			|	SUM(Set.NumberOfDaysCalculated) AS NumberOfDaysCalculated
			|INTO SeasonalCoefficientsByGroup
			|FROM(
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		SeasonalIndexes.ZoomRatio * (YEAR(&ClassificationPeriodEndDate) - YEAR(&ClassificationPeriodStartDate) - 1) AS ZoomRatio,
			|		(YEAR(&ClassificationPeriodEndDate) - YEAR(&ClassificationPeriodStartDate) - 1) AS NumberOfDays,
			|		0 AS CoefficientIsCalculated,
			|		0 AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND (YEAR(&ClassificationPeriodEndDate) - YEAR(&ClassificationPeriodStartDate)) > 1
			|	
			|	UNION ALL
			|	
			// Incomplete year from the beginning of the period.
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		SeasonalIndexes.ZoomRatio AS ZoomRatio,
			|		1 AS NumberOfDays,
			|		0 AS CoefficientIsCalculated,
			|		0 AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND CASE WHEN (YEAR(&ClassificationPeriodEndDate) - YEAR(&ClassificationPeriodStartDate)) > 0 THEN
			|							SeasonalIndexes.PeriodNumber >= DAYOFYEAR(&ClassificationPeriodStartDate)
			|						ELSE
			|							SeasonalIndexes.PeriodNumber >= DAYOFYEAR(&ClassificationPeriodStartDate)
			|								AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(&ClassificationPeriodEndDate)
			|					END
			|	
			|	UNION ALL
			|	
			// Incomplete year before the end of the period.
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		SeasonalIndexes.ZoomRatio AS ZoomRatio,
			|		1 AS NumberOfDays,
			|		0 AS CoefficientIsCalculated,
			|		0 AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND (YEAR(&ClassificationPeriodEndDate) - YEAR(&ClassificationPeriodStartDate)) > 0
			|				AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(&ClassificationPeriodEndDate)
			|	
			|	UNION ALL
			|	
			// Full years (billing period).
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		0 AS ZoomRatio,
			|		0 AS NumberOfDays,
			|		SeasonalIndexes.ZoomRatio * (YEAR(&BillingPeriodEndDate) - YEAR(&BillingPeriodStartDate) - 1) AS CoefficientIsCalculated,
			|		(YEAR(&BillingPeriodEndDate) - YEAR(&BillingPeriodStartDate) - 1) AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND (YEAR(&BillingPeriodEndDate) - YEAR(&BillingPeriodStartDate)) > 1
			|	
			|	UNION ALL
			|	
			// Incomplete year from the beginning of the period (billing period).
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		0 AS ZoomRatio,
			|		0 AS NumberOfDays,
			|		SeasonalIndexes.ZoomRatio AS CoefficientIsCalculated,
			|		1 AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND CASE WHEN (YEAR(&BillingPeriodEndDate) - YEAR(&BillingPeriodStartDate)) > 0 THEN
			|							SeasonalIndexes.PeriodNumber >= DAYOFYEAR(&BillingPeriodStartDate)
			|						ELSE
			|							SeasonalIndexes.PeriodNumber >= DAYOFYEAR(&BillingPeriodStartDate)
			|								AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(&BillingPeriodEndDate)
			|					END
			|	
			|	UNION ALL
			|	
			// Incomplete year before the end of the period (estimated).
			|	SELECT
			|		Groups.ItemsGroup AS ItemsGroup,
			|		Groups.SeasonalGroupOfBusinessRegion AS SeasonalGroupOfBusinessRegion,
			|		0 AS ZoomRatio,
			|		0 AS NumberOfDays,
			|		SeasonalIndexes.ZoomRatio AS CoefficientIsCalculated,
			|		1 AS NumberOfDaysCalculated
			|	FROM
			|		SeasonalGroups AS Groups
			|			INNER JOIN InformationRegister.SeasonalIndexes AS SeasonalIndexes
			|			ON Groups.ItemsGroup = SeasonalIndexes.ItemsGroup
			|				AND Groups.SeasonalGroupOfBusinessRegion = SeasonalIndexes.SeasonalGroupOfBusinessRegion
			|				AND SeasonalIndexes.Periodicity = VALUE(Enum.Periodicity.DAY)
			|				AND (YEAR(&BillingPeriodEndDate) - YEAR(&BillingPeriodStartDate)) > 0
			|				AND SeasonalIndexes.PeriodNumber <= DAYOFYEAR(&BillingPeriodEndDate)) AS Set
			|GROUP BY
			|	Set.ItemsGroup,
			|	Set.SeasonalGroupOfBusinessRegion
			|INDEX BY
			|	ItemsGroup, SeasonalGroupOfBusinessRegion
			|;
			|
			|//////////////////////////////////////
			|SELECT
			|	Goods.Products                       AS Products,
			|	Goods.Warehouse                              AS Warehouse,
			|	CASE WHEN
			|		SeasonalCoefficientsByGroup.ZoomRatio = 0
			|			OR SeasonalCoefficientsByGroup.NumberOfDays = 0
			|			OR SeasonalCoefficientsByGroup.CoefficientIsCalculated = 0
			|			OR SeasonalCoefficientsByGroup.NumberOfDaysCalculated = 0 THEN
			|		0
			|			ELSE
			|				(SeasonalCoefficientsByGroup.CoefficientIsCalculated * SeasonalCoefficientsByGroup.NumberOfDays)
			|					/ (SeasonalCoefficientsByGroup.ZoomRatio * SeasonalCoefficientsByGroup.NumberOfDaysCalculated)
			|		END AS ZoomRatio
			|INTO SeasonalIndexes
			|FROM
			|	VariousGoodsAndWarehousesWithoutCharacteristics AS Goods
			|		
			|		LEFT JOIN SeasonalCoefficientsByGroup AS SeasonalCoefficientsByGroup
			|		ON SeasonalCoefficientsByGroup.ItemsGroup = Goods.ItemsGroup
			|		 AND SeasonalCoefficientsByGroup.SeasonalGroupOfBusinessRegion = Goods.SeasonalGroupOfBusinessRegion
			|WHERE
			|	SeasonalCoefficientsByGroup.ZoomRatio > 0
			|		AND SeasonalCoefficientsByGroup.NumberOfDays > 0
			|		AND SeasonalCoefficientsByGroup.CoefficientIsCalculated > 0
			|		AND SeasonalCoefficientsByGroup.NumberOfDaysCalculated > 0
			
			|INDEX BY
			|	Products, Warehouse";
		Texts.Add(Text);
		
		DeleteText_ =
			"DROP SeasonalGroups;
			|DROP SeasonalCoefficientsByGroup;
			|DROP VariousGoodsAndWarehousesWithoutCharacteristics";
			
		If CommonClientServer.DebugMode() Then
			
			Query.Text = Text;
			Query.Execute();
			Query.Text = DeleteText_;
			Query.Execute();
			
		Else
			
			Texts.Add(DeleteText_);
			Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
			Query.Execute();
			
		EndIf;
		
	Else
		
		Query.Text =
			"SELECT
			|	NULL AS Products,
			|	NULL AS Warehouse,
			|	0    AS ZoomRatio
			|INTO SeasonalIndexes";
			
		Query.Execute();
		
	EndIf;
	
EndProcedure

Procedure AddTemporaryCalendarScheduleTable(Query)
	
	ScheduleWithoutCalendar = CreateEmptyGraph(
		Query.Parameters.ClassificationPeriodStartDate,
		Query.Parameters.ClassificationPeriodEndDate);
	
	Query.SetParameter("ScheduleWithoutCalendar", ScheduleWithoutCalendar);
	
	Query.Text =
		"SELECT
		|	ScheduleWithoutCalendar.ScheduleDate AS ScheduleDate
		|INTO ScheduleWithoutCalendar
		|FROM
		|	&ScheduleWithoutCalendar AS ScheduleWithoutCalendar
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalendarSchedules.Calendar AS Calendar,
		|	CalendarSchedules.Year AS Year,
		|	CalendarSchedules.ScheduleDate AS ScheduleDate,
		|	CalendarSchedules.DayAddedToSchedule AS DayAddedToSchedule,
		|	CalendarSchedules.DaysCountInScheduleSinceBegOfYear AS DaysCountInScheduleSinceBegOfYear
		|INTO TTChart
		|FROM
		|	InformationRegister.CalendarSchedules AS CalendarSchedules
		|WHERE
		|	CalendarSchedules.ScheduleDate BETWEEN &ClassificationPeriodStartDate AND &ClassificationPeriodEndDate
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ISNULL(Constants.MainEnterpriseCalendar, CatWarehouse.Calendar) AS Calendar,
		|	Schedule.ScheduleDate                                                   AS Date
		|INTO ScheduleOfWorkAccordingToCalendar
		|FROM
		|	VariousGoodsAndWarehouses AS Goods
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouse
		|		ON Goods.Warehouse = CatWarehouse.Ref
		|		LEFT JOIN Constants AS Constants
		|		ON CatWarehouse.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|		INNER JOIN TTChart AS Schedule
		|		ON ISNULL(Constants.MainEnterpriseCalendar, CatWarehouse.Calendar) = Schedule.Calendar
		|			AND Schedule.DayAddedToSchedule
		|			AND YEAR(&ClassificationPeriodStartDate) <= Schedule.Year
		|			AND Schedule.Year                     <= YEAR(&ClassificationPeriodEndDate)
		|			AND &ClassificationPeriodStartDate <= Schedule.ScheduleDate
		|			AND Schedule.ScheduleDate             <= &ClassificationPeriodEndDate
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Catalog.Calendars.EmptyRef) AS Calendar,
		|	ScheduleWithoutCalendar.ScheduleDate              AS Date
		|FROM
		|	ScheduleWithoutCalendar AS ScheduleWithoutCalendar
		|
		|INDEX BY
		|	Calendar,
		|	Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ScheduleWithoutCalendar";
	
	Query.Execute();
	
EndProcedure

Procedure TakeIntoAccountSeasonalityFactorsWorkingDaysAndDaysOfIncompleteSales(Query)
	
	Query.Text =
		"SELECT
		|	Returns.Warehouse                                                      AS Warehouse,
		|	Returns.Products                                               AS Products,
		|	Returns.Characteristic                                             AS Characteristic,
		|	Returns.Count * ISNULL(SeasonalIndexes.ZoomRatio, 1) AS Count
		|INTO Returns
		|FROM
		|	RefundsInformationSecurityData AS Returns
		|		
		|		LEFT JOIN SeasonalIndexes AS SeasonalIndexes
		|		ON SeasonalIndexes.Products = Returns.Products
		|		 AND SeasonalIndexes.Warehouse        = Returns.Warehouse
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Expense.Products                                              AS Products,
		|	Expense.Characteristic                                            AS Characteristic,
		|	Expense.Warehouse                                                     AS Warehouse,
		|	Expense.Date                                                      AS Date,
		|	Expense.Count * ISNULL(SeasonalIndexes.ZoomRatio,1) AS Count,
		|	CASE WHEN SignsOfPresence.IsBalance THEN
		|				Expense.Count * ISNULL(SeasonalIndexes.ZoomRatio,1)
		|			ELSE
		|				0
		|		END                                                        AS QuantityOnDaysOfFullSales
		|INTO ConsumptionByDay
		|FROM
		|	ConsumptionByDayInformationSecurityData AS Expense
		|		
		|		LEFT JOIN Constants AS Constants
		|		ON Expense.Warehouse.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|		
		|		LEFT JOIN ScheduleOfWorkAccordingToCalendar AS Workdays
		|		ON ISNULL(Constants.MainEnterpriseCalendar, Expense.Warehouse.Calendar) = Workdays.Calendar
		|		 AND Expense.Date = Workdays.Date
		|		
		|		LEFT JOIN SeasonalIndexes AS SeasonalIndexes
		|		ON SeasonalIndexes.Products = Expense.Products
		|		 AND SeasonalIndexes.Warehouse        = Expense.Warehouse
		|		
		|		LEFT JOIN SignsOfBalancesByDate AS SignsOfPresence
		|		ON SignsOfPresence.Date              = Expense.Date
		|			AND SignsOfPresence.Products   = Expense.Products
		|			AND SignsOfPresence.Characteristic = Expense.Characteristic
		|			AND SignsOfPresence.Warehouse          = Expense.Warehouse
		|WHERE
		|	NOT Workdays.Calendar IS NULL
		|		AND NOT SignsOfPresence.Products IS NULL
		|;
		|
		|/////////////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Expense.Products                                                          AS Products,
		|	Expense.Characteristic                                                        AS Characteristic,
		|	Expense.Warehouse                                                                 AS Warehouse,
		|	SUM(Expense.Count)                                                     AS Count,
		|	SUM(Expense.QuantityOnDaysOfFullSales)                                     AS QuantityOnDaysOfFullSales,
		|	SUM(Expense.Count * Expense.Count)                                 AS QuantitySquare,
		|	SUM(Expense.QuantityOnDaysOfFullSales * Expense.QuantityOnDaysOfFullSales) AS QuantityOnDaysOfFullSalesSquare
		|INTO Expenses
		|FROM
		|	ConsumptionByDay AS Expense
		|GROUP BY
		|	Expense.Products,
		|	Expense.Characteristic,
		|	Expense.Warehouse";
	
	Query.Execute();
	
EndProcedure

Procedure AddTemporaryTableToAccountForDays(Query)
	
	Query.Text =
		"SELECT
		|	SignsByDate.Products                     AS Products,
		|	SignsByDate.Characteristic                   AS Characteristic,
		|	SignsByDate.Warehouse                            AS Warehouse,
		|	Workdays.Date                                  AS Date,
		|	MAX(SignsByDate.Date)                   AS DateOfAttribute,
		|	MAX(SignsByDate.Date = Workdays.Date) AS CurDayAttributeIsUsed
		|INTO DatesOfSignsOfBalancesForDay
		|FROM
		|	SignsOfBalancesByDate AS SignsByDate
		|		
		|		LEFT JOIN Constants AS Constants
		|		ON SignsByDate.Warehouse.Calendar = VALUE(Catalog.Calendars.EmptyRef)
		|		
		|		INNER JOIN ScheduleOfWorkAccordingToCalendar AS Workdays
		|		ON ISNULL(Constants.MainEnterpriseCalendar, SignsByDate.Warehouse.Calendar) = Workdays.Calendar
		|		 AND SignsByDate.Date <= Workdays.Date
		|		
		|GROUP BY
		|	SignsByDate.Products,
		|	SignsByDate.Characteristic,
		|	SignsByDate.Warehouse,
		|	Workdays.Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DatesOfSigns.Products   AS Products,
		|	DatesOfSigns.Characteristic AS Characteristic,
		|	DatesOfSigns.Warehouse          AS Warehouse,
		|	DatesOfSigns.Date           AS Date,
		|	DatesOfSigns.CurDayAttributeIsUsed AND ISNULL(Expense.Count, 0) <> 0
		|		OR SignsByDate.IsClosingBalance AS Consider, // there is an expense on this day or there is a final balance on this day.
		|	DatesOfSigns.CurDayAttributeIsUsed AND SignsByDate.IsBalance
		|		OR NOT DatesOfSigns.CurDayAttributeIsUsed
		|				AND SignsByDate.IsClosingBalance AS DaysOfFullSales // there are movements on this day, and there is an initial and final remainder, or there are no movements on this day, and there was a final remainder on the previous day with movements.
		|INTO SignsOfAccountingDays
		|FROM
		|	DatesOfSignsOfBalancesForDay AS DatesOfSigns
		|		
		|		INNER JOIN SignsOfBalancesByDate AS SignsByDate
		|		ON SignsByDate.Date              = DatesOfSigns.DateOfAttribute
		|			AND SignsByDate.Products   = DatesOfSigns.Products
		|			AND SignsByDate.Characteristic = DatesOfSigns.Characteristic
		|			AND SignsByDate.Warehouse          = DatesOfSigns.Warehouse
		|		
		|		LEFT JOIN ConsumptionByDay AS Expense
		|		ON Expense.Date              = DatesOfSigns.Date
		|			AND Expense.Products   = DatesOfSigns.Products
		|			AND Expense.Characteristic = DatesOfSigns.Characteristic
		|			AND Expense.Warehouse          = DatesOfSigns.Warehouse
		|WHERE
		// Take into account or take into account the days of full sales
		|	DatesOfSigns.CurDayAttributeIsUsed
		|			AND ISNULL(Expense.Count, 0) <> 0
		|				OR SignsByDate.IsClosingBalance
		|		OR DatesOfSigns.CurDayAttributeIsUsed
		|				AND SignsByDate.IsBalance
		|		OR NOT DatesOfSigns.CurDayAttributeIsUsed
		|				AND SignsByDate.IsClosingBalance
		|;
		|
		|//////////////////////////////////////////
		|DROP DatesOfSignsOfBalancesForDay";
	Query.Execute();
	
EndProcedure

Function CreateEmptyGraph(ClassificationPeriodStartDate, ClassificationPeriodEndDate)
	
	ScheduleWithoutCalendar = New ValueTable();
	ScheduleWithoutCalendar.Columns.Add("ScheduleDate", New TypeDescription("Date"));
	
	If Not ValueIsFilled(Constants.MainEnterpriseCalendar.Get())
		And ValueIsFilled(ClassificationPeriodStartDate)
		And ValueIsFilled(ClassificationPeriodEndDate) Then
		
		ScheduleDate = ClassificationPeriodStartDate;
		While True Do
			
			If ScheduleDate > ClassificationPeriodEndDate Then
				Break;
			EndIf;
			
			TableRow = ScheduleWithoutCalendar.Add();
			TableRow.ScheduleDate = ScheduleDate;
			
			ScheduleDate = ScheduleDate + 86400;  //86400 - the duration of the day in seconds.
			
		EndDo;
		
	EndIf;
	
	Return ScheduleWithoutCalendar;
	
EndFunction

#EndRegion

#EndRegion