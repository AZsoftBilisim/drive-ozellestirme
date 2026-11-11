#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	LockForUpdate = True;
	
	AdditionalProperties.Insert("BatchAccountingIsEnabled",
		CalculationOfCostCached.BatchAccountingIsEnabled(
			BegOfMonth(AdditionalProperties.RecorderDate)));
	
	// The current state of the set is placed in a temporary table
	// in order to get a change in the new set relative to the current one when writing.
	Query = New Query("
	|SELECT
	|	Goods.Period                     AS Period,
	|	Goods.Recorder                AS Recorder,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.Terms                 AS Terms,
	|	Goods.Organization                AS Organization,
	|	Goods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	Goods.CCDNumber                   AS CCDNumber,
	|
	|	Goods.Count          AS Count,
	|	Goods.QuantityByGBRN    AS QuantityByGBRN,
	|	Goods.RevenueAmount        AS RevenueAmount,
	|	Goods.CommissionAmount AS CommissionAmount,
	|
	|	Goods.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Goods.DocumentSalesOfGoodsAndServices            AS DocumentSalesOfGoodsAndServices,
	|	Goods.BusinessOperation         AS BusinessOperation,
	|	Goods.VATTaxation            AS VATTaxation,
	|	Goods.Products                  AS Products,
	|	Goods.Characteristic                AS Characteristic
	|INTO GoodsTransferredBeforeWrite
	|FROM
	|	AccumulationRegister.GoodsTransferredToCommissionAgent AS Goods
	|WHERE
	|	Goods.Recorder = &Recorder
	|	AND &BatchAccountingIsEnabled
	|");
	
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	Query = New Query("SELECT
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.Terms AS Terms,
	|	Table.Organization AS Organization,
	|	Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	Table.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.VATTaxation AS VATTaxation,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	SUM(Table.Count) AS CountUpdate,
	|	SUM(Table.QuantityByGBRN) AS QuantityByGBRNUpdate,
	|	SUM(Table.RevenueAmount) AS RevenueAmountUpdate,
	|	SUM(Table.CommissionAmount) AS CommissionAmountUpdate
	|INTO ChangesTableGoodsTransferredToCommissionAgent
	|FROM
	|	(SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.Terms AS Terms,
	|		Goods.Organization AS Organization,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.Count AS Count,
	|		Goods.QuantityByGBRN AS QuantityByGBRN,
	|		Goods.RevenueAmount AS RevenueAmount,
	|		Goods.CommissionAmount AS CommissionAmount,
	|		Goods.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|		Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.VATTaxation AS VATTaxation,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic
	|	FROM
	|		GoodsTransferredBeforeWrite AS Goods
	|	WHERE
	|		&BatchAccountingIsEnabled
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.Terms AS Terms,
	|		Goods.Organization AS Organization,
	|		Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		-Goods.Count AS Count,
	|		-Goods.QuantityByGBRN AS QuantityByGBRN,
	|		-Goods.RevenueAmount AS RevenueAmount,
	|		-Goods.CommissionAmount AS CommissionAmount,
	|		Goods.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|		Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.VATTaxation AS VATTaxation,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic
	|	FROM
	|		AccumulationRegister.GoodsTransferredToCommissionAgent AS Goods
	|	WHERE
	|		Goods.Recorder = &Recorder
	|		AND &BatchAccountingIsEnabled) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.ItemsLocationAttributes,
	|	Table.Terms,
	|	Table.Organization,
	|	Table.InventoryOwnerAttribute,
	|	Table.CCDNumber,
	|	Table.CorItemsLocationAttributes,
	|	Table.DocumentSalesOfGoodsAndServices,
	|	Table.BusinessOperation,
	|	Table.VATTaxation,
	|	Table.Products,
	|	Table.Characteristic
	|HAVING
	|	SUM(Table.Count) <> 0
	|	OR SUM(Table.QuantityByGBRN) <> 0
	|	OR SUM(Table.RevenueAmount) <> 0
	|	OR SUM(Table.CommissionAmount) <> 0
	|");
	
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf