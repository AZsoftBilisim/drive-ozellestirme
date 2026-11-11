#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Populates the collection with data on the state of stocks
//
// Parameters:
//  Object - DataProcessorObject.GenerationOfPurchaseOrders - treatment,
//           you want to put data on the state of stocks.
//  Parameters - Structure - Structure containing calculation parameters:
//   Offsetting of inventory - Boolean - A sign of the need to use the entire Balance of the product in the calculation instead of the free Balance.
//
Procedure FillInByStockState(Object, Parameters) Export

	Query = New Query();
	Query.SetParameter("Warehouse", Object.Warehouse);
	SetParametersForCalculatingStatistics(Query, Object.SalesPeriod);

	GetInventoryData(Object.Inventories, TemporaryTableOfGoods_("Warehouse"), Query, Parameters);

EndProcedure

// Fills the collection with sales data
//
// Parameters:
//  Object - DataProcessorObject.GenerationOfPurchaseOrders - processing
//           to place sales data in,
//  Parameters - Structure - Structure containing calculation parameters:
//   Offsetting of inventory - Boolean - A sign of the need to use the entire Balance of the product in the calculation instead of the free Balance.
//
Procedure UpdateSalesData(Object, Parameters) Export

	Query = New Query();
	Query.SetParameter("ValueTable", Object.Inventories.Unload(, "Products, Characteristic, Warehouse"));
	SetParametersForCalculatingStatistics(Query, Object.SalesPeriod);

	GetInventoryData(Object.Inventories, TemporaryTableOfGoods_("ValueTable"), Query, Parameters);

EndProcedure

// Adds items to maintain inventory
//
// Parameters:
//  Object - DataProcessorObject.GenerationOfPurchaseOrders - processing
//           to add products to,
//  Table - ValueTable - A table containing the items to add,
//  Parameters - Structure - structure with fields:
//   * ModifiedTheInventoryTable - Boolean - Indicates that the inventory table will be modified.
//  InventoryLevel - String - The symbol of the element selection of the inventory level.
//  FulfillOrders - String - defines the method of accounting for balances.
Procedure AddProductsToInventoryTable(Object, Table, Parameters, InventoryLevel, FulfillOrders) Export

	ThereIsStockColumn = Table.Columns.Find("MaximumBalance") <> Undefined;
	If ThereIsStockColumn Then // the added table contains the values of the stock maintenance parameters

		RecordStockMaintenanceParameters(Table);

	EndIf;

	KeyFields = "Products,Characteristic,Warehouse";
	Table.Sort(KeyFields, New CompareValues);

	TableInventory = Object.Inventories.Unload();
	TableInventory.Columns.Add("SourceIndex_", TMCommonUse.GetDescriptionOfNumberTypes(10, 0));

	TotalRows = TableInventory.Count();
	For IndexOf = 0 To TotalRows - 1 Do
		TableInventory[IndexOf].SourceIndex_ = IndexOf;
	EndDo;

	TableInventory.Sort(KeyFields, New CompareValues);

	MergeParameters = SupplyClientServer.TableJoinParameters();
	MergeParameters.AddLines_ = True;
	SupplyServer.UpdateCollectionWithDataFromTable(TableInventory, Table, KeyFields, MergeParameters);

	For Each String In MergeParameters.ModifiedRows Do

		If ThereIsStockColumn Then
			FillPropertyValues(Object.Inventories[String.SourceIndex_], String, "MinimumBalance, MaximumBalance");
		EndIf;

	EndDo;

	Query = New Query();
	Query.SetParameter("ValueTable", MergeParameters.NewLines);
	SetParametersForCalculatingStatistics(Query, Object.SalesPeriod);

	GetInventoryData(MergeParameters.NewLines, TemporaryTableOfGoods_("ValueTable"), Query, Parameters);

	For Each String In MergeParameters.NewLines Do

		NewRow = Object.Inventories.Add();
		FillPropertyValues(NewRow, String);

		String.NotSatisfiesTheFilter = NotSatisfiesTheFilter(String, InventoryLevel, FulfillOrders);

		UpdateTotalsInRow(NewRow);

	EndDo;

	If MergeParameters.ModifiedRows.Count() > 0 And ThereIsStockColumn
		Or MergeParameters.NewLines.Count() > 0 Then

			Parameters.ModifiedTheInventoryTable = True;

	EndIf;

EndProcedure

