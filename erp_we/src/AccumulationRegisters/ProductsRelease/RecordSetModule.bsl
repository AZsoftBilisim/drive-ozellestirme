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
	
	Query = New Query("
	|SELECT
	|	ProductionIssue.Period,
	|	ProductionIssue.Recorder,
	|	ProductionIssue.Organization,
	|	ProductionIssue.ItemsLocationAttributes,
	|	ProductionIssue.ReferenceOrder,
	|	ProductionIssue.RowCode,
	|	ProductionIssue.OrderDocument,
	|	ProductionIssue.InventoryOwnerAttribute,
	|	ProductionIssue.BillOfMaterials,
	|	ProductionIssue.Department,
	|	ProductionIssue.ExpenseItem,
	|	ProductionIssue.DimensionOfExpenses,
	|	ProductionIssue.AssetsLiabilitiesDimension,
	|
	|	ProductionIssue.Count,
	|
	|	ProductionIssue.ProductsAccountingDimension
	|INTO ProductsReleaseBeforeWrite
	|FROM
	|	AccumulationRegister.ProductsRelease AS ProductionIssue
	|WHERE
	|	ProductionIssue.Recorder = &Recorder
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Table.Period                       AS Period,
	|	Table.Organization                  AS Organization,
	|	Table.Recorder                  AS Recorder,
	|	Table.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	Table.ReferenceOrder                 AS ReferenceOrder,
	|	Table.RowCode                    AS RowCode,
	|	Table.OrderDocument                        AS OrderDocument,
	|	Table.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	Table.BillOfMaterials                 AS BillOfMaterials,
	|	Table.Department                AS Department,
	|	Table.ExpenseItem               AS ExpenseItem,
	|	Table.DimensionOfExpenses            AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	Table.ProductsAccountingDimension      AS ProductsAccountingDimension,
	|	SUM(Table.Count)            AS CountUpdate
	|INTO ChangesTableProductsRelease
	|FROM
	|	(SELECT
	|		ProductionIssue.Period,
	|		ProductionIssue.Recorder,
	|		ProductionIssue.Organization,
	|		ProductionIssue.ItemsLocationAttributes,
	|		ProductionIssue.ReferenceOrder,
	|		ProductionIssue.RowCode,
	|		ProductionIssue.OrderDocument,
	|		ProductionIssue.InventoryOwnerAttribute,
	|		ProductionIssue.BillOfMaterials,
	|		ProductionIssue.Department,
	|		ProductionIssue.ExpenseItem,
	|		ProductionIssue.DimensionOfExpenses,
	|		ProductionIssue.AssetsLiabilitiesDimension,
	|
	|		ProductionIssue.Count,
	|
	|		ProductionIssue.ProductsAccountingDimension
	|	FROM
	|		ProductsReleaseBeforeWrite AS ProductionIssue
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		ProductionIssue.Period,
	|		ProductionIssue.Recorder,
	|		ProductionIssue.Organization,
	|		ProductionIssue.ItemsLocationAttributes,
	|		ProductionIssue.ReferenceOrder,
	|		ProductionIssue.RowCode,
	|		ProductionIssue.OrderDocument,
	|		ProductionIssue.InventoryOwnerAttribute,
	|		ProductionIssue.BillOfMaterials,
	|		ProductionIssue.Department,
	|		ProductionIssue.ExpenseItem,
	|		ProductionIssue.DimensionOfExpenses,
	|		ProductionIssue.AssetsLiabilitiesDimension,
	|
	|		-ProductionIssue.Count,
	|
	|		ProductionIssue.ProductsAccountingDimension
	|	FROM
	|		AccumulationRegister.ProductsRelease AS ProductionIssue
	|	WHERE
	|		ProductionIssue.Recorder = &Recorder
	|	) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Organization,
	|	Table.ItemsLocationAttributes,
	|	Table.ReferenceOrder,
	|	Table.RowCode,
	|	Table.OrderDocument,
	|	Table.InventoryOwnerAttribute,
	|	Table.BillOfMaterials,
	|	Table.Department,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension,
	|	Table.ProductsAccountingDimension
	|HAVING
	|	SUM(Table.Count) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductsReleaseBeforeWrite
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
