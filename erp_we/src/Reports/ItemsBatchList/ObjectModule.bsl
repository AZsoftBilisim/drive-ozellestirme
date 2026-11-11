#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	FilterProducts = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Products").Value;
	FilterSeries = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Series").Value;
	
	If Not ValueIsFilled(FilterProducts)
		And Not ValueIsFilled(FilterSeries) Then
		
		MessageText = NStr("vi = 'Vui lòng thiết lập bộ lọc theo mặt hàng hoặc sê-ri.';
							|ru = 'Установите отбор по номенклатуре или серии.';
							|en = 'Set the filter by item or batch.'; fa = 'Set the filter by item or batch.';
							|it = 'Set the filter by item or batch.';
							|pl = 'Set the filter by item or batch.';
							|tr = 'Filtreyi öğeye veya seriye göre ayarlayın.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	SetRequiredSettings();
	
	DataCompositionSchema.DataSets.RemnantsOfSeries.Query = QueryTextReport_();
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings()
	
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"RecipientTypeDepartment",
		NStr("vi = 'Bộ phận';
			|ru = 'Подразделение';
			|en = 'Business unit'; fa = 'Business unit';
			|it = 'Reparto';
			|pl = 'Dział';
			|tr = 'Departman'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"RecipientTypeCustomer",
		NStr("vi = 'Khách hàng';
			|ru = 'Покупатель';
			|en = 'Customer'; fa = 'مشتری';
			|it = 'Acquirente';
			|pl = 'Nabywca';
			|tr = 'Müşteri'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer,
		"RecipientTypeWarehouse",
		NStr("vi = 'Kho bãi';
			|ru = 'Склад';
			|en = 'Warehouse'; fa = 'Warehouse';
			|it = 'Magazzino';
			|pl = 'Warehouse';
			|tr = 'Ambar'"));
	
EndProcedure

Function QueryTextReport_()
	
	QueryText =
	"SELECT
	|	Products.Ref AS Ref,
	|	TypesOfProductPolicyAccountingSeries.Warehouse AS Warehouse
	|INTO ProductsForWhichBalancesAreNotMaintained
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
	|		ON TypesOfProductPolicyAccountingSeries.Ref = Products.ProductKind
	|WHERE
	|	CASE
	|		WHEN &Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN &Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE Products.Ref = &Products
	|	END
	|	AND TypesOfProductPolicyAccountingSeries.BatchAccountingPolicy.PolicyType IN
	|	(VALUE(Enum.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification),
	|		VALUE(Enum.TypesOfBatchSpecificationPolicies.FEFOAutoCalculationOfRemainingBatch))
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductStock.Recorder AS Recorder,
	|	ProductStock.SecondPeriod AS SecondPeriod,
	|	ProductStock.DayPeriod AS DayPeriod,
	|	ProductStock.WeekPeriod AS WeekPeriod,
	|	ProductStock.TenDaysPeriod AS TenDaysPeriod,
	|	ProductStock.MonthPeriod AS MonthPeriod,
	|	ProductStock.QuarterPeriod AS QuarterPeriod,
	|	ProductStock.HalfYearPeriod AS HalfYearPeriod,
	|	ProductStock.YearPeriod AS YearPeriod,
	|	ProductStock.Products AS Products,
	|	ProductStock.Characteristic AS Characteristic,
	|	ProductStock.Series AS Series,
	|	ProductStock.Warehouse AS Recipient,
	|	ProductStock.Premise AS Premise,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockOpeningBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockOpeningBalance / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockReceipt
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockReceipt / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockExpense
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockExpense / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockClosingBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockClosingBalance / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Balance,
	|	&RecipientTypeWarehouse AS TypeRecipient,
	|	TRUE AS RemainingGoodsAvailable
	|{SELECT
	|	Recorder.*,
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	Products.*,
	|	Characteristic.*,
	|	Series.*,
	|	Recipient.*,
	|	Premise.*,
	|	InitialBalance,
	|	Receipt,
	|	Expense,
	|	Balance,
	|	TypeRecipient,
	|	RemainingGoodsAvailable}
	|FROM
	|	AccumulationRegister.ProductStock.BalanceAndTurnovers(,, Auto,, CASE
	|		WHEN &Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Series = &Series
	|		WHEN &Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Products = &Products
	|		ELSE Products = &Products
	|		AND Series = &Series
	|	END
	|	AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &Characteristic IN (Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef), UNDEFINED)) AS
	|		ProductStock
	|{WHERE
	|	ProductStock.Recorder.* AS Recorder,
	|	ProductStock.SecondPeriod AS SecondPeriod,
	|	ProductStock.DayPeriod AS DayPeriod,
	|	ProductStock.WeekPeriod AS WeekPeriod,
	|	ProductStock.TenDaysPeriod AS TenDaysPeriod,
	|	ProductStock.MonthPeriod AS MonthPeriod,
	|	ProductStock.QuarterPeriod AS QuarterPeriod,
	|	ProductStock.HalfYearPeriod AS HalfYearPeriod,
	|	ProductStock.YearPeriod AS YearPeriod,
	|	ProductStock.Products.* AS Products,
	|	ProductStock.Characteristic.* AS Characteristic,
	|	ProductStock.Series.* AS Series,
	|	ProductStock.Warehouse.* AS Recipient,
	|	ProductStock.Premise.* AS Premise,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockOpeningBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockOpeningBalance / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockReceipt
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockReceipt / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockExpense
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockExpense / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN ProductStock.InStockClosingBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN ProductStock.Products.UnitFactorForReports <> 0
	|					THEN ProductStock.InStockClosingBalance / ProductStock.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Balance,
	|	&RecipientTypeWarehouse AS TypeRecipient,
	|	TRUE AS RemainingGoodsAvailable}
	|
	|UNION ALL
	|
	|SELECT
	|	MaterialsInProduction.Recorder AS Recorder,
	|	MaterialsInProduction.SecondPeriod AS SecondPeriod,
	|	MaterialsInProduction.DayPeriod AS DayPeriod,
	|	MaterialsInProduction.WeekPeriod AS WeekPeriod,
	|	MaterialsInProduction.TenDaysPeriod AS TenDaysPeriod,
	|	MaterialsInProduction.MonthPeriod AS MonthPeriod,
	|	MaterialsInProduction.QuarterPeriod AS QuarterPeriod,
	|	MaterialsInProduction.HalfYearPeriod AS HalfYearPeriod,
	|	MaterialsInProduction.YearPeriod AS YearPeriod,
	|	MaterialsInProduction.Products AS Products,
	|	MaterialsInProduction.Characteristic AS Characteristic,
	|	MaterialsInProduction.Series AS Series,
	|	MaterialsInProduction.Department AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountOpeningBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountOpeningBalance /
	|						MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountReceipt
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountReceipt / MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountExpense
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountExpense / MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountClosingBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountClosingBalance /
	|						MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Balance,
	|	&RecipientTypeDepartment AS TypeRecipient,
	|	TRUE AS RemainingGoodsAvailable
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.BalanceAndTurnovers(,, Auto,, CASE
	|		WHEN &Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Series = &Series
	|		WHEN &Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Products = &Products
	|		ELSE Products = &Products
	|		AND Series = &Series
	|	END
	|	AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &Characteristic IN (Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef), UNDEFINED)) AS
	|		MaterialsInProduction
	|{WHERE
	|	MaterialsInProduction.Recorder.* AS Recorder,
	|	MaterialsInProduction.SecondPeriod AS SecondPeriod,
	|	MaterialsInProduction.DayPeriod AS DayPeriod,
	|	MaterialsInProduction.WeekPeriod AS WeekPeriod,
	|	MaterialsInProduction.TenDaysPeriod AS TenDaysPeriod,
	|	MaterialsInProduction.MonthPeriod AS MonthPeriod,
	|	MaterialsInProduction.QuarterPeriod AS QuarterPeriod,
	|	MaterialsInProduction.HalfYearPeriod AS HalfYearPeriod,
	|	MaterialsInProduction.YearPeriod AS YearPeriod,
	|	MaterialsInProduction.Products.* AS Products,
	|	MaterialsInProduction.Characteristic.* AS Characteristic,
	|	MaterialsInProduction.Series.* AS Series,
	|	MaterialsInProduction.Department.* AS Recipient,
	|	(VALUE(Catalog.Warerooms.EmptyRef)).* AS Premise,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountOpeningBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountOpeningBalance /
	|						MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountReceipt
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountReceipt / MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountExpense
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountExpense / MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN MaterialsInProduction.CountClosingBalance
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN MaterialsInProduction.Products.UnitFactorForReports <> 0
	|					THEN MaterialsInProduction.CountClosingBalance /
	|						MaterialsInProduction.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Balance,
	|	&RecipientTypeDepartment AS TypeRecipient,
	|	TRUE AS RemainingGoodsAvailable}
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsBatchMovement.Recorder AS Recorder,
	|	GoodsBatchMovement.SecondPeriod AS SecondPeriod,
	|	GoodsBatchMovement.DayPeriod AS DayPeriod,
	|	GoodsBatchMovement.WeekPeriod AS WeekPeriod,
	|	GoodsBatchMovement.TenDaysPeriod AS TenDaysPeriod,
	|	GoodsBatchMovement.MonthPeriod AS MonthPeriod,
	|	GoodsBatchMovement.QuarterPeriod AS QuarterPeriod,
	|	GoodsBatchMovement.HalfYearPeriod AS HalfYearPeriod,
	|	GoodsBatchMovement.YearPeriod AS YearPeriod,
	|	GoodsBatchMovement.Products AS Products,
	|	GoodsBatchMovement.Characteristic AS Characteristic,
	|	GoodsBatchMovement.Series AS Series,
	|	GoodsBatchMovement.Recipient AS Recipient,
	|	GoodsBatchMovement.WareroomOfRecipient AS Premise,
	|	0 AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN GoodsBatchMovement.CountTurnover
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN GoodsBatchMovement.Products.UnitFactorForReports <> 0
	|					THEN GoodsBatchMovement.CountTurnover / GoodsBatchMovement.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	0 AS Expense,
	|	0 AS Balance,
	|	CASE
	|		WHEN GoodsBatchMovement.Recipient REFS Catalog.BusinessStructure
	|			THEN &RecipientTypeDepartment
	|		WHEN GoodsBatchMovement.Recipient REFS Catalog.Partners
	|			THEN &RecipientTypeCustomer
	|		ELSE &RecipientTypeWarehouse
	|	END AS TypeRecipient,
	|	FALSE AS RemainingGoodsAvailable
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(,, Auto, ThisIsWarehouseRecord
	|	AND CASE
	|		WHEN &Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Series = &Series
	|		WHEN &Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Products = &Products
	|		ELSE Products = &Products
	|		AND Series = &Series
	|	END
	|	AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &Characteristic IN (Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef), UNDEFINED)
	|	AND ((Products, Recipient) IN
	|		(SELECT
	|			ProductsForWhichBalancesAreNotMaintained.Ref,
	|			ProductsForWhichBalancesAreNotMaintained.Warehouse
	|		FROM
	|			ProductsForWhichBalancesAreNotMaintained)
	|	OR Recipient REFS Catalog.Partners
	|	AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ShipmentToCustomer),
	|		VALUE(Enum.WarehouseTransactions.RetailShipment)))) AS GoodsBatchMovement
	|{WHERE
	|	GoodsBatchMovement.Recorder.* AS Recorder,
	|	GoodsBatchMovement.SecondPeriod AS SecondPeriod,
	|	GoodsBatchMovement.DayPeriod AS DayPeriod,
	|	GoodsBatchMovement.WeekPeriod AS WeekPeriod,
	|	GoodsBatchMovement.TenDaysPeriod AS TenDaysPeriod,
	|	GoodsBatchMovement.MonthPeriod AS MonthPeriod,
	|	GoodsBatchMovement.QuarterPeriod AS QuarterPeriod,
	|	GoodsBatchMovement.HalfYearPeriod AS HalfYearPeriod,
	|	GoodsBatchMovement.YearPeriod AS YearPeriod,
	|	GoodsBatchMovement.Products.* AS Products,
	|	GoodsBatchMovement.Characteristic.* AS Characteristic,
	|	GoodsBatchMovement.Series.* AS Series,
	|	GoodsBatchMovement.Recipient.* AS Recipient,
	|	GoodsBatchMovement.WareroomOfRecipient.* AS Premise,
	|	0 AS InitialBalance,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN GoodsBatchMovement.CountTurnover
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN GoodsBatchMovement.Products.UnitFactorForReports <> 0
	|					THEN GoodsBatchMovement.CountTurnover / GoodsBatchMovement.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Receipt,
	|	0 AS Expense,
	|	0 AS Balance,
	|	CASE
	|		WHEN GoodsBatchMovement.Recipient REFS Catalog.BusinessStructure
	|			THEN &RecipientTypeDepartment
	|		WHEN GoodsBatchMovement.Recipient REFS Catalog.Partners
	|			THEN &RecipientTypeCustomer
	|		ELSE &RecipientTypeWarehouse
	|	END AS TypeRecipient,
	|	FALSE AS RemainingGoodsAvailable}
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsBatchMovement.Recorder AS Recorder,
	|	GoodsBatchMovement.SecondPeriod AS SecondPeriod,
	|	GoodsBatchMovement.DayPeriod AS DayPeriod,
	|	GoodsBatchMovement.WeekPeriod AS WeekPeriod,
	|	GoodsBatchMovement.TenDaysPeriod AS TenDaysPeriod,
	|	GoodsBatchMovement.MonthPeriod AS MonthPeriod,
	|	GoodsBatchMovement.QuarterPeriod AS QuarterPeriod,
	|	GoodsBatchMovement.HalfYearPeriod AS HalfYearPeriod,
	|	GoodsBatchMovement.YearPeriod AS YearPeriod,
	|	GoodsBatchMovement.Products AS Products,
	|	GoodsBatchMovement.Characteristic AS Characteristic,
	|	GoodsBatchMovement.Series AS Series,
	|	GoodsBatchMovement.Sender AS Sender,
	|	GoodsBatchMovement.WareroomOfSender AS Premise,
	|	0 AS InitialBalance,
	|	0 AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN GoodsBatchMovement.CountTurnover
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN GoodsBatchMovement.Products.UnitFactorForReports <> 0
	|					THEN GoodsBatchMovement.CountTurnover / GoodsBatchMovement.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	0 AS Balance,
	|	CASE
	|		WHEN GoodsBatchMovement.Sender REFS Catalog.BusinessStructure
	|			THEN &RecipientTypeDepartment
	|		WHEN GoodsBatchMovement.Sender REFS Catalog.Partners
	|			THEN &RecipientTypeCustomer
	|		ELSE &RecipientTypeWarehouse
	|	END AS TypeRecipient,
	|	FALSE AS RemainingGoodsAvailable
	|FROM
	|	AccumulationRegister.GoodsBatchMovement.Turnovers(,, Auto, ThisIsWarehouseRecord
	|	AND CASE
	|		WHEN &Products = VALUE(Catalog.Products.EmptyRef)
	|			THEN Series = &Series
	|		WHEN &Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Products = &Products
	|		ELSE Products = &Products
	|		AND Series = &Series
	|	END
	|	AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND &Characteristic IN (Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef), UNDEFINED)
	|	AND ((Products, Sender) IN
	|		(SELECT
	|			ProductsForWhichBalancesAreNotMaintained.Ref,
	|			ProductsForWhichBalancesAreNotMaintained.Warehouse
	|		FROM
	|			ProductsForWhichBalancesAreNotMaintained)
	|	OR Sender REFS Catalog.Partners
	|	AND WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer)))) AS
	|		GoodsBatchMovement
	|{WHERE
	|	GoodsBatchMovement.Recorder.* AS Recorder,
	|	GoodsBatchMovement.SecondPeriod AS SecondPeriod,
	|	GoodsBatchMovement.DayPeriod AS DayPeriod,
	|	GoodsBatchMovement.WeekPeriod AS WeekPeriod,
	|	GoodsBatchMovement.TenDaysPeriod AS TenDaysPeriod,
	|	GoodsBatchMovement.MonthPeriod AS MonthPeriod,
	|	GoodsBatchMovement.QuarterPeriod AS QuarterPeriod,
	|	GoodsBatchMovement.HalfYearPeriod AS HalfYearPeriod,
	|	GoodsBatchMovement.YearPeriod AS YearPeriod,
	|	GoodsBatchMovement.Products.* AS Products,
	|	GoodsBatchMovement.Characteristic.* AS Characteristic,
	|	GoodsBatchMovement.Series.* AS Series,
	|	GoodsBatchMovement.Sender.* AS Sender,
	|	GoodsBatchMovement.WareroomOfSender.* AS Premise,
	|	0 AS InitialBalance,
	|	0 AS Receipt,
	|	CASE
	|		WHEN &QuantityUnits = 0
	|			THEN GoodsBatchMovement.CountTurnover
	|		WHEN &QuantityUnits = 1
	|			THEN CASE
	|				WHEN GoodsBatchMovement.Products.UnitFactorForReports <> 0
	|					THEN GoodsBatchMovement.CountTurnover / GoodsBatchMovement.Products.UnitFactorForReports
	|				ELSE 0
	|			END
	|	END AS Expense,
	|	0 AS Balance,
	|	CASE
	|		WHEN GoodsBatchMovement.Sender REFS Catalog.BusinessStructure
	|			THEN &RecipientTypeDepartment
	|		WHEN GoodsBatchMovement.Sender REFS Catalog.Partners
	|			THEN &RecipientTypeCustomer
	|		ELSE &RecipientTypeWarehouse
	|	END AS TypeRecipient,
	|	FALSE AS RemainingGoodsAvailable}";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