// Updates the data in the "Product restrictions" register based on the table data.
//
// Parameters:
//  Table - ValueTable - Contains new parameters for maintaining inventory of goods, a table with fields:
//   Nomenclature - Reference link.Item - Product key field,
//   Feature - Reference link.Item - Product key field,
//   Warehouse - Reference link.Item - Product key field,
//   Minimum margin - Number - Value of the minimum margin,
//   The maximum stock is a number - The value of the maximum stock.
//
Procedure RecordStockMaintenanceParameters(Table) Export

	Query = New Query();
	Query.SetParameter("ValueTable", Table);
	Query.Text =
	"SELECT
	|	T.Products      AS Products,
	|	T.Characteristic    AS Characteristic,
	|	T.Warehouse             AS Warehouse,
	|
	|	T.MinimumBalance  AS MinimumBalance,
	|	T.MaximumBalance AS MaximumBalance
	|
	|INTO TTNewParameters
	|FROM
	|	&ValueTable AS T
	|INDEX BY
	|	Products, Characteristic
	|;
	|
	|/////////////////////////////////
	|SELECT
	|	NewParameters.Products      AS Products,
	|	NewParameters.Characteristic    AS Characteristic,
	|	NewParameters.Warehouse             AS Warehouse,
	|
	|	NewParameters.MinimumBalance  AS MinimumInventoryQuantity,
	|	NewParameters.MaximumBalance AS MaximumInventoryAmount
	|
	|FROM
	|	TTNewParameters AS NewParameters
	|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
	|		ON &SubstituteGoodsRestriction
	|WHERE
	|	ProductRestrictions.Products IS NULL
	|	OR ProductRestrictions.InventoryReplenishmentMethod <> VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax)
	|	OR NewParameters.MinimumBalance <> ProductRestrictions.MinimumInventoryQuantity
	|	OR NewParameters.MaximumBalance <> ProductRestrictions.MaximumInventoryAmount
	|	OR NewParameters.MaximumBalance = 0 AND NOT ProductRestrictions.Products IS NULL";

	Fields = "NewParameters.Products,NewParameters.Characteristic,NewParameters.Warehouse";
	Query.Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Query.Text, "SubstituteGoodsRestriction", Fields);
	
	BeginTransaction();
	Try
		
		SetPrivilegedMode(True);
		TableNewParameters = Query.Execute().Unload();
		
		KeysToDelete = New Array;
		For Each String In TableNewParameters Do
			If ValueIsFilled(String.Characteristic) Then
				RecordKey = InformationRegisters.ProductRestrictions.FeatureRecordingKey();
				RecordKey.Characteristic = String.Characteristic;
			Else
				RecordKey = InformationRegisters.ProductRestrictions.ProductEntryKey();
			EndIf;
			RecordKey.Products	= String.Products;
			RecordKey.Warehouse		= String.Warehouse;
			
			If String.MaximumInventoryAmount > 0 Then
				Parameters = InformationRegisters.ProductRestrictions.ParametersMinMax();
				Parameters.Insert("MinimumInventoryQuantity",	String.MinimumInventoryQuantity);
				Parameters.Insert("MaximumInventoryAmount",	String.MaximumInventoryAmount);
				InformationRegisters.ProductRestrictions.AddStockMaintenanceMinMax(RecordKey, Parameters);
			Else
				KeysToDelete.Add(RecordKey);
			EndIf;
		EndDo;
		
		If KeysToDelete.Count() > 0 Then
			InformationRegisters.ProductRestrictions.RemoveStockMaintenance(KeysToDelete);
		EndIf;
		
		SetPrivilegedMode(False);
		
		CommitTransaction();
	
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Tùy chọn nắm giữ hàng tồn kho';
							|ru = 'Запись параметров поддержания запаса';
							|en = 'Write inventory level control parameters'; fa = 'Write inventory level control parameters';
							|it = 'Salvataggio dei parametri di mantenimento delle scorte';
							|pl = 'Zapisywanie parametrów podtrzymywania zapasu';
							|tr = 'Stok yenileme parametrelerinin kaydedilmesi'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;

EndProcedure

// Calculates the quantity to order to maintain inventory
//
// Parameters:
//  State - FormDataCollectionItem, Structure - contains the inventory status data required for calculation.
//  SupplyFromStock - Boolean - Flag that determines whether to use data on available warehouse balances and
//                           orders to be received, or all balances and orders to be received in the calculation.
//
// Returns:
//  Structure - Structure with fields:
//   The exact order reached is a Boolean sign, true if the Balance is less than or equal to the minimum margin,
//   To Order - Number - The calculated quantity to order up to the maximum,
//   The Boolean mark indicates a recommendation for ordering this item.
//
Function ToOrderToMaintainStock(State, SupplyFromStock) Export

	Balance = ?(SupplyFromStock, State.Balance, State.AvailableStock);
	OnQualityControl = ?(SupplyFromStock, State.OnQualityControlBalance, State.UnderQualityControlAvailableBalance);
	OrdersPendingGoodsReceipt = ?(SupplyFromStock, State.OrdersPendingGoodsReceipt, State.OrdersPendingGoodsReceiptFree);
	OrderPointIsAchieved = Balance - State.MinimumBalance <= 0;
	If Not OrderPointIsAchieved Then
		ToOrder = Max(0, State.MaximumBalance - (Balance - State.MinimumBalance)
			- (OrdersPendingGoodsReceipt + OnQualityControl));
	Else
		ToOrder = State.MaximumBalance - (OrdersPendingGoodsReceipt + OnQualityControl);
	EndIf;

	If State.PieceUnitOfMeasure Then
		ToOrder = Int(ToOrder) + ?(Int(ToOrder) < ToOrder, 1, 0);
	EndIf;

	Return New Structure("OrderPointIsAchieved, ToOrder, Mark",
		OrderPointIsAchieved, ToOrder, OrderPointIsAchieved And ToOrder > 0);

EndFunction

// Calculates the values of service details for displaying totals in the form
//
// Parameters:
//  String - FormDataCollectionItem, Structure - contains the row data required for the calculation.
//
// Returns:
//  Structure - Structure with fields: Weight, Sum, Sum Total.
//
Function ServiceDetails_(String) Export

	Result = New Structure();
	Result.Insert("WeightTotal",   ?(String.Mark, String.Weight  * String.ToOrder, 0));
	Result.Insert("VolumeTotal", ?(String.Mark, String.ToOrder * String.VolumeM3, 0));
	Result.Insert("Sum",     String.Price * String.ToOrder);
	Result.Insert("AmountTotal", ?(String.Mark, Result.Sum, 0));

	Return Result;

EndFunction

// Based on the data from a row in the Inventory table, it calculates whether the row meets the remainder selection criteria.
//
// Parameters:
// String - FormDataCollectionItem - A string for which you need to determine whether the selection is satisfied.
// InventoryLevel - String - The symbol of the element selection of the inventory level.
// FulfillOrders - String - defines the method of accounting for balances.
//
// Returns:
// Boolean - Flag, false if the string satisfies the selection, true if it does not satisfy.
//
Function NotSatisfiesTheFilter(String, InventoryLevel, FulfillOrders) Export

	Balance = ?(FulfillOrders = TextAtExpenseOfRemainder(), String.Balance, String.AvailableStock);
	OrdersPendingGoodsReceipt = ?(FulfillOrders = TextAtExpenseOfRemainder(),
	String.OrdersPendingGoodsReceipt, String.OrdersPendingGoodsReceiptFree);

	Result = Not
				?(InventoryLevel = "LessThanMinBalance",           String.MinimumBalance     >= Balance,
				?(InventoryLevel = "LessThanTheDoubleMinimumBalance", String.MinimumBalance * 2 >= Balance,
				?(InventoryLevel = "OverMinimumBalance",           String.MinimumBalance     < Balance,
				?(InventoryLevel = "MoreThanMaxBalance",          String.MaximumBalance    < Balance + OrdersPendingGoodsReceipt,
					True))));

	Return Result;

EndFunction

