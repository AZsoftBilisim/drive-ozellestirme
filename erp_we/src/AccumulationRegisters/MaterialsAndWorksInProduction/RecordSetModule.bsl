#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	If CostCalculationAppliedAlgorithms.GenerateRegisteredRecordsOfCostAccountingRegisters(ThisObject) Then
		CostCalculationAppliedAlgorithms.SaveRegisteredRecordsGeneratedByCalculationOfBatchesAndCosts(ThisObject, Replacing);
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined
		Or Not DocumentsPosting.MonitorChanges(AdditionalProperties) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Costs.Period,
	|	Costs.Recorder,
	|	Costs.Organization,
	|	Costs.ItemsLocationAttributes,
	|
	|	Costs.Count,
	|
	|	Costs.ProductCostElement,
	|	Costs.ProductionOrder,
	|	Costs.RowCodeProducts,
	|	Costs.Stage,
	|	Costs.Purpose,
	|	Costs.VATTaxation,
	|	Costs.ProductsAccountingDimension,
	|	Costs.BillOfMaterials,
	|	Costs.ExpenseItem,
	|	Costs.DimensionOfExpenses,
	|	Costs.ReceivingBusinessUnit
	|INTO MaterialsAndWorksInProductionBeforeWrite
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction AS Costs
	|WHERE
	|	Costs.Recorder = &Recorder
	|");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Or Not DocumentsPosting.MonitorChanges(AdditionalProperties)
		Or ExchangePlans.MasterNode() <> Undefined
		Or CostCalculationAppliedAlgorithms.RegisteredRecordsAreRecordedByCalculatingBatchesAndCosts(ThisObject) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	Table.Period AS Period,
	|	Table.Recorder AS Recorder,
	|	Table.Organization AS Organization,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.ProductCostElement AS ProductCostElement,
	|	Table.ProductionOrder AS ProductionOrder,
	|	Table.RowCodeProducts AS RowCodeProducts,
	|	Table.Stage AS Stage,
	|	Table.Purpose AS Purpose,
	|	Table.VATTaxation AS VATTaxation,
	|	Table.ProductsAccountingDimension AS ProductsAccountingDimension,
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	Table.ExpenseItem AS ExpenseItem,
	|	Table.DimensionOfExpenses AS DimensionOfExpenses,
	|	Table.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|	SUM(Table.Count) AS CountUpdate
	|INTO ChangesTableMaterialsAndWorksInProduction
	|FROM
	|	(SELECT
	|		Costs.Period,
	|		Costs.Recorder,
	|		Costs.Organization,
	|		Costs.ItemsLocationAttributes,
	|		Costs.Count,
	|		Costs.ProductCostElement,
	|		Costs.ProductionOrder,
	|		Costs.RowCodeProducts,
	|		Costs.Stage,
	|		Costs.Purpose,
	|		Costs.VATTaxation,
	|		Costs.ProductsAccountingDimension,
	|		Costs.BillOfMaterials,
	|		Costs.ExpenseItem,
	|		Costs.DimensionOfExpenses,
	|		Costs.ReceivingBusinessUnit
	|	FROM
	|		MaterialsAndWorksInProductionBeforeWrite AS Costs
	|
	|	UNION ALL
	|
	|	SELECT
	|		Costs.Period,
	|		Costs.Recorder,
	|		Costs.Organization,
	|		Costs.ItemsLocationAttributes,
	|		-Costs.Count,
	|		Costs.ProductCostElement,
	|		Costs.ProductionOrder,
	|		Costs.RowCodeProducts,
	|		Costs.Stage,
	|		Costs.Purpose,
	|		Costs.VATTaxation,
	|		Costs.ProductsAccountingDimension,
	|		Costs.BillOfMaterials,
	|		Costs.ExpenseItem,
	|		Costs.DimensionOfExpenses,
	|		Costs.ReceivingBusinessUnit
	|	FROM
	|		AccumulationRegister.MaterialsAndWorksInProduction AS Costs
	|	WHERE
	|		Costs.Recorder = &Recorder) AS Table
	|GROUP BY
	|	Table.Period,
	|	Table.Recorder,
	|	Table.Organization,
	|	Table.ItemsLocationAttributes,
	|	Table.ProductCostElement,
	|	Table.ProductionOrder,
	|	Table.RowCodeProducts,
	|	Table.Stage,
	|	Table.Purpose,
	|	Table.VATTaxation,
	|	Table.ProductsAccountingDimension,
	|	Table.BillOfMaterials,
	|	Table.ExpenseItem,
	|	Table.DimensionOfExpenses,
	|	Table.ReceivingBusinessUnit
	|HAVING
	|	SUM(Table.Count) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP MaterialsAndWorksInProductionBeforeWrite");
	
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	
	Query.Execute();
	
EndProcedure

#EndRegion

#EndIf
