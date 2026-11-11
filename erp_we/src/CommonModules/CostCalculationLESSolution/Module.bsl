///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cost calculation mechanism: preparation and solution of a system of linear equations
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Calculation of the cost in terms of provisions for impairment.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CostCalculation_ProvisionsForImpairmentOfInventories(CalculationParameters) Export
	
	// Generates temporary tables:
	// - In the correction node

	// - Svyazi nodesreservation of supplies
	PreparationOfDataForSolvingCaseOfReservesForImpairmentOfInventories(CalculationParameters);
	
	// Generates a temporary table:
	// - In the table_resolution_reservation_reservation_reservation_reservation_reservation_reservation_reservation_reservation_reservation
	SolveCaseOf_ReservesForImpairmentOfStocksOfOrganizations(CalculationParameters);
	// Generates a temporary table:
	// - The cost of Party goods
	GenerateCostOfBatchesOfGoods_ProvisionsForImpairmentOfInventories(CalculationParameters);
	
	If CalculationParameters.BatchCalculationStarted Then
			
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
			
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

// Calculation of the cost in terms of the cost of goods and labor costs.
// The resources of the "Cost of goods" register are calculated":
//	-  Cost Of Stomatitis, Timotesubani, Work
//	- Stoimosti, Timotesubani, Truestring
//	-  Stoimostyu, TradeStation
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CostCalculation_MaterialAndLaborCosts(CalculationParameters) Export
	
	// Generates temporary tables:
	// - intranslationsreferences
	PreparationOfDataForSolvingSLS(CalculationParameters);
	
	If CalculationParameters.AccountingPolicies.FifoWeighted.Count() > 0 Then
		PrepareDataForCalculatingCostOfFIFO(CalculationParameters); // correction of the node correction
	EndIf;
	
	// Generates a temporary table:
	// - vttablitsareferences_Cost of the enterprise
	SolveCase_CostOfEnterprise(CalculationParameters);
	
	// Generates a temporary table:
	// - vttablitsareferences_Cost of organizations
	SolveCase__CostOfOrganizations(CalculationParameters);
	
	// Updates the temporary table:
	// - The cost of Party goods
	UpdateCostOfBatchesOfGoods_MaterialAndLaborCosts(CalculationParameters);
	
	SaveSLU(CalculationParameters);
	
	If CalculationParameters.BatchCalculationStarted Then
			
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
			
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

// Calculation of the cost in terms of additional costs for goods and in terms of including/excluding VAT.
// The resources of the "Cost of goods" register are calculated:
//	- Additional expenses, additional expenses, additional expenses
//	- Stoimosti, Depreciating
//	-  Stoimostyu, Depreciation
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CostCalculation_AdditionalExpenses(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing
	 And Not CalculationParameters.DistributionOfAdditionalCostsBetweenPartiesAndGoods Then
		Return;
	EndIf;
	
	PreparingDataToSolveCaseAdditionalCosts(CalculationParameters);
	
	CalculationOfCostOfPastPeriods(CalculationParameters);
	
	PreparingDataForSolutionOfSLECase_AdditionalCosts_NodesAndConnections(CalculationParameters);
	
	// Generates a temporary table:
	// - Decision tables
	SolveCase_AdditionalCosts(CalculationParameters);
		
	// Generates a temporary table:
	// - The cost of Party goods
	UpdateCostOfBatchesOfGoods_AdditionalCosts(CalculationParameters);
	RegisterCost_AdditionalCosts(CalculationParameters);
	
	If CalculationParameters.BatchCalculationStarted Then
		
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
		
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

// Calculation of the cost in terms of additional costs for goods and in terms of including/excluding VAT.
// The resources of the "Cost of goods" register are calculated:
//	- Additional expenses, additional expenses, additional expenses
//	- Stoimosti, Depreciating
//	-  Stoimostyu, Depreciation
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CostCalculation_InclusionExclusionOfVAT(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	AdjustmentNodesInclusionExclusionOfVAT(CalculationParameters);
	
	// Generates a temporary table:
	// - vttablitsareferences_Cost of organizations
	SolveCase__InclusionExclusionOfVATOrganizations(CalculationParameters);
	
	// Generates a temporary table:
	// - The cost of Party goods
	UpdateCostOfBatchesOfGoods_InclusionExclusionOfVAT(CalculationParameters);
	
	If CalculationParameters.BatchCalculationStarted Then
			
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
			
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

// Calculation of the cost in terms of item-by-item production costs.
// The resources of the "Cost of goods" register are calculated":
//	- Postmanipulation, Postmanipulation, Postmanipulation, Postmanipulation
//	- Postmanufacturing, Postmanipulation
//	- Permanent Difference, Temporary Difference
//	- Item-by-item, item-by-item, item-by-item, item-by-item, item-by-item, item-by-item, item-by-item, item-by-item
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CostCalculation_ItemByItemExpensesAndTaxAccounting(CalculationParameters) Export
	
	// Stage 1: preparation and calculation of the cost price in terms of item-by-item expenses.
	
	// Generates temporary tables:
	//	- vtuzlykorrection of the status of the output
	//	- vttablicsreferencesexternal links
	PreparingDataToAddressCaseByCaseCosts(CalculationParameters);
	
	// Generates a temporary table:
	// - vttablitsareferences_Cost of the enterprise
	SolveCases_ItemByItemExpensesOfEnterprise(CalculationParameters);
	
	// Generates a temporary table:
	// - vttablitsareferences_Cost of organizations
	SolveCases_ItemByItemExpensesOfOrganizations(CalculationParameters);
	
	
	// Stage 3: preparation and calculation of the cost price, taking into account the reserves of upcoming expenses.
	// Generates temporary tables:
	// - Reserve nodes
	// - Detailereferences
	PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses(CalculationParameters);
	
	// Item-by-item expenses are adjusted for the amount of reserves for upcoming expenses
	SolveCase__ReservesOfUpcomingExpenses(CalculationParameters);
	
	// stage 4: formation of tables of the cost of batches and the cost of other Unfinished production expenses
	
	CostCalculationAppliedAlgorithms.CopyTemporaryTable(CalculationParameters, 
		"TTValueOfBatchesOfGoods", "TTValueOfBatchesOfGoodsPrevious");
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTValueOfBatchesOfGoods");
	
	// Generates a temporary table:
	// - The cost of Party goods
	PreparationOfDataForCostOfBatchesOfGoods(CalculationParameters);
		
	// Generates temporary tables:
	// - Vtoimostinesperformance
	// - vtoimostinesperforming productionregl
	// - Reserve of current expenses
	PreparationOfDataForCostOfOtherExpensesUnfinishedProduction(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"TTTableOfSolutions_CostOfEnterprise");
	
	If CalculationParameters.BatchCalculationStarted Then
			
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
			
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region StageProcedures_PreparationOfDataForSolvingSLS

#Region Description_PreparationOfDataForSolvingSLS

// The data preparation stage for the solution of the service prepares temporary tables of nodes and links to solve a system of linear
// equations.
// Output stage tables:
// - vtuzlykorrections - a table of nodes. Each node corresponds to one set of measurement values of the register "Cost of goods".
// 		The table is formed at the stage of preparing the data for the resolution of the reserve impairment of supplies
// - In the displacement of the list - a table of links between nodes  
//
// Rules for the formation of the VTUZLYKORRECTION table:
// Initial Cost formation:
//	1. Register Records with the record type "Debit note adjustment" - adjustment of quantity and Cost to increase or decrease
//	2. Register Records with the entry type "Write-offs for the issue (reverse of the previous period)"
//	3. Receipts with household operations "Output", "Receipt from the processor" and "Output to the unit"
//		with zero quantity - the calculated Cost of labor
//		costs at the preliminary closing Of the month, we add the planned Cost Of products to the initial Cost
//	4. Receipts according to the list of business operations of external receipt
//	5. Expenses with the record type "Lot reference" - The Cost Of An unfactured delivery
//	6. Parishes with the Reverse sign
//	7. Register Recorded movements With The Reverse sign and The "Correction of the previous period" entry type
//	8. The Register Recorded With The accounting operation "Disposal At a fixed Cost" with the sign "Calculation not completed" with a minus sign - refunds to the supplier
//		if the Lot reference Was not found for the refund. the Cost Is needed to calculate deviations in the re-sorting stage Of Lot references Of goods.
//		The Cost In the node is reduced by the fixed Cost Of the refund.
//	9. Register Records with the type of entries "Deviation in Cost", "Deviation in Cost For other income", "Deviation in Cost For other expenses",
//		"Distribution of retired goods", "Debit notes of the previous period" with a minus sign
//		The Cost In the node is reduced by the amount of the adjustment
//	10. Register Recorded With The utility operation "Commission agent's Report" and The record type "Return without source document" with a minus sign
//		if the date of The source document is in the previous period.
//		The calculated Cost Of returning goods To The commission agent From the client, if the Sale was in the previous period.
//		the Cost is calculated in the procedure to adjust the cost Of the returns Of the previous Periods(). 

#EndRegion

// Stage " Preparation of the data for the decision of the service"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForSolvingSLS(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForSolvingSLS");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTWriteOffs, ServiceNodesMaterialAndLaborCosts, ServiceConnectionsMaterialAndLaborCosts");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextOfRequestToSolveProblem(CalculationParameters));
		
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "ThereIsReturnableWaste");
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function TextOfRequestToSolveProblem(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TTTextForMovingWriteOffs());
	If CalculationParameters = Undefined
	 Or CalculationParameters.AccountingPolicies.FifoWeighted.Count() = 0 Then
		QueriesTexts.Add(TextServiceNodesMaterialAndLaborCosts());
		QueriesTexts.Add(CommunicationTextSLU_MaterialAndLaborCosts());
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextTTHasReturnableWaste() Export
	Return "
		|SELECT TOP 0
		|	DD.Organization AS Organization,
		|	DD.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	DD.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection
		|INTO ThereIsReturnableWaste
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization
		|";
EndFunction

Function TextTT_Adjustments_MaterialAndLaborCosts() Export // vt VtUzlyKorreferences
	Return "
		|SELECT
		|	RECORDAUTONUMBER()                        AS NodeNumber,
		|	Cost_.Organization                AS Organization,
		|	Cost_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Cost_.AccountingSection                AS AccountingSection,
		|	Cost_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	(CASE
		|		WHEN &ScheduledJob
		|		 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN UNDEFINED
		|		ELSE Cost_.Lot END)    AS Lot,
		|	(CASE
		|		WHEN &ScheduledJob THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE Cost_.LotVendorAttributes END) AS LotVendorAttributes,
		|	(CASE
		|		WHEN &ScheduledJob THEN UNDEFINED
		|		ELSE Cost_.FinancialAccountingDimension END) AS FinancialAccountingDimension,
		|	(CASE
		|		WHEN &ScheduledJob
		|		 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE Cost_.VATActivityType END) AS VATActivityType,
		|
		// Resources for calculating the cost of goods of the enterprise.
		|	SUM(Cost_.Count)                  AS Count,
		|	SUM(Cost_.QuantityIsWrittenOffAtFixedCost) AS QuantityIsWrittenOffAtFixedCost,
		|	SUM(Cost_.Cost)                   AS Cost,
		|	SUM(Cost_.CostExcludingVAT)             AS CostExcludingVAT,
		|	SUM(Cost_.AddExpensesForGoods)                  AS AddExpensesForGoods,
		|	SUM(Cost_.AdditionalExpensesExcludingVAT)            AS AdditionalExpensesExcludingVAT,
		|	SUM(Cost_.OffBalanceCost)       AS OffBalanceCost,
		|	SUM(Cost_.LaborCosts)                AS LaborCosts,
		|	SUM(Cost_.ItemizedFixedCostsIncludingVAT)   AS ItemizedFixedCostsIncludingVAT,
		|	SUM(Cost_.ItemizedVariableCostsIncludingVAT)   AS ItemizedVariableCostsIncludingVAT,
		|	SUM(Cost_.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(Cost_.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		// Resources for calculating the cost of goods of organizations.
		|	SUM(Cost_.LocalCost)               AS LocalCost,
		|	SUM(Cost_.AddExpensesLocal)              AS AddExpensesLocal,
		|	SUM(Cost_.OffBalanceCostLocal)   AS OffBalanceCostLocal,
		|	SUM(Cost_.LaborCostsLocal)            AS LaborCostsLocal,
		|	SUM(Cost_.ItemizedFixedCostsCompl)   AS ItemizedFixedCostsCompl,
		|	SUM(Cost_.ItemizedVariableCostsCompl)   AS ItemizedVariableCostsCompl,
		|	SUM(Cost_.ProvisionForImpairmentLocal)    AS ProvisionForImpairmentLocal,
		|	SUM(Cost_.CostMan)                AS CostMan,
		|	SUM(Cost_.AddExpensesMan)               AS AddExpensesMan,
		|	SUM(Cost_.LaborCostsMan)             AS LaborCostsMan,
		|	SUM(Cost_.ItemizedFixedCostsManag)    AS ItemizedFixedCostsManag,
		|	SUM(Cost_.ItemizedVariableCostsManag)    AS ItemizedVariableCostsManag,
		|	SUM(Cost_.ProvisionForImpairmentMan)     AS ProvisionForImpairmentMan
		|INTO TTAdjustmentNodes
		|FROM (
		|	SELECT
		|		Cost_.Organization,
		|		Cost_.ItemsLocationAttributes,
		|		(CASE
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			 AND Cost_.Count < 0
		|			 AND NOT ThereIsReturnableWaste.Organization IS NULL
		|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) // returnable waste is accounted for by an empty accounting section
		|			ELSE Cost_.AccountingSection END) AS AccountingSection,
		|		Cost_.InventoryOwnerAttribute,
		|		Cost_.Lot,
		|		Cost_.LotVendorAttributes,
		|		Cost_.FinancialAccountingDimension,
		|		Cost_.VATActivityType,
		// The number of goods is the same for all types of accounting. 
		|		(CASE
		// the Registered Records with the record type "debit note adjustment" are included in the initial Cost Of the calculation nodes, as well As the record type Lot reference.
		// We exclude summary fields only for records generated during the execution of documents.
		// the Registered Records with the sign of "Computability" should be taken into account in the initial Cost Of the node.
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.Count
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.Count
		|						ELSE Cost_.Count
		|					END
		// Expendable Registered Recorded movements with the record type "Addition (last period)" increase the quantity and cost in the node,
		// incoming Registered Recorded movements reduce the quantity and cost in the node. In Registered Records, the quantity and cost are negative.
		// In addition to the Accounting section "Output" for medium-slip, because with medium-slip, the initial Register 
		// Records are generated for the Recorders of the cost calculation and it does not reverse 
		// the sum Register Records for the "Output" section. Therefore, they need to calculate the cost.
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)) 
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.Count 
		|					ELSE Cost_.Count END
		// Movements to correct the movement of the previous period should form the initial cost of the node in the same way as the purchase adjustment,
		// because the expenditure movements of such a movement form the initial cost of the node (record type "Correction of the previous period"). 
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.Count
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.Count
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN -Cost_.Count
		|		 	WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReversingEntry)
		|			 AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|			 AND Cost_.VATActivityType <> Cost_.VATActivityTypeShipments
		|			 AND Cost_.VATActivityTypeShipments <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|				THEN -Cost_.Count
		// The expenditure Registered Records with the record types "Correction of the last period" and "Addition (last period)" are
		// returns to the warehouse, have a previously calculated cost in the last period, and therefore should form the initial cost of the node. 
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.Count
		// Disposal at a fixed cost is taken into account in the initial cost of the node, if no batch has been selected for such disposal.
		// The conditions for data sampling must correspond to the procedure for correcting the cost of writing inventory in the general module for calculating the cost of cost correction
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|			 AND Cost_.Cost <> 0
		|				THEN -Cost_.Count
		// The movements of the commission agent's return report are added if the sale was reflected in the previous period.
		// The sampling conditions must correspond to the request for the formation of the realization of the past periods in the general module for calculating the cost of cost correction
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.Count
		|			ELSE 0 
		|		END) AS Count,
		// In the future, we will exclude the amount of write-off for expenses at a fixed cost from:
		//	solving the case for the cost of the enterprise (solve it using the platform_The cost of an enterprise),
		//	solutions for the cost of organizations (solved by a platform_Cost
		//	of organizations), service solutions for inclusion/exclusion of VAT (
		//	to solve the platform_inclution_exclution_organizations), service solutions for impairment reserves (to solve the platform_reservation_reservation_organizations).
		|		CASE
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN Cost_.Count
		|		 	ELSE 0 
		|		END AS QuantityIsWrittenOffAtFixedCost,
		// Data on the amounts of external receipts.
		// The formation rules are described in the Description area_Preparing the data for the resolution of the service
		// The conditions for the formation of summary indicators must correspond to the function of the Tax Accounting text().
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.Cost
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.Cost
		|						ELSE Cost_.Cost
		|					END
		// Expendable Registered Records with the record type "Addition (last period)" increase the quantity and cost in the node,
		// incoming Registered Records reduce the quantity and cost in the node. In Registered Records, the quantity and cost are negative.
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.Cost 
		|					ELSE Cost_.Cost END
		// Movements to correct the movement of the previous period should form the initial cost of the node in the same way as the purchase adjustment,
		// because the expenditure movements of such a movement form the initial cost of the node (record type "Correction of the previous period").
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.Cost
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				AND Cost_.OfficialTypeOfMovementParish AND &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|				THEN Cost_.Cost
		|			WHEN Cost_.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ProductsRelease),
		|				VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|		 	 AND Cost_.OfficialTypeOfMovementParish
		|				THEN (CASE
		|					WHEN (Cost_.Count = 0
		|					 OR &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing))
		|		 	 		AND (NOT &PreliminaryCalculation OR Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot))
		|						THEN Cost_.Cost
		|				ELSE 0 END)
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.Cost
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN -Cost_.Cost

		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.Cost
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.Cost
		// The expenditure Registered Records with the record types "Correction of the last period" and "Addition (last period)" are
		// returns to the warehouse, have a previously calculated cost in the last period, and therefore should form the initial cost of the node. 
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.Cost
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.Cost
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.CostVariance),
		|					VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|					VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|					VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|				THEN -Cost_.Cost
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.Cost
		|			ELSE 0
		|		END) AS Cost,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.CostExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.CostExcludingVAT
		|						ELSE Cost_.CostExcludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.CostExcludingVAT 
		|					ELSE Cost_.CostExcludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.CostExcludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				AND Cost_.OfficialTypeOfMovementParish AND &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|				THEN Cost_.CostExcludingVAT
		|			WHEN Cost_.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ProductsRelease),
		|				VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|		 	 AND Cost_.OfficialTypeOfMovementParish
		|				THEN (CASE
		|					WHEN (Cost_.Count = 0
		|					 OR &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing))
		|		 	 		AND (NOT &PreliminaryCalculation OR Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot))
		|						THEN Cost_.CostExcludingVAT
		|				ELSE 0 END)
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.CostExcludingVAT
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN -Cost_.CostExcludingVAT
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.CostExcludingVAT
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.CostExcludingVAT
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.CostExcludingVAT
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.CostExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.CostVariance),
		|					VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|					VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|					VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|				THEN -Cost_.CostExcludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.CostExcludingVAT
		|			ELSE 0
		|		END) AS CostExcludingVAT,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.AddExpensesForGoods
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.AddExpensesForGoods
		|						ELSE Cost_.AddExpensesForGoods
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.AddExpensesForGoods 
		|					ELSE Cost_.AddExpensesForGoods END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.AddExpensesForGoods
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.AddExpensesForGoods
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.AddExpensesForGoods
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.AddExpensesForGoods
		|			WHEN Cost_.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.CostVariance),
		|				VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|				VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|			THEN
		|				-Cost_.AddExpensesForGoods
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.AddExpensesForGoods
		|			ELSE 0
		|		END) AS AddExpensesForGoods,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.AdditionalExpensesExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.AdditionalExpensesExcludingVAT
		|						ELSE Cost_.AdditionalExpensesExcludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.AdditionalExpensesExcludingVAT 
		|					ELSE Cost_.AdditionalExpensesExcludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.AdditionalExpensesExcludingVAT
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.AdditionalExpensesExcludingVAT
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.AdditionalExpensesExcludingVAT
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.AdditionalExpensesExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.CostVariance),
		|				VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|				VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|			THEN
		|				-Cost_.AdditionalExpensesExcludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.AdditionalExpensesExcludingVAT
		|			ELSE 0
		|		END) AS AdditionalExpensesExcludingVAT,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.OffBalanceCost
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.OffBalanceCost
		|						ELSE Cost_.OffBalanceCost
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.OffBalanceCost 
		|					ELSE Cost_.OffBalanceCost END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.OffBalanceCost
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods)
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.OffBalanceCost
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.OffBalanceCost
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.OffBalanceCost
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.OffBalanceCost
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.OffBalanceCost
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.OffBalanceCost
		|			ELSE 0
		|		END) AS OffBalanceCost,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.LaborCosts
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.LaborCosts
		|						ELSE Cost_.LaborCosts
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.LaborCosts 
		|					ELSE Cost_.LaborCosts END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.LaborCosts
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.LaborCosts
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.LaborCosts
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.LaborCosts
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.LaborCosts
		|			ELSE 0
		|		END) AS LaborCosts,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedFixedCostsIncludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedFixedCostsIncludingVAT
		|						ELSE Cost_.ItemizedFixedCostsIncludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedFixedCostsIncludingVAT 
		|					ELSE Cost_.ItemizedFixedCostsIncludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedFixedCostsIncludingVAT
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedFixedCostsIncludingVAT
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedFixedCostsIncludingVAT
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedFixedCostsIncludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedFixedCostsIncludingVAT
		|			ELSE 0
		|		END) AS ItemizedFixedCostsIncludingVAT,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedVariableCostsIncludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedVariableCostsIncludingVAT
		|						ELSE Cost_.ItemizedVariableCostsIncludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedVariableCostsIncludingVAT 
		|					ELSE Cost_.ItemizedVariableCostsIncludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedVariableCostsIncludingVAT
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedVariableCostsIncludingVAT
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedVariableCostsIncludingVAT
		// When the chronological sequence of the party list is disabled &restored, we clear the amount ((except of operations of receipts
		// and refunds of previous periods)
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedVariableCostsIncludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedVariableCostsIncludingVAT
		|			ELSE 0
		|		END) AS ItemizedVariableCostsIncludingVAT,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedFixedCostsExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedFixedCostsExcludingVAT
		|						ELSE Cost_.ItemizedFixedCostsExcludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedFixedCostsExcludingVAT 
		|					ELSE Cost_.ItemizedFixedCostsExcludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedFixedCostsExcludingVAT
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedFixedCostsExcludingVAT
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedFixedCostsExcludingVAT
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedFixedCostsExcludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedFixedCostsExcludingVAT
		|			ELSE 0
		|		END) AS ItemizedFixedCostsExcludingVAT,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedVariableCostsExcludingVAT
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedVariableCostsExcludingVAT
		|						ELSE Cost_.ItemizedVariableCostsExcludingVAT
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedVariableCostsExcludingVAT 
		|					ELSE Cost_.ItemizedVariableCostsExcludingVAT END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedVariableCostsExcludingVAT
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedVariableCostsExcludingVAT
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedVariableCostsExcludingVAT
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedVariableCostsExcludingVAT
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedVariableCostsExcludingVAT
		|			ELSE 0
		|		END) AS ItemizedVariableCostsExcludingVAT,
		|
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.LocalCost
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.LocalCost
		|						ELSE Cost_.LocalCost
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.LocalCost 
		|					ELSE Cost_.LocalCost END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.LocalCost
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				AND Cost_.OfficialTypeOfMovementParish AND &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|				THEN Cost_.LocalCost
		// Production at the planned cost, if deviations are written off to the cost of sales.
		// The initial cost of the node in the Local and Man accounting organizations should include the planned cost.
		// The same conditions should be in the request for the text of the tax account for the cost field.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN Cost_.LocalCost
		|			WHEN Cost_.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ProductsRelease),
		|				VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|		 	 AND Cost_.OfficialTypeOfMovementParish
		|				THEN (CASE
		|					WHEN (Cost_.Count = 0
		|					 OR &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing))
		|		 	 		AND (NOT &PreliminaryCalculation OR Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot))
		|						THEN Cost_.LocalCost
		|				ELSE 0 END)
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.LocalCost
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN -Cost_.LocalCost
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.LocalCost
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.LocalCost
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.LocalCost
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.LocalCost
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.CostVariance),
		|					VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|					VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|					VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|				THEN -Cost_.LocalCost
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.LocalCost
		|			ELSE 0
		|		END) AS LocalCost,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.AddExpensesLocal
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.AddExpensesLocal
		|						ELSE Cost_.AddExpensesLocal
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.AddExpensesLocal 
		|					ELSE Cost_.AddExpensesLocal END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.AddExpensesLocal
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.AddExpensesLocal
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.AddExpensesLocal
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.AddExpensesLocal
		// The amount of additional expenses allocated to the disposal of goods in previous periods should reduce the initial cost in the node.
		|			WHEN Cost_.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.CostVariance),
		|				VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|				VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|			THEN
		|				-Cost_.AddExpensesLocal
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.AddExpensesLocal
		|			ELSE 0
		|		END) AS AddExpensesLocal,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.OffBalanceCostLocal
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.OffBalanceCostLocal
		|						ELSE Cost_.OffBalanceCostLocal
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.OffBalanceCostLocal 
		|					ELSE Cost_.OffBalanceCostLocal END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.OffBalanceCostLocal
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.OffBalanceCostLocal
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.OffBalanceCostLocal
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.OffBalanceCostLocal
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.OffBalanceCostLocal
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.OffBalanceCostLocal
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.OffBalanceCostLocal
		|			ELSE 0
		|		END) AS OffBalanceCostLocal,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.LaborCostsLocal
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.LaborCostsLocal
		|						ELSE Cost_.LaborCostsLocal
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.LaborCostsLocal 
		|					ELSE Cost_.LaborCostsLocal END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.LaborCostsLocal
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.LaborCostsLocal
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.LaborCostsLocal
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.LaborCostsLocal
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.LaborCostsLocal
		|			ELSE 0
		|		END) AS LaborCostsLocal,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedFixedCostsCompl
		|			WHEN Cost_.ReversingEntry
		|			 AND Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedFixedCostsCompl
		|						ELSE Cost_.ItemizedFixedCostsCompl
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedFixedCostsCompl 
		|					ELSE Cost_.ItemizedFixedCostsCompl END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedFixedCostsCompl
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedFixedCostsCompl
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedFixedCostsCompl
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedFixedCostsCompl
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedFixedCostsCompl
		|			ELSE 0
		|		END) AS ItemizedFixedCostsCompl,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedVariableCostsCompl
		|			WHEN Cost_.ReversingEntry
		|			 AND Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedVariableCostsCompl
		|						ELSE Cost_.ItemizedVariableCostsCompl
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedVariableCostsCompl 
		|					ELSE Cost_.ItemizedVariableCostsCompl END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedVariableCostsCompl
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedVariableCostsCompl
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedVariableCostsCompl
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedVariableCostsCompl
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedVariableCostsCompl
		|			ELSE 0
		|		END) AS ItemizedVariableCostsCompl,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ProvisionForImpairmentLocal
		|			WHEN Cost_.ReversingEntry
		|			 AND Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ProvisionForImpairmentLocal
		|						ELSE Cost_.ProvisionForImpairmentLocal
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ProvisionForImpairmentLocal 
		|					ELSE Cost_.ProvisionForImpairmentLocal END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ProvisionForImpairmentLocal
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ProvisionForImpairmentLocal
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ProvisionForImpairmentLocal
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ProvisionForImpairmentLocal
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ProvisionForImpairmentLocal
		|			ELSE 0
		|		END) AS ProvisionForImpairmentLocal,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.CostMan
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.CostMan
		|						ELSE Cost_.CostMan
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.CostMan 
		|					ELSE Cost_.CostMan END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.CostMan
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				AND Cost_.OfficialTypeOfMovementParish AND &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|				THEN Cost_.CostMan
		// Production at the standard cost, if deviations are written off to the cost of sales.
		// The initial cost of the node in the Local and Man accounting of organizations should include the standard cost.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN Cost_.CostMan
		|			WHEN Cost_.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.ProductsRelease),
		|				VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
		|		 	 AND Cost_.OfficialTypeOfMovementParish
		|				THEN (CASE
		|					WHEN (Cost_.Count = 0
		|					 OR &MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing))
		|		 	 		AND (NOT &PreliminaryCalculation OR Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot))
		|						THEN Cost_.CostMan
		|				ELSE 0 END)
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|			 AND CalculatedDocuments.Recorder IS NOT NULL
		|				THEN 0
		|			WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|			 AND Cost_.OfficialTypeOfMovementParish
		|				THEN Cost_.CostMan
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN -Cost_.CostMan
		// We exclude the quantity and cost of writing off expenses at a fixed cost.
		// List of households. operations must match in all exceptions with this comment.
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish
		|				AND Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|					VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		|				THEN -Cost_.CostMan
		|			WHEN Cost_.ReversingEntry AND Cost_.OfficialTypeOfMovementParish
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)
		|				THEN Cost_.CostMan
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.CostMan
		|			WHEN Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			 AND Cost_.CalculationIsNotCompleted
		|				THEN -Cost_.CostMan
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.CostVariance),
		|					VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|					VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|					VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|				THEN -Cost_.CostMan
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.CostMan
		|			ELSE 0
		|		END) AS CostMan,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.AddExpensesMan
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.AddExpensesMan
		|						ELSE Cost_.AddExpensesMan
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.AddExpensesMan 
		|					ELSE Cost_.AddExpensesMan END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.AddExpensesMan
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.AddExpensesMan
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.AddExpensesMan
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.AddExpensesMan
		|			WHEN Cost_.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.CostVariance),
		|				VALUE(Enum.LotRecordTypes.CostVarianceForOtherIncome),
		|				VALUE(Enum.LotRecordTypes.GoodsCostVarianceForOtherExpenses),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod))
		|			THEN
		|				-Cost_.AddExpensesMan
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.AddExpensesMan
		|			ELSE 0
		|		END) AS AddExpensesMan,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.LaborCostsMan
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.LaborCostsMan
		|						ELSE Cost_.LaborCostsMan
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.LaborCostsMan 
		|					ELSE Cost_.LaborCostsMan END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.LaborCostsMan
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.LaborCostsMan
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.LaborCostsMan
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.LaborCostsMan
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.LaborCostsMan
		|			ELSE 0
		|		END) AS LaborCostsMan,
		|
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedFixedCostsManag
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedFixedCostsManag
		|						ELSE Cost_.ItemizedFixedCostsManag
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedFixedCostsManag 
		|					ELSE Cost_.ItemizedFixedCostsManag END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedFixedCostsManag
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedFixedCostsManag
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedFixedCostsManag
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedFixedCostsManag
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedFixedCostsManag
		|			ELSE 0
		|		END) AS ItemizedFixedCostsManag,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ItemizedVariableCostsManag
		|			WHEN Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ItemizedVariableCostsManag
		|						ELSE Cost_.ItemizedVariableCostsManag
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ItemizedVariableCostsManag 
		|					ELSE Cost_.ItemizedVariableCostsManag END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ItemizedVariableCostsManag
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ItemizedVariableCostsManag
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ItemizedVariableCostsManag
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ItemizedVariableCostsManag
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ItemizedVariableCostsManag
		|			ELSE 0
		|		END) AS ItemizedVariableCostsManag,
		|		(CASE
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN Cost_.ProvisionForImpairmentMan
		|			WHEN Cost_.ReversingEntry
		|			 AND Cost_.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction))
		|				THEN
		|					CASE 
		|						WHEN Cost_.MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.EmptyRef)
		|						 AND NOT Cost_.CalculationOfCost
		|							THEN 0
		|						WHEN NOT Cost_.OfficialTypeOfMovementParish
		|							THEN -Cost_.ProvisionForImpairmentMan
		|						ELSE Cost_.ProvisionForImpairmentMan
		|					END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN CASE WHEN NOT Cost_.OfficialTypeOfMovementParish
		|					THEN -Cost_.ProvisionForImpairmentMan 
		|					ELSE Cost_.ProvisionForImpairmentMan END
		|			WHEN Cost_.EntryType = VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				THEN Cost_.ProvisionForImpairmentMan
		|			WHEN Cost_.OfficialTypeOfMovementParish
		|				THEN 
		|					CASE
		|						WHEN CalculatedDocuments.Recorder IS NULL
		|							THEN Cost_.ProvisionForImpairmentMan
		|						WHEN (Cost_.BusinessOperation IN (&ArrayOfReceiptOperations)
		|			 			 OR Cost_.BusinessOperation IN (&ArrayOfOperationsRefundsForPastPeriods))
		|							THEN Cost_.ProvisionForImpairmentMan
		// When the chronological sequence of the party list is disabled &restored, we clear the amount (except of operations of receipts
		// and refunds of previous periods) 
		// Otherwise, there will already be an amount in the receiver node and the SLU solution will begin to double the amounts at each cost calculation.
		|						ELSE 0
		|					END
		|			WHEN NOT Cost_.OfficialTypeOfMovementParish AND Cost_.ReversingEntry
		|	 		 AND Cost_.EntryType IN (
		|			  VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			  VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod))
		|			 AND NOT (Cost_.Organization IN (&MediumSlipOrganizations)
		|					AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease))
		|				THEN -Cost_.ProvisionForImpairmentMan
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|			 AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
		|			 AND Cost_.DocumentSource <> UNDEFINED
		|			 AND Register3.IBDocumentDate < &BeginOfPeriod
		|				THEN -Cost_.ProvisionForImpairmentMan
		|			ELSE 0
		|		END) AS ProvisionForImpairmentMan
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		// The conditions for using the data of the temporary table of data from documentary sources must correspond to the conditions
		// for the formation of this table in the procedure for calculating the cost of cost correction.Adjust the value of the returns of the previous periods().
		|		LEFT JOIN TueDatesOfSourceDocuments AS Register3
		|		ON Register3.Ref = Cost_.DocumentSource
		|
		|		LEFT JOIN ThereIsReturnableWaste AS ThereIsReturnableWaste
		|		ON ThereIsReturnableWaste.Organization = Cost_.Organization
		|			AND ThereIsReturnableWaste.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND ThereIsReturnableWaste.InventoryOwnerAttribute = Cost_.InventoryOwnerAttribute
		|			AND ThereIsReturnableWaste.AccountingSection = Cost_.AccountingSection
		|
		// The connection condition must match (except for the connection type)
		// with See CostCalculationCostAdjustment.SaveCostCalculationRegisteredRecordsOfCalculatedDocuments
		|		LEFT JOIN CalculatedDocuments AS CalculatedDocuments
		|			ON CalculatedDocuments.Period = Cost_.Period
		|			AND CalculatedDocuments.Recorder = Cost_.Recorder
		|
		// Reduction of the number in the node during oncoming movements to the same node.
		|	UNION ALL
		|	SELECT
		|		Cost_.Organization                   AS Organization,
		|		Cost_.CorItemsLocationAttributes AS ItemsLocationAttributes,
		|		Cost_.CorAccountingSection                AS AccountingSection,
		|		Cost_.CorInventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|		Cost_.CorLot                     AS Lot,
		|		Cost_.LotVendorAttributesCorr       AS LotVendorAttributes,
		|		Cost_.CorControllingAttributes  AS FinancialAccountingDimension,
		|		Cost_.CorVATActivityTypes         AS VATActivityType,
		|
		|		-Cost_.Count                   AS Count,
		|		0 AS QuantityIsWrittenOffAtFixedCost,
		|		0 AS Cost,
		|		0 AS CostExcludingVAT,
		|		0 AS AddExpensesForGoods,
		|		0 AS AdditionalExpensesExcludingVAT,
		|		0 AS OffBalanceCost,
		|		0 AS LaborCosts,
		|		0 AS ItemizedFixedCostsIncludingVAT,
		|		0 AS ItemizedVariableCostsIncludingVAT,
		|		0 AS ItemizedFixedCostsExcludingVAT,
		|		0 AS ItemizedVariableCostsExcludingVAT,
		|		0 AS LocalCost,
		|		0 AS AddExpensesLocal,
		|		0 AS OffBalanceCostLocal,
		|		0 AS LaborCostsLocal,
		|		0 AS ItemizedFixedCostsCompl,
		|		0 AS ItemizedVariableCostsCompl,
		|		0 AS ProvisionForImpairmentLocal,
		|		0 AS CostMan,
		|		0 AS AddExpensesMan,
		|		0 AS LaborCostsMan,
		|		0 AS ItemizedFixedCostsManag,
		|		0 AS ItemizedVariableCostsManag,
		|		0 AS ProvisionForImpairmentMan
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|	WHERE
		|		 Cost_.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND Cost_.CorCompany = VALUE(Catalog.Companies.EmptyRef)
		|		 AND Cost_.CorItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|		 AND Cost_.CorAccountingSection                = Cost_.AccountingSection
		|		 AND Cost_.CorInventoryOwnerAttribute                 = Cost_.InventoryOwnerAttribute
		|		 AND Cost_.CorLot                     = Cost_.Lot
		|		 AND Cost_.LotVendorAttributesCorr       = Cost_.LotVendorAttributes
		|		 AND Cost_.CorControllingAttributes  = Cost_.FinancialAccountingDimension
		|		 AND Cost_.CorVATActivityTypes         = Cost_.VATActivityType
		|
		// Balances at the beginning of the billing period.
		|	UNION ALL
		|	SELECT
		|		Balance.Organization,
		|		Balance.ItemsLocationAttributes,
		|		Balance.AccountingSection,
		|		Balance.InventoryOwnerAttribute,
		|		Balance.Lot,
		|		Balance.LotVendorAttributes,
		|		Balance.FinancialAccountingDimension,
		|		Balance.VATActivityType,
		|
		|		Balance.CountBalance                  AS Count,
		|		0 AS QuantityIsWrittenOffAtFixedCost,
		|		Balance.CostBalance                   AS Cost,
		|		Balance.CostExcludingVATBalance             AS CostExcludingVAT,
		|		Balance.AddExpensesForGoodsBalance                  AS AddExpensesForGoods,
		|		Balance.AdditionalExpensesExcludingVATBalance            AS AdditionalExpensesExcludingVAT,
		|		Balance.OffBalanceCostBalance       AS OffBalanceCost,
		|		Balance.LaborCostsBalance                AS LaborCosts,
		|		Balance.ItemizedFixedCostsIncludingVATBalance   AS ItemizedFixedCostsIncludingVAT,
		|		Balance.ItemizedVariableCostsIncludingVATBalance   AS ItemizedVariableCostsIncludingVAT,
		|		Balance.ItemizedFixedCostsExcludingVATBalance AS ItemizedFixedCostsExcludingVAT,
		|		Balance.ItemizedVariableCostsExcludingVATBalance AS ItemizedVariableCostsExcludingVAT,
		|		Balance.LocalCostBalance               AS LocalCost,
		|		Balance.AddExpensesLocalBalance              AS AddExpensesLocal,
		|		Balance.OffBalanceCostLocalBalance   AS OffBalanceCostLocal,
		|		Balance.LaborCostsLocalBalance            AS LaborCostsLocal,
		|		Balance.ItemizedFixedCostsComplBalance   AS ItemizedFixedCostsCompl,
		|		Balance.ItemizedVariableCostsComplBalance   AS ItemizedVariableCostsCompl,
		|		Balance.ProvisionForImpairmentLocalBalance    AS ProvisionForImpairmentLocal,
		|		Balance.CostManBalance                AS CostMan,
		|		Balance.AddExpensesManBalance               AS AddExpensesMan,
		|		Balance.LaborCostsManBalance             AS LaborCostsMan,
		|		Balance.ItemizedFixedCostsManagBalance    AS ItemizedFixedCostsManag,
		|		Balance.ItemizedVariableCostsManagBalance    AS ItemizedVariableCostsManag,
		|		Balance.ProvisionForImpairmentManBalance     AS ProvisionForImpairmentMan
		|	FROM
		|		AccumulationRegister.InventoryCost.Balance(
		|			&BorderStartOfPeriod,
		|			Organization IN (&CompanyArray)
		|		) AS Balance
		|	) AS Cost_
		|
		|GROUP BY
		|	Cost_.Organization,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.AccountingSection,
		|	Cost_.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN &ScheduledJob
		|		 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN UNDEFINED
		|		ELSE Cost_.Lot END), // Lot
		|	(CASE
		|		WHEN &ScheduledJob THEN VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
		|		ELSE Cost_.LotVendorAttributes END), // LotVendorAttributes
		|	(CASE
		|		WHEN &ScheduledJob THEN UNDEFINED
		|		ELSE Cost_.FinancialAccountingDimension END), // FinancialAccountingDimension
		|	(CASE
		|		WHEN &ScheduledJob
		|		 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
		|		ELSE Cost_.VATActivityType END) // VATActivityType
		|
		|HAVING
		|	SUM(Cost_.Count) <> 0
		|	OR SUM(Cost_.Cost) <> 0
		|	OR SUM(Cost_.CostExcludingVAT) <> 0
		|	OR SUM(Cost_.AddExpensesForGoods) <> 0
		|	OR SUM(Cost_.AdditionalExpensesExcludingVAT) <> 0
		|	OR SUM(Cost_.OffBalanceCost) <> 0
		|	OR SUM(Cost_.LaborCosts) <> 0
		|	OR SUM(Cost_.ItemizedFixedCostsIncludingVAT) <> 0
		|	OR SUM(Cost_.ItemizedVariableCostsIncludingVAT) <> 0
		|	OR SUM(Cost_.ItemizedFixedCostsExcludingVAT) <> 0
		|	OR SUM(Cost_.ItemizedVariableCostsExcludingVAT) <> 0
		|	OR SUM(Cost_.LocalCost) <> 0
		|	OR SUM(Cost_.AddExpensesLocal) <> 0
		|	OR SUM(Cost_.OffBalanceCostLocal) <> 0
		|	OR SUM(Cost_.LaborCostsLocal) <> 0
		|	OR SUM(Cost_.ItemizedFixedCostsCompl) <> 0
		|	OR SUM(Cost_.ItemizedVariableCostsCompl) <> 0
		|	OR SUM(Cost_.ProvisionForImpairmentLocal) <> 0
		|	OR SUM(Cost_.CostMan) <> 0
		|	OR SUM(Cost_.AddExpensesMan) <> 0
		|	OR SUM(Cost_.LaborCostsMan) <> 0
		|	OR SUM(Cost_.ItemizedFixedCostsManag) <> 0
		|	OR SUM(Cost_.ItemizedVariableCostsManag) <> 0
		|	OR SUM(Cost_.ProvisionForImpairmentMan) <> 0
		|
		|INDEX BY
		|	Organization,
		|	ItemsLocationAttributes,
		|	AccountingSection,
		|	InventoryOwnerAttribute,
		|	Lot,
		|	LotVendorAttributes,
		|	FinancialAccountingDimension,
		|	VATActivityType
		|";
EndFunction


Function TTTextForMovingWriteOffs() // VT VT the translation of the description, uses VT the work of the reader

	Return "
		|SELECT
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|INTO VT_TypesOfGiverStocks
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|
		|INDEX BY
		|	InventoryOwnerAttribute
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Cost_.SourceNodeNumber            					AS SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber            					AS ReceiverNodeNumber,
		|	Cost_.TransferToAnotherOrganization 					AS TransferToAnotherOrganization,
		|	Cost_.Organization 									AS Organization,
		|	SUM(Cost_.Count)	           					AS ArcWeight,
		|	MAX(Cost_.DoNotMoveOffBalanceSheetValue)  	AS DoNotMoveOffBalanceSheetValue,
		|	MAX(Cost_.DoNotMoveBookValue)  	AS DoNotMoveBookValue,
		|	MAX(Cost_.DoNotMoveNetInitialCostLOCAL)			AS DoNotMoveNetInitialCostLOCAL,
		|	MAX(Cost_.SourceOnMediumSlip)			AS SourceOnMediumSlip
		|INTO TTWriteOffs
		|FROM (
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		(CASE
		|			WHEN Cost_.BusinessOperation IN (
		|			 VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			 VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))
		|				THEN AdjustmentNodesReceiverLocalAccounting.NodeNumber
		|			WHEN NOT AdjustmentNodesTransmissionReceiver.NodeNumber IS NULL
		|				THEN AdjustmentNodesTransmissionReceiver.NodeNumber
		|			ELSE AdjustmentNodesReceiver.NodeNumber END) AS ReceiverNodeNumber,
		// The condition for checking for a transfer to another organization must correspond 
		// to the function of the text of the movement of the highest value of the products during the period of detailed worship().
		|		(CASE
		|			WHEN Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|				THEN TRUE
		|			ELSE FALSE END) AS TransferToAnotherOrganization,
		|		Cost_.Count,
		// The condition should be similar to the calculation of the cost of cost correction.To form a Movement recordthe value of goods by request, the value-off-balance and value-off-balance fields
		|		CASE
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
		|				THEN TRUE
		|			WHEN VT_TypesOfGiverStocks.InventoryOwnerAttribute IS NOT NULL 
		|					AND (VT_TypesOfGiverStocksBalanced.InventoryOwnerAttribute IS NULL
		|						OR Cost_.CorItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
		|				THEN TRUE
		|				ELSE FALSE
		|		END AS DoNotMoveOffBalanceSheetValue,
		|		(CASE
		|			WHEN (FALSE
		|				OR Cost_.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|						VALUE(Enum.BusinessTransactions.Subcontracting2_5),
		|						VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
		|						VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
		|						VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
		|						VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
		|	  			OR Cost_.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff)
		|				) THEN TRUE
		|			ELSE FALSE END) AS DoNotMoveBookValue,
		|	(CASE
		|		WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		 AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE END) AS DoNotMoveNetInitialCostLOCAL,
		|		Cost_.Organization AS Organization,
		|		(CASE
		// For work-in-progress, the cost estimation method is not checked, because with any valuation method it is necessary 
		// to calculate the actual cost of the product.
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		 	 OR VALUETYPE(Cost_.Lot) = TYPE(Catalog.ProductionLots)
		|				THEN FALSE
		|			ELSE
		|				TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			END) AS SourceOnMediumSlip
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND SourceAdjustmentNodes.AccountingSection                 = Cost_.AccountingSection
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                  = Cost_.InventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization                 = Cost_.Organization
		|			AND (SourceAdjustmentNodes.Lot              	    = Cost_.Lot
		|				OR &ScheduledJob
		|		 		AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			AND (SourceAdjustmentNodes.LotVendorAttributes        = Cost_.LotVendorAttributes
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.FinancialAccountingDimension   = Cost_.FinancialAccountingDimension
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.VATActivityType          = Cost_.VATActivityType
		|				OR &ScheduledJob
		|		 		AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|
		|		LEFT JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.CorAccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND (AdjustmentNodesReceiver.Lot                    = Cost_.CorLot
		|				OR &ScheduledJob
		|		 		AND Cost_.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			AND (AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributesCorr
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.CorControllingAttributes
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesReceiver.VATActivityType        = Cost_.CorVATActivityTypes
		|				OR &ScheduledJob
		|		 		AND Cost_.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|
		|		LEFT JOIN TTAdjustmentNodes AS AdjustmentNodesTransmissionReceiver
		|		ON
		|			AdjustmentNodesTransmissionReceiver.ItemsLocationAttributes  = Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesTransmissionReceiver.AccountingSection               = Cost_.CorAccountingSection
		|			AND AdjustmentNodesTransmissionReceiver.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesTransmissionReceiver.Organization               = Cost_.CorCompany
		|			AND (AdjustmentNodesTransmissionReceiver.Lot                   = Cost_.CorLot
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.LotVendorAttributes     = Cost_.LotVendorAttributesCorr
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.FinancialAccountingDimension = Cost_.CorControllingAttributes
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.VATActivityType        = Cost_.CorVATActivityTypes
		|				OR &ScheduledJob)
		|			AND Cost_.AccountingSection    <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
		|			AND Cost_.CorCompany <> Cost_.Organization
		|			AND Cost_.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|
		|		LEFT JOIN
		|			TTAdjustmentNodes AS AdjustmentNodesReceiverLocalAccounting
		|		ON
		|			AdjustmentNodesReceiverLocalAccounting.ItemsLocationAttributes 	= Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesReceiverLocalAccounting.AccountingSection 				= Cost_.AccountingSection
		|			AND AdjustmentNodesReceiverLocalAccounting.InventoryOwnerAttribute 					= Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesReceiverLocalAccounting.Organization 				= Cost_.CorCompany
		|			AND AdjustmentNodesReceiverLocalAccounting.Lot 						= Cost_.CorLot
		|			AND AdjustmentNodesReceiverLocalAccounting.LotVendorAttributes 		= Cost_.LotVendorAttributesCorr
		|			AND AdjustmentNodesReceiverLocalAccounting.FinancialAccountingDimension 	= Cost_.CorControllingAttributes
		|			AND AdjustmentNodesReceiverLocalAccounting.VATActivityType 			= Cost_.CorVATActivityTypes
		|
		|		LEFT JOIN ThereIsReturnableWaste AS ThereIsReturnableWaste
		|			ON ThereIsReturnableWaste.Organization = Cost_.Organization
		|			AND ThereIsReturnableWaste.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND ThereIsReturnableWaste.InventoryOwnerAttribute = Cost_.InventoryOwnerAttribute
		|			AND ThereIsReturnableWaste.AccountingSection = Cost_.AccountingSection
		|		LEFT JOIN VT_TypesOfGiverStocks AS VT_TypesOfGiverStocks
		|			ON Cost_.InventoryOwnerAttribute = VT_TypesOfGiverStocks.InventoryOwnerAttribute
		|		LEFT JOIN VT_TypesOfGiverStocks AS VT_TypesOfGiverStocksBalanced
		|			ON Cost_.CorInventoryOwnerAttribute = VT_TypesOfGiverStocksBalanced.InventoryOwnerAttribute
		|	WHERE
		|		NOT Cost_.OfficialTypeOfMovementParish
		|		AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		AND NOT (Cost_.ReversingEntry
		|			AND Cost_.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|				VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction)))
		|		AND (NOT AdjustmentNodesReceiver.NodeNumber IS NULL
		|			OR NOT AdjustmentNodesTransmissionReceiver.NodeNumber IS NULL
		|			OR NOT AdjustmentNodesReceiverLocalAccounting.NodeNumber IS NULL)
		// Let's exclude moving to the same node, except for the output
		|		AND (SourceAdjustmentNodes.NodeNumber <>
		|			(CASE
		|				WHEN Cost_.BusinessOperation IN (
		|				 VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|				 VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))
		|					THEN AdjustmentNodesReceiverLocalAccounting.NodeNumber
		|				WHEN NOT AdjustmentNodesTransmissionReceiver.NodeNumber IS NULL
		|					THEN AdjustmentNodesTransmissionReceiver.NodeNumber
		|				ELSE AdjustmentNodesReceiver.NodeNumber END)
		|			OR Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease))
		// We Exclude the transfer of products to the warehouse at A Fixed Cost. The Fixed Cost has Already Been Taken Into Account In The Initial Cost Of The Node.
		|		AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)
		// We exclude returnable waste (the arc for returnable waste is formed by a separate request).
		|		AND NOT(Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|			AND Cost_.Count < 0
		|			AND NOT ThereIsReturnableWaste.Organization IS NULL)
		|
		// Reducing the weight of arcs when returning goods from the customer or when adjusting sales in the negative,
		// if the type of VAT activity does not change during the return.
		|	UNION ALL
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		FALSE AS TransferToAnotherOrganization,
		|		-Cost_.Count AS Count,
		|		FALSE AS DoNotMoveOffBalanceSheetValue,
		|		FALSE AS DoNotMoveBookValue,
		|		FALSE AS DoNotMoveNetInitialCostLOCAL,
		|		Cost_.Organization AS Organization,
		|		(CASE
		// For work-in-progress, the cost estimation method is not checked, because with any valuation method it is necessary 
		// to calculate the actual cost of the product.
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		 	 OR VALUETYPE(Cost_.Lot) = TYPE(Catalog.ProductionLots)
		|				THEN FALSE
		|			ELSE
		|				TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			END) AS SourceOnMediumSlip
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes   = Cost_.CorItemsLocationAttributes
		|			AND SourceAdjustmentNodes.AccountingSection               = Cost_.AccountingSection
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization               = Cost_.Organization
		|			AND SourceAdjustmentNodes.Lot                    = Cost_.Lot
		|			AND SourceAdjustmentNodes.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND SourceAdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND SourceAdjustmentNodes.VATActivityType        = Cost_.VATActivityTypeShipments
		|
		|		INNER JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.AccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND AdjustmentNodesReceiver.Lot                    = Cost_.Lot
		|			AND AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND AdjustmentNodesReceiver.VATActivityType        = Cost_.VATActivityType
		|	WHERE
		|		NOT Cost_.OfficialTypeOfMovementParish
		|		AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReversingEntry)
		|		AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|		AND NOT Cost_.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		AND SourceAdjustmentNodes.NodeNumber <> AdjustmentNodesReceiver.NodeNumber
		|
		
		// Distribution of returnable waste
		|	UNION ALL
		|
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		FALSE AS TransferToAnotherOrganization,
		|		Cost_.Count AS Count,
		|		FALSE AS DoNotMoveOffBalanceSheetValue,
		|		FALSE AS DoNotMoveBookValue,
		|		FALSE AS DoNotMoveNetInitialCostLOCAL,
		|		Cost_.Organization AS Organization,
		|		(CASE
		// For work-in-progress, the cost estimation method is not checked, because with any valuation method it is necessary 
		// to calculate the actual cost of the product.
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|		 	 OR VALUETYPE(Cost_.Lot) = TYPE(Catalog.ProductionLots)
		|				THEN FALSE
		|			ELSE
		|				TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			END) AS SourceOnMediumSlip
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization               = Cost_.Organization
		|			AND SourceAdjustmentNodes.AccountingSection               = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			AND SourceAdjustmentNodes.Lot                    = Cost_.Lot
		|			AND SourceAdjustmentNodes.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND SourceAdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND SourceAdjustmentNodes.VATActivityType        = Cost_.VATActivityType
		|
		|		LEFT JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.CorAccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND AdjustmentNodesReceiver.Lot                    = Cost_.CorLot
		|			AND AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributesCorr
		|			AND AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.CorControllingAttributes
		|			AND AdjustmentNodesReceiver.VATActivityType        = Cost_.CorVATActivityTypes
		|
		|		LEFT JOIN ThereIsReturnableWaste AS ThereIsReturnableWaste
		|			ON ThereIsReturnableWaste.Organization               = Cost_.Organization
		|			AND ThereIsReturnableWaste.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND ThereIsReturnableWaste.InventoryOwnerAttribute                 = Cost_.InventoryOwnerAttribute
		|			AND ThereIsReturnableWaste.AccountingSection                = Cost_.AccountingSection
		|	WHERE
		|		NOT Cost_.OfficialTypeOfMovementParish
		|		AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|		AND Cost_.Count < 0
		|		AND NOT ThereIsReturnableWaste.Organization IS NULL
		|
		// Return to another warehouse
		|	UNION ALL
		|
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		FALSE AS TransferToAnotherOrganization,
		|		Cost_.Count AS Count,
		|		FALSE AS DoNotMoveOffBalanceSheetValue,
		|		FALSE AS DoNotMoveBookValue,
		|		FALSE AS DoNotMoveNetInitialCostLOCAL,
		|		Cost_.Organization AS Organization,
		|		TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage) AS SourceOnMediumSlip
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = Cost_.CorItemsLocationAttributes
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute = Cost_.CorInventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization = Cost_.Organization
		|			AND SourceAdjustmentNodes.Lot = Cost_.CorLot
		|			AND SourceAdjustmentNodes.LotVendorAttributes = Cost_.LotVendorAttributesCorr
		|			AND SourceAdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND SourceAdjustmentNodes.VATActivityType = Cost_.CorVATActivityTypes
		|
		|		LEFT JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.AccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND AdjustmentNodesReceiver.Lot                    = Cost_.Lot
		|			AND AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND AdjustmentNodesReceiver.VATActivityType        = Cost_.VATActivityType
		|	WHERE
		|		Cost_.OfficialTypeOfMovementParish
		|		AND Cost_.Count > 0
		|		AND Cost_.EntryType IN (VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse))
		|		AND SourceAdjustmentNodes.NodeNumber <> AdjustmentNodesReceiver.NodeNumber
		|
		|	) AS Cost_
		|GROUP BY
		|	Cost_.SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber,
		|	Cost_.TransferToAnotherOrganization,
		|	Cost_.Organization
		|";
EndFunction

Function TextServiceNodesMaterialAndLaborCosts() // TT nodal_material_work costs
	Return "
		|SELECT
		|	InitialCostOfNodes.NodeNumber AS NodeNumber,
		|	SUM(InitialCostOfNodes.Cost) AS Cost,
		|	SUM(InitialCostOfNodes.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(InitialCostOfNodes.OffBalanceCost) AS OffBalanceCost,
		|	SUM(InitialCostOfNodes.LaborCosts) AS LaborCosts,
		|	SUM(InitialCostOfNodes.LocalCost) AS LocalCost,
		|	SUM(InitialCostOfNodes.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(InitialCostOfNodes.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(InitialCostOfNodes.CostMan) AS CostMan,
		|	SUM(InitialCostOfNodes.LaborCostsMan) AS LaborCostsMan
		|
		|INTO ServiceNodesMaterialAndLaborCosts
		|FROM
		|	(SELECT
		|		AdjustmentNodes.NodeNumber AS NodeNumber,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|				THEN 0
		|			ELSE AdjustmentNodes.Cost
		|		END AS Cost,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|				THEN 0
		|			ELSE AdjustmentNodes.CostExcludingVAT
		|		END AS CostExcludingVAT,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|					VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		 	 AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
		|				THEN 0
		|			ELSE AdjustmentNodes.OffBalanceCost
		|		END AS OffBalanceCost,
		|		AdjustmentNodes.LaborCosts AS LaborCosts,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|			ELSE AdjustmentNodes.LocalCost
		|		END AS LocalCost,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		 	 AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
		|				THEN 0
		|			ELSE AdjustmentNodes.OffBalanceCostLocal
		|		END AS OffBalanceCostLocal,
		|		AdjustmentNodes.LaborCostsLocal AS LaborCostsLocal,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|			ELSE AdjustmentNodes.CostMan
		|		END AS CostMan,
		|		AdjustmentNodes.LaborCostsMan AS LaborCostsMan
		|	FROM
		|		TTAdjustmentNodes AS AdjustmentNodes
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		AdjustmentNodes.NodeNumber,
		|		0 AS Cost,
		|		0 AS CostExcludingVAT,
		|		0 AS OffBalanceCost,
		|		0 AS LaborCosts,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			THEN 0
		|			ELSE CAST(Costs_2.ProvisionForImpairmentLocal * ReserveConnections.ArcWeight AS NUMBER(28, 10))
		|		END AS LocalCost,
		|		0,
		|		0,
		|		CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			THEN 0
		|			ELSE CAST(Costs_2.ProvisionForImpairmentMan * ReserveConnections.ArcWeight AS NUMBER(28, 10))
		|		END AS CostMan,
		|		0
		|	FROM
		|		ConnectionsOfNodesOfReservesUnderImpairmentOfStocks AS ReserveConnections
		|			INNER JOIN TTAdjustmentNodes AS AdjustmentNodes
		|			ON ReserveConnections.ReceiverNodeNumber = AdjustmentNodes.NodeNumber
		|			INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|			ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|			INNER JOIN TTValueOfBatchesOfGoods AS Costs_2
		|			ON ReserveConnections.SourceNodeNumber = Costs_2.NodeNumber
		|	WHERE
		|		NOT ReserveConnections.TransferReserve
		|		AND NOT ReserveConnections.RestoreReserves
		|	) AS InitialCostOfNodes
		|
		|GROUP BY
		|	InitialCostOfNodes.NodeNumber
		|";
EndFunction

Function CommunicationTextSLU_MaterialAndLaborCosts() // TT svyazislu_materialnit labor costs
	Return "
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|			OR WriteOffMovements.SourceOnMediumSlip THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightCost,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|			OR WriteOffMovements.SourceOnMediumSlip THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightCostWithoutVAT,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveOffBalanceSheetValue, FALSE)
		|			OR WriteOffMovements.SourceOnMediumSlip THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightCostOffBalance,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLaborCosts,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.SourceOnMediumSlip
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLocalCost,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveOffBalanceSheetValue, FALSE)
		|			OR WriteOffMovements.SourceOnMediumSlip
		|		THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightCostOffBalanceLocal,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLocalLaborCosts,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.SourceOnMediumSlip
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightManCost,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLaborCostsMan
		|
		|INTO ServiceConnectionsMaterialAndLaborCosts
		|FROM
		|	TTWriteOffs AS WriteOffMovements
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		// The expression below should match in the trace. places: The text of the link_state_the output of the enterprise, the text_state_state_the output of the organization
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightCost,
		|
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightCostWithoutVAT,
		|
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		  AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightCostOffBalance,
		|
		|	CAST(AdjustmentNodes.Count
		|		- AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightLaborCosts,
		|
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightLocalCost,
		|
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|		  AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightCostOffBalanceLocal,
		|
		|	CAST(AdjustmentNodes.Count
		|		- AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightLocalLaborCosts,
		|
		|	CAST(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND NOT AdjustmentNodes.AccountingSection IN (
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
		|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|			THEN 0
		|		ELSE AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost
		|	END AS NUMBER(28,10)) AS ArcWeightManCost,
		|
		|	CAST(AdjustmentNodes.Count
		|		- AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightLaborCostsMan
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForSolvingSLAByFIFOWeighted

Procedure PrepareDataForCalculatingCostOfFIFO(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForCalculatingFIFOCostWeighted");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);

	// Formation of the node table.
	Query.Text =
	"SELECT
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Organization,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|
	|	Cost_.CountBalance
	|INTO TTInitialBalances
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(&BorderStartOfPeriod,
	|			Organization IN (&SFIFOOrganizationsWeighted)
	|		) AS Cost_
	|
	|INDEX BY
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Organization,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|
	|	Cost_.Count                    AS CountBalance,
	|	Cost_.AddExpensesForGoods                    AS AddExpensesForGoodsBalance,
	|	Cost_.AdditionalExpensesExcludingVAT              AS AdditionalExpensesExcludingVATBalance,
	|	Cost_.LaborCosts                  AS LaborCostsBalance,
	|	Cost_.ItemizedFixedCostsIncludingVAT     AS ItemizedFixedCostsIncludingVATBalance,
	|	Cost_.ItemizedFixedCostsExcludingVAT   AS ItemizedFixedCostsExcludingVATBalance,
	|	Cost_.ItemizedVariableCostsIncludingVAT     AS ItemizedVariableCostsIncludingVATBalance,
	|	Cost_.ItemizedVariableCostsExcludingVAT   AS ItemizedVariableCostsExcludingVATBalance,
	|
	|	Cost_.AddExpensesLocal                AS AddExpensesLocalBalance,
	|	Cost_.LaborCostsLocal              AS LaborCostsLocalBalance,
	|	Cost_.ItemizedFixedCostsCompl     AS ItemizedFixedCostsComplBalance,
	|	Cost_.ItemizedVariableCostsCompl     AS ItemizedVariableCostsComplBalance,
	|	Cost_.AddExpensesMan                 AS AddExpensesManBalance,
	|	Cost_.LaborCostsMan               AS LaborCostsManBalance,
	|	Cost_.ItemizedFixedCostsManag      AS ItemizedFixedCostsManagBalance,
	|	Cost_.ItemizedVariableCostsManag      AS ItemizedVariableCostsManagBalance
	|
	|INTO TTFinalResiduals
	|FROM
	|	TTCashSettlementBalancesCostOfGoods AS Cost_
	|WHERE
	|	Cost_.Organization IN (&SFIFOOrganizationsWeighted)
	|	
	|INDEX BY
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|
	|	SUM(Cost_.Count) AS CountReceipt
	|INTO TTParishes
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS Cost_
	|WHERE
	|	Cost_.OfficialTypeOfMovementParish
	|	AND Cost_.Organization IN (&SFIFOOrganizationsWeighted)
	|	AND (Cost_.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|		OR NOT &BatchAccountingVersion22)
	|
	|GROUP BY
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|
	|INDEX BY
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	DATEADD(&EndOfPeriod, SECOND, 1) AS Period,
	|	FinalBalances.Organization,
	|	FinalBalances.ItemsLocationAttributes,
	|	FinalBalances.AccountingSection,
	|	FinalBalances.InventoryOwnerAttribute,
	|	FinalBalances.Lot,
	|	FinalBalances.LotVendorAttributes,
	|	FinalBalances.FinancialAccountingDimension,
	|	FinalBalances.VATActivityType,
	|
	|	(CASE
	|		WHEN FinalBalances.CountBalance > 0 THEN FinalBalances.CountBalance
	|		ELSE 0 END) 																		AS CountBalance,
	|	(CASE
	|		WHEN FinalBalances.CountBalance > 0 THEN FinalBalances.CountBalance
	|		ELSE 0 END) 																		AS AmountBalanceAtEndOfPeriod,
	|	ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) AS CountReceipt,
	|
	|	0 AS CostBalance,
	|	0 AS CostExcludingVATBalance,
	|	0 AS OffBalanceCostBalance,
	|	0 AS LocalCostBalance,
	|	0 AS OffBalanceCostLocalBalance,
	|	0 AS CostManBalance,
	|
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.AddExpensesForGoodsBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS AdditionalExpenseCostBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.AdditionalExpensesExcludingVATBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS AdditionalExpensesCostExcludingVATBalance,
	|
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.LaborCostsBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS LaborCostsBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedFixedCostsIncludingVATBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedFixedCostsIncludingVATBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedFixedCostsExcludingVATBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedFixedCostsExcludingVATBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedVariableCostsIncludingVATBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedVariableCostsIncludingVATBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		  AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedVariableCostsExcludingVATBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedVariableCostsExcludingVATBalance,
	|
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.AddExpensesLocalBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS AddExpensesLocalBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.AddExpensesManBalance /
	|					(ISNULL(Parishes.CountReceipt, 0) + ISNULL(InitialResiduals.CountBalance, 0))
	|		ELSE 0 END) AS AddExpensesManBalance,
	|
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.LaborCostsLocalBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS LaborCostsLocalBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedFixedCostsComplBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedFixedCostsComplBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedVariableCostsComplBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedVariableCostsComplBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.LaborCostsManBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS LaborCostsManBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedFixedCostsManagBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedFixedCostsManagBalance,
	|	(CASE
	|		WHEN ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > FinalBalances.CountBalance
	|		 AND ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0) > 0
	|			THEN FinalBalances.CountBalance * FinalBalances.ItemizedVariableCostsManagBalance /
	|					(ISNULL(InitialResiduals.CountBalance, 0) + ISNULL(Parishes.CountReceipt, 0))
	|		ELSE 0 END) AS ItemizedVariableCostsManagBalance
	|
	|INTO BalanceTable
	|FROM
	|	TTFinalResiduals AS FinalBalances
	|
	|	LEFT JOIN TTInitialBalances AS InitialResiduals
	|		ON FinalBalances.Organization = InitialResiduals.Organization
	|		AND FinalBalances.ItemsLocationAttributes = InitialResiduals.ItemsLocationAttributes
	|		AND FinalBalances.AccountingSection = InitialResiduals.AccountingSection
	|		AND FinalBalances.InventoryOwnerAttribute = InitialResiduals.InventoryOwnerAttribute
	|		AND FinalBalances.Lot = InitialResiduals.Lot
	|		AND FinalBalances.LotVendorAttributes = InitialResiduals.LotVendorAttributes
	|		AND FinalBalances.FinancialAccountingDimension = InitialResiduals.FinancialAccountingDimension
	|		AND FinalBalances.VATActivityType = InitialResiduals.VATActivityType
	|
	|	LEFT JOIN TTParishes AS Parishes
	|		ON FinalBalances.Organization = Parishes.Organization
	|		AND FinalBalances.ItemsLocationAttributes = Parishes.ItemsLocationAttributes
	|		AND FinalBalances.AccountingSection = Parishes.AccountingSection
	|		AND FinalBalances.InventoryOwnerAttribute = Parishes.InventoryOwnerAttribute
	|		AND FinalBalances.Lot = Parishes.Lot
	|		AND FinalBalances.LotVendorAttributes = Parishes.LotVendorAttributes
	|		AND FinalBalances.FinancialAccountingDimension = Parishes.FinancialAccountingDimension
	|		AND FinalBalances.VATActivityType = Parishes.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTInitialBalances
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTFinalResiduals
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTParishes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	1 
	|INTO TableOfBatchPeriods
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);

	Query.Text =
	"
	|DROP TableOfBatchPeriods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	InventoryCost.Organization                           AS Organization,
	|	InventoryCost.ItemsLocationAttributes            AS ItemsLocationAttributes,
	|	InventoryCost.AccountingSection                           AS AccountingSection,
	|	InventoryCost.InventoryOwnerAttribute                            AS InventoryOwnerAttribute,
	|	InventoryCost.Lot                                AS Lot,
	|	InventoryCost.LotVendorAttributes                  AS LotVendorAttributes,
	|	InventoryCost.FinancialAccountingDimension             AS FinancialAccountingDimension,
	|	InventoryCost.VATActivityType                    AS VATActivityType,
	|	MAX(BEGINOFPERIOD(InventoryCost.Period, DAY)) AS Period
	|INTO TableOfBatchPeriods
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS InventoryCost
	|		INNER JOIN BalanceTable AS BalanceTable
	|			ON InventoryCost.ItemsLocationAttributes   = BalanceTable.ItemsLocationAttributes
	|				AND InventoryCost.AccountingSection 				 = BalanceTable.AccountingSection
	|				AND InventoryCost.InventoryOwnerAttribute  				 = BalanceTable.InventoryOwnerAttribute
	|				AND InventoryCost.Organization 				 = BalanceTable.Organization
	|				AND InventoryCost.Lot 					 = BalanceTable.Lot
	|				AND InventoryCost.LotVendorAttributes 	 = BalanceTable.LotVendorAttributes
	|				AND InventoryCost.FinancialAccountingDimension = BalanceTable.FinancialAccountingDimension
	|				AND InventoryCost.VATActivityType 		 = BalanceTable.VATActivityType
	|				AND BalanceTable.CountBalance <> 0
	|WHERE
	|	InventoryCost.OfficialTypeOfMovementParish
	|	AND InventoryCost.Cost <> 0
	|	AND InventoryCost.Period < BalanceTable.Period
	|
	|GROUP BY
	|	InventoryCost.ItemsLocationAttributes,
	|	InventoryCost.InventoryOwnerAttribute,
	|	InventoryCost.AccountingSection,
	|	InventoryCost.Organization,
	|	InventoryCost.Lot,
	|	InventoryCost.LotVendorAttributes,
	|	InventoryCost.FinancialAccountingDimension,
	|	InventoryCost.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Cost_.Period                                AS Period,
	|	Cost_.Organization                           AS Organization,
	|	Cost_.ItemsLocationAttributes            AS ItemsLocationAttributes,
	|	Cost_.AccountingSection                           AS AccountingSection,
	|	Cost_.InventoryOwnerAttribute                            AS InventoryOwnerAttribute,
	|	Cost_.Lot                                AS Lot,
	|	Cost_.LotVendorAttributes                  AS LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension             AS FinancialAccountingDimension,
	|	Cost_.VATActivityType                    AS VATActivityType,
	|	SUM(Cost_.Count)                     AS Count,
	|	SUM(Cost_.Cost)                      AS Cost,
	|	SUM(Cost_.CostExcludingVAT)                AS CostExcludingVAT,
	|	SUM(Cost_.OffBalanceCost)          AS OffBalanceCost,
	|	SUM(Cost_.LocalCost)                  AS LocalCost,
	|	SUM(Cost_.OffBalanceCostLocal)      AS OffBalanceCostLocal,
	|	SUM(Cost_.CostMan)                   AS CostMan
	|INTO ExternalRevenueTable
	|FROM
	|	(SELECT
	|		PartyPeriods.Period                                AS Period,
	|		PartyPeriods.Organization                           AS Organization,
	|		PartyPeriods.ItemsLocationAttributes            AS ItemsLocationAttributes,
	|		PartyPeriods.AccountingSection                           AS AccountingSection,
	|		PartyPeriods.InventoryOwnerAttribute                            AS InventoryOwnerAttribute,
	|		PartyPeriods.Lot                                AS Lot,
	|		PartyPeriods.LotVendorAttributes                  AS LotVendorAttributes,
	|		PartyPeriods.FinancialAccountingDimension             AS FinancialAccountingDimension,
	|		PartyPeriods.VATActivityType                    AS VATActivityType,
	|		ISNULL(Cost_.Count, 0)               AS Count,
	|		ISNULL(Cost_.Cost, 0)                AS Cost,
	|		ISNULL(Cost_.CostExcludingVAT, 0)          AS CostExcludingVAT,
	|		ISNULL(Cost_.OffBalanceCost, 0)    AS OffBalanceCost,
	|		ISNULL(Cost_.LocalCost, 0)            AS LocalCost,
	|		ISNULL(Cost_.OffBalanceCostLocal, 0) AS OffBalanceCostLocal,
	|		ISNULL(Cost_.CostMan, 0)             AS CostMan
	|	FROM
	|		TableOfBatchPeriods AS PartyPeriods
	|			LEFT JOIN TTCashEstimatedTurnoverCostOfGoods AS Cost_
	|			ON PartyPeriods.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
	|				AND PartyPeriods.AccountingSection               = Cost_.AccountingSection
	|				AND PartyPeriods.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
	|				AND PartyPeriods.Organization               = Cost_.Organization
	|				AND PartyPeriods.Lot                    = Cost_.Lot
	|				AND PartyPeriods.LotVendorAttributes      = Cost_.LotVendorAttributes
	|				AND PartyPeriods.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
	|				AND PartyPeriods.VATActivityType        = Cost_.VATActivityType
	|				AND Cost_.OfficialTypeOfMovementParish
	|				AND (Cost_.Period BETWEEN PartyPeriods.Period AND ENDOFPERIOD(PartyPeriods.Period, DAY))
	|				AND (Cost_.BusinessOperation IN (&ArrayOfOperationsExternalReceipt))
	|				AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	) AS Cost_
	|
	|GROUP BY
	|	Cost_.Period,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Organization,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ExternalRevenueTable.Period AS Period,
	|	BalanceTable.Organization,
	|	BalanceTable.ItemsLocationAttributes,
	|	BalanceTable.AccountingSection,
	|	BalanceTable.InventoryOwnerAttribute,
	|	BalanceTable.Lot,
	|	BalanceTable.LotVendorAttributes,
	|	BalanceTable.FinancialAccountingDimension,
	|	BalanceTable.VATActivityType,
	|	(CASE
	|		WHEN BalanceTable.CountBalance > ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN BalanceTable.CountBalance - ISNULL(ExternalRevenueTable.Count, 0)
	|		ELSE 0 END) AS NewQuantityBalance,
	|	BalanceTable.AmountBalanceAtEndOfPeriod,
	|	BalanceTable.CountReceipt,
	|
	|	BalanceTable.CostBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.Cost, 0)
	|		ELSE ISNULL(ExternalRevenueTable.Cost, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewCostBalance,
	|
	|	BalanceTable.CostExcludingVATBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.CostExcludingVAT, 0)
	|		ELSE ISNULL(ExternalRevenueTable.CostExcludingVAT, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewValueWithoutVATBalance,
	|
	|	BalanceTable.OffBalanceCostBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.OffBalanceCost, 0)
	|		ELSE ISNULL(ExternalRevenueTable.OffBalanceCost, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewValueOffBalanceBalance,
	|
	|	BalanceTable.LocalCostBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.LocalCost, 0)
	|		ELSE ISNULL(ExternalRevenueTable.LocalCost, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewValueLocalBalance,
	|
	|	BalanceTable.OffBalanceCostLocalBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.OffBalanceCostLocal, 0)
	|		ELSE ISNULL(ExternalRevenueTable.OffBalanceCostLocal, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewValueOffBalanceSheetLocalBalance,
	|
	|	BalanceTable.CostManBalance
	|	+ CASE
	|		WHEN BalanceTable.CountBalance >= ISNULL(ExternalRevenueTable.Count, 0)
	|			THEN ISNULL(ExternalRevenueTable.CostMan, 0)
	|		ELSE ISNULL(ExternalRevenueTable.CostMan, 0) * BalanceTable.CountBalance / ISNULL(ExternalRevenueTable.Count, 1)
	|	END                                      AS NewCostOfManBalance,
	|
	|	BalanceTable.AdditionalExpenseCostBalance          AS NewValueAdditionalExpensesBalance,
	|	BalanceTable.AdditionalExpensesCostExcludingVATBalance    AS NewValueAdditionalExpensesWithoutVATBalance,
	|	BalanceTable.LaborCostsBalance                 AS NewLaborCostBalance,
	|	BalanceTable.ItemizedFixedCostsIncludingVATBalance    AS NewArticleByArticleConstantsWithVAT,
	|	BalanceTable.ItemizedFixedCostsExcludingVATBalance  AS NewArticleByArticlePermanentWithoutVATBalance,
	|	BalanceTable.ItemizedVariableCostsIncludingVATBalance    AS NewArticleByArticleVariablesWithVATRemainder,
	|	BalanceTable.ItemizedVariableCostsExcludingVATBalance  AS NewArticleByArticleVariablesExcludingVATBalance,
	|
	|	BalanceTable.AddExpensesLocalBalance               AS NewLocalBalanceSupplement,
	|	BalanceTable.LaborCostsLocalBalance             AS NewLaborCostsLocalBalance,
	|	BalanceTable.ItemizedFixedCostsComplBalance    AS NewArticleByArticlePermanentLocalRemainder,
	|	BalanceTable.ItemizedVariableCostsComplBalance    AS NewArticleByArticleVariablesLocalRemainder,
	|
	|	BalanceTable.AddExpensesManBalance                AS NewSupplementManBalance,
	|	BalanceTable.LaborCostsManBalance              AS NewLaborCostsManBalance,
	|	BalanceTable.ItemizedFixedCostsManagBalance     AS NewArticleByArticlePermanentMan,
	|	BalanceTable.ItemizedVariableCostsManagBalance     AS NewArticleByArticleVariablesOfMan
	|
	|INTO TableOfNewBalances
	|FROM
	|	BalanceTable AS BalanceTable
	|		LEFT JOIN ExternalRevenueTable AS ExternalRevenueTable
	|		ON BalanceTable.ItemsLocationAttributes 	= ExternalRevenueTable.ItemsLocationAttributes
	|			AND BalanceTable.Organization 				= ExternalRevenueTable.Organization
	|			AND BalanceTable.AccountingSection 				= ExternalRevenueTable.AccountingSection
	|			AND BalanceTable.InventoryOwnerAttribute  				= ExternalRevenueTable.InventoryOwnerAttribute
	|			AND BalanceTable.Lot                    = ExternalRevenueTable.Lot
	|			AND BalanceTable.LotVendorAttributes      = ExternalRevenueTable.LotVendorAttributes
	|			AND BalanceTable.FinancialAccountingDimension = ExternalRevenueTable.FinancialAccountingDimension
	|			AND BalanceTable.VATActivityType        = ExternalRevenueTable.VATActivityType
	|			AND BalanceTable.CountBalance <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP BalanceTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP ExternalRevenueTable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TableOfNewBalances.Period,
	|	TableOfNewBalances.Organization,
	|	TableOfNewBalances.ItemsLocationAttributes,
	|	TableOfNewBalances.AccountingSection,
	|	TableOfNewBalances.InventoryOwnerAttribute,
	|	TableOfNewBalances.Lot,
	|	TableOfNewBalances.LotVendorAttributes,
	|	TableOfNewBalances.FinancialAccountingDimension,
	|	TableOfNewBalances.VATActivityType,
	|
	|	TableOfNewBalances.NewQuantityBalance AS CountBalance,
	|	TableOfNewBalances.AmountBalanceAtEndOfPeriod AS AmountBalanceAtEndOfPeriod,
	|	TableOfNewBalances.CountReceipt,
	|
	|	TableOfNewBalances.NewCostBalance                   AS CostBalance,
	|	TableOfNewBalances.NewValueWithoutVATBalance             AS CostExcludingVATBalance,
	|	TableOfNewBalances.NewValueOffBalanceBalance       AS OffBalanceCostBalance,
	|	TableOfNewBalances.NewValueLocalBalance               AS LocalCostBalance,
	|	TableOfNewBalances.NewValueOffBalanceSheetLocalBalance   AS OffBalanceCostLocalBalance,
	|	TableOfNewBalances.NewCostOfManBalance                AS CostManBalance,
	|
	|	TableOfNewBalances.NewValueAdditionalExpensesBalance         AS AdditionalExpenseCostBalance,
	|	TableOfNewBalances.NewValueAdditionalExpensesWithoutVATBalance   AS AdditionalExpensesCostExcludingVATBalance,
	|	TableOfNewBalances.NewLaborCostBalance                AS LaborCostsBalance,
	|	TableOfNewBalances.NewArticleByArticleConstantsWithVAT   AS ItemizedFixedCostsIncludingVATBalance,
	|	TableOfNewBalances.NewArticleByArticlePermanentWithoutVATBalance AS ItemizedFixedCostsExcludingVATBalance,
	|	TableOfNewBalances.NewArticleByArticleVariablesWithVATRemainder   AS ItemizedVariableCostsIncludingVATBalance,
	|	TableOfNewBalances.NewArticleByArticleVariablesExcludingVATBalance AS ItemizedVariableCostsExcludingVATBalance,
	|
	|	TableOfNewBalances.NewLocalBalanceSupplement              AS AddExpensesLocalBalance,
	|	TableOfNewBalances.NewLaborCostsLocalBalance            AS LaborCostsLocalBalance,
	|	TableOfNewBalances.NewArticleByArticlePermanentLocalRemainder   AS ItemizedFixedCostsComplBalance,
	|	TableOfNewBalances.NewArticleByArticleVariablesLocalRemainder   AS ItemizedVariableCostsComplBalance,
	|
	|	TableOfNewBalances.NewSupplementManBalance               AS AddExpensesManBalance,
	|	TableOfNewBalances.NewLaborCostsManBalance             AS LaborCostsManBalance,
	|	TableOfNewBalances.NewArticleByArticlePermanentMan    AS ItemizedFixedCostsManagBalance,
	|	TableOfNewBalances.NewArticleByArticleVariablesOfMan    AS ItemizedVariableCostsManagBalance
	|
	|INTO BalanceTable
	|FROM
	|	TableOfNewBalances AS TableOfNewBalances
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TableOfNewBalances
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT TOP 1
	|	1
	|FROM
	|	TableOfBatchPeriods AS TableOfBatchPeriods
	|";
	
	While True Do 
		
		// The maximum number of request executions = the maximum number of product receipts to the warehouse.
		QueryResult = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True);
		
		If QueryResult.IsEmpty() Then
			Break;
		EndIf;
		
		CostCalculationProtocol.IncreaseAmountOfProcessedDataForMeasurement(
			CalculationParameters,
			CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters, "BalanceTable"));
		
	EndDo;

	// The number and cost of external arrivals to the node are adjusted.
	Query.Text = "
	|DROP TableOfBatchPeriods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TableAdjustmentNodes.NodeNumber                  AS NodeNumber,
	|	TableAdjustmentNodes.Organization                AS Organization,
	|	TableAdjustmentNodes.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableAdjustmentNodes.AccountingSection                AS AccountingSection,
	|	TableAdjustmentNodes.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableAdjustmentNodes.Lot                     AS Lot,
	|	TableAdjustmentNodes.LotVendorAttributes       AS LotVendorAttributes,
	|	TableAdjustmentNodes.FinancialAccountingDimension  AS FinancialAccountingDimension,
	|	TableAdjustmentNodes.VATActivityType         AS VATActivityType,
	|
	|	(CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.Count
	|		ELSE TableAdjustmentNodes.Count
	|		 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|		 + ISNULL(BalanceTable.CountBalance, 0) END) AS Count,
	|	TableAdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS QuantityIsWrittenOffAtFixedCost,
	|
	// Resources for calculating the cost of goods of the enterprise.
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.Cost
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.Cost - ISNULL(BalanceTable.CostBalance, 0) 
	|	END                                 AS Cost,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.CostExcludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.CostExcludingVAT - ISNULL(BalanceTable.CostExcludingVATBalance, 0) 
	|	END                                 AS CostExcludingVAT,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.OffBalanceCost
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.OffBalanceCost - ISNULL(BalanceTable.OffBalanceCostBalance, 0) 
	|	END                                 AS OffBalanceCost,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.AddExpensesForGoods
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.Cost - ISNULL(BalanceTable.CostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.AddExpensesForGoods - ISNULL(BalanceTable.AdditionalExpenseCostBalance, 0) 
	|	END                                 AS AddExpensesForGoods,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.AdditionalExpensesExcludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostExcludingVAT - ISNULL(BalanceTable.CostExcludingVATBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.AdditionalExpensesExcludingVAT - ISNULL(BalanceTable.AdditionalExpensesCostExcludingVATBalance, 0)
	|	END                                 AS AdditionalExpensesExcludingVAT,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.LaborCosts
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.Cost - ISNULL(BalanceTable.CostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.LaborCosts - ISNULL(BalanceTable.LaborCostsBalance, 0) 
	|	END                                 AS LaborCosts,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedFixedCostsIncludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.Cost - ISNULL(BalanceTable.CostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedFixedCostsIncludingVAT - ISNULL(BalanceTable.ItemizedFixedCostsIncludingVATBalance, 0)
	|	END                                 AS ItemizedFixedCostsIncludingVAT,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedFixedCostsExcludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostExcludingVAT - ISNULL(BalanceTable.CostExcludingVATBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedFixedCostsExcludingVAT - ISNULL(BalanceTable.ItemizedFixedCostsExcludingVATBalance, 0)
	|	END                                 AS ItemizedFixedCostsExcludingVAT,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedVariableCostsIncludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.Cost - ISNULL(BalanceTable.CostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedVariableCostsIncludingVAT - ISNULL(BalanceTable.ItemizedVariableCostsIncludingVATBalance, 0)
	|	END                                 AS ItemizedVariableCostsIncludingVAT,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedVariableCostsExcludingVAT
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostExcludingVAT - ISNULL(BalanceTable.CostExcludingVATBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedVariableCostsExcludingVAT - ISNULL(BalanceTable.ItemizedVariableCostsExcludingVATBalance, 0)
	|	END                                 AS ItemizedVariableCostsExcludingVAT,
	|
	// Resources for calculating the cost of goods of organizations (regulated accounting).
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.LocalCost
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.LocalCost - ISNULL(BalanceTable.LocalCostBalance, 0)
	|	END                                 AS LocalCost,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.OffBalanceCostLocal
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.OffBalanceCostLocal - ISNULL(BalanceTable.OffBalanceCostLocalBalance, 0) 
	|	END                                 AS OffBalanceCostLocal,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.AddExpensesLocal
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.LocalCost - ISNULL(BalanceTable.LocalCostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.AddExpensesLocal - ISNULL(BalanceTable.AddExpensesLocalBalance, 0)
	|	END                                 AS AddExpensesLocal,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.LaborCostsLocal
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.LocalCost - ISNULL(BalanceTable.LocalCostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.LaborCostsLocal - ISNULL(BalanceTable.LaborCostsLocalBalance, 0)
	|	END                                 AS LaborCostsLocal,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedFixedCostsCompl
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.LocalCost - ISNULL(BalanceTable.LocalCostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedFixedCostsCompl - ISNULL(BalanceTable.ItemizedFixedCostsComplBalance, 0)
	|	END                                 AS ItemizedFixedCostsCompl,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedVariableCostsCompl
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.LocalCost - ISNULL(BalanceTable.LocalCostBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedVariableCostsCompl - ISNULL(BalanceTable.ItemizedVariableCostsComplBalance, 0)
	|	END                                 AS ItemizedVariableCostsCompl,
	|
	// Resources for calculating the cost of goods of organizations (management accounting).
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.CostMan
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0)
	|			 + ISNULL(BalanceTable.CountBalance, 0) = 0
	|			THEN 0
	|		ELSE
	|			TableAdjustmentNodes.CostMan - ISNULL(BalanceTable.CostManBalance, 0)
	|	END                                 AS CostMan,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.AddExpensesMan
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostMan - ISNULL(BalanceTable.CostManBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.AddExpensesMan - ISNULL(BalanceTable.AddExpensesManBalance, 0)
	|	END                                              AS AddExpensesMan,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.LaborCostsMan
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostMan - ISNULL(BalanceTable.CostManBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.LaborCostsMan - ISNULL(BalanceTable.LaborCostsManBalance, 0)
	|	END                                 AS LaborCostsMan,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedFixedCostsManag
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostMan - ISNULL(BalanceTable.CostManBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedFixedCostsManag - ISNULL(BalanceTable.ItemizedFixedCostsManagBalance, 0)
	|	END                                 AS ItemizedFixedCostsManag,
	|
	|	CASE
	|		WHEN ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = ISNULL(BalanceTable.CountReceipt, 0)
	|			THEN TableAdjustmentNodes.ItemizedVariableCostsManag
	|		WHEN TableAdjustmentNodes.Count
	|			 - ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) = 0
	|			THEN 0
	|		WHEN (TableAdjustmentNodes.CostMan - ISNULL(BalanceTable.CostManBalance, 0)) = 0
	|			AND ISNULL(BalanceTable.AmountBalanceAtEndOfPeriod, 0) <> 0
	|			THEN 0	
	|		ELSE
	|			TableAdjustmentNodes.ItemizedVariableCostsManag - ISNULL(BalanceTable.ItemizedVariableCostsManagBalance, 0)
	|	END                                 AS ItemizedVariableCostsManag
	|
	|INTO TTNodesAdjustmentTemporary
	|FROM
	|	TTAdjustmentNodes AS TableAdjustmentNodes
	|
	|		LEFT JOIN BalanceTable AS BalanceTable
	|		ON TableAdjustmentNodes.ItemsLocationAttributes   = BalanceTable.ItemsLocationAttributes
	|			AND TableAdjustmentNodes.AccountingSection               = BalanceTable.AccountingSection
	|			AND TableAdjustmentNodes.InventoryOwnerAttribute                = BalanceTable.InventoryOwnerAttribute
	|			AND TableAdjustmentNodes.Organization               = BalanceTable.Organization
	|			AND TableAdjustmentNodes.Lot 					 = BalanceTable.Lot
	|			AND TableAdjustmentNodes.LotVendorAttributes 	 = BalanceTable.LotVendorAttributes
	|			AND TableAdjustmentNodes.FinancialAccountingDimension = BalanceTable.FinancialAccountingDimension
	|			AND TableAdjustmentNodes.VATActivityType 		 = BalanceTable.VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTAdjustmentNodes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	T.NodeNumber AS NodeNumber,
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Lot AS Lot,
	|	T.LotVendorAttributes AS LotVendorAttributes,
	|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	T.VATActivityType AS VATActivityType,
	// Resources for calculating the cost of goods of the enterprise.
	|	T.Count                  AS Count,
	|	T.QuantityIsWrittenOffAtFixedCost AS QuantityIsWrittenOffAtFixedCost,
	|	T.Cost                   AS Cost,
	|	T.CostExcludingVAT             AS CostExcludingVAT,
	|	T.OffBalanceCost       AS OffBalanceCost,
	|	T.AddExpensesForGoods                  AS AddExpensesForGoods,
	|	T.AdditionalExpensesExcludingVAT            AS AdditionalExpensesExcludingVAT,
	|	T.LaborCosts                AS LaborCosts,
	|	T.ItemizedFixedCostsIncludingVAT   AS ItemizedFixedCostsIncludingVAT,
	|	T.ItemizedVariableCostsIncludingVAT   AS ItemizedVariableCostsIncludingVAT,
	|	T.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	T.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	// Resources for calculating the cost of goods of organizations.
	|	T.LocalCost               AS LocalCost,
	|	T.AddExpensesLocal              AS AddExpensesLocal,
	|	T.OffBalanceCostLocal   AS OffBalanceCostLocal,
	|	T.LaborCostsLocal            AS LaborCostsLocal,
	|	T.CostMan                AS CostMan,
	|	T.AddExpensesMan               AS AddExpensesMan,
	|	T.LaborCostsMan             AS LaborCostsMan,
	|	T.ItemizedFixedCostsCompl   AS ItemizedFixedCostsCompl,
	|	T.ItemizedVariableCostsCompl   AS ItemizedVariableCostsCompl,
	|	T.ItemizedFixedCostsManag    AS ItemizedFixedCostsManag,
	|	T.ItemizedVariableCostsManag    AS ItemizedVariableCostsManag
	|
	|INTO TTAdjustmentNodes
	|FROM
	|	TTNodesAdjustmentTemporary AS T
	|INDEX BY
	|	Organization,
	|	ItemsLocationAttributes,
	|	AccountingSection,
	|	InventoryOwnerAttribute,
	|	Lot,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP TTNodesAdjustmentTemporary
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP BalanceTable
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"ServiceNodesMaterialAndLaborCosts, ServiceConnectionsMaterialAndLaborCosts");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextForSolvingFIFOSLEWeighted(CalculationParameters));
		
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function QueryTextForSolvingFIFOSLEWeighted(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextServiceNodesMaterialAndLaborCosts());
	QueriesTexts.Add(CommunicationTextSLU_MaterialAndLaborCosts());
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region StageProcedures_PreparingDataToSolveSLAAdditionalCosts

// Stage " Preparation of the data for the resolution of the service_additional expenses"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparingDataToSolveCaseAdditionalCosts(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataToSolveCaseAdditionalCosts");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"AdditionalCostAdjustmentNodes,
		|TTCostOfGoodsWriteOff,
		|ConnectionsOfAdditionalExpenseNodesWithRecorder,
		|ConnectionsOfNodesOfAdditionalExpenses,
		|ConnectionsOfNodesOfProductionExpensesOfPreviousPeriods,
		|InitialCostOfAdditionalExpenses,
		|ServiceNodesAdditionalCosts,
		|SLEConnections_AdditionalCosts");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextToSolveSLU_AdditionalCosts(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function TextToSolveSLU_AdditionalCosts(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(CostCalculationCostAdjustment.TextOfAmountOfOtherExpenses(CalculationParameters));
	QueriesTexts.Add(TextForAdjustingAdditionalCosts());
	QueriesTexts.Add(TextTTCostOfGoodsWriteOff());
	QueriesTexts.Add(TextOfConnectionOfAdditionalCostNodesWithRecorder()); // Uses the highest value of a product description
	QueriesTexts.Add(CommunicationTextForAdditionalCosts());
	QueriesTexts.Add(TextOfConnectionOfNodesOfProductionCostsOfPastPeriods());
	QueriesTexts.Add(TextInitialCostOfAdditionalExpenses()); // TT Of the initial cost of additional expenses
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextForAdjustingAdditionalCosts()
	
	QueryText =
		"SELECT
		|	MAX(T.NodeNumber) AS NodeNumber
		|INTO MaximumProductNodeNumbers
		|FROM
		|	TTAdjustmentNodes AS T
		|;
		|
		|SELECT
		|	RECORDAUTONUMBER() AS NodeNumber,
		|	Source.Organization,
		|	Source.Department,
		|	Source.ExpenseItem,
		|	Source.DimensionOfExpenses,
		|	Source.LineOfBusiness,
		|	Source.ReceiptPeriod,
		|	Source.WeightWithVAT,
		|	Source.WeightWithoutVAT,
		|	Source.LocalWeight,
		|	Source.WeightTA,
		|	Source.ManSWeight,
		|	Source.NDTWeight,
		|	Source.ManagementAccounting,
		|	Source.LocalAccounting,
		|	Source.TaxAccounting,
		|	Source.AIT
		|INTO AdditionalCostAdjustmentNodesPreliminary
		|FROM
		|	(SELECT
		|		Attributes.Organization,
		|		Attributes.Department,
		|		Attributes.ExpenseItem,
		|		Attributes.DimensionOfExpenses,
		|		Attributes.LineOfBusiness,
		|		MIN(Source.ReceiptPeriod) AS ReceiptPeriod,
		|		SUM(CASE
		|			WHEN Attributes.ManagementAccounting
		|				THEN Source.CostShare
		|			ELSE 0 END) AS WeightWithVAT,
		|		SUM(CASE
		|			WHEN Attributes.ManagementAccounting
		|				THEN Source.ShareOfValueWithoutVAT
		|			ELSE 0 END) AS WeightWithoutVAT,
		|		SUM(CASE
		|			WHEN Attributes.LocalAccounting
		|				THEN Source.ShareOfLocalValue
		|			ELSE 0 END) AS LocalWeight,
		// The TA weight should be filled in if the document is reflected in tax accounting or accounting,
		// because for expenses not accepted for tax accounting, the Tax accounting feature in the document will be turned off,
		// and the permanent difference will have to be distributed along with the amount of Local accounting.  
		|		SUM(CASE
		|			WHEN Attributes.TaxAccounting
		|			 OR Attributes.LocalAccounting
		|				THEN Source.ShareValueTa
		|			ELSE 0 END) AS WeightTA,
		|		SUM(CASE
		|			WHEN Attributes.ManagementAccounting
		|				THEN Source.ShareOfManSCost
		|			ELSE 0 END) AS ManSWeight,
		|		SUM(CASE
		|			WHEN Attributes.AIT
		|				THEN Source.ShareOfCostOfPersonalIncomeTax
		|			ELSE 0 END) AS NDTWeight,
		|		MAX(Attributes.ManagementAccounting) AS ManagementAccounting,
		|		MAX(Attributes.LocalAccounting) AS LocalAccounting,
		|		MAX(Attributes.TaxAccounting) AS TaxAccounting,
		|		MAX(Attributes.AIT) AS AIT
		|	FROM
		|		SharesOfAdditionalExpenses AS Source
		|
		|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|			ON Source.Recorder = Attributes.Ref
		|
		|	GROUP BY
		|		Attributes.Organization,
		|		Attributes.Department,
		|		Attributes.ExpenseItem,
		|		Attributes.DimensionOfExpenses,
		|		Attributes.LineOfBusiness) AS Source
		|;
		|
		|SELECT
		|	Source.NodeNumber + ISNULL(NodeNumbers.NodeNumber, 0) AS NodeNumber,
		|	Source.Organization,
		|	Source.Department,
		|	Source.ExpenseItem,
		|	Source.DimensionOfExpenses,
		|	Source.LineOfBusiness,
		|	Source.ReceiptPeriod,
		|	Source.WeightWithVAT,
		|	Source.WeightWithoutVAT,
		|	Source.LocalWeight,
		|	Source.WeightTA,
		|	Source.ManSWeight,
		|	Source.NDTWeight,
		|	(CASE
		|		WHEN Source.ManagementAccounting
		|			THEN ISNULL(ManSExpenses_.Sum, 0)
		|		ELSE 0 END) AS CostInclVAT,
		|	(CASE
		|		WHEN Source.ManagementAccounting
		|			THEN ISNULL(ManSExpenses_.AmountExcludingVAT, 0)
		|		ELSE 0 END) AS CostExcludingVAT,
		|	(CASE
		|		WHEN Source.ManagementAccounting
		|			THEN ISNULL(ManSExpenses_.SumMan, 0)
		|		ELSE 0 END) AS CostMan,
		|	(CASE
		|		WHEN Source.LocalAccounting
		|			THEN ISNULL(LocalExpenditureAmounts.SumCompl, 0)
		|		ELSE 0 END) AS LocalCost,
		|	CASE
		|		WHEN Source.LocalAccounting
		|			THEN ISNULL(LocalExpenditureAmounts.PermanentDifference, 0)
		|		ELSE 0 END AS PermanentDifference,
		|	CASE
		// When Local accounting is disabled, the tax accounting flag may not be set in the distribution documents.
		|		WHEN NOT &UseLocal OR Source.TaxAccounting
		|			THEN ISNULL(AmountOfExpensesTA.SumCompl, 0) - ISNULL(AmountOfExpensesTA.PermanentDifference, 0) - ISNULL(AmountOfExpensesTA.CostTD, 0)
		|		ELSE 0 END AS CostInTaxAccounting,
		|	ISNULL(LocalExpenditureAmounts.AITAmount, 0) AS CostOfPersonalIncomeTax
		|INTO AdditionalCostAdjustmentNodes
		|FROM
		|	AdditionalCostAdjustmentNodesPreliminary AS Source
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = Source.ExpenseItem
		|
		|		LEFT JOIN MaximumProductNodeNumbers AS NodeNumbers
		|		ON TRUE
		|
		|		LEFT JOIN ExpenseAmounts AS ManSExpenses_
		|		ON ManSExpenses_.Organization = Source.Organization
		|			AND ManSExpenses_.ExpenseItem = Source.ExpenseItem
		|			AND ManSExpenses_.DimensionOfExpenses = Source.DimensionOfExpenses
		|			AND ManSExpenses_.Department = Source.Department
		|			AND ManSExpenses_.LineOfBusiness = Source.LineOfBusiness
		|			AND ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|
		|		LEFT JOIN ExpenseAmounts AS LocalExpenditureAmounts
		|		ON LocalExpenditureAmounts.Organization = Source.Organization
		|			AND LocalExpenditureAmounts.ExpenseItem = Source.ExpenseItem
		|			AND LocalExpenditureAmounts.DimensionOfExpenses = Source.DimensionOfExpenses
		|			AND LocalExpenditureAmounts.Department = Source.Department
		|			AND LocalExpenditureAmounts.LineOfBusiness = Source.LineOfBusiness
		|			AND ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|
		|		LEFT JOIN ExpenseAmounts AS AmountOfExpensesTA
		|		ON AmountOfExpensesTA.Organization = Source.Organization
		|			AND AmountOfExpensesTA.ExpenseItem = Source.ExpenseItem
		|			AND AmountOfExpensesTA.DimensionOfExpenses = Source.DimensionOfExpenses
		|			AND AmountOfExpensesTA.Department = Source.Department
		|			AND AmountOfExpensesTA.LineOfBusiness = Source.LineOfBusiness
		|			AND ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToInventoryCost)";
		
	Return QueryText;
	
EndFunction

// Text description of the data for the TT node correctingadditional expenses.
// 
// Returns:
//  String - Text description of the data for the TT node correctingadditional expenses.
Function TextDescriptionOfDataForAdditionalCostAdjustmentNodes() Export
	
	QueryText = "SELECT TOP 0
		|	0																AS NodeNumber,
		|	VALUE(Catalog.Companies.EmptyRef)					AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef)			AS Department,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItem,
		|	UNDEFINED													AS DimensionOfExpenses,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef)		AS LineOfBusiness,
		|	0 AS WeightWithVAT,
		|	0 AS WeightWithoutVAT,
		|	0 AS LocalWeight,
		|	0 AS WeightTA,
		|	0 AS ManSWeight,
		|	0 AS NDTWeight,
		|	0 AS CostInclVAT,
		|	0 AS CostExcludingVAT,
		|	0 AS CostMan,
		|	0 AS LocalCost,
		|	0 AS PermanentDifference,
		|	0 AS CostInTaxAccounting,
		|	0 AS CostOfPersonalIncomeTax
		|INTO Data
		|"; 
		
		QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
EndFunction

Function TextTTCostOfGoodsWriteOff()
	Return "
		|SELECT
		|	SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	Cost_.Organization AS Organization,
		|	Cost_.AccountingSection AS AccountingSection,
		|	ISNULL(OrganizationCor.Ref, Cost_.Organization) AS CorCompany,
		|	Cost_.Department AS Department,
		|	Cost_.CorLineOfBusiness AS CorLineOfBusiness,
		|	CAST(Cost_.ExpenseItemOfWriteOff AS ChartOfCharacteristicTypes.ExpenseItems) AS ExpenseItemOfWriteOff,
		|	Cost_.DimensionOfExpenses AS DimensionOfExpenses,
		|	Cost_.BusinessOperation AS BusinessOperation,
		|	Cost_.OfficialTypeOfMovementParish AS OfficialTypeOfMovementParish,
		|	SUM(Cost_.Count) AS Count
		|
		|INTO TTCostOfGoodsWriteOff
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|	INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|	ON SourceAdjustmentNodes.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
		|		AND SourceAdjustmentNodes.AccountingSection               = Cost_.AccountingSection
		|		AND SourceAdjustmentNodes.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
		|		AND SourceAdjustmentNodes.Organization               = Cost_.Organization
		|		AND SourceAdjustmentNodes.Lot                    = Cost_.Lot
		|		AND SourceAdjustmentNodes.LotVendorAttributes      = Cost_.LotVendorAttributes
		|		AND SourceAdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|		AND SourceAdjustmentNodes.VATActivityType        = Cost_.VATActivityType
		|
		|	LEFT JOIN Catalog.Companies AS OrganizationCor
		|		ON OrganizationCor.Ref = Cost_.CorCompany
		|
		|WHERE
		// The selection conditions must match the function of the textcommunication of additional spending nodes().
		|	(Cost_.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
		|	 OR Cost_.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand),
		|		VALUE(Enum.BusinessTransactions.GoodsConsumption),
		|		VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller),
		|		VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
		|		VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses),
		|		VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
		|		VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction),
		|		VALUE(Enum.BusinessTransactions.ProductionCostsReverseTransaction),
		|		VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase),
		|		VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		VALUE(Enum.BusinessTransactions.TransferToFixedAssets),
		|		VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD),
		|		VALUE(Enum.BusinessTransactions.TransferToOperation),
		|		VALUE(Enum.BusinessTransactions.CommissioningACAndTA),
		|		VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)))
		// The exception is the cancellation of expenses with the return of the previous period, because the cost is calculated at the step of adjusting the cost of the returns of the past periods
		|	AND NOT (Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction) 
		|		AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn))
		|	AND NOT (
		|		Cost_.ReversingEntry AND Cost_.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections), 
		|			VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|		))
		// We will exclude issues at a fixed cost with write-off for expenses because their cost has already been recorded in the register of other expenses
		|	AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
		|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|GROUP BY
		|	SourceAdjustmentNodes.NodeNumber,
		|	Cost_.Organization,
		|	Cost_.AccountingSection,
		|	ISNULL(OrganizationCor.Ref, Cost_.Organization),
		|	Cost_.Department,
		|	Cost_.CorLineOfBusiness,
		|	CAST(Cost_.ExpenseItemOfWriteOff AS ChartOfCharacteristicTypes.ExpenseItems),
		|	Cost_.DimensionOfExpenses,
		|	Cost_.BusinessOperation,
		|	Cost_.OfficialTypeOfMovementParish
		|
		|INDEX BY
		|	Organization, ExpenseItemOfWriteOff, DimensionOfExpenses
		|";
	
EndFunction

Function TextOfConnectionOfAdditionalCostNodesWithRecorder() // Uses the highest value of a product description
	Return 
		"SELECT
		|	Cost_.Recorder          AS Recorder,
		|	Cost_.SourceNodeNumber    AS SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber    AS ReceiverNodeNumber,
		|	SUM(Cost_.ArcWeightWithVAT)   AS ArcWeightWithVAT,
		|	SUM(Cost_.ArcWeightWithoutVAT) AS ArcWeightWithoutVAT,
		|	SUM(Cost_.ArcWeightLocal)   AS ArcWeightLocal,
		|	SUM(Cost_.WeightOfArcISTA)     AS WeightOfArcISTA,
		|	SUM(Cost_.ArcWeightNDD)    AS ArcWeightNDD,
		|	SUM(Cost_.ArcWeightMan)    AS ArcWeightMan,
		|	MAX(Cost_.RestoreReserves)    AS RestoreReserves,
		|	MAX(Cost_.AcceptedVNU)            AS AcceptedVNU,
		|	MAX(Cost_.NotDistributedInBuhAccounting) AS NotDistributedInBuhAccounting,
		|	MAX(Cost_.NotDistributedInNalAccounting) AS NotDistributedInNalAccounting,
		|	MAX(Cost_.SourceOnMediumSlip) AS SourceOnMediumSlip
		|
		|INTO ConnectionsOfAdditionalExpenseNodesWithRecorder
		|FROM (
		// Write-off of materials for additional expenses
		// The conditions for filling in the indicators of the weight arc must correspond to the functions
		// textvtablitablesvyazationstateinesreferences() #The area of the textsquestionmaterialstatistics.
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Cost_.SourceNodeNumber  AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber  AS ReceiverNodeNumber,
		|		(CASE
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionManag
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS ArcWeightWithVAT,
		|		(CASE
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionManag
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS ArcWeightWithoutVAT,
		|		(CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of sales 
		// , the item-by-item Local expenses are not taken into account in the cost of other expenses. 
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionLocal
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			OR Cost_.BusinessOperation = 
		|				VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS ArcWeightLocal,
		|		(CASE
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionTax
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			OR Cost_.BusinessOperation = 
		|				VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS WeightOfArcISTA,
		|		(CASE
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionTax
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			OR Cost_.BusinessOperation = 
		|				VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS ArcWeightNDD,
		|		(CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of goods sold 
		// , item-by-item expenses of the Man are not taken into account in the cost of other expenses. 
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|			WHEN Cost_.ExpenseItemOfWriteOff.CostAllocationOptionManag
		|			 <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			OR Cost_.BusinessOperation = 
		|				VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS ArcWeightMan,
		// The conditions for the formation of the Restore Reserves field must correspond to the conditions for the formation of a similar field
		// in the procedure for correcting the cost of writing reserves() #The area of the correction table.
		|		(CASE
		|			WHEN Cost_.Organization IN (&CompaniesWithRestorationOfReservesWhenInventoryWriteOffForExpenses)
		|				THEN TRUE
		|			ELSE FALSE END) AS RestoreReserves,
		|	ISNULL(Cost_.ExpenseItemOfWriteOff.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|	(CASE
		|		WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
		|			THEN TRUE
		|		ELSE FALSE END)
		|		OR ISNULL(ItemsOfExpensesWriteOffs.CostAllocationOptionLocal, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInBuhAccounting,
		|	ISNULL(ItemsOfExpensesWriteOffs.CostAllocationOptionTax, 
		|		VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|		VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|		VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|		VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|		VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInNalAccounting,
		// For sources with the "Medium-slip" cost estimation method, connections between nodes are excluded when calculating the service, because
		// with medium-slip, the cost is calculated when carrying out documents.
		// In addition to the "Output" section of accounting, the actual cost is always calculated using it for any valuation method.
		|		(CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|				THEN TRUE
		|			ELSE FALSE END) AS SourceOnMediumSlip
		|	FROM
		|		TTCostOfGoodsWriteOff AS Cost_
		|
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		LEFT JOIN Catalog.Companies AS OrganizationCor
		|		ON OrganizationCor.Ref = Cost_.CorCompany
		|
		|		INNER JOIN AdditionalCostAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ExpenseItem               = Cost_.ExpenseItemOfWriteOff
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses         = Cost_.DimensionOfExpenses
		|			AND AdjustmentNodesReceiver.LineOfBusiness   = Cost_.CorLineOfBusiness
		|			AND AdjustmentNodesReceiver.Department             = Cost_.Department
		|			AND AdjustmentNodesReceiver.Organization               = ISNULL(OrganizationCor.Ref, Cost_.Organization)
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ItemsOfExpensesWriteOffs
		|			ON ItemsOfExpensesWriteOffs.Ref = Cost_.ExpenseItemOfWriteOff
		|
		|	UNION ALL
		|
		// Distribution of additional costs for goods
		|	SELECT
		|		Shares.Recorder AS Recorder,
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.CostShare
		|			ELSE 0 END) AS ArcWeightWithVAT,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.ShareOfValueWithoutVAT
		|			ELSE 0 END) AS ArcWeightWithoutVAT,
		|		(CASE
		|			WHEN Attributes.LocalAccounting THEN Shares.ShareOfLocalValue
		|			ELSE 0 END) AS ArcWeightLocal,
		|		(CASE
		|			WHEN Attributes.TaxAccounting THEN Shares.ShareValueTa
		|			ELSE 0 END) AS WeightOfArcISTA,
		|		(CASE
		|			WHEN Attributes.AIT THEN Shares.ShareOfCostOfPersonalIncomeTax
		|			ELSE 0 END) AS ArcWeightNDD,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.ShareOfManSCost
		|			ELSE 0 END) AS ArcWeightMan,
		|		FALSE AS RestoreReserves,
		|		ISNULL(Attributes.ExpenseItem.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		Attributes.TaxAccounting
		|			AND NOT Attributes.LocalAccounting AS NotDistributedInBuhAccounting,
		|		Attributes.LocalAccounting
		|			AND NOT Attributes.TaxAccounting AS NotDistributedInNalAccounting,
		// For sources with the "Medium-slip" cost estimation method, connections between nodes are excluded when calculating the service, because
		// with medium-slip, the cost of distributed additional expenses is reflected in the register "Deviations in the cost of goods".
		|		(CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|				THEN TRUE
		|			ELSE FALSE END) AS SourceOnMediumSlip
		|	FROM
		|		SharesOfAdditionalExpenses AS Shares
		|
		|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|			ON Shares.Recorder = Attributes.Ref
		|
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|			ON Attributes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|			INNER JOIN AdditionalCostAdjustmentNodes AS SourceAdjustmentNodes
		|			ON Attributes.ExpenseItem = SourceAdjustmentNodes.ExpenseItem
		|				AND Attributes.DimensionOfExpenses = SourceAdjustmentNodes.DimensionOfExpenses
		|				AND Attributes.LineOfBusiness = SourceAdjustmentNodes.LineOfBusiness
		|				AND Attributes.Department = SourceAdjustmentNodes.Department
		|				AND Attributes.Organization = SourceAdjustmentNodes.Organization
		|
		|			INNER JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|			ON AdjustmentNodesReceiver.ItemsLocationAttributes
		|					= Shares.CorItemsLocationAttributes
		|				AND AdjustmentNodesReceiver.AccountingSection               = Shares.CorAccountingSection
		|				AND AdjustmentNodesReceiver.Organization               = Shares.CorCompany
		|				AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Shares.CorInventoryOwnerAttribute
		|				AND (AdjustmentNodesReceiver.Lot                   = Shares.CorLot
		|					OR &ScheduledJob)
		|				AND (AdjustmentNodesReceiver.LotVendorAttributes     = Shares.LotVendorAttributesCorr
		|					OR &ScheduledJob)
		|				AND (AdjustmentNodesReceiver.FinancialAccountingDimension = Shares.CorControllingAttributes
		|					OR &ScheduledJob)
		|				AND (AdjustmentNodesReceiver.VATActivityType       = Shares.CorVATActivityTypes
		|					OR &ScheduledJob)
		|	WHERE
		|		(Shares.BusinessOperation = UNDEFINED
		|			AND Shares.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|			OR Shares.EntryType <> VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods))
		|
		|	UNION ALL
		|
		// Allocation of additional expenses to other items of additional expenses.
		|	SELECT
		|		Shares.Recorder AS Recorder,
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.CostShare
		|			ELSE 0 END) AS ArcWeightWithVAT,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.ShareOfValueWithoutVAT
		|			ELSE 0 END) AS ArcWeightWithoutVAT,
		|		(CASE
		|			WHEN Attributes.LocalAccounting THEN Shares.ShareOfLocalValue
		|			ELSE 0 END) AS ArcWeightLocal,
		|		(CASE
		|			WHEN Attributes.TaxAccounting THEN Shares.ShareValueTa
		|			ELSE 0 END) AS WeightOfArcISTA,
		|		(CASE
		|			WHEN Attributes.AIT THEN Shares.ShareOfCostOfPersonalIncomeTax
		|			ELSE 0 END) AS ArcWeightNDD,
		|		(CASE
		|			WHEN Attributes.ManagementAccounting THEN Shares.ShareOfManSCost
		|			ELSE 0 END) AS ArcWeightMan,
		|		FALSE AS RestoreReserves,
		|		ISNULL(Attributes.ExpenseItem.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		Attributes.TaxAccounting
		|			AND NOT Attributes.LocalAccounting AS NotDistributedInBuhAccounting,
		|		Attributes.LocalAccounting
		|			AND NOT Attributes.TaxAccounting AS NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		SharesOfAdditionalExpenses AS Shares
		|
		|		INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|		ON Shares.Recorder = Attributes.Ref
		|
		|		INNER JOIN AdditionalCostAdjustmentNodes AS SourceAdjustmentNodes
		|		ON Attributes.ExpenseItem = SourceAdjustmentNodes.ExpenseItem
		|			AND Attributes.DimensionOfExpenses = SourceAdjustmentNodes.DimensionOfExpenses
		|			AND Attributes.LineOfBusiness = SourceAdjustmentNodes.LineOfBusiness
		|			AND Attributes.Department = SourceAdjustmentNodes.Department
		|			AND Attributes.Organization = SourceAdjustmentNodes.Organization
		|
		|		INNER JOIN AdditionalCostAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ExpenseItem = Shares.CorExpenseItem
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses = Shares.CorExpenditureDimension
		|			AND AdjustmentNodesReceiver.LineOfBusiness = Shares.CorLineOfBusiness
		|			AND AdjustmentNodesReceiver.Department = Shares.DebitBusinessUnit
		|			AND AdjustmentNodesReceiver.Organization = Shares.CorCompany
		|	WHERE
		|		Shares.BusinessOperation = VALUE(Enum.BusinessTransactions.VATIsAccruedByTaxAgent)
		|		OR Shares.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)
		|
		|	) AS Cost_
		|GROUP BY
		|	Cost_.Recorder,
		|	Cost_.SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber
		|";
EndFunction

Function CommunicationTextForAdditionalCosts() // Uses node connectionsadditional spending by the registrar
	Return "
		|SELECT
		|	Links.SourceNodeNumber    AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber    AS ReceiverNodeNumber,
		|	SUM(Links.ArcWeightWithVAT)   AS ArcWeightWithVAT,
		|	SUM(Links.ArcWeightWithoutVAT) AS ArcWeightWithoutVAT,
		|	SUM(Links.ArcWeightLocal)   AS ArcWeightLocal,
		|	SUM(Links.WeightOfArcISTA)     AS WeightOfArcISTA,
		|	SUM(Links.ArcWeightNDD)    AS ArcWeightNDD,
		|	SUM(Links.ArcWeightMan)    AS ArcWeightMan,
		|	MAX(Links.RestoreReserves)    AS RestoreReserves,
		|	MAX(Links.AcceptedVNU)            AS AcceptedVNU,
		|	MAX(Links.NotDistributedInBuhAccounting) AS NotDistributedInBuhAccounting,
		|	MAX(Links.NotDistributedInNalAccounting) AS NotDistributedInNalAccounting,
		|	MAX(Links.SourceOnMediumSlip) AS SourceOnMediumSlip
		|
		|INTO ConnectionsOfNodesOfAdditionalExpenses
		|FROM
		|	ConnectionsOfAdditionalExpenseNodesWithRecorder AS Links
		|GROUP BY
		|	Links.SourceNodeNumber,
		|	Links.ReceiverNodeNumber
		|";
EndFunction

// Text description of data for TT communication nodesadditional expenses.
// 
// Returns:
//  String - Text description of data for TT communication nodesadditional expenses.
Function TextDescriptionOfDataForLinksOfAdditionalCostNodes() Export
	
	QueryText = "SELECT TOP 0
		|	0 AS SourceNodeNumber,
		|	0 AS ReceiverNodeNumber,
		|	0 AS ArcWeightWithVAT,
		|	0 AS ArcWeightWithoutVAT,
		|	0 AS ArcWeightLocal,
		|	0 AS WeightOfArcISTA,
		|	0 AS ArcWeightNDD,
		|	0 AS ArcWeightMan,
		|	FALSE AS RestoreReserves,
		|	FALSE AS AcceptedVNU,
		|	FALSE AS NotDistributedInBuhAccounting,
		|	FALSE AS NotDistributedInNalAccounting
		|INTO Data
		|"; 
		
		QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
EndFunction

Function TextOfConnectionOfNodesOfProductionCostsOfPastPeriods()
	Return 
		"SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		Shares.CorCompany					AS Organization,
		|		Shares.DebitBusinessUnit				AS Department,
		|		Shares.CorExpenseItem				AS ExpenseItem,
		|		Shares.CorExpenditureDimension			AS DimensionOfExpenses,
		|		Shares.CorLineOfBusiness		AS LineOfBusiness,
		|		Shares.CostShare                  AS ArcWeightWithVAT,
		|		Shares.ShareOfValueWithoutVAT            AS ArcWeightWithoutVAT,
		|		Shares.ShareOfLocalValue              AS ArcWeightLocal,
		|		Shares.ShareValueTa                AS WeightOfArcISTA,
		|		Shares.ShareOfManSCost               AS ArcWeightMan,
		|		Shares.ShareOfCostOfPersonalIncomeTax               AS ArcWeightNDD
		|INTO ConnectionsOfNodesOfProductionExpensesOfPreviousPeriods
		|	FROM
		|		SharesOfAdditionalExpenses AS Shares
		|
		|			INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|			ON Shares.Recorder = Attributes.Ref
		|
		|			INNER JOIN AdditionalCostAdjustmentNodes AS SourceAdjustmentNodes
		|			ON Attributes.ExpenseItem = SourceAdjustmentNodes.ExpenseItem
		|				AND Attributes.DimensionOfExpenses = SourceAdjustmentNodes.DimensionOfExpenses
		|				AND Attributes.LineOfBusiness = SourceAdjustmentNodes.LineOfBusiness
		|				AND Attributes.Department = SourceAdjustmentNodes.Department
		|				AND Attributes.Organization = SourceAdjustmentNodes.Organization
		|
		|	WHERE
		|		Shares.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|		AND Shares.CorExpenseItem <> UNDEFINED
		|		AND Shares.EntryType = VALUE(Enum.LotRecordTypes.AllocationByDisposedGoods)";
EndFunction

// The text is a description of the data for TT communication nodes of the production costs of the past periods.
// 
// Returns:
//  String - The text is a description of the data for TT communication nodes of the production costs of the past periods.
Function TextDescriptionOfDataForConnectionsOfNodesOfProductionCostsOfPreviousPeriods() Export
	
	QueryText = "SELECT TOP 0
		|		0																AS SourceNodeNumber,
		|		VALUE(Catalog.Companies.EmptyRef)					AS Organization,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)			AS Department,
		|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItem,
		|		UNDEFINED													AS DimensionOfExpenses,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef)		AS LineOfBusiness,
		|		0 AS ArcWeightWithVAT,
		|		0 AS ArcWeightWithoutVAT,
		|		0 AS ArcWeightLocal,
		|		0 AS WeightOfArcISTA,
		|		0 AS ArcWeightMan,
		|		0 AS ArcWeightNDD
		|INTO Data
		|"; 
		
		QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
EndFunction

Function TextInitialCostOfAdditionalExpenses() // TT Of the initial cost of additional expenses
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		// With the cost estimation method, the "Medium-sliding" amount of expenses is already reflected in the "Other expenses" register and the initial cost
		// does not need to be calculated, except for the production of products with write-off for expenses.
		// The output of products with write-off to expenses is reflected in the accounting section "Output".
		|	CAST(SUM(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		ELSE ((ISNULL(CostOfBatchesOfGoods.Cost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0))
		|		* ISNULL(Links.ArcWeightWithVAT, 0)) END) AS NUMBER(28,10)) AS AdditionalExpensesIncludingVAT,
		|
		|	CAST(SUM(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		ELSE ((ISNULL(CostOfBatchesOfGoods.CostExcludingVAT, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0))
		|		* ISNULL(Links.ArcWeightWithoutVAT, 0)) END) AS NUMBER(28,10)) AS AdditionalExpensesExcludingVAT,
		|
		// With the cost estimation method, the "Average Sliding" amount of expenses is already reflected in the "Other expenses" register.
		// The initial cost should include the amount of the allowance for impairment, because the amount of the reserve is calculated at the close of the month 
		// Except for the production of products with a write-off for expenses. 
		// At the time of production, the amount of the reserve for impairment of inventories is written off to the cost of sales.
		|	CAST(SUM(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN (CASE WHEN NOT Links.RestoreReserves
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|			ELSE 0 END)
		|		ELSE ((ISNULL(CostOfBatchesOfGoods.LocalCost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsLocal, 0)
		|				+ (CASE WHEN NOT Links.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|					ELSE 0 END))
		|		* ISNULL(Links.ArcWeightLocal, 0)) END) AS NUMBER(28,10)) AS AddExpensesLocal,
		|
		|	CAST(SUM(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN (CASE WHEN NOT Links.RestoreReserves
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|			ELSE 0 END)
		|		ELSE ((ISNULL(CostOfBatchesOfGoods.CostMan, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsMan, 0)
		|				+ (CASE WHEN NOT Links.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|					ELSE 0 END))
		|		* ISNULL(Links.ArcWeightMan, 0)) END) AS NUMBER(28,10)) AS AddExpensesMan
		|
		|INTO InitialCostOfAdditionalExpenses
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|	LEFT JOIN ConnectionsOfNodesOfAdditionalExpenses AS Links
		|		ON AdjustmentNodes.NodeNumber = Links.ReceiverNodeNumber
		|
		|	LEFT JOIN TTValueOfBatchesOfGoods AS CostOfBatchesOfGoods
		|		ON CostOfBatchesOfGoods.NodeNumber = Links.SourceNodeNumber
		|
		|WHERE
		|	NOT Links.ReceiverNodeNumber IS NULL
		|	AND NOT Links.SourceNodeNumber IS NULL
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber
		|
		|INDEX BY
		|	NodeNumber
		|";
EndFunction

#EndRegion

#Region StageProcedures_DataPreparationForSLESolutionAdditionalCosts_NodesAndSLEConnections

Procedure PreparingDataForSolutionOfSLECase_AdditionalCosts_NodesAndConnections(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataForSolutionOfSLECase_AdditionalCosts_NodesAndConnections");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"DistributedAdditionalCosts, ServiceNodesAdditionalCosts, SLEConnections_AdditionalCosts");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextForSolvingCase_AdditionalCosts_NodesAndSLEConnections(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"InitialCostOfAdditionalExpenses");
	
EndProcedure

Function TextForSolvingCase_AdditionalCosts_NodesAndSLEConnections(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextDistributedAdditionalCosts()); // TT distributed Additional expenses
	QueriesTexts.Add(TextNodesSLU_AdditionalCosts()); // TT Nodal_additional Expenses
	QueriesTexts.Add(CommunicationText_AdditionalCosts()); // TT Connection_additional expenses
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextDistributedAdditionalCosts() // TT distributed Additional expenses
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|	Cost_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Cost_.ItemsLocationAttributes.Products AS Products,
		|	Cost_.Lot,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.AddExpensesForGoods
		|		ELSE -Cost_.AddExpensesForGoods END) AS AddExpensesForGoods,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.AdditionalExpensesExcludingVAT
		|		ELSE -Cost_.AdditionalExpensesExcludingVAT END) AS AdditionalExpensesExcludingVAT,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.AddExpensesLocal
		|		ELSE -Cost_.AddExpensesLocal END) AS AddExpensesLocal,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.PermanentDifference
		|		ELSE -Cost_.PermanentDifference END) AS PermanentDifference,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.CostTD
		|		ELSE -Cost_.CostTD END) AS CostTD,
		|	SUM(CASE WHEN Cost_.OfficialTypeOfMovementParish THEN Cost_.AddExpensesMan
		|		ELSE -Cost_.AddExpensesMan END) AS AddExpensesMan
		|
		|INTO DistributedAdditionalCosts
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|	INNER JOIN TTAdjustmentNodes AS AdjustmentNodes
		|		ON AdjustmentNodes.Organization = Cost_.Organization
		|		AND AdjustmentNodes.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|		AND AdjustmentNodes.AccountingSection = Cost_.AccountingSection
		|		AND AdjustmentNodes.InventoryOwnerAttribute = Cost_.InventoryOwnerAttribute
		|		AND AdjustmentNodes.Lot = Cost_.Lot
		|		AND AdjustmentNodes.LotVendorAttributes = Cost_.LotVendorAttributes
		|		AND AdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|		AND AdjustmentNodes.VATActivityType = Cost_.VATActivityType
		|WHERE
		|	Cost_.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND VALUETYPE(Cost_.Recorder) IN (
		|		TYPE(Document.AllocationOfOtherCosts),
		|		TYPE(Document.CostCalculationRecorder))
		|	AND NOT (VALUETYPE(Cost_.Recorder) = TYPE(Document.AllocationOfOtherCosts)
		|		AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost))
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.ItemsLocationAttributes.Products,
		|	Cost_.Lot
		|
		|INDEX BY
		|	NodeNumber
		|";
EndFunction

Function TextNodesSLU_AdditionalCosts() // TT Nodal_additional Expenses
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|
		|	AdjustmentNodes.CostInclVAT
		|		+ ISNULL(CostOfNodes.AdditionalExpensesIncludingVAT, 0)   AS CostInclVAT,
		|	AdjustmentNodes.CostExcludingVAT
		|		+ ISNULL(CostOfNodes.AdditionalExpensesExcludingVAT, 0) AS CostExcludingVAT,
		|	AdjustmentNodes.LocalCost
		|		+ ISNULL(CostOfNodes.AddExpensesLocal, 0)   AS LocalCost,
		|	AdjustmentNodes.CostMan
		|		+ ISNULL(CostOfNodes.AddExpensesMan, 0)    AS CostMan
		|
		|INTO ServiceNodesAdditionalCosts
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|
		|	LEFT JOIN InitialCostOfAdditionalExpenses AS CostOfNodes
		|		ON AdjustmentNodes.NodeNumber = CostOfNodes.NodeNumber
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber            AS NodeNumber,
		|	AdjustmentNodes.AddExpensesForGoods
		|		+ ISNULL(CostAdjustment.AddExpensesForGoods, 0) AS CostInclVAT,
		|	AdjustmentNodes.AdditionalExpensesExcludingVAT
		|		+ ISNULL(CostAdjustment.AdditionalExpensesExcludingVAT, 0) AS CostExcludingVAT,
		|	AdjustmentNodes.AddExpensesLocal
		|		+ ISNULL(CostAdjustment.AddExpensesLocal, 0) AS LocalCost,
		|	AdjustmentNodes.AddExpensesMan
		|		+ ISNULL(CostAdjustment.AddExpensesMan, 0) AS CostMan
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|	LEFT JOIN DistributedAdditionalCosts AS CostAdjustment
		|		ON CostAdjustment.NodeNumber = AdjustmentNodes.NodeNumber
		|";
EndFunction

Function CommunicationText_AdditionalCosts() // TT Connection_additional expenses
	Return "
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization AND WriteOffMovements.SourceOnMediumSlip THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightWithoutVAT,
		|
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(CASE
		|		WHEN WriteOffMovements.TransferToAnotherOrganization THEN 0
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightMan
		|
		|INTO SLEConnections_AdditionalCosts
		|FROM
		|	TTWriteOffs AS WriteOffMovements
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|	ON WriteOffMovements.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|		AND TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	Links.SourceNodeNumber AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(-Links.ArcWeightWithVAT AS NUMBER(28,10))   AS ArcWeightWithVAT,
		|	CAST(-Links.ArcWeightWithoutVAT AS NUMBER(28,10)) AS ArcWeightWithoutVAT,
		|	CAST(-Links.ArcWeightLocal AS NUMBER(28,10))   AS ArcWeightLocal,
		|	CAST(-Links.ArcWeightMan AS NUMBER(28,10))    AS ArcWeightMan
		|FROM
		|	ConnectionsOfNodesOfAdditionalExpenses AS Links
		|WHERE
		|	NOT Links.SourceOnMediumSlip
		|
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(AdjustmentNodes.Count AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|	CAST(AdjustmentNodes.Count AS NUMBER(28,10)) AS ArcWeightWithoutVAT,
		|	CAST(AdjustmentNodes.Count AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(AdjustmentNodes.Count AS NUMBER(28,10)) AS ArcWeightMan
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(AdjustmentNodes.WeightWithVAT AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|	CAST(AdjustmentNodes.WeightWithoutVAT AS NUMBER(28,10)) AS ArcWeightWithoutVAT,
		|	CAST(AdjustmentNodes.LocalWeight AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(AdjustmentNodes.ManSWeight AS NUMBER(28,10)) AS ArcWeightMan
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|";
EndFunction

#EndRegion

#Region StageProcedures_CalculationOfCostOfPastPeriods

// Calculation of deviations in cost and additional expenses based on past periods.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure CalculationOfCostOfPastPeriods(CalculationParameters)
	
	PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods(CalculationParameters);
	
	// Generates a temporary table:
	// - VtTablityResults_Past period
	SolveSLEPlatform_CalculationOfCostOfPastPeriods(CalculationParameters);
		
	CostCalculationCostAdjustment.AdjustCostOfPastPeriods(CalculationParameters);
	
	If CalculationParameters.BatchCalculationStarted Then
		
		// Return to the batch calculation mechanism from the cost calculation
		CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, False);
		
		// We will restore all settlement caches of balances and turnover for all organizations
		CostCalculationAppliedAlgorithms.UpdateCalculatedRegisterCaches_(CalculationParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StageProcedures_PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods

// The stage of "Preparing the data for the resolution of the_accounting_the cost of the past few periods"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	#Region MinimumPeriods
	
	Query.Text = TextMinimumPeriods();
	
	QueryResult = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True,, True);
	Selection = QueryResult.Select();
	
	BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	If Selection.Next() Then
		MinimumPeriod = ?(ValueIsFilled(Selection.MinimumPeriod), Selection.MinimumPeriod, BeginOfPeriod);
	Else
		MinimumPeriod = BeginOfPeriod; 
	EndIf;
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("MinimumPastPeriod", Min(MinimumPeriod, CalculationParameters.PayrollPeriod.EndOfPreviousPeriod));
	
	#EndRegion
	
	GeneralParametersForClosingMonth = MonthEndTransactionsServer.GeneralParametersForClosingMonth();
	If GeneralParametersForClosingMonth.Property("ItemOfExpensesForSelection")
	 And ValueIsFilled(GeneralParametersForClosingMonth.ItemOfExpensesForSelection) Then
		AddlParameters.Insert("ItemOfExpensesForSelection", GeneralParametersForClosingMonth.ItemOfExpensesForSelection);
	Else
		AddlParameters.Insert("ItemOfExpensesForSelection", Undefined);
	EndIf;
	If GeneralParametersForClosingMonth.Property("DivisionForSelection")
	 And ValueIsFilled(GeneralParametersForClosingMonth.DivisionForSelection) Then
		AddlParameters.Insert("DivisionForSelection", GeneralParametersForClosingMonth.DivisionForSelection);
	Else
		AddlParameters.Insert("DivisionForSelection", Undefined);
	EndIf;
	If GeneralParametersForClosingMonth.Property("ProductionLotReferenceForSelection")
	 And ValueIsFilled(GeneralParametersForClosingMonth.ProductionLotReferenceForSelection) Then
	 	AddlParameters.Insert("ProductionLotReferenceForSelection", GeneralParametersForClosingMonth.ProductionLotReferenceForSelection);
	Else
		AddlParameters.Insert("ProductionLotReferenceForSelection", Undefined);
	EndIf;
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTOfDeviationToDistribution, TTDeviationsOtherExpensesToBeAllocated,
		|TTOfRegisteredRecordsOfInventoryCostsByPeriod,
		|RegisteredRecordsTTOtherExpensesByPeriodPreliminary, RegisteredRecordsTTOtherExpensesByPeriod,
		|TTNodesOfExpensesOfPreviousPeriods, TTNodesOfDeviationsAreArticleByArticle,
		|TTNodesOfDeviations, TTNodesOtherExpensesUnfinishedProduction, DeviationTTCommunication,
		|NodesSLU_CalculationOfCostOfPastPeriods, SvyaziSLU_CalculationOfCostOfPastPeriods");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextForSolvingCaseCalculationOfCostOfPastPeriods(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Formation of the Query Text of the table of minimum periods.
//
// Returns:
// 	String - Query text
//
Function TextMinimumPeriods() Export // TT Minimum periods
	Return "
		|SELECT DISTINCT
		|	DD.Organization AS Organization,
		|	BEGINOFPERIOD(DD.VariancePeriod, MONTH) AS VariancePeriod
		|INTO TTDeviationPeriods
		|FROM
		|	TTCashEstimatedTurnoverOtherExpenses AS DD
		|WHERE
		|	DD.VariancePeriod <> DATETIME(1,1,1)
		|	AND DD.VariancePeriod < &BeginOfPeriod
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DD.Organization AS Organization,
		|	BEGINOFPERIOD(DD.VariancePeriod, MONTH) AS VariancePeriod
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|WHERE
		|	DD.VariancePeriod <> DATETIME(1,1,1)
		|	AND DD.VariancePeriod < &BeginOfPeriod
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DD.CorCompany AS Organization,
		|	BEGINOFPERIOD(DD.ReceiptPeriod, MONTH) AS VariancePeriod
		|FROM
		|	SharesOfAdditionalExpenses AS DD
		|WHERE
		|	DD.ReceiptPeriod <> DATETIME(1,1,1)
		|	AND DD.ReceiptPeriod < &BeginOfPeriod
		|;
		|SELECT
		|	DD.Organization AS Organization,
		|	MIN(DD.VariancePeriod) AS VariancePeriod
		|
		|INTO MinimumPeriodsPreliminary
		|FROM
		|	TTDeviationPeriods AS DD
		|GROUP BY
		|	DD.Organization
		|
		// Add minimum periods for branches and parent organizations.
		|UNION ALL
		|
		|SELECT
		|	BranchOffices_.Ref AS Organization,
		|	MIN(DD.VariancePeriod) AS VariancePeriod
		|FROM
		|	TTDeviationPeriods AS DD
		|	INNER JOIN Catalog.Companies AS Companies
		|		ON Companies.Ref = DD.Organization
		|	INNER JOIN Catalog.Companies AS BranchOffices_
		|		ON BranchOffices_.Ref IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		// Adding branches of the parent company, branches with the same parent company, and the parent company of the branch. 
		|		AND (BranchOffices_.Ref = Companies.ParentCompany
		|			OR BranchOffices_.ParentCompany = Companies.ParentCompany
		|			OR BranchOffices_.Ref = Companies.ParentCompany)
		|GROUP BY
		|	BranchOffices_.Ref
		|;
		|SELECT
		|	DD.Organization AS Organization,
		|	MIN(DD.VariancePeriod) AS VariancePeriod
		|
		|INTO MinimumPeriods
		|FROM
		|	MinimumPeriodsPreliminary AS DD
		|GROUP BY
		|	DD.Organization
		|;
		|SELECT
		|	MIN(DD.VariancePeriod) AS MinimumPeriod
		|FROM
		|	MinimumPeriods AS DD
		|";
EndFunction

// Formation of the Query Text for calculating the cost of past periods.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//	
// Returns:
// 	String - Query text
//
Function QueryTextForSolvingCaseCalculationOfCostOfPastPeriods(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(CostCalculationFillingInformationAboutLots.TextCorrectedDocuments()); // tue Corrected documents
	QueriesTexts.Add(TTOfDeviationToDistribution()); // TT to the worship of the distribution
	QueriesTexts.Add(TTDeviationsOtherExpensesToBeAllocated()); // TT to worship the prochieradditional expenses
	QueriesTexts.Add(TextTTRegisteredRecordsOfInventoryCostsByPeriodDetailed()); // TT vtmovementsthe values of the goods perioddetails
	QueriesTexts.Add(TextOfTTOfWriteOffForExpensesByPeriod()); // TT VtSpisaniyAnRashodyPoPeriodam
	QueriesTexts.Add(TextTTUsedExpensesByPeriod()); // TT is squeezed into useexcended periods
	QueriesTexts.Add(TextTTOtherExpensesPreviousPeriod()); // TT VT is the first time the past period has been spent
	QueriesTexts.Add(TextTTOtherExpensesUnfinishedProductionLastPeriod()); // TT vtprochieraskhodynzproslyiperiod
	QueriesTexts.Add(TextTTOtherExpensesWorkInProgressPreviousPeriod()); // TT vtprochierachievementnotesperfect productionthe previous period
	QueriesTexts.Add(TextTTIssuesLastPeriod()); // TT vtthe issues of the previous period
	QueriesTexts.Add(TextTTOfRegisteredRecordedOtherExpensesByPeriodPreliminary()); // TT textmovementprochierachievementoperiodampredvaritelnaya
	
	QueriesTexts.Add(TextTTNodesAdjustmentsOfPreviousPeriodsPreliminary()); // TT vtuzlykorrectirovkiproslykhperiodovprevious
	QueriesTexts.Add(TextTTNodesAdjustmentsOfPreviousPeriodsGrouped()); // TT vtuzlykorrection of the past periodsgrouped
	QueriesTexts.Add(TextTTNodesAdjustmentsOfPreviousPeriods()); // TT vtuzlykorrection of the past few periods
	QueriesTexts.Add(TextTTNodesOfExpensesOfPreviousPeriodsPreliminary()); // TT Textthe cost nodes of the past periodpreservative
	QueriesTexts.Add(TextTTNodesOfExpensesOfPreviousPeriods()); // TT of texturesconsumption of the past periods
	QueriesTexts.Add(TextTTNodesOfDeviationsAreArticleByArticle()); // TTNodesOfDeviationsAreArticleByArticle
	QueriesTexts.Add(TextTTNodesOfDeviationsPreliminary()); // TT VtUzlyOtkloneniyPredvaritelnaya
	QueriesTexts.Add(TextTTNodesOfDeviationsNumbered()); // TT vtuzlyotkloneniy Numbered
	QueriesTexts.Add(TextCoefficientsOfReductionOfDeviationNodes()); // TT is the coefficient of adoration of nodesreferences
	QueriesTexts.Add(TextTTNodesOfDeviations()); // TT vtuzlyotreferences
	QueriesTexts.Add(TextTTNodesOtherExpensesUnfinishedProduction()); // TT vtuzlyprochieraskhodynzp
	QueriesTexts.Add(TextOfTTOfRegisteredRecordsOfInventoryCostsByPeriod()); // TT vtmovementsthe value of goods by period
	QueriesTexts.Add(TextTTOfRegisteredRecordedOtherExpensesByPeriod()); // TT textmovementprochierachievementsreferences
	
	QueryTextsOfLink = New Array;
	QueryTextsOfLink.Add(TextOfTTOfRegisteredRecordsConnectionsOfInventoryCostsByPeriod()); // Uses the following movements for the highest values of goods by period
	QueryTextsOfLink.Add(TextWriteOffOfItemsForItemByItemExpenses()); // Uses the following movements for the highest values of goods by period
	QueryTextsOfLink.Add(TextOfInventoryCostRelationshipBetweenPeriods());
	QueryTextsOfLink.Add(TextOfRelationshipOfOtherExpensesBetweenPeriods());
	QueryTextsOfLink.Add(TextDistributionOfExpensesForInventoryCosts());
	QueryTextsOfLink.Add(TextDistributionOfExpensesForProductionLotReferences());
	QueryTextsOfLink.Add(TextAllocationOfExpensesToOtherItemsOfExpenses());
	TextOfTTOfDeviationConnectionPreliminary = StrConcat(QueryTextsOfLink, Common.UnionAllText());
	TextOfTTOfDeviationConnectionPreliminary = TextOfTTOfDeviationConnectionPreliminary + "
	|INDEX BY
	|	SourceNodeNumber
	|";
	
	QueriesTexts.Add(TextOfTTOfDeviationConnectionPreliminary); // TT Vtsvyaziotkloneniypredvaritelnaya
	QueriesTexts.Add(TextOfTTOfDeviationConnection()); // TT Vtvyaziotreferences
	QueriesTexts.Add(TextNodesOfServiceCalculationOfCostOfPastPeriods()); // TT nodal_accountingthe cost of the past three periods
	QueriesTexts.Add(TextOfLinkSLU_CalculationOfCostOfPastPeriods()); // TT svyazislu_accountingthe cost of the past few periods
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextTTOtherExpensesPreviousPeriod()
	QueryText = "
		|SELECT
		|	T.Period AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS MonthPeriod,
		|	T.Recorder AS Recorder,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.Sum AS Sum,
		|	T.AmountExcludingVAT AS AmountExcludingVAT,
		|	T.SumCompl AS SumCompl,
		|	T.SumCompl - T.PermanentDifference - T.CostTD AS AmountFA,
		|	T.SumMan AS SumMan,
		|	T.AITAmount AS AITAmount,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostTD AS CostTD
		|INTO TTOtherExpensesForPreviousPeriodPreliminary
		|FROM
		|	AccumulationRegister.OtherExpenses AS T
		|WHERE
		|	T.Period >= &MinimumPastPeriod
		|	AND T.Organization IN(&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND (&ItemOfExpensesForSelection = UNDEFINED
		|		OR T.ExpenseItem = &ItemOfExpensesForSelection)
		|
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	LineOfBusiness,
		|	Department,
		|	Organization,
		|	MonthPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Period AS Period,
		|	T.MonthPeriod AS MonthPeriod,
		|	T.Recorder AS Recorder,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.Sum AS Sum,
		|	T.AmountExcludingVAT AS AmountExcludingVAT,
		|	T.SumCompl AS SumCompl,
		|	T.AmountFA AS AmountFA,
		|	T.SumMan AS SumMan,
		|	T.AITAmount AS AITAmount,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostTD AS CostTD,
		|	CorrectedDocuments_.ReversedDocument IS NULL AS RecorderIsNotCancelled
		|INTO TTOtherExpensesForPreviousPeriod
		|FROM
		|	TTOtherExpensesForPreviousPeriodPreliminary AS T
		|
		|	INNER JOIN TTUsedExpensesByPeriod AS Filter
		|	ON (Filter.Organization = T.Organization)
		|		AND (Filter.Department = T.Department)
		|		AND (Filter.LineOfBusiness = T.LineOfBusiness)
		|		AND (Filter.ExpenseItem = T.ExpenseItem)
		|		AND (Filter.DimensionOfExpenses = T.DimensionOfExpenses)
		|		AND (Filter.DistributionPeriod = T.MonthPeriod)
		|
		|	LEFT JOIN AdditionalCostAdjustmentNodes AS NodesOfAdditionalExpenses
		|	ON NodesOfAdditionalExpenses.Organization = T.Organization
		|		AND NodesOfAdditionalExpenses.Department = T.Department
		|		AND NodesOfAdditionalExpenses.LineOfBusiness = T.LineOfBusiness
		|		AND NodesOfAdditionalExpenses.ExpenseItem = T.ExpenseItem
		|		AND NodesOfAdditionalExpenses.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND NodesOfAdditionalExpenses.ReceiptPeriod < &BeginOfPeriod
		|
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|	ON (CorrectedDocuments_.ReversedDocument = T.Recorder)
		|
		|WHERE
		// We exclude from the database expenses for which there is a base of distribution according to the document of distribution of expenses.
		|	NodesOfAdditionalExpenses.Organization IS NULL
		|
		|INDEX BY
		|	RecorderIsNotCancelled,
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Period AS Period,
		|	T.MonthPeriod AS MonthPeriod,
		|	T.Recorder AS Recorder,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.Sum AS Sum,
		|	T.AmountExcludingVAT AS AmountExcludingVAT,
		|	T.SumCompl AS SumCompl,
		|	T.AmountFA AS AmountFA,
		|	T.SumMan AS SumMan,
		|	T.AITAmount AS AITAmount,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostTD AS CostTD,
		|	T.RecorderIsNotCancelled AS RecorderIsNotCancelled
		|INTO TTOtherExpensesLastPeriodEndOfPeriodLimited
		|FROM
		|	TTOtherExpensesForPreviousPeriod AS T
		|WHERE
		|	T.Period <= &EndOfPreviousPeriod
		// We exclude the selection of documents from the previous period for which there are storno or corrections in the current period.
		|	AND T.RecorderIsNotCancelled
		|
		|INDEX BY
		|	Period,
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTOtherExpensesForPreviousPeriodPreliminary
		|";
	Return QueryText;
EndFunction

Function TextTTOtherExpensesWorkInProgressPreviousPeriod()
	QueryText = "
		|SELECT
		|	T.Period AS Period,
		|	T.Recorder AS Recorder,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.ProductionLot AS ProductionLot,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	T.BusinessTransactionSetting.BusinessOperation AS SettingUpBusinessTransactionBusinessTransaction,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	T.Cost AS Cost,
		|	T.CostExcludingVAT AS CostExcludingVAT,
		|	T.LocalCost AS LocalCost1,
		|	T.LocalCost AS LocalCost,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostTD AS CostTD,
		|	T.CostMan AS CostMan,
		|	T.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
		|INTO TTOtherExpensesOfWorkInProgressPreviousPeriod
		|FROM
		|	AccumulationRegister.OtherWorkInProgressExpenses AS T
		|		LEFT JOIN ProductionBatchesAreSummarized AS ProductionLots
		|		ON (ProductionLots.ProductionLot = T.ProductionLot)
		|			AND (ProductionLots.Organization = T.Organization)
		|		LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON (CorrectedDocuments_.ReversedDocument = T.Recorder)
		|			AND (NOT ISNULL(ProductionLots.CostAllocationForIssue, FALSE))
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN(&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				TTUsedExpensesByPeriodCollapsed AS Filter
		|			WHERE
		|				Filter.Organization = T.Organization
		|				AND Filter.ExpenseItem = T.ExpenseItem
		|				AND Filter.DimensionOfExpenses = T.DimensionOfExpenses)
		|	AND (&ItemOfExpensesForSelection = UNDEFINED
		|		OR T.ExpenseItem = &ItemOfExpensesForSelection)
		|	AND (&ProductionLotReferenceForSelection = UNDEFINED
		|		OR T.ProductionLot = &ProductionLotReferenceForSelection)
		// We exclude the selection of documents from the previous period for which there are storno or corrections in the current period.
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|INDEX BY
		|	Period,
		|	Recorder
		|"; 
	Return QueryText;
EndFunction

Function TextTTOtherExpensesUnfinishedProductionLastPeriod()
	QueryText = "
	|SELECT
	|	OtherExpensesOfUnfinishedProduction.Recorder AS Recorder,
	|	OtherExpensesOfUnfinishedProduction.Period AS Period,
	|	OtherExpensesOfUnfinishedProduction.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	OtherExpensesOfUnfinishedProduction.FinRecordID AS FinRecordID,
	|	OtherExpensesOfUnfinishedProduction.LineOfBusiness AS LineOfBusiness,
	|	OtherExpensesOfUnfinishedProduction.Department AS Department,
	|	OtherExpensesOfUnfinishedProduction.ProductionLot AS ProductionLot,
	|	OtherExpensesOfUnfinishedProduction.ProductCostElement AS ProductCostElement,
	|	OtherExpensesOfUnfinishedProduction.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
	|	OtherExpensesOfUnfinishedProduction.Cost AS Cost,
	|	OtherExpensesOfUnfinishedProduction.LocalCost AS LocalCost,
	|	OtherExpensesOfUnfinishedProduction.CostMan AS CostMan,
	|	OtherExpensesOfUnfinishedProduction.CostOfPersonalIncomeTax AS CostOfPersonalIncomeTax
	|INTO TTOtherExpensesUnfinishedProductionLastPeriod
	|FROM
	|	AccumulationRegister.OtherWorkInProgressExpenses AS OtherExpensesOfUnfinishedProduction
	|WHERE
	|	OtherExpensesOfUnfinishedProduction.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
	|	AND VALUETYPE(OtherExpensesOfUnfinishedProduction.Recorder) <> TYPE(Document.CostCalculationRecorder)
	|	AND OtherExpensesOfUnfinishedProduction.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (&ProductionLotReferenceForSelection = UNDEFINED
	|		OR OtherExpensesOfUnfinishedProduction.ProductionLot = &ProductionLotReferenceForSelection)
	|	AND (&ItemOfExpensesForSelection = UNDEFINED
	|		OR OtherExpensesOfUnfinishedProduction.ExpenseItem = &ItemOfExpensesForSelection)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TTUsedExpensesByPeriodCollapsed AS Filter
	|			WHERE
	|				Filter.Organization = OtherExpensesOfUnfinishedProduction.Organization
	|				AND Filter.ExpenseItem = OtherExpensesOfUnfinishedProduction.ExpenseItem
	|				AND Filter.DimensionOfExpenses = OtherExpensesOfUnfinishedProduction.DimensionOfExpenses)
	|
	|INDEX BY
	|	Period,
	|	Recorder
	|";
	Return QueryText;
EndFunction

Function TTOfDeviationToDistribution() // TT to the worship of the distribution
	
	// A similar query is used in the cost calculation.It is required to re-account the value of the previous periods()
	// When making changes to this request, you need to change the above request in the same way.
	
	Return "
		|SELECT
		|	BEGINOFPERIOD(T.VariancePeriod, MONTH) AS VariancePeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesForGoods
		|		ELSE -T.AddExpensesForGoods END) AS AdditionalExpensesIncludingVAT,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AdditionalExpensesExcludingVAT
		|		ELSE -T.AdditionalExpensesExcludingVAT END) AS AdditionalExpensesExcludingVAT,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesLocal
		|		ELSE -T.AddExpensesLocal END) AS AddExpensesLocal,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesMan
		|		ELSE -T.AddExpensesMan END) AS AddExpensesMan,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.PermanentDifference
		|		ELSE -T.PermanentDifference END) AS PermanentDifference,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.CostTD
		|		ELSE -T.CostTD END) AS CostTD,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish
		|		THEN T.AddExpensesLocal - T.PermanentDifference - T.CostTD
		|		ELSE -(T.AddExpensesLocal - T.PermanentDifference - T.CostTD) END) AS CostInTaxAccounting,
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.CostOfPersonalIncomeTax
		|		ELSE -T.CostOfPersonalIncomeTax END) AS AIT
		|
		|INTO TTOfDeviationToDistribution
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|WHERE
		|	T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND NOT T.Organization IN (&MediumSlipOrganizations)
		|	AND T.VariancePeriod <> DATETIME(1,1,1)
		|	AND T.VariancePeriod < &BeginOfPeriod
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND (NOT T.CalculationOfCost AND NOT T.LotCalculation
		|		OR T.EntryType =VALUE(Enum.LotRecordTypes.CostVariance)
		|		OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate))
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.VariancePeriod, MONTH),
		|	T.ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|
		|HAVING
		|	SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesForGoods
		|		ELSE -T.AddExpensesForGoods END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AdditionalExpensesExcludingVAT
		|		ELSE -T.AdditionalExpensesExcludingVAT END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesLocal
		|		ELSE -T.AddExpensesLocal END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.AddExpensesMan
		|		ELSE -T.AddExpensesMan END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.PermanentDifference
		|		ELSE -T.PermanentDifference END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.CostTD
		|		ELSE -T.CostTD END) <> 0
		|	OR SUM(CASE WHEN T.OfficialTypeOfMovementParish THEN T.CostOfPersonalIncomeTax
		|		ELSE -T.CostOfPersonalIncomeTax END) <> 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TTDeviationsOtherExpensesToBeAllocated() // TT to worship the prochieradditional expenses
	
	// A similar query is used in the cost calculation.It is required to re-account the value of the previous periods()
	// When making changes to this request, you need to change the above request in the same way.
	
	Return "
		|SELECT
		|	BEGINOFPERIOD(T.VariancePeriod, MONTH) AS VariancePeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.Sum
		|		ELSE -T.Sum END) AS Sum,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.AmountExcludingVAT
		|		ELSE -T.AmountExcludingVAT END) AS AmountExcludingVAT,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.SumCompl
		|		ELSE -T.SumCompl END) AS SumCompl,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.SumMan
		|		ELSE -T.SumMan END) AS SumMan,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.PermanentDifference
		|		ELSE -T.PermanentDifference END) AS PermanentDifference,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.CostTD
		|		ELSE -T.CostTD END) AS CostTD,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish
		|			THEN T.SumCompl - T.PermanentDifference - T.CostTD
		|		ELSE -(T.SumCompl - T.PermanentDifference - T.CostTD) END) AS AmountFA,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.AITAmount
		|		ELSE -T.AITAmount END) AS AIT
		|
		|INTO TTDeviationsOtherExpensesToBeAllocated
		|FROM
		|	TTCashEstimatedTurnoverOtherExpenses AS T
		|
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = T.ExpenseItem
		|
		|	LEFT JOIN AdditionalCostAdjustmentNodes AS NodesOfAdditionalExpenses
		|		ON NodesOfAdditionalExpenses.Organization = T.Organization
		|		AND NodesOfAdditionalExpenses.Department = T.Department
		|		AND NodesOfAdditionalExpenses.LineOfBusiness = T.LineOfBusiness
		|		AND NodesOfAdditionalExpenses.ExpenseItem = T.ExpenseItem
		|		AND NodesOfAdditionalExpenses.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND NodesOfAdditionalExpenses.ReceiptPeriod < &BeginOfPeriod
		|WHERE
		|	T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND T.VariancePeriod <> DATETIME(1,1,1)
		|	AND T.VariancePeriod < &BeginOfPeriod
		|	AND NOT T.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness),
		|			VALUE(Enum.BusinessTransactions.AllocationOfNormalizedExpensesAsPerTA))
		// We exclude expenses for which there is a distribution base according to the cost allocation document.
		|	AND NodesOfAdditionalExpenses.Organization IS NULL
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.VariancePeriod, MONTH),
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|
		|HAVING
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		 WHEN T.OfficialTypeOfMovementParish THEN T.Sum
		|		ELSE -T.Sum END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.AmountExcludingVAT
		|		ELSE -T.AmountExcludingVAT END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.SumCompl
		|		ELSE -T.SumCompl END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.SumMan
		|		ELSE -T.SumMan END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.PermanentDifference
		|		ELSE -T.PermanentDifference END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.CostTD
		|		ELSE -T.CostTD END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish
		|			THEN T.SumCompl - T.PermanentDifference - T.CostTD
		|		ELSE -(T.SumCompl - T.PermanentDifference - T.CostTD) END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly))
		|			THEN 0
		|		WHEN T.OfficialTypeOfMovementParish THEN T.AITAmount
		|		ELSE -T.AITAmount END) <> 0
		|
		|INDEX BY
		|	Organization,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|";
EndFunction

Function TextTTRegisteredRecordsOfInventoryCostsByPeriodDetailed() // Movements of the highest values of the goods perioddetails
	// The sample of Registered Recorded past periods should be similar to the sample for the average sliding movement
	// in the function of the textthe values of the goods during the period of detailed worship().
	Return "
		|SELECT
		|	FALSE AS ThisIsCurrentPeriod,
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// The condition for checking for a transfer to another organization must correspond to the text-to-Text function of the description()
		// in the general module for calculating the cost of resolving the issue.
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END AS ThereIsCorPart,
		|	&BeginOfPeriod AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		// Dimensions
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
		|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		// Cor Attributes
		|	T.CorAccountingSection AS CorAccountingSection,
		|	T.CorCompany AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorItemsLocationAttributes.Products AS CorNomenclature,
		|	T.CorItemsLocationAttributes.Characteristic AS CorCharacteristics,
		|	T.CorItemsLocationAttributes.StorageLocation AS BoxStorageLocation,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	(CASE
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|			THEN T.VATActivityType
		|		ELSE T.CorVATActivityTypes END) AS CorVATActivityTypes,
		|
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.Department AS Department,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN -T.Count
		|		ELSE T.Count END) AS Count
		|
		|INTO TTRegisteredRecordsOfInventoryCostsByPeriodDetailed
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = T.Organization
		|		AND MinimumPeriods.VariancePeriod <= T.Period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND (T.RecordType = VALUE(AccumulationRecordType.Expense)
		|		OR T.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|	)
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND T.Count <> 0
		// We exclude off-balance sheet sections of accounting, except for the semi-finished giver - there may be balance costs for it.
		|	AND (NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		OR ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
		|	AND T.Count <> 0
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		// We exclude the selection of documents from the previous period for which there are storno or corrections in the current period.
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// The condition for checking for a transfer to another organization must correspond to the text-to-Text function of the description()
		// in the general module for calculating the cost of resolving the issue.
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END, // ThereIsCorPart
		|	BEGINOFPERIOD(T.Period, MONTH),
		// Dimensions
		|	T.ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.Characteristic,
		|	ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|		VALUE(Catalog.LinesOfBusiness.EmptyRef)), // LineOfBusiness
		|	T.ItemsLocationAttributes.StorageLocation,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		// Cor Attributes
		|	T.CorAccountingSection,
		|	T.CorCompany,
		|	T.CorItemsLocationAttributes,
		|	T.CorItemsLocationAttributes.Products,
		|	T.CorItemsLocationAttributes.Characteristic,
		|	T.CorItemsLocationAttributes.StorageLocation,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	(CASE
		|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|			THEN T.VATActivityType
		|		ELSE T.CorVATActivityTypes END), // CorVATActivityTypes
		|
		|	T.AccountingDimensionByPartners,
		|	T.Department,
		|	T.CorLineOfBusiness,
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) // WriteOffDeviationsToCostOfGoodsSelling
		|HAVING
		|	SUM(T.Count) <> 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction	

Function TextOfTTOfWriteOffForExpensesByPeriod() // TT VtSpisaniyAnRashodyPoPeriodam
	Return "
		|SELECT DISTINCT
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.CorLineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItemOfWriteOff AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses
		|
		|INTO TTWriteOffForExpensesByPeriod
		|FROM
		|	TTRegisteredRecordsOfInventoryCostsByPeriodDetailed AS T
		|WHERE
		|	T.ExpenseItemOfWriteOff <> UNDEFINED 
		|	AND T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND T.ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.CostCalculationError)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.DebitBusinessUnit AS Department,
		|	T.CorLineOfBusiness AS LineOfBusiness,
		|	T.CorExpenseItem AS ExpenseItem,
		|	T.CorExpenditureDimension AS DimensionOfExpenses
		|FROM
		|	AccumulationRegister.OtherExpenses AS T
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&CompanyArray)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND T.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|";
EndFunction

Function TextTTUsedExpensesByPeriod() // TT is squeezed into useexcended periods
	Return "
		|SELECT DISTINCT
		|	BEGINOFPERIOD(T.VariancePeriod, MONTH) AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses
		|
		|INTO TTUsedExpensesByPeriodPreliminary
		|FROM
		|	TTDeviationsOtherExpensesToBeAllocated AS T
		|WHERE
		|	(&ItemOfExpensesForSelection = UNDEFINED
		|		OR T.ExpenseItem = &ItemOfExpensesForSelection)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses
		|FROM
		|	TTWriteOffForExpensesByPeriod AS T
		|WHERE
		|	(&ItemOfExpensesForSelection = UNDEFINED
		|		OR T.ExpenseItem = &ItemOfExpensesForSelection)
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	LineOfBusiness,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|;
		|SELECT DISTINCT
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses
		|
		|INTO TTUsedExpensesByPeriod
		|FROM
		|	TTUsedExpensesByPeriodPreliminary AS T
		|
		|	LEFT JOIN AdditionalCostAdjustmentNodes AS NodesOfAdditionalExpenses
		|		ON NodesOfAdditionalExpenses.Organization = T.Organization
		|		AND NodesOfAdditionalExpenses.Department = T.Department
		|		AND NodesOfAdditionalExpenses.LineOfBusiness = T.LineOfBusiness
		|		AND NodesOfAdditionalExpenses.ExpenseItem = T.ExpenseItem
		|		AND NodesOfAdditionalExpenses.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND NodesOfAdditionalExpenses.ReceiptPeriod < &BeginOfPeriod
		|WHERE
		// We exclude expenses for which there is a base of distribution according to the document of distribution of expenses.
		// For such expenses, nodes are formed in query 3 according to the data of the table of node correctionsadditional expenses. 
		|	NodesOfAdditionalExpenses.Organization IS NULL
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	LineOfBusiness,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|;
		|SELECT DISTINCT
		|	T.Organization AS Organization,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses
		|
		|INTO TTUsedExpensesByPeriodCollapsed
		|FROM
		|	TTUsedExpensesByPeriod AS T
		|
		|INDEX BY
		|	Organization,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|";
EndFunction

Function TextTTIssuesLastPeriod() // TT vtthe issues of the previous period
	Return "
		|SELECT DISTINCT
		|	DD.Period AS Period,
		|	DD.Recorder AS Recorder,
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute, 
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	DD.BusinessOperation,
		|	DD.FinRecordID,
		|	DD.BusinessTransactionSetting
		|
		|INTO TTIssuesLastPeriod
		|FROM
		|	AccumulationRegister.InventoryCost AS DD
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = DD.Organization
		|		AND MinimumPeriods.VariancePeriod <= DD.Period
		|WHERE
		|	DD.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND DD.Organization IN(&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND DD.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ProductsRelease),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit),
		|		VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
		|	AND NOT DD.ReversingEntry
		|
		|INDEX BY
		|	Period,
		|	Recorder
		|";
EndFunction

Function TextTTOfRegisteredRecordedOtherExpensesByPeriodPreliminary() // TT vtmovementprochierachievementoperiodampredvaritelnaya
	QueryText = "";
	
	#Region ExpenseAllocationOnInventoryCosts_1
	QueryText = QueryText + "
		// Distribution of expenses for the cost of goods.
		|SELECT
		|	""1"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	TRUE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	Cost_.Organization AS CorCompany,
		|	ISNULL(Cost_.ItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(Cost_.ItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	Cost_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) CorLineOfBusiness,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS DebitBusinessUnit,
		|	UNDEFINED AS BoxStorageLocation,
		// COR Cost Attributes
		|	Cost_.AccountingSection AS CorAccountingSection,
		|	Cost_.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Cost_.Lot AS CorLot,
		|	Cost_.LotVendorAttributes AS LotVendorAttributesCorr,
		|	Cost_.FinancialAccountingDimension AS CorControllingAttributes,
		|	Cost_.VATActivityType AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED  AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Sum) AS AmountIncludingVAT,
		|	SUM(T.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.SumCompl) AS SumCompl,
		|	SUM(T.SumCompl - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.SumMan) AS SumMan,
		|	SUM(T.AITAmount) AS AITAmount
		|
		|INTO RegisteredRecordsTTOtherExpensesByPeriodPreliminary
		|FROM
		|	TTOtherExpensesLastPeriodEndOfPeriodLimited AS T
		|
		|	INNER JOIN AccumulationRegister.InventoryCost AS Cost_
		|		ON Cost_.Period = T.Period
		|		AND Cost_.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND Cost_.Recorder = T.Recorder
		|		AND Cost_.BusinessTransactionSetting = T.BusinessTransactionSetting		
		|		AND Cost_.FinRecordID = T.FinRecordID
		|		AND Cost_.AddExpensesForGoods = T.Sum
		|		AND Cost_.AddExpensesLocal = T.SumCompl
		|		AND Cost_.AddExpensesMan = T.SumMan
		|		AND Cost_.CostOfPersonalIncomeTax = T.AITAmount
		|
		|WHERE
		|	NOT T.Organization IN (&MediumSlipOrganizations)
		|	AND VALUETYPE(T.Recorder) <> TYPE(Document.CostCalculationRecorder)
		|
		|GROUP BY
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes of deviations
		|	Cost_.Organization,
		|	ISNULL(Cost_.ItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(Cost_.ItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	Cost_.InventoryOwnerAttribute, // CorInventoryOwnerAttribute
		// COR Cost Attributes
		|	Cost_.AccountingSection,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.Lot,
		|	Cost_.LotVendorAttributes,
		|	Cost_.FinancialAccountingDimension,
		|	Cost_.VATActivityType,
		|
		|	T.DebitBusinessUnit,
		|	T.CorLineOfBusiness,
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Sum) <> 0
		|	OR SUM(T.AmountExcludingVAT) <> 0
		|	OR SUM(T.SumCompl) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.SumMan) <> 0
		|	OR SUM(T.AITAmount) <> 0
		|";
	#EndRegion
	
	#Region DistributionOfExpensesForInventoryCostsAverageSliding_2
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of expenses for inventory costs at a medium-slip.
		|SELECT
		|	""2"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	TRUE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	Cost_.Organization AS CorCompany,
		|	Cost_.Products AS CorNomenclature,
		|	Cost_.Characteristic AS CorCharacteristics,
		|	Cost_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	Cost_.LineOfBusiness AS CorLineOfBusiness,
		|	Cost_.Department AS DebitBusinessUnit,
		|	Cost_.StorageLocation AS BoxStorageLocation,
		// COR Cost Attributes 
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	UNDEFINED CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		// Other fields
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED  AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Sum) AS AmountIncludingVAT,
		|	SUM(T.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.SumCompl) AS SumCompl,
		|	SUM(T.SumCompl - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.SumMan) AS SumMan,
		|	SUM(T.AITAmount) AS AITAmount
		|FROM
		|	TTOtherExpensesLastPeriodEndOfPeriodLimited AS T
		|
		|	INNER JOIN AccumulationRegister.GoodsCostVariances AS Cost_
		|		ON Cost_.Period = T.Period
		|		AND Cost_.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND Cost_.Recorder = T.Recorder
		|		AND Cost_.BusinessTransactionSetting = T.BusinessTransactionSetting		
		|		AND Cost_.FinRecordID = T.FinRecordID
		|		AND Cost_.AdditionalExpensesIncludingVAT = T.Sum
		|		AND Cost_.AddExpensesLocal = T.SumCompl
		|		AND Cost_.AddExpensesMan = T.SumMan
		|		AND Cost_.AIT = T.AITAmount
		|
		|WHERE
		|	T.Organization IN(&MediumSlipOrganizations)
		|
		|GROUP BY
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes of deviations
		|	Cost_.Organization,
		|	Cost_.Products,
		|	Cost_.Characteristic,
		|	Cost_.InventoryOwnerAttribute,
		|	Cost_.LineOfBusiness,
		|	Cost_.Department,
		|	Cost_.StorageLocation,
		|
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Sum) <> 0
		|	OR SUM(T.AmountExcludingVAT) <> 0
		|	OR SUM(T.SumCompl) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.SumMan) <> 0
		|	OR SUM(T.AITAmount) <> 0
		|";
	#EndRegion
		
	#Region DistributionOfExpensesForInventoryCostsBasedOn_3
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of expenses for inventory costs according to the distribution base.
		|SELECT
		|	""3"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	(T.CorAccountingSection <> UNDEFINED) AS ThereIsCorPart,
		|	T.Recorder AS Recorder,
		|	Attributes.Date AS Period,
		|	BEGINOFPERIOD(T.ReceiptPeriod, MONTH) AS DistributionPeriod,
		// Dimensions
		|	Attributes.Organization AS Organization,
		|	Attributes.Department AS Department,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	Attributes.ExpenseItem AS ExpenseItem,
		|	Attributes.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	T.CorCompany AS CorCompany,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(T.CorItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		// COR Cost Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		WHEN Attributes.Organization IN (&MediumSlipOrganizations)		
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		ELSE T.CorAccountingSection END) AS CorAccountingSection,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED  AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	BsnsTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	MAX(T.FinRecordID) AS FinRecordID,
		|	SUM(T.CostShare) AS AmountIncludingVAT,
		|	SUM(T.ShareOfValueWithoutVAT) AS AmountExcludingVAT,
		|	SUM(T.ShareOfLocalValue) AS SumCompl,
		|	SUM(T.ShareValueTa) AS AmountFA,
		|	SUM(T.ShareOfManSCost) AS SumMan,
		|	SUM(T.ShareOfCostOfPersonalIncomeTax) AS AITAmount
		|FROM
		|	SharesOfAdditionalExpenses AS T
		|
		|	INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|		ON T.Recorder = Attributes.Ref
		|
		|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BsnsTransactionsSettings
		|		ON BsnsTransactionsSettings.BusinessOperation = T.BusinessOperation
		|
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Attributes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|WHERE
		|	T.ReceiptPeriod < &BeginOfPeriod
		|	AND Attributes.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND (&ItemOfExpensesForSelection = UNDEFINED
		|		OR Attributes.ExpenseItem = &ItemOfExpensesForSelection)
		|
		|GROUP BY
		|	(T.CorAccountingSection <> UNDEFINED), // ThereIsCorPart
		|	T.Recorder,
		|	Attributes.Date,
		|	BEGINOFPERIOD(T.ReceiptPeriod, MONTH),
		// Dimensions
		|	Attributes.Organization,
		|	Attributes.Department,
		|	Attributes.LineOfBusiness,
		|	Attributes.ExpenseItem,
		|	Attributes.DimensionOfExpenses,
		// Cor Attributes of deviations
		|	T.CorCompany,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(T.CorItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	T.CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		WHEN Attributes.Organization IN (&MediumSlipOrganizations)		
		|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		ELSE T.CorAccountingSection END), // CorAccountingSection
		|	T.CorItemsLocationAttributes,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	BsnsTransactionsSettings.Ref
		|HAVING
		|	SUM(T.CostShare) <> 0
		|	OR SUM(T.ShareOfValueWithoutVAT) <> 0
		|	OR SUM(T.ShareOfLocalValue) <> 0
		|	OR SUM(T.ShareValueTa) <> 0
		|	OR SUM(T.ShareOfManSCost) <> 0
		|	OR SUM(T.ShareOfCostOfPersonalIncomeTax) <> 0
		|";
	#EndRegion
	#Region AllocationOfExpensesForProductionLots_4
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of costs for production batches.
		|SELECT
		|	""4"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	TRUE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	T.Organization AS CorCompany,
		|	UNDEFINED AS CorNomenclature,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CorCharacteristics,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	OtherExpensesOfUnfinishedProduction.LineOfBusiness AS CorLineOfBusiness,
		|	OtherExpensesOfUnfinishedProduction.Department AS DebitBusinessUnit,
		|	UNDEFINED AS BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	OtherExpensesOfUnfinishedProduction.ProductionLot AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement AS ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Sum) AS AmountIncludingVAT,
		|	SUM(T.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.SumCompl) AS SumCompl,
		|	SUM(T.SumCompl - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.SumMan) AS SumMan,
		|	SUM(T.AITAmount) AS AITAmount
		|FROM
		|	TTOtherExpensesLastPeriodEndOfPeriodLimited AS T
		|		INNER JOIN TTOtherExpensesUnfinishedProductionLastPeriod AS OtherExpensesOfUnfinishedProduction
		|		ON (OtherExpensesOfUnfinishedProduction.Period = T.Period)
		|			AND (OtherExpensesOfUnfinishedProduction.Recorder = T.Recorder)
		|			AND (OtherExpensesOfUnfinishedProduction.BusinessTransactionSetting = T.BusinessTransactionSetting)
		|			AND (OtherExpensesOfUnfinishedProduction.FinRecordID = T.FinRecordID)
		|			AND (OtherExpensesOfUnfinishedProduction.Cost = T.Sum)
		|			AND (OtherExpensesOfUnfinishedProduction.LocalCost = T.SumCompl)
		|			AND (OtherExpensesOfUnfinishedProduction.CostMan = T.SumMan)
		|			AND (OtherExpensesOfUnfinishedProduction.CostOfPersonalIncomeTax = T.AITAmount)
		|
		|GROUP BY
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes
		|	OtherExpensesOfUnfinishedProduction.ProductionLot,
		|	OtherExpensesOfUnfinishedProduction.ProductCostElement,
		|	OtherExpensesOfUnfinishedProduction.RuleOfCostAllocatingToProductionLots,
		|	OtherExpensesOfUnfinishedProduction.Department, // DebitBusinessUnit
		|	OtherExpensesOfUnfinishedProduction.LineOfBusiness, // CorLineOfBusiness
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Sum) <> 0
		|	OR SUM(T.AmountExcludingVAT) <> 0
		|	OR SUM(T.SumCompl) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.SumMan) <> 0
		|	OR SUM(T.AITAmount) <> 0
		|";
	#EndRegion
	
	#Region DistributionOfExpensesForManufacturedProducts_5
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of expenses for manufactured products.
		|SELECT
		|	""5"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	TRUE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.ProductionLot AS Lot,
		// Cor Attributes of deviations
		|	Cost_.Organization AS CorCompany,
		|	ISNULL(Cost_.ItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(Cost_.ItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	T.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS CorLineOfBusiness,
		|	ISNULL(Cost_.ItemsLocationAttributes.StorageLocation,
		|		VALUE(Catalog.BusinessStructure.EmptyRef)) AS DebitBusinessUnit,
		|	ISNULL(Cost_.ItemsLocationAttributes.StorageLocation, UNDEFINED) AS BoxStorageLocation,
		// COR Cost Attributes
		|	Cost_.AccountingSection AS CorAccountingSection,
		|	Cost_.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	Cost_.Lot AS CorLot,
		|	Cost_.LotVendorAttributes AS LotVendorAttributesCorr,
		|	Cost_.FinancialAccountingDimension AS CorControllingAttributes,
		|	Cost_.VATActivityType AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS CorExpenseItem,
		|	UNDEFINED AS CorExpenditureDimension,
		|	Cost_.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Cost) AS AmountIncludingVAT,
		|	SUM(T.CostExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.LocalCost) AS SumCompl,
		|	SUM(T.LocalCost - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.CostMan) AS SumMan,
		|	SUM(T.CostOfPersonalIncomeTax) AS AITAmount
		|FROM
		|
		|	TTOtherExpensesOfWorkInProgressPreviousPeriod AS T
		|	INNER JOIN TTIssuesLastPeriod AS Cost_
		|	ON Cost_.Period = T.Period
		|		AND Cost_.Recorder = T.Recorder
		|		AND Cost_.BusinessTransactionSetting = T.BusinessTransactionSetting
		|		AND Cost_.FinRecordID = T.FinRecordID
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH),
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.ProductionLot,
		// Cor Attributes of deviations
		|	Cost_.Organization,
		|	ISNULL(Cost_.ItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(Cost_.ItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	T.InventoryOwnerAttribute,
		|	ISNULL(Cost_.ItemsLocationAttributes.StorageLocation, UNDEFINED), // BoxStorageLocation
		// COR Cost Attributes
		|	Cost_.AccountingSection,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.Lot,
		|	Cost_.LotVendorAttributes,
		|	Cost_.FinancialAccountingDimension,
		|	Cost_.VATActivityType,
		|
		|	T.ProductCostElement,
		|	T.RuleOfCostAllocatingToProductionLots,
		|	Cost_.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Cost) <> 0
		|	OR SUM(T.CostExcludingVAT) <> 0
		|	OR SUM(T.LocalCost) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.CostMan) <> 0
		|	OR SUM(T.CostOfPersonalIncomeTax) <> 0
		|";
	#EndRegion
	#Region ExpenseAllocationOnCostOfGoodsSold_6
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of expenses for the cost of sales.
		|SELECT
		|	""6"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	FALSE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	T.Organization AS CorCompany,
		// The nomenclature field must not be filled in. This is a condition for fetching data in the general module for calculating the cost of correcting the cost
		// in the query #The area of the distribution of the cost of the financial resultsproche_5
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CorCharacteristics,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	UNDEFINED AS BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	Sales.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Sales.Lot AS CorLot,
		|	Sales.LotVendorAttributes AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|
		|	Sales.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Sales.SalesOrder AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Sum) AS AmountIncludingVAT,
		|	SUM(T.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.SumCompl) AS SumCompl,
		|	SUM(T.SumCompl - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.SumMan) AS SumMan,
		|	SUM(T.AITAmount) AS AITAmount
		|FROM
		|	TTOtherExpensesLastPeriodEndOfPeriodLimited AS T
		|
		|	INNER JOIN AccumulationRegister.RevenueAndCOGS AS Sales
		|		ON Sales.Period = T.Period
		|		AND Sales.Recorder = T.Recorder
		|		AND Sales.BusinessTransactionSetting = T.BusinessTransactionSetting		
		|		AND Sales.FinRecordID = T.FinRecordID
		|		AND Sales.SellingExpensesIncludingVAT = T.Sum
		|		AND Sales.SellingExpensesLocal = T.SumCompl
		|		AND Sales.SellingExpensesMan = T.SumMan
		|WHERE
		|	VALUETYPE(T.Recorder) <> TYPE(Document.CostCalculationRecorder)
		|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffRoundingErrors)
		|
		|GROUP BY
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes
		|	Sales.ItemsLocationAttributes,
		|	ISNULL(Sales.ItemsLocationAttributes.Products, VALUE(Catalog.Products.EmptyRef)),
		|
		|	Sales.AccountingDimensionByPartners,
		|	Sales.SalesOrder,
		|	Sales.Lot,
		|	Sales.LotVendorAttributes,
		|	T.DebitBusinessUnit,
		|	T.CorLineOfBusiness,
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Sum) <> 0
		|	OR SUM(T.AmountExcludingVAT) <> 0
		|	OR SUM(T.SumCompl) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.SumMan) <> 0
		|	OR SUM(T.AITAmount) <> 0
		|";
	#EndRegion
	
	#Region ExpenseAllocationToFinancialResult_7
	QueryText = QueryText + "
		|UNION ALL
		|
		// Allocation of expenses for Profitability&costs and other areas of disposal.
		|SELECT
		|	""7"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	FALSE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	&BeginOfPeriod AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	T.Organization AS CorCompany,
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CorCharacteristics,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	UNDEFINED AS BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.Sum END) AS AmountIncludingVAT,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.AmountExcludingVAT END) AS AmountExcludingVAT,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.SumCompl END) AS SumCompl,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		// If there was no TA amount distribution in the previous period, then the Local amount will be used as the distribution base,
		// with the same distribution options in TA and Local accounting, except for the distribution of expenses for the financial result.
		|		WHEN (T.SumCompl - T.PermanentDifference - T.CostTD) = 0
		|		 AND ARTICLES__.CostAllocationOptionLocal = ARTICLES__.CostAllocationOptionTax
		|		 AND ARTICLES__.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)
		|			THEN T.SumCompl
		|		ELSE T.SumCompl - T.PermanentDifference - T.CostTD END) AS AmountFA,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.SumMan END) AS SumMan,
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.AITAmount END) AS AITAmount
		|FROM
		|	TTOtherExpensesLastPeriodEndOfPeriodLimited AS T
		|
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = T.ExpenseItem
		|
		|WHERE
		|	VALUETYPE(T.Recorder) <> TYPE(Document.CostCalculationRecorder)
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.FixedAssetsInitialRecognition),
		|		VALUE(Enum.BusinessTransactions.IntangibleAssetsInitialRecognition),
		|		VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation),
		|		VALUE(Enum.BusinessTransactions.WriteOffRoundingErrors))
		// We exclude the Registered Records that are selected in queries 1, 3, and 5.
		|	AND NOT TRUE IN (SELECT TOP 1 TRUE
		|					FROM AccumulationRegister.InventoryCost AS Cost_
		|					WHERE (Cost_.Period = T.Period)
		|						AND (Cost_.RecordType = VALUE(AccumulationRecordType.Receipt))
		|						AND (Cost_.Recorder = T.Recorder)
		|						AND (Cost_.BusinessTransactionSetting = T.BusinessTransactionSetting)
		|						AND (Cost_.FinRecordID = T.FinRecordID)
		|					)
		|	AND NOT TRUE IN (SELECT TOP 1 TRUE
		|					FROM AccumulationRegister.RevenueAndCOGS AS Sales
		|					WHERE (Sales.Period = T.Period)
		|						AND (Sales.Recorder = T.Recorder)
		|						AND (Sales.BusinessTransactionSetting = T.BusinessTransactionSetting)
		|						AND (Sales.FinRecordID = T.FinRecordID)
		|						AND (Sales.SellingExpensesIncludingVAT = T.Sum)
		|						AND (Sales.SellingExpensesLocal = T.SumCompl)
		|						AND (Sales.SellingExpensesMan = T.SumMan)
		|					)
		|	AND NOT TRUE IN (SELECT TOP 1 TRUE
		|					FROM AccumulationRegister.OtherWorkInProgressExpenses AS OtherExpensesOfUnfinishedProduction
		|					WHERE (OtherExpensesOfUnfinishedProduction.Period = T.Period)
		|						AND (OtherExpensesOfUnfinishedProduction.RecordType = VALUE(AccumulationRecordType.Receipt))
		|						AND (OtherExpensesOfUnfinishedProduction.Recorder = T.Recorder)
		|						AND (OtherExpensesOfUnfinishedProduction.BusinessTransactionSetting = T.BusinessTransactionSetting)
		|						AND (OtherExpensesOfUnfinishedProduction.FinRecordID = T.FinRecordID)
		|					)
		|
		|GROUP BY
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes
		|	T.DebitBusinessUnit,
		|	T.CorLineOfBusiness,
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.Sum END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.AmountExcludingVAT END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.SumCompl END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.SumCompl - T.PermanentDifference - T.CostTD END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.SumMan END) <> 0
		|	OR SUM(CASE
		|		WHEN ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|			THEN 0
		|		ELSE T.AITAmount END) <> 0
		|";
	#EndRegion
	
	#Region DeferredExpensesAllocation_8
	QueryText = QueryText + "
		|UNION ALL
		|
		// Distribution of expenses of future periods.
		|SELECT
		|	""8"" AS RequestSource,
		|	FALSE AS ThisIsCurrentPeriod,
		|	FALSE AS ThereIsCorPart,
		|	UNDEFINED AS Recorder,
		|	(CASE
		|		WHEN T.Period > &BeginOfPeriod THEN T.Period
		|		ELSE &BeginOfPeriod END) AS Period,
		|	T.MonthPeriod AS DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		// Cor Attributes of deviations
		|	T.Organization AS CorCompany,
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CorCharacteristics,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.DebitBusinessUnit AS DebitBusinessUnit,
		|	UNDEFINED AS BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		|
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
		|	UNDEFINED AS SalesOrder,
		|	UNDEFINED AS ProductCostElement,
		|	UNDEFINED AS RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Sum) AS AmountIncludingVAT,
		|	SUM(T.AmountExcludingVAT) AS AmountExcludingVAT,
		|	SUM(T.SumCompl) AS SumCompl,
		|	SUM(T.SumCompl - T.PermanentDifference - T.CostTD) AS AmountFA,
		|	SUM(T.SumMan) AS SumMan,
		|	SUM(T.AITAmount) AS AITAmount
		|FROM
		|	TTOtherExpensesForPreviousPeriod AS T
		|WHERE
		|	T.BusinessOperation = VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation)
		|	AND VALUETYPE(T.Recorder) = TYPE(Document.DeferredExpensesAllocation)
		|GROUP BY
		|	(CASE
		|		WHEN T.Period > &BeginOfPeriod THEN T.Period
		|		ELSE &BeginOfPeriod END), // Period
		|	T.MonthPeriod,
		// Dimensions
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		// Cor Attributes
		|	T.DebitBusinessUnit,
		|	T.CorLineOfBusiness,
		|	T.CorExpenseItem,
		|	T.CorExpenditureDimension,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|HAVING
		|	SUM(T.Sum) <> 0
		|	OR SUM(T.AmountExcludingVAT) <> 0
		|	OR SUM(T.SumCompl) <> 0
		|	OR SUM(T.PermanentDifference) <> 0
		|	OR SUM(T.CostTD) <> 0
		|	OR SUM(T.SumMan) <> 0
		|	OR SUM(T.AITAmount) <> 0
		|";
	#EndRegion
	
	QueryText = QueryText + "
		|INDEX BY
		|	DistributionPeriod,
		|	Organization,
		|	Department,
		|	LineOfBusiness,
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Lot,
		|	ProductCostElement
		|	
		|";
		
	Return QueryText;
		
EndFunction	

Function TextTTNodesAdjustmentsOfPreviousPeriodsPreliminary() // TT vtuzlykorrectirovkiproslykhperiodovprevious
	// The sampling should be similar to the sampling for the mean-sliding function
	// The texturecorrection of the past few periods of the previous worship().
	Return "
		|SELECT
		|	T.Period AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	T.CountOpeningBalance AS CountOpeningBalance,
		|	T.CountClosingBalance AS CountClosingBalance,
		|	T.CountReceipt AS CountReceipt
		|
		|INTO TTNodesOfAdjustmentOfPastPeriodsPreliminary
		|FROM
		|	AccumulationRegister.InventoryCost.BalanceAndTurnovers(&MinimumPastPeriod, &BeginOfPeriod, Month, ,
		|		Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods) 
		|		AND NOT Organization IN (&MediumSlipOrganizations)
		|		AND &MinimumPastPeriod <> &EndOfPreviousPeriod
		|	) AS T
		|WHERE
		|	T.CountOpeningBalance <> 0
		|	OR T.CountReceipt <> 0
		|
		|UNION ALL
		|
		// From the quantity in the node we subtract the write-off at a fixed cost.
		// There is no allocation of expenses for issues at a fixed cost. 
		|SELECT
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	0 AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	-SUM(T.Count) AS CountReceipt
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND NOT T.Organization IN (&MediumSlipOrganizations)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND T.Count <> 0
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	T.ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.StorageLocation,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|
		|UNION ALL
		|
		// The amount in the node is increased by the amount written off by changing the valuation method.
		|SELECT
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	0 AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	-SUM(T.Count) AS CountReceipt
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods)
		|	AND NOT T.Organization IN (&MediumSlipOrganizations)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND T.Count < 0
		|	AND T.EntryType = VALUE(Enum.LotRecordTypes.InternalChangingPriceEvaluationMethod)
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	T.ItemsLocationAttributes,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.StorageLocation,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|";
EndFunction

Function TextTTNodesAdjustmentsOfPreviousPeriodsGrouped() // TT vtuzlykorrection of the past periodsgrouped
	Return "
		|SELECT
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	SUM(T.CountOpeningBalance) AS CountOpeningBalance,
		|	SUM(T.CountClosingBalance) AS CountClosingBalance,
		|	SUM(T.CountReceipt) AS CountReceipt
		|
		|INTO TTNodesAdjustmentsOfPastPeriodsGrouped
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriodsPreliminary AS T
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TextTTNodesAdjustmentsOfPreviousPeriods() // TT vtuzlykorrection of the past few periods
	// The sample should be similar to the sample for the
	// average slip in the function of the texturecorrection of the previous periods of adoration().
	Return "
		|SELECT
		|	T.DistributionPeriod AS DistributionPeriod,
		|	MAX(ISNULL(T2.DistributionPeriod, UNDEFINED)) AS DistributionPeriodPrevious,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|	T.CountOpeningBalance AS CountOpeningBalance,
		|	T.CountClosingBalance AS CountClosingBalance,
		|	T.CountReceipt AS CountReceipt
		|
		|INTO TTNodesOfAdjustmentOfPastPeriods
		|FROM
		|	TTNodesAdjustmentsOfPastPeriodsGrouped AS T
		|	LEFT JOIN TTNodesAdjustmentsOfPastPeriodsGrouped AS T2
		|		ON T.ItemsLocationAttributes = T2.ItemsLocationAttributes
		|		AND T.AccountingSection = T2.AccountingSection
		|		AND T.Organization = T2.Organization
		|		AND T.InventoryOwnerAttribute = T2.InventoryOwnerAttribute
		|		AND T.Lot = T2.Lot
		|		AND T.LotVendorAttributes = T2.LotVendorAttributes
		|		AND T.FinancialAccountingDimension = T2.FinancialAccountingDimension
		|		AND T.VATActivityType = T2.VATActivityType
		|		AND T.DistributionPeriod > T2.DistributionPeriod
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.CountOpeningBalance,
		|	T.CountClosingBalance,
		|	T.CountReceipt
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TextTTNodesOfExpensesOfPreviousPeriodsPreliminary() // TT Textthe cost nodes of the past periodpreservative
	Return "
		|SELECT
		|	UNDEFINED AS Ref,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionManag,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionLocal,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionTax
		|	
		|INTO TTObjectsOfCostOccurrence
		|
		|UNION ALL
		|
		|SELECT
		|	ConstCenter.Ref,
		|	ConstCenter.CostAllocationOptionManag,
		|	ConstCenter.CostAllocationOptionLocal,
		|	ConstCenter.CostAllocationOptionTax
		|FROM
		|	Catalog.CostCenters AS ConstCenter
		|
		|INDEX BY
		|	Ref
		|;
		|SELECT
		|	""1"" AS RequestSource,
		|	0 AS NodeNumberOfAdditionalExpenseAmount,
		|	T.Period AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumOpeningBalance END) AS SumOpeningBalance,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.AmountExcludingVATOpeningBalance END) AS AmountExcludingVATOpeningBalance,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumComplOpeningBalance END) AS SumComplOpeningBalance,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionTax, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumComplOpeningBalance
		|			-T.PermanentDifferenceOpeningBalance
		|			-T.CostTDOpeningBalance END) AS AmountFAOpeningBalance,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumManOpeningBalance END) AS SumManOpeningBalance,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumReceipt END) AS SumReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.AmountExcludingVATReceipt END) AS AmountExcludingVATReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumComplReceipt END) AS SumComplReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionTax, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		// If there was no TA amount distribution in the previous period, then the Local amount will be used as the distribution base,
		// with the same distribution options in TA and Local accounting.
		|		WHEN (T.SumComplReceipt - T.PermanentDifferenceReceipt - T.CostTDReceipt) = 0
		|		 AND AssetRef.CostAllocationOptionLocal = AssetRef.CostAllocationOptionTax
		|			THEN T.SumComplReceipt
		|		ELSE T.SumComplReceipt - T.PermanentDifferenceReceipt - T.CostTDReceipt END) AS AmountFAReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN 0
		|		ELSE T.SumManReceipt END) AS SumManReceipt
		|
		|INTO TTNodesOfExpensesOfPreviousPeriodsPreliminary
		|FROM
		|	AccumulationRegister.OtherExpenses.BalanceAndTurnovers(&MinimumPastPeriod, &EndOfPreviousPeriod, Month, ,
		|		Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods) 
		|		AND &MinimumPastPeriod <> &EndOfPreviousPeriod
		|		AND (Organization, Department, LineOfBusiness, ExpenseItem, DimensionOfExpenses) IN (
		|			SELECT
		|				Filter.Organization,
		|				Filter.Department,
		|				Filter.LineOfBusiness,
		|				Filter.ExpenseItem,
		|				Filter.DimensionOfExpenses
		|			FROM
		|				TTUsedExpensesByPeriod AS Filter)
		|	) AS T
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|		ON AssetRef.Ref = T.ExpenseItem
		|	LEFT JOIN TTObjectsOfCostOccurrence AS ConstCenter
		|		ON ConstCenter.Ref = T.DimensionOfExpenses
		|
		|UNION ALL
		|
		// Expenses of future periods.
		|SELECT
		|	""2"" AS RequestSource,
		|	0 AS NodeNumberOfAdditionalExpenseAmount,
		|	T.Period AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	0 AS SumOpeningBalance,
		|	0 AS AmountExcludingVATOpeningBalance,
		|	0 AS SumComplOpeningBalance,
		|	0 AS AmountFAOpeningBalance,
		|	0 AS SumManOpeningBalance,
		// For expenses of future periods, the initial cost in the node is determined by the amount of the expense - the amount of the distribution of the RBP.
		// The initial Balance of the RBP does not make sense for the purposes of the distribution of deviations, because it may include 
		// previously distributed deviations and this will violate the proportion of distribution coefficients.
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN T.Sum
		|		ELSE 0 END) AS SumReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN T.AmountExcludingVAT
		|		ELSE 0 END) AS AmountExcludingVATReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN T.SumCompl
		|		ELSE 0 END) AS SumComplReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionTax, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN T.SumCompl - T.PermanentDifference - T.CostTD
		|		ELSE 0 END) AS AmountFAReceipt,
		|	(CASE
		|		WHEN AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|		 OR ISNULL(ConstCenter.CostAllocationOptionManag, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
		|			THEN T.SumMan
		|		ELSE 0 END) AS SumManReceipt
		|FROM
		|	AccumulationRegister.OtherExpenses AS T
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|		ON AssetRef.Ref = T.ExpenseItem
		|	LEFT JOIN TTObjectsOfCostOccurrence AS ConstCenter
		|		ON ConstCenter.Ref = T.DimensionOfExpenses
		|WHERE
		|	T.Period >= &MinimumPastPeriod
		|	AND T.Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods) 
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation)
		|	AND VALUETYPE(T.Recorder) = TYPE(Document.DeferredExpensesAllocation) 
		|	AND (T.Organization, T.Department, T.LineOfBusiness, T.ExpenseItem, T.DimensionOfExpenses) IN (
		|		SELECT
		|			Filter.Organization,
		|			Filter.Department,
		|			Filter.LineOfBusiness,
		|			Filter.ExpenseItem,
		|			Filter.DimensionOfExpenses
		|		FROM
		|			TTUsedExpensesByPeriod AS Filter)
		|
		|UNION ALL
		|
		|SELECT
		|	""3"" AS RequestSource,
		|	T.NodeNumber AS NodeNumberOfAdditionalExpenseAmount,
		|	BEGINOFPERIOD(T.ReceiptPeriod, MONTH) AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	0 AS SumOpeningBalance,
		|	0 AS AmountExcludingVATOpeningBalance,
		|	0 AS SumComplOpeningBalance,
		|	0 AS AmountFAOpeningBalance,
		|	0 AS SumManOpeningBalance,
		|	T.WeightWithVAT 	AS SumReceipt,
		|	T.WeightWithoutVAT AS AmountExcludingVATReceipt,
		|	T.LocalWeight	AS SumComplReceipt,
		|	T.WeightTA		AS AmountFAReceipt,
		|	T.ManSWeight	AS SumManReceipt
		|FROM
		|	AdditionalCostAdjustmentNodes AS T
		|WHERE
		|	BEGINOFPERIOD(T.ReceiptPeriod, MONTH) < &BeginOfPeriod
		|	AND (T.WeightWithVAT <> 0
		|		OR T.WeightWithoutVAT <> 0
		|		OR T.LocalWeight <> 0
		|		OR T.WeightTA <> 0
		|		OR T.ManSWeight <> 0)
		|
		|UNION ALL
		|
		|SELECT
		|	""4"" AS RequestSource,
		|	0 AS NodeNumberOfAdditionalExpenseAmount,
		|	T.Period AS DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.ProductionLot AS Lot,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.CostOpeningBalance				AS SumOpeningBalance,
		|	T.CostExcludingVATOpeningBalance		AS AmountExcludingVATOpeningBalance,
		|	T.LocalCostOpeningBalance			AS SumComplOpeningBalance,
		|	T.LocalCostOpeningBalance
		|		-T.PermanentDifferenceOpeningBalance
		|		-T.CostTDOpeningBalance AS AmountFAOpeningBalance,
		|	T.CostManOpeningBalance				AS SumManOpeningBalance,
		|	T.CostReceipt						AS SumReceipt,
		|	T.CostExcludingVATReceipt					AS AmountExcludingVATReceipt,
		|	T.LocalCostReceipt					AS SumComplReceipt,
		|	T.LocalCostReceipt
		|		-T.PermanentDifferenceReceipt
		|		-T.CostTDReceipt			AS AmountFAReceipt,
		|	T.CostManReceipt					AS SumManReceipt
		|FROM
		|	AccumulationRegister.OtherWorkInProgressExpenses.BalanceAndTurnovers(&MinimumPastPeriod, &EndOfPreviousPeriod, Month, ,
		|		Organization IN (&CompaniesWithDistributionOfDeviationsInPastPeriods) 
		|		AND &MinimumPastPeriod <> &EndOfPreviousPeriod
		|		AND (Organization, ExpenseItem, DimensionOfExpenses) IN (
		|			SELECT
		|				Filter.Organization,
		|				Filter.ExpenseItem,
		|				Filter.DimensionOfExpenses
		|			FROM
		|				TTUsedExpensesByPeriodCollapsed AS Filter)
		|		AND (&ProductionLotReferenceForSelection = UNDEFINED
		|			OR ProductionLot = &ProductionLotReferenceForSelection)
		|	) AS T
		|WHERE
		|	T.CostOpeningBalance <> 0
		|	OR T.LocalCostOpeningBalance <> 0
		|	OR T.PermanentDifferenceOpeningBalance <> 0
		|	OR T.CostTDOpeningBalance <> 0
		|	OR T.CostManOpeningBalance <> 0
		|	OR T.CostReceipt <> 0
		|	OR T.LocalCostReceipt <> 0
		|	OR T.PermanentDifferenceReceipt <> 0
		|	OR T.CostTDReceipt <> 0
		|	OR T.CostManReceipt <> 0
		|
		|INDEX BY
		|	Organization,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|";
EndFunction

Function TextTTNodesOfExpensesOfPreviousPeriods() // TTNodesOfExpensesOfPreviousPeriods
	Return "
		|SELECT
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	MAX(ISNULL(T2.DistributionPeriod, UNDEFINED)) AS DistributionPeriodPrevious,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.Lot AS Lot,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.SumOpeningBalance AS SumOpeningBalance,
		|	T.AmountExcludingVATOpeningBalance AS AmountExcludingVATOpeningBalance,
		|	T.SumComplOpeningBalance AS SumComplOpeningBalance,
		|	T.AmountFAOpeningBalance AS AmountFAOpeningBalance,
		|	T.SumManOpeningBalance AS SumManOpeningBalance,
		|	T.SumReceipt AS SumReceipt,
		|	T.AmountExcludingVATReceipt AS AmountExcludingVATReceipt,
		|	T.SumComplReceipt AS SumComplReceipt,
		|	T.AmountFAReceipt AS AmountFAReceipt,
		|	T.SumManReceipt AS SumManReceipt
		|
		|INTO TTNodesOfExpensesOfPreviousPeriods
		|FROM
		|	TTNodesOfExpensesOfPreviousPeriodsPreliminary AS T
		|
		|	LEFT JOIN TTNodesOfExpensesOfPreviousPeriodsPreliminary AS T2
		|		ON T.Organization = T2.Organization
		|		AND T.Department = T2.Department
		|		AND T.LineOfBusiness = T2.LineOfBusiness
		|		AND T.ExpenseItem = T2.ExpenseItem
		|		AND T.DimensionOfExpenses = T2.DimensionOfExpenses
		|		AND T.Lot = T2.Lot
		|		AND T.ProductCostElement = T2.ProductCostElement
		|		AND T.DistributionPeriod > T2.DistributionPeriod
		|		AND T.DistributionPeriod <> DATETIME(1,1,1)
		|
		|GROUP BY
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	T.DistributionPeriod,
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.Lot,
		|	T.ProductCostElement,
		|	T.SumOpeningBalance,
		|	T.AmountExcludingVATOpeningBalance,
		|	T.SumComplOpeningBalance,
		|	T.AmountFAOpeningBalance,
		|	T.SumManOpeningBalance,
		|	T.SumReceipt,
		|	T.AmountExcludingVATReceipt,
		|	T.SumComplReceipt,
		|	T.AmountFAReceipt,
		|	T.SumManReceipt
		|
		|INDEX BY
		|	Organization,
		|	ExpenseItem,
		|	DimensionOfExpenses
		|";
EndFunction

Function TextTTNodesOfDeviationsAreArticleByArticle() // TTNodesOfDeviationsAreArticleByArticle
	Return "
		|SELECT
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	ISNULL(DeviationsToDistribution.VariancePeriod, T.DistributionPeriod) AS VariancePeriod,
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.Lot AS Lot,
		|
		|	T.ProductCostElement AS ProductCostElement,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	(T.Lot <> UNDEFINED) AS ThisIsUnfinishedPRODUCTION,
		|
		|	ISNULL(DeviationsToDistribution.Sum, 0) AS CostVariancesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.AmountExcludingVAT, 0) AS CostVariancesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.SumCompl, 0) AS CostVariancesLocal,
		|	ISNULL(DeviationsToDistribution.SumMan, 0) AS CostVariancesMgmt,
		|
		|	ISNULL(NodesOfAdditionalExpenses.CostInclVAT, 0)
		|		+ ISNULL(CostOfNodes.AdditionalExpensesIncludingVAT, 0) AS AdditionalExpensesIncludingVAT,
		|	ISNULL(NodesOfAdditionalExpenses.CostExcludingVAT, 0)
		|		+ ISNULL(CostOfNodes.AdditionalExpensesExcludingVAT, 0) AS AdditionalExpensesExcludingVAT,
		|	ISNULL(NodesOfAdditionalExpenses.LocalCost, 0)
		|		+ ISNULL(CostOfNodes.AddExpensesLocal, 0) AS AddExpensesLocal,
		|	ISNULL(NodesOfAdditionalExpenses.CostMan, 0)
		|		+ ISNULL(CostOfNodes.AddExpensesMan, 0) AS AddExpensesMan,
		|	ISNULL(DeviationsToDistribution.PermanentDifference, 0)
		|		+ ISNULL(NodesOfAdditionalExpenses.PermanentDifference, 0) AS PermanentDifference,
		|	ISNULL(DeviationsToDistribution.AmountFA, 0)
		|		+ ISNULL(NodesOfAdditionalExpenses.CostInTaxAccounting, 0) AS CostInTaxAccounting,
		|	ISNULL(DeviationsToDistribution.AIT, 0)
		|		+ ISNULL(NodesOfAdditionalExpenses.CostOfPersonalIncomeTax, 0) AS AIT,
		|
		|	0 AS Count,
		|	T.SumOpeningBalance + T.SumReceipt AS NumberWithVAT,
		|	T.AmountExcludingVATOpeningBalance + T.AmountExcludingVATReceipt AS QuantityWithoutVAT,
		|	T.SumComplOpeningBalance + T.SumComplReceipt AS NumberOfLocal,
		|	T.AmountFAOpeningBalance + T.AmountFAReceipt AS NumberOfTA,
		|	T.SumManOpeningBalance + T.SumManReceipt AS NumberOfMen
		|
		|INTO TTNodesOfDeviationsAreArticleByArticle
		|FROM
		|	TTNodesOfExpensesOfPreviousPeriods AS T
		|
		|	LEFT JOIN TTDeviationsOtherExpensesToBeAllocated AS DeviationsToDistribution
		|		ON T.DistributionPeriod = DeviationsToDistribution.VariancePeriod
		|		AND T.Organization = DeviationsToDistribution.Organization
		|		AND T.Department = DeviationsToDistribution.Department
		|		AND T.LineOfBusiness = DeviationsToDistribution.LineOfBusiness
		|		AND T.ExpenseItem = DeviationsToDistribution.ExpenseItem
		|		AND T.DimensionOfExpenses = DeviationsToDistribution.DimensionOfExpenses
		|		AND T.Lot = UNDEFINED
		|
		|	LEFT JOIN AdditionalCostAdjustmentNodes AS NodesOfAdditionalExpenses
		|		ON NodesOfAdditionalExpenses.NodeNumber = T.NodeNumberOfAdditionalExpenseAmount
		|
		|	LEFT JOIN InitialCostOfAdditionalExpenses AS CostOfNodes
		|		ON CostOfNodes.NodeNumber = T.NodeNumberOfAdditionalExpenseAmount
		|";
EndFunction

Function TextTTNodesOfDeviationsPreliminary() // TTNodesOfDeviationsPreliminary
	Return "
		|SELECT
		|	""1"" AS RequestSource,
		|	0 AS NodeNumberOfAdditionalExpenseAmount,
		|	ISNULL(DeviationsToDistribution.VariancePeriod, T.DistributionPeriod) AS VariancePeriod,
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.AccountingSection AS AccountingSection,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	UNDEFINED AS ProductCostElement,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	FALSE AS TheseAreArticleByArticle,
		|	FALSE AS ThisIsUnfinishedPRODUCTION,
		|
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesIncludingVAT, 0) AS CostVariancesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesExcludingVAT, 0) AS CostVariancesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.AddExpensesLocal, 0) AS CostVariancesLocal,
		|	ISNULL(DeviationsToDistribution.AddExpensesMan, 0) AS CostVariancesMgmt,
		|	0 AS AdditionalExpensesIncludingVAT,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	ISNULL(DeviationsToDistribution.PermanentDifference, 0) AS PermanentDifference,
		|	ISNULL(DeviationsToDistribution.CostInTaxAccounting, 0) AS CostInTaxAccounting,
		|	ISNULL(DeviationsToDistribution.AIT, 0) AS AIT,
		|
		|	T.CountOpeningBalance + T.CountReceipt AS Count,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberWithVAT,
		|	T.CountOpeningBalance + T.CountReceipt AS QuantityWithoutVAT,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfLocal,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfTA,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfMen
		|
		|INTO TTNodesOfDeviationsPreliminary
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriods AS T
		|
		|	LEFT JOIN TTOfDeviationToDistribution AS DeviationsToDistribution
		|		ON T.DistributionPeriod = DeviationsToDistribution.VariancePeriod
		|		AND T.ItemsLocationAttributes = DeviationsToDistribution.ItemsLocationAttributes
		|		AND T.AccountingSection = DeviationsToDistribution.AccountingSection
		|		AND T.Organization = DeviationsToDistribution.Organization
		|		AND T.InventoryOwnerAttribute = DeviationsToDistribution.InventoryOwnerAttribute
		|		AND T.Lot = DeviationsToDistribution.Lot
		|		AND T.LotVendorAttributes = DeviationsToDistribution.LotVendorAttributes
		|		AND T.FinancialAccountingDimension = DeviationsToDistribution.FinancialAccountingDimension
		|		AND T.VATActivityType = DeviationsToDistribution.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	""2"" AS RequestSource,
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	T.VariancePeriod,
		|	T.DistributionPeriod,
		|	T.Organization AS Organization,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	UNDEFINED AS Products,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		|
		|	T.ProductCostElement AS ProductCostElement,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	TRUE AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION,
		|
		|	T.CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT,
		|	T.CostVariancesLocal,
		|	T.CostVariancesMgmt,
		|
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|
		|	0 AS Count,
		|	T.NumberWithVAT,
		|	T.QuantityWithoutVAT,
		|	T.NumberOfLocal,
		|	T.NumberOfTA,
		|	T.NumberOfMen
		|FROM
		|	TTNodesOfDeviationsAreArticleByArticle AS T
		|WHERE
		|	NOT T.Organization IN (&MediumSlipOrganizations)
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TextTTNodesOfDeviationsNumbered() // TT vtuzlyotkloneniy Numbered
	Return "
		|SELECT
		|	MAX(T.NodeNumber) AS NodeNumber
		|INTO MaximumNodeNumbersOfAdditionalExpenses
		|FROM
		|	AdditionalCostAdjustmentNodes AS T
		|;
		|SELECT TOP 9999999999999
		|	RECORDAUTONUMBER() AS NodeNumberIsPreliminary,
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	0 AS NodeNumberArticleByArticle,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	T.ProductCostElement AS ProductCostElement,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.TheseAreArticleByArticle AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	T.CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT,
		|	T.CostVariancesLocal,
		|	T.CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|	T.Count AS Count,
		|	T.NumberWithVAT AS NumberWithVAT,
		|	T.QuantityWithoutVAT AS QuantityWithoutVAT,
		|	T.NumberOfLocal AS NumberOfLocal,
		|	T.NumberOfTA AS NumberOfTA,
		|	T.NumberOfMen AS NumberOfMen
		|
		|INTO TTDeviationNodesNumbered
		|FROM
		|	TTNodesOfDeviationsPreliminary AS T
		|
		|ORDER BY
		|	T.NodeNumberOfAdditionalExpenseAmount,
		|	T.DistributionPeriod,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.InventoryOwnerAttribute,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|
		|INDEX BY
		|	NodeNumberIsPreliminary
		|";
EndFunction

Function TextCoefficientsOfReductionOfDeviationNodes() // TT is the coefficient of adoration of nodesreferences
	
	QueryText = "
		|SELECT
		// The node number field should be defined in the same way as the requests for Text Nodes() and Text Nodes()
		|	(CASE
		|		WHEN DD.NodeNumberOfAdditionalExpenseAmount <> 0 THEN DD.NodeNumberOfAdditionalExpenseAmount
		|		WHEN DD.NodeNumberArticleByArticle > 0 THEN DD.NodeNumberArticleByArticle
		|		ELSE DD.NodeNumberIsPreliminary + ISNULL(NodeNumbers.NodeNumber, 0) END) AS NodeNumber,
		|	DD.NodeNumberIsPreliminary AS NodeNumberIsPreliminary,
		// To correctly calculate the price, the total amount of the distribution base should not exceed 1,000
		// , the calculation is performed as follows: when distributing 100 rubles, the price must contain all decimal places.
		|	CASE
		|		WHEN SUM(DD.NumberWithVAT) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.NumberWithVAT) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.NumberWithVAT) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.NumberWithVAT) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.NumberWithVAT) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.NumberWithVAT) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientWithVAT,
		|	CASE
		|		WHEN SUM(DD.QuantityWithoutVAT) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.QuantityWithoutVAT) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.QuantityWithoutVAT) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.QuantityWithoutVAT) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.QuantityWithoutVAT) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.QuantityWithoutVAT) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientWithoutVAT,
		|	CASE
		|		WHEN SUM(DD.NumberOfLocal) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.NumberOfLocal) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.NumberOfLocal) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.NumberOfLocal) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.NumberOfLocal) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.NumberOfLocal) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS LocalCoefficient,
		|	CASE
		|		WHEN SUM(DD.NumberOfMen) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.NumberOfMen) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.NumberOfMen) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.NumberOfMen) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.NumberOfMen) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.NumberOfMen) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS ManSCoefficient,
		|	CASE
		|		WHEN SUM(DD.NumberOfTA) > 1000000000
		|	 		THEN 1000000
		|		WHEN SUM(DD.NumberOfTA) > 100000000
		|	 		THEN 100000
		|		WHEN SUM(DD.NumberOfTA) > 10000000
		|	 		THEN 10000
		|		WHEN SUM(DD.NumberOfTA) > 1000000
		|	 		THEN 1000
		|		WHEN SUM(DD.NumberOfTA) > 100000
		|	 		THEN 100
		|		WHEN SUM(DD.NumberOfTA) > 10000
		|	 		THEN 10
		|		ELSE 1
		|	END AS CoefficientIsTA
		|
		|INTO CoefficientsOfReductionOfNodesOfDeviations
		|FROM
		|	TTDeviationNodesNumbered AS DD
		|	LEFT JOIN MaximumNodeNumbersOfAdditionalExpenses AS NodeNumbers
		|		ON TRUE
		|WHERE
		|	DD.TheseAreArticleByArticle
		|
		|GROUP BY
		|	(CASE
		|		WHEN DD.NodeNumberOfAdditionalExpenseAmount <> 0 THEN DD.NodeNumberOfAdditionalExpenseAmount
		|		WHEN DD.NodeNumberArticleByArticle > 0 THEN DD.NodeNumberArticleByArticle
		|		ELSE DD.NodeNumberIsPreliminary + ISNULL(NodeNumbers.NodeNumber, 0) END), // NodeNumber
		|	DD.NodeNumberIsPreliminary
		|
		|INDEX BY
		|	NodeNumberIsPreliminary
		|";

	Return QueryText;
		
EndFunction

Function TextTTNodesOfDeviations() // TT vtuzlyotreferences
	Return "
		|SELECT TOP 9999999999999
		// The Node number field should be defined in the same way as the query for the Adoration textreferences().
		|	(CASE
		|		WHEN T.NodeNumberOfAdditionalExpenseAmount <> 0 THEN T.NodeNumberOfAdditionalExpenseAmount
		|		ELSE T.NodeNumberIsPreliminary + ISNULL(NodeNumbers.NodeNumber, 0) END) AS NodeNumber,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		|
		|	T.ProductCostElement AS ProductCostElement,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	T.CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT,
		|	T.CostVariancesLocal,
		|	T.CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|	T.Count AS Count,
		|	CAST(T.NumberWithVAT / ISNULL(ReductionCoefficients.CoefficientWithVAT, 1) AS NUMBER (23,10)) AS NumberWithVAT,
		|	CAST(T.QuantityWithoutVAT / ISNULL(ReductionCoefficients.CoefficientWithoutVAT, 1) AS NUMBER (23,10)) AS QuantityWithoutVAT,
		|	CAST(T.NumberOfLocal / ISNULL(ReductionCoefficients.LocalCoefficient, 1) AS NUMBER (23,10)) AS NumberOfLocal,
		|	CAST(T.NumberOfTA / ISNULL(ReductionCoefficients.CoefficientIsTA, 1) AS NUMBER (23,10)) AS NumberOfTA,
		|	CAST(T.NumberOfMen / ISNULL(ReductionCoefficients.ManSCoefficient, 1) AS NUMBER (23,10)) AS NumberOfMen
		|
		|INTO TTNodesOfDeviations
		|FROM
		|	TTDeviationNodesNumbered AS T
		|
		|	LEFT JOIN MaximumNodeNumbersOfAdditionalExpenses AS NodeNumbers
		|		ON TRUE
		|	LEFT JOIN CoefficientsOfReductionOfNodesOfDeviations AS ReductionCoefficients
		|		ON ReductionCoefficients.NodeNumberIsPreliminary = T.NodeNumberIsPreliminary
		|
		|ORDER BY
		|	NodeNumber ASC
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TextTTNodesOtherExpensesUnfinishedProduction() // TTNodesOtherExpensesUnfinishedProduction
	Return "
		|SELECT
		|	T.NodeNumber AS NodeNumber
		|
		|INTO TTNodesOtherExpensesUnfinishedProduction
		|FROM
		|	TTNodesOfDeviations AS T
		|WHERE
		|	T.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND T.Lot <> UNDEFINED
		|
		|UNION ALL
		|
		|SELECT
		|	T.NodeNumber AS NodeNumber
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS T
		|WHERE
		|	T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|	AND T.Organization IN (&MediumSlipOrganizations)
		|
		|INDEX BY
		|	NodeNumber
		|
		|";
EndFunction

Function TextOfTTOfRegisteredRecordsOfInventoryCostsByPeriod() // TTOfRegisteredRecordsOfInventoryCostsByPeriod
	Return "
		|SELECT
		|	T.ThisIsCurrentPeriod,
		|	T.ThereIsCorPart,
		|	T.Period,
		|	T.DistributionPeriod,
		|	CAST(SourceNodes.NodeNumber AS NUMBER(31,0)) AS SourceNodeNumber,
		|	(CASE
		|		WHEN NOT NodesReceiversBranches.NodeNumber IS NULL
		|			THEN NodesReceiversBranches.NodeNumber
		|		WHEN NOT ReceiverNodes_.NodeNumber IS NULL
		|			THEN ReceiverNodes_.NodeNumber
		|		ELSE -1 END) AS ReceiverNodeNumber,
		|	SourceNodes.VariancePeriod AS DeviationPeriodSource,
		|	SourceNodes.DistributionPeriod AS DistributionPeriodSource,
		|	(CASE
		|		WHEN NOT NodesReceiversBranches.DistributionPeriod IS NULL
		|			THEN NodesReceiversBranches.DistributionPeriod
		|		WHEN NOT ReceiverNodes_.DistributionPeriod IS NULL
		|			THEN ReceiverNodes_.DistributionPeriod
		|		ELSE DATETIME(1,1,1) END) AS PeriodOfDistributionReceiver,
		// Dimensions
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.StorageLocation AS StorageLocation,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.Lot AS Lot,
		|	T.LotVendorAttributes AS LotVendorAttributes,
		|	T.FinancialAccountingDimension AS FinancialAccountingDimension,
		|	T.VATActivityType AS VATActivityType,
		// Cor Attributes
		|	T.CorAccountingSection AS CorAccountingSection,
		|	T.CorCompany AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorNomenclature AS CorNomenclature,
		|	T.CorCharacteristics AS CorCharacteristics,
		|	T.BoxStorageLocation AS BoxStorageLocation,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	T.CorLot AS CorLot,
		|	T.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	T.CorControllingAttributes AS CorControllingAttributes,
		|	T.CorVATActivityTypes AS CorVATActivityTypes,
		|
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.Department AS Department,
		|	T.Department AS DebitBusinessUnit,
		|	T.CorLineOfBusiness AS CorLineOfBusiness,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.WriteOffDeviationsToCostOfGoodsSelling,
		|	T.FinRecordID AS FinRecordID,
		|	T.Count AS Count
		|
		|INTO TTOfRegisteredRecordsOfInventoryCostsByPeriod
		|FROM
		|	TTRegisteredRecordsOfInventoryCostsByPeriodDetailed AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND SourceNodes.AccountingSection = T.AccountingSection
		|		AND SourceNodes.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Lot = T.Lot	
		|		AND SourceNodes.LotVendorAttributes = T.LotVendorAttributes
		|		AND SourceNodes.FinancialAccountingDimension = T.FinancialAccountingDimension
		|		AND SourceNodes.VATActivityType = T.VATActivityType
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriod
		|
		|	LEFT JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.ItemsLocationAttributes = T.CorItemsLocationAttributes
		|		AND ReceiverNodes_.AccountingSection = T.CorAccountingSection
		|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Lot = T.CorLot
		|		AND ReceiverNodes_.LotVendorAttributes = T.LotVendorAttributesCorr
		|		AND ReceiverNodes_.FinancialAccountingDimension = T.CorControllingAttributes
		|		AND ReceiverNodes_.VATActivityType = T.CorVATActivityTypes
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|
		|	LEFT JOIN TTNodesOfDeviations AS NodesReceiversBranches
		|		ON NodesReceiversBranches.ItemsLocationAttributes = T.CorItemsLocationAttributes
		|		AND NodesReceiversBranches.AccountingSection = T.CorAccountingSection
		|		AND T.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		AND NodesReceiversBranches.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND NodesReceiversBranches.Organization = T.CorCompany
		|		AND NodesReceiversBranches.Lot = T.CorLot
		|		AND NodesReceiversBranches.LotVendorAttributes = T.LotVendorAttributesCorr
		|		AND NodesReceiversBranches.FinancialAccountingDimension = T.CorControllingAttributes
		|		AND NodesReceiversBranches.VATActivityType = T.CorVATActivityTypes
		|		AND NodesReceiversBranches.DistributionPeriod = T.DistributionPeriod
		|		AND T.CorCompany <> T.Organization
		|		AND T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|
		|INDEX BY
		|	SourceNodeNumber
		|";
EndFunction	

Function TextTTOfRegisteredRecordedOtherExpensesByPeriod() // TT vtmovementprochierachievementsreferences
	Return "
		|SELECT
		|	SourceNodes.NodeNumber AS NodeNumber,
		|	T.ThisIsCurrentPeriod,
		|	T.ThereIsCorPart,
		|	T.Recorder,
		|	T.Period,
		|	T.DistributionPeriod,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.Lot,
		// Cor Attributes of deviations
		|	T.CorCompany,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation,
		// COR Cost Attributes
		|	T.CorAccountingSection,
		|	T.CorItemsLocationAttributes,
		|	T.CorLot,
		|	T.LotVendorAttributesCorr,
		|	T.CorControllingAttributes,
		|	T.CorVATActivityTypes,
		|
		|	T.AccountingDimensionByPartners,
		|	T.SalesOrder,
		|	T.ProductCostElement,
		|	T.RuleOfCostAllocatingToProductionLots,
		|	T.CorExpenseItem AS CorExpenseItem,
		|	T.CorExpenditureDimension AS CorExpenditureDimension,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	T.FinRecordID AS FinRecordID,
		|	CAST(T.AmountIncludingVAT / ISNULL(ReductionCoefficients.CoefficientWithVAT, 1) AS NUMBER (23,10)) AS AmountIncludingVAT,
		|	CAST(T.AmountExcludingVAT / ISNULL(ReductionCoefficients.CoefficientWithoutVAT, 1) AS NUMBER (23,10)) AS AmountExcludingVAT,
		|	CAST(T.SumCompl / ISNULL(ReductionCoefficients.LocalCoefficient, 1) AS NUMBER (23,10)) AS SumCompl,
		|	CAST(T.AmountFA / ISNULL(ReductionCoefficients.CoefficientIsTA, 1) AS NUMBER (23,10)) AS AmountFA,
		|	CAST(T.SumMan / ISNULL(ReductionCoefficients.ManSCoefficient, 1) AS NUMBER (23,10)) AS SumMan,
		|	CAST(T.AITAmount / ISNULL(ReductionCoefficients.CoefficientIsTA, 1) AS NUMBER (23,10)) AS AITAmount
		|
		|INTO RegisteredRecordsTTOtherExpensesByPeriod
		|FROM
		|	RegisteredRecordsTTOtherExpensesByPeriodPreliminary AS T
		|
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = T.Organization
		|		AND MinimumPeriods.VariancePeriod <= T.DistributionPeriod
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Department = T.Department
		|		AND SourceNodes.LineOfBusiness = T.LineOfBusiness
		|		AND SourceNodes.ExpenseItem = T.ExpenseItem
		|		AND SourceNodes.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND SourceNodes.Lot = T.Lot
		|		AND (SourceNodes.ProductCostElement = T.ProductCostElement
		|			OR T.Lot = UNDEFINED)
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriod
		|
		|	LEFT JOIN CoefficientsOfReductionOfNodesOfDeviations AS ReductionCoefficients
		|		ON ReductionCoefficients.NodeNumber = SourceNodes.NodeNumber
		|
		|INDEX BY
		|	Organization,
		|	Department,
		|	ExpenseItem
		|";
EndFunction	

Function TextOfTTOfRegisteredRecordsConnectionsOfInventoryCostsByPeriod() // vtvyaziotcleniipredivaration_1, uses vtmovementsestablished goods periods
	Return "
		|SELECT TOP 9999999999999
		|	""TextOfTTOfRegisteredRecordsConnectionsOfInventoryCostsByPeriod"" AS RequestSource,
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot AS Lot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.BoxStorageLocation,
		|	T.CorLot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriodSource AS DistributionPeriodSource,
		|	T.PeriodOfDistributionReceiver AS PeriodOfDistributionReceiver,
		|	FALSE AS TheseAreLeftovers,
		|	SUM(T.Count) AS Count,
		|	SUM(T.Count) AS NumberWithVAT,
		|	SUM(T.Count) AS QuantityWithoutVAT,
		|	SUM(CASE
		|		WHEN T.WriteOffDeviationsToCostOfGoodsSelling THEN 0
		|		ELSE T.Count END) AS NumberOfLocal,
		|	SUM(T.Count) AS NumberOfTA,
		|	SUM(CASE
		|		WHEN T.WriteOffDeviationsToCostOfGoodsSelling THEN 0
		|		ELSE T.Count END) AS NumberOfMen
		|
		|INTO DeviationTTCommunicationPreliminary
		|FROM
		|	TTOfRegisteredRecordsOfInventoryCostsByPeriod AS T
		|WHERE
		|	T.ThereIsCorPart
		|
		|GROUP BY
		|	T.SourceNodeNumber,
		|	T.ReceiverNodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.BoxStorageLocation,
		|	T.CorLot,
		|	T.DistributionPeriodSource,
		|	T.PeriodOfDistributionReceiver
		|";
EndFunction
	
Function TextWriteOffOfItemsForItemByItemExpenses() // vtvyaziotcleniipredivaria_2, uses vtmovementsestablished goods periods
	Return "
		// Write-off of items for item-by-item expenses.
		// The conditions for filling in the Quantity indicators must correspond to the functions of the texcommunication of additional spending nodes() and
		// textvtablitablesvyazationstateinesreferences() #The area of the textquestionmaterialstatistics.
		|SELECT
		|	""TextWriteOffOfItemsForItemByItemExpenses"" AS RequestSource,
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot AS Lot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	UNDEFINED AS BoxStorageLocation,	
		|	UNDEFINED AS CorLot,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriodSource AS DistributionPeriodSource,
		|	&BeginOfPeriod AS ReceiverAllocationPeriod,
		|	FALSE AS TheseAreLeftovers,
		|	SUM(T.Count) AS Count,
		|	SUM(T.Count) AS NumberWithVAT,
		|	SUM(T.Count) AS QuantityWithoutVAT,
		|	SUM(CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of sales 
		// , the item-by-item Local expenses are not taken into account in the cost of other expenses.
		|			WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|		ELSE T.Count END) AS NumberOfLocal,
		|	SUM(T.Count) AS NumberOfTA,
		|	SUM(CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of goods sold 
		// , item-by-item expenses of the Man are not taken into account in the cost of other expenses. 
		|			WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|		ELSE T.Count END) AS NumberOfMen
		|FROM
		|	TTOfRegisteredRecordsOfInventoryCostsByPeriod AS T
		|
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.LineOfBusiness = T.CorLineOfBusiness	
		|		AND ReceiverNodes_.Department = T.DebitBusinessUnit
		|		AND ReceiverNodes_.ExpenseItem = T.ExpenseItemOfWriteOff
		|		AND ReceiverNodes_.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND ReceiverNodes_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		AND ReceiverNodes_.Lot = UNDEFINED
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|		AND NOT ReceiverNodes_.ThisIsUnfinishedPRODUCTION
		|
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ItemsOfExpensesWriteOffs
		|		ON ItemsOfExpensesWriteOffs.Ref = T.ExpenseItemOfWriteOff
		|WHERE
		|	NOT T.ThereIsCorPart
		// Deviations in the cost of goods are not distributed among organizations in the management accounting of the enterprise.
		|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
		|
		|GROUP BY
		|	T.SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.DistributionPeriodSource,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot,
		|	T.ExpenseItemOfWriteOff
		|";
EndFunction
	
Function TextOfInventoryCostRelationshipBetweenPeriods() // In connection with the worship of the worshiping_3, uses the node to correct past periods, in the node of worship
	Return "
		// The relationship of the cost of goods between periods.
		|SELECT
		|	""TextOfInventoryCostRelationshipBetweenPeriods"" AS RequestSource,
		|	SourceNodes.NodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot AS Lot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	T.ItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.Products AS CorNomenclature,
		|	T.StorageLocation AS BoxStorageLocation,
		|	T.Lot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	SourceNodes.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	TRUE AS TheseAreLeftovers,
		|	SUM(T.CountOpeningBalance) AS Count,
		|	SUM(T.CountOpeningBalance) AS NumberWithVAT,
		|	SUM(T.CountOpeningBalance) AS QuantityWithoutVAT,
		|	SUM(T.CountOpeningBalance) AS NumberOfLocal,
		|	SUM(T.CountOpeningBalance) AS NumberOfTA,
		|	SUM(T.CountOpeningBalance) AS NumberOfMen
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriods AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND SourceNodes.AccountingSection = T.AccountingSection
		|		AND SourceNodes.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Lot = T.Lot	
		|		AND SourceNodes.LotVendorAttributes = T.LotVendorAttributes
		|		AND SourceNodes.FinancialAccountingDimension = T.FinancialAccountingDimension
		|		AND SourceNodes.VATActivityType = T.VATActivityType
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriodPrevious
		|		AND T.CountOpeningBalance <> 0
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.ItemsLocationAttributes = T.ItemsLocationAttributes
		|		AND ReceiverNodes_.AccountingSection = T.AccountingSection
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Lot = T.Lot	
		|		AND ReceiverNodes_.LotVendorAttributes = T.LotVendorAttributes
		|		AND ReceiverNodes_.FinancialAccountingDimension = T.FinancialAccountingDimension
		|		AND ReceiverNodes_.VATActivityType = T.VATActivityType
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|
		|GROUP BY
		|	SourceNodes.NodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot,
		|	SourceNodes.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction
	
Function TextOfRelationshipOfOtherExpensesBetweenPeriods() // vtvyaziotclassification_4, uses the nodes of the expenditure of the previous periods
	Return "
		// Relationships of other expenses between periods.
		|SELECT
		|	""TextOfRelationshipOfOtherExpensesBetweenPeriods"" AS RequestSource,
		|	SourceNodes.NodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	UNDEFINED AS Products,
		|	UNDEFINED AS StorageLocation,
		|	T.Lot AS Lot,
		|	T.ExpenseItem AS ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	UNDEFINED AS CorNomenclature,
		|	UNDEFINED AS BoxStorageLocation,
		|	T.Lot AS CorLot,
		|	T.ExpenseItem AS ExpenseItemOfWriteOff,
		|	SourceNodes.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	TRUE AS TheseAreLeftovers,
		|	0 AS Count,
		|	SUM(T.SumOpeningBalance) AS NumberWithVAT,
		|	SUM(T.AmountExcludingVATOpeningBalance) AS QuantityWithoutVAT,
		|	SUM(T.SumComplOpeningBalance) AS NumberOfLocal,
		|	SUM(T.AmountFAOpeningBalance) AS NumberOfTA,
		|	SUM(T.SumManOpeningBalance) AS NumberOfMen
		|FROM
		|	TTNodesOfExpensesOfPreviousPeriods AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Department = T.Department
		|		AND SourceNodes.LineOfBusiness = T.LineOfBusiness
		|		AND SourceNodes.ExpenseItem = T.ExpenseItem
		|		AND SourceNodes.DimensionOfExpenses = T.DimensionOfExpenses
		|		AND SourceNodes.Lot = T.Lot
		|		AND SourceNodes.ProductCostElement = T.ProductCostElement
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriodPrevious
		|		AND (T.SumOpeningBalance <> 0
		|			OR T.AmountExcludingVATOpeningBalance <> 0
		|			OR T.SumComplOpeningBalance <> 0
		|			OR T.AmountFAOpeningBalance <> 0
		|			OR T.SumManOpeningBalance <> 0)
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Department = T.Department
		|		AND ReceiverNodes_.LineOfBusiness = T.LineOfBusiness
		|		AND ReceiverNodes_.ExpenseItem = T.ExpenseItem
		|		AND ReceiverNodes_.DimensionOfExpenses = T.DimensionOfExpenses	
		|		AND ReceiverNodes_.Lot = T.Lot
		|		AND ReceiverNodes_.ProductCostElement = T.ProductCostElement
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|
		|GROUP BY
		|	SourceNodes.NodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.ExpenseItem,
		|	T.Lot,
		|	SourceNodes.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction

Function TextDistributionOfExpensesForInventoryCosts() // vtvyaziotcleniipredivaration_5, uses vtmovementprochierachievementsreferences
	Return "
		// Distribution of expenses for the cost of goods.
		|SELECT
		|	""TextDistributionOfExpensesForInventoryCosts"" AS RequestSource,
		|	T.NodeNumber AS SourceNodeNumber,
		|	ISNULL(ReceiverNodes_.NodeNumber, -1) AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorNomenclature AS CorNomenclature,
		|	T.BoxStorageLocation AS BoxStorageLocation,
		|	T.CorLot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriod AS PeriodOfSource,
		|	T.DistributionPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	SUM(T.AmountIncludingVAT)   AS NumberWithVAT,
		|	SUM(T.AmountExcludingVAT) AS QuantityWithoutVAT,
		|	SUM(T.SumCompl)   AS NumberOfLocal,
		|	SUM(T.AmountFA)     AS NumberOfTA,
		|	SUM(T.SumMan)    AS NumberOfMen
		|FROM
		|	RegisteredRecordsTTOtherExpensesByPeriod AS T
		|
		// When distributing the costs of the receiving node, there may not be if the costs are distributed to the Balance of goods
		// for which there are no Registered Records.
		|	LEFT JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.ItemsLocationAttributes = T.CorItemsLocationAttributes
		|		AND ReceiverNodes_.AccountingSection = T.CorAccountingSection
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND ReceiverNodes_.Organization = T.CorCompany
		|		AND ReceiverNodes_.Lot = T.CorLot	
		|		AND ReceiverNodes_.LotVendorAttributes = T.LotVendorAttributesCorr
		|		AND ReceiverNodes_.FinancialAccountingDimension = T.CorControllingAttributes
		|		AND ReceiverNodes_.VATActivityType = T.CorVATActivityTypes
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|WHERE
		|	T.CorNomenclature <> VALUE(Catalog.Products.EmptyRef)
		|	AND VALUETYPE(T.CorLot) <> TYPE(Catalog.ProductionLots)
		|
		|GROUP BY
		|	T.NodeNumber,
		|	ISNULL(ReceiverNodes_.NodeNumber, -1),
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.BoxStorageLocation,
		|	T.CorLot,
		|	T.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction
Function TextDistributionOfExpensesForProductionLotReferences() // DeviationTTCommunicationPreliminary_6
	Return "
		// Distribution of costs for production batches.
		|SELECT
		|	""TextDistributionOfExpensesForProductionLotReferences"" AS RequestSource,
		|	T.NodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorNomenclature AS CorNomenclature,
		|	T.BoxStorageLocation AS BoxStorageLocation,
		|	T.CorLot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	SUM(T.AmountIncludingVAT)   AS NumberWithVAT,
		|	SUM(T.AmountExcludingVAT) AS QuantityWithoutVAT,
		|	SUM(T.SumCompl)   AS NumberOfLocal,
		|	SUM(T.AmountFA)     AS NumberOfTA,
		|	SUM(T.SumMan)    AS NumberOfMen
		|FROM
		|	RegisteredRecordsTTOtherExpensesByPeriod AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Department = T.DebitBusinessUnit
		|		AND ReceiverNodes_.LineOfBusiness = T.CorLineOfBusiness
		|		AND ReceiverNodes_.ExpenseItem = T.ExpenseItem
		|		AND ReceiverNodes_.DimensionOfExpenses = T.DimensionOfExpenses	
		|		AND ReceiverNodes_.Lot = T.CorLot
		|		AND ReceiverNodes_.ProductCostElement = T.ProductCostElement
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|WHERE
		|	T.Lot = UNDEFINED
		|	AND T.CorLot <> UNDEFINED
		|	AND VALUETYPE(T.CorLot) = TYPE(Catalog.ProductionLots)
		|
		|GROUP BY
		|	T.NodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.BoxStorageLocation,
		|	T.CorLot,
		|	T.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction
Function TextAllocationOfExpensesToOtherItemsOfExpenses() // DeviationTTCommunicationPreliminary_7
	Return "
		// Allocation of expenses to other items of expenses.
		|SELECT
		|	""TextAllocationOfExpensesToOtherItemsOfExpenses"" AS RequestSource,
		|	T.NodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	T.ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	UNDEFINED AS BoxStorageLocation,
		|	UNDEFINED AS CorLot,
		|	T.CorExpenseItem AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	SUM(T.AmountIncludingVAT)   AS NumberWithVAT,
		|	SUM(T.AmountExcludingVAT) AS QuantityWithoutVAT,
		|	SUM(T.SumCompl)   AS NumberOfLocal,
		|	SUM(T.AmountFA)     AS NumberOfTA,
		|	SUM(T.SumMan)    AS NumberOfMen
		|FROM
		|	RegisteredRecordsTTOtherExpensesByPeriod AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Department = T.DebitBusinessUnit
		|		AND ReceiverNodes_.LineOfBusiness = T.CorLineOfBusiness
		|		AND ReceiverNodes_.ExpenseItem = T.CorExpenseItem
		|		AND ReceiverNodes_.DimensionOfExpenses = T.CorExpenditureDimension	
		|		AND ReceiverNodes_.Lot = UNDEFINED
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|WHERE
		|	T.ThereIsCorPart
		|	AND T.CorNomenclature = UNDEFINED
		|	AND T.CorLot = UNDEFINED
		|	AND T.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|
		|GROUP BY
		|	T.NodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.ExpenseItem,
		|	T.CorExpenseItem,
		|	T.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|
		|ORDER BY
		|	SourceNodeNumber,
		|	ReceiverNodeNumber
		|";
EndFunction

Function TextOfTTOfDeviationConnection() // TT vtsvyaziotkloneniy, uses vtsvyaziotkloneniypredvaritelnaya
	Return "
		|SELECT
		|	T.SourceNodeNumber AS SourceNodeNumber,
		|	T.ReceiverNodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.ExpenseItemOfWriteOff,
		|	T.DistributionPeriodSource,
		|	T.PeriodOfDistributionReceiver,
		|	T.TheseAreLeftovers,
		|	SUM(T.Count) AS Count,
		|	SUM(T.NumberWithVAT) AS NumberWithVAT,
		|	SUM(T.QuantityWithoutVAT) AS QuantityWithoutVAT,
		|	SUM(T.NumberOfLocal) AS NumberOfLocal,
		|	SUM(T.NumberOfTA) AS NumberOfTA,
		|	SUM(T.NumberOfMen) AS NumberOfMen
		|
		|INTO DeviationTTCommunication
		|FROM
		|	DeviationTTCommunicationPreliminary AS T
		|WHERE
		|	T.SourceNodeNumber <> T.ReceiverNodeNumber
		|GROUP BY
		|	T.SourceNodeNumber,
		|	T.ReceiverNodeNumber,
		|	T.ItemsLocationAttributes,
		|	T.Products,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.ExpenseItemOfWriteOff,
		|	T.DistributionPeriodSource,
		|	T.PeriodOfDistributionReceiver,
		|	T.TheseAreLeftovers
		|
		|INDEX BY
		|	SourceNodeNumber
		|";
EndFunction

Function TextNodesOfServiceCalculationOfCostOfPastPeriods() // TT nodal_accountingthe cost of the past three periods
	Return "
		|SELECT
		|	T.NodeNumber AS NodeNumber,
		|	T.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT AS CostVariancesExcludingVAT,
		|	T.CostVariancesLocal AS CostVariancesLocal,
		|	T.CostVariancesMgmt AS CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal AS AddExpensesLocal,
		|	T.AddExpensesMan AS AddExpensesMan,
		|	T.PermanentDifference AS PermanentDifference,
		|	T.CostInTaxAccounting AS CostInTaxAccounting,
		|	T.AIT AS AIT
		|
		|INTO NodesSLU_CalculationOfCostOfPastPeriods
		|FROM
		|	TTNodesOfDeviations AS T
		|";
EndFunction

Function TextOfLinkSLU_CalculationOfCostOfPastPeriods() // TT svyazislu_accountingthe cost of the past few periods
	Return "
		|SELECT
		|	Links.SourceNodeNumber AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	-Links.NumberWithVAT AS ArcWeightWithVAT,
		|	-Links.QuantityWithoutVAT AS ArcWeightWithoutVAT,
		|	-Links.NumberOfLocal AS ArcWeightLocal,
		|	-Links.NumberOfTA AS WeightOfArcISTA,
		|	-Links.NumberOfMen AS ArcWeightMan
		|
		|INTO SvyaziSLU_CalculationOfCostOfPastPeriods
		|FROM
		|	DeviationTTCommunication AS Links
		|
		|UNION ALL
		|
		|SELECT
		|	Nodes.NodeNumber AS SourceNodeNumber,
		|	Nodes.NodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(Nodes.NumberWithVAT AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|	CAST(Nodes.QuantityWithoutVAT AS NUMBER(28,10)) AS ArcWeightWithoutVAT,
		|	CAST(Nodes.NumberOfLocal AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(Nodes.NumberOfTA AS NUMBER(28,10)) AS WeightOfArcISTA,
		|	CAST(Nodes.NumberOfMen AS NUMBER(28,10)) AS ArcWeightMan
		|FROM
		|	TTNodesOfDeviations AS Nodes
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD

Procedure PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"SERVICENodes_CalculationOfCostOfPastPeriods_CostedPD");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextToSolveSLERejectionsCostPDIsConstant(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function QueryTextToSolveSLERejectionsCostPDIsConstant(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextInitialCostOfDeviationIsCostPDOfVConstantDDDDDDDD() // TT is the starting cost of a permanent difference
		+ Common.QueryBatchSeparator() + TextNodesOfSERVICE_CalculationOfCostOfPastPeriods_CostPD() // TT vtuzlykorrectedconstant difference
		+ "";
	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextInitialCostOfDeviationIsCostPDOfVConstantDDDDDDDD() // TT is the initial value of the worship of a permanent difference
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|
		// The Cost(PD) of expenses that are not accepted for tax accounting.
		|	CAST(SUM(CASE
		|		WHEN NOT ARTICLES__.EnteredInTaxAccounting
		|			THEN ISNULL(DecisionTable.CostInTaxAccounting, 0)
		|				* ISNULL(Links.NumberOfLocal, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS PermanentDifference
		|
		|INTO InitialCostOfDeviationIsCostPDOfVConstant
		|FROM
		|	TTNodesOfDeviations AS AdjustmentNodes
		|
		|	INNER JOIN DeviationTTCommunication AS Links
		|		ON AdjustmentNodes.NodeNumber = Links.ReceiverNodeNumber
		|
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = Links.ExpenseItemOfWriteOff
		|
		|	LEFT JOIN ResultOfCalculationIsTA AS DecisionTable
		|		ON DecisionTable.NodeNumber = Links.SourceNodeNumber
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber
		|
		|INDEX BY
		|	NodeNumber
		|";
EndFunction	

Function TextNodesOfSERVICE_CalculationOfCostOfPastPeriods_CostPD() // TT nodal_accountingthe cost of the past few periods_Constant Difference
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|	CAST(ISNULL(AdjustmentNodes.PermanentDifference, 0)
		|		+ ISNULL(InitialCost_0.PermanentDifference, 0) AS NUMBER(28, 10)) AS PermanentDifference
		|
		|INTO SERVICENodes_CalculationOfCostOfPastPeriods_CostedPD
		|FROM
		|	TTNodesOfDeviations AS AdjustmentNodes
		|
		|	LEFT JOIN InitialCostOfDeviationIsCostPDOfVConstant AS InitialCost_0
		|		ON InitialCost_0.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|INDEX BY
		|	NodeNumber
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparingDataToSolveCaseOfDeviationsInCostOfGoods

// The stage of "Preparing the data for the resolution of the_accounting_the cost of the past few periods"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparingDataToSolveCaseOfDeviationsInCostOfGoods(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataToSolveCaseOfDeviationsInCostOfGoods");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTOfRegisteredRecordsOfInventoryCostsByPeriod, TTRegisteredRecordsOfInventoryCostsByPeriodDetailed,
		|RegisteredRecordsTTOtherExpensesByPeriod,
		|TTBalancesOfDeviationsAtBeginningOfPeriodDetailed, DeviationTTCommunicationPreliminary,
		|TTCommunicationDistributionOfAdditionalExpensesAmount, TTCommunicationsDistributionOfArticleByArticleForIssue,
		|TTNodesOtherExpensesUnfinishedProduction,
		|TTNodesOfDeviations, DeviationTTCommunication");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	#Region MinimumPeriod
	Query.Text = "
	|SELECT
	|	MIN(BEGINOFPERIOD(T.MinimumPeriod, MONTH)) AS MinimumPeriod
	|FROM (
	|	SELECT
	|		MIN(T.VariancePeriod) AS MinimumPeriod
	|	FROM
	|		TTCacheEstimatedTurnoverDeviationsInCostOfGoods AS T
	|	WHERE
	|		T.OfficialTypeOfMovementParish
	|		AND T.VariancePeriod <> DATETIME(1,1,1)
	|
	|	UNION ALL
	|
	|	SELECT
	|		MIN(T.VariancePeriod) AS MinimumPeriod
	|	FROM
	|		TTIsStornoOfDeviationsOfPreviousPeriod AS T
	|	WHERE
	|		T.VariancePeriod <> DATETIME(1,1,1)
	|
	|	UNION ALL
	|
	|	SELECT
	|		BEGINOFPERIOD(DD.VariancePeriod, MONTH) AS MinimumPeriod
	|	FROM
	|		TTCashEstimatedTurnoverOtherExpenses AS DD
	|	WHERE
	|		DD.VariancePeriod <> DATETIME(1,1,1)
	|		AND DD.VariancePeriod < &BeginOfPeriod
	|
	|	UNION ALL
	|
	|	SELECT
	|		BEGINOFPERIOD(DD.ReceiptPeriod, MONTH) AS MinimumPeriod
	|	FROM
	|		SharesOfAdditionalExpenses AS DD
	|	WHERE
	|		DD.ReceiptPeriod <> DATETIME(1,1,1)
	|		AND DD.ReceiptPeriod < &BeginOfPeriod
	|) AS T
	|";
	
	QueryResult = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True,, True);
	Selection = QueryResult.Select();
	
	BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	If Selection.Next() Then
		MinimumPeriod = ?(ValueIsFilled(Selection.MinimumPeriod), Selection.MinimumPeriod, BeginOfPeriod);
	Else
		MinimumPeriod = BeginOfPeriod; 
	EndIf;
	
	#EndRegion
	
	#Region RecentNodeNumbers
	Query.Text = "
	|SELECT
	|	MAX(ISNULL(T.NodeNumberOfAdditionalExpenseAmount, 0)) AS NodeNumberOfAdditionalExpenseAmount,
	|	MAX(ISNULL(T.NodeNumberArticleByArticle, 0)) AS NodeNumberArticleByArticle
	|FROM (
	|	SELECT
	|		MAX(T.NodeNumber) AS NodeNumberOfAdditionalExpenseAmount,
	|		0 AS NodeNumberArticleByArticle
	|	FROM
	|		AdditionalCostAdjustmentNodes AS T
	|
	|	UNION ALL
	|
	|	SELECT
	|		0 AS NodeNumberOfAdditionalExpenseAmount,
	|		MAX(T.NodeNumber) AS NodeNumberArticleByArticle
	|	FROM
	|		TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS T
	|	) AS T
	|;
	|";
	QueryResult = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True,, True);
	Selection = QueryResult.Select();
	
	BeginOfPeriod = CalculationParameters.PayrollPeriod.BeginOfPeriod;
	If Selection.Next() Then
		LastNodeNumber = Max(Selection.NodeNumberOfAdditionalExpenseAmount, Selection.NodeNumberArticleByArticle);
	Else
		LastNodeNumber = 0; 
	EndIf;
	
	#EndRegion
	
	AddlParameters = CalculationParameters.AdditionalStageRequestParameters;
	AddlParameters.Insert("MinimumPeriod", MinimumPeriod);
	AddlParameters.Insert("MinimumPastPeriod", Min(MinimumPeriod, CalculationParameters.PayrollPeriod.EndOfPreviousPeriod));
	AddlParameters.Insert("LastNodeNumber", LastNodeNumber);
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextForSolvingCaseOfDeviationInCostOfGoods(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"RegisteredRecordsTTOtherExpensesByPeriodPreliminary");
	
EndProcedure

// Formation of the Query Text for calculating the cost of past periods.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//	
// Returns:
// 	String - Query text
//
Function QueryTextForSolvingCaseOfDeviationInCostOfGoods(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextTTDeviationsToDistribution()); // TTOfDeviationToDistribution
	QueriesTexts.Add(TextTTOfRegisteredRecordsOfInventoryCostsByPeriodDetailedDeviations()); // TTRegisteredRecordsOfInventoryCostsByPeriodDetailed
	QueriesTexts.Add(TextTTOfRegisteredRecordsOfInventoryCostsByPeriodCollapsed()); // TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp
	QueriesTexts.Add(TextIsTTStornoOfMovementsOfPreviousPeriod()); // TTIsStornoOfMovementsOfPreviousPeriod
	QueriesTexts.Add(TextTTThereIsRegisteredRecordsOfGoods()); // TTHasRegisteredRecordsOfGoods
	QueriesTexts.Add(TextTTNodesCorrectionsOfPastPeriodsPreliminaryDeviations()); // TTNodesOfAdjustmentOfPastPeriodsPreliminary
	QueriesTexts.Add(TextTTNodesAdjustmentsOfPastPeriodsGroupedDeviations()); // TTNodesAdjustmentsOfPastPeriodsGrouped
	QueriesTexts.Add(TextTTNodesOfCorrectionOfPastPeriodsOfDeviation()); // TTNodesOfAdjustmentOfPastPeriods
	QueriesTexts.Add(TextTTAdjustmentNodesOfCurrentPeriod()); // TTNodesOfCurrentPeriodAdjustment
	QueriesTexts.Add(TextTTRemainingDeviationsAtBeginningOfPeriod()); // During the formal period, during the formal period, during the formal period, during the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period
	QueriesTexts.Add(TextTTNodesOfDeviationsPreliminaryDeviations()); // TTNodesOfDeviationsPreliminary
	QueriesTexts.Add(TextTTNodesOfDeviationsNumberedDeviations()); // TTDeviationNodesNumbered
	QueriesTexts.Add(TextCoefficientsOfReductionOfDeviationNodes()); // TT is the coefficient of adoration of nodesreferences
	QueriesTexts.Add(TextTTDeviationNodesDeviations()); // TTNodesOfDeviations
	QueriesTexts.Add(TextTTNodesOtherExpensesUnfinishedProduction()); // TTNodesOtherExpensesUnfinishedProduction
	QueriesTexts.Add(TextOfTTCommunicationIsDistributionOfArticleByArticleForIssue()); // TTCommunicationsDistributionOfArticleByArticleForIssue
	QueriesTexts.Add(TextOfTTOfRegisteredRecordedInventoryCostsForPeriodsOfDeviation()); // TTOfRegisteredRecordsOfInventoryCostsByPeriod
	QueriesTexts.Add(TextTTOfRegisteredRecordedOtherExpensesByPeriod()); // TT vtmovementprochierachievementsreferences
	
	QueryTextsOfLink = New Array;
	QueryTextsOfLink.Add(TextOfTTOfRegisteredRecordsConnectionsOfInventoryCostsByPeriod()); // Uses the following movements for the highest values of goods by period
	QueryTextsOfLink.Add(TextWriteOffOfItemsForItemByItemExpenses()); // Uses the following movements for the highest values of goods by period
	QueryTextsOfLink.Add(TextOfRelationshipOfInventoryCostBetweenPeriodsOfDeviation()); // Uses a node to correct past periods
	QueryTextsOfLink.Add(TextOfRelationshipOfOtherExpensesBetweenPeriods()); // Uses nodes to spend the past periods
	QueryTextsOfLink.Add(TextAllocationOfExpensesForInventoryCostsDeviations()); // Uses vtmovementprochierachievementoperiods
	QueryTextsOfLink.Add(TextDistributionOfExpensesForProductionLotReferences()); // Uses vtmovementprochierachievementoperiods
	QueryTextsOfLink.Add(TextDistributionOfExpensesForProductionLotReferencesCurrentPeriod()); // Uses a table with a link to the stateexploits
	QueryTextsOfLink.Add(TextDistributionOfExpensesForIssueOfCurrentPeriod()); // Uses in connection with the distribution of the status of each issue
	QueryTextsOfLink.Add(TextAllocationOfExpensesToOtherItemsOfExpenses()); // Uses vtmovementprochierachievementoperiods
	TextOfTTOfDeviationConnectionPreliminary = StrConcat(QueryTextsOfLink, Common.UnionAllText());
	TextOfTTOfDeviationConnectionPreliminary = TextOfTTOfDeviationConnectionPreliminary + "
	|INDEX BY
	|	SourceNodeNumber
	|";
	
	QueriesTexts.Add(TextOfTTOfDeviationConnectionPreliminary); // TT Vtsvyaziotkloneniypredvaritelnaya
	QueriesTexts.Add(TextOfTTOfDeviationConnection()); // DeviationTTCommunication
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextTTDeviationsToDistribution() // TTOfDeviationToDistribution
	Return "
		|SELECT
		|	T.VariancePeriod AS VariancePeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	T.ReversingEntry AS ReversingEntry,
		|	SUM(T.CostVariancesIncludingVAT) AS CostVariancesIncludingVAT,
		|	SUM(T.CostVariancesExcludingVAT) AS CostVariancesExcludingVAT,
		|	SUM(T.CostVariancesLocal) AS CostVariancesLocal,
		|	SUM(T.CostVariancesMgmt) AS CostVariancesMgmt,
		|	SUM(T.AdditionalExpensesIncludingVAT) AS AdditionalExpensesIncludingVAT,
		|	SUM(T.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(T.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(T.AddExpensesMan) AS AddExpensesMan,
		|	SUM(T.VATLocal) AS VATLocal,
		|	SUM(T.VATManag) AS VATManag,
		|	SUM(T.PermanentDifference) AS PermanentDifference,
		|	SUM(T.CostTD) AS CostTD,
		|	SUM(T.CostInTaxAccounting) AS CostInTaxAccounting,
		|	SUM(T.AIT) AS AIT
		|
		|INTO TTOfDeviationToDistribution
		|FROM (
		|	SELECT
		|		T.VariancePeriod AS VariancePeriod,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|		T.Organization AS Organization,
		|		T.Products AS Products,
		|		T.Characteristic AS Characteristic,
		|		T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		T.LineOfBusiness AS LineOfBusiness,
		|		T.Department AS Department,
		|		T.StorageLocation AS StorageLocation,
		|		T.ReversingEntry,
		|		T.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		T.CostVariancesExcludingVAT AS CostVariancesExcludingVAT,
		|		T.CostVariancesLocal AS CostVariancesLocal,
		|		T.CostVariancesMgmt AS CostVariancesMgmt,
		|		T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		T.AddExpensesLocal AS AddExpensesLocal,
		|		T.AddExpensesMan AS AddExpensesMan,
		|		T.VATLocal AS VATLocal,
		|		T.VATManag AS VATManag,
		|		T.PermanentDifference AS PermanentDifference,
		|		T.CostTD AS CostTD,
		|		T.CostVariancesLocal + T.AddExpensesLocal + T.VATLocal - T.PermanentDifference - T.CostTD AS CostInTaxAccounting,
		|		T.AIT AS AIT
		|	FROM
		|		TTCacheEstimatedTurnoverDeviationsInCostOfGoods AS T
		|	WHERE
		|		T.OfficialTypeOfMovementParish
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.VariancePeriod AS VariancePeriod,
		|		T.AccountingSection AS AccountingSection,
		|		T.Organization AS Organization,
		|		T.Products AS Products,
		|		T.Characteristic AS Characteristic,
		|		T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		T.LineOfBusiness AS LineOfBusiness,
		|		T.Department AS Department,
		|		T.StorageLocation AS StorageLocation,
		|		TRUE AS ReversingEntry,
		|		T.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		T.CostVariancesExcludingVAT AS CostVariancesExcludingVAT,
		|		T.CostVariancesLocal AS CostVariancesLocal,
		|		T.CostVariancesMgmt AS CostVariancesMgmt,
		|		T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		T.AddExpensesLocal AS AddExpensesLocal,
		|		T.AddExpensesMan AS AddExpensesMan,
		|		T.VATLocal AS VATLocal,
		|		T.VATManag AS VATManag,
		|		T.PermanentDifference AS PermanentDifference,
		|		T.CostTD AS CostTD,
		|		(T.CostVariancesLocal + T.AddExpensesLocal + T.VATLocal - T.PermanentDifference - T.CostTD) AS CostInTaxAccounting,
		|		T.AIT AS AIT
		|	FROM
		|		TTIsStornoOfDeviationsOfPreviousPeriod AS T
		|
		|	UNION ALL
		|
		|	SELECT
		|		T.VariancePeriod AS VariancePeriod,
		|		T.AccountingSection AS AccountingSection,
		|		(CASE
		|			WHEN T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|				THEN T.CorCompany
		|			ELSE T.Organization END) AS Organization,
		|		T.CorNomenclature AS Products,
		|		T.CorCharacteristics AS Characteristic,
		|		T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		T.CorLineOfBusiness AS LineOfBusiness,
		|		T.DebitBusinessUnit AS Department,
		|		T.BoxStorageLocation AS StorageLocation,
		|		TRUE AS ReversingEntry,
		|		-T.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		-T.CostVariancesExcludingVAT AS CostVariancesExcludingVAT,
		|		-T.CostVariancesLocal AS CostVariancesLocal,
		|		-T.CostVariancesMgmt AS CostVariancesMgmt,
		|		-T.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		-T.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		-T.AddExpensesLocal AS AddExpensesLocal,
		|		-T.AddExpensesMan AS AddExpensesMan,
		|		-T.VATLocal AS VATLocal,
		|		-T.VATManag AS VATManag,
		|		-T.PermanentDifference AS PermanentDifference,
		|		-T.CostTD AS CostTD,
		|		-(T.CostVariancesLocal + T.AddExpensesLocal + T.VATLocal - T.PermanentDifference - T.CostTD) AS CostInTaxAccounting,
		|		-T.AIT AS AIT
		|	FROM
		|		TTIsStornoOfDeviationsOfPreviousPeriod AS T
		|	WHERE
		|		T.ThereIsCorPart
		|	) AS T
		|
		|GROUP BY
		|	T.VariancePeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.ReversingEntry
		|
		|INDEX BY
		|	Products,
		|	Department
		|;
		|SELECT DISTINCT
		|	T.Organization AS Organization,
		|	MIN(T.VariancePeriod) AS VariancePeriod
		|
		|INTO MinimumPeriodsPreliminary
		|FROM
		|	TTOfDeviationToDistribution AS T
		|GROUP BY
		|	T.Organization
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	T.Organization AS Organization,
		|	MIN(T.VariancePeriod) AS VariancePeriod
		|FROM
		|	TTDeviationsOtherExpensesToBeAllocated AS T
		|GROUP BY
		|	T.Organization
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DD.CorCompany AS Organization,
		|	BEGINOFPERIOD(DD.ReceiptPeriod, MONTH) AS VariancePeriod
		|FROM
		|	SharesOfAdditionalExpenses AS DD
		|WHERE
		|	DD.ReceiptPeriod <> DATETIME(1,1,1)
		|	AND DD.ReceiptPeriod < &BeginOfPeriod
		|;
		|SELECT
		|	T.Organization AS Organization,
		|	MIN(T.VariancePeriod) AS VariancePeriod
		|
		|INTO MinimumPeriods
		|FROM
		|	MinimumPeriodsPreliminary AS T
		|GROUP BY
		|	T.Organization
		|";
EndFunction
	
Function TextTTOfRegisteredRecordsOfInventoryCostsByPeriodDetailedDeviations() // TTRegisteredRecordsOfInventoryCostsByPeriodDetailed
	Return "
		|SELECT
		|	TRUE AS ThisIsCurrentPeriod,
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// The condition for checking for a transfer to another organization must correspond to the text-to-Text function of the description()
		// in the general module for calculating the cost of resolving the issue.
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END AS ThereIsCorPart,
		|	MIN(T.Period) AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS StorageLocation,
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS CorAccountingSection,
		|	T.CorCompany AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(T.CorItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		|
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count
		|
		|INTO TTRegisteredRecordsOfInventoryCostsByPeriodDetailed
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|WHERE
		|	NOT T.OfficialTypeOfMovementParish
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		// We exclude off-balance sheet sections of accounting, except for the semi-finished giver - there may be balance costs for it.
		|	AND (NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		OR ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
		|	AND T.Count <> 0
		|	AND NOT T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost),
		|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost))
		// We exclude storno documents of the previous period. The cost of such records is determined in 
		// the procedure to adjust the cost of the movement of corrected documents().
		|	AND NOT (T.ReversingEntry
		|		AND T.EntryType IN (
		|			VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections),
		|			VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod),
		|			VALUE(Enum.LotRecordTypes.ProductCostConsumptionPastPeriodReverseTransaction)))
		// We exclude the selection of documents for which there are storno or corrections in the current period.
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|
		|GROUP BY
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END,
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	T.Organization,
		|	T.AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.CHARACTERISTIC,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // LineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // Department
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // StorageLocation
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // CorAccountingSection
		|	T.CorCompany,
		|	T.CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(T.CorItemsLocationAttributes.CHARACTERISTIC,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) // WriteOffDeviationsToCostOfGoodsSelling
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS ThisIsCurrentPeriod,
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// The condition for checking for a transfer to another organization must correspond to the text-to-Text function of the description()
		// in the general module for calculating the cost of resolving the issue.
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END AS ThereIsCorPart,
		// The distribution of deviations related to the previous period is reflected by the start date of the current period.
		|	&BeginOfPeriod AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS StorageLocation,
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS CorAccountingSection,
		|	T.CorCompany AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = T.Organization
		|		AND MinimumPeriods.VariancePeriod <= T.Period
		|	LEFT JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.ReversedDocument = T.Recorder
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&MediumSlipOrganizations)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND T.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		// We exclude off-balance sheet sections of accounting, except for the semi-finished giver - there may be balance costs for it.
		|	AND (NOT T.AccountingSection IN (&OffBalanceSheetAccountingSections)
		|		OR ISNULL(T.InventoryOwnerAttribute.InventoryType, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
		|	AND T.Count <> 0
		// We exclude the selection of documents from the previous period for which there are storno or corrections in the current period.
		|	AND CorrectedDocuments_.ReversedDocument IS NULL
		|GROUP BY
		|	CASE
		|		WHEN T.CorItemsLocationAttributes.Products IS NULL
		|		 OR T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 OR T.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|					VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|			THEN FALSE 
		|		ELSE TRUE END,
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	T.Organization,
		|	T.AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // LineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // Department
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // StorageLocation
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // CorAccountingSection
		|	T.CorCompany,
		|	T.CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) // WriteOffDeviationsToCostOfGoodsSelling
		|
		|UNION ALL
		|
		// Registered Records of the delivery invoice for the distribution of Additional expense amounts for unfactated deliveries.  
		|SELECT
		|	FALSE AS ThisIsCurrentPeriod,
		|	TRUE AS ThereIsCorPart,
		// The distribution of deviations related to the previous period is reflected by the start date of the current period.
		|	&BeginOfPeriod AS Period,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS StorageLocation,
		// Cor Attributes
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
		|	T.Organization AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	FALSE AS WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = T.Organization
		|		AND MinimumPeriods.VariancePeriod <= T.Period
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPreviousPeriod
		|	AND T.Organization IN (&MediumSlipOrganizations)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|	AND T.Count <> 0
		|	AND T.LotCalculation
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	T.Organization,
		|	T.AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // LineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // Department
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // StorageLocation
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // CorAccountingSection
		|	T.CorCompany,
		|	T.CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextTTOfRegisteredRecordsOfInventoryCostsByPeriodCollapsed() // TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp
	Return "
		|SELECT
		|	T.ThisIsCurrentPeriod,
		|	T.ThereIsCorPart,
		|	T.DistributionPeriod,
		|	MIN(T.Period) AS Period,
		|	T.Organization,
		// Dimensions
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		// Cost measurements
		|	(CASE
		|		WHEN T.WriteOffDeviationsToCostOfGoodsSelling THEN T.ItemsLocationAttributes
		|		ELSE VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) END) AS ItemsLocationAttributes,
		|	T.AccountingSection,
		|	UNDEFINED AS Lot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		// Cor Attributes of deviations
		|	T.CorCompany,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		// Cor Attributes
		|	T.AccountingDimensionByPartners,
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count
		|
		|INTO TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp
		|FROM
		|	TTRegisteredRecordsOfInventoryCostsByPeriodDetailed AS T
		|
		|GROUP BY
		|	T.ThisIsCurrentPeriod,
		|	T.ThereIsCorPart,
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		// Dimensions
		|	(CASE
		|		WHEN T.WriteOffDeviationsToCostOfGoodsSelling THEN T.ItemsLocationAttributes
		|		ELSE VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) END), // ItemsLocationAttributes
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		// Cor Attributes
		|	T.CorAccountingSection,
		|	T.CorCompany,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation,
		|	T.AccountingDimensionByPartners,
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.WriteOffDeviationsToCostOfGoodsSelling
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextIsTTStornoOfMovementsOfPreviousPeriod() // TTIsStornoOfMovementsOfPreviousPeriod
	Return "
		|SELECT
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	BEGINOFPERIOD(CorrectedDocuments_.DateOfDocumentBeingCancelled, MONTH) AS PeriodBeingCancelled,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
		// Dimensions
		|	T.Organization AS Organization,
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS Department,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS StorageLocation,
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS CorAccountingSection,
		|	T.CorCompany AS CorCompany,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)) AS CorNomenclature,
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS CorCharacteristics,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		|	T.ExpenseItemOfWriteOff AS ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.AssetAndLiabilityItem AS AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|	T.GLAccountSettings AS GLAccountSettings,
		|	T.BusinessOperation AS BusinessOperation,
		|	T.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS WriteOffDeviationsToCostOfGoodsSelling,
		|	MIN(T.FinRecordID) AS FinRecordID,
		|	SUM(T.Count) AS Count
		|
		|INTO TTIsStornoOfMovementsOfPreviousPeriod
		|FROM
		|	AccumulationRegister.InventoryCost AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|	INNER JOIN MinimumPeriods AS MinimumPeriods
		|		ON MinimumPeriods.Organization = T.Organization
		|		AND MinimumPeriods.VariancePeriod <= T.Period
		|	INNER JOIN CorrectedDocuments_ AS CorrectedDocuments_
		|		ON CorrectedDocuments_.Recorder = T.Recorder
		|WHERE
		|	T.Period BETWEEN &MinimumPastPeriod AND &EndOfPeriod
		|	AND T.Organization IN (&MediumSlipOrganizations)
		|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND NOT T.AccountingSection IN(
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries))
		|	AND T.Count <> 0
		|	AND T.ReversingEntry
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH),
		|	BEGINOFPERIOD(CorrectedDocuments_.DateOfDocumentBeingCancelled, MONTH),
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	T.Organization,
		|	T.AccountingDimensionByPartners,
		|	T.ItemsLocationAttributes,
		|	T.InventoryOwnerAttribute,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.Characteristic,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // LineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // Department
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // StorageLocation
		// Cor Attributes
		|	(CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.CorAccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // CorAccountingSection
		|	T.CorCompany,
		|	T.CorItemsLocationAttributes,
		|	T.CorInventoryOwnerAttribute,
		|	ISNULL(T.CorItemsLocationAttributes.Products,
		|		VALUE(Catalog.Products.EmptyRef)), // CorNomenclature
		|	ISNULL(T.CorItemsLocationAttributes.Characteristic,
		|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)), // CorCharacteristics
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.CorLineOfBusiness
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.CorItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN T.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|			THEN T.Department
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|		 OR T.CorItemsLocationAttributes.StorageType IS NULL
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.CorItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.CorItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|		 AND NOT T.CorItemsLocationAttributes.StorageLocation IS NULL
		|			THEN T.CorItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) // WriteOffDeviationsToCostOfGoodsSelling
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextTTThereIsRegisteredRecordsOfGoods() // TTHasRegisteredRecordsOfGoods
	Return "
		|SELECT DISTINCT
		|	T.DistributionPeriod,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.ReversingEntry AS ReversingEntry
		|
		|INTO TTHasDetailedRegisterRecordsOfGoods
		|FROM (
		|	SELECT DISTINCT
		|		T.DistributionPeriod,
		|		T.Organization,
		|		T.Products,
		|		T.Characteristic,
		|		T.InventoryOwnerAttribute,
		|		T.LineOfBusiness,
		|		T.Department,
		|		T.StorageLocation,
		|		FALSE AS ReversingEntry
		|	FROM
		|		TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp AS T
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		T.DistributionPeriod,
		|		(CASE
		|			WHEN T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|				THEN T.CorCompany
		|			ELSE T.Organization END) AS Organization,
		|		T.CorNomenclature,
		|		T.CorCharacteristics,
		|		T.CorInventoryOwnerAttribute,
		|		T.CorLineOfBusiness,
		|		T.DebitBusinessUnit,
		|		T.BoxStorageLocation,
		|		FALSE AS ReversingEntry
		|	FROM
		|		TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp AS T
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		&BeginOfPeriod AS DistributionPeriod,
		|		T.Organization,
		|		T.Products,
		|		T.Characteristic,
		|		T.InventoryOwnerAttribute,
		|		T.LineOfBusiness,
		|		T.Department,
		|		T.StorageLocation,
		|		T.ReversingEntry
		|	FROM
		|		TTIsStornoOfDeviationsOfPreviousPeriod AS T
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		&BeginOfPeriod AS DistributionPeriod,
		|		(CASE
		|			WHEN T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|				THEN T.CorCompany
		|			ELSE T.Organization END) AS Organization,
		|		T.CorNomenclature,
		|		T.CorCharacteristics,
		|		T.CorInventoryOwnerAttribute,
		|		T.CorLineOfBusiness,
		|		T.DebitBusinessUnit,
		|		T.BoxStorageLocation,
		|		T.ReversingEntry
		|	FROM
		|		TTIsStornoOfDeviationsOfPreviousPeriod AS T
		|	WHERE
		|		T.ThereIsCorPart
		|
		|	) AS T
		|
		|INDEX BY
		|	Products,
		|	Department
		|;
		|SELECT DISTINCT
		|	T.DistributionPeriod,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation
		|
		|INTO TTHasRegisteredRecordsOfGoods
		|FROM
		|	TTHasDetailedRegisterRecordsOfGoods AS T
		|";
EndFunction
	
Function TextTTNodesCorrectionsOfPastPeriodsPreliminaryDeviations() // TTNodesOfAdjustmentOfPastPeriodsPreliminary
	Return "
		|SELECT
		|	""1"" AS RequestSource,
		|	BEGINOFPERIOD(T.Period, MONTH) AS DistributionPeriod,
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.ItemsLocationAttributes.Products AS Products,
		|	T.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END) AS LineOfBusiness,
		|	(CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END) AS Department,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END) AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	SUM(CASE
		// We exclude the Balance of unfactured deliveries.
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|		 AND T.CountOpeningBalance < 0
		|			THEN 0
		|		ELSE T.CountOpeningBalance END) AS CountOpeningBalance,
		|	SUM(T.CountClosingBalance) AS CountClosingBalance,
		|	SUM(T.CountReceipt) AS CountReceipt
		|
		|INTO TTNodesOfAdjustmentOfPastPeriodsPreliminary
		|FROM
		|	AccumulationRegister.InventoryCost.BalanceAndTurnovers(&MinimumPastPeriod, &EndOfPeriod, Month, , 
		|		Organization IN (&MediumSlipOrganizations)
		|		AND &MinimumPastPeriod <> &EndOfPreviousPeriod
		|	) AS T
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON T.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|WHERE
		|	T.CountOpeningBalance <> 0
		|	OR T.CountReceipt <> 0
		|
		|GROUP BY
		|	BEGINOFPERIOD(T.Period, MONTH), // DistributionPeriod
		|	(CASE
		|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN T.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	T.Organization,
		|	T.ItemsLocationAttributes.Products,
		|	T.ItemsLocationAttributes.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(T.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END), // LineOfBusiness
		|	(CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN T.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(T.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END), // Department
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN T.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END) // StorageLocation
		|
		|UNION ALL
		|
		// An increase in the Balance in the node by storno of movements during the correction period.
		|SELECT
		|	""2"" AS RequestSource,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	SUM(-T.Count) AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	0 AS CountReceipt
		|FROM
		|	TTIsStornoOfMovementsOfPreviousPeriod AS T
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation
		|
		|UNION ALL
		|
		// Correction of the Balance in the node by storno movements in the correction period.
		|SELECT
		|	""3"" AS RequestSource,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.CorAccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.CorNomenclature AS Products,
		|	T.CorCharacteristics AS Characteristic,
		|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS LineOfBusiness,
		|	T.DebitBusinessUnit AS Department,
		|	T.BoxStorageLocation AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	SUM(T.Count) AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	0 AS CountReceipt
		|FROM
		|	TTIsStornoOfMovementsOfPreviousPeriod AS T
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.CorAccountingSection,
		|	T.Organization,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation
		|
		|UNION ALL
		|
		// A decrease in the arrival at the node by storno of movements in the period being reversed.
		|SELECT
		|	""4"" AS RequestSource,
		|	T.PeriodBeingCancelled AS DistributionPeriod,
		|	T.CorAccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.CorNomenclature AS Products,
		|	T.CorCharacteristics AS Characteristic,
		|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.CorLineOfBusiness AS LineOfBusiness,
		|	T.DebitBusinessUnit AS Department,
		|	T.BoxStorageLocation AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	0 AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	SUM(T.Count) AS CountReceipt
		|FROM
		|	TTIsStornoOfMovementsOfPreviousPeriod AS T
		|
		|GROUP BY
		|	T.PeriodBeingCancelled,
		|	T.CorAccountingSection,
		|	T.Organization,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation
		|
		|UNION ALL
		|
		// Adjustment of arrival at the node for the quantity of delivery invoice.
		|SELECT
		|	""5"" AS RequestSource,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	0 AS CountOpeningBalance,
		|	0 AS CountClosingBalance,
		|	SUM(-T.Count) AS CountReceipt
		|FROM
		|	TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp AS T
		|WHERE
		|	T.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation
		|";
EndFunction
	
Function TextTTNodesAdjustmentsOfPastPeriodsGroupedDeviations() // TTNodesAdjustmentsOfPastPeriodsGrouped
	Return "
		|SELECT
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	SUM(T.CountOpeningBalance) AS CountOpeningBalance,
		|	SUM(T.CountClosingBalance) AS CountClosingBalance,
		|	SUM(T.CountReceipt) AS CountReceipt
		|
		|INTO TTNodesAdjustmentsOfPastPeriodsGrouped
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriodsPreliminary AS T
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle
		|
		|INDEX BY
		|	Products,
		|	Department,
		|	StorageLocation
		|";
EndFunction
	
Function TextTTNodesOfCorrectionOfPastPeriodsOfDeviation() // TTNodesOfAdjustmentOfPastPeriods
	Return "
		|SELECT
		|	T.DistributionPeriod AS DistributionPeriod,
		|	MAX(ISNULL(T2.DistributionPeriod, UNDEFINED)) AS DistributionPeriodPrevious,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	T.CountOpeningBalance AS CountOpeningBalance,
		|	T.CountClosingBalance AS CountClosingBalance,
		|	T.CountReceipt AS CountReceipt
		|
		|INTO TTNodesOfAdjustmentOfPastPeriods
		|FROM
		|	TTNodesAdjustmentsOfPastPeriodsGrouped AS T
		|	LEFT JOIN TTNodesAdjustmentsOfPastPeriodsGrouped AS T2
		|		ON T.Organization = T2.Organization
		|		AND T.Products = T2.Products
		|		AND T.Characteristic = T2.Characteristic
		|		AND T.InventoryOwnerAttribute = T2.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = T2.LineOfBusiness
		|		AND T.Department = T2.Department
		|		AND T.StorageLocation = T2.StorageLocation
		|		AND T.AccountingSection = T2.AccountingSection
		|		AND T.DistributionPeriod > T2.DistributionPeriod
		|
		|GROUP BY
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle,
		|	T.CountOpeningBalance,
		|	T.CountClosingBalance,
		|	T.CountReceipt
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextTTAdjustmentNodesOfCurrentPeriod() // TTNodesOfCurrentPeriodAdjustment
	Return "
		|SELECT
		|	(CASE
		|		WHEN Nodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN Nodes.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
		|	Nodes.Organization AS Organization,
		|	Nodes.ItemsLocationAttributes.Products AS Products,
		|	Nodes.ItemsLocationAttributes.Characteristic AS Characteristic,
		|	Nodes.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(Nodes.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END) AS LineOfBusiness,
		|	(CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN Nodes.ItemsLocationAttributes.StorageLocation
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(Nodes.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(Nodes.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END) AS Department,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN Nodes.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END) AS StorageLocation,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	UNDEFINED AS DimensionOfExpenses,
		|	0 AS NodeNumberArticleByArticle,
		|	FALSE AS ThisIsUnfinishedPRODUCTION,
		|	SUM(Nodes.Count) AS Count,
		|	SUM(Nodes.Count) AS NumberWithVAT,
		|	SUM(Nodes.Count) AS QuantityWithoutVAT,
		|	SUM(Nodes.Count) AS NumberOfLocal,
		|	SUM(Nodes.Count) AS NumberOfTA,
		|	SUM(Nodes.Count) AS NumberOfMen
		|
		|INTO TTNodesOfCurrentPeriodAdjustment
		|FROM
		|	TTAdjustmentNodes AS Nodes
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Nodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|WHERE
		|	Nodes.Organization IN (&MediumSlipOrganizations)
		|	
		|GROUP BY
		|	(CASE
		|		WHEN Nodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN Nodes.AccountingSection 
		|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END), // AccountingSection
		|	Nodes.Organization,
		|	Nodes.ItemsLocationAttributes.Products,
		|	Nodes.ItemsLocationAttributes.CHARACTERISTIC,
		|	Nodes.InventoryOwnerAttribute,
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(Nodes.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END), // LineOfBusiness
		|	(CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN Nodes.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END), // StorageLocation
		|	(CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN Nodes.ItemsLocationAttributes.StorageLocation
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(Nodes.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN Nodes.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(Nodes.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END) // Department
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	Nodes.Organization AS Organization,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	Nodes.LineOfBusiness AS LineOfBusiness,
		|	Nodes.Department AS Department,
		|	UNDEFINED AS StorageLocation,
		|	Nodes.ExpenseItem AS ExpenseItem,
		|	Nodes.DimensionOfExpenses AS DimensionOfExpenses,
		|	Nodes.NodeNumber AS NodeNumberArticleByArticle,
		|	(CASE
		|		WHEN Nodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN TRUE
		|		ELSE FALSE END) AS ThisIsUnfinishedPRODUCTION,
		|	0 AS Count,
		|	SUM(Nodes.WeightArticleByArticle) AS NumberWithVAT,
		|	SUM(Nodes.WeightArticleByArticleWithoutVAT) AS QuantityWithoutVAT,
		|	SUM(Nodes.WeightArticleByArticleLocal) AS NumberOfLocal,
		|	SUM(Nodes.WeightItemByItemTA) AS NumberOfTA,
		|	SUM(Nodes.WeightArticleByArticleMan) AS NumberOfMen
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS Nodes
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Nodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|WHERE
		|	Nodes.Organization IN (&MediumSlipOrganizations)
		|	
		|GROUP BY
		|	Nodes.Organization,
		|	Nodes.LineOfBusiness,
		|	Nodes.Department,
		|	Nodes.ExpenseItem,
		|	Nodes.DimensionOfExpenses,
		|	Nodes.NodeNumber,
		|	(CASE
		|		WHEN Nodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|			THEN TRUE
		|		ELSE FALSE END) // ThisIsUnfinishedPRODUCTION
		|
		|UNION ALL
		|
		|SELECT
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	Nodes.Organization AS Organization,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	Nodes.LineOfBusiness AS LineOfBusiness,
		|	Nodes.Department AS Department,
		|	UNDEFINED AS StorageLocation,
		|	Nodes.ExpenseItem AS ExpenseItem,
		|	Nodes.DimensionOfExpenses AS DimensionOfExpenses,
		|	Nodes.NodeNumber AS NodeNumberArticleByArticle,
		|	FALSE AS ThisIsUnfinishedPRODUCTION,
		|	0 AS Count,
		|	SUM(Nodes.WeightWithVAT) AS NumberWithVAT,
		|	SUM(Nodes.WeightWithoutVAT) AS QuantityWithoutVAT,
		|	SUM(Nodes.LocalWeight) AS NumberOfLocal,
		|	SUM(Nodes.WeightTA) AS NumberOfTA,
		|	SUM(Nodes.ManSWeight) AS NumberOfMen
		|FROM
		|	AdditionalCostAdjustmentNodes AS Nodes
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Nodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|WHERE
		|	Nodes.Organization IN (&MediumSlipOrganizations)
		|	AND Nodes.ReceiptPeriod >= &BeginOfPeriod
		|	
		|GROUP BY
		|	Nodes.Organization,
		|	Nodes.LineOfBusiness,
		|	Nodes.Department,
		|	Nodes.ExpenseItem,
		|	Nodes.DimensionOfExpenses,
		|	Nodes.NodeNumber
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextTTRemainingDeviationsAtBeginningOfPeriod() // During the formal period, during the formal period, during the formal period, during the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period, after the formal period
	Return "
		|SELECT
		|	Balance.VariancePeriod AS VariancePeriod,
		|	Balance.AccountingSection AS AccountingSection,
		|	Balance.Organization AS Organization,
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.Department AS Department,
		|	Balance.StorageLocation AS StorageLocation,
		|	SUM(Balance.CostVariancesIncludingVAT) AS CostVariancesIncludingVAT,
		|	SUM(Balance.CostVariancesExcludingVAT) AS CostVariancesExcludingVAT,
		|	SUM(Balance.CostVariancesLocal) AS CostVariancesLocal,
		|	SUM(Balance.CostVariancesMgmt) AS CostVariancesMgmt,
		|	SUM(Balance.AdditionalExpensesIncludingVAT) AS AdditionalExpensesIncludingVAT,
		|	SUM(Balance.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(Balance.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(Balance.AddExpensesMan) AS AddExpensesMan,
		|	SUM(Balance.VATLocal) AS VATLocal,
		|	SUM(Balance.VATManag) AS VATManag,
		|	SUM(Balance.PermanentDifference) AS PermanentDifference,
		|	SUM(Balance.CostTD) AS CostTD,
		|	SUM(Balance.CostInTaxAccounting) AS CostInTaxAccounting,
		|	SUM(Balance.AIT) AS AIT
		|
		|INTO TTBalancesOfDeviationsAtBeginningOfPeriodDetailed
		|FROM (
		|	SELECT
		|		TRUE AS TheseAreBalancesAtBeginningOfPeriod,
		|		Balance.VariancePeriod AS VariancePeriod,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|		Balance.Organization AS Organization,
		|		Balance.Products AS Products,
		|		Balance.Characteristic AS Characteristic,
		|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Balance.LineOfBusiness AS LineOfBusiness,
		|		Balance.Department AS Department,
		|		Balance.StorageLocation AS StorageLocation,
		|		Balance.CostVariancesIncludingVATBalance AS CostVariancesIncludingVAT,
		|		Balance.CostVariancesExcludingVATBalance AS CostVariancesExcludingVAT,
		|		Balance.CostVariancesLocalBalance AS CostVariancesLocal,
		|		Balance.CostVariancesMgmtBalance AS CostVariancesMgmt,
		|		Balance.AdditionalExpensesIncludingVATBalance  AS AdditionalExpensesIncludingVAT,
		|		Balance.AdditionalExpensesExcludingVATBalance AS AdditionalExpensesExcludingVAT,
		|		Balance.AddExpensesLocalBalance AS AddExpensesLocal,
		|		Balance.AddExpensesManBalance AS AddExpensesMan,
		|		Balance.VATLocalBalance AS VATLocal,
		|		Balance.VATManagBalance AS VATManag,
		|		Balance.PermanentDifferenceBalance AS PermanentDifference,
		|		Balance.CostTDBalance AS CostTD,
		|		Balance.CostVariancesLocalBalance
		|			+ Balance.AddExpensesLocalBalance
		|			+ Balance.VATLocalBalance
		|			- Balance.PermanentDifferenceBalance
		|			- Balance.CostTDBalance AS CostInTaxAccounting,
		|		Balance.AITBalance AS AIT
		|	FROM
		|		AccumulationRegister.GoodsCostVariances.Balance(&BeginOfPeriod, 
		|			(Organization,
		|			Products,
		|			Characteristic,
		|			InventoryOwnerAttribute,
		|			LineOfBusiness, 
		|			Department,
		|			StorageLocation) IN (
		|			SELECT
		|				RegisterRecords.Organization,
		|				RegisterRecords.Products,
		|				RegisterRecords.Characteristic,
		|				RegisterRecords.InventoryOwnerAttribute,
		|				RegisterRecords.LineOfBusiness,
		|				RegisterRecords.Department,
		|				RegisterRecords.StorageLocation
		|			FROM
		|				TTHasDetailedRegisterRecordsOfGoods AS RegisterRecords
		// The Balance of deviations from the previous period should be transferred to the current period only if there are
		// Registered Recorded movements in this analytics in the current period.
		|			WHERE
		|				RegisterRecords.DistributionPeriod >= &BeginOfPeriod
		|			)
		|		) AS Balance
		|
		|	UNION ALL
		|
		|	SELECT
		|		FALSE AS TheseAreBalancesAtBeginningOfPeriod,
		|		Balance.VariancePeriod AS VariancePeriod,
		|		Balance.AccountingSection AS AccountingSection,
		|		Balance.Organization AS Organization,
		|		Balance.Products AS Products,
		|		Balance.Characteristic AS Characteristic,
		|		Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		Balance.LineOfBusiness AS LineOfBusiness,
		|		Balance.Department AS Department,
		|		Balance.StorageLocation AS StorageLocation,
		|		Balance.CostVariancesIncludingVAT AS CostVariancesIncludingVAT,
		|		Balance.CostVariancesExcludingVAT AS CostVariancesExcludingVAT,
		|		Balance.CostVariancesLocal AS CostVariancesLocal,
		|		Balance.CostVariancesMgmt AS CostVariancesMgmt,
		|		Balance.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
		|		Balance.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
		|		Balance.AddExpensesLocal AS AddExpensesLocal,
		|		Balance.AddExpensesMan AS AddExpensesMan,
		|		Balance.VATLocal AS VATLocal,
		|		Balance.VATManag AS VATManag,
		|		Balance.PermanentDifference AS PermanentDifference,
		|		Balance.CostTD AS CostTD,
		|		Balance.CostInTaxAccounting AS CostInTaxAccounting,
		|		Balance.AIT AS AIT
		|	FROM
		|		TTOfDeviationToDistribution AS Balance
		|	WHERE
		// We will reduce the Balances at the beginning of the period by storno of the deviations of the previous period.
		// The storno deviations of the previous period are added to the Balances at the beginning of the period
		// only if there are Registered Recorded movements in this analytics in the current period.
		|		Balance.ReversingEntry
		|		AND (Balance.Organization,
		|			Balance.Products,
		|			Balance.Characteristic,
		|			Balance.InventoryOwnerAttribute,
		|			Balance.LineOfBusiness, 
		|			Balance.Department,
		|			Balance.StorageLocation) IN (
		|			SELECT
		|				RegisterRecords.Organization,
		|				RegisterRecords.Products,
		|				RegisterRecords.Characteristic,
		|				RegisterRecords.InventoryOwnerAttribute,
		|				RegisterRecords.LineOfBusiness,
		|				RegisterRecords.Department,
		|				RegisterRecords.StorageLocation
		|			FROM
		|				TTHasDetailedRegisterRecordsOfGoods AS RegisterRecords
		|			WHERE
		|				RegisterRecords.DistributionPeriod >= &BeginOfPeriod
		|			)
		|	) AS Balance
		|
		|GROUP BY
		|	Balance.VariancePeriod,
		|	Balance.AccountingSection,
		|	Balance.Organization,
		|	Balance.Products,
		|	Balance.Characteristic,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.LineOfBusiness,
		|	Balance.Department,
		|	Balance.StorageLocation
		|;
		|SELECT
		|	Balance.AccountingSection AS AccountingSection,
		|	Balance.Organization AS Organization,
		|	Balance.Products AS Products,
		|	Balance.Characteristic AS Characteristic,
		|	Balance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Balance.LineOfBusiness AS LineOfBusiness,
		|	Balance.Department AS Department,
		|	Balance.StorageLocation AS StorageLocation,
		|	SUM(Balance.CostVariancesIncludingVAT) AS CostVariancesIncludingVAT,
		|	SUM(Balance.CostVariancesExcludingVAT) AS CostVariancesExcludingVAT,
		|	SUM(Balance.CostVariancesLocal) AS CostVariancesLocal,
		|	SUM(Balance.CostVariancesMgmt) AS CostVariancesMgmt,
		|	SUM(Balance.AdditionalExpensesIncludingVAT)  AS AdditionalExpensesIncludingVAT,
		|	SUM(Balance.AdditionalExpensesExcludingVAT) AS AdditionalExpensesExcludingVAT,
		|	SUM(Balance.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(Balance.AddExpensesMan) AS AddExpensesMan,
		|	SUM(Balance.VATLocal) AS VATLocal,
		|	SUM(Balance.VATManag) AS VATManag,
		|	SUM(Balance.PermanentDifference) AS PermanentDifference,
		|	SUM(Balance.CostInTaxAccounting) AS CostInTaxAccounting,
		|	SUM(Balance.AIT) AS AIT
		|
		|INTO RemainingDeviationsAtBeginningOfPeriodTT
		|FROM
		|	TTBalancesOfDeviationsAtBeginningOfPeriodDetailed AS Balance
		|
		|GROUP BY
		|	Balance.AccountingSection,
		|	Balance.Organization,
		|	Balance.Products,
		|	Balance.Characteristic,
		|	Balance.InventoryOwnerAttribute,
		|	Balance.LineOfBusiness,
		|	Balance.Department,
		|	Balance.StorageLocation
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
	
Function TextTTNodesOfDeviationsPreliminaryDeviations() // TTNodesOfDeviationsPreliminary
	Return "
		|SELECT
		|	""1"" AS RequestSource,
		|	ISNULL(DeviationsToDistribution.VariancePeriod, &BeginOfPeriod) AS VariancePeriod,
		|	&BeginOfPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	FALSE AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	ISNULL(DeviationsToDistribution.CostVariancesIncludingVAT, 0)
		|		+ ISNULL(RemnantsOfDeviations.CostVariancesIncludingVAT, 0) AS CostVariancesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.CostVariancesExcludingVAT, 0)
		|		+ ISNULL(RemnantsOfDeviations.CostVariancesExcludingVAT, 0) AS CostVariancesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.CostVariancesLocal, 0)
		|		+ ISNULL(RemnantsOfDeviations.CostVariancesLocal, 0) AS CostVariancesLocal,
		|	ISNULL(DeviationsToDistribution.CostVariancesMgmt, 0)
		|		+ ISNULL(RemnantsOfDeviations.CostVariancesMgmt, 0) AS CostVariancesMgmt,
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesIncludingVAT, 0)
		|		+ ISNULL(RemnantsOfDeviations.AdditionalExpensesIncludingVAT, 0) AS AdditionalExpensesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesExcludingVAT, 0)
		|		+ ISNULL(RemnantsOfDeviations.AdditionalExpensesExcludingVAT, 0) AS AdditionalExpensesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.AddExpensesLocal, 0)
		|		+ ISNULL(RemnantsOfDeviations.AddExpensesLocal, 0) AS AddExpensesLocal,
		|	ISNULL(DeviationsToDistribution.AddExpensesMan, 0)
		|		+ ISNULL(RemnantsOfDeviations.AddExpensesMan, 0) AS AddExpensesMan,
		|	ISNULL(DeviationsToDistribution.VATLocal, 0)
		|		+ ISNULL(RemnantsOfDeviations.VATLocal, 0) AS VATLocal,
		|	ISNULL(DeviationsToDistribution.VATManag, 0)
		|		+ ISNULL(RemnantsOfDeviations.VATManag, 0) AS VATManag,
		|	ISNULL(DeviationsToDistribution.PermanentDifference, 0)
		|		+ ISNULL(RemnantsOfDeviations.PermanentDifference, 0) AS PermanentDifference,
		|	ISNULL(DeviationsToDistribution.CostInTaxAccounting, 0)
		|		+ ISNULL(RemnantsOfDeviations.CostInTaxAccounting, 0) AS CostInTaxAccounting,
		|	ISNULL(DeviationsToDistribution.AIT, 0)
		|		+ ISNULL(RemnantsOfDeviations.AIT, 0) AS AIT,
		|
		|	T.Count AS Count,
		|	T.NumberWithVAT AS NumberWithVAT,
		|	T.QuantityWithoutVAT AS QuantityWithoutVAT,
		|	T.NumberOfLocal AS NumberOfLocal,
		|	T.NumberOfTA AS NumberOfTA,
		|	T.NumberOfMen AS NumberOfMen
		|
		|INTO TTNodesOfDeviationsPreliminary
		|FROM
		|	TTNodesOfCurrentPeriodAdjustment AS T
		|
		|	INNER JOIN TTHasRegisteredRecordsOfGoods AS ThereAreRegisteredRecordsOfGoods
		|		ON &BeginOfPeriod = ThereAreRegisteredRecordsOfGoods.DistributionPeriod
		|		AND T.Organization = ThereAreRegisteredRecordsOfGoods.Organization
		|		AND T.Products = ThereAreRegisteredRecordsOfGoods.Products
		|		AND T.Characteristic = ThereAreRegisteredRecordsOfGoods.Characteristic
		|		AND T.InventoryOwnerAttribute = ThereAreRegisteredRecordsOfGoods.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = ThereAreRegisteredRecordsOfGoods.LineOfBusiness
		|		AND T.Department = ThereAreRegisteredRecordsOfGoods.Department
		|		AND T.StorageLocation = ThereAreRegisteredRecordsOfGoods.StorageLocation
		|
		|	LEFT JOIN TTOfDeviationToDistribution AS DeviationsToDistribution
		|		ON &BeginOfPeriod = DeviationsToDistribution.VariancePeriod
		|		AND T.Organization = DeviationsToDistribution.Organization
		|		AND T.Products = DeviationsToDistribution.Products
		|		AND T.Characteristic = DeviationsToDistribution.Characteristic
		|		AND T.InventoryOwnerAttribute = DeviationsToDistribution.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = DeviationsToDistribution.LineOfBusiness
		|		AND T.Department = DeviationsToDistribution.Department
		|		AND T.StorageLocation = DeviationsToDistribution.StorageLocation
		|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// Storno of the deviations of the previous period refers to the Balances at the beginning of the period. Are added to the table after the declination statesnanachaloperiod 
		|		AND NOT DeviationsToDistribution.ReversingEntry
		|
		|	LEFT JOIN RemainingDeviationsAtBeginningOfPeriodTT AS RemnantsOfDeviations
		|		ON T.Organization = RemnantsOfDeviations.Organization
		|		AND T.Products = RemnantsOfDeviations.Products
		|		AND T.Characteristic = RemnantsOfDeviations.Characteristic
		|		AND T.InventoryOwnerAttribute = RemnantsOfDeviations.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = RemnantsOfDeviations.LineOfBusiness
		|		AND T.Department = RemnantsOfDeviations.Department
		|		AND T.StorageLocation = RemnantsOfDeviations.StorageLocation
		|		AND T.AccountingSection = RemnantsOfDeviations.AccountingSection
		|WHERE
		|	T.NodeNumberArticleByArticle = 0
		|
		|UNION ALL
		|
		// Nodes of additional expenses and item-by-item production expenses of the current period. 
		|SELECT
		|	""2"" AS RequestSource,
		|	&BeginOfPeriod AS VariancePeriod,
		|	&BeginOfPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	TRUE AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	0 AS CostVariancesIncludingVAT,
		|	0 AS CostVariancesExcludingVAT,
		|	0 AS CostVariancesLocal,
		|	0 AS CostVariancesMgmt,
		|	0 AS AdditionalExpensesIncludingVAT,
		|	0 AS AdditionalExpensesExcludingVAT,
		|	0 AS AddExpensesLocal,
		|	0 AS AddExpensesMan,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	0 AS PermanentDifference,
		|	0 AS CostInTaxAccounting,
		|	0 AS AIT,
		|
		|	0 AS Count,
		|	T.NumberWithVAT AS NumberWithVAT,
		|	T.QuantityWithoutVAT AS QuantityWithoutVAT,
		|	T.NumberOfLocal AS NumberOfLocal,
		|	T.NumberOfTA AS NumberOfTA,
		|	T.NumberOfMen AS NumberOfMen
		|FROM
		|	TTNodesOfCurrentPeriodAdjustment AS T
		|WHERE
		|	T.NodeNumberArticleByArticle > 0
		|
		|UNION ALL
		|
		// Nodes of item-by-item expenses of the previous period. 
		|SELECT
		|	""3"" AS RequestSource,
		|	T.VariancePeriod,
		|	T.DistributionPeriod,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
		|	T.Organization AS Organization,
		|	UNDEFINED AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	UNDEFINED AS StorageLocation,
		|	T.Lot AS Lot,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberOfAdditionalExpenseAmount AS NodeNumberArticleByArticle,
		|	TRUE AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION,
		|
		|	0 AS CostVariancesIncludingVAT,
		|	0 AS CostVariancesExcludingVAT,
		|	0 AS CostVariancesLocal,
		|	0 AS CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|
		|	0 AS Count,
		|	T.NumberWithVAT,
		|	T.QuantityWithoutVAT,
		|	T.NumberOfLocal,
		|	T.NumberOfTA,
		|	T.NumberOfMen
		|FROM
		|	TTNodesOfDeviationsAreArticleByArticle AS T
		|WHERE
		|	T.Organization IN (&MediumSlipOrganizations)
		|
		|UNION ALL
		|
		|SELECT
		|	""4"" AS RequestSource,
		|	ISNULL(DeviationsToDistribution.VariancePeriod, T.DistributionPeriod) AS VariancePeriod,
		|	T.DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	UNDEFINED AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	FALSE AS TheseAreArticleByArticle,
		|	FALSE AS ThisIsUnfinishedPRODUCTION,
		|
		|	ISNULL(DeviationsToDistribution.CostVariancesIncludingVAT, 0) AS CostVariancesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.CostVariancesExcludingVAT, 0) AS CostVariancesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.CostVariancesLocal, 0) AS CostVariancesLocal,
		|	ISNULL(DeviationsToDistribution.CostVariancesMgmt, 0) AS CostVariancesMgmt,
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesIncludingVAT, 0) AS AdditionalExpensesIncludingVAT,
		|	ISNULL(DeviationsToDistribution.AdditionalExpensesExcludingVAT, 0) AS AdditionalExpensesExcludingVAT,
		|	ISNULL(DeviationsToDistribution.AddExpensesLocal, 0) AS AddExpensesLocal,
		|	ISNULL(DeviationsToDistribution.AddExpensesMan, 0) AS AddExpensesMan,
		|	ISNULL(DeviationsToDistribution.VATLocal, 0) AS VATLocal,
		|	ISNULL(DeviationsToDistribution.VATManag, 0) AS VATManag,
		|	ISNULL(DeviationsToDistribution.PermanentDifference, 0) AS PermanentDifference,
		|	ISNULL(DeviationsToDistribution.CostInTaxAccounting, 0) AS CostInTaxAccounting,
		|	ISNULL(DeviationsToDistribution.AIT, 0) AS AIT,
		|
		|	T.CountOpeningBalance + T.CountReceipt AS Count,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberWithVAT,
		|	T.CountOpeningBalance + T.CountReceipt AS QuantityWithoutVAT,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfLocal,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfTA,
		|	T.CountOpeningBalance + T.CountReceipt AS NumberOfMen
		|
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriods AS T
		|	LEFT JOIN TTHasRegisteredRecordsOfGoods AS ThereAreRegisteredRecordsOfGoods
		|		ON &BeginOfPeriod = ThereAreRegisteredRecordsOfGoods.DistributionPeriod
		|		AND &BeginOfPeriod = T.DistributionPeriod
		|		AND T.Organization = ThereAreRegisteredRecordsOfGoods.Organization
		|		AND T.Products = ThereAreRegisteredRecordsOfGoods.Products
		|		AND T.Characteristic = ThereAreRegisteredRecordsOfGoods.Characteristic
		|		AND T.InventoryOwnerAttribute = ThereAreRegisteredRecordsOfGoods.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = ThereAreRegisteredRecordsOfGoods.LineOfBusiness
		|		AND T.Department = ThereAreRegisteredRecordsOfGoods.Department
		|		AND T.StorageLocation = ThereAreRegisteredRecordsOfGoods.StorageLocation
		|
		|	LEFT JOIN TTOfDeviationToDistribution AS DeviationsToDistribution
		|		ON T.DistributionPeriod = DeviationsToDistribution.VariancePeriod
		|		AND T.Organization = DeviationsToDistribution.Organization
		|		AND T.Products = DeviationsToDistribution.Products
		|		AND T.Characteristic = DeviationsToDistribution.Characteristic
		|		AND T.InventoryOwnerAttribute = DeviationsToDistribution.InventoryOwnerAttribute
		|		AND T.LineOfBusiness = DeviationsToDistribution.LineOfBusiness
		|		AND T.Department = DeviationsToDistribution.Department
		|		AND T.StorageLocation = DeviationsToDistribution.StorageLocation
		|		AND T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		// Storno of the deviations of the previous period refers to the Balances at the beginning of the period. Are added to the table after the declination statesnanachaloperiod 
		|		AND NOT DeviationsToDistribution.ReversingEntry
		|WHERE
		|	ThereAreRegisteredRecordsOfGoods.Organization IS NULL
		|
		|INDEX BY
		|	Organization,
		|	Products
		|";
EndFunction

Function TextTTNodesOfDeviationsNumberedDeviations() // TTDeviationNodesNumbered
	Return "
		|SELECT
		|	&LastNodeNumber AS NodeNumber
		|INTO MaximumNodeNumbersOfAdditionalExpenses
		|;
		|SELECT TOP 9999999999999
		|	RECORDAUTONUMBER() AS NodeNumberIsPreliminary,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	T.Lot AS Lot,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	0 AS NodeNumberOfAdditionalExpenseAmount,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	T.TheseAreArticleByArticle AS TheseAreArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	T.CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT,
		|	T.CostVariancesLocal,
		|	T.CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	T.VATLocal,
		|	T.VATManag,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|	T.Count AS Count,
		|	T.NumberWithVAT AS NumberWithVAT,
		|	T.QuantityWithoutVAT AS QuantityWithoutVAT,
		|	T.NumberOfLocal AS NumberOfLocal,
		|	T.NumberOfTA AS NumberOfTA,
		|	T.NumberOfMen AS NumberOfMen
		|
		|INTO TTDeviationNodesNumbered
		|FROM
		|	TTNodesOfDeviationsPreliminary AS T
		|
		|ORDER BY
		|	T.NodeNumberArticleByArticle ASC,
		|	T.DistributionPeriod,
		|	T.AccountingSection,
		|	T.Organization,
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		|	T.Lot,
		|	T.ProductCostElement,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|";
EndFunction

Function TextTTDeviationNodesDeviations() // TTNodesOfDeviations
	Return "
		|SELECT TOP 9999999999999
		// The Node number field should be defined in the same way as the query for the Adoration textreferences().
		|	(CASE
		|		WHEN T.NodeNumberArticleByArticle > 0 THEN T.NodeNumberArticleByArticle
		|		ELSE T.NodeNumberIsPreliminary + ISNULL(NodeNumbers.NodeNumber, 0) END) AS NodeNumber,
		|	T.VariancePeriod AS VariancePeriod,
		|	T.DistributionPeriod AS DistributionPeriod,
		|	T.AccountingSection AS AccountingSection,
		|	T.Organization AS Organization,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	T.LineOfBusiness AS LineOfBusiness,
		|	T.Department AS Department,
		|	T.StorageLocation AS StorageLocation,
		|	T.Lot AS Lot,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.DimensionOfExpenses AS DimensionOfExpenses,
		|	T.NodeNumberArticleByArticle AS NodeNumberArticleByArticle,
		|	T.ThisIsUnfinishedPRODUCTION AS ThisIsUnfinishedPRODUCTION,
		|
		|	T.CostVariancesIncludingVAT,
		|	T.CostVariancesExcludingVAT,
		|	T.CostVariancesLocal,
		|	T.CostVariancesMgmt,
		|	T.AdditionalExpensesIncludingVAT,
		|	T.AdditionalExpensesExcludingVAT,
		|	T.AddExpensesLocal,
		|	T.AddExpensesMan,
		|	T.VATLocal,
		|	T.VATManag,
		|	T.PermanentDifference,
		|	T.CostInTaxAccounting,
		|	T.AIT,
		|	T.Count AS Count,
		|	CAST(T.NumberWithVAT / ISNULL(ReductionCoefficients.CoefficientWithVAT, 1) AS NUMBER (23,10)) AS NumberWithVAT,
		|	CAST(T.QuantityWithoutVAT / ISNULL(ReductionCoefficients.CoefficientWithoutVAT, 1) AS NUMBER (23,10)) AS QuantityWithoutVAT,
		|	CAST(T.NumberOfLocal / ISNULL(ReductionCoefficients.LocalCoefficient, 1) AS NUMBER (23,10)) AS NumberOfLocal,
		|	CAST(T.NumberOfTA / ISNULL(ReductionCoefficients.CoefficientIsTA, 1) AS NUMBER (23,10)) AS NumberOfTA,
		|	CAST(T.NumberOfMen / ISNULL(ReductionCoefficients.ManSCoefficient, 1) AS NUMBER (23,10)) AS NumberOfMen
		|
		|INTO TTNodesOfDeviations
		|FROM
		|	TTDeviationNodesNumbered AS T
		|
		|	LEFT JOIN MaximumNodeNumbersOfAdditionalExpenses AS NodeNumbers
		|		ON TRUE
		|	LEFT JOIN CoefficientsOfReductionOfNodesOfDeviations AS ReductionCoefficients
		|		ON ReductionCoefficients.NodeNumberIsPreliminary = T.NodeNumberIsPreliminary
		|
		|ORDER BY
		|	T.NodeNumberArticleByArticle ASC,
		|	T.NodeNumberIsPreliminary ASC
		|
		|INDEX BY
		|	Products,
		|	Department
		|";
EndFunction
Function TextOfTTCommunicationIsDistributionOfArticleByArticleForIssue() // TTCommunicationsDistributionOfArticleByArticleForIssue
	Return "
		|SELECT
		|	Links.SourceNodeNumber,
		|	&BeginOfPeriod AS VariancePeriod,
		|	ReceiverNodes_.Organization AS CorCompany,
		|	ReceiverNodes_.ItemsLocationAttributes.Products AS CorNomenclature,
		|	ReceiverNodes_.ItemsLocationAttributes.Characteristic AS CorCharacteristics,
		|	ReceiverNodes_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(ReceiverNodes_.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS CorLineOfBusiness,
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN ReceiverNodes_.ItemsLocationAttributes.StorageLocation
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(ReceiverNodes_.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(ReceiverNodes_.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DebitBusinessUnit,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN ReceiverNodes_.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END AS BoxStorageLocation,
		|	SourceNodes.Department,
		|	SourceNodes.LineOfBusiness,
		|	SourceNodes.ExpenseItem,
		|	SourceNodes.DimensionOfExpenses,
		|	SourceNodes.Lot,
		|	SUM(Links.ArcWeightItemByItemCostsWithVAT) AS ArcWeightWithVAT,
		|	SUM(Links.ArcWeightItemByItemCostsWithoutVAT) AS ArcWeightWithoutVAT,
		|	SUM(Links.ArcWeightItemByItemLocalCosts) AS ArcWeightLocal,
		|	SUM(Links.ArcWeightItemByItemCostsTA) AS WeightOfArcISTA,
		|	SUM(Links.ArcWeightItemByItemManCosts) AS ArcWeightMan,
		|	SUM(Links.ArcWeightNDD) AS ArcWeightNDD
		|
		|INTO TTCommunicationsDistributionOfArticleByArticleForIssue
		|FROM
		|	TtTableOfLinksItemByItemExpenses AS Links
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS SourceNodes
		|		ON SourceNodes.NodeNumber = Links.SourceNodeNumber
		|		AND SourceNodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|	INNER JOIN TTAdjustmentNodes AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = Links.ReceiverNodeNumber
		|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON ReceiverNodes_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|GROUP BY
		|	Links.SourceNodeNumber,
		|	ReceiverNodes_.Organization,
		|	ReceiverNodes_.ItemsLocationAttributes.Products,
		|	ReceiverNodes_.ItemsLocationAttributes.CHARACTERISTIC,
		|	ReceiverNodes_.InventoryOwnerAttribute,
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByLinesOfBusiness
		|			THEN ISNULL(ReceiverNodes_.ItemsLocationAttributes.Purpose.LineOfBusiness,
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END, // CorLineOfBusiness
		|	CASE
		|		WHEN NOT TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByBusinessUnits
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|			THEN ReceiverNodes_.ItemsLocationAttributes.StorageLocation
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|			THEN CAST(ReceiverNodes_.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).Department
		|		WHEN ReceiverNodes_.ItemsLocationAttributes.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|			THEN CAST(ReceiverNodes_.ItemsLocationAttributes.StorageLocation AS Catalog.CounterpartyContracts).Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END, // DebitBusinessUnit
		|	CASE
		|		WHEN TTAccountingPoliciesOfFinancialAccounting.ItemizeVariancesByWarehousesStorageLocations
		|			THEN ReceiverNodes_.ItemsLocationAttributes.StorageLocation
		|		ELSE UNDEFINED
		|	END, // BoxStorageLocation
		|	SourceNodes.Department,
		|	SourceNodes.LineOfBusiness,
		|	SourceNodes.ExpenseItem,
		|	SourceNodes.DimensionOfExpenses,
		|	SourceNodes.Lot
		|";
EndFunction

Function TextDistributionOfExpensesForProductionLotReferencesCurrentPeriod() // Uses a table with a link to the stateexploits
	Return "
		// Distribution of item-by-item production costs for batches of production of the current period.
		|SELECT
		|	""TextDistributionOfExpensesForProductionLotReferencesCurrentPeriod"" AS RequestSource,
		|	SourceNodes.NodeNumber AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	ReceiverNodes_.ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS CorNomenclature,
		|	UNDEFINED AS BoxStorageLocation,
		|	ReceiverNodes_.Lot AS CorLot,
		|	ReceiverNodes_.ExpenseItem AS ExpenseItemOfWriteOff,
		|	&BeginOfPeriod AS PeriodOfSource,
		|	&BeginOfPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	Links.ArcWeightItemByItemCostsWithVAT   AS NumberWithVAT,
		|	Links.ArcWeightItemByItemCostsWithoutVAT AS QuantityWithoutVAT,
		|	Links.ArcWeightItemByItemLocalCosts   AS NumberOfLocal,
		|	(CASE
		|		WHEN Links.NotDistributedInNalAccounting OR NOT Links.AcceptedVNU
		|			THEN 0
		|		ELSE Links.ArcWeightItemByItemCostsTA END) AS NumberOfTA,
		|	Links.ArcWeightItemByItemManCosts AS NumberOfMen
		|FROM
		|	TtTableOfLinksItemByItemExpenses AS Links
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.NodeNumberArticleByArticle = Links.SourceNodeNumber
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS ReceiverNodes_
		|		ON ReceiverNodes_.NodeNumber = Links.ReceiverNodeNumber
		|";
EndFunction

Function TextDistributionOfExpensesForIssueOfCurrentPeriod() // Uses in connection with the distribution of the status of each issue
	Return "
		// Distribution of item-by-item production costs for manufactured products.
		|SELECT
		|	""TextDistributionOfExpensesForIssueOfCurrentPeriod"" AS RequestSource,
		|	Links.SourceNodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	Links.Lot AS Lot,
		|	Links.ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	Links.CorNomenclature AS CorNomenclature,
		|	Links.BoxStorageLocation AS BoxStorageLocation,
		|	UNDEFINED AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	&BeginOfPeriod AS PeriodOfSource,
		|	&BeginOfPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	Links.ArcWeightWithVAT	AS NumberWithVAT,
		|	Links.ArcWeightWithoutVAT AS QuantityWithoutVAT,
		|	Links.ArcWeightLocal	AS NumberOfLocal,
		|	Links.WeightOfArcISTA		AS NumberOfTA,
		|	Links.ArcWeightMan	AS NumberOfMen
		|FROM
		|	TTCommunicationsDistributionOfArticleByArticleForIssue AS Links
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = Links.CorCompany
		|		AND ReceiverNodes_.Products = Links.CorNomenclature
		|		AND ReceiverNodes_.Characteristic = Links.CorCharacteristics
		|		AND ReceiverNodes_.InventoryOwnerAttribute = Links.CorInventoryOwnerAttribute
		|		AND ReceiverNodes_.LineOfBusiness = Links.CorLineOfBusiness	
		|		AND ReceiverNodes_.Department = Links.DebitBusinessUnit
		|		AND ReceiverNodes_.StorageLocation = Links.BoxStorageLocation
		|		AND ReceiverNodes_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		AND ReceiverNodes_.DistributionPeriod = &BeginOfPeriod
		|";
EndFunction

Function TextOfTTOfRegisteredRecordedInventoryCostsForPeriodsOfDeviation() // TTOfRegisteredRecordsOfInventoryCostsByPeriod
	Return "
		|SELECT
		|	T.ThisIsCurrentPeriod,
		|	T.ThereIsCorPart,
		|	T.DistributionPeriod,
		|	CAST(SourceNodes.NodeNumber AS NUMBER(31,0)) AS SourceNodeNumber,
		|	(CASE
		|		WHEN NOT NodesReceiversBranches.NodeNumber IS NULL
		|			THEN NodesReceiversBranches.NodeNumber
		|		ELSE ReceiverNodes_.NodeNumber END) AS ReceiverNodeNumber,
		|	SourceNodes.VariancePeriod AS DeviationPeriodSource,
		|	SourceNodes.DistributionPeriod AS DistributionPeriodSource,
		|	(CASE
		|		WHEN NOT NodesReceiversBranches.DistributionPeriod IS NULL
		|			THEN NodesReceiversBranches.DistributionPeriod
		|		ELSE ReceiverNodes_.DistributionPeriod END) AS PeriodOfDistributionReceiver,
		|
		|	T.Period AS Period,
		|	T.Organization,
		// Dimensions
		|	T.Products,
		|	T.Characteristic,
		|	T.InventoryOwnerAttribute,
		|	T.LineOfBusiness,
		|	T.Department,
		|	T.StorageLocation,
		// Cost measurements
		|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	T.AccountingSection AS AccountingSection,
		|	UNDEFINED AS Lot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|	UNDEFINED AS FinancialAccountingDimension,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
		// Cor Attributes of deviations
		|	T.CorCompany,
		|	T.CorNomenclature,
		|	T.CorCharacteristics,
		|	T.CorInventoryOwnerAttribute,
		|	T.CorLineOfBusiness,
		|	T.DebitBusinessUnit,
		|	T.BoxStorageLocation,
		// COR Cost Attributes
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	T.CorAccountingSection,
		|	UNDEFINED AS CorLot,
		|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributesCorr,
		|	UNDEFINED AS CorControllingAttributes,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS CorVATActivityTypes,
		// Cor Attributes
		|	T.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	T.ExpenseItemOfWriteOff,
		|	T.DimensionOfExpenses,
		|	T.AssetAndLiabilityItem,
		|	T.AssetsLiabilitiesDimension,
		|	T.GLAccountSettings,
		|	T.BusinessOperation,
		|	T.BusinessTransactionSetting,
		|	T.WriteOffDeviationsToCostOfGoodsSelling,
		|	T.FinRecordID AS FinRecordID,
		|	T.Count AS Count
		|
		|INTO TTOfRegisteredRecordsOfInventoryCostsByPeriod
		|FROM
		|	TTRegisteredRecordsOfInventoryCostsByPeriodRolledUp AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Products = T.Products
		|		AND SourceNodes.Characteristic = T.Characteristic
		|		AND SourceNodes.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND SourceNodes.LineOfBusiness = T.LineOfBusiness	
		|		AND SourceNodes.Department = T.Department
		|		AND SourceNodes.StorageLocation = T.StorageLocation
		|		AND SourceNodes.AccountingSection = T.AccountingSection
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriod
		|
		|	LEFT JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Products = T.CorNomenclature
		|		AND ReceiverNodes_.Products <> VALUE(Catalog.Products.EmptyRef)
		|		AND ReceiverNodes_.Characteristic = T.CorCharacteristics
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND ReceiverNodes_.LineOfBusiness = T.CorLineOfBusiness	
		|		AND ReceiverNodes_.Department = T.DebitBusinessUnit
		|		AND ReceiverNodes_.StorageLocation = T.BoxStorageLocation
		|		AND ReceiverNodes_.AccountingSection = T.CorAccountingSection
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|
		|	LEFT JOIN TTNodesOfDeviations AS NodesReceiversBranches
		|		ON NodesReceiversBranches.Organization = T.CorCompany
		|		AND NodesReceiversBranches.Products = T.CorNomenclature
		|		AND NodesReceiversBranches.Products <> VALUE(Catalog.Products.EmptyRef)
		|		AND NodesReceiversBranches.Characteristic = T.CorCharacteristics
		|		AND NodesReceiversBranches.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND NodesReceiversBranches.LineOfBusiness = T.CorLineOfBusiness	
		|		AND NodesReceiversBranches.Department = T.DebitBusinessUnit
		|		AND NodesReceiversBranches.StorageLocation = T.BoxStorageLocation
		|		AND NodesReceiversBranches.AccountingSection = T.CorAccountingSection
		|		AND NodesReceiversBranches.DistributionPeriod = T.DistributionPeriod
		|		AND T.CorCompany <> T.Organization
		|		AND T.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|
		|INDEX BY
		|	SourceNodeNumber
		|";
EndFunction

Function TextOfRelationshipOfInventoryCostBetweenPeriodsOfDeviation() // In connection with the worship of the worshiping_3, uses the node to correct past periods, in the node of worship
	Return "
		// The relationship of the cost of goods between periods.
		|SELECT
		|	""TextOfRelationshipOfInventoryCostBetweenPeriodsOfDeviation"" AS RequestSource,
		|	SourceNodes.NodeNumber AS SourceNodeNumber,
		|	ReceiverNodes_.NodeNumber AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot AS Lot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS CorItemsLocationAttributes,
		|	T.Products AS CorNomenclature,
		|	T.StorageLocation AS BoxStorageLocation,
		|	T.Lot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	SourceNodes.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	TRUE AS TheseAreLeftovers,
		|	SUM(T.CountOpeningBalance) AS Count,
		|	SUM(T.CountOpeningBalance) AS NumberWithVAT,
		|	SUM(T.CountOpeningBalance) AS QuantityWithoutVAT,
		|	SUM(T.CountOpeningBalance) AS NumberOfLocal,
		|	SUM(T.CountOpeningBalance) AS NumberOfTA,
		|	SUM(T.CountOpeningBalance) AS NumberOfMen
		|FROM
		|	TTNodesOfAdjustmentOfPastPeriods AS T
		|
		|	INNER JOIN TTNodesOfDeviations AS SourceNodes
		|		ON SourceNodes.Organization = T.Organization
		|		AND SourceNodes.Products = T.Products
		|		AND SourceNodes.Characteristic = T.Characteristic
		|		AND SourceNodes.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND SourceNodes.LineOfBusiness = T.LineOfBusiness	
		|		AND SourceNodes.Department = T.Department
		|		AND SourceNodes.StorageLocation = T.StorageLocation
		|		AND SourceNodes.AccountingSection = T.AccountingSection
		|		AND SourceNodes.DistributionPeriod = T.DistributionPeriodPrevious
		|		AND T.CountOpeningBalance <> 0
		|
		|	INNER JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.Organization
		|		AND ReceiverNodes_.Products = T.Products
		|		AND ReceiverNodes_.Characteristic = T.Characteristic
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.InventoryOwnerAttribute
		|		AND ReceiverNodes_.LineOfBusiness = T.LineOfBusiness	
		|		AND ReceiverNodes_.Department = T.Department
		|		AND ReceiverNodes_.StorageLocation = T.StorageLocation
		|		AND SourceNodes.AccountingSection = T.AccountingSection
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|
		|GROUP BY
		|	SourceNodes.NodeNumber,
		|	ReceiverNodes_.NodeNumber,
		|	T.Products,
		|	T.StorageLocation,
		|	T.Lot,
		|	SourceNodes.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction

Function TextAllocationOfExpensesForInventoryCostsDeviations() // vtvyaziotcleniipredivaration_5, uses vtmovementprochierachievementsreferences
	Return "
		// Distribution of expenses for the cost of goods.
		|SELECT
		|	""TextAllocationOfExpensesForInventoryCostsDeviations"" AS RequestSource,
		|	T.NodeNumber AS SourceNodeNumber,
		|	ISNULL(ReceiverNodes_.NodeNumber, -1) AS ReceiverNodeNumber,
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	UNDEFINED AS StorageLocation,
		|	UNDEFINED AS Lot,
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	T.CorNomenclature AS CorNomenclature,
		|	T.BoxStorageLocation AS BoxStorageLocation,
		|	T.CorLot AS CorLot,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItemOfWriteOff,
		|	T.DistributionPeriod AS PeriodOfSource,
		|	ReceiverNodes_.DistributionPeriod AS ReceiverPeriod,
		|	FALSE TheseAreLeftovers,
		|	0 AS Count,
		|	SUM(T.AmountIncludingVAT)   AS NumberWithVAT,
		|	SUM(T.AmountExcludingVAT) AS QuantityWithoutVAT,
		|	SUM(T.SumCompl)   AS NumberOfLocal,
		|	SUM(T.AmountFA)     AS NumberOfTA,
		|	SUM(T.SumMan)    AS NumberOfMen
		|FROM
		|	RegisteredRecordsTTOtherExpensesByPeriod AS T
		|
		// When distributing the costs of the receiving node, there may not be if the costs are distributed to the Balance of goods
		// for which there are no Registered Records.
		|	LEFT JOIN TTNodesOfDeviations AS ReceiverNodes_
		|		ON ReceiverNodes_.Organization = T.CorCompany
		|		AND ReceiverNodes_.Products = T.CorNomenclature
		|		AND ReceiverNodes_.Characteristic = T.CorCharacteristics
		|		AND ReceiverNodes_.InventoryOwnerAttribute = T.CorInventoryOwnerAttribute
		|		AND ReceiverNodes_.LineOfBusiness = T.CorLineOfBusiness	
		|		AND ReceiverNodes_.Department = T.DebitBusinessUnit
		|		AND ReceiverNodes_.StorageLocation = T.BoxStorageLocation
		|		AND ReceiverNodes_.AccountingSection = T.CorAccountingSection
		|		AND ReceiverNodes_.DistributionPeriod = T.DistributionPeriod
		|WHERE
		|	T.CorNomenclature <> VALUE(Catalog.Products.EmptyRef)
		|	AND T.CorLot = UNDEFINED
		|
		|GROUP BY
		|	T.NodeNumber,
		|	ISNULL(ReceiverNodes_.NodeNumber, -1),
		|	T.ExpenseItem,
		|	T.CorItemsLocationAttributes,
		|	T.CorNomenclature,
		|	T.BoxStorageLocation,
		|	T.CorLot,
		|	T.DistributionPeriod,
		|	ReceiverNodes_.DistributionPeriod
		|";
EndFunction
	
#EndRegion

#Region StageProcedures_PreparationOfDataForSolvingCaseInclusionExclusionOfVAT

Procedure AdjustmentNodesInclusionExclusionOfVAT(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataForSolvingCaseOfInclusionExclusionOfVAT");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"AdjustmentNodesInclusionExclusionOfVAT, ServiceConnection_InclusionExclusionOfVAT");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextForSolvingCaseOfInclusionExclusionOfVAT(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function TextForSolvingCaseOfInclusionExclusionOfVAT(CalculationParameters = Undefined) Export
	
	QueryText = 
	"SELECT
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType,
	|	SUM(Cost_.LocalCost) AS LocalCost,
	|	SUM(Cost_.CostMan) AS CostMan
	|INTO ValueOfVAT
	|FROM
	|	TTCashEstimatedTurnoverCostOfGoods AS Cost_
	|WHERE
	|	Cost_.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
	|	AND Cost_.LotCalculation
	|	AND NOT Cost_.ReversingEntry
	|
	|GROUP BY
	|	Cost_.Organization,
	|	Cost_.ItemsLocationAttributes,
	|	Cost_.AccountingSection,
	|	Cost_.InventoryOwnerAttribute,
	|	Cost_.Lot,
	|	Cost_.LotVendorAttributes,
	|	Cost_.FinancialAccountingDimension,
	|	Cost_.VATActivityType
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdjustmentNodes.NodeNumber,
	|
	|	ISNULL(ValueOfVAT.LocalCost, 0) AS LocalCost,
	|	ISNULL(ValueOfVAT.CostMan, 0)  AS CostMan
	|
	|INTO AdjustmentNodesInclusionExclusionOfVAT
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN ValueOfVAT AS ValueOfVAT
	|	ON ValueOfVAT.Organization                   = AdjustmentNodes.Organization
	|		AND ValueOfVAT.ItemsLocationAttributes = AdjustmentNodes.ItemsLocationAttributes
	|		AND ValueOfVAT.AccountingSection                = AdjustmentNodes.AccountingSection
	|		AND ValueOfVAT.InventoryOwnerAttribute                 = AdjustmentNodes.InventoryOwnerAttribute
	|		AND ValueOfVAT.Lot                     = AdjustmentNodes.Lot
	|		AND ValueOfVAT.LotVendorAttributes       = AdjustmentNodes.LotVendorAttributes
	|		AND ValueOfVAT.FinancialAccountingDimension  = AdjustmentNodes.FinancialAccountingDimension
	|		AND ValueOfVAT.VATActivityType         = AdjustmentNodes.VATActivityType
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
	|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	CAST(CASE
	|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
	|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
	|			THEN 0
	|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
	|	END AS NUMBER(28,10)) AS ArcWeightLocalCost,
	|	CAST(CASE
	|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
	|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
	|			THEN 0
	|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
	|	END AS NUMBER(28,10)) AS ArcWeightManCost
	|
	|INTO ServiceConnection_InclusionExclusionOfVAT
	|FROM
	|	TTWriteOffs AS WriteOffMovements
	|WHERE
	|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
	|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
	|	AND NOT WriteOffMovements.TransferToAnotherOrganization
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
	|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
	|
	|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightLocalCost,
	|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightManCost
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForSolutionOfRAReservesForImpairmentOfInventories

// The stage of "Preparation of the data for the resolution of the service of the reserve for the depreciation of supplies"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForSolvingCaseOfReservesForImpairmentOfInventories(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters,
		"PreparationOfDataForSolvingCaseOfReservesForImpairmentOfInventories");
	
	TablesToSave_ = New Array;
	TablesToSave_.Add("ThereIsReturnableWaste");
	TablesToSave_.Add("TTAdjustmentNodes");
	TablesToSave_.Add("ConnectionsOfNodesOfReservesUnderImpairmentOfStocks");
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		StrConcat(TablesToSave_, ","));
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextForSolvingCaseOfReservesForImpairmentOfInventories(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

Function TextForSolvingCaseOfReservesForImpairmentOfInventories(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextTTHasReturnableWaste());
	QueriesTexts.Add(TextTT_Adjustments_MaterialAndLaborCosts());
	QueriesTexts.Add(TextOfRelationshipBetweenNodesOfReservesForImpairmentOfInventories());
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextOfRelationshipBetweenNodesOfReservesForImpairmentOfInventories()

	Return "
		|SELECT
		|	Cost_.SourceNodeNumber            AS SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber            AS ReceiverNodeNumber,
		|	MAX(Cost_.TransferReserve)   AS TransferReserve,
		|	MAX(Cost_.RestoreReserves) AS RestoreReserves,
		|	SUM(Cost_.Count)	           AS ArcWeight
		|
		|INTO ConnectionsOfNodesOfReservesUnderImpairmentOfStocks
		|FROM (
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		(CASE
		// The output of products at the planned cost, if deviations are written off to the cost of goods sold.
		// Reserves for supply of inventories are written off to the cost of goods sold at the time of production.
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|			 AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN FALSE
		// The conditions for the formation of the Transfer Reserve field must correspond to the conditions for the formation of the Write off Reserves field
		// in the procedure for calculating the cost of cost correction.Adjust the cost of writing inventory().
		|		WHEN (ProductAnalysisSource.Products = ProductAnalysis.Products
		|			AND ProductAnalysisSource.Characteristic = ProductAnalysis.Characteristic
		|			OR Cost_.AccountingSection
		|				= VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|
		|			 OR VALUETYPE(Cost_.Lot) = TYPE(Catalog.ProductionLots)
		|			)
		|				THEN TRUE
		|			ELSE FALSE END) AS TransferReserve,
		|	(CASE
		// The output of products at the planned cost, if deviations are written off to the cost of goods sold.
		// Reserves for supply of inventories are written off to the cost of goods sold at the time of production.
		|		WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
		|		 AND Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|		 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|		 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS RestoreReserves,
		|		Cost_.Count
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|		ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND SourceAdjustmentNodes.AccountingSection                 = Cost_.AccountingSection
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                  = Cost_.InventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization                 = Cost_.Organization
		|			AND (SourceAdjustmentNodes.Lot              	    = Cost_.Lot
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.LotVendorAttributes        = Cost_.LotVendorAttributes
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.FinancialAccountingDimension   = Cost_.FinancialAccountingDimension
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.VATActivityType          = Cost_.VATActivityType
		|				OR &ScheduledJob)
		|			AND NOT Cost_.OfficialTypeOfMovementParish
		|			AND NOT (Cost_.ReversingEntry 
		|					AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections))
		|		
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS ProductAnalysisSource
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = ProductAnalysisSource.Ref
		|
		|		INNER JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.CorAccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND (AdjustmentNodesReceiver.Lot                    = Cost_.CorLot
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributesCorr
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.CorControllingAttributes
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesReceiver.VATActivityType        = Cost_.CorVATActivityTypes
		|				OR &ScheduledJob)
		|		
		|		
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS ProductAnalysis
		|		ON ProductAnalysis.Ref = AdjustmentNodesReceiver.ItemsLocationAttributes
		|
		|	WHERE
		|		SourceAdjustmentNodes.NodeNumber <> AdjustmentNodesReceiver.NodeNumber
		|		AND NOT Cost_.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
		|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
		|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
		|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
		|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|
		|	UNION ALL
		|
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesTransmissionReceiver.NodeNumber AS ReceiverNodeNumber,
		|		(CASE
		// The conditions for the formation of the Transfer Reserve field must correspond to the conditions for the formation of the Write off Reserves field
		// in the procedure for calculating the cost of cost correction.Adjust the cost of writing inventory().
		|		WHEN ProductAnalysisSource.Products = ProductAnalysis.Products
		|			AND ProductAnalysisSource.Characteristic = ProductAnalysis.Characteristic
		|				THEN TRUE
		|			ELSE FALSE END) AS TransferReserve,
		|	FALSE AS RestoreReserves,
		|		Cost_.Count
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = Cost_.ItemsLocationAttributes
		|			AND SourceAdjustmentNodes.AccountingSection                 = Cost_.AccountingSection
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                  = Cost_.InventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization                 = Cost_.Organization
		|			AND (SourceAdjustmentNodes.Lot              	    = Cost_.Lot
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.LotVendorAttributes        = Cost_.LotVendorAttributes
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.FinancialAccountingDimension   = Cost_.FinancialAccountingDimension
		|				OR &ScheduledJob)
		|			AND (SourceAdjustmentNodes.VATActivityType          = Cost_.VATActivityType
		|				OR &ScheduledJob)
		|			AND NOT Cost_.OfficialTypeOfMovementParish
		|			AND NOT (Cost_.ReversingEntry 
		|					AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections))
		|		
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS ProductAnalysisSource
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes = ProductAnalysisSource.Ref
		|
		|		LEFT JOIN TTInterconnectedCompanies AS InterconnectedOrganizations
		|		ON InterconnectedOrganizations.Organization1 = Cost_.Organization
		|			AND InterconnectedOrganizations.Organization2 = Cost_.CorCompany
		|		
		|		INNER JOIN TTAdjustmentNodes AS AdjustmentNodesTransmissionReceiver
		|		ON
		|			AdjustmentNodesTransmissionReceiver.ItemsLocationAttributes  = Cost_.CorItemsLocationAttributes
		|			AND AdjustmentNodesTransmissionReceiver.AccountingSection               = Cost_.CorAccountingSection
		|			AND AdjustmentNodesTransmissionReceiver.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND AdjustmentNodesTransmissionReceiver.Organization               = Cost_.CorCompany
		|			AND (AdjustmentNodesTransmissionReceiver.Lot                   = Cost_.CorLot
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.LotVendorAttributes     = Cost_.LotVendorAttributesCorr
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.FinancialAccountingDimension = Cost_.CorControllingAttributes
		|				OR &ScheduledJob)
		|			AND (AdjustmentNodesTransmissionReceiver.VATActivityType        = Cost_.CorVATActivityTypes
		|				OR &ScheduledJob)
		|			AND Cost_.AccountingSection    <> VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
		|			AND Cost_.CorCompany <> Cost_.Organization
		|			AND Cost_.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		// The Transfer of the impairment allowance can only occur between related entities.
		|			AND InterconnectedOrganizations.Organization2 IS NOT NULL
		|		
		|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS ProductAnalysis
		|		ON AdjustmentNodesTransmissionReceiver.ItemsLocationAttributes = ProductAnalysis.Ref
		|
		|	WHERE
		|		SourceAdjustmentNodes.NodeNumber <> AdjustmentNodesTransmissionReceiver.NodeNumber
		|		AND NOT Cost_.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
		|			VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting),
		|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
		|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
		|
		// Reducing the weight of arcs when returning goods from the customer or when adjusting sales in the negative,
		// if the type of VAT activity does not change during the return.
		|	UNION ALL
		|	
		|	SELECT
		|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		FALSE AS TransferReserve,
		|		FALSE AS RestoreReserves,
		|		-Cost_.Count AS Count
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|
		|		INNER JOIN TTAdjustmentNodes AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.ItemsLocationAttributes   = Cost_.CorItemsLocationAttributes
		|			AND SourceAdjustmentNodes.AccountingSection               = Cost_.AccountingSection
		|			AND SourceAdjustmentNodes.InventoryOwnerAttribute                = Cost_.CorInventoryOwnerAttribute
		|			AND SourceAdjustmentNodes.Organization               = Cost_.Organization
		|			AND SourceAdjustmentNodes.Lot                    = Cost_.Lot
		|			AND SourceAdjustmentNodes.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND SourceAdjustmentNodes.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND SourceAdjustmentNodes.VATActivityType        = Cost_.VATActivityTypeShipments
		|
		|		INNER JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes   = Cost_.ItemsLocationAttributes
		|			AND AdjustmentNodesReceiver.AccountingSection               = Cost_.AccountingSection
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Cost_.InventoryOwnerAttribute
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.Organization
		|			AND AdjustmentNodesReceiver.Lot                    = Cost_.Lot
		|			AND AdjustmentNodesReceiver.LotVendorAttributes      = Cost_.LotVendorAttributes
		|			AND AdjustmentNodesReceiver.FinancialAccountingDimension = Cost_.FinancialAccountingDimension
		|			AND AdjustmentNodesReceiver.VATActivityType        = Cost_.VATActivityType
		|	WHERE
		|		NOT Cost_.OfficialTypeOfMovementParish
		|		AND NOT Cost_.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
		|		AND Cost_.EntryType = VALUE(Enum.LotRecordTypes.ReversingEntry)
		|		AND Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.ReverseOfSale)
		|		AND SourceAdjustmentNodes.NodeNumber <> AdjustmentNodesReceiver.NodeNumber
		|
		|	) AS Cost_
		|GROUP BY
		|	Cost_.SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparingDataToAddressCaseByCaseCosts

#Region Description_PreparingDataToAddressCaseByCaseCosts

// At the stage of preparing the data for the resolution of item-by-item expenditures, the initial data is generated to solve the case
// in terms of item-by-item production costs.
// 
// Important features:
//	According to one cost analysis, there may be several "Cost Allocation" documents (from one to three)
//	with different checkboxes for accounting.
//	At the same time, there will be one line in the table with the table of the item of expenditure, in which the fields will be filled in according to the data of all
//	the "Cost Allocation" documents.
//
// Temporary table of vtuzlykorrectionstateynyerreferences
//	A table of item-by-item production sub-assets and sub-assets covered by reserves. 
//	Used to generate temporary tables:
//	- Receivers of reserves, reserves of expenses, reserves of current expenses - for writing off reserves of upcoming expenses
//	- The initial value of the constant difference, in the correction node of the constant difference, in the table of the constant difference
//	- VtUzlyKorrectirovkiNU 
//	- The cost of non-perfected production, the cost of non-perfected productionregl
//
// Temporary table of initial coststateinspend
//	Contains the calculated initial cost in each item-by-item expenses sub-asset, if the item-by-item expenses are charged to item-by-item expenses.
//	It is formed from the cost of three components of the cost of goods that have already been calculated at previous stages:
//	Cost + Additional expenses + Labor costs, taking into account reserves for impairment of inventories.

#EndRegion

// The stage of "Preparing the data for resolving the status of accounting data"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForSolvingSLEItemByItemExpensesVATAccounting(CalculationParameters) Export
	
	If Not CalculationOfCostCached.AllocateItemByItemExpensesRecursively() Then
		Return;
	EndIf;
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForSolvingSLEItemByItemExpensesVATAccounting");
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(CalculationParameters);
	
	PreparingDataToAddressCaseByCaseCosts(CalculationParameters);
	
	NewTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(
		CalculationParameters,
		ExistingTT + ", TTWriteOffOfItemByItemCosts");
	
	CalculationParameters.Insert("TemporaryTablesSLEItemByItemExpenses", NewTT);
	
EndProcedure
	
// Stage " Preparation of the data for the resolution of the workstatesexternal links"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparingDataToAddressCaseByCaseCosts(CalculationParameters)
	
	FirstRun = Not CalculationParameters.Property("TemporaryTablesSLEItemByItemExpenses");
	
	If Not CalculationOfCostCached.AllocateItemByItemExpensesRecursively()
	 Or Not FirstRun Then
	 	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataToAddressCaseByCaseCosts");
	EndIf;
	
	If Not FirstRun Then
		CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, CalculationParameters.TemporaryTablesSLEItemByItemExpenses);
		CalculationParameters.Delete("TemporaryTablesSLEItemByItemExpenses");
	EndIf;
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTNodesAdjustmentsItemByItemUnfinishedProductionCosts,
		|ReserveMovementDocuments, ProvisionsForExpenses, TtTableOfLinksItemByItemExpenses,
		|TTTableOfLinksItemByItemExpensesWithRecorders,
		|InitialCostItemByItemCosts,
		|SLENodes_ItemByItemExpensesOfEnterprise, SLENodes_ItemByItemExpensesOfOrganizations,
		|SLEConnections_ItemByItemExpensesOfEnterprise, SLEConnections_ItemByItemExpensesOfOrganizations");
		
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextOfRequestToResolveCaseItemByItemExpenses(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function TextOfRequestToResolveCaseItemByItemExpenses(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array;
	QueriesTexts.Add(CostCalculationCostAdjustment.TextTTWorkInProgress(CalculationParameters));
	QueriesTexts.Add(TextTTWriteOffForArticlesFromHIA());
	QueriesTexts.Add(TextOfAdjustmentItemByItemUnfinishedProductionCosts());
	QueriesTexts.Add(TextTTIssues());
	QueriesTexts.Add(TextTTCostOfGoodsWriteOff());
	QueriesTexts.Add(TextTTAdjustmentNodesAreArticleByArticle());
	QueriesTexts.Add(TEXTOFCOMMUNICATIONOFPRODUCTIONCostsSubAssetsWriteOffToOTHERItemsOfExpenditure());
	QueriesTexts.Add(TextAuxiliaryTablesForTableOfLinksItemByItemExpenses());
	QueriesTexts.Add(TextTTTableOfLinksArticleByArticleExpensesWithRecorders());
	QueriesTexts.Add(TextTTTableOfRelationsItemByItemExpenses());
	QueriesTexts.Add(TextInitialCostItemByItemExpenses());
	QueriesTexts.Add(TextVATCost());
	QueriesTexts.Add(TextSLENodes_ItemByItemExpensesOfEnterprise());
	QueriesTexts.Add(TextSLENodes_ItemByItemExpensesOfOrganizations());
	QueriesTexts.Add(TextSLEJoin_ItemByItemExpensesOfEnterprise());
	QueriesTexts.Add(TextSLEJoin_ItemByItemExpensesOfOrganizations());
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextOfAdjustmentItemByItemUnfinishedProductionCosts() // vt vtuzlykorrection of the status of the output
	
	#Region RequestTextForRecentNumbers
	DataDefinitionRequestText = "
		|	SELECT
		|		0 AS NodeNumber,
		|		0 AS NodeNumberUnfinishedProduction,
		|		0 AS ReserveNodeNumber,
		|		0 AS HIATransitNodeNumber
		|";

	RequestTextLastNumberForAdditionalCostAdjustment = "
		|	SELECT
		|		MAX(T.NodeNumber),
		|		0,
		|		0,
		|		0
		|	FROM
		|		AdditionalCostAdjustmentNodes AS T
		|";

	RequestTextLastTtNumberAdjustmentNodes = "
		|	SELECT
		|		MAX(T.NodeNumber),
		|		0,
		|		0,
		|		0
		|	FROM
		|		TTAdjustmentNodes AS T
		|";

	RequestTextLastNumberTtWorkInProgress = "
		|	SELECT
		|		0,
		|		MAX(T.NodeNumber),
		|		0,
		|		0
		|	FROM
		|		TTWorkInProgress AS T
		|";

	RequestTextLastNumberCostItemsCoveredByReserves = "
		|	SELECT
		|		0,
		|		0,
		|		MAX(T.NodeNumber),
		|		0
		|	FROM
		|		ExpenditureItemsCoveredByReserves AS T
		|";

	RequestTextLastTtNumberInitialDataOfTransitNodesForExpensesBetweenHIA = "
		|	SELECT
		|		0,
		|		0,
		|		0,
		|		MAX(T.NodeNumber)
		|	FROM
		|		TTInitialDataOfTransitNodesOfExpendituresBetweenHIA AS T
		|";

	RequestTextsForRecentIssues = New Array;
	RequestTextsForRecentIssues.Add(DataDefinitionRequestText);
	RequestTextsForRecentIssues.Add(RequestTextLastNumberForAdditionalCostAdjustment);
	RequestTextsForRecentIssues.Add(RequestTextLastTtNumberAdjustmentNodes);
	RequestTextsForRecentIssues.Add(RequestTextLastNumberTtWorkInProgress);
	RequestTextsForRecentIssues.Add(RequestTextLastNumberCostItemsCoveredByReserves);
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		RequestTextsForRecentIssues.Add(RequestTextLastTtNumberInitialDataOfTransitNodesForExpensesBetweenHIA);
	EndIf;
	CompositionOfRequestsForRecentNumbers = StrConcat(RequestTextsForRecentIssues, TMCommonUse.QuerySeparatorInJoin());	
	
	RequestTextForRecentNumbers = "
		|SELECT
		|	MAX(T.NodeNumber) AS NodeNumber,
		|	MAX(T.NodeNumberUnfinishedProduction) AS NodeNumberUnfinishedProduction,
		|	MAX(T.ReserveNodeNumber) AS ReserveNodeNumber,
		|	MAX(T.HIATransitNodeNumber) AS HIATransitNodeNumber
		|INTO LastNodeNumber
		|FROM &CompositionOfRequestsForRecentNumbers AS T";
	
	RequestTextForRecentNumbers = StrReplace(RequestTextForRecentNumbers, "&CompositionOfRequestsForRecentNumbers","("+CompositionOfRequestsForRecentNumbers+")");
	#EndRegion
		
	#Region TextOfRequestForNodesInWorkInProgress
	TextOfRequestForNodesInWorkInProgress = "
		|SELECT
		|	""TextOfRequestForNodesInWorkInProgress""			AS RequestSource,
		|	LastNodeNumber.NodeNumber
		|		+ Table.NodeNumber										AS NodeNumber,
		|	Table.Organization                							AS Organization,
		|	Table.AccountingSection                		 					AS AccountingSection,
		|	Table.Lot                     							AS Lot,
		|	Table.LotVendorAttributes       							AS LotVendorAttributes,
		|	Table.RowCodeProducts       							AS RowCodeProducts,
		|	Table.Department						 				AS Department,
		|	Table.VATActivityType									AS VATActivityType,
		|	Table.LineOfBusiness    							AS LineOfBusiness,
		|	Table.ExpenseItem             							AS ExpenseItem,
		|	Table.DimensionOfExpenses          							AS DimensionOfExpenses,
		|	Table.ProductCostElement									AS ProductCostElement,
		|	Table.Stage												AS Stage,
		|	Table.ProductsGroup										AS ProductsGroup,
		|	Table.RuleOfCostAllocatingToProductionLots							AS RuleOfCostAllocatingToProductionLots,
		// Resources for calculating the cost of goods of the enterprise.
		|	Table.Count                 							AS WeightArticleByArticle,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|			THEN Table.Sum
		|		ELSE 0 END)											AS ItemizedFixedCostsIncludingVAT,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN Table.Sum
		|		ELSE 0 END)											AS ItemizedVariableCostsIncludingVAT,
		|
		|	Table.QuantityWithoutVAT           							AS WeightArticleByArticleWithoutVAT,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|			THEN Table.AmountExcludingVAT
		|		ELSE 0 END)											AS ItemizedFixedCostsExcludingVAT,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN Table.AmountExcludingVAT
		|		ELSE 0 END)											AS ItemizedVariableCostsExcludingVAT,
		// Resources for calculating the cost of goods of organizations.
		|	Table.NumberOfLocal                 						AS WeightArticleByArticleLocal,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|			THEN Table.SumCompl
		|		ELSE 0	END)											AS ItemizedFixedCostsCompl,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN Table.SumCompl
		|		ELSE 0	END)											AS ItemizedVariableCostsCompl,
		|	Table.NumberOfTA                 						AS WeightItemByItemTA,
		|	Table.AmountFA          									AS AmountFA,
		|	Table.PermanentDifference          							AS PermanentDifference,
		|
		|	Table.NumberOfMen                 						AS WeightArticleByArticleMan,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|			THEN Table.SumMan
		|		ELSE 0	END)											AS ItemizedFixedCostsManag,
		|	(CASE
		|		WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN Table.SumMan
		|		ELSE 0	END)											AS ItemizedVariableCostsManag,
		|
		|	Table.NumberOfPersonalData										AS WeightItemByItemNDD,
		|	Table.CostOfPersonalIncomeTax										AS ItemByItemCostOfPersonalIncomeTax
		|
		|INTO TTNodesAdjustmentsItemByItemUnfinishedProductionCosts
		|FROM
		|	TTWorkInProgress AS Table
		|LEFT JOIN
		|	ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|ON
		|	Table.ExpenseItem = AssetRef.Ref
		|LEFT JOIN LastNodeNumber AS LastNodeNumber
		|	ON TRUE
		|WHERE
		|	(Table.Count <> 0
		|		OR Table.QuantityWithoutVAT <> 0
		|		OR Table.NumberOfLocal <> 0
		|		OR Table.NumberOfTA <> 0
		|		OR Table.NumberOfPersonalData <> 0
		|		OR Table.NumberOfMen <> 0
		|		OR Table.SumCompl <> 0
		|		OR Table.AmountFA <> 0
		|		OR Table.SumMan <> 0
		|		OR Table.CostOfPersonalIncomeTax <> 0
		|		)
		|	AND Table.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|";
	#EndRegion

	#Region TextOfRequestForCostItemsCoveredByReserves
	TextOfRequestForCostItemsCoveredByReserves = "
		// Data on other items of expenditure
		|SELECT
		|	""TextOfRequestForCostItemsCoveredByReserves""		AS RequestSource,
		|	LastNodeNumber.NodeNumber
		|		+ LastNodeNumber.NodeNumberUnfinishedProduction
		|		+ Table.NodeNumber										AS NodeNumber,
		|	Table.Organization                							AS Organization,
		|	VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
		|	UNDEFINED                       							AS Lot,
		|	UNDEFINED                       							AS LotVendorAttributes,
		|	0															AS RowCodeProducts,
		|	Table.Department                       				AS Department,
		|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATActivityType,
		|	Table.LineOfBusiness    							AS LineOfBusiness,
		|	Table.ExpenseItem										AS ExpenseItem,
		|	Table.DimensionOfExpenses                       			AS DimensionOfExpenses,
		|	VALUE(Catalog.ProductCostElements.EmptyRef)			AS ProductCostElement,
		|	VALUE(Catalog.ProductionStages.EmptyRef)			AS Stage,
		|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|	VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		// Resources for calculating the cost of goods of the enterprise.
		|	0															AS WeightArticleByArticle,
		|	0															AS ItemizedFixedCostsIncludingVAT,
		|	0															AS ItemizedVariableCostsIncludingVAT,
		|	0															AS WeightArticleByArticleWithoutVAT,
		|	0															AS ItemizedFixedCostsExcludingVAT,
		|	0															AS ItemizedVariableCostsExcludingVAT,
		// Resources for calculating the cost of goods of organizations.
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfLocal, 0) = 0 THEN 1
		|		ELSE 0 END)											AS WeightArticleByArticleLocal,
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfLocal, 0) = 0
		|			THEN Table.SumCompl
		|		ELSE 0 END)											AS ItemizedFixedCostsCompl,
		|	0															AS ItemizedVariableCostsCompl,
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfTA, 0) = 0 THEN 1
		|		ELSE 0 END)											AS WeightItemByItemTA,
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfTA, 0) = 0
		|			THEN Table.AmountFA
		|		ELSE 0 END)											AS AmountFA,
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfLocal, 0) = 0
		|			THEN Table.PermanentDifference
		|		ELSE 0 END)											AS PermanentDifference,
		|
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfMen, 0) = 0 THEN 1
		|		ELSE 0 END)											AS WeightArticleByArticleMan,
		|	(CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfMen, 0) = 0
		|			THEN Table.SumMan
		|		ELSE 0 END)											AS ItemizedFixedCostsManag,
		|	0															AS ItemizedVariableCostsManag,
		|
		|	CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfPersonalData, 0) = 0 THEN 1
		|		ELSE 0
		|	END														AS WeightItemByItemNDD,
		|	CASE
		|		WHEN ISNULL(UnfinishedProduction.NumberOfPersonalData, 0) = 0
		|			THEN Table.CostOfPersonalIncomeTax
		|		ELSE 0
		|	END														AS ItemByItemCostOfPersonalIncomeTax
		|FROM
		|	ExpenditureItemsCoveredByReserves AS Table
		|
		|	LEFT JOIN TTWorkInProgress AS UnfinishedProduction
		|	ON Table.Organization = UnfinishedProduction.Organization
		|		AND Table.Department = UnfinishedProduction.Department
		|		AND Table.LineOfBusiness = UnfinishedProduction.LineOfBusiness
		|		AND Table.ExpenseItem = UnfinishedProduction.ExpenseItem
		|		AND Table.DimensionOfExpenses = UnfinishedProduction.DimensionOfExpenses
		|		AND UnfinishedProduction.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|
		|	LEFT JOIN LastNodeNumber AS LastNodeNumber
		|		ON TRUE
		|WHERE
		|	ISNULL(UnfinishedProduction.NumberOfLocal, 0) = 0
		|	OR ISNULL(UnfinishedProduction.NumberOfTA, 0) = 0
		|	OR ISNULL(UnfinishedProduction.NumberOfMen, 0) = 0
		|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion

	#Region RequestTextOfTTNodesInitialDataOfTransitNodesForExpensesBetweenHIA
	RequestTextOfTTNodesInitialDataOfTransitNodesForExpensesBetweenHIA = "
		// Data on transits to cost objects
		|	SELECT
		|		""RequestTextOfTTNodesInitialDataOfTransitNodesForExpensesBetweenHIA"" AS RequestSource,
		|		LastNodeNumber.NodeNumber
		|		+ LastNodeNumber.NodeNumberUnfinishedProduction
		|		+ LastNodeNumber.ReserveNodeNumber
		|		+ Table.NodeNumber											AS NodeNumber,
		|		Table.Organization											AS Organization,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
		|		VALUE(Catalog.ProductionLots.EmptyRef)		AS Lot,
		|		UNDEFINED												AS LotVendorAttributes,
		|		0															AS RowCodeProducts,	
		|		Table.Department										AS Department,
		|		VALUE(Enum.VATTaxationTypes.EmptyRef)  AS VATActivityType,
		|		Table.LineOfBusiness								AS LineOfBusiness,
		|		Table.ExpenseItem										AS ExpenseItem,
		|		Table.DimensionOfExpenses									AS DimensionOfExpenses,
		|		VALUE(Catalog.ProductCostElements.EmptyRef)			AS ProductCostElement,
		|		VALUE(Catalog.ProductionStages.EmptyRef)			AS Stage,
		|		VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		|		Table.LedWeight										AS WeightArticleByArticle,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0 
		|			AND (AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef))
		|				THEN ISNULL(T.Sum,0)
		|			ELSE 0
		|		END														AS ItemizedFixedCostsIncludingVAT,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0 AND AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN ISNULL(T.Sum,0)
		|			ELSE 0
		|		END														AS ItemizedVariableCostsIncludingVAT,
		|		Table.LedWeight										AS WeightArticleByArticleWithoutVAT,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0  
		|			AND (AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef))
		|				THEN ISNULL(T.AmountExcludingVAT,0)
		|			ELSE 0
		|		END														AS ItemizedFixedCostsExcludingVAT,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0 AND AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN ISNULL(T.AmountExcludingVAT,0)
		|			ELSE 0
		|		END														AS ItemizedVariableCostsExcludingVAT,
		|		Table.LocalWeightGiven									AS WeightArticleByArticleLocal,
		|		CASE
		|			WHEN NOT Table.LocalWeightGiven = 0  
		|			AND (AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef))
		|				THEN ISNULL(T.SumCompl,0)
		|			ELSE 0
		|		END														AS ItemizedFixedCostsCompl,
		|		CASE
		|			WHEN NOT Table.LocalWeightGiven = 0 AND AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN ISNULL(T.SumCompl,0)
		|			ELSE 0
		|		END														AS ItemizedVariableCostsCompl,
		|		Table.LocalWeightGiven									AS WeightItemByItemTA,
		|		CASE
		|			WHEN Table.LocalWeightGiven = 0
		|					OR AssetRef.CostAllocationOptionTax IN (
		|						VALUE(Enum.CostAllocationOptions.ToDeferredExpenses), 
		|						VALUE(Enum.CostAllocationOptions.DoNotAllocate)
		|						)
		|				THEN 0
		|			ELSE ISNULL(T.SumCompl, 0) - ISNULL(T.PermanentDifference, 0) - ISNULL(T.CostTD, 0)
		|		END AS AmountFA,
		|		CASE
		|			WHEN NOT Table.LocalWeightGiven = 0
		|				THEN ISNULL(T.PermanentDifference, 0)
		|			ELSE 0
		|		END														AS PermanentDifference,
		|		Table.LedWeight													AS WeightArticleByArticleMan,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0 
		|			AND (AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef))
		|				THEN ISNULL(T.SumMan,0)
		|			ELSE 0
		|		END														AS ItemizedFixedCostsManag,
		|		CASE
		|			WHEN NOT Table.LedWeight = 0 AND AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN ISNULL(T.SumMan,0)
		|			ELSE 0
		|		END														AS ItemizedVariableCostsManag,
		|
		|	Table.GivenWeightOfNDT AS WeightItemByItemNDD,
		|	CASE
		|		WHEN ISNULL(Table.GivenWeightOfNDT, 0) <> 0
		|			THEN T.AITAmount
		|		ELSE 0
		|	END															AS ItemByItemCostOfPersonalIncomeTax
		|	FROM
		|		TTInitialDataOfTransitNodesOfExpendituresBetweenHIA AS Table
		|	LEFT JOIN
		|		ExpenseAmounts AS T
		|	ON
		|		Table.Organization = T.Organization
		|		AND Table.Department = T.Department
		|		AND Table.LineOfBusiness = T.LineOfBusiness
		|		AND Table.ExpenseItem = T.ExpenseItem
		|		AND Table.DimensionOfExpenses = T.DimensionOfExpenses
		|	LEFT JOIN
		|		ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|	ON
		|		Table.ExpenseItem = AssetRef.Ref
		|
		|	LEFT JOIN LastNodeNumber AS LastNodeNumber
		|		ON TRUE
		|
		|	WHERE
		|		NOT (Table.Weight = 0 AND Table.LocalWeight = 0)
		|		AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion

	#Region TextOfRequestForTTWriteOffsForArticlesFromHIA
	TextOfRequestForTTWriteOffsForArticlesFromHIA = "
		// Data on write-off to items from cost objects
		|	SELECT
		|		""TextOfRequestForTTWriteOffsForArticlesFromHIA"" 				AS RequestSource,
		|		LastNodeNumber.NodeNumber
		|			+ LastNodeNumber.NodeNumberUnfinishedProduction
		|			+ LastNodeNumber.ReserveNodeNumber
		|			+ LastNodeNumber.HIATransitNodeNumber
		|			+ Table.NodeNumber										AS NodeNumber,
		|		Table.Organization											AS Organization,
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts) AS AccountingSection,
		|		VALUE(Catalog.ProductionLots.EmptyRef)		AS Lot,
		|		VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
		|		0															AS RowCodeProducts,	
		|		Table.Department										AS Department,
		|		VALUE(Enum.VATTaxationTypes.EmptyRef)  AS VATActivityType,
		|		Table.LineOfBusiness							AS LineOfBusiness,
		|		Table.ExpenseItem										AS ExpenseItem,
		|		Table.DimensionOfExpenses									AS DimensionOfExpenses,
		|		VALUE(Catalog.ProductCostElements.EmptyRef)			AS ProductCostElement,
		|		VALUE(Catalog.ProductionStages.EmptyRef)			AS Stage,
		|		VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|		VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef) AS RuleOfCostAllocatingToProductionLots,
		// Resources for calculating the cost of goods of the enterprise.
		|		0	AS WeightArticleByArticle,
		|		0	AS ItemizedFixedCostsIncludingVAT,
		|		0	AS ItemizedVariableCostsIncludingVAT,
		|
		|		0	AS WeightArticleByArticleWithoutVAT,
		|		0	AS ItemizedFixedCostsExcludingVAT,
		|		0	AS ItemizedVariableCostsExcludingVAT,
		// Resources for calculating the cost of goods of organizations.
		|		0	AS WeightArticleByArticleLocal,
		|		0	AS ItemizedFixedCostsCompl,
		|		0	AS ItemizedVariableCostsCompl,
		|		0	AS WeightItemByItemTA,
		|		0	AS AmountFA,
		|		0	AS PermanentDifference,
		|
		|		0	AS WeightArticleByArticleMan,
		|		0	AS ItemizedFixedCostsManag,
		|		0	AS ItemizedVariableCostsManag,
		|
		|		0 AS WeightItemByItemNDD,
		|		0 AS ItemByItemCostOfPersonalIncomeTax
		|	FROM
		|		TTWriteOffsForArticlesFromHIA AS Table
		|
		|	LEFT JOIN LastNodeNumber AS LastNodeNumber
		|		ON TRUE
		|WHERE
		|	&MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForNodesInWorkInProgress);
	QueriesTexts.Add(TextOfRequestForCostItemsCoveredByReserves);
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		QueriesTexts.Add(RequestTextOfTTNodesInitialDataOfTransitNodesForExpensesBetweenHIA);
		QueriesTexts.Add(TextOfRequestForTTWriteOffsForArticlesFromHIA);
	EndIf;
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());	
	
	
	QueryText = QueryText + "
	|INDEX BY
	|	NodeNumber
	|";
	
	Return RequestTextForRecentNumbers 
		+ Common.QueryBatchSeparator()
		+ QueryText;
	
EndFunction

Function TextTTWriteOffForArticlesFromHIA()
	Return "
	// Data on write-off to items from cost objects
	|	SELECT
	|		RECORDAUTONUMBER()											AS NodeNumber,
	|		DD.Organization												AS Organization,
	|		WriteOffItems.Department								AS Department,
	|		WriteOffItems.LineOfBusiness						AS LineOfBusiness,
	|		WriteOffItems.ExpenseItem								AS ExpenseItem,
	|		WriteOffItems.DimensionOfExpenses							AS DimensionOfExpenses
	|	INTO TTWriteOffsForArticlesFromHIA
	|	FROM
	|		Document.AllocationOfOtherCosts AS DD
	|	INNER JOIN
	|		Document.AllocationOfOtherCosts.WriteOff AS WriteOffItems
	|	ON
	|		DD.Ref = WriteOffItems.Ref
	|	LEFT JOIN TTWorkInProgress AS UnfinishedProduction
	|	ON DD.Organization = UnfinishedProduction.Organization
	|		AND WriteOffItems.Department = UnfinishedProduction.Department
	|		AND WriteOffItems.LineOfBusiness = UnfinishedProduction.LineOfBusiness
	|		AND WriteOffItems.ExpenseItem = UnfinishedProduction.ExpenseItem
	|		AND WriteOffItems.DimensionOfExpenses = UnfinishedProduction.DimensionOfExpenses
	|		AND UnfinishedProduction.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|WHERE
	|	UnfinishedProduction.NodeNumber IS NULL
	|	AND (DD.Posted AND BEGINOFPERIOD(DD.Date, MONTH) = &BeginOfPeriod)
	|	AND DD.AllocateToExpenseItems AND DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|";
EndFunction

// The text of the formation of the temp table of product releases.
// 
// Returns:
//	String - Query text 
//
Function TextTTIssues() Export
	Return "
		|SELECT
		|	(CASE 
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN CalculationLoggers.Ref
		|		ELSE DD.Recorder END)	AS Recorder,
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute, 
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType,
		|	SUM(DD.Count) AS Count,
		|	MAX(DD.FinRecordID) AS FinRecordID
		|
		|INTO TTIssues
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS DD
		|
		|	LEFT JOIN TTCostCalculationRecorders AS CalculationLoggers
		|		ON CalculationLoggers.Organization = DD.Organization
		|WHERE
		|	DD.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ProductsRelease),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
		|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit),
		|		VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
		|
		|	AND DD.OfficialTypeOfMovementParish
		|	AND DD.Count > 0
		|	AND NOT DD.ReversingEntry
		|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|
		|GROUP BY
		|	(CASE 
		|		WHEN DD.Organization IN (&MediumSlipOrganizations)
		|			THEN CalculationLoggers.Ref
		|		ELSE DD.Recorder END),
		|	DD.Organization,
		|	DD.ItemsLocationAttributes,
		|	DD.AccountingSection,
		|	DD.InventoryOwnerAttribute, 
		|	DD.Lot,
		|	DD.LotVendorAttributes,
		|	DD.FinancialAccountingDimension,
		|	DD.VATActivityType
		|
		|INDEX BY
		|	Recorder,
		|	ItemsLocationAttributes
		|";
EndFunction

Function TextTTAdjustmentNodesAreArticleByArticle()
	Return "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.Organization AS Organization,
	|	AdjustmentNodes.LineOfBusiness,
	|	AdjustmentNodes.Department,
	|	AdjustmentNodes.ExpenseItem AS ExpenseItem,
	|	AdjustmentNodes.DimensionOfExpenses AS DimensionOfExpenses,
	|	AdjustmentNodes.AccountingSection,
	|	AdjustmentNodes.ProductCostElement,
	|	AdjustmentNodes.Stage,
	|	AdjustmentNodes.ProductsGroup,
	|	AdjustmentNodes.RuleOfCostAllocatingToProductionLots,
	|	AdjustmentNodes.Lot,
	|	AdjustmentNodes.LotVendorAttributes,
	|	AdjustmentNodes.RowCodeProducts,
	|	AdjustmentNodes.VATActivityType
	|
	|INTO TTAdjustmentNodesAreArticleByArticle
	|FROM
	|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
	|INDEX BY
	|	Organization, ExpenseItem, DimensionOfExpenses
	|";
EndFunction 

Function TEXTOFCOMMUNICATIONOFPRODUCTIONCostsSubAssetsWriteOffToOTHERItemsOfExpenditure()
	Return "
		|SELECT
		|	SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	Shares.Organization					AS Organization,
		|	Shares.DebitBusinessUnit				AS Department,
		|	Shares.CorExpenseItem				AS ExpenseItem,
		|	Shares.CorExpenditureDimension			AS DimensionOfExpenses,
		|	Shares.CorLineOfBusiness		AS LineOfBusiness,
		|	Shares.CostShare                  AS ArcWeightWithVAT,
		|	Shares.ShareOfValueWithoutVAT            AS ArcWeightWithoutVAT,
		|	Shares.ShareOfLocalValue              AS ArcWeightLocal,
		|	Shares.ShareOfManSCost               AS ArcWeightMan,
		|	Shares.ShareValueTa                AS WeightOfArcISTA,
		|	Shares.ShareOfCostOfPersonalIncomeTax               AS ArcWeightNDD
		|
		|INTO ConnectionsOfProductionCostsSubAssetsWriteOffToOtherItemsOfExpenditure
		|FROM
		|	SharesOfProductionCosts AS Shares
		|
		|	INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|	ON Shares.Recorder = Attributes.Ref
		|
		|	INNER JOIN TTAdjustmentNodesAreArticleByArticle AS SourceAdjustmentNodes
		|	ON Attributes.ExpenseItem = SourceAdjustmentNodes.ExpenseItem
		|		AND Attributes.DimensionOfExpenses = SourceAdjustmentNodes.DimensionOfExpenses
		|		AND Attributes.LineOfBusiness = SourceAdjustmentNodes.LineOfBusiness
		|		AND Attributes.Department = SourceAdjustmentNodes.Department
		|		AND Attributes.Organization = SourceAdjustmentNodes.Organization
		|WHERE
		|	Shares.CorExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND Shares.CorExpenseItem <> UNDEFINED
		|	AND Shares.EntryType = VALUE(Enum.LotRecordTypes.ExpenseAs)
		|";
EndFunction

Function TextAuxiliaryTablesForTableOfLinksItemByItemExpenses()
	
	Return "
		// Auxiliary tables for the distribution of production costs for production batches
		|SELECT
		|	Expenses.Recorder AS Recorder,
		|	Expenses.Organization AS Organization,
		|	Expenses.Department AS Department,
		|	Expenses.LineOfBusiness AS LineOfBusiness,
		|	Expenses.CorLineOfBusiness AS CorLineOfBusiness,
		|	Expenses.ExpenseItem AS ExpenseItem,
		|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	Expenses.ProductCostElement AS ProductCostElement,
		|	Expenses.Stage AS Stage,
		|	Expenses.ProductsGroup AS ProductsGroup,
		|	Expenses.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	Expenses.DocumentOfProductionIssue AS DocumentOfProductionIssue,
		|	Expenses.ReleaseLotDimension AS ReleaseLotDimension,
		|	Expenses.RowCodeProducts AS RowCodeProducts,
		|	Attributes.Department AS DistributionDivision,
		|
		|	Expenses.IndicatorOfAllocationToLot,
		|	Expenses.IndicatorOfAllocationToLotExcludingVAT,
		|	Expenses.IndicatorOfAllocationToLotCompl,
		|	Expenses.RateOfAssignmentToBatchIsTA,
		|	Expenses.IndicatorOfAllocationToLotManag,
		|	Expenses.IndicatorOfAttributionToPartyNDD,
		|	(CASE
		|		WHEN ArticleDetails_1.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN TRUE
		|		ELSE FALSE END) AS ItemizedFixed,
		|	(CASE
		|		WHEN ArticleDetails_1.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN TRUE
		|		ELSE FALSE END)                                             AS ItemizedVariable,
		|	ISNULL(ArticleDetails_1.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|	Attributes.TaxAccounting
		|		AND NOT Attributes.LocalAccounting AS NotDistributedInBuhAccounting,
		|	Attributes.LocalAccounting
		|		AND NOT Attributes.TaxAccounting AS NotDistributedInNalAccounting
		|INTO OtherExpensesOfUnfinishedProductionForLotReferencesOfProduction1
		|FROM
		|	TTOtherWorkInProgressExpenses__ AS Expenses
		|	INNER JOIN Document.AllocationOfOtherCosts AS Attributes
		|		ON Attributes.Ref = Expenses.Recorder
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON ArticleDetails_1.Ref = Expenses.ExpenseItem
		|WHERE
		|	Expenses.Organization IN (&CompanyArray)
		|	AND Expenses.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND (Expenses.IndicatorOfAllocationToLot <> 0
		|		OR Expenses.IndicatorOfAllocationToLotExcludingVAT <> 0
		|		OR Expenses.IndicatorOfAllocationToLotCompl <> 0
		|		OR Expenses.IndicatorOfAllocationToLotManag <> 0
		|		OR Expenses.RateOfAssignmentToBatchIsTA <> 0
		|		OR Expenses.IndicatorOfAttributionToPartyNDD <> 0
		|		)
		|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	DistributionDivision,
		|	CorLineOfBusiness,
		|	Organization
		|;
		|
		|SELECT
		|	T.NodeNumber,
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses
		|INTO TTAdjustmentUnitsItemByItemProductionCosts
		|FROM
		|	TTAdjustmentNodesAreArticleByArticle AS T
		|WHERE
		|	T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	LineOfBusiness,
		|	Organization
		|;
		|
		|SELECT
		|	Expenses.Recorder AS Recorder,
		|	SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	Expenses.Organization AS Organization,
		|	Expenses.Department AS Department,
		|	Expenses.LineOfBusiness AS LineOfBusiness,
		|	Expenses.CorLineOfBusiness AS CorLineOfBusiness,
		|	Expenses.ExpenseItem AS ExpenseItem,
		|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	Expenses.ProductCostElement AS ProductCostElement,
		|	Expenses.Stage AS Stage,
		|	Expenses.ProductsGroup AS ProductsGroup,
		|	Expenses.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	Expenses.DocumentOfProductionIssue AS DocumentOfProductionIssue,
		|	Expenses.ReleaseLotDimension AS ReleaseLotDimension,
		|	Expenses.RowCodeProducts AS RowCodeProducts,
		|
		|	Expenses.IndicatorOfAllocationToLot,
		|	Expenses.IndicatorOfAllocationToLotExcludingVAT,
		|	Expenses.IndicatorOfAllocationToLotCompl,
		|	Expenses.RateOfAssignmentToBatchIsTA,
		|	Expenses.IndicatorOfAllocationToLotManag,
		|	Expenses.IndicatorOfAttributionToPartyNDD,
		|	Expenses.ItemizedFixed,
		|	Expenses.ItemizedVariable,
		|	Expenses.AcceptedVNU,
		|	Expenses.NotDistributedInBuhAccounting,
		|	Expenses.NotDistributedInNalAccounting
		|INTO OtherExpensesOfUnfinishedProductionForLotReferencesOfProduction2
		|FROM
		|	OtherExpensesOfUnfinishedProductionForLotReferencesOfProduction1 AS Expenses
		|	INNER JOIN TTAdjustmentUnitsItemByItemProductionCosts AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.Organization                  = Expenses.Organization
		|			AND SourceAdjustmentNodes.Department             = Expenses.DistributionDivision
		|			AND SourceAdjustmentNodes.LineOfBusiness   = Expenses.CorLineOfBusiness
		|			AND SourceAdjustmentNodes.ExpenseItem            = Expenses.ExpenseItem
		|			AND SourceAdjustmentNodes.DimensionOfExpenses         = Expenses.DimensionOfExpenses
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	DocumentOfProductionIssue,
		|	Stage,
		|	Department,
		|	LineOfBusiness,
		|	Organization
		|;
		|
		|SELECT
		|	T.NodeNumber,
		|	T.Organization,
		|	T.Department,
		|	T.LineOfBusiness,
		|	T.ExpenseItem,
		|	T.DimensionOfExpenses,
		|	T.ProductCostElement,
		|	T.Stage,
		|	T.ProductsGroup,
		|	T.RuleOfCostAllocatingToProductionLots,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.RowCodeProducts,
		|	T.VATActivityType
		|INTO TTAdjustmentNodesAreArticleByArticleUnfinishedProduction
		|FROM
		|	TTAdjustmentNodesAreArticleByArticle AS T
		|WHERE
		|	T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Lot,
		|	Stage,
		|	Department,
		|	LineOfBusiness,
		|	Organization
	    |
		|;
		// Auxiliary tables for the distribution of production costs for output
		|SELECT
		|	Expenses.Recorder AS Recorder,
		|	Expenses.Organization AS Organization,
		|	Expenses.Department AS Department,
		|	Expenses.LineOfBusiness AS LineOfBusiness,
		|	Expenses.AccountingSection AS AccountingSection,
		|	Expenses.LotVendorAttributesCorr AS LotVendorAttributesCorr,
		|	Expenses.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Expenses.ExpenseItem AS ExpenseItem,
		|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	Expenses.VATActivityType AS VATActivityType,
		|	Expenses.ProductCostElement AS ProductCostElement,
		|	Expenses.Stage AS Stage,
		|	Expenses.ProductsGroup AS ProductsGroup,
		|	Expenses.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	Expenses.DocumentOfProductionIssue AS DocumentOfProductionIssue,
		|	Expenses.ReleaseLotDimension AS ReleaseLotDimension,
		|	Expenses.RowCodeProducts AS RowCodeProducts,
		|	ISNULL(AnalyticsOfProductsWithoutDestination.DimensionKey, Expenses.ProductsAccountingDimension) AS ProductsAccountingDimension,
		|
		|	Expenses.IndicatorOfAllocationToIssue,
		|	Expenses.IndicatorOfAttributionToOutputWithoutVAT,
		|	Expenses.LocalIssueAttributionRate,
		|	Expenses.IndicatorOfAttributionToIssueIsTA,
		|	Expenses.IndicatorOfAssignmentToIssueOfMan,
		|	Expenses.IndicatorOfAttributionToIssueOfPersonalIncomeTax,
		|	(CASE
		|		WHEN ArticleDetails_1.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				OR ArticleDetails_1.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE END) AS ItemizedFixed,
		|	(CASE
		|		WHEN ArticleDetails_1.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN TRUE
		|		ELSE FALSE END)                                             AS ItemizedVariable,
		|	ISNULL(ArticleDetails_1.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		// When allocating to output, all expenses should be included in the cost of output
		// , regardless of the options for allocating the item of expenditure in AC and TA. 
		// Distribution options are taken into account only when distributing to production batches. 
		|	FALSE AS NotDistributedInBuhAccounting,
		|	FALSE AS NotDistributedInNalAccounting
		|INTO OtherExpensesOfUnfinishedProductionForIssue1
		|FROM
		|	TTOtherWorkInProgressExpenses__ AS Expenses
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|		ON Dimension.Ref = Expenses.ProductsAccountingDimension
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfProductsWithoutDestination
		|		ON AnalyticsOfProductsWithoutDestination.Products     = Dimension.Products
		|		AND AnalyticsOfProductsWithoutDestination.Characteristic    = Dimension.Characteristic
		|		AND AnalyticsOfProductsWithoutDestination.Series             = Dimension.Series
		|		AND AnalyticsOfProductsWithoutDestination.StorageLocation     = Dimension.StorageLocation
		|		AND AnalyticsOfProductsWithoutDestination.Purpose        = VALUE(Catalog.Assignments.EmptyRef)
		|		AND AnalyticsOfProductsWithoutDestination.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|		AND NOT &KeepRecordsOfInventoryCostByAssignments
		|	LEFT JOIN TTOvz AS TTOvz
		|		ON Expenses.DimensionOfExpenses = TTOvz.ConstCenter
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON ArticleDetails_1.Ref = Expenses.ExpenseItem
		|WHERE
		|	Expenses.Organization IN (&CompanyArray)
		|	AND Expenses.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND Expenses.DocumentSource <> VALUE(Document.AllocationOfOtherCosts.EmptyRef)
		|	AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|INDEX BY
		|	Recorder,
		|	ProductsAccountingDimension
	    |
		|;
		|SELECT
		|	Expenses.Recorder AS Recorder,
		|	Expenses.Organization AS Organization,
		|	Expenses.Department AS Department,
		|	Expenses.LineOfBusiness AS LineOfBusiness,
		|	Expenses.AccountingSection AS AccountingSection,
		|	Expenses.ExpenseItem AS ExpenseItem,
		|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
		|	Expenses.VATActivityType AS VATActivityType,
		|	Expenses.ProductCostElement AS ProductCostElement,
		|	Expenses.Stage AS Stage,
		|	Expenses.ProductsGroup AS ProductsGroup,
		|	Expenses.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
		|	Expenses.DocumentOfProductionIssue AS DocumentOfProductionIssue,
		|	Expenses.ReleaseLotDimension AS ReleaseLotDimension,
		|	Expenses.RowCodeProducts AS RowCodeProducts,
		|	Expenses.ProductsAccountingDimension AS ProductsAccountingDimension,
		|
		|	Releases.InventoryOwnerAttribute AS ReleasesInventoryOwnerAttributes,
		|	Releases.Lot AS IssuesLotReference,
		|	Releases.LotVendorAttributes AS ReleasesLotVendorAttributes,
		|	Releases.FinancialAccountingDimension AS IssuesOfControllingAttributeOfFinancialAccounting,
		|	Releases.VATActivityType AS ReleasesVATActivityType,
		|
		|	Expenses.IndicatorOfAllocationToIssue,
		|	Expenses.IndicatorOfAttributionToOutputWithoutVAT,
		|	Expenses.LocalIssueAttributionRate,
		|	Expenses.IndicatorOfAttributionToIssueIsTA,
		|	Expenses.IndicatorOfAssignmentToIssueOfMan,
		|	Expenses.IndicatorOfAttributionToIssueOfPersonalIncomeTax,
		|	Expenses.ItemizedFixed,
		|	Expenses.ItemizedVariable,
		|	Expenses.AcceptedVNU,
		|	Expenses.NotDistributedInBuhAccounting,
		|	Expenses.NotDistributedInNalAccounting
		|INTO OtherExpensesOfUnfinishedProductionForIssue2
		|FROM
		|	OtherExpensesOfUnfinishedProductionForIssue1 AS Expenses
		|		LEFT JOIN TTIssues AS Releases
		|		ON Releases.Recorder = Expenses.Recorder
		|			AND Releases.ItemsLocationAttributes = Expenses.ProductsAccountingDimension
		|			AND Releases.AccountingSection              = Expenses.AccountingSection
		|			AND Releases.LotVendorAttributes     = Expenses.LotVendorAttributesCorr
		|			AND Releases.InventoryOwnerAttribute               = Expenses.InventoryOwnerAttribute
		|			AND (Releases.VATActivityType      = Expenses.VATActivityType
		|				OR Expenses.VATActivityType = UNDEFINED)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	DocumentOfProductionIssue,
		|	Stage,
		|	Department,
		|	LineOfBusiness,
		|	Organization
	    |
		|;
		|SELECT
		|	SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	Expenses.Organization AS Organization,
		|	Expenses.AccountingSection AS AccountingSection,
		|	Expenses.ProductsAccountingDimension AS ProductsAccountingDimension,
		|
		|	Expenses.ReleasesInventoryOwnerAttributes,
		|	Expenses.IssuesLotReference,
		|	Expenses.ReleasesLotVendorAttributes,
		|	Expenses.IssuesOfControllingAttributeOfFinancialAccounting,
		|	Expenses.ReleasesVATActivityType,
		|
		|	Expenses.IndicatorOfAllocationToIssue,
		|	Expenses.IndicatorOfAttributionToOutputWithoutVAT,
		|	Expenses.LocalIssueAttributionRate,
		|	Expenses.IndicatorOfAttributionToIssueIsTA,
		|	Expenses.IndicatorOfAssignmentToIssueOfMan,
		|	Expenses.IndicatorOfAttributionToIssueOfPersonalIncomeTax,
		|	Expenses.ItemizedFixed,
		|	Expenses.ItemizedVariable,
		|	Expenses.AcceptedVNU,
		|	Expenses.NotDistributedInBuhAccounting,
		|	Expenses.NotDistributedInNalAccounting
		|INTO OtherExpensesOfUnfinishedProductionForIssue3
		|FROM
		|	OtherExpensesOfUnfinishedProductionForIssue2 AS Expenses
		|		INNER JOIN TTAdjustmentNodesAreArticleByArticleUnfinishedProduction AS SourceAdjustmentNodes
		|		ON SourceAdjustmentNodes.Organization                 = Expenses.Organization
		|			AND SourceAdjustmentNodes.Department            = Expenses.Department
		|			AND SourceAdjustmentNodes.ExpenseItem           = Expenses.ExpenseItem
		|			AND SourceAdjustmentNodes.DimensionOfExpenses        = Expenses.DimensionOfExpenses
		|			AND SourceAdjustmentNodes.ProductCostElement        = Expenses.ProductCostElement
		|			AND SourceAdjustmentNodes.Stage                     = Expenses.Stage
		|			AND SourceAdjustmentNodes.ProductsGroup          = Expenses.ProductsGroup
		|			AND SourceAdjustmentNodes.RuleOfCostAllocatingToProductionLots = Expenses.RuleOfCostAllocatingToProductionLots
		|			AND SourceAdjustmentNodes.Lot                   = Expenses.DocumentOfProductionIssue
		|			AND SourceAdjustmentNodes.LotVendorAttributes     = Expenses.ReleaseLotDimension
		|			AND SourceAdjustmentNodes.RowCodeProducts       = Expenses.RowCodeProducts
		|			AND SourceAdjustmentNodes.VATActivityType       = Expenses.VATActivityType
		|			AND SourceAdjustmentNodes.LineOfBusiness  = Expenses.LineOfBusiness
		|INDEX BY
		|	Organization,
		|	ProductsAccountingDimension,
		|	AccountingSection,
		|	ReleasesInventoryOwnerAttributes,
		|	IssuesLotReference,
		|	ReleasesLotVendorAttributes,
		|	IssuesOfControllingAttributeOfFinancialAccounting,
		|	ReleasesVATActivityType
		|";
	
EndFunction

Function TextTTTableOfLinksArticleByArticleExpensesWithRecorders()
	MainQuery = "
		|SELECT
		|	Cost_.Recorder                            AS Recorder,
		|	Cost_.SourceNodeNumber                      AS SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber                      AS ReceiverNodeNumber,
		|	CAST(SUM(Cost_.ArcWeightItemByItemCostsWithVAT) AS NUMBER(31,10))   AS ArcWeightItemByItemCostsWithVAT,
		|	CAST(SUM(Cost_.ArcWeightItemByItemCostsWithoutVAT) AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|	CAST(SUM(Cost_.ArcWeightItemByItemLocalCosts) AS NUMBER(31,10))   AS ArcWeightItemByItemLocalCosts,
		|	CAST(SUM(Cost_.ArcWeightItemByItemCostsTA) AS NUMBER(31,10))     AS ArcWeightItemByItemCostsTA,
		|	CAST(SUM(Cost_.ArcWeightItemByItemManCosts) AS NUMBER(31,10))    AS ArcWeightItemByItemManCosts,
		|	CAST(SUM(Cost_.ArcWeightNDD) AS NUMBER(31,10))						AS ArcWeightNDD,
		|	MAX(Cost_.ItemizedFixed)        AS ItemizedFixed,
		|	MAX(Cost_.ItemizedVariable)        AS ItemizedVariable,
		|	MAX(Cost_.RestoreReserves)       AS RestoreReserves,
		|	MAX(Cost_.AcceptedVNU)               AS AcceptedVNU,
		|	MAX(Cost_.NotDistributedInBuhAccounting)    AS NotDistributedInBuhAccounting,
		|	MAX(Cost_.NotDistributedInNalAccounting)	 AS NotDistributedInNalAccounting,
		|	MAX(Cost_.SourceOnMediumSlip)	 AS SourceOnMediumSlip
		|
		|INTO TTTableOfLinksItemByItemExpensesWithRecorders
		|FROM &CompositionOfLinks AS Cost_
		|GROUP BY
		|	Cost_.Recorder,
		|	Cost_.SourceNodeNumber,
		|	Cost_.ReceiverNodeNumber
		|";

	#Region RequestTextCopyingMaterialsToArticles
	RequestTextCopyingMaterialsToArticles = "
		// Write-off of materials for production items of expenses.
		// The conditions for filling in the weight of the ARC indicators must correspond to the functions of the texcommunication of the additional spending nodes().
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Cost_.SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber  AS ReceiverNodeNumber,
		|		CAST((CASE
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionManag
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithVAT,
		|		CAST((CASE
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionManag
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|
		|		CAST((CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of sales 
		// , the item-by-item Local expenses are not taken into account in the cost of other expenses. 
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|			WHEN Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.TransferToOperation),
		|					VALUE(Enum.BusinessTransactions.CommissioningACAndTA),
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
		|				THEN 0
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionLocal
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightItemByItemLocalCosts,
		|
		|		CAST((CASE
		|			WHEN Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.CommissioningACAndTA),
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
		|				THEN 0
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionTax
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightItemByItemCostsTA,
		|
		|		CAST((CASE
		// When releasing products at the planned cost with write-off of deviations to the cost of goods sold 
		// , item-by-item expenses of the Man are not taken into account in the cost of other expenses. 
		|			WHEN Cost_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND TTAccountingPoliciesOfFinancialAccounting.ProductCostingByPlannedCost
		|			 AND TTAccountingPoliciesOfFinancialAccounting.WriteOffProductCostVariancesToCostOfGoodsSold
		|				THEN 0
		|			WHEN Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
		|				THEN 0
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionManag
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightItemByItemManCosts,
		|
		|		CAST((CASE
		|			WHEN Cost_.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.CommissioningACAndTA),
		|					VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
		|				THEN 0
		|			WHEN NOT ItemsOfExpensesWriteOffs.CostAllocationOptionLocal
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|				)
		|				AND NOT ItemsOfExpensesWriteOffs.CostAllocationOptionTax
		|			 IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts), 
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect), 
		|				VALUE(Enum.CostAllocationOptions.ToCostCenters),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)
		|				)
		|				THEN 0
		|			WHEN Cost_.OfficialTypeOfMovementParish THEN -Cost_.Count
		|			ELSE Cost_.Count END) AS NUMBER(31,10)) AS ArcWeightNDD,
		|
		|		(CASE
		|			WHEN ItemsOfExpensesWriteOffs.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|					OR ItemsOfExpensesWriteOffs.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedFixed,
		|		(CASE
		|			WHEN ItemsOfExpensesWriteOffs.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedVariable,
		|
		// The conditions for the formation of the Restore Reserves field must correspond to the conditions for the formation of a similar field
		// in the procedure for correcting the cost of writing reserves() #The area of the correction table.
		|		(CASE
		|			WHEN ItemsOfExpensesWriteOffs.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|				THEN TRUE
		|			WHEN Cost_.Organization IN (&CompaniesWithRestorationOfReservesWhenInventoryWriteOffForExpenses)
		|				THEN TRUE
		|			ELSE FALSE END) AS RestoreReserves,
		|
		|		ISNULL(ItemsOfExpensesWriteOffs.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		(CASE
		|			WHEN Cost_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
		|				THEN TRUE
		|			ELSE FALSE END)
		|			OR ItemsOfExpensesWriteOffs.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|				VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|				VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInBuhAccounting,
		|		ItemsOfExpensesWriteOffs.CostAllocationOptionTax IN (
		|			VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost),
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInNalAccounting,
		// For sources with the "Medium-slip" cost estimation method, connections between nodes are excluded when calculating the service, because
		// with medium-slip, the cost is calculated when carrying out documents.
		// In addition to the "Output" section of accounting, the actual cost is always calculated using it for any valuation method.
		|		(CASE
		|			WHEN TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|			 AND Cost_.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			 AND Cost_.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProductionCostsReverseTransaction)
		|				THEN TRUE
		|			ELSE FALSE END) AS SourceOnMediumSlip
		|	FROM
		|		TTCostOfGoodsWriteOff AS Cost_
		|
		|		INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
		|			ON Cost_.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
		|
		|		INNER JOIN TTAdjustmentNodesAreArticleByArticle AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ExpenseItem               = Cost_.ExpenseItemOfWriteOff
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses         = Cost_.DimensionOfExpenses
		|			AND AdjustmentNodesReceiver.LineOfBusiness   = Cost_.CorLineOfBusiness
		|			AND AdjustmentNodesReceiver.Department             = Cost_.Department
		|			AND AdjustmentNodesReceiver.Organization               = Cost_.CorCompany
		|			AND AdjustmentNodesReceiver.AccountingSection               = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ItemsOfExpensesWriteOffs
		|			ON ItemsOfExpensesWriteOffs.Ref = Cost_.ExpenseItemOfWriteOff
		|";
	#EndRegion

	#Region RequestTextDistributionToProductionBatches
	RequestTextDistributionToProductionBatches = "
	// Distribution of production costs for production batches
		|	SELECT
		|		Expenses.Recorder					AS Recorder,
		|		Expenses.SourceNodeNumber			AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		CAST(Expenses.IndicatorOfAllocationToLot AS NUMBER(31,10)) 		 AS ArcWeightItemByItemCostsWithVAT,
		|		CAST(Expenses.IndicatorOfAllocationToLotExcludingVAT AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|		CAST(Expenses.IndicatorOfAllocationToLotCompl AS NUMBER(31,10)) 	 AS ArcWeightItemByItemLocalCosts,
		|		CAST(Expenses.RateOfAssignmentToBatchIsTA AS NUMBER(31,10)) 	 AS ArcWeightItemByItemCostsTA,
		|		CAST(Expenses.IndicatorOfAllocationToLotManag AS NUMBER(31,10)) 	 AS ArcWeightItemByItemManCosts,
		|		CAST(Expenses.IndicatorOfAttributionToPartyNDD AS NUMBER(31,10)) 	 AS ArcWeightNDD,
		|		Expenses.ItemizedFixed,
		|		Expenses.ItemizedVariable,
		|		FALSE AS RestoreReserves,
		|		Expenses.AcceptedVNU,
		|		Expenses.NotDistributedInBuhAccounting,
		|		Expenses.NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		OtherExpensesOfUnfinishedProductionForLotReferencesOfProduction2 AS Expenses
		|
		|		INNER JOIN TTAdjustmentNodesAreArticleByArticleUnfinishedProduction AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.Organization                 = Expenses.Organization
		|			AND AdjustmentNodesReceiver.Department            = Expenses.Department
		|			AND AdjustmentNodesReceiver.ExpenseItem           = Expenses.ExpenseItem
		|			AND AdjustmentNodesReceiver.LineOfBusiness  = Expenses.LineOfBusiness
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses        = Expenses.DimensionOfExpenses
		|			AND AdjustmentNodesReceiver.ProductCostElement        = Expenses.ProductCostElement
		|			AND AdjustmentNodesReceiver.Stage                     = Expenses.Stage
		|			AND AdjustmentNodesReceiver.ProductsGroup          = Expenses.ProductsGroup
		|			AND AdjustmentNodesReceiver.RuleOfCostAllocatingToProductionLots = Expenses.RuleOfCostAllocatingToProductionLots
		|			AND AdjustmentNodesReceiver.Lot                   = Expenses.DocumentOfProductionIssue
		|			AND AdjustmentNodesReceiver.LotVendorAttributes     = Expenses.ReleaseLotDimension
		|			AND AdjustmentNodesReceiver.RowCodeProducts       = Expenses.RowCodeProducts
		|";
	#EndRegion

	#Region RequestTextDistributionForOutput
	RequestTextDistributionForOutput = "
	// Distribution of production costs for output
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Expenses.SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
		|		CAST(Expenses.IndicatorOfAllocationToIssue AS NUMBER(31,10))		 AS ArcWeightItemByItemCostsWithVAT,
		|		CAST(Expenses.IndicatorOfAttributionToOutputWithoutVAT AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|		CAST(Expenses.LocalIssueAttributionRate AS NUMBER(31,10))	 AS ArcWeightItemByItemLocalCosts,
		|		CAST(Expenses.IndicatorOfAttributionToIssueIsTA AS NUMBER(31,10)) 	 AS ArcWeightItemByItemCostsTA,
		|		CAST(Expenses.IndicatorOfAssignmentToIssueOfMan AS NUMBER(31,10))	 AS ArcWeightItemByItemManCosts,
		|		CAST(Expenses.IndicatorOfAttributionToIssueOfPersonalIncomeTax AS NUMBER(31,10)) 	 AS ArcWeightNDD,
		|		Expenses.ItemizedFixed AS ItemizedFixed,
		|		Expenses.ItemizedVariable AS ItemizedVariable,
		|		FALSE AS RestoreReserves,
		|		Expenses.AcceptedVNU AS AcceptedVNU,
		|		Expenses.NotDistributedInBuhAccounting AS NotDistributedInBuhAccounting,
		|		Expenses.NotDistributedInNalAccounting AS NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		OtherExpensesOfUnfinishedProductionForIssue3 AS Expenses
		|		LEFT JOIN TTAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.ItemsLocationAttributes = Expenses.ProductsAccountingDimension
		|			AND AdjustmentNodesReceiver.AccountingSection               = Expenses.AccountingSection
		|			AND AdjustmentNodesReceiver.Organization               = Expenses.Organization
		|			AND AdjustmentNodesReceiver.InventoryOwnerAttribute                = Expenses.ReleasesInventoryOwnerAttributes
		|			AND AdjustmentNodesReceiver.Lot                    = Expenses.IssuesLotReference
		|			AND AdjustmentNodesReceiver.LotVendorAttributes      = Expenses.ReleasesLotVendorAttributes
		|			AND AdjustmentNodesReceiver.FinancialAccountingDimension = Expenses.IssuesOfControllingAttributeOfFinancialAccounting
		|			AND AdjustmentNodesReceiver.VATActivityType        = Expenses.ReleasesVATActivityType
		|";
	#EndRegion

	#Region QueryTextConnectionsOfNodesOfProductionExpensesOfPreviousPeriods
	QueryTextConnectionsOfNodesOfProductionExpensesOfPreviousPeriods = "
		|// Distribution of additional the cost of discarded materials for production costs
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Links.SourceNodeNumber					AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber 	AS ReceiverNodeNumber,
		|		CAST(Links.ArcWeightWithVAT AS NUMBER(31,10))   AS ArcWeightItemByItemCostsWithVAT,
		|		CAST(Links.ArcWeightWithoutVAT AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|		CAST(Links.ArcWeightLocal AS NUMBER(31,10))   AS ArcWeightItemByItemLocalCosts,
		|		CAST(Links.WeightOfArcISTA AS NUMBER(31,10))     AS ArcWeightItemByItemCostsTA,
		|		CAST(Links.ArcWeightMan AS NUMBER(31,10))	   AS ArcWeightItemByItemManCosts,
		|		CAST(Links.ArcWeightNDD AS NUMBER(31,10))	   AS ArcWeightNDD,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedFixed,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedVariable,
		|		FALSE                                              AS RestoreReserves,
		|		ISNULL(ARTICLES__.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		ISNULL(ARTICLES__.CostAllocationOptionLocal, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInBuhAccounting,
		|		ISNULL(ARTICLES__.CostAllocationOptionTax, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		ConnectionsOfNodesOfProductionExpensesOfPreviousPeriods AS Links
		|
		|		INNER JOIN TTAdjustmentNodesAreArticleByArticle AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.Organization                  = Links.Organization
		|			AND AdjustmentNodesReceiver.Department             = Links.Department
		|			AND AdjustmentNodesReceiver.LineOfBusiness   = Links.LineOfBusiness
		|			AND AdjustmentNodesReceiver.ExpenseItem            = Links.ExpenseItem
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses         = Links.DimensionOfExpenses
		|			AND AdjustmentNodesReceiver.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = Links.ExpenseItem
		|WHERE
		|	&MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion

	#Region QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToItemsOfAdditionalExpenses
	QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToItemsOfAdditionalExpenses = "
		|// distribution of production costs to other items of expenditure (additional expenses for items).
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Links.SourceNodeNumber					AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber 	AS ReceiverNodeNumber,
		|		CAST(Links.ArcWeightWithVAT AS NUMBER(31,10))   AS ArcWeightItemByItemCostsWithVAT,
		|		CAST(Links.ArcWeightWithoutVAT AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|		CAST(Links.ArcWeightLocal AS NUMBER(31,10))   AS ArcWeightItemByItemLocalCosts,
		|		CAST(Links.WeightOfArcISTA AS NUMBER(31,10))     AS ArcWeightItemByItemCostsTA,
		|		CAST(Links.ArcWeightMan AS NUMBER(31,10))    AS ArcWeightItemByItemManCosts,
		|		CAST(Links.ArcWeightNDD AS NUMBER(31,10))	   AS ArcWeightNDD,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedFixed,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN TRUE
		|			ELSE FALSE END)                                             AS ItemizedVariable,
		|		FALSE                                                              AS RestoreReserves,
		|		ISNULL(ARTICLES__.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		ISNULL(ARTICLES__.CostAllocationOptionLocal, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInBuhAccounting,
		|		ISNULL(ARTICLES__.CostAllocationOptionTax, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) IN (
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses),
		|			VALUE(Enum.CostAllocationOptions.DoNotAllocate),
		|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
		|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness)) AS NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		ConnectionsOfProductionCostsSubAssetsWriteOffToOtherItemsOfExpenditure AS Links
		|
		|		INNER JOIN AdditionalCostAdjustmentNodes AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.Organization                  = Links.Organization
		|			AND AdjustmentNodesReceiver.Department             = Links.Department
		|			AND AdjustmentNodesReceiver.LineOfBusiness   = Links.LineOfBusiness
		|			AND AdjustmentNodesReceiver.ExpenseItem            = Links.ExpenseItem
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses         = Links.DimensionOfExpenses
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = Links.ExpenseItem
		|WHERE
		|	&MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion

	#Region QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToOtherItemByItemItemsOfExpenses
	QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToOtherItemByItemItemsOfExpenses = "
		|// Distribution of production costs to other items of expenditure (article-by-article).
		|	SELECT
		|		UNDEFINED AS Recorder,
		|		Links.SourceNodeNumber					AS SourceNodeNumber,
		|		AdjustmentNodesReceiver.NodeNumber 	AS ReceiverNodeNumber,
		|		CAST(Links.ArcWeightWithVAT AS NUMBER(31,10))   AS ArcWeightItemByItemCostsWithVAT,
		|		CAST(Links.ArcWeightWithoutVAT AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|		CAST(Links.ArcWeightLocal AS NUMBER(31,10))   AS ArcWeightItemByItemLocalCosts,
		|		CAST(Links.WeightOfArcISTA AS NUMBER(31,10))     AS ArcWeightItemByItemCostsTA,
		|		CAST(Links.ArcWeightMan AS NUMBER(31,10))    AS ArcWeightItemByItemManCosts,
		|		CAST(Links.ArcWeightNDD AS NUMBER(31,10))	   AS ArcWeightNDD,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN TRUE
		|			ELSE FALSE END) AS ItemizedFixed,
		|		(CASE
		|			WHEN ARTICLES__.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN TRUE
		|			ELSE FALSE END)                                             AS ItemizedVariable,
		|		FALSE                                                              AS RestoreReserves,
		|		ISNULL(ARTICLES__.EnteredInTaxAccounting, TRUE) AS AcceptedVNU,
		|		ISNULL(ARTICLES__.CostAllocationOptionLocal, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) =
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS NotDistributedInBuhAccounting,
		|		ISNULL(ARTICLES__.CostAllocationOptionTax, 
		|			VALUE(Enum.CostAllocationOptions.EmptyRef)) =
		|			VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS NotDistributedInNalAccounting,
		|		FALSE AS SourceOnMediumSlip
		|	FROM
		|		ConnectionsOfProductionCostsSubAssetsWriteOffToOtherItemsOfExpenditure AS Links
		|
		|		INNER JOIN TTAdjustmentNodesAreArticleByArticle AS AdjustmentNodesReceiver
		|		ON AdjustmentNodesReceiver.Organization                  = Links.Organization
		|			AND AdjustmentNodesReceiver.Department             = Links.Department
		|			AND AdjustmentNodesReceiver.LineOfBusiness   = Links.LineOfBusiness
		|			AND AdjustmentNodesReceiver.ExpenseItem            = Links.ExpenseItem
		|			AND AdjustmentNodesReceiver.DimensionOfExpenses         = Links.DimensionOfExpenses
		|
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON ARTICLES__.Ref = Links.ExpenseItem
		|WHERE
		|	&MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
		|";
	#EndRegion

	#Region RequestTextTransitBetweenHIA
	RequestTextTransitBetweenHIA = "
	// Transits between HIA
	|	SELECT
	|		UNDEFINED AS Recorder,
	|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
	|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.Weight <> 0
	|				THEN Expenses.LedWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightItemByItemCostsWithVAT,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.Weight <> 0
	|				THEN Expenses.LedWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightItemByItemCostsWithoutVAT,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.LocalWeight <> 0
	|				THEN Expenses.LocalWeightGiven
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightItemByItemLocalCosts,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.LocalWeight <> 0
	|				THEN Expenses.LocalWeightGiven
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightItemByItemCostsTA,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.Weight <> 0
	|				THEN Expenses.LedWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightItemByItemManCosts,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND TransitHubs.LocalWeight <> 0
	|				THEN Expenses.GivenWeightOfNDT
	|			ELSE 0 
	|		END AS NUMBER(31,10))				AS ArcWeightNDD,
	|		(CASE
	|			WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
	|					OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE END) AS ItemizedFixed,
	|		(CASE
	|			WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
	|				THEN TRUE
	|			ELSE FALSE END)                                             AS ItemizedVariable,
	|		FALSE                                                              AS RestoreReserves,
	|		AssetRef.EnteredInTaxAccounting AS AcceptedVNU,
	|		FALSE                                                              AS NotDistributedInBuhAccounting,
	|		ISNULL(TTOvz.CostAllocationOptionTax, AssetRef.CostAllocationOptionTax) IN (
	|				VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|				VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly),
	|				VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|		) AS NotDistributedInNalAccounting,
	|		FALSE AS SourceOnMediumSlip
	|	FROM
	|		TTTransitOfExpensesBetweenHIA AS Expenses
	|
	|		INNER JOIN
	|			TTInitialDataOfTransitNodesOfExpendituresBetweenHIA AS TransitHubs
	|		ON
	|			TransitHubs.ExpenseItem = Expenses.ExpenseItem
	|			AND TransitHubs.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|			AND TransitHubs.Organization = Expenses.Organization
	|			AND TransitHubs.Department = Expenses.Department
	|			AND TransitHubs.LineOfBusiness = Expenses.LineOfBusiness
	|
	|		INNER JOIN
	|			TTAdjustmentNodesAreArticleByArticle AS SourceAdjustmentNodes
	|		ON
	|			SourceAdjustmentNodes.ExpenseItem = Expenses.ExpenseItem
	|			AND SourceAdjustmentNodes.DimensionOfExpenses = Expenses.DimensionOfExpenses
	|			AND SourceAdjustmentNodes.Organization = Expenses.Organization
	|			AND SourceAdjustmentNodes.Department = Expenses.Department
	|			AND SourceAdjustmentNodes.LineOfBusiness = Expenses.LineOfBusiness
	|			AND SourceAdjustmentNodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|		INNER JOIN TTAdjustmentNodesAreArticleByArticle AS AdjustmentNodesReceiver
	|		ON
	|			AdjustmentNodesReceiver.ExpenseItem = Expenses.ExpenseItem
	|			AND AdjustmentNodesReceiver.DimensionOfExpenses = Expenses.CorExpenditureDimension
	|			AND AdjustmentNodesReceiver.Organization = Expenses.Organization
	|			AND AdjustmentNodesReceiver.Department = Expenses.DebitBusinessUnit
	|			AND AdjustmentNodesReceiver.LineOfBusiness = Expenses.LineOfBusiness
	|			AND AdjustmentNodesReceiver.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|		INNER JOIN
	|			ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON
	|			Expenses.ExpenseItem = AssetRef.Ref
	|
	|		INNER JOIN
	|			TTOvz AS TTOvz
	|		ON
	|			Expenses.CorExpenditureDimension = TTOvz.ConstCenter
	|
	|		INNER JOIN
	|			TTShareOfDistributionOfOtherCosts AS DD
	|		ON
	|			Expenses.DocumentRegisterRecords = DD.Ref
	|	WHERE
	|		&MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|";
	#EndRegion
	
	#Region RequestTextWriteOffForItemsInTransitFromHIA
	RequestTextWriteOffForItemsInTransitFromHIA = "
	// Write-off for articles in transit from the HIA
	|	SELECT
	|		DD.Ref AS Recorder,
	|		SourceAdjustmentNodes.NodeNumber AS SourceNodeNumber,
	|		AdjustmentNodesReceiver.NodeNumber AS ReceiverNodeNumber,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.Weight <> 0
	|				THEN WriteOffItems.CostShare * Table.Weight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightItemByItemCostsWithVAT,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.Weight <> 0
	|				THEN WriteOffItems.CostShare * Table.Weight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightItemByItemCostsWithoutVAT,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.LocalWeight <> 0
	|				THEN WriteOffItems.CostShare * Table.LocalWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightItemByItemLocalCosts,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.LocalWeight <> 0
	|				THEN WriteOffItems.CostShare * Table.LocalWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightItemByItemCostsTA,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.Weight <> 0
	|				THEN WriteOffItems.CostShare * Table.Weight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightItemByItemManCosts,
	|		CAST(CASE 
	|			WHEN DD.AllocateToCostCenter AND Table.LocalWeight <> 0
	|				THEN WriteOffItems.CostShare * Table.LocalWeight
	|			ELSE 0 
	|		END AS NUMBER(31,10))						AS ArcWeightNDD,
	|		(CASE
	|			WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
	|					OR AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE END) AS ItemizedFixed,
	|		(CASE
	|			WHEN AssetRef.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
	|				THEN TRUE
	|			ELSE FALSE END) AS ItemizedVariable,
	|		FALSE                            AS RestoreReserves,
	|		AssetRef.EnteredInTaxAccounting AS AcceptedVNU,
	|		FALSE                            AS NotDistributedInBuhAccounting,
	|		AssetRef.CostAllocationOptionTax IN (
	|			VALUE(Enum.CostAllocationOptions.ToLinesOfBusiness),
	|			VALUE(Enum.CostAllocationOptions.ToCurrentPeriodExpensesDirectly)) AS NotDistributedInNalAccounting,
	|		FALSE AS SourceOnMediumSlip
	|	FROM
	|		Document.AllocationOfOtherCosts.WriteOff AS WriteOffItems
	|	INNER JOIN
	|		TTShareOfDistributionOfOtherCosts AS DD
	|	ON
	|		DD.Ref = WriteOffItems.Ref
	|	INNER JOIN
	|		TTInitialDataOfTransitNodesOfExpendituresBetweenHIA AS Table
	|	ON
	|		Table.Organization = DD.Organization
	|		AND Table.Department = DD.Department
	|		AND Table.DimensionOfExpenses = DD.DimensionOfExpenses
	|	INNER JOIN
	|			TTAdjustmentNodesAreArticleByArticle AS SourceAdjustmentNodes
	|		ON
	|			SourceAdjustmentNodes.Organization = Table.Organization
	|			AND SourceAdjustmentNodes.Department = Table.Department
	|			AND SourceAdjustmentNodes.LineOfBusiness = Table.LineOfBusiness
	|			AND SourceAdjustmentNodes.ExpenseItem = Table.ExpenseItem
	|			AND SourceAdjustmentNodes.DimensionOfExpenses = Table.DimensionOfExpenses
	|			AND SourceAdjustmentNodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|	INNER JOIN TTAdjustmentNodesAreArticleByArticle AS AdjustmentNodesReceiver
	|	ON
	|		AdjustmentNodesReceiver.Organization = DD.Organization
	|		AND AdjustmentNodesReceiver.Department = WriteOffItems.Department
	|		AND AdjustmentNodesReceiver.LineOfBusiness = WriteOffItems.LineOfBusiness
	|		AND AdjustmentNodesReceiver.ExpenseItem = WriteOffItems.ExpenseItem
	|		AND AdjustmentNodesReceiver.DimensionOfExpenses = WriteOffItems.DimensionOfExpenses
	|		AND AdjustmentNodesReceiver.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|	ON
	|		SourceAdjustmentNodes.ExpenseItem = AssetRef.Ref
	|
	|	WHERE DD.AssignAllocationSetting = VALUE(Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter)
	|		AND DD.AllocateToExpenseItems 
	|		AND &MonthEndClosingMode <> VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|";
	#EndRegion

	TextOfCompositionRequests = New Array;
	TextOfCompositionRequests.Add(RequestTextDistributionForOutput);
	TextOfCompositionRequests.Add(RequestTextDistributionToProductionBatches);
	TextOfCompositionRequests.Add(QueryTextConnectionsOfNodesOfProductionExpensesOfPreviousPeriods);
	TextOfCompositionRequests.Add(QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToItemsOfAdditionalExpenses);
	TextOfCompositionRequests.Add(QueryTextOfCommunicationOfNodesOfProductionCostsWriteOffToOtherItemByItemItemsOfExpenses);
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		
		RequestTextCopyingMaterialsToArticles = StrReplace(
			RequestTextCopyingMaterialsToArticles, 
			"ItemsOfExpensesWriteOffs.CostAllocationOptionManag", 
			"ISNULL(TTOvz.CostAllocationOptionManag, 
			|	ItemsOfExpensesWriteOffs.CostAllocationOptionManag)");
		RequestTextCopyingMaterialsToArticles = StrReplace(
			RequestTextCopyingMaterialsToArticles, 
			"ItemsOfExpensesWriteOffs.CostAllocationOptionLocal", 
			"ISNULL(TTOvz.CostAllocationOptionLocal, 
			|	ItemsOfExpensesWriteOffs.CostAllocationOptionLocal)");
		RequestTextCopyingMaterialsToArticles = StrReplace(
			RequestTextCopyingMaterialsToArticles, 
			"ItemsOfExpensesWriteOffs.CostAllocationOptionTax", 
			"ISNULL(TTOvz.CostAllocationOptionTax, 
			|	ItemsOfExpensesWriteOffs.CostAllocationOptionTax)");

		RequestTextCopyingMaterialsToArticles = RequestTextCopyingMaterialsToArticles + "
		|	LEFT JOIN
		|		TTOvz AS TTOvz
		|	ON
		|		Cost_.DimensionOfExpenses = TTOvz.ConstCenter
		|";
		
		TextOfCompositionRequests.Add(RequestTextTransitBetweenHIA);
		TextOfCompositionRequests.Add(RequestTextWriteOffForItemsInTransitFromHIA);
	EndIf;

	TextOfCompositionRequests.Add(RequestTextCopyingMaterialsToArticles);
	
	QueryText =	StrReplace(MainQuery, "&CompositionOfLinks", "("+ 
		StrConcat(TextOfCompositionRequests, TMCommonUse.QuerySeparatorInJoin())+")");	
	
	Return QueryText;

EndFunction

Function TextTTTableOfRelationsItemByItemExpenses()
	Return "
		|SELECT
		|	Links.SourceNodeNumber                      AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber                      AS ReceiverNodeNumber,
		|	CAST(SUM(Links.ArcWeightItemByItemCostsWithVAT) AS NUMBER(31,10))   AS ArcWeightItemByItemCostsWithVAT,
		|	CAST(SUM(Links.ArcWeightItemByItemCostsWithoutVAT) AS NUMBER(31,10)) AS ArcWeightItemByItemCostsWithoutVAT,
		|	CAST(SUM(Links.ArcWeightItemByItemLocalCosts) AS NUMBER(31,10))   AS ArcWeightItemByItemLocalCosts,
		|	CAST(SUM(Links.ArcWeightItemByItemCostsTA) AS NUMBER(31,10))     AS ArcWeightItemByItemCostsTA,
		|	CAST(SUM(Links.ArcWeightItemByItemManCosts) AS NUMBER(31,10))    AS ArcWeightItemByItemManCosts,
		|	CAST(SUM(Links.ArcWeightNDD) AS NUMBER(31,10))						AS ArcWeightNDD,
		|	MAX(Links.ItemizedFixed)        AS ItemizedFixed,
		|	MAX(Links.ItemizedVariable)        AS ItemizedVariable,
		|	MAX(Links.RestoreReserves)       AS RestoreReserves,
		|	MAX(Links.AcceptedVNU)               AS AcceptedVNU,
		|	MAX(Links.NotDistributedInBuhAccounting)    AS NotDistributedInBuhAccounting,
		|	MAX(Links.NotDistributedInNalAccounting)	 AS NotDistributedInNalAccounting,
		|	MAX(Links.SourceOnMediumSlip)	 AS SourceOnMediumSlip
		|
		|INTO TtTableOfLinksItemByItemExpenses
		|FROM
		|	TTTableOfLinksItemByItemExpensesWithRecorders AS Links
		|GROUP BY
		|	Links.SourceNodeNumber,
		|	Links.ReceiverNodeNumber
		|INDEX BY SETS
		|(
		|	(SourceNodeNumber,	ReceiverNodeNumber),
		|	(ReceiverNodeNumber, SourceNodeNumber)
		|)
		|";
EndFunction

Function TextInitialCostItemByItemExpenses()
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		// Item-by-item expenses of the enterprise with VAT
		|	CAST(SUM(CASE
		// With the cost estimation method, the "Medium-sliding" amount of expenses is already reflected in the "Other expenses" register and the initial cost
		// does not need to be calculated, except for the production of products with write-off for expenses.
		// The output of products with write-off to expenses is reflected in the accounting section "Output".
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		WHEN ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.Cost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AdditionalExpenseCost, 0)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemCostsWithVAT, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedFixedCostsIncludingVAT,
		|
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		WHEN ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.Cost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AdditionalExpenseCost, 0)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemCostsWithVAT, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedVariableCostsIncludingVAT,
		// Item-by-item expenses of the enterprise without VAT
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		WHEN ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.CostExcludingVAT, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AdditionalExpensesCostExcludingVAT, 0)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemCostsWithoutVAT, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedFixedCostsExcludingVAT,
		|
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|			THEN 0
		|		WHEN ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.CostExcludingVAT, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCosts, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AdditionalExpensesCostExcludingVAT, 0)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemCostsWithoutVAT, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedVariableCostsExcludingVAT,
		|
		// Article-by-article expenses of companies (regulated accounting)
		//
		// With the cost estimation method, the "Average Sliding" amount of expenses is already reflected in the "Other expenses" register.
		// The initial cost should include the amount of the allowance for impairment, because the amount of the reserve is calculated at the close of the month 
		// Except for the production of products with write-off for expenses. At the time of production, the amount of the reserve for impairment of inventories is written off to the cost of goods sold.
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|		 	 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|			ELSE 0 END)
		|		WHEN ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.LocalCost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsLocal, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AddExpensesLocal, 0)
		|				+ (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|					ELSE 0 END)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemLocalCosts, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
		|
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|		 	 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|			ELSE 0 END)
		|		WHEN ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.LocalCost, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsLocal, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AddExpensesLocal, 0)
		|				+ (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentLocal, 0)
		|					ELSE 0 END)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemLocalCosts, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
		|
		// Item-by-item expenses of organizations (management accounting)
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|		 	 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|			ELSE 0 END)
		|		WHEN ISNULL(WriteOffMovements.ItemizedFixed, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.CostMan, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsMan, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AddExpensesMan, 0)
		|				+ (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|					ELSE 0 END)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemManCosts, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
		|
		|	CAST(SUM(CASE
		|		WHEN WriteOffMovements.SourceOnMediumSlip
		|		 AND ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|		 	 AND ISNULL(CostOfBatchesOfGoods.AccountingSection, UNDEFINED) <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
		|				THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|			ELSE 0 END)
		|		WHEN ISNULL(WriteOffMovements.ItemizedVariable, FALSE)
		|			THEN (ISNULL(CostOfBatchesOfGoods.CostMan, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.LaborCostsMan, 0)
		|				+ ISNULL(CostOfBatchesOfGoods.AddExpensesMan, 0)
		|				+ (CASE WHEN NOT WriteOffMovements.RestoreReserves
		|					THEN ISNULL(CostOfBatchesOfGoods.ProvisionForImpairmentMan, 0)
		|					ELSE 0 END)
		|				) * ISNULL(WriteOffMovements.ArcWeightItemByItemManCosts, 0)
		|		ELSE 0 END) AS NUMBER(28,10)) AS ItemizedVariableCostsManag
		|
		|INTO InitialCostItemByItemCosts
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|	LEFT JOIN TtTableOfLinksItemByItemExpenses AS WriteOffMovements
		|		ON AdjustmentNodes.NodeNumber = WriteOffMovements.ReceiverNodeNumber
		|
		|	LEFT JOIN TTValueOfBatchesOfGoods AS CostOfBatchesOfGoods
		|		ON CostOfBatchesOfGoods.NodeNumber = WriteOffMovements.SourceNodeNumber
		|
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber
		|
		|INDEX BY
		|	NodeNumber
		|";
EndFunction

Function TextVATCost()
	Return " 
		|SELECT
		|	Cost_.Organization,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.AccountingSection,
		|	Cost_.InventoryOwnerAttribute,
		|	Cost_.Lot,
		|	Cost_.LotVendorAttributes,
		|	Cost_.FinancialAccountingDimension,
		|	Cost_.VATActivityType,
		|	SUM(Cost_.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(Cost_.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(Cost_.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(Cost_.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag
		|INTO ValueOfVAT
		|FROM
		|	TTCashEstimatedTurnoverCostOfGoods AS Cost_
		|WHERE
		|	Cost_.EntryType = VALUE(Enum.LotRecordTypes.InclusionExclusionOfVATInCost)
		|	AND Cost_.LotCalculation
		|
		|GROUP BY
		|	Cost_.Organization,
		|	Cost_.ItemsLocationAttributes,
		|	Cost_.AccountingSection,
		|	Cost_.InventoryOwnerAttribute,
		|	Cost_.Lot,
		|	Cost_.LotVendorAttributes,
		|	Cost_.FinancialAccountingDimension,
		|	Cost_.VATActivityType
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|";
EndFunction

Function TextSLENodes_ItemByItemExpensesOfEnterprise()
	Return "	
		|SELECT
		|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
		// Item-by-item expenses of the enterprise with VAT
		|	AdjustmentNodes.ItemizedFixedCostsIncludingVAT   AS ItemizedFixedCostsIncludingVAT,
		|	AdjustmentNodes.ItemizedVariableCostsIncludingVAT   AS ItemizedVariableCostsIncludingVAT,
		// Item-by-item expenses of the enterprise without VAT
		|	AdjustmentNodes.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	AdjustmentNodes.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT
		|
		|INTO SLENodes_ItemByItemExpensesOfEnterprise
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber                                       AS NodeNumber,
		// Item-by-item expenses of the enterprise with VAT
		|	AdjustmentNodes.ItemizedFixedCostsIncludingVAT
		|		+ ISNULL(InitialCost_0.ItemizedFixedCostsIncludingVAT, 0)   AS ItemizedFixedCostsIncludingVAT,
		|	AdjustmentNodes.ItemizedVariableCostsIncludingVAT
		|		+ ISNULL(InitialCost_0.ItemizedVariableCostsIncludingVAT, 0)   AS ItemizedVariableCostsIncludingVAT,
		// Item-by-item expenses of the enterprise without VAT
		|	AdjustmentNodes.ItemizedFixedCostsExcludingVAT
		|		+ ISNULL(InitialCost_0.ItemizedFixedCostsExcludingVAT, 0) AS ItemizedFixedCostsExcludingVAT,
		|	AdjustmentNodes.ItemizedVariableCostsExcludingVAT
		|		+ ISNULL(InitialCost_0.ItemizedVariableCostsExcludingVAT, 0) AS ItemizedVariableCostsExcludingVAT
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|	LEFT JOIN InitialCostItemByItemCosts AS InitialCost_0
		|	ON InitialCost_0.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|";
EndFunction

Function TextSLENodes_ItemByItemExpensesOfOrganizations()
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
		// Filling in the fields must correspond to the function of the text_reservation_reserved expenses().
		// Item-by-item expenses of organizations (regulated accounting)
		|	AdjustmentNodes.ItemizedFixedCostsCompl
		|		+ ISNULL(ValueOfVAT.ItemizedFixedCostsCompl, 0) AS ItemizedFixedCostsCompl,
		|	AdjustmentNodes.ItemizedVariableCostsCompl
		|		+ ISNULL(ValueOfVAT.ItemizedVariableCostsCompl, 0) AS ItemizedVariableCostsCompl,
		// Item-by-item expenses of organizations (management accounting)
		|	AdjustmentNodes.ItemizedFixedCostsManag
		|		+ ISNULL(ValueOfVAT.ItemizedFixedCostsManag, 0) AS ItemizedFixedCostsManag,
		|	AdjustmentNodes.ItemizedVariableCostsManag
		|		+ ISNULL(ValueOfVAT.ItemizedVariableCostsManag, 0) AS ItemizedVariableCostsManag
		|
		|INTO SLENodes_ItemByItemExpensesOfOrganizations
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|	LEFT JOIN ValueOfVAT AS ValueOfVAT
		|	ON ValueOfVAT.Organization                   = AdjustmentNodes.Organization
		|		AND ValueOfVAT.ItemsLocationAttributes = AdjustmentNodes.ItemsLocationAttributes
		|		AND ValueOfVAT.AccountingSection                = AdjustmentNodes.AccountingSection
		|		AND ValueOfVAT.InventoryOwnerAttribute                 = AdjustmentNodes.InventoryOwnerAttribute
		|		AND ValueOfVAT.Lot                     = AdjustmentNodes.Lot
		|		AND ValueOfVAT.LotVendorAttributes       = AdjustmentNodes.LotVendorAttributes
		|		AND ValueOfVAT.FinancialAccountingDimension  = AdjustmentNodes.FinancialAccountingDimension
		|		AND ValueOfVAT.VATActivityType         = AdjustmentNodes.VATActivityType
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber                                     AS NodeNumber,
		// Item-by-item expenses of organizations (regulated accounting)
		|	AdjustmentNodes.ItemizedFixedCostsCompl
		|		+ ISNULL(InitialCost_0.ItemizedFixedCostsCompl, 0) AS ItemizedFixedCostsCompl,
		|	AdjustmentNodes.ItemizedVariableCostsCompl 
		|		+ ISNULL(InitialCost_0.ItemizedVariableCostsCompl, 0) AS ItemizedVariableCostsCompl,
		// Item-by-item expenses of organizations (management accounting)
		|	AdjustmentNodes.ItemizedFixedCostsManag
		|		+ ISNULL(InitialCost_0.ItemizedFixedCostsManag, 0)  AS ItemizedFixedCostsManag,
		|	AdjustmentNodes.ItemizedVariableCostsManag
		|		+ ISNULL(InitialCost_0.ItemizedVariableCostsManag, 0)  AS ItemizedVariableCostsManag
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|	LEFT JOIN InitialCostItemByItemCosts AS InitialCost_0
		|	ON InitialCost_0.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|UNION ALL
		|
		// Nodes must comply with the procedure to solve the platform_reservation_references() #Area nodes_reservation account
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|";
EndFunction
	
Function TextSLEJoin_ItemByItemExpensesOfEnterprise()
	Return "
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightWithoutVAT
		|
		|INTO SLEConnections_ItemByItemExpensesOfEnterprise
		|FROM
		|	TTWriteOffs AS WriteOffMovements
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceOnMediumSlip
		|
		|UNION ALL
		|
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	CAST(ISNULL(-WriteOffMovements.ArcWeightItemByItemCostsWithVAT, 0) AS NUMBER(28,10))   AS ArcWeightWithVAT,
		|	CAST(ISNULL(-WriteOffMovements.ArcWeightItemByItemCostsWithoutVAT, 0) AS NUMBER(28,10)) AS ArcWeightWithoutVAT
		|FROM
		|	TtTableOfLinksItemByItemExpenses AS WriteOffMovements
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceOnMediumSlip
		|
		|UNION ALL
		|
		|SELECT
		|	Links.SourceNodeNumber AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(-Links.ArcWeightWithVAT AS NUMBER(28,10))   AS ArcWeightWithVAT,
		|	CAST(-Links.ArcWeightWithoutVAT AS NUMBER(28,10)) AS ArcWeightWithoutVAT
		|FROM
		|	ConnectionsOfNodesOfAdditionalExpenses AS Links
		|WHERE
		|	NOT Links.SourceOnMediumSlip
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		// The expression below should match in the trace. places: The text of the link_state_units of organizations to solve using the platform_The cost of the enterprise
		|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightWithVAT,
		|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightWithoutVAT
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|	CAST(AdjustmentNodes.WeightArticleByArticle AS NUMBER(28,10))       AS ArcWeightWithVAT,
		|	CAST(AdjustmentNodes.WeightArticleByArticleWithoutVAT AS NUMBER(28,10)) AS ArcWeightWithoutVAT
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|	CAST(AdjustmentNodes.WeightWithVAT AS NUMBER(28,10))       AS ArcWeightWithVAT,
		|	CAST(AdjustmentNodes.WeightWithoutVAT AS NUMBER(28,10))     AS ArcWeightWithoutVAT
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|";
EndFunction

Function TextSLEJoin_ItemByItemExpensesOfOrganizations()
	Return "
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE) THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS WeightOfArcISTA,
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.DoNotMoveBookValue, FALSE)
		|		 OR WriteOffMovements.DoNotMoveNetInitialCostLOCAL
		|			THEN 0
		|		ELSE ISNULL(-WriteOffMovements.ArcWeight, 0)
		|	END AS NUMBER(28,10)) AS ArcWeightMan
		|
		|INTO SLEConnections_ItemByItemExpensesOfOrganizations
		|FROM
		|	TTWriteOffs AS WriteOffMovements
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|	AND NOT WriteOffMovements.TransferToAnotherOrganization
		|
		|UNION ALL
		|	
		|SELECT
		|	WriteOffMovements.SourceNodeNumber AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber AS ReceiverNodeNumber,
		|	CAST(CASE
		// Expenses are not distributed in the boom. accounting - The Net Initial Cost, Local should remain at the source, 
		// except for the item being written Off to The Item-By-Item Sub-Asset of The Item-by-Item expenses (corresponds to the arrival in the "Other Expenses" register).
		|		WHEN ISNULL(WriteOffMovements.NotDistributedInBuhAccounting, FALSE) AND AdjustmentNodes.NodeNumber IS NULL
		|			THEN 0 
		|		ELSE ISNULL(-WriteOffMovements.ArcWeightItemByItemLocalCosts, 0) END AS NUMBER(28,10)) AS ArcWeightLocal,
		// Expenses are not distributed in cash. accounting - the cost TA must remain at the source, 
		// except for the item being written off to the item-by-item expenses node (corresponds to the arrival in the "Other expenses" register).
		// The conditions for generating the value of the Vesdugin field must match the request of the Text Table().
		|	CAST(CASE
		|		WHEN ISNULL(WriteOffMovements.NotDistributedInNalAccounting, FALSE) AND AdjustmentNodes.NodeNumber IS NULL
		|			THEN 0 
		|		ELSE ISNULL(-WriteOffMovements.ArcWeightItemByItemCostsTA, 0) END AS NUMBER(28,10)) AS WeightOfArcISTA,
		|	CAST(ISNULL(-WriteOffMovements.ArcWeightItemByItemManCosts, 0) AS NUMBER(28,10))    AS ArcWeightMan
		|FROM
		|	TtTableOfLinksItemByItemExpenses AS WriteOffMovements
		|	LEFT JOIN TTAdjustmentNodes AS AdjustmentNodes
		|		ON AdjustmentNodes.NodeNumber = WriteOffMovements.SourceNodeNumber
		|WHERE
		|	NOT WriteOffMovements.ReceiverNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceNodeNumber IS NULL
		|	AND NOT WriteOffMovements.SourceOnMediumSlip
		|
		|UNION ALL
		|
		|SELECT
		|	Links.SourceNodeNumber AS SourceNodeNumber,
		|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
		|
		|	CAST(-Links.ArcWeightLocal AS NUMBER(28,10))   AS ArcWeightLocal,
		|	CAST(-Links.WeightOfArcISTA AS NUMBER(28,10))     AS WeightOfArcISTA,
		|	CAST(-Links.ArcWeightMan AS NUMBER(28,10))    AS ArcWeightMan
		|FROM
		|	ConnectionsOfNodesOfAdditionalExpenses AS Links
		|WHERE
		|	NOT Links.SourceOnMediumSlip
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		// The expression below should match in the trace. places: The text of the link_state_the output of the enterprise, solve the Platform_The cost of the enterprise
		|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightLocal,
		|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS WeightOfArcISTA,
		|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightMan
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|	CAST(AdjustmentNodes.WeightArticleByArticleLocal AS NUMBER(28,10))   AS ArcWeightLocal,
		|	CAST(AdjustmentNodes.WeightItemByItemTA AS NUMBER(28,10))     AS WeightOfArcISTA,
		|	CAST(AdjustmentNodes.WeightArticleByArticleMan AS NUMBER(28,10))    AS ArcWeightMan
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|UNION ALL
		|
		|SELECT
		|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
		|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
		|	CAST(AdjustmentNodes.LocalWeight AS NUMBER(28,10))  AS ArcWeightLocal,
		|	CAST(AdjustmentNodes.WeightTA AS NUMBER(28,10))    AS WeightOfArcISTA,
		|	CAST(AdjustmentNodes.ManSWeight AS NUMBER(28,10))   AS ArcWeightMan
		|FROM
		|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses

#Region Description_PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses

// At the stage of preparing the data for the resolution of the current expenses, the initial data is generated for calculating 
// the service, taking into account the reserves of upcoming expenses.
// 
// Temporary table of reserve expenditures
//	The initial data on the reserves of upcoming expenses are in the temporary table of expenditure reserves. 
//	This temporary table is formed in the function Textnotecompleteproduction() according To The Balance Of The Accumulation REGISTER Of RESERVES Of CURRENT EXPENDITURES.
//	This is the function that is called in the procedure to prepare the data for the resolution of the status of the outputs().
//
// The temporary table is coverablereservation of the outputs
//	The data of the reserves of upcoming expenses are matched with the data of expenses covered by the reserves.
//	The result of the comparison is recorded in a temporary table of coveredreferencesextensions.
//	For comparison, an auxiliary temporary table is used to cover the amount of expenses covered, a preliminary one,
//	in which various analysts of the reserves of upcoming expenses are indicated. It is formed according to the data of the Reserve expenditure table.
//	The temporary table of the covered reserves of the expenses is formed in the function of the textnotecompleteproduction()
// 
// Temporary table of the document of the movement of reserves
//	For each type of reserves, one document is defined for accrual of write-offs of current expenditures for which 
//	movements will be generated according to the registers of other expenditures and reserves of current expenditures.
//	This temporary table is formed in the function Textnotecompleteproduction()    
//
// Temporary table of receiver reserves
//	The data on the reserves of upcoming expenses are supplemented by the numbers of the item-by-item expenses nodes in the Text Receiver function of the reserves().
//	The result is saved to the temporary table of receiver reserves.
// 
// Temporary table of reserve costs
//	For each item-by-item expenses node, the amount of item-by-item expenses in the node is added to the Text Reserveextension function(). 
//	The result is saved in the temporary reserveextension table.
// 
// Temporary Summary tablereferences
//	For each reserve, the total amount of expenses covered by this reserve is determined in the function Text Summary of Condom expenses().
//	The result is placed in the temporary table Summary of condom expenses.
//
// Temporary table of detailsreferencesexternal links
//	The amount of each reserve is distributed among the expenses covered by the reserve in proportion to the expense amounts: 
//		Reserve = (Expense amount / Total expense amount) * Reserve. 
//	The calculation is performed in the function textdetalnyereservesodes().
//	The result is saved in the temporary table detailereservesodes.
// 
// Temporary table of reservesnodes
//	For each item-by-item cost node, the total amount of the reserve is calculated, which covers this expense. 
//	It is executed in the function Text Reserving Nodes().
//	The result is written to the temporary table Reserving nodes.
// 
// Temporary table of nodal_reservation_references
// For each uszla of the calculation of the SLU, new nodes are formed according to the following rules:
//	- If there are no reserves for the item–by-item expenses node or the amount in the node is negative, the original initial cost remains in the node
//	- If the amount of item–by-item expenses in the node is less than or equal to the amount of the reserve, we reduce the initial cost in the node by the amount of expenses
//	- If the amount of item–by-item expenses in the node is greater than the amount of the reserve, we reduce the initial cost in the node by the amount of the reserve  
//		distributed between item-by-item constant and variable expenses in proportion to the expense amounts.
// For example, for variable expenses:
//	Item–by-item variables - Reserve * Article-by-article variables / (Article-by-article constants + Article-by-article variables)
// 
// The output data of the data preparation stage for the resolution of the current expenses are temporary tables 
// RESERVE_NODES, detail_reserve_nodes, and node_reserve_references
// 
// Next, the stage is performed to solve the platform_reservation_references(). 
// In the stage, the case solution for item-by-item expenses is performed, taking into account the amount of reserves.
// A request for new nodes is generated in the #Node_account area to calculate the SLU.
// In the #Communication area, a request for links between nodes is generated to calculate the amounts of item-by-item expenses, taking into account reserves.
// After calculating the system of linear equations, the calculation result is loaded into the temporary table of the solution tables_Cost  
// of organizations in the region #regiontablesresults_Cost of organizations
//
// The formation of movements by registers of other expenditures and reserves of current expenditures are formed in 
// the procedure for correcting the cost of writing reserves of current expenditures() of the general module for calculating the cost of cost correction.

#EndRegion

// The stage of "Preparing the data for the resolution of the issue of current expenses"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"NodeReserves, DetailedReservesByNode, SLENodes_FutureExpenseCommitments, NodesOfSLU_ProvisionsAndContingentLiabilities_N,
		|SLEJoin_FutureExpenseCommitments, SLEJoin_FutureExpenseCommitments_TA");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextOfRequestForSolutionOfSLUReservesOfForthcomingExpenses(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function TextOfRequestForSolutionOfSLUReservesOfForthcomingExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		// preparation of temporary tables
		+ TextReserveReceivers()
		+ Common.QueryBatchSeparator() + TextProvisionsWithExpenses()
		+ Common.QueryBatchSeparator() + TextConsolidatedExpenditureOnReserves()
		+ Common.QueryBatchSeparator() + TextDetailedReservesByNode()
		+ Common.QueryBatchSeparator() + TextReservesByNodes()
		+ Common.QueryBatchSeparator() + TextSLEJoin_ItemByItemExpensesOfOrganizations() // TT svyazislu_postateynyreferences of organizations
		+ Common.QueryBatchSeparator() + TextSLENodes_FutureExpenseCommitments() // TT Nodal_reservation Of Current Expenditures
		+ Common.QueryBatchSeparator() + TextSLEJoin_FutureExpenseCommitments() // Uses a link_state_consumption of organizations
		
		+ "";
	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextReserveReceivers() // w receiver reserves, uses a reserve for expenses
	Return "
		|SELECT
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject,
		|	Nodes.NodeNumber,
		|	DD.ReserveLocal,
		|	DD.TAReserve,
		|	DD.ReserveMan
		|INTO ReserveReceivers
		|FROM
		|	ProvisionsForExpenses AS DD
		|
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS Nodes
		|		ON Nodes.Organization            = DD.Organization
		|		AND Nodes.LineOfBusiness = DD.LineOfBusiness
		|		AND Nodes.Department           = DD.Department
		|		AND Nodes.ExpenseItem          = DD.ExpenseItem
		|		AND Nodes.DimensionOfExpenses       = DD.DimensionOfExpenses
		|		AND Nodes.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
		|
		|INDEX BY
		|	Nodes.NodeNumber
		|";
EndFunction

Function TextProvisionsWithExpenses() // VT reserves with expenses, uses receivers of reserves
	Return "
		|SELECT
		|	ReserveReceivers.Organization AS Organization,
		|	ReserveReceivers.LineOfBusiness AS LineOfBusiness,
		|	ReserveReceivers.ReserveKind AS ReserveKind,
		|	ReserveReceivers.ProvisionObject AS ProvisionObject,
		|	ReserveReceivers.NodeNumber,
		|	ReserveReceivers.ReserveLocal,
		|	ReserveReceivers.TAReserve,
		|	ReserveReceivers.ReserveMan,
		|
		|	CAST((ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedVariableCostsCompl, 0)
		|		+ ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedFixedCostsCompl, 0))
		|		* AdjustmentNodes.WeightArticleByArticleLocal AS NUMBER(28,10)) AS ExpenseCompl,
		|
		|	CAST(ISNULL(TTDecisionTableTaxAccounting.PermanentDifference, 0)
		|		* AdjustmentNodes.WeightArticleByArticleLocal AS NUMBER(28,10)) AS ExpensePD,
		|
		|	CAST(ISNULL(TTDecisionTableTaxAccounting.AmountFA, 0)
		|			* AdjustmentNodes.WeightItemByItemTA AS NUMBER(28,10)) AS ConsumptionWELL,
		|
		|	CAST((ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedVariableCostsManag, 0)
		|		+ ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedFixedCostsManag, 0))
		|		* AdjustmentNodes.WeightArticleByArticleMan AS NUMBER(28,10)) AS ExpenseMan
		|
		|INTO ProvisionsWithExpenses
		|FROM
		|	ReserveReceivers AS ReserveReceivers
		|
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|		ON AdjustmentNodes.NodeNumber = ReserveReceivers.NodeNumber
		|
		|	LEFT JOIN TTTableOfSolutions_CostOfOrganizations AS TTTableOfSolutionsArticleByArticle
		|		ON TTTableOfSolutionsArticleByArticle.NodeNumber = ReserveReceivers.NodeNumber
		|
		|	LEFT JOIN TTDecisionTable_TaxAccounting AS TTDecisionTableTaxAccounting
		|		ON TTDecisionTableTaxAccounting.NodeNumber = ReserveReceivers.NodeNumber
		|WHERE
		|	(ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedVariableCostsCompl, 0)
		|		+ ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedFixedCostsCompl, 0)) > 0
		|	OR
		|	ISNULL(TTDecisionTableTaxAccounting.AmountFA, 0) > 0
		|	OR
		|	(ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedVariableCostsManag, 0)
		|		+ ISNULL(TTTableOfSolutionsArticleByArticle.ItemizedFixedCostsManag, 0)) > 0
		|	OR
		|	AdjustmentNodes.ItemizedVariableCostsCompl > 0
		|	OR
		|	AdjustmentNodes.ItemizedFixedCostsCompl > 0
		|	OR
		|	AdjustmentNodes.AmountFA > 0
		|
		|INDEX BY
		|	Organization,
		|	LineOfBusiness,
		|	ReserveKind,
		|	ProvisionObject
		|";
EndFunction

Function TextConsolidatedExpenditureOnReserves() // In summary, the use of the reserve is spent
	Return "
		|SELECT
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject,
		|	SUM(
		|		CASE
		|			WHEN DD.ExpenseCompl < 0 THEN
		|				0
		|			ELSE
		|				DD.ExpenseCompl
		|		END) AS LocalExpenses,
		|	SUM(
		|		CASE
		|			WHEN DD.ExpensePD < 0 THEN
		|				0
		|			ELSE
		|				DD.ExpensePD
		|		END) AS ExpensesPD,
		|	SUM(
		|		CASE
		|			WHEN DD.ConsumptionWELL < 0 THEN
		|				0
		|			ELSE
		|				DD.ConsumptionWELL
		|		END) AS ExpensesTA,
		|	SUM(
		|		CASE
		|			WHEN DD.ExpenseMan < 0 THEN
		|				0
		|			ELSE
		|				DD.ExpenseMan
		|		END) AS ManSExpenses
		|
		|INTO ConsolidatedExpenditureOnReserves
		|FROM
		|	ProvisionsWithExpenses AS DD
		|	
		|GROUP BY
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject
		|
		|INDEX BY
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject
		|";
EndFunction

Function TextDetailedReservesByNode() // wt detailsreferencessources
	Return "
		|SELECT
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject,
		|	DD.NodeNumber,
		|	CAST(DD.ExpenseCompl AS NUMBER(28,10)) AS ExpenseCompl,
		|	CAST(DD.ExpensePD AS NUMBER(28,10)) AS ExpensePD,
		|	CAST(DD.ConsumptionWELL AS NUMBER(28,10)) AS ConsumptionWELL,
		|	CAST(DD.ExpenseMan AS NUMBER(28,10))  AS ExpenseMan,
		|	CAST(
		|		CASE
		|			WHEN Expenses.LocalExpenses = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ExpenseCompl / Expenses.LocalExpenses AS NUMBER(28,10)) * DD.ReserveLocal
		|		END AS NUMBER(28,10)) AS ReserveLocal,
		|	CAST(
		|		CASE
		|			WHEN Expenses.ExpensesTA = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ConsumptionWELL / Expenses.ExpensesTA AS NUMBER(28,10)) * DD.TAReserve
		|		END AS NUMBER(28,10)) AS TAReserve,
		|	CAST(
		|		CASE
		|			WHEN Expenses.ManSExpenses = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ExpenseMan / Expenses.ManSExpenses AS NUMBER(28,10)) * DD.ReserveMan
		|		END AS NUMBER(28,10)) AS ReserveMan
		|
		|INTO DetailedReservesByNode
		|FROM
		|	ProvisionsWithExpenses AS DD
		|
		|	INNER JOIN ConsolidatedExpenditureOnReserves AS Expenses
		|		ON Expenses.Organization            = DD.Organization
		|		AND Expenses.LineOfBusiness = DD.LineOfBusiness
		|		AND Expenses.ReserveKind             = DD.ReserveKind
		|		AND Expenses.ProvisionObject     = DD.ProvisionObject
		|";
EndFunction

Function TextReservesByNodes() // in reserve nodes, uses detailed reserve nodes
	Return "
		|SELECT
		|	DD.NodeNumber,
		|	MAX(DD.ExpenseCompl) AS ExpenseCompl,
		|	MAX(DD.ExpensePD)   AS ExpensePD,
		|	MAX(DD.ConsumptionWELL)   AS ConsumptionWELL,
		|	MAX(DD.ExpenseMan)  AS ExpenseMan,
		|	SUM(DD.ReserveLocal) AS ReserveLocal,
		|	SUM(DD.TAReserve)   AS TAReserve,
		|	SUM(DD.ReserveMan)  AS ReserveMan
		|
		|INTO NodeReserves
		|FROM
		|	DetailedReservesByNode AS DD
		|
		|GROUP BY
		|	DD.NodeNumber
		|	
		|INDEX BY
		|	NodeNumber
		|";
EndFunction

Function TextSLENodes_FutureExpenseCommitments() // TT Nodal_reservation Of Current Expenditures
	Return "
		// The table of nodes reflects the initial cost before calculation.
		// The Cost of Tax Accounting is formed as the sum of five components of the cost of Local Accounting minus the permanent and 
		// temporary difference.
		// The Initial Cost Of Local Accounting Is Taken From The Temporary table Of The Adjustment node.
		// The amount of inclusion/exclusion of VAT in the cost from the table of the adjustment nodesinclutionexclusions is added to the initial cost.
		// The initial permanent and temporary difference is taken from the temporary table in the Tax Accounting Correction node.
		|SELECT
		|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
		// Filling in the fields must correspond to the function of the textu_substantial expenses of organizations().
		// Item-by-item expenses of organizations (regulated accounting)
		|	AdjustmentNodes.ItemizedFixedCostsCompl
		|		+ ISNULL(ValueOfVAT.ItemizedFixedCostsCompl, 0) AS ItemizedFixedCostsCompl,
		|	AdjustmentNodes.ItemizedVariableCostsCompl
		|		+ ISNULL(ValueOfVAT.ItemizedVariableCostsCompl, 0) AS ItemizedVariableCostsCompl,
		// Item-by-item expenses of organizations (management accounting)
		|	AdjustmentNodes.ItemizedFixedCostsManag
		|		+ ISNULL(ValueOfVAT.ItemizedFixedCostsManag, 0) AS ItemizedFixedCostsManag,
		|	AdjustmentNodes.ItemizedVariableCostsManag
		|		+ ISNULL(ValueOfVAT.ItemizedVariableCostsManag, 0) AS ItemizedVariableCostsManag,
		|
		// Expenses of organizations (constant difference)
		|	0 // for easy tag placement
		|	AS PermanentDifference,
		// Expenses of organizations (tax accounting)
		|	0 // for easy tag placement
		|	AS ExpensesTA
		|
		|INTO SLENodes_FutureExpenseCommitments
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|
		|	LEFT JOIN ValueOfVAT AS ValueOfVAT
		|	ON ValueOfVAT.Organization                   = AdjustmentNodes.Organization
		|		AND ValueOfVAT.ItemsLocationAttributes = AdjustmentNodes.ItemsLocationAttributes
		|		AND ValueOfVAT.AccountingSection                = AdjustmentNodes.AccountingSection
		|		AND ValueOfVAT.InventoryOwnerAttribute                 = AdjustmentNodes.InventoryOwnerAttribute
		|		AND ValueOfVAT.Lot                     = AdjustmentNodes.Lot
		|		AND ValueOfVAT.LotVendorAttributes       = AdjustmentNodes.LotVendorAttributes
		|		AND ValueOfVAT.FinancialAccountingDimension  = AdjustmentNodes.FinancialAccountingDimension
		|		AND ValueOfVAT.VATActivityType         = AdjustmentNodes.VATActivityType
		|
		|
		|UNION ALL
		|
		// For Item-By-item expenses, The Initial Cost has Already Been Generated in the temporary table of the organization's item-by-item expenses. 
		// For expenses covered by reserves, The Initial Cost is the difference between the amount of the expense and the amount of the reserve.
		// If the amount of the reserve exceeds the amount of the expense, then The Initial Cost for Calculation will be equal to 0.
		|SELECT
		|	AdjustmentNodes.NodeNumber                                       AS NodeNumber,
		// Item-by-item expenses of organizations (regulated accounting)
		|	CASE
		// If there are no cuts for the node or a negative amount of expenses in the node was obtained during the calculation
		// of the service, then we do not perform an adjustment for the amount of the reserve for such a node.
		// In such a node, we leave the initial cost of expenses.
		|		WHEN Reserves.ReserveLocal IS NULL
		|		 OR ISNULL(Reserves.ExpenseCompl, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		// if the total amount in the node is less than the reserve, we reduce the initial cost in the node by the total amount of expenses
		// adjusted for the ratio of fixed expenses to the total amount of expenses.
		|		WHEN (ISNULL(Reserves.ExpenseCompl, 0) - ISNULL(Reserves.ReserveLocal, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		|				- ISNULL(Reserves.ExpenseCompl, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		// if the total amount in the node is more than the reserve, we reduce the initial cost in the node by the amount of the reserve,
		// adjusted for the ratio of fixed costs to the total amount of expenses.
		|		ELSE ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		|			- ISNULL(Reserves.ReserveLocal, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|	END AS ItemizedFixedCostsCompl,
		|
		|	CASE
		|		WHEN Reserves.ReserveLocal IS NULL
		|		 OR ISNULL(Reserves.ExpenseCompl, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		// if the total amount in the node is less than the reserve, we reduce the initial cost in the node by the total amount of expenses
		// adjusted for the ratio of variable expenses to the total amount of expenses.
		|		WHEN (ISNULL(Reserves.ExpenseCompl, 0) - ISNULL(Reserves.ReserveLocal, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		|				- ISNULL(Reserves.ExpenseCompl, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		// if the total amount in the node is greater than the reserve, we reduce the initial cost in the node by the amount of the reserve,
		// adjusted for the ratio of variable expenses to the total amount of expenses.
		|		ELSE ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		|			- ISNULL(Reserves.ReserveLocal, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|	END AS ItemizedVariableCostsCompl,
		|
		// Item-by-item expenses of organizations (management accounting)
		|	CASE
		|		WHEN Reserves.ReserveMan IS NULL
		|		 OR ISNULL(Reserves.ExpenseMan, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsManag, 0)
		// if the total amount in the node is less than the reserve, we reduce the initial cost in the node by the total amount of expenses
		// adjusted for the ratio of fixed expenses to the total amount of expenses.
		|		WHEN (ISNULL(Reserves.ExpenseMan, 0) - ISNULL(Reserves.ReserveMan, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsManag, 0)
		|				- ISNULL(Reserves.ExpenseMan, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedFixedCostsManag, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0)
		// if the total amount in the node is more than the reserve, we reduce the initial cost in the node by the amount of the reserve,
		// adjusted for the ratio of fixed costs to the total amount of expenses.
		|		ELSE ISNULL(SLENodes.ItemizedFixedCostsManag, 0)
		|			- ISNULL(Reserves.ReserveMan, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedFixedCostsManag, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0)
		|	END AS ItemizedFixedCostsManag,
		|
		|	CASE
		|		WHEN Reserves.ReserveMan IS NULL
		|		 OR ISNULL(Reserves.ExpenseMan, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsManag, 0)
		// if the total amount in the node is less than the reserve, we reduce the initial cost in the node by the total amount of expenses
		// adjusted for the ratio of variable expenses to the total amount of expenses.
		|		WHEN (ISNULL(Reserves.ExpenseMan, 0) - ISNULL(Reserves.ReserveMan, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsManag, 0)
		|				- ISNULL(Reserves.ExpenseMan, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedVariableCostsManag, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0)
		// if the total amount in the node is greater than the reserve, we reduce the initial cost in the node by the amount of the reserve,
		// adjusted for the ratio of variable expenses to the total amount of expenses.
		|		ELSE ISNULL(SLENodes.ItemizedVariableCostsManag, 0)
		|			- ISNULL(Reserves.ReserveMan, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedVariableCostsManag, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsManag + CostOfOrganizations.ItemizedVariableCostsManag, 0)
		|	END AS ItemizedVariableCostsManag,
		|
		// Any constant difference in the system (even negative) is considered to be related to the amounts of accounting, 
		// because it occurs when there is an expense in the AC and its absence in the TA, therefore, when calculating, taking into account the write-off of reserves 
		// , it is obtained from the proportion of the amount of AC, taking into account the reserve, to the original amount of the AC by calculation according to the formula:
		//		Sum of the account of the reserve = (Sum of the account of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the reserve of the Reserve / Source Summabu) * Initial sum,
		//		where 
		//			initial sum			= Correction nodes.Constant Difference
		//			The sum of the account reserves 	= (item-by-item constant values + Item-by-item variable values) of the Cur request,
		//			The original sum is			= (nodule.Item-by-item are permanent perl + nodule.Article-by-article refineryeregl)
		|
		// The formation of the initial cost of the constant difference must correspond to the function of the textcorrection of the constant difference().
		|	CASE 
		|		WHEN Reserves.ReserveLocal IS NULL
		|		 OR ISNULL(SLENodes.ItemizedFixedCostsCompl + SLENodes.ItemizedVariableCostsCompl, 0) = 0
		|			THEN CAST(AdjustmentNodes.PermanentDifference
		|				AS NUMBER(28, 10))
		|		ELSE (
		|
		//	Item-by-itemreferences of the Cur request
		|	CASE
		|		WHEN Reserves.ReserveLocal IS NULL
		|		 OR ISNULL(Reserves.ExpenseCompl, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		|		WHEN (ISNULL(Reserves.ExpenseCompl, 0) - ISNULL(Reserves.ReserveLocal, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		|				- ISNULL(Reserves.ExpenseCompl, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		ELSE ISNULL(SLENodes.ItemizedFixedCostsCompl, 0)
		|			- ISNULL(Reserves.ReserveLocal, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|	END
		|	+
		//	Item-by-item refinereferencesfurther Cur request
		|	CASE
		|		WHEN Reserves.ReserveLocal IS NULL
		|		 OR ISNULL(Reserves.ExpenseCompl, 0) <= 0
		|		 OR ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0) <=0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		|		WHEN (ISNULL(Reserves.ExpenseCompl, 0) - ISNULL(Reserves.ReserveLocal, 0)) <= 0
		|			THEN ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		|				- ISNULL(Reserves.ExpenseCompl, 0)
		|		 			* ISNULL(CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		 			/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		ELSE ISNULL(SLENodes.ItemizedVariableCostsCompl, 0)
		|			- ISNULL(Reserves.ReserveLocal, 0)
		|		 		* ISNULL(CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|		 		/ ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl + CostOfOrganizations.ItemizedVariableCostsCompl, 0)
		|	END
		|
		|	) / ISNULL(SLENodes.ItemizedFixedCostsCompl + SLENodes.ItemizedVariableCostsCompl, 0) * AdjustmentNodes.PermanentDifference
		|	END AS PermanentDifference,
		|
		|	CASE
		|		WHEN FALSE THEN 0 // for easy tag placement
		|	END AS ExpensesTA
		|
		|FROM
		|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|
		|	LEFT JOIN SLENodes_ItemByItemExpensesOfOrganizations AS SLENodes
		|		ON SLENodes.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|	LEFT JOIN TTTableOfSolutions_CostOfOrganizations AS CostOfOrganizations
		|		ON CostOfOrganizations.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|	LEFT JOIN NodeReserves AS Reserves
		|		ON Reserves.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|
		|";
EndFunction

Function TextSLEJoin_FutureExpenseCommitments()
	Return "
		|SELECT
		|	Links.SourceNodeNumber,
		|	Links.ReceiverNodeNumber,
		|	Links.ArcWeightLocal AS ArcWeightLocal,
		|	Links.ArcWeightMan AS ArcWeightMan
		|
		|INTO SLEJoin_FutureExpenseCommitments
		|FROM
		|	SLEConnections_ItemByItemExpensesOfOrganizations AS Links
		|";
EndFunction


#EndRegion


// Calculation of a system of linear equations
#Region ProceduresForSolvingCases

// For compatibility with the platform below 8.3.14
//
// Returns:
//	SystemOfLinearEquationsCalculation - component of the solution of a system of linear equations
//
Function GetComponentToSolveSLU(CalculationParameters) Export
	
	SystemOfLinearEquationsCalculation = Common.CalculateInSafeMode("New SystemOfLinearEquationsCalculation");
	
	SystemOfLinearEquationsCalculation.IterationCount				  = CalculationParameters.SolutionOfSLU.MaxNumberOfIterations;
	SystemOfLinearEquationsCalculation.AdequateAccuracy					  = CalculationParameters.SolutionOfSLU.AdequateAccuracy;
	SystemOfLinearEquationsCalculation.ComputationalResourcesUsage = CalculationParameters.SolutionOfSLU.ComputationalResourcesUsage;
	SystemOfLinearEquationsCalculation.AlgorithmSelectionBorder    = CalculationParameters.SolutionOfSLU.AlgorithmSelectionBorder;
	
	Return SystemOfLinearEquationsCalculation;
	
EndFunction

// Performs calculation of systems of equations for indicators:
//	Cost, costbeznds, costabalance, Labor costs
//		
// The result of this procedure will be a temporary table " vttablitsaresolutions_Prime cost of the enterprise"
//
Procedure SolveCase_CostOfEnterprise(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase_CostOfEnterprise");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho giá vốn doanh nghiệp';
									|ru = 'Решение для себестоимости предприятия';
									|en = 'Solution for the enterprise cost'; fa = 'Solution for the enterprise cost';
									|it = 'Soluzione per costi di produzione dello stabilimento';
									|pl = 'Rozwiązania dla kosztu własnego przedsiębiorstwa';
									|tr = 'İşletme maliyet çözümü'", Common.DefaultLanguageCode());
	
	#Region Nodes
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.Cost AS Cost,
	|	AdjustmentNodes.CostExcludingVAT AS CostExcludingVAT,
	|	AdjustmentNodes.OffBalanceCost AS OffBalanceCost,
	|	AdjustmentNodes.LaborCosts AS LaborCosts
	|FROM
	|	ServiceNodesMaterialAndLaborCosts AS AdjustmentNodes
	|";
	
	#EndRegion
	
	#Region Links
	
	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	Links.SourceNodeNumber AS SourceNodeNumber,
	|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	Links.ArcWeightCost,
	|	Links.ArcWeightCostWithoutVAT,
	|	Links.ArcWeightCostOffBalance,
	|	Links.ArcWeightLaborCosts
	|FROM
	|	ServiceConnectionsMaterialAndLaborCosts AS Links
	|";
	CommunicationRequest.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, CommunicationRequest.Text);
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightCost", "Cost");
	SLEFieldStructure.Insert("ArcWeightCostWithoutVAT", "CostExcludingVAT");
	SLEFieldStructure.Insert("ArcWeightCostOffBalance", "OffBalanceCost");
	SLEFieldStructure.Insert("ArcWeightLaborCosts", "LaborCosts");

	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromQueries(
		CalculationParameters,
		RequestNodes,
		"NodeNumber",
		CommunicationRequest,
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_CostOfEnterprise_Material_.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "RelationDataSource_CostOfEnterprise_Material_.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SLESolution_Cost
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "Cost";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightCost";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightCostWithoutVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "ServiceNodesMaterialAndLaborCosts");
	CalculationParameters.Insert("RelationshipTableName", "ServiceConnectionsMaterialAndLaborCosts");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "Cost", "CostExcludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightCost", "ArcWeightCostWithoutVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"Cost, CostExcludingVAT",,"TableOfSolutionsCost");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (giá trị gồm thuế GTGT và không thuế GTGT)';
										|ru = ' (стоимость с НДС и без НДС)';
										|en = ' (cost incl. VAT and excl. VAT)'; fa = ' (cost incl. VAT and excl. VAT)';
										|it = ' (cost incl. VAT and excl. VAT)';
										|pl = ' (cost incl. VAT and excl. VAT)';
										|tr = ' (KDV dahil ve KDV hariç maliyet)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SLESolution_LaborCosts
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LaborCosts";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLaborCosts";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"LaborCosts",,"TableOfSolutionsLaborCosts");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (công lao động)';
										|ru = ' (трудозатраты)';
										|en = ' (labor costs)'; fa = ' (labor costs)';
										|it = ' (labor costs)';
										|pl = ' (labor costs)';
										|tr = ' (iş gücü maliyetleri)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLE_BALANCE
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "OffBalanceCost";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightCostOffBalance";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"OffBalanceCost",,"TableOfSolutionsOffBalance");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (các chỉ tiêu ngoài bảng)';
										|ru = ' (забалансовые показатели)';
										|en = ' (off-balance indicators)'; fa = ' (off-balance indicators)';
										|it = ' (indicatori fuori bilancio)';
										|pl = ' (wskaźniki pozabilansowe)';
										|tr = ' (bilanço dışı göstergeler)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion
	
	#Region TTTableOfSolutions_CostOfEnterprise
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_CostOfEnterprise_Material");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfEnterprise");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_CostOfEnterprise_Material(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"TableOfSolutionsCost, TableOfSolutionsLaborCosts, TableOfSolutionsOffBalance");
	
	SaveSLUVFile(CalculationParameters);
	
EndProcedure

Function QueryTextTTTableOfSolutions_CostOfEnterprise_Material(CalculationParameters)
	
	QueryText = "
	|SELECT TOP 1
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.Cost AS Cost,
	|	AdjustmentNodes.CostExcludingVAT AS CostExcludingVAT,
	|	AdjustmentNodes.OffBalanceCost AS OffBalanceCost,
	|	AdjustmentNodes.LaborCosts AS LaborCosts
	|INTO SLENodes_Test
	|FROM
	|	ServiceNodesMaterialAndLaborCosts AS AdjustmentNodes
	|;
	|SELECT TOP 1
	|	Links.SourceNodeNumber AS SourceNodeNumber,
	|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
	|	Links.ArcWeightCost,
	|	Links.ArcWeightCostWithoutVAT,
	|	Links.ArcWeightCostOffBalance,
	|	Links.ArcWeightLaborCosts
	|INTO SLEJoin_Test
	|FROM
	|	ServiceConnectionsMaterialAndLaborCosts AS Links
	|;
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0 OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod
	|			= VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsCost.Cost, 0) END AS NUMBER(28,10)) AS Cost,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0 OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod
	|			= VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsCost.CostExcludingVAT, 0) END AS NUMBER(28,10)) AS CostExcludingVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0 OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod
	|			= VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|	 	 AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsOffBalance.OffBalanceCost, 0) END AS NUMBER(28,10)) AS OffBalanceCost,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsLaborCosts.LaborCosts, 0) END AS NUMBER(28,10)) AS LaborCosts
	|
	|INTO TTTableOfSolutions_CostOfEnterprise
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|
	|	LEFT JOIN TableOfSolutionsCost AS TableOfSolutionsCost
	|		ON TableOfSolutionsCost.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsLaborCosts AS TableOfSolutionsLaborCosts
	|		ON TableOfSolutionsLaborCosts.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsOffBalance AS TableOfSolutionsOffBalance
	|		ON TableOfSolutionsOffBalance.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs calculation of systems of equations for indicators:
//	Stoimosti, Timotesubani, Truestring, Stoimostyu, TradeStation
//		
// The result of this procedure will be a temporary table " vttablitsaresolutions_Cost of organizationsorganizations"
//
Procedure SolveCase__CostOfOrganizations(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase__CostOfOrganizations");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho giá vốn doanh nghiệp';
									|ru = 'Решение для себестоимости организаций';
									|en = 'Solution for cost of companies'; fa = 'Solution for cost of companies';
									|it = 'Soluzione per costi di produzione delle aziende';
									|pl = 'Rozwiązania dla kosztu własnego firm';
									|tr = 'İş yeri maliyet çözümü'", Common.DefaultLanguageCode());
	
	#Region Nodes
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.LocalCost AS LocalCost,
	|	AdjustmentNodes.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	AdjustmentNodes.LaborCostsLocal AS LaborCostsLocal,
	|	AdjustmentNodes.CostMan AS CostMan,
	|	AdjustmentNodes.LaborCostsMan AS LaborCostsMan
	|FROM
	|	ServiceNodesMaterialAndLaborCosts AS AdjustmentNodes
	|";
	
	#EndRegion
	
	#Region Links
	
	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	Links.SourceNodeNumber AS SourceNodeNumber,
	|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	Links.ArcWeightLocalCost,
	|	Links.ArcWeightCostOffBalanceLocal,
	|	Links.ArcWeightLocalLaborCosts,
	|	Links.ArcWeightManCost,
	|	Links.ArcWeightLaborCostsMan
	|FROM
	|	ServiceConnectionsMaterialAndLaborCosts AS Links
	|";
	CommunicationRequest.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, CommunicationRequest.Text);
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightLocalCost", "LocalCost");
	SLEFieldStructure.Insert("ArcWeightCostOffBalanceLocal",  "OffBalanceCostLocal");
	SLEFieldStructure.Insert("ArcWeightLocalLaborCosts",  "LaborCostsLocal");
	SLEFieldStructure.Insert("ArcWeightManCost",  "CostMan");
	SLEFieldStructure.Insert("ArcWeightLaborCostsMan",  "LaborCostsMan");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromQueries(
		CalculationParameters,
		RequestNodes,
		"NodeNumber",
		CommunicationRequest,
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "SourceOfNodeData_CostOfOrganization_Material.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "SourceOfTheseLinks_CostOfOrganization_Material.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SLESolution_Cost
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LocalCost";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocalCost";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightManCost";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "ServiceNodesMaterialAndLaborCosts");
	CalculationParameters.Insert("RelationshipTableName", "ServiceConnectionsMaterialAndLaborCosts");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "LocalCost", "CostMan"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocalCost", "ArcWeightManCost"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"LocalCost, CostMan",,"TableOfSolutionsCost");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (giá trị kế toán và điều chỉnh)';
										|ru = ' (стоимость регл и упр)';
										|en = ' (cost local and mgmt)'; fa = ' (cost local and mgmt)';
										|it = ' (cost local and mgmt)';
										|pl = ' (cost local and mgmt)';
										|tr = ' (net başlangıç maliyeti, yerel ve yönetim)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SLESolution_LaborCosts
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LaborCostsLocal";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocalLaborCosts";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LaborCostsMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLaborCostsMan";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"LaborCostsLocal, LaborCostsMan",,"TableOfSolutionsLaborCosts");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (các chỉ tiêu trong bảng)';
										|ru = ' (балансовые показатели)';
										|en = ' (balance indicators)'; fa = ' (balance indicators)';
										|it = ' (indicatori di bilancio)';
										|pl = ' (wskaźniki bilansowe)';
										|tr = ' (bilanço göstergeleri)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLE_BALANCE
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "OffBalanceCostLocal";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightCostOffBalanceLocal";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"OffBalanceCostLocal",,"TableOfSolutionsOffBalance");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (các chỉ tiêu ngoài bảng)';
										|ru = ' (забалансовые показатели)';
										|en = ' (off-balance indicators)'; fa = ' (off-balance indicators)';
										|it = ' (indicatori fuori bilancio)';
										|pl = ' (wskaźniki pozabilansowe)';
										|tr = ' (bilanço dışı göstergeler)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion
	
	#Region TTTableOfSolutions_CostOfOrganizations
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_CostOfOrganizations_Material");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfOrganizations");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_CostOfOrganizations_Material(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"TableOfSolutionsCost, TableOfSolutionsLaborCosts, TableOfSolutionsOffBalance");

EndProcedure

Function QueryTextTTTableOfSolutions_CostOfOrganizations_Material(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsCost.LocalCost, 0) END AS NUMBER(28,10)) AS LocalCost,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|	 	 AND VALUETYPE(AdjustmentNodes.Lot) <> TYPE(Catalog.ProductionLots)
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsOffBalance.OffBalanceCostLocal, 0) END AS NUMBER(28,10)) AS OffBalanceCostLocal,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsLaborCosts.LaborCostsLocal, 0) END AS NUMBER(28,10)) AS LaborCostsLocal,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			OR TTAccountingPoliciesOfFinancialAccounting.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		 AND NOT AdjustmentNodes.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsCost.CostMan, 0) END AS NUMBER(28,10)) AS CostMan,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsLaborCosts.LaborCostsMan, 0) END AS NUMBER(28,10)) AS LaborCostsMan
	|
	|INTO TTTableOfSolutions_CostOfOrganizations
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|	INNER JOIN TTAccountingPoliciesOfFinancialAccounting AS TTAccountingPoliciesOfFinancialAccounting
	|		ON AdjustmentNodes.Organization = TTAccountingPoliciesOfFinancialAccounting.Organization
	|
	|	LEFT JOIN TableOfSolutionsCost AS TableOfSolutionsCost
	|		ON TableOfSolutionsCost.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsLaborCosts AS TableOfSolutionsLaborCosts
	|		ON TableOfSolutionsLaborCosts.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsOffBalance AS TableOfSolutionsOffBalance
	|		ON TableOfSolutionsOffBalance.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs calculation of systems of equations for indicators:
//	additional expenses, additional expenses
//		
// The result of this procedure will be a temporary table of "Decision Tables".
//
Procedure SolveCase_AdditionalCosts(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase_AdditionalCosts");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho giá vốn doanh nghiệp';
									|ru = 'Решение для себестоимости предприятия';
									|en = 'Solution for the enterprise cost'; fa = 'Solution for the enterprise cost';
									|it = 'Soluzione per costi di produzione dello stabilimento';
									|pl = 'Rozwiązania dla kosztu własnego przedsiębiorstwa';
									|tr = 'İşletme maliyet çözümü'", Common.DefaultLanguageCode());
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightWithVAT", "CostInclVAT");
	SLEFieldStructure.Insert("ArcWeightWithoutVAT", "CostExcludingVAT");
	SLEFieldStructure.Insert("ArcWeightLocal", "LocalCost");
	SLEFieldStructure.Insert("ArcWeightMan", "CostMan");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"ServiceNodesAdditionalCosts",
		"NodeNumber",
		"SLEConnections_AdditionalCosts",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	#Region Nodes
	
	Query.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.CostInclVAT AS CostInclVAT,
	|	AdjustmentNodes.CostExcludingVAT AS CostExcludingVAT,
	|	AdjustmentNodes.LocalCost AS LocalCost,
	|	AdjustmentNodes.CostMan AS CostMan
	|FROM
	|	ServiceNodesAdditionalCosts AS AdjustmentNodes
	|";
	
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																											|ru = 'узлы';
																																											|en = 'nodes'; fa = 'nodes';
																																											|it = 'nodi';
																																											|pl = 'węzły';
																																											|tr = 'üniteler'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region Links
	
	Query.Text = "
	|SELECT
	|	Links.SourceNodeNumber AS SourceNodeNumber,
	|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	Links.ArcWeightWithVAT       AS ArcWeightWithVAT,
	|	Links.ArcWeightWithoutVAT     AS ArcWeightWithoutVAT,
	|	Links.ArcWeightLocal       AS ArcWeightLocal,
	|	Links.ArcWeightMan        AS ArcWeightMan
	|FROM
	|	SLEConnections_AdditionalCosts AS Links
	|";
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(
		CalculationParameters, Query.Text);
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(
		CalculationParameters, Query,,, True, 
		ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
												|ru = 'связи';
												|en = 'links'; fa = 'links';
												|it = 'collegamenti';
												|pl = 'powiązania';
												|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_AddExpensesForGoods.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "RelationDataSource_AddExpensesForGoods.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters,
		"SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase__AdditionalExpensesOfEnterprise");
	
	#Region SolutionSLE_EnterpriseAccounting
	
	// description of systems
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostInclVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithVAT";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithoutVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "ServiceNodesAdditionalCosts");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_AdditionalCosts");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostInclVAT", "CostExcludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightWithVAT", "ArcWeightWithoutVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostInclVAT, CostExcludingVAT",
		,
		"CalculationResultEnterpriseAccounting");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
		
	DecisionTable.Clear();
	
	#EndRegion
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveSLEPlatform_AdditionalExpensesAmountOfOrganizations");
	
	#Region SolutionSLU_Man
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "ServiceNodesAdditionalCosts");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_AdditionalCosts");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostMan", "CostMan"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightMan", "ArcWeightMan"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostMan",
		,
		"ManCalculationResult");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
		
	DecisionTable.Clear();
	
	#EndRegion
		
	#Region SolutionSLU_Local
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LocalCost";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "ServiceNodesAdditionalCosts");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_AdditionalCosts");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "LocalCost", "LocalCost"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocal", "ArcWeightLocal"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"LocalCost",
		,
		"LocalCalculationResult");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	#EndRegion
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#Region DecisionTable
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_AdditionalCosts");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"DecisionTable");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_AdditionalCosts(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"ServiceNodesAdditionalCosts, SLEConnections_AdditionalCosts");
	
EndProcedure

Function QueryTextTTTableOfSolutions_AdditionalCosts(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithVAT = 0
	|			THEN 0
	|		ELSE ISNULL(CalculationResultEnterpriseAccounting.CostInclVAT, 0) END AS NUMBER(28,10)) AS CostInclVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(CalculationResultEnterpriseAccounting.CostExcludingVAT, 0) END AS NUMBER(28,10)) AS CostExcludingVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.LocalWeight = 0
	|			THEN 0
	|		ELSE ISNULL(LocalCalculationResult.LocalCost, 0) END AS NUMBER(28,10)) AS LocalCost,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.ManSWeight = 0
	|			THEN 0
	|		ELSE ISNULL(ManCalculationResult.CostMan, 0) END AS NUMBER(28,10)) AS CostMan
	|
	|INTO DecisionTable
	|FROM
	|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN CalculationResultEnterpriseAccounting AS CalculationResultEnterpriseAccounting
	|		ON CalculationResultEnterpriseAccounting.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManCalculationResult AS ManCalculationResult
	|		ON ManCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN LocalCalculationResult AS LocalCalculationResult
	|		ON LocalCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(CalculationResultEnterpriseAccounting.CostInclVAT, 0) END AS NUMBER(28,10)) AS CostInclVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(CalculationResultEnterpriseAccounting.CostExcludingVAT, 0) END AS NUMBER(28,10)) AS CostExcludingVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(LocalCalculationResult.LocalCost, 0) END AS NUMBER(28,10)) AS LocalCost,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(ManCalculationResult.CostMan, 0) END AS NUMBER(28,10)) AS CostMan
	|
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN CalculationResultEnterpriseAccounting AS CalculationResultEnterpriseAccounting
	|		ON CalculationResultEnterpriseAccounting.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManCalculationResult AS ManCalculationResult
	|		ON ManCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN LocalCalculationResult AS LocalCalculationResult
	|		ON LocalCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs the calculation of systems of equations for the cost of past periods.
//		
// The result of this procedure will be a temp table of "Resolution tables".
//
Procedure SolveSLEPlatform_CalculationOfCostOfPastPeriods(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveSLEPlatform_CalculationOfCostOfPastPeriods");
	
	ExplanationForMeasurement = NStr("ru = 'Решение для расчета себестоимости прошлых периодов';
									|vi = 'Solution for calculating the cost of previous periods';
									|en = 'Solution for calculating the cost of previous periods'; fa = 'Solution for calculating the cost of previous periods';
									|it = 'Solution for calculating the cost of previous periods';
									|pl = 'Solution for calculating the cost of previous periods';
									|tr = 'Geçmiş dönemlerin maliyet hesaplama çözümü'", Common.DefaultLanguageCode());
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightWithVAT", "CostVariancesIncludingVAT, AdditionalExpensesIncludingVAT");
	SLEFieldStructure.Insert("ArcWeightWithoutVAT", "CostVariancesExcludingVAT, AdditionalExpensesExcludingVAT");
	SLEFieldStructure.Insert("ArcWeightLocal", "CostVariancesLocal, AddExpensesLocal, PermanentDifference");
	SLEFieldStructure.Insert("ArcWeightMan", "CostVariancesMgmt, AddExpensesMan");
	SLEFieldStructure.Insert("WeightOfArcISTA", "CostInTaxAccounting, AIT");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"NodesSLU_CalculationOfCostOfPastPeriods",
		"NodeNumber",
		"SvyaziSLU_CalculationOfCostOfPastPeriods",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
		
	#Region Nodes
	
	Query.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.CostVariancesIncludingVAT,
	|	AdjustmentNodes.CostVariancesExcludingVAT,
	|	AdjustmentNodes.CostVariancesLocal,
	|	AdjustmentNodes.CostVariancesMgmt,
	|	AdjustmentNodes.AdditionalExpensesIncludingVAT AS AdditionalExpensesIncludingVAT,
	|	AdjustmentNodes.AdditionalExpensesExcludingVAT AS AdditionalExpensesExcludingVAT,
	|	AdjustmentNodes.AddExpensesLocal AS AddExpensesLocal,
	|	AdjustmentNodes.AddExpensesMan AS AddExpensesMan,
	|	AdjustmentNodes.PermanentDifference AS PermanentDifference,
	|	AdjustmentNodes.CostInTaxAccounting AS CostInTaxAccounting,
	|	AdjustmentNodes.AIT AS AIT
	|FROM
	|	NodesSLU_CalculationOfCostOfPastPeriods AS AdjustmentNodes
	|";
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True,
		ExplanationForMeasurement + ", " + NStr("vi = 'nút';
												|ru = 'узлы';
												|en = 'nodes'; fa = 'nodes';
												|it = 'nodes';
												|pl = 'nodes';
												|tr = 'üniteler'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	#Region Links
	
	Query.Text = "
	|SELECT
	|	Links.SourceNodeNumber AS SourceNodeNumber,
	|	Links.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	Links.ArcWeightWithVAT		AS ArcWeightWithVAT,
	|	Links.ArcWeightWithoutVAT		AS ArcWeightWithoutVAT,
	|	Links.ArcWeightLocal		AS ArcWeightLocal,
	|	Links.WeightOfArcISTA			AS WeightOfArcISTA,
	|	Links.ArcWeightMan		AS ArcWeightMan
	|FROM
	|	SvyaziSLU_CalculationOfCostOfPastPeriods AS Links
	|";
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True, 
		ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
												|ru = 'связи';
												|en = 'links'; fa = 'links';
												|it = 'links';
												|pl = 'links';
												|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	#EndRegion
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_PastPeriod.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "SourceOfDataLinks_PastPeriod.txt";
		ValueToFile(FileName, LinkTable);
		
 	EndIf;
 	
 	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters,
		"SolveSystemOfLinearEquations", ExplanationForMeasurement);
 	
 	#Region SolvingSLUCommonPart
 	
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SolutionSLU_EnterpriseAccountingWithVAT
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostVariancesIncludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithVAT";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "AdditionalExpensesIncludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostVariancesIncludingVAT", "AdditionalExpensesIncludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightWithVAT", "ArcWeightWithVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostVariancesIncludingVAT, AdditionalExpensesIncludingVAT");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "ResultOfCalculationIsCompanySAccountingWithVAT";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
		
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_EnterpriseAccountingWithoutVAT
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostVariancesExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithoutVAT";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "AdditionalExpensesExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithoutVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostVariancesExcludingVAT", "AdditionalExpensesExcludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightWithoutVAT", "ArcWeightWithoutVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostVariancesExcludingVAT, AdditionalExpensesExcludingVAT");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "ResultOfCalculationIsCompanySAccountingWithoutVAT";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
		
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_Man
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostVariancesMgmt";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "AddExpensesMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostVariancesMgmt", "AddExpensesMan"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightMan", "ArcWeightMan"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostVariancesMgmt, AddExpensesMan");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "ManCalculationResult";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
		
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_Local
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostVariancesLocal";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "AddExpensesLocal";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostVariancesLocal", "AddExpensesLocal"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocal", "ArcWeightLocal"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"CostVariancesLocal, AddExpensesLocal");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "LocalCalculationResult";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_NU
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostInTaxAccounting";
	SystemDetails.FactorsInRelationsColumn = "WeightOfArcISTA";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "CostInTaxAccounting", "CostInTaxAccounting"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "WeightOfArcISTA", "WeightOfArcISTA"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution("CostInTaxAccounting");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "ResultOfCalculationIsTA";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_NDD
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "AIT";
	SystemDetails.FactorsInRelationsColumn = "WeightOfArcISTA";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "NodesSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "AIT", "AIT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "WeightOfArcISTA", "WeightOfArcISTA"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution("AIT");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "AITCalculationResult";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	#EndRegion

	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);

	#Region SolutionSLU_ConstantDifference
	
	PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD(CalculationParameters);
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters,
		"CalculateSystemsOfLinearEquations_CostPDIsConstant", ExplanationForMeasurement);
		
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightLocal", "PermanentDifference");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"SERVICENodes_CalculationOfCostOfPastPeriods_CostedPD",
		"NodeNumber",
		"SvyaziSLU_CalculationOfCostOfPastPeriods",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
		
	Query.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	AdjustmentNodes.PermanentDifference AS PermanentDifference
	|FROM
	|	SERVICENodes_CalculationOfCostOfPastPeriods_CostedPD AS AdjustmentNodes
	|";
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query,,, True,
		ExplanationForMeasurement + ", " + NStr("vi = 'nút';
												|ru = 'узлы';
												|en = 'nodes'; fa = 'nodes';
												|it = 'nodes';
												|pl = 'nodes';
												|tr = 'üniteler'", Common.DefaultLanguageCode()));
		
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "PermanentDifference";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SERVICENodes_CalculationOfCostOfPastPeriods_CostedPD");
	CalculationParameters.Insert("RelationshipTableName", "SvyaziSLU_CalculationOfCostOfPastPeriods");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "PermanentDifference", "PermanentDifference"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocal", "ArcWeightLocal"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution("PermanentDifference");
	SLULoadingParameters.NumberOfDigits = 31;
	SLULoadingParameters.ConsiderZeroSolutions = False;
	SLULoadingParameters.TempTableName = "ResultOfCalculationIsPD";
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion
	
	#Region TableOfDecisions_LastPeriod
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTDecisionTable_LastPeriod");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTDecisionTable_LastPeriod");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextTTTableOfDecisions_LastPeriod(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"NodesSLU_CalculationOfCostOfPastPeriods, SvyaziSLU_CalculationOfCostOfPastPeriods");
	
EndProcedure

Function TextTTTableOfDecisions_LastPeriod(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberWithVAT = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsCompanySAccountingWithVAT.CostVariancesIncludingVAT, 0) END AS NUMBER(28,10)) AS CostVariancesIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.QuantityWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsCompanySAccountingWithoutVAT.CostVariancesExcludingVAT, 0) END AS NUMBER(28,10)) AS CostVariancesExcludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalCalculationResult.CostVariancesLocal, 0) END AS NUMBER(28,10)) AS CostVariancesLocal,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfMen = 0
	|			THEN 0
	|		ELSE ISNULL(ManCalculationResult.CostVariancesMgmt, 0) END AS NUMBER(28,10)) AS CostVariancesMgmt,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberWithVAT = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsCompanySAccountingWithVAT.AdditionalExpensesIncludingVAT, 0) END AS NUMBER(28,10)) AS AdditionalExpensesIncludingVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.QuantityWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsCompanySAccountingWithoutVAT.AdditionalExpensesExcludingVAT, 0) END AS NUMBER(28,10)) AS AdditionalExpensesExcludingVAT,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalCalculationResult.AddExpensesLocal, 0) END AS NUMBER(28,10)) AS AddExpensesLocal,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfTA = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsTA.CostInTaxAccounting, 0) END AS NUMBER(28,10)) AS CostInTaxAccounting,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfLocal = 0
	|			THEN 0
	|		ELSE ISNULL(ResultOfCalculationIsPD.PermanentDifference, 0) END AS NUMBER(28,10)) AS PermanentDifference,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfTA = 0 AND AdjustmentNodes.NumberOfLocal = 0
	|			THEN 0
	|		WHEN AdjustmentNodes.NumberOfTA = 0 AND AdjustmentNodes.NumberOfLocal <> 0
	|			THEN ISNULL(LocalCalculationResult.CostVariancesLocal, 0)
	|			+ ISNULL(LocalCalculationResult.AddExpensesLocal, 0)
	|			- ISNULL(ResultOfCalculationIsPD.PermanentDifference, 0)
	|		WHEN AdjustmentNodes.NumberOfTA <> 0 AND AdjustmentNodes.NumberOfLocal = 0
	|			THEN -(ISNULL(LocalCalculationResult.CostVariancesLocal, 0)
	|			+ ISNULL(LocalCalculationResult.AddExpensesLocal, 0)
	|			- ISNULL(ResultOfCalculationIsPD.PermanentDifference, 0))
	|		ELSE ISNULL(LocalCalculationResult.CostVariancesLocal, 0)
	|			+ ISNULL(LocalCalculationResult.AddExpensesLocal, 0) 
	|			- ISNULL(ResultOfCalculationIsTA.CostInTaxAccounting, 0)
	|			- ISNULL(ResultOfCalculationIsPD.PermanentDifference, 0)
	|		END AS NUMBER(28,10)) AS CostTD,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfMen = 0
	|			THEN 0
	|		ELSE ISNULL(ManCalculationResult.AddExpensesMan, 0) END AS NUMBER(28,10)) AS AddExpensesMan,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.NumberOfTA = 0
	|			THEN 0
	|		ELSE ISNULL(AITCalculationResult.AIT, 0) END AS NUMBER(28,10)) AS AIT
	|
	|INTO TTDecisionTable_LastPeriod
	|FROM
	|	TTNodesOfDeviations AS AdjustmentNodes
	|
	|	LEFT JOIN ResultOfCalculationIsCompanySAccountingWithVAT AS ResultOfCalculationIsCompanySAccountingWithVAT
	|		ON ResultOfCalculationIsCompanySAccountingWithVAT.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ResultOfCalculationIsCompanySAccountingWithoutVAT AS ResultOfCalculationIsCompanySAccountingWithoutVAT
	|		ON ResultOfCalculationIsCompanySAccountingWithoutVAT.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManCalculationResult AS ManCalculationResult
	|		ON ManCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN LocalCalculationResult AS LocalCalculationResult
	|		ON LocalCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ResultOfCalculationIsTA AS ResultOfCalculationIsTA
	|		ON ResultOfCalculationIsTA.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ResultOfCalculationIsPD AS ResultOfCalculationIsPD
	|		ON ResultOfCalculationIsPD.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN AITCalculationResult AS AITCalculationResult
	|		ON AITCalculationResult.NodeNumber = AdjustmentNodes.NodeNumber
	|WHERE
	|	NOT ResultOfCalculationIsCompanySAccountingWithVAT.NodeNumber IS NULL
	|	OR NOT ResultOfCalculationIsCompanySAccountingWithoutVAT.NodeNumber IS NULL
	|	OR NOT ManCalculationResult.NodeNumber IS NULL
	|	OR NOT LocalCalculationResult.NodeNumber IS NULL
	|	OR NOT ResultOfCalculationIsTA.NodeNumber IS NULL
	|	OR NOT ResultOfCalculationIsPD.NodeNumber IS NULL
	|	OR NOT AITCalculationResult.NodeNumber IS NULL
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs calculation of systems of equations for indicators:
//	Stoimosti, Stoimostyu
//		
// The result of this procedure will be a temporary table " vttablitsaresolutions_Cost of organizationsorganizations"
//
Procedure SolveCase__InclusionExclusionOfVATOrganizations(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase__InclusionExclusionOfVATOrganizations");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho giá vốn doanh nghiệp';
									|ru = 'Решение для себестоимости организаций';
									|en = 'Solution for cost of companies'; fa = 'Solution for cost of companies';
									|it = 'Soluzione per costi di produzione delle aziende';
									|pl = 'Rozwiązania dla kosztu własnego firm';
									|tr = 'İş yeri maliyet çözümü'", Common.DefaultLanguageCode());
	
	#Region Nodes
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber        AS NodeNumber,
	|	AdjustmentNodes.LocalCost    AS LocalCost,
	|	AdjustmentNodes.CostMan     AS CostMan
	|FROM
	|	AdjustmentNodesInclusionExclusionOfVAT AS AdjustmentNodes";
	
	#EndRegion
	
	#Region Links
	
	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	WriteOffMovements.SourceNodeNumber,
	|	WriteOffMovements.ReceiverNodeNumber,
	|	WriteOffMovements.ArcWeightLocalCost,
	|	WriteOffMovements.ArcWeightManCost
	|FROM
	|	ServiceConnection_InclusionExclusionOfVAT AS WriteOffMovements
	|";
	
	#EndRegion
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightLocalCost", "LocalCost");
	SLEFieldStructure.Insert("ArcWeightManCost",  "CostMan");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromQueries(
		CalculationParameters,
		RequestNodes,
		"NodeNumber",
		CommunicationRequest,
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	#Region SolutionOfSLU
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_NDS.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "SourceOfLinksDataIs_NDS.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	// description of systems
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "LocalCost";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocalCost";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "CostMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightManCost";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"LocalCost, CostMan");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	#Region DecisionTable
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_InclusionExclusionOfVATOrganizations");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfOrganizations");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_InclusionExclusionOfVATOrganizations(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	DecisionTable.Clear();
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"DecisionTable");
	
EndProcedure

Function QueryTextTTTableOfSolutions_InclusionExclusionOfVATOrganizations(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(DecisionTable.LocalCost, 0) END AS NUMBER(28,10)) AS LocalCost,
	|
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(DecisionTable.CostMan, 0) END AS NUMBER(28,10)) AS CostMan
	|INTO TTTableOfSolutions_CostOfOrganizations
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN DecisionTable AS DecisionTable
	|	ON DecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs the calculation of systems of equations for the following indicators:
//	Reserve Devaluation, Reserve devaluation
//		
// The result of this procedure will be a temporary table "vttablitsaresolution_reservation_conventions".
//
Procedure SolveCaseOf_ReservesForImpairmentOfStocksOfOrganizations(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCaseOf_ReservesForImpairmentOfStocksOfOrganizations");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho giá vốn doanh nghiệp';
									|ru = 'Решение для себестоимости организаций';
									|en = 'Solution for cost of companies'; fa = 'Solution for cost of companies';
									|it = 'Soluzione per costi di produzione delle aziende';
									|pl = 'Rozwiązania dla kosztu własnego firm';
									|tr = 'İş yeri maliyet çözümü'", Common.DefaultLanguageCode());
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|
	|	AdjustmentNodes.ProvisionForImpairmentLocal  AS ProvisionForImpairmentLocal,
	|	AdjustmentNodes.ProvisionForImpairmentMan   AS ProvisionForImpairmentMan
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|";

	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	NodeConnections.SourceNodeNumber AS SourceNodeNumber,
	|	NodeConnections.ReceiverNodeNumber AS ReceiverNodeNumber,
	|
	|	CAST(
	|		CASE
	|			WHEN NOT NodeConnections.TransferReserve
	|				THEN 0
	|			ELSE
	|				-NodeConnections.ArcWeight
	|		END AS NUMBER(28,10)) AS ArcWeightReserveLocal,
	|	CAST(
	|		CASE
	|			WHEN NOT NodeConnections.TransferReserve
	|				THEN 0
	|			ELSE
	|				-NodeConnections.ArcWeight
	|		END AS NUMBER(28,10)) AS ArcWeightReserveMan
	|FROM
	|	ConnectionsOfNodesOfReservesUnderImpairmentOfStocks AS NodeConnections
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS SourceNodeNumber,
	|	AdjustmentNodes.NodeNumber AS ReceiverNodeNumber,
	|
	|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightReserveLocal,
	|	CAST(AdjustmentNodes.Count - AdjustmentNodes.QuantityIsWrittenOffAtFixedCost AS NUMBER(28,10)) AS ArcWeightReserveMan
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|";
	CommunicationRequest.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, CommunicationRequest.Text);
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightReserveLocal", "ProvisionForImpairmentLocal");
	SLEFieldStructure.Insert("ArcWeightReserveMan",  "ProvisionForImpairmentMan");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromQueries(
		CalculationParameters,
		RequestNodes,
		"NodeNumber",
		CommunicationRequest,
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	// description of systems
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ProvisionForImpairmentLocal";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightReserveLocal";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ProvisionForImpairmentMan";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightReserveMan";
	
	// Decision
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ProvisionForImpairmentLocal, ProvisionForImpairmentMan",
		,
		"DecisionTable_Reserves");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	Query = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(DecisionTable.ProvisionForImpairmentLocal, 0) END AS NUMBER(28,10)) AS ProvisionForImpairmentLocal,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(DecisionTable.ProvisionForImpairmentMan, 0) END AS NUMBER(28,10)) AS ProvisionForImpairmentMan
	|
	|INTO TTTable1_ProvisionsForImpairmentOfInventoriesOfOrganizations
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN DecisionTable_Reserves AS DecisionTable
	|	ON DecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|DROP DecisionTable_Reserves 
	|";
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
EndProcedure

// Performs the calculation of systems of equations for the parameters:
//	Postmanipulation, Postmanipulation, Postmanipulation, Postmanipulation
//		
// The result of this procedure will be temporary tables:
// - "Stabilizersare_Prime cost of the enterprise"
//
Procedure SolveCases_ItemByItemExpensesOfEnterprise(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCases_ItemByItemExpensesOfEnterprise");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho chi phí từng khoản của doanh nghiệp';
									|ru = 'Решение для постатейных расходов предприятия';
									|en = 'Solution for the enterprise itemized expenses'; fa = 'Solution for the enterprise itemized expenses';
									|it = 'Soluzione per le spese dettagliate dello stabilimento';
									|pl = 'Rozwiązanie dla rozchodów wg pozycji przedsiębiorstwa';
									|tr = 'İşletmenin kalemlere ayrılmış giderleri için çözüm'", Common.DefaultLanguageCode());
	
	#Region Nodes
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
	// Item-by-item expenses of the enterprise with VAT
	|	AdjustmentNodes.ItemizedFixedCostsIncludingVAT   AS ItemizedFixedCostsIncludingVAT,
	|	AdjustmentNodes.ItemizedVariableCostsIncludingVAT   AS ItemizedVariableCostsIncludingVAT,
	// Item-by-item expenses of the enterprise without VAT
	|	AdjustmentNodes.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	AdjustmentNodes.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT
	|FROM
	|	SLENodes_ItemByItemExpensesOfEnterprise AS AdjustmentNodes
	|";
	
	#EndRegion
	
	#Region Links
	                                          
	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	Links.SourceNodeNumber,
	|	Links.ReceiverNodeNumber,
	|	Links.ArcWeightWithVAT,
	|	Links.ArcWeightWithoutVAT
	|FROM
	|	SLEConnections_ItemByItemExpensesOfEnterprise AS Links
	|";
	CommunicationRequest.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, CommunicationRequest.Text);
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightWithVAT", "ItemizedFixedCostsIncludingVAT, ItemizedVariableCostsIncludingVAT");
	SLEFieldStructure.Insert("ArcWeightWithoutVAT", "ItemizedFixedCostsExcludingVAT, ItemizedVariableCostsExcludingVAT");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"SLENodes_ItemByItemExpensesOfEnterprise",
		"NodeNumber",
		"SLEConnections_ItemByItemExpensesOfEnterprise",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_CostOfEnterprise_Itemized.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "RelationDataSource_CostOfEnterprise_Itemized.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SLESolution_WithVAT
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsIncludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithVAT";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsIncludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_ItemByItemExpensesOfEnterprise");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_ItemByItemExpensesOfEnterprise");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsIncludingVAT", "ItemizedVariableCostsIncludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightWithVAT", "ArcWeightWithVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsIncludingVAT, ItemizedVariableCostsIncludingVAT",,"WithVATDecisionTable");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (gồm thuế GTGT)';
										|ru = ' (с НДС)';
										|en = ' (including VAT)'; fa = ' (including VAT)';
										|it = ' (con IVA)';
										|pl = ' (brutto)';
										|tr = ' (KDV dahil)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SLESolution_WithoutVAT
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithoutVAT";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsExcludingVAT";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightWithoutVAT";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_ItemByItemExpensesOfEnterprise");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_ItemByItemExpensesOfEnterprise");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsExcludingVAT", "ItemizedVariableCostsExcludingVAT"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightWithoutVAT", "ArcWeightWithoutVAT"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsExcludingVAT, ItemizedVariableCostsExcludingVAT",,"TableOfSolutionsWithoutVAT");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (không gồm thuế GTGT)';
										|ru = ' (без НДС)';
										|en = ' (VAT exclusive)'; fa = ' (VAT exclusive)';
										|it = ' (IVA esclusa)';
										|pl = ' (netto)';
										|tr = ' (KDV hariç)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#Region TTTableOfSolutions_CostOfEnterprise
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_CostOfEnterprise_ItemByItem");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfEnterprise");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_CostOfEnterprise_ItemByItem(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters,
		"SLENodes_ItemByItemExpensesOfEnterprise, SLEConnections_ItemByItemExpensesOfEnterprise,
		|WithVATDecisionTable, TableOfSolutionsWithoutVAT");

EndProcedure

Function QueryTextTTTableOfSolutions_CostOfEnterprise_ItemByItem(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedFixedCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedVariableCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedFixedCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsExcludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedVariableCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsExcludingVAT
	|
	|INTO TTTableOfSolutions_CostOfEnterprise
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN WithVATDecisionTable AS WithVATDecisionTable
	|	ON WithVATDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsWithoutVAT AS TableOfSolutionsWithoutVAT
	|	ON TableOfSolutionsWithoutVAT.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticle = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedFixedCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticle = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedVariableCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedFixedCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsExcludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedVariableCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsExcludingVAT
	|FROM
	|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
	|
	|	LEFT JOIN WithVATDecisionTable AS WithVATDecisionTable
	|	ON WithVATDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsWithoutVAT AS TableOfSolutionsWithoutVAT
	|	ON TableOfSolutionsWithoutVAT.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithVAT = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedFixedCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithVAT = 0
	|			THEN 0
	|		ELSE ISNULL(WithVATDecisionTable.ItemizedVariableCostsIncludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsIncludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedFixedCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsExcludingVAT,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightWithoutVAT = 0
	|			THEN 0
	|		ELSE ISNULL(TableOfSolutionsWithoutVAT.ItemizedVariableCostsExcludingVAT, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsExcludingVAT
	|FROM
	|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN WithVATDecisionTable AS WithVATDecisionTable
	|	ON WithVATDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutionsWithoutVAT AS TableOfSolutionsWithoutVAT
	|	ON TableOfSolutionsWithoutVAT.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs the calculation of systems of equations for the parameters:
//	Postmanufacturing, Postmanipulation, Postmanipulation, Postmanipulation
//		
// The result of this procedure will be temporary tables:
// - "Stabilizersare_Cost of organizationsorganizations"
//
Procedure SolveCases_ItemByItemExpensesOfOrganizations(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCases_ItemByItemExpensesOfOrganizations");
	
	ExplanationForMeasurement = NStr("vi = 'Giải pháp cho chi phí từng khoản của doanh nghiệp';
									|ru = 'Решение для постатейных расходов организаций';
									|en = 'Solution for the company itemized expenses'; fa = 'Solution for the company itemized expenses';
									|it = 'Soluzione per le spese dettagliate delle aziende';
									|pl = 'Rozwiązanie dla rozchodów wg pozycji firm';
									|tr = 'İş yerinin kalemlere ayrılmış giderleri için çözüm'", Common.DefaultLanguageCode());
	
	#Region Nodes
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
	// Item-by-item expenses of organizations (regulated accounting)
	|	AdjustmentNodes.ItemizedFixedCostsCompl   AS ItemizedFixedCostsCompl,
	|	AdjustmentNodes.ItemizedVariableCostsCompl   AS ItemizedVariableCostsCompl,
	// Item-by-item expenses of organizations (management accounting)
	|	AdjustmentNodes.ItemizedFixedCostsManag    AS ItemizedFixedCostsManag,
	|	AdjustmentNodes.ItemizedVariableCostsManag    AS ItemizedVariableCostsManag
	|FROM
	|	SLENodes_ItemByItemExpensesOfOrganizations AS AdjustmentNodes
	|";
	
	#EndRegion
	
	// Connections must comply with the procedure to solve the platform_reservation_references() #Communication Area
	#Region Links

	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	Links.SourceNodeNumber,
	|	Links.ReceiverNodeNumber,
	|	Links.ArcWeightLocal,
	|	Links.ArcWeightMan
	|FROM
	|	SLEConnections_ItemByItemExpensesOfOrganizations AS Links
	|";
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightLocal", "ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	SLEFieldStructure.Insert("ArcWeightMan", "ItemizedFixedCostsManag, ItemizedVariableCostsManag");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"SLENodes_ItemByItemExpensesOfOrganizations",
		"NodeNumber",
		"SLEConnections_ItemByItemExpensesOfOrganizations",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_CostOfOrganization_ItemByItem.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "SourceOfDataLinks_CostOfOrganization_ItemByItem.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SolutionSLU_Local
	
	// description of systems 
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsCompl";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsCompl";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_ItemByItemExpensesOfOrganizations");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_ItemByItemExpensesOfOrganizations");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsCompl", "ItemizedVariableCostsCompl"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocal", "ArcWeightLocal"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// loading the solution into a temporary table
	
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsCompl, ItemizedVariableCostsCompl",
		,
		"TableOfSolutions_CostOfLocalOrganizations");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_Man
	
	// resetting the parameters of the previous calculation
	
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// description of systems
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsManag";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsManag";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_ItemByItemExpensesOfOrganizations");
	CalculationParameters.Insert("RelationshipTableName", "SLEConnections_ItemByItemExpensesOfOrganizations");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsManag", "ItemizedVariableCostsManag"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightMan", "ArcWeightMan"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// loading the solution into a temporary table
	
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsManag, ItemizedVariableCostsManag",
		,
		"TableOfSolutions_CostOfManOrganizations");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement);
	
	DecisionTable.Clear();
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion
	
	#Region TTTableOfSolutions_CostOfOrganizations
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_CostOfOrganizations_ItemByItem");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfOrganizations");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		QueryTextTTTableOfSolutions_CostOfOrganizations_ItemByItem(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"TableOfSolutions_CostOfLocalOrganizations, TableOfSolutions_CostOfManOrganizations");

EndProcedure

Function QueryTextTTTableOfSolutions_CostOfOrganizations_ItemByItem(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|
	|INTO TTTableOfSolutions_CostOfOrganizations
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN TableOfSolutions_CostOfLocalOrganizations AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutions_CostOfManOrganizations AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleMan = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleMan = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|FROM
	|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
	|
	|	LEFT JOIN TableOfSolutions_CostOfLocalOrganizations AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutions_CostOfManOrganizations AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.LocalWeight = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.LocalWeight = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.ManSWeight = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.ManSWeight = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|FROM
	|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN TableOfSolutions_CostOfLocalOrganizations AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN TableOfSolutions_CostOfManOrganizations AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return TrimAll(QueryText);
	
EndFunction

// Performs an adjustment of upcoming expenses by the amount of reserves for indicators:
//		Item-by-item Permanent, item-by-item variable, 
//		Item-by-item Permanent CPR, item-by-item Variable CPR,
//		Temporary difference (for the amount of the reserve in tax accounting).
//
Procedure SolveCase__ReservesOfUpcomingExpenses(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "SolveCase__ReservesOfUpcomingExpenses");
	
	ExplanationForMeasurement = NStr("vi = 'Dự phòng phải trả';
									|ru = 'Резервы предстоящих расходов';
									|en = 'Provisions and contingent liabilities'; fa = 'ذخایر و بدهی‌های احتمالی';
									|it = 'Riserve di spese imminenti';
									|pl = 'Rezerwy przyszłych wydatków';
									|tr = 'Karşılıklar ve şarta bağlı yükümlülükler'", Common.DefaultLanguageCode());
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT TOP 1
	|	DD.NodeNumber
	|INTO ThereAreReservesForNodes
	|FROM
	|	DetailedReservesByNode AS DD
	|";
	
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	// If the table of detailereservers is empty, then there is no point in counting reserves
	NumberOfRowsReservesByNodes = 
			CostCalculationAppliedAlgorithms.TemporaryTableSize(CalculationParameters.TempTablesManager, "ThereAreReservesForNodes");
			
	If NumberOfRowsReservesByNodes = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	#Region Nodes_TakingIntoAccountReserves
	
	RequestNodes = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(RequestNodes, CalculationParameters);
	
	RequestNodes.Text = "
	|SELECT
	|	AdjustmentNodes.NodeNumber                   AS NodeNumber,
	// Item-by-item expenses of organizations (regulated accounting)
	|	AdjustmentNodes.ItemizedFixedCostsCompl   AS ItemizedFixedCostsCompl,
	|	AdjustmentNodes.ItemizedVariableCostsCompl   AS ItemizedVariableCostsCompl,
	// Item-by-item expenses of organizations (management accounting)
	|	AdjustmentNodes.ItemizedFixedCostsManag    AS ItemizedFixedCostsManag,
	|	AdjustmentNodes.ItemizedVariableCostsManag    AS ItemizedVariableCostsManag
	|FROM
	|	SLENodes_FutureExpenseCommitments AS AdjustmentNodes
	|";
	
	#EndRegion
	
	// Links must comply with the procedure to solve the platform_Item-by-Item expenses of Organizations() #Communication Area
	#Region Links
	                                          
	CommunicationRequest = New Query();
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(CommunicationRequest, CalculationParameters);
	
	CommunicationRequest.Text = "
	|SELECT
	|	Links.SourceNodeNumber,
	|	Links.ReceiverNodeNumber,
	|	Links.ArcWeightLocal,
	|	Links.ArcWeightMan
	|FROM
	|	SLEJoin_FutureExpenseCommitments AS Links
	|";
	CommunicationRequest.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, CommunicationRequest.Text);
	
	#EndRegion
	
	#Region SolvingSLUCommonPart
	
	// adjusting the cost of nodes with zero weight
	SLEFieldStructure = New Structure;
	SLEFieldStructure.Insert("ArcWeightLocal", "ItemizedFixedCostsCompl, ItemizedVariableCostsCompl");
	SLEFieldStructure.Insert("ArcWeightMan", "ItemizedFixedCostsManag, ItemizedVariableCostsManag");
	
	CostCalculationAppliedAlgorithms.AdjustCostOfNodesSLEFromTemporaryTables(
		CalculationParameters,
		"SLENodes_FutureExpenseCommitments",
		"NodeNumber",
		"SLEJoin_FutureExpenseCommitments",
		"SourceNodeNumber, ReceiverNodeNumber",
		SLEFieldStructure,
		ExplanationForMeasurement);
	
	// data sources
	MatrixOfNodes  = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, RequestNodes,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'nút';
																																													|ru = 'узлы';
																																													|en = 'nodes'; fa = 'nodes';
																																													|it = 'nodi';
																																													|pl = 'węzły';
																																													|tr = 'üniteler'", Common.DefaultLanguageCode()));
	RelationshipMatrix = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, CommunicationRequest,,, True, ExplanationForMeasurement + ", " + NStr("vi = 'liên kết';
																																																|ru = 'связи';
																																																|en = 'links'; fa = 'links';
																																																|it = 'collegamenti';
																																																|pl = 'powiązania';
																																																|tr = 'bağlantılar'", Common.DefaultLanguageCode()));
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
 	If UploadFormat = "txt" And ValueIsFilled(DirectoryName) Then  
		
		DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
			
		NodeTable_ = MatrixOfNodes.Unload();
		FileName = DirectoryName + "NodeDataSource_FutureExpenseCommitments.txt";
		ValueToFile(FileName, NodeTable_);
			
		LinkTable = RelationshipMatrix.Unload();
		FileName = DirectoryName + "RelationDataSource_FutureExpenseCommitments.txt";
		ValueToFile(FileName, LinkTable);
		
	EndIf;
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SolveSystemOfLinearEquations", ExplanationForMeasurement);
	SystemOfLinearEquationsCalculation = GetComponentToSolveSLU(CalculationParameters);
	
	SystemOfLinearEquationsCalculation.NodeDataSource = MatrixOfNodes;
	SystemOfLinearEquationsCalculation.RelationDataSource = RelationshipMatrix;
	
	// description of key columns
	SystemOfLinearEquationsCalculation.EquationsInNodesColumn = "NodeNumber";
	SystemOfLinearEquationsCalculation.EquationsInRelationsColumn = "ReceiverNodeNumber";
	SystemOfLinearEquationsCalculation.VariablesInRelationsColumn = "SourceNodeNumber";
	
	#EndRegion
	
	#Region SolutionSLU_Local
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsCompl";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsCompl";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightLocal";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_FutureExpenseCommitments");
	CalculationParameters.Insert("RelationshipTableName", "SLEJoin_FutureExpenseCommitments");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsCompl", "ItemizedVariableCostsCompl"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightLocal", "ArcWeightLocal"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading the solution into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsCompl, ItemizedVariableCostsCompl",,"LocalDecisionTable");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (các chỉ tiêu tài chính)';
										|ru = ' (регл. показатели)';
										|en = ' (local indicators)'; fa = ' (local indicators)';
										|it = ' (indicatori reg.)';
										|pl = ' (wskaźniki regl.)';
										|tr = ' (yerel muhasebe göstergeleri)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();
	
	#EndRegion
	
	#Region SolutionSLU_Man
	
	// reset for the next set of descriptions
	SystemOfLinearEquationsCalculation.SystemsDescription.Clear();
	
	// a set of system descriptions
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedFixedCostsManag";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	SystemDetails = SystemOfLinearEquationsCalculation.SystemsDescription.Add();
	SystemDetails.FactorsInNodesColumn = "ItemizedVariableCostsManag";
	SystemDetails.FactorsInRelationsColumn = "ArcWeightMan";
	
	// Decision
	
	CalculationParameters.Insert("NodeTableName", "SLENodes_FutureExpenseCommitments");
	CalculationParameters.Insert("RelationshipTableName", "SLEJoin_FutureExpenseCommitments");
	CalculationParameters.Insert("CostColumnNames", 
		New Structure("Cost1, Cost2", "ItemizedFixedCostsManag", "ItemizedVariableCostsManag"));
	CalculationParameters.Insert("NamesOfBalanceColumns",
		New Structure("ArcWeight1, ArcWeight2", "ArcWeightMan", "ArcWeightMan"));
	CalculationParameters.Insert("IterativeCalculationSLE", True);
	
	DecisionTable = CostCalculationAppliedAlgorithms.SolveSystemOfLinearEquations(CalculationParameters, SystemOfLinearEquationsCalculation);
	
	// Loading solutions into a temporary table.
	SLULoadingParameters = CostCalculationAppliedAlgorithms.InitializeParametersForLoadingSLUSolution(
		"ItemizedFixedCostsManag, ItemizedVariableCostsManag",,"ManSDecisionTable");
	
	CostCalculationAppliedAlgorithms.LoadSLUSolutionIntoTemporaryTable(
		CalculationParameters,
		SLULoadingParameters,
		DecisionTable,
		ExplanationForMeasurement + NStr("vi = ' (các chỉ tiêu quản trị)';
										|ru = ' (упр. показатели)';
										|en = ' (mgmt indicators)'; fa = ' (mgmt indicators)';
										|it = ' (indicatori gest.)';
										|pl = ' (wskaźniki zarz.)';
										|tr = ' (yönetim muhasebesi göstergeleri)'", Common.DefaultLanguageCode()));
	
	DecisionTable.Clear();

	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
	#EndRegion

	#Region TTTableOfSolutions_CostOfOrganizations
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "TTTableOfSolutions_CostOfOrganizations");
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "TTTableOfSolutions_CostOfOrganizationsWithReserves");

	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTTableOfSolutions_CostOfOrganizations");
	
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		TextTTTableOfSolutions_CostOfOrganizationsWithReserves(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
	#EndRegion
	
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"SLENodes_FutureExpenseCommitments, SLEJoin_FutureExpenseCommitments, TableOfSolutions_SumTA");
	
EndProcedure

Function TextTTTableOfSolutions_CostOfOrganizationsWithReserves(CalculationParameters)
	
	QueryText = "
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.Count = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|
	|INTO TTTableOfSolutions_CostOfOrganizations
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN LocalDecisionTable AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManSDecisionTable AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleLocal = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleMan = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.WeightArticleByArticleMan = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|FROM
	|	TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
	|
	|	LEFT JOIN LocalDecisionTable AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManSDecisionTable AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentNodes.NodeNumber AS NodeNumber,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.LocalWeight = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedFixedCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.LocalWeight = 0
	|			THEN 0
	|		ELSE ISNULL(LocalDecisionTable.ItemizedVariableCostsCompl, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsCompl,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.ManSWeight = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedFixedCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedFixedCostsManag,
	|	CAST(CASE
	|		WHEN AdjustmentNodes.ManSWeight = 0
	|			THEN 0
	|		ELSE ISNULL(ManSDecisionTable.ItemizedVariableCostsManag, 0) END AS NUMBER(28,10)) AS ItemizedVariableCostsManag
	|FROM
	|	AdditionalCostAdjustmentNodes AS AdjustmentNodes
	|
	|	LEFT JOIN LocalDecisionTable AS LocalDecisionTable
	|	ON LocalDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|	LEFT JOIN ManSDecisionTable AS ManSDecisionTable
	|	ON ManSDecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
	|
	|INDEX BY
	|	NodeNumber
	|";
	
	Return TrimAll(QueryText);
	
EndFunction


Procedure SaveSLU(CalculationParameters)
	
	CostCalculationProtocol.StartOfCodeSnippetExecution(CalculationParameters, "SaveSLU", "");
		
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	ISNULL(MAX(T.NodeNumber), -1) + 1 AS NodeNumber
	|FROM
	|	TTCostAdjustmentUnits AS T
	|WHERE
	|	T.Organization IN (&OrganizationsIncludingVATLotsVersion24)";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	FirstNodeNumber = Selection.NodeNumber;
	
	Query.SetParameter("FirstNodeNumber", FirstNodeNumber);
	
	Query.Text =
	"SELECT
	|	AdjustmentNodes.NodeNumber + &FirstNodeNumber 	AS NodeNumber,
	|	AdjustmentNodes.Organization                	AS Organization,
	|	AdjustmentNodes.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	AdjustmentNodes.AccountingSection                	AS AccountingSection,
	|	AdjustmentNodes.InventoryOwnerAttribute                 	AS InventoryOwnerAttribute,
	|	AdjustmentNodes.Lot					 	AS Lot,
	|	AdjustmentNodes.LotVendorAttributes		 	AS LotVendorAttributes,
	|	AdjustmentNodes.FinancialAccountingDimension	 	AS FinancialAccountingDimension,
	|	AdjustmentNodes.VATActivityType		 	AS VATActivityType,
	|
	|	AdjustmentNodes.Count          		 	AS Weight
	|INTO TTCurNodes
	|FROM
	|	TTAdjustmentNodes AS AdjustmentNodes
	|WHERE
	|	AdjustmentNodes.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	WriteOffMovements.SourceNodeNumber + &FirstNodeNumber AS SourceNodeNumber,
	|	WriteOffMovements.ReceiverNodeNumber + &FirstNodeNumber AS ReceiverNodeNumber,
	|	WriteOffMovements.DoNotMoveNetInitialCostLOCAL			 AS DoNotMoveNetInitialCostLOCAL,
	|	WriteOffMovements.ArcWeight                              AS Weight
	|INTO TTCurConnections
	|FROM
	|	TTWriteOffs AS WriteOffMovements
	|	INNER JOIN TTAdjustmentNodes AS NodesSource
	|		ON NodesSource.NodeNumber = WriteOffMovements.SourceNodeNumber
	|	LEFT JOIN TTAdjustmentNodes AS ReceiverNodes
	|		ON ReceiverNodes.NodeNumber = WriteOffMovements.ReceiverNodeNumber
	|WHERE
	|	NOT WriteOffMovements.TransferToAnotherOrganization
	|	AND NodesSource.Organization IN (&OrganizationsIncludingVATLotsVersion24)
	|	AND NOT ISNULL(ReceiverNodes.AccountingSection, UNDEFINED) IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff))
	|	AND NOT (ISNULL(ReceiverNodes.AccountingSection, UNDEFINED) = VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		AND ISNULL(ReceiverNodes.InventoryOwnerAttribute.InventoryType, UNDEFINED) <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider))
	|";
	
	Query.Execute();
	
	CostCalculationAppliedAlgorithms.MergeTemporaryTables(
		CalculationParameters,
		"TTCurNodes",
		"TTCostAdjustmentUnits",
		"NodeNumber, Organization, ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute,
			|Lot, LotVendorAttributes, FinancialAccountingDimension, VATActivityType, Weight",
		"",
		"NodeNumber",
		True);
	
	CostCalculationAppliedAlgorithms.MergeTemporaryTables(
		CalculationParameters,
		"TTCurConnections",
		"TTCommunicationNodesCostAdjustment",
		"SourceNodeNumber, ReceiverNodeNumber, DoNotMoveNetInitialCostLOCAL, Weight",
		"",
		"SourceNodeNumber",
		True);
	
	CostCalculationProtocol.EndOfCodeSnippetExecution(CalculationParameters);
	
EndProcedure
//
// Saves temporary tables that are used for solving SLS to files on disk.
//
Procedure SaveSLUVFile(CalculationParameters, LocalCostCalculation = False)
	
	DirectoryName = TrimAll(CalculationParameters.UploadingCalculationData.DirectoryForSavingSLUData);
	
	If Not ValueIsFilled(DirectoryName) Then
		Return; // unloading of the SLU is not required
	EndIf;
	
	Try
		ErrorText = "";
		CreateDirectory(DirectoryName);
	Except
		ErrorText = BriefErrorDescription(ErrorInfo());
	EndTry;
	
	DirectoryName = CommonClientServer.AddLastPathSeparator(DirectoryName);
	Directory     = New File(DirectoryName);
	
	If Not Directory.Exists() Or Not Directory.IsDirectory() Then
		
		ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tìm thấy thư mục để lưu lại dữ liệu hệ phương trình tuyến tính: ""%1""
				|%2';
				|ru = 'Не найден каталог для сохранения данных СЛУ: ""%1""
				|%2';
				|en = 'Directory for saving LES data is not found: ""%1""
				|%2'; fa = 'Directory for saving LES data is not found: ""%1""
				|%2';
				|it = 'Non è stata trovata una directory per il salvataggio dei dati del sistema lineare: ""%1""
				|%2';
				|pl = 'Nie znaleziono katalogu do zapisu danych URL: ""%1""
				|%2';
				|tr = 'DDS verilerini kaydetmek için klasör bulunamadı: ""%1""
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.ValuePresentation(DirectoryName),
			ErrorText);
		
		CostCalculationProtocol.FixCalculationError(
			CalculationParameters,
			Enums.TypesOfLotAccountingAndCostErrors.RunTimeError,
			ProtocolText_);
		
		Return; // the upload directory was not found
		
	EndIf;
	
	UploadFormat = TrimAll(Lower(CalculationParameters.UploadingCalculationData.FormatForSavingSLUData));
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	If UploadFormat = "mxl" Then
		
		// Vtuzlykorrections and vttablitsaresults are uploaded to one file. "..Nodes".
		//	- we will assign the prefixes "Node" and "Solution" to the columns of the same name in these tables, respectively
		// After the translation of the description, we upload it to the file "...Arcs".
		
		FileNameTemplate =
			Format(CurrentSessionDate() - Date(1,1,1), "ND=12; NLZ=; NG=")      // date-time of unloading
			+ "_" + ?(CalculationParameters.PreliminaryCalculation, "Preliminary", "Actual") // what kind of calculation
			+ "_" + ?(LocalCostCalculation, "Compl", "Man")					   // what is the cost price we calculate
			+ "_%1.mxl";													   // which temporary table are we unloading
		
		// Get data from temporary tables
		Query.Text =
		"SELECT
		|	AdjustmentNodes.NodeNumber					 	AS NodeNumber,
		|	AdjustmentNodes.Organization                	AS Organization,
		|	AdjustmentNodes.ItemsLocationAttributes 	AS ItemsLocationAttributes,
		|	AdjustmentNodes.AccountingSection                	AS AccountingSection,
		|	AdjustmentNodes.InventoryOwnerAttribute                 	AS InventoryOwnerAttribute,
		|	AdjustmentNodes.Lot					 	AS Lot,
		|	AdjustmentNodes.LotVendorAttributes		 	AS LotVendorAttributes,
		|	AdjustmentNodes.FinancialAccountingDimension	 	AS FinancialAccountingDimension,
		|	AdjustmentNodes.VATActivityType		 	AS VATActivityType,
		|
		|	AdjustmentNodes.Count          		 	AS Count,
		|	AdjustmentNodes.Cost                     AS NodeCost,
		|	AdjustmentNodes.CostExcludingVAT               AS NodeCostWithoutVAT,
		|	AdjustmentNodes.LaborCosts                  AS LaborCostsGraph_1,
		|	AdjustmentNodes.OffBalanceCost 		AS NodeCostOffBalanceSheet,
		|
		|	CostOfEnterprise.Cost              AS SolutionCost,
		|	CostOfEnterprise.CostExcludingVAT        AS SolutionCostWithoutVAT,
		|	CostOfEnterprise.LaborCosts           AS SolvingLaborCosts,
		|	CostOfEnterprise.OffBalanceCost 	AS SolutionOffBalanceSheetCost
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|	LEFT JOIN TTTableOfSolutions_CostOfEnterprise AS CostOfEnterprise
		|		ON CostOfEnterprise.NodeNumber = AdjustmentNodes.NodeNumber
		|
		|ORDER BY
		|	NodeNumber
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	WriteOffMovements.SourceNodeNumber 		     AS SourceNodeNumber,
		|	WriteOffMovements.ReceiverNodeNumber 		     AS ReceiverNodeNumber,
		|	WriteOffMovements.TransferToAnotherOrganization AS TransferToAnotherOrganization,
		|	WriteOffMovements.ArcWeight                      AS ArcWeight,
		|	WriteOffMovements.DoNotMoveOffBalanceSheetValue            AS DoNotMoveOffBalanceSheetValue,
		|	WriteOffMovements.DoNotMoveBookValue		     AS DoNotMoveBookValue
		|FROM
		|	TTWriteOffs AS WriteOffMovements
		|
		|ORDER BY
		|	ReceiverNodeNumber,
		|	SourceNodeNumber
		|";
		
		QueryResult = Query.ExecuteBatch();
		
		// Save the first file
		ProtocolText_ = TMCommonUse.SaveTableOfValuesToFile(
			QueryResult[0].Unload(),
			DirectoryName + StringFunctionsClientServer.SubstituteParametersToString(FileNameTemplate, "Nodes"));
		
		If ValueIsFilled(ProtocolText_) Then  // file writing error
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.RunTimeError,
				ProtocolText_);
			
		EndIf;
		
		// Save the second file
		ProtocolText_ = TMCommonUse.SaveTableOfValuesToFile(
			QueryResult[1].Unload(),
			DirectoryName + StringFunctionsClientServer.SubstituteParametersToString(FileNameTemplate, "Arcs"));
		
		If ValueIsFilled(ProtocolText_) Then
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.RunTimeError,
				ProtocolText_);
			
		EndIf;
		
	ElsIf UploadFormat = "csv" Then
		// VtUzlyKorrectirovki - free members
		// In the displacement of the description - coefficients; Source number - equation number, Receiver number - element number
		//
		// CASE of n unknowns:
		// A(1,1)*X1 + A(1,2)*X2 + ... A(1,n)*Xn = B1
		// A(2,1)*X1 + A(2,2)*X2 + ... A(2,n)*Xn =B2
		// ...
		// A(n,1)*X1 + A(n,2)*X2 + ... A(n,n)*Xn = Bn
		//
		// CSV file string format:
		// <Free coefficient B>[,(<Unknown number X>, <Coefficient A>)]
		// There must be a line for each equation, with the sequence number of the line = the equation number
		
		SLUFile = New TextDocument;
		
		FileNameTemplate =
			Format(CurrentSessionDate() - Date(1,1,1), "ND=12; NLZ=; NG=")      // date-time of unloading
			+ "_" + ?(CalculationParameters.PreliminaryCalculation, "Prev_", "Real") // what kind of calculation
			+ "_" + ?(LocalCostCalculation, "Compl", "Man")					   // what is the cost price we calculate
			+ "_SLU.csv";													   // which temporary table are we unloading
		
		Query.Text =
		"SELECT
		|	EquationNumbers.NodeNumber AS EquationNumber,
		|	ISNULL(Coefficients.ReceiverNodeNumber, 0) AS UnknownNumber,
		|	CAST(ISNULL(Coefficients.ArcWeight, 0) AS NUMBER(28,10)) AS CoefficientOfUnknown,
		|	CAST(CASE
		|			WHEN EquationNumbers.Count = 0
		|				THEN 0
		|			WHEN ISNULL(Coefficients.DoNotMoveBookValue, FALSE)
		|				THEN 0
		|			ELSE EquationNumbers.Cost
		|		END AS NUMBER(28,10)) AS FreeCoefficient
		|FROM
		|	TTAdjustmentNodes AS EquationNumbers
		|	LEFT JOIN TTWriteOffs AS Coefficients
		|		ON EquationNumbers.NodeNumber = Coefficients.SourceNodeNumber
		|
		|ORDER BY
		|	EquationNumber,
		|	UnknownNumber
		|TOTALS
		|	MIN(FreeCoefficient)
		|BY
		|	EquationNumber";
		
		Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
		
		SamplingEquations = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SamplingEquations.Next() Do
			
			FileString = TrimAll(Format(SamplingEquations.FreeCoefficient, "NDS=.; NZ=0; NG=0"));
			
			SamplingUnknowns = SamplingEquations.Select();
			
			While SamplingUnknowns.Next() Do
				
				If SamplingUnknowns.UnknownNumber = NULL Then
					Break; // there are no non-zero coefficients in this equation
				EndIf;
				
				// <Free coefficient B>[,(<Unknown number X>, <Coefficient A>)]
				FileString = FileString
					+ ",("
					+ TrimAll(Format(SamplingUnknowns.UnknownNumber, "NFD=; NZ=0; NG=0"))
					+ ","
					+ TrimAll(Format(SamplingUnknowns.CoefficientOfUnknown, "NDS=.; NZ=0; NG=0"))
					+ ")";
				
			EndDo;
			
			SLUFile.AddLine(FileString);
			
		EndDo;
		
		Try
			SLUFile.Write(DirectoryName + FileNameTemplate);
		Except
			
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể ghi lại tệp ""%1""
					|%2';
					|ru = 'Не удалось записать файл ""%1""
					|%2';
					|en = 'Cannot save the ""%1"" file
					|%2'; fa = 'Cannot save the ""%1"" file
					|%2';
					|it = 'Non è stato possibile scrivere il file ""%1""
					|%2';
					|pl = 'Nie udało się zapisać plik ""%1""
					|%2';
					|tr = 'Dosya kaydedilmedi ""%1""
					|%2'", Common.DefaultLanguageCode()),
				DirectoryName + FileNameTemplate,
				DetailErrorDescription(ErrorInfo()));
			
			CostCalculationProtocol.FixCalculationError(
				CalculationParameters,
				Enums.TypesOfLotAccountingAndCostErrors.RunTimeError,
				ProtocolText_);
			
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

// Formation of the table of the cost of party products

#Region StageProcedures_RegisterCost

Procedure UpdateCostOfBatchesOfGoods_MaterialAndLaborCosts(CalculationParameters)

	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "UpdateCostOfBatchesOfGoods_MaterialAndLaborCosts");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
		|SELECT
		|	UNDEFINED                                 AS DocumentRegisterRecords,
		|	&BeginOfPeriod                               AS Period,
		|	CostOfBatchesOfGoods.NodeNumber                  AS NodeNumber,
		// Dimensions
		|	CostOfBatchesOfGoods.Organization                AS Organization,
		|	CostOfBatchesOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CostOfBatchesOfGoods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	CostOfBatchesOfGoods.AccountingSection                AS AccountingSection,
		|	CostOfBatchesOfGoods.Lot                     AS Lot,
		|	CostOfBatchesOfGoods.LotVendorAttributes       AS LotVendorAttributes,
		|	CostOfBatchesOfGoods.FinancialAccountingDimension  AS FinancialAccountingDimension,
		|	CostOfBatchesOfGoods.VATActivityType         AS VATActivityType,
		// Resources
		|	CAST(ISNULL(CostOfEnterprise.Cost, 0) AS NUMBER(28,10))                 AS Cost,
		|	CAST(ISNULL(CostOfEnterprise.CostExcludingVAT, 0) AS NUMBER(28,10))           AS CostExcludingVAT,
		|	CAST(ISNULL(CostOfEnterprise.OffBalanceCost, 0) AS NUMBER(28,10))     AS OffBalanceCost,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AdditionalExpenseCost,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AdditionalExpensesCostExcludingVAT,
		|	CAST(ISNULL(CostOfEnterprise.LaborCosts, 0) AS NUMBER(28,10))              AS LaborCosts,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsIncludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsExcludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsIncludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsExcludingVAT,
		|
		|	CAST(ISNULL(CostOfOrganizations.LocalCost, 0) AS NUMBER(28,10))             AS LocalCost,
		|	CAST(ISNULL(CostOfOrganizations.OffBalanceCostLocal, 0) AS NUMBER(28,10)) AS OffBalanceCostLocal,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AddExpensesLocal,
		|	CAST(ISNULL(CostOfOrganizations.LaborCostsLocal, 0) AS NUMBER(28,10))          AS LaborCostsLocal,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsCompl,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsCompl,
		|	CAST(ISNULL(CostOfOrganizations.LocalCost, 0) AS NUMBER(28,10))             AS CostInTaxAccounting,
		|	CAST(0 AS NUMBER (28,10))                                                              AS PermanentDifference,
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostTD,
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostOfPersonalIncomeTax,
		|	CostOfBatchesOfGoods.ProvisionForImpairmentLocal                                            AS ProvisionForImpairmentLocal,
		|
		|	CAST(ISNULL(CostOfOrganizations.CostMan, 0) AS NUMBER(28,10))              AS CostMan,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AddExpensesMan,
		|	CAST(ISNULL(CostOfOrganizations.LaborCostsMan, 0) AS NUMBER(28,10))           AS LaborCostsMan,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsManag,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsManag,
		|	CostOfBatchesOfGoods.ProvisionForImpairmentMan                                             AS ProvisionForImpairmentMan
		|
		|INTO CostOfBatchesOfGoodsPreliminary
		|FROM
		|	TTValueOfBatchesOfGoods AS CostOfBatchesOfGoods
		|	LEFT JOIN TTTableOfSolutions_CostOfEnterprise AS CostOfEnterprise
		|		ON CostOfEnterprise.NodeNumber = CostOfBatchesOfGoods.NodeNumber
		|	LEFT JOIN TTTableOfSolutions_CostOfOrganizations AS CostOfOrganizations
		|		ON CostOfOrganizations.NodeNumber = CostOfBatchesOfGoods.NodeNumber
		|;
		|/////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	*
		|INTO TTValueOfBatchesOfGoods
		|FROM
		|	CostOfBatchesOfGoodsPreliminary AS CostOfBatchesOfGoods
		// The indexation corresponds to the table of the cash settlement turnover and the cost of goods
		// Calculation of the cost of the individual rhythms.Create a description of the Register() #Index area of the Register
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|;
		|";
	
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"CostOfBatchesOfGoodsPreliminary");
		
	// Let's add information about nodes with zero weights and non-zero sums to the protocol
	If CalculationParameters.Property("NodesWithZeroWeights") Then
		NodesWithZeroWeights = CalculationParameters.NodesWithZeroWeights;
	Else
		NodesWithZeroWeights = New Array;
	EndIf;
	Query.SetParameter("IncorrectNodes", NodesWithZeroWeights);
	
	Query.Text =
	"SELECT DISTINCT
	|	T.Organization AS Organization,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.Lot AS Lot,
	|	T.VATActivityType AS VATActivityType
	|FROM
	|	TTValueOfBatchesOfGoods AS T
	|WHERE
	|	T.NodeNumber IN (&IncorrectNodes)
	|
	|ORDER BY
	|	Organization,
	|	ItemsLocationAttributes,
	|	Lot,
	|	VATActivityType
	|";
	
	ProtocolString = "";
	
	If ValueIsFilled(NodesWithZeroWeights) Then
		
		Selection = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True);
		
		While Selection.Next() Do
			
			ProtocolString = ProtocolString + ?(ProtocolString = "", "", Chars.LF)
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Doanh nghiệp: ""%1"", Đối tượng phân tích mặt hàng: ""%2"", Lô hàng: ""%3"", Dạng hoạt động thuế GTGT: ""%4"",';
						|ru = 'Организация: ""%1"", Аналитика номенклатуры: ""%2"", Партия: ""%3"", Вид деятельности НДС: ""%4"",';
						|en = 'Company: ""%1"", Item dimension: ""%2"", Lot: ""%3"", VAT activity type: ""%4"",'; fa = 'Company: ""%1"", Item dimension: ""%2"", Lot: ""%3"", VAT activity type: ""%4"",';
						|it = 'Azienda: ""%1"", Analitica degli articoli: ""%2"", Lotto: ""%3"", Tipo di attività IVA: ""%4"",';
						|pl = 'Firma: ""%1"", Analityka nomenklatury: ""%2"", Partia: ""%3"", Rodzaj działalności VAT: ""%4"",';
						|tr = 'İş yeri: ""%1"", Öğe boyutu: ""%2"", Lot: ""%3"", Faaliyet türü KDV: ""%4"",'"),
					Selection.Organization,
					Selection.ItemsLocationAttributes,
					Selection.Lot,
					Selection.VATActivityType);
					
		EndDo;
		
		If ValueIsFilled(ProtocolString) Then
			
			ProtocolString =
				NStr("vi = 'Giá trị của một số đối tượng phân tích mặt hàng không thể được tính toán khi giải quyết hệ phương trình tuyến tính
					|do một số dữ liệu của hệ phương trình tuyến tính (nút có trọng số bằng 0 nhưng lại có giá trị khác 0).';
					|ru = 'Стоимость некоторых аналитик номенклатуры не может быть рассчитана при решении СЛУ
					|по причине некорректных данных СЛУ (нулевой вес узла и ненулевая стоимость).';
					|en = 'Cannot calculate the cost of some item dimensions when solving LES.
					|Reason: incorrect LES data (zero node weight and non-zero cost).'; fa = 'Cannot calculate the cost of some item dimensions when solving LES.
					|Reason: incorrect LES data (zero node weight and non-zero cost).';
					|it = 'Cannot calculate the cost of some item dimensions when solving LES.
					|Reason: incorrect LES data (zero node weight and non-zero cost).';
					|pl = 'Cannot calculate the cost of some item dimensions when solving LES.
					|Reason: incorrect LES data (zero node weight and non-zero cost).';
					|tr = 'Bazı öğe boyutlarının maliyeti, yanlış DDS verileri (sıfır düğüm ağırlığı olan ve sıfır olmayan maliyet) sebebiyle DDS,
					| çözülürken hesaplanamaz.'")
				+ Chars.LF + ProtocolString;
			
			CostCalculationProtocol.AdditionalInformation(CalculationParameters, ProtocolString);
		
		EndIf;
		
	EndIf;
	
	// Let's add information about nodes with field overflow to the protocol
	
	If Not ValueIsFilled(CalculationParameters.NodesWithFieldOverflow) Then
		Return;
	EndIf;
	
	ProtocolString = "";
	
	Query.SetParameter("IncorrectNodes", CalculationParameters.NodesWithFieldOverflow);
	
	Selection = CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query, True);
	
	While Selection.Next() Do
		
		ProtocolString = ProtocolString + ?(ProtocolString = "", "", Chars.LF)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Doanh nghiệp: ""%1"", Đối tượng phân tích mặt hàng: ""%2"", Lô hàng: ""%3"", Dạng hoạt động thuế GTGT: ""%4"",';
					|ru = 'Организация: ""%1"", Аналитика номенклатуры: ""%2"", Партия: ""%3"", Вид деятельности НДС: ""%4"",';
					|en = 'Company: ""%1"", Item dimension: ""%2"", Lot: ""%3"", VAT activity type: ""%4"",'; fa = 'Company: ""%1"", Item dimension: ""%2"", Lot: ""%3"", VAT activity type: ""%4"",';
					|it = 'Azienda: ""%1"", Analitica degli articoli: ""%2"", Lotto: ""%3"", Tipo di attività IVA: ""%4"",';
					|pl = 'Firma: ""%1"", Analityka nomenklatury: ""%2"", Partia: ""%3"", Rodzaj działalności VAT: ""%4"",';
					|tr = 'İş yeri: ""%1"", Öğe boyutu: ""%2"", Lot: ""%3"", Faaliyet türü KDV: ""%4"",'"),
				Selection.Organization,
				Selection.ItemsLocationAttributes,
				Selection.Lot,
				Selection.VATActivityType);
				
	EndDo;
	
	If Not ValueIsFilled(ProtocolString) Then
		Return;
	EndIf;
	
	ProtocolString =
		NStr("vi = 'Giá trị của một số đối tượng phân tích không thể tính toán bằng cách giải hệ phương trình tuyến tính.
			|Có thể có các lý do: xuất vượt quá nhập và số dư đầu hoặc lặp biến động.';
			|ru = 'Стоимость некоторых аналитик номенклатуры не может быть рассчитана при решении СЛУ.
			|Возможные причины: превышение расходов над приходами и начальными остатками или зацикливание движений.';
			|en = 'The cost of some item dimensions can not be calculated when solving LES.
			|Possible causes: consumption exceeding receipts and beginning inventories or looping records.'; fa = 'The cost of some item dimensions can not be calculated when solving LES.
			|Possible causes: consumption exceeding receipts and beginning inventories or looping records.';
			|it = 'Il costo di alcune analitiche degli articoli non può essere calcolato con il sistema lineare. 
			| Possibili cause: le uscite superano le entrate e i saldi iniziali oppure movimento ciclico.';
			|pl = 'Wartość niektórych analityk nie może być obliczona podczas rozwiązywania URL.
			|Możliwe przyczyny: przekroczenie rozchodów nad dochodami i saldami początkowymi lub zapętlenie ruchów.';
			|tr = 'DDS çözülürken bazı öğe boyutlarının maliyeti hesaplanamaz.
			|Olası nedenler: giderlerin tahsilatlardan ve açılış bakiyelerinden fazla olması veya hareketlerin döngüsel olması.'")
		+ Chars.LF + ProtocolString;
	
	CostCalculationProtocol.AdditionalInformation(CalculationParameters, ProtocolString);
		
EndProcedure

Procedure UpdateCostOfBatchesOfGoods_AdditionalCosts(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "UpdateCostOfBatchesOfGoods_AdditionalCosts");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	UNDEFINED                                     AS DocumentRegisterRecords,
	|	&BeginOfPeriod                                   AS Period,
	|	CostOfBatchesOfGoods.NodeNumber                 AS NodeNumber,
	// Dimensions
	|	CostOfBatchesOfGoods.Organization                AS Organization,
	|	CostOfBatchesOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CostOfBatchesOfGoods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	CostOfBatchesOfGoods.AccountingSection                AS AccountingSection,
	|	CostOfBatchesOfGoods.Lot                     AS Lot,
	|	CostOfBatchesOfGoods.LotVendorAttributes       AS LotVendorAttributes,
	|	CostOfBatchesOfGoods.FinancialAccountingDimension  AS FinancialAccountingDimension,
	|	CostOfBatchesOfGoods.VATActivityType         AS VATActivityType,
	// Resources
	|	CostOfBatchesOfGoods.Cost                                        AS Cost,
	|	CostOfBatchesOfGoods.CostExcludingVAT                                  AS CostExcludingVAT,
	|	CostOfBatchesOfGoods.OffBalanceCost                            AS OffBalanceCost,
	|	CAST(ISNULL(DecisionTable.CostInclVAT, 0) AS NUMBER(28,10))    AS AdditionalExpenseCost,
	|	CAST(ISNULL(DecisionTable.CostExcludingVAT, 0) AS NUMBER(28,10))  AS AdditionalExpensesCostExcludingVAT,
	|	CostOfBatchesOfGoods.LaborCosts                                     AS LaborCosts,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedFixedCostsIncludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedFixedCostsExcludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedVariableCostsIncludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedVariableCostsExcludingVAT,
	|
	|	CostOfBatchesOfGoods.LocalCost                                    AS LocalCost,
	|	CostOfBatchesOfGoods.OffBalanceCostLocal                        AS OffBalanceCostLocal,
	|	CAST(ISNULL(DecisionTable.LocalCost, 0) AS NUMBER(28,10))    AS AddExpensesLocal,
	|	CostOfBatchesOfGoods.LaborCostsLocal                                 AS LaborCostsLocal,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedFixedCostsCompl,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedVariableCostsCompl,
	|	CostOfBatchesOfGoods.LocalCost                                    AS CostInTaxAccounting,
	|	CAST(0 AS NUMBER (28,10))                                           AS PermanentDifference,
	|	CAST(0 AS NUMBER (28,10))                                           AS CostTD,
	|	CAST(0 AS NUMBER (28,10))                                           AS CostOfPersonalIncomeTax,
	|	CostOfBatchesOfGoods.ProvisionForImpairmentLocal                         AS ProvisionForImpairmentLocal,
	|
	|	CostOfBatchesOfGoods.CostMan                                     AS CostMan,
	|	CAST(ISNULL(DecisionTable.CostMan, 0) AS NUMBER(28,10))     AS AddExpensesMan,
	|	CostOfBatchesOfGoods.LaborCostsMan                                  AS LaborCostsMan,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedFixedCostsManag,
	|	CAST(0 AS NUMBER (28,10))                                           AS ItemizedVariableCostsManag,
	|	CostOfBatchesOfGoods.ProvisionForImpairmentMan                          AS ProvisionForImpairmentMan
	|
	|INTO CostOfBatchesOfGoodsPreliminary
	|FROM
	|	TTValueOfBatchesOfGoods AS CostOfBatchesOfGoods
	|	LEFT JOIN DecisionTable AS DecisionTable
	|		ON DecisionTable.NodeNumber = CostOfBatchesOfGoods.NodeNumber
	|;
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO TTValueOfBatchesOfGoods
	|FROM
	|	CostOfBatchesOfGoodsPreliminary AS CostOfBatchesOfGoods
	// The indexation corresponds to the table of the cash settlement turnover and the cost of goods
	// Calculation of the cost of the individual rhythms.Create a description of the Register() #Index area of the Register
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|;
	|";
	
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, 
		"ExpenseAmounts, CostOfBatchesOfGoodsPreliminary");
	
EndProcedure

Procedure RegisterCost_AdditionalCosts(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "RegisterCost_AdditionalCosts");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text =
	"SELECT
	|	Nodes.NodeNumber,
	// Dimensions
	|	Nodes.Organization,
	|	Nodes.Department,
	|	Nodes.LineOfBusiness,
	|	Nodes.ExpenseItem,
	|	Nodes.DimensionOfExpenses,
	// Resources
	|	CAST(ISNULL(DecisionTable.CostInclVAT, 0) AS NUMBER(28,10))    AS CostInclVAT,
	|	CAST(ISNULL(DecisionTable.CostExcludingVAT, 0) AS NUMBER(28,10))  AS CostExcludingVAT,
	|	CAST(ISNULL(DecisionTable.LocalCost, 0) AS NUMBER(28,10))    AS LocalCost,
	|	CAST(ISNULL(DecisionTable.CostMan, 0) AS NUMBER(28,10))     AS CostMan
	|INTO CostOfAdditionalExpenses
	|FROM
	|	AdditionalCostAdjustmentNodes AS Nodes
	|	LEFT JOIN DecisionTable AS DecisionTable
	|		ON DecisionTable.NodeNumber = Nodes.NodeNumber
	|
	|INDEX BY
	|	Organization,
	|	DimensionOfExpenses,
	|	ExpenseItem,
	|	LineOfBusiness,
	|	Department
	|";
	
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
EndProcedure

// Text description of the data for the TT cost of additional expenses.
// 
// Returns:
//  String - Text description of the data for the TT cost of additional expenses.
Function TextDescriptionOfDataForCostOfAdditionalExpenses() Export
	
	QueryText = "SELECT
		|	0 AS NodeNumber,
		// Dimensions
		|	VALUE(Catalog.Companies.EmptyRef)					AS Organization,
		|	VALUE(Catalog.BusinessStructure.EmptyRef)			AS Department,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef)		AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItem,
		|	UNDEFINED													AS DimensionOfExpenses,
		// Resources
		|	CAST(0 AS NUMBER(28,10)) AS CostInclVAT,
		|	CAST(0 AS NUMBER(28,10)) AS CostExcludingVAT,
		|	CAST(0 AS NUMBER(28,10)) AS LocalCost,
		|	CAST(0 AS NUMBER(28,10)) AS CostMan
		|INTO Data
		|"; 
		
		QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);

	Return QueryText;
EndFunction

Procedure UpdateCostOfBatchesOfGoods_InclusionExclusionOfVAT(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "RegisterCost_IncludeExcludeVAT");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = "
	|SELECT
	|	UNDEFINED                                     AS DocumentRegisterRecords,
	|	&BeginOfPeriod                                   AS Period,
	|	CostOfBatchesOfGoods.NodeNumber                 AS NodeNumber,
	// Dimensions
	|	CostOfBatchesOfGoods.Organization                AS Organization,
	|	CostOfBatchesOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CostOfBatchesOfGoods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	CostOfBatchesOfGoods.AccountingSection                AS AccountingSection,
	|	CostOfBatchesOfGoods.Lot                     AS Lot,
	|	CostOfBatchesOfGoods.LotVendorAttributes       AS LotVendorAttributes,
	|	CostOfBatchesOfGoods.FinancialAccountingDimension  AS FinancialAccountingDimension,
	|	CostOfBatchesOfGoods.VATActivityType         AS VATActivityType,
	// Resources
	|	CostOfBatchesOfGoods.Cost                                                  AS Cost,
	|	CostOfBatchesOfGoods.CostExcludingVAT                                            AS CostExcludingVAT,
	|	CostOfBatchesOfGoods.OffBalanceCost                                      AS OffBalanceCost,
	|	CostOfBatchesOfGoods.AdditionalExpenseCost                                        AS AdditionalExpenseCost,
	|	CostOfBatchesOfGoods.AdditionalExpensesCostExcludingVAT                                  AS AdditionalExpensesCostExcludingVAT,
	|	CostOfBatchesOfGoods.LaborCosts                                               AS LaborCosts,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedFixedCostsIncludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedFixedCostsExcludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedVariableCostsIncludingVAT,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedVariableCostsExcludingVAT,
	|
	|	CAST(CostOfBatchesOfGoods.LocalCost
	|		+ ISNULL(CostOfOrganizations.LocalCost, 0) AS NUMBER(28,10))       AS LocalCost,
	|	CostOfBatchesOfGoods.OffBalanceCostLocal                                  AS OffBalanceCostLocal,
	|	CostOfBatchesOfGoods.AddExpensesLocal                                             AS AddExpensesLocal,
	|	CostOfBatchesOfGoods.LaborCostsLocal                                           AS LaborCostsLocal,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedFixedCostsCompl,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedVariableCostsCompl,
	|	CAST(CostOfBatchesOfGoods.LocalCost
	|		+ ISNULL(CostOfOrganizations.LocalCost, 0) AS NUMBER(28,10))       AS CostInTaxAccounting,
	|	CAST(0 AS NUMBER (28,10))                                                     AS PermanentDifference,
	|	CAST(0 AS NUMBER (28,10))                                                     AS CostTD,
	|	CAST(0 AS NUMBER (28,10))                                                     AS CostOfPersonalIncomeTax,
	|	CostOfBatchesOfGoods.ProvisionForImpairmentLocal                                   AS ProvisionForImpairmentLocal,
	|
	|	CAST(CostOfBatchesOfGoods.CostMan
	|		+ ISNULL(CostOfOrganizations.CostMan, 0) AS NUMBER(28,10))        AS CostMan,
	|	CostOfBatchesOfGoods.AddExpensesMan                                              AS AddExpensesMan,
	|	CostOfBatchesOfGoods.LaborCostsMan                                            AS LaborCostsMan,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedFixedCostsManag,
	|	CAST(0 AS NUMBER (28,10))                                                     AS ItemizedVariableCostsManag,
	|	CostOfBatchesOfGoods.ProvisionForImpairmentMan                                    AS ProvisionForImpairmentMan
	|
	|INTO CostOfBatchesOfGoodsPreliminary
	|FROM
	|	TTValueOfBatchesOfGoods AS CostOfBatchesOfGoods
	|	LEFT JOIN TTTableOfSolutions_CostOfOrganizations AS CostOfOrganizations
	|		ON CostOfOrganizations.NodeNumber = CostOfBatchesOfGoods.NodeNumber
	|;
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|INTO TTValueOfBatchesOfGoods
	|FROM
	|	CostOfBatchesOfGoodsPreliminary AS CostOfBatchesOfGoods
		// The indexation corresponds to the table of the cash settlement turnover and the cost of goods
	// Calculation of the cost of the individual rhythms.Create a description of the Register() #Index area of the Register
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization,
	|	Lot
	|";
	
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(CalculationParameters, "CostOfBatchesOfGoodsPreliminary");
	
EndProcedure

Procedure GenerateCostOfBatchesOfGoods_ProvisionsForImpairmentOfInventories(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "GenerateCostOfBatchesOfGoods_ProvisionsForImpairmentOfInventories");
	
	Query = New Query;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	Query.Text = 
		"SELECT
		|	UNDEFINED                                 AS DocumentRegisterRecords,
		|	&BeginOfPeriod                               AS Period,
		|	AdjustmentNodes.NodeNumber                  AS NodeNumber,
		// Dimensions
		|	AdjustmentNodes.Organization                AS Organization,
		|	AdjustmentNodes.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	AdjustmentNodes.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	AdjustmentNodes.AccountingSection                AS AccountingSection,
		|	AdjustmentNodes.Lot                     AS Lot,
		|	AdjustmentNodes.LotVendorAttributes       AS LotVendorAttributes,
		|	AdjustmentNodes.FinancialAccountingDimension  AS FinancialAccountingDimension,
		|	AdjustmentNodes.VATActivityType         AS VATActivityType,
		// Resources
		|	CAST(0 AS NUMBER(28,10))                                                               AS Cost,
		|	CAST(0 AS NUMBER(28,10))                                                               AS CostExcludingVAT,
		|	CAST(0 AS NUMBER(28,10))                                                               AS OffBalanceCost,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AdditionalExpenseCost,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AdditionalExpensesCostExcludingVAT,
		|	CAST(0 AS NUMBER(28,10))                                                               AS LaborCosts,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsIncludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsExcludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsIncludingVAT,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsExcludingVAT,
		|
		|	CAST(0 AS NUMBER (28,10))                                                              AS LocalCost,
		|	CAST(0 AS NUMBER(28,10))                                                               AS OffBalanceCostLocal,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AddExpensesLocal,
		|	CAST(0 AS NUMBER(28,10))                                                               AS LaborCostsLocal,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsCompl,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsCompl,
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostInTaxAccounting,
		|	CAST(0 AS NUMBER (28,10))                                                              AS PermanentDifference,
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostTD,
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostOfPersonalIncomeTax,
		|	CAST(&ProvisionForImpairmentLocal AS NUMBER(28,10))                                       AS ProvisionForImpairmentLocal,
		|
		|	CAST(0 AS NUMBER (28,10))                                                              AS CostMan,
		|	CAST(0 AS NUMBER (28,10))                                                              AS AddExpensesMan,
		|	CAST(0 AS NUMBER(28,10))                                                               AS LaborCostsMan,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedFixedCostsManag,
		|	CAST(0 AS NUMBER (28,10))                                                              AS ItemizedVariableCostsManag,
		|	CAST(&ProvisionForImpairmentMan AS NUMBER(28,10))                                        AS ProvisionForImpairmentMan
		|INTO TTValueOfBatchesOfGoods
		|FROM
		|	TTAdjustmentNodes AS AdjustmentNodes
		|	LEFT JOIN TTTable1_ProvisionsForImpairmentOfInventoriesOfOrganizations AS TableOfOrganizationsDecisions
		|		ON TableOfOrganizationsDecisions.NodeNumber = AdjustmentNodes.NodeNumber
		// The indexation corresponds to the table of the cash settlement turnover and the cost of goods
		// Calculation of the cost of the individual rhythms.Create a description of the Register() #Index area of the Register
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
	Query.Text = StrReplace(Query.Text, "&ProvisionForImpairmentLocal", "ISNULL(TableOfOrganizationsDecisions.ProvisionForImpairmentLocal, 0)");
	Query.Text = StrReplace(Query.Text, "&ProvisionForImpairmentMan", "ISNULL(TableOfOrganizationsDecisions.ProvisionForImpairmentMan, 0)");
	Query.Text = StrReplace(Query.Text, "&ProvisionForImpairmentLocal", "0");
	Query.Text = StrReplace(Query.Text, "&ProvisionForImpairmentMan", "0");
	
	Query.Text = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, Query.Text);
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
EndProcedure

#EndRegion

#Region StageProcedures_PreparationOfDataForCostOfBatchesOfGoods

// Stage " Preparation of the data for the cost ofparty goods"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForCostOfBatchesOfGoods(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForCostOfBatchesOfGoods");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTValueOfBatchesOfGoods");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		RequestTextForCostOfBatchesOfGoods(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForCostOfBatchesOfGoods(CalculationParameters = Undefined) Export
	
	QueryText = "" 
		+ TextCostOfBatchesOfGoods()
		+ "";
	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextCostOfBatchesOfGoods()
	Return "
		|SELECT
		|	CostOfBatchesOfGoods.NodeNumber                 AS NodeNumber,
		// Dimensions
		|	CostOfBatchesOfGoods.Organization                AS Organization,
		|	CostOfBatchesOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CostOfBatchesOfGoods.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	CostOfBatchesOfGoods.AccountingSection                AS AccountingSection,
		|	CostOfBatchesOfGoods.Lot                     AS Lot,
		|	CostOfBatchesOfGoods.LotVendorAttributes       AS LotVendorAttributes,
		|	CostOfBatchesOfGoods.FinancialAccountingDimension  AS FinancialAccountingDimension,
		|	CostOfBatchesOfGoods.VATActivityType         AS VATActivityType,
		// Resources
		|	CostOfBatchesOfGoods.Cost                                                             AS Cost,
		|	CostOfBatchesOfGoods.AdditionalExpenseCost                                                   AS AdditionalExpenseCost,
		|	CostOfBatchesOfGoods.OffBalanceCost                                                 AS OffBalanceCost,
		|	CostOfBatchesOfGoods.CostExcludingVAT                                                       AS CostExcludingVAT,
		|	CostOfBatchesOfGoods.AdditionalExpensesCostExcludingVAT                                             AS AdditionalExpensesCostExcludingVAT,
		|	CostOfBatchesOfGoods.LaborCosts                                                          AS LaborCosts,
		|	CAST(ISNULL(CostOfEnterprise.ItemizedFixedCostsIncludingVAT, 0) AS NUMBER(28,10))   AS ItemizedFixedCostsIncludingVAT,
		|	CAST(ISNULL(CostOfEnterprise.ItemizedVariableCostsIncludingVAT, 0) AS NUMBER(28,10))   AS ItemizedVariableCostsIncludingVAT,
		|	CAST(ISNULL(CostOfEnterprise.ItemizedFixedCostsExcludingVAT, 0) AS NUMBER(28,10)) AS ItemizedFixedCostsExcludingVAT,
		|	CAST(ISNULL(CostOfEnterprise.ItemizedVariableCostsExcludingVAT, 0) AS NUMBER(28,10)) AS ItemizedVariableCostsExcludingVAT,
		|
		|	CostOfBatchesOfGoods.LocalCost                                                         AS LocalCost,
		|	CostOfBatchesOfGoods.OffBalanceCostLocal                                             AS OffBalanceCostLocal,
		|	CostOfBatchesOfGoods.AddExpensesLocal                                                        AS AddExpensesLocal,
		|	CostOfBatchesOfGoods.LaborCostsLocal                                                      AS LaborCostsLocal,
		|	CAST(ISNULL(CostOfOrganizations.ItemizedFixedCostsCompl, 0) AS NUMBER(28,10))   AS ItemizedFixedCostsCompl,
		|	CAST(ISNULL(CostOfOrganizations.ItemizedVariableCostsCompl, 0) AS NUMBER(28,10))   AS ItemizedVariableCostsCompl,
		|
		|	CAST(
		|	0 AS NUMBER(28,10))                                                                          AS CostInTaxAccounting,
		|	CAST(
		|	0 AS NUMBER(28,10))                                                                          AS PermanentDifference,
		|	CAST(
		|	0 AS NUMBER(28,10))                                                                          AS CostTD,
		// There is no cost of personal income tax at this stage yet. See calculation of the highest costind.Cost calculation_COSTNDD
		|	CAST(0 AS NUMBER(28,10))																 AS CostOfPersonalIncomeTax,
		|	CostOfBatchesOfGoods.ProvisionForImpairmentLocal                                              AS ProvisionForImpairmentLocal,
		|
		|	CostOfBatchesOfGoods.CostMan                                                          AS CostMan,
		|	CostOfBatchesOfGoods.AddExpensesMan                                                         AS AddExpensesMan,
		|	CostOfBatchesOfGoods.LaborCostsMan                                                       AS LaborCostsMan,
		|	CAST(ISNULL(CostOfOrganizations.ItemizedFixedCostsManag, 0) AS NUMBER(28,10))    AS ItemizedFixedCostsManag,
		|	CAST(ISNULL(CostOfOrganizations.ItemizedVariableCostsManag, 0) AS NUMBER(28,10))    AS ItemizedVariableCostsManag,
		|	CostOfBatchesOfGoods.ProvisionForImpairmentMan                                               AS ProvisionForImpairmentMan
		|
		|INTO TTValueOfBatchesOfGoods
		|FROM
		|	TTValueOfBatchesOfGoodsPrevious AS CostOfBatchesOfGoods
		|	LEFT JOIN TTTableOfSolutions_CostOfEnterprise AS CostOfEnterprise
		|		ON CostOfEnterprise.NodeNumber = CostOfBatchesOfGoods.NodeNumber
		|	LEFT JOIN TTTableOfSolutions_CostOfOrganizations AS CostOfOrganizations
		|		ON CostOfOrganizations.NodeNumber = CostOfBatchesOfGoods.NodeNumber
		|
		// The indexation corresponds to the table of the cash settlement turnover and the cost of goods
		// Calculation of the cost of the individual rhythms.Create a description of the Register() #Index area of the Register
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparationOfDataForCostOfOtherExpensesUnfinishedProduction

// Stage "Preparation of the data for the cost of other expenses""
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparationOfDataForCostOfOtherExpensesUnfinishedProduction(CalculationParameters)
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparationOfDataForCostOfOtherExpensesUnfinishedProduction");
	
	// 1. Initialization of the data structure of the data preparation stage.
	CostCalculationAppliedAlgorithms.InitializeDataPreparationForFollowingSteps(
		CalculationParameters,
		"TTValueOfWorkInProgress, TTValueOfWorkInProgressLocal, FutureExpenseCommitments,
		|TtOfCostOfAdditionalExpenses, TtOfCostOfAdditionalLocalExpenses");
		
	// 2. Formation of temporary tables.
	CostCalculationAppliedAlgorithms.PrepareDataForFollowingSteps(
		CalculationParameters,
		RequestTextForCostOfOtherUnfinishedProductionExpenses(CalculationParameters));
	
	// 3. We are completing the data preparation stage. 
	CostCalculationAppliedAlgorithms.CompleteDataPreparationForNextSteps(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForCostOfOtherUnfinishedProductionExpenses(CalculationParameters = Undefined) Export
	
	QueryText = ""
		+ TTValueOfWorkInProgress()
		+ Common.QueryBatchSeparator() + TTValueOfWorkInProgressLocal()
		+ Common.QueryBatchSeparator() + FutureExpenseCommitments()
		+ Common.QueryBatchSeparator() + TtOfCostOfAdditionalExpensesArticleByArticle()
		+ Common.QueryBatchSeparator() + TTCostOfAdditionalExpensesArticleByArticleLocal()
		+ "";
	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TTValueOfWorkInProgress()
	Return "
		|SELECT
		|	AdjustmentNodes.AccountingSection 					  AS AccountingSection,
		|	AdjustmentNodes.Organization 					  AS Organization,
		|	AdjustmentNodes.Department                   AS Department,
		|	AdjustmentNodes.LineOfBusiness		  AS LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem 				  AS ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses 			  AS DimensionOfExpenses,
		|	AdjustmentNodes.ProductCostElement 			  AS ProductCostElement,
		|	AdjustmentNodes.Stage 							  AS Stage,
		|	AdjustmentNodes.ProductsGroup 				  AS ProductsGroup,
		|	AdjustmentNodes.RuleOfCostAllocatingToProductionLots 		  AS RuleOfCostAllocatingToProductionLots,
		|	AdjustmentNodes.Lot 						  AS Lot,
		|	AdjustmentNodes.LotVendorAttributes 			  AS LotVendorAttributes,
		|	AdjustmentNodes.RowCodeProducts 			  AS RowCodeProducts,
		
		|	0                                                 AS Cost,
		|	0                                                 AS AdditionalExpenseCost,
		|	0                                                 AS LaborCosts,
		|	SUM(DecisionTable.ItemizedFixedCostsIncludingVAT)	  AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DecisionTable.ItemizedVariableCostsIncludingVAT)	  AS ItemizedVariableCostsIncludingVAT,
		|	0                                                 AS OffBalanceCost,
		
		|	0                                                 AS CostExcludingVAT,
		|	0                                                 AS AdditionalExpensesCostExcludingVAT,
		|	0                                                 AS LaborCostsWithoutVAT,
		|	SUM(DecisionTable.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DecisionTable.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT
		|
		|INTO TTValueOfWorkInProgress
		|FROM
		|	TTTableOfSolutions_CostOfEnterprise AS DecisionTable
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|		ON DecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
		|WHERE
		|	(DecisionTable.ItemizedFixedCostsIncludingVAT <> 0
		|		OR DecisionTable.ItemizedVariableCostsIncludingVAT <> 0
		|		OR DecisionTable.ItemizedFixedCostsExcludingVAT <> 0
		|		OR DecisionTable.ItemizedVariableCostsExcludingVAT <> 0)
		|	AND AdjustmentNodes.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
		|	AND AdjustmentNodes.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND AdjustmentNodes.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|
		|GROUP BY
		|	AdjustmentNodes.AccountingSection,
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses,
		|	AdjustmentNodes.ProductCostElement,
		|	AdjustmentNodes.Stage,
		|	AdjustmentNodes.ProductsGroup,
		|	AdjustmentNodes.RuleOfCostAllocatingToProductionLots,
		|	AdjustmentNodes.Lot,
		|	AdjustmentNodes.LotVendorAttributes,
		|	AdjustmentNodes.RowCodeProducts
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Stage
		|";
EndFunction

Function TTValueOfWorkInProgressLocal()
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber 				AS NodeNumber,
		|	AdjustmentNodes.AccountingSection 				AS AccountingSection,
		|	AdjustmentNodes.Organization 				AS Organization,
		|	AdjustmentNodes.Department             AS Department,
		|	AdjustmentNodes.LineOfBusiness	AS LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem 			AS ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses 		AS DimensionOfExpenses,
		|	AdjustmentNodes.ProductCostElement 		AS ProductCostElement,
		|	AdjustmentNodes.Stage 						AS Stage,
		|	AdjustmentNodes.ProductsGroup 			AS ProductsGroup,
		|	AdjustmentNodes.RuleOfCostAllocatingToProductionLots 	AS RuleOfCostAllocatingToProductionLots,
		|	AdjustmentNodes.Lot					AS Lot,
		|	AdjustmentNodes.LotVendorAttributes		AS LotVendorAttributes,
		|	AdjustmentNodes.RowCodeProducts		AS RowCodeProducts,
		
		|	0 AS LocalCost,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	SUM(DecisionTable.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(DecisionTable.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	CASE 
		|		WHEN MAX(AdjustmentNodes.WeightArticleByArticleLocal) = 0 THEN 0
		|		ELSE SUM(ISNULL(NodeReserves.ReserveLocal, 0)) / MAX(AdjustmentNodes.WeightArticleByArticleLocal)
		|	END AS ReserveLocal,
		|	0 AS OffBalanceCostLocal,
		|	SUM(ISNULL(DecisionTable_TaxAccounting.AmountFA, 0))           AS CostInTaxAccounting,
		|	SUM(ISNULL(DecisionTable_TaxAccounting.PermanentDifference, 0)) AS PermanentDifference,
		|	SUM(ISNULL(DecisionTable_TaxAccounting.CostTD, 0))  AS CostTD,
		
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS LaborCostsMan,
		|	SUM(DecisionTable.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(DecisionTable.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag,
		|	CASE 
		|		WHEN MAX(AdjustmentNodes.WeightArticleByArticleMan) = 0 THEN 0
		|		ELSE SUM(ISNULL(NodeReserves.ReserveMan, 0)) / MAX(AdjustmentNodes.WeightArticleByArticleMan)
		|	END AS ReserveMan,
		|	0 AS CostOfPersonalIncomeTax
		|
		|INTO TTValueOfWorkInProgressLocal
		|FROM
		|	TTTableOfSolutions_CostOfOrganizations AS DecisionTable
		|
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS AdjustmentNodes
		|	ON AdjustmentNodes.NodeNumber = DecisionTable.NodeNumber
		|
		|	LEFT JOIN TTDecisionTable_TaxAccounting AS DecisionTable_TaxAccounting
		|	ON DecisionTable_TaxAccounting.NodeNumber = DecisionTable.NodeNumber
		|
		|	LEFT JOIN NodeReserves AS NodeReserves
		|		ON DecisionTable.NodeNumber = NodeReserves.NodeNumber
		|WHERE
		|	(DecisionTable.ItemizedFixedCostsCompl <> 0
		|		OR DecisionTable.ItemizedVariableCostsCompl <> 0
		|		OR DecisionTable.ItemizedFixedCostsManag <> 0
		|		OR DecisionTable.ItemizedVariableCostsManag <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.AmountFA, 0) <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.PermanentDifference, 0) <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.CostTD, 0) <> 0)
		|	AND AdjustmentNodes.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
		|	AND AdjustmentNodes.ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|	AND AdjustmentNodes.AccountingSection IN (
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts),
		|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber,
		|	AdjustmentNodes.AccountingSection,
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses,
		|	AdjustmentNodes.ProductCostElement,
		|	AdjustmentNodes.Stage,
		|	AdjustmentNodes.ProductsGroup,
		|	AdjustmentNodes.RuleOfCostAllocatingToProductionLots,
		|	AdjustmentNodes.Lot,
		|	AdjustmentNodes.LotVendorAttributes,
		|	AdjustmentNodes.RowCodeProducts
		|
		|INDEX BY
		|	Lot,
		|	LotVendorAttributes,
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	Stage
		|";
EndFunction

Function TtOfCostOfAdditionalExpensesArticleByArticle()
	Return "
		|SELECT
		|	AdjustmentNodes.Organization AS Organization,
		|	AdjustmentNodes.Department AS Department,
		|	AdjustmentNodes.LineOfBusiness AS LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem AS ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses AS DimensionOfExpenses,
		|	SUM(DecisionTable.ItemizedFixedCostsIncludingVAT)   AS ItemizedFixedCostsIncludingVAT,
		|	SUM(DecisionTable.ItemizedVariableCostsIncludingVAT)   AS ItemizedVariableCostsIncludingVAT,
		|	SUM(DecisionTable.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(DecisionTable.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT
		|INTO TtOfCostOfAdditionalExpenses
		|FROM
		|	TTTableOfSolutions_CostOfEnterprise AS DecisionTable
		|	INNER JOIN AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|		ON DecisionTable.NodeNumber = AdjustmentNodes.NodeNumber
		|WHERE
		|	DecisionTable.ItemizedVariableCostsIncludingVAT + DecisionTable.ItemizedFixedCostsIncludingVAT <> 0
		|		OR DecisionTable.ItemizedVariableCostsExcludingVAT + DecisionTable.ItemizedFixedCostsExcludingVAT <> 0
		|
		|GROUP BY
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses
		|
		|INDEX BY
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses
		|";
EndFunction

Function TTCostOfAdditionalExpensesArticleByArticleLocal()
	Return "
		|SELECT
		|	AdjustmentNodes.NodeNumber AS NodeNumber,
		|	AdjustmentNodes.Organization AS Organization,
		|	AdjustmentNodes.Department AS Department,
		|	AdjustmentNodes.LineOfBusiness AS LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem AS ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses AS DimensionOfExpenses,
		|	SUM(DecisionTable.ItemizedFixedCostsCompl)   AS ItemizedFixedCostsCompl,
		|	SUM(DecisionTable.ItemizedVariableCostsCompl)   AS ItemizedVariableCostsCompl,
		|	SUM(DecisionTable.ItemizedFixedCostsManag)    AS ItemizedFixedCostsManag,
		|	SUM(DecisionTable.ItemizedVariableCostsManag)    AS ItemizedVariableCostsManag,
		|
		|	SUM(ISNULL(DecisionTable_TaxAccounting.AmountFA, 0))          AS CostInTaxAccounting,
		|	SUM(ISNULL(DecisionTable_TaxAccounting.PermanentDifference, 0))	AS PermanentDifference,
		|	SUM(ISNULL(DecisionTable_TaxAccounting.CostTD, 0))	AS CostTD,
		|	0																	AS CostOfPersonalIncomeTax
		|INTO TtOfCostOfAdditionalLocalExpenses
		|FROM
		|	TTTableOfSolutions_CostOfOrganizations AS DecisionTable
		|
		|	INNER JOIN AdditionalCostAdjustmentNodes AS AdjustmentNodes
		|	ON AdjustmentNodes.NodeNumber = DecisionTable.NodeNumber
		|
		|	LEFT JOIN TTDecisionTable_TaxAccounting AS DecisionTable_TaxAccounting
		|	ON DecisionTable_TaxAccounting.NodeNumber = DecisionTable.NodeNumber
		|
		|WHERE
		|	DecisionTable.ItemizedVariableCostsCompl + DecisionTable.ItemizedFixedCostsCompl <> 0
		|		OR DecisionTable.ItemizedVariableCostsManag + DecisionTable.ItemizedFixedCostsManag <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.AmountFA, 0) <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.PermanentDifference, 0) <> 0
		|		OR ISNULL(DecisionTable_TaxAccounting.CostTD, 0) <> 0
		|
		|GROUP BY
		|	AdjustmentNodes.NodeNumber,
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses
		|
		|INDEX BY
		|	AdjustmentNodes.NodeNumber,
		|	AdjustmentNodes.Organization,
		|	AdjustmentNodes.Department,
		|	AdjustmentNodes.LineOfBusiness,
		|	AdjustmentNodes.ExpenseItem,
		|	AdjustmentNodes.DimensionOfExpenses
		|";
EndFunction

Function FutureExpenseCommitments()
	Return "
		|SELECT
		|	DD.Organization,
		|	DD.LineOfBusiness,
		|	DD.ReserveKind,
		|	DD.ProvisionObject,
		|	Nodes.Department,
		|	Nodes.ExpenseItem,
		|	Nodes.DimensionOfExpenses,
		|	CAST(
		|		CASE
		|			WHEN DD.ExpenseCompl = 0 OR NodeReserves.ReserveLocal = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ExpenseCompl /
		|					CASE
		|						WHEN DD.ExpenseCompl < NodeReserves.ReserveLocal
		|							THEN NodeReserves.ReserveLocal
		|						ELSE DD.ExpenseCompl
		|					END AS NUMBER(28,10))
		|		END * DD.ReserveLocal AS NUMBER(28,10)) AS SumCompl,
		|	CAST(
		|		CASE
		|			WHEN DD.ExpensePD = 0 OR NodeReserves.ReserveLocal = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ExpensePD /
		|					CASE
		|						WHEN DD.ExpensePD < NodeReserves.ReserveLocal
		|							THEN NodeReserves.ReserveLocal
		|						ELSE DD.ExpensePD
		|					END AS NUMBER(28,10))
		|		END * DD.ReserveLocal AS NUMBER(28,10)) AS PermanentDifference,
		|	CAST(
		|		CASE
		|			WHEN DD.ConsumptionWELL = 0 OR NodeReserves.TAReserve = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ConsumptionWELL /
		|					CASE
		|						WHEN DD.ConsumptionWELL < NodeReserves.TAReserve
		|							THEN NodeReserves.TAReserve
		|						ELSE DD.ConsumptionWELL
		|					END AS NUMBER(28,10))
		|		END * DD.TAReserve AS NUMBER(28,10)) AS AmountFA,
		|	CAST(
		|		CASE
		|			WHEN DD.ExpenseMan = 0 OR NodeReserves.ReserveMan = 0
		|				THEN 0
		|			ELSE
		|				CAST(DD.ExpenseMan /
		|					CASE
		|						WHEN DD.ExpenseMan < NodeReserves.ReserveMan
		|							THEN NodeReserves.ReserveMan
		|						ELSE DD.ExpenseMan
		|					END AS NUMBER(28,10))
		|		END * DD.ReserveMan AS NUMBER(28,10)) AS SumMan
		|INTO FutureExpenseCommitments
		|FROM
		|	DetailedReservesByNode AS DD
		|
		|	INNER JOIN NodeReserves AS NodeReserves
		|		ON DD.NodeNumber = NodeReserves.NodeNumber
		|	INNER JOIN TTNodesAdjustmentsItemByItemUnfinishedProductionCosts AS Nodes
		|		ON DD.NodeNumber = Nodes.NodeNumber
		|";
EndFunction

#EndRegion

#Region StageProcedures_PreparingDataForCostOfGoods

// Stage " Preparation of the data for the cost of goods"
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//
Procedure PreparingDataForCostOfGoods(CalculationParameters) Export
	
	CostCalculationProtocol.StartOfCalculationStage(CalculationParameters, "PreparingDataForCostOfGoods");
	
	// 1. Initialization of the data structure for calculation
	//	- forms the structure of the calculation parameters.Distribution of parties.
	CostCalculationAppliedAlgorithms.InitializeBatchTranslation(
		CalculationParameters,
		Undefined,
		Metadata.InformationRegisters.GoodsCost.Name);
		
	CalculationParameters.Insert("CostCalculationIsUnderway", True);
		
	// 2. Getting the source data for the broadcast
	// 	- generates a temporary Data table.
	CostCalculationAppliedAlgorithms.GetDataFromCalculationStage(
		CalculationParameters,
		RequestTextForProductPrices(CalculationParameters));
		
	CalculationParameters.Insert("CostCalculationIsUnderway", False);
		
	// 3. Putting data into the receiver table and clearing auxiliary temporary tables.
	// 	- generates movements according to the register of information about the cost of goods.
	CostCalculationAppliedAlgorithms.CompleteBatchDistribution(CalculationParameters);
	
EndProcedure

// Request texts

// ... general

Function RequestTextForProductPrices(CalculationParameters = Undefined) Export
	
	QueriesTexts = New Array();
	// preparation of temporary tables
	QueriesTexts.Add(TextTTRpmQuantityWithBatches());
	QueriesTexts.Add(TextTTRpmQuantityWithoutBatches());
	
	// Comment 20966.
	// If the calculation parameters are defined, in order to optimize, we form the query text depending on:
	//   * If this is a routine task, then we connect TT and without taking into account the batches, we get the average cost.
	//   * If this is NOT a routine task, we connect the TT taking into account the batches.
	// If the calculation parameters are NOT defined, then the request text is generated for both cases - not optimal.
	If CalculationParameters = Undefined Then
		QueriesTexts.Add(TextTTCostOfBatchesOfGoodsWithQuantity(False)); // Uses the second number of parties
	Else
		IsScheduledJob = False;
		If CalculationParameters.Property("ScheduledJob") Then
			IsScheduledJob = CalculationParameters.ScheduledJob;
		EndIf;
		
		If IsScheduledJob Then
			QueriesTexts.Add(TextTTCostOfBatchesOfGoodsWithQuantity_RoutineTask());
		Else
			QueriesTexts.Add(TextTTCostOfBatchesOfGoodsWithQuantity(True)); // Uses the second number of parties
		EndIf;
	EndIf;
	
	QueryTextsMerging = New Array();
	// Sample data
	QueryTextsMerging.Add(TextDescriptionOfDataForCostOfGoods());
	QueryTextsMerging.Add(TextCostOfGoods());
	
	MergeRequestText = StrConcat(QueryTextsMerging,
		TMCommonUse.QuerySeparatorInJoin());
	QueriesTexts.Add(MergeRequestText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	If CalculationParameters <> Undefined Then
		QueryText = CostCalculationCostAdjustment.SetBitDepthOfNumbersInRequestText(CalculationParameters, QueryText);
	EndIf;
	
	Return QueryText;
	
EndFunction

// ... formation of temporary tables

Function TextTTRpmQuantityWithBatches()
	Return "
		|SELECT
		|	T.ItemsLocationAttributes,
		|	T.AccountingSection,
		|	T.InventoryOwnerAttribute,
		|	T.Organization,
		|	T.Lot,
		|	T.LotVendorAttributes,
		|	T.FinancialAccountingDimension,
		|	T.VATActivityType,
		|	CAST(CASE
		|		WHEN T.CountExpense <> 0 THEN T.CountExpense
		|		ELSE T.CountBalance
		|	END AS NUMBER(15,3)) AS Count
		|INTO TTRpmQuantityWithBatches
		|FROM
		|(SELECT
		|	QuantityData.ItemsLocationAttributes,
		|	QuantityData.AccountingSection,
		|	QuantityData.InventoryOwnerAttribute,
		|	QuantityData.Organization,
		|	QuantityData.Lot,
		|	QuantityData.LotVendorAttributes,
		|	QuantityData.FinancialAccountingDimension,
		|	QuantityData.VATActivityType,
		|	SUM(QuantityData.CountExpense)  AS CountExpense,
		|	SUM(QuantityData.CountBalance) AS CountBalance
		|FROM
		|	(SELECT
		|		Turnovers.ItemsLocationAttributes,
		|		Turnovers.AccountingSection AS AccountingSection,
		|		Turnovers.InventoryOwnerAttribute,
		|		Turnovers.Organization,
		|		Turnovers.Lot,
		|		Turnovers.LotVendorAttributes,
		|		Turnovers.FinancialAccountingDimension,
		|		Turnovers.VATActivityType,
		|		Turnovers.Count 	AS CountExpense,
		|		0 					AS CountBalance
		|	FROM
		|		TTCashEstimatedTurnoverCostOfGoods AS Turnovers
		|	WHERE
		|		NOT Turnovers.OfficialTypeOfMovementParish
		|		AND Turnovers.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|
		|	UNION ALL
		|
		|	SELECT
		|		Balance.ItemsLocationAttributes,
		|		Balance.AccountingSection,
		|		Balance.InventoryOwnerAttribute,
		|		Balance.Organization,
		|		Balance.Lot,
		|		Balance.LotVendorAttributes,
		|		Balance.FinancialAccountingDimension,
		|		Balance.VATActivityType,
		|		0 					AS CountExpense,
		|		Balance.Count 	AS CountBalance
		|	FROM
		|		TTCashSettlementBalancesCostOfGoods AS Balance
		|	WHERE
		|		Balance.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
		|	) AS QuantityData
		|
		|GROUP BY
		|	QuantityData.ItemsLocationAttributes,
		|	QuantityData.Organization,
		|	QuantityData.InventoryOwnerAttribute,
		|	QuantityData.AccountingSection,
		|	QuantityData.Lot,
		|	QuantityData.LotVendorAttributes,
		|	QuantityData.FinancialAccountingDimension,
		|	QuantityData.VATActivityType
		|) AS T
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization,
		|	Lot
		|";
EndFunction

Function TextTTRpmQuantityWithoutBatches() // Uses the second number of parties
	Return "
		|SELECT
		|	Turnovers.ItemsLocationAttributes,
		|	Turnovers.AccountingSection,
		|	Turnovers.InventoryOwnerAttribute,
		|	Turnovers.Organization,
		|	SUM(CAST(Turnovers.Count AS NUMBER(15,3))) AS Count
		|INTO TTRevolutionsQuantityWithoutBatches
		|FROM
		|	TTRpmQuantityWithBatches AS Turnovers
		|
		|GROUP BY
		|	Turnovers.ItemsLocationAttributes,
		|	Turnovers.AccountingSection,
		|	Turnovers.InventoryOwnerAttribute,
		|	Turnovers.Organization
		|
		|HAVING
		|	SUM(Turnovers.Count) <> 0
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization
		|";
EndFunction

Function TextTTCostOfBatchesOfGoodsWithQuantity_RoutineTask() // Uses the second number of parties
	QueryText = "
		|SELECT
		|	GoodsCost.Organization AS Organization,
		|	GoodsCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsCost.AccountingSection AS AccountingSection,
		|	SUM(GoodsCost.Cost) AS Cost,
		|	SUM(GoodsCost.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(GoodsCost.OffBalanceCost) AS OffBalanceCost,
		|	SUM(GoodsCost.AdditionalExpenseCost) AS AdditionalExpenseCost,
		|	SUM(GoodsCost.AdditionalExpensesCostExcludingVAT) AS AdditionalExpensesCostExcludingVAT,
		|	SUM(GoodsCost.LaborCosts) AS LaborCosts,
		|	SUM(GoodsCost.ItemizedFixedCostsIncludingVAT) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(GoodsCost.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(GoodsCost.ItemizedVariableCostsIncludingVAT) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(GoodsCost.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(GoodsCost.LocalCost) AS LocalCost,
		|	SUM(GoodsCost.OffBalanceCostLocal) AS OffBalanceCostLocal,
		|	SUM(GoodsCost.PermanentDifference) AS PermanentDifference,
		|	SUM(GoodsCost.CostTD) AS CostTD,
		|	SUM(GoodsCost.AddExpensesLocal) AS AddExpensesLocal,
		|	SUM(GoodsCost.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(GoodsCost.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(GoodsCost.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(GoodsCost.CostMan) AS CostMan,
		|	SUM(GoodsCost.AddExpensesMan) AS AddExpensesMan,
		|	SUM(GoodsCost.LaborCostsMan) AS LaborCostsMan,
		|	SUM(GoodsCost.ItemizedFixedCostsManag) AS ItemizedFixedCostsManag,
		|	SUM(GoodsCost.ItemizedVariableCostsManag) AS ItemizedVariableCostsManag
		|
		|INTO TTCostOfBatchesOfGoods_RoutineTask
		|FROM
		|	TTValueOfBatchesOfGoods AS GoodsCost
		|
		|GROUP BY
		|	GoodsCost.Organization,
		|	GoodsCost.AccountingSection,
		|	GoodsCost.InventoryOwnerAttribute,
		|	GoodsCost.ItemsLocationAttributes
		|
		|INDEX BY
		|	Organization,
		|	AccountingSection,
		|	InventoryOwnerAttribute,
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RevolutionsWithBatches.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	RevolutionsWithBatches.AccountingSection AS AccountingSection,
		|	RevolutionsWithBatches.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	RevolutionsWithBatches.Organization AS Organization,
		|	SUM(RevolutionsWithBatches.Count)
		|
		|INTO TTRevolutionsQuantityWithBatches_RoutineTask
		|FROM
		|	TTRpmQuantityWithBatches AS RevolutionsWithBatches
		|
		|GROUP BY
		|	RevolutionsWithBatches.ItemsLocationAttributes,
		|	RevolutionsWithBatches.AccountingSection,
		|	RevolutionsWithBatches.InventoryOwnerAttribute,
		|	RevolutionsWithBatches.Organization
		|
		|INDEX BY
		|	Organization,
		|	AccountingSection,
		|	InventoryOwnerAttribute,
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsCost.Organization AS Organization,
		|	GoodsCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsCost.AccountingSection AS AccountingSection,
		|	CAST(GoodsCost.Cost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS Cost,
		|	CAST(GoodsCost.CostExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS CostExcludingVAT,
		|	CAST(GoodsCost.OffBalanceCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS OffBalanceCost,
		|	CAST(GoodsCost.AdditionalExpenseCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS AdditionalExpenseCost,
		|	CAST(GoodsCost.AdditionalExpensesCostExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS AdditionalExpensesCostExcludingVAT,
		|	CAST(GoodsCost.LaborCosts
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS LaborCosts,
		|	CAST(GoodsCost.ItemizedFixedCostsIncludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedFixedCostsIncludingVAT,
		|	CAST(GoodsCost.ItemizedFixedCostsExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedFixedCostsExcludingVAT,
		|	CAST(GoodsCost.ItemizedVariableCostsIncludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedVariableCostsIncludingVAT,
		|	CAST(GoodsCost.ItemizedVariableCostsExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedVariableCostsExcludingVAT,
		|	CAST(GoodsCost.LocalCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS LocalCost,
		|	CAST(GoodsCost.OffBalanceCostLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS OffBalanceCostLocal,
		|	CAST(GoodsCost.PermanentDifference
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS PermanentDifference,
		|	CAST(GoodsCost.CostTD
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS CostTD,
		|	CAST(0 AS NUMBER (31,10))                            AS CostOfPersonalIncomeTax,
		|	CAST(GoodsCost.AddExpensesLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS AddExpensesLocal,
		|	CAST(GoodsCost.LaborCostsLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS LaborCostsLocal,
		|	CAST(GoodsCost.ItemizedFixedCostsCompl
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedFixedCostsCompl,
		|	CAST(GoodsCost.ItemizedVariableCostsCompl
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedVariableCostsCompl,
		|	CAST(GoodsCost.CostMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS CostMan,
		|	CAST(GoodsCost.AddExpensesMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS AddExpensesMan,
		|	CAST(GoodsCost.LaborCostsMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS LaborCostsMan,
		|	CAST(GoodsCost.ItemizedFixedCostsManag
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedFixedCostsManag,
		|	CAST(GoodsCost.ItemizedVariableCostsManag
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10)) AS ItemizedVariableCostsManag
		|
		|INTO TTCostOfBatchesOfGoodsWithQuantity
		|FROM
		|	TTCostOfBatchesOfGoods_RoutineTask AS GoodsCost
		|
		|	INNER JOIN TTRevolutionsQuantityWithBatches_RoutineTask AS RevolutionsWithBatches
		|		ON RevolutionsWithBatches.ItemsLocationAttributes  = GoodsCost.ItemsLocationAttributes
		|		AND RevolutionsWithBatches.AccountingSection 					= GoodsCost.AccountingSection
		|		AND RevolutionsWithBatches.InventoryOwnerAttribute 					= GoodsCost.InventoryOwnerAttribute
		|		AND RevolutionsWithBatches.Organization 					= GoodsCost.Organization
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTCostOfBatchesOfGoods_RoutineTask
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTRevolutionsQuantityWithBatches_RoutineTask
		|";
		
	Return QueryText;
EndFunction

Function TextTTCostOfBatchesOfGoodsWithQuantity(CalculationParametersAreDefined) // Uses the second number of parties
	QueryText = "
		|SELECT
		|	GoodsCost.Organization AS Organization,
		|	GoodsCost.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsCost.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsCost.AccountingSection AS AccountingSection,
		|
		|	SUM(
		|		CAST(GoodsCost.Cost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS Cost,
		|	SUM(
		|		CAST(GoodsCost.CostExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS CostExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.OffBalanceCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS OffBalanceCost,
		|	SUM(
		|		CAST(GoodsCost.AdditionalExpenseCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS AdditionalExpenseCost,
		|	SUM(
		|		CAST(GoodsCost.AdditionalExpensesCostExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS AdditionalExpensesCostExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.LaborCosts
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS LaborCosts,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsIncludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedFixedCostsIncludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsIncludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedVariableCostsIncludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsExcludingVAT
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.LocalCost
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS LocalCost,
		|	SUM(
		|		CAST(GoodsCost.OffBalanceCostLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS OffBalanceCostLocal,
		|	SUM(
		|		CAST(GoodsCost.PermanentDifference
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS PermanentDifference,
		|	SUM(
		|		CAST(GoodsCost.CostTD
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS CostTD,
		|	CAST(0 AS NUMBER (31,10))                            AS CostOfPersonalIncomeTax,
		|	SUM(
		|		CAST(GoodsCost.AddExpensesLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS AddExpensesLocal,
		|	SUM(
		|		CAST(GoodsCost.LaborCostsLocal
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS LaborCostsLocal,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsCompl
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedFixedCostsCompl,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsCompl
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedVariableCostsCompl,
		|	SUM(
		|		CAST(GoodsCost.CostMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS CostMan,
		|	SUM(
		|		CAST(GoodsCost.AddExpensesMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS AddExpensesMan,
		|	SUM(
		|		CAST(GoodsCost.LaborCostsMan
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS LaborCostsMan,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsManag
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedFixedCostsManag,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsManag
		|			* RevolutionsWithBatches.Count AS NUMBER(31,10))) AS ItemizedVariableCostsManag
		|
		|INTO TTCostOfBatchesOfGoodsWithQuantity
		|FROM
		|	TTValueOfBatchesOfGoods AS GoodsCost
		|
		|	INNER JOIN TTRpmQuantityWithBatches AS RevolutionsWithBatches
		|		ON RevolutionsWithBatches.ItemsLocationAttributes  = GoodsCost.ItemsLocationAttributes
		|		AND RevolutionsWithBatches.AccountingSection 					= GoodsCost.AccountingSection
		|		AND RevolutionsWithBatches.InventoryOwnerAttribute 					= GoodsCost.InventoryOwnerAttribute
		|		AND RevolutionsWithBatches.Organization 					= GoodsCost.Organization
		|		AND (RevolutionsWithBatches.Lot 						= GoodsCost.Lot
		|			OR &ScheduledJob)
		|		AND (RevolutionsWithBatches.LotVendorAttributes 		= GoodsCost.LotVendorAttributes
		|			OR &ScheduledJob)
		|		AND (RevolutionsWithBatches.FinancialAccountingDimension 	= GoodsCost.FinancialAccountingDimension
		|			OR &ScheduledJob)
		|		AND (RevolutionsWithBatches.VATActivityType 			= GoodsCost.VATActivityType
		|			OR &ScheduledJob)
		|
		|GROUP BY
		|	GoodsCost.ItemsLocationAttributes,
		|	GoodsCost.AccountingSection,
		|	GoodsCost.InventoryOwnerAttribute,
		|	GoodsCost.Organization
		|
		|INDEX BY
		|	ItemsLocationAttributes,
		|	Organization
		|";
		
	If CalculationParametersAreDefined Then
		// See comment 20966.
		QueryText = StrReplace(QueryText, "OR &ScheduledJob", "");
	EndIf;
	
	Return QueryText;
EndFunction

Function TextDescriptionOfDataForCostOfGoods()
	
	QueryText = "
		|SELECT TOP 0
		|	GoodsCost.Recorder,
		|	GoodsCost.Period,
		|
		|	GoodsCost.Organization,
		|	GoodsCost.ItemsLocationAttributes,
		|	GoodsCost.InventoryOwnerAttribute,
		|	GoodsCost.AccountingSection,
		|
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS OffBalanceCost,
		|	0 AS AdditionalExpenseCost,
		|	0 AS AdditionalExpensesCostExcludingVAT,
		|	0 AS LaborCosts,
		|	0 AS ItemizedFixedCostsIncludingVAT,
		|	0 AS ItemizedFixedCostsExcludingVAT,
		|	0 AS ItemizedVariableCostsIncludingVAT,
		|	0 AS ItemizedVariableCostsExcludingVAT,
		|	0 AS LocalCost,
		|	0 AS OffBalanceCostLocal,
		|	0 AS PermanentDifference,
		|	0 AS CostTD,
		|	0 AS CostOfPersonalIncomeTax,
		|	0 AS AddExpensesLocal,
		|	0 AS LaborCostsLocal,
		|	0 AS ItemizedFixedCostsCompl,
		|	0 AS ItemizedVariableCostsCompl,
		|	0 AS CostMan,
		|	0 AS AddExpensesMan,
		|	0 AS LaborCostsMan,
		|	0 AS ItemizedFixedCostsManag,
		|	0 AS ItemizedVariableCostsManag
		|
		|INTO Data
		|FROM
		|	InformationRegister.GoodsCost AS GoodsCost
		|";
		
	QueryText = CostCalculationAppliedAlgorithms.PrepareDataDescriptionRequest(QueryText);
	
	Return QueryText;
	
EndFunction

Function TextCostOfGoods() // Uses the value of Party goods by quantity, in addition to the quantity of non-parties
	Return "
		|SELECT
		|	CostCalculationDocuments.Ref													AS Recorder,
		|	&BeginOfPeriod 																			AS Period,
		|
		|	GoodsCost.Organization 															AS Organization,
		|	GoodsCost.ItemsLocationAttributes 											AS ItemsLocationAttributes,
		|	GoodsCost.InventoryOwnerAttribute 															AS InventoryOwnerAttribute,
		|	GoodsCost.AccountingSection 															AS AccountingSection,
		|
		|	SUM(
		|		CAST(GoodsCost.Cost
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS Cost,
		|	SUM(
		|		CAST(GoodsCost.CostExcludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS CostExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.OffBalanceCost
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS OffBalanceCost,
		|	SUM(
		|		CAST(GoodsCost.AdditionalExpenseCost
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS AdditionalExpenseCost,
		|	SUM(
		|		CAST(GoodsCost.AdditionalExpensesCostExcludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS AdditionalExpensesCostExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.LaborCosts
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS LaborCosts,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsIncludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedFixedCostsIncludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsExcludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedFixedCostsExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsIncludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedVariableCostsIncludingVAT,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsExcludingVAT
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedVariableCostsExcludingVAT,
		|	SUM(
		|		CAST(GoodsCost.LocalCost
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS LocalCost,
		|	SUM(
		|		CAST(GoodsCost.OffBalanceCostLocal
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS OffBalanceCostLocal,
		|	SUM(
		|		CAST(GoodsCost.PermanentDifference
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS PermanentDifference,
		|	SUM(
		|		CAST(GoodsCost.CostTD
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS CostTD,
		|	SUM(
		|		CAST(
		|			GoodsCost.CostOfPersonalIncomeTax
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS CostOfPersonalIncomeTax,
		|	SUM(
		|		CAST(GoodsCost.AddExpensesLocal
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS AddExpensesLocal,
		|	SUM(
		|		CAST(GoodsCost.LaborCostsLocal
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS LaborCostsLocal,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsCompl
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedFixedCostsCompl,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsCompl
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedVariableCostsCompl,
		|	SUM(
		|		CAST(GoodsCost.CostMan
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS CostMan,
		|	SUM(
		|		CAST(GoodsCost.AddExpensesMan
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS AddExpensesMan,
		|	SUM(
		|		CAST(GoodsCost.LaborCostsMan
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS LaborCostsMan,
		|	SUM(
		|		CAST(GoodsCost.ItemizedFixedCostsManag
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedFixedCostsManag,
		|	SUM(
		|		CAST(GoodsCost.ItemizedVariableCostsManag
		|				 / Turnovers.Count AS NUMBER(31,10)))									AS ItemizedVariableCostsManag
		|FROM
		|	TTCostOfBatchesOfGoodsWithQuantity AS GoodsCost
		|
		|	INNER JOIN TTCostCalculationDocuments AS CostCalculationDocuments
		|		ON GoodsCost.Organization = CostCalculationDocuments.Organization
		|
		|	INNER JOIN TTRevolutionsQuantityWithoutBatches AS Turnovers
		|		ON Turnovers.ItemsLocationAttributes   = GoodsCost.ItemsLocationAttributes
		|		AND Turnovers.AccountingSection 					= GoodsCost.AccountingSection
		|		AND Turnovers.InventoryOwnerAttribute 					= GoodsCost.InventoryOwnerAttribute
		|		AND Turnovers.Organization 					= GoodsCost.Organization
		|
		|GROUP BY
		|	CostCalculationDocuments.Ref,
		|	GoodsCost.ItemsLocationAttributes,
		|	GoodsCost.AccountingSection,
		|	GoodsCost.InventoryOwnerAttribute,
		|	GoodsCost.Organization
		|";
EndFunction

#EndRegion

#Region Testing

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure ComplementStepsWithDataPreparationForFollowingSteps(StageList) Export
	
	StageList.Add("PreparationOfDataForSolvingSLS");
	StageList.Add("PreparationOfDataForCalculatingFIFOCostWeighted");
	StageList.Add("TTTableOfSolutions_CostOfEnterprise_Material");
	StageList.Add("TTTableOfSolutions_CostOfOrganizations_Material");
	StageList.Add("PreparingDataToSolveCaseAdditionalCosts");
	StageList.Add("PreparingDataForSolutionOfSLECase_AdditionalCosts_NodesAndConnections");
	StageList.Add("TTTableOfSolutions_AdditionalCosts");
	StageList.Add("PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods");
	StageList.Add("PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD");
	StageList.Add("TTDecisionTable_LastPeriod");
	StageList.Add("PreparingDataForSolvingCaseOfInclusionExclusionOfVAT");
	StageList.Add("TTTableOfSolutions_InclusionExclusionOfVATOrganizations");
	StageList.Add("PreparationOfDataForCostOfBatchesOfGoods");
	StageList.Add("PreparationOfDataForSolvingCaseOfReservesForImpairmentOfInventories");
	StageList.Add("PreparationOfDataForSolvingSLEItemByItemExpensesVATAccounting");
	StageList.Add("PreparingDataToAddressCaseByCaseCosts");
	StageList.Add("TTTableOfSolutions_CostOfEnterprise_ItemByItem");
	StageList.Add("TTTableOfSolutions_CostOfOrganizations_ItemByItem");
	StageList.Add("PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses");
	StageList.Add("TTTableOfSolutions_CostOfOrganizationsWithReserves");
	StageList.Add("TTDecisionTable_TaxAccountingWithReserves");
	StageList.Add("PreparationOfDataForSolutionOfRATaxAccounting");
	StageList.Add("PreparingDataForSLESolutionIsConstantCostPD");
	StageList.Add("PreparationOfDataForSLESolutionOfCaseOfConstantDifferenceInCostsPDWithReserves");
	StageList.Add("PreparationOfDataForSolvingCaseTaxAccounting_ItemByItemExpenses");
	StageList.Add("TTDecisionTable_TaxAccounting");
	StageList.Add("PreparationOfDataForCostOfOtherExpensesUnfinishedProduction");
	StageList.Add("PreparingDataToSolveCaseOfDeviationsInCostOfGoods");
	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList - 
//
Procedure AddStagesWithBatchTranslation(StageList) Export
	
	StageList.Add("PreparingDataForCostOfGoods");
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	If StageName_ = "PreparationOfDataForSolvingSLS" Then
		QueryText = TextOfRequestToSolveProblem(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForCalculatingFIFOCostWeighted" Then
		QueryText = QueryTextForSolvingFIFOSLEWeighted(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_CostOfEnterprise_Material" Then
		QueryText = QueryTextTTTableOfSolutions_CostOfEnterprise_Material(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_CostOfOrganizations_Material" Then
		QueryText = QueryTextTTTableOfSolutions_CostOfOrganizations_Material(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForSolvingCaseOfReservesForImpairmentOfInventories" Then
		QueryText = TextForSolvingCaseOfReservesForImpairmentOfInventories(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForCostOfBatchesOfGoods" Then
		QueryText = RequestTextForCostOfBatchesOfGoods(CalculationParameters);
	ElsIf StageName_ = "PreparingDataToSolveCaseAdditionalCosts" Then
		QueryText = TextToSolveSLU_AdditionalCosts(CalculationParameters);
	ElsIf StageName_ = "PreparingDataForSolutionOfSLECase_AdditionalCosts_NodesAndConnections" Then
		QueryText = TextForSolvingCase_AdditionalCosts_NodesAndSLEConnections(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_AdditionalCosts" Then
		QueryText = QueryTextTTTableOfSolutions_AdditionalCosts(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForSolvingCaseCalculationOfCostOfPastPeriods" Then
		QueryText = QueryTextForSolvingCaseCalculationOfCostOfPastPeriods(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForSolvingCase_CalculationOfCostOfPastPeriods_CostedPD" Then
		QueryText = QueryTextToSolveSLERejectionsCostPDIsConstant(CalculationParameters);
	ElsIf StageName_ = "TTDecisionTable_LastPeriod" Then
		QueryText = TextTTTableOfDecisions_LastPeriod(CalculationParameters);
	ElsIf StageName_ = "PreparingDataForSolvingCaseOfInclusionExclusionOfVAT" Then
		QueryText = TextForSolvingCaseOfInclusionExclusionOfVAT(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_InclusionExclusionOfVATOrganizations" Then
		QueryText = QueryTextTTTableOfSolutions_InclusionExclusionOfVATOrganizations(CalculationParameters);
	ElsIf StageName_ = "PreparingDataForCostOfGoods" Then
		QueryText = RequestTextForProductPrices(CalculationParameters);
	ElsIf StageName_ = "PreparingDataToAddressCaseByCaseCosts" Then
		QueryText = TextOfRequestToResolveCaseItemByItemExpenses(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_CostOfEnterprise_ItemByItem" Then
		QueryText = QueryTextTTTableOfSolutions_CostOfEnterprise_ItemByItem(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_CostOfOrganizations_ItemByItem" Then
		QueryText = QueryTextTTTableOfSolutions_CostOfOrganizations_ItemByItem(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForSolvingSLEItemByItemExpensesVATAccounting" Then
		QueryText = TextOfRequestToResolveCaseItemByItemExpenses(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForSolutionOfSLAReservesOfForthcomingExpenses" Then
		QueryText = TextOfRequestForSolutionOfSLUReservesOfForthcomingExpenses(CalculationParameters);
	ElsIf StageName_ = "TTTableOfSolutions_CostOfOrganizationsWithReserves" Then
		QueryText = TextTTTableOfSolutions_CostOfOrganizationsWithReserves(CalculationParameters);
	ElsIf StageName_ = "PreparationOfDataForCostOfOtherExpensesUnfinishedProduction" Then
		QueryText = RequestTextForCostOfOtherUnfinishedProductionExpenses(CalculationParameters);
	ElsIf StageName_ = "PreparingDataToSolveCaseOfDeviationsInCostOfGoods" Then
		QueryText = QueryTextForSolvingCaseOfDeviationInCostOfGoods(CalculationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