// Fills the collection with order status data
//
// Parameters:
//  Object - FormDataStructure - data from the form of the processing object "creating orders for suppliers" - processing
//           in which you need to put data on the status of securing orders,
//  UseStockBalance - Boolean - indicates whether free balances are used to secure orders.
//
Procedure FillByOrderState(Object, UseStockBalance) Export
	
	QueriesTexts = New Array;
	
	QueriesTexts.Add(TemporaryOrdersTable());
	QueriesTexts.Add(TextOfRequestForTermsOfPurchase("TTOrders"));
	QueriesTexts.Add(TemporaryTableInventoryToOrder());
	
	QueriesTexts.Add(OrderRequestText());
	QueriesTexts.Add(RequestTextForBalancesFromOrders());
	
	Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("BeginOfPeriod", CurrentSessionDate()); //to get prices.
	Query.SetParameter("EndOfCurrentDay", EndOfDay(CurrentSessionDate()));
	Columns = "Products, Characteristic, Warehouse, ToOrder";
	If UseStockBalance Then
		Rows = New Structure("Mark", True);
	Else
		Rows = New Array;
	EndIf;
	Query.SetParameter("OrderRequirementsTable", Object.Inventories.Unload(Rows, Columns));
	Query.SetParameter("UseStockBalance", UseStockBalance);

	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TheOrdersTable          = QueryResults[QueryResults.Count() - 2].Unload();
	TableBalancesFromOrders = QueryResults[QueryResults.Count() - 1].Unload();

	Object.Orders.Clear();
	Object.Orders.Load(TheOrdersTable);
	KeyFields = "Products,Characteristic,Warehouse,Purpose,ReceivingBusinessUnit";
	AllocateQuantity(Object.Orders, TableBalancesFromOrders, KeyFields, "Supplied", "Required2");

	HighestPriority = Catalogs.Priorities.GetLowerPriority();
	LowestPriority = Catalogs.Priorities.GetTopPriority();
	
	For Each String In Object.Orders Do

		CalculationResult2 = ToOrderToSecureOrders(String);
		FillPropertyValues(String, CalculationResult2);

		CalculationResult2 = ServiceDetails_(String);
		FillPropertyValues(String, CalculationResult2);
		
		String.PictureOfPriority = ?(String.Priority = HighestPriority, 0, ?(String.Priority = LowestPriority, 2, 1));
		
	EndDo;

EndProcedure

