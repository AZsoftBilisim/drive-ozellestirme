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
	|	Goods.CompanyOwner        AS CompanyOwner,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.SellerInventoryOwnerAttribute         AS SellerInventoryOwnerAttribute,
	|	Goods.CCDNumber                   AS CCDNumber,
	|
	|	Goods.Count AS Count,
	|
	|	Goods.VATTaxation    AS VATTaxation,
	|	Goods.BusinessOperation AS BusinessOperation,
	|	Goods.Products          AS Products,
	|	Goods.Characteristic        AS Characteristic,
	|	Goods.CorInventoryOwnerAttribute         AS CorInventoryOwnerAttribute,
	|	Goods.Primary             AS Primary
	|INTO GoodsToTransferBeforeWrite
	|FROM
	|	AccumulationRegister.CompanyGoodsForTransfer AS Goods
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
	|	Table.CompanyOwner AS Organization,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	Table.CCDNumber AS CCDNumber,
	|	Table.VATTaxation AS VATTaxation,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	Table.Primary AS Primary,
	|	SUM(Table.Count) AS CountUpdate
	|INTO ChangesTableCompanyGoodsForTransfer
	|FROM
	|	(SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		Goods.CompanyOwner AS CompanyOwner,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		Goods.Count AS Count,
	|		Goods.VATTaxation AS VATTaxation,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Goods.Primary AS Primary
	|	FROM
	|		GoodsToTransferBeforeWrite AS Goods
	|	WHERE
	|		&BatchAccountingIsEnabled
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Period AS Period,
	|		Goods.Recorder AS Recorder,
	|		Goods.CompanyOwner AS CompanyOwner,
	|		Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Goods.SellerInventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|		Goods.CCDNumber AS CCDNumber,
	|		-Goods.Count AS Count,
	|		Goods.VATTaxation AS VATTaxation,
	|		Goods.BusinessOperation AS BusinessOperation,
	|		Goods.Products AS Products,
	|		Goods.Characteristic AS Characteristic,
	|		Goods.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|		Goods.Primary AS Primary
	|	FROM
	|		AccumulationRegister.CompanyGoodsForTransfer AS Goods
	|	WHERE
	|		Goods.Recorder = &Recorder
	|		AND &BatchAccountingIsEnabled) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.CompanyOwner,
	|	Table.ItemsLocationAttributes,
	|	Table.SellerInventoryOwnerAttribute,
	|	Table.CCDNumber,
	|	Table.VATTaxation,
	|	Table.BusinessOperation,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.CorInventoryOwnerAttribute,
	|	Table.Primary
	|HAVING
	|	SUM(Table.Count) <> 0");
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("BatchAccountingIsEnabled", AdditionalProperties.BatchAccountingIsEnabled);
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