// Creates documents based on filling in the tabular parts of the "forming orders to suppliers" processing.
//
// Parameters:
//  Object - FormDataStructure - data from the form of the processing object "creating orders for suppliers".
//
// Returns:
//  Structure - Structure with fields:
//   Documents - Array - an array of elements of the Document object type.To the requester, contains the created documents.
//   Messages - Array - array of error messages that occurred when creating and conducting documents.
//
Function CreateOrders(Object) Export

	DocumentsObjects = New Array();
	Messages        = New Array();

	Table = New ValueTable();
	Table.Columns.Add("Products",             New TypeDescription("CatalogRef.Products"));
	Table.Columns.Add("Characteristic",           New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table.Columns.Add("Warehouse",                    New TypeDescription("CatalogRef.Warehouses"));
	Table.Columns.Add("ReceivingBusinessUnit",  New TypeDescription("CatalogRef.BusinessStructure"));
	Table.Columns.Add("Purpose",               New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("Vendor",                New TypeDescription("CatalogRef.Partners"));
	Table.Columns.Add("Terms",               New TypeDescription("CatalogRef.TermsOfPurchaseFromVendors"));
	Table.Columns.Add("VendorPriceKind",        New TypeDescription("CatalogRef.VendorPriceTypes"));
	Table.Columns.Add("ToOrder",                  TMCommonUse.DescriptionOfQuantitativeFieldType());
	
	For Each String In Object.Inventories Do

		If String.Mark And String.ToOrder > 0 Then

			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);

		EndIf;

	EndDo;

	For Each String In Object.Orders Do

		If String.Mark And String.ToOrder > 0 Then

			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);

		EndIf;

	EndDo;

	Table.GroupBy("Products,Characteristic,Warehouse,ReceivingBusinessUnit,Purpose,Vendor,Terms,VendorPriceKind", "ToOrder");
	
	Query = New Query();
	Query.SetParameter("ValueTable", Table);
	Query.SetParameter("BegOfDay", BegOfDay(CurrentSessionDate()));
	
	Texts = New Array();
	
	Text = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	T.Products                               AS Products,
		|	T.Characteristic                             AS Characteristic,
		|	T.Warehouse                                      AS Warehouse,
		|	T.ReceivingBusinessUnit                    AS ReceivingBusinessUnit,
		|	T.Purpose                                 AS Purpose,
		|
		|	T.Vendor                                  AS Partner,
		|	T.Terms                                 AS Terms,
		|	T.VendorPriceKind                          AS VendorPriceKind,
		|
		|	T.ToOrder                                    AS Count
		|
		|INTO TTFillData
		|FROM
		|	&ValueTable AS T
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ISNULL(AllAgreements.ShipmentDueDate + AllAgreements.DeliveryTime, 0) AS DeliveryPeriodDays
		|INTO TTSearchParameters
		|FROM
		|	TTFillData AS FillingData
		|		
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AllAgreements
		|		ON AllAgreements.Ref = FillingData.Terms
		|INDEX BY
		|	DeliveryPeriodDays
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	Table.DeliveryPeriodDays AS DeliveryPeriodDays,
		|	CalculationOfDeliveryDateOverridable.DateFound AS DateOfReceipt
		|	
		|INTO TTScheduleDates
		|FROM
		|	TTSearchParameters AS Table
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|;
		|
		|//////////////////////////////////////////////
		|DROP TTSearchParameters";
	
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar("&BegOfDay", "Table.DeliveryPeriodDays");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.DateFound", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	FillingData.Partner AS Partner,
		|	FillingData.Terms AS Terms,
		|	FillingData.Warehouse AS Warehouse,
		|	FillingData.Products AS Products,
		|	MAX(FillingData.Products.VATRate) AS VATRate,
		|	FillingData.Characteristic AS Characteristic,
		|	FillingData.Purpose AS Purpose,
		|	MAX(ISNULL(FillingData.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
		|	FillingData.ReceivingBusinessUnit AS ReceivingBusinessUnit,
		|	FillingData.VendorPriceKind AS VendorPriceKind,
		|	ScheduleDates.DateOfReceipt AS DateOfReceipt,
		|	MAX(FillingData.Count) AS NumberOfPackages,
		|	MAX(FillingData.Count) AS Count
		|FROM
		|	TTFillData AS FillingData
		|		
		|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AllAgreements
		|		ON AllAgreements.Ref = FillingData.Terms
		|		
		|		LEFT JOIN TTScheduleDates AS ScheduleDates
		|		ON ISNULL(AllAgreements.ShipmentDueDate + AllAgreements.DeliveryTime, 0) = ScheduleDates.DeliveryPeriodDays
		|
		|GROUP BY
		|	FillingData.Terms,
		|	FillingData.Partner,
		|	FillingData.Warehouse,
		|	FillingData.Purpose,
		|	ScheduleDates.DateOfReceipt,
		|	FillingData.Products,
		|	FillingData.Characteristic,
		|	FillingData.ReceivingBusinessUnit,
		|	FillingData.VendorPriceKind
		|ORDER BY
		|	Terms, Partner, Warehouse, LineOfBusiness,                               // order bypass orders
		|	Purpose, DateOfReceipt, Products, Characteristic, ReceivingBusinessUnit // the order of the lines In the order";
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	OrdersToSupplierTable = Query.Execute().Unload();
	OrderKeyFields = "Terms, Partner, LineOfBusiness";
	ArrayOfTables = SupplyServer.SplitTableByKeyValue(OrdersToSupplierTable, OrderKeyFields);

	For Each Item In ArrayOfTables Do

		OrderKeyFields = "Warehouse";
		FillingData = Item.Key;
		TablesByWarehouse = SupplyServer.SplitTableByKeyValue(Item.Table, OrderKeyFields, "");

		TextComment = NStr("vi = 'Đã tạo bộ xử lý tự động ""Lập đơn hàng đặt nhà cung cấp"".';
							|ru = 'Сформирован автоматически обработкой ""Формирование заказов поставщикам"".';
							|en = 'Generated automatically using the ""Purchase order generation"" data processor.'; fa = 'Generated automatically using the ""Purchase order generation"" data processor.';
							|it = 'Formato automaticamente dall''elaborazione ""Generazione di ordini ai fornitori"".';
							|pl = 'Utworzony automatycznie przez przetwarzanie ""Формирование заказов поставщикам"".';
							|tr = '""Satın alma siparişi oluşturma"" işlemi tarafından otomatik olarak oluşturuldu.'");
		FillingData.Insert("Comment", TextComment);

		If TablesByWarehouse.Count() = 2 //If there is only one order with goods, then we add work to it.
			And Not ValueIsFilled(TablesByWarehouse[0].Table[0].Warehouse) Then

			CommonClientServer.SupplementTable(TablesByWarehouse[0].Table, TablesByWarehouse[1].Table);
			TablesByWarehouse.Delete(0);

		EndIf;

		For Each Item1 In TablesByWarehouse Do

			FillingData.Insert("Warehouse", Item1.Key.Warehouse);
			ColumnVT = Item1.Table.Columns.ReceivingBusinessUnit; // ValueTableColumn - 
			ColumnVT.Name = "Department";
			FillingData.Insert("Goods", Item1.Table);
			Document = DataProcessors.DemandFulfillment.FillInAndHoldDocument(
				Documents.PurchaseOrder, FillingData, Enums.PurchaseOrderStatuses.Confirmed_, Messages);
			DocumentsObjects.Add(Document);

		EndDo;

	EndDo;
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();

	Result = New Structure("Documents, Messages", DocumentsObjects, Messages);
	Return Result;

EndFunction

#EndRegion

#Region Private

#Region AddingStocksToTable

Procedure GetInventoryData(Table, TemporaryTableOfGoods_, Query, Parameters)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = TemporaryTableOfGoods_;
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	SupplyServer.AddTemporaryTableOfConsumptionStatistics(Query, "TTProducts_1");
	
	SetPrivilegedMode(False);

	QueriesTexts = New Array;
	
	QueriesTexts.Add(TextOfRequestForTermsOfPurchase());
	
	QueriesTexts.Add(TableProductRestrictions());
	QueriesTexts.Add(TableConsumptionStatistics());
	LongDesc = InventoryAllocation();
	NumberOfTables = LongDesc.NumberOfTables;
	QueriesTexts.Add(LongDesc.QueryText);
	QueriesTexts.Add(TableBalance());
	QueriesTexts.Add(OrdersToReceiveTable());
	QueriesTexts.Add(TableTermsOfPurchase());
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query.SetParameter("BeginOfPeriod", CurrentSessionDate()); //to get prices.
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TotalTables = QueryResults.Count();
	
	SampleProductRestrictions   = QueryResults[TotalTables - NumberOfTables - 5].Select();
	TableOfConsumptionStatistics = QueryResults[TotalTables - NumberOfTables - 4].Unload();
	TableBalance               = QueryResults[TotalTables - 3].Unload();
	OrdersToReceiveTable    = QueryResults[TotalTables - 2].Unload();
	TableTermsOfPurchase        = QueryResults[TotalTables - 1].Unload();
	
	Table.Clear();
	
	While SampleProductRestrictions.Next() Do
		FillPropertyValues(Table.Add(), SampleProductRestrictions);
	EndDo;
	
	KeyFields = "Products,Characteristic,Warehouse";
	SupplyServer.UpdateCollectionWithDataFromTable(Table, TableOfConsumptionStatistics, KeyFields);
	SupplyServer.UpdateCollectionWithDataFromTable(Table, TableBalance, KeyFields);
	SupplyServer.UpdateCollectionWithDataFromTable(Table, OrdersToReceiveTable, KeyFields);
	SupplyServer.UpdateCollectionWithDataFromTable(Table, TableTermsOfPurchase, KeyFields);
	
	For Each String In Table Do
		
		CalculationResult2 = ToOrderToMaintainStock(String, Parameters.SupplyFromStock);
		FillPropertyValues(String, CalculationResult2);
		
		CalculationResult2 = ServiceDetails_(String);
		FillPropertyValues(String, CalculationResult2);
		
	EndDo;
	
EndProcedure

Procedure SetParametersForCalculatingStatistics(Query, SalesPeriod)
	
	Days1 = 86400;
	EndDate = EndOfDay(CurrentSessionDate()) - Days1;
	StartDate    = BegOfDay(EndDate) - Days1 * (SalesPeriod - 1);
	If EndDate < StartDate Then
		EndDate = StartDate;
	EndIf;
	
	SupplyServer.SetParametersForStatisticsCalculationRequest(Query, New StandardPeriod(StartDate, EndDate));
	
EndProcedure

Procedure UpdateTotalsInRow(String)

	String.WeightTotal   = ?(String.Mark, String.ToOrder * String.Weight, 0);
	String.VolumeTotal = ?(String.Mark, String.ToOrder * String.VolumeM3, 0);
	String.Sum     = String.Price * String.ToOrder;
	String.AmountTotal = ?(String.Mark, String.Sum, 0);

EndProcedure

#EndRegion

#Region StockStateQueryTexts

Function TableProductRestrictions()

	Text =
		"SELECT
		|	Goods.Products       AS Products,
		|	Goods.Characteristic     AS Characteristic,
		|	Goods.Warehouse              AS Warehouse,
		|
		|	ISNULL(ProductRestrictions.MinimumInventoryQuantity, 0)  AS MinimumBalance,
		|	ISNULL(ProductRestrictions.MaximumInventoryAmount, 0) AS MaximumBalance,
		|
		|	&QueryTextItemWeight              AS Weight,
		|	&QueryTextTheVolumeOfTheItem            AS VolumeM3,
		|	CatProducts.UnitOfMeasure AS UnitOfMeasure,
		|	CatProducts.SKU          AS SKU,
		|	CatProducts.Code              AS Code,
		|
		|	CASE WHEN CatProducts.UnitOfMeasure.MeasuredValueType
		|		= VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END                            AS PieceUnitOfMeasure
		|FROM
		|	TTProducts_1 AS Goods
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction
		|
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON Goods.Products = CatProducts.Ref
		|
		|ORDER BY
		|	Products, Characteristic, Warehouse";

	Text = StrReplace(Text,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"CatProducts.UnitOfMeasure",
		"CatProducts"));
	Text = StrReplace(Text,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"CatProducts.UnitOfMeasure",
		"CatProducts"));
		
	Fields = "Goods.Products,Goods.Characteristic,Goods.Warehouse";
	Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Text, "SubstituteGoodsRestriction", Fields);
	Return Text;

EndFunction

Function TemporaryTableOfGoods_(Source)
	
	If Source = "Warehouse" Then
		
		Return InformationRegisters.ProductRestrictions.TemporaryTableGoodsOfSupportedStock() +
			"SELECT
			|	T.Products       AS Products,
			|	T.Characteristic     AS Characteristic,
			|	T.Warehouse              AS Warehouse
			|INTO TTProducts_1
			|FROM
			|	TTGoodsOfSupportedStock AS T
			|
			|WHERE
			|	T.Warehouse = &Warehouse
			|INDEX BY
			|	Products, Characteristic, Warehouse";
		
	ElsIf Source = "ValueTable" Then
		
		Return
			"SELECT
			|	T.Products       AS Products,
			|	T.Characteristic     AS Characteristic,
			|	T.Warehouse              AS Warehouse
			|INTO TTProducts_1
			|FROM
			|	&ValueTable AS T
			|
			|INDEX BY
			|	Products, Characteristic, Warehouse";
		
	EndIf;
	
EndFunction

Function TableConsumptionStatistics()
	
	Return
		"SELECT
		|	T.Products      AS Products,
		|	T.Characteristic    AS Characteristic,
		|	T.Warehouse             AS Warehouse,
		|
		|	T.AverageDailyConsumption  AS AverageDailyConsumption,
		|	T.Consumption               AS Sales
		|
		|FROM
		|	TTConsumptionStatistics AS T
		|
		|ORDER BY
		|	Products, Characteristic, Warehouse";
	
EndFunction

Function InventoryAllocation()
	
	QueryText =
		"SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|			FROM
		|				TTProducts_1 AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|	
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|			FROM
		|				TTProducts_1 AS Filter)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose";
		
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "CalculationOfInventoryDistribution"; // @query-part-1
	
	Texts = ProvisionInDocumentsServer.InventoryAllocation("", TablesNames);
	Text = StrConcat(Texts, Common.QueryBatchSeparator());
	TotalTables = Texts.Count() + 2;
	
	Texts = New Array();
	Texts.Add(QueryText);
	Texts.Add(Text);
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return New Structure("NumberOfTables, QueryText", TotalTables, QueryText);
	
EndFunction

Function TableBalance()
	
	Text =
		"SELECT
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.InStock AS Balance,
		|	Inventories.Available_Surplus AS AvailableStock,
		|	Inventories.AvailableWithLock AS OnQualityControlBalance,
		|	Inventories.AvailableWithLock_Surplus AS UnderQualityControlAvailableBalance
		|FROM
		|	CalculationOfInventoryDistribution AS Inventories
		|WHERE
		|	Inventories.InStock <> 0
		|		OR Inventories.Available_Surplus <> 0
		|		OR Inventories.AvailableWithLock <> 0
		|		OR Inventories.AvailableWithLock_Surplus <> 0
		|ORDER BY
		|	Products, Characteristic, Warehouse";
	
	Return Text;

EndFunction

Function OrdersToReceiveTable()
	
	Text =
		"SELECT
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Expected_
		|		+ Inventories.ExpectedWithBlocking
		|		+ Inventories.AwaitingApproval AS OrdersPendingGoodsReceipt,
		|	Inventories.Expected_Surplus
		|		+ Inventories.ExpectedWithLock_Surplus
		|		+ Inventories.OnApproval_Surplus AS OrdersPendingGoodsReceiptFree
		|FROM
		|	CalculationOfInventoryDistribution AS Inventories
		|WHERE
		|	Inventories.Expected_
		|		+ Inventories.ExpectedWithBlocking
		|		+ Inventories.AwaitingApproval > 0
		|ORDER BY
		|	Products, Characteristic, Warehouse";
	
	Return Text;

EndFunction

Function TextOfRequestForTermsOfPurchase(Source = Undefined)
	
	Text =
		"SELECT //Last order date
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|
		|	MAX(Goods.Ref.Date) AS LastOrderDate
		|
		|INTO TTLastOrderDate
		|FROM
		|	TTProducts_1 AS T
		|		INNER JOIN Document.PurchaseOrder.Goods AS Goods
		|		ON T.Products   = Goods.Products
		|		 AND T.Characteristic = Goods.Characteristic
		|		 AND T.Warehouse          = Goods.Warehouse
		|WHERE
		|	Goods.Ref.Posted
		|GROUP BY
		|	T.Products, T.Characteristic, T.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT //Date of the penultimate order.
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|	MAX(T.LastOrderDate)  AS LastOrderDate,
		|	MAX(CASE WHEN T.LastOrderDate = Goods.Ref.Date THEN
		|				NULL
		|			ELSE Goods.Ref.Date
		|		END)                        AS DateOfPenultimateOrder
		|	
		|INTO TTIsDateOfPenultimateOrder
		|FROM
		|	TTLastOrderDate AS T
		|		INNER JOIN Document.PurchaseOrder.Goods AS Goods
		|		ON T.Products   = Goods.Products
		|		 AND T.Characteristic = Goods.Characteristic
		|		 AND T.Warehouse          = Goods.Warehouse
		|WHERE
		|	Goods.Ref.Posted
		|GROUP BY
		|	T.Products, T.Characteristic, T.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT // Date of the third order.
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|	MAX(T.LastOrderDate)     AS LastOrderDate,
		|	MAX(T.DateOfPenultimateOrder) AS DateOfPenultimateOrder,
		|	MAX(CASE WHEN Goods.Ref.Date IN (T.LastOrderDate, T.DateOfPenultimateOrder) THEN
		|				NULL
		|			ELSE Goods.Ref.Date
		|		END)                           AS ThirdOrderDate
		|	
		|INTO TTThirdOrderDate
		|FROM
		|	TTIsDateOfPenultimateOrder AS T
		|		INNER JOIN Document.PurchaseOrder.Goods AS Goods
		|		ON T.Products   = Goods.Products
		|		 AND T.Characteristic = Goods.Characteristic
		|		 AND T.Warehouse          = Goods.Warehouse
		|WHERE
		|	Goods.Ref.Posted
		|GROUP BY
		|	T.Products, T.Characteristic, T.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT //The last three orders by position.
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|
		|	MAX(CASE WHEN T.LastOrderDate = Goods.Ref.Date THEN
		|				Goods.Ref
		|			ELSE NULL
		|		END)                           AS OrderDocument1,
		|	MAX(CASE WHEN T.DateOfPenultimateOrder = Goods.Ref.Date THEN
		|				Goods.Ref
		|			ELSE NULL
		|		END)                           AS OrderDocument2,
		|	MAX(CASE WHEN T.ThirdOrderDate = Goods.Ref.Date THEN
		|				Goods.Ref
		|			ELSE NULL
		|		END)                           AS OrderDocument3
		|
		|INTO TTLastThreeOrders
		|FROM
		|	TTThirdOrderDate AS T
		|		INNER JOIN Document.PurchaseOrder.Goods AS Goods
		|		ON T.Products   = Goods.Products
		|		 AND T.Characteristic = Goods.Characteristic
		|		 AND T.Warehouse          = Goods.Warehouse
		|		 AND Goods.Ref.Date IN (T.LastOrderDate, T.DateOfPenultimateOrder, T.ThirdOrderDate)
		|WHERE
		|	Goods.Ref.Posted
		|GROUP BY
		|	T.Products, T.Characteristic, T.Warehouse
		|INDEX BY
		|	OrderDocument1, OrderDocument2, OrderDocument3
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT //Data for filling in the source of collateral and terms of purchase.
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|
		|	CASE WHEN T.OrderDocument2.Partner IS NULL THEN
		|				T.OrderDocument1.Partner
		|			WHEN T.OrderDocument3.Partner IS NULL THEN
		|				CASE WHEN T.OrderDocument1.Partner = T.OrderDocument2.Partner THEN
		|							T.OrderDocument1.Partner
		|						ELSE VALUE(Catalog.Partners.EmptyRef)
		|					END
		|			ELSE
		|				CASE WHEN T.OrderDocument1.Partner = T.OrderDocument2.Partner OR T.OrderDocument1.Partner = T.OrderDocument3.Partner THEN
		|							T.OrderDocument1.Partner
		|						WHEN T.OrderDocument2.Partner = T.OrderDocument3.Partner THEN
		|							T.OrderDocument2.Partner
		|						ELSE VALUE(Catalog.Partners.EmptyRef)
		|					END
		|		END       AS Partner,
		|
		|	CASE WHEN T.OrderDocument2.Partner IS NULL THEN
		|				T.OrderDocument1.Terms
		|			WHEN T.OrderDocument3.Partner IS NULL THEN
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms THEN
		|							T.OrderDocument1.Terms
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|			ELSE
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms OR T.OrderDocument1.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument1.Terms
		|						WHEN T.OrderDocument2.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument2.Terms
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|		END       AS Terms,
		|
		|	CASE WHEN T.OrderDocument2.Partner IS NULL THEN
		|				T.OrderDocument1.Terms.Currency
		|			WHEN T.OrderDocument3.Partner IS NULL THEN
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms THEN
		|							T.OrderDocument1.Terms.Currency
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|			ELSE
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms OR T.OrderDocument1.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument1.Terms.Currency
		|						WHEN T.OrderDocument2.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument2.Terms.Currency
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|		END       AS Currency,
		|
		|	CAST(CASE WHEN T.OrderDocument2.Partner IS NULL THEN
		|				T.OrderDocument1.Terms
		|			WHEN T.OrderDocument3.Partner IS NULL THEN
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms THEN
		|							T.OrderDocument1.Terms
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|			ELSE
		|				CASE WHEN T.OrderDocument1.Terms = T.OrderDocument2.Terms OR T.OrderDocument1.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument1.Terms
		|						WHEN T.OrderDocument2.Terms = T.OrderDocument3.Terms THEN
		|							T.OrderDocument2.Terms
		|						ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
		|					END
		|		END AS Catalog.TermsOfPurchaseFromVendors).VendorPriceKind AS VendorPriceKind
		|
		|INTO TTFillData
		|FROM
		|	TTLastThreeOrders AS T
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	
	If ValueIsFilled(Source) Then
		Text = StrReplace(Text, "TTProducts_1", Source);
	EndIf;
	
	Return Text;
	
EndFunction

Function TableTermsOfPurchase()
	
	Return
		"SELECT
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|	T.Partner        AS Vendor,
		|	T.VendorPriceKind AS VendorPriceKind,
		|	T.Terms     AS Terms,
		|
		|	SupplierPrices.Price                   AS Price,
		|	SupplierPrices.Package               AS Package,
		|	SupplierPrices.Currency                 AS Currency
		|FROM
		|	TTFillData AS T
		|		LEFT JOIN InformationRegister.ItemsPricesOfVendor.SliceLast(
		|			ENDOFPERIOD(&BeginOfPeriod, DAY),
		|			(Products, Characteristic, Partner, VendorPriceKind)IN (
		|				SELECT
		|					T.Products           AS Products,
		|					T.Characteristic         AS Characteristic,
		|					T.Partner                AS Partner,
		|					T.VendorPriceKind      AS VendorPriceKind
		|				FROM
		|					TTFillData AS T)) AS SupplierPrices
		|		ON T.Products   = SupplierPrices.Products
		|		 AND T.Characteristic = SupplierPrices.Characteristic
		|ORDER BY
		|	Products, Characteristic, Warehouse";
	
EndFunction

#EndRegion

#Region FillingByStateOfOrders

Function TemporaryOrdersTable()
	
	Text =
		"SELECT ALLOWED // Shipping order lines
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.ReceivingBusinessUnit AS ReceivingBusinessUnit,
		|	Set.OrderDocument AS OrderDocument,
		|	Set.Purpose AS Purpose,
		|	Set.DateOfShipment AS DateOfShipment,
		|	SUM(Set.Required2) AS Required2,
		|	SUM(Set.Supplied) AS Supplied
		|INTO TTOrders
		|FROM(
		|SELECT
		|	Demands.Products                               AS Products,
		|	Demands.Characteristic                             AS Characteristic,
		|	
		|	CASE WHEN Demands.Warehouse REFS Catalog.Warehouses THEN
		|				Demands.Warehouse
		|			ELSE
		|				UNDEFINED
		|		END AS Warehouse,
		|	
		|	CASE WHEN Demands.Warehouse REFS Catalog.BusinessStructure THEN
		|				Demands.Warehouse
		|			ELSE
		|				UNDEFINED
		|		END AS ReceivingBusinessUnit,
		|	
		|	Demands.ShipmentOrder                             AS OrderDocument,
		|	Demands.Purpose                                  AS Purpose,
		|	Demands.RequestShipmentOn                        AS DateOfShipment,
		|	Demands.Count AS Required2,
		|	CASE
		|		WHEN
		|			Demands.InventoryState IN(
		|				VALUE(Enum.InventoryStates.InStock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval))
		|			THEN Demands.Count
		|		ELSE 0
		|	END AS Supplied
		|	FROM
		|		InformationRegister.InventoryAllocation AS Demands
		|	WHERE
		|		(Demands.Warehouse = &Warehouse OR NOT Demands.Warehouse REFS Catalog.Warehouses)
		|			AND Demands.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|				VALUE(Enum.DemandCharacteristics.ToSupply))
		|UNION ALL
		|
		|SELECT
		|	Demands.Products                               AS Products,
		|	Demands.Characteristic                             AS Characteristic,
		|	
		|	CASE WHEN Demands.Warehouse REFS Catalog.Warehouses THEN
		|				Demands.Warehouse
		|			ELSE
		|				UNDEFINED
		|		END AS Warehouse,
		|	
		|	CASE WHEN Demands.Warehouse REFS Catalog.BusinessStructure THEN
		|				Demands.Warehouse
		|			ELSE
		|				UNDEFINED
		|		END AS ReceivingBusinessUnit,
		|	
		|	Demands.ProductionOrder                        AS OrderDocument,
		|	Demands.Purpose                                 AS Purpose,
		|	Demands.ProductionOrder.EarliestStartDate          AS DateOfShipment,
		|	Demands.ToSupply - Demands.Replaced
		|		- Demands.AllocatedFromAvailableInventory
		|		- Demands.AllocatedFromAvailableInventoryWithAssignment
		|		- Demands.AllocatedInFreeProductionLots
		|		- Demands.AllocatedInAssignedProductionLots
		|		- Demands.Scheduled                        AS Required2,
		|	0 AS Supplied
		|	
		|	FROM
		|		InformationRegister.OrderStructure AS Demands
		|
		|	WHERE
		|		(Demands.Warehouse = &Warehouse OR NOT Demands.Warehouse REFS Catalog.Warehouses)
		|			AND Demands.LineKind NOT IN (
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
		|
		|) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.ReceivingBusinessUnit,
		|	Set.OrderDocument,
		|	Set.Purpose,
		|	Set.DateOfShipment
		|HAVING
		|	SUM(Set.Required2) > 0
		|INDEX BY
		|	Products";

	Return Text;

EndFunction

Function OrderRequestText()
	
	Text =
		"SELECT
		|	T.Products                         AS Products,
		|	T.Characteristic                       AS Characteristic,
		|	T.Warehouse                                AS Warehouse,
		|	T.ReceivingBusinessUnit              AS ReceivingBusinessUnit,
		|	T.OrderDocument                                AS OrderDocument,
		|	T.Purpose                           AS Purpose,
		|	T.DateOfShipment                         AS DateOfShipment,
		|	T.Required2                            AS Required2,
		|	T.Supplied                           AS Supplied,
		|	&QueryTextItemWeight           AS Weight,
		|	&QueryTextTheVolumeOfTheItem         AS VolumeM3,
		|	CatProducts.UnitOfMeasure       AS UnitOfMeasure,
		|	CatProducts.SKU                AS SKU,
		|	CatProducts.Code                    AS Code,
		|	FillingData.Partner               AS Vendor,
		|	FillingData.Terms            AS Terms,
		|	FillingData.VendorPriceKind     AS VendorPriceKind,
		|	SupplierPrices.Price                   AS Price,
		|	SupplierPrices.Package               AS Package,
		|	SupplierPrices.Currency                 AS Currency,
		|	ReportOrders.Priority                AS Priority,
		|	CASE
		|		WHEN NOT OrderingByDocumentDate.Value IS NULL
		|			THEN UNDEFINED
		|		WHEN T.DateOfShipment > &EndOfCurrentDay
		|			THEN T.DateOfShipment
		|		WHEN &CheckingStageTakingIntoAccountOverridableRights
		|			THEN &DateOfProductionOrderTakingIntoAccountRightsOverridable
		|		WHEN TRUE
		|			THEN ReportOrders.IBDocumentDate
		|	END AS Order,
		|	CASE
		|		WHEN &CheckingStageTakingIntoAccountOverridableRights
		|			THEN &DateOfProductionOrderTakingIntoAccountRightsOverridable
		|		WHEN TRUE
		|			THEN ReportOrders.IBDocumentDate
		|	END AS IBDocumentDate,
		|	CASE
		|		WHEN T.DateOfShipment > &EndOfCurrentDay
		|			THEN T.DateOfShipment
		|		WHEN &CheckingStageTakingIntoAccountOverridableRights
		|			THEN &DateOfProductionOrderTakingIntoAccountRightsOverridable
		|		WHEN TRUE
		|			THEN ReportOrders.IBDocumentDate
		|	END AS OrderByShipmentDateAfterDocumentDate
		|FROM
		|	TTOrders AS T
		|		LEFT JOIN TTFillData AS FillingData
		|		ON T.Products = FillingData.Products
		|		 AND T.Characteristic = FillingData.Characteristic
		|		 AND T.Warehouse = FillingData.Warehouse
		|		LEFT JOIN InformationRegister.ItemsPricesOfVendor.SliceLast(
		|			ENDOFPERIOD(&BeginOfPeriod, DAY),
		|			(Products, Characteristic, Partner, VendorPriceKind)IN (
		|				SELECT
		|					T.Products           AS Products,
		|					T.Characteristic         AS Characteristic,
		|					T.Partner                AS Partner,
		|					T.VendorPriceKind      AS VendorPriceKind
		|				FROM
		|					TTFillData AS T)) AS SupplierPrices
		|		ON T.Products   = SupplierPrices.Products
		|		 AND T.Characteristic = SupplierPrices.Characteristic
		|
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON T.Products = CatProducts.Ref
		|		
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS ReportOrders
		|		ON ReportOrders.Ref = T.OrderDocument
		|		 AND NOT ReportOrders.AdditionalRecord
		|		
		|		LEFT JOIN Constant.OptionOfOrderingDemandsByOrdersForSupply AS OrderingByDocumentDate
		|		ON OrderingByDocumentDate.Value = VALUE(Enum.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate)
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ReceivingBusinessUnit,
		|	Priority,
		|	Order,
		|	IBDocumentDate,
		|	OrderByShipmentDateAfterDocumentDate,
		|	OrderDocument";
	
	Text = StrReplace(Text,
		"&QueryTextItemWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
		"CatProducts.UnitOfMeasure",
		"CatProducts"));
	Text = StrReplace(Text,
		"&QueryTextTheVolumeOfTheItem",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
		"CatProducts.UnitOfMeasure",
		"CatProducts"));
	
	CheckingTextStage = "FALSE";
	ProductionOrderDateText = "DATETIME(1, 1, 1)";
	If AccessRight("Read", Metadata.Documents.ProductionStage2_2)
			And AccessRight("Read", Metadata.Documents.ProductionOrder2_2) Then
				
				CheckingTextStage = "VALUETYPE(T.OrderDocument) = TYPE(Document.ProductionStage2_2)";
				ProductionOrderDateText = "CAST(T.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder.Date";
				
	EndIf;
	Text = StrReplace(Text, "&CheckingStageTakingIntoAccountOverridableRights", CheckingTextStage);
	Text = StrReplace(Text, "&DateOfProductionOrderTakingIntoAccountRightsOverridable", ProductionOrderDateText);
	
	Return Text;
	
EndFunction

Function TemporaryTableInventoryToOrder()
	
	Return
		"SELECT
		|	T.Products               AS Products,
		|	T.Characteristic             AS Characteristic,
		|	T.Warehouse                      AS Warehouse,
		|	T.ToOrder                    AS Count
		|
		|INTO TTInventoryToOrder
		|FROM
		|	&OrderRequirementsTable AS T
		|WHERE
		|	T.ToOrder > 0";
	
EndFunction

Function RequestTextForBalancesFromOrders()
	
	Text =
		// The quantity to the order to maintain inventory in the current session of work with the processing of the formation of orders.
		"SELECT
		|	T.Products                                         AS Products,
		|	T.Characteristic                                       AS Characteristic,
		|	T.Warehouse                                                AS Warehouse,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS ReceivingBusinessUnit,
		|	VALUE(Catalog.Assignments.EmptyRef)           AS Purpose,
		|	T.Count                                           AS Supplied
		|FROM
		|	TTInventoryToOrder AS T
		|
		|ORDER BY
		|	Products, Characteristic, Warehouse, Purpose, ReceivingBusinessUnit";
	
	Return Text;
	
EndFunction


Procedure AllocateQuantity(Collection, Table, String_Key, FieldNameQuantity, FieldNameMax)

	KeyFields = StrSplit(String_Key, ",");
	ReceiverIndex = 0;
	IndexOf = 0;
	CompareValues = New CompareValues();
	While IndexOf < Table.Count() And ReceiverIndex < Collection.Count() Do

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

			IndexOf = IndexOf + 1;

		ElsIf KeyComparisonResult > 0 Then

			ReceiverIndex = ReceiverIndex + 1;

		Else

			DistributedQuantity = Min(DestinationRow[FieldNameMax] - DestinationRow[FieldNameQuantity],
				String[FieldNameQuantity]);
			String[FieldNameQuantity] = String[FieldNameQuantity] - DistributedQuantity;
			DestinationRow[FieldNameQuantity] = DestinationRow[FieldNameQuantity] + DistributedQuantity;
			ReceiverIndex = ReceiverIndex + 1;

		EndIf;

	EndDo;

EndProcedure

Function ToOrderToSecureOrders(State)

	ToOrder = State.Required2 - State.Supplied;
	Mark = ToOrder > 0;
	Return New Structure("ToOrder, Mark", ToOrder, Mark);

EndFunction

Function TextAtExpenseOfRemainder()

	Return NStr("vi = 'Do sự cân bằng';
				|ru = 'За счет остатка';
				|en = 'Use stock balance'; fa = 'استفاده از مانده موجودی';
				|it = 'Per il resto della fattura pro-forma';
				|pl = 'Z ostatka';
				|tr = 'Bakiye hesabına'");

EndFunction

#EndRegion

#EndRegion

#EndIf
